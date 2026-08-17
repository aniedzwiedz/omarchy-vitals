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

Maintainers, from a clean `main` that matches `origin/main`:

```bash
./scripts/release.sh patch    # 1.2.0 -> 1.2.1
./scripts/release.sh minor    # 1.2.0 -> 1.3.0
./scripts/release.sh 1.3.0    # explicit
```

The script runs checks, cuts the changelog, commits, tags `vX.Y.Z`, pushes,
and creates the GitHub Release. Users pick it up with
`omarchy plugin update hamsti.vitals`.
