# DATASET PROFILE CATALOG: SMART DELIVERY OPERATIONS ANALYTICS

**Document ID:** DOC-DP-002  
**Version:** 1.0.0 (Production Blueprint)  
**Database Name:** `smart_delivery_analytics`  
**Total Source Files:** 7 CSV Datasets  
**Total Combined Records:** 29,300 Records  

---

## 1. High-Level Dataset Inventory

| Dataset Name | Physical Filename | Total Rows | Total Cols | Primary Key | Foreign Keys | Role in System |
| :--- | :--- | :---: | :---: | :--- | :--- | :--- |
| **Customers** | `customers.csv` | 1,000 | 6 | `customer_id` | None | Dimension: Customer Demographics |
| **Customer Behavior** | `customer_behavior.csv` | 1,000 | 6 | `customer_id` | `customer_id` -> `customers` | Analytics Mart: Historical Engagement & Churn |
| **Delivery Partners**| `delivery_partners.csv` | 200 | 4 | `partner_id` | None | Dimension: Courier Fleet Registry |
| **Restaurants** | `restaurants.csv` | 100 | 5 | `restaurant_id` | None | Dimension: Merchant Catalog & Cuisine |
| **Orders** | `orders.csv` | 10,000 | 9 | `order_id` | `customer_id`, `restaurant_id`, `partner_id` | Fact: Core Transaction Ledger |
| **Payments** | `payments.csv` | 10,000 | 4 | `payment_id` | `order_id` -> `orders` | Fact / Sub-Ledger: Financial Settlements |
| **Ratings** | `ratings.csv` | 7,000 | 4 | `rating_id` | `order_id` -> `orders` | Fact / Feedback: Post-Delivery CSAT |

---

## 2. Table-by-Table Column Profiles

### 2.1 `customers.csv` (1,000 rows, 6 columns)
*Master registry of all end-consumer user profiles registered on the food delivery platform.*

| Column Name | Inferred Type | Proposed MySQL Type | Null Count (%) | Unique Values | Min / Max / Distribution | Business Significance |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- |
| `customer_id` | Integer | `INT UNSIGNED PRIMARY KEY` | 0 (0.0%) | 1,000 | 1 to 1,000 | Unique system identifier for registered customer. |
| `customer_name`| Text | `VARCHAR(100) NOT NULL` | 0 (0.0%) | 482 | Sample: Arun Kumar, Ananya Singh, Pallavi Bose | Customer full name. Common Indian first/last name combinations. |
| `age` | Integer | `TINYINT UNSIGNED NOT NULL`| 0 (0.0%) | 43 | Min: 18, Max: 60, Mean: 39.34, Median: 40 | Demographic age bracket. Normal distribution across adult working demographic. |
| `gender` | Categorical | `ENUM('Male','Female','Other')` | 0 (0.0%) | 3 | Female: 347 (34.7%)<br/>Other: 329 (32.9%)<br/>Male: 324 (32.4%) | Customer gender classification for demographic segmentation. |
| `city` | Categorical | `VARCHAR(50) NOT NULL` | 0 (0.0%) | 10 | Ahmedabad: 120, Pune: 114, Delhi: 113, Surat: 104, Bangalore: 102, Kolkata: 97, Chennai: 89, Jaipur: 89, Hyderabad: 88, Mumbai: 84 | Customer resident city (Tier-1 and Tier-2 metropolitan hubs). |
| `signup_date` | Date (ISO) | `DATE NOT NULL` | 0 (0.0%) | 458 | Min: 2022-01-01<br/>Max: 2023-06-29 | Date account was created on platform (18-month registration window). |

---

### 2.2 `customer_behavior.csv` (1,000 rows, 6 columns)
*Derived customer analytics mart storing aggregated behavioral indicators used for churn forecasting and cohort analysis.*

| Column Name | Inferred Type | Proposed MySQL Type | Null Count (%) | Unique Values | Min / Max / Distribution | Business Significance |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- |
| `customer_id` | Integer | `INT UNSIGNED PRIMARY KEY` | 0 (0.0%) | 1,000 | 1 to 1,000 | References `customers(customer_id)` (1-to-1 cardinality). |
| `total_orders` | Integer | `SMALLINT UNSIGNED NOT NULL`| 0 (0.0%) | 19 | Min: 1, Max: 20, Mean: 8.20, Median: 8 | Lifetime count of successfully delivered orders. Matches `orders.csv` perfectly. |
| `total_spending`| Decimal | `DECIMAL(10,2) NOT NULL` | 0 (0.0%) | 1,000 | Min: ₹614.71, Max: ₹16,192.19, Mean: ₹6,414.65 | Cumulative gross item spend across delivered orders in INR. |
| `avg_order_value`| Decimal | `DECIMAL(10,2) NOT NULL` | 0 (0.0%) | 993 | Min: ₹257.98, Max: ₹1,397.90, Mean: ₹785.02 | Average ticket size per delivered order (`total_spending / total_orders`). |
| `last_order_days`| Integer | `SMALLINT UNSIGNED NOT NULL`| 0 (0.0%) | 261 | Min: 1, Max: 590, Mean: 89.53, Median: 61 | Days elapsed since customer's last order relative to benchmark date `2025-01-01`. |
| `churn_flag` | Binary Flag | `TINYINT(1) NOT NULL` | 0 (0.0%) | 2 | 0 (Active): 650 (65.0%)<br/>1 (Churned): 350 (35.0%) | Churn indicator: `1` if inactive > 90 days or 0 delivered orders; else `0`. |

---

### 2.3 `delivery_partners.csv` (200 rows, 4 columns)
*Roster of registered delivery fleet executives performing last-mile order fulfillment.*

| Column Name | Inferred Type | Proposed MySQL Type | Null Count (%) | Unique Values | Min / Max / Distribution | Business Significance |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- |
| `partner_id` | Integer | `SMALLINT UNSIGNED PRIMARY KEY`| 0 (0.0%)| 200 | 1 to 200 | Unique partner identifier. |
| `partner_name` | Text | `VARCHAR(100) NOT NULL` | 0 (0.0%) | 126 | Sample: Karthik Rao, Ravi Yadav, Anil Kumar | Partner full name. |
| `vehicle_type` | Categorical | `ENUM('Bike','Scooter','Electric Bike','Bicycle')` | 0 (0.0%) | 4 | Bike: 51 (25.5%)<br/>Scooter: 50 (25.0%)<br/>Electric Bike: 50 (25.0%)<br/>Bicycle: 49 (24.5%) | Mode of delivery transportation; vital for transit speed comparison. |
| `joining_date` | Date (ISO) | `DATE NOT NULL` | 0 (0.0%) | 185 | Min: 2021-01-03<br/>Max: 2023-12-16 | Date courier onboarded onto platform. |

---

### 2.4 `restaurants.csv` (100 rows, 5 columns)
*Merchant partner catalog of food preparation establishments active on the delivery network.*

| Column Name | Inferred Type | Proposed MySQL Type | Null Count (%) | Unique Values | Min / Max / Distribution | Business Significance |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- |
| `restaurant_id`| Integer | `SMALLINT UNSIGNED PRIMARY KEY`| 0 (0.0%)| 100 | 1 to 100 | Unique merchant identifier. |
| `restaurant_name`| Text | `VARCHAR(100) NOT NULL` | 0 (0.0%) | 68 | Sample: Star Express, Royal Corner, Desi Hub | Commercial brand/outlet name. |
| `cuisine_type` | Categorical | `VARCHAR(50) NOT NULL` | 0 (0.0%) | 10 | Chinese: 17, Burgers: 13, North Indian: 12, Sushi: 12, Pizza: 10, Thai: 9, Desserts: 9, South Indian: 8, Biryani: 6, Continental: 4 | Primary food category prepared by the outlet. |
| `city` | Categorical | `VARCHAR(50) NOT NULL` | 0 (0.0%) | 10 | Mumbai: 14, Chennai: 13, Pune: 12, Kolkata: 11, Hyderabad: 10, Jaipur: 10, Delhi: 9, Surat: 9, Bangalore: 6, Ahmedabad: 6 | Physical operational location of the restaurant kitchen. |
| `rating` | Float | `DECIMAL(2,1) NOT NULL` | 0 (0.0%) | 24 | Min: 2.6, Max: 4.9, Mean: 3.81, Median: 3.8 | Historic merchant kitchen rating on platform out of 5.0. |

---

### 2.5 `orders.csv` (10,000 rows, 9 columns)
*Central operational transaction table recording every food order placed across the 2-year timeline.*

| Column Name | Inferred Type | Proposed MySQL Type | Null Count (%) | Unique Values | Min / Max / Distribution | Business Significance |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- |
| `order_id` | Integer | `INT UNSIGNED PRIMARY KEY` | 0 (0.0%) | 10,000 | 1 to 10,000 | Unique operational order tracking number. |
| `customer_id` | Integer | `INT UNSIGNED NOT NULL` | 0 (0.0%) | 1,000 | 1 to 1,000 (Avg 10 orders/cust) | Foreign Key linking to `customers(customer_id)`. |
| `restaurant_id`| Integer | `SMALLINT UNSIGNED NOT NULL`| 0 (0.0%) | 100 | 1 to 100 (Avg 100 orders/rest) | Foreign Key linking to `restaurants(restaurant_id)`. |
| `partner_id` | Integer | `SMALLINT UNSIGNED NOT NULL`| 0 (0.0%) | 200 | 1 to 200 (Avg 50 orders/part) | Foreign Key linking to `delivery_partners(partner_id)`. |
| `order_time` | Datetime (ISO)| `DATETIME NOT NULL` | 0 (0.0%) | 10,000 | Min: 2023-01-01 00:56:50<br/>Max: 2024-12-30 23:32:43 | Timestamp when order was placed by customer. |
| `delivered_time`| Datetime (ISO)| `DATETIME NULL` | 1,803 (18.03%) | 8,198 | Min: 2023-01-01 01:21:50<br/>Max: 2024-12-31 00:08:43 | Timestamp when courier delivered order. NULL for Cancelled and Pending orders. |
| `order_amount` | Decimal | `DECIMAL(10,2) NOT NULL` | 0 (0.0%) | 9,665 | Min: ₹80.37, Max: ₹1,500.00, Mean: ₹784.68, Median: ₹776.90 | Subtotal basket value of food items ordered. |
| `delivery_fee` | Decimal | `DECIMAL(10,2) NOT NULL` | 0 (0.0%) | 4,312 | Min: ₹10.00, Max: ₹60.00, Mean: ₹35.41, Median: ₹35.74 | Convenience/logistics fee levied on customer. |
| `status` | Categorical | `ENUM('Delivered','Cancelled','Pending')` | 0 (0.0%) | 3 | Delivered: 8,197 (81.97%)<br/>Cancelled: 1,195 (11.95%)<br/>Pending: 608 (6.08%) | Terminal / current fulfillment status of the order. |

---

### 2.6 `payments.csv` (10,000 rows, 4 columns)
*Payment settlement transaction log capturing checkout payments for every order.*

| Column Name | Inferred Type | Proposed MySQL Type | Null Count (%) | Unique Values | Min / Max / Distribution | Business Significance |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- |
| `payment_id` | Integer | `INT UNSIGNED PRIMARY KEY` | 0 (0.0%) | 10,000 | 1 to 10,000 | Unique financial transaction gateway receipt ID. |
| `order_id` | Integer | `INT UNSIGNED UNIQUE NOT NULL`| 0 (0.0%) | 10,000 | 1 to 10,000 (1-to-1 with orders) | Foreign Key linking to `orders(order_id)`. |
| `payment_mode` | Categorical | `ENUM('UPI','Wallet','Debit Card','Credit Card','Cash on Delivery')` | 0 (0.0%) | 5 | UPI: 2,083 (20.83%)<br/>Wallet: 2,027 (20.27%)<br/>Debit Card: 1,994 (19.94%)<br/>Credit Card: 1,987 (19.87%)<br/>Cash on Delivery: 1,909 (19.09%) | Payment channel utilized. Highly balanced across all modern Indian payment instruments. |
| `amount` | Decimal | `DECIMAL(10,2) NOT NULL` | 0 (0.0%) | 9,673 | Min: ₹92.67, Max: ₹1,557.90, Mean: ₹820.09, Median: ₹811.41 | Total settlement amount paid by user. Reconciles 100% to `order_amount + delivery_fee`. |

---

### 2.7 `ratings.csv` (7,000 rows, 4 columns)
*Post-order customer satisfaction survey responses submitted for delivered orders.*

| Column Name | Inferred Type | Proposed MySQL Type | Null Count (%) | Unique Values | Min / Max / Distribution | Business Significance |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- |
| `rating_id` | Integer | `INT UNSIGNED PRIMARY KEY` | 0 (0.0%) | 7,000 | 1 to 7,000 | Unique survey review identifier. |
| `order_id` | Integer | `INT UNSIGNED UNIQUE NOT NULL`| 0 (0.0%) | 7,000 | 1 to 9,999 (subset of delivered) | Foreign Key linking to `orders(order_id)` (85.4% response rate on delivered orders). |
| `customer_rating`| Float | `DECIMAL(2,1) NOT NULL` | 0 (0.0%) | 41 | Min: 1.0, Max: 5.0, Mean: 2.99, Median: 3.0 | Rating score out of 5.0 submitted by customer. |
| `feedback` | Categorical | `VARCHAR(100) NOT NULL` | 0 (0.0%) | 12 | Top: Average experience (627), Amazing taste (615), Best biryani ever (613), Will order again (604), Packaging was poor (590), Delivery was late (582) | Standard feedback tag chosen by customer. |

---

## 3. Data Type Standardization & Normalization Plan

1. **Monetary Precision:** All currency fields (`order_amount`, `delivery_fee`, `amount`, `total_spending`, `avg_order_value`) are standardized to `DECIMAL(10,2)` to prevent floating-point rounding errors common in `FLOAT`/`DOUBLE`.
2. **Temporal Integrity:** All dates are standardized to native ISO `DATE` (`YYYY-MM-DD`) and `DATETIME` (`YYYY-MM-DD HH:MM:SS`).
3. **Cardinality Constraints:**
   - `orders(order_id)` to `payments(order_id)` is **1-to-1** (`UNIQUE NOT NULL`).
   - `orders(order_id)` to `ratings(order_id)` is **1-to-0..1** (`UNIQUE NOT NULL`).
   - `customers(customer_id)` to `customer_behavior(customer_id)` is **1-to-1** (`PRIMARY KEY & FOREIGN KEY`).
   - `customers`, `restaurants`, `delivery_partners` each have a **1-to-Many** relationship with `orders`.
