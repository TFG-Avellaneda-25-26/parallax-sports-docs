---
title: Animaciones GSAP
description: "Plugins GSAP registrados y animaciones por componente en Parallax Sports: MorphSVG, ScrollTrigger, DrawSVG, TextPlugin, Flip."
tags:
  - frontend
  - animaciones
  - gsap
---

# Animaciones GSAP

## Fuentes

- [GSAP Docs v3](https://gsap.com/docs/v3/)
- [GSAP SplitText – CodePen Collection](https://codepen.io/collection/bNPJyv?cursor=eyJwYWdlIjo4fQ==)
- [Cómo descubrí GSAP (YouTube)](https://youtu.be/shotcE73Vns?si=DoLea1O3wuNkfXxw)
- [Guía oficial GSAP SplitText (YouTube)](https://youtu.be/L1afzNAhI40?si=nhS_tekzVlkkFsth)
- [CSS tricks (YouTube)](https://youtu.be/Ol62e-dWu0E?si=LgRQi_9TWnsQ_JSP)
- [Ideas de websites cool (YouTube)](https://youtu.be/YjIM4HYSQaM?si=VDe7QRfsx8ZJlJ9g)
- [Awwwards](https://www.awwwards.com)
- [lightweight.info – inspiración de botón](https://lightweight.info/en)
- [SillySoftware Projects](https://www.sillysoftware.club/projects)
- [vladburca.com](https://vladburca.com/contact)
- [Melondy](https://melondy.com)
- [Ambient Canvas Backgrounds – tympanus](https://tympanus.net/Development/AmbientCanvasBackgrounds/index5.html)
- [stripe.dev](https://stripe.dev)
- [Raycast](https://www.raycast.com/)
- [Utopia Tokyo](https://www.utopiatokyo.com)
- [Lucide Icons](https://lucide.dev)
- [caniuse.com](https://caniuse.com)

---

## Registro de plugins

**Ubicación:** `shared/lib/gsap.ts`

Todos los plugins se registran una única vez en este fichero, que es importado por `app.config.ts`:

```typescript
gsap.registerPlugin(
  DrawSVGPlugin,
  MorphSVGPlugin,
  SplitTextPlugin,
  Flip,
  ScrollTrigger,
  TextPlugin,
  ScrollToPlugin,
)
```

---

## LandingPage

**Ubicación:** `pages/landing/`

### MorphSVG: ciclo de logos deportivos

- 7 paths SVG representan: Basketball, Dota2, Valorant, F1, StarCraft, CS, LoL.
- `MorphSVGPlugin` anima continuamente de un path al siguiente en bucle (`repeat: -1`).
- El tween se pausa al recibir el evento custom `theme-transition-start` (captura de View Transitions) y se reanuda al recibir `theme-transition-end`.

Esto evita que GSAP modifique el DOM durante el snapshot que toma el browser para la transición de tema.

### Parallax: ScrollTrigger

- El hero hace parallax sobre el scroll usando `ScrollTrigger` con `scrub: true`.

---

## HeaderComponent

**Ubicación:** `widgets/header/`

### Animación de borde (DrawSVG)

Al montar el componente, `DrawSVGPlugin` revela el borde SVG de la cabecera desde 0% hasta 100%.

### Aviso de verificación (TextPlugin)

Cuando un usuario sin email verificado intenta navegar a Settings:

1. `TextPlugin` anima el texto del header: `"Settings"` → `"VERIFY!"` → `"Settings"`.
2. El ciclo atrae la atención sin bloquear la navegación.

`shouldShowVerifyBadge` es un computed local que envuelve señales cross-componente para solucionar un quirk de detección de cambios en modo zoneless + OnPush.

---

## OtpDialogComponent

**Ubicación:** `features/auth/ui/otp-dialog/`

Al montar el diálogo, cada celda de entrada OTP recibe una animación de entrada **escalonada** (stagger) con GSAP:

```typescript
gsap.from(cells, {
  opacity: 0,
  y: -10,
  stagger: 0.05,
  duration: 0.3,
  ease: "power2.out",
})
```

---

## ThemeToggleComponent

**Ubicación:** `features/theme-switch/`

### MorphSVG: sol ↔ luna

`MorphSVGPlugin` anima el icono SVG entre la forma de sol (tema claro) y la forma de luna (tema oscuro) al cambiar el tema.

### View Transitions API: ripple

La animación de ripple se gestiona conjuntamente con la View Transitions API. Ver [[frontend/view-transitions|View Transitions API]] para el flujo completo.

---

## DashboardPage

**Ubicación:** `pages/dashboard/`

### Infinite scroll: ScrollTrigger

Un elemento sentinel situado al final de la lista de eventos activa `EventStore.loadMore()` cuando entra en el viewport:

```typescript
ScrollTrigger.create({
  trigger: sentinelEl,
  onEnter: () => eventStore.loadMore(),
})
```

La carga se omite si `EventStore.isLoading()` es `true` o `hasMore()` es `false`.
