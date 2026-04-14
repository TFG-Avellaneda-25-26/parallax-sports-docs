---
title: Data Sync Flow
description: "Scheduler → external API → upsert pipeline → events ready for alerts"
tags:
  - sync
  - architecture
---

# Data Sync Flow

How event data gets from external sports APIs into the local database.

## Sequence

```mermaid
sequenceDiagram
    participant Cron
    participant Scheduler as ExternalApiDailyScheduler
    participant Job as DailySyncJob
    participant Client as API Client
    participant API as External API
    participant Writer as SyncWriteService
    participant DB as PostgreSQL
    participant Alerts as AlertGenerationService

    Cron->>Scheduler: 00:30 UTC daily
    Scheduler->>Job: sync(executionDate) per provider
    
    Job->>Client: Fetch data
    Client->>API: GET /matches?date=...
    API-->>Client: Paginated response
    
    loop Each page
        Client->>Writer: Upsert batch
        Writer->>DB: Sport, Competition, Season
        Writer->>DB: Event (idempotent by external_provider + external_id)
        Writer->>DB: Participant, EventEntry
        Writer->>DB: MediaAsset (logos)
    end

    Job-->>Scheduler: SyncResult

    Note over Alerts: Post-sync hook (F1)
    Job->>Alerts: Generate alerts for new events
    Alerts->>DB: Create user_event_alerts
```

## Provider differences

| Provider | API | Pagination | Sync window |
|----------|-----|------------|-------------|
| [[sync-formula1\|Formula 1]] | OpenF1 | Full year fetch | Entire year |
| [[sync-basketball\|Basketball]] | Balldontlie | Cursor-based (page budget: 10) | Date window from last sync |
| [[sync-pandascore\|PandaScore]] | PandaScore | Page-based | Two-phase: tournaments then matches |

## Idempotency

Events are deduplicated by `(external_provider, external_id)`. The `SyncWriteHelper.setIfChanged` pattern avoids unnecessary database writes when data hasn't changed.

## Error handling

Each provider runs independently — one failing doesn't block the others. The scheduler aggregates success/failure counts and logs per-provider results.
