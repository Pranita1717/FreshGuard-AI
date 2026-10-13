# FreshGuard AI — System Logic & Process Flowcharts

This document specifies the operational flowcharts for the 5 core computational processes within FreshGuard AI.

---

## 1. Authentication & Role-Based Access Control Flow

```mermaid
flowchart TD
    Start(["User submits Email & Password"]) --> InputValidation{"Client-side\nFields Valid?"}
    InputValidation -- No --> ShowClientError["Display Validation Error"]
    InputValidation -- Yes --> PostLogin["POST /api/auth/login"]
    
    PostLogin --> FindUser{"User exists in\nMongoDB users collection?"}
    FindUser -- No --> Return401["Return HTTP 401 Unauthorized\n(Record in Login Logs)"]
    FindUser -- Yes --> CheckPassword{"BCrypt Password Match?"}
    CheckPassword -- No --> Return401
    CheckPassword -- Yes --> GenJWT["Generate Signed JWT Token\n(HMAC-SHA256, 24h validity)"]
    
    GenJWT --> WriteLoginLog["Record Successful Login Log"]
    WriteLoginLog --> Return200["Return User Profile + JWT Token"]
    
    Return200 --> SaveSession["Flutter Session: Store in SharedPreferences"]
    SaveSession --> CheckRole{"Check User Role"}
    
    CheckRole -- "ADMIN" --> NavAdmin["Navigate to /admin\n(Admin Dashboard)"]
    CheckRole -- "STORE_MANAGER" --> NavManager["Navigate to /manager\n(Store Manager Portal)"]
    CheckRole -- "EMPLOYEE" --> NavEmployee["Navigate to /employee\n(Staff Operations Board)"]
```

---

## 2. OCR Expiry Date Detection & Human-in-the-Loop Verification

```mermaid
flowchart TD
    StartOCR(["Staff captures label photo OR enters text"]) --> SubmitOCR["POST /api/ocr/expiry\n(Multipart image OR JSON text)"]
    SubmitOCR --> Normalize["Normalize text: Uppercase, remove noise"]
    Normalize --> RegexMatch{"Evaluate Date Regex Patterns\n(DD/MM/YYYY, MM/YYYY, Best Before, EXP)"}
    
    RegexMatch -- Found Match --> ExtractDate["Extract date string & calculate confidence score"]
    RegexMatch -- No Match Found --> ReturnFallback["Return confidence: 0.0 with prompt for manual entry"]
    
    ExtractDate --> ReturnOCR["Return extracted date, format, and confidence"]
    ReturnFallback --> ReturnOCR
    
    ReturnOCR --> FlutterModal["Flutter UI displays Verification Modal\n(Human-in-the-loop)"]
    FlutterModal --> UserReview{"Staff confirms or corrects date"}
    
    UserReview -- "Rejects / Edits" --> ManualEdit["Staff enters corrected date"]
    UserReview -- "Approves" --> AttachDate["Attach verified date to selected Product"]
    ManualEdit --> AttachDate
    
    AttachDate --> PutProduct["PUT /api/products/{id}\n(Update product expiry in MongoDB)"]
    PutProduct --> FinishOCR(["Expiry date verified & persisted"])
```

---

## 3. Rule-Based Shelf Priority Triage (FIFO)

```mermaid
flowchart TD
    StartTriage(["Fetch Product Record from MongoDB"]) --> CalcDays["Calculate daysRemaining =\nChronoUnit.DAYS.between(today, product.expiryDate)"]
    
    CalcDays --> CheckExpired{"daysRemaining < 0 ?"}
    CheckExpired -- Yes --> SetExpired["Status: EXPIRED\nShelf Priority: HIGH\nAction: Pull from shelf immediately"]
    
    CheckExpired -- No --> CheckCritical{"daysRemaining <= 7 ?"}
    CheckCritical -- Yes --> SetCritical["Status: CRITICAL\nShelf Priority: HIGH\nAction: Move to eye-level front row (FIFO)\nApply promo markdown"]
    
    CheckCritical -- No --> CheckNearExpiry{"daysRemaining <= 30 ?"}
    CheckNearExpiry -- Yes --> SetNearExpiry["Status: NEAR_EXPIRY\nShelf Priority: MEDIUM\nAction: Rotate behind critical batch\nMonitor daily sales"]
    
    CheckNearExpiry -- No --> SetSafe["Status: SAFE\nShelf Priority: LOW\nAction: Standard storage behind older stock"]
    
    SetExpired --> RenderCard["Render Color-Coded Triage Badge in UI"]
    SetCritical --> RenderCard
    SetNearExpiry --> RenderCard
    SetSafe --> RenderCard
```

---

## 4. Deterministic Restocking Intelligence Formula

```mermaid
flowchart TD
    StartRestock(["Query all active store products"]) --> LoopItem["Iterate over Product item"]
    LoopItem --> CheckStock{"currentQuantity <= minimumStock ?"}
    
    CheckStock -- No --> StockOK["Stock is Adequate\nNo purchase order needed"]
    CheckStock -- Yes --> ApplyFormula["Apply Deterministic Formula:\nsuggestedRestock = max(0, (minimumStock * 2) - currentQuantity)"]
    
    ApplyFormula --> BuildSuggestion["Build Reorder Proposal:\n- Product Title & Barcode\n- Current vs Minimum Buffer\n- Suggested Units to Order\n- Rule Trigger Reason"]
    
    BuildSuggestion --> AddToList["Append to Restocking List"]
    StockOK --> NextItem{"More products?"}
    AddToList --> NextItem
    
    NextItem -- Yes --> LoopItem
    NextItem -- No --> ReturnRestock["Return JSON to Flutter Restocking Screen"]
    
    ReturnRestock --> ManagerAction{"Store Manager reviews list"}
    ManagerAction -- "Receive Delivery" --> PutInventory["PUT /api/inventory/{id}\naction: RESTOCK\nIncrement quantity in MongoDB"]
    PutInventory --> WriteAuditLog["Write immutable InventoryLog"]
    WriteAuditLog --> FinishRestock(["Inventory restored above buffer"])
```

---

## 5. Expired Product Safe Removal Protocol

```mermaid
flowchart TD
    StartDisposal(["Staff navigates to /employee/remove-expired"]) --> QueryExpired["Fetch products where\nexpiryStatus == 'EXPIRED' AND status != 'REMOVED'"]
    
    QueryExpired --> AnyExpired{"Expired items present?"}
    AnyExpired -- No --> CompliantUI["Display 'Store Shelves 100% Compliant'"]
    
    AnyExpired -- Yes --> RenderExpiredList["Display expired batches with red warning cards"]
    RenderExpiredList --> SelectItem["Staff selects item for disposal"]
    
    SelectItem --> SelectMethod["Select Disposal Method:\n- Safe Bio-Waste Disposal\n- Vendor Expiry Return\n- Spoilage / Damaged Dump"]
    
    SelectMethod --> SubmitDisposal["POST /api/inventory/{id}/remove-expired\n{quantity, reason, disposalMethod}"]
    
    SubmitDisposal --> BackendUpdate["Backend Service Operations:\n1. Deduct units from currentQuantity\n2. If quantity == 0, mark status = 'REMOVED'\n3. Recalculate expiry triage"]
    
    BackendUpdate --> WriteDisposalLog["Write permanent InventoryLog:\n- action: 'REMOVE_EXPIRED'\n- performedBy: staff email\n- timestamp: now\n- reason: method + rationale"]
    
    WriteDisposalLog --> ReturnUpdated["Return updated product state to UI"]
    ReturnUpdated --> ShowSuccess["Show confirmation SnackBar\nPreserve audit trail without data deletion"]
```
