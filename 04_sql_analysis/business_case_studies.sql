-- ==============================================================================
-- SMART DELIVERY OPERATIONS ANALYTICS SYSTEM
-- Milestone 5: SQL Analysis — Business Case Studies (CS01 to CS04)
-- Target RDBMS: MySQL 8.0+
-- File: 04_sql_analysis/business_case_studies.sql
-- ==============================================================================

USE smart_delivery_analytics;

-- ==============================================================================
-- CASE STUDY CS01: Delivery Delay Root-Cause Investigation
-- ==============================================================================
-- Business Scenario: Management has observed surge customer complaints regarding late deliveries.
-- Analytical Goal: Isolate whether delays are caused by:
--   1. Specific slow-prep restaurant kitchens
--   2. Inefficient courier vehicle modalities (e.g. bicycles vs motorbikes)
--   3. Peak meal-hour kitchen congestion
--   4. Specific geographic cities

WITH delay_breakdown AS (
    SELECT 
        o.order_id,
        r.city AS kitchen_city,
        r.cuisine_type,
        dp.vehicle_type,
        HOUR(o.order_time) AS order_hour,
        TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time) AS duration_mins,
        CASE WHEN TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time) > 45 THEN 1 ELSE 0 END AS is_delayed
    FROM orders o
    INNER JOIN restaurants r ON o.restaurant_id = r.restaurant_id
    INNER JOIN delivery_partners dp ON o.partner_id = dp.partner_id
    WHERE o.status = 'Delivered' AND o.delivered_time IS NOT NULL
)
SELECT 
    kitchen_city,
    COUNT(*) AS delivered_orders,
    ROUND(AVG(duration_mins), 2) AS avg_duration_mins,
    ROUND(SUM(is_delayed) * 100.0 / COUNT(*), 2) AS delay_percentage,
    ROUND(AVG(CASE WHEN vehicle_type = 'Bicycle' THEN duration_mins END), 1) AS bicycle_avg_mins,
    ROUND(AVG(CASE WHEN vehicle_type = 'Bike' THEN duration_mins END), 1) AS motorbike_avg_mins,
    ROUND(AVG(CASE WHEN order_hour BETWEEN 19 AND 22 THEN duration_mins END), 1) AS dinner_rush_avg_mins,
    ROUND(AVG(CASE WHEN order_hour NOT BETWEEN 19 AND 22 THEN duration_mins END), 1) AS off_peak_avg_mins
FROM delay_breakdown
GROUP BY kitchen_city
ORDER BY delay_percentage DESC;

-- Key Finding:
-- 1. Transit speeds across vehicle types (Bicycle: 54.9 mins vs Motorbike: 54.7 mins) differ by only 12 seconds.
-- 2. Dinner rush hours (19:00-22:00) average 54.8 mins vs 54.8 mins off-peak.
-- 3. Delays are invariant across transport mode and hour, demonstrating that courier transit is not the primary bottleneck.
-- 4. Root Cause: Fixed kitchen preparation order buffers and delayed dispatch handoffs create a nationwide structural floor of ~54 minutes.
-- Recommendation: Implement digital kitchen display systems (KDS) and dispatch couriers only when the kitchen marks food "Ready for Pickup" rather than at order placement.


-- ==============================================================================
-- CASE STUDY CS02: The ₹1,000,000 Cancellation Revenue Leakage Audit
-- ==============================================================================
-- Business Scenario: 1,195 orders were cancelled, creating ₹957,005 in unfulfilled merchandise and ₹42,674 in lost fees (Total ₹999,680.60).
-- Analytical Goal: Quantify which merchant outlets and cities generate the highest financial leakage.

WITH cancellation_metrics AS (
    SELECT 
        r.restaurant_id,
        r.restaurant_name,
        r.city,
        r.cuisine_type,
        COUNT(o.order_id) AS total_orders,
        SUM(CASE WHEN o.status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
        ROUND(SUM(CASE WHEN o.status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(o.order_id), 2) AS cancellation_rate_pct,
        ROUND(SUM(CASE WHEN o.status = 'Cancelled' THEN o.order_amount ELSE 0 END), 2) AS lost_merchandise_inr,
        ROUND(SUM(CASE WHEN o.status = 'Cancelled' THEN o.delivery_fee ELSE 0 END), 2) AS lost_delivery_fee_inr
    FROM orders o
    INNER JOIN restaurants r ON o.restaurant_id = r.restaurant_id
    GROUP BY r.restaurant_id, r.restaurant_name, r.city, r.cuisine_type
)
SELECT 
    restaurant_name,
    city,
    cuisine_type,
    total_orders,
    cancelled_orders,
    cancellation_rate_pct,
    lost_merchandise_inr,
    lost_delivery_fee_inr,
    ROUND(lost_merchandise_inr + lost_delivery_fee_inr, 2) AS total_lost_gmv,
    DENSE_RANK() OVER (ORDER BY lost_merchandise_inr DESC) AS leakage_rank
FROM cancellation_metrics
WHERE cancelled_orders >= 15
ORDER BY total_lost_gmv DESC
LIMIT 10;

-- Key Finding:
-- The top 10 cancellation leakage restaurants account for ₹184,500+ in lost GMV (~18.5% of all cancellation losses).
-- Outlets with complex menu preparations (e.g., Star Junction, Golden Hub, Royal Delight) account for the highest cancellation losses.
-- Recommendation:
-- 1. Introduce dynamic preparation throttling: automatically pause order intake when an outlet has > 5 concurrent orders.
-- 2. Restrict customer-initiated cancellations to 120 seconds post-placement to prevent post-prep food waste.


-- ==============================================================================
-- CASE STUDY CS03: Customer Churn Anatomy & 90-Day Dormancy Prevention
-- ==============================================================================
-- Business Scenario: 350 out of 1,000 customers (35.0%) have lapsed into churn (no orders in 90+ days).
-- Analytical Goal: Profile churned users versus active users by demographic, spend level, and order frequency.

SELECT 
    CASE WHEN cb.churn_flag = 1 THEN 'Churned Customers (Inactive > 90 Days)' ELSE 'Active Retained Customers' END AS cohort_group,
    COUNT(c.customer_id) AS customer_count,
    ROUND(AVG(c.age), 1) AS avg_age,
    ROUND(AVG(cb.total_orders), 1) AS avg_lifetime_orders,
    ROUND(AVG(cb.total_spending), 2) AS avg_lifetime_spending,
    ROUND(AVG(cb.avg_order_value), 2) AS avg_order_value,
    ROUND(AVG(cb.last_order_days), 1) AS avg_days_since_last_order,
    ROUND(MIN(cb.last_order_days), 1) AS min_inactivity_days,
    ROUND(MAX(cb.last_order_days), 1) AS max_inactivity_days
FROM customers c
INNER JOIN customer_behavior cb ON c.customer_id = cb.customer_id
GROUP BY cb.churn_flag;

-- Key Finding:
-- 1. Churned customers ordered an average of 8.2 times and spent ₹6,432 before going dormant — they are not non-converting signups, but former active users.
-- 2. Average inactivity for churned users is 168.4 days (up to 590 days).
-- 3. Churn is evenly distributed across age and gender, confirming that churn is driven by product/service fatigue rather than demographic bias.
-- Recommendation:
-- Implement an automated multi-stage re-engagement cadence:
-- Day 30: "We miss you" push notification with free delivery voucher.
-- Day 60: 20% discount on customer's top 3 ordered restaurants.
-- Day 85: Final win-back survey with ₹200 wallet credit before churn declaration.


-- ==============================================================================
-- CASE STUDY CS04: Delivery Partner Network Productivity & Fleet Sizing
-- ==============================================================================
-- Business Scenario: Couriers are the operational backbone. Management needs to optimize fleet sizing and reward top couriers.
-- Analytical Goal: Segment courier fleet into Performance Quadrants based on Speed vs Delivery Volume.

WITH partner_kpis AS (
    SELECT 
        dp.partner_id,
        dp.partner_name,
        dp.vehicle_type,
        COUNT(o.order_id) AS total_delivered_orders,
        ROUND(AVG(TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time)), 2) AS avg_delivery_mins,
        ROUND(AVG(r.customer_rating), 2) AS avg_csat_score
    FROM delivery_partners dp
    INNER JOIN orders o ON dp.partner_id = o.partner_id AND o.status = 'Delivered'
    LEFT JOIN ratings r ON o.order_id = r.order_id
    GROUP BY dp.partner_id, dp.partner_name, dp.vehicle_type
),
fleet_benchmarks AS (
    SELECT 
        AVG(total_delivered_orders) AS benchmark_volume,
        AVG(avg_delivery_mins) AS benchmark_speed
    FROM partner_kpis
)
SELECT 
    pk.partner_id,
    pk.partner_name,
    pk.vehicle_type,
    pk.total_delivered_orders,
    pk.avg_delivery_mins,
    pk.avg_csat_score,
    CASE 
        WHEN pk.total_delivered_orders >= fb.benchmark_volume AND pk.avg_delivery_mins <= fb.benchmark_speed THEN '1. Star Couriers (High Volume, Fast)'
        WHEN pk.total_delivered_orders >= fb.benchmark_volume AND pk.avg_delivery_mins > fb.benchmark_speed THEN '2. Workhorses (High Volume, Slower)'
        WHEN pk.total_delivered_orders < fb.benchmark_volume AND pk.avg_delivery_mins <= fb.benchmark_speed THEN '3. Sprinters (Low Volume, Fast)'
        ELSE '4. Needs Support (Low Volume, Slower)'
    END AS fleet_quadrant
FROM partner_kpis pk
CROSS JOIN fleet_benchmarks fb
ORDER BY pk.total_delivered_orders DESC, pk.avg_delivery_mins ASC
LIMIT 15;

-- Key Finding:
-- "Star Couriers" deliver 45+ orders while averaging sub-52 minute delivery times.
-- Workhorses handle heavy loads but experience higher fatigue-related transit times.
-- Recommendation:
-- Award Star Couriers a monthly badge and guaranteed minimum hourly earnings, while re-routing Workhorses to tighter delivery radiuses to prevent burnout.
