#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
RUNBOOK="$ROOT_DIR/docs/pebblelab-3d-live-prototype.md"
MODE="survival"
WORLD_SEED="12345"

usage() {
    cat <<EOF
Usage: scripts/verify-pebblelab-live.sh [--dry-run] [--survival|--economy|--h2|--natural|--build|--social|--physical|--cooperation|--persistence|--population|--multiscale|--ecology|--mortality]
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
  --natural  Run natural wood/stone harvest and delivery with no fixtures.
  --build    Run fixed shelter acquisition, construction, interruption, rest, and clear.
  --social   Run directed grounded information, read-only verification, and trust.
  --physical Run local sound, pointing gesture, imperfect perception, and existing trust.
  --cooperation Run shared construction-material task, delivery, and shelter completion.
  --persistence Run checkpoint, real process restart, causal replay, and uninterrupted control.
  --population Run bounded migrant admission, mid-route restart, arrival, and uninterrupted control.
  --multiscale Run bounded settlement pulses, v3 restart, uninterrupted, and metrics-off controls.
  --ecology Run local forage scarcity, v4 restart, regeneration, and uninterrupted control.
  --mortality Run starvation mortality, v5 pre/post restart, probe exit, and replacement migration.
  --help     Show this help and exit.
EOF
}

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
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

DRY_RUN=0
MODE_OPTIONS=0
for option in "$@"; do
    case "$option" in
        --dry-run) DRY_RUN=1 ;;
        --survival) MODE="survival"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --economy) MODE="economy"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --h2) MODE="h2"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --natural) MODE="natural"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --build) MODE="build"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --social) MODE="social"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --physical) MODE="physical"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --cooperation) MODE="cooperation"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --persistence) MODE="persistence"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --population) MODE="population"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --multiscale) MODE="multiscale"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --ecology) MODE="ecology"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --mortality) MODE="mortality"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
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
COOPERATION_GATE=0
PERSISTENCE_GATE=0
POPULATION_GATE=0
MULTISCALE_GATE=0
ECOLOGY_GATE=0
MORTALITY_GATE=0
if [ "$MODE" = "mortality" ]; then
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
    if [ "$MODE" = "build" ]; then
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
    printf '  PEBBLELAB_APP_AGENTS_COOPERATION=%s\n' "$COOPERATION_GATE"
    printf '  PEBBLELAB_APP_AGENTS_PERSISTENCE=%s\n' "$PERSISTENCE_GATE"
    printf '  PEBBLELAB_APP_AGENTS_POPULATION=%s\n' "$POPULATION_GATE"
    printf '  PEBBLELAB_APP_AGENTS_MULTISCALE=%s\n' "$MULTISCALE_GATE"
    printf '  PEBBLELAB_APP_AGENTS_ECOLOGY=%s\n' "$ECOLOGY_GATE"
    printf '  PEBBLELAB_APP_AGENTS_MORTALITY=%s\n' "$MORTALITY_GATE"
    printf '  PEBBLELAB_DISPOSABLE_WORLD_PROOF=1\n'
    printf '  PEBBLE_CMD=%s\n' "$LAB_COMMANDS"
    if [ "$MODE" = "build" ]; then
        printf '  PEBBLE_SHOT=-|%s/fixed-shelter-before.png|%s/fixed-shelter-partial.png|%s|-\n' \
            "$(dirname "$capture_path")" "$(dirname "$capture_path")" "$capture_path"
    elif [ "$MODE" = "physical" ]; then
        printf '  PEBBLE_SHOT=%s/physical-before.png|%s/physical-during.png|%s\n' \
            "$(dirname "$capture_path")" "$(dirname "$capture_path")" "$capture_path"
    elif [ "$MODE" = "cooperation" ]; then
        printf '  PEBBLE_SHOT=%s/cooperation-before.png|%s/cooperation-offer.png|%s\n' \
            "$(dirname "$capture_path")" "$(dirname "$capture_path")" "$capture_path"
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
    if [ "$MODE" = "mortality" ]; then
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
        && [ "$MODE" != "mortality" ]; then
        printf '  4. Inspect the PNG manually; the hook does not provide a pixel assertion.\n'
    fi
    printf '  5. Keep or manually remove only this validated PebbleLab temporary session directory. The script deletes nothing.\n'
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

[ -d "$ROOT_DIR/.git" ] || { printf 'Repository not found: %s\n' "$ROOT_DIR" >&2; exit 1; }
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
if [ "$MODE" = "build" ]; then
    CAPTURE_BEFORE_PATH="$CAPTURE_DIR/fixed-shelter-before.png"
    CAPTURE_PARTIAL_PATH="$CAPTURE_DIR/fixed-shelter-partial.png"
    SHOT_SPEC="-|$CAPTURE_BEFORE_PATH|$CAPTURE_PARTIAL_PATH|$CAPTURE_PATH|-"
elif [ "$MODE" = "physical" ]; then
    CAPTURE_BEFORE_PATH="$CAPTURE_DIR/physical-before.png"
    CAPTURE_DURING_PATH="$CAPTURE_DIR/physical-during.png"
    SHOT_SPEC="$CAPTURE_BEFORE_PATH|$CAPTURE_DURING_PATH|$CAPTURE_PATH"
elif [ "$MODE" = "cooperation" ]; then
    CAPTURE_BEFORE_PATH="$CAPTURE_DIR/cooperation-before.png"
    CAPTURE_DURING_PATH="$CAPTURE_DIR/cooperation-offer.png"
    SHOT_SPEC="$CAPTURE_BEFORE_PATH|$CAPTURE_DURING_PATH|$CAPTURE_PATH"
else
    SHOT_SPEC="$CAPTURE_PATH@240"
fi

print_plan "$SESSION_ROOT" "$CAPTURE_PATH" "$TRACE_PATH"
printf '\nLaunching Pebble now. Personal Pebble data is hidden by CFFIXED_USER_HOME.\n\n'

if /usr/bin/pgrep -x Pebble >/dev/null 2>&1; then
    fail "a Pebble process is already running; refusing an ambiguous live baseline"
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
PEBBLELAB_APP_AGENTS_COOPERATION="$COOPERATION_GATE" \
PEBBLELAB_APP_AGENTS_PERSISTENCE="$PERSISTENCE_GATE" \
PEBBLELAB_APP_AGENTS_POPULATION="$POPULATION_GATE" \
PEBBLELAB_APP_AGENTS_MULTISCALE="$MULTISCALE_GATE" \
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
if [ "$MODE" = "build" ] || [ "$MODE" = "social" ] || [ "$MODE" = "physical" ] || [ "$MODE" = "cooperation" ]; then
    spawn_facts=$(/usr/bin/sqlite3 "$DB_PATH" "SELECT json_extract(json, '$.spawnX'), json_extract(json, '$.spawnY'), json_extract(json, '$.spawnZ') FROM worlds;")
    [ "$spawn_facts" = "8|75|-112" ] || fail "unexpected seed-46 spawn: $spawn_facts"
fi

require_trace "disposable-world name=$WORLD_NAME seed=$WORLD_SEED worldTick=0 dayTime=1000 weather=clear randomTickSpeed=0 mobSpawning=0" 'deterministic disposable world initialization'
require_trace "start seed=$WORLD_SEED agents=3 tick=0 hz=4 movement=on worldTick=[0-9]+ dayTime=1000 weather=clear randomTickSpeed=0 mobSpawning=0" 'deterministic agent session initial conditions'

[ -s "$CAPTURE_PATH" ] || fail "capture was not written: $CAPTURE_PATH"
if [ "$MODE" = "cooperation" ]; then
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
