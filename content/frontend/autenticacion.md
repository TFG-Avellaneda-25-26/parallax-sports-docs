---
title: Autenticación frontend
description: Estrategia de autenticación del frontend de Parallax Sports: HttpOnly cookies, interceptores HTTP y guards de ruta.
tags:
  - frontend
  - autenticacion
  - seguridad
  - interceptores
---

# Autenticación frontend

## HttpOnly cookies

Spring Boot emite dos cookies al autenticar al usuario:

| Cookie          | Atributos                      |
| --------------- | ------------------------------ |
| `access_token`  | HttpOnly, SameSite=Lax, Secure |
| `refresh_token` | HttpOnly, SameSite=Lax, Secure |

Angular **nunca accede a los tokens directamente**: son invisibles para JavaScript. El browser los adjunta automáticamente a cada petición al mismo origen.

---

## ApiClient

**Ubicación:** `shared/api/api-client.ts`

Wrapper delgado sobre `HttpClient` de Angular. Su única responsabilidad es añadir `withCredentials: true` a cada petición para que el browser envíe las cookies de sesión:

```typescript
get<T>(url: string, options?: HttpOptions): Observable<T> {
  return this.http.get<T>(url, { ...options, withCredentials: true })
}
```

El token de inyección `API_BASE_URL` (configurado como `''`) hace que todas las rutas sean relativas al origen actual. nginx en producción y el proxy de `ng serve` en desarrollo enrutan `/api/*` al backend.

---

## authInterceptor

**Ubicación:** `shared/interceptors/auth.interceptor.ts`

Gestiona el refresco transparente del `access_token` cuando caduca.

**Flujo:**

1. Una petición recibe una respuesta **HTTP 401** (excluidas las rutas de autenticación propias: `/api/auth/*`).
2. El interceptor serializa todas las peticiones en vuelo mediante un `BehaviorSubject` (cola de refresco).
3. Se dispara **una única** petición `POST /api/auth/refresh`.
4. **Si el refresco tiene éxito:** se replayan todas las peticiones encoladas con las nuevas credenciales.
5. **Si el refresco falla:** se propaga el error; `errorInterceptor` redirige al usuario al login.

El uso del `BehaviorSubject` como cola evita múltiples intentos de refresco en paralelo ante peticiones concurrentes.

---

## errorInterceptor

**Ubicación:** `shared/interceptors/error.interceptor.ts`

Normaliza todos los errores HTTP al shape `ProblemDetails` (RFC 7807):

```typescript
interface ProblemDetails {
  type: string
  title: string
  status: number
  detail: string
  instance: string
  invalid_params?: Record<string, string>
}
```

**Comportamiento por código:**

| Código / Condición         | Acción                                                         |
| -------------------------- | -------------------------------------------------------------- |
| Status 0 (red error)       | `ErrorStore.set(error)` + navega a `/error`                    |
| 404                        | `ErrorStore.set(error)` + navega a `/error`                    |
| ≥ 500                      | `ErrorStore.set(error)` + navega a `/error`                    |
| Fallo de refresco de token | `ErrorStore.set(error)` + navega a `/error`                    |
| 400                        | Propaga el error normalizado para manejo a nivel de componente |
| 401 en rutas de auth       | Propaga el error (login incorrecto)                            |
| 409                        | Propaga el error (conflicto, p. ej. email ya registrado)       |

---

## Guards de ruta

Ver [[frontend/rutas-paginas|Rutas y páginas]] para el árbol de rutas completo.

### `authGuard`

- Llama a `UserStore.loadUser()` → GET `/api/users/me`.
- Si la cookie es válida, el request tiene éxito y la navegación continúa.
- Si devuelve 401: redirige a `/` (landing).
- Si lanza excepción: redirige a `/error`.

### `verifiedEmailGuard`

- Se ejecuta después de `authGuard` (el usuario ya está cargado).
- Lee `UserStore.isVerified()`: refleja `user.emailVerified`.
- Si `false`: bloquea el acceso a `/settings` hasta que el usuario verifique su email.

## Fuentes
