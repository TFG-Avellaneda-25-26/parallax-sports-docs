---
title: Animations
description: "GSAP parallax animations on the landing page — the 'Parallax' in the name"
tags:
  - frontend
---

# Animations

The landing page uses [GSAP](https://gsap.com/) (GreenSock Animation Platform) v3.14.2 for parallax scroll effects — which is where the project name comes from.

## Setup

GSAP helpers are centralized in `shared/lib/gsap.ts`, keeping animation utilities in the shared layer per [[fsd-architecture|FSD]] conventions.

## Usage

The landing page component applies parallax effects to create depth and motion as the user scrolls. These are purely visual — they don't affect layout or content rendering.

> [!info] Why GSAP?
> GSAP provides high-performance, cross-browser animations with fine-grained control over scroll-triggered effects. It's the industry standard for complex web animations.
