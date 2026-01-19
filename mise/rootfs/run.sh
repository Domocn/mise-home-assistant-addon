#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# Mise Home Assistant Add-on startup script

set -e

CONFIG_PATH=/data/options.json
BASHIO_LOG_LEVEL="info"

# Function to log messages
log() {
    echo "[Mise] $1"
}

log "Starting Mise Home Assistant Add-on v2.0.0..."

# Read configuration from Home Assistant options
if [ -f "$CONFIG_PATH" ]; then
    log "Reading configuration from Home Assistant..."

    # JWT Secret - generate if not provided
    JWT_SECRET=$(jq -r '.jwt_secret // empty' "$CONFIG_PATH")
    if [ -z "$JWT_SECRET" ]; then
        log "Generating JWT secret..."
        JWT_SECRET=$(head -c 64 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 64)
        # Store for persistence
        echo "$JWT_SECRET" > /data/jwt_secret
    fi

    # Load persisted JWT secret if exists
    if [ -f /data/jwt_secret ] && [ -z "$JWT_SECRET" ]; then
        JWT_SECRET=$(cat /data/jwt_secret)
    fi

    # LLM Configuration
    LLM_PROVIDER=$(jq -r '.llm_provider // "embedded"' "$CONFIG_PATH")
    OLLAMA_URL=$(jq -r '.ollama_url // "http://homeassistant.local:11434"' "$CONFIG_PATH")
    OLLAMA_MODEL=$(jq -r '.ollama_model // "llama3"' "$CONFIG_PATH")
    OPENAI_API_KEY=$(jq -r '.openai_api_key // empty' "$CONFIG_PATH")
    ANTHROPIC_API_KEY=$(jq -r '.anthropic_api_key // empty' "$CONFIG_PATH")
    GOOGLE_AI_API_KEY=$(jq -r '.google_ai_api_key // empty' "$CONFIG_PATH")

    # Email Configuration
    EMAIL_ENABLED=$(jq -r '.email_enabled // "false"' "$CONFIG_PATH")
    SMTP_SERVER=$(jq -r '.smtp_server // empty' "$CONFIG_PATH")
    SMTP_PORT=$(jq -r '.smtp_port // "587"' "$CONFIG_PATH")
    SMTP_USERNAME=$(jq -r '.smtp_username // empty' "$CONFIG_PATH")
    SMTP_PASSWORD=$(jq -r '.smtp_password // empty' "$CONFIG_PATH")
    SMTP_FROM_EMAIL=$(jq -r '.smtp_from_email // empty' "$CONFIG_PATH")

    # OAuth Configuration
    ENABLE_REGISTRATION=$(jq -r '.enable_registration // "true"' "$CONFIG_PATH")
    GOOGLE_CLIENT_ID=$(jq -r '.google_client_id // empty' "$CONFIG_PATH")
    GOOGLE_CLIENT_SECRET=$(jq -r '.google_client_secret // empty' "$CONFIG_PATH")
    GITHUB_CLIENT_ID=$(jq -r '.github_client_id // empty' "$CONFIG_PATH")
    GITHUB_CLIENT_SECRET=$(jq -r '.github_client_secret // empty' "$CONFIG_PATH")

    # PostgreSQL Configuration
    POSTGRES_MAX_CONNECTIONS=$(jq -r '.postgres_max_connections // "100"' "$CONFIG_PATH")
    POSTGRES_SHARED_BUFFERS=$(jq -r '.postgres_shared_buffers // "256MB"' "$CONFIG_PATH")

    # Redis Configuration
    REDIS_MAXMEMORY=$(jq -r '.redis_maxmemory // "256mb"' "$CONFIG_PATH")

    # Celery Configuration
    CELERY_CONCURRENCY=$(jq -r '.celery_concurrency // "2"' "$CONFIG_PATH")
    ENABLE_FLOWER=$(jq -r '.enable_flower_dashboard // "true"' "$CONFIG_PATH")

    # Debug Mode
    DEBUG_MODE=$(jq -r '.debug_mode // "false"' "$CONFIG_PATH")
else
    log "No configuration file found, using defaults..."
    JWT_SECRET=$(head -c 64 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 64)
    echo "$JWT_SECRET" > /data/jwt_secret
    LLM_PROVIDER="embedded"
    EMAIL_ENABLED="false"
    ENABLE_REGISTRATION="true"
    POSTGRES_MAX_CONNECTIONS="100"
    POSTGRES_SHARED_BUFFERS="256MB"
    REDIS_MAXMEMORY="256mb"
    CELERY_CONCURRENCY="2"
    ENABLE_FLOWER="true"
    DEBUG_MODE="false"
fi

# Set logging level based on debug mode
if [ "$DEBUG_MODE" = "true" ]; then
    LOG_LEVEL="DEBUG"
    UVICORN_LOG_LEVEL="debug"
    CELERY_LOG_LEVEL="debug"
    log "DEBUG MODE ENABLED - Verbose logging active"
else
    LOG_LEVEL="INFO"
    UVICORN_LOG_LEVEL="info"
    CELERY_LOG_LEVEL="info"
fi

# Get Home Assistant ingress information
INGRESS_PATH=""
if [ -n "$SUPERVISOR_TOKEN" ]; then
    log "Running as Home Assistant add-on with Supervisor..."
    INGRESS_ENTRY=$(curl -s -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" http://supervisor/addons/self/info | jq -r '.data.ingress_entry // empty')
    if [ -n "$INGRESS_ENTRY" ]; then
        INGRESS_PATH="$INGRESS_ENTRY"
        log "Ingress path: $INGRESS_PATH"
    fi
fi

# Export environment variables for the backend
export DATABASE_URL="postgresql://mise:mise@127.0.0.1:5432/mise"
export REDIS_URL="redis://127.0.0.1:6379"
export REDIS_PUBSUB_ENABLED="true"
export JWT_SECRET="$JWT_SECRET"
export LLM_PROVIDER="$LLM_PROVIDER"
export OLLAMA_URL="$OLLAMA_URL"
export OLLAMA_MODEL="$OLLAMA_MODEL"
export OPENAI_API_KEY="$OPENAI_API_KEY"
export ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY"
export GOOGLE_AI_API_KEY="$GOOGLE_AI_API_KEY"
export EMAIL_ENABLED="$EMAIL_ENABLED"
export SMTP_HOST="$SMTP_SERVER"
export SMTP_PORT="$SMTP_PORT"
export SMTP_USER="$SMTP_USERNAME"
export SMTP_PASSWORD="$SMTP_PASSWORD"
export SMTP_FROM_EMAIL="$SMTP_FROM_EMAIL"
export ENABLE_REGISTRATION="$ENABLE_REGISTRATION"
export GOOGLE_CLIENT_ID="$GOOGLE_CLIENT_ID"
export GOOGLE_CLIENT_SECRET="$GOOGLE_CLIENT_SECRET"
export GITHUB_CLIENT_ID="$GITHUB_CLIENT_ID"
export GITHUB_CLIENT_SECRET="$GITHUB_CLIENT_SECRET"
export CORS_ORIGINS="*"
export UPLOAD_DIR="/data/uploads"
export MISE_HA_ADDON="true"
export INGRESS_PATH="$INGRESS_PATH"
export DEBUG_MODE="$DEBUG_MODE"
export LOG_LEVEL="$LOG_LEVEL"
export UVICORN_LOG_LEVEL="$UVICORN_LOG_LEVEL"
export CELERY_LOG_LEVEL="$CELERY_LOG_LEVEL"

# Ensure data directories exist with correct permissions
log "Setting up data directories..."
mkdir -p /data/postgres
mkdir -p /data/redis
mkdir -p /data/uploads
mkdir -p /var/log/mise
mkdir -p /var/run/postgresql

# Set log directory permissions FIRST so all services can write logs
chmod 777 /var/log/mise

# Create log files with correct ownership so postgres user can write
touch /var/log/mise/postgres.log /var/log/mise/postgres-error.log
chown postgres:postgres /var/log/mise/postgres.log /var/log/mise/postgres-error.log

# Set data directory permissions
chown -R postgres:postgres /data/postgres /var/run/postgresql
chown -R redis:redis /data/redis
chmod 700 /data/postgres

# Initialize PostgreSQL if not already initialized
if [ ! -d /data/postgres/base ]; then
    log "Initializing PostgreSQL database..."
    su - postgres -c "/usr/lib/postgresql/15/bin/initdb -D /data/postgres"

    # Configure PostgreSQL
    cat >> /data/postgres/postgresql.conf <<EOF
max_connections = $POSTGRES_MAX_CONNECTIONS
shared_buffers = $POSTGRES_SHARED_BUFFERS
listen_addresses = '127.0.0.1'
port = 5432
unix_socket_directories = '/var/run/postgresql'
logging_collector = on
log_directory = '/var/log/mise'
log_filename = 'postgresql-%Y-%m-%d.log'
EOF

    # Start PostgreSQL temporarily to create user and database
    su - postgres -c "/usr/lib/postgresql/15/bin/pg_ctl -D /data/postgres -l /var/log/mise/postgres.log start"
    sleep 5

    # Create user and database
    su - postgres -c "psql -c \"CREATE USER mise WITH PASSWORD 'mise';\""
    su - postgres -c "psql -c \"CREATE DATABASE mise OWNER mise;\""
    su - postgres -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE mise TO mise;\""

    # Stop PostgreSQL (supervisor will manage it)
    su - postgres -c "/usr/lib/postgresql/15/bin/pg_ctl -D /data/postgres stop"

    log "PostgreSQL initialized successfully"
else
    log "PostgreSQL database already exists"
fi

# Update backend to use the data directory for uploads
if [ -L /app/backend/uploads ]; then
    rm /app/backend/uploads
fi
ln -sf /data/uploads /app/backend/uploads

# Update frontend base path for ingress if needed
if [ -n "$INGRESS_PATH" ]; then
    log "Configuring frontend for ingress path: $INGRESS_PATH"
    # Update index.html base tag if needed
    if [ -f /app/frontend/index.html ]; then
        sed -i "s|<base href=\"/\"|<base href=\"${INGRESS_PATH}/\"|g" /app/frontend/index.html 2>/dev/null || true
    fi
fi

# Write environment file for supervisor processes
cat > /etc/mise.env << EOF
DATABASE_URL=$DATABASE_URL
REDIS_URL=$REDIS_URL
REDIS_PUBSUB_ENABLED=$REDIS_PUBSUB_ENABLED
JWT_SECRET=$JWT_SECRET
LLM_PROVIDER=$LLM_PROVIDER
OLLAMA_URL=$OLLAMA_URL
OLLAMA_MODEL=$OLLAMA_MODEL
OPENAI_API_KEY=$OPENAI_API_KEY
ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY
GOOGLE_AI_API_KEY=$GOOGLE_AI_API_KEY
EMAIL_ENABLED=$EMAIL_ENABLED
SMTP_HOST=$SMTP_HOST
SMTP_PORT=$SMTP_PORT
SMTP_USER=$SMTP_USER
SMTP_PASSWORD=$SMTP_PASSWORD
SMTP_FROM_EMAIL=$SMTP_FROM_EMAIL
ENABLE_REGISTRATION=$ENABLE_REGISTRATION
GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID
GOOGLE_CLIENT_SECRET=$GOOGLE_CLIENT_SECRET
GITHUB_CLIENT_ID=$GITHUB_CLIENT_ID
GITHUB_CLIENT_SECRET=$GITHUB_CLIENT_SECRET
CORS_ORIGINS=$CORS_ORIGINS
UPLOAD_DIR=$UPLOAD_DIR
MISE_HA_ADDON=true
DEBUG_MODE=$DEBUG_MODE
LOG_LEVEL=$LOG_LEVEL
UVICORN_LOG_LEVEL=$UVICORN_LOG_LEVEL
CELERY_LOG_LEVEL=$CELERY_LOG_LEVEL
PATH=/opt/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
EOF

# Note: Environment variables are passed via /usr/local/bin/mise-env.sh wrapper script
# which sources /etc/mise.env before starting each service

log "Configuration complete. Starting services..."
log "  - PostgreSQL: 127.0.0.1:5432"
log "  - Redis: 127.0.0.1:6379"
log "  - Backend API: 127.0.0.1:8001"
log "  - Celery Worker: $CELERY_CONCURRENCY workers"
if [ "$ENABLE_FLOWER" = "true" ]; then
    log "  - Flower Dashboard: 127.0.0.1:5555"
fi
log "  - Frontend/Nginx: 0.0.0.0:3000"
log "  - LLM Provider: $LLM_PROVIDER"
log ""
log "Logs are available in:"
log "  - Home Assistant add-on logs (this output)"
log "  - /api/debug/logs API endpoint (when debug enabled)"
log "  - /var/log/mise/ directory (inside container)"

# Show debug information if debug mode is enabled
if [ "$DEBUG_MODE" = "true" ]; then
    log "====== DEBUG INFO ======"
    log "Python version: $(python3 --version)"
    log "Uvicorn version: $(su -s /bin/bash - root -c 'source /opt/venv/bin/activate && uvicorn --version' 2>&1 || echo 'Not available')"
    log "Environment variables written to: /etc/mise.env"
    log "Log files location: /var/log/mise/"
    log "======================="
fi

# Start supervisor to manage all processes
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
