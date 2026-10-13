package com.freshguardai;

import com.freshguardai.model.Priority;
import com.freshguardai.model.ProductStatus;
import com.freshguardai.service.ProductService;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.assertEquals;

class ProductServiceTest {

    @Test
    void testExpiryStatusExpired() {
        LocalDate pastDate = LocalDate.now().minusDays(1);
        ProductStatus status = ProductService.calculateExpiryStatus(pastDate);
        Priority priority = ProductService.calculateShelfPriority(status);

        assertEquals(ProductStatus.EXPIRED, status);
        assertEquals(Priority.HIGH, priority);
    }

    @Test
    void testExpiryStatusCritical() {
        LocalDate criticalDate = LocalDate.now().plusDays(4);
        ProductStatus status = ProductService.calculateExpiryStatus(criticalDate);
        Priority priority = ProductService.calculateShelfPriority(status);

        assertEquals(ProductStatus.CRITICAL, status);
        assertEquals(Priority.HIGH, priority);
    }

    @Test
    void testExpiryStatusNearExpiry() {
        LocalDate nearDate = LocalDate.now().plusDays(20);
        ProductStatus status = ProductService.calculateExpiryStatus(nearDate);
        Priority priority = ProductService.calculateShelfPriority(status);

        assertEquals(ProductStatus.NEAR_EXPIRY, status);
        assertEquals(Priority.MEDIUM, priority);
    }

    @Test
    void testExpiryStatusSafe() {
        LocalDate safeDate = LocalDate.now().plusDays(60);
        ProductStatus status = ProductService.calculateExpiryStatus(safeDate);
        Priority priority = ProductService.calculateShelfPriority(status);

        assertEquals(ProductStatus.SAFE, status);
        assertEquals(Priority.LOW, priority);
    }
}
