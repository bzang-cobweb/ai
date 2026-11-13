---
name: audit-source
description: Produire la spec d'un concept métier — enveloppe commune à tous les types de projet.
---

## Quand utiliser ce skill
Quand une tâche demande de cartographier le projet ou d'auditer un concept
métier (une table et ses écrans, une fonctionnalité, un domaine).

## La carte : `spec_index`
Premier livrable de chaque run, avant toute spec :

```json
{
  "concepts": [
    { "nom": "organisations", "sources": ["app/Models/Organisation.php", "resources/views/organisations/..."] }
  ],
  "non_rattaches": ["chemin/fichier_orphelin.php"]
}
```

**Écrire la mémoire** `spec_index` — le lead dispatche les audits par
concept à partir de cette carte.

## Procédure par concept
1. Lire **tous** les fichiers `sources` du concept dans leur totalité — jamais
   auditer partiellement
2. Remplir l'enveloppe ci-dessous ; la section `stack` suit le skill d'audit de
   la stack (`audit-laravel`, ...) s'il existe, sinon reste vide et l'absence
   est signalée dans `incertitudes`
3. **Écrire la mémoire** `spec_<concept>` — confirmer avant de marquer done

## L'enveloppe — contrat garanti
Chaque spec contient ces champs, quel que soit le type de projet.
**Un champ absent signifie « non audité », jamais « inexistant ».**

```json
{
  "concept": "organisations",
  "sources": ["app/Models/Organisation.php"],
  "fonctionnalites": ["list", "create", "edit", "export"],
  "acces": {
    "list": ["staff", "superadmin"],
    "create": ["superadmin"]
  },
  "regles_metier": ["..."],
  "incertitudes": ["Statut_Rapport : valeur par défaut non trouvée dans la source"],
  "stack": {}
}
```

- `fonctionnalites`, `acces`, `regles_metier` — noms figés : tester, frontend
  et backend les lisent tels quels
- `incertitudes` — **seul** endroit où exprimer un doute : une entrée par
  valeur incertaine, avec le champ concerné et la raison
- `stack` — section libre définie par le skill d'audit de la stack

## Règles absolues
- Ne jamais déduire ce qui n'est pas explicitement dans la source
- Valeur incertaine → entrée dans `incertitudes`, jamais de flag ailleurs
- Fichier illisible → le consigner dans `incertitudes` ; concept entier
  illisible → **Bloquer la tâche**
- Un run = un audit frais : écraser les specs existantes sans les lire
