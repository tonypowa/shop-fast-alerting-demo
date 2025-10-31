# Grafana Alloy Configuration

This directory contains the Grafana Alloy configuration for the ShopFast demo.

## What is Alloy?

Grafana Alloy is the modern, unified observability collector that replaces several older agents:
- **Promtail** (logs)
- **Grafana Agent** (metrics, logs, traces)
- **Agent Operator** (Kubernetes deployments)

## Configuration File

The `config.alloy` file uses the **River** configuration language, which is:
- More declarative and easier to read than YAML
- Supports dynamic configurations
- Has better type safety and validation
- Provides a visual component graph in the UI

## Components

The configuration consists of these components:

### 1. `local.file_match "shopfast_logs"`
Discovers log files matching the pattern `/app/logs/*.log`

### 2. `loki.source.file "shopfast_services"`
Tails the discovered log files and forwards content to the next component

### 3. `loki.process "parse_logs"`
Parses log lines to extract:
- **timestamp** - ISO 8601 timestamp
- **level** - Log level (INFO, ERROR, etc.)
- **service** - Service name (api-service, payment-service, etc.)
- **message** - The actual log message

These are converted to Loki labels for filtering and alerting.

### 4. `loki.write "loki_endpoint"`
Sends processed logs to Loki at `http://loki:3100`

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
- [Migration from Promtail](https://grafana.com/docs/alloy/latest/tasks/migrate/from-promtail/)

