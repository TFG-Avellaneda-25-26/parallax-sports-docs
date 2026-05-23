---
title: Backend
description: Índice de la documentación del backend de Parallax Sports (Spring Boot).
tags:
  - backend
---

# Backend

Servicio principal desarrollado con Spring Boot. Expone la API REST, gestiona la autenticación, sincroniza datos deportivos externos y genera alertas para los usuarios.

## Páginas

| Página                                             | Descripción                                                                  |
| -------------------------------------------------- | ---------------------------------------------------------------------------- |
| [[estructura-proyecto\|Estructura del proyecto]]   | Layout de paquetes package-by-feature y responsabilidad de cada módulo.      |
| [[autenticacion\|Autenticación]]                   | JWT, OAuth2 (Google/Discord), verificación de email y revocación de tokens.  |
| [[modelo-datos\|Modelo de datos]]                  | Entidades JPA, campos clave y relaciones entre tablas.                       |
| [[sistema-alertas\|Sistema de alertas]]            | Generación, dispatch, máquina de estados y reintentos de alertas de eventos. |
| [[sincronizacion-datos\|Sincronización de datos]]  | Jobs diarios de ingesta desde OpenF1, BallDontLie y PandaScore.              |
| [[redis-streams-contrato\|Contrato Redis Streams]] | Definición del protocolo productor-consumidor para despacho de alertas.      |
| [[manejo-excepciones\|Manejo de excepciones]]      | Problem Details RFC 7807, jerarquía de excepciones y auditoría AOP.          |
| [[observabilidad\|Observabilidad]]                 | Métricas Micrometer, trazabilidad MDC y endpoints Actuator.                  |
| [[api-reference\|Referencia de la API]]            | Tabla completa de endpoints REST agrupados por módulo.                       |

## Fuentes
