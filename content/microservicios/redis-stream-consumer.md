---
title: RedisStreamConsumer
description: Clase base abstracta que implementa el loop de consumo de streams de Redis, el procesamiento de mensajes, la lógica de reintentos y las métricas de observabilidad.
tags:
  - microservicios
  - redis
  - streams
  - ktor
---

`RedisStreamConsumer` es la clase abstracta del módulo `:common` que todos los consumidores de alertas extienden. Encapsula el loop de polling, el enrutado al proveedor específico, el ACK/DEL en Redis, la comunicación con Spring y la lógica de reintentos.

## Loop `start()`

El método `start()` ejecuta un bucle continuo mientras `isRunning` sea `true`:

```
XREADGROUP GROUP {group} {workerId} BLOCK 5000 COUNT 3 STREAMS {stream} >
```

Por cada mensaje recibido se lanza una corrutina en `Dispatchers.Default` que llama a `processSingleMessage(id, body)`.

### `processSingleMessage(id, body)`

1. Convierte `body: Map<String, String>` → `AlertStreamMessage` mediante `MapToDTO`.
2. Establece el contexto MDC (`alertId`, `workerId`, `channel`, `traceId`) con `alertMdc(...)`.
3. Llama a `onMessageReceived(message)`.

## `onMessageReceived(message)`

Flujo principal de procesamiento de cada mensaje:

1. **Comprobar intentos:** si `attempts >= maxAttempts` → `handleFailureAndRetry(EXCEEDED)` y retorno.
2. **Obtener artefacto:** llama a `getArtifactIfNeeded(message)`.
3. **Enviar al proveedor:** llama al método abstracto `sendToProvider(message, artifactUrl)`.
4. **Éxito:**
   - **`XACK` + `XDEL`** el mensaje del stream. ← **Esto ocurre ANTES de llamar a Spring.**
   - Llama a `springCallbackService.reportStatus(sent, latencyMs)`.
5. **`ProviderPermanentFailureException(errorCode)`:**
   - **`XACK` + `XDEL`** inmediatamente (sin reintento).
   - Llama a `springCallbackService.reportStatus(failed_permanent, errorCode)`.
6. **Cualquier otra excepción** → `handleFailureAndRetry(error)`:
   - Espera 15 segundos.
   - Reinserta el mensaje en el stream con `attempts + 1` (nuevo mensaje con contador incrementado).
   - Llama a `springCallbackService.reportStatus(failed_retryable, errorCode)`.

> **CRÍTICO:** El ACK ocurre **antes** del callback a Spring, no después. Si el callback falla, el mensaje ya ha sido eliminado del stream y no se reprocesará.

## `getArtifactIfNeeded(message)`

- Devuelve `null` si `message.artifactRequired = false`.
- Limitado por un semáforo a **3 llamadas concurrentes** a Playwright.
- Zona horaria utilizada para el renderizado:
  - Canal **email**: `userTimezone ?: venueTimezone`
  - Resto de canales: `venueTimezone` únicamente
- Llama a `PlaywrightClient` → `POST /api/internal/screenshot` → devuelve la URL del artefacto.

## `stop()`

Establece `isRunning = false`. El loop termina al finalizar la iteración en curso.

## Métricas (`StreamConsumerMetrics`)

| Métrica                             | Tipo    | Etiquetas              |
| ----------------------------------- | ------- | ---------------------- |
| `stream.messages.consumed.total`    | Counter | stream, channel        |
| `stream.message.processing.seconds` | Timer   |:                      |
| `stream.message.retries.total`      | Counter |:                      |
| `stream.message.dropped.total`      | Counter |: (fallos permanentes) |
| `provider.send.seconds`             | Timer   | channel                |
| `artifact.fetch.seconds`            | Timer   |:                      |
| `callback.to.spring.total`          | Counter | status                 |
