package com.freshguardai.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import java.time.LocalDateTime;

@Document(collection = "inventory_logs")
public class InventoryLog {
    @Id private String id;
    private String productId;
    private String productName;
    private String action;
    private Integer oldQuantity;
    private Integer newQuantity;
    private Integer changedQuantity;
    private String performedBy;
    private Role performedByRole;
    private LocalDateTime timestamp = LocalDateTime.now();
    private String reason;
    private String storeName;

    public InventoryLog() {}

    public InventoryLog(String productId, String productName, String action, Integer oldQuantity,
                         Integer newQuantity, Integer changedQuantity, String performedBy,
                         Role performedByRole, String reason) {
        this(productId, productName, action, oldQuantity, newQuantity, changedQuantity,
                performedBy, performedByRole, reason, null);
    }

    public InventoryLog(String productId, String productName, String action, Integer oldQuantity,
                        Integer newQuantity, Integer changedQuantity, String performedBy,
                        Role performedByRole, String reason, String storeName) {
        this.productId = productId; this.productName = productName; this.action = action;
        this.oldQuantity = oldQuantity; this.newQuantity = newQuantity;
        this.changedQuantity = changedQuantity; this.performedBy = performedBy;
        this.performedByRole = performedByRole; this.reason = reason;
        this.storeName = storeName; this.timestamp = LocalDateTime.now();
    }
    public String getId(){return id;} public void setId(String id){this.id=id;}
    public String getProductId(){return productId;} public void setProductId(String v){productId=v;}
    public String getProductName(){return productName;} public void setProductName(String v){productName=v;}
    public String getAction(){return action;} public void setAction(String v){action=v;}
    public Integer getOldQuantity(){return oldQuantity;} public void setOldQuantity(Integer v){oldQuantity=v;}
    public Integer getNewQuantity(){return newQuantity;} public void setNewQuantity(Integer v){newQuantity=v;}
    public Integer getChangedQuantity(){return changedQuantity;} public void setChangedQuantity(Integer v){changedQuantity=v;}
    public String getPerformedBy(){return performedBy;} public void setPerformedBy(String v){performedBy=v;}
    public Role getPerformedByRole(){return performedByRole;} public void setPerformedByRole(Role v){performedByRole=v;}
    public LocalDateTime getTimestamp(){return timestamp;} public void setTimestamp(LocalDateTime v){timestamp=v;}
    public String getReason(){return reason;} public void setReason(String v){reason=v;}
    public String getStoreName(){return storeName;} public void setStoreName(String v){storeName=v;}
}
