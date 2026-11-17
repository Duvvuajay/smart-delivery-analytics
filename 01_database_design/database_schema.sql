-- ==============================================================================
-- SMART DELIVERY OPERATIONS ANALYTICS SYSTEM
-- Production Relational Database Schema (Layer 2: Cleaned Relational Core)
-- Target RDBMS: MySQL 8.0+
-- File: 01_database_design/database_schema.sql
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. DATABASE INITIALIZATION
-- ------------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS smart_delivery_analytics
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE smart_delivery_analytics;

-- ------------------------------------------------------------------------------
-- 2. DROP EXISTING OBJECTS (Reverse Dependency Order for Idempotency)
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS ratings;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customer_behavior;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS restaurants;
DROP TABLE IF EXISTS delivery_partners;
DROP TABLE IF EXISTS data_ingestion_audit;

-- ------------------------------------------------------------------------------
-- 3. AUDIT & IMPORT TRACKING LAYER
-- ------------------------------------------------------------------------------
CREATE TABLE data_ingestion_audit (
    audit_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT 'Surrogate key for audit event',
    batch_id VARCHAR(64) NOT NULL COMMENT 'Unique identifier for ingestion pipeline run',
    source_entity VARCHAR(64) NOT NULL COMMENT 'Source dataset name (e.g., orders, payments)',
    target_table VARCHAR(64) NOT NULL COMMENT 'Destination relational table',
    operation_type ENUM('STAGING_LOAD', 'CLEANING_TRANSFORM', 'INTEGRITY_CHECK', 'INDEX_REBUILD') NOT NULL COMMENT 'Lifecycle stage',
    records_read INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total source records ingested',
    records_inserted INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total valid records inserted',
    records_rejected INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Records quarantined or discarded',
    status ENUM('SUCCESS', 'WARNING', 'FAILED') NOT NULL COMMENT 'Execution outcome',
    execution_duration_ms INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Duration in milliseconds',
    notes TEXT NULL COMMENT 'Descriptive diagnostics or error log',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Execution timestamp'
) ENGINE=InnoDB COMMENT='Tracks ETL/ELT execution metrics and data pipeline audit trials';

-- ------------------------------------------------------------------------------
-- 4. MASTER ENTITIES & DIMENSIONS
-- ------------------------------------------------------------------------------

-- Master Customer Registry
CREATE TABLE customers (
    customer_id INT UNSIGNED NOT NULL COMMENT 'Unique surrogate customer identifier',
    customer_name VARCHAR(100) NOT NULL COMMENT 'Full name of the registered customer',
    age TINYINT UNSIGNED NOT NULL COMMENT 'Customer age in years',
    gender ENUM('Male', 'Female', 'Other') NOT NULL COMMENT 'Customer self-identified gender',
    city VARCHAR(50) NOT NULL COMMENT 'Customer primary residential metropolitan city',
    signup_date DATE NOT NULL COMMENT 'Platform registration date (YYYY-MM-DD)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Record insertion timestamp',
    CONSTRAINT pk_customers PRIMARY KEY (customer_id),
    CONSTRAINT chk_customers_age CHECK (age >= 18 AND age <= 100)
) ENGINE=InnoDB COMMENT='Master entity table containing registered user profiles';

-- Derived Customer Behavior & Engagement Mart (1-to-1 with customers)
CREATE TABLE customer_behavior (
    customer_id INT UNSIGNED NOT NULL COMMENT 'Primary key references customers(customer_id)',
    total_orders SMALLINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Lifetime count of successfully delivered orders',
    total_spending DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT 'Cumulative item merchandise spend in INR (Delivered orders)',
    avg_order_value DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT 'Average basket size per delivered order in INR',
    last_order_days SMALLINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Days elapsed since latest order as of 2025-01-01 benchmark',
    churn_flag TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 = Churned (inactive > 90 days or 0 orders), 0 = Active',
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Snapshot refresh timestamp',
    CONSTRAINT pk_customer_behavior PRIMARY KEY (customer_id),
    CONSTRAINT fk_cb_customers FOREIGN KEY (customer_id) 
        REFERENCES customers(customer_id) 
        ON UPDATE CASCADE 
        ON DELETE CASCADE,
    CONSTRAINT chk_cb_churn_flag CHECK (churn_flag IN (0, 1)),
    CONSTRAINT chk_cb_total_spending CHECK (total_spending >= 0.00),
    CONSTRAINT chk_cb_avg_order_value CHECK (avg_order_value >= 0.00)
) ENGINE=InnoDB COMMENT='Aggregated analytical feature store table for customer cohort and churn analysis';

-- Restaurant Partner Catalog
CREATE TABLE restaurants (
    restaurant_id SMALLINT UNSIGNED NOT NULL COMMENT 'Unique merchant establishment identifier',
    restaurant_name VARCHAR(100) NOT NULL COMMENT 'Commercial trading brand or outlet name',
    cuisine_type VARCHAR(50) NOT NULL COMMENT 'Primary gastronomic classification',
    city VARCHAR(50) NOT NULL COMMENT 'Operational kitchen metropolitan city hub',
    rating DECIMAL(2,1) NOT NULL COMMENT 'Platform kitchen rating on a 1.0 to 5.0 scale',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation timestamp',
    CONSTRAINT pk_restaurants PRIMARY KEY (restaurant_id),
    CONSTRAINT chk_restaurants_rating CHECK (rating >= 1.0 AND rating <= 5.0)
) ENGINE=InnoDB COMMENT='Merchant partner outlets active on the delivery network';

-- Delivery Courier Partner Fleet
CREATE TABLE delivery_partners (
    partner_id SMALLINT UNSIGNED NOT NULL COMMENT 'Unique delivery courier executive identifier',
    partner_name VARCHAR(100) NOT NULL COMMENT 'Courier legal name',
    vehicle_type ENUM('Bike', 'Scooter', 'Electric Bike', 'Bicycle') NOT NULL COMMENT 'Last-mile transportation mode',
    joining_date DATE NOT NULL COMMENT 'Date courier onboarded onto platform (YYYY-MM-DD)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation timestamp',
    CONSTRAINT pk_delivery_partners PRIMARY KEY (partner_id)
) ENGINE=InnoDB COMMENT='Registered fleet of last-mile delivery executives';

-- ------------------------------------------------------------------------------
-- 5. OPERATIONAL FACT TABLES & TRANSACTIONAL LEDGERS
-- ------------------------------------------------------------------------------

-- Central Operational Orders Fact Table
CREATE TABLE orders (
    order_id INT UNSIGNED NOT NULL COMMENT 'Unique system order transaction tracking ID',
    customer_id INT UNSIGNED NOT NULL COMMENT 'Foreign key to customers(customer_id)',
    restaurant_id SMALLINT UNSIGNED NOT NULL COMMENT 'Foreign key to restaurants(restaurant_id)',
    partner_id SMALLINT UNSIGNED NOT NULL COMMENT 'Foreign key to delivery_partners(partner_id)',
    order_time DATETIME NOT NULL COMMENT 'Checkout placement timestamp',
    delivered_time DATETIME NULL COMMENT 'Fulfillment completion timestamp (NULL if not Delivered)',
    order_amount DECIMAL(10,2) NOT NULL COMMENT 'Item merchandise basket subtotal in INR',
    delivery_fee DECIMAL(10,2) NOT NULL COMMENT 'Logistics convenience fee levied in INR',
    status ENUM('Delivered', 'Cancelled', 'Pending') NOT NULL DEFAULT 'Pending' COMMENT 'Terminal or operational state',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Ingestion timestamp',
    CONSTRAINT pk_orders PRIMARY KEY (order_id),
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) 
        REFERENCES customers(customer_id) 
        ON UPDATE CASCADE 
        ON DELETE RESTRICT,
    CONSTRAINT fk_orders_restaurant FOREIGN KEY (restaurant_id) 
        REFERENCES restaurants(restaurant_id) 
        ON UPDATE CASCADE 
        ON DELETE RESTRICT,
    CONSTRAINT fk_orders_partner FOREIGN KEY (partner_id) 
        REFERENCES delivery_partners(partner_id) 
        ON UPDATE CASCADE 
        ON DELETE RESTRICT,
    CONSTRAINT chk_orders_amount CHECK (order_amount > 0.00),
    CONSTRAINT chk_orders_fee CHECK (delivery_fee >= 0.00),
    CONSTRAINT chk_delivered_time_status CHECK (
        (status = 'Delivered' AND delivered_time IS NOT NULL AND delivered_time >= order_time) OR
        (status IN ('Cancelled', 'Pending') AND delivered_time IS NULL)
    )
) ENGINE=InnoDB COMMENT='Central transaction fact table capturing all order events';

-- Financial Payment Ledger Sub-Fact (1-to-1 with orders)
CREATE TABLE payments (
    payment_id INT UNSIGNED NOT NULL COMMENT 'Unique payment gateway receipt transaction number',
    order_id INT UNSIGNED NOT NULL COMMENT 'Foreign key references orders(order_id)',
    payment_mode ENUM('Credit Card', 'Debit Card', 'UPI', 'Cash on Delivery', 'Wallet') NOT NULL COMMENT 'Settlement gateway channel',
    amount DECIMAL(10,2) NOT NULL COMMENT 'Total gross amount paid including delivery fee in INR',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Ledger recording timestamp',
    CONSTRAINT pk_payments PRIMARY KEY (payment_id),
    CONSTRAINT uq_payments_order UNIQUE (order_id),
    CONSTRAINT fk_payments_order FOREIGN KEY (order_id) 
        REFERENCES orders(order_id) 
        ON UPDATE CASCADE 
        ON DELETE RESTRICT,
    CONSTRAINT chk_payments_amount CHECK (amount > 0.00)
) ENGINE=InnoDB COMMENT='Financial payment transaction ledger recording payment gateway settlements';

-- Customer Post-Delivery Feedback & Ratings Sub-Fact (1-to-0..1 with orders)
CREATE TABLE ratings (
    rating_id INT UNSIGNED NOT NULL COMMENT 'Unique survey response identifier',
    order_id INT UNSIGNED NOT NULL COMMENT 'Foreign key references orders(order_id)',
    customer_rating DECIMAL(2,1) NOT NULL COMMENT 'Customer rating score on a 1.0 to 5.0 scale',
    feedback VARCHAR(255) NOT NULL COMMENT 'Customer feedback category text or free comment',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Survey submission timestamp',
    CONSTRAINT pk_ratings PRIMARY KEY (rating_id),
    CONSTRAINT uq_ratings_order UNIQUE (order_id),
    CONSTRAINT fk_ratings_order FOREIGN KEY (order_id) 
        REFERENCES orders(order_id) 
        ON UPDATE CASCADE 
        ON DELETE RESTRICT,
    CONSTRAINT chk_ratings_score CHECK (customer_rating >= 1.0 AND customer_rating <= 5.0)
) ENGINE=InnoDB COMMENT='Post-delivery customer satisfaction rating and qualitative feedback survey';

-- ------------------------------------------------------------------------------
-- 6. OPERATIONAL & ANALYTICAL PERFORMANCE INDEXES
-- ------------------------------------------------------------------------------

-- Foreign Key Lookup & Join Performance Indexes
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_restaurant_id ON orders(restaurant_id);
CREATE INDEX idx_orders_partner_id ON orders(partner_id);

-- Operational Query Filtering & Slicing Indexes
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_order_time ON orders(order_time);
CREATE INDEX idx_orders_delivered_time ON orders(delivered_time);
CREATE INDEX idx_orders_status_time ON orders(status, order_time);

-- Merchant and Geographic Slicing Indexes
CREATE INDEX idx_restaurants_city ON restaurants(city);
CREATE INDEX idx_restaurants_cuisine ON restaurants(cuisine_type);
CREATE INDEX idx_restaurants_rating ON restaurants(rating);

-- Customer Demographics Slicing Indexes
CREATE INDEX idx_customers_city ON customers(city);
CREATE INDEX idx_customers_signup ON customers(signup_date);

-- Courier Fleet Slicing Indexes
CREATE INDEX idx_partners_vehicle ON delivery_partners(vehicle_type);
CREATE INDEX idx_partners_joining ON delivery_partners(joining_date);

-- Financial & Feedback Slicing Indexes
CREATE INDEX idx_payments_mode ON payments(payment_mode);
CREATE INDEX idx_ratings_score ON ratings(customer_rating);
CREATE INDEX idx_cb_churn ON customer_behavior(churn_flag);

-- ------------------------------------------------------------------------------
-- 7. METRIC & DDL VERIFICATION QUERY
-- ------------------------------------------------------------------------------
SELECT 
    table_name, 
    engine, 
    table_rows, 
    data_length, 
    index_length, 
    table_collation, 
    table_comment 
FROM information_schema.tables 
WHERE table_schema = 'smart_delivery_analytics'
ORDER BY table_name;
