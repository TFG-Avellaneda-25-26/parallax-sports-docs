---
title: Ciclo de Vida de las Alertas
description: Cómo se generan, programan, envían y rastrean las alertas de eventos deportivos en Parallax Sports.
tags:
  - backend
  - alertas
  - notificaciones
  - scheduler
---

# Ciclo de Vida de las Alertas

## 1. ¿Qué es una alerta?

Una alerta es un aviso personalizado que se envía a un usuario antes de que empiece un evento deportivo que le interesa.

Las alertas se pueden enviar por tres canales distintos: **Telegram**, **Discord** y **Email**. El usuario puede configurar por qué canal quiere recibir las alertas de cada deporte y con cuántos minutos de antelación quiere que le avisen.

---

## 2. Los estados de una alerta

Una alerta pasa por varios estados a lo largo de su vida:

```
scheduled ──────────────────────────────────────► queued
    │                                                 │
    │  (si necesita imagen adjunta)                  ▼
    ▼                                           processing
waiting_artifact                                     │
    │                                          ┌─────┴──────┐
    │ (imagen lista)                            ▼            ▼
    └──────────────► scheduled             sent       failed_retryable
                                                            │
                                               (máx intentos)
                                                            ▼
                                                   failed_permanent
                                                   
                         cancelled  (en cualquier momento)
```

| Estado | Significado |
|---|---|
| `scheduled` | La alerta está programada y esperando su hora de envío |
| `waiting_artifact` | Está esperando a que se genere una imagen/media adjunta |
| `queued` | Ha sido recogida por el scheduler y publicada en Redis para su envío |
| `processing` | El microservicio notificador la está procesando |
| `sent` | El mensaje fue entregado al destinatario |
| `failed_retryable` | El envío falló pero se puede reintentar |
| `failed_permanent` | Falló de forma definitiva (demasiados intentos o error irrecuperable) |
| `cancelled` | Cancelada antes o durante el envío |

---

## 3. Fase 1 — Generación de alertas

La generación ocurre justo después de que los eventos se importan desde las APIs externas. El `UserEventAlertGenerationService` recibe la lista de eventos recién guardados y determina qué usuarios deben recibir una alerta para cada uno.

**¿Qué usuarios son elegibles?**

Un usuario es elegible para recibir una alerta de un evento si se cumple alguna de estas condiciones:
1. Tiene activada la opción **"seguir todo"** para ese deporte y no ha puesto filtro de tipo de evento, o el tipo del evento coincide con su filtro.
2. Tiene un **follow explícito** a una competición o participante concreto que aparece en ese evento.

Para cada usuario elegible, se crea una alerta por cada canal que tenga configurado. Si el usuario no ha configurado ningún canal específico, se usa el canal por defecto del sistema (Telegram) con el tiempo de antelación por defecto.

Las alertas se crean con un sistema de **upsert idempotente**: si ya existe una alerta para la misma combinación de usuario + evento + canal + tiempo de antelación, se actualiza en lugar de crear un duplicado.

---

## 4. Fase 2 — Despacho de alertas

Cada **minuto**, el `UserEventAlertDispatchScheduler` comprueba si hay alertas cuya hora de envío (`send_at_utc`) ha llegado. Para cada canal (telegram, discord, email), reclama un lote de alertas pendientes y las publica en un **stream de Redis**, que actúa como cola de mensajes hacia el microservicio notificador (Ktor).

Este flujo de envío incluye:

- **Enriquecimiento del payload**: antes de publicar, se cargan en batch el evento y el usuario asociados a las alertas para adjuntar información en el mensaje.
- **Routing de Discord**: para alertas de Discord, el sistema resuelve a qué servidor/canal de Discord hay que enviar el mensaje según las preferencias del usuario.
- **Fallback HTTP**: si Redis no está disponible, el dispatcher intenta enviar la alerta directamente al microservicio Ktor por HTTP. Si este fallback también falla, la alerta queda en estado `failed_retryable`.
- **Política de reintentos**: los fallos retryables se reprograman con un backoff exponencial hasta un máximo de intentos configurable.

---

## 5. Fase 3 — Callbacks del microservicio

El microservicio Ktor (el que realmente envía los mensajes a Telegram, Discord o el servidor de correo) reporta el resultado de cada envío de vuelta al backend Spring mediante callbacks HTTP internos. El `AlertCallbackService` procesa estos callbacks:

- **Callback de estado**: informa si la alerta fue `sent`, `failed_retryable`, `failed_permanent` o está en `processing`. Se aplica la máquina de estados que valida que la transición sea legal.
- **Callback de artefacto**: cuando el microservicio ha generado una imagen para adjuntar a la alerta (por ejemplo, una tarjeta visual del evento), notifica al backend con la URL del archivo subido a Cloudinary. El backend asocia el artefacto a la alerta y, si estaba en `waiting_artifact`, la pasa a `scheduled`.

Todos los callbacks están protegidos por una **API key interna** que el microservicio debe incluir en la cabecera de la petición.

---

## 6. Registro de intentos de entrega

Por cada resultado terminal de un envío (éxito, fallo retryable o permanente), el sistema guarda una fila en la tabla `alert_delivery_attempts`. Esta tabla actúa como historial completo de todos los intentos de entrega: qué worker procesó la alerta, en qué stream de Redis estaba, cuánto tardó (`latency_ms`), qué error ocurrió, y qué ID le asignó el proveedor (por ejemplo, el ID del mensaje de Telegram).

Esto es fundamental para la depuración: si un usuario dice que no recibió una alerta, se puede consultar la tabla y ver exactamente qué pasó.
