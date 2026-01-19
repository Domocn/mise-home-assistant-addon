#!/bin/bash
# Wait for PostgreSQL to be ready before starting a command

set -e

POSTGRES_HOST="${POSTGRES_HOST:-127.0.0.1}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
MAX_RETRIES="${MAX_RETRIES:-30}"
RETRY_INTERVAL="${RETRY_INTERVAL:-2}"

echo "[wait-for-postgres] Waiting for PostgreSQL at ${POSTGRES_HOST}:${POSTGRES_PORT}..."

retries=0
until pg_isready -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -q; do
    retries=$((retries + 1))
    if [ $retries -ge $MAX_RETRIES ]; then
        echo "[wait-for-postgres] PostgreSQL not ready after $MAX_RETRIES retries. Giving up."
        exit 1
    fi
    echo "[wait-for-postgres] PostgreSQL not ready yet (attempt $retries/$MAX_RETRIES). Waiting ${RETRY_INTERVAL}s..."
    sleep $RETRY_INTERVAL
done

echo "[wait-for-postgres] PostgreSQL is ready!"

# Execute the command passed as arguments
exec "$@"
