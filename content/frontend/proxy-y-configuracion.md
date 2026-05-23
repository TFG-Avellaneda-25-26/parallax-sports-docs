---
title: Proxy y configuración Angular/nginx
description: Configuración del proxy Angular durante el desarrollo y nginx en producción para Parallax Sports.
tags:
  - frontend
  - infraestructura
  - nginx
  - proxy
---

# Proxy y configuración Angular/nginx

## Fuentes

- [Spring MVC CORS](https://docs.spring.io/spring-framework/reference/web/webmvc-cors.html)

---

## Durante desarrollo (`ng serve`)

Existen dos ficheros de proxy en la raíz del proyecto Angular:

| Fichero           | Tipo          | Target por defecto                             |
| ----------------- | ------------- | ---------------------------------------------- |
| `proxy.conf.js`   | JS dinámico   | `NG_API_URL` o `http://localhost:8080`         |
| `proxy.conf.json` | JSON estático | `http://192.168.1.29:8080` (LXC Docker Spring) |

`angular.json` tiene configurado `"proxyConfig": "proxy.conf.js"` en todas las configuraciones de `serve`. **`proxy.conf.json` existe como referencia legacy** y no está activo.

### `proxy.conf.js`

Lee la variable de entorno `NG_API_URL` en tiempo de arranque. Si no está definida, usa `http://localhost:8080`:

```javascript
const target = process.env.NG_API_URL ?? "http://localhost:8080"
module.exports = {
  "/api": { target, changeOrigin: true },
  "/login": { target, changeOrigin: true },
  "/oauth2": { target, changeOrigin: true },
}
```

### Scripts npm

| Comando                         | Proxy activo                                         | Target                  |
| ------------------------------- | ---------------------------------------------------- | ----------------------- |
| `npm start`                     | `proxy.conf.js` (`NG_API_URL` no definida)           | `http://localhost:8080` |
| `npm run start:local`           | `proxy.conf.js` (`NG_API_URL=http://localhost:8080`) | `http://localhost:8080` |
| `NG_API_URL=http://X npm start` | `proxy.conf.js`                                      | `http://X`              |

### Rutas proxied (ambos configs)

| Ruta        | Destino                              |
| ----------- | ------------------------------------ |
| `/api/*`    | Spring Boot :8080                    |
| `/login/*`  | Spring Boot :8080 (callbacks OAuth2) |
| `/oauth2/*` | Spring Boot :8080                    |

---

## En producción (nginx)

`nginx.conf` sirve la SPA Angular y enruta el tráfico al backend dentro de la red Docker `stack`.

### Bloques de configuración

**API y OAuth2:**

```nginx
location /api/ {
  proxy_pass http://spring-boot:8080;
  proxy_buffering off;        # SSE: /api/admin/loadtest/runs/{id}/logs
  proxy_read_timeout 1h;
}

location /login/  { proxy_pass http://spring-boot:8080; }
location /oauth2/ { proxy_pass http://spring-boot:8080; }
```

`proxy_buffering off` es necesario para que el streaming de logs de loadtest (SSE) llegue al cliente sin que nginx los almacene en buffer.

**Assets estáticos con cache agresiva:**

```nginx
location ~* \.(js|css|woff2?|png|svg|ico|webp)$ {
  expires 1y;
  add_header Cache-Control "public, immutable";
}
```

Los bundles de Angular llevan hash en el nombre de fichero, por lo que son inmutables.

**Shell SPA (sin cache):**

```nginx
location = /index.html {
  add_header Cache-Control "no-cache, no-store, must-revalidate";
}
```

`index.html` nunca se cachea para que el browser siempre obtenga la versión más reciente con los nuevos hashes de bundle.

**Healthcheck:**

```nginx
location = /health {
  return 200 "UP";
  add_header Content-Type text/plain;
}
```

Usado por el healthcheck del contenedor Docker.

**SPA fallback:**

```nginx
location / {
  try_files $uri $uri/ /index.html;
}
```

Todas las rutas desconocidas devuelven `index.html` para que Angular Router gestione la navegación en el cliente.

**Seguridad:**

```nginx
server_tokens off;
```

Oculta la versión de nginx en las cabeceras de respuesta y páginas de error.

---

## `API_BASE_URL` token

Configurado como `''` (cadena vacía) en `AppConfig`:

```typescript
{ provide: API_BASE_URL, useValue: '' }
```

Esto hace que todas las peticiones de `ApiClient` sean relativas al origen actual (`/api/...`). nginx en producción y el proxy de `ng serve` en desarrollo se encargan de enrutar esas rutas al backend sin que el código Angular necesite conocer la URL del servidor.
