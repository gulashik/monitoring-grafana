#!/usr/bin/env sh
# пересоздать алер как editable если нужно
set -eu
GRAFANA_URL="${GRAFANA_URL:-http://localhost:3000}"
GRAFANA_USER="${GRAFANA_USER:-admin}"
GRAFANA_PASSWORD="${GRAFANA_PASSWORD:-admin}"

auth="$GRAFANA_USER:$GRAFANA_PASSWORD"
folder_title="Demo Alerting"
folder_uid="demo-alerting"
rule_uid="nginx-exporter-down-grafana"
rule_group="demo-grafana-alerting"

curl -s -u "$auth" \
  -H "Content-Type: application/json" \
  -X POST "$GRAFANA_URL/api/folders" \
  --data "{\"uid\":\"$folder_uid\",\"title\":\"$folder_title\"}" >/dev/null || true

curl -s -u "$auth" \
  -X DELETE "$GRAFANA_URL/apis/rules.alerting.grafana.app/v0alpha1/namespaces/default/alertrules/$rule_uid" >/dev/null || true

cat > /tmp/nginx-exporter-down-grafana.json <<'JSON'
{
  "uid": "nginx-exporter-down-grafana",
  "title": "NginxExporterDown",
  "ruleGroup": "demo-grafana-alerting",
  "folderUID": "demo-alerting",
  "orgId": 1,
  "condition": "C",
  "data": [
    {
      "refId": "A",
      "queryType": "",
      "relativeTimeRange": {
        "from": 300,
        "to": 0
      },
      "datasourceUid": "prometheus",
      "model": {
        "datasource": {
          "type": "prometheus",
          "uid": "prometheus"
        },
        "editorMode": "code",
        "expr": "1 - up{job=\"nginx-exporter\"}",
        "instant": true,
        "intervalMs": 1000,
        "maxDataPoints": 43200,
        "range": false,
        "refId": "A"
      }
    },
    {
      "refId": "C",
      "queryType": "",
      "relativeTimeRange": {
        "from": 0,
        "to": 0
      },
      "datasourceUid": "__expr__",
      "model": {
        "conditions": [
          {
            "evaluator": {
              "params": [
                0
              ],
              "type": "gt"
            },
            "operator": {
              "type": "and"
            },
            "query": {
              "params": [
                "C"
              ]
            },
            "reducer": {
              "params": [],
              "type": "last"
            },
            "type": "query"
          }
        ],
        "datasource": {
          "type": "__expr__",
          "uid": "__expr__"
        },
        "expression": "A",
        "intervalMs": 1000,
        "maxDataPoints": 43200,
        "refId": "C",
        "type": "threshold"
      }
    }
  ],
  "noDataState": "Alerting",
  "execErrState": "Error",
  "for": "1m",
  "annotations": {
    "summary": "Grafana не видит nginx-exporter",
    "description": "Prometheus возвращает 1 - up{job=\"nginx-exporter\"} > 0. Проверьте контейнер nginx-exporter и target в Prometheus.",
    "runbook_url": "http://localhost:9090/targets?search=nginx-exporter"
  },
  "labels": {
    "severity": "warning",
    "service": "nginx-exporter",
    "source": "grafana"
  },
  "isPaused": false
}
JSON

curl -fsS -u "$auth" \
  -H "Content-Type: application/json" \
  -H "X-Disable-Provenance: true" \
  -X POST "$GRAFANA_URL/api/v1/provisioning/alert-rules" \
  --data @/tmp/nginx-exporter-down-grafana.json >/dev/null

curl -fsS -u "$auth" \
  "$GRAFANA_URL/api/v1/provisioning/alert-rules/$rule_uid"
