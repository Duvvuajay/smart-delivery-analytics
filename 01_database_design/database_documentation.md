# RELATIONAL DATABASE ARCHITECTURE & SCHEMA DOCUMENTATION

**Document ID:** DOC-DB-004  
**Database Name:** `smart_delivery_analytics`  
**RDBMS Target:** MySQL 8.0+ (Enterprise / Community Server)  
**Storage Engine:** InnoDB (ACID Compliant)  
**Default Character Set:** `utf8mb4` | **Collation:** `utf8mb4_unicode_ci`  
**Status:** Milestone 2 Final Production Blueprint  

---

## 1. Architectural Philosophy & Layered Model

In enterprise food logistics platforms (e.g., Swiggy, Zomato, DoorDash), analytics infrastructure must balance two competing objectives:
1. **High-Integrity Transaction Processing (OLTP):** Ensuring zero data loss, strict referential integrity, strong typing, and no insertion/update anomalies.
2. **High-Throughput Analytical Processing (OLAP):** Powering interactive dashboards, window function calculations, and machine learning pipelines without locking transactional tables.

To solve this, the **Smart Delivery Operations Analytics System** implements a **Three-Layer Database Architecture**:

```mermaid
flowchart TD
    subgraph Layer 1: Staging Layer (Raw Fidelity)
        STG_C[stg_customers]
        STG_CB[stg_customer_behavior]
        STG_DP[stg_delivery_partners]
        STG_R[stg_restaurants]
        STG_O[stg_orders]
        STG_P[stg_payments]
        STG_RT[stg_ratings]
    end

    subgraph Layer 2: Cleaned Relational Core (3NF Relational Data Warehouse)
        CORE_C[(customers)]
        CORE_CB[(customer_behavior)]
        CORE_DP[(delivery_partners)]
        CORE_R[(restaurants)]
        CORE_O[(orders)]
        CORE_P[(payments)]
        CORE_RT[(ratings)]
        AUDIT[(data_ingestion_audit)]
    end

    subgraph Layer 3: Analytical Data Marts & BI Presentation Layer
        VW_EXEC[vw_dashboard_overview]
        VW_DELIV[vw_delivery_performance]
        VW_CANC[vw_cancellation_analysis]
        VW_REV[vw_revenue_analysis]
        VW_CUST[vw_customer_retention]
        VW_PART[vw_partner_performance]
        VW_STAR[Star Schema Views: Dim/Fact]
    end

    STG_C --> CORE_C
    STG_CB --> CORE_CB
    STG_DP --> CORE_DP
    STG_R --> CORE_R
    STG_O --> CORE_O
    STG_P --> CORE_P
    STG_RT --> CORE_RT

    CORE_O --> VW_EXEC & VW_DELIV & VW_CANC & VW_REV & VW_CUST & VW_PART & VW_STAR
    CORE_C & CORE_R & CORE_DP & CORE_P & CORE_RT & CORE_CB --> VW_EXEC & VW_DELIV & VW_CANC & VW_REV & VW_CUST & VW_PART & VW_STAR
```

---

## 2. Formal Normalization Proof (1NF through BCNF)

The relational core (Layer 2) is rigorously normalized to **Third Normal Form (3NF)** and **Boyce-Codd Normal Form (BCNF)** to prevent modification anomalies.

### 2.1 First Normal Form (1NF) Compliance
* **Requirement:** Each column contains only atomic (indivisible) values, each record is unique, and no repeating groups exist.
* **Proof:**
  - `customer_name` contains distinct strings without embedded structures.
  - `cuisine_type`, `vehicle_type`, `status`, and `payment_mode` store single atomic category values (enforced via `ENUM` and `VARCHAR`).
  - No comma-separated lists or JSON arrays exist in core relational attributes.
  - Every table has an explicitly declared, non-null Primary Key (`customer_id`, `restaurant_id`, `partner_id`, `order_id`, `payment_id`, `rating_id`).

### 2.2 Second Normal Form (2NF) Compliance
* **Requirement:** The table must be in 1NF, and every non-key attribute must be **fully functionally dependent** on the primary key (no partial key dependencies).
* **Proof:**
  - Every table in Layer 2 utilizes a **single-column primary key** (`order_id`, `customer_id`, etc.).
  - Because no compound/composite primary keys exist in the entity tables, **partial functional dependency is mathematically impossible**. All non-key attributes depend on the entire primary key.

### 2.3 Third Normal Form (3NF) Compliance
* **Requirement:** The table must be in 2NF, and **no transitive functional dependencies** exist ($X \rightarrow Y \rightarrow Z$ where $X$ is the primary key and $Y$ is a non-key attribute).
* **Proof:**
  - In `orders`, attributes like `restaurant_name` or `customer_name` are **not stored**; only foreign keys (`restaurant_id`, `customer_id`) are referenced. Customer demographic changes do not require updates in `orders`.
  - In `payments`, the transaction only stores payment metadata and references `order_id`. It does not store customer profile or restaurant details.
  - In `restaurants`, city is an attribute of the restaurant location; cuisine type is independent of city.
  - Therefore, all non-key attributes depend **solely on the primary key, the whole primary key, and nothing but the primary key**.

### 2.4 Boyce-Codd Normal Form (BCNF)
* **Requirement:** For every functional dependency $X \rightarrow Y$, $X$ must be a superkey.
* **Proof:** In all Layer 2 tables, the only determinants for functional dependencies are the declared primary keys (`order_id`, `customer_id`, `restaurant_id`, `partner_id`) or declared candidate keys (`payments.order_id`, `ratings.order_id`), which are superkeys.

---

## 3. Detailed Data Dictionary & Schema Specification

### 3.1 Table: `customers`
* **Purpose:** Stores demographic profiles of registered app users.
* **Row Count:** 1,000 | **Engine:** InnoDB | **PK:** `customer_id`

| Column Name | Physical Data Type | Nullable | Default | Constraints | Description |
| :--- | :--- | :---: | :---: | :--- | :--- |
| `customer_id` | `INT UNSIGNED` | NO | None | `PRIMARY KEY` | Unique customer surrogate ID (1 to 1,000) |
| `customer_name` | `VARCHAR(100)` | NO | None | None | Customer full legal name |
| `age` | `TINYINT UNSIGNED` | NO | None | `CHECK (age >= 18 AND age <= 100)` | User age in years |
| `gender` | `ENUM('Male','Female','Other')` | NO | None | Domain ENUM | Self-identified gender |
| `city` | `VARCHAR(50)` | NO | None | Index | Primary residential city (10 major hubs) |
| `signup_date` | `DATE` | NO | None | Index | Registration date on platform (2022-01-01 to 2023-06-29) |
| `created_at` | `TIMESTAMP` | NO | `CURRENT_TIMESTAMP` | System | Record insertion timestamp |

---

### 3.2 Table: `customer_behavior`
* **Purpose:** Analytics data mart storing aggregated customer engagement features for churn analysis.
* **Row Count:** 1,000 | **Engine:** InnoDB | **PK:** `customer_id` | **Cardinality:** 1-to-1 with `customers`

| Column Name | Physical Data Type | Nullable | Default | Constraints | Description |
| :--- | :--- | :---: | :---: | :--- | :--- |
| `customer_id` | `INT UNSIGNED` | NO | None | `PRIMARY KEY`, `FK` $\rightarrow$ `customers` | Foreign key referencing `customers(customer_id)` |
| `total_orders` | `SMALLINT UNSIGNED` | NO | `0` | None | Total delivered orders count |
| `total_spending`| `DECIMAL(10,2)` | NO | `0.00` | `CHECK (total_spending >= 0.00)` | Cumulative item spend across delivered orders |
| `avg_order_value`| `DECIMAL(10,2)` | NO | `0.00` | `CHECK (avg_order_value >= 0.00)` | Average basket size per delivered order |
| `last_order_days`| `SMALLINT UNSIGNED` | NO | `0` | None | Days since last order as of 2025-01-01 benchmark |
| `churn_flag` | `TINYINT(1)` | NO | `0` | `CHECK (churn_flag IN (0,1))` | 1 = Churned (>90 days inactive), 0 = Active |
| `last_updated` | `TIMESTAMP` | NO | `CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | System | Auto-updating modification timestamp |

---

### 3.3 Table: `restaurants`
* **Purpose:** Merchant partners active on the platform.
* **Row Count:** 100 | **Engine:** InnoDB | **PK:** `restaurant_id`

| Column Name | Physical Data Type | Nullable | Default | Constraints | Description |
| :--- | :--- | :---: | :---: | :--- | :--- |
| `restaurant_id` | `SMALLINT UNSIGNED` | NO | None | `PRIMARY KEY` | Unique merchant outlet ID (1 to 100) |
| `restaurant_name`| `VARCHAR(100)` | NO | None | None | Commercial outlet brand name |
| `cuisine_type` | `VARCHAR(50)` | NO | None | Index | Primary cuisine category |
| `city` | `VARCHAR(50)` | NO | None | Index | Kitchen operational city hub |
| `rating` | `DECIMAL(2,1)` | NO | None | `CHECK (rating >= 1.0 AND rating <= 5.0)` | Merchant platform rating |
| `created_at` | `TIMESTAMP` | NO | `CURRENT_TIMESTAMP` | System | Record creation timestamp |

---

### 3.4 Table: `delivery_partners`
* **Purpose:** Courier executives responsible for order transport.
* **Row Count:** 200 | **Engine:** InnoDB | **PK:** `partner_id`

| Column Name | Physical Data Type | Nullable | Default | Constraints | Description |
| :--- | :--- | :---: | :---: | :--- | :--- |
| `partner_id` | `SMALLINT UNSIGNED` | NO | None | `PRIMARY KEY` | Unique courier partner ID (1 to 200) |
| `partner_name` | `VARCHAR(100)` | NO | None | None | Courier legal name |
| `vehicle_type` | `ENUM('Bike','Scooter','Electric Bike','Bicycle')` | NO | None | Index | Mode of transportation |
| `joining_date` | `DATE` | NO | None | Index | Courier onboarding date |
| `created_at` | `TIMESTAMP` | NO | `CURRENT_TIMESTAMP` | System | Record creation timestamp |

---

### 3.5 Table: `orders`
* **Purpose:** Central operational fact ledger tracking every food delivery request.
* **Row Count:** 10,000 | **Engine:** InnoDB | **PK:** `order_id`

| Column Name | Physical Data Type | Nullable | Default | Constraints | Description |
| :--- | :--- | :---: | :---: | :--- | :--- |
| `order_id` | `INT UNSIGNED` | NO | None | `PRIMARY KEY` | Unique order tracking number (1 to 10,000) |
| `customer_id` | `INT UNSIGNED` | NO | None | `FK` $\rightarrow$ `customers`, Index | User who initiated checkout |
| `restaurant_id`| `SMALLINT UNSIGNED` | NO | None | `FK` $\rightarrow$ `restaurants`, Index | Outlet preparing food |
| `partner_id` | `SMALLINT UNSIGNED` | NO | None | `FK` $\rightarrow$ `delivery_partners`, Index | Courier assigned to delivery |
| `order_time` | `DATETIME` | NO | None | Index | Timestamp when order was placed |
| `delivered_time`| `DATETIME` | YES | `NULL` | Status Check Constraint | Timestamp order reached customer (NULL if unfulfilled) |
| `order_amount` | `DECIMAL(10,2)` | NO | None | `CHECK (order_amount > 0.00)` | Subtotal basket value of items in INR |
| `delivery_fee` | `DECIMAL(10,2)` | NO | None | `CHECK (delivery_fee >= 0.00)` | Logistics convenience fee levied in INR |
| `status` | `ENUM('Delivered','Cancelled','Pending')` | NO | `'Pending'` | Index | Terminal / operational status |
| `created_at` | `TIMESTAMP` | NO | `CURRENT_TIMESTAMP` | System | Ingestion timestamp |

---

### 3.6 Table: `payments`
* **Purpose:** Financial payment transaction ledger capturing checkout settlements.
* **Row Count:** 10,000 | **Engine:** InnoDB | **PK:** `payment_id` | **Cardinality:** 1-to-1 with `orders`

| Column Name | Physical Data Type | Nullable | Default | Constraints | Description |
| :--- | :--- | :---: | :---: | :--- | :--- |
| `payment_id` | `INT UNSIGNED` | NO | None | `PRIMARY KEY` | Unique transaction receipt ID (1 to 10,000) |
| `order_id` | `INT UNSIGNED` | NO | None | `UNIQUE`, `FK` $\rightarrow$ `orders` | Foreign key referencing `orders(order_id)` |
| `payment_mode` | `ENUM('Credit Card','Debit Card','UPI','Cash on Delivery','Wallet')` | NO | None | Index | Payment settlement channel |
| `amount` | `DECIMAL(10,2)` | NO | None | `CHECK (amount > 0.00)` | Total settlement amount paid (`order_amount + delivery_fee`) |
| `created_at` | `TIMESTAMP` | NO | `CURRENT_TIMESTAMP` | System | Gateway settlement recording timestamp |

---

### 3.7 Table: `ratings`
* **Purpose:** Post-delivery customer feedback and CSAT scores.
* **Row Count:** 7,000 | **Engine:** InnoDB | **PK:** `rating_id` | **Cardinality:** 1-to-0..1 with `orders`

| Column Name | Physical Data Type | Nullable | Default | Constraints | Description |
| :--- | :--- | :---: | :---: | :--- | :--- |
| `rating_id` | `INT UNSIGNED` | NO | None | `PRIMARY KEY` | Unique feedback submission ID (1 to 7,000) |
| `order_id` | `INT UNSIGNED` | NO | None | `UNIQUE`, `FK` $\rightarrow$ `orders` | Foreign key referencing `orders(order_id)` |
| `customer_rating`| `DECIMAL(2,1)` | NO | None | `CHECK (customer_rating >= 1.0 AND customer_rating <= 5.0)` | CSAT score out of 5.0 |
| `feedback` | `VARCHAR(255)` | NO | None | Index | Feedback categorical tag or qualitative comment |
| `created_at` | `TIMESTAMP` | NO | `CURRENT_TIMESTAMP` | System | Survey submission timestamp |

---

### 3.8 Table: `data_ingestion_audit`
* **Purpose:** System-level audit tracking table recording ETL pipeline execution runs, record counts, and errors.
* **Row Count:** Dynamic | **Engine:** InnoDB | **PK:** `audit_id`

| Column Name | Physical Data Type | Nullable | Default | Constraints | Description |
| :--- | :--- | :---: | :---: | :--- | :--- |
| `audit_id` | `BIGINT UNSIGNED` | NO | Auto-Increment | `PRIMARY KEY` | Unique surrogate audit log ID |
| `batch_id` | `VARCHAR(64)` | NO | None | None | Ingestion batch or pipeline run identifier |
| `source_entity` | `VARCHAR(64)` | NO | None | None | Name of source CSV file |
| `target_table` | `VARCHAR(64)` | NO | None | None | Destination table name |
| `operation_type`| `ENUM('STAGING_LOAD','CLEANING_TRANSFORM','INTEGRITY_CHECK','INDEX_REBUILD')` | NO | None | None | Pipeline phase |
| `records_read` | `INT UNSIGNED` | NO | `0` | None | Total rows ingested from source |
| `records_inserted`| `INT UNSIGNED` | NO | `0` | None | Total rows successfully written |
| `records_rejected`| `INT UNSIGNED` | NO | `0` | None | Rows flagged or quarantined |
| `status` | `ENUM('SUCCESS','WARNING','FAILED')` | NO | None | None | Execution outcome |
| `execution_duration_ms` | `INT UNSIGNED` | NO | `0` | None | Execution time in milliseconds |
| `notes` | `TEXT` | YES | `NULL` | None | Diagnostic messages or exception traces |
| `created_at` | `TIMESTAMP` | NO | `CURRENT_TIMESTAMP` | System | Audit event timestamp |

---

## 4. Relationship Cardinality & Integrity Policy Matrix

| Parent Table | Child Table | Join Condition | Cardinality | Business Rule & Referential Action |
| :--- | :--- | :--- | :---: | :--- |
| `customers` | `orders` | `customers.customer_id = orders.customer_id` | **1 : M** | A customer places 0 or many orders. `ON UPDATE CASCADE ON DELETE RESTRICT` prevents accidental deletion of customer accounts with existing transactional orders. |
| `customers` | `customer_behavior` | `customers.customer_id = customer_behavior.customer_id` | **1 : 1** | Exactly one behavioral profile per customer. `ON UPDATE CASCADE ON DELETE CASCADE` automatically purges behavior profile if parent customer is deleted. |
| `restaurants` | `orders` | `restaurants.restaurant_id = orders.restaurant_id` | **1 : M** | A merchant prepares 0 or many orders. `ON UPDATE CASCADE ON DELETE RESTRICT` protects historical restaurant order records. |
| `delivery_partners` | `orders` | `delivery_partners.partner_id = orders.partner_id` | **1 : M** | A courier fulfills 0 or many orders. `ON UPDATE CASCADE ON DELETE RESTRICT` ensures courier performance history is preserved. |
| `orders` | `payments` | `orders.order_id = payments.order_id` | **1 : 1** | Each order produces exactly one gateway checkout transaction. Enforced via `UNIQUE` constraint on `payments.order_id`. `ON UPDATE CASCADE ON DELETE RESTRICT`. |
| `orders` | `ratings` | `orders.order_id = ratings.order_id` | **1 : 0..1** | A delivered order may receive at most one survey rating. Enforced via `UNIQUE` constraint on `ratings.order_id`. `ON UPDATE CASCADE ON DELETE RESTRICT`. |

---

## 5. Storage Engine & Indexing Performance Analysis

### 5.1 Storage Engine: InnoDB
* **ACID Transactions:** Full crash recovery via Write-Ahead Logging (`ib_logfile`), row-level locking, and multi-version concurrency control (MVCC).
* **Foreign Key Constraints:** Native physical constraint validation at the storage engine level.
* **Row Format:** `DYNAMIC` format with 16KB page size for optimal B-Tree node fanout.

### 5.2 Performance Indexing Strategy
To ensure that queries execute in milliseconds even under high concurrent load:
1. **Foreign Key Indexes:** Every foreign key column (`orders.customer_id`, `orders.restaurant_id`, `orders.partner_id`) is explicitly indexed to avoid full table scans during `JOIN` operations.
2. **Composite Filtering Index:** `CREATE INDEX idx_orders_status_time ON orders(status, order_time);` enables index range scans for operational metrics filtering by status and date range simultaneously.
3. **Covering Indexes for Aggregations:** Foreign keys paired with metrics enable index-only scans for high-frequency analytical queries.
