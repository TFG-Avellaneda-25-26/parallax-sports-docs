---
title: ms-playwright
description: Microservicio de renderizado de capturas de pantalla usando Chromium headless. Orquesta el pipeline completo de generación y caché de artefactos con Cloudinary.
tags:
  - microservicios
  - playwright
  - ktor
  - screenshots
---

`ms-playwright` renderiza tarjetas de eventos como imágenes PNG usando Chromium headless y orquesta el pipeline completo de generación y caché de artefactos. Corre en el puerto **8087**.

## Fuentes

- [Playwright: Introducción](https://playwright.dev/docs/intro)

---

## `PlaywrightService`

Inicializa Playwright al arrancar: `Playwright.create()` → `chromium().launch(headless=true)` → instancia `Browser`.

### `renderHtmlToImage(html: String): ByteArray`

1. Crea un nuevo contexto de navegador con viewport **1200×630**.
2. `page.setContent(html)`
3. `page.waitForLoadState()`
4. `page.waitForSelector(".card", VISIBLE, timeout=3s)`
5. Captura screenshot como PNG.
6. Devuelve `ByteArray`. En caso de fallo devuelve `ByteArray` vacío.

> **Resolución:** **1200×630 PNG**.

## Routing: `POST /api/internal/screenshot`

Recibe `ScreenshotRequest` (del módulo `:common`): `eventId`, `channel`, `timezone?`, `renderHash?`.

```
1. GET {cloudinaryBaseUrl}/check/{eventId}/{renderHash}
   → si encontrado: devolver PlaywrightResponse(success=true, url=cachedUrl)

2. GET {springRenderBaseUrl}/event/{eventId}?channel={channel}&tz={timezone}
   → leer cabecera X-Render-Hash de la respuesta como hash efectivo

3. playwrightService.renderHtmlToImage(htmlBody) → bytes PNG

4. POST {cloudinaryBaseUrl}/upload (multipart: file=bytes, eventId, hash)
   → devuelve UploadResponse

5. devolver PlaywrightResponse(success=true, url=uploadedUrl)
```

## Plantilla (`templates/event-card.html`)

Plantilla Thymeleaf con tema oscuro estilo esports.

| Campo renderizado | Origen              |
| ----------------- | ------------------- |
| Nombre del evento | `event.eventName`   |
| Equipo local      | `event.localTeam`   |
| Equipo visitante  | `event.visitorTeam` |
| Localización      | `event.location`    |

- CSS: `--primary-color: #ff0099`
- El CSS es idéntico al CSS estático de `ms-discord`.

## Configuración (`application.conf`)

| Clave                       | Valor                    |
| --------------------------- | ------------------------ |
| Puerto                      | 8087                     |
| URL base de ms-cloudinary   | Desde `shared-data.conf` |
| URL base de Spring (render) | Desde `shared-data.conf` |

No requiere `application-secrets.conf` (no maneja secretos propios).

## Docker

Utiliza `Dockerfile.playwright`, separado del `Dockerfile` de los demás servicios.

- **Imagen base:** `mcr.microsoft.com/playwright/java:v1.58.0-noble`: incluye los binarios de Chromium preinstalados.
- **Usuario de ejecución:** `pwuser`.
