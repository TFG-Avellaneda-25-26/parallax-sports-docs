---
title: Backend Observability
description: "Application-side observability — Logback to Loki, Actuator to Prometheus, structured logging"
tags:
  - backend
  - observability
aliases:
  - "Logging"
  - "Metrics"
---

# Backend Observability

Two independent pipelines feed the [[observability-stack|observability stack]]:

```
Logs:    App → Logback appender → Loki → Grafana
Metrics: App → /actuator/prometheus → Prometheus (scrape) → Grafana
```

## Logging

The backend uses SLF4J + Logback with a Loki appender that pushes structured logs directly to the Loki instance.

Configuration is in `logback-spring.xml`, with the Loki URL from `LOKI_URL` environment variable (default: `http://localhost:3100`).

## Metrics

Spring Boot Actuator exposes a Prometheus-compatible metrics endpoint at `/actuator/prometheus`. Prometheus scrapes this endpoint at configured intervals.

### Exposed actuator endpoints

| Endpoint | Access | Purpose |
|----------|--------|---------|
| `/actuator/health` | Public | Health check |
| `/actuator/info` | Public | Application info |
| `/actuator/prometheus` | Public | Prometheus metrics |
| `/actuator/mappings` | ADMIN | Request mappings |
| `/actuator/conditions` | ADMIN | Auto-configuration report |
