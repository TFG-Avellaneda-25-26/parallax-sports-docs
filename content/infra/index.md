---
title: Infraestructura
description: "Índice de la sección de infraestructura: despliegue, CI/CD, servicios y observabilidad de Parallax Sports."
tags: [infra, docker, devops]
---

# Infraestructura

Documentación de la infraestructura de Parallax Sports: contenedores, pipelines, bases de datos y observabilidad.

## Páginas

- [[despliegue|Guía de despliegue]] — Modos de despliegue: todo en Docker, desarrollo local y combinaciones mixtas.
- [[guia-profesor|Guía para el profesor]] — Pasos mínimos para arrancar el proyecto completo desde Docker Hub.
- [[docker-compose|Docker Compose]] — Anotaciones sobre la estructura del `docker-compose.yml` y sus variantes.
- [[ci-cd|CI/CD con Jenkins]] — Pipelines de Spring, Angular y Ktor: stages, secretos y estrategia de imágenes.
- [[redis|Redis]] — Configuración, pools y patrones de uso (blacklist JWT, OTP, streams de alertas).
- [[observabilidad-stack|Stack de observabilidad]] — Alloy, Prometheus, Loki, Grafana, Alertmanager y exporters.
- [[proxmox|Proxmox]] — Servidor físico y contenedor LXC donde corre toda la infraestructura.

## Fuentes
