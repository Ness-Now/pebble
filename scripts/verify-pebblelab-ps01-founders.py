#!/usr/bin/env python3
"""Bounded natural-World PS01 founder campaign. No terrain or resource fixture."""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent
BASELINE = "196c6f770acc9bb416e04d03f39a7e1191f9329e"
# AGENTS is spelled APP_AGENTS; all dependent domains are explicit launch gates.
ENV_GATES = ["PEBBLELAB_APP_AGENTS", "PEBBLELAB_APP_PROBES", "PEBBLELAB_DEBUG_ENTITIES"] + [
    "PEBBLELAB_APP_AGENTS_" + name for name in [
        "MOVE", "TRACE", "OVERLAY", "PERSISTENCE", "POPULATION", "LIFECYCLE",
        "KINSHIP", "HOUSEHOLDS", "CARE", "CHILDHOOD", "FAMILY", "MORTALITY",
        "HOMEOSTASIS", "GENETICS", "OBSERVER", "SCALE", "AUTONOMOUS_CIVILIZATION",
    ]
]
SCENARIOS = [
    ("normal-24", 46, 24, "", None),
    ("normal-20", 46, 20, "", None),
    ("normal-30", 887, 30, "/tp -64 100 32;/surface|", None),
    ("unavailable", 12345, 24, "/tp 4096 200 4096;", "placement"),
    ("late-probe", 46, 24, "", "probe"),
    ("dependency", 46, 24, "", "dependency"),
    ("legacy-three", 46, 3, "", "legacy"),
] + [("late-" + stage, 46, 24, "", "authority:" + stage) for stage in [
    "population", "lifecycle", "kinship", "household", "dependentCare", "childhood",
    "family", "mortality", "homeostasis", "genetics", "verification",
]]


def run(args):
    assert "PEBBLE_REGOLD" not in os.environ, "PEBBLE_REGOLD must be absent"
    subprocess.run(["git", "merge-base", "--is-ancestor", BASELINE, "HEAD"], cwd=ROOT, check=True)
    if args.dry_run:
        print(json.dumps({"baselineAncestor": BASELINE, "scenarios": SCENARIOS,
                          "terrainMutations": 0, "starterResources": 0,
                          "normalProductCommand": "/lab start founders 24",
                          "normalDisposableProofFlag": False}, indent=2))
        return
    assert args.output, "--output is required"
    output = Path(args.output).resolve()
    output.mkdir(parents=True, exist_ok=True)
    assert subprocess.run(["pgrep", "-x", "Pebble"], stdout=subprocess.DEVNULL).returncode == 1, "Pebble already running"
    binary = ROOT / ".build/release/Pebble"
    assert binary.is_file(), "Build first: swift build -c release --product Pebble"
    results = []
    for name, seed, count, prefix, attack in SCENARIOS:
        folder = output / name
        assert not folder.exists(), f"refusing to overwrite evidence: {folder}"
        folder.mkdir()
        home = folder / "home"
        home.mkdir()
        env = {k: v for k, v in os.environ.items() if not k.startswith("PEBBLE")}
        env.update({k: "1" for k in ENV_GATES})
        env.update(CFFIXED_USER_HOME=str(home), PEBBLE_AUTOLOAD="1", PEBBLE_NEWWORLD=str(seed))
        # No named disposable World: retain the ordinary World rules and terrain.
        # Only fault-injection runs arm the existing disposable proof guards.
        if attack == "probe":
            env["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] = "1"
            env["PEBBLELAB_DISPOSABLE_SAFE_BOOTSTRAP_LATE_FAILURE_PROOF"] = "1"
        if attack and attack.startswith("authority:"):
            env["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] = "1"
            env["PEBBLELAB_DISPOSABLE_FOUNDER_AUTHORITY_FAILURE"] = attack.split(":")[1]
        if attack == "dependency":
            env["PEBBLELAB_APP_AGENTS_KINSHIP"] = "0"
        start = "/lab start" if count == 3 else f"/lab start founders {count}"
        if attack in (None, "legacy"):
            capture = folder / "bootstrap.png"
            observed = folder / "observed.png"
            range_commands = "/lab start founders 19;/lab start founders 31;" if attack is None else ""
            commands = prefix + range_commands + start + ";/lab pause;/lab focus agent_0;/lab follow agent_0;/lab overlay full"
            if attack is None:
                commands += ";/lab observer open;/lab observer global;/lab checkpoint save founders;/lab checkpoint load founders;/lab observer close"
                commands += ";/lab start founders 24"
            commands += "|/lab resume|/lab pause;/lab status;/lab observer status"
            if attack is None:
                commands += ";/lab checkpoint save observed"
            commands += "|/lab stop;/lab status"
            shots = f"{capture}|-|{observed}|-"
            if "|" in prefix:
                shots = "-|" + shots
        else:
            commands = prefix + start + ";/lab status|/lab status"
            shots = "-|-"
        env.update(PEBBLE_CMD=commands, PEBBLE_SHOT=shots)
        (folder / "launch.json").write_text(json.dumps({k: env[k] for k in env if k.startswith("PEBBLE") or k == "CFFIXED_USER_HOME"}, indent=2) + "\n")
        print(f"Running {name} seed={seed} founders={count}", flush=True)
        with (folder / "complete.log").open("w") as log:
            process = subprocess.run([str(binary)], cwd=ROOT, env=env, stdout=log, stderr=subprocess.STDOUT, timeout=180)
        text = (folder / "complete.log").read_text()
        row = {"name": name, "seed": seed, "founders": count, "exitCode": process.returncode,
               "commands": commands, "normalTerrain": True, "proofFlag": bool(attack == "probe" or (attack and attack.startswith("authority:")))}
        results.append(row)
        (output / "results.json").write_text(json.dumps(results, indent=2) + "\n")
        assert process.returncode == 0, f"{name}: process exit {process.returncode}"
        assert subprocess.run(["pgrep", "-x", "Pebble"], stdout=subprocess.DEVNULL).returncode == 1, f"{name}: process remains"
        assert "CANDIDATE_PHYSICAL_HARD_FAILURE" not in text, f"{name}: hard failure"
        assert re.search(r"status inactive gate=enabled", text), f"{name}: inactive boundary missing"
        if attack in (None, "legacy"):
            assert f"sessionAgents={count} worldProbes={count}" in text, f"{name}: publication mismatch"
            assert re.search(rf"summary .*runtimeErrors=0 .*probesRemoved={count} ", text), f"{name}: cleanup/runtime error"
            assert capture.is_file() and observed.is_file(), f"{name}: captures missing"
            assert "bootstrap rollback" not in text and "start failed" not in text, f"{name}: bootstrap error"
            if attack is None:
                candidate = re.search(r"founder candidate count=(\d+) ids=([^ ]+) .*checkpoint=exact digest=([0-9a-f]+)", text)
                assert candidate and int(candidate[1]) == count, f"{name}: cross-domain evidence missing"
                ids = sorted(f"agent_{i}" for i in range(count))
                assert candidate[2].split(",") == ids
                assert "checkpoint loaded" in text and "checkpoint saved" in text, f"{name}: checkpoint proof missing"
                assert "observerMutation=0" in text and "fullCognition=ALL scaling=inactive" in text
                assert re.search(rf"observer .*population={count} .*mutation=none .*digestStable=1", text), f"{name}: Observer population count mismatch"
                assert "normal founders must be 20...30" in text and "Founder start requires an inactive session" in text
                status_rows = re.findall(r"status PebbleAgents .*", text)
                assert status_rows, f"{name}: temporal status missing"
                observations = dict(re.findall(r"(agent_\d+)=[^ ]+/m\d+/o(\d+)", status_rows[-1]))
                assert sorted(observations) == ids and min(map(int, observations.values())) > 0, f"{name}: cognition population mismatch"
                assert len(set(observations.values())) == 1, f"{name}: unequal cognition coverage"
                # Read the ordinary durable checkpoint, not a separate roster.
                checkpoints = {path.parent.name: path for path in home.rglob("session.json")}
                assert "founders" in checkpoints and "observed" in checkpoints
                for checkpoint_name in ["founders", "observed"]:
                    destination = folder / "checkpoints" / checkpoint_name
                    destination.mkdir(parents=True)
                    for filename in ["session.json", "manifest.json"]:
                        shutil.copy2(checkpoints[checkpoint_name].parent / filename, destination / filename)
                durable = json.loads(checkpoints["observed"].read_text())["durableState"]
                agents = durable["agents"]
                durable_ids = [agent["agentID"] for agent in agents]
                assert durable_ids == ids and len(set(durable_ids)) == count
                registry = durable["populationRegistry"]
                assert registry.get("scaleState") is None and len(registry["members"]) == count
                structured_observations = {agent["agentID"]: agent["observationCount"] for agent in agents}
                goal_counts = {agent["goalSelectionCount"] for agent in agents}
                assert structured_observations == {key: int(value) for key, value in observations.items()}
                assert len(goal_counts) == 1 and min(goal_counts) > 0
                row.update(ids=ids, checkpointDigest=candidate[3], observer="exact-read-only", scaling="inactive",
                           perFounderObservations=structured_observations, perFounderGoalSelections=min(goal_counts),
                           cognitionEvidence="ordinary observed checkpoint agents and focused cognitionPerformed results")
        else:
            assert "bootstrap publication status=verified" not in text and "founder candidate" not in text, f"{name}: partial publication"
            if attack == "placement":
                refusal = re.search(r"bootstrap placement status=refused anchor=4096,200,4096 reason=insufficient_safe_positions found=(\d+) required=(\d+) candidates=(\d+)/(\d+) rejections=([^ ]+) session=none probes=0", text)
                assert refusal, f"{name}: measured placement refusal missing"
                found, required, evaluated, maximum = map(int, refusal.groups()[:4])
                assert found < required == count + 1 and 0 < evaluated <= maximum == 12000
                row.update(found=found, required=required, candidatesEvaluated=evaluated,
                           maximumCandidateEvaluations=maximum, rejections=refusal[5])
            else:
                removed = 23 if attack == "probe" else 24
                assert re.search(rf"bootstrap rollback status=verified .*probesRemoved={removed} session=none residual=0", text), f"{name}: rollback missing"
                if attack and attack.startswith("authority:"):
                    assert "injected_founder_authority_failure_after_" + attack.split(":")[1] in text
                row.update(rollback="exact", probesRemoved=removed, residualProbes=0, publishedSession=False)
        row["status"] = "PASS"
        (output / "results.json").write_text(json.dumps(results, indent=2) + "\n")
        print(f"PASS {name}", flush=True)
    print(f"PASS {len(results)}/{len(SCENARIOS)} natural-World founder scenarios", flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--output")
    run(parser.parse_args())
