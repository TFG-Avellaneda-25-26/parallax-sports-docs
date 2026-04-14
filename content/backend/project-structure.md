---
title: Backend Structure
description: "Spring Boot package-by-feature layout — auth, bot, core, external, follow, notification, sport, user"
tags:
  - backend
  - architecture
---

# Project Structure

The backend follows a package-by-feature layout under `dev.parallaxsports`. Each top-level package owns a vertical slice of the domain.

```
dev.parallaxsports/
├── ParallaxSportsApiApplication.java    # @EnableScheduling
├── auth/                                # Authentication & identity
├── bot/                                 # Bot command permissions
├── core/                                # Cross-cutting infrastructure
├── external/                            # External API integrations
├── follow/                              # User follow & notification preferences
├── notification/                        # Alert lifecycle management
├── sport/                               # Public sport API layer
└── user/                                # User CRUD & settings
```

## Package breakdown

### `auth/` — Authentication & Identity

Handles registration, login, token management, and OAuth2 social login.

| Sublayer | Contents |
|----------|---------|
| `controller/` | `AuthController` — register, login, refresh, logout, email verification |
| `service/` | `AuthService`, `JwtTokenProvider`, `RefreshTokenService`, `EmailVerificationService`, `OAuthService`, `OAuthUserProvisioningService` |
| `security/` | `JwtAuthenticationFilter`, `OAuth2SuccessHandler`, `UserDetailsServiceImpl` |
| `model/` | `RefreshToken` (JPA entity), `AuthProvider` enum, `TokenType` enum |
| `dto/` | Request/response objects for auth endpoints |
| `repository/` | `RefreshTokenRepository` |
| `client/` | `EmailVerificationClient` — calls the [[ms-email]] microservice |

Scheduled cleanup: `RefreshTokenCleanupScheduler`, `UnverifiedUserCleanupScheduler`

### `bot/` — Bot Command Permissions

Lightweight API for checking user permissions from Discord/Telegram bots.

- `BotCommandController` — `GET /api/bot/check-permission`
- `BotPermissionCacheService` — Redis-backed permission cache
- `BotApiKeyFilter` — API key validation filter

### `core/` — Cross-cutting Infrastructure

Shared configuration, exception handling, security filters, and utilities.

| Sublayer | Contents |
|----------|---------|
| `config/` | `SecurityConfig`, `RedisConfig`, `HttpClientConfig`, `JacksonConfig`, `OpenApiConfig`, `PropertiesConfig` |
| `config/properties/` | `AppProperties`, `JwtProperties`, `AlertProperties`, `ExternalApiProperties`, `ExternalSyncProperties`, `BotProperties`, `RedisProperties` |
| `exception/` | `GlobalExceptionHandler`, `ProblemDetailResponseAdvice`, domain exceptions (`BadRequestException`, `ResourceNotFoundException`, etc.), `RestAuthenticationEntryPoint`, `RestAccessDeniedHandler` |
| `security/` | `@RequiresVerifiedEmail` annotation + `VerifiedEmailAspect` (AOP) |
| `util/` | `DateUtils` |

### `external/` — External API Integrations

Each sport provider gets its own sub-package:

- `sync/` — Shared infrastructure: `ExternalApiDailySyncJob` interface, `ExternalApiDailyScheduler`, `SyncWriteHelper`
- `formula1/` — OpenF1 client, sync service, write service, daily job, admin controller
- `basketball/` — Balldontlie client, sync service, write service, daily job, admin controller

See [[sync-pipeline]] for how the plugin architecture works.

### `follow/` — User Follow & Notification Preferences

Manages which sports, competitions, and participants a user follows, and their notification channel preferences.

- `UserSportFollow` — user follows a specific competition or participant
- `UserSportSettings` — default notification settings per sport
- `UserSportNotificationChannel` — per-sport email/discord/telegram toggles
- `UserFollowNotificationChannel` — per-follow channel overrides

### `notification/` — Alert Lifecycle

The [[alerts-system|alert system]] implementation:

| Sublayer | Contents |
|----------|---------|
| `service/` | `UserEventAlertGenerationService`, `UserEventAlertDispatchScheduler`, `AlertStreamPublisher`, `AlertCallbackService` |
| `service/policy/` | `AlertRetryPolicy`, `AlertStatusTransitionPolicy` |
| `controller/` | `InternalAlertCallbackController` — callback endpoints for Ktor workers |
| `integration/stream/` | `AlertStreamPayloadBuilder` |
| `startup/` | `AlertSchemaStartupValidator`, `AlertStreamContractStartupValidator` |
| `client/` | `KtorAlertDispatchClient` — HTTP fallback |
| `repository/` | Alert queries with custom `SKIP LOCKED` claim logic |

### `sport/` — Public Sport API Layer

Public-facing controllers and DTOs for querying sport data:

- `basketball/` — `BasketballController` (`GET /api/basketball/games`, `/teams`), `BasketballLeague` enum
- `formula1/` — `Formula1Controller` (`GET /api/formula1/sessions/{year}`)

### `user/` — User CRUD & Settings

- `UserController` — CRUD with pagination
- `UserSettingsController` — GET/PUT user preferences
- `User` entity — core user model with roles, email verification, login tracking
- `UserSettings` — one-to-one relationship for theme, view mode, timezone, locale
- `UserIdentity` — OAuth provider link table
