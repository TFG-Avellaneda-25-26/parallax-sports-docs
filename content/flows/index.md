---
title: Flows
description: "Cross-system flows — end-to-end traces of features that span multiple services"
tags:
  - architecture
---

# Flows

The individual stack docs explain the parts. This section explains the conversations between those parts — end-to-end flows that cross service boundaries.

Each flow traces a user-visible behavior from trigger to resolution, linking back to the relevant technical pages along the way.

- **[[alert-delivery]]** — The primary flow. A user follows a team → external sync creates an event → alert generation → Redis Stream → Ktor worker → channel delivery → status callback.
- **[[user-registration]]** — Register → email verification → login → JWT → dashboard.
- **[[data-sync]]** — Scheduler triggers daily → external API → upsert pipeline → events ready for alerts.
- **[[artifact-pipeline]]** — Alert needs an image → Playwright screenshot → Cloudinary upload → artifact attached to alert.
- **[[oauth-discord-flow]]** — Discord OAuth2 web login + bot account linking via `user_identities`.
