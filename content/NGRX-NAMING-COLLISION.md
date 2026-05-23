# ngrx/signals: state/method name collision crashes CD

## TL;DR

In `signalStore`, if a `withState` property and a `withMethods` method share a
name, **the method wins** on the store instance. The state signal is still
internally accessible but `store.X` returns the method. If a template then
calls that name as a function (`@if (X())`) expecting to read the signal, it
actually invokes the method — which usually performs a `patchState`. Writing
a signal during template render throws **NG0600**, which aborts the current
change-detection tick and can suppress unrelated UI further down the tree.

## What we hit

On the dashboard route, clicking the header's **Verify** button did not
display the OTP dialog. It would only appear after the user navigated to
another route or toggled the theme. On the settings route the same button
worked correctly.

The console showed:

```
ERROR RuntimeError: NG0600: Writing to signals is not allowed while Angular renders the template (eg. interpolations)
    at patchState (ngrx-signals.mjs:...)
    at _FilterDrawerComponent.open (filter-drawer.store.ts:15)
    at FilterDrawerComponent_Template (filter-drawer.html:1)
    at executeTemplate (...)
    at refreshView (...)
    at tick (...)
    at requestAnimationFrame
```

## Root cause

[`FilterDrawerStore`](src/features/dashboard/store/filter-drawer.store.ts) was
declared like this:

```ts
const initialState: FilterDrawerState = { open: false };

export const FilterDrawerStore = signalStore(
  { providedIn: 'root' },
  withState(initialState),         // exposes store.open as Signal<boolean>
  withMethods((store) => ({
    open(): void {                  // overrides store.open with a function
      patchState(store, { open: true });
    },
    close(): void { ... },
    toggle(): void { ... },
  })),
);
```

In [`FilterDrawerComponent`](src/features/dashboard/ui/filter-drawer/filter-drawer.ts):

```ts
protected readonly open = this.drawerStore.open;  // <-- actually the method
```

And the template, [`filter-drawer.html`](src/features/dashboard/ui/filter-drawer/filter-drawer.html):

```html
@if (open()) { ... }   <!-- invokes the method during render -->
```

So every CD pass on the dashboard:

1. The drawer template runs.
2. `open()` calls `patchState({ open: true })`.
3. A signal is written during template evaluation → NG0600 is thrown.
4. The current tick aborts before reaching siblings further down the tree.

Because `<app-verify-email-dialog>` sits at the app-root level *after*
`<router-outlet />`, and is OnPush, it was scheduled for check on the same
tick the click triggered — exactly the tick the drawer crashed. Its
`@if (isOpen())` never re-evaluated, so the dialog stayed unmounted.

Navigating or theme-toggling kicked off a *new* CD tick. The drawer kept
throwing on every tick, but the dialog had already been marked dirty and
managed to render on a later pass (Angular's CD is best-effort and tries to
recover after errors).

## Why it didn't happen on `/settings`

The settings page doesn't include `FilterDrawerComponent`. No crashing
template, no aborted tick, no symptom.

## Fix

Rename the state property so it no longer collides with the method. We chose
`isOpen` to match the convention already used by `VerifyEmailService` and
`VerifyEmailDialogComponent`:

```ts
interface FilterDrawerState { isOpen: boolean; }

const initialState: FilterDrawerState = { isOpen: false };

export const FilterDrawerStore = signalStore(
  { providedIn: 'root' },
  withState(initialState),
  withMethods((store) => ({
    open():   void { patchState(store, { isOpen: true  }); },
    close():  void { patchState(store, { isOpen: false }); },
    toggle(): void { patchState(store, { isOpen: !store.isOpen() }); },
  })),
);
```

Consumer side:

```ts
// filter-drawer.ts
protected readonly isOpen = this.drawerStore.isOpen;
```

```html
<!-- filter-drawer.html -->
@if (isOpen()) { ... }
```

`dashboard-toolbar.ts` still calls `this.drawerStore.open()` (the method) and
needed no change.

## Lessons / convention

- In `signalStore`, **never give a state property and a method the same
  name.** ngrx/signals does not warn about it, and the method silently
  shadows the signal. Common offenders: `open` / `close` / `toggle` /
  `loading` / `error`.
- A safe naming convention for boolean state: `isOpen`, `isLoading`,
  `hasError`. Pair with imperative methods: `open()`, `load()`, `setError()`.
- A signal write inside a template (interpolation, `@if`, `@for` expressions)
  is **always** a bug, even when it doesn't visibly throw. NG0600 in
  production is silenced/swallowed in some configurations, but the tick is
  still aborted and you'll see "stale UI" symptoms elsewhere on the page.
- When a button "does nothing" but the same UI works after navigation or
  theme switch, suspect an aborted CD tick. **Open the console first** —
  the stack trace usually points at the real culprit, which is rarely the
  component that visibly failed to update.

## Red herring during diagnosis

The header component carries a workaround comment about zoneless + OnPush
"missing the first cross-component store-signal update," and uses a local
`computed()` wrapper around store signals as a defence. That pattern was
applied speculatively to `VerifyEmailComponent` and
`VerifyEmailDialogComponent` while diagnosing this bug and reverted once the
NG0600 was found — the wrapper is unnecessary here. Worth re-evaluating
whether the original header workaround is still needed, or whether *its*
original symptom was also a hidden NG0600 from somewhere.
