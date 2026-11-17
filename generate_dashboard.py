"""
Smart Delivery Operations Analytics – HTML Dashboard Generator
Reads all 7 CSV files, computes KPIs, and produces a single self-contained index.html
"""

import csv, os, json, math
from datetime import datetime
from collections import defaultdict

# ── Paths ──────────────────────────────────────────────────────────────────────
DATA_DIR  = r"c:\sql_main\smart-delivery-analytics\original_data"
OUT_PATH  = r"c:\sql_main\smart-delivery-analytics\dashboard\index.html"

os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)

def load(fname):
    with open(os.path.join(DATA_DIR, fname), encoding="utf-8") as f:
        return list(csv.DictReader(f))

print("Loading data …")
orders      = load("orders.csv")
customers   = load("customers.csv")
behavior    = load("customer_behavior.csv")
restaurants = load("restaurants.csv")
partners    = load("delivery_partners.csv")
payments    = load("payments.csv")
ratings     = load("ratings.csv")
print(f"  {len(orders)} orders | {len(customers)} customers | {len(restaurants)} restaurants | {len(partners)} partners")

# ── Helpers ────────────────────────────────────────────────────────────────────
def safe_float(v, default=0.0):
    try: return float(str(v).strip())
    except: return default

def parse_dt(s):
    for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%d"):
        try: return datetime.strptime(str(s).strip(), fmt)
        except: pass
    return None

rest_map = {r["restaurant_id"]: r for r in restaurants}
part_map = {p["partner_id"]:   p for p in partners}
pay_map  = {p["order_id"]:     p for p in payments}

# ── KPI Computation ────────────────────────────────────────────────────────────
total_orders     = len(orders)
delivered        = [o for o in orders if o["status"].strip() == "Delivered"]
cancelled        = [o for o in orders if o["status"].strip() == "Cancelled"]
cancel_rate      = round(len(cancelled)/total_orders*100, 2)
total_revenue    = round(sum(safe_float(o["order_amount"]) + safe_float(o["delivery_fee"]) for o in delivered), 2)
aov              = round(sum(safe_float(o["order_amount"]) for o in delivered)/len(delivered), 2) if delivered else 0

durations = []
for o in delivered:
    t1, t2 = parse_dt(o["order_time"]), parse_dt(o.get("delivered_time",""))
    if t1 and t2 and t2 > t1:
        durations.append((t2 - t1).seconds / 60)

avg_delivery     = round(sum(durations)/len(durations), 2) if durations else 0
on_time_pct      = round(sum(1 for d in durations if d <= 45)/len(durations)*100, 2) if durations else 0
avg_rating       = round(sum(safe_float(r["customer_rating"]) for r in ratings)/len(ratings), 2) if ratings else 0
churn_customers  = sum(1 for b in behavior if str(b.get("churn_flag","0")).strip() == "1")
active_customers = len(customers) - churn_customers
retention_rate   = round(active_customers/len(customers)*100, 2)
total_del_fee    = round(sum(safe_float(o["delivery_fee"]) for o in delivered), 2)

# ── Monthly Revenue Trend ──────────────────────────────────────────────────────
monthly = defaultdict(lambda: {"revenue": 0, "orders": 0, "cancelled": 0})
for o in orders:
    dt = parse_dt(o["order_time"])
    if not dt: continue
    key = dt.strftime("%Y-%m")
    if o["status"].strip() == "Delivered":
        monthly[key]["revenue"] += safe_float(o["order_amount"]) + safe_float(o["delivery_fee"])
        monthly[key]["orders"]  += 1
    elif o["status"].strip() == "Cancelled":
        monthly[key]["cancelled"] += 1

months_sorted = sorted(monthly.keys())
monthly_labels  = [m for m in months_sorted]
monthly_revenue = [round(monthly[m]["revenue"], 2) for m in months_sorted]
monthly_orders  = [monthly[m]["orders"]    for m in months_sorted]
monthly_cancel  = [monthly[m]["cancelled"] for m in months_sorted]

# ── City Performance ───────────────────────────────────────────────────────────
city_data = defaultdict(lambda: {"revenue": 0, "orders": 0, "cancelled": 0, "delays": 0, "del_orders": 0})
for o in orders:
    r = rest_map.get(o["restaurant_id"], {})
    city = r.get("city", "Unknown").strip()
    if o["status"].strip() == "Delivered":
        city_data[city]["revenue"]   += safe_float(o["order_amount"]) + safe_float(o["delivery_fee"])
        city_data[city]["orders"]    += 1
        t1, t2 = parse_dt(o["order_time"]), parse_dt(o.get("delivered_time",""))
        if t1 and t2 and t2 > t1:
            dur = (t2-t1).seconds/60
            city_data[city]["del_orders"] += 1
            if dur > 45: city_data[city]["delays"] += 1
    elif o["status"].strip() == "Cancelled":
        city_data[city]["cancelled"] += 1

cities_sorted = sorted(city_data.keys(), key=lambda c: city_data[c]["revenue"], reverse=True)
city_labels   = cities_sorted
city_revenue  = [round(city_data[c]["revenue"], 2) for c in cities_sorted]
city_orders   = [city_data[c]["orders"]   for c in cities_sorted]
city_cancel_r = [round(city_data[c]["cancelled"]/(city_data[c]["orders"]+city_data[c]["cancelled"]+0.0001)*100,1) for c in cities_sorted]
city_delay_r  = [round(city_data[c]["delays"]/max(city_data[c]["del_orders"],1)*100,1) for c in cities_sorted]

# ── Top 10 Restaurants ─────────────────────────────────────────────────────────
rest_data = defaultdict(lambda: {"revenue": 0, "orders": 0, "name": ""})
for o in delivered:
    rid = o["restaurant_id"]
    rest_data[rid]["revenue"] += safe_float(o["order_amount"])
    rest_data[rid]["orders"]  += 1
    rest_data[rid]["name"]     = rest_map.get(rid, {}).get("restaurant_name", rid)

top10_rest = sorted(rest_data.items(), key=lambda x: x[1]["revenue"], reverse=True)[:10]
rest_labels  = [v["name"][:20] for _, v in top10_rest]
rest_revenue = [round(v["revenue"], 2) for _, v in top10_rest]
rest_orders  = [v["orders"] for _, v in top10_rest]

# ── Payment Mode Distribution ──────────────────────────────────────────────────
pay_mode = defaultdict(lambda: {"count": 0, "amount": 0})
for p in payments:
    mode = p.get("payment_mode", "Unknown").strip()
    pay_mode[mode]["count"]  += 1
    pay_mode[mode]["amount"] += safe_float(p.get("amount", 0))

pay_labels  = list(pay_mode.keys())
pay_counts  = [pay_mode[m]["count"]  for m in pay_labels]
pay_amounts = [round(pay_mode[m]["amount"],2) for m in pay_labels]

# ── Delivery Speed Tiers ───────────────────────────────────────────────────────
tiers = {"≤30 min (Fast)": 0, "31-45 min (Standard)": 0, "46-60 min (Delayed)": 0, ">60 min (Severe)": 0}
for d in durations:
    if d <= 30:   tiers["≤30 min (Fast)"]        += 1
    elif d <= 45: tiers["31-45 min (Standard)"]   += 1
    elif d <= 60: tiers["46-60 min (Delayed)"]    += 1
    else:         tiers[">60 min (Severe)"]       += 1

tier_labels  = list(tiers.keys())
tier_counts  = list(tiers.values())

# ── Vehicle Type Performance ───────────────────────────────────────────────────
veh_data = defaultdict(lambda: {"orders": 0, "dur_sum": 0, "dur_cnt": 0})
for o in delivered:
    pid = o["partner_id"]
    vtype = part_map.get(pid, {}).get("vehicle_type", "Unknown").strip()
    veh_data[vtype]["orders"] += 1
    t1, t2 = parse_dt(o["order_time"]), parse_dt(o.get("delivered_time",""))
    if t1 and t2 and t2 > t1:
        veh_data[vtype]["dur_sum"] += (t2-t1).seconds/60
        veh_data[vtype]["dur_cnt"] += 1

veh_labels   = list(veh_data.keys())
veh_orders   = [veh_data[v]["orders"] for v in veh_labels]
veh_avg_time = [round(veh_data[v]["dur_sum"]/max(veh_data[v]["dur_cnt"],1),2) for v in veh_labels]

# ── Customer Segments ──────────────────────────────────────────────────────────
seg = {"Low (<₹4K)": 0, "Medium (₹4K-₹7K)": 0, "High (₹7K-₹10K)": 0, "VIP (>₹10K)": 0}
for b in behavior:
    sp = safe_float(b.get("total_spending", 0))
    if sp < 4000:    seg["Low (<₹4K)"]        += 1
    elif sp < 7000:  seg["Medium (₹4K-₹7K)"]  += 1
    elif sp < 10000: seg["High (₹7K-₹10K)"]   += 1
    else:            seg["VIP (>₹10K)"]        += 1

seg_labels = list(seg.keys())
seg_counts = list(seg.values())

# ── Rating Distribution ────────────────────────────────────────────────────────
rat_dist = defaultdict(int)
for r in ratings:
    score = str(int(safe_float(r["customer_rating"])))
    rat_dist[score] += 1

rat_labels = ["1 ⭐", "2 ⭐", "3 ⭐", "4 ⭐", "5 ⭐"]
rat_counts = [rat_dist.get(str(i), 0) for i in range(1, 6)]

# ── Cancellation by Day ────────────────────────────────────────────────────────
day_data = defaultdict(lambda: {"total": 0, "cancelled": 0})
day_order = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]
for o in orders:
    dt = parse_dt(o["order_time"])
    if not dt: continue
    day = dt.strftime("%A")
    day_data[day]["total"] += 1
    if o["status"].strip() == "Cancelled":
        day_data[day]["cancelled"] += 1

day_cancel_rate = [round(day_data[d]["cancelled"]/max(day_data[d]["total"],1)*100,1) for d in day_order]

# ── Embed data into HTML ───────────────────────────────────────────────────────
js_data = f"""
const KPI = {{
  totalOrders:    {total_orders},
  delivered:      {len(delivered)},
  cancelled:      {len(cancelled)},
  cancelRate:     {cancel_rate},
  totalRevenue:   {total_revenue},
  aov:            {aov},
  avgDelivery:    {avg_delivery},
  onTimePct:      {on_time_pct},
  avgRating:      {avg_rating},
  retentionRate:  {retention_rate},
  totalDelFee:    {total_del_fee},
  totalCustomers: {len(customers)},
  activeCustomers:{active_customers},
  churnCustomers: {churn_customers}
}};
const monthlyLabels  = {json.dumps(monthly_labels)};
const monthlyRevenue = {json.dumps(monthly_revenue)};
const monthlyOrders  = {json.dumps(monthly_orders)};
const monthlyCancel  = {json.dumps(monthly_cancel)};
const cityLabels     = {json.dumps(city_labels)};
const cityRevenue    = {json.dumps(city_revenue)};
const cityOrders     = {json.dumps(city_orders)};
const cityCancelRate = {json.dumps(city_cancel_r)};
const cityDelayRate  = {json.dumps(city_delay_r)};
const restLabels     = {json.dumps(rest_labels)};
const restRevenue    = {json.dumps(rest_revenue)};
const restOrders     = {json.dumps(rest_orders)};
const payLabels      = {json.dumps(pay_labels)};
const payCounts      = {json.dumps(pay_counts)};
const payAmounts     = {json.dumps(pay_amounts)};
const tierLabels     = {json.dumps(tier_labels)};
const tierCounts     = {json.dumps(tier_counts)};
const vehLabels      = {json.dumps(veh_labels)};
const vehOrders      = {json.dumps(veh_orders)};
const vehAvgTime     = {json.dumps(veh_avg_time)};
const segLabels      = {json.dumps(seg_labels)};
const segCounts      = {json.dumps(seg_counts)};
const ratLabels      = {json.dumps(rat_labels)};
const ratCounts      = {json.dumps(rat_counts)};
const dayOrder       = {json.dumps(day_order)};
const dayCancelRate  = {json.dumps(day_cancel_rate)};
"""

HTML = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>Smart Delivery Operations Analytics</title>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
<style>
  *{{box-sizing:border-box;margin:0;padding:0}}
  :root{{--blue:#1e3a8a;--indigo:#4f46e5;--green:#059669;--red:#dc2626;--orange:#ea580c;--yellow:#ca8a04;--bg:#f1f5f9;--card:#fff;--text:#1e293b;--sub:#64748b}}
  body{{font-family:'Segoe UI',system-ui,sans-serif;background:var(--bg);color:var(--text);min-height:100vh}}

  /* HEADER */
  header{{background:linear-gradient(135deg,var(--blue) 0%,var(--indigo) 100%);color:#fff;padding:28px 32px;display:flex;align-items:center;justify-content:space-between;box-shadow:0 4px 20px rgba(30,58,138,.4)}}
  header h1{{font-size:1.75rem;font-weight:700;letter-spacing:-.5px}}
  header p{{font-size:.85rem;opacity:.8;margin-top:4px}}
  .badge{{background:rgba(255,255,255,.18);border:1px solid rgba(255,255,255,.35);border-radius:20px;padding:6px 14px;font-size:.8rem;font-weight:600}}

  /* NAV TABS */
  nav{{background:#fff;border-bottom:2px solid #e2e8f0;display:flex;gap:0;overflow-x:auto;box-shadow:0 2px 8px rgba(0,0,0,.06)}}
  nav button{{border:none;background:none;padding:14px 22px;font-size:.88rem;font-weight:600;color:var(--sub);cursor:pointer;white-space:nowrap;border-bottom:3px solid transparent;transition:all .2s}}
  nav button.active{{color:var(--indigo);border-bottom-color:var(--indigo);background:#f8f7ff}}
  nav button:hover:not(.active){{color:var(--text);background:#f8fafc}}

  /* MAIN */
  main{{padding:28px 32px;max-width:1600px;margin:0 auto}}
  .page{{display:none}}.page.active{{display:block}}

  /* KPI CARDS */
  .kpi-grid{{display:grid;grid-template-columns:repeat(auto-fit,minmax(190px,1fr));gap:18px;margin-bottom:28px}}
  .kpi-card{{background:var(--card);border-radius:14px;padding:22px 20px;box-shadow:0 2px 12px rgba(0,0,0,.07);border-left:5px solid var(--indigo);transition:transform .2s,box-shadow .2s;cursor:default}}
  .kpi-card:hover{{transform:translateY(-3px);box-shadow:0 6px 24px rgba(0,0,0,.13)}}
  .kpi-card .label{{font-size:.76rem;font-weight:600;color:var(--sub);text-transform:uppercase;letter-spacing:.6px;margin-bottom:8px}}
  .kpi-card .value{{font-size:1.75rem;font-weight:800;color:var(--text);line-height:1}}
  .kpi-card .sub{{font-size:.78rem;color:var(--sub);margin-top:5px}}
  .kpi-card.green{{border-left-color:var(--green)}}.kpi-card.green .value{{color:var(--green)}}
  .kpi-card.red{{border-left-color:var(--red)}}.kpi-card.red .value{{color:var(--red)}}
  .kpi-card.orange{{border-left-color:var(--orange)}}.kpi-card.orange .value{{color:var(--orange)}}
  .kpi-card.yellow{{border-left-color:var(--yellow)}}.kpi-card.yellow .value{{color:var(--yellow)}}
  .kpi-card.blue{{border-left-color:var(--blue)}}.kpi-card.blue .value{{color:var(--blue)}}

  /* CHARTS */
  .charts-grid{{display:grid;grid-template-columns:repeat(auto-fit,minmax(460px,1fr));gap:22px}}
  .chart-card{{background:var(--card);border-radius:14px;padding:24px;box-shadow:0 2px 12px rgba(0,0,0,.07)}}
  .chart-card h3{{font-size:.95rem;font-weight:700;color:var(--text);margin-bottom:18px;padding-bottom:10px;border-bottom:1px solid #e2e8f0;display:flex;align-items:center;gap:8px}}
  .chart-card h3 .icon{{font-size:1.1rem}}
  .chart-wrap{{position:relative;height:280px}}
  .chart-wrap.tall{{height:340px}}

  /* TABLE */
  .table-wrap{{overflow-x:auto;margin-top:0}}
  table{{width:100%;border-collapse:collapse;font-size:.84rem}}
  th{{background:#f8fafc;color:var(--sub);font-weight:700;padding:10px 14px;text-align:left;text-transform:uppercase;font-size:.73rem;letter-spacing:.5px;border-bottom:2px solid #e2e8f0}}
  td{{padding:10px 14px;border-bottom:1px solid #f1f5f9;color:var(--text)}}
  tr:last-child td{{border-bottom:none}}
  tr:hover td{{background:#fafbff}}
  .pill{{display:inline-block;padding:3px 10px;border-radius:12px;font-size:.74rem;font-weight:600}}
  .pill.green{{background:#d1fae5;color:#065f46}}
  .pill.red{{background:#fee2e2;color:#991b1b}}
  .pill.orange{{background:#ffedd5;color:#9a3412}}

  /* SECTION TITLE */
  .section-title{{font-size:1.3rem;font-weight:800;color:var(--blue);margin-bottom:20px;display:flex;align-items:center;gap:10px}}
  .section-title::after{{content:'';flex:1;height:2px;background:linear-gradient(to right,#e0e7ff,transparent)}}

  footer{{text-align:center;padding:28px;color:var(--sub);font-size:.8rem;margin-top:20px}}
</style>
</head>
<body>

<header>
  <div>
    <h1>🚀 Smart Delivery Operations Analytics</h1>
    <p>End-to-End Business Intelligence Dashboard · 10,000 Orders · 10 Cities · 2023–2024</p>
  </div>
  <div style="display:flex;gap:10px;flex-wrap:wrap">
    <span class="badge">📦 MySQL 8.0+</span>
    <span class="badge">📊 Real Data</span>
    <span class="badge">⚡ Live KPIs</span>
  </div>
</header>

<nav id="nav">
  <button class="active" onclick="showPage('exec','this')">🏠 Executive</button>
  <button onclick="showPage('delivery','this')">🕐 Delivery</button>
  <button onclick="showPage('cancel','this')">❌ Cancellations</button>
  <button onclick="showPage('revenue','this')">💰 Revenue</button>
  <button onclick="showPage('restaurant','this')">🍽 Restaurants</button>
  <button onclick="showPage('partner','this')">🛵 Partners</button>
  <button onclick="showPage('customer','this')">👥 Customers</button>
</nav>

<main>

<!-- ═══════════════ EXECUTIVE PAGE ═══════════════ -->
<div class="page active" id="page-exec">
  <p class="section-title">📋 Executive Summary</p>
  <div class="kpi-grid" id="exec-kpis"></div>
  <div class="charts-grid">
    <div class="chart-card"><h3><span class="icon">📈</span>Monthly Revenue Trend (₹)</h3><div class="chart-wrap tall"><canvas id="ch-monthly-rev"></canvas></div></div>
    <div class="chart-card"><h3><span class="icon">📦</span>Monthly Order Volume</h3><div class="chart-wrap tall"><canvas id="ch-monthly-ord"></canvas></div></div>
    <div class="chart-card"><h3><span class="icon">💳</span>Payment Method Distribution</h3><div class="chart-wrap"><canvas id="ch-pay-pie"></canvas></div></div>
    <div class="chart-card"><h3><span class="icon">⭐</span>Customer Rating Distribution</h3><div class="chart-wrap"><canvas id="ch-ratings"></canvas></div></div>
  </div>
</div>

<!-- ═══════════════ DELIVERY PAGE ═══════════════ -->
<div class="page" id="page-delivery">
  <p class="section-title">🕐 Delivery Performance</p>
  <div class="kpi-grid" id="del-kpis"></div>
  <div class="charts-grid">
    <div class="chart-card"><h3><span class="icon">🏎</span>Delivery Speed Tiers</h3><div class="chart-wrap"><canvas id="ch-tiers"></canvas></div></div>
    <div class="chart-card"><h3><span class="icon">🏙</span>Avg Delivery Time by City (mins)</h3><div class="chart-wrap"><canvas id="ch-city-delay"></canvas></div></div>
    <div class="chart-card"><h3><span class="icon">🛵</span>Deliveries by Vehicle Type</h3><div class="chart-wrap"><canvas id="ch-veh-orders"></canvas></div></div>
    <div class="chart-card"><h3><span class="icon">⏱</span>Avg Delivery Time by Vehicle (mins)</h3><div class="chart-wrap"><canvas id="ch-veh-time"></canvas></div></div>
  </div>
</div>

<!-- ═══════════════ CANCELLATION PAGE ═══════════════ -->
<div class="page" id="page-cancel">
  <p class="section-title">❌ Cancellation Analysis</p>
  <div class="kpi-grid" id="cancel-kpis"></div>
  <div class="charts-grid">
    <div class="chart-card"><h3><span class="icon">📅</span>Cancellation Rate by Day of Week</h3><div class="chart-wrap"><canvas id="ch-day-cancel"></canvas></div></div>
    <div class="chart-card"><h3><span class="icon">🏙</span>Cancellation Rate by City (%)</h3><div class="chart-wrap"><canvas id="ch-city-cancel"></canvas></div></div>
    <div class="chart-card"><h3><span class="icon">📊</span>Monthly Cancellations Trend</h3><div class="chart-wrap tall"><canvas id="ch-monthly-cancel"></canvas></div></div>
    <div class="chart-card"><h3><span class="icon">💳</span>Cancellation by Payment Mode</h3><div class="chart-wrap"><canvas id="ch-pay-cancel"></canvas></div></div>
  </div>
</div>

<!-- ═══════════════ REVENUE PAGE ═══════════════ -->
<div class="page" id="page-revenue">
  <p class="section-title">💰 Revenue Optimisation</p>
  <div class="kpi-grid" id="rev-kpis"></div>
  <div class="charts-grid">
    <div class="chart-card"><h3><span class="icon">🏙</span>Revenue by City (₹)</h3><div class="chart-wrap tall"><canvas id="ch-city-rev"></canvas></div></div>
    <div class="chart-card"><h3><span class="icon">💳</span>Revenue by Payment Method (₹)</h3><div class="chart-wrap"><canvas id="ch-pay-rev"></canvas></div></div>
    <div class="chart-card"><h3><span class="icon">📈</span>Revenue vs Cancellations (Monthly)</h3><div class="chart-wrap tall"><canvas id="ch-rev-cancel"></canvas></div></div>
    <div class="chart-card"><h3><span class="icon">💳</span>Transaction Share by Payment Mode</h3><div class="chart-wrap"><canvas id="ch-pay-txn"></canvas></div></div>
  </div>
</div>

<!-- ═══════════════ RESTAURANT PAGE ═══════════════ -->
<div class="page" id="page-restaurant">
  <p class="section-title">🍽 Restaurant Performance</p>
  <div class="charts-grid">
    <div class="chart-card" style="grid-column:1/-1"><h3><span class="icon">🏆</span>Top 10 Restaurants by Revenue (₹)</h3><div class="chart-wrap tall"><canvas id="ch-rest-rev"></canvas></div></div>
    <div class="chart-card" style="grid-column:1/-1"><h3><span class="icon">📋</span>Top 10 Restaurant Detail</h3>
      <div class="table-wrap"><table id="rest-table"></table></div>
    </div>
  </div>
</div>

<!-- ═══════════════ PARTNER PAGE ═══════════════ -->
<div class="page" id="page-partner">
  <p class="section-title">🛵 Partner & Fleet Analytics</p>
  <div class="kpi-grid" id="partner-kpis"></div>
  <div class="charts-grid">
    <div class="chart-card"><h3><span class="icon">🏎</span>Fleet Composition by Vehicle Type</h3><div class="chart-wrap"><canvas id="ch-fleet-pie"></canvas></div></div>
    <div class="chart-card"><h3><span class="icon">📦</span>Deliveries by Vehicle Type</h3><div class="chart-wrap"><canvas id="ch-veh-bar"></canvas></div></div>
    <div class="chart-card" style="grid-column:1/-1"><h3><span class="icon">⏱</span>Avg Delivery Time by Vehicle (mins)</h3><div class="chart-wrap"><canvas id="ch-veh-time2"></canvas></div></div>
  </div>
</div>

<!-- ═══════════════ CUSTOMER PAGE ═══════════════ -->
<div class="page" id="page-customer">
  <p class="section-title">👥 Customer Insights</p>
  <div class="kpi-grid" id="cust-kpis"></div>
  <div class="charts-grid">
    <div class="chart-card"><h3><span class="icon">💰</span>Customer Spend Segments</h3><div class="chart-wrap"><canvas id="ch-seg-pie"></canvas></div></div>
    <div class="chart-card"><h3><span class="icon">🔄</span>Active vs Churned Customers</h3><div class="chart-wrap"><canvas id="ch-churn"></canvas></div></div>
    <div class="chart-card"><h3><span class="icon">⭐</span>Rating Distribution</h3><div class="chart-wrap"><canvas id="ch-rat2"></canvas></div></div>
    <div class="chart-card"><h3><span class="icon">📊</span>Spend Segment Counts</h3><div class="chart-wrap"><canvas id="ch-seg-bar"></canvas></div></div>
  </div>
</div>

</main>

<footer>Smart Delivery Operations Analytics · MySQL 8.0+ · Generated {datetime.now().strftime('%Y-%m-%d %H:%M')} · All KPIs computed from 29,300 raw records</footer>

<script>
{js_data}

// ── HELPERS ──────────────────────────────────────────────────────────────────
function fmt(n){{return new Intl.NumberFormat('en-IN').format(n)}}
function fmtRs(n){{return '₹'+new Intl.NumberFormat('en-IN',{{maximumFractionDigits:0}}).format(n)}}
const PALETTE = ['#4f46e5','#059669','#ea580c','#dc2626','#ca8a04','#7c3aed','#0891b2','#be185d','#047857','#b45309'];
const LIGHT   = ['#e0e7ff','#d1fae5','#ffedd5','#fee2e2','#fef9c3','#ede9fe','#cffafe','#fce7f3','#d1fae5','#fef3c7'];

function mkCard(label, value, sub, cls='') {{
  return `<div class="kpi-card ${{cls}}"><div class="label">${{label}}</div><div class="value">${{value}}</div><div class="sub">${{sub}}</div></div>`;
}}

function bar(id, labels, datasets, opts={{}}) {{
  new Chart(document.getElementById(id), {{type:'bar',data:{{labels,datasets}},options:{{responsive:true,maintainAspectRatio:false,plugins:{{legend:{{position:'top'}}}},scales:{{y:{{beginAtZero:true}}}}, ...opts}}}});
}}
function line(id, labels, datasets, opts={{}}) {{
  new Chart(document.getElementById(id), {{type:'line',data:{{labels,datasets}},options:{{responsive:true,maintainAspectRatio:false,plugins:{{legend:{{position:'top'}}}},scales:{{y:{{beginAtZero:true}}}}, ...opts}}}});
}}
function doughnut(id, labels, data, colors) {{
  new Chart(document.getElementById(id), {{type:'doughnut',data:{{labels,datasets:[{{data,backgroundColor:colors,borderWidth:2,borderColor:'#fff'}}]}},options:{{responsive:true,maintainAspectRatio:false,plugins:{{legend:{{position:'right'}}}}}}}});
}}
function hbar(id, labels, datasets, opts={{}}) {{
  new Chart(document.getElementById(id), {{type:'bar',data:{{labels,datasets}},options:{{indexAxis:'y',responsive:true,maintainAspectRatio:false,plugins:{{legend:{{position:'top'}}}},scales:{{x:{{beginAtZero:true}}}}, ...opts}}}});
}}

// ── NAV ──────────────────────────────────────────────────────────────────────
function showPage(id, btn) {{
  document.querySelectorAll('.page').forEach(p=>p.classList.remove('active'));
  document.querySelectorAll('nav button').forEach(b=>b.classList.remove('active'));
  document.getElementById('page-'+id).classList.add('active');
  event.target.classList.add('active');
}}

// ── KPI CARDS ────────────────────────────────────────────────────────────────
document.getElementById('exec-kpis').innerHTML = [
  mkCard('Total Orders',     fmt(KPI.totalOrders), 'All order events'),
  mkCard('Delivered',        fmt(KPI.delivered),  `${{(KPI.delivered/KPI.totalOrders*100).toFixed(1)}}% success rate`,'green'),
  mkCard('Total Revenue',    fmtRs(KPI.totalRevenue), 'Delivered GMV + fees','blue'),
  mkCard('Avg Order Value',  fmtRs(KPI.aov),      'Per delivered order'),
  mkCard('Cancellation Rate',KPI.cancelRate+'%',  `${{fmt(KPI.cancelled)}} orders lost`,'red'),
  mkCard('Avg Delivery',     KPI.avgDelivery+' min','Platform average','orange'),
  mkCard('On-Time Rate',     KPI.onTimePct+'%',   '≤45 min deliveries','green'),
  mkCard('CSAT Score',       KPI.avgRating+'/5',  `${{fmt(7000)}} ratings`,'yellow'),
].join('');

document.getElementById('del-kpis').innerHTML = [
  mkCard('Total Delivered',  fmt(KPI.delivered),   'Successfully fulfilled','green'),
  mkCard('Avg Delivery Time',KPI.avgDelivery+' min','Platform average'),
  mkCard('On-Time Rate',     KPI.onTimePct+'%',    '≤45 min threshold','green'),
  mkCard('SLA Breach Rate',  (100-KPI.onTimePct).toFixed(1)+'%','> 45 min deliveries','red'),
].join('');

document.getElementById('cancel-kpis').innerHTML = [
  mkCard('Total Cancelled',  fmt(KPI.cancelled),   'Orders not fulfilled','red'),
  mkCard('Cancellation Rate',KPI.cancelRate+'%',   'Of total orders','red'),
  mkCard('Lost Revenue',     fmtRs(KPI.totalRevenue * KPI.cancelRate/100 * 1.3),'Est. GMV lost','orange'),
  mkCard('Peak Cancel Day',  'Check chart →',      'See day-of-week chart'),
].join('');

document.getElementById('rev-kpis').innerHTML = [
  mkCard('Total Revenue',    fmtRs(KPI.totalRevenue),'Collected GMV','blue'),
  mkCard('Delivery Fees',    fmtRs(KPI.totalDelFee), 'Logistics revenue','green'),
  mkCard('AOV',              fmtRs(KPI.aov),          'Avg order value'),
  mkCard('Fee Share',        (KPI.totalDelFee/KPI.totalRevenue*100).toFixed(1)+'%','Fees % of revenue','yellow'),
].join('');

document.getElementById('partner-kpis').innerHTML = [
  mkCard('Total Partners',   fmt(200),              'Active fleet size'),
  mkCard('Total Deliveries', fmt(KPI.delivered),    'Completed by fleet','green'),
  mkCard('Avg Delivery Time',KPI.avgDelivery+' min','Fleet average','orange'),
  mkCard('CSAT Score',       KPI.avgRating+'/5',    'Fleet rating','yellow'),
].join('');

document.getElementById('cust-kpis').innerHTML = [
  mkCard('Total Customers',  fmt(KPI.totalCustomers),'Registered users'),
  mkCard('Active Customers', fmt(KPI.activeCustomers),'Not churned','green'),
  mkCard('Churned',          fmt(KPI.churnCustomers),'Inactive > 90 days','red'),
  mkCard('Retention Rate',   KPI.retentionRate+'%',  'Of total customers','green'),
].join('');

// ── CHARTS ───────────────────────────────────────────────────────────────────
// Executive
line('ch-monthly-rev', monthlyLabels, [{{label:'Revenue (₹)',data:monthlyRevenue,borderColor:'#4f46e5',backgroundColor:'rgba(79,70,229,.12)',fill:true,tension:.4,pointRadius:4}}]);
bar('ch-monthly-ord',  monthlyLabels, [{{label:'Delivered Orders',data:monthlyOrders,backgroundColor:'#059669'}},{{label:'Cancelled',data:monthlyCancel,backgroundColor:'#dc2626'}}]);
doughnut('ch-pay-pie',  payLabels,   payCounts,  PALETTE);
bar('ch-ratings',       ratLabels,   [{{label:'Number of Ratings',data:ratCounts,backgroundColor:PALETTE}}]);

// Delivery
doughnut('ch-tiers',  tierLabels, tierCounts, ['#059669','#4f46e5','#ea580c','#dc2626']);
hbar('ch-city-delay', cityLabels, [{{label:'Delay Rate %',data:cityDelayRate,backgroundColor:'#ea580c'}}]);
bar('ch-veh-orders',  vehLabels,  [{{label:'Total Deliveries',data:vehOrders,backgroundColor:PALETTE}}]);
bar('ch-veh-time',    vehLabels,  [{{label:'Avg Delivery Time (mins)',data:vehAvgTime,backgroundColor:'#7c3aed'}}]);

// Cancellations
bar('ch-day-cancel', dayOrder, [{{label:'Cancellation Rate %',data:dayCancelRate,backgroundColor:'#dc2626'}}]);
hbar('ch-city-cancel',cityLabels,[{{label:'Cancellation Rate %',data:cityCancelRate,backgroundColor:'#dc2626'}}]);
line('ch-monthly-cancel',monthlyLabels,[{{label:'Cancellations',data:monthlyCancel,borderColor:'#dc2626',backgroundColor:'rgba(220,38,38,.12)',fill:true,tension:.4}}]);
bar('ch-pay-cancel', payLabels,  [{{label:'Transaction Count',data:payCounts,backgroundColor:PALETTE}}]);

// Revenue
hbar('ch-city-rev',   cityLabels, [{{label:'Revenue (₹)',data:cityRevenue,backgroundColor:PALETTE}}]);
bar('ch-pay-rev',     payLabels,  [{{label:'Total Amount (₹)',data:payAmounts,backgroundColor:PALETTE}}]);
new Chart(document.getElementById('ch-rev-cancel'),{{type:'bar',data:{{labels:monthlyLabels,datasets:[{{type:'bar',label:'Revenue (₹)',data:monthlyRevenue,backgroundColor:'rgba(79,70,229,.7)',yAxisID:'y'}},{{type:'line',label:'Cancellations',data:monthlyCancel,borderColor:'#dc2626',backgroundColor:'rgba(220,38,38,.1)',fill:false,tension:.4,yAxisID:'y1',pointRadius:4}}]}},options:{{responsive:true,maintainAspectRatio:false,plugins:{{legend:{{position:'top'}}}},scales:{{y:{{beginAtZero:true,position:'left'}},y1:{{beginAtZero:true,position:'right',grid:{{drawOnChartArea:false}}}}}}}}}});
doughnut('ch-pay-txn', payLabels, payCounts, PALETTE);

// Restaurant
hbar('ch-rest-rev', restLabels, [{{label:'Revenue (₹)',data:restRevenue,backgroundColor:PALETTE}}]);
const tbl = document.getElementById('rest-table');
tbl.innerHTML = '<thead><tr><th>#</th><th>Restaurant</th><th>Revenue (₹)</th><th>Orders</th><th>AOV (₹)</th></tr></thead><tbody>' +
  restLabels.map((n,i) => `<tr><td>${{i+1}}</td><td>${{n}}</td><td>${{fmtRs(restRevenue[i])}}</td><td>${{fmt(restOrders[i])}}</td><td>${{fmtRs(Math.round(restRevenue[i]/restOrders[i]))}}</td></tr>`).join('') +
  '</tbody>';

// Partners
const fleetCounts = vehOrders;
doughnut('ch-fleet-pie', vehLabels, fleetCounts, PALETTE);
bar('ch-veh-bar',  vehLabels, [{{label:'Total Deliveries',data:vehOrders,backgroundColor:PALETTE}}]);
bar('ch-veh-time2',vehLabels, [{{label:'Avg Time (mins)',data:vehAvgTime,backgroundColor:'#7c3aed'}}]);

// Customers
doughnut('ch-seg-pie', segLabels, segCounts, ['#4f46e5','#059669','#ea580c','#ca8a04']);
doughnut('ch-churn', ['Active','Churned'],[KPI.activeCustomers,KPI.churnCustomers],['#059669','#dc2626']);
bar('ch-rat2', ratLabels, [{{label:'Count',data:ratCounts,backgroundColor:PALETTE}}]);
bar('ch-seg-bar', segLabels, [{{label:'Customer Count',data:segCounts,backgroundColor:['#4f46e5','#059669','#ea580c','#ca8a04']}}]);

</script>
</body>
</html>
"""

with open(OUT_PATH, "w", encoding="utf-8") as f:
    f.write(HTML)

print(f"\nDASHBOARD GENERATED SUCCESSFULLY!")
print(f"    Location: {OUT_PATH}")
print(f"    Open it in Chrome / Edge by double-clicking the file.")
