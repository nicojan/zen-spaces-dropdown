# Spaces Dropdown

Turns the workspace switcher at the bottom of Zen's sidebar into a polished
upward-opening dropdown.

- Collapsed by default: only the active workspace shows, acting as the trigger.
- Hover or focus the trigger and the dropdown expands **upward**, with the
  other workspaces stacked above. Workspace #1 sits closest to the trigger;
  higher-numbered workspaces stack upward.
- A subtle drag-handle glyph fades in on hover. Drag any row to reorder —
  Zen's built-in workspace reordering is preserved.
- Optional alphabetical sort.
- Optional compact row height for users with many workspaces.
- "Always open" mode if you'd rather skip the collapse behavior entirely.

## Preferences

| Setting | Default | What it does |
|---|---|---|
| **Sort spaces by** | Manual | `Manual` honors the drag order you set. `Alphabetical (A → Z)` sorts by the first letter of each workspace name. |
| **Show drag handles on hover** | On | Reveals a subtle grip glyph on the left of each row when you hover it. |
| **Compact rows** | Off | Tightens row vertical padding for denser lists. |
| **Always show all spaces** | Off | Disables the collapse-to-trigger behavior. Useful if you prefer always-visible workspace icons. |

## Known limitations

- "Sort by recently used" is not available. The Zen Mods marketplace runs
  CSS-only mods, and that mode requires tracking timestamps in JavaScript.
- Alphabetical sort uses the first letter of each workspace name. Workspaces
  starting with a non-letter character (numbers, emoji, etc.) sort after Z.

## Author

[nicojan](https://github.com/nicojan) — issues and contributions welcome at the
[zen-spaces-dropdown repo](https://github.com/nicojan/zen-spaces-dropdown).
