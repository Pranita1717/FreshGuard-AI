package com.freshguardai.controller;
import com.freshguardai.dto.InventoryUpdateRequest;
import com.freshguardai.model.*;
import com.freshguardai.security.CustomUserDetails;
import com.freshguardai.service.*;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;
@RestController @RequestMapping({"/api/inventory","/api/manager/inventory"}) @PreAuthorize("hasAnyRole('STORE_MANAGER','EMPLOYEE')")
public class InventoryController {
 private final InventoryService inventoryService; private final ProductService productService;
 public InventoryController(InventoryService i,ProductService p){inventoryService=i;productService=p;}
 @GetMapping public ResponseEntity<List<Product>> getInventory(@AuthenticationPrincipal CustomUserDetails u){return ResponseEntity.ok(productService.getAllProducts(u.getUser().getStoreName()));}
 @GetMapping("/restocking") public ResponseEntity<List<Map<String,Object>>> getRestocking(@AuthenticationPrincipal CustomUserDetails u){return ResponseEntity.ok(inventoryService.getRestockingData(u.getUser().getStoreName()));}
 @GetMapping("/{id}") public ResponseEntity<Product> getInventoryItem(@PathVariable String id,@AuthenticationPrincipal CustomUserDetails u){return ResponseEntity.ok(productService.getProductById(id,u.getUser().getStoreName()));}
 @PutMapping("/{id}") public ResponseEntity<Product> updateInventory(@PathVariable String id,@Valid @RequestBody InventoryUpdateRequest req,@AuthenticationPrincipal CustomUserDetails u){return ResponseEntity.ok(inventoryService.updateInventory(id,req,u.getUsername(),u.getUser().getRole(),u.getUser().getStoreName()));}
 @PostMapping("/{id}/remove-expired") public ResponseEntity<Product> removeExpired(@PathVariable String id,@RequestBody Map<String,Object> body,@AuthenticationPrincipal CustomUserDetails u){int q=body.get("quantity")!=null?Integer.parseInt(body.get("quantity").toString()):1;String reason=body.get("reason")!=null?body.get("reason").toString():"Safe removal of expired goods";return ResponseEntity.ok(inventoryService.removeExpired(id,q,reason,u.getUsername(),u.getUser().getRole(),u.getUser().getStoreName()));}
 @GetMapping("/logs") public ResponseEntity<List<InventoryLog>> getInventoryLogs(@AuthenticationPrincipal CustomUserDetails u){return ResponseEntity.ok(inventoryService.getInventoryLogs(u.getUser().getStoreName()));}
}
