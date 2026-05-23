---
title: Estructura del proyecto
description: Layout package-by-feature del backend Spring Boot de Parallax Sports y responsabilidad de cada módulo.
tags: [backend, arquitectura]
---

# Estructura del proyecto

El backend sigue el estilo **package-by-feature**: cada paquete encapsula su propio controller, DTO, servicio, repositorio y modelo. No hay paquetes horizontales globales salvo `core`.

## Árbol de paquetes

```
dev.parallaxsports/
├── ParallaxSportsApiApplication.java   (@EnableScheduling)
├── admin/         controller/ dto/ service/
├── audit/         annotation/ aspect/ controller/ dto/ model/ repository/ service/
├── auth/          client/ controller/ dto/ model/ repository/ security/ service/
├── bot/           controller/ dto/ filter/ service/
├── core/          config/ config/properties/ exception/ filter/ metrics/ security/ util/
├── external/      basketball/ formula1/ pandascore/ sync/
├── follow/        controller/ dto/ model/ repository/ service/
├── loadtest/      controller/ dto/ model/ repository/ service/
├── notification/  client/ controller/ discord/ dto/ event/ integration/ model/ repository/ service/ startup/
├── sport/         basketball/ event/ formula1/ model/ repository/
└── user/          controller/ dto/ model/ repository/ service/
```

## Módulos

### `admin`

Operaciones de administración: gestión de usuarios, inyección manual de eventos deportivos y triggers de sincronización.

Clases clave: `AdminUserController`, `AdminEventInjectionController`.

---

### `audit`

Registro de auditoría de operaciones privilegiadas mediante AOP.

- `@Audited` — anotación que marca métodos a auditar.
- `AuditedAspect` — aspecto `@Around` que intercepta los métodos anotados y persiste `AuditLog`.
- `AuditService` — escribe registros con actor, IP, traceId y detalle JSON.

---

### `auth`

Autenticación completa: JWT, OAuth2, verificación de email y revocación de tokens.

Clases clave: `AuthController`, `AuthService`, `JwtTokenProvider`, `RefreshTokenService`, `EmailVerificationService`, `OAuthService`, `OAuthUserProvisioningService`, `JwtAuthenticationFilter`, `OAuth2SuccessHandler`.

Ver [[autenticacion|Autenticación]] para el detalle completo.

---

### `bot`

API para bots externos (Discord bot, etc.) autenticados con API key.

- `BotCommandController` — `GET /api/bot/check-permission` comprueba si un usuario de Discord tiene acceso a una operación.
- `BotApiKeyFilter` — valida la API key en cabecera antes del filtro JWT.
- `BotPermissionCacheService` — caché Redis de permisos para reducir consultas a BD.

---

### `core`

Infraestructura transversal. No contiene lógica de dominio.

| Subpaquete          | Contenido                                                                                  |
| ------------------- | ------------------------------------------------------------------------------------------ |
| `config`            | `SecurityConfig`, CORS, beans globales                                                     |
| `config/properties` | Clases `@ConfigurationProperties`                                                          |
| `exception`         | `GlobalExceptionHandler`, `ProblemDetailResponseAdvice`                                    |
| `filter`            | `MdcPropagationFilter` (traceId en MDC)                                                    |
| `metrics`           | `AlertMetrics`, `AuthMetrics`, `ExternalApiMetrics` (Micrometer)                           |
| `security`          | `RestAuthenticationEntryPoint`, `RestAccessDeniedHandler`, `SecurityProblemResponseWriter` |
| `util`              | Utilidades genéricas                                                                       |

También contiene `@RequiresVerifiedEmail` + `VerifiedEmailAspect` que bloquea operaciones en cuentas sin email verificado.

---

### `external`

Clientes HTTP y jobs de sincronización diaria de datos deportivos externos.

- `basketball/` — cliente BallDontLie (NBA/WNBA).
- `formula1/` — cliente OpenF1.
- `pandascore/` — cliente PandaScore (esports).
- `sync/` — `ExternalApiDailySyncJob` (interfaz), `ExternalApiDailyScheduler`, `SyncWriteHelper`.

Ver [[sincronizacion-datos|Sincronización de datos]].

---

### `follow`

Gestión de seguimientos de deportes y participantes por parte del usuario.

Modelos: `UserSportFollow`, `UserSportNotificationChannel`, `UserFollowNotificationChannel`, `UserSportSettings`.

---

### `loadtest`

Ejecución y monitoreo de pruebas de carga desde la interfaz de administración.

- `LoadTestController` — endpoint SSE que emite logs en tiempo real.
- `LoadTestRunnerService` — lanza contenedores k6 con docker-java y captura su salida.

---

### `notification`

Subsistema completo de alertas de eventos.

| Clase                             | Rol                                                          |
| --------------------------------- | ------------------------------------------------------------ |
| `UserEventAlertGenerationService` | Genera alertas tras la ingesta de eventos                    |
| `UserEventAlertDispatchScheduler` | Scheduler minutal que reclama y despacha alertas             |
| `AlertStreamPublisher`            | Publica en Redis Streams por canal                           |
| `AlertCallbackService`            | Recibe callbacks de workers Ktor                             |
| `AlertRenderService`              | Renderiza HTML con Thymeleaf para artefactos                 |
| `DiscordRoutingResolver`          | Resuelve si un usuario Discord recibe DM o canal de servidor |

Ver [[sistema-alertas|Sistema de alertas]].

---

### `sport`

Controllers públicos de datos deportivos y repositorios de entidades del dominio.

- `BasketballController`, `Formula1Controller`, `PandaScorePublicController` — endpoints de consulta pública.
- Subpaquetes `basketball/`, `formula1/` con entidades específicas de deporte.

---

### `user`

Gestión del perfil de usuario y configuración personal.

Clases clave: `UserController`, `UserSettingsController`.

## Fuentes
