# Creating Alerts Manually in Grafana UI

This guide shows you how to create all 7 demo alerts manually in Grafana, which you can then export to fix the provisioned versions.

## Prerequisites

1. Access Grafana: http://localhost:3000 (admin/admin)
2. Ensure all 3 data sources are configured:
   - Prometheus (UID: `prometheus`)
   - Loki (UID: `loki`)
   - PostgreSQL (UID: `postgres`)

## Create Folder First

1. Go to **Dashboards** → **New** → **New folder**
2. Name: `ShopFast Demo`
3. Click **Create**

---

## Alert 1: High CPU Usage (Prometheus)

### Navigation
1. Go to **Alerting** → **Alert rules**
2. Click **New alert rule**

### Configuration

**Step 1: Enter alert rule name**
- **Rule name**: `High CPU Usage`

**Step 2: Define query and alert condition**
- **Section A - Query**:
  - Select data source: **Prometheus**
  - Query: `rate(process_cpu_seconds_total[1m])`
  - Time range: `From: now-5m, To: now`

- **Section B - Expression**:
  - Operation: **Threshold**
  - Input: A
  - IS ABOVE: `0.7`
  - Make this the alert condition: ✓ (checked)

**Step 3: Set evaluation behavior**
- **Folder**: `ShopFast Demo`
- **Evaluation group**: Create new: `ShopFast Alerts`
- **Evaluation interval**: `30s`
- **Pending period**: `1m`

**Step 4: Add annotations**
- **Summary**: `High CPU usage detected`
- **Description**: `CPU usage is above 70% for {{ $labels.service }} service`

**Step 5: Add labels**
- `severity` = `warning`
- `team` = `platform`

**Save and exit**

---

## Alert 2: High Error Rate (Prometheus)

**Step 1: Enter alert rule name**
- **Rule name**: `High Error Rate`

**Step 2: Define query and alert condition**
- **Section A - Query**:
  - Data source: **Prometheus**
  - Query: `rate(http_requests_total{status=~"5.."}[5m])`
  - Time range: `From: now-5m, To: now`

- **Section B - Expression**:
  - Operation: **Threshold**
  - Input: A
  - IS ABOVE: `0.1`
  - Make this the alert condition: ✓

**Step 3: Set evaluation behavior**
- **Folder**: `ShopFast Demo`
- **Evaluation group**: `ShopFast Alerts` (existing)
- **Pending period**: `2m`

**Step 4: Add annotations**
- **Summary**: `High error rate detected`
- **Description**: `Error rate is above 10% for {{ $labels.service }} service`

**Step 5: Add labels**
- `severity` = `critical`
- `team` = `backend`

**Save and exit**

---

## Alert 3: Slow API Response Time (Prometheus)

**Step 1: Enter alert rule name**
- **Rule name**: `Slow API Response Time`

**Step 2: Define query and alert condition**
- **Section A - Query**:
  - Data source: **Prometheus**
  - Query: `histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))`
  - Time range: `From: now-5m, To: now`

- **Section B - Expression**:
  - Operation: **Threshold**
  - Input: A
  - IS ABOVE: `1.0`
  - Make this the alert condition: ✓

**Step 3: Set evaluation behavior**
- **Folder**: `ShopFast Demo`
- **Evaluation group**: `ShopFast Alerts` (existing)
- **Pending period**: `3m`

**Step 4: Add annotations**
- **Summary**: `Slow response time detected`
- **Description**: `95th percentile response time is above 1 second for {{ $labels.service }}`

**Step 5: Add labels**
- `severity` = `warning`
- `team` = `backend`

**Save and exit**

---

## Alert 4: Payment Service Failures (Loki)

**Step 1: Enter alert rule name**
- **Rule name**: `Payment Service Failures`

**Step 2: Define query and alert condition**
- **Section A - Query**:
  - Data source: **Loki**
  - Query: `sum(count_over_time({service="payment"} |~ "ERROR|payment failed" [5m]))`
  - Time range: `From: now-10m, To: now`

- **Section B - Expression**:
  - Operation: **Threshold**
  - Input: A
  - IS ABOVE: `5`
  - Make this the alert condition: ✓

**Step 3: Set evaluation behavior**
- **Folder**: `ShopFast Demo`
- **Evaluation group**: `ShopFast Alerts` (existing)
- **Pending period**: `1m`

**Step 4: Add annotations**
- **Summary**: `Payment service experiencing failures`
- **Description**: `Payment service has more than 5 failures in the last 5 minutes`

**Step 5: Add labels**
- `severity` = `critical`
- `team` = `payments`

**Save and exit**

---

## Alert 5: Low Inventory Warning (PostgreSQL)

**Step 1: Enter alert rule name**
- **Rule name**: `Low Inventory Warning`

**Step 2: Define query and alert condition**
- **Section A - Query**:
  - Data source: **PostgreSQL**
  - Toggle to **Code** mode (SQL editor)
  - Query:
    ```sql
    SELECT 
      name as metric,
      stock_level as value,
      NOW() as time
    FROM products 
    WHERE stock_level <= low_stock_threshold
    ```
  - Format: **Table**
  - Time range: `From: now-10m, To: now`

- **Section B - Expression**:
  - Operation: **Threshold**
  - Input: A
  - Condition: **Rows returned**
  - IS ABOVE: `0`
  - Make this the alert condition: ✓

**Step 3: Set evaluation behavior**
- **Folder**: `ShopFast Demo`
- **Evaluation group**: `ShopFast Alerts` (existing)
- **Pending period**: `30s`

**Step 4: Add annotations**
- **Summary**: `Low inventory detected for multiple products`
- **Description**: `Products are running low on inventory`

**Step 5: Add labels**
- `severity` = `warning`
- `team` = `operations`

**Save and exit**

---

## Alert 6: Critical Inventory Alert (PostgreSQL)

**Step 1: Enter alert rule name**
- **Rule name**: `Critical Inventory Alert`

**Step 2: Define query and alert condition**
- **Section A - Query**:
  - Data source: **PostgreSQL**
  - Toggle to **Code** mode
  - Query:
    ```sql
    SELECT 
      name as metric,
      stock_level as value,
      NOW() as time
    FROM products 
    WHERE stock_level <= 5
    ```
  - Format: **Table**
  - Time range: `From: now-10m, To: now`

- **Section B - Expression**:
  - Operation: **Threshold**
  - Input: A
  - Condition: **Rows returned**
  - IS ABOVE: `0`
  - Make this the alert condition: ✓

**Step 3: Set evaluation behavior**
- **Folder**: `ShopFast Demo`
- **Evaluation group**: `ShopFast Alerts` (existing)
- **Pending period**: `30s`

**Step 4: Add annotations**
- **Summary**: `CRITICAL: Inventory almost depleted`
- **Description**: `Products have critically low inventory (5 or fewer units)`

**Step 5: Add labels**
- `severity` = `critical`
- `team` = `operations`

**Save and exit**

---

## Alert 7: Multiple Failed Login Attempts (PostgreSQL)

**Step 1: Enter alert rule name**
- **Rule name**: `Multiple Failed Login Attempts`

**Step 2: Define query and alert condition**
- **Section A - Query**:
  - Data source: **PostgreSQL**
  - Toggle to **Code** mode
  - Query:
    ```sql
    SELECT 
      email as metric,
      COUNT(*) as value,
      NOW() as time
    FROM login_attempts 
    WHERE success = false 
      AND attempt_time > NOW() - INTERVAL '5 minutes' 
    GROUP BY email 
    HAVING COUNT(*) >= 5
    ```
  - Format: **Table**
  - Time range: `From: now-10m, To: now`

- **Section B - Expression**:
  - Operation: **Threshold**
  - Input: A
  - Condition: **Rows returned**
  - IS ABOVE: `0`
  - Make this the alert condition: ✓

**Step 3: Set evaluation behavior**
- **Folder**: `ShopFast Demo`
- **Evaluation group**: `ShopFast Alerts` (existing)
- **Pending period**: `1m`

**Step 4: Add annotations**
- **Summary**: `Potential brute force attack detected`
- **Description**: `Multiple failed login attempts detected for user account`

**Step 5: Add labels**
- `severity` = `critical`
- `team` = `security`

**Save and exit**

---

## After Creating All Alerts

### Export the Alert Rules

1. Go to **Alerting** → **Alert rules**
2. Click on each alert rule
3. Click **Export** button (top right)
4. Choose **Export for provisioning**
5. Save the YAML

### Update Provisioning File

1. Combine all exported alerts into one file
2. Replace `grafana/provisioning/alerting/alerting.yml`
3. Restart Grafana to verify they load correctly

---

## Tips

### If Alert Doesn't Fire

1. **Check the query** in Explore first:
   - Go to **Explore**
   - Select the data source
   - Run the query
   - Verify it returns data

2. **Check evaluation**:
   - In alert rule, click **Evaluate now**
   - See what data it's receiving

3. **Check time ranges**:
   - PostgreSQL queries need explicit time column
   - Prometheus queries use scrape time automatically
   - Loki queries use log timestamp

### Common Issues

**PostgreSQL alerts**: 
- Must return columns: `metric`, `value`, and `time`
- Use `NOW()` for the time column
- Format must be **Table**

**Loki alerts**:
- Count queries work better than raw log queries
- Use `count_over_time()` for counting log lines
- Use `|~` for regex matching

**Prometheus alerts**:
- Use `rate()` for counters
- Use `histogram_quantile()` for latency percentiles
- Time range is automatic based on query range

---

## Quick Reference: Data Source UIDs

When creating alerts via API or JSON:
- Prometheus: `prometheus`
- Loki: `loki`
- PostgreSQL: `postgres`

---

Good luck! Once you've created and tested these alerts, export them and we'll update the provisioning file with the working versions.

