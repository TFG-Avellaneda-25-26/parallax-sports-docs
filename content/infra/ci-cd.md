---
title: CI/CD con Jenkins
description: "Pipelines de Jenkins para Spring, Angular y Ktor: stages, gestión de secretos con git-crypt y estrategia de imágenes Docker."
tags: [infra, ci-cd, jenkins, docker]
---

# CI/CD con Jenkins

## Jenkins

- Corre en Docker en el LXC, con `/var/run/docker.sock` y `/opt/stack` montados
- Imagen personalizada (`jenkins/Dockerfile`) con git-crypt, Docker CLI y herramientas necesarias
- Accesible en el puerto **8090**
- Credencial `gitcrypt-ktor`: clave simétrica para el repo de Ktor
- Credencial `062f57c8-aae6-4a78-90ed-b159c33a51d7`: clave simétrica para el repo de Spring

## Pipeline Spring (`parallax-sports-spring/Jenkinsfile`)

| Stage                | Qué hace                                                                                         |
| -------------------- | ------------------------------------------------------------------------------------------------ |
| `Checkout`           | `checkout scm`                                                                                   |
| `Decrypt secrets`    | `git-crypt unlock "$GC_KEY"` → verifica que `api-secrets.yml` es texto plano                     |
| `Build jar`          | `./mvnw -B -ntp clean package -DskipTests`                                                       |
| `Build Docker image` | `docker build -t localhost:5000/parallax-spring:latest -t ...:${BUILD_NUMBER} .`                 |
| `Push to registry`   | Push de ambos tags a `localhost:5000`                                                            |
| `Deploy`             | `COMPOSE_PROFILES=apps docker compose pull spring-boot` + `up -d --force-recreate --pull=always` |

**Post:** siempre `rm -f src/main/resources/api-secrets.yml` + `cleanWs()`

**Estrategia de secretos:** Jenkins desencripta `api-secrets.yml` **antes** del `docker build` → se copia con `COPY` en la imagen. En runtime: `--spring.config.import=optional:file:/app/config/api-secrets.yml`.

## Pipeline Angular (`parallax-sports-angular/Jenkinsfile`)

| Stage                | Qué hace                                                                     |
| -------------------- | ---------------------------------------------------------------------------- |
| `Checkout`           | `checkout scm`                                                               |
| `Build Docker image` | Dockerfile multi-stage: `npm ci` + `npx ng build` dentro de `node:22-alpine` |
| `Push to registry`   | Push a `localhost:5000`                                                      |
| `Deploy`             | `COMPOSE_PROFILES=apps` pull + force-recreate angular                        |

Sin secretos que desencriptar. Angular hace peticiones mismo-origen (nginx proxifica `/api/`).

## Pipeline Ktor (`parallax-sports-ktor-microservices/Jenkinsfile`)

Variables de entorno: `SERVICES = 'ms-discord ms-email ms-cloudinary'`, `PLAYWRIGHT_SVC = 'ms-playwright'`

| Stage                 | Qué hace                                                                                                                                               |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `Checkout`            | `checkout scm`                                                                                                                                         |
| `Decrypt secrets`     | `git-crypt unlock "$GC_KEY"` → verifica que `application-secrets.conf` es texto plano                                                                  |
| `Build distributions` | `./gradlew clean installDist --no-daemon -x test`                                                                                                      |
| `Build & push images` | 3 servicios estándar: `docker build --build-arg SERVICE={svc} ...`; ms-playwright: `docker build -f Dockerfile.playwright ...`; push de las 4 imágenes |
| `Deploy`              | Pull + force-recreate de los 4 servicios vía compose                                                                                                   |

**Post:** siempre `find . -name "application-secrets.conf" ... -delete` + `find . -name "shared-secrets.conf" ... -delete` + `cleanWs()`

**Estrategia de secretos:** igual que Spring: los secretos se embeben en la distribución `installDist` antes del `docker build`. El `Dockerfile` compartido usa `--build-arg SERVICE=ms-discord`. `ms-playwright` usa `Dockerfile.playwright` separado.

## Registry local vs Docker Hub

- Jenkins pushea a `localhost:5000` (registry local en el LXC)
- Para publicar en Docker Hub para la evaluación del profesor: taggear y pushear manualmente (ver [[guia-profesor]])

## Fuentes
