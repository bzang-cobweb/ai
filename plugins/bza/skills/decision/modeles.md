# Modèles d'entrée du registre


Copier le modèle du type voulu dans `.ia/context/decisions/AAAA-MM-JJ-<sujet>.md`.

### Décision

```markdown
# `AAAA-MM-JJ` — <titre court de la décision>

- **Type** : décision
- **Question posée** : <ce qui a été demandé, en une phrase>
- **Réponse** : <ce qui a été tranché, sans interprétation>
- **Motif** : <pourquoi — c'est ce qui permettra de savoir quand la décision expire>
- **Portée** : <ce que la décision couvre, et ce qu'elle ne couvre pas>
- **Corollaires** : <ce qui en découle mécaniquement et que personne n'a énoncé>
- **Tranché par** : <humain | orchestrateur>
```

### Risque assumé — ne pas re-signaler

> Point identifié, évalué, et **accepté en connaissance de cause**. Sans cette
> entrée, chaque nouvel audit le remonte comme un défaut et le même arbitrage
> est repayé.

```markdown
# `AAAA-MM-JJ` — <le point>

- **Type** : risque assumé
- **Ce que c'est** : <description factuelle>
- **Pourquoi c'est assumé** : <le raisonnement>
- **Ce qui le rouvrirait** : <la condition qui rendrait le sujet à nouveau ouvert>
```

### Conséquence de conception assumée

> Effet d'une décision que personne n'avait énoncé, et qui se relirait dans six
> mois comme un bug à corriger. L'écrire au moment où il est accepté est la
> seule façon de ne pas le « corriger » par erreur plus tard.

```markdown
# `AAAA-MM-JJ` — <la conséquence>

- **Type** : conséquence de conception
- **Découle de** : <la décision d'origine>
- **Ce que ça implique concrètement** : <le comportement observable>
- **Ce n'est pas un défaut** : <pourquoi c'est voulu>
```

### Règle de blocage

> Toute règle qui bloque ou sérialise du travail porte son motif. Quand le motif
> tombe, la levée est une **nouvelle entrée** qui remplace celle-ci — sinon les
> agents réappliquent la règle depuis leurs mémoires.

```markdown
# `AAAA-MM-JJ` — <ce qui est bloqué>

- **Type** : règle de blocage
- **Règle** : <ce qui est bloqué ou sérialisé>
- **Motif** : <pourquoi>
- **Statut** : en vigueur | levée (voir l'entrée qui remplace celle-ci)
```
