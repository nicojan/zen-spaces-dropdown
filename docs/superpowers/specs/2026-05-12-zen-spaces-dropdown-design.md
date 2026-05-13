# Spec — `zen-spaces-dropdown`

**Date:** 2026-05-12
**Owner:** nico@forhuman.ca
**Status:** Approved, ready for implementation plan

---

## 1. Purpose

A Zen Browser Mod that restyles Zen's existing workspace ("Spaces") switcher into a polished, upward-opening dropdown anchored to the workspace button at the bottom of the sidebar. The first workspace sits closest to the trigger button; higher-numbered workspaces stack upward. A user-selectable preference toggles between manual order (drag-to-reorder) and alphabetical sort.

## 2. Scope

### In scope
- Restyle Zen's existing workspace switcher popup so it presents as an upward dropdown.
- Reverse the visual stack order: workspace #1 nearest the trigger, higher numbers further away.
- Render a subtle drag-handle (CSS-only "grip" glyph) on hover for each row.
- Preserve Zen's built-in drag-to-reorder behavior.
- Expose a sort preference with two modes: `manual` (default) and `alphabetical`.
- Expose visual toggles: `show-drag-handles` (default on), `compact` row height (default off).
- Publish to the official Zen Mods marketplace.

### Out of scope (deferred or rejected)
- "Recent / latest used" sort — requires JavaScript; not possible in a CSS-only marketplace mod.
- Adding new DOM elements (e.g., custom dropdown chrome) — would require JavaScript.
- Per-workspace icon customization.
- Keyboard-shortcut changes.

## 3. Architecture

### Constraints
Zen Mods distributed via the official marketplace are **CSS-only**. The mod is delivered as a single `chrome.css` file plus a `preferences.json` schema. User options are surfaced to CSS via Mozilla's pref-aware media queries:
- `@media (-moz-bool-pref: "mod.spaces-dropdown.show-drag-handles") { ... }`
- `@media (-moz-pref("mod.spaces-dropdown.sort", "alphabetical")) { ... }`
- String prefs become CSS custom properties with dots converted to hyphens.

### Approach
We do **not** create new DOM. We restyle Zen's existing workspace switcher elements:
- The trigger button at the bottom of the sidebar (the workspaces selector).
- The popup/panel that opens when the trigger is clicked.

Transformations applied:
1. **Position:** Anchor the panel to the trigger so it grows upward (`transform-origin: bottom`, `bottom: 100%`, override default `top`/`margin-top` positioning).
2. **Order reversal:** Workspace row container uses `flex-direction: column-reverse` so workspace #1 (first in DOM) appears at the visual bottom.
3. **Drag handles:** Each row gets a `::before` grip glyph (CSS-drawn, no image asset) that fades in on row hover when `show-drag-handles` is enabled. The row itself remains the native drag target — Zen's drag-reorder is untouched.
4. **Alphabetical sort:** When `sort = alphabetical`, apply `order` values to each row using attribute selectors like `[aria-label^="A" i], [label^="A" i] { order: 1 }` … `Z { order: 26 }`. Non-letter starts get `order: 27`. Ties are resolved by Zen's DOM order.
5. **Compact mode:** When enabled, reduce row vertical padding from default to tight.

### Risks and verification points
- **DOM/attribute risk:** We assume workspace names render as `aria-label`, `label`, or text content reachable via CSS. We verify this by inspecting the Zen DevTools Inspector against a live profile during dev-environment setup. If neither attribute is exposed, alphabetical sort is dropped from `preferences.json` before publishing, and the spec section 4.2 is removed.
- **Popup positioning override risk:** Zen may compute the popup's screen position with JS positioning logic that overrides simple CSS top/bottom rules. Mitigation: use `!important` overrides on `top`, `bottom`, `margin-top`, `inset` properties and override the popup's `transform`. If that fails, fall back to styling the trigger button itself to look like a dropdown (no popup repositioning) — captured as a fallback path during implementation.
- **CSS specificity battles with Zen's default chrome:** Use the highest-specificity selectors needed to win, plus `!important` where Zen's own rules use `!important`. Audit at end of implementation to ensure overrides are minimal.

## 4. Components

### 4.1 `mod/theme.json` — Manifest
JSON object pointing at raw GitHub URLs for `chrome.css`, `readme.md`, `image.png`, `preferences.json`. Schema follows existing marketplace entries (id UUID v4, name, description, homepage, style, readme, image, author, version, tags, createdAt, updatedAt, preferences).

### 4.2 `mod/chrome.css` — The actual mod
Organized in sections:
1. **Base layout** — popup positioning (upward), shape, blur, elevation.
2. **Row order reversal** — `flex-direction: column-reverse` on the list container.
3. **Row styling** — padding, hover state, selected state, accent color binding.
4. **Drag handle** — `::before` grip glyph, gated by `@media (-moz-bool-pref)`.
5. **Sort modes** — gated `@media (-moz-pref("...", "alphabetical"))` block with `[aria-label^=…]` order rules.
6. **Compact mode** — gated `@media (-moz-bool-pref)` block tightening rows.

### 4.3 `mod/preferences.json`
Three preferences:
```json
[
  {
    "property": "mod.spaces-dropdown.sort",
    "label": "Sort spaces by",
    "type": "dropdown",
    "defaultValue": "manual",
    "options": [
      { "label": "Manual (drag to reorder)", "value": "manual" },
      { "label": "Alphabetical (A → Z)", "value": "alphabetical" }
    ]
  },
  {
    "property": "mod.spaces-dropdown.show-drag-handles",
    "label": "Show drag handles on hover",
    "type": "checkbox",
    "defaultValue": true
  },
  {
    "property": "mod.spaces-dropdown.compact",
    "label": "Compact rows",
    "type": "checkbox",
    "defaultValue": false
  }
]
```

### 4.4 `mod/readme.md` — User-facing
Marketplace install instructions, screenshots, preference descriptions, known limitations (no "recent" sort).

### 4.5 `mod/image.png` — Marketplace preview
1280×800 screenshot of the mod in action. Placeholder commit until dev environment produces a real screenshot.

### 4.6 `scripts/link-dev.sh`, `scripts/unlink-dev.sh`
Bash scripts that:
- Locate the user's Zen profile (parse `profiles.ini` under `~/Library/Application Support/zen/`).
- Ensure `<profile>/chrome/` exists.
- Symlink `mod/chrome.css` → `<profile>/chrome/userChrome.css` (and back out on unlink).
- Print next-step instructions ("restart Zen, enable `toolkit.legacyUserProfileCustomizations.stylesheets`").

### 4.7 `scripts/validate.sh`
Validates `theme.json` and `preferences.json` parse as JSON and that all required keys are present.

## 5. Data flow

```
User toggles pref in Zen Settings → Mods page
        ↓
Zen writes pref to about:config (mod.spaces-dropdown.*)
        ↓
chrome.css media queries re-evaluate
        ↓
DOM repaints with new order/visibility — no reload required
```

No persistent storage owned by the mod. Workspace order itself is Zen's data, persisted by Zen.

## 6. Error handling

CSS has no error states in the traditional sense. Robustness rules:
- Every rule uses defensive selectors that gracefully no-op if the target element doesn't exist.
- No hard dependencies on internal Zen class names that look unstable — prefer semantic selectors (`[zen-workspace-id]`, `panelmultiview`) over private classes.
- All values use `!important` only when overriding Zen's own `!important` rules.

## 7. Testing

- **Manual visual test (primary)**: Live-edit via symlink to `userChrome.css`, inspect with Style Editor.
- **JSON validation**: `scripts/validate.sh` run as a pre-commit local check.
- **Preference matrix**: Walk through all combinations of the three prefs in a checklist within `readme.md` development notes.
- **Cross-version**: Test against current stable Zen and current Twilight (beta) channel.
- No automated unit tests — CSS-only mod, no logic to assert.

## 8. Build / publish

- **Build artifact**: `mod/chrome.css` is the artifact. No transpile or bundle step.
- **Publish to marketplace**: Open issue at `zen-browser/theme-store` titled `[create-theme]: Spaces Dropdown`, pointing at this repo's raw URLs. A bot copies files into `themes/<uuid>/`.
- **License**: CC BY-NC-SA 4.0 (marketplace requirement).
- **Versioning**: SemVer. `1.0.0` for initial release.

## 9. Repo naming and identity

- **Repo name**: `zen-spaces-dropdown`
- **Mod display name**: `Spaces Dropdown`
- **UUID**: Generated once at implementation time, locked in `theme.json`.

## 10. Open questions (none blocking)

None — all major decisions resolved. Workspace DOM attribute confirmation happens during dev-environment setup; if it fails, alphabetical sort is dropped (documented fallback).
