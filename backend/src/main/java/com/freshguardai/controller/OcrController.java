package com.freshguardai.controller;

import com.freshguardai.dto.OcrResponse;
import com.freshguardai.service.OcrService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

@RestController
@RequestMapping("/api/ocr")
public class OcrController {

    private final OcrService ocrService;

    public OcrController(OcrService ocrService) {
        this.ocrService = ocrService;
    }

    @PostMapping({"/expiry", "/extract"})
    @PreAuthorize("hasAnyRole('STORE_MANAGER', 'EMPLOYEE')")
    public ResponseEntity<OcrResponse> extractExpiryDate(
            @RequestParam(value = "image", required = false) MultipartFile image,
            @RequestParam(value = "text", required = false) String text,
            @RequestBody(required = false) Map<String, String> body) {

        String manualText = text;
        if (manualText == null && body != null && body.containsKey("text")) {
            manualText = body.get("text");
        }

        OcrResponse response = ocrService.processImage(image, manualText);
        return ResponseEntity.ok(response);
    }
}
