---
title: Despliegue
description: "Guía de despliegue de Parallax Sports: modos de ejecución en Docker y en local, configuración de secretos y servicios expuestos."
tags: [infra, docker, devops, despliegue]
---

# Despliegue

## Fuentes

- [git-crypt para secretos en CI (YouTube)](https://youtu.be/M5IkdUunf8g?si=tpyqjalzocRfqMv4)

---

## Prerequisitos

| Herramienta                       | Versión | Para qué               |
| --------------------------------- | ------- | ---------------------- |
| Docker + Docker Compose           | v2      | Infraestructura en LXC |
| JDK 21                            | :       | Spring local           |
| Node 22 + npm 11                  | :       | Angular local          |
| git-crypt + clave GPG o simétrica | :       | Desencriptar secrets   |

## Configuración de secrets (una vez por máquina)

### LXC

```bash
git-crypt unlock /root/parallax-infra.key
```

### Spring (portátil)

```bash
cp src/main/resources/api-secrets.example.yml src/main/resources/api-secrets.local.yml
# Rellenar con las credenciales reales
```

### Ktor (portátil)

```bash
cp common/src/main/resources/shared-secrets.example.conf common/src/main/resources/shared-secrets.local.conf
cp common/src/main/resources/shared-data.example.conf common/src/main/resources/shared-data.local.conf
# Rellenar URLs y keys
```

## Modos de despliegue

| Angular                       | Spring | Ktor   | Descripción                                                     |
| ----------------------------- | ------ | ------ | --------------------------------------------------------------- |
| Docker                        | Docker | Docker | Producción / demo. `COMPOSE_PROFILES=apps docker compose up -d` |
| Local (`npm start`)           | Docker | Docker | Desarrollo UI. Solo Angular en local                            |
| Local (`npm run start:local`) | Local  | Docker | Desarrollo full-stack sin Ktor                                  |
| Local (`npm run start:local`) | Local  | Local  | Desarrollo completo                                             |

## Modo 1: Todo en Docker (producción)

```bash
ssh root@192.168.1.29
cd /opt/stack && git pull
COMPOSE_PROFILES=apps docker compose up -d
docker compose ps  # verificar healthchecks
```

## Modo 2: Angular local → Spring Docker

**En LXC:**

```bash
COMPOSE_PROFILES=apps docker compose up -d spring-boot
```

**En portátil:**

```bash
cd parallax-sports-angular
npm start  # proxy.conf.js con NG_API_URL unset → localhost:8080 por defecto
```

> [!note]
> `npm start` sin `NG_API_URL` apunta a `localhost:8080`, **no** al LXC Docker. Para apuntar al Docker del LXC: `NG_API_URL=http://192.168.1.29:8080 npm start`.

## Modo 3: Angular + Spring local → infra Docker

**En LXC:** `docker compose up -d` (sin `COMPOSE_PROFILES`, solo infra)

**Portátil: terminal 1:**

```bash
cd parallax-sports-spring && ./mvnw spring-boot:run
```

**Portátil: terminal 2:**

```bash
cd parallax-sports-angular && npm run start:local
```

## Modo 4: Todo local (incluyendo Ktor)

**En LXC:** `docker compose up -d`

**Portátil:**

```bash
# Terminal 1
cd parallax-sports-spring && ./mvnw spring-boot:run

# Terminal 2 (repetir por servicio)
cd parallax-sports-ktor-microservices
./gradlew :ms-discord:run
# o :ms-email:run, :ms-cloudinary:run, :ms-playwright:run

# Terminal 3
cd parallax-sports-angular && npm run start:local
```

## Servicios expuestos en el LXC

| Servicio     | URL                      |
| ------------ | ------------------------ |
| Angular SPA  | http://192.168.1.29      |
| Spring API   | http://192.168.1.29:8080 |
| Grafana      | http://192.168.1.29:3000 |
| Jenkins      | http://192.168.1.29:8090 |
| Prometheus   | http://192.168.1.29:9090 |
| Alertmanager | http://192.168.1.29:9093 |

## Parar servicios

```bash
# Parar solo apps, mantener infra
COMPOSE_PROFILES=apps docker compose stop spring-boot angular ms-discord ms-email ms-cloudinary ms-playwright

# Teardown completo (volúmenes de datos se conservan)
COMPOSE_PROFILES=apps docker compose down
```

## Re-autorizar Gmail OAuth en el LXC

El _refresh token_ de Gmail vive en el volumen `./data/redis` del LXC. Si se borra ese volumen (`down -v`) hay que rehacer el flujo OAuth contra el `ms-email` del LXC. El problema: el _redirect URI_ registrado en Google Cloud Console es `http://localhost:8084/auth/callback`, y Google **solo admite `http://` para `localhost`/`127.0.0.1`** (nunca para `192.168.1.29` u otra IP de LAN — exigiría HTTPS). La solución es un túnel SSH puntual.

**Paso 1** — Desde el portátil, abrir un túnel `localhost:8084 → LXC:8084` (dejar la terminal abierta):

```bash
ssh -L 8084:localhost:8084 root@192.168.1.29
```

**Paso 2** — En el navegador del portátil:

```text
http://localhost:8084/auth/google/login
```

**Paso 3** — Aceptar el consentimiento en Google con la cuenta `daw590779@gmail.com` (permisos `gmail.send`).

**Paso 4** — Google redirige a `http://localhost:8084/auth/callback?code=...`. El navegador sigue el redirect → pasa por el túnel → llega al `ms-email` del LXC → guarda el _refresh token_ en Redis. La página muestra `Success Refresh token saved in redis`.

**Paso 5** — Cerrar el túnel. El token persiste en `./data/redis` mientras no se borre el volumen.
