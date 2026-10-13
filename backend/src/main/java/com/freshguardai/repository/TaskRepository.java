package com.freshguardai.repository;
import com.freshguardai.model.Task;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
@Repository
public interface TaskRepository extends MongoRepository<Task,String> {
    List<Task> findAllByOrderByCreatedAtDesc();
    List<Task> findByAssignedToOrderByCreatedAtDesc(String assignedTo);
    List<Task> findByStoreNameOrderByCreatedAtDesc(String storeName);
    List<Task> findByAssignedToAndStoreNameOrderByCreatedAtDesc(String assignedTo,String storeName);
    List<Task> findByStatus(String status);
    List<Task> findByStatusAndStoreName(String status,String storeName);
}
