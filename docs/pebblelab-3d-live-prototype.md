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
Sous la gate matérielle CIV-16, une preuve jetable relie aussi les probes à de
vrais `ItemStack` et à un container Pebble réel sans publier de second stock
civilisationnel.
Sous les gates matérielle et naturelle, la preuve CIV-17 fait casser un vrai
log et une vraie stone par les règles Pebble, acquiert uniquement leurs drops
causaux dans la custody réelle et publie ensuite la causalité et la pratique.
Sous les gates matérielle et construction, la preuve CIV-18 consomme trois
vraies stones et six vrais oak logs en posant les neuf cellules ordonnées par
`executeBlockPlacement`, puis restaure sa fixture jetable.
Sous les gates de convergence CIV-19, la preuve embodiment fait choisir chaque
pas live par PebbleCore `findPath`, l'exécute par `Entity.move`, puis publie
seulement la position physique vérifiée dans la session civilisationnelle.
Sous la gate CIV-21, un sensor Pebble read-only observe l'écologie locale réelle
du World, tandis qu'un calendrier civil séparé dérive uniquement du tick de
session. Ce chemin ne mute ni World, ni matière, ni écologie coarse CIV-09.
Sous la gate CIV-22, un plan agricole borné sélectionne un site observé, puis
compose navigation, labourage, plantation, croissance Farming Core, récolte,
custody et dépôt dans un vrai container sans créer de stock abstrait.

## Prérequis et lancement

Le cycle de développement et les validations permanentes sont décrits dans [`docs/pebblelab/DEVELOPMENT_WORKFLOW.md`](pebblelab/DEVELOPMENT_WORKFLOW.md). Pour une session Phase J reproductible qui n'expose aucun monde personnel, commencer par `scripts/verify-pebblelab-live.sh --dry-run`, puis lancer explicitement `scripts/verify-pebblelab-live.sh`. Les options `--economy`, `--h2`, `--natural`, `--social`, `--physical`, `--cooperation`, `--persistence`, `--population`, `--multiscale`, `--ecology`, `--mortality`, `--reproduction`, `--kinship`, `--households`, `--care`, `--skills`, `--material`, `--harvest` et `--construction` conservent respectivement les preuves Phase I, H2, récolte naturelle J→K, information sociale CIV-03, canal physique CIV-04, tâche partagée CIV-05, restart/replay CIV-06, migration physique CIV-07, métriques settlement CIV-08, écologie alimentaire CIV-09, sortie de population CIV-10, âge/maturité/reproduction bornée CIV-11, parenté durable CIV-12A, appartenance household CIV-12B, dependent care final de CIV-12, compétences pratiques CIV-13, custody matérielle CIV-16, convergence harvest CIV-17 et convergence construction CIV-18. Ce lanceur réutilise les hooks existants d'autoload, de monde neuf, de commandes et de capture, impose un monde jetable préfixé `PebbleLab-Disposable-` avec seed fixe et conserve monde, traces et captures sous un home temporaire isolé. La vérification visuelle de la capture reste manuelle.

Les options supplémentaires `--embodiment`, `--teaching`,
`--ecological-observation` et `--agriculture` portent respectivement les
preuves CIV-19, CIV-20, CIV-21 et CIV-22 décrites ci-dessous.

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
/lab gateway proof              /lab material proof    /lab harvest proof
/lab construction proof         /lab embodiment proof
/lab economy <setup|auto on|auto off|status|clear>
/lab survival <on|off|status>
/lab natural <on|off|status|scan>
/lab ecology <on|off|status|scan|clear>
/lab forage status
/lab ecological-observation <on|status|scan|proof>
/lab mortality <on|off|status|clear>
/lab exits status
/lab lifecycle <on|status|clear>
/lab reproduction <on|off|status>
/lab births status
/lab kinship <on|status>
/lab household <on|status>
/lab skills <on|status>
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

## CIV-16 — Custody matérielle réelle V1

Le mode `scripts/verify-pebblelab-live.sh --material` active explicitement
`PEBBLELAB_APP_AGENTS_MATERIAL=1` dans un monde jetable seed `46`. Il exécute
deux fois `/lab material proof` sur une session en pause : identité normalisée
par nom d’item, transfert agent ↔ container réel, split/merge, consommation,
replay idempotent, détection stale et rollback tardif. La même preuve connecte
les callbacks place/tool de CIV-15 à la custody réelle, puis restaure le World,
retire les drops de preuve et laisse session et `AgentCampStock` inchangés.

La fixture crédite des piles uniquement dans la custody éphémère autorisée du
test et les efface avant retour. Elle ne définit ni ownership, ni claim, ni
checkpoint général de l’inventaire live ; ces frontières restent respectivement
réservées à CIV-26 et à la convergence de persistence future.

## CIV-17 — Convergence harvest et ressources V1

Le mode `scripts/verify-pebblelab-live.sh --harvest` active explicitement les
gates naturelle, matérielle, persistence, population, lifecycle et skills dans
`PebbleLab-Disposable-Harvest-46`. La commande de harnais `/lab harvest proof`
reste réservée au monde jetable, à une session en pause et au mouvement coupé.
Elle seed explicitement un axe et une pioche réels dans la custody du probe,
puis rejoue deux fois le même scénario déterministe.

NaturalResource conserve son observation bornée, son target lock, son
fingerprint et son identité de transaction. Son exécution live passe désormais
par la gateway CIV-15 : `executeBlockBreak` applique les règles Pebble de
harvest et d'usure, rapporte les identifiants exacts des `ItemEntity` qu'il a
créés, puis le bridge CIV-16 déplace ces stacks dans `carriedItems` avec les
règles d'inventaire Core. La session civilisationnelle n'est publiée qu'après
vérification de la mutation, des drops, de la custody et de l'outil. Cette
publication ajoute un succès causal et une unité de pratique `foraging`, mais
aucun `wood`/`stone` abstrait ni `AgentCampStock`.

La preuve casse un `oak_log` en `oak_log x1`, puis une `stone` en
`cobblestone x1`; chaque outil reçoit exactement un point de damage. Un
`ItemEntity` de dirt préexistant et adjacent reste inchangé. Les présentations
dupliquée et stale, la cible hors de portée, l'absence d'outil productif, la
custody pleine et l'échec tardif d'acquisition produisent zéro succès causal et
restaurent exactement bloc, drops, custody, outil et effets. Les deux commandes
live publient le même digest, terminent avec `runtimeErrors=0` et retirent les
trois probes. Le mapping de planification `wood`/`stone` reste une abstraction
coarse compatible ; il ne calcule jamais les drops Pebble.

## CIV-18 — Convergence construction et placement V1

Le mode `scripts/verify-pebblelab-live.sh --construction` active les gates
construction, matériau, persistence, population, lifecycle et skills dans
`PebbleLab-Disposable-Construction-46`. `/lab construction proof` installe un
projet et de vrais `ItemStack` uniquement dans une fixture bornée, rejoue deux
fois le même scénario, puis restaure World, custody, position du probe et
entités. L'option historique `--build` est un alias de cette preuve convergée.

Le blueprint fixe conserve son ordre, ses targets, work positions,
fingerprints originaux, ledger et validation finale. Chaque cellule résout le
premier slot réel compatible dans un ordre stable, puis passe par la gateway
CIV-15 et `executeBlockPlacement`. PebbleCore décide replaceability, collision,
orientation, support, résultat physique et débit. Le ledger et la session ne
sont publiés qu'après vérification ; chaque succès produit exactement un event
`constructionPlacement` et une unité de pratique `construction`. Aucun
`AgentCampStock`, inventaire abstrait ou escrow coarse ne bouge sur ce chemin.

La preuve couvre matériau absent ou incompatible, mauvais ordre, cible stale,
non-replaceable ou occupée, duplicate, cellule antérieure altérée, support
final retiré et échec de publication sur la dernière cellule. Les failures
tardives restaurent exactement bloc, custody et session sans effet ni skill
fantôme. Le chemin headless conserve l'escrow abstrait historique ; `clear` et
`cleanup` restent des restaurations lifecycle bornées, pas un gameplay de
démolition.

## CIV-19 — Navigation et embodiment boundary V1

Le mode `scripts/verify-pebblelab-live.sh --embodiment` active explicitement
les gates nécessaires dans `PebbleLab-Disposable-Embodiment-46`. La commande
`/lab embodiment proof` est limitée au monde jetable, à une session en pause
et au mouvement coupé. Elle rejoue deux fois des fixtures bornées couvrant
route simple, obstacle statique, changement dynamique, marche verticale,
terrain non supporté, conflit multi-agent, publication tardive, identité et
lifecycle. Elle réutilise aussi les preuves reach harvest et construction.

La frontière live est stricte : `PebbleAgents` fournit raisons, destination et
waypoints ; `Pebble` résout l'embodiment et orchestre la transaction ;
PebbleCore `findPath`, `Entity.move`, collision et `World` choisissent et
valident chaque pas. La position physique vérifiée gagne sur la projection de
session. Une dérive bornée est publiée comme réconciliation explicite ; une
dérive excessive, un body manquant/dupliqué, un ancien World, une destination
bloquée ou un conflit sont refusés sans téléportation.

Le scénario admet ensuite un migrant et exécute quatre ticks normaux. La trace
doit contenir `authority=PebbleCore`, `publication=verified`, quatre outcomes
`moved` du body, `noNormalSetPos=1`, `runtimeErrors=0` et
`probesRemoved=4`. La capture `navigation-embodiment-proof.png` reste une
preuve visuelle manuelle ; la trace et les tests déterministes portent les
assertions. `LabCoreAgentEntity` demeure un body expérimental non enregistré,
non persistant et non universel. Gate R reste acquise.

## CIV-21 — Observation écologique et calendrier civil V1

Le mode `scripts/verify-pebblelab-live.sh --ecological-observation` utilise
`PebbleLab-Disposable-EcologicalObservation-46`, active uniquement agents,
persistence, population, probes et la gate CIV-21, puis garde la session en
pause. `/lab ecological-observation on` active explicitement le schéma v12 sans
observation rétroactive ; `scan` observe l'agent focalisé et `proof` exécute la
preuve jetable automatisée.

Le sensor Pebble part de l'embodiment réel de chaque observer. Il visite au
plus un rayon horizontal 4 et vertical 2, 512 cellules, quatre chunks déjà
chargés, 1 024 lectures World, 64 entités et 128 résultats. Il normalise les
noms canoniques de biome, bloc, fluide et espèce, sans persister les IDs de
registre ou d'entité. Les chunks absents restent `chunkUnavailable` et ne sont
jamais demandés. Le cache technique, limité à 64 entrées, inclut identité du
World, contexte, dimension, origine et budgets ; il ne réutilise qu'un relevé
du même tick physique et est invalidé à chaque tick cognitif, mutation de
fixture, reload ou remplacement de World.

La date civile utilise 24 ticks de session par jour, 30 jours par saison et
quatre saisons par année depuis l'année 1. Le temps, l'heure et la météo du
World restent des observations physiques séparées : `spring` ne modifie ni
crop, ni température, ni météo. Les observations ont une TTL dynamique de
quatre ticks, une rétention globale de 128 et de 16 par agent. Elles ne
créditent ni inventory, ni `AgentCampStock`, ni ressource générique et ne
touchent pas `AgentLocalEcologyState`, qui demeure coarse/headless/dormant.

La preuve place puis restaure une petite fixture contrôlée avec dirt,
farmland, wheat, eau, sapling et cow. Elle vérifie deux identités de biome
PebbleCore distinctes, les contrastes eau/sol/animal/pêche présents puis
absents, crop `3→7`, météo `clear→rain`, affordance de pêche sans prédire loot
ou délai, séparation des observers, scan sans mutation, chunk absent sans
chargement, cache invalidé sur un autre `World`, benchmark de 32 requêtes (`1
miss + 31 hits`), checkpoint v12 byte-exact, capture rendue et cleanup. La
commande `--dry-run` reste le préflight ; la preuve réelle et l'inspection
manuelle du PNG sont obligatoires.

## CIV-22 — Agriculture et surplus géré V1

Le mode `scripts/verify-pebblelab-live.sh --agriculture` utilise
`PebbleLab-Disposable-Agriculture-46` et active seulement les dépendances
matérielles, persistence, population, lifecycle, skills, observation CIV-21 et
la gate Agriculture default-off. `/lab agriculture on` active le schéma v13
sans inventer plot, culture ou surplus ; `status` reste read-only et `proof`
prépare seulement une fixture locale jetable.

La preuve fait choisir à `agent_0` quatre cellules depuis de vraies observations
de sol et d'eau, se déplacer par `findPath`/`Entity.move`, labourer avec une
vraie hoe, consommer quatre vraies wheat seeds, puis progresser de stage 0 à 7
uniquement par les random ticks canoniques de `Farming.swift`. La récolte passe
par le break/drop Core, acquiert seulement les `ItemEntity` causaux et transfère
les items par la custody CIV-16 vers un vrai container. La réserve de graines
et le surplus courant sont relus physiquement ; leur historique v13 n'est ni
spendable, ni ownership, ni profession.

Le scénario vérifie aussi crop immature, targets stale, doublon, conflit de
workers, container/custody pleins, échecs tardifs, retrait externe et
réconciliation. Une saison civile ne change ni croissance ni rendement ; la
ferme ne crédite ni `AgentCampStock`, ni ressource générique, ni
`AgentLocalEcologyState`. La capture finale conserve deux crops, farmland, eau,
container et probes pour inspection manuelle, puis la terminaison restaure la
fixture et exige `runtimeErrors=0`.

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
care ou héritage. La tranche suivante termine le contrat global CIV-12 sans
créer un nouveau jalon top-level.

## CIV-12 — Dependent care et intégration lifecycle V1

Le mode `scripts/verify-pebblelab-live.sh --care` ajoute la gate exacte
`PEBBLELAB_APP_AGENTS_CARE=1` aux gates agents, persistence, population,
lifecycle, kinship, households, survival et consommation déjà existantes. La
commande explicite `/lab care on` transforme une session v8 en v9 ; `/lab care
status` ne fait qu'observer assignments, besoins, engagements, dependents
at-risk et digest. Un v9 est refusé si care ou l'une de ses dépendances manque,
et un v8 ne s'active jamais implicitement au restore.

Dans le monde jetable seed `46`, la vraie naissance d'`agent_4` crée son
assignment vers `agent_0` dans la transaction population/lifecycle/kinship/
household/care. Le newborn conserve `observationCount=0`, `actionCount=0` et
`movementCount=0` au tick de naissance, puis le caregiver interrompt son
activité, l'approche par le mouvement existant et fournit une unité réelle de
`foodRaw`. Le débit provient d'abord de son inventaire puis du `campStock`, et
la trace compare `foodBefore = foodAfter + consumedByDependent`; aucun besoin
n'est résolu lorsque le débit échoue. Le juvenile ne conserve que les capacités
perception, idle, retour au home, approche du caregiver et consommation de
nourriture déjà portée.

Un second processus recharge le v9 post-naissance et produit les mêmes octets,
digests, assignments, ressources et événements que le contrôle ininterrompu.
La preuve tardive réservée au harnais laisse d'abord réussir le candidat kernel
complet, force ensuite l'échec physique du probe newborn, puis compare session,
recorder, ordinals, ledger, probes et index d'entités avant/après. Les runs
positifs finissent avec `runtimeErrors=0` et cinq probes retirés ; le run
d'échec contient exactement l'erreur contrôlée attendue et retire quatre probes.
`PebbleAgents` n'accède pas au World et aucune trace d'appel ou d'événement de
mutation de bloc/World n'est observée ; aucun compteur artificiel d'attribution
care n'est revendiqué.

`CIV-12 — Kinship, Households and Dependent Care V1` est terminé localement.
Cette V1 n'introduit ni adoption, mariage, propriété, héritage, stock household,
enseignement, compétence ou institution de care. Le recalage post-CIV-12 a
ensuite désigné NEXT-1 comme première verticale prospective.

## NEXT-1 — Compétences pratiques et task matching V1

Le mode `scripts/verify-pebblelab-live.sh --skills` active exactement
`PEBBLELAB_APP_AGENTS_SKILLS=1` avec les gates matérielles nécessaires dans un
monde jetable seed 46. `/lab skills on` crée explicitement le schéma v10 sans
rétrocrédit ; `/lab skills status` expose profils, unités, niveaux dérivés et
digest sans devenir une autorité.

La preuve produit de vraies récoltes et livraisons, obtient des historiques
individuels différents, puis fait sélectionner `agent_1` comme helper de la
tâche de construction parce que son `materialHandling` est supérieur après les
contraintes d'éligibilité. Le checkpoint v10 est chargé dans un nouveau
processus et comparé byte à byte à un second run indépendant. Le harnais
jetable force aussi, après pose World et crédit construction dans la candidate,
une défaillance avant publication : bloc, session, ressources, preuves de
pratique, ledger, recorder, probes et index World sont restaurés, puis le même
run termine réellement la construction. Les runs positifs ont
`runtimeErrors=0`; le run d'échec a l'unique erreur contrôlée attendue.

`NEXT-1 — Practice-Based Skills and Task Matching V1` est terminé localement.
Il n'ajoute ni enseignement, profession, aptitude innée, bonus de rendement,
agriculture, propriété, connaissance ou culture. Prochaine verticale
prospective : `NEXT-2 — Demonstration, Teaching and Apprenticeship V1`.

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

## J→K — Natural targeting V1 (socle historique)

Le mode naturel reste désactivé par défaut et exige `PEBBLELAB_APP_AGENTS_NATURAL=1`, puis `/lab natural on`. Il n'active ni le mouvement, ni l'économie, ni la survie. Le mapping borné des fingerprints metadata `0` déjà enregistrés et générés (`oak_log#1520`, `birch_log#2032`, `stone#48`) ne sert plus qu'à la perception, au planning et à la compatibilité coarse ; il ne détermine aucun drop. Aucun bloc ne donne `foodRaw`; la nourriture de survie reste une fixture.

Le scan read-only couvre un rayon horizontal maximal de 8 et la bande verticale `agentY-2...agentY+4`, au plus 1 008 positions cibles et 384 lectures d'approche, sans charger de chunk. Cette bande couvre les différences de niveau simples du movement stack et les troncs accessibles sans ouvrir un scan vertical général. Il émet au plus 32 candidats puis 8 observations dans un ordre stable. La session conserve la source `naturalWorld`, le fingerprint, le target lock et la réservation. Le planner H2 et le movement stack restent les seuls chemins de navigation.

Depuis CIV-17, la récolte live relit le fingerprint exact puis délègue la mutation, les drops et l'usure à `executeBlockBreak`; elle acquiert ensuite les `ItemEntity` causaux dans la custody réelle avant publication. Le chemin headless/coarse historique conserve son crédit abstrait dans sa boundary de compatibilité, mais une transaction live n'écrit jamais dans les deux modèles.

L'ancien scénario `--natural` qui démontrait un crédit abstrait et une livraison `AgentCampStock` est superseded comme autorité live. L'option reste un alias de compatibilité vers la preuve `--harvest`; la section CIV-17 ci-dessus décrit le contrat physique actuel. Les tests headless conservent les anciennes transactions abstraites pour leur périmètre coarse explicite.

## K — Fixed Shelter Construction V1 (historique)

Le scénario ci-dessous décrit la preuve antérieure à CIV-18. Il est conservé
comme historique ; `--build` redirige désormais vers `--construction`, qui est
l'autorité live actuelle. Le chemin escrow reste couvert en headless/coarse.

Le mode `scripts/verify-pebblelab-live.sh --build` utilise exclusivement le monde jetable `PebbleLab-Disposable-Build-46`, la seed `46` et l'anchor `(20,66,-24)`. Après activation explicite des gates naturelle et construction, il sélectionne en lecture seule le site d'origine `(22,66,-25)`, collecte six `wood` et trois `stone` naturels, les livre au stock existant puis finance atomiquement le blueprint fixe `fixedLeanToV1`. Le blueprint place, dans l'ordre, trois pierres de mur bas, trois troncs de mur haut et trois troncs de toit; l'entrée `(1,0,0)` et la cellule de repos `(1,0,1)` restent vides.

La preuve interrompt l'auto-construction après les cellules `0...2`, exécute quatre ticks sans pose, reprend exactement à l'index `3`, achève `9/9`, puis active la survie pour vérifier le nouveau home `(23,66,-24)` et le repos sous le toit. Les trois captures `fixed-shelter-before.png`, `fixed-shelter-partial.png` et `fixed-shelter-complete.png` complètent la trace structurée; elles ne remplacent pas les assertions de fingerprints, d'ordre et de rollback de `pebsmoke`.

Enfin, `/lab build clear` restaure et vérifie les neuf fingerprints originaux en ordre inverse, rend `wood=6, stone=3` au stock, supprime le projet et restaure l'ancien home. Les ressources naturelles récoltées restent détruites. La construction est une sandbox temporaire: elle n'ouvre ni placement libre, ni crafting, ni persistance.
