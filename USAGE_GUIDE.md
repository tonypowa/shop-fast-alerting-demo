# ShopFast Demo - Complete Usage Guide

## What We Built

You now have two ways to run simulations:

### ✅ Option 1: Docker-Based (No Python Needed)
Uses containerized Python - recommended for clean environments.

### ✅ Option 2: Local Python
Traditional approach if you have Python installed.

---

## Getting Started

### 1. Fix Docker Permissions (One-Time)

```bash
# Add yourself to docker group
sudo usermod -aG docker $USER

# Activate group (or logout/login)
newgrp docker

# Verify
docker ps
```

### 2. Start the Demo Environment

```bash
cd /home/tonypowa/Desktop/grafana/tonypowaGrafana/grafana/demo-alerting-stack
docker compose up -d
```

Wait 30-60 seconds for services to initialize.

### 3. Access Grafana

Open browser: http://localhost:3000
- Username: `admin`
- Password: `admin`

Go to **Alerting → Alert rules** to see 7 pre-configured alerts.

---

## Running Simulations

### Docker Method (Recommended)

#### Interactive Mode (Easy!)

Just run the script without arguments for a menu:

```bash
./run-simulation.sh
```

You'll see:
```
╔════════════════════════════════════════════════════════════╗
║        🚀 ShopFast Simulation Control Center 🚀           ║
╚════════════════════════════════════════════════════════════╝

1) 🟢 Normal Traffic (baseline - no alerts)
2) ⚡ Flash Sale (triggers LOW INVENTORY alert)
3) 💳 Payment Failures (triggers LOG-BASED alert)
4) 🔒 Security Breach (triggers DATABASE alert)
5) 🔥 High CPU Usage (triggers METRICS alert)
6) 📦 Low Inventory (gradual depletion)
7) 🎯 Run ALL Scenarios (complete demo)
8) 🔧 Rebuild Docker Image
9) ❌ Exit
```

The script will prompt you for parameters (duration, product-id, etc.)

#### Command-Line Mode (Advanced)

Or run directly with arguments:

```bash
# Normal traffic
./run-simulation.sh normal --duration 60

# Flash sale (triggers low inventory alert)
./run-simulation.sh flash-sale --product-id 1 --duration 30

# Payment failures (triggers log-based alert)
./run-simulation.sh payment-failures --duration 60

# Security breach (triggers database alert)
./run-simulation.sh security

# High CPU (triggers metrics alert)
./run-simulation.sh high-cpu --duration 30

# Low inventory (gradual depletion)
./run-simulation.sh low-inventory --product-id 6

# Run all scenarios
./run-simulation.sh all
```

### Local Python Method (Alternative)

```bash
cd simulation
pip install -r requirements.txt

# Run scenarios
python simulator.py normal --duration 60
python simulator.py flash-sale --product-id 1 --duration 30
# ... etc
```

---

## Demo Control Panel

For live demos, use the control panel to manually trigger alerts:

```bash
./demo-control.sh
```

**Interactive Menu:**
1. Reset to Default (50 units) - Safe state
2. Set to High Stock (100 units) - Plenty of inventory
3. Set Near Threshold (15 units) - Close to alerting
4. **Trigger Alert Now (8 units)** - ⚡ Instant alert!
5. View All Products
6. Reset All Products to Defaults
7. Clear All Orders
8. Exit

---

## Demo Presentation Flow

### Step 1: Introduction (2 minutes)
```bash
# Show services running
docker compose ps

# Access Grafana
http://localhost:3000
```

Show the 7 alert rules in Grafana UI.

### Step 2: Normal Operations (1 minute)
```bash
./run-simulation.sh normal --duration 30
```

Show healthy metrics - no alerts firing.

### Step 3: Flash Sale Alert (2 minutes)
```bash
./run-simulation.sh flash-sale --product-id 1 --duration 30
```

Watch in Grafana:
- **Alerting → Alert rules**
- Find "Low Inventory Warning"
- Alert fires when stock ≤ 10 units
- Show PostgreSQL query behind the alert

### Step 4: Payment Failures (2 minutes)
```bash
./run-simulation.sh payment-failures --duration 45
```

Watch in Grafana:
- Alert: "Payment Service Failures"
- Go to **Explore** → Select Loki
- Query: `{service="payment"} |= "ERROR"`
- Show log-based alerting

### Step 5: Security Incident (1 minute)
```bash
./run-simulation.sh security
```

Watch in Grafana:
- Alert: "Multiple Failed Login Attempts"
- Go to **Explore** → Select PostgreSQL
- Query: `SELECT * FROM login_attempts WHERE success = false`
- Show database alerting

### Step 6: Performance Issues (1 minute)
```bash
./run-simulation.sh high-cpu --duration 30
```

Watch in Grafana:
- Alert: "High CPU Usage"
- Go to **Explore** → Select Prometheus
- Query: `rate(process_cpu_seconds_total[1m]) * 100`
- Show metrics-based alerting

---

## Key Files

| File | Purpose |
|------|---------|
| `start-demo.sh` | Quick start script |
| `demo-control.sh` | Live demo control panel |
| `run-simulation.sh` | Docker-based simulator wrapper |
| `simulation/Dockerfile` | Containerized Python environment |
| `simulation/simulator.py` | Traffic simulator |
| `docker-compose.yml` | Service orchestration |

---

## Alert Types Demonstrated

### 1. Metrics-Based (Prometheus)
- ✅ High CPU Usage
- ✅ High Error Rate
- ✅ Slow Response Time

### 2. Log-Based (Loki)
- ✅ Payment Service Failures

### 3. Database-Based (PostgreSQL)
- ✅ Low Inventory Warning
- ✅ Critical Inventory Alert
- ✅ Multiple Failed Login Attempts

---

## Architecture Overview

```
┌─────────────┐
│   Grafana   │ ← Dashboards & Alerts (Port 3000)
└──────┬──────┘
       │
       ├──────────┬──────────┬──────────┐
       │          │          │          │
┌──────▼─────┐ ┌─▼────┐ ┌───▼────┐ ┌──▼──────┐
│ Prometheus │ │ Loki │ │Postgres│ │Promtail │
│  (9090)    │ │(3100)│ │ (5432) │ │         │
└──────┬─────┘ └──┬───┘ └───┬────┘ └─────────┘
       │          │         │
       └──────────┴─────────┴─────────────┐
                                           │
┌──────────────────────────────────────────▼──┐
│              Microservices                  │
│  ┌────────┐ ┌─────────┐ ┌─────────┐        │
│  │   API  │ │Frontend │ │ Payment │        │
│  │ (8080) │ │ (8081)  │ │ (8082)  │        │
│  └────────┘ └─────────┘ └─────────┘        │
│  ┌──────────┐                               │
│  │Inventory │                               │
│  │  (8083)  │                               │
│  └──────────┘                               │
└─────────────────────────────────────────────┘
                    │
            ┌───────▼────────┐
            │   Simulator    │
            │ (Docker/Python)│
            └────────────────┘
```

---

## Troubleshooting

### Services won't start
```bash
docker compose down
docker compose up -d --force-recreate
```

### Simulator connection errors
```bash
# Check services are running
docker compose ps

# Check network
docker network ls | grep demo-alerting-stack

# View service logs
docker compose logs -f api-service
```

### Permission denied
```bash
# Add to docker group
sudo usermod -aG docker $USER
newgrp docker
```

### Alerts not firing
- Check alert evaluation interval (default: 30s)
- Check "For" duration in alert rule
- Verify query returns data in **Explore**

---

## Cleanup

### Stop services
```bash
docker compose down
```

### Remove all data
```bash
docker compose down -v
```

### Remove simulator image
```bash
docker rmi shopfast-simulator
```

---

## Quick Reference

```bash
# Start everything
docker compose up -d

# Run simulation (Docker)
./run-simulation.sh flash-sale --product-id 1 --duration 30

# Manual control
./demo-control.sh

# View logs
docker compose logs -f

# Stop everything
docker compose down
```

---

## Next Steps

1. ✅ Explore Grafana dashboards
2. ✅ Modify alert thresholds in Grafana UI
3. ✅ Add notification channels (Slack, PagerDuty)
4. ✅ Create custom dashboards
5. ✅ Try different simulation scenarios

---

## Additional Documentation

- `README.md` - Full project documentation
- `QUICKSTART.md` - Quick start guide
- `DOCKER_SIMULATOR.md` - Docker simulator details
- `ARCHITECTURE.md` - Detailed architecture
- `TROUBLESHOOTING.md` - Common issues

---

**Happy Demo-ing! 🚀**

