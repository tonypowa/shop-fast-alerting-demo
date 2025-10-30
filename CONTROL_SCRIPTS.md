# Control Scripts Comparison

The demo has **two interactive control scripts** for managing demonstrations.

## Quick Overview

| Script | Purpose | Use Case |
|--------|---------|----------|
| `./run-simulation.sh` | **Run traffic simulations** | Trigger alerts by generating realistic traffic patterns |
| `./demo-control.sh` | **Direct database control** | Instantly change inventory levels during live demos |

---

## 1. run-simulation.sh - Simulation Control

### What it does
Runs containerized Python simulations that generate realistic e-commerce traffic patterns to trigger alerts.

### When to use
- **Before presentations** - to test alerts
- **During demos** - to show realistic scenarios
- **Training** - to demonstrate how alerts work

### How it works
```
./run-simulation.sh
  ↓
Runs Docker container with Python simulator
  ↓
Generates HTTP requests, logs, database activity
  ↓
Alerts fire in Grafana (after evaluation period)
```

### Interactive Menu
```bash
./run-simulation.sh
```

```
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

### Example Workflow
```bash
# Start simulation
./run-simulation.sh
# Select: 2 (Flash Sale)
# Enter Product ID: 1
# Enter Duration: 30

# Wait 30-60 seconds...
# → Alert fires in Grafana!
```

### Pros
✅ **Realistic** - simulates actual user behavior  
✅ **Complete** - generates metrics, logs, and database activity  
✅ **Educational** - shows how alerts work end-to-end  
✅ **Automated** - runs for specified duration  

### Cons
⚠️ **Time delay** - alerts take 30-60s to evaluate and fire  
⚠️ **Less predictable** - timing depends on simulation  

---

## 2. demo-control.sh - Database Control

### What it does
Directly modifies inventory levels in the PostgreSQL database for instant alert triggering.

### When to use
- **Live presentations** - when you need instant results
- **Testing** - to quickly verify alert thresholds
- **Recovery** - to reset state between demos

### How it works
```
./demo-control.sh
  ↓
Executes SQL directly on PostgreSQL
  ↓
Changes inventory levels immediately
  ↓
Alert fires on next evaluation (30s)
```

### Interactive Menu
```bash
./demo-control.sh
```

```
1) Reset to Default (50 units)
2) Set to High Stock (100 units)
3) Set Near Threshold (15 units)
4) Trigger Alert Now (8 units)          ← INSTANT ALERT!
5) View All Products
6) Reset All Products to Defaults
7) Clear All Orders
8) Exit
```

### Example Workflow
```bash
# Open control panel
./demo-control.sh
# Select: 4 (Trigger Alert Now)

# Wait 30 seconds for next evaluation...
# → Alert fires immediately!

# After demo, select: 1 (Reset to Default)
# → Alert clears
```

### Pros
✅ **Instant** - direct database manipulation  
✅ **Predictable** - exact control over values  
✅ **Quick** - perfect for live demos  
✅ **Reversible** - easy to reset state  

### Cons
⚠️ **Less realistic** - bypasses normal application flow  
⚠️ **Limited scope** - only affects inventory alerts  
⚠️ **Database-only** - doesn't generate metrics or logs  

---

## Side-by-Side Comparison

### Scenario: Trigger Low Inventory Alert

#### Using run-simulation.sh
```bash
./run-simulation.sh
# Select: 2 (Flash Sale)
# Product: 1
# Duration: 30

# What happens:
# - 30 seconds of simulated purchases
# - HTTP requests hit API service
# - Orders created in database
# - Inventory decreases gradually
# - Metrics collected by Prometheus
# - Logs sent to Loki
# - Alert fires after 30-60s
```

**Timeline:** ~1-2 minutes total  
**Realism:** High  
**Complexity:** Complete observability stack involved  

#### Using demo-control.sh
```bash
./demo-control.sh
# Select: 4 (Trigger Alert Now)

# What happens:
# - SQL UPDATE executed instantly
# - Inventory set to 8 units
# - Grafana queries database on next evaluation
# - Alert fires after 30s
```

**Timeline:** ~30 seconds total  
**Realism:** Low (but fast)  
**Complexity:** Simple database query  

---

## Which One to Use?

### For Learning & Testing
**Use `run-simulation.sh`**
- Shows the complete observability story
- Demonstrates realistic scenarios
- Tests all alert types (metrics, logs, database)

### For Live Presentations
**Use both together!**

**Start with `run-simulation.sh`:**
- Demonstrate normal traffic
- Show gradual degradation
- Explain the simulation

**Switch to `demo-control.sh`:**
- Quick resets between scenarios
- Instant alert triggering when time is short
- Recovery from failed demos

### For Quick Verification
**Use `demo-control.sh`**
- Fastest way to test alert thresholds
- Verify Grafana configuration
- Check notification channels

---

## Common Workflows

### Workflow 1: Complete Demo (15 minutes)
```bash
# 1. Reset everything
./demo-control.sh → Option 6 (Reset All)

# 2. Show normal operations
./run-simulation.sh → Option 1 (Normal Traffic, 30s)

# 3. Flash sale scenario
./run-simulation.sh → Option 2 (Flash Sale, 30s)
# Watch alert fire in Grafana

# 4. Payment failures
./run-simulation.sh → Option 3 (Payment Failures, 45s)
# Show Loki logs in Grafana

# 5. Security breach
./run-simulation.sh → Option 4 (Security)
# Show database alert

# 6. Clean up
./demo-control.sh → Option 6 (Reset All)
```

### Workflow 2: Quick Alert Test (2 minutes)
```bash
# 1. Trigger alert
./demo-control.sh → Option 4 (Trigger Alert Now)

# 2. Wait 30 seconds

# 3. Verify in Grafana → Alerting → Alert rules

# 4. Reset
./demo-control.sh → Option 1 (Reset to Default)
```

### Workflow 3: Comprehensive Testing (5 minutes)
```bash
# Run all simulation scenarios
./run-simulation.sh → Option 7 (Run ALL Scenarios)

# This runs:
# - Normal traffic
# - Inventory depletion
# - Flash sale
# - Payment failures
# - Security breach
# - High CPU

# Takes ~5 minutes, tests everything
```

---

## Technical Details

### run-simulation.sh
- **Language:** Bash wrapper + Python simulator
- **Runtime:** Docker container
- **Network:** Connects to `demo-alerting-stack_monitoring`
- **Dependencies:** Docker only (no Python on host)
- **Impact:** Generates traffic across all services

### demo-control.sh
- **Language:** Bash
- **Runtime:** Direct `psql` commands via Docker exec
- **Network:** Connects to PostgreSQL container
- **Dependencies:** Docker only
- **Impact:** Only modifies database

---

## Best Practices

### ✅ Do
- Use `run-simulation.sh` for realistic demos
- Use `demo-control.sh` for quick resets
- Test both scripts before presentations
- Keep Grafana open while running simulations
- Set alert evaluation to 30s for faster demos

### ❌ Don't
- Run both simultaneously (confusing results)
- Forget to reset between scenarios
- Expect instant results from simulations
- Skip the "normal traffic" baseline

---

## Troubleshooting

### run-simulation.sh issues
```bash
# Docker permission denied
sudo usermod -aG docker $USER
newgrp docker

# Image not found
./run-simulation.sh → Option 8 (Rebuild Image)

# Connection errors
docker compose ps  # Verify services running
```

### demo-control.sh issues
```bash
# Container not found
docker compose ps  # Check postgres running
docker ps | grep postgres

# Permission denied
# Run with sudo if needed
sudo ./demo-control.sh
```

---

## Summary

- **`run-simulation.sh`** = Realistic traffic generator (slow but complete)
- **`demo-control.sh`** = Instant database control (fast but limited)

Both are essential tools for effective Grafana alerting demonstrations! 🚀

