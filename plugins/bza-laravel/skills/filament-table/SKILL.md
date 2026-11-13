---
name: filament-table
description: Dans un projet Laravel avec Filament, écrire la table de la vue de liste d'une ressource ou d'un relation manager — colonnes, compteurs, tri, recherche, filtres, actions, suppression douce.
---

## Quand utiliser ce skill
Pour toute table Filament : `Tables/<Modèle>Table.php` d'une ressource, ou la
méthode `table()` d'un relation manager. La structure de la ressource est dans
`bza-laravel:filament-resource`.

## La classe
```php
abstract class PostTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->reorderable('sorting')
            ->defaultSort('sorting')
            ->columns([
                ToggleColumn::make('enabled')->label(__('post.enabled')),
                TextColumn::make('title')->label(__('post.title'))
                    ->sortable()
                    ->searchable(),
                TextColumn::make('author.name')->label(__('post.author')),
                TextColumn::make('comments_count')->label(__('comment.plural'))
                    ->counts(['comments' => fn (Builder $query) => $query->withTrashed()])
                    ->sortable(),
            ])
            ->filters([
                TrashedFilter::make(),
            ])
            ->recordActions(AbstractResource::getActions())
            ->toolbarActions(AbstractResource::getBulkActions());
    }
}
```

## Procédure
1. **Colonnes** — une colonne par donnée utile à la liste, libellé traduit.
   `searchable()` et `sortable()` uniquement sur une colonne de la requête : une
   colonne de la table, une relation (`author.name`), ou un agrégat déclaré.
2. **Compteurs et agrégats** — toujours par la requête : `->counts('comments')`,
   `->sum('lines', 'amount')`, `->exists('comments')`. Pour compter aussi les
   lignes supprimées en douceur, passer une closure :
   `->counts(['comments' => fn (Builder $query) => $query->withTrashed()])`.
   Un `getStateUsing(fn ($record) => $record->comments()->count())` fait une
   requête par ligne, et son `sortable()` trie sur une colonne qui n'existe pas
   dans la requête.
3. **Relations affichées** — une colonne `author.name` est chargée par Filament ;
   une valeur calculée qui touche une relation se charge dans
   `->modifyQueryUsing(fn (Builder $query) => $query->with('author'))`.
4. **Filtres** — les filtres partagés entre ressources viennent de la classe de
   base. Un `SelectFilter` construit ses options par une requête ciblée
   (`pluck`), jamais par `Model::all()`.
5. **Suppression douce** — `TrashedFilter::make()` plutôt qu'un
   `withoutGlobalScopes([SoftDeletingScope::class])` qui affiche toujours les
   lignes supprimées. Les actions `RestoreAction` et `ForceDeleteAction` suivent.
6. **Actions** — ligne : `recordActions()`, sélection : `toolbarActions()`, en-tête :
   `headerActions()`. Les jeux d'actions communs viennent de la classe de base ;
   chaque action est autorisée par la policy (`bza-laravel:create-policy`).
7. **Ordre manuel** — `reorderable('sorting')` avec `defaultSort('sorting')` ; la
   policy porte `reorder`.
8. **Tester** sur la page de liste, statut Filament activé
   (`bza-laravel:filament-resource`) :
   ```php
   livewire(ListPosts::class)
       ->assertCanSeeTableRecords($posts)
       ->sortTable('comments_count')
       ->assertCanSeeTableRecords($posts->sortBy('comments_count'), inOrder: true)
       ->searchTable($posts->first()->title)
       ->assertCountTableRecords(1);
   ```
   Chaque colonne `sortable()` et `searchable()` est exercée une fois.

## Règles absolues
- Aucune requête par ligne : compteurs et relations passent par la requête de la table
- `sortable()` et `searchable()` seulement sur ce que la requête contient
- Aucun libellé en dur
- Une action de table n'est visible que si la policy l'autorise
