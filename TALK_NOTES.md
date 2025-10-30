# Presentation Notes for Grafana Alerting Demo

## Introduction (3 minutes)

### Hook
"How many of you have experienced a production outage that could have been prevented with better alerting?"

### Overview
- Today we'll explore Grafana alerting with a real e-commerce application
- Multiple data sources: Prometheus, Loki, PostgreSQL
- Real-world scenarios you can relate to

### Architecture Quick Tour
- Show the Docker Compose setup
- Explain the microservices: API, Frontend, Payment, Inventory
- Show the three data sources in Grafana UI

## Demo Flow (20 minutes)

### 1. Baseline - Everything Healthy (2 min)

**Actions:**
```bash
# Terminal 1: Start normal traffic
python simulator.py normal --duration 120
```

**Show in Grafana:**
- Dashboard showing all services
- Metrics flowing in Prometheus
- Logs appearing in Loki
- No alerts firing (green)

**Talking Points:**
- "This is what a healthy system looks like"
- "All services responding normally"
- "Metrics, logs, and business data all being collected"

### 2. Business Alert - Low Inventory (5 min)

**Actions:**
```bash
# Terminal 2: Start flash sale
python simulator.py flash-sale --product-id 1 --duration 45
```

**Show in Grafana:**
1. Go to Alerting → Alert rules
2. Watch "Low Inventory Warning"
3. Show the PostgreSQL query
4. Alert fires!
5. Click to see details: which product, current level

**Talking Points:**
- "Flash sale drives high traffic"
- "Inventory depleting rapidly"
- "This is a business metric alert - queries database directly"
- "Critical for operations team to know before customers see 'Out of Stock'"
- "Could trigger automated reordering"

**Query to Show:**
```sql
SELECT name, stock_level 
FROM products 
WHERE stock_level <= low_stock_threshold
```

### 3. Application Alert - Payment Failures (5 min)

**Actions:**
```bash
# Terminal 3: Start payment failures
python simulator.py payment-failures --duration 60
```

**Show in Grafana:**
1. Go to Explore → Loki
2. Show logs with errors appearing
3. Go to Alerting → "Payment Service Failures"
4. Alert fires!
5. Show the log query pattern

**Talking Points:**
- "Payment gateway experiencing issues"
- "This is a log-based alert - counting error patterns"
- "Combines logs across all payment service instances"
- "Could indicate integration issue, gateway problem, or fraud attempt"
- "Critical for revenue - needs immediate attention"

**Query to Show:**
```
sum(count_over_time({service="payment"} |~ "ERROR|payment failed" [5m])) > 5
```

### 4. Security Alert - Brute Force Attack (3 min)

**Actions:**
```bash
# Terminal 4: Simulate attack
python simulator.py security
```

**Show in Grafana:**
1. Go to Explore → PostgreSQL
2. Query login_attempts table
3. Show multiple failures for same user
4. Alert fires: "Multiple Failed Login Attempts"

**Talking Points:**
- "Security team needs to know about suspicious activity"
- "This queries structured data in PostgreSQL"
- "Could be brute force attack or compromised credential"
- "Demonstrates alerting on any SQL query result"

**Query to Show:**
```sql
SELECT email, COUNT(*) 
FROM login_attempts 
WHERE success = false 
  AND attempt_time > NOW() - INTERVAL '5 minutes' 
GROUP BY email 
HAVING COUNT(*) >= 5
```

### 5. Performance Alert - High CPU (3 min)

**Actions:**
```bash
# Terminal 5: CPU stress
python simulator.py high-cpu --duration 30
```

**Show in Grafana:**
1. Watch CPU metrics spike in Prometheus
2. Alert fires: "High CPU Usage"
3. Show Prometheus query
4. Show how it identifies which service

**Talking Points:**
- "Classic infrastructure alert"
- "But with service context"
- "Could indicate traffic spike, inefficient query, or resource leak"
- "Helps prevent cascading failures"

**Query to Show:**
```
rate(process_cpu_seconds_total[1m]) > 0.7
```

### 6. Multi-Source Correlation (2 min)

**Show in Grafana:**
- Create or show dashboard with:
  - CPU metrics (Prometheus)
  - Error logs (Loki)
  - Order count (PostgreSQL)
- Show how they correlate during flash sale

**Talking Points:**
- "Real power: correlate across data sources"
- "See the full picture"
- "High CPU + error logs + dropping inventory = flash sale impact"

## Key Takeaways (2 minutes)

1. **Multi-Source Alerting**
   - Metrics (Prometheus): Infrastructure and application performance
   - Logs (Loki): Application errors and events
   - SQL (PostgreSQL): Business metrics and security events

2. **Alert Types**
   - Threshold alerts (CPU > 70%)
   - Rate alerts (errors increasing)
   - Pattern alerts (log patterns)
   - Business rules (inventory < threshold)

3. **Real-World Benefits**
   - Catch issues before customers do
   - Reduce MTTR (Mean Time To Resolution)
   - Correlate across systems
   - Alert on business metrics, not just tech metrics

4. **Best Practices**
   - Set appropriate thresholds
   - Use "for" duration to avoid flapping
   - Create runbooks linked to alerts
   - Route to appropriate teams
   - Test your alerts!

## Demo Tips

### Before Presentation
- [ ] Run `docker-compose up -d` 30 minutes before
- [ ] Test each scenario once
- [ ] Have Grafana tabs pre-opened
- [ ] Clear alert history for clean start
- [ ] Prepare 5 terminal windows
- [ ] Test network connection

### During Presentation
- [ ] Keep Docker Compose logs visible
- [ ] Have backup screenshots
- [ ] Explain WHY each alert matters
- [ ] Show the queries, not just results
- [ ] Engage audience: "Have you seen this?"

### If Something Breaks
- [ ] Have screenshots ready
- [ ] Explain what should happen
- [ ] "Let me show you the configuration instead"
- [ ] Keep calm - it's a demo!

### Terminal Windows Setup
1. Docker Compose logs: `docker-compose logs -f`
2. Normal traffic: `python simulator.py normal --duration 300`
3. Scenario runner: Ready for commands
4. Grafana browser
5. Backup terminal

## Q&A Prep

**Q: How do alerts scale?**
A: Grafana Alerting is designed for scale. We're running everything on one machine for demo, but in production you'd have distributed Prometheus, Loki, and Grafana instances.

**Q: What about notification channels?**
A: Grafana integrates with Slack, PagerDuty, Email, Teams, webhooks, and 30+ others. Easy to configure in UI or provisioning.

**Q: Can we alert on complex queries?**
A: Yes! Any query your data source supports. You saw SQL, PromQL, LogQL. Can also use transformations.

**Q: How to avoid alert fatigue?**
A: Good thresholds, use "for" duration, alert on what matters, route intelligently, silence when needed.

**Q: What about alerting in Grafana Cloud?**
A: Same experience, but managed. Plus: multi-region, SLA, integrated with Grafana Cloud data sources.

**Q: Can alerts trigger actions?**
A: Yes! Webhooks can trigger automation. Also OnCall for escalation policies.

## Resources to Share

- Grafana Alerting docs: https://grafana.com/docs/grafana/latest/alerting/
- This demo stack: [your repo URL]
- Grafana Play (try it): https://play.grafana.org
- Community forum: https://community.grafana.com

## Follow-up

- Share demo repository link
- Share slides
- Connect on LinkedIn/Twitter
- Invite to local Grafana meetup
- Point to Grafana tutorials

---

Good luck with your presentation! 🎉

