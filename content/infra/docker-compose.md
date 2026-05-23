---
title: Docker Compose
description: "Estructura anotada del docker-compose.yml: red, servicios, diferencias entre entorno dev y teacher, healthchecks y volúmenes."
tags: [infra, docker, devops]
---

# Docker Compose

## Red

Única red bridge `stack`. Todos los servicios se comunican por nombre de contenedor dentro de esta red.

## Diferencias dev vs. teacher

**`docker-compose.yml` (dev) incluye además:**

- `registry:2` — Docker Registry local en el puerto 5000 para las imágenes construidas por Jenkins
- `jenkins` — CI/CD; monta `/var/run/docker.sock` y `/opt/stack`; puerto 8090
- Los servicios de app se despliegan solo con `COMPOSE_PROFILES=apps` (perfil requerido)

**`docker-compose.teacher.yml` (evaluación):**

- Sin registry ni Jenkins (no hace CI/CD)
- Apps siempre activas (sin perfil)
- Imágenes desde Docker Hub `diegokoes/`
- `.env` simplificado: solo `POSTGRES_*`, `GRAFANA_ADMIN_PASSWORD`, `FRONTEND_URL`, `LOADTEST_SCRIPTS_PATH`

## Bases de datos

**postgres (`postgres:16-alpine`)**

- Credenciales desde `.env`: `POSTGRES_USER` / `PASSWORD` / `DB`
- Volumen: `./data/postgres`
- Healthcheck: `pg_isready`

**redis (`redis:7-alpine`)**

- Comando: `--save 60 1 --maxmemory 512mb --maxmemory-policy allkeys-lru`
- Volumen: `./data/redis`

## Observabilidad

| Servicio            | Config montada                                       | Puerto |
| ------------------- | ---------------------------------------------------- | ------ |
| `loki`              | `./loki/loki-config.yml`                             | 3100   |
| `prometheus`        | `./prometheus/prometheus.yml`, `./prometheus/rules/` | 9090   |
| `alloy`             | — accede al Docker socket (read-only) para discovery | 12345  |
| `alertmanager`      | `./alertmanager/config.yml`                          | 9093   |
| `grafana`           | `./grafana/provisioning/`                            | 3000   |
| `cadvisor`          | —                                                    | 8081   |
| `node-exporter`     | —                                                    | 9100   |
| `postgres-exporter` | —                                                    | 9187   |
| `redis-exporter`    | —                                                    | 9121   |

Prometheus tiene remote-write receiver habilitado y retención de 30 días. Grafana tiene dashboards provisionados automáticamente.

## Aplicaciones

En teacher siempre activas; en dev requieren perfil `apps`.

| Servicio        | Depende de                          | Variables relevantes                                                |
| --------------- | ----------------------------------- | ------------------------------------------------------------------- |
| `spring-boot`   | postgres (healthy), redis (healthy) | `SPRING_*`, `APP_*`; monta docker.sock para `LoadTestRunnerService` |
| `ms-discord`    | redis (healthy)                     | `SERVICE_NAME`, `REDIS_HOST/PORT`, `SPRING_BASE_URL`                |
| `ms-email`      | redis (healthy)                     | ídem                                                                |
| `ms-cloudinary` | —                                   | sin dependencia de Redis                                            |
| `ms-playwright` | —                                   | sin dependencia de Redis                                            |
| `angular`       | spring-boot (healthy)               | nginx SPA                                                           |

Healthcheck de `spring-boot`: `GET /actuator/health`.

## Healthchecks

Todos los servicios tienen healthcheck definido. Los servicios de app esperan a que postgres y redis estén `healthy` antes de arrancar.

## Volúmenes

El directorio `./data/` en el host contiene:

```
data/
├── postgres/
├── redis/
├── grafana/
├── loki/
├── prometheus/
├── alloy/
├── jenkins/
└── registry/
```

## Fuentes
