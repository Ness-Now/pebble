#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
if [ "${1:-}" = "--dry-run" ]; then
    cat <<'EOF'
CIV-46: two real Pebble processes per seed, seeds 46 and 73.
Disposable CFFIXED_USER_HOME only; no personal worlds. Builds release Pebble
(PEBBLELAB_CIV46_BUILD_CONFIGURATION=debug allows the same campaign in debug).
PEBBLELAB_APP_AGENTS_WRITING=1, PEBBLELAB_APP_AGENTS_ARCHIVE=1 and
PEBBLELAB_DISPOSABLE_WORLD_PROOF=1.
The non-civilization player camera is creative so terrain water cannot kill
the observer while the bounded proof runs; civilization actors are unchanged.
Process 1 reuses CIV-45's disclosed blank-sign fixture, inscribes it through
the production adapter, creates one physical catalogue and writes a schema-41
checkpoint. Process 2 reloads the World and checkpoint, rebuilds the derived
index, retrieves through current Core authority, checks idempotence, removes
the carrier, proves search/retrieval refusal without cognitive publication,
and restores the disposable fixture exactly.
Captures and complete traces are retained under /tmp/pebblelab-civ46-live.*.
Capture inspection remains a separate required action; this script makes no
pixel claim.
EOF
    exit 0
fi
[ "$#" -eq 0 ] || exit 2
cd "$ROOT_DIR"
BUILD_CONFIGURATION=${PEBBLELAB_CIV46_BUILD_CONFIGURATION:-release}
case "$BUILD_CONFIGURATION" in debug|release) ;; *) exit 2 ;; esac
swift build -c "$BUILD_CONFIGURATION" --product Pebble
PROOF_ROOT=$(mktemp -d /tmp/pebblelab-civ46-live.XXXXXX)
export PEBBLELAB_CIV46_CAMPAIGN_ROOT="$PROOF_ROOT"
export PEBBLELAB_CIV46_BUILD_CONFIGURATION="$BUILD_CONFIGURATION"
python3 - <<'PY'
import os, pathlib, subprocess
root = pathlib.Path(os.environ['PEBBLELAB_CIV46_CAMPAIGN_ROOT'])
binary = (pathlib.Path('.build') /
          os.environ['PEBBLELAB_CIV46_BUILD_CONFIGURATION'] /
          'Pebble').resolve()
for seed in [46, 73]:
    case = root / str(seed)
    case.mkdir()
    home = case / 'home'
    home.mkdir()
    env = dict(
        os.environ,
        CFFIXED_USER_HOME=str(home),
        PEBBLE_AUTOLOAD='1',
        PEBBLELAB_APP_AGENTS='1',
        PEBBLELAB_APP_AGENTS_MOVE='1',
        PEBBLELAB_APP_PROBES='1',
        PEBBLELAB_DEBUG_ENTITIES='1',
        PEBBLELAB_APP_AGENTS_TRACE='1',
        PEBBLELAB_APP_AGENTS_WRITING='1',
        PEBBLELAB_APP_AGENTS_ARCHIVE='1',
        PEBBLELAB_DISPOSABLE_WORLD_PROOF='1',
        PEBBLELAB_CIV45_PROOF_DIR=str(case),
        PEBBLELAB_CIV46_PROOF_DIR=str(case),
    )
    boot = ('/gamemode creative;/gamerule randomTickSpeed 0;'
            '/gamerule doMobSpawning false;'
            '/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;'
            '/time set 1000;/weather clear;/tp 14 68 -18|/lab start;'
            '/lab pause;/lab movement off;/lab overlay off')
    for phase in ['write', 'read']:
        if phase == 'write':
            env['PEBBLE_NEWWORLD'] = str(seed)
            env['PEBBLE_NEWWORLD_NAME'] = f'PebbleLab-Disposable-Archive-{seed}'
            commands = (boot + ';/lab writing proof write;'
                        '/lab archive proof write;/lab writing proof camera|'
                        '/lab archive status')
            shots = f'-|-|{case}/catalogued.png'
        else:
            env.pop('PEBBLE_NEWWORLD', None)
            env.pop('PEBBLE_NEWWORLD_NAME', None)
            commands = (boot + ';/lab writing proof camera|'
                        '/lab archive proof read;/lab stop')
            shots = f'-|-|{case}/before-loss.png'
        env['PEBBLE_CMD'] = commands
        env['PEBBLE_SHOT'] = shots
        trace = case / f'{phase}.log'
        with trace.open('w') as stream:
            result = subprocess.run(
                [str(binary)],
                env=env,
                stdout=stream,
                stderr=subprocess.STDOUT,
                timeout=300,
            )
        text = trace.read_text()
        assert result.returncode == 0, (
            seed, phase, result.returncode, str(trace)
        )
        assert 'status=FAIL' not in text, str(trace)
        assert '[lab-live] error' not in text, str(trace)
        assert f'CIV46_LIVE phase={phase} ' in text, str(trace)
        assert 'status=PASS' in text, str(trace)
        if phase == 'read':
            assert 'cleanup=verified' in text, str(trace)
        print(
            f'CIV46_LIVE_PROCESS seed={seed} phase={phase} '
            f'exit=0 trace={trace}',
            flush=True,
        )
    assert (case / 'catalogued.png').is_file()
    assert (case / 'before-loss.png').is_file()
    assert (case / 'archive-checkpoint.json').is_file()
    assert (case / 'archive-retrieved-checkpoint.json').is_file()
assert subprocess.run(
    ['/usr/bin/pgrep', '-x', 'Pebble'],
    stdout=subprocess.DEVNULL,
).returncode == 1
print(
    'PASS: CIV-46 two-seed/two-process archive persistence, bounded rebuild, '
    f'current retrieval, loss refusal and cleanup; evidence={root}'
)
PY
