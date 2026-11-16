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
   dans `app/Listeners/`, nommé d'après ce qu'il déclenche. Il prend dans
   `$event->row` les informations de son étape et appelle le service suivant :
   ```php
   final class ImportPostComments
   {
       public function __construct(
           private readonly ImportCommentsService $service,
       ) {}

       public function handle(PostImported $event): void
       {
           $this->service->run([
               'post' => $event->post,
               'comments' => $event->row['comments'] ?? [],
           ]);
       }
   }
   ```
   Le service de l'étape suivante suit le même schéma que tout service :
   méthode `run()` qui reçoit les données, fonction d'affichage optionnelle au
   constructeur (`bza-laravel:create-command`). Construit par le conteneur dans
   le listener, il tourne sans elle : ses messages vont au journal.
4. **Enregistrer** — la découverte automatique (Laravel 11+) associe le listener
   à l'évènement par le type de `handle()`. Projet qui déclare ses listeners à la
   main (`EventServiceProvider`, module) : l'ajouter au même endroit que les autres.
5. **Synchrone ou en file** — synchrone par défaut. Une étape longue ou qui
   appelle un service externe implémente `ShouldQueue` sur le listener ; ce
   choix se note dans le rapport, il change l'ordre dans lequel les messages
   apparaissent et ce qu'un échec fait remonter.
6. **Tests** :
   - service de la première étape : `Event::fake([PostImported::class])`, puis
     `Event::assertDispatched(PostImported::class, fn ($e) => $e->post->is($post))` —
     et `assertNotDispatched` quand la première étape échoue ;
   - listener : `Event::assertListening(PostImported::class, ImportPostComments::class)` ;
   - service de l'étape suivante : seul, par `run()`, comme tout service ;
   - un test de bout en bout **sans** `Event::fake` : la commande ou l'action
     d'origine produit le post **et** ses commentaires.

## Règles absolues
- Un service n'appelle jamais le service de l'étape suivante : il émet un évènement, un listener fait l'appel
- L'évènement est émis par le service, une fois la première étape enregistrée, et nommé au passé (`PostImported`)
- Un évènement émis dans une transaction implémente `ShouldDispatchAfterCommit`
- L'évènement porte la ligne source entière (`$row`), jamais les seules données d'un listener
- Le listener ne contient aucun traitement : il prend dans `$event->row` les données de son étape et les transmet au `run()` du service suivant
- Les tests prouvent l'émission, l'écoute, et la cascade complète sans `Event::fake`
