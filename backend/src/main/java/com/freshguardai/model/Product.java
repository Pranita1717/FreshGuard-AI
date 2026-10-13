package com.freshguardai.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Document(collection = "products")
public class Product {

    @Id
    private String id;

    @Indexed
    private String barcode;

    private String name;

    private String category;

    private String brand;

    private Integer quantity;

    private String unit = "units";

    private Integer minimumStock;

    private Double price;

    private LocalDate manufacturingDate;

    private LocalDate expiryDate;

    private ProductStatus expiryStatus;

    private Priority shelfPriority;

    private String storeName;

    private LocalDateTime createdAt = LocalDateTime.now();

    private LocalDateTime updatedAt = LocalDateTime.now();

    private Boolean ocrVerified = false;

    private String ocrText;

    public Product() {
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getBarcode() {
        return barcode;
    }

    public void setBarcode(String barcode) {
        this.barcode = barcode;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public String getBrand() {
        return brand;
    }

    public void setBrand(String brand) {
        this.brand = brand;
    }

    public Integer getQuantity() {
        return quantity;
    }

    public void setQuantity(Integer quantity) {
        this.quantity = quantity;
    }

    public String getUnit() {
        return unit;
    }

    public void setUnit(String unit) {
        this.unit = unit;
    }

    public Integer getMinimumStock() {
        return minimumStock;
    }

    public void setMinimumStock(Integer minimumStock) {
        this.minimumStock = minimumStock;
    }

    public Double getPrice() {
        return price;
    }

    public void setPrice(Double price) {
        this.price = price;
    }

    public LocalDate getManufacturingDate() {
        return manufacturingDate;
    }

    public void setManufacturingDate(LocalDate manufacturingDate) {
        this.manufacturingDate = manufacturingDate;
    }

    public LocalDate getExpiryDate() {
        return expiryDate;
    }

    public void setExpiryDate(LocalDate expiryDate) {
        this.expiryDate = expiryDate;
    }

    public ProductStatus getExpiryStatus() {
        return expiryStatus;
    }

    public void setExpiryStatus(ProductStatus expiryStatus) {
        this.expiryStatus = expiryStatus;
    }

    public Priority getShelfPriority() {
        return shelfPriority;
    }

    public void setShelfPriority(Priority shelfPriority) {
        this.shelfPriority = shelfPriority;
    }

    public String getStoreName() {
        return storeName;
    }

    public void setStoreName(String storeName) {
        this.storeName = storeName;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }

    public Boolean getOcrVerified() {
        return ocrVerified;
    }

    public void setOcrVerified(Boolean ocrVerified) {
        this.ocrVerified = ocrVerified;
    }

    public String getOcrText() {
        return ocrText;
    }

    public void setOcrText(String ocrText) {
        this.ocrText = ocrText;
    }
    @org.springframework.data.annotation.Transient
    public Long getDaysUntilExpiry() {
        if (expiryDate == null) return null;
        return java.time.temporal.ChronoUnit.DAYS.between(java.time.LocalDate.now(), expiryDate);
    }

}
