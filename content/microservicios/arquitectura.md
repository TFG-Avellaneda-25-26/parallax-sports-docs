---
title: Arquitectura común de los microservicios
description: Estructura del proyecto Gradle multi-módulo, stack tecnológico, puertos por servicio y descripción del módulo common compartido por todos los microservicios.
tags:
  - microservicios
  - ktor
  - arquitectura
  - gradle
---

## Proyecto Gradle multi-módulo

El fichero `settings.gradle.kts` define los siguientes módulos:

```
:common
:ms-discord
:ms-email
:ms-cloudinary
:ms-playwright
```

`ms-telegram` existe como directorio `bin/` con un binario compilado pero **no forma parte del build de Gradle**.

## Stack tecnológico

| Componente          | Versión / Detalle                                            |
| ------------------- | ------------------------------------------------------------ |
| Kotlin              | 2.3.0                                                        |
| Ktor                | 3.4.1                                                        |
| Koin                | 4.1.1                                                        |
| JVM                 | 21                                                           |
| Redis (Lettuce)     | Solo `ms-discord` y `ms-email`                               |
| Motor HTTP          | CIO — 1000 conexiones máx., 100 por ruta                     |
| Serialización       | `kotlinx-serialization` JSON                                 |
| Métricas            | Micrometer + Prometheus                                      |
| Logs                | Logback + LogstashEncoder (JSON)                             |
| Motor de plantillas | Thymeleaf (`ConfigureEngine`, `ClassLoaderTemplateResolver`) |

## Puertos por servicio

| Servicio      | Puerto |
| ------------- | ------ |
| ms-discord    | 8082   |
| ms-email      | 8084   |
| ms-cloudinary | 8085   |
| ms-playwright | 8087   |

## Módulo `:common`

Código compartido por todos los servicios.

### Clase base

- `RedisStreamConsumer` — clase abstracta que implementa el loop de consumo de streams de Redis. Documentada en [[redis-stream-consumer]].

### Configuración (`AppConfig`)

Data classes de configuración cargadas desde `application.conf` y `shared-data.conf`:

- `DiscordConfig`
- `EmailConfig`
- `CloudinaryConfig`
- `PlaywrightConfig`
- `TelegramConfig`

### Módulos Koin (`ConfigModule`)

| Módulo Koin              | Descripción                                                                          |
| ------------------------ | ------------------------------------------------------------------------------------ |
| `discordConfigModule`    | Configuración de Discord                                                             |
| `emailConfigModule`      | Configuración de Gmail OAuth                                                         |
| `cloudinaryConfigModule` | Credenciales de Cloudinary                                                           |
| `playwrightConfigModule` | URL base de ms-playwright                                                            |
| `redisModule`            | `RedisClient` construido desde `parallaxbot.redis.url`                               |
| `networkModule`          | `HttpClient` con `UrlBasedAuthPlugin` que inyecta `X-Api-Key` en peticiones a Spring |

### Clientes HTTP compartidos

- `NetworkModule` — `HttpClient` CIO compartido.
- `PlaywrightClient` — realiza `POST /api/internal/screenshot` contra ms-playwright en la URL configurada.
- `SpringCallbackService` — llama a Spring en `http://localhost:8080` por defecto. En Docker, `shared-data.conf` sobreescribe la URL mediante la variable de entorno `SPRING_BASE_URL` (configurada como `http://spring-boot:8080` en `docker-compose.teacher.yml`).

### DTOs

| DTO                       | Descripción                                         |
| ------------------------- | --------------------------------------------------- |
| `AlertStreamMessage`      | Mensaje leído del stream de Redis                   |
| `AlertStatusCallback`     | Payload enviado a Spring con el resultado del envío |
| `EventDTO`                | Datos del evento deportivo                          |
| `PlaywrightResponse`      | Respuesta de ms-playwright (url del artefacto)      |
| `CloudinaryCheckResponse` | Respuesta de ms-cloudinary al verificar existencia  |
| `UploadResponse`          | Respuesta de ms-cloudinary tras subir imagen        |

### Utilidades

- `MapToDTO` — convierte el `Map<String, String>` de un mensaje de stream en `AlertStreamMessage`.
- `StreamConsumerMetrics` — contadores y timers Micrometer del loop de consumo.
- `MdcContext` — establece los campos MDC `alertId`, `workerId`, `channel` y `traceId` por mensaje procesado.

### Observabilidad

- `HealthModule` — rutas `/health` y `/health/ready`.
- `MetricsModule` — endpoint `/metrics` en formato Prometheus.
- Logs estructurados en JSON vía LogstashEncoder. El campo `app` se toma de la variable de entorno `SERVICE_NAME`.

## Patrón de inicio (`Application.kt`)

Todos los servicios siguen el mismo patrón de arranque:

1. Instalar `MicrometerMetrics`, `HealthModule`, `ContentNegotiation(JSON)` y `Koin`.
2. Inicializar el recurso específico del proveedor (bot JDA / browser Playwright / SDK de Cloudinary).
3. Inyectar y lanzar el consumidor en un `CoroutineScope(Dispatchers.Default)`.
4. Registrar `ApplicationStopped` → shutdown graceful.

## Fuentes
