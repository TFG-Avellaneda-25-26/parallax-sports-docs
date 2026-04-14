---
title: Telegram Microservice
description: "Telegram bot with command dispatch — wired but alert delivery not yet implemented"
tags:
  - microservices
  - wip
---

# ms-telegram

The Telegram microservice has the bot infrastructure in place but alert delivery is **not yet functional**.

**Port:** 8083
**Stream:** `alerts.telegram.v1`
**Group:** `telegram-workers`

> [!warning] Placeholder
> `TelegramService.sendEvent()` currently returns an empty string. The consumer architecture is wired, but actual message delivery to Telegram is not implemented yet. See [[things-to-improve]].

## What's wired

- `TelegramBot` — builds the bot instance and starts long-polling
- `TelegramDispatcher` — routes command messages to handlers via coroutine scope
- `ITelegramCommand` interface — command contract matching the Discord pattern
- `/login` command — generates auth URL (same pattern as Discord)
- `TelegramAlertConsumer` — extends [[redis-stream-consumer|RedisStreamConsumer]], calls `sendEvent()`, returns provider ID

## What's missing

- Actual message sending via the Telegram Bot API
- Rich message formatting (Markdown/HTML)
- Image attachment for artifact-required alerts
- Channel/chat ID resolution from user settings

## Configuration

```hocon
parallaxbot.telegram {
    token = ${TELEGRAM_TOKEN}
}
```
