package com.freshguardai.dto;

import java.time.LocalDateTime;

public class SystemHealthResponse {

    private String serverStatus;
    private String mongoStatus;
    private long jvmMemoryUsedMb;
    private long jvmMemoryMaxMb;
    private long jvmMemoryTotalMb;
    private long uptimeSeconds;
    private int activeThreads;
    private String javaVersion;
    private String springBootVersion;
    private LocalDateTime timestamp = LocalDateTime.now();

    public SystemHealthResponse() {
    }

    public String getServerStatus() {
        return serverStatus;
    }

    public void setServerStatus(String serverStatus) {
        this.serverStatus = serverStatus;
    }

    public String getMongoStatus() {
        return mongoStatus;
    }

    public void setMongoStatus(String mongoStatus) {
        this.mongoStatus = mongoStatus;
    }

    public long getJvmMemoryUsedMb() {
        return jvmMemoryUsedMb;
    }

    public void setJvmMemoryUsedMb(long jvmMemoryUsedMb) {
        this.jvmMemoryUsedMb = jvmMemoryUsedMb;
    }

    public long getJvmMemoryMaxMb() {
        return jvmMemoryMaxMb;
    }

    public void setJvmMemoryMaxMb(long jvmMemoryMaxMb) {
        this.jvmMemoryMaxMb = jvmMemoryMaxMb;
    }

    public long getJvmMemoryTotalMb() {
        return jvmMemoryTotalMb;
    }

    public void setJvmMemoryTotalMb(long jvmMemoryTotalMb) {
        this.jvmMemoryTotalMb = jvmMemoryTotalMb;
    }

    public long getUptimeSeconds() {
        return uptimeSeconds;
    }

    public void setUptimeSeconds(long uptimeSeconds) {
        this.uptimeSeconds = uptimeSeconds;
    }

    public int getActiveThreads() {
        return activeThreads;
    }

    public void setActiveThreads(int activeThreads) {
        this.activeThreads = activeThreads;
    }

    public String getJavaVersion() {
        return javaVersion;
    }

    public void setJavaVersion(String javaVersion) {
        this.javaVersion = javaVersion;
    }

    public String getSpringBootVersion() {
        return springBootVersion;
    }

    public void setSpringBootVersion(String springBootVersion) {
        this.springBootVersion = springBootVersion;
    }

    public LocalDateTime getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(LocalDateTime timestamp) {
        this.timestamp = timestamp;
    }
}
