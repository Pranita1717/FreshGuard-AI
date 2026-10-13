package com.freshguardai.service;

import com.freshguardai.model.*;
import com.freshguardai.repository.InventoryLogRepository;
import com.lowagie.text.Document;
import com.lowagie.text.Element;
import com.lowagie.text.Font;
import com.lowagie.text.FontFactory;
import com.lowagie.text.PageSize;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Phrase;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import org.springframework.stereotype.Service;
import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class ReportService {
    private final InventoryLogRepository inventoryLogRepository; private final ProductService productService;
    public ReportService(InventoryLogRepository inventoryLogRepository,ProductService productService){this.inventoryLogRepository=inventoryLogRepository;this.productService=productService;}
    public Map<String,Object> getReportData(String type,String storeName){
        Map<String,Object> report=new HashMap<>();java.util.List<Product> products=productService.getAllProducts(storeName);String t=type!=null?type.toUpperCase():"SUMMARY";report.put("generatedAt",LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));report.put("reportType",t);report.put("storeName",storeName);
        switch(t){
            case "INVENTORY"->{report.put("title","Store Inventory Report");report.put("totalProducts",products.size());report.put("totalQuantity",products.stream().mapToInt(p->p.getQuantity()!=null?p.getQuantity():0).sum());report.put("items",products);}
            case "EXPIRY"->{java.util.List<Product> risk=products.stream().filter(p->p.getExpiryStatus()==ProductStatus.EXPIRED||p.getExpiryStatus()==ProductStatus.CRITICAL||p.getExpiryStatus()==ProductStatus.NEAR_EXPIRY).collect(Collectors.toList());report.put("title","Food Expiry Risk Report");report.put("totalRiskProducts",risk.size());report.put("items",risk);}
            case "LOW_STOCK"->{java.util.List<Product> low=products.stream().filter(p->p.getQuantity()!=null&&p.getMinimumStock()!=null&&p.getQuantity()<=p.getMinimumStock()).collect(Collectors.toList());report.put("title","Low Stock Report");report.put("totalLowStockProducts",low.size());report.put("items",low);}
            case "REMOVED_EXPIRED"->{java.util.List<InventoryLog> logs=inventoryLogRepository.findByActionAndStoreName("REMOVE_EXPIRED",storeName);report.put("title","Removed Expired Stock Audit");report.put("totalRemovalIncidents",logs.size());report.put("logs",logs);}
            default->{report.put("title","FreshGuard Store Operational Summary");report.put("totalProducts",products.size());report.put("totalQuantity",products.stream().mapToInt(p->p.getQuantity()!=null?p.getQuantity():0).sum());report.put("expiredCount",products.stream().filter(p->p.getExpiryStatus()==ProductStatus.EXPIRED).count());report.put("criticalCount",products.stream().filter(p->p.getExpiryStatus()==ProductStatus.CRITICAL).count());report.put("nearExpiryCount",products.stream().filter(p->p.getExpiryStatus()==ProductStatus.NEAR_EXPIRY).count());report.put("safeCount",products.stream().filter(p->p.getExpiryStatus()==ProductStatus.SAFE).count());report.put("lowStockCount",products.stream().filter(p->p.getQuantity()!=null&&p.getMinimumStock()!=null&&p.getQuantity()<=p.getMinimumStock()).count());}
        } return report;
    }
    public byte[] generatePdfReport(String type,String storeName){
        try(ByteArrayOutputStream out=new ByteArrayOutputStream()){
            Document document=new Document(PageSize.A4,36,36,36,36);PdfWriter.getInstance(document,out);document.open();
            Color green=new Color(22,139,69), light=new Color(245,245,245);Font title=FontFactory.getFont(FontFactory.HELVETICA_BOLD,18,green), sub=FontFactory.getFont(FontFactory.HELVETICA,10,Color.DARK_GRAY), header=FontFactory.getFont(FontFactory.HELVETICA_BOLD,8,Color.WHITE), body=FontFactory.getFont(FontFactory.HELVETICA,8,Color.BLACK);
            Paragraph h=new Paragraph("FRESHGUARD",title);h.setAlignment(Element.ALIGN_CENTER);document.add(h);Paragraph s=new Paragraph("Store: "+storeName+" | Report: "+(type==null?"SUMMARY":type.toUpperCase())+" | "+LocalDateTime.now().format(DateTimeFormatter.ofPattern("dd-MM-yyyy HH:mm:ss")),sub);s.setAlignment(Element.ALIGN_CENTER);s.setSpacingAfter(15);document.add(s);
            java.util.List<Product> products=productService.getAllProducts(storeName);
            if("REMOVED_EXPIRED".equalsIgnoreCase(type)){
                java.util.List<InventoryLog> logs=inventoryLogRepository.findByActionAndStoreName("REMOVE_EXPIRED",storeName);PdfPTable table=new PdfPTable(6);table.setWidthPercentage(100);String[] hs={"Timestamp","Product","Qty","By","Role","Reason"};for(String x:hs){PdfPCell c=new PdfPCell(new Phrase(x,header));c.setBackgroundColor(green);c.setPadding(5);table.addCell(c);}for(InventoryLog l:logs){table.addCell(new Phrase(l.getTimestamp().format(DateTimeFormatter.ofPattern("dd/MM HH:mm")),body));table.addCell(new Phrase(n(l.getProductName()),body));table.addCell(new Phrase(String.valueOf(Math.abs(l.getChangedQuantity()!=null?l.getChangedQuantity():0)),body));table.addCell(new Phrase(n(l.getPerformedBy()),body));table.addCell(new Phrase(l.getPerformedByRole()!=null?l.getPerformedByRole().name():"-",body));table.addCell(new Phrase(n(l.getReason()),body));}document.add(table);
            }else{
                java.util.List<Product> list=products;if("EXPIRY".equalsIgnoreCase(type))list=products.stream().filter(p->p.getExpiryStatus()!=ProductStatus.SAFE).collect(Collectors.toList());else if("LOW_STOCK".equalsIgnoreCase(type))list=products.stream().filter(p->p.getQuantity()!=null&&p.getMinimumStock()!=null&&p.getQuantity()<=p.getMinimumStock()).collect(Collectors.toList());
                PdfPTable table=new PdfPTable(7);table.setWidthPercentage(100);String[] hs={"Barcode","Product","Category","Qty","Price","Expiry","Status"};for(String x:hs){PdfPCell c=new PdfPCell(new Phrase(x,header));c.setBackgroundColor(green);c.setPadding(5);table.addCell(c);}int i=0;for(Product p:list){Color bg=i++%2==0?Color.WHITE:light;cell(table,p.getBarcode(),body,bg);cell(table,p.getName(),body,bg);cell(table,p.getCategory(),body,bg);cell(table,String.valueOf(p.getQuantity()),body,bg);cell(table,String.format("%.2f",p.getPrice()!=null?p.getPrice():0),body,bg);cell(table,p.getExpiryDate()!=null?p.getExpiryDate().toString():"N/A",body,bg);cell(table,p.getExpiryStatus()!=null?p.getExpiryStatus().name():"SAFE",body,bg);}document.add(table);
            }
            document.add(new Paragraph("Total records: "+products.size(),sub));document.close();return out.toByteArray();
        }catch(Exception e){throw new RuntimeException("Failed to generate PDF report",e);}
    }
    private void cell(PdfPTable t,String v,Font f,Color bg){PdfPCell c=new PdfPCell(new Phrase(n(v),f));c.setBackgroundColor(bg);c.setPadding(4);t.addCell(c);}private String n(String v){return v==null?"-":v;}
}
