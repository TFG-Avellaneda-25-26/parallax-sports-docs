---
title: Flujos
description: "Índice de los flujos end-to-end del sistema Parallax Sports"
tags: [flujos, arquitectura]
---

# Flujos

Flujos principales del sistema, desde la ingesta de datos externos hasta la entrega de notificaciones al usuario.

| Flujo                                                      | Descripción                                                                                        |
| ---------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| [[entrega-alertas\|Entrega de alertas]]                    | Ciclo completo desde la sincronización de datos hasta la entrega de una alerta por Discord o email |
| [[pipeline-artefactos\|Pipeline de artefactos]]            | Generación de capturas de pantalla con Playwright y almacenamiento en Cloudinary                   |
| [[registro-usuario\|Registro de usuario]]                  | Registro, verificación de email por OTP y limpieza de cuentas no verificadas                       |
| [[sincronizacion-datos\|Sincronización de datos externos]] | Ingesta diaria desde OpenF1, BallDontLie y PandaScore hacia PostgreSQL                             |
| [[oauth-discord\|OAuth Discord]]                           | Vinculación de cuenta Discord para recibir notificaciones vía bot                                  |
