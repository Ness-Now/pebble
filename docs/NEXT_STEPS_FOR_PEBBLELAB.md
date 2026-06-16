# Next Steps — External AI research → PebbleLab

## Ordre d'utilisation des références

1. MineRL
   - Construire LabEnvironment : reset / step / observe / reward / done.

2. mineflayer-pathfinder
   - Construire LabNavigationGoal : GoalNear / GoalBlock / GoalFollow / GoalComposite.

3. mineflayer
   - Construire LabAgentController : moveTo / dig / place / eat / sleep / attack / deposit.

4. MineDojo
   - Construire LabScenario et LabTask.

5. Voyager
   - Construire LabSkillLibrary et LabPlanner.

6. Baritone
   - Construire LabProcess : mining / building / exploration.

7. VPT
   - Construire LabTrajectory et préparer imitation learning.

8. MineCLIP / STEVE-1
   - Ajouter objectifs textuels et text-to-behavior plus tard.

## Première mission Codex recommandée

Lire :
- ARCHITECTURE.md
- CONTRIBUTING.md
- Package.swift
- docs/AI_EXTERNAL_RESEARCH.md
- docs/AI_COMPATIBILITY_MATRIX.md

Objectif :
Proposer une architecture PebbleLab v1 inspirée de MineRL, mineflayer-pathfinder, mineflayer et MineDojo.

Contraintes :
- Ne code rien.
- Ne modifie aucun fichier.
- Le but est un mode headless.
- Pebble doit continuer à fonctionner.
- PebbleCore doit rester déterministe.
- Ne touche pas aux registries.
- Ne touche pas aux goldens.

Livrable attendu :
1. fichiers Swift à créer ;
2. types à créer ;
3. commandes terminal pour tester ;
4. ordre de développement ;
5. risques.
