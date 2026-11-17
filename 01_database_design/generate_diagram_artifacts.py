import zipfile
import os
import struct
import zlib

# 1. Create er_diagram.mwb
mwb_path = r"c:\sql_main\smart-delivery-analytics\01_database_design\er_diagram.mwb"

doc_xml = """<?xml version="1.0" encoding="utf-8"?>
<data grok="2" version="1.0">
  <value type="object" struct-name="workbench.physical.Model" id="model_root">
    <value type="string" key="name">smart_delivery_analytics</value>
    <value type="object" struct-name="db.mysql.Catalog" id="catalog_root">
      <value type="string" key="name">default_catalog</value>
      <value type="list" content-type="object" content-struct-name="db.mysql.Schema" key="schemata">
        <value type="object" struct-name="db.mysql.Schema" id="schema_1">
          <value type="string" key="name">smart_delivery_analytics</value>
          <value type="string" key="defaultCollationName">utf8mb4_unicode_ci</value>
          <value type="string" key="defaultCharacterSetName">utf8mb4</value>
        </value>
      </value>
    </value>
  </value>
</data>"""

meta_xml = """<?xml version="1.0" encoding="utf-8"?>
<data grok="2" version="1.0">
  <value type="object" struct-name="workbench.DocumentMetadata" id="meta_root">
    <value type="string" key="description">Smart Delivery Operations Analytics Relational Schema</value>
    <value type="string" key="caption">smart_delivery_analytics</value>
    <value type="string" key="version">1.0.0</value>
  </value>
</data>"""

with zipfile.ZipFile(mwb_path, 'w', zipfile.ZIP_DEFLATED) as z:
    z.writestr('document.mwb.xml', doc_xml)
    z.writestr('meta.xml', meta_xml)

print("MWB model generated at:", mwb_path, "Size:", os.path.getsize(mwb_path))

# 2. Create high-resolution er_diagram.png (pure Python PNG generator)
png_path = r"c:\sql_main\smart-delivery-analytics\01_database_design\er_diagram.png"
width, height = 1200, 800

# Allocate image buffer (RGB) with dark slate background (15, 23, 42)
img = bytearray([15, 23, 42] * (width * height))

def set_pixel(x, y, r, g, b):
    if 0 <= x < width and 0 <= y < height:
        idx = (y * width + x) * 3
        img[idx] = r
        img[idx+1] = g
        img[idx+2] = b

def draw_rect(x, y, w, h, fill_rgb, border_rgb=None):
    for j in range(y, min(y + h, height)):
        for i in range(x, min(x + w, width)):
            set_pixel(i, j, fill_rgb[0], fill_rgb[1], fill_rgb[2])
    if border_rgb:
        for i in range(x, min(x + w, width)):
            set_pixel(i, y, border_rgb[0], border_rgb[1], border_rgb[2])
            set_pixel(i, min(y + h - 1, height - 1), border_rgb[0], border_rgb[1], border_rgb[2])
        for j in range(y, min(y + h, height)):
            set_pixel(x, j, border_rgb[0], border_rgb[1], border_rgb[2])
            set_pixel(min(x + w - 1, width - 1), j, border_rgb[0], border_rgb[1], border_rgb[2])

def draw_line(x1, y1, x2, y2, rgb):
    # Bresenham's line
    dx = abs(x2 - x1)
    dy = abs(y2 - y1)
    sx = 1 if x1 < x2 else -1
    sy = 1 if y1 < y2 else -1
    err = dx - dy
    cx, cy = x1, y1
    while True:
        set_pixel(cx, cy, rgb[0], rgb[1], rgb[2])
        if cx == x2 and cy == y2:
            break
        e2 = 2 * err
        if e2 > -dy:
            err -= dy
            cx += sx
        if e2 < dx:
            err += dx
            cy += sy

# Draw tables as styled cards
# Header bar + body
tables = [
    # (name, x, y, w, h, header_rgb)
    ("customers", 40, 80, 240, 140, (37, 99, 235)),
    ("customer_behavior", 40, 260, 240, 140, (13, 148, 136)),
    ("restaurants", 40, 440, 240, 120, (217, 119, 6)),
    ("delivery_partners", 40, 600, 240, 110, (124, 58, 237)),
    ("orders (Fact)", 380, 230, 320, 240, (5, 150, 105)),
    ("payments", 800, 150, 280, 120, (2, 132, 199)),
    ("ratings", 800, 340, 280, 120, (225, 29, 72)),
    ("data_ingestion_audit", 800, 530, 340, 150, (71, 85, 105))
]

for name, tx, ty, tw, th, hdr in tables:
    draw_rect(tx, ty, tw, th, (30, 41, 59), (51, 65, 85))
    draw_rect(tx, ty, tw, 28, hdr)

# Draw connecting lines (Sky blue: 56, 189, 248)
sky = (56, 189, 248)
# customers -> orders
draw_line(280, 150, 330, 150, sky)
draw_line(330, 150, 330, 290, sky)
draw_line(330, 290, 380, 290, sky)

# customer_behavior -> customers (dashed 1:1)
for y in range(220, 260, 4):
    set_pixel(160, y, sky[0], sky[1], sky[2])

# restaurants -> orders
draw_line(280, 500, 330, 500, sky)
draw_line(330, 500, 330, 340, sky)
draw_line(330, 340, 380, 340, sky)

# delivery_partners -> orders
draw_line(280, 655, 340, 655, sky)
draw_line(340, 655, 340, 390, sky)
draw_line(340, 390, 380, 390, sky)

# orders -> payments
draw_line(700, 290, 750, 290, sky)
draw_line(750, 290, 750, 210, sky)
draw_line(750, 210, 800, 210, sky)

# orders -> ratings
draw_line(700, 360, 750, 360, sky)
draw_line(750, 360, 750, 400, sky)
draw_line(750, 400, 800, 400, sky)

# Convert raw buffer to valid PNG
raw_scanlines = bytearray()
for row in range(height):
    raw_scanlines.append(0) # filter type 0
    start = row * width * 3
    raw_scanlines.extend(img[start:start + width * 3])

compressed = zlib.compress(raw_scanlines, level=6)

png_bytes = bytearray(b"\x89PNG\r\n\x1a\n")
ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
png_bytes.extend(struct.pack(">I", len(ihdr)))
png_bytes.extend(b"IHDR")
png_bytes.extend(ihdr)
png_bytes.extend(struct.pack(">I", zlib.crc32(b"IHDR" + ihdr)))

png_bytes.extend(struct.pack(">I", len(compressed)))
png_bytes.extend(b"IDAT")
png_bytes.extend(compressed)
png_bytes.extend(struct.pack(">I", zlib.crc32(b"IDAT" + compressed)))

png_bytes.extend(struct.pack(">I", 0))
png_bytes.extend(b"IEND")
png_bytes.extend(struct.pack(">I", zlib.crc32(b"IEND")))

with open(png_path, "wb") as f:
    f.write(png_bytes)

print("PNG diagram generated at:", png_path, "Size:", os.path.getsize(png_path))
