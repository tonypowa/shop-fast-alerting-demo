# Demo Queries - Complete Working Reference

This document contains all working queries for demonstrating the ShopFast observability stack.

---

## 📊 METRICS QUERIES (Prometheus)

### General Service Metrics

**Query 1: Request rate by service**
```promql
sum by (job) (rate(http_requests_total[5m]))
```
Shows requests per second for each service.

**Query 2: Requests by status code**
```promql
sum by (job, status) (rate(http_requests_total[5m]))
```
Break down by HTTP status codes (200, 201, 400, 500, etc.)

**Query 3: Error rate (4xx + 5xx)**
```promql
sum by (job) (rate(http_requests_total{status=~"4..|5.."}[5m]))
```
Shows only error responses.

**Query 4: Success rate percentage**
```promql
sum by (job) (rate(http_requests_total{status=~"2.."}[5m])) / sum by (job) (rate(http_requests_total[5m])) * 100
```
Percentage of successful requests per service.

**Query 5: Average response time by service**
```promql
rate(http_request_duration_seconds_sum[5m]) / rate(http_request_duration_seconds_count[5m])
```
Average latency in seconds.

**Query 6: p95 latency by service**
```promql
histogram_quantile(0.95, sum by (job, le) (rate(http_request_duration_seconds_bucket[5m])))
```
95th percentile response time.

**Query 7: Service health (up/down)**
```promql
up
```
Returns 1 if service is up, 0 if down.

---

### Inventory Metrics

**Query 8: All product stock levels**
```promql
inventory_stock_level
```
Current stock for all products.

**Query 9: Gaming Laptop stock (Product ID 1)**
```promql
inventory_stock_level{product_id="1"}
```
Watch this drop during flash sale!

**Query 10: Product by name**
```promql
inventory_stock_level{product_name="Gaming Laptop"}
```
Filter by product name.

**Query 11: Low stock product count**
```promql
inventory_low_stock_products
```
Number of products below their threshold.

**Query 12: Products below 20 units**
```promql
inventory_stock_level < 20
```
Alert-worthy inventory levels.

**Query 13: Products below threshold**
```promql
inventory_stock_level <= on(product_id) group_left inventory_low_stock_threshold
```
Products that need restocking.

---

### Payment Metrics

**Query 14: Payment rate**
```promql
rate(payments_total[5m])
```
Payments per second.

**Query 15: Payments by status**
```promql
sum by (status) (rate(payments_total[5m]))
```
Shows success vs failed payments.

**Query 16: Failed payment rate**
```promql
rate(payments_total{status="failed"}[5m])
```
Only failed payments.

**Query 17: Payment success rate %**
```promql
sum(rate(payments_total{status="success"}[5m])) / sum(rate(payments_total[5m])) * 100
```
Percentage of successful payments.

**Query 18: Total payment amount processed**
```promql
rate(payment_amount_total[5m])
```
Dollar amount per second.

---

### Order Metrics

**Query 19: Order creation rate**
```promql
rate(orders_total[5m])
```
Orders per second.

**Query 20: Total orders created**
```promql
orders_total
```
Cumulative order count.

---

### Frontend Metrics

**Query 21: Page view rate**
```promql
rate(page_views_total[5m])
```
Pages viewed per second.

**Query 22: Total page views**
```promql
page_views_total
```
Cumulative page views.

---

## 📝 LOG QUERIES (Loki)

### General Logs

**Query 1: All service logs**
```logql
{service_name="shopfast-services"}
```

**Query 2: Logs containing "ERROR"**
```logql
{service_name="shopfast-services"} |= "ERROR"
```

**Query 3: Logs containing "WARNING"**
```logql
{service_name="shopfast-services"} |= "WARNING"
```

**Query 4: Filter by filename (service)**
```logql
{service_name="shopfast-services", filename="/app/logs/api.log"}
```
Available filenames: `/app/logs/api.log`, `/app/logs/frontend.log`, `/app/logs/payment.log`, `/app/logs/inventory.log`

**Query 5: All services (regex)**
```logql
{filename=~"/app/logs/.*\\.log", service_name="shopfast-services"}
```

---

### Order Logs

**Query 6: Order creation logs**
```logql
{service_name="shopfast-services", filename="/app/logs/api.log"} |= "Order" |= "created"
```

**Query 7: Failed orders**
```logql
{service_name="shopfast-services", filename="/app/logs/api.log"} |= "Order" |= "failed"
```

**Query 8: Orders for specific product**
```logql
{service_name="shopfast-services", filename="/app/logs/api.log"} |= "Order" |= "product 1"
```

---

### Payment Logs

**Query 9: Payment errors**
```logql
{service_name="shopfast-services", filename="/app/logs/payment.log"} |= "ERROR" |= "failed"
```

**Query 10: Payment failures with reason**
```logql
{service_name="shopfast-services", filename="/app/logs/payment.log"} |= "Payment failed"
```

---

### Inventory Logs

**Query 11: Stock updates**
```logql
{service_name="shopfast-services", filename="/app/logs/inventory.log"} |= "Stock updated"
```

**Query 12: Low stock warnings**
```logql
{service_name="shopfast-services", filename="/app/logs/inventory.log"} |= "Low stock"
```

---

### Log Analytics

**Query 13: Count errors over time**
```logql
sum(count_over_time({service_name="shopfast-services"} |= "ERROR" [1m]))
```

**Query 14: Error rate by service (filename)**
```logql
sum by (filename) (count_over_time({service_name="shopfast-services"} |= "ERROR" [5m]))
```

**Query 15: Top error messages by service**
```logql
topk(10, sum by (filename) (count_over_time({service_name="shopfast-services"} |= "ERROR" [5m])))
```

---

## 🎯 DEMO WALKTHROUGH QUERIES

### Flash Sale Scenario

Run simulation: `./run-simulation.sh` → Option 3 → Product 1 → 30 seconds

**1. Show inventory dropping (Metrics)**
```promql
inventory_stock_level{product_id="1"}
```

**2. Show orders increasing (Metrics)**
```promql
rate(orders_total[5m])
```

**3. Show traffic spike (Metrics)**
```promql
sum(rate(http_requests_total[5m]))
```

**4. Show order logs (Logs)**
```logql
{service_name="shopfast-services", filename="/app/logs/api.log"} |= "Order" |= "created" |= "product 1"
```

**5. Check alert (Metrics)**
```promql
inventory_stock_level{product_id="1"} <= 10
```

---

### Payment Failures Scenario

Run simulation: `./run-simulation.sh` → Option 4 → 60 seconds

**1. Show payment failures (Metrics)**
```promql
rate(payments_total{status="failed"}[5m])
```

**2. Show error logs (Logs)**
```logql
{service_name="shopfast-services", filename="/app/logs/payment.log"} |= "Payment failed"
```

**3. Count errors over time (Logs)**
```logql
sum(count_over_time({service_name="shopfast-services", filename="/app/logs/payment.log"} |= "ERROR" [1m]))
```

---

## 🔔 ALERT QUERIES

These are the actual queries used in alerts:

**High CPU Usage**
```promql
rate(process_cpu_seconds_total[1m]) > 0.7
```

**High Error Rate**
```promql
rate(http_requests_total[2m]) > 0 
and 
rate(http_requests_total{status=~"5.."}[2m]) / rate(http_requests_total[2m]) > 0.1
```

**Slow Response Time**
```promql
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[3m])) > 1
```

**Payment Failures (Loki)**
```logql
sum(count_over_time({service="payment"} |~ "ERROR|payment failed" [5m])) > 5
```

**Low Inventory (PostgreSQL)**
```sql
SELECT name, stock_level 
FROM products 
WHERE stock_level <= low_stock_threshold
```

---

## 💡 Pro Tips

1. **Use rate() for counters** - Always use `rate()` with `_total` metrics
2. **Use sum by (label)** - Group results by service, status, etc.
3. **Time ranges matter** - [5m] for rate, [1m] for count_over_time
4. **Filter early** - `{service_name="shopfast-services", filename="/app/logs/api.log"}` before `|=` filters
5. **Correlate signals** - Use timestamps to jump between metrics and logs
6. **Loki labels** - service_name="shopfast-services", filename="/app/logs/{service}.log"
7. **String filtering** - Use `|= "ERROR"` or `|= "WARNING"` since level is not a label

---

## 🚀 Quick Reference Card

| Signal | Datasource | Example Query |
|--------|-----------|---------------|
| Metrics | Prometheus | `rate(http_requests_total[5m])` |
| Logs | Loki | `{service_name="shopfast-services", filename="/app/logs/api.log"} \|= "ERROR"` |
| Database | PostgreSQL | `SELECT stock_level FROM products WHERE id = 1` |

---

**For more information:**
- Main README: `README.md`
- Correlation Demo: `CORRELATION_DEMO.md`
- Database Schema: `DATABASE_SCHEMA.md`

