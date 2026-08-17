#!/usr/bin/env bash
# Cut a tagged GitHub release. Versions are CalVer: YYYY.MM.DD
# (YYYY.MM.DD.N if we ship more than once that day).
#
#   ./scripts/release.sh              # today
#   ./scripts/release.sh 2026.08.17   # explicit
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

fail() {
  echo "release: $*" >&2
  exit 1
}

command -v git >/dev/null || fail "git is required"
command -v jq >/dev/null || fail "jq is required"
command -v python3 >/dev/null || fail "python3 is required"
command -v gh >/dev/null || fail "gh is required"

[[ -z $(git status --porcelain) ]] || fail "working tree is dirty"
[[ $(git branch --show-current) == main ]] || fail "release from main"
git fetch origin
[[ $(git rev-parse HEAD) == $(git rev-parse origin/main) ]] \
  || fail "main is not in sync with origin/main"

calver_re='^[0-9]{4}\.[0-9]{2}\.[0-9]{2}(\.[0-9]+)?$'
today=$(date +%Y.%m.%d)

if [[ $# -eq 0 ]]; then
  version=$today
  n=1
  while git rev-parse "v$version" >/dev/null 2>&1; do
    version="${today}.${n}"
    n=$((n + 1))
  done
elif [[ $# -eq 1 ]]; then
  [[ $1 =~ $calver_re ]] || fail "version must be YYYY.MM.DD or YYYY.MM.DD.N"
  version=$1
else
  fail "usage: $0 [YYYY.MM.DD]"
fi

tag="v$version"
git rev-parse "$tag" >/dev/null 2>&1 && fail "tag $tag already exists"

"$root/scripts/check.sh"

iso_date=$(date +%F)
python3 - "$version" "$iso_date" <<'PY'
import pathlib, re, sys

version, today = sys.argv[1], sys.argv[2]
path = pathlib.Path("CHANGELOG.md")
text = path.read_text()
heading = f"## [{version}]"
repo = "https://github.com/thehamsti/omarchy-vitals"

unreleased = re.search(r"^## \[Unreleased\]\s*\n", text, re.M)
if not unreleased:
    sys.exit("CHANGELOG.md has no [Unreleased] section")

if heading not in text:
    rest = text[unreleased.end():]
    nxt = re.search(r"^## \[", rest, re.M)
    notes = rest[: nxt.start()] if nxt else rest
    after = rest[nxt.start():] if nxt else ""
    body = notes.strip()
    section = f"## [{version}] - {today}\n"
    if body:
        section += f"\n{body}\n"
    section += "\n"
    text = text[: unreleased.end()] + "\n" + section + after

unreleased_link = f"[Unreleased]: {repo}/compare/v{version}...HEAD"
version_link = f"[{version}]: {repo}/releases/tag/v{version}"
if re.search(r"^\[Unreleased\]:", text, re.M):
    text = re.sub(r"^\[Unreleased\]:.*$", unreleased_link, text, count=1, flags=re.M)
else:
    text = text.rstrip() + "\n\n" + unreleased_link + "\n"
if version_link not in text:
    text = re.sub(
        r"^\[Unreleased\]:.*$",
        unreleased_link + "\n" + version_link,
        text,
        count=1,
        flags=re.M,
    )

path.write_text(text)
print(f"changelog: {heading} - {today}")
PY

tmp=$(mktemp)
jq --arg v "$version" '.version = $v' manifest.json >"$tmp"
mv "$tmp" manifest.json

notes=$(python3 - "$version" <<'PY'
import pathlib, re, sys
version = sys.argv[1]
text = pathlib.Path("CHANGELOG.md").read_text()
match = re.search(
    rf"^## \[{re.escape(version)}\][^\n]*\n(.*?)(?=^## |\Z)",
    text,
    re.M | re.S,
)
if not match:
    sys.exit(f"no changelog section for {version}")
body = match.group(1).strip()
body = re.sub(r"^\[.*\]: .*\n?", "", body, flags=re.M).strip()
print(f"## Vitals {version}\n")
print(body or "See the commit history for details.")
PY
)

if [[ -n $(git status --porcelain) ]]; then
  git add manifest.json CHANGELOG.md
  git commit -m "Release ${version}"
fi

git tag -a "$tag" -m "Vitals ${version}"
git push origin main
git push origin "$tag"
gh release create "$tag" --title "Vitals ${version}" --notes "$notes"

echo "released ${tag}"
echo "users update with: omarchy plugin update hamsti.vitals"
