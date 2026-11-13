---
name: create-policy
description: Dans un projet Laravel, écrire la Policy d'un modèle — une méthode par action — et l'appliquer à chaque route qui agit sur ce modèle. À utiliser dès qu'une route, un contrôleur ou une action concerne un modèle.
---

## Quand utiliser ce skill
Dès qu'une action concerne un modèle : création d'un contrôleur, ajout d'une
route ou d'une action (`search`, `print`, `publish`…), sur un modèle qui a déjà
une policy ou non. Une action qui ne concerne aucun modèle est gardée sur la route
par une capacité `Gate::define()` ou un middleware (`bza-laravel:create-controller`).

## Le principe
Chaque modèle a **sa** policy, et elle contient **toutes** les actions qui le
concernent. Chaque route qui agit sur ce modèle applique la policy. Pour ces
actions, le contrôleur ne contrôle pas l'accès lui-même.

## Procédure
1. **Créer ou compléter la policy** — une par modèle :
   `php artisan make:policy <Modèle>Policy --model=<Modèle>`. Le stub renvoie
   `false` partout : une méthode non écrite refuse.
2. **Une méthode par action** — chaque action qui concerne le modèle a sa méthode :

   | Action | Méthode de policy |
   |---|---|
   | `index` | `viewAny(User $user)` |
   | `show` | `view(User $user, Post $post)` |
   | `create`, `store` | `create(User $user)` |
   | `edit`, `update` | `update(User $user, Post $post)` |
   | `destroy` | `delete(User $user, Post $post)` |
   | toute autre action | méthode au nom de l'action : `publish(User $user, Post $post)`, `search(User $user)`, `print(User $user, Post $post)` |

   Une action qui suit la règle d'une autre délègue, pour que la règle n'ait
   qu'un domicile :
   ```php
   public function search(User $user): bool
   {
       return $this->viewAny($user);
   }
   ```
   Les méthodes du stub sans action correspondante (`restore`, `forceDelete` sans
   suppression douce) sont retirées. Terminé quand chaque action du contrôleur
   qui concerne le modèle a sa méthode.
3. **Écrire les règles** depuis `acces` de la spec. Une règle absente de la spec
   bloque la tâche : elle se remonte (`bza:lois/escalade.md`), on ne l'invente pas.
4. **Séparer la requête Filament des autres** (projet avec Filament) — chaque
   méthode de la policy écrit deux règles nommées : celle du back-office
   Filament, et celle des autres requêtes (site, API, commande). Filament consulte ces mêmes méthodes pour ses
   vues et ses actions (`bza-laravel:filament-resource`).
   ```php
   public function update(User $user, Post $post): bool
   {
       if (Filament::isServing()) {
           // Back-office : édition réservée aux éditeurs.
           return $user->hasPermissionTo(PermissionEnum::EDIT_POSTS);
       }

       // Site et API : l'auteur modifie son propre article.
       return $post->author()->is($user);
   }
   ```
   Une branche sans accès retourne `false` explicitement, avec son motif en
   commentaire. Deux branches qui partagent une règle appellent la même méthode
   privée, mais restent écrites toutes les deux.
5. **Accès invité** — typer `?User` uniquement si la spec ouvre l'action aux
   invités, et traiter `null` avant tout appel sur `$user`. Sans `?User`,
   Laravel refuse l'invité avant d'entrer dans la méthode.
6. **Enregistrer** — l'auto-découverte associe `…\Models\Post` à
   `…\Policies\PostPolicy`. Hors de cette convention (modules, autre dossier),
   déclarer `Gate::policy(Post::class, PostPolicy::class)` au même endroit que
   les autres policies du projet.
7. **Appliquer à chaque route** :
   ```php
   Route::get('posts/search', [PostController::class, 'search'])->can('search', Post::class);
   Route::post('posts/{post}/publish', [PostController::class, 'publish'])->can('publish', 'post');

   Route::resource('posts', PostController::class)
       ->middlewareFor('index', 'can:viewAny,'.Post::class)
       ->middlewareFor('show', 'can:view,post')
       ->middlewareFor(['create', 'store'], 'can:create,'.Post::class)
       ->middlewareFor(['edit', 'update'], 'can:update,post')
       ->middlewareFor('destroy', 'can:delete,post');
   ```
   Le second argument nomme le paramètre de route (`'post'`) pour une action
   sur un objet, ou la classe pour une action sans objet. Sur une route imbriquée
   qui touche aussi le parent, chaque modèle est gardé :
   `->can('update', 'category')->can('create', Post::class)`. Les `->can()`
   chaînés s'additionnent, mais un second `middlewareFor()` sur la même action
   **remplace** le premier : passer toutes les gardes d'une action en un seul
   appel, `->middlewareFor('store', ['can:update,category', 'can:create,'.Post::class])`.
8. **Prouver** — chaque branche de chaque méthode : la branche hors Filament par
   les routes, la branche Filament par les tests Livewire, qui activent
   `Filament::setServingStatus()` (sans lui, `livewire()` passe par la branche
   hors Filament). Pour chaque route, un test Feature :
   - compte autorisé : succès ;
   - compte sans droit : 403, et rien d'écrit ;
   - invité : 401 ou redirection vers la connexion, sauf accès invité prévu.
   Puis un test de balayage de la table de routes, qui échoue si une route de
   contrôleur n'a pas de garde `can:` (policy ou capacité Gate) :
   ```php
   foreach (Route::getRoutes()->getRoutes() as $route) {
       if (! str_starts_with($route->getActionName(), 'App\\Http\\Controllers\\')) {
           continue;
       }
       $guarded = collect($route->gatherMiddleware())->contains(fn ($m) => is_string($m) && str_starts_with($m, 'can:'));
       if (! $guarded && ! in_array($route->uri(), self::WITHOUT_CAN, true)) {
           $unguarded[] = $route->uri();
       }
   }
   ```
   `WITHOUT_CAN` liste, avec leur motif, les routes publiques ou gardées par un
   autre middleware de route. Le balayage ne voit que le middleware `can:` : une garde posée
   ailleurs sera signalée, et une garde qui vise la mauvaise capacité n'est vue
   que par les tests par route.

## Règles absolues
- Un modèle concerné par une action a sa policy ; la policy contient une méthode pour chaque action
- Chaque route qui agit sur un modèle porte la garde `can:` de sa policy
- Pour une action sur un modèle, aucun contrôle d'accès dans le contrôleur : ni `abort_unless()`, ni `$this->authorize()`, ni middleware du contrôleur
- Une méthode de policy écrit la règle une seule fois ; les actions qui la partagent délèguent
- Dans un projet avec Filament, chaque méthode commence par `if (Filament::isServing())` et écrit ses deux règles
- Les tests couvrent le refus **et** l'acceptation, dans les deux branches
