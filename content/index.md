---
title: Parallax Sports
description: "Documentación del proyecto Parallax Sports, un dashboard personalizable de eventos deportivos con envío de alertas por múltiples canales"
---

# Bienvenid@

> [!tip] Empieza aquí
> Si es tu primera vez leyendo esta documentación, comienza por [[architecture-overview|Visión General de la Arquitectura]] para ver cómo encaja todo y luego explora el stack que más te interese.

## Secciones

- **[[project/index|Proyecto]]** - Visión general: qué hace la plataforma, el stack, el modelo de dominio...

- **[[backend/index|Backend]]** - La API de Spring Boot: autenticación, sincronización de datos desde APIs deportivas externas, ciclo de vida de alertas, manejo de excepciones y observabilidad.

- **[[frontend/index|Frontend]]** - El dashboard en Angular: arquitectura Feature-Sliced Design, routing, gestión de estado y animaciones.

- **[[microservices/index|Microservicios]]** - Los workers de alertas en Ktor: bot de Discord, correo mediante Gmail, bot de Telegram, generación de capturas con Playwright y almacenamiento de imágenes en Cloudinary.

- **[[infra/index|Infraestructura]]** - Self hosting: Docker Compose, Traefik, Redis, stack de observabilidad (Prometheus + Loki + Grafana) y Jenkins.

- **[[flows/index|Flujos]]** - Cómo se conecta todo: flujos end-to-end que atraviesan múltiples sistemas, desde el envío de alertas hasta el registro de usuarios y la sincronización de datos.

- **[[journal/index|Diario]]** - Reflexión sobre nuestras decisiones y organización, incluyendo lo bueno y lo malo a lo largo del timeline de desarrollo. Uso de IA, aspectos a mejorar...
