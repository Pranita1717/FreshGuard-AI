package com.freshguardai.repository;
import com.freshguardai.model.Discount;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
@Repository
public interface DiscountRepository extends MongoRepository<Discount,String> {
    List<Discount> findByStoreNameOrderByCreatedAtDesc(String storeName);
    List<Discount> findByStatusAndStoreName(String status,String storeName);
    List<Discount> findByStatus(String status);
    List<Discount> findByProductId(String productId);
}
