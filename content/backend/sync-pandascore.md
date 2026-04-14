---
title: PandaScore Sync
description: "Esports integration via PandaScore API — current state, code review findings, and recommended fixes"
tags:
  - backend
  - sync
  - esports
aliases:
  - "Esports Sync"
  - "PandaScore"
---

# PandaScore Sync (Esports)

PandaScore is a single API that covers multiple esports (LoL, CS2, Dota 2, Valorant, Overwatch). Unlike the [[sync-formula1|Formula 1]] and [[sync-basketball|Basketball]] integrations where one API maps to one sport, PandaScore requires routing matches to per-game `Sport` rows.

> [!warning] Work in progress
> This integration compiles and syncs data, but has several correctness bugs. See the code review findings below for details and the priority fix list at the bottom.

## Folder structure

The `pandascore/` module is correct — one API covering multiple esports belongs in one module. The issue is in the data model, not the structure.

## Recommended implementation strategy

### Two-phase daily sync

Use a two-phase approach inside the existing `PandascoreDailySyncJob` / `ExternalApiDailySyncJob` flow:

**Phase 1 — Tournament discovery (runs first):**

1. For each of the 5 supported games, call `GET /tournaments?filter[tier]=s,a&filter[videogame_slug]=<slug>&per_page=100` and paginate
2. Upsert `Sport` (per-game) + `Competition` (from league) + `Season` (from serie) + league logo
3. Collect tournament IDs into an in-memory `Set<Long>` for Phase 2

**Phase 2 — Match sync:**

1. Call `GET /matches?filter[tournament_id]=id1,id2,...&per_page=100` paginated
2. This guarantees only S/A tier matches — no client-side filtering needed
3. Upsert `Event` + `Participant` + `EventEntry` + team logos

### `PandascoreVideogame` enum

Following the `BasketballLeague` pattern:

| Value | API Slug | Sport Key | Provider |
|-------|----------|-----------|----------|
| `LOL` | `lol` | `esports-lol` | `pandascore-lol` |
| `CS2` | `cs-go` | `esports-cs2` | `pandascore-cs2` |
| `DOTA2` | `dota-2` | `esports-dota2` | `pandascore-dota2` |
| `VALORANT` | `valorant` | `esports-valorant` | `pandascore-valorant` |
| `OVERWATCH` | `ow` | `esports-overwatch` | `pandascore-overwatch` |

## Code review findings

### Critical bugs

**1. All esports share one `Sport` row**

```java
private static final String SPORT_KEY = "esports";
private static final String SPORT_NAME = "Esports";
```

Every match gets saved under the same Sport, making it impossible to follow LoL vs Valorant separately. Fix: derive Sport from `match.videogame().slug()` using the enum above.

**2. Opponents saved but never linked to events**

`upsertParticipant` saves `Participant` rows but never creates `EventEntry` records. Without `EventEntry`, you cannot query which teams played in a match. Fix: call `upsertEventEntry` after saving each participant, with `display_order` from array position.

**3. Status saved raw — violates DB CHECK constraint**

| PandaScore | DB CHECK | Needs mapping |
|------------|----------|---------------|
| `not_started` | `scheduled` | yes |
| `running` | `live` | yes |
| `finished` | `finished` | no |
| `canceled` | `cancelled` | yes (typo) |

Saving `"not_started"` directly will fail the CHECK constraint at runtime. Fix: add `normalizeStatus()` like basketball has.

### Other bugs

- **Redundant save** — `created ? eventRepository.save(event) : eventRepository.save(event)` — both branches identical. Apply `setIfChanged` pattern.
- **Team logos never saved** — `PandaScoreTeamDto` has `image_url` but `upsertParticipant` ignores it. No `MediaAsset` rows created for esports teams.
- **Participant lookup by name, not external ID** — risks cross-sport collision once per-game Sports exist.
- **League logo saved unconditionally** — no existence check, creates duplicate rows on every sync run.
- **Season from current year** — uses `OffsetDateTime.now().getYear()` instead of `serie.year()` from the API.
- **`event_type` never set** — should default to `"match"` at minimum.
- **`incomplete` flag logic inverted** — uses `&&` instead of `||`, masking budget exhaustion.
- **Videogame filter parameter name wrong** — the filter is likely being silently ignored, pulling all games.
- **Controller copy-paste** — four identical methods for four games. Collapse to one endpoint with a path variable.

### What's actually fine

- `PandascoreClient` structure is correct — same `RestClient.Builder` pattern, proper API key header, good error handling
- `PandascoreDailySyncJob` implements `ExternalApiDailySyncJob` correctly
- DTOs have `@JsonIgnoreProperties(ignoreUnknown = true)`
- Rate limit detection is solid

## Priority fix order

1. Add `videogame` to DTO + create per-game `Sport` rows
2. Fix `normalizeStatus` — runtime CHECK constraint failure
3. Fix `EventEntry` linking — orphaned participants
4. Add team logo saving via `image_url`
5. Fix `MediaAsset` duplicate saves for league logos
6. Collapse controller to one method + enum
7. Fix videogame filter param name
8. Apply `setIfChanged` pattern
9. Fix season from `serie.year`, set `event_type`
10. Fix `incomplete` flag
11. Fix participant lookup by external ID
