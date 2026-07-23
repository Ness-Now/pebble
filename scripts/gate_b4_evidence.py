#!/usr/bin/env python3
"""Parse Gate B re-evaluation #4 traces into bounded HEAD-bound evidence."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path


FIXED = {
    "short": [(46, 800), (71, 800), (113, 800), (197, 800), (337, 800)],
    "medium": [(509, 4800), (887, 4800), (1597, 4800)],
    "stress": [(2593, 6400), (4099, 6400)],
}


def digest(text: str) -> str:
    return hashlib.sha256(text.encode()).hexdigest()


def tokens(line: str) -> dict[str, str]:
    return dict(re.findall(r"([A-Za-z][A-Za-z0-9]*)=([^ ]+)", line))


def last_line(lines: list[str], marker: str) -> str:
    return next((line for line in reversed(lines) if marker in line), "")


def run_result(args: argparse.Namespace) -> None:
    text = Path(args.log).read_text(errors="replace")
    lines = text.splitlines()
    snapshot_line = last_line(lines, "GATE_B3_ACCEPTANCE_SNAPSHOT")
    snapshot = tokens(snapshot_line)
    horizon_line = last_line(lines, "GATE_B3_HORIZON_COMPLETE")
    horizon = tokens(horizon_line)
    fatal_line = last_line(lines, "GATE_B3_FATAL_INVARIANT")
    fatal = tokens(fatal_line)
    distance_line = last_line(lines, "GATE_B4_DISTANCE_FROM_HOME_FAILURE")
    distance_failure = tokens(distance_line)
    start_line = last_line(lines, "[lab-live] start seed=")
    bootstrap_lines = [
        line for line in lines
        if "passive composite bootstrap" in line
        or "GATE_B_BOOTSTRAP_COMPLETE" in line
        or "PLAYABLE_SLICE_BOOTSTRAP_COMPLETE" in line
        or "GATE_B3_RANDOM_TICKS" in line
    ]
    errors = [
        line.split("[lab-live] error ", 1)[-1]
        for line in lines if line.startswith("[lab-live] error ")
    ]
    unique_errors = list(dict.fromkeys(errors))
    exact = horizon.get("exact") == "1"
    bootstrap = any("GATE_B_BOOTSTRAP_COMPLETE" in line for line in lines)
    ticks = int(
        horizon.get("tick")
        or fatal.get("tick")
        or snapshot.get("tick")
        or tokens(last_line(lines, "summary reason=")).get("ticks")
        or 0
    )
    runtime_errors = int(snapshot.get("runtimeErrors", len(errors)) or 0)
    bootstrap_index = next(
        (index for index, line in enumerate(lines) if "GATE_B_BOOTSTRAP_COMPLETE" in line),
        None,
    )
    post_bootstrap_lines = lines[bootstrap_index + 1:] if bootstrap_index is not None else []
    movement_disable_after_bootstrap = any(
        "[lab-live] movement=off " in line for line in post_bootstrap_lines
    )
    last_transition_line = last_line(lines, "tick=")
    last_physical_line = last_line(lines, "autonomous activity completed actor=")
    if distance_failure:
        primary = "distance_from_home_feedback_boundary"
    elif fatal.get("reason"):
        primary = fatal["reason"]
    elif errors:
        primary = re.sub(r"[^A-Za-z0-9_.-]+", "_", unique_errors[0]).strip("_")
    elif not bootstrap:
        primary = "bootstrap_not_completed"
    elif not exact:
        primary = "fixed_horizon_not_completed"
    else:
        primary = "none"
    passed = (
        args.app_exit == 0 and bootstrap and exact
        and ticks == args.horizon and runtime_errors == 0 and not errors
    )
    domains: dict[str, int] = {}
    actions: dict[str, int] = {}
    for line in lines:
        if "autonomous activity completed actor=" not in line:
            continue
        values = tokens(line)
        domain = values.get("domain", "unknown")
        action = values.get("action", "unknown")
        domains[domain] = domains.get(domain, 0) + 1
        actions[action] = actions.get(action, 0) + 1
    semantic_lines = [
        line for line in lines
        if line.startswith("[lab-live] ")
        and not any(value in line for value in (
            "worldTick=", "GATE_B3_RENDER_", "summary reason=termination",
        ))
    ]
    result = {
        "schemaVersion": 2,
        "head": args.head,
        "seed": args.seed,
        "tier": args.tier,
        "label": args.label,
        "horizon": args.horizon,
        "configurationDigest": args.configuration_digest,
        "bootstrapDigest": digest("\n".join(bootstrap_lines)),
        "startSemanticDigest": digest(start_line),
        "finalSemanticDigest": snapshot.get("digest", digest("\n".join(semantic_lines))),
        "traceSemanticDigest": digest("\n".join(semantic_lines)),
        "attempted": True,
        "bootstrapComplete": bootstrap,
        "ticksReached": ticks,
        "horizonComplete": exact and ticks == args.horizon,
        "appExit": args.app_exit,
        "elapsedSeconds": args.elapsed_seconds,
        "manualProductiveCommands": int(snapshot.get("manualProductive", 0) or 0),
        "runtimeErrors": runtime_errors,
        "errorCount": len(errors),
        "uniqueErrors": unique_errors[:20],
        "fatalInvariant": fatal.get("reason"),
        "failureWorldTick": int(fatal.get("worldTick", 0) or 0),
        "distanceFromHomeFailure": distance_failure or None,
        "movementPolicy": {
            "enabledAtFinalSnapshot": snapshot.get("movementEnabled") == "1",
            "everEnabled": snapshot.get("movementEverEnabled") == "1",
            "disabledAfterBootstrap": movement_disable_after_bootstrap,
            "bypassUsed": False,
            "operations": int(snapshot.get("movementOperations", 0) or 0),
            "blocked": int(snapshot.get("movementBlocks", 0) or 0),
            "maximumAcceptedDistanceFromHome": int(
                snapshot.get("maxDistanceHome", 0) or 0
            ),
        },
        "lastSuccessfulCognitiveTick": int(
            snapshot.get("successfulCognitiveTicks", 0) or 0
        ),
        "lastPhysicalAction": last_physical_line or None,
        "lastTransitionTrace": last_transition_line or None,
        "activityFamilies": domains,
        "actions": actions,
        "snapshot": snapshot,
        "checkpointAttempted": any("GATE_B3_CHECKPOINT_BOUNDARY" in line for line in lines),
        "checkpointSaved": any("checkpoint saved name=gate-b3-887-mid" in line for line in lines),
        "checkpointLoaded": any("checkpoint loaded name=gate-b3-887-mid" in line for line in lines),
        "shockAttempted": any("GATE_B3_SHOCK" in line for line in lines),
        "primaryFailure": primary,
        "result": "PASS" if passed else "FAIL",
    }
    Path(args.output).write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")


def passive_result(args: argparse.Namespace) -> None:
    text = Path(args.log).read_text(errors="replace")
    lines = text.splitlines()
    complete_line = last_line(lines, "GATE_B3_PASSIVE_WALL_COMPLETE")
    complete = tokens(complete_line)
    snapshot = tokens(last_line(lines, "GATE_B3_ACCEPTANCE_SNAPSHOT"))
    coexistence = tokens(last_line(lines, "player coexistence result"))
    render = tokens(last_line(lines, "GATE_B3_RENDER_COHERENCE"))
    fatal = tokens(last_line(lines, "GATE_B3_FATAL_INVARIANT"))
    distance_failure = tokens(last_line(lines, "GATE_B4_DISTANCE_FROM_HOME_FAILURE"))
    captures = sorted(
        path.name for path in Path(args.capture_directory).glob("gate-b4-*.png")
        if path.stat().st_size > 0
    )
    elapsed = float(complete.get("elapsedSeconds", 0) or 0)
    runtime_errors = int(snapshot.get("runtimeErrors", 0) or 0)
    bootstrap = any("PLAYABLE_SLICE_BOOTSTRAP_COMPLETE" in line for line in lines)
    movement = coexistence.get("passed") == "1"
    completed = int(snapshot.get("completed", 0) or 0)
    families = tokens(last_line(lines, "autonomous summary bootstrap=")).get("families", "")
    passed = (
        args.app_exit == 0 and bootstrap and elapsed >= 300
        and movement and runtime_errors == 0 and completed > 0
        and len(captures) >= 6
    )
    primary = "none"
    if not bootstrap:
        primary = "bootstrap_not_completed"
    elif elapsed < 300:
        primary = "five_minute_wall_duration_not_completed"
    elif runtime_errors:
        primary = "runtime_errors_during_passive_slice"
    elif not movement:
        primary = "player_control_coexistence_not_proven"
    elif completed == 0:
        primary = "no_continuing_autonomous_completions"
    result = {
        "schemaVersion": 2,
        "head": args.head,
        "world": "PebbleLab-Disposable-GateB-Reevaluation4-46",
        "seed": 46,
        "targetWallSeconds": 300,
        "measuredWallSeconds": elapsed,
        "processElapsedSeconds": args.elapsed_seconds,
        "appExit": args.app_exit,
        "bootstrapComplete": bootstrap,
        "simulationTick": int(complete.get("simulationTick", snapshot.get("tick", 0)) or 0),
        "worldTick": int(complete.get("worldTick", 0) or 0),
        "runtimeErrors": runtime_errors,
        "manualProductiveCommands": int(snapshot.get("manualProductive", 0) or 0),
        "playerControlCoexistence": movement,
        "playerCoexistence": coexistence,
        "renderCoherence": render,
        "fatalInvariant": fatal or None,
        "distanceFromHomeFailure": distance_failure or None,
        "captures": captures,
        "activityFamilies": families,
        "primaryFailure": primary,
        "result": "PASS" if passed else "FAIL",
    }
    Path(args.output).write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")


def aggregate(args: argparse.Namespace) -> None:
    root = Path(args.root)
    runs: list[dict] = []
    for tier, values in FIXED.items():
        for seed, _ in values:
            path = root / tier / str(seed) / "result.json"
            if path.exists():
                runs.append(json.loads(path.read_text()))
            else:
                runs.append({
                    "head": args.head, "seed": seed, "tier": tier,
                    "attempted": False, "horizonComplete": False,
                    "result": "FAIL", "primaryFailure": "not_executed",
                })
    repeat_path = root / "determinism" / "509-repeat" / "result.json"
    repeat = json.loads(repeat_path.read_text()) if repeat_path.exists() else None
    primary_509 = next((run for run in runs if run["seed"] == 509), None)
    deterministic = bool(
        repeat and primary_509
        and repeat["horizonComplete"] and primary_509["horizonComplete"]
        and repeat["traceSemanticDigest"] == primary_509["traceSemanticDigest"]
    )
    deterministic_failure = bool(
        repeat and primary_509
        and repeat.get("ticksReached") == primary_509.get("ticksReached")
        and repeat.get("primaryFailure") == primary_509.get("primaryFailure")
        and repeat.get("finalSemanticDigest") == primary_509.get("finalSemanticDigest")
    )
    checkpoint = next((run for run in runs if run["seed"] == 887), None)
    checkpoint_pass = bool(
        checkpoint and checkpoint.get("checkpointAttempted")
        and checkpoint.get("checkpointSaved") and checkpoint.get("checkpointLoaded")
        and checkpoint.get("horizonComplete")
    )
    passive_path = root / "passive" / "result.json"
    passive = json.loads(passive_path.read_text()) if passive_path.exists() else None
    full_gate_text = (root / "full-gate.log").read_text(errors="replace") \
        if (root / "full-gate.log").exists() else ""
    full_gate = "35/35" in full_gate_text and re.search(r"\b3187 passed, 0 failed\b", full_gate_text)
    focused_path = root / "focused" / "results.tsv"
    focused_pass = False
    focused: list[dict] = []
    if focused_path.exists():
        for line in focused_path.read_text().splitlines():
            selector, passed, failed, exit_code = line.split("\t")
            focused.append({
                "selector": selector, "passed": int(passed),
                "failed": int(failed), "exit": int(exit_code),
            })
        focused_pass = len(focused) == 13 and all(
            item["failed"] == 0 and item["exit"] == 0 for item in focused
        )
    failures = [
        {
            "seed": run["seed"], "tier": run["tier"],
            "tick": run.get("ticksReached", 0),
            "worldTick": run.get("failureWorldTick", 0),
            "criterion": run["primaryFailure"],
            "classification": "INTEGRATION BUG",
            "distanceFromHome": run.get("distanceFromHomeFailure"),
        }
        for run in runs if run["result"] == "FAIL"
    ]
    pillars = {
        "B1": "FAIL", "B2": "FAIL", "B3": "FAIL", "B4": "FAIL",
        "B5": "FAIL", "B6": "FAIL", "B7": "FAIL", "B8": "FAIL",
        "B9": "FAIL", "B10": "FAIL", "B11": "FAIL", "B12": "FAIL",
    }
    all_attempted = all(run.get("attempted") for run in runs)
    all_horizons = all(run.get("horizonComplete") for run in runs)
    candidate = (
        all(value == "PASS" for value in pillars.values())
        and all_attempted and all_horizons and deterministic and checkpoint_pass
        and passive is not None and passive["result"] == "PASS"
        and focused_pass and bool(full_gate)
    )
    summary = {
        "schemaVersion": 4,
        "evaluation": "Gate B Re-evaluation #4",
        "head": args.head,
        "configurationDigest": args.configuration_digest,
        "candidateResult": "PASS" if candidate else "FAIL",
        "allFixedSeedsAttempted": all_attempted,
        "allFixedHorizonsCompleted": all_horizons,
        "rerolls": 0,
        "runs": runs,
        "seed509Repeat": {
            "executed": repeat is not None,
            "semanticEquality": deterministic,
            "failureReproducedDeterministically": deterministic_failure,
            "result": "PASS" if deterministic else "FAIL",
        },
        "seed887CheckpointReconciliation": {
            "attempted": bool(checkpoint and checkpoint.get("checkpointAttempted")),
            "saved": bool(checkpoint and checkpoint.get("checkpointSaved")),
            "loaded": bool(checkpoint and checkpoint.get("checkpointLoaded")),
            "result": "PASS" if checkpoint_pass else "FAIL",
        },
        "passive": passive,
        "focused": focused,
        "focusedResult": "PASS" if focused_pass else "FAIL",
        "fullCanonicalGate": {
            "baseline": 3187,
            "new": 0,
            "removed": 0,
            "expected": "35/35; 3187 passed, 0 failed",
            "result": "PASS" if full_gate else "FAIL",
        },
        "pillars": pillars,
        "pillarEvidence": {
            "B1": "FAIL: campaign terminated before a horizon-complete society ledger",
            "B2": "FAIL: real adult food closure occurred, but required long-horizon and dependent contexts did not complete",
            "B3": "FAIL: agriculture, livestock, fishing and gathering occurred before the systemic failure, but no horizon completed",
            "B4": "FAIL: till occurred; no integrated Core-grown harvest cycle completed",
            "B5": "FAIL: real feed occurred; resource-bounded continuity and product/breeding were not established",
            "B6": "FAIL: no required medium plus stress care chain completed",
            "B7": "FAIL: apprenticeship and demonstrations appeared, but own-practice integrated closure was not established to horizon",
            "B8": "FAIL: Work refresh did not regress, but systemic movement/home failure prevented durable horizon evidence",
            "B9": "FAIL: both subtractive shock boundaries were unreachable",
            "B10": "FAIL: local/zero-ghost evidence exists before failure, but stale adaptation and full campaign coverage did not complete",
            "B11": "FAIL: fixed horizons, final determinism and checkpoint/reconciliation did not complete",
            "B12": "FAIL: the five-minute continuing passive society requirement did not complete",
        },
        "hardFailures": failures,
        "systemicFailure": {
            "id": "B-BLOCKER-MOVEMENT-HOME-BOUNDARY",
            "classification": "INTEGRATION BUG",
            "criterion": "distance_from_home_feedback_boundary",
            "affectedFixedSeeds": [
                run["seed"] for run in runs
                if run.get("primaryFailure") == "distance_from_home_feedback_boundary"
            ],
            "behaviorAlteringWorkaroundUsed": False,
            "distanceFromHomeBypassUsed": False,
        },
        "gateR": "ACQUIRED",
        "gateBCanonicallyAcquired": False,
        "civ26Started": False,
        "productQuestion": "NO",
    }
    Path(args.output).write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n")


def parser() -> argparse.ArgumentParser:
    top = argparse.ArgumentParser()
    sub = top.add_subparsers(dest="command", required=True)
    run = sub.add_parser("run")
    run.add_argument("--head", required=True)
    run.add_argument("--seed", type=int, required=True)
    run.add_argument("--tier", required=True)
    run.add_argument("--horizon", type=int, required=True)
    run.add_argument("--label", required=True)
    run.add_argument("--configuration-digest", required=True)
    run.add_argument("--elapsed-seconds", type=int, required=True)
    run.add_argument("--app-exit", type=int, required=True)
    run.add_argument("--log", required=True)
    run.add_argument("--output", required=True)
    passive = sub.add_parser("passive")
    passive.add_argument("--head", required=True)
    passive.add_argument("--elapsed-seconds", type=int, required=True)
    passive.add_argument("--app-exit", type=int, required=True)
    passive.add_argument("--log", required=True)
    passive.add_argument("--capture-directory", required=True)
    passive.add_argument("--output", required=True)
    aggregate_parser = sub.add_parser("aggregate")
    aggregate_parser.add_argument("--head", required=True)
    aggregate_parser.add_argument("--root", required=True)
    aggregate_parser.add_argument("--configuration-digest", required=True)
    aggregate_parser.add_argument("--output", required=True)
    return top


if __name__ == "__main__":
    arguments = parser().parse_args()
    if arguments.command == "run":
        run_result(arguments)
    elif arguments.command == "passive":
        passive_result(arguments)
    else:
        aggregate(arguments)
