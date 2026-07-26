# GATE-B-CONVERGENCE-01B — progressive soak readiness

```text
NOT READY FOR GATE B RE-EVALUATION #5
```

Cette mission teste la fondation publiée de `GATE-B-CONVERGENCE-01A`. Elle
n'est ni Gate B re-evaluation #5, ni une acquisition de Gate B, ni une phase de
correction produit. Gate B reste non acquise et `CIV-26` n'est pas commencé.

## Binding et périmètre

La campagne est liée à :

- baseline historique re-evaluation #4 :
  `eaed4ce1d0a8c151316ddd84e8076813b3079c94` ;
- fondation d'implémentation publiée :
  `e85377a05c5e0ffc6bfdcf95a581fef9c7e889c8` ;
- `EVALUATED_HEAD` :
  `3e6d29724ec55bc98ee4ada740b4867583da6289` ;
- digest de configuration :
  `226fc72e539449761935aa311269e4b534376127576e224012ab8ad0863c5cf5` ;
- evidence root :
  `/tmp/PebbleLab-GateB-Convergence01-3e6d29724ec55bc98ee4ada740b4867583da6289`.

Le seul changement avant les vagues sépare la baseline d'architecture
historique de la fondation publiée attendue. Depuis cette fondation, aucun
fichier `Sources/**` ou `Sources/pebsmoke/**` n'est modifié. Il n'y a eu ni
reroll, ni substitution de seed, ni correction produit.

## Vagues exécutées

| Vague | Commande | Résultat | Détail |
| --- | --- | --- | --- |
| Wave 0 | `--wave0` | PASS | 17 selectors, 1 310 checks, 0 failed |
| Wave 1 | `--wave1` | PASS | 10/10 seeds à 128 ticks |
| Wave 2 | `--wave2` | FAIL | 10/10 seeds tentés ; 5 `HARNESS_INVALID`, 5 `NOT_REACHED` |
| Wave 3 | `--wave3` | NOT_RUN | arrêt après la première vague en échec |
| Determinism | `--determinism` | NOT_RUN | arrêt après Wave 2 |
| Checkpoint | `--checkpoint` | NOT_RUN | arrêt après Wave 2 |
| Stress 2593 | `--stress` | NOT_RUN | arrêt après Wave 2 |
| Stress 4099 | `--stress` | NOT_RUN | arrêt après Wave 2 |
| Live 120 s | `--live` | NOT_RUN | arrêt après Wave 2 |

## Wave 1 — 10 × 128

| Seed | Résultat | Ticks | s | Erreurs | Mouvements / blocks | Distance max | Complétions |
| ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 46 | PASS | 128 | 5 | 0 | 199 / 101 | 12 | 25 |
| 71 | PASS | 128 | 5 | 0 | 208 / 94 | 12 | 25 |
| 113 | PASS | 128 | 5 | 0 | 199 / 101 | 12 | 25 |
| 197 | PASS | 128 | 6 | 0 | 207 / 94 | 12 | 25 |
| 337 | PASS | 128 | 5 | 0 | 212 / 90 | 12 | 25 |
| 509 | PASS | 128 | 6 | 0 | 208 / 94 | 12 | 25 |
| 887 | PASS | 128 | 5 | 0 | 211 / 84 | 10 | 26 |
| 1597 | PASS | 128 | 5 | 0 | 211 / 84 | 10 | 26 |
| 2593 | PASS | 128 | 5 | 0 | 211 / 84 | 10 | 26 |
| 4099 | PASS | 128 | 5 | 0 | 208 / 94 | 12 | 25 |

Tous les runs conservent un bootstrap role-neutral, le mouvement actif, zéro
commande productive post-bootstrap, zéro rôle assigné, zéro erreur runtime et
des résultats physiques autonomes : six actions agriculture, une tâche
livestock et dix-huit ou dix-neuf résultats wild.

## Wave 2 — 10 × 800

| Seed | État brut | Ticks | Compl. >600 | Mouv. >600 | Starts / compl. / blocks | Same target | Replan limit |
| ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 46 | HARNESS_INVALID | 800 | 0 | 400 | 189 / 25 / 157 | 164 | 153 |
| 71 | NOT_REACHED | 804 | 0 | 179 | 194 / 25 / 160 | 168 | 154 |
| 113 | HARNESS_INVALID | 800 | 0 | 400 | 189 / 25 / 157 | 164 | 153 |
| 197 | NOT_REACHED | 804 | 0 | 343 | 193 / 25 / 160 | 168 | 154 |
| 337 | HARNESS_INVALID | 800 | 0 | 354 | 193 / 25 / 159 | 167 | 153 |
| 509 | HARNESS_INVALID | 800 | 0 | 354 | 193 / 25 / 159 | 167 | 153 |
| 887 | NOT_REACHED | 804 | 0 | 374 | 190 / 26 / 156 | 165 | 151 |
| 1597 | NOT_REACHED | 804 | 0 | 374 | 190 / 26 / 156 | 165 | 151 |
| 2593 | HARNESS_INVALID | 800 | 0 | 368 | 189 / 26 / 155 | 164 | 150 |
| 4099 | NOT_REACHED | 804 | 0 | 408 | 194 / 25 / 160 | 168 | 154 |

Chaque application sort avec code zéro et zéro erreur runtime. Le mouvement
reste actif après tick 600, sans bypass distance, mais aucune activité physique
ne se termine après tick 600. Les cinq `NOT_REACHED` reflètent un marker
`tick=804 target=800 exact=0`, jamais converti en PASS.

## Blocker produit

```text
B-BLOCKER-AUTONOMOUS-ACTIVITY-OCCUPIED-DESTINATION-RETRY-STORM
classification: PRODUCT INTEGRATION BUG
reproduction: 10/10 fixed seeds
```

Représentant seed 46 :

```text
Civilization tick: 136
World tick: 92
actor: agent_0
goal: civilizationActivity
activity: wildSubsistence/wildGathering
position: 9,76,-113
home: 14,76,-115
proposed Core step: 9,76,-112
physical result: blocked — destination occupied
feedback: movementBlocked
```

Les premières observations du même défaut apparaissent à tick 105–156 selon
le seed. Après l'épuisement borné du replan, la même cible matériellement
inchangée est sélectionnée de nouveau. La trace seed 46 répète ensuite
`wildSubsistence/wildGathering` tous les cinq ticks, conserve `agent_0` à la
même position et totalise 153 refus
`bounded_navigation_replan_limit_reached`. Le parser publie
`sameObservedFailureRun=1` et `blocking=0`, mais la revue senior classe ce
churn `BLOCKING` : le pattern causal est systémique et empêche toute
complétion productive après tick 128.

La plus petite correction recommandée appartient à une mission produit
séparée : dans la couture intention/replan existante de PebbleAgents, viser une
position de travail adjacente, physiquement atteignable et vérifiée pour les
interactions dont la cellule cible est occupée. Après épuisement du replan,
l'activité doit devenir stale et exiger une observation locale fraîche ou un
cooldown borné avant de resélectionner la même cible. PebbleCore conserve le
pathfinding et `Entity.move`; aucune téléportation, extension home, seconde
autorité ou réussite abstraite n'est autorisée.

Ce blocker est distinct de `B-BLOCKER-MOVEMENT-HOME-BOUNDARY`. L'ancien défaut
tick 508–509 ne réapparaît pas : toutes les sessions gardent le mouvement
actif, zéro erreur distance, zéro bypass et une distance maximale acceptée de
10 ou 12 selon le contrat métier.

## Invalidités du harnais

Trois défauts publiés ont été découverts après le gel de
`EVALUATED_HEAD`; ils n'ont pas été corrigés pendant la campagne :

1. `H-BLOCKER-WORK-DEMAND-RETAINED-CAP-MISMATCH` : l'instrumentation compare
   les 128 demandes Work retenues à `maximumActiveDemands=64`, alors que le
   produit borne explicitement la collection retenue totale à
   `maximumActiveDemands * 2`. Les applications et Worlds ont réellement été
   lancés ; les données produit restent diagnostiques, mais aucun PASS Wave 2
   n'est récupérable.
2. `H-BLOCKER-FIXED-HORIZON-OVERSHOOT` : cinq seeds dépassent la cible fixe et
   émettent tick 804 au lieu de tick 800. Les applications et Worlds ont été
   lancés ; `NOT_REACHED` demeure la seule classification fail-closed.
3. `H-BLOCKER-FAILED-WAVE-SUMMARY-AGGREGATION` : `--summary` exige que Wave 2
   soit déjà PASS et refuse donc d'agréger une campagne arrêtée sur échec.
   Aucune application et aucun World ne sont lancés par cette tentative. Le
   présent record est une synthèse reviewer-authored des JSON et logs
   HEAD-bound, pas le résultat faussement présenté d'un agrégateur réussi.

Les corrections minimales sont respectivement : exposer la vraie limite
retenue Work `2 × maximumActiveDemands`, arrêter les batches sur l'horizon
exact et autoriser `--summary` à agréger un échec avec les vagues suivantes
explicitement `NOT_RUN`.

## Continuité fonctionnelle

- Agriculture : six till/plant par seed, mais zéro cycle, maturité, harvest,
  recomputation de réserve ou cycle suivant ; `FAIL`.
- Wild : dix-huit ou dix-neuf complétions précoces, puis la cible occupée
  concentre le churn et aucune complétion ne survient après tick 128 ;
  continuité `FAIL`.
- Livestock : initiation autonome, observation locale, reach physique, débit
  feed et une tâche réelle sont présents ; zéro produit, breeding ou gestion
  ultérieure ; continuité `FAIL`.
- Nourriture physique : neuf consommations exactes par seed à ticks 500–502,
  baisse de faim et delta abstrait nul. La custody finale est physique, sans
  dropped ID ni stock fantôme, mais la continuité après tick 600 n'est pas
  établie ; readiness `FAIL`.
- Care : zéro besoin et zéro outcome dans Wave 2 ; les stress n'ont pas été
  lancés, donc `NOT_EXERCISED`.
- Teaching : quatre apprentissages et démonstrations, puis une ou deux propres
  réussites guidées avec `guidedPracticeSkillDelta=0` ; own-practice closure
  `PASS`.
- Work/professions : demandes, refresh, engagements, neuf à onze preuves et
  trois profils existent, sans identity/stale reject. L'absence de résultat
  physique prolongé après tick 128 empêche toutefois la readiness de
  spécialisation ; `FAIL`.

## Matière et bornes

Les trois kits physiques identiques restent traçables. Un feed fait passer le
wheat total de 9 à 8 et trois plantations les seeds de 12 à 9. Les outils
restent trois hoes et trois shears. Les consommations alimentaires portent un
débit physique exact et un delta abstrait nul ; le stock générique et le camp
stock restent à zéro. Aucun animal, produit livestock ou outil n'est créé par
le harnais.

Les activités retenues restent entre 188 et 193 sur 256, avec zéro éviction et
une lifetime maximale de 5. Le causal ledger est compacté à sa borne
8 192. Les engagements Work restent entre 164 et 169 sur 256. Le seul marker
de borne invalide est le cap Work mal instrumenté `128/64`, alors que le cap
produit de la collection retenue est 128.

## Validation et disposition

Sur `EVALUATED_HEAD`, la gate canonique passe :

```text
35/35
3187 baseline + 38 new - 0 removed/replaced = 3225
3225 passed
0 failed
```

Aucun nouveau noyau cognitif, pathfinder, inventaire, moteur de persistence,
farming, livestock, scheduler Teaching/Work, oracle global ou autorité runtime
Gate B n'est ajouté. Gate R reste `ACQUIRED`.

La campagne n'autorise pas Gate B re-evaluation #5. Gate B re-evaluation #4
reste un `FAIL` historique, Gate B reste non acquise et `CIV-26` reste
`planned` / non commencé.
