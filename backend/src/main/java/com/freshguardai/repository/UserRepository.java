package com.freshguardai.repository;

import com.freshguardai.model.Role;
import com.freshguardai.model.User;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends MongoRepository<User, String> {
    Optional<User> findByEmail(String email);
    boolean existsByEmail(String email);
    List<User> findByRole(Role role);
    List<User> findByRoleAndStoreNameOrderByNameAsc(Role role, String storeName);
    long countByActive(boolean active);
    long countByRole(Role role);
}
