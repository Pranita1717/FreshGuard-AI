package com.freshguardai.controller;

import com.freshguardai.dto.LoginRequest;
import com.freshguardai.dto.LoginResponse;
import com.freshguardai.dto.RegisterRequest;
import com.freshguardai.service.UserService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final UserService userService;

    public AuthController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(@Valid @RequestBody LoginRequest request,
                                               HttpServletRequest servletRequest) {
        String clientIp = servletRequest.getRemoteAddr();
        LoginResponse response = userService.login(request, clientIp);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/register")
    public ResponseEntity<LoginResponse> register(@Valid @RequestBody RegisterRequest request) {
        LoginResponse response = userService.register(request);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/me")
    public ResponseEntity<java.util.Map<String, Object>> getProfile(@org.springframework.security.core.annotation.AuthenticationPrincipal com.freshguardai.security.CustomUserDetails userDetails) {
        if (userDetails == null) {
            return ResponseEntity.status(401).build();
        }
        com.freshguardai.model.User user = userDetails.getUser();
        java.util.Map<String, Object> map = new java.util.HashMap<>();
        map.put("id", user.getId());
        map.put("name", user.getName());
        map.put("email", user.getEmail());
        map.put("phone", user.getPhone());
        map.put("role", user.getRole().name());
        map.put("storeName", user.getStoreName());
        map.put("createdAt", user.getCreatedAt());
        return ResponseEntity.ok(map);
    }

    @PutMapping("/profile")
    public ResponseEntity<java.util.Map<String, Object>> updateProfile(
            @RequestBody java.util.Map<String, String> body,
            @org.springframework.security.core.annotation.AuthenticationPrincipal com.freshguardai.security.CustomUserDetails userDetails) {
        if (userDetails == null) {
            return ResponseEntity.status(401).build();
        }
        String name = body.get("name");
        String phone = body.get("phone");
        String storeName = body.get("storeName");

        com.freshguardai.model.User updated = userService.updateProfile(userDetails.getUsername(), name, phone, storeName);
        java.util.Map<String, Object> map = new java.util.HashMap<>();
        map.put("id", updated.getId());
        map.put("name", updated.getName());
        map.put("email", updated.getEmail());
        map.put("phone", updated.getPhone());
        map.put("role", updated.getRole().name());
        map.put("storeName", updated.getStoreName());
        return ResponseEntity.ok(map);
    }
}
