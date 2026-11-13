---
name: filament-pages
description: Dans un projet Laravel avec Filament, écrire les pages d'une ressource — liste, création, édition, prévisualisation, page personnalisée —, leurs actions d'en-tête, fil d'Ariane et transformations de données.
---

## Quand utiliser ce skill
Pour toute page dans `Pages/` d'une ressource Filament. La structure de la
ressource est dans `bza-laravel:filament-resource`.

## Les pages

| Page | Classe de base | Route dans `getPages()` |
|---|---|---|
| `ListPosts` | `ListRecords` | `'index' => ListPosts::route('/')` |
| `CreatePost` | `CreateRecord` | `'create' => CreatePost::route('/create')` |
| `ViewPost` | `ViewRecord` | `'view' => ViewPost::route('/{record}')` |
| `EditPost` | `EditRecord` | `'edit' => EditPost::route('/{record}/edit')` |

Chaque page déclare `protected static string $resource = PostResource::class;`.
Une page sans comportement propre s'arrête là :

```php
class CreatePost extends CreateRecord
{
    protected static string $resource = PostResource::class;
}
```

## Procédure
1. **Actions d'en-tête** — `getHeaderActions()` :
   - liste : `CreateAction::make()` ;
   - prévisualisation : `EditAction::make()` ;
   - édition : `ViewAction::make()` s'il y a une page View, `DeleteAction::make()`,
     et les actions métier de la ressource.

   Une action métier réutilisée sur plusieurs pages est une classe
   (`PublishAction extends Action`, avec `getDefaultName()` et `setUp()`), pas une
   closure recopiée.
2. **Transformer les données** — dans la page, jamais dans le schéma :
   ```php
   protected function mutateFormDataBeforeCreate(array $data): array
   {
       $data['author_id'] = auth()->id();

       return $data;
   }
   ```
   `mutateFormDataBeforeSave()` en édition, `mutateFormDataBeforeFill()` pour
   préparer l'affichage. Une logique d'écriture qui dépasse le modèle (relations,
   fichiers, effets de bord) appelle le service du modèle
   (`bza-laravel:requete-service`) depuis `handleRecordCreation()` ou
   `handleRecordUpdate()`.
3. **Après l'écriture** — `afterCreate()`, `afterSave()` pour un effet de bord
   (purge de cache, notification) ; `getRedirectUrl()` pour la destination.
4. **Titre et fil d'Ariane** — `getBreadcrumb()` renvoie le titre de
   l'enregistrement quand il existe :
   ```php
   public function getBreadcrumb(): string
   {
       return $this->record->title ?? parent::getBreadcrumb();
   }
   ```
5. **Page personnalisée** — `php artisan make:filament-page <Nom> --resource=PostResource`,
   déclarée dans `getPages()`. Ses droits passent par la policy : `authorize()` dans
   `mount()`, ou une capacité dédiée (`bza-laravel:create-policy`).
6. **Tester** chaque page, statut Filament activé (`bza-laravel:filament-resource`) :
   accès autorisé (200), accès refusé (403), et chaque action d'en-tête :
   ```php
   livewire(EditPost::class, ['record' => $post->getKey()])
       ->callAction(DeleteAction::class);
   $this->assertSoftDeleted($post);
   ```

## Règles absolues
- Une page ne contient que son comportement propre : pas de champ, pas de colonne
- Les données se transforment dans les hooks de la page, l'écriture complexe dans le service
- Chaque action d'en-tête est autorisée par la policy
- Aucun libellé en dur
