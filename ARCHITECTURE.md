# Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                           Grafana (Port 3000)                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │  Dashboards  │  │    Alerts    │  │ Notifications│              │
│  └──────────────┘  └──────────────┘  └──────────────┘              │
└────────┬────────────────┬────────────────┬───────────────────────────┘
         │                │                │
         │                │                │
    ┌────▼────┐      ┌────▼────┐     ┌────▼────────┐
    │Prometheus│      │  Loki   │     │  PostgreSQL │
    │  :9090   │      │  :3100  │     │    :5432    │
    └────┬────┘      └────┬────┘     └────┬────────┘
         │                │                │
         │ Scrapes        │ Collects       │ Direct
         │ /metrics       │ Logs           │ Queries
         │                │                │
    ┌────┴────────────────┴────────────────┴─────┐
    │                                             │
    │      ┌──────────┐         ┌──────────┐     │
    │      │Promtail  │────────▶│   Logs   │     │
    │      │          │  Tails  │ Directory│     │
    │      └──────────┘         └─────┬────┘     │
    │                                 │          │
    │  ┌──────────────────────────────┼──────────┼──┐
    │  │        Microservices         │          │  │
    │  │                              │          │  │
    │  │  ┌──────────────┐           │          │  │
    │  │  │ API Service  │◀──────────┴──────┐   │  │
    │  │  │   :8080      │                  │   │  │
    │  │  │ /metrics     │                  │   │  │
    │  │  │ logs/api.log │                  │   │  │
    │  │  └──────┬───────┘                  │   │  │
    │  │         │                          │   │  │
    │  │  ┌──────▼─────────┐                │   │  │
    │  │  │Frontend Service│                │   │  │
    │  │  │     :8081      │                │   │  │
    │  │  │   /metrics     │                │   │  │
    │  │  │logs/frontend.log               │   │  │
    │  │  └────────────────┘                │   │  │
    │  │                                    │   │  │
    │  │  ┌─────────────────┐               │   │  │
    │  │  │ Payment Service │               │   │  │
    │  │  │     :8082       │               │   │  │
    │  │  │   /metrics      │               │   │  │
    │  │  │logs/payment.log │               │   │  │
    │  │  └─────────────────┘               │   │  │
    │  │                                    │   │  │
    │  │  ┌──────────────────┐              │   │  │
    │  │  │Inventory Service │              │   │  │
    │  │  │     :8083        │              │   │  │
    │  │  │   /metrics       │              │   │  │
    │  │  │logs/inventory.log│              │   │  │
    │  │  └──────────────────┘              │   │  │
    │  │                                    │   │  │
    │  └────────────────────────────────────┼───┼──┘
    │                                       │   │
    └───────────────────────────────────────┼───┼────
                                            │   │
                                    ┌───────▼───▼────┐
                                    │   PostgreSQL   │
                                    │   Database     │
                                    │  - Products    │
                                    │  - Orders      │
                                    │  - Customers   │
                                    │  - Login Logs  │
                                    └────────────────┘
```

## Data Flow

### Metrics Flow (Prometheus)
```
Service → /metrics endpoint → Prometheus scrape → Prometheus TSDB → Grafana Query → Alert Evaluation
```

### Logs Flow (Loki)
```
Service → Write log file → Promtail tail → Loki ingestion → Loki storage → Grafana Query → Alert Evaluation
```

### Database Flow (PostgreSQL)
```
Service → SQL INSERT/UPDATE → PostgreSQL tables → Grafana Query → Alert Evaluation
```

## Alert Evaluation Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Grafana Alerting                         │
│                                                             │
│  ┌────────────────────────────────────────────────────┐    │
│  │  Every 30 seconds (evaluation interval)            │    │
│  │                                                     │    │
│  │  For each alert rule:                              │    │
│  │    1. Execute query against data source            │    │
│  │    2. Evaluate condition                           │    │
│  │    3. Check "For" duration                         │    │
│  │    4. Update alert state:                          │    │
│  │       - Normal (green)                             │    │
│  │       - Pending (orange) - condition met, waiting  │    │
│  │       - Firing (red) - condition met + duration    │    │
│  │    5. If firing → Send notifications               │    │
│  └────────────────────────────────────────────────────┘    │
│                              │                              │
└──────────────────────────────┼──────────────────────────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │ Notification Channels│
                    │  - Email             │
                    │  - Slack             │
                    │  - PagerDuty         │
                    │  - Webhook           │
                    │  - etc.              │
                    └──────────────────────┘
```

## Service Responsibilities

### API Service
**Purpose**: Core business logic

**Responsibilities:**
- Product catalog queries
- Order creation and processing
- Stock level updates
- Database transactions

**Metrics Exposed:**
- `http_requests_total{method, endpoint, status}` - Request counter
- `http_request_duration_seconds{method, endpoint}` - Latency histogram
- `orders_total{status}` - Order counter

**Logs Generated:**
- Order created/failed
- Product queries
- Database errors
- Transaction logs

### Frontend Service
**Purpose**: User-facing interface

**Responsibilities:**
- Page rendering simulation
- User interaction tracking
- Session management simulation
- Error simulation for demos

**Metrics Exposed:**
- `http_requests_total{method, endpoint, status}` - Request counter
- `http_request_duration_seconds{method, endpoint}` - Latency histogram
- `page_views_total{page}` - Page view counter

**Logs Generated:**
- Page access logs
- Session timeouts
- Frontend errors

### Payment Service
**Purpose**: Payment processing

**Responsibilities:**
- Payment authorization simulation
- Failure scenario simulation
- Refund processing
- Transaction logging

**Metrics Exposed:**
- `http_requests_total{method, endpoint, status}` - Request counter
- `http_request_duration_seconds{method, endpoint}` - Latency histogram
- `payments_total{status, method}` - Payment counter
- `payment_amount_total` - Revenue counter

**Logs Generated:**
- Payment success/failure
- Payment method used
- Transaction IDs
- Error reasons

### Inventory Service
**Purpose**: Stock monitoring

**Responsibilities:**
- Real-time stock level exposure
- Low stock detection
- Inventory alerts generation
- Stock statistics

**Metrics Exposed:**
- `http_requests_total{method, endpoint, status}` - Request counter
- `http_request_duration_seconds{method, endpoint}` - Latency histogram
- `inventory_stock_level{product_id, product_name}` - Stock gauge
- `inventory_low_stock_products` - Low stock count gauge

**Logs Generated:**
- Stock level changes
- Low stock warnings
- Critical stock alerts
- Inventory queries

## Database Schema

```sql
┌─────────────────────┐
│     products        │
├─────────────────────┤
│ id (PK)             │
│ name                │
│ description         │
│ price               │
│ stock_level         │◀────────┐
│ low_stock_threshold │         │
│ last_updated        │         │
└─────────────────────┘         │
         △                      │
         │                      │
         │ FK                   │
         │                      │
┌────────┴────────────┐         │
│      orders         │         │
├─────────────────────┤         │
│ id (PK)             │         │
│ product_id (FK)     │─────────┘
│ quantity            │
│ total_amount        │
│ order_status        │
│ order_time          │
└─────────────────────┘

┌─────────────────────┐
│    customers        │
├─────────────────────┤
│ id (PK)             │
│ email               │
│ name                │
│ created_at          │
└─────────────────────┘

┌─────────────────────┐
│  login_attempts     │
├─────────────────────┤
│ id (PK)             │
│ email               │
│ ip_address          │
│ success             │
│ attempt_time        │
└─────────────────────┘

Views:
- low_stock_products: Products below threshold
- order_stats_hourly: Aggregated order statistics
```

## Alert Rule Architecture

### Structure
```yaml
Alert Rule:
  - uid: Unique identifier
  - title: Human-readable name
  - condition: Query expression
  - data: Data source and query
  - noDataState: How to handle no data
  - execErrState: How to handle query errors
  - for: Duration before firing
  - annotations: Description, runbook, etc.
  - labels: For routing and grouping
```

### Example Alert Flow

**Low Inventory Alert:**

1. **Every 30s**: Grafana executes:
   ```sql
   SELECT name, stock_level 
   FROM products 
   WHERE stock_level <= low_stock_threshold
   ```

2. **Condition**: If query returns any rows

3. **State Machine**:
   ```
   Normal → [Query returns rows] → Pending
   Pending → [Wait 30s] → Firing
   Firing → [Query returns no rows] → Normal
   ```

4. **When Firing**:
   - Alert appears in Grafana UI (red)
   - Annotations show which products
   - Notifications sent (if configured)
   - Alert history recorded

## Network Architecture

```
┌─────────────────────────────────────────────────────┐
│         Docker Network: monitoring                  │
│         Subnet: 172.18.0.0/16                       │
│                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐         │
│  │ Grafana  │  │Prometheus│  │   Loki   │         │
│  │172.18.0.2│  │172.18.0.3│  │172.18.0.4│         │
│  └──────────┘  └──────────┘  └──────────┘         │
│                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐         │
│  │PostgreSQL│  │Promtail  │  │   API    │         │
│  │172.18.0.5│  │172.18.0.6│  │172.18.0.7│         │
│  └──────────┘  └──────────┘  └──────────┘         │
│                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐         │
│  │ Frontend │  │ Payment  │  │Inventory │         │
│  │172.18.0.8│  │172.18.0.9│  │172.18.0.10        │
│  └──────────┘  └──────────┘  └──────────┘         │
│                                                     │
└─────────────────────────────────────────────────────┘
         │
         │ Port Mappings
         ▼
┌─────────────────────────────────────────────────────┐
│              Host Machine (localhost)               │
│                                                     │
│  Port 3000  → Grafana                              │
│  Port 9090  → Prometheus                           │
│  Port 3100  → Loki                                 │
│  Port 5432  → PostgreSQL                           │
│  Port 8080  → API Service                          │
│  Port 8081  → Frontend Service                     │
│  Port 8082  → Payment Service                      │
│  Port 8083  → Inventory Service                    │
└─────────────────────────────────────────────────────┘
```

## Security Considerations

### For Demo/Development
- ✅ Default credentials (admin/admin)
- ✅ No TLS/SSL (plain HTTP)
- ✅ Open ports
- ✅ Simple password for database

### For Production (DO NOT USE AS-IS)
- ❌ Need strong passwords
- ❌ Need TLS certificates
- ❌ Need network policies
- ❌ Need authentication tokens
- ❌ Need secret management
- ❌ Need proper access controls

## Scalability Considerations

### Current Design (Demo)
- Single instance of each service
- Local Docker network
- File-based storage for logs
- Single database instance

### Production Considerations
- Multiple service replicas
- Load balancers
- Distributed storage (S3, etc.)
- Database clustering
- Service mesh
- Kubernetes orchestration

## Monitoring the Monitor

To see what's happening with the observability stack itself:

```bash
# Prometheus metrics about Prometheus
http://localhost:9090/metrics

# Loki metrics
http://localhost:3100/metrics

# Grafana metrics
http://localhost:3000/metrics

# Check health
curl http://localhost:9090/-/healthy
curl http://localhost:3100/ready
curl http://localhost:3000/api/health
```

## Performance Tuning

### For Demo
- Keep default settings
- Sufficient for demo workloads

### For Heavy Load
- Increase Prometheus retention
- Adjust Loki retention policies
- Tune PostgreSQL connections
- Scale service replicas
- Add Redis cache
- Use external storage

---

This architecture is optimized for demonstration and educational purposes, showcasing Grafana's alerting capabilities across multiple data sources in a realistic e-commerce scenario.

