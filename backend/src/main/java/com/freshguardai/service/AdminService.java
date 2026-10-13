package com.freshguardai.service;

import com.freshguardai.dto.AdminAnalyticsResponse;
import com.freshguardai.dto.SystemHealthResponse;
import com.freshguardai.model.LoginLog;
import com.freshguardai.model.Role;
import com.freshguardai.model.SystemLog;
import com.freshguardai.repository.*;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.stereotype.Service;

import java.lang.management.ManagementFactory;
import java.time.LocalDateTime;
import java.util.List;

@Service
public class AdminService {

    private final UserRepository userRepository;
    private final LoginLogRepository loginLogRepository;
    private final DiscountRepository discountRepository;
    private final TaskRepository taskRepository;
    private final SystemLogRepository systemLogRepository;
    private final MongoTemplate mongoTemplate;

    public AdminService(UserRepository userRepository,
                        LoginLogRepository loginLogRepository,
                        DiscountRepository discountRepository,
                        TaskRepository taskRepository,
                        SystemLogRepository systemLogRepository,
                        MongoTemplate mongoTemplate) {
        this.userRepository = userRepository;
        this.loginLogRepository = loginLogRepository;
        this.discountRepository = discountRepository;
        this.taskRepository = taskRepository;
        this.systemLogRepository = systemLogRepository;
        this.mongoTemplate = mongoTemplate;
    }

    public AdminAnalyticsResponse getAnalytics() {
        AdminAnalyticsResponse response = new AdminAnalyticsResponse();

        response.setTotalRegisteredUsers(userRepository.count());
        response.setActiveUsers(userRepository.countByActive(true));
        response.setEmployeesCount(userRepository.countByRole(Role.EMPLOYEE));
        response.setStoreManagersCount(userRepository.countByRole(Role.STORE_MANAGER));

        long totalLogins = loginLogRepository.count();
        long successfulLogins = loginLogRepository.countBySuccess(true);
        long failedLogins = loginLogRepository.countBySuccess(false);

        response.setTotalLoginAttempts(totalLogins);
        response.setSuccessfulLogins(successfulLogins);
        response.setFailedLoginAttempts(failedLogins);

        // Admin intentionally sees application-level telemetry only, not store inventory details.
        response.setTotalProducts(0);
        response.setTotalInventoryQuantity(0);
        response.setExpiredProducts(0);
        response.setCriticalProducts(0);
        response.setNearExpiryProducts(0);
        response.setSafeProducts(0);
        response.setLowStockProducts(0);

        response.setTotalDiscounts(discountRepository.count());
        response.setPendingDiscounts(discountRepository.findByStatus("PENDING").size());

        response.setOpenTasks(taskRepository.findByStatus("PENDING").size() + taskRepository.findByStatus("IN_PROGRESS").size());
        response.setCompletedTasks(taskRepository.findByStatus("COMPLETED").size());

        return response;
    }

    public SystemHealthResponse getSystemHealth() {
        SystemHealthResponse health = new SystemHealthResponse();
        health.setServerStatus("UP");

        try {
            mongoTemplate.getDb().runCommand(new org.bson.Document("ping", 1));
            health.setMongoStatus("CONNECTED (Healthy)");
        } catch (Exception e) {
            health.setMongoStatus("DISCONNECTED (" + e.getMessage() + ")");
        }

        Runtime runtime = Runtime.getRuntime();
        long totalMemory = runtime.totalMemory() / (1024 * 1024);
        long freeMemory = runtime.freeMemory() / (1024 * 1024);
        long maxMemory = runtime.maxMemory() / (1024 * 1024);
        long usedMemory = totalMemory - freeMemory;

        health.setJvmMemoryUsedMb(usedMemory);
        health.setJvmMemoryTotalMb(totalMemory);
        health.setJvmMemoryMaxMb(maxMemory);
        health.setUptimeSeconds(ManagementFactory.getRuntimeMXBean().getUptime() / 1000);
        health.setActiveThreads(Thread.activeCount());
        health.setJavaVersion(System.getProperty("java.version"));
        health.setSpringBootVersion("3.3.4");
        health.setTimestamp(LocalDateTime.now());

        return health;
    }

    public List<LoginLog> getRecentLoginActivity() {
        return loginLogRepository.findAllByOrderByTimestampDesc();
    }

    public List<SystemLog> getSystemLogs() {
        return systemLogRepository.findTop50ByOrderByTimestampDesc();
    }
}
