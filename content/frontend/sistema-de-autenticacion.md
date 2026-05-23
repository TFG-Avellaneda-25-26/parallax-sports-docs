---
title: Sistema Completo de Autenticación
description: Documentación sobre cómo funciona el inicio de sesión, el registro y la recuperación de contraseñas.
---

# Sistema Completo de Autenticación

## 1. Introducción 

La finalidad principal del sistema de autenticación es garantizar la seguridad, integridad y privacidad de la información, restringiendo el acceso a las áreas privadas del panel de control únicamente a aquellos usuarios que estén debidamente registrados e identificados.

## 2. Análisis y diseño del proyecto

### 2.1. Descripción de la arquitectura web

Todo el sistema de autenticación funciona como una SPA (aplicación de una sola página). Esto significa que la pantalla no se recarga cuando el usuario pasa del login al registro o a recuperar su contraseña, haciendo que la web se sienta mucho más rápida.

Para organizar el código, hemos usado un modelo llamado Feature-Sliced Design (FSD). Básicamente, dividimos el código en tres partes independientes: lo que ve el usuario (la interfaz), la memoria de la aplicación (el estado) y la conexión con el servidor. Así el código queda mucho más ordenado y fácil de mantener.

### 2.2. Tecnologías y herramientas utilizadas

Para montar esta parte de la aplicación, usamos estas tecnologías:
- **Angular:** Como base para crear la web y unir todos los componentes.
- **@ngrx/signals:** Para guardar y controlar la información de los formularios en tiempo real, de forma muy rápida y directa.
- **@angular/forms/signals:** Para comprobar que los datos que escribe el usuario (como el correo o la contraseña) están bien escritos, usando la nueva forma de trabajo de Angular.
- **ng-otp-input:** Una pequeña librería que usamos para crear las casillas donde el usuario escribe el código numérico de verificación que le enviamos al correo.

### 2.3. Análisis de usuarios

En esta parte del proyecto tenemos tres tipos de perfiles en cuenta:
- **Usuario invitado:** Alguien que acaba de entrar a la web y todavía no ha iniciado sesión. Solo necesita ver el formulario para entrar, crearse una cuenta o pedir que le enviemos un correo si no recuerda su contraseña.
- **Usuario verificando su cuenta:** Una persona que está a mitad del proceso y necesita escribir el código (OTP) que le hemos mandado al email para confirmar que es él.
- **Usuario autenticado:** La persona que ya ha metido bien sus datos y entra al panel privado de la aplicación con todos sus permisos.

### 2.4. Definición de requisitos funcionales y no funcionales

**Lo que tiene que hacer (Requisitos funcionales):**
- **Inicio de sesión:** Dejar que los usuarios entren con su correo y contraseña.
- **Registro:** Permitir crear una cuenta nueva pidiendo el nombre, un correo y una contraseña segura.
- **Recuperación de contraseña:** Darle al usuario la opción de recuperar su cuenta con estos pasos:
  1. Pedirle su correo.
  2. Pedirle que introduzca un código numérico que le llega al email.
  3. Dejarle elegir una contraseña nueva (que cumpla los requisitos mínimos).
- **Comprobación de datos:** Avisar al usuario si está poniendo un email con mal formato o una contraseña muy débil antes de enviar nada al servidor.

**Cómo tiene que funcionar (Requisitos no funcionales):**
- **Fácil de usar:** Los mensajes de error tienen que ser claros y aparecer al instante si el usuario se equivoca al escribir.
- **Seguro:** Las contraseñas viajan siempre de forma oculta y segura al servidor.
- **Rápido:** Las ventanitas donde se mete el código de verificación deben abrirse al instante, sin tirones visuales.

## 3. Organización de la lógica de negocio

Para que el código no sea un caos, hemos repartido el trabajo de la autenticación en tres capas:

### La parte visual (Capa de Presentación)
Aquí están los componentes que ve el usuario. Por ejemplo, el formulario principal cambia los botones y los textos automáticamente dependiendo de si la persona quiere iniciar sesión o registrarse. También aquí están las ventanas modales (diálogos) que saltan para pedir el código de verificación del email.

### La memoria (Capa de Estado o Store)
Es el "cerebro" del login. Aquí guardamos una variable que nos dice en qué pantalla está el usuario (login o registro). También nos encargamos de revisar que los campos del formulario estén bien escritos. Por ejemplo, si está intentando registrarse, somos muy estrictos y comprobamos si el correo ya existe, pero si solo está iniciando sesión, las reglas son más relajadas.

### La conexión (Capa de Servicios y API)
Esta parte es la única que habla con el servidor (el backend). Tiene funciones dedicadas a enviar los datos para iniciar sesión, registrarse o mandar el código de verificación. Cuando el servidor nos da el "ok", esta capa avisa al resto de la aplicación para cargar el perfil de la persona y llevarla a la pantalla principal.

## 4. Conclusiones y retos encontrados

Uno de los retos del sistema de autenticación fue el intentar no repetir código, porque los tres procesos hacen cosas muy parecidas (como validar correos o contraseñas), pero se comunican con el servidor de forma diferente. La solución fue usar las nuevas "signals" de Angular, que nos permitieron hacer que los formularios respondieran al momento cuando el usuario pasaba de iniciar sesión a registrarse, sin que la página se quedara bloqueada.

Además, añadir la ventanita emergente para poner el código del correo mejoró muchísimo la experiencia de uso, consiguiendo que recuperar una contraseña sea un proceso fácil, moderno y seguro.
