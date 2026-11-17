# Power BI – Project Setup Guide

This guide walks you through creating the **Smart Delivery Analytics** Power BI solution using the artifacts you already have in the repository.

## Prerequisites
1. **Power BI Desktop** (64‑bit) installed on Windows.
2. **MySQL ODBC 8.0 Unicode Driver** (or the native MySQL connector – Power BI now supports direct MySQL connections). Verify that you can connect to the `smart_delivery_analytics` database from other tools (e.g., MySQL Workbench).
3. The MySQL user you will use must have **read‑only** permissions on all schema objects (tables, views, stored procedures).
4. The repository folder `c:\sql_main\smart-delivery-analytics\08_powerbi\` should contain:
   * `model.md` – star‑schema design (for reference).
   * `power_query.m` – Power Query (M) script that pulls the data.
   * `dax_measures.txt` – all DAX measures.
   * `Smart_Delivery_Analytics.pbix` – placeholder that you will open in Power BI.

---

## Step‑by‑Step Procedure

### 1. Open Power BI Desktop and start a new report
* File → **New**.
* Save the file immediately as `c:\sql_main\smart-delivery-analytics\08_powerbi\Smart_Delivery_Analytics.pbix`.

### 2. Connect to MySQL and load tables
1. **Home → Get Data → MySQL database**.
2. Server: `localhost` (or your MySQL host). Database: `smart_delivery_analytics`.
3. Choose **DirectQuery** (recommended for large tables) **or** Import – the project was designed for Import to leverage VertiPaq compression.
4. Authenticate with the MySQL user credentials.
5. In the Navigator, **check** the following objects:
   * `DimCustomer`  
   * `DimRestaurant`
   * `DimPartner`
   * `DimDate`
   * `FactOrders`
   * `FactPayments`
   * `FactRatings`
6. Click **Load**.

> **Tip:** If Power BI cannot see the objects, make sure they are defined as **views** in MySQL (see `vw_fact_orders` etc.) and that the user has `SELECT` rights.

### 3. Apply the Power Query (M) script (optional but recommended)
If you prefer to manage the import centrally, you can replace the auto‑generated queries with the M script:
1. In **Home → Transform data → Advanced Editor** for each table, replace the code with the corresponding query from `power_query.m` (the script contains a `Source` function that you can call for each object).
2. Save & Apply.

### 4. Define Relationships (usually auto‑detected)
Power BI will infer relationships based on column names ending with `ID`/`Key`. Verify that the following are present (as shown in `model.md`):
* `DimDate[DateKey]` → `FactOrders[DateKey]`, `FactPayments[DateKey]`, `FactRatings[DateKey]`
* `DimCustomer[CustomerID]` → `FactOrders[CustomerID]`
* `DimRestaurant[RestaurantID]` → `FactOrders[RestaurantID]`
* `DimPartner[PartnerID]` → `FactOrders[PartnerID]`
* `FactOrders[OrderID]` → `FactPayments[OrderID]` and `FactRatings[OrderID]`

Set **Cardinality** = *Many to One* (Fact → Dimension) and **Cross filter direction** = *Single*.

### 5. Paste DAX measures
1. Open the **Modeling** tab.
2. Click **New Measure**.
3. Copy the DAX formula for each measure from `dax_measures.txt` and give the measure the exact name shown in the left column.
4. Repeat for all measures (Delivery Delays, Cancellations, Revenue Optimisation, Executive KPI cards).

### 6. Build the Dashboard Pages
The PDF specification (see `Smart_Delivery_Analytics.pdf`) defines **seven** dashboard pages:
1. **Executive Summary** – KPI cards.
2. **Delivery Performance** – visualise average, fastest, slowest delivery times, city‑wise delays.
3. **Cancellation Analysis** – cancellation rates, heat‑maps by city/time.
4. **Revenue Overview** – total revenue, month‑over‑month trend, payment‑method share.
5. **Restaurant Performance** – revenue ranking, cancellation ranking.
6. **Partner Efficiency** – avg delivery time per partner, partner scorecard.
7. **Customer Insights** – churn flag, high‑value customers.

For each page, drag the appropriate visual (card, line chart, bar chart, slicer) and bind it to the corresponding DAX measure or dimension field. Use the **Slicer** pane to expose filters for *Date*, *City*, *Restaurant*, *Partner*, and *Payment Mode*.

### 7. Add Interactivity
* Enable **Drill‑through** from the Executive Summary cards to the detailed pages.
* Add **Tooltip** pages for hover‑over details (e.g., show order count when hovering a city bar).
* Configure **Bookmarks** for “Reset Filters” and “Export to PDF”.

### 8. Test & Validate
1. Switch to **Data view** and verify that the numbers match the values produced by the MySQL analytical queries (the 71 queries you already ran).
2. In **Report view**, apply a few slicers (e.g., filter to a specific month) and ensure KPI cards update accordingly.
3. Export a **PDF** of the dashboard and compare the figures with the Excel workbook to guarantee consistency.

### 9. Publish (optional)
If you have Power BI Service, publish the PBIX to a workspace so stakeholders can view it online. Remember to set up a **scheduled refresh** that points to the same MySQL ODBC connection (refresh frequency recommended: daily).

---

## Quick Reference – Files Overview
| File | Purpose |
|------|---------|
| `model.md` | Star‑schema description with mermaid diagram (reference). |
| `power_query.m` | M script to pull MySQL tables; copy‑paste into Power BI’s Advanced Editor. |
| `dax_measures.txt` | All DAX formulas needed for the seven dashboard pages. |
| `Smart_Delivery_Analytics.pbix` | Empty Power BI file – open it and follow the steps above. |

---

### You’re Done!
Once the above steps are completed, you will have a fully functional Power BI solution that mirrors the Excel KPI cards and the MySQL analytical layer, satisfying the project’s **Phase 8** requirement.

Feel free to ask if you need any clarification on a specific step, or if you would like the PBIX file pre‑populated with the model (that would require the Power BI Desktop automation tool, which is outside the sandbox).