# PebbleLab — maquette 3D live

## Statut

La maquette rend par défaut les trois agents historiques PebbleLab observables
dans l’application Pebble. Sous gate population explicite, elle peut aussi
admettre un quatrième agent migrant dans un registre local borné à huit
membres. Elle expose leur cognition partagée, leur perception locale, leurs
déplacements cardinaux sûrs et l’influence de leur mémoire de mouvement. La
verticale population ne modifie aucun bloc du terrain.
Sous une gate multi-scale supplémentaire, `settlement-main` publie aussi un
frame administratif borné tous les quatre ticks. Cette vue collective ne
ralentit, ne remplace et ne pilote aucun tick agent.
Sous la gate ecology, des habitats réels lus dans le World portent aussi un
rendement alimentaire local borné. La cueillette ne casse aucun bloc et la
pression de subsistance reste un diagnostic collectif sans rétroaction.
Sous la gate mortality, la famine peut finaliser une sortie de population
bornée sans cadavre ni mutation du World ; seuls les agents actifs conservent
un probe.
Sous la gate lifecycle, un âge démographique déterministe et trois stages
bornés permettent une naissance locale sur un site World validé en lecture
seule, sans grossesse, famille, génétique ni mutation du World.

## Prérequis et lancement

Le cycle de développement et les validations permanentes sont décrits dans [`docs/pebblelab/DEVELOPMENT_WORKFLOW.md`](pebblelab/DEVELOPMENT_WORKFLOW.md). Pour une session Phase J reproductible qui n'expose aucun monde personnel, commencer par `scripts/verify-pebblelab-live.sh --dry-run`, puis lancer explicitement `scripts/verify-pebblelab-live.sh`. Les options `--economy`, `--h2`, `--natural`, `--social`, `--physical`, `--cooperation`, `--persistence`, `--population`, `--multiscale`, `--ecology`, `--mortality`, `--reproduction`, `--kinship` et `--households` conservent respectivement les preuves Phase I, H2, récolte naturelle J→K, information sociale CIV-03, canal physique CIV-04, tâche partagée CIV-05, restart/replay CIV-06, migration physique CIV-07, métriques settlement CIV-08, écologie alimentaire CIV-09, sortie de population CIV-10, âge/maturité/reproduction bornée CIV-11, parenté durable CIV-12A et appartenance household CIV-12B. Ce lanceur réutilise les hooks existants d'autoload, de monde neuf, de commandes et de capture, impose un monde jetable préfixé `PebbleLab-Disposable-` avec seed fixe et conserve monde, traces et captures sous un home temporaire isolé. La vérification visuelle de la capture reste manuelle.

Depuis la racine du dépôt :

```bash
PEBBLELAB_APP_AGENTS=1 \
PEBBLELAB_APP_AGENTS_MOVE=1 \
PEBBLELAB_APP_AGENTS_INTERACT=1 \
PEBBLELAB_APP_PROBES=1 \
PEBBLELAB_DEBUG_ENTITIES=1 \
PEBBLELAB_APP_AGENTS_OVERLAY=1 \
swift run -c release Pebble
```

Les quatre premières variables sont les gates obligatoires du preset de démonstration. `PEBBLELAB_APP_AGENTS_OVERLAY=1` sélectionne l’overlay compact par défaut. `PEBBLELAB_APP_AGENTS_TRACE=1` active les traces et `PEBBLELAB_APP_AGENTS_TRACE_EVERY=20` espace uniquement les traces périodiques.

## Démonstration

Dans le chat, lancer :

```text
/lab demo
```

Le preset démarre trois agents à 4 Hz, active le mouvement, focalise `agent_2`, suit le focus et affiche l’overlay compact. Il ne change ni le joueur, ni l’heure, ni la météo, ni les blocs.

Commandes de démonstration :

```text
/lab demo start
/lab demo status
/lab demo stop
```

## Commandes `/lab`

```text
/lab help
/lab start                       /lab stop          /lab clear
/lab pause                       /lab resume        /lab step
/lab speed <1|2|4|8>             /lab reset
/lab movement <on|off>
/lab interaction <setup|setup distant <2...8>|harvest|status|auto on|auto off>
/lab economy <setup|auto on|auto off|status|clear>
/lab survival <on|off|status>
/lab natural <on|off|status|scan>
/lab ecology <on|off|status|scan|clear>
/lab forage status
/lab mortality <on|off|status|clear>
/lab exits status
/lab lifecycle <on|status|clear>
/lab reproduction <on|off|status>
/lab births status
/lab kinship <on|status>
/lab household <on|status>
/lab social <on|off|status|clear>
/lab physical <on|off|status|clear>
/lab cooperation <on|off|status|clear>
/lab population <on|off|status|clear>
/lab migration <admit|status>
/lab settlement <on|off|status|clear>
/lab scale status
/lab checkpoint <status|list|save|load|delete>
/lab replay <status|start|stop|verify>
/lab status
/lab focus <agentId|next>        /lab next
/lab follow <agentId|focus|next|off>
/lab overlay <off|compact|full>
```

`/lab overlay on` reste un alias de `compact`. L’overlay compact est destiné aux démonstrations ; `full` expose le diagnostic détaillé. Sans commande explicite, F3 sélectionne le mode full et la variable d’environnement sélectionne compact.

`follow focus` suit dynamiquement l’agent focalisé ; un identifiant suit une cible fixe. Le follow ne déplace jamais le joueur : il oriente seulement sa vue. Le joueur reste libre de se déplacer.

## CIV-04 — Canal physique local

Le mode `scripts/verify-pebblelab-live.sh --physical` utilise un monde jetable neuf, la seed `46`, trois agents et les gates sociale et physique explicitement actives. La gate `PEBBLELAB_APP_AGENTS_PHYSICAL=1` reste désactivée par défaut et exige la gate sociale. Quand elle est active, une transmission CIV-03 devient un appel sonore local et un pointage vers le fait : la session ne crée le message et la belief qu’après une observation exacte de ces deux modalités au tick suivant. `/lab physical off` annule les signaux pending et arrête les présentations sans effacer les preuves sociales ; `/lab physical clear` efface uniquement l’état borné du canal, jamais le ledger causal ni le World.

Pebble réutilise le moteur audio existant pour demander une note courte à la position de l’émetteur. Le renderer affiche, pendant trois ticks au plus, un fil orange attaché au haut du proxy et orienté vers la position pointée. Ce fil de debug reste lisible devant le terrain afin que la capture automatisée démontre la pose ; il ne décide ni de la perception, ni du destinataire. L’adapter read-only calcule séparément distance, occlusion, chunks prêts et ligne de vue. Le succès matériel du son et le rendu n’alimentent jamais la cognition.

La preuve produit `physical-before.png`, `physical-during.png` et `physical-after.png`. La capture centrale doit montrer le fil orange, absent des deux autres. La trace doit montrer `requested=1` pour l’audio, une perception exacte de `agent_2`, une perception ambiguë du bystander `agent_0`, le message et la belief CIV-03, la vérification read-only puis le trust `0→10`. Les cas son seul, geste seul, ambigu, missed, inconclusive et expiration sont couverts sans mutation World par le scénario headless et `pebsmoke`.

## CIV-05 — Tâche partagée et coopération matérielle

Le mode `scripts/verify-pebblelab-live.sh --cooperation` démarre dans un monde
jetable neuf avec la seed `46` et les gates sociale, physique, ressources
naturelles, construction et coopération explicitement actives. La gate
`PEBBLELAB_APP_AGENTS_COOPERATION=1` reste désactivée par défaut. La preuve
attend une offre physique exacte, son acceptation volontaire par un helper
distinct du builder, trois récoltes de pierre et une livraison du helper, puis
les six récoltes de bois, le financement et les neuf placements du builder.
Elle vérifie enfin la construction complète, le nouveau home, la conservation
de neuf matériaux, l'absence d'erreur runtime et le cleanup vérifié.

Les captures `cooperation-before.png`, `cooperation-offer.png` et
`cooperation-complete.png` documentent les trois états observables, sans
assertion automatique sur les pixels. La trace et les événements causaux font
autorité pour l'acceptation, les contributions et les transitions matérielles.
Chaque exécution doit employer un monde jetable neuf et conserver son dossier
temporaire pour inspection ; aucun monde personnel ne doit être utilisé.

## CIV-06 — Checkpoint restart-safe et replay causal

Le mode `scripts/verify-pebblelab-live.sh --persistence` active explicitement
`PEBBLELAB_APP_AGENTS_PERSISTENCE=1` dans un home jetable. Il sauvegarde un
checkpoint versionné à une frontière stable avant toute mutation World
réussie, termine le premier processus, recharge le même monde dans un second
processus, restaure la session et ses trois probes, puis poursuit la chaîne
matérielle CIV-05. Un contrôle ininterrompu doit produire les mêmes décisions
et le même digest durable. Le journal typé est rejoué par le kernel pur, sans
World ni nouvelle publication physique.

Les sidecars bornés vivent sous `Application Support/Pebble/PebbleLabAgents`
avec binding strict au monde, à la dimension, à la seed, à l'anchor et aux
cellules pertinentes. Les checkpoints pris après une récolte ou un placement
réussi sont explicitement marqués non restart-safe et leur chargement live est
refusé. CIV-06 n'ajoute ni snapshot complet du World, ni autosave, ni migration
générale de schéma ; la gate reste désactivée par défaut.

## CIV-07 — Registre de population et migration locale bornée

Le mode `scripts/verify-pebblelab-live.sh --population` active explicitement
`PEBBLELAB_APP_AGENTS_POPULATION=1` et la persistence CIV-06 dans un monde
jetable seed `46`. `/lab population on` enregistre `agent_0`, `agent_1` et
`agent_2` comme fondateurs de `settlement-main` sans modifier leur cognition,
leur position ou leur home. `/lab migration admit` utilise un adapter World
read-only pour sélectionner une entrée, une réception et une route sûres,
puis admet atomiquement `agent_3` et son quatrième probe.

La preuve exécute exactement deux mouvements physiques, sauvegarde un
checkpoint population v2 restart-safe, termine le processus, restaure quatre
agents et quatre probes, puis poursuit la même route jusqu'à l'arrivée au tick
7. Un contrôle ininterrompu doit produire les mêmes mouvements, digests
durable, population et causal. Le cleanup retire exactement quatre probes. La
gate reste désactivée par défaut et la population active est limitée à huit
membres ; aucune naissance, mort, reproduction, famille, émigration,
population hors écran ou mutation World n'est ouverte.

## CIV-08 — Métriques settlement et vue multi-scale bornée

Le mode `scripts/verify-pebblelab-live.sh --multiscale` active explicitement
`PEBBLELAB_APP_AGENTS_MULTISCALE=1`, ainsi que population et persistence, dans
un monde jetable seed `46`. `/lab settlement on` construit une baseline au tick
courant ; le runtime publie ensuite un frame administratif de
`settlement-main` aux ticks `4`, `8` et `12`. `/lab scale status` rappelle que
les agents restent exécutés à chaque tick, que la coarse execution est
désactivée et qu'aucun agent n'est hors écran.

La preuve sauvegarde `settlement-frame-1` en checkpoint v3 au tick 4, termine
réellement le processus, restaure quatre agents, quatre probes, la route du
migrant, le frame 1 et l'horloge macro, puis poursuit jusqu'au troisième pulse.
Un contrôle ininterrompu produit les mêmes frames, digests et décisions. Un
contrôle avec les métriques désactivées produit une trace micro byte-identical,
ce qui prouve l'absence de rétroaction cognitive ou matérielle.

Les fixtures headless contrôlées font passer le vrai classificateur par les
cinq conditions : `incomplete`, `strained`, `transitioning`, `active` et
`stable`. La preuve `active` repose sur un mouvement de résident réellement
accepté dans une fenêtre complète, sans urgence, migration, transition de
population ni activité matérielle. Le monde live conserve au contraire les
besoins et goals historiques des fondateurs ; ses frames aux ticks `4`, `8` et
`12` restent donc honnêtement `strained` lorsque `seekSafety` ou `rest` sont
engagés. Le script l'affirme explicitement. Cette vérité administrative
n'altère ni migration, ni population, ni conservation, et ne doit pas être
masquée en requalifiant les états micro ou en exigeant du live une séquence
artificielle des cinq conditions.

CIV-08 est terminé et validé localement. Il ne constitue pas une optimisation
de grande population : l'historique est borné à seize frames, la population
reste limitée à huit agents actifs et chaque agent conserve sa cognition
complète. Le checkpoint/replay v3 n'ouvre ni autosave général, ni snapshot du
World, ni framework général de migration.

## CIV-09 — Écologie locale et pression de subsistance

Le mode `scripts/verify-pebblelab-live.sh --ecology` active explicitement
`PEBBLELAB_APP_AGENTS_ECOLOGY=1` avec population, settlement metrics,
persistence, survie et économie dans un monde jetable seed `46`. Après
l'arrivée physique d'`agent_3`, `/lab ecology on` inspecte en lecture seule un
maximum de seize candidats et enregistre deux patches locaux adossés à de vrais
blocs habitat. Chaque patch possède une unité de rendement initial, un ID
stable, une capacité et une horloge de régénération ; le rayon perceptif agent
reste limité à huit blocs.

La cueillette produit `forage_food`, suit la navigation bornée existante et
résout les concurrents par patch, `AgentID`, puis operation ID. Un succès retire
exactement une unité de rendement et ajoute un `foodRaw` réellement porté,
ensuite consommé par le chemin de survie historique. La fin de tick valide les
habitats, régénère dans l'ordre lexical au seul rythme de l'horloge simulée et
publie la pression administrative `abundant`, `adequate`, `scarce`, `critical`
ou `recovering`. Cette pression n'est jamais une entrée de cognition.

La preuve sauvegarde `ecology-shortage` au tick 21 avec quatre résidents, un
patch épuisé, un rendement disponible inférieur aux trois résidents affamés et
une pression `scarce`, puis restaure le même World, les quatre
probes, les yields, les besoins, les horloges et le ledger depuis un checkpoint
v4. La continuation et le contrôle ininterrompu convergent sur les mêmes
traces, digests, régénérations, gagnants, consommations et dégâts de famine,
avec conservation écologique et matérielle exactes et aucune mutation World.

CIV-09 est terminé et validé localement. Cette V1 n'est pas une botanique
réaliste et n'ouvre ni agriculture, saisons, animaux, chasse, pêche, eau,
cuisson ou pourrissement.

## CIV-10 — Mortalité et sortie de population bornée

Le mode `scripts/verify-pebblelab-live.sh --mortality` active explicitement
`PEBBLELAB_APP_AGENTS_MORTALITY=1` avec survie, population, persistence,
settlement metrics et écologie dans un monde jetable seed `46`. La gate reste
désactivée par défaut et exige une population active cohérente. `/lab mortality
status` expose les death records et le compte de ressources terminales bornés ;
`/lab exits status` expose les transitions de population correspondantes.

La preuve forme quatre résidents, sauvegarde au tick 26 un checkpoint v5 où
`agent_2` possède exactement 10 points de santé, puis redémarre et exécute un
seul tick létal. Au tick 27, la famine produit exactement une mort, aucune
cognition ni action terminale, une population `4 → 3`, le retrait vérifié du
probe et un checkpoint post-mortem sans résurrection. Un troisième processus
réadmet physiquement `agent_4`, qui atteint la réception au tick 34 ; la
population et les probes reviennent à quatre tandis que l'ordinal monotone
passe à cinq. La continuation restart et le contrôle ininterrompu ont des
traces, octets et digests identiques.

Le contrat causal conserve l'ordre `starvation_damage →
lethalHealthDepletion → mortalityResourcesRetired →
mortalityCommitmentsResolved → populationMemberExited →
agentDeathFinalized`. Le dernier événement confirme que toutes les
sous-transitions de la mort ont été validées et appliquées. Le death record v5
porte en outre un snapshot terminal borné des compteurs d'activité : au tick
létal, les compteurs cognitifs et matériels restent figés tandis que
`ticksAlive` avance exactement une fois. Les fixtures headless traversent la
vraie frontière de mort avec des références actives dans les domaines
ressources, social, physique, coopération, construction et écologie, puis
vérifient leur nettoyage sans effacer les historiques.

Le harnais jetable fournit simultanément `PEBBLE_CMD` et
`PEBBLELAB_DISPOSABLE_WORLD_PROOF=1`. Cette seconde gate est indispensable
pour empêcher l'ouverture automatique de la pause lors d'une perte de focus
du processus de preuve ; `PEBBLE_CMD` seul conserve le comportement normal de
pause du jeu.

CIV-10 est terminé et validé localement. Les ressources portées par un mort
restent comptabilisées dans `unrecoveredAtDeath` ; aucun cadavre ni objet n'est
créé dans le World. Cette V1 n'ouvre ni vieillissement, maladie, combat,
funérailles, héritage, résurrection, naissance, reproduction ou famille. La
prochaine étape canonique est
`CIV-11 — Age, Maturity and Bounded Reproduction V1`.

## CIV-11 — Âge, maturité et reproduction locale bornée

Le mode `scripts/verify-pebblelab-live.sh --reproduction` active explicitement
`PEBBLELAB_APP_AGENTS_LIFECYCLE=1` avec population, persistence, settlement
metrics, écologie et survie dans un monde jetable seed `46`. La gate reste
désactivée par défaut. `/lab lifecycle on` enregistre les quatre résidents
actifs avec un âge démographique mature dérivé de l'horloge simulée, distinct
de `ticksAlive`; `/lab reproduction on` autorise ensuite au plus un plan
reproductif actif et `/lab births status` expose l'historique borné.

Après l'arrivée physique d'`agent_3`, la preuve initialise l'écologie en lecture
seule. Le pulse du tick `8` établit une pression `abundant`; l'évaluation
déterministe du tick `10` sélectionne `agent_0` et `agent_1` comme deux
progéniteurs historiques et sauvegarde un checkpoint v6 mid-plan. Après
restart, l'adapter inspecte un maximum borné de sites autour de la réception,
ne mute aucun bloc et valide la position `(18,67,-23)`. Au tick `12`, la
transaction crée `birth-00000001` et `agent_4`, fait passer population et probes
de quatre à cinq, avance `nextPopulationOrdinal` à cinq et laisse le newborn à
âge zéro, inventaire vide et zéro perception, action ou mouvement sur son tick
de naissance.

Un second checkpoint/restart v6 restaure exactement les cinq agents et
l'historique causal. `agent_4` devient `juvenile` au tick `14`, puis `mature` au
tick `20`. La continuation avec deux restarts et le contrôle ininterrompu
produisent les mêmes traces normalisées, octets durables et digests lifecycle,
population, ecology, settlement et causal. Le contexte alimentaire conditionne
la naissance mais ne crée, ne détruit et ne consomme aucun `foodRaw`.

CIV-11 est terminé et validé localement. Les deux progéniteurs ne constituent
ni couple, ni foyer, ni famille et aucune règle de sexe, grossesse, soin
parental, génétique ou héritage n'est ouverte. La prochaine étape canonique est
`CIV-12 — Kinship, Households and Dependent Care V1`.

## CIV-12A — Graphe de parenté durable V1

Le mode `scripts/verify-pebblelab-live.sh --kinship` réutilise la naissance
réelle CIV-11 avec la gate supplémentaire
`PEBBLELAB_APP_AGENTS_KINSHIP=1`. Après `/lab lifecycle on`, la commande
explicite `/lab kinship on` migre exactement les allocations v6 prouvables en
personnes historiques racines, sans inventer de parents. La gate reste
désactivée par défaut et exige agents, persistence, population et lifecycle.

La naissance d'`agent_4` ajoute dans la même transaction candidate un record
immuable `agent_4 <- agent_0,agent_1`. Le nouvel événement
`kinshipParentageRecorded` est causé par `populationMemberBorn`, puis cause
`birthFinalized`. Le checkpoint v7 encode personnes et parentages dans un ordre
canonique ; les enfants par parent, fratries et ancêtres restent des index
dérivés non encodés. Un second processus restaure exactement les cinq personnes,
le parentage et les digests. Le restore rapproche les événements causaux encore
retenus avec leurs records complets ; une référence absente n'est recevable que
si sa séquence est prouvée antérieure à la fenêtre retenue. Les traces exigent
zéro erreur runtime pour les runs positifs et un cleanup complet des probes. La
preuve World reste exacte sans compteur d'attribution inventé : `PebbleAgents`
n'accède pas au World et aucun appel ou événement de mutation de bloc/World
n'est observé ; le kinship ne crée aucune ressource ni représentation graphique.

Le workflow couvre aussi une défaillance tardive réservée au harnais jetable.
Après validation complète de la naissance et du parentage dans le candidat, la
création/réconciliation physique du probe newborn échoue de manière contrôlée.
Les octets durables, le tick, l'ordinal, les membres population/lifecycle, les
personnes et parentages kinship, le ledger causal, le recorder, la carte des
probes et les index d'entités World sont alors identiques à l'état antérieur ;
le newborn est absent et le cleanup retire les quatre probes existants. Un run
positif indépendant exécuté ensuite restaure v7, publie la naissance et retire
ses cinq probes. En gate-off, la trace de naissance CIV-11 et le checkpoint v6
restent byte-identiques au baseline antérieur à CIV-12A.

CIV-12A est terminé et validé localement. Il n'introduit ni foyer, care,
cohabitation, mariage, adoption, génétique, héritage, propriété, maison
politique ou changement cognitif des newborns. La prochaine étape canonique
est `CIV-12B — Households and Membership V1`.

## CIV-12B — Foyers et périodes d'appartenance V1

Le mode `scripts/verify-pebblelab-live.sh --households` réutilise le workflow
naissance/kinship avec la gate supplémentaire
`PEBBLELAB_APP_AGENTS_HOUSEHOLDS=1`. La commande explicite
`/lab household on` migre le checkpoint v7 en v8 en groupant les résidents par
`homePosition`; `/lab household status` expose seulement les foyers,
appartenances, ancres et digest de la session. Les gates agents, persistence,
population, lifecycle et kinship sont obligatoires. Un v8 est refusé si une de
ces gates manque, tandis qu'un v7 chargé avec toutes les gates reste v7 tant
que l'activation explicite n'a pas eu lieu.

Dans le monde jetable seed `46`, les quatre résidents initiaux reçoivent une
appartenance, puis la vraie naissance d'`agent_4` crée un foyer singleton car
ses parents ont des homes distincts. La chaîne causale est
`populationMemberBorn → kinshipParentageRecorded → householdCreated →
householdMembershipStarted → birthFinalized`. Un second processus recharge le
checkpoint v8 et retrouve exactement foyers, périodes, homes et digests ; le
contrôle ininterrompu produit les mêmes octets durables. Le harnais tardif
compare aussi le snapshot household complet avant/après l'échec physique du
probe newborn. Les runs positifs terminent avec `runtimeErrors=0` et retirent
les cinq probes. `PebbleAgents` n'accède pas au World et aucune trace de
mutation de bloc/World n'est observée ; aucun compteur d'attribution artificiel
n'est revendiqué.

CIV-12B est terminé et validé localement. Le household ne possède ni ressource,
stock, bloc, terrain ou bâtiment et ne signifie ni famille biologique, mariage,
care ou héritage. La prochaine étape canonique est
`CIV-12C — Dependent Care and Lifecycle Integration V1`.

## Arrêt propre et inspection

Utiliser `/lab demo stop`, `/lab stop` ou `/lab clear`. Les probes transitoires sont retirées, le follow est désactivé et un résumé de session est écrit lorsque les traces sont actives. `/lab status` confirme ensuite que la session est inactive. Les probes ont `shouldSaveToChunk == false` et `persistent == false` ; aucun agent n’est restauré lors d’un lancement ultérieur.

## Garde-fous et limitations V0

- exactement trois agents lorsque la gate population est désactivée ; au plus
  huit membres actifs sous la gate CIV-07 ;
- mouvement cardinal single-step ;
- perception World en rayon 1 ;
- mémoire bornée ; la navigation historique reste dans son rayon contractuel
  et une migration CIV-07 est limitée à une distance locale de 24 ;
- aucune destination partagée et aucun dangerous drop exécuté ;
- navigation de ressource bornée au rayon 8, route cardinale et un pas au plus par tick ;
- hors gate naturelle explicite, seule la fixture transactionnelle peut être mutée puis restaurée ; la construction reste interdite ;
- aucune langue libre ni retransmission ; la coopération est limitée à la
  tâche de livraison matérielle CIV-05 explicitement gated ;
- aucune persistance active par défaut ; la persistence CIV-06 reste bornée,
  explicitement gated et limitée aux frontières restart-safe documentées ;
- aucun agent dynamique hors admission migratoire CIV-07 ou naissance locale
  explicitement gated de CIV-11 ; la seule suppression active est la mort par
  famine explicitement gated de CIV-10, sans simulation hors écran ;
- aucun tick agent sauté, aucune coarse execution et aucun agrégat macro
  utilisé comme entrée cognitive ; la gate CIV-08 est désactivée par défaut ;
- aucun patch alimentaire global : CIV-09 reste local, borné, en lecture World
  seule et désactivé par défaut ; aucune agriculture, saison ou faune ;
- aucune entité de cadavre : CIV-10 conserve des records et ressources
  terminales bornés, sans mutation World, vieillissement ou maladie ;
- CIV-11 conserve uniquement âge, stages et filiation historique bornée :
  aucun sexe, grossesse, couple, foyer, soin parental, génétique ou héritage ;
- CIV-12A conserve uniquement personnes historiques et parentages canoniques :
  aucun foyer, care, propriété, héritage, dynastie ou représentation World ;
- aucun contrôleur autonome du joueur.

Les comportements cognitifs supplémentaires, la planification longue, le
replay complet du World et l'autosave restent hors de cette verticale.

## Transactional interaction G1

La primitive G1 est une fixture manuelle, non autonome, protégée par `PEBBLELAB_APP_AGENTS_INTERACT=1` en plus de la gate agents. Sur une session active, en pause et avec le mouvement désactivé, `/lab interaction setup` place un unique bloc `amethyst_block` adjacent à l’agent focalisé dans une sandbox de rayon horizontal 8 autour de l’anchor. `/lab interaction harvest` retire ce bloc, crédite exactement une `sandboxResource` dans l’inventaire partagé borné et écrit la mémoire `resource_harvested`. `/lab interaction status` expose le ledger, l’inventaire, l’outcome et le rollback.

Le bloc original est conservé dans un ledger applicatif puis restauré par stop, clear, reset, redémarrage, changement de World ou terminaison. Une erreur après mutation déclenche un rollback vérifié avant toute publication de la copie de session. G1 ne sélectionne aucune cible cognitive, ne crée aucun goal de collecte et ne rend pas la récolte autonome ; ces branchements sont réservés à G2.

## G2 — Autonomous adjacent sandbox harvest

Le setup reste manuel avec `/lab interaction setup`. Une fois la session en mouvement off, `/lab interaction auto on` autorise explicitement le seul acteur propriétaire du ledger à percevoir la fixture adjacente, sélectionner `collectResource`, produire `harvest_block` et réutiliser la transaction G1 lors du prochain `/lab step`. `/lab interaction auto off` coupe ce branchement ; le mode auto est toujours désactivé au démarrage. Le status et l’overlay exposent la ressource perçue, la cible, l’action, l’outcome, l’inventaire et la mémoire.

G2 reste strictement adjacent-only : aucune navigation, aucun scan distant et aucun bloc naturel — y compris un autre bloc d’améthyste — ne sont collectables. La fixture est unique, issue exclusivement du ledger sandbox et restaurée au cleanup. Un échec bloquant désactive l’auto pour éviter une boucle. Les outils, drops, temps de minage, autres ressources et la sélection autonome d’une cible distante restent hors périmètre.

## H1 — Distant resource survey and target lock

`/lab interaction setup distant <2...8>` place la même fixture `amethyst_block` du ledger, à une distance cardinale exacte et après validation d’une route sûre existante. Avec l’auto explicitement activé, la session live utilise un rayon borné à 8, sélectionne une `activeResourceTarget` déterministe et la conserve tant qu’elle reste visible et compatible avec l’inventaire. La perception reste ledger-only : aucun bloc naturel n’est scanné.

Une cible distante produit `collectResource` puis l’action sèche `approach_resource`. H1 ne crée ni route, ni waypoint, ni pathfinding et ne déplace pas l’agent ; elle ne déclenche aucune interaction et ne crédite ni inventaire ni mémoire de récolte. La récolte manuelle distante reste refusée. Le setup adjacent historique demeure inchangé et continue à produire le chemin G2 `harvest_block`. Le déplacement borné vers la cible est réservé à H2.

## H2 — Navigate-to-harvest

Le lanceur live crée automatiquement `PebbleLab-Disposable-H2-12345` dans un home temporaire isolé, configure `agent_2`, une fixture distante à quatre blocs, l'auto-interaction et le mouvement, puis exécute exactement quatre `/lab step`. Le setup observe le terrain réel, demande au planner partagé une route sûre, puis modifie uniquement le bloc-fixture final ; le corridor, son sol et les cellules pieds/tête restent en lecture seule. La trace vérifie neuf blocs intermédiaires avant et pendant la navigation, après la récolte et après le cleanup. La session réserve la cible avec un tie-break stable, calcule une route cardinale dans un relevé World borné aux chunks déjà prêts, et remet uniquement le prochain pas à `AgentMovementCoordinator`. Les trois premiers ticks appliquent chacun au plus un pas par le movement stack existant. À distance Manhattan 1, le quatrième tick produit `harvest_block` et réutilise sans détour la transaction G1/G2. Le cleanup restaure et vérifie uniquement le bloc-fixture.

`/lab interaction status`, l'overlay full et chaque trace de tick exposent le propriétaire de réservation, le statut de navigation, la longueur et l'index de route, les pas restants, le prochain pas, le compteur de replan, la dernière invalidation/erreur, la distance actuelle et les derniers outcomes. La preuve attendue montre `inventory 0 -> 1`, une seule mémoire `resource_harvested`, aucune erreur runtime, puis la restauration de la fixture lors de la terminaison.

La route est limitée au rayon 8, à 256 nœuds visités, à 16 pas et à trois replans espacés d'au moins un tick. Une cellule ou un chunk indisponible, un pas vertical hors `-1...1`, un dangerous drop, la perte de réservation ou la disparition de la cible invalide explicitement la route. Aucun chargement de chunk, pathfinding mondial, ressource naturelle ou persistance de route n'est ouvert.

## Phase I — Closed Resource Economy Sandbox V1

`/lab economy setup` prépare au maximum trois fixtures réversibles pour `foodRaw`, `wood` et `stone`. Les blocs visuels sont respectivement `hay_block`, `oak_log` et `cobblestone`, déjà enregistrés ; ces blocs n'acquièrent aucune sémantique gameplay hors du ledger sandbox. Le setup inspecte le terrain réel, essaie des cibles dans un ordre stable, valide chaque route avec `AgentBoundedRoutePlanner`, puis mute uniquement les trois blocs-fixtures finaux. Les corridors, supports, pieds, têtes, obstacles et différences de hauteur restent en lecture seule.

Après `/lab economy auto on` et `/lab movement on`, l'agent focalisé collecte les fixtures dans l'ordre déterministe `foodRaw`, `wood`, `stone`. Le quota V1 vaut 2. Une fois deux unités portées, la session passe au goal `deliverResources`, planifie une route `.exact` vers `homePosition`, émet au plus un `return_home` par tick, puis `deliver_resource`. La transaction pure de session vide atomiquement le seul `AgentResourceInventory`, crédite `AgentCampStock`, écrit une mémoire `resource_delivered` et expose l'invariant `harvested = carried + campStock` par ressource.

Le scénario permanent utilise le monde `PebbleLab-Disposable-I-12345`, la seed `12345`, trois fixtures et dix ticks cognitifs. La preuve attendue montre `foodRaw 0→1`, `wood 0→1`, le retour au home, l'inventaire `2→0`, le stock `0→2`, la conservation exacte, zéro corridor modifié et trois blocs restaurés au cleanup. `/lab economy clear`, stop, reset, remplacement de World et terminaison restaurent et vérifient chaque bloc-fixture sans annuler les quantités économiques déjà produites.

Cette phase reste entièrement `sandboxFixture` : aucun bloc naturel n'est scanné ou collecté, aucun drop physique, coffre, registre, save/load, consommation ou construction n'est ouvert.

## Phase J — Autonomous Survival Sandbox V1

`/lab survival on` active explicitement, dans la session partagée, une politique bornée de faim, fatigue, famine et repos. Le mode reste désactivé par défaut et ne change ni les gates, ni l'économie, ni le mouvement. `/lab survival off` libère les engagements hunger/rest sans toucher à l'inventaire, au stock ou au World ; `/lab survival status` expose les seuils, les compteurs, le dernier outcome de consommation et la conservation étendue.

Une faim engagée cible exclusivement les fixtures `foodRaw` et réutilise le target lock, la réservation, la route H2, le movement stack et la récolte transactionnelle existants. Lorsque l'unité est portée, `consume_food` retire atomiquement un `foodRaw`, réduit la faim, écrit une seule mémoire `food_consumed` et étend l'invariant à `harvested = carried + campStock + consumed`. Sans nourriture, la période de grâce et les dégâts de famine sont déterministes ; la mort et le respawn restent hors scope.

Une fatigue engagée conserve le goal `rest` jusqu'au seuil de récupération. Loin du home, la purpose `homeRest` réutilise le planner exact et `return_home`, à un pas maximum par tick. Au home, l'action `rest` réduit la fatigue avant la reprise des activités normales. Le mode live par défaut utilise `PebbleLab-Disposable-J-12345`, conserve les trois blocs-fixtures comme seules mutations World, vérifie zéro modification de corridor et restaure les trois fixtures au cleanup. La preuve négative de famine sans nourriture est structurée dans `pebsmoke`, car elle ne nécessite aucune mutation World ni validation pixel.

## J→K — Natural Wood and Stone Harvest V1

Le mode naturel reste désactivé par défaut et exige `PEBBLELAB_APP_AGENTS_NATURAL=1`, puis `/lab natural on`. Il n'active ni le mouvement, ni l'économie, ni la survie. Le mapping Pebble est volontairement fermé aux fingerprints metadata `0` déjà enregistrés et générés : `oak_log#1520` et `birch_log#2032` donnent `wood`, `stone#48` donne `stone`. Aucun bloc ne donne `foodRaw`; la nourriture de survie reste une fixture.

Le scan read-only couvre un rayon horizontal maximal de 8 et la bande verticale `agentY-2...agentY+4`, au plus 1 008 positions cibles et 384 lectures d'approche, sans charger de chunk. Cette bande couvre les différences de niveau simples du movement stack et les troncs accessibles sans ouvrir un scan vertical général. Il émet au plus 32 candidats puis 8 observations dans un ordre stable. La session conserve la source `naturalWorld`, le fingerprint, le target lock et la réservation. Le planner H2 et le movement stack restent les seuls chemins de navigation.

La récolte naturelle relit le fingerprint exact, prévalide la copie de session, remplace uniquement la cible par air, vérifie la mutation puis publie le crédit. Une publication refusée restaure immédiatement et vérifie le bloc exact; après succès, le bloc reste retiré et le cleanup ne le recrée pas. Les fixtures conservent leur ledger réversible séparé. L'invariant économique reste `harvested = carried + campStock + consumed`.

La preuve permanente `scripts/verify-pebblelab-live.sh --natural` utilise le monde jetable `PebbleLab-Disposable-Natural-46`, la seed `46`, l'anchor joueur `(19,68,-21)`, zéro fixture et `agent_2` au home `(21,68,-21)`. Elle observe un `oak_log#1520` en `(24,68,-22)`, parcourt trois pas jusqu'à `(24,68,-21)`, récolte ensuite la pierre exposée adjacente `stone#48` en `(24,68,-20)`, revient au home en trois pas et livre `wood=1, stone=1`. La trace vérifie les deux blocs devenus air, `fixtures=0`, `naturalRestoredAfterSuccess=0`, la conservation `2=0+2+0`, zéro corridor modifié et zéro erreur runtime. La capture reste une preuve visuelle complémentaire; les fingerprints, la déduplication et le rollback injecté sont couverts par `pebsmoke`.

## K — Fixed Shelter Construction V1

Le mode `scripts/verify-pebblelab-live.sh --build` utilise exclusivement le monde jetable `PebbleLab-Disposable-Build-46`, la seed `46` et l'anchor `(20,66,-24)`. Après activation explicite des gates naturelle et construction, il sélectionne en lecture seule le site d'origine `(22,66,-25)`, collecte six `wood` et trois `stone` naturels, les livre au stock existant puis finance atomiquement le blueprint fixe `fixedLeanToV1`. Le blueprint place, dans l'ordre, trois pierres de mur bas, trois troncs de mur haut et trois troncs de toit; l'entrée `(1,0,0)` et la cellule de repos `(1,0,1)` restent vides.

La preuve interrompt l'auto-construction après les cellules `0...2`, exécute quatre ticks sans pose, reprend exactement à l'index `3`, achève `9/9`, puis active la survie pour vérifier le nouveau home `(23,66,-24)` et le repos sous le toit. Les trois captures `fixed-shelter-before.png`, `fixed-shelter-partial.png` et `fixed-shelter-complete.png` complètent la trace structurée; elles ne remplacent pas les assertions de fingerprints, d'ordre et de rollback de `pebsmoke`.

Enfin, `/lab build clear` restaure et vérifie les neuf fingerprints originaux en ordre inverse, rend `wood=6, stone=3` au stock, supprime le projet et restaure l'ancien home. Les ressources naturelles récoltées restent détruites. La construction est une sandbox temporaire: elle n'ouvre ni placement libre, ni crafting, ni persistance.
