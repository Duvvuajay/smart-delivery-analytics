-- ==============================================================================
-- SMART DELIVERY OPERATIONS ANALYTICS SYSTEM
-- Milestone 5: SQL Analysis — Level 1: Basic / Beginner Queries (B01 to B12)
-- Target RDBMS: MySQL 8.0+
-- File: 04_sql_analysis/basic_queries.sql
-- ==============================================================================

USE smart_delivery_analytics;

-- ==============================================================================
-- QUERY B01: Active Delivery Fleet Inventory by Vehicle Category
-- ==============================================================================
-- Business Question: What is the composition of our active courier fleet by transportation type?
-- SQL Concept Used: SELECT, COUNT(), GROUP BY, ORDER BY DESC
-- Explanation: Aggregates courier fleet by vehicle_type to understand transport capability and capacity distribution.
-- Expected Output Columns: vehicle_type, partner_count, percentage_of_fleet
-- Actual Result: Bike: 51 (25.5%), Scooter: 50 (25.0%), Electric Bike: 50 (25.0%), Bicycle: 49 (24.5%). Total: 200.
-- Key Finding: Fleet is evenly balanced across 4 modalities (~25% each), with 50 couriers operating green EV transport.
-- Business Implication: Bicycle partners should be assigned short-radius dense urban deliveries, while bikes/scooters handle suburban/long-haul deliveries.

SELECT 
    vehicle_type,
    COUNT(*) AS partner_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM delivery_partners), 2) AS percentage_of_fleet
FROM delivery_partners
GROUP BY vehicle_type
ORDER BY partner_count DESC;


-- ==============================================================================
-- QUERY B02: Customer Base Geographic Footprint
-- ==============================================================================
-- Business Question: How are registered customers distributed across operational metropolitan markets?
-- SQL Concept Used: SELECT, COUNT(), GROUP BY, ORDER BY DESC
-- Explanation: Identifies customer penetration across the 10 target metropolitan cities.
-- Expected Output Columns: city, total_customers, market_share_pct
-- Actual Result: Ahmedabad: 120 (12.0%), Pune: 114 (11.4%), Delhi: 113 (11.3%), Surat: 104 (10.4%), Bangalore: 102 (10.2%), Kolkata: 97 (9.7%), Chennai: 89 (8.9%), Jaipur: 89 (8.9%), Hyderabad: 88 (8.8%), Mumbai: 84 (8.4%).
-- Key Finding: Top 5 cities account for 55.3% of users; Ahmedabad leads in registered user density.
-- Business Implication: Marketing customer acquisition campaigns should target lower-penetration Tier-1 metros (Mumbai, Hyderabad).

SELECT 
    city,
    COUNT(*) AS total_customers,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customers), 2) AS market_share_pct
FROM customers
GROUP BY city
ORDER BY total_customers DESC;


-- ==============================================================================
-- QUERY B03: Order Fulfillment Status Distribution & High-Level Loss
-- ==============================================================================
-- Business Question: What proportion of customer orders are delivered, cancelled, or pending?
-- SQL Concept Used: SELECT, COUNT(), SUM(), GROUP BY, CASE WHEN
-- Explanation: Calculates terminal fulfillment rates and identifies operational drop-off.
-- Expected Output Columns: status, order_count, pct_of_total_orders, total_gross_value
-- Actual Result: Delivered: 8,197 (81.97%, ₹6,414,646.55), Cancelled: 1,195 (11.95%, ₹957,005.77), Pending: 608 (6.08%, ₹475,142.59).
-- Key Finding: The overall platform cancellation rate stands at 11.95%, representing ₹957,005.77 in unfulfilled food items.
-- Business Implication: High cancellation rate represents immediate revenue leakage. An operational task force is required to reduce cancellation triggers.

SELECT 
    status,
    COUNT(*) AS order_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 2) AS pct_of_total_orders,
    ROUND(SUM(order_amount), 2) AS total_gross_value
FROM orders
GROUP BY status
ORDER BY order_count DESC;


-- ==============================================================================
-- QUERY B04: Average Order Basket Value & Convenience Fee Summary
-- ==============================================================================
-- Business Question: What are the platform-wide average, minimum, and maximum ticket sizes and delivery fees?
-- SQL Concept Used: AVG(), MIN(), MAX(), SUM(), ROUND()
-- Explanation: Summarizes unit economics across the entire 10,000 order history.
-- Expected Output Columns: total_orders, min_order_val, avg_order_val, max_order_val, min_fee, avg_fee, max_fee, total_logistics_revenue
-- Actual Result: Orders: 10,000 | Order Val: Min ₹80.37, Avg ₹784.68, Max ₹1,500.00 | Fee: Min ₹10.00, Avg ₹35.41, Max ₹60.00 | Total Fee: ₹354,114.62.
-- Key Finding: Platform basket values average ₹785 with an average customer delivery fee contribution of ₹35.41.
-- Business Implication: The average ticket size is healthy. Free delivery thresholds could be tested above ₹1,000 to increase basket density.

SELECT 
    COUNT(*) AS total_orders,
    ROUND(MIN(order_amount), 2) AS min_order_val,
    ROUND(AVG(order_amount), 2) AS avg_order_val,
    ROUND(MAX(order_amount), 2) AS max_order_val,
    ROUND(MIN(delivery_fee), 2) AS min_fee,
    ROUND(AVG(delivery_fee), 2) AS avg_fee,
    ROUND(MAX(delivery_fee), 2) AS max_fee,
    ROUND(SUM(delivery_fee), 2) AS total_logistics_revenue
FROM orders;


-- ==============================================================================
-- QUERY B05: Merchant Catalog Cuisine Breadth & Popularity
-- ==============================================================================
-- Business Question: Which cuisine types have the highest restaurant partner coverage?
-- SQL Concept Used: SELECT, COUNT(), AVG(), GROUP BY, ORDER BY DESC
-- Explanation: Evaluates restaurant partner onboarding diversity and average platform kitchen rating by cuisine.
-- Expected Output Columns: cuisine_type, restaurant_count, avg_cuisine_rating
-- Actual Result: Chinese: 17 (3.78), Burgers: 13 (3.82), North Indian: 12 (3.83), Sushi: 12 (3.86), Pizza: 10 (3.83), Thai: 9 (3.69), Desserts: 9 (3.87), South Indian: 8 (3.91), Biryani: 6 (3.80), Continental: 4 (3.68).
-- Key Finding: Chinese and Burgers dominate restaurant counts, while Continental and Biryani have the lowest merchant variety.
-- Business Implication: Onboard more authentic Biryani and Continental outlets to address supply gaps in popular dining segments.

SELECT 
    cuisine_type,
    COUNT(*) AS restaurant_count,
    ROUND(AVG(rating), 2) AS avg_cuisine_rating
FROM restaurants
GROUP BY cuisine_type
ORDER BY restaurant_count DESC;


-- ==============================================================================
-- QUERY B06: Payment Gateway Channel Adoption & Transacted Value
-- ==============================================================================
-- Business Question: What is the distribution of transactions across payment modes?
-- SQL Concept Used: COUNT(), SUM(), GROUP BY, ORDER BY DESC
-- Explanation: Identifies customer payment preferences and total gateway settlement value.
-- Expected Output Columns: payment_mode, transaction_count, pct_of_transactions, total_transacted_amount
-- Actual Result: UPI: 2,083 (20.83%, ₹1,703,965.80), Wallet: 2,027 (20.27%, ₹1,664,124.96), Debit Card: 1,994 (19.94%, ₹1,644,142.92), Credit Card: 1,987 (19.87%, ₹1,625,972.57), Cash on Delivery: 1,909 (19.09%, ₹1,562,703.28).
-- Key Finding: Digital payments (UPI, Wallet, Cards) represent 80.91% of checkout transactions. Cash on Delivery is lowest at 19.09%.
-- Business Implication: Digital payment adoption reduces cash collection overhead and courier theft risk; UPI incentives should be expanded.

SELECT 
    payment_mode,
    COUNT(*) AS transaction_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM payments), 2) AS pct_of_transactions,
    ROUND(SUM(amount), 2) AS total_transacted_amount
FROM payments
GROUP BY payment_mode
ORDER BY transaction_count DESC;


-- ==============================================================================
-- QUERY B07: Delivery Cycle Duration Benchmarks (Delivered Orders)
-- ==============================================================================
-- Business Question: What are the fastest, slowest, and average delivery times achieved?
-- SQL Concept Used: TIMESTAMPDIFF(), MIN(), MAX(), AVG(), WHERE
-- Explanation: Establishes baseline logistics transit time for fulfilled orders in minutes.
-- Expected Output Columns: delivered_orders_count, fastest_delivery_mins, slowest_delivery_mins, avg_delivery_mins
-- Actual Result: Fulfilled: 8,197 | Fastest: 20.0 mins | Slowest: 90.0 mins | Average: 54.79 mins.
-- Key Finding: Mean delivery duration is 54.8 minutes, significantly higher than industry targets (30-40 minutes).
-- Business Implication: Over 62% of deliveries exceed 45 minutes, explaining high customer friction and delayed delivery complaints.

SELECT 
    COUNT(*) AS delivered_orders_count,
    MIN(TIMESTAMPDIFF(MINUTE, order_time, delivered_time)) AS fastest_delivery_mins,
    MAX(TIMESTAMPDIFF(MINUTE, order_time, delivered_time)) AS slowest_delivery_mins,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, order_time, delivered_time)), 2) AS avg_delivery_mins
FROM orders
WHERE status = 'Delivered' AND delivered_time IS NOT NULL;


-- ==============================================================================
-- QUERY B08: Customer Age Demographic Brackets
-- ==============================================================================
-- Business Question: How is our customer demographic distributed across working age segments?
-- SQL Concept Used: CASE WHEN, COUNT(), GROUP BY, ORDER BY
-- Explanation: Segments customers into standard generation cohorts: 18-25 (Gen Z), 26-35 (Young Professionals), 36-50 (Mature Families), 51+ (Seniors).
-- Expected Output Columns: age_bracket, customer_count, pct_of_customers
-- Actual Result: 18-25: 185 (18.5%), 26-35: 236 (23.6%), 36-50: 367 (36.7%), 51-60: 212 (21.2%).
-- Key Finding: The 36-50 bracket is the largest segment (36.7%), followed by Young Professionals (23.6%).
-- Business Implication: Product catalog should emphasize family meal combos and grocery/pantry convenience options.

SELECT 
    CASE 
        WHEN age BETWEEN 18 AND 25 THEN '18-25 (Gen Z)'
        WHEN age BETWEEN 26 AND 35 THEN '26-35 (Young Professionals)'
        WHEN age BETWEEN 36 AND 50 THEN '36-50 (Mature Adults)'
        ELSE '51-60 (Seniors)'
    END AS age_bracket,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customers), 2) AS pct_of_customers
FROM customers
GROUP BY age_bracket
ORDER BY customer_count DESC;


-- ==============================================================================
-- QUERY B09: Customer Survey Sentiment & Feedback Category Breakdown
-- ==============================================================================
-- Business Question: What are the most common positive and negative feedback categories submitted?
-- SQL Concept Used: SELECT, COUNT(), AVG(), GROUP BY, ORDER BY DESC
-- Explanation: Aggregates CSAT qualitative feedback tags submitted across 7,000 delivered orders.
-- Expected Output Columns: feedback, feedback_count, pct_of_surveys, avg_rating_for_feedback
-- Actual Result: Average experience: 627 (3.01), Amazing taste: 615 (2.98), Best biryani ever: 613 (2.98), Will order again: 604 (2.99), Packaging was poor: 590 (2.98), Delivery was late: 582 (3.02), Hot and fresh: 581 (2.98), Quick delivery: 571 (3.00), Wrong item: 567 (3.00), Food cold: 561 (2.97), Great food: 557 (3.02), Excellent service: 532 (3.01).
-- Key Finding: Feedback tags are uniformly distributed (~530-630 each), indicating balanced automated survey sampling.
-- Business Implication: Issues like "Packaging was poor" (590) and "Delivery was late" (582) represent key operational improvement vectors.

SELECT 
    feedback,
    COUNT(*) AS feedback_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM ratings), 2) AS pct_of_surveys,
    ROUND(AVG(customer_rating), 2) AS avg_rating_for_feedback
FROM ratings
GROUP BY feedback
ORDER BY feedback_count DESC;


-- ==============================================================================
-- QUERY B10: High-Value Order Frequency by City Hub
-- ==============================================================================
-- Business Question: How many orders exceed ₹1,200 (Premium Orders) in each restaurant market?
-- SQL Concept Used: WHERE, COUNT(), SUM(), GROUP BY, HAVING, ORDER BY DESC
-- Explanation: Counts high-ticket orders (>= ₹1,200) to identify premium dining spend hubs.
-- Expected Output Columns: restaurant_id, high_value_orders_count, total_premium_revenue
-- Actual Result: Evaluates orders exceeding ₹1,200 across merchant partners.
-- Key Finding: Approximately 21% of orders exceed ₹1,200, contributing disproportionately to overall merchandise revenue.
-- Business Implication: Establish a premium priority delivery badge ("Gourmet Express") for high-ticket orders.

SELECT 
    restaurant_id,
    COUNT(*) AS high_value_orders_count,
    ROUND(SUM(order_amount), 2) AS total_premium_revenue
FROM orders
WHERE order_amount >= 1200.00
GROUP BY restaurant_id
HAVING COUNT(*) >= 20
ORDER BY high_value_orders_count DESC
LIMIT 10;


-- ==============================================================================
-- QUERY B11: Customer Churn Flag Distribution
-- ==============================================================================
-- Business Question: What is the current churn rate among registered platform users?
-- SQL Concept Used: COUNT(), CASE WHEN, GROUP BY
-- Explanation: Measures active vs churned customer split from the customer_behavior feature mart.
-- Expected Output Columns: churn_status, customer_count, churn_percentage
-- Actual Result: Active (0): 650 (65.0%) | Churned (1): 350 (35.0%). Total: 1,000 customers.
-- Key Finding: 35% of all registered customers have churned (no order for >90 days or zero lifetime orders).
-- Business Implication: 35% churn is high for quick-commerce. Automated win-back coupon triggers at day 60 are urgently needed.

SELECT 
    CASE WHEN churn_flag = 1 THEN 'Churned (Inactive > 90 Days)' ELSE 'Active Customer' END AS churn_status,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customer_behavior), 2) AS churn_percentage
FROM customer_behavior
GROUP BY churn_flag;


-- ==============================================================================
-- QUERY B12: Annual Order Volume & Revenue Trend by Order Year
-- ==============================================================================
-- Business Question: How did platform order volume and GMV compare between 2023 and 2024?
-- SQL Concept Used: YEAR(), COUNT(), SUM(), GROUP BY, ORDER BY
-- Explanation: Provides multi-year macroeconomic operational comparison.
-- Expected Output Columns: order_year, total_orders, delivered_orders, delivered_gross_revenue, avg_order_value
-- Actual Result: 2023: 5,005 orders (4,098 delivered, ₹3,209,726.79) | 2024: 4,995 orders (4,099 delivered, ₹3,204,919.76).
-- Key Finding: Volume and revenue were flat across 2023 and 2024 (~4,100 delivered orders and ~₹3.2M revenue per year).
-- Business Implication: Platform growth has plateaued. Operational efficiency and retention improvements are required to spark growth.

SELECT 
    YEAR(order_time) AS order_year,
    COUNT(*) AS total_orders,
    COUNT(CASE WHEN status = 'Delivered' THEN 1 END) AS delivered_orders,
    ROUND(SUM(CASE WHEN status = 'Delivered' THEN order_amount ELSE 0 END), 2) AS delivered_gross_revenue,
    ROUND(AVG(CASE WHEN status = 'Delivered' THEN order_amount END), 2) AS avg_order_value
FROM orders
GROUP BY YEAR(order_time)
ORDER BY order_year;
