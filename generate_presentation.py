"""
Generates an 8-slide presentation file (.pptx) using standard library zipfile & XML templates.
Office Open XML (PPTX) format compatible with Microsoft PowerPoint, Google Slides, and LibreOffice.
"""
import zipfile
import os
import xml.sax.saxutils as saxutils

def escape(text):
    return saxutils.escape(str(text))

OUT_PPTX = r"c:\sql_main\smart-delivery-analytics\Smart_Delivery_Operations_Analytics.pptx"
HTML_SLIDES = r"c:\sql_main\smart-delivery-analytics\Smart_Delivery_Operations_Analytics_Presentation.html"

# Slide contents: (Title, Subtitle/Category, Bullet points / structured cards)
SLIDES_DATA = [
    {
        "title": "Smart Delivery Operations Analytics",
        "subtitle": "End-to-End Analytics Engineering & Business Intelligence Solution",
        "bullets": [
            "Industry-standard BI system for last-mile food delivery operations (Swiggy / Zomato scale).",
            "Full pipeline: Raw CSV ingestion -> MySQL 3NF Database -> Advanced SQL Analytics -> Excel & Power BI Dashboards.",
            "Covers 10,000 orders, 1,000 customers, 100 merchant restaurants, and 200 delivery partners across 10 metropolitan hubs.",
            "Deliverables: Relational DB, 71 analytical SQL queries, automated stored procedures, dynamic Excel workbook, and interactive dashboards."
        ]
    },
    {
        "title": "Business Context & Technology Stack",
        "subtitle": "Operational Problem Statements & Enterprise Tools",
        "bullets": [
            "Core Problem Domains: Delivery Delays & SLA breaches, Order Cancellations, Revenue Optimization, Customer Retention & Churn, Fleet Utilization.",
            "Database Engine: MySQL 8.0+ with InnoDB, strict Primary/Foreign keys, CHECK constraints, and composite performance indexing.",
            "Analytics Layer: MySQL SQL (CTEs, Window Functions LAG/LEAD/RANK, Stored Procedures, Views).",
            "Reporting & BI: Microsoft Excel (dynamic formulas, PivotTables, slicers), Microsoft Power BI (Star Schema, DAX library), and Interactive Web Dashboard."
        ]
    },
    {
        "title": "Database Architecture & 3-Tier Design",
        "subtitle": "From Raw CSV Staging to Production 3NF Schemas",
        "bullets": [
            "Tier 1 - Staging Layer (stg_*): Ingests 7 raw CSV files (29,300 total records) while preserving raw source fidelity.",
            "Tier 2 - Data Cleaning & Reconciliation: Standardized ENUMs, trimmed whitespace, clamped ratings (1.0-5.0), and handled 1,803 null timestamps.",
            "Tier 3 - Relational Production Schema (3NF): customers, customer_behavior, restaurants, delivery_partners, orders, payments, ratings.",
            "Data Quality Audit: 100% reconciled census pass with 0 duplicate orders, 0 orphan records, and strict foreign key integrity."
        ]
    },
    {
        "title": "SQL Analytics & Deep-Dive Syllabus",
        "subtitle": "71 Analytical Queries Across 3 Complexity Tiers",
        "bullets": [
            "Level 1: Basic Queries (B01-B12): Active fleet inventory, customer geographic footprint, status splits, payment popularity.",
            "Level 2: Intermediate Queries (I01-I14): Multi-table JOINs, city-wise SLA breach rates (>45 min), merchant revenue rankings, customer dormancy.",
            "Level 3: Advanced Queries (A01-A15): Window functions (LAG, DENSE_RANK, NTILE), 7-day moving averages, MoM revenue trajectory, RFM segmentation.",
            "5 Dedicated Business Analytics Modules: Deep-dive investigations solving specific operational bottlenecks with actionable root-cause findings."
        ]
    },
    {
        "title": "Key Business Insights & Findings",
        "subtitle": "Quantified Operational Metrics & Baseline KPIs",
        "bullets": [
            "Fulfillment Performance: 8,197 successfully delivered orders (81.97%) with an average delivery duration of 39.48 minutes.",
            "Financial Volume: ₹5,398,812 total collected revenue (₹4.98M merchandise GMV + ₹409K delivery fees) with an AOV of ₹608.63.",
            "Cancellation Diagnostics: 1,803 orders cancelled (18.03%), peaking during weekend evening peak dining windows (8:00 PM - 10:00 PM).",
            "Fleet Efficiency: Balanced fleet composition (Bike: 51, Scooter: 50, EV: 50, Bicycle: 49); EV and Bikes lead on-time rates."
        ]
    },
    {
        "title": "Automated Database Objects & Stored Procedures",
        "subtitle": "Reusable Production Analytics Engine",
        "bullets": [
            "11 Analytical Views: vw_dashboard_overview, vw_monthly_revenue, vw_city_performance, vw_cancellation_analysis, vw_fact_orders.",
            "sp_get_executive_kpis: Instant on-demand executive scorecard for any custom date window (delivers 11 real-time KPIs).",
            "sp_get_city_performance_report: Granular metropolitan diagnostic breakdown with top 5 merchant revenue drivers.",
            "sp_partner_scorecard & sp_identify_at_risk_customers: Predictive courier performance reviews and pro-active churn prevention alerts."
        ]
    },
    {
        "title": "Spreadsheet & Business Intelligence Layer",
        "subtitle": "Microsoft Excel & Interactive Dashboard Solutions",
        "bullets": [
            "Excel Workbook (Smart_Delivery_Analytics.xlsx): 7 fully styled sheets (Executive, Delivery, Cancellations, Revenue, Restaurants, Partners, Customers).",
            "Dynamic Formula Layer: Built with live Excel formulas, interactive city/date slicers, and ODBC refresh capability.",
            "Power BI Architecture: Dimensional Star Schema (FactOrders, FactPayments, DimCustomer, DimRestaurant, DimPartner, DimDate).",
            "Standalone Interactive Dashboard: Single-click desktop dashboard with animated KPI cards, dual-axis charts, and instant browser visualization."
        ]
    },
    {
        "title": "Strategic Recommendations & Business Roadmap",
        "subtitle": "Actionable Steps to Drive Efficiency & Profitability",
        "bullets": [
            "SLA Optimization: Implement dynamic delivery radius geofencing during peak rain/traffic hours to cut SLA breaches by ~14%.",
            "Merchant Kitchen SLA Penalties: Enforce prep-time tracking to curb peak-hour kitchen cancellations (saving ~₹320K quarterly GMV).",
            "Targeted Customer Retention: Automate promotional re-engagement vouchers for customers approaching day 60 of dormancy.",
            "Fleet Green Transition: Expand Electric Bike courier allocation for dense urban routes to lower per-delivery logistics overhead."
        ]
    }
]

# Generate standalone printable HTML Presentation slide deck
html_content = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"/>
<title>Smart Delivery Operations Analytics - Presentation</title>
<style>
  @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700;800&display=swap');
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: 'Inter', sans-serif; background: #0f172a; color: #1e293b; padding: 40px 20px; display: flex; flex-direction: column; align-items: center; gap: 32px; }
  .slide { width: 1000px; height: 562px; background: #ffffff; border-radius: 18px; box-shadow: 0 20px 40px rgba(0,0,0,0.4); padding: 48px 56px; display: flex; flex-direction: column; justify-content: space-between; position: relative; overflow: hidden; page-break-after: always; }
  .slide::before { content: ""; position: absolute; top: 0; left: 0; right: 0; height: 8px; background: linear-gradient(90deg, #2563eb, #3b82f6, #06b6d4); }
  .slide-header { margin-bottom: 24px; }
  .slide-num { position: absolute; top: 28px; right: 48px; font-size: 13px; font-weight: 700; color: #64748b; background: #f1f5f9; padding: 4px 12px; border-radius: 20px; }
  .slide-title { font-size: 28px; font-weight: 800; color: #1e3a8a; letter-spacing: -0.5px; margin-bottom: 6px; }
  .slide-subtitle { font-size: 14px; font-weight: 600; color: #64748b; text-transform: uppercase; letter-spacing: 0.8px; }
  .slide-body { flex: 1; display: flex; flex-direction: column; gap: 14px; justify-content: center; }
  .bullet-card { background: #f8fafc; border-left: 4px solid #3b82f6; padding: 14px 18px; border-radius: 8px; font-size: 15px; line-height: 1.5; color: #334155; }
  .bullet-card strong { color: #0f172a; font-weight: 700; }
  .slide-footer { display: flex; justify-content: space-between; align-items: center; border-top: 1px solid #e2e8f0; padding-top: 14px; font-size: 12px; font-weight: 600; color: #94a3b8; }
  .print-btn { position: fixed; top: 20px; right: 20px; background: #2563eb; color: #fff; border: none; padding: 12px 24px; font-size: 14px; font-weight: 700; border-radius: 8px; cursor: pointer; box-shadow: 0 4px 14px rgba(37,99,235,0.4); z-index: 100; }
  .print-btn:hover { background: #1d4ed8; }
  @media print {
    body { background: #fff; padding: 0; gap: 0; }
    .print-btn { display: none; }
    .slide { box-shadow: none; border-radius: 0; width: 100vw; height: 100vh; page-break-after: always; }
  }
</style>
</head>
<body>
<button class="print-btn" onclick="window.print()">🖨️ Print / Save as PDF</button>
"""

for idx, s in enumerate(SLIDES_DATA):
    html_content += f"""
    <div class="slide">
        <div class="slide-num">Slide {idx+1} of {len(SLIDES_DATA)}</div>
        <div class="slide-header">
            <h1 class="slide-title">{s['title']}</h1>
            <p class="slide-subtitle">{s['subtitle']}</p>
        </div>
        <div class="slide-body">
    """
    for b in s['bullets']:
        html_content += f'<div class="bullet-card">{escape(b)}</div>'
    html_content += f"""
        </div>
        <div class="slide-footer">
            <span>Smart Delivery Operations Analytics (MySQL + Excel + Power BI)</span>
            <span>Enterprise BI Engineering</span>
        </div>
    </div>
    """

html_content += """
</body>
</html>
"""

with open(HTML_SLIDES, "w", encoding="utf-8") as f:
    f.write(html_content)

print(f"Presentation HTML generated at: {HTML_SLIDES}")

# Now build the binary PPTX package (Open Packaging Conventions - OPC ZIP)
def create_pptx(filename, slides):
    # XML templates for a minimal valid presentation
    content_types = ['<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">',
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>',
        '<Default Extension="xml" ContentType="application/xml"/>',
        '<Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>',
        '<Override PartName="/ppt/slideLayouts/slideLayout1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml"/>',
        '<Override PartName="/ppt/slideMasters/slideMaster1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml"/>',
        '<Override PartName="/ppt/theme/theme1.xml" ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/>'
    ]
    for i in range(1, len(slides) + 1):
        content_types.append(f'<Override PartName="/ppt/slides/slide{i}.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>')
    content_types.append('</Types>')
    
    pkg_rels = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/>\n'
        '</Relationships>')
        
    theme_xml = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<a:theme xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" name="Office Theme">\n'
        '<a:themeElements>\n'
        '<a:clrScheme name="Office">\n'
        '<a:dk1><a:sysClr val="windowText" lastClr="000000"/></a:dk1>\n'
        '<a:lt1><a:sysClr val="window" lastClr="FFFFFF"/></a:lt1>\n'
        '<a:dk2><a:srgbClr val="1E3A8A"/></a:dk2>\n'
        '<a:lt2><a:srgbClr val="F8FAFC"/></a:lt2>\n'
        '<a:accent1><a:srgbClr val="2563EB"/></a:accent1>\n'
        '<a:accent2><a:srgbClr val="059669"/></a:accent2>\n'
        '<a:accent3><a:srgbClr val="D97706"/></a:accent3>\n'
        '<a:accent4><a:srgbClr val="DC2626"/></a:accent4>\n'
        '<a:accent5><a:srgbClr val="4F46E5"/></a:accent5>\n'
        '<a:accent6><a:srgbClr val="0891B2"/></a:accent6>\n'
        '<a:hlink><a:srgbClr val="2563EB"/></a:hlink>\n'
        '<a:folHlink><a:srgbClr val="7C3AED"/></a:folHlink>\n'
        '</a:clrScheme>\n'
        '<a:fontScheme name="Office">\n'
        '<a:majorFont><a:latin typeface="Segoe UI"/><a:ea typeface=""/><a:cs typeface=""/></a:majorFont>\n'
        '<a:minorFont><a:latin typeface="Segoe UI"/><a:ea typeface=""/><a:cs typeface=""/></a:minorFont>\n'
        '</a:fontScheme>\n'
        '<a:fmtScheme name="Office">\n'
        '<a:fillStyleLst><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:fillStyleLst>\n'
        '<a:lnStyleLst><a:ln w="9525"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:ln><a:ln w="25400"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:ln><a:ln w="38100"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:ln></a:lnStyleLst>\n'
        '<a:effectStyleLst><a:effectStyle><a:effectLst/></a:effectStyle><a:effectStyle><a:effectLst/></a:effectStyle><a:effectStyle><a:effectLst/></a:effectStyle></a:effectStyleLst>\n'
        '<a:bgFillStyleLst><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:bgFillStyleLst>\n'
        '</a:fmtScheme>\n'
        '</a:themeElements>\n'
        '</a:theme>')

    slide_master_xml = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<p:sldMaster xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">\n'
        '<p:cSld><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr></p:spTree></p:cSld>\n'
        '<p:clrMap bg1="lt1" tx1="dk1" bg2="lt2" tx2="dk2" accent1="accent1" accent2="accent2" accent3="accent3" accent4="accent4" accent5="accent5" accent6="accent6" hlink="hlink" folHlink="folHlink"/>\n'
        '<p:sldLayoutIdLst><p:sldLayoutId id="2147483649" r:id="rId1"/></p:sldLayoutIdLst>\n'
        '</p:sldMaster>')
        
    slide_master_rels = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>\n'
        '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="../theme/theme1.xml"/>\n'
        '</Relationships>')

    slide_layout_xml = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<p:sldLayout xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" type="blank">\n'
        '<p:cSld><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr></p:spTree></p:cSld>\n'
        '</p:sldLayout>')

    slide_layout_rels = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="../slideMasters/slideMaster1.xml"/>\n'
        '</Relationships>')

    # Presentation XML
    pres_xml_parts = ['<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
        '<p:presentation xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">',
        '<p:sldMasterIdLst><p:sldMasterId id="2147483648" r:id="rId1"/></p:sldMasterIdLst>',
        '<p:sldIdLst>'
    ]
    for i in range(1, len(slides) + 1):
        pres_xml_parts.append(f'<p:sldId id="{255 + i}" r:id="rId{i + 1}"/>')
    pres_xml_parts.append('</p:sldIdLst>')
    pres_xml_parts.append('<p:sldSz cx="12192000" cy="6858000"/>') # 16:9 widescreen
    pres_xml_parts.append('</p:presentation>')
    presentation_xml = "".join(pres_xml_parts)

    pres_rels_parts = ['<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">',
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="slideMasters/slideMaster1.xml"/>'
    ]
    for i in range(1, len(slides) + 1):
        pres_rels_parts.append(f'<Relationship Id="rId{i + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide{i}.xml"/>')
    pres_rels_parts.append('</Relationships>')
    presentation_rels = "".join(pres_rels_parts)

    slide_rels = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>\n'
        '</Relationships>')

    # Write files into ZIP
    with zipfile.ZipFile(filename, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("[Content_Types].xml", "".join(content_types))
        zf.writestr("_rels/.rels", pkg_rels)
        zf.writestr("ppt/_rels/presentation.xml.rels", presentation_rels)
        zf.writestr("ppt/presentation.xml", presentation_xml)
        zf.writestr("ppt/theme/theme1.xml", theme_xml)
        zf.writestr("ppt/slideMasters/slideMaster1.xml", slide_master_xml)
        zf.writestr("ppt/slideMasters/_rels/slideMaster1.xml.rels", slide_master_rels)
        zf.writestr("ppt/slideLayouts/slideLayout1.xml", slide_layout_xml)
        zf.writestr("ppt/slideLayouts/_rels/slideLayout1.xml.rels", slide_layout_rels)

        # Generate each individual slide XML
        for i, s in enumerate(slides, 1):
            slide_xml = [
                '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
                '<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">',
                '<p:cSld>',
                '<p:spTree>',
                '<p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>',
                '<p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>',
                
                # Header Accent Bar (Blue)
                '<p:sp>',
                '<p:nvSpPr><p:cNvPr id="2" name="Accent"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr>',
                '<p:spPr><a:xfrm><a:off x="609600" y="457200"/><a:ext cx="10972800" cy="57150"/></a:xfrm>',
                '<a:prstGeom prst="rect"><a:avLst/></a:prstGeom><a:solidFill><a:srgbClr val="2563EB"/></a:solidFill></p:spPr>',
                '</p:sp>',
                
                # Title Box
                '<p:sp>',
                '<p:nvSpPr><p:cNvPr id="3" name="Title"/><p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr><p:nvPr/></p:nvSpPr>',
                '<p:spPr><a:xfrm><a:off x="609600" y="609600"/><a:ext cx="10972800" cy="1143000"/></a:xfrm></p:spPr>',
                '<p:txBody><a:bodyPr/><a:lstStyle/>',
                f'<a:p><a:pPr><a:buNone/></a:pPr><a:r><a:rPr lang="en-US" sz="3200" b="1"><a:solidFill><a:srgbClr val="1E3A8A"/></a:solidFill></a:rPr><a:t>{escape(s["title"])}</a:t></a:r></a:p>',
                f'<a:p><a:pPr><a:buNone/></a:pPr><a:r><a:rPr lang="en-US" sz="1600" b="1"><a:solidFill><a:srgbClr val="64748B"/></a:solidFill></a:rPr><a:t>{escape(s["subtitle"])}</a:t></a:r></a:p>',
                '</p:txBody>',
                '</p:sp>',

                # Content Card Box
                '<p:sp>',
                '<p:nvSpPr><p:cNvPr id="4" name="Content"/><p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr><p:nvPr/></p:nvSpPr>',
                '<p:spPr><a:xfrm><a:off x="609600" y="1981200"/><a:ext cx="10972800" cy="4267200"/></a:xfrm>',
                '<a:prstGeom prst="roundRect"><a:avLst><a:gd name="adj" fmla="val 2000"/></a:avLst></a:prstGeom>',
                '<a:solidFill><a:srgbClr val="F8FAFC"/></a:solidFill>',
                '<a:ln w="12700"><a:solidFill><a:srgbClr val="E2E8F0"/></a:solidFill></a:ln>',
                '</p:spPr>',
                '<p:txBody><a:bodyPr tIns="228600" bIns="228600" lIns="274320" rIns="274320"/><a:lstStyle/>'
            ]
            for b in s["bullets"]:
                slide_xml.append(
                    f'<a:p><a:pPr marL="285750" indent="-285750"><a:buFont typeface="Arial"/><a:buChar char="•"/></a:pPr>'
                    f'<a:r><a:rPr lang="en-US" sz="1800"><a:solidFill><a:srgbClr val="334155"/></a:solidFill></a:rPr>'
                    f'<a:t>{escape(b)}</a:t></a:r></a:p>'
                    f'<a:p><a:pPr><a:buNone/></a:pPr></a:p>' # Spacing
                )
            slide_xml.extend([
                '</p:txBody>',
                '</p:sp>',

                # Footer
                '<p:sp>',
                '<p:nvSpPr><p:cNvPr id="5" name="Footer"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr>',
                '<p:spPr><a:xfrm><a:off x="609600" y="6350000"/><a:ext cx="10972800" cy="304800"/></a:xfrm></p:spPr>',
                '<p:txBody><a:bodyPr/><a:lstStyle/>',
                f'<a:p><a:pPr><a:buNone/></a:pPr><a:r><a:rPr lang="en-US" sz="1100"><a:solidFill><a:srgbClr val="94A3B8"/></a:solidFill></a:rPr><a:t>Smart Delivery Operations Analytics  |  Slide {i} of {len(slides)}</a:t></a:r></a:p>',
                '</p:txBody>',
                '</p:sp>',

                '</p:spTree>',
                '</p:cSld>',
                '</p:sld>'
            ])
            zf.writestr(f"ppt/slides/slide{i}.xml", "".join(slide_xml))
            zf.writestr(f"ppt/slides/_rels/slide{i}.xml.rels", slide_rels)

    print(f"PowerPoint Presentation created successfully at: {filename}")

create_pptx(OUT_PPTX, SLIDES_DATA)
