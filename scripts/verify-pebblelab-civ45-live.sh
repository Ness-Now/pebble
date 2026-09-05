#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
if [ "${1:-}" = "--dry-run" ]; then
    cat <<'EOF'
CIV-45: two real Pebble processes per seed, seeds 46 and 73.
Disposable CFFIXED_USER_HOME only; no personal worlds. Builds release Pebble
(PEBBLELAB_CIV45_BUILD_CONFIGURATION=debug allows the same campaign in debug).
PEBBLELAB_APP_AGENTS_WRITING=1 and PEBBLELAB_DISPOSABLE_WORLD_PROOF=1.
Normal safe bootstrap near (14,68,-18), unflattened terrain, bounded local site search.
Disclosed fixture inputs: one blank oak sign and one oak log on existing support.
Process 1: real inscription, late rollback, first notation lesson, World save and schema-40 checkpoint.
Process 2: World reload, exact checkpoint restore, second local lesson, false reading,
normal text edit, sign replacement refusal, fixture restoration and normal probe cleanup.
Captures and complete traces retained under /tmp/pebblelab-civ45-live.*.
Capture inspection remains a separate required action; this script makes no pixel claim.
EOF
    exit 0
fi
[ "$#" -eq 0 ] || exit 2
cd "$ROOT_DIR"
BUILD_CONFIGURATION=${PEBBLELAB_CIV45_BUILD_CONFIGURATION:-release}
case "$BUILD_CONFIGURATION" in debug|release) ;; *) exit 2 ;; esac
swift build -c "$BUILD_CONFIGURATION" --product Pebble
PROOF_ROOT=$(mktemp -d /tmp/pebblelab-civ45-live.XXXXXX)
export PEBBLELAB_CIV45_CAMPAIGN_ROOT="$PROOF_ROOT"
export PEBBLELAB_CIV45_BUILD_CONFIGURATION="$BUILD_CONFIGURATION"
python3 - <<'PY'
import json, os, pathlib, subprocess
root = pathlib.Path(os.environ['PEBBLELAB_CIV45_CAMPAIGN_ROOT'])
binary = pathlib.Path('.build') / os.environ['PEBBLELAB_CIV45_BUILD_CONFIGURATION'] / 'Pebble'
binary = binary.resolve()
for seed in [46, 73]:
    case = root / str(seed)
    case.mkdir()
    home = case / 'home'
    home.mkdir()
    env = dict(os.environ, CFFIXED_USER_HOME=str(home), PEBBLE_AUTOLOAD='1',
        PEBBLELAB_APP_AGENTS='1', PEBBLELAB_APP_AGENTS_MOVE='1',
        PEBBLELAB_APP_PROBES='1', PEBBLELAB_DEBUG_ENTITIES='1',
        PEBBLELAB_APP_AGENTS_TRACE='1', PEBBLELAB_APP_AGENTS_WRITING='1',
        PEBBLELAB_DISPOSABLE_WORLD_PROOF='1', PEBBLELAB_CIV45_PROOF_DIR=str(case))
    boot = '/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 68 -18|/lab start;/lab pause;/lab movement off;/lab overlay off'
    for phase in ['write', 'read']:
        commands = boot + f';/lab writing proof {phase}'
        if phase == 'write':
            env['PEBBLE_NEWWORLD'] = str(seed)
            env['PEBBLE_NEWWORLD_NAME'] = f'PebbleLab-Disposable-Writing-{seed}'
            commands += ';/lab writing proof camera|/lab writing status agent_1'
            shots = f'-|-|{case}/written.png'
        else:
            env.pop('PEBBLE_NEWWORLD', None)
            env.pop('PEBBLE_NEWWORLD_NAME', None)
            commands += ';/lab writing proof camera|/lab writing status agent_1|/lab writing proof destroy;/lab stop'
            shots = f'-|-|{case}/read.png|-'
        env['PEBBLE_CMD'] = commands
        env['PEBBLE_SHOT'] = shots
        trace = case / f'{phase}.log'
        with trace.open('w') as stream:
            result = subprocess.run([str(binary)], env=env, stdout=stream,
                stderr=subprocess.STDOUT, timeout=300)
        text = trace.read_text()
        assert result.returncode == 0, (seed, phase, result.returncode, str(trace))
        assert 'status=FAIL' not in text and '[lab-live] error' not in text, str(trace)
        assert f'phase={phase} ' in text and 'status=PASS' in text, str(trace)
        assert 'cleanup' in text, ('missing lifecycle cleanup', str(trace))
        if phase == 'read':
            assert 'phase=destroy status=PASS cleanup=verified' in text, str(trace)
        print(f'CIV45_LIVE_PROCESS seed={seed} phase={phase} exit=0 trace={trace}', flush=True)
    assert (case / 'written.png').is_file() and (case / 'read.png').is_file()
assert subprocess.run(['/usr/bin/pgrep', '-x', 'Pebble'], stdout=subprocess.DEVNULL).returncode == 1
print(f'PASS: CIV-45 two-seed/two-process World persistence, local writing/literacy/read, rollback and cleanup; evidence={root}')
PY
