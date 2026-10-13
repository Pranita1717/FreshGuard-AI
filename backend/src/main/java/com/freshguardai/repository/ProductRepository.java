package com.freshguardai.repository;

import com.freshguardai.model.Priority;
import com.freshguardai.model.Product;
import com.freshguardai.model.ProductStatus;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface ProductRepository extends MongoRepository<Product, String> {
    Optional<Product> findByBarcodeAndStoreName(String barcode, String storeName);
    boolean existsByBarcodeAndStoreName(String barcode, String storeName);
    List<Product> findByStoreName(String storeName);
    Optional<Product> findByIdAndStoreName(String id, String storeName);
    List<Product> findByCategoryAndStoreName(String category, String storeName);
    List<Product> findByExpiryStatusAndStoreName(ProductStatus expiryStatus, String storeName);
    List<Product> findByShelfPriorityAndStoreName(Priority shelfPriority, String storeName);
    List<Product> findByExpiryDateBeforeAndStoreName(LocalDate date, String storeName);
    List<Product> findByQuantityLessThanEqualAndStoreName(Integer threshold, String storeName);
    long countByExpiryStatus(ProductStatus expiryStatus);
    long countByStoreName(String storeName);
}
