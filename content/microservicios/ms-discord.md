---
title: ms-discord
description: Microservicio de Discord — bot JDA multi-guild y consumidor de alertas que enruta embeds a canales de servidor o DMs según las preferencias del usuario.
tags:
  - microservicios
  - discord
  - ktor
  - jda
---

`ms-discord` implementa el bot de Discord de Parallax Sports y el consumidor del stream de alertas. Corre en el puerto **8082**.

## Stream consumer

- **Stream:** `alerts.discord.v1`
- **Grupo:** `discord-workers`
- `DiscordAlertConsumer` extiende [[redis-stream-consumer|RedisStreamConsumer]].
- `sendToProvider(message, artifactUrl)` delega en `DiscordService.sendEventEmbed(message, artifactUrl)`.

## Arquitectura multi-guild

El bot puede estar instalado en múltiples servidores (guilds) simultáneamente:

- **`DiscordGuildConfig`** — almacena el canal por defecto y quién instaló el bot en ese guild.
- **`DiscordGuildSportChannel`** — override de canal por deporte dentro de un guild.
- **`UserDiscordDeliveryPreference`** — modo de entrega global del usuario: `DM` o `GUILD_CHANNEL`.
- **`UserDiscordSportDeliveryOverride`** — override de modo de entrega por deporte.

## Enrutado en `DiscordService`

```
discordDeliveryMode = "DM"
  → jda.retrieveUserById(discordUserId).complete()
  → user.openPrivateChannel().complete()
  → channel.sendMessageEmbeds(embed).complete()

discordDeliveryMode = "GUILD_CHANNEL"
  → jda.getTextChannelById(discordChannelId)
  → channel.sendMessageEmbeds(embed).complete()

else → throw ProviderPermanentFailureException("discord_unroutable")
```

## Comandos slash

| Comando                                             | Descripción                                                                               |
| --------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `/link`                                             | Envía un embed efímero con la URL de OAuth de Parallax Sports para vincular la cuenta     |
| `/events [type]`                                    | Obtiene eventos de Spring, los agrupa por tipo y envía chunks de máx. 10 embeds           |
| `/parallax-setchannel [sport]`                      | Requiere `MANAGE_SERVER`. Configura el canal por defecto o por deporte en el guild actual |
| `/parallax-delivery <mode> [sport] [guild] [clear]` | Configura el modo `DM`/`GUILD_CHANNEL` para el usuario, con override opcional por deporte |

## Ciclo de vida del guild

- **`GuildJoinEvent`** — el bot se instala en un nuevo servidor:
  1. Llama a `SpringDiscordAdminClient.installGuild()`.
  2. Envía un DM al owner del guild con el mensaje de configuración inicial.
- **`GuildLeaveEvent`** — el bot es eliminado del servidor:
  1. Llama a `SpringDiscordAdminClient.uninstallGuild()`.
  2. Limpia la configuración del guild en Spring.

## SportsCache

- Protegido por `Mutex`, TTL de 10 minutos.
- Consulta la lista de deportes desde Spring (`GET /api/sports`).
- Usado para el autocompletado del comando `/parallax-setchannel`.
- Si el fetch devuelve vacío, mantiene la caché anterior (resiliencia ante fallos).

## `SpringDiscordAdminClient` — endpoints

| Método | Ruta                                                     | Descripción                                                    |
| ------ | -------------------------------------------------------- | -------------------------------------------------------------- |
| GET    | `/api/internal/discord/users/by-discord/{discordUserId}` | Resuelve el ID de usuario de Spring a partir del ID de Discord |
| POST   | `/guilds/{guildId}/install`                              | Registra la instalación del bot en el guild                    |
| DELETE | `/guilds/{guildId}`                                      | Elimina la configuración del guild                             |
| POST   | `/guilds/{guildId}/channel`                              | Establece el canal por defecto del guild                       |
| PUT    | `/users/{userId}/delivery`                               | Configura la preferencia de entrega global                     |
| DELETE | `/users/{userId}/delivery`                               | Elimina la preferencia de entrega global                       |
| PUT    | `/users/{userId}/delivery/sports/{sportId}`              | Override por deporte (por ID)                                  |
| DELETE | `/users/{userId}/delivery/sports/{sportId}`              | Elimina override por deporte (por ID)                          |
| PUT    | `/users/{userId}/delivery/sport-keys/{key}`              | Override por deporte (por clave)                               |
| DELETE | `/users/{userId}/delivery/sport-keys/{key}`              | Elimina override por deporte (por clave)                       |

## Configuración JDA

- **Intents:** `MESSAGE_CONTENT`, `GUILD_MESSAGES`, `DIRECT_MESSAGES`
- Si `devGuild` está configurado, los comandos slash se registran solo en ese guild (despliegue instantáneo en desarrollo). En caso contrario, registro global.
- El bot llama a `awaitReady()` antes de registrar los comandos.

## Fuentes
