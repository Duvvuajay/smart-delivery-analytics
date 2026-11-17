-- ============================================================
-- Smart Delivery Analytics – Workbench Startup Script
-- Saved as a Workbench Snippet for quick access
-- ============================================================

-- Paste this in any Workbench query tab and press Ctrl+Enter
-- It shows your live KPIs AND the dashboard URL to click

USE smart_delivery_analytics;

SELECT '========================================' AS info UNION ALL
SELECT ' SMART DELIVERY ANALYTICS DASHBOARD   ' UNION ALL
SELECT '========================================' UNION ALL
SELECT ' Open URL in browser:                  ' UNION ALL
SELECT ' file:///C:/sql_main/smart-delivery-analytics/dashboard/index.html' UNION ALL
SELECT '========================================';

-- Live Executive KPIs
SELECT
    COUNT(*)                                                                              AS total_orders,
    SUM(CASE WHEN status='Delivered' THEN 1 ELSE 0 END)                                  AS delivered,
    SUM(CASE WHEN status='Cancelled' THEN 1 ELSE 0 END)                                  AS cancelled,
    CONCAT(ROUND(SUM(CASE WHEN status='Cancelled' THEN 1 ELSE 0 END)*100.0/COUNT(*),1),'%') AS cancel_rate,
    CONCAT('INR ', FORMAT(SUM(CASE WHEN status='Delivered' THEN order_amount+delivery_fee ELSE 0 END),2)) AS total_revenue,
    CONCAT(ROUND(AVG(CASE WHEN status='Delivered' THEN TIMESTAMPDIFF(MINUTE,order_time,delivered_time) END),1),' mins') AS avg_delivery
FROM orders;
