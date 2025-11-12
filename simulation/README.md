# ShopFast Traffic Simulator

This directory contains scripts to simulate realistic e-commerce traffic and trigger various alerting scenarios for demonstration purposes.

## Prerequisites

Install Python dependencies:

```bash
pip install -r requirements.txt
```

## Scenarios

### 1. Normal Traffic
Simulates typical e-commerce browsing and purchasing behavior:
```bash
python simulator.py normal --duration 60
```

### 2. Flash Sale
Simulates high traffic and rapid inventory depletion on a specific product:
```bash
python simulator.py flash-sale --product-id 1 --duration 30
```
This will trigger **Low Inventory** alerts.

### 3. Payment Failures
Simulates high payment failure rate:
```bash
python simulator.py payment-failures --duration 60
```
This will trigger **Payment Service Failures** alerts in Loki logs.

### 4. High CPU
Simulates CPU-intensive operations:
```bash
python simulator.py high-cpu --duration 30
```
This will trigger **High CPU Usage** alerts in Prometheus.

### 5. Security Breach
Simulates multiple failed login attempts:
```bash
python simulator.py security
```
This will trigger **Failed Login Attempts** alerts from PostgreSQL.

### 6. Low Inventory
Gradually depletes inventory for a specific product:
```bash
python simulator.py low-inventory --product-id 6
```
This will trigger both **Low Inventory** and **Critical Inventory** alerts from PostgreSQL.

### 7. All Scenarios
Runs all scenarios in sequence:
```bash
python simulator.py all
```

## Monitoring

You can monitor the services at:
- Prometheus: http://localhost:9090
- Loki: http://localhost:3100
- Grafana: http://localhost:3000 (admin/admin)
- API Service: http://localhost:8080/metrics
- Frontend: http://localhost:8081/metrics
- Payment: http://localhost:8082/metrics
- Inventory: http://localhost:8083/metrics

