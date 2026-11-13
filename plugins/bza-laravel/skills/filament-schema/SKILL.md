---
name: filament-schema
description: Dans un projet Laravel avec Filament, écrire le formulaire de création et d'édition d'une ressource ou d'un relation manager — onglets, champs, validation, champs dépendants, champs riches.
---

## Quand utiliser ce skill
Pour tout formulaire Filament : `Schemas/<Modèle>Form.php` d'une ressource, ou la
méthode `form()` d'un relation manager. La structure de la ressource est dans
`bza-laravel:filament-resource`.

## La classe
```php
abstract class PostForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->columns(1)
            ->components([
                Tabs::make('Tabs')->tabs([
                    static::getGeneralTab(),
                    AbstractResource::getAccessTab(),
                ]),
            ]);
    }

    public static function getGeneralTab(): Tab
    {
        return Tab::make(__('post.tabs.general'))->schema([
            TextInput::make('title')
                ->label(__('post.title'))
                ->maxLength(255)
                ->live(onBlur: true)
                ->afterStateUpdated(fn (Set $set, ?string $state) => $set('slug', Str::slug($state)))
                ->required(),
            TextInput::make('slug')
                ->label(__('post.slug'))
                ->unique(ignoreRecord: true)
                ->required(),
            Select::make('category_id')
                ->label(__('post.category'))
                ->relationship('category', 'name')
                ->searchable()
                ->preload()
                ->required(),
        ]);
    }
}
```

## Procédure
1. **Découper** — un onglet ou une section par groupe de champs, chacun dans sa
   méthode statique (`getGeneralTab()`). Un onglet commun à plusieurs ressources
   vient de la classe de base.
2. **Valider dans le champ** — chaque contrainte de la colonne se retrouve sur son
   champ : `required()`, `maxLength()` aligné sur la colonne, `unique(ignoreRecord: true)`,
   `numeric()`, `email()`. Le formulaire Filament ne passe pas par une
   FormRequest : si le même modèle est aussi écrit par une API
   (`bza-laravel:requete-service`), les deux jeux de règles se comparent ; une
   divergence se signale.
3. **Relations** — `Select::make('category_id')->relationship('category', 'name')`
   plutôt que des options construites à la main ; `searchable()` et `preload()`
   pour une liste longue.
4. **Champs dépendants** — `live(onBlur: true)` et `afterStateUpdated()` pour
   dériver une valeur (slug) ; `visible(fn (Get $get) => …)` pour afficher un champ
   selon un autre. `live()` sans `onBlur` déclenche un aller-retour serveur à chaque
   frappe.
5. **Champs riches** — un éditeur HTML stocke du HTML : il est assaini à
   l'enregistrement et à l'affichage par l'assainisseur du projet. Un champ texte
   brut reste un `TextInput` ou un `Textarea`.
6. **Champs traduisibles** — placés dans la structure que le plugin de traduction
   du projet attend, pour recevoir la valeur d'une locale et non le tableau JSON.
7. **Transformer avant écriture** — une transformation des données se fait dans la
   page (`mutateFormDataBeforeCreate()`, `mutateFormDataBeforeSave()`,
   `bza-laravel:filament-pages`), pas dans le schéma.
8. **Tester** sur les pages de création et d'édition, statut Filament activé
   (`bza-laravel:filament-resource`) :
   ```php
   livewire(CreatePost::class)
       ->fillForm(['title' => 'Titre', 'slug' => 'titre', 'category_id' => $category->id])
       ->call('create')
       ->assertHasNoFormErrors();
   $this->assertDatabaseHas(Post::class, ['slug' => 'titre']);

   livewire(CreatePost::class)
       ->fillForm(['title' => ''])
       ->call('create')
       ->assertHasFormErrors(['title' => 'required']);
   ```

## Règles absolues
- Chaque contrainte de la colonne est déclarée sur son champ
- Aucun libellé en dur
- Un champ HTML riche est assaini ; un champ texte brut n'est jamais un éditeur riche
- Le schéma décrit les champs ; les transformations de données vivent dans la page
