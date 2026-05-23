---
title: "View Transitions API: Ripple de tema"
description: Implementación del efecto ripple de cambio de tema mediante la View Transitions API y su integración con GSAP en Parallax Sports.
tags:
  - frontend
  - animaciones
  - view-transitions
  - gsap
---

# View Transitions API: Ripple de tema

## Fuentes

- [CSS Wrapped 2025: View Transition Groups](https://chrome.dev/css-wrapped-2025/#nested-view-transition-groups)
- [Theme switch con View Transitions (StackBlitz)](https://stackblitz.com/edit/stackblitz-starters-cklnkm?file=src%2Fmain.ts)
- [awww – inspiración del theme switch en Hyprland](https://codeberg.org/LGFae/awww)
- [caniuse.com](https://caniuse.com)

---

El cambio de tema (claro <> oscuro) se anima con un efecto de onda expansiva (ripple) que parte del punto exacto donde el usuario hace clic. Se implementa con la View Transitions API del browser, sin librerías adicionales.

## Las 3 fases

### 1. Captura

Cuando el usuario hace clic en `ThemeToggleComponent`:

1. Se obtiene la posición del clic mediante `getBoundingClientRect()` del botón.
2. Se calculan las coordenadas `x`, `y` relativas al viewport.
3. Se calcula el radio final necesario para cubrir toda la pantalla:

$$r_{end} = \sqrt{\max(x,\, W-x)^2 + \max(y,\, H-y)^2}$$

4. Se escriben las custom properties en `:root`:

```css
--theme-transition-x: <x>px;
--theme-transition-y: <y>px;
--theme-transition-end-radius: <r>px;
```

### 2. Transición

Se llama a `document.startViewTransition(callback)`. Dentro del callback (síncrono):

1. Se despacha el evento custom `theme-transition-start` → `LandingPage` pausa el tween de MorphSVG (ver [[frontend/animaciones|Animaciones GSAP]]).
2. `ThemeStore.toggle()` cambia el tema → se actualiza `data-theme` en `<html>`.
3. El browser captura el screenshot "nuevo" de forma interna.

### 3. Animación CSS

La pseudoclase `::view-transition-new(root)` recibe la animación del círculo expansivo:

```css
::view-transition-new(root) {
  clip-path: circle(0% at var(--theme-transition-x) var(--theme-transition-y));
  animation: theme-ripple 400ms ease-in forwards;
}

@keyframes theme-ripple {
  to {
    clip-path: circle(
      var(--theme-transition-end-radius) at var(--theme-transition-x) var(--theme-transition-y)
    );
  }
}
```

El resultado: el nuevo tema "emerge" como un círculo que se expande desde el punto de clic hasta cubrir toda la pantalla.

---

## Integración con GSAP

La View Transitions API toma snapshots del DOM. Si GSAP está animando SVG en ese instante, el snapshot puede quedar corrupto.

| Evento                   | Quién lo despacha                                       | Quién lo escucha                            |
| ------------------------ | ------------------------------------------------------- | ------------------------------------------- |
| `theme-transition-start` | `ThemeToggleComponent` (antes de `startViewTransition`) | `LandingPage`: pausa el tween de MorphSVG   |
| `theme-transition-end`   | `ThemeToggleComponent` (en `.finished.then()`)          | `LandingPage`: reanuda el tween de MorphSVG |

---

```typescript
if ("startViewTransition" in document) {
  document.startViewTransition(callback)
} else {
  callback()
}
```
