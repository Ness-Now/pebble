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

`CIV-00` à `CIV-14` sont terminés et acquis dans leurs contrats bornés. La
phase canonique actuelle est :

`CIV-15 — Actor-Neutral Physical Action Gateway V1`.

Les noms `NEXT-1` et `NEXT-2` sont uniquement des alias historiques :

- `NEXT-1` désignait la verticale de compétences maintenant canonisée comme
  `CIV-13` et terminée ;
- `NEXT-2` désignait une proposition d’enseignement maintenant planifiée comme
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
- NaturalResource V1 et Construction V1 comme preuves transactionnelles avec
  prévalidation, vérification, publication et rollback.

Ces preuves ne constituent pas encore une agriculture réelle, une économie
d’items complète, une grande population, un cycle de vie complet, un système
de connaissance, une culture, une institution ou une civilisation médiévale.

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
| `LIVE_BRIDGE` | contrôleur, sensors, adapters, coordination de mouvement et executors de `Pebble` | Conserver comme frontière actor/World ; ils n’acquièrent aucune cognition parallèle. |
| `COARSE_DORMANT` | `AgentLocalEcologyState`, `AgentCampStock`, catégories `foodRaw`/`wood`/`stone`, `AgentBoundedRoutePlanner` | Conserver pour headless, coarse, dormant ou waypoints uniquement avec conservation et parité explicites. |
| `TO_CONVERGE` | NaturalResource V1, Construction V1, projection inventory/stock live, frontière navigation physique live, frontière persistence World/civilisation | Migrer incrémentalement vers les mécaniques PebbleCore après preuve de remplacement et rollback. |
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
| `CIV-15` | current | Actor-Neutral Physical Action Gateway V1 |
| `CIV-16` | planned | Real Material Identity and Inventory Bridge V1 |
| `CIV-17` | planned | Harvest and Resource Convergence V1 |
| `CIV-18` | planned | Construction and Placement Convergence V1 |
| `CIV-19` | planned | Navigation and Embodiment Boundary Consolidation V1 |

`CIV-15` à `CIV-19` doivent fermer la frontière entre intention
civilisationnelle et action physique réelle sans réécrire PebbleCore. Gate R
est requise avant les nouvelles verticales physiques de subsistance.

### Société locale autonome — Gate B

| Phase | Statut | Verticale |
| --- | --- | --- |
| `CIV-20` | planned | Demonstration, Teaching and Apprenticeship V1 |
| `CIV-21` | planned | Ecological Observation and Civil Calendar V1 |
| `CIV-22` | planned | Agriculture and Managed Surplus V1 |
| `CIV-23` | planned | Fishing, Hunting and Wild Subsistence V1 |
| `CIV-24` | planned | Livestock and Animal Capital V1 |
| `CIV-25` | planned | Durable Work Commitments and Emergent Professions V1 |

Ces phases doivent produire plusieurs stratégies matérielles viables et une
spécialisation dérivée de la pratique, de l’enseignement et des besoins, sans
classe professionnelle imposée.

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
- `CIV-15` ouvre uniquement les seams actor-neutral et la gateway bornée ; il
  ne commence ni l’inventaire CIV-16, ni les convergences CIV-17/CIV-18.
