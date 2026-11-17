import csv
import os

data_dir = r"c:\sql_main\smart-delivery-analytics\original_data"
output_file = r"c:\sql_main\smart-delivery-analytics\02_data_ingestion\load_staging_data.sql"

def escape_sql(val):
    if val is None or val == "":
        return "NULL"
    val = val.replace("\\", "\\\\").replace("'", "''")
    return f"'{val}'"

with open(output_file, "w", encoding="utf-8") as out:
    out.write("-- ==============================================================================\n")
    out.write("-- SMART DELIVERY OPERATIONS ANALYTICS SYSTEM\n")
    out.write("-- Self-Contained Staging Data Multi-Row SQL Insert Dump (29,300 Records)\n")
    out.write("-- Allows Direct Loading into MySQL Workbench without LOAD DATA INFILE Privileges\n")
    out.write("-- ==============================================================================\n\n")
    out.write("USE smart_delivery_analytics;\n\n")
    out.write("SET FOREIGN_KEY_CHECKS = 0;\n")
    out.write("SET SQL_MODE = 'NO_AUTO_VALUE_ON_ZERO';\n\n")

    # Table mappings
    tables = [
        ("customers.csv", "stg_customers", ["customer_id", "customer_name", "age", "gender", "city", "signup_date"]),
        ("customer_behavior.csv", "stg_customer_behavior", ["customer_id", "total_orders", "total_spending", "avg_order_value", "last_order_days", "churn_flag"]),
        ("delivery_partners.csv", "stg_delivery_partners", ["partner_id", "partner_name", "vehicle_type", "joining_date"]),
        ("restaurants.csv", "stg_restaurants", ["restaurant_id", "restaurant_name", "cuisine_type", "city", "rating"]),
        ("orders.csv", "stg_orders", ["order_id", "customer_id", "restaurant_id", "partner_id", "order_time", "delivered_time", "order_amount", "delivery_fee", "status"]),
        ("payments.csv", "stg_payments", ["payment_id", "order_id", "payment_mode", "amount"]),
        ("ratings.csv", "stg_ratings", ["rating_id", "order_id", "customer_rating", "feedback"])
    ]

    for fname, tbl_name, cols in tables:
        fpath = os.path.join(data_dir, fname)
        with open(fpath, "r", encoding="utf-8") as f:
            reader = csv.reader(f)
            header = next(reader)
            rows = list(reader)

        out.write(f"-- ------------------------------------------------------------------------------\n")
        out.write(f"-- Data for {tbl_name} ({len(rows)} records from {fname})\n")
        out.write(f"-- ------------------------------------------------------------------------------\n")
        out.write(f"TRUNCATE TABLE {tbl_name};\n")

        cols_str = ", ".join(cols)
        batch_size = 500
        for i in range(0, len(rows), batch_size):
            batch = rows[i:i + batch_size]
            out.write(f"INSERT INTO {tbl_name} ({cols_str}) VALUES\n")
            row_lines = []
            for r in batch:
                vals = [escape_sql(val) for val in r]
                row_lines.append(f"    ({', '.join(vals)})")
            out.write(",\n".join(row_lines))
            out.write(";\n")
        out.write("\n")

    out.write("SET FOREIGN_KEY_CHECKS = 1;\n")

print("Generated load_staging_data.sql! File size:", os.path.getsize(output_file))
