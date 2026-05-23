# THE VIEW TRANSITIONS API IN 60 SECONDS

The browser gives you one function: `document.startViewTransition(callback)`. When you call it, the browser does this dance:

1. **Snapshot the current DOM** as a bitmap → exposed as the `::view-transition-old(root)` pseudo-element.
2. **Run your callback synchronously**. This is where you mutate the DOM (in our case, change `data-theme`).
3. **Snapshot the new DOM** as a bitmap → exposed as the `::view-transition-new(root)` pseudo-element.
4. **Animate** both pseudo-elements for one frame loop. By default it cross-fades them. You override the animation in CSS to do whatever you want — clip-path, transform, opacity, anything.
5. When animations finish, tear down the pseudos and show the live DOM.

That's it. The API is just "give me two snapshots and let me animate between them with CSS."

# OUR SPECIFIC FLOW

## CLICK → COORDINATES → CSS VARIABLES

In [theme-toggle.ts:50-66](vscode-webview://1e7jd267dul0t7vv49n2e9043md3vbefm20ltt2lt576m6enubhk/src/features/theme-switch/ui/theme-toogle/theme-toggle.ts#L50-L66) we read the button's bounding rect and compute three values:

- `--theme-transition-x` / `--theme-transition-y` — the button's center, in viewport pixels.
- `--theme-transition-end-radius` — the distance from that center to the _farthest_ viewport corner (`Math.hypot(max(x, vw-x), max(y, vh-y))`). This is how big the circle has to grow to fully cover the screen.

We also set `data-theme-transition="to-dark"` or `"to-light"` on `<html>` so the CSS knows which direction to animate.

## SYNCHRONOUS DOM MUTATION INSIDE THE CALLBACK

In [theme-toggle.ts:39-42](vscode-webview://1e7jd267dul0t7vv49n2e9043md3vbefm20ltt2lt576m6enubhk/src/features/theme-switch/ui/theme-toogle/theme-toggle.ts#L39-L42):

```ts
const apply = () => {
  this.themeStore.toggleTheme();
  root.setAttribute('data-theme', nextTheme);
};
```

Two important things here:

- The `setAttribute` is **redundant with the store's `effect()`**, but Angular's `effect()` runs asynchronously on the next microtask. The View Transitions callback needs the DOM mutated _synchronously_ so the new snapshot captures the new theme. So we set the attribute by hand inside the callback; the store's effect later re-applies the same value (no-op).
- We call `startViewTransition(apply)` and the browser handles the snapshot timing for us.

## FALLBACK

```ts
if (!supported || reduced) { apply(); return; }
```

Firefox older than 2025, or anyone with `prefers-reduced-motion: reduce` — they just get an instant theme swap. No animation, no error.

## THE CSS WAVE

In [theme.css](vscode-webview://1e7jd267dul0t7vv49n2e9043md3vbefm20ltt2lt576m6enubhk/src/shared/ui/styles/theme.css), we kill the default cross-fade:

```css
::view-transition-old(root),
::view-transition-new(root) {
  animation: none;
  mix-blend-mode: normal;
}
```

Then per direction, we animate **only one** of the two snapshots:

- **`to-dark`**: the _new_ (dark) snapshot is on top with `z-index: 1`, and its `clip-path` grows from `circle(0 at button)` to `circle(maxRadius at button)` — the dark theme expands outward from the button. Underneath sits the old (light) snapshot, unchanged.
- **`to-light`**: flip it. The _old_ (dark) snapshot is on top, and its `clip-path` shrinks from full to `circle(0)` — the dark theme retracts into the button, revealing the light theme that was sitting full-size underneath all along.

That's why the directions feel different visually but use the exact same keyframes — one expands the new layer, the other shrinks the old layer.

## COORDINATION WITH GSAP (THE LANDING PAGE)

This is the part that doesn't come from the API itself. Because the snapshot is a static bitmap, any in-flight GSAP morph would freeze mid-shape inside it. So:

1. [theme-toggle.ts:67](vscode-webview://1e7jd267dul0t7vv49n2e9043md3vbefm20ltt2lt576m6enubhk/src/features/theme-switch/ui/theme-toogle/theme-toggle.ts#L67) dispatches `theme-transition-start` on `window` _before_ calling `startViewTransition`. This fires synchronously — all listeners run before the next line executes.
2. [landing-page.ts:158-164](vscode-webview://1e7jd267dul0t7vv49n2e9043md3vbefm20ltt2lt576m6enubhk/src/pages/landing/landing-page.ts#L158-L164) listens, kills the morph timeline, and `gsap.set()`s the path back to the current logo's clean `d` attribute.
3. _Then_ `startViewTransition` runs, snapshots a clean logo, plays the wave.
4. On `transition.finished` ([theme-toggle.ts:73-76](vscode-webview://1e7jd267dul0t7vv49n2e9043md3vbefm20ltt2lt576m6enubhk/src/features/theme-switch/ui/theme-toogle/theme-toggle.ts#L73-L76)) we dispatch `theme-transition-end`, the landing calls `runNextMorph()`, the loop resumes from where it visually was.

The events go through `window` instead of a service so any future component (auth animations, settings transitions) can opt in with two `addEventListener` lines — no DI coupling to the theme feature.

## PUTTING THE TIMELINE TOGETHER

```
click button
  ├─ icon GSAP morph starts (1.2s, runs through everything below — it's on the button itself which is captured with the rest)
  ├─ set CSS vars + data-theme-transition on <html>
  ├─ dispatch 'theme-transition-start'  ──► landing snaps SVG to clean logo
  ├─ startViewTransition(apply):
  │     ├─ browser: snapshot old DOM (clean logo, old theme)
  │     ├─ apply(): toggleTheme() + setAttribute('data-theme', new)
  │     └─ browser: snapshot new DOM (clean logo, new theme)
  ├─ CSS wave runs 1.6s on the new (or old) snapshot's clip-path
  └─ transition.finished:
        ├─ remove data-theme-transition attr
        └─ dispatch 'theme-transition-end'  ──► landing resumes morph loop
```

The reason this feels like more than the sum of its parts is that the only state shared between toggle and landing is two custom events on `window`. The theme store doesn't know about transitions, the landing page doesn't know about themes, and the toggle doesn't know about the SVG morph. Each component owns its own animation lifecycle.