package com.freshguardai.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import java.time.LocalDateTime;

@Document(collection = "notifications")
public class Notification {
    @Id private String id;
    private String title;
    private String message;
    private String type;
    private String productId;
    private String userId;
    private String storeName;
    private boolean read = false;
    private LocalDateTime createdAt = LocalDateTime.now();

    public Notification() {}
    public Notification(String title, String message, String type, String productId, String userId) {
        this(title, message, type, productId, userId, null);
    }
    public Notification(String title, String message, String type, String productId, String userId, String storeName) {
        this.title=title; this.message=message; this.type=type; this.productId=productId;
        this.userId=userId; this.storeName=storeName; this.read=false; this.createdAt=LocalDateTime.now();
    }
    public String getId(){return id;} public void setId(String v){id=v;}
    public String getTitle(){return title;} public void setTitle(String v){title=v;}
    public String getMessage(){return message;} public void setMessage(String v){message=v;}
    public String getType(){return type;} public void setType(String v){type=v;}
    public String getProductId(){return productId;} public void setProductId(String v){productId=v;}
    public String getUserId(){return userId;} public void setUserId(String v){userId=v;}
    public String getStoreName(){return storeName;} public void setStoreName(String v){storeName=v;}
    public boolean isRead(){return read;} public void setRead(boolean v){read=v;}
    public LocalDateTime getCreatedAt(){return createdAt;} public void setCreatedAt(LocalDateTime v){createdAt=v;}
}
