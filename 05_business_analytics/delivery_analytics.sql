-- ==============================================================================
-- SMART DELIVERY OPERATIONS ANALYTICS SYSTEM
-- Business Analytics Module 1: Delivery Delays (PDF Problem 1)
-- Target RDBMS: MySQL 8.0+
-- File: 05_business_analytics/delivery_analytics.sql
-- ==============================================================================

USE smart_delivery_analytics;

-- ------------------------------------------------------------------------------
-- QUESTION 1: Which restaurants are associated with the longest average delivery times?
-- ------------------------------------------------------------------------------
SELECT 
    r.restaurant_id,
    r.restaurant_name,
    r.cuisine_type,
    r.city,
    COUNT(o.order_id) AS delivered_orders,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time)), 2) AS avg_delivery_time_mins,
    MIN(TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time)) AS fastest_delivery_mins,
    MAX(TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time)) AS slowest_delivery_mins,
    SUM(CASE WHEN TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time) > 45 THEN 1 ELSE 0 END) AS delayed_orders_count,
    ROUND(SUM(CASE WHEN TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time) > 45 THEN 1 ELSE 0 END) * 100.0 / COUNT(o.order_id), 2) AS delayed_order_pct
FROM orders o
INNER JOIN restaurants r ON o.restaurant_id = r.restaurant_id
WHERE o.status = 'Delivered' AND o.delivered_time IS NOT NULL
GROUP BY r.restaurant_id, r.restaurant_name, r.cuisine_type, r.city
ORDER BY avg_delivery_time_mins DESC
LIMIT 10;


-- ------------------------------------------------------------------------------
-- QUESTION 2: Which delivery partners have the highest average delivery time per order?
-- ------------------------------------------------------------------------------
SELECT 
    dp.partner_id,
    dp.partner_name,
    dp.vehicle_type,
    COUNT(o.order_id) AS completed_deliveries,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time)), 2) AS avg_delivery_time_mins,
    MIN(TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time)) AS min_delivery_time_mins,
    MAX(TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time)) AS max_delivery_time_mins,
    ROUND(SUM(CASE WHEN TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time) > 45 THEN 1 ELSE 0 END) * 100.0 / COUNT(o.order_id), 2) AS delay_rate_pct
FROM orders o
INNER JOIN delivery_partners dp ON o.partner_id = dp.partner_id
WHERE o.status = 'Delivered' AND o.delivered_time IS NOT NULL
GROUP BY dp.partner_id, dp.partner_name, dp.vehicle_type
HAVING COUNT(o.order_id) >= 20
ORDER BY avg_delivery_time_mins DESC
LIMIT 10;


-- ------------------------------------------------------------------------------
-- QUESTION 3: Which cities experience the most delivery delays?
-- ------------------------------------------------------------------------------
SELECT 
    r.city,
    COUNT(o.order_id) AS total_delivered_orders,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time)), 2) AS avg_delivery_time_mins,
    SUM(CASE WHEN TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time) > 45 THEN 1 ELSE 0 END) AS delayed_orders_count,
    ROUND(SUM(CASE WHEN TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time) > 45 THEN 1 ELSE 0 END) * 100.0 / COUNT(o.order_id), 2) AS delayed_order_pct,
    SUM(CASE WHEN TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time) <= 30 THEN 1 ELSE 0 END) AS on_time_orders_count,
    ROUND(SUM(CASE WHEN TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time) <= 30 THEN 1 ELSE 0 END) * 100.0 / COUNT(o.order_id), 2) AS on_time_delivery_pct
FROM orders o
INNER JOIN restaurants r ON o.restaurant_id = r.restaurant_id
WHERE o.status = 'Delivered' AND o.delivered_time IS NOT NULL
GROUP BY r.city
ORDER BY avg_delivery_time_mins DESC;


-- ------------------------------------------------------------------------------
-- QUESTION 4: Are delivery delays increasing or decreasing over time? (Monthly Trend)
-- ------------------------------------------------------------------------------
SELECT 
    DATE_FORMAT(order_time, '%Y-%m') AS order_month,
    COUNT(order_id) AS total_delivered_orders,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, order_time, delivered_time)), 2) AS avg_delivery_time_mins,
    SUM(CASE WHEN TIMESTAMPDIFF(MINUTE, order_time, delivered_time) > 45 THEN 1 ELSE 0 END) AS delayed_orders_count,
    ROUND(SUM(CASE WHEN TIMESTAMPDIFF(MINUTE, order_time, delivered_time) > 45 THEN 1 ELSE 0 END) * 100.0 / COUNT(order_id), 2) AS delayed_order_pct,
    ROUND(SUM(CASE WHEN TIMESTAMPDIFF(MINUTE, order_time, delivered_time) <= 30 THEN 1 ELSE 0 END) * 100.0 / COUNT(order_id), 2) AS on_time_delivery_pct
FROM orders
WHERE status = 'Delivered' AND delivered_time IS NOT NULL
GROUP BY DATE_FORMAT(order_time, '%Y-%m')
ORDER BY order_month;


-- ------------------------------------------------------------------------------
-- ADDITIONAL METRICS: Delivery Duration Tier Breakdown
-- ------------------------------------------------------------------------------
SELECT 
    CASE 
        WHEN TIMESTAMPDIFF(MINUTE, order_time, delivered_time) <= 30 THEN '1. Fast (<= 30 mins)'
        WHEN TIMESTAMPDIFF(MINUTE, order_time, delivered_time) BETWEEN 31 AND 45 THEN '2. Standard (31 - 45 mins)'
        WHEN TIMESTAMPDIFF(MINUTE, order_time, delivered_time) BETWEEN 46 AND 60 THEN '3. Delayed (46 - 60 mins)'
        ELSE '4. Severely Delayed (> 60 mins)'
    END AS delivery_tier,
    COUNT(*) AS order_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders WHERE status = 'Delivered'), 2) AS tier_percentage,
    ROUND(AVG(order_amount), 2) AS avg_order_ticket
FROM orders
WHERE status = 'Delivered' AND delivered_time IS NOT NULL
GROUP BY delivery_tier
ORDER BY delivery_tier;
