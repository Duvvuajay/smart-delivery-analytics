-- ==============================================================================
-- SMART DELIVERY OPERATIONS ANALYTICS SYSTEM
-- Milestone 6: Standard Reporting Queries & Stored Procedure Execution Tests
-- Target RDBMS: MySQL 8.0+
-- File: 06_database_objects/reporting_queries.sql
-- ==============================================================================

USE smart_delivery_analytics;

-- ------------------------------------------------------------------------------
-- 1. EXECUTIVE REPORTING EXTRACTS (From Views)
-- ------------------------------------------------------------------------------

-- Extract 1: Executive KPI Scorecard
SELECT * FROM vw_dashboard_overview;

-- Extract 2: Monthly Financial Trajectory & MoM Growth
SELECT 
    order_month,
    delivered_orders,
    merchandise_revenue,
    delivery_fee_revenue,
    total_net_revenue,
    mom_growth_rate_pct
FROM vw_monthly_revenue
ORDER BY order_month DESC;

-- Extract 3: Metropolitan City Operational Benchmark
SELECT 
    city,
    total_orders,
    delivered_orders,
    cancellation_rate_pct,
    total_realized_revenue,
    avg_delivery_time_mins,
    delayed_delivery_pct
FROM vw_city_performance
ORDER BY total_realized_revenue DESC;

-- Extract 4: SLA Delivery Duration Tiers
SELECT * FROM vw_delivery_performance ORDER BY delivery_tier;

-- Extract 5: Customer Spend Tier Segmentation
SELECT * FROM vw_customer_segments ORDER BY spend_tier;

-- Extract 6: Payment Channel Popularity & Yield
SELECT * FROM vw_payment_analysis ORDER BY total_collected_amount DESC;


-- ------------------------------------------------------------------------------
-- 2. PARAMETERIZED STORED PROCEDURE TEST BATTERY
-- ------------------------------------------------------------------------------

-- Test 1: Full-Year 2024 Executive Scorecard
CALL sp_get_executive_kpis('2024-01-01', '2024-12-31');

-- Test 2: Specific Month Operational Summary (October 2024 Festive Month)
CALL sp_get_monthly_kpi_summary('2024-10');

-- Test 3: Localized City Performance Report for Bangalore Hub
CALL sp_get_city_performance_report('Bangalore');

-- Test 4: Immediate At-Risk Customer Alert (Dormancy between 75 and 89 days)
CALL sp_identify_at_risk_customers(75);

-- Test 5: Courier Partner 360-Degree Scorecard for Partner ID 10
CALL sp_partner_scorecard(10);
