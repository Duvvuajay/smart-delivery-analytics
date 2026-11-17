-- ==============================================================================
-- SMART DELIVERY OPERATIONS ANALYTICS SYSTEM
-- Milestone 6: Performance Indexing & Query Plan Optimization
-- Target RDBMS: MySQL 8.0+
-- File: 06_database_objects/indexes.sql
-- ==============================================================================

USE smart_delivery_analytics;

-- ------------------------------------------------------------------------------
-- 1. ANALYTICAL FEATURE MART ADDITIONAL INDEXES (SAFE CREATION)
-- ------------------------------------------------------------------------------
-- Ensure idx_cb_recency exists on customer_behavior(last_order_days)

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_create_index_if_not_exists $$
CREATE PROCEDURE sp_create_index_if_not_exists(
    IN p_table_name VARCHAR(64),
    IN p_index_name VARCHAR(64),
    IN p_columns VARCHAR(255)
)
BEGIN
    DECLARE v_exists INT;
    SELECT COUNT(*) INTO v_exists
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = p_table_name
      AND index_name = p_index_name;

    IF v_exists = 0 THEN
        SET @sql = CONCAT('CREATE INDEX ', p_index_name, ' ON ', p_table_name, '(', p_columns, ')');
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END $$

DELIMITER ;

CALL sp_create_index_if_not_exists('customer_behavior', 'idx_cb_recency', 'last_order_days');

DROP PROCEDURE IF EXISTS sp_create_index_if_not_exists;

-- ------------------------------------------------------------------------------
-- 2. EXECUTION PLAN VALIDATION & BENCHMARKING (EXPLAIN)
-- ------------------------------------------------------------------------------

-- Benchmark 1: Monthly Delivered Revenue Filtering
-- Query Plan uses: idx_orders_status_time (Index Range Scan)
EXPLAIN
SELECT 
    DATE_FORMAT(order_time, '%Y-%m') AS order_month,
    COUNT(order_id) AS delivered_orders,
    SUM(order_amount) AS revenue
FROM orders
WHERE status = 'Delivered'
  AND order_time >= '2024-01-01 00:00:00'
GROUP BY DATE_FORMAT(order_time, '%Y-%m');

-- Benchmark 2: Multi-Table Operational Join (Orders + Restaurants + Couriers)
EXPLAIN
SELECT 
    r.city,
    dp.vehicle_type,
    COUNT(o.order_id) AS delivery_count,
    AVG(TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time)) AS avg_mins
FROM orders o
INNER JOIN restaurants r ON o.restaurant_id = r.restaurant_id
INNER JOIN delivery_partners dp ON o.partner_id = dp.partner_id
WHERE o.status = 'Delivered'
GROUP BY r.city, dp.vehicle_type;

-- Benchmark 3: High-Value Customer Dormancy Subquery
EXPLAIN
SELECT 
    c.customer_id,
    c.customer_name,
    cb.total_spending,
    cb.last_order_days
FROM customers c
INNER JOIN customer_behavior cb ON c.customer_id = cb.customer_id
WHERE cb.last_order_days > 90
ORDER BY cb.total_spending DESC;

-- ------------------------------------------------------------------------------
-- 3. INDEX MAINTENANCE & CARDINALITY REFRESH
-- ------------------------------------------------------------------------------
ANALYZE TABLE customers;
ANALYZE TABLE customer_behavior;
ANALYZE TABLE restaurants;
ANALYZE TABLE delivery_partners;
ANALYZE TABLE orders;
ANALYZE TABLE payments;
ANALYZE TABLE ratings;
