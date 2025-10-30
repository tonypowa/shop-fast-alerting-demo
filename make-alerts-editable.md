# Making Alerts Editable in Grafana UI

## The Issue
Provisioned alerts from YAML files are read-only by default in Grafana.

## Solution: Use Grafana API Provisioning Instead

### Option 1: Quick Fix (Recommended for Demo)
After the first startup:
1. Stop Grafana: `docker-compose stop grafana`
2. Move the provisioning file: 
   ```bash
   mv grafana/provisioning/alerting/alerting.yml grafana/provisioning/alerting/alerting.yml.backup
   ```
3. Start Grafana: `docker-compose start grafana`
4. The alerts remain but are now fully editable!

### Option 2: Disable Provisioning (Keep as Reference)
1. Rename the folder:
   ```bash
   mv grafana/provisioning/alerting grafana/provisioning/alerting-reference
   ```
2. Restart: `docker-compose restart grafana`
3. Manually create alerts using the UI (use the YAML as reference)

### Option 3: Use Environment Variable
Add to docker-compose.yml under grafana environment:
```yaml
- GF_ALERTING_ENABLED=true
- GF_UNIFIED_ALERTING_ENABLED=true
```

Then create alerts via UI or API instead of file provisioning.

## For Your Talk
**Best Approach:**
1. Let me provision them initially (as reference)
2. You can then recreate them in the UI (editable)
3. Or use the Quick Fix above to convert them

Would you like me to apply Option 1 now?

