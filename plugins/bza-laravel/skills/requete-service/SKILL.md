---
name: requete-service
description: Dans un projet Laravel, écrire une action de contrôleur qui reçoit des données — formulaire, API, fichier, filtres, action métier — avec une FormRequest dédiée et, s'il existe, un service qui reçoit les données validées.
---

## Quand utiliser ce skill
Pour toute action qui reçoit des données de la requête : `store` et `update`, mais
aussi toute autre action, qu'elle écrive ou non (`search`, `print`, `export`,
`publish`, `import`, `duplicate`…), web ou API. Les actions qui ne reçoivent
aucune donnée (`show`, `destroy` sans corps ni paramètre) ne suivent pas ce schéma.

## Le schéma

| Pièce | Présence | Rôle |
|---|---|---|
| Requête personnalisée | **toujours** | valide et autorise les données de l'action |
| Service | optionnel | reçoit les données validées en argument ; une méthode par action |
| Contrôleur | toujours | reçoit la requête, transmet ses données validées, construit la réponse |

La validation vit dans la requête, jamais dans le contrôleur. Le service ne
connaît pas la requête : il est réutilisable depuis une commande, un import ou un job.

## Procédure
1. **Requête** — `php artisan make:request <Nom>Request`.
   - Les actions qui reçoivent les mêmes données partagent une requête : store et
     update d'un modèle utilisent `<Modèle>Request`.
   - Une action aux données propres a la sienne : `<Verbe><Modèle>Request`
     (`SearchPostRequest`, `PrintPostRequest`).
   - Quand la requête est partagée, le modèle de la route distingue les cas :
     ```php
     public function rules(): array
     {
         $post = $this->route('post'); // null en store, le modèle en update

         return [
             'title' => ['required', 'string', 'max:255'],
             'slug' => ['required', Rule::unique('posts')->ignore($post)],
         ];
     }

     public function authorize(): bool
     {
         $post = $this->route('post');

         return $post instanceof Post
             ? $this->user()?->can('update', $post) ?? false
             : $this->user()?->can('create', Post::class) ?? false;
     }
     ```
   `authorize()` reprend la capacité du `can:` posé sur la route : méthode de
   policy pour une action sur un modèle (`bza-laravel:create-policy`), capacité
   Gate sinon (`bza-laravel:create-controller`). Une route gardée par un autre
   middleware, ou publique, retourne `true`. Une normalisation des entrées
   (assainissement HTML, valeurs par défaut) se fait dans une méthode de la
   requête dérivée de `validated()`, par exemple `data()`.
2. **Service, ou pas** — en créer un quand l'action fait plus qu'écrire les
   données validées sur un seul modèle (relations, fichiers, plusieurs modèles,
   effets de bord), quand sa logique doit servir hors HTTP, ou quand un service
   existe déjà pour ce modèle : l'utiliser.
3. **Sans service** — l'action écrit ce que la requête a validé :
   ```php
   public function publish(PublishPostRequest $request, Post $post): RedirectResponse
   {
       $post->update($request->validated());

       return to_route('posts.show', $post);
   }
   ```
4. **Avec service** — un service par modèle ou par domaine, une méthode par action,
   nommée d'après l'action (`create`, `update`, `search`, `print`…). Chaque méthode
   reçoit les données validées en argument, avec leur forme en PHPDoc, et les
   modèles de la route :
   ```php
   final class PostService
   {
       /** @param array{title: string, slug: string} $data */
       public function create(array $data): Post
       {
           return Post::create($data);
       }

       /** @param array{title: string, slug: string} $data */
       public function update(Post $post, array $data): Post
       {
           $post->update($data);

           return $post;
       }

       /** @param array{q?: string, category?: int} $filters */
       public function search(array $filters): LengthAwarePaginator
       {
           return Post::query()
               ->when($filters['q'] ?? null, fn ($query, $q) => $query->where('title', 'like', "%{$q}%"))
               ->when($filters['category'] ?? null, fn ($query, $id) => $query->where('category_id', $id))
               ->paginate();
       }
   }
   ```
   Plusieurs écritures (relations, `sync`, fichiers) s'enveloppent dans
   `DB::transaction()` à l'intérieur de la méthode. Un traitement qui en
   déclenche un autre sur ce qu'il vient de produire (créer une commande, puis
   sa facture) émet un évènement qu'un listener transmet au service suivant :
   `bza-laravel:service-cascade`. Le contrôleur reçoit la requête
   et le service en paramètres de l'action :
   ```php
   public function store(PostRequest $request, PostService $service): RedirectResponse
   {
       $post = $service->create($request->validated());

       return to_route('posts.show', $post);
   }

   public function update(PostRequest $request, Post $post, PostService $service): RedirectResponse
   {
       $service->update($post, $request->validated());

       return to_route('posts.show', $post);
   }

   public function search(SearchPostRequest $request, PostService $service): View
   {
       return view('posts.index', ['posts' => $service->search($request->validated())]);
   }
   ```
   La requête s'autorise et se valide quand le conteneur la construit : une requête
   invalide reçoit sa 422 (ou sa redirection avec erreurs) avant la première ligne
   de l'action.
5. **Tests** :
   - Feature, par HTTP, pour chaque action : entrée invalide (422, erreur sur le
     champ attendu, rien d'écrit), entrée valide (valeurs attendues en base ou dans
     la réponse), champ non prévu ignoré, compte sans droit (403, rien d'écrit) ;
   - Unit ou Feature sans HTTP pour le service : un tableau de données en entrée,
     le résultat attendu en sortie.

## Règles absolues
- Toute action qui reçoit des données reçoit une requête personnalisée : ni `Request` générique, ni `$request->validate()`, ni `Validator::make()` dans le contrôleur
- Seules les données validées sont utilisées : `validated()`, `safe()` ou une méthode de la requête qui en dérive ; jamais `all()` ni `input()`
- Le service reçoit des données, jamais la requête : ni `Request` en argument, ni `request()` dans son code
- La requête s'injecte dans la méthode de l'action, jamais dans le constructeur du contrôleur : un contrôleur qui hérite de `Illuminate\Routing\Controller` (squelettes antérieurs à Laravel 11) est construit avant les middlewares de la route, et la requête serait validée avant `auth` et `can:`
- Le service fait confiance à ses données : un appelant hors HTTP (commande, import, job) les valide avant l'appel ; une validation qu'il réécrit à côté de la requête se signale (`bza:lois/coherence.md`)
