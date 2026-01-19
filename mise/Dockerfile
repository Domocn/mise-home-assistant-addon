# Mise Home Assistant Add-on
# Optimized multi-stage build for faster ARM builds
# syntax=docker/dockerfile:1

ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base-debian:bookworm

# Stage 1: Build frontend
FROM node:20-slim AS frontend-build
WORKDIR /app

# Install git and ca-certificates, enable yarn in one layer
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends git ca-certificates && \
    corepack enable && \
    corepack prepare yarn@1.22.22 --activate

# Clone and build frontend
RUN git clone --depth 1 https://github.com/Domocn/Mise.git /mise
WORKDIR /mise/frontend
ARG REACT_APP_BACKEND_URL=/api
ENV REACT_APP_BACKEND_URL=$REACT_APP_BACKEND_URL

# Use yarn cache mount for faster rebuilds
RUN --mount=type=cache,target=/root/.yarn \
    yarn install --frozen-lockfile || yarn install

RUN yarn build

# Stage 2: Main application image
FROM ${BUILD_FROM}

# Install ALL system packages in ONE layer with cache mounts
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 python3-pip python3-venv nginx curl jq bash git \
        supervisor gnupg lsb-release wget ca-certificates redis-server && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | \
        gpg --dearmor -o /usr/share/keyrings/postgresql-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/postgresql-keyring.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends postgresql-15 postgresql-client-15

# Create Python venv and directories
RUN python3 -m venv /opt/venv && \
    mkdir -p /app/backend /app/frontend \
        /data/postgres /data/redis /data/uploads \
        /var/log/mise /run/nginx /run/postgresql /var/run/postgresql

ENV PATH="/opt/venv/bin:$PATH"

# Clone repo, install Python deps, and copy backend - using pip cache
RUN --mount=type=cache,target=/root/.cache/pip \
    git clone --depth 1 https://github.com/Domocn/Mise.git /tmp/mise && \
    pip install --no-cache-dir -r /tmp/mise/backend/requirements.txt && \
    cp -r /tmp/mise/backend/* /app/backend/ && \
    rm -rf /tmp/mise

# Copy frontend build from first stage
COPY --from=frontend-build /mise/frontend/build /app/frontend/

# Copy config files and set permissions
COPY rootfs/etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY rootfs/etc/supervisor/conf.d/ /etc/supervisor/conf.d/
COPY rootfs/run.sh /run.sh
RUN chmod +x /run.sh && \
    chown -R postgres:postgres /data/postgres /var/run/postgresql /run/postgresql && \
    chown -R redis:redis /data/redis

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
