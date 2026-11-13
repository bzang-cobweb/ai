---
name: filament-resource
description: Dans un projet Laravel avec Filament, créer ou modifier une ressource Filament — structure de dossiers, classe Resource, droits, libellés, navigation. Point d'entrée vers les skills de table, formulaire, infolist, pages et relation managers.
---

## Quand utiliser ce skill
Pour toute création ou modification d'une ressource Filament. Ce skill fixe la
structure ; le détail de chaque partie est dans son propre skill.

## Structure
Une ressource est une classe courte qui délègue chaque vue à une classe dédiée :

```
Filament/Resources/
├── PostResource.php
└── PostResource/
    ├── Tables/PostTable.php                 → bza-laravel:filament-table
    ├── Schemas/PostForm.php                 → bza-laravel:filament-schema
    ├── InfoLists/PostInfolist.php           → bza-laravel:filament-infolist
    ├── Pages/ListPosts.php, CreatePost.php,
    │   EditPost.php, ViewPost.php           → bza-laravel:filament-pages
    └── RelationManagers/CommentsRelationManager.php
                                             → bza-laravel:filament-relation-manager
```

Seuls les dossiers utilisés existent : une ressource sans prévisualisation n'a ni
`InfoLists/` ni `ViewPost`.

## Procédure
1. **Générer** : `php artisan make:filament-resource Post` (ajouter `--view` pour
   une prévisualisation, `--soft-deletes` si le modèle en a). Le générateur
   nomme la table au pluriel (`PostsTable`) et range l'infolist dans
   `Schemas/PostInfolist.php` : renommer en `PostTable` et déplacer l'infolist
   dans `InfoLists/`, namespace compris.
2. **Écrire la classe Resource** — elle ne contient que du câblage :
   ```php
   class PostResource extends AbstractResource
   {
       protected static ?string $model = Post::class;

       protected static ?int $navigationSort = 30;

       public static function form(Schema $schema): Schema
       {
           return PostForm::configure($schema);
       }

       public static function infolist(Schema $schema): Schema
       {
           return PostInfolist::configure($schema);
       }

       public static function table(Table $table): Table
       {
           return PostTable::configure($table);
       }

       public static function getRelations(): array
       {
           return [CommentsRelationManager::class];
       }

       public static function getPages(): array
       {
           return [
               'index' => ListPosts::route('/'),
               'create' => CreatePost::route('/create'),
               'view' => ViewPost::route('/{record}'),
               'edit' => EditPost::route('/{record}/edit'),
           ];
       }

       public static function getModelLabel(): string
       {
           return __('post.singular');
       }

       public static function getPluralModelLabel(): string
       {
           return __('post.plural');
       }
   }
   ```
3. **Factoriser** ce qui se répète entre ressources (filtres, champs, onglets,
   jeux d'actions) dans une classe de base abstraite (`AbstractResource extends
   Resource`) du module ou de l'application, en méthodes statiques. Une ressource
   l'étend au lieu de dupliquer.
4. **Droits** — l'accès à chaque vue et à chaque action Filament dépend de la
   méthode correspondante de la policy du modèle :

   | Vue ou action Filament | Méthode de policy |
   |---|---|
   | liste, entrée de menu | `viewAny` |
   | prévisualisation | `view` |
   | création | `create` |
   | édition | `update` |
   | suppression, suppression groupée | `delete`, `deleteAny` |
   | restauration, suppression définitive | `restore`, `restoreAny`, `forceDelete`, `forceDeleteAny` |
   | ordre manuel, duplication | `reorder`, `replicate` |
   | relation manager | `attach`, `detach`, `associate`, `dissociate` sur le modèle enfant |

   Chaque méthode distingue la requête Filament des autres requêtes
   (`bza-laravel:create-policy`). Une méthode absente refuse, et Filament masque
   l'action.
5. **Navigation** — `$navigationSort`, et un groupe par module via la classe de
   base. Masquer l'entrée de menu ne retire aucun droit : l'accès reste décidé par
   `viewAny`.
6. **Libellés** — tous les libellés passent par les traductions (`__()`), y compris
   les modèles, colonnes, champs, onglets et titres.
7. **Tests Livewire** — `livewire(ListPosts::class)` ne passe pas par les
   middlewares du panneau : `Filament::isServing()` y vaut `false`, et la policy
   répond par sa branche hors Filament. Activer le statut dans le `setUp()` des
   tests Filament :
   ```php
   protected function setUp(): void
   {
       parent::setUp();

       Filament::setCurrentPanel('admin');
       Filament::setServingStatus();
   }
   ```

## Règles absolues
- La classe Resource ne contient que du câblage : formulaire, table et infolist vivent dans leurs classes
- Chaque vue et chaque action est autorisée par la méthode correspondante de la policy du modèle, jamais par une condition dans la ressource
- Un test Livewire de Filament active `Filament::setServingStatus()`
- Aucun libellé en dur
- Un comportement répété dans deux ressources va dans la classe de base
