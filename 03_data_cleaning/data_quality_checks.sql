-- ==============================================================================
-- SMART DELIVERY OPERATIONS ANALYTICS SYSTEM
-- Data Quality Audit & Anomaly Detection Queries
-- Target RDBMS: MySQL 8.0+
-- File: 03_data_cleaning/data_quality_checks.sql
-- ==============================================================================

USE smart_delivery_analytics;

-- ------------------------------------------------------------------------------
-- 1. WHITESPACE & CITY NAME STANDARDIZATION AUDIT
-- ------------------------------------------------------------------------------
-- Detect leading/trailing whitespace in city names across customers & restaurants
SELECT 
    'City Whitespace Audit' AS check_name,
    'stg_customers' AS table_name,
    city AS raw_city,
    LENGTH(city) AS raw_len,
    LENGTH(TRIM(city)) AS trim_len,
    COUNT(*) AS record_count
FROM stg_customers
WHERE LENGTH(city) != LENGTH(TRIM(city))
GROUP BY city;

SELECT 
    'City Whitespace Audit' AS check_name,
    'stg_restaurants' AS table_name,
    city AS raw_city,
    LENGTH(city) AS raw_len,
    LENGTH(TRIM(city)) AS trim_len,
    COUNT(*) AS record_count
FROM stg_restaurants
WHERE LENGTH(city) != LENGTH(TRIM(city))
GROUP BY city;

-- Cross-table city distribution check (MySQL equivalent of FULL OUTER JOIN using LEFT JOIN + RIGHT JOIN)
SELECT 
    c.city AS city_name,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    COUNT(DISTINCT r.restaurant_id) AS restaurant_count
FROM stg_customers c
LEFT JOIN stg_restaurants r ON c.city = r.city
GROUP BY c.city
UNION
SELECT 
    r.city AS city_name,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    COUNT(DISTINCT r.restaurant_id) AS restaurant_count
FROM stg_customers c
RIGHT JOIN stg_restaurants r ON c.city = r.city
GROUP BY r.city
ORDER BY city_name;

-- ------------------------------------------------------------------------------
-- 2. RATING BOUNDARY AUDIT ([1.0, 5.0] Valid Range)
-- ------------------------------------------------------------------------------
-- Audit restaurant ratings
SELECT 
    'Restaurant Rating Boundaries' AS check_name,
    MIN(CAST(rating AS DECIMAL(3,2))) AS min_rating,
    MAX(CAST(rating AS DECIMAL(3,2))) AS max_rating,
    AVG(CAST(rating AS DECIMAL(3,2))) AS avg_rating,
    COUNT(CASE WHEN CAST(rating AS DECIMAL(3,2)) < 1.0 OR CAST(rating AS DECIMAL(3,2)) > 5.0 THEN 1 END) AS out_of_bounds_count
FROM stg_restaurants;

-- Audit customer survey ratings
SELECT 
    'Customer Rating Boundaries' AS check_name,
    MIN(CAST(customer_rating AS DECIMAL(3,2))) AS min_rating,
    MAX(CAST(customer_rating AS DECIMAL(3,2))) AS max_rating,
    AVG(CAST(customer_rating AS DECIMAL(3,2))) AS avg_rating,
    COUNT(CASE WHEN CAST(customer_rating AS DECIMAL(3,2)) < 1.0 OR CAST(customer_rating AS DECIMAL(3,2)) > 5.0 THEN 1 END) AS out_of_bounds_count
FROM stg_ratings;

-- ------------------------------------------------------------------------------
-- 3. DUPLICATE ORDER & PAYMENT RECORD AUDIT
-- ------------------------------------------------------------------------------
-- Duplicate orders check
SELECT 
    'Duplicate Orders Audit' AS check_name,
    order_id,
    COUNT(*) AS occurrence_count
FROM stg_orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Duplicate payments check (by payment_id)
SELECT 
    'Duplicate Payment ID Audit' AS check_name,
    payment_id,
    COUNT(*) AS occurrence_count
FROM stg_payments
GROUP BY payment_id
HAVING COUNT(*) > 1;

-- Duplicate payments check (by order_id - 1:1 rule)
SELECT 
    'Multiple Payments per Order Audit' AS check_name,
    order_id,
    COUNT(*) AS occurrence_count
FROM stg_payments
GROUP BY order_id
HAVING COUNT(*) > 1;

-- ------------------------------------------------------------------------------
-- 4. MISSING DELIVERY TIMESTAMPS & STATUS CORRELATION AUDIT
-- ------------------------------------------------------------------------------
SELECT 
    'Delivery Timestamp Status Matrix' AS check_name,
    status,
    COUNT(*) AS total_orders,
    COUNT(CASE WHEN delivered_time IS NOT NULL AND TRIM(delivered_time) != '' THEN 1 END) AS populated_timestamps,
    COUNT(CASE WHEN delivered_time IS NULL OR TRIM(delivered_time) = '' THEN 1 END) AS null_or_empty_timestamps,
    MIN(CASE WHEN status = 'Delivered' THEN TIMESTAMPDIFF(MINUTE, order_time, delivered_time) END) AS min_delivery_duration_mins,
    MAX(CASE WHEN status = 'Delivered' THEN TIMESTAMPDIFF(MINUTE, order_time, delivered_time) END) AS max_delivery_duration_mins,
    AVG(CASE WHEN status = 'Delivered' THEN TIMESTAMPDIFF(MINUTE, order_time, delivered_time) END) AS avg_delivery_duration_mins
FROM stg_orders
GROUP BY status;

-- ------------------------------------------------------------------------------
-- 5. ORDER STATUS DOMAIN INTEGRITY
-- ------------------------------------------------------------------------------
SELECT 
    'Order Status Domain Check' AS check_name,
    status AS raw_status_value,
    COUNT(*) AS count_of_orders
FROM stg_orders
GROUP BY status;

-- ------------------------------------------------------------------------------
-- 6. DATE FORMAT & PARSEABILITY AUDIT
-- ------------------------------------------------------------------------------
-- Orders date format verification
SELECT 
    'Orders Date Format Audit' AS check_name,
    COUNT(CASE WHEN STR_TO_DATE(order_time, '%Y-%m-%d %H:%i:%s') IS NULL THEN 1 END) AS invalid_order_timestamps,
    COUNT(CASE WHEN delivered_time IS NOT NULL AND TRIM(delivered_time) != '' AND STR_TO_DATE(delivered_time, '%Y-%m-%d %H:%i:%s') IS NULL THEN 1 END) AS invalid_delivered_timestamps
FROM stg_orders;

-- Customers & Partners date format verification
SELECT 
    'Entity Date Format Audit' AS check_name,
    (SELECT COUNT(*) FROM stg_customers WHERE STR_TO_DATE(signup_date, '%Y-%m-%d') IS NULL) AS invalid_signup_dates,
    (SELECT COUNT(*) FROM stg_delivery_partners WHERE STR_TO_DATE(joining_date, '%Y-%m-%d') IS NULL) AS invalid_joining_dates;

-- ------------------------------------------------------------------------------
-- 7. FINANCIAL RECONCILIATION & NUMERIC SANITY AUDIT
-- ------------------------------------------------------------------------------
-- Negative or zero balances
SELECT 
    'Financial Sanity Audit' AS check_name,
    COUNT(CASE WHEN CAST(order_amount AS DECIMAL(10,2)) <= 0 THEN 1 END) AS non_positive_order_amounts,
    COUNT(CASE WHEN CAST(delivery_fee AS DECIMAL(10,2)) < 0 THEN 1 END) AS negative_delivery_fees,
    (SELECT COUNT(CASE WHEN CAST(amount AS DECIMAL(10,2)) <= 0 THEN 1 END) FROM stg_payments) AS non_positive_payment_amounts
FROM stg_orders;

-- Order amount + delivery fee vs payment amount reconciliation
SELECT 
    'Order-Payment Amount Balance Check' AS check_name,
    COUNT(*) AS total_compared,
    SUM(CASE WHEN ABS(CAST(p.amount AS DECIMAL(10,2)) - (CAST(o.order_amount AS DECIMAL(10,2)) + CAST(o.delivery_fee AS DECIMAL(10,2)))) > 0.01 THEN 1 ELSE 0 END) AS mismatch_count
FROM stg_orders o
INNER JOIN stg_payments p ON o.order_id = p.order_id;

-- ------------------------------------------------------------------------------
-- 8. CHRONOLOGICAL SEQUENCE AUDIT (Business Anomaly Detection)
-- ------------------------------------------------------------------------------
-- Orders preceding customer signup
SELECT 
    'Orders Preceding Customer Signup' AS check_name,
    COUNT(*) AS anomaly_count,
    MIN(DATEDIFF(STR_TO_DATE(o.order_time, '%Y-%m-%d'), STR_TO_DATE(c.signup_date, '%Y-%m-%d'))) AS max_days_before_signup
FROM stg_orders o
INNER JOIN stg_customers c ON o.customer_id = c.customer_id
WHERE STR_TO_DATE(o.order_time, '%Y-%m-%d') < STR_TO_DATE(c.signup_date, '%Y-%m-%d');

-- Orders preceding partner joining
SELECT 
    'Orders Preceding Partner Joining' AS check_name,
    COUNT(*) AS anomaly_count,
    MIN(DATEDIFF(STR_TO_DATE(o.order_time, '%Y-%m-%d'), STR_TO_DATE(dp.joining_date, '%Y-%m-%d'))) AS max_days_before_joining
FROM stg_orders o
INNER JOIN stg_delivery_partners dp ON o.partner_id = dp.partner_id
WHERE STR_TO_DATE(o.order_time, '%Y-%m-%d') < STR_TO_DATE(dp.joining_date, '%Y-%m-%d');
