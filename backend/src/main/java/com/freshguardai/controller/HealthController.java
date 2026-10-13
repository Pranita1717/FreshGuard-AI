package com.freshguardai.controller;

import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/health")
public class HealthController {

    private final MongoTemplate mongoTemplate;

    public HealthController(MongoTemplate mongoTemplate) {
        this.mongoTemplate = mongoTemplate;
    }

    @GetMapping
    public ResponseEntity<Map<String, Object>> checkHealth() {
        Map<String, Object> health = new HashMap<>();
        health.put("status", "UP");
        health.put("service", "FreshGuard Backend");
        health.put("timestamp", LocalDateTime.now().toString());

        try {
            mongoTemplate.getDb().runCommand(new org.bson.Document("ping", 1));
            health.put("database", "CONNECTED");
            health.put("databaseType", "MongoDB");
        } catch (Exception e) {
            health.put("database", "DOWN: " + e.getMessage());
        }

        return ResponseEntity.ok(health);
    }
}
