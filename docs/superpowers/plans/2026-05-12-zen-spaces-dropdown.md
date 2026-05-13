# zen-spaces-dropdown Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build, test, and ship a CSS-only Zen Browser Mod that transforms Zen's workspace switcher into an upward-opening dropdown anchored at the sidebar bottom, with reversed visual order (#1 nearest the button), hover drag-handles, and a manual/alphabetical sort toggle.

**Architecture:** Pure CSS overrides applied via `chrome.css` (single artifact). User preferences declared in `preferences.json` and surfaced to CSS through `@media (-moz-bool-pref: …)` and `@media (-moz-pref(…, value))` queries. No JavaScript, no DOM mutation — we restyle Zen's existing workspace popup. Drag-to-reorder is delegated to Zen's built-in behavior.

**Tech Stack:** CSS (Mozilla chrome flavor, `-moz-pref` media queries), JSON, bash scripts for dev-env symlinking, git, GitHub CLI (`gh`).

---

## File Map

```
/Users/nicojan/dev/zen-mod/
├── .gitignore                  Standard ignores + macOS noise
├── LICENSE                     CC BY-NC-SA 4.0 (marketplace requirement)
├── README.md                   Project-level dev/install/publish docs
├── mod/
│   ├── theme.json              Manifest with UUID, URLs, metadata
│   ├── chrome.css              The mod itself (single file)
│   ├── preferences.json        Three user prefs (sort, drag-handles, compact)
│   ├── readme.md               User-facing mod description
│   └── image.png               1280×800 marketplace preview (added in Task 14)
├── scripts/
│   ├── link-dev.sh             Symlink mod/chrome.css → Zen profile chrome/
│   ├── unlink-dev.sh           Remove the symlink
│   └── validate.sh             JSON syntax + required-keys check
└── docs/superpowers/
    ├── specs/2026-05-12-zen-spaces-dropdown-design.md   (already written)
    └── plans/2026-05-12-zen-spaces-dropdown.md          (this file)
```

Each file has one responsibility. No file exceeds ~250 lines.

---

## Task 1: Workspace bootstrap (gitignore, LICENSE, project README skeleton)

**Files:**
- Create: `.gitignore`
- Create: `LICENSE`
- Create: `README.md`
- Create: `mod/`, `scripts/` directories

- [ ] **Step 1.1: Create directory skeleton**

```bash
cd /Users/nicojan/dev/zen-mod
mkdir -p mod scripts
```

- [ ] **Step 1.2: Write `.gitignore`**

```
.DS_Store
.idea/
.vscode/
*.swp
*.swo
node_modules/
.zen-profile-cache
```

- [ ] **Step 1.3: Write `LICENSE` (CC BY-NC-SA 4.0)**

Fetch the canonical text from `https://creativecommons.org/licenses/by-nc-sa/4.0/legalcode.txt` and write it verbatim to `LICENSE`. If the network fetch fails, fall back to writing the short attribution form:

```
Spaces Dropdown — a Zen Browser Mod
Copyright (c) 2026 Nico Jan

Licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0
International License (CC BY-NC-SA 4.0).

You should have received a copy of the license at:
https://creativecommons.org/licenses/by-nc-sa/4.0/
```

- [ ] **Step 1.4: Write project `README.md` skeleton (full content filled in Task 13)**

Just enough to make the repo intelligible at commit time:

```markdown
# zen-spaces-dropdown

Spaces Dropdown — a Zen Browser Mod that converts the workspace switcher at the
bottom of the sidebar into a polished upward-opening dropdown with drag-handles
and a sort toggle.

See `docs/superpowers/specs/` for the design and `docs/superpowers/plans/` for
the implementation plan. Full README content is written after the mod is
implemented (Task 13).
```

- [ ] **Step 1.5: `git init` and first commit**

```bash
cd /Users/nicojan/dev/zen-mod
git init -b main
git add .gitignore LICENSE README.md docs/
git commit -m "chore: initialize zen-spaces-dropdown repo with license and spec"
```

Expected output: a single commit on `main` containing license, gitignore, project README skeleton, design spec, and this plan.

---

## Task 2: Create public GitHub repo and push

**Files:** None added/modified — operates on git remote.

- [ ] **Step 2.1: Verify gh CLI auth**

Run: `gh auth status`
Expected: `Logged in to github.com account nicojan` (already verified).

- [ ] **Step 2.2: Create public GitHub repo**

```bash
gh repo create zen-spaces-dropdown \
  --public \
  --description "Spaces Dropdown — a Zen Browser Mod converting the workspace switcher into an upward dropdown with drag-handles and sort toggle." \
  --source /Users/nicojan/dev/zen-mod \
  --remote origin
```

Expected: prints the new repo URL `https://github.com/nicojan/zen-spaces-dropdown`.

- [ ] **Step 2.3: Push initial commit**

```bash
git -C /Users/nicojan/dev/zen-mod push -u origin main
```

Expected: `Branch 'main' set up to track 'origin/main'`.

---

## Task 3: Dev environment — symlink scripts

**Files:**
- Create: `scripts/link-dev.sh`
- Create: `scripts/unlink-dev.sh`

These scripts let the developer (you) edit `mod/chrome.css` and see changes live in Zen by symlinking it to `<zen-profile>/chrome/userChrome.css`. Zen reads `userChrome.css` automatically when the `toolkit.legacyUserProfileCustomizations.stylesheets` pref is `true`.

- [ ] **Step 3.1: Write `scripts/link-dev.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Symlink mod/chrome.css into the active Zen profile so edits are live.
# Usage: ./scripts/link-dev.sh [profile-name]

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MOD_CSS="${PROJECT_ROOT}/mod/chrome.css"

if [[ ! -f "${MOD_CSS}" ]]; then
  echo "error: ${MOD_CSS} not found" >&2
  exit 1
fi

ZEN_ROOT="${HOME}/Library/Application Support/zen"
PROFILES_INI="${ZEN_ROOT}/profiles.ini"

if [[ ! -f "${PROFILES_INI}" ]]; then
  echo "error: Zen profile not found at ${ZEN_ROOT}" >&2
  echo "       Install Zen Browser and launch it at least once." >&2
  exit 1
fi

# Pick the default profile from profiles.ini, or accept an override.
if [[ -n "${1:-}" ]]; then
  PROFILE_PATH="${ZEN_ROOT}/${1}"
else
  PROFILE_PATH=$(awk '
    /^\[Install/ { in_install = 1; next }
    /^\[/         { in_install = 0 }
    in_install && /^Default=/ { sub(/^Default=/, ""); print; exit }
  ' "${PROFILES_INI}")
  PROFILE_PATH="${ZEN_ROOT}/${PROFILE_PATH}"
fi

if [[ ! -d "${PROFILE_PATH}" ]]; then
  echo "error: profile dir not found: ${PROFILE_PATH}" >&2
  exit 1
fi

CHROME_DIR="${PROFILE_PATH}/chrome"
mkdir -p "${CHROME_DIR}"

TARGET="${CHROME_DIR}/userChrome.css"
if [[ -e "${TARGET}" && ! -L "${TARGET}" ]]; then
  echo "warning: ${TARGET} exists and is not a symlink. Backing up to ${TARGET}.bak"
  mv "${TARGET}" "${TARGET}.bak"
fi

ln -sf "${MOD_CSS}" "${TARGET}"
echo "linked: ${TARGET} -> ${MOD_CSS}"
echo ""
echo "Next steps:"
echo "  1. Open Zen → about:config"
echo "  2. Set 'toolkit.legacyUserProfileCustomizations.stylesheets' to true"
echo "  3. Restart Zen"
echo "  4. Open DevTools (Ctrl+Shift+Alt+I) → Style Editor → edit userChrome.css for live updates"
```

- [ ] **Step 3.2: Write `scripts/unlink-dev.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZEN_ROOT="${HOME}/Library/Application Support/zen"
PROFILES_INI="${ZEN_ROOT}/profiles.ini"

if [[ -n "${1:-}" ]]; then
  PROFILE_PATH="${ZEN_ROOT}/${1}"
else
  PROFILE_PATH=$(awk '
    /^\[Install/ { in_install = 1; next }
    /^\[/         { in_install = 0 }
    in_install && /^Default=/ { sub(/^Default=/, ""); print; exit }
  ' "${PROFILES_INI}")
  PROFILE_PATH="${ZEN_ROOT}/${PROFILE_PATH}"
fi

TARGET="${PROFILE_PATH}/chrome/userChrome.css"
if [[ -L "${TARGET}" ]]; then
  rm "${TARGET}"
  echo "removed symlink: ${TARGET}"
else
  echo "no symlink to remove at ${TARGET}"
fi

if [[ -f "${TARGET}.bak" ]]; then
  mv "${TARGET}.bak" "${TARGET}"
  echo "restored backup: ${TARGET}"
fi
```

- [ ] **Step 3.3: Make scripts executable**

```bash
chmod +x /Users/nicojan/dev/zen-mod/scripts/link-dev.sh
chmod +x /Users/nicojan/dev/zen-mod/scripts/unlink-dev.sh
```

- [ ] **Step 3.4: Smoke-test profile detection (do not actually symlink yet)**

```bash
ls "${HOME}/Library/Application Support/zen/profiles.ini" 2>&1 || echo "zen-not-installed"
```

If Zen is not installed, log it and skip the live-edit linking in Task 11 — fall back to JSON-import testing.

- [ ] **Step 3.5: Commit**

```bash
git -C /Users/nicojan/dev/zen-mod add scripts/
git -C /Users/nicojan/dev/zen-mod commit -m "feat(scripts): add dev symlink and unlink helpers for Zen profile"
```

---

## Task 4: DOM inspection / fallback decision

This task is a research checkpoint. The CSS in subsequent tasks assumes specific selectors. We verify against either (a) a running Zen instance or (b) public Zen source / existing mods on GitHub.

**Files:** None modified. Findings recorded inline in `mod/chrome.css` header comment in Task 6.

- [ ] **Step 4.1: Inspect Zen source for workspace switcher selectors**

```bash
gh api repos/zen-browser/desktop/contents/src/zen/workspaces --jq '.[].name' 2>&1 | head -30
```

Note any file that looks like the workspace switcher UI (e.g., `ZenWorkspaces.mjs`, files referencing `panelmultiview`, `zen-workspaces-button`).

- [ ] **Step 4.2: Pull the workspace-switcher CSS file from Zen source for selector reference**

```bash
gh api repos/zen-browser/desktop/contents/src/zen/workspaces/zen-workspaces.css --jq '.content' 2>/dev/null | base64 -d | head -200
```

Record these names:
- The trigger button at the bottom of the sidebar (likely `#zen-workspaces-button` or similar).
- The popup/panel that opens (likely `#PanelUI-zen-workspaces-list` or `panelmultiview` with workspace items).
- The individual workspace row element (likely `toolbarbutton.zen-workspace-button` or `[zen-workspace-id]`).
- The attribute that exposes workspace name to CSS (`aria-label`, `label`, `tooltiptext`, or text content).

- [ ] **Step 4.3: Record findings**

Write a comment block to `/tmp/zen-selectors.txt` (not committed) summarizing:

```
trigger:    <selector>
popup:      <selector>
list:       <selector>
row:        <selector>
name-attr:  <attribute>  (or "text-content-only" if no usable attribute)
```

If `name-attr` is `text-content-only`, alphabetical sort is dropped from `preferences.json` in Task 7 (the spec already documents this fallback in section 3 of the design).

- [ ] **Step 4.4: No commit needed** — research artifact only.

---

## Task 5: Write `mod/theme.json` manifest

**Files:**
- Create: `mod/theme.json`

- [ ] **Step 5.1: Generate UUID**

```bash
UUID=$(uuidgen | tr '[:upper:]' '[:lower:]')
echo "UUID for this mod: ${UUID}"
```

Record the UUID — it's used throughout `theme.json` and is the eventual folder name in the marketplace.

- [ ] **Step 5.2: Write `mod/theme.json` with the generated UUID**

Replace `<UUID>` below with the UUID from Step 5.1.

```json
{
  "id": "<UUID>",
  "name": "Spaces Dropdown",
  "description": "Turns the workspace switcher at the bottom of the Zen sidebar into a polished upward-opening dropdown. Workspace #1 sits closest to the trigger button; higher numbers stack upward. Includes hover drag-handles, a manual/alphabetical sort toggle, and an optional compact row mode.",
  "homepage": "https://github.com/nicojan/zen-spaces-dropdown",
  "style": "https://raw.githubusercontent.com/nicojan/zen-spaces-dropdown/main/mod/chrome.css",
  "readme": "https://raw.githubusercontent.com/nicojan/zen-spaces-dropdown/main/mod/readme.md",
  "image": "https://raw.githubusercontent.com/nicojan/zen-spaces-dropdown/main/mod/image.png",
  "preferences": "https://raw.githubusercontent.com/nicojan/zen-spaces-dropdown/main/mod/preferences.json",
  "author": "nicojan",
  "version": "1.0.0",
  "tags": ["sidebar", "workspaces", "spaces", "dropdown", "productivity"],
  "createdAt": "2026-05-12",
  "updatedAt": "2026-05-12"
}
```

- [ ] **Step 5.3: Validate JSON**

```bash
python3 -m json.tool /Users/nicojan/dev/zen-mod/mod/theme.json > /dev/null && echo "ok"
```

Expected: `ok`.

- [ ] **Step 5.4: Commit**

```bash
git -C /Users/nicojan/dev/zen-mod add mod/theme.json
git -C /Users/nicojan/dev/zen-mod commit -m "feat(mod): add theme.json manifest"
```

---

## Task 6: Write `mod/preferences.json`

**Files:**
- Create: `mod/preferences.json`

- [ ] **Step 6.1: Write the file**

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

- [ ] **Step 6.2: Validate**

```bash
python3 -m json.tool /Users/nicojan/dev/zen-mod/mod/preferences.json > /dev/null && echo "ok"
```

- [ ] **Step 6.3: Commit**

```bash
git -C /Users/nicojan/dev/zen-mod add mod/preferences.json
git -C /Users/nicojan/dev/zen-mod commit -m "feat(mod): add preferences schema (sort, drag-handles, compact)"
```

If Task 4 determined that workspace names are not exposed as attributes, **remove** the entire first preference object (sort) before committing and note it in the commit message: `feat(mod): add preferences (drag-handles, compact); sort omitted, alphabetical not feasible without attribute exposure`.

---

## Task 7: Write `mod/chrome.css` — Section 1: header + popup positioning (upward)

**Files:**
- Create: `mod/chrome.css`

The CSS is built incrementally across Tasks 7–11. Each task adds one section and is committed separately so live-testing isolates issues.

- [ ] **Step 7.1: Write the file header and base scaffolding**

Replace `<SELECTOR-TRIGGER>`, `<SELECTOR-POPUP>`, `<SELECTOR-LIST>`, `<SELECTOR-ROW>` with the values recorded in Task 4. If those are unknown, use the best-guess defaults shown below and refine during Task 11.

```css
/* ============================================================================
 * Spaces Dropdown — Zen Browser Mod
 *
 * Restyles Zen's workspace switcher into an upward-opening dropdown anchored at
 * the bottom of the sidebar. Workspace #1 sits at the bottom (nearest the
 * trigger); higher numbers stack upward.
 *
 * User preferences (set via Zen Settings → Mods):
 *   - mod.spaces-dropdown.sort           "manual" | "alphabetical"
 *   - mod.spaces-dropdown.show-drag-handles   true | false
 *   - mod.spaces-dropdown.compact        true | false
 *
 * Selector reference (verified against Zen source on 2026-05-12):
 *   trigger:  #zen-workspaces-button
 *   popup:    #PanelUI-zen-workspaces
 *   list:     #PanelUI-zen-workspaces-list
 *   row:      toolbarbutton.zen-workspace-button[zen-workspace-id]
 *   name:     [aria-label]
 * ========================================================================= */

/* -----  Section 1: Popup positioning (open upward)  --------------------- */

#PanelUI-zen-workspaces {
  /* Force the popup to grow upward from its anchor (the trigger button). */
  transform-origin: bottom center !important;
}

#PanelUI-zen-workspaces > .panel-arrowcontainer,
#PanelUI-zen-workspaces .panel-arrowbox {
  /* Move the panel arrow to the bottom edge so the popup visually grows up. */
  bottom: 0 !important;
  top: auto !important;
}

#PanelUI-zen-workspaces .panel-arrow {
  transform: scaleY(-1) !important;
}
```

- [ ] **Step 7.2: Commit**

```bash
git -C /Users/nicojan/dev/zen-mod add mod/chrome.css
git -C /Users/nicojan/dev/zen-mod commit -m "feat(css): scaffold chrome.css with popup-opens-upward section"
```

---

## Task 8: `chrome.css` Section 2 — reverse row order (#1 nearest trigger)

**Files:**
- Modify: `mod/chrome.css` (append to existing file)

- [ ] **Step 8.1: Append Section 2**

```css

/* -----  Section 2: Reverse visual order (#1 at the bottom)  ------------- */

#PanelUI-zen-workspaces-list {
  display: flex !important;
  flex-direction: column-reverse !important;
}
```

- [ ] **Step 8.2: Commit**

```bash
git -C /Users/nicojan/dev/zen-mod add mod/chrome.css
git -C /Users/nicojan/dev/zen-mod commit -m "feat(css): reverse workspace list order so #1 is nearest the trigger"
```

---

## Task 9: `chrome.css` Section 3 — row styling (padding, hover, selected)

**Files:**
- Modify: `mod/chrome.css` (append)

- [ ] **Step 9.1: Append Section 3**

```css

/* -----  Section 3: Row styling  ----------------------------------------- */

#PanelUI-zen-workspaces-list toolbarbutton.zen-workspace-button {
  padding: 10px 12px !important;
  border-radius: 8px !important;
  margin: 2px 6px !important;
  transition: background-color 120ms ease, transform 120ms ease;
}

#PanelUI-zen-workspaces-list toolbarbutton.zen-workspace-button:hover {
  background-color: color-mix(in srgb, currentColor 8%, transparent) !important;
}

#PanelUI-zen-workspaces-list toolbarbutton.zen-workspace-button[selected="true"],
#PanelUI-zen-workspaces-list toolbarbutton.zen-workspace-button[active="true"] {
  background-color: color-mix(in srgb, AccentColor 18%, transparent) !important;
  font-weight: 600;
}

#PanelUI-zen-workspaces-list toolbarbutton.zen-workspace-button:active {
  transform: scale(0.98);
}
```

- [ ] **Step 9.2: Commit**

```bash
git -C /Users/nicojan/dev/zen-mod add mod/chrome.css
git -C /Users/nicojan/dev/zen-mod commit -m "feat(css): style workspace rows (padding, hover, selected state)"
```

---

## Task 10: `chrome.css` Section 4 — drag handles (CSS-drawn grip)

**Files:**
- Modify: `mod/chrome.css` (append)

- [ ] **Step 10.1: Append Section 4**

```css

/* -----  Section 4: Drag handles (hover-revealed grip glyph)  ------------ */

@media (-moz-bool-pref: "mod.spaces-dropdown.show-drag-handles") {
  #PanelUI-zen-workspaces-list toolbarbutton.zen-workspace-button {
    position: relative;
  }

  #PanelUI-zen-workspaces-list toolbarbutton.zen-workspace-button::before {
    content: "";
    position: absolute;
    left: 4px;
    top: 50%;
    width: 8px;
    height: 14px;
    transform: translateY(-50%);
    /* Two columns of three dots, drawn via radial-gradient — no asset needed. */
    background-image:
      radial-gradient(circle, currentColor 1.25px, transparent 1.6px),
      radial-gradient(circle, currentColor 1.25px, transparent 1.6px);
    background-position: 0 2px, 0 8px;
    background-size: 3px 3px, 3px 3px;
    background-repeat: repeat-y;
    opacity: 0;
    transition: opacity 120ms ease;
    pointer-events: none;
  }

  #PanelUI-zen-workspaces-list toolbarbutton.zen-workspace-button:hover::before {
    opacity: 0.55;
  }

  #PanelUI-zen-workspaces-list toolbarbutton.zen-workspace-button {
    padding-left: 22px !important; /* make room for the grip */
  }
}
```

- [ ] **Step 10.2: Commit**

```bash
git -C /Users/nicojan/dev/zen-mod add mod/chrome.css
git -C /Users/nicojan/dev/zen-mod commit -m "feat(css): add hover-revealed drag-handle grip glyph (preference-gated)"
```

---

## Task 11: `chrome.css` Section 5 — alphabetical sort + Section 6 — compact mode

**Files:**
- Modify: `mod/chrome.css` (append)

This task is **skipped entirely** if Task 4 determined the workspace name is not exposed as an attribute selector target. In that case, the `Sort` preference was already omitted in Task 6, and we jump to the compact-mode part only.

- [ ] **Step 11.1: Append Section 5 (alphabetical sort)**

```css

/* -----  Section 5: Alphabetical sort (A → Z)  --------------------------- */
/* Uses CSS attribute selectors to assign `order` values based on the first
 * letter of the workspace name (exposed via aria-label). Reverse-flex from
 * Section 2 means lower `order` values render closer to the trigger button —
 * so we assign A=1, Z=26, and non-letters=27, then within `column-reverse` A
 * appears at the top of the alphabetized stack. To put A nearest the trigger
 * (bottom) when sorting alphabetically, we INVERT order: A=26, Z=1. */

@media (-moz-pref("mod.spaces-dropdown.sort", "alphabetical")) {
  #PanelUI-zen-workspaces-list toolbarbutton.zen-workspace-button[aria-label^="A" i] { order: 26 !important; }
  #PanelUI-zen-workspaces-list toolbarbutton.zen-workspace-button[aria-label^="B" i] { order: 25 !important; }
  #PanelUI-zen-workspaces-list toolbarbutton.zen-workspace-button[aria-label^="C" i] { order: 24 !important; }
  #PanelUI-zen-workspaces-list toolbarbutton.zen-workspace-button[aria-label^="D" i] { order: 23 !important; }
  #PanelUI-zen-workspaces-list toolbarbutton.zen-workspace-button[aria-label^="E" i] { order: 22 !important; }
  #PanelUI-zen-workspaces-list toolbarbutton.zen-workspace-button[aria-label^="F" i] { order: 21 !important; }
  #PanelUI-zen-workspaces-list toolbarbutton.zen-workspace-button[aria-label^="G" i] { order: 20 !important; }
  #PanelUI-zen-workspaces-list toolbarbutton.zen-workspace-button[aria-label^="H" i] { order: 19 !important; }
  #PanelUI-zen-workspaces-list toolbarbutton.zen-workspace-button[aria-label^="I" i] { order: 18 !important; }
  #PanelUI-zen-workspaces-list toolbarbutton.zen-workspace-button[aria-label^="J" i] { order: 17 !important; }
  #PanelUI-zen-workspaces-list toolbarbutton.zen-workspace-button[aria-label^="K" i] { order: 16 !important; }
  #PanelUI-zen-workspaces-list toolbarbutton.zen-workspace-button[aria-label^="L" i] { order: 15 !important; }
  #PanelUI-zen-workspaces-list toolbarbutton.zen-workspace-button[aria-label^="M" i] { order: 14 !important; }
  #PanelUI-zen-workspaces-list toolbarbutton.zen-workspace-button[aria-label^="N" i] { order: 13 !important; }
  #PanelUI-zen-workspaces-list toolbarbutton.zen-workspace-button[aria-label^="O" i] { order: 12 !important; }
  #PanelUI-zen-workspaces-list toolbarbutton.zen-workspace-button[aria-label^="P" i] { order: 11 !important; }
  #PanelUI-zen-workspaces-list toolbarbutton.zen-workspace-button[aria-label^="Q" i] { order: 10 !important; }
  #PanelUI-zen-workspaces-list toolbarbutton.zen-workspace-button[aria-label^="R" i] { order:  9 !important; }
  #PanelUI-zen-workspaces-list toolbarbutton.zen-workspace-button[aria-label^="S" i] { order:  8 !important; }
  #PanelUI-zen-workspaces-list toolbarbutton.zen-workspace-button[aria-label^="T" i] { order:  7 !important; }
  #PanelUI-zen-workspaces-list toolbarbutton.zen-workspace-button[aria-label^="U" i] { order:  6 !important; }
  #PanelUI-zen-workspaces-list toolbarbutton.zen-workspace-button[aria-label^="V" i] { order:  5 !important; }
  #PanelUI-zen-workspaces-list toolbarbutton.zen-workspace-button[aria-label^="W" i] { order:  4 !important; }
  #PanelUI-zen-workspaces-list toolbarbutton.zen-workspace-button[aria-label^="X" i] { order:  3 !important; }
  #PanelUI-zen-workspaces-list toolbarbutton.zen-workspace-button[aria-label^="Y" i] { order:  2 !important; }
  #PanelUI-zen-workspaces-list toolbarbutton.zen-workspace-button[aria-label^="Z" i] { order:  1 !important; }
}
```

- [ ] **Step 11.2: Append Section 6 (compact mode)**

```css

/* -----  Section 6: Compact rows  --------------------------------------- */

@media (-moz-bool-pref: "mod.spaces-dropdown.compact") {
  #PanelUI-zen-workspaces-list toolbarbutton.zen-workspace-button {
    padding-top: 5px !important;
    padding-bottom: 5px !important;
    margin: 1px 6px !important;
  }
}
```

- [ ] **Step 11.3: Commit**

```bash
git -C /Users/nicojan/dev/zen-mod add mod/chrome.css
git -C /Users/nicojan/dev/zen-mod commit -m "feat(css): add alphabetical sort and compact-row modes"
```

---

## Task 12: `scripts/validate.sh` — JSON and required-keys check

**Files:**
- Create: `scripts/validate.sh`

- [ ] **Step 12.1: Write the validator**

```bash
#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

THEME_JSON="${PROJECT_ROOT}/mod/theme.json"
PREFS_JSON="${PROJECT_ROOT}/mod/preferences.json"

echo "==> validating ${THEME_JSON}"
python3 -m json.tool "${THEME_JSON}" > /dev/null
python3 - <<PY
import json, sys
required = {"id","name","description","style","readme","author","version","createdAt","updatedAt"}
with open("${THEME_JSON}") as f:
    obj = json.load(f)
missing = required - obj.keys()
if missing:
    print(f"missing keys in theme.json: {sorted(missing)}", file=sys.stderr)
    sys.exit(1)
# Verify it's a UUID-shaped id
import re
if not re.fullmatch(r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}", obj["id"]):
    print(f"theme.json: id is not a UUID: {obj['id']}", file=sys.stderr)
    sys.exit(1)
print("  ok")
PY

echo "==> validating ${PREFS_JSON}"
python3 -m json.tool "${PREFS_JSON}" > /dev/null
python3 - <<PY
import json, sys
with open("${PREFS_JSON}") as f:
    arr = json.load(f)
if not isinstance(arr, list):
    print("preferences.json must be a JSON array", file=sys.stderr)
    sys.exit(1)
for i, p in enumerate(arr):
    required = {"property","label","type"}
    missing = required - p.keys()
    if missing:
        print(f"preference[{i}] missing: {sorted(missing)}", file=sys.stderr); sys.exit(1)
    if p["type"] not in ("checkbox","dropdown","string"):
        print(f"preference[{i}] bad type: {p['type']}", file=sys.stderr); sys.exit(1)
    if p["type"] == "dropdown" and "options" not in p:
        print(f"preference[{i}] dropdown missing options", file=sys.stderr); sys.exit(1)
print("  ok")
PY

echo "all good."
```

- [ ] **Step 12.2: Make executable and run**

```bash
chmod +x /Users/nicojan/dev/zen-mod/scripts/validate.sh
/Users/nicojan/dev/zen-mod/scripts/validate.sh
```

Expected output:
```
==> validating .../mod/theme.json
  ok
==> validating .../mod/preferences.json
  ok
all good.
```

- [ ] **Step 12.3: Commit**

```bash
git -C /Users/nicojan/dev/zen-mod add scripts/validate.sh
git -C /Users/nicojan/dev/zen-mod commit -m "feat(scripts): add JSON validator for theme.json and preferences.json"
```

---

## Task 13: Write `mod/readme.md` (user-facing) and finalize project `README.md`

**Files:**
- Create: `mod/readme.md`
- Modify: `README.md`

- [ ] **Step 13.1: Write `mod/readme.md`** (this is the marketplace-facing description)

```markdown
# Spaces Dropdown

Turns the workspace switcher at the bottom of Zen's sidebar into a polished
upward-opening dropdown.

- Workspace #1 sits at the bottom of the dropdown, closest to the trigger
  button. Higher-numbered workspaces stack upward.
- Subtle drag-handles fade in on hover. Drag any row to reorder — Zen's native
  workspace reordering is preserved.
- Optional alphabetical sort.
- Optional compact row height for users with many workspaces.

## Preferences

| Setting | Default | What it does |
|---|---|---|
| **Sort spaces by** | Manual | `Manual` honors the drag order you set. `Alphabetical (A → Z)` sorts by workspace name. |
| **Show drag handles on hover** | On | Reveals a subtle grip glyph on the left of each row when you hover it. |
| **Compact rows** | Off | Tightens row vertical padding for denser lists. |

## Known limitations

- "Sort by recently used" is not available. The marketplace runs CSS-only mods,
  and that mode requires tracking timestamps in JavaScript.
- Alphabetical sort uses the first letter of each workspace name. Workspaces
  starting with a non-letter character sort after Z.

## Author

[nicojan](https://github.com/nicojan) — issues and contributions welcome at the
[zen-spaces-dropdown repo](https://github.com/nicojan/zen-spaces-dropdown).
```

- [ ] **Step 13.2: Replace project `README.md` with full content**

```markdown
# zen-spaces-dropdown

A CSS-only Zen Browser Mod that turns the workspace switcher into a polished
upward-opening dropdown anchored at the bottom of the sidebar.

![Spaces Dropdown preview](./mod/image.png)

## What it does

- Restyles Zen's existing workspace popup to open upward from the trigger.
- Reverses the visual order so workspace #1 sits closest to the trigger
  button.
- Reveals a subtle drag-handle glyph on hover. Drag rows to reorder — Zen's
  native reordering is preserved.
- Optional alphabetical sort.
- Optional compact row height.

See [`mod/readme.md`](./mod/readme.md) for the user-facing description that
ships to the marketplace.

## Repo layout

```
mod/         The actual mod (theme.json, chrome.css, preferences.json, etc.)
scripts/     Dev helpers (symlink into Zen profile, validate JSON)
docs/        Spec and implementation plan
```

## Development

### Live-edit setup (macOS, default profile)

```bash
./scripts/link-dev.sh
```

This symlinks `mod/chrome.css` into your active Zen profile as
`userChrome.css`. Then in Zen:

1. Open `about:config`.
2. Set `toolkit.legacyUserProfileCustomizations.stylesheets` to `true`.
3. Restart Zen.
4. Open DevTools (`Ctrl+Shift+Alt+I`) → Style Editor — `userChrome.css` is now
   live-editable; changes apply immediately.

To remove the symlink:

```bash
./scripts/unlink-dev.sh
```

### Validation

```bash
./scripts/validate.sh
```

Validates `theme.json` and `preferences.json`.

## Testing

This is a CSS-only mod, so testing is manual visual verification. Walk through
the preference matrix in Zen Settings → Mods → Spaces Dropdown:

- **Sort**: Manual, Alphabetical
- **Show drag handles**: On, Off
- **Compact rows**: On, Off

Verify with 1 workspace, 3 workspaces, and 10+ workspaces. Verify in both
light and dark themes.

## Publishing to the Zen Mods marketplace

1. Push to GitHub (make sure `mod/image.png` is committed).
2. Open an issue at
   [`zen-browser/theme-store`](https://github.com/zen-browser/theme-store/issues/new/choose)
   titled `[create-theme]: Spaces Dropdown`.
3. Fill in the template with the raw GitHub URLs from `mod/theme.json`.
4. A bot scaffolds the marketplace entry.

## License

[CC BY-NC-SA 4.0](./LICENSE)
```

- [ ] **Step 13.3: Commit**

```bash
git -C /Users/nicojan/dev/zen-mod add mod/readme.md README.md
git -C /Users/nicojan/dev/zen-mod commit -m "docs: write user-facing mod readme and full project README"
```

---

## Task 14: Live-test in Zen, capture screenshot for `mod/image.png`

This task requires a running Zen Browser. If Zen is not installed (Task 3 Step 3.4 surfaced this), skip Step 14.1–14.3 and use a 1280×800 placeholder for `image.png`.

**Files:**
- Create: `mod/image.png`

- [ ] **Step 14.1: Run `link-dev.sh`**

```bash
/Users/nicojan/dev/zen-mod/scripts/link-dev.sh
```

- [ ] **Step 14.2: Open Zen, enable legacy stylesheets, restart**

Manual step. Then create 3–4 workspaces with distinct names ("Personal", "Work", "Research", "Music") so the screenshot is informative.

- [ ] **Step 14.3: Click the workspace button, take a screenshot of the dropdown**

Use macOS `Cmd+Shift+4` or `Cmd+Shift+5` to capture the dropdown area only. Save to `/Users/nicojan/dev/zen-mod/mod/image.png`. Ensure dimensions are ≥1280×800; resize if needed:

```bash
sips -Z 1280 /Users/nicojan/dev/zen-mod/mod/image.png
```

- [ ] **Step 14.4: Commit**

```bash
git -C /Users/nicojan/dev/zen-mod add mod/image.png
git -C /Users/nicojan/dev/zen-mod commit -m "docs: add marketplace preview screenshot"
```

---

## Task 15: Audit pass (UI/UX, edge cases, preference matrix)

This task is the explicit user-requested iteration loop. Run it after Task 14.

**Files:** Modify whichever section of `mod/chrome.css` the audit surfaces issues in.

- [ ] **Step 15.1: Audit checklist — go through each item and note issues**

For each item, test in Zen with the live-linked CSS:

1. **Single workspace**: Does the dropdown look right with only one row?
2. **Many workspaces (10+)**: Does the dropdown overflow gracefully? Is scrolling smooth?
3. **Very long workspace name**: Does it truncate with ellipsis or wrap unbearably?
4. **Workspaces with emoji/unicode names**: Do they render correctly? Do they sort sensibly in alphabetical mode?
5. **Light theme**: Hover state visible? Selected state distinct?
6. **Dark theme**: Hover state visible? Selected state distinct?
7. **Accent color binding**: Selected workspace uses the system accent color?
8. **Compact mode on, drag handles on**: Do the handles still fit?
9. **Alphabetical mode**: Is the sort visually correct? Is the reverse-of-reverse logic right (A nearest the trigger)?
10. **Toggling sort live**: Does the order update without restart?
11. **Toggling drag-handles live**: Does the glyph fade in/out cleanly?
12. **Animation smoothness**: Open/close transition feel right?
13. **Click target**: Is the row click target the same as without the mod? (Don't break Zen's native click handling.)
14. **Drag-to-reorder**: Can you still drag rows? Does drop visualization work?
15. **Keyboard navigation**: Tab/arrow keys still work in the popup?

- [ ] **Step 15.2: Fix findings**

For each issue found, edit the relevant section of `chrome.css` and commit with `fix(css): <what>`. If a structural problem requires re-architecting (e.g., the popup truly cannot be flipped via CSS), update the spec at `docs/superpowers/specs/2026-05-12-zen-spaces-dropdown-design.md` and re-think.

- [ ] **Step 15.3: Re-audit after fixes**

Repeat Step 15.1 until findings are trivial (purely cosmetic disagreements, no functional issues).

- [ ] **Step 15.4: Final commit and version bump**

If the audit produced fixes, bump `version` in `theme.json` from `1.0.0` to `1.0.1` (or `1.1.0` if functionality changed):

```bash
git -C /Users/nicojan/dev/zen-mod commit -am "chore: bump version to 1.0.1 after audit pass"
```

---

## Task 16: Final push and marketplace submission (optional, gated on user confirm)

**Files:** None modified.

- [ ] **Step 16.1: Push all commits**

```bash
git -C /Users/nicojan/dev/zen-mod push
```

- [ ] **Step 16.2: Open marketplace submission issue (only if user confirms)**

Do NOT auto-open the marketplace issue. Ask the user first: "Ready to submit to the Zen Mods marketplace? This opens a public issue at `zen-browser/theme-store`."

If yes:

```bash
gh issue create \
  --repo zen-browser/theme-store \
  --title "[create-theme]: Spaces Dropdown" \
  --body "$(cat <<'EOF'
**Mod name:** Spaces Dropdown
**Author:** nicojan
**Description:** Turns the workspace switcher at the bottom of Zen's sidebar into a polished upward-opening dropdown. Workspace #1 sits closest to the trigger; higher numbers stack upward. Hover drag-handles, manual/alphabetical sort, optional compact rows.
**Repo:** https://github.com/nicojan/zen-spaces-dropdown
**Raw URLs:**
- theme.json:       https://raw.githubusercontent.com/nicojan/zen-spaces-dropdown/main/mod/theme.json
- chrome.css:       https://raw.githubusercontent.com/nicojan/zen-spaces-dropdown/main/mod/chrome.css
- preferences.json: https://raw.githubusercontent.com/nicojan/zen-spaces-dropdown/main/mod/preferences.json
- readme.md:        https://raw.githubusercontent.com/nicojan/zen-spaces-dropdown/main/mod/readme.md
- image.png:        https://raw.githubusercontent.com/nicojan/zen-spaces-dropdown/main/mod/image.png

**License:** CC BY-NC-SA 4.0
EOF
)"
```

---

## Self-review (writing-plans checklist)

**Spec coverage:**
- Spec §1 Purpose → Tasks 7–11 (CSS sections) implement this.
- Spec §2 In-scope items → Tasks 7 (popup upward), 8 (order reversal), 10 (drag handle), 11 (alphabetical, compact), 6 (sort preference).
- Spec §3 Architecture constraints (CSS-only, `-moz-pref` queries) → encoded in Tasks 10, 11.
- Spec §3 Risks: DOM/attribute risk → Task 4 verifies; Task 6 Step 6.3 documents the fallback (drop sort).
- Spec §4 Components → Tasks 5–13 each create one component.
- Spec §6 Error handling (defensive selectors, `!important` discipline) → Task 15 audit checklist Item 13 verifies click behavior preserved.
- Spec §7 Testing → Task 15 explicit audit.
- Spec §8 Build/Publish → Task 16.
- Spec §9 Naming/UUID → Task 5.

No gaps.

**Placeholder scan:** No `TBD`, `TODO`, or vague-handling steps. Selector names in Task 7 carry concrete defaults plus a note that Task 4 may refine them; Task 11 has the full A–Z enumeration explicit; Task 14 has explicit `sips` resize command.

**Type/name consistency:** `#PanelUI-zen-workspaces`, `#PanelUI-zen-workspaces-list`, `toolbarbutton.zen-workspace-button`, `mod.spaces-dropdown.{sort, show-drag-handles, compact}` are used consistently across Tasks 7, 8, 9, 10, 11, 12 (validator), and 13.

---

**Plan complete.** Execution options:

1. **Subagent-Driven (recommended)** — dispatch a fresh subagent per task, review between tasks.
2. **Inline Execution** — execute tasks in this session with checkpoints.

Given user request "build it autonomously, also iteratively", **inline execution with checkpoints** is the better fit — it keeps everything in one session for the audit-and-revise loop in Task 15.
