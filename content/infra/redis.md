---
title: Redis
description: "Configuración de Redis en Parallax Sports: pool Lettuce, patrones de uso (blacklist JWT, OTP, streams de alertas) y consumer groups."
tags: [infra, redis, docker]
---

# Redis

## Fuentes

- [Spring Boot Redis Cache – Baeldung](https://www.baeldung.com/spring-boot-redis-cache)
- [Eliminar datos en Redis – Baeldung](https://www.baeldung.com/redis-delete-data)
- [Redis: Pub/Sub](https://redis.io/docs/latest/develop/pubsub/)

---

## Configuración (docker-compose)

```
redis-server --save 60 1 --loglevel warning --maxmemory 512mb --maxmemory-policy allkeys-lru
```

| Parámetro         | Valor | Efecto                                                                    |
| ----------------- | ----- | ------------------------------------------------------------------------- |
| `save 60 1`       | :     | Persiste en disco cada 60 s si ≥1 clave cambió                            |
| `maxmemory 512mb` | :     | Límite de memoria                                                         |
| `allkeys-lru`     | :     | Evicta claves menos usadas al llenarse (afecta caches, no datos críticos) |

## Pool Lettuce (Spring)

| Parámetro          | Valor         |
| ------------------ | ------------- |
| max-active         | 20 conexiones |
| max-idle           | 10            |
| min-idle           | 2             |
| max-wait           | 2000 ms       |
| Connection timeout | 2000 ms       |

## Usos en Spring

| Patrón de clave        | Tipo   | TTL                | Propósito                           |
| ---------------------- | ------ | ------------------ | ----------------------------------- |
| `jwt:blacklist:{jti}`  | String | Restante del token | Access token revocado               |
| `email-verify:{email}` | String | 10 min             | Código OTP de verificación de email |
| `alerts.discord.v1`    | Stream | :                  | Mensajes de alerta canal Discord    |
| `alerts.email.v1`      | Stream | :                  | Mensajes de alerta canal email      |
| `alerts.telegram.v1`   | Stream | :                  | Mensajes de alerta canal Telegram   |

Los streams se mantienen con `XTRIM MAXLEN 200000` tras cada publish.

## Usos en Ktor (ms-email)

| Clave                       | TTL     | Propósito               |
| --------------------------- | ------- | ----------------------- |
| `auth:google:access_token`  | 55 min  | Gmail API access token  |
| `auth:google:refresh_token` | Sin TTL | Gmail API refresh token |

## Consumer groups

| Stream               | Grupo              |
| -------------------- | ------------------ |
| `alerts.discord.v1`  | `discord-workers`  |
| `alerts.email.v1`    | `email-workers`    |
| `alerts.telegram.v1` | `telegram-workers` |
