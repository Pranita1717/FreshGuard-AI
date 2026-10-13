package com.freshguardai.controller;
import com.freshguardai.model.Product;
import com.freshguardai.security.CustomUserDetails;
import com.freshguardai.service.BarcodeService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
@RestController @RequestMapping("/api/barcode") @PreAuthorize("hasAnyRole('STORE_MANAGER','EMPLOYEE')")
public class BarcodeController {
 private final BarcodeService service; public BarcodeController(BarcodeService s){service=s;}
 @GetMapping("/{barcode}") public ResponseEntity<Product> scan(@PathVariable String barcode,@AuthenticationPrincipal CustomUserDetails u){return ResponseEntity.ok(service.lookupByBarcode(barcode,u.getUser().getStoreName()));}
}
