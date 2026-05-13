# zen-spaces-dropdown

A CSS-only Zen Browser Mod that turns the inline workspace switcher into a
polished upward-opening dropdown anchored at the bottom of the sidebar.

![Spaces Dropdown preview](./mod/image.png)

## What it does

- Collapses Zen's workspace bar so only the active workspace shows by default.
- On hover or keyboard focus, the dropdown expands **upward** with the other
  workspaces stacked above. Workspace #1 sits closest to the trigger; higher
  numbers stack upward.
- Reveals a subtle drag-handle glyph on hover. Drag rows to reorder — Zen's
  native reordering is preserved.
- Optional alphabetical sort, compact rows, and "always open" mode.

See [`mod/readme.md`](./mod/readme.md) for the user-facing description that
ships to the Zen Mods marketplace.

## Repo layout

```
mod/         The artifact (theme.json, chrome.css, preferences.json, readme.md, image.png)
scripts/     Dev helpers (symlink into Zen profile, validate JSON + CSS)
docs/        Spec and implementation plan
```

## Development

### Live-edit setup (macOS)

```bash
./scripts/link-dev.sh                 # uses Default profile from profiles.ini
./scripts/link-dev.sh "Profiles/<id>" # or specify a profile explicitly
```

This symlinks `mod/chrome.css` into the chosen Zen profile as
`chrome/userChrome.css`. Then in Zen:

1. Open `about:config`.
2. Set `toolkit.legacyUserProfileCustomizations.stylesheets` to `true`.
3. Restart Zen.
4. Open DevTools (`Cmd+Shift+Alt+I` on macOS) → Style Editor — `userChrome.css`
   is now live-editable; changes apply immediately.

To remove the symlink (and restore any prior `userChrome.css` from backup):

```bash
./scripts/unlink-dev.sh
```

### Validation

```bash
./scripts/validate.sh
```

Validates `theme.json` and `preferences.json` as JSON, checks required fields,
verifies the `id` is a UUID, and brace-checks `chrome.css`.

## Testing

This is a CSS-only mod, so testing is manual visual verification. Walk through
the preference matrix in Zen → Settings → Mods → **Spaces Dropdown**:

- **Sort**: Manual, Alphabetical
- **Show drag handles**: On, Off
- **Compact rows**: On, Off
- **Always open**: On, Off

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
