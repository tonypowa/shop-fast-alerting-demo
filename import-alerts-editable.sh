#!/bin/bash
# Script to import alert rules as editable (non-provisioned) via API

GRAFANA_URL="http://localhost:3000"
GRAFANA_USER="admin"
GRAFANA_PASSWORD="admin"

echo "Waiting for Grafana to be ready..."
until curl -s -f -u ${GRAFANA_USER}:${GRAFANA_PASSWORD} ${GRAFANA_URL}/api/health > /dev/null 2>&1; do
    sleep 2
done

echo "Grafana is ready!"
echo "Note: To make alerts editable, either:"
echo "  1. Create them manually in the UI"
echo "  2. Import them via API (this script)"
echo "  3. Remove the provisioning file after first load"
echo ""
echo "For your demo, I recommend option 3:"
echo "  - Let provisioning create the alerts"
echo "  - Then remove/rename: grafana/provisioning/alerting/alerting.yml"
echo "  - Restart Grafana"
echo "  - Alerts will remain but become editable"
echo ""
echo "Do you want to remove the provisioning file now? (y/n)"

