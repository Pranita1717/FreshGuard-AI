package com.freshguardai.service;
import com.freshguardai.model.Product;
import org.springframework.stereotype.Service;
@Service public class BarcodeService { private final ProductService productService; public BarcodeService(ProductService p){productService=p;} public Product lookupByBarcode(String barcode,String storeName){return productService.getProductByBarcode(barcode,storeName);} }
