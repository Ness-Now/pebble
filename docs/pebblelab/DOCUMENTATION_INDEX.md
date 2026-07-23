# PebbleLab — Index documentaire

## Règle d’autorité

En cas de contradiction sur la direction future, appliquer cet ordre :

1. code et tests du HEAD validé pour l’état réellement implémenté ;
2. vision canonique pour la cible produit et les invariants ;
3. roadmap V3 Reuse-First pour l’ordre prospectif ;
4. manifest pour sa projection machine-lisible ;
5. instructions `AGENTS.md`, workflow et runbooks dans leur périmètre ;
6. références historiques et plans remplacés comme contexte seulement.

Un statut ou une « next step » dans un document historique ne remplace jamais
la roadmap prospective actuelle.

## `canonical-current`

| Document | Rôle |
| --- | --- |
| [`PEBBLE_CIVILIZATION_VISION.md`](PEBBLE_CIVILIZATION_VISION.md) | Cible produit, doctrine et invariants de Medieval Civilization V1. |
| [`PEBBLE_CIVILIZATION_ROADMAP.md`](PEBBLE_CIVILIZATION_ROADMAP.md) | Autorité prospective V3 Reuse-First, phases `CIV-00` à `CIV-67`, gates et frontières de convergence. |
| [`ROADMAP_MANIFEST.json`](ROADMAP_MANIFEST.json) | Projection machine-lisible de la roadmap V3 ; elle doit rester synchronisée avec l’autorité humaine. |
| [`DEVELOPMENT_WORKFLOW.md`](DEVELOPMENT_WORKFLOW.md) | Cycle de livraison, niveaux de risque et validations permanentes. |

Les `AGENTS.md` racine et target-locaux sont des instructions permanentes, pas
des roadmaps. Ils restent obligatoires dans leur périmètre.

État canonique après l'évaluation dédiée : `CIV-00` à `CIV-25` sont
`completed` dans leurs contrats bornés et Gate R reste acquise. La candidate
Gate B est `FAIL` et Gate B n'est pas acquise. Aucune phase n'est promue
automatiquement pendant sa correction ; `CIV-26` à `CIV-67` restent `planned`.
Les jalons non canoniques publiés `GATE-B-CORR-01` et `GATE-B-CORR-02` ont
remédié leurs quatre blockers historiques. Gate B re-evaluation #2 est
désormais enregistrée `FAIL` : le chemin produit normal ne crée pas
l'apprentissage local requis avant que l'exécution autonome puisse publier une
démonstration. La campagne 5/3/2 a donc été arrêtée avant exécution plutôt que
scriptée. `GATE-B-CORR-03 — Integrated Local Apprenticeship Initiation` remédie
maintenant ce blocker localement par la cognition normale et l'autorité
Teaching CIV-20 existante. Cette correction n'est pas Gate B re-evaluation #3 :
Gate B reste non acquise et `CIV-26` reste planifié.

## `operational-runbook`

- [`../pebblelab-3d-live-prototype.md`](../pebblelab-3d-live-prototype.md) est le
  runbook live canonique. Il décrit les gates, commandes, preuves et limites des
  verticales 3D actuellement acquises.
- [`GATE_B_CANDIDATE_EVALUATION.md`](GATE_B_CANDIDATE_EVALUATION.md) est le
  record d'acceptance post-CIV-25 : évaluations #1 et #2, verdict candidate
  `FAIL`, blockers, preuves et statuts publiés de `GATE-B-CORR-01` et
  `GATE-B-CORR-02`, puis remédiation locale CORR-03 en attente de
  re-evaluation #3.
  Il ne marque pas Gate B acquise et ne remplace pas la roadmap prospective.
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

- le plan directeur V2, ses anciens numéros prospectifs et les alias
  `NEXT-1`/`NEXT-2`, conservés uniquement pour relire l’histoire antérieure à
  la V3 Reuse-First ;
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
