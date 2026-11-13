---
name: filament-relation-manager
description: Dans un projet Laravel avec Filament, écrire un relation manager — onglet d'une relation sur la page d'édition ou de prévisualisation d'une ressource : table, formulaire en modale ou page dédiée, attachement, titre avec compteur.
---

## Quand utiliser ce skill
Pour toute relation gérée depuis la page d'un enregistrement : `hasMany`,
`belongsToMany`, `morphMany`… La structure de la ressource est dans
`bza-laravel:filament-resource`.

## La classe
```php
class CommentsRelationManager extends RelationManager
{
    protected static string $relationship = 'comments';

    public function form(Schema $schema): Schema
    {
        return CommentForm::configure($schema);
    }

    public function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('title')
            ->columns([
                TextColumn::make('title')->label(__('comment.title'))->sortable()->searchable(),
            ])
            ->headerActions([CreateAction::make()])
            ->recordActions(AbstractResource::getActions(stickyModal: true))
            ->toolbarActions(AbstractResource::getBulkActions());
    }

    public static function getTitle(Model $ownerRecord, string $pageClass): string
    {
        return __('comment.plural') . ' (' . $ownerRecord->comments()->count() . ')';
    }

    public static function getModelLabel(): string
    {
        return __('comment.singular');
    }

    public static function getPluralModelLabel(): string
    {
        return __('comment.plural');
    }
}
```

## Procédure
1. **Générer** : `php artisan make:filament-relation-manager PostResource comments title`,
   puis déclarer la classe dans `PostResource::getRelations()`.
2. **Table** — mêmes règles que `bza-laravel:filament-table`, compteurs par la
   requête compris. `recordTitleAttribute()` nomme l'enregistrement dans les
   modales et les messages.
3. **Formulaire** — choisir où s'édite l'enfant :
   - enfant simple : `form()` en modale. Si l'enfant a sa propre ressource, réutiliser
     son schéma (`CommentForm::configure($schema)`) au lieu de le recopier ;
   - enfant riche (onglets, relations propres) : pas de `form()`, et des actions
     qui ouvrent la page de sa ressource :
     `EditAction::make()->url(fn (Comment $record) => CommentResource::getUrl('edit', ['record' => $record]))`.
4. **Plusieurs-à-plusieurs** — `AttachAction` et `DetachAction` (ou
   `AssociateAction` et `DissociateAction` pour un `hasMany`) ; colonnes du pivot
   par `withPivot()` sur la relation. La policy de l'enfant porte `attach`,
   `detach`, `associate`, `dissociate` (`bza-laravel:create-policy`).
5. **Titre** — `getTitle()` avec un compteur : une seule requête `count()`, sans
   charger la relation.
6. **Même relation sur plusieurs ressources** — une classe abstraite commune
   (`AbstractDocumentsRelationManager`) ; chaque ressource l'étend en ne
   redéfinissant que ce qui change.
7. **Affichage conditionnel** — `canViewForRecord(Model $ownerRecord, string $pageClass)`
   pour masquer l'onglet selon l'enregistrement ; il s'ajoute à la policy, il ne la
   remplace pas.
8. **Tester**, statut Filament activé (`bza-laravel:filament-resource`) :
   ```php
   livewire(CommentsRelationManager::class, [
       'ownerRecord' => $post,
       'pageClass' => EditPost::class,
   ])
       ->assertCanSeeTableRecords($post->comments)
       ->assertCountTableRecords($post->comments()->count());
   ```

## Règles absolues
- Un formulaire d'enfant n'est jamais recopié : il réutilise le schéma de sa ressource
- Compteurs et colonnes passent par la requête, jamais par une requête par ligne
- Chaque action (créer, attacher, détacher) est autorisée par la policy de l'enfant
- Aucun libellé en dur
