# Phase 4 Visual App Validation

Date: 2026-06-18

Branch: `lab/pebblelab-v1`

## Objective

Validate the complete app-side debug probe workflow without extending the
simulation: explicit creation, cyan wireframe visibility, duplicate rejection,
status reporting, and explicit cleanup.

This is an operator-driven validation in a disposable world. It does not turn
the probe into gameplay content.

## Prerequisites

- Use branch `lab/pebblelab-v1` with a clean worktree.
- Use a newly created disposable world, never an important save.
- Confirm `swift build -c release --product Pebble` passes.
- Keep both gates scoped to this launch only:
  - `PEBBLELAB_APP_PROBES=1` permits creation;
  - `PEBBLELAB_DEBUG_ENTITIES=1` permits wireframe rendering.
- Know how to open chat and submit slash commands in Pebble.

## Terminal Launch

```sh
cd ~/Dev/pebble-lab
git checkout lab/pebblelab-v1
git pull origin lab/pebblelab-v1

PEBBLELAB_APP_PROBES=1 PEBBLELAB_DEBUG_ENTITIES=1 swift run -c release Pebble
```

Do not export either variable globally. Closing this process returns normal
launches to their default-off behavior.

## In-App Workflow

Run these commands in order:

```text
/labprobe status
/labprobe spawn
/labprobe status
/labprobe spawn
/labprobe clear
/labprobe status
```

## Expected Results

1. Initial status reports `gate=enabled, count=0`.
2. First spawn creates one transient probe near the player.
3. A cyan wireframe AABB appears near the player.
4. The second status reports `count=1` with entity ID and position.
5. The second spawn is refused and recommends `/labprobe clear`.
6. Clear reports that one probe was removed.
7. Final status reports `count=0`.
8. The cyan wireframe disappears after clear.

The probe must not appear in normal `/summon` behavior and must remain absent
from `EntityRegistry`. Its `shouldSaveToChunk` policy remains `false`.

## Observed Results

Manual app visual validation was completed successfully by the user in a new
disposable world with both `PEBBLELAB_APP_PROBES=1` and
`PEBBLELAB_DEBUG_ENTITIES=1` active.

Observed command results:

```text
/labprobe status
Lab probes: gate=enabled, count=0

/labprobe spawn
Spawned transient lab probe id=715 at 26.8 68.0 -106.5

/labprobe status
Lab probes: gate=enabled, count=1, id=715 at 26.8 68.0 -106.5

/labprobe spawn
A lab probe already exists. Use /labprobe clear first.

/labprobe clear
Removed 1 lab probe

/labprobe status
Lab probes: gate=enabled, count=0
```

The cyan wireframe was visible near the player after spawn. User-provided
screenshots confirmed the workflow; the screenshots are not committed to this
repository.

The final `count=0` confirms cleanup; no additional clear command was required.

## Validation Checklist

- [x] Launch uses both exact-value environment gates.
- [x] A disposable world is opened or created.
- [x] Initial status is enabled with count zero.
- [x] First spawn succeeds.
- [x] Cyan wireframe is visible near the player.
- [x] Status reports one probe with a plausible position.
- [x] Duplicate spawn is refused.
- [x] Clear removes exactly one probe.
- [x] Final status is count zero.
- [ ] Wireframe disappears.
- [ ] App exits normally after cleanup.

Record the Pebble commit, macOS version, GPU, world name, and any unexpected
chat output before marking the visual check complete.

## Rollback And Cleanup Checklist

- [ ] Run `/labprobe clear` before leaving the world.
- [ ] Confirm `/labprobe status` reports count zero.
- [ ] Exit Pebble normally.
- [ ] Do not relaunch with either gate for normal gameplay.
- [ ] Delete the disposable world after validation if it has no diagnostic
      value.
- [ ] If the app crashes before clear, reopen only the disposable world and
      verify no probe was restored; do not repeat the test on an important
      save.

## Safety Notes

- Always use a disposable world.
- Always run `/labprobe clear` before exit.
- Do not test on an important save until this workflow has been observed
  successfully.
- `shouldSaveToChunk == false` provides explicit save exclusion, but operational
  caution remains appropriate for an unregistered experimental entity.
- Never enable these environment variables during normal use.

## Remaining Risks

- World replacement, dimension transfer, title exit, and app termination now
  trigger explicit automatic probe cleanup, but those UI transitions are not
  yet covered by automated app navigation tests.
- A crash can prevent the operator from running `/labprobe clear`, although the
  save-exclusion policy prevents chunk serialization.
- The marker has not yet been visually verified across camera distances,
  dimensions, display scales, or GPU families.
- Command behavior is compiled but not covered by an automated UI test.
- Screenshot automation could race world loading or chat focus.

## Next Phase

Recommended: Phase 4.5B, scripted screenshot validation of the existing gated
workflow and hardened cleanup contract in a disposable world.
