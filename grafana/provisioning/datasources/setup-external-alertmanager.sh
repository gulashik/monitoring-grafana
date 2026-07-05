#!/usr/bin/env sh
# Настройка Grafana Alerting для использования внешнего Alertmanager
set -eu

GRAFANA_URL="${GRAFANA_URL:-http://localhost:3000}"
GRAFANA_USER="${GRAFANA_USER:-admin}"
GRAFANA_PASSWORD="${GRAFANA_ADMIN_PASSWORD:-admin}"

auth="$GRAFANA_USER:$GRAFANA_PASSWORD"

echo "Waiting for Grafana at $GRAFANA_URL..."
until curl -fsS -u "$auth" "$GRAFANA_URL/api/health" >/dev/null; do
  echo "Still waiting for Grafana..."
  sleep 2
done

echo "Configuring Grafana Alerting to use all Alertmanagers..."
curl -fsS -u "$auth" \
  -H "Content-Type: application/json" \
  -X POST "$GRAFANA_URL/api/v1/ngalert/admin_config" \
  -d '{"alertmanagersChoice":"all"}'

echo "Configuration complete."
