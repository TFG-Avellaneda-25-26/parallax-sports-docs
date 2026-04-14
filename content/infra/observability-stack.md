---
title: Observability Stack
description: "Prometheus, Loki, and Grafana — metrics scraping, log aggregation, and unified dashboards"
tags:
  - infra
  - observability
aliases:
  - "Monitoring"
  - "Grafana Stack"
---

# Observability Stack

The observability pipeline uses Prometheus + Loki + Grafana, all running as services in the same Docker Compose deployment.

> [!info] Backend side
> For how the Spring application emits logs and metrics, see [[observability|Backend Observability]].

## Components

```
┌──────────┐     scrape      ┌────────────┐
│ Backend  │ ◀───────────── │ Prometheus │
│ /actuator│                 │            │──┐
│/prometheus│                └────────────┘  │
└──────────┘                                  │  ┌─────────┐
                                              ├─▶│ Grafana │
┌──────────┐     push        ┌────────────┐  │  │ /grafana │
│ Backend  │ ──────────────▶ │    Loki    │──┘  └─────────┘
│ logback  │                 │            │
│ appender │                 └────────────┘
└──────────┘
```

- **Prometheus** scrapes metrics from the backend's `/actuator/prometheus` endpoint
- **Loki** receives logs pushed by the backend's logback appender
- **Grafana** provides a unified UI for both logs (Loki) and metrics (Prometheus), accessible at `/grafana`

## Configuration

Configuration files are mounted from `./config/` in the Docker Compose setup:

| File | Purpose |
|------|---------|
| `config/prometheus/prometheus.yml` | Scrape targets and intervals |
| `config/loki/loki-config.yml` | Retention and storage settings |
| `config/grafana/provisioning/` | Pre-loaded datasources and dashboards |

> [!warning] To be documented in detail
> Specific configuration values, retention policies, and dashboard provisioning need detailed documentation.
