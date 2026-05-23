---
title: Sincronización de Datos Deportivos Externos
description: Cómo el backend importa y actualiza eventos de fútbol, baloncesto, Fórmula 1 y eSports desde APIs externas.
tags:
  - backend
  - sincronizacion
  - apis-externas
  - scheduler
---

# Sincronización de Datos Deportivos Externos

## 1. ¿Qué problema resuelve esto?

Parallax Sports muestra eventos deportivos de distintas disciplinas, pero la plataforma no tiene una fuente propia de datos: los obtiene de **APIs externas de terceros** (como API-Football para fútbol y baloncesto, la API oficial de Fórmula 1, o PandaScore para eSports).

Para no depender de hacer llamadas en tiempo real a esas APIs (lo que sería lento e inestable), el backend tiene un proceso de **sincronización diaria** que importa los eventos del día y los guarda en la base de datos propia. A partir de ese momento, el frontend consume los datos locales, que son mucho más rápidos de servir.

---

## 2. La arquitectura del sistema de sincronización

El sistema está diseñado con un **patrón de estrategia**: hay un planificador central (`ExternalApiDailyScheduler`) que no sabe nada de qué deporte está sincronizando. Simplemente itera sobre todos los "trabajos" registrados y los ejecuta uno por uno. Cada deporte tiene su propia implementación del trabajo de sincronización.

```
ExternalApiDailyScheduler
    ├── ejecuta → FootballSyncJob  (API-Football)
    ├── ejecuta → BasketballSyncJob  (API-Football)
    ├── ejecuta → Formula1SyncJob  (API oficial F1)
    └── ejecuta → PandaScoreSyncJob  (eSports)
```

Para añadir un deporte nuevo al sistema, solo hay que crear una nueva clase que implemente `ExternalApiDailySyncJob` y Spring la registra automáticamente.

---

## 3. ¿Cuándo se ejecuta?

La sincronización se lanza **cada día a las 00:30 UTC** mediante un cron de Spring (`@Scheduled`). Este horario se puede cambiar mediante configuración sin necesidad de redesplegar.

Adicionalmente, existe un **endpoint de administrador** (`POST /api/admin/sync/run`) que permite lanzar la sincronización manualmente en cualquier momento. Esto es útil durante el desarrollo o si una sincronización fallara y hubiera que relanzarla.

La ejecución está desactivable mediante la propiedad `app.external-sync.enabled=false`, lo que permite entornos de prueba sin tráfico a APIs externas.

---

## 4. ¿Qué pasa después de la sincronización?

Cuando la sincronización termina, ocurren dos cosas importantes:

### 4.1. Invalidación de caché

Los eventos del feed del dashboard están **cacheados en Redis** para servirse rápido. Tras una sincronización, esa caché se invalida automáticamente (se borran todas las entradas con el prefijo `event-feed:*`) para que la próxima petición del frontend lea los datos actualizados.

La invalidación usa un `SCAN` de Redis en lugar de `KEYS` para no bloquear el servidor Redis mientras busca las entradas a eliminar.

### 4.2. Generación de alertas

Cuando los eventos se guardan en la base de datos, el sistema publica un evento interno de Spring (`EventsIngestedEvent`). El `UserEventAlertGenerationService` escucha este evento y, **después de que la transacción se confirme** (`@TransactionalEventListener(phase = AFTER_COMMIT)`), genera las alertas para los usuarios que siguen esos deportes.

Esta separación es importante: las alertas se generan fuera de la transacción de sincronización para que un error en la generación de alertas no deshaga la importación de eventos.

---

## 5. El helper de escritura: `SyncWriteHelper`

Para simplificar la lógica de cada trabajo de sincronización, existe el `SyncWriteHelper`. Su función es hacer **upserts** de los eventos: si el evento ya existe en la base de datos (identificado por su clave externa), lo actualiza; si no existe, lo crea. De esta forma, se puede lanzar la sincronización varias veces sin duplicar datos.

---

## 6. Resultado de ejecución y observabilidad

Cada ejecución de la sincronización devuelve un `ExternalSyncExecutionResult` con:
- La fecha de ejecución.
- El número total de proveedores procesados.
- Cuántos tuvieron éxito y cuántos fallaron.

Esto se registra en los logs estructurados y, cuando se lanza desde el endpoint de administrador, se devuelve también en la respuesta HTTP para facilitar la depuración. La ejecución completa está medida con Micrometer (`@Timed`) y las métricas están disponibles en el endpoint de Actuator.
