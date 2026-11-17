Add-Type -AssemblyName System.Drawing

$width = 1600
$height = 1100
$bmp = New-Object System.Drawing.Bitmap $width, $height
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

# Background
$bgBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(15, 23, 42)) # Slate 900
$g.FillRectangle($bgBrush, 0, 0, $width, $height)

# Title
$titleFont = New-Object System.Drawing.Font "Segoe UI", 20, [System.Drawing.FontStyle]::Bold
$subFont = New-Object System.Drawing.Font "Segoe UI", 11, [System.Drawing.FontStyle]::Regular
$headerBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(56, 189, 248)) # Sky 400
$whiteBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(248, 250, 252))
$mutedBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(148, 163, 184))

$g.DrawString("SMART DELIVERY OPERATIONS ANALYTICS — ENTITY RELATIONSHIP DIAGRAM", $titleFont, $headerBrush, 50, 30)
$g.DrawString("Target Database: smart_delivery_analytics | Engine: InnoDB | MySQL 8.0+ Enterprise Schema", $subFont, $mutedBrush, 52, 68)

# Table drawing function
function Draw-Table {
    param($x, $y, $w, $h, $tableName, $badge, $columns, $headerColor)
    
    # Outer box shadow / border
    $borderPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(51, 65, 85)), 2
    $cardBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(30, 41, 59))
    $g.FillRectangle($cardBrush, $x, $y, $w, $h)
    $g.DrawRectangle($borderPen, $x, $y, $w, $h)
    
    # Header
    $headBrush = New-Object System.Drawing.SolidBrush $headerColor
    $g.FillRectangle($headBrush, $x, $y, $w, 36)
    
    $tblFont = New-Object System.Drawing.Font "Segoe UI", 11, [System.Drawing.FontStyle]::Bold
    $badgeFont = New-Object System.Drawing.Font "Segoe UI", 9, [System.Drawing.FontStyle]::Regular
    $g.DrawString($tableName, $tblFont, $whiteBrush, ($x + 10), ($y + 8))
    $g.DrawString($badge, $badgeFont, $whiteBrush, ($x + $w - 85), ($y + 10))
    
    # Columns
    $colFont = New-Object System.Drawing.Font "Consolas", 9.5, [System.Drawing.FontStyle]::Regular
    $pkFont = New-Object System.Drawing.Font "Consolas", 9.5, [System.Drawing.FontStyle]::Bold
    $keyBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(251, 191, 36)) # Amber
    $fkBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(129, 140, 248)) # Indigo
    $textBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(226, 232, 240))
    $typeBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(148, 163, 184))
    
    $curY = $y + 44
    foreach ($col in $columns) {
        $parts = $col -split "\|"
        $keyType = $parts[0].Trim()
        $colName = $parts[1].Trim()
        $dataType = $parts[2].Trim()
        
        if ($keyType -eq "PK") {
            $g.DrawString("[PK]", $pkFont, $keyBrush, ($x + 8), $curY)
        } elseif ($keyType -eq "FK") {
            $g.DrawString("[FK]", $pkFont, $fkBrush, ($x + 8), $curY)
        } elseif ($keyType -eq "PFK") {
            $g.DrawString("[PFK]", $pkFont, $keyBrush, ($x + 6), $curY)
        } else {
            $g.DrawString("    ", $colFont, $mutedBrush, ($x + 8), $curY)
        }
        
        $g.DrawString($colName, $colFont, $textBrush, ($x + 52), $curY)
        $g.DrawString($dataType, $colFont, $typeBrush, ($x + $w - 110), $curY)
        $curY += 22
    }
}

# Color definitions
$blueHead = [System.Drawing.Color]::FromArgb(37, 99, 235)
$tealHead = [System.Drawing.Color]::FromArgb(13, 148, 136)
$purpleHead = [System.Drawing.Color]::FromArgb(124, 58, 237)
$amberHead = [System.Drawing.Color]::FromArgb(217, 119, 6)
$emeraldHead = [System.Drawing.Color]::FromArgb(5, 150, 105)
$roseHead = [System.Drawing.Color]::FromArgb(225, 29, 72)

# Draw Master / Dimension Tables
Draw-Table 50 120 340 190 "customers" "1,000 rows" @(
    "PK  | customer_id   | INT UNSIGNED",
    "    | customer_name | VARCHAR(100)",
    "    | age           | TINYINT UNSIGNED",
    "    | gender        | ENUM(3)",
    "    | city          | VARCHAR(50)",
    "    | signup_date   | DATE"
) $blueHead

Draw-Table 50 360 340 190 "customer_behavior" "1,000 rows" @(
    "PFK | customer_id   | INT UNSIGNED",
    "    | total_orders  | SMALLINT UNSIGNED",
    "    | total_spending| DECIMAL(10,2)",
    "    | avg_order_val | DECIMAL(10,2)",
    "    | last_order_dys| SMALLINT UNSIGNED",
    "    | churn_flag    | TINYINT(1)"
) $tealHead

Draw-Table 50 600 340 170 "restaurants" "100 rows" @(
    "PK  | restaurant_id | SMALLINT UNSIGNED",
    "    | restaurant_nam| VARCHAR(100)",
    "    | cuisine_type  | VARCHAR(50)",
    "    | city          | VARCHAR(50)",
    "    | rating        | DECIMAL(2,1)"
) $amberHead

Draw-Table 50 820 340 150 "delivery_partners" "200 rows" @(
    "PK  | partner_id    | SMALLINT UNSIGNED",
    "    | partner_name  | VARCHAR(100)",
    "    | vehicle_type  | ENUM(4)",
    "    | joining_date  | DATE"
) $purpleHead

# Draw Central Orders Fact Table
Draw-Table 520 320 420 270 "orders" "10,000 rows" @(
    "PK  | order_id       | INT UNSIGNED",
    "FK  | customer_id    | INT UNSIGNED",
    "FK  | restaurant_id  | SMALLINT UNSIGNED",
    "FK  | partner_id     | SMALLINT UNSIGNED",
    "    | order_time     | DATETIME",
    "    | delivered_time | DATETIME NULL",
    "    | order_amount   | DECIMAL(10,2)",
    "    | delivery_fee   | DECIMAL(10,2)",
    "    | status         | ENUM(3)",
    "    | created_at     | TIMESTAMP"
) $emeraldHead

# Draw Sub-Facts (Payments & Ratings)
Draw-Table 1080 230 360 160 "payments" "10,000 rows" @(
    "PK  | payment_id    | INT UNSIGNED",
    "FK  | order_id      | INT UNSIGNED (UQ)",
    "    | payment_mode  | ENUM(5)",
    "    | amount        | DECIMAL(10,2)",
    "    | created_at    | TIMESTAMP"
) $emeraldHead

Draw-Table 1080 470 360 160 "ratings" "7,000 rows" @(
    "PK  | rating_id     | INT UNSIGNED",
    "FK  | order_id      | INT UNSIGNED (UQ)",
    "    | cust_rating   | DECIMAL(2,1)",
    "    | feedback      | VARCHAR(255)",
    "    | created_at    | TIMESTAMP"
) $roseHead

# Draw Audit Table
Draw-Table 1080 720 460 210 "data_ingestion_audit" "Pipeline Audit" @(
    "PK  | audit_id       | BIGINT UNSIGNED",
    "    | batch_id       | VARCHAR(64)",
    "    | source_entity  | VARCHAR(64)",
    "    | target_table   | VARCHAR(64)",
    "    | operation_type | ENUM(4)",
    "    | records_read   | INT UNSIGNED",
    "    | records_insert | INT UNSIGNED",
    "    | status         | ENUM(3)"
) $blueHead

# Draw Relationship Connectors
$relPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(56, 189, 248)), 2 # Sky 400
$relPenDash = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(129, 140, 248)), 2
$relPenDash.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash

# customers (1) to orders (M)
$g.DrawLine($relPen, 390, 210, 460, 210)
$g.DrawLine($relPen, 460, 210, 460, 360)
$g.DrawLine($relPen, 460, 360, 520, 360)

# customers (1) to customer_behavior (1)
$g.DrawLine($relPenDash, 220, 310, 220, 360)

# restaurants (1) to orders (M)
$g.DrawLine($relPen, 390, 680, 460, 680)
$g.DrawLine($relPen, 460, 680, 460, 410)
$g.DrawLine($relPen, 460, 410, 520, 410)

# delivery_partners (1) to orders (M)
$g.DrawLine($relPen, 390, 890, 480, 890)
$g.DrawLine($relPen, 480, 890, 480, 440)
$g.DrawLine($relPen, 480, 440, 520, 440)

# orders (1) to payments (1)
$g.DrawLine($relPen, 940, 380, 1010, 380)
$g.DrawLine($relPen, 1010, 380, 1010, 310)
$g.DrawLine($relPen, 1010, 310, 1080, 310)

# orders (1) to ratings (0..1)
$g.DrawLine($relPen, 940, 450, 1010, 450)
$g.DrawLine($relPen, 1010, 450, 1010, 550)
$g.DrawLine($relPen, 1010, 550, 1080, 550)

# Add Legend
$legendBox = New-Object System.Drawing.Rectangle 50, 990, 900, 75
$g.FillRectangle((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(30, 41, 59))), $legendBox)
$g.DrawRectangle((New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(71, 85, 105)), 1), $legendBox)

$lblFont = New-Object System.Drawing.Font "Segoe UI", 10, [System.Drawing.FontStyle]::Bold
$g.DrawString("RELATIONSHIP CARDINALITY LEGEND:", $lblFont, $whiteBrush, 65, 1005)

$g.DrawLine($relPen, 340, 1015, 380, 1015)
$g.DrawString("One-to-Many (1 : M) Identifying Relation", $subFont, $mutedBrush, 390, 1005)

$g.DrawLine($relPenDash, 670, 1015, 710, 1015)
$g.DrawString("One-to-One (1 : 1) Extension Entity", $subFont, $mutedBrush, 720, 1005)

$g.DrawString("Primary Keys: [PK] | Foreign Keys: [FK] | Strict Referential Integrity: ON UPDATE CASCADE ON DELETE RESTRICT", $subFont, $headerBrush, 65, 1035)

# Save image
$outputPath = "c:\sql_main\smart-delivery-analytics\01_database_design\er_diagram.png"
$bmp.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)

$g.Dispose()
$bmp.Dispose()
Write-Host "ER Diagram image successfully rendered to: $outputPath"
