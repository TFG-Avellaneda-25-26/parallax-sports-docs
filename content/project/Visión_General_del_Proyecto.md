---
title: Visión General del Proyecto
description: Documentación global de Parallax Sports, abarcando desde el frontend hasta la infraestructura y microservicios.
---

# Parallax Sports - Visión General de la Plataforma

Bienvenido a la documentación técnica principal del proyecto. Parallax Sports no es solo una página web, sino una plataforma completa orientada a la gestión y visualización de eventos deportivos, destacando por su potente sistema de envío de alertas personalizadas a través de múltiples canales (Discord, Telegram y Correo electrónico).

Este documento sirve como un "mapa" para entender cómo encajan todas las piezas de la plataforma antes de profundizar en el código de cada sección.

---

## 1. Descripción Global del Sistema

El objetivo de Parallax Sports es ofrecer a los usuarios un panel de control (dashboard) donde puedan seguir sus eventos deportivos favoritos. La plataforma se encarga de sincronizar datos en tiempo real desde APIs deportivas externas y, cuando ocurre un evento relevante, dispara alertas automáticas a las comunidades de los usuarios mediante diferentes bots.

Para que todo esto funcione de forma rápida y sin caídas, el sistema se ha dividido en varias partes independientes que se comunican entre sí.

---

## 2. Arquitectura y Componentes del Sistema

El proyecto está diseñado usando una arquitectura de microservicios y sistemas distribuidos. Se divide en cuatro grandes bloques:

### Frontend
Es la cara visible del proyecto. Es el panel de control interactivo donde los usuarios se registran, configuran qué deportes quieren seguir y asocian sus cuentas de Discord o Telegram.
- **Tecnologías:** Está construido íntegramente en Angular 21, utilizando una arquitectura estricta llamada Feature-Sliced Design (FSD) para no mezclar componentes. Para que vaya muy rápido y la pantalla no se quede congelada, utiliza la última tecnología de gestión de estado reactivo (@ngrx/signals).

### Backend
Es el servidor principal (la API) que gestiona toda la lógica de negocio central.
- **Tecnologías:** Está desarrollado en Java usando el framework Spring Boot.
- **Responsabilidades:** Se encarga de guardar de forma segura a los usuarios (autenticación), sincronizar constantemente la información de los partidos desde APIs deportivas externas, y gestionar el ciclo de vida de las alertas. También cuenta con un manejo avanzado de excepciones para que ningún error tumbe el servidor.

### Microservicios
En lugar de sobrecargar el servidor principal, las tareas pesadas de enviar notificaciones se han separado en pequeños programas independientes.
- **Tecnologías:** Construidos en Kotlin usando el framework Ktor.
- **Responsabilidades:** Tenemos un worker especializado en el Bot de Discord, otro para el Bot de Telegram y otro para el envío de correos mediante Gmail. Además, hay un servicio dedicado exclusivamente a generar capturas de pantalla automáticas (usando Playwright) y subirlas a la nube (Cloudinary) para adjuntarlas en las alertas.

### Infraestructura y DevOps
Para que todo el sistema anterior funcione de forma orquestada en un servidor real (Self-hosting), hemos montado una infraestructura profesional.
- **Despliegue:** Todo funciona dentro de contenedores gestionados por Docker Compose. Utilizamos Traefik como proxy inverso para dirigir el tráfico de internet a la parte correcta (al front o al back).
- **Rendimiento:** Usamos Redis para cachear datos y que las peticiones vayan mucho más rápido.
- **Automatización (CI/CD):** Tenemos un servidor Jenkins que, cada vez que subimos código a GitHub, compila y despliega la aplicación automáticamente sin que tengamos que hacer nada a mano.
- **Observabilidad:** Para saber si algo falla en tiempo real, contamos con un "stack" de monitorización compuesto por Prometheus, Loki y Grafana, que nos muestra gráficos del estado de la plataforma.

---

## 3. Flujo Principal de Trabajo

Para entender cómo se conecta todo, imagina este recorrido:
1. El **Backend (Spring Boot)** se conecta a una API externa y detecta que un partido acaba de terminar.
2. El servidor guarda el resultado y emite una orden de "Alerta".
3. El **Microservicio de capturas (Playwright)** recibe la orden, toma una foto del resultado y la sube a la nube.
4. Los **Workers (Ktor)** recogen esa foto y los datos del partido, y mandan los mensajes automáticamente al Discord y Telegram de los usuarios.
5. Mientras tanto, el usuario entra al **Frontend (Angular)** y puede ver todo su panel actualizado al instante con la información de los eventos.

---

## Información extra

Esta es la visión genérica. Si quieres ver cómo hemos programado cada una de estas piezas, dirígete a las secciones correspondientes de la wiki (Frontend, Backend, Microservicios o Infraestructura) donde detallamos el código, los patrones de diseño y los problemas que tuvimos que resolver.
