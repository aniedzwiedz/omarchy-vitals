#!/usr/bin/env bash
# Run the same checks CI and ./scripts/release.sh expect.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

fail() {
  echo "check: $*" >&2
  exit 1
}

command -v python3 >/dev/null || fail "python3 is required"
command -v node >/dev/null || fail "node is required"
command -v jq >/dev/null || fail "jq is required"

python3 -m py_compile collect.py
node tests/model.test.js

jq -e '
  .schemaVersion == 1
  and (.id | type == "string" and length > 0)
  and (.version | test("^[0-9]+\\.[0-9]+\\.[0-9]+$"))
  and (.kinds | type == "array" and length > 0)
  and (.entryPoints | type == "object")
  and (.entryPoints.barWidget | type == "string")
' manifest.json >/dev/null \
  || fail "manifest.json is missing required fields or a semver version"

entry=$(jq -r '.entryPoints.barWidget' manifest.json)
[[ -f $entry ]] || fail "entryPoints.barWidget does not exist: $entry"

if command -v omarchy >/dev/null; then
  omarchy plugin validate .
fi

echo "checks passed"
