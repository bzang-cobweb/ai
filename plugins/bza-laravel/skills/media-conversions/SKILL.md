---
name: media-conversions
description: Dans un projet Laravel avec spatie/laravel-medialibrary, gérer une image envoyée (logo, photo, couverture) — réglages lus dans le .env via la config, collection, image enregistrée optimisée, une conversion par écran qui l'affiche, adresse avec repli, ressource d'API et listes qui demandent chacune la leur, champ Filament, tests. À utiliser dès qu'on ajoute ou retouche une collection de médias image, ses conversions ou leurs tailles.
---

## Quand utiliser ce skill
Pour toute image rattachée à un modèle par `HasMedia` et affichée par une API ou
un back-office : logo d'un partenaire, photo d'une offre, photo de profil. Une
collection existante qu'on retouche est ramenée à ce schéma si ses tailles sont
écrites en dur ou si un écran reçoit l'image d'origine.

## Le schéma

| Pièce | Rôle |
|---|---|
| `.env` / `.env.example` | les réglages : types acceptés, poids maximal, qualité, **une taille par écran** |
| `config/<module>.php` | les lit avec `env()` et leur donne une valeur par défaut ; seul endroit qui appelle `env()` |
| Modèle | la collection, une conversion par écran (bouclée sur la config), l'adresse avec repli |
| Service | enregistre l'image optimisée, depuis l'app comme depuis le back-office ; expose les réglages aux formulaires |
| Ressource d'API / liste | demande **la conversion de son écran**, jamais l'image d'origine |
| Champ Filament | passe par le même service |

Une règle, un domicile : une taille ne s'écrit qu'une fois, dans la config ; le
code ne contient que des **noms** de conversion.

## Procédure

1. **Nommer les écrans** — une conversion par endroit où l'image s'affiche, nommée
   d'après l'écran (`home`, `list`, `mine`, `detail`), pas d'après la taille
   (`thumb`, `small`) : deux écrans à la même taille aujourd'hui divergeront
   demain. La taille d'un écran se calcule : plus grand côté de l'emplacement en
   points × densité visée (3 pour un téléphone récent), puis arrondi ; un
   compromis plus bas se décide et se consigne.

2. **Réglages dans le `.env`** — un préfixe par image (`PARTNER_LOGO_`), ajouté à
   `.env.example` **et** au `.env` (skill `env`, jamais en éditant le fichier) :
   ```dotenv
   PARTNER_LOGO_MIME_TYPES=image/jpeg,image/png,image/webp
   PARTNER_LOGO_MAX_UPLOAD_KB=5120
   PARTNER_LOGO_QUALITY=85
   PARTNER_LOGO_HOME_SIZE=288
   PARTNER_LOGO_LIST_SIZE=168
   PARTNER_LOGO_MINE_SIZE=480
   PARTNER_LOGO_DETAIL_SIZE=360
   ```
   Pas de variable pour la taille de l'image enregistrée : elle se déduit des
   conversions (étape 5).

3. **Config** — dans la config du module (ou `config/media.php`), chaque valeur
   castée, une liste découpée proprement :
   ```php
   'logo' => [
       'mime_types' => array_values(array_filter(array_map('trim', explode(',', (string) env('PARTNER_LOGO_MIME_TYPES', 'image/jpeg,image/png,image/webp'))))),
       'max_upload_kb' => (int) env('PARTNER_LOGO_MAX_UPLOAD_KB', 5120),
       'quality' => (int) env('PARTNER_LOGO_QUALITY', 85),
       'conversions' => [
           'home' => (int) env('PARTNER_LOGO_HOME_SIZE', 288),
           'list' => (int) env('PARTNER_LOGO_LIST_SIZE', 168),
           'mine' => (int) env('PARTNER_LOGO_MINE_SIZE', 480),
           'detail' => (int) env('PARTNER_LOGO_DETAIL_SIZE', 360),
       ],
   ],
   ```
   Le code lit `config('partner.logo.…')`, jamais `env()` : avec le cache de
   configuration, `env()` hors de `config/` renvoie `null`.

4. **Modèle : collection et conversions** — la collection nommée par une
   constante ; les conversions bouclées sur la config, restreintes à la
   collection :
   ```php
   public const LOGO = 'logo';

   public function registerMediaCollections(): void
   {
       $this->addMediaCollection(self::LOGO)->singleFile()->useDisk('public');
   }

   public function registerMediaConversions(?Media $media = null): void
   {
       foreach ((array) config('partner.logo.conversions') as $name => $size) {
           $this->addMediaConversion((string) $name)
               ->performOnCollections(self::LOGO)
               ->fit(Fit::Max, (int) $size, (int) $size)
               ->format('webp')
               ->quality((int) config('partner.logo.quality'))
               ->nonOptimized()
               ->nonQueued();
       }
   }
   ```
   - `Fit::Max` : le plus grand côté tient dans la taille, les proportions sont
     gardées, l'image n'est jamais agrandie — un logo en bandeau reste un
     bandeau. `Fit::Crop` seulement si l'écran exige un format fixe, décidé.
   - `nonQueued()` quand aucune file ne tourne en production ; sinon les laisser
     en file et accepter le repli de l'étape 6 le temps du traitement.
   - `nonOptimized()` : l'image source est déjà optimisée par le service ; sans
     les binaires d'optimisation installés, l'optimiseur ne ferait qu'échouer en
     silence.
   - Plusieurs collections sur un modèle : une boucle par collection, chacune
     avec ses `performOnCollections`.

5. **Service : l'image enregistrée** — un service par image
   (`PartnerLogoService`, skill `requete-service`) qui expose les réglages et
   enregistre une version optimisée, jamais l'original :
   ```php
   public static function acceptedMimeTypes(): array { return config('partner.logo.mime_types'); }
   public static function maxUploadKb(): int { return (int) config('partner.logo.max_upload_kb'); }

   /** La plus grande des conversions : la source de toutes, une image n'étant jamais agrandie. */
   public static function storedSize(): int
   {
       $sizes = array_map('intval', (array) config('partner.logo.conversions'));
       if ($sizes === []) {
           return 512;
       }

       return max($sizes);
   }

   public function store(Partner $partner, string $sourcePath, ?string $name = null): Media
   {
       $base = (string) tempnam(sys_get_temp_dir(), 'partner');
       $optimised = $base.'.webp';

       try {
           Image::load($sourcePath)
               ->orientation()
               ->fit(Fit::Max, self::storedSize(), self::storedSize())
               ->quality((int) config('partner.logo.quality'))
               ->format('webp')
               ->save($optimised);

           $media = $partner->addMedia($optimised)
               ->usingFileName(($name ?? (string) Str::uuid()).'.webp')
               ->toMediaCollection(Partner::LOGO);
       } finally {
           foreach ([$base, $optimised] as $path) {
               if (is_file($path)) {
                   unlink($path);
               }
           }
       }

       $partner->unsetRelation('media');

       return $media;
   }
   ```
   - La taille enregistrée = la plus grande conversion : plus grand, on stocke
     des pixels qu'aucun écran ne montre ; plus petit, la plus grande conversion
     serait floue. Pas de réglage à part, qui finirait par diverger.
   - `orientation()` applique l'EXIF avant de redimensionner (photos de téléphone).
   - `unsetRelation('media')` : sans lui, le modèle garde l'ancienne liste en
     mémoire et `getFirstMedia()` renvoie l'image remplacée.
   - Le minimum utile à l'envoi est la plus grande conversion ; un envoi plus
     petit est accepté (il n'est pas agrandi) sauf décision contraire.

6. **Adresse avec repli** — une méthode du modèle, que tous les écrans appellent :
   ```php
   public function logoUrl(?string $conversion = null): ?string
   {
       $media = $this->getFirstMedia(self::LOGO);
       if ($media === null) {
           return null;
       }
       if ($conversion === null) {
           return $media->getUrl();
       }
       if (! $media->hasGeneratedConversion($conversion)) {
           return $media->getUrl();
       }

       return $media->getUrl($conversion);
   }
   ```
   Le repli sert l'image enregistrée tant que la conversion n'existe pas (image
   antérieure à la conversion, file pas encore passée) : jamais une adresse
   cassée.

7. **Chaque écran demande la sienne** — la ressource d'API (skill
   `api-resource`) a une conversion par défaut et une méthode par variante ; une
   liste passe le nom de son écran :
   ```php
   private string $logoConversion = 'home';

   public function withContact(): static
   {
       $this->withContact = true;
       $this->logoConversion = 'detail';

       return $this;
   }

   // toArray()
   'logo' => $this->resource->logoUrl($this->logoConversion),
   ```
   Un écran qui reçoit `logoUrl()` sans nom télécharge l'image enregistrée, la
   plus lourde : c'est un défaut à corriger. Charger `media` avec la requête
   (`->with('media')`) pour une liste.

8. **Champ Filament** — le même service, pour que le back-office enregistre la
   même image que l'app (skill `filament-schema`) :
   ```php
   SpatieMediaLibraryFileUpload::make('logo')
       ->collection(Partner::LOGO)
       ->image()
       ->acceptedFileTypes(PartnerLogoService::acceptedMimeTypes())
       ->maxSize(PartnerLogoService::maxUploadKb())
       ->saveUploadedFileUsing(
           fn (TemporaryUploadedFile $file, Partner $record): string => app(PartnerLogoService::class)
               ->store($record, $file->getRealPath())
               ->uuid,
       ),
   ```
   La validation d'un formulaire de l'app lit les mêmes méthodes
   (`mimetypes:` et `max:`).

9. **Images existantes** — après l'ajout ou le changement d'une taille :
   ```
   php artisan media-library:regenerate "Modules\Partner\Models\Partner" --force
   ```
   Une conversion supprimée de la config laisse ses fichiers sur le disque :
   les retirer par `--force` après régénération, ou le noter.

10. **Tests** :
    - chaque conversion est produite, à sa taille **lue dans la config** : en
      changer une dans le test (`config([...'list' => 100])`) prouve qu'elle
      n'est pas écrite en dur ; mesurer le grand côté avec `getimagesize()` sur
      `Storage::fake('public')` ;
    - chaque écran reçoit la sienne : l'adresse renvoyée par chaque route ou
      liste contient `-<conversion>.webp` ;
    - le repli : `$media->markAsConversionNotGenerated('home')` puis
      `save()`, l'adresse est celle de l'image ;
    - l'image enregistrée ne dépasse pas la plus grande conversion.
    `UploadedFile::fake()->image('x.png', 2000, 1000)` fournit la source ; la
    garder dans une variable tant qu'on la lit.

## Règles absolues
- Une taille, un type accepté, un poids ou une qualité ne s'écrit jamais dans le code : `.env` → config → code
- `env()` n'est appelé que dans `config/`
- Une conversion par écran, nommée d'après l'écran ; chaque écran demande la sienne
- L'image enregistrée est optimisée et bornée à la plus grande conversion ; l'original n'est pas gardé sauf décision
- L'app et le back-office enregistrent par le même service
- L'adresse d'une conversion non produite se replie sur l'image enregistrée
- Les tests prouvent les tailles lues dans la config et la conversion servie par chaque écran
