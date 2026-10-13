# FreshGuard AI – Fixed Submission Build

The project in this archive has been corrected for navigation, store isolation, inventory actions, OCR, barcode/camera permissions, notifications, tasks, reports, and role access. See **FIXED_SETUP.md** for setup and demo credentials.

---

﻿# FRESHGUARD AI
### Smart Food Expiry & Inventory Management System
> **MCA Academic Capstone Project**  
> A Production-Style, Fully Connected End-to-End Mobile & Web Application

---

## 1. Executive Summary & Abstract
Commercial supermarkets and food distribution centers lose an estimated 12% to 18% of perishable goods each month due to poor shelf rotation, human oversight of expiration dates, and inaccurate physical stock counting. 

**FreshGuard AI** solves this critical problem through a deterministic, rule-based inventory and expiry triage system. Combining a high-performance **Flutter** frontend, an enterprise-grade **Java Spring Boot 3** REST API backend, and a **MongoDB** document database, FreshGuard AI provides complete store accountability:
- Eliminates customer food safety risk through real-time First-In, First-Out (FIFO) shelf triage.
- Employs human-in-the-loop OCR packaging date extraction and rapid barcode scanner auditing.
- Provides mathematical restocking purchase orders to prevent stockouts.
- Delivers server-side vector PDF generation via OpenPDF for executive audits.
- Enforces zero silent data loss: expired stock disposal writes an immutable audit trail while de-listing expired items.

---

## 2. Technology Stack

| Layer | Technologies & Frameworks | Description |
|---|---|---|
| **Frontend** | Flutter 3.41.4, Dart 3.11.1 | Cross-platform UI (Web/Chrome, Windows Desktop, Android) |
| **Styling** | Material Design 3, Emerald Green Theme | Responsive grid, custom cards, live telemetry widgets |
| **Client Storage** | `shared_preferences: ^2.3.2` | Persistent JWT session management and user credentials |
| **Visual Charts** | `fl_chart: ^0.68.0` | Interactive status distribution and valuation graphs |
| **Backend** | Java 17, Spring Boot 3.3.4 | Microservices-ready MVC enterprise architecture |
| **Build Tool** | Gradle 8.10.2 (`gradlew.bat`) | Automated dependency resolution and compilation (NO Maven) |
| **Security** | Spring Security 6, JJWT 0.12.6, BCrypt | Stateless JWT Bearer token authentication & role RBAC |
| **PDF Engine** | OpenPDF 2.0.3 (`librepdf`) | In-memory dynamic vector PDF generation |
| **Database** | MongoDB (`localhost:27017/freshguard`) | Spring Data MongoDB document persistence with indexes |

---

## 3. Role-Based Access Control (RBAC) Architecture

The application strictly implements three distinct user roles:

1. **`ADMIN` (System Administrator)**:
   - Dedicated exclusively to system uptime, JVM memory diagnostics, MongoDB connection pinging, and security login audit logs.
   - **Strict Boundary**: Cannot manipulate inventory, add products, or approve discounts. Admin registration is blocked on public portals.
2. **`STORE_MANAGER` (Store Operations Manager)**:
   - Full store catalog management (Create, Read, Update, Delete SKU products).
   - Oversees shelf triage priorities, approves/rejects markdown discounts, executes supplier restocking orders, and exports PDF reports.
3. **`EMPLOYEE` (Store Frontline Staff)**:
   - Daily operational checklist and duty board (`PENDING` -> `IN_PROGRESS` -> `COMPLETED`).
   - Rapid barcode shelf verification and human-confirmed OCR label date capture.
   - Physical count audits with variance calculations (`Physical - System`).
   - Executes the Expired Stock Disposal Protocol.

---

## 4. Default Seeded Credentials for Demonstration

All test accounts are pre-seeded in MongoDB:

| Role | Email | Password | Access Level |
|---|---|---|---|
| **Admin** | `admin@freshguard.local` | `Admin@123` | System Health, Telemetry, Audit Logs |
| **Store Manager** | `manager@freshguard.local` | `Manager@123` | Full Inventory, Triage, Discounts, Restock, Reports |
| **Store Employee** | `employee@freshguard.local` | `Employee@123` | Tasks, Scanner, Count Audit, Expired Disposal |

> **Viva Demo Tip**: The Login screen includes one-click **"Viva Quick-Fill"** buttons for Admin, Manager, and Employee to fill credentials instantly during viva evaluation.

---

## 5. Prerequisites & Local Environment Setup

- **Java JDK**: Version 17 or higher (`java -version`)
- **Flutter SDK**: Version 3.24 or higher (`flutter doctor`)
- **MongoDB Server**: Running locally on port `27017` (`mongod`)
- **Git** (optional)

---

## 6. How to Run Locally

### Step 1: Start MongoDB
Ensure MongoDB is running locally:
```powershell
mongod --dbpath <your-data-directory>
# Or verify Windows service:
Get-Service -Name MongoDB
```

### Step 2: Launch the Spring Boot Backend
Open a terminal in `d:/project/backend`:
```powershell
cd d:/project/backend
.\gradlew.bat bootRun
```
*The server will start on `http://localhost:8080/api` and seed default users, test products, and operational logs automatically.*

Verify health status:
```powershell
Invoke-RestMethod -Uri "http://localhost:8080/api/health"
```

### Step 3: Launch the Flutter Frontend
Open a second terminal in `d:/project/frontend`:
```powershell
cd d:/project/frontend
# Run on Chrome Browser:
flutter run -d chrome

# Or run natively on Windows Desktop:
flutter run -d windows
```

---

## 7. Verification & Testing

Both automated unit and widget test suites are included:

- **Frontend Tests**:
  ```powershell
  cd d:/project/frontend
  flutter analyze     # Output: No issues found!
  flutter test        # 16/16 tests passing
  ```
- **Backend Tests**:
  ```powershell
  cd d:/project/backend
  .\gradlew.bat test
  ```

---

## 8. Viva Voce Examination Guide (Q&A)

### Q1: Why was MongoDB chosen instead of a traditional relational database (RDBMS)?
> **Answer**: Perishable food inventory items have dynamic characteristics (e.g. some products require batch lot numbers, storage temperature metadata, packaging date OCR payloads, or variable expiry rules). MongoDB document collections (`products`, `inventory_logs`) allow flexible document schemas and fast JSON serialization directly to our REST API. Furthermore, MongoDB handles time-series audit logs with high write throughput without table locking.

### Q2: Why is AI/ML not used for predicting food expiration dates?
> **Answer**: Food expiration is a high-stakes, legally regulated public safety domain. Machine learning models (e.g., regressions or deep neural networks) are probabilistic and prone to hallucination or confidence drift. A model hallucinating a safe date for spoiled meat could result in severe food poisoning and store liability. FreshGuard AI intentionally utilizes **100% deterministic date arithmetic** (`ChronoUnit.DAYS.between(today, expiryDate)`). Machine vision is restricted strictly to OCR date extraction, where a human staff member must verify the parsed date before it is committed.

### Q3: Explain the Shelf Priority Triage algorithm.
> **Answer**: The system applies a strict First-In, First-Out (FIFO) triage calculation:
> 1. `daysUntilExpiry < 0`: **EXPIRED (Priority: HIGH)** — Immediate removal from shelves to disposal bin.
> 2. `0 <= daysUntilExpiry <= 7`: **CRITICAL (Priority: HIGH)** — Move item to eye-level front row; attach promotional markdown tag.
> 3. `8 <= daysUntilExpiry <= 30`: **NEAR_EXPIRY (Priority: MEDIUM)** — Rotate stock behind critical items; monitor daily sales.
> 4. `daysUntilExpiry > 30`: **SAFE (Priority: LOW)** — Standard back shelf storage.

### Q4: How is JWT authentication and stateless authorization implemented?
> **Answer**: 
> 1. The client submits credentials to `/api/auth/login`.
> 2. `DaoAuthenticationProvider` verifies the password using BCrypt (strength 12).
> 3. Upon success, JJWT generates an HMAC-SHA256 signed token containing the user email and role (`ROLE_STORE_MANAGER`), valid for 24 hours.
> 4. On subsequent requests, the Flutter client passes `Authorization: Bearer <token>`.
> 5. `JwtAuthenticationFilter` intercepts the request, verifies the signature, and sets the Spring `SecurityContextHolder`. Method security (`@PreAuthorize("hasRole('...')")`) protects role-specific operations.

### Q5: How does the Restocking formula work?
> **Answer**: 
> Reordering is triggered deterministically whenever `currentQuantity <= minimumStock`. The recommended order quantity is computed as:
> $$\text{Suggested Order} = \max\left(0, (\text{minimumStock} \times 2) - \text{currentQuantity}\right)$$
> This formula guarantees that the received delivery restores the buffer to double the safety threshold while taking into account leftover stock, preventing both stockouts and perishable over-ordering.

### Q6: What happens when an employee marks an item as "Removed / Expired"?
> **Answer**: 
> The system adheres to a zero silent data loss principle. It does **not** delete the MongoDB document. Instead:
> 1. It calls `POST /api/inventory/{id}/remove-expired`.
> 2. The product's `quantity` is reduced to 0 and its status is updated to `REMOVED`.
> 3. An immutable `InventoryLog` is recorded with `action = "REMOVE_EXPIRED"`, the staff user's email, timestamp, and selected disposal method (e.g. Bio-Waste, Vendor Return).
> 4. This ensures full compliance during health department audits.

### Q7: How does the dynamic PDF report generation work?
> **Answer**:
> When a manager requests an export (`GET /api/reports/pdf?type=...`), the backend invokes `ReportService` using **OpenPDF 2.0.3**. The service constructs a clean vector PDF in an in-memory `ByteArrayOutputStream`, drawing corporate headers, inventory valuations, itemized stock tables, and cryptographic timestamps. It returns the raw byte stream directly with `Content-Type: application/pdf`, allowing instant client download without creating temporary files on the server disk.

---

## 9. Project Directory Structure
```
d:/project/
├── backend/                        # Java Spring Boot 3 Backend
│   ├── src/main/java/com/freshguardai/
│   │   ├── config/                 # Security & CORS configuration
│   │   ├── controller/             # 11 REST API Controllers
│   │   ├── dto/                    # Request & Response DTOs
│   │   ├── model/                  # MongoDB Document Models
│   │   ├── repository/             # Spring Data MongoDB Repositories
│   │   ├── security/               # JWT Filter & UserDetails
│   │   └── service/                # Business Logic Services
│   ├── src/main/resources/         # application.properties
│   ├── build.gradle                # Gradle Build Configuration
│   └── gradlew.bat                 # Gradle Wrapper Script
├── frontend/                       # Flutter Cross-Platform Frontend
│   ├── lib/
│   │   ├── screens/                # 18 Modular UI Screens
│   │   ├── services/               # ApiService, Session, ApiConfig
│   │   ├── widgets/                # AppShell, StatCard
│   │   └── main.dart               # App entrypoint & Route registry
│   ├── test/                       # 16 Flutter Unit & Widget Tests
│   └── pubspec.yaml                # Flutter Dependencies
├── docs/                           # Capstone Architectural Documentation
│   ├── ERD.md                      # Mermaid ERD & MongoDB Schemas
│   ├── Use_Case_Diagram.md         # Mermaid Use Case Specifications
│   ├── Flowchart.md                # 5 Core Process Flowcharts
│   ├── System_Architecture.md      # Multi-Tier System Architecture
│   └── API_Documentation.md        # Complete REST API Reference
├── postman/                        # Postman Test Suite
│   └── FreshGuardAI.postman_collection.json
└── README.md                       # Comprehensive Master Documentation
```
