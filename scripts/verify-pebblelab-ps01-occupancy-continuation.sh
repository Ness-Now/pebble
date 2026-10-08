#!/usr/bin/env bash
set -euo pipefail
[ "${PEBBLE_REGOLD+x}" != x ] || { printf 'PEBBLE_REGOLD must be absent.\n' >&2; exit 1; }
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
MODE=headless
DRY=0
EVIDENCE=/tmp/pebblelab-ps01-occupancy-evidence
for arg in "$@"; do
    case "$arg" in
        --headless) MODE=headless ;;
        --live) MODE=live ;;
        --dry-run) DRY=1 ;;
        /tmp/*|/private/tmp/*) EVIDENCE=$arg ;;
        *) printf 'Usage: %s [--dry-run] [--headless|--live] /tmp/evidence-directory\n' "$0" >&2; exit 2 ;;
    esac
done
cd "$ROOT_DIR"
python3 - "$ROOT_DIR" "$EVIDENCE" "$MODE" "$DRY" <<'PY'
import hashlib,json,os,pathlib,shutil,sqlite3,subprocess,sys,time
root=pathlib.Path(sys.argv[1]); evidence=pathlib.Path(sys.argv[2])
mode=sys.argv[3]; dry=sys.argv[4]=='1'
hardware=subprocess.run(['sysctl','-n','hw.optional.arm64'],stdout=subprocess.PIPE,stderr=subprocess.DEVNULL)
native_arch='arm64' if hardware.stdout.strip()==b'1' else 'x86_64'
swift_build=['swift','build','--arch',native_arch]
names=['AGENTS','PROBES','AGENTS_OBSERVER','AGENTS_MOVE','AGENTS_INTERACT',
 'AGENTS_MATERIAL','AGENTS_PERSISTENCE','AGENTS_POPULATION','AGENTS_LIFECYCLE',
 'AGENTS_KINSHIP','AGENTS_HOUSEHOLDS','AGENTS_CARE','AGENTS_CHILDHOOD','AGENTS_FAMILY',
 'AGENTS_MORTALITY','AGENTS_HOMEOSTASIS','AGENTS_GENETICS','AGENTS_SKILLS',
 'AGENTS_ECOLOGICAL_OBSERVATION','AGENTS_WILD_SUBSISTENCE','AGENTS_AUTONOMOUS_CIVILIZATION']
gates={'PEBBLELAB_APP_'+name:'1' for name in names}; gates['PEBBLELAB_DEBUG_ENTITIES']='1'
if dry:
 print(json.dumps({'mode':mode,'evidence':str(evidence),'gates':gates,
  'nativeArchitecture':native_arch,
  'build':[' '.join(swift_build+['-c','release','--product',name]) for name in ['Pebble','pebsmoke']],
  'headless':['Core continuation-restoration suite','controlled capture/admission attacks',
   'two independent natural seed-5 writers, 18000 ordinary ticks after 52 tick bootstrap',
   'zero/one/several/custody/late restore faults and same-process retry','natural and Save/Exit fresh readers','exact semantic deterministic comparison'],
  'live':['real Pebble app: natural writer before Save/Continue and Save/Exit',
   'real fresh Pebble app: reader after exact continuation',
   'inspect actual Metal write.png, continue.png and read.png; no actor/terrain scene staging'],
  'runtimeIsolation':'new Foundation home per writer; independent copied homes for each reader/fault',
  'pushAttempted':'NO'},indent=2));sys.exit(0)
evidence.mkdir(parents=True,exist_ok=True)
commands=[]
base={k:v for k,v in os.environ.items() if not k.startswith('PEBBLE') and k!='CFFIXED_USER_HOME'}
def environment(home, phase=None, live=False, output=None):
 env=dict(base,**gates);env['CFFIXED_USER_HOME']=str(home)
 if phase:
  env['PEBBLELAB_PS01_OCCUPANCY_'+('LIVE_PHASE' if live else 'PHASE')]=phase
  env['PEBBLELAB_PS01_OCCUPANCY_OUTPUT']=str(output)
 if live: env['PEBBLELAB_PS01_OCCUPANCY_LIVE_CAPTURE_DIR']=str(evidence)
 return env
def record(argv,env,label):
 row={'label':label,'argv':list(map(str,argv)),
      'environment':{k:v for k,v in env.items() if k.startswith('PEBBLE') or k=='CFFIXED_USER_HOME'},
      'started':time.time()}
 commands.append(row);(evidence/'commands.json').write_text(json.dumps(commands,indent=2)+'\n')
 return row
def run(argv,env,label):
 row=record(argv,env,label)
 with (evidence/(label+'.log')).open('w') as log:
  result=subprocess.run(list(map(str,argv)),cwd=str(root),env=env,stdout=log,stderr=subprocess.STDOUT)
 row['exit']=result.returncode;row['completed']=time.time()
 (evidence/'commands.json').write_text(json.dumps(commands,indent=2)+'\n')
 print(label,'exit',result.returncode,flush=True)
 if result.returncode: raise RuntimeError(label+' failed; inspect '+str(evidence/(label+'.log')))
def saved_boundary(home,label):
 paths=list(home.rglob('pebble.db'))
 assert len(paths)==1,'expected one isolated Core database'
 source=sqlite3.connect(str(paths[0]));copy=sqlite3.connect(str(evidence/(label+'.sqlite3')))
 try:
  source.backup(copy)
  world=json.loads(source.execute('SELECT json FROM worlds WHERE id=?',('ps01-i09-seed-5-founders-24',)).fetchone()[0])
  player=json.loads(source.execute('SELECT json FROM player WHERE world=?',(world['id'],)).fetchone()[0])
  revision,payload=source.execute('SELECT revision,payload FROM world_continuations WHERE world=?',(world['id'],)).fetchone()
  assert world['seed']==5 and world['difficulty']==2 and world['dims']['0']['time'] in [18052,18072]
  (evidence/(label+'-world-boundary.json')).write_text(json.dumps({'world':world,'player':player,
   'continuationRevision':revision,'continuation':json.loads(payload),
   'payloadSHA256':hashlib.sha256(payload).hexdigest()},indent=2)+'\n')
 finally: copy.close();source.close()
if os.environ.get('PEBBLELAB_OCCUPANCY_SKIP_BUILD')!='1':
 run(swift_build+['-c','release','--product','Pebble'],base,'build-pebble')
 run(swift_build+['-c','release','--product','pebsmoke'],base,'build-smoke')
binroot=pathlib.Path(subprocess.check_output(swift_build+['-c','release','--show-bin-path'],cwd=str(root),env=base).decode().strip())
hashes={str(p.relative_to(root)):hashlib.sha256(p.read_bytes()).hexdigest()
 for folder in ['Sources/PebbleCore','Sources/PebbleAgents','Sources/Pebble','Sources/pebsmoke']
 for p in sorted((root/folder).rglob('*.swift'))}
hashes.update({str(binroot/name):hashlib.sha256((binroot/name).read_bytes()).hexdigest() for name in ['Pebble','pebsmoke']})
(evidence/'source-executable-hashes.json').write_text(json.dumps(hashes,indent=2)+'\n')
if mode=='live':
 home=evidence/'native-home';home.mkdir(exist_ok=False)
 output=evidence/'native-boundary.json'
 run([binroot/'Pebble'],environment(home,'write',True,output),'native-write')
 saved_boundary(home,'native-writer')
 naturalhome=pathlib.Path(str(home)+'.natural')
 naturaloutput=pathlib.Path(str(output)+'.natural.json')
 run([binroot/'Pebble'],environment(naturalhome,'read',True,naturaloutput),'native-read')
 finalhome=evidence/'native-final-reader-home';shutil.copytree(home,finalhome)
 run([binroot/'Pebble'],environment(finalhome,'read',output=output),'native-final-read')
 print('PASS: native writer/continue/fresh reader. Inspect three Metal captures before claiming VGS.',flush=True)
else:
 corehome=evidence/'core-home';corehome.mkdir(exist_ok=False)
 coreenv=dict(base,CFFIXED_USER_HOME=str(corehome),PEBBLELAB_SMOKE_ONLY='continuation-restoration')
 run([binroot/'pebsmoke'],coreenv,'core-focused')
 controlled=evidence/'controlled-home';controlled.mkdir(exist_ok=False)
 run([binroot/'Pebble'],environment(controlled,'controlled',output=evidence/'controlled.json'),'controlled')
 writers=[]
 try:
  for label in ['a','b']:
   home=evidence/('home-'+label);home.mkdir(exist_ok=False)
   output=evidence/('boundary-'+label+'.json');env=environment(home,'write',output=output)
   row=record([binroot/'Pebble'],env,'write-'+label)
   log=(evidence/('write-'+label+'.log')).open('w')
   proc=subprocess.Popen([str(binroot/'Pebble')],cwd=str(root),env=env,stdout=log,stderr=subprocess.STDOUT)
   writers.append((proc,log,row,home,output,label))
   print('started natural writer',label,'pid',proc.pid,flush=True)
  for proc,log,row,home,output,label in writers:
   code=proc.wait();log.close();row['exit']=code;row['completed']=time.time()
   (evidence/'commands.json').write_text(json.dumps(commands,indent=2)+'\n')
   if code: raise RuntimeError('natural writer '+label+' failed')
 finally:
  for proc,log,*_ in writers:
   if proc.poll() is None: proc.terminate();proc.wait()
   if not log.closed: log.close()
 for proc,log,row,home,output,label in writers:
  saved_boundary(home,'writer-'+label)
  naturalhome=pathlib.Path(str(home)+'.natural')
  naturaloutput=pathlib.Path(str(output)+'.natural.json')
  saved_boundary(naturalhome,'natural-writer-'+label)
  if label=='a':
   for fault in ['zero','one','several','custody','late']:
    faulthome=evidence/('fault-'+fault+'-home');shutil.copytree(naturalhome,faulthome)
    faultenv=environment(faulthome,'restore-fault',output=naturaloutput)
    faultenv['PEBBLELAB_PS01_OCCUPANCY_FAULT']=fault
    run([binroot/'Pebble'],faultenv,'restore-fault-'+fault)
  for kind,source,expected in [('natural',naturalhome,naturaloutput),('exit',home,output)]:
   reader=evidence/('reader-'+label+'-'+kind+'-home');shutil.copytree(source,reader)
   run([binroot/'Pebble'],environment(reader,'read',output=expected),'read-'+label+'-'+kind)
 a=json.loads((evidence/'boundary-a.json').read_text());b=json.loads((evidence/'boundary-b.json').read_text())
 ra=json.loads((evidence/'boundary-a.json.read.json').read_text());rb=json.loads((evidence/'boundary-b.json.read.json').read_text())
 na=json.loads((evidence/'boundary-a.json.natural.json').read_text());nb=json.loads((evidence/'boundary-b.json.natural.json').read_text())
 assert na==nb,'natural boundary semantic state differs across repeats'
 assert a==b,'Save/Exit semantic state differs across repeats'
 assert ra==rb,'fresh continued Session state differs across repeats'
 (evidence/'deterministic-repeat.json').write_text(json.dumps({'naturalBoundaryEqual':True,'exitBoundaryEqual':True,'readerEqual':True,
   'ordinaryRuntimeIDsCompared':False,'semanticDigest':a['semanticDigest']},indent=2)+'\n')
 print('PASS: complete natural seed-5 capture/continuation, rollback, fresh readers and deterministic repeat.',flush=True)
PY
