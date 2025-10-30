# 🚀 ShopFast - Grafana Alerting Demo Stack

A complete, production-ready demo environment for showcasing Grafana's alerting capabilities with real-world e-commerce scenarios.

[![Docker](https://img.shields.io/badge/Docker-required-blue)](https://www.docker.com/)
[![Python](https://img.shields.io/badge/Python-containerized-green)](https://www.python.org/)
[![License](https://img.shields.io/badge/License-Demo-yellow)](LICENSE)

---

## 🎯 Quick Start (2 Minutes)

```bash
# 1. Clone the repository
git clone <your-repo-url>
cd shopfast-demo

# 2. Start all services
docker compose up -d

# 3. Access Grafana
# Open browser: http://localhost:3000
# Login: admin / admin

# 4. Run a simulation (Linux/Mac)
./run-simulation.sh

# Or on Windows
run-simulation.bat

# 5. Watch alerts fire in Grafana! 🎉
```

**That's it!** No Python installation, no dependency management, just Docker.

---

## ✨ What This Demo Provides

### 🎨 Complete Observability Stack
- **Grafana 12** - Visualization and alerting platform
- **Prometheus** - Metrics collection and storage
- **Loki** - Log aggregation
- **PostgreSQL** - Business data storage
- **4 Microservices** - Simulated e-commerce application

### 📊 7 Pre-Configured Alert Rules

| Alert | Type | Trigger Condition |
|-------|------|------------------|
| High CPU Usage | Prometheus | CPU > 70% for 1 min |
| High Error Rate | Prometheus | Errors > 10% for 2 min |
| Slow Response Time | Prometheus | p95 > 1s for 3 min |
| Payment Failures | Loki (Logs) | > 5 errors in 5 min |
| Low Inventory | PostgreSQL | Stock ≤ threshold |
| Critical Inventory | PostgreSQL | Stock ≤ 5 units |
| Failed Logins | PostgreSQL | ≥ 5 attempts in 5 min |

### 🎮 Interactive Control Panels

**Simulation Control** (`run-simulation.sh` / `run-simulation.bat`)
- Generate realistic traffic patterns
- Trigger specific alert scenarios
- Complete demo workflows

**Database Control** (`demo-control.sh` / `demo-control.bat`)
- Instant inventory manipulation
- Quick resets between demos
- Direct alert triggering

---

## 📋 Requirements

- **Docker Desktop** or **Docker Engine** + **Docker Compose**
- **4GB RAM** recommended
- **Ports available:** 3000, 8080-8083, 9090, 3100, 5432

**No Python installation required!** Everything runs in containers.

---

## 🏗️ Architecture

```
┌─────────────┐
│   Grafana   │ ← Dashboards & Alerts (Port 3000)
└──────┬──────┘
       │
       ├──────────┬──────────┬──────────┐
       │          │          │          │
┌──────▼─────┐ ┌─▼────┐ ┌───▼────┐ ┌──▼──────┐
│ Prometheus │ │ Loki │ │Postgres│ │Promtail │
│   :9090    │ │:3100 │ │ :5432  │ │         │
└──────┬─────┘ └──┬───┘ └───┬────┘ └─────────┘
       │          │         │
       └──────────┴─────────┴─────────────┐
                                           │
┌──────────────────────────────────────────▼──┐
│              Microservices                  │
│  ┌────────┐ ┌─────────┐ ┌─────────┐        │
│  │   API  │ │Frontend │ │ Payment │        │
│  │ :8080  │ │  :8081  │ │  :8082  │        │
│  └────────┘ └─────────┘ └─────────┘        │
│  ┌──────────┐                               │
│  │Inventory │                               │
│  │  :8083   │                               │
│  └──────────┘                               │
└─────────────────────────────────────────────┘
                    │
            ┌───────▼────────┐
            │   Simulator    │
            │ (Docker/Python)│
            └────────────────┘
```

---

## 🎬 Demo Scenarios

### Scenario 1: Flash Sale (Inventory Alert)
Simulates high traffic and rapid inventory depletion.

**Trigger:** `./run-simulation.sh` → Option 2  
**Alert fires:** Low Inventory Warning (PostgreSQL)  
**Watch in Grafana:** Alerting → Alert rules

### Scenario 2: Payment Failures (Log Alert)
Generates payment errors logged to Loki.

**Trigger:** `./run-simulation.sh` → Option 3  
**Alert fires:** Payment Service Failures (Loki)  
**Watch in Grafana:** Explore → Loki → `{service="payment"} |= "ERROR"`

### Scenario 3: Security Breach (Database Alert)
Creates multiple failed login attempts.

**Trigger:** `./run-simulation.sh` → Option 4  
**Alert fires:** Multiple Failed Login Attempts (PostgreSQL)  
**Watch in Grafana:** Alerting → Alert rules

### Scenario 4: High CPU (Metrics Alert)
Simulates CPU-intensive operations.

**Trigger:** `./run-simulation.sh` → Option 5  
**Alert fires:** High CPU Usage (Prometheus)  
**Watch in Grafana:** Explore → Prometheus

### Scenario 5: Complete Demo
Runs all scenarios in sequence (~5 minutes).

**Trigger:** `./run-simulation.sh` → Option 7

---

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| **[START_HERE.md](START_HERE.md)** | 2-minute quick reference |
| **[USAGE_GUIDE.md](USAGE_GUIDE.md)** | Complete usage instructions |
| **[CONTROL_SCRIPTS.md](CONTROL_SCRIPTS.md)** | Script comparison guide |
| **[DOCKER_SIMULATOR.md](DOCKER_SIMULATOR.md)** | Simulator technical details |
| **[ARCHITECTURE.md](ARCHITECTURE.md)** | System architecture |
| **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** | Common issues |
| **[QUICKSTART.md](QUICKSTART.md)** | 5-minute setup |

---

## 🖥️ Platform Support

### Linux ✅
```bash
docker compose up -d
./run-simulation.sh
./demo-control.sh
```

### macOS ✅
```bash
docker compose up -d
./run-simulation.sh
./demo-control.sh
```

### Windows ✅
```powershell
docker compose up -d
run-simulation.bat
demo-control.bat
```

Or use WSL/Git Bash for `.sh` scripts.

---

## 🎓 Use Cases

### Training & Education
- Teach Grafana alerting concepts
- Demonstrate multi-source alerts (metrics, logs, database)
- Show alert configuration best practices

### Sales Demonstrations
- Showcase Grafana capabilities
- Demonstrate real-world scenarios
- Interactive customer presentations

### Testing & Development
- Test alert rule modifications
- Verify notification channels
- Develop custom dashboards

### Conference Talks
- Live demos with pre-configured scenarios
- Quick reset between presentations
- Reliable, reproducible results

---

## 🛠️ Service URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| Grafana | http://localhost:3000 | admin / admin |
| Prometheus | http://localhost:9090 | - |
| Loki | http://localhost:3100 | - |
| API Service | http://localhost:8080 | - |
| Frontend | http://localhost:8081 | - |
| Payment | http://localhost:8082 | - |
| Inventory | http://localhost:8083 | - |

---

## 🎨 Customization

### Add Notification Channels
Edit `grafana/provisioning/alerting/notification-channels.yml`:

```yaml
notifiers:
  - name: Slack
    type: slack
    settings:
      url: <your-webhook-url>
```

### Modify Alert Thresholds
Edit `grafana/provisioning/alerting/alerting.yml` or modify in Grafana UI.

### Add Custom Metrics
Edit service code in `services/*/app.py` to expose new Prometheus metrics.

### Create Dashboards
Use Grafana UI to create dashboards, then export to `grafana/provisioning/dashboards/`.

---

## 🧹 Cleanup

```bash
# Stop services (preserves data)
docker compose down

# Stop and remove all data
docker compose down -v

# Remove simulator image
docker rmi shopfast-simulator
```

---

## 🐛 Troubleshooting

### Services won't start
```bash
docker compose down
docker compose up -d --force-recreate
```

### Simulator connection errors
```bash
# Check services are running
docker compose ps

# Check logs
docker compose logs -f api-service
```

### Alerts not firing
- Wait 30-60 seconds for evaluation
- Check alert "For" duration in Grafana
- Verify queries return data in Explore view

### Docker permission denied (Linux)
```bash
sudo usermod -aG docker $USER
newgrp docker
```

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for more details.

---

## 📖 How It Works

1. **Services start** via `docker-compose.yml`
2. **Grafana auto-provisions** data sources and alert rules
3. **Simulator generates traffic** via Python script in container
4. **Services emit** metrics (Prometheus), logs (Loki), and data (PostgreSQL)
5. **Grafana evaluates** alert rules every 30 seconds
6. **Alerts fire** when conditions are met
7. **Notifications sent** (if configured)

---

## 🤝 Contributing

This is a demo project. Feel free to:
- Fork and customize for your needs
- Add new scenarios
- Improve documentation
- Create additional dashboards

---

## 📝 License

This project is for educational and demonstration purposes.

---

## 🌟 Features

✅ **Zero Python Setup** - Simulator runs in Docker  
✅ **Cross-Platform** - Works on Linux, Mac, Windows  
✅ **Pre-Configured** - 7 alerts ready to demo  
✅ **Interactive Controls** - Easy-to-use CLI menus  
✅ **Multi-Source Alerts** - Prometheus, Loki, PostgreSQL  
✅ **Realistic Scenarios** - E-commerce use cases  
✅ **Quick Reset** - Database control panel  
✅ **Complete Documentation** - Multiple guides included  

---

## 🚀 Get Started Now!

```bash
git clone <your-repo-url>
cd shopfast-demo
docker compose up -d
./run-simulation.sh  # or run-simulation.bat on Windows
```

Then open http://localhost:3000 and watch the alerts fire! 🎉

---

## 📞 Support

- 📖 Read the documentation in this repository
- 🐛 Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- 💬 Open an issue for questions or problems

---

**Built with ❤️ for the Grafana community**
