---
title: Sync Pipeline
description: "Plugin-based external API synchronization — ExternalApiDailySyncJob interface, scheduler, and provider patterns"
tags:
  - backend
  - sync
aliases:
  - "External Sync"
  - "Data Sync"
---

# Sync Pipeline

The sync pipeline fetches event data from external sports APIs and upserts it into the local database. It uses a plugin architecture where each sport provider implements a common interface.

## Architecture

```
ExternalApiDailyScheduler (cron: 00:30 UTC)
    │
    ├── Formula1DailySyncJob ──→ OpenF1 API
    ├── BasketballDailySyncJob (NBA) ──→ Balldontlie API
    └── BasketballDailySyncJob (WNBA) ──→ Balldontlie API
```

### Plugin interface

```java
public interface ExternalApiDailySyncJob {
    String providerKey();           // e.g. "formula1", "nba"
    void sync(LocalDate executionDate);
}
```

All implementations are auto-discovered by Spring via `List<ExternalApiDailySyncJob>` injection.

### Scheduler

`ExternalApiDailyScheduler` runs at a configurable cron (default: `0 30 0 * * *` — 00:30 UTC daily):

1. Resolve execution date using configured timezone
2. Iterate through all registered jobs
3. Call `job.sync(executionDate)` for each
4. Catch exceptions per job — one provider failing doesn't block the others
5. Return summary: jobs discovered, succeeded, failed

Can also be triggered manually via `ExternalSyncAdminController`.

### Write pattern

All providers share the `SyncWriteHelper.setIfChanged` pattern — only persist when a field actually changed, avoiding unnecessary database writes.

## Providers

### Formula 1 — [[sync-formula1]]

- **API:** OpenF1 (`https://api.openf1.org/v1`)
- **Sync strategy:** Full year sync (meetings + sessions)
- **Post-sync:** Generates user alerts for synced session events

### Basketball — [[sync-basketball]]

- **API:** Balldontlie (`https://api.balldontlie.io`)
- **Leagues:** NBA and WNBA (separate jobs, configurable)
- **Sync strategy:** Page-based with date windowing, rate limit detection, page budget (default: 10 pages)

### Esports — [[sync-pandascore]]

- **API:** PandaScore
- **Status:** Partially implemented with known bugs
- **Sync strategy:** Two-phase (tournament discovery → match sync)

## Configuration

```yaml
app:
  external-sync:
    enabled: true
    zone-id: UTC
    daily-cron: "0 30 0 * * *"
    years-back: 0
    years-forward: 1
    nba-enabled: true
    wnba-enabled: true
```

## Admin endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/admin/sync/daily` | POST | Trigger daily sync manually |
| `/api/admin/formula1/sync/{year}` | POST | Sync specific F1 year |
| `/api/admin/basketball/sync` | POST | Sync basketball with date range |
