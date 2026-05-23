---
title: Panel de Ajustes y Preferencias
description: Documentación sobre la configuración del usuario, preferencias visuales y arquitectura modular del panel de ajustes.
---

# Panel de Ajustes y Preferencias (Settings)

## 1. Introducción

El Panel de Ajustes es el espacio privado donde cada usuario puede personalizar su experiencia dentro de Parallax Sports. Su finalidad es dar control total a la persona sobre sus datos personales, la seguridad de su cuenta y cómo prefiere visualizar la información (temas visuales, zonas horarias y formatos de fecha).

El objetivo de este módulo es centralizar todas estas opciones en una interfaz limpia y navegable. Una vez que el usuario entra aquí, puede desde cambiar su contraseña hasta gestionar la manera de recibir información de los diferentes eventos deportivos.

## 2. Análisis y diseño del proyecto

### 2.1. Descripción de la arquitectura web

Como todo el Frontend, el Panel de Ajustes está diseñado bajo la arquitectura Feature-Sliced Design (FSD) y funciona como una SPA, lo que significa que el usuario puede cambiar de una pestaña de ajustes a otra sin tiempos de carga.

Para mantener el código ordenado, el panel está dividido en "sub-módulos" independientes:
- **Cuenta (Account):** Para datos personales, correos y contraseñas.
- **Preferencias (Preferences):** Para ajustes visuales, zonas horarias y formato horario.
- **Seguidos (Follows):** Para gestionar los equipos o ligas que el usuario ha marcado como favoritos.
- **Administración (Admin):** Un panel especial visible solo para usuarios con privilegios.

### 2.2. Tecnologías y herramientas utilizadas

- **Angular 21:** Usando componentes independientes (Standalone Components).
- **@ngrx/signals:** Para gestionar qué sección del menú está activa y realizar desplazamientos suaves por la pantalla.
- **@angular/forms/signals:** Aquí es donde más brilla esta librería, ya que en lugar de tener un formulario gigante y pesado, cada ajuste (como cambiar el nombre o la contraseña) es un mini-formulario reactivo independiente.

### 2.3. Análisis de usuarios

En este panel interactúan dos perfiles de usuario autenticados:
- **Usuario Estándar:** Tiene acceso a cambiar sus propios datos, sus preferencias visuales y gestionar a qué equipos sigue.
- **Usuario Administrador:** Además de todo lo anterior, tiene acceso a la pestaña "Admin", donde puede gestionar datos globales de la plataforma.

### 2.4. Definición de requisitos funcionales y no funcionales

**Lo que tiene que hacer (Requisitos funcionales):**
- **Edición modular:** Cada dato (email, nombre, contraseña) se debe poder actualizar de forma individual pulsando un botón de guardar específico, sin obligar al usuario a enviar toda la página entera.
- **Navegación por anclas:** Si el usuario pulsa en el menú lateral sobre "Cambiar Contraseña", la página debe hacer scroll automáticamente hasta esa sección.
- **Preferencias en tiempo real:** Si el usuario cambia el tema (claro/oscuro) o la zona horaria, el cambio debe aplicarse de inmediato a toda la plataforma.

**Cómo tiene que funcionar (Requisitos no funcionales):**
- **Reutilización:** Las validaciones de la nueva contraseña aquí deben ser exactamente las mismas que las que se usaron en el sistema de registro.
- **Experiencia fluida:** Las animaciones de desplazamiento (scroll) deben ser suaves y resaltar visualmente la sección a la que se acaba de llegar.

## 3. Organización de la lógica de negocio

La magia de este panel reside en cómo hemos separado las responsabilidades para que no sea un caos de código:

### Fábricas de Formularios (Form Factories)
En lugar de crear un controlador gigante para todos los datos del usuario, hemos programado pequeñas "fábricas" (por ejemplo, `createEmailForm()`, `createPasswordForm()`). Cada una de estas fábricas crea un mini-formulario inteligente con sus propias reglas de validación. Así, el componente visual (`AccountComponent`) solo tiene que llamar a estas fábricas y pintar las casillas, manteniéndose súper limpio y fácil de leer.

### El Navegador de Ajustes (SettingsNavStore)
Para la navegación, creamos un pequeño gestor de memoria llamado `SettingsNavStore`. Cuando el usuario hace clic en una opción del menú lateral, este almacén guarda el ID de la sección. Automáticamente, el componente principal detecta este cambio y usa una función del navegador (`scrollIntoView`) para deslizarse suavemente hasta ese punto, iluminando la sección durante un segundo para que el usuario sepa dónde está.

### Conexión con el Usuario Global (UserStore)
Todos estos mini-formularios, cuando se guardan con éxito a través de la API, avisan al almacén central del usuario (`UserStore`) para que actualice la información global. Así, si te cambias el nombre, el nombre nuevo aparece reflejado al instante en el menú principal sin tener que recargar.

## 4. Conclusiones y retos encontrados

El mayor reto al construir el Panel de Ajustes fue evitar el "código espagueti". Históricamente, las páginas de configuración tienden a convertirse en archivos enormes llenos de variables porque tienen decenas de campos distintos.

La solución que implementamos fue dividir la página en mini-formularios independientes (Fábricas de Formularios con Signals). Nos permitió reutilizar las validaciones que ya teníamos hechas para el sistema de Registro, garantizando que las reglas de seguridad son las mismas en toda la web. 

Además, añadir el desplazamiento suave con iluminación (highlighting) al navegar por el menú le ha dado un toque muy moderno y profesional a la experiencia de uso, demostrando atención a los pequeños detalles.
