---
name: blade
description: Créer ou modifier une vue Blade fidèle à la spec et à l'interface originale — structure, libellés, `@can` sur les liens, boutons et formulaires dont la route est gardée, contenus `@can`, `@auth` et `@guest` chargés en différé (`data-lazy-url`) pour rester compatibles avec le cache.
---

## Quand utiliser ce skill
Quand une tâche demande de créer ou modifier une vue, un layout ou un composant Blade.
Le HTML suit `bza-dev:html`. Pour les assets et le build : `bza-laravel:front-build`.

## Procédure
1. **Lire la mémoire** `spec_<concept>` → lire `fonctionnalites`, `acces` et la structure de la source
2. Identifier le layout parent à étendre (`@extends`)
3. Reproduire la structure de la source section par section :
   - En-tête, titre de page, breadcrumb
   - Filtres et formulaires de recherche
   - Tableau ou liste des données
   - Actions (boutons, liens) par ligne et en masse
   - Pagination
4. Appliquer les libellés **exactement** tels qu'ils apparaissent dans la source
5. **Droits** — un bouton, lien ou formulaire dont la route porte un middleware
   `can:` est entouré du `@can` correspondant (voir « Droits dans la vue »)
6. **Cache** — dans une page cachable, tout contenu entouré de `@can`, `@auth` ou
   `@guest` se charge en différé (voir « Contenus chargés en différé »)
7. Vérifier le rendu dans le navigateur avant de marquer done, en invité et
   connecté

## Droits dans la vue
Pour chaque bouton, lien ou formulaire, lire la route qu'il vise
(`php artisan route:list --name=<nom> -v`) :

| La route cible porte | Dans la vue |
|---|---|
| un middleware `can:<capacité>,<modèle>` | `@can('<capacité>', $modele)` autour de l'élément |
| un middleware `can:<capacité>` (capacité Gate) | `@can('<capacité>')` autour de l'élément |
| aucun middleware `can:` | rien : l'élément s'affiche sans condition |

La vue pose **exactement la capacité** de la route (`bza-laravel:create-policy`) :

```blade
@can('update', $post)
    <a href="{{ route('posts.edit', $post) }}">{{ __('post.edit') }}</a>
@endcan

@can('delete', $post)
    <form method="POST" action="{{ route('posts.destroy', $post) }}">
        @csrf
        @method('DELETE')
        <button type="submit">{{ __('post.delete') }}</button>
    </form>
@endcan
```

- Une route qui porte plusieurs `can:` donne autant de `@can` imbriqués.
- Pour un invité, `@can` ne répond `true` que si la méthode de policy accepte
  `?User` ; sinon l'élément est masqué, ce qui est le comportement attendu.
- Sur un élément dont la route porte `can:`, un `@if(auth()->user()->role === …)`
  ou un `@auth` ne remplace pas `@can` : la règle vit dans la policy, la vue la
  consulte.
- Masquer un bouton ne protège rien : la route reste gardée par son `can:`.
- Dans une page cachable, ces `@can` ne restent pas dans la page : ils passent
  dans un fragment (section suivante).

## Contenus chargés en différé
Une page servie depuis un cache HTTP partagé (Varnish, CDN, cache de réponse)
est la même pour tous ses visiteurs : un `@can`, `@auth` ou `@guest` y serait
évalué une fois, au remplissage du cache, puis servi à tous. Tout contenu
entouré de `@can`, `@auth` ou `@guest` se charge donc **en différé**, après le
rendu.

1. **Délimiter les fragments** — des éléments gardés qui se suivent (liens,
   boutons, formulaires, chacun avec son `@can`) forment **un seul fragment**,
   rendu par **un seul endpoint**. Un fragment par élément gardé isolé. Une barre
   d'actions de trois éléments fait une requête, jamais trois.
2. **Dans la page en cache**, le groupe est remplacé par un conteneur vide qui
   réserve sa place :
   ```blade
   <div data-lazy-url="{{ route('posts.actions', $post) }}" class="lazy-html"></div>
   ```
3. **Une route de fragment** — `GET`, qui renvoie la vue partielle du groupe :
   ```php
   Route::get('posts/{post}/actions', [PostController::class, 'actions'])
       ->name('posts.actions')
       ->can('view', 'post');
   ```
   - elle est gardée par la capacité de la page qui l'appelle, pas par celles des
     éléments : chaque élément garde son propre `@can` dans la vue partielle ;
   - sa réponse est `Cache-Control: private, no-store`, jamais `public` ;
   - ses paramètres passent par une requête personnalisée
     (`bza-laravel:requete-service`) ;
   - un visiteur qui n'a droit à aucun élément reçoit un fragment vide (200),
     pour que la page reste intacte.
4. **La vue partielle** porte tous les éléments du groupe, chacun avec son
   `@can`, `@auth` ou `@guest` :
   ```blade
   @can('update', $post)
       <a href="{{ route('posts.edit', $post) }}">{{ __('post.edit') }}</a>
   @endcan
   @can('publish', $post)
       <form method="POST" action="{{ route('posts.publish', $post) }}">
           @csrf
           <button type="submit">{{ __('post.publish') }}</button>
       </form>
   @endcan
   @can('delete', $post)
       <form method="POST" action="{{ route('posts.destroy', $post) }}">
           @csrf
           @method('DELETE')
           <button type="submit">{{ __('post.delete') }}</button>
       </form>
   @endcan
   @auth
       <button type="button" data-action="toggle-favorite" data-url="{{ route('posts.favorite', $post) }}"
               @class(['is-active' => $isFavorited])>{{ __('post.favorite') }}</button>
   @endauth
   ```
   Un formulaire chargé en fragment porte son `@csrf` : le jeton est celui de la
   session du visiteur, puisque le fragment n'est pas en cache.
5. **Un seul chargeur** dans le projet, qui remplit chaque conteneur :
   ```js
   document.querySelectorAll('[data-lazy-url]').forEach(async (container) => {
       const response = await fetch(container.dataset.lazyUrl, { credentials: 'same-origin' });
       if (response.ok) {
           container.innerHTML = await response.text();
           container.classList.add('lazy-html--loaded');
       }
   });
   ```
   Le HTML injecté n'exécute pas ses `<script>` et n'a pas d'écouteurs : les
   interactions du fragment passent par des écouteurs délégués sur `document`
   (`bza-dev:js`).
6. **Listes** — dans une liste de N lignes qui portent chacune des éléments
   gardés, un seul endpoint rend les fragments de toutes les lignes ; jamais
   N requêtes.

Une page déclarée non cachable (`private, no-store` : compte, panier, back-office)
garde ses `@can`, `@auth` et `@guest` dans la page.

## Tester
- **Droits** : pour chaque élément entouré de `@can`, un test Feature appelle le
  fragment (ou la page non cachable) avec un compte autorisé (élément présent,
  texte attendu) et un compte sans droit (élément absent).
- **Cache** : la page cachable rendue pour un invité et pour un compte connecté
  est identique ; ses vues ne contiennent ni `@can`, ni `@auth`, ni `@guest`.
- **Fragment** : invité et comptes de droits différents reçoivent chacun leurs
  éléments, et la réponse porte `no-store`.
- **Navigateur** : le fragment est chargé et ses interactions fonctionnent
  (`bza-dev:preuve-navigateur`).

## Règles absolues
- Les règles de `bza-dev:frontend` s'appliquent (libellés identiques à la source,
  aucune fonctionnalité hors spec, navigation globale intacte)
- Vérifier les viewports mobile et desktop si la source est responsive
- Un bouton, lien ou formulaire est entouré de `@can` si et seulement si sa route porte un middleware `can:`, avec la même capacité
- Une page cachable ne contient ni `@can`, ni `@auth`, ni `@guest` : ces contenus sont chargés par `data-lazy-url`
- Des éléments gardés qui se suivent sont rendus par un seul endpoint
- Une route de fragment n'est jamais cachée en partagé
