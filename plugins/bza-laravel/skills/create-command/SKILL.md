---
name: create-command
description: Dans un projet Laravel, écrire une commande Artisan dont le traitement vit dans une classe Service — le service reçoit en constructeur une fonction d'affichage optionnelle et expose une méthode run() qui reçoit les données. À utiliser dès qu'on ajoute ou modifie une commande Artisan (make:command, app/Console/Commands).
---

## Quand utiliser ce skill
Pour toute commande Artisan ajoutée au projet : import, export, synchronisation,
nettoyage, recalcul, tâche planifiée… Une commande existante qu'on retouche est
ramenée à ce schéma si son traitement vit encore dans `handle()`.

## Le schéma

| Pièce | Rôle |
|---|---|
| Commande | lit et valide les arguments et options, construit le service avec sa fonction d'affichage, appelle `run()`, rend le code de sortie |
| Service | fait **tout** le traitement ; reçoit en constructeur une fonction d'affichage optionnelle ; expose `run()` qui reçoit les données |

La commande ne contient aucun traitement : ni requête, ni écriture, ni boucle
métier. Le service ne connaît pas la console : il affiche par la fonction reçue,
et reste appelable sans elle depuis un job, un contrôleur ou un test.

## Procédure
1. **Commande** — `php artisan make:command <Verbe><Nom>Command`
   (`ImportPostsCommand`), signature en `<domaine>:<verbe>` (`posts:import`).
2. **Service** — `app/Services/<Verbe><Nom>Service.php` (`ImportPostsService`),
   ou dans le dossier `Services` du module. Un service par commande ; s'il existe
   déjà un service pour ce traitement, l'utiliser et lui ajouter la fonction
   d'affichage et `run()` plutôt que d'en créer un second.
   ```php
   final class ImportPostsService
   {
       /**
        * @param  (Closure(string): void)|null  $info  reçoit chaque message du traitement
        */
       public function __construct(
           private readonly ?Closure $info = null,
       ) {}

       /**
        * @param  array{path: string, dry_run: bool}  $data
        */
       public function run(array $data): int
       {
           $rows = $this->read($data['path']);
           $this->info(sprintf('%d lignes à importer', count($rows)));

           $imported = 0;
           foreach ($rows as $row) {
               // … traitement
               $imported++;
           }

           $this->info("{$imported} articles importés");

           return $imported;
       }

       private function info(string $message): void
       {
           Log::info($message);

           if ($this->info !== null) {
               ($this->info)($message);
           }
       }
   }
   ```
   - La fonction d'affichage est **optionnelle** (`?Closure`, défaut `null`) :
     sans elle, le service tourne en silence à l'écran mais journalise toujours.
   - Tout message passe par la méthode privée `info()` : jamais d'`echo`, de
     `dump()` ni de `$this->info` de console dans le service.
   - Les autres dépendances du service s'ajoutent au constructeur, **avant**
     `$info` : le conteneur les résout.
   - Plusieurs écritures s'enveloppent dans `DB::transaction()` à l'intérieur
     de `run()`.
   - Un traitement en cascade (importer un post, puis ses commentaires) passe
     par un évènement et un listener, jamais par un appel direct au second
     service : `bza-laravel:service-cascade`.
3. **`run()`** — l'unique point d'entrée public du traitement. Il reçoit les
   données déjà validées, avec leur forme en PHPDoc (`array{…}`), et peut rendre
   un résultat (nombre traité, rapport) que la commande affiche ou teste.
4. **Commande** — `handle()` lit les arguments et options, les valide, construit
   le service avec la fonction d'affichage, appelle `run()` :
   ```php
   final class ImportPostsCommand extends Command
   {
       protected $signature = 'posts:import {path : fichier CSV à importer} {--dry-run : ne rien écrire}';

       protected $description = 'Importe des articles depuis un fichier CSV';

       public function handle(): int
       {
           $validator = Validator::make(
               ['path' => $this->argument('path'), 'dry_run' => $this->option('dry-run')],
               ['path' => ['required', 'string'], 'dry_run' => ['boolean']],
           );

           if ($validator->fails()) {
               foreach ($validator->errors()->all() as $error) {
                   $this->error($error);
               }

               return self::FAILURE;
           }

           $service = app()->make(ImportPostsService::class, [
               'info' => fn (string $message) => $this->info($message),
           ]);

           $service->run($validator->validated());

           return self::SUCCESS;
       }
   }
   ```
   `app()->make()` avec le paramètre nommé `info` laisse le conteneur résoudre
   les autres dépendances du service. La validation se fait ici, comme la
   FormRequest le fait pour une action HTTP (`bza-laravel:requete-service`) : le
   service fait confiance à ses données.
5. **Tests** :
   - service, sans console : appeler `run()` avec un tableau de données et une
     fonction qui collecte les messages ; vérifier le résultat, l'état en base
     et les messages reçus ; un second cas construit le service **sans**
     fonction d'affichage et doit passer aussi ;
   - commande : `$this->artisan('posts:import', ['path' => …])` avec
     `->expectsOutput()` sur un message du service, `->assertSuccessful()` ;
     une entrée invalide donne `->assertFailed()` et rien d'écrit.

## Règles absolues
- Le traitement d'une commande vit dans un service, jamais dans `handle()`
- Le constructeur du service reçoit une fonction d'affichage `?Closure $info = null`, optionnelle, dernier paramètre
- Le service affiche uniquement par cette fonction, via sa méthode privée `info()`, qui journalise aussi le message
- Le service expose `run(array $data)`, appelé par `handle()` ; il ne lit ni `argument()`, ni `option()`, ni la requête
- La commande valide ses entrées avant d'appeler `run()` et rend `self::SUCCESS` ou `self::FAILURE`
- Une cascade entre services passe par un évènement et un listener (`bza-laravel:service-cascade`)
