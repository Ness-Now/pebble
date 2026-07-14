# Pebble Civilization — Vision

## Statut et trajectoire

Ce document est la vision produit canonique de PebbleLab. Il décrit une cible à
long terme, pas l’état déjà implémenté.

`PebbleLab Society V1` est le premier jalon social observable. Il doit établir
les fondations d’une société simulée — information sociale, confiance,
coopération, tâches, persistance et population — sans être confondu avec la
cible produit complète.

`Medieval Civilization V1` est la cible produit principale à long terme : un
monde médiéval alternatif et préindustriel, approximativement inspiré des
contraintes sociales, matérielles et technologiques de la période 1200–1550,
mais laissant émerger des sociétés différentes.

Le stade post-K actuellement acquis reste volontairement plus étroit. Un agent
visible peut percevoir le World réel, arbitrer ses besoins à l’aide d’une
cognition et d’une mémoire influentes, verrouiller une cible, naviguer dans des
bounds, récolter transactionnellement des ressources naturelles, les porter,
les livrer au camp, consommer de la nourriture, subir la famine, se reposer,
financer un projet, placer en escrow ses matériaux et construire
transactionnellement un abri fixe qui devient son nouveau home. Ce résultat ne
constitue encore ni communication sociale, ni coopération, ni civilisation.

## Cible de simulation

La simulation ne code pas une féodalité obligatoire. Elle code les conditions
matérielles, informationnelles, écologiques et sociales qui peuvent produire,
selon l’histoire vécue :

- des seigneuries ;
- des clans ;
- des communes ;
- des guildes ;
- des républiques marchandes ;
- des monarchies ;
- des confédérations ;
- des théocraties ;
- des communautés plus égalitaires.

Aucune forme n’est une fin prédéterminée. Une société doit pouvoir se maintenir,
se transformer, se fragmenter ou disparaître à cause de décisions et de
contraintes observables.

## Doctrine de simulation

Les futures verticales respectent les principes suivants :

- simuler les causes plutôt que les résultats ;
- information locale, limitée et faillible ;
- aucune omniscience collective ;
- conservation matérielle stricte ;
- conséquences réelles des décisions ;
- plusieurs stratégies viables ;
- émergence encadrée par des règles sûres.

Le kernel déterministe décide ce qui est possible et valide chaque transition.
Les adapters observent et mutent le World à travers des boundaries explicites,
bornées, vérifiables et transactionnelles. Les rapports doivent permettre de
relier un résultat à ses observations, décisions, transactions et effets.

## Séparations conceptuelles

Les domaines suivants restent distincts, même lorsqu’ils interagissent :

```text
génétique
≠ développement
≠ éducation
≠ connaissance
≠ compétence
≠ culture
≠ profession
≠ statut social
```

Un trait hérité ne vaut pas savoir. Une éducation ne garantit pas la maîtrise.
Une profession ne résume pas un individu. Une appartenance culturelle ou un
statut ne détermine pas mécaniquement une croyance, une aptitude ou une loyauté.

## Individus et cycle de vie

À long terme, les individus combinent :

- des besoins concurrents ;
- des aptitudes différentes ;
- des personnalités imparfaites ;
- des erreurs et des informations incomplètes ;
- un apprentissage issu de la pratique et de la transmission ;
- des expériences individuelles qui influencent leurs décisions ;
- le vieillissement, la mort et des descendants.

Le cycle de vie doit produire des contraintes réelles de temps, de dépendance,
de soin et de succession. Il ne doit pas réduire les agents à des profils
optimaux ni transformer les descendants en copies de leurs parents.

## Compétences et professions

L’efficacité effective suit le modèle cible :

```text
théorie
+ maîtrise pratique
+ expérience réelle
= efficacité effective
```

Une profession n’est jamais une classe définitive. La spécialisation émerge du
temps limité, de l’apprentissage, des outils disponibles, des ateliers, de la
réputation, des obligations et de la transmission familiale. Une personne peut
changer de rôle, cumuler des activités, perdre une maîtrise faute de pratique
ou savoir expliquer une théorie sans savoir l’exécuter correctement.

## Savoir, croyance et transmission

La transmission future peut passer par :

- l’observation ;
- l’imitation ;
- l’enseignement parental ;
- l’apprentissage auprès d’un maître ;
- le bouche-à-oreille ;
- la pratique ;
- les livres ;
- les écoles ;
- les guildes ;
- les bibliothèques.

Chaque passage peut perdre, altérer ou enrichir l’information. Le modèle doit
distinguer :

```text
vérité du monde
≠ affirmation transmise
≠ compréhension de l’agent
≠ croyance de l’agent
≠ nouvelle transmission
```

La provenance devient décisionnellement pertinente dès qu’une affirmation peut
influencer une action. Les livres sont des objets matériels, copiés, transportés,
stockés, endommagés ou perdus ; les institutions du savoir ne sont utiles que
si des personnes peuvent comprendre et transmettre leur contenu.

## Société et appartenances

La simulation prévoit séparément :

- les foyers ;
- les familles ;
- les lignées ;
- les maisons et dynasties ;
- les guildes ;
- les religions ;
- les villages ;
- les cités ;
- les royaumes ;
- les nations ;
- d’autres organisations émergentes.

Ces ensembles peuvent se recouvrir sans partager le même propriétaire, la
même durée de vie ou les mêmes règles d’admission. Une appartenance officielle
n’équivaut jamais automatiquement à une loyauté réelle. Confiance, dette,
parenté, foi, intérêt, contrainte, réputation et expérience peuvent tirer un
individu dans des directions opposées.

## Économie et conservation

Tout futur domaine économique doit pouvoir rendre compte de l’invariant :

```text
ressources produites ou extraites
=
inventaires
+ stocks
+ entrepôts
+ marchandises en vente
+ matériaux construits
+ ressources consommées
+ pertes ou destructions
```

Les catégories et unités précises pourront évoluer, mais aucune opération ne
doit faire apparaître gratuitement une ressource. La trajectoire économique
visée est progressive :

```text
troc
→ dette
→ marché local
→ monnaie
→ halle ou entrepôt de marché
→ commerce régional
```

La propriété, la possession, la garde, la dette et le droit d’usage doivent
être distingués avant d’introduire des marchés crédibles. Prix, pénuries,
spécialisation et routes commerciales doivent découler des biens matériels,
des coûts, des risques, de l’information locale et de la logistique.

## Communication physique

Le proto-langage est une chaîne causale :

```text
intention
→ signal physique
→ perception
→ interprétation
→ vérification
```

La communication dépend de la proximité, de la portée, du bruit, de la mémoire
et des capacités de l’émetteur comme du récepteur. Elle peut utiliser gestes,
sons, sifflets, cloches, feux, messagers, marques, écriture et livres. Il
n’existe aucune communication longue distance gratuite : l’information doit
voyager par un support et peut arriver tard, déformée ou jamais.

## Technologies du monde

Les rails et la redstone sont des technologies internes à ce monde, pas des
exceptions extérieures à sa cohérence.

- Les rails apparaissent d’abord dans les usages miniers et logistiques.
- La redstone est un phénomène naturel découvert progressivement.
- Leur extraction et leur usage ont des coûts matériels.
- Leur conception exige un savoir spécialisé.
- Les installations demandent maintenance et pièces.
- Elles connaissent des pannes et des accidents.
- Leur diffusion est lente et socialement située.
- Le savoir nécessaire peut être perdu.

Le progrès n’est ni uniforme ni irréversible. Une invention utile ne devient
pas automatiquement disponible à toute la population.

## Place du LLM

Le LLM n’est pas le moteur permanent de la simulation. Le kernel déterministe
reste responsable des actions, des transactions, de la causalité et des
mutations du World.

Un futur LLM peut verbaliser, négocier, raconter, interpréter ou proposer. Toute
sortie est une proposition structurée validée par le moteur avant de produire
un effet. Le provider est interchangeable : aucun fournisseur, protocole réseau
ou modèle spécifique ne contamine les domaines de simulation.

La simulation doit fonctionner sans LLM. Cette capacité arrive tard, reste
optionnelle, explicitement gated et ne devient jamais propriétaire de l’état,
des transactions ou du World.

## Critère de réussite

`Medieval Civilization V1` ne sera pas accepté parce que des agents portent une
étiquette de métier, de royaume ou de religion. Il devra produire des histoires
rejouables et causalement explicables dans lesquelles des individus limités
apprennent, transmettent, coopèrent, échangent, fondent ou quittent des groupes,
construisent des institutions et affrontent les conséquences matérielles de
leurs décisions, sans résultat social imposé à l’avance.
