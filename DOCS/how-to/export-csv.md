# Export to CSV: Save Health Data as CSV Files

**Export health data from iPhone to CSV format for analysis**

---

**Time:** 5 minutes
**Difficulty:** Beginner
**Prerequisites:**
- [ ] Devices paired successfully
- [ ] iOS server running
- [ ] CLI installed and accessible

---

## Goal

Export health data to CSV files that can be opened in Excel, Google Sheets, or analyzed with scripts.

---

## Steps

### Step 1: Basic CSV Export

```bash
healthsync fetch --types steps --format csv > steps.csv
```

**Output file (steps.csv):**
```csv
timestamp,type,value,unit,source
2026-01-07T10:30:00Z,steps,1234,count,iPhone
2026-01-07T11:00:00Z,steps,567,count,iPhone
```

---

### Step 2: Export Multiple Data Types

```bash
# Export steps and heart rate together
healthsync fetch --types steps,heartRate --format csv > health_data.csv
```

**Output:**
```csv
timestamp,type,value,unit,source
2026-01-07T10:30:00Z,steps,1234,count,iPhone
2026-01-07T10:30:00Z,heartRate,72,count/min,Apple Watch
```

---

### Step 3: Export All Data Types

```bash
# Export everything
healthsync fetch --types all --format csv > all_health_data.csv
```

**Warning:** This may be a large file depending on your date range.

---

### Step 4: Export with Date Range

```bash
# January 2026 only
healthsync fetch --types steps \
  --start 2026-01-01T00:00:00Z \
  --end 2026-01-31T23:59:59Z \
  --format csv > january_steps.csv
```

---

### Step 5: Export to Specific Directory

```bash
# Create output directory
mkdir -p ~/HealthExports

# Export with date stamp
healthsync fetch --types steps --format csv > ~/HealthExports/steps_$(date +%Y%m%d).csv
```

---

## Verification

**Check the exported file:**

```bash
# View first lines
head -5 steps.csv

# Count rows
wc -l steps.csv

# Check file size
ls -lh steps.csv
```

---

## CSV Column Reference

| Column | Description | Example |
|--------|-------------|---------|
| `timestamp` | ISO 8601 date/time | `2026-01-07T10:30:00Z` |
| `type` | Health data type | `steps`, `heartRate` |
| `value` | Numeric value | `1234`, `72.5` |
| `unit` | Measurement unit | `count`, `count/min`, `kcal` |
| `source` | Data source device | `iPhone`, `Apple Watch` |

---

## Advanced Export Options

### Include Metadata

```bash
healthsync fetch --types steps --format csv --include-metadata > steps_with_meta.csv
```

**Additional columns:**
```csv
timestamp,type,value,unit,source,deviceName,deviceModel,bundleIdentifier
```

### Aggregate Before Export

```bash
# Daily totals
healthsync fetch --types steps --aggregate daily --format csv > daily_steps.csv
```

**Output:**
```csv
date,type,total,average,min,max,count
2026-01-01,steps,10234,1023,45,2345,10
2026-01-02,steps,8567,856,23,1890,10
```

### Custom Delimiter

```bash
# Tab-separated values
healthsync fetch --types steps --format tsv > steps.tsv

# Semicolon-separated (for European Excel)
healthsync fetch --types steps --delimiter ";" > steps_euro.csv
```

---

## Common Issues

### Issue: "CSV is empty"

**Cause:** No data in the specified date range.

**Solution:**
1. Check date range includes data
2. Verify the data type is enabled
3. Try without date filters first

### Issue: "Special characters in data"

**Cause:** Source names or notes contain commas.

**Solution:**
The CLI automatically quotes fields with special characters:
```csv
timestamp,type,value,unit,source
2026-01-07T10:30:00Z,steps,1234,count,"My Device, Version 2"
```

### Issue: "File is too large"

**Cause:** Exporting many types over long date range.

**Solution:**
1. Export one type at a time
2. Use shorter date ranges
3. Use aggregation to reduce rows

---

## Opening in Applications

### Excel

1. Double-click the `.csv` file
2. Or: File > Import > CSV

### Google Sheets

1. Open Google Sheets
2. File > Import > Upload
3. Select your CSV file

### Numbers (macOS)

1. Double-click the `.csv` file
2. Or: File > Import > CSV

### Python/Pandas

```python
import pandas as pd

df = pd.read_csv('steps.csv', parse_dates=['timestamp'])
print(df.head())
print(df['value'].sum())  # Total steps
```

### R

```r
library(readr)
steps <- read_csv("steps.csv")
summary(steps)
```

---

## Batch Export Script

**Export all types to separate files:**

```bash
#!/bin/bash
# export_all.sh

OUTPUT_DIR=~/HealthExports/$(date +%Y%m%d)
mkdir -p "$OUTPUT_DIR"

TYPES=("steps" "heartRate" "activeEnergy" "distance" "sleep")

for type in "${TYPES[@]}"; do
  echo "Exporting $type..."
  healthsync fetch --types "$type" --format csv > "$OUTPUT_DIR/$type.csv"
done

echo "Export complete! Files in $OUTPUT_DIR"
ls -la "$OUTPUT_DIR"
```

---

## See Also

- [Fetch Steps](./fetch-steps.md) - Basic data fetching
- [Sync Date Range](./sync-range.md) - Date range options
- [Filter by Type](./filter-types.md) - Available data types

---

**Last Updated:** 2026-01-07
