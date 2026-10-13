package com.freshguardai.controller;
import com.freshguardai.model.Notification;
import com.freshguardai.security.CustomUserDetails;
import com.freshguardai.service.NotificationService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.*;
@RestController @RequestMapping("/api/notifications") @PreAuthorize("hasAnyRole('STORE_MANAGER','EMPLOYEE')")
public class NotificationController {
 private final NotificationService service; public NotificationController(NotificationService s){service=s;}
 @GetMapping public ResponseEntity<List<Notification>> get(@AuthenticationPrincipal CustomUserDetails u){return ResponseEntity.ok(service.getNotificationsForUser(u.getUser().getId(),u.getUser().getStoreName()));}
 @PutMapping("/{id}/read") public ResponseEntity<Notification> read(@PathVariable String id,@AuthenticationPrincipal CustomUserDetails u){return ResponseEntity.ok(service.markAsRead(id,u.getUser().getId(),u.getUser().getStoreName()));}
 @PutMapping("/read-all") public ResponseEntity<Map<String,String>> readAll(@AuthenticationPrincipal CustomUserDetails u){service.markAllAsRead(u.getUser().getId(),u.getUser().getStoreName());return ResponseEntity.ok(Map.of("message","Your store notifications marked as read"));}
}
