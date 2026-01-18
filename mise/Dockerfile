# Mise Home Assistant Add-on
# Multi-stage build for frontend + backend + MongoDB

ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base-debian:bookworm

# Stage 1: Clone and build frontend
FROM node:20-slim AS frontend-build

WORKDIR /app

# Install git
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# Enable corepack for yarn
RUN corepack enable && corepack prepare yarn@1.22.22 --activate

# Clone the Mise repository
RUN git clone --depth 1 https://github.com/Domocn/Mise.git /mise

WORKDIR /mise/frontend

# Install dependencies
RUN yarn install --frozen-lockfile || yarn install

# Build with API path for HA ingress
ARG REACT_APP_BACKEND_URL=/api
ENV REACT_APP_BACKEND_URL=$REACT_APP_BACKEND_URL

# Build the app
RUN yarn build

# Stage 2: Final Home Assistant base image (Debian-based for MongoDB support)
FROM ${BUILD_FROM}

# Install required packages (without MongoDB first)
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    nginx \
    curl \
    jq \
    bash \
    git \
    supervisor \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Add MongoDB official repository and install MongoDB
RUN curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg && \
    echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] http://repo.mongodb.org/apt/debian bookworm/mongodb-org/7.0 main" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list && \
    apt-get update && \
    apt-get install -y mongodb-org && \
    rm -rf /var/lib/apt/lists/*

# Set up Python virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Clone backend and install dependencies
RUN git clone --depth 1 https://github.com/Domocn/Mise.git /tmp/mise && \
    cp /tmp/mise/backend/requirements.txt /tmp/requirements.txt && \
    pip install --no-cache-dir -r /tmp/requirements.txt

# Create necessary directories
RUN mkdir -p \
    /app/backend \
    /app/frontend \
    /data/mongodb \
    /data/uploads \
    /var/log/mise \
    /run/nginx \
    /run/mongodb

# Copy backend code from cloned repo
RUN cp -r /tmp/mise/backend/* /app/backend/ && \
    rm -rf /tmp/mise

# Copy built frontend from build stage
COPY --from=frontend-build /mise/frontend/build /app/frontend/

# Copy nginx configuration
COPY rootfs/etc/nginx/nginx.conf /etc/nginx/nginx.conf

# Copy supervisor configuration
COPY rootfs/etc/supervisor/conf.d/ /etc/supervisor/conf.d/

# Copy run script
COPY rootfs/run.sh /run.sh
RUN chmod +x /run.sh

# Set working directory
WORKDIR /app/backend

# Expose ports
EXPOSE 3000 8001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Labels
LABEL \
    io.hass.name="Mise" \
    io.hass.description="Self-hosted family recipe management and meal planning" \
    io.hass.version="1.0.0" \
    io.hass.type="addon" \
    io.hass.arch="amd64|aarch64"

# Run the startup script
CMD ["/run.sh"]
    nginx \
    mongodb \
    curl \
    jq \
    bash \
    git \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Set up Python virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Clone backend and install dependencies
RUN git clone --depth 1 https://github.com/Domocn/Mise.git /tmp/mise && \
    cp /tmp/mise/backend/requirements.txt /tmp/requirements.txt && \
    pip install --no-cache-dir -r /tmp/requirements.txt

# Create necessary directories
RUN mkdir -p \
    /app/backend \
    /app/frontend \
    /data/mongodb \
    /data/uploads \
    /var/log/mise \
    /run/nginx \
    /run/mongodb

# Copy backend code from cloned repo
RUN cp -r /tmp/mise/backend/* /app/backend/ && \
    rm -rf /tmp/mise

# Copy built frontend from build stage
COPY --from=frontend-build /mise/frontend/build /app/frontend/

# Copy nginx configuration
COPY rootfs/etc/nginx/nginx.conf /etc/nginx/nginx.conf

# Copy supervisor configuration
COPY rootfs/etc/supervisor/conf.d/ /etc/supervisor/conf.d/

# Copy run script
COPY rootfs/run.sh /run.sh
RUN chmod +x /run.sh

# Set working directory
WORKDIR /app/backend

# Expose ports
EXPOSE 3000 8001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Labels
LABEL \
    io.hass.name="Mise" \
    io.hass.description="Self-hosted family recipe management and meal planning" \
    io.hass.version="1.0.0" \
    io.hass.type="addon" \
    io.hass.arch="amd64|aarch64"

# Run the startup script
CMD ["/run.sh"]

