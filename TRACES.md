# Distributed Tracing Guide

Complete guide to using distributed tracing in the ShopFast demo.

---

## Overview

This demo includes **distributed tracing** powered by:
- **OpenTelemetry** - Industry-standard instrumentation
- **Grafana Alloy** - Unified collector for traces and logs
- **Grafana Tempo** - Distributed tracing backend
- **Grafana** - Visualization and correlation

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Instrumented Services                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │   API    │  │ Frontend │  │ Payment  │  │Inventory │   │
│  │  (OTel)  │  │  (OTel)  │  │  (OTel)  │  │  (OTel)  │   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘   │
└───────┼─────────────┼─────────────┼─────────────┼──────────┘
        │             │             │             │
        └─────────────┴─────────────┴─────────────┘
                      │
                OTLP (gRPC/HTTP)
                Ports 4317/4318
                      │
                      ▼
        ┌─────────────────────────┐
        │    Grafana Alloy        │
        │  (Trace Collector)      │
        │  - Receives OTLP        │
        │  - Batches traces       │
        │  - Forwards to Tempo    │
        └────────────┬────────────┘
                     │
                     ▼
        ┌─────────────────────────┐
        │    Grafana Tempo        │
        │  (Trace Storage)        │
        │  - Stores traces        │
        │  - Indexes for search   │
        │  - 48h retention        │
        └────────────┬────────────┘
                     │
                     ▼
        ┌─────────────────────────┐
        │       Grafana           │
        │  - Query traces         │
        │  - Visualize spans      │
        │  - Correlate w/ logs    │
        └─────────────────────────┘
```

---

## What Gets Traced?

### Automatic Instrumentation

Each service is automatically instrumented to trace:

#### Flask Application
- All HTTP requests (method, path, status code, duration)
- Request/response headers
- Error stack traces

#### Database Queries (API & Inventory services)
- SQL query text
- Connection info
- Query duration
- Row count

#### HTTP Client Requests
- Outgoing HTTP calls to other services
- Full request/response cycle
- Propagates trace context

### Example Trace Hierarchy

```
POST /api/orders (api-service) [320ms]
├─ SELECT products WHERE id=? (database) [45ms]
│  └─ db.statement: SELECT price, stock_level FROM products WHERE id = $1
├─ POST /api/payment/process (payment-service) [220ms]
│  ├─ http.method: POST
│  ├─ http.status_code: 200
│  └─ Processing delay [200ms]
└─ UPDATE products SET stock_level (database) [35ms]
   └─ db.statement: UPDATE products SET stock_level = stock_level - $1
```

---

## Using Traces in Grafana

### 1. Explore View

**Access:** Grafana → Explore → Select "Tempo"

#### Search by Service
```
service.name="api-service"
```

#### Search by Span Name
```
name="POST /api/orders"
```

#### TraceQL Queries

Find slow requests:
```traceql
{ duration > 500ms }
```

Find errors:
```traceql
{ span.http.status_code >= 500 }
```

Find specific operations:
```traceql
{ name =~ ".*orders.*" }
```

Complex query:
```traceql
{ 
  service.name="api-service" 
  && span.http.method="POST" 
  && duration > 200ms 
}
```

### 2. Service Graph

**Access:** Grafana → Explore → Tempo → Service Graph tab

Shows:
- Service dependencies
- Request rates between services
- Error rates
- Latency percentiles

### 3. Trace Correlation

#### From Trace to Logs
1. Open a trace in Grafana
2. Click any span
3. Click "Logs for this span"
4. See all logs during that span's timeframe

#### From Logs to Trace
1. In Explore, select Loki
2. Run a log query: `{service="api"}`
3. Click "Tempo" button next to log line
4. Opens the trace for that request

#### From Trace to Metrics
1. Open a trace
2. Click "View metrics" button
3. See Prometheus metrics at that timestamp

---

## Trace Attributes

### Common Attributes

Every span includes:
- `service.name` - Which service created the span
- `span.kind` - Type (SERVER, CLIENT, INTERNAL)
- `span.name` - Operation name
- `span.status` - OK, ERROR, or UNSET

### HTTP Spans

```
span.http.method = "POST"
span.http.target = "/api/orders"
span.http.status_code = 201
span.http.user_agent = "python-requests/2.31.0"
span.http.host = "api-service:8080"
```

### Database Spans

```
db.system = "postgresql"
db.name = "shopfast"
db.statement = "SELECT * FROM products WHERE id = $1"
db.operation = "SELECT"
```

---

## Demo Scenarios

### Scenario 1: Track Order Flow

1. Run flash sale simulation:
   ```bash
   ./run-simulation.sh
   # Select option 3 (Flash Sale)
   ```

2. In Grafana Explore → Tempo:
   ```traceql
   { service.name="api-service" && name="POST /api/orders" }
   ```

3. Click on a trace to see:
   - Total order processing time
   - Database query durations
   - Time spent in each service

### Scenario 2: Debug Payment Failures

1. Run payment failure simulation:
   ```bash
   ./run-simulation.sh
   # Select option 4 (Payment Failures)
   ```

2. Search for errors:
   ```traceql
   { span.http.status_code = 400 }
   ```

3. Click trace → See exact failure point in payment service

4. Click "Logs for this span" → See error logs

### Scenario 3: Find Slow Queries

1. Run normal traffic:
   ```bash
   ./run-simulation.sh
   # Select option 2 (Normal Traffic)
   ```

2. Find slow database operations:
   ```traceql
   { 
     db.system="postgresql" 
     && duration > 100ms 
   }
   ```

3. Identify slow queries and optimize

---

## Configuration Details

### Service Configuration

Each service sends traces to Alloy:

```python
# services/api/app.py
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter

otlp_exporter = OTLPSpanExporter(
    endpoint="http://alloy:4317",  # Alloy collector
    insecure=True
)
```

### Alloy Configuration

Alloy receives and forwards traces:

```hcl
// alloy/config.alloy

// Receive traces from services
otelcol.receiver.otlp "default" {
  grpc {
    endpoint = "0.0.0.0:4317"
  }
  http {
    endpoint = "0.0.0.0:4318"
  }
  output {
    traces = [otelcol.processor.batch.default.input]
  }
}

// Batch for efficiency
otelcol.processor.batch "default" {
  timeout = "5s"
  send_batch_size = 100
  output {
    traces = [otelcol.exporter.otlp.tempo.input]
  }
}

// Forward to Tempo
otelcol.exporter.otlp "tempo" {
  client {
    endpoint = "tempo:4317"
    tls {
      insecure = true
    }
  }
}
```

### Tempo Configuration

```yaml
# tempo/tempo.yml

server:
  http_listen_port: 3200

distributor:
  receivers:
    otlp:
      protocols:
        grpc:
        http:

storage:
  trace:
    backend: local
    local:
      path: /var/tempo/blocks

compactor:
  compaction:
    block_retention: 48h
```

---

## Troubleshooting

### No Traces Appearing

1. **Check services are instrumented:**
   ```bash
   docker logs shopfast-api
   # Should see: "Setting up OpenTelemetry..."
   ```

2. **Check Alloy is receiving:**
   - Open http://localhost:12345
   - Look for `otelcol.receiver.otlp` component
   - Should show received spans

3. **Check Tempo is running:**
   ```bash
   docker logs shopfast-tempo
   ```

4. **Verify connectivity:**
   ```bash
   docker exec shopfast-api curl -v http://alloy:4317
   ```

### Traces Not Correlating with Logs

Ensure:
1. Services are generating logs
2. Alloy is collecting logs to Loki
3. Time ranges overlap in Grafana queries
4. Service names match between traces and logs

### Slow Trace Queries

- Reduce time range (try last 15 minutes)
- Use more specific filters
- Tempo indexes on service.name and span.name

---

## Advanced: Custom Spans

Want to trace specific business logic?

```python
from opentelemetry import trace

tracer = trace.get_tracer(__name__)

@app.route('/api/orders', methods=['POST'])
def create_order():
    # Auto-traced by Flask instrumentation
    
    # Add custom span for business logic
    with tracer.start_as_current_span("validate_order") as span:
        span.set_attribute("order.product_id", product_id)
        span.set_attribute("order.quantity", quantity)
        
        # Your validation logic
        validate_inventory(product_id, quantity)
    
    with tracer.start_as_current_span("apply_discount"):
        discount = calculate_discount(product_id)
        span.set_attribute("discount.amount", discount)
```

This creates:
```
POST /api/orders [320ms]
├─ validate_order [45ms]
│  ├─ order.product_id: 1
│  └─ order.quantity: 2
└─ apply_discount [20ms]
   └─ discount.amount: 10.50
```

---

## Best Practices

### DO:
✅ Use specific TraceQL queries (faster)  
✅ Filter by time range (last hour, not last week)  
✅ Use service.name for quick filtering  
✅ Add meaningful span attributes  
✅ Correlate with logs for full context  

### DON'T:
❌ Query all traces without filters (slow)  
❌ Use very large time ranges  
❌ Ignore span attributes (they're searchable!)  
❌ Forget to check Alloy UI for debugging  

---

## Learn More

- [OpenTelemetry Python Docs](https://opentelemetry.io/docs/instrumentation/python/)
- [Grafana Tempo Docs](https://grafana.com/docs/tempo/latest/)
- [TraceQL Guide](https://grafana.com/docs/tempo/latest/traceql/)
- [Grafana Alloy OTLP](https://grafana.com/docs/alloy/latest/reference/components/otelcol.receiver.otlp/)

---

**Built with OpenTelemetry + Grafana Tempo for complete observability** 🔍


