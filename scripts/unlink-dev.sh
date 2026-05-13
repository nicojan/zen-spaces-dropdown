#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZEN_ROOT="${HOME}/Library/Application Support/zen"
PROFILES_INI="${ZEN_ROOT}/profiles.ini"

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
