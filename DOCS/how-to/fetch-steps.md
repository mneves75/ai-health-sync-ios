# Fetch Steps: Get Step Count Data

**Retrieve step count data from your iPhone via the CLI**

---

**Time:** 5 minutes
**Difficulty:** Beginner
**Prerequisites:**
- [ ] Devices paired successfully
- [ ] iOS server running
- [ ] Steps data exists in HealthKit

---

## Goal

Fetch step count data from your iPhone and display it on your Mac using the CLI.

---

## Steps

### Step 1: Verify Connection

```bash
healthsync status
```

**Expected output:**
```
Connection Status: Paired
Device: iPhone 16
Secure: Yes (mTLS)
```

If not paired, see [Pair Devices](./pair-devices.md).

---

### Step 2: Fetch Today's Steps

```bash
healthsync fetch --types steps
```

**Output (CSV format):**
```csv
timestamp,type,value,unit,source
2026-01-07T10:30:00Z,steps,1234,count,iPhone
2026-01-07T11:00:00Z,steps,567,count,iPhone
2026-01-07T11:30:00Z,steps,890,count,Apple Watch
```

---

### Step 3: Fetch Steps for Date Range

```bash
# Last 7 days
healthsync fetch --types steps \
  --start 2026-01-01T00:00:00Z \
  --end 2026-01-07T23:59:59Z
```

**Shorthand:**
```bash
# Last 7 days
healthsync fetch --types steps --days 7

# Yesterday
healthsync fetch --types steps --yesterday

# This week
healthsync fetch --types steps --week
```

---

### Step 4: Save to File

```bash
# Save as CSV
healthsync fetch --types steps > steps.csv

# Save as JSON
healthsync fetch --types steps --format json > steps.json
```

---

### Step 5: Limit Results

```bash
# Get only the last 10 entries
healthsync fetch --types steps --limit 10

# Get first 100 entries
healthsync fetch --types steps --limit 100
```

---

## Verification

**Check the data:**

```bash
# Count entries
healthsync fetch --types steps | wc -l

# View first few lines
healthsync fetch --types steps | head -5

# Sum total steps (using awk)
healthsync fetch --types steps | tail -n +2 | awk -F',' '{sum += $3} END {print "Total:", sum}'
```

---

## Output Formats

### CSV (Default)

```bash
healthsync fetch --types steps --format csv
```

```csv
timestamp,type,value,unit,source
2026-01-07T10:30:00Z,steps,1234,count,iPhone
```

### JSON

```bash
healthsync fetch --types steps --format json
```

```json
{
  "samples": [
    {
      "timestamp": "2026-01-07T10:30:00Z",
      "type": "steps",
      "value": 1234,
      "unit": "count",
      "source": "iPhone"
    }
  ],
  "count": 1,
  "query": {
    "types": ["steps"],
    "start": "2026-01-07T00:00:00Z",
    "end": "2026-01-07T23:59:59Z"
  }
}
```

---

## Common Issues

### Issue: "No data returned"

**Cause:** No step data in HealthKit for the specified range.

**Solution:**
1. Check date range includes days with data
2. Add test data to Health app:
   - Open Health > Browse > Steps > Add Data
3. Verify steps are enabled in iOS app

### Issue: "Type not authorized"

**Cause:** Steps not authorized in HealthKit.

**Solution:**
1. Open Settings > Health > Data Access & Devices
2. Find iOS Health Sync
3. Enable "Steps" permission

### Issue: "Connection timeout"

**Cause:** iOS server not running or network issue.

**Solution:**
1. Check iOS app shows "Server Running"
2. Verify both devices on same network
3. Try: `healthsync discover`

---

## Combine with Other Types

```bash
# Steps and distance
healthsync fetch --types steps,distance

# All activity data
healthsync fetch --types steps,distance,activeEnergy,flightsClimbed
```

---

## Aggregation Options

```bash
# Daily totals
healthsync fetch --types steps --aggregate daily

# Hourly breakdown
healthsync fetch --types steps --aggregate hourly

# Weekly summary
healthsync fetch --types steps --aggregate weekly
```

---

## Scripting Examples

### Daily Step Report

```bash
#!/bin/bash
# daily-steps.sh

TODAY=$(date +%Y-%m-%d)
STEPS=$(healthsync fetch --types steps --format json | jq '[.samples[].value] | add')

echo "Steps for $TODAY: $STEPS"
```

### Weekly Step Summary

```bash
#!/bin/bash
# weekly-steps.sh

healthsync fetch --types steps --days 7 --aggregate daily --format json | \
  jq -r '.aggregations[] | "\(.date): \(.total) steps"'
```

---

## See Also

- [Export to CSV](./export-csv.md) - Export all data types
- [Filter by Data Type](./filter-types.md) - Other data types
- [Sync Specific Date Range](./sync-range.md) - Date range options
- [CLI Reference](../learn/09-cli.md) - Full command reference

---

**Last Updated:** 2026-01-07
