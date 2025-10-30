# 🚀 START HERE - ShopFast Demo Quick Reference

Welcome to the ShopFast Grafana Alerting Demo! This guide will get you running in 2 minutes.

## What You Have

A complete **Grafana alerting demo** with:
- 🎯 **8 microservices** (Grafana, Prometheus, Loki, PostgreSQL + 4 app services)
- 📊 **7 pre-configured alerts** (metrics, logs, and database alerts)
- 🐍 **Dockerized Python simulator** (no local Python needed!)
- 🎮 **2 interactive control panels** (simulation + database control)

---

## 🏃 Quick Start

### Step 1: Start Services
```bash
cd /home/tonypowa/Desktop/grafana/tonypowaGrafana/grafana/demo-alerting-stack
docker compose up -d
```

Wait 30-60 seconds for initialization.

### Step 2: Access Grafana
Open browser: **http://localhost:3000**
- Username: `admin`
- Password: `admin`

Go to: **Alerting → Alert rules** (you'll see 7 alerts)

### Step 3: Run a Simulation
```bash
./run-simulation.sh
```

Select: **Option 2** (Flash Sale)  
Watch the alert fire in Grafana! 🎉

---

## 🎮 Two Control Panels

### 1. Simulation Control (Recommended)
```bash
./run-simulation.sh
```

**What it does:** Generates realistic traffic to trigger alerts  
**Best for:** Complete demos, testing, training  
**Time:** 30-120 seconds per scenario  

**Menu:**
```
1) 🟢 Normal Traffic
2) ⚡ Flash Sale (LOW INVENTORY alert)
3) 💳 Payment Failures (LOG-BASED alert)
4) 🔒 Security Breach (DATABASE alert)
5) 🔥 High CPU (METRICS alert)
6) 📦 Low Inventory (gradual)
7) 🎯 Run ALL Scenarios
8) 🔧 Rebuild Docker Image
9) ❌ Exit
```

### 2. Database Control (Quick Fixes)
```bash
./demo-control.sh
```

**What it does:** Directly modifies inventory in database  
**Best for:** Instant alerts, quick resets, live demos  
**Time:** Instant + 30s for alert evaluation  

**Menu:**
```
1) Reset to Default (50 units)
2) Set to High Stock (100 units)
3) Set Near Threshold (15 units)
4) Trigger Alert Now (8 units) ⚡
5) View All Products
6) Reset All Products
7) Clear All Orders
8) Exit
```

---

## 📋 5-Minute Demo Script

Perfect for presentations:

```bash
# 1. Start services
docker compose up -d
# Wait 60 seconds

# 2. Open Grafana
http://localhost:3000
# Show the 7 alert rules

# 3. Run flash sale
./run-simulation.sh
# Select: 2, Product: 1, Duration: 30

# 4. Watch alert fire (30-60s)
# Show in Grafana → Alerting → Alert rules

# 5. Reset
./demo-control.sh
# Select: 1 (Reset to Default)
```

---

## 📚 Documentation Index

| File | Purpose |
|------|---------|
| **START_HERE.md** | 👈 You are here! Quick reference |
| **USAGE_GUIDE.md** | Complete usage guide with workflows |
| **CONTROL_SCRIPTS.md** | Comparison of both control scripts |
| **DOCKER_SIMULATOR.md** | Technical details of simulator |
| **README.md** | Full project documentation |
| **QUICKSTART.md** | 5-minute quick start |
| **ARCHITECTURE.md** | System architecture details |
| **TROUBLESHOOTING.md** | Common issues and solutions |

---

## 🎯 Alert Types Demonstrated

### Prometheus (Metrics-Based)
- ✅ High CPU Usage (>70% for 1 min)
- ✅ High Error Rate (>10% for 2 min)
- ✅ Slow Response Time (p95 >1s for 3 min)

### Loki (Log-Based)
- ✅ Payment Service Failures (>5 errors in 5 min)

### PostgreSQL (Database-Based)
- ✅ Low Inventory Warning (stock ≤ threshold)
- ✅ Critical Inventory (stock ≤ 5)
- ✅ Failed Logins (≥5 attempts in 5 min)

---

## 🔧 Docker Permissions (Ubuntu)

If you get "permission denied" errors:

```bash
# Add yourself to docker group (one-time)
sudo usermod -aG docker $USER

# Activate the group
newgrp docker

# Verify
docker ps
```

---

## 🎬 Service URLs

| Service | URL | Purpose |
|---------|-----|---------|
| Grafana | http://localhost:3000 | Dashboards & Alerts |
| Prometheus | http://localhost:9090 | Metrics storage |
| Loki | http://localhost:3100 | Log aggregation |
| API | http://localhost:8080 | Order/product API |
| Frontend | http://localhost:8081 | Web app |
| Payment | http://localhost:8082 | Payment processing |
| Inventory | http://localhost:8083 | Stock management |
| PostgreSQL | localhost:5432 | Business database |

---

## 🛠️ Common Commands

```bash
# Start everything
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f

# Run simulation (interactive)
./run-simulation.sh

# Database control (interactive)
./demo-control.sh

# Stop everything
docker compose down

# Full reset (removes data)
docker compose down -v
```

---

## 🆘 Troubleshooting

### Services won't start
```bash
docker compose down
docker compose up -d --force-recreate
```

### Simulator connection errors
```bash
# Check services are running
docker compose ps

# All should show "Up" status
```

### Alerts not firing
- Wait at least 30 seconds (evaluation interval)
- Check alert "For" duration in Grafana
- Verify query returns data in Explore

### Docker permission denied
```bash
sudo usermod -aG docker $USER
newgrp docker
```

---

## 💡 Pro Tips

1. **Pre-run everything** before presentations
2. **Set evaluation interval to 30s** for faster demos
3. **Open multiple terminal windows:**
   - Window 1: `docker compose logs -f`
   - Window 2: `./run-simulation.sh`
   - Window 3: Grafana in browser
4. **Use `demo-control.sh`** for instant resets between demos
5. **Bookmark Grafana URLs:**
   - http://localhost:3000/alerting/list
   - http://localhost:3000/explore

---

## 🎓 Learning Path

### Beginner
1. Start services (`docker compose up -d`)
2. Access Grafana (http://localhost:3000)
3. Run one simulation (`./run-simulation.sh` → Option 2)
4. Watch alert fire
5. Explore alert configuration in Grafana

### Intermediate
1. Run all scenarios (`./run-simulation.sh` → Option 7)
2. Check logs in Loki (`Explore → Loki`)
3. Query metrics in Prometheus (`Explore → Prometheus`)
4. Modify alert thresholds in Grafana
5. Create custom dashboards

### Advanced
1. Add notification channels (Slack, PagerDuty)
2. Modify service code to add metrics
3. Create new alert rules
4. Customize simulation scenarios
5. Build custom dashboards for each service

---

## 🎉 Ready to Demo!

### For a 10-minute presentation:
```bash
# Terminal 1
docker compose up -d
./run-simulation.sh

# Browser
http://localhost:3000

# Show:
# 1. Alert rules (2 min)
# 2. Run flash sale (2 min)
# 3. Watch alert fire (2 min)
# 4. Show Loki logs (2 min)
# 5. Show PostgreSQL data (2 min)
```

### For a deep dive:
Run all scenarios and show:
- Prometheus metrics in Explore
- Loki log queries with filters
- PostgreSQL custom queries
- Alert notification configuration
- Dashboard creation

---

## 📞 Need Help?

1. Check **TROUBLESHOOTING.md**
2. Read **USAGE_GUIDE.md**
3. Review **ARCHITECTURE.md**
4. Check container logs: `docker compose logs -f <service-name>`

---

## 🚀 Next Steps

1. ✅ Run through all scenarios once
2. ✅ Explore Grafana's Explore view
3. ✅ Create a custom dashboard
4. ✅ Add a notification channel
5. ✅ Modify alert thresholds
6. ✅ Present to your team!

---

**You're all set! Happy demo-ing! 🎉**

Quick commands to copy-paste:
```bash
cd /home/tonypowa/Desktop/grafana/tonypowaGrafana/grafana/demo-alerting-stack
docker compose up -d
./run-simulation.sh
```

Then open: http://localhost:3000 (admin/admin)

