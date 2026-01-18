# Mise Home Assistant Add-on
# Multi-stage build for frontend + backend + MongoDB

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
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv nginx curl jq bash git supervisor gnupg \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg && \
    echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] http://repo.mongodb.org/apt/debian bookworm/mongodb-org/7.0 main" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list && \
    apt-get update && apt-get install -y mongodb-org && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

RUN git clone --depth 1 https://github.com/Domocn/Mise.git /tmp/mise && \
    cp /tmp/mise/backend/requirements.txt /tmp/requirements.txt && \
    pip install --no-cache-dir -r /tmp/requirements.txt

RUN mkdir -p /app/backend /app/frontend /data/mongodb /data/uploads /var/log/mise /run/nginx /run/mongodb

RUN cp -r /tmp/mise/backend/* /app/backend/ && rm -rf /tmp/mise

COPY --from=frontend-build /mise/frontend/build /app/frontend/
COPY rootfs/etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY rootfs/etc/supervisor/conf.d/ /etc/supervisor/conf.d/
COPY rootfs/run.sh /run.sh
RUN chmod +x /run.sh

WORKDIR /app/backend
EXPOSE 3000 8001

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

LABEL io.hass.name="Mise" \
    io.hass.description="Self-hosted family recipe management and meal planning" \
    io.hass.version="1.0.0" \
    io.hass.type="addon" \
    io.hass.arch="amd64|aarch64"

CMD ["/run.sh"]

COPY --from=frontend-build /mise/frontend/build /app/frontend/
COPY rootfs/etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY rootfs/etc/supervisor/conf.d/ /etc/supervisor/conf.d/
COPY rootfs/run.sh /run.sh
RUN chmod +x /run.sh

WORKDIR /app/backend
EXPOSE 3000 8001

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

LABEL io.hass.name="Mise" \
    io.hass.description="Self-hosted family recipe management and meal planning" \
    io.hass.version="1.0.0" \
    io.hass.type="addon" \
    io.hass.arch="amd64|aarch64"

CMD ["/run.sh"]
