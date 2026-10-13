package com.freshguardai.dto;

import java.time.LocalDate;

public class OcrResponse {

    private String extractedDate;
    private String rawText;
    private Double confidence;
    private String dateType; // EXPIRY, MFG, BEST_BEFORE
    private LocalDate detectedExpiryDate;
    private String status; // SUCCESS, MANUAL_VERIFICATION_REQUIRED, NO_DATE_FOUND
    private String message;

    public OcrResponse() {
    }

    public OcrResponse(String extractedDate, String rawText, Double confidence, String dateType,
                       LocalDate detectedExpiryDate, String status, String message) {
        this.extractedDate = extractedDate;
        this.rawText = rawText;
        this.confidence = confidence;
        this.dateType = dateType;
        this.detectedExpiryDate = detectedExpiryDate;
        this.status = status;
        this.message = message;
    }

    public String getExtractedDate() {
        return extractedDate;
    }

    public void setExtractedDate(String extractedDate) {
        this.extractedDate = extractedDate;
    }

    public String getRawText() {
        return rawText;
    }

    public void setRawText(String rawText) {
        this.rawText = rawText;
    }

    public Double getConfidence() {
        return confidence;
    }

    public void setConfidence(Double confidence) {
        this.confidence = confidence;
    }

    public String getDateType() {
        return dateType;
    }

    public void setDateType(String dateType) {
        this.dateType = dateType;
    }

    public LocalDate getDetectedExpiryDate() {
        return detectedExpiryDate;
    }

    public void setDetectedExpiryDate(LocalDate detectedExpiryDate) {
        this.detectedExpiryDate = detectedExpiryDate;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }
}
