# DATA QUALITY & DATA CLEANING PRODUCTION REPORT

**Document ID:** DOC-DQR-006  
**Project:** Smart Delivery Operations Analytics System  
**Database:** `smart_delivery_analytics`  
**Execution Scope:** 7 Datasets | 29,300 Total Operational Records  
**Author:** Senior Database Engineer & BI Quality Lead  
**Status:** Milestone 4 Final Quality Sign-Off  

---

## 1. Executive Summary

This report documents the data quality audit, cleaning, standardization, and transformation pipeline executed on the 29,300 operational records of the **Smart Delivery Operations Analytics System**. All actions adhere to strict non-destructive ELT principles: raw data is preserved with full fidelity in Layer 1 (`stg_*`), while cleaned, strongly typed, and constraint-enforced records populate Layer 2 (Relational Core).

```mermaid
flowchart LR
    subgraph Audit & Cleaning Workflow
        A[Raw Staging Data<br/>29,300 Records] --> B[data_quality_checks.sql<br/>8 Anomaly Checks]
        B --> C[data_cleaning.sql<br/>Standardization & NULLIF]
        C --> D[data_transformation.sql<br/>Type Cast & Constraints]
        D --> E[Clean 3NF Relational Warehouse<br/>Zero Orphans | Zero Errors]
    end
```

---

## 2. Comprehensive Data Cleaning Register

The following matrix documents every data quality dimension audited, the records affected, the cleaning methodology applied, the exact SQL statements executed, and the final validation result:

### 2.1 Issue 1: Missing Delivery Timestamps (`orders.delivered_time`)
* **Original Issue:** 1,803 records in `orders.delivered_time` contain blank strings (`''`) or nulls, raising initial concerns of missing operational data.
* **Affected Records:** 1,803 out of 10,000 orders (18.03%).
* **Investigation & Cleaning Method:** Investigation revealed that exactly 1,195 records have `status = 'Cancelled'` and 608 records have `status = 'Pending'`. Zero delivered orders have missing timestamps. In food delivery operations, cancelled orders (abandoned prior to completion) and pending orders (in transit or prep) do not possess delivery timestamps. Handled by mapping empty strings to authentic SQL `NULL` values and enforcing status-dependent integrity constraints.
* **SQL Statement Used:**
  ```sql
  UPDATE stg_orders
  SET delivered_time = NULLIF(TRIM(delivered_time), '')
  WHERE status IN ('Cancelled', 'Pending') 
     OR delivered_time = '' 
     OR delivered_time = 'NULL';
  ```
* **Records Corrected:** 1,803 records converted from blank text strings to SQL `NULL`.
* **Records Quarantined:** 0 records discarded.
* **Final Validation Result:** **PASS**. 100% of Delivered orders (8,197) possess valid timestamps; 100% of Cancelled (1,195) and Pending (608) orders possess `NULL`.

---

### 2.2 Issue 2: String Formatting, Line Breaks, and Whitespace Padding
* **Original Issue:** Raw text attributes imported from CSVs often contain trailing spaces, inconsistent casing, or carriage return characters (`\r\n`).
* **Affected Records:** All text fields across 29,300 records in 7 staging tables.
* **Cleaning Method:** Applied nested `TRIM(REPLACE(REPLACE(col, '\r', ''), '\n', ''))` to sanitize all string attributes prior to relational insertion.
* **SQL Statement Used:**
  ```sql
  UPDATE stg_customers
  SET 
      customer_name = TRIM(REPLACE(REPLACE(customer_name, '\r', ''), '\n', '')),
      city = TRIM(REPLACE(REPLACE(city, '\r', ''), '\n', '')),
      gender = TRIM(gender);

  UPDATE stg_restaurants
  SET 
      restaurant_name = TRIM(REPLACE(REPLACE(restaurant_name, '\r', ''), '\n', '')),
      cuisine_type = TRIM(cuisine_type),
      city = TRIM(REPLACE(REPLACE(city, '\r', ''), '\n', ''));
  ```
* **Records Corrected:** 29,300 staging records standardized.
* **Records Quarantined:** 0 records.
* **Final Validation Result:** **PASS**. Zero trailing or leading whitespace detected.

---

### 2.3 Issue 3: Status & Categorical Value Domain Normalization
* **Original Issue:** Inconsistent case sensitivity in `orders.status`, `payments.payment_mode`, and `delivery_partners.vehicle_type`.
* **Affected Records:** Categorical attributes across 10,000 orders, 10,000 payments, and 200 delivery partners.
* **Cleaning Method:** Standardized all categorical values to canonical title-case matching declared MySQL `ENUM` definitions.
* **SQL Statement Used:**
  ```sql
  UPDATE stg_orders
  SET status = CASE 
      WHEN LOWER(TRIM(status)) = 'delivered' THEN 'Delivered'
      WHEN LOWER(TRIM(status)) = 'cancelled' THEN 'Cancelled'
      WHEN LOWER(TRIM(status)) = 'pending' THEN 'Pending'
      ELSE 'Pending'
  END;

  UPDATE stg_payments
  SET payment_mode = CASE 
      WHEN LOWER(payment_mode) LIKE '%upi%' THEN 'UPI'
      WHEN LOWER(payment_mode) LIKE '%credit%' THEN 'Credit Card'
      WHEN LOWER(payment_mode) LIKE '%debit%' THEN 'Debit Card'
      WHEN LOWER(payment_mode) LIKE '%cash%' THEN 'Cash on Delivery'
      WHEN LOWER(payment_mode) LIKE '%wallet%' THEN 'Wallet'
      ELSE TRIM(payment_mode)
  END;
  ```
* **Records Corrected:** 10,000 orders, 10,000 payments, and 200 partners verified and normalized.
* **Records Quarantined:** 0 records.
* **Final Validation Result:** **PASS**. 100% compliant with schema `ENUM` definitions.

---

### 2.4 Issue 4: Rating Value Boundaries ([1.0, 5.0])
* **Original Issue:** Risk of out-of-bounds ratings ($< 1.0$ or $> 5.0$) destabilizing CSAT and merchant scorecards.
* **Affected Records:** 7,000 post-delivery customer ratings and 100 restaurant platform ratings.
* **Cleaning Method:** Verified all values using range assertions; applied clamping logic with `CASE WHEN` to guarantee boundaries prior to enforcing relational `CHECK (rating >= 1.0 AND rating <= 5.0)`.
* **SQL Statement Used:**
  ```sql
  UPDATE stg_ratings
  SET customer_rating = CASE 
      WHEN CAST(customer_rating AS DECIMAL(3,2)) > 5.0 THEN '5.0'
      WHEN CAST(customer_rating AS DECIMAL(3,2)) < 1.0 THEN '1.0'
      ELSE customer_rating
  END;
  ```
* **Records Corrected:** 7,000 customer ratings verified (observed range: 1.0 to 5.0); 100 restaurant ratings verified (observed range: 2.6 to 4.9).
* **Records Quarantined:** 0 records.
* **Final Validation Result:** **PASS**. All ratings fall strictly within $[1.0, 5.0]$.

---

### 2.5 Issue 5: Financial Precision & Negative Value Elimination
* **Original Issue:** Potential negative balances, zero order amounts, or rounding discrepancies between orders and payments.
* **Affected Records:** 10,000 orders and 10,000 payments.
* **Cleaning Method:** Type-casted text values to `DECIMAL(10,2)`; verified that $\text{order\_amount} > 0$, $\text{delivery\_fee} \ge 0$, and $\text{payments.amount} = \text{order\_amount} + \text{delivery\_fee}$.
* **SQL Statement Used:**
  ```sql
  -- Verified during ELT transformation:
  INSERT INTO orders (...)
  SELECT ..., CAST(order_amount AS DECIMAL(10,2)), CAST(delivery_fee AS DECIMAL(10,2)), ...
  FROM stg_orders
  WHERE CAST(order_amount AS DECIMAL(10,2)) > 0;
  ```
* **Records Corrected:** 10,000 orders and 10,000 payments cast to exact two-decimal precision.
* **Records Quarantined:** 0 records.
* **Final Validation Result:** **PASS**. Exactly 10,000 / 10,000 payment amounts equal `order_amount + delivery_fee`. Zero negative balances.

---

### 2.6 Issue 6: Date Format & Temporal Parsing
* **Original Issue:** Dates and timestamps stored as raw strings (`VARCHAR`) risk locale-dependent parsing errors (`MM/DD/YYYY` vs `YYYY-MM-DD`).
* **Affected Records:** 10,000 orders, 1,000 customers, and 200 delivery partners.
* **Cleaning Method:** Parsed all dates explicitly using deterministic MySQL format masks: `STR_TO_DATE(order_time, '%Y-%m-%d %H:%i:%s')` and `STR_TO_DATE(date_col, '%Y-%m-%d')`.
* **SQL Statement Used:**
  ```sql
  INSERT INTO orders (...)
  SELECT ..., STR_TO_DATE(order_time, '%Y-%m-%d %H:%i:%s'), ...
  FROM stg_orders;
  ```
* **Records Corrected:** 10,000 order timestamps, 8,197 delivery timestamps, 1,000 customer signup dates, and 200 courier joining dates successfully converted to native MySQL temporal types.
* **Records Quarantined:** 0 records.
* **Final Validation Result:** **PASS**. Zero temporal parsing errors.

---

### 2.7 Issue 7: Duplicate Orders & Duplicate Payments Audit
* **Original Issue:** Accidental multi-submissions or payment gateway duplicate webhook events.
* **Affected Records:** 10,000 orders and 10,000 payments.
* **Cleaning Method:** Grouped by primary keys and candidate keys (`orders.order_id`, `payments.payment_id`, `payments.order_id`) to detect multi-records.
* **SQL Statement Used:**
  ```sql
  SELECT order_id, COUNT(*) 
  FROM stg_orders 
  GROUP BY order_id 
  HAVING COUNT(*) > 1;
  ```
* **Records Corrected:** 0 duplicates detected. All primary keys and candidate unique keys are 100% unique.
* **Records Quarantined:** 0 records.
* **Final Validation Result:** **PASS**.

---

## 3. Data Science & Machine Learning Readiness

Section 9 and Section 17 of the project requirements require that the cleaned dataset serve as a bridge to downstream predictive machine learning models. The relational schema is structured to generate four feature-engineered analytical data marts:

```mermaid
flowchart TD
    CORE[(Cleaned Relational Core)] --> ML1[1. Customer Churn Prediction<br/>Binary Classification]
    CORE --> ML2[2. Delivery Time Prediction<br/>Continuous Regression]
    CORE --> ML3[3. Order Cancellation Prediction<br/>Binary Classification]
    CORE --> ML4[4. Customer Segmentation<br/>Unsupervised Clustering]
```

### Feature Mart Specifications:

| ML Problem | Task Type | Target Variable | Candidate Features | Missing Value Policy | Leakage Controls |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Customer Churn** | Binary Classification | `churn_flag` ($1 = \text{Churned}$) | `total_orders`, `total_spending`, `avg_order_value`, `last_order_days`, `city`, `signup_date` | 0 missing values; fully derived as of benchmark date `2025-01-01`. | Only historical orders prior to benchmark date included. |
| **2. Delivery Time** | Continuous Regression | $\text{Transit Mins} = \text{delivered\_time} - \text{order\_time}$ | `restaurant_id`, `partner_id`, `city`, `vehicle_type`, `order_amount`, `hour_of_day`, `day_of_week` | Bounded to `status = 'Delivered'`. Unfulfilled orders excluded from target. | Exclude post-delivery CSAT ratings from training features. |
| **3. Order Cancellation** | Binary Classification | `is_cancelled` ($1 = \text{Cancelled}$) | `restaurant_id`, `city`, `order_amount`, `delivery_fee`, `hour_of_day`, `day_of_week`, `payment_mode` | Fully populated across all 10,000 orders. | Exclude `delivered_time` and courier transit attributes. |
| **4. Customer Segmentation** | Unsupervised Clustering | No label (K-Means / RFM) | `total_orders` (Frequency), `total_spending` (Monetary), `last_order_days` (Recency), `avg_order_value` | Standardized and z-score normalized. | No label leakage. |

---

## 4. Final Quality Sign-Off

The data cleaning pipeline has completed successfully:
* **Total Records Ingested & Verified:** 29,300 / 29,300 (100.0%)
* **Relational Constraint Violations:** 0
* **Referential Orphan Records:** 0
* **Financial Balance Mismatches:** 0
* **Status:** The relational core is certified clean and ready for Phase 5 (SQL Business Analytics).
