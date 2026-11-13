---
name: create-controller
description: Créer un contrôleur Laravel selon les fonctionnalités et accès définis dans la spec.
---

## Quand utiliser ce skill
Quand une tâche demande de créer ou compléter un contrôleur.

## Procédure
1. `recall "spec_<concept>"` → lire `fonctionnalites` et `acces`
2. `php artisan make:controller <Nom>Controller`
3. Créer une méthode par fonctionnalité de `fonctionnalites`. Les fonctionnalités
   CRUD suivent les noms de ressource Laravel :
   - `list` → `index()`
   - `create` → `create()` + `store()`
   - `edit` → `edit()` + `update()`
   - `delete` → `destroy()`

   Toute autre fonctionnalité donne une méthode à son nom : `search()`, `print()`,
   `export()`, `import()`, `publish()`, `duplicate()`…
4. Appliquer les contrôles d'accès depuis `acces`, **sur la route** :
   - action qui concerne un modèle : `bza-laravel:create-policy` — une policy
     par modèle, une méthode par action, la garde `can:` sur chaque route ;
   - autre action : une capacité déclarée par `Gate::define()` et posée par
     `->can()`, ou un middleware posé sur la route ou sur son groupe :
     ```php
     Gate::define('viewReports', fn (User $user) => $user->hasPermissionTo('view reports'));

     Route::get('reports', [ReportController::class, 'index'])->can('viewReports');
     Route::get('reports/print', [ReportController::class, 'print'])->can('viewReports');
     ```
   - `abort_unless()` en début de méthode, uniquement pour un contrôle qui dépend
     des données reçues ou d'un état calculé, qu'une route ne peut pas trancher.

   Le contrôleur ne déclare aucun middleware (ni `HasMiddleware`, ni
   `$this->middleware()`) et n'hérite pas de `Illuminate\Routing\Controller` :
   ce dernier fait construire le contrôleur avant les middlewares de la route.
   L'accès de chaque action se lit dans `php artisan route:list`
5. Pour chaque méthode qui reçoit des données (`store()`, `update()`, `search()`,
   `print()`, toute autre action) : appliquer `bza-laravel:requete-service` —
   requête personnalisée toujours, service optionnel qui reçoit les données validées
6. Pour chaque méthode d'API qui renvoie un modèle ou une liste de modèles :
   appliquer `bza-laravel:api-resource` — sa ressource `JsonResource`, ou la
   collection de cette ressource
7. Ajouter les routes dans `routes/web.php` ou `routes/api.php` selon le contexte
8. Nommer les routes selon les conventions existantes dans le projet

## Règles absolues
- Une méthode par fonctionnalité de `fonctionnalites`, quel que soit son nom — pas de méthode sans fonctionnalité
- Contrôles d'accès identiques à `acces` dans la spec — pas d'improvisation
- L'accès se pose sur la route ; dans le contrôleur, seul `abort_unless()` subsiste, pour un contrôle qui dépend des données
- Nommer les routes en suivant les conventions déjà en place dans le projet
- Aucune validation dans le contrôleur — les données soumises passent par une requête personnalisée
- Pas de logique métier dans le contrôleur — déléguer à un service si nécessaire, selon `bza-laravel:requete-service`
- Jamais un modèle ou une collection Eloquent dans une réponse JSON — sa ressource, selon `bza-laravel:api-resource`
