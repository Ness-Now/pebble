# Compatibility Matrix — Minecraft AI projects → PebbleLab

## Directement compatible avec Pebble

Aucun projet n'est directement compatible avec Pebble.

Raisons :
- Pebble n'est pas Minecraft Java.
- Pebble n'a pas le protocole serveur Minecraft.
- Pebble est Swift/Metal/macOS.
- Les autres projets sont souvent Python, JavaScript, Java, CUDA ou Minecraft Java.
- Les agents existants ciblent souvent MineRL, MineDojo, mineflayer ou Minecraft officiel.

## Très utile conceptuellement

### MineRL

Utilité :
- API environnement IA.

À reprendre :
- reset
- step
- observation
- action
- reward
- done
- trajectories

Priorité :
Très haute.

### MineDojo

Utilité :
- scénarios, tâches, objectifs textuels.

À reprendre :
- task suite
- success conditions
- benchmark
- prompts

Priorité :
Haute.

### mineflayer-pathfinder

Utilité :
- navigation.

À reprendre :
- GoalNear
- GoalBlock
- GoalFollow
- GoalComposite
- MovementProfile

Priorité :
Très haute.

### mineflayer

Utilité :
- API bot haut niveau.

À reprendre :
- moveTo
- dig
- place
- equip
- attack
- inventory
- events

Priorité :
Haute.

### Voyager

Utilité :
- skill library, curriculum, planner.

À reprendre :
- LabSkill
- LabSkillLibrary
- LabPlanner
- LabCurriculum

Priorité :
Très haute après actions de base.

## Utile plus tard

### Baritone

Utilité :
- pathfinding longue distance, mining, building.

À reprendre :
- LabProcess
- MiningProcess
- BuildingProcess
- ExplorationProcess

Priorité :
Moyenne puis haute.

### VPT

Utilité :
- imitation learning.

À reprendre :
- LabTrajectory
- observation/action frames
- behavioral cloning

Priorité :
Plus tard.

### MineCLIP

Utilité :
- reward textuel/visuel.

À reprendre :
- GoalEvaluator
- text objective scoring

Priorité :
Plus tard.

### STEVE-1

Utilité :
- text-to-behavior.

À reprendre :
- LabInstruction
- instruction → goal
- instruction → skill

Priorité :
Plus tard.

## À ne pas faire au début

- Installer tous les environnements lourds.
- Télécharger les modèles/poids.
- Brancher mineflayer directement à Pebble.
- Refaire Minecraft Java.
- Utiliser pixels bruts comme première observation.
- Entraîner du RL massif.
- Mettre un LLM dans chaque agent à chaque tick.
- Modifier PebbleCore sans tests.
- Modifier les registries.
- Regold les tests sans comprendre.
