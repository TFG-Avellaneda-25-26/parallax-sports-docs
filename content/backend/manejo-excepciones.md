---
title: Manejo de excepciones
description: Estrategia de gestión de errores en Parallax Sports basada en Problem Details RFC 9457, jerarquía de excepciones de dominio y auditoría AOP.
tags: [backend, excepciones, errores, auditoria, aop]
---

# Manejo de excepciones

## Fuentes

- [RFC 9457: Problem Details for HTTP APIs](https://www.rfc-editor.org/info/rfc9457)
- [Anotaciones personalizadas en Java – Baeldung](https://www.baeldung.com/java-custom-annotation)
- [AOP con anotaciones en Spring – Baeldung](https://www.baeldung.com/spring-aop-annotation)

---

## Problem Details RFC 9457

Todos los errores devuelven `Content-Type: application/problem+json` con la estructura:

```json
{
  "type": "https://parallaxsports.dev/problems/resource-not-found",
  "title": "Resource Not Found",
  "status": 404,
  "detail": "Event with id 'abc' not found",
  "instance": "/api/sport/events/abc"
}
```

Los errores de validación (`400`) añaden el campo adicional:

```json
"invalid_params": [
  { "field": "email", "message": "must be a valid email address" }
]
```

**Implementación:**

- `ProblemDetailResponseAdvice`: `@RestControllerAdvice` que convierte excepciones a `ProblemDetail`.
- `GlobalExceptionHandler`: captura excepciones de dominio y del sistema.

---

## Jerarquía de excepciones de dominio

| Excepción                      | HTTP |
| ------------------------------ | ---- |
| `BadRequestException`          | 400  |
| `UnauthorizedException`        | 401  |
| `ResourceNotFoundException`    | 404  |
| `DuplicateResourceException`   | 409  |
| `StateConflictException`       | 409  |
| `ServiceUnavailableException`  | 503  |
| `SystemConfigurationException` | 500  |
| `UpstreamServiceException`     | 502  |

---

## Handlers de seguridad

- `RestAuthenticationEntryPoint`: invocado por Spring Security cuando la petición llega sin autenticación válida; devuelve `401` en formato Problem Details.
- `RestAccessDeniedHandler`: invocado cuando un usuario autenticado no tiene permisos suficientes; devuelve `403`.
- `SecurityProblemResponseWriter`: utilidad compartida entre los dos handlers anteriores para serializar la respuesta Problem Details en el contexto de los filtros de seguridad.

---

## Auditoría con AOP

### `@Audited`

Anotación que marca métodos de controller o servicio cuyas invocaciones deben registrarse en `AuditLog`.

```java
@Audited(action = "USER_ROLE_CHANGED", entityType = "User")
public void changeRole(UUID userId, Role newRole) { ... }
```

### `AuditedAspect`

Aspecto Spring `@Around` que intercepta todos los métodos anotados con `@Audited`:

1. Extrae `actor_user_id` del `SecurityContext`.
2. Obtiene `ip_address` de la request HTTP.
3. Lee `trace_id` del MDC (ver [[observabilidad|Observabilidad]]).
4. Serializa los argumentos relevantes como `detail` JSON.
5. Persiste `AuditLog` independientemente del resultado del método (éxito o excepción).

### Operaciones auditadas

- Operaciones de administración (cambio de rol, borrado de usuario, inyección de eventos).
- Eventos de autenticación (registro, login, revocación de tokens).
- Cambios en datos del usuario.

Los registros son consultables vía `GET /api/admin/audit` (paginado, filtrable por actor, acción, entidad y fecha).
