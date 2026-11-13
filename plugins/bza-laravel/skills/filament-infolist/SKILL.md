---
name: filament-infolist
description: Dans un projet Laravel avec Filament, écrire l'infolist de la vue de prévisualisation d'une ressource — entrées, mise en page, page View, accès en lecture seule.
---

## Quand utiliser ce skill
Quand une ressource doit montrer un enregistrement en lecture seule : la page
`View<Modèle>`. La structure de la ressource est dans `bza-laravel:filament-resource`.

## La classe
`InfoLists/<Modèle>Infolist.php` — le générateur (`make:filament-resource --view`)
la crée dans `Schemas/PostInfolist.php` : la déplacer, namespace compris.

```php
abstract class PostInfolist
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->columns(1)
            ->components([
                Section::make(__('post.tabs.general'))->schema([
                    TextEntry::make('title')->label(__('post.title')),
                    TextEntry::make('category.name')->label(__('post.category')),
                    IconEntry::make('enabled')->label(__('post.enabled'))->boolean(),
                    TextEntry::make('published_at')->label(__('post.published_at'))->dateTime(),
                ]),
                Section::make(__('comment.plural'))->schema([
                    RepeatableEntry::make('comments')->label('')->schema([
                        TextEntry::make('title')->label(__('comment.title')),
                    ]),
                ]),
            ]);
    }
}
```

## Procédure
1. **Entrées** — une entrée par donnée à montrer, de `Filament\Infolists\Components`
   (`TextEntry`, `IconEntry`, `ImageEntry`, `RepeatableEntry`), libellé traduit.
   Mise en page avec `Filament\Schemas\Components` (`Section`, `Grid`, `Tabs`),
   en reprenant les onglets du formulaire quand ils existent.
2. **Formats** — formater dans l'entrée : `->dateTime()`, `->boolean()`,
   `->badge()`, `->money()`, `->formatStateUsing()`.
3. **HTML** — `TextEntry::make('body')->html()` rend sans échappement : la valeur
   passe par l'assainisseur d'affichage du projet. Un champ texte brut ne prend
   jamais `->html()`.
4. **Relations** — `category.name` ou `RepeatableEntry::make('comments')` ; un
   compteur passe par `->counts('comments')`.
5. **Brancher** — `PostResource::infolist()` délègue à `PostInfolist::configure()`,
   la page `'view' => ViewPost::route('/{record}')` est déclarée dans
   `getPages()`, et la table expose `ViewAction::make()` dans ses `recordActions()`.
   La page `ViewPost` étend `ViewRecord` et propose `EditAction::make()` en
   en-tête (`bza-laravel:filament-pages`).
6. **Droits** — la page est autorisée par la méthode `view` de la policy
   (`bza-laravel:create-policy`).
7. **Tester**, statut Filament activé (`bza-laravel:filament-resource`) :
   ```php
   livewire(ViewPost::class, ['record' => $post->getKey()])
       ->assertOk()
       ->assertSchemaStateSet(['title' => $post->title])
       ->assertSee($post->category->name);
   ```
   Plus un compte sans `view` : 403.

## Règles absolues
- L'infolist est en lecture seule : aucune action d'écriture dans ses entrées
- Une entrée `->html()` reçoit une valeur assainie
- Aucun libellé en dur
- La page View est autorisée par `view`, jamais par une condition dans la page
