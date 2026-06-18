# Phase 4 Scripted Screenshot Validation

Date: 2026-06-18

Branch: `lab/pebblelab-v1`

## Objective

Capture visual evidence of a gated `LabCoreAgentEntity` probe with Pebble's
existing app hooks, without changing simulation, persistence, commands, or
rendering.

## Existing Hooks

`Sources/Pebble/main.swift` already provides the complete sequence:

- `PEBBLE_AUTOLOAD=1` skips menus and enters a world;
- `PEBBLE_NEWWORLD=<seed>` creates a fresh world when autoload is active;
- `PEBBLE_CMD="..."` waits until a world and player exist, then waits more
  than 90 frames and executes semicolon-separated commands;
- `PEBBLE_SHOT=<path>@<frames>` waits until `PEBBLE_CMD` has completed, counts
  down the requested frames, and captures the composited frame without UI;
- after capture, Pebble waits 120 frames for the asynchronous PNG write and
  terminates normally.

`PEBBLE_SHOT` also disables `framebufferOnly`, allowing the renderer's existing
texture-to-buffer capture path. App termination invokes the Phase 4.5A probe
cleanup before final save.

No `scripts/` directory or existing shell-script convention is present, so
Phase 4.5B adds documentation rather than creating a new repository convention.

## Prerequisites

- Use a clean `lab/pebblelab-v1` worktree.
- Use a unique `PEBBLE_NEWWORLD` seed; this creates a disposable world named
  `WGTest-<seed>` in the local world list.
- Keep all environment variables scoped to one command.
- Choose a screenshot path under `/tmp`.
- Build the release Pebble product first.

## Validated Command

The probe spawns one block east of the player. The existing `/tp` command sets
the camera yaw to `-90` so the probe is framed before capture:

```sh
cd ~/Dev/pebble-lab
PEBBLELAB_APP_PROBES=1 \
PEBBLELAB_DEBUG_ENTITIES=1 \
PEBBLE_AUTOLOAD=1 \
PEBBLE_NEWWORLD=4546 \
PEBBLE_CMD='/tp ~ ~ ~ -90 0;/labprobe spawn' \
PEBBLE_SHOT=/tmp/pebblelab-probe-phase45b-facing.png@120 \
swift run -c release Pebble
```

## Expected Workflow

1. Create and enter `WGTest-4546`.
2. Wait for the player and more than 90 rendered frames.
3. Face east with the existing `/tp` command.
4. Spawn one gated transient probe.
5. Wait another 120 frames.
6. Capture the final composited image without HUD.
7. Terminate normally after the asynchronous PNG write.
8. Clear the probe through the app termination hook before final save.

## Observed Results

The validated command completed successfully and printed:

```text
[shot] captured /tmp/pebblelab-probe-phase45b-facing.png
```

The resulting PNG:

- exists at the requested `/tmp` path;
- is `3024 x 1898` pixels;
- contains the cyan wireframe AABB in front of the camera;
- is not tracked or committed.

An initial attempt without camera orientation also produced a valid PNG, but
the probe was outside the camera view. This proves that command-before-shot
ordering is reliable while framing remains the caller's responsibility.

## Limits

- The hook proves command execution, rendering, capture, and normal
  termination, but it does not parse chat output or assert probe count.
- Visual confirmation was performed by inspecting the generated PNG; no
  automated pixel classifier was added.
- Terrain can partially obscure the marker depending on spawn and camera.
- Each `PEBBLE_NEWWORLD` run leaves a disposable `WGTest-*` world in the local
  world list; remove it manually after validation.
- This is not a general UI-test framework.

## Cleanup And Safety

- Never use `PEBBLE_AUTOLOAD` without `PEBBLE_NEWWORLD` for this workflow;
  otherwise Pebble opens the most recently played save.
- Use only disposable seeds and worlds.
- Keep screenshot output under `/tmp` or ignored `runs/`.
- Do not export the gates globally.
- Delete disposable `WGTest-*` worlds after review.
- Manual sessions should still run `/labprobe clear`; scripted-shot sessions
  rely on normal termination cleanup from Phase 4.5A.

## Next Phase

Recommended: Phase 4.6A, first simple physical behavior loop planning. The
probe lifecycle, visibility, save exclusion, cleanup, and screenshot evidence
are now established; any behavior must remain deterministic, gated, and
separate from vanilla mobs.
