---
name: service-cascade
description: Dans un projet Laravel, enchaîner des traitements en cascade entre services (importer un post puis ses commentaires, créer une commande puis sa facture…) par un évènement émis une fois la première étape faite et un listener qui appelle le service de l'étape suivante. À utiliser dès qu'un service doit déclencher le traitement d'un autre.
---

## Quand utiliser ce skill
Dès qu'un service, une fois son traitement fait, doit en déclencher un autre sur
ce qu'il vient de produire : importer un post puis ses commentaires, créer un
compte puis son espace, valider une commande puis générer sa facture. Le service
peut venir d'une commande (`bza-laravel:create-command`) ou d'une action de
contrôleur (`bza-laravel:requete-service`).

## Le schéma

| Pièce | Rôle |
|---|---|
| Service de la première étape | fait son traitement, puis émet l'évènement ; ne connaît pas l'étape suivante |
| Évènement | nommé au passé d'après ce qui vient d'arriver (`PostImported`) ; porte le modèle produit et la ligne source entière |
| Listener | prend dans la ligne de l'évènement ce dont son étape a besoin, appelle le service de l'étape suivante ; aucun traitement à lui |
| Service de l'étape suivante | fait son traitement ; peut à son tour émettre son propre évènement |

Un service n'appelle jamais directement le service de l'étape suivante : la
cascade passe **toujours** par au moins un évènement et un listener.

## Procédure
1. **Évènement** — `php artisan make:event PostImported`, dans `app/Events/`
   (ou celui du module). Il porte le modèle produit et la **ligne source
   entière**, déjà validée, telle que le service l'a reçue — jamais un
   sous-ensemble taillé pour un listener :
   ```php
   final class PostImported implements ShouldDispatchAfterCommit
   {
       use Dispatchable, SerializesModels;

       /**
        * @param  array{post: array<string, mixed>, comments?: list<array{author: string, body: string}>, tags?: list<string>}  $row
        */
       public function __construct(
           public readonly Post $post,
           public readonly array $row,
       ) {}
   }
   ```
   C'est à chaque listener d'aller chercher dans `$row` ce dont il a besoin :
   un nouveau listener (import des tags, notification) s'ajoute sans toucher ni
   l'évènement ni le service qui l'émet.
   `ShouldDispatchAfterCommit` retient l'évènement jusqu'à la validation de la
   transaction en cours : l'étape suivante ne part jamais sur un post qu'un
   `rollback` fera disparaître.
2. **Émettre depuis le service** — une fois le modèle enregistré, à l'intérieur
   du service, jamais dans la commande ni le contrôleur :
   ```php
   public function run(array $data): int
   {
       foreach ($data['posts'] as $row) {
           $post = DB::transaction(fn () => Post::create($row['post']));
           $this->info("Post {$post->id} importé");

           PostImported::dispatch($post, $row);
       }

       return count($data['posts']);
   }
   ```
3. **Listener** — `php artisan make:listener ImportPostComments --event=PostImported`,
   écrit selon `bza-laravel:create-listener` : le service suivant injecté dans
   son constructeur, `handle()` qui prend dans `$event->row` les informations
   de son étape et appelle le service :
   ```php
   final class ImportPostComments
   {
       public function __construct(
           private readonly ImportCommentsService $service,
       ) {}

       public function handle(PostImported $event): void
       {
           $comments = $event->row['comments'] ?? [];

           if ($comments === []) {
               return;
           }

           $this->service->run(['post' => $event->post, 'comments' => $comments]);
       }
   }
   ```
   Le service de l'étape suivante suit le même schéma que tout service :
   méthode `run()` qui reçoit les données, fonction d'affichage optionnelle au
   constructeur (`bza-laravel:create-command`). Injecté dans le listener, il tourne
   sans elle : ses messages vont au journal. Pour les afficher dans la console
   de la commande d'origine, l'évènement porte aussi sa fonction d'affichage
   (`?Closure $info = null`) et le listener instancie le service avec elle
   (`bza-laravel:create-listener`).
4. **Enregistrer, synchrone ou en file** — comme tout listener
   (`bza-laravel:create-listener`).
5. **Tests** :
   - service de la première étape : `Event::fake([PostImported::class])`, puis
     `Event::assertDispatched(PostImported::class, fn ($e) => $e->post->is($post))` —
     et `assertNotDispatched` quand la première étape échoue ;
   - listener : écoute, appel avec les bonnes données, aucun appel quand elles
     manquent (`bza-laravel:create-listener`) ;
   - service de l'étape suivante : seul, par `run()`, comme tout service ;
   - un test de bout en bout **sans** `Event::fake` : la commande ou l'action
     d'origine produit le post **et** ses commentaires.

## Règles absolues
- Un service n'appelle jamais le service de l'étape suivante : il émet un évènement, un listener fait l'appel
- L'évènement est émis par le service, une fois la première étape enregistrée, et nommé au passé (`PostImported`)
- Un évènement émis dans une transaction implémente `ShouldDispatchAfterCommit`
- L'évènement porte la ligne source entière (`$row`), jamais les seules données d'un listener
- Le listener suit `bza-laravel:create-listener` : service injecté au constructeur, `handle()` qui prend dans `$event->row` les données de son étape et appelle le `run()` du service suivant
- Les tests prouvent l'émission, l'écoute, et la cascade complète sans `Event::fake`
