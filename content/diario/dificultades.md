---
title: Dificultades
description: "Problemas técnicos encontrados durante el desarrollo y cómo se resolvieron"
tags: [diario, dificultades, debugging]
---

# Dificultades

## NgRx Signals: Colisión de nombre estado/método (NG0600)

**Problema:** En un `signalStore` de `@ngrx/signals`, si una propiedad de `withState` y un método de `withMethods` tienen el mismo nombre, el método silencia la señal sin error en tiempo de compilación.

**Síntoma observado:** `FilterDrawerStore` tenía `open: false` en el estado y `open()` como método. En el template, `store.open()` resolvía como método, no como señal. Angular lanzaba NG0600 (escritura de señal durante Change Detection), abortaba el ciclo de CD, y `VerifyEmailDialogComponent` nunca renderizaba aunque `VerifyEmailService.isOpen()` fuera `true`.

**Diagnóstico:** Al no aparecer errores visibles en consola (NG0600 es un warning interno), el bug parecía un problema de lógica en el dialog. La colisión es invisible hasta que se inspecciona el store directamente.

**Solución:** Renombrar el estado a `isOpen: false`. El método `open()` queda intacto. Convención establecida: usar siempre `isOpen` / `isLoading` / `hasError` para estado booleano, y verbos imperativos (`open()`, `load()`, `setError()`) para métodos.

**Lección:** En `@ngrx/signals`, los nombres de estado y métodos comparten el mismo namespace en el objeto del store. Revisar siempre si el nombre elegido para un método ya existe como propiedad de estado.

---

## FSD sin documentación previa

Adoptamos [Feature-Sliced Design](https://feature-sliced.design/) como arquitectura del frontend Angular. La metodología es sólida y merece la pena, pero cometimos el error de empezar a desarrollar antes de documentar bien los procedimientos y de tener claro dónde iba cada pieza.

El resultado fue confusión recurrente: ramas que mezclaban `features` y `pages`, dudas sobre si algo pertenecía a `widgets` o a `shared`, y convenciones que cada uno aplicaba de forma distinta. Al ser una metodología nueva para el equipo, sin una guía interna de referencia, cada decisión de estructura se resolvía sobre la marcha.

**Lección:** Con una metodología nueva, la documentación interna debe preceder al código. Unas pocas horas definiendo las reglas de cada capa habrían ahorrado semanas de refactorizaciones y conflictos de ramas.

---

## Redis: documentación densa y curva de aprendizaje pronunciada

Redis fue uno de los bloques más costosos del proyecto. La documentación oficial es extensa pero no siempre fácil de seguir, especialmente en los apartados de Streams, grupos de consumidores y gestión de TTL. Al principio dependimos más de lo que nos hubiera gustado de la IA para salir adelante, aunque con el tiempo ganamos soltura.

Ver también: [[uso-ia#Cuando la IA no ayudó o generó problemas|Uso de IA — Redis]].

---

## Balance entre curiosidad técnica y priorización de tareas

Teníamos una filosofía clara: ir más allá de lo visto en clase, leer artículos, ver vídeos, profundizar. Eso es positivo y nos llevó a soluciones interesantes. El problema fue que no supimos combinar esa mentalidad con la disciplina de priorizar las tareas más importantes en cada momento.

El resultado fue que dedicábamos tiempo a explorar tecnologías o características antes de tener estabilizada la base, lo que a veces generaba deuda técnica o retrasos en funcionalidades críticas.

---

## Ausencia de tests en una arquitectura compleja

Desde el principio decidimos no escribir tests. En un proyecto con Redis Streams, PostgreSQL, varios microservicios Ktor y una API Spring, esa decisión tuvo un coste real: verificar que los componentes se comunicaban bien, que los contratos de los streams se respetaban y que las funcionalidades no tenían regresiones requería pruebas manuales largas y repetitivas.

Testing automatizado habría agilizado el ciclo de desarrollo de forma significativa, especialmente para los flujos de integración entre servicios.

---

## Ktor: múltiples refactorizaciones hasta encontrar la estructura

Ktor era un framework nuevo para el equipo. La organización inicial de los microservicios no se ajustaba bien a lo que queríamos, y necesitamos varias refactorizaciones hasta dar con una estructura limpia y consistente. Cada iteración enseñaba algo, pero también consumía tiempo que podríamos haber invertido en funcionalidades.

---

## Angular 21: features experimentales y debugging sin red

Usar Angular 21 fue en general una buena experiencia: los Signal Forms son mucho más naturales que los reactivos o los template-driven vistos en clase. El problema llegó al implementar features nuevos de Angular 21 como el `aria-tree` y el `autocomplete` con ARIA completo, que en las demos y en los docs pintaban bien pero en producción requerían un debugging tedioso y poco documentado.

La IA aquí no ayudaba prácticamente nada, lo cual fue positivo en el sentido de que nos obligó a buscarnos la vida, pero costoso en tiempo. También aparecieron bugs curiosos en la combinación señales + View Transition API y en el `aria-tree` que, una vez encontrados, resultaban ser enredos o tonterías que daban más risa que frustración.

## Fuentes
