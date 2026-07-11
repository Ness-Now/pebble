# Phase A0 — Shared Agent Runtime Audit & Extraction Plan

## 1. Titre et métadonnées

| Champ | Valeur |
| --- | --- |
| Projet | PebbleLab / SIMU Minecraft / Pebble |
| Phase | A0 — Shared Agent Runtime Audit & Extraction Plan |
| Nature | Audit documentaire uniquement |
| Date de l'audit | 11 juillet 2026 |
| Dépôt local | `/Users/nessnow/Dev/pebble-lab` |
| Dépôt GitHub | `Ness-Now/pebble` |
| Branche | `lab/pebblelab-v1` |
| HEAD audité | `be6f0894e90e319f10d20aef34052cc1a9f8dc23` |
| Commit de départ | `Add PebbleLab agents_basic cognitive loop fixture smoke` |
| Plan directeur | `pebblelab_plan_directeur_technique_3d_live_2026-07-11.md`, pièce jointe locale lue hors dépôt |
| Changement runtime | Aucun |
| Module `PebbleAgents` créé | Non |

Ce document décrit l'état réel au commit audité et un plan d'extraction. Les noms
`Agent*` proposés pour les futures sous-phases ne sont pas des symboles existants,
sauf mention explicite. Le code local et l'état Git constaté priment sur le plan
directeur.

## 2. Résumé exécutif

Le verrou architectural est confirmé. `Pebble` et `PebbleLab` sont deux targets
exécutables frères qui dépendent de `PebbleCore`; `Pebble` ne dépend pas de
`PebbleLab`, et un exécutable n'est pas une bibliothèque de runtime à importer.
La cognition réelle de `agents_basic` est donc enfermée dans l'exécutable
`PebbleLab` (`Package.swift:12-47`).

Le chemin réel de `agents_basic` n'est pas le smoke
`agents_basic_cognitive_loop_fixture_smoke`. Le premier est une boucle Worldful
réelle, exécutée dans `main.swift`; le second est un fixture Worldless qui ne
modifie que `LabAgent.currentGoal`, avec perception et mémoire contrôlées, action
dry-run et aucun mouvement (`LabAgentsBasicCognitiveLoop.makeAgentsBasicCognitiveLoopRun`,
`Sources/PebbleLab/LabAgentsBasicCognitiveLoop.swift:401`).

La boucle réelle appelle, dans cet ordre, pour chaque agent et chaque tick :
`tick`, `observe`, `observeNearbyAgents`, `selectGoal`, `decideAction`,
`applyLastActionEffect`, puis `applyAbstractMovement`
(`tickAndEncodeAgent`, `Sources/PebbleLab/main.swift:558`). Elle produit de vraies
mutations des besoins, de l'état, de la perception, du goal, de l'action, de
l'effet, de la position abstraite, de la mémoire et des compteurs.

Le modèle est compact mais fortement agrégé dans `LabAgent.swift`. Sa seule
dépendance directe à `PebbleCore` est la méthode `observe(world:tick:)`, via
`World`, `CHUNK_W` et `floorDiv`. La préparation de `agents_basic` dépend en plus
de la génération de chunks et des registries. La décision d'action, les DTOs de
position/goal/action, les besoins et la mémoire abstraite ne dépendent pas de
`PebbleCore`.

La plus petite tranche verticale recommandée pour A1 est la décision d'action
pure et ses DTOs : futurs `AgentPosition`, `AgentGoalKind`, `AgentGoal`,
`AgentAction`, `AgentActionDecisionInput` et `AgentActionDecider`, avec des
typealiases temporaires `LabAgentPosition`, `LabGoalKind`, `LabGoal` et
`LabAgentAction`. `LabAgent.decideAction(tick:)` resterait un wrapper mutant dans
PebbleLab, mais déléguerait réellement le choix de l'action au nouveau module.
Cette tranche est appelée 240 fois dans la baseline de 3 agents × 80 ticks, est
directement réutilisable par la Phase B, n'ouvre ni World ni movement stack, et
ne déplace pas tout `LabAgent`.

Recommandation : lancer A1 selon ce découpage corrigé et non implémenter d'un
bloc la liste de fichiers conceptuels du plan directeur. Risque A1 : **moyen**,
principalement à cause de la visibilité Swift et de l'usage transversal des
types `LabGoalKind`/`LabGoal` dans les anciens fixtures.

## 3. État Git vérifié

Vérification initiale obligatoire :

```text
pwd                         /Users/nessnow/Dev/pebble-lab
branche                     lab/pebblelab-v1
HEAD local                  be6f0894e90e319f10d20aef34052cc1a9f8dc23
HEAD distant après fetch    be6f0894e90e319f10d20aef34052cc1a9f8dc23
commit local/distant        be6f089 Add PebbleLab agents_basic cognitive loop fixture smoke
working tree initial        propre
```

`git fetch origin` a été exécuté. Aucun pull, stash, reset, rebase, changement de
branche ou push n'a été effectué.

## 4. Documents et fichiers lus

### 4.1 Document stratégique

Le plan directeur a été lu intégralement (2 864 lignes) depuis la pièce jointe
locale hors dépôt :

```text
/Users/nessnow/Pebble-perso/REPRISE AVEC 5.6 SOL/
pebblelab_plan_directeur_technique_3d_live_2026-07-11.md
```

Le chemin annoncé `/Users/nessnow/Dev/pebblelab-context/...` n'existait pas;
le fichier joint portant exactement le nom attendu était accessible au chemin
ci-dessus. Il n'a pas été copié dans le dépôt.

Décisions du plan qui contraignent directement A :

- créer ultérieurement un runtime partagé `PebbleAgents`;
- maintenir une seule source de vérité cognitive;
- interdire toute duplication entre Pebble et PebbleLab;
- extraire progressivement, avec wrappers ou typealiases temporaires;
- préserver le comportement et les preuves de `agents_basic`;
- fournir des snapshots read-only réutilisables par la future app;
- passer assez rapidement à la Phase B après la preuve de parité;
- ne pas ouvrir World, renderer, HUD, commandes ni movement live pendant A.

### 4.2 Package

- `Package.swift`, lu intégralement;
- description SwiftPM JSON produite par `swift package describe --type json`;
- inventaire `find Sources -maxdepth 2 -type f | sort`;
- recherche du dossier `Tests` : dossier absent.

### 4.3 Runtime `agents_basic` et `LabAgent`

- `Sources/PebbleLab/LabAgent.swift`, intégral;
- `Sources/PebbleLab/LabScenarios.swift`, intégral;
- `Sources/PebbleLab/LabOptions.swift`, intégral;
- `Sources/PebbleLab/main.swift`, routage, helpers d'événements, boucle,
  snapshots, métriques et sortie;
- `Sources/PebbleLab/LabOutput.swift`, types et portions utilisés;
- `Sources/PebbleLab/LabEvents.swift`, `RunEvent` et encodage;
- inventaire complet des fichiers de premier niveau de `Sources/PebbleLab`.

### 4.4 Cognition et preuves de boundary

- `Sources/PebbleLab/LabAgentsBasicCognitiveLoop.swift`, types, run, rapports,
  invariants, digest, métriques et événements;
- `Sources/PebbleLab/LabAgentsBasicGoalApply.swift`, types et chemin d'apply;
- `Sources/PebbleLab/LabAgentsBasicGoalIntegration.swift`, types et décisions;
- déclarations et appels ciblés dans `LabBehaviorLoop.swift`,
  `LabMemoryUpdate.swift`, `LabMemoryRetrieval.swift`,
  `LabGoalSelectionMemory.swift`, `LabBehaviorLoopMemoryGoalBridge.swift` et
  `LabCognitiveLoopIntegration.swift`.

### 4.5 PebbleCore

- définitions ciblées de `World` dans `World/GameWorld.swift`;
- `CHUNK_W`, `floorDiv` et `Chunk` dans `World/Chunk.swift`;
- `registerAllBlocks` dans `World/BlockRegistry.swift`;
- `registerAllBiomes` dans `Gen/Biomes.swift`;
- `generateChunk` dans `Gen/Generator.swift`;
- recherches ciblées sur les méthodes World réellement appelées.

### 4.6 Documents historiques utiles

- `docs/pebblelab/PHASE_5_0A_COGNITIVE_AGENT_STATE_AUDIT.md`;
- `docs/pebblelab/PHASE_5_14D_ROADMAP_SCENARIO_ROUTER_DEBT_AUDIT.md`;
- `docs/pebblelab/PHASE_5_15A_AGENTS_BASIC_COGNITIVE_LOOP_SMOKE_PLAN.md`.

Les recherches `rg` ont également couvert toutes les références à `LabAgent`,
aux méthodes par tick, aux constructions d'agents, aux imports et aux symboles
de snapshots/goals/needs.

## 5. Graphe réel des targets

### 5.1 Manifeste

`Package.swift` utilise `swift-tools-version: 6.0`, cible macOS 14 et force le
mode de langage Swift 5 pour les quatre targets. Aucune dépendance externe
n'est déclarée.

| Product SwiftPM réel | Target | Type | Chemin | Dépendances | Swift |
| --- | --- | --- | --- | --- | --- |
| implicite `Pebble` | `Pebble` | executable | `Sources/Pebble` | `PebbleCore` | 5 |
| implicite `PebbleLab` | `PebbleLab` | executable | `Sources/PebbleLab` | `PebbleCore` | 5 |
| implicite `pebsmoke` | `pebsmoke` | executable | `Sources/pebsmoke` | `PebbleCore` | 5 |
| aucun product library explicite | `PebbleCore` | library target | `Sources/PebbleCore` | aucune target | 5 |

Le manifeste ne contient pas de tableau `products`; SwiftPM expose trois
products exécutables implicites. Le target library `PebbleCore` est utilisable
à l'intérieur du package. `swift package describe` compte 16 sources pour
Pebble, 49 pour PebbleLab, 66 pour PebbleCore et 1 pour pebsmoke.

```text
PebbleCore
├── Pebble (AppKit, Metal, MetalKit, QuartzCore, AVFoundation)
├── PebbleLab (headless, Foundation)
└── pebsmoke (headless)
```

### 5.2 Pourquoi Pebble ne peut pas importer PebbleLab

1. `Pebble` ne déclare que `PebbleCore` comme dépendance
   (`Package.swift:20-34`).
2. `PebbleLab` est un `.executableTarget`, pas un target library
   (`Package.swift:43-47`).
3. Une dépendance inverse `Pebble -> PebbleLab` serait contraire à la frontière
   UI/runtime et ne fournirait pas une bibliothèque partagée propre.
4. Déplacer la cognition dans PebbleCore polluerait le moteur et couplerait trop
   tôt la cognition au World.

### 5.3 Emplacement du futur module

Le futur target interne doit être un frère de PebbleCore :

```text
PebbleCore
PebbleAgents     (target library interne, Swift 5, initialement sans PebbleCore)
PebbleLab  -> PebbleCore + PebbleAgents
Pebble     -> PebbleCore                 (A1-A3)
Pebble     -> PebbleCore + PebbleAgents  (Phase B)
pebsmoke   -> PebbleCore
```

A1 n'a pas besoin d'ajouter un product library public. Une dépendance de target
interne suffit. Ajouter un tableau `products` explicite imposerait de redéclarer
ou de vérifier les products exécutables implicites et élargirait inutilement le
diff.

## 6. Call graph de `agents_basic`

### 6.1 Sélection, préparation et construction

| Étape | Symbole exact | Fichier | Entrées | Sorties / mutations | Appels |
| --- | --- | --- | --- | --- | --- |
| CLI | `parseArguments(_:)` | `LabOptions.swift:44` | `CommandLine.arguments` | `Options` | `fail`, conversions Swift |
| Validation | `validateScenario(_:)` | `LabScenarios.swift:33` | `"agents_basic"` | valide ou termine | `supportedScenarios.contains` |
| Router | top-level `main.swift` | `main.swift:4` | `Options` | crée `World` sauf fixtures Worldless | `World(dim:seed:)` |
| Préparation | `prepareScenario(_:world:)` | `LabScenarios.swift:39` | options + World | `ScenarioResult` | registries, génération, adoption chunks |
| Branche scenario | `scenario == "agents_basic"` | `LabScenarios.swift:116` | count, seed, World | `[LabAgent]` | `makeBasicAgents` |
| Placement | `makeBasicAgents(count:seed:world:)` | `LabScenarios.swift:208` | count/seed/World | grille stable d'agents | `makeLabAgent`, inventaire |
| Construction | `makeLabAgent(id:x:z:world:)` | `LabScenarios.swift:240` | id/x/z/World | `LabAgent` | `spawnYAt`, init |
| Spawn Y | `spawnYAt(x:z:world:)` | `LabScenarios.swift:245` | colonne World | Y libre | `heightAt`, `getBlock` |

Pour `agents_basic`, le chunk radius implicite vaut 1 si l'option n'est pas
fournie (`LabScenarios.swift:49`), donc neuf chunks sont générés et adoptés.
`registerAllBlocks()` et `registerAllBiomes()` sont appelés avant génération.
`makeBasicAgents` place les agents sur une grille de pas 4, décalée par
`seed % count`, assigne curiosité 0,9 aux indices multiples de 3 et un inventaire
initial aux agents 0 et 1.

### 6.2 Initialisation observable conditionnelle

Si et seulement si `--out` est fourni, `main.swift:798-829` exécute avant le
premier tick, dans l'ordre stable du tableau :

```text
encodeSpawnAndInitialObservation
→ remember(type: "spawned", tick: 0)
→ observe(world:, tick: 0)
→ observeNearbyAgents(snapshot initial)
→ selectGoal(tick: 0)
→ encode spawn/home/inventory/observation/nearby/goal/memory
```

Cette dépendance du comportement initial à la présence de `--out` est une
divergence runtime/infrastructure réelle : sans output, ces appels initiaux ne
sont pas exécutés. A1 ne doit pas la corriger, car cela changerait le runtime;
A2 devra la supprimer sous preuve de parité définie explicitement.

### 6.3 Boucle par tick

Le router normal est la branche `else` de `main.swift:923`. Pour chacun des 80
ticks de baseline :

```text
World.tick()
→ ticksCompleted += 1
→ let allAgents = labAgents             // snapshot de début de tick
→ pour chaque index dans l'ordre du tableau
   → tickAndEncodeAgent                 // si --out
      → LabAgent.tick
      → LabAgent.observe(world:tick:)
      → LabAgent.observeNearbyAgents(allAgents)
      → LabAgent.selectGoal(tick:)
      → LabAgent.decideAction(tick:)
      → LabAgent.applyLastActionEffect(tick:)
      → LabAgent.applyAbstractMovement(tick:)
      → encode événements et nouvelles mémoires
   → mêmes sept appels inline            // sans --out
→ LabAgentPhysicalBridge.tick/sync       // bridge vide pour agents_basic
→ LabCoreEntityBridge.tick/sync          // bridge vide pour agents_basic
→ éventuel événement world_tick
```

L'ordre multi-agent est l'ordre du tableau `agent_0`, `agent_1`, `agent_2`.
Toutefois, `observeNearbyAgents` reçoit la copie `allAgents` prise avant les
mutations du tick : tous les agents observent donc les positions de début du
tick, ce qui est déterministe et évite un avantage d'ordre pour la perception.

### 6.4 Responsabilités et mutations par appel

| Symbole | Responsabilité | Entrées | Sorties | Mutations | Dépendances |
| --- | --- | --- | --- | --- | --- |
| `World.tick()` | avancer la simulation Core | état World | `world.time` | World interne | PebbleCore |
| `LabAgent.tick()` | vieillissement minimal | agent | aucune | hunger +0,01; fatigue +0,005; state idle; ticksAlive +1 | types locaux |
| `observe(world:tick:)` | perception locale World | World, position, tick | `LabAgentObservation` | observation, observationCount, mémoire | World, `floorDiv`, `CHUNK_W` |
| `observeNearbyAgents` | perception sociale géométrique | snapshot agents, rayon 8 | nearby list | nearbyAgents, nearbyObservationCount | position locale |
| `selectGoal` | priorité déterministe | health/fear/needs/nearby | `LabGoalChange?` | selection count, goal et change count si kind change | goal DTOs |
| `decideAction` | mapping goal → action | goal/id/tick/home/position | `LabAgentAction` | lastAction, actionCount, mémoire | helpers purs |
| `applyLastActionEffect` | appliquer effet abstrait | lastAction, goal | `LabAgentActionEffect` | needs/fear/state/effect/count/mémoire | Foundation `min/max` |
| `applyAbstractMovement` | déplacement abstrait direct | lastAction, home/position | `LabAgentMovement?` | position, mouvement, compteurs, mémoire | aucun World/collision |
| `tickAndEncodeAgent` | orchestration + événements | agent inout, snapshot agents | NDJSON | toutes ci-dessus + compteurs d'événements | `RunEvent` |

`applyAbstractMovement` n'est pas le movement stack avancé de Phase 4. Il
applique directement un delta abstrait sans collision, arbitrage, World ou
feedback. Le movement stack avancé reste fermé en Phase A.

### 6.5 Outputs, métriques et invariants

Pour le scénario runtime `agents_basic`, le writer générique produit exactement :

- `config.json` (`RunConfig`);
- `world_snapshot.json` (`WorldSnapshot`);
- `agent_snapshot.json` (`AgentSnapshot` contenant directement `[LabAgent]`);
- `metrics.json` (`RunMetrics`, mega-struct monolithique);
- `events.ndjson` (`RunEvent`, mega-struct monolithique).

Il ne produit aucun report dédié, digest, invariant report ni résumé Markdown.
Le succès générique vient de `makeSuccessCriteria()` puis de la chaîne
`runSuccess` (`main.swift:1015`, `main.swift:4553`) : ticks atteints, nombre
d'agents conservé et au moins un tick agent, plus les gates optionnelles des
autres familles de scénarios.

## 7. Inventaire des types et fonctions

### 7.1 Types de domaine et runtime directement nécessaires

| Type exact | Propriétaire actuel | Catégorie | Champs pertinents / conformances | Mutation | PebbleCore | Usage | Extraction |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `LabAgent` | `LabAgent.swift:4` | runtime agrégé | 28 champs stockés; `Encodable`; encode custom | fortement mutable | oui via `observe` | nombreux scénarios | fractionner A1/A2, pas déplacer entier |
| `LabAgentPosition` | `LabAgent.swift:440` | domaine | x/y/z `Int`; `Codable, Equatable` | valeur immuable, champ agent mutable | non | agents, physical, movement, terrain | A1 → `AgentPosition` + typealias |
| `LabAgentNeeds` | `LabAgent.swift:446` | domaine | hunger/fatigue/curiosity/safety; `Encodable` | champs mutables | non | runtime et fixtures | A2 |
| `LabGoalKind` | `LabAgent.swift:529` | domaine | 5 cases; `String, Codable, Equatable` | immuable | non | très transversal cognition | A1 → `AgentGoalKind` + typealias |
| `LabGoal` | `LabAgent.swift:537` | domaine | kind/reason/startedAtTick/urgency; `Codable, Equatable` | valeur immuable, currentGoal mutable | non | runtime + fixtures | A1 → `AgentGoal` + typealias |
| `LabGoalChange` | `LabAgent.swift:544` | runtime | from/to/goal; aucune conformance | immuable | non | runtime events uniquement | A2 ou rester adapter |
| `LabMemoryEntry` | `LabAgent.swift:608` | domaine | tick/type/summary/importance; `Encodable` | valeur immuable, tableau append-only non borné | non | runtime + memory fixtures | A2, avec politique explicite |
| `LabAgentObservation` | `LabAgent.swift:508` | World adapter DTO | position/chunk/surface/blocks; `Encodable` | immuable, option agent mutable | oui sémantiquement | runtime Worldful | garder adapter A; normaliser post-A/C |
| `LabNearbyAgentObservation` | `LabAgent.swift:521` | perception domaine | id/deltas/distance; `Codable, Equatable` | immuable, liste agent mutable | non | runtime + behavior fixture | A2 |
| `LabAgentAction` | `LabAgent.swift:550` | domaine/runtime | name/reason/tick/deltas; `Encodable` | valeur immuable, lastAction mutable | non | runtime et movement fixtures | A1 → `AgentAction` + typealias |
| `LabAgentActionEffect` | `LabAgent.swift:568` | résultat runtime | before/after besoins/fear/state; `Encodable` | immuable, last effect mutable | non | runtime/events | A2 |
| `LabAgentMovement` | `LabAgent.swift:586` | résultat mouvement abstrait | from/to/delta/distance/home; `Encodable` | immuable, position/counters mutés ailleurs | non | runtime + anciens smokes | Post-A; ne pas confondre avec stack |
| `LabInventory` | `LabAgent.swift:453` | domaine abstrait | `[String:Int]`; `Codable, Equatable` | add/remove | non | plusieurs scénarios | rester temporairement; Post-A |

### 7.2 Infrastructure du scénario et des outputs

| Type exact | Fichier | Catégorie | Rôle dans `agents_basic` | Extraction |
| --- | --- | --- | --- | --- |
| `Options` | `LabOptions.swift:3` | CLI | seed/ticks/scenario/out/count/options | jamais |
| `ScenarioResult` | `LabScenarios.swift:4` | scenario state | chunks, agents, bridges | PebbleLab |
| `AdoptedChunk` | `LabScenarios.swift:19` | World setup/report | état de chaque chunk adopté | PebbleLab |
| `RunConfig` | `LabOutput.swift:3` | output | config JSON | PebbleLab |
| `RunSuccessCriteria` | `LabOutput.swift:12` | report minimal | trois booléens génériques | PebbleLab |
| `RunMetrics` | `LabOutput.swift:55` | metrics mega-struct | agrégats de toutes familles | ne pas déplacer |
| `RunEvent` | `LabEvents.swift:3` | event mega-struct | événements NDJSON toutes familles | ne pas déplacer |
| `WorldSnapshot` | `LabOutput.swift:5271` | World report | état chunks final | PebbleLab |
| `AgentSnapshot` | `LabOutput.swift:5300` | output wrapper | scenario/seed/ticks/`[LabAgent]` | garder pour compatibilité; remplacer par adapter A3 |

### 7.3 Snapshot réutilisable : état réel

Il n'existe pas de snapshot partagé pour l'app. `AgentSnapshot` est un wrapper
PebbleLab qui encode directement les agents mutables. L'encodage custom de
`LabAgent` expose un sous-ensemble et des champs dérivés, dont seulement les 10
dernières mémoires. Le champ `observationCount`, bien que présent sur
`LabAgent`, n'est pas dans `CodingKeys`; il apparaît dans les métriques mais pas
dans `agent_snapshot.json`. Les snapshots spécialisés 5.15 sont des DTOs de
fixture, pas des snapshots runtime généraux.

## 8. Dépendances de `LabAgent`

### 8.1 Champs exhaustifs

`LabAgent` possède : `id`, `type`, `state`, `position`, `needs`, `health`,
`fear`, `homePosition`, `inventory`, `observation`, `nearbyAgents`,
`currentGoal`, `lastAction`, `lastActionEffect`, `lastMovement`, `memory`,
`tickCreated`, `ticksAlive`, `observationCount`, `nearbyObservationCount`,
`goalSelectionCount`, `goalChangeCount`, `actionCount`, `actionEffectCount`,
`movementCount`, `totalManhattanDistanceMoved`, `returnHomeMoveCount` et
`totalDistanceReducedTowardHome` (`LabAgent.swift:5-32`).

Il n'a aucun nested type. Il a un initializer unique
`init(id:x:y:z:)` (`LabAgent.swift:41`). Il conforme uniquement à `Encodable`
et fournit `CodingKeys`/`encode(to:)` custom.

### 8.2 Matrice des symboles

| Symbole | Appelé par `agents_basic` | Mutation | Dépendance PebbleCore | Candidat A1 | Candidat ultérieur | Doit rester |
| --- | ---: | --- | ---: | ---: | ---: | ---: |
| `init(id:x:y:z:)` | oui | initialise | non | non | A2 | wrapper temporaire |
| `isAlive` | oui, métriques | pure | non | non | snapshot A3 | non |
| `distanceFromHome` | oui | pure | non | indirectement décision | A2 | non |
| `tick()` | oui/tick | needs/state/counter | non | non | A2 | wrapper temporaire |
| `observe(world:tick:)` | oui + tick 0 avec output | observation/counter/memory | **oui** | non | adapter Phase C | PebbleLab en A |
| `observeNearbyAgents` | oui | nearby/counter | non | non | A2/A3 | wrapper temporaire |
| `selectGoal(tick:)` | oui | goal/counters | non | non | A2 | wrapper temporaire |
| `decideAction(tick:)` | oui | action/counter/memory | non | **wrapper délégué** | A2 | wrapper A1 |
| `applyLastActionEffect(tick:)` | oui | needs/fear/state/effect/memory | non | non | A2 | wrapper temporaire |
| `applyAbstractMovement(tick:)` | oui | position/movement/counters/memory | non | non | Post-A/D | PebbleLab pendant A |
| `movementStepTowardHome()` | via décision | pure | non | oui, logique partagée | A1 | wrapper possible |
| `remember(...)` | oui directement/indirectement | append non borné | non | non | A2 | wrapper temporaire |
| `encode(to:)` | oui, snapshot | pure/output | non | non | adapter A3 | PebbleLab |
| `movementDirectionForAgent(id:tick:)` | via explore | pure | non | **oui** | — | wrapper possible |
| `LabInventory.add/remove/has/count` | setup/metrics | inventaire | non | non | Post-A | temporairement PebbleLab |

### 8.3 Fonctions non appelées par le runtime `agents_basic`

Toutes les méthodes de `LabAgent` sont utilisées directement ou transitivement
par `agents_basic`; seules les opérations `LabInventory.remove` et `has` ne le
sont pas. En revanche, les grands pipelines des fichiers `LabMemoryRetrieval`,
`LabGoalSelectionMemory`, `LabBehaviorLoopMemoryGoalBridge` et
`LabCognitiveLoopIntegration` ne sont pas appelés par le runtime `agents_basic`.
Ils appartiennent à des scénarios fixture séparés.

### 8.4 Couplages implicites

- scénario : `makeBasicAgents` modifie curiosité et inventaire selon l'index;
- output : `LabAgent` possède son schéma JSON lui-même;
- reports : les snapshots 5.14/5.15 lisent directement tous ses champs;
- World : `observe` combine lecture World et mutation de mémoire;
- movement : `decideAction` produit directement `move_abstract`, et
  `applyAbstractMovement` l'applique sans validation;
- déterminisme : direction explore = `(suffix numérique de id + tick) % 4`;
- infrastructure : la présence de `--out` active une initialisation cognitive
  supplémentaire au tick 0.

## 9. Dépendances vers PebbleCore

### 9.1 Dépendances directes du chemin

| Classe | Symboles | Fichiers d'appel | Décision A |
| --- | --- | --- | --- |
| Types légers | `CHUNK_W`, `floorDiv` | `LabAgent.observe` | garder dans adapter PebbleLab; ne justifie pas une dépendance du kernel |
| World read-only | `World`, `isChunkReady`, `surfaceY`, `heightAt`, `getBlock` | `LabAgent.observe`, `spawnYAt` | adapter plus tard, Phase C |
| World setup | `World(dim:seed:)`, `setChunk`, `light.initChunkLight` | main/scenarios | PebbleLab uniquement |
| Génération | `generateChunk`, `Chunk`, `buildHeightmap`, `scanSpecials` | `prepareScenario` | PebbleLab uniquement |
| Registries | `registerAllBlocks`, `registerAllBiomes` | `prepareScenario` | ne jamais déplacer dans A1 |
| Tick World | `World.tick` | `main.swift` | orchestration PebbleLab en A |

### 9.2 Dépendances transitives à tenir hors d'A1

1. **Types génériques légers** : aucun type Core n'est nécessaire au kernel
   cognitif minimal. Une position entière propre à PebbleAgents est préférable.
2. **World** : génération, chunks, lumière et lectures restent derrière
   PebbleLab; un adapter read-only normalisé n'arrive qu'en Phase C.
3. **Entités physiques** : `LabAgentPhysicalBridge`, `LabCoreEntityBridge` et
   `LabCoreAgentEntity` ne doivent pas entrer en A1. Leurs bridges sont vides
   mais leurs `tick/sync` génériques sont malgré tout appelés par main.
4. **Movement stack** : tous les intents, feedbacks, arbitres, planning,
   collision et route following restent fermés. Le déplacement abstrait legacy
   reste temporairement dans PebbleLab.
5. **Save/load et registries** : aucun save/load n'est utilisé par
   `agents_basic`; les registries ne servent qu'au setup World et ne doivent
   jamais migrer vers PebbleAgents en A1.

### 9.3 PebbleAgents doit-il dépendre de PebbleCore dès A1 ?

**Non.** Il peut et devrait commencer sans PebbleCore.

Avantages :

- empêche que `World` fuite dans le kernel;
- garantit l'usage futur par Pebble et les tests synthétiques;
- réduit la surface publique et le temps de compilation;
- force des DTOs explicites et déterministes;
- la tranche A1 choisie n'utilise aucun symbole PebbleCore.

Inconvénients :

- nécessite des DTOs `AgentPosition` distincts des types Core;
- impose plus tard un mapping dans les adapters;
- certains helpers simples (`floorDiv`) ne sont pas réutilisés directement.

Ces coûts sont faibles et souhaitables : `floorDiv` appartient à la perception
World, pas à la cognition. Une dépendance PebbleCore pourra être réévaluée pour
un adapter séparé, jamais introduite implicitement dans le kernel.

## 10. Séparation runtime / outputs / reports

| Élément | Classement | Justification |
| --- | --- | --- |
| position/goal/action purs | `EXTRACT_TO_PEBBLEAGENTS` | domaine partagé, aucun World |
| décision goal → action | `EXTRACT_TO_PEBBLEAGENTS` | tranche cognitive réelle et pure |
| needs tick/goal selection/effects | `EXTRACT_TO_PEBBLEAGENTS` en A2 | kernel déterministe après A1 |
| mémoire abstraite et policy de borne | `EXTRACT_TO_PEBBLEAGENTS` en A2 | état cognitif, actuellement non borné |
| session multi-agent et snapshot partagé | `EXTRACT_TO_PEBBLEAGENTS` en A3 | source de vérité et interface Phase B |
| `LabAgent.observe(world:)` | `ADAPT_LATER` | mélange World et runtime; Phase C |
| `LabAgentObservation` actuel | `ADAPT_LATER` | contient coordonnées chunk et block IDs Core |
| `applyAbstractMovement` legacy | `KEEP_IN_PEBBLELAB` pendant A | application directe, doit attendre Phase D |
| `ScenarioResult`, router, `Options` | `KEEP_IN_PEBBLELAB` | orchestration/CLI |
| `LabOutput`, `RunMetrics` | `DO_NOT_MOVE` | schéma monolithique historique |
| `LabEvents`, `RunEvent` | `DO_NOT_MOVE` | mega-struct inter-scénarios |
| reports/invariants/digests 5.x | `KEEP_IN_PEBBLELAB` | preuves de fixtures, pas runtime app |
| filesystem et `writeJSON` | `DO_NOT_MOVE` | effet de bord de laboratoire |
| summaries Markdown | `DO_NOT_MOVE` | présentation fixture |
| `AgentSnapshot` actuel | `KEEP_IN_PEBBLELAB` | wrapper de compatibilité, pas snapshot partagé |
| registries/génération/chunks | `DO_NOT_MOVE` | propriété PebbleCore/PebbleLab adapter |
| physical/Core entity bridges | `ADAPT_LATER` | contrôleur app Phase B/D |

Le code réel ne justifie aucune exception à la règle présumée : PebbleAgents ne
doit contenir ni CLI, filesystem, JSON report spécifique, metrics mega-struct,
event mega-struct, router ni Markdown writer.

## 11. Matrice d'extraction

| Type ou fonction | Propriétaire actuel | Dépendances | Utilisé par `agents_basic` | Destination recommandée | Sous-phase | Compatibilité | Risque / justification |
| --- | --- | --- | ---: | --- | --- | --- | --- |
| `LabAgentPosition` | LabAgent.swift | Swift | oui | PebbleAgents `AgentPosition` | A1 | typealias `LabAgentPosition` | moyen; très transversal mais schéma simple |
| `LabGoalKind` | LabAgent.swift | Swift Codable | oui | PebbleAgents `AgentGoalKind` | A1 | typealias | moyen; nombreux fixtures |
| `LabGoal` | LabAgent.swift | goal kind | oui | PebbleAgents `AgentGoal` | A1 | typealias | moyen; préserver Codable/Equatable |
| `LabAgentAction` | LabAgent.swift | Swift Encodable | oui | PebbleAgents `AgentAction` | A1 | typealias | moyen; préserver JSON exact |
| `movementDirectionForAgent` | LabAgent.swift | id/tick | oui | PebbleAgents action decider | A1 | wrapper temporaire | faible; pure |
| `movementStepTowardHome` | LabAgent | positions | seekSafety | PebbleAgents action decider | A1 | wrapper ou délégation | faible |
| corps de `decideAction` | LabAgent | goal/position/id/tick | oui | PebbleAgents `AgentActionDecider` | A1 | méthode Lab wrapper | moyen; tranche centrale |
| mutations actionCount/memory de `decideAction` | LabAgent | mémoire/counters | oui | remain temporarily in place | A1 | wrapper identique | faible; évite migration large |
| `LabAgentNeeds` + `tick` | LabAgent | Swift | oui | PebbleAgents | A2 | typealias/wrapper | moyen; flottants exacts |
| `selectGoal` | LabAgent | needs/fear/nearby | oui | PebbleAgents kernel | A2 | wrapper et résultats compatibles | élevé; ordre priorités/digests |
| `LabNearbyAgentObservation` | LabAgent | positions | oui | PebbleAgents perception DTO | A2 | typealias | moyen |
| `LabMemoryEntry`/`remember` | LabAgent | tableau | oui | PebbleAgents memory | A2 | policy legacy explicite | élevé; non borné actuellement |
| `applyLastActionEffect` | LabAgent | needs/action/goal | oui | PebbleAgents kernel | A2 | wrapper | élevé; mutations flottantes |
| `LabGoalChange` | LabAgent | goals | oui | PebbleAgents ou adapter | A2 | typealias/adaptation | faible |
| `LabAgentObservation` | LabAgent | World/block IDs | oui | remain temporarily in place | Post-A/C | adapter → perception normalisée | élevé; World leak |
| `observe(world:)` | LabAgent | PebbleCore World | oui | PebbleLab adapter | Post-A/C | injecter DTO | élevé |
| `LabAgentMovement` | LabAgent | action/position | oui | remain temporarily in place | Post-A/D | ancien output | élevé; mouvement legacy |
| `applyAbstractMovement` | LabAgent | action/position | oui | PebbleLab puis adapter app | Post-A/D | résultat inchangé en A | élevé |
| `LabInventory` | LabAgent | dictionnaire | setup/metrics | remain temporarily in place | Post-A | inclure snapshot seulement | faible en A |
| `LabAgent` agrégé | LabAgent.swift | tous les types + World | oui | façade PebbleLab puis état partagé | A2/A3 progressif | wrappers | élevé si déplacé d'un bloc |
| session tick stable | main.swift | World/output/bridges | oui | PebbleAgents pour orchestration cognitive seule | A3 | adapters World/output | élevé; séparer effets |
| snapshot runtime read-only | inexistant | état partagé | non (à créer) | PebbleAgents | A3 | writer ancien inchangé | moyen; API Phase B |
| `AgentSnapshot` actuel | LabOutput | `[LabAgent]` | output | PebbleLab | Never move | adapter depuis snapshots A3 | faible |
| `RunMetrics` | LabOutput | tous scénarios | oui | PebbleLab | Never move | mêmes clés/valeurs | élevé si déplacé |
| `RunEvent`/encodeurs | LabEvents/main | tous scénarios | oui | PebbleLab | Never move | mêmes lignes NDJSON | élevé |
| `Options`/router | Options/main | CLI | oui | PebbleLab | Never move | aucun refactor A | élevé inutile |
| World/génération/registries | PebbleCore + scenarios | Core | oui setup | PebbleCore/PebbleLab | Never move | adapter | critique |
| physical bridges | PebbleLab/PebbleCore | Entity/World | no-op exécuté | Pebble application adapter | Post-A | aucun changement A | élevé |
| movement stack Phase 4 | PebbleLab | World/physical/planning | non | remain temporarily in place | Post-A/D | fermé | élevé |

## 12. Proposition A1 / A2 / A3

### A1 — Shared Action Decision Slice

**Objectif unique :** créer le target réel PebbleAgents et faire déléguer par
`agents_basic` la décision goal → action à une implémentation partagée.

**Types/fonctions :** `AgentPosition`, `AgentGoalKind`, `AgentGoal`,
`AgentAction`, `AgentActionDecisionInput`, `AgentActionDecider.decide`, direction
explore et pas vers home. `LabAgent.decideAction` reste le wrapper de mutation.

**Fichiers créés probables :**

- `Sources/PebbleAgents/AgentActionDecision.swift`;
- `Tests/PebbleAgentsTests/AgentActionDecisionTests.swift`.

**Fichiers modifiés probables :** `Package.swift`, `LabAgent.swift` seulement.

**Compatibilité :** typealiases `Lab*`; conformances et JSON identiques;
mémoire/counters restent appliqués par le wrapper Lab.

**Tests :** `swift test`; builds debug/release; pebsmoke; deux runs
`agents_basic`; smokes goal apply et 5.15B; comparaison de quatre fichiers
stables et des séquences goal/action.

**DoD binaire :** target non vide; décision appelée par le runtime; toutes les
branches action couvertes; hashes de parité identiques hors `config.outPath`;
aucun import PebbleCore dans PebbleAgents; aucune autre zone modifiée.

**Risque : moyen.** Typealiases et access control affectent de nombreux
fixtures à la compilation, mais la logique extraite est petite et pure.

**Rollback logique :** remettre les quatre types et le switch dans
`LabAgent.swift`, retirer dépendance/target/tests; aucune migration de données.

**Dépendance :** aucune autre que A0. **Résultat Phase B :** types goal/action et
decision kernel déjà importables par l'app.

### A2 — Minimal Cognitive State and Kernel

**Objectif unique :** extraire les mutations cognitives restantes hors World et
hors déplacement : needs tick, nearby perception normalisée, goal selection,
action effect et mémoire.

**Types/fonctions :** futurs `AgentNeeds`, `AgentNearbyObservation`,
`AgentMemoryEntry`, `AgentCognitiveState`, `AgentGoalSelection`,
`AgentActionEffect`; fonctions pures de transition. `LabAgent.observe(world:)`
et `applyAbstractMovement` restent en place.

**Fichiers créés probables :** 2 à 4 fichiers sous `Sources/PebbleAgents` et
tests ciblés. **Fichiers modifiés :** `LabAgent.swift`; au plus un adapter
PebbleLab dédié. Ne pas modifier main si les wrappers suffisent.

**Compatibilité :** façade `LabAgent` conservée; schéma Codable historique
inchangé; mode mémoire `legacyUnbounded` explicite pour parité, avec une policy
bornée disponible pour la future session. Ne jamais tronquer silencieusement la
baseline historique.

**Tests/DoD :** tests de seuils de goal, effets exacts, floats et ordre; runs
0/1/3/80 ticks; 3 et 10 agents; fixtures memory/goal/5.15; hashes historiques;
aucun World reçu par le kernel. DoD : le switch goal et les effets ne sont plus
dupliqués dans LabAgent, toutes les preuves restent vertes.

**Risque : élevé.** Les seuils flottants, la mémoire non bornée et les nombreux
fixtures rendent cette extraction plus sensible.

**Rollback logique :** rétablir les wrappers comme implémentations locales sans
changer les DTOs A1. **Dépendance :** A1. **Résultat B :** kernel cognitif
réutilisable, encore nourri par un adapter Lab.

### A3 — Shared Multi-Agent Session and Read-Only Snapshots

**Objectif unique :** créer une session cognitive multi-agent stable et des
snapshots partagés, puis faire passer `agents_basic` par cette session sans
déplacer ses outputs historiques.

**Types/fonctions :** `AgentSimulationSession`, `AgentSessionConfiguration`,
`AgentPerceptionInput`, `AgentSnapshot`, `AgentSessionSnapshot`, résultat de tick
et ordre stable par agent id. La session ne possède ni World ni filesystem.

**Fichiers créés :** session/snapshot dans PebbleAgents; adapters de perception
et output dans PebbleLab. **Fichiers modifiés :** `main.swift` de façon minimale,
`LabScenarios.swift` si nécessaire, `LabOutput.swift` uniquement pour adapter
les snapshots à l'ancien JSON.

**Compatibilité :** l'ancien `AgentSnapshot` PebbleLab reste le writer de
`agent_snapshot.json`; `RunMetrics` et `RunEvent` consomment les résultats de la
session via adapter; aucune clé JSON ne change.

**Tests/DoD :** ordre d'entrée permuté mais snapshot trié; 0/1/3 agents; pause
non concernée; deux runs; multi-seed; hashes; session sans Foundation I/O,
AppKit, Metal ou PebbleCore. DoD : `agents_basic` utilise la session partagée et
Pebble peut compiler contre les snapshots lors de B sans dépendre de PebbleLab.

**Risque : élevé.** C'est la sous-phase qui touche l'orchestration monolithique.

**Rollback logique :** conserver le kernel A1/A2, remettre la boucle locale et
retirer l'adapter session. **Dépendance :** A2. **Résultat B :** source de vérité
et snapshots directement consommables par le futur contrôleur app.

## 13. Définition détaillée de A1

### 13.1 Tranche exacte

Extraire le bloc fonctionnel actuellement compris entre
`LabAgent.decideAction(tick:)` (`LabAgent.swift:158`) et ses deux helpers purs
`movementStepTowardHome()` (`LabAgent.swift:330`) et
`movementDirectionForAgent(id:tick:)` (`LabAgent.swift:426`).

Ne pas extraire les mutations de wrapper :

```text
lastAction = action
actionCount += 1
remember(type: "action_chosen", ...)
```

Elles restent dans `LabAgent.decideAction` en A1. Le wrapper construit
`AgentActionDecisionInput`, appelle `AgentActionDecider.decide`, puis conserve
exactement ces trois mutations. Ainsi la logique de choix est partagée, tandis
que mémoire et état agrégé attendent A2.

### 13.2 Symboles futurs et compatibilité

```text
PebbleAgents.AgentPosition
PebbleAgents.AgentGoalKind
PebbleAgents.AgentGoal
PebbleAgents.AgentAction
PebbleAgents.AgentActionDecisionInput
PebbleAgents.AgentActionDecider.decide(_:)
```

Dans PebbleLab, temporairement :

```text
typealias LabAgentPosition = AgentPosition
typealias LabGoalKind = AgentGoalKind
typealias LabGoal = AgentGoal
typealias LabAgentAction = AgentAction
```

Tous les types et initializers nécessaires au wrapper doivent être `public`.
Les conformances doivent rester exactement celles du code actuel : position et
goal Codable/Equatable, action Encodable, mêmes raw values et mêmes labels de
champs. Ne pas ajouter arbitrairement Hashable ou Sendable en A1.

### 13.3 Graphe de dépendances A1

```text
AgentPosition ─┐
AgentGoalKind ─┼→ AgentActionDecisionInput → AgentActionDecider → AgentAction
AgentGoal ─────┘

LabAgent.decideAction
→ convertit l'état en AgentActionDecisionInput
→ AgentActionDecider.decide
→ affecte lastAction
→ incrémente actionCount
→ remember(action_chosen)
```

Le target graph devient :

```text
PebbleCore
PebbleAgents                 (aucune dépendance target)
PebbleLab → PebbleCore + PebbleAgents
Pebble    → PebbleCore
pebsmoke  → PebbleCore
```

### 13.4 Pourquoi cette tranche

- appelée à chaque tick de chaque agent;
- toutes ses branches sont observées dans le runtime ou testables sans World;
- directement utile à l'observer 3D pour afficher goal/action;
- aucune dépendance PebbleCore;
- aucune sortie filesystem;
- séparation naturelle entre décision pure et effets/mouvement;
- suffisamment substantielle pour éviter un target vide;
- suffisamment petite pour éviter le déplacement complet de `LabAgent`.

### 13.5 Comportements à préserver exactement

- priorité du `switch` sur les cinq goals;
- `seekSafety`: pas cardinal vers home avec priorité X en cas d'égalité, sinon
  `wait` à home;
- `rest` → `rest`;
- `observeOtherAgent` → `observe_area`;
- `explore`: cycle déterministe basé sur suffixe numérique + tick;
- `idle` → `wait`;
- noms/reasons/deltas/tick identiques;
- une action et une mémoire `action_chosen` par tick;
- aucun changement de goal, effet, position ou ordre;
- JSON et événements bit-identiques.

### 13.6 Preuve de parité

Sur deux runs dans des dossiers différents, comparer :

- `agent_snapshot.json` byte-for-byte;
- `metrics.json` byte-for-byte;
- `events.ndjson` byte-for-byte;
- `world_snapshot.json` byte-for-byte;
- `config.json` après suppression de `outPath`;
- séquence `[tick, agentId, action, reason]`;
- séquence `[tick, agentId, fromGoal, toGoal, reason]`;
- positions finales et compteurs d'action/mouvement/mémoire;
- outputs des fixtures goal integration, goal apply et cognitive loop.

### 13.7 Fichiers probables A1

Créés :

- `Sources/PebbleAgents/AgentActionDecision.swift`;
- `Tests/PebbleAgentsTests/AgentActionDecisionTests.swift`.

Modifiés :

- `Package.swift` : target, dépendance PebbleLab, target de tests;
- `Sources/PebbleLab/LabAgent.swift` : import, typealiases, wrapper délégué.

### 13.8 Fichiers interdits A1

- `Sources/PebbleLab/main.swift`;
- `Sources/PebbleLab/LabScenarios.swift`;
- `LabOptions.swift`, `LabOutput.swift`, `LabEvents.swift`;
- tous les fichiers de reports/fixtures 5.x;
- tout `Sources/Pebble/*`;
- tout `Sources/PebbleCore/*`;
- renderer, HUD, commandes, physical bridges, movement stack;
- registries, save/load, resources, shaders, goldens;
- ROADMAP, CHANGELOG, DEV_JOURNAL et anciens documents de phase.

### 13.9 Commit et risque

Message proposé :

```text
Extract shared PebbleAgents action decision slice
```

Risque qualitatif : **moyen**. La logique est pure et petite, mais les types de
goal sont consommés par de nombreux fichiers PebbleLab et Swift exige une
visibilité publique complète à travers le module.

## 14. DoD de A1

A1 est terminée si et seulement si :

1. `PebbleAgents` est un target non vide, Swift 5, sans PebbleCore/AppKit/Metal;
2. PebbleLab dépend de PebbleAgents;
3. le runtime `agents_basic` appelle réellement `AgentActionDecider`;
4. aucune deuxième implémentation du switch goal → action ne subsiste;
5. les typealiases temporaires compilent tous les scénarios existants;
6. les cinq branches de décision et les cas seekSafety home/axes sont testés;
7. `swift test`, les trois builds demandés et pebsmoke passent;
8. deux runs 3 agents × 80 ticks ont une parité exacte selon §13.6;
9. les smokes 5.13, 5.14 et 5.15B restent verts;
10. aucun JSON, événement, compteur, goal, action ou position ne change;
11. aucun World, movement stack, renderer ou app runtime n'est ouvert;
12. le diff est limité aux quatre chemins prévus et à aucun cleanup.

## 15. Tests de A1

### 15.1 Unitaires

`swift test` avec au minimum :

- idle → wait;
- rest → rest;
- observeOtherAgent → observe_area;
- explore pour les quatre directions et un id sans suffixe;
- seekSafety déjà home → wait;
- seekSafety X positif/négatif, Z positif/négatif;
- égalité abs(X)==abs(Z) choisit X;
- tick et reason exacts;
- encodage JSON `AgentAction` compatible.

### 15.2 Intégration et parité

```text
swift build
swift test
swift build -c release --product Pebble
swift build -c release --product PebbleLab
swift run -c release pebsmoke

swift run -c release PebbleLab --seed 12345 --agents 3 --ticks 80 \
  --scenario agents_basic --out /tmp/pebbleagents-a1-run1
swift run -c release PebbleLab --seed 12345 --agents 3 --ticks 80 \
  --scenario agents_basic --out /tmp/pebbleagents-a1-run2

swift run -c release PebbleLab --seed 12345 --ticks 20 \
  --scenario agents_basic_goal_integration_guarded_fixture_smoke --out /tmp/a1-513
swift run -c release PebbleLab --seed 12345 --ticks 20 \
  --scenario agents_basic_goal_apply_guarded_fixture_smoke --out /tmp/a1-514
swift run -c release PebbleLab --seed 12345 --ticks 20 \
  --scenario agents_basic_cognitive_loop_fixture_smoke --out /tmp/a1-515
```

Ajouter des runs sans `--out` pour vérifier que A1 ne modifie pas la divergence
historique output/no-output, sans tenter de la corriger.

## 16. Fichiers probables de A1

| Action | Fichier | Limite |
| --- | --- | --- |
| créer | `Sources/PebbleAgents/AgentActionDecision.swift` | DTOs + décision pure uniquement |
| créer | `Tests/PebbleAgentsTests/AgentActionDecisionTests.swift` | tests de branches/encodage |
| modifier | `Package.swift` | target, dépendance PebbleLab, test target |
| modifier | `Sources/PebbleLab/LabAgent.swift` | import, aliases, délégation; aucun cleanup |

Si un cinquième fichier Swift paraît nécessaire, A1 doit être réévaluée avant
de l'élargir.

## 17. Fichiers interdits en A1

Les interdictions détaillées du §13.8 sont absolues. En particulier, A1 ne doit
pas toucher `main.swift` sous prétexte de router cleanup, ne doit pas déplacer
`AgentSnapshot`, `RunMetrics` ou `RunEvent`, et ne doit pas rendre Pebble
dépendant de PebbleAgents avant la Phase B.

## 18. Risques et mitigations

| Risque | Niveau | Mitigation |
| --- | --- | --- |
| cycle PebbleAgents ↔ PebbleCore/PebbleLab | élevé | A1 sans dépendance; PebbleAgents ne connaît aucun type Lab/Core |
| access control Swift inter-module | moyen | tous DTOs/init/méthodes nécessaires publics; test compile complet |
| types imbriqués | faible | aucun nested type dans LabAgent; ne pas en créer inutilement |
| extensions réparties | faible A1 | helpers action sont dans LabAgent.swift; rg avant/après |
| Codable modifié | élevé | conserver raw values, labels, conformances; golden JSON local |
| Hashable/Equatable modifié | moyen | ne pas ajouter de conformances en A1; Equatable identique |
| ordre déterministe | élevé | ordre de session inchangé; direction exacte; hashes séquences |
| signatures de digests fixture | élevé | exécuter 5.13/5.14/5.15; aucune normalisation de texte |
| formats reports/JSON | élevé | outputs restent PebbleLab; comparaison byte-for-byte |
| `config.json` faux négatif | faible | normaliser uniquement `outPath`; tout le reste exact |
| typealiases insuffisants | moyen | compile tous 49 fichiers; wrappers si diagnostics publics |
| logique dupliquée | élevé | une seule implémentation du switch; wrapper ne décide pas |
| comportement agents_basic changé | élevé | baseline 3×80 + multi-seed + événements/hashes |
| dépendance accidentelle au World | élevé | test/rg : aucun `import PebbleCore`, `World`, block/chunk dans target |
| déplacement prématuré des outputs | élevé | fichiers output/events interdits A1/A2 |
| API publique excessive | moyen | un fichier, DTOs minimaux, aucune abstraction hypothétique |
| compilation croisée Pebble/PebbleLab | moyen | Pebble inchangé en A; builds release des deux |
| impact pebsmoke | faible A1 | target Core inchangé; exécuter 456 tests |
| mémoire actuellement non bornée | élevé A2 | ne pas changer A1; policy explicite et testée en A2 |
| comportement dépendant de `--out` | élevé A2/A3 | documenter; corriger seulement avec baseline séparée et décision explicite |
| movement abstrait confondu avec stack | élevé | garder `applyAbstractMovement` dans Lab; Phase D seulement |
| snapshot app incomplet | moyen A3 | nouveau snapshot read-only dédié; ne pas réutiliser aveuglément `AgentSnapshot` |
| compilation release PebbleLab lente | moyen | extraction progressive; ne pas refactorer main; mesurer après chaque tranche |

## 19. Divergences avec le plan directeur

1. **Mémoire bornée annoncée, mémoire réelle non bornée.**
   `LabAgent.remember` fait un simple `append` (`LabAgent.swift:349`). Les bornes
   des fixtures Phase 5 ne bornent pas la mémoire runtime `agents_basic`.
2. **`AgentSimulationSession` n'existe pas.** La source de vérité actuelle est
   le tableau global `labAgents` dans `main.swift`, entouré de state global.
3. **Snapshot partagé inexistant.** `AgentSnapshot` encode `[LabAgent]` et est
   spécifique au writer PebbleLab; les snapshots 5.15 sont fixture-only.
4. **Le plan présente la boucle cognitive Phase 5 comme base réutilisable.**
   Les pipelines memory retrieval/bridge/cognitive integration sont des
   scénarios séparés et ne sont pas appelés par le runtime `agents_basic`.
5. **5.15B n'est pas une vraie boucle live.** Le code confirme la description
   prudente du plan : seule `currentGoal` mute; perception/mémoire sont fixtures,
   action dry-run, mouvement zéro.
6. **Perception et mémoire sont couplées.** `observe(world:tick:)` lit World et
   écrit une mémoire dans la même méthode, donc l'adapter futur doit séparer
   fact collection et transition cognitive.
7. **Le comportement dépend du filesystem.** Avec `--out`, le tick 0 effectue
   spawn memory, observation, nearby observation et sélection de goal; sans
   output, non. Ce couplage n'est pas mentionné dans le plan.
8. **`agents_basic` n'a pas de digest dédié.** La parité A doit être prouvée par
   hashes externes des outputs et séquences, pas par un digest produit.
9. **Le plan suggère de migrer état, kernel et session en Phase A.** Le code réel
   justifie trois commits A1/A2/A3; tout déplacer ensemble serait massif.
10. **Le plan dit ordre stable par agentId.** Le runtime utilise actuellement
    l'ordre du tableau; il coïncide avec agentId pour `makeBasicAgents`, mais la
    garantie n'est pas encapsulée. A3 devra la rendre explicite sans changer les
    sorties historiques.

Ces divergences ne remettent pas en cause la stratégie `PebbleAgents`; elles
imposent une extraction plus incrémentale et une définition de parité plus
précise.

## 20. Recommandation finale

**Lancer A1**, avec la tranche de décision d'action définie dans ce document.

Ne pas lancer une A1 qui créerait seulement un target et des protocoles, et ne
pas suivre littéralement la liste conceptuelle du plan en migrant tout
`LabAgent`. L'ordre recommandé est :

```text
A1  DTOs position/goal/action + décision pure réellement appelée
→ A2 transitions cognitives hors World/mouvement avec façade LabAgent
→ A3 session multi-agent + snapshots read-only + adapters PebbleLab
→ Phase B intégration app, sans duplication
```

Les preuves de sortie de la baseline rendent A1 opérationnelle et réversible.
Le principal point de vigilance avant A2 est la décision explicite sur la
mémoire legacy non bornée et sur le couplage comportemental à `--out`.

### Réponses explicites aux 21 questions

1. État Git exact : §3.
2. Fichiers lus : §4.
3. Structure réelle du package : §5.
4. Structure réelle de `agents_basic` : §6.
5. Types exacts : §7.
6. Fonctions appelées par tick : §6.3-6.4.
7. Dépendances de LabAgent : §8.
8. Dépendances PebbleCore : §9.
9. Outputs/reports/events : §6.5 et §10.
10. Extractible vers PebbleAgents : §10-11.
11. À garder dans PebbleLab : §10-11.
12. À ne surtout pas déplacer : §10, §17.
13. Découpage A1/A2/A3 : §12.
14. Ordre d'extraction : §20.
15. Risques principaux : §18.
16. DoD A1 : §14.
17. Tests A1 : §15.
18. Fichiers probablement modifiés : §16.
19. Fichiers interdits : §17.
20. Risque A1 : moyen (§13.9).
21. Recommandation : lancer A1 selon le plan corrigé.

## Annexe A — Baseline technique A0

### A.1 Builds et smoke

| Commande | Résultat |
| --- | --- |
| `swift build` | succès, build debug complet |
| `swift build -c release --product Pebble` | succès |
| `swift build -c release --product PebbleLab` | succès, 563,52 s sur cette machine |
| `swift run -c release pebsmoke` | succès, 456 passed, 0 failed |
| `swift run -c release PebbleLab --help` | succès; `agents_basic` et options confirmés |

### A.2 Commande réelle `agents_basic`

```text
swift run -c release PebbleLab \
  --seed 12345 \
  --agents 3 \
  --ticks 80 \
  --scenario agents_basic \
  --out /tmp/pebblelab-a0-agents-basic-run1
```

La même commande a été exécutée vers `run2`.

### A.3 Fichiers et déterminisme

Les cinq fichiers ont été produits dans chaque run. Tailles run1 :

| Fichier | Octets | SHA-256 run1 | Comparaison run2 |
| --- | ---: | --- | --- |
| `agent_snapshot.json` | 12 227 | `acf4a472c259bd519413b5da7966d2006be17dad0b45a3f19fa4e2f4c9deb768` | identique |
| `config.json` | 167 | `61943dc2cefa2cdc3927b4ef785b9b7e95f511819cb2767b81a54a7db68b62e6` | différent seulement par `outPath` |
| `events.ndjson` | 529 658 | `c3e89c4827d4326159bf136e52d1ed15a9de854533b34ba6681904dfe1eecb0b` | identique |
| `metrics.json` | 1 815 | `0beba41739b9063cbc91c8820d5dac5aa69e0dd56ac733da1b9e2a077533e56a` | identique |
| `world_snapshot.json` | 1 669 | `caeb791f880cd6d75aa5f1c21e534aa62cddb0dc2a937e491a9b3be978881cb3` | identique |

Après suppression de `outPath`, les configs sont identiques. Aucun digest
interne n'existe pour ce scénario.

### A.4 Séquences et compteurs

- 240 actions, hash de séquence identique :
  `e776d4658017bdc3a02daa3fdd1aab6c1d7c026e611a24136ff34bb2908f4b3a`;
- 160 changements de goal, hash identique :
  `31489c4d345e8ec516502cd6411c94d8ee625594fa353765a8115592763c9f9f`;
- 3 agents vivants; 240 ticks agents; 243 observations;
- 240 actions et 240 effets;
- 826 entrées mémoire;
- 100 mouvements, distance Manhattan totale 100;
- 2 418 événements écrits, 0 supprimé;
- goals finaux : trois `rest`.

Positions finales identiques :

| Agent | Position finale | Home | Distance | Mouvements | Mémoire | Goal final |
| --- | --- | --- | ---: | ---: | ---: | --- |
| agent_0 | (-14,64,6) | (6,64,6) | 20 | 60 | 302 | rest |
| agent_1 | (10,64,6) | (10,64,6) | 0 | 20 | 262 | rest |
| agent_2 | (6,64,10) | (6,64,10) | 0 | 20 | 262 | rest |

Aucune source de non-déterminisme n'a été observée à options égales. La seule
différence de fichier est le chemin de destination intentionnel dans config.

### A.5 Nettoyage

Les deux répertoires de run et les quatre fichiers temporaires de séquences
créés sous `/tmp` doivent être supprimés après finalisation du document. Aucun
output n'a été créé sous `runs/` ni ailleurs dans le dépôt.
