# MineRL → PebbleLab

## Rôle dans le projet

MineRL sert de modèle pour concevoir PebbleLab comme un environnement d'entraînement IA.

L'idée principale à reprendre :
- reset
- step
- observation
- action
- reward
- done
- info
- trajectoires

## À reprendre

- API reset / step / observe / reward / done.
- Notion d'épisode.
- Notion de scénario court.
- Observation space.
- Action space.
- Séparation environnement / policy.
- Enregistrement de trajectoires.
- Évaluation par tâches simples.

## À ne pas reprendre directement

- Backend Minecraft Java.
- Installation Java/JDK/Malmo.
- Pixel-only au début.
- Action-space souris/clavier brut au début.
- Dépendances lourdes.

## Adaptation Pebble

Créer une API Swift conceptuelle :

- PebbleLabEnv.reset(seed, scenario)
- PebbleLabEnv.step(action)
- PebbleLabEnv.observe()
- PebbleLabEnv.reward()
- PebbleLabEnv.done()
- PebbleLabEnv.info()

## Décision PebbleLab v1

On commence avec des actions haut niveau :

- wander
- moveTo
- gatherResource
- eat
- sleep
- returnHome
- depositInventory
- flee
- followAgent

Les actions bas niveau type clavier/souris/caméra viendront plus tard.

## Types Swift futurs

- LabEnvironment
- LabObservation
- LabAction
- LabReward
- LabEpisode
- LabTrajectory
- LabDoneReason

## Priorité

Très haute.

MineRL est le modèle de base pour l'API d'entraînement.
# MineDojo → PebbleLab

## Rôle dans le projet

MineDojo sert de modèle pour organiser des scénarios, tâches et objectifs variés.

L'idée à reprendre :
PebbleLab ne doit pas seulement lancer des agents dans un monde. Il doit proposer des scénarios mesurables.

## À reprendre

- Organisation en tâches/scénarios.
- Objectifs textuels.
- Conditions de succès.
- Tâches de survie.
- Tâches de collecte.
- Tâches de craft.
- Tâches de combat.
- Tâches créatives.
- Benchmark d'agents.

## À ne pas reprendre directement

- Backend Minecraft Java.
- Installation MineDojo.
- Données massives.
- Docker/Java au début.
- Observations multimodales lourdes.

## Adaptation Pebble

Créer :

- LabScenario
- LabTask
- LabSuccessCondition
- LabRewardFunction
- LabScenarioRegistry
- LabScenarioResult

## Scénarios PebbleLab v1

- empty_world_tick
- survival_day_1
- gather_food_basic
- gather_wood_10
- return_home_at_night
- avoid_monster
- community_survive_3_days
- shared_storage_basic
- build_shelter_basic
- explore_radius_100

## Scénarios PebbleLab v2

- village_food_security
- build_two_houses
- mine_stone_and_craft_tools
- defend_storage_at_night
- migrate_to_safer_area
- split_group_experiment
- cooperation_vs_individualism
- famine_response
- role_specialization
- primitive_economy

## Priorité

Haute.

MineDojo donne la logique de benchmark et de progression.
# MineCLIP → PebbleLab

## Rôle dans le projet

MineCLIP sert d'inspiration pour relier des objectifs textuels à une évaluation de comportement.

Ce n'est pas une priorité immédiate.

## À reprendre plus tard

- Idée de reward model.
- Objectifs textuels.
- Comparaison vidéo/texte.
- Évaluation d'un run par rapport à une intention.
- Récompenses moins manuelles.

## À ne pas faire maintenant

- Installer MineCLIP.
- Télécharger les poids.
- Brancher un gros modèle.
- Utiliser directement les vidéos.
- Remplacer les rewards simples.

## Adaptation Pebble future

Créer d'abord une interface abstraite :

- LabGoalEvaluator
- RuleBasedGoalEvaluator
- TextGoalEvaluator plus tard
- VisualGoalEvaluator plus tard

## Exemple

Objectif texte :
"build a shelter"

Évaluation v1 par règles :
- au moins 4 murs
- un toit
- un coffre
- un lit
- agent vivant à la fin

Évaluation v2 plus tard :
- screenshots/replay + modèle

## Priorité

Moyenne à basse au début.

MineCLIP devient utile après :
- replays
- screenshots
- scénarios
- agents physiques
- trajectoires
# STEVE-1 → PebbleLab

## Rôle dans le projet

STEVE-1 sert d'inspiration pour le comportement conditionné par texte.

Exemple :
- "collect wood"
- "build shelter"
- "find food"
- "mine iron"

## À reprendre

- Idée texte → comportement.
- Séparation instruction / policy.
- Tâches courtes.
- Évaluation par prompt.
- Utilisation de modèles préentraînés comme source d'inspiration.

## À ne pas reprendre maintenant

- Poids STEVE-1.
- VPT complet.
- MineCLIP complet.
- Dépendances Linux/CUDA.
- Pixel brut.
- Contrôle souris/clavier brut.

## Adaptation Pebble

Créer plus tard :

- LabInstruction
- LabInstructionParser
- LabInstructionPlanner
- LabGoalFromInstruction

## Version simple sans ML

"collect wood" → GatherResourceGoal(.wood)

"return home" → ReturnHomeGoal

"find food" → FindFoodGoal

"build shelter" → BuildBlueprintGoal(.basicShelter)

## Priorité

Basse au début, haute plus tard.

D'abord, on fait des goals et skills codés à la main.
Ensuite seulement, on ajoute des instructions textuelles.
# Voyager → PebbleLab

## Rôle dans le projet

Voyager est probablement l'une des meilleures inspirations pour PebbleLab.

Son idée principale :
un agent progresse grâce à une bibliothèque de skills réutilisables.

## À reprendre

- Skill library.
- Curriculum automatique.
- Mémoire de compétences.
- Planner haut niveau.
- Skills composables.
- Skills interprétables.
- Résultat de tâche.
- Réutilisation de compétences dans un autre monde.

## À ne pas reprendre directement

- mineflayer.
- Minecraft Java.
- Exécution de code généré par LLM.
- LLM à chaque tick.
- Dépendance à un compte Minecraft.
- Node comme moteur principal.

## Adaptation Pebble

Créer :

- LabSkill
- LabSkillLibrary
- LabSkillContext
- LabSkillResult
- LabPlanner
- LabCurriculum
- LabSkillMetrics

## Skills PebbleLab v1

- wander
- returnHome
- findFood
- eatFood
- gatherWood
- depositInventory
- fleeDanger
- followAgent

## Skills PebbleLab v2

- craftBasicTool
- buildBasicShelter
- guardStorage
- exploreArea
- mineStone
- shareKnowledge
- farmFood
- repairShelter

## Skills PebbleLab société

- assignRole
- askForHelp
- shareFood
- defendGroup
- migrateGroup
- formSubgroup
- tradeResource

## Priorité

Très haute, mais après l'API environnement et les actions de base.

Voyager donne la structure des compétences.
# mineflayer → PebbleLab

## Rôle dans le projet

mineflayer sert d'inspiration pour l'API haut niveau d'un bot.

Il n'est pas compatible directement avec Pebble, car il dépend du protocole Minecraft Java.

## À reprendre

- API lisible de bot.
- Actions haut niveau.
- Événements.
- Plugins.
- Contrôle d'inventaire.
- craft / dig / place / attack / eat.
- Principe bot.on(event).

## À ne pas reprendre

- Protocole Minecraft Java.
- Node comme dépendance directe.
- Connexion serveur.
- Plugins mineflayer tels quels.

## Adaptation Pebble

Créer :

- LabAgentController
- LabAction
- LabEvent
- LabInventoryView
- LabWorldView
- LabBotAPI

## API cible Swift

- moveTo(position)
- digBlock(position)
- placeBlock(block, position)
- equipItem(item)
- attackEntity(entityId)
- eat(item)
- sleep(bedPosition)
- depositItem(item, count, storageId)
- withdrawItem(item, count, storageId)
- lookAt(position)
- follow(agentId)

## Événements

- agentSpawned
- agentDied
- inventoryChanged
- goalChanged
- pathFailed
- resourceFound
- dangerSeen
- itemCrafted
- itemDeposited
- shelterBuilt

## Priorité

Haute.

mineflayer aide à rendre PebbleLab agréable à contrôler.
# mineflayer-pathfinder → PebbleLab

## Rôle dans le projet

mineflayer-pathfinder sert d'inspiration pour les goals de navigation.

Pebble a déjà du pathfinding, donc il ne faut pas importer le code JS.
Il faut reprendre les concepts.

## À reprendre

- GoalNear
- GoalBlock
- GoalFollow
- GoalComposite
- Movements
- Movement costs
- goto(goal)
- path_update
- goal_reached
- path_reset
- NoPath / Timeout / GoalChanged

## À ne pas reprendre

- JavaScript.
- Bot mineflayer.
- dépendances Prismarine.
- protocole Minecraft.

## Adaptation Pebble

Créer :

- LabNavigationGoal
- LabGoalNear
- LabGoalBlock
- LabGoalFollow
- LabGoalComposite
- LabGoalAvoidArea
- LabMovementProfile
- LabPathPlanner
- LabPathResult
- LabPathFailureReason

## Movement profile

Un profil de mouvement doit dire :

- peut marcher
- peut sauter
- peut casser blocs
- peut poser blocs
- peut nager
- peut éviter danger
- coût de casser
- coût de poser
- coût de passer près d'un danger
- coût de monter/descendre

## Priorité

Très haute.

La navigation est obligatoire pour une IA crédible.
# Baritone → PebbleLab

## Rôle dans le projet

Baritone sert d'inspiration pour les processus longs.

Exemples :
- aller loin
- miner
- construire
- explorer
- farmer
- recalculer un chemin
- gérer les obstacles

## À reprendre

- Long distance pathing.
- Segmented pathing.
- Chunk caching conceptuel.
- Block breaking dans le coût de chemin.
- Block placing dans le coût de chemin.
- GoalComposite.
- Processus : farm, build, mine, explore.
- Recalcul si le monde change.

## À ne pas reprendre

- Code Java.
- Forge/Fabric/NeoForge.
- Minecraft client.
- Mod loaders.
- Dépendances Gradle.

## Adaptation Pebble

Créer :

- LabProcess
- GoToProcess
- MiningProcess
- BuildingProcess
- ExplorationProcess
- FarmingProcess
- LongDistancePathPlanner
- ProcessStatus
- ProcessMetrics

## Règle importante

Un process doit être :

- interruptible
- observable
- loggable
- mesurable
- capable d'échouer proprement
- capable de reprendre

## Priorité

Moyenne au début, haute ensuite.

D'abord navigation simple, ensuite processus longs.
# VPT → PebbleLab

## Rôle dans le projet

VPT sert d'inspiration pour l'imitation learning.

L'idée :
enregistrer observation + action, puis entraîner un modèle à imiter.

## À reprendre plus tard

- Trajectoires observation/action.
- Behavioral cloning.
- Politique préentraînée.
- Modèle inverse conceptuel.
- Enregistrement de démonstrations.
- Séparation policy / action mapping.

## À ne pas faire maintenant

- Pixel brut.
- Gros modèle.
- Entraînement vidéo.
- Reproduction complète de VPT.
- Dépendance aux poids OpenAI.
- CUDA/GPU cloud.

## Adaptation Pebble

Créer d'abord :

- LabTrajectory
- LabObservationFrame
- LabActionFrame
- LabRewardFrame
- LabDemoRecorder
- LabPolicyEvaluator

## Format conseillé

NDJSON :

{"tick":0,"agent":1,"obs":{...},"action":"wander","reward":0,"done":false}
{"tick":1,"agent":1,"obs":{...},"action":"moveTo","reward":0.1,"done":false}

## Priorité

Basse au début, importante plus tard.

Il faut d'abord avoir :
- agents
- actions
- observations
- rewards
- scénarios
