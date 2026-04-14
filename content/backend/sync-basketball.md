---
title: Basketball Sync
description: "Balldontlie API integration — NBA and WNBA games, teams, and date-windowed sync"
tags:
  - backend
  - sync
  - basketball
---

# Basketball Sync

Synchronizes NBA and WNBA data from the [Balldontlie API](https://api.balldontlie.io).

## Leagues

`BasketballLeague` enum maps each league to its API configuration:

| League | API value | Sport key |
|--------|-----------|-----------|
| NBA | `nba` | `nba` |
| WNBA | `wnba` | `wnba` |

## Sync strategy

Page-based pagination with intelligent windowing:

1. **Resolve start date** — latest synced date or execution date
2. **Paginate** through Balldontlie API using cursor-based pagination
3. **Per-game upsert** — `BasketballSyncWriteService` creates/updates Event, Participant, EventEntry with `home`/`away` sides
4. **Rate limit detection** — gracefully handles 429 responses
5. **Stop conditions** — max pages reached, cursor exhausted, or rate limited

**Default page budget:** 10 pages per sync run.

Team logos are resolved via `BasketballTeamLogoResolver` — a static mapping since Balldontlie doesn't provide logo URLs directly.

## Sync response

Returns: `fromDate`, `maxProcessedDate`, `pagesUsed`, `datesSynced`, `gamesFetched`, `gamesUpserted`, `incomplete`, `stoppedByRateLimit`.

## Public API

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/basketball/games` | GET | Query games by date range |
| `/api/basketball/teams` | GET | Get teams by league |

## Admin API

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/admin/basketball/sync` | POST | Trigger sync with date range and league |
