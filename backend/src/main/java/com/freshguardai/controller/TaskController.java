package com.freshguardai.controller;

import com.freshguardai.model.*;
import com.freshguardai.security.CustomUserDetails;
import com.freshguardai.service.TaskService;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.*;
import java.time.LocalDateTime;

@RestController
@RequestMapping("/api/tasks")
@PreAuthorize("hasAnyRole('STORE_MANAGER','EMPLOYEE')")
public class TaskController {
    private final TaskService service;
    public TaskController(TaskService s) { service = s; }

    @GetMapping
    public ResponseEntity<List<Task>> getTasks(@AuthenticationPrincipal CustomUserDetails u) {
        if (u.getUser().getRole() == Role.EMPLOYEE) {
            return ResponseEntity.ok(service.getTasksForUser(u.getUsername(), u.getUser().getStoreName()));
        }
        return ResponseEntity.ok(service.getTasksForStore(u.getUser().getStoreName()));
    }

    @GetMapping("/employees")
    @PreAuthorize("hasRole('STORE_MANAGER')")
    public ResponseEntity<List<User>> getConnectedEmployees(@AuthenticationPrincipal CustomUserDetails u) {
        return ResponseEntity.ok(service.getEmployeesForStore(u.getUser().getStoreName()));
    }

    @PostMapping
    @PreAuthorize("hasRole('STORE_MANAGER')")
    public ResponseEntity<Task> create(@RequestBody Map<String,Object> b, @AuthenticationPrincipal CustomUserDetails u) {
        Priority p = b.get("priority") != null ? Priority.valueOf(b.get("priority").toString()) : Priority.MEDIUM;
        Task t = service.createTask(
                (String)b.get("title"),
                (String)b.get("description"),
                (String)b.get("assignedTo"),
                (String)b.get("productId"),
                p,
                u.getUser().getStoreName(),
                (String)b.get("taskType"),
                u.getUsername(),
                b.get("dueDate") != null && !b.get("dueDate").toString().isBlank() ? LocalDateTime.parse(b.get("dueDate").toString()) : null);
        return new ResponseEntity<>(t, HttpStatus.CREATED);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Task> update(@PathVariable String id, @RequestBody Map<String,String> b, @AuthenticationPrincipal CustomUserDetails u) {
        return ResponseEntity.ok(service.updateTaskStatus(id, b.get("status"), u.getUsername(), u.getUser().getStoreName(), u.getUser().getRole()));
    }

    @PutMapping("/{id}/complete")
    public ResponseEntity<Task> complete(@PathVariable String id, @AuthenticationPrincipal CustomUserDetails u) {
        return ResponseEntity.ok(service.completeTask(id, u.getUsername(), u.getUser().getStoreName(), u.getUser().getRole()));
    }
}
