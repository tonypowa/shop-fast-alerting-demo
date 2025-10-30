# Docker-Based Simulator Guide

No Python installation required! The simulator runs in a container.

## Quick Start

### Docker Permissions

Before running, ensure you have Docker permissions:

**Option 1: Add your user to docker group (recommended)**
```bash
sudo usermod -aG docker $USER
newgrp docker  # or logout/login
```

**Option 2: Run with sudo**
```bash
sudo ./run-simulation.sh normal --duration 60
```

### First Time Setup

The wrapper script will automatically build the Docker image on first run:

```bash
./run-simulation.sh
```

This builds the `shopfast-simulator` image with Python 3.11 and all dependencies.

## Running Simulations

### 🎯 Interactive Mode (Recommended)

Simply run without arguments for an interactive menu:

```bash
./run-simulation.sh
```

You'll get a nice menu:
```
╔════════════════════════════════════════════════════════════╗
║        🚀 ShopFast Simulation Control Center 🚀           ║
╚════════════════════════════════════════════════════════════╝

Choose a simulation scenario to trigger Grafana alerts:

1) 🟢 Normal Traffic (baseline - no alerts)
2) ⚡ Flash Sale (triggers LOW INVENTORY alert)
3) 💳 Payment Failures (triggers LOG-BASED alert)
4) 🔒 Security Breach (triggers DATABASE alert)
5) 🔥 High CPU Usage (triggers METRICS alert)
6) 📦 Low Inventory (gradual depletion)
7) 🎯 Run ALL Scenarios (complete demo)
8) 🔧 Rebuild Docker Image
9) ❌ Exit

Select scenario (1-9):
```

**Features:**
- Prompts for duration, product-id, and other parameters
- Shows helpful tips after each scenario
- Loops back to menu after each run
- Clean, user-friendly interface

### 💻 Command-Line Mode

Or run directly with arguments (great for scripting):

#### Normal Traffic (Baseline)
```bash
./run-simulation.sh normal --duration 60
```

#### Flash Sale (Triggers Low Inventory Alert)
```bash
./run-simulation.sh flash-sale --product-id 1 --duration 30
```

#### Payment Failures (Triggers Log-Based Alert)
```bash
./run-simulation.sh payment-failures --duration 60
```

#### Security Breach (Triggers Database Alert)
```bash
./run-simulation.sh security
```

#### High CPU (Triggers Metrics Alert)
```bash
./run-simulation.sh high-cpu --duration 30
```

#### Low Inventory (Gradual Depletion)
```bash
./run-simulation.sh low-inventory --product-id 6
```

#### Run All Scenarios
```bash
./run-simulation.sh all
```

## How It Works

The `run-simulation.sh` script:

1. **Builds the image** (first time only) from `simulation/Dockerfile`
2. **Connects to the demo network** (`demo-alerting-stack_monitoring`)
3. **Sets environment variables** for service URLs and database connection
4. **Runs the simulator** with your arguments
5. **Auto-removes the container** after completion

## Architecture

```
┌─────────────────────────────┐
│  ./run-simulation.sh        │
│  (Wrapper Script)           │
└────────────┬────────────────┘
             │
             ▼
┌─────────────────────────────┐
│  shopfast-simulator         │
│  (Docker Container)         │
│  - Python 3.11              │
│  - requests                 │
│  - psycopg2-binary          │
│  - simulator.py             │
└────────────┬────────────────┘
             │
             │ Network: monitoring
             │
    ┌────────┼─────────┐
    ▼        ▼         ▼
┌────────┐ ┌─────┐ ┌──────────┐
│  API   │ │Loki │ │PostgreSQL│
└────────┘ └─────┘ └──────────┘
```

## Rebuilding the Image

If you modify `simulator.py` or `requirements.txt`:

```bash
# Remove the old image
docker rmi shopfast-simulator

# Run again to rebuild
./run-simulation.sh --help
```

Or manually rebuild:
```bash
cd simulation
docker build -t shopfast-simulator .
```

## Benefits

✅ **No Python installation needed** on host machine  
✅ **Isolated environment** - no dependency conflicts  
✅ **Consistent across machines** - works on any OS with Docker  
✅ **Easy cleanup** - just remove the Docker image  
✅ **Network isolation** - runs in the same network as services  

## Troubleshooting

### Network Error
If you see connection errors, ensure the services are running:
```bash
docker compose ps
```

The simulator needs to connect to:
- `shopfast-api:8080`
- `shopfast-frontend:8081`
- `shopfast-payment:8082`
- `shopfast-inventory:8083`
- `shopfast-postgres:5432`

### Image Not Found
If the image doesn't auto-build:
```bash
cd simulation
docker build -t shopfast-simulator .
```

### Check Network Name
If connection fails, verify the network name:
```bash
docker network ls | grep demo-alerting-stack
```

Update `run-simulation.sh` line 27 if your network has a different name.

## Alternative: Manual Docker Run

If you prefer not to use the wrapper script:

```bash
# Build
docker build -t shopfast-simulator ./simulation

# Run
docker run --rm \
    --network demo-alerting-stack_monitoring \
    -e API_URL="http://shopfast-api:8080" \
    -e FRONTEND_URL="http://shopfast-frontend:8081" \
    -e PAYMENT_URL="http://shopfast-payment:8082" \
    -e INVENTORY_URL="http://shopfast-inventory:8083" \
    -e DB_HOST="shopfast-postgres" \
    shopfast-simulator normal --duration 60
```

## Still Want to Use Local Python?

The simulator still works with local Python installation:

```bash
cd simulation
pip install -r requirements.txt
python simulator.py normal --duration 60
```

Environment variables default to `localhost`, so it works both ways!

