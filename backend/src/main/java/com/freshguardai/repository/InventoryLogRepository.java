package com.freshguardai.repository;

import com.freshguardai.model.InventoryLog;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface InventoryLogRepository extends MongoRepository<InventoryLog, String> {
    List<InventoryLog> findByProductId(String productId);
    List<InventoryLog> findByAction(String action);
    List<InventoryLog> findByStoreNameOrderByTimestampDesc(String storeName);
    List<InventoryLog> findByActionAndStoreName(String action, String storeName);
    List<InventoryLog> findAllByOrderByTimestampDesc();
}
