---
title: Dashboard y Eventos
description: Documentación sobre el panel principal, la gestión de vistas (grid/tabla) y el sistema de filtrado de eventos deportivos.
---

# Panel Principal (Dashboard) y Eventos

## 1. Introducción

El Dashboard es una de las partes principales de la aplicación. Una vez que el usuario inicia sesión de forma exitosa, este es el primer lugar al que llega. Su finalidad es mostrar de un solo vistazo todos los eventos deportivos que están ocurriendo o que están programados, permitiendo al usuario explorarlos de forma cómoda e intuitiva.

El objetivo de esta pantalla es que cada usuario pueda organizar tanta cantidad de información deportiva (decenas de eventos, distintas ligas y juegos) como necesite, sin sentirse abrumado. Para ello, se ha diseñado un sistema que permite cambiar la forma en la que se ven los datos y aplicar filtros avanzados al instante.

## 2. Análisis y diseño del proyecto

### 2.1. Descripción de la arquitectura web

Al igual que el resto de la plataforma, el Dashboard funciona de forma dinámica sin recargar la página (SPA). Sigue la estructura de **Feature-Sliced Design (FSD)**, por lo que el código no está mezclado en un archivo gigante, sino repartido:

- **Capa de Página (`src/pages/dashboard`)**: Es el "lienzo" en blanco. Simplemente se encarga de coger los componentes visuales de los filtros y de las listas de eventos, y ponerlos en la pantalla principal.
- **Capa de Features (`src/features/dashboard` y `src/features/event`)**: Aquí es donde ocurre la magia. Hemos separado todo lo que tiene que ver con *filtrar* y *cambiar de vista* (en la feature de dashboard) de lo que tiene que ver puramente con *pintar eventos* (en la feature de event, que provee las tarjetas y las tablas).

### 2.2. Definición de requisitos funcionales y no funcionales

**Requisitos funcionales:**
- **Resolución de datos antes de cargar:** Antes de que la página del Dashboard siquiera se muestre, el sistema debe haber descargado los eventos desde el servidor (usando un *Resolver* en la ruta).
- **Múltiples Vistas:** El usuario debe poder alternar entre una vista de "Tarjetas" (Grid) y una vista de "Tabla" para revisar los eventos.
- **Sistema de Filtros:** El usuario debe poder abrir un panel lateral y filtrar los eventos usando un árbol de categorías (por ejemplo: filtrar por Videojuego -> Liga).

**Requisitos no funcionales:**
- **Velocidad y Reactividad:** Al aplicar un filtro, la lista de eventos debe actualizarse instantáneamente sin tirones, ya que el filtrado se hace directamente en la memoria del navegador.

## 3. Organización de la lógica de negocio

Para que esta pantalla no se vuelva lenta cuando hay muchos datos, hemos dividido la memoria (el estado) usando la potencia de `@ngrx/signals`:

### El Gestor de Datos (EventStore)
Tenemos un "almacén" que se encarga exclusivamente de guardar la lista completa de eventos que nos ha mandado el servidor. No hace nada más que tener los datos brutos guardados y listos para usar.

### El Gestor de Vista (DashboardViewStore)
Es un pequeño almacén de memoria que solo guarda un dato: si el usuario prefiere ver la pantalla en modo `grid` (tarjetas) o en modo `table` (tabla). Cuando el usuario pulsa un botón en la barra superior, este dato cambia y la interfaz entera se transforma al momento.

### El Gestor de Filtros (EventFilterStore)
Aquí reside la parte más compleja. Este gestor analiza todos los eventos que hay en el `EventStore` y construye dinámicamente un árbol de categorías (ligas, equipos, juegos). Cuando el usuario marca o desmarca una casilla en este árbol, el filtro procesa la lista original y le entrega a la pantalla solo los eventos que coinciden. 

## 4. Conclusiones y retos encontrados

El mayor reto a la hora de programar este Dashboard fue **el rendimiento visual**. Si hubiéramos hecho peticiones al servidor cada vez que el usuario quería aplicar un filtro o cambiar la forma de ver los datos (tabla o tarjeta), la pantalla iría a tirones y el backend sufriría mucha carga.

La solución fue centralizar la lógica en el frontend. Usando las Signals, descargamos todos los eventos necesarios una sola vez al entrar. A partir de ahí, tanto los cambios de vista como el árbol de filtros operan directamente sobre la memoria local de la aplicación. Esto ha logrado una experiencia de usuario increíblemente fluida: si buscas un partido en concreto, aparece literalmente al instante según vas escribiendo o marcando casillas.