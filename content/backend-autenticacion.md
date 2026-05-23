---
title: Autenticación y Gestión de Sesiones
description: Cómo funciona el sistema de autenticación del backend de Parallax Sports — JWT, OAuth2, refresh tokens y revocación.
tags:
  - backend
  - autenticacion
  - jwt
  - oauth2
---

# Autenticación y Gestión de Sesiones

## 1. Introducción

El backend de Parallax Sports soporta **dos formas de iniciar sesión**: mediante usuario y contraseña clásico, y mediante OAuth2 con proveedores externos (por ejemplo, Google). En ambos casos, el resultado es el mismo: el servidor emite dos tokens JWT que se guardan en cookies HttpOnly del navegador.

La decisión de usar **cookies HttpOnly** en lugar de guardar los tokens en `localStorage` es deliberada y tiene un motivo de seguridad claro: el JavaScript de la página nunca puede leer las cookies HttpOnly, lo que elimina por completo la superficie de ataque de los ataques XSS (Cross-Site Scripting).

---

## 2. Los dos tipos de token

El sistema trabaja con dos JWT distintos, cada uno con un propósito diferente:

- **Access Token** ( `access_token` ) con una duración corta (minutos) se utiliza para autenticar cada petición a la API
- **Refresh Token** ( `refresh_token` ) con una duración larga (días) sirbe para pedir un par de tokens nuevos cuando el access expira 

Ambos tokens llevan dentro tres datos clave:
- **`sub`** (subject): el email del usuario.
- **`token_type`**: el valor `"access"` o `"refresh"` para que el servidor sepa qué token está recibiendo.
- **`role`**: el rol del usuario (`USER` o `ADMIN`).
- **`email_verified`**: si el email ha sido confirmado.

La firma se genera con **HS256** usando una clave secreta configurada en el servidor. Si alguien manipula el contenido del token, la verificación de firma falla y el token es rechazado.

---

## 3. Flujo de login con email y contraseña

```
Cliente → POST /api/auth/login
        → AuthService.login()
        → Spring Security valida las credenciales
        → Se emiten access_token + refresh_token
        → Se guardan en cookies HttpOnly
        ← 200 OK + {userId, emailVerified}
```

1. El `AuthService` le pide al `AuthenticationManager` de Spring Security que compruebe las credenciales.
2. Si son correctas, se actualizan la fecha de último login y se llama a `issueAndSetCookies()`.
3. El `JwtTokenProvider` genera ambos tokens con un UUID único (`jti`) en cada uno.
4. El **refresh token** se guarda también en base de datos (tabla `refresh_tokens`) con un hash SHA-256 del token real. Nunca se guarda el token en crudo, solo su huella.
5. Ambos tokens se escriben como cookies en la respuesta HTTP.

El registro (`/api/auth/register`) sigue el mismo proceso. Adicionalmente, se intenta enviar un correo de verificación, pero si falla, el usuario igualmente queda registrado y puede iniciar sesión.

---

## 4. El filtro JWT: cómo se autentica cada petición

Cada petición que llega al servidor pasa por el `JwtAuthenticationFilter` antes de llegar al controlador. Este filtro hace lo siguiente:

1. Busca el token de acceso: primero en la cabecera `Authorization: Bearer <token>` y si no, en la cookie `access_token`.
2. Si no hay token, deja pasar la petición sin autenticar (los endpoints públicos no necesitan token).
3. Si hay token, lo valida: firma correcta, no expirado, y de tipo `"access"`.
4. **Comprueba en Redis** si el token ha sido revocado (blacklist). Un token puede estar en la blacklist si el usuario cerró sesión antes de que expirara.
5. Si todo es correcto, mete el usuario autenticado en el `SecurityContextHolder` de Spring, que es donde el resto del código puede consultarlo.

---

## 5. Rotación de tokens (refresh)

Cuando el access token expira, el frontend llama a `POST /api/auth/refresh`. El backend:

1. Extrae el refresh token de la cookie.
2. Valida la firma y que sea de tipo `"refresh"`.
3. **Comprueba en base de datos** que el token no haya sido revocado y que el hash SHA-256 coincide.
4. Si el token es válido en la firma pero **no está en la base de datos**, el sistema interpreta esto como un posible **ataque de reutilización de token** (alguien robó un token antiguo). En ese caso, **revoca todos los tokens de ese usuario** de golpe para proteger la cuenta.
5. Si todo va bien, se emite un nuevo par de tokens y se revoca el antiguo. Este patrón se llama **rotación de refresh tokens**.

---

## 6. Login con OAuth2 (Google)

El flujo OAuth2 es gestionado por Spring Security. Cuando el usuario hace clic en "Iniciar sesión con Google":

1. Spring redirige al usuario a Google para que autorice.
2. Google devuelve al usuario al callback del backend con un código de autorización.
3. Spring Security intercambia ese código por el perfil del usuario.
4. El `OAuth2SuccessHandler` recibe el perfil, busca o crea el usuario en la base de datos, emite los dos tokens JWT y los escribe en las cookies.
5. Finalmente, redirige al navegador a `/dashboard` con las cookies ya establecidas.

---

## 7. Cierre de sesión

`POST /api/auth/logout` revoca el refresh token actual en base de datos (marcando `revoked_at`) y borra ambas cookies del navegador estableciendo `maxAge=0`. El access token no se puede revocar directamente porque es stateless, pero su duración es tan corta que expira pronto de todas formas.

---

## 8. Tareas de limpieza automática

Dos schedulers corren en segundo plano para mantener la base de datos limpia:

- **`RefreshTokenCleanupScheduler`**: elimina periódicamente los refresh tokens expirados o revocados de la tabla.
- **`UnverifiedUserCleanupScheduler`**: elimina las cuentas de usuario que se registraron pero nunca verificaron su email, pasado un tiempo configurable.
