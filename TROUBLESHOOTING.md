# Troubleshooting Guide

Common issues and their solutions for the ShopFast demo environment.

## Services Won't Start

### Issue: Docker Compose fails to start

**Symptoms:**
```
Error: Cannot start service xyz
```

**Solutions:**

1. Check Docker is running:
```bash
docker ps
```

2. Check port conflicts:
```bash
# Windows
netstat -ano | findstr "3000 9090 5432"

# Linux/Mac
lsof -i :3000,9090,5432
```

3. Force recreate:
```bash
docker-compose down
docker-compose up -d --force-recreate
```

4. Check Docker resources:
- Docker Desktop → Settings → Resources
- Ensure at least 4GB RAM allocated

### Issue: Services start but are unhealthy

**Check service logs:**
```bash
docker-compose logs postgres
docker-compose logs api-service
docker-compose logs grafana
```

**Common cause:** PostgreSQL not ready yet
**Solution:** Wait 60 seconds, then restart dependent services:
```bash
docker-compose restart api-service inventory-service
```

## Database Issues

### Issue: "Connection refused" to PostgreSQL

**Cause:** Database not fully initialized

**Solution:**
```bash
# Check if PostgreSQL is ready
docker-compose exec postgres pg_isready

# If not ready, wait and check logs
docker-compose logs postgres

# Should see: "database system is ready to accept connections"
```

### Issue: "Permission denied" or "role does not exist"

**Solution:** Recreate the database:
```bash
docker-compose down -v  # WARNING: Deletes all data
docker-compose up -d
```

### Issue: No data in database

**Check if init script ran:**
```bash
docker-compose exec postgres psql -U shopfast -d shopfast -c "SELECT COUNT(*) FROM products;"
```

Should return 10 products. If not:
```bash
docker-compose down -v
docker-compose up -d
```

## Grafana Issues

### Issue: Can't access Grafana at localhost:3000

**Solutions:**

1. Check Grafana is running:
```bash
docker-compose ps grafana
```

2. Check logs:
```bash
docker-compose logs grafana
```

3. Try explicit address:
```
http://127.0.0.1:3000
```

4. Clear browser cache and try incognito mode

### Issue: Data sources not provisioned

**Symptoms:** Data sources missing or showing errors

**Solutions:**

1. Check provisioning files exist:
```bash
ls -la grafana/provisioning/datasources/
```

2. Check Grafana logs:
```bash
docker-compose logs grafana | grep -i datasource
```

3. Manually test connections:
   - Grafana → Configuration → Data Sources
   - Click each data source
   - Click "Save & Test"

4. Recreate Grafana:
```bash
docker-compose stop grafana
docker volume rm demo-alerting-stack_grafana-data
docker-compose up -d grafana
```

### Issue: Alerts not provisioned

**Check alert rules:**
```bash
# In Grafana UI
Alerting → Alert rules

# Should see 7 rules
```

**If missing:**
```bash
# Check provisioning file
cat grafana/provisioning/alerting/alerting.yml

# Check Grafana logs
docker-compose logs grafana | grep -i alert
```

### Issue: Alerts not firing

**Troubleshooting steps:**

1. **Check alert evaluation:**
   - Go to Alert rule
   - Click "Evaluate now"
   - See if query returns data

2. **Check data source:**
   - Go to Explore
   - Run the alert query manually
   - Verify it returns expected results

3. **Check evaluation interval:**
   - Default is 30 seconds
   - May need to wait longer

4. **Check "For" duration:**
   - Alert might need condition to persist
   - Example: "For 1m" means wait 1 minute before firing

5. **Check alert state:**
   - Normal: Green (not firing)
   - Pending: Orange (condition met, waiting for "For" duration)
   - Firing: Red (alert active)

## Prometheus Issues

### Issue: Prometheus not scraping targets

**Check targets:**
- Go to http://localhost:9090/targets
- All should be "UP"

**If DOWN:**

1. Check service is running:
```bash
docker-compose ps api-service
```

2. Check service exposes /metrics:
```bash
curl http://localhost:8080/metrics
```

3. Check Prometheus config:
```bash
cat prometheus/prometheus.yml
```

4. Check logs:
```bash
docker-compose logs prometheus
```

### Issue: No metrics data

**Solutions:**

1. Check if services are running:
```bash
docker-compose ps
```

2. Test metrics endpoints:
```bash
curl http://localhost:8080/metrics
curl http://localhost:8081/metrics
```

3. Restart Prometheus:
```bash
docker-compose restart prometheus
```

## Loki Issues

### Issue: No logs appearing

**Troubleshooting:**

1. **Check log files exist:**
```bash
ls -la logs/
```

Should see: api.log, frontend.log, payment.log, inventory.log

2. **Check Promtail is running:**
```bash
docker-compose ps promtail
docker-compose logs promtail
```

3. **Check Promtail config:**
```bash
cat loki/promtail-config.yml
```

4. **Manually check logs:**
```bash
tail -f logs/*.log
```

5. **Test Loki:**
```bash
# In Grafana Explore with Loki
{service=~".*"}
```

### Issue: Promtail errors

**Common error:** "permission denied" reading log files

**Solution:**
```bash
# Make logs readable
chmod -R 755 logs/
```

## Simulation Issues

### Issue: "Connection refused" when running simulator

**Cause:** Services not accessible from host

**Solutions:**

1. Check services are running:
```bash
docker-compose ps
```

2. Test connectivity:
```bash
curl http://localhost:8080/health
curl http://localhost:8081/health
```

3. Check if ports are bound:
```bash
# Windows
netstat -ano | findstr "8080"

# Linux/Mac
lsof -i :8080
```

### Issue: Python dependencies won't install

**Solutions:**

1. Use virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # Linux/Mac
venv\Scripts\activate     # Windows
pip install -r simulation/requirements.txt
```

2. Upgrade pip:
```bash
pip install --upgrade pip
```

3. Use specific Python version:
```bash
python3.11 -m pip install -r simulation/requirements.txt
```

### Issue: Simulator runs but nothing happens

**Check:**

1. Services are healthy:
```bash
curl http://localhost:8080/health
```

2. Database is accessible:
```bash
docker-compose exec postgres psql -U shopfast -d shopfast -c "SELECT 1;"
```

3. Run with debug logging:
```bash
# Edit simulator.py, change logging level:
logging.basicConfig(level=logging.DEBUG)
```

## Performance Issues

### Issue: Services are slow

**Solutions:**

1. Check Docker resource allocation:
   - Docker Desktop → Settings → Resources
   - Increase RAM to 6-8GB if available

2. Check CPU usage:
```bash
docker stats
```

3. Reduce scrape intervals:
   - Edit prometheus/prometheus.yml
   - Change scrape_interval to 30s or 60s

4. Reduce simulation rate:
```bash
python simulator.py normal --duration 60 --requests-per-second 1
```

## Network Issues

### Issue: Services can't communicate

**Check Docker network:**
```bash
docker network ls
docker network inspect demo-alerting-stack_monitoring
```

**Solutions:**

1. Recreate network:
```bash
docker-compose down
docker network rm demo-alerting-stack_monitoring
docker-compose up -d
```

2. Check service names in docker-compose.yml match connection strings

## Complete Reset

If all else fails, nuclear option:

```bash
# Stop everything
docker-compose down -v

# Remove all images
docker-compose down --rmi all

# Clean Docker system (WARNING: affects all containers)
docker system prune -a

# Start fresh
docker-compose up -d --build
```

## Still Having Issues?

1. **Check logs:**
```bash
docker-compose logs > debug.log
```

2. **Check versions:**
```bash
docker --version
docker-compose --version
python --version
```

3. **System resources:**
```bash
# Free memory
free -h  # Linux
Get-ComputerInfo | Select-Object OsFreePhysicalMemory  # Windows

# Disk space
df -h  # Linux/Mac
Get-PSDrive  # Windows
```

4. **Create GitHub issue with:**
   - Your operating system
   - Docker version
   - Error messages from logs
   - Steps to reproduce

## Useful Commands Reference

```bash
# View all logs
docker-compose logs -f

# View specific service
docker-compose logs -f api-service

# Restart a service
docker-compose restart api-service

# Rebuild a service
docker-compose up -d --build api-service

# Check service health
docker-compose ps

# Execute command in container
docker-compose exec postgres psql -U shopfast

# View networks
docker network ls

# View volumes
docker volume ls

# Clean up everything
docker-compose down -v --rmi all

# Check resource usage
docker stats
```

## Getting Help

- Check logs first: `docker-compose logs`
- Read error messages carefully
- Search Grafana community forums
- Check GitHub issues for similar problems
- Ask in Grafana Slack community

---

**Remember:** Most issues are solved by:
1. Waiting longer (especially PostgreSQL)
2. Checking logs
3. Restarting services
4. As last resort: `docker-compose down -v && docker-compose up -d`

