# Migration from Promtail to Grafana Alloy

## Summary

This demo has been updated to use **Grafana Alloy** instead of Promtail. Alloy is Grafana's modern, unified observability collector that replaces Promtail with better performance, cleaner configuration, and support for logs, metrics, and traces.

## What Changed

### 1. Docker Compose (`docker-compose.yml`)

**Before (Promtail):**
```yaml
promtail:
  image: grafana/promtail:latest
  container_name: shopfast-promtail
  volumes:
    - ./loki/promtail-config.yml:/etc/promtail/config.yml
    - /var/log:/var/log
    - ./logs:/app/logs
  command: -config.file=/etc/promtail/config.yml
```

**After (Alloy):**
```yaml
alloy:
  image: grafana/alloy:latest
  container_name: shopfast-alloy
  volumes:
    - ./alloy/config.alloy:/etc/alloy/config.alloy
    - /var/log:/var/log
    - ./logs:/app/logs
  command: run --server.http.listen-addr=0.0.0.0:12345 --storage.path=/var/lib/alloy/data /etc/alloy/config.alloy
  ports:
    - "12345:12345"  # Alloy UI
```

### 2. Configuration Files

**New Directory:** `alloy/`
- `config.alloy` - River configuration for log collection
- `README.md` - Documentation about the Alloy configuration

**Old File (no longer used):** `loki/promtail-config.yml`

### 3. Configuration Syntax

**Before (Promtail YAML):**
```yaml
scrape_configs:
  - job_name: shopfast-services
    static_configs:
      - targets:
          - localhost
        labels:
          job: shopfast-services
          __path__: /app/logs/*.log
    pipeline_stages:
      - regex:
          expression: '^(?P<timestamp>\S+)\s+(?P<level>\S+)\s+\[(?P<service>\S+)\]\s+(?P<message>.+)$'
```

**After (Alloy River):**
```river
local.file_match "shopfast_logs" {
  path_targets = [{
    __address__ = "localhost",
    __path__    = "/app/logs/*.log",
    job         = "shopfast-services",
  }]
}

loki.source.file "shopfast_services" {
  targets    = local.file_match.shopfast_logs.targets
  forward_to = [loki.process.parse_logs.receiver]
}
```

### 4. New Features

#### Alloy UI (http://localhost:12345)
- Visual component graph
- Real-time log flow monitoring
- Configuration debugging
- Component health status

## Benefits of Alloy

1. **Modern Architecture**: Built from the ground up with best practices
2. **Better Performance**: More efficient resource usage
3. **Cleaner Syntax**: River language is more readable than YAML
4. **Unified Collector**: One agent for logs, metrics, and traces
5. **Better Debugging**: Built-in UI for troubleshooting
6. **Active Development**: Future-proof as Grafana's recommended solution

## Migration Impact

✅ **No functional changes** - The demo works exactly the same way
✅ **Same log format** - Services don't need any changes
✅ **Same alerts** - All Grafana alerting rules work as before
✅ **Better UX** - Added Alloy UI for visibility

## How to Use

### Starting the Stack

```bash
docker compose up -d
```

Wait 30-60 seconds, then verify Alloy is running:

```bash
# Check Alloy logs
docker compose logs -f alloy

# Access Alloy UI
open http://localhost:12345
```

### Viewing Logs in Alloy UI

1. Open http://localhost:12345
2. Click on "Graph" to see the component pipeline
3. Click on any component to see its details
4. View logs flowing through the system in real-time

### Troubleshooting

If logs aren't appearing in Loki:

1. Check Alloy is running: `docker compose ps alloy`
2. View Alloy logs: `docker compose logs -f alloy`
3. Check the Alloy UI at http://localhost:12345
4. Verify log files exist: `ls -la logs/`

## Backward Compatibility

The old `loki/promtail-config.yml` file is still present but not used. You can safely delete it if desired:

```bash
rm loki/promtail-config.yml
```

## Learn More

- [Grafana Alloy Documentation](https://grafana.com/docs/alloy/latest/)
- [River Configuration Language](https://grafana.com/docs/alloy/latest/concepts/configuration-syntax/)
- [Migration Guide from Promtail](https://grafana.com/docs/alloy/latest/tasks/migrate/from-promtail/)

---

**Migration Date:** October 31, 2025  
**Alloy Version:** Latest (using `grafana/alloy:latest` Docker image)

