# Mise Home Assistant Add-on
# Multi-stage build for frontend + backend + PostgreSQL + Redis

ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base-debian:bookworm

FROM node:20-slim AS frontend-build
WORKDIR /app
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*
RUN corepack enable && corepack prepare yarn@1.22.22 --activate
RUN git clone --depth 1 https://github.com/Domocn/Mise.git /mise
WORKDIR /mise/frontend
RUN yarn install --frozen-lockfile || yarn install
ARG REACT_APP_BACKEND_URL=/api
ENV REACT_APP_BACKEND_URL=$REACT_APP_BACKEND_URL
RUN yarn build

FROM ${BUILD_FROM}

# Install base packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv nginx curl jq bash git supervisor gnupg \
    lsb-release wget ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install PostgreSQL 15
RUN echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/postgresql-keyring.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get install -y postgresql-15 postgresql-client-15 && \
    rm -rf /var/lib/apt/lists/*

# Install Redis
RUN apt-get update && \
    apt-get install -y redis-server && \
    rm -rf /var/lib/apt/lists/*

# Create Python virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Clone Mise repository and install Python dependencies
RUN git clone --depth 1 https://github.com/Domocn/Mise.git /tmp/mise && \
    cp /tmp/mise/backend/requirements.txt /tmp/requirements.txt && \
    pip install --no-cache-dir -r /tmp/requirements.txt

# Create necessary directories
RUN mkdir -p /app/backend /app/frontend \
    /data/postgres /data/redis /data/uploads \
    /var/log/mise /run/nginx /run/postgresql \
    /var/run/postgresql

# Copy backend code
RUN cp -r /tmp/mise/backend/* /app/backend/ && rm -rf /tmp/mise

# Copy frontend build
COPY --from=frontend-build /mise/frontend/build /app/frontend/

# Copy configuration files
COPY rootfs/etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY rootfs/etc/supervisor/conf.d/ /etc/supervisor/conf.d/
COPY rootfs/run.sh /run.sh
RUN chmod +x /run.sh

# Set PostgreSQL permissions
RUN chown -R postgres:postgres /data/postgres /var/run/postgresql /run/postgresql

# Set Redis permissions
RUN chown -R redis:redis /data/redis

WORKDIR /app/backend

# Expose ports
EXPOSE 3000 8001 5555

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=3 \
    CMD curl -f http://localhost:3000/health || curl -f http://localhost:8001/api/health || exit 1

# Labels
LABEL io.hass.name="Mise" \
    io.hass.description="Self-hosted family recipe management and meal planning with PostgreSQL, Redis, and background jobs" \
    io.hass.version="2.0.0" \
    io.hass.type="addon" \
    io.hass.arch="amd64|aarch64"

CMD ["/run.sh"]
