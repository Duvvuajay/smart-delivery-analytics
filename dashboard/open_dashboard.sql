-- ============================================================
-- SMART DELIVERY ANALYTICS – Dashboard Launcher Script
-- Run this script in MySQL Workbench to open the dashboard
-- ============================================================
-- HOW TO USE:
--   1. Open this file in MySQL Workbench
--   2. Run the SELECT statement below
--   3. Then copy the URL shown and paste it into Chrome/Edge
--      OR use Tools → Plugins → Utilities → Open Analytics Dashboard
-- ============================================================

USE smart_delivery_analytics;

-- Quick KPI check (confirms database is live)
SELECT
    'SMART DELIVERY ANALYTICS – DASHBOARD LAUNCHER' AS project,
    COUNT(*)                                          AS total_orders,
    ROUND(SUM(CASE WHEN status='Delivered' THEN order_amount+delivery_fee ELSE 0 END),2) AS total_revenue_inr,
    ROUND(SUM(CASE WHEN status='Cancelled' THEN 1 ELSE 0 END)*100.0/COUNT(*),2)          AS cancellation_rate_pct,
    ROUND(AVG(CASE WHEN status='Delivered' THEN TIMESTAMPDIFF(MINUTE,order_time,delivered_time) END),2) AS avg_delivery_mins,
    'file:///C:/sql_main/smart-delivery-analytics/dashboard/index.html' AS dashboard_url
FROM orders;
