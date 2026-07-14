# PebbleLab — Index documentaire

## Règle d’autorité

En cas de contradiction sur la direction future, appliquer cet ordre :

1. documents canoniques actuels ;
2. instructions `AGENTS.md` applicables au fichier concerné ;
3. documents opérationnels et runbooks pour leur procédure ;
4. références historiques pour expliquer une décision passée ;
5. plans remplacés uniquement comme contexte historique.

Un statut ou une « next step » dans un document historique ne remplace jamais
la roadmap prospective actuelle.

## `canonical-current`

| Document | Rôle |
| --- | --- |
| [`PEBBLE_CIVILIZATION_VISION.md`](PEBBLE_CIVILIZATION_VISION.md) | Cible produit, doctrine et invariants de Medieval Civilization V1. |
| [`PEBBLE_CIVILIZATION_ROADMAP.md`](PEBBLE_CIVILIZATION_ROADMAP.md) | État post-K, jalons, dépendances et ordre prospectif `CIV-XX`. |
| [`DEVELOPMENT_WORKFLOW.md`](DEVELOPMENT_WORKFLOW.md) | Cycle de livraison, niveaux de risque et validations permanentes. |

Les `AGENTS.md` racine et target-locaux sont des instructions permanentes, pas
des roadmaps. Ils restent obligatoires dans leur périmètre.

## `operational-runbook`

- [`../pebblelab-3d-live-prototype.md`](../pebblelab-3d-live-prototype.md) est le
  runbook live canonique. Il décrit les gates, commandes, preuves et limites des
  verticales 3D actuellement acquises.
- Les fichiers racine `README.md`, `ARCHITECTURE.md`, `CONTRIBUTING.md` et
  `SECURITY.md` restent les références opérationnelles du jeu Pebble et du
  dépôt général ; ils ne définissent pas la roadmap Civilization.

## `historical-reference`

Ces fichiers sont conservés comme preuve ou journal technique :

- [`ROADMAP.md`](ROADMAP.md), historique détaillé des anciennes phases ;
- `CHANGELOG.md`, `DECISIONS.md`, `DEV_JOURNAL.md` et `JOURNAL.md` dans ce
  dossier ;
- les anciens changelogs, journaux et décisions préfixés `PEBBLELAB_` dans
  `docs/` ;
- les audits datés, notamment `PHASE_A0_SHARED_AGENT_RUNTIME_AUDIT.md` et les
  audits de dette ou de reprise ;
- `docs/AI_EXTERNAL_RESEARCH.md` et `docs/AI_COMPATIBILITY_MATRIX.md`, qui
  documentent les recherches initiales sans imposer l’architecture actuelle ;
- les changelogs généraux du dépôt, pour l’histoire du jeu de base.

Leur contenu peut être exact pour le commit ou la phase décrite tout en étant
obsolète comme recommandation prospective.

## `superseded-or-obsolete`

Les séries suivantes ne pilotent plus le travail futur :

- `PHASE_4_*.md` et `PHASE_5_*.md`, anciens plans de phases terminées ou
  dépassées ;
- `NEXT_STEPS_FOR_PEBBLELAB.md` et `PEBBLELAB_NEXT.md`, anciennes listes de
  prochaines étapes ;
- `PEBBLELAB_OVERVIEW.md` et `PEBBLELAB_SOCIAL_AGENTS.md`, cadrages initiaux
  remplacés par la vision actuelle ;
- `PEBBLELAB_CODEX_RULES.md`, remplacé pour les instructions permanentes par
  les `AGENTS.md` et pour le processus par `DEVELOPMENT_WORKFLOW.md` ;
- les anciens documents de reprise et plans directeurs lorsqu’ils sont cités
  dans les journaux ou audits.

Ils ne sont ni supprimés ni renommés. Ils restent consultables comme contexte
historique, mais leurs API hypothétiques, limites temporaires et recommandations
de phase ne sont pas des engagements actuels.

## Convention pour les nouveaux documents

- Une direction produit durable appartient à la vision.
- Un ordre de livraison ou une dépendance appartient à la roadmap prospective.
- Une procédure reproductible appartient au workflow ou à un runbook identifié.
- Un compte rendu terminé appartient à un journal, changelog, audit ou document
  explicitement historique.
- Une mission utilise un identifiant `CIV-XX` et relie ses décisions aux
  documents canoniques sans recopier leur contenu.
