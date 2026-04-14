---
title: Backend
description: "Spring Boot API documentation — authentication, data sync, alerts, exception handling, and observability"
tags:
  - backend
---

# Backend — Spring Boot API

The backend is a Spring Boot 4 application (Java 21) that serves as the central hub of the platform. It handles authentication, exposes the REST API, orchestrates external data synchronization, manages the alert lifecycle, and feeds the observability pipeline.

## Sections

| Page | What it covers |
|------|---------------|
| [[project-structure]] | Package-by-feature layout: `auth`, `bot`, `core`, `external`, `follow`, `notification`, `sport`, `user` |
| [[authentication]] | JWT + OAuth2 (Discord, Google), email verification, refresh tokens, security filter chain |
| [[data-model]] | Full PostgreSQL schema walkthrough — 13 table groups with annotated ER diagram |
| [[sync-pipeline]] | Plugin-based external API sync: `ExternalApiDailySyncJob` interface, scheduler, page budgets |
| [[sync-formula1]] | OpenF1 integration: sessions, circuits, drivers |
| [[sync-basketball]] | Balldontlie integration: NBA/WNBA games and teams |
| [[sync-pandascore]] | PandaScore esports integration: current state, code review findings |
| [[alerts-system]] | The full alert lifecycle: generation → dispatch → Redis Streams → callbacks → retry |
| [[redis-streams-contract]] | Producer-consumer contract between Spring and the Ktor workers |
| [[exception-handling]] | RFC 7807 ProblemDetail strategy, `GlobalExceptionHandler`, domain exceptions |
| [[observability]] | Logback → Loki, Actuator → Prometheus, structured logging |
| [[api-reference]] | REST surface overview, Swagger, Postman collections |
