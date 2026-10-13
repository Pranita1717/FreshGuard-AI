package com.freshguardai.controller;

import com.freshguardai.dto.AdminAnalyticsResponse;
import com.freshguardai.dto.SystemHealthResponse;
import com.freshguardai.model.LoginLog;
import com.freshguardai.model.SystemLog;
import com.freshguardai.service.AdminService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/admin")
@PreAuthorize("hasRole('ADMIN')")
public class AdminController {

    private final AdminService adminService;

    public AdminController(AdminService adminService) {
        this.adminService = adminService;
    }

    @GetMapping("/analytics")
    public ResponseEntity<AdminAnalyticsResponse> getAnalytics() {
        return ResponseEntity.ok(adminService.getAnalytics());
    }

    @GetMapping("/system-health")
    public ResponseEntity<SystemHealthResponse> getSystemHealth() {
        return ResponseEntity.ok(adminService.getSystemHealth());
    }

    @GetMapping("/login-activity")
    public ResponseEntity<List<LoginLog>> getLoginActivity() {
        return ResponseEntity.ok(adminService.getRecentLoginActivity());
    }

    @GetMapping("/system-logs")
    public ResponseEntity<List<SystemLog>> getSystemLogs() {
        return ResponseEntity.ok(adminService.getSystemLogs());
    }
}
