---
title: Formularios Signal
description: Formularios reactivos basados en señales con @angular/forms/signals en Parallax Sports: AuthForm, Settings forms, OTP dialog.
tags:
  - frontend
  - formularios
  - signals
---

# Formularios Signal

Parallax Sports usa la API experimental `@angular/forms/signals` para formularios completamente reactivos, sin llamadas imperativas a `form.submit()` ni subscripciones manuales.

## API base

- `FormRoot<T>`: raíz del formulario; contiene el estado de validez global
- `FormField<T>`: campo individual; acepta validadores síncronos y asíncronos
- La validación se ejecuta **reactivamente** al cambiar el valor del campo
- Los errores son señales: se pueden leer en plantilla con `field.errors()`

---

## AuthForm

**Ubicación:** `features/auth/store/auth.store.ts`

El formulario vive como propiedad `authForm` dentro de `AuthStore`. Los campos activos varían según el `mode` (login / register).

### Modo login

| Campo      | Validadores                |
| ---------- | -------------------------- |
| `email`    | Patrón de email (síncrono) |
| `password` | Requerido                  |

### Modo register

| Campo             | Validadores                                               |
| ----------------- | --------------------------------------------------------- |
| `email`           | Patrón (síncrono) + disponibilidad (asíncrono, debounced) |
| `password`        | Requerido, longitud mínima                                |
| `confirmPassword` | Cross-field: debe coincidir con `password`                |
| `displayName`     | Requerido, longitud mínima                                |

**Validador asíncrono de email:** llama a `POST /api/users/email` (endpoint público) para comprobar si el email ya está registrado. Se aplica debounce para evitar peticiones en cada pulsación.

**Esquema de validación:** definido en `entities/auth/model/auth.schema.ts`.

---

## Settings forms: Account

**Ubicación:** `features/settings/ui/account/forms/`

| Fichero                | Campos                                              | Validadores                                           |
| ---------------------- | --------------------------------------------------- | ----------------------------------------------------- |
| `display-name-form.ts` | `displayName`                                       | Requerido, longitud mínima                            |
| `email-form.ts`        | `newEmail`, `currentPassword`                       | Email válido; `currentPassword` para re-autenticación |
| `password-form.ts`     | `currentPassword`, `newPassword`, `confirmPassword` | Coincidencia cross-field; longitud mínima             |

---

## Settings forms: Preferences

**Ubicación:** `features/settings/ui/preferences/forms/`

| Fichero                | Campo         | UI                                                               |
| ---------------------- | ------------- | ---------------------------------------------------------------- |
| `timezone-form.ts`     | `timezone`    | `stateful-combobox-autocomplete-select` con datos de `@vvo/tzdb` |
| `date-format-form.ts`  | `dateFormat`  | `<select>`                                                       |
| `default-view-form.ts` | `defaultView` | Radio buttons (cards / table)                                    |

---

## OTP Dialog

**Ubicación:** `features/auth/ui/otp-dialog/`

El diálogo de verificación de email usa `ReactiveFormsModule` (no signal forms) ya que delega en el componente externo `ng-otp-input`.

| Aspecto          | Detalle                                                        |
| ---------------- | -------------------------------------------------------------- |
| Entrada          | 6 dígitos mediante `ng-otp-input`                              |
| Estados internos | `idle` → `verifying` → `success` \| `error`                    |
| Outputs          | `verified` (EventEmitter), `closed` (EventEmitter)             |
| Animación        | GSAP: entrada escalonada de cada celda al montar el componente |

El código OTP se envía a `POST /api/auth/verify-email` con el token de 6 dígitos. Ver [[frontend/animaciones|Animaciones GSAP]] para el detalle de la animación de entrada.

## Fuentes
