# PebbleLab — maquette 3D live

## Statut

La maquette V0 rend trois agents PebbleLab observables dans l’application Pebble. Elle expose leur cognition partagée, leur perception locale, leurs déplacements cardinaux sûrs et l’influence de leur mémoire de mouvement. Le terrain et les sauvegardes restent inchangés.

## Prérequis et lancement

Le cycle de développement et les validations permanentes sont décrits dans [`docs/pebblelab/DEVELOPMENT_WORKFLOW.md`](pebblelab/DEVELOPMENT_WORKFLOW.md). Pour une session Phase J reproductible qui n'expose aucun monde personnel, commencer par `scripts/verify-pebblelab-live.sh --dry-run`, puis lancer explicitement `scripts/verify-pebblelab-live.sh`. Les options `--economy` et `--h2` conservent respectivement les preuves Phase I et H2. Ce lanceur réutilise les hooks existants d'autoload, de monde neuf, de commandes et de capture, impose un monde jetable préfixé `PebbleLab-Disposable-` avec seed fixe et conserve monde, traces et captures sous un home temporaire isolé. La vérification visuelle de la capture reste manuelle.

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
/lab economy <setup|auto on|auto off|status|clear>
/lab survival <on|off|status>
/lab status
/lab focus <agentId|next>        /lab next
/lab follow <agentId|focus|next|off>
/lab overlay <off|compact|full>
```

`/lab overlay on` reste un alias de `compact`. L’overlay compact est destiné aux démonstrations ; `full` expose le diagnostic détaillé. Sans commande explicite, F3 sélectionne le mode full et la variable d’environnement sélectionne compact.

`follow focus` suit dynamiquement l’agent focalisé ; un identifiant suit une cible fixe. Le follow ne déplace jamais le joueur : il oriente seulement sa vue. Le joueur reste libre de se déplacer.

## Arrêt propre et inspection

Utiliser `/lab demo stop`, `/lab stop` ou `/lab clear`. Les probes transitoires sont retirées, le follow est désactivé et un résumé de session est écrit lorsque les traces sont actives. `/lab status` confirme ensuite que la session est inactive. Les probes ont `shouldSaveToChunk == false` et `persistent == false` ; aucun agent n’est restauré lors d’un lancement ultérieur.

## Garde-fous et limitations V0

- exactement trois agents ;
- mouvement cardinal single-step ;
- perception World en rayon 1 ;
- mémoire bornée et distance au home toujours inférieure ou égale à 8 ;
- aucune destination partagée et aucun dangerous drop exécuté ;
- navigation de ressource bornée au rayon 8, route cardinale et un pas au plus par tick ;
- seule la fixture transactionnelle peut être mutée puis restaurée ; aucun bloc naturel, mining général ou construction ;
- aucune société ou communication entre agents ;
- aucune persistance agent ;
- aucun contrôleur autonome du joueur.

Les comportements cognitifs supplémentaires, la planification longue, les interactions terrain et la persistance sont explicitement reportés après la Phase F.

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
