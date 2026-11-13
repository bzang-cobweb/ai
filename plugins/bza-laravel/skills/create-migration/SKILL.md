---
name: create-migration
description: Créer une migration Laravel fidèle à une spec de l'auditor.
---

## Quand utiliser ce skill
Quand une tâche demande de créer ou modifier une table de base de données.

## Procédure
1. `recall "spec_<concept>"` → lire `stack.colonnes` et `incertitudes`
2. Vérifier dans `database/migrations/` qu'aucune migration pour cette table n'existe déjà
3. `php artisan make:migration create_<table>_table`
4. Transcrire chaque colonne : nom exact (casse comprise), type, nullable, défaut, enum values
5. Ajouter les index mentionnés dans la spec (`unique`, `index`, `foreign`)
6. `php artisan migrate --pretend` → vérifier la syntaxe sans exécuter
7. `php artisan migrate` → exécuter
8. `php artisan migrate:status` → confirmer que la migration est bien marquée `Ran`

## Règles absolues
- Noms de colonnes identiques à la spec, casse comprise
- Valeurs d'enum copiées mot pour mot depuis la spec
- Jamais modifier une migration déjà exécutée — toujours créer une nouvelle
- Colonne citée dans `incertitudes` → **Bloquer la tâche** (« Colonne incertaine : <nom> ») avant de continuer
