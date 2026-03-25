#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# Порты из .env (make health не подставляет env_file compose)
if [[ -f "$ROOT/.env" ]]; then
  set -a
  # shellcheck source=/dev/null
  . "$ROOT/.env"
  set +a
fi

SERVICES=(
  "http://localhost:${API_GATEWAY_PORT:-3000}/health"
  "http://localhost:${IDENTITY_SERVICE_PORT:-3001}/health"
  "http://localhost:${PLANTS_SERVICE_PORT:-3002}/health"
  "http://localhost:${FEED_SERVICE_PORT:-3003}/health"
  "http://localhost:${NOTIFICATIONS_SERVICE_PORT:-3004}/health"
)

echo "Running health checks..."

FAILED=0

for url in "${SERVICES[@]}"; do
  echo "- Checking ${url}"
  if curl -fsS "${url}" > /dev/null; then
    echo "  OK"
  else
    echo "  FAILED"
    FAILED=1
  fi
done

if [ "${FAILED}" -ne 0 ]; then
  echo "Some services are unhealthy"
  exit 1
fi

echo "All services are healthy"

