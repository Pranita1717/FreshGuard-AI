package com.freshguardai.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import java.time.LocalDateTime;

@Document(collection = "discounts")
public class Discount {
    @Id private String id;
    private String productId;
    private String productName;
    private Double percentage;
    private String reason;
    private String status = "PENDING";
    private String createdBy;
    private String approvedBy;
    private String storeName;
    private LocalDateTime createdAt = LocalDateTime.now();
    private LocalDateTime approvedAt;
    public Discount() {}
    public Discount(String productId,String productName,Double percentage,String reason,String createdBy){
        this(productId,productName,percentage,reason,createdBy,null);
    }
    public Discount(String productId,String productName,Double percentage,String reason,String createdBy,String storeName){
        this.productId=productId;this.productName=productName;this.percentage=percentage;this.reason=reason;
        this.createdBy=createdBy;this.storeName=storeName;this.status="PENDING";this.createdAt=LocalDateTime.now();
    }
    public String getId(){return id;} public void setId(String v){id=v;}
    public String getProductId(){return productId;} public void setProductId(String v){productId=v;}
    public String getProductName(){return productName;} public void setProductName(String v){productName=v;}
    public Double getPercentage(){return percentage;} public void setPercentage(Double v){percentage=v;}
    public String getReason(){return reason;} public void setReason(String v){reason=v;}
    public String getStatus(){return status;} public void setStatus(String v){status=v;}
    public String getCreatedBy(){return createdBy;} public void setCreatedBy(String v){createdBy=v;}
    public String getApprovedBy(){return approvedBy;} public void setApprovedBy(String v){approvedBy=v;}
    public String getStoreName(){return storeName;} public void setStoreName(String v){storeName=v;}
    public LocalDateTime getCreatedAt(){return createdAt;} public void setCreatedAt(LocalDateTime v){createdAt=v;}
    public LocalDateTime getApprovedAt(){return approvedAt;} public void setApprovedAt(LocalDateTime v){approvedAt=v;}
}
