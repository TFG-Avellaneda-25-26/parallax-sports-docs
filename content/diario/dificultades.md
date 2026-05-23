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

## [Placeholder: otras dificultades]

<!-- Añadir más problemas y soluciones -->

## Fuentes
