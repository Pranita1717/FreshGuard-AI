package com.freshguardai.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import java.time.LocalDateTime;

@Document(collection="tasks")
public class Task {
    @Id private String id;
    private String title;
    private String description;
    private String assignedTo;
    private String productId;
    private String taskType;
    private String assignedBy;
    private String status="PENDING";
    private Priority priority=Priority.MEDIUM;
    private String storeName;
    private LocalDateTime createdAt=LocalDateTime.now();
    private LocalDateTime updatedAt=LocalDateTime.now();
    private LocalDateTime dueDate;
    private LocalDateTime completedAt;
    public Task(){}
    public Task(String title,String description,String assignedTo,String productId,Priority priority){
        this(title,description,assignedTo,productId,priority,null);
    }
    public Task(String title,String description,String assignedTo,String productId,Priority priority,String storeName){
        this(title,description,assignedTo,productId,priority,storeName,null,null);
    }
    public Task(String title,String description,String assignedTo,String productId,Priority priority,String storeName,String taskType,String assignedBy){
        this.title=title;this.description=description;this.assignedTo=assignedTo;this.productId=productId;this.taskType=taskType;this.assignedBy=assignedBy;
        this.priority=priority!=null?priority:Priority.MEDIUM;this.storeName=storeName;this.status="PENDING";this.createdAt=LocalDateTime.now();this.updatedAt=LocalDateTime.now();
    }
    public String getId(){return id;} public void setId(String v){id=v;}
    public String getTitle(){return title;} public void setTitle(String v){title=v;}
    public String getDescription(){return description;} public void setDescription(String v){description=v;}
    public String getAssignedTo(){return assignedTo;} public void setAssignedTo(String v){assignedTo=v;}
    public String getProductId(){return productId;} public void setProductId(String v){productId=v;}
    public String getTaskType(){return taskType;} public void setTaskType(String v){taskType=v;}
    public String getAssignedBy(){return assignedBy;} public void setAssignedBy(String v){assignedBy=v;}
    public String getStatus(){return status;} public void setStatus(String v){status=v;}
    public Priority getPriority(){return priority;} public void setPriority(Priority v){priority=v;}
    public String getStoreName(){return storeName;} public void setStoreName(String v){storeName=v;}
    public LocalDateTime getCreatedAt(){return createdAt;} public void setCreatedAt(LocalDateTime v){createdAt=v;}
    public LocalDateTime getUpdatedAt(){return updatedAt;} public void setUpdatedAt(LocalDateTime v){updatedAt=v;}
    public LocalDateTime getDueDate(){return dueDate;} public void setDueDate(LocalDateTime v){dueDate=v;}
    public LocalDateTime getCompletedAt(){return completedAt;} public void setCompletedAt(LocalDateTime v){completedAt=v;}
}
