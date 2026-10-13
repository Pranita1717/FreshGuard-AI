package com.freshguardai.repository;
import com.freshguardai.model.Notification;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.data.mongodb.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;
@Repository
public interface NotificationRepository extends MongoRepository<Notification,String> {
    @Query("{ '$or': [ { 'userId': ?0 }, { 'storeName': ?1 } ] }")
    List<Notification> findVisible(String userId,String storeName);
    @Query("{ '$and': [ { '$or': [ { 'userId': ?0 }, { 'storeName': ?1 } ] }, { 'read': false } ] }")
    List<Notification> findUnreadVisible(String userId,String storeName);
    long countByUserIdAndReadFalse(String userId);
}
