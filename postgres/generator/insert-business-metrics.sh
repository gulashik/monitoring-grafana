#!/usr/bin/env sh

set -eu

CONTAINER_NAME="${CONTAINER_NAME:-postgres-metrics-db}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_DB="${POSTGRES_DB:-metrics_db}"

echo "Starting business metrics generation in container $CONTAINER_NAME..."

# Вызов процедуры. 
# Сама процедура содержит бесконечный цикл с pg_sleep, 
# поэтому этот вызов будет работать пока не придет сигнал прерывания.
podman exec "$CONTAINER_NAME" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "call public.insert_business_metrics();"
