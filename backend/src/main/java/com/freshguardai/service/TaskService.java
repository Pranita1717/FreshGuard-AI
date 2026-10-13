package com.freshguardai.service;

import com.freshguardai.exception.BadRequestException;
import com.freshguardai.exception.ResourceNotFoundException;
import com.freshguardai.model.*;
import com.freshguardai.repository.TaskRepository;
import com.freshguardai.repository.UserRepository;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;
import java.util.List;

@Service
public class TaskService {
    private final TaskRepository taskRepository;
    private final NotificationService notificationService;
    private final UserRepository userRepository;
    private final ProductService productService;

    public TaskService(TaskRepository taskRepository, NotificationService notificationService, UserRepository userRepository, ProductService productService) {
        this.taskRepository = taskRepository;
        this.notificationService = notificationService;
        this.userRepository = userRepository;
        this.productService = productService;
    }

    public List<User> getEmployeesForStore(String storeName) {
        if (storeName == null || storeName.isBlank()) return List.of();
        return userRepository.findByRoleAndStoreNameOrderByNameAsc(Role.EMPLOYEE, storeName);
    }

    public Task createTask(String title, String description, String assignedTo, String productId, Priority priority, String storeName, String taskType, String assignedBy, LocalDateTime dueDate) {
        if (title == null || title.isBlank() || assignedTo == null || assignedTo.isBlank()) {
            throw new BadRequestException("Task title and assigned employee are required");
        }
        if (storeName == null || storeName.isBlank()) throw new BadRequestException("Manager store is required");
        User employee = userRepository.findByEmail(assignedTo.trim().toLowerCase())
                .orElseThrow(() -> new BadRequestException("Assigned employee was not found"));
        if (employee.getRole() != Role.EMPLOYEE || !storeName.equals(employee.getStoreName())) {
            throw new BadRequestException("Employee must belong to the same store as the manager");
        }
        if (productId != null && !productId.isBlank()) productService.getProductById(productId, storeName);

        String normalizedType = taskType == null || taskType.isBlank() ? "OTHER" : taskType.trim().toUpperCase();
        Task task = new Task(title.trim(), description != null ? description.trim() : "", employee.getEmail(), productId, priority, storeName, normalizedType, assignedBy);
        task.setDueDate(dueDate);
        Task saved = taskRepository.save(task);
        notificationService.createNotification(
                "New Task Assigned",
                "Task: '" + title.trim() + "' assigned to you by your store manager.",
                "TASK_ASSIGNED", productId, employee.getId(), storeName);
        return saved;
    }

    public List<Task> getTasksForStore(String storeName) {
        return taskRepository.findByStoreNameOrderByCreatedAtDesc(storeName);
    }

    public List<Task> getTasksForUser(String assignedTo, String storeName) {
        return taskRepository.findByAssignedToAndStoreNameOrderByCreatedAtDesc(assignedTo, storeName);
    }

    private Task owned(String id, String email, String storeName, Role role) {
        Task t = taskRepository.findById(id).orElseThrow(() -> new ResourceNotFoundException("Task not found"));
        if (!storeName.equals(t.getStoreName())) throw new ResourceNotFoundException("Task not found");
        if (role == Role.EMPLOYEE && !email.equals(t.getAssignedTo())) throw new ResourceNotFoundException("Task not found");
        return t;
    }

    public Task updateTaskStatus(String id, String status, String email, String storeName, Role role) {
        if (status == null || !(status.equals("PENDING") || status.equals("IN_PROGRESS") || status.equals("COMPLETED"))) {
            throw new BadRequestException("Invalid task status");
        }
        Task t = owned(id, email, storeName, role);
        t.setStatus(status);
        t.setUpdatedAt(LocalDateTime.now());
        if ("COMPLETED".equals(status)) t.setCompletedAt(LocalDateTime.now());
        return taskRepository.save(t);
    }

    public Task completeTask(String id, String email, String storeName, Role role) {
        return updateTaskStatus(id, "COMPLETED", email, storeName, role);
    }
}
