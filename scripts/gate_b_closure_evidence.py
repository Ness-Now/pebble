#!/usr/bin/env python3
"""Fail-closed evidence parser for finite-world Gate B closure."""

from __future__ import annotations

import argparse
import json
import re
import tempfile
from pathlib import Path

KV = re.compile(r"([A-Za-z][A-Za-z0-9_]*)=([^\s]+)")


def fields(line: str) -> dict[str, str]:
    return dict(KV.findall(line))


def lines_with(text: str, marker: str) -> list[str]:
    return [line for line in text.splitlines() if marker in line]


def integer(values: dict[str, str], key: str) -> int:
    if key not in values or not re.fullmatch(r"-?[0-9]+", values[key]):
        raise ValueError(f"missing or malformed integer: {key}")
    return int(values[key])


def parse_run(
    log: Path, seed: int, horizon: int, app_exit: int, reactivation: bool = False
) -> dict:
    text = log.read_text(errors="replace")
    required = {
        "snapshot": lines_with(text, "GATE_B3_ACCEPTANCE_SNAPSHOT"),
        "finite": lines_with(text, "GATE_B_FINITE_WORLD"),
        "churn": lines_with(text, "GATE_B_CONVERGENCE_CHURN"),
        "bounds": lines_with(text, "GATE_B_CONVERGENCE_BOUNDS"),
        "marker": lines_with(text, "GATE_B3_HORIZON_COMPLETE"),
    }
    missing = sorted(key for key, values in required.items() if not values)
    result = {
        "schemaVersion": 1,
        "seed": seed,
        "horizon": horizon,
        "appExit": app_exit,
        "classification": "HARNESS_INVALID",
        "gateBResult": "FAIL",
        "primaryFailure": "missing:" + ",".join(missing) if missing else "none",
        "blockingReasons": [],
    }
    if missing:
        return result
    try:
        snapshot = fields(required["snapshot"][-1])
        finite = fields(required["finite"][-1])
        churn = fields(required["churn"][-1])
        bounds = fields(required["bounds"][-1])
        marker = fields(required["marker"][-1])
        result.update(
            ticksReached=integer(marker, "tick"),
            snapshotTick=integer(snapshot, "tick"),
            markerTick=integer(marker, "tick"),
            runtimeErrors=integer(snapshot, "runtimeErrors"),
            manualProductive=integer(snapshot, "manualProductive"),
            movementEnabled=integer(snapshot, "movementEnabled"),
            physicalCompletions=integer(snapshot, "completed"),
            sourcesObserved=integer(finite, "sourcesObserved"),
            sourcesViable=integer(finite, "sourcesViable"),
            sourcesTemporary=integer(finite, "sourcesTemporary"),
            sourcesDepleted=integer(finite, "sourcesDepleted"),
            sourcesWithdrawn=integer(finite, "sourcesWithdrawn"),
            candidatesGenerated=integer(finite, "candidatesGenerated"),
            activitiesActive=integer(finite, "activitiesActive"),
            workExecutable=integer(finite, "workExecutable"),
            cooldownsActive=integer(finite, "cooldownsActive"),
            cooldownsExpired=integer(finite, "cooldownsExpired"),
            finiteWorldState=finite.get("state"),
            contradiction=finite.get("contradiction"),
            domains=finite.get("domains", ""),
            exercisedDomains=snapshot.get("families", ""),
            churnBlocking=integer(churn, "blocking"),
            boundsValid=integer(bounds, "valid"),
        )
    except (ValueError, KeyError) as error:
        result["primaryFailure"] = str(error)
        return result

    failures = []
    if app_exit != 0:
        failures.append(f"app_exit:{app_exit}")
    if not (
        result["ticksReached"] == horizon
        and result["snapshotTick"] == horizon
        and result["markerTick"] == horizon
        and integer(marker, "target") == horizon
        and integer(marker, "exact") == 1
    ):
        failures.append("inexact_horizon")
    if result["runtimeErrors"] != 0:
        failures.append("runtime_errors")
    if result["manualProductive"] != 0:
        failures.append("manual_productive_command")
    if result["movementEnabled"] != 1:
        failures.append("movement_disabled")
    if result["physicalCompletions"] <= 0:
        failures.append("no_autonomous_physical_completion")
    if result["churnBlocking"] != 0:
        failures.append("retry_or_churn_blocking")
    if result["boundsValid"] != 1:
        failures.append("bounds_invalid")
    if result["finiteWorldState"] == "FALSE_QUIESCENCE":
        failures.append(result["contradiction"] or "false_quiescence")
    elif result["finiteWorldState"] == "QUIESCENT_NO_EXECUTABLE_SOURCE":
        if any(
            result[key] != 0
            for key in (
                "sourcesViable",
                "candidatesGenerated",
                "activitiesActive",
                "workExecutable",
                "cooldownsActive",
            )
        ):
            failures.append("incoherent_quiescence")
        result["classification"] = "PASS_FINITE_WORLD_EXHAUSTED"
    elif result["finiteWorldState"] == "PRODUCTIVE":
        if result["candidatesGenerated"] <= 0 and result["activitiesActive"] <= 0:
            failures.append("productive_without_candidate_or_activity")
        result["classification"] = "PASS_PRODUCTIVE_AT_HORIZON"
    else:
        failures.append("unknown_finite_world_state")

    if reactivation:
        injections = lines_with(text, "GATE_B_MATERIAL_REACTIVATION")
        if len(required["finite"]) < 2 or not injections:
            failures.append("missing_reactivation_boundary")
        else:
            before = fields(required["finite"][0])
            injection = fields(injections[-1])
            injection_tick = integer(injection, "tick")
            completions = [
                fields(line)
                for line in lines_with(text, "autonomous activity completed")
            ]
            resumed = [
                value for value in completions
                if integer(value, "tick") > injection_tick
                and value.get("domain") == "wildGathering"
            ]
            result["reactivation"] = {
                "preState": before.get("state"),
                "injectionTick": injection_tick,
                "applied": integer(injection, "applied"),
                "postPhysicalSuccesses": len(resumed),
                "lastSuccessTick": max(
                    [integer(value, "tick") for value in resumed], default=-1
                ),
            }
            if before.get("state") != "QUIESCENT_NO_EXECUTABLE_SOURCE":
                failures.append("reactivation_precondition_not_quiescent")
            if integer(injection, "applied") != 1:
                failures.append("material_reactivation_not_applied")
            if not resumed:
                failures.append("no_autonomous_success_after_reactivation")

    if failures:
        result["classification"] = "FAIL"
        result["primaryFailure"] = failures[0]
        result["blockingReasons"] = failures
        return result
    result["gateBResult"] = "PASS"
    result["primaryFailure"] = "none"
    return result


def self_test() -> None:
    base = "\n".join(
        [
            "[lab-live] GATE_B3_ACCEPTANCE_SNAPSHOT seed=46 tick=800 runtimeErrors=0 manualProductive=0 movementEnabled=1 completed=4 families=agriculture:2,wildSubsistence:2",
            "[lab-live] GATE_B_FINITE_WORLD tick=800 state=QUIESCENT_NO_EXECUTABLE_SOURCE contradiction=none sourcesObserved=8 sourcesViable=0 sourcesTemporary=3 sourcesDepleted=2 sourcesWithdrawn=3 candidatesGenerated=0 activitiesActive=0 workExecutable=0 cooldownsActive=0 cooldownsExpired=2 domains=agriculture:o8v0t3d2w3c0",
            "[lab-live] GATE_B_CONVERGENCE_CHURN tick=800 blocking=0",
            "[lab-live] GATE_B_CONVERGENCE_BOUNDS valid=1",
            "[lab-live] GATE_B3_HORIZON_COMPLETE seed=46 tick=800 target=800 exact=1",
        ]
    )
    with tempfile.TemporaryDirectory() as directory:
        path = Path(directory) / "log"
        path.write_text(base + "\n")
        good = parse_run(path, 46, 800, 0)
        assert good["classification"] == "PASS_FINITE_WORLD_EXHAUSTED"
        false = base.replace(
            "sourcesViable=0", "sourcesViable=1"
        ).replace(
            "state=QUIESCENT_NO_EXECUTABLE_SOURCE", "state=FALSE_QUIESCENCE"
        )
        path.write_text(false + "\n")
        assert parse_run(path, 46, 800, 0)["classification"] == "FAIL"
        path.write_text(base.replace(" exact=1", " exact=0") + "\n")
        assert parse_run(path, 46, 800, 0)["classification"] == "FAIL"
        path.write_text(base.splitlines()[0] + "\n")
        assert parse_run(path, 46, 800, 0)["classification"] == "HARNESS_INVALID"
    print("gate_b_closure_evidence self-test: PASS")


def main() -> None:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("self-test")
    run = subparsers.add_parser("run")
    run.add_argument("--log", type=Path, required=True)
    run.add_argument("--seed", type=int, required=True)
    run.add_argument("--horizon", type=int, required=True)
    run.add_argument("--app-exit", type=int, required=True)
    run.add_argument("--output", type=Path, required=True)
    run.add_argument("--reactivation", action="store_true")
    arguments = parser.parse_args()
    if arguments.command == "self-test":
        self_test()
        return
    value = parse_run(
        arguments.log,
        arguments.seed,
        arguments.horizon,
        arguments.app_exit,
        arguments.reactivation,
    )
    arguments.output.write_text(
        json.dumps(value, indent=2, sort_keys=True) + "\n"
    )
    print(value["classification"])


if __name__ == "__main__":
    main()
