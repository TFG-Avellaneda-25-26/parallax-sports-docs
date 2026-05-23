# Despliegue de infraestructura

Esta guía explica cómo poner en marcha el proyecto desde cero, tanto en modo completamente Docker como en modo de desarrollo local (Angular y Spring corriendo en la máquina, con la infraestructura en Docker). El evaluador recibirá los ficheros de secretos en texto plano por separado.

---

## Qué contiene el stack

El proyecto usa Docker Compose para levantar todos los servicios. Se divide en dos capas:

**Infraestructura** (siempre en Docker):

- PostgreSQL — base de datos principal
- Redis — caché y colas de mensajes (Redis Streams)
- Loki + Alloy — recogida y almacenamiento de logs
- Prometheus + Alertmanager — métricas y alertas
- Grafana — dashboards de observabilidad
- Jenkins — CI/CD para construir y desplegar imágenes
- Registry local — almacén de imágenes Docker (puerto 5000)

**Aplicaciones** (en Docker o localmente, según se prefiera):

- `spring-boot` — API REST principal (puerto 8080)
- `angular` — SPA servida por nginx (puerto 80)
- `ms-discord`, `ms-email`, `ms-cloudinary`, `ms-playwright` — microservicios Ktor

---

## Requisitos previos

- Docker Engine y Docker Compose instalados
- `git` instalado
- Los ficheros de secretos que se entregan por separado (ver sección siguiente)

Para desarrollo local también se necesita:

- JDK 21 (para Spring)
- Node 22 y npm (para Angular)

---

## Preparación: clonar el repositorio y colocar los secretos

```bash
# Clonar el repositorio de infraestructura
git clone https://github.com/TFG-Avellaneda-25-26/parallax-sports-infra.git
cd parallax-sports-infra
```

El repositorio usa `git-crypt` para cifrar los secretos en git. Como el evaluador no tiene la clave GPG del proyecto, los secretos se entregan directamente como ficheros en texto plano. Simplemente hay que colocarlos en su sitio:

```bash
    # Copiar el fichero .env con las variables de entorno
cp /ruta/a/los/secretos/.env .env

# Copiar la configuración de Alertmanager (contiene el webhook de Discord)
cp /ruta/a/los/secretos/alertmanager-config.yml alertmanager/config.yml
```

Verificar que los ficheros tienen contenido legible (no datos binarios cifrados):

```bash
head -2 .env                     # debe mostrar algo como: POSTGRES_USER=admin
head -3 alertmanager/config.yml  # debe mostrar: global:
```

---

## Levantar todo en Docker

Con los secretos en su sitio, ya se puede levantar el stack completo. El flag `--profile apps` incluye también los contenedores de las aplicaciones (Spring, Angular, microservicios):

```bash
COMPOSE_PROFILES=apps docker compose up -d
```

Esto levanta todos los servicios. La primera vez tardará varios minutos mientras Docker descarga las imágenes base.

Comprobar que todo está corriendo:

```bash
docker compose ps
```

Una vez en marcha, los servicios principales son accesibles en:

| Servicio             | URL                   |
| -------------------- | --------------------- |
| Angular (aplicación) | http://localhost      |
| Spring API           | http://localhost:8080 |
| Grafana              | http://localhost:3000 |
| Prometheus           | http://localhost:9090 |
| Jenkins              | http://localhost:8090 |

> Si el evaluador accede desde otra máquina, sustituir `localhost` por la IP del servidor donde corre Docker.

---

## Detener el stack

```bash
COMPOSE_PROFILES=apps docker compose down
```

Los datos (base de datos, logs, configuración de Grafana) persisten en el directorio `data/` y se recuperan al volver a levantar el stack.

---

## Alternativa: ejecutar Spring o Angular localmente

Si se prefiere ejecutar la API o el frontend en la máquina en lugar de en Docker, se puede hacer sin conflictos. La infraestructura (Postgres, Redis, etc.) sigue corriendo en Docker y los servicios locales se conectan a ella.

### Solo infraestructura en Docker (sin aplicaciones)

```bash
# Sin --profile, no se levantan los contenedores de las aplicaciones
docker compose up -d
```

Esto libera los puertos 8080 y 80 para que Spring y Angular puedan usarlos localmente.

### Ejecutar Spring localmente

Clonar el repositorio de Spring y colocar el fichero de secretos local:

```bash
git clone https://github.com/TFG-Avellaneda-25-26/parallax-sports-spring.git
cd parallax-sports-spring

# Colocar los secretos locales (se entregan por separado)
cp /ruta/a/los/secretos/api-secrets.local.yml src/main/resources/api-secrets.local.yml
```

Arrancar la API:

```bash
./mvnw spring-boot:run
```

Spring se conectará automáticamente a la base de datos PostgreSQL y Redis que están corriendo en Docker (publicados en `localhost:5432` y `localhost:6379`).

### Ejecutar Angular localmente

Clonar el repositorio de Angular:

```bash
git clone https://github.com/TFG-Avellaneda-25-26/parallax-sports-angular.git
cd parallax-sports-angular
npm install
```

Arrancar el servidor de desarrollo:

```bash
npm start
```

Esto abre Angular en `http://localhost:4200`. Por defecto, las peticiones a la API van a `http://192.168.1.29:8080` (el servidor de despliegue del proyecto). Si la API está corriendo localmente, usar:

```bash
npm run start:local   # redirige la API a http://localhost:8080
```

---

## Credenciales de acceso

Los valores concretos de usuarios y contraseñas se encuentran en el fichero `.env` que se entrega por separado. Los campos relevantes son:

- `POSTGRES_USER` / `POSTGRES_PASSWORD` — acceso a la base de datos
- `GRAFANA_ADMIN_PASSWORD` — panel de Grafana (usuario: `admin`)
- `APP_CORS_ALLOWED_ORIGINS` — orígenes permitidos en CORS (ajustar si se accede desde una IP diferente)

Si el stack se despliega en una máquina con una IP distinta a `192.168.1.29`, hay que actualizar estas líneas en `.env`:

```
FRONTEND_URL=http://<nueva-ip>
APP_CORS_ALLOWED_ORIGINS=http://<nueva-ip>,http://localhost:4200
```

Y reiniciar Spring:

```bash
COMPOSE_PROFILES=apps docker compose up -d spring-boot
```

---

## Si algo no arranca

**Los contenedores de aplicación no encuentran sus imágenes** — las imágenes se construyen con Jenkins. Si es la primera vez y Jenkins no ha ejecutado los pipelines todavía, las imágenes no existen. En ese caso, lo más sencillo es ejecutar Spring y Angular localmente (ver sección anterior) mientras Jenkins construye las imágenes en segundo plano.

**`.env` muestra caracteres extraños** — el fichero sigue cifrado. Asegurarse de haber copiado el fichero en texto plano tal como se indica en la sección de preparación.

**Spring no conecta a la base de datos** — verificar que los contenedores de infraestructura están corriendo con `docker compose ps` y que los valores de `POSTGRES_USER` y `POSTGRES_PASSWORD` en `.env` coinciden con los de `api-secrets.local.yml`.

**Puerto 80 ocupado** — si hay otro servidor web en la máquina, cambiar el puerto del contenedor `angular` en `docker-compose.yml` de `"80:80"` a, por ejemplo, `"8000:80"` y acceder desde `http://localhost:8000`.
