#!/usr/bin/env bash
# Создаёт дополнительные БД при первом запуске тома (docker-entrypoint-initdb.d).
# Переменная POSTGRES_MULTIPLE_DATABASES задаётся в docker-compose (как в .env).
set -euo pipefail

if [[ -z "${POSTGRES_MULTIPLE_DATABASES:-}" ]]; then
  exit 0
fi

IFS=',' read -ra DBS <<< "$POSTGRES_MULTIPLE_DATABASES"
for raw in "${DBS[@]}"; do
  db="${raw//[[:space:]]/}"
  [[ -z "$db" ]] && continue
  exists="$(psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -tAc "SELECT 1 FROM pg_database WHERE datname = '$db'")"
  if [[ "$exists" != "1" ]]; then
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -c "CREATE DATABASE \"$db\";"
  fi
done
