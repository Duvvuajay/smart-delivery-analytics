-- ==============================================================================
-- SMART DELIVERY OPERATIONS ANALYTICS SYSTEM
-- Business Analytics Module 5: Delivery Partner Performance (PDF Problem 5)
-- Target RDBMS: MySQL 8.0+
-- File: 05_business_analytics/partner_analytics.sql
-- ==============================================================================

USE smart_delivery_analytics;

-- ------------------------------------------------------------------------------
-- QUESTION 1: Who are the fastest delivery partners based on average delivery time?
-- ------------------------------------------------------------------------------
SELECT 
    dp.partner_id,
    dp.partner_name,
    dp.vehicle_type,
    COUNT(o.order_id) AS delivered_orders,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time)), 2) AS avg_delivery_time_mins,
    MIN(TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time)) AS fastest_delivery_mins,
    MAX(TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time)) AS slowest_delivery_mins,
    DENSE_RANK() OVER (ORDER BY AVG(TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time)) ASC) AS speed_rank
FROM delivery_partners dp
INNER JOIN orders o ON dp.partner_id = o.partner_id
WHERE o.status = 'Delivered' AND o.delivered_time IS NOT NULL
GROUP BY dp.partner_id, dp.partner_name, dp.vehicle_type
HAVING COUNT(o.order_id) >= 25
ORDER BY avg_delivery_time_mins ASC
LIMIT 10;


-- ------------------------------------------------------------------------------
-- QUESTION 2: Which partners handle the highest volume of successful deliveries?
-- ------------------------------------------------------------------------------
SELECT 
    dp.partner_id,
    dp.partner_name,
    dp.vehicle_type,
    dp.joining_date,
    COUNT(o.order_id) AS successful_deliveries,
    ROUND(SUM(o.delivery_fee), 2) AS total_delivery_fees_earned,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time)), 2) AS avg_delivery_time_mins,
    DENSE_RANK() OVER (ORDER BY COUNT(o.order_id) DESC) AS volume_rank
FROM delivery_partners dp
INNER JOIN orders o ON dp.partner_id = o.partner_id
WHERE o.status = 'Delivered'
GROUP BY dp.partner_id, dp.partner_name, dp.vehicle_type, dp.joining_date
ORDER BY successful_deliveries DESC
LIMIT 15;


-- ------------------------------------------------------------------------------
-- QUESTION 3: Which partners are associated with the most cancellations or delays?
-- ------------------------------------------------------------------------------
WITH partner_issues AS (
    SELECT 
        dp.partner_id,
        dp.partner_name,
        dp.vehicle_type,
        COUNT(o.order_id) AS total_assigned_orders,
        SUM(CASE WHEN o.status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
        ROUND(SUM(CASE WHEN o.status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(o.order_id), 2) AS cancellation_rate_pct,
        SUM(CASE WHEN o.status = 'Delivered' AND TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time) > 45 THEN 1 ELSE 0 END) AS delayed_orders,
        ROUND(SUM(CASE WHEN o.status = 'Delivered' AND TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time) > 45 THEN 1 ELSE 0 END) * 100.0 / NULLIF(SUM(CASE WHEN o.status = 'Delivered' THEN 1 ELSE 0 END), 0), 2) AS delay_rate_pct
    FROM delivery_partners dp
    INNER JOIN orders o ON dp.partner_id = o.partner_id
    GROUP BY dp.partner_id, dp.partner_name, dp.vehicle_type
)
SELECT 
    partner_id,
    partner_name,
    vehicle_type,
    total_assigned_orders,
    cancelled_orders,
    cancellation_rate_pct,
    delayed_orders,
    delay_rate_pct
FROM partner_issues
WHERE total_assigned_orders >= 35
ORDER BY cancellation_rate_pct DESC, delay_rate_pct DESC
LIMIT 15;


-- ------------------------------------------------------------------------------
-- QUESTION 4: What is the average customer rating received per delivery partner?
-- ------------------------------------------------------------------------------
SELECT 
    dp.partner_id,
    dp.partner_name,
    dp.vehicle_type,
    COUNT(DISTINCT o.order_id) AS total_delivered_orders,
    COUNT(r.rating_id) AS total_reviews_received,
    ROUND(COUNT(r.rating_id) * 100.0 / COUNT(DISTINCT o.order_id), 1) AS rating_coverage_pct,
    ROUND(AVG(r.customer_rating), 2) AS avg_partner_rating,
    SUM(CASE WHEN r.customer_rating = 5.0 THEN 1 ELSE 0 END) AS five_star_ratings,
    SUM(CASE WHEN r.customer_rating <= 2.0 THEN 1 ELSE 0 END) AS poor_ratings
FROM delivery_partners dp
INNER JOIN orders o ON dp.partner_id = o.partner_id AND o.status = 'Delivered'
INNER JOIN ratings r ON o.order_id = r.order_id
GROUP BY dp.partner_id, dp.partner_name, dp.vehicle_type
HAVING COUNT(r.rating_id) >= 20
ORDER BY avg_partner_rating DESC
LIMIT 15;


-- ------------------------------------------------------------------------------
-- ADDITIONAL METRICS: Vehicle Type Modality Performance Comparison
-- ------------------------------------------------------------------------------
SELECT 
    dp.vehicle_type,
    COUNT(DISTINCT dp.partner_id) AS active_partners_in_category,
    COUNT(o.order_id) AS total_deliveries_fulfilled,
    ROUND(COUNT(o.order_id) * 1.0 / COUNT(DISTINCT dp.partner_id), 1) AS avg_deliveries_per_courier,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time)), 2) AS avg_delivery_time_mins,
    ROUND(SUM(CASE WHEN TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time) > 45 THEN 1 ELSE 0 END) * 100.0 / COUNT(o.order_id), 2) AS delayed_delivery_pct,
    ROUND(AVG(r.customer_rating), 2) AS avg_customer_rating
FROM delivery_partners dp
INNER JOIN orders o ON dp.partner_id = o.partner_id AND o.status = 'Delivered'
LEFT JOIN ratings r ON o.order_id = r.order_id
GROUP BY dp.vehicle_type
ORDER BY avg_delivery_time_mins ASC;
