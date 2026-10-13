package com.freshguardai.dto;

public class AdminAnalyticsResponse {

    private long totalRegisteredUsers;
    private long activeUsers;
    private long employeesCount;
    private long storeManagersCount;
    private long totalLoginAttempts;
    private long successfulLogins;
    private long failedLoginAttempts;
    private long totalProducts;
    private long totalInventoryQuantity;
    private long expiredProducts;
    private long criticalProducts;
    private long nearExpiryProducts;
    private long safeProducts;
    private long lowStockProducts;
    private long totalDiscounts;
    private long pendingDiscounts;
    private long openTasks;
    private long completedTasks;

    public AdminAnalyticsResponse() {
    }

    public long getTotalRegisteredUsers() {
        return totalRegisteredUsers;
    }

    public void setTotalRegisteredUsers(long totalRegisteredUsers) {
        this.totalRegisteredUsers = totalRegisteredUsers;
    }

    public long getActiveUsers() {
        return activeUsers;
    }

    public void setActiveUsers(long activeUsers) {
        this.activeUsers = activeUsers;
    }

    public long getTotalLoginAttempts() {
        return totalLoginAttempts;
    }

    public void setTotalLoginAttempts(long totalLoginAttempts) {
        this.totalLoginAttempts = totalLoginAttempts;
    }

    public long getSuccessfulLogins() {
        return successfulLogins;
    }

    public void setSuccessfulLogins(long successfulLogins) {
        this.successfulLogins = successfulLogins;
    }

    public long getFailedLoginAttempts() {
        return failedLoginAttempts;
    }

    public void setFailedLoginAttempts(long failedLoginAttempts) {
        this.failedLoginAttempts = failedLoginAttempts;
    }

    public long getTotalProducts() {
        return totalProducts;
    }

    public void setTotalProducts(long totalProducts) {
        this.totalProducts = totalProducts;
    }

    public long getTotalInventoryQuantity() {
        return totalInventoryQuantity;
    }

    public void setTotalInventoryQuantity(long totalInventoryQuantity) {
        this.totalInventoryQuantity = totalInventoryQuantity;
    }

    public long getExpiredProducts() {
        return expiredProducts;
    }

    public void setExpiredProducts(long expiredProducts) {
        this.expiredProducts = expiredProducts;
    }

    public long getCriticalProducts() {
        return criticalProducts;
    }

    public void setCriticalProducts(long criticalProducts) {
        this.criticalProducts = criticalProducts;
    }

    public long getNearExpiryProducts() {
        return nearExpiryProducts;
    }

    public void setNearExpiryProducts(long nearExpiryProducts) {
        this.nearExpiryProducts = nearExpiryProducts;
    }

    public long getSafeProducts() {
        return safeProducts;
    }

    public void setSafeProducts(long safeProducts) {
        this.safeProducts = safeProducts;
    }

    public long getLowStockProducts() {
        return lowStockProducts;
    }

    public void setLowStockProducts(long lowStockProducts) {
        this.lowStockProducts = lowStockProducts;
    }

    public long getTotalDiscounts() {
        return totalDiscounts;
    }

    public void setTotalDiscounts(long totalDiscounts) {
        this.totalDiscounts = totalDiscounts;
    }

    public long getPendingDiscounts() {
        return pendingDiscounts;
    }

    public void setPendingDiscounts(long pendingDiscounts) {
        this.pendingDiscounts = pendingDiscounts;
    }

    public long getOpenTasks() {
        return openTasks;
    }

    public void setOpenTasks(long openTasks) {
        this.openTasks = openTasks;
    }

    public long getCompletedTasks() {
        return completedTasks;
    }

    public void setCompletedTasks(long completedTasks) {
        this.completedTasks = completedTasks;
    }

    public long getEmployeesCount() {
        return employeesCount;
    }

    public void setEmployeesCount(long employeesCount) {
        this.employeesCount = employeesCount;
    }

    public long getStoreManagersCount() {
        return storeManagersCount;
    }

    public void setStoreManagersCount(long storeManagersCount) {
        this.storeManagersCount = storeManagersCount;
    }
}
