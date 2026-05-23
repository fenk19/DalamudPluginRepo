---
name: publish-plugin-version
description: Publish or roll back the public Dalamud custom repository version for the RSR/BMR integration builds. Use when Codex needs to update pluginmaster.json to point at already-created fixed GitHub Release assets, verify links, commit, and push the DalamudPluginRepo metadata.
---

# Publish Plugin Version

## Overview

Use this skill in `fenk19/DalamudPluginRepo` after fixed-version GitHub Release
assets exist in the RSR and BMR custom repositories. This skill updates the
public `pluginmaster.json` metadata only; it does not build plugin binaries.

## Workflow

1. Confirm repository state:

```sh
git status --short --branch
git remote -v
```

Work from `main`. `origin` should be `fenk19/DalamudPluginRepo`.

2. Confirm the target version exists in the plugin repositories:

```sh
gh release view 99.0.0.N --repo fenk19/RotationSolverReborn-BMR
gh release view 99.0.0.N --repo fenk19/BossmodReborn-RSR
```

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

Check that `RotationSolver` points to
`fenk19/RotationSolverReborn-BMR/releases/download/VERSION/RotationSolver-BMR-VERSION.zip`
and `BossModReborn` points to
`fenk19/BossmodReborn-RSR/releases/download/VERSION/BossModReborn-RSR-VERSION.zip`.

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
- Use `--verify-links` before writing public metadata.
- Do not edit `pluginmaster.json` by hand for normal release operations; use the
scripts so URLs, versions, changelogs, and `LastUpdate` stay consistent.
