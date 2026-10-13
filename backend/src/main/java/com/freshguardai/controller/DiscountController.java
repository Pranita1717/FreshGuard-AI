package com.freshguardai.controller;
import com.freshguardai.model.Discount;
import com.freshguardai.security.CustomUserDetails;
import com.freshguardai.service.DiscountService;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.*;
@RestController @RequestMapping("/api/discounts") @PreAuthorize("hasRole('STORE_MANAGER')")
public class DiscountController {
 private final DiscountService service; public DiscountController(DiscountService s){service=s;}
 @GetMapping public ResponseEntity<List<Discount>> getAll(@AuthenticationPrincipal CustomUserDetails u){return ResponseEntity.ok(service.getAllDiscounts(u.getUser().getStoreName()));}
 @GetMapping("/suggestions") public ResponseEntity<List<Map<String,Object>>> suggestions(@AuthenticationPrincipal CustomUserDetails u){return ResponseEntity.ok(service.getDiscountSuggestions(u.getUser().getStoreName()));}
 @PostMapping public ResponseEntity<Discount> create(@RequestBody Map<String,Object> b,@AuthenticationPrincipal CustomUserDetails u){String pid=(String)b.get("productId");Double pct=Double.valueOf(b.get("percentage").toString());String reason=b.get("reason")!=null?b.get("reason").toString():"Store markdown";return new ResponseEntity<>(service.createDiscount(pid,pct,reason,u.getUsername(),u.getUser().getStoreName()),HttpStatus.CREATED);}
 @PutMapping("/{id}/approve") public ResponseEntity<Discount> approve(@PathVariable String id,@AuthenticationPrincipal CustomUserDetails u){return ResponseEntity.ok(service.approveDiscount(id,u.getUsername(),u.getUser().getStoreName()));}
 @PutMapping("/{id}/reject") public ResponseEntity<Discount> reject(@PathVariable String id,@AuthenticationPrincipal CustomUserDetails u){return ResponseEntity.ok(service.rejectDiscount(id,u.getUsername(),u.getUser().getStoreName()));}
}
