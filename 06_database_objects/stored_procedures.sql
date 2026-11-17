-- ==============================================================================
-- SMART DELIVERY OPERATIONS ANALYTICS SYSTEM
-- Milestone 6: Production Stored Procedures (Automated Reporting & Diagnostics)
-- Target RDBMS: MySQL 8.0+
-- File: 06_database_objects/stored_procedures.sql
-- ==============================================================================

USE smart_delivery_analytics;

DROP PROCEDURE IF EXISTS sp_get_executive_kpis;
DROP PROCEDURE IF EXISTS sp_get_monthly_kpi_summary;
DROP PROCEDURE IF EXISTS sp_get_city_performance_report;
DROP PROCEDURE IF EXISTS sp_identify_at_risk_customers;
DROP PROCEDURE IF EXISTS sp_partner_scorecard;

DELIMITER $$

-- ------------------------------------------------------------------------------
-- 1. PROCEDURE: sp_get_executive_kpis
-- Purpose: Returns complete executive scorecard for any custom date window.
-- Usage: CALL sp_get_executive_kpis('2024-01-01', '2024-12-31');
-- ------------------------------------------------------------------------------
CREATE PROCEDURE sp_get_executive_kpis(
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    SELECT 
        COUNT(order_id) AS total_orders,
        COUNT(CASE WHEN status = 'Delivered' THEN 1 END) AS delivered_orders,
        COUNT(CASE WHEN status = 'Cancelled' THEN 1 END) AS cancelled_orders,
        ROUND(COUNT(CASE WHEN status = 'Cancelled' THEN 1 END) * 100.0 / COUNT(order_id), 2) AS cancellation_rate_pct,
        ROUND(SUM(CASE WHEN status = 'Delivered' THEN order_amount ELSE 0 END), 2) AS net_merchandise_revenue,
        ROUND(SUM(CASE WHEN status = 'Delivered' THEN delivery_fee ELSE 0 END), 2) AS total_delivery_fees,
        ROUND(SUM(CASE WHEN status = 'Delivered' THEN (order_amount + delivery_fee) ELSE 0 END), 2) AS total_collected_revenue,
        ROUND(SUM(CASE WHEN status = 'Cancelled' THEN (order_amount + delivery_fee) ELSE 0 END), 2) AS lost_cancellation_gmv,
        ROUND(AVG(CASE WHEN status = 'Delivered' THEN order_amount END), 2) AS average_order_value,
        ROUND(AVG(CASE WHEN status = 'Delivered' THEN TIMESTAMPDIFF(MINUTE, order_time, delivered_time) END), 2) AS avg_delivery_time_mins,
        ROUND(SUM(CASE WHEN status = 'Delivered' AND TIMESTAMPDIFF(MINUTE, order_time, delivered_time) > 45 THEN 1 ELSE 0 END) * 100.0 / 
              NULLIF(COUNT(CASE WHEN status = 'Delivered' THEN 1 END), 0), 2) AS sla_breach_rate_pct
    FROM orders
    WHERE CAST(order_time AS DATE) BETWEEN p_start_date AND p_end_date;
END $$


-- ------------------------------------------------------------------------------
-- 2. PROCEDURE: sp_get_monthly_kpi_summary
-- Purpose: Generates monthly operational summary for a specified YYYY-MM.
-- Usage: CALL sp_get_monthly_kpi_summary('2024-06');
-- ------------------------------------------------------------------------------
CREATE PROCEDURE sp_get_monthly_kpi_summary(
    IN p_year_month VARCHAR(7)
)
BEGIN
    SELECT 
        p_year_month AS report_month,
        COUNT(o.order_id) AS total_orders_initiated,
        SUM(CASE WHEN o.status = 'Delivered' THEN 1 ELSE 0 END) AS delivered_orders,
        SUM(CASE WHEN o.status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
        ROUND(SUM(CASE WHEN o.status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(o.order_id), 2) AS cancellation_rate_pct,
        ROUND(SUM(CASE WHEN o.status = 'Delivered' THEN o.order_amount ELSE 0 END), 2) AS delivered_revenue_inr,
        ROUND(SUM(CASE WHEN o.status = 'Delivered' THEN o.delivery_fee ELSE 0 END), 2) AS delivery_fees_inr,
        ROUND(SUM(CASE WHEN o.status = 'Delivered' THEN (o.order_amount + o.delivery_fee) ELSE 0 END), 2) AS total_collected_inr,
        ROUND(AVG(CASE WHEN o.status = 'Delivered' THEN o.order_amount END), 2) AS avg_order_value,
        ROUND(AVG(CASE WHEN o.status = 'Delivered' THEN TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time) END), 2) AS avg_delivery_duration_mins,
        ROUND(AVG(r.customer_rating), 2) AS avg_customer_rating
    FROM orders o
    LEFT JOIN ratings r ON o.order_id = r.order_id
    WHERE DATE_FORMAT(o.order_time, '%Y-%m') = p_year_month;
END $$


-- ------------------------------------------------------------------------------
-- 3. PROCEDURE: sp_get_city_performance_report
-- Purpose: Generates localized city operational scorecard for any city hub.
-- Usage: CALL sp_get_city_performance_report('Chennai');
-- ------------------------------------------------------------------------------
CREATE PROCEDURE sp_get_city_performance_report(
    IN p_city VARCHAR(50)
)
BEGIN
    -- City Level Overview
    SELECT 
        p_city AS target_city,
        COUNT(DISTINCT r.restaurant_id) AS active_restaurants,
        COUNT(o.order_id) AS total_orders_handled,
        SUM(CASE WHEN o.status = 'Delivered' THEN 1 ELSE 0 END) AS completed_deliveries,
        SUM(CASE WHEN o.status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
        ROUND(SUM(CASE WHEN o.status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(o.order_id), 2) AS cancellation_rate_pct,
        ROUND(SUM(CASE WHEN o.status = 'Delivered' THEN o.order_amount ELSE 0 END), 2) AS net_merchandise_revenue,
        ROUND(AVG(CASE WHEN o.status = 'Delivered' THEN o.order_amount END), 2) AS avg_ticket_size,
        ROUND(AVG(CASE WHEN o.status = 'Delivered' THEN TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time) END), 2) AS avg_delivery_time_mins,
        ROUND(SUM(CASE WHEN o.status = 'Delivered' AND TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time) > 45 THEN 1 ELSE 0 END) * 100.0 / 
              NULLIF(SUM(CASE WHEN o.status = 'Delivered' THEN 1 ELSE 0 END), 0), 2) AS delay_rate_pct
    FROM restaurants r
    LEFT JOIN orders o ON r.restaurant_id = o.restaurant_id
    WHERE r.city = p_city;

    -- Top 5 Restaurants in City by Revenue
    SELECT 
        r.restaurant_id,
        r.restaurant_name,
        r.cuisine_type,
        r.rating,
        COUNT(o.order_id) AS orders_count,
        ROUND(SUM(CASE WHEN o.status = 'Delivered' THEN o.order_amount ELSE 0 END), 2) AS delivered_revenue
    FROM restaurants r
    INNER JOIN orders o ON r.restaurant_id = o.restaurant_id
    WHERE r.city = p_city
    GROUP BY r.restaurant_id, r.restaurant_name, r.cuisine_type, r.rating
    ORDER BY delivered_revenue DESC
    LIMIT 5;
END $$


-- ------------------------------------------------------------------------------
-- 4. PROCEDURE: sp_identify_at_risk_customers
-- Purpose: Identifies customers approaching churn based on custom dormancy threshold.
-- Usage: CALL sp_identify_at_risk_customers(70);
-- ------------------------------------------------------------------------------
CREATE PROCEDURE sp_identify_at_risk_customers(
    IN p_inactivity_threshold INT
)
BEGIN
    SELECT 
        c.customer_id,
        c.customer_name,
        c.city,
        c.age,
        cb.total_orders,
        cb.total_spending,
        cb.avg_order_value,
        cb.last_order_days AS days_inactive,
        (90 - cb.last_order_days) AS days_before_churn_declared,
        CASE 
            WHEN cb.total_spending >= 10000.00 THEN 'Tier 1: VIP Account'
            WHEN cb.total_spending >= 6000.00 THEN 'Tier 2: High Value'
            ELSE 'Tier 3: Standard'
        END AS account_priority
    FROM customers c
    INNER JOIN customer_behavior cb ON c.customer_id = cb.customer_id
    WHERE cb.last_order_days BETWEEN p_inactivity_threshold AND 89
      AND cb.churn_flag = 0
    ORDER BY cb.total_spending DESC;
END $$


-- ------------------------------------------------------------------------------
-- 5. PROCEDURE: sp_partner_scorecard
-- Purpose: Retrieves 360-degree performance evaluation for a specific courier ID.
-- Usage: CALL sp_partner_scorecard(10);
-- ------------------------------------------------------------------------------
CREATE PROCEDURE sp_partner_scorecard(
    IN p_partner_id INT
)
BEGIN
    SELECT 
        dp.partner_id,
        dp.partner_name,
        dp.vehicle_type,
        dp.joining_date,
        COUNT(o.order_id) AS total_assigned_orders,
        SUM(CASE WHEN o.status = 'Delivered' THEN 1 ELSE 0 END) AS successful_deliveries,
        SUM(CASE WHEN o.status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
        ROUND(SUM(CASE WHEN o.status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(o.order_id), 2) AS partner_cancellation_rate,
        ROUND(SUM(o.delivery_fee), 2) AS total_delivery_fees_earned,
        ROUND(AVG(CASE WHEN o.status = 'Delivered' THEN TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time) END), 2) AS partner_avg_delivery_mins,
        (SELECT ROUND(AVG(TIMESTAMPDIFF(MINUTE, order_time, delivered_time)), 2) FROM orders WHERE status = 'Delivered') AS platform_avg_delivery_mins,
        ROUND(AVG(r.customer_rating), 2) AS partner_avg_csat,
        (SELECT ROUND(AVG(customer_rating), 2) FROM ratings) AS platform_avg_csat
    FROM delivery_partners dp
    LEFT JOIN orders o ON dp.partner_id = o.partner_id
    LEFT JOIN ratings r ON o.order_id = r.order_id
    WHERE dp.partner_id = p_partner_id
    GROUP BY dp.partner_id, dp.partner_name, dp.vehicle_type, dp.joining_date;
END $$

DELIMITER ;
