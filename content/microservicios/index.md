---
title: Microservicios
description: Índice de los microservicios Ktor que componen la capa de notificaciones de Parallax Sports.
tags:
  - microservicios
  - ktor
---

Los microservicios de Parallax Sports están implementados en Kotlin con el framework Ktor y se despliegan como contenedores independientes. Gestionan el envío de alertas a través de distintos canales y operaciones auxiliares como la captura de pantallas y el almacenamiento de imágenes.

## Páginas de esta sección

- [[arquitectura|Arquitectura común]]: Estructura multi-módulo Gradle, stack tecnológico, puertos y módulo `common`
- [[redis-stream-consumer|RedisStreamConsumer]]: Clase base abstracta del loop de consumo de streams
- [[ms-discord|ms-discord]]: Bot de Discord y consumidor de alertas con soporte multi-guild
- [[ms-email|ms-email]]: Envío de alertas por correo electrónico vía Gmail API
- [[ms-cloudinary|ms-cloudinary]]: Almacenamiento y verificación de imágenes en Cloudinary
- [[ms-playwright|ms-playwright]]: Renderizado de capturas de pantalla con Chromium headless

> **Nota:** El microservicio `ms-telegram` existe únicamente como binario compilado en el directorio `bin/` y no forma parte del proyecto Gradle activo. No está documentado en esta sección.

## Fuentes
