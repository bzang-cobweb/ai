---
name: api-resource
description: Dans un projet Laravel, écrire la réponse d'une route d'API qui renvoie un modèle ou une liste de modèles — toujours une classe ressource qui étend JsonResource, une collection de cette ressource pour une liste.
---

## Quand utiliser ce skill
Pour toute action qui renvoie un ou plusieurs modèles en JSON : API REST, route
appelée en `fetch`, endpoint consommé par une application mobile ou un tiers.

## La règle
Une réponse ne contient jamais un modèle Eloquent sérialisé tel quel. Un modèle
passe par **sa** ressource ; une liste de modèles, par la collection de cette
ressource :

| L'action renvoie | Réponse |
|---|---|
| un modèle | `new PostResource($post)` |
| une liste ou une page de modèles | `PostResource::collection($posts)` |

`return $post`, `response()->json($post)`, `$post->toArray()` et
`response()->json(Post::all())` sérialisent tous les attributs non masqués du
modèle : une colonne ajoutée plus tard part dans l'API sans que personne ne l'ait
décidé.

## Procédure
1. **Créer la ressource** — `php artisan make:resource PostResource`, une par
   modèle, dans `Http/Resources/` de l'application ou du module.
2. **Lister les champs exposés** — chaque champ est écrit, aucun n'est hérité :
   ```php
   class PostResource extends JsonResource
   {
       /**
        * @return array<string, mixed>
        */
       public function toArray(Request $request): array
       {
           return [
               'id' => $this->id,
               'title' => $this->title,
               'published_at' => $this->published_at?->toIso8601String(),
               'author' => new UserResource($this->whenLoaded('author')),
               'comments' => CommentResource::collection($this->whenLoaded('comments')),
               'comments_count' => $this->whenCounted('comments'),
               'can_update' => $request->user()?->can('update', $this->resource) ?? false,
           ];
       }
   }
   ```
   - une relation passe par la ressource de son modèle, et seulement si elle est
     chargée (`whenLoaded`) : la ressource ne déclenche aucune requête ;
   - un champ réservé à certains appelants passe par `when()` ou `mergeWhen()`,
     avec la même capacité que la policy (`bza-laravel:create-policy`) ;
   - un HTML riche passe par l'assainisseur d'affichage du projet ; un texte brut
     reste du texte ;
   - aucune donnée sensible (jeton, mot de passe, adresse interne) sans décision
     écrite.
3. **Renvoyer la ressource** depuis l'action, avec le type de retour :
   ```php
   public function show(Post $post): PostResource
   {
       return new PostResource($post->load('author'));
   }

   public function index(SearchPostRequest $request, PostService $service): AnonymousResourceCollection
   {
       return PostResource::collection($service->search($request->validated()));
   }
   ```
   Une collection construite depuis un paginateur garde `links` et `meta`. Les
   relations affichées sont chargées par la requête (`with()`, `load()`,
   `withCount()`), pas par la ressource.
4. **Enveloppe** — `data` par défaut. Le retrait de l'enveloppe se décide une
   fois pour toute l'application, dans `AppServiceProvider::boot()`
   (`JsonResource::withoutWrapping()`), jamais en écrivant `static::$wrap` dans
   une ressource : la valeur changerait pour toutes les ressources de la requête.
5. **Une réponse sans modèle** (statut d'une action, compteur, formulaire) n'est
   pas concernée et reste un `response()->json([...])` explicite.
6. **Tester** la forme exacte, pas seulement le statut :
   ```php
   $this->getJson("/api/posts/{$post->id}")
       ->assertOk()
       ->assertExactJson(['data' => [
           'id' => $post->id,
           'title' => $post->title,
           'published_at' => $post->published_at->toIso8601String(),
           'can_update' => false,
       ]]);
   ```
   Et pour une liste : `assertJsonCount(3, 'data')` et `assertJsonStructure(['data' => [['id', 'title']], 'links', 'meta'])`.
   Un attribut ajouté au modèle et absent de la ressource ne doit pas apparaître :
   `assertJsonMissingPath('data.internal_note')`.
7. **Contrat** — un générateur OpenAPI dérive ses schémas des ressources
   (`bza-laravel:generate-openapi`) : une ressource bien typée donne un contrat juste.

## Règles absolues
- Une action d'API qui renvoie un modèle renvoie sa ressource ; une liste, la collection de cette ressource
- Jamais un modèle, une collection Eloquent ou un `toArray()` de modèle dans une réponse JSON
- Une ressource écrit chacun de ses champs ; une relation passe par sa propre ressource et `whenLoaded`
- L'enveloppe `data` se règle une seule fois pour l'application, jamais dans une ressource
- Les tests vérifient la forme exacte de la réponse et l'absence des champs non exposés
