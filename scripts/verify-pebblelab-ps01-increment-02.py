#!/usr/bin/env python3
"""Natural-World PS01 Increment 02 terminal-population live campaign."""

import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess


ROOT = Path(__file__).resolve().parent.parent
BASELINE = "7f732c320bb5685bed436868367ce2fb10385953"
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
        "SCALE",
        "AUTONOMOUS_CIVILIZATION",
    ]
]


def command_plan(count: int):
    before = (
        f"/lab start founders {count};/lab pause;/lab movement off;"
        "/lab follow off;/lab overlay full;/lab observer open;"
        "/lab observer global;/lab mortality status;/lab status"
    )
    terminal = ";".join(["/lab step"] * 23)
    terminal += (
        ";/lab mortality status;/lab population status;"
        "/lab homeostasis status;/lab exits status;/lab observer status;"
        "/lab checkpoint save extinction"
    )
    restored = (
        "/lab checkpoint load extinction;/lab mortality status;"
        "/lab observer status;/lab step;/lab mortality status;/lab status"
    )
    cleanup = "/lab stop;/lab status"
    return "|".join([before, terminal, restored, cleanup]), [
        "before.png",
        "extinction.png",
        "restored.png",
    ]


def copy_checkpoint(home: Path, destination: Path) -> dict:
    candidates = list(home.rglob("checkpoints/extinction/session.json"))
    assert len(candidates) == 1, "extinction checkpoint session missing or ambiguous"
    source = candidates[0].parent
    destination.mkdir()
    for filename in ["session.json", "manifest.json"]:
        shutil.copy2(source / filename, destination / filename)
    return json.loads((destination / "session.json").read_text())["durableState"]


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
                    "civilizationSteps": 23,
                    "foodProvisioned": 0,
                    "physiologyOverrides": 0,
                    "terrainMutations": 0,
                    "disposableProofFlag": False,
                    "checkpoint": "save extinction, load extinction, step once",
                },
                indent=2,
            )
        )
        return

    assert args.output, "--output is required"
    output = Path(args.output).resolve()
    assert not output.exists(), f"refusing to overwrite evidence: {output}"
    output.mkdir(parents=True)
    assert (
        subprocess.run(
            ["pgrep", "-x", "Pebble"], stdout=subprocess.DEVNULL
        ).returncode
        == 1
    ), "Pebble already running"
    binary = ROOT / ".build/release/Pebble"
    assert binary.is_file(), "Build first: swift build -c release --product Pebble"

    results = []
    for name, seed, count in SCENARIOS:
        folder = output / name
        folder.mkdir()
        home = folder / "home"
        home.mkdir()
        commands, capture_names = command_plan(count)
        captures = [folder / name for name in capture_names]
        env = {key: value for key, value in os.environ.items()
               if not key.startswith("PEBBLE")}
        env.update({gate: "1" for gate in ENV_GATES})
        env.update(
            CFFIXED_USER_HOME=str(home),
            PEBBLE_AUTOLOAD="1",
            PEBBLE_NEWWORLD=str(seed),
            PEBBLE_CMD=commands,
            PEBBLE_SHOT="|".join(map(str, captures)) + "|-",
        )
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
                timeout=180,
            )
        text = log_path.read_text()
        assert process.returncode == 0, f"{name}: process exit {process.returncode}"
        assert (
            subprocess.run(
                ["pgrep", "-x", "Pebble"], stdout=subprocess.DEVNULL
            ).returncode
            == 1
        ), f"{name}: Pebble process remains"
        assert "PEBBLELAB_DISPOSABLE_WORLD_PROOF" not in launch
        assert f"sessionAgents={count} worldProbes={count}" in text
        assert re.search(
            rf"founder candidate count={count} .*fullCognition=ALL "
            r"scaling=inactive .*checkpoint=exact",
            text,
        ), f"{name}: normal founder authority missing"
        started = re.search(
            rf"start seed={seed} agents={count} tick=0 .*worldTick=(\d+)", text
        )
        assert started, f"{name}: startup trace missing"
        assert re.search(r"step tick=23", text), f"{name}: tick 23 not committed"
        physical = re.findall(
            r"mortality physical custody tick=23 agent=(agent_\d+) "
            r"kind=verifiedEmpty .*receipt=([^ ]+)",
            text,
        )
        exits = re.findall(
            r"mortality exit tick=23 death=([^ ]+) agent=(agent_\d+) ", text
        )
        assert len(physical) == count, f"{name}: physical exits {len(physical)}"
        assert len({receipt for _, receipt in physical}) == count
        assert len(exits) == count and len({death for death, _ in exits}) == count
        status_pattern = (
            rf"mortality gate=enabled active=yes agents=0 deaths={count} "
            rf"retained={count} evicted=0 .*tick=23 terminal=0 "
            r"members=0 .*probes=0"
        )
        assert len(re.findall(status_pattern, text)) >= 2, (
            f"{name}: extinction/restore mortality status missing"
        )
        assert re.search(
            rf"observer status open=1 view=global .*population=0 .*deaths={count} "
            r".*mutation=none .*digestStable=1",
            text,
        ), f"{name}: Observer extinction missing"
        assert re.search(
            r"checkpoint saved name=extinction .*tick=23 .*restartSafe=1 ", text
        ), f"{name}: extinction checkpoint missing"
        assert re.search(
            r"checkpoint loaded name=extinction .*tick=23 .*probes=0 ", text
        ), f"{name}: extinction restore missing"
        assert re.search(r"step tick=24", text), f"{name}: empty continuation missing"
        assert re.search(
            r"summary reason=stop .*agents=0 .*runtimeErrors=0 .*probesRemoved=0 ",
            text,
        ), f"{name}: final cleanup missing"
        assert "deathsPerTickExceeded" not in text
        assert not re.search(r"runtimeErrors=[1-9]", text)
        assert "CANDIDATE_PHYSICAL_HARD_FAILURE" not in text
        assert all(path.is_file() and path.stat().st_size > 0 for path in captures)

        durable = copy_checkpoint(home, folder / "checkpoint")
        mortality = durable["mortalityState"]
        assert durable["clock"]["tick"] == 23
        assert durable["agents"] == []
        assert durable["populationRegistry"]["members"] == []
        assert mortality["pendingTransitions"] == []
        assert mortality["totalDeathCount"] == count
        assert mortality["configuration"]["maximumDeathsPerTick"] == 30
        assert len(mortality["records"]) == count
        assert {record["deathTick"] for record in mortality["records"]} == {23}
        shutil.rmtree(home)

        result = {
            "name": name,
            "seed": seed,
            "founders": count,
            "exitCode": process.returncode,
            "worldTickAtStartup": int(started.group(1)),
            "civilizationTerminalTick": 23,
            "civilizationPostRestoreTick": 24,
            "livingPopulation": 0,
            "livingProbes": 0,
            "pendingMortality": 0,
            "finalizedDeaths": count,
            "physicalReceipts": count,
            "runtimeErrors": 0,
            "deathsPerTickExceeded": 0,
            "observerLivingPopulation": 0,
            "checkpointRestored": True,
            "normalTerrain": True,
            "foodProvisioned": 0,
            "physiologyOverrides": 0,
            "proofFlag": False,
            "captures": capture_names,
            "status": "PASS",
        }
        results.append(result)
        (output / "results.json").write_text(json.dumps(results, indent=2) + "\n")
        print(f"PASS {name}", flush=True)

    print(f"PASS {len(results)}/{len(SCENARIOS)} normal extinction scenarios")
    print(f"Evidence: {output}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--output")
    run(parser.parse_args())
