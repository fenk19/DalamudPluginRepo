# Dalamud Plugin Repository

This repository hosts the public Dalamud custom repository metadata and release
assets for private integration builds maintained by fenk19.

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

## Release Asset Policy

Each published version should include:

- The plugin install/update zip referenced by `pluginmaster.json`
- The plugin manifest used for the build
- License notices required by the upstream project
- For Rotation Solver Reborn, the complete corresponding source archive for the
  exact distributed DLL

Rotation Solver Reborn is licensed under LGPL-3.0-or-later, so public binary
distribution must be accompanied by publicly accessible corresponding source.
BossMod Reborn is licensed under BSD-3-Clause, so its binary distribution must
include the copyright notice, license text, and disclaimer in the documentation
or other materials accompanying the distribution.

## Versioning

Integration builds should use a version number higher than the currently
available original build so that Dalamud does not replace them with an upstream
release from another repository. Increment the integration build suffix whenever
publishing a new build.
