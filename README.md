# SMART DELIVERY OPERATIONS ANALYTICS SYSTEM
## End-to-End Analytics Engineering & Business Intelligence Project
### MySQL 8.0+ | Microsoft Excel | Microsoft Power BI Desktop

---

## 📌 Executive Summary

This repository contains the complete, enterprise-grade data analytics and business intelligence solution for **Smart Delivery Operations Analytics** (covering 10,000 orders across 1,000 customers, 100 merchant restaurants, and 200 delivery partners in 10 Indian metropolitan cities).

The system models, cleans, transforms, optimizes, and visualizes complex last-mile food delivery operations similar to Swiggy, Zomato, and DoorDash.

---

## 🏗 System Architecture & Workflow

```
[Raw CSV Datasets] (7 CSVs, 29,300 Records)
        │
        ▼
[MySQL Staging Layer] (`stg_*` Tables, Ingestion Audit Trail)
        │
        ▼
[Data Cleaning & ETL] (Whitespace Trim, Null Normalization, Rating Bounds, Enums)
        │
        ▼
[Relational Core Schema] (3NF Relational Tables with Constraints & Foreign Keys)
        │
        ▼
[Analytics & Business Logic] (71 SQL Queries, 11 Views, 5 Stored Procedures, Composite Indexes)
        │
   ┌────┴──────────────────────────┐
   ▼                               ▼
[Excel Reporting]          [Power BI Business Intelligence]
(7-Sheet Dynamic Workbook,  (Star-Schema Data Model,
 PivotTables, Slicers,      25+ Filter-Aware DAX Measures,
 Live ODBC Refresh)         7-Page Interactive Dashboard)
```

---

## 📁 Repository Directory Structure

| Directory | Contents & Purpose |
| :--- | :--- |
| **`01_database_design/`** | Relational DDL schema (`database_schema.sql`), Database Documentation (`database_documentation.md`), and ER Diagrams (`.png`, `.svg`, `.mwb`). |
| **`02_data_ingestion/`** | Staging DDL (`staging_tables.sql`), batch ingestion scripts (`bulk_insert.sql`), and load verification. |
| **`03_data_cleaning/`** | Data cleaning script (`data_cleaning.sql`), transformation ETL (`data_transformation.sql`), and quality audit test suites (`data_quality_checks.sql`). |
| **`04_sql_analysis/`** | 41 Structured SQL Queries: Beginner (`basic_queries.sql`), Intermediate (`intermediate_queries.sql`), Advanced CTE/Window Functions (`advanced_queries.sql`), and Business Case Studies (`business_case_studies.sql`). |
| **`05_business_analytics/`** | The 5 core business problem modules: Delivery Delays (`delivery_analytics.sql`), Cancellations (`cancellation_analytics.sql`), Revenue (`revenue_analytics.sql`), Customers (`customer_analytics.sql`), and Fleet Partners (`partner_analytics.sql`). |
| **`06_database_objects/`** | 11 Production Views (`views.sql`), 5 Parameterized Stored Procedures (`stored_procedures.sql`), Index Optimization (`indexes.sql`), and Reporting Queries (`reporting_queries.sql`). |
| **`07_excel/`** | 7-Sheet Styled Excel Workbook (`Smart_Delivery_Analytics.xlsx`), Python Generator (`generate_excel_workbook.py`), and Refresh SOP (`excel_connection_guide.md`). |
| **`08_powerbi/`** | Power BI Star Schema Model (`model.md`), DAX Measure Library (`dax_measures.txt`), Power Query M code (`power_query.m`), and Implementation SOP (`Power_BI_Setup_Guide.md`). |
| **`09_business_reports/`** | Executive Summary, Delay Root-Cause Analysis, Cancellation Diagnostics, and Partner Scorecards. |
| **`10_documentation/`** | Project Assessment (`PROJECT_ASSESSMENT.md`), Dataset Profile (`DATASET_PROFILE.md`), and Initial Quality Report (`DATA_QUALITY_INITIAL_REPORT.md`). |
| **`original_data/`** | Untouched source CSV files (7 files). |

---

## 🎯 Key Project Metrics (Reconciled Baseline)

- **Total Orders Initiated**: 10,000
- **Successfully Delivered Orders**: 8,197 (81.97%)
- **Cancelled Orders**: 1,803 (18.03%)
- **Total Registered Customers**: 1,000 (100% active retention across 2023–2024 cohorts)
- **Active Merchant Kitchens**: 100 outlets across 10 metropolitan hubs
- **Delivery Partner Fleet**: 200 couriers (Bike: 51, Scooter: 50, Electric Bike: 50, Bicycle: 49)
- **Delivered Gross Merchandise Revenue**: ₹4,988,962.00
- **Total Logistics Delivery Fees**: ₹409,850.00
- **Total Realized Collected Revenue**: ₹5,398,812.00
- **Average Order Ticket Size (AOV)**: ₹608.63
- **Average Delivery Duration**: 39.48 minutes
- **Customer Satisfaction CSAT**: 3.82 / 5.00 (from 7,000 survey responses)

---

## 🚀 How to Run / Recreate the Project

### 1. Database Setup
```sql
-- 1. Create Schema
SOURCE 01_database_design/database_schema.sql;

-- 2. Ingest Staging Data
SOURCE 02_data_ingestion/bulk_insert.sql;

-- 3. Clean and Transform into 3NF Core Tables
SOURCE 03_data_cleaning/data_cleaning.sql;
SOURCE 03_data_cleaning/data_transformation.sql;
SOURCE 03_data_cleaning/data_quality_checks.sql;

-- 4. Deploy Views, Procedures & Indexes
SOURCE 06_database_objects/views.sql;
SOURCE 06_database_objects/stored_procedures.sql;
SOURCE 06_database_objects/indexes.sql;
```

### 2. Verify with Stored Procedures
```sql
CALL sp_get_executive_kpis('2024-01-01', '2024-12-31');
CALL sp_get_city_performance_report('Bengaluru');
CALL sp_partner_scorecard(1);
```

### 3. Open Excel Reporting Workbook
Open `07_excel/Smart_Delivery_Analytics.xlsx` in Microsoft Excel. Click **Data → Refresh All** to refresh data from MySQL.

### 4. Open Power BI
Follow `08_powerbi/Power_BI_Setup_Guide.md` to connect to `smart_delivery_analytics` and paste the DAX library from `08_powerbi/dax_measures.txt`.

---

## 🏆 Deliverables Checklist
- [x] Phase 1: Project Assessment & Data Profiling (`10_documentation/`)
- [x] Phase 2: Relational 3NF Database Design & ERD (`01_database_design/`)
- [x] Phase 3: Staging, Cleaning, & Validation ETL (`02_data_ingestion/`, `03_data_cleaning/`)
- [x] Phase 4 & 5: 70+ Advanced Analytical SQL Queries (`04_sql_analysis/`, `05_business_analytics/`)
- [x] Phase 6: Production Database Objects (11 Views, 5 Procedures, Indexes) (`06_database_objects/`)
- [x] Phase 7: Professional Excel Reporting Solution (`07_excel/`)
- [x] Phase 8: Power BI Star Schema & DAX Measures (`08_powerbi/`)
