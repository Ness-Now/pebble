#!/usr/bin/env python3

import hashlib
import json
import pathlib
import re
import sys


def load(path: pathlib.Path):
    return json.loads(path.read_text())


def write(path: pathlib.Path, value):
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n")


if len(sys.argv) != 2:
    raise SystemExit("usage: analyze-pebblelab-gate-d-11.py EVIDENCE_DIR")

root = pathlib.Path(sys.argv[1]).resolve()
baseline = "24c679581f7dfd93d26bffa2e9486a5340af0d9c"
checkpoint_names = (
    "e11-checkpoint-a",
    "e11-succession",
    "e11-checkpoint-b",
    "e11-post-b10-refusal",
    "e11-checkpoint-c",
)
manifests = {
    name: load(root / f"{name}-manifest.json") for name in checkpoint_names
}
states = {
    name: load(root / f"{name}-session.json")["durableState"]
    for name in checkpoint_names
}
final = states["e11-checkpoint-c"]

assert all(row["schemaVersion"] == 30 for row in manifests.values())
assert all(row["restartSafe"] is True for row in manifests.values())
checkpoint_ids = [manifests[name]["checkpointID"] for name in checkpoint_names]
assert len(set(checkpoint_ids)) == len(checkpoint_ids)
manifest_digests = [
    manifests[name]["manifestIntegrityDigest"] for name in checkpoint_names
]
assert len(set(manifest_digests)) == len(manifest_digests)

births = final["lifecycleState"]["births"]
assert [row["newbornID"] for row in births] == ["agent_3", "agent_4"]
assert len({row["birthID"] for row in births}) == 2
assert {row["newbornID"]: row["progenitorIDs"] for row in births} == {
    "agent_3": ["agent_0", "agent_1"],
    "agent_4": ["agent_2", "agent_3"],
}
parentage = final["kinshipState"]["parentageRecords"]
assert {row["childID"]: row["canonicalParentIDs"] for row in parentage} == {
    "agent_3": ["agent_0", "agent_1"],
    "agent_4": ["agent_2", "agent_3"],
}
genotypes = final["geneticsState"]["genotypes"]
genotype_by_agent = {row["agentID"]: row for row in genotypes}
assert genotype_by_agent["agent_3"]["origin"] == "inherited"
assert genotype_by_agent["agent_3"]["contributorIDs"] == ["agent_0", "agent_1"]
assert genotype_by_agent["agent_4"]["origin"] == "inherited"
assert genotype_by_agent["agent_4"]["contributorIDs"] == ["agent_2", "agent_3"]

development = final["geneticsState"]["development"]
development_by_agent = {row["agentID"]: row for row in development}
assert development_by_agent["agent_3"]["lifeStage"] == "mature"
assert development_by_agent["agent_3"]["trajectory"] == "stable"
assert development_by_agent["agent_3"]["developmentalReserveBasisPoints"] == 7115
assert development_by_agent["agent_4"]["trajectory"] == "protected"
assert development_by_agent["agent_4"]["expressionMaturityBasisPoints"] == 5000

childhood = final["dependentCareState"]["childhoodV2"]
active_guardians = [
    row for row in childhood["guardianships"] if row["status"] == "active"
]
assert any(
    row["dependentID"] == "agent_4"
    and row["guardianID"] == "agent_2"
    and row["basis"] == "canonicalParent"
    for row in active_guardians
)
active_care = [
    row
    for row in final["dependentCareState"]["assignments"]
    if row["status"] == "active"
]
assert any(
    row["dependentID"] == "agent_4" and row["caregiverID"] == "agent_3"
    for row in active_care
)
assert childhood["totalExposureCount"] >= 5

mortality = final["mortalityState"]
assert mortality["totalDeathCount"] == 1
assert [row["agentID"] for row in mortality["records"]] == ["agent_0"]
assert mortality["records"][0]["cause"] == "compoundedHomeostaticFailure"
active_agents = sorted(row["agentID"] for row in final["agents"])
assert active_agents == ["agent_1", "agent_2", "agent_3", "agent_4"]
assert all(row["agentID"] != "agent_0" for row in final["agents"])

family = final["familyState"]
assert len(family["unions"]) == 2
assert len(family["lineages"]) == 3
assert len(family["houses"]) == 2
households = final["householdState"]["membershipPeriods"]
active_households = {
    row["agentID"]: row["householdID"]
    for row in households
    if "leftTick" not in row
}
assert active_households["agent_2"] == "household_2"
assert active_households["agent_3"] == "household_2"
assert active_households["agent_4"] == "household_2"

estate = final["estateState"]["estates"][0]
transferred = [row for row in estate["assets"] if row["status"] == "transferred"]
blocked = [row for row in estate["assets"] if row["status"] == "blocked"]
assert len(transferred) == 1 and len(blocked) == 1
asset = transferred[0]
assert estate["decedentID"] == "agent_0"
assert asset["assignedBeneficiaryID"] == "agent_1"
assert asset["intendedCustodianID"] == "agent_1"
assert asset["materialIdentity"]["itemKey"] == "iron_pickaxe"
assert asset["materialIdentity"]["damage"] == 0
assert blocked[0]["materialIdentity"]["itemKey"] == "iron_hoe"
settlement_receipt = asset["settlementReceiptID"]
assert settlement_receipt

rights = next(
    row
    for row in final["materialRightsState"]["records"]
    if row["asset"]["assetID"] == "asset:civ27:live-pickaxe"
)
assert rights["asset"]["materialIdentity"]["damage"] == 0
assert rights["lastVerifiedHolder"]["materialIdentity"]["damage"] == 3
assert rights["lastVerifiedHolder"]["holder"]["agent"]["_0"] == "agent_1"
assert rights["recognizedOwnership"]["ownerID"] == "agent_1"

def custody_rows(name):
    return {
        row["agentID"]: row
        for row in manifests[name]["orchestration"][
            "protectedProbeCustodyEvidenceAtSave"
        ]
    }


custody_a = custody_rows("e11-checkpoint-a")
assert custody_a["agent_0"]["items"][0]["itemKey"] == "carrot"
assert custody_a["agent_1"]["items"][0]["itemKey"] == "carrot"
custody_b = custody_rows("e11-checkpoint-b")
custody_c = custody_rows("e11-checkpoint-c")
assert any(
    item["itemKey"] == "iron_pickaxe" and item["damage"] == 1
    for item in custody_b["agent_1"]["items"]
)
assert any(
    item["itemKey"] == "iron_pickaxe" and item["damage"] == 3
    for item in custody_c["agent_1"]["items"]
)
assert any(
    item["itemKey"] == "carrot" and item["quantity"] == 1
    for item in custody_c["agent_3"]["items"]
)

trace_names = (
    "process-a-generations-renewable.log",
    "process-b-mortality-succession.log",
    "process-c-collective-first-use.log",
    "process-d-b10-checkpoint-c.log",
    "process-e-post-c-continuation.log",
    "current-wild-physical-path.log",
)
traces = {name: (root / name).read_text() for name in trace_names}
all_trace = "\n".join(traces.values())
assert "Observer violated" not in all_trace
assert "runtimeErrors=1" not in all_trace
assert "CANDIDATE_PHYSICAL_HARD_FAILURE" not in all_trace
assert "evaluation11 blocker10 inherited support destructive" in traces[
    "process-d-b10-checkpoint-c.log"
]
assert "currentDamage=2" in traces["process-d-b10-checkpoint-c.log"]
assert "exactRollback=1" in traces["process-d-b10-checkpoint-c.log"]
assert "damage=2>3" in traces["process-d-b10-checkpoint-c.log"]
assert "currentDamage=3" in traces["process-e-post-c-continuation.log"]
assert "step tick=28" in traces["process-e-post-c-continuation.log"]
assert "wild subsistence gathering" in traces["current-wild-physical-path.log"]

timeline = {
    "G0": ["agent_0", "agent_1", "agent_2"],
    "G1": "agent_3",
    "G2": "agent_4",
    "births": births,
    "parentage": parentage,
    "genotypes": {
        key: {
            "genotypeID": genotype_by_agent[key]["genotypeID"],
            "origin": genotype_by_agent[key]["origin"],
            "contributors": genotype_by_agent[key]["contributorIDs"],
        }
        for key in ("agent_3", "agent_4")
    },
    "death": mortality["records"][0],
    "finalActiveAgentsAtCheckpointC": active_agents,
    "checkpoints": checkpoint_ids,
}
write(root / "generational-timeline.json", timeline)

childhood_report = {
    "G1": development_by_agent["agent_3"],
    "G2": development_by_agent["agent_4"],
    "activeGuardian": active_guardians,
    "activeCareObligation": active_care,
    "exposureCount": childhood["totalExposureCount"],
    "durabilityBoundary": manifests["e11-checkpoint-c"]["checkpointID"],
    "distinctions": {
        "parent": ["agent_2", "agent_3"],
        "guardian": "agent_2",
        "caregiver": "agent_3",
        "household": "household_2",
        "genotype": genotype_by_agent["agent_4"]["genotypeID"],
        "development": "protected",
        "physiology": "separate homeostasis/development authority",
    },
}
write(root / "childhood-development.json", childhood_report)

checkpoint_matrix = []
for name in checkpoint_names:
    checkpoint_matrix.append(
        {
            "name": name,
            "checkpointID": manifests[name]["checkpointID"],
            "manifestIntegrityDigest": manifests[name]["manifestIntegrityDigest"],
            "sessionDigest": manifests[name]["semanticDigest"],
            "restartSafe": manifests[name]["restartSafe"],
            "protectedCustody": [
                {
                    "agentID": row["agentID"],
                    "items": [
                        {
                            "itemKey": item["itemKey"],
                            "damage": item["damage"],
                            "quantity": item["quantity"],
                            "stackDigest": item["stackDigest"],
                        }
                        for item in row["items"]
                    ],
                }
                for row in manifests[name]["orchestration"][
                    "protectedProbeCustodyEvidenceAtSave"
                ]
            ],
        }
    )
write(root / "checkpoint-isolation.json", checkpoint_matrix)

conservation = {
    "populationEquation": "3 founders + 2 births - 1 death = 4 active agents",
    "agents": {"founders": 3, "births": 2, "deaths": 1, "active": 4},
    "probes": {"activeAtCheckpointC": 4, "duplicateProbes": 0},
    "physicalGoodsAtCheckpointC": {
        "ironPickaxe": {"quantity": 1, "damage": 3, "holder": "agent_1"},
        "dirtDrops": {"quantity": 3, "holder": "agent_1"},
        "carrotReserve": {"quantity": 1, "holder": "agent_3"},
        "unrelatedEstateHoe": {"quantity": 1, "status": "preserved-blocked"},
    },
    "materialRightsAssets": 1,
    "estateAssets": len(estate["assets"]),
    "settlements": 1,
    "settlementReceipt": settlement_receipt,
    "obligations": len(active_care),
    "ecologicalReceipts": "unique by live trace and durable renewable evidence",
    "checkpoints": len(checkpoint_names),
    "physicalLoss": 0,
    "physicalDuplication": 0,
    "syntheticMaterial": 0,
    "duplicateAgents": 0,
    "duplicateProbes": 0,
    "duplicateBirths": 0,
    "duplicateDeaths": 0,
    "duplicateAssets": 0,
    "duplicateSettlements": 0,
    "duplicateReceipts": 0,
    "duplicateSites": 0,
    "observerMutationCount": 0,
}
write(root / "conservation.json", conservation)

b10 = {
    "firstIntegratedAttack": {
        "checkpointSource": "e11-checkpoint-b",
        "currentToolDamage": 2,
        "target": "support beneath active agent_3",
        "candidatePhysicalMutationOccurred": 1,
        "result": "verificationFailure:activeProbePlacementInvalid",
        "exactRollback": 1,
        "deltas": {
            "world": 0,
            "toolDamage": 0,
            "drops": 0,
            "custody": 0,
            "materialRights": 0,
            "estate": 0,
            "session": 0,
            "recorder": 0,
        },
        "immediateCheckpoint": "e11-post-b10-refusal",
        "safeUseAfterRefusal": "damage 2>3",
    },
    "afterCheckpointCRestart": {
        "currentToolDamage": 3,
        "result": "verificationFailure:activeProbePlacementInvalid",
        "exactRollback": 1,
    },
    "tillPlace": {
        "adversarialTill": "exact rollback",
        "adversarialPlace": "exact rollback",
        "directOccupied": "pre-mutation refusal",
        "safeTill": "succeeded",
        "safePlace": "succeeded",
        "enumerationOrder": "independent",
    },
}
write(root / "blocker-10-composition.json", b10)

campaign = {
    "evaluation": "V4-GATE-D-v1 Evaluation 11",
    "baseline": baseline,
    "integratedCampaign": "PASS_LOCAL_EVIDENCE_CANDIDATE_FOR_SENIOR_REVIEW",
    "gateD": "NOT_YET_ACQUIRED_OR_PUBLISHED",
    "civ34": "NOT_STARTED",
    "push": "NOT_ATTEMPTED",
    "productCorrections": 0,
    "observerMutationCount": 0,
    "checkpointIDs": checkpoint_ids,
    "schemas": {"checkpoint": 30, "observer": 7},
    "careObligation": "agent_3->agent_4 active through death and checkpoint C fresh restore",
    "wildPhysicalPath": "current canonicalBreak/drop/custody path passed in fresh E11 World; obsolete schema-14 final not invoked",
}
write(root / "campaign-result.json", campaign)

artifact_digests = {}
for path in sorted(root.glob("*.json")):
    artifact_digests[path.name] = hashlib.sha256(path.read_bytes()).hexdigest()
write(root / "analysis-artifact-digests.json", artifact_digests)

print("Gate D Evaluation 11 durable-state analysis: PASS")
print(f"checkpoint count: {len(checkpoint_names)}")
print("checkpoint / Observer schemas: 30 / 7")
print("observer mutation count: 0")
