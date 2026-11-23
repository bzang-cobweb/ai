---
name: create-listener
description: Dans un projet Laravel, écrire le listener d'un évènement — les services qui font le travail injectés dans son constructeur (ou instanciés avec leurs paramètres quand ceux-ci ne s'injectent pas), une méthode handle() qui se contente de réunir les données de l'évènement et d'appeler la méthode du service. À utiliser dès qu'on ajoute ou modifie un listener (make:listener, app/Listeners).
---

## Quand utiliser ce skill
Pour tout listener ajouté au projet, qu'il serve une cascade entre services
(`bza-laravel:service-cascade`) ou réagisse à un évènement du framework ou d'un
paquet (`Registered`, `Login`…). Un listener existant qu'on retouche est ramené
à ce schéma si son traitement vit encore dans `handle()`.

## Le schéma

| Pièce | Rôle |
|---|---|
| Constructeur du listener | reçoit, injectés par le conteneur, les services qui font le travail — sauf ceux qui attendent un paramètre non injectable, instanciés dans `handle()` |
| `handle()` | s'assure que la méthode du service peut être appelée : réunit dans l'évènement les données dont elle a besoin, vérifie qu'elles sont là, l'appelle |
| Service | fait **tout** le traitement (`run()` ou méthode nommée d'après l'action) |

Comme pour une commande (`bza-laravel:create-command`), le listener est un
point d'entrée : il ne contient aucun traitement, ni requête, ni écriture, ni
boucle métier.

## Procédure
1. **Créer** — `php artisan make:listener <Verbe><Nom> --event=<Évènement>`
   (`ImportPostComments`), dans `app/Listeners/` ou celui du module, nommé
   d'après ce qu'il déclenche.
2. **Injecter les services** — dans le constructeur, en propriétés promues
   `private readonly`. Le conteneur les résout, y compris pour un listener en
   file. Un service dont tout le constructeur s'injecte ne se résout jamais
   dans `handle()` :
   ```php
   final class ImportPostComments
   {
       public function __construct(
           private readonly ImportCommentsService $service,
       ) {}
   ```
   Un listener qui déclenche plusieurs étapes indépendantes reçoit plusieurs
   services ; si ces étapes n'ont pas d'ordre entre elles, préférer un listener
   par étape.

   **Paramètre non injectable** — quand le service attend un paramètre que le
   conteneur ne peut pas fournir (la fonction d'affichage d'une commande, une
   valeur propre à l'évènement), il n'est pas injecté : `handle()` l'instancie
   en lui passant ce paramètre, pris dans l'évènement, avec `app()->make()` pour
   que le conteneur résolve les autres dépendances :
   ```php
   final class PostImported implements ShouldDispatchAfterCommit
   {
       use Dispatchable;

       /**
        * @param  (Closure(string): void)|null  $info  affichage de la commande d'origine
        */
       public function __construct(
           public readonly Post $post,
           public readonly array $row,
           public readonly ?Closure $info = null,
       ) {}
   }

   final class ImportPostComments
   {
       public function handle(PostImported $event): void
       {
           $comments = $event->row['comments'] ?? [];

           if ($comments === []) {
               return;
           }

           $service = app()->make(ImportCommentsService::class, ['info' => $event->info]);
           $service->run(['post' => $event->post, 'comments' => $comments]);
       }
   }
   ```
   L'instanciation est alors la seule chose que `handle()` ajoute aux trois
   temps ci-dessous. Une closure ne se sérialise pas : un évènement qui en
   porte une ne passe ni par une file ni par `SerializesModels`, et son
   listener reste synchrone.
3. **`handle()`** — trois temps, rien d'autre :
   ```php
       public function handle(PostImported $event): void
       {
           // 1. Réunir les données dont le service a besoin.
           $comments = $event->row['comments'] ?? [];

           // 2. S'assurer que l'appel a un sens : sinon, ne rien faire.
           if ($comments === []) {
               return;
           }

           // 3. Appeler le service avec ses données.
           $this->service->run([
               'post' => $event->post,
               'comments' => $comments,
           ]);
       }
   }
   ```
   - Les données se prennent dans l'évènement tel qu'il est émis (la ligne
     source entière pour une cascade) : c'est au listener d'aller chercher les
     siennes, pas à l'évènement de les lui préparer.
   - Le contrôle se limite à ce qui rend l'appel possible : donnée absente ou
     vide. Il ne réécrit pas la validation des
     données, faite par l'émetteur, ni une règle métier, qui vit dans le service.
   - Le tableau passé au service a la forme décrite par le PHPDoc de sa
     méthode ; une transformation des données (calcul, mise en forme) se fait
     dans le service, pas ici.
   - Un service injecté n'a pas de fonction d'affichage : ses messages vont au
     journal (`bza-laravel:create-command`). Pour qu'ils s'affichent dans la
     console d'une commande, l'évènement porte la fonction et `handle()`
     instancie le service avec elle (étape 2).
4. **Synchrone ou en file** — synchrone par défaut. Un traitement long ou qui
   appelle un service externe implémente `ShouldQueue` sur le listener ;
   `handle()` ne change pas. Ce choix se note dans le rapport.
5. **Enregistrer** — la découverte automatique associe le listener à
   l'évènement par le type de `handle()`. Projet qui déclare ses listeners à la
   main (`EventServiceProvider`, module) : l'ajouter au même endroit que les autres.
6. **Tests** :
   - écoute : `Event::assertListening(PostImported::class, ImportPostComments::class)` ;
   - `handle()` : construire le listener avec un double du service
     (`$this->mock(ImportCommentsService::class)` puis `app(ImportPostComments::class)`),
     vérifier que le service reçoit exactement les données attendues, et qu'il
     **n'est pas** appelé quand la donnée manque ; pour un service instancié
     dans `handle()`, `$this->mock()` ne suffit pas (le conteneur ignore une
     instance quand on lui passe des paramètres) : lier le double par
     `$this->app->bind(ImportCommentsService::class, fn ($app, array $params) => $double)`
     et vérifier aussi les paramètres reçus (`$params['info']`) ;
   - le service, seul, par sa méthode, comme tout service.

## Règles absolues
- Les services qui font le travail sont injectés dans le constructeur du listener ; seul un service qui attend un paramètre non injectable est instancié dans `handle()`, avec `app()->make()` et ce paramètre pris dans l'évènement
- Un évènement qui porte une closure est traité par des listeners synchrones
- `handle()` ne fait que réunir les données de l'évènement, vérifier que l'appel est possible et appeler la méthode du service
- Aucun traitement dans le listener : ni requête, ni écriture, ni transformation des données
- Quand une donnée nécessaire manque, `handle()` retourne sans appeler le service
- Les tests prouvent l'appel avec les bonnes données et l'absence d'appel quand elles manquent
