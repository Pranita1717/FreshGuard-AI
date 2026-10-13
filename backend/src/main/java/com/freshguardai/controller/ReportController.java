package com.freshguardai.controller;
import com.freshguardai.security.CustomUserDetails;
import com.freshguardai.service.ReportService;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.Map;
@RestController @RequestMapping("/api/reports") @PreAuthorize("hasRole('STORE_MANAGER')")
public class ReportController {
 private final ReportService service; public ReportController(ReportService s){service=s;}
 @GetMapping public ResponseEntity<Map<String,Object>> get(@RequestParam(defaultValue="SUMMARY") String type,@AuthenticationPrincipal CustomUserDetails u){return ResponseEntity.ok(service.getReportData(type,u.getUser().getStoreName()));}
 @PostMapping public ResponseEntity<Map<String,Object>> generate(@RequestBody(required=false) Map<String,String> body,@AuthenticationPrincipal CustomUserDetails u){String type=body!=null&&body.containsKey("type")?body.get("type"):"SUMMARY";return ResponseEntity.ok(service.getReportData(type,u.getUser().getStoreName()));}
 @GetMapping("/pdf") public ResponseEntity<byte[]> pdf(@RequestParam(defaultValue="SUMMARY") String type,@AuthenticationPrincipal CustomUserDetails u){byte[] bytes=service.generatePdfReport(type,u.getUser().getStoreName());HttpHeaders h=new HttpHeaders();h.setContentType(MediaType.APPLICATION_PDF);h.setContentDisposition(ContentDisposition.attachment().filename("freshguard-"+type.toLowerCase()+"-report.pdf").build());return ResponseEntity.ok().headers(h).body(bytes);}
}
