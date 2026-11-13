---
name: create-model
description: Créer un modèle Eloquent selon la spec de l'auditor.
---

## Quand utiliser ce skill
Quand une tâche demande de créer ou compléter un modèle Eloquent.

## Procédure
1. `recall "spec_<concept>"` → lire la spec complète
2. `php artisan make:model <Nom>`
3. Définir les propriétés de base :
   - `$table` — si le nom de table diffère de la convention Laravel
   - `$primaryKey` — si la clé primaire n'est pas `id`
   - `$keyType` — si la PK est une chaîne
   - `$incrementing` — `false` si la PK n'est pas auto-incrémentée
   - `$timestamps` — `false` si la table n'a pas `created_at`/`updated_at`
4. Définir `$fillable` avec exactement les colonnes listées dans `stack.colonnes` (hors PK et timestamps)
5. Définir `$casts` selon les types de `stack.colonnes` : `enum`, `boolean`, `datetime`, `array`...
6. Ajouter les relations (`belongsTo`, `hasMany`, `belongsToMany`) selon `stack.dependances` dans la spec
7. Ajouter les scopes uniquement si la spec mentionne des filtres récurrents

## Règles absolues
- `$fillable` correspond exactement aux colonnes de `stack.colonnes` — ni plus, ni moins
- `$casts` reflète les types définis dans la spec
- Ne pas ajouter de relations absentes de la spec
- Ne pas ajouter de méthodes métier — c'est le rôle du service ou du contrôleur
