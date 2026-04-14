---
title: Discord Microservice
description: "JDA Discord bot with slash commands and alert delivery via rich embeds"
tags:
  - microservices
  - alerts
---

# ms-discord

The Discord microservice runs a JDA bot that serves two purposes: interactive slash commands for users, and alert delivery via rich embeds.

**Port:** 8082
**Stream:** `alerts.discord.v1`
**Group:** `discord-workers`

## Bot setup

`DiscordBot` is a factory that builds the JDA instance:

- Enables `MESSAGE_CONTENT` gateway intent
- Registers guild slash commands on startup
- Commands are scoped to a specific server (configured via `server-id`)

`DiscordListener` extends JDA's `ListenerAdapter` and routes slash command interactions to the appropriate handler via a coroutine scope.

## Slash commands

| Command | Description |
|---------|-------------|
| `/events [type]` | Fetches upcoming events from the Spring API, groups by league, sends chunked embeds (max 10 per message) |
| `/login` | Generates a one-time auth link (UUID token + Discord user ID), sends as an ephemeral message |

Commands implement the `ICommand` interface: `name`, `description`, `options`, `execute(SlashCommandInteractionEvent)`.

## Alert delivery

`DiscordAlertConsumer` extends [[redis-stream-consumer|RedisStreamConsumer]]:

1. Receives `AlertStreamMessage` from the stream
2. Resolves artifact (screenshot) if needed
3. Calls `DiscordService.sendEventEmbed(message, artifactUrl)`
4. Returns the Discord message ID as the provider message ID

## Rich embeds

`EmbedFactory` builds Discord embeds for different contexts:

- **`createEventEmbed`** — event alert with optional image, competition name, start time, venue
- **`leagueSchedule`** — grouped event list for the `/events` command
- **`userAuth`** — auth link embed for `/login`
- **`error`** — error message embed

## Configuration

```hocon
parallaxbot.discord {
    token = ${DISCORD_TOKEN}
    server-id = "..."
    channels { ping = "..." }
}
```
