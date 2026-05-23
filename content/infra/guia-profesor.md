---
title: Guía para el profesor
description: "Guía de despliegue rápido de Parallax Sports para evaluadores: arrancar el proyecto completo desde Docker Hub sin necesidad de compilar."
tags: [infra, docker, devops, evaluacion]
---

# Guía para el profesor

Pasos para levantar Parallax Sports completo desde Docker Hub, sin necesidad de compilar código ni conocer el entorno de desarrollo.

## Prerequisitos

- Docker Engine >= 24
- Docker Compose v2 (`docker compose version` — sin guión)
- ~4 GB RAM libre, ~10 GB disco libre
- No se necesita cuenta de Docker Hub (imágenes públicas bajo `diegokoes/`)

## Pasos

### 1. Clonar el repositorio de infraestructura

```bash
git clone https://github.com/TFG-Avellaneda-25-26/parallax-sports-infra.git
cd parallax-sports-infra
```

### 2. Configurar el fichero .env

```bash
cp .env.teacher.example .env
```

Editar `.env` con un editor de texto:

```env
POSTGRES_USER=parallax
POSTGRES_PASSWORD=<contraseña segura>
POSTGRES_DB=parallax

GRAFANA_ADMIN_PASSWORD=<contraseña para Grafana>

# IP de tu máquina (no localhost si otros dispositivos acceden)
FRONTEND_URL=http://TU_IP_AQUI

# Ruta ABSOLUTA al directorio loadtests/ de este repo
LOADTEST_SCRIPTS_PATH=/ruta/al/repo/parallax-sports-infra/loadtests
```

### 3. Arrancar todos los servicios

```bash
docker compose -f docker-compose.teacher.yml up -d
```

Docker descargará automáticamente las imágenes de Docker Hub (~3-5 min según conexión).

### 4. Verificar que todo está running

```bash
docker compose -f docker-compose.teacher.yml ps
```

Todos los servicios deben mostrar `healthy` o `running`.

## Servicios disponibles

| Servicio      | URL                               | Credenciales                              |
| ------------- | --------------------------------- | ----------------------------------------- |
| SPA (Angular) | http://TU_IP:80                   | Registro en la propia app                 |
| API (Spring)  | http://TU_IP:8080/swagger-ui.html | —                                         |
| Grafana       | http://TU_IP:3000                 | admin / (GRAFANA_ADMIN_PASSWORD del .env) |
| Prometheus    | http://TU_IP:9090                 | —                                         |
| Alertmanager  | http://TU_IP:9093                 | —                                         |

## Load tests (opcional)

Para ejecutar los tests de carga con k6:

```bash
docker compose -f docker-compose.teacher.yml --profile loadtest up -d k6
# Ejecutar un escenario concreto:
docker exec k6 k6 run /scripts/auth_smoke.js
```

Escenarios disponibles en `loadtests/`:

| Escenario                    | Fichero                       |
| ---------------------------- | ----------------------------- |
| Smoke de autenticación       | `auth_smoke.js`               |
| Stress de login              | `auth_login_stress.js`        |
| Stress de lectura de eventos | `events_read_stress.js`       |
| Stress de follows            | `follows_write_stress.js`     |
| Pipeline de alertas e2e      | `alerts_pipeline_e2e.js`      |
| Aislamiento de streams       | `alerts_stream_isolated.js`   |
| Stress de blacklist JWT      | `jwt_blacklist_stress.js`     |
| Stress de render Playwright  | `playwright_render_stress.js` |
| Recuperación tras spike      | `spike_recovery.js`           |

## Parar

```bash
docker compose -f docker-compose.teacher.yml down
# Para eliminar también volúmenes de datos:
docker compose -f docker-compose.teacher.yml down -v
```

## Para el desarrollador — subir imágenes a Docker Hub

Las imágenes se construyen en Jenkins y se pushean al registry local (`localhost:5000`). Para publicarlas en Docker Hub (necesario antes de la evaluación):

```bash
# Login (una vez)
docker login

# Para cada imagen:
docker tag localhost:5000/parallax-spring:latest diegokoes/parallax-spring:latest
docker push diegokoes/parallax-spring:latest

docker tag localhost:5000/parallax-angular:latest diegokoes/parallax-angular:latest
docker push diegokoes/parallax-angular:latest

docker tag localhost:5000/parallax-ms-discord:latest diegokoes/parallax-ms-discord:latest
docker push diegokoes/parallax-ms-discord:latest

docker tag localhost:5000/parallax-ms-email:latest diegokoes/parallax-ms-email:latest
docker push diegokoes/parallax-ms-email:latest

docker tag localhost:5000/parallax-ms-cloudinary:latest diegokoes/parallax-ms-cloudinary:latest
docker push diegokoes/parallax-ms-cloudinary:latest

docker tag localhost:5000/parallax-ms-playwright:latest diegokoes/parallax-ms-playwright:latest
docker push diegokoes/parallax-ms-playwright:latest
```

Ver también [[ci-cd|CI/CD con Jenkins]] para el flujo de build completo.

## Fuentes
