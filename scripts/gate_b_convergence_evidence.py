#!/usr/bin/env python3
"""HEAD-bound evidence parser for GATE-B-CONVERGENCE-01.

This parser never grants Gate B. It validates progressive integration probes
and emits only readiness (or non-readiness) for a later official re-evaluation.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import struct
import tempfile
import zlib
from pathlib import Path
from typing import Any


FIXED_SEEDS = [46, 71, 113, 197, 337, 509, 887, 1597, 2593, 4099]
MEDIUM_SEEDS = [509, 887, 1597]
STRESS_SEEDS = [2593, 4099]
STRESS_KINDS = {2593: "worker-care", 4099: "tool-feed"}
REQUIRED_BLOCKERS = {
    "B-BLOCKER-ACCEPTANCE-BOOTSTRAP-ROLE-ASSIGNMENT",
    "B-BLOCKER-MOVEMENT-HOME-BOUNDARY",
    "B-BLOCKER-AUTONOMOUS-LIVESTOCK-INITIATION",
    "B-BLOCKER-CHECKPOINT-PHYSICAL-CUSTODY",
}
HARNESS_BLOCKERS = {
    "B-BLOCKER-ACCEPTANCE-BOOTSTRAP-ROLE-ASSIGNMENT",
}
KNOWN_ACTIVITY_FAMILIES = {
    "agriculture",
    "fishing",
    "hunting",
    "wildGathering",
    "livestock",
    "dependentCare",
    "teaching",
    "construction",
    "materialHandling",
}
WILD_ACTIVITY_DOMAINS = {"fishing", "hunting", "wildGathering"}
REQUIRED_SELECTORS = {
    "bounded-autonomous-navigation",
    "role-neutral-society-bootstrap",
    "autonomous-civilization",
    "embodiment",
    "work-demand-refresh",
    "work-professions",
    "agriculture",
    "wild-subsistence",
    "livestock",
    "dependent-care",
    "integrated-teaching-initiation",
    "teaching",
    "physical-food-survival",
    "checkpoint-replay",
    "skills",
    "materials",
    "ecological-observation",
}
ROLE_FIELDS = [
    "assignedPlanner",
    "assignedLivestockWorkers",
    "assignedWildWorker",
    "prequeuedProductiveTasks",
    "prestartedAgriculturePlans",
    "prestartedApprenticeships",
    "preloadedSkills",
    "preloadedProfessions",
]
LIVE_CAPTURES = [
    "convergence-start.png",
    "convergence-role-neutral-emergence.png",
    "convergence-after-previous-home-boundary.png",
    "convergence-multi-agent.png",
    "convergence-late.png",
]
SEMANTIC_DIGEST_FIELDS = {
    "semanticDigest",
    "worldEntityDigest",
    "durable",
    "population",
    "positionsHome",
    "activities",
    "materialCustody",
    "food",
    "agriculture",
    "livestock",
    "care",
    "teaching",
    "work",
    "skills",
    "causal",
}
SEMANTIC_INTEGER_FIELDS = {
    "tick",
    "agentCount",
    "alive",
    "causalSequence",
    "worldEntities",
}
CHURN_FIELDS = {
    "tick",
    "starts",
    "completed",
    "blocked",
    "stale",
    "interrupted",
    "superseded",
    "sameCandidateRestarts",
    "sameTargetRestarts",
    "continuations",
    "crossFamilySwitches",
    "maxLifetime",
    "sameObservedFailureRun",
    "sameObservedFailureSpan",
    "blocking",
}
RESULT_STATES = {
    "PASS",
    "FAIL",
    "NOT_RUN",
    "NOT_REACHED",
    "HARNESS_INVALID",
    "TIMEOUT",
}
GATE_R_CHECKS = {
    "coreUnchanged",
    "singleAgentKernel",
    "noSecondPathfinder",
    "noSecondInventory",
    "noSecondFarming",
    "noSecondLivestock",
    "noTeachingScheduler",
    "noWorkScheduler",
    "noGlobalResourceOracle",
    "noGateBRuntimeAuthority",
}
MOVEMENT_AUDIT_CHECKS = {
    "coreEntityMoveAuthority",
    "noAgentSetPosOrTeleport",
    "noAcceptanceBypass",
    "movementEnabledEvidence",
    "trueExplorationBoundary",
    "localWaypointContract",
    "rollbackPreserved",
}
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
HEX_SHA256 = re.compile(r"^[0-9a-f]{64}$")


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def canonical_activity_family(domain: str) -> str:
    if domain in WILD_ACTIVITY_DOMAINS:
        return "wildSubsistence"
    if domain == "dependentCare":
        return "care"
    if domain in {"construction", "materialHandling"}:
        return "materialWork"
    return domain


def inspect_png(data: bytes) -> dict[str, Any]:
    evidence: dict[str, Any] = {
        "pngSignature": data.startswith(PNG_SIGNATURE),
        "structureValid": False,
        "width": 0,
        "height": 0,
        "chunkCount": 0,
        "idatBytes": 0,
    }
    if not evidence["pngSignature"]:
        return evidence
    offset = len(PNG_SIGNATURE)
    chunk_count = 0
    saw_ihdr = False
    saw_iend = False
    try:
        while offset < len(data):
            if offset + 12 > len(data):
                return evidence
            length = struct.unpack(">I", data[offset:offset + 4])[0]
            chunk_type = data[offset + 4:offset + 8]
            chunk_end = offset + 12 + length
            if chunk_end > len(data):
                return evidence
            chunk_data = data[offset + 8:offset + 8 + length]
            expected_crc = struct.unpack(
                ">I", data[offset + 8 + length:chunk_end]
            )[0]
            if zlib.crc32(chunk_type + chunk_data) & 0xFFFFFFFF != expected_crc:
                return evidence
            chunk_count += 1
            if chunk_count == 1:
                if chunk_type != b"IHDR" or length != 13:
                    return evidence
                width, height = struct.unpack(">II", chunk_data[:8])
                if width <= 0 or height <= 0:
                    return evidence
                evidence["width"] = width
                evidence["height"] = height
                saw_ihdr = True
            elif chunk_type == b"IHDR":
                return evidence
            if chunk_type == b"IDAT":
                evidence["idatBytes"] += length
            if chunk_type == b"IEND":
                if length != 0 or chunk_end != len(data):
                    return evidence
                saw_iend = True
                offset = chunk_end
                break
            offset = chunk_end
    except (ValueError, struct.error):
        return evidence
    evidence["chunkCount"] = chunk_count
    evidence["structureValid"] = (
        saw_ihdr
        and saw_iend
        and evidence["idatBytes"] > 0
        and offset == len(data)
    )
    return evidence


def write_json(path: Path, value: dict[str, Any]) -> None:
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n")
    temporary.replace(path)


def tokens(line: str) -> dict[str, str]:
    return dict(re.findall(r"([A-Za-z][A-Za-z0-9]*)=([^ ]+)", line))


def last_line(lines: list[str], marker: str) -> str:
    return next((line for line in reversed(lines) if marker in line), "")


def integer(value: Any, default: int = 0) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return default


def decimal(value: Any, default: float = 0.0) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def marker_lines(lines: list[str], marker: str) -> list[str]:
    return [line for line in lines if marker in line]


def marker_values(lines: list[str], marker: str) -> tuple[dict[str, str], int]:
    matches = marker_lines(lines, marker)
    return (tokens(matches[-1]) if matches else {}, len(matches))


def exact_marker_values(
    lines: list[str], marker: str
) -> tuple[dict[str, str], int]:
    expression = re.compile(re.escape(marker) + r"(?: |$)")
    matches = [line for line in lines if expression.search(line)]
    return (tokens(matches[-1]) if matches else {}, len(matches))


def classified_result(
    checks: dict[str, bool],
    *,
    timeout: bool = False,
    harness_invalid: bool = False,
    reached: bool = True,
) -> str:
    if timeout:
        return "TIMEOUT"
    if harness_invalid:
        return "HARNESS_INVALID"
    if not reached:
        return "NOT_REACHED"
    return "PASS" if checks and all(checks.values()) else "FAIL"


def exact_result(
    root: Path,
    directory: str,
    label: str,
    *,
    head: str,
    configuration_digest: str | None = None,
    seed: int | None = None,
    horizon: int | None = None,
    wave: str | None = None,
    live: bool = False,
) -> dict[str, Any]:
    """Load one credit result without silently selecting a later retry.

    A credit label owns exactly one `attempt-0001` directory. Any retry,
    missing trace, stale result, or metadata mismatch turns the returned
    record into a failed evidence record.
    """

    label_root = root / directory / label
    attempts = sorted(
        path for path in label_root.glob("attempt-*") if path.is_dir()
    )
    integrity: dict[str, Any] = {
        "attemptCount": len(attempts),
        "attemptNames": [path.name for path in attempts],
        "exactlyOneAttempt": (
            len(attempts) == 1 and attempts[0].name == "attempt-0001"
        ),
        "resultPresent": False,
        "logPresent": False,
        "logSHA256Matches": False,
        "logSnapshotMatchesTrace": False,
        "semanticStateMatchesTrace": False,
        "headMatches": False,
        "missionMatches": False,
        "schemaMatches": False,
        "configurationMatches": configuration_digest is None,
        "seedMatches": seed is None,
        "horizonMatches": horizon is None,
        "waveMatches": wave is None,
        "gateBRemainsUnacquired": False,
        "civ26RemainsUnstarted": False,
    }
    value: dict[str, Any] = {
        "head": None,
        "seed": seed,
        "wave": wave or directory,
        "convergenceResult": "NOT_RUN",
        "result": "NOT_RUN",
        "primaryFailure": "evidence_not_run",
    }
    if not integrity["exactlyOneAttempt"]:
        state = "NOT_RUN" if not attempts else "HARNESS_INVALID"
        value["convergenceResult"] = state
        value["result"] = state
        value["primaryFailure"] = (
            "evidence_not_run" if not attempts else "evidence_attempt_count"
        )
        value["evidenceIntegrity"] = integrity
        return value

    attempt = attempts[0]
    result_path = attempt / "result.json"
    log_path = attempt / "pebble-live.log"
    integrity["resultPresent"] = result_path.is_file()
    integrity["logPresent"] = log_path.is_file()
    if not result_path.is_file():
        value["convergenceResult"] = "HARNESS_INVALID"
        value["result"] = "HARNESS_INVALID"
        value["primaryFailure"] = "evidence_result_missing"
        value["evidenceIntegrity"] = integrity
        return value
    try:
        loaded = json.loads(result_path.read_text())
        if not isinstance(loaded, dict):
            raise ValueError("result root is not an object")
        value = loaded
    except (OSError, ValueError, json.JSONDecodeError) as error:
        value["convergenceResult"] = "HARNESS_INVALID"
        value["result"] = "HARNESS_INVALID"
        value["primaryFailure"] = f"evidence_result_invalid:{type(error).__name__}"
        value["evidenceIntegrity"] = integrity
        return value

    integrity["headMatches"] = value.get("head") == head
    integrity["missionMatches"] = value.get("mission") == "GATE-B-CONVERGENCE-01"
    integrity["schemaMatches"] = value.get("schemaVersion") == (3 if live else 5)
    integrity["resultStateValid"] = (
        value.get("result", value.get("convergenceResult")) in RESULT_STATES
        and value.get("convergenceResult", value.get("result")) in RESULT_STATES
    )
    integrity["gateBRemainsUnacquired"] = (
        value.get("gateBCanonicallyAcquired") is False
    )
    integrity["civ26RemainsUnstarted"] = value.get("civ26Started") is False
    if configuration_digest is not None:
        integrity["configurationMatches"] = (
            value.get("configurationDigest") == configuration_digest
        )
    log_snapshot = value.get("logSnapshot", {})
    if not isinstance(log_snapshot, dict):
        log_snapshot = {}
    if seed is not None:
        integrity["seedMatches"] = value.get("seed") == seed
        integrity["logSnapshotSeedMatches"] = (
            integer(log_snapshot.get("seed"), -1) == seed
        )
    if horizon is not None:
        integrity["horizonMatches"] = value.get("horizon") == horizon
        integrity["logSnapshotTickMatches"] = (
            integer(log_snapshot.get("tick"), -1) == horizon
        )
    if wave is not None:
        integrity["waveMatches"] = value.get("wave") == wave
    if log_path.is_file():
        log_raw = log_path.read_bytes()
        log_lines = log_raw.decode(errors="replace").splitlines()
        trace_snapshot, trace_snapshot_count = marker_values(
            log_lines, "GATE_B3_ACCEPTANCE_SNAPSHOT"
        )
        trace_semantic, trace_semantic_count = marker_values(
            log_lines, "GATE_B_CONVERGENCE_SEMANTIC"
        )
        integrity["logSHA256Matches"] = (
            value.get("logSHA256") == sha256_bytes(log_raw)
        )
        integrity["logSnapshotMatchesTrace"] = (
            trace_snapshot_count == 1 and log_snapshot == trace_snapshot
        )
        integrity["semanticStateMatchesTrace"] = (
            trace_semantic_count == 1
            and value.get("semanticState") == trace_semantic
        )

    valid = all(
        check is True for key, check in integrity.items()
        if key not in {"attemptCount", "attemptNames"}
    )
    integrity["valid"] = valid
    value["evidenceIntegrity"] = integrity
    if not valid:
        value["convergenceResult"] = "HARNESS_INVALID"
        value["result"] = "HARNESS_INVALID"
        value["primaryFailure"] = "evidence_integrity"
    elif live and value.get("result") != "PASS":
        value["primaryFailure"] = value.get("primaryFailure", "live_failed")
    return value


def exact_labels(root: Path, directory: str, expected: set[str]) -> bool:
    wave_root = root / directory
    actual = {
        path.name for path in wave_root.iterdir() if path.is_dir()
    } if wave_root.is_dir() else set()
    return actual == expected


def load_audit_proof(
    path: Path,
    *,
    head: str,
    required_checks: set[str],
) -> tuple[dict[str, Any], bool]:
    try:
        value = json.loads(path.read_text())
    except (OSError, ValueError, json.JSONDecodeError) as error:
        return ({
            "path": str(path),
            "result": "UNPROVEN",
            "reason": type(error).__name__,
        }, False)
    if not isinstance(value, dict):
        return ({
            "path": str(path),
            "result": "UNPROVEN",
            "reason": "root_not_object",
        }, False)
    checks = value.get("checks", {})
    commands = value.get("commands", [])
    valid = (
        value.get("head") == head
        and value.get("result") == "PASS"
        and isinstance(checks, dict)
        and required_checks.issubset(checks)
        and all(checks.get(key) is True for key in required_checks)
        and all(check is True for check in checks.values())
        and isinstance(commands, list)
        and bool(commands)
        and all(
            isinstance(command, dict)
            and isinstance(command.get("command"), str)
            and bool(command["command"].strip())
            and command.get("exit") == 0
            for command in commands
        )
    )
    return ({
        "path": str(path),
        "head": value.get("head"),
        "result": value.get("result"),
        "checks": checks,
        "commands": commands,
        "valid": valid,
    }, valid)


def bootstrap_audit(lines: list[str]) -> dict[str, Any]:
    bootstrap_lines = marker_lines(lines, "passive composite bootstrap")
    values = tokens(bootstrap_lines[-1]) if bootstrap_lines else {}
    counters = {field: integer(values.get(field), -1) for field in ROLE_FIELDS}
    agent_count = integer(values.get("agents"), -1)
    starter_kit_count = integer(values.get("starterKits"), -1)
    kit_quantities = {
        "hoe": integer(values.get("kitHoe"), -1),
        "seeds": integer(values.get("kitSeeds"), -1),
        "wheat": integer(values.get("kitWheat"), -1),
        "fishingRod": integer(values.get("kitFishingRod"), -1),
        "shears": integer(values.get("kitShears"), -1),
    }
    return {
        **counters,
        "markerCount": len(bootstrap_lines),
        "agentCount": agent_count,
        "starterKitCount": starter_kit_count,
        "kitQuantities": kit_quantities,
        "productiveCommandsAtBootstrap": integer(
            values.get("commandsProductive"), -1
        ),
        "identicalBoundedPhysicalKits": (
            values.get("custody") == "physical_identical_bounded"
            and agent_count >= 3
            and starter_kit_count == agent_count
            and kit_quantities == {
                "hoe": 1,
                "seeds": 4,
                "wheat": 3,
                "fishingRod": 1,
                "shears": 1,
            }
        ),
        "allAssignmentsZero": all(value == 0 for value in counters.values()),
        "productiveCommandsZero": values.get("commandsProductive") == "0",
    }


def completion_tick(line: str) -> int:
    values = tokens(line)
    if "tick" in values:
        return integer(values["tick"])
    receipt = values.get("receipt", "")
    match = re.search(r":([0-9]+)(?::|$)", receipt)
    return integer(match.group(1)) if match else 0


def parse_semantic(
    lines: list[str], expected_tick: int
) -> tuple[dict[str, str], dict[str, Any]]:
    values, count = marker_values(lines, "GATE_B_CONVERGENCE_SEMANTIC")
    required = SEMANTIC_DIGEST_FIELDS | SEMANTIC_INTEGER_FIELDS
    integers = {
        field: integer(values.get(field), -1)
        for field in SEMANTIC_INTEGER_FIELDS
    }
    checks = {
        "markerExactlyOnce": count == 1,
        "allRequiredKeysPresent": required.issubset(values),
        "allStateDigestsAreSHA256": all(
            HEX_SHA256.fullmatch(values.get(field, "")) is not None
            for field in SEMANTIC_DIGEST_FIELDS
        ),
        "integerFieldsNonnegative": all(value >= 0 for value in integers.values()),
        "tickMatches": integers["tick"] == expected_tick,
        "populationCoherent": (
            integers["agentCount"] >= 1
            and 0 <= integers["alive"] <= integers["agentCount"]
        ),
        "worldEntityCountCoherent": (
            integers["worldEntities"] >= integers["agentCount"]
        ),
    }
    return values, {
        "markerCount": count,
        "requiredKeys": sorted(required),
        "checks": checks,
        "valid": all(checks.values()),
    }


def parse_churn(
    lines: list[str], snapshot: dict[str, Any]
) -> tuple[dict[str, str], dict[str, Any]]:
    values, count = marker_values(lines, "GATE_B_CONVERGENCE_CHURN")
    parsed = {field: integer(values.get(field), -1) for field in CHURN_FIELDS}
    checks = {
        "markerExactlyOnce": count == 1,
        "allRequiredKeysPresent": CHURN_FIELDS.issubset(values),
        "allCountersNonnegative": all(value >= 0 for value in parsed.values()),
        "snapshotTickMatch": parsed["tick"] == integer(snapshot.get("tick"), -2),
        "snapshotStartsMatch": parsed["starts"] == integer(snapshot.get("starts"), -2),
        "snapshotCompletedMatch": (
            parsed["completed"] == integer(snapshot.get("completed"), -2)
        ),
        "snapshotBlockedMatch": (
            parsed["blocked"] == integer(snapshot.get("blocked"), -2)
        ),
        "noProvenMateriallyUnchangedLoop": parsed["blocking"] == 0,
    }
    return values, {
        "markerCount": count,
        "values": parsed,
        "checks": checks,
        "valid": all(checks.values()),
        "blocking": parsed["blocking"] == 1,
    }


def parse_bounds(lines: list[str]) -> tuple[dict[str, str], dict[str, Any]]:
    values, count = marker_values(lines, "GATE_B_CONVERGENCE_BOUNDS")
    pairs: dict[str, dict[str, int]] = {}
    malformed_pairs: list[str] = []
    scalars: dict[str, int] = {}
    for key, raw in values.items():
        if key == "valid":
            continue
        if "/" in raw:
            components = raw.split("/")
            if len(components) != 2:
                malformed_pairs.append(key)
                continue
            pairs[key] = {
                "count": integer(components[0], -1),
                "cap": integer(components[1], -1),
            }
        else:
            scalars[key] = integer(raw, -1)
    checks = {
        "markerExactlyOnce": count == 1,
        "instrumentationValid": values.get("valid") == "1",
        "atLeastEightCountCapPairs": len(pairs) >= 8,
        "allPairsWellFormedAndWithinCap": (
            not malformed_pairs
            and all(
                pair["count"] >= 0
                and pair["cap"] >= 0
                and pair["count"] <= pair["cap"]
                for pair in pairs.values()
            )
        ),
        "worldEntitiesPresent": scalars.get("worldEntities", -1) >= 0,
        "allScalarValuesNonnegative": all(value >= 0 for value in scalars.values()),
    }
    return values, {
        "markerCount": count,
        "pairs": dict(sorted(pairs.items())),
        "scalars": dict(sorted(scalars.items())),
        "malformedPairs": malformed_pairs,
        "checks": checks,
        "valid": all(checks.values()),
    }


def augment_run(args: argparse.Namespace) -> None:
    base_path = Path(args.base_result)
    log_path = Path(args.log)
    try:
        loaded = json.loads(base_path.read_text())
        if not isinstance(loaded, dict):
            raise ValueError("base result root is not an object")
        base = loaded
        raw = log_path.read_bytes()
    except (OSError, ValueError, json.JSONDecodeError) as error:
        write_json(Path(args.output), {
            "schemaVersion": 5,
            "mission": "GATE-B-CONVERGENCE-01",
            "head": args.head,
            "seed": args.seed,
            "horizon": args.horizon,
            "wave": args.wave,
            "configurationDigest": args.configuration_digest,
            "convergenceChecks": {},
            "failedConvergenceChecks": ["inputEvidenceReadable"],
            "primaryFailure": f"harness_input:{type(error).__name__}",
            "convergenceResult": "HARNESS_INVALID",
            "result": "HARNESS_INVALID",
            "gateBCanonicallyAcquired": False,
            "civ26Started": False,
        })
        return
    lines = raw.decode(errors="replace").splitlines()
    snapshot_value = base.get("snapshot")
    snapshot = snapshot_value if isinstance(snapshot_value, dict) else {}
    log_snapshot, snapshot_marker_count = marker_values(
        lines, "GATE_B3_ACCEPTANCE_SNAPSHOT"
    )
    horizon_marker, horizon_marker_count = marker_values(
        lines, "GATE_B3_HORIZON_COMPLETE"
    )
    role = bootstrap_audit(lines)
    completions = [
        line for line in lines if "autonomous activity completed actor=" in line
    ]
    raw_completion_domains: dict[str, int] = {}
    completion_families: dict[str, int] = {}
    post_600_completion_families: dict[str, int] = {}
    completion_ticks: list[int] = []
    post_600 = 0
    post_2000 = 0
    for line in completions:
        values = tokens(line)
        domain = values.get("domain", "unknown")
        raw_completion_domains[domain] = raw_completion_domains.get(domain, 0) + 1
        family = canonical_activity_family(domain)
        completion_families[family] = completion_families.get(family, 0) + 1
        tick = completion_tick(line)
        completion_ticks.append(tick)
        if tick > 600:
            post_600 += 1
            post_600_completion_families[family] = (
                post_600_completion_families.get(family, 0) + 1
            )
        if tick > 2000:
            post_2000 += 1
    completion_tokens = [tokens(line) for line in completions]
    movement_trace_lines = marker_lines(lines, "embodiment movement tick=")
    physical_movement_after_600 = 0
    physical_movement_after_2000 = 0
    for line in movement_trace_lines:
        movement_tick = integer(tokens(line).get("tick"), -1)
        moved_count = line.count(":moved:")
        if movement_tick > 600:
            physical_movement_after_600 += moved_count
        if movement_tick > 2000:
            physical_movement_after_2000 += moved_count
    semantic, semantic_audit = parse_semantic(lines, args.horizon)
    churn, churn_audit = parse_churn(lines, log_snapshot)
    bounds, bounds_audit = parse_bounds(lines)
    bounds_audit["checks"]["snapshotWorldEntitiesMatch"] = (
        bounds_audit.get("scalars", {}).get("worldEntities", -1)
        == integer(log_snapshot.get("worldEntities"), -2)
    )
    bounds_audit["valid"] = all(bounds_audit["checks"].values())
    movement = base.get("movementPolicy", {})
    if not isinstance(movement, dict):
        movement = {}
    role_pass = (
        role["markerCount"] == 1
        and role["allAssignmentsZero"]
        and role["identicalBoundedPhysicalKits"]
        and role["productiveCommandsZero"]
    )
    post_bootstrap = []
    bootstrap_indexes = [
        index for index, line in enumerate(lines)
        if "GATE_B_BOOTSTRAP_COMPLETE" in line
    ]
    if bootstrap_indexes:
        post_bootstrap = lines[bootstrap_indexes[0] + 1:]
    movement_disable_lines = [
        line for line in post_bootstrap if "[lab-live] movement=off " in line
    ]
    forbidden_movement_lines = [
        line for line in lines if any(marker in line for marker in (
            "bypass=1",
            "distanceHomeBypassUsed=1",
            "directSetPos=1",
            "teleportOrSetPosWorkaroundUsed=1",
        ))
    ]
    runtime_error_lines = [
        line for line in lines if line.startswith("[lab-live] error ")
    ]
    base_required_fields = {
        "head",
        "seed",
        "horizon",
        "configurationDigest",
        "ticksReached",
        "horizonComplete",
        "appExit",
        "runtimeErrors",
        "errorCount",
        "bootstrapComplete",
        "manualProductiveCommands",
        "movementPolicy",
        "snapshot",
        "checkpointAttempted",
        "checkpointSaved",
        "checkpointLoaded",
    }
    movement_required_fields = {
        "enabledAtFinalSnapshot",
        "everEnabled",
        "disabledAfterBootstrap",
        "operations",
    }
    snapshot_required_fields = {
        "seed",
        "tick",
        "digest",
        "agents",
        "alive",
        "worldEntities",
        "runtimeErrors",
        "manualProductive",
        "movementEnabled",
        "movementEverEnabled",
        "movementOperations",
        "starts",
        "completed",
        "blocked",
        "campStockUnits",
        "genericResourceUnits",
    }
    required_base_fields_present = (
        base_required_fields.issubset(base)
        and isinstance(snapshot_value, dict)
        and movement_required_fields.issubset(movement)
    )
    reached_horizon = (
        integer(base.get("ticksReached"), -1) == args.horizon
        and base.get("horizonComplete") is True
    )
    final_trace_well_formed = (
        snapshot_marker_count == 1
        and horizon_marker_count == 1
        and role["markerCount"] == 1
        and semantic_audit["valid"]
        and churn_audit["valid"]
        and bounds_audit["valid"]
        and snapshot_required_fields.issubset(snapshot)
    )
    timeout_detected = any(
        marker in line
        for line in lines
        for marker in (
            "GATE_B_CONVERGENCE_TIMEOUT",
            "GATE_B_CONVERGENCE_LIVE_TIMEOUT",
        )
    )
    harness_invalid = (
        not required_base_fields_present
        or "\x00" in raw.decode(errors="replace")
        or base.get("head") != args.head
        or base.get("seed") != args.seed
        or base.get("horizon") != args.horizon
        or base.get("configurationDigest") != args.configuration_digest
        or (reached_horizon and not final_trace_well_formed)
        or snapshot_marker_count > 1
        or horizon_marker_count > 1
        or role["markerCount"] > 1
    )
    wave_reached = reached_horizon
    common_checks = {
        "requiredBaseFieldsPresent": required_base_fields_present,
        "headMatches": base.get("head") == args.head,
        "seedMatches": base.get("seed") == args.seed,
        "horizonMatches": base.get("horizon") == args.horizon,
        "configurationMatches": (
            base.get("configurationDigest") == args.configuration_digest
        ),
        "horizonComplete": base.get("horizonComplete") is True,
        "appExitZero": base.get("appExit") == 0,
        "runtimeErrorsZero": (
            base.get("runtimeErrors") == 0 and base.get("errorCount") == 0
            and not runtime_error_lines
        ),
        "bootstrapComplete": base.get("bootstrapComplete") is True,
        "bootstrapMarkerExactlyOnce": len(bootstrap_indexes) == 1,
        "roleNeutral": role_pass,
        "productiveCommandsZero": (
            base.get("manualProductiveCommands") == 0
            and log_snapshot.get("manualProductive") == "0"
        ),
        "finalSnapshotExactlyOnce": snapshot_marker_count == 1,
        "baseSnapshotMatchesLog": snapshot == log_snapshot,
        "logSnapshotSeedMatches": integer(log_snapshot.get("seed"), -1) == args.seed,
        "logSnapshotTickMatches": (
            integer(log_snapshot.get("tick"), -1) == args.horizon
        ),
        "horizonMarkerExactlyOnce": horizon_marker_count == 1,
        "horizonMarkerMatches": (
            integer(horizon_marker.get("seed"), -1) == args.seed
            and integer(horizon_marker.get("tick"), -1) == args.horizon
            and integer(horizon_marker.get("target"), -1) == args.horizon
            and horizon_marker.get("exact") == "1"
        ),
        "semanticStateComplete": semantic_audit["valid"],
        "semanticStateMatchesSnapshot": (
            semantic.get("durable") == log_snapshot.get("digest")
            and integer(semantic.get("agentCount"), -1)
            == integer(log_snapshot.get("agents"), -2)
            and integer(semantic.get("alive"), -1)
            == integer(log_snapshot.get("alive"), -2)
            and integer(semantic.get("worldEntities"), -1)
            == integer(log_snapshot.get("worldEntities"), -2)
        ),
        "completionFamiliesKnown": (
            bool(completions)
            and all(
                value.get("domain") in KNOWN_ACTIVITY_FAMILIES
                for value in completion_tokens
            )
        ),
        "completionManualTriggerZero": (
            bool(completions)
            and all(value.get("manualTrigger") == "0" for value in completion_tokens)
        ),
        "completionTicksWithinHorizon": (
            bool(completion_ticks)
            and all(0 < tick <= args.horizon for tick in completion_ticks)
        ),
        "completionTraceMatchesSnapshot": (
            len(completions) == integer(log_snapshot.get("completed"), -1)
        ),
        "movementEnabled": (
            movement.get("enabledAtFinalSnapshot") is True
            and movement.get("everEnabled") is True
            and movement.get("disabledAfterBootstrap") is False
            and log_snapshot.get("movementEnabled") == "1"
            and log_snapshot.get("movementEverEnabled") == "1"
            and movement.get("operations", 0) > 0
            and integer(log_snapshot.get("movementOperations"), -1)
            == movement.get("operations")
            and not movement_disable_lines
        ),
        "distanceHomeBypassAbsent": (
            not base.get("distanceFromHomeFailure")
            and not marker_lines(lines, "GATE_B4_DISTANCE_FROM_HOME_FAILURE")
            and not forbidden_movement_lines
        ),
        "ghostProductiveStockAbsent": (
            integer(snapshot.get("campStockUnits"), -1) == 0
            and integer(snapshot.get("genericResourceUnits"), -1) == 0
        ),
    }
    wave_checks: dict[str, bool] = {}
    if args.wave == "wave1-128":
        wave_checks.update({
            "atLeastTwoActivityFamilies": len(
                [value for value in completion_families.values() if value > 0]
            ) >= 2,
            "churnAcceptable": churn_audit["valid"],
        })
    elif args.wave == "wave2-800":
        wave_checks.update({
            "activityContinuedAfter600": post_600 > 0,
            "physicalMovementContinuedAfter600": (
                physical_movement_after_600 > 0
            ),
            "workContinued": (
                integer(snapshot.get("workCommitments")) > 0
                and integer(snapshot.get("workActive")) > 0
                and integer(snapshot.get("workEvidence")) > 0
                and integer(snapshot.get("workRefreshEvents")) > 0
            ),
            "physicalFoodCausal": (
                integer(snapshot.get("physicalFoodTotal")) > 0
                and integer(snapshot.get("physicalFoodDroppedIDs")) == 0
            ),
            "churnAcceptable": churn_audit["valid"],
            "boundsValid": bounds_audit["valid"],
        })
    elif args.wave == "wave3-2400":
        wave_checks.update({
            "activityContinuedAfter2000": post_2000 > 0,
            "physicalMovementContinuedAfter2000": (
                physical_movement_after_2000 > 0
            ),
            "agricultureProgressObserved": (
                integer(snapshot.get("agricultureActions")) > 0
            ),
            "livestockContinuationObserved": (
                completion_families.get("livestock", 0) >= 2
                and post_600_completion_families.get("livestock", 0) >= 1
                and integer(snapshot.get("livestockRecords")) >= 2
            ),
            "diagnosticSubsystemCountersPresent": all(
                key in snapshot and integer(snapshot.get(key), -1) >= 0
                for key in (
                    "agricultureActions",
                    "agricultureCycles",
                    "livestockAnimals",
                    "livestockRecords",
                    "careNeeds",
                    "careOutcomes",
                    "teachingApprenticeships",
                    "teachingGuided",
                    "workCommitments",
                    "workEvidence",
                    "autonomyRetained",
                    "autonomyEvicted",
                    "causalRetained",
                    "causalDropped",
                )
            ),
            "workOutcomesObserved": integer(snapshot.get("workEvidence")) > 0,
            "physicalFoodCausal": (
                integer(snapshot.get("physicalFoodTotal")) > 0
                and integer(snapshot.get("physicalFoodDroppedIDs")) == 0
            ),
            "churnAcceptable": churn_audit["valid"],
            "boundsValid": bounds_audit["valid"],
        })
    elif args.wave == "determinism":
        wave_checks.update({
            "churnAcceptable": churn_audit["valid"],
            "boundsValid": bounds_audit["valid"],
        })
    elif args.wave == "checkpoint":
        checkpoint_values, checkpoint_count = exact_marker_values(
            lines, "GATE_B_CONVERGENCE_CHECKPOINT"
        )
        checkpoint_boundary, checkpoint_boundary_count = marker_values(
            lines, "GATE_B3_CHECKPOINT_BOUNDARY"
        )
        custody_markers = [
            tokens(line)
            for line in marker_lines(lines, "GATE_B_CONVERGENCE_CUSTODY")
        ]
        custody_by_phase = {
            phase: [value for value in custody_markers if value.get("phase") == phase]
            for phase in ("before", "after", "continued")
        }
        custody_before = (
            custody_by_phase["before"][0]
            if len(custody_by_phase["before"]) == 1 else {}
        )
        custody_after = (
            custody_by_phase["after"][0]
            if len(custody_by_phase["after"]) == 1 else {}
        )
        custody_continued = (
            custody_by_phase["continued"][0]
            if len(custody_by_phase["continued"]) == 1 else {}
        )
        continued_values, continued_count = marker_values(
            lines, "GATE_B_CONVERGENCE_CHECKPOINT_CONTINUED"
        )
        load_values, load_count = marker_values(
            lines, "checkpoint loaded name=gate-b3-887-mid"
        )
        save_values, save_count = marker_values(
            lines, "checkpoint saved name=gate-b3-887-mid"
        )
        checkpoint_error_lines = [
            line for line in lines
            if "checkpoint error" in line.lower()
            or "checkpoint failed" in line.lower()
        ]
        expected_checkpoint_tick = args.horizon // 2
        checkpoint_before = integer(
            checkpoint_values.get("beforeCompletions"), -1
        )
        checkpoint_after = integer(
            checkpoint_values.get("afterCompletions"), -1
        )
        checkpoint_checks = {
            "markerExactlyOnce": checkpoint_count == 1,
            "boundaryMarkerExact": (
                checkpoint_boundary_count == 1
                and checkpoint_boundary.get("seed") == str(args.seed)
                and integer(checkpoint_boundary.get("tick"), -1)
                == expected_checkpoint_tick
                and integer(checkpoint_boundary.get("target"), -1)
                == expected_checkpoint_tick
            ),
            "saveReportedSuccess": (
                checkpoint_values.get("saveSucceeded") == "1"
                and save_count == 1
                and save_values.get("mutation") == "none"
            ),
            "loadReportedSuccess": (
                checkpoint_values.get("loadSucceeded") == "1"
                and load_count == 1
            ),
            "exact": checkpoint_values.get("exact") == "1",
            "custodyExact": checkpoint_values.get("custodyExact") == "1",
            "boundaryTicksExact": (
                integer(checkpoint_values.get("beforeTick"), -1)
                == expected_checkpoint_tick
                and integer(checkpoint_values.get("afterTick"), -1)
                == expected_checkpoint_tick
            ),
            "durableStateExact": (
                HEX_SHA256.fullmatch(
                    checkpoint_values.get("beforeDurable", "")
                ) is not None
                and checkpoint_values.get("beforeDurable")
                == checkpoint_values.get("afterDurable")
            ),
            "semanticStateExact": (
                HEX_SHA256.fullmatch(
                    checkpoint_values.get("beforeSemantic", "")
                ) is not None
                and checkpoint_values.get("beforeSemantic")
                == checkpoint_values.get("afterSemantic")
            ),
            "configurationUnchanged": (
                checkpoint_values.get("configurationUnchanged") == "1"
            ),
            "reconciled": checkpoint_values.get("reconciled") == "1",
            "exactProbeReuse": (
                load_values.get("probeReconciliation") == "reused_exact"
            ),
            "restoreWorldMutationNone": (
                load_values.get("worldMutation") == "none"
            ),
            "custodyPhasesExactlyOnce": (
                len(custody_markers) == 3
                and all(
                    len(custody_by_phase[phase]) == 1
                    for phase in ("before", "after", "continued")
                )
            ),
            "custodySnapshotsComplete": all(
                {
                    "tick",
                    "durable",
                    "civilizationAgentIDs",
                    "probeRuntimeBindings",
                    "worldEntityIDs",
                    "agentInventories",
                    "containerInventories",
                    "looseItemEntities",
                    "agentFingerprints",
                    "containerFingerprints",
                    "materialTotals",
                    "agentMaterialQuantity",
                    "containerMaterialQuantity",
                    "looseMaterialQuantity",
                    "totalMaterialQuantity",
                    "trackedCustodyDigest",
                }.issubset(value)
                for value in (custody_before, custody_after, custody_continued)
            ),
            "civilizationIdentityStableAcrossRestore": (
                custody_before.get("civilizationAgentIDs", "")
                and custody_before.get("civilizationAgentIDs")
                == custody_after.get("civilizationAgentIDs")
            ),
            "runtimeBindingReusedExactly": (
                custody_before.get("probeRuntimeBindings", "")
                and custody_before.get("probeRuntimeBindings")
                == custody_after.get("probeRuntimeBindings")
            ),
            "physicalCustodyFingerprintExact": all(
                custody_before.get(field, "")
                and custody_before.get(field) == custody_after.get(field)
                for field in (
                    "worldEntityIDs",
                    "agentInventories",
                    "containerInventories",
                    "looseItemEntities",
                    "agentFingerprints",
                    "containerFingerprints",
                    "trackedCustodyDigest",
                )
            ),
            "materialTotalsExact": (
                checkpoint_values.get("beforeMaterialTotals", "")
                and checkpoint_values.get("beforeMaterialTotals")
                == checkpoint_values.get("afterMaterialTotals")
                and checkpoint_values.get("beforeMaterialTotals")
                == custody_before.get("materialTotals")
                and custody_before.get("materialTotals")
                == custody_after.get("materialTotals")
            ),
            "holderQuantitiesExact": all(
                integer(checkpoint_values.get(f"before{holder}Quantity"), -1) >= 0
                and checkpoint_values.get(f"before{holder}Quantity")
                == checkpoint_values.get(f"after{holder}Quantity")
                for holder in ("Agent", "Container", "Loose", "Total")
            ),
            "beforeCompletionsPresent": checkpoint_before >= 0,
            "completionCounterRestoredExactly": (
                checkpoint_after == checkpoint_before
            ),
            "continuationMarkerExactlyOnce": continued_count == 1,
            "continuationReachedAfterRestore": (
                integer(continued_values.get("targetTick"), -1)
                > expected_checkpoint_tick
                and integer(continued_values.get("actualTick"), -1)
                >= integer(continued_values.get("targetTick"), -1)
                and continued_values.get("snapshotPresent") == "1"
                and continued_values.get("stableCivilizationIDs") == "1"
            ),
            "continuationCustodyLinked": (
                continued_values.get("postLoadCustodyDigest", "")
                == custody_after.get("trackedCustodyDigest")
                and continued_values.get("continuedCustodyDigest", "")
                == custody_continued.get("trackedCustodyDigest")
                and continued_values.get("postLoadMaterialTotals", "")
                == custody_after.get("materialTotals")
                and continued_values.get("continuedMaterialTotals", "")
                == custody_continued.get("materialTotals")
            ),
            "postRestoreProgress": (
                integer(log_snapshot.get("completed"), -1) > checkpoint_before
            ),
            "checkpointErrorsAbsent": not checkpoint_error_lines,
        }
        checkpoint_audit = {
            "markerCount": checkpoint_count,
            "values": checkpoint_values,
            "checks": checkpoint_checks,
            "valid": all(checkpoint_checks.values()),
        }
        checkpoint_runtime_reached = (
            base.get("checkpointAttempted") is True
            and base.get("checkpointSaved") is True
            and base.get("checkpointLoaded") is True
        )
        wave_reached = wave_reached and checkpoint_runtime_reached
        harness_invalid = harness_invalid or (
            reached_horizon
            and checkpoint_runtime_reached
            and (
                checkpoint_count != 1
                or checkpoint_boundary_count != 1
                or len(custody_markers) != 3
                or continued_count != 1
                or save_count != 1
                or load_count != 1
            )
        )
        wave_checks.update({
            "checkpointBoundaryReached": base.get("checkpointAttempted") is True,
            "checkpointSaved": base.get("checkpointSaved") is True,
            "checkpointLoaded": base.get("checkpointLoaded") is True,
            "checkpointSemanticExact": checkpoint_audit["valid"],
            "churnAcceptable": churn_audit["valid"],
            "boundsValid": bounds_audit["valid"],
        })
    elif args.wave == "stress":
        shock, shock_count = marker_values(lines, "GATE_B3_SHOCK")
        shock_indexes = [
            index for index, line in enumerate(lines) if "GATE_B3_SHOCK" in line
        ]
        post_shock_completions = []
        if len(shock_indexes) == 1:
            for line in lines[shock_indexes[0] + 1:]:
                if "autonomous activity completed actor=" not in line:
                    continue
                values = tokens(line)
                if completion_tick(line) > 3200:
                    post_shock_completions.append(values)
        expected_kind = STRESS_KINDS.get(args.seed)
        completions_before = integer(shock.get("completionsBefore"), -1)
        work_before = integer(shock.get("workEvidenceBefore"), -1)
        common_shock_checks = {
            "markerExactlyOnce": shock_count == 1,
            "kindMatchesSeed": shock.get("kind") == expected_kind,
            "applied": shock.get("applied") == "1",
            "tickExactly3200": integer(shock.get("tick"), -1) == 3200,
            "baselineCountersPresent": (
                completions_before >= 0 and work_before >= 0
            ),
            "subtractiveOnly": not any(
                marker in "\n".join(lines)
                for marker in (
                    "replacementInjected=1",
                    "foodInjected=1",
                    "replacementToolInjected=1",
                    "replacementFeedInjected=1",
                    "successInjected=1",
                )
            ),
            "postShockResponse": (
                bool(post_shock_completions)
                and (
                    integer(log_snapshot.get("completed"), -1) > completions_before
                    or integer(log_snapshot.get("workEvidence"), -1) > work_before
                )
            ),
        }
        if expected_kind == "worker-care":
            kind_checks = {
                "workerIdentified": (
                    bool(re.fullmatch(r"agent_[A-Za-z0-9_.-]+", shock.get("actor", "")))
                ),
                "workerRemoved": shock.get("removedWorker") == "1",
                "physicalWorkerUnavailable": (
                    shock.get("physicalAvailable") == "0"
                ),
                "carePressurePresent": (
                    integer(shock.get("carePressureBefore"), -1) > 0
                ),
                "noWorkerOrFoodReplacement": (
                    shock.get("replacementInjected") == "0"
                    and shock.get("foodInjected") == "0"
                ),
                "otherActorContinuedAfterShock": any(
                    value.get("actor") != shock.get("actor")
                    for value in post_shock_completions
                ),
            }
        else:
            removed_quantities: dict[str, int] = {}
            removed_well_formed = True
            for component in shock.get("removed", "").split(","):
                name, separator, quantity = component.rpartition(":")
                parsed_quantity = integer(quantity, -1)
                if (
                    not separator
                    or name not in {
                        "iron_hoe",
                        "wheat",
                        "wheat_seeds",
                        "fishing_rod",
                        "shears",
                    }
                    or parsed_quantity <= 0
                    or name in removed_quantities
                ):
                    removed_well_formed = False
                    continue
                removed_quantities[name] = parsed_quantity
            removed_quantity = integer(shock.get("removedQuantity"), -1)
            kind_checks = {
                "physicalStockRemoved": (
                    removed_well_formed
                    and bool(removed_quantities)
                    and removed_quantity > 0
                    and sum(removed_quantities.values()) == removed_quantity
                ),
                "livestockDisrupted": (
                    shock.get("livestockDisruption") == "1"
                    and (
                        removed_quantities.get("wheat", 0)
                        + removed_quantities.get("shears", 0)
                    ) > 0
                ),
                "wildDisrupted": (
                    shock.get("wildDisruption") == "1"
                    and removed_quantities.get("fishing_rod", 0) > 0
                ),
                "noToolFeedOrSuccessReplacement": (
                    shock.get("replacementToolInjected") == "0"
                    and shock.get("replacementFeedInjected") == "0"
                    and shock.get("successInjected") == "0"
                ),
            }
        shock_checks = {**common_shock_checks, **kind_checks}
        shock_audit = {
            "markerCount": shock_count,
            "expectedKind": expected_kind,
            "values": shock,
            "postShockCompletionCount": len(post_shock_completions),
            "postShockCompletionFamilies": dict(sorted({
                family: sum(
                    canonical_activity_family(value.get("domain", "unknown"))
                    == family
                    for value in post_shock_completions
                )
                for family in {
                    canonical_activity_family(value.get("domain", "unknown"))
                    for value in post_shock_completions
                }
            }.items())),
            "checks": shock_checks,
            "valid": all(shock_checks.values()),
        }
        wave_reached = (
            wave_reached
            and base.get("shockAttempted") is True
            and shock_count == 1
            and shock.get("applied") == "1"
        )
        harness_invalid = harness_invalid or shock_count > 1
        wave_checks.update({
            "shockContractExact": shock_audit["valid"],
            "continued400TicksAfterShock": base.get("ticksReached", 0) == 3600,
            "churnAcceptable": churn_audit["valid"],
            "boundsValid": bounds_audit["valid"],
        })
    checks = {**common_checks, **wave_checks}
    failed_checks = sorted(key for key, passed in checks.items() if not passed)
    primary_failure = base.get("primaryFailure")
    result_state = classified_result(
        checks,
        timeout=timeout_detected,
        harness_invalid=harness_invalid,
        reached=wave_reached,
    )
    if result_state == "PASS":
        primary_failure = "none"
    elif result_state == "TIMEOUT":
        primary_failure = "timeout"
    elif result_state == "HARNESS_INVALID":
        primary_failure = (
            "harness_invalid:"
            + (failed_checks[0] if failed_checks else "evidence_integrity")
        )
    elif result_state == "NOT_REACHED":
        if primary_failure in {None, "", "none"}:
            primary_failure = "horizon_or_required_boundary_not_reached"
    elif primary_failure in {None, "", "none"}:
        primary_failure = (
            f"convergence_check:{failed_checks[0]}"
            if failed_checks else "convergence_failed"
        )
    base.update({
        "schemaVersion": 5,
        "mission": "GATE-B-CONVERGENCE-01",
        "wave": args.wave,
        "logSHA256": sha256_bytes(raw),
        "logSnapshot": log_snapshot,
        "horizonMarker": horizon_marker,
        "roleNeutralityAudit": role,
        "rawCompletionDomains": dict(sorted(raw_completion_domains.items())),
        "completionFamilies": dict(sorted(completion_families.items())),
        "completionFamiliesAfterTick600": dict(
            sorted(post_600_completion_families.items())
        ),
        "physicalCompletionsAfterTick600": post_600,
        "physicalCompletionsAfterTick2000": post_2000,
        "physicalMovementsAfterTick600": physical_movement_after_600,
        "physicalMovementsAfterTick2000": physical_movement_after_2000,
        "semanticState": semantic,
        "semanticAudit": semantic_audit,
        "churnAudit": churn_audit,
        "boundsAudit": bounds_audit,
        "movementEvidence": {
            "postBootstrapDisableLines": movement_disable_lines,
            "forbiddenBypassLines": forbidden_movement_lines,
            "distanceHomeFailureLines": marker_lines(
                lines, "GATE_B4_DISTANCE_FROM_HOME_FAILURE"
            ),
        },
        "checkpointAudit": locals().get("checkpoint_audit"),
        "shockAudit": locals().get("shock_audit"),
        "convergenceChecks": checks,
        "failedConvergenceChecks": failed_checks,
        "primaryFailure": primary_failure or "none",
        "convergenceResult": result_state,
        "result": result_state,
        "gateBCanonicallyAcquired": False,
        "civ26Started": False,
    })
    write_json(Path(args.output), base)


def parse_live(args: argparse.Namespace) -> None:
    log_path = Path(args.log)
    capture_dir = Path(args.capture_directory)
    try:
        raw = log_path.read_bytes()
    except OSError as error:
        write_json(Path(args.output), {
            "schemaVersion": 3,
            "mission": "GATE-B-CONVERGENCE-01",
            "head": args.head,
            "wave": "live",
            "seed": 46,
            "result": "HARNESS_INVALID",
            "primaryFailure": f"harness_input:{type(error).__name__}",
            "checks": {},
            "failedChecks": ["logReadable"],
            "gateBCanonicallyAcquired": False,
            "civ26Started": False,
        })
        return
    lines = raw.decode(errors="replace").splitlines()
    complete, complete_count = marker_values(
        lines, "GATE_B3_PASSIVE_WALL_COMPLETE"
    )
    snapshot, snapshot_count = marker_values(
        lines, "GATE_B3_ACCEPTANCE_SNAPSHOT"
    )
    coexistence, coexistence_count = marker_values(
        lines, "player coexistence result"
    )
    role = bootstrap_audit(lines)
    capture_evidence: list[dict[str, Any]] = []
    for name in LIVE_CAPTURES:
        path = capture_dir / name
        data = path.read_bytes() if path.is_file() else b""
        inspection = inspect_png(data)
        capture_evidence.append({
            "name": name,
            "present": path.is_file(),
            "size": len(data),
            "sha256": sha256_bytes(data) if data else None,
            **inspection,
        })
    captures = [
        value["name"] for value in capture_evidence
        if value["present"] and value["structureValid"]
    ]
    completion_lines = [
        line for line in lines if "autonomous activity completed actor=" in line
    ]
    completion_values = [tokens(line) for line in completion_lines]
    completion_ticks = [completion_tick(line) for line in completion_lines]
    wall_start_indexes = [
        index for index, line in enumerate(lines)
        if "GATE_B3_PASSIVE_WALL_START" in line
    ]
    post_start_completions = (
        [
            line for line in lines[wall_start_indexes[0] + 1:]
            if "autonomous activity completed actor=" in line
        ]
        if len(wall_start_indexes) == 1 else []
    )
    simulation_tick = integer(complete.get("simulationTick"), -1)
    semantic, semantic_audit = parse_semantic(lines, simulation_tick)
    initial_completions = integer(complete.get("initialCompletions"), -1)
    final_completions = integer(complete.get("finalCompletions"), -1)
    completion_delta = integer(complete.get("completionDelta"), -1)
    alive_agents = integer(complete.get("aliveAgents"), -1)
    runtime_error_lines = [
        line for line in lines if line.startswith("[lab-live] error ")
    ]
    forbidden_movement_lines = [
        line for line in lines if any(marker in line for marker in (
            "bypass=1",
            "distanceHomeBypassUsed=1",
            "directSetPos=1",
            "teleportOrSetPosWorkaroundUsed=1",
        ))
    ]
    live_timeout_detected = any(
        "GATE_B_CONVERGENCE_LIVE_TIMEOUT" in line for line in lines
    )
    live_required_complete_fields = {
        "targetSeconds",
        "elapsedSeconds",
        "simulationTick",
        "worldTick",
        "initialCompletions",
        "finalCompletions",
        "completionDelta",
        "aliveAgents",
        "movementStayedEnabled",
        "runtimeErrors",
        "productiveCommands",
    }
    live_required_snapshot_fields = {
        "seed",
        "tick",
        "digest",
        "agents",
        "alive",
        "worldEntities",
        "runtimeErrors",
        "manualProductive",
        "movementEnabled",
        "movementEverEnabled",
        "completed",
    }
    live_reached = (
        complete_count == 1
        and decimal(complete.get("elapsedSeconds"), -1) >= 120
        and args.elapsed_seconds >= 120
    )
    live_harness_invalid = (
        "\x00" in raw.decode(errors="replace")
        or complete_count > 1
        or snapshot_count > 1
        or role["markerCount"] > 1
        or (live_reached and (
            not live_required_complete_fields.issubset(complete)
            or not live_required_snapshot_fields.issubset(snapshot)
            or not semantic_audit["valid"]
        ))
    )
    checks = {
        "appExitZero": args.app_exit == 0,
        "completionMarkerExactlyOnce": complete_count == 1,
        "wallStartExactlyOnce": len(wall_start_indexes) == 1,
        "targetSecondsExactly120": decimal(complete.get("targetSeconds"), -1) == 120,
        "durationAtLeast120": decimal(complete.get("elapsedSeconds")) >= 120,
        "processDurationAtLeast120": args.elapsed_seconds >= 120,
        "roleNeutral": (
            role["markerCount"] == 1
            and role["allAssignmentsZero"]
            and role["identicalBoundedPhysicalKits"]
            and role["productiveCommandsZero"]
        ),
        "snapshotExactlyOnce": snapshot_count == 1,
        "snapshotSeedMatches": integer(snapshot.get("seed"), -1) == 46,
        "snapshotTickMatches": integer(snapshot.get("tick"), -1) == simulation_tick,
        "positiveFinalTicks": (
            simulation_tick > 0 and integer(complete.get("worldTick"), -1) > 0
        ),
        "semanticStateComplete": semantic_audit["valid"],
        "semanticStateMatchesSnapshot": (
            semantic.get("durable") == snapshot.get("digest")
            and integer(semantic.get("agentCount"), -1)
            == integer(snapshot.get("agents"), -2)
            and integer(semantic.get("alive"), -1)
            == integer(snapshot.get("alive"), -2)
            and integer(semantic.get("worldEntities"), -1)
            == integer(snapshot.get("worldEntities"), -2)
        ),
        "movementStayedEnabled": (
            complete.get("movementStayedEnabled") == "1"
            and snapshot.get("movementEnabled") == "1"
            and snapshot.get("movementEverEnabled") == "1"
        ),
        "runtimeErrorsZero": (
            complete.get("runtimeErrors") == "0"
            and snapshot.get("runtimeErrors") == "0"
            and not runtime_error_lines
        ),
        "productiveCommandsZero": (
            complete.get("productiveCommands") == "0"
            and snapshot.get("manualProductive") == "0"
        ),
        "civilizationContinuedLate": (
            initial_completions >= 0
            and final_completions > initial_completions
            and completion_delta == final_completions - initial_completions
            and completion_delta > 0
            and integer(snapshot.get("completed"), -1) == final_completions
            and bool(post_start_completions)
        ),
        "completionFamiliesKnown": (
            bool(completion_values)
            and all(
                value.get("domain") in KNOWN_ACTIVITY_FAMILIES
                for value in completion_values
            )
        ),
        "completionManualTriggerZero": (
            bool(completion_values)
            and all(
                value.get("manualTrigger") == "0"
                for value in completion_values
            )
        ),
        "completionTicksWithinRun": (
            bool(completion_ticks)
            and all(0 < tick <= simulation_tick for tick in completion_ticks)
        ),
        "multipleAgentsObservable": (
            alive_agents >= 3
            and integer(snapshot.get("alive"), -1) == alive_agents
            and integer(snapshot.get("agents"), -1) >= 3
        ),
        "playerInputCoexists": (
            coexistence_count == 1
            and coexistence.get("passed") == "1"
            and coexistence.get("directSetPos") == "0"
            and integer(coexistence.get("completedDelta"), -1) > 0
        ),
        "allFiveCapturesArePNG": (
            captures == LIVE_CAPTURES
            and all(value["structureValid"] for value in capture_evidence)
            and len({
                (value["width"], value["height"]) for value in capture_evidence
            }) == 1
        ),
        "distanceHomeBypassAbsent": (
            not any("GATE_B4_DISTANCE_FROM_HOME_FAILURE" in line for line in lines)
            and not forbidden_movement_lines
        ),
    }
    failed_checks = sorted(key for key, passed in checks.items() if not passed)
    result_state = classified_result(
        checks,
        timeout=live_timeout_detected,
        harness_invalid=live_harness_invalid,
        reached=live_reached,
    )
    result = {
        "schemaVersion": 3,
        "mission": "GATE-B-CONVERGENCE-01",
        "head": args.head,
        "wave": "live",
        "seed": 46,
        "targetWallSeconds": 120,
        "measuredWallSeconds": decimal(complete.get("elapsedSeconds")),
        "processElapsedSeconds": args.elapsed_seconds,
        "appExit": args.app_exit,
        "logSHA256": sha256_bytes(raw),
        "logSnapshot": snapshot,
        "simulationTick": simulation_tick,
        "worldTick": integer(complete.get("worldTick")),
        "roleNeutralityAudit": role,
        "captures": captures,
        "captureEvidence": capture_evidence,
        "snapshot": snapshot,
        "completion": complete,
        "rawCompletionDomains": dict(sorted({
            family: sum(
                value.get("domain") == family for value in completion_values
            )
            for family in KNOWN_ACTIVITY_FAMILIES
            if any(value.get("domain") == family for value in completion_values)
        }.items())),
        "completionFamilies": dict(sorted({
            family: sum(
                canonical_activity_family(value.get("domain", "unknown"))
                == family
                for value in completion_values
            )
            for family in {
                canonical_activity_family(value.get("domain", "unknown"))
                for value in completion_values
            }
        }.items())),
        "postStartCompletionTraceCount": len(post_start_completions),
        "semanticState": semantic,
        "semanticAudit": semantic_audit,
        "playerCoexistence": coexistence,
        "movementEvidence": {
            "forbiddenBypassLines": forbidden_movement_lines,
            "distanceHomeFailureLines": marker_lines(
                lines, "GATE_B4_DISTANCE_FROM_HOME_FAILURE"
            ),
        },
        "checks": checks,
        "failedChecks": failed_checks,
        "primaryFailure": (
            "none" if result_state == "PASS"
            else ({
                "TIMEOUT": "timeout",
                "HARNESS_INVALID": "harness_invalid",
                "NOT_REACHED": "wall_target_not_reached",
            }.get(result_state)
            or (
                f"live_check:{failed_checks[0]}"
                if failed_checks else "live_failed"
            ))
        ),
        "result": result_state,
        "gateBCanonicallyAcquired": False,
        "civ26Started": False,
    }
    write_json(Path(args.output), result)


def wave_results(
    root: Path,
    directory: str,
    seeds: list[int],
    *,
    head: str,
    configuration_digest: str,
    horizon: int,
    prefix: str = "seed-",
) -> tuple[list[dict[str, Any]], bool]:
    results = []
    expected_labels = {f"{prefix}{seed}" for seed in seeds}
    for seed in seeds:
        results.append(exact_result(
            root,
            directory,
            f"{prefix}{seed}",
            head=head,
            configuration_digest=configuration_digest,
            seed=seed,
            horizon=horizon,
            wave=directory,
        ))
    return results, exact_labels(root, directory, expected_labels)


def passed_runs(values: list[dict[str, Any]]) -> bool:
    return bool(values) and all(
        value.get("convergenceResult") == "PASS"
        and value.get("evidenceIntegrity", {}).get("valid") is True
        and isinstance(value.get("convergenceChecks"), dict)
        and bool(value["convergenceChecks"])
        and all(check is True for check in value["convergenceChecks"].values())
        for value in values
    )


def aggregate_result_state(
    values: list[dict[str, Any]],
    *,
    passed: bool,
    additional_failure: bool = False,
) -> str:
    if passed and not additional_failure:
        return "PASS"
    states = [
        value.get("convergenceResult", value.get("result", "HARNESS_INVALID"))
        for value in values
    ]
    for state in ("TIMEOUT", "HARNESS_INVALID", "NOT_REACHED", "FAIL"):
        if state in states:
            return state
    if states and all(state == "NOT_RUN" for state in states):
        return "NOT_RUN"
    return "FAIL" if additional_failure else "HARNESS_INVALID"


def aggregate(args: argparse.Namespace) -> None:
    root = Path(args.root)
    wave1, wave1_labels = wave_results(
        root, "wave1-128", FIXED_SEEDS,
        head=args.head, configuration_digest=args.configuration_digest,
        horizon=128,
    )
    wave2, wave2_labels = wave_results(
        root, "wave2-800", FIXED_SEEDS,
        head=args.head, configuration_digest=args.configuration_digest,
        horizon=800,
    )
    wave3, wave3_labels = wave_results(
        root, "wave3-2400", MEDIUM_SEEDS,
        head=args.head, configuration_digest=args.configuration_digest,
        horizon=2400,
    )
    stress, stress_labels = wave_results(
        root, "stress", STRESS_SEEDS,
        head=args.head, configuration_digest=args.configuration_digest,
        horizon=3600,
    )
    deterministic_a = exact_result(
        root, "determinism", "seed-509-a",
        head=args.head, configuration_digest=args.configuration_digest,
        seed=509, horizon=1600, wave="determinism",
    )
    deterministic_b = exact_result(
        root, "determinism", "seed-509-b",
        head=args.head, configuration_digest=args.configuration_digest,
        seed=509, horizon=1600, wave="determinism",
    )
    determinism_labels = exact_labels(
        root, "determinism", {"seed-509-a", "seed-509-b"}
    )
    checkpoint = exact_result(
        root, "checkpoint", "seed-887",
        head=args.head, configuration_digest=args.configuration_digest,
        seed=887, horizon=2400, wave="checkpoint",
    )
    checkpoint_labels = exact_labels(root, "checkpoint", {"seed-887"})
    live = exact_result(
        root, "live", "client",
        head=args.head, seed=46, wave="live", live=True,
    )
    live_labels = exact_labels(root, "live", {"client"})

    focused_path = root / "focused" / "results.tsv"
    focused: list[dict[str, Any]] = []
    focused_malformed = False
    if focused_path.exists():
        for line in focused_path.read_text().splitlines():
            fields = line.split("\t")
            if len(fields) != 4:
                focused_malformed = True
                continue
            selector, passed, failed, exit_code = fields
            item = {
                "selector": selector,
                "passed": integer(passed),
                "failed": integer(failed),
                "exit": integer(exit_code),
            }
            selector_log_path = root / "focused" / f"{selector}.log"
            try:
                selector_log_raw = selector_log_path.read_bytes()
            except OSError:
                selector_log_raw = b""
            selector_log_text = selector_log_raw.decode(errors="replace")
            selector_counts = re.findall(
                r"^([0-9]+) passed, ([0-9]+) failed$",
                selector_log_text,
                flags=re.MULTILINE,
            )
            item.update({
                "logPresent": selector_log_path.is_file(),
                "logSHA256": (
                    sha256_bytes(selector_log_raw) if selector_log_raw else None
                ),
                "logResultCount": len(selector_counts),
                "logCountMatches": (
                    len(selector_counts) == 1
                    and integer(selector_counts[0][0], -1) == item["passed"]
                    and integer(selector_counts[0][1], -1) == item["failed"]
                ),
            })
            focused.append(item)
    focused_selectors = [item["selector"] for item in focused]
    focused_log_names = {
        path.name for path in (root / "focused").glob("*.log")
        if path.is_file()
    }
    focused_pass = (
        not focused_malformed
        and len(focused) == len(REQUIRED_SELECTORS)
        and len(focused_selectors) == len(set(focused_selectors))
        and set(focused_selectors) == REQUIRED_SELECTORS
        and focused_log_names == {
            f"{selector}.log" for selector in REQUIRED_SELECTORS
        }
        and all(
            item["passed"] > 0
            and item["failed"] == 0
            and item["exit"] == 0
            and item["logPresent"] is True
            and item["logCountMatches"] is True
            for item in focused
        )
    )

    wave1_pass = wave1_labels and passed_runs(wave1)
    wave2_pass = wave2_labels and passed_runs(wave2)
    wave3_pass = wave3_labels and passed_runs(wave3)
    deterministic = bool(
        determinism_labels
        and passed_runs([deterministic_a, deterministic_b])
        and deterministic_a.get("semanticState")
        and deterministic_a.get("semanticState") == deterministic_b.get("semanticState")
    )
    checkpoint_pass = (
        checkpoint_labels
        and passed_runs([checkpoint])
        and checkpoint.get("checkpointAudit", {}).get("valid") is True
    )
    stress_pass = stress_labels and passed_runs(stress)
    wave1_state = aggregate_result_state(
        wave1, passed=wave1_pass, additional_failure=not wave1_labels
    )
    wave2_state = aggregate_result_state(
        wave2, passed=wave2_pass, additional_failure=not wave2_labels
    )
    wave3_state = aggregate_result_state(
        wave3, passed=wave3_pass, additional_failure=not wave3_labels
    )
    determinism_state = aggregate_result_state(
        [deterministic_a, deterministic_b],
        passed=deterministic,
        additional_failure=(
            determinism_labels
            and passed_runs([deterministic_a, deterministic_b])
            and not deterministic
        ),
    )
    checkpoint_state = aggregate_result_state(
        [checkpoint],
        passed=checkpoint_pass,
        additional_failure=(
            checkpoint_labels
            and passed_runs([checkpoint])
            and checkpoint.get("checkpointAudit", {}).get("valid") is not True
        ),
    )
    stress_state = aggregate_result_state(
        stress, passed=stress_pass, additional_failure=not stress_labels
    )
    dry_run_path = root / "live" / "dry-run.log"
    try:
        dry_run_raw = dry_run_path.read_bytes()
    except OSError:
        dry_run_raw = b""
    dry_run_text = dry_run_raw.decode(errors="replace")
    dry_run_checks = {
        "logPresent": dry_run_path.is_file() and bool(dry_run_raw),
        "scenarioExact": "Scenario: gate-b-passive" in dry_run_text,
        "seedExact": "Fixed seed: 46" in dry_run_text,
        "playerInputProofEnabled": (
            "PEBBLELAB_PASSIVE_OBSERVER_INPUT_PROOF=1" in dry_run_text
        ),
        "dryRunDidNotLaunch": (
            "DRY RUN: Pebble was not launched and no directory was created."
            in dry_run_text
        ),
    }
    dry_run_pass = all(dry_run_checks.values())
    dry_run_evidence = {
        "path": str(dry_run_path),
        "sha256": sha256_bytes(dry_run_raw) if dry_run_raw else None,
        "checks": dry_run_checks,
        "result": "PASS" if dry_run_pass else "FAIL",
    }
    live_pass = (
        dry_run_pass
        and
        live_labels
        and live.get("result") == "PASS"
        and live.get("evidenceIntegrity", {}).get("valid") is True
        and isinstance(live.get("checks"), dict)
        and bool(live["checks"])
        and all(check is True for check in live["checks"].values())
    )
    live_state = aggregate_result_state(
        [live],
        passed=live_pass,
        additional_failure=(
            live.get("result") != "NOT_RUN"
            and (not live_labels or not dry_run_pass)
        ),
    )
    focused_state = (
        "PASS" if focused_pass
        else ("NOT_RUN" if not focused_path.exists() else "HARNESS_INVALID")
    )

    full_gate_path = root / "summary" / "full-gate.json"
    try:
        full_gate = json.loads(full_gate_path.read_text())
    except (OSError, ValueError, json.JSONDecodeError):
        full_gate = {
            "exit": -1, "steps": "unknown", "passed": 0, "failed": -1,
        }
    if not isinstance(full_gate, dict):
        full_gate = {
            "exit": -1, "steps": "unknown", "passed": 0, "failed": -1,
        }
    full_gate_log_path = root / "summary" / "full-gate.log"
    try:
        full_gate_log_raw = full_gate_log_path.read_bytes()
    except OSError:
        full_gate_log_raw = b""
    full_gate_log_text = full_gate_log_raw.decode(errors="replace")
    full_gate_log_counts = re.findall(
        r"^([0-9]+) passed, ([0-9]+) failed$",
        full_gate_log_text,
        flags=re.MULTILINE,
    )
    full_gate_log_linked = (
        full_gate_log_path.is_file()
        and bool(full_gate_log_raw)
        and bool(full_gate_log_counts)
        and integer(full_gate_log_counts[-1][0], -1) == full_gate.get("passed")
        and integer(full_gate_log_counts[-1][1], -1) == full_gate.get("failed")
        and "PASS: all 35 PebbleLab verification steps succeeded."
        in full_gate_log_text
    )
    full_gate = {
        **full_gate,
        "logPath": str(full_gate_log_path),
        "logSHA256": (
            sha256_bytes(full_gate_log_raw) if full_gate_log_raw else None
        ),
        "logLinked": full_gate_log_linked,
    }
    full_gate_pass = (
        full_gate.get("baseline") == 3187
        and integer(full_gate.get("newChecks"), -1) > 0
        and full_gate.get("removedOrReplacedChecks") == 0
        and full_gate.get("expected") == args.expected_checks
        and args.expected_checks == (
            full_gate.get("baseline", 0) + full_gate.get("newChecks", 0)
        )
        and full_gate.get("exit") == 0
        and full_gate.get("steps") == "35/35"
        and full_gate.get("failed") == 0
        and full_gate.get("passed") == args.expected_checks
        and full_gate_log_linked
    )

    configuration_path = root / "configuration.json"
    try:
        configuration = json.loads(configuration_path.read_text())
    except (OSError, ValueError, json.JSONDecodeError):
        configuration = {}
    if not isinstance(configuration, dict):
        configuration = {}
    configuration_checks = {
        "rootBoundToHead": (
            root.name == f"PebbleLab-GateB-Convergence01-{args.head}"
        ),
        "headMatches": configuration.get("head") == args.head,
        "branchMatches": configuration.get("branch") == "lab/pebblelab-v1",
        "digestMatches": (
            configuration.get("configurationDigest") == args.configuration_digest
        ),
        "fixedSeedsExact": configuration.get("fixedSeeds") == FIXED_SEEDS,
        "randomTickSpeedExact": configuration.get("randomTickSpeed") == 3,
        "cognitiveFrequencyExact": (
            configuration.get("campaignCognitiveHz") == 80
        ),
        "rerollsZero": configuration.get("rerolls") == 0,
        "productiveCommandsZero": (
            configuration.get("postBootstrapProductiveCommands") == 0
        ),
        "gateBNotAcquired": (
            configuration.get("gateBCanonicallyAcquired") is False
        ),
        "civ26NotStarted": configuration.get("civ26Started") is False,
        "waveMatrixExact": configuration.get("waves") == {
            "wave1": {"ticks": 128},
            "wave2": {"ticks": 800},
            "wave3": {"seeds": MEDIUM_SEEDS, "ticks": 2400},
            "determinism": {"seed": 509, "ticks": 1600, "runs": 2},
            "checkpoint": {"seed": 887, "saveTick": 1200, "ticks": 2400},
            "stress": {"seeds": STRESS_SEEDS, "shockTick": 3200, "ticks": 3600},
            "live": {"seconds": 120},
        },
    }
    configuration_pass = all(configuration_checks.values())

    all_runs = (
        wave1 + wave2 + wave3
        + [deterministic_a, deterministic_b, checkpoint]
        + stress
    )
    role_evidence_valid = all(
        value.get("evidenceIntegrity", {}).get("valid") is True
        for value in all_runs
    ) and live.get("evidenceIntegrity", {}).get("valid") is True
    role_assignments_zero = all(
        value.get("roleNeutralityAudit", {}).get("allAssignmentsZero") is True
        for value in all_runs
    ) and live.get("roleNeutralityAudit", {}).get("allAssignmentsZero") is True
    role_kits_bounded = all(
        value.get("roleNeutralityAudit", {}).get(
            "identicalBoundedPhysicalKits"
        ) is True
        for value in all_runs
    ) and live.get("roleNeutralityAudit", {}).get(
        "identicalBoundedPhysicalKits"
    ) is True
    role_commands_zero = all(
        value.get("roleNeutralityAudit", {}).get(
            "productiveCommandsZero"
        ) is True
        for value in all_runs
    ) and live.get("roleNeutralityAudit", {}).get(
        "productiveCommandsZero"
    ) is True
    role_neutral = (
        bool(all_runs)
        and role_evidence_valid
        and role_assignments_zero
        and role_kits_bounded
        and role_commands_zero
    )
    runtime_movement = all(
        value.get("evidenceIntegrity", {}).get("valid") is True
        and value.get("convergenceChecks", {}).get("movementEnabled") is True
        and value.get("convergenceChecks", {}).get(
            "distanceHomeBypassAbsent"
        ) is True
        for value in all_runs
    ) and (
        live.get("evidenceIntegrity", {}).get("valid") is True
        and live.get("checks", {}).get("movementStayedEnabled") is True
        and live.get("checks", {}).get("distanceHomeBypassAbsent") is True
    ) and bool(all_runs)

    gate_r_path = Path(args.gate_r_evidence) if args.gate_r_evidence else (
        root / "summary" / "gate-r.json"
    )
    gate_r_audit, gate_r_pass = load_audit_proof(
        gate_r_path, head=args.head, required_checks=GATE_R_CHECKS
    )
    movement_path = (
        Path(args.movement_audit_evidence)
        if args.movement_audit_evidence
        else root / "summary" / "movement-audit.json"
    )
    movement_source_audit, movement_source_pass = load_audit_proof(
        movement_path, head=args.head, required_checks=MOVEMENT_AUDIT_CHECKS
    )
    movement = runtime_movement and movement_source_pass

    churn_runs = (
        wave2 + wave3 + [deterministic_a, deterministic_b, checkpoint] + stress
    )
    churn_pass = bool(churn_runs) and all(
        value.get("evidenceIntegrity", {}).get("valid") is True
        and value.get("churnAudit", {}).get("valid") is True
        and value.get("churnAudit", {}).get("blocking") is False
        for value in churn_runs
    )
    bounds_pass = bool(churn_runs) and all(
        value.get("evidenceIntegrity", {}).get("valid") is True
        and value.get("boundsAudit", {}).get("valid") is True
        for value in churn_runs
    )

    discovered = list(args.discovered_blocker)
    corrected = list(args.corrected_blocker)
    remaining = list(args.remaining_blocker)
    discovered_set = set(discovered)
    corrected_set = set(corrected)
    remaining_set = set(remaining)
    product_corrected = corrected_set - HARNESS_BLOCKERS
    product_discovered = discovered_set - HARNESS_BLOCKERS
    blocker_ledger_checks = {
        "identifiersUnique": (
            len(discovered) == len(discovered_set)
            and len(corrected) == len(corrected_set)
            and len(remaining) == len(remaining_set)
        ),
        "identifiersWellFormed": all(
            value.startswith("B-BLOCKER-")
            for value in discovered_set | corrected_set | remaining_set
        ),
        "requiredBlockersRecorded": (
            REQUIRED_BLOCKERS.issubset(discovered_set)
            and REQUIRED_BLOCKERS.issubset(corrected_set)
        ),
        "correctedAndRemainingPartitionDiscovered": (
            corrected_set.isdisjoint(remaining_set)
            and corrected_set | remaining_set == discovered_set
        ),
        "productCorrectionCountMatches": (
            args.product_corrections == len(product_corrected)
        ),
        "harnessGroupExactlyOne": (
            corrected_set & HARNESS_BLOCKERS == HARNESS_BLOCKERS
        ),
        "productBlockerBudgetAtMostFour": len(product_discovered) <= 4,
        "productCorrectionBudgetAtMostFour": (
            0 <= args.product_corrections <= 4
        ),
    }
    blocker_ledger_pass = all(blocker_ledger_checks.values())

    wave0 = focused_pass
    convergence_readiness_checks = {
        "configurationBoundToFinalHead": configuration_pass,
        "blockerLedgerConsistent": blocker_ledger_pass,
        "wave0Focused": wave0,
        "wave1AllTenSeeds128": wave1_pass,
        "wave2AllTenSeeds800": wave2_pass,
        "wave3MediumSeeds2400": wave3_pass,
        "seed509DeterministicRepeat": deterministic,
        "seed887CheckpointReconciliation": checkpoint_pass,
        "stress2593And4099": stress_pass,
        "liveTwoMinutePreflight": live_pass,
        "roleNeutralBootstrap": role_neutral,
        "movementHomeIntegration": movement,
        "churnAcceptable": churn_pass,
        "boundsValid": bounds_pass,
        "gateR": gate_r_pass,
        "fullCanonicalGate": full_gate_pass,
    }
    unclassified_convergence_failures: list[str] = []

    def record_unclassified_failure(value: str) -> None:
        if value not in unclassified_convergence_failures:
            unclassified_convergence_failures.append(value)

    for check, passed in convergence_readiness_checks.items():
        if not passed:
            record_unclassified_failure(f"readinessCheck:{check}")
    for value in all_runs + [live]:
        result_passed = (
            value.get("convergenceResult") == "PASS"
            if "convergenceResult" in value
            else value.get("result") == "PASS"
        )
        if result_passed:
            continue
        wave = value.get("wave", "unknown")
        seed = value.get("seed", "unknown")
        identity = f"{wave}:seed-{seed}"
        failed_checks = value.get(
            "failedConvergenceChecks", value.get("failedChecks", [])
        )
        if isinstance(failed_checks, list):
            for check in failed_checks:
                record_unclassified_failure(
                    f"run:{identity}:failedCheck:{check}"
                )
        primary_failure = value.get("primaryFailure")
        if (
            primary_failure is not None
            and primary_failure not in ("", "none")
        ):
            record_unclassified_failure(
                f"run:{identity}:primaryFailure:{primary_failure}"
            )

    inferred_remaining = (
        ["B-BLOCKER-UNCLASSIFIED-CONVERGENCE-FAILURE"]
        if unclassified_convergence_failures else []
    )
    effective_remaining = remaining + [
        blocker for blocker in inferred_remaining if blocker not in remaining_set
    ]
    no_remaining_blockers = not effective_remaining
    readiness_checks = {
        "configurationBoundToFinalHead": configuration_pass,
        "blockerLedgerConsistent": blocker_ledger_pass,
        "noRemainingBlockers": no_remaining_blockers,
        **{
            key: value for key, value in convergence_readiness_checks.items()
            if key not in {
                "configurationBoundToFinalHead", "blockerLedgerConsistent"
            }
        },
    }
    ready = all(readiness_checks.values())
    summary = {
        "schemaVersion": 2,
        "mission": "GATE-B-CONVERGENCE-01",
        "head": args.head,
        "configurationDigest": args.configuration_digest,
        "fixedSeeds": FIXED_SEEDS,
        "configurationAudit": {
            "path": str(configuration_path),
            "checks": configuration_checks,
            "result": "PASS" if configuration_pass else "FAIL",
        },
        "rerolls": configuration.get("rerolls"),
        "blockersDiscovered": discovered,
        "blockersCorrected": corrected,
        "declaredRemainingBlockers": remaining,
        "remainingBlockers": effective_remaining,
        "unclassifiedConvergenceFailures": unclassified_convergence_failures,
        "blockerLedger": {
            "checks": blocker_ledger_checks,
            "productBlockersDiscovered": sorted(product_discovered),
            "productBlockersCorrected": sorted(product_corrected),
            "harnessBlockersCorrected": sorted(
                corrected_set & HARNESS_BLOCKERS
            ),
            "result": "PASS" if blocker_ledger_pass else "FAIL",
        },
        "correctionBudget": {
            "maximumProductCorrections": 4,
            "usedProductCorrections": args.product_corrections,
            "remainingProductCorrections": max(0, 4 - args.product_corrections),
            "acceptanceHarnessGroupsUsed": 1,
            "maximumCommits": 6,
            "withinBudget": (
                blocker_ledger_checks["productBlockerBudgetAtMostFour"]
                and blocker_ledger_checks["productCorrectionBudgetAtMostFour"]
            ),
        },
        "waves": {
            "wave0": {"result": focused_state, "focused": focused},
            "wave1": {
                "result": wave1_state,
                "labelsExact": wave1_labels,
                "runs": wave1,
            },
            "wave2": {
                "result": wave2_state,
                "labelsExact": wave2_labels,
                "runs": wave2,
            },
            "wave3": {
                "result": wave3_state,
                "labelsExact": wave3_labels,
                "runs": wave3,
            },
            "determinism": {
                "result": determinism_state,
                "labelsExact": determinism_labels,
                "runA": deterministic_a,
                "runB": deterministic_b,
                "semanticEquality": deterministic,
            },
            "checkpoint": {
                "result": checkpoint_state,
                "labelsExact": checkpoint_labels,
                "run": checkpoint,
            },
            "stress": {
                "result": stress_state,
                "labelsExact": stress_labels,
                "runs": stress,
            },
            "live": {
                "result": live_state,
                "labelsExact": live_labels,
                "dryRun": dry_run_evidence,
                "run": live,
            },
        },
        "roleNeutralityAudit": {
            "result": "PASS" if role_neutral else "FAIL",
            "evidenceValid": role_evidence_valid,
            "allAssignmentsZero": role_assignments_zero,
            "identicalBoundedPhysicalKits": role_kits_bounded,
            "productiveCommandsZero": role_commands_zero,
        },
        "movementPolicyAudit": {
            "result": "PASS" if movement else "FAIL",
            "runtimeEvidencePass": runtime_movement,
            "sourceContractEvidence": movement_source_audit,
            "movementRemainedEnabled": (
                True if runtime_movement else None
            ),
            "distanceHomeBypassUsed": (
                False if movement else None
            ),
            "teleportOrSetPosWorkaroundUsed": (
                False if movement else None
            ),
        },
        "churnAnalysis": {
            "result": "PASS" if churn_pass else "FAIL",
            "runs": [{
                "seed": value.get("seed"),
                "wave": value.get("wave"),
                "audit": value.get("churnAudit"),
            } for value in churn_runs],
        },
        "boundsAudit": {
            "result": "PASS" if bounds_pass else "FAIL",
            "runs": [{
                "seed": value.get("seed"),
                "wave": value.get("wave"),
                "audit": value.get("boundsAudit"),
            } for value in churn_runs],
        },
        "determinism": {
            "seed": 509,
            "semanticEquality": deterministic,
        },
        "checkpoint": {
            "seed": 887,
            "savedLoadedContinued": checkpoint_pass,
        },
        "stress": {
            "seeds": STRESS_SEEDS,
            "result": "PASS" if stress_pass else "FAIL",
        },
        "live": {
            "targetSeconds": 120,
            "dryRun": dry_run_evidence,
            "result": "PASS" if live_pass else "FAIL",
        },
        "canonicalGate": full_gate,
        "gateRAudit": gate_r_audit,
        "readinessChecks": readiness_checks,
        "readinessVerdict": (
            "READY FOR GATE B RE-EVALUATION #5"
            if ready else "NOT READY FOR GATE B RE-EVALUATION #5"
        ),
        "gateR": "ACQUIRED" if gate_r_pass else "UNPROVEN_OR_REGRESSED",
        "gateBCanonicallyAcquired": False,
        "civ26Started": False,
        "pushAttempted": False,
    }
    write_json(Path(args.output), summary)


def self_test() -> None:
    checks = {"contract": True}
    assertions = {
        "pass": classified_result(checks) == "PASS",
        "fail": classified_result({"contract": False}) == "FAIL",
        "notReached": (
            classified_result(checks, reached=False) == "NOT_REACHED"
        ),
        "harnessInvalid": (
            classified_result(checks, harness_invalid=True)
            == "HARNESS_INVALID"
        ),
        "timeout": (
            classified_result(
                checks,
                timeout=True,
                harness_invalid=True,
                reached=False,
            ) == "TIMEOUT"
        ),
        "semanticMissingFieldsRejected": (
            parse_semantic(
                ["[lab-live] GATE_B_CONVERGENCE_SEMANTIC tick=1"],
                1,
            )[1]["valid"] is False
        ),
    }
    with tempfile.TemporaryDirectory() as directory:
        not_run = exact_result(
            Path(directory),
            "wave1-128",
            "seed-46",
            head="0" * 40,
            configuration_digest="1" * 64,
            seed=46,
            horizon=128,
            wave="wave1-128",
        )
        assertions["notRun"] = (
            not_run.get("convergenceResult") == "NOT_RUN"
        )
    result = {
        "schemaVersion": 1,
        "resultStates": sorted(RESULT_STATES),
        "checks": assertions,
        "result": "PASS" if all(assertions.values()) else "FAIL",
    }
    print(json.dumps(result, indent=2, sort_keys=True))
    if result["result"] != "PASS":
        raise SystemExit(1)


def parser() -> argparse.ArgumentParser:
    top = argparse.ArgumentParser()
    sub = top.add_subparsers(dest="command", required=True)

    run = sub.add_parser("run")
    run.add_argument("--base-result", required=True)
    run.add_argument("--log", required=True)
    run.add_argument("--output", required=True)
    run.add_argument("--wave", required=True)
    run.add_argument("--head", required=True)
    run.add_argument("--seed", type=int, required=True)
    run.add_argument("--horizon", type=int, required=True)
    run.add_argument("--configuration-digest", required=True)

    live = sub.add_parser("live")
    live.add_argument("--head", required=True)
    live.add_argument("--elapsed-seconds", type=int, required=True)
    live.add_argument("--app-exit", type=int, required=True)
    live.add_argument("--log", required=True)
    live.add_argument("--capture-directory", required=True)
    live.add_argument("--output", required=True)

    summary = sub.add_parser("aggregate")
    summary.add_argument("--head", required=True)
    summary.add_argument("--root", required=True)
    summary.add_argument("--configuration-digest", required=True)
    summary.add_argument("--expected-checks", type=int, required=True)
    summary.add_argument("--product-corrections", type=int, required=True)
    summary.add_argument("--discovered-blocker", action="append", default=[])
    summary.add_argument("--corrected-blocker", action="append", default=[])
    summary.add_argument("--remaining-blocker", action="append", default=[])
    summary.add_argument("--gate-r-evidence")
    summary.add_argument("--movement-audit-evidence")
    summary.add_argument("--output", required=True)
    sub.add_parser("self-test")
    return top


if __name__ == "__main__":
    arguments = parser().parse_args()
    if arguments.command == "run":
        augment_run(arguments)
    elif arguments.command == "live":
        parse_live(arguments)
    elif arguments.command == "aggregate":
        aggregate(arguments)
    else:
        self_test()
