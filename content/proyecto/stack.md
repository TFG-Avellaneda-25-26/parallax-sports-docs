---
title: Stack tecnológico
description: Tabla completa de tecnologías con versiones exactas y razón de cada elección.
tags: [proyecto, stack]
---

# Stack tecnológico

## Backend: Spring Boot

| Tecnología                                | Versión        | Rol                                           |
| ----------------------------------------- | -------------- | --------------------------------------------- |
| Java                                      | 21             | Lenguaje principal, LTS con virtual threads   |
| Spring Boot                               | 4.0.4          | Framework base                                |
| Spring Framework                          | 7.0.6          | Núcleo                                        |
| Spring Security                           | 7.0.4          | Autenticación y autorización                  |
| Spring Data JPA / Hibernate               | (boot-managed) | ORM + acceso a PostgreSQL                     |
| Spring Data Redis (Lettuce)               | (boot-managed) | Pool de conexiones Redis                      |
| Spring OAuth2 Client                      | (boot-managed) | Login con Google y Discord                    |
| Tomcat                                    | 11.0.21        | Servidor embebido                             |
| JJWT                                      | 0.13.0         | Generación y validación de tokens JWT (HS256) |
| springdoc-openapi                         | 3.0.3          | Swagger UI / OpenAPI 3                        |
| Micrometer + Prometheus Registry          | (boot-managed) | Exportación de métricas                       |
| Micrometer Tracing (OpenTelemetry bridge) | (boot-managed) | Propagación de traceId en MDC                 |
| Logstash Logback Encoder                  | 9.0            | Logs en formato JSON para Loki                |
| Thymeleaf                                 | (boot-managed) | Renderizado de HTML para alertas              |
| Docker Java                               | 3.7.1          | Control de contenedores k6 desde Spring       |
| PostgreSQL JDBC                           | (runtime)      | Driver                                        |
| Lombok                                    | (provided)     | Reducción de boilerplate                      |

## Microservicios Ktor

| Tecnología                   | Versión        | Rol                                                 |
| ---------------------------- | -------------- | --------------------------------------------------- |
| Kotlin                       | 2.3.0          | Lenguaje                                            |
| Ktor (server + client)       | 3.4.1          | Framework HTTP                                      |
| Koin                         | 4.1.1          | Inyección de dependencias                           |
| Kotlinx Serialization (JSON) | (ktor-managed) | Serialización                                       |
| Lettuce (Redis)              | (ktor-managed) | Cliente Redis para Streams                          |
| JVM                          | 21             | Runtime                                             |
| Playwright (Java)            | 1.58.0         | Automatización de Chromium headless (ms-playwright) |
| JDA (Java Discord API)       | (latest)       | Cliente Discord (ms-discord)                        |
| Cloudinary Java SDK          | (latest)       | Upload/gestión de imágenes (ms-cloudinary)          |
| Thymeleaf                    | (ktor-managed) | Templates HTML para emails y render de alertas      |
| Micrometer + Prometheus      | (ktor-managed) | Métricas por microservicio                          |
| Logstash Logback Encoder     | (ktor-managed) | Logs JSON                                           |

## Frontend: Angular

| Tecnología                | Versión           | Rol                                                                         |
| ------------------------- | ----------------- | --------------------------------------------------------------------------- |
| Angular                   | 21.2.x            | Framework SPA                                                               |
| @ngrx/signals             | 21.1.0            | Gestión de estado basada en señales                                         |
| @angular/forms/signals    | (angular-managed) | Formularios reactivos con señales                                           |
| GSAP                      | 3.14.2            | Animaciones (MorphSVG, DrawSVG, SplitText, Flip, ScrollTrigger, TextPlugin) |
| @js-temporal/polyfill     | latest            | Temporal API para manejo de fechas                                          |
| @vvo/tzdb                 | latest            | Base de datos de zonas horarias                                             |
| ng-otp-input              | latest            | Componente OTP para verificación de email                                   |
| browser-image-compression | latest            | Compresión de imágenes en cliente                                           |
| Sheriff                   | latest            | Enforcement de límites de importación FSD con ESLint                        |
| TypeScript                | 5.x               | Lenguaje                                                                    |

## Infraestructura

| Tecnología         | Versión             | Rol                                                            |
| ------------------ | ------------------- | -------------------------------------------------------------- |
| Docker Engine      | ≥ 24                | Contenedores                                                   |
| Docker Compose v2  | latest              | Orquestación local                                             |
| PostgreSQL         | 16-alpine           | Base de datos principal                                        |
| Redis              | 7-alpine            | Streams de alertas, caché JWT y tokens OAuth                   |
| Nginx              | alpine              | Servidor estático y reverse proxy para Angular                 |
| Grafana            | latest              | Dashboards de observabilidad                                   |
| Prometheus         | latest              | Scrape y almacenamiento de métricas (30d retención)            |
| Grafana Loki       | latest              | Logs agregados                                                 |
| Grafana Alloy      | latest              | Colector de logs y métricas (reemplaza Promtail + Agent)       |
| Alertmanager       | latest              | Reglas de alerta sobre métricas                                |
| cAdvisor           | latest              | Métricas de contenedores                                       |
| node-exporter      | latest              | Métricas del host                                              |
| postgres-exporter  | latest              | Métricas de PostgreSQL                                         |
| redis-exporter     | latest              | Métricas de Redis                                              |
| Jenkins            | (custom Dockerfile) | CI/CD: build, push y deploy de los tres repos                  |
| Docker Registry v2 | (dev only)          | Registro local de imágenes en el LXC                           |
| Docker Hub         |:                   | Registro de imágenes para evaluadores (`diegokoes/parallax-*`) |
| Proxmox VE         |:                   | Hipervisor del servidor físico                                 |
| LXC                |:                   | Contenedor Linux donde corre toda la infraestructura           |

## Fuentes
