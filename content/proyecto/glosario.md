---
title: Glosario
description: Términos propios del proyecto Parallax Sports usados en toda la documentación.
tags: [proyecto, glosario]
---

# Glosario

| Término                     | Definición                                                                                                                                                                                                                    |
| --------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Alert artifact**          | Imagen PNG generada por ms-playwright para adjuntar a una alerta. Se almacena en Cloudinary y se reutiliza si el `render_context_hash` ya existe.                                                                             |
| **Artifact gating**         | Cuando `artifact_required=true`, el dispatch scheduler no publica la alerta en el stream hasta que el artefacto esté disponible (`artifact_id` no nulo).                                                                      |
| **Consumer group**          | Mecanismo de Redis Streams que permite que múltiples instancias de un worker compartan la carga de mensajes sin duplicarlos. Cada mensaje es entregado a exactamente un consumidor del grupo.                                 |
| **Dead Letter Queue (DLQ)** | Stream de Redis donde se depositan mensajes que han superado el máximo de reintentos y no pueden procesarse. Permite inspección manual sin perder datos.                                                                      |
| **Delivery mode**           | Forma en que el bot de Discord entrega la alerta: `DM` (mensaje directo al usuario) o `GUILD_CHANNEL` (canal configurado en el servidor).                                                                                     |
| **Event type**              | Subclasificación de un evento dentro de un deporte: `race`, `qualifying`, `match`, `session`, etc. Los usuarios pueden filtrar alertas por tipo.                                                                              |
| **External ID**             | Identificador del evento en el sistema origen (OpenF1, BallDontLie, PandaScore). Se usa como clave de deduplicación al sincronizar: si el `external_id` ya existe, se actualiza en lugar de crear una nueva fila.             |
| **Follow**                  | Declaración explícita de un usuario de que quiere seguir una competición o participante concreto. Distinto de `follow_all`, que es una suscripción implícita a todo un deporte.                                               |
| **Guild**                   | Servidor de Discord. La configuración de canal de alerta es por guild: cada servidor puede tener un canal por defecto y canales específicos por deporte.                                                                      |
| **HttpOnly cookie**         | Cookie que el navegador no expone a JavaScript (`document.cookie`). Usada para transportar los tokens JWT de acceso y refresco de forma segura.                                                                               |
| **Idempotency key**         | Clave única que identifica una alerta concreta (usuario + evento + canal + lead time). Evita crear filas duplicadas si el scheduler se ejecuta dos veces sobre el mismo evento.                                               |
| **JTI** (JWT ID)            | Campo `jti` del token JWT: UUID único por token. Se usa como clave en la blacklist de Redis para invalidar access tokens antes de su expiración natural.                                                                      |
| **Lead time**               | Margen en minutos antes del inicio del evento en que se envía la alerta. Configurable por el usuario por deporte y canal.                                                                                                     |
| **Render context hash**     | SHA-256 calculado sobre el ID del evento, el sport key, el estado y la zona horaria. Dos alertas con el mismo hash producirían la misma imagen → se reutiliza el artefacto existente.                                         |
| **Render hash**             | Ver _render context hash_. También es la cabecera `X-Render-Hash` que devuelve el endpoint `/api/internal/render/event/{id}` para que ms-playwright pueda verificar si la imagen ya existe en Cloudinary antes de renderizar. |
| **Redis Stream**            | Estructura de datos de Redis similar a un log append-only. Usado como cola de mensajes entre Spring (productor) y los microservicios Ktor (consumidores).                                                                     |
| **Schema version**          | Campo `schemaVersion=v1` en el payload del stream. Permite evolucionar el formato sin romper consumidores que aún no han sido desplegados.                                                                                    |
| **send_at_utc**             | Timestamp UTC calculado como `event.start_time_utc - lead_time_minutes`. El scheduler solo publica alertas cuyo `send_at_utc ≤ now()`.                                                                                        |
| **Sport key**               | Identificador textual único de un deporte en el sistema: `formula1`, `nba`, `wnba`, `esports-lol`, `esports-cs2`, `esports-dota2`, `esports-valorant`, `esports-overwatch`.                                                   |
| **Stream consumer**         | Instancia de `RedisStreamConsumer` (clase abstracta en `common`) que hace poll continuo sobre un stream de Redis con `XREADGROUP`.                                                                                            |
| **Worker**                  | Microservicio Ktor que consume un stream de alertas y las entrega a un proveedor externo (Discord, Gmail).                                                                                                                    |
| **XACK + XDEL**             | Comandos Redis para confirmar que un mensaje ha sido procesado (`XACK`) y eliminarlo del stream (`XDEL`). Se ejecutan _antes_ de enviar el callback a Spring para no bloquear el loop en caso de que el callback falle.       |

## Fuentes
