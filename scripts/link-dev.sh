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
  PROFILE_REL=$(awk '
    /^\[Install/ { in_install = 1; next }
    /^\[/         { in_install = 0 }
    in_install && /^Default=/ { sub(/^Default=/, ""); print; exit }
  ' "${PROFILES_INI}")
  PROFILE_PATH="${ZEN_ROOT}/${PROFILE_REL}"
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
echo "  1. Open Zen -> about:config"
echo "  2. Set 'toolkit.legacyUserProfileCustomizations.stylesheets' to true"
echo "  3. Restart Zen"
echo "  4. Open DevTools (Ctrl+Shift+Alt+I) -> Style Editor -> edit userChrome.css for live updates"
