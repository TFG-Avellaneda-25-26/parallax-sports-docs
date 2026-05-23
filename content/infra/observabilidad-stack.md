---
title: Stack de observabilidad
description: "Grafana Alloy, Prometheus, Loki, Grafana, Alertmanager y exporters: configuración y responsabilidades de cada componente."
tags: [infra, observabilidad, prometheus, loki, grafana]
---

# Stack de observabilidad

## Grafana Alloy (colector)

- Recolecta logs de contenedores Docker vía `/var/run/docker.sock` (montado en solo lectura)
- Reenvía logs estructurados en JSON a Loki
- Scrapes de métricas Prometheus desde todos los servicios
- Configuración: `alloy/config.alloy`
- Puerto UI de Alloy: **12345**

## Prometheus

- **Targets de scrape:** Spring (`/actuator/prometheus`), ms-discord / ms-email / ms-cloudinary / ms-playwright (`/metrics`), cAdvisor, node-exporter, postgres-exporter, redis-exporter
- **Remote write receiver** habilitado (k6 envía métricas de carga directamente)
- **Retención:** 30 días
- **Reglas:** `prometheus/rules/alerts.yml` + `prometheus/rules/recording.yml`
- Puerto: **9090**

## Loki

- Recibe logs estructurados en JSON enviados por Alloy
- Configuración: `loki/loki-config.yml`
- Puerto: **3100**
- Campos MDC indexados: `traceId`, `alertId`, `workerId`, `channel`, `app` (`SERVICE_NAME`)

## Grafana

Dashboards provisionados automáticamente (sin configuración manual):

| Dashboard              | Contenido                                                |
| ---------------------- | -------------------------------------------------------- |
| `overview.json`        | Métricas generales del sistema                           |
| `auth-security.json`   | Registros, logins, token refreshes, detecciones de reuse |
| `alerts-pipeline.json` | Latencia del pipeline de alertas por canal               |
| `logs-explorer.json`   | Explorador de logs con filtros                           |

- Datasources provisionados: Prometheus + Loki
- Puerto: **3000**
- Usuario admin: `admin`, contraseña en `.env` → `GRAFANA_ADMIN_PASSWORD`

## Alertmanager

- Configuración: `alertmanager/config.yml`
- Recibe alertas disparadas por las reglas de Prometheus
- Puerto: **9093**

## Exporters

| Exporter          | Puerto | Qué mide                                 |
| ----------------- | ------ | ---------------------------------------- |
| cAdvisor          | 8081   | CPU, memoria y red por contenedor Docker |
| node-exporter     | 9100   | CPU, memoria, disco y red del host       |
| postgres-exporter | 9187   | Queries, conexiones, locks, replicación  |
| redis-exporter    | 9121   | Comandos, memoria, streams, keyspace     |

## Load tests (k6)

- k6 envía métricas via remote write a Prometheus (variable `PROM_RW_URL`)
- El `LoadTestRunnerService` de Spring inicia contenedores k6 mediante la API docker-java
- Scripts en `loadtests/` del [[guia-profesor|repositorio de infra]]

## Fuentes
