---
title: Parallax Sports
description: "Documentation hub for the Parallax Sports platform — a customizable sports events dashboard with multi-channel alert delivery"
---

# Parallax Sports

A customizable sports events dashboard with real-time, multi-channel alert delivery. Built as a full-stack distributed system spanning a Spring Boot API, an Angular frontend, five Ktor microservices, and a self-hosted infrastructure on Proxmox.

> [!tip] Start here
> If this is your first time reading these docs, start with the [[architecture-overview|Architecture Overview]] to see how everything fits together, then explore whichever stack interests you.

## Sections

- **[[project/index|Project]]** — The big picture: what the platform does, the tech stack, the domain model, and a glossary of terms used throughout.

- **[[backend/index|Backend]]** — The Spring Boot API: authentication, data sync from external sports APIs, the alert lifecycle, exception handling, and observability.

- **[[frontend/index|Frontend]]** — The Angular dashboard: Feature-Sliced Design architecture, routing, state management, and the parallax animations.

- **[[microservices/index|Microservices]]** — The Ktor alert workers: Discord bot, email via Gmail, Telegram bot, screenshot generation with Playwright, and image storage on Cloudinary.

- **[[infra/index|Infrastructure]]** — Self-hosted deployment: Docker Compose, Traefik reverse proxy, Redis, the observability stack (Prometheus + Loki + Grafana), and CI/CD.

- **[[flows/index|Flows]]** — How things connect: end-to-end flows that cross multiple systems, from alert delivery to user registration to data sync.

- **[[journal/index|Journal]]** — The human side: the team, the timeline, architectural decisions, struggles, things to improve, and how AI tools were used.

- **[[guides/index|Guides]]** — Practical guides: local setup, contributing, and code documentation standards.
