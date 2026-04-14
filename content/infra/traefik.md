---
title: Traefik
description: "Reverse proxy with automatic HTTPS — routing rules, ACME certificates, and service discovery"
tags:
  - infra
---

# Traefik

Traefik v3.3 serves as the reverse proxy, handling HTTPS termination, automatic certificate management, and request routing.

## Routing rules

| Service | Rule | Target |
|---------|------|--------|
| Frontend | `Host(\`${DOMAIN}\`)` | Angular app (port 80) |
| Backend | `Host(\`${DOMAIN}\`) && PathPrefix(\`/api\`)` | Spring Boot (port 8080) |
| Grafana | `Host(\`${DOMAIN}\`) && PathPrefix(\`/grafana\`)` | Grafana (port 3000) |

## HTTPS

- **ACME provider**: Let's Encrypt
- **Challenge type**: TLS-ALPN-01
- **Certificate storage**: `letsencrypt` Docker volume
- **HTTP → HTTPS**: Automatic redirect on port 80

## Service discovery

Traefik discovers services via the Docker socket (`/var/run/docker.sock:ro`). Each service defines its routing rules as Docker labels — no static configuration file needed.
