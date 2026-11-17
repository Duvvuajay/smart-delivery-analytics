-- ==============================================================================
-- SMART DELIVERY OPERATIONS ANALYTICS SYSTEM
-- Milestone 6: Production Database Objects — Reusable SQL Views
-- Target RDBMS: MySQL 8.0+
-- File: 06_database_objects/views.sql
-- ==============================================================================

USE smart_delivery_analytics;

-- Drop views in reverse dependency order
DROP VIEW IF EXISTS vw_dim_date;
DROP VIEW IF EXISTS vw_dim_delivery_partners;
DROP VIEW IF EXISTS vw_dim_restaurants;
DROP VIEW IF EXISTS vw_dim_customers;
DROP VIEW IF EXISTS vw_fact_orders;
DROP VIEW IF EXISTS vw_payment_analysis;
DROP VIEW IF EXISTS vw_partner_performance;
DROP VIEW IF EXISTS vw_customer_segments;
DROP VIEW IF EXISTS vw_customer_retention;
DROP VIEW IF EXISTS vw_cancellation_analysis;
DROP VIEW IF EXISTS vw_delivery_performance;
DROP VIEW IF EXISTS vw_restaurant_performance;
DROP VIEW IF EXISTS vw_city_performance;
DROP VIEW IF EXISTS vw_monthly_revenue;
DROP VIEW IF EXISTS vw_dashboard_overview;

-- ------------------------------------------------------------------------------
-- 1. VIEW: vw_dashboard_overview (Executive Scorecard Baseline)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_dashboard_overview AS
SELECT 
    COUNT(o.order_id) AS total_orders,
    (SELECT COUNT(*) FROM customers) AS total_customers,
    ROUND(SUM(CASE WHEN o.status = 'Delivered' THEN o.order_amount ELSE 0 END), 2) AS total_delivered_revenue,
    ROUND(SUM(CASE WHEN o.status = 'Delivered' THEN o.delivery_fee ELSE 0 END), 2) AS total_delivery_fees,
    ROUND(SUM(CASE WHEN o.status = 'Delivered' THEN (o.order_amount + o.delivery_fee) ELSE 0 END), 2) AS total_collected_revenue,
    ROUND(AVG(CASE WHEN o.status = 'Delivered' THEN o.order_amount END), 2) AS average_order_value,
    ROUND(SUM(CASE WHEN o.status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(o.order_id), 2) AS cancellation_rate_pct,
    ROUND(AVG(CASE WHEN o.status = 'Delivered' THEN TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time) END), 2) AS avg_delivery_time_mins,
    ROUND(SUM(CASE WHEN cb.churn_flag = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT cb.customer_id), 2) AS customer_retention_rate_pct,
    (SELECT ROUND(AVG(customer_rating), 2) FROM ratings) AS avg_customer_rating
FROM orders o
CROSS JOIN customer_behavior cb;


-- ------------------------------------------------------------------------------
-- 2. VIEW: vw_monthly_revenue (Monthly Revenue & MoM Growth Trajectory)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_monthly_revenue AS
WITH monthly_metrics AS (
    SELECT 
        DATE_FORMAT(order_time, '%Y-%m') AS order_month,
        COUNT(order_id) AS total_orders,
        SUM(CASE WHEN status = 'Delivered' THEN 1 ELSE 0 END) AS delivered_orders,
        SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
        ROUND(SUM(CASE WHEN status = 'Delivered' THEN order_amount ELSE 0 END), 2) AS merchandise_revenue,
        ROUND(SUM(CASE WHEN status = 'Delivered' THEN delivery_fee ELSE 0 END), 2) AS delivery_fee_revenue,
        ROUND(SUM(CASE WHEN status = 'Delivered' THEN (order_amount + delivery_fee) ELSE 0 END), 2) AS total_net_revenue,
        ROUND(AVG(CASE WHEN status = 'Delivered' THEN order_amount END), 2) AS avg_order_value
    FROM orders
    GROUP BY DATE_FORMAT(order_time, '%Y-%m')
)
SELECT 
    order_month,
    total_orders,
    delivered_orders,
    cancelled_orders,
    merchandise_revenue,
    delivery_fee_revenue,
    total_net_revenue,
    avg_order_value,
    LAG(total_net_revenue, 1) OVER (ORDER BY order_month) AS prev_month_net_revenue,
    ROUND(total_net_revenue - LAG(total_net_revenue, 1) OVER (ORDER BY order_month), 2) AS mom_net_revenue_change,
    ROUND((total_net_revenue - LAG(total_net_revenue, 1) OVER (ORDER BY order_month)) * 100.0 / 
          NULLIF(LAG(total_net_revenue, 1) OVER (ORDER BY order_month), 0), 2) AS mom_growth_rate_pct
FROM monthly_metrics;


-- ------------------------------------------------------------------------------
-- 3. VIEW: vw_city_performance (Metropolitan Operational Benchmark)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_city_performance AS
SELECT 
    r.city,
    COUNT(o.order_id) AS total_orders,
    SUM(CASE WHEN o.status = 'Delivered' THEN 1 ELSE 0 END) AS delivered_orders,
    SUM(CASE WHEN o.status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
    ROUND(SUM(CASE WHEN o.status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(o.order_id), 2) AS cancellation_rate_pct,
    ROUND(SUM(CASE WHEN o.status = 'Delivered' THEN o.order_amount ELSE 0 END), 2) AS delivered_merchandise_revenue,
    ROUND(SUM(CASE WHEN o.status = 'Delivered' THEN o.delivery_fee ELSE 0 END), 2) AS delivered_delivery_fees,
    ROUND(SUM(CASE WHEN o.status = 'Delivered' THEN (o.order_amount + o.delivery_fee) ELSE 0 END), 2) AS total_realized_revenue,
    ROUND(SUM(CASE WHEN o.status = 'Cancelled' THEN (o.order_amount + o.delivery_fee) ELSE 0 END), 2) AS cancelled_lost_gmv,
    ROUND(AVG(CASE WHEN o.status = 'Delivered' THEN o.order_amount END), 2) AS avg_order_value,
    ROUND(AVG(CASE WHEN o.status = 'Delivered' THEN TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time) END), 2) AS avg_delivery_time_mins,
    ROUND(SUM(CASE WHEN o.status = 'Delivered' AND TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time) > 45 THEN 1 ELSE 0 END) * 100.0 / 
          NULLIF(SUM(CASE WHEN o.status = 'Delivered' THEN 1 ELSE 0 END), 0), 2) AS delayed_delivery_pct
FROM orders o
INNER JOIN restaurants r ON o.restaurant_id = r.restaurant_id
GROUP BY r.city;


-- ------------------------------------------------------------------------------
-- 4. VIEW: vw_restaurant_performance (Merchant Partner Scorecard)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_restaurant_performance AS
SELECT 
    r.restaurant_id,
    r.restaurant_name,
    r.cuisine_type,
    r.city,
    r.rating AS merchant_platform_rating,
    COUNT(o.order_id) AS total_orders,
    SUM(CASE WHEN o.status = 'Delivered' THEN 1 ELSE 0 END) AS delivered_orders,
    SUM(CASE WHEN o.status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
    ROUND(SUM(CASE WHEN o.status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(o.order_id), 2) AS cancellation_rate_pct,
    ROUND(SUM(CASE WHEN o.status = 'Delivered' THEN o.order_amount ELSE 0 END), 2) AS delivered_revenue,
    ROUND(AVG(CASE WHEN o.status = 'Delivered' THEN o.order_amount END), 2) AS avg_order_value,
    ROUND(AVG(CASE WHEN o.status = 'Delivered' THEN TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time) END), 2) AS avg_delivery_time_mins
FROM restaurants r
LEFT JOIN orders o ON r.restaurant_id = o.restaurant_id
GROUP BY r.restaurant_id, r.restaurant_name, r.cuisine_type, r.city, r.rating;


-- ------------------------------------------------------------------------------
-- 5. VIEW: vw_delivery_performance (SLA Compliance & Speed Tiers)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_delivery_performance AS
SELECT 
    CASE 
        WHEN TIMESTAMPDIFF(MINUTE, order_time, delivered_time) <= 30 THEN '1. Fast (<= 30 mins)'
        WHEN TIMESTAMPDIFF(MINUTE, order_time, delivered_time) BETWEEN 31 AND 45 THEN '2. Standard (31 - 45 mins)'
        WHEN TIMESTAMPDIFF(MINUTE, order_time, delivered_time) BETWEEN 46 AND 60 THEN '3. Delayed (46 - 60 mins)'
        ELSE '4. Severely Delayed (> 60 mins)'
    END AS delivery_tier,
    COUNT(order_id) AS order_count,
    ROUND(COUNT(order_id) * 100.0 / (SELECT COUNT(*) FROM orders WHERE status = 'Delivered'), 2) AS tier_percentage,
    ROUND(AVG(order_amount), 2) AS avg_order_amount,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, order_time, delivered_time)), 2) AS mean_duration_mins
FROM orders
WHERE status = 'Delivered' AND delivered_time IS NOT NULL
GROUP BY delivery_tier;


-- ------------------------------------------------------------------------------
-- 6. VIEW: vw_cancellation_analysis (Temporal Drop-off Heatmap)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_cancellation_analysis AS
SELECT 
    DAYNAME(order_time) AS day_of_week,
    DAYOFWEEK(order_time) AS day_of_week_num,
    HOUR(order_time) AS hour_of_day,
    COUNT(order_id) AS total_orders,
    SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
    ROUND(SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(order_id), 2) AS cancellation_rate_pct,
    ROUND(SUM(CASE WHEN status = 'Cancelled' THEN (order_amount + delivery_fee) ELSE 0 END), 2) AS lost_revenue_inr
FROM orders
GROUP BY DAYNAME(order_time), DAYOFWEEK(order_time), HOUR(order_time);


-- ------------------------------------------------------------------------------
-- 7. VIEW: vw_customer_retention (Acquisition Cohort Matrix)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_customer_retention AS
SELECT 
    CONCAT(YEAR(c.signup_date), '-Q', QUARTER(c.signup_date)) AS signup_cohort,
    COUNT(c.customer_id) AS acquired_customers,
    SUM(CASE WHEN cb.churn_flag = 0 THEN 1 ELSE 0 END) AS active_customers,
    SUM(CASE WHEN cb.churn_flag = 1 THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(SUM(CASE WHEN cb.churn_flag = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(c.customer_id), 2) AS retention_rate_pct,
    ROUND(SUM(CASE WHEN cb.churn_flag = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(c.customer_id), 2) AS churn_rate_pct,
    ROUND(AVG(cb.total_spending), 2) AS avg_cohort_ltv,
    ROUND(AVG(cb.total_orders), 1) AS avg_cohort_orders
FROM customers c
INNER JOIN customer_behavior cb ON c.customer_id = cb.customer_id
GROUP BY YEAR(c.signup_date), QUARTER(c.signup_date);


-- ------------------------------------------------------------------------------
-- 8. VIEW: vw_customer_segments (RFM Spend Tiers)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_customer_segments AS
SELECT 
    CASE 
        WHEN total_spending < 4000.00 THEN '1. Low Spender (< ₹4,000)'
        WHEN total_spending BETWEEN 4000.00 AND 7000.00 THEN '2. Medium Spender (₹4,000 - ₹7,000)'
        WHEN total_spending BETWEEN 7000.01 AND 10000.00 THEN '3. High Spender (₹7,001 - ₹10,000)'
        ELSE '4. VIP Spender (> ₹10,000)'
    END AS spend_tier,
    COUNT(customer_id) AS customer_count,
    ROUND(COUNT(customer_id) * 100.0 / (SELECT COUNT(*) FROM customer_behavior), 2) AS pct_of_customers,
    ROUND(SUM(total_spending), 2) AS total_segment_spending,
    ROUND(AVG(total_spending), 2) AS avg_customer_spending,
    ROUND(AVG(total_orders), 1) AS avg_customer_orders,
    ROUND(AVG(last_order_days), 1) AS avg_inactivity_days,
    SUM(CASE WHEN churn_flag = 1 THEN 1 ELSE 0 END) AS churned_count,
    ROUND(SUM(CASE WHEN churn_flag = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(customer_id), 2) AS segment_churn_rate_pct
FROM customer_behavior
GROUP BY spend_tier;


-- ------------------------------------------------------------------------------
-- 9. VIEW: vw_partner_performance (Courier Operational Scorecard)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_partner_performance AS
SELECT 
    dp.partner_id,
    dp.partner_name,
    dp.vehicle_type,
    dp.joining_date,
    COUNT(o.order_id) AS total_assigned_orders,
    SUM(CASE WHEN o.status = 'Delivered' THEN 1 ELSE 0 END) AS successful_deliveries,
    SUM(CASE WHEN o.status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
    ROUND(SUM(CASE WHEN o.status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(o.order_id), 2) AS cancellation_rate_pct,
    ROUND(AVG(CASE WHEN o.status = 'Delivered' THEN TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time) END), 2) AS avg_delivery_time_mins,
    ROUND(SUM(CASE WHEN o.status = 'Delivered' AND TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time) > 45 THEN 1 ELSE 0 END) * 100.0 / 
          NULLIF(SUM(CASE WHEN o.status = 'Delivered' THEN 1 ELSE 0 END), 0), 2) AS delay_rate_pct,
    ROUND(AVG(r.customer_rating), 2) AS avg_partner_rating,
    COUNT(r.rating_id) AS total_ratings_received
FROM delivery_partners dp
LEFT JOIN orders o ON dp.partner_id = o.partner_id
LEFT JOIN ratings r ON o.order_id = r.order_id
GROUP BY dp.partner_id, dp.partner_name, dp.vehicle_type, dp.joining_date;


-- ------------------------------------------------------------------------------
-- 10. VIEW: vw_payment_analysis (Gateway Settlements & Channel Yield)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_payment_analysis AS
SELECT 
    p.payment_mode,
    COUNT(o.order_id) AS settled_transactions,
    ROUND(COUNT(o.order_id) * 100.0 / (SELECT COUNT(*) FROM orders WHERE status = 'Delivered'), 2) AS transaction_popularity_pct,
    ROUND(SUM(o.order_amount), 2) AS total_merchandise_revenue,
    ROUND(SUM(o.delivery_fee), 2) AS total_delivery_fees,
    ROUND(SUM(p.amount), 2) AS total_collected_amount,
    ROUND(SUM(p.amount) * 100.0 / (SELECT SUM(amount) FROM payments p2 INNER JOIN orders o2 ON p2.order_id = o2.order_id WHERE o2.status = 'Delivered'), 2) AS financial_value_share_pct,
    ROUND(AVG(p.amount), 2) AS avg_settlement_per_order
FROM orders o
INNER JOIN payments p ON o.order_id = p.order_id
WHERE o.status = 'Delivered'
GROUP BY p.payment_mode;


-- ------------------------------------------------------------------------------
-- 11. ENRICHED STAR SCHEMA FACT VIEW: vw_fact_orders (Power BI / Excel Ready)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_fact_orders AS
SELECT 
    o.order_id,
    o.customer_id,
    o.restaurant_id,
    o.partner_id,
    o.order_time,
    CAST(o.order_time AS DATE) AS order_date,
    o.delivered_time,
    o.order_amount,
    o.delivery_fee,
    (o.order_amount + o.delivery_fee) AS total_order_value,
    o.status,
    TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time) AS delivery_duration_mins,
    CASE WHEN TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time) > 45 THEN 1 ELSE 0 END AS is_delayed,
    CASE WHEN o.status = 'Cancelled' THEN 1 ELSE 0 END AS is_cancelled,
    CASE WHEN o.status = 'Delivered' THEN 1 ELSE 0 END AS is_delivered,
    r.city AS restaurant_city,
    r.cuisine_type,
    dp.vehicle_type,
    p.payment_mode,
    p.amount AS payment_amount,
    r_sub.customer_rating,
    r_sub.feedback
FROM orders o
INNER JOIN restaurants r ON o.restaurant_id = r.restaurant_id
INNER JOIN delivery_partners dp ON o.partner_id = dp.partner_id
LEFT JOIN payments p ON o.order_id = p.order_id
LEFT JOIN ratings r_sub ON o.order_id = r_sub.order_id;
