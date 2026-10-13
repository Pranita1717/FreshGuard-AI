# FreshGuard AI — Use Case Specifications & Diagram

## 1. System Actors
1. **System Administrator (`ADMIN`)**:
   - Monitors overall system health, MongoDB ping latency, and JVM heap memory.
   - Observes security login audit logs and telemetry.
   - **Boundary Enforcement**: Cannot modify products or alter physical store inventory.
2. **Store Manager (`STORE_MANAGER`)**:
   - Manages complete store catalog (Create, Read, Update, Delete products).
   - Oversees rule-based shelf triage priorities (High, Medium, Low).
   - Reviews and approves promotional markdown discounts.
   - Triggers inventory restocking purchase orders.
   - Generates and exports dynamic PDF reports (OpenPDF).
   - Assigns operational duty tasks to staff members.
3. **Store Employee (`EMPLOYEE`)**:
   - Inspects physical shelves via rapid barcode scanning.
   - Performs OCR packaging date verification with human-in-the-loop confirmation.
   - Conducts physical stock count audits and reconciles variances.
   - Executes the Expired Stock Disposal Protocol.
   - Completes assigned duty checklists.
4. **Backend System Engine**:
   - Runs automated daily midnight expiry recalculation.
   - Generates notifications when products transition into Critical or Low Stock states.

---

## 2. Mermaid Use Case Diagram

```mermaid
flowchart LR
    %% Actors
    Admin(["System Administrator"])
    Manager(["Store Manager"])
    Employee(["Store Employee"])
    System(["Backend Engine"])

    %% Use Cases Admin
    subgraph Admin_Portal["Administrator Scope"]
        UC_Health["Monitor System Health & JVM"]
        UC_Audit["Review Security & Login Logs"]
        UC_Telemetry["Observe Store Telemetry"]
    end

    %% Use Cases Manager
    subgraph Manager_Portal["Store Manager Scope"]
        UC_Catalog["Manage Product Catalog (CRUD)"]
        UC_Triage["Inspect Shelf Priority (FIFO)"]
        UC_Discount["Approve / Reject Discounts"]
        UC_Restock["Calculate & Trigger Restock"]
        UC_Reports["Generate OpenPDF Reports"]
        UC_Assign["Assign Duties & Tasks"]
    end

    %% Use Cases Employee
    subgraph Employee_Portal["Store Employee Scope"]
        UC_Barcode["Scan Barcode for Shelf Advice"]
        UC_OCR["OCR Packaging Date Extraction"]
        UC_StockAudit["Physical Stock Count Audit"]
        UC_Disposal["Execute Expired Disposal"]
        UC_Tasks["Checklist & Complete Duties"]
    end

    %% Use Cases Common
    subgraph Common_Scope["Authentication & Alerts"]
        UC_Login["JWT Authentication & Login"]
        UC_Alerts["View Real-time Notifications"]
        UC_Profile["Update Staff Profile"]
    end

    %% Actor Connections
    Admin --> UC_Login
    Admin --> UC_Health
    Admin --> UC_Audit
    Admin --> UC_Telemetry
    Admin --> UC_Profile

    Manager --> UC_Login
    Manager --> UC_Catalog
    Manager --> UC_Triage
    Manager --> UC_Discount
    Manager --> UC_Restock
    Manager --> UC_Reports
    Manager --> UC_Assign
    Manager --> UC_Alerts
    Manager --> UC_Profile

    Employee --> UC_Login
    Employee --> UC_Barcode
    Employee --> UC_OCR
    Employee --> UC_StockAudit
    Employee --> UC_Disposal
    Employee --> UC_Tasks
    Employee --> UC_Alerts
    Employee --> UC_Profile

    System --> UC_Alerts
    System --> UC_Triage
    System --> UC_Restock
```

---

## 3. Core Use Case Descriptions

### UC-01: Rule-Based Shelf Priority Triage
- **Primary Actor**: Store Manager / Store Employee
- **Precondition**: User is authenticated with a valid JWT token.
- **Description**: The system categorizes inventory into High, Medium, and Low shelf placement priority using strict date arithmetic:
  - `daysUntilExpiry < 0`: EXPIRED (High Priority -> Immediate Disposal)
  - `0 <= daysUntilExpiry <= 7`: CRITICAL (High Priority -> Eye-level front row FIFO)
  - `8 <= daysUntilExpiry <= 30`: NEAR EXPIRY (Medium Priority -> Rotate stock behind front items)
  - `daysUntilExpiry > 30`: SAFE (Low Priority -> Standard back shelf storage)
- **Postcondition**: Stock is visually flagged and ready for physical shelf re-alignment.

### UC-02: OCR Packaging Date Extraction & Verification
- **Primary Actor**: Store Employee / Store Manager
- **Precondition**: Product package label is photographed or text is submitted.
- **Description**: OCR parser extracts dates across formats (`DD/MM/YYYY`, `MM/YYYY`, `Best Before`, etc.), assigns a confidence score, and prompts the human user to confirm the extracted date before attaching it to the product record.
- **Postcondition**: Product expiry date is verified and persisted to MongoDB.

### UC-03: Expired Stock Disposal Protocol
- **Primary Actor**: Store Employee / Store Manager
- **Precondition**: Products have `daysUntilExpiry <= 0` or status `EXPIRED`.
- **Description**: Staff reviews overdue items, chooses a disposal method (Bio-waste, vendor return, damage dump), enters unit count, and submits. The system sets status to `REMOVED` and writes a permanent immutable `InventoryLog`.
- **Postcondition**: Stock is de-listed from active sales; inventory log preserves full audit history.
