---
name: publish-plugin-version
description: Publish or roll back the public Dalamud custom repository version for the RSR/BMR integration builds. Use when Codex needs to update pluginmaster.json to point at already-created fixed GitHub Release assets, verify links, commit, and push the DalamudPluginRepo metadata.
---

# Publish Plugin Version

## Overview

Use this skill in `fenk19/DalamudPluginRepo` after fixed-version public GitHub
Release assets exist in this repository. The RSR and BMR custom repositories can
remain private; `pluginmaster.json` must point only at public assets in
`DalamudPluginRepo`.

## Workflow

1. Confirm repository state:

```sh
git status --short --branch
git remote -v
```

Work from `main`. `origin` should be `fenk19/DalamudPluginRepo`.

2. Confirm the target version exists in this public repository:

```sh
gh release view 99.0.0.N --repo fenk19/DalamudPluginRepo --json assets,url
```

The release must include `RotationSolver-BMR-99.0.0.N.zip`,
`BossModReborn-RSR-99.0.0.N.zip`, and
`RotationSolverReborn-BMR-99.0.0.N-source.zip`.

3. Preview the public metadata change:

```sh
scripts/set-public-version.sh 99.0.0.N --verify-links --dry-run
```

For a one-plugin publication, add `--only rsr` or `--only bmr`. Avoid partial
publication unless that is explicitly intended.

4. Apply, commit, and push:

```sh
scripts/set-public-version.sh 99.0.0.N --verify-links --commit --push
```

5. Verify the pushed metadata:

```sh
git status --short --branch
curl -fsSL https://raw.githubusercontent.com/fenk19/DalamudPluginRepo/main/pluginmaster.json
```

Check that `RotationSolver`, `BossModReborn`, and the RSR corresponding-source
link in the changelog all point to
`fenk19/DalamudPluginRepo/releases/download/VERSION/...`.

## Rollback Guidance

Publishing a lower `AssemblyVersion` changes what new installs and manual
reinstalls receive, but it will not auto-downgrade clients that already installed
a higher version. Dalamud's normal update detection only offers versions greater
than the installed version.

For automatic rollback of installed clients, build and publish a new higher
version whose contents revert the bad change, for example `99.0.0.4` after a bad
`99.0.0.3`.

## Constraints

- Keep both plugin entries on the same `99.0.0.N` version unless intentionally
using `--only`.
- Keep install/update URLs public. Do not point `pluginmaster.json` at the
private RSR/BMR custom repositories.
- Use `--verify-links` before writing public metadata.
- Do not edit `pluginmaster.json` by hand for normal release operations; use the
scripts so URLs, versions, changelogs, and `LastUpdate` stay consistent.
