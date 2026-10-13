package com.freshguardai.service;

import com.freshguardai.dto.ProductRequest;
import com.freshguardai.exception.BadRequestException;
import com.freshguardai.exception.ResourceNotFoundException;
import com.freshguardai.model.*;
import com.freshguardai.repository.InventoryLogRepository;
import com.freshguardai.repository.ProductRepository;
import com.freshguardai.repository.SystemLogRepository;
import org.springframework.stereotype.Service;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class ProductService {
    private final ProductRepository productRepository;
    private final InventoryLogRepository inventoryLogRepository;
    private final NotificationService notificationService;
    private final SystemLogRepository systemLogRepository;

    public ProductService(ProductRepository productRepository,InventoryLogRepository inventoryLogRepository,
                          NotificationService notificationService,SystemLogRepository systemLogRepository){
        this.productRepository=productRepository;this.inventoryLogRepository=inventoryLogRepository;
        this.notificationService=notificationService;this.systemLogRepository=systemLogRepository;
    }
    public static ProductStatus calculateExpiryStatus(LocalDate expiryDate){
        if(expiryDate==null)return ProductStatus.SAFE;
        long d=ChronoUnit.DAYS.between(LocalDate.now(),expiryDate);
        if(d<0)return ProductStatus.EXPIRED;
        if(d<=7)return ProductStatus.CRITICAL;
        if(d<=30)return ProductStatus.NEAR_EXPIRY;
        return ProductStatus.SAFE;
    }
    public static Priority calculateShelfPriority(ProductStatus status){
        if(status==ProductStatus.EXPIRED||status==ProductStatus.CRITICAL)return Priority.HIGH;
        if(status==ProductStatus.NEAR_EXPIRY)return Priority.MEDIUM;
        return Priority.LOW;
    }
    public Product saveOrRefreshProduct(Product product){
        if(product.getExpiryStatus()==ProductStatus.REMOVED)return product;
        ProductStatus status=calculateExpiryStatus(product.getExpiryDate());
        product.setExpiryStatus(status);product.setShelfPriority(calculateShelfPriority(status));
        return product;
    }
    public List<Product> getAllProducts(String storeName){
        return productRepository.findByStoreName(storeName).stream().map(this::saveOrRefreshProduct).collect(Collectors.toList());
    }
    public Product getProductById(String id,String storeName){
        return productRepository.findByIdAndStoreName(id,storeName)
                .orElseThrow(()->new ResourceNotFoundException("Product not found in your store"));
    }
    public Product getProductByBarcode(String barcode,String storeName){
        return productRepository.findByBarcodeAndStoreName(barcode.trim(),storeName)
                .orElseThrow(()->new ResourceNotFoundException("Product not found with barcode: "+barcode));
    }
    public Product createProduct(ProductRequest request,String performedBy,Role role,String storeName){
        if(storeName==null||storeName.isBlank())throw new BadRequestException("Your account is not assigned to a store");
        if(productRepository.existsByBarcodeAndStoreName(request.getBarcode().trim(),storeName))
            throw new BadRequestException("Product with barcode already exists in this store: "+request.getBarcode());
        if(request.getManufacturingDate()!=null && request.getManufacturingDate().isAfter(request.getExpiryDate()))
            throw new BadRequestException("Manufacturing date cannot be after expiry date");
        Product p=new Product();
        p.setBarcode(request.getBarcode().trim());p.setName(request.getName().trim());p.setCategory(request.getCategory().trim());
        p.setBrand(request.getBrand()!=null?request.getBrand().trim():"");
        p.setQuantity(request.getQuantity());p.setMinimumStock(request.getMinimumStock());p.setPrice(request.getPrice());
        p.setManufacturingDate(request.getManufacturingDate());p.setExpiryDate(request.getExpiryDate());
        p.setUnit(request.getUnit()!=null&&!request.getUnit().isBlank()?request.getUnit().trim():"units");
        p.setStoreName(storeName);p.setCreatedAt(LocalDateTime.now());p.setUpdatedAt(LocalDateTime.now());saveOrRefreshProduct(p);
        Product saved=productRepository.save(p);
        logInventory(saved,"ADD",0,saved.getQuantity(),saved.getQuantity(),performedBy,role,"Initial product entry");
        checkAndCreateAlerts(saved); logSystem("PRODUCT_CREATED","Product created: "+saved.getName()+" by "+performedBy,"INFO");
        return saved;
    }
    public Product updateProduct(String id,ProductRequest request,String performedBy,Role role,String storeName){
        Product p=getProductById(id,storeName);
        if(request.getManufacturingDate()!=null&&request.getManufacturingDate().isAfter(request.getExpiryDate()))throw new BadRequestException("Manufacturing date cannot be after expiry date");
        String barcode=request.getBarcode().trim();
        if(!p.getBarcode().equals(barcode)&&productRepository.existsByBarcodeAndStoreName(barcode,storeName))throw new BadRequestException("Another product uses this barcode in your store");
        int old=p.getQuantity();p.setBarcode(barcode);p.setName(request.getName().trim());p.setCategory(request.getCategory().trim());
        p.setBrand(request.getBrand()!=null?request.getBrand().trim():"");
        p.setQuantity(request.getQuantity());p.setMinimumStock(request.getMinimumStock());p.setPrice(request.getPrice());p.setManufacturingDate(request.getManufacturingDate());p.setExpiryDate(request.getExpiryDate());
        if(request.getUnit()!=null&&!request.getUnit().isBlank())p.setUnit(request.getUnit().trim());p.setUpdatedAt(LocalDateTime.now());saveOrRefreshProduct(p);
        Product saved=productRepository.save(p);if(old!=saved.getQuantity())logInventory(saved,"UPDATE_STOCK",old,saved.getQuantity(),saved.getQuantity()-old,performedBy,role,"Product edit quantity adjustment");
        checkAndCreateAlerts(saved);return saved;
    }
    public void deleteProduct(String id,String performedBy,Role role,String storeName){
        Product p=getProductById(id,storeName);productRepository.delete(p);
        logInventory(p,"DELETE",p.getQuantity(),0,-p.getQuantity(),performedBy,role,"Product deleted from catalog");
        logSystem("PRODUCT_DELETED","Product deleted: "+p.getName()+" by "+performedBy,"WARN");
    }
    public Product updateExpiryDate(String id,LocalDate newExpiryDate,String ocrText,String performedBy,Role role,String storeName){
        if(newExpiryDate==null)throw new BadRequestException("Valid expiry date is required");
        Product p=getProductById(id,storeName);p.setExpiryDate(newExpiryDate);p.setOcrVerified(true);if(ocrText!=null&&!ocrText.isBlank())p.setOcrText(ocrText);
        p.setUpdatedAt(LocalDateTime.now());saveOrRefreshProduct(p);Product saved=productRepository.save(p);
        logInventory(saved,"OCR_EXPIRY_VERIFIED",saved.getQuantity(),saved.getQuantity(),0,performedBy,role,"Expiry date verified: "+newExpiryDate);
        logSystem("OCR_EXPIRY_UPDATED","Expiry date updated for "+saved.getName()+" by "+performedBy,"INFO");checkAndCreateAlerts(saved);return saved;
    }
    public void checkAndCreateAlerts(Product p){
        if(p.getStoreName()==null)return;
        if(p.getExpiryStatus()==ProductStatus.EXPIRED) notificationService.createNotification("Product Expired!","Product '"+p.getName()+"' has EXPIRED. Please remove it from shelves immediately.","EXPIRY_ALERT",p.getId(),null,p.getStoreName());
        else if(p.getExpiryStatus()==ProductStatus.CRITICAL) notificationService.createNotification("Critical Expiry Warning","Product '"+p.getName()+"' expires within 7 days ("+p.getExpiryDate()+"). Apply discount or triage.","EXPIRY_ALERT",p.getId(),null,p.getStoreName());
        else if(p.getExpiryStatus()==ProductStatus.NEAR_EXPIRY) notificationService.createNotification("Near Expiry Notice","Product '"+p.getName()+"' is within 30 days of expiry ("+p.getExpiryDate()+").","EXPIRY_ALERT",p.getId(),null,p.getStoreName());
        if(p.getQuantity()!=null&&p.getMinimumStock()!=null&&p.getQuantity()<=p.getMinimumStock()) notificationService.createNotification("Low Stock Alert","Product '"+p.getName()+"' stock is at "+p.getQuantity()+" (Threshold: "+p.getMinimumStock()+"). Restock needed.","LOW_STOCK",p.getId(),null,p.getStoreName());
    }
    private void logInventory(Product p,String action,int oldQ,int newQ,int changed,String by,Role role,String reason){inventoryLogRepository.save(new InventoryLog(p.getId(),p.getName(),action,oldQ,newQ,changed,by,role,reason,p.getStoreName()));}
    private void logSystem(String event,String description,String severity){systemLogRepository.save(new SystemLog(event,description,severity));}
}
