package com.freshguardai.service;

import com.freshguardai.exception.BadRequestException;
import com.freshguardai.exception.ResourceNotFoundException;
import com.freshguardai.model.Discount;
import com.freshguardai.model.Product;
import com.freshguardai.repository.DiscountRepository;
import org.springframework.stereotype.Service;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.time.LocalDateTime;
import java.util.*;

@Service
public class DiscountService {
    private final DiscountRepository discountRepository; private final ProductService productService; private final NotificationService notificationService;
    public DiscountService(DiscountRepository discountRepository,ProductService productService,NotificationService notificationService){this.discountRepository=discountRepository;this.productService=productService;this.notificationService=notificationService;}
    public Discount createDiscount(String productId,Double percentage,String reason,String createdBy,String storeName){
        if(percentage==null||percentage<=0||percentage>90)throw new BadRequestException("Discount percentage must be between 1% and 90%");
        Product p=productService.getProductById(productId,storeName);
        Discount d=new Discount(p.getId(),p.getName(),percentage,reason!=null?reason:"Store markdown",createdBy,storeName);Discount saved=discountRepository.save(d);
        notificationService.createNotification("New Discount Proposed","A discount of "+percentage+"% was proposed for '"+p.getName()+"'","DISCOUNT_ACTION",p.getId(),null,storeName);return saved;
    }
    public List<Discount> getAllDiscounts(String storeName){return discountRepository.findByStoreNameOrderByCreatedAtDesc(storeName);}
    public List<Map<String,Object>> getDiscountSuggestions(String storeName){
        return productService.getAllProducts(storeName).stream().filter(p->p.getExpiryStatus().name().equals("CRITICAL")||p.getExpiryStatus().name().equals("NEAR_EXPIRY")).map(p->{
            Map<String,Object> m=new HashMap<>();double pct=p.getExpiryStatus().name().equals("CRITICAL")?40.0:20.0;double price=p.getPrice()!=null?p.getPrice():0.0;double discounted=Math.round(price*(1-pct/100.0)*100.0)/100.0;long days=p.getExpiryDate()==null?0:ChronoUnit.DAYS.between(LocalDate.now(),p.getExpiryDate());
            m.put("productId",p.getId());m.put("productName",p.getName());m.put("category",p.getCategory());m.put("expiryDate",p.getExpiryDate()!=null?p.getExpiryDate().toString():"");m.put("daysUntilExpiry",days);m.put("currentPrice",price);m.put("suggestedDiscount",pct);m.put("suggestedDiscountPercent",pct);m.put("suggestedPrice",discounted);m.put("discountedPrice",discounted);m.put("reason",p.getExpiryStatus().name().equals("CRITICAL")?"Critical expiry (7 days or less) - urgent clearance recommended":"Approaching expiry (30 days or less) - promotional markdown");m.put("ruleReason",m.get("reason"));m.put("status","SUGGESTED");return m;
        }).toList();
    }
    private Discount getOwned(String id,String storeName){Discount d=discountRepository.findById(id).orElseThrow(()->new ResourceNotFoundException("Discount not found"));if(!storeName.equals(d.getStoreName()))throw new ResourceNotFoundException("Discount not found");return d;}
    public Discount approveDiscount(String id,String by,String storeName){Discount d=getOwned(id,storeName);d.setStatus("APPROVED");d.setApprovedBy(by);d.setApprovedAt(LocalDateTime.now());Discount s=discountRepository.save(d);notificationService.createNotification("Discount Approved","Discount of "+s.getPercentage()+"% approved for '"+s.getProductName()+"'","DISCOUNT_ACTION",s.getProductId(),null,storeName);return s;}
    public Discount rejectDiscount(String id,String by,String storeName){Discount d=getOwned(id,storeName);d.setStatus("REJECTED");d.setApprovedBy(by);d.setApprovedAt(LocalDateTime.now());return discountRepository.save(d);}
}
