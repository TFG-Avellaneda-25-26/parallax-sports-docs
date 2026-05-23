---
title: Decisiones
description: "Decisiones técnicas y arquitectónicas relevantes — formato ADR simplificado"
tags: [diario, decisiones, arquitectura]
---

# Decisiones

Cada decisión sigue el formato: **Contexto → Decisión → Consecuencias**.

## Reescritura multi-guild de ms-discord (Fase 3)

**Contexto:** La arquitectura inicial de ms-discord asumía un único servidor Discord. El bot se instalaba en un solo guild y todas las alertas se enviaban al canal configurado en ese guild. No existía el concepto de preferencias por usuario ni de DM.

**Decisión:** Reescribir ms-discord para soportar múltiples guilds simultáneamente, con preferencias de entrega por usuario (DM vs canal de guild) y overrides por deporte.

**Cambios implementados:**

- Nuevas tablas: `discord_guild_configs`, `discord_guild_sport_channels`, `user_discord_delivery_prefs`, `user_discord_sport_delivery_overrides`
- Nuevo comando `/parallax-delivery` para que cada usuario configure su preferencia de entrega.
- `DiscordRoutingResolver` en Spring calcula la ruta antes de publicar en el Redis Stream.
- Lifecycle de guilds: hooks `GuildJoinEvent` / `GuildLeaveEvent` para auto-install/uninstall del bot.
- `DiscordGuildSportChannelRepository` para gestionar canales por deporte por guild.

**Consecuencias:**

- Mayor flexibilidad para usuarios presentes en múltiples servidores.
- El campo `discordDeliveryMode` en el payload del stream es ahora crítico para el routing.
- Spring necesita conocer el estado de la configuración de Discord de cada usuario antes del dispatch. Si la configuración es incompleta o el usuario no está en ningún guild con el bot, la alerta queda en `failed_permanent`.

---

## [Placeholder: otras decisiones]

<!-- Añadir más decisiones usando el mismo formato -->

## Fuentes
