# Product chrome design note

This file is the lock for **product chrome only**: gallery, theme switcher, JSON paste, forms, buttons, inputs, dialogs, navigation, toasts, empty states.

It does **not** apply to submitted résumé themes. Those are unconstrained art aimed at the [`rz-*` class contract](../skeleton/CLASS-CONTRACT.md).

Elm will implement this UI in vanilla CSS. No Tailwind. No CSS-in-JS. Chrome class names must never use the `rz-` prefix.

---

## Source of truth

Port the visual language of [GPUI Component](https://longbridge.github.io/gpui-component/) (native macOS/Windows + [shadcn/ui](https://ui.shadcn.com/)):

| Doc | Why it matters |
| --- | --- |
| [GPUI Component](https://longbridge.github.io/gpui-component/) | Overall system, light/dark, component set |
| [Getting started](https://longbridge.github.io/gpui-component/docs/getting-started) | Sizes, button variants, icons |
| [Theme](https://longbridge.github.io/gpui-component/docs/theme) | Semantic tokens, not ad-hoc hex |
| [Styling and motion](https://github.com/longbridge/gpui-component/blob/main/docs/STYLING-AND-MOTION.md) | Precedence, radius, disabled, reduced motion |

Read those before adding a chrome control. If this note and the upstream docs disagree, upstream wins — then update this note.

---

## Two surfaces

| Surface | Classes | CSS |
| --- | --- | --- |
| Product chrome | never `rz-*` | GPUI tokens below |
| Résumé preview | only `rz-*` | designer `.css`, sandboxed |

The gallery mounts a résumé in an iframe (or equivalent sandbox) so theme CSS cannot style chrome, and chrome CSS cannot leak into the theme.

---

## Semantic tokens

Map GPUI theme fields to CSS custom properties on the chrome root (`:root` / `[data-theme="dark"]`). Do not paint chrome with one-off hex.

**Required tokens**

| Token | Role |
| --- | --- |
| `background` / `foreground` | Page canvas and default text |
| `primary` / `primary-foreground` | Brand actions, key selection |
| `secondary` / `secondary-foreground` | Quiet fills |
| `muted` / `muted-foreground` | Disabled-adjacent text, placeholders, captions |
| `accent` / `accent-foreground` | Hover washes on menus and list rows |
| `destructive` (GPUI `danger`) / `destructive-foreground` | Irreversible actions |
| `success` / `success-foreground` | Positive confirmation |
| `warning` / `warning-foreground` | Caution |
| `info` / `info-foreground` | Neutral system notices |
| `border` | Default hairlines |
| `input` | Input / select borders |
| `ring` | Focus ring |
| `popover` / `popover-foreground` | Menus, dropdowns, floating panels |
| `sidebar` / `sidebar-foreground` / `sidebar-border` / `sidebar-accent` / `sidebar-primary` | App shell |

Include hover / active companions where GPUI defines them (`primary-hover`, `primary-active`, `danger-hover`, …). Light and dark values are both first-class; do not invert in place.

Link color uses `link` / `link-hover` / `link-active` when painting chrome hyperlinks (not résumé links — those belong to the theme).

---

## Sizes

Most chrome controls expose four sizes, matching GPUI:

| Token | GPUI helper | Typical use |
| --- | --- | --- |
| `xs` | `xsmall()` | Compact table actions, icon-only chips |
| `sm` | `small()` | Dense toolbars, secondary filters |
| `md` | `medium()` | Default. Forms, primary actions |
| `lg` | `large()` | Empty-state CTAs, marketing-adjacent chrome |

Default is `md`. Do not invent `xl` or pixel sizes per screen.

---

## Button variants

| Variant | When |
| --- | --- |
| `primary` | The one action we want |
| `danger` | Destroys data or is hard to undo |
| `warning` | Dangerous-adjacent; confirm first |
| `success` | Completes a positive flow (publish, apply theme) |
| `ghost` | Tertiary, toolbars, icon buttons |
| `outline` | Secondary, sits on `background` |

Do not add a seventh variant without updating this note. `info` exists as a **tone** for banners and badges, not as a default button style unless a later GPUI mapping requires it.

---

## Radius

Corners come from theme tokens. Never write a literal radius on chrome.

| Token | Value | Use |
| --- | --- | --- |
| `radius` | `6px` | Controls, inputs, chips, menus |
| `radius-lg` | `8px` | Dialogs, cards, other large surfaces |
| `radius-full` | pill / circle | Avatars, badge dots, switches |

**`radius-full` becomes `0` when `radius` is `0`.** A square theme is square everywhere — including pills. Derive tighter/looser curves from the tokens (`radius / 2`, `radius * 2`), do not hard-code `9999px` or `50%` in chrome.

Exceptions: a caller-requested explicit shape, or plotted/data geometry. Résumé themes may use any radius they want.

---

## Style precedence

Resolve chrome styles in this order (later wins only for fields it sets):

```
instance
  → value states (checked, selected, open, pressed, …)
  → disabled
  → GPUI hover / active / focus
```

- **Disabled is last among semantic layers.** A disabled control does not look hovered or pressed.
- Do not attach hover/active refinements unless the control is enabled.
- Builder/call order does not change precedence; the component does.
- Semantic root styles do not automatically restyle child parts. Style parts explicitly (track vs thumb, trigger vs content).

Focus uses the `ring` token. Keyboard focus must remain visible; do not remove outlines without a replacement ring.

---

## Motion

Motion is optional. Ordinary controls (buttons, inputs, checkboxes, tabs) do **not** require fade, slide, or size animations.

If chrome does animate (dialogs, toasts, theme-preview crossfade):

- Honor `prefers-reduced-motion: reduce` by adopting the end state immediately.
- Keep duration short; prefer animating opacity/transform, not layout.
- A zero duration means “snap to target.”

---

## Light and dark

Ship both. Follow the OS unless the user pins a chrome theme. Résumé themes have their own light/dark story and must not flip chrome, or vice versa.

Use `color-scheme: light` / `dark` on the chrome root so native form controls match.

---

## Icons

Lucide-style only: 24×24 viewBox, 2px stroke, rounded caps/joins. No filled brand icons in chrome except an eventual ResumeZen mark. Pair icon buttons with an accessible name.

---

## Elm mapping (later)

When the Elm app lands:

1. Define tokens as custom properties, not Elm records of hex.
2. Express variants and sizes as chrome classes (`btn`, `btn--primary`, `btn--md`), never `rz-*`.
3. Sandbox the résumé iframe; the only bridge is “which `.css` href to load.”
4. Keep this file honest — if a control ships that violates tokens, sizes, variants, radius, or precedence, that is a bug.
