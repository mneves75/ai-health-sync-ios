# Filter by Data Type: Query Specific Health Metrics

**Select which health data types to fetch from HealthKit**

---

**Time:** 5 minutes
**Difficulty:** Beginner
**Prerequisites:**
- [ ] Devices paired successfully
- [ ] iOS server running
- [ ] Data types authorized in HealthKit

---

## Goal

Query specific health data types or combinations of types from your iPhone.

---

## Steps

### Step 1: List Available Types

```bash
healthsync types
```

**Output:**
```
Available Health Data Types:
  - steps (authorized)
  - heartRate (authorized)
  - activeEnergy (authorized)
  - distance (authorized)
  - flightsClimbed (authorized)
  - sleep (authorized)
  - bloodOxygen (not authorized)
  - respiratoryRate (not authorized)
```

---

### Step 2: Query Single Type

```bash
healthsync fetch --types steps
healthsync fetch --types heartRate
healthsync fetch --types activeEnergy
```

---

### Step 3: Query Multiple Types

```bash
# Comma-separated list
healthsync fetch --types steps,heartRate,distance

# All activity types
healthsync fetch --types steps,distance,activeEnergy,flightsClimbed
```

---

### Step 4: Query All Types

```bash
# All authorized types
healthsync fetch --types all
```

**Note:** Only returns data for authorized types.

---

### Step 5: Query by Category

```bash
# Activity metrics
healthsync fetch --category activity

# Vital signs
healthsync fetch --category vitals

# Sleep data
healthsync fetch --category sleep

# Body measurements
healthsync fetch --category body
```

---

## Verification

**Check which types have data:**

```bash
# Count samples per type
healthsync fetch --types all --format json | jq 'group_by(.type) | map({type: .[0].type, count: length})'
```

---

## Available Data Types

### Activity

| Type | CLI Name | Unit | Description |
|------|----------|------|-------------|
| Steps | `steps` | count | Walking/running steps |
| Distance | `distance` | m | Walking/running distance |
| Active Energy | `activeEnergy` | kcal | Calories burned |
| Flights Climbed | `flightsClimbed` | count | Floors climbed |
| Exercise Time | `exerciseTime` | min | Workout minutes |
| Stand Time | `standTime` | min | Standing minutes |

### Vitals

| Type | CLI Name | Unit | Description |
|------|----------|------|-------------|
| Heart Rate | `heartRate` | count/min | Beats per minute |
| Resting HR | `restingHeartRate` | count/min | Resting heart rate |
| HRV | `heartRateVariability` | ms | Heart rate variability |
| Blood Oxygen | `bloodOxygen` | % | SpO2 percentage |
| Respiratory Rate | `respiratoryRate` | count/min | Breaths per minute |

### Sleep

| Type | CLI Name | Unit | Description |
|------|----------|------|-------------|
| Sleep Analysis | `sleep` | category | Sleep stages |
| Time Asleep | `timeAsleep` | min | Total sleep time |
| Time in Bed | `timeInBed` | min | Total time in bed |

### Body

| Type | CLI Name | Unit | Description |
|------|----------|------|-------------|
| Weight | `weight` | kg | Body weight |
| Height | `height` | m | Body height |
| BMI | `bmi` | count | Body mass index |
| Body Fat | `bodyFat` | % | Body fat percentage |

---

## Common Issues

### Issue: "Type not authorized"

**Cause:** HealthKit permission not granted for this type.

**Solution:**
1. Open Settings > Health > Data Access & Devices
2. Find iOS Health Sync
3. Enable the data type

### Issue: "Type not recognized"

**Cause:** Typo in type name.

**Solution:**
```bash
# List valid type names
healthsync types --list
```

### Issue: "No data for type"

**Cause:** No data recorded for this type.

**Solution:**
1. Check Health app has data for this type
2. Verify date range includes data
3. Some types require specific devices (e.g., Apple Watch for HRV)

---

## Combining Types with Filters

### Types + Date Range
```bash
healthsync fetch --types steps,heartRate \
  --start 2026-01-01 \
  --end 2026-01-07
```

### Types + Aggregation
```bash
healthsync fetch --types steps,distance \
  --days 30 \
  --aggregate daily
```

### Types + Format
```bash
healthsync fetch --types heartRate --format json > heartrate.json
```

---

## Type Aliases

Short names for common combinations:

```bash
# Activity = steps, distance, activeEnergy, flightsClimbed
healthsync fetch --types activity

# Vitals = heartRate, bloodOxygen, respiratoryRate
healthsync fetch --types vitals

# All = all authorized types
healthsync fetch --types all
```

---

## Scripting: Dynamic Type Selection

```bash
#!/bin/bash
# Fetch only types with data

TYPES=$(healthsync types --with-data --format csv | tail -n +2 | cut -d',' -f1 | tr '\n' ',')
healthsync fetch --types "$TYPES" > all_data.csv
```

---

## See Also

- [Fetch Steps](./fetch-steps.md) - Step data specifically
- [Export to CSV](./export-csv.md) - Save to files
- [Add New Data Type](./add-datatype.md) - Extend supported types
- [HealthKit Guide](../learn/06-healthkit.md) - Complete type reference

---

**Last Updated:** 2026-01-07
