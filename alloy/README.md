# Grafana Alloy Configuration

This directory contains the Grafana Alloy configuration for the ShopFast demo.

## What is Alloy?

Grafana Alloy is the modern, unified observability collector for metrics, logs, and traces.

## Configuration File

The `config.alloy` file uses the **River** configuration language, which is:
- More declarative and easier to read than YAML
- Supports dynamic configurations
- Has better type safety and validation
- Provides a visual component graph in the UI

## Unified Collection

This configuration demonstrates **Alloy as a unified collector** for all three pillars of observability:

```
Services
   ↓
Alloy (single collector)
   ├→ Prometheus (metrics)
   ├→ Loki (logs)
   └→ Tempo (traces)
```

## Components

The configuration consists of these components:

### Metrics Collection

#### 1. `prometheus.scrape "shopfast_metrics"`
Scrapes `/metrics` endpoints from all 4 services every 15 seconds. Targets are defined inline with job labels for each service.

#### 2. `prometheus.remote_write "prometheus"`
Sends collected metrics to Prometheus via remote write API with optimized batching (queue capacity: 10k samples, batch deadline: 5s).

### Logs Collection

#### 1. `local.file_match "shopfast_logs"`
Discovers log files matching the pattern `/app/logs/*.log`

#### 2. `loki.source.file "shopfast_services"`
Tails the discovered log files and forwards content to the next component

#### 3. `loki.process "parse_logs"`
Parses log lines to extract:
- **timestamp** - ISO 8601 timestamp
- **level** - Log level (INFO, ERROR, etc.)
- **service** - Service name (api-service, payment-service, etc.)
- **message** - The actual log message

These are converted to Loki labels for filtering and alerting.

#### 4. `loki.write "loki_endpoint"`
Sends processed logs to Loki at `http://loki:3100`

### Traces Collection

#### 1. `otelcol.receiver.otlp "default"`
Receives traces from instrumented services via OTLP on ports 4317 (gRPC) and 4318 (HTTP).

#### 2. `otelcol.processor.batch "default"`
Batches traces for efficiency (5s timeout, 100 spans per batch) before forwarding.

#### 3. `otelcol.exporter.otlp "tempo"`
Forwards traces to Tempo at `tempo:4317` via gRPC.

## Expected Log Format

Services should emit logs in this format:
```
2024-10-31T12:34:56Z INFO [api-service] User created order #123
```

## Alloy UI

Access the Alloy UI at **http://localhost:12345** to:
- View the component graph
- See real-time logs flowing through the pipeline
- Debug configuration issues
- Monitor component health

## Modifying the Configuration

1. Edit `config.alloy`
2. Restart the Alloy container:
   ```bash
   docker compose restart alloy
   ```
3. Check logs for errors:
   ```bash
   docker compose logs -f alloy
   ```

## Learn More

- [Alloy Documentation](https://grafana.com/docs/alloy/latest/)
- [River Language Reference](https://grafana.com/docs/alloy/latest/concepts/configuration-syntax/)

