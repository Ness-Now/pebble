# GATE-B-CONVERGENCE-01A — implementation foundation closure

`GATE-B-CONVERGENCE-01A` récupère et ferme le travail d'implémentation
interrompu de `GATE-B-CONVERGENCE-01`. Cette mission n'exécute aucune vague de
progressive soak et ne constitue pas Gate B re-evaluation #5.

Le baseline canonique reste
`eaed4ce1d0a8c151316ddd84e8076813b3079c94`. Gate B re-evaluation #4 reste un
`FAIL` historique, Gate B n'est pas acquise et `CIV-26` n'est pas commencé.

## Périmètre fermé

Le bootstrap d'acceptance est role-neutral : aucun planner, responsable
livestock, worker sauvage, travail productif, plan agriculture, apprentissage,
skill ou profession n'est préassigné. Chaque habitant reçoit uniquement le
même kit physique borné ; l'agriculture et le livestock doivent émerger des
observations et de la cognition normales.

Trois blockers produit ont été corrigés, sur un budget maximal de quatre :

1. `B-BLOCKER-MOVEMENT-HOME-BOUNDARY`, incluant son extension 3D : la
   destination Core exacte est validée avant toute mutation et un pas `7 → 9`
   est refusé avec zéro mutation physique ;
2. `B-BLOCKER-AUTONOMOUS-LIVESTOCK-INITIATION` : l'initiation part
   d'observations locales fraîches, utilise l'autorité CIV-24 et atteint le
   résultat physique existant sans acteur assigné par le harnais ;
3. `B-BLOCKER-CHECKPOINT-PHYSICAL-CUSTODY` : un checkpoint ne détruit ni ne
   recrée un embodiment cohérent. Les probes existantes et leur custody sont
   réutilisées exactement ; toute incohérence d'identité ou de position est
   refusée avant mutation World.

Le codec durable trie aussi les compteurs multi-stratégies wild-subsistence
avant encodage. Le schéma checkpoint reste `v18` et aucun format SaveDB n'est
modifié.

## Harness de convergence

`scripts/verify-pebblelab-gate-b-convergence.sh` et
`scripts/gate_b_convergence_evidence.py` préparent la mission séparée de
progressive soak. Les preuves sont liées au HEAD et au digest de configuration,
refusent les rerolls et distinguent :

```text
PASS
FAIL
NOT_RUN
NOT_REACHED
HARNESS_INVALID
TIMEOUT
```

Les champs porteurs manquants, un HEAD périmé, un timeout, une trace tronquée,
un checkpoint non restauré ou une équation de custody incomplète ne peuvent
pas devenir `PASS`.

## Disposition

Le résultat maximal de cette mission est :

```text
IMPLEMENTATION FOUNDATION READY FOR PROGRESSIVE SOAK
```

Il n'implique ni `READY FOR GATE B RE-EVALUATION #5`, ni acquisition de Gate B.
Les vagues `10 × 800`, `3 × 2400`, déterminisme `1600 A/B`, stress `3600` et
le live final de 120 secondes restent explicitement non exécutés ici ; ils
appartiennent à `GATE-B-CONVERGENCE-01B`.
