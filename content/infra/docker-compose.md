---
title: Docker Compose
description: "Annotated compose.yml walkthrough — service definitions, labels, and networking"
tags:
  - infra
  - docker
---

# Docker Compose

The entire platform is orchestrated via a single `compose.yml`. This page walks through each service definition.

## Traefik (reverse proxy)

```yaml
traefik:
  image: traefik:v3.3
  ports: ["80:80", "443:443"]
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock:ro
    - letsencrypt:/letsencrypt
```

- **HTTPS**: Let's Encrypt ACME with TLS challenge
- **Routing**: Service discovery via Docker labels
- **HTTP → HTTPS**: Automatic redirect on port 80

## Frontend (Angular)

```yaml
frontend:
  image: <custom>
  labels:
    - traefik.http.routers.frontend.rule=Host(`${DOMAIN}`)
```

Served via nginx on port 80, exposed through Traefik with host-based routing.

## Backend (Spring Boot)

```yaml
backend:
  image: <custom>
  labels:
    - traefik.http.routers.backend.rule=Host(`${DOMAIN}`) && PathPrefix(`/api`)
```

Runs on port 8080, exposed through Traefik with path-prefix routing (`/api`).

## Redis

```yaml
redis:
  image: redis:7-alpine
  command: redis-server --requirepass ${REDIS_PASSWORD}
  volumes: [redis_data:/data]
```

Backend-only network. Used for [[alerts-system|Redis Streams]] (alert transport) and OAuth token caching ([[ms-email]]).

## Observability services

**Prometheus** — scrapes `/actuator/prometheus` from backend.
**Loki** (`grafana/loki:3.6.0`) — receives logs from backend's logback appender.
**Grafana** (`grafana/grafana-enterprise`) — unified UI at `/grafana` sub-path.

Config files mounted from `./config/` — see [[observability-stack]].

## Networks

| Network | Exposed services | Purpose |
|---------|-----------------|---------|
| `frontend` | Traefik, Frontend, Backend | Public-facing |
| `backend` | Backend, Redis, Prometheus, Loki, Grafana | Internal |

## Volumes

`redis_data`, `prometheus_data`, `loki_data`, `grafana_data`, `letsencrypt`
