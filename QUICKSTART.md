# Quick Start Guide

Get the ShopFast demo running in 5 minutes!

## Prerequisites

- Docker Desktop installed and running
- Python 3.9 or higher
- 4GB available RAM

## Step-by-Step

### 1. Start the Environment

**Linux/Mac:**
```bash
chmod +x start-demo.sh
./start-demo.sh
```

**Windows:**
```bash
start-demo.bat
```

Or manually:
```bash
docker-compose up -d
```

### 2. Wait for Services

Give the services 30-60 seconds to start up. You can check progress:

```bash
docker-compose ps
```

All services should show "Up" status.

### 3. Access Grafana

Open your browser: http://localhost:3000

- **Username**: admin
- **Password**: admin

### 4. Verify Data Sources

In Grafana:
1. Go to **Configuration → Data Sources**
2. You should see:
   - ✅ Prometheus (default)
   - ✅ Loki
   - ✅ PostgreSQL

Click each one and click "Test" to verify they're working.

### 5. Check Alert Rules

In Grafana:
1. Go to **Alerting → Alert rules**
2. You should see 7 alert rules configured:
   - High CPU Usage
   - High Error Rate
   - Slow API Response Time
   - Payment Service Failures
   - Low Inventory Warning
   - Critical Inventory Alert
   - Multiple Failed Login Attempts

### 6. Run Your First Simulation

```bash
cd simulation
pip install -r requirements.txt
python simulator.py normal --duration 60
```

This simulates normal e-commerce traffic for 60 seconds.

### 7. Trigger an Alert

Let's trigger a low inventory alert:

```bash
python simulator.py flash-sale --product-id 1 --duration 30
```

Watch in Grafana:
1. Go to **Alerting → Alert rules**
2. Find "Low Inventory Warning"
3. Wait 30-60 seconds
4. The alert should fire! 🎉

### 8. View Alert Details

In Grafana:
1. Go to **Alerting → Alert rules**
2. Click on the firing alert
3. See the details: which product, current stock level
4. Check the alert history

## Next Steps

### Try Other Scenarios

```bash
# Payment failures (log-based alert)
python simulator.py payment-failures --duration 60

# Security incident (database alert)
python simulator.py security

# High CPU (metric-based alert)
python simulator.py high-cpu --duration 30

# Run everything
python simulator.py all
```

### Explore the Data

**Prometheus** (metrics): http://localhost:9090
- Try queries like: `rate(http_requests_total[5m])`
- See all metrics from services

**Loki** (logs): Use Grafana's Explore view
- Query: `{service="payment"} |= "ERROR"`
- See all service logs

**PostgreSQL** (business data): Use Grafana's Explore view
- Query: `SELECT * FROM low_stock_products`
- See inventory levels

### Create Custom Dashboards

In Grafana:
1. Click **+** → **Dashboard**
2. Add panels with:
   - Order counts from Prometheus
   - Error logs from Loki
   - Inventory levels from PostgreSQL

### Modify Alerts

1. Go to **Alerting → Alert rules**
2. Click any alert to edit
3. Change thresholds, durations, etc.
4. Save and test!

## Common Issues

### Services won't start
```bash
docker-compose down
docker-compose up -d --force-recreate
```

### Can't connect to database
Wait 60 seconds. PostgreSQL takes time to initialize on first run.

### Alerts not firing
- Check alert evaluation interval (default: 30s)
- Check alert "For" duration
- Verify the query returns data in Explore

### Logs not appearing
```bash
# Check if log directory exists
ls -la logs/

# Check Promtail is running
docker-compose logs promtail
```

## Stop Everything

```bash
docker-compose down
```

To remove all data and start fresh:
```bash
docker-compose down -v
```

## Ready for Your Talk?

Check out the full [README.md](README.md) for:
- Detailed architecture
- All alert configurations
- Demo presentation flow
- Customization options

**Pro tip**: Run through all scenarios once before your presentation to ensure everything works!

