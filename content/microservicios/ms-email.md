---
title: ms-email
description: Microservicio de envío de alertas por correo electrónico mediante Gmail API con OAuth2. Incluye gestión de tokens en Redis y plantillas Thymeleaf.
tags:
  - microservicios
  - email
  - gmail
  - oauth2
  - ktor
---

`ms-email` envía alertas de eventos deportivos a usuarios por correo electrónico usando la API de Gmail. Corre en el puerto **8084**.

## Stream consumer

- **Stream:** `alerts.email.v1`
- **Grupo:** `email-workers`
- `EmailAlertConsumer` extiende [[redis-stream-consumer|RedisStreamConsumer]].
- Antes de llamar a `sendToProvider`, obtiene un token de acceso válido con `googleTokenManager.getAccessToken()`.

## `GoogleTokenManager`

Gestiona los tokens OAuth2 de Google almacenándolos en Redis.

| Clave Redis                 | TTL        | Descripción                                                      |
| --------------------------- | ---------- | ---------------------------------------------------------------- |
| `auth:google:access_token`  | 55 minutos | Token de acceso (Google emite tokens de 60 min; 5 min de margen) |
| `auth:google:refresh_token` | Sin TTL    | Token de refresco permanente                                     |

- **`getAccessToken()`**: devuelve el token cacheado en Redis o llama a `refreshAccessToken()`.
- **`refreshAccessToken()`**: `POST https://oauth2.googleapis.com/token` con `grant_type=refresh_token`.
- **`initialExchange(code, redirectUri)`**: `POST` con `grant_type=authorization_code`; almacena el token de refresco y el de acceso en Redis.

```kotlin
data class GoogleTokenResponse(
    val access_token: String,
    val expires_in: Int,
    val refresh_token: String?,   // nulo en respuestas de refresco
    val token_type: String
)
```

## `EmailService`

### `sendEvent(message, accessToken, artifactUrl)`

1. Construye un `Context` de Thymeleaf con: `event` (EventDTO), `artifactUrl`, `localizedTime` (formateado con la zona horaria del usuario) y `timezone`.
2. Procesa la plantilla `event` → string HTML.
3. Llama a `sendGmail(to, subject, htmlBody, accessToken)`.

### `sendVerificationEmail(to, code, token)`

Procesa la plantilla `verification` y envía el correo de verificación de cuenta.

### `sendGmail(to, subject, htmlBody, accessToken)`

1. Codifica el mensaje MIME como Base64 URL-safe.
2. `POST https://gmail.googleapis.com/gmail/v1/users/me/messages/send`
3. Devuelve el ID de mensaje de Google.

## Routing HTTP

| Método | Ruta                      | Descripción                                                                                                |
| ------ | ------------------------- | ---------------------------------------------------------------------------------------------------------- |
| GET    | `/auth/google/login`      | Redirige al consentimiento OAuth de Google (scopes: `gmail.send`; `access_type=offline`, `prompt=consent`) |
| GET    | `/auth/callback?code=...` | Llama a `initialExchange`, almacena los tokens en Redis                                                    |
| POST   | `/internal/email/verify`  | Body: `{email, verificationCode}`: envía el correo de verificación                                        |

## Plantillas Thymeleaf

### `verification.html`

- Cabecera con color `#5865f2` (morado) y branding "Parallax Sports".
- Interpolación de `${code}`.
- Nota de caducidad a los 10 minutos.

### `event.html`

- Tema oscuro: fondo `#0f1115`, tarjeta `#16181f`.
- Imagen del artefacto opcional.
- Campos: nombre del evento, competición, hora localizada + zona horaria, tipo de evento, ID de alerta en el footer.

## Configuración (`application.conf`)

| Clave                | Valor por defecto                                              |
| -------------------- | -------------------------------------------------------------- |
| Puerto               | 8084                                                           |
| `email.from`         | `"ParallaxSports"`                                             |
| `oauth.redirect-uri` | `http://localhost:8084/auth/callback` (sobreescrito en Docker) |

## Fuentes
