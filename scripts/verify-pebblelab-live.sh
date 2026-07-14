#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
RUNBOOK="$ROOT_DIR/docs/pebblelab-3d-live-prototype.md"
MODE="survival"
WORLD_SEED="12345"

usage() {
    cat <<EOF
Usage: scripts/verify-pebblelab-live.sh [--dry-run] [--survival|--economy|--h2|--natural|--build|--social|--physical|--cooperation]
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
if [ "$MODE" = "cooperation" ]; then
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
    if [ "$MODE" = "cooperation" ]; then
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
    printf '  4. Inspect the PNG manually; the hook does not provide a pixel assertion.\n'
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
