---
title: Uso de IA
description: "Herramientas de IA utilizadas durante el desarrollo, qué ayudó y qué no"
tags: [diario, ia, herramientas]
---

# Uso de IA

## Fuentes

- [Thoughts on slowing the fuck down – Mario Zechner](https://mariozechner.at/posts/2026-03-25-thoughts-on-slowing-the-fuck-down)

---

## Herramientas utilizadas

La herramienta principal fue **Claude** (Anthropic), utilizado tanto en su interfaz web como integrado en el editor a través de GitHub Copilot. Al principio probamos Copilot para que generase comentarios de código automáticamente, pero el resultado era filler inútil que ensuciaba el código sin aportar valor, así que lo descartamos para ese uso rápidamente.

## En qué ayudó la IA

**Bugs concretos:** cuando nos atascábamos en un error específico con contexto suficiente (stacktrace, código relevante), la IA era útil para orientar el diagnóstico.

**Tareas monótonas y repetitivas:** operaciones que se hacen una vez y ya se conocen para siempre, como registrar rutas en `app.routes.ts`, generar boilerplate de módulos, o ajustar configuraciones de infraestructura. Aquí la IA ahorró tiempo real.

**Redis:** en las fases iniciales, cuando la documentación de Redis Streams nos resultaba densa, la IA sirvió de puente para entender conceptos y desbloquear la implementación. Ver [[dificultades#Redis documentación densa y curva de aprendizaje pronunciada|Dificultades — Redis]].

**Esta documentación:** teníamos un documento sin formatear tipo "memoria" con todos los enlaces a docs, inspiraciones y artículos que íbamos acumulando, más documentación de funcionalidades escrita por nosotros. La transición de parsear todo eso y moverlo a esta estructura de docs con Quartz ha sido íntegramente con IA (GitHub Copilot), que fue muy efectivo en esa tarea de transformación y restructuración.

## Cuando la IA no ayudó o generó problemas

**Angular 21 ARIA features:** al debuggear el `aria-tree` y el `autocomplete` con ARIA completo de Angular 21, la IA no aportaba nada útil. La documentación era escasa, los bugs eran nuevos y el contexto era demasiado específico. Tuvimos que resolver esos problemas por nuestra cuenta, lo que fue costoso en tiempo pero positivo como ejercicio. Ver [[dificultades#Angular 21 features experimentales y debugging sin red|Dificultades — Angular 21]].

**Comentarios de código automáticos:** Copilot en modo sugerencia de comentarios llenaba el código de texto genérico que no describía nada relevante. Se desactivó ese comportamiento desde el principio.

## Aprendizajes

La IA es más útil como herramienta de desbloqueo puntual que como copiloto permanente. Funciona bien en tareas con contexto claro y acotado (bugs con stacktrace, boilerplate conocido, transformación de documentos), y falla en problemas donde la documentación externa es escasa o el bug es nuevo. Aprender a distinguir cuándo usarla y cuándo no fue parte del aprendizaje del proyecto.
