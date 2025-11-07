# Grafana Correlation Demo Script

**Goal:** Show how Grafana correlates metrics and logs to provide complete observability.

---

## 🎯 Demo Scenario: "The Flash Sale Investigation"

**Story:** A flash sale caused inventory to drop rapidly. Let's investigate what happened using correlation.

---

## Part 1: Start with an Alert (The Entry Point)

### Step 1: Trigger the Alert

```bash
./run-simulation.sh
# Select: 3 (Flash Sale)
# Product: 1 (Gaming Laptop)
# Duration: 30 seconds
```

**Wait ~60 seconds** for alert to fire.

### Step 2: View the Alert

1. **Grafana** → **Alerting** → **Alert rules**
2. Find **"Low Inventory Warning"** alert
3. Show it's **Firing** 🔥
4. Click on the alert to see details
   - Shows: `product_name="Gaming Laptop"`, `stock_level=8`

**Narration:** 
> "We got an alert that Gaming Laptop inventory is low. Now let's investigate WHY this happened using Grafana's correlation features."

---

## Part 2: Metrics → See the Trend

### Step 3: Check Inventory Metrics

1. **Grafana** → **Explore**
2. **Data source:** Prometheus
3. **Query:**
   ```promql
   inventory_stock_level{product_name="Gaming Laptop"}
   ```
4. Click **Run query**

**What you see:**
- Graph showing stock dropping from 50 → 8 units
- Sharp decline during the flash sale period

**Narration:**
> "The metrics show inventory dropped rapidly in the last few minutes from 50 to 8 units. But WHAT caused this spike in orders? Let's look at logs."

---

## Part 3: Metrics → Logs (Correlation)

### Step 4: Correlate with Logs

**Method 1: Time-Based Correlation**

1. **Note the time range** from the metrics graph when inventory dropped (e.g., 14:35-14:36)
2. Click **"Split"** button to open a second panel
3. Select **Loki** as data source
4. Set the **same time range** as the metrics
5. **Query:**
   ```logql
   {service_name="shopfast-services"} |= "Order"
   ```
6. Click **Run query**

**What you see:**
- Burst of order creation logs during that exact time period
- "Order created successfully" messages
- High volume during flash sale

**Narration:**
> "By correlating the time ranges, we can see logs showing a massive spike in orders during this period. The logs confirm what the metrics suggested - there was a sudden burst of order activity."

---

## Part 4: Deep Dive into Logs

### Step 5: Analyze Log Patterns

**Refine the log query:**
```logql
{service_name="shopfast-services"} |= "product" |= "Gaming Laptop"
```

**What you see:**
- Specific orders for Gaming Laptop
- Order quantities
- Timestamps matching the metrics spike

**Narration:**
> "We can filter logs to see only Gaming Laptop orders. This gives us the detailed context - we can see individual transactions that caused the inventory depletion."

---

## Part 5: Check Related Metrics

### Step 6: View Request Rate

**Add another split panel with Prometheus:**

```promql
rate(http_requests_total{endpoint="/api/orders"}[5m])
```

**What you see:**
- Request rate spike correlating with inventory drop
- Normal rate: ~5 req/min
- Flash sale rate: ~40 req/min

**Narration:**
> "And here's the request rate to our API - it spiked from 5 to 40 requests per minute during the flash sale. All these data sources tell the same story when we correlate them by time."

---

## 📊 Complete Correlation Flow Summary

Here's what we just demonstrated:

```
1. ALERT fires (Low Inventory)
   ↓
2. Check METRICS (Prometheus) - See inventory dropping
   ↓
3. Correlate with LOGS (Loki) - See burst of orders at same time
   ↓
4. Check related METRICS - Confirm request rate spike
   ↓
5. ROOT CAUSE IDENTIFIED: Flash sale drove high order volume
```

**Key Correlations Shown:**
- ✅ Alert → Metrics (what's happening)
- ✅ Metrics → Logs (why it's happening)  
- ✅ Time-based correlation (same events across sources)
- ✅ Multi-dimensional view (inventory + orders + requests)

---

## 🎬 Alternative Scenarios

### Scenario 2: Payment Failures (Error Investigation)

1. Run payment failures simulation
2. **Alert fires:** "Payment Service Failures"  
3. **Metrics:** Show error rate spike
4. **Logs:** Filter for ERROR level, see "payment failed" messages
5. **Correlation:** Match error spike time with log timestamps

**Demo Query:**
```logql
{service_name="shopfast-services"} |= "ERROR" |= "payment"
```

### Scenario 3: Security Investigation

1. Run security breach simulation
2. **Alert fires:** "Multiple Failed Login Attempts"
3. **Database:** Show failed attempts count
4. **Logs:** Show authentication failure messages
5. **Metrics:** Show authentication error rate spike

---

## 💡 Demo Tips

### What to Say:

**Opening:**
> "Traditional monitoring shows you WHAT is broken. Grafana Observability shows you WHAT, WHY, and WHERE - all correlated together by time."

**During Correlation:**
> "Notice how I'm using the same time range across all data sources. Grafana makes it easy to correlate events by matching timestamps. No copying times between tools, no switching platforms."

**Key Benefit:**
> "From alert to root cause in under 3 minutes. That's the power of correlation - reducing MTTR (Mean Time To Resolution) by having all your observability data in one place."

### Common Questions:

**Q: "How does Grafana correlate the data?"**
A: "Time-based correlation. All data sources include timestamps, and Grafana makes it easy to query the same time ranges across metrics, logs, and databases."

**Q: "Does this work with any data source?"**
A: "Yes! Grafana supports 150+ data sources. As long as they provide timestamped data, you can correlate them."

**Q: "What if my services don't have structured logs?"**
A: "You can still correlate by time. Structured logs make filtering easier, but time-based correlation works with any log format."

---

## 🔧 Quick Access Queries

### Metrics - Inventory Levels
```promql
inventory_stock_level{product_name="Gaming Laptop"}
```

### Metrics - Request Rate
```promql
rate(http_requests_total[5m])
```

### Metrics - Error Rate
```promql
rate(http_requests_total{status=~"5.."}[5m])
```

### Logs - All Orders
```logql
{service_name="shopfast-services"} |= "Order"
```

### Logs - Errors Only
```logql
{service_name="shopfast-services"} |= "ERROR"
```

### Logs - Payment Related
```logql
{service_name="shopfast-services"} |= "payment"
```

---

## 🚀 Practice Run Checklist

Before your demo:

- [ ] Start all services: `docker compose up -d`
- [ ] Wait 60 seconds for initialization
- [ ] Pre-open Grafana Explore tab
- [ ] Test one flash sale run
- [ ] Verify metrics are collecting in Prometheus
- [ ] Verify logs are appearing in Loki
- [ ] Practice the time-range correlation flow
- [ ] Bookmark this file for reference

---

**Remember:** The goal is to show how **time-based correlation across metrics and logs** reduces investigation time from hours to minutes. Focus on the "aha!" moment when logs confirm what metrics suggest! 🎯

