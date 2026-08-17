# Contributing

PRs against `main` are welcome. Keep them small and scoped to one change.

## Checks

```bash
./scripts/check.sh
```

That compiles `collect.py`, runs `tests/model.test.js`, and sanity-checks
`manifest.json`. If `omarchy` is on `PATH` it also runs
`omarchy plugin validate .`.

## Changelog

Add a bullet under `## [Unreleased]` in `CHANGELOG.md`. Do not bump
`manifest.json` version in a feature PR — the release script does that.

## Releasing

Versions are [CalVer](https://calver.org/): `YYYY.MM.DD`. A second ship on
the same day becomes `YYYY.MM.DD.1`.

From a clean `main` that matches `origin/main`:

```bash
./scripts/release.sh              # today, e.g. 2026.08.17
./scripts/release.sh 2026.08.17   # explicit
```

The script runs checks, cuts the changelog, commits, tags `vYYYY.MM.DD`,
pushes, and creates the GitHub Release. Users pick it up with
`omarchy plugin update hamsti.vitals`.
