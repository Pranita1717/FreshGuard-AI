# FreshGuard AI — REST API Specification & Reference

**Base URL**: `http://localhost:8080/api`  
**Authentication**: Bearer Token in `Authorization: Bearer <jwt_token>` header for all protected routes.

---

## 1. Authentication Endpoints

### 1.1 User Login
- **URL**: `POST /auth/login`
- **Access**: Public
- **Request Body**:
```json
{
  "email": "manager@freshguard.local",
  "password": "Manager@123"
}
```
- **Response (200 OK)**:
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "type": "Bearer",
  "id": "6724fa10e3b1c20...",
  "email": "manager@freshguard.local",
  "name": "Store Manager",
  "role": "STORE_MANAGER",
  "storeName": "FreshGuard Superstore #101"
}
```

### 1.2 User Registration
- **URL**: `POST /auth/register`
- **Access**: Public (Allows `STORE_MANAGER` and `EMPLOYEE`; blocks `ADMIN`)
- **Request Body**:
```json
{
  "name": "John Doe",
  "email": "john.doe@freshguard.local",
  "phone": "+91 9876543210",
  "role": "EMPLOYEE",
  "storeName": "FreshGuard West Branch",
  "password": "Password@123",
  "confirmPassword": "Password@123"
}
```
- **Response (200 OK)**:
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "type": "Bearer",
  "id": "6724fb...",
  "email": "john.doe@freshguard.local",
  "name": "John Doe",
  "role": "EMPLOYEE",
  "storeName": "FreshGuard West Branch"
}
```

### 1.3 Get Current User Profile
- **URL**: `GET /auth/me`
- **Access**: Protected (Any authenticated user)
- **Response (200 OK)**:
```json
{
  "id": "6724fa...",
  "name": "Store Manager",
  "email": "manager@freshguard.local",
  "role": "STORE_MANAGER",
  "storeName": "FreshGuard Superstore #101",
  "phone": "+91 9876543211",
  "active": true
}
```

### 1.4 Update User Profile
- **URL**: `PUT /auth/profile`
- **Access**: Protected
- **Request Body**:
```json
{
  "name": "Store Manager Sr.",
  "phone": "+91 9876543299",
  "storeName": "FreshGuard Central Store"
}
```

---

## 2. Health & Diagnostics

### 2.1 Backend & MongoDB Health Ping
- **URL**: `GET /health`
- **Access**: Public
- **Response (200 OK)**:
```json
{
  "status": "UP",
  "database": "CONNECTED",
  "databaseType": "MongoDB",
  "service": "FreshGuard AI Backend",
  "timestamp": "2026-09-27T16:00:00"
}
```

---

## 3. Administrator Endpoints

### 3.1 System Analytics & Telemetry
- **URL**: `GET /admin/analytics`
- **Access**: `ROLE_ADMIN` Only
- **Response (200 OK)**:
```json
{
  "totalUsers": 8,
  "totalProducts": 6,
  "totalInventoryLogs": 24,
  "recentLogins": 12,
  "systemStatus": "OPTIMAL"
}
```

### 3.2 Host & JVM System Health
- **URL**: `GET /admin/system-health`
- **Access**: `ROLE_ADMIN` Only
- **Response (200 OK)**:
```json
{
  "serverStatus": "UP",
  "database": "CONNECTED",
  "freeMemoryBytes": 245104640,
  "totalMemoryBytes": 536870912,
  "availableProcessors": 12
}
```

---

## 4. Product Catalog Endpoints

### 4.1 Get All Active Products
- **URL**: `GET /products`
- **Access**: Protected
- **Response (200 OK)**:
```json
[
  {
    "id": "6724fc...",
    "name": "Amul Taaza Homogenised Toned Milk",
    "barcode": "8901262010014",
    "category": "DAIRY",
    "price": 54.0,
    "quantity": 18,
    "unit": "liter",
    "minimumStock": 10,
    "manufacturingDate": "2026-09-24",
    "expiryDate": "2026-09-29",
    "expiryStatus": "CRITICAL",
    "daysUntilExpiry": 2,
    "shelfPriority": "HIGH",
    "status": "ACTIVE"
  }
]
```

### 4.2 Lookup Product by Barcode
- **URL**: `GET /products/barcode/{barcode}`
- **Access**: Protected
- **Response (200 OK)**: Single Product JSON object.

### 4.3 Create Product
- **URL**: `POST /products`
- **Access**: `ROLE_STORE_MANAGER`
- **Request Body**:
```json
{
  "name": "Organic Honey 500g",
  "barcode": "8901262099999",
  "category": "PACKAGED",
  "price": 280.0,
  "quantity": 25,
  "unit": "box",
  "minimumStock": 8,
  "manufacturingDate": "2026-08-01",
  "expiryDate": "2027-08-01"
}
```

### 4.4 Update Product
- **URL**: `PUT /products/{id}`
- **Access**: `ROLE_STORE_MANAGER`

---

## 5. Inventory & Restocking Endpoints

### 5.1 Adjust Stock / Physical Audit
- **URL**: `PUT /inventory/{id}`
- **Access**: `ROLE_STORE_MANAGER`, `ROLE_EMPLOYEE`
- **Request Body**:
```json
{
  "action": "ADD",
  "quantityChange": 10,
  "reason": "Restocked from morning delivery"
}
```

### 5.2 Deterministic Restocking Calculations
- **URL**: `GET /inventory/restocking`
- **Access**: Protected
- **Response (200 OK)**:
```json
[
  {
    "id": "6724fc...",
    "name": "Grade A Large White Eggs (6 pack)",
    "barcode": "8901262030036",
    "category": "DAIRY",
    "currentQuantity": 4,
    "minimumStock": 15,
    "suggestedRestock": 26,
    "ruleReason": "Stock (4) <= minimum buffer (15). Suggested reorder: (15 * 2) - 4 = 26 units."
  }
]
```

### 5.3 Remove Expired Product (Disposal Protocol)
- **URL**: `POST /inventory/{id}/remove-expired`
- **Access**: `ROLE_STORE_MANAGER`, `ROLE_EMPLOYEE`
- **Request Body**:
```json
{
  "quantity": 10,
  "reason": "Safe Bio-Waste Disposal"
}
```

---

## 6. Discounts & Markdowns

### 6.1 Get Rule-Based Markdown Suggestions
- **URL**: `GET /discounts/suggestions`
- **Access**: Protected
- **Response (200 OK)**:
```json
[
  {
    "productId": "6724fc...",
    "productName": "Amul Taaza Homogenised Toned Milk",
    "barcode": "8901262010014",
    "category": "DAIRY",
    "currentPrice": 54.0,
    "daysUntilExpiry": 2,
    "suggestedDiscountPercent": 50.0,
    "discountedPrice": 27.0,
    "ruleReason": "Expires in 2 days (<= 3 days threshold): Suggest 50% markdown to accelerate sales."
  }
]
```

### 6.2 Create Discount
- **URL**: `POST /discounts`
- **Access**: `ROLE_STORE_MANAGER`
- **Request Body**:
```json
{
  "productId": "6724fc...",
  "percentage": 30.0,
  "reason": "Near-expiry promotional markdown"
}
```

### 6.3 Approve / Reject Discount
- **URL**: `PUT /discounts/{id}/approve`
- **URL**: `PUT /discounts/{id}/reject`
- **Access**: `ROLE_STORE_MANAGER`

---

## 7. Reports & OpenPDF Dynamic Generation

### 7.1 Query Report Metrics
- **URL**: `GET /reports?type={SUMMARY|INVENTORY|EXPIRY|LOW_STOCK}`
- **Access**: Protected

### 7.2 Download Dynamic OpenPDF Document
- **URL**: `GET /reports/pdf?type={SUMMARY|INVENTORY|EXPIRY|LOW_STOCK}`
- **Access**: Protected (Returns binary stream `application/pdf`)

---

## 8. OCR Date Extraction

### 8.1 Extract Packaging Date
- **URL**: `POST /ocr/expiry`
- **Access**: Protected
- **Request (JSON Text)**:
```json
{
  "text": "MFD: 10/08/2026 EXP: 28/09/2026 LOT: B102"
}
```
- **Response (200 OK)**:
```json
{
  "rawText": "MFD: 10/08/2026 EXP: 28/09/2026 LOT: B102",
  "extractedExpiryDate": "2026-09-28",
  "extractedMfgDate": "2026-08-10",
  "confidence": 0.95,
  "status": "SUCCESS",
  "message": "Expiry date extracted successfully. Please verify before attaching."
}
```
