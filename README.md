# Dalamud Plugin Repository

This repository hosts the public Dalamud custom repository metadata for private
integration builds maintained by fenk19.

## Custom Repository URL

Add this URL in Dalamud:

```text
https://raw.githubusercontent.com/fenk19/DalamudPluginRepo/main/pluginmaster.json
```

In game, open `/xlsettings`, go to `Experimental`, add the URL under
`Custom Plugin Repositories`, save, then use the Plugin Installer.

## Distributed Builds

This repository is intended to publish release assets for:

- Rotation Solver Reborn with BossModReborn integration
- BossMod Reborn with RotationSolverReborn integration

The plugin identities are intentionally kept the same as the original plugins:

- `RotationSolver`
- `BossModReborn`

Because the identities are reused, these builds replace the corresponding
original plugins in Dalamud. Do not install the original and integration builds
side by side.

Dalamud may still show the integration builds as separate entries in the plugin
installer because they come from this custom repository and use different
display names and download metadata. That is expected. After installation, the
loaded plugin identity remains the original `InternalName`, so other plugins and
Dalamud plugin APIs should see them as `RotationSolver` and `BossModReborn`.
Use only one build for each reused identity at a time.

## Release Asset Policy

Each published version should include:

- The plugin install/update zip referenced by `pluginmaster.json`
- The plugin manifest used for the build
- License notices required by the upstream project
- For Rotation Solver Reborn, the complete corresponding source archive for the
  exact distributed DLL

For `99.0.0.2` and later, release fixed-version assets from the matching plugin
repository:

- `fenk19/RotationSolverReborn-BMR`
- `fenk19/BossmodReborn-RSR`

Rotation Solver Reborn is licensed under LGPL-3.0-or-later, so public binary
distribution must be accompanied by publicly accessible corresponding source.
BossMod Reborn is licensed under BSD-3-Clause, so its binary distribution must
include the copyright notice, license text, and disclaimer in the documentation
or other materials accompanying the distribution.

## Versioning

Integration builds use the `99.X.Y.Z` version range so that Dalamud treats them
as newer than the original upstream plugins even when upstream moves to a newer
game patch version.

Use these increment rules:

- Upstream-only sync without conflicts: increment `Z` only.
- Custom integration behavior change: increment `Y` and reset `Z` to `0`.
- Upstream sync that conflicts with existing custom changes: increment `Y` and
  reset `Z` to `0`, because the resolved result is treated as a custom
  integration change.

Keep `X` unchanged unless deliberately starting a new fixed-version series.

The first public integration build should use:

- `99.0.0.1`

To calculate the next version from the currently published `pluginmaster.json`
version:

```sh
scripts/next-version.sh upstream-only
scripts/next-version.sh custom
scripts/next-version.sh conflict
```

## Maintenance Scripts

Use the repository script to update `pluginmaster.json` after fixed-version
release assets have been uploaded:

```sh
scripts/update-pluginmaster.sh 99.0.0.2 --verify-links
```

Before writing, preview the generated metadata:

```sh
scripts/update-pluginmaster.sh 99.0.0.2 --dry-run
```

The script updates the install/update links, assembly versions, changelogs, and
`LastUpdate` fields for the `RotationSolver` and `BossModReborn` entries.

To move the public version forward or backward to an already published fixed
version:

```sh
scripts/set-public-version.sh 99.0.0.2 --verify-links --commit --push
```

This only changes `pluginmaster.json`; it does not create plugin release assets.
Create those first in each plugin repository with `scripts/release-version.sh`.

Dalamud automatic updates are version-increasing. Publishing a lower
`AssemblyVersion` is useful for new installs and manual reinstall/recovery, but
clients that already installed a higher version should not be expected to
automatically downgrade.
