---
title: Manejo de Excepciones y Observabilidad
description: Cómo el backend gestiona los errores de forma uniforme, registra eventos de auditoría y expone métricas.
tags:
  - backend
  - excepciones
  - observabilidad
  - metricas
  - auditoria
---

# Manejo de Excepciones y Observabilidad

## 1. Introducción

Un sistema que falla sin avisar o que devuelve errores genéricos es difícil de mantener y de depurar. El backend de Parallax Sports tiene tres capas de visibilidad sobre lo que ocurre en producción:

1. **Manejo uniforme de excepciones**: todos los errores se traducen al mismo formato estándar.
2. **Auditoría**: los eventos importantes quedan registrados permanentemente.
3. **Métricas**: contadores en tiempo real que permiten detectar problemas.

---

## 2. Manejo de excepciones: RFC 9457 Problem Details

Todas las respuestas de error de la API siguen el estándar **RFC 9457 (Problem Details for HTTP APIs)**. En lugar de devolver un JSON arbitrario cuando algo falla, siempre se devuelve un objeto con esta forma:

```json
{
  "type": "/problems/not-found",
  "title": "Resource Not Found",
  "status": 404,
  "detail": "User not found",
  "instance": "/api/users/99"
}
```

Esto lo gestiona el `GlobalExceptionHandler`, una clase anotada con `@RestControllerAdvice` que intercepta todas las excepciones no capturadas del proyecto y las convierte al formato correcto.

### Las excepciones de dominio propias

El proyecto tiene sus propias excepciones que mapean directamente a códigos HTTP:

| Excepción | HTTP | Cuándo se usa |
|---|---|---|
| `ResourceNotFoundException` | 404 | El recurso pedido no existe en la BD |
| `BadRequestException` | 400 | El cliente envió datos inválidos |
| `UnauthorizedException` | 401 | No hay sesión válida o las credenciales son incorrectas |
| `DuplicateResourceException` | 409 | Se intenta crear algo que ya existe (ej: email repetido) |
| `StateConflictException` | 409 | Transición de estado no permitida (ej: confirmar una alerta ya enviada) |
| `ServiceUnavailableException` | 503 | Un servicio dependiente no está disponible |
| `UpstreamServiceException` | 502 | Una API externa devolvió un error |
| `SystemConfigurationException` | 500/503 | Falta configuración requerida en el arranque |

### Errores de validación

Los campos de los DTOs se validan con las anotaciones de Bean Validation (`@NotBlank`, `@Email`, etc.). Cuando una validación falla, el handler devuelve un 400 con la lista detallada de campos inválidos:

```json
{
  "type": "/problems/validation-error",
  "status": 400,
  "invalid_params": [
    { "name": "email", "reason": "must be a well-formed email address" }
  ]
}
```

### Errores de infraestructura

Los errores de Redis (`RedisConnectionFailureException`) se capturan y devuelven un 503 en lugar de un 500 genérico, indicando correctamente que el problema es de disponibilidad del servicio, no un bug del código. Los fallos en llamadas a APIs externas (`RestClientException`) se mapean a 502 (Bad Gateway).

### Red de seguridad

Si alguna excepción no capturada llega hasta el handler, el método anotado con `@ExceptionHandler(Exception.class)` la atrapa y devuelve un 500 limpio. Los errores 5xx se logean con nivel `ERROR` (con el stack trace completo), mientras que los 4xx se logean con `WARN` sin stack trace para no ensuciar los logs.

---

## 3. Errores de seguridad

Los errores de autenticación y autorización tienen un tratamiento especial porque ocurren antes de que lleguen a los controladores (en los filtros de Spring Security). El proyecto tiene dos clases específicas para esto:

- **`RestAuthenticationEntryPoint`**: devuelve un 401 en formato Problem Details cuando una petición accede a un recurso protegido sin estar autenticado.
- **`RestAccessDeniedHandler`**: devuelve un 403 cuando el usuario está autenticado pero no tiene permisos suficientes.

Sin estas clases, Spring Security devolvería por defecto una página HTML de error, que es incompatible con una API REST.

---

## 4. Auditoría

El `AuditService` registra en base de datos los eventos relevantes del sistema. Funciona de forma **asíncrona** (usando un executor dedicado `@Async`) para no añadir latencia a las peticiones del usuario: el hilo que atiende la petición sigue su trabajo mientras el registro de auditoría se escribe en segundo plano.

Cada entrada de auditoría guarda:
- **`action`**: qué pasó (ej: `LOGIN_SUCCESS`, `ALERT_CREATED`, `TOKEN_REFRESHED`).
- **`actor_user_id`**: quién lo hizo.
- **`entity_type` / `entity_id`**: sobre qué entidad actuó.
- **`detail`**: un mapa JSON con información adicional (ej: el canal de la alerta, el motivo de un fallo).
- **`source`**: el método HTTP y la ruta de la petición (ej: `POST /api/auth/login`).
- **`ip_address`**: la IP del cliente, respetando la cabecera `X-Forwarded-For` si hay un proxy delante.
- **`trace_id`**: el ID de traza del MDC de Logback, que permite correlacionar el evento de auditoría con las líneas de log correspondientes.

Algunos de los eventos que quedan registrados: `USER_REGISTERED`, `LOGIN_SUCCESS`, `LOGIN_FAILED`, `LOGOUT`, `TOKEN_REFRESHED`, `REFRESH_REUSE_DETECTED`, `OAUTH_LOGIN`, `ALERT_CREATED`, `ALERT_QUEUED`, `ALERT_SENT`, `ALERT_FAILED_PERMANENT`.

---

## 5. Métricas con Micrometer

El proyecto usa **Micrometer** (la librería estándar de métricas de Spring Boot) con tres grupos de métricas personalizadas:

### AuthMetrics
Contadores para los eventos del sistema de autenticación:
- `auth_login_total{result="success"}` — logins exitosos
- `auth_login_total{result="failure", reason="invalid_credentials"}` — fallos de login
- `auth_refresh_total{result="success"}` — renovaciones de token correctas
- `auth_refresh_total{result="reuse_attack"}` — detecciones de ataque de reutilización
- `auth_oauth_login_total{provider="google"}` — logins vía OAuth2

### AlertMetrics
Contadores para el sistema de alertas:
- `alert_created_total{channel="telegram"}` — alertas creadas por canal
- `alert_queued_total{channel="discord"}` — alertas publicadas en Redis por canal
- `alert_status_callback_total{channel="email", status="sent"}` — resultados de entrega

### ExternalApiMetrics
Contadores para la sincronización externa:
- `external_sync_total{provider="football"}` — ejecuciones por proveedor

Los schedulers más pesados están anotados con `@Timed` de Micrometer, lo que registra automáticamente histogramas de duración con percentiles p50, p95 y p99. Todas estas métricas se exponen a través del endpoint `/actuator/prometheus` de Spring Boot Actuator para ser consumidas por Prometheus y visualizadas en Grafana.
