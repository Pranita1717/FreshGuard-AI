package com.freshguardai.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;

@Document(collection = "system_logs")
public class SystemLog {

    @Id
    private String id;

    private String event;

    private String description;

    private String severity; // INFO, WARN, ERROR

    private LocalDateTime timestamp = LocalDateTime.now();

    public SystemLog() {
    }

    public SystemLog(String event, String description, String severity) {
        this.event = event;
        this.description = description;
        this.severity = severity;
        this.timestamp = LocalDateTime.now();
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getEvent() {
        return event;
    }

    public void setEvent(String event) {
        this.event = event;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getSeverity() {
        return severity;
    }

    public void setSeverity(String severity) {
        this.severity = severity;
    }

    public LocalDateTime getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(LocalDateTime timestamp) {
        this.timestamp = timestamp;
    }
}
