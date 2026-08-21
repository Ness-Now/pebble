#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
RUNBOOK="$ROOT_DIR/docs/pebblelab-3d-live-prototype.md"
MODE="survival"
WORLD_SEED="12345"

usage() {
    cat <<EOF
Usage: scripts/verify-pebblelab-live.sh [--dry-run] [--survival|--economy|--h2|--natural|--harvest|--construction|--embodiment|--build|--social|--physical|--material|--rights|--production|--barter|--contracts|--markets|--cooperation|--persistence|--population|--multiscale|--ecology|--mortality|--reproduction|--kinship|--households|--care|--skills|--teaching|--integrated-teaching|--ecological-observation|--agriculture|--wild-subsistence|--physical-food-survival|--livestock|--work-professions|--work-demand-refresh|--gate-b-passive]
       scripts/verify-pebblelab-live.sh --help

Launches Pebble for a reproducible, operator-verified Phase J live check. The app is
given an isolated temporary Foundation home, so personal Pebble worlds are not
visible. The existing autoload/new-world hook creates exactly one world with:

  name: ${WORLD_NAME:-PebbleLab-Disposable-<mode>-12345}
  seed: $WORLD_SEED

The launcher reuses Pebble's existing PEBBLE_AUTOLOAD, PEBBLE_NEWWORLD,
PEBBLE_CMD, and PEBBLE_SHOT hooks. PEBBLE_NEWWORLD_NAME is accepted only for a
PebbleLab-Disposable-* name. It does not claim to validate pixels; inspect the
retained trace and capture using $RUNBOOK.

Options:
  --dry-run  Print the environment, commands, and manual steps; do not launch.
  --survival Run the Phase J hunger, consumption, and rest proof (default).
  --economy  Run the preserved Phase I closed-economy proof.
  --h2       Run the preserved H2 navigate-to-harvest proof.
  --natural  Historical alias for the converged CIV-17 harvest proof.
  --harvest  Run CIV-17 real break/drop/custody convergence and rollback proofs.
  --construction Run CIV-18 ordered real-custody placement and rollback proofs.
  --embodiment Run CIV-19 Core navigation, embodiment, reach, and rollback proofs.
  --build    Historical alias for the converged CIV-18 construction proof.
  --social   Run directed grounded information, read-only verification, and trust.
  --physical Run local sound, pointing gesture, imperfect perception, and existing trust.
  --material Run real agent/container custody, transactions, consumption, and CIV-15 seams.
  --rights Run CIV-26 real custody, claims, permissions, transgression, and rollback.
  --production Run CIV-34 real recipes, workshop, custody, restart, and produced-tool use.
  --barter Run CIV-35 local consent, two-sided custody, rollback, restart, and tool use.
  --contracts Run CIV-36 open debt, three-process restart, fulfillment rollback, and exact-once proof.
  --markets Run CIV-37 physical deposits, local price discovery, rollback, restart, and withdrawal.
  --cooperation Run shared construction-material task, delivery, and shelter completion.
  --persistence Run checkpoint, real process restart, causal replay, and uninterrupted control.
  --population Run bounded migrant admission, mid-route restart, arrival, and uninterrupted control.
  --multiscale Run bounded settlement pulses, v3 restart, uninterrupted, and metrics-off controls.
  --ecology Run local forage scarcity, v4 restart, regeneration, and uninterrupted control.
  --mortality Run starvation mortality, v5 pre/post restart, probe exit, and replacement migration.
  --reproduction Run deterministic age, bounded local birth, v6 pre/post restart, and maturity.
  --kinship Run the reproduction workflow with explicit kinship activation and v7 restart.
  --households Run the kinship workflow with explicit household activation and v8 restart.
  --care Run the household workflow with dependent care, material nourishment, and v9 restart.
  --skills Run causal material practice, skill-ranked task matching, v10 restart, and rollback.
  --teaching Run real local demonstration, no-free-skill, guided practice, and distance refusal.
  --integrated-teaching Run normal local apprenticeship initiation and the full real-action Teaching chain.
  --ecological-observation Run bounded real-World ecology, civil calendar, cache, and v12 proof.
  --agriculture Run real wheat till/plant/grow/harvest/storage and v13 proof.
  --wild-subsistence Run real fishing, hunting, wild gathering, custody, and v14 proof.
  --physical-food-survival Run real berry acquisition, exact eating, shadow rejection, and v17 proof.
  --livestock Run real sheep feeding, breeding, herding, wool, loss, and v15 proof.
  --work-professions Run real work commitments and derived multi-agent profiles with v16 proof.
  --work-demand-refresh Run 256 integrated Civilization ticks with stable Work refresh evidence.
  --gate-b-passive Run a five-minute rendered passive observer slice with no productive command after bootstrap.
  --help     Show this help and exit.
EOF
}

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

require_repository_root() {
    local root=$1
    local top_level

    git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
        || fail "repository metadata not found at $root"
    top_level=$(git -C "$root" rev-parse --show-toplevel 2>/dev/null) \
        || fail "repository metadata not found at $root"
    [ "$top_level" = "$root" ] \
        || fail "unexpected repository root: $top_level"
}

require_trace() {
    pattern=$1
    description=$2
    /usr/bin/grep -Eq "$pattern" "$TRACE_PATH" \
        || fail "live trace missing: $description"
}

reject_trace() {
    pattern=$1
    description=$2
    if /usr/bin/grep -Eq "$pattern" "$TRACE_PATH"; then
        fail "live trace unexpectedly contains: $description"
    fi
}

require_trace_count() {
    pattern=$1
    expected=$2
    description=$3
    actual=$(/usr/bin/grep -Ec "$pattern" "$TRACE_PATH" || true)
    [ "$actual" -eq "$expected" ] \
        || fail "live trace count $actual != $expected: $description"
}

require_trace_at_least() {
    pattern=$1
    minimum=$2
    description=$3
    actual=$(/usr/bin/grep -Ec "$pattern" "$TRACE_PATH" || true)
    [ "$actual" -ge "$minimum" ] \
        || fail "live trace count $actual < $minimum: $description"
}

DRY_RUN=0
MODE_OPTIONS=0
for option in "$@"; do
    case "$option" in
        --dry-run) DRY_RUN=1 ;;
        --survival) MODE="survival"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --economy) MODE="economy"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --h2) MODE="h2"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --natural) MODE="harvest"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --harvest) MODE="harvest"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --construction) MODE="construction"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --embodiment) MODE="embodiment"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --build) MODE="construction"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --social) MODE="social"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --physical) MODE="physical"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --material) MODE="material"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --rights) MODE="rights"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --production) MODE="production"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --barter) MODE="barter"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --contracts) MODE="contracts"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --markets) MODE="markets"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --cooperation) MODE="cooperation"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --persistence) MODE="persistence"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --population) MODE="population"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --multiscale) MODE="multiscale"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --ecology) MODE="ecology"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --mortality) MODE="mortality"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --reproduction) MODE="reproduction"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --kinship) MODE="kinship"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --households) MODE="households"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --care) MODE="care"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --skills) MODE="skills"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --teaching) MODE="teaching"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --integrated-teaching) MODE="integrated-teaching"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --ecological-observation) MODE="ecological-observation"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --agriculture) MODE="agriculture"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --wild-subsistence) MODE="wild-subsistence"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --physical-food-survival) MODE="physical-food-survival"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --livestock) MODE="livestock"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --work-professions) MODE="work-professions"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --work-demand-refresh) MODE="work-demand-refresh"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --gate-b-passive) MODE="gate-b-passive"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --help|-h) usage; exit 0 ;;
        *) printf 'Unknown option: %s\n' "$option" >&2; usage >&2; exit 2 ;;
    esac
done
[ "$#" -le 2 ] || { usage >&2; exit 2; }
[ "$MODE_OPTIONS" -le 1 ] || fail "choose only one live scenario"

NATURAL_GATE=0
BUILD_GATE=0
SOCIAL_GATE=0
PHYSICAL_GATE=0
MATERIAL_GATE=0
COOPERATION_GATE=0
PERSISTENCE_GATE=0
POPULATION_GATE=0
MULTISCALE_GATE=0
ECOLOGY_GATE=0
MORTALITY_GATE=0
LIFECYCLE_GATE=0
KINSHIP_GATE=0
HOUSEHOLD_GATE=0
CARE_GATE=0
SKILL_GATE=0
TEACHING_GATE=0
ECOLOGICAL_OBSERVATION_GATE=0
AGRICULTURE_GATE=0
WILD_SUBSISTENCE_GATE=0
LIVESTOCK_GATE=0
WORK_PROFESSIONS_GATE=0
PRODUCTION_GATE=0
BARTER_GATE=0
CONTRACT_GATE=0
MARKET_GATE=0
GATE_E_BLOCKER_03=0
GATE_E_BLOCKER_04=0
AUTONOMOUS_CIVILIZATION_GATE=0
INTEGRATED_TEACHING_PROOF=0
PASSIVE_OBSERVER_INPUT_PROOF=0
PASSIVE_OBSERVER_BATCH_FRAMES=240
WORK_DEMAND_REFRESH_PROOF=0
GATE_B3_ACCEPTANCE=0
GATE_B3_COGNITIVE_HZ=4
GATE_B3_HORIZON=0
GATE_B3_RANDOM_TICK_SPEED=3
if [ "$MODE" = "markets" ]; then
    WORLD_SEED="46"
    MATERIAL_GATE=1
    PERSISTENCE_GATE=1
    PRODUCTION_GATE=1
    MARKET_GATE=1
    AUTONOMOUS_CIVILIZATION_GATE=1
    WORLD_NAME="PebbleLab-Disposable-Markets-46"
    CAPTURE_NAME="market-final-cleanup.png"
    MARKET_PHASE1_COMMANDS='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 68 -18|/lab start;/tp 14 73 -22;/lab pause;/lab movement off;/lab market setup;/lab market status;/lab overlay compact|/lab step;/lab market status|/lab step;/lab market status;/lab overlay compact|/lab step;/lab market status;/lab market proof;/lab checkpoint save market-open-v34;/lab checkpoint status;/lab causality tail 20;/lab status'
    MARKET_PHASE2_COMMANDS='/tp 14 68 -18;/lab start;/tp 14 73 -22;/lab pause;/lab movement off;/lab checkpoint load market-open-v34;/lab market status;/lab market proof;/lab overlay compact|/lab step;/lab market status|/lab step;/lab market status;/lab market remote-buyer|/lab market status;/lab market proof;/lab overlay compact|/lab step;/lab market status;/lab market proof;/lab market restore-locality|/lab step;/lab market status;/lab overlay compact|/lab step;/lab market status;/lab overlay compact|/lab step;/lab market status;/lab market proof;/lab checkpoint save market-traded-v34;/lab checkpoint status;/lab causality tail 20;/lab status'
    MARKET_PHASE3_COMMANDS='/tp 14 68 -18;/lab start;/tp 14 73 -22;/lab pause;/lab movement off;/lab checkpoint load market-traded-v34;/lab market status;/lab market proof;/lab overlay compact|/lab step;/lab market status|/lab step;/lab market status|/lab step;/lab market status|/lab step;/lab market status|/lab step;/lab market status;/lab overlay compact|/lab step;/lab market status|/lab step;/lab market status|/lab step;/lab market status;/lab overlay compact|/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab market status;/lab market proof;/lab checkpoint save market-final-v34;/lab checkpoint status;/lab causality tail 20;/lab status'
    MARKET_PHASE4_COMMANDS='/tp 14 68 -18;/lab start;/tp 14 73 -22;/lab pause;/lab movement off;/lab checkpoint load market-final-v34;/lab market status;/lab market proof;/lab overlay compact|/lab step;/lab market status;/lab market proof;/lab market cleanup;/lab status'
    if [ "${PEBBLELAB_GATE_E_BLOCKER_03:-0}" = "1" ]; then
        GATE_E_BLOCKER_03=1
        MARKET_PHASE2_COMMANDS='/tp 14 68 -18;/lab start;/tp 14 73 -22;/lab pause;/lab movement off;/lab checkpoint load market-open-v34;/lab market status;/lab market proof;/lab overlay compact|/lab step;/lab market status|/lab step;/lab market status;/lab market blocker-03-status;/lab market remote-buyer|/lab market status;/lab market proof;/lab overlay compact|/lab step;/lab market status;/lab market proof;/lab market restore-locality|/lab step;/lab market status;/lab overlay compact|/lab step;/lab market status;/lab overlay compact|/lab step;/lab market status;/lab market proof;/lab market blocker-03-status;/lab checkpoint save market-traded-v34;/lab checkpoint status;/lab causality tail 20;/lab status'
        MARKET_PHASE3_COMMANDS='/tp 14 68 -18;/lab start;/tp 14 73 -22;/lab pause;/lab movement off;/lab checkpoint load market-traded-v34;/lab market status;/lab market proof;/lab overlay compact|/lab step;/lab market status|/lab step;/lab market status|/lab step;/lab market status|/lab step;/lab market status|/lab step;/lab market status;/lab overlay compact|/lab step;/lab market status|/lab step;/lab market status|/lab step;/lab market status;/lab overlay compact|/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab market status;/lab market proof;/lab market blocker-03-status;/lab checkpoint save market-final-v34;/lab checkpoint status;/lab causality tail 20;/lab status'
        MARKET_PHASE4_COMMANDS='/tp 14 68 -18;/lab start;/tp 14 73 -22;/lab pause;/lab movement off;/lab checkpoint load market-final-v34;/lab market status;/lab market proof;/lab market blocker-03-status;/lab overlay compact|/lab step;/lab market status;/lab market blocker-03-status;/lab overlay compact|/lab step;/lab market status;/lab market blocker-03-status;/lab overlay compact|/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab market status;/lab market proof;/lab market blocker-03-status;/lab checkpoint save market-blocker03-reentered-v34;/lab checkpoint status;/lab observer status;/lab overlay compact|/lab market cleanup;/lab status'
    fi
    if [ "${PEBBLELAB_GATE_E_BLOCKER_04:-0}" = "1" ]; then
        [ "$GATE_E_BLOCKER_03" -eq 0 ] \
            || fail "Gate E Blocker 04 cannot share a Blocker 03 live campaign"
        GATE_E_BLOCKER_04=1
        BARTER_GATE=1
        CONTRACT_GATE=1
        WORLD_NAME="PebbleLab-Disposable-Gate-E-Blocker-04-46"
        CAPTURE_NAME="gate-e-blocker04-final-cleanup.png"
        MARKET_PHASE1_COMMANDS='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 68 -18|/lab start;/tp 14 73 -22;/lab pause;/lab movement off;/lab market setup;/lab market status;/lab market blocker-04-status;/lab overlay compact|/lab step;/lab market status;/lab contract status;/lab market blocker-04-status;/lab observer status;/lab overlay compact|/lab checkpoint save gate-e-blocker04-live-contract-v34;/lab checkpoint status;/lab causality tail 20;/lab status'
        MARKET_PHASE2_COMMANDS='/tp 14 68 -18;/lab start;/tp 14 73 -22;/lab pause;/lab movement off;/lab checkpoint load gate-e-blocker04-live-contract-v34;/lab market status;/lab contract status;/lab market blocker-04-status;/lab observer status;/lab overlay compact|/lab step;/lab market status;/lab contract status;/lab market blocker-04-status;/lab market blocker-04-enable-barter;/lab market blocker-04-status;/lab overlay compact|/lab checkpoint save gate-e-blocker04-released-v34;/lab checkpoint status;/lab causality tail 20;/lab status'
        MARKET_PHASE3_COMMANDS='/tp 14 68 -18;/lab start;/tp 14 73 -22;/lab pause;/lab movement off;/lab checkpoint load gate-e-blocker04-released-v34;/lab market status;/lab contract status;/lab market blocker-04-status;/lab observer status;/lab overlay compact|/lab step;/lab market status;/lab contract status;/lab market blocker-04-status;/lab overlay compact|/lab step;/lab market status;/lab contract status;/lab market blocker-04-status;/lab overlay compact|/lab checkpoint save gate-e-blocker04-barter-completed-v34;/lab checkpoint status;/lab causality tail 20;/lab status'
        MARKET_PHASE4_COMMANDS='/tp 14 68 -18;/lab start;/tp 14 73 -22;/lab pause;/lab movement off;/lab checkpoint load gate-e-blocker04-barter-completed-v34;/lab market status;/lab contract status;/lab market blocker-04-status;/lab observer status;/lab overlay compact|/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab market status;/lab contract status;/lab market blocker-04-status;/lab overlay compact|/lab market cleanup;/lab status'
    fi
    LAB_COMMANDS="$MARKET_PHASE1_COMMANDS"
elif [ "$MODE" = "contracts" ]; then
    WORLD_SEED="46"
    MATERIAL_GATE=1
    PERSISTENCE_GATE=1
    PRODUCTION_GATE=1
    CONTRACT_GATE=1
    AUTONOMOUS_CIVILIZATION_GATE=1
    WORLD_NAME="PebbleLab-Disposable-Contracts-46"
    CAPTURE_NAME="contract-final.png"
    CONTRACT_CAPACITY_COMMANDS='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 68 -18|/lab start;/tp 14 73 -22;/lab pause;/lab movement off;/lab contract setup;/lab contract status|/lab step;/lab contract status|/lab step;/lab contract status;/lab contract cleanup;/lab status'
    CONTRACT_PHASE1_COMMANDS='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 68 -18|/lab start;/tp 14 73 -22;/lab pause;/lab movement off;/lab contract setup;/lab contract status;/lab overlay compact|/lab step;/lab contract drift consideration;/lab contract status;/lab overlay compact|/lab step;/lab contract status;/lab overlay compact|/lab step;/lab contract status;/lab checkpoint save contract-open-v33;/lab checkpoint status;/lab causality tail 20;/lab status'
    CONTRACT_PHASE2_COMMANDS='/tp 14 68 -18;/lab start;/tp 14 73 -22;/lab pause;/lab movement off;/lab checkpoint load contract-open-v33;/lab contract status;/lab overlay compact|/lab step;/lab contract drift fulfillment;/lab contract status;/lab overlay compact|/lab step;/lab contract status;/lab overlay compact|/lab step;/lab contract status;/lab overlay compact|/lab step;/lab contract status;/lab contract proof;/lab checkpoint save contract-fulfilled-v33;/lab checkpoint status;/lab causality tail 20;/lab status'
    CONTRACT_PHASE3_COMMANDS='/tp 14 68 -18;/lab start;/tp 14 73 -22;/lab pause;/lab movement off;/lab checkpoint load contract-fulfilled-v33;/lab contract status;/lab overlay compact|/lab step;/lab contract status;/lab contract proof;/lab checkpoint save contract-final-v33;/lab checkpoint status;/lab causality tail 20;/lab contract cleanup;/lab status'
    LAB_COMMANDS="$CONTRACT_PHASE1_COMMANDS"
elif [ "$MODE" = "barter" ]; then
    WORLD_SEED="46"
    MATERIAL_GATE=1
    PERSISTENCE_GATE=1
    POPULATION_GATE=1
    LIFECYCLE_GATE=1
    SKILL_GATE=1
    PRODUCTION_GATE=1
    BARTER_GATE=1
    AUTONOMOUS_CIVILIZATION_GATE=1
    WORLD_NAME="PebbleLab-Disposable-Barter-46"
    CAPTURE_NAME="barter-final.png"
    BARTER_PHASE1_COMMANDS='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 68 -18|/lab start;/tp 14 73 -22;/lab pause;/lab movement off;/lab population on;/lab lifecycle on;/lab skills on;/lab barter setup;/lab barter status;/lab overlay compact|/lab step;/lab barter status;/lab overlay compact|/lab step;/lab barter status|/lab step;/lab barter status;/lab barter proof;/lab checkpoint save barter-v32;/lab checkpoint status;/lab causality tail 20;/lab status'
    BARTER_PHASE2_COMMANDS='/tp 14 68 -18;/lab start;/tp 14 73 -22;/lab pause;/lab movement off;/lab population on;/lab lifecycle on;/lab skills on;/lab checkpoint load barter-v32;/lab barter status;/lab overlay compact|/lab barter use-produced-tool;/lab barter status;/lab causality tail 20;/lab overlay compact|/lab checkpoint save barter-final-v32;/lab checkpoint status;/lab barter cleanup;/lab status'
    LAB_COMMANDS="$BARTER_PHASE1_COMMANDS"
elif [ "$MODE" = "production" ]; then
    WORLD_SEED="46"
    MATERIAL_GATE=1
    PERSISTENCE_GATE=1
    POPULATION_GATE=1
    LIFECYCLE_GATE=1
    SKILL_GATE=1
    PRODUCTION_GATE=1
    WORLD_NAME="PebbleLab-Disposable-Production-46"
    CAPTURE_NAME="production-final.png"
    PRODUCTION_PHASE1_COMMANDS='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 68 -18|/lab start;/tp 14 73 -22;/lab pause;/lab movement off;/lab population on;/lab lifecycle on;/lab skills on;/lab focus agent_2;/lab production setup;/lab production proof;/lab production status;/lab overlay compact|/lab step;/lab production status|/lab step;/lab production status;/lab checkpoint save production-v31;/lab checkpoint status;/lab causality tail 20;/lab status'
    PRODUCTION_PHASE2_COMMANDS='/tp 14 68 -18;/lab start;/tp 14 73 -22;/lab pause;/lab movement off;/lab population on;/lab lifecycle on;/lab skills on;/lab focus agent_2;/lab checkpoint load production-v31;/lab production status;/lab overlay compact|/lab production use-produced-tool;/lab production status;/lab causality tail 20;/lab overlay compact|/lab production cleanup;/lab checkpoint save production-final-v31;/lab checkpoint status;/lab production status;/lab status'
    LAB_COMMANDS="$PRODUCTION_PHASE1_COMMANDS"
elif [ "$MODE" = "integrated-teaching" ]; then
    WORLD_SEED="46"
    MATERIAL_GATE=1
    PERSISTENCE_GATE=1
    POPULATION_GATE=1
    LIFECYCLE_GATE=1
    SKILL_GATE=1
    TEACHING_GATE=1
    ECOLOGICAL_OBSERVATION_GATE=1
    AGRICULTURE_GATE=1
    WILD_SUBSISTENCE_GATE=1
    LIVESTOCK_GATE=1
    AUTONOMOUS_CIVILIZATION_GATE=1
    INTEGRATED_TEACHING_PROOF=1
    PASSIVE_OBSERVER_BATCH_FRAMES=600
    WORLD_NAME="PebbleLab-Disposable-IntegratedTeaching-46"
    CAPTURE_NAME="integrated-teaching-student-practice.png"
    LAB_COMMANDS='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 68 -18|/lab start;/lab pause;/lab movement off;/lab population on;/lab lifecycle on;/lab skills on;/lab teaching on;/lab ecological-observation on;/tp 24.5 68 -11.5 150 12;/lab focus agent_0;/lab follow off;/lab overlay off;/lab autonomous-civilization passive;/lab resume|/lab teaching status;/lab autonomous-civilization status;/lab focus agent_0|/lab teaching status;/lab autonomous-civilization status;/lab focus agent_1|/lab teaching status;/lab autonomous-civilization status;/lab causality status'
elif [ "$MODE" = "work-demand-refresh" ]; then
    WORLD_SEED="46"
    MATERIAL_GATE=1
    PERSISTENCE_GATE=1
    POPULATION_GATE=1
    MULTISCALE_GATE=1
    ECOLOGY_GATE=1
    MORTALITY_GATE=1
    LIFECYCLE_GATE=1
    KINSHIP_GATE=1
    HOUSEHOLD_GATE=1
    CARE_GATE=1
    SKILL_GATE=1
    TEACHING_GATE=1
    ECOLOGICAL_OBSERVATION_GATE=1
    AGRICULTURE_GATE=1
    WILD_SUBSISTENCE_GATE=1
    LIVESTOCK_GATE=1
    WORK_PROFESSIONS_GATE=1
    AUTONOMOUS_CIVILIZATION_GATE=1
    PASSIVE_OBSERVER_INPUT_PROOF=1
    WORK_DEMAND_REFRESH_PROOF=1
    GATE_B3_ACCEPTANCE=1
    GATE_B3_HORIZON=256
    WORLD_NAME="PebbleLab-Disposable-WorkDemandRefresh-46"
    CAPTURE_NAME="corr04-later-active-society.png"
    LAB_COMMANDS='/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/lab start;/lab pause;/lab movement off;/lab population on;/lab lifecycle on;/lab survival on;/lab mortality on;/lab kinship on;/lab household on;/lab care on;/lab skills on;/lab teaching on;/lab settlement on;/lab ecology on;/lab ecological-observation on;/lab work-professions on;/lab physical-food-survival on;/lab autonomous-civilization passive;/lab resume'
elif [ "$MODE" = "gate-b-passive" ]; then
    WORLD_SEED="46"
    MATERIAL_GATE=1
    PERSISTENCE_GATE=1
    POPULATION_GATE=1
    LIFECYCLE_GATE=1
    SKILL_GATE=1
    ECOLOGICAL_OBSERVATION_GATE=1
    AGRICULTURE_GATE=1
    WILD_SUBSISTENCE_GATE=1
    LIVESTOCK_GATE=1
    AUTONOMOUS_CIVILIZATION_GATE=1
    PASSIVE_OBSERVER_INPUT_PROOF=1
    PASSIVE_OBSERVER_BATCH_FRAMES=3600
    WORLD_NAME="PebbleLab-Disposable-GateB-Reevaluation-46"
    CAPTURE_NAME="gate-b2-later.png"
    LAB_COMMANDS='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 68 -18|/lab start;/lab pause;/lab movement off;/lab population on;/lab lifecycle on;/lab skills on;/lab ecological-observation on;/lab survival on;/lab physical-food-survival on;/tp 24.5 68 -11.5 150 12;/lab focus agent_0;/lab follow off;/lab overlay off;/lab autonomous-civilization passive;/lab resume|/lab autonomous-civilization status;/lab focus agent_0|/lab autonomous-civilization status;/lab focus agent_0|/lab autonomous-civilization status;/lab focus agent_1|/lab autonomous-civilization status;/lab focus agent_0|/lab autonomous-civilization status;/lab causality status'
elif [ "$MODE" = "physical-food-survival" ]; then
    WORLD_SEED="46"
    MATERIAL_GATE=1
    PERSISTENCE_GATE=1
    POPULATION_GATE=1
    LIFECYCLE_GATE=1
    SKILL_GATE=1
    ECOLOGICAL_OBSERVATION_GATE=1
    WILD_SUBSISTENCE_GATE=1
    WORLD_NAME="PebbleLab-Disposable-PhysicalFood-46"
    CAPTURE_NAME="physical-food-final.png"
    PHYSICAL_FOOD_BOOT='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 68 -18|/lab start;/tp 14 71 -18;/lab pause;/lab population on;/lab lifecycle on;/lab skills on;/lab focus agent_2;/lab survival on;/lab physical-food-survival on;/lab physical-food-survival proof shadow-setup'
    physical_food_step=0
    while [ "$physical_food_step" -lt 17 ]; do
        PHYSICAL_FOOD_BOOT="$PHYSICAL_FOOD_BOOT;/lab step"
        physical_food_step=$((physical_food_step + 1))
    done
    LAB_COMMANDS="$PHYSICAL_FOOD_BOOT;/lab physical-food-survival proof shadow;/lab ecological-observation on;/lab wild-subsistence on;/lab wild-subsistence proof setup;/tp 14 70 -20 0 25;/lab overlay off|/lab wild-subsistence proof fish|/lab wild-subsistence proof hunt|/lab wild-subsistence proof gather|/lab physical-food-survival proof consume|/lab physical-food-survival proof final;/lab physical-food-survival status;/lab causality tail 20;/lab status"
elif [ "$MODE" = "work-professions" ]; then
    WORLD_SEED="46"
    MATERIAL_GATE=1
    PERSISTENCE_GATE=1
    POPULATION_GATE=1
    LIFECYCLE_GATE=1
    SKILL_GATE=1
    ECOLOGICAL_OBSERVATION_GATE=1
    WILD_SUBSISTENCE_GATE=1
    WORK_PROFESSIONS_GATE=1
    WORLD_NAME="PebbleLab-Disposable-WorkProfessions-46"
    CAPTURE_NAME="work-professions-final.png"
    LAB_COMMANDS='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 68 -18|/lab start;/tp 14 71 -18;/lab pause;/lab movement off;/lab population on;/lab lifecycle on;/lab skills on;/lab ecological-observation on;/lab wild-subsistence on;/lab work-professions on;/lab focus agent_0;/lab wild-subsistence proof setup;/lab work-professions refresh;/lab work-professions match;/tp 14 70 -20 0 25;/lab overlay compact;/lab work-professions status|/lab wild-subsistence proof fish;/lab work-professions record;/lab work-professions status|/lab wild-subsistence proof hunt;/lab work-professions record;/lab work-professions status|/lab work-professions crisis;/lab work-professions status|/lab work-professions resume;/lab wild-subsistence proof gather;/lab work-professions record;/lab work-professions final;/lab checkpoint status;/lab causality tail 20;/lab status'
elif [ "$MODE" = "livestock" ]; then
    WORLD_SEED="46"
    MATERIAL_GATE=1
    PERSISTENCE_GATE=1
    POPULATION_GATE=1
    LIFECYCLE_GATE=1
    SKILL_GATE=1
    ECOLOGICAL_OBSERVATION_GATE=1
    LIVESTOCK_GATE=1
    WORLD_NAME="PebbleLab-Disposable-Livestock-46"
    CAPTURE_NAME="livestock-final.png"
    LAB_COMMANDS='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 68 -18|/lab start;/lab pause;/lab movement off;/lab population on;/lab lifecycle on;/lab skills on;/lab ecological-observation on;/lab livestock on;/lab focus agent_0;/lab livestock proof setup;/tp 18 72 -17 -135 20;/lab overlay off|/lab livestock status|/lab livestock proof feed|/lab livestock proof breed|/lab livestock proof work|/lab livestock proof loss;/lab livestock status;/lab causality tail 20;/lab status'
elif [ "$MODE" = "wild-subsistence" ]; then
    WORLD_SEED="46"
    MATERIAL_GATE=1
    PERSISTENCE_GATE=1
    POPULATION_GATE=1
    LIFECYCLE_GATE=1
    SKILL_GATE=1
    ECOLOGICAL_OBSERVATION_GATE=1
    WILD_SUBSISTENCE_GATE=1
    WORLD_NAME="PebbleLab-Disposable-WildSubsistence-46"
    CAPTURE_NAME="subsistence-final.png"
    LAB_COMMANDS='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 68 -18|/lab start;/tp 14 71 -18;/lab pause;/lab movement off;/lab population on;/lab lifecycle on;/lab skills on;/lab ecological-observation on;/lab wild-subsistence on;/lab focus agent_0;/lab wild-subsistence proof setup;/tp 14 70 -20 0 25;/lab overlay off|/lab wild-subsistence proof fish;/lab wild-subsistence status|/lab wild-subsistence proof hunt;/lab wild-subsistence status|/lab wild-subsistence proof gather;/lab wild-subsistence status|/lab wild-subsistence proof final;/lab checkpoint status;/lab causality tail 20;/tp 14 70 -20 0 25;/lab status'
elif [ "$MODE" = "agriculture" ]; then
    WORLD_SEED="46"
    MATERIAL_GATE=1
    PERSISTENCE_GATE=1
    POPULATION_GATE=1
    LIFECYCLE_GATE=1
    SKILL_GATE=1
    ECOLOGICAL_OBSERVATION_GATE=1
    AGRICULTURE_GATE=1
    WORLD_NAME="PebbleLab-Disposable-Agriculture-46"
    CAPTURE_NAME="agriculture-final.png"
    LAB_COMMANDS='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 68 -18|/lab start;/tp 14 71 -18;/lab pause;/lab movement off;/lab population on;/lab lifecycle on;/lab skills on;/lab ecological-observation on;/lab agriculture on;/lab focus agent_0;/lab agriculture proof;/lab agriculture status;/lab checkpoint save agriculture-v13;/lab checkpoint status;/lab causality tail 20;/tp 22 73 -30 0 30;/lab overlay off;/lab status'
elif [ "$MODE" = "ecological-observation" ]; then
    WORLD_SEED="46"
    PERSISTENCE_GATE=1
    POPULATION_GATE=1
    ECOLOGICAL_OBSERVATION_GATE=1
    WORLD_NAME="PebbleLab-Disposable-EcologicalObservation-46"
    CAPTURE_NAME="ecological-observation-proof.png"
    LAB_COMMANDS='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 68 -18|/lab start;/tp 14 71 -18;/lab pause;/lab movement off;/lab population on;/lab ecological-observation on;/lab focus agent_0;/lab ecological-observation proof;/lab ecological-observation status;/lab checkpoint save ecological-v12;/lab checkpoint status;/lab causality tail 10;/lab status;/lab overlay off'
elif [ "$MODE" = "teaching" ]; then
    WORLD_SEED="46"
    NATURAL_GATE=1
    SOCIAL_GATE=1
    PHYSICAL_GATE=1
    MATERIAL_GATE=1
    PERSISTENCE_GATE=1
    POPULATION_GATE=1
    LIFECYCLE_GATE=1
    SKILL_GATE=1
    TEACHING_GATE=1
    WORLD_NAME="PebbleLab-Disposable-Teaching-46"
    CAPTURE_NAME="teaching-proof.png"
    LAB_COMMANDS='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 68 -18|/lab start;/tp 14 71 -18;/lab pause;/lab movement off;/lab population on;/lab lifecycle on;/lab skills on;/lab teaching on;/lab focus agent_2;/lab teaching proof;/lab teaching status;/lab causality tail 20;/lab status'
elif [ "$MODE" = "skills" ]; then
    WORLD_SEED="46"
    NATURAL_GATE=1
    BUILD_GATE=1
    SOCIAL_GATE=1
    PHYSICAL_GATE=1
    COOPERATION_GATE=1
    PERSISTENCE_GATE=1
    POPULATION_GATE=1
    MULTISCALE_GATE=1
    ECOLOGY_GATE=1
    LIFECYCLE_GATE=1
    SKILL_GATE=1
    WORLD_NAME="PebbleLab-Disposable-Skills-46"
    CAPTURE_NAME="practice-based-skills-proof.png"
    BUILD_ANCHOR_X=${PEBBLELAB_BUILD_ANCHOR_X:-14}
    BUILD_ANCHOR_Z=${PEBBLELAB_BUILD_ANCHOR_Z:--21}
    BUILD_ANCHOR_Y=${PEBBLELAB_BUILD_ANCHOR_Y:-66}
    BUILD_PLAYER_Y=$((BUILD_ANCHOR_Y + 3))
    SKILLS_PRACTICE_TICK=62
    SKILLS_TASK_TICK=64
    SKILLS_FINAL_TICK=67
    SKILLS_WORLD_READY="/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp $BUILD_ANCHOR_X $BUILD_ANCHOR_Y $BUILD_ANCHOR_Z"
    SKILLS_PHASE1_COMMANDS="$SKILLS_WORLD_READY|/lab start;/tp $BUILD_ANCHOR_X $BUILD_PLAYER_Y $BUILD_ANCHOR_Z;/lab pause;/lab movement off;/lab population on;/lab settlement on;/lab lifecycle on;/lab skills on;/lab focus agent_2;/lab follow agent_2;/lab build setup;/lab migration admit;/lab focus agent_3;/lab follow agent_3;/lab movement on"
    skills_step=0
    while [ "$skills_step" -lt 7 ]; do
        SKILLS_PHASE1_COMMANDS="$SKILLS_PHASE1_COMMANDS;/lab step"
        skills_step=$((skills_step + 1))
    done
    SKILLS_PHASE1_COMMANDS="$SKILLS_PHASE1_COMMANDS;/lab ecology on;/lab survival on;/lab focus agent_0;/lab follow agent_0"
    skills_step=0
    while [ "$skills_step" -lt 7 ]; do
        SKILLS_PHASE1_COMMANDS="$SKILLS_PHASE1_COMMANDS;/lab step"
        skills_step=$((skills_step + 1))
    done
    SKILLS_PHASE1_COMMANDS="$SKILLS_PHASE1_COMMANDS;/lab survival off;/lab economy auto on"
    skills_step=0
    while [ "$skills_step" -lt 46 ]; do
        SKILLS_PHASE1_COMMANDS="$SKILLS_PHASE1_COMMANDS;/lab step"
        skills_step=$((skills_step + 1))
    done
    SKILLS_PHASE1_COMMANDS="$SKILLS_PHASE1_COMMANDS;/lab economy auto off;/lab ecology off;/lab step;/lab step;/lab skills status;/lab focus agent_2;/lab follow agent_2;/lab build auto on;/lab social on;/lab physical on;/lab cooperation on"
    skills_step=0
    while [ "$skills_step" -lt 5 ]; do
        SKILLS_PHASE1_COMMANDS="$SKILLS_PHASE1_COMMANDS;/lab step"
        skills_step=$((skills_step + 1))
    done
    SKILLS_PHASE1_COMMANDS="$SKILLS_PHASE1_COMMANDS;/lab movement off;/lab economy auto off;/lab skills status;/lab cooperation status;/lab checkpoint save skills-v10;/lab checkpoint status;/lab causality tail 20;/lab status"
    SKILLS_RESTART_COMMANDS="$SKILLS_WORLD_READY|/lab start;/tp $BUILD_ANCHOR_X $BUILD_PLAYER_Y $BUILD_ANCHOR_Z;/lab checkpoint load skills-v10;/lab skills status;/lab cooperation status;/lab checkpoint status;/lab causality tail 20;/lab status"
    SKILLS_FAILURE_COMMANDS="$SKILLS_WORLD_READY|/lab start;/tp $BUILD_ANCHOR_X $BUILD_PLAYER_Y $BUILD_ANCHOR_Z;/lab pause;/lab movement off;/lab population on;/lab lifecycle on;/lab skills on;/lab focus agent_2;/lab follow agent_2;/lab natural on;/lab build setup;/lab economy auto on;/lab build auto on;/lab social on;/lab physical on;/lab cooperation on;/lab movement on"
    skills_step=0
    while [ "$skills_step" -lt 180 ]; do
        SKILLS_FAILURE_COMMANDS="$SKILLS_FAILURE_COMMANDS;/lab step"
        skills_step=$((skills_step + 1))
    done
    SKILLS_FAILURE_COMMANDS="$SKILLS_FAILURE_COMMANDS;/lab skills status;/lab build status;/lab causality status;/lab status"
    LAB_COMMANDS="$SKILLS_PHASE1_COMMANDS"
elif [ "$MODE" = "reproduction" ] || [ "$MODE" = "kinship" ] \
    || [ "$MODE" = "households" ] || [ "$MODE" = "care" ]; then
    WORLD_SEED="46"
    PERSISTENCE_GATE=1
    POPULATION_GATE=1
    MULTISCALE_GATE=1
    ECOLOGY_GATE=1
    LIFECYCLE_GATE=1
    if [ "$MODE" = "kinship" ] || [ "$MODE" = "households" ] || [ "$MODE" = "care" ]; then
        KINSHIP_GATE=1
        if [ "$MODE" = "households" ] || [ "$MODE" = "care" ]; then
            HOUSEHOLD_GATE=1
            if [ "$MODE" = "care" ]; then
                CARE_GATE=1
                WORLD_NAME="PebbleLab-Disposable-Care-46"
                CAPTURE_NAME="dependent-care-proof.txt"
                EXPECTED_REPRODUCTION_SCHEMA=9
            else
                WORLD_NAME="PebbleLab-Disposable-Households-46"
                CAPTURE_NAME="household-membership-proof.txt"
                EXPECTED_REPRODUCTION_SCHEMA=8
            fi
        else
            WORLD_NAME="PebbleLab-Disposable-Kinship-46"
            CAPTURE_NAME="durable-kinship-proof.txt"
            EXPECTED_REPRODUCTION_SCHEMA=7
        fi
    else
        WORLD_NAME="PebbleLab-Disposable-Reproduction-46"
        CAPTURE_NAME="age-maturity-reproduction-proof.txt"
        EXPECTED_REPRODUCTION_SCHEMA=6
    fi
    POPULATION_ANCHOR_X=${PEBBLELAB_ECOLOGY_ANCHOR_X:-14}
    POPULATION_ANCHOR_Z=${PEBBLELAB_ECOLOGY_ANCHOR_Z:--21}
    if [ "$MODE" = "care" ]; then
        POPULATION_ANCHOR_Y=${PEBBLELAB_ECOLOGY_ANCHOR_Y:-68}
    else
        POPULATION_ANCHOR_Y=${PEBBLELAB_ECOLOGY_ANCHOR_Y:-66}
    fi
    POPULATION_PLAYER_Y=$((POPULATION_ANCHOR_Y + 3))
    REPRO_INITIAL_TICK=7
    REPRO_PLAN_TICK=10
    REPRO_PREBIRTH_TICK=11
    REPRO_BIRTH_TICK=12
    REPRO_JUVENILE_TICK=14
    REPRO_FINAL_TICK=20
    REPRO_PLAN_ID="reproduction-plan-00000010-agent_0-agent_1"
    if [ "$MODE" = "care" ]; then
        REPRO_INITIAL_TICK=15
        REPRO_PLAN_TICK=16
        REPRO_PREBIRTH_TICK=17
        REPRO_BIRTH_TICK=18
        REPRO_JUVENILE_TICK=20
        REPRO_FINAL_TICK=26
        REPRO_PLAN_ID="reproduction-plan-00000016-agent_0-agent_1"
    fi
    POPULATION_WORLD_READY="/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp $POPULATION_ANCHOR_X $POPULATION_ANCHOR_Y $POPULATION_ANCHOR_Z"
    REPRODUCTION_BOOTSTRAP_COMMANDS="$POPULATION_WORLD_READY|/lab start;/tp $POPULATION_ANCHOR_X $POPULATION_PLAYER_Y $POPULATION_ANCHOR_Z;/lab pause;/lab movement on;/lab population on;/lab settlement on;/lab migration admit;/lab focus agent_3;/lab follow agent_3"
    reproduction_step=0
    while [ "$reproduction_step" -lt 7 ]; do
        REPRODUCTION_BOOTSTRAP_COMMANDS="$REPRODUCTION_BOOTSTRAP_COMMANDS;/lab step"
        reproduction_step=$((reproduction_step + 1))
    done
    REPRODUCTION_BOOTSTRAP_COMMANDS="$REPRODUCTION_BOOTSTRAP_COMMANDS;/lab migration status;/lab population status;/lab ecology on;/lab ecology scan"
    if [ "$MODE" = "care" ]; then
        REPRODUCTION_BOOTSTRAP_COMMANDS="$REPRODUCTION_BOOTSTRAP_COMMANDS;/lab economy auto on"
        reproduction_step=0
        while [ "$reproduction_step" -lt 8 ]; do
            REPRODUCTION_BOOTSTRAP_COMMANDS="$REPRODUCTION_BOOTSTRAP_COMMANDS;/lab step"
            reproduction_step=$((reproduction_step + 1))
        done
    fi
    REPRODUCTION_BOOTSTRAP_COMMANDS="$REPRODUCTION_BOOTSTRAP_COMMANDS;/lab survival on;/lab lifecycle on"
    if [ "$MODE" = "kinship" ] || [ "$MODE" = "households" ] || [ "$MODE" = "care" ]; then
        REPRODUCTION_BOOTSTRAP_COMMANDS="$REPRODUCTION_BOOTSTRAP_COMMANDS;/lab checkpoint save kinship-preactivation-v6;/lab kinship on;/lab kinship status"
    fi
    if [ "$MODE" = "households" ] || [ "$MODE" = "care" ]; then
        REPRODUCTION_BOOTSTRAP_COMMANDS="$REPRODUCTION_BOOTSTRAP_COMMANDS;/lab checkpoint save households-preactivation-v7;/lab household on;/lab household status"
    fi
    if [ "$MODE" = "care" ]; then
        REPRODUCTION_BOOTSTRAP_COMMANDS="$REPRODUCTION_BOOTSTRAP_COMMANDS;/lab checkpoint save care-preactivation-v8;/lab care on;/lab care status"
    fi
    REPRODUCTION_BOOTSTRAP_COMMANDS="$REPRODUCTION_BOOTSTRAP_COMMANDS;/lab reproduction on"
    if [ "$MODE" = "care" ]; then
        REPRODUCTION_PHASE1_COMMANDS="$REPRODUCTION_BOOTSTRAP_COMMANDS;/lab step"
    else
        REPRODUCTION_PHASE1_COMMANDS="$REPRODUCTION_BOOTSTRAP_COMMANDS;/lab step;/lab step;/lab step"
    fi
    REPRODUCTION_PHASE1_COMMANDS="$REPRODUCTION_PHASE1_COMMANDS;/lab lifecycle status;/lab reproduction status;/lab births status;/lab checkpoint save reproduction-midplan;/lab checkpoint status;/lab causality status;/lab status"
    LAB_COMMANDS="$REPRODUCTION_PHASE1_COMMANDS"
elif [ "$MODE" = "mortality" ]; then
    WORLD_SEED="46"
    PERSISTENCE_GATE=1
    POPULATION_GATE=1
    MULTISCALE_GATE=1
    ECOLOGY_GATE=1
    MORTALITY_GATE=1
    WORLD_NAME="PebbleLab-Disposable-Mortality-46"
    CAPTURE_NAME="mortality-population-exit-proof.txt"
    POPULATION_ANCHOR_X=${PEBBLELAB_ECOLOGY_ANCHOR_X:-14}
    POPULATION_ANCHOR_Z=${PEBBLELAB_ECOLOGY_ANCHOR_Z:--21}
    POPULATION_ANCHOR_Y=${PEBBLELAB_ECOLOGY_ANCHOR_Y:-66}
    POPULATION_PLAYER_Y=$((POPULATION_ANCHOR_Y + 3))
    POPULATION_WORLD_READY="/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp $POPULATION_ANCHOR_X $POPULATION_ANCHOR_Y $POPULATION_ANCHOR_Z"
    MORTALITY_BOOTSTRAP_COMMANDS="$POPULATION_WORLD_READY|/lab start;/tp $POPULATION_ANCHOR_X $POPULATION_PLAYER_Y $POPULATION_ANCHOR_Z;/lab pause;/lab movement on;/lab population on;/lab settlement on;/lab survival on;/lab mortality on;/lab focus agent_0"
    mortality_step=0
    while [ "$mortality_step" -lt 10 ]; do
        MORTALITY_BOOTSTRAP_COMMANDS="$MORTALITY_BOOTSTRAP_COMMANDS;/lab step"
        mortality_step=$((mortality_step + 1))
    done
    MORTALITY_BOOTSTRAP_COMMANDS="$MORTALITY_BOOTSTRAP_COMMANDS;/lab migration admit;/lab focus agent_3;/lab follow agent_3"
    mortality_step=0
    while [ "$mortality_step" -lt 5 ]; do
        MORTALITY_BOOTSTRAP_COMMANDS="$MORTALITY_BOOTSTRAP_COMMANDS;/lab step"
        mortality_step=$((mortality_step + 1))
    done
    MORTALITY_BOOTSTRAP_COMMANDS="$MORTALITY_BOOTSTRAP_COMMANDS;/lab migration status;/lab population status;/lab ecology on;/lab ecology scan;/lab economy auto on"
    mortality_step=0
    while [ "$mortality_step" -lt 11 ]; do
        MORTALITY_BOOTSTRAP_COMMANDS="$MORTALITY_BOOTSTRAP_COMMANDS;/lab step"
        mortality_step=$((mortality_step + 1))
    done
    MORTALITY_PHASE1_COMMANDS="$MORTALITY_BOOTSTRAP_COMMANDS;/lab focus agent_2;/lab follow agent_2;/lab ecology status;/lab survival status;/lab mortality status;/lab exits status;/lab checkpoint save mortality-preexit;/lab checkpoint status;/lab causality status;/lab status"
    LAB_COMMANDS="$MORTALITY_PHASE1_COMMANDS"
elif [ "$MODE" = "ecology" ]; then
    WORLD_SEED="46"
    PERSISTENCE_GATE=1
    POPULATION_GATE=1
    MULTISCALE_GATE=1
    ECOLOGY_GATE=1
    WORLD_NAME="PebbleLab-Disposable-Ecology-46"
    CAPTURE_NAME="local-ecology-proof.txt"
    POPULATION_ANCHOR_X=${PEBBLELAB_ECOLOGY_ANCHOR_X:-14}
    POPULATION_ANCHOR_Z=${PEBBLELAB_ECOLOGY_ANCHOR_Z:--21}
    POPULATION_ANCHOR_Y=${PEBBLELAB_ECOLOGY_ANCHOR_Y:-66}
    POPULATION_PLAYER_Y=$((POPULATION_ANCHOR_Y + 3))
    POPULATION_WORLD_READY="/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp $POPULATION_ANCHOR_X $POPULATION_ANCHOR_Y $POPULATION_ANCHOR_Z"
    ECOLOGY_PHASE1_COMMANDS="$POPULATION_WORLD_READY|/lab start;/tp $POPULATION_ANCHOR_X $POPULATION_PLAYER_Y $POPULATION_ANCHOR_Z;/lab pause;/lab movement on;/lab population on;/lab settlement on;/lab migration admit;/lab focus agent_3;/lab follow agent_3"
    ecology_step=0
    while [ "$ecology_step" -lt 7 ]; do
        ECOLOGY_PHASE1_COMMANDS="$ECOLOGY_PHASE1_COMMANDS;/lab step"
        ecology_step=$((ecology_step + 1))
    done
    ECOLOGY_PHASE1_COMMANDS="$ECOLOGY_PHASE1_COMMANDS;/lab migration status;/lab population status;/lab ecology on;/lab survival on;/lab focus agent_0;/lab ecology scan;/lab ecology status"
    ecology_step=0
    while [ "$ecology_step" -lt 7 ]; do
        ECOLOGY_PHASE1_COMMANDS="$ECOLOGY_PHASE1_COMMANDS;/lab step"
        ecology_step=$((ecology_step + 1))
    done
    ECOLOGY_PHASE1_COMMANDS="$ECOLOGY_PHASE1_COMMANDS;/lab economy auto on"
    ecology_step=0
    while [ "$ecology_step" -lt 7 ]; do
        ECOLOGY_PHASE1_COMMANDS="$ECOLOGY_PHASE1_COMMANDS;/lab step"
        ecology_step=$((ecology_step + 1))
    done
    ECOLOGY_PHASE1_COMMANDS="$ECOLOGY_PHASE1_COMMANDS;/lab ecology status;/lab forage status;/lab survival status;/lab checkpoint save ecology-shortage;/lab checkpoint status;/lab causality status;/lab status"
    LAB_COMMANDS="$ECOLOGY_PHASE1_COMMANDS"
elif [ "$MODE" = "multiscale" ]; then
    WORLD_SEED="46"
    PERSISTENCE_GATE=1
    POPULATION_GATE=1
    MULTISCALE_GATE=1
    WORLD_NAME="PebbleLab-Disposable-Multiscale-46"
    CAPTURE_NAME="settlement-multiscale-proof.txt"
    POPULATION_ANCHOR_X=${PEBBLELAB_POPULATION_ANCHOR_X:-14}
    POPULATION_ANCHOR_Z=${PEBBLELAB_POPULATION_ANCHOR_Z:--18}
    POPULATION_ANCHOR_Y=${PEBBLELAB_POPULATION_ANCHOR_Y:-68}
    POPULATION_PLAYER_Y=$((POPULATION_ANCHOR_Y + 3))
    POPULATION_WORLD_READY="/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp $POPULATION_ANCHOR_X $POPULATION_ANCHOR_Y $POPULATION_ANCHOR_Z"
    MULTISCALE_PHASE1_COMMANDS="$POPULATION_WORLD_READY|/lab start;/tp $POPULATION_ANCHOR_X $POPULATION_PLAYER_Y $POPULATION_ANCHOR_Z;/lab pause;/lab movement on;/lab population on;/lab settlement on;/lab settlement status;/lab scale status;/lab migration admit;/lab focus agent_3;/lab follow agent_3"
    multiscale_step=0
    while [ "$multiscale_step" -lt 4 ]; do
        MULTISCALE_PHASE1_COMMANDS="$MULTISCALE_PHASE1_COMMANDS;/lab step"
        multiscale_step=$((multiscale_step + 1))
    done
    MULTISCALE_PHASE1_COMMANDS="$MULTISCALE_PHASE1_COMMANDS;/lab migration status;/lab settlement status;/lab checkpoint save settlement-frame-1;/lab checkpoint status;/lab causality status;/lab status"
    LAB_COMMANDS="$MULTISCALE_PHASE1_COMMANDS"
elif [ "$MODE" = "population" ]; then
    WORLD_SEED="46"
    PERSISTENCE_GATE=1
    POPULATION_GATE=1
    WORLD_NAME="PebbleLab-Disposable-Population-46"
    CAPTURE_NAME="population-proof.txt"
    POPULATION_ANCHOR_X=${PEBBLELAB_POPULATION_ANCHOR_X:-14}
    POPULATION_ANCHOR_Z=${PEBBLELAB_POPULATION_ANCHOR_Z:--18}
    POPULATION_ANCHOR_Y=${PEBBLELAB_POPULATION_ANCHOR_Y:-68}
    POPULATION_PLAYER_Y=$((POPULATION_ANCHOR_Y + 3))
    POPULATION_WORLD_READY="/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp $POPULATION_ANCHOR_X $POPULATION_ANCHOR_Y $POPULATION_ANCHOR_Z"
    POPULATION_PHASE1_COMMANDS="$POPULATION_WORLD_READY|/lab start;/tp $POPULATION_ANCHOR_X $POPULATION_PLAYER_Y $POPULATION_ANCHOR_Z;/lab pause;/lab movement on;/lab population on;/lab population status;/lab migration admit;/lab focus agent_3;/lab follow agent_3;/lab migration status;/lab step;/lab step;/lab migration status;/lab checkpoint save migration-mid-route;/lab checkpoint status;/lab causality status;/lab status"
    LAB_COMMANDS="$POPULATION_PHASE1_COMMANDS"
elif [ "$MODE" = "persistence" ]; then
    WORLD_SEED="46"
    NATURAL_GATE=1
    BUILD_GATE=1
    SOCIAL_GATE=1
    PHYSICAL_GATE=1
    COOPERATION_GATE=1
    PERSISTENCE_GATE=1
    WORLD_NAME="PebbleLab-Disposable-Persistence-46"
    CAPTURE_NAME="persistence-proof.txt"
    BUILD_ANCHOR_X=${PEBBLELAB_BUILD_ANCHOR_X:-14}
    BUILD_ANCHOR_Z=${PEBBLELAB_BUILD_ANCHOR_Z:--21}
    BUILD_ANCHOR_Y=${PEBBLELAB_BUILD_ANCHOR_Y:-66}
    BUILD_PLAYER_Y=$((BUILD_ANCHOR_Y + 3))
    PERSISTENCE_WORLD_READY="/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp $BUILD_ANCHOR_X $BUILD_ANCHOR_Y $BUILD_ANCHOR_Z"
    PERSISTENCE_PHASE1_COMMANDS="$PERSISTENCE_WORLD_READY|/lab start;/tp $BUILD_ANCHOR_X $BUILD_PLAYER_Y $BUILD_ANCHOR_Z;/lab pause;/lab movement off;/lab focus agent_2;/lab follow agent_2;/lab natural on;/lab build setup;/lab economy auto on;/lab build auto on;/lab social on;/lab physical on;/lab cooperation on;/lab movement on"
    persistence_step=0
    while [ "$persistence_step" -lt 4 ]; do
        PERSISTENCE_PHASE1_COMMANDS="$PERSISTENCE_PHASE1_COMMANDS;/lab step"
        persistence_step=$((persistence_step + 1))
    done
    PERSISTENCE_PHASE1_COMMANDS="$PERSISTENCE_PHASE1_COMMANDS;/lab economy auto off;/lab step;/lab cooperation status;/lab checkpoint status;/lab checkpoint save accepted-task;/lab replay start accepted-task;/lab replay status;/lab checkpoint status"
    PERSISTENCE_PHASE2_COMMANDS="$PERSISTENCE_WORLD_READY|/lab start;/tp $BUILD_ANCHOR_X $BUILD_PLAYER_Y $BUILD_ANCHOR_Z;/lab checkpoint load accepted-task;/lab replay start accepted-task;/lab step;/lab economy auto on"
    PERSISTENCE_STEPS=${PEBBLELAB_PERSISTENCE_STEPS:-180}
    persistence_step=0
    while [ "$persistence_step" -lt "$PERSISTENCE_STEPS" ]; do
        PERSISTENCE_PHASE2_COMMANDS="$PERSISTENCE_PHASE2_COMMANDS;/lab step"
        persistence_step=$((persistence_step + 1))
    done
    PERSISTENCE_PHASE2_COMMANDS="$PERSISTENCE_PHASE2_COMMANDS;/lab cooperation status;/lab build status;/lab checkpoint save post-material;/lab checkpoint status;/lab replay stop live-continuation;/lab replay verify accepted-task live-continuation;/lab causality status;/lab status|/lab movement off;/lab cooperation off;/lab physical off;/lab social off;/lab build clear;/lab build status;/lab follow off"
    PERSISTENCE_CONTROL_COMMANDS="$PERSISTENCE_WORLD_READY|/lab start;/tp $BUILD_ANCHOR_X $BUILD_PLAYER_Y $BUILD_ANCHOR_Z;/lab pause;/lab movement off;/lab focus agent_2;/lab follow agent_2;/lab natural on;/lab build setup;/lab economy auto on;/lab build auto on;/lab social on;/lab physical on;/lab cooperation on;/lab movement on"
    persistence_step=0
    while [ "$persistence_step" -lt 4 ]; do
        PERSISTENCE_CONTROL_COMMANDS="$PERSISTENCE_CONTROL_COMMANDS;/lab step"
        persistence_step=$((persistence_step + 1))
    done
    PERSISTENCE_CONTROL_COMMANDS="$PERSISTENCE_CONTROL_COMMANDS;/lab economy auto off;/lab step;/lab step;/lab economy auto on"
    persistence_step=0
    while [ "$persistence_step" -lt "$PERSISTENCE_STEPS" ]; do
        PERSISTENCE_CONTROL_COMMANDS="$PERSISTENCE_CONTROL_COMMANDS;/lab step"
        persistence_step=$((persistence_step + 1))
    done
    PERSISTENCE_CONTROL_COMMANDS="$PERSISTENCE_CONTROL_COMMANDS;/lab cooperation status;/lab build status;/lab checkpoint status;/lab causality status;/lab status|/lab movement off;/lab cooperation off;/lab physical off;/lab social off;/lab build clear;/lab build status;/lab follow off"
    LAB_COMMANDS="$PERSISTENCE_PHASE1_COMMANDS"
elif [ "$MODE" = "cooperation" ]; then
    WORLD_SEED="46"
    NATURAL_GATE=1
    BUILD_GATE=1
    SOCIAL_GATE=1
    PHYSICAL_GATE=1
    COOPERATION_GATE=1
    WORLD_NAME="PebbleLab-Disposable-Cooperation-46"
    CAPTURE_NAME="cooperation-complete.png"
    BUILD_ANCHOR_X=${PEBBLELAB_BUILD_ANCHOR_X:-14}
    BUILD_ANCHOR_Z=${PEBBLELAB_BUILD_ANCHOR_Z:--21}
    BUILD_ANCHOR_Y=${PEBBLELAB_BUILD_ANCHOR_Y:-66}
    BUILD_PLAYER_Y=$((BUILD_ANCHOR_Y + 3))
    LAB_COMMANDS="/tp $BUILD_ANCHOR_X $BUILD_ANCHOR_Y $BUILD_ANCHOR_Z|/lab start;/tp $BUILD_ANCHOR_X $BUILD_PLAYER_Y $BUILD_ANCHOR_Z;/lab pause;/lab movement off;/lab focus agent_2;/lab follow agent_2;/lab natural on;/lab build setup;/lab economy auto on;/lab build auto on;/lab social on;/lab physical on;/lab cooperation on;/lab overlay compact;/lab movement on;/lab build status|"
    COOPERATION_STEPS=${PEBBLELAB_COOPERATION_STEPS:-180}
    cooperation_step=0
    while [ "$cooperation_step" -lt "$COOPERATION_STEPS" ]; do
        LAB_COMMANDS="$LAB_COMMANDS;/lab step"
        if [ "$cooperation_step" -eq 5 ]; then
            LAB_COMMANDS="$LAB_COMMANDS|"
        fi
        cooperation_step=$((cooperation_step + 1))
    done
    LAB_COMMANDS="$LAB_COMMANDS;/lab cooperation status;/lab build status;/lab economy status;/lab natural status;/lab physical status;/lab social status;/lab causality status;/lab causality tail 20;/lab status|/lab movement off;/lab cooperation off;/lab physical off;/lab social off;/lab build clear;/lab build status;/lab cooperation status;/lab follow off"
elif [ "$MODE" = "embodiment" ]; then
    WORLD_SEED="46"
    NATURAL_GATE=1
    BUILD_GATE=1
    MATERIAL_GATE=1
    PERSISTENCE_GATE=1
    POPULATION_GATE=1
    LIFECYCLE_GATE=1
    SKILL_GATE=1
    WORLD_NAME="PebbleLab-Disposable-Embodiment-46"
    CAPTURE_NAME="navigation-embodiment-proof.png"
    LAB_COMMANDS='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 68 -18|/lab start;/tp 14 71 -18;/lab pause;/lab movement off;/lab population on;/lab lifecycle on;/lab skills on;/lab focus agent_2;/lab harvest proof;/lab construction proof;/lab embodiment proof;/lab migration admit;/lab focus agent_3;/lab movement on;/lab step;/lab step;/lab step;/lab step;/lab movement off;/lab status'
elif [ "$MODE" = "construction" ]; then
    WORLD_SEED="46"
    BUILD_GATE=1
    MATERIAL_GATE=1
    PERSISTENCE_GATE=1
    POPULATION_GATE=1
    LIFECYCLE_GATE=1
    SKILL_GATE=1
    WORLD_NAME="PebbleLab-Disposable-Construction-46"
    CAPTURE_NAME="construction-convergence-proof.png"
    LAB_COMMANDS='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 68 -18|/lab start;/tp 14 71 -18;/lab pause;/lab movement off;/lab population on;/lab lifecycle on;/lab skills on;/lab focus agent_2;/lab construction proof;/lab status'
elif [ "$MODE" = "harvest" ]; then
    WORLD_SEED="46"
    NATURAL_GATE=1
    MATERIAL_GATE=1
    PERSISTENCE_GATE=1
    POPULATION_GATE=1
    LIFECYCLE_GATE=1
    SKILL_GATE=1
    WORLD_NAME="PebbleLab-Disposable-Harvest-46"
    CAPTURE_NAME="harvest-convergence-proof.png"
    LAB_COMMANDS='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 68 -18|/lab start;/tp 14 71 -18;/lab pause;/lab movement off;/lab population on;/lab lifecycle on;/lab skills on;/lab focus agent_2;/lab harvest proof;/lab harvest proof;/lab status'
elif [ "$MODE" = "material" ]; then
    WORLD_SEED="46"
    MATERIAL_GATE=1
    WORLD_NAME="PebbleLab-Disposable-Material-46"
    CAPTURE_NAME="real-material-custody-proof.png"
    LAB_COMMANDS='/tp 14 68 -18;/lab start;/tp 14 71 -18;/lab pause;/lab movement off;/lab focus agent_2;/lab material proof;/lab material proof;/lab status'
elif [ "$MODE" = "rights" ]; then
    WORLD_SEED="46"
    MATERIAL_GATE=1
    WORLD_NAME="PebbleLab-Disposable-Rights-46"
    CAPTURE_NAME="civ26-rights-divergence.png"
    LAB_COMMANDS='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 68 -18|/lab start;/tp 14 71 -18;/lab pause;/lab movement off;/lab rights proof;/lab rights status;/lab overlay compact|/lab rights clear;/lab rights status;/lab follow off'
elif [ "$MODE" = "physical" ]; then
    WORLD_SEED="46"
    SOCIAL_GATE=1
    PHYSICAL_GATE=1
    WORLD_NAME="PebbleLab-Disposable-Physical-46"
    CAPTURE_NAME="physical-after.png"
    SOCIAL_ANCHOR_X=${PEBBLELAB_SOCIAL_ANCHOR_X:-14}
    SOCIAL_ANCHOR_Y=${PEBBLELAB_SOCIAL_ANCHOR_Y:-68}
    SOCIAL_ANCHOR_Z=${PEBBLELAB_SOCIAL_ANCHOR_Z:--18}
    SOCIAL_PLAYER_Y=$((SOCIAL_ANCHOR_Y + 3))
    LAB_COMMANDS="/tp $SOCIAL_ANCHOR_X $SOCIAL_ANCHOR_Y $SOCIAL_ANCHOR_Z;/lab start;/tp $SOCIAL_ANCHOR_X $SOCIAL_PLAYER_Y $SOCIAL_ANCHOR_Z;/lab pause;/lab movement off;/lab focus agent_1;/lab follow agent_1;/lab survival on;/lab social on;/lab physical on;/lab overlay compact;/lab step|/lab step;/lab physical status|/lab movement on;/lab step;/lab step;/lab step;/lab step;/lab physical status;/lab social status;/lab causality status;/lab causality tail 20;/lab status;/lab movement off;/lab physical off;/lab social off;/lab follow off"
elif [ "$MODE" = "social" ]; then
    WORLD_SEED="46"
    SOCIAL_GATE=1
    WORLD_NAME="PebbleLab-Disposable-Social-46"
    CAPTURE_NAME="social-information-trust.png"
    SOCIAL_ANCHOR_X=${PEBBLELAB_SOCIAL_ANCHOR_X:-14}
    SOCIAL_ANCHOR_Y=${PEBBLELAB_SOCIAL_ANCHOR_Y:-68}
    SOCIAL_ANCHOR_Z=${PEBBLELAB_SOCIAL_ANCHOR_Z:--18}
    SOCIAL_PLAYER_Y=$((SOCIAL_ANCHOR_Y + 3))
    LAB_COMMANDS="/tp $SOCIAL_ANCHOR_X $SOCIAL_ANCHOR_Y $SOCIAL_ANCHOR_Z;/lab start;/tp $SOCIAL_ANCHOR_X $SOCIAL_PLAYER_Y $SOCIAL_ANCHOR_Z;/lab pause;/lab movement off;/lab focus agent_1;/lab survival on;/lab social on;/lab overlay compact;/lab step;/lab step;/lab social status;/lab movement on;/lab step;/lab step;/lab step;/lab step;/lab social status;/lab causality status;/lab causality tail 20;/lab status;/lab movement off;/lab social off;/lab social status"
elif [ "$MODE" = "build" ]; then
    WORLD_SEED=${PEBBLELAB_BUILD_SEED:-46}
    NATURAL_GATE=1
    BUILD_GATE=1
    WORLD_NAME="PebbleLab-Disposable-Build-$WORLD_SEED"
    CAPTURE_NAME="fixed-shelter-complete.png"
    BUILD_ANCHOR_X=${PEBBLELAB_BUILD_ANCHOR_X:-20}
    BUILD_ANCHOR_Z=${PEBBLELAB_BUILD_ANCHOR_Z:--24}
    BUILD_ANCHOR_Y=${PEBBLELAB_BUILD_ANCHOR_Y:-66}
    BUILD_PLAYER_Y=$((BUILD_ANCHOR_Y + 3))
    LAB_COMMANDS="/tp $BUILD_ANCHOR_X $BUILD_ANCHOR_Y $BUILD_ANCHOR_Z|/lab start;/tp $BUILD_ANCHOR_X $BUILD_PLAYER_Y $BUILD_ANCHOR_Z;/lab pause;/lab movement off;/lab focus agent_2;/lab follow agent_2;/lab natural on;/lab build setup;/lab economy auto on;/lab build auto on;/lab movement on;/lab overlay off;/lab follow off;/tp $BUILD_ANCHOR_X $BUILD_ANCHOR_Y $BUILD_ANCHOR_Z -60 10;/lab build status|"
    BUILD_STEPS=${PEBBLELAB_BUILD_STEPS:-112}
    build_step=0
    while [ "$build_step" -lt "$BUILD_STEPS" ]; do
        LAB_COMMANDS="$LAB_COMMANDS;/lab step"
        build_step=$((build_step + 1))
    done
    LAB_COMMANDS="$LAB_COMMANDS;/lab build auto off"
    build_step=0
    while [ "$build_step" -lt 4 ]; do
        LAB_COMMANDS="$LAB_COMMANDS;/lab step"
        build_step=$((build_step + 1))
    done
    LAB_COMMANDS="$LAB_COMMANDS;/lab build status|/lab build auto on"
    build_step=0
    while [ "$build_step" -lt 30 ]; do
        LAB_COMMANDS="$LAB_COMMANDS;/lab step"
        build_step=$((build_step + 1))
    done
    LAB_COMMANDS="$LAB_COMMANDS;/lab build status;/lab survival on"
    build_step=0
    while [ "$build_step" -lt 8 ]; do
        LAB_COMMANDS="$LAB_COMMANDS;/lab step"
        build_step=$((build_step + 1))
    done
    LAB_COMMANDS="$LAB_COMMANDS;/lab survival status;/lab build status;/lab economy status;/lab natural status;/lab causality status;/lab causality tail 20;/lab overlay compact|/lab survival off;/lab movement off;/lab build clear;/lab build status;/lab economy status;/lab natural status;/lab status;/lab causality status;/lab causality tail 20"
elif [ "$MODE" = "natural" ]; then
    WORLD_SEED="46"
    NATURAL_GATE=1
    WORLD_NAME="PebbleLab-Disposable-Natural-46"
    CAPTURE_NAME="natural-wood-stone-harvest.png"
    LAB_COMMANDS='/tp 19 68 -21;/lab start;/tp 19 71 -21;/lab pause;/lab movement off;/lab focus agent_2;/lab follow agent_2;/lab natural on;/lab economy auto on;/lab movement on;/lab overlay full;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab natural status;/lab economy status;/lab status'
elif [ "$MODE" = "h2" ]; then
    WORLD_NAME="PebbleLab-Disposable-H2-12345"
    CAPTURE_NAME="h2-navigate-harvest.png"
    LAB_COMMANDS='/lab start;/lab pause;/lab movement off;/lab focus agent_2;/lab interaction setup distant 4;/lab interaction auto on;/lab movement on;/lab overlay full;/lab step;/lab step;/lab step;/lab step;/lab interaction status;/lab status'
elif [ "$MODE" = "economy" ]; then
    WORLD_NAME="PebbleLab-Disposable-I-12345"
    CAPTURE_NAME="phase-i-closed-economy.png"
    LAB_COMMANDS='/lab start;/lab pause;/lab movement off;/lab focus agent_2;/lab economy setup;/lab economy auto on;/lab movement on;/lab overlay full;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab economy status;/lab status'
else
    WORLD_NAME="PebbleLab-Disposable-J-12345"
    CAPTURE_NAME="phase-j-autonomous-survival.png"
    LAB_COMMANDS='/lab start;/lab pause;/lab movement off;/lab focus agent_2;/lab economy setup;/lab survival on;/lab overlay full;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab economy auto on;/lab movement on;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab survival status;/lab economy status;/lab status'
fi

if [ "${PEBBLE_REGOLD+x}" = x ]; then
    printf 'PEBBLE_REGOLD must be absent (an empty value is also refused).\n' >&2
    exit 1
fi

print_plan() {
    session_root=$1
    capture_path=$2
    trace_path=$3
    printf 'PebbleLab live verification launcher\n'
    printf 'Scenario: %s\n' "$MODE"
    printf 'Repository: %s\n' "$ROOT_DIR"
    printf 'Runbook: %s\n' "$RUNBOOK"
    printf 'Isolated session root: %s\n' "$session_root"
    printf 'Disposable world name: %s\n' "$WORLD_NAME"
    printf 'Fixed seed: %s\n' "$WORLD_SEED"
    if [ "$MODE" = "production" ]; then
        capture_dir=$(dirname "$capture_path")
        printf 'Captures: %s\n' "$capture_dir/production-workshop.png"
        printf '          %s\n' "$capture_dir/production-tool.png"
        printf '          %s\n' "$capture_dir/production-output.png"
        printf '          %s\n' "$capture_dir/production-restored.png"
        printf '          %s\n' "$capture_dir/production-used.png"
        printf '          %s\n' "$capture_path"
    elif [ "$MODE" = "work-demand-refresh" ]; then
        capture_dir=$(dirname "$capture_path")
        printf 'Captures: %s\n' "$capture_dir/corr04-before-first-refresh.png"
        printf '          %s\n' "$capture_dir/corr04-after-first-refresh.png"
        printf '          %s\n' "$capture_path"
    elif [ "$MODE" = "integrated-teaching" ]; then
        capture_dir=$(dirname "$capture_path")
        printf 'Captures: %s\n' "$capture_dir/integrated-teaching-before.png"
        printf '          %s\n' "$capture_dir/integrated-teaching-apprenticeship.png"
        printf '          %s\n' "$capture_dir/integrated-teaching-demonstration-context.png"
        printf '          %s\n' "$capture_path"
    elif [ "$MODE" = "gate-b-passive" ]; then
        capture_dir=$(dirname "$capture_path")
        printf 'Captures: %s\n' "$capture_dir/gate-b2-start.png"
        printf '          %s\n' "$capture_dir/gate-b2-multi-agent.png"
        printf '          %s\n' "$capture_dir/gate-b2-agriculture.png"
        printf '          %s\n' "$capture_dir/gate-b2-livestock.png"
        printf '          %s\n' "$capture_dir/gate-b2-follow-agent.png"
        printf '          %s\n' "$capture_path"
    elif [ "$MODE" = "work-professions" ]; then
        capture_dir=$(dirname "$capture_path")
        printf 'Captures: %s\n' "$capture_dir/work-professions-initial.png"
        printf '          %s\n' "$capture_dir/work-professions-specialized.png"
        printf '          %s\n' "$capture_dir/work-professions-crisis.png"
        printf '          %s\n' "$capture_path"
    elif [ "$MODE" = "physical-food-survival" ]; then
        capture_dir=$(dirname "$capture_path")
        printf 'Captures: %s\n' "$capture_dir/physical-food-before.png"
        printf '          %s\n' "$capture_dir/physical-food-acquired.png"
        printf '          %s\n' "$capture_dir/physical-food-consumed.png"
        printf '          %s\n' "$capture_path"
    elif [ "$MODE" = "build" ]; then
        capture_dir=$(dirname "$capture_path")
        printf 'Captures: %s\n' "$capture_dir/fixed-shelter-before.png"
        printf '          %s\n' "$capture_dir/fixed-shelter-partial.png"
        printf '          %s\n' "$capture_path"
    elif [ "$MODE" = "physical" ]; then
        capture_dir=$(dirname "$capture_path")
        printf 'Captures: %s\n' "$capture_dir/physical-before.png"
        printf '          %s\n' "$capture_dir/physical-during.png"
        printf '          %s\n' "$capture_path"
    elif [ "$MODE" = "cooperation" ]; then
        capture_dir=$(dirname "$capture_path")
        printf 'Captures: %s\n' "$capture_dir/cooperation-before.png"
        printf '          %s\n' "$capture_dir/cooperation-offer.png"
        printf '          %s\n' "$capture_path"
    else
        printf 'Capture: %s\n' "$capture_path"
    fi
    printf 'Trace: %s\n' "$trace_path"
    printf '\nEnvironment:\n'
    printf '  CFFIXED_USER_HOME=%s/home\n' "$session_root"
    printf '  PEBBLE_AUTOLOAD=1\n'
    printf '  PEBBLE_NEWWORLD=%s\n' "$WORLD_SEED"
    printf '  PEBBLE_NEWWORLD_NAME=%s\n' "$WORLD_NAME"
    printf '  disposable world dynamics: random ticks, mob spawning, daylight, and weather disabled\n'
    printf '  PEBBLELAB_APP_AGENTS=1\n'
    printf '  PEBBLELAB_APP_AGENTS_MOVE=1\n'
    printf '  PEBBLELAB_APP_PROBES=1\n'
    printf '  PEBBLELAB_DEBUG_ENTITIES=1\n'
    printf '  PEBBLELAB_APP_AGENTS_OVERLAY=1\n'
    printf '  PEBBLELAB_APP_AGENTS_TRACE=1\n'
    printf '  PEBBLELAB_APP_AGENTS_TRACE_EVERY=1\n'
    printf '  PEBBLELAB_APP_AGENTS_INTERACT=1\n'
    printf '  PEBBLELAB_APP_AGENTS_NATURAL=%s\n' "$NATURAL_GATE"
    printf '  PEBBLELAB_APP_AGENTS_BUILD=%s\n' "$BUILD_GATE"
    printf '  PEBBLELAB_APP_AGENTS_SOCIAL=%s\n' "$SOCIAL_GATE"
    printf '  PEBBLELAB_APP_AGENTS_PHYSICAL=%s\n' "$PHYSICAL_GATE"
    printf '  PEBBLELAB_APP_AGENTS_MATERIAL=%s\n' "$MATERIAL_GATE"
    printf '  PEBBLELAB_APP_AGENTS_COOPERATION=%s\n' "$COOPERATION_GATE"
    printf '  PEBBLELAB_APP_AGENTS_PERSISTENCE=%s\n' "$PERSISTENCE_GATE"
    printf '  PEBBLELAB_APP_AGENTS_POPULATION=%s\n' "$POPULATION_GATE"
    printf '  PEBBLELAB_APP_AGENTS_MULTISCALE=%s\n' "$MULTISCALE_GATE"
    printf '  PEBBLELAB_APP_AGENTS_ECOLOGY=%s\n' "$ECOLOGY_GATE"
    printf '  PEBBLELAB_APP_AGENTS_MORTALITY=%s\n' "$MORTALITY_GATE"
    printf '  PEBBLELAB_APP_AGENTS_LIFECYCLE=%s\n' "$LIFECYCLE_GATE"
    printf '  PEBBLELAB_APP_AGENTS_KINSHIP=%s\n' "$KINSHIP_GATE"
    printf '  PEBBLELAB_APP_AGENTS_HOUSEHOLDS=%s\n' "$HOUSEHOLD_GATE"
    printf '  PEBBLELAB_APP_AGENTS_CARE=%s\n' "$CARE_GATE"
    printf '  PEBBLELAB_APP_AGENTS_SKILLS=%s\n' "$SKILL_GATE"
    printf '  PEBBLELAB_APP_AGENTS_TEACHING=%s\n' "$TEACHING_GATE"
    printf '  PEBBLELAB_APP_AGENTS_ECOLOGICAL_OBSERVATION=%s\n' "$ECOLOGICAL_OBSERVATION_GATE"
    printf '  PEBBLELAB_APP_AGENTS_AGRICULTURE=%s\n' "$AGRICULTURE_GATE"
    printf '  PEBBLELAB_APP_AGENTS_WILD_SUBSISTENCE=%s\n' "$WILD_SUBSISTENCE_GATE"
    printf '  PEBBLELAB_APP_AGENTS_LIVESTOCK=%s\n' "$LIVESTOCK_GATE"
    printf '  PEBBLELAB_APP_AGENTS_WORK_PROFESSIONS=%s\n' "$WORK_PROFESSIONS_GATE"
    printf '  PEBBLELAB_APP_AGENTS_PRODUCTION=%s\n' "$PRODUCTION_GATE"
    printf '  PEBBLELAB_APP_AGENTS_BARTER=%s\n' "$BARTER_GATE"
    printf '  PEBBLELAB_APP_AGENTS_CONTRACTS=%s\n' "$CONTRACT_GATE"
    printf '  PEBBLELAB_APP_AGENTS_MARKETS=%s\n' "$MARKET_GATE"
    if [ "$GATE_E_BLOCKER_04" -eq 1 ]; then
        printf '  PEBBLELAB_APP_AGENTS_OBSERVER=1\n'
        printf '  PEBBLELAB_GATE_E_BLOCKER_04=1\n'
    fi
    printf '  PEBBLELAB_APP_AGENTS_AUTONOMOUS_CIVILIZATION=%s\n' "$AUTONOMOUS_CIVILIZATION_GATE"
    printf '  PEBBLELAB_INTEGRATED_TEACHING_PROOF=%s\n' "$INTEGRATED_TEACHING_PROOF"
    printf '  PEBBLELAB_PASSIVE_OBSERVER_INPUT_PROOF=%s\n' "$PASSIVE_OBSERVER_INPUT_PROOF"
    printf '  PEBBLELAB_PASSIVE_OBSERVER_BATCH_FRAMES=%s\n' "$PASSIVE_OBSERVER_BATCH_FRAMES"
    printf '  PEBBLELAB_WORK_DEMAND_REFRESH_PROOF=%s\n' "$WORK_DEMAND_REFRESH_PROOF"
    printf '  PEBBLELAB_GATE_B3_ACCEPTANCE=%s\n' "$GATE_B3_ACCEPTANCE"
    printf '  PEBBLELAB_GATE_B3_COGNITIVE_HZ=%s\n' "$GATE_B3_COGNITIVE_HZ"
    printf '  PEBBLELAB_GATE_B3_HORIZON=%s\n' "$GATE_B3_HORIZON"
    printf '  PEBBLELAB_DISPOSABLE_WORLD_PROOF=1\n'
    printf '  PEBBLE_CMD=%s\n' "$LAB_COMMANDS"
    if [ "$MODE" = "markets" ]; then
        printf '  Restart 2 PEBBLE_CMD=%s\n' "$MARKET_PHASE2_COMMANDS"
        printf '  Restart 3 PEBBLE_CMD=%s\n' "$MARKET_PHASE3_COMMANDS"
        printf '  Restart 4 PEBBLE_CMD=%s\n' "$MARKET_PHASE4_COMMANDS"
    elif [ "$MODE" = "contracts" ]; then
        printf '  Capacity proof PEBBLE_CMD=%s\n' "$CONTRACT_CAPACITY_COMMANDS"
        printf '  PEBBLE_SHOT=-|%s/contract-before-promise.png|%s/contract-proposal.png|%s/contract-consideration-publication-rollback.png|%s/contract-open-debt.png\n' \
            "$(dirname "$capture_path")" "$(dirname "$capture_path")" \
            "$(dirname "$capture_path")" "$(dirname "$capture_path")"
        printf '  Restart 2 PEBBLE_CMD=%s\n' "$CONTRACT_PHASE2_COMMANDS"
        printf '  Restart 3 PEBBLE_CMD=%s\n' "$CONTRACT_PHASE3_COMMANDS"
    elif [ "$MODE" = "barter" ]; then
        printf '  2. Confirm two local residents retain distinct produced goods before exchange.\n'
        printf '  3. Confirm offer, acceptance, compensated mid-transfer fault, exact retry, and swapped custody.\n'
        printf '  4. Confirm the fresh process preserves one exchange and the receiver uses the produced pickaxe.\n'
    elif [ "$MODE" = "production" ]; then
        printf '  PEBBLE_SHOT=-|%s/production-workshop.png|%s/production-tool.png|%s/production-output.png\n' \
            "$(dirname "$capture_path")" "$(dirname "$capture_path")" \
            "$(dirname "$capture_path")"
        printf '  Restart PEBBLE_CMD=%s\n' "$PRODUCTION_PHASE2_COMMANDS"
        printf '  Restart PEBBLE_SHOT=%s/production-restored.png|%s/production-used.png|%s\n' \
            "$(dirname "$capture_path")" "$(dirname "$capture_path")" \
            "$capture_path"
    elif [ "$MODE" = "work-demand-refresh" ]; then
        printf '  PEBBLE_SHOT=%s@999999\n' "$capture_path"
    elif [ "$MODE" = "integrated-teaching" ]; then
        printf '  PEBBLE_SHOT=-|%s/integrated-teaching-before.png|%s/integrated-teaching-apprenticeship.png|%s/integrated-teaching-demonstration-context.png|%s\n' \
            "$(dirname "$capture_path")" "$(dirname "$capture_path")" \
            "$(dirname "$capture_path")" "$capture_path"
    elif [ "$MODE" = "gate-b-passive" ]; then
        printf '  PEBBLE_SHOT=-|%s/gate-b2-start.png|%s/gate-b2-multi-agent.png|%s/gate-b2-agriculture.png|%s/gate-b2-livestock.png|%s/gate-b2-follow-agent.png|%s\n' \
            "$(dirname "$capture_path")" "$(dirname "$capture_path")" \
            "$(dirname "$capture_path")" "$(dirname "$capture_path")" \
            "$(dirname "$capture_path")" "$capture_path"
    elif [ "$MODE" = "physical-food-survival" ]; then
        printf '  PEBBLE_SHOT=-|%s/physical-food-before.png|-|-|%s/physical-food-acquired.png|%s/physical-food-consumed.png|%s\n' \
            "$(dirname "$capture_path")" "$(dirname "$capture_path")" \
            "$(dirname "$capture_path")" "$capture_path"
    elif [ "$MODE" = "build" ]; then
        printf '  PEBBLE_SHOT=-|%s/fixed-shelter-before.png|%s/fixed-shelter-partial.png|%s|-\n' \
            "$(dirname "$capture_path")" "$(dirname "$capture_path")" "$capture_path"
    elif [ "$MODE" = "physical" ]; then
        printf '  PEBBLE_SHOT=%s/physical-before.png|%s/physical-during.png|%s\n' \
            "$(dirname "$capture_path")" "$(dirname "$capture_path")" "$capture_path"
    elif [ "$MODE" = "rights" ]; then
        printf '  PEBBLE_SHOT=-|%s|-\n' "$capture_path"
    elif [ "$MODE" = "cooperation" ]; then
        printf '  PEBBLE_SHOT=%s/cooperation-before.png|%s/cooperation-offer.png|%s\n' \
            "$(dirname "$capture_path")" "$(dirname "$capture_path")" "$capture_path"
    elif [ "$MODE" = "work-professions" ]; then
        printf '  PEBBLE_SHOT=-|%s/work-professions-initial.png|-|%s/work-professions-specialized.png|%s/work-professions-crisis.png|%s\n' \
            "$(dirname "$capture_path")" "$(dirname "$capture_path")" \
            "$(dirname "$capture_path")" "$capture_path"
    elif [ "$MODE" = "wild-subsistence" ]; then
        printf '  PEBBLE_SHOT=-|-|%s/subsistence-fishing.png|%s/subsistence-hunting.png|%s/subsistence-gathering.png|%s\n' \
            "$(dirname "$capture_path")" "$(dirname "$capture_path")" \
            "$(dirname "$capture_path")" "$capture_path"
    elif [ "$MODE" = "livestock" ]; then
        printf '  PEBBLE_SHOT=-|-|%s/livestock-managed.png|%s/livestock-feeding.png|%s/livestock-offspring.png|%s/livestock-product.png|%s\n' \
            "$(dirname "$capture_path")" "$(dirname "$capture_path")" \
            "$(dirname "$capture_path")" "$(dirname "$capture_path")" "$capture_path"
    elif [ "$MODE" = "agriculture" ]; then
        printf '  PEBBLE_SHOT=%s@1200\n' "$capture_path"
    else
        printf '  PEBBLE_SHOT=%s@240\n' "$capture_path"
    fi
    printf '\nExisting /lab commands executed after the disposable World is ready:\n'
    old_ifs=$IFS
    IFS=';|'
    for command in $LAB_COMMANDS; do printf '  %s\n' "$command"; done
    IFS=$old_ifs
    printf '\nOperator checks:\n'
    printf '  1. Wait for automatic disposable-world creation, commands, capture, and normal termination.\n'
    if [ "$MODE" = "markets" ] && [ "$GATE_E_BLOCKER_04" -eq 1 ]; then
        printf '  2. Confirm ordinary contract cognition commits the exact pickaxe while ordinary market discovery observes but cannot select it.\n'
        printf '  3. Confirm fresh restore preserves the exclusion, same-contract continuation transfers consideration, and terminal progress releases the commitment.\n'
        printf '  4. Confirm ordinary barter reuses the released pickaxe, remains the sole live commitment while the bounded stall admits no new lot, and completes both real physical legs exactly once.\n'
        printf '  5. Confirm terminal release survives the final fresh restore, permits one ordinary market reuse, then reaches bounded withdrawal without barter replay.\n'
        printf '  6. Confirm schema 34, Observer schema 11, exact current authority, conservation, and zero duplicate commitments or receipts.\n'
    elif [ "$MODE" = "markets" ]; then
        printf '  2. Confirm normal deposit/listing behavior and an open physical lot at the first checkpoint.\n'
        printf '  3. Confirm normal seller rejection/acceptance, then a real remote buyer refusal with zero mutation/publication and exact locality restore.\n'
        printf '  4. Confirm both exact rollback faults, immediate retry, and one completed local price row.\n'
        printf '  5. Confirm restored history causally changes a later quote, the second trade completes, and the unsold lot is physically withdrawn.\n'
        printf '  6. Confirm a final fresh restore does not repeat settlement or withdrawal, then restores the empty stall cell.\n'
    elif [ "$MODE" = "contracts" ]; then
        printf '  2. Confirm saturated production-need capacity refuses before consideration mutation.\n'
        printf '  3. Confirm ordinary consideration publication failure rolls back before the retry opens debt.\n'
        printf '  4. Confirm process two restores open debt, normally produces bread, rolls back explicit and ordinary fulfillment failures, and retries.\n'
        printf '  5. Confirm process three preserves fulfilled state and executes no duplicate fulfillment.\n'
    elif [ "$MODE" = "production" ]; then
        printf '  2. Confirm the real crafting table transforms exact canonical inputs into a stone pickaxe and bread.\n'
        printf '  3. Confirm the negative matrix, true late rollback, immediate retry, contention, and reserved-input refusal.\n'
        printf '  4. Confirm a fresh process restores exact custody/history, then the produced pickaxe breaks real stone with damage 0->1.\n'
    elif [ "$MODE" = "work-demand-refresh" ]; then
        printf '  2. Observe normal Player movement while the single integrated society crosses repeated Work reviews.\n'
        printf '  3. Confirm the three captures bracket tick 4 and show a later unfrozen society.\n'
        printf '  4. Confirm refresh traces distinguish heartbeats, newer provenance, and new logical demands.\n'
    elif [ "$MODE" = "integrated-teaching" ]; then
        printf '  2. After PLAYABLE_SLICE_BOOTSTRAP_COMPLETE, issue no productive command and observe the normal autonomous timeline.\n'
        printf '  3. Confirm one inhabitant becomes practiced only through real work before a local apprenticeship starts.\n'
        printf '  4. Confirm a later real mentor success is observed, then the student earns practice only from their own success.\n'
    elif [ "$MODE" = "gate-b-passive" ]; then
        printf '  2. After PLAYABLE_SLICE_BOOTSTRAP_COMPLETE, issue no productive command; normal walking and mouse look remain available.\n'
        printf '  3. Observe agriculture, livestock, wild subsistence, physical eating, and a cross-family switch in one World.\n'
        printf '  4. Confirm real GameCore key/mouse input moves the Player while cognition and physical actions continue.\n'
    elif [ "$MODE" = "physical-food-survival" ]; then
        printf '  2. Inspect the hungry agent and mature berry context before acquisition.\n'
        printf '  3. Confirm the gathered ItemStack appears in real custody, then decreases by exactly one.\n'
        printf '  4. Confirm the trace proves shadow foodRaw rejection and the same canonical hunger changing.\n'
    elif [ "$MODE" = "work-professions" ]; then
        printf '  2. Inspect initial, specialized, crisis, and final PNGs with the work/profile overlay.\n'
        printf '  3. Confirm fishing, hunting, and gathering remain real PebbleCore work with exact custody.\n'
        printf '  4. Confirm the crisis suspends/resumes responsibility and no profile grants output or permission.\n'
    elif [ "$MODE" = "livestock" ]; then
        printf '  2. Inspect managed, feeding, offspring, product/herding, and final PNGs; the final herd retains one adult and the real juvenile.\n'
        printf '  3. Confirm the trace proves the removed adult as loss and zero CampStock, ResourceInventory, or LocalEcology credit.\n'
        printf '  4. Confirm movement came from Core leash physics and wool entered real custody.\n'
    elif [ "$MODE" = "wild-subsistence" ]; then
        printf '  2. Confirm the real water/agent fishing context; the trace proves the canonical bobber cycle and removal.\n'
        printf '  3. Confirm one real chicken is absent/dead after Core combat and no duplicate prey/drop exists.\n'
        printf '  4. Confirm the berry source is physically depleted and all acquired items remain in real custody.\n'
    elif [ "$MODE" = "agriculture" ]; then
        printf '  2. Confirm the retained field shows hydrated farmland, water, two real wheat crops, and a chest.\n'
        printf '  3. Confirm Core random growth, canonical drops, real custody, seed reserve, and live container surplus.\n'
        printf '  4. Confirm stale/capacity/late failures roll back and live farm creates zero abstract stock credit.\n'
    elif [ "$MODE" = "ecological-observation" ]; then
        printf '  2. Confirm agent_0 observes real local biome, water, soil, crop, plant, cow, and fishing affordance.\n'
        printf '  3. Confirm crop stage and rain change only after real World fixture changes; no scan mutates World or materials.\n'
        printf '  4. Confirm same-tick cache, unloaded chunk refusal, World replacement invalidation, and schema v12 checkpoint.\n'
    elif [ "$MODE" = "teaching" ]; then
        printf '  2. Confirm teacher and student resolve to real Pebble embodiments in local CIV-04 range.\n'
        printf '  3. Confirm observation grants zero skill and the student real harvest grants exactly one.\n'
        printf '  4. Confirm out-of-range exposure is refused and both deterministic runs clean up exactly.\n'
    elif [ "$MODE" = "skills" ]; then
        printf '  2. Confirm explicit v9 to v10 activation grants no retroactive practice.\n'
        printf '  3. Confirm real forage/delivery practice changes one cooperative helper selection.\n'
        printf '  4. Confirm process restart, independent control, and late physical rollback are exact.\n'
    elif [ "$MODE" = "care" ]; then
        printf '  2. Confirm explicit v8 to v9 activation and deterministic caregiver assignment.\n'
        printf '  3. Confirm agent_4 remains passive while its caregiver moves and debits real food.\n'
        printf '  4. Confirm process restart preserves care, households, resources, and digests exactly.\n'
    elif [ "$MODE" = "households" ]; then
        printf '  2. Confirm explicit v7 to v8 activation groups the four residents by home position.\n'
        printf '  3. Confirm the true birth gives agent_4 one household membership without World mutation.\n'
        printf '  4. Confirm process restart preserves households, memberships, homes, and digests exactly.\n'
    elif [ "$MODE" = "kinship" ]; then
        printf '  2. Confirm explicit kinship activation archives the four historical roots in schema v7.\n'
        printf '  3. Confirm the true CIV-11 birth records agent_4 -> agent_0,agent_1 without World mutation.\n'
        printf '  4. Confirm process restart preserves people, parentage, durable digest, and kinship digest exactly.\n'
    elif [ "$MODE" = "reproduction" ]; then
        printf '  2. Confirm four mature residents, one deterministic plan, and a restart-safe v6 mid-plan checkpoint.\n'
        printf '  3. Confirm one read-only birth site, agent_4, five probes, and a restart-safe post-birth checkpoint.\n'
        printf '  4. Confirm exact newborn, juvenile, and mature thresholds plus uninterrupted equivalence.\n'
    elif [ "$MODE" = "mortality" ]; then
        printf '  2. Confirm four residents and exactly one naturally lethal starvation transition.\n'
        printf '  3. Confirm v5 pre/post-death restart, exact probe exit, focus reconciliation, and no terminal action.\n'
        printf '  4. Confirm agent_4 physically replaces the exited member and matches uninterrupted control.\n'
    elif [ "$MODE" = "ecology" ]; then
        printf '  2. Confirm four residents, two read-only habitat patches, and bounded local perception.\n'
        printf '  3. Confirm transactional forage, scarcity, starvation damage, deterministic regeneration, and recovery.\n'
        printf '  4. Confirm v4 restart and uninterrupted control preserve patches, pressure, material, and causal digests.\n'
    elif [ "$MODE" = "multiscale" ]; then
        printf '  2. Confirm four micro ticks, one macro pulse, four agents, and no coarse execution.\n'
        printf '  3. Confirm a v3 restart-safe checkpoint restores frame 1 and its pulse clock exactly.\n'
        printf '  4. Confirm restart, uninterrupted, and metrics-off controls preserve all micro decisions.\n'
    elif [ "$MODE" = "population" ]; then
        printf '  2. Confirm three historical founders, deterministic agent_3 admission, and exactly four probes.\n'
        printf '  3. Confirm a v2 restart-safe checkpoint after exactly two successful migrant movements.\n'
        printf '  4. Confirm restart and uninterrupted control reach the same resident state and causal digest.\n'
    elif [ "$MODE" = "persistence" ]; then
        printf '  2. Confirm accepted-task is restartSafe with zero harvests, placements, inventory, and stock.\n'
        printf '  3. Confirm a second process restores the exact tick, simulation, digest, task, and three probes.\n'
        printf '  4. Confirm replay matches live final state and the uninterrupted control digest.\n'
    elif [ "$MODE" = "cooperation" ]; then
        printf '  2. Confirm agent_2 physically offers a three-stone task only to agent_1.\n'
        printf '  3. Confirm helper stone delivery, builder wood delivery, funding, 9/9 construction, and exact conservation.\n'
    elif [ "$MODE" = "embodiment" ]; then
        printf '  2. Confirm Core path selection and Entity.move own every tested physical step.\n'
        printf '  3. Confirm missing, duplicate, stale-World, conflict, gap, and late publication are refused.\n'
        printf '  4. Confirm CIV-17/18 reach proofs use the same embodiment and cleanup remains exact.\n'
    elif [ "$MODE" = "construction" ]; then
        printf '  2. Confirm nine ordered cells use three real stone and six real oak-log items through PebbleCore.\n'
        printf '  3. Confirm all refusal and late-failure probes preserve World, custody, project, causality, and skill.\n'
    elif [ "$MODE" = "harvest" ]; then
        printf '  2. Confirm two identical CIV-17 proof digests with canonical log and cobblestone drops.\n'
        printf '  3. Confirm exact unrelated-item, capacity, wrong-tool, stale, duplicate, and late rollback evidence.\n'
        printf '  4. Confirm real tool damage/custody, two causal successes, two practice credits, and zero ghost stock.\n'
    elif [ "$MODE" = "material" ]; then
        printf '  2. Confirm two identical stable-identity and real custody proof digests.\n'
        printf '  3. Confirm real container transfer, consume, stale/idempotent refusal, and verified rollback.\n'
        printf '  4. Confirm CIV-15 placement/tool state use real stacks and cleanup leaves no material fixture.\n'
    elif [ "$MODE" = "rights" ]; then
        printf '  2. Confirm the rendered overlay shows holder agent_2, custodian agent_1, and owner agent_0.\n'
        printf '  3. Confirm the real transfer path records permission, transgression, conflict, and rollback.\n'
        printf '  4. Confirm post-capture cleanup removes proof custody and leaves no residual entity.\n'
    elif [ "$MODE" = "physical" ]; then
        printf '  2. Confirm agent_1 emits one positional attention sound and one bounded pointing gesture.\n'
        printf '  3. Confirm exact recipient perception, ambiguous bystander impression, read-only verification, and trust 0->10.\n'
    elif [ "$MODE" = "social" ]; then
        printf '  2. Confirm one direct natural fact from agent_1 and one directed delivery to agent_2.\n'
        printf '  3. Confirm bounded approach, read-only fingerprint match, trust 0->10, and no material delta.\n'
    elif [ "$MODE" = "build" ]; then
        printf '  2. Confirm read-only site selection, natural acquisition of 6 wood and 3 stone, and atomic funding.\n'
        printf '  3. Confirm exact work routes, one placement per tick, 9/9 completion, shelter home/rest, and conservation.\n'
    elif [ "$MODE" = "natural" ]; then
        printf '  2. Confirm zero fixtures, bounded natural scans, oak_log then stone targets, and existing routes.\n'
        printf '  3. Confirm both exact blocks become air permanently, stock wood/stone is 1/1, and conservation is exact.\n'
    elif [ "$MODE" = "h2" ]; then
        printf '  2. Inspect four tick records: route/index progression, three single steps, then harvest_block.\n'
        printf '  3. Confirm target reservation, adjacent arrival, inventory 0->1, resource_harvested, and no runtime error.\n'
    elif [ "$MODE" = "economy" ]; then
        printf '  2. Confirm two different fixtures are harvested before the delivery quota switches the goal.\n'
        printf '  3. Confirm bounded return_home steps, deliver_resource, empty inventory, camp stock 2, and exact conservation.\n'
    else
        printf '  2. Confirm hunger growth, satisfyHunger, food-only targeting, three route steps, harvest, and consume_food.\n'
        printf '  3. Confirm consumed=1 conservation, fatigue-driven homeRest, rest recovery, normal goal resumption, and zero corridor changes.\n'
    fi
    if [ "$MODE" != "persistence" ] && [ "$MODE" != "population" ] \
        && [ "$MODE" != "multiscale" ] && [ "$MODE" != "ecology" ] \
        && [ "$MODE" != "mortality" ] && [ "$MODE" != "reproduction" ] \
        && [ "$MODE" != "kinship" ] && [ "$MODE" != "households" ] \
        && [ "$MODE" != "care" ] && [ "$MODE" != "skills" ]; then
        if [ "$MODE" = "markets" ]; then
            printf '  7. Inspect the PNG manually; the hook does not provide a pixel assertion.\n'
        elif [ "$MODE" = "material" ] || [ "$MODE" = "rights" ] || [ "$MODE" = "production" ] || [ "$MODE" = "barter" ] || [ "$MODE" = "contracts" ] || [ "$MODE" = "harvest" ] || [ "$MODE" = "construction" ] || [ "$MODE" = "embodiment" ] || [ "$MODE" = "teaching" ] || [ "$MODE" = "integrated-teaching" ] || [ "$MODE" = "ecological-observation" ] || [ "$MODE" = "agriculture" ] || [ "$MODE" = "wild-subsistence" ] || [ "$MODE" = "physical-food-survival" ] || [ "$MODE" = "livestock" ] || [ "$MODE" = "work-professions" ] || [ "$MODE" = "work-demand-refresh" ] || [ "$MODE" = "gate-b-passive" ]; then
            printf '  5. Inspect the PNG manually; the hook does not provide a pixel assertion.\n'
        else
            printf '  4. Inspect the PNG manually; the hook does not provide a pixel assertion.\n'
        fi
    fi
    if [ "$MODE" = "markets" ]; then
        printf '  8. Keep or manually remove only this validated PebbleLab temporary session directory. The script deletes nothing.\n'
    elif [ "$MODE" = "material" ] || [ "$MODE" = "rights" ] || [ "$MODE" = "production" ] || [ "$MODE" = "barter" ] || [ "$MODE" = "contracts" ] || [ "$MODE" = "harvest" ] || [ "$MODE" = "construction" ] || [ "$MODE" = "embodiment" ] || [ "$MODE" = "teaching" ] || [ "$MODE" = "integrated-teaching" ] || [ "$MODE" = "ecological-observation" ] || [ "$MODE" = "agriculture" ] || [ "$MODE" = "wild-subsistence" ] || [ "$MODE" = "physical-food-survival" ] || [ "$MODE" = "livestock" ] || [ "$MODE" = "work-professions" ] || [ "$MODE" = "work-demand-refresh" ] || [ "$MODE" = "gate-b-passive" ]; then
        printf '  6. Keep or manually remove only this validated PebbleLab temporary session directory. The script deletes nothing.\n'
    else
        printf '  5. Keep or manually remove only this validated PebbleLab temporary session directory. The script deletes nothing.\n'
    fi
}

if [ "$DRY_RUN" -eq 1 ]; then
    DRY_TMP_BASE=${TMPDIR:-/tmp}
    DRY_TMP_BASE=${DRY_TMP_BASE%/}
    print_plan "$DRY_TMP_BASE/PebbleLab-live.XXXXXX" \
        "$DRY_TMP_BASE/PebbleLab-live.XXXXXX/captures/$CAPTURE_NAME" \
        "$DRY_TMP_BASE/PebbleLab-live.XXXXXX/pebble-live.log"
    printf '\nDRY RUN: Pebble was not launched and no directory was created.\n'
    exit 0
fi

require_repository_root "$ROOT_DIR"
[ -f "$RUNBOOK" ] || { printf 'Runbook not found: %s\n' "$RUNBOOK" >&2; exit 1; }
case "$WORLD_NAME" in
    PebbleLab-Disposable-*) ;;
    *) printf 'Refusing non-disposable world name: %s\n' "$WORLD_NAME" >&2; exit 1 ;;
esac

TMP_BASE=${TMPDIR:-/tmp}
TMP_BASE=${TMP_BASE%/}
SESSION_ROOT=$(mktemp -d "$TMP_BASE/PebbleLab-live.XXXXXX")
case "$SESSION_ROOT" in
    "$TMP_BASE"/PebbleLab-live.*) ;;
    *) printf 'Refusing unsafe temporary path: %s\n' "$SESSION_ROOT" >&2; exit 1 ;;
esac

SESSION_HOME="$SESSION_ROOT/home"
CAPTURE_DIR="$SESSION_ROOT/captures"
CAPTURE_PATH="$CAPTURE_DIR/$CAPTURE_NAME"
TRACE_PATH="$SESSION_ROOT/pebble-live.log"
[ ! -e "$SESSION_HOME" ] || fail "fresh isolated home already exists: $SESSION_HOME"
DB_PATH="$SESSION_HOME/Library/Application Support/Pebble/pebble.db"
[ ! -e "$DB_PATH" ] || fail "fresh disposable database already exists: $DB_PATH"
/bin/mkdir -p "$SESSION_HOME" "$CAPTURE_DIR"
if [ "$MODE" = "markets" ]; then
    if [ "$GATE_E_BLOCKER_04" -eq 1 ]; then
        CAPTURE_BLOCKER04_SETUP_PATH="$CAPTURE_DIR/blocker04-composed-setup.png"
        CAPTURE_BLOCKER04_EXCLUSION_PATH="$CAPTURE_DIR/blocker04-contract-blocks-market.png"
        CAPTURE_BLOCKER04_CHECKPOINT_PATH="$CAPTURE_DIR/blocker04-live-checkpoint.png"
        CAPTURE_BLOCKER04_RESTORED_PATH="$CAPTURE_DIR/blocker04-exclusion-restored.png"
        CAPTURE_BLOCKER04_CONTINUED_PATH="$CAPTURE_DIR/blocker04-contract-continuation.png"
        CAPTURE_BLOCKER04_RELEASED_PATH="$CAPTURE_DIR/blocker04-terminal-release.png"
        CAPTURE_BLOCKER04_BARTER_RESTORED_PATH="$CAPTURE_DIR/blocker04-release-restored.png"
        CAPTURE_BLOCKER04_BARTER_EXCLUSION_PATH="$CAPTURE_DIR/blocker04-barter-blocks-market.png"
        CAPTURE_BLOCKER04_BARTER_COMPLETED_PATH="$CAPTURE_DIR/blocker04-barter-completed.png"
        CAPTURE_BLOCKER04_BARTER_CHECKPOINT_PATH="$CAPTURE_DIR/blocker04-barter-checkpoint.png"
        CAPTURE_BLOCKER04_FINAL_RESTORE_PATH="$CAPTURE_DIR/blocker04-terminal-reuse-restored.png"
        CAPTURE_BLOCKER04_CLEANUP_READY_PATH="$CAPTURE_DIR/blocker04-cleanup-ready.png"
        SHOT_SPEC="-|$CAPTURE_BLOCKER04_SETUP_PATH|$CAPTURE_BLOCKER04_EXCLUSION_PATH|$CAPTURE_BLOCKER04_CHECKPOINT_PATH"
    else
    CAPTURE_BEFORE_PATH="$CAPTURE_DIR/market-established.png"
    CAPTURE_DEPOSITED_PATH="$CAPTURE_DIR/market-deposited.png"
    CAPTURE_OPEN_PATH="$CAPTURE_DIR/market-open-listing.png"
    CAPTURE_RESTORED_PATH="$CAPTURE_DIR/market-restored-open.png"
    CAPTURE_REMOTE_PATH="$CAPTURE_DIR/market-remote-buyer-refusal.png"
    CAPTURE_MID_FAULT_PATH="$CAPTURE_DIR/market-mid-settlement-rollback.png"
    CAPTURE_POST_FAULT_PATH="$CAPTURE_DIR/market-post-mutation-rollback.png"
    CAPTURE_COMPLETED_PATH="$CAPTURE_DIR/market-completed-trade.png"
    CAPTURE_HISTORY_PATH="$CAPTURE_DIR/market-restored-history.png"
    CAPTURE_LATER_PATH="$CAPTURE_DIR/market-history-informed-trade.png"
    CAPTURE_WITHDRAWAL_PATH="$CAPTURE_DIR/market-unsold-withdrawal.png"
    CAPTURE_FINAL_RESTORE_PATH="$CAPTURE_DIR/market-final-restored.png"
    if [ "$GATE_E_BLOCKER_03" -eq 1 ]; then
        CAPTURE_BLOCKER03_DEPOSIT_PATH="$CAPTURE_DIR/blocker03-ordinary-selection-and-deposit.png"
        CAPTURE_BLOCKER03_LISTING_PATH="$CAPTURE_DIR/blocker03-ordinary-listing.png"
        CAPTURE_BLOCKER03_CONTINUED_PATH="$CAPTURE_DIR/blocker03-continued-market-path.png"
    fi
    SHOT_SPEC="-|$CAPTURE_BEFORE_PATH|$CAPTURE_DEPOSITED_PATH|$CAPTURE_OPEN_PATH"
    fi
elif [ "$MODE" = "contracts" ]; then
    CAPTURE_CAPACITY_PATH="$CAPTURE_DIR/contract-capacity-refusal.png"
    CAPTURE_BEFORE_PATH="$CAPTURE_DIR/contract-before-promise.png"
    CAPTURE_PROPOSAL_PATH="$CAPTURE_DIR/contract-proposal.png"
    CAPTURE_CONSIDERATION_FAULT_PATH="$CAPTURE_DIR/contract-consideration-publication-rollback.png"
    CAPTURE_OPEN_PATH="$CAPTURE_DIR/contract-open-debt.png"
    CAPTURE_RESTORED_PATH="$CAPTURE_DIR/contract-restored-open-debt.png"
    CAPTURE_PRODUCED_PATH="$CAPTURE_DIR/contract-produced-bread.png"
    CAPTURE_FAULT_PATH="$CAPTURE_DIR/contract-fulfillment-rollback.png"
    CAPTURE_PUBLICATION_FAULT_PATH="$CAPTURE_DIR/contract-fulfillment-publication-rollback.png"
    CAPTURE_FULFILLED_PATH="$CAPTURE_DIR/contract-fulfilled.png"
    CAPTURE_VERIFIED_PATH="$CAPTURE_DIR/contract-restored-fulfilled.png"
    SHOT_SPEC="-|$CAPTURE_BEFORE_PATH|$CAPTURE_PROPOSAL_PATH|$CAPTURE_CONSIDERATION_FAULT_PATH|$CAPTURE_OPEN_PATH"
elif [ "$MODE" = "barter" ]; then
    CAPTURE_PRE_PATH="$CAPTURE_DIR/barter-pre-exchange.png"
    CAPTURE_OFFER_PATH="$CAPTURE_DIR/barter-offer.png"
    CAPTURE_POST_PATH="$CAPTURE_DIR/barter-post-exchange.png"
    CAPTURE_RESTORED_PATH="$CAPTURE_DIR/barter-restored.png"
    CAPTURE_USED_PATH="$CAPTURE_DIR/barter-produced-tool-used.png"
    SHOT_SPEC="-|$CAPTURE_PRE_PATH|$CAPTURE_OFFER_PATH|-|$CAPTURE_POST_PATH"
elif [ "$MODE" = "production" ]; then
    CAPTURE_WORKSHOP_PATH="$CAPTURE_DIR/production-workshop.png"
    CAPTURE_TOOL_PATH="$CAPTURE_DIR/production-tool.png"
    CAPTURE_OUTPUT_PATH="$CAPTURE_DIR/production-output.png"
    CAPTURE_RESTORED_PATH="$CAPTURE_DIR/production-restored.png"
    CAPTURE_USED_PATH="$CAPTURE_DIR/production-used.png"
    SHOT_SPEC="-|$CAPTURE_WORKSHOP_PATH|$CAPTURE_TOOL_PATH|$CAPTURE_OUTPUT_PATH"
elif [ "$MODE" = "work-demand-refresh" ]; then
    CAPTURE_BEFORE_PATH="$CAPTURE_DIR/corr04-before-first-refresh.png"
    CAPTURE_AFTER_PATH="$CAPTURE_DIR/corr04-after-first-refresh.png"
    SHOT_SPEC="$CAPTURE_PATH@999999"
elif [ "$MODE" = "integrated-teaching" ]; then
    CAPTURE_BEFORE_PATH="$CAPTURE_DIR/integrated-teaching-before.png"
    CAPTURE_APPRENTICESHIP_PATH="$CAPTURE_DIR/integrated-teaching-apprenticeship.png"
    CAPTURE_DEMONSTRATION_PATH="$CAPTURE_DIR/integrated-teaching-demonstration-context.png"
    SHOT_SPEC="-|$CAPTURE_BEFORE_PATH|$CAPTURE_APPRENTICESHIP_PATH|$CAPTURE_DEMONSTRATION_PATH|$CAPTURE_PATH"
elif [ "$MODE" = "gate-b-passive" ]; then
    CAPTURE_START_PATH="$CAPTURE_DIR/gate-b2-start.png"
    CAPTURE_MULTI_PATH="$CAPTURE_DIR/gate-b2-multi-agent.png"
    CAPTURE_AGRICULTURE_PATH="$CAPTURE_DIR/gate-b2-agriculture.png"
    CAPTURE_LIVESTOCK_PATH="$CAPTURE_DIR/gate-b2-livestock.png"
    CAPTURE_FOLLOW_PATH="$CAPTURE_DIR/gate-b2-follow-agent.png"
    SHOT_SPEC="-|$CAPTURE_START_PATH|$CAPTURE_MULTI_PATH|$CAPTURE_AGRICULTURE_PATH|$CAPTURE_LIVESTOCK_PATH|$CAPTURE_FOLLOW_PATH|$CAPTURE_PATH"
elif [ "$MODE" = "physical-food-survival" ]; then
    CAPTURE_BEFORE_PATH="$CAPTURE_DIR/physical-food-before.png"
    CAPTURE_ACQUIRED_PATH="$CAPTURE_DIR/physical-food-acquired.png"
    CAPTURE_CONSUMED_PATH="$CAPTURE_DIR/physical-food-consumed.png"
    SHOT_SPEC="-|$CAPTURE_BEFORE_PATH|-|-|$CAPTURE_ACQUIRED_PATH|$CAPTURE_CONSUMED_PATH|$CAPTURE_PATH"
elif [ "$MODE" = "work-professions" ]; then
    CAPTURE_INITIAL_PATH="$CAPTURE_DIR/work-professions-initial.png"
    CAPTURE_SPECIALIZED_PATH="$CAPTURE_DIR/work-professions-specialized.png"
    CAPTURE_CRISIS_PATH="$CAPTURE_DIR/work-professions-crisis.png"
    SHOT_SPEC="-|$CAPTURE_INITIAL_PATH|-|$CAPTURE_SPECIALIZED_PATH|$CAPTURE_CRISIS_PATH|$CAPTURE_PATH"
elif [ "$MODE" = "wild-subsistence" ]; then
    CAPTURE_FISHING_PATH="$CAPTURE_DIR/subsistence-fishing.png"
    CAPTURE_HUNTING_PATH="$CAPTURE_DIR/subsistence-hunting.png"
    CAPTURE_GATHERING_PATH="$CAPTURE_DIR/subsistence-gathering.png"
    SHOT_SPEC="-|-|$CAPTURE_FISHING_PATH|$CAPTURE_HUNTING_PATH|$CAPTURE_GATHERING_PATH|$CAPTURE_PATH"
elif [ "$MODE" = "livestock" ]; then
    CAPTURE_MANAGED_PATH="$CAPTURE_DIR/livestock-managed.png"
    CAPTURE_FEEDING_PATH="$CAPTURE_DIR/livestock-feeding.png"
    CAPTURE_OFFSPRING_PATH="$CAPTURE_DIR/livestock-offspring.png"
    CAPTURE_PRODUCT_PATH="$CAPTURE_DIR/livestock-product.png"
    SHOT_SPEC="-|-|$CAPTURE_MANAGED_PATH|$CAPTURE_FEEDING_PATH|$CAPTURE_OFFSPRING_PATH|$CAPTURE_PRODUCT_PATH|$CAPTURE_PATH"
elif [ "$MODE" = "build" ]; then
    CAPTURE_BEFORE_PATH="$CAPTURE_DIR/fixed-shelter-before.png"
    CAPTURE_PARTIAL_PATH="$CAPTURE_DIR/fixed-shelter-partial.png"
    SHOT_SPEC="-|$CAPTURE_BEFORE_PATH|$CAPTURE_PARTIAL_PATH|$CAPTURE_PATH|-"
elif [ "$MODE" = "physical" ]; then
    CAPTURE_BEFORE_PATH="$CAPTURE_DIR/physical-before.png"
    CAPTURE_DURING_PATH="$CAPTURE_DIR/physical-during.png"
    SHOT_SPEC="$CAPTURE_BEFORE_PATH|$CAPTURE_DURING_PATH|$CAPTURE_PATH"
elif [ "$MODE" = "rights" ]; then
    SHOT_SPEC="-|$CAPTURE_PATH|-"
elif [ "$MODE" = "cooperation" ]; then
    CAPTURE_BEFORE_PATH="$CAPTURE_DIR/cooperation-before.png"
    CAPTURE_DURING_PATH="$CAPTURE_DIR/cooperation-offer.png"
    SHOT_SPEC="$CAPTURE_BEFORE_PATH|$CAPTURE_DURING_PATH|$CAPTURE_PATH"
elif [ "$MODE" = "agriculture" ]; then
    SHOT_SPEC="$CAPTURE_PATH@1200"
else
    SHOT_SPEC="$CAPTURE_PATH@240"
fi

print_plan "$SESSION_ROOT" "$CAPTURE_PATH" "$TRACE_PATH"
printf '\nLaunching Pebble now. Personal Pebble data is hidden by CFFIXED_USER_HOME.\n\n'

if /usr/bin/pgrep -x Pebble >/dev/null 2>&1; then
    fail "a Pebble process is already running; refusing an ambiguous live baseline"
fi

if [ "$MODE" = "markets" ]; then
    cd "$ROOT_DIR"
    swift build -c release --product Pebble
    PEBBLE_BINARY="$ROOT_DIR/.build/release/Pebble"
    [ -x "$PEBBLE_BINARY" ] \
        || fail "Release Pebble binary missing: $PEBBLE_BINARY"

    PHASE1_TRACE="$SESSION_ROOT/market-phase1.log"
    PHASE2_TRACE="$SESSION_ROOT/market-phase2.log"
    PHASE3_TRACE="$SESSION_ROOT/market-phase3.log"
    PHASE4_TRACE="$SESSION_ROOT/market-phase4.log"

    run_market_app() {
        run_home=$1
        run_trace=$2
        run_commands=$3
        create_world=$4
        command_world_tick=$5
        run_shots=$6
        mid_fault=$7
        post_fault=$8
        if [ "$create_world" -eq 1 ]; then
            market_world_args="PEBBLE_NEWWORLD=$WORLD_SEED"
        else
            market_world_args=""
        fi
        env \
            CFFIXED_USER_HOME="$run_home" \
            PEBBLE_AUTOLOAD=1 \
            ${market_world_args:+$market_world_args} \
            PEBBLE_NEWWORLD_NAME="$WORLD_NAME" \
            PEBBLELAB_APP_AGENTS=1 \
            PEBBLELAB_APP_AGENTS_MOVE=1 \
            PEBBLELAB_APP_PROBES=1 \
            PEBBLELAB_DEBUG_ENTITIES=1 \
            PEBBLELAB_APP_AGENTS_OVERLAY=1 \
            PEBBLELAB_APP_AGENTS_TRACE=1 \
            PEBBLELAB_APP_AGENTS_TRACE_EVERY=1 \
            PEBBLELAB_APP_AGENTS_INTERACT=1 \
            PEBBLELAB_APP_AGENTS_OBSERVER="$((GATE_E_BLOCKER_03 + GATE_E_BLOCKER_04))" \
            PEBBLELAB_APP_AGENTS_MATERIAL=1 \
            PEBBLELAB_APP_AGENTS_PERSISTENCE=1 \
            PEBBLELAB_APP_AGENTS_PRODUCTION=1 \
            PEBBLELAB_APP_AGENTS_BARTER="$GATE_E_BLOCKER_04" \
            PEBBLELAB_APP_AGENTS_CONTRACTS="$GATE_E_BLOCKER_04" \
            PEBBLELAB_APP_AGENTS_MARKETS=1 \
            PEBBLELAB_APP_AGENTS_AUTONOMOUS_CIVILIZATION=1 \
            PEBBLELAB_DISPOSABLE_MARKET_MID_FAULT="$mid_fault" \
            PEBBLELAB_DISPOSABLE_MARKET_POST_MUTATION_FAULT="$post_fault" \
            PEBBLELAB_GATE_E_BLOCKER_03="$GATE_E_BLOCKER_03" \
            PEBBLELAB_GATE_E_BLOCKER_04="$GATE_E_BLOCKER_04" \
            PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
            PEBBLE_CMD_WORLD_TICK="$command_world_tick" \
            PEBBLE_CMD="$run_commands" \
            PEBBLE_SHOT="$run_shots" \
            "$PEBBLE_BINARY" 2>&1 | /usr/bin/tee "$run_trace"
        if /usr/bin/pgrep -x Pebble >/dev/null 2>&1; then
            fail "Pebble process remained after market phase: $run_trace"
        fi
    }

    if [ "$GATE_E_BLOCKER_04" -eq 1 ]; then
        printf '\nGate E Blocker 04 phase 1: ordinary contract commitment excludes the exact market asset.\n'
        run_market_app "$SESSION_HOME" "$PHASE1_TRACE" \
            "$MARKET_PHASE1_COMMANDS" 1 100 "$SHOT_SPEC" 0 0
        TRACE_PATH="$PHASE1_TRACE"
        for capture in \
            "$CAPTURE_BLOCKER04_SETUP_PATH" \
            "$CAPTURE_BLOCKER04_EXCLUSION_PATH" \
            "$CAPTURE_BLOCKER04_CHECKPOINT_PATH"; do
            [ -s "$capture" ] || fail "Blocker 04 phase-one capture missing: $capture"
        done
        require_trace 'market setup .*blocker04_bread3:1 .*blocker04CrossSystemSetup=1' 'bounded physical setup enables normal contract, barter, and market paths'
        require_trace 'contract normal promise proposal .*normalProposalDecision=1 proofFixtureDecisionAuthority=0 physicalMutation=0' 'ordinary contract cognition acquires the first exact commitment'
        require_trace 'blocker04 composed commitment authority asset=market-asset:0-initial-pickaxe .*contractLive=1 barterLive=0 marketLive=0 contractOpen=1 .*observedMarketOpportunities=1 ordinarySelectedTarget=0 targetDeposits=0 nonterminalTargetDeposits=0 excludedMarketAcquisition=1 crossSystemDuplicateLiveCommitments=0 .*exactCurrentAuthority=1 .*physicalLoss=0 physicalDuplication=0 syntheticMaterial=0 .*readOnly=1' 'ordinary market discovery sees but cannot select the contract-bound exact asset'
        require_trace 'checkpoint saved name=gate-e-blocker04-live-contract-v34 .*restartSafe=1 ' 'live composed exclusion is schema-34 restart safe'
        require_trace 'observer status .*schema=11 ' 'Observer remains schema 11 and read-only'
        require_trace 'summary .*runtimeErrors=0 .*probesRemoved=3 ' 'clean phase-one process termination'
        reject_trace 'market deposit completed .*asset=market-asset:0-initial-pickaxe|crossSystemDuplicateLiveCommitments=1|CANDIDATE_PHYSICAL_HARD_FAILURE' 'conflicting target deposit, duplicate commitment, or hard physical failure'

        PERSISTENCE_ROOT="$SESSION_HOME/Library/Application Support/Pebble/PebbleLabAgents"
        LIVE_SESSION=$(/usr/bin/find "$PERSISTENCE_ROOT" -type f -path '*/checkpoints/gate-e-blocker04-live-contract-v34/session.json' -print -quit)
        [ -n "$LIVE_SESSION" ] || fail "Blocker 04 live checkpoint missing"
        /usr/bin/grep -q '"schemaVersion":34' "$LIVE_SESSION" \
            || fail "Blocker 04 live checkpoint is not schema 34"
        LIVE_DIGEST=$(/usr/bin/sed -n 's/.*checkpoint saved name=gate-e-blocker04-live-contract-v34 .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' "$PHASE1_TRACE" | /usr/bin/tail -1)
        [ -n "$LIVE_DIGEST" ] || fail "Blocker 04 live digest extraction failed"
        persisted_world_tick=$(/usr/bin/sqlite3 "$DB_PATH" "SELECT json_extract(json, '$.dims.\"0\".time') FROM worlds;")
        case "$persisted_world_tick" in
            ''|*[!0-9]*) fail "invalid Blocker 04 World tick: $persisted_world_tick" ;;
        esac
        continuation_command_tick=$((persisted_world_tick + 100))

        printf '\nGate E Blocker 04 phase 2: fresh restore, legitimate continuation, and release.\n'
        PHASE2_SHOTS="$CAPTURE_BLOCKER04_RESTORED_PATH|$CAPTURE_BLOCKER04_CONTINUED_PATH|$CAPTURE_BLOCKER04_RELEASED_PATH"
        run_market_app "$SESSION_HOME" "$PHASE2_TRACE" \
            "$MARKET_PHASE2_COMMANDS" 0 "$continuation_command_tick" \
            "$PHASE2_SHOTS" 0 0
        TRACE_PATH="$PHASE2_TRACE"
        for capture in \
            "$CAPTURE_BLOCKER04_RESTORED_PATH" \
            "$CAPTURE_BLOCKER04_CONTINUED_PATH" \
            "$CAPTURE_BLOCKER04_RELEASED_PATH"; do
            [ -s "$capture" ] || fail "Blocker 04 phase-two capture missing: $capture"
        done
        require_trace "checkpoint loaded name=gate-e-blocker04-live-contract-v34 .*digest=$LIVE_DIGEST .*restartSafe=1 .*custodyDuplicates=0 physicalBoundary=acquired" 'fresh process reconstructs the derived live exclusion'
        require_trace 'blocker04 composed commitment authority asset=market-asset:0-initial-pickaxe .*contractLive=1 barterLive=0 marketLive=0 contractOpen=1 .*excludedMarketAcquisition=1 crossSystemDuplicateLiveCommitments=0 .*exactCurrentAuthority=1' 'restart preserves the live contract-to-market exclusion'
        require_trace 'contract normal promisee decision .*decision=accepted .*normalAcceptanceDecision=1 .*physicalMutation=0' 'ordinary promisee decision advances the same commitment'
        require_trace 'contract physical publication .*action=consideration .*material=stone_pickaxe:1 .*publication=verified' 'verified physical consideration completes the exact commitment leg'
        require_trace 'blocker04 composed commitment authority asset=market-asset:0-initial-pickaxe commitments=0 logicalCommitments=0 contractLive=0 barterLive=0 marketLive=0 .*contractAdvanced=1 .*crossSystemDuplicateLiveCommitments=0 .*exactCurrentAuthority=1 .*physicalLoss=0 physicalDuplication=0 syntheticMaterial=0' 'successful consideration deterministically releases commitment authority while retaining physical verification'
        require_trace 'blocker04 barter enabled configurationOnly=1 currentNeedObserved=1 economicOutcomeInjected=0 physicalMutation=0' 'barter uses the already-published contract-performance need without injecting an economic decision or physical effect'
        require_trace 'checkpoint saved name=gate-e-blocker04-released-v34 .*restartSafe=1 ' 'released state is schema-34 restart safe'
        require_trace 'summary .*runtimeErrors=0 .*probesRemoved=3 ' 'clean phase-two process termination'
        reject_trace 'crossSystemDuplicateLiveCommitments=1|CANDIDATE_PHYSICAL_HARD_FAILURE|CANDIDATE_PHYSICAL_ROLLBACK' 'duplicate commitment, hard failure, or unexpected rollback'

        RELEASED_DIGEST=$(/usr/bin/sed -n 's/.*checkpoint saved name=gate-e-blocker04-released-v34 .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' "$PHASE2_TRACE" | /usr/bin/tail -1)
        [ -n "$RELEASED_DIGEST" ] || fail "Blocker 04 released digest extraction failed"
        RELEASED_SESSION=$(/usr/bin/find "$PERSISTENCE_ROOT" -type f -path '*/checkpoints/gate-e-blocker04-released-v34/session.json' -print -quit)
        [ -n "$RELEASED_SESSION" ] || fail "Blocker 04 released checkpoint missing"
        persisted_world_tick=$(/usr/bin/sqlite3 "$DB_PATH" "SELECT json_extract(json, '$.dims.\"0\".time') FROM worlds;")
        continuation_command_tick=$((persisted_world_tick + 100))

        printf '\nGate E Blocker 04 phase 3: released-state restart, ordinary barter reuse, and a second composed exclusion.\n'
        PHASE3_SHOTS="$CAPTURE_BLOCKER04_BARTER_RESTORED_PATH|$CAPTURE_BLOCKER04_BARTER_EXCLUSION_PATH|$CAPTURE_BLOCKER04_BARTER_COMPLETED_PATH|$CAPTURE_BLOCKER04_BARTER_CHECKPOINT_PATH"
        run_market_app "$SESSION_HOME" "$PHASE3_TRACE" \
            "$MARKET_PHASE3_COMMANDS" 0 "$continuation_command_tick" \
            "$PHASE3_SHOTS" 0 0
        TRACE_PATH="$PHASE3_TRACE"
        for capture in \
            "$CAPTURE_BLOCKER04_BARTER_RESTORED_PATH" \
            "$CAPTURE_BLOCKER04_BARTER_EXCLUSION_PATH" \
            "$CAPTURE_BLOCKER04_BARTER_COMPLETED_PATH" \
            "$CAPTURE_BLOCKER04_BARTER_CHECKPOINT_PATH"; do
            [ -s "$capture" ] || fail "Blocker 04 phase-three capture missing: $capture"
        done
        require_trace "checkpoint loaded name=gate-e-blocker04-released-v34 .*digest=$RELEASED_DIGEST .*restartSafe=1 .*custodyDuplicates=0 physicalBoundary=acquired" 'fresh process preserves terminal release without replay'
        require_trace 'barter normal offer decision .*normalOfferDecision=1 barterProofFixtureDecisionAuthority=0 physicalMutation=0' 'ordinary barter cognition reuses the released exact asset'
        require_trace 'blocker04 composed commitment authority asset=market-asset:0-initial-pickaxe commitments=1 logicalCommitments=1 contractLive=0 barterLive=1 marketLive=0 .*barterPending=1 .*observedMarketOpportunities=0 ordinarySelectedTarget=0 targetDeposits=0 nonterminalTargetDeposits=0 excludedMarketAcquisition=0 crossSystemDuplicateLiveCommitments=0 .*exactCurrentAuthority=1' 'live barter commitment remains singular while the bounded one-lot stall admits no competing acquisition'
        require_trace 'barter normal counterparty decision .*decision=accepted .*normalCounterpartyDecision=1 .*physicalMutation=0' 'ordinary counterparty accepts without fixture authority'
        require_trace 'barter completed .*offered=bread:3 requested=stone_pickaxe:1 .*publication=verified' 'ordinary verified two-leg barter completes the released asset reuse'
        require_trace 'blocker04 composed commitment authority asset=market-asset:0-initial-pickaxe commitments=0 logicalCommitments=0 contractLive=0 barterLive=0 marketLive=0 .*barterPending=0 barterCompleted=1 .*crossSystemDuplicateLiveCommitments=0 .*exactCurrentAuthority=1 .*physicalLoss=0 physicalDuplication=0 syntheticMaterial=0' 'terminal barter history releases authority while retaining current physical truth'
        require_trace 'checkpoint saved name=gate-e-blocker04-barter-completed-v34 .*restartSafe=1 ' 'terminal barter release is schema-34 restart safe'
        require_trace 'summary .*runtimeErrors=0 .*probesRemoved=3 ' 'clean phase-three process termination'
        reject_trace 'crossSystemDuplicateLiveCommitments=1|market deposit completed .*asset=market-asset:0-initial-pickaxe|CANDIDATE_PHYSICAL_HARD_FAILURE|CANDIDATE_PHYSICAL_ROLLBACK' 'duplicate commitment, conflicting market mutation, or unexpected physical failure'

        BARTER_DIGEST=$(/usr/bin/sed -n 's/.*checkpoint saved name=gate-e-blocker04-barter-completed-v34 .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' "$PHASE3_TRACE" | /usr/bin/tail -1)
        [ -n "$BARTER_DIGEST" ] || fail "Blocker 04 barter digest extraction failed"
        BARTER_SESSION=$(/usr/bin/find "$PERSISTENCE_ROOT" -type f -path '*/checkpoints/gate-e-blocker04-barter-completed-v34/session.json' -print -quit)
        [ -n "$BARTER_SESSION" ] || fail "Blocker 04 barter checkpoint missing"
        persisted_world_tick=$(/usr/bin/sqlite3 "$DB_PATH" "SELECT json_extract(json, '$.dims.\"0\".time') FROM worlds;")
        continuation_command_tick=$((persisted_world_tick + 100))

        printf '\nGate E Blocker 04 phase 4: terminal-release restart, ordinary market reuse, bounded withdrawal, cleanup, and no replay.\n'
        PHASE4_SHOTS="$CAPTURE_BLOCKER04_FINAL_RESTORE_PATH|$CAPTURE_BLOCKER04_CLEANUP_READY_PATH|$CAPTURE_PATH"
        run_market_app "$SESSION_HOME" "$PHASE4_TRACE" \
            "$MARKET_PHASE4_COMMANDS" 0 "$continuation_command_tick" \
            "$PHASE4_SHOTS" 0 0
        TRACE_PATH="$PHASE4_TRACE"
        for capture in \
            "$CAPTURE_BLOCKER04_FINAL_RESTORE_PATH" \
            "$CAPTURE_BLOCKER04_CLEANUP_READY_PATH" \
            "$CAPTURE_PATH"; do
            [ -s "$capture" ] || fail "Blocker 04 phase-four capture missing: $capture"
        done
        require_trace "checkpoint loaded name=gate-e-blocker04-barter-completed-v34 .*digest=$BARTER_DIGEST .*restartSafe=1 .*custodyDuplicates=0 physicalBoundary=acquired" 'fresh process preserves barter terminal release without replay'
        require_trace_at_least 'blocker04 composed commitment authority asset=market-asset:0-initial-pickaxe .*crossSystemDuplicateLiveCommitments=0 .*exactCurrentAuthority=1 .*physicalLoss=0 physicalDuplication=0 syntheticMaterial=0 .*duplicateReceipts=0 duplicateSettlements=0 observerMutationCount=0 unexpectedRuntimeErrors=0 readOnly=1' 2 'current exact authority and zero duplicate commitment survive restart and bounded progress'
        require_trace_count 'market deposit completed .*asset=market-asset:0-initial-pickaxe .*ordinaryAutonomousSelection=1 .*publication=verified duplicateDeposits=0' 1 'terminal barter release permits one ordinary verified market reuse'
        require_trace 'blocker04 composed commitment authority asset=market-asset:0-initial-pickaxe commitments=0 logicalCommitments=0 contractLive=0 barterLive=0 marketLive=0 .*barterCompleted=1 .*targetDeposits=1 nonterminalTargetDeposits=0 .*crossSystemDuplicateLiveCommitments=0 .*currentHolder=agent:agent_0 .*exactCurrentAuthority=1' 'bounded listing expiry and verified withdrawal release the reused exact asset'
        require_trace 'Restored disposable market air cell after restart; completed economic custody was preserved.' 'exact disposable market cell cleanup'
        require_trace 'summary .*runtimeErrors=0 .*probesRemoved=3 ' 'clean phase-four process termination'
        reject_trace 'crossSystemDuplicateLiveCommitments=1|barter completed|CANDIDATE_PHYSICAL_HARD_FAILURE|CANDIDATE_PHYSICAL_ROLLBACK' 'barter replay, duplicate commitment, or unexpected physical failure'

        world_facts=$(/usr/bin/sqlite3 "$DB_PATH" "SELECT count(*), json_extract(json, '$.seed'), json_extract(json, '$.name'), json_extract(json, '$.dims.\"0\".dayTime'), json_extract(json, '$.dims.\"0\".raining'), json_extract(json, '$.dims.\"0\".thundering'), json_extract(json, '$.gameRules.doMobSpawning'), json_extract(json, '$.gameRules.doDaylightCycle'), json_extract(json, '$.gameRules.doWeatherCycle') FROM worlds;")
        expected_world_facts="1|$WORLD_SEED|$WORLD_NAME|1000|0|0|0|0|0"
        [ "$world_facts" = "$expected_world_facts" ] \
            || fail "unexpected Blocker 04 disposable World facts: $world_facts"
        if /usr/bin/pgrep -x Pebble >/dev/null 2>&1 \
            || /usr/bin/pgrep -x swift-run >/dev/null 2>&1 \
            || /usr/bin/pgrep -x pebsmoke >/dev/null 2>&1; then
            fail "residual PebbleLab process after Blocker 04 proof"
        fi
        printf '\nPASS: Blocker 04 composed exclusion, same-operation continuation, terminal release, restart, conservation, and cleanup verified.\n'
        printf 'Phase 1 trace: %s\n' "$PHASE1_TRACE"
        printf 'Phase 2 trace: %s\n' "$PHASE2_TRACE"
        printf 'Phase 3 trace: %s\n' "$PHASE3_TRACE"
        printf 'Phase 4 trace: %s\n' "$PHASE4_TRACE"
        printf 'Live checkpoint: %s\n' "$LIVE_SESSION"
        printf 'Released checkpoint: %s\n' "$RELEASED_SESSION"
        printf 'Barter checkpoint: %s\n' "$BARTER_SESSION"
        printf 'Checkpoint schema: 34\n'
        printf 'Observer schema: 11\n'
        printf 'Retained isolated session: %s\n' "$SESSION_ROOT"
        exit 0
    fi

    printf '\nMarket phase 1: physical place, bounded capacity, normal deposit/listing, and open checkpoint.\n'
    PHASE1_SHOTS="-|$CAPTURE_BEFORE_PATH|-|$CAPTURE_DEPOSITED_PATH|$CAPTURE_OPEN_PATH"
    run_market_app "$SESSION_HOME" "$PHASE1_TRACE" \
        "$MARKET_PHASE1_COMMANDS" 1 100 "$PHASE1_SHOTS" 0 0
    TRACE_PATH="$PHASE1_TRACE"
    [ -s "$CAPTURE_BEFORE_PATH" ] || fail "market established capture missing"
    [ -s "$CAPTURE_DEPOSITED_PATH" ] || fail "market deposited capture missing"
    [ -s "$CAPTURE_OPEN_PATH" ] || fail "market open-listing capture missing"
    require_trace 'market setup market=central .*marketCapacityPhysical=bounded capacityRefusal=destinationFull marketProofFixtureDecisionAuthority=0 .*manualProductiveMarketCommandsAfterBootstrap=0' 'physical market bootstrap and real full-container refusal'
    require_trace 'market normal deposit discovery .*normalMarketDiscovery=1 .*globalInventoryScan=0 .*marketProofFixtureDecisionAuthority=0' 'bounded normal local market discovery'
    require_trace 'market deposit completed .*normalDepositDecision=1 depositPhysicalMutation=1 .*owner=agent_[0-9]+ .*publication=verified duplicateDeposits=0' 'normal exact physical deposit retaining seller ownership'
    require_trace 'market normal listing decision .*normalListingDecision=1 listingAuthority=verified-local-deposit automaticPosting=1 newSellerAction=0 firstProposedTerms=stone_pickaxe:1/bread:3 .*historyUsed=false .*marketProofFixtureDecisionAuthority=0' 'initial local ask through verified deposit authorization and normal cognition'
    require_trace 'market proof schema=34 observerSchema=11 openCheckpointSafe=1 ' 'open listing restart readiness'
    require_trace 'checkpoint saved name=market-open-v34 .*restartSafe=1 ' 'open physical market checkpoint'
    require_trace 'summary .*runtimeErrors=0 .*probesRemoved=3 ' 'clean first process termination'
    reject_trace 'market normal buyer decision|market settlement completed|market unsold withdrawal completed|CANDIDATE_PHYSICAL_HARD_FAILURE' 'premature market decision, settlement, withdrawal, or hard failure'

    PERSISTENCE_ROOT="$SESSION_HOME/Library/Application Support/Pebble/PebbleLabAgents"
    OPEN_SESSION=$(/usr/bin/find "$PERSISTENCE_ROOT" -type f -path '*/checkpoints/market-open-v34/session.json' -print -quit)
    [ -n "$OPEN_SESSION" ] || fail "market-open-v34 session.json missing"
    /usr/bin/grep -q '"schemaVersion":34' "$OPEN_SESSION" \
        || fail "open market checkpoint is not schema 34"
    OPEN_DIGEST=$(/usr/bin/sed -n 's/.*checkpoint saved name=market-open-v34 .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' "$PHASE1_TRACE" | /usr/bin/tail -1)
    [ -n "$OPEN_DIGEST" ] || fail "open market digest extraction failed"
    persisted_world_tick=$(/usr/bin/sqlite3 "$DB_PATH" "SELECT json_extract(json, '$.dims.\"0\".time') FROM worlds;")
    case "$persisted_world_tick" in
        ''|*[!0-9]*) fail "invalid persisted market World tick: $persisted_world_tick" ;;
    esac
    continuation_command_tick=$((persisted_world_tick + 100))

    printf '\nMarket phase 2: fresh open restore, two real post-mutation rollbacks, and exact retry.\n'
    PHASE2_SHOTS="$CAPTURE_RESTORED_PATH|-|-|$CAPTURE_REMOTE_PATH|-|$CAPTURE_MID_FAULT_PATH|$CAPTURE_POST_FAULT_PATH|$CAPTURE_COMPLETED_PATH"
    run_market_app "$SESSION_HOME" "$PHASE2_TRACE" \
        "$MARKET_PHASE2_COMMANDS" 0 "$continuation_command_tick" \
        "$PHASE2_SHOTS" 1 1
    TRACE_PATH="$PHASE2_TRACE"
    [ -s "$CAPTURE_RESTORED_PATH" ] || fail "market restored-open capture missing"
    [ -s "$CAPTURE_REMOTE_PATH" ] || fail "market remote-buyer capture missing"
    [ -s "$CAPTURE_MID_FAULT_PATH" ] || fail "market mid-fault capture missing"
    [ -s "$CAPTURE_POST_FAULT_PATH" ] || fail "market post-fault capture missing"
    [ -s "$CAPTURE_COMPLETED_PATH" ] || fail "market completed capture missing"
    require_trace "checkpoint loaded name=market-open-v34 .*digest=$OPEN_DIGEST .*restartSafe=1 .*custodyDuplicates=0 physicalBoundary=acquired" 'fresh process restores exact open market custody'
    require_trace 'market normal seller decision .*accepted=0 requestedQuoteItem=bread requestedQuoteQuantity=1 .*sellerDecisionAuthority=normal-cognition sellerUnconditionalAccept=0 .*marketProofFixtureDecisionAuthority=0' 'normal seller cognition rejects insufficient one-bread counteroffer'
    require_trace 'market normal seller decision .*accepted=1 requestedQuoteItem=bread requestedQuoteQuantity=2 .*sellerDecisionAuthority=normal-cognition sellerUnconditionalAccept=0 .*marketProofFixtureDecisionAuthority=0' 'normal seller cognition later accepts coherent two-bread counteroffer'
    require_trace 'market remote buyer staged .*proposalHistoricalLocalityAuthority=0 marketProofFixtureDecisionAuthority=0' 'real buyer probe moved outside the market after reservation'
    require_trace 'market remote settlement refused .*buyerCurrentLocalityAtSettlement=0 .*physicalMutation=0 tradePublication=0 priceHistoryPublication=0 retryableUntilExpiry=1' 'remote settlement refused before physical mutation or publication'
    require_trace 'market remote buyer locality restored exact=1 retryableBeforeExpiry=1 physicalTradeMutation=0' 'bounded reservation retry restores exact locality'
    require_trace_at_least 'market normal buyer decision .*normalBuyerDecision=1 rejectedAsk=true revisedTerms=stone_pickaxe:1/bread:2 .*localPresence=1' 1 'normal two-bread counteroffer follows rejected insufficient offer'
    require_trace_at_least 'market true mid-settlement mutation .*candidatePhysicalMutation=1 publication=0' 3 'both fault paths and retry cross a real first leg'
    require_trace_count 'CANDIDATE_PHYSICAL_ROLLBACK operation=advanceOneTick .*marketPostMutationBoundary' 2 'two exact candidate physical rollbacks'
    require_trace_at_least 'CANDIDATE_PHYSICAL_ROLLBACK .*publishedSession=unchanged .*publishedRecorder=unchanged' 2 'session and recorder remain unpublished on both errors'
    require_trace 'market settlement completed .*completedTerms=stone_pickaxe:1/bread:2 .*localPriceHistoryCreated=1 duplicateMarketTradeReceipts=0 duplicateReservations=0 .*publication=verified' 'retry completes exactly one physical trade and price row'
    require_trace 'market proof schema=34 observerSchema=11 .*sellerDecisionAuthority=normal-cognition sellerUnconditionalAccept=0 normalSellerRejections=1 normalSellerAcceptances=1 remoteSettlementAttempts=1 remoteSettlementPhysicalMutation=0 remoteSettlementTradePublication=0 remoteSettlementPriceHistoryPublication=0 .*priceRows=1 trades=1 withdrawals=0 .*candidateMidFaultInjected=1 candidatePostMutationFaultInjected=1 manualProductiveMarketCommandsAfterBootstrap=0' 'bounded locality, cognition and exact retry proof'
    require_trace 'checkpoint saved name=market-traded-v34 .*restartSafe=1 ' 'completed market checkpoint'
    require_trace 'summary .*runtimeErrors=3 .*probesRemoved=3 ' 'three expected locality/fault runtime failures and clean second termination'
    reject_trace 'CANDIDATE_PHYSICAL_HARD_FAILURE' 'market compensation hard failure'
    if [ "$GATE_E_BLOCKER_03" -eq 1 ]; then
        require_trace 'blocker03 market reservation authority terminalAccepted=0 liveProposed=0 liveAccepted=1 nonterminalTargetDeposits=0 targetReserved=1 terminalOnlyReleased=0 exactCurrentAuthority=1 .*readOnly=1' 'accepted live proposal retains strict current reservation authority'
        require_trace 'blocker03 market reservation authority terminalAccepted=1 liveProposed=0 liveAccepted=0 nonterminalTargetDeposits=0 targetReserved=0 terminalOnlyReleased=1 exactCurrentAuthority=1 .*trades=1 priceRows=1 .*readOnly=1' 'first completed trade becomes history without retaining reservation authority'
    fi

    TRADED_DIGEST=$(/usr/bin/sed -n 's/.*checkpoint saved name=market-traded-v34 .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' "$PHASE2_TRACE" | /usr/bin/tail -1)
    [ -n "$TRADED_DIGEST" ] || fail "traded market digest extraction failed"
    persisted_world_tick=$(/usr/bin/sqlite3 "$DB_PATH" "SELECT json_extract(json, '$.dims.\"0\".time') FROM worlds;")
    continuation_command_tick=$((persisted_world_tick + 100))

    printf '\nMarket phase 3: restored price memory, later comparable trade, expiry, and real withdrawal.\n'
    PHASE3_SHOTS="$CAPTURE_HISTORY_PATH|-|-|-|-|$CAPTURE_LATER_PATH|-|-|-|$CAPTURE_WITHDRAWAL_PATH"
    run_market_app "$SESSION_HOME" "$PHASE3_TRACE" \
        "$MARKET_PHASE3_COMMANDS" 0 "$continuation_command_tick" \
        "$PHASE3_SHOTS" 0 0
    TRACE_PATH="$PHASE3_TRACE"
    [ -s "$CAPTURE_HISTORY_PATH" ] || fail "market restored-history capture missing"
    [ -s "$CAPTURE_LATER_PATH" ] || fail "market later-trade capture missing"
    [ -s "$CAPTURE_WITHDRAWAL_PATH" ] || fail "market withdrawal capture missing"
    require_trace "checkpoint loaded name=market-traded-v34 .*digest=$TRADED_DIGEST .*restartSafe=1 .*custodyDuplicates=0 physicalBoundary=acquired" 'fresh process restores completed trade and price history'
    require_trace 'market normal listing decision .*firstProposedTerms=stone_pickaxe:1/bread:2 .*sellerReasonQuoteQuantity=3 historySelectedQuoteQuantity=2 priceHistoryCausalControl=1 historyUsed=true laterDecisionUsedPriceHistory=1 ' 'restored local price evidence causally changes later comparable ask'
    require_trace 'market normal buyer decision .*normalBuyerDecision=1 rejectedAsk=false revisedTerms=stone_pickaxe:1/bread:2 ' 'later buyer selects history-informed terms for current need'
    require_trace 'market status .*trades=2 withdrawals=1 priceHistory=stone_pickaxe/bread=2/1@' 'second trade and unsold withdrawal retained'
    require_trace 'market listing expired .*reservationReleased=1 physicalMutation=0' 'unsold listing expiry moves no matter'
    require_trace 'market unsold withdrawal completed .*publication=verified' 'unsold exact lot physically returns to seller'
    require_trace 'market proof schema=34 observerSchema=11 .*priceRows=2 trades=2 withdrawals=1 ' 'final bounded market truth'
    require_trace 'checkpoint saved name=market-final-v34 .*restartSafe=1 ' 'final market checkpoint'
    require_trace 'summary .*runtimeErrors=0 .*probesRemoved=3 ' 'clean third process termination'
    reject_trace 'CANDIDATE_PHYSICAL_HARD_FAILURE|CANDIDATE_PHYSICAL_ROLLBACK' 'unexpected third-process market rollback'
    if [ "$GATE_E_BLOCKER_03" -eq 1 ]; then
        require_trace 'blocker03 market reservation authority terminalAccepted=2 liveProposed=0 liveAccepted=0 nonterminalTargetDeposits=0 targetReserved=0 terminalOnlyReleased=1 exactCurrentAuthority=1 .*trades=2 priceRows=2 withdrawals=1 readOnly=1' 'two retained completed proposals release current authority while trade and price provenance remain exact'
    fi

    FINAL_DIGEST=$(/usr/bin/sed -n 's/.*checkpoint saved name=market-final-v34 .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' "$PHASE3_TRACE" | /usr/bin/tail -1)
    [ -n "$FINAL_DIGEST" ] || fail "final market digest extraction failed"
    FINAL_SESSION=$(/usr/bin/find "$PERSISTENCE_ROOT" -type f -path '*/checkpoints/market-final-v34/session.json' -print -quit)
    [ -n "$FINAL_SESSION" ] && /usr/bin/grep -q '"schemaVersion":34' "$FINAL_SESSION" \
        || fail "final market checkpoint is not schema 34"
    persisted_world_tick=$(/usr/bin/sqlite3 "$DB_PATH" "SELECT json_extract(json, '$.dims.\"0\".time') FROM worlds;")
    continuation_command_tick=$((persisted_world_tick + 100))

    printf '\nMarket phase 4: final fresh restore, exact-once verification, and empty-stall cleanup.\n'
    if [ "$GATE_E_BLOCKER_03" -eq 1 ]; then
        PHASE4_SHOTS="$CAPTURE_FINAL_RESTORE_PATH|$CAPTURE_BLOCKER03_DEPOSIT_PATH|$CAPTURE_BLOCKER03_LISTING_PATH|$CAPTURE_BLOCKER03_CONTINUED_PATH|$CAPTURE_PATH"
    else
        PHASE4_SHOTS="$CAPTURE_FINAL_RESTORE_PATH|$CAPTURE_PATH"
    fi
    run_market_app "$SESSION_HOME" "$PHASE4_TRACE" \
        "$MARKET_PHASE4_COMMANDS" 0 "$continuation_command_tick" \
        "$PHASE4_SHOTS" 0 0
    TRACE_PATH="$PHASE4_TRACE"
    [ -s "$CAPTURE_FINAL_RESTORE_PATH" ] || fail "market final-restore capture missing"
    [ -s "$CAPTURE_PATH" ] || fail "market cleanup capture missing"
    if [ "$GATE_E_BLOCKER_03" -eq 1 ]; then
        [ -s "$CAPTURE_BLOCKER03_DEPOSIT_PATH" ] \
            || fail "Blocker 03 ordinary-selection-and-deposit capture missing"
        [ -s "$CAPTURE_BLOCKER03_LISTING_PATH" ] \
            || fail "Blocker 03 ordinary-listing capture missing"
        [ -s "$CAPTURE_BLOCKER03_CONTINUED_PATH" ] \
            || fail "Blocker 03 continued-path capture missing"
    fi
    require_trace "checkpoint loaded name=market-final-v34 .*digest=$FINAL_DIGEST .*restartSafe=1 .*custodyDuplicates=0 physicalBoundary=acquired" 'fresh process restores final price and withdrawal truth'
    require_trace_at_least 'market status .*trades=2 withdrawals=1 priceHistory=stone_pickaxe/bread=2/1@' 2 'final restart remains exact across another product tick'
    require_trace 'Restored disposable market air cell after restart; completed economic custody was preserved.' 'empty physical stall cleanup'
    require_trace 'summary .*runtimeErrors=0 .*probesRemoved=3 ' 'clean fourth process termination'
    if [ "$GATE_E_BLOCKER_03" -eq 1 ]; then
        require_trace 'blocker03 market reservation authority terminalAccepted=2 liveProposed=0 liveAccepted=0 nonterminalTargetDeposits=0 targetReserved=0 terminalOnlyReleased=1 exactCurrentAuthority=1 .*currentOpportunities=0 ordinarySelectedTarget=0 targetDeposits=0 targetListings=0 .*trades=2 priceRows=2 withdrawals=1 readOnly=1' 'fresh restart preserves terminal history and released exact current authority'
        require_trace 'market deposit completed .*asset=market-asset:9-consideration-bread2 normalDepositDecision=1 depositPhysicalMutation=1 ordinaryAutonomousSelection=1 reservationAuthorityBefore=0 .*publication=verified duplicateDeposits=0' 'ordinary post-restart selection executes the released asset through the verified physical deposit path'
        require_trace 'blocker03 market reservation authority terminalAccepted=2 liveProposed=0 liveAccepted=0 nonterminalTargetDeposits=1 targetReserved=1 terminalOnlyReleased=0 exactCurrentAuthority=1 .*targetDeposits=1 targetListings=0 liveTargetListings=0 .*readOnly=1' 'new physical deposit reacquires live reservation authority without duplication'
        require_trace 'blocker03 market reservation authority terminalAccepted=2 liveProposed=0 liveAccepted=0 nonterminalTargetDeposits=1 targetReserved=1 terminalOnlyReleased=0 exactCurrentAuthority=1 .*targetDeposits=1 targetListings=1 liveTargetListings=1 .*readOnly=1' 'new ordinary listing remains actively reserved'
        require_trace 'checkpoint saved name=market-blocker03-reentered-v34 .*restartSafe=1 ' 'post-reentry market checkpoint remains schema-34 restart safe'
        require_trace 'observer status .*schema=11 .*' 'Observer schema remains read-only and available'
        reject_trace 'market settlement completed|CANDIDATE_PHYSICAL_ROLLBACK|CANDIDATE_PHYSICAL_HARD_FAILURE' 'historical settlement replay or unexpected rollback'
    else
        reject_trace 'market settlement completed|market unsold withdrawal completed|CANDIDATE_PHYSICAL_ROLLBACK|CANDIDATE_PHYSICAL_HARD_FAILURE' 'reexecuted final market outcome or rollback'
    fi

    world_facts=$(/usr/bin/sqlite3 "$DB_PATH" "SELECT count(*), json_extract(json, '$.seed'), json_extract(json, '$.name'), json_extract(json, '$.dims.\"0\".dayTime'), json_extract(json, '$.dims.\"0\".raining'), json_extract(json, '$.dims.\"0\".thundering'), json_extract(json, '$.gameRules.doMobSpawning'), json_extract(json, '$.gameRules.doDaylightCycle'), json_extract(json, '$.gameRules.doWeatherCycle') FROM worlds;")
    expected_world_facts="1|$WORLD_SEED|$WORLD_NAME|1000|0|0|0|0|0"
    [ "$world_facts" = "$expected_world_facts" ] \
        || fail "unexpected market disposable World facts: $world_facts"
    if /usr/bin/pgrep -x Pebble >/dev/null 2>&1 \
        || /usr/bin/pgrep -x swift-run >/dev/null 2>&1 \
        || /usr/bin/pgrep -x pebsmoke >/dev/null 2>&1; then
        fail "residual PebbleLab process after market proof"
    fi
    if [ "$GATE_E_BLOCKER_03" -eq 1 ]; then
        printf '\nPASS: Blocker 03 active reservation, terminal-history release, ordinary post-restart re-entry, conservation, and cleanup verified.\n'
    else
        printf '\nPASS: physical market custody, two exact settlement rollbacks, restart, local price discovery, later quote, withdrawal, and cleanup verified.\n'
    fi
    printf 'Phase 1 trace: %s\n' "$PHASE1_TRACE"
    printf 'Phase 2 trace: %s\n' "$PHASE2_TRACE"
    printf 'Phase 3 trace: %s\n' "$PHASE3_TRACE"
    printf 'Phase 4 trace: %s\n' "$PHASE4_TRACE"
    printf 'Checkpoint schema: 34\n'
    printf 'Observer schema: 11\n'
    printf 'Retained isolated session: %s\n' "$SESSION_ROOT"
    exit 0
fi

if [ "$MODE" = "contracts" ]; then
    cd "$ROOT_DIR"
    swift build -c release --product Pebble
    PEBBLE_BINARY="$ROOT_DIR/.build/release/Pebble"
    [ -x "$PEBBLE_BINARY" ] \
        || fail "Release Pebble binary missing: $PEBBLE_BINARY"

    PHASE_CAPACITY_TRACE="$SESSION_ROOT/contract-capacity.log"
    PHASE1_TRACE="$SESSION_ROOT/contract-phase1.log"
    PHASE2_TRACE="$SESSION_ROOT/contract-phase2.log"
    PHASE3_TRACE="$SESSION_ROOT/contract-phase3.log"

    run_contract_app() {
        run_home=$1
        run_trace=$2
        run_commands=$3
        create_world=$4
        command_world_tick=$5
        run_shots=$6
        capacity_proof=$7
        consideration_publication_fault=$8
        fulfillment_fault=$9
        fulfillment_publication_fault=${10}
        if [ "$create_world" -eq 1 ]; then
            CFFIXED_USER_HOME="$run_home" \
            PEBBLE_AUTOLOAD=1 \
            PEBBLE_NEWWORLD="$WORLD_SEED" \
            PEBBLE_NEWWORLD_NAME="$WORLD_NAME" \
            PEBBLELAB_APP_AGENTS=1 \
            PEBBLELAB_APP_AGENTS_MOVE=1 \
            PEBBLELAB_APP_PROBES=1 \
            PEBBLELAB_DEBUG_ENTITIES=1 \
            PEBBLELAB_APP_AGENTS_OVERLAY=1 \
            PEBBLELAB_APP_AGENTS_TRACE=1 \
            PEBBLELAB_APP_AGENTS_TRACE_EVERY=1 \
            PEBBLELAB_APP_AGENTS_INTERACT=1 \
            PEBBLELAB_APP_AGENTS_MATERIAL=1 \
            PEBBLELAB_APP_AGENTS_PERSISTENCE=1 \
            PEBBLELAB_APP_AGENTS_PRODUCTION=1 \
            PEBBLELAB_APP_AGENTS_CONTRACTS=1 \
            PEBBLELAB_APP_AGENTS_AUTONOMOUS_CIVILIZATION=1 \
            PEBBLELAB_DISPOSABLE_CONTRACT_PRODUCTION_NEED_CAPACITY_PROOF="$capacity_proof" \
            PEBBLELAB_DISPOSABLE_CONTRACT_CONSIDERATION_PUBLICATION_FAULT="$consideration_publication_fault" \
            PEBBLELAB_DISPOSABLE_CONTRACT_FULFILLMENT_FAULT="$fulfillment_fault" \
            PEBBLELAB_DISPOSABLE_CONTRACT_FULFILLMENT_PUBLICATION_FAULT="$fulfillment_publication_fault" \
            PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
            PEBBLE_CMD_WORLD_TICK="$command_world_tick" \
            PEBBLE_CMD="$run_commands" \
            PEBBLE_SHOT="$run_shots" \
            "$PEBBLE_BINARY" 2>&1 | /usr/bin/tee "$run_trace"
        else
            CFFIXED_USER_HOME="$run_home" \
            PEBBLE_AUTOLOAD=1 \
            PEBBLELAB_APP_AGENTS=1 \
            PEBBLELAB_APP_AGENTS_MOVE=1 \
            PEBBLELAB_APP_PROBES=1 \
            PEBBLELAB_DEBUG_ENTITIES=1 \
            PEBBLELAB_APP_AGENTS_OVERLAY=1 \
            PEBBLELAB_APP_AGENTS_TRACE=1 \
            PEBBLELAB_APP_AGENTS_TRACE_EVERY=1 \
            PEBBLELAB_APP_AGENTS_INTERACT=1 \
            PEBBLELAB_APP_AGENTS_MATERIAL=1 \
            PEBBLELAB_APP_AGENTS_PERSISTENCE=1 \
            PEBBLELAB_APP_AGENTS_PRODUCTION=1 \
            PEBBLELAB_APP_AGENTS_CONTRACTS=1 \
            PEBBLELAB_APP_AGENTS_AUTONOMOUS_CIVILIZATION=1 \
            PEBBLELAB_DISPOSABLE_CONTRACT_PRODUCTION_NEED_CAPACITY_PROOF="$capacity_proof" \
            PEBBLELAB_DISPOSABLE_CONTRACT_CONSIDERATION_PUBLICATION_FAULT="$consideration_publication_fault" \
            PEBBLELAB_DISPOSABLE_CONTRACT_FULFILLMENT_FAULT="$fulfillment_fault" \
            PEBBLELAB_DISPOSABLE_CONTRACT_FULFILLMENT_PUBLICATION_FAULT="$fulfillment_publication_fault" \
            PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
            PEBBLE_CMD_WORLD_TICK="$command_world_tick" \
            PEBBLE_CMD="$run_commands" \
            PEBBLE_SHOT="$run_shots" \
            "$PEBBLE_BINARY" 2>&1 | /usr/bin/tee "$run_trace"
        fi
        if /usr/bin/pgrep -x Pebble >/dev/null 2>&1; then
            fail "Pebble process remained after contract phase: $run_trace"
        fi
    }

    printf '\nContract capacity proof: real performance-need capacity refusal before transfer.\n'
    CAPACITY_HOME="$SESSION_ROOT/capacity-home"
    CAPACITY_SHOTS="-|-|-|$CAPTURE_CAPACITY_PATH"
    run_contract_app \
        "$CAPACITY_HOME" "$PHASE_CAPACITY_TRACE" "$CONTRACT_CAPACITY_COMMANDS" \
        1 100 "$CAPACITY_SHOTS" 1 0 0 0
    TRACE_PATH="$PHASE_CAPACITY_TRACE"
    [ -s "$CAPTURE_CAPACITY_PATH" ] \
        || fail "contract capacity-refusal capture missing"
    require_trace 'contract publication prevalidation refused obligation=obligation-[0-9a-f]+ action=consideration physicalMutation=0 candidateCompensationDelta=0 reason=.*production_capacity_reached_needs' 'production need capacity refuses before physical transfer'
    require_trace 'autonomous activity blocked actor=agent_[0-9]+ domain=contract reason=.*publication_prevalidation_refused' 'harmless pre-mutation refusal remains bounded blocked outcome'
    require_trace 'contracts enabled=1 .*awaitingConsideration.*active=1 debts=0 fulfilled=0 ' 'accepted obligation remains awaiting consideration after capacity refusal'
    require_trace 'summary .*runtimeErrors=0 .*probesRemoved=3 ' 'capacity proof clean shutdown'
    reject_trace 'contract post-transfer mutation|CANDIDATE_PHYSICAL_ROLLBACK|CANDIDATE_PHYSICAL_HARD_FAILURE' 'capacity refusal physical mutation or rollback'

    printf '\nContract phase 1: normal promise, distinct acceptance, real consideration, and open debt checkpoint.\n'
    run_contract_app \
        "$SESSION_HOME" "$PHASE1_TRACE" "$CONTRACT_PHASE1_COMMANDS" \
        1 100 "$SHOT_SPEC" 0 1 0 0
    TRACE_PATH="$PHASE1_TRACE"
    [ -s "$CAPTURE_BEFORE_PATH" ] || fail "contract pre-promise capture missing"
    [ -s "$CAPTURE_PROPOSAL_PATH" ] || fail "contract proposal capture missing"
    [ -s "$CAPTURE_CONSIDERATION_FAULT_PATH" ] \
        || fail "contract consideration publication rollback capture missing"
    [ -s "$CAPTURE_OPEN_PATH" ] || fail "contract open-debt capture missing"
    require_trace 'contract setup promisor=agent_[0-9]+ promisee=agent_[0-9]+ reasonCurrent=stone_pickaxe:1 promisedFuture=bread:1 promisedHeldBefore=0 consideration=stone_pickaxe:1 physical=verified normalProposal=awaiting normalAcceptance=awaiting proofFixtureDecisionAuthority=0 manualProductiveContractCommandsAfterBootstrap=0' 'bootstrap creates current consideration, inputs, and reasons but no decisive promise'
    require_trace 'contract normal promise proposal proposal=promise-[0-9a-f]+ promisor=agent_[0-9]+ normalProposalDecision=1 proofFixtureDecisionAuthority=0 physicalMutation=0' 'normal promise decision'
    require_trace 'contract normal promisee decision proposal=promise-[0-9a-f]+ promisee=agent_[0-9]+ decision=accepted distinctAcceptance=1 normalAcceptanceDecision=1 proofFixtureDecisionAuthority=0 physicalMutation=0' 'distinct normal acceptance'
    require_trace 'contract unrelated inventory drift leg=consideration .*currentAuthorityBefore=exact currentAuthorityAfter=exact fullFingerprintChanged=1 trackedIdentityChanged=0 trackedQuantityChanged=0' 'consideration unrelated-slot drift positive control'
    require_trace_at_least 'contract current asset authority obligation=obligation-[0-9a-f]+ action=consideration status=exact .*historicalFullFingerprintCurrent=0 currentFingerprintImmediatePrecondition=1' 2 'current consideration fingerprint used for fault and retry'
    require_trace_at_least 'contract post-transfer mutation obligation=obligation-[0-9a-f]+ action=consideration .*candidatePhysicalMutation=1 publication=0' 2 'ordinary consideration failure and retry reach real transfer'
    require_trace 'contract post-mutation error policy action=consideration candidateCompensationDelta=1 escapeCandidate=1 autonomousBlocked=0 error=.*ordinary_consideration_publication_rejected_after_transfer' 'ordinary consideration publication error escapes blocked path'
    require_trace 'CANDIDATE_PHYSICAL_ROLLBACK operation=advanceOneTick .*contractBoundary.*ordinary consideration publication rejected after transfer.*registered=material-transfer:contract:obligation-[0-9a-f]+:consideration:[0-9]+ .*completed=material-transfer:contract:obligation-[0-9a-f]+:consideration:[0-9]+ .*publishedSession=unchanged .*publishedRecorder=unchanged' 'exact ordinary consideration publication rollback'
    require_trace_count 'contract physical publication obligation=obligation-[0-9a-f]+ action=consideration ' 1 'one successful consideration publication after rollback'
    require_trace 'contracts enabled=1 .*active=1 debts=1 fulfilled=0 .*checkpointReady=1 .*proofFixtureDecisionAuthority=0 .*manualProductiveContractCommandsAfterBootstrap=0 .*physicalLoss=0 physicalDuplication=0 syntheticMaterial=0 duplicateFulfillmentReceipts=0 duplicateReservations=0 observerMutationCount=0' 'open debt has bounded truthful status'
    require_trace 'checkpoint saved name=contract-open-v33 .*restartSafe=1 ' 'restart-safe open debt checkpoint'
    require_trace 'summary .*runtimeErrors=1 .*probesRemoved=3 ' 'one expected consideration publication fault and clean phase-one shutdown'
    reject_trace 'autonomous activity blocked .*domain=contract' 'ordinary post-mutation consideration error swallowed as blocked'
    reject_trace 'contract normal promised good obtained|action=fulfillment|CANDIDATE_PHYSICAL_HARD_FAILURE' 'premature performance or hard rollback failure'

    PERSISTENCE_ROOT="$SESSION_HOME/Library/Application Support/Pebble/PebbleLabAgents"
    OPEN_SESSION=$(/usr/bin/find "$PERSISTENCE_ROOT" -type f -path '*/checkpoints/contract-open-v33/session.json' -print -quit)
    [ -n "$OPEN_SESSION" ] || fail "contract-open-v33 session.json missing"
    /usr/bin/grep -q '"schemaVersion":33' "$OPEN_SESSION" \
        || fail "open contract checkpoint is not schema 33"
    OPEN_DIGEST=$(/usr/bin/sed -n 's/.*checkpoint saved name=contract-open-v33 .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' "$PHASE1_TRACE" | /usr/bin/tail -1)
    [ -n "$OPEN_DIGEST" ] || fail "open contract digest extraction failed"
    persisted_world_tick=$(/usr/bin/sqlite3 "$DB_PATH" "SELECT json_extract(json, '$.dims.\"0\".time') FROM worlds;")
    case "$persisted_world_tick" in
        ''|*[!0-9]*) fail "invalid persisted contract World tick: $persisted_world_tick" ;;
    esac
    continuation_command_tick=$((persisted_world_tick + 100))

    printf '\nContract phase 2: restore open debt, normal production, true fulfillment fault, rollback, and retry.\n'
    PHASE2_SHOTS="$CAPTURE_RESTORED_PATH|$CAPTURE_PRODUCED_PATH|$CAPTURE_FAULT_PATH|$CAPTURE_PUBLICATION_FAULT_PATH|$CAPTURE_FULFILLED_PATH"
    run_contract_app \
        "$SESSION_HOME" "$PHASE2_TRACE" "$CONTRACT_PHASE2_COMMANDS" \
        0 "$continuation_command_tick" "$PHASE2_SHOTS" 0 0 1 1
    TRACE_PATH="$PHASE2_TRACE"
    [ -s "$CAPTURE_RESTORED_PATH" ] || fail "contract restored-open capture missing"
    [ -s "$CAPTURE_PRODUCED_PATH" ] || fail "contract produced-good capture missing"
    [ -s "$CAPTURE_FAULT_PATH" ] || fail "contract rollback capture missing"
    [ -s "$CAPTURE_PUBLICATION_FAULT_PATH" ] \
        || fail "contract publication rollback capture missing"
    [ -s "$CAPTURE_FULFILLED_PATH" ] || fail "contract fulfilled capture missing"
    require_trace "checkpoint loaded name=contract-open-v33 .*digest=$OPEN_DIGEST .*restartSafe=1 .*custodyDuplicates=0 physicalBoundary=acquired" 'fresh-process open debt and custody restore'
    require_trace 'contract normal promised good obtained obligation=obligation-[0-9a-f]+ producer=agent_[0-9]+ material=bread:1 productionReceipt=produce:production:contract:obligation-[0-9a-f]+:perform:t[0-9]+:[0-9a-f]+ normalProductPath=1' 'later normal production obtains promised good'
    require_trace 'contract unrelated inventory drift leg=fulfillment .*currentAuthorityBefore=exact currentAuthorityAfter=exact fullFingerprintChanged=1 trackedIdentityChanged=0 trackedQuantityChanged=0' 'fulfillment unrelated-slot drift positive control'
    require_trace_at_least 'contract current asset authority obligation=obligation-[0-9a-f]+ action=fulfillment status=exact .*historicalFullFingerprintCurrent=0 currentFingerprintImmediatePrecondition=1' 3 'current fulfillment fingerprint used for both faults and retry'
    require_trace_at_least 'contract post-transfer mutation obligation=obligation-[0-9a-f]+ action=fulfillment receipt=contract:obligation-[0-9a-f]+:fulfillment quantity=1 candidatePhysicalMutation=1 publication=0' 3 'explicit fault, ordinary publication fault, and retry all reach real mutation'
    require_trace_at_least 'contract post-mutation error policy action=fulfillment candidateCompensationDelta=1 escapeCandidate=1 autonomousBlocked=0 ' 2 'all fulfillment post-mutation errors escape blocked path'
    require_trace 'CANDIDATE_PHYSICAL_ROLLBACK operation=advanceOneTick .*contractPostMutationBoundary.*registered=material-transfer:contract:obligation-[0-9a-f]+:fulfillment:[0-9]+ .*completed=material-transfer:contract:obligation-[0-9a-f]+:fulfillment:[0-9]+ .*publishedSession=unchanged .*publishedRecorder=unchanged' 'exact post-fulfillment compensation with open published debt'
    require_trace 'CANDIDATE_PHYSICAL_ROLLBACK operation=advanceOneTick .*contractBoundary.*ordinary fulfillment publication rejected after transfer.*registered=material-transfer:contract:obligation-[0-9a-f]+:fulfillment:[0-9]+ .*completed=material-transfer:contract:obligation-[0-9a-f]+:fulfillment:[0-9]+ .*publishedSession=unchanged .*publishedRecorder=unchanged' 'exact ordinary fulfillment publication rollback'
    require_trace_count 'contract physical publication obligation=obligation-[0-9a-f]+ action=fulfillment ' 1 'one successful physical fulfillment publication'
    require_trace 'contract proof result=PASS promise=explicit acceptance=distinct obligation=durable consideration=physical debt=open-before-fulfillment normalProductPath=PASS fulfillment=physical exactOnce=1 duplicateFulfillmentCount=0 observerMutationCount=0 proofFixtureDecisionAuthority=0 manualProductiveContractCommandsAfterBootstrap=0 physicalLoss=0 physicalDuplication=0 syntheticMaterial=0 duplicateFulfillmentReceipts=0 duplicateReservations=0' 'exact-once positive proof'
    require_trace 'checkpoint saved name=contract-fulfilled-v33 .*restartSafe=1 ' 'restart-safe fulfilled checkpoint'
    require_trace 'summary .*runtimeErrors=2 .*probesRemoved=3 ' 'two expected fulfillment publication faults and clean phase-two shutdown'
    reject_trace 'autonomous activity blocked .*domain=contract' 'ordinary post-mutation fulfillment error swallowed as blocked'
    reject_trace 'CANDIDATE_PHYSICAL_HARD_FAILURE' 'unverifiable contract rollback'

    FULFILLED_SESSION=$(/usr/bin/find "$PERSISTENCE_ROOT" -type f -path '*/checkpoints/contract-fulfilled-v33/session.json' -print -quit)
    [ -n "$FULFILLED_SESSION" ] || fail "contract-fulfilled-v33 session.json missing"
    /usr/bin/grep -q '"schemaVersion":33' "$FULFILLED_SESSION" \
        || fail "fulfilled contract checkpoint is not schema 33"
    FULFILLED_DIGEST=$(/usr/bin/sed -n 's/.*checkpoint saved name=contract-fulfilled-v33 .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' "$PHASE2_TRACE" | /usr/bin/tail -1)
    [ -n "$FULFILLED_DIGEST" ] || fail "fulfilled contract digest extraction failed"
    persisted_world_tick=$(/usr/bin/sqlite3 "$DB_PATH" "SELECT json_extract(json, '$.dims.\"0\".time') FROM worlds;")
    case "$persisted_world_tick" in
        ''|*[!0-9]*) fail "invalid persisted fulfilled World tick: $persisted_world_tick" ;;
    esac
    continuation_command_tick=$((persisted_world_tick + 100))

    printf '\nContract phase 3: restore fulfilled state and prove no duplicate fulfillment.\n'
    PHASE3_SHOTS="$CAPTURE_VERIFIED_PATH|$CAPTURE_PATH"
    run_contract_app \
        "$SESSION_HOME" "$PHASE3_TRACE" "$CONTRACT_PHASE3_COMMANDS" \
        0 "$continuation_command_tick" "$PHASE3_SHOTS" 0 0 0 0
    TRACE_PATH="$PHASE3_TRACE"
    [ -s "$CAPTURE_VERIFIED_PATH" ] || fail "contract restored-fulfilled capture missing"
    [ -s "$CAPTURE_PATH" ] || fail "contract final capture missing"
    require_trace "checkpoint loaded name=contract-fulfilled-v33 .*digest=$FULFILLED_DIGEST .*restartSafe=1 .*custodyDuplicates=0 physicalBoundary=acquired" 'fresh-process fulfilled contract restore'
    require_trace 'contracts enabled=1 .*active=0 debts=0 fulfilled=1 .*proofFixtureDecisionAuthority=0 .*manualProductiveContractCommandsAfterBootstrap=0 .*duplicateFulfillmentReceipts=0' 'fulfilled contract remains closed once'
    require_trace 'contract proof result=PASS .*fulfillment=physical exactOnce=1 duplicateFulfillmentCount=0 observerMutationCount=0' 'duplicate attempt remains refused after restart'
    require_trace 'checkpoint saved name=contract-final-v33 .*restartSafe=1 ' 'final schema-33 checkpoint'
    require_trace 'Contract disposable fixture cleanup cells=exact fulfilledCustody=retained' 'fixture cleanup retains performed custody'
    require_trace 'summary .*runtimeErrors=0 .*probesRemoved=3 ' 'phase-three clean shutdown'
    reject_trace 'contract physical publication obligation=.*action=fulfillment|contract post-transfer mutation .*action=fulfillment|^\[lab-live\] error ' 'duplicate fulfillment or unexpected continuation error'

    FINAL_SESSION=$(/usr/bin/find "$PERSISTENCE_ROOT" -type f -path '*/checkpoints/contract-final-v33/session.json' -print -quit)
    [ -n "$FINAL_SESSION" ] || fail "contract-final-v33 session.json missing"
    /usr/bin/grep -q '"schemaVersion":33' "$FINAL_SESSION" \
        || fail "final contract checkpoint is not schema 33"
    if /usr/bin/pgrep -x Pebble >/dev/null 2>&1 \
        || /usr/bin/pgrep -x swift-run >/dev/null 2>&1 \
        || /usr/bin/pgrep -x pebsmoke >/dev/null 2>&1; then
        fail "residual PebbleLab process after contract proof"
    fi
    printf '\nPASS: CIV-36 capacity prevalidation, current asset authority, ordinary and explicit exact rollback/retry, three-process durability, exact-once fulfillment, and cleanup verified.\n'
    printf 'Capacity trace: %s\n' "$PHASE_CAPACITY_TRACE"
    printf 'Phase 1 trace: %s\n' "$PHASE1_TRACE"
    printf 'Phase 2 trace: %s\n' "$PHASE2_TRACE"
    printf 'Phase 3 trace: %s\n' "$PHASE3_TRACE"
    printf 'Checkpoint schema: 33\n'
    printf 'Observer schema: 10\n'
    printf 'Final capture: %s\n' "$CAPTURE_PATH"
    printf 'Retained isolated session: %s\n' "$SESSION_ROOT"
    exit 0
fi

if [ "$MODE" = "barter" ]; then
    cd "$ROOT_DIR"
    swift build -c release --product Pebble
    PEBBLE_BINARY="$ROOT_DIR/.build/release/Pebble"
    [ -x "$PEBBLE_BINARY" ] \
        || fail "Release Pebble binary missing: $PEBBLE_BINARY"

    PHASE1_TRACE="$SESSION_ROOT/barter-phase1.log"
    PHASE2_TRACE="$SESSION_ROOT/barter-phase2.log"

    run_barter_app() {
        run_home=$1
        run_trace=$2
        run_commands=$3
        create_world=$4
        command_world_tick=$5
        run_shots=$6
        mid_fault=$7
        if [ "$create_world" -eq 1 ]; then
            CFFIXED_USER_HOME="$run_home" \
            PEBBLE_AUTOLOAD=1 \
            PEBBLE_NEWWORLD="$WORLD_SEED" \
            PEBBLE_NEWWORLD_NAME="$WORLD_NAME" \
            PEBBLELAB_APP_AGENTS=1 \
            PEBBLELAB_APP_AGENTS_MOVE=1 \
            PEBBLELAB_APP_PROBES=1 \
            PEBBLELAB_DEBUG_ENTITIES=1 \
            PEBBLELAB_APP_AGENTS_OVERLAY=1 \
            PEBBLELAB_APP_AGENTS_TRACE=1 \
            PEBBLELAB_APP_AGENTS_TRACE_EVERY=1 \
            PEBBLELAB_APP_AGENTS_INTERACT=1 \
            PEBBLELAB_APP_AGENTS_MATERIAL=1 \
            PEBBLELAB_APP_AGENTS_PERSISTENCE=1 \
            PEBBLELAB_APP_AGENTS_POPULATION=1 \
            PEBBLELAB_APP_AGENTS_LIFECYCLE=1 \
            PEBBLELAB_APP_AGENTS_SKILLS=1 \
            PEBBLELAB_APP_AGENTS_PRODUCTION=1 \
            PEBBLELAB_APP_AGENTS_BARTER=1 \
            PEBBLELAB_APP_AGENTS_AUTONOMOUS_CIVILIZATION=1 \
            PEBBLELAB_DISPOSABLE_BARTER_MID_FAULT="$mid_fault" \
            PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
            PEBBLE_CMD_WORLD_TICK="$command_world_tick" \
            PEBBLE_CMD="$run_commands" \
            PEBBLE_SHOT="$run_shots" \
            "$PEBBLE_BINARY" 2>&1 | /usr/bin/tee "$run_trace"
        else
            CFFIXED_USER_HOME="$run_home" \
            PEBBLE_AUTOLOAD=1 \
            PEBBLELAB_APP_AGENTS=1 \
            PEBBLELAB_APP_AGENTS_MOVE=1 \
            PEBBLELAB_APP_PROBES=1 \
            PEBBLELAB_DEBUG_ENTITIES=1 \
            PEBBLELAB_APP_AGENTS_OVERLAY=1 \
            PEBBLELAB_APP_AGENTS_TRACE=1 \
            PEBBLELAB_APP_AGENTS_TRACE_EVERY=1 \
            PEBBLELAB_APP_AGENTS_INTERACT=1 \
            PEBBLELAB_APP_AGENTS_MATERIAL=1 \
            PEBBLELAB_APP_AGENTS_PERSISTENCE=1 \
            PEBBLELAB_APP_AGENTS_POPULATION=1 \
            PEBBLELAB_APP_AGENTS_LIFECYCLE=1 \
            PEBBLELAB_APP_AGENTS_SKILLS=1 \
            PEBBLELAB_APP_AGENTS_PRODUCTION=1 \
            PEBBLELAB_APP_AGENTS_BARTER=1 \
            PEBBLELAB_APP_AGENTS_AUTONOMOUS_CIVILIZATION=1 \
            PEBBLELAB_DISPOSABLE_BARTER_MID_FAULT="$mid_fault" \
            PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
            PEBBLE_CMD_WORLD_TICK="$command_world_tick" \
            PEBBLE_CMD="$run_commands" \
            PEBBLE_SHOT="$run_shots" \
            "$PEBBLE_BINARY" 2>&1 | /usr/bin/tee "$run_trace"
        fi
        if /usr/bin/pgrep -x Pebble >/dev/null 2>&1; then
            fail "Pebble process remained after barter phase: $run_trace"
        fi
    }

    printf '\nBarter phase 1: production, local consent, injected mid-transfer rollback, and retry.\n'
    run_barter_app \
        "$SESSION_HOME" "$PHASE1_TRACE" "$BARTER_PHASE1_COMMANDS" \
        1 100 "$SHOT_SPEC" 1
    TRACE_PATH="$PHASE1_TRACE"
    [ -s "$CAPTURE_PRE_PATH" ] || fail "barter pre-exchange capture missing"
    [ -s "$CAPTURE_OFFER_PATH" ] || fail "barter offer capture missing"
    [ -s "$CAPTURE_POST_PATH" ] || fail "barter post-exchange capture missing"
    require_trace 'barter setup offeror=agent_[0-9]+ counterparty=agent_[0-9]+ produced=stone_pickaxe:1,bread:2 physical=verified .*opportunity=awaiting-normal-runtime .*productPath=normal-autonomous .*barterProofFixtureDecisionAuthority=0 .*manualProductiveBarterCommandsAfterBootstrap=0' 'bootstrap creates goods and needs but no decisive authority'
    require_trace 'barter normal opportunity discovery .*normalOpportunityDiscovery=1 .*barterProofFixtureDecisionAuthority=0 .*bounds=agents:[0-9]+,counterparties:[0-9]+,goods:[0-9]+,pairs:[0-9]+,needs:[0-9]+,discoveries:[0-9]+' 'bounded normal runtime opportunity discovery'
    require_trace 'barter normal offer decision actor=agent_[0-9]+ to=agent_[0-9]+ offer=barter-[0-9a-f]+ normalOfferDecision=1 barterProofFixtureDecisionAuthority=0 physicalMutation=0' 'normal explicit offer without matter movement'
    require_trace_at_least 'barter normal counterparty decision actor=agent_[0-9]+ offer=barter-[0-9a-f]+ decision=accepted normalCounterpartyDecision=1 barterProofFixtureDecisionAuthority=0 .*physicalMutation=0' 2 'independent normal acceptance and retry'
    require_trace 'barter mid-exchange mutation offer=barter-[0-9a-f]+ .*candidatePhysicalMutation=1 publication=0' 'true first physical mutation seam'
    require_trace 'CANDIDATE_PHYSICAL_ROLLBACK operation=advanceOneTick .*barterPostMutationBoundary.*registered=material-transfer:barter:barter-[0-9a-f]+:offered:[0-9]+ .*completed=material-transfer:barter:barter-[0-9a-f]+:offered:[0-9]+ .*publishedSession=unchanged .*publishedRecorder=unchanged' 'exact post-mutation compensation'
    require_trace_count 'barter completed offer=barter-[0-9a-f]+ ' 1 'one completed physical barter after immediate retry'
    require_trace 'barter proof normalProductPath=PASS .*producedGood=stone_pickaxe:1 .*after=agent_[0-9]+:bread:2;agent_[0-9]+:stone_pickaxe:1 .*stale=staleSource wrongQuantity=(invalidRequest|insufficientQuantity) missing=insufficientQuantity capacity=destinationFull adversarialPhysical=exact .*physicalLoss=0 physicalDuplication=0 syntheticMaterial=0' 'positive and adversarial physical matrix'
    require_trace 'checkpoint saved name=barter-v32 .*restartSafe=1 ' 'restart-safe completed barter checkpoint'
    require_trace 'summary .*runtimeErrors=1 .*probesRemoved=3 ' 'one expected injected failure and clean shutdown'
    reject_trace 'CANDIDATE_PHYSICAL_HARD_FAILURE' 'unverifiable barter rollback'

    PERSISTENCE_ROOT="$SESSION_HOME/Library/Application Support/Pebble/PebbleLabAgents"
    PHASE1_SESSION=$(/usr/bin/find "$PERSISTENCE_ROOT" -type f -path '*/checkpoints/barter-v32/session.json' -print -quit)
    [ -n "$PHASE1_SESSION" ] || fail "barter-v32 session.json missing"
    /usr/bin/grep -q '"schemaVersion":32' "$PHASE1_SESSION" \
        || fail "barter-v32 checkpoint is not schema 32"
    PHASE1_DIGEST=$(/usr/bin/sed -n 's/.*checkpoint saved name=barter-v32 .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' "$PHASE1_TRACE" | /usr/bin/tail -1)
    [ -n "$PHASE1_DIGEST" ] || fail "barter-v32 digest extraction failed"
    persisted_world_tick=$(/usr/bin/sqlite3 "$DB_PATH" "SELECT json_extract(json, '$.dims.\"0\".time') FROM worlds;")
    case "$persisted_world_tick" in
        ''|*[!0-9]*) fail "invalid persisted barter World tick: $persisted_world_tick" ;;
    esac
    continuation_command_tick=$((persisted_world_tick + 100))

    printf '\nBarter phase 2: fresh process, exact rights/custody restore, and receiver tool use.\n'
    PHASE2_SHOTS="$CAPTURE_RESTORED_PATH|$CAPTURE_USED_PATH|$CAPTURE_PATH"
    run_barter_app \
        "$SESSION_HOME" "$PHASE2_TRACE" "$BARTER_PHASE2_COMMANDS" \
        0 "$continuation_command_tick" "$PHASE2_SHOTS" 0
    TRACE_PATH="$PHASE2_TRACE"
    [ -s "$CAPTURE_RESTORED_PATH" ] || fail "barter restart capture missing"
    [ -s "$CAPTURE_USED_PATH" ] || fail "barter produced-tool-use capture missing"
    [ -s "$CAPTURE_PATH" ] || fail "barter final capture missing"
    require_trace "checkpoint loaded name=barter-v32 .*digest=$PHASE1_DIGEST .*restartSafe=1 .*custodyDuplicates=0 physicalBoundary=acquired" 'fresh-process physical custody restore'
    require_trace 'barter enabled=1 .*barter-[0-9a-f]+:completed .*completed=1 .*physicalLoss=0 physicalDuplication=0 syntheticMaterial=0 duplicateExchangeReceipts=0 duplicateReservations=0 .*barterProofFixtureDecisionAuthority=0 .*manualProductiveBarterCommandsAfterBootstrap=0' 'one durable normal exchange without replayed transfer'
    require_trace 'bartered produced tool used producer=agent_[0-9]+ receiver=agent_[0-9]+ .*sameItem=stone_pickaxe damage=0>1 world=stone>air downstreamUse=PASS' 'receiver uses exact produced tool after restart'
    require_trace 'checkpoint saved name=barter-final-v32 .*restartSafe=1 ' 'final v32 checkpoint'
    require_trace 'Barter disposable fixture cleanup cells=exact exchangedCustody=retained' 'fixture cleanup retains exchanged goods'
    require_trace 'summary .*runtimeErrors=0 .*probesRemoved=3 ' 'fresh continuation clean shutdown'
    reject_trace 'barter completed offer=barter-[0-9a-f]+ ' 'completed barter repeated after restart'
    reject_trace '^\[lab-live\] error ' 'unexpected continuation runtime error'

    FINAL_SESSION=$(/usr/bin/find "$PERSISTENCE_ROOT" -type f -path '*/checkpoints/barter-final-v32/session.json' -print -quit)
    [ -n "$FINAL_SESSION" ] || fail "barter-final-v32 session.json missing"
    /usr/bin/grep -q '"schemaVersion":32' "$FINAL_SESSION" \
        || fail "barter-final-v32 checkpoint is not schema 32"
    if /usr/bin/pgrep -x Pebble >/dev/null 2>&1 \
        || /usr/bin/pgrep -x swift-run >/dev/null 2>&1 \
        || /usr/bin/pgrep -x pebsmoke >/dev/null 2>&1; then
        fail "residual PebbleLab process after barter proof"
    fi
    printf '\nPASS: CIV-35 normal discovery, local consent, sustainable offers, atomic rollback/retry, restart, downstream use, and cleanup verified.\n'
    printf 'Phase 1 trace: %s\n' "$PHASE1_TRACE"
    printf 'Phase 2 trace: %s\n' "$PHASE2_TRACE"
    printf 'Checkpoint schema: 32\n'
    printf 'Observer schema: 9\n'
    printf 'Final capture: %s\n' "$CAPTURE_PATH"
    printf 'Retained isolated session: %s\n' "$SESSION_ROOT"
    exit 0
fi

if [ "$MODE" = "production" ]; then
    cd "$ROOT_DIR"
    swift build -c release --product Pebble
    PEBBLE_BINARY="$ROOT_DIR/.build/release/Pebble"
    [ -x "$PEBBLE_BINARY" ] \
        || fail "Release Pebble binary missing: $PEBBLE_BINARY"

    PHASE1_TRACE="$SESSION_ROOT/production-phase1.log"
    PHASE2_TRACE="$SESSION_ROOT/production-phase2.log"

    run_production_app() {
        run_home=$1
        run_trace=$2
        run_commands=$3
        create_world=$4
        command_world_tick=$5
        run_shots=$6
        if [ "$create_world" -eq 1 ]; then
            CFFIXED_USER_HOME="$run_home" \
            PEBBLE_AUTOLOAD=1 \
            PEBBLE_NEWWORLD="$WORLD_SEED" \
            PEBBLE_NEWWORLD_NAME="$WORLD_NAME" \
            PEBBLELAB_APP_AGENTS=1 \
            PEBBLELAB_APP_AGENTS_MOVE=1 \
            PEBBLELAB_APP_PROBES=1 \
            PEBBLELAB_DEBUG_ENTITIES=1 \
            PEBBLELAB_APP_AGENTS_OVERLAY=1 \
            PEBBLELAB_APP_AGENTS_TRACE=1 \
            PEBBLELAB_APP_AGENTS_TRACE_EVERY=1 \
            PEBBLELAB_APP_AGENTS_INTERACT=1 \
            PEBBLELAB_APP_AGENTS_MATERIAL=1 \
            PEBBLELAB_APP_AGENTS_PERSISTENCE=1 \
            PEBBLELAB_APP_AGENTS_POPULATION=1 \
            PEBBLELAB_APP_AGENTS_LIFECYCLE=1 \
            PEBBLELAB_APP_AGENTS_SKILLS=1 \
            PEBBLELAB_APP_AGENTS_PRODUCTION=1 \
            PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
            PEBBLE_CMD_WORLD_TICK="$command_world_tick" \
            PEBBLE_CMD="$run_commands" \
            PEBBLE_SHOT="$run_shots" \
            "$PEBBLE_BINARY" 2>&1 | /usr/bin/tee "$run_trace"
        else
            CFFIXED_USER_HOME="$run_home" \
            PEBBLE_AUTOLOAD=1 \
            PEBBLELAB_APP_AGENTS=1 \
            PEBBLELAB_APP_AGENTS_MOVE=1 \
            PEBBLELAB_APP_PROBES=1 \
            PEBBLELAB_DEBUG_ENTITIES=1 \
            PEBBLELAB_APP_AGENTS_OVERLAY=1 \
            PEBBLELAB_APP_AGENTS_TRACE=1 \
            PEBBLELAB_APP_AGENTS_TRACE_EVERY=1 \
            PEBBLELAB_APP_AGENTS_INTERACT=1 \
            PEBBLELAB_APP_AGENTS_MATERIAL=1 \
            PEBBLELAB_APP_AGENTS_PERSISTENCE=1 \
            PEBBLELAB_APP_AGENTS_POPULATION=1 \
            PEBBLELAB_APP_AGENTS_LIFECYCLE=1 \
            PEBBLELAB_APP_AGENTS_SKILLS=1 \
            PEBBLELAB_APP_AGENTS_PRODUCTION=1 \
            PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
            PEBBLE_CMD_WORLD_TICK="$command_world_tick" \
            PEBBLE_CMD="$run_commands" \
            PEBBLE_SHOT="$run_shots" \
            "$PEBBLE_BINARY" 2>&1 | /usr/bin/tee "$run_trace"
        fi
        if /usr/bin/pgrep -x Pebble >/dev/null 2>&1; then
            fail "Pebble process remained after production phase: $run_trace"
        fi
    }

    printf '\nProduction phase 1: autonomous physical recipes and protected checkpoint.\n'
    run_production_app \
        "$SESSION_HOME" "$PHASE1_TRACE" "$PRODUCTION_PHASE1_COMMANDS" \
        1 100 "$SHOT_SPEC"
    TRACE_PATH="$PHASE1_TRACE"
    [ -s "$CAPTURE_WORKSHOP_PATH" ] \
        || fail "production workshop capture missing: $CAPTURE_WORKSHOP_PATH"
    [ -s "$CAPTURE_TOOL_PATH" ] \
        || fail "production tool capture missing: $CAPTURE_TOOL_PATH"
    [ -s "$CAPTURE_OUTPUT_PATH" ] \
        || fail "production output capture missing: $CAPTURE_OUTPUT_PATH"
    require_trace 'production setup actor=agent_2 reason=missingUsefulTool .*workshop=crafting_table@.*inputs=cobblestone:3,stick:2,wheat:3 .*outputsBefore=stone_pickaxe:0,bread:0 .*productPath=autonomous' 'causal need and physical workshop setup'
    require_trace 'production boundary proof missingInput=PASS wrongQuantity=PASS wrongIdentity=PASS staleWorkshop=PASS externalChange=PASS reservedAmbiguous=PASS contention=PASS lateMutationReached=1 rollback=exact immediateRetry=PASS session=exact physicalLoss=0 physicalDuplication=0 syntheticMaterial=0 productionPublication=0' 'negative matrix and true post-mutation rollback'
    require_trace_count 'production verified actor=agent_2 ' 2 'exactly two normal production publications'
    require_trace 'production verified actor=agent_2 .*inputs=cobblestone:3,stick:2 output=stone_pickaxe:1 ' 'canonical stone pickaxe recipe'
    require_trace 'production verified actor=agent_2 .*inputs=wheat:3 output=bread:1 ' 'second canonical bread recipe'
    require_trace_count 'autonomous activity completed .*actor=agent_2 domain=production ' 2 'two production activities through normal autonomy'
    require_trace 'autonomous material practice actor=agent_2 domain=crafting .*practice=0>1 .*outputBonus=0 manualTrigger=0' 'first real crafting practice'
    require_trace 'autonomous material practice actor=agent_2 domain=crafting .*practice=1>2 .*outputBonus=0 manualTrigger=0' 'second real crafting practice'
    require_trace 'production enabled=1 activeNeeds=0 fulfilled=2 opportunities=0 records=2 uses=0 totalProduction=2 duplicateProductionReceipts=0 inFlight=0 .*custody=agent_2:1,agent_2:1' 'exact output history and live custody before restart'
    require_trace 'checkpoint saved name=production-v31 .*restartSafe=1 protectedCustodyAgents=3 protectedCustodyStacks=2 protectedCustodyQuantity=2 ' 'restart-safe exact physical custody checkpoint'
    require_trace 'summary .*runtimeErrors=0 .*probesRemoved=3 ' 'first process clean runtime shutdown'
    require_trace 'stop probesRemoved=3 reason=termination custodyHandoff=protected handoffFreshness=exact taggedCustodySpills=2' 'first process exact protected-custody handoff'
    reject_trace '^\[lab-live\] error ' 'unexpected first-process runtime error'

    PERSISTENCE_ROOT="$SESSION_HOME/Library/Application Support/Pebble/PebbleLabAgents"
    PHASE1_SESSION=$(/usr/bin/find "$PERSISTENCE_ROOT" -type f -path '*/checkpoints/production-v31/session.json' -print -quit)
    [ -n "$PHASE1_SESSION" ] || fail "production-v31 session.json missing"
    /usr/bin/grep -q '"schemaVersion":31' "$PHASE1_SESSION" \
        || fail "production-v31 checkpoint is not schema 31"
    PHASE1_DIGEST=$(/usr/bin/sed -n 's/.*checkpoint saved name=production-v31 .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' "$PHASE1_TRACE" | /usr/bin/tail -1)
    [ -n "$PHASE1_DIGEST" ] || fail "production-v31 digest extraction failed"
    [ -f "$DB_PATH" ] || fail "production disposable database missing"
    persisted_world_tick=$(/usr/bin/sqlite3 "$DB_PATH" "SELECT json_extract(json, '$.dims.\"0\".time') FROM worlds;")
    case "$persisted_world_tick" in
        ''|*[!0-9]*) fail "invalid persisted production World tick: $persisted_world_tick" ;;
    esac
    continuation_command_tick=$((persisted_world_tick + 100))

    printf '\nProduction phase 2: fresh process, exact custody restore, and produced-tool use.\n'
    PHASE2_SHOTS="$CAPTURE_RESTORED_PATH|$CAPTURE_USED_PATH|$CAPTURE_PATH"
    run_production_app \
        "$SESSION_HOME" "$PHASE2_TRACE" "$PRODUCTION_PHASE2_COMMANDS" \
        0 "$continuation_command_tick" "$PHASE2_SHOTS"
    TRACE_PATH="$PHASE2_TRACE"
    [ -s "$CAPTURE_RESTORED_PATH" ] \
        || fail "production restart capture missing: $CAPTURE_RESTORED_PATH"
    [ -s "$CAPTURE_USED_PATH" ] \
        || fail "production use capture missing: $CAPTURE_USED_PATH"
    [ -s "$CAPTURE_PATH" ] \
        || fail "production final capture missing: $CAPTURE_PATH"
    require_trace "checkpoint loaded name=production-v31 .*digest=$PHASE1_DIGEST .*restartSafe=1 .*custodyRestoredStacks=2 custodyRestoredQuantity=2 .*custodyDuplicates=0 physicalBoundary=acquired" 'fresh-process exact session and physical custody restore'
    require_trace 'production enabled=1 activeNeeds=0 fulfilled=2 opportunities=0 records=2 uses=0 totalProduction=2 duplicateProductionReceipts=0 inFlight=0 .*custody=agent_2:1,agent_2:1' 'restored output history without duplication'
    require_trace 'produced tool used actor=agent_2 .*sameItem=stone_pickaxe damage=0>1 world=stone>air dropsAcquired=[1-9][0-9]* wrongTool=FAIL_CLOSED .*postRestartCapable=1' 'same produced stack used after restart with real durability and World effect'
    require_trace 'production enabled=1 activeNeeds=0 fulfilled=2 opportunities=0 records=2 uses=1 totalProduction=2 duplicateProductionReceipts=0 inFlight=0 ' 'post-use causal production state'
    require_trace 'production cleanup workshop=air target=air cognition=retained custody=retained fixtureCells=exact' 'disposable fixture cleanup'
    require_trace 'checkpoint saved name=production-final-v31 .*restartSafe=1 protectedCustodyAgents=3 protectedCustodyStacks=3 protectedCustodyQuantity=3 ' 'final damaged-tool, bread, and acquired-drop custody checkpoint'
    require_trace 'summary .*runtimeErrors=0 .*probesRemoved=3 ' 'second process clean runtime shutdown'
    require_trace 'stop probesRemoved=3 reason=termination custodyHandoff=protected handoffFreshness=exact taggedCustodySpills=3' 'second process exact protected-custody handoff'
    reject_trace '^\[lab-live\] error ' 'unexpected second-process runtime error'

    FINAL_SESSION=$(/usr/bin/find "$PERSISTENCE_ROOT" -type f -path '*/checkpoints/production-final-v31/session.json' -print -quit)
    [ -n "$FINAL_SESSION" ] || fail "production-final-v31 session.json missing"
    /usr/bin/grep -q '"schemaVersion":31' "$FINAL_SESSION" \
        || fail "production-final-v31 checkpoint is not schema 31"
    world_facts=$(/usr/bin/sqlite3 "$DB_PATH" "SELECT count(*), json_extract(json, '$.seed'), json_extract(json, '$.name'), json_extract(json, '$.dims.\"0\".dayTime'), json_extract(json, '$.dims.\"0\".raining'), json_extract(json, '$.dims.\"0\".thundering'), json_extract(json, '$.gameRules.doMobSpawning'), json_extract(json, '$.gameRules.doDaylightCycle'), json_extract(json, '$.gameRules.doWeatherCycle') FROM worlds;")
    expected_world_facts="1|$WORLD_SEED|$WORLD_NAME|1000|0|0|0|0|0"
    [ "$world_facts" = "$expected_world_facts" ] \
        || fail "unexpected production disposable World facts: $world_facts"
    if /usr/bin/pgrep -x Pebble >/dev/null 2>&1 \
        || /usr/bin/pgrep -x swift-run >/dev/null 2>&1 \
        || /usr/bin/pgrep -x pebsmoke >/dev/null 2>&1; then
        fail "residual PebbleLab process after production proof"
    fi
    printf '\nPASS: canonical production, adversarial rollback, exact custody restart, produced-tool use, and cleanup verified.\n'
    printf 'Phase 1 trace: %s\n' "$PHASE1_TRACE"
    printf 'Phase 2 trace: %s\n' "$PHASE2_TRACE"
    printf 'Checkpoint schema: 31\n'
    printf 'Final capture: %s\n' "$CAPTURE_PATH"
    printf 'Retained isolated session: %s\n' "$SESSION_ROOT"
    exit 0
fi

if [ "$MODE" = "reproduction" ] || [ "$MODE" = "kinship" ] \
    || [ "$MODE" = "households" ] || [ "$MODE" = "care" ]; then
    cd "$ROOT_DIR"
    swift build -c release --product Pebble
    PEBBLE_BINARY="$ROOT_DIR/.build/release/Pebble"
    [ -x "$PEBBLE_BINARY" ] || fail "Release Pebble binary missing: $PEBBLE_BINARY"

    PHASE1_TRACE="$SESSION_ROOT/reproduction-phase1.log"
    PHASE2_TRACE="$SESSION_ROOT/reproduction-phase2.log"
    PHASE3_TRACE="$SESSION_ROOT/reproduction-phase3.log"
    CONTROL_HOME="$SESSION_ROOT/control-home"
    CONTROL_TRACE="$SESSION_ROOT/reproduction-control.log"
    [ ! -e "$CONTROL_HOME" ] || fail "fresh reproduction control home already exists: $CONTROL_HOME"

    run_reproduction_app() {
        run_home=$1
        run_trace=$2
        run_commands=$3
        create_world=$4
        command_world_tick=$5
        kinship_late_failure_proof=${6:-0}
        care_late_failure_proof=${7:-0}
        if [ "$create_world" -eq 1 ]; then
            CFFIXED_USER_HOME="$run_home" \
            PEBBLE_AUTOLOAD=1 \
            PEBBLE_NEWWORLD="$WORLD_SEED" \
            PEBBLE_NEWWORLD_NAME="$WORLD_NAME" \
            PEBBLELAB_APP_AGENTS=1 \
            PEBBLELAB_APP_AGENTS_MOVE=1 \
            PEBBLELAB_APP_PROBES=1 \
            PEBBLELAB_DEBUG_ENTITIES=1 \
            PEBBLELAB_APP_AGENTS_OVERLAY=1 \
            PEBBLELAB_APP_AGENTS_TRACE=1 \
            PEBBLELAB_APP_AGENTS_TRACE_EVERY=1 \
            PEBBLELAB_APP_AGENTS_INTERACT=1 \
            PEBBLELAB_APP_AGENTS_NATURAL=0 \
            PEBBLELAB_APP_AGENTS_BUILD=0 \
            PEBBLELAB_APP_AGENTS_SOCIAL=0 \
            PEBBLELAB_APP_AGENTS_PHYSICAL=0 \
            PEBBLELAB_APP_AGENTS_COOPERATION=0 \
            PEBBLELAB_APP_AGENTS_PERSISTENCE=1 \
            PEBBLELAB_APP_AGENTS_POPULATION=1 \
            PEBBLELAB_APP_AGENTS_MULTISCALE=1 \
            PEBBLELAB_APP_AGENTS_ECOLOGY=1 \
            PEBBLELAB_APP_AGENTS_MORTALITY=0 \
            PEBBLELAB_APP_AGENTS_LIFECYCLE=1 \
            PEBBLELAB_APP_AGENTS_KINSHIP="$KINSHIP_GATE" \
            PEBBLELAB_APP_AGENTS_HOUSEHOLDS="$HOUSEHOLD_GATE" \
            PEBBLELAB_APP_AGENTS_CARE="$CARE_GATE" \
            PEBBLELAB_DISPOSABLE_KINSHIP_LATE_FAILURE_PROOF="$kinship_late_failure_proof" \
            PEBBLELAB_DISPOSABLE_CARE_LATE_FAILURE_PROOF="$care_late_failure_proof" \
            PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
            PEBBLE_CMD_WORLD_TICK="$command_world_tick" \
            PEBBLE_CMD="$run_commands" \
            PEBBLE_SHOT='-|-|-|-|-' \
            "$PEBBLE_BINARY" 2>&1 | /usr/bin/tee "$run_trace"
        else
            CFFIXED_USER_HOME="$run_home" \
            PEBBLE_AUTOLOAD=1 \
            PEBBLELAB_APP_AGENTS=1 \
            PEBBLELAB_APP_AGENTS_MOVE=1 \
            PEBBLELAB_APP_PROBES=1 \
            PEBBLELAB_DEBUG_ENTITIES=1 \
            PEBBLELAB_APP_AGENTS_OVERLAY=1 \
            PEBBLELAB_APP_AGENTS_TRACE=1 \
            PEBBLELAB_APP_AGENTS_TRACE_EVERY=1 \
            PEBBLELAB_APP_AGENTS_INTERACT=1 \
            PEBBLELAB_APP_AGENTS_NATURAL=0 \
            PEBBLELAB_APP_AGENTS_BUILD=0 \
            PEBBLELAB_APP_AGENTS_SOCIAL=0 \
            PEBBLELAB_APP_AGENTS_PHYSICAL=0 \
            PEBBLELAB_APP_AGENTS_COOPERATION=0 \
            PEBBLELAB_APP_AGENTS_PERSISTENCE=1 \
            PEBBLELAB_APP_AGENTS_POPULATION=1 \
            PEBBLELAB_APP_AGENTS_MULTISCALE=1 \
            PEBBLELAB_APP_AGENTS_ECOLOGY=1 \
            PEBBLELAB_APP_AGENTS_MORTALITY=0 \
            PEBBLELAB_APP_AGENTS_LIFECYCLE=1 \
            PEBBLELAB_APP_AGENTS_KINSHIP="$KINSHIP_GATE" \
            PEBBLELAB_APP_AGENTS_HOUSEHOLDS="$HOUSEHOLD_GATE" \
            PEBBLELAB_APP_AGENTS_CARE="$CARE_GATE" \
            PEBBLELAB_DISPOSABLE_KINSHIP_LATE_FAILURE_PROOF="$kinship_late_failure_proof" \
            PEBBLELAB_DISPOSABLE_CARE_LATE_FAILURE_PROOF="$care_late_failure_proof" \
            PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
            PEBBLE_CMD_WORLD_TICK="$command_world_tick" \
            PEBBLE_CMD="$run_commands" \
            PEBBLE_SHOT='-|-|-|-|-' \
            "$PEBBLE_BINARY" 2>&1 | /usr/bin/tee "$run_trace"
        fi
        if /usr/bin/pgrep -x Pebble >/dev/null 2>&1; then
            fail "Pebble process remained after reproduction phase: $run_trace"
        fi
    }

    printf '\nReproduction phase 1: four mature residents and mid-plan v6 checkpoint.\n'
    run_reproduction_app "$SESSION_HOME" "$PHASE1_TRACE" "$REPRODUCTION_PHASE1_COMMANDS" 1 100
    TRACE_PATH="$PHASE1_TRACE"
    require_trace 'start seed=46 agents=3 tick=0 ' 'historical three-agent bootstrap'
    require_trace '^\[pebblelab-proof\] disposable-world gate=armed$' 'explicit disposable-world proof gate'
    require_trace 'migration id=migration-00000003 migrant=agent_3 .*status=arrived ' 'physical agent_3 arrival before lifecycle activation'
    require_trace 'population gate=enabled enabled=1 settlement=settlement-main capacity=8 members=4 founders=3 residents=4 migrating=0 nextOrdinal=4 ' 'four resident population'
    require_trace "lifecycle tick=$REPRO_INITIAL_TICK enabled=1 reproduction=0 newborn=0 juvenile=0 mature=4 plans=0 .*ages=agent_0:[0-9]+/mature,agent_1:[0-9]+/mature,agent_2:[0-9]+/mature,agent_3:[0-9]+/mature nextOrdinal=4 probes=agent_0,agent_1,agent_2,agent_3 " 'four bootstrap mature lifecycle members'
    require_trace "lifecycle tick=$REPRO_PLAN_TICK enabled=1 reproduction=1 newborn=0 juvenile=0 mature=4 plans=1 plan=$REPRO_PLAN_ID due=$REPRO_BIRTH_TICK births=0 " 'deterministic pending plan'
    require_trace "reproduction tick=$REPRO_PLAN_TICK enabled=1 eligible=.* pairs=.* plan=$REPRO_PLAN_ID parents=agent_0,agent_1 created=$REPRO_PLAN_TICK due=$REPRO_BIRTH_TICK population=4/8 pressure=(abundant|adequate) food=[1-9][0-9]* lastCancellation=none " 'true reproductive eligibility status'
    require_trace "checkpoint saved name=reproduction-midplan .*tick=$REPRO_PLAN_TICK .*restartSafe=1 " 'restart-safe mid-plan checkpoint'
    require_trace 'summary .*agents=4 .*runtimeErrors=0 .*probesRemoved=4 ' 'clean mid-plan four-probe cleanup'
    reject_trace 'birth finalized|runtime error|worldMutation=(block|world)' 'premature birth, runtime error, or World mutation'
    if [ "$MODE" = "kinship" ] || [ "$MODE" = "households" ] || [ "$MODE" = "care" ]; then
        require_trace "kinship tick=$REPRO_INITIAL_TICK enabled=1 people=4 parentages=0 child=none parents=none digest=[0-9a-f]+ worldMutation=none" 'explicit four-root kinship initialization'
    fi
    if [ "$MODE" = "households" ] || [ "$MODE" = "care" ]; then
        require_trace "household tick=$REPRO_INITIAL_TICK enabled=1 households=[1-9][0-9]* active=[1-9][0-9]* memberships=4 nextOrdinal=[1-9][0-9]* digest=[0-9a-f]+ worldMutation=none" 'explicit four-resident household initialization'
    fi
    if [ "$MODE" = "care" ]; then
        require_trace "care tick=$REPRO_INITIAL_TICK enabled=1 assignments=0 needs=0 engagements=0 atRisk= digest=[0-9a-f]+ worldMutation=none" 'explicit mature-only care initialization'
    fi

    REPRODUCTION_ROOT="$SESSION_HOME/Library/Application Support/Pebble/PebbleLabAgents"
    MID_MANIFEST=$(/usr/bin/find "$REPRODUCTION_ROOT" -type f -path '*/checkpoints/reproduction-midplan/manifest.json' -print -quit)
    MID_SESSION=$(/usr/bin/find "$REPRODUCTION_ROOT" -type f -path '*/checkpoints/reproduction-midplan/session.json' -print -quit)
    [ -n "$MID_MANIFEST" ] && [ -n "$MID_SESSION" ] || fail "mid-plan v6 bundle missing"
    /usr/bin/grep -q "\"schemaVersion\":$EXPECTED_REPRODUCTION_SCHEMA" "$MID_MANIFEST" \
        || fail "mid-plan manifest is not v$EXPECTED_REPRODUCTION_SCHEMA"
    /usr/bin/grep -q "\"schemaVersion\":$EXPECTED_REPRODUCTION_SCHEMA" "$MID_SESSION" \
        || fail "mid-plan session is not v$EXPECTED_REPRODUCTION_SCHEMA"
    /usr/bin/grep -q '"restartSafe":true' "$MID_MANIFEST" || fail "mid-plan checkpoint is not restart-safe"
    [ "$(/usr/bin/plutil -extract durableState.lifecycleState.totalBirthCount raw -o - "$MID_SESSION")" = "0" ] \
        || fail "mid-plan checkpoint already contains a birth"
    [ "$(/usr/bin/plutil -extract durableState.lifecycleState.plans.0.status raw -o - "$MID_SESSION")" = "planned" ] \
        && [ "$(/usr/bin/plutil -extract durableState.lifecycleState.plans.0.dueTick raw -o - "$MID_SESSION")" = "$REPRO_BIRTH_TICK" ] \
        || fail "mid-plan pending plan is not exact"
    [ "$(/usr/bin/plutil -extract durableState.populationRegistry.nextPopulationOrdinal raw -o - "$MID_SESSION")" = "4" ] \
        || fail "mid-plan ordinal is not four"
    [ "$(/usr/bin/plutil -extract durableState.lifecycleState.members.3.agentID raw -o - "$MID_SESSION")" = "agent_3" ] \
        && [ "$(/usr/bin/plutil -extract durableState.lifecycleState.members.3.origin raw -o - "$MID_SESSION")" = "importedMigrant" ] \
        || fail "activation did not preserve the arrived migrant's demographic origin"
    if [ "$MODE" = "kinship" ] || [ "$MODE" = "households" ] || [ "$MODE" = "care" ]; then
        [ "$(/usr/bin/plutil -extract durableState.kinshipState.totalHistoricalPersonCount raw -o - "$MID_SESSION")" = "4" ] \
            && [ "$(/usr/bin/plutil -extract durableState.kinshipState.totalParentageRecordCount raw -o - "$MID_SESSION")" = "0" ] \
            || fail "kinship activation did not archive exactly four roots"
        PREACTIVATION_V6=$(/usr/bin/find "$REPRODUCTION_ROOT" -type f -path '*/checkpoints/kinship-preactivation-v6/session.json' -print -quit)
        [ -n "$PREACTIVATION_V6" ] \
            && /usr/bin/grep -q '"schemaVersion":6' "$PREACTIVATION_V6" \
            && ! /usr/bin/grep -q '"kinshipState"' "$PREACTIVATION_V6" \
            || fail "kinship preactivation v6 checkpoint is not exact"
    fi
    if [ "$MODE" = "households" ] || [ "$MODE" = "care" ]; then
        PREACTIVATION_V7=$(/usr/bin/find "$REPRODUCTION_ROOT" -type f -path '*/checkpoints/households-preactivation-v7/session.json' -print -quit)
        [ -n "$PREACTIVATION_V7" ] \
            && /usr/bin/grep -q '"schemaVersion":7' "$PREACTIVATION_V7" \
            && /usr/bin/grep -q '"kinshipState"' "$PREACTIVATION_V7" \
            && ! /usr/bin/grep -q '"householdState"' "$PREACTIVATION_V7" \
            || fail "household preactivation v7 checkpoint is not exact"
        [ "$(/usr/bin/plutil -extract durableState.householdState.membershipPeriods json -o - "$MID_SESSION" \
            | /usr/bin/grep -o '"agentID"' | /usr/bin/wc -l | /usr/bin/tr -d ' ')" = "4" ] \
            || fail "household activation did not assign exactly four residents"
    fi
    if [ "$MODE" = "care" ]; then
        PREACTIVATION_V8=$(/usr/bin/find "$REPRODUCTION_ROOT" -type f -path '*/checkpoints/care-preactivation-v8/session.json' -print -quit)
        [ -n "$PREACTIVATION_V8" ] \
            && /usr/bin/grep -q '"schemaVersion":8' "$PREACTIVATION_V8" \
            && /usr/bin/grep -q '"householdState"' "$PREACTIVATION_V8" \
            && ! /usr/bin/grep -q '"dependentCareState"' "$PREACTIVATION_V8" \
            || fail "care preactivation v8 checkpoint is not exact"
        [ "$(/usr/bin/plutil -extract durableState.dependentCareState.totalAssignmentCount raw -o - "$MID_SESSION")" = "0" ] \
            || fail "care activation invented an assignment for mature founders"
    fi

    MID_DIGEST=$(/usr/bin/sed -n 's/.*checkpoint saved name=reproduction-midplan .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' "$PHASE1_TRACE" | /usr/bin/tail -1)
    MID_SIM=$(/usr/bin/sed -n 's/.*checkpoint saved name=reproduction-midplan .* simulation=\([^ ]*\) digest=.*/\1/p' "$PHASE1_TRACE" | /usr/bin/tail -1)
    [ -n "$MID_DIGEST" ] && [ -n "$MID_SIM" ] || fail "mid-plan identity extraction failed"

    CONTROL_DB="$CONTROL_HOME/Library/Application Support/Pebble/pebble.db"
    /bin/mkdir -p "$(dirname "$CONTROL_DB")"
    [ ! -e "$CONTROL_DB" ] || fail "fresh reproduction control database already exists"
    /usr/bin/sqlite3 "$DB_PATH" ".backup '$CONTROL_DB'"
    [ -s "$CONTROL_DB" ] || fail "reproduction control database snapshot failed"
    persisted_world_tick=$(/usr/bin/sqlite3 "$DB_PATH" "SELECT json_extract(json, '$.dims.\"0\".time') FROM worlds;")
    case "$persisted_world_tick" in
        ''|*[!0-9]*) fail "invalid persisted World tick after reproduction phase 1: $persisted_world_tick" ;;
    esac
    continuation_command_tick=$((persisted_world_tick + 100))

    if [ "$MODE" = "kinship" ] || [ "$MODE" = "households" ] || [ "$MODE" = "care" ]; then
        run_lineage_gate_case() {
            gate_name=$1
            agents_gate=$2
            persistence_gate=$3
            population_gate=$4
            lifecycle_gate=$5
            kinship_gate=$6
            household_gate=$7
            care_gate=0
            gate_commands=$8
            if [ "$#" -eq 9 ]; then
                care_gate=$8
                gate_commands=$9
            fi
            gate_home="$SESSION_ROOT/gate-$gate_name-home"
            gate_trace="$SESSION_ROOT/gate-$gate_name.log"
            [ ! -e "$gate_home" ] || fail "fresh lineage gate home already exists: $gate_name"
            /usr/bin/ditto "$SESSION_HOME" "$gate_home"
            CFFIXED_USER_HOME="$gate_home" \
            PEBBLE_AUTOLOAD=1 \
            PEBBLELAB_APP_AGENTS="$agents_gate" \
            PEBBLELAB_APP_AGENTS_MOVE=1 \
            PEBBLELAB_APP_PROBES=1 \
            PEBBLELAB_DEBUG_ENTITIES=1 \
            PEBBLELAB_APP_AGENTS_OVERLAY=1 \
            PEBBLELAB_APP_AGENTS_TRACE=1 \
            PEBBLELAB_APP_AGENTS_TRACE_EVERY=1 \
            PEBBLELAB_APP_AGENTS_INTERACT=1 \
            PEBBLELAB_APP_AGENTS_NATURAL=0 \
            PEBBLELAB_APP_AGENTS_BUILD=0 \
            PEBBLELAB_APP_AGENTS_SOCIAL=0 \
            PEBBLELAB_APP_AGENTS_PHYSICAL=0 \
            PEBBLELAB_APP_AGENTS_COOPERATION=0 \
            PEBBLELAB_APP_AGENTS_PERSISTENCE="$persistence_gate" \
            PEBBLELAB_APP_AGENTS_POPULATION="$population_gate" \
            PEBBLELAB_APP_AGENTS_MULTISCALE=1 \
            PEBBLELAB_APP_AGENTS_ECOLOGY=1 \
            PEBBLELAB_APP_AGENTS_MORTALITY=0 \
            PEBBLELAB_APP_AGENTS_LIFECYCLE="$lifecycle_gate" \
            PEBBLELAB_APP_AGENTS_KINSHIP="$kinship_gate" \
            PEBBLELAB_APP_AGENTS_HOUSEHOLDS="$household_gate" \
            PEBBLELAB_APP_AGENTS_CARE="$care_gate" \
            PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
            PEBBLE_CMD_WORLD_TICK="$continuation_command_tick" \
            PEBBLE_CMD="$gate_commands" \
            PEBBLE_SHOT='-|-|-|-|-' \
            "$PEBBLE_BINARY" 2>&1 | /usr/bin/tee "$gate_trace"
            if /usr/bin/pgrep -x Pebble >/dev/null 2>&1; then
                fail "Pebble process remained after lineage gate case: $gate_name"
            fi
            TRACE_PATH="$gate_trace"
        }

        if [ "$MODE" = "kinship" ]; then
            printf '\nKinship gate matrix: exact dependency and restore refusals.\n'
            run_lineage_gate_case only 0 0 0 0 1 0 \
                "$POPULATION_WORLD_READY|/lab kinship on"
            require_trace 'kinship gates refused missing=PEBBLELAB_APP_AGENTS=1,PEBBLELAB_APP_AGENTS_PERSISTENCE=1,PEBBLELAB_APP_AGENTS_POPULATION=1,PEBBLELAB_APP_AGENTS_LIFECYCLE=1' 'kinship-only refusal'
            run_lineage_gate_case agents-no-persistence 1 0 0 0 1 0 \
                "$POPULATION_WORLD_READY|/lab kinship on"
            require_trace 'kinship gates refused missing=PEBBLELAB_APP_AGENTS_PERSISTENCE=1,PEBBLELAB_APP_AGENTS_POPULATION=1,PEBBLELAB_APP_AGENTS_LIFECYCLE=1' 'agents without persistence refusal'
            run_lineage_gate_case population-no-lifecycle 1 1 1 0 1 0 \
                "$POPULATION_WORLD_READY|/lab kinship on"
            require_trace 'kinship gates refused missing=PEBBLELAB_APP_AGENTS_LIFECYCLE=1' 'population without lifecycle refusal'
            run_lineage_gate_case lifecycle-no-persistence 1 0 1 1 1 0 \
                "$POPULATION_WORLD_READY|/lab kinship on"
            require_trace 'kinship gates refused missing=PEBBLELAB_APP_AGENTS_PERSISTENCE=1' 'lifecycle without persistence refusal'
            run_lineage_gate_case v7-no-kinship 1 1 1 1 0 0 \
                "$POPULATION_WORLD_READY|/lab start;/lab checkpoint load reproduction-midplan"
            require_trace 'checkpoint load refused name=reproduction-midplan reason=kinshipGate' 'v7 without kinship gate refusal'
            run_lineage_gate_case v7-no-lifecycle 1 1 1 0 1 0 \
                "$POPULATION_WORLD_READY|/lab start;/lab checkpoint load reproduction-midplan"
            require_trace 'checkpoint load refused name=reproduction-midplan reason=lifecycleGate' 'v7 without lifecycle gate refusal'
            run_lineage_gate_case v6-all 1 1 1 1 1 0 \
                "$POPULATION_WORLD_READY|/lab start;/lab checkpoint load kinship-preactivation-v6;/lab kinship status"
            require_trace "checkpoint loaded name=kinship-preactivation-v6 .*tick=$REPRO_INITIAL_TICK .*restartSafe=1 probes=4 paused=1" 'v6 restore with all gates'
            require_trace "kinship tick=$REPRO_INITIAL_TICK enabled=0 people=0 parentages=0 child=none parents=none digest=[0-9a-f]+ worldMutation=none" 'v6 restore does not activate kinship silently'
        elif [ "$MODE" = "households" ]; then
            printf '\nHousehold gate matrix: exact dependencies, activation, and restore refusals.\n'
            run_lineage_gate_case household-only 0 0 0 0 0 1 \
                "$POPULATION_WORLD_READY|/lab household on"
            require_trace 'household gates refused missing=PEBBLELAB_APP_AGENTS=1,PEBBLELAB_APP_AGENTS_PERSISTENCE=1,PEBBLELAB_APP_AGENTS_POPULATION=1,PEBBLELAB_APP_AGENTS_LIFECYCLE=1,PEBBLELAB_APP_AGENTS_KINSHIP=1' 'household-only refusal'
            run_lineage_gate_case household-agents-no-persistence 1 0 0 0 0 1 \
                "$POPULATION_WORLD_READY|/lab household on"
            require_trace 'household gates refused missing=PEBBLELAB_APP_AGENTS_PERSISTENCE=1,PEBBLELAB_APP_AGENTS_POPULATION=1,PEBBLELAB_APP_AGENTS_LIFECYCLE=1,PEBBLELAB_APP_AGENTS_KINSHIP=1' 'household plus agents without persistence refusal'
            run_lineage_gate_case household-population-no-lifecycle 1 1 1 0 1 1 \
                "$POPULATION_WORLD_READY|/lab household on"
            require_trace 'household gates refused missing=PEBBLELAB_APP_AGENTS_LIFECYCLE=1' 'household population without lifecycle refusal'
            run_lineage_gate_case household-lifecycle-no-persistence 1 0 1 1 1 1 \
                "$POPULATION_WORLD_READY|/lab household on"
            require_trace 'household gates refused missing=PEBBLELAB_APP_AGENTS_PERSISTENCE=1' 'household lifecycle without persistence refusal'
            run_lineage_gate_case household-all 1 1 1 1 1 1 \
                "$POPULATION_WORLD_READY|/lab start;/lab checkpoint load households-preactivation-v7;/lab household on;/lab household status"
            require_trace "household tick=$REPRO_INITIAL_TICK enabled=1 households=[1-9][0-9]* active=[1-9][0-9]* memberships=4 nextOrdinal=[1-9][0-9]* digest=[0-9a-f]+ worldMutation=none" 'all household dependencies succeed'
            run_lineage_gate_case v8-no-household 1 1 1 1 1 0 \
                "$POPULATION_WORLD_READY|/lab start;/lab checkpoint load reproduction-midplan"
            require_trace 'checkpoint load refused name=reproduction-midplan reason=householdGate' 'v8 without household gate refusal'
            run_lineage_gate_case v8-no-lifecycle 1 1 1 0 1 1 \
                "$POPULATION_WORLD_READY|/lab start;/lab checkpoint load reproduction-midplan"
            require_trace 'checkpoint load refused name=reproduction-midplan reason=lifecycleGate' 'v8 without lifecycle gate refusal'
            run_lineage_gate_case v7-all 1 1 1 1 1 1 \
                "$POPULATION_WORLD_READY|/lab start;/lab checkpoint load households-preactivation-v7;/lab household status"
            require_trace "checkpoint loaded name=households-preactivation-v7 .*tick=$REPRO_INITIAL_TICK .*restartSafe=1 probes=4 paused=1" 'v7 restore with all household gates'
            require_trace "household tick=$REPRO_INITIAL_TICK enabled=0 households=0 active=0 memberships=0 nextOrdinal=-1 digest=[0-9a-f]+ worldMutation=none" 'v7 restore does not activate households silently'
        else
            printf '\nCare gate matrix: exact dependencies, activation, and restore refusals.\n'
            run_lineage_gate_case care-only 0 0 0 0 0 0 1 \
                "$POPULATION_WORLD_READY|/lab care on"
            require_trace 'care gates refused missing=PEBBLELAB_APP_AGENTS=1,PEBBLELAB_APP_AGENTS_PERSISTENCE=1,PEBBLELAB_APP_AGENTS_POPULATION=1,PEBBLELAB_APP_AGENTS_LIFECYCLE=1,PEBBLELAB_APP_AGENTS_KINSHIP=1,PEBBLELAB_APP_AGENTS_HOUSEHOLDS=1' 'care-only refusal'
            run_lineage_gate_case care-no-persistence 1 0 1 1 1 1 1 \
                "$POPULATION_WORLD_READY|/lab care on"
            require_trace 'care gates refused missing=PEBBLELAB_APP_AGENTS_PERSISTENCE=1' 'care without persistence refusal'
            run_lineage_gate_case care-no-household 1 1 1 1 1 0 1 \
                "$POPULATION_WORLD_READY|/lab care on"
            require_trace 'care gates refused missing=PEBBLELAB_APP_AGENTS_HOUSEHOLDS=1' 'care without household refusal'
            run_lineage_gate_case care-all 1 1 1 1 1 1 1 \
                "$POPULATION_WORLD_READY|/lab start;/lab checkpoint load care-preactivation-v8;/lab survival on;/lab care on;/lab care status"
            require_trace "care tick=$REPRO_INITIAL_TICK enabled=1 assignments=0 needs=0 engagements=0 atRisk= digest=[0-9a-f]+ worldMutation=none" 'all care dependencies succeed'
            run_lineage_gate_case v9-no-care 1 1 1 1 1 1 0 \
                "$POPULATION_WORLD_READY|/lab start;/lab checkpoint load reproduction-midplan"
            require_trace 'checkpoint load refused name=reproduction-midplan reason=careGate' 'v9 without care gate refusal'
            run_lineage_gate_case v9-no-lifecycle 1 1 1 0 1 1 1 \
                "$POPULATION_WORLD_READY|/lab start;/lab checkpoint load reproduction-midplan"
            require_trace 'checkpoint load refused name=reproduction-midplan reason=lifecycleGate' 'v9 without lifecycle gate refusal'
            run_lineage_gate_case v8-all 1 1 1 1 1 1 1 \
                "$POPULATION_WORLD_READY|/lab start;/lab checkpoint load care-preactivation-v8;/lab care status"
            require_trace "checkpoint loaded name=care-preactivation-v8 .*tick=$REPRO_INITIAL_TICK .*restartSafe=1 probes=4 paused=1" 'v8 restore with all care gates'
            require_trace "care tick=$REPRO_INITIAL_TICK enabled=0 assignments=0 needs=0 engagements=0 atRisk= digest=[0-9a-f]+ worldMutation=none" 'v8 restore does not activate care silently'
        fi

        FAILURE_HOME="$SESSION_ROOT/late-failure-home"
        FAILURE_TRACE="$SESSION_ROOT/kinship-late-failure.log"
        [ ! -e "$FAILURE_HOME" ] || fail "fresh kinship late-failure home already exists"
        /usr/bin/ditto "$SESSION_HOME" "$FAILURE_HOME"
        KINSHIP_FAILURE_COMMANDS="$POPULATION_WORLD_READY|/lab start;/tp $POPULATION_ANCHOR_X $POPULATION_PLAYER_Y $POPULATION_ANCHOR_Z;/lab checkpoint load reproduction-midplan;/lab movement off;/lab replay start reproduction-midplan;/lab step;/lab step;/lab births status;/lab replay status;/lab kinship status"
        if [ "$MODE" = "households" ] || [ "$MODE" = "care" ]; then
            KINSHIP_FAILURE_COMMANDS="$KINSHIP_FAILURE_COMMANDS;/lab household status"
        fi
        if [ "$MODE" = "care" ]; then
            KINSHIP_FAILURE_COMMANDS="$KINSHIP_FAILURE_COMMANDS;/lab care status"
        fi
        KINSHIP_FAILURE_COMMANDS="$KINSHIP_FAILURE_COMMANDS;/lab status"
        printf '\nLineage late failure: valid birth candidate, newborn probe rollback, no publication.\n'
        if [ "$MODE" = "care" ]; then
            run_reproduction_app \
                "$FAILURE_HOME" "$FAILURE_TRACE" "$KINSHIP_FAILURE_COMMANDS" \
                0 "$continuation_command_tick" 0 1
        else
            run_reproduction_app \
                "$FAILURE_HOME" "$FAILURE_TRACE" "$KINSHIP_FAILURE_COMMANDS" \
                0 "$continuation_command_tick" 1
        fi
        TRACE_PATH="$FAILURE_TRACE"
        require_trace "checkpoint loaded name=reproduction-midplan .*tick=$REPRO_PLAN_TICK simulation=$MID_SIM digest=$MID_DIGEST .*restartSafe=1 probes=4 paused=1" 'late-failure checkpoint restore'
        if [ "$MODE" = "households" ] || [ "$MODE" = "care" ]; then
            require_trace "kinship late-failure candidate valid=1 tick=$REPRO_BIRTH_TICK newborn=agent_4 nextOrdinal=5 populationMembers=5 lifecycleMembers=5 kinshipPeople=5 parentages=1 households=[1-9][0-9]* memberships=5 careAssignments=[0-9]+ careNeeds=[0-9]+ causalSequence=[0-9]+ causalEvents=[0-9]+ recorderRecords=[1-9][0-9]* recorderBytes=[1-9][0-9]* probeCreated=1" 'fully valid unpublished household/care birth candidate'
            require_trace "kinship late-failure rollback sessionBytes=exact tick=$REPRO_PREBIRTH_TICK nextOrdinal=4 populationMembers=4 lifecycleMembers=4 kinshipPeople=4 parentages=0 households=[1-9][0-9]* memberships=4 careAssignments=[0-9]+ careNeeds=[0-9]+ causalSequence=[0-9]+ causalEvents=[0-9]+ recorderBytes=exact recorderRecords=[1-9][0-9]* probeMap=exact worldEntityIndexes=exact newbornAbsent=1" 'exact household/care session recorder and probe rollback'
        else
            require_trace "kinship late-failure candidate valid=1 tick=$REPRO_BIRTH_TICK newborn=agent_4 nextOrdinal=5 populationMembers=5 lifecycleMembers=5 kinshipPeople=5 parentages=1 households=0 memberships=0 careAssignments=0 careNeeds=0 causalSequence=[0-9]+ causalEvents=[0-9]+ recorderRecords=[1-9][0-9]* recorderBytes=[1-9][0-9]* probeCreated=1" 'fully valid unpublished kinship birth candidate'
            require_trace "kinship late-failure rollback sessionBytes=exact tick=$REPRO_PREBIRTH_TICK nextOrdinal=4 populationMembers=4 lifecycleMembers=4 kinshipPeople=4 parentages=0 households=0 memberships=0 careAssignments=0 careNeeds=0 causalSequence=[0-9]+ causalEvents=[0-9]+ recorderBytes=exact recorderRecords=[1-9][0-9]* probeMap=exact worldEntityIndexes=exact newbornAbsent=1" 'exact session recorder and probe rollback'
        fi
        require_trace_count '^\[lab-live\] kinship late-failure controlledError=kinshipLateFailureProof$' 1 'one controlled late-failure marker'
        require_trace_count '^\[lab-live\] error kinshipLateFailureProof$' 1 'one controlled expected late publication error'
        require_trace 'summary .*agents=4 .*runtimeErrors=1 .*probesRemoved=4 ' 'controlled error and clean four-probe shutdown'
        reject_trace 'birth finalized|worldMutation=(block|world)' 'published birth or World mutation during late-failure proof'
    fi

    REPRODUCTION_PHASE2_COMMANDS="$POPULATION_WORLD_READY|/lab start;/tp $POPULATION_ANCHOR_X $POPULATION_PLAYER_Y $POPULATION_ANCHOR_Z;/lab checkpoint load reproduction-midplan;/lab lifecycle status;/lab reproduction status;/lab step;/lab step;/lab births status;/lab lifecycle status;/lab population status;/lab ecology status;/lab settlement status;/lab checkpoint save reproduction-postbirth;/lab checkpoint status;/lab causality status;/lab status"
    if [ "$MODE" = "care" ]; then
        REPRODUCTION_PHASE2_COMMANDS="$REPRODUCTION_PHASE2_COMMANDS;/lab kinship status;/lab household status"
        BIRTH_FINALIZED_PATTERN="^\\[lab-live\\] birth finalized tick=$REPRO_BIRTH_TICK birth=birth-00000001 plan=$REPRO_PLAN_ID newborn=agent_4 ordinal=4 parents=agent_0,agent_1 position=.* stage=newborn age=0 kinship=1 kinshipParents=agent_0,agent_1 kinshipDigest=[0-9a-f]+ household=1 householdID=household_[0-9]+ householdDigest=[0-9a-f]+ care=1 caregiver=agent_0 careDigest=[0-9a-f]+ population=5 nextOrdinal=5 probes=agent_0,agent_1,agent_2,agent_3,agent_4 worldMutation=none$"
    elif [ "$MODE" = "households" ]; then
        REPRODUCTION_PHASE2_COMMANDS="$REPRODUCTION_PHASE2_COMMANDS;/lab kinship status;/lab household status"
        BIRTH_FINALIZED_PATTERN='^\[lab-live\] birth finalized tick=12 birth=birth-00000001 plan=reproduction-plan-00000010-agent_0-agent_1 newborn=agent_4 ordinal=4 parents=agent_0,agent_1 position=.* stage=newborn age=0 kinship=1 kinshipParents=agent_0,agent_1 kinshipDigest=[0-9a-f]+ household=1 householdID=household_[0-9]+ householdDigest=[0-9a-f]+ population=5 nextOrdinal=5 probes=agent_0,agent_1,agent_2,agent_3,agent_4 worldMutation=none$'
    elif [ "$MODE" = "kinship" ]; then
        REPRODUCTION_PHASE2_COMMANDS="$REPRODUCTION_PHASE2_COMMANDS;/lab kinship status"
        BIRTH_FINALIZED_PATTERN='^\[lab-live\] birth finalized tick=12 birth=birth-00000001 plan=reproduction-plan-00000010-agent_0-agent_1 newborn=agent_4 ordinal=4 parents=agent_0,agent_1 position=.* stage=newborn age=0 kinship=1 kinshipParents=agent_0,agent_1 kinshipDigest=[0-9a-f]+ population=5 nextOrdinal=5 probes=agent_0,agent_1,agent_2,agent_3,agent_4 worldMutation=none$'
    else
        BIRTH_FINALIZED_PATTERN='^\[lab-live\] birth finalized tick=12 birth=birth-00000001 plan=reproduction-plan-00000010-agent_0-agent_1 newborn=agent_4 ordinal=4 parents=agent_0,agent_1 position=.* stage=newborn age=0 population=5 nextOrdinal=5 probes=agent_0,agent_1,agent_2,agent_3,agent_4 worldMutation=none$'
    fi
    printf '\nReproduction phase 2: exact mid-plan restore and local birth.\n'
    run_reproduction_app "$SESSION_HOME" "$PHASE2_TRACE" "$REPRODUCTION_PHASE2_COMMANDS" 0 "$continuation_command_tick"
    TRACE_PATH="$PHASE2_TRACE"
    require_trace "checkpoint loaded name=reproduction-midplan .*tick=$REPRO_PLAN_TICK simulation=$MID_SIM digest=$MID_DIGEST .*restartSafe=1 probes=4 paused=1" 'exact mid-plan restore with four probes'
    require_trace_count "^\\[lab-live\\] birth site tick=$REPRO_BIRTH_TICK plan=$REPRO_PLAN_ID position=.* candidate=[0-9]+ valid=1 validCandidates=[1-9][0-9]* reads=[1-9][0-9]* fingerprint=[0-9-]+ mutation=none$" 1 'one real read-only birth site'
    require_trace_count "$BIRTH_FINALIZED_PATTERN" 1 'one exact local birth'
    require_trace_count '^\[lab-live\] birth finalized ' 1 'exactly one finalized birth in the restarted phase'
    require_trace "lifecycle tick=$REPRO_BIRTH_TICK enabled=1 reproduction=1 newborn=1 juvenile=0 mature=4 plans=0 plan=none due=-1 births=1 newbornID=agent_4 ages=.*agent_4:0/newborn nextOrdinal=5 probes=agent_0,agent_1,agent_2,agent_3,agent_4 " 'birth-tick lifecycle state'
    require_trace "checkpoint saved name=reproduction-postbirth .*tick=$REPRO_BIRTH_TICK .*restartSafe=1 " 'restart-safe post-birth checkpoint'
    require_trace 'summary .*agents=5 .*runtimeErrors=0 .*probesRemoved=5 ' 'clean post-birth five-probe cleanup'
    reject_trace 'runtime error|worldMutation=(block|world)' 'runtime error or World mutation'

    POST_MANIFEST=$(/usr/bin/find "$REPRODUCTION_ROOT" -type f -path '*/checkpoints/reproduction-postbirth/manifest.json' -print -quit)
    POST_SESSION=$(/usr/bin/find "$REPRODUCTION_ROOT" -type f -path '*/checkpoints/reproduction-postbirth/session.json' -print -quit)
    [ -n "$POST_MANIFEST" ] && [ -n "$POST_SESSION" ] \
        || fail "post-birth v$EXPECTED_REPRODUCTION_SCHEMA bundle missing"
    /usr/bin/grep -q "\"schemaVersion\":$EXPECTED_REPRODUCTION_SCHEMA" "$POST_SESSION" \
        || fail "post-birth session is not v$EXPECTED_REPRODUCTION_SCHEMA"
    [ "$(/usr/bin/plutil -extract durableState.lifecycleState.totalBirthCount raw -o - "$POST_SESSION")" = "1" ] \
        && [ "$(/usr/bin/plutil -extract durableState.populationRegistry.nextPopulationOrdinal raw -o - "$POST_SESSION")" = "5" ] \
        || fail "post-birth totals or ordinal are not exact"
    [ "$(/usr/bin/plutil -extract durableState.agents.4.agentID raw -o - "$POST_SESSION")" = "agent_4" ] \
        && [ "$(/usr/bin/plutil -extract durableState.agents.4.ticksAlive raw -o - "$POST_SESSION")" = "0" ] \
        && [ "$(/usr/bin/plutil -extract durableState.agents.4.observationCount raw -o - "$POST_SESSION")" = "0" ] \
        && [ "$(/usr/bin/plutil -extract durableState.agents.4.actionCount raw -o - "$POST_SESSION")" = "0" ] \
        && [ "$(/usr/bin/plutil -extract durableState.agents.4.movementCount raw -o - "$POST_SESSION")" = "0" ] \
        || fail "newborn acted or aged on the birth tick"
    [ "$(/usr/bin/plutil -extract durableState.agents.4.resourceInventory.totalCount raw -o - "$POST_SESSION" 2>/dev/null || printf 0)" = "0" ] \
        || fail "newborn inventory is not empty"
    site_sequence=$(/usr/bin/plutil -extract durableState.lifecycleState.births.0.siteValidatedEventID.sequence raw -o - "$POST_SESSION")
    born_sequence=$(/usr/bin/plutil -extract durableState.lifecycleState.births.0.populationBornEventID.sequence raw -o - "$POST_SESSION")
    finalized_sequence=$(/usr/bin/plutil -extract durableState.lifecycleState.births.0.finalizedEventID.sequence raw -o - "$POST_SESSION")
    if [ "$MODE" = "care" ]; then
        recorded_sequence=$(/usr/bin/plutil -extract durableState.kinshipState.parentageRecords.0.recordedEventID.sequence raw -o - "$POST_SESSION")
        membership_sequence=$(/usr/bin/plutil -extract durableState.householdState.membershipPeriods.4.joinedEventID.sequence raw -o - "$POST_SESSION")
        assignment_sequence=$(/usr/bin/plutil -extract durableState.dependentCareState.assignments.0.startedEventID.sequence raw -o - "$POST_SESSION")
        need_sequence=$(/usr/bin/plutil -extract durableState.dependentCareState.activeNeeds.0.raisedEventID.sequence raw -o - "$POST_SESSION")
        [ "$born_sequence" -eq $((site_sequence + 1)) ] \
            && [ "$recorded_sequence" -eq $((born_sequence + 1)) ] \
            && [ "$membership_sequence" -eq $((recorded_sequence + 1)) ] \
            && [ "$assignment_sequence" -eq $((membership_sequence + 1)) ] \
            && [ "$need_sequence" -eq $((assignment_sequence + 1)) ] \
            && [ "$finalized_sequence" -eq $((need_sequence + 1)) ] \
            || fail "care birth causal sequence is not exact"
        [ "$(/usr/bin/plutil -extract durableState.dependentCareState.totalAssignmentCount raw -o - "$POST_SESSION")" = "1" ] \
            && [ "$(/usr/bin/plutil -extract durableState.dependentCareState.assignments.0.dependentID raw -o - "$POST_SESSION")" = "agent_4" ] \
            && [ "$(/usr/bin/plutil -extract durableState.dependentCareState.assignments.0.caregiverID raw -o - "$POST_SESSION")" = "agent_0" ] \
            && [ "$(/usr/bin/plutil -extract durableState.dependentCareState.activeNeeds.0.kind raw -o - "$POST_SESSION")" = "supervision" ] \
            || fail "post-birth care assignment is not exact"
    elif [ "$MODE" = "households" ]; then
        recorded_sequence=$(/usr/bin/plutil -extract durableState.kinshipState.parentageRecords.0.recordedEventID.sequence raw -o - "$POST_SESSION")
        household_created_sequence=$(/usr/bin/plutil -extract durableState.householdState.households.4.createdEventID.sequence raw -o - "$POST_SESSION")
        membership_sequence=$(/usr/bin/plutil -extract durableState.householdState.membershipPeriods.4.joinedEventID.sequence raw -o - "$POST_SESSION")
        [ "$born_sequence" -eq $((site_sequence + 1)) ] \
            && [ "$recorded_sequence" -eq $((born_sequence + 1)) ] \
            && [ "$household_created_sequence" -eq $((recorded_sequence + 1)) ] \
            && [ "$membership_sequence" -eq $((household_created_sequence + 1)) ] \
            && [ "$finalized_sequence" -eq $((membership_sequence + 1)) ] \
            || fail "household birth causal sequence is not exact"
        [ "$(/usr/bin/plutil -extract durableState.kinshipState.totalHistoricalPersonCount raw -o - "$POST_SESSION")" = "5" ] \
            && [ "$(/usr/bin/plutil -extract durableState.kinshipState.totalParentageRecordCount raw -o - "$POST_SESSION")" = "1" ] \
            && [ "$(/usr/bin/plutil -extract durableState.householdState.membershipPeriods.4.agentID raw -o - "$POST_SESSION")" = "agent_4" ] \
            && [ "$(/usr/bin/plutil -extract durableState.householdState.membershipPeriods.4.joinedReason raw -o - "$POST_SESSION")" = "birth" ] \
            && [ "$(/usr/bin/plutil -extract durableState.householdState.membershipPeriods.4.leftTick raw -o - "$POST_SESSION" 2>/dev/null || printf absent)" = "absent" ] \
            || fail "post-birth household membership is not exact"
    elif [ "$MODE" = "kinship" ]; then
        recorded_sequence=$(/usr/bin/plutil -extract durableState.kinshipState.parentageRecords.0.recordedEventID.sequence raw -o - "$POST_SESSION")
        [ "$born_sequence" -eq $((site_sequence + 1)) ] \
            && [ "$recorded_sequence" -eq $((born_sequence + 1)) ] \
            && [ "$finalized_sequence" -eq $((recorded_sequence + 1)) ] \
            || fail "kinship birth causal sequence is not exact"
        [ "$(/usr/bin/plutil -extract durableState.kinshipState.totalHistoricalPersonCount raw -o - "$POST_SESSION")" = "5" ] \
            && [ "$(/usr/bin/plutil -extract durableState.kinshipState.totalParentageRecordCount raw -o - "$POST_SESSION")" = "1" ] \
            && [ "$(/usr/bin/plutil -extract durableState.kinshipState.parentageRecords.0.childID raw -o - "$POST_SESSION")" = "agent_4" ] \
            && [ "$(/usr/bin/plutil -extract durableState.kinshipState.parentageRecords.0.canonicalParentIDs.0 raw -o - "$POST_SESSION")" = "agent_0" ] \
            && [ "$(/usr/bin/plutil -extract durableState.kinshipState.parentageRecords.0.canonicalParentIDs.1 raw -o - "$POST_SESSION")" = "agent_1" ] \
            || fail "post-birth kinship parentage is not exact"
    else
        [ "$born_sequence" -eq $((site_sequence + 1)) ] \
            && [ "$finalized_sequence" -eq $((born_sequence + 1)) ] \
            || fail "birth causal sequence is not exact"
    fi
    POST_DIGEST=$(/usr/bin/sed -n 's/.*checkpoint saved name=reproduction-postbirth .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' "$PHASE2_TRACE" | /usr/bin/tail -1)
    [ -n "$POST_DIGEST" ] || fail "post-birth digest extraction failed"

    persisted_world_tick=$(/usr/bin/sqlite3 "$DB_PATH" "SELECT json_extract(json, '$.dims.\"0\".time') FROM worlds;")
    case "$persisted_world_tick" in
        ''|*[!0-9]*) fail "invalid persisted World tick after reproduction phase 2: $persisted_world_tick" ;;
    esac
    continuation_command_tick=$((persisted_world_tick + 100))
    REPRODUCTION_PHASE3_COMMANDS="$POPULATION_WORLD_READY|/lab start;/tp $POPULATION_ANCHOR_X $POPULATION_PLAYER_Y $POPULATION_ANCHOR_Z;/lab checkpoint load reproduction-postbirth"
    reproduction_step=0
    if [ "$MODE" = "care" ]; then
        REPRODUCTION_PHASE3_COMMANDS="$REPRODUCTION_PHASE3_COMMANDS;/lab physical-food-survival on"
        while [ "$reproduction_step" -lt 4 ]; do
            REPRODUCTION_PHASE3_COMMANDS="$REPRODUCTION_PHASE3_COMMANDS;/lab step"
            reproduction_step=$((reproduction_step + 1))
        done
        REPRODUCTION_PHASE3_COMMANDS="$REPRODUCTION_PHASE3_COMMANDS;/lab care proof physical-food-setup"
    fi
    while [ "$reproduction_step" -lt 8 ]; do
        REPRODUCTION_PHASE3_COMMANDS="$REPRODUCTION_PHASE3_COMMANDS;/lab step"
        reproduction_step=$((reproduction_step + 1))
    done
    REPRODUCTION_PHASE3_COMMANDS="$REPRODUCTION_PHASE3_COMMANDS;/lab lifecycle status;/lab reproduction status;/lab births status;/lab population status;/lab ecology status;/lab settlement status;/lab checkpoint save reproduction-final;/lab checkpoint status;/lab causality status;/lab status"
    if [ "$MODE" = "care" ]; then
        REPRODUCTION_PHASE3_COMMANDS="$REPRODUCTION_PHASE3_COMMANDS;/lab kinship status;/lab household status;/lab care status"
    elif [ "$MODE" = "households" ]; then
        REPRODUCTION_PHASE3_COMMANDS="$REPRODUCTION_PHASE3_COMMANDS;/lab kinship status;/lab household status"
    elif [ "$MODE" = "kinship" ]; then
        REPRODUCTION_PHASE3_COMMANDS="$REPRODUCTION_PHASE3_COMMANDS;/lab kinship status"
    fi

    REPRODUCTION_CONTROL_COMMANDS="$REPRODUCTION_BOOTSTRAP_COMMANDS"
    reproduction_step=0
    reproduction_control_steps=13
    if [ "$MODE" = "care" ]; then
        reproduction_control_steps=11
        while [ "$reproduction_step" -lt 3 ]; do
            REPRODUCTION_CONTROL_COMMANDS="$REPRODUCTION_CONTROL_COMMANDS;/lab step"
            reproduction_step=$((reproduction_step + 1))
        done
        REPRODUCTION_CONTROL_COMMANDS="$REPRODUCTION_CONTROL_COMMANDS;/lab physical-food-survival on"
        while [ "$reproduction_step" -lt 7 ]; do
            REPRODUCTION_CONTROL_COMMANDS="$REPRODUCTION_CONTROL_COMMANDS;/lab step"
            reproduction_step=$((reproduction_step + 1))
        done
        REPRODUCTION_CONTROL_COMMANDS="$REPRODUCTION_CONTROL_COMMANDS;/lab care proof physical-food-setup"
    fi
    while [ "$reproduction_step" -lt "$reproduction_control_steps" ]; do
        REPRODUCTION_CONTROL_COMMANDS="$REPRODUCTION_CONTROL_COMMANDS;/lab step"
        reproduction_step=$((reproduction_step + 1))
    done
    REPRODUCTION_CONTROL_COMMANDS="$REPRODUCTION_CONTROL_COMMANDS;/lab lifecycle status;/lab reproduction status;/lab births status;/lab population status;/lab ecology status;/lab settlement status;/lab checkpoint save reproduction-final-control;/lab checkpoint status;/lab causality status;/lab status"
    if [ "$MODE" = "care" ]; then
        REPRODUCTION_CONTROL_COMMANDS="$REPRODUCTION_CONTROL_COMMANDS;/lab kinship status;/lab household status;/lab care status"
    elif [ "$MODE" = "households" ]; then
        REPRODUCTION_CONTROL_COMMANDS="$REPRODUCTION_CONTROL_COMMANDS;/lab kinship status;/lab household status"
    elif [ "$MODE" = "kinship" ]; then
        REPRODUCTION_CONTROL_COMMANDS="$REPRODUCTION_CONTROL_COMMANDS;/lab kinship status"
    fi

    printf '\nReproduction phase 3: post-birth restore through exact maturity.\n'
    run_reproduction_app "$SESSION_HOME" "$PHASE3_TRACE" "$REPRODUCTION_PHASE3_COMMANDS" 0 "$continuation_command_tick"
    TRACE_PATH="$PHASE3_TRACE"
    require_trace "checkpoint loaded name=reproduction-postbirth .*tick=$REPRO_BIRTH_TICK simulation=$MID_SIM digest=$POST_DIGEST .*restartSafe=1 probes=5 paused=1" 'exact post-birth restore with five probes'
    require_trace "lifecycle tick=$REPRO_JUVENILE_TICK enabled=1 reproduction=1 newborn=0 juvenile=1 mature=4 .*births=1 newbornID=agent_4 ages=.*agent_4:2/juvenile " 'exact juvenile threshold'
    require_trace "lifecycle tick=$REPRO_FINAL_TICK enabled=1 reproduction=1 newborn=0 juvenile=0 mature=5 plans=0 plan=none due=-1 births=1 newbornID=agent_4 ages=.*agent_4:8/mature nextOrdinal=5 probes=agent_0,agent_1,agent_2,agent_3,agent_4 " 'exact mature threshold'
    require_trace "checkpoint saved name=reproduction-final .*tick=$REPRO_FINAL_TICK .*restartSafe=1 " "final v$EXPECTED_REPRODUCTION_SCHEMA checkpoint"
    require_trace 'summary .*agents=5 .*runtimeErrors=0 .*probesRemoved=5 ' 'clean final five-probe cleanup'
    reject_trace 'birth finalized|runtime error|worldMutation=(block|world)' 'duplicate birth, runtime error, or World mutation after restore'
    if [ "$MODE" = "care" ]; then
        require_trace 'care physical shadow audit tick=22 caregiver=agent_0 dependent=agent_4 foodRawShadow=[1-9][0-9]* realFood=none physicalDebit=0 hungerRescue=0 historyDelta=0' 'abstract shadow food cannot nourish a live dependent in physical mode'
        require_trace 'care physical food setup tick=22 caregiver=agent_0 dependent=agent_4 material=sweet_berries slot=[0-9]+ count=1 custody=real approachSteps=[1-9][0-9]* movement=CorePath\+Entity.move bootstrap=bounded' 'bounded real-food care fixture after real physical approach'
        require_trace 'care physical nourishment tick=2[3-5] caregiver=agent_0 dependent=agent_4 material=sweet_berries slot=[0-9]+ physicalCount=1>0 physicalDebit=1 hunger=0\.[0-9]+>0\.[0-9]+ foodRawGhostDelta=0 receipt=physical-care:[A-Za-z0-9_.:-]+' 'exact physical dependent nourishment after real caregiver approach'
        require_trace "care tick=$REPRO_FINAL_TICK enabled=1 assignments=0 needs=0 engagements=0 atRisk= digest=[0-9a-f]+ worldMutation=none" 'care lifecycle closes cleanly at maturity'
    fi

    printf '\nReproduction uninterrupted control.\n'
    run_reproduction_app "$CONTROL_HOME" "$CONTROL_TRACE" "$REPRODUCTION_CONTROL_COMMANDS" 0 "$continuation_command_tick"
    TRACE_PATH="$CONTROL_TRACE"
    require_trace_count "$BIRTH_FINALIZED_PATTERN" 1 'one uninterrupted local birth'
    require_trace_count '^\[lab-live\] birth finalized ' 1 'exactly one finalized birth without restart'
    require_trace "lifecycle tick=$REPRO_FINAL_TICK enabled=1 reproduction=1 newborn=0 juvenile=0 mature=5 plans=0 .*births=1 newbornID=agent_4 ages=.*agent_4:8/mature " 'uninterrupted exact maturity'
    require_trace 'summary .*agents=5 .*runtimeErrors=0 .*probesRemoved=5 ' 'clean uninterrupted cleanup'
    reject_trace 'runtime error|worldMutation=(block|world)' 'uninterrupted runtime error or World mutation'

    LIVE_DIGEST=$(/usr/bin/sed -n 's/.*checkpoint saved name=reproduction-final .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' "$PHASE3_TRACE" | /usr/bin/tail -1)
    CONTROL_DIGEST=$(/usr/bin/sed -n 's/.*checkpoint saved name=reproduction-final-control .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' "$CONTROL_TRACE" | /usr/bin/tail -1)
    LIVE_LIFECYCLE_DIGEST=$(/usr/bin/sed -n "s/.*lifecycle tick=$REPRO_FINAL_TICK .* digest=\\([0-9a-f]*\\)$/\\1/p" "$PHASE3_TRACE" | /usr/bin/tail -1)
    CONTROL_LIFECYCLE_DIGEST=$(/usr/bin/sed -n "s/.*lifecycle tick=$REPRO_FINAL_TICK .* digest=\\([0-9a-f]*\\)$/\\1/p" "$CONTROL_TRACE" | /usr/bin/tail -1)
    LIVE_POPULATION_DIGEST=$(/usr/bin/sed -n 's/.*population gate=enabled .* digest=\([0-9a-f]*\)$/\1/p' "$PHASE3_TRACE" | /usr/bin/tail -1)
    CONTROL_POPULATION_DIGEST=$(/usr/bin/sed -n 's/.*population gate=enabled .* digest=\([0-9a-f]*\)$/\1/p' "$CONTROL_TRACE" | /usr/bin/tail -1)
    LIVE_ECOLOGY_DIGEST=$(/usr/bin/sed -n 's/.*ecology gate=enabled .* digest=\([0-9a-f]*\) ecologyConservation=.*/\1/p' "$PHASE3_TRACE" | /usr/bin/tail -1)
    CONTROL_ECOLOGY_DIGEST=$(/usr/bin/sed -n 's/.*ecology gate=enabled .* digest=\([0-9a-f]*\) ecologyConservation=.*/\1/p' "$CONTROL_TRACE" | /usr/bin/tail -1)
    LIVE_SETTLEMENT_DIGEST=$(/usr/bin/sed -n 's/.*settlement gate=enabled .* digest=\([0-9a-f]*\)$/\1/p' "$PHASE3_TRACE" | /usr/bin/tail -1)
    CONTROL_SETTLEMENT_DIGEST=$(/usr/bin/sed -n 's/.*settlement gate=enabled .* digest=\([0-9a-f]*\)$/\1/p' "$CONTROL_TRACE" | /usr/bin/tail -1)
    LIVE_CAUSAL_DIGEST=$(/usr/bin/sed -n 's/.*causality status .* digest=\([0-9a-f]*\)$/\1/p' "$PHASE3_TRACE" | /usr/bin/tail -1)
    CONTROL_CAUSAL_DIGEST=$(/usr/bin/sed -n 's/.*causality status .* digest=\([0-9a-f]*\)$/\1/p' "$CONTROL_TRACE" | /usr/bin/tail -1)
    if [ "$MODE" = "kinship" ] || [ "$MODE" = "households" ] || [ "$MODE" = "care" ]; then
        LIVE_KINSHIP_DIGEST=$(/usr/bin/sed -n "s/.*kinship tick=$REPRO_FINAL_TICK .* digest=\\([0-9a-f]*\\) worldMutation=none$/\\1/p" "$PHASE3_TRACE" | /usr/bin/tail -1)
        CONTROL_KINSHIP_DIGEST=$(/usr/bin/sed -n "s/.*kinship tick=$REPRO_FINAL_TICK .* digest=\\([0-9a-f]*\\) worldMutation=none$/\\1/p" "$CONTROL_TRACE" | /usr/bin/tail -1)
    fi
    if [ "$MODE" = "households" ] || [ "$MODE" = "care" ]; then
        LIVE_HOUSEHOLD_DIGEST=$(/usr/bin/sed -n "s/.*household tick=$REPRO_FINAL_TICK .* digest=\\([0-9a-f]*\\) worldMutation=none$/\\1/p" "$PHASE3_TRACE" | /usr/bin/tail -1)
        CONTROL_HOUSEHOLD_DIGEST=$(/usr/bin/sed -n "s/.*household tick=$REPRO_FINAL_TICK .* digest=\\([0-9a-f]*\\) worldMutation=none$/\\1/p" "$CONTROL_TRACE" | /usr/bin/tail -1)
    fi
    if [ "$MODE" = "care" ]; then
        LIVE_CARE_DIGEST=$(/usr/bin/sed -n "s/.*care tick=$REPRO_FINAL_TICK .* digest=\\([0-9a-f]*\\) worldMutation=none$/\\1/p" "$PHASE3_TRACE" | /usr/bin/tail -1)
        CONTROL_CARE_DIGEST=$(/usr/bin/sed -n "s/.*care tick=$REPRO_FINAL_TICK .* digest=\\([0-9a-f]*\\) worldMutation=none$/\\1/p" "$CONTROL_TRACE" | /usr/bin/tail -1)
    fi
    [ -n "$LIVE_DIGEST" ] && [ "$LIVE_DIGEST" = "$CONTROL_DIGEST" ] \
        || fail "reproduction restart/uninterrupted durable digest mismatch"
    [ "$LIVE_LIFECYCLE_DIGEST" = "$CONTROL_LIFECYCLE_DIGEST" ] \
        || fail "reproduction restart/uninterrupted lifecycle digest mismatch"
    [ "$LIVE_POPULATION_DIGEST" = "$CONTROL_POPULATION_DIGEST" ] \
        || fail "reproduction restart/uninterrupted population digest mismatch"
    [ "$LIVE_ECOLOGY_DIGEST" = "$CONTROL_ECOLOGY_DIGEST" ] \
        || fail "reproduction restart/uninterrupted ecology digest mismatch"
    [ "$LIVE_SETTLEMENT_DIGEST" = "$CONTROL_SETTLEMENT_DIGEST" ] \
        || fail "reproduction restart/uninterrupted settlement digest mismatch"
    [ "$LIVE_CAUSAL_DIGEST" = "$CONTROL_CAUSAL_DIGEST" ] \
        || fail "reproduction restart/uninterrupted causal digest mismatch"
    if [ "$MODE" = "kinship" ] || [ "$MODE" = "households" ] || [ "$MODE" = "care" ]; then
        [ -n "$LIVE_KINSHIP_DIGEST" ] \
            && [ "$LIVE_KINSHIP_DIGEST" = "$CONTROL_KINSHIP_DIGEST" ] \
            || fail "kinship restart/uninterrupted digest mismatch"
    fi
    if [ "$MODE" = "households" ] || [ "$MODE" = "care" ]; then
        [ -n "$LIVE_HOUSEHOLD_DIGEST" ] \
            && [ "$LIVE_HOUSEHOLD_DIGEST" = "$CONTROL_HOUSEHOLD_DIGEST" ] \
            || fail "household restart/uninterrupted digest mismatch"
    fi
    if [ "$MODE" = "care" ]; then
        [ -n "$LIVE_CARE_DIGEST" ] && [ "$LIVE_CARE_DIGEST" = "$CONTROL_CARE_DIGEST" ] \
            || fail "care restart/uninterrupted digest mismatch"
    fi

    if [ "$MODE" = "care" ]; then
        REPRO_TRACE_TICKS='(17|1[89]|2[0-6])'
    else
        REPRO_TRACE_TICKS='(11|1[2-9]|20)'
    fi
    /bin/cat "$PHASE2_TRACE" "$PHASE3_TRACE" \
        | /usr/bin/grep -E "^\\[lab-live\\] (tick=$REPRO_TRACE_TICKS |lifecycle tick=$REPRO_TRACE_TICKS |care (tick=|nourishment tick=)$REPRO_TRACE_TICKS |birth (site|finalized) tick=$REPRO_BIRTH_TICK )" \
        > "$SESSION_ROOT/restart-reproduction.normalized"
    /usr/bin/grep -E "^\\[lab-live\\] (tick=$REPRO_TRACE_TICKS |lifecycle tick=$REPRO_TRACE_TICKS |care (tick=|nourishment tick=)$REPRO_TRACE_TICKS |birth (site|finalized) tick=$REPRO_BIRTH_TICK )" "$CONTROL_TRACE" \
        > "$SESSION_ROOT/control-reproduction.normalized"
    /usr/bin/cmp "$SESSION_ROOT/restart-reproduction.normalized" "$SESSION_ROOT/control-reproduction.normalized" \
        || fail "reproduction restart and uninterrupted traces differ"

    FINAL_SESSION=$(/usr/bin/find "$REPRODUCTION_ROOT" -type f -path '*/checkpoints/reproduction-final/session.json' -print -quit)
    [ -n "$FINAL_SESSION" ] || fail "final reproduction checkpoint missing"
    [ "$(/usr/bin/plutil -extract durableState.lifecycleState.totalBirthCount raw -o - "$FINAL_SESSION")" = "1" ] \
        && [ "$(/usr/bin/plutil -extract durableState.lifecycleState.members.4.currentStage raw -o - "$FINAL_SESSION")" = "mature" ] \
        && [ "$(/usr/bin/plutil -extract durableState.populationRegistry.nextPopulationOrdinal raw -o - "$FINAL_SESSION")" = "5" ] \
        || fail "final birth, maturity, or ordinal changed"
    if [ "$MODE" = "kinship" ] || [ "$MODE" = "households" ] || [ "$MODE" = "care" ]; then
        [ "$(/usr/bin/plutil -extract durableState.kinshipState.totalHistoricalPersonCount raw -o - "$FINAL_SESSION")" = "5" ] \
            && [ "$(/usr/bin/plutil -extract durableState.kinshipState.totalParentageRecordCount raw -o - "$FINAL_SESSION")" = "1" ] \
            || fail "final kinship graph changed after restart"
    fi
    if [ "$MODE" = "households" ] || [ "$MODE" = "care" ]; then
        [ "$(/usr/bin/plutil -extract durableState.householdState.membershipPeriods.4.agentID raw -o - "$FINAL_SESSION")" = "agent_4" ] \
            && [ "$(/usr/bin/plutil -extract durableState.householdState.membershipPeriods.4.joinedReason raw -o - "$FINAL_SESSION")" = "birth" ] \
            && [ "$(/usr/bin/plutil -extract durableState.householdState.totalMembershipPeriodCount raw -o - "$FINAL_SESSION")" = "5" ] \
            || fail "final household membership changed after restart"
    fi
    if [ "$MODE" = "care" ]; then
        [ "$(/usr/bin/plutil -extract durableState.dependentCareState.assignments.0.status raw -o - "$FINAL_SESSION")" = "ended" ] \
            && [ "$(/usr/bin/plutil -extract durableState.dependentCareState.activeNeeds json -o - "$FINAL_SESSION")" = "[]" ] \
            && [ "$(/usr/bin/plutil -extract durableState.dependentCareState.terminalOutcomes.0.foodSource raw -o - "$FINAL_SESSION")" = "physicalCaregiverInventory" ] \
            && [ "$(/usr/bin/plutil -extract durableState.dependentCareState.terminalOutcomes.0.materialQuantity raw -o - "$FINAL_SESSION")" = "1" ] \
            && [ "$(/usr/bin/plutil -extract durableState.consumedResourceTotals.foodRawCount raw -o - "$FINAL_SESSION")" = "0" ] \
            || fail "final physical care closure, provenance, or ghost material count is not exact"
    fi
    stage_event_count=$(/usr/bin/plutil -extract durableState.causalLedger.events json -o - "$FINAL_SESSION" \
        | /usr/bin/grep -o '"kind":"lifeStageChanged"' | /usr/bin/wc -l | /usr/bin/tr -d ' ')
    [ "$stage_event_count" = "2" ] || fail "expected exactly two lifecycle stage events, got $stage_event_count"
    mature_stage_sequence=$(/usr/bin/plutil -extract \
        durableState.lifecycleState.members.4.lastLifecycleEventID.sequence raw -o - "$FINAL_SESSION")
    mature_stage_index=$((mature_stage_sequence - 1))
    [ "$(/usr/bin/plutil -extract \
        "durableState.causalLedger.events.$mature_stage_index.kind" raw -o - "$FINAL_SESSION")" \
        = "lifeStageChanged" ] || fail "expected terminal lifecycle event to be mature stage change"
    juvenile_stage_sequence=$(/usr/bin/plutil -extract \
        "durableState.causalLedger.events.$mature_stage_index.causes.0.sequence" raw -o - "$FINAL_SESSION")
    juvenile_stage_index=$((juvenile_stage_sequence - 1))
    [ "$(/usr/bin/plutil -extract \
        "durableState.causalLedger.events.$juvenile_stage_index.kind" raw -o - "$FINAL_SESSION")" \
        = "lifeStageChanged" ] || fail "expected mature stage cause to be juvenile stage change"
    stage_event_ticks=$(printf '%s\n%s' \
        "$(/usr/bin/plutil -extract \
            "durableState.causalLedger.events.$juvenile_stage_index.instant.tick" raw -o - "$FINAL_SESSION")" \
        "$(/usr/bin/plutil -extract \
            "durableState.causalLedger.events.$mature_stage_index.instant.tick" raw -o - "$FINAL_SESSION")")
    expected_stage_event_ticks=$(printf '%s\n%s' "$REPRO_JUVENILE_TICK" "$REPRO_FINAL_TICK")
    [ "$stage_event_ticks" = "$expected_stage_event_ticks" ] \
        || fail "expected lifecycle stage causal ticks $REPRO_JUVENILE_TICK and $REPRO_FINAL_TICK, got: $stage_event_ticks"
    if /usr/bin/pgrep -f '[/]PebbleLab-live\.' >/dev/null 2>&1; then
        fail "residual PebbleLab process after reproduction proof"
    fi
    printf '\nPASS: deterministic lifecycle age, one bounded local birth, v%s pre/post restart, exact maturity, and uninterrupted equivalence verified.\n' "$EXPECTED_REPRODUCTION_SCHEMA"
    printf 'Phase 1 trace: %s\n' "$PHASE1_TRACE"
    printf 'Phase 2 trace: %s\n' "$PHASE2_TRACE"
    printf 'Phase 3 trace: %s\n' "$PHASE3_TRACE"
    printf 'Control trace: %s\n' "$CONTROL_TRACE"
    printf 'Final durable digest: %s\n' "$LIVE_DIGEST"
    printf 'Lifecycle digest: %s\n' "$LIVE_LIFECYCLE_DIGEST"
    printf 'Population digest: %s\n' "$LIVE_POPULATION_DIGEST"
    printf 'Ecology digest: %s\n' "$LIVE_ECOLOGY_DIGEST"
    printf 'Settlement digest: %s\n' "$LIVE_SETTLEMENT_DIGEST"
    printf 'Causal digest: %s\n' "$LIVE_CAUSAL_DIGEST"
    if [ "$MODE" = "kinship" ] || [ "$MODE" = "households" ] || [ "$MODE" = "care" ]; then
        printf 'Kinship digest: %s\n' "$LIVE_KINSHIP_DIGEST"
        printf 'Kinship World boundary: PebbleAgents has no World access; no block/world mutation trace observed.\n'
        printf 'Kinship late-failure trace: %s\n' "$FAILURE_TRACE"
    fi
    if [ "$MODE" = "households" ] || [ "$MODE" = "care" ]; then
        printf 'Household digest: %s\n' "$LIVE_HOUSEHOLD_DIGEST"
        printf 'Household World boundary: PebbleAgents has no World access; no block/world mutation trace observed.\n'
    fi
    if [ "$MODE" = "care" ]; then
        printf 'Care digest: %s\n' "$LIVE_CARE_DIGEST"
        printf 'Care food equation: sourceBefore=sourceAfter+consumed; consumedResourceTotals.foodRaw>=1.\n'
        printf 'Care World boundary: PebbleAgents has no World access; no block/world mutation trace observed.\n'
    fi
    printf 'Retained isolated session: %s\n' "$SESSION_ROOT"
    exit 0
fi

if [ "$MODE" = "mortality" ]; then
    cd "$ROOT_DIR"
    swift build -c release --product Pebble
    PEBBLE_BINARY="$ROOT_DIR/.build/release/Pebble"
    [ -x "$PEBBLE_BINARY" ] || fail "Release Pebble binary missing: $PEBBLE_BINARY"

    PHASE1_TRACE="$SESSION_ROOT/mortality-phase1.log"
    PHASE2_TRACE="$SESSION_ROOT/mortality-phase2.log"
    PHASE3_TRACE="$SESSION_ROOT/mortality-phase3.log"
    CONTROL_HOME="$SESSION_ROOT/control-home"
    CONTROL_TRACE="$SESSION_ROOT/mortality-control.log"
    [ ! -e "$CONTROL_HOME" ] || fail "fresh mortality control home already exists: $CONTROL_HOME"

    run_mortality_app() {
        run_home=$1
        run_trace=$2
        run_commands=$3
        create_world=$4
        command_world_tick=$5
        if [ "$create_world" -eq 1 ]; then
            CFFIXED_USER_HOME="$run_home" \
            PEBBLE_AUTOLOAD=1 \
            PEBBLE_NEWWORLD="$WORLD_SEED" \
            PEBBLE_NEWWORLD_NAME="$WORLD_NAME" \
            PEBBLELAB_APP_AGENTS=1 \
            PEBBLELAB_APP_AGENTS_MOVE=1 \
            PEBBLELAB_APP_PROBES=1 \
            PEBBLELAB_DEBUG_ENTITIES=1 \
            PEBBLELAB_APP_AGENTS_OVERLAY=1 \
            PEBBLELAB_APP_AGENTS_TRACE=1 \
            PEBBLELAB_APP_AGENTS_TRACE_EVERY=1 \
            PEBBLELAB_APP_AGENTS_INTERACT=1 \
            PEBBLELAB_APP_AGENTS_NATURAL=0 \
            PEBBLELAB_APP_AGENTS_BUILD=0 \
            PEBBLELAB_APP_AGENTS_SOCIAL=0 \
            PEBBLELAB_APP_AGENTS_PHYSICAL=0 \
            PEBBLELAB_APP_AGENTS_COOPERATION=0 \
            PEBBLELAB_APP_AGENTS_PERSISTENCE=1 \
            PEBBLELAB_APP_AGENTS_POPULATION=1 \
            PEBBLELAB_APP_AGENTS_MULTISCALE=1 \
            PEBBLELAB_APP_AGENTS_ECOLOGY=1 \
            PEBBLELAB_APP_AGENTS_MORTALITY=1 \
            PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
            PEBBLE_CMD_WORLD_TICK="$command_world_tick" \
            PEBBLE_CMD="$run_commands" \
            PEBBLE_SHOT='-|-|-|-|-' \
            "$PEBBLE_BINARY" 2>&1 | /usr/bin/tee "$run_trace"
        else
            CFFIXED_USER_HOME="$run_home" \
            PEBBLE_AUTOLOAD=1 \
            PEBBLELAB_APP_AGENTS=1 \
            PEBBLELAB_APP_AGENTS_MOVE=1 \
            PEBBLELAB_APP_PROBES=1 \
            PEBBLELAB_DEBUG_ENTITIES=1 \
            PEBBLELAB_APP_AGENTS_OVERLAY=1 \
            PEBBLELAB_APP_AGENTS_TRACE=1 \
            PEBBLELAB_APP_AGENTS_TRACE_EVERY=1 \
            PEBBLELAB_APP_AGENTS_INTERACT=1 \
            PEBBLELAB_APP_AGENTS_NATURAL=0 \
            PEBBLELAB_APP_AGENTS_BUILD=0 \
            PEBBLELAB_APP_AGENTS_SOCIAL=0 \
            PEBBLELAB_APP_AGENTS_PHYSICAL=0 \
            PEBBLELAB_APP_AGENTS_COOPERATION=0 \
            PEBBLELAB_APP_AGENTS_PERSISTENCE=1 \
            PEBBLELAB_APP_AGENTS_POPULATION=1 \
            PEBBLELAB_APP_AGENTS_MULTISCALE=1 \
            PEBBLELAB_APP_AGENTS_ECOLOGY=1 \
            PEBBLELAB_APP_AGENTS_MORTALITY=1 \
            PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
            PEBBLE_CMD_WORLD_TICK="$command_world_tick" \
            PEBBLE_CMD="$run_commands" \
            PEBBLE_SHOT='-|-|-|-|-' \
            "$PEBBLE_BINARY" 2>&1 | /usr/bin/tee "$run_trace"
        fi
        if /usr/bin/pgrep -x Pebble >/dev/null 2>&1; then
            fail "Pebble process remained after mortality phase: $run_trace"
        fi
    }

    printf '\nMortality phase 1: four residents and restart-safe pre-lethal v5 checkpoint.\n'
    run_mortality_app "$SESSION_HOME" "$PHASE1_TRACE" "$MORTALITY_PHASE1_COMMANDS" 1 100
    TRACE_PATH="$PHASE1_TRACE"
    require_trace 'start seed=46 agents=3 tick=0 ' 'historical three-agent bootstrap'
    require_trace '^\[pebblelab-proof\] disposable-world gate=armed$' 'explicit disposable-world focus policy'
    require_trace 'mortality enabled tick=0 active=3 deaths=0 terminal=0 mutation=none' 'mortality enabled without direct death'
    require_trace 'migration id=migration-00000003 migrant=agent_3 .*status=arrived ' 'physical agent_3 arrival'
    require_trace 'population gate=enabled enabled=1 settlement=settlement-main capacity=8 members=4 founders=3 residents=4 migrating=0 nextOrdinal=4 ' 'four active residents before mortality'
    require_trace 'mortality gate=enabled active=yes agents=4 deaths=0 retained=0 evicted=0 latest=none victim=none tick=-1 terminal=0 members=4 nextOrdinal=4 probes=4 ' 'pre-lethal mortality state'
    require_trace 'checkpoint saved name=mortality-preexit .*tick=26 .*restartSafe=1 ' 'restart-safe pre-lethal checkpoint'
    require_trace 'summary .*agents=4 .*runtimeErrors=0 .*probesRemoved=4 ' 'clean pre-lethal four-probe cleanup'
    reject_trace 'mortality exit|agent death finalized|runtime error|health=0' 'premature death or runtime error'

    MORTALITY_ROOT="$SESSION_HOME/Library/Application Support/Pebble/PebbleLabAgents"
    PRE_MANIFEST=$(/usr/bin/find "$MORTALITY_ROOT" -type f -path '*/checkpoints/mortality-preexit/manifest.json' -print -quit)
    PRE_SESSION=$(/usr/bin/find "$MORTALITY_ROOT" -type f -path '*/checkpoints/mortality-preexit/session.json' -print -quit)
    [ -n "$PRE_MANIFEST" ] && [ -n "$PRE_SESSION" ] || fail "mortality pre-exit bundle missing"
    /usr/bin/grep -q '"schemaVersion":5' "$PRE_MANIFEST" || fail "pre-exit manifest is not schema v5"
    /usr/bin/grep -q '"schemaVersion":5' "$PRE_SESSION" || fail "pre-exit session is not schema v5"
    /usr/bin/grep -q '"restartSafe":true' "$PRE_MANIFEST" || fail "pre-exit checkpoint is not restart-safe"
    [ "$(/usr/bin/plutil -extract durableState.agents.2.agentID raw -o - "$PRE_SESSION")" = "agent_2" ] \
        || fail "agent_2 is not the canonical mortality victim"
    [ "$(/usr/bin/plutil -extract durableState.agents.2.health raw -o - "$PRE_SESSION")" = "10" ] \
        || fail "agent_2 pre-lethal health is not 10"
    [ "$(/usr/bin/plutil -extract durableState.agents.2.needs.hunger raw -o - "$PRE_SESSION")" = "1" ] \
        || fail "agent_2 pre-lethal hunger is not critical"
    [ "$(/usr/bin/plutil -extract durableState.mortalityState.totalDeathCount raw -o - "$PRE_SESSION")" = "0" ] \
        || fail "pre-lethal checkpoint already contains a death"
    [ "$(/usr/bin/plutil -extract durableState.populationRegistry.nextPopulationOrdinal raw -o - "$PRE_SESSION")" = "4" ] \
        || fail "pre-lethal next population ordinal is not four"

    PRE_DIGEST=$(/usr/bin/sed -n 's/.*checkpoint saved name=mortality-preexit .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' "$PHASE1_TRACE" | /usr/bin/tail -1)
    PRE_SIM=$(/usr/bin/sed -n 's/.*checkpoint saved name=mortality-preexit .* simulation=\([^ ]*\) digest=.*/\1/p' "$PHASE1_TRACE" | /usr/bin/tail -1)
    [ -n "$PRE_DIGEST" ] && [ -n "$PRE_SIM" ] || fail "mortality pre-exit identity extraction failed"

    CONTROL_DB="$CONTROL_HOME/Library/Application Support/Pebble/pebble.db"
    /bin/mkdir -p "$(dirname "$CONTROL_DB")"
    [ ! -e "$CONTROL_DB" ] || fail "fresh mortality control database already exists"
    /usr/bin/sqlite3 "$DB_PATH" ".backup '$CONTROL_DB'"
    [ -s "$CONTROL_DB" ] || fail "mortality control database snapshot failed"
    persisted_world_tick=$(/usr/bin/sqlite3 "$DB_PATH" "SELECT json_extract(json, '$.dims.\"0\".time') FROM worlds;")
    case "$persisted_world_tick" in
        ''|*[!0-9]*) fail "invalid persisted World tick after mortality phase 1: $persisted_world_tick" ;;
    esac
    continuation_command_tick=$((persisted_world_tick + 100))
    control_command_tick=$continuation_command_tick

    MORTALITY_PHASE2_COMMANDS="$POPULATION_WORLD_READY|/lab start;/tp $POPULATION_ANCHOR_X $POPULATION_PLAYER_Y $POPULATION_ANCHOR_Z;/lab checkpoint load mortality-preexit;/lab mortality status;/lab survival status;/lab step;/lab mortality status;/lab exits status;/lab population status;/lab settlement status;/lab ecology status;/lab checkpoint save mortality-postexit;/lab checkpoint status;/lab causality status;/lab status"
    printf '\nMortality phase 2: exact pre-lethal restore and one terminal tick.\n'
    run_mortality_app "$SESSION_HOME" "$PHASE2_TRACE" "$MORTALITY_PHASE2_COMMANDS" 0 "$continuation_command_tick"
    TRACE_PATH="$PHASE2_TRACE"
    require_trace "checkpoint loaded name=mortality-preexit .*tick=26 simulation=$PRE_SIM digest=$PRE_DIGEST .*restartSafe=1 probes=4 paused=1 focus=agent_2 lifecycleEvent=none worldMutation=none" 'exact pre-lethal v5 restore'
    require_trace_count '^\[lab-live\] mortality exit tick=27 death=death-agent_2-t27-[0-9a-f]{16} agent=agent_2 cause=starvation health=10>0 population=4>3 terminal=0 probes=4>3 focus=agent_0 corpse=none worldMutation=none$' 1 'one exact terminal transition and probe removal'
    require_trace 'mortality gate=enabled active=yes agents=3 deaths=1 retained=1 evicted=0 latest=death-agent_2-t27-.* victim=agent_2 tick=27 terminal=0 members=3 nextOrdinal=4 probes=3 ' 'post-death mortality state'
    require_trace 'population exits count=1 latestDeath=death-agent_2-t27-.* agent=agent_2 tick=27 population=4>3' 'typed population exit frame'
    require_trace 'checkpoint saved name=mortality-postexit .*tick=27 .*restartSafe=1 ' 'restart-safe post-death checkpoint'
    require_trace 'summary .*agents=3 .*runtimeErrors=0 .*probesRemoved=3 ' 'clean post-death three-probe cleanup'
    reject_trace 'tick=27 .*agent_2:|runtime error|corpse=[^n]' 'terminal cognition, runtime error, or corpse'

    POST_MANIFEST=$(/usr/bin/find "$MORTALITY_ROOT" -type f -path '*/checkpoints/mortality-postexit/manifest.json' -print -quit)
    POST_SESSION=$(/usr/bin/find "$MORTALITY_ROOT" -type f -path '*/checkpoints/mortality-postexit/session.json' -print -quit)
    [ -n "$POST_MANIFEST" ] && [ -n "$POST_SESSION" ] || fail "mortality post-exit bundle missing"
    /usr/bin/grep -q '"schemaVersion":5' "$POST_SESSION" || fail "post-exit session is not schema v5"
    [ "$(/usr/bin/plutil -extract durableState.agents raw -o - "$POST_SESSION" | /usr/bin/grep -c 'agent_2' || true)" = "0" ] \
        || fail "dead agent_2 remains active after checkpoint"
    [ "$(/usr/bin/plutil -extract durableState.mortalityState.totalDeathCount raw -o - "$POST_SESSION")" = "1" ] \
        || fail "post-exit death count is not one"
    [ "$(/usr/bin/plutil -extract durableState.populationRegistry.nextPopulationOrdinal raw -o - "$POST_SESSION")" = "4" ] \
        || fail "death changed the next population ordinal"

    for counter in \
        observationCount \
        nearbyObservationCount \
        goalSelectionCount \
        goalChangeCount \
        actionCount \
        actionEffectCount \
        movementCount \
        totalManhattanDistanceMoved \
        returnHomeMoveCount
    do
        pre_value=$(/usr/bin/plutil -extract "durableState.agents.2.$counter" raw -o - "$PRE_SESSION")
        terminal_value=$(/usr/bin/plutil -extract \
            "durableState.mortalityState.records.0.terminalActivity.$counter" \
            raw -o - "$POST_SESSION")
        [ "$terminal_value" = "$pre_value" ] \
            || fail "terminal $counter changed across lethal survival boundary: $pre_value>$terminal_value"
    done
    pre_food=$(/usr/bin/plutil -extract \
        durableState.agents.2.survivalProgress.foodConsumedCount raw -o - "$PRE_SESSION")
    terminal_food=$(/usr/bin/plutil -extract \
        durableState.mortalityState.records.0.terminalActivity.foodConsumedCount \
        raw -o - "$POST_SESSION")
    [ "$terminal_food" = "$pre_food" ] \
        || fail "terminal foodConsumedCount changed across lethal survival boundary"
    pre_ticks_alive=$(/usr/bin/plutil -extract durableState.agents.2.ticksAlive raw -o - "$PRE_SESSION")
    terminal_ticks_alive=$(/usr/bin/plutil -extract \
        durableState.mortalityState.records.0.terminalActivity.ticksAlive \
        raw -o - "$POST_SESSION")
    [ "$terminal_ticks_alive" -eq $((pre_ticks_alive + 1)) ] \
        || fail "terminal ticksAlive did not advance exactly once"

    lethal_sequence=$(/usr/bin/plutil -extract \
        durableState.mortalityState.records.0.lethalDamageEventID.sequence raw -o - "$POST_SESSION")
    resources_sequence=$(/usr/bin/plutil -extract \
        durableState.mortalityState.records.0.resourcesRetiredEventID.sequence raw -o - "$POST_SESSION")
    commitments_sequence=$(/usr/bin/plutil -extract \
        durableState.mortalityState.records.0.commitmentsResolvedEventID.sequence raw -o - "$POST_SESSION")
    exit_sequence=$(/usr/bin/plutil -extract \
        durableState.mortalityState.records.0.populationExitEventID.sequence raw -o - "$POST_SESSION")
    finalized_sequence=$(/usr/bin/plutil -extract \
        durableState.mortalityState.records.0.deathEventID.sequence raw -o - "$POST_SESSION")
    [ "$resources_sequence" -eq $((lethal_sequence + 1)) ] \
        && [ "$commitments_sequence" -eq $((resources_sequence + 1)) ] \
        && [ "$exit_sequence" -eq $((commitments_sequence + 1)) ] \
        && [ "$finalized_sequence" -eq $((exit_sequence + 1)) ] \
        || fail "mortality causal sequence is not exact"
    [ "$(/usr/bin/plutil -extract durableState.causalLedger.droppedEventCount raw -o - "$POST_SESSION")" = "0" ] \
        || fail "mortality live ledger dropped events required by proof"

    lethal_index=$((lethal_sequence - 1))
    resources_index=$((resources_sequence - 1))
    commitments_index=$((commitments_sequence - 1))
    exit_index=$((exit_sequence - 1))
    finalized_index=$((finalized_sequence - 1))
    [ "$(/usr/bin/plutil -extract "durableState.causalLedger.events.$lethal_index.kind" raw -o - "$POST_SESSION")" = "lethalHealthDepletion" ] \
        && [ "$(/usr/bin/plutil -extract "durableState.causalLedger.events.$resources_index.kind" raw -o - "$POST_SESSION")" = "mortalityResourcesRetired" ] \
        && [ "$(/usr/bin/plutil -extract "durableState.causalLedger.events.$commitments_index.kind" raw -o - "$POST_SESSION")" = "mortalityCommitmentsResolved" ] \
        && [ "$(/usr/bin/plutil -extract "durableState.causalLedger.events.$exit_index.kind" raw -o - "$POST_SESSION")" = "populationMemberExited" ] \
        && [ "$(/usr/bin/plutil -extract "durableState.causalLedger.events.$finalized_index.kind" raw -o - "$POST_SESSION")" = "agentDeathFinalized" ] \
        || fail "mortality causal kinds are not in canonical order"
    [ "$(/usr/bin/plutil -extract "durableState.causalLedger.events.$resources_index.causes.0.sequence" raw -o - "$POST_SESSION")" = "$lethal_sequence" ] \
        && [ "$(/usr/bin/plutil -extract "durableState.causalLedger.events.$commitments_index.causes.0.sequence" raw -o - "$POST_SESSION")" = "$lethal_sequence" ] \
        && [ "$(/usr/bin/plutil -extract "durableState.causalLedger.events.$exit_index.causes.0.sequence" raw -o - "$POST_SESSION")" = "$lethal_sequence" ] \
        && [ "$(/usr/bin/plutil -extract "durableState.causalLedger.events.$exit_index.causes.1.sequence" raw -o - "$POST_SESSION")" = "$resources_sequence" ] \
        && [ "$(/usr/bin/plutil -extract "durableState.causalLedger.events.$exit_index.causes.2.sequence" raw -o - "$POST_SESSION")" = "$commitments_sequence" ] \
        && [ "$(/usr/bin/plutil -extract "durableState.causalLedger.events.$finalized_index.causes.0.sequence" raw -o - "$POST_SESSION")" = "$exit_sequence" ] \
        || fail "mortality causal links are not exact"

    latest_sequence=$(/usr/bin/plutil -extract durableState.causalLedger.latestSequence raw -o - "$POST_SESSION")
    event_index=$lethal_index
    while [ "$event_index" -lt "$latest_sequence" ]; do
        event_kind=$(/usr/bin/plutil -extract \
            "durableState.causalLedger.events.$event_index.kind" raw -o - "$POST_SESSION")
        event_actor=$(/usr/bin/plutil -extract \
            "durableState.causalLedger.events.$event_index.actorID" raw -o - "$POST_SESSION" 2>/dev/null || true)
        event_subject=$(/usr/bin/plutil -extract \
            "durableState.causalLedger.events.$event_index.subjectID" raw -o - "$POST_SESSION" 2>/dev/null || true)
        if [ "$event_actor" = "agent_2" ] || [ "$event_subject" = "agent_2" ]; then
            case "$event_kind" in
                perception|goalTransition|actionSelected|movement|interaction|delivery|consumption|resourceFactGrounded|socialMessageSent|physicalSignalEmitted|sharedTaskAccepted|sharedTaskProgress|constructionPlacement|ecologyForageResolved)
                    fail "post-lethal cognitive or material event for agent_2: $event_kind" ;;
            esac
            if [ "$event_index" -gt "$finalized_index" ]; then
                case "$event_kind" in
                    lethalHealthDepletion|mortalityResourcesRetired|mortalityCommitmentsResolved|populationMemberExited|agentDeathFinalized)
                        fail "agentDeathFinalized is not the terminal mortality event" ;;
                esac
            fi
        fi
        event_index=$((event_index + 1))
    done

    for active_path in \
        durableState.agents \
        durableState.reservations \
        durableState.failedNaturalResourceTargets \
        durableState.activeSocialVerifications \
        durableState.lastSocialShareTicks \
        durableState.lastCooperationOfferTicks \
        durableState.lastPerceptionEvents \
        durableState.lastDecisionEvents \
        durableState.lastOutcomeEvents \
        durableState.populationRegistry.members \
        durableState.populationRegistry.settlement.residentIDs \
        durableState.populationRegistry.settlement.inTransitIDs
    do
        if /usr/bin/plutil -extract "$active_path" json -o - "$POST_SESSION" \
            | /usr/bin/grep -q 'agent_2'; then
            fail "dead agent_2 remains in active reference path $active_path"
        fi
    done
    POST_DIGEST=$(/usr/bin/sed -n 's/.*checkpoint saved name=mortality-postexit .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' "$PHASE2_TRACE" | /usr/bin/tail -1)
    POST_DEATH_ID=$(/usr/bin/sed -n 's/.*mortality exit tick=27 death=\([^ ]*\) agent=.*/\1/p' "$PHASE2_TRACE" | /usr/bin/tail -1)
    [ -n "$POST_DIGEST" ] && [ -n "$POST_DEATH_ID" ] || fail "post-exit identity extraction failed"
    persisted_world_tick=$(/usr/bin/sqlite3 "$DB_PATH" "SELECT json_extract(json, '$.dims.\"0\".time') FROM worlds;")
    case "$persisted_world_tick" in
        ''|*[!0-9]*) fail "invalid persisted World tick after mortality phase 2: $persisted_world_tick" ;;
    esac
    continuation_command_tick=$((persisted_world_tick + 100))
    control_command_tick=$continuation_command_tick

    MORTALITY_PHASE3_COMMANDS="$POPULATION_WORLD_READY|/lab start;/tp $POPULATION_ANCHOR_X $POPULATION_PLAYER_Y $POPULATION_ANCHOR_Z;/lab checkpoint load mortality-postexit;/lab mortality status;/lab population status;/lab step;/lab migration admit;/lab focus agent_4;/lab follow agent_4;/lab movement on"
    mortality_step=0
    while [ "$mortality_step" -lt 8 ]; do
        MORTALITY_PHASE3_COMMANDS="$MORTALITY_PHASE3_COMMANDS;/lab step"
        mortality_step=$((mortality_step + 1))
    done
    MORTALITY_PHASE3_COMMANDS="$MORTALITY_PHASE3_COMMANDS;/lab migration status;/lab population status;/lab mortality status;/lab exits status;/lab ecology status;/lab settlement status;/lab checkpoint save mortality-final;/lab checkpoint status;/lab causality status;/lab status"
    printf '\nMortality phase 3: post-death restore and physical agent_4 replacement.\n'
    run_mortality_app "$SESSION_HOME" "$PHASE3_TRACE" "$MORTALITY_PHASE3_COMMANDS" 0 "$continuation_command_tick"
    TRACE_PATH="$PHASE3_TRACE"
    require_trace "checkpoint loaded name=mortality-postexit .*tick=27 simulation=$PRE_SIM digest=$POST_DIGEST .*restartSafe=1 probes=3 paused=1 focus=agent_0 lifecycleEvent=none worldMutation=none" 'exact post-death v5 restore without resurrection'
    require_trace 'migration admitted id=migration-00000004 migrant=agent_4 .*probes=agent_0,agent_1,agent_3,agent_4 members=4 nextOrdinal=5' 'monotone agent_4 admission and atomic fourth probe'
    require_trace 'migration id=migration-00000004 migrant=agent_4 .*status=arrived ' 'physical replacement arrival'
    require_trace 'population gate=enabled enabled=1 settlement=settlement-main capacity=8 members=4 founders=2 residents=4 migrating=0 nextOrdinal=5 activeMigration=0 latestMigrant=agent_4 latestMigrationStatus=arrived ' 'four-resident replacement registry'
    require_trace "mortality gate=enabled active=yes agents=4 deaths=1 retained=1 evicted=0 latest=$POST_DEATH_ID victim=agent_2 tick=27 terminal=0 members=4 nextOrdinal=5 probes=4" 'one durable death after replacement'
    require_trace 'checkpoint saved name=mortality-final .*restartSafe=1 ' 'restart-safe final mortality checkpoint'
    require_trace 'summary .*agents=4 .*runtimeErrors=0 .*probesRemoved=4 ' 'clean final four-probe cleanup'
    reject_trace 'mortality exit tick=(2[8-9]|3[0-9])|runtime error|agent_2=.*\/m' 'second death, runtime error, or resurrection'

    MORTALITY_CONTROL_COMMANDS="$MORTALITY_BOOTSTRAP_COMMANDS;/lab focus agent_2;/lab follow agent_2;/lab step;/lab step;/lab migration admit;/lab focus agent_4;/lab follow agent_4"
    mortality_step=0
    while [ "$mortality_step" -lt 8 ]; do
        MORTALITY_CONTROL_COMMANDS="$MORTALITY_CONTROL_COMMANDS;/lab step"
        mortality_step=$((mortality_step + 1))
    done
    MORTALITY_CONTROL_COMMANDS="$MORTALITY_CONTROL_COMMANDS;/lab migration status;/lab population status;/lab mortality status;/lab exits status;/lab ecology status;/lab settlement status;/lab checkpoint save mortality-final-control;/lab checkpoint status;/lab causality status;/lab status"
    printf '\nMortality uninterrupted control.\n'
    run_mortality_app "$CONTROL_HOME" "$CONTROL_TRACE" "$MORTALITY_CONTROL_COMMANDS" 0 "$control_command_tick"
    TRACE_PATH="$CONTROL_TRACE"
    require_trace_count '^\[lab-live\] mortality exit tick=27 death=death-agent_2-t27-[0-9a-f]{16} agent=agent_2 cause=starvation health=10>0 population=4>3 terminal=0 probes=4>3 focus=agent_0 corpse=none worldMutation=none$' 1 'one uninterrupted terminal transition'
    require_trace 'migration id=migration-00000004 migrant=agent_4 .*status=arrived ' 'uninterrupted agent_4 arrival'
    require_trace 'summary .*agents=4 .*runtimeErrors=0 .*probesRemoved=4 ' 'clean uninterrupted cleanup'
    reject_trace 'mortality exit tick=(2[8-9]|3[0-9])|runtime error' 'uninterrupted second death or runtime error'

    LIVE_DIGEST=$(/usr/bin/sed -n 's/.*checkpoint saved name=mortality-final .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' "$PHASE3_TRACE" | /usr/bin/tail -1)
    CONTROL_DIGEST=$(/usr/bin/sed -n 's/.*checkpoint saved name=mortality-final-control .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' "$CONTROL_TRACE" | /usr/bin/tail -1)
    LIVE_MORTALITY_DIGEST=$(/usr/bin/sed -n 's/.*mortality gate=enabled .* digest=\([0-9a-f]*\)$/\1/p' "$PHASE3_TRACE" | /usr/bin/tail -1)
    CONTROL_MORTALITY_DIGEST=$(/usr/bin/sed -n 's/.*mortality gate=enabled .* digest=\([0-9a-f]*\)$/\1/p' "$CONTROL_TRACE" | /usr/bin/tail -1)
    LIVE_ECOLOGY_DIGEST=$(/usr/bin/sed -n 's/.*ecology gate=enabled .* digest=\([0-9a-f]*\) ecologyConservation=.*/\1/p' "$PHASE3_TRACE" | /usr/bin/tail -1)
    CONTROL_ECOLOGY_DIGEST=$(/usr/bin/sed -n 's/.*ecology gate=enabled .* digest=\([0-9a-f]*\) ecologyConservation=.*/\1/p' "$CONTROL_TRACE" | /usr/bin/tail -1)
    LIVE_SETTLEMENT_DIGEST=$(/usr/bin/sed -n 's/.*settlement gate=enabled .* digest=\([0-9a-f]*\)$/\1/p' "$PHASE3_TRACE" | /usr/bin/tail -1)
    CONTROL_SETTLEMENT_DIGEST=$(/usr/bin/sed -n 's/.*settlement gate=enabled .* digest=\([0-9a-f]*\)$/\1/p' "$CONTROL_TRACE" | /usr/bin/tail -1)
    LIVE_POPULATION_DIGEST=$(/usr/bin/sed -n 's/.*population gate=enabled .* digest=\([0-9a-f]*\)$/\1/p' "$PHASE3_TRACE" | /usr/bin/tail -1)
    CONTROL_POPULATION_DIGEST=$(/usr/bin/sed -n 's/.*population gate=enabled .* digest=\([0-9a-f]*\)$/\1/p' "$CONTROL_TRACE" | /usr/bin/tail -1)
    LIVE_CAUSAL_DIGEST=$(/usr/bin/sed -n 's/.*causality status .* digest=\([0-9a-f]*\)$/\1/p' "$PHASE3_TRACE" | /usr/bin/tail -1)
    CONTROL_CAUSAL_DIGEST=$(/usr/bin/sed -n 's/.*causality status .* digest=\([0-9a-f]*\)$/\1/p' "$CONTROL_TRACE" | /usr/bin/tail -1)
    [ -n "$LIVE_DIGEST" ] && [ "$LIVE_DIGEST" = "$CONTROL_DIGEST" ] \
        || fail "mortality restart/uninterrupted durable digest mismatch"
    [ "$LIVE_MORTALITY_DIGEST" = "$CONTROL_MORTALITY_DIGEST" ] \
        || fail "mortality restart/uninterrupted mortality digest mismatch"
    [ "$LIVE_ECOLOGY_DIGEST" = "$CONTROL_ECOLOGY_DIGEST" ] \
        || fail "mortality restart/uninterrupted ecology digest mismatch"
    [ "$LIVE_SETTLEMENT_DIGEST" = "$CONTROL_SETTLEMENT_DIGEST" ] \
        || fail "mortality restart/uninterrupted settlement digest mismatch"
    [ "$LIVE_POPULATION_DIGEST" = "$CONTROL_POPULATION_DIGEST" ] \
        || fail "mortality restart/uninterrupted population digest mismatch"
    [ "$LIVE_CAUSAL_DIGEST" = "$CONTROL_CAUSAL_DIGEST" ] \
        || fail "mortality restart/uninterrupted causal digest mismatch"

    /bin/cat "$PHASE2_TRACE" "$PHASE3_TRACE" | /usr/bin/grep -E '^\[lab-live\] (tick=(2[7-9]|3[0-6]) |ecology (pulse|forage) tick=(2[7-9]|3[0-6]) |population tick=(2[7-9]|3[0-6]) |settlement (frame|classifications|welfare) tick=(2[7-9]|3[0-6]) |mortality exit tick=27 )' \
        > "$SESSION_ROOT/restart-mortality.normalized"
    /usr/bin/grep -E '^\[lab-live\] (tick=(2[7-9]|3[0-6]) |ecology (pulse|forage) tick=(2[7-9]|3[0-6]) |population tick=(2[7-9]|3[0-6]) |settlement (frame|classifications|welfare) tick=(2[7-9]|3[0-6]) |mortality exit tick=27 )' "$CONTROL_TRACE" \
        > "$SESSION_ROOT/control-mortality.normalized"
    /usr/bin/cmp "$SESSION_ROOT/restart-mortality.normalized" "$SESSION_ROOT/control-mortality.normalized" \
        || fail "mortality restart and uninterrupted decision/material traces differ"

    FINAL_SESSION=$(/usr/bin/find "$MORTALITY_ROOT" -type f -path '*/checkpoints/mortality-final/session.json' -print -quit)
    [ -n "$FINAL_SESSION" ] || fail "final mortality checkpoint missing"
    [ "$(/usr/bin/plutil -extract durableState.mortalityState.totalDeathCount raw -o - "$FINAL_SESSION")" = "1" ] \
        || fail "final mortality checkpoint death count changed"
    [ "$(/usr/bin/plutil -extract durableState.populationRegistry.nextPopulationOrdinal raw -o - "$FINAL_SESSION")" = "5" ] \
        || fail "final replacement ordinal is not five"
    if /usr/bin/pgrep -f '[/]PebbleLab-live\.' >/dev/null 2>&1; then
        fail "residual PebbleLab process after mortality proof"
    fi
    printf '\nPASS: bounded starvation mortality, v5 pre/post restart, probe exit, agent_4 replacement, and uninterrupted equivalence verified.\n'
    printf 'Phase 1 trace: %s\n' "$PHASE1_TRACE"
    printf 'Phase 2 trace: %s\n' "$PHASE2_TRACE"
    printf 'Phase 3 trace: %s\n' "$PHASE3_TRACE"
    printf 'Control trace: %s\n' "$CONTROL_TRACE"
    printf 'Death ID: %s\n' "$POST_DEATH_ID"
    printf 'Final durable digest: %s\n' "$LIVE_DIGEST"
    printf 'Mortality digest: %s\n' "$LIVE_MORTALITY_DIGEST"
    printf 'Ecology digest: %s\n' "$LIVE_ECOLOGY_DIGEST"
    printf 'Settlement digest: %s\n' "$LIVE_SETTLEMENT_DIGEST"
    printf 'Population digest: %s\n' "$LIVE_POPULATION_DIGEST"
    printf 'Causal digest: %s\n' "$LIVE_CAUSAL_DIGEST"
    printf 'Retained isolated session: %s\n' "$SESSION_ROOT"
    exit 0
fi

if [ "$MODE" = "ecology" ]; then
    cd "$ROOT_DIR"
    swift build -c release --product Pebble
    PEBBLE_BINARY="$ROOT_DIR/.build/release/Pebble"
    [ -x "$PEBBLE_BINARY" ] || fail "Release Pebble binary missing: $PEBBLE_BINARY"

    PHASE1_TRACE="$SESSION_ROOT/ecology-phase1.log"
    PHASE2_TRACE="$SESSION_ROOT/ecology-phase2.log"
    CONTROL_HOME="$SESSION_ROOT/control-home"
    CONTROL_TRACE="$SESSION_ROOT/ecology-control.log"
    [ ! -e "$CONTROL_HOME" ] || fail "fresh ecology control home already exists: $CONTROL_HOME"

    run_ecology_app() {
        run_home=$1
        run_trace=$2
        run_commands=$3
        create_world=$4
        command_world_tick=$5
        if [ "$create_world" -eq 1 ]; then
            CFFIXED_USER_HOME="$run_home" \
            PEBBLE_AUTOLOAD=1 \
            PEBBLE_NEWWORLD="$WORLD_SEED" \
            PEBBLE_NEWWORLD_NAME="$WORLD_NAME" \
            PEBBLELAB_APP_AGENTS=1 \
            PEBBLELAB_APP_AGENTS_MOVE=1 \
            PEBBLELAB_APP_PROBES=1 \
            PEBBLELAB_DEBUG_ENTITIES=1 \
            PEBBLELAB_APP_AGENTS_OVERLAY=1 \
            PEBBLELAB_APP_AGENTS_TRACE=1 \
            PEBBLELAB_APP_AGENTS_TRACE_EVERY=1 \
            PEBBLELAB_APP_AGENTS_INTERACT=1 \
            PEBBLELAB_APP_AGENTS_NATURAL=0 \
            PEBBLELAB_APP_AGENTS_BUILD=0 \
            PEBBLELAB_APP_AGENTS_SOCIAL=0 \
            PEBBLELAB_APP_AGENTS_PHYSICAL=0 \
            PEBBLELAB_APP_AGENTS_COOPERATION=0 \
            PEBBLELAB_APP_AGENTS_PERSISTENCE=1 \
            PEBBLELAB_APP_AGENTS_POPULATION=1 \
            PEBBLELAB_APP_AGENTS_MULTISCALE=1 \
            PEBBLELAB_APP_AGENTS_ECOLOGY=1 \
            PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
            PEBBLE_CMD_WORLD_TICK="$command_world_tick" \
            PEBBLE_CMD="$run_commands" \
            PEBBLE_SHOT='-|-|-|-' \
            "$PEBBLE_BINARY" 2>&1 | /usr/bin/tee "$run_trace"
        else
            CFFIXED_USER_HOME="$run_home" \
            PEBBLE_AUTOLOAD=1 \
            PEBBLELAB_APP_AGENTS=1 \
            PEBBLELAB_APP_AGENTS_MOVE=1 \
            PEBBLELAB_APP_PROBES=1 \
            PEBBLELAB_DEBUG_ENTITIES=1 \
            PEBBLELAB_APP_AGENTS_OVERLAY=1 \
            PEBBLELAB_APP_AGENTS_TRACE=1 \
            PEBBLELAB_APP_AGENTS_TRACE_EVERY=1 \
            PEBBLELAB_APP_AGENTS_INTERACT=1 \
            PEBBLELAB_APP_AGENTS_NATURAL=0 \
            PEBBLELAB_APP_AGENTS_BUILD=0 \
            PEBBLELAB_APP_AGENTS_SOCIAL=0 \
            PEBBLELAB_APP_AGENTS_PHYSICAL=0 \
            PEBBLELAB_APP_AGENTS_COOPERATION=0 \
            PEBBLELAB_APP_AGENTS_PERSISTENCE=1 \
            PEBBLELAB_APP_AGENTS_POPULATION=1 \
            PEBBLELAB_APP_AGENTS_MULTISCALE=1 \
            PEBBLELAB_APP_AGENTS_ECOLOGY=1 \
            PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
            PEBBLE_CMD_WORLD_TICK="$command_world_tick" \
            PEBBLE_CMD="$run_commands" \
            PEBBLE_SHOT='-|-|-|-' \
            "$PEBBLE_BINARY" 2>&1 | /usr/bin/tee "$run_trace"
        fi
        if /usr/bin/pgrep -x Pebble >/dev/null 2>&1; then
            fail "Pebble process remained after ecology phase: $run_trace"
        fi
    }

    printf '\nEcology phase 1: four residents, bounded forage, shortage, and v4 checkpoint.\n'
    run_ecology_app "$SESSION_HOME" "$PHASE1_TRACE" "$ECOLOGY_PHASE1_COMMANDS" 1 100
    TRACE_PATH="$PHASE1_TRACE"
    require_trace 'start seed=46 agents=3 tick=0 ' 'historical three-agent bootstrap'
    require_trace 'migration id=migration-00000003 migrant=agent_3 .*routeCursor=[1-9][0-9]* status=arrived ' 'physical migrant arrival before ecology activation'
    require_trace 'population gate=enabled enabled=1 settlement=settlement-main capacity=8 members=4 founders=3 residents=4 migrating=0 ' 'four-resident ecology population'
    require_trace 'ecology=on tick=7 patches=2 reads=[1-9][0-9]* mutation=none' 'read-only local ecology initialization'
    require_trace_count '^\[lab-live\] ecology patch id=patch-[0-9a-f]+ habitat=.* forage=.* fingerprint=[1-9][0-9]* distance=[1-9][0-9]* yield=1/1 status=available mutation=none$' 2 'two real bounded habitat patches'
    require_trace 'tick=15 .*economy=on natural=off .*survival=on ' 'canonical economy and survival gates with natural wood/stone disabled'
    require_trace 'ecology forage tick=.* status=succeeded yield=1->0 inventory=0->1 mutation=none' 'transactional forage success'
    forage_success_count=$(/usr/bin/grep -Ec '^\[lab-live\] ecology forage tick=.* status=succeeded ' "$PHASE1_TRACE" || true)
    [ "$forage_success_count" -ge 2 ] || fail "live ecology produced fewer than two successful forages"
    require_trace 'tick=14 .*action=approach_resource focusMove=moved:.*navigationPurpose=resource navigation=active ' 'bounded authoritative approach to local forage'
    require_trace 'ecology pulse tick=21 patches=2 yield=1/2 regenerated=1 harvested=2 pressure=scarce hungry=3 critical=0 starvationDamage=0 .*conservation=exact mutation=none' 'real local shortage with yield below hungry residents'
    require_trace 'ecology gate=enabled active=yes settlement=settlement-main patches=2 available=1 depleted=1 invalidated=0 yield=1/2 regenerated=1 harvested=2 .*pressure=scarce hungry=3 .*ecologyConservation=2\+1:1\+2:exact resourceConservation=2:1\+0\+1\+0\+0:exact .*reason=initialized_from_read-only_World_scan' 'checkpoint shortage status and double conservation'
    require_trace 'checkpoint saved name=ecology-shortage .*tick=21 .*restartSafe=1 ' 'restart-safe shortage checkpoint'
    require_trace 'summary .*agents=4 .*runtimeErrors=0 .*probesRemoved=4 .*naturalHarvests=0 .*buildProject=none .*causalDropped=0' 'clean four-probe shortage cleanup'
    reject_trace 'ecology.*mutation=(block|world)|runtime error|health=0' 'World mutation, runtime error, or zero health during shortage'

    ECOLOGY_ROOT="$SESSION_HOME/Library/Application Support/Pebble/PebbleLabAgents"
    SHORTAGE_MANIFEST=$(/usr/bin/find "$ECOLOGY_ROOT" -type f -path '*/checkpoints/ecology-shortage/manifest.json' -print -quit)
    SHORTAGE_SESSION=$(/usr/bin/find "$ECOLOGY_ROOT" -type f -path '*/checkpoints/ecology-shortage/session.json' -print -quit)
    [ -n "$SHORTAGE_MANIFEST" ] && [ -n "$SHORTAGE_SESSION" ] \
        || fail "ecology v4 checkpoint bundle missing"
    /usr/bin/grep -q '"schemaVersion":4' "$SHORTAGE_MANIFEST" \
        || fail "ecology checkpoint manifest is not schema v4"
    /usr/bin/grep -q '"schemaVersion":4' "$SHORTAGE_SESSION" \
        || fail "ecology checkpoint session is not schema v4"
    /usr/bin/grep -q '"restartSafe":true' "$SHORTAGE_MANIFEST" \
        || fail "ecology shortage checkpoint is not restart-safe"
    /usr/bin/grep -q '"localEcologyState"' "$SHORTAGE_SESSION" \
        || fail "ecology state missing from schema v4 checkpoint"
    if /usr/bin/grep -q '"health":0' "$SHORTAGE_SESSION"; then
        fail "zero-health agent in ecology shortage checkpoint"
    fi

    PHASE1_DIGEST=$(/usr/bin/sed -n 's/.*checkpoint saved name=ecology-shortage .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' "$PHASE1_TRACE" | /usr/bin/tail -1)
    PHASE1_SIM=$(/usr/bin/sed -n 's/.*checkpoint saved name=ecology-shortage .* simulation=\([^ ]*\) digest=.*/\1/p' "$PHASE1_TRACE" | /usr/bin/tail -1)
    [ -n "$PHASE1_DIGEST" ] && [ -n "$PHASE1_SIM" ] \
        || fail "ecology phase-one identity extraction failed"

    CONTROL_DB="$CONTROL_HOME/Library/Application Support/Pebble/pebble.db"
    /bin/mkdir -p "$(dirname "$CONTROL_DB")"
    [ ! -e "$CONTROL_DB" ] || fail "fresh ecology control database already exists"
    /usr/bin/sqlite3 "$DB_PATH" ".backup '$CONTROL_DB'"
    [ -s "$CONTROL_DB" ] || fail "ecology control database snapshot failed"
    persisted_world_tick=$(/usr/bin/sqlite3 "$DB_PATH" "SELECT json_extract(json, '$.dims.\"0\".time') FROM worlds;")
    case "$persisted_world_tick" in
        ''|*[!0-9]*) fail "invalid persisted World tick after ecology phase 1: $persisted_world_tick" ;;
    esac
    continuation_command_tick=$((persisted_world_tick + 100))

    ECOLOGY_PHASE2_COMMANDS="$POPULATION_WORLD_READY|/lab start;/tp $POPULATION_ANCHOR_X $POPULATION_PLAYER_Y $POPULATION_ANCHOR_Z;/lab checkpoint load ecology-shortage;/lab ecology status;/lab population status;/lab movement on"
    ecology_step=0
    while [ "$ecology_step" -lt 11 ]; do
        ECOLOGY_PHASE2_COMMANDS="$ECOLOGY_PHASE2_COMMANDS;/lab step"
        ecology_step=$((ecology_step + 1))
    done
    ECOLOGY_PHASE2_COMMANDS="$ECOLOGY_PHASE2_COMMANDS;/lab ecology status;/lab forage status;/lab survival status;/lab population status;/lab settlement status;/lab checkpoint save ecology-final;/lab checkpoint status;/lab causality status;/lab status"

    ECOLOGY_CONTROL_COMMANDS="$POPULATION_WORLD_READY|/lab start;/tp $POPULATION_ANCHOR_X $POPULATION_PLAYER_Y $POPULATION_ANCHOR_Z;/lab pause;/lab movement on;/lab population on;/lab settlement on;/lab migration admit;/lab focus agent_3;/lab follow agent_3"
    ecology_step=0
    while [ "$ecology_step" -lt 7 ]; do
        ECOLOGY_CONTROL_COMMANDS="$ECOLOGY_CONTROL_COMMANDS;/lab step"
        ecology_step=$((ecology_step + 1))
    done
    ECOLOGY_CONTROL_COMMANDS="$ECOLOGY_CONTROL_COMMANDS;/lab ecology on;/lab survival on;/lab focus agent_0;/lab ecology scan"
    ecology_step=0
    while [ "$ecology_step" -lt 7 ]; do
        ECOLOGY_CONTROL_COMMANDS="$ECOLOGY_CONTROL_COMMANDS;/lab step"
        ecology_step=$((ecology_step + 1))
    done
    ECOLOGY_CONTROL_COMMANDS="$ECOLOGY_CONTROL_COMMANDS;/lab economy auto on"
    ecology_step=0
    while [ "$ecology_step" -lt 18 ]; do
        ECOLOGY_CONTROL_COMMANDS="$ECOLOGY_CONTROL_COMMANDS;/lab step"
        ecology_step=$((ecology_step + 1))
    done
    ECOLOGY_CONTROL_COMMANDS="$ECOLOGY_CONTROL_COMMANDS;/lab ecology status;/lab forage status;/lab survival status;/lab population status;/lab settlement status;/lab checkpoint save ecology-final-control;/lab checkpoint status;/lab causality status;/lab status"

    printf '\nEcology phase 2: exact v4 restart, regeneration, forage, consumption, and pressure recovery.\n'
    run_ecology_app "$SESSION_HOME" "$PHASE2_TRACE" "$ECOLOGY_PHASE2_COMMANDS" 0 "$continuation_command_tick"
    TRACE_PATH="$PHASE2_TRACE"
    require_trace "checkpoint loaded name=ecology-shortage .*tick=21 simulation=$PHASE1_SIM digest=$PHASE1_DIGEST .*restartSafe=1 probes=4 paused=1 focus=agent_0 lifecycleEvent=none worldMutation=none" 'exact four-agent v4 restore'
    require_trace 'ecology pulse tick=.*regenerated=[1-9][0-9]* .*pressure=recovering .*conservation=exact mutation=none' 'deterministic regeneration and recovering pressure'
    require_trace 'ecology forage tick=.*status=succeeded yield=1->0 inventory=0->1 mutation=none' 'post-restart forage success'
    require_trace 'ecology pulse tick=.*critical=[1-9][0-9]* starvationDamage=[1-9][0-9]* .*conservation=exact mutation=none' 'real critical hunger and starvation damage'
    require_trace 'ecology gate=enabled active=yes settlement=settlement-main patches=2 .*invalidated=0 .*regenerated=[1-9][0-9]* harvested=[3-9][0-9]* .*ecologyConservation=.*:exact resourceConservation=.*:exact .*reads=[1-9][0-9]*/256 ' 'final unchanged habitats and exact ecology/material conservation'
    require_trace 'checkpoint saved name=ecology-final .*tick=32 .*restartSafe=1 ' 'restart-safe final v4 checkpoint before zero health'
    require_trace 'summary .*agents=4 .*runtimeErrors=0 .*probesRemoved=4 .*naturalHarvests=0 .*buildProject=none .*causalDropped=0' 'clean restarted ecology cleanup'
    reject_trace 'ecology.*mutation=(block|world)|runtime error|health=0' 'World mutation, runtime error, or zero health after restart'

    LIVE_DIGEST=$(/usr/bin/sed -n 's/.*checkpoint saved name=ecology-final .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' "$PHASE2_TRACE" | /usr/bin/tail -1)
    LIVE_ECOLOGY_DIGEST=$(/usr/bin/sed -n 's/.*ecology gate=enabled .* digest=\([0-9a-f]*\) ecologyConservation=.*/\1/p' "$PHASE2_TRACE" | /usr/bin/tail -1)
    LIVE_SETTLEMENT_DIGEST=$(/usr/bin/sed -n 's/.*settlement gate=enabled .* digest=\([0-9a-f]*\)$/\1/p' "$PHASE2_TRACE" | /usr/bin/tail -1)
    LIVE_POPULATION_DIGEST=$(/usr/bin/sed -n 's/.*population gate=enabled .* digest=\([0-9a-f]*\)$/\1/p' "$PHASE2_TRACE" | /usr/bin/tail -1)
    LIVE_CAUSAL_DIGEST=$(/usr/bin/sed -n 's/.*causality status .* digest=\([0-9a-f]*\)$/\1/p' "$PHASE2_TRACE" | /usr/bin/tail -1)
    [ -n "$LIVE_DIGEST" ] && [ -n "$LIVE_ECOLOGY_DIGEST" ] \
        && [ -n "$LIVE_SETTLEMENT_DIGEST" ] && [ -n "$LIVE_POPULATION_DIGEST" ] \
        && [ -n "$LIVE_CAUSAL_DIGEST" ] || fail "ecology final digest extraction failed"

    printf '\nEcology uninterrupted control.\n'
    run_ecology_app "$CONTROL_HOME" "$CONTROL_TRACE" "$ECOLOGY_CONTROL_COMMANDS" 0 "$continuation_command_tick"
    TRACE_PATH="$CONTROL_TRACE"
    require_trace 'ecology pulse tick=.*critical=[1-9][0-9]* starvationDamage=[1-9][0-9]* .*conservation=exact mutation=none' 'uninterrupted critical hunger and starvation damage'
    require_trace 'ecology pulse tick=.*regenerated=[1-9][0-9]* .*pressure=recovering .*conservation=exact mutation=none' 'uninterrupted regeneration and recovery'
    require_trace 'checkpoint saved name=ecology-final-control .*tick=32 .*restartSafe=1 ' 'uninterrupted final v4 checkpoint before zero health'
    require_trace 'summary .*agents=4 .*runtimeErrors=0 .*probesRemoved=4 .*naturalHarvests=0 .*buildProject=none .*causalDropped=0' 'clean uninterrupted ecology cleanup'
    reject_trace 'ecology.*mutation=(block|world)|runtime error|health=0' 'World mutation, runtime error, or zero health in uninterrupted control'

    CONTROL_DIGEST=$(/usr/bin/sed -n 's/.*checkpoint saved name=ecology-final-control .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' "$CONTROL_TRACE" | /usr/bin/tail -1)
    CONTROL_ECOLOGY_DIGEST=$(/usr/bin/sed -n 's/.*ecology gate=enabled .* digest=\([0-9a-f]*\) ecologyConservation=.*/\1/p' "$CONTROL_TRACE" | /usr/bin/tail -1)
    CONTROL_SETTLEMENT_DIGEST=$(/usr/bin/sed -n 's/.*settlement gate=enabled .* digest=\([0-9a-f]*\)$/\1/p' "$CONTROL_TRACE" | /usr/bin/tail -1)
    CONTROL_POPULATION_DIGEST=$(/usr/bin/sed -n 's/.*population gate=enabled .* digest=\([0-9a-f]*\)$/\1/p' "$CONTROL_TRACE" | /usr/bin/tail -1)
    CONTROL_CAUSAL_DIGEST=$(/usr/bin/sed -n 's/.*causality status .* digest=\([0-9a-f]*\)$/\1/p' "$CONTROL_TRACE" | /usr/bin/tail -1)
    [ "$CONTROL_DIGEST" = "$LIVE_DIGEST" ] || fail "ecology restart/uninterrupted durable digest mismatch"
    [ "$CONTROL_ECOLOGY_DIGEST" = "$LIVE_ECOLOGY_DIGEST" ] || fail "ecology restart/uninterrupted ecology digest mismatch"
    [ "$CONTROL_SETTLEMENT_DIGEST" = "$LIVE_SETTLEMENT_DIGEST" ] || fail "ecology restart/uninterrupted settlement digest mismatch"
    [ "$CONTROL_POPULATION_DIGEST" = "$LIVE_POPULATION_DIGEST" ] || fail "ecology restart/uninterrupted population digest mismatch"
    [ "$CONTROL_CAUSAL_DIGEST" = "$LIVE_CAUSAL_DIGEST" ] || fail "ecology restart/uninterrupted causal digest mismatch"

    /usr/bin/grep -E '^\[lab-live\] (tick=(2[2-9]|3[0-2]) |ecology (pulse|forage) tick=(2[2-9]|3[0-2]) )' "$PHASE2_TRACE" \
        > "$SESSION_ROOT/restart-ecology.normalized"
    /usr/bin/grep -E '^\[lab-live\] (tick=(2[2-9]|3[0-2]) |ecology (pulse|forage) tick=(2[2-9]|3[0-2]) )' "$CONTROL_TRACE" \
        > "$SESSION_ROOT/control-ecology.normalized"
    /usr/bin/cmp "$SESSION_ROOT/restart-ecology.normalized" "$SESSION_ROOT/control-ecology.normalized" \
        || fail "ecology restart and uninterrupted decision/material traces differ"

    FINAL_MANIFEST=$(/usr/bin/find "$ECOLOGY_ROOT" -type f -path '*/checkpoints/ecology-final/manifest.json' -print -quit)
    FINAL_SESSION=$(/usr/bin/find "$ECOLOGY_ROOT" -type f -path '*/checkpoints/ecology-final/session.json' -print -quit)
    [ -n "$FINAL_MANIFEST" ] && [ -n "$FINAL_SESSION" ] || fail "final ecology checkpoint bundle missing"
    /usr/bin/grep -q '"schemaVersion":4' "$FINAL_MANIFEST" || fail "final ecology manifest is not schema v4"
    if /usr/bin/grep -q '"health":0' "$FINAL_SESSION"; then fail "zero-health agent in final ecology checkpoint"; fi

    if /usr/bin/pgrep -x Pebble >/dev/null 2>&1 \
        || /usr/bin/pgrep -x swift-run >/dev/null 2>&1 \
        || /usr/bin/pgrep -x pebsmoke >/dev/null 2>&1; then
        fail "residual PebbleLab process after ecology proof"
    fi
    printf '\nPASS: local read-only ecology, scarcity, v4 restart, regeneration, recovery, and uninterrupted equivalence verified.\n'
    printf 'Phase 1 trace: %s\n' "$PHASE1_TRACE"
    printf 'Phase 2 trace: %s\n' "$PHASE2_TRACE"
    printf 'Control trace: %s\n' "$CONTROL_TRACE"
    printf 'Final durable digest: %s\n' "$LIVE_DIGEST"
    printf 'Ecology digest: %s\n' "$LIVE_ECOLOGY_DIGEST"
    printf 'Settlement digest: %s\n' "$LIVE_SETTLEMENT_DIGEST"
    printf 'Population digest: %s\n' "$LIVE_POPULATION_DIGEST"
    printf 'Causal digest: %s\n' "$LIVE_CAUSAL_DIGEST"
    printf 'Retained isolated session: %s\n' "$SESSION_ROOT"
    exit 0
fi

if [ "$MODE" = "multiscale" ]; then
    cd "$ROOT_DIR"
    swift build -c release --product Pebble
    PEBBLE_BINARY="$ROOT_DIR/.build/release/Pebble"
    [ -x "$PEBBLE_BINARY" ] || fail "Release Pebble binary missing: $PEBBLE_BINARY"

    PHASE1_TRACE="$SESSION_ROOT/multiscale-phase1.log"
    PHASE2_TRACE="$SESSION_ROOT/multiscale-phase2.log"
    CONTROL_HOME="$SESSION_ROOT/control-home"
    CONTROL_TRACE="$SESSION_ROOT/multiscale-control.log"
    METRICS_OFF_HOME="$SESSION_ROOT/metrics-off-home"
    METRICS_OFF_TRACE="$SESSION_ROOT/multiscale-metrics-off.log"
    [ ! -e "$CONTROL_HOME" ] || fail "fresh multiscale control home already exists: $CONTROL_HOME"
    [ ! -e "$METRICS_OFF_HOME" ] \
        || fail "fresh metrics-off control home already exists: $METRICS_OFF_HOME"

    run_multiscale_app() {
        run_home=$1
        run_trace=$2
        run_commands=$3
        create_world=$4
        command_world_tick=$5
        metrics_gate=$6
        if [ "$create_world" -eq 1 ]; then
            CFFIXED_USER_HOME="$run_home" \
            PEBBLE_AUTOLOAD=1 \
            PEBBLE_NEWWORLD="$WORLD_SEED" \
            PEBBLE_NEWWORLD_NAME="$WORLD_NAME" \
            PEBBLELAB_APP_AGENTS=1 \
            PEBBLELAB_APP_AGENTS_MOVE=1 \
            PEBBLELAB_APP_PROBES=1 \
            PEBBLELAB_DEBUG_ENTITIES=1 \
            PEBBLELAB_APP_AGENTS_OVERLAY=1 \
            PEBBLELAB_APP_AGENTS_TRACE=1 \
            PEBBLELAB_APP_AGENTS_TRACE_EVERY=1 \
            PEBBLELAB_APP_AGENTS_INTERACT=1 \
            PEBBLELAB_APP_AGENTS_NATURAL=0 \
            PEBBLELAB_APP_AGENTS_BUILD=0 \
            PEBBLELAB_APP_AGENTS_SOCIAL=0 \
            PEBBLELAB_APP_AGENTS_PHYSICAL=0 \
            PEBBLELAB_APP_AGENTS_COOPERATION=0 \
            PEBBLELAB_APP_AGENTS_PERSISTENCE=1 \
            PEBBLELAB_APP_AGENTS_POPULATION=1 \
            PEBBLELAB_APP_AGENTS_MULTISCALE="$metrics_gate" \
            PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
            PEBBLE_CMD_WORLD_TICK="$command_world_tick" \
            PEBBLE_CMD="$run_commands" \
            PEBBLE_SHOT='-|-|-|-' \
            "$PEBBLE_BINARY" 2>&1 | /usr/bin/tee "$run_trace"
        else
            CFFIXED_USER_HOME="$run_home" \
            PEBBLE_AUTOLOAD=1 \
            PEBBLELAB_APP_AGENTS=1 \
            PEBBLELAB_APP_AGENTS_MOVE=1 \
            PEBBLELAB_APP_PROBES=1 \
            PEBBLELAB_DEBUG_ENTITIES=1 \
            PEBBLELAB_APP_AGENTS_OVERLAY=1 \
            PEBBLELAB_APP_AGENTS_TRACE=1 \
            PEBBLELAB_APP_AGENTS_TRACE_EVERY=1 \
            PEBBLELAB_APP_AGENTS_INTERACT=1 \
            PEBBLELAB_APP_AGENTS_NATURAL=0 \
            PEBBLELAB_APP_AGENTS_BUILD=0 \
            PEBBLELAB_APP_AGENTS_SOCIAL=0 \
            PEBBLELAB_APP_AGENTS_PHYSICAL=0 \
            PEBBLELAB_APP_AGENTS_COOPERATION=0 \
            PEBBLELAB_APP_AGENTS_PERSISTENCE=1 \
            PEBBLELAB_APP_AGENTS_POPULATION=1 \
            PEBBLELAB_APP_AGENTS_MULTISCALE="$metrics_gate" \
            PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
            PEBBLE_CMD_WORLD_TICK="$command_world_tick" \
            PEBBLE_CMD="$run_commands" \
            PEBBLE_SHOT='-|-|-|-' \
            "$PEBBLE_BINARY" 2>&1 | /usr/bin/tee "$run_trace"
        fi
        if /usr/bin/pgrep -x Pebble >/dev/null 2>&1; then
            fail "Pebble process remained after multiscale phase: $run_trace"
        fi
    }

    printf '\nMultiscale phase 1: four micro ticks, first macro frame, and v3 checkpoint.\n'
    run_multiscale_app \
        "$SESSION_HOME" "$PHASE1_TRACE" "$MULTISCALE_PHASE1_COMMANDS" 1 100 1
    TRACE_PATH="$PHASE1_TRACE"
    require_trace 'start seed=46 agents=3 tick=0 ' 'historical three-agent bootstrap'
    require_trace 'population initialized settlement=settlement-main capacity=8 founders=3 members=3 nextOrdinal=3 ' 'three founder population registry'
    require_trace 'settlement metrics initialized tick=0 settlement=settlement-main macroSequence=0 nextPulse=4 mutation=none' 'settlement baseline at tick zero'
    require_trace 'scale microAgents=3 microTicks=every_tick macroSettlement=every_4_ticks coarseAgentExecution=off offScreenAgents=0' 'honest two-scale status before admission'
    require_trace 'migration admitted id=migration-00000003 migrant=agent_3 .*routeLength=8 ' 'deterministic migrant admission'
    require_trace 'settlement frame tick=4 id=settlement-main/frame-00000001-t4 sequence=1 window=0..4 .*coverage=complete condition=strained reason=urgent_agents population=4/8 residents=3 migrants=1 urgent=2 .*movementDelta=4 .*materialDelta=0 socialDelta=0 physicalDelta=0 cooperationDelta=0 ' 'first complete strained four-tick macro frame'
    require_trace 'settlement classifications tick=4 agent_0:microUrgent:safety,agent_1:microEngaged:micro_commitment,agent_2:microUrgent:safety,agent_3:microMigrating:migration' 'real founder urgency and migrant classification without feedback'
    require_trace 'settlement welfare tick=4 ' 'fixed-point welfare and spatial frame details'
    require_trace 'checkpoint saved name=settlement-frame-1 .*tick=4 .*restartSafe=1 ' 'restart-safe v3 checkpoint after frame one'
    require_trace 'summary .*agents=4 .*runtimeErrors=0 .*probesRemoved=4 .*naturalHarvests=0 .*buildProject=none .*conservation=0:0\+0\+0\+0\+0:exact .*causalDropped=0' 'clean four-probe phase-one cleanup'

    MULTISCALE_ROOT="$SESSION_HOME/Library/Application Support/Pebble/PebbleLabAgents"
    FRAME1_MANIFEST=$(/usr/bin/find "$MULTISCALE_ROOT" -type f -path '*/checkpoints/settlement-frame-1/manifest.json' -print -quit)
    FRAME1_SESSION=$(/usr/bin/find "$MULTISCALE_ROOT" -type f -path '*/checkpoints/settlement-frame-1/session.json' -print -quit)
    [ -n "$FRAME1_MANIFEST" ] && [ -n "$FRAME1_SESSION" ] \
        || fail "settlement v3 checkpoint bundle missing"
    /usr/bin/grep -q '"schemaVersion":3' "$FRAME1_MANIFEST" \
        || fail "settlement checkpoint manifest is not schema v3"
    /usr/bin/grep -q '"schemaVersion":3' "$FRAME1_SESSION" \
        || fail "settlement checkpoint session is not schema v3"
    /usr/bin/grep -q '"restartSafe":true' "$FRAME1_MANIFEST" \
        || fail "settlement frame-one checkpoint is not restart-safe"
    /usr/bin/grep -q '"macroSequence":1' "$FRAME1_SESSION" \
        || fail "settlement frame-one checkpoint did not retain macro sequence one"
    /usr/bin/grep -q '"lastPulseTick":4' "$FRAME1_SESSION" \
        || fail "settlement frame-one checkpoint did not retain last pulse four"
    /usr/bin/grep -q '"nextPulseTick":8' "$FRAME1_SESSION" \
        || fail "settlement frame-one checkpoint did not retain next pulse eight"

    PHASE1_DIGEST=$(/usr/bin/sed -n 's/.*checkpoint saved name=settlement-frame-1 .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' "$PHASE1_TRACE" | /usr/bin/tail -1)
    PHASE1_SIM=$(/usr/bin/sed -n 's/.*checkpoint saved name=settlement-frame-1 .* simulation=\([^ ]*\) digest=.*/\1/p' "$PHASE1_TRACE" | /usr/bin/tail -1)
    [ -n "$PHASE1_DIGEST" ] && [ -n "$PHASE1_SIM" ] \
        || fail "multiscale phase-one identity extraction failed"

    CONTROL_DB="$CONTROL_HOME/Library/Application Support/Pebble/pebble.db"
    METRICS_OFF_DB="$METRICS_OFF_HOME/Library/Application Support/Pebble/pebble.db"
    /bin/mkdir -p "$(dirname "$CONTROL_DB")" "$(dirname "$METRICS_OFF_DB")"
    [ ! -e "$CONTROL_DB" ] || fail "fresh multiscale control database already exists"
    [ ! -e "$METRICS_OFF_DB" ] || fail "fresh metrics-off database already exists"
    /usr/bin/sqlite3 "$DB_PATH" ".backup '$CONTROL_DB'"
    /usr/bin/sqlite3 "$DB_PATH" ".backup '$METRICS_OFF_DB'"
    [ -s "$CONTROL_DB" ] && [ -s "$METRICS_OFF_DB" ] \
        || fail "multiscale control database snapshots failed"
    persisted_world_tick=$(/usr/bin/sqlite3 "$DB_PATH" "SELECT json_extract(json, '$.dims.\"0\".time') FROM worlds;")
    case "$persisted_world_tick" in
        ''|*[!0-9]*) fail "invalid persisted World tick after multiscale phase 1: $persisted_world_tick" ;;
    esac
    continuation_command_tick=$((persisted_world_tick + 100))

    MULTISCALE_PHASE2_COMMANDS="$POPULATION_WORLD_READY|/lab start;/tp $POPULATION_ANCHOR_X $POPULATION_PLAYER_Y $POPULATION_ANCHOR_Z;/lab checkpoint load settlement-frame-1;/lab movement on;/lab migration status;/lab settlement status;/lab scale status"
    multiscale_step=0
    while [ "$multiscale_step" -lt 4 ]; do
        MULTISCALE_PHASE2_COMMANDS="$MULTISCALE_PHASE2_COMMANDS;/lab step"
        multiscale_step=$((multiscale_step + 1))
    done
    MULTISCALE_PHASE2_COMMANDS="$MULTISCALE_PHASE2_COMMANDS;/lab settlement status;/lab movement off"
    multiscale_step=0
    while [ "$multiscale_step" -lt 4 ]; do
        MULTISCALE_PHASE2_COMMANDS="$MULTISCALE_PHASE2_COMMANDS;/lab step"
        multiscale_step=$((multiscale_step + 1))
    done
    MULTISCALE_PHASE2_COMMANDS="$MULTISCALE_PHASE2_COMMANDS;/lab migration status;/lab population status;/lab settlement status;/lab scale status;/lab checkpoint save settlement-final;/lab checkpoint status;/lab causality status;/lab status"

    MULTISCALE_CONTROL_COMMANDS="$POPULATION_WORLD_READY|/lab start;/tp $POPULATION_ANCHOR_X $POPULATION_PLAYER_Y $POPULATION_ANCHOR_Z;/lab pause;/lab movement on;/lab population on;/lab settlement on;/lab migration admit;/lab focus agent_3;/lab follow agent_3"
    multiscale_step=0
    while [ "$multiscale_step" -lt 8 ]; do
        MULTISCALE_CONTROL_COMMANDS="$MULTISCALE_CONTROL_COMMANDS;/lab step"
        multiscale_step=$((multiscale_step + 1))
    done
    MULTISCALE_CONTROL_COMMANDS="$MULTISCALE_CONTROL_COMMANDS;/lab movement off"
    multiscale_step=0
    while [ "$multiscale_step" -lt 4 ]; do
        MULTISCALE_CONTROL_COMMANDS="$MULTISCALE_CONTROL_COMMANDS;/lab step"
        multiscale_step=$((multiscale_step + 1))
    done
    MULTISCALE_CONTROL_COMMANDS="$MULTISCALE_CONTROL_COMMANDS;/lab migration status;/lab population status;/lab settlement status;/lab scale status;/lab checkpoint save settlement-final-control;/lab checkpoint status;/lab causality status;/lab status"

    METRICS_OFF_COMMANDS="$POPULATION_WORLD_READY|/lab start;/tp $POPULATION_ANCHOR_X $POPULATION_PLAYER_Y $POPULATION_ANCHOR_Z;/lab pause;/lab movement on;/lab population on;/lab migration admit;/lab focus agent_3;/lab follow agent_3"
    multiscale_step=0
    while [ "$multiscale_step" -lt 8 ]; do
        METRICS_OFF_COMMANDS="$METRICS_OFF_COMMANDS;/lab step"
        multiscale_step=$((multiscale_step + 1))
    done
    METRICS_OFF_COMMANDS="$METRICS_OFF_COMMANDS;/lab movement off"
    multiscale_step=0
    while [ "$multiscale_step" -lt 4 ]; do
        METRICS_OFF_COMMANDS="$METRICS_OFF_COMMANDS;/lab step"
        multiscale_step=$((multiscale_step + 1))
    done
    METRICS_OFF_COMMANDS="$METRICS_OFF_COMMANDS;/lab migration status;/lab population status;/lab checkpoint save settlement-metrics-off;/lab checkpoint status;/lab causality status;/lab status"

    printf '\nMultiscale phase 2: real process restart and pulses two and three.\n'
    run_multiscale_app \
        "$SESSION_HOME" "$PHASE2_TRACE" "$MULTISCALE_PHASE2_COMMANDS" \
        0 "$continuation_command_tick" 1
    TRACE_PATH="$PHASE2_TRACE"
    require_trace "checkpoint loaded name=settlement-frame-1 .*tick=4 simulation=$PHASE1_SIM digest=$PHASE1_DIGEST .*restartSafe=1 probes=4 paused=1 focus=agent_3 lifecycleEvent=none worldMutation=none" 'exact four-agent v3 restore'
    require_trace 'settlement gate=enabled enabled=1 settlement=settlement-main microTick=4 macroInterval=4 macroSequence=1 lastPulse=4 nextPulse=8 frames=1 evicted=0 ' 'restored macro clock and frame history'
    require_trace 'settlement frame tick=8 id=settlement-main/frame-00000002-t8 sequence=2 window=4..8 .*coverage=complete condition=strained reason=urgent_agents population=4/8 residents=4 migrants=0 urgent=3 .*movementDelta=3 .*populationDelta=2 ' 'strained arrival window macro frame'
    require_trace 'settlement classifications tick=8 agent_0:microUrgent:rest,agent_1:microEngaged:micro_commitment,agent_2:microUrgent:safety,agent_3:microUrgent:rest' 'rest and safety urgency remains visible after arrival'
    require_trace 'settlement frame tick=12 id=settlement-main/frame-00000003-t12 sequence=3 window=8..12 .*coverage=complete condition=strained reason=urgent_agents population=4/8 residents=4 migrants=0 urgent=3 .*movementDelta=0 .*materialDelta=0 socialDelta=0 physicalDelta=0 cooperationDelta=0 populationDelta=0 ' 'strained quiet third macro frame'
    require_trace 'settlement classifications tick=12 agent_0:microUrgent:rest,agent_1:microEngaged:micro_commitment,agent_2:microUrgent:safety,agent_3:microUrgent:rest' 'historical urgency remains visible in the quiet frame'
    require_trace 'migration id=migration-00000003 migrant=agent_3 .*routeCursor=7 status=arrived ' 'migrant arrived after restart'
    require_trace 'settlement gate=enabled enabled=1 settlement=settlement-main microTick=12 macroInterval=4 macroSequence=3 lastPulse=12 nextPulse=16 frames=3 evicted=0 ' 'final retained three-frame state'
    require_trace 'scale microAgents=4 microTicks=every_tick macroSettlement=every_4_ticks coarseAgentExecution=off offScreenAgents=0' 'no coarse or off-screen execution'
    require_trace 'checkpoint saved name=settlement-final .*tick=12 .*restartSafe=1 ' 'restart-safe final v3 checkpoint'
    require_trace 'summary .*agents=4 .*runtimeErrors=0 .*probesRemoved=4 .*naturalHarvests=0 .*buildProject=none .*conservation=0:0\+0\+0\+0\+0:exact .*causalDropped=0' 'clean restarted multiscale cleanup'

    LIVE_DIGEST=$(/usr/bin/sed -n 's/.*checkpoint saved name=settlement-final .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' "$PHASE2_TRACE" | /usr/bin/tail -1)
    LIVE_SETTLEMENT_DIGEST=$(/usr/bin/sed -n 's/.*settlement gate=enabled .* digest=\([0-9a-f]*\)$/\1/p' "$PHASE2_TRACE" | /usr/bin/tail -1)
    LIVE_POPULATION_DIGEST=$(/usr/bin/sed -n 's/.*population gate=enabled .* digest=\([0-9a-f]*\)$/\1/p' "$PHASE2_TRACE" | /usr/bin/tail -1)
    LIVE_CAUSAL_DIGEST=$(/usr/bin/sed -n 's/.*causality status .* digest=\([0-9a-f]*\)$/\1/p' "$PHASE2_TRACE" | /usr/bin/tail -1)
    [ -n "$LIVE_DIGEST" ] && [ -n "$LIVE_SETTLEMENT_DIGEST" ] \
        && [ -n "$LIVE_POPULATION_DIGEST" ] && [ -n "$LIVE_CAUSAL_DIGEST" ] \
        || fail "multiscale final digest extraction failed"

    printf '\nMultiscale uninterrupted control.\n'
    run_multiscale_app \
        "$CONTROL_HOME" "$CONTROL_TRACE" "$MULTISCALE_CONTROL_COMMANDS" \
        0 "$continuation_command_tick" 1
    TRACE_PATH="$CONTROL_TRACE"
    require_trace 'settlement frame tick=4 id=settlement-main/frame-00000001-t4 sequence=1 .*condition=strained reason=urgent_agents ' 'uninterrupted strained frame one'
    require_trace 'settlement frame tick=8 id=settlement-main/frame-00000002-t8 sequence=2 .*condition=strained reason=urgent_agents ' 'uninterrupted strained frame two'
    require_trace 'settlement frame tick=12 id=settlement-main/frame-00000003-t12 sequence=3 .*condition=strained reason=urgent_agents ' 'uninterrupted strained frame three'
    require_trace 'summary .*agents=4 .*runtimeErrors=0 .*probesRemoved=4 .*conservation=0:0\+0\+0\+0\+0:exact .*causalDropped=0' 'clean uninterrupted multiscale cleanup'

    CONTROL_DIGEST=$(/usr/bin/sed -n 's/.*checkpoint saved name=settlement-final-control .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' "$CONTROL_TRACE" | /usr/bin/tail -1)
    CONTROL_SETTLEMENT_DIGEST=$(/usr/bin/sed -n 's/.*settlement gate=enabled .* digest=\([0-9a-f]*\)$/\1/p' "$CONTROL_TRACE" | /usr/bin/tail -1)
    CONTROL_POPULATION_DIGEST=$(/usr/bin/sed -n 's/.*population gate=enabled .* digest=\([0-9a-f]*\)$/\1/p' "$CONTROL_TRACE" | /usr/bin/tail -1)
    CONTROL_CAUSAL_DIGEST=$(/usr/bin/sed -n 's/.*causality status .* digest=\([0-9a-f]*\)$/\1/p' "$CONTROL_TRACE" | /usr/bin/tail -1)
    [ "$CONTROL_DIGEST" = "$LIVE_DIGEST" ] \
        || fail "multiscale restart/uninterrupted durable digest mismatch"
    [ "$CONTROL_SETTLEMENT_DIGEST" = "$LIVE_SETTLEMENT_DIGEST" ] \
        || fail "multiscale restart/uninterrupted settlement digest mismatch"
    [ "$CONTROL_POPULATION_DIGEST" = "$LIVE_POPULATION_DIGEST" ] \
        || fail "multiscale restart/uninterrupted population digest mismatch"
    [ "$CONTROL_CAUSAL_DIGEST" = "$LIVE_CAUSAL_DIGEST" ] \
        || fail "multiscale restart/uninterrupted causal digest mismatch"

    /usr/bin/grep -E '^\[lab-live\] tick=([5-9]|1[0-2]) ' "$PHASE2_TRACE" \
        > "$SESSION_ROOT/restart-micro.normalized"
    /usr/bin/grep -E '^\[lab-live\] tick=([5-9]|1[0-2]) ' "$CONTROL_TRACE" \
        > "$SESSION_ROOT/control-micro.normalized"
    /usr/bin/cmp "$SESSION_ROOT/restart-micro.normalized" "$SESSION_ROOT/control-micro.normalized" \
        || fail "multiscale restart and uninterrupted micro traces differ"
    {
        /usr/bin/grep -E '^\[lab-live\] settlement (frame|classifications|welfare) tick=4 ' "$PHASE1_TRACE"
        /usr/bin/grep -E '^\[lab-live\] settlement (frame|classifications|welfare) tick=(8|12) ' "$PHASE2_TRACE"
    } > "$SESSION_ROOT/restart-macro.normalized"
    /usr/bin/grep -E '^\[lab-live\] settlement (frame|classifications|welfare) tick=(4|8|12) ' "$CONTROL_TRACE" \
        > "$SESSION_ROOT/control-macro.normalized"
    /usr/bin/cmp "$SESSION_ROOT/restart-macro.normalized" "$SESSION_ROOT/control-macro.normalized" \
        || fail "multiscale restart and uninterrupted macro traces differ"

    printf '\nMultiscale metrics-off behavioral control.\n'
    run_multiscale_app \
        "$METRICS_OFF_HOME" "$METRICS_OFF_TRACE" "$METRICS_OFF_COMMANDS" \
        0 "$continuation_command_tick" 0
    TRACE_PATH="$METRICS_OFF_TRACE"
    reject_trace 'settlement metrics initialized|settlement frame tick=|settlement classifications tick=' 'settlement metrics while the gate is off'
    require_trace 'migration id=migration-00000003 migrant=agent_3 .*routeCursor=7 status=arrived ' 'metrics-off migrant arrival'
    require_trace 'checkpoint saved name=settlement-metrics-off .*tick=12 .*restartSafe=1 ' 'metrics-off v2 checkpoint'
    require_trace 'summary .*agents=4 .*runtimeErrors=0 .*probesRemoved=4 .*conservation=0:0\+0\+0\+0\+0:exact .*causalDropped=0' 'clean metrics-off control cleanup'
    METRICS_OFF_MANIFEST=$(/usr/bin/find "$METRICS_OFF_HOME/Library/Application Support/Pebble/PebbleLabAgents" -type f -path '*/checkpoints/settlement-metrics-off/manifest.json' -print -quit)
    [ -n "$METRICS_OFF_MANIFEST" ] || fail "metrics-off checkpoint manifest missing"
    /usr/bin/grep -q '"schemaVersion":2' "$METRICS_OFF_MANIFEST" \
        || fail "metrics-off population checkpoint is not unchanged schema v2"

    /usr/bin/grep -E '^\[lab-live\] tick=([1-9]|1[0-2]) ' "$CONTROL_TRACE" \
        > "$SESSION_ROOT/metrics-on-micro.normalized"
    /usr/bin/grep -E '^\[lab-live\] tick=([1-9]|1[0-2]) ' "$METRICS_OFF_TRACE" \
        > "$SESSION_ROOT/metrics-off-micro.normalized"
    /usr/bin/cmp "$SESSION_ROOT/metrics-on-micro.normalized" "$SESSION_ROOT/metrics-off-micro.normalized" \
        || fail "settlement metrics changed a micro decision or material outcome"

    if /usr/bin/pgrep -x Pebble >/dev/null 2>&1 \
        || /usr/bin/pgrep -x swift-run >/dev/null 2>&1 \
        || /usr/bin/pgrep -x pebsmoke >/dev/null 2>&1; then
        fail "residual PebbleLab process after multiscale proof"
    fi
    printf '\nPASS: bounded settlement pulses, v3 restart, uninterrupted equivalence, and metrics-off cognitive neutrality verified.\n'
    printf 'Phase 1 trace: %s\n' "$PHASE1_TRACE"
    printf 'Phase 2 trace: %s\n' "$PHASE2_TRACE"
    printf 'Control trace: %s\n' "$CONTROL_TRACE"
    printf 'Metrics-off trace: %s\n' "$METRICS_OFF_TRACE"
    printf 'Final durable digest: %s\n' "$LIVE_DIGEST"
    printf 'Settlement digest: %s\n' "$LIVE_SETTLEMENT_DIGEST"
    printf 'Population digest: %s\n' "$LIVE_POPULATION_DIGEST"
    printf 'Causal digest: %s\n' "$LIVE_CAUSAL_DIGEST"
    printf 'Retained isolated session: %s\n' "$SESSION_ROOT"
    exit 0
fi

if [ "$MODE" = "population" ]; then
    cd "$ROOT_DIR"
    swift build -c release --product Pebble
    PEBBLE_BINARY="$ROOT_DIR/.build/release/Pebble"
    [ -x "$PEBBLE_BINARY" ] || fail "Release Pebble binary missing: $PEBBLE_BINARY"

    PHASE1_TRACE="$SESSION_ROOT/population-phase1.log"
    PHASE2_TRACE="$SESSION_ROOT/population-phase2.log"
    CONTROL_HOME="$SESSION_ROOT/control-home"
    CONTROL_TRACE="$SESSION_ROOT/population-control.log"
    [ ! -e "$CONTROL_HOME" ] || fail "fresh population control home already exists: $CONTROL_HOME"

    run_population_app() {
        run_home=$1
        run_trace=$2
        run_commands=$3
        create_world=$4
        command_world_tick=$5
        if [ "$create_world" -eq 1 ]; then
            CFFIXED_USER_HOME="$run_home" \
            PEBBLE_AUTOLOAD=1 \
            PEBBLE_NEWWORLD="$WORLD_SEED" \
            PEBBLE_NEWWORLD_NAME="$WORLD_NAME" \
            PEBBLELAB_APP_AGENTS=1 \
            PEBBLELAB_APP_AGENTS_MOVE=1 \
            PEBBLELAB_APP_PROBES=1 \
            PEBBLELAB_DEBUG_ENTITIES=1 \
            PEBBLELAB_APP_AGENTS_OVERLAY=1 \
            PEBBLELAB_APP_AGENTS_TRACE=1 \
            PEBBLELAB_APP_AGENTS_TRACE_EVERY=1 \
            PEBBLELAB_APP_AGENTS_INTERACT=1 \
            PEBBLELAB_APP_AGENTS_NATURAL=0 \
            PEBBLELAB_APP_AGENTS_BUILD=0 \
            PEBBLELAB_APP_AGENTS_SOCIAL=0 \
            PEBBLELAB_APP_AGENTS_PHYSICAL=0 \
            PEBBLELAB_APP_AGENTS_COOPERATION=0 \
            PEBBLELAB_APP_AGENTS_PERSISTENCE=1 \
            PEBBLELAB_APP_AGENTS_POPULATION=1 \
            PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
            PEBBLE_CMD_WORLD_TICK="$command_world_tick" \
            PEBBLE_CMD="$run_commands" \
            PEBBLE_SHOT='-|-|-' \
            "$PEBBLE_BINARY" 2>&1 | /usr/bin/tee "$run_trace"
        else
            CFFIXED_USER_HOME="$run_home" \
            PEBBLE_AUTOLOAD=1 \
            PEBBLELAB_APP_AGENTS=1 \
            PEBBLELAB_APP_AGENTS_MOVE=1 \
            PEBBLELAB_APP_PROBES=1 \
            PEBBLELAB_DEBUG_ENTITIES=1 \
            PEBBLELAB_APP_AGENTS_OVERLAY=1 \
            PEBBLELAB_APP_AGENTS_TRACE=1 \
            PEBBLELAB_APP_AGENTS_TRACE_EVERY=1 \
            PEBBLELAB_APP_AGENTS_INTERACT=1 \
            PEBBLELAB_APP_AGENTS_NATURAL=0 \
            PEBBLELAB_APP_AGENTS_BUILD=0 \
            PEBBLELAB_APP_AGENTS_SOCIAL=0 \
            PEBBLELAB_APP_AGENTS_PHYSICAL=0 \
            PEBBLELAB_APP_AGENTS_COOPERATION=0 \
            PEBBLELAB_APP_AGENTS_PERSISTENCE=1 \
            PEBBLELAB_APP_AGENTS_POPULATION=1 \
            PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
            PEBBLE_CMD_WORLD_TICK="$command_world_tick" \
            PEBBLE_CMD="$run_commands" \
            PEBBLE_SHOT='-|-|-' \
            "$PEBBLE_BINARY" 2>&1 | /usr/bin/tee "$run_trace"
        fi
        if /usr/bin/pgrep -x Pebble >/dev/null 2>&1; then
            fail "Pebble process remained after population phase: $run_trace"
        fi
    }

    printf '\nPopulation phase 1: deterministic admission and restart-safe mid-route checkpoint.\n'
    run_population_app "$SESSION_HOME" "$PHASE1_TRACE" "$POPULATION_PHASE1_COMMANDS" 1 100
    TRACE_PATH="$PHASE1_TRACE"
    require_trace 'start seed=46 agents=3 tick=0 ' 'historical three-agent bootstrap'
    require_trace 'population initialized settlement=settlement-main capacity=8 founders=3 members=3 nextOrdinal=3 ' 'three founder population registry'
    require_trace 'migration admitted id=migration-00000003 migrant=agent_3 origin=outside-north destination=settlement-main .*routeLength=[5-9][0-9]*|migration admitted id=migration-00000003 migrant=agent_3 origin=outside-north destination=settlement-main .*routeLength=[5-9]' 'bounded deterministic migrant admission'
    require_trace 'migration id=migration-00000003 migrant=agent_3 origin=outside-north destination=settlement-main .*routeCursor=2 status=inTransit ' 'two successful migrant movements before checkpoint'
    require_trace 'checkpoint saved name=migration-mid-route .*tick=2 .*restartSafe=1 ' 'restart-safe mid-route checkpoint'
    require_trace 'summary .*agents=4 .*runtimeErrors=0 .*probesRemoved=4 .*naturalHarvests=0 .*buildProject=none .*conservation=0:0\+0\+0\+0\+0:exact .*causalDropped=0' 'clean four-probe phase-one cleanup'

    POPULATION_ROOT="$SESSION_HOME/Library/Application Support/Pebble/PebbleLabAgents"
    MID_MANIFEST=$(/usr/bin/find "$POPULATION_ROOT" -type f -path '*/checkpoints/migration-mid-route/manifest.json' -print -quit)
    MID_SESSION=$(/usr/bin/find "$POPULATION_ROOT" -type f -path '*/checkpoints/migration-mid-route/session.json' -print -quit)
    [ -n "$MID_MANIFEST" ] && [ -n "$MID_SESSION" ] \
        || fail "population v2 checkpoint bundle missing"
    /usr/bin/grep -q '"schemaVersion":2' "$MID_MANIFEST" \
        || fail "population checkpoint manifest is not schema v2"
    /usr/bin/grep -q '"schemaVersion":2' "$MID_SESSION" \
        || fail "population checkpoint session is not schema v2"
    /usr/bin/grep -q '"restartSafe":true' "$MID_MANIFEST" \
        || fail "population mid-route checkpoint is not restart-safe"

    PHASE1_DIGEST=$(/usr/bin/sed -n 's/.*checkpoint saved name=migration-mid-route .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' "$PHASE1_TRACE" | /usr/bin/tail -1)
    PHASE1_SIM=$(/usr/bin/sed -n 's/.*checkpoint saved name=migration-mid-route .* simulation=\([^ ]*\) digest=.*/\1/p' "$PHASE1_TRACE" | /usr/bin/tail -1)
    ROUTE_LENGTH=$(/usr/bin/sed -n 's/.*migration id=migration-00000003 .* routeLength=\([0-9]*\) routeCursor=2 status=inTransit.*/\1/p' "$PHASE1_TRACE" | /usr/bin/tail -1)
    [ -n "$PHASE1_DIGEST" ] && [ -n "$PHASE1_SIM" ] && [ -n "$ROUTE_LENGTH" ] \
        || fail "population phase-one identity or route extraction failed"
    case "$ROUTE_LENGTH" in
        ''|*[!0-9]*) fail "invalid migration route length: $ROUTE_LENGTH" ;;
    esac
    remaining_steps=$((ROUTE_LENGTH - 3))
    total_steps=$((ROUTE_LENGTH - 1))
    [ "$remaining_steps" -ge 1 ] \
        || fail "migration route did not remain active after two movements: length=$ROUTE_LENGTH"

    CONTROL_DB="$CONTROL_HOME/Library/Application Support/Pebble/pebble.db"
    /bin/mkdir -p "$(dirname "$CONTROL_DB")"
    [ ! -e "$CONTROL_DB" ] || fail "fresh population control database already exists: $CONTROL_DB"
    /usr/bin/sqlite3 "$DB_PATH" ".backup '$CONTROL_DB'"
    [ -s "$CONTROL_DB" ] || fail "population control database snapshot failed"
    persisted_world_tick=$(/usr/bin/sqlite3 "$DB_PATH" "SELECT json_extract(json, '$.dims.\"0\".time') FROM worlds;")
    case "$persisted_world_tick" in
        ''|*[!0-9]*) fail "invalid persisted World tick after population phase 1: $persisted_world_tick" ;;
    esac
    continuation_command_tick=$((persisted_world_tick + 100))

    POPULATION_PHASE2_COMMANDS="$POPULATION_WORLD_READY|/lab start;/tp $POPULATION_ANCHOR_X $POPULATION_PLAYER_Y $POPULATION_ANCHOR_Z;/lab checkpoint load migration-mid-route;/lab migration status"
    population_step=0
    while [ "$population_step" -lt "$remaining_steps" ]; do
        POPULATION_PHASE2_COMMANDS="$POPULATION_PHASE2_COMMANDS;/lab step"
        population_step=$((population_step + 1))
    done
    POPULATION_PHASE2_COMMANDS="$POPULATION_PHASE2_COMMANDS;/lab migration status;/lab population status;/lab checkpoint save migration-arrived;/lab checkpoint status;/lab causality status;/lab status"

    POPULATION_CONTROL_COMMANDS="$POPULATION_WORLD_READY|/lab start;/tp $POPULATION_ANCHOR_X $POPULATION_PLAYER_Y $POPULATION_ANCHOR_Z;/lab pause;/lab movement on;/lab population on;/lab migration admit;/lab focus agent_3;/lab follow agent_3"
    population_step=0
    while [ "$population_step" -lt "$total_steps" ]; do
        POPULATION_CONTROL_COMMANDS="$POPULATION_CONTROL_COMMANDS;/lab step"
        population_step=$((population_step + 1))
    done
    POPULATION_CONTROL_COMMANDS="$POPULATION_CONTROL_COMMANDS;/lab migration status;/lab population status;/lab checkpoint save migration-arrived-control;/lab checkpoint status;/lab causality status;/lab status"

    printf '\nPopulation phase 2: real process restart and physical arrival.\n'
    run_population_app "$SESSION_HOME" "$PHASE2_TRACE" "$POPULATION_PHASE2_COMMANDS" 0 "$continuation_command_tick"
    TRACE_PATH="$PHASE2_TRACE"
    require_trace "checkpoint loaded name=migration-mid-route .*tick=2 simulation=$PHASE1_SIM digest=$PHASE1_DIGEST .*restartSafe=1 probes=4 paused=1 focus=agent_3 lifecycleEvent=none worldMutation=none" 'exact four-agent checkpoint restore'
    require_trace 'migration id=migration-00000003 migrant=agent_3 origin=outside-north destination=settlement-main .*status=arrived ' 'migrant arrived after restart'
    require_trace 'population gate=enabled enabled=1 settlement=settlement-main capacity=8 members=4 founders=3 residents=4 migrating=0 nextOrdinal=4 activeMigration=0 latestMigrant=agent_3 latestMigrationStatus=arrived ' 'final four-resident registry'
    require_trace 'checkpoint saved name=migration-arrived .*restartSafe=1 ' 'restart-safe final population checkpoint'
    require_trace 'summary .*agents=4 .*runtimeErrors=0 .*probesRemoved=4 .*naturalHarvests=0 .*buildProject=none .*conservation=0:0\+0\+0\+0\+0:exact .*causalDropped=0' 'clean restarted population cleanup'
    require_trace 'population summary enabled=1 settlement=settlement-main members=4/8 founders=3 residents=4 migrating=0 active=0 arrived=1 rejected=0 failed=0 nextOrdinal=4 ' 'retained population evidence after cleanup'

    LIVE_DIGEST=$(/usr/bin/sed -n 's/.*checkpoint saved name=migration-arrived .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' "$PHASE2_TRACE" | /usr/bin/tail -1)
    LIVE_POPULATION_DIGEST=$(/usr/bin/sed -n 's/.*population gate=enabled .* digest=\([0-9a-f]*\)$/\1/p' "$PHASE2_TRACE" | /usr/bin/tail -1)
    LIVE_CAUSAL_SEQUENCE=$(/usr/bin/sed -n 's/.*causality status .* nextSequence=\([0-9]*\) retainedEventCount=.*/\1/p' "$PHASE2_TRACE" | /usr/bin/tail -1)
    LIVE_CAUSAL_DIGEST=$(/usr/bin/sed -n 's/.*causality status .* digest=\([0-9a-f]*\)$/\1/p' "$PHASE2_TRACE" | /usr/bin/tail -1)
    [ -n "$LIVE_DIGEST" ] && [ -n "$LIVE_POPULATION_DIGEST" ] \
        && [ -n "$LIVE_CAUSAL_SEQUENCE" ] && [ -n "$LIVE_CAUSAL_DIGEST" ] \
        || fail "population final digest extraction failed"

    printf '\nPopulation uninterrupted control.\n'
    run_population_app "$CONTROL_HOME" "$CONTROL_TRACE" "$POPULATION_CONTROL_COMMANDS" 0 "$continuation_command_tick"
    TRACE_PATH="$CONTROL_TRACE"
    require_trace 'migration id=migration-00000003 migrant=agent_3 origin=outside-north destination=settlement-main .*status=arrived ' 'uninterrupted migrant arrival'
    require_trace 'population gate=enabled enabled=1 settlement=settlement-main capacity=8 members=4 founders=3 residents=4 migrating=0 nextOrdinal=4 activeMigration=0 latestMigrant=agent_3 latestMigrationStatus=arrived ' 'uninterrupted four-resident registry'
    require_trace 'summary .*agents=4 .*runtimeErrors=0 .*probesRemoved=4 .*naturalHarvests=0 .*buildProject=none .*conservation=0:0\+0\+0\+0\+0:exact .*causalDropped=0' 'clean uninterrupted population cleanup'

    CONTROL_DIGEST=$(/usr/bin/sed -n 's/.*checkpoint saved name=migration-arrived-control .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' "$CONTROL_TRACE" | /usr/bin/tail -1)
    CONTROL_POPULATION_DIGEST=$(/usr/bin/sed -n 's/.*population gate=enabled .* digest=\([0-9a-f]*\)$/\1/p' "$CONTROL_TRACE" | /usr/bin/tail -1)
    CONTROL_CAUSAL_SEQUENCE=$(/usr/bin/sed -n 's/.*causality status .* nextSequence=\([0-9]*\) retainedEventCount=.*/\1/p' "$CONTROL_TRACE" | /usr/bin/tail -1)
    CONTROL_CAUSAL_DIGEST=$(/usr/bin/sed -n 's/.*causality status .* digest=\([0-9a-f]*\)$/\1/p' "$CONTROL_TRACE" | /usr/bin/tail -1)
    [ "$CONTROL_DIGEST" = "$LIVE_DIGEST" ] \
        || fail "population restart/uninterrupted durable digest mismatch: restart=$LIVE_DIGEST control=$CONTROL_DIGEST"
    [ "$CONTROL_POPULATION_DIGEST" = "$LIVE_POPULATION_DIGEST" ] \
        || fail "population restart/uninterrupted registry digest mismatch"
    [ "$CONTROL_CAUSAL_SEQUENCE" = "$LIVE_CAUSAL_SEQUENCE" ] \
        || fail "population restart/uninterrupted causal sequence mismatch"
    [ "$CONTROL_CAUSAL_DIGEST" = "$LIVE_CAUSAL_DIGEST" ] \
        || fail "population restart/uninterrupted causal digest mismatch"

    /usr/bin/grep -E '^\[lab-live\] (tick=([3-9]|[1-9][0-9]+) |population tick=([3-9]|[1-9][0-9]+) )' "$PHASE2_TRACE" > "$SESSION_ROOT/restart-population.normalized"
    /usr/bin/grep -E '^\[lab-live\] (tick=([3-9]|[1-9][0-9]+) |population tick=([3-9]|[1-9][0-9]+) )' "$CONTROL_TRACE" > "$SESSION_ROOT/control-population.normalized"
    /usr/bin/cmp "$SESSION_ROOT/restart-population.normalized" "$SESSION_ROOT/control-population.normalized" \
        || fail "population restart and uninterrupted decision traces differ"

    if /usr/bin/pgrep -x Pebble >/dev/null 2>&1 \
        || /usr/bin/pgrep -x swift-run >/dev/null 2>&1 \
        || /usr/bin/pgrep -x pebsmoke >/dev/null 2>&1; then
        fail "residual PebbleLab process after population proof"
    fi
    printf '\nPASS: bounded population admission, v2 mid-route restart, physical arrival, and uninterrupted equivalence verified.\n'
    printf 'Phase 1 trace: %s\n' "$PHASE1_TRACE"
    printf 'Phase 2 trace: %s\n' "$PHASE2_TRACE"
    printf 'Control trace: %s\n' "$CONTROL_TRACE"
    printf 'Final durable digest: %s\n' "$LIVE_DIGEST"
    printf 'Population digest: %s\n' "$LIVE_POPULATION_DIGEST"
    printf 'Causal digest: %s\n' "$LIVE_CAUSAL_DIGEST"
    printf 'Retained isolated session: %s\n' "$SESSION_ROOT"
    exit 0
fi

if [ "$MODE" = "skills" ]; then
    cd "$ROOT_DIR"
    swift build -c release --product Pebble
    PEBBLE_BINARY="$ROOT_DIR/.build/release/Pebble"
    [ -x "$PEBBLE_BINARY" ] || fail "Release Pebble binary missing: $PEBBLE_BINARY"

    PHASE1_TRACE="$SESSION_ROOT/skills-phase1.log"
    RESTART_TRACE="$SESSION_ROOT/skills-restart.log"
    FAILURE_HOME="$SESSION_ROOT/skills-failure-home"
    FAILURE_TRACE="$SESSION_ROOT/skills-late-failure.log"
    CONTROL_HOME="$SESSION_ROOT/skills-control-home"
    CONTROL_TRACE="$SESSION_ROOT/skills-control.log"

    run_skills_app() {
        run_home=$1
        run_trace=$2
        run_commands=$3
        create_world=$4
        command_world_tick=$5
        late_failure=${6:-0}
        if [ "$create_world" -eq 1 ]; then
            CFFIXED_USER_HOME="$run_home" \
            PEBBLE_AUTOLOAD=1 \
            PEBBLE_NEWWORLD="$WORLD_SEED" \
            PEBBLE_NEWWORLD_NAME="$WORLD_NAME" \
            PEBBLELAB_APP_AGENTS=1 \
            PEBBLELAB_APP_AGENTS_MOVE=1 \
            PEBBLELAB_APP_PROBES=1 \
            PEBBLELAB_DEBUG_ENTITIES=1 \
            PEBBLELAB_APP_AGENTS_OVERLAY=1 \
            PEBBLELAB_APP_AGENTS_TRACE=1 \
            PEBBLELAB_APP_AGENTS_TRACE_EVERY=1 \
            PEBBLELAB_APP_AGENTS_INTERACT=1 \
            PEBBLELAB_APP_AGENTS_NATURAL=1 \
            PEBBLELAB_APP_AGENTS_BUILD=1 \
            PEBBLELAB_APP_AGENTS_SOCIAL=1 \
            PEBBLELAB_APP_AGENTS_PHYSICAL=1 \
            PEBBLELAB_APP_AGENTS_COOPERATION=1 \
            PEBBLELAB_APP_AGENTS_PERSISTENCE=1 \
            PEBBLELAB_APP_AGENTS_POPULATION=1 \
            PEBBLELAB_APP_AGENTS_MULTISCALE=1 \
            PEBBLELAB_APP_AGENTS_ECOLOGY=1 \
            PEBBLELAB_APP_AGENTS_LIFECYCLE=1 \
            PEBBLELAB_APP_AGENTS_SKILLS=1 \
            PEBBLELAB_DISPOSABLE_SKILL_LATE_FAILURE_PROOF="$late_failure" \
            PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
            PEBBLE_CMD_WORLD_TICK="$command_world_tick" \
            PEBBLE_CMD="$run_commands" \
            PEBBLE_SHOT="${run_trace%.log}.png" \
            "$PEBBLE_BINARY" 2>&1 | /usr/bin/tee "$run_trace"
        else
            CFFIXED_USER_HOME="$run_home" \
            PEBBLE_AUTOLOAD=1 \
            PEBBLELAB_APP_AGENTS=1 \
            PEBBLELAB_APP_AGENTS_MOVE=1 \
            PEBBLELAB_APP_PROBES=1 \
            PEBBLELAB_DEBUG_ENTITIES=1 \
            PEBBLELAB_APP_AGENTS_OVERLAY=1 \
            PEBBLELAB_APP_AGENTS_TRACE=1 \
            PEBBLELAB_APP_AGENTS_TRACE_EVERY=1 \
            PEBBLELAB_APP_AGENTS_INTERACT=1 \
            PEBBLELAB_APP_AGENTS_NATURAL=1 \
            PEBBLELAB_APP_AGENTS_BUILD=1 \
            PEBBLELAB_APP_AGENTS_SOCIAL=1 \
            PEBBLELAB_APP_AGENTS_PHYSICAL=1 \
            PEBBLELAB_APP_AGENTS_COOPERATION=1 \
            PEBBLELAB_APP_AGENTS_PERSISTENCE=1 \
            PEBBLELAB_APP_AGENTS_POPULATION=1 \
            PEBBLELAB_APP_AGENTS_MULTISCALE=1 \
            PEBBLELAB_APP_AGENTS_ECOLOGY=1 \
            PEBBLELAB_APP_AGENTS_LIFECYCLE=1 \
            PEBBLELAB_APP_AGENTS_SKILLS=1 \
            PEBBLELAB_DISPOSABLE_SKILL_LATE_FAILURE_PROOF="$late_failure" \
            PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
            PEBBLE_CMD_WORLD_TICK="$command_world_tick" \
            PEBBLE_CMD="$run_commands" \
            PEBBLE_SHOT="${run_trace%.log}.png" \
            "$PEBBLE_BINARY" 2>&1 | /usr/bin/tee "$run_trace"
        fi
        if /usr/bin/pgrep -x Pebble >/dev/null 2>&1; then
            fail "Pebble process remained after skills phase: $run_trace"
        fi
    }

    printf '\nSkills phase 1: material practice, ranked matching, and v10 checkpoint.\n'
    run_skills_app "$SESSION_HOME" "$PHASE1_TRACE" "$SKILLS_PHASE1_COMMANDS" 1 100 0
    TRACE_PATH="$PHASE1_TRACE"
    require_trace 'skills tick=0 profiles=0 credits=0 units=0 profilesState= digest=[0-9a-f]+' 'explicit zero-retroactive v10 activation'
    require_trace "skills tick=$SKILLS_PRACTICE_TICK profiles=2 credits=10 units=10 profilesState=agent_0:foraging=3/practiced,materialHandling=1/novice,construction=0/untrained,caregiving=0/untrained;agent_1:foraging=4/practiced,materialHandling=2/novice,construction=0/untrained,caregiving=0/untrained digest=[0-9a-f]+" 'real unequal material practice before matching'
    require_trace "cooperation task tick=$SKILLS_TASK_TICK id=task-.* issuer=agent_2 helper=agent_1 resource=stone requested=3 .*status=draft .*reason=direct_builder_demand_and_resource_fact;_skill=materialHandling:2/novice" 'real skill-ranked cooperative task'
    require_trace "checkpoint saved name=skills-v10 .*tick=$SKILLS_FINAL_TICK .*restartSafe=1 " 'restart-safe v10 checkpoint'
    require_trace 'summary .*runtimeErrors=0 .*probesRemoved=4 ' 'clean skills phase-one shutdown'
    reject_trace 'skills late-failure|runtime error|worldMutation=(block|world)' 'unexpected failure or World mutation in safe phase'

    SKILLS_ROOT="$SESSION_HOME/Library/Application Support/Pebble/PebbleLabAgents"
    SKILLS_MANIFEST=$(/usr/bin/find "$SKILLS_ROOT" -type f -path '*/checkpoints/skills-v10/manifest.json' -print -quit)
    SKILLS_SESSION=$(/usr/bin/find "$SKILLS_ROOT" -type f -path '*/checkpoints/skills-v10/session.json' -print -quit)
    [ -n "$SKILLS_MANIFEST" ] && [ -n "$SKILLS_SESSION" ] \
        || fail "skills v10 checkpoint bundle missing"
    /usr/bin/grep -q '"schemaVersion":10' "$SKILLS_SESSION" \
        || fail "skills checkpoint is not schema v10"
    /usr/bin/grep -q '"restartSafe":true' "$SKILLS_MANIFEST" \
        || fail "skills checkpoint is not restart-safe"
    PHASE1_DIGEST=$(/usr/bin/sed -n 's/.*checkpoint saved name=skills-v10 .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' "$PHASE1_TRACE" | /usr/bin/tail -1)
    PHASE1_SKILL_DIGEST=$(/usr/bin/sed -n "s/.*skills tick=$SKILLS_FINAL_TICK .* digest=\\([0-9a-f]*\\)$/\\1/p" "$PHASE1_TRACE" | /usr/bin/tail -1)
    PHASE1_SIM=$(/usr/bin/sed -n 's/.*checkpoint saved name=skills-v10 .* simulation=\([^ ]*\) digest=.*/\1/p' "$PHASE1_TRACE" | /usr/bin/tail -1)
    [ -n "$PHASE1_DIGEST" ] && [ -n "$PHASE1_SKILL_DIGEST" ] \
        && [ -n "$PHASE1_SIM" ] || fail "skills phase-one digest extraction failed"

    persisted_world_tick=$(/usr/bin/sqlite3 "$DB_PATH" "SELECT json_extract(json, '$.dims.\"0\".time') FROM worlds;")
    case "$persisted_world_tick" in
        ''|*[!0-9]*) fail "invalid persisted skills World tick: $persisted_world_tick" ;;
    esac
    restart_command_tick=$((persisted_world_tick + 100))
    printf '\nSkills phase 2: real process restart.\n'
    run_skills_app "$SESSION_HOME" "$RESTART_TRACE" "$SKILLS_RESTART_COMMANDS" 0 "$restart_command_tick" 0
    TRACE_PATH="$RESTART_TRACE"
    require_trace "checkpoint loaded name=skills-v10 .*tick=$SKILLS_FINAL_TICK simulation=$PHASE1_SIM digest=$PHASE1_DIGEST .*restartSafe=1 probes=4 paused=1" 'exact v10 load in a new process'
    require_trace "skills tick=$SKILLS_FINAL_TICK .*digest=$PHASE1_SKILL_DIGEST" 'skill profiles and digest survive restart'
    require_trace 'cooperation status gate=enabled enabled=yes .*helper=agent_1 resource=stone requested=3 .*status=draft' 'same ranked task survives restart'
    require_trace 'summary .*runtimeErrors=0 .*probesRemoved=4 ' 'clean skills restart shutdown'

    printf '\nSkills late failure: valid construction candidate plus skill credit, physical rollback.\n'
    run_skills_app "$FAILURE_HOME" "$FAILURE_TRACE" "$SKILLS_FAILURE_COMMANDS" 1 100 1
    TRACE_PATH="$FAILURE_TRACE"
    require_trace_count '^\[lab-live\] skills late-failure candidate valid=1 .*worldPlaced=1 published=0$' 1 'one fully credited unpublished construction candidate'
    require_trace_count '^\[lab-live\] skills late-failure rollback sessionBytes=exact resources=exact practiceTotals=exact records=exact levels=exact causal=exact recorder=exact probes=exact worldIndexes=exact block=restored ghostCredit=0$' 1 'exact skill and physical rollback'
    require_trace 'skills late-failure controlledError=injected_construction_publication_failure publishedSession=unchanged publishedRecorder=unchanged probes=unchanged worldIndexes=unchanged' 'one controlled late publication error at the unpublished boundary'
    require_trace 'build gate=enabled auto=on .*status=completed .*placed=9/9 ' 'positive construction completed after the one-shot rollback'
    require_trace 'summary .*runtimeErrors=1 .*probesRemoved=3 .*buildRollback=1 ' 'one controlled error and clean failure-run cleanup'

    CONTROL_COMMANDS=${SKILLS_PHASE1_COMMANDS/skills-v10/skills-v10-control}
    printf '\nSkills independent deterministic control.\n'
    run_skills_app "$CONTROL_HOME" "$CONTROL_TRACE" "$CONTROL_COMMANDS" 1 100 0
    TRACE_PATH="$CONTROL_TRACE"
    require_trace "checkpoint saved name=skills-v10-control .*tick=$SKILLS_FINAL_TICK .*restartSafe=1 " 'independent v10 control checkpoint'
    require_trace 'summary .*runtimeErrors=0 .*probesRemoved=4 ' 'clean independent control shutdown'
    CONTROL_ROOT="$CONTROL_HOME/Library/Application Support/Pebble/PebbleLabAgents"
    CONTROL_SESSION=$(/usr/bin/find "$CONTROL_ROOT" -type f -path '*/checkpoints/skills-v10-control/session.json' -print -quit)
    [ -n "$CONTROL_SESSION" ] || fail "skills control checkpoint session missing"
    /usr/bin/cmp "$SKILLS_SESSION" "$CONTROL_SESSION" \
        || fail "independent skills sessions are not byte-identical"
    CONTROL_DIGEST=$(/usr/bin/sed -n 's/.*checkpoint saved name=skills-v10-control .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' "$CONTROL_TRACE" | /usr/bin/tail -1)
    CONTROL_SKILL_DIGEST=$(/usr/bin/sed -n "s/.*skills tick=$SKILLS_FINAL_TICK .* digest=\\([0-9a-f]*\\)$/\\1/p" "$CONTROL_TRACE" | /usr/bin/tail -1)
    [ "$CONTROL_DIGEST" = "$PHASE1_DIGEST" ] \
        && [ "$CONTROL_SKILL_DIGEST" = "$PHASE1_SKILL_DIGEST" ] \
        || fail "independent skills digests differ"

    if /usr/bin/pgrep -x Pebble >/dev/null 2>&1 \
        || /usr/bin/pgrep -x swift-run >/dev/null 2>&1; then
        fail "residual Pebble process after skills proof"
    fi
    printf '\nPASS: practice-based skills, ranked task matching, v10 restart, independent determinism, and late rollback verified.\n'
    printf 'Seed: %s\n' "$WORLD_SEED"
    printf 'Phase 1 trace: %s\n' "$PHASE1_TRACE"
    printf 'Restart trace: %s\n' "$RESTART_TRACE"
    printf 'Failure trace: %s\n' "$FAILURE_TRACE"
    printf 'Control trace: %s\n' "$CONTROL_TRACE"
    printf 'Durable digest: %s\n' "$PHASE1_DIGEST"
    printf 'Skill digest: %s\n' "$PHASE1_SKILL_DIGEST"
    printf 'Retained isolated session: %s\n' "$SESSION_ROOT"
    exit 0
fi

if [ "$MODE" = "persistence" ]; then
    cd "$ROOT_DIR"
    swift build -c release --product Pebble
    PEBBLE_BINARY="$ROOT_DIR/.build/release/Pebble"
    [ -x "$PEBBLE_BINARY" ] || fail "Release Pebble binary missing: $PEBBLE_BINARY"

    PHASE1_TRACE="$SESSION_ROOT/persistence-phase1.log"
    PHASE2_TRACE="$SESSION_ROOT/persistence-phase2.log"
    CONTROL_HOME="$SESSION_ROOT/control-home"
    CONTROL_TRACE="$SESSION_ROOT/persistence-control.log"
    [ ! -e "$CONTROL_HOME" ] || fail "fresh control home already exists: $CONTROL_HOME"

    run_persistence_app() {
        run_home=$1
        run_trace=$2
        run_commands=$3
        create_world=$4
        command_world_tick=$5
        if [ "$create_world" -eq 1 ]; then
            CFFIXED_USER_HOME="$run_home" \
            PEBBLE_AUTOLOAD=1 \
            PEBBLE_NEWWORLD="$WORLD_SEED" \
            PEBBLE_NEWWORLD_NAME="$WORLD_NAME" \
            PEBBLELAB_APP_AGENTS=1 \
            PEBBLELAB_APP_AGENTS_MOVE=1 \
            PEBBLELAB_APP_PROBES=1 \
            PEBBLELAB_DEBUG_ENTITIES=1 \
            PEBBLELAB_APP_AGENTS_OVERLAY=1 \
            PEBBLELAB_APP_AGENTS_TRACE=1 \
            PEBBLELAB_APP_AGENTS_TRACE_EVERY=1 \
            PEBBLELAB_APP_AGENTS_INTERACT=1 \
            PEBBLELAB_APP_AGENTS_NATURAL=1 \
            PEBBLELAB_APP_AGENTS_BUILD=1 \
            PEBBLELAB_APP_AGENTS_SOCIAL=1 \
            PEBBLELAB_APP_AGENTS_PHYSICAL=1 \
            PEBBLELAB_APP_AGENTS_COOPERATION=1 \
            PEBBLELAB_APP_AGENTS_PERSISTENCE=1 \
            PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
            PEBBLE_CMD_WORLD_TICK="$command_world_tick" \
            PEBBLE_CMD="$run_commands" \
            PEBBLE_SHOT='-|-|-' \
            "$PEBBLE_BINARY" 2>&1 | /usr/bin/tee "$run_trace"
        else
            CFFIXED_USER_HOME="$run_home" \
            PEBBLE_AUTOLOAD=1 \
            PEBBLELAB_APP_AGENTS=1 \
            PEBBLELAB_APP_AGENTS_MOVE=1 \
            PEBBLELAB_APP_PROBES=1 \
            PEBBLELAB_DEBUG_ENTITIES=1 \
            PEBBLELAB_APP_AGENTS_OVERLAY=1 \
            PEBBLELAB_APP_AGENTS_TRACE=1 \
            PEBBLELAB_APP_AGENTS_TRACE_EVERY=1 \
            PEBBLELAB_APP_AGENTS_INTERACT=1 \
            PEBBLELAB_APP_AGENTS_NATURAL=1 \
            PEBBLELAB_APP_AGENTS_BUILD=1 \
            PEBBLELAB_APP_AGENTS_SOCIAL=1 \
            PEBBLELAB_APP_AGENTS_PHYSICAL=1 \
            PEBBLELAB_APP_AGENTS_COOPERATION=1 \
            PEBBLELAB_APP_AGENTS_PERSISTENCE=1 \
            PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
            PEBBLE_CMD_WORLD_TICK="$command_world_tick" \
            PEBBLE_CMD="$run_commands" \
            PEBBLE_SHOT='-|-|-' \
            "$PEBBLE_BINARY" 2>&1 | /usr/bin/tee "$run_trace"
        fi
        if /usr/bin/pgrep -x Pebble >/dev/null 2>&1; then
            fail "Pebble process remained after persistence phase: $run_trace"
        fi
    }

    printf '\nPersistence phase 1: accepted task and restart-safe checkpoint.\n'
    run_persistence_app "$SESSION_HOME" "$PHASE1_TRACE" "$PERSISTENCE_PHASE1_COMMANDS" 1 100
    TRACE_PATH="$PHASE1_TRACE"
    require_trace 'cooperation task tick=5 .*status=(accepted|active)' 'accepted task before checkpoint'
    reject_trace 'natural harvest actor=' 'World harvest before restart-safe checkpoint'
    reject_trace 'cooperation placement tick=' 'World placement before restart-safe checkpoint'
    require_trace 'checkpoint saved name=accepted-task .*tick=5 .*restartSafe=1 .*mutation=none' 'restart-safe checkpoint at accepted task boundary'
    require_trace 'checkpoint status gate=enabled ready=1 restartSafe=1 .*tick=5 .*recording=active' 'stable checkpoint boundary and active recorder'
    require_trace 'summary .*runtimeErrors=0 .*probesRemoved=3 .*naturalHarvests=0 .*buildPlaced=0 .*constructionRestored=1' 'clean first-process shutdown'

    PERSISTENCE_ROOT="$SESSION_HOME/Library/Application Support/Pebble/PebbleLabAgents"
    ACCEPTED_MANIFEST=$(/usr/bin/find "$PERSISTENCE_ROOT" -type f -path '*/checkpoints/accepted-task/manifest.json' -print -quit)
    [ -n "$ACCEPTED_MANIFEST" ] || fail "accepted-task manifest missing under managed root"
    /usr/bin/grep -q '"restartSafe":true' "$ACCEPTED_MANIFEST" \
        || fail "accepted-task manifest is not restart-safe"
    /usr/bin/grep -q '"focusedAgentID":"agent_2"' "$ACCEPTED_MANIFEST" \
        || fail "accepted-task manifest did not retain the decision-relevant live focus"
    PHASE1_DIGEST=$(/usr/bin/sed -n 's/.*checkpoint saved name=accepted-task .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' "$PHASE1_TRACE" | /usr/bin/tail -1)
    PHASE1_SIM=$(/usr/bin/sed -n 's/.*checkpoint saved name=accepted-task .* simulation=\([^ ]*\) digest=.*/\1/p' "$PHASE1_TRACE" | /usr/bin/tail -1)
    [ -n "$PHASE1_DIGEST" ] && [ -n "$PHASE1_SIM" ] || fail "phase-1 identity extraction failed"

    CONTROL_DB="$CONTROL_HOME/Library/Application Support/Pebble/pebble.db"
    /bin/mkdir -p "$(dirname "$CONTROL_DB")"
    [ ! -e "$CONTROL_DB" ] || fail "fresh control database already exists: $CONTROL_DB"
    /usr/bin/sqlite3 "$DB_PATH" ".backup '$CONTROL_DB'"
    [ -s "$CONTROL_DB" ] || fail "post-phase-1 control database snapshot failed"
    persisted_world_tick=$(/usr/bin/sqlite3 "$DB_PATH" "SELECT json_extract(json, '$.dims.\"0\".time') FROM worlds;")
    case "$persisted_world_tick" in
        ''|*[!0-9]*) fail "invalid persisted World tick after phase 1: $persisted_world_tick" ;;
    esac
    continuation_command_tick=$((persisted_world_tick + 100))

    printf '\nPersistence phase 2: real process restart, load, continuation, and replay.\n'
    run_persistence_app "$SESSION_HOME" "$PHASE2_TRACE" "$PERSISTENCE_PHASE2_COMMANDS" 0 "$continuation_command_tick"
    TRACE_PATH="$PHASE2_TRACE"
    require_trace "checkpoint loaded name=accepted-task .*tick=5 simulation=$PHASE1_SIM digest=$PHASE1_DIGEST .*restartSafe=1 probes=3 paused=1 focus=agent_2 lifecycleEvent=none worldMutation=none" 'exact checkpoint restore in second process'
    require_trace 'replay recording started base=accepted-task .*tick=5 .*records=0' 'replay recording resumed from restored base'
    require_trace_count 'cooperation harvest tick=[1-9][0-9]* operation=g2-natural:agent_1:.* actor=agent_1 .* resource=stone status=succeeded' 3 'three helper stone harvests after restart'
    require_trace_count 'cooperation harvest tick=[1-9][0-9]* operation=g2-natural:agent_2:.* actor=agent_2 .* resource=wood status=succeeded' 6 'six builder wood harvests after restart'
    require_trace 'cooperation task tick=[1-9][0-9]* .*contributed=3 status=completed' 'shared task completion after restart'
    require_trace 'cooperation reliability tick=[1-9][0-9]* .*score=10 completed=1 failed=0 outcome=completed' 'reliability update after restart'
    require_trace_count 'cooperation placement tick=[1-9][0-9]* .*cell=[0-8] ' 9 'nine ordered placements after restart'
    require_trace 'build gate=enabled auto=on .*status=completed .*placed=9/9 .*conservation=9:0\+0\+0\+0\+9:exact' 'completed material continuation after restart'
    require_trace 'checkpoint saved name=post-material .*restartSafe=0 ' 'unsafe post-mutation checkpoint labelled explicitly'
    require_trace 'replay recording stopped name=live-continuation .*replayable=1' 'bounded replay journal persisted'
    require_trace 'replay verified checkpoint=accepted-task journal=live-continuation .*liveMutation=none worldMutation=none' 'pure replay verified without live publication'
    require_trace 'summary .*runtimeErrors=0 .*probesRemoved=3 .*naturalHarvests=9 .*constructionRestored=1' 'second-process cleanup'

    POST_MANIFEST=$(/usr/bin/find "$PERSISTENCE_ROOT" -type f -path '*/checkpoints/post-material/manifest.json' -print -quit)
    [ -n "$POST_MANIFEST" ] || fail "post-material manifest missing under managed root"
    /usr/bin/grep -q '"restartSafe":false' "$POST_MANIFEST" \
        || fail "post-material checkpoint was incorrectly marked restart-safe"
    LIVE_DIGEST=$(/usr/bin/sed -n 's/.*checkpoint saved name=post-material .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' "$PHASE2_TRACE" | /usr/bin/tail -1)
    REPLAY_DIGEST=$(/usr/bin/sed -n 's/.*replay verified checkpoint=accepted-task journal=live-continuation .* digest=\([0-9a-f]*\) causalSequence=.*/\1/p' "$PHASE2_TRACE" | /usr/bin/tail -1)
    [ -n "$LIVE_DIGEST" ] && [ "$LIVE_DIGEST" = "$REPLAY_DIGEST" ] \
        || fail "live/replay final digest mismatch: live=$LIVE_DIGEST replay=$REPLAY_DIGEST"

    printf '\nPersistence uninterrupted control.\n'
    run_persistence_app "$CONTROL_HOME" "$CONTROL_TRACE" "$PERSISTENCE_CONTROL_COMMANDS" 0 "$continuation_command_tick"
    TRACE_PATH="$CONTROL_TRACE"
    require_trace 'checkpoint status gate=enabled ready=1 restartSafe=0 .*recording=inactive' 'uninterrupted final durable state'
    require_trace 'summary .*runtimeErrors=0 .*probesRemoved=3 .*naturalHarvests=9 .*constructionRestored=1' 'uninterrupted cleanup'
    CONTROL_DIGEST=$(/usr/bin/sed -n 's/.*checkpoint status gate=enabled .* digest=\([0-9a-f]*\) causalSequence=.*/\1/p' "$CONTROL_TRACE" | /usr/bin/tail -1)
    [ -n "$CONTROL_DIGEST" ] && [ "$CONTROL_DIGEST" = "$LIVE_DIGEST" ] \
        || fail "restart/uninterrupted digest mismatch: restart=$LIVE_DIGEST control=$CONTROL_DIGEST"

    /usr/bin/grep -E '^\[lab-live\] tick=([6-9]|[1-9][0-9]+) ' "$PHASE2_TRACE" > "$SESSION_ROOT/restart-decisions.normalized"
    /usr/bin/grep -E '^\[lab-live\] tick=([6-9]|[1-9][0-9]+) ' "$CONTROL_TRACE" > "$SESSION_ROOT/control-decisions.normalized"
    /usr/bin/cmp "$SESSION_ROOT/restart-decisions.normalized" "$SESSION_ROOT/control-decisions.normalized" \
        || fail "restart and uninterrupted decision traces differ"

    if /usr/bin/pgrep -x Pebble >/dev/null 2>&1 \
        || /usr/bin/pgrep -x swift-run >/dev/null 2>&1 \
        || /usr/bin/pgrep -x pebsmoke >/dev/null 2>&1; then
        fail "residual PebbleLab process after persistence proof"
    fi
    printf '\nPASS: restart-safe checkpoint, real process restart, pure causal replay, unsafe checkpoint labelling, and uninterrupted equivalence verified.\n'
    printf 'Phase 1 trace: %s\n' "$PHASE1_TRACE"
    printf 'Phase 2 trace: %s\n' "$PHASE2_TRACE"
    printf 'Control trace: %s\n' "$CONTROL_TRACE"
    printf 'Final durable digest: %s\n' "$LIVE_DIGEST"
    printf 'Retained isolated session: %s\n' "$SESSION_ROOT"
    exit 0
fi

cd "$ROOT_DIR"
CFFIXED_USER_HOME="$SESSION_HOME" \
PEBBLE_AUTOLOAD=1 \
PEBBLE_NEWWORLD="$WORLD_SEED" \
PEBBLE_NEWWORLD_NAME="$WORLD_NAME" \
PEBBLELAB_APP_AGENTS=1 \
PEBBLELAB_APP_AGENTS_MOVE=1 \
PEBBLELAB_APP_PROBES=1 \
PEBBLELAB_DEBUG_ENTITIES=1 \
PEBBLELAB_APP_AGENTS_OVERLAY=1 \
PEBBLELAB_APP_AGENTS_TRACE=1 \
PEBBLELAB_APP_AGENTS_TRACE_EVERY=1 \
PEBBLELAB_APP_AGENTS_INTERACT=1 \
PEBBLELAB_APP_AGENTS_NATURAL="$NATURAL_GATE" \
PEBBLELAB_APP_AGENTS_BUILD="$BUILD_GATE" \
PEBBLELAB_APP_AGENTS_SOCIAL="$SOCIAL_GATE" \
PEBBLELAB_APP_AGENTS_PHYSICAL="$PHYSICAL_GATE" \
PEBBLELAB_APP_AGENTS_MATERIAL="$MATERIAL_GATE" \
PEBBLELAB_APP_AGENTS_COOPERATION="$COOPERATION_GATE" \
PEBBLELAB_APP_AGENTS_PERSISTENCE="$PERSISTENCE_GATE" \
PEBBLELAB_APP_AGENTS_POPULATION="$POPULATION_GATE" \
PEBBLELAB_APP_AGENTS_MULTISCALE="$MULTISCALE_GATE" \
PEBBLELAB_APP_AGENTS_ECOLOGY="$ECOLOGY_GATE" \
PEBBLELAB_APP_AGENTS_MORTALITY="$MORTALITY_GATE" \
PEBBLELAB_APP_AGENTS_LIFECYCLE="$LIFECYCLE_GATE" \
PEBBLELAB_APP_AGENTS_KINSHIP="$KINSHIP_GATE" \
PEBBLELAB_APP_AGENTS_HOUSEHOLDS="$HOUSEHOLD_GATE" \
PEBBLELAB_APP_AGENTS_CARE="$CARE_GATE" \
PEBBLELAB_APP_AGENTS_SKILLS="$SKILL_GATE" \
PEBBLELAB_APP_AGENTS_TEACHING="$TEACHING_GATE" \
PEBBLELAB_APP_AGENTS_ECOLOGICAL_OBSERVATION="$ECOLOGICAL_OBSERVATION_GATE" \
PEBBLELAB_APP_AGENTS_AGRICULTURE="$AGRICULTURE_GATE" \
PEBBLELAB_APP_AGENTS_WILD_SUBSISTENCE="$WILD_SUBSISTENCE_GATE" \
PEBBLELAB_APP_AGENTS_LIVESTOCK="$LIVESTOCK_GATE" \
PEBBLELAB_APP_AGENTS_WORK_PROFESSIONS="$WORK_PROFESSIONS_GATE" \
PEBBLELAB_APP_AGENTS_PRODUCTION="$PRODUCTION_GATE" \
PEBBLELAB_APP_AGENTS_BARTER="$BARTER_GATE" \
PEBBLELAB_APP_AGENTS_CONTRACTS="$CONTRACT_GATE" \
PEBBLELAB_APP_AGENTS_AUTONOMOUS_CIVILIZATION="$AUTONOMOUS_CIVILIZATION_GATE" \
PEBBLELAB_INTEGRATED_TEACHING_PROOF="$INTEGRATED_TEACHING_PROOF" \
PEBBLELAB_PASSIVE_OBSERVER_INPUT_PROOF="$PASSIVE_OBSERVER_INPUT_PROOF" \
PEBBLELAB_PASSIVE_OBSERVER_BATCH_FRAMES="$PASSIVE_OBSERVER_BATCH_FRAMES" \
PEBBLELAB_WORK_DEMAND_REFRESH_PROOF="$WORK_DEMAND_REFRESH_PROOF" \
PEBBLELAB_WORK_DEMAND_REFRESH_CAPTURE_DIR="$CAPTURE_DIR" \
PEBBLELAB_GATE_B3_ACCEPTANCE="$GATE_B3_ACCEPTANCE" \
PEBBLELAB_GATE_B3_COGNITIVE_HZ="$GATE_B3_COGNITIVE_HZ" \
PEBBLELAB_GATE_B3_HORIZON="$GATE_B3_HORIZON" \
PEBBLELAB_GATE_B3_RANDOM_TICK_SPEED="$GATE_B3_RANDOM_TICK_SPEED" \
PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
PEBBLE_CMD="$LAB_COMMANDS" \
PEBBLE_SHOT="$SHOT_SPEC" \
swift run -c release Pebble 2>&1 | /usr/bin/tee "$TRACE_PATH"

if /usr/bin/pgrep -x Pebble >/dev/null 2>&1; then
    fail "Pebble process remained after the isolated live run"
fi
[ -f "$DB_PATH" ] || fail "disposable database was not created: $DB_PATH"
world_facts=$(/usr/bin/sqlite3 "$DB_PATH" "SELECT count(*), json_extract(json, '$.seed'), json_extract(json, '$.name'), json_extract(json, '$.dims.\"0\".dayTime'), json_extract(json, '$.dims.\"0\".raining'), json_extract(json, '$.dims.\"0\".thundering'), json_extract(json, '$.gameRules.doMobSpawning'), json_extract(json, '$.gameRules.doDaylightCycle'), json_extract(json, '$.gameRules.doWeatherCycle') FROM worlds;")
expected_world_facts="1|$WORLD_SEED|$WORLD_NAME|1000|0|0|0|0|0"
[ "$world_facts" = "$expected_world_facts" ] \
    || fail "unexpected disposable world facts: $world_facts"
if [ "$MODE" = "build" ] || [ "$MODE" = "social" ] || [ "$MODE" = "physical" ] || [ "$MODE" = "material" ] || [ "$MODE" = "rights" ] || [ "$MODE" = "cooperation" ] || [ "$MODE" = "harvest" ] || [ "$MODE" = "construction" ] || [ "$MODE" = "embodiment" ] || [ "$MODE" = "teaching" ] || [ "$MODE" = "integrated-teaching" ] || [ "$MODE" = "ecological-observation" ] || [ "$MODE" = "agriculture" ] || [ "$MODE" = "wild-subsistence" ] || [ "$MODE" = "physical-food-survival" ] || [ "$MODE" = "livestock" ] || [ "$MODE" = "work-professions" ] || [ "$MODE" = "work-demand-refresh" ] || [ "$MODE" = "gate-b-passive" ]; then
    spawn_facts=$(/usr/bin/sqlite3 "$DB_PATH" "SELECT json_extract(json, '$.spawnX'), json_extract(json, '$.spawnY'), json_extract(json, '$.spawnZ') FROM worlds;")
    [ "$spawn_facts" = "8|75|-112" ] || fail "unexpected seed-46 spawn: $spawn_facts"
fi

require_trace "disposable-world name=$WORLD_NAME seed=$WORLD_SEED worldTick=0 dayTime=1000 weather=clear randomTickSpeed=0 mobSpawning=0" 'deterministic disposable world initialization'
EXPECTED_START_RANDOM_TICK_SPEED=0
if [ "$MODE" = "work-demand-refresh" ]; then
    EXPECTED_START_RANDOM_TICK_SPEED="$GATE_B3_RANDOM_TICK_SPEED"
fi
require_trace "start seed=$WORLD_SEED agents=3 tick=0 hz=4 movement=on worldTick=[0-9]+ dayTime=1000 weather=clear randomTickSpeed=$EXPECTED_START_RANDOM_TICK_SPEED mobSpawning=0" 'deterministic agent session initial conditions'

[ -s "$CAPTURE_PATH" ] || fail "capture was not written: $CAPTURE_PATH"
if [ "$MODE" = "work-demand-refresh" ]; then
    [ -s "$CAPTURE_BEFORE_PATH" ] || fail "pre-refresh capture was not written: $CAPTURE_BEFORE_PATH"
    [ -s "$CAPTURE_AFTER_PATH" ] || fail "post-refresh capture was not written: $CAPTURE_AFTER_PATH"
    require_trace 'PLAYABLE_SLICE_BOOTSTRAP_COMPLETE tick=0 agents=3 follow=off productiveCommandsAfter=0' 'normal integrated passive bootstrap'
    require_trace '^\[lab-live\] work demand reconciled demand=.* source=agriculture sourceKey=.* domain=cultivation oldSource=.* newSource=.* createdAt=0 refreshedAt=4 reactivated=0$' 'exact first newer-provenance reconciliation at tick 4'
    require_trace '^\[lab-live\] work demand refresh tick=4 attempt=2 .*meaningful=[1-9][0-9]* .*totalDemands=[0-9]+>[0-9]+ .*runtimeErrors=0$' 'tick-4 refresh completes without error'
    require_trace '^\[lab-live\] GATE_B3_ACCEPTANCE_SNAPSHOT seed=46 tick=256 .*runtimeErrors=0 manualProductive=0 .*decisions=[1-9][0-9]* .*completed=[1-9][0-9]* .*workDemands=[1-9][0-9]* .*workCommitments=[1-9][0-9]* .*workRefreshAttempts=6[4-9] .*workMeaningfulRefreshes=[1-9][0-9]* .*workRefreshEvents=[1-9][0-9]* .*workIdentityRejects=0 workStaleRejects=0 ' 'bounded repeated Work refresh and continuing society'
    require_trace '^\[lab-live\] GATE_B3_HORIZON_COMPLETE seed=46 tick=256 target=256 exact=1$' 'exact 256-tick integrated horizon'
    require_trace '^\[lab-live\] player coexistence result .* decisionsDelta=[1-9][0-9]* completedDelta=[1-9][0-9]* directSetPos=0 passed=1$' 'normal Player control coexists with continued autonomy'
    require_trace 'summary .*ticks=256 .*runtimeErrors=0 .*probesRemoved=3 ' 'normal cleanup after the 64-second cognitive horizon'
    require_trace 'autonomous summary bootstrap=1 manualProductive=0 .*completed=[1-9][0-9]* ' 'no productive manual command after bootstrap'
    reject_trace 'demand identity changed|demand logical identity changed|work demand refresh rejected|runtimeErrors=[1-9]|productiveCount=[1-9]' 'Work identity failure, runtime error, or productive manual command'
    printf '\nPASS: stable causal Work refreshes, tick-4 escape, 256-tick client continuity, Player coexistence, three captures, and zero runtime errors verified.\n'
elif [ "$MODE" = "integrated-teaching" ]; then
    [ -s "$CAPTURE_BEFORE_PATH" ] || fail "integrated Teaching before capture was not written: $CAPTURE_BEFORE_PATH"
    [ -s "$CAPTURE_APPRENTICESHIP_PATH" ] || fail "integrated Teaching apprenticeship capture was not written: $CAPTURE_APPRENTICESHIP_PATH"
    [ -s "$CAPTURE_DEMONSTRATION_PATH" ] || fail "integrated Teaching demonstration capture was not written: $CAPTURE_DEMONSTRATION_PATH"
    require_trace 'PLAYABLE_SLICE_BOOTSTRAP_COMPLETE tick=0 agents=3 follow=off productiveCommandsAfter=0' 'normal passive bootstrap marker'
    require_trace '^\[lab-live\] integrated teaching bootstrap resources=real_sweet_berry_bushes:18 assignedRoles=0 fakeSkill=0 fakePracticeHistory=0 activeApprenticeships=0$' 'real opportunities with no designated social role or fake history'
    require_trace '^\[lab-live\] autonomous material practice actor=agent_[0-2] domain=foraging source=.* skillEvent=.* practice=0>1 physicalReceipt=.* outputBonus=0 manualTrigger=0$' 'real material work begins mentor experience'
    require_trace '^\[lab-live\] autonomous material practice actor=agent_[0-2] domain=foraging source=.* skillEvent=.* practice=2>3 physicalReceipt=.* outputBonus=0 manualTrigger=0$' 'one inhabitant becomes practiced through real work'
    require_trace '^\[lab-live\] autonomous teaching review tick=[1-9][0-9]* opportunities=[1-9][0-9]* requests=[1-9][0-9]* accepted=[1-9][0-9]* .*started=[1-9][0-9]* .*manualSelectMentorCalls=0$' 'normal bounded review starts a local apprenticeship'
    require_trace '^\[lab-live\] autonomous apprenticeship started id=.* teacher=agent_[0-2] student=agent_[0-2] domain=foraging teacherPractice=[3-9][0-9]* studentPractice=[0-2] distance=[0-8] studentDecision=accept teacherDecision=accept reason=.* manualInitiation=0$' 'existing selector starts a local consented foraging apprenticeship'
    require_trace '^\[lab-live\] autonomous teaching demonstration apprenticeship=.* teacher=agent_[0-2] student=agent_[0-2] domain=foraging source=.* distance=[0-8] lineOfSight=1 studentPractice=[0-9]+>[0-9]+ observationSkillDelta=0$' 'later real mentor success is locally observed with zero free practice'
    require_trace '^\[lab-live\] autonomous guided practice apprenticeship=.* student=agent_[0-2] domain=foraging source=.* skillEvent=.* practiceAfterOwnSuccess=[1-9][0-9]* practiceAfterLink=[1-9][0-9]* guidedPracticeSkillDelta=0 materialBonus=0$' 'student own physical success receives normal credit and a guided link'
    require_trace 'autonomous summary bootstrap=1 manualProductive=0 .*completed=[1-9][0-9]* ' 'no productive manual command after bootstrap'
    require_trace 'summary .*agents=3 .*runtimeErrors=0 .*probesRemoved=3 .*follow=off demo=0 ' 'normal client lifecycle and exact cleanup'
    require_trace '^\[lab-live\] passive society cleanup cells=exact entities=exact custody=exact$' 'integrated fixture cleanup'
    reject_trace 'passive command .*class=productive|productiveCount=[1-9]|/lab teaching proof|manualInitiation=[1-9]|manualSelectMentorCalls=[1-9]|outputBonus=[1-9]|materialBonus=[1-9]|runtimeErrors=[1-9]|rollbackFailure' 'manual Teaching action, productive command, bonus, or runtime failure'
    printf '\nPASS: autonomous local apprenticeship, real mentor demonstration, zero-free-skill observation, student own practice, and guided link verified.\n'
elif [ "$MODE" = "gate-b-passive" ]; then
    [ -s "$CAPTURE_START_PATH" ] || fail "passive start capture was not written: $CAPTURE_START_PATH"
    [ -s "$CAPTURE_MULTI_PATH" ] || fail "passive multi-agent capture was not written: $CAPTURE_MULTI_PATH"
    [ -s "$CAPTURE_AGRICULTURE_PATH" ] || fail "passive agriculture capture was not written: $CAPTURE_AGRICULTURE_PATH"
    [ -s "$CAPTURE_LIVESTOCK_PATH" ] || fail "passive livestock capture was not written: $CAPTURE_LIVESTOCK_PATH"
    [ -s "$CAPTURE_FOLLOW_PATH" ] || fail "passive focus capture was not written: $CAPTURE_FOLLOW_PATH"
    require_trace 'PLAYABLE_SLICE_BOOTSTRAP_COMPLETE tick=0 agents=3 follow=off productiveCommandsAfter=0' 'bounded passive bootstrap marker'
    require_trace '^\[lab-live\] passive composite bootstrap world=one session=one settlement=one agents=3 .*field=real storage=real water=real livestockPhysical=2 food=real commandsProductive=0$' 'single composite physical World and session'
    require_trace '^\[lab-live\] passive visual identity actor=agent_0 variant=villager_fisherman marker=stableAgentID ' 'stable agent_0 visual identity'
    require_trace '^\[lab-live\] passive visual identity actor=agent_1 variant=villager_farmer marker=stableAgentID ' 'stable agent_1 visual identity'
    require_trace '^\[lab-live\] passive visual identity actor=agent_2 variant=villager marker=stableAgentID ' 'stable agent_2 visual identity'
    require_trace '^\[lab-live\] autonomous activity completed actor=agent_[0-2] domain=agriculture action=(till|plant|harvest) .*manualTrigger=0$' 'naturally selected real agriculture completion'
    require_trace '^\[lab-live\] autonomous activity completed actor=agent_1 domain=livestock action=feed .*manualTrigger=0$' 'agent_1 real livestock completion'
    require_trace '^\[lab-live\] autonomous activity completed actor=agent_2 domain=livestock action=feed .*manualTrigger=0$' 'agent_2 real livestock completion'
    require_trace '^\[lab-live\] autonomous activity completed actor=agent_[0-2] domain=(fishing|hunting|wildGathering) .*manualTrigger=0$' 'real Wild Subsistence completion'
    require_trace 'physical food consumption actor=agent_2 material=sweet_berries .*physicalDebit=exact abstractDelta=0' 'autonomous real-food hunger closure'
    require_trace '^\[lab-live\] passive cross-family switch actor=agent_[0-2] from=(agriculture|livestock|wildSubsistence|physicalSurvival) to=(agriculture|livestock|wildSubsistence|physicalSurvival) ' 'causal cross-family autonomous switch'
    require_trace_at_least '^\[lab-live\] passive focus decision .* actor=agent_0 ' 3 'three meaningful decisions for the unchanged observer focus'
    require_trace_at_least '^\[lab-live\] passive focus outcome .* actor=agent_0 ' 2 'two completed real actions for the unchanged observer focus'
    require_trace '^\[lab-live\] player coexistence result inputPath=GameCore\.keyDown/keyUp\+mouseDelta worldTicks=[2-9][0-9]* simulationTicks=[0-9]+>[1-9][0-9]* position=[^ ]+>[^ ]+ camera=[^ ]+>[^ ]+ distance=([1-9][0-9]*|[1-9][0-9]*\.[0-9]+|0\.[3-9][0-9]*) decisionsDelta=[1-9][0-9]* completedDelta=[1-9][0-9]* directSetPos=0 passed=1$' 'real key/mouse Player control coexisting with autonomous progress'
    require_trace 'autonomous summary bootstrap=1 manualProductive=0 decisions=[1-9][0-9]* candidates=[1-9][0-9]* starts=[1-9][0-9]* completed=[1-9][0-9]* blocked=[0-9]+ switches=[0-9]+ completedAgents=3 domains=.*agriculture.*livestock.*wildGathering.* chainedAgents=.* active=[0-9]+ retained=[0-9]+ evicted=[0-9]+ idleLongest=[0-9]+ sameFamilyContinuations=[1-9][0-9]* crossFamilySwitches=[1-9][0-9]* families=.*agriculture:[1-9].*livestock:[1-9].*physicalSurvival:[1-9].*wildSubsistence:[1-9].* idleByAgent=.* idleReasons=.* idleEligibleViolations=0' 'continuous passive autonomy and bounded product-audit counters'
    require_trace 'summary .*ticks=(6[0-9][0-9]|[7-9][0-9][0-9]|1[0-2][0-9][0-9]) .*agents=3 .*runtimeErrors=0 .*probesRemoved=3 .*follow=off demo=0 ' 'five-minute normal lifecycle and exact cleanup'
    require_trace '^\[lab-live\] passive society cleanup cells=exact entities=exact custody=exact$' 'exact composite fixture cleanup'
    reject_trace 'passive command .*class=productive|productiveCount=[1-9]|Autonomous Civilization command failed|rollbackFailure|runtimeErrors=[1-9]|abstractCredit=[^0]|campStockDelta=[^0]|resourceInventoryDelta=[^0]' 'productive command, runtime failure, or ghost productive credit'
    printf '\nPASS: continuous playable passive society slice, three cross-family domains, real Player input, stable visual identities, exact cleanup, and zero productive commands verified.\n'
elif [ "$MODE" = "physical-food-survival" ]; then
    [ -s "$CAPTURE_BEFORE_PATH" ] || fail "before capture was not written: $CAPTURE_BEFORE_PATH"
    [ -s "$CAPTURE_ACQUIRED_PATH" ] || fail "acquired capture was not written: $CAPTURE_ACQUIRED_PATH"
    [ -s "$CAPTURE_CONSUMED_PATH" ] || fail "consumed capture was not written: $CAPTURE_CONSUMED_PATH"
    require_trace 'physical food shadow actor=agent_2 foodRaw=[1-9][0-9]* physicalFood=none abstractSpend=rejected hunger=0\.[0-9]+ criticalTicks=[1-9][0-9]* health=[0-9]+ starvation=progressed mutation=none' 'abstract shadow authority rejection and starvation progression'
    require_trace_count '^\[lab-live\] wild subsistence gathering actor=agent_2 resource=sweet_berry_bush observation=real approachSteps=[1-9][0-9]* interaction=canonicalBreak drops=exact loot=sweet_berries custody=real depleted=1 regrowth=CoreOnly practice=1 abstractCredit=0$' 1 'real berry acquisition through CIV-23'
    require_trace 'physical food faults actor=agent_2 stale=refused staleDebit=0 staleHungerDelta=0 rollback=verified rollbackItem=restored rollbackSession=unchanged' 'stale refusal and verified rollback'
    require_trace 'physical food live actor=agent_2 source=CIV23-wildGathering material=sweet_berries slot=[0-9]+ countBefore=[1-9][0-9]* consumed=1 countAfter=[0-9]+ remainder=none coreHunger=2 saturation=0\.4 hunger=0\.[0-9]+>0\.[0-9]+ criticalTicks=[1-9][0-9]*>0 foodRawDelta=0 campStockDelta=0 localEcologyDelta=0 resourceInventoryDelta=0 receipt=physical-food:[A-Za-z0-9_.-]+:[A-Za-z0-9_.-]+:[1-9][0-9]* custody=real physicalConservation=exact' 'exact physical food debit and canonical hunger publication'
    require_trace 'physical food duplicate actor=agent_2 consumptionID=physical-food:[A-Za-z0-9_.-]+:[A-Za-z0-9_.-]+:[1-9][0-9]* secondDebit=0 secondHungerDelta=0 secondHistory=0' 'physical consumption idempotence'
    require_trace 'physical food proof authority=physicalItems source=matureSweetBerryBush observation=real gathering=canonicalBreak itemEntity=real acquisition=exact custody=real consumption=exact survival=AgentNeeds.hunger hunger=0\.[0-9]+ health=[0-9]+ history=1 abstractCredit=0 schema=17 restart=validatedOutcomeOnly physicalInventoryOwner=PebbleCore GateR=acquired foodBlocker=remediated autonomyBlocker=open GateB=notAcquired runtimeErrors=0' 'complete GATE-B-CORR-01 live proof'
    require_trace 'wild subsistence cleanup entities=exact cells=exact custody=exact probes=restored' 'exact physical food fixture cleanup'
    require_trace 'summary .*runtimeErrors=0 .*probesRemoved=3 ' 'physical food runtime health'
    reject_trace 'PhysicalFoodSurvival command failed|rollbackFailure|abstractCredit=[^0]|foodRawDelta=[^0]|campStockDelta=[^0]|resourceInventoryDelta=[^0]' 'physical food failure, rollback failure, or ghost abstract mutation'
    printf '\nPASS: real berry acquisition, exact physical consumption, shadow rejection, v17 state, and Gate B food remediation verified.\n'
elif [ "$MODE" = "work-professions" ]; then
    [ -s "$CAPTURE_INITIAL_PATH" ] || fail "initial capture was not written: $CAPTURE_INITIAL_PATH"
    [ -s "$CAPTURE_SPECIALIZED_PATH" ] || fail "specialized capture was not written: $CAPTURE_SPECIALIZED_PATH"
    [ -s "$CAPTURE_CRISIS_PATH" ] || fail "crisis capture was not written: $CAPTURE_CRISIS_PATH"
    require_trace_count '^\[lab-live\] work professions match demand=.* domain=(fishing|hunting|foraging) candidates=3 selected=agent_[0-2] physicalEligibility=adapter$' 3 'three deterministic physical-context matches'
    require_trace_count '^\[lab-live\] work professions outcome commitment=.* worker=agent_[0-2] domain=(fishing|hunting|foraging) source=.* verified=1 physicalMultiplier=0 abstractCredit=0$' 3 'three normalized real work outcomes'
    require_trace '^\[lab-live\] work professions crisis commitment=.* worker=agent_2 status=suspended professionLock=0$' 'crisis suspension without profession lock'
    require_trace '^\[lab-live\] work professions resume commitment=.* worker=agent_2 status=active$' 'bounded crisis recovery'
    require_trace_count '^\[lab-live\] work professions proof authority=PebbleCore domains=fishing,hunting,foraging commitments=3 outcomes=3 profiles=agent_0:fishing,agent_1:hunting,agent_2:foraging specialization=derived physicalMultiplier=0 abstractMaterialCredit=0 campStockDelta=0 resourceInventoryDelta=0 localEcologyDelta=0 schema=16 GateR=acquired GateB=notAcquired digest=[0-9a-f]+ runtimeErrors=0 world=active$' 1 'complete CIV-25 live proof'
    require_trace 'summary .*runtimeErrors=0 .*probesRemoved=3 ' 'work profession runtime health and cleanup'
    reject_trace 'WorkProfessions command failed|WorkProfessions found no new|rollbackFailure|physicalMultiplier=[^0]|abstractMaterialCredit=[^0]|campStockDelta=[^0]|resourceInventoryDelta=[^0]' 'work profession failure or ghost benefit'
    printf '\nPASS: real work commitments, derived profiles, crisis adaptation, v16 state, and zero ghost credit verified.\n'
elif [ "$MODE" = "livestock" ]; then
    [ -s "$CAPTURE_MANAGED_PATH" ] || fail "managed capture was not written: $CAPTURE_MANAGED_PATH"
    [ -s "$CAPTURE_FEEDING_PATH" ] || fail "feeding capture was not written: $CAPTURE_FEEDING_PATH"
    [ -s "$CAPTURE_OFFSPRING_PATH" ] || fail "offspring capture was not written: $CAPTURE_OFFSPRING_PATH"
    [ -s "$CAPTURE_PRODUCT_PATH" ] || fail "product capture was not written: $CAPTURE_PRODUCT_PATH"
    require_trace_count '^\[lab-live\] livestock proof physical feed=2 birth=1 herding=1 product=[1-9][0-9]* loss=1$' 1 'real Core livestock vertical'
    require_trace_count '^\[lab-live\] livestock proof no_ghost_stock=1 campStockDelta=0 resourceInventoryDelta=0 localEcologyDelta=0 husbandry=4 Core_authority=1$' 1 'livestock conservation and practice'
    require_trace 'livestock status enabled=1 herds=1 living=2 young=1 unresolved=0 missing=1 products=[1-9][0-9]* digest=[0-9a-f]+' 'final current animal capital'
    require_trace 'summary .*runtimeErrors=0 .*probesRemoved=3 ' 'livestock cleanup and runtime health'
    reject_trace 'Livestock command failed|livestock fixture cleanup failed|rollbackFailure|no_ghost_stock=0|Core_authority=0' 'livestock failure, rollback failure, or ghost credit'
    printf '\nPASS: real sheep feed, Core birth, leash movement, wool custody, loss, and v15 state verified.\n'
elif [ "$MODE" = "wild-subsistence" ]; then
    [ -s "$CAPTURE_FISHING_PATH" ] || fail "fishing capture was not written: $CAPTURE_FISHING_PATH"
    [ -s "$CAPTURE_HUNTING_PATH" ] || fail "hunting capture was not written: $CAPTURE_HUNTING_PATH"
    [ -s "$CAPTURE_GATHERING_PATH" ] || fail "gathering capture was not written: $CAPTURE_GATHERING_PATH"
    require_trace_count '^\[lab-live\] wild subsistence fishing actor=agent_0 water=real approachSteps=[1-9][0-9]* rod=real cast=FishingBobber waited=[1-9][0-9]* bite=real RNG=Core loot=.* foodQuantity=[0-9]+ itemEntities=exact custody=real rodDurability=(damaged|unchanged|broken) practice=1 abstractCredit=0$' 1 'real Core fishing and exact custody'
    require_trace_count '^\[lab-live\] wild subsistence fishing-full actor=agent_0 catch=real custody=destinationFull lootIDs=exact lootRetained=1 publication=none practiceDelta=0 reconciliation=physicalTruthRetained$' 1 'full fishing custody retains exact physical loot without publication'
    require_trace_count '^\[lab-live\] wild subsistence hunting actor=agent_1 prey=chicken entity=real revalidatedMoved=[0-8] approachSteps=[1-9][0-9]* reach=physical attack=Core damage=real death=real attribution=finalActor drops=exact loot=.* custody=real practice=1 abstractCredit=0 duplicateDeath=0$' 1 'real Core hunting, death, attribution, and drops'
    require_trace_count '^\[lab-live\] wild subsistence gathering actor=agent_2 resource=sweet_berry_bush observation=real approachSteps=[1-9][0-9]* interaction=canonicalBreak drops=exact loot=sweet_berries custody=real depleted=1 regrowth=CoreOnly practice=1 abstractCredit=0$' 1 'real canonical wild gathering and depletion'
    require_trace_count '^\[lab-live\] wild subsistence proof authority=PebbleCore fishing=FishingBobber hunting=LivingEntity gathering=canonicalBreak outputs=physical custody=real outcomes=3 campStockDelta=0 resourceInventoryDelta=0 localEcologyDelta=0 practice=fishing:1,hunting:1,foraging:1 schema=14 restart=completedHistoryOnly activePhysicalRestart=cancel GateR=acquired GateB=notAcquired fixture=retainedForCapture cleanup=deferred digest=[0-9a-f]+ runtimeErrors=0$' 1 'complete CIV-23 physical proof'
    require_trace 'wild subsistence cleanup entities=exact cells=exact custody=exact probes=restored' 'exact proof cleanup'
    require_trace 'summary .*runtimeErrors=0 .*probesRemoved=3 ' 'wild subsistence runtime health'
    reject_trace 'WildSubsistence command failed|wild subsistence fixture cleanup failed|rollbackFailure|abstractCredit=[^0]|campStockDelta=[^0]|resourceInventoryDelta=[^0]' 'wild subsistence failure, rollback failure, or ghost credit'
    printf '\nPASS: real fishing, hunting, wild gathering, exact custody, v14 state, and cleanup verified.\n'
elif [ "$MODE" = "agriculture" ]; then
    require_trace_count '^\[lab-live\] agriculture proof actor=agent_0 authority=PebbleCore crop=wheat observation=CIV21 site=real soil=real water=real plan=4cells navigation=findPath\+Entity.move reach=physical hoe=iron_hoe till=canonical plant=registry seedsConsumed=4 growth=randomTicks growthCalls=[1-9][0-9]* stage=0>7 hydration=water mature=CIV21 harvest=canonical drops=exact custody=real wheat=4 seedReserve=([4-9]|[1-9][0-9]+) container=real liveSeedsAfterReplant=[1-9][0-9]* liveWheat=4 surplus=physical historicalRecord=nonspendable externalRemoval=reflected multiAgentWinner=agent_0 duplicate=refused immature=wait staleTill=refused stalePlant=refused staleHarvest=refused lateTill=rollback latePlant=rollback lateHarvest=rollback fullCustody=rollback fullStorage=rollback tamper=reconciled practice=18 waitingPractice=0 observationPractice=0 campStockDelta=0 resourceInventoryDelta=0 civilSeasonGrowthEffect=0 displayCrops=2 fixture=retainedForCapture cleanup=deferred schema=13 cycle=complete digest=[0-9a-f]+$' 1 'complete CIV-22 agriculture proof'
    require_trace 'agriculture autonomy observer=agent_0 observation=fresh soil=real water=real tool=real seeds=real storage=real plot=planned cells=4 next=till worldMutation=none materialMutation=none' 'normal agriculture decision seam'
    require_trace 'agriculture state tick=0 reason=activated enabled=1 schema=13 plots=0 actions=0 cycles=0 reservations=0 surplusRecords=0 .*worldMutation=none materialMutation=none' 'zero-retroactive v13 activation'
    require_trace 'checkpoint saved name=agriculture-v13 .*tick=0 .*restartSafe=0 ' 'honest live v13 checkpoint with app-owned fixture'
    require_trace 'summary .*runtimeErrors=0 .*probesRemoved=3 ' 'agriculture cleanup and runtime health'
    reject_trace 'Agriculture proof failed|agriculture proof failed|rollbackFailure|campStockDelta=[^0]|resourceInventoryDelta=[^0]|cleanup=failed' 'agriculture proof failure, ghost credit, or leaked state'
    printf '\nPASS: real wheat cycle, Core growth, physical seed reserve/surplus, rollback, and exact cleanup verified.\n'
elif [ "$MODE" = "ecological-observation" ]; then
    require_trace_count '^\[lab-live\] ecological observation proof observer=agent_0 authority=PebbleCore biome=real water=real soil=real crop=3>7 plant=real animal=cow fishing=candidate weather=clear>rain physicalTime=real civilDate=1-spring-1 clock=sessionTick independentWorldClock=1 biomePair=different waterContrast=present>absent soilContrast=tillable>invalid animalContrast=present>absent fishingContrast=candidate>absent perAgent=exact agent_1=none stableKeys=canonical noRuntimeIDs=1 chunkForce=none unavailable=unknown WorldReplacement=cacheMiss budgetExceeded=explicit missingEmbodiment=refused cache32=1miss\+31hits reads=[0-9]+ cellsMax=512 worldReadsMax=1024 entitiesMax=64 resultsMax=128 scanWorldMutation=none fixtureMutation=controlled materialMutation=none coarseEcologyMutation=none schema=12 restart=exact fixture=retainedForCapture cleanup=deferred digest=[0-9a-f]+$' 1 'complete CIV-21 ecological observation proof'
    require_trace 'ecological observation state tick=0 reason=activated enabled=1 schema=12 civil=1-spring-1 retained=0 total=0 fresh=0 stale=0 .*mutation=none' 'explicit zero-retroactive ecological observation activation'
    require_trace 'checkpoint saved name=ecological-v12 .*tick=0 .*restartSafe=1 .*mutation=none' 'live v12 ecological checkpoint save'
    require_trace 'summary .*runtimeErrors=0 .*probesRemoved=3 ' 'ecological observation proof cleanup and runtime health'
    reject_trace 'Ecological observation proof failed|ecological observation proof failed|chunk was forced|scan mutated World|cleanup=failed' 'ecological observation failure or leaked state'
    printf '\nPASS: real local ecological observation, civil calendar, bounded cache, v12 restart, and exact cleanup verified.\n'
elif [ "$MODE" = "teaching" ]; then
    require_trace_count '^\[lab-live\] teaching proof teacher=agent_2 student=agent_1 physical=embodiments locality=CIV04 exact=1 teacherAction=realHarvest exposure=1 skillObservation=0>0 studentAction=realHarvest skillPractice=1 guided=1 outOfRange=rejected worldMutation=harvestOnly teachingWorldMutation=none yieldBonus=0 session=unchanged custody=restored fixture=restored cleanup=exact runs=2 digest=[0-9a-f]+$' 1 'complete CIV-20 live Teaching proof'
    require_trace 'teaching tick=0 enabled=1 active=0 demonstrations=0 exposures=0 guided=0 digest=[0-9a-f]+ worldMutation=none skillMutation=none' 'default-off then explicit zero-retroactive Teaching activation'
    require_trace 'summary .*runtimeErrors=0 .*probesRemoved=3 ' 'Teaching proof cleanup and runtime health'
    reject_trace 'Teaching proof failed|teaching proof failed|observation granted skill|double credited|cleanup=failed' 'Teaching proof failure or leaked state'
    printf '\nPASS: real local demonstration, no-free-skill, guided practice, distance refusal, and exact cleanup verified.\n'
elif [ "$MODE" = "embodiment" ]; then
    require_trace_count '^\[lab-live\] embodiment proof authority=PebbleCore/findPath\+Entity.move body=PebbleAgentEmbodiment oneToOne=exact simple=passed obstacle=passed dynamic=passed vertical=passed gap=refused multiAgent=refused waypoint=corePath coarsePlanner=preserved physicalTruth=wins orientation=physical noNormalSetPos=1 latePublicationRollback=exact harvestReach=physical constructionReach=physical missing=refused duplicate=refused staleWorld=refused custodyRemoval=spilled session=unchanged custody=unchanged cleanup=exact runs=2 digest=[0-9a-f]+$' 1 'complete CIV-19 navigation and embodiment convergence proof'
    require_trace_count '^\[lab-live\] harvest proof .*session=unchanged cleanup=exact runs=2 digest=[0-9a-f]+$' 1 'CIV-17 physical reach regression proof'
    require_trace_count '^\[lab-live\] construction proof .*session=unchanged cleanup=exact runs=2 digest=[0-9a-f]+$' 1 'CIV-18 work-position regression proof'
    require_trace '^\[lab-live\] embodiment movement tick=[1-4] authority=PebbleCore publication=verified outcomes=.*:moved:.* noNormalSetPos=1$' 'normal live controller publishes a Core-verified physical movement'
    require_trace 'summary .*runtimeErrors=0 .*probesRemoved=4 ' 'embodiment proof cleanup and runtime health'
    reject_trace 'Embodiment convergence proof failed|embodiment proof failed|rollbackVerificationFailed|session=changed|cleanup=failed' 'embodiment proof failure or leaked state'
    printf '\nPASS: Core navigation, physical movement, embodiment lifecycle, reach, and late rollback verified.\n'
elif [ "$MODE" = "construction" ]; then
    require_trace_count '^\[lab-live\] construction proof actor=agent_2 blueprint=fixedLeanToV1 cells=9 materials=stone:3,oak_log:6 custody=real slotOrder=stable wrongMaterial=refused missingMaterial=refused stale=refused nonreplaceable=refused occupied=refused wrongOrder=refused priorTamper=refused duplicate=refused supportRollback=exact publicationRollback=exact finalCellRollback=exact installed=9 consumed=9 ghostStock=0 causal=9 practice=9 playerParity=executeBlockPlacement session=unchanged cleanup=exact runs=2 digest=[0-9a-f]+$' 1 'complete CIV-18 construction convergence proof'
    require_trace 'summary .*runtimeErrors=0 .*probesRemoved=3 ' 'construction proof cleanup and runtime health'
    reject_trace 'Construction convergence proof failed|rollbackFailure|session=changed|cleanup=failed' 'construction proof failure or leaked state'
    printf '\nPASS: ordered real-custody construction, PebbleCore placement, rollback, and deterministic repeat verified.\n'
elif [ "$MODE" = "harvest" ]; then
    require_trace_count '^\[lab-live\] harvest proof actor=agent_2 log=oak_logx1 stone=cobblestonex1 axeDamage=1 pickaxeDamage=1 custody=real unrelated=preserved capacityRollback=exact lateRollback=exact wrongToolRollback=exact stale=refused duplicate=refused abstractCredit=0 campStockCredit=0 causal=2 practiceDelta=2 session=unchanged cleanup=exact runs=2 digest=[0-9a-f]+$' 2 'two complete CIV-17 harvest convergence proofs'
    harvest_digests=$(/usr/bin/sed -n 's/^\[lab-live\] harvest proof .* digest=\([0-9a-f]*\)$/\1/p' "$TRACE_PATH" | /usr/bin/sort -u | /usr/bin/wc -l | /usr/bin/tr -d ' ')
    [ "$harvest_digests" -eq 1 ] || fail "harvest proof digests differ across replay"
    require_trace 'summary .*runtimeErrors=0 .*probesRemoved=3 ' 'harvest proof cleanup and runtime health'
    reject_trace 'Harvest convergence proof failed|rollbackFailure|session=changed|cleanup=failed' 'harvest proof failure or leaked state'
    printf '\nPASS: canonical Pebble breaking, exact drop custody, tool wear, rollback, and deterministic replay verified.\n'
elif [ "$MODE" = "material" ]; then
    require_trace_count '^\[lab-live\] material proof actor=agent_2 identity=stable transfer=succeeded duplicate=duplicate stale=staleSource withdraw=succeeded lateTransfer=verificationFailure consume=succeeded lateConsume=verificationFailure place=succeeded break=succeeded lateBreak=verificationFailure session=unchanged campStock=unchanged cleanup=verified digest=[0-9a-f]+$' 2 'two complete real-material proofs'
    material_digests=$(/usr/bin/sed -n 's/^\[lab-live\] material proof .* digest=\([0-9a-f]*\)$/\1/p' "$TRACE_PATH" | /usr/bin/sort -u | /usr/bin/wc -l | /usr/bin/tr -d ' ')
    [ "$material_digests" -eq 1 ] || fail "material proof digests differ across replay"
    require_trace 'summary .*runtimeErrors=0 .*probesRemoved=3 ' 'material proof cleanup and runtime health'
    reject_trace 'Material custody proof failed|rollbackFailure|session=changed|campStock=changed|cleanup=failed' 'material proof failure or leaked state'
    printf '\nPASS: stable real-material custody, transactions, CIV-15 seams, and repeated deterministic cleanup verified.\n'
elif [ "$MODE" = "rights" ]; then
    require_trace_count '^\[lab-live\] rights proof asset=asset:iron_pickaxe:live physicalHolder=agent_2 custodian=agent_1 recognizedOwner=agent_0 claims=agent_0,agent_2 authorizedUser=agent_1 aligned=allowed loan=verified borrowerDenied=noUseRight authorizedReturn=verified unauthorizedTake=transgression conflict=active rollback=verified rolesAfterRollback=unchanged authority=PebbleCore transfer=PebbleGateway state=AgentSimulationSession fixture=retainedForCapture digest=[0-9a-f]+$' 1 'complete CIV-26 physical and social divergence'
    require_trace '^\[lab-live\] rights status enabled=1 assets=1 conflicts=1 records=asset:iron_pickaxe:live:holder=agent:agent_2,custodian=agent_1,owner=agent_0,claims=agent_0\+agent_2,users=agent_1,conflict=yes$' 'inspectable final rights matrix'
    require_trace '^\[lab-live\] rights cleanup custody=exact entities=exact state=cleared$' 'exact post-capture cleanup'
    require_trace 'summary .*runtimeErrors=0 .*probesRemoved=3 ' 'rights runtime health and probe cleanup'
    reject_trace 'Material-rights proof failed|material-rights fixture cleanup failed|rollbackFailure|cleanup=failed|runtimeErrors=[1-9]' 'CIV-26 failure, rollback failure, or cleanup leak'
    printf '\nPASS: CIV-26 real custody, local ownership recognition, permissions, transgression, conflict, rollback, and cleanup verified.\n'
elif [ "$MODE" = "cooperation" ]; then
    [ -s "$CAPTURE_BEFORE_PATH" ] || fail "before capture was not written: $CAPTURE_BEFORE_PATH"
    [ -s "$CAPTURE_DURING_PATH" ] || fail "offer capture was not written: $CAPTURE_DURING_PATH"
    require_trace 'cooperation=on tick=0 mutation=none' 'cooperation was explicitly enabled after its dependencies'
    require_trace 'cooperation task tick=[1-9][0-9]* id=task-.* issuer=agent_2 helper=agent_1 resource=stone requested=3 .*status=(signaled|offered)' 'builder created one bounded three-stone offer for the helper'
    reject_trace 'cooperation task .* helper=agent_0' 'urgent third agent assigned a task'
    require_trace 'physical perception tick=[1-9][0-9]* signal=signal-.* observer=agent_1 intended=1 .*outcome=exact' 'intended helper perceived the physical offer exactly'
    require_trace 'cooperation task tick=[1-9][0-9]* .*status=(accepted|active)' 'helper voluntarily accepted and started the task'
    require_trace_count 'cooperation harvest tick=[1-9][0-9]* operation=g2-natural:agent_1:.* actor=agent_1 .* resource=stone status=succeeded' 3 'helper harvested exactly three real stone blocks'
    require_trace 'cooperation delivery tick=[1-9][0-9]* operation=economy-delivery:agent_1:.* actor=agent_1 transferred=stone:(1|2|3) status=succeeded' 'helper transferred real stone through the existing delivery transaction'
    require_trace 'cooperation task tick=[1-9][0-9]* .*resource=stone requested=3 contributed=3 status=completed' 'helper delivery completed the material task'
    require_trace 'cooperation reliability tick=[1-9][0-9]* issuer=agent_2 helper=agent_1 score=10 completed=1 failed=0 outcome=completed' 'successful task updated directed cooperation reliability'
    require_trace_count 'cooperation harvest tick=[1-9][0-9]* operation=g2-natural:agent_2:.* actor=agent_2 .* resource=wood status=succeeded' 6 'builder harvested exactly six real wood blocks'
    require_trace 'cooperation funding tick=[1-9][0-9]* operation=construction-funding:agent_2:.* event=.*event-[0-9]{20} actor=agent_2 .*status=funded' 'builder funding event is inspectable'
    require_trace_count 'cooperation placement tick=[1-9][0-9]* operation=construction-placement:agent_2:.* actor=agent_2 cell=[0-8] ' 9 'builder produced exactly nine ordered placement events'
    require_trace 'action=fund_construction .*buildStatus=funded .*conservation=9:0\+0\+0\+9\+0:exact' 'shared real stock funded the existing project atomically'
    require_trace 'build gate=enabled auto=on .*status=completed .*placedMaterials=wood:6,stone:3 placed=9/9 .*home=23,66,-24 .*conservation=9:0\+0\+0\+0\+9:exact' 'existing builder authority completed all nine cells'
    require_trace 'cooperation status gate=enabled enabled=yes .*issuer=agent_2 helper=agent_1 resource=stone requested=3 contributed=3 status=completed .*reliability=10 .*completed=1 .*contributedStone=3 .*digest=[0-9a-f]{16}' 'bounded final cooperation status'
    require_trace 'summary .*runtimeErrors=0 .*probesRemoved=3 .*naturalHarvests=9 naturalRollbacks=0 .*constructionRestored=1 .*causalDropped=0' 'cooperation proof cleaned the disposable run without runtime errors'
    require_trace 'cooperation summary enabled=0 tasks=1 .*completed=1 .*relations=1 .*digest=[0-9a-f]{16}' 'cooperation history survives explicit off and cleanup'
    printf '\nPASS: shared-task cooperation and material construction live evidence verified.\n'
elif [ "$MODE" = "physical" ]; then
    [ -s "$CAPTURE_BEFORE_PATH" ] || fail "before capture was not written: $CAPTURE_BEFORE_PATH"
    [ -s "$CAPTURE_DURING_PATH" ] || fail "during capture was not written: $CAPTURE_DURING_PATH"
    require_trace 'physical=on tick=0 mutation=none' 'physical mode was explicitly enabled without mutation'
    require_trace 'social tick=1 .*fact=.*observer=agent_1 .*resource=(wood|stone) .*messages=none .*trust=none' 'direct fact exists before physical emission'
    require_trace 'physical signal tick=2 id=signal-.* sender=agent_1 recipient=agent_2 fact=fact-.* status=pending' 'single directed physical signal emitted at tick two'
    require_trace 'physical audio signal=signal-.* sender=agent_1 .*requested=1 presented=[01] presentation=(available|unavailable)' 'existing audio engine received one positional request'
    require_trace 'physical gesture signal=signal-.* sender=agent_1 .*pose=on expires=5 mutation=none' 'bounded pointing gesture was presented'
    require_trace 'physical perception tick=3 signal=signal-.* observer=agent_2 intended=1 distance=1 sound=95 gesture=95 occlusions=0 los=1 chunksReady=1 outcome=exact .*decodedEvent=.*event-[0-9]{20} mutation=none' 'intended recipient perceived both modalities exactly'
    require_trace 'physical perception tick=3 signal=signal-.* observer=agent_0 intended=0 distance=1 sound=95 gesture=95 occlusions=0 los=1 chunksReady=1 outcome=ambiguous .*decodedEvent=none mutation=none' 'bystander retained only a non-semantic impression'
    require_trace 'social tick=3 .*messages=message-.*sender=agent_1 recipient=agent_2 .*belief=belief-.*owner=agent_2 status=unverified' 'exact physical decode reused the existing CIV-03 message and belief'
    reject_trace 'belief=.*owner=agent_0' 'bystander belief'
    require_trace 'social verification tick=[4-9] verifier=agent_2 sender=agent_1 .*resourceUnchanged=1 .*result=confirmed .*mutation=none' 'read-only verification confirms the physically received fact'
    require_trace 'social tick=[4-9] .*belief=.*owner=agent_2 status=confirmed .*trust=agent_2→agent_1=10@.*inventories=agent_0:0,agent_1:0,agent_2:0 stock=0 construction=none conservation=exact' 'trust changes with no material delta'
    require_trace 'physical status gate=enabled enabled=yes pending=0 emitted=1 latest=signal-.* sender=agent_1 recipient=agent_2 fact=fact-.* sound=95 gesture=95 outcome=exact soundHeard=2 gestureSeen=2 decoded=1 exact=1 ambiguous=1 missed=0 inconclusive=0 expired=0 .*events=[1-9][0-9]* digest=[0-9a-f]{16}' 'bounded final physical status'
    require_trace 'summary .*movementCount=[1-9][0-9]* .*runtimeErrors=0 .*probesRemoved=3 .*naturalHarvests=0 .*buildProject=none .*conservation=0:0\+0\+0\+0\+0:exact .*causalDropped=0' 'physical proof preserves material state and cleans up'
    require_trace 'physical summary enabled=0 signals=1 pending=0 exact=1 ambiguous=1 missed=0 inconclusive=0 decoded=1 expired=0 .*digest=[0-9a-f]{16}' 'physical evidence retained through explicit off and cleanup'
    printf '\nPASS: local physical sound, gesture, imperfect perception, and trust live evidence verified.\n'
elif [ "$MODE" = "social" ]; then
    require_trace 'social=on tick=0 mutation=none' 'social mode was explicitly enabled without mutation'
    require_trace 'social tick=1 .*fact=.*observer=agent_1 .*resource=(wood|stone) .*fingerprint=[0-9]+ .*messages=none .*trust=none' 'direct natural fact grounded for agent_1'
    require_trace 'social tick=2 .*messages=message-.*sender=agent_1 recipient=agent_2 .*belief=belief-.*owner=agent_2 status=unverified .*trust=none' 'single directed message and unverified belief'
    reject_trace 'sender=agent_1 recipient=agent_0' 'directed message to excluded urgent agent_0'
    require_trace 'social tick=[3-9] .*active=agent_2@.*navigation=socialVerification:active' 'recipient follows bounded social verification route'
    require_trace 'social verification tick=[3-9] verifier=agent_2 sender=agent_1 .*expected=1520 observed=1520 after=1520 resourceUnchanged=1 .*result=confirmed .*mutation=none' 'read-only World verification confirms the grounded fact without mutation'
    require_trace 'social tick=[3-9] .*belief=.*owner=agent_2 status=confirmed .*trust=agent_2→agent_1=10@.* active=none .*inventories=agent_0:0,agent_1:0,agent_2:0 stock=0 construction=none conservation=exact' 'directed trust updates while every material state remains unchanged'
    require_trace 'social status gate=enabled enabled=yes messages=1 unverified=0 confirmed=1 contradicted=0 expired=0 .*active=none trustEdges=1 trust=agent_2→agent_1=10 .*events=[1-9][0-9]* .*digest=[0-9a-f]{16}' 'bounded final social status'
    require_trace 'summary .*movementCount=[1-9][0-9]* .*runtimeErrors=0 .*probesRemoved=3 .*naturalHarvests=0 .*buildProject=none .*conservation=0:0\+0\+0\+0\+0:exact .*causalDropped=0' 'social proof preserves material state and cleans up'
    printf '\nPASS: grounded social information and directed trust live evidence verified.\n'
elif [ "$MODE" = "build" ]; then
    [ -s "$CAPTURE_BEFORE_PATH" ] || fail "before capture was not written: $CAPTURE_BEFORE_PATH"
    [ -s "$CAPTURE_PARTIAL_PATH" ] || fail "partial capture was not written: $CAPTURE_PARTIAL_PATH"
    require_trace 'build setup project=fixedLeanToV1:agent_2:0:.* candidates=.* worldMutations=0' 'read-only fixed shelter site selection'
    require_trace 'build gate=enabled auto=on .*blueprint=fixedLeanToV1 builder=agent_2 .*required=wood:6,stone:3 .*placed=0/9' 'fixed blueprint project diagnostics before construction'
    require_trace 'natural harvest actor=agent_2 .*resource=wood source=naturalWorld.*inventoryCredit=1 memory=resource_harvested' 'natural wood acquisition'
    require_trace 'natural harvest actor=agent_2 .*resource=stone source=naturalWorld.*inventoryCredit=1 memory=resource_harvested' 'natural stone acquisition'
    require_trace 'action=fund_construction .*campStock=.*wood:0,stone:0 .*buildStatus=funded .*conservation=9:0\+0\+0\+9\+0:exact' 'atomic construction funding'
    require_trace 'tick=112 .*action=place_block .*buildStatus=building .*buildPlaced=3 buildNext=3 .*conservation=9:0\+0\+0\+6\+3:exact' 'first three cells placed in order'
    require_trace 'build auto=off tick=112 mutation=none' 'construction interrupted after three placements'
    require_trace 'tick=116 .*build=off .*buildPlaced=3 buildNext=3 .*conservation=9:0\+0\+0\+6\+3:exact' 'no placement during four interrupted ticks'
    require_trace 'build gate=enabled auto=off .*placed=3/9 nextCell=3 .*conservation=9:0\+0\+0\+6\+3:exact' 'partial project retained exactly'
    require_trace 'build auto=on tick=116 mutation=none' 'construction resumed without replanning the project'
    require_trace 'action=place_block .*buildPlaced=4 buildNext=4 .*buildLast=3:wood@' 'resume continues at exact cell index three'
    require_trace 'build gate=enabled auto=on .*status=completed .*placedMaterials=wood:6,stone:3 placed=9/9 nextCell=9 .*home=23,66,-24 rest=23,66,-24 .*conservation=9:0\+0\+0\+0\+9:exact' 'completed shelter, new home, and extended conservation'
    require_trace 'causality status PebbleAgents causality simulationId=live-46-20-66--24 simulationTick=[0-9]+ nextSequence=[0-9]+ retainedEventCount=[1-9][0-9]* firstRetainedSequence=1 lastSequence=[0-9]+ droppedEventCount=0 digest=[0-9a-f]{16}' 'stable live simulation identity and bounded causal status'
    require_trace 'causality tail limit=20 returned=20' 'bounded causal tail inspection'
    require_trace 'causality eventId=live-46-20-66--24/event-[0-9]{20} tick=[0-9]+ kind=constructionClear' 'material causal clear visible in bounded live tail'
    require_trace 'survival=on tick=146 reason=command' 'survival explicitly enabled only after construction'
    require_trace 'goals=.*agent_2:rest.*navigationPurpose=homeRest' 'survival rest routes to the shelter home'
    require_trace 'tick=149 .*action=rest .*survival=on .*fatigue=0\.00 .*home=23,66,-24' 'rest completes in the shelter'
    require_trace 'build clear project=fixedLeanToV1:agent_2:0:22,66,-25 restored=9 conservation=exact' 'transactional clear restored nine cells'
    require_trace 'build gate=enabled auto=off project=none .*stock=wood:6,stone:3 .*conservation=9:0\+9\+0\+0\+0:exact' 'clear refunded materials and removed project'
    require_trace 'summary .*runtimeErrors=0 .*naturalHarvests=9 naturalRollbacks=0 naturalRestoredAfterSuccess=0 buildProject=none buildPlaced=0 buildRestored=9 buildRollback=0 constructionRestored=1 conservation=9:0\+9\+0\+0\+0:exact causalSim=live-46-20-66--24 causalTick=[0-9]+ causalSequence=[0-9]+ causalEvents=[0-9]+ causalDropped=0' 'verified clear, lifecycle, natural destruction boundary, and causal summary'
    printf '\nPASS: fixed shelter live trace and capture evidence verified.\n'
elif [ "$MODE" = "natural" ]; then
    require_trace 'natural=on tick=0 mutation=none' 'natural mode was explicitly enabled without mutation'
    require_trace 'tick=1 .*focus=agent_2 action=approach_resource .*resourceSeen=wood@24,68,-22:naturalWorld#1520 .*reservationOwner=agent_2 navigationPurpose=resource navigation=active' 'natural oak target lock, reservation, and route'
    require_trace 'tick=3 .*focus=agent_2 action=approach_resource .*navigationPurpose=resource navigation=arrived' 'wood route arrives one step per tick'
    require_trace 'natural harvest actor=agent_2 target=24,68,-22 resource=wood source=naturalWorld fingerprint=1520 blockAfter=0 cleanupRestore=0 inventoryCredit=1 memory=resource_harvested' 'oak block removed permanently and credited once'
    require_trace 'tick=4 .*action=harvest_block .*naturalHarvests=1 .*inventoryByResource=.*wood:1.*conservation=1:1\+0\+0(\+0\+0)?:exact' 'wood harvest state and conservation'
    require_trace 'natural harvest actor=agent_2 target=24,68,-20 resource=stone source=naturalWorld fingerprint=48 blockAfter=0 cleanupRestore=0 inventoryCredit=1 memory=resource_harvested' 'adjacent stone block removed permanently and credited once'
    require_trace 'tick=5 .*action=harvest_block .*resourceSeen=wood@24,67,-22:naturalWorld#1520 .*naturalHarvests=2 .*inventoryByResource=.*wood:1,stone:1.*conservation=2:2\+0\+0(\+0\+0)?:exact' 'stone harvest reaches quota exactly'
    require_trace 'tick=7 .*goals=.*agent_2:deliverResources.*action=return_home .*navigationPurpose=homeDelivery navigation=active' 'existing bounded home route starts one step per tick'
    require_trace 'tick=9 .*goals=.*agent_2:deliverResources.*action=return_home .*navigationPurpose=homeDelivery navigation=arrived' 'existing bounded home route arrives'
    require_trace 'tick=10 .*action=deliver_resource .*inventoryByResource=.*wood:0,stone:0.*campStock=.*wood:1,stone:1.*deliveryOutcome=succeeded .*conservation=2:0\+2\+0(\+0\+0)?:exact' 'atomic delivery and exact conservation'
    require_trace 'natural gate=enabled active=yes actor=agent_2 .*harvestCount=2 rollbackCount=0 fixtures=0 conservation=2:0\+2\+0(\+0\+0)?:exact' 'natural status and zero fixtures'
    require_trace 'summary .*runtimeErrors=0 .*interactionRestored=1 .*naturalHarvests=2 naturalRollbacks=0 naturalRestoredAfterSuccess=0 .*conservation=2:0\+2\+0(\+0\+0)?:exact .*cleanupRestoredBlocks=0' 'clean runtime and no natural cleanup restoration'
    printf '\nPASS: natural wood/stone live trace and capture evidence verified.\n'
elif [ "$MODE" = "h2" ]; then
    require_trace 'interaction setup mode=distant distance=4 .*corridorObserved=9 corridorChanged=0 fixtureSetupMutations=1' 'setup changed only the final fixture block'
    require_trace 'tick=1 .*focus=agent_2 action=approach_resource .*reservationOwner=agent_2 navigationPurpose=resource navigation=active routeLength=4 routeIndex=1 stepsRemaining=2' 'tick 1 target reservation and first step'
    require_trace 'tick=2 .*focus=agent_2 action=approach_resource .*navigationPurpose=resource navigation=active routeLength=4 routeIndex=2 stepsRemaining=1' 'tick 2 single-step route progress'
    require_trace 'tick=3 .*focus=agent_2 action=approach_resource .*navigationPurpose=resource navigation=arrived routeLength=4 routeIndex=3 stepsRemaining=0' 'tick 3 adjacent arrival'
    require_trace 'tick=4 .*focus=agent_2 action=harvest_block .*navigationPurpose=none navigation=idle routeLength=0 .*invalidation=harvested .*interactionSucceeded=1' 'tick 4 transactional harvest'
    require_trace 'tick=1 .*corridorObserved=9 corridorChanged=0 fixtureSetupMutations=1' 'corridor unchanged during tick 1'
    require_trace 'tick=2 .*corridorObserved=9 corridorChanged=0 fixtureSetupMutations=1' 'corridor unchanged during tick 2'
    require_trace 'tick=3 .*corridorObserved=9 corridorChanged=0 fixtureSetupMutations=1' 'corridor unchanged during tick 3'
    require_trace 'tick=4 .*corridorObserved=9 corridorChanged=0 fixtureSetupMutations=1' 'corridor unchanged after harvest'
    require_trace 'interaction gate=enabled .*actualDistance=1 .*harvested=yes .*inventory=1/8 outcome=succeeded memory=resource_harvested .*corridorObserved=9 corridorChangedSetup=0 corridorChangedNavigation=0 corridorChangedHarvest=0 fixtureSetupMutations=1' 'final inventory, memory, and read-only corridor'
    require_trace 'summary .*runtimeErrors=0 .*interactionRestored=1 .*corridorObserved=9 corridorChangedCleanup=0 cleanupRestoredBlocks=1' 'clean runtime and one-block cleanup'
    printf '\nPASS: H2 live trace and capture evidence verified.\n'
elif [ "$MODE" = "economy" ]; then
    require_trace 'economy setup actor=agent_2 fixtures=.*foodRaw.*wood.*stone.*corridorChanged=0 fixtureSetupMutations=3' 'three target-only fixtures were created'
    require_trace 'action=harvest_block .*inventoryByResource=.*foodRaw:1.*fixtures=.*foodRaw:0:harvested.*conservation=1:1\+0\+0(\+0\+0)?:exact' 'first resource harvested exactly once'
    require_trace 'action=harvest_block .*inventoryByResource=.*foodRaw:1,wood:1.*fixtures=.*wood:1:harvested.*conservation=2:2\+0\+0(\+0\+0)?:exact' 'second resource kind harvested exactly once'
    require_trace 'goals=.*agent_2:deliverResources.*action=return_home .*navigationPurpose=homeDelivery' 'delivery goal uses bounded home route'
    require_trace 'action=deliver_resource .*inventoryByResource=.*foodRaw:0,wood:0.*campStock=.*foodRaw:1,wood:1.*deliveryOutcome=succeeded .*conservation=2:0\+2\+0(\+0\+0)?:exact' 'atomic delivery and exact conservation'
    require_trace 'economy active=yes .*inventoryTotal=0/8 .*campStockTotal=2 .*deliveryOutcome=succeeded .*memory=resource_delivered .*conservation=2:0\+2\+0(\+0\+0)?:exact .*corridorChangedSetup=0 corridorChangedNavigation=0 corridorChangedHarvest=0' 'final economy status'
    require_trace 'summary .*runtimeErrors=0 .*interactionRestored=1 .*conservation=2:0\+2\+0(\+0\+0)?:exact .*corridorChangedCleanup=0 cleanupRestoredBlocks=3' 'clean runtime and three-block cleanup'
    printf '\nPASS: Phase I closed-economy live trace and capture evidence verified.\n'
else
    require_trace 'economy setup actor=agent_2 fixtures=.*foodRaw.*wood.*stone.*corridorChanged=0 fixtureSetupMutations=3' 'three target-only fixtures were created'
    require_trace 'tick=1 .*movement=off .*survival=on .*hunger=0\.05 fatigue=0\.06 health=100' 'bounded survival need progression starts deterministically'
    require_trace 'tick=7 .*movement=off .*survival=on .*hunger=0\.35 fatigue=0\.42 health=100' 'pre-hunger progression remains bounded without movement'
    require_trace 'tick=8 .*action=approach_resource .*resourceSeen=foodRaw@.*reservationOwner=agent_2 navigationPurpose=resource navigation=active .*survival=on' 'threshold-crossing tick selects foodRaw and starts reserved navigation'
    require_trace 'tick=9 .*goals=.*agent_2:satisfyHunger.*focus=agent_2 action=approach_resource .*resourceSeen=foodRaw@.*navigationPurpose=resource navigation=active' 'hunger goal engages and the food route progresses one step'
    require_trace 'tick=10 .*focus=agent_2 action=approach_resource .*navigationPurpose=resource navigation=arrived' 'food route reaches cardinal adjacency'
    require_trace 'tick=11 .*focus=agent_2 action=harvest_block .*interactionSucceeded=1 .*inventoryByResource=.*foodRaw:1.*conservation=1:1\+0\+0(\+0\+0)?:exact' 'foodRaw harvest uses the existing transaction'
    require_trace 'tick=12 .*focus=agent_2 action=consume_food .*hunger=0\.00 .*foodConsumed=1 .*consumptionOutcome=succeeded consumptionSucceeded=1 survivalMemory=food_consumed .*inventoryByResource=.*foodRaw:0.*conservation=1:0\+0\+1(\+0\+0)?:exact' 'atomic food consumption and extended conservation'
    require_trace 'tick=13 .*goals=.*agent_2:rest.*action=return_home .*survivalStatus=exhausted' 'fatigue switches to committed rest'
    require_trace 'tick=14 .*focus=agent_2 action=return_home .*navigationPurpose=homeRest navigation=active' 'rest reuses bounded home route'
    require_trace 'tick=16 .*focus=agent_2 action=return_home .*navigationPurpose=homeRest navigation=arrived' 'rest route arrives at home one step per tick'
    require_trace 'tick=17 .*focus=agent_2 action=rest .*survivalStatus=stable .*fatigue=0\.00' 'rest recovers fatigue at home'
    require_trace 'tick=18 .*goals=.*agent_2:collectResource.*survivalStatus=stable' 'normal economy goal resumes after recovery'
    require_trace 'survival active=yes .*foodRaw=0 foodConsumed=1 .*consumptionOutcome=succeeded memory=food_consumed .*conservation=1:0\+0\+1(\+0\+0)?:exact' 'survival status exposes the successful transaction'
    require_trace 'summary .*runtimeErrors=0 .*interactionRestored=1 .*conservation=1:0\+0\+1(\+0\+0)?:exact .*corridorChangedCleanup=0 cleanupRestoredBlocks=3' 'clean survival runtime and fixture-only cleanup'
    printf '\nPASS: Phase J survival live trace and capture evidence verified.\n'
fi
printf 'The PNG still requires visual inspection; see %s\n' "$RUNBOOK"
printf 'Retained isolated session: %s\n' "$SESSION_ROOT"
