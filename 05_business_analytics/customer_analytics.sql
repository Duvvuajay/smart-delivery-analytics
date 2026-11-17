-- ==============================================================================
-- SMART DELIVERY OPERATIONS ANALYTICS SYSTEM
-- Business Analytics Module 4: Customer Retention (PDF Problem 4)
-- Target RDBMS: MySQL 8.0+
-- File: 05_business_analytics/customer_analytics.sql
-- ==============================================================================

USE smart_delivery_analytics;

-- ------------------------------------------------------------------------------
-- QUESTION 1: Who are the top 10 most valuable customers by lifetime spending?
-- ------------------------------------------------------------------------------
SELECT 
    c.customer_id,
    c.customer_name,
    c.city,
    c.gender,
    c.age,
    c.signup_date,
    cb.total_orders,
    cb.total_spending,
    cb.avg_order_value,
    cb.last_order_days,
    CASE WHEN cb.churn_flag = 1 THEN 'Churned' ELSE 'Active' END AS retention_status,
    DENSE_RANK() OVER (ORDER BY cb.total_spending DESC) AS ltv_rank
FROM customers c
INNER JOIN customer_behavior cb ON c.customer_id = cb.customer_id
ORDER BY cb.total_spending DESC
LIMIT 10;


-- ------------------------------------------------------------------------------
-- QUESTION 2: Which customers order most frequently, and what is their average order value?
-- ------------------------------------------------------------------------------
SELECT 
    c.customer_id,
    c.customer_name,
    c.city,
    cb.total_orders AS lifetime_delivered_orders,
    cb.avg_order_value,
    cb.total_spending,
    cb.last_order_days,
    DENSE_RANK() OVER (ORDER BY cb.total_orders DESC, cb.total_spending DESC) AS frequency_rank
FROM customers c
INNER JOIN customer_behavior cb ON c.customer_id = cb.customer_id
ORDER BY cb.total_orders DESC, cb.total_spending DESC
LIMIT 15;


-- ------------------------------------------------------------------------------
-- QUESTION 3: Which customers have gone inactive in the last 90 days?
-- (Note: Measured relative to the January 2025 benchmark date in customer_behavior)
-- ------------------------------------------------------------------------------
SELECT 
    c.customer_id,
    c.customer_name,
    c.city,
    c.age,
    cb.total_orders,
    cb.total_spending,
    cb.last_order_days AS days_since_last_order,
    cb.churn_flag
FROM customers c
INNER JOIN customer_behavior cb ON c.customer_id = cb.customer_id
WHERE cb.last_order_days > 90
ORDER BY cb.last_order_days DESC, cb.total_spending DESC
LIMIT 20;


-- ------------------------------------------------------------------------------
-- QUESTION 4: What behavioural patterns signal that a customer is about to churn?
-- ------------------------------------------------------------------------------
WITH customer_activity_profile AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        c.city,
        cb.total_orders,
        cb.total_spending,
        cb.avg_order_value,
        cb.last_order_days,
        cb.churn_flag,
        CASE 
            WHEN cb.last_order_days <= 30 THEN '1. Highly Engaged (0-30 days)'
            WHEN cb.last_order_days BETWEEN 31 AND 60 THEN '2. Moderate Activity (31-60 days)'
            WHEN cb.last_order_days BETWEEN 61 AND 90 THEN '3. At-Risk Warning (61-90 days)'
            ELSE '4. Churned (> 90 days)'
        END AS engagement_risk_cohort
    FROM customers c
    INNER JOIN customer_behavior cb ON c.customer_id = cb.customer_id
)
SELECT 
    engagement_risk_cohort,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customer_behavior), 2) AS pct_of_customer_base,
    ROUND(AVG(total_orders), 1) AS avg_lifetime_orders,
    ROUND(AVG(total_spending), 2) AS avg_lifetime_spend,
    ROUND(AVG(avg_order_value), 2) AS avg_ticket_size,
    ROUND(AVG(last_order_days), 1) AS mean_inactivity_days
FROM customer_activity_profile
GROUP BY engagement_risk_cohort
ORDER BY engagement_risk_cohort;


-- ------------------------------------------------------------------------------
-- ADDITIONAL METRICS: Repeat Customer Rate & Platform Retention Summary
-- ------------------------------------------------------------------------------
SELECT 
    COUNT(*) AS total_registered_customers,
    SUM(CASE WHEN cb.total_orders > 1 THEN 1 ELSE 0 END) AS repeat_customers_count,
    ROUND(SUM(CASE WHEN cb.total_orders > 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS repeat_customer_rate_pct,
    SUM(CASE WHEN cb.churn_flag = 0 THEN 1 ELSE 0 END) AS active_retained_customers,
    ROUND(SUM(CASE WHEN cb.churn_flag = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS active_retention_rate_pct,
    SUM(CASE WHEN cb.churn_flag = 1 THEN 1 ELSE 0 END) AS churned_inactive_customers,
    ROUND(SUM(CASE WHEN cb.churn_flag = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate_pct,
    ROUND(AVG(cb.total_spending), 2) AS overall_avg_customer_ltv
FROM customers c
INNER JOIN customer_behavior cb ON c.customer_id = cb.customer_id;
