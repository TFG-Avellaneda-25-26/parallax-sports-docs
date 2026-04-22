---
title: Bienvenid@
description: "Documentación del proyecto Parallax Sports, un dashboard personalizable de eventos deportivos con envío de alertas por múltiples canales"
---

# Parallax Sports

> [!tip] Empieza aquí
> Si es tu primera vez leyendo esta documentación, comienza por [[architecture-overview|Visión General de la Arquitectura]] para ver cómo encaja todo y luego explora el stack que más te interese.

## Secciones

- **[[project/index|Proyecto]]** - La visión general: qué hace la plataforma, el stack tecnológico, el modelo de dominio y un glosario de términos usados en toda la documentación.

- **[[backend/index|Backend]]** - La API de Spring Boot: autenticación, sincronización de datos desde APIs deportivas externas, ciclo de vida de alertas, manejo de excepciones y observabilidad.

- **[[frontend/index|Frontend]]** - El dashboard en Angular: arquitectura Feature-Sliced Design, routing, gestión de estado y animaciones parallax.

- **[[microservices/index|Microservicios]]** - Los workers de alertas en Ktor: bot de Discord, correo mediante Gmail, bot de Telegram, generación de capturas con Playwright y almacenamiento de imágenes en Cloudinary.

- **[[infra/index|Infraestructura]]** - Despliegue autohospedado: Docker Compose, proxy inverso con Traefik, Redis, stack de observabilidad (Prometheus + Loki + Grafana) y CI/CD.

- **[[flows/index|Flujos]]** - Cómo se conecta todo: flujos end-to-end que atraviesan múltiples sistemas, desde el envío de alertas hasta el registro de usuarios y la sincronización de datos.

- **[[journal/index|Diario]]** - El lado humano: el equipo, la línea temporal, decisiones de arquitectura, dificultades, mejoras pendientes y cómo se usaron herramientas de IA.

- **[[guides/index|Guías]]** - Guías prácticas: configuración local, cómo contribuir y estándares de documentación de código.
