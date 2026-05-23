---
title: Exception Handling
description: "RFC 7807 ProblemDetail strategy — centralized error mapping, domain exceptions, and consistent API error responses"
tags:
  - backend
  - api
aliases:
  - "Error Handling"
  - "ProblemDetail"
---

# Exception Handling

The API uses centralized exception mapping with RFC 7807 `ProblemDetail` responses. Every error — from validation failures to upstream timeouts — produces a consistent, machine-readable response.

## Response format

```json
{
  "type": "/problems/not-found",
  "title": "Not Found",
  "status": 404,
  "detail": "User with id 42 not found",
  "instance": "/api/users/42"
}
```

- `type` — stable URI reference for error category
- `instance` — the request path that triggered the error

## Problem types

| Type URI | HTTP Status | Triggered by |
|----------|-------------|-------------|
| `/problems/not-found` | 404 | `ResourceNotFoundException` |
| `/problems/bad-request` | 400 | `BadRequestException` |
| `/problems/unauthorized` | 401 | `UnauthorizedException`, `AuthenticationException` |
| `/problems/forbidden` | 403 | `AccessDeniedException` |
| `/problems/conflict` | 409 | `DuplicateResourceException`, `StateConflictException` |
| `/problems/validation-error` | 400 | `@Valid` failures — includes `invalid_params` list |
| `/problems/malformed-body` | 400 | Unparseable JSON |
| `/problems/bad-gateway` | 502 | `UpstreamServiceException`, `RestClientException` |
| `/problems/service-unavailable` | 503 | `ServiceUnavailableException`, Redis connection failures |
| `/problems/internal-error` | 500 | Unhandled exceptions (safety net) |

## Domain exceptions

| Exception | Status | Use case |
|-----------|--------|----------|
| `ResourceNotFoundException` | 404 | Entity not found by ID |
| `BadRequestException` | 400 | Invalid input that isn't a validation error |
| `UnauthorizedException` | 401 | Missing or invalid credentials |
| `DuplicateResourceException` | 409 | Unique constraint violation |
| `StateConflictException` | 409 | Invalid lifecycle transition (e.g., alert already sent) |
| `UpstreamServiceException` | 502 | External API error |
| `ServiceUnavailableException` | 503 | Infrastructure unavailable |

## Database constraint handling

`DataIntegrityViolationException` is parsed to provide meaningful responses:

- "unique" or "duplicate" in message → 409 Conflict
- "foreign key" or "check constraint" → 400 Bad Request

## Logging strategy

- **5xx errors:** ERROR level with full stack trace
- **4xx errors:** WARN level (no stack trace)
- All errors include: status, path, exception type, message

## Implementation

- `GlobalExceptionHandler` (`@RestControllerAdvice`) — handles all exception types
- `ProblemDetailResponseAdvice` — ensures `type` and `instance` are always populated on any `ProblemDetail` response
