---
name: backend
description: Implémenter le backend d'un projet Laravel (migrations, modèles, contrôleurs, services, contrat OpenAPI) fidèlement aux specs d'audit. À utiliser pour tout travail backend dans un projet Laravel.
---

# Backend Laravel

Implémenter le backend Laravel à partir des specs. Ne jamais inventer de schéma :
toujours travailler depuis une spec (`.ia/memory/spec_<concept>.json`). Absente
sur du code existant → la produire d'abord avec `bza-dev:auditor`.

## Démarche
- Créer migrations, modèles, contrôleurs et services selon la spec :
  `bza-laravel:create-migration`, `bza-laravel:create-model`,
  `bza-laravel:create-policy`, `bza-laravel:create-controller`,
  `bza-laravel:requete-service`, `bza-laravel:api-resource` pour toute réponse
  d'API qui renvoie un modèle.
- Commande Artisan : `bza-laravel:create-command` — traitement dans un service.
- Back-office Filament : `bza-laravel:filament-resource`, point d'entrée vers la
  table, le formulaire, l'infolist, les pages et les relation managers.
- Respecter noms de colonnes, types et valeurs d'enum de la source — aucune
  invention.
- Signaler tout écart entre la spec et ce qui est techniquement réalisable.
- Projet qui expose des routes HTTP : produire et rafraîchir `openapi.yaml` en le
  dérivant du code (`bza-laravel:generate-openapi`).

## Traits
Un trait vit dans un répertoire `Concerns`, à côté de ce qu'il sert, comme dans
Laravel : `app/Models/Concerns/`, `app/Policies/Concerns/`,
`Modules/<Module>/app/Concerns/`. Son nom dit ce qu'il apporte, sans suffixe
`Trait` : `HasUploadMedia`, `InteractsWithClipboard`, `IsCacheable`.

Un comportement commun à plusieurs classes y trouve son domicile au lieu d'être
recopié : le court-circuit administrateur des policies vit dans un seul
`HasBeforeAbility`, que chaque policy utilise.

## Règles absolues
- Aucun répertoire `Traits` : un trait est rangé dans `Concerns` et nommé sans suffixe `Trait`
- Jamais modifier une migration déjà exécutée — créer une nouvelle migration
- Noms de colonnes identiques à la spec, casse comprise
- Valeurs d'enum copiées mot pour mot depuis la spec
- Pas de `done` sans avoir lancé `php artisan migrate:status`
- Un `openapi.yaml` écrit ou retouché à la main est réputé faux — le régénérer
- Rapport de fin de tâche : `bza:rapport-de-tache`
