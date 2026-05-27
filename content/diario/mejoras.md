---
title: Mejoras
description: "Deuda técnica conocida, features incompletas y reflexiones sobre qué haríamos diferente"
tags: [diario, mejoras, deuda-tecnica]
---

# Mejoras

**Tests:** la ausencia de tests automatizados es la deuda más grande. Con una arquitectura de Redis Streams, PostgreSQL, microservicios Ktor y API Spring, añadir tests de integración entre servicios marcaría una diferencia real en la mantenibilidad y velocidad de desarrollo. Ver [[dificultades#Ausencia de tests en una arquitectura compleja|Dificultades — Tests]].

**CSS duplicado:** hay estilos repetidos entre componentes que deberían extraerse a tokens o utilidades compartidas. Una auditoría de CSS eliminaría redundancia y facilitaría los cambios de tema.

**Responsive:** aunque la mayor parte de la interfaz funciona en móvil, hay vistas que no están completamente revisadas en pantallas pequeñas. Requiere una pasada sistemática por todas las páginas.

**Redis Fallback con http:** el sistema de alertas depende completamente de Redis Streams para propagar eventos entre el backend Spring y los microservicios Ktor. Si Redis cae o no está disponible, no existe ningún mecanismo de fallback: los eventos simplemente se pierden y los microservicios no reciben las alertas. Queda pendiente implementar una capa de resiliencia que, ante la ausencia de Redis, recurra a llamadas HTTP directas entre servicios. Esto implicaría que el backend detecte el fallo de conexión con Redis y, en ese caso, envíe las notificaciones mediante peticiones HTTP a los endpoints correspondientes de cada microservicio, garantizando así la entrega de alertas aunque la infraestructura de mensajería no esté operativa.
