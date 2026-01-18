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

log "Starting Mise Home Assistant Add-on..."

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
else
    log "No configuration file found, using defaults..."
    JWT_SECRET=$(head -c 64 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 64)
    echo "$JWT_SECRET" > /data/jwt_secret
    LLM_PROVIDER="embedded"
    EMAIL_ENABLED="false"
    ENABLE_REGISTRATION="true"
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
export MONGO_URL="mongodb://127.0.0.1:27017"
export DB_NAME="mise"
export JWT_SECRET="$JWT_SECRET"
export LLM_PROVIDER="$LLM_PROVIDER"
export OLLAMA_URL="$OLLAMA_URL"
export OLLAMA_MODEL="$OLLAMA_MODEL"
export OPENAI_API_KEY="$OPENAI_API_KEY"
export ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY"
export GOOGLE_AI_API_KEY="$GOOGLE_AI_API_KEY"
export EMAIL_ENABLED="$EMAIL_ENABLED"
export SMTP_SERVER="$SMTP_SERVER"
export SMTP_PORT="$SMTP_PORT"
export SMTP_USERNAME="$SMTP_USERNAME"
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

# Ensure data directories exist with correct permissions
log "Setting up data directories..."
mkdir -p /data/mongodb
mkdir -p /data/uploads
mkdir -p /var/log/mise
chown -R root:root /data/mongodb
chmod 755 /data/mongodb

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
MONGO_URL=$MONGO_URL
DB_NAME=$DB_NAME
JWT_SECRET=$JWT_SECRET
LLM_PROVIDER=$LLM_PROVIDER
OLLAMA_URL=$OLLAMA_URL
OLLAMA_MODEL=$OLLAMA_MODEL
OPENAI_API_KEY=$OPENAI_API_KEY
ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY
GOOGLE_AI_API_KEY=$GOOGLE_AI_API_KEY
EMAIL_ENABLED=$EMAIL_ENABLED
SMTP_SERVER=$SMTP_SERVER
SMTP_PORT=$SMTP_PORT
SMTP_USERNAME=$SMTP_USERNAME
SMTP_PASSWORD=$SMTP_PASSWORD
SMTP_FROM_EMAIL=$SMTP_FROM_EMAIL
ENABLE_REGISTRATION=$ENABLE_REGISTRATION
GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID
GOOGLE_CLIENT_SECRET=$GOOGLE_CLIENT_SECRET
GITHUB_CLIENT_ID=$GITHUB_CLIENT_ID
GITHUB_CLIENT_SECRET=$GITHUB_CLIENT_SECRET
CORS_ORIGINS=$CORS_ORIGINS
UPLOAD_DIR=$UPLOAD_DIR
MISE_HA_ADDON=$MISE_HA_ADDON
EOF

# Update supervisor config to use environment file
sed -i '/\[program:backend\]/a environment=file:/etc/mise.env' /etc/supervisor/conf.d/supervisord.conf 2>/dev/null || true

log "Configuration complete. Starting services..."
log "  - MongoDB: 127.0.0.1:27017"
log "  - Backend API: 127.0.0.1:8001"
log "  - Frontend/Nginx: 0.0.0.0:3000"
log "  - LLM Provider: $LLM_PROVIDER"

# Start supervisor to manage all processes
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
