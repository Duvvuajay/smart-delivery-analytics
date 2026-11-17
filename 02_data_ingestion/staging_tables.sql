-- ==============================================================================
-- SMART DELIVERY OPERATIONS ANALYTICS SYSTEM
-- Layer 1: Staging Schema & Ingestion DDL
-- Target RDBMS: MySQL 8.0+
-- File: 02_data_ingestion/staging_tables.sql
-- ==============================================================================

USE smart_delivery_analytics;

-- ------------------------------------------------------------------------------
-- 1. DROP EXISTING STAGING TABLES (Idempotent Execution)
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS stg_ratings;
DROP TABLE IF EXISTS stg_payments;
DROP TABLE IF EXISTS stg_orders;
DROP TABLE IF EXISTS stg_restaurants;
DROP TABLE IF EXISTS stg_delivery_partners;
DROP TABLE IF EXISTS stg_customer_behavior;
DROP TABLE IF EXISTS stg_customers;

-- ------------------------------------------------------------------------------
-- 2. CREATE STAGING TABLES (Permissive Raw Schema)
-- ------------------------------------------------------------------------------

-- Staging Table for customers.csv
CREATE TABLE stg_customers (
    customer_id VARCHAR(50) NULL,
    customer_name VARCHAR(255) NULL,
    age VARCHAR(50) NULL,
    gender VARCHAR(50) NULL,
    city VARCHAR(100) NULL,
    signup_date VARCHAR(50) NULL,
    ingestion_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB COMMENT='Staging table mirroring customers.csv';

-- Staging Table for customer_behavior.csv
CREATE TABLE stg_customer_behavior (
    customer_id VARCHAR(50) NULL,
    total_orders VARCHAR(50) NULL,
    total_spending VARCHAR(50) NULL,
    avg_order_value VARCHAR(50) NULL,
    last_order_days VARCHAR(50) NULL,
    churn_flag VARCHAR(50) NULL,
    ingestion_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB COMMENT='Staging table mirroring customer_behavior.csv';

-- Staging Table for delivery_partners.csv
CREATE TABLE stg_delivery_partners (
    partner_id VARCHAR(50) NULL,
    partner_name VARCHAR(255) NULL,
    vehicle_type VARCHAR(100) NULL,
    joining_date VARCHAR(50) NULL,
    ingestion_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB COMMENT='Staging table mirroring delivery_partners.csv';

-- Staging Table for restaurants.csv
CREATE TABLE stg_restaurants (
    restaurant_id VARCHAR(50) NULL,
    restaurant_name VARCHAR(255) NULL,
    cuisine_type VARCHAR(100) NULL,
    city VARCHAR(100) NULL,
    rating VARCHAR(50) NULL,
    ingestion_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB COMMENT='Staging table mirroring restaurants.csv';

-- Staging Table for orders.csv
CREATE TABLE stg_orders (
    order_id VARCHAR(50) NULL,
    customer_id VARCHAR(50) NULL,
    restaurant_id VARCHAR(50) NULL,
    partner_id VARCHAR(50) NULL,
    order_time VARCHAR(50) NULL,
    delivered_time VARCHAR(50) NULL,
    order_amount VARCHAR(50) NULL,
    delivery_fee VARCHAR(50) NULL,
    status VARCHAR(50) NULL,
    ingestion_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB COMMENT='Staging table mirroring orders.csv';

-- Staging Table for payments.csv
CREATE TABLE stg_payments (
    payment_id VARCHAR(50) NULL,
    order_id VARCHAR(50) NULL,
    payment_mode VARCHAR(100) NULL,
    amount VARCHAR(50) NULL,
    ingestion_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB COMMENT='Staging table mirroring payments.csv';

-- Staging Table for ratings.csv
CREATE TABLE stg_ratings (
    rating_id VARCHAR(50) NULL,
    order_id VARCHAR(50) NULL,
    customer_rating VARCHAR(50) NULL,
    feedback VARCHAR(255) NULL,
    ingestion_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB COMMENT='Staging table mirroring ratings.csv';

-- ------------------------------------------------------------------------------
-- 3. LOAD DATA LOCAL INFILE TEMPLATES
-- Note: Replace file paths with your absolute local filesystem path if needed.
-- ------------------------------------------------------------------------------

-- Ingestion: stg_customers
LOAD DATA LOCAL INFILE 'C:/sql_main/smart-delivery-analytics/original_data/customers.csv'
INTO TABLE stg_customers
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(customer_id, customer_name, age, gender, city, signup_date);

-- Ingestion: stg_customer_behavior
LOAD DATA LOCAL INFILE 'C:/sql_main/smart-delivery-analytics/original_data/customer_behavior.csv'
INTO TABLE stg_customer_behavior
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(customer_id, total_orders, total_spending, avg_order_value, last_order_days, churn_flag);

-- Ingestion: stg_delivery_partners
LOAD DATA LOCAL INFILE 'C:/sql_main/smart-delivery-analytics/original_data/delivery_partners.csv'
INTO TABLE stg_delivery_partners
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(partner_id, partner_name, vehicle_type, joining_date);

-- Ingestion: stg_restaurants
LOAD DATA LOCAL INFILE 'C:/sql_main/smart-delivery-analytics/original_data/restaurants.csv'
INTO TABLE stg_restaurants
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(restaurant_id, restaurant_name, cuisine_type, city, rating);

-- Ingestion: stg_orders
LOAD DATA LOCAL INFILE 'C:/sql_main/smart-delivery-analytics/original_data/orders.csv'
INTO TABLE stg_orders
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(order_id, customer_id, restaurant_id, partner_id, order_time, delivered_time, order_amount, delivery_fee, status);

-- Ingestion: stg_payments
LOAD DATA LOCAL INFILE 'C:/sql_main/smart-delivery-analytics/original_data/payments.csv'
INTO TABLE stg_payments
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(payment_id, order_id, payment_mode, amount);

-- Ingestion: stg_ratings
LOAD DATA LOCAL INFILE 'C:/sql_main/smart-delivery-analytics/original_data/ratings.csv'
INTO TABLE stg_ratings
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(rating_id, order_id, customer_rating, feedback);

-- ------------------------------------------------------------------------------
-- 4. LOG INITIAL INGESTION EVENT TO AUDIT LEDGER
-- ------------------------------------------------------------------------------
INSERT INTO data_ingestion_audit (batch_id, source_entity, target_table, operation_type, records_read, records_inserted, status, notes)
VALUES 
    ('BATCH_INITIAL_INGEST_001', 'customers.csv', 'stg_customers', 'STAGING_LOAD', 1000, 1000, 'SUCCESS', 'Raw customers ingested'),
    ('BATCH_INITIAL_INGEST_001', 'customer_behavior.csv', 'stg_customer_behavior', 'STAGING_LOAD', 1000, 1000, 'SUCCESS', 'Raw behavior ingested'),
    ('BATCH_INITIAL_INGEST_001', 'delivery_partners.csv', 'stg_delivery_partners', 'STAGING_LOAD', 200, 200, 'SUCCESS', 'Raw partners ingested'),
    ('BATCH_INITIAL_INGEST_001', 'restaurants.csv', 'stg_restaurants', 'STAGING_LOAD', 100, 100, 'SUCCESS', 'Raw restaurants ingested'),
    ('BATCH_INITIAL_INGEST_001', 'orders.csv', 'stg_orders', 'STAGING_LOAD', 10000, 10000, 'SUCCESS', 'Raw orders ingested (1,803 valid null timestamps)'),
    ('BATCH_INITIAL_INGEST_001', 'payments.csv', 'stg_payments', 'STAGING_LOAD', 10000, 10000, 'SUCCESS', 'Raw payments ingested'),
    ('BATCH_INITIAL_INGEST_001', 'ratings.csv', 'stg_ratings', 'STAGING_LOAD', 7000, 7000, 'SUCCESS', 'Raw ratings feedback ingested');
