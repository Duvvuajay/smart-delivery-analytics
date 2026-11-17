-- ==============================================================================
-- SMART DELIVERY OPERATIONS ANALYTICS SYSTEM
-- Business Analytics Module 2: Order Cancellations (PDF Problem 2)
-- Target RDBMS: MySQL 8.0+
-- File: 05_business_analytics/cancellation_analytics.sql
-- ==============================================================================

USE smart_delivery_analytics;

-- ------------------------------------------------------------------------------
-- QUESTION 1: Which restaurants receive the highest volume of cancellations?
-- ------------------------------------------------------------------------------
SELECT 
    r.restaurant_id,
    r.restaurant_name,
    r.cuisine_type,
    r.city,
    COUNT(o.order_id) AS total_orders_received,
    SUM(CASE WHEN o.status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders_count,
    ROUND(SUM(CASE WHEN o.status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(o.order_id), 2) AS cancellation_rate_pct,
    ROUND(SUM(CASE WHEN o.status = 'Cancelled' THEN o.order_amount ELSE 0 END), 2) AS lost_merchandise_value_inr
FROM orders o
INNER JOIN restaurants r ON o.restaurant_id = r.restaurant_id
GROUP BY r.restaurant_id, r.restaurant_name, r.cuisine_type, r.city
ORDER BY cancelled_orders_count DESC
LIMIT 10;


-- ------------------------------------------------------------------------------
-- QUESTION 2: Which cities have the highest cancellation rates by percentage?
-- ------------------------------------------------------------------------------
SELECT 
    r.city,
    COUNT(o.order_id) AS total_orders,
    SUM(CASE WHEN o.status = 'Delivered' THEN 1 ELSE 0 END) AS delivered_orders,
    SUM(CASE WHEN o.status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
    ROUND(SUM(CASE WHEN o.status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(o.order_id), 2) AS city_cancellation_rate_pct,
    ROUND(SUM(CASE WHEN o.status = 'Cancelled' THEN o.order_amount ELSE 0 END), 2) AS total_lost_gmv_inr
FROM orders o
INNER JOIN restaurants r ON o.restaurant_id = r.restaurant_id
GROUP BY r.city
ORDER BY city_cancellation_rate_pct DESC;


-- ------------------------------------------------------------------------------
-- QUESTION 3: Is there an association between delivery delays and cancellations?
-- ------------------------------------------------------------------------------
-- Note: Cancelled orders do not reach fulfillment, so direct delivery duration cannot be measured on cancelled orders.
-- Method: Measure whether restaurants with above-average historical delivery times suffer higher cancellation rates.
WITH restaurant_operational_stats AS (
    SELECT 
        restaurant_id,
        ROUND(AVG(CASE WHEN status = 'Delivered' THEN TIMESTAMPDIFF(MINUTE, order_time, delivered_time) END), 1) AS avg_delivery_time_mins,
        COUNT(order_id) AS total_orders,
        SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
        ROUND(SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(order_id), 2) AS cancellation_rate_pct
    FROM orders
    GROUP BY restaurant_id
)
SELECT 
    CASE 
        WHEN avg_delivery_time_mins < 52.0 THEN '1. Fast Prep Kitchens (< 52 mins)'
        WHEN avg_delivery_time_mins BETWEEN 52.0 AND 55.0 THEN '2. Moderate Prep Kitchens (52-55 mins)'
        ELSE '3. Slow Prep Kitchens (> 55 mins)'
    END AS kitchen_speed_tier,
    COUNT(*) AS restaurant_count,
    ROUND(AVG(avg_delivery_time_mins), 1) AS cohort_avg_delivery_mins,
    SUM(total_orders) AS total_orders,
    SUM(cancelled_orders) AS total_cancelled_orders,
    ROUND(SUM(cancelled_orders) * 100.0 / SUM(total_orders), 2) AS tier_cancellation_rate_pct
FROM restaurant_operational_stats
GROUP BY kitchen_speed_tier
ORDER BY kitchen_speed_tier;


-- ------------------------------------------------------------------------------
-- QUESTION 4: On which days and at which times do cancellations peak?
-- ------------------------------------------------------------------------------
-- Day-of-Week Cancellation Patterns
SELECT 
    DAYNAME(order_time) AS day_name,
    DAYOFWEEK(order_time) AS day_index,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
    ROUND(SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS cancellation_rate_pct
FROM orders
GROUP BY DAYNAME(order_time), DAYOFWEEK(order_time)
ORDER BY day_index;

-- Hour-of-Day Cancellation Heatmap Matrix
SELECT 
    HOUR(order_time) AS order_hour,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
    ROUND(SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS hourly_cancellation_rate_pct,
    ROUND(SUM(CASE WHEN status = 'Cancelled' THEN order_amount ELSE 0 END), 2) AS lost_hourly_gmv_inr
FROM orders
GROUP BY HOUR(order_time)
ORDER BY order_hour;


-- ------------------------------------------------------------------------------
-- ADDITIONAL METRICS: Monthly Cancellation Trajectory
-- ------------------------------------------------------------------------------
SELECT 
    DATE_FORMAT(order_time, '%Y-%m') AS order_month,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
    ROUND(SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS monthly_cancellation_rate_pct,
    ROUND(SUM(CASE WHEN status = 'Cancelled' THEN order_amount ELSE 0 END), 2) AS monthly_lost_revenue_inr
FROM orders
GROUP BY DATE_FORMAT(order_time, '%Y-%m')
ORDER BY order_month;
