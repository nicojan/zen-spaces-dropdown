#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

THEME_JSON="${PROJECT_ROOT}/mod/theme.json"
PREFS_JSON="${PROJECT_ROOT}/mod/preferences.json"
CHROME_CSS="${PROJECT_ROOT}/mod/chrome.css"

echo "==> validating ${THEME_JSON}"
python3 -m json.tool "${THEME_JSON}" > /dev/null
python3 - <<PY
import json, re, sys
required = {"id","name","description","style","readme","author","version","createdAt","updatedAt"}
with open("${THEME_JSON}") as f:
    obj = json.load(f)
missing = required - obj.keys()
if missing:
    print(f"missing keys in theme.json: {sorted(missing)}", file=sys.stderr)
    sys.exit(1)
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
    print("preferences.json must be a JSON array", file=sys.stderr); sys.exit(1)
for i, p in enumerate(arr):
    miss = {"property","label","type"} - p.keys()
    if miss:
        print(f"preference[{i}] missing: {sorted(miss)}", file=sys.stderr); sys.exit(1)
    if p["type"] not in ("checkbox","dropdown","string"):
        print(f"preference[{i}] bad type: {p['type']}", file=sys.stderr); sys.exit(1)
    if p["type"] == "dropdown" and "options" not in p:
        print(f"preference[{i}] dropdown missing options", file=sys.stderr); sys.exit(1)
print("  ok")
PY

echo "==> sanity-checking ${CHROME_CSS}"
# Cheap syntactic check: balanced braces.
python3 - <<PY
import sys
with open("${CHROME_CSS}") as f:
    css = f.read()
open_b  = css.count("{")
close_b = css.count("}")
if open_b != close_b:
    print(f"chrome.css: unbalanced braces ({open_b} open, {close_b} close)", file=sys.stderr)
    sys.exit(1)
print(f"  ok ({open_b} rule blocks)")
PY

echo "all good."
