---
title: Deployment
description: "Docker Compose deployment architecture — services, networks, volumes, and environment variables"
tags:
  - infra
  - docker
aliases:
  - "Docker Deployment"
---

# Deployment

The full stack runs on a self-hosted [[proxmox|Proxmox]] server using Docker Compose. [[traefik|Traefik]] acts as the reverse proxy with automatic HTTPS.

## Services

| Service | Image | Role |
|---------|-------|------|
| Traefik | `traefik:v3.3` | Reverse proxy, HTTPS (ACME/Let's Encrypt) |
| Frontend | custom image | Angular app served via nginx |
| Backend | custom image | Spring Boot API (port 8080) |
| Redis | `redis:7-alpine` | Streams (alert transport) + caching |
| Prometheus | `prom/prometheus` | Metrics scraping |
| Loki | `grafana/loki:3.6.0` | Log aggregation |
| Grafana | `grafana/grafana-enterprise` | Observability UI |

See [[docker-compose]] for the annotated `compose.yml` walkthrough.

## Network topology

```
                    Internet
                       │
                  ┌────┴────┐
                  │ Traefik │ ← HTTPS termination
                  └────┬────┘
                       │
            ┌──────────┼──────────┐
         frontend    network    backend
         network                network
            │                     │
       ┌────┴────┐          ┌────┴────────────────────────┐
       │Frontend │          │Backend  Redis  Prometheus   │
       │(Angular)│          │(Spring) (7)    Loki  Grafana│
       └─────────┘          └─────────────────────────────┘
```

- **`frontend` network**: exposes Traefik, frontend, and backend to the internet
- **`backend` network**: internal communication between API, Redis, Prometheus, Loki, and Grafana

Grafana runs on sub-path `/grafana` (configured via `GF_SERVER_ROOT_URL`).

## Persistent volumes

| Volume | Used by | Purpose |
|--------|---------|---------|
| `redis_data` | Redis | Stream data + cached tokens |
| `prometheus_data` | Prometheus | Metrics time-series |
| `loki_data` | Loki | Log storage |
| `grafana_data` | Grafana | Dashboards and settings |
| `letsencrypt` | Traefik | ACME certificates |

## Environment variables

| Variable | Used by | Purpose |
|----------|---------|---------|
| `DOMAIN` | Traefik, frontend, backend | Public domain name |
| `REDIS_PASSWORD` | Redis, backend | Redis authentication |
| `GRAFANA_ADMIN_USER` | Grafana | Admin username |
| `GRAFANA_ADMIN_PASSWORD` | Grafana | Admin password |
| DB connection vars | Backend | PostgreSQL connection string |
| Backend config vars | Backend | JWT secrets, OAuth credentials, API keys |

## Proxmox setup

> [!warning] Work in progress
> Proxmox VM and network configuration is not yet documented. See [[proxmox]].
