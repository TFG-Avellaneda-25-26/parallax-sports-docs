---
title: Infrastructure
description: "Infrastructure documentation — Docker Compose, Traefik, Redis, observability stack, CI/CD, and Proxmox hosting"
tags:
  - infra
---

# Infrastructure

The platform is self-hosted on a Proxmox server, orchestrated with Docker Compose, and exposed through Traefik as a reverse proxy with automatic HTTPS.

## Sections

| Page | What it covers |
|------|---------------|
| [[deployment]] | Docker Compose services, networks, volumes, environment variables |
| [[docker-compose]] | Annotated `compose.yml` walkthrough |
| [[traefik]] | Reverse proxy, HTTPS via Let's Encrypt ACME, routing rules |
| [[redis]] | Redis 7: Streams for alert transport, caching for OAuth tokens, persistence config |
| [[observability-stack]] | Prometheus + Loki + Grafana: scrape config, retention, dashboard provisioning |
| [[ci-cd]] | Jenkins pipeline |
| [[proxmox]] | Self-hosted server setup |
