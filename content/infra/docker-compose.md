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

- `registry:2`: Docker Registry local en el puerto 5000 para las imágenes construidas por Jenkins
- `jenkins`: CI/CD; monta `/var/run/docker.sock` y `/opt/stack`; puerto 8090
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

| Servicio            | Config montada                                                      | Puerto |
| ------------------- | ------------------------------------------------------------------- | ------ |
| `loki`              | `./loki/loki-config.yml`                                            | 3100   |
| `prometheus`        | `./prometheus/prometheus.yml`, `./prometheus/rules/`                | 9090   |
| `alloy`             | `./alloy/config.alloy`; accede al Docker socket (ro) para discovery | 12345  |
| `alertmanager`      | `./alertmanager/config.yml`                                         | 9093   |
| `grafana`           | `./grafana/provisioning/`                                           | 3000   |
| `cadvisor`          | Sin config; monta `/`, `/sys`, `/var/lib/docker` (ro)               | 8081   |
| `node-exporter`     | Sin config; monta `/host` (ro)                                      | 9100   |
| `postgres-exporter` | Sin config; cadena de conexión via `DATA_SOURCE_NAME`               | 9187   |
| `redis-exporter`    | Sin config; dirección via `--redis.addr`                            | 9121   |

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

## Perfiles (`docker-compose.yml` dev)

El compose de desarrollo usa [Docker Compose profiles](https://docs.docker.com/compose/profiles/) para poder levantar solo la infraestructura sin las apps, lo habitual en desarrollo local donde las apps corren directamente en la JVM/Node.

| Perfil      | Servicios incluidos                                                      | Caso de uso                                 |
| ----------- | ------------------------------------------------------------------------ | ------------------------------------------- |
| _(ninguno)_ | postgres, redis, toda la observabilidad, cloudflared                     | Infra sola para dev local                   |
| `apps`      | spring-boot, ms-discord, ms-email, ms-cloudinary, ms-playwright, angular | Despliegue completo desde el registry local |
| `loadtest`  | k6                                                                       | Tests de carga                              |

```bash
# Solo infraestructura (dev local — apps corren fuera de Docker)
docker compose up -d

# Infraestructura + apps (desde registry local en :5000)
docker compose --profile apps up -d

# Todo incluyendo k6
docker compose --profile apps --profile loadtest up -d
```

En `docker-compose.teacher.yml` los servicios de app no tienen perfil, así que siempre arrancan con `up -d`.

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
