# PebbleLab — maquette 3D live

## Statut

La maquette V0 rend trois agents PebbleLab observables dans l’application Pebble. Elle expose leur cognition partagée, leur perception locale, leurs déplacements cardinaux sûrs et l’influence de leur mémoire de mouvement. Le terrain et les sauvegardes restent inchangés.

## Prérequis et lancement

Depuis la racine du dépôt :

```bash
PEBBLELAB_APP_AGENTS=1 \
PEBBLELAB_APP_AGENTS_MOVE=1 \
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
- aucun pathfinding long, route, waypoint ou steering ;
- aucune mutation de terrain, mining ou construction ;
- aucune société ou communication entre agents ;
- aucune persistance agent ;
- aucun contrôleur autonome du joueur.

Les comportements cognitifs supplémentaires, la planification longue, les interactions terrain et la persistance sont explicitement reportés après la Phase F.

## Transactional interaction G1

La primitive G1 est une fixture manuelle, non autonome, protégée par `PEBBLELAB_APP_AGENTS_INTERACT=1` en plus de la gate agents. Sur une session active, en pause et avec le mouvement désactivé, `/lab interaction setup` place un unique bloc `amethyst_block` adjacent à l’agent focalisé dans une sandbox de rayon horizontal 8 autour de l’anchor. `/lab interaction harvest` retire ce bloc, crédite exactement une `sandboxResource` dans l’inventaire partagé borné et écrit la mémoire `resource_harvested`. `/lab interaction status` expose le ledger, l’inventaire, l’outcome et le rollback.

Le bloc original est conservé dans un ledger applicatif puis restauré par stop, clear, reset, redémarrage, changement de World ou terminaison. Une erreur après mutation déclenche un rollback vérifié avant toute publication de la copie de session. G1 ne sélectionne aucune cible cognitive, ne crée aucun goal de collecte et ne rend pas la récolte autonome ; ces branchements sont réservés à G2.
