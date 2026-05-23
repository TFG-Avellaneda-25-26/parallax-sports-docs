---
title: Mejoras
description: "Deuda técnica conocida, features incompletas y reflexiones sobre qué haríamos diferente"
tags: [diario, mejoras, deuda-tecnica]
---

# Mejoras

## Deuda técnica conocida

**Tests:** la ausencia de tests automatizados es la deuda más grande. Con una arquitectura de Redis Streams, PostgreSQL, microservicios Ktor y API Spring, añadir tests de integración entre servicios marcaría una diferencia real en la mantenibilidad y velocidad de desarrollo. Ver [[dificultades#Ausencia de tests en una arquitectura compleja|Dificultades — Tests]].

**CSS duplicado:** hay estilos repetidos entre componentes que deberían extraerse a tokens o utilidades compartidas. Una auditoría de CSS eliminaría redundancia y facilitaría los cambios de tema.

**Responsive:** aunque la mayor parte de la interfaz funciona en móvil, hay vistas que no están completamente revisadas en pantallas pequeñas. Requiere una pasada sistemática por todas las páginas.

## Features incompletas

**PandaScore — esports:** la integración con PandaScore está operativa, pero la API cubre muchos más esports de los que actualmente se muestran en la aplicación. Ampliar el soporte a más competiciones y juegos es una mejora directa con la infraestructura ya en pie.

**i18n:** la aplicación está en castellano. Añadir internacionalización (al menos inglés) ampliaría el alcance y es técnicamente viable con Angular i18n o `ngx-translate`.

## Qué haríamos diferente

**FSD desde el principio con guía interna:** adoptar Feature-Sliced Design antes de escribir código, con un documento claro de convenciones para cada capa. Ver [[dificultades#FSD sin documentación previa|Dificultades — FSD]].

**Priorizar antes de explorar:** la curiosidad técnica fue un activo, pero combinarla con una gestión de tareas más disciplinada habría reducido los bloqueos por deuda acumulada.

**Tests desde la fase de integración:** no necesariamente TDD completo, pero sí tests de integración para los contratos de los streams y los endpoints críticos desde que el backend estabilizó su estructura.

## Fuentes
