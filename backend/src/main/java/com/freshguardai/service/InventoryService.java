package com.freshguardai.service;

import com.freshguardai.dto.InventoryUpdateRequest;
import com.freshguardai.exception.BadRequestException;
import com.freshguardai.model.*;
import com.freshguardai.repository.InventoryLogRepository;
import com.freshguardai.repository.ProductRepository;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class InventoryService {
    private final ProductRepository productRepository; private final InventoryLogRepository inventoryLogRepository; private final ProductService productService;
    public InventoryService(ProductRepository productRepository,InventoryLogRepository inventoryLogRepository,ProductService productService){this.productRepository=productRepository;this.inventoryLogRepository=inventoryLogRepository;this.productService=productService;}
    public Product updateInventory(String productId,InventoryUpdateRequest request,String performedBy,Role role,String storeName){
        Product p=productService.getProductById(productId,storeName);int old=p.getQuantity()!=null?p.getQuantity():0;int newQ=old;int changed=0;
        String action=request.getAction()==null?"":request.getAction().trim().toUpperCase();
        Integer q=request.getQuantityChange();
        if(q!=null&&q<0)throw new BadRequestException("Quantity change cannot be negative");
        switch(action){
            case "INCREASE","RESTOCK","RECEIVE_DELIVERY" -> {int c=q!=null?q:1;if(c<=0)throw new BadRequestException("Quantity must be greater than 0");newQ=old+c;changed=c;}
            case "DECREASE" -> {int c=q!=null?q:1;if(c<=0)throw new BadRequestException("Quantity must be greater than 0");if(old<c)throw new BadRequestException("Cannot decrease stock below 0");newQ=old-c;changed=-c;}
            case "SET" -> {Integer target=request.getNewQuantity()!=null?request.getNewQuantity():q;if(target==null||target<0)throw new BadRequestException("Valid non-negative new quantity is required");newQ=target;changed=newQ-old;}
            case "REMOVE_EXPIRED" -> {int c=q!=null?q:old;if(c<=0)throw new BadRequestException("Quantity to remove must be greater than 0");if(old<c)throw new BadRequestException("Cannot remove more items than existing stock");newQ=old-c;changed=-c;}
            default -> throw new BadRequestException("Unsupported inventory action: "+request.getAction()+". Use INCREASE, DECREASE, SET, RECEIVE_DELIVERY or REMOVE_EXPIRED.");
        }
        p.setQuantity(newQ);if(newQ==0&&"REMOVE_EXPIRED".equals(action))p.setExpiryStatus(ProductStatus.REMOVED);else productService.saveOrRefreshProduct(p);p.setUpdatedAt(LocalDateTime.now());Product saved=productRepository.save(p);
        inventoryLogRepository.save(new InventoryLog(saved.getId(),saved.getName(),action,old,newQ,changed,performedBy,role,request.getReason()!=null?request.getReason():"Stock updated via "+action,storeName));
        productService.checkAndCreateAlerts(saved);return saved;
    }
    public Product removeExpired(String productId,int quantity,String reason,String by,Role role,String storeName){if(quantity<=0)throw new BadRequestException("Quantity must be greater than 0");return updateInventory(productId,new InventoryUpdateRequest("REMOVE_EXPIRED",quantity,null,reason),by,role,storeName);}
    public List<Map<String,Object>> getRestockingData(String storeName){
        return productService.getAllProducts(storeName).stream().filter(p->p.getExpiryStatus()!=ProductStatus.REMOVED).map(p->{Map<String,Object> m=new HashMap<>();int cur=p.getQuantity()!=null?p.getQuantity():0;int min=p.getMinimumStock()!=null?p.getMinimumStock():0;int suggested=Math.max(0,(min*2)-cur);m.put("productId",p.getId());m.put("productName",p.getName());m.put("barcode",p.getBarcode());m.put("category",p.getCategory());m.put("currentQuantity",cur);m.put("minimumStock",min);m.put("suggestedQuantity",suggested);m.put("status",cur<=min?"RESTOCK_REQUIRED":"SUFFICIENT");m.put("id",p.getId());m.put("name",p.getName());m.put("currentStock",cur);m.put("suggestedRestock",suggested);m.put("unit",p.getUnit());m.put("ruleReason",cur<=min?"Current stock is at or below the configured minimum threshold":"Stock is above the minimum threshold");m.put("urgency",cur==0?"OUT_OF_STOCK":cur<=Math.max(1,min/2)?"CRITICAL":cur<=min?"HIGH":"NORMAL");return m;}).collect(Collectors.toList());
    }
    public List<InventoryLog> getInventoryLogs(String storeName){return inventoryLogRepository.findByStoreNameOrderByTimestampDesc(storeName);}
}
