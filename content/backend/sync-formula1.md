---
title: Formula 1 Sync
description: "OpenF1 API integration — meetings, sessions, circuits, and drivers"
tags:
  - backend
  - sync
  - formula1
---

# Formula 1 Sync

Synchronizes Formula 1 data from the [OpenF1 API](https://api.openf1.org/v1).

## Data model mapping

| OpenF1 concept | Local entity | Notes |
|----------------|-------------|-------|
| Meeting | Parent `Event` | Race weekend container |
| Session | Child `Event` | Practice, qualifying, race |
| Circuit | `Venue` | With timezone for display |
| Driver | `Participant` (athlete) | Linked via `EventEntry` |

Events use hierarchical self-reference: sessions have `parent_event_id` pointing to the meeting.

## Sync flow

`Formula1SyncService.syncYear(year)`:

1. Fetch all meetings for the year from OpenF1
2. Fetch all sessions for the year from OpenF1
3. Upsert via `Formula1SyncWriteService.syncSeason()` — creates Sport, Competition, Season, Venues, Meetings, Sessions
4. Post-process: generate user alerts for synced session events via `UserEventAlertGenerationService`
5. Return summary: meetings fetched/upserted, sessions fetched/upserted, venues upserted

## Public API

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/formula1/sessions/{year}` | GET | Get all sessions for a year (chronological, with venue logos) |

## Admin API

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/admin/formula1/sync/{year}` | POST | Trigger full year sync |
