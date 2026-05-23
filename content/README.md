# Parallax Sports - Frontend

Este repositorio contiene el código fuente del frontend para el proyecto Parallax Sports. Esta aplicación web está construida utilizando las últimas características de Angular 21 junto con una arquitectura modular estricta para garantizar la escalabilidad y el mantenimiento a largo plazo.

---

## Índice

1. [Descripción del Proyecto](#descripción-del-proyecto)
2. [Arquitectura y Estructura](#arquitectura-y-estructura)
3. [Stack Tecnológico](#stack-tecnológico)
4. [Características Principales](#características-principales)
5. [Integración y Despliegue Continuo (CI/CD)](#integración-y-despliegue-continuo-cicd)
6. [Instalación y Ejecución Local](#instalación-y-ejecución-local)
7. [Scripts Disponibles](#scripts-disponibles)

---

## Descripción del Proyecto

Parallax Sports es una plataforma orientada a la gestión y visualización de eventos deportivos. El frontend tiene como objetivo ofrecer una experiencia de usuario fluida, reactiva e inmersiva. Se hace un uso extensivo de las señales de Angular (Signals) y el nuevo ecosistema `@ngrx/signals` para la gestión del estado de forma completamente reactiva, eliminando la dependencia excesiva de RxJS clásico en la capa de vista y componentes.

---

## Arquitectura y Estructura

El proyecto sigue los principios de la arquitectura Feature-Sliced Design (FSD) adaptada a Angular. Esto permite una separación clara de responsabilidades y un bajo acoplamiento entre los módulos. Para asegurar que se cumplan las reglas de dependencias (por ejemplo, que una `entidad` no importe una `feature`), se utiliza Sheriff (`@softarc/eslint-plugin-sheriff`).

La estructura principal del código fuente (`src/`) es la siguiente:

- **`app/`**: Inicialización de la aplicación, enrutamiento global (`app.routes.ts`) y configuraciones raíz.
- **`pages/`**: Componentes enrutables de alto nivel (Dashboard, Auth, Landing, Settings, Error).
- **`widgets/`**: Bloques de UI compuestos que combinan entidades y características (ej. `event-feed`, `header`, `settings-nav`).
- **`features/`**: Funcionalidades específicas que aportan valor de negocio e interactúan con el estado (ej. flujos de Autenticación, configuración de preferencias de Usuario, control de temas, interacción con Eventos).
- **`entities/`**: Modelos de dominio, servicios de API y estado de dominio (ej. `user`, `auth`, `event`, `timezone`).
- **`shared/`**: Componentes genéricos, directivas, utilidades, interceptores HTTP y lib genéricas compartidas por toda la aplicación.

---

## Stack Tecnológico

- **Framework:** Angular 21 (Modo Standalone Component, Control Flow)
- **Lenguaje:** TypeScript 5.9
- **Gestión de Estado:** `@ngrx/signals`
- **Formularios:** `@angular/forms/signals` para validación y control reactivo nativo de formularios.
- **Animaciones:** GSAP 3 (GreenSock Animation Platform) para micro-interacciones fluidas.
- **Manejo de Fechas/Zonas Horarias:** API Temporal (`@js-temporal/polyfill`) y `@vvo/tzdb`.
- **Linting & Code Quality:** ESLint v9, Angular ESLint v21, y Sheriff Core.

---

## Características Principales

1. **Sistema Completo de Autenticación**
   - Inicio de sesión y registro de usuarios.
   - Flujo de recuperación de contraseña con envío de correos (Forgot Password).
   - Verificación en múltiples pasos mediante códigos de un solo uso (OTP) utilizando la librería `ng-otp-input`.
   - Protección de rutas a través de Guards modernos (`authGuard`, `redirectIfAuthenticatedGuard`).

2. **Panel Principal (Dashboard)**
   - Visualización de eventos (Event Feed) alimentado por un resolver (`eventResolver`) que pre-carga los datos del estado en base a la configuración y zona horaria del usuario.
   
3. **Gestión de Cuenta y Configuración**
   - Panel de preferencias modular que incluye la actualización de la cuenta, seguimientos de equipos/ligas (Follows), panel de administración y ajustes de zona horaria.

4. **Experiencia de Usuario (UX) Inmersiva**
   - Transiciones y animaciones personalizadas gestionadas con GSAP.
   - UI adaptativa con cambio de tema dinámico (`theme-switch`).

---

## Integración y Despliegue Continuo (CI/CD)

El ciclo de vida del proyecto está totalmente automatizado y preparado para entornos de producción utilizando prácticas de DevOps:

- **Contenedores:** Aplicación dockerizada (`Dockerfile` multistage) que compila el frontend usando node, y sirve los ficheros estáticos minificados a través de un servidor web **Nginx** (Alpine).
- **Pipeline (Jenkins):** Automatización mediante un `Jenkinsfile` que:
  1. Clona el repositorio.
  2. Construye las imágenes Docker de forma nativa (`AOT` compilation habilitada).
  3. Sube la imagen a un Docker Registry local.
  4. Realiza el despliegue automático mediante Docker Compose (`docker compose pull & up`).
- **Nginx Configuración:** Incluye configuración para enrutamiento SPA (Single Page Application) realizando redirección a `index.html` para el soporte del Router de Angular, compresión y cacheo.

---

## Instalación y Ejecución Local

### Pre-requisitos
- Node.js (v22 o superior recomendado)
- NPM (v11 o superior)

### Pasos

1. Clonar el repositorio:
```bash
git clone https://github.com/tfg-avellaneda-25-26/parallax-sports-angular.git
cd parallax-sports-angular
```

2. Instalar dependencias:
```bash
npm install
```

3. Ejecutar servidor de desarrollo local:
```bash
npm start
```
*La aplicación estará disponible por defecto en `http://localhost:4200`.*

---

## Scripts Disponibles

En el `package.json` están configurados los siguientes comandos:

- `npm start`: Levanta el servidor de desarrollo en modo por defecto.
- `npm run start:local`: Levanta el servidor apuntando explícitamente a una API local (`NG_API_URL=http://localhost:8080`).
- `npm run build`: Compila la aplicación para producción con minimización (crea la carpeta `dist/`).
- `npm run watch`: Ejecuta el compilador en modo escucha para desarrollo en paralelo.
- `npm run test`: Ejecuta la batería de tests unitarios (si están configurados).
- `npm run lint`: Realiza el análisis de código estático (ESLint + Sheriff).

---

**Project DOCS Oficiales:** [https://tfg-avellaneda-25-26.github.io/parallax-sports-docs/](https://tfg-avellaneda-25-26.github.io/parallax-sports-docs/)
