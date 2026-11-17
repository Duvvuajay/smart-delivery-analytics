-- ==============================================================================
-- SMART DELIVERY OPERATIONS ANALYTICS SYSTEM
-- Business Analytics Module 3: Revenue Optimisation (PDF Problem 3)
-- Target RDBMS: MySQL 8.0+
-- File: 05_business_analytics/revenue_analytics.sql
-- ==============================================================================

USE smart_delivery_analytics;

-- ------------------------------------------------------------------------------
-- QUESTION 1: Which restaurants generate the highest total revenue?
-- ------------------------------------------------------------------------------
SELECT 
    r.restaurant_id,
    r.restaurant_name,
    r.cuisine_type,
    r.city,
    COUNT(o.order_id) AS delivered_orders,
    ROUND(SUM(o.order_amount), 2) AS net_merchandise_revenue,
    ROUND(SUM(o.delivery_fee), 2) AS total_delivery_fees,
    ROUND(SUM(o.order_amount + o.delivery_fee), 2) AS total_customer_spend,
    ROUND(AVG(o.order_amount), 2) AS avg_order_ticket
FROM orders o
INNER JOIN restaurants r ON o.restaurant_id = r.restaurant_id
WHERE o.status = 'Delivered'
GROUP BY r.restaurant_id, r.restaurant_name, r.cuisine_type, r.city
ORDER BY net_merchandise_revenue DESC
LIMIT 10;


-- ------------------------------------------------------------------------------
-- QUESTION 2: Which cities contribute the most to overall company revenue?
-- ------------------------------------------------------------------------------
WITH city_totals AS (
    SELECT 
        r.city,
        COUNT(o.order_id) AS delivered_orders,
        ROUND(SUM(o.order_amount), 2) AS city_delivered_revenue,
        ROUND(SUM(o.delivery_fee), 2) AS city_delivery_fees,
        ROUND(SUM(o.order_amount + o.delivery_fee), 2) AS city_total_revenue,
        ROUND(AVG(o.order_amount), 2) AS avg_order_value
    FROM orders o
    INNER JOIN restaurants r ON o.restaurant_id = r.restaurant_id
    WHERE o.status = 'Delivered'
    GROUP BY r.city
)
SELECT 
    city,
    delivered_orders,
    city_delivered_revenue,
    ROUND(city_delivered_revenue * 100.0 / SUM(city_delivered_revenue) OVER (), 2) AS revenue_share_pct,
    city_delivery_fees,
    city_total_revenue,
    avg_order_value,
    DENSE_RANK() OVER (ORDER BY city_delivered_revenue DESC) AS city_revenue_rank
FROM city_totals
ORDER BY city_delivered_revenue DESC;


-- ------------------------------------------------------------------------------
-- QUESTION 3: Which payment methods are most popular and most valuable?
-- ------------------------------------------------------------------------------
SELECT 
    p.payment_mode,
    COUNT(o.order_id) AS settled_transactions,
    ROUND(COUNT(o.order_id) * 100.0 / (SELECT COUNT(*) FROM orders WHERE status = 'Delivered'), 2) AS transaction_popularity_pct,
    ROUND(SUM(o.order_amount), 2) AS total_merchandise_revenue,
    ROUND(SUM(o.delivery_fee), 2) AS total_delivery_fees,
    ROUND(SUM(p.amount), 2) AS total_collected_amount,
    ROUND(SUM(p.amount) * 100.0 / (SELECT SUM(amount) FROM payments p2 INNER JOIN orders o2 ON p2.order_id = o2.order_id WHERE o2.status = 'Delivered'), 2) AS financial_value_share_pct,
    ROUND(AVG(p.amount), 2) AS avg_ticket_size
FROM orders o
INNER JOIN payments p ON o.order_id = p.order_id
WHERE o.status = 'Delivered'
GROUP BY p.payment_mode
ORDER BY total_collected_amount DESC;


-- ------------------------------------------------------------------------------
-- QUESTION 4: What are the monthly revenue trends and MoM growth over the past year?
-- ------------------------------------------------------------------------------
WITH monthly_perf AS (
    SELECT 
        DATE_FORMAT(order_time, '%Y-%m') AS order_month,
        COUNT(order_id) AS delivered_orders,
        ROUND(SUM(order_amount), 2) AS merchandise_revenue,
        ROUND(SUM(delivery_fee), 2) AS delivery_fee_revenue,
        ROUND(SUM(order_amount + delivery_fee), 2) AS total_net_revenue
    FROM orders
    WHERE status = 'Delivered'
    GROUP BY DATE_FORMAT(order_time, '%Y-%m')
)
SELECT 
    order_month,
    delivered_orders,
    merchandise_revenue,
    delivery_fee_revenue,
    total_net_revenue,
    LAG(total_net_revenue, 1) OVER (ORDER BY order_month) AS prev_month_net_revenue,
    ROUND(total_net_revenue - LAG(total_net_revenue, 1) OVER (ORDER BY order_month), 2) AS mom_revenue_change,
    ROUND((total_net_revenue - LAG(total_net_revenue, 1) OVER (ORDER BY order_month)) * 100.0 / LAG(total_net_revenue, 1) OVER (ORDER BY order_month), 2) AS mom_growth_rate_pct
FROM monthly_perf
ORDER BY order_month;


-- ------------------------------------------------------------------------------
-- ADDITIONAL METRICS: Financial Reconciliation Summary (Gross vs Realized vs Lost)
-- ------------------------------------------------------------------------------
SELECT 
    status AS order_status_cohort,
    COUNT(*) AS total_orders,
    ROUND(SUM(order_amount), 2) AS total_order_amount,
    ROUND(SUM(delivery_fee), 2) AS total_delivery_fees,
    ROUND(SUM(order_amount + delivery_fee), 2) AS gross_transacted_value,
    ROUND(AVG(order_amount), 2) AS avg_ticket_size,
    CASE 
        WHEN status = 'Delivered' THEN 'Realized Net Revenue (Delivered)'
        WHEN status = 'Cancelled' THEN 'Unfulfilled Lost Revenue (Cancelled)'
        ELSE 'Pending Pipeline Revenue (In Transit)'
    END AS financial_accounting_classification
FROM orders
GROUP BY status;
