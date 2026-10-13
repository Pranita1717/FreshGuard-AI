package com.freshguardai.service;

import com.freshguardai.exception.ResourceNotFoundException;
import com.freshguardai.model.Notification;
import com.freshguardai.repository.NotificationRepository;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class NotificationService {
    private final NotificationRepository notificationRepository;
    public NotificationService(NotificationRepository notificationRepository){this.notificationRepository=notificationRepository;}

    public Notification createNotification(String title,String message,String type,String productId,String userId){
        return createNotification(title,message,type,productId,userId,null);
    }
    public Notification createNotification(String title,String message,String type,String productId,String userId,String storeName){
        return notificationRepository.save(new Notification(title,message,type,productId,userId,storeName));
    }
    public List<Notification> getNotificationsForUser(String userId,String storeName){
        return notificationRepository.findVisible(userId,storeName);
    }
    public List<Notification> getUnreadForUser(String userId,String storeName){
        return notificationRepository.findUnreadVisible(userId,storeName);
    }
    public Notification markAsRead(String id,String userId,String storeName){
        Notification n=notificationRepository.findById(id).orElseThrow(()->new ResourceNotFoundException("Notification not found"));
        if (!isVisibleTo(n,userId,storeName)) throw new ResourceNotFoundException("Notification not found");
        n.setRead(true); return notificationRepository.save(n);
    }
    public void markAllAsRead(String userId,String storeName){
        List<Notification> list=getUnreadForUser(userId,storeName);
        list.forEach(n->n.setRead(true)); notificationRepository.saveAll(list);
    }
    public long getUnreadCount(String userId){return notificationRepository.countByUserIdAndReadFalse(userId);}
    private boolean isVisibleTo(Notification n,String userId,String storeName){
        return (n.getUserId()!=null && n.getUserId().equals(userId)) ||
               (n.getStoreName()!=null && n.getStoreName().equals(storeName));
    }
}
