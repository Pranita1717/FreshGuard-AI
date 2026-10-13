package com.freshguardai.controller;

import com.freshguardai.dto.ProductRequest;
import com.freshguardai.model.Product;
import com.freshguardai.model.Role;
import com.freshguardai.security.CustomUserDetails;
import com.freshguardai.service.ProductService;
import jakarta.validation.Valid;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping({"/api/products","/api/manager/products"})
@PreAuthorize("hasAnyRole('STORE_MANAGER','EMPLOYEE')")
public class ProductController {
    private final ProductService productService;
    public ProductController(ProductService productService){this.productService=productService;}
    @GetMapping public ResponseEntity<List<Product>> getAllProducts(@AuthenticationPrincipal CustomUserDetails u){return ResponseEntity.ok(productService.getAllProducts(u.getUser().getStoreName()));}
    @GetMapping("/{id}") public ResponseEntity<Product> getProductById(@PathVariable String id,@AuthenticationPrincipal CustomUserDetails u){return ResponseEntity.ok(productService.getProductById(id,u.getUser().getStoreName()));}
    @GetMapping("/barcode/{barcode}") public ResponseEntity<Product> getProductByBarcode(@PathVariable String barcode,@AuthenticationPrincipal CustomUserDetails u){return ResponseEntity.ok(productService.getProductByBarcode(barcode,u.getUser().getStoreName()));}
    @PostMapping @PreAuthorize("hasRole('STORE_MANAGER')") public ResponseEntity<Product> createProduct(@Valid @RequestBody ProductRequest request,@AuthenticationPrincipal CustomUserDetails u){Product p=productService.createProduct(request,u.getUsername(),Role.STORE_MANAGER,u.getUser().getStoreName());return new ResponseEntity<>(p,HttpStatus.CREATED);}
    @PutMapping("/{id}") @PreAuthorize("hasRole('STORE_MANAGER')") public ResponseEntity<Product> updateProduct(@PathVariable String id,@Valid @RequestBody ProductRequest request,@AuthenticationPrincipal CustomUserDetails u){return ResponseEntity.ok(productService.updateProduct(id,request,u.getUsername(),Role.STORE_MANAGER,u.getUser().getStoreName()));}
    @DeleteMapping("/{id}") @PreAuthorize("hasRole('STORE_MANAGER')") public ResponseEntity<Void> deleteProduct(@PathVariable String id,@AuthenticationPrincipal CustomUserDetails u){productService.deleteProduct(id,u.getUsername(),Role.STORE_MANAGER,u.getUser().getStoreName());return ResponseEntity.noContent().build();}
    @PutMapping("/{id}/expiry") public ResponseEntity<Product> updateExpiryDate(@PathVariable String id,@RequestBody Map<String,Object> body,@AuthenticationPrincipal CustomUserDetails u){String s=(String)body.get("expiryDate");if(s==null||s.isBlank())return ResponseEntity.badRequest().build();LocalDate d=LocalDate.parse(s.trim());return ResponseEntity.ok(productService.updateExpiryDate(id,d,(String)body.get("ocrText"),u.getUsername(),u.getUser().getRole(),u.getUser().getStoreName()));}
}
