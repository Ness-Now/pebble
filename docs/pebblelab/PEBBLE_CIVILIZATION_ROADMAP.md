# Pebble Civilization — Roadmap prospective

## Statut

Cette roadmap est l’autorité prospective canonique. Elle définit un ordre de
risque et de dépendance, sans figer prématurément les API des domaines futurs.
L’ancienne [`ROADMAP.md`](ROADMAP.md) reste le journal historique détaillé des
phases terminées.

## État actuel vérifié

Le point de départ est le HEAD post-K :

- construction individuelle autonome acquise dans la verticale bornée de
  l’abri fixe ;
- perception réelle, cognition, mémoire influente, target lock, navigation,
  récolte naturelle transactionnelle, inventaire, livraison, stock, faim,
  consommation, famine, fatigue, repos, financement, escrow et nouveau home
  acquis dans leurs contrats actuels ;
- information sociale causale et confiance dirigée acquises dans leur verticale
  bornée ;
- sons locaux, gestes de pointage et perception physique imparfaite acquis dans
  une verticale bornée ; tâches partagées et coopération matérielle bornée
  acquises pour la construction d'un abri ;
- registre local de population borné, admission physique d'un migrant,
  identité dynamique monotone, checkpoint/replay population v2 et reprise
  mid-route acquis sous gate explicite, avec un maximum de huit agents actifs ;
- métriques collectives bornées de `settlement-main`, pulse macro déterministe
  tous les quatre ticks, classifications administratives, historique borné et
  checkpoint/replay v3 acquis sous gate explicite. Tous les agents continuent
  à recevoir leur tick micro complet : aucune coarse execution et aucun agent
  hors écran ne sont introduits ;
- écologie alimentaire locale bornée acquise sous gate explicite : deux patches
  sauvages adossés à des habitats World réels, rendement limité, épuisement,
  régénération déterministe, cueillette transactionnelle, conservation double,
  pression de subsistance administrative et checkpoint/replay v4 ;
- mortalité par famine bornée acquise sous gate explicite : transition
  terminale atomique, death records durables, ressources terminales
  comptabilisées, sortie de population et retrait du probe, puis remplacement
  physique par un nouvel AgentID monotone avec checkpoint/replay v5 ;
- âge démographique déterministe distinct de `ticksAlive`, stages
  `newborn`/`juvenile`/`mature` et reproduction locale bornée acquis sous gate
  explicite : deux progéniteurs historiques, site World validé en lecture
  seule, AgentID monotone et checkpoint/replay v6 ;
- parenté historique durable acquise sous gate explicite : personnes
  historiques sans statut vivant/résident dupliqué, parentages canoniques
  immuables, index enfant/parents/enfants/fratries dérivés et
  checkpoint/replay v7 ; le kernel pur `PebbleAgents` n'accède pas au World et
  la preuve live n'observe aucun appel ou événement de mutation de bloc/World ;
- foyers résidentiels bornés, périodes d'appartenance historiques et home
  partagé acquis sous gate explicite avec checkpoint/replay v8 ; dependent care
  matériel et comportemental acquis sous gate explicite avec checkpoint/replay
  v9, politique de capacités par stage et alimentation conservée depuis
  l'inventaire du caregiver ou le camp stock existant ;
- compétences pratiques individuelles acquises par succès matériels causaux
  dans quatre domaines bornés (`foraging`, `materialHandling`, `construction`,
  `caregiving`) et task matching coopératif réellement influencé par la maîtrise,
  avec checkpoint/replay v10 sous gate explicite.

Le langage libre, le forwarding, l'enseignement, les professions, l'économie du travail, la
persistance complète des agents, le replay complet du World, la grande
population, le vieillissement physique, les maladies, les familles,
l'émigration et le cycle de vie complet ne sont pas acquis.

Ce stade ne doit pas être décrit comme une civilisation déjà implémentée.

## Jalons produit

### PebbleLab Society V1

Society V1 devient le premier jalon social observable et intermédiaire vers la
cible principale. Il comprend notamment :

- information sociale locale et causale ;
- confiance dirigée ;
- coopération ;
- tâches et responsabilités partagées ;
- persistance et checkpoints ;
- replay causal ;
- population et migration ;
- métriques collectives.

Ce jalon valide des interactions sociales réelles. Il ne prétend pas encore
livrer familles, culture cumulative, marchés, institutions ou histoire
médiévale complète.

### Medieval Civilization V1

`Medieval Civilization V1` est la cible produit principale à long terme. Son
acceptation dépend de systèmes matériels, sociaux, générationnels et culturels
intégrés, reproductibles et observables, pas d’étiquettes scénarisées.

## Prochain enchaînement obligatoire

1. `CIV-00 — Documentation and AGENTS Rebaseline`
2. `CIV-01 — Behavior-Preserving Runtime Modularization`
3. `CIV-02 — Stable Identity, Simulation Clock and Causal Ledger`
4. `CIV-03 — Social Information and Directed Trust V1`

`CIV-01` est terminé et validé localement : le runtime existant a été
modularisé sans changement de comportement. `CIV-02` est également terminé et
validé localement : les fondations d’identité stable, d’horloge simulée et de
causalité déterministe sont acquises sans ouvrir la persistance ni la
communication. `CIV-03` est terminé et validé localement : l’information
sociale causale et la confiance dirigée sont acquises, sans forwarding,
coopération ni persistance. `CIV-04` est terminé et validé localement : sons,
gestes et perception imparfaite sont acquis dans un canal local borné, sans
langage libre ni forwarding. `CIV-05` est terminé et validé localement : une
tâche de livraison de matériaux peut être offerte, acceptée et accomplie par
un helper distinct du builder, avec contribution matérielle conservée et
fiabilité dirigée, sans profession ni économie du travail. `CIV-06` est
terminé et validé localement : les checkpoints agents versionnés et bornés,
le chargement restart-safe et le replay causal pur du kernel sont acquis sous
gate explicite. Cette verticale n'est ni un snapshot complet du World, ni un
autosave, ni un framework général de migration de schéma. `CIV-07` est
également terminé et validé localement : les trois fondateurs historiques
peuvent initialiser `settlement-main`, un migrant `agent_3` peut être admis
depuis `outside-north`, marcher physiquement jusqu'au point d'accueil et
devenir résident après un restart mid-route. La population reste bornée à huit
membres, sans naissance, mort, reproduction, famille, émigration ou simulation
hors écran. `CIV-08` est terminé et validé localement : le settlement possède
désormais une vue macro administrative à cadence bornée, persistée et
rejouable, sans rétroaction sur les décisions, les mouvements ou les
transactions micro. Les fixtures headless contrôlées couvrent les cinq
conditions du vrai classificateur (`incomplete`, `strained`, `transitioning`,
`active`, `stable`) ; la preuve live historique reste correctement `strained`
aux trois pulses parce que les urgences micro réelles sont prioritaires. La
verticale `CIV-09` est terminée et validée localement : quatre résidents
exploitent des patches alimentaires locaux bornés détectés en lecture seule
dans le World, avec compétition déterministe, rendement limité, épuisement,
régénération, consommation et pression collective sans rétroaction cognitive.
Le checkpoint/replay v4 conserve exactement patches, horloges et bilans. Cette
V1 n'introduit ni agriculture, saisons, animaux ni eau. La verticale `CIV-10`
est terminée et validée localement : la famine peut maintenant finaliser une
mort à une frontière de tick déterministe, retirer atomiquement le résident de
la population active et conserver son death record ainsi que ses ressources
dans un compte terminal borné. Le probe correspondant est retiré, puis la
capacité libérée permet l'admission physique d'`agent_4` sans réutiliser aucun
identifiant. Le checkpoint/replay v5 couvre les reprises pré- et post-mortem.
Le record terminal v5 fige les compteurs cognitifs et matériels, et la preuve
contractuelle couvre l'ordre causal létal exact ainsi que le nettoyage des
références actives de chaque verticale sans supprimer leurs historiques.
Cette V1 ne crée aucun cadavre et n'ouvre ni vieillissement, maladie,
reproduction, famille ou héritage. `CIV-11` est terminé et validé localement :
le lifecycle dérive un âge démographique de l'horloge simulée, conserve
`ticksAlive`, classe les membres en `newborn`, `juvenile` et `mature`, puis
peut produire une naissance locale atomique dans la limite de population. La
preuve sélectionne deux progéniteurs historiques sans créer couple ni foyer,
valide un site World en lecture seule, crée `agent_4` avec un ordinal monotone
et restaure exactement le plan, la naissance et la maturation via le schéma
checkpoint/replay v6. Cette V1 n'introduit aucun sexe, grossesse, famille,
génétique ou héritage. `CIV-12A — Durable Kinship Graph V1` est terminé et
validé localement : l'archive kinship devient l'autorité historique unique,
les champs `progenitorIDs` lifecycle/birth restent des projections contrôlées,
les fondateurs et migrants sont des racines à parentage inconnu, et mort,
migration, checkpoint, restart et replay ne suppriment aucun lien. L'archive
bornée est fail-closed et le schéma v7 n'encode aucun index inverse. Le restore
v7 rapproche intégralement les événements causaux encore retenus avec chaque
parentage et n'accepte une référence absente que si sa séquence est prouvée
antérieure à la fenêtre retenue. La preuve de hardening conserve les traces et
octets v1-v6 gate-off, force après validation du candidat une défaillance
physique newborn réservée au harnais jetable, puis vérifie l'absence de toute
publication session, recorder, ordinal, événement ou probe. Cette verticale
n'introduit ni foyer, care, propriété, héritage, génétique ou cognition newborn
supplémentaire. `CIV-12B — Households and Membership V1` est terminé et validé
localement : `AgentSimulationSession` possède l'unique archive household, les
foyers monotones conservent une ancre de résidence sans posséder le terrain ni
les ressources, et les périodes historiques déterminent l'unique appartenance
courante. L'activation explicite v7→v8 groupe les résidents par `homePosition` ;
formation, déplacement, naissance, admission migratoire et mortalité publient
leurs changements de membership, home et causalité dans une même candidate.
Les foyers vides sont dissous sans réutilisation d'ID, tandis que kinship reste
indépendant. Checkpoint, restart et replay v8 restaurent exactement les foyers,
les périodes et les homes, sans mutation World. La dernière tranche interne de
`CIV-12` ajoute maintenant le dependent care : newborns sans cognition, action
ou mouvement autonomes, juveniles limités, assignments déterministes vers un
caregiver mature, besoins explicites et engagements prioritaires. La nourriture
fournie est débitée exactement une fois de l'inventaire réel du caregiver puis,
à défaut, du `campStock`; un manque reste `unmet`. Les changements de household,
la naissance et la mortalité revalident ou ferment les assignments dans leur
transaction candidate, sans modifier kinship. Le schéma v9, le restart et le
replay conservent exactement care, lifecycle et households ; les versions v1 à
v8 restent inchangées lorsque la gate care est désactivée.

`CIV-12 — Kinship, Households and Dependent Care V1` est terminé localement.
Il n'introduit ni adoption, mariage, propriété, stock household, enseignement,
compétences ou héritage.

`NEXT-1 — Practice-Based Skills and Task Matching V1` est terminé et validé
localement. Les niveaux sont dérivés de succès matériels réellement publiés,
sans crédit rétroactif, XP temporel, talent inné, profession ni bonus de
rendement. Les historiques divergents influencent une vraie sélection de helper
après les contraintes d'éligibilité et de sécurité. Le schéma v10 persiste les
totaux et preuves bornées ; restart et replay reproduisent les causes sans API
publique d'ajout d'XP, tandis que les versions v1 à v9 restent inchangées avec
la gate skills désactivée.

Prochaine verticale prospective :
`NEXT-2 — Demonstration, Teaching and Apprenticeship V1`.

## Grands programmes ultérieurs

L’ordre précis sera réévalué à chaque preuve, mais les programmes structurants
sont :

1. coopération, tâches et rôles ;
2. persistance, checkpoints et replay ;
3. population et simulation multi-échelle ;
4. écologie et subsistance préindustrielle ;
5. cycle de vie, reproduction et génétique ;
6. foyers, familles, lignées et héritage ;
7. compétences, apprentissage et professions ;
8. propriété, production et conservation ;
9. troc, dette, monnaie et marchés ;
10. proto-langage et communication physique ;
11. connaissances, livres, archives et bibliothèques ;
12. cultures distribuées et mémoire collective ;
13. guildes et institutions ;
14. religions et systèmes de croyances ;
15. territoires et structures politiques ;
16. diplomatie, conflits et guerre ;
17. technologies médiévales, rails et redstone ;
18. training bridge et politiques apprises ;
19. provider LLM local et interchangeable ;
20. modes Dieu ;
21. Genesis Run ;
22. Medieval Civilization V1 acceptance.

Ces noms définissent des problèmes produit et des dépendances. Ils n’annoncent
ni API finale, ni modèle de données final, ni capacité déjà implémentée.

## Dépendances incontournables

- Pas de grande population avant identité stable et spatialisation.
- Pas de générations avant horloge, persistance et parenté versionnée.
- Pas d’héritage avant propriété.
- Pas de marché avant propriété et conservation.
- Pas de culture cumulative avant transmission et persistance.
- Pas de bibliothèque utile avant livres matériels et savoir structuré.
- Pas de guerre crédible avant groupes, territoires et logistique.
- Pas de LLM décisionnaire direct.
- Pas de Genesis Run avant persistance, cycle de vie, apprentissage et
  communication.

S’ajoutent les invariants permanents : aucun raccourci d’omniscience, aucune
création gratuite de biens, aucune mutation World non autorisée, aucune seconde
source de vérité cognitive et aucune feature expérimentale active par défaut.

## Règle de livraison

Chaque bloc futur doit produire au moins un des résultats suivants :

- un nouveau comportement observable ;
- une réduction directe d’un risque bloquant ;
- une fondation indispensable du bloc suivant ;
- une amélioration importante du debug ou du replay.

Une verticale livre ensemble son contrat, son implémentation, ses preuves
focalisées, ses régressions et sa documentation. Une mission purement
documentaire reste exceptionnelle et doit réduire un risque réel, comme
`CIV-00` réduit l’ambiguïté stratégique et documentaire avant la prochaine
mission technique.
