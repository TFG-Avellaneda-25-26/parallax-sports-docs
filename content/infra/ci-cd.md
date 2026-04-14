---
title: CI/CD
description: "Jenkins pipeline for build, test, and deployment"
tags:
  - infra
  - wip
---

# CI/CD

> [!warning] Work in progress
> The Jenkins pipeline is not yet documented. This page will be expanded with pipeline stages, secrets management, and deployment process.

## Stack

- **CI/CD server**: Jenkins
- **Deployment target**: Self-hosted Proxmox server
- **Container registry**: Docker images built and pushed for frontend and backend

## Expected pipeline stages

1. **Build** — compile and package
2. **Test** — run unit and integration tests
3. **Build images** — Docker image creation
4. **Deploy** — push to server and restart services
