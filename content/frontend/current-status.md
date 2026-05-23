---
title: Frontend Status
description: "Honest progress report — what's built, what's stubbed, what's next"
tags:
  - frontend
  - wip
---

# Current Status

An honest look at where the frontend stands.

## What's built

- **Landing page** — mostly complete with parallax animations
- **Error page** — error display component with RFC 7807 `ProblemDetails` mapping
- **Theme toggle** — dark/light mode switching with signal store
- **FSD scaffold** — full architectural skeleton with path aliases
- **HTTP layer** — API client, error interceptor, auth interceptor structure
- **Routing** — lazy-loaded routes with auth guard wiring

## What's stubbed

- **Dashboard** — main authenticated view, not yet implemented
- **Settings** — user preferences page
- **Login / Register** — forms exist in structure, implementation in progress
- **Email verification** — UI component placeholder
- **View mode toggle** — cards/table switching, API service exists but not connected
- **Event feed widget** — placeholder for sport events display

## What's next

The frontend is early-stage compared to the backend and microservices. Key work remaining:

1. Complete auth flow (login/register forms → API → token storage → redirect)
2. Build the dashboard with event feed
3. Implement sport event cards and table views
4. Connect notification channel preferences in settings
5. Add user follow management

See [[things-to-improve]] for broader project-level improvements.
