---
title: Parallax Sports
description: "Documentación del proyecto Parallax Sports, un dashboard personalizable de eventos deportivos con envío de alertas por múltiples canales"
---

# BIENVENID@!

> [!tip] Empieza aquí
> Si es tu primera vez leyendo esta documentación, comienza por ganar una [[proyecto/arquitectura|visión general de la arquitectura]] del proyecto para ver cómo encaja todo y luego explora el stack que más te interese.

## SECCIONES

- **[[proyecto/index|Proyecto]]**: Visión general: qué hace la plataforma, arquitectura, stack tecnológico y modelo de dominio.

- **[[backend/index|Backend]]**: La API de Spring Boot: autenticación, sincronización de datos deportivos externos, ciclo de vida de alertas, manejo de excepciones y observabilidad.

- **[[frontend/index|Frontend]]**: El dashboard en Angular: arquitectura Feature-Sliced Design, routing, gestión de estado, formularios signal y animaciones.

- **[[microservicios/index|Microservicios]]**: Workers de alertas en Ktor: bot de Discord, correo por Gmail, capturas con Playwright e imágenes en Cloudinary.

- **[[infra/index|Infraestructura]]**: Self-hosting en Proxmox/LXC: Docker Compose, Redis, stack de observabilidad (Prometheus + Loki + Grafana) y Jenkins.

- **[[flujos/index|Flujos]]**: Flujos end-to-end: entrega de alertas, pipeline de artefactos, registro de usuario, sincronización de datos y OAuth Discord.

- **[[diario/index|Diario]]**: Proceso de desarrollo: dificultades, mejorasy uso de IA.
