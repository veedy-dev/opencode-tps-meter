# OpenCode TPS Meter

Adds a live TPS meter to the OpenCode TUI footer.

It shows:
- live rolling TPS over the last 15 seconds while a response is streaming
- exact output TPS after the response completes

## Demo

![OpenCode TPS Meter demo](assets/tps-meter-demo.gif)

Full video: [assets/tps-meter-demo.mp4](assets/tps-meter-demo.mp4)

This is a **TUI/CLI patch**, not a Desktop extension and not a normal OpenCode plugin. OpenCode does not expose a plugin hook for the TUI footer, so this project patches the OpenCode source for supported versions.

## Install

One command:

```bash
curl -fsSL https://raw.githubusercontent.com/guard22/opencode-tps-meter/main/install.sh | bash
```

By default, the installer uses the **latest supported** OpenCode version from [`manifest.sh`](manifest.sh).

To install a specific supported version:

```bash
OPENCODE_TPS_VERSION=1.3.13 curl -fsSL https://raw.githubusercontent.com/guard22/opencode-tps-meter/main/install.sh | bash
```

## How the installer works

- downloads the exact supported OpenCode tag
- downloads the matching patch for that exact version
- runs `git apply --check` before modifying anything
- installs the patched source into `~/.local/share/opencode-tps-meter/releases/<version>`
- points `~/.local/share/opencode-tps-meter/current` at the active release
- installs a wrapper at `~/.local/bin/opencode`
- preserves your original launcher as `~/.local/bin/opencode-stock`

If the requested OpenCode version is not supported, or the patch does not apply cleanly, the installer exits without replacing your launcher.

## Supported versions

Current supported versions are listed in [`manifest.sh`](manifest.sh).

Right now:

- `1.3.13`

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/guard22/opencode-tps-meter/main/uninstall.sh | bash
```

## Notes

- This patches **OpenCode TUI/CLI**, not Desktop.
- It preserves your launch directory, so `opencode` opens the project you launched it from.
- Live TPS is an estimate based on stream deltas.
- Final TPS uses exact **output-token** usage from the completed assistant message.
- Requires `bun`, `git`, and `curl`.
- Future OpenCode releases may require a new patch; unsupported versions fail cleanly instead of half-installing.

## Tested

- OpenCode `1.3.13`
- Bun `1.3.5`
