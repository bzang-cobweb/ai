---
name: visual-qa
description: Comparer visuellement l'interface implémentée avec sa référence (site existant, frame Figma ou captures adoptées).
---

## Quand utiliser ce skill
Quand une tâche demande de valider visuellement une vue ou un composant implémenté.

## Procédure
La demande désigne la **référence** : l'URL d'un site existant, une frame Figma, ou des
captures déjà adoptées. Si aucune n'est désignée, la demander plutôt que d'en choisir une.

1. Ouvrir la référence → lister chaque élément visible :
   - Titre, libellés, colonnes du tableau
   - Filtres, champs de formulaire
   - Boutons et actions disponibles
   - Messages d'état (vide, erreur, succès)
2. Ouvrir la version **implémentée** → comparer élément par élément
3. Répéter pour chaque rôle si les accès diffèrent (`acces` dans la spec)
4. Produire le rapport ci-dessous

## Format du rapport
```
VQA — <nom de la vue>
Référence  : <URL, frame Figma ou capture>
URL cible  : <url>
Rôles testés : <liste>

Bloquants : <n>
- <élément manquant ou incorrect — reproductible>

Majeurs : <n>
- <dégradation significative>

Mineurs : <n>
- <amélioration souhaitable>
```

## Règles absolues
- Ne pas émettre de go si un élément fonctionnel est absent
- Tout écart doit être reproductible — URL + rôle + action précise
- Ne jamais supposer : vérifier dans le navigateur, pas dans le code
