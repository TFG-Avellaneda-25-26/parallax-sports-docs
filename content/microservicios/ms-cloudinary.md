---
title: ms-cloudinary
description: Microservicio de almacenamiento de imágenes en Cloudinary. Expone endpoints para verificar existencia y subir artefactos generados por ms-playwright.
tags:
  - microservicios
  - cloudinary
  - ktor
  - imágenes
---

`ms-cloudinary` es un servicio HTTP puro sin consumidor de Redis. Spring no lo llama directamente; es [[ms-playwright]] quien lo invoca como parte del pipeline de generación de artefactos. Corre en el puerto **8085**.

## Fuentes

- [Cloudinary Documentation](https://cloudinary.com/documentation/cloudinary_references)

---

## API

| Método | Ruta                      | Descripción                                                                                        |
| ------ | ------------------------- | -------------------------------------------------------------------------------------------------- |
| GET    | `/check/{eventId}/{hash}` | Comprueba si el artefacto ya existe; devuelve `CloudinaryCheckResponse` con la URL si se encuentra |
| POST   | `/upload` (multipart)     | Sube una imagen; campos: `file` (bytes), `eventId` (string), `hash` (string)                       |

> **Nota:** La ruta de verificación es `/check/{eventId}/{hash}`: tanto `eventId` como `hash` son parámetros de ruta.

## `CloudinaryService`

### `uploadImage(bytes, eventId, hash)`

- Sube la imagen a Cloudinary en la ruta: `parallaxbot/events/{eventId}_{hash}`.
- `overwrite = false`: si el artefacto ya existe, la operación se omite sin error.
- Se ejecuta en `Dispatchers.IO`.
- Devuelve `UploadResponse` con la `secureUrl` de Cloudinary.

### `getExistingUrl(eventId, hash)`

- Consulta la API Admin de Cloudinary buscando el recurso `parallaxbot/events/{eventId}_{hash}`.
- Devuelve `CloudinaryCheckResponse { found: Boolean, url: String? }`.

## Módulos Koin

- `cloudinaryConfigModule`: credenciales de Cloudinary desde `application-secrets.conf`.
- `networkModule`: `HttpClient` compartido del módulo `:common`.
- `configureCloudinary`: instancia el SDK de Cloudinary con `secure = true`.
- `CloudinaryService`: servicio principal.

## Configuración (`application.conf`)

| Clave        | Valor                            |
| ------------ | -------------------------------- |
| Puerto       | 8085                             |
| `cloud-name` | Desde `application-secrets.conf` |
| `api-key`    | Desde `application-secrets.conf` |
| `api-secret` | Desde `application-secrets.conf` |
