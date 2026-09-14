#!/usr/bin/env python3
"""Natural rendered PS01 Increment 03 observer-displacement campaign."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess


ROOT = Path(__file__).resolve().parent.parent
BASELINE = "757cad2742e4b76e13010035f246da1e375a01a4"
SCENARIOS = [
    ("normal-20-seed-46", 46, 20),
    ("normal-24-seed-46", 46, 24),
    ("normal-24-seed-887", 887, 24),
    ("normal-30-seed-887", 887, 30),
]
ENV_GATES = [
    "PEBBLELAB_APP_AGENTS",
    "PEBBLELAB_APP_PROBES",
    "PEBBLELAB_DEBUG_ENTITIES",
] + [
    "PEBBLELAB_APP_AGENTS_" + name
    for name in [
        "MOVE",
        "TRACE",
        "OVERLAY",
        "PERSISTENCE",
        "POPULATION",
        "LIFECYCLE",
        "KINSHIP",
        "HOUSEHOLDS",
        "CARE",
        "CHILDHOOD",
        "FAMILY",
        "MORTALITY",
        "HOMEOSTASIS",
        "GENETICS",
        "OBSERVER",
    ]
]


def command_plan(count: int, default_rate: bool) -> tuple[str, list[str]]:
    start = f"/lab start founders {count};/lab overlay full"
    if not default_rate:
        start += ";/lab speed 1"
    commands = "|".join(
        [
            start,
            "/lab status",
            "/tp ~512 top ~",
            "/lab status",
            "/tp ~-512 top ~",
            "/lab status",
        ]
    )
    shots = ["-", "near.png", "-", "far.png", "-", "returned.png"]
    return commands, shots


def parse_evidence(text: str) -> dict[str, dict[str, str]]:
    evidence = {}
    for line in text.splitlines():
        if not line.startswith("[ps01-i03-live] "):
            continue
        payload = line[len("[ps01-i03-live] "):]
        fields = dict(
            token.split("=", 1)
            for token in payload.split()
            if "=" in token
        )
        evidence[fields["phase"]] = fields
    return evidence


def integer(fields: dict[str, str], name: str) -> int:
    return int(fields[name].split(":", 1)[0])


def run(args: argparse.Namespace) -> None:
    assert "PEBBLE_REGOLD" not in os.environ, "PEBBLE_REGOLD must be absent"
    subprocess.run(
        ["git", "merge-base", "--is-ancestor", BASELINE, "HEAD"],
        cwd=ROOT,
        check=True,
    )
    if args.dry_run:
        print(
            json.dumps(
                {
                    "baselineAncestor": BASELINE,
                    "scenarios": SCENARIOS,
                    "normalProductCommand": "/lab start founders <20|24|30>",
                    "observerPath": "near, +512 x, remain remote, -512 x",
                    "cognitiveRate": "default 4 Hz" if args.default_rate else "1 Hz stress",
                    "resourceProvisioning": 0,
                    "terrainMutations": 0,
                    "physiologyOverrides": 0,
                    "disposableProofFlag": False,
                    "captures": ["near", "far", "returned"],
                },
                indent=2,
            )
        )
        return

    assert args.output, "--output is required"
    output = Path(args.output).resolve()
    assert not output.exists(), f"refusing to overwrite evidence: {output}"
    output.mkdir(parents=True)
    assert subprocess.run(
        ["pgrep", "-x", "Pebble"], stdout=subprocess.DEVNULL
    ).returncode == 1, "Pebble already running"
    binary = ROOT / ".build/release/Pebble"
    assert binary.is_file(), "Build first: swift build -c release --product Pebble"

    results = []
    for name, seed, count in SCENARIOS:
        folder = output / name
        folder.mkdir()
        home = folder / "home"
        home.mkdir()
        commands, shot_names = command_plan(count, args.default_rate)
        shot_paths = [
            "-" if item == "-" else str(folder / item)
            for item in shot_names
        ]
        env = {
            key: value for key, value in os.environ.items()
            if not key.startswith("PEBBLE")
        }
        env.update({gate: "1" for gate in ENV_GATES})
        env.update(
            CFFIXED_USER_HOME=str(home),
            PEBBLE_AUTOLOAD="1",
            PEBBLE_NEWWORLD=str(seed),
            PEBBLE_CMD=commands,
            PEBBLE_SHOT="|".join(shot_paths),
            PEBBLELAB_PS01_INCREMENT03_LIVE_PROOF="1",
        )
        if args.default_rate:
            env["PEBBLELAB_PS01_INCREMENT03_BATCH_FRAMES"] = "60"
        launch = {
            key: env[key]
            for key in env
            if key.startswith("PEBBLE") or key == "CFFIXED_USER_HOME"
        }
        (folder / "launch.json").write_text(
            json.dumps(launch, indent=2) + "\n"
        )
        print(f"Running {name} seed={seed} founders={count}", flush=True)
        log_path = folder / "complete.log"
        with log_path.open("w") as log:
            process = subprocess.run(
                [str(binary)],
                cwd=ROOT,
                env=env,
                stdout=log,
                stderr=subprocess.STDOUT,
                timeout=240,
            )
        text = log_path.read_text()
        assert process.returncode == 0, f"{name}: process exit {process.returncode}"
        assert subprocess.run(
            ["pgrep", "-x", "Pebble"], stdout=subprocess.DEVNULL
        ).returncode == 1, f"{name}: Pebble process remains"
        assert "PEBBLELAB_DISPOSABLE_WORLD_PROOF" not in launch
        assert f"sessionAgents={count} worldProbes={count}" in text
        assert f"start seed={seed} agents={count} tick=0" in text
        if args.default_rate:
            assert re.search(
                rf"start seed={seed} agents={count} tick=0 hz=4 ", text
            ), f"{name}: default 4 Hz start missing"
            assert "speed set" not in text
        else:
            assert re.search(
                rf"start seed={seed} agents={count} tick=0 hz=4 ", text
            ), f"{name}: normal 4 Hz start missing"
            assert re.search(
                r"status PebbleAgents running tick=\d+ hz=1 ", text
            ), f"{name}: explicit 1 Hz stress rate missing"
        assert "CANDIDATE_PHYSICAL_HARD_FAILURE" not in text
        assert not re.search(r"runtimeErrors=[1-9]", text)

        evidence = parse_evidence(text)
        required = ["near", "far", "return-stable"]
        assert all(phase in evidence for phase in required), (
            f"{name}: missing phase evidence {sorted(evidence)}"
        )
        for phase in required:
            fields = evidence[phase]
            assert fields["coverage"] == "ready", f"{name}: {phase} not ready"
            assert integer(fields, "population") == count
            assert integer(fields, "probes") == count
            assert integer(fields, "roots") == count
            assert integer(fields, "ready") == integer(fields, "chunks")
            assert integer(fields, "pending") == 0
            assert integer(fields, "refused") == 0
            assert integer(fields, "rootAgreement") == 1
            assert integer(fields, "sensorReady") == count
            assert integer(fields, "sensorUnavailable") == 0
            assert integer(fields, "pathReady") == count
            assert integer(fields, "pathUnavailable") == 0
            assert integer(fields, "runtimeErrors") == 0
            assert integer(fields, "hardFailure") == 0
            assert fields["lastError"] == "none"
            assert fields["coverageDigest"] != "none"
            assert fields["physicalDigest"] != "none"
            assert fields["civDigest"] != "none"
        near, far, returned = (evidence[phase] for phase in required)
        departed = evidence["departed"]
        assert integer(near, "nearestRootChunks") <= 1
        assert integer(far, "nearestRootChunks") > 6
        assert integer(returned, "nearestRootChunks") <= 1
        assert integer(far, "probeTicks") > integer(near, "probeTicks")
        assert integer(returned, "probeTicks") > integer(far, "probeTicks")
        assert near["coverageDigest"] == far["coverageDigest"]
        assert far["coverageDigest"] == returned["coverageDigest"]
        assert near["convergence"].split(":", 1)[0] != "pending"
        remote_world_ticks = integer(far, "worldTick") - integer(
            departed, "worldTick"
        )
        assert remote_world_ticks > 0

        captures = [folder / item for item in shot_names if item != "-"]
        assert all(path.is_file() and path.stat().st_size > 0 for path in captures)
        assert all(path.read_bytes()[:8] == b"\x89PNG\r\n\x1a\n" for path in captures)
        result = {
            "name": name,
            "seed": seed,
            "founders": count,
            "exitCode": process.returncode,
            "resourceProvisioning": 0,
            "terrainMutations": 0,
            "physiologyOverrides": 0,
            "disposableWorldProofFlag": False,
            "evidenceCollector": True,
            "cognitiveHz": 4 if args.default_rate else 1,
            "remoteWorldTicks": remote_world_ticks,
            "near": near,
            "far": far,
            "returned": returned,
            "captures": [path.name for path in captures],
            "status": "PASS",
        }
        results.append(result)
        (output / "results.json").write_text(
            json.dumps(results, indent=2) + "\n"
        )
        shutil.rmtree(home)
        print(f"PASS {name}", flush=True)

    print(f"PASS {len(results)}/{len(SCENARIOS)} normal rendered scenarios")
    print(f"Evidence: {output}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--output")
    parser.add_argument("--default-rate", action="store_true")
    run(parser.parse_args())
