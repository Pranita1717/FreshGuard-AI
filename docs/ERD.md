# FreshGuard AI — Entity Relationship Diagram (ERD) & Schema Specification

## 1. Overview
FreshGuard AI is built upon MongoDB (NoSQL Document Store) using Spring Data MongoDB. While MongoDB is schemaless by default, Spring Data MongoDB models enforce strong typing, validation constraints, and bidirectional referential integrity across the system collections.

---

## 2. Mermaid Entity Relationship Diagram

```mermaid
erDiagram
    USER ||--o{ INVENTORY_LOG : performs
    USER ||--o{ LOGIN_LOG : generates
    USER ||--o{ TASK : assigned_to
    USER ||--o{ DISCOUNT : creates_approves
    
    PRODUCT ||--o{ INVENTORY_LOG : logs_change
    PRODUCT ||--o{ TASK : references
    PRODUCT ||--o{ DISCOUNT : receives
    PRODUCT ||--o{ NOTIFICATION : triggers

    USER {
        string id PK "ObjectId"
        string email UK "Unique index"
        string password "BCrypt hash"
        string name "Full name"
        string phone "Contact number"
        string role "ADMIN | STORE_MANAGER | EMPLOYEE"
        string storeName "Store / Branch Name"
        boolean active "Account active status"
        date createdAt "Timestamp"
        date updatedAt "Timestamp"
    }

    PRODUCT {
        string id PK "ObjectId"
        string barcode UK "EAN-13 / UPC Unique Index"
        string name "Product title"
        string category "DAIRY | BAKERY | MEAT | PRODUCE | PACKAGED"
        double price "Base price in INR"
        int quantity "Current physical inventory units"
        string unit "kg | liter | packet | box | units"
        int minimumStock "Safety stock reorder threshold"
        date manufacturingDate "Batch production date"
        date expiryDate "Shelf expiration date"
        string expiryStatus "EXPIRED | CRITICAL | NEAR_EXPIRY | SAFE"
        int daysUntilExpiry "Calculated difference vs today"
        string shelfPriority "HIGH | MEDIUM | LOW"
        string status "ACTIVE | REMOVED"
        date createdAt "Timestamp"
        date updatedAt "Timestamp"
    }

    INVENTORY_LOG {
        string id PK "ObjectId"
        string productId FK "Reference to Product"
        string productName "Denormalized for audit"
        string barcode "Product barcode"
        string action "ADD | REDUCE | SET | RESTOCK | REMOVE_EXPIRED"
        int quantityChanged "Delta units"
        int previousQuantity "Units before mutation"
        int newQuantity "Units after mutation"
        string reason "Audit rationale"
        string performedBy "Staff email / username"
        string userRole "STORE_MANAGER | EMPLOYEE"
        date timestamp "Audit occurrence time"
    }

    LOGIN_LOG {
        string id PK "ObjectId"
        string email "User email"
        string role "User role"
        boolean successful "Login outcome"
        string ipAddress "Client IP"
        string failureReason "Reason if failed"
        date timestamp "Attempt timestamp"
    }

    NOTIFICATION {
        string id PK "ObjectId"
        string title "Alert title"
        string message "Detailed alert description"
        string type "CRITICAL | WARNING | INFO"
        string productId FK "Related Product ID"
        boolean isRead "Read status"
        date createdAt "Creation timestamp"
    }

    TASK {
        string id PK "ObjectId"
        string title "Duty title"
        string description "Staff instructions"
        string status "PENDING | IN_PROGRESS | COMPLETED"
        string priority "HIGH | MEDIUM | LOW"
        string assignedTo "Staff user email"
        string productId FK "Related Product ID"
        date dueDate "Target completion timestamp"
        date createdAt "Creation timestamp"
        date updatedAt "Update timestamp"
    }

    DISCOUNT {
        string id PK "ObjectId"
        string productId FK "Reference to Product"
        string productName "Denormalized product name"
        double percentage "Markdown percent (e.g. 30%)"
        double originalPrice "Price before discount"
        double discountedPrice "Price after discount"
        string status "PENDING | APPROVED | REJECTED"
        string reason "Expiry triage rationale"
        string createdBy "Staff email"
        string approvedBy "Manager email"
        date createdAt "Creation timestamp"
    }

    SYSTEM_LOG {
        string id PK "ObjectId"
        string level "INFO | WARN | ERROR"
        string message "System event message"
        string service "freshguard-backend"
        date timestamp "Event timestamp"
    }
```

---

## 3. Data Dictionary

### Collection: `users`
| Field | Type | Constraints | Description |
|---|---|---|---|
| `_id` | ObjectId / String | Primary Key | Unique document identifier |
| `email` | String | Unique, Non-null, Indexed | Staff / Manager / Admin login email |
| `password` | String | BCrypt Hash (60 chars) | Salted password hash |
| `name` | String | Non-null | Staff member full name |
| `phone` | String | Nullable | Contact telephone |
| `role` | Enum / String | `ADMIN`, `STORE_MANAGER`, `EMPLOYEE` | Access control tier |
| `storeName` | String | Non-null | Branch / Store assignment |
| `active` | Boolean | Default `true` | Account enable / disable flag |
| `createdAt` | LocalDateTime | System-generated | Registration timestamp |

### Collection: `products`
| Field | Type | Constraints | Description |
|---|---|---|---|
| `_id` | ObjectId / String | Primary Key | Unique product ID |
| `barcode` | String | Unique Index | EAN-13 / UPC product barcode |
| `name` | String | Non-null | Product brand and item name |
| `category` | String | Non-null | Department category |
| `price` | Double | Min: 0.0 | Unit retail price (INR) |
| `quantity` | Integer | Min: 0 | Current shelf and backroom count |
| `unit` | String | Default `'units'` | Packaging unit of measure |
| `minimumStock` | Integer | Min: 0 | Restock trigger threshold |
| `manufacturingDate` | LocalDate | Non-null | Packaging / Production date |
| `expiryDate` | LocalDate | Non-null | Expiration date |
| `expiryStatus` | String | `EXPIRED`, `CRITICAL`, `NEAR_EXPIRY`, `SAFE` | Deterministic status |
| `daysUntilExpiry` | Integer | Calculated | Days remaining until expiry |
| `shelfPriority` | String | `HIGH`, `MEDIUM`, `LOW` | FIFO triage placement tier |
| `status` | String | `ACTIVE`, `REMOVED` | De-list status without data loss |

### Collection: `inventory_logs`
| Field | Type | Constraints | Description |
|---|---|---|---|
| `_id` | ObjectId / String | Primary Key | Log incident identifier |
| `productId` | String | Indexed | Referenced product identifier |
| `productName` | String | Non-null | Denormalized product name |
| `barcode` | String | Non-null | Scanned barcode |
| `action` | String | Non-null | Operation type (`ADD`, `REDUCE`, `SET`, `RESTOCK`, `REMOVE_EXPIRED`) |
| `quantityChanged` | Integer | Non-null | Quantity delta |
| `previousQuantity` | Integer | Min: 0 | Stock before change |
| `newQuantity` | Integer | Min: 0 | Stock after change |
| `reason` | String | Non-null | Staff audit explanation |
| `performedBy` | String | Non-null | User email who performed action |
| `userRole` | String | Non-null | Role of user at time of change |
| `timestamp` | LocalDateTime | Indexed | Incident timestamp |

---

## 4. Indexing Strategy
1. `users.email`: Unique ascending index for fast O(1) user lookups during authentication.
2. `products.barcode`: Unique ascending index for rapid sub-millisecond barcode scanner queries.
3. `products.expiryDate`: Ascending index to support efficient shelf-life triage sorting.
4. `inventory_logs.timestamp`: Descending index for audit trail timeline queries.
5. `notifications.isRead`: Compound index with `createdAt` for instant unread notification counts.
