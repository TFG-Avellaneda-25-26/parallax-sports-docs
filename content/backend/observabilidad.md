---
title: Observabilidad
description: Métricas Micrometer personalizadas, trazabilidad MDC con Logback y endpoints Actuator expuestos en el backend de Parallax Sports.
tags: [backend, observabilidad, metricas, micrometer, prometheus, logs, mdc]
---

# Observabilidad

Para el stack de infraestructura (Prometheus, Loki, Grafana, Alloy) ver [[infra/observabilidad-stack|Stack de observabilidad]].

---

## Métricas Micrometer

### AlertMetrics

Métricas del pipeline de alertas de eventos.

| Métrica                   | Tipo                                    | Etiquetas               |
| ------------------------- | --------------------------------------- | ----------------------- |
| `alerts.pipeline.latency` | Histogram (percentiles 0.5, 0.95, 0.99) | —                       |
| `alerts.generated.total`  | Counter                                 | `channel`               |
| `alerts.dispatched.total` | Counter                                 | `channel`               |
| `alerts.sent.total`       | Counter                                 | `channel`               |
| `alerts.failed.total`     | Counter                                 | `channel`, `error_code` |
| `alerts.retried.total`    | Counter                                 | —                       |

### AuthMetrics

| Métrica                                   | Tipo    | Etiquetas                                   |
| ----------------------------------------- | ------- | ------------------------------------------- |
| `auth.registrations.total`                | Counter | —                                           |
| `auth.logins.total`                       | Counter | `provider` (`local` / `google` / `discord`) |
| `auth.token.refresh.total`                | Counter | —                                           |
| `auth.token.refresh.reuse_detected.total` | Counter | —                                           |

### ExternalApiMetrics

| Métrica                                   | Tipo    | Etiquetas  |
| ----------------------------------------- | ------- | ---------- |
| `external.api.sync.duration.seconds`      | Timer   | `provider` |
| `external.api.sync.events_upserted.total` | Counter | `provider` |

### Métricas estándar

Micrometer auto-configuration expone métricas de JVM (heap, GC, threads), Tomcat (requests, sessions), HikariCP (pool de conexiones BD) y Spring MVC (latencia de endpoints HTTP).

**Endpoint Prometheus:** `GET /actuator/prometheus` (público).

---

## Trazabilidad MDC

### MdcPropagationFilter

Filtro que se ejecuta al inicio de cada request HTTP:

- Extrae o genera el `traceId` (header `X-Trace-Id` o UUID nuevo).
- Popula el MDC con `traceId`.
- El MDC se limpia al finalizar la request.

### Campos estructurados en Logback

`logback-spring.xml` usa `LogstashEncoder` de `logstash-logback-encoder`. Campos incluidos en cada línea de log JSON:

| Campo      | Origen                                  |
| ---------- | --------------------------------------- |
| `traceId`  | MDC                                     |
| `spanId`   | MDC                                     |
| `alertId`  | MDC (puesto por `AlertStreamPublisher`) |
| `workerId` | MDC (puesto por callbacks de workers)   |
| `channel`  | MDC                                     |
| `app`      | Propiedad fija de la aplicación         |

El `traceId` correlaciona logs entre Spring Boot y los workers Ktor: ambos propagan el mismo `traceId` en sus llamadas HTTP internas.

---

## Auditoría

La tabla `AuditLog` registra todas las operaciones privilegiadas. Ver [[manejo-excepciones|Manejo de excepciones — Auditoría AOP]].

Endpoint: `GET /api/admin/audit` — paginado, filtrable por `actor`, `action`, `entity`, `dateFrom`, `dateTo`.

---

## Endpoints Actuator expuestos

| Endpoint               | Acceso     |
| ---------------------- | ---------- |
| `/actuator/health`     | Público    |
| `/actuator/info`       | Público    |
| `/actuator/prometheus` | Público    |
| `/actuator/mappings`   | Público    |
| `/actuator/conditions` | Público    |
| `/actuator/**` (resto) | Solo ADMIN |

## Fuentes
