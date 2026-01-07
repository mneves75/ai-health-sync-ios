# Sync Specific Date Range: Query Data by Time Period

**Fetch health data for specific dates or time ranges**

---

**Time:** 5 minutes
**Difficulty:** Beginner
**Prerequisites:**
- [ ] Devices paired successfully
- [ ] iOS server running
- [ ] Health data exists for the date range

---

## Goal

Query health data for specific time periods using date ranges and convenience shortcuts.

---

## Steps

### Step 1: Explicit Date Range

```bash
healthsync fetch --types steps \
  --start 2026-01-01T00:00:00Z \
  --end 2026-01-07T23:59:59Z
```

**Date format:** ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`)

---

### Step 2: Date-Only Format

```bash
# Dates without time (midnight to midnight)
healthsync fetch --types steps \
  --start 2026-01-01 \
  --end 2026-01-07
```

---

### Step 3: Relative Date Shortcuts

```bash
# Today
healthsync fetch --types steps --today

# Yesterday
healthsync fetch --types steps --yesterday

# Last 7 days
healthsync fetch --types steps --days 7

# Last 30 days
healthsync fetch --types steps --days 30

# This week (Monday to today)
healthsync fetch --types steps --week

# This month
healthsync fetch --types steps --month

# This year
healthsync fetch --types steps --year
```

---

### Step 4: Time-Specific Queries

```bash
# Morning hours only (6 AM - 12 PM)
healthsync fetch --types steps \
  --start 2026-01-07T06:00:00Z \
  --end 2026-01-07T12:00:00Z

# Last 24 hours
healthsync fetch --types steps --hours 24

# Last 2 hours
healthsync fetch --types steps --hours 2
```

---

### Step 5: Combine with Other Options

```bash
# Last week, aggregated daily, as JSON
healthsync fetch --types steps \
  --days 7 \
  --aggregate daily \
  --format json

# January 2026, limited to 1000 results
healthsync fetch --types steps \
  --start 2026-01-01 \
  --end 2026-01-31 \
  --limit 1000
```

---

## Verification

**Check the date range of returned data:**

```bash
# First and last timestamps
healthsync fetch --types steps --days 7 | head -2
healthsync fetch --types steps --days 7 | tail -1
```

---

## Date Format Reference

| Format | Example | Description |
|--------|---------|-------------|
| ISO 8601 Full | `2026-01-07T10:30:00Z` | UTC timestamp |
| ISO 8601 Date | `2026-01-07` | Date only (midnight) |
| Local Time | `2026-01-07T10:30:00` | Without Z (local) |

**Timezone notes:**
- `Z` suffix = UTC
- No suffix = local timezone
- Results always returned in UTC

---

## Common Date Ranges

### This Week
```bash
healthsync fetch --types steps --week
```

### Last Month
```bash
healthsync fetch --types steps --days 30
```

### Specific Month
```bash
# February 2026
healthsync fetch --types steps \
  --start 2026-02-01 \
  --end 2026-02-28
```

### Year to Date
```bash
healthsync fetch --types steps \
  --start 2026-01-01 \
  --end $(date +%Y-%m-%d)
```

### All Time (Caution!)
```bash
# May return large amounts of data
healthsync fetch --types steps \
  --start 2020-01-01 \
  --end 2026-12-31
```

---

## Common Issues

### Issue: "No data in range"

**Cause:** No health data exists for the specified dates.

**Solution:**
1. Widen the date range
2. Verify data exists in Health app
3. Check the data type is correct

### Issue: "Too much data returned"

**Cause:** Large date range returns millions of samples.

**Solution:**
1. Use `--limit` flag: `--limit 1000`
2. Use aggregation: `--aggregate daily`
3. Use smaller date ranges

### Issue: "Timeout on large queries"

**Cause:** Query takes too long to complete.

**Solution:**
1. Reduce date range
2. Query one data type at a time
3. Use pagination: `--offset 0 --limit 1000`

---

## Aggregation by Time Period

### Daily Aggregation
```bash
healthsync fetch --types steps --days 30 --aggregate daily
```

**Output:**
```csv
date,type,total,average,min,max,count
2026-01-01,steps,10234,1023,45,2345,10
2026-01-02,steps,8567,856,23,1890,10
```

### Hourly Aggregation
```bash
healthsync fetch --types steps --today --aggregate hourly
```

**Output:**
```csv
hour,type,total,average,count
2026-01-07T06:00:00Z,steps,234,117,2
2026-01-07T07:00:00Z,steps,567,189,3
```

### Weekly Aggregation
```bash
healthsync fetch --types steps --days 90 --aggregate weekly
```

---

## Scripting Examples

### Compare Two Periods

```bash
#!/bin/bash
# Compare this week vs last week

THIS_WEEK=$(healthsync fetch --types steps --week --format json | jq '[.samples[].value] | add')
LAST_WEEK=$(healthsync fetch --types steps --days 14 --format json | jq '[.samples[].value] | add' | awk '{print $1/2}')

echo "This week: $THIS_WEEK steps"
echo "Last week average: $LAST_WEEK steps"
```

### Monthly Report

```bash
#!/bin/bash
# Monthly step totals for 2026

for month in {01..12}; do
  START="2026-$month-01"
  END="2026-$month-31"  # CLI handles month-end automatically

  TOTAL=$(healthsync fetch --types steps \
    --start "$START" --end "$END" \
    --format json | jq '[.samples[].value] | add // 0')

  echo "2026-$month: $TOTAL steps"
done
```

---

## See Also

- [Fetch Steps](./fetch-steps.md) - Basic step data fetching
- [Export to CSV](./export-csv.md) - Save data to files
- [Filter by Type](./filter-types.md) - Query different data types

---

**Last Updated:** 2026-01-07
