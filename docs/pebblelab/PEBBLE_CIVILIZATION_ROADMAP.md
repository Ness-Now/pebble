# Pebble Civilization — Roadmap V3 Reuse-First

## Statut et autorité

Cette roadmap est l’autorité prospective canonique `V3-Reuse-First`. Elle
ordonne les risques et les dépendances sans annoncer comme acquise une capacité
seulement planifiée. Le code et les tests du HEAD validé restent l’autorité sur
l’état réellement implémenté ;
[`PEBBLE_CIVILIZATION_VISION.md`](PEBBLE_CIVILIZATION_VISION.md) reste
l’autorité sur la cible produit et ses invariants.

[`ROADMAP_MANIFEST.json`](ROADMAP_MANIFEST.json) est la projection
machine-lisible de ce document. En cas d’écart, cette roadmap humaine contrôle
la direction prospective et le manifest doit être resynchronisé.
[`ROADMAP.md`](ROADMAP.md) conserve le journal historique détaillé sans définir
la prochaine étape.

Baseline de ce recalage :
`b58f71b75110c2e65403cd073409a8559429ec77`.

## Position canonique actuelle

`CIV-00` à `CIV-25` sont terminés et acquis dans leurs contrats bornés. Gate R
est acquise. Les correctifs non canoniques `GATE-B-CORR-01` et
`GATE-B-CORR-02` sont publiés ; ils ont fermé les quatre blockers historiques
de l'évaluation #1 sans promouvoir de phase `CIV-*`.

Gate B re-evaluation #2, démarrée sur le baseline
`fc618de61437c4acd63ec0ff41823e6d91b56d0a`, est `FAIL`. Le chemin autonome
a depuis identifié l'absence d'initiation Teaching intégrée. Le correctif local
non canonique `GATE-B-CORR-03 — Integrated Local Apprenticeship Initiation`
remédie maintenant ce blocker : la cognition normale dérive une opportunité
locale contextuelle, les deux participants décident, puis l'autorité CIV-20
existante sélectionne le mentor et crée l'apprentissage. La preuve intégrée
conserve la causalité réussite réelle → démonstration sans skill gratuit →
réussite propre de l'élève → pratique guidée. La campagne 5/3/2 n'a pas été
relancée. Gate B reste non acquise, sa re-evaluation #3 est requise et `CIV-26`
reste `planned`.

Les noms `NEXT-1` et `NEXT-2` sont uniquement des alias historiques :

- `NEXT-1` désignait la verticale de compétences maintenant canonisée comme
  `CIV-13` et terminée ;
- `NEXT-2` désignait la proposition d’enseignement maintenant canonisée comme
  `CIV-20`.

Aucun identifiant `NEXT-*` n’est une phase canonique V3.

## État acquis, sans extrapolation

Les preuves acquises couvrent notamment, dans leurs limites actuelles :

- le runtime partagé `PebbleAgents` et `AgentSimulationSession` comme source
  unique des transitions cognitives et civilisationnelles ;
- les identités stables, l’horloge simulée et le ledger causal ;
- l’information sociale, la confiance dirigée, le canal physique local, les
  tâches coopératives et leurs contributions matérielles ;
- les checkpoints versionnés, restart et replay causal bornés ;
- la population locale, la migration, les métriques settlement, l’écologie
  locale abstraite, la mortalité par famine et le lifecycle borné ;
- la parenté durable, les households, le dependent care et les compétences
  issues de succès matériels réels ;
- l'enseignement CIV-20 borné, local et refusable, où seule la propre réussite
  matérielle de l'élève crédite sa pratique ;
- NaturalResource V1 converge en live vers le break/drop PebbleCore et la
  custody réelle ; son chemin abstrait subsiste seulement comme compatibilité
  coarse/headless.
- Construction V1 conserve blueprint, ordre, ledger, causalité et skills, mais
  ses cellules live utilisent désormais la custody réelle et
  `executeBlockPlacement` ; son escrow abstrait subsiste seulement sur le
  chemin coarse/headless.
- la gateway actor-neutral CIV-15 pour break/place, avec refus stale,
  vérification de custody/tool state et rollback borné avant publication.
- le bridge CIV-16 d’identité matérielle et de custody réelle, avec
  `ItemStack`, containers, fingerprints, receipts et rollback vérifié.
- la frontière navigation/embodiment CIV-19 : intentions et waypoints restent
  civilisationnels, tandis que pathfinding, collision, mouvement et position
  live vérifiée restent l'autorité de PebbleCore via les adapters de Pebble.
- l'observation écologique CIV-21 reste locale, bornée et read-only ; son
  calendrier civil n'altère ni croissance, ni météo, ni autre vérité physique.
- l'agriculture CIV-22 orchestre labourage, plantation, croissance Farming,
  récolte, custody, dépôt et surplus courant à partir des vrais outils, items,
  blocs, random ticks et containers PebbleCore, sans rendement abstrait live.

Ces preuves ne constituent pas encore une société locale autosuffisante, une
économie d’items complète, une grande population, un cycle de vie complet, un
système de connaissance, une culture, une institution ou une civilisation
médiévale.

## Décision Reuse-First

Tout nouveau besoin physique commence par un audit ciblé de PebbleCore :

```text
besoin physique
-> audit PebbleCore
-> mécanique existante ?
   -> oui : réutiliser, adapter, ou extraire une primitive actor-neutral
   -> non : ajouter le minimum générique dans le layer propriétaire
```

Une partie des chemins actuels de use/break/place/craft est encore façonnée
autour de `Player`. Cela justifie une extraction actor-neutral minimale ou un
adapter dans `Pebble`, jamais une copie des règles dans `PebbleAgents`.

Sont interdits par défaut les seconds moteurs live de farming, crafting,
inventory, combat, animaux, redstone, rails, persistence World et pathfinding
physique général.

## Architecture propriétaire

| Layer | Autorité |
| --- | --- |
| `PebbleCore` | Vérité physique : `World`, chunks, blocs, items, entités, règles de gameplay, physique et persistence World. |
| `Pebble` | Sensors, adapters et executors actor/World : observation bornée, prévalidation, mutation, vérification, outcome et rollback. |
| `PebbleAgents` | Cognition et civilisation déterministes : identité, besoins, mémoire, décisions, causalité sociale, population, lifecycle, parenté, care, skills et futurs domaines sociaux. |
| `AgentSimulationSession` | Aggregate root civilisationnel unique et propriétaire des transitions partagées ; aucun second kernel cognitif. |
| `PebbleLab` | Runner headless, scénarios, long-runs, métriques, snapshots, benchmarks et évaluation. |
| `pebsmoke` | Preuves, invariants, régressions et fault injection. |
| UI / God / LLM | Présentation ou proposition structurée seulement ; aucune propriété du World, des transactions ou de la cognition. |

`PebbleAgents` reste pur et n’importe pas `PebbleCore`, AppKit, Metal, un
réseau ou un provider LLM. Le live reçoit des observations et outcomes validés
par `Pebble`.

## Classification des abstractions existantes

Les classes suivantes sont normatives. Elles décrivent la trajectoire de
migration, pas une suppression immédiate.

| Classe | Systèmes | Décision |
| --- | --- | --- |
| `CANONICAL` | `AgentSimulationSession`, identités/clock, causal ledger, checkpoint/replay, social/trust, communication locale, cooperation/tasks, population, mortality/lifecycle, kinship, households, care, skills | Continuer dans `PebbleAgents` comme vérité civilisationnelle. |
| `LIVE_BRIDGE` | contrôleur, sensors, `PebbleAgentEmbodiment`, adapters, coordination de mouvement et executors de `Pebble` | Conserver comme frontière actor/World ; ils n’acquièrent aucune cognition parallèle. |
| `COARSE_DORMANT` | `AgentLocalEcologyState`, `AgentCampStock`, catégories `foodRaw`/`wood`/`stone`, `AgentBoundedRoutePlanner` | Conserver pour headless, coarse, dormant ou waypoints uniquement avec conservation et parité explicites. |
| `TO_CONVERGE` | projection inventory/stock live et frontière persistence World/civilisation | Migrer incrémentalement vers les mécaniques PebbleCore après preuve de remplacement et rollback. |
| `LEGACY_FROZEN` | anciennes stacks et fixtures explicitement superseded par le runtime partagé | Garder pour compatibilité/régression ; ne plus leur ajouter de capacité produit et ne pas les supprimer en big-bang. |

Une abstraction peut fournir aujourd’hui une preuve de bridge tout en ayant
`TO_CONVERGE` comme destination. La classification primaire ci-dessus indique
où doit aller le produit.

### Contrats de migration permanents

- `AgentLocalEcologyState` peut devenir une projection coarse/dormant ; il ne
  doit pas devenir un second moteur écologique live.
- `AgentCampStock` et les catégories génériques restent des modèles de
  compatibilité, conservation et agrégation pendant que le live converge vers
  de vrais `ItemStack` et containers.
- `AgentBoundedRoutePlanner` reste utile en headless, coarse et pour des
  waypoints ; il ne devient pas un second pathfinder physique général.
- NaturalResource V1 et Construction V1 conservent leurs preuves de
  transaction, idempotence et rollback pendant leur convergence vers les
  règles Pebble de break/drop et place.
- checkpoint/replay, causal ledger, kinship, households, care, social/trust et
  skills restent des systèmes Civilization canoniques.
- Aucune abstraction V1 n’est retirée avant preuve de remplacement, parité des
  outcomes et migration compatible.

## Matrice de réutilisation physique

Pebble fournit déjà, ou fournit substantiellement, les autorités suivantes.
Les phases futures les réutilisent ou les adaptent au lieu de les réimplémenter
dans `PebbleAgents`.

| Domaine physique | Autorité existante | Décision V3 |
| --- | --- | --- |
| worldgen, biomes, chunks | PebbleCore `Gen` et `World` | Réutiliser et observer par DTO bornés. |
| farming, croissance, random ticks | PebbleCore `Farming` | Réutiliser ; aucun `FarmingEngine` agent. |
| animaux, babies, breeding | PebbleCore entités/AI | Réutiliser ; Civilization ajoute décisions, tâches et valeur sociale. |
| pêche et loot | PebbleCore fishing bobber/loot | Réutiliser les règles, équipements, délais et vrais drops. |
| registries items/blocs | PebbleCore registries | Autorité des identités physiques ; ne pas recopier le catalogue dans un enum agent. |
| inventories et containers | PebbleCore `ItemStack`, inventories et block entities | Autorité live ; snapshots civilisationnels uniquement lorsque nécessaires. |
| recipes, crafting, smelting | PebbleCore recipes/crafting/furnaces | Réutiliser pour toute transformation matérielle. |
| outils et durability | PebbleCore item/tool definitions et usure | Réutiliser ; aucun bonus de skill ne crée de matière. |
| block breaking et drops | PebbleCore interaction/drop rules | Faire converger NaturalResource V1 vers ces primitives. |
| block placement | PebbleCore placement, replaceability, orientation, collision et block entities | Faire converger Construction V1 vers ces primitives. |
| physique et collision | PebbleCore entités/World | Autorité sur le déplacement incarné. |
| pathfinding/navigation physique | PebbleCore A* et `Navigation` | Réutiliser pour le live ; garder le planner agent borné pour coarse/waypoints. |
| combat | PebbleCore combat/damage/equipment | Réutiliser ; Civilization ajoute causes, morale, coordination et logistique. |
| redstone | PebbleCore redstone | Réutiliser comme technologie matérielle réelle. |
| rails et minecarts | PebbleCore rails, véhicules et rail physics | Réutiliser ; Civilization ajoute projets, droits, financement et maintenance. |
| persistence World/SQLite | PebbleCore `SaveDB` et save queue | Réutiliser ; la persistence Civilization se réconcilie avec elle sans second World-save. |

## Roadmap canonique CIV-00 à CIV-67

Les statuts `planned` ci-dessous signifient explicitement « non acquis ». Les
détails d’API restent à fixer par la mission qui ouvre chaque verticale.

### Fondations acquises

| Phase | Statut | Verticale |
| --- | --- | --- |
| `CIV-00` | completed | Documentation and Civilization Rebaseline |
| `CIV-01` | completed | Behavior-Preserving Runtime Modularization |
| `CIV-02` | completed | Stable Identity, Simulation Clock and Causal Ledger |
| `CIV-03` | completed | Social Information and Directed Trust V1 |
| `CIV-04` | completed | Physical Local Communication V1 |
| `CIV-05` | completed | Cooperative Material Tasks V1 |
| `CIV-06` | completed | Checkpoint, Restart and Replay V1 |
| `CIV-07` | completed | Population and Local Migration V1 |
| `CIV-08` | completed | Settlement Metrics V1 |
| `CIV-09` | completed | Local Ecology V1 |
| `CIV-10` | completed | Starvation Mortality V1 |
| `CIV-11` | completed | Age, Stages, Reproduction and Birth V1 |
| `CIV-12` | completed | Kinship, Households and Dependent Care V1 |
| `CIV-13` | completed | Practice-Based Skills and Task Matching V1 |

### Convergence Reuse-First

| Phase | Statut | Verticale |
| --- | --- | --- |
| `CIV-14` | completed | Reuse & Convergence Baseline |
| `CIV-15` | completed | Actor-Neutral Physical Action Gateway V1 |
| `CIV-16` | completed | Real Material Identity and Inventory Bridge V1 |
| `CIV-17` | completed | Harvest and Resource Convergence V1 |
| `CIV-18` | completed | Construction and Placement Convergence V1 |
| `CIV-19` | completed | Navigation and Embodiment Boundary Consolidation V1 |

`CIV-15` à `CIV-18` ont fermé les frontières action, custody, harvest et
construction. `CIV-19` a consolidé la dernière frontière : la
civilisation décide pourquoi et où aller, tandis que PebbleCore choisit et
exécute le mouvement physique. La validation senior du SHA publié
`c2e78b9c325f3012f6ea6fa31a6afd8da5698a12` a acquis Gate R.

#### Contrat acquis CIV-19

- `PebbleAgents` conserve intentions, destinations, waypoints, progression
  cognitive et projections coarse/headless ; il n'importe pas PebbleCore.
- `Pebble` résout un `PebbleAgentEmbodiment` un-à-un, valide identité, World,
  lifecycle, position, orientation et custody, puis adapte l'intention.
- PebbleCore `findPath`, `Entity.move`, collision et `World` sont l'autorité de
  chaque pas live. Un changement dynamique invalide le pas et provoque un
  calcul Core ultérieur ; il n'existe ni second A* ni fallback de téléportation.
- La position physique vérifiée gagne. Une dérive bornée produit une
  réconciliation explicite ; une dérive hors contrat, un embodiment manquant,
  dupliqué ou rattaché à un ancien World est refusé.
- `AgentBoundedRoutePlanner` et `AgentBoundedTravel` restent déterministes pour
  headless/coarse et la sélection de waypoints. Ils ne décident plus du chemin
  physique live détaillé.
- Harvest, construction et les gateways d'action calculent le reach depuis
  l'embodiment physique. Une publication civilisationnelle n'arrive qu'après
  mouvement/mutation et vérification physiques ; un échec tardif déclenche le
  rollback physique vérifié ou refuse la publication.
- `LabCoreAgentEntity` reste un body expérimental, non enregistré, non
  persistant et non présenté comme type fondamental universel.

### Société locale autonome — Gate B

| Phase | Statut | Verticale |
| --- | --- | --- |
| `CIV-20` | completed | Demonstration, Teaching and Apprenticeship V1 |
| `CIV-21` | completed | Ecological Observation and Civil Calendar V1 |
| `CIV-22` | completed | Agriculture and Managed Surplus V1 |
| `CIV-23` | completed | Fishing, Hunting and Wild Subsistence V1 |
| `CIV-24` | completed | Livestock and Animal Capital V1 |
| `CIV-25` | completed | Durable Work Commitments and Emergent Professions V1 |

Ces phases doivent produire plusieurs stratégies matérielles viables et une
spécialisation dérivée de la pratique, de l’enseignement et des besoins, sans
classe professionnelle imposée.

#### Contrat acquis CIV-20

- `AgentSimulationSession` possède un état Teaching séparé, borné,
  déterministe et default-off : apprentissages temporaires, démonstrations,
  expositions et liens de pratique guidée.
- Une démonstration référence un succès matériel causal réel et frais du
  teacher, avec teacher au moins `practiced`, student consentant et observation
  locale exacte issue des embodiments live et de la géométrie CIV-04.
- Regarder ne crédite jamais de compétence. Seul le succès matériel propre du
  student passe par le crédit de pratique CIV-13 ; le lien guidé décrit cette
  causalité sans XP, rendement ou matière supplémentaire.
- La confiance départage des mentors autrement éligibles mais ne crée ni
  capacité ni résultat. L'apprentissage reste refusable, interruptible,
  expirant et réconcilié avec lifecycle, décès, migration, care et sécurité.
- Les juveniles peuvent observer sans contourner leurs capacités matérielles ;
  les newborns ne deviennent pas apprentis productifs.
- Checkpoint/replay v11 conserve l'état Teaching et reste compatible avec les
  schémas v1-v10, où Teaching demeure désactivé.
- Le bridge live Teaching ne mute ni World ni inventory, ne planifie aucun
  chemin et n'exécute aucune action physique ; il observe et référence les
  actions Pebble déjà validées.

#### Contrat acquis CIV-21

- La vérité écologique live reste dans le `World` PebbleCore. Un sensor Pebble
  local, borné et read-only normalise biome, eau, sols, crops/plantes,
  animaux, affordance de pêche, météo et temps physique sans charger de chunk.
- Chaque observation appartient à un observer incarné et conserve uniquement
  des noms canoniques de biome, bloc, fluide et espèce ; aucun identifiant de
  registre ou d'entité runtime ne traverse vers `PebbleAgents`.
- Le calendrier civil déterministe dérive exclusivement du tick de
  `AgentSimulationSession` : 24 ticks par jour, 30 jours par saison, quatre
  saisons par année et epoch année 1. Une saison civile n'applique aucun effet
  physique, climatique ou agricole.
- Fraîcheur, historiques, scans, résultats, lectures, entités et cache sont
  bornés. Un chunk indisponible reste `unknown`, jamais une absence inventée ;
  un changement pertinent invalide le cache avant une nouvelle décision.
- Observer ne crédite ni ressource, ni inventory, ni `AgentCampStock`, et ne
  mute ni les yields de `AgentLocalEcologyState` ni le World. Cette écologie V1
  historique reste une projection coarse/headless/dormant de compatibilité.
- Checkpoint/replay v12 conserve observations normalisées et calendrier. Les
  schémas v1-v11 restent compatibles avec CIV-21 désactivé et aucune
  observation rétroactive.

#### Contrat acquis CIV-22

- L'intention, le plan borné, les réservations et l'historique agricole sont
  civilisationnels ; farmland, crops, hydratation, lumière, random ticks,
  croissance, drops, items, durabilité et containers restent l'autorité de
  PebbleCore.
- Le live utilise de vrais outils, planting items et positions physiques via
  les gateways CIV-15/16/17/19. Il sélectionne un site depuis une observation
  CIV-21 fraîche, puis revalide le World avant chaque action.
- La croissance vient exclusivement des random ticks canoniques. Le calendrier
  civil peut dater semis et récoltes mais ne change jamais la croissance.
- La réserve de graines est une quantité d'items physiques réellement
  présente. Le surplus est une vue read-only dérivée d'une custody/container
  réelle ; son record historique n'est ni spendable, ni ownership.
- `AgentLocalEcologyState`, `AgentCampStock` et les catégories génériques
  restent coarse/headless/dormant : une ferme live ne leur crédite aucun yield
  ou stock fantôme.
- Le checkpoint v13, s'il est activé, conserve seulement intention, références
  stables et histoire bornée ; le champ physique reste dans le save du World et
  doit être réconcilié.

#### Contrat acquis CIV-23

- `AgentSimulationSession` possède un état WildSubsistence default-off,
  déterministe et borné : opportunités locales, réservations one-shot,
  tentatives, outcomes terminés et historiques non spendables. Il ne possède
  ni population animale, ni stock de poisson, ni HP de proie, ni inventaire ou
  moteur de régénération parallèle.
- La pêche réutilise le vrai `FishingBobber`, son eau, son délai
  nibble/bite, le RNG et les loot tables PebbleCore. Une primitive de cast
  actor-neutral et le résultat du retrieve exposent les IDs exacts des
  `ItemEntity`; l'adapter Pebble réutilise ensuite la custody CIV-16/17 et la
  durabilité canonique de la rod, sans reroll silencieux.
- La chasse résout une vraie Entity animale observée, approche via
  `findPath`/`Entity.move`, puis applique une attaque melee Core minimale
  actor-neutral. Santé, mort, attribution au dernier acteur dommageant,
  durabilité et drops restent physiques ; une proie morte ou stale ne produit
  aucun second décès ni loot.
- La cueillette sauvage V1 choisit un `sweet_berry_bush` mature observé, puis
  réutilise le break/drop canonique CIV-15/17 et la custody exacte. Sa
  déplétion est un état du World et sa croissance éventuelle vient uniquement
  des random ticks PebbleCore.
- La sélection compare agriculture, pêche, chasse et cueillette à partir
  d'observations CIV-21 fraîches, de l'équipement réellement disponible, de la
  distance, du besoin existant, de l'histoire locale propre et de la pratique,
  avec tie-break déterministe. Elle ne connaît ni futur loot, ni rendement
  caché, ni meilleure stratégie globale.
- Les domaines minimaux `fishing` et `hunting` complètent `foraging` pour la
  cueillette. Seule une acquisition matérielle physique causalement validée
  crédite exactement une pratique ; Teaching accepte ces domaines sans
  conférer de skill par observation et aucun skill ne change RNG, damage,
  drops ou croissance.
- Cod, salmon, chicken et sweet berries restent classés par les métadonnées
  food PebbleCore. Le correctif non canonique `GATE-B-CORR-01` réutilise une
  description Core actor-neutral pour les aliments V1 à débit simple, puis
  publie un outcome validé vers le même `AgentNeeds.hunger` que la starvation.
  Les effets, restes et téléportations restent hors scope et aucun second
  moteur de calories n'est créé.
- Checkpoint/replay v17 conserve seulement l'état civilisationnel terminé et
  reste compatible avec v1-v16, les états postérieurs absents par défaut. Un cast ou
  combat physique actif n'est pas restart-safe et doit être annulé ou
  réconcilié depuis le World, jamais rejoué comme moteur Civilization.
- Les trois chemins live produisent zéro crédit `AgentCampStock`, inventory
  générique ou yield CIV-09. La disponibilité courante vient uniquement de la
  custody ou d'un container physique ; Gate R reste acquise et Gate B reste
  non acquise.

#### Contrat acquis CIV-24

- Les animaux, leur santé, âge, déplacement, collision, reproduction, bébés,
  mort et persistence physique restent exclusivement sous l’autorité de
  PebbleCore. `PebbleAgents` n’introduit aucun `AnimalSimulation` parallèle.
- `AgentLivestockState` conserve seulement groupes bornés, management areas,
  responsabilités temporaires, tâches/réservations, décisions, outcomes et
  histoire causale. Être managed n’est ni être tame, ni être possédé, ni
  établir un claim ou une valeur monétaire.
- Le mouton est l’espèce représentative V1. L’alimentation consomme un vrai
  wheat item puis appelle la primitive Core actor-neutral ; `BreedGoal` et le
  clock Core créent et font grandir le vrai offspring. Aucune naissance
  abstraite ne peut valider la verticale.
- La conduite réutilise la laisse, la navigation, les collisions et le
  mouvement Core, sans second pathfinder ni téléportation. L’enclos est une
  management area opérationnelle, pas une forcefield ou un droit foncier.
- La tonte réutilise l’état `Sheep.sheared`, le RNG et de vrais `ItemEntity`
  wool, ensuite transférés par la custody transactionnelle existante. Les
  produits ne sont publiés qu’après acquisition et vérification physiques.
- `AgentLivestockCapitalSnapshot` est une vue dérivée, bornée et non spendable
  des animaux vivants résolus, jeunes/adultes, readiness, produits, naissances
  et pertes. Le World gagne toujours ; missing, dead et ambiguous sont
  réconciliés explicitement sans compensation ni nearest-match inventé.
- La reproduction est différée quand le feed physique compatible, net de la
  réserve de semis CIV-22, est insuffisant ou quand la capacité/care l’exige.
  Le live ne crédite ni `AgentCampStock`, ni inventory générique, ni yield
  CIV-09 et un animal managed est exclu de Hunting tant qu’il est résolu vivant.
- Le domaine `husbandry` crédite exactement les succès physiques distincts de
  feed, herd et product custody. Observation, attente, décision et birth
  observation ne donnent aucun XP ; Teaching peut transporter la provenance,
  jamais le résultat ou un bonus physique.
- Checkpoint/replay v15 conserve les records civilisationnels, jamais les
  animaux. Les runtime entity IDs restent transitoires ; après restart,
  l'identité physique reste unresolved/ambiguous jusqu'à ré-observation et
  réadmission explicites. Le bridge ne choisit jamais l'animal le plus proche
  et ne déduit pas l'identité d'une simple correspondance espèce-position. Les
  schémas v1-v14 gardent Livestock désactivé et vide.
- Gate R reste acquise. Cette verticale seule n'acquiert pas Gate B ;
  l'évaluation dédiée post-CIV-25 a depuis confirmé les blockers ci-dessous.

#### Contrat acquis CIV-25

- `AgentSimulationSession` possède l’unique état WorkCommitments default-off,
  déterministe et borné : demandes causales et fraîches, responsabilités
  temporaires, cadence, revue, expiration, suspension, reprise, remplacement,
  outcomes normalisés, histoire compacte et réputation de travail locale.
- Agriculture, wild subsistence, livestock, construction, dependent care et
  coopération restent les sources de besoins, tâches et résultats. CIV-25
  organise leur continuité ; il ne crée ni moteur de demande omniscient, ni
  second scheduler CIV-05, ni executor physique ou tâche fictive.
- Le matching sépare éligibilité et rang décomposable : capacité, skill et
  pratique, continuité, réputation locale connue, trust contextuel, distance
  observée, disponibilité et charge, obligations/care, ainsi que vrais outils
  et ressources. Le dernier tie-break est l’`AgentID` ; aucun profil n’accorde
  permission ou exclusivité.
- Chaque preuve de travail référence exactement un outcome causal existant.
  Une source ne peut créditer qu’une fois l’histoire, le fulfillment et la
  réputation ; succès, échec imputable, blocage externe et interruption
  légitime restent distingués sans produire matière, skill ou résultat.
- `AgentProfessionProfile` est une projection read-only recomputée à la
  demande. Elle combine distributions récentes et lifetime, engagements
  actifs/passés, continuité, skill/pratique, apprentissage et réputation ; elle
  expose primary/secondary domains et une concentration integer/fixed-point,
  sans setter, classe, statut, propriété, salaire, héritage ou bonus physique.
- Multi-activité et reconversion restent possibles : l’histoire lifetime
  persiste tandis que l’activité récente peut déplacer progressivement le
  domaine dominant. Une crise, l’indisponibilité ou une obligation de care
  suspend la responsabilité productive ; un remplaçant capable, même non
  spécialiste, reste sélectionnable sans recevoir l’histoire de son
  prédécesseur.
- Les métriques descriptives exposent coverage par domaine, dépendance envers
  un seul worker, depth de remplacement, concentration et coordination. Elles
  ne créent ni droit CIV-26, ni workshop CIV-27, ni guilde CIV-49, ni booléen
  runtime `GateBState`.
- Checkpoint/replay v16 conserve l’état Work causal et borné. Les schémas
  v1-v15 restent chargeables avec CIV-25 désactivé et vide ; aucun engagement,
  profil ou réputation passé n’est inventé, et les profils se recomputent
  byte-exact depuis leurs sources durables.
- La preuve live réutilise de vraies actions Pebble de pêche, chasse et
  cueillette puis leurs outcomes déjà vérifiés. Elle montre trois profils
  dérivés distincts, suspension/reprise de crise et zéro multiplicateur,
  crédit abstrait, delta `AgentCampStock`, inventory générique ou yield
  `AgentLocalEcologyState`. Gate R reste acquise. Ces preuves sont des contrats
  de composant ; elles ne prouvent pas à elles seules Gate B.

#### Évaluations candidates Gate B — FAIL, CORR-01/CORR-02 publiés, CORR-03 local

L'[évaluation dédiée](GATE_B_CANDIDATE_EVALUATION.md) #1 a confirmé quatre
blockers. Les jalons correctifs non canoniques publiés `GATE-B-CORR-01 — Real
Food Consumption and Survival Convergence` et `GATE-B-CORR-02 — Autonomous
Agent Activity Orchestration and Playable Observer Convergence` ont remédié ces
quatre seams :

- `B-BLOCKER-FOOD-CLOSURE` : `CLOSED / PUBLISHED` ; un vrai aliment
  Core en custody exacte peut désormais modifier la survie canonique sans
  crédit `.foodRaw` ;
- `B-BLOCKER-AUTONOMOUS-PLAYABLE-SLICE` : `CLOSED / PUBLISHED` par
  sélection déterministe dans `AgentSimulationSession`, intents typés,
  exécuteurs Pebble existants et slice passive default-off ;
- `B-BLOCKER-LIVESTOCK-RESERVE-CLOSURE` : `CLOSED / PUBLISHED` ; la
  réserve physique de plantation rend la reproduction inéligible avant tout
  spend et les exécuteurs Core restent autoritaires ;
- `B-BLOCKER-CRISIS-REPLACEMENT-ORCHESTRATION` : `CLOSED / PUBLISHED` ;
  la revue normale suspend, choisit un remplaçant capable et attend son outcome
  réel avant fulfillment.

CORR-02 ajoute aussi un chemin de care physique : custody réelle du caregiver,
FoodDef Core, débit exact puis hunger canonique du dependent, sans fallback
`.foodRaw` en mode physique. Les correctifs ne constituent pas la campagne
d'acceptance.

Gate B re-evaluation #2 reste historiquement `FAIL`. Le correctif non canonique
`GATE-B-CORR-03 — Integrated Local Apprenticeship Initiation` remédie localement
son blocker B7 par un appel normal, contextuel, local et borné dans
`AgentSimulationSession`. Il réutilise le selector/ranker CIV-20, les
démonstrations et la pratique guidée existants ; il n'ajoute ni scheduler,
oracle global, skill gratuit, profession ni matière. La campagne 5/3/2 et Gate
B re-evaluation #3 n'ont pas été exécutées. Gate B reste non acquise, cette
roadmap ne renumérote pas `CIV-26` et ne le passe pas `current`.

### Économie matérielle locale — Gate C

| Phase | Statut | Verticale |
| --- | --- | --- |
| `CIV-26` | planned | Possession, Custody, Claims and Use Rights V1 |
| `CIV-27` | planned | Production, Tools and Workshops V1 |
| `CIV-28` | planned | Barter and Local Exchange V1 |
| `CIV-29` | planned | Debt, Promises and Durable Contracts V1 |
| `CIV-30` | planned | Physical Markets and Local Price Discovery V1 |
| `CIV-31` | planned | Currency, Units of Account and Accounting V1 |

Les biens restent physiques, transportés et conservés. Les marchés, contrats
et monnaies n’autorisent ni téléportation, ni double dépense, ni prix global
omniscient.

### Persistence et échelle — Gate D

| Phase | Statut | Verticale |
| --- | --- | --- |
| `CIV-32` | planned | World/Civilization Persistence Convergence V1 |
| `CIV-33` | planned | Multi-Settlement, Population Scaling and Fidelity Tiers V1 |
| `CIV-34` | planned | Training and Evaluation Bridge V1 |

Le training bridge reste optionnel et non bloquant. Les transitions
live/near/dormant conservent identité, matière et obligations ; aucune policy
externe ne devient autorité.

### Continuité générationnelle — Gate E

| Phase | Statut | Verticale |
| --- | --- | --- |
| `CIV-35` | planned | Homeostasis, Health, Aging and Mortality V2 |
| `CIV-36` | planned | Genetics, Development and Phenotype V1 |
| `CIV-37` | planned | Childhood Learning and Social Development V2 |
| `CIV-38` | planned | Unions, Family Relations, Lineages and Houses V1 |
| `CIV-39` | planned | Inheritance, Estates and Succession V1 |

Génétique, développement, connaissance, compétence, culture, profession et
statut restent distincts. Les skills ne sont jamais hérités et les estates
référencent de vrais biens, claims et obligations.

### Savoir et culture cumulative — Gate F

| Phase | Statut | Verticale |
| --- | --- | --- |
| `CIV-40` | planned | Structured Knowledge Graph V1 |
| `CIV-41` | planned | Oral Transmission and Distortion V1 |
| `CIV-42` | planned | Learned Proto-Language V1 |
| `CIV-43` | planned | Compositional and Long-Distance Communication V1 |
| `CIV-44` | planned | Writing and Literacy V1 |
| `CIV-45` | planned | Books, Manuscripts, Copying and Translation V1 |
| `CIV-46` | planned | Archives, Libraries and Cumulative Knowledge V1 |
| `CIV-47` | planned | Distributed Culture, Norms and Ritual Practices V1 |

La vérité du World, une affirmation, la compréhension, la croyance, la
tradition et l’énoncé restent séparés. Les messages longue distance et les
livres ont un support physique ; le savoir peut se déformer ou disparaître.

### Institutions médiévales — Gate G

| Phase | Statut | Verticale |
| --- | --- | --- |
| `CIV-48` | planned | Generic Organization Kernel V1 |
| `CIV-49` | planned | Guilds and Professional Institutions V1 |
| `CIV-50` | planned | Heraldry and Visible Identity V1 |
| `CIV-51` | planned | Settlements, Territory, Land and Obligations V1 |
| `CIV-52` | planned | Governance, Charters, Law and Justice V1 |
| `CIV-53` | planned | Beliefs, Myths and Emergent Religion V1 |
| `CIV-54` | planned | Diplomacy, Treaties and Dynastic Alliances V1 |
| `CIV-55` | planned | Conflict, Defense, Raids and War Logistics V1 |
| `CIV-56` | planned | Emergent Polities and Alternative Feudalities V1 |

Les labels politiques, religieux ou culturels restent descriptifs. Ils
découlent de comportements, appartenances, ressources, croyances et histoires
observables ; ils ne créent jamais directement leurs effets.

### Technologie et Renaissance alternative — Gate H

| Phase | Statut | Verticale |
| --- | --- | --- |
| `CIV-57` | planned | Technology, Crafting Knowledge and Innovation V1 |
| `CIV-58` | planned | Redstone, Rails and Infrastructure V1 |

L’innovation réutilise les recettes et mécaniques réelles. Redstone, rails et
minecarts sont des technologies matérielles coûteuses, maintenues, transmissibles
et perdables.

### God mode, LLM optionnel et acceptation finale

| Phase | Statut | Verticale |
| --- | --- | --- |
| `CIV-59` | planned | God Observer, Historiography and Time Control V1 |
| `CIV-60` | planned | Divine Interventions, Revelations and Prophets V1 |
| `CIV-61` | planned | LLM Provider Abstraction and Deterministic Mock V1 |
| `CIV-62` | planned | Local LLM Prototype and Benchmark |
| `CIV-63` | planned | Grounded Dialogue, Autobiography and Player Contact V1 |
| `CIV-64` | planned | Dynamic Cognitive Budget and Large-Scale Inference V1 |
| `CIV-65` | planned | Genesis Presets and Founder World |
| `CIV-66` | planned | Long-Duration Medieval Civilization Acceptance |
| `CIV-67` | planned | Incarnation and God World Final |

Le monde doit fonctionner avec le provider LLM désactivé. Un LLM tardif peut
verbaliser, résumer, reformuler ou proposer une structure validable ; il ne
mutera jamais directement le World, l’inventaire, les transactions ou l’état
cognitif. Le God mode observe d’abord ; toute intervention produit un événement
physique ou informationnel audité, et l’incarnation réutilise les lois
ordinaires du monde.

## Gates V3

| Gate | Après | Critère |
| --- | --- | --- |
| `R` — No Parallel Physical Engines | `CIV-19` | Actions actor-neutral/adapters, vrais items, break/drop, placement et navigation possèdent une frontière de réutilisation démontrée. |
| `B` — Self-Sustaining Local Society | `CIV-25` | Teaching, subsistances plurielles, surplus, livestock et travail durable forment une société locale viable. |
| `C` — Local Material Economy | `CIV-31` | Rights, production, échange, dette, marchés physiques et monnaie optionnelle conservent les biens réels. |
| `D` — Durable Scaled Society | `CIV-34` | Persistence réconciliée, plusieurs settlements, fidelity tiers et évaluation optionnelle sont bornés et observables. |
| `E` — Generational Continuity | `CIV-39` | Santé, développement, enfance, maisons et succession produisent une continuité multi-générationnelle. |
| `F` — Cumulative Culture | `CIV-47` | Savoir, oralité, langage, écriture, livres, archives et cultures peuvent s’accumuler, diverger et disparaître. |
| `G` — Medieval Institutions | `CIV-56` | Organisations, guildes, territoire, loi, religion, diplomatie, conflit et polities émergent de causes simulées. |
| `H` — Alternative Renaissance | `CIV-58` | Innovation cumulative et infrastructures Pebble réelles sont socialement situées et matériellement maintenues. |

Une gate n’est ouverte que par ses preuves ; sa présence dans la roadmap ne
signifie pas qu’elle est déjà acquise.

Gate R est acquise depuis la validation senior de `CIV-19`. Gate B a été
évaluée après `CIV-25` et reste non acquise avec un résultat candidate `FAIL`.
Les gates C à H restent non acquises tant que leurs critères respectifs ne sont
pas prouvés.

## Cible produit conservée

La cible reste une civilisation médiévale alternative, préindustrielle,
autonome, persistante et multi-générationnelle. Des individus limités doivent
survivre, apprendre, transmettre, produire, échanger, former ou quitter des
foyers et organisations, créer des cultures, institutions, religions et
polities, innover, entrer en conflit ou négocier, vieillir et mourir sans forme
sociale imposée.

Le succès n’est ni une étiquette de « royaume », ni un récit plausible généré
de l’extérieur. C’est une histoire rejouable dont les croyances, économies,
alliances, héritages, guerres, technologies et effondrements se reconstruisent
depuis des observations locales, des décisions, des transactions matérielles
et une causalité persistante. Le joueur peut l’observer, l’accélérer,
l’influencer comme un dieu puis s’y incarner, sans que son absence empêche le
monde de vivre.

## Invariants de livraison

- Simuler les causes, jamais imposer le résultat social.
- Aucune omniscience collective ni communication gratuite à distance.
- Toute verticale matérielle étend une équation de conservation réconciliable.
- Toute collection live est bornée ou possède une politique de persistence et
  de compaction explicite.
- Toute mutation World est prévalidée, bornée, transactionnelle, vérifiée et
  rollbackée de façon vérifiable en cas d’échec.
- Toute feature expérimentale reste désactivée par défaut.
- Une verticale livre normalement contrat, implémentation, preuves focalisées,
  une seule full gate finale justifiée et documentation en 1 à 3 commits
  reviewables.
- `CIV-15` à `CIV-19` ont acquis les frontières actor-neutral, custody,
  harvest, construction, navigation et embodiment ; Gate R est acquise.
  `CIV-20` à `CIV-25` sont acquis dans leurs contrats bornés. L'évaluation
  candidate Gate B est `FAIL`. `GATE-B-CORR-01` et `GATE-B-CORR-02` sont
  publiés et ont remédié nourriture/survie, orchestration autonome, slice
  passive, réserve livestock, remplacement de crise et care physique. La
  re-evaluation #2 a échoué sur l'initiation Teaching intégrée avant campagne
  5/3/2. CORR-03 remédie désormais ce blocker localement sans acquérir Gate B ;
  restart composite, campagne systémique et re-evaluation #3 restent non
  prouvés. Gate B demeure non acquise et `CIV-26` reste planifié.
