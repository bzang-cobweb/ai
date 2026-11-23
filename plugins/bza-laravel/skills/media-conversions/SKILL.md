---
name: media-conversions
description: Dans un projet Laravel avec spatie/laravel-medialibrary, gérer une image envoyée (logo, photo, couverture) — réglages lus dans le .env via la config, collection, image enregistrée optimisée (bornée à la plus grande conversion ou original plafonné), taille minimale à l'envoi, une conversion par écran qui l'affiche, adresse avec repli, ressource d'API et listes qui demandent chacune la leur, champ Filament, tests. À utiliser dès qu'on ajoute ou retouche une collection de médias image, ses conversions ou leurs tailles.
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
| Service | enregistre l'image (étape 5), depuis l'app comme depuis le back-office ; expose les réglages et le minimum à l'envoi aux formulaires |
| Ressource d'API / liste | demande **la conversion de son écran**, jamais l'image d'origine |
| Champ Filament | passe par le même service |

Une règle, un domicile : une taille ne s'écrit qu'une fois, dans la config ; le
code ne contient que des **noms** de conversion.

## Procédure

1. **Nommer les écrans** — une conversion par endroit où l'image s'affiche, nommée
   d'après l'écran (`home`, `list`, `mine`, `detail`), pas d'après la taille
   (`thumb`, `small`) : deux écrans à la même taille aujourd'hui divergeront
   demain. La taille d'un écran se calcule : plus grand côté de l'emplacement en
   points × densité visée, sur le plus grand appareil visé, puis arrondi ; un
   compromis plus bas se décide et se consigne.
   - Densité : 3 pour un iPhone et la plupart des Android ; 3,5 pour les
     Android les plus denses ; 2 pour un site web (écran Retina).
   - Emplacement : la place que l'image **occupe vraiment**. Une image affichée
     en entier (`contain`) dans un cadre d'une autre forme est bornée par le
     côté le plus court du cadre : un logo carré dans une zone 16:9 de
     360 × 203 points occupe 203 × 203 points, soit 609 px à 3.
   - Les pixels ne changent pas la place à l'écran, seulement la netteté :
     l'app étire l'image dans son cadre. Une image « trop petite à l'écran »
     vient du cadre (marge, forme), pas de la conversion.
   - Deux places servies par une même conversion : elle prend la taille de la
     plus grande, et la plus petite télécharge des pixels en trop. Une
     conversion n'apporte rien quand sa place est à peine plus petite que
     l'image enregistrée ; elle est indispensable quand l'écart est grand
     (une carte de 540 px pour une photo de 1920 px).

2. **Réglages dans le `.env`** — un préfixe par image (`PARTNER_LOGO_`), ajouté à
   `.env.example` **et** au `.env` (skill `env`, jamais en éditant le fichier) :
   ```dotenv
   PARTNER_LOGO_MIME_TYPES=image/jpeg,image/png,image/webp
   PARTNER_LOGO_MAX_UPLOAD_KB=5120
   PARTNER_LOGO_QUALITY=85
   PARTNER_LOGO_ORIGINAL_SIZE=1024
   PARTNER_LOGO_HOME_SIZE=288
   PARTNER_LOGO_LIST_SIZE=720
   PARTNER_LOGO_DETAIL_SIZE=360
   ```
   `*_ORIGINAL_SIZE` seulement si l'original est gardé (étape 5, choix B) ;
   sinon la taille enregistrée se déduit des conversions, sans variable.

3. **Config** — dans la config du module (ou `config/media.php`), chaque valeur
   castée, une liste découpée proprement :
   ```php
   'logo' => [
       'mime_types' => array_values(array_filter(array_map('trim', explode(',', (string) env('PARTNER_LOGO_MIME_TYPES', 'image/jpeg,image/png,image/webp'))))),
       'max_upload_kb' => (int) env('PARTNER_LOGO_MAX_UPLOAD_KB', 5120),
       'quality' => (int) env('PARTNER_LOGO_QUALITY', 85),
       // L'original gardé, plafonné à ce plus grand côté (choix B de l'étape 5).
       'original_size' => (int) env('PARTNER_LOGO_ORIGINAL_SIZE', 1024),
       'conversions' => [
           // Une ligne par écran, avec sa place en points : la taille se relit.
           'home' => (int) env('PARTNER_LOGO_HOME_SIZE', 288),
           'list' => (int) env('PARTNER_LOGO_LIST_SIZE', 720),
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
   - Une photo qui remplit un cadre 16:9 (`cover`) se borne par sa **largeur**
     (`fit(Fit::Max, $width, 4 * $width)`) : une photo en hauteur garde ainsi
     toute la largeur de la carte.
   - `nonOptimized()` : l'image source est déjà optimisée par le service ; sans
     les binaires d'optimisation installés, l'optimiseur ne ferait qu'échouer en
     silence.
   - Plusieurs collections sur un modèle : une boucle par collection, chacune
     avec ses `performOnCollections`.

5. **Service : l'image enregistrée** — un service par image
   (`PartnerLogoService`, skill `requete-service`) qui expose les réglages et
   enregistre l'image en WebP, optimisée et plafonnée. Le fichier envoyé tel
   quel (4000 px d'un téléphone) n'est jamais gardé. Deux choix pour le
   plafond, à décider et consigner :

   | | A. Bornée à la plus grande conversion | B. Original gardé, plafonné |
   |---|---|---|
   | `storedSize()` | `max(config('…conversions'))` | `config('…original_size')` |
   | Agrandir une conversion plus tard | sans effet sur les images déjà là | jusqu'au plafond, sans redemander les images |
   | Stockage | au plus juste | un peu plus lourd |
   | Quand | photos nombreuses (offres), avatar | image rare et coûteuse à redemander (logo d'un partenaire) |

   Dans les deux cas, aucun écran ne sert l'image enregistrée : chacun demande
   sa conversion (étape 7).
   ```php
   public static function acceptedMimeTypes(): array { return config('partner.logo.mime_types'); }
   public static function maxUploadKb(): int { return (int) config('partner.logo.max_upload_kb'); }

   // A. Bornée à la plus grande conversion, la source de toutes.
   public static function storedSize(): int
   {
       $sizes = array_map('intval', (array) config('partner.logo.conversions'));
       if ($sizes === []) {
           return 512;
       }

       return max($sizes);
   }

   // B. L'original gardé, plafonné.
   public static function storedSize(): int
   {
       return (int) config('partner.logo.original_size');
   }

   /** Le minimum à l'envoi : la conversion de la plus grande place, jamais un agrandissement. */
   public static function minUploadSize(): int
   {
       return (int) config('partner.logo.conversions.list');
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
   - Choix A : plus grand que la plus grande conversion, on stocke des pixels
     qu'aucun écran ne montre ; plus petit, elle serait floue. Pas de réglage à
     part, qui finirait par diverger. Choix B : un seul réglage, le plafond.
     Ne jamais promettre qu'une image envoyée plus grande servira plus tard si
     elle est réduite à l'enregistrement : ce qui dépasse le plafond est perdu.
   - `orientation()` applique l'EXIF avant de redimensionner (photos de téléphone).
   - `unsetRelation('media')` : sans lui, le modèle garde l'ancienne liste en
     mémoire et `getFirstMedia()` renvoie l'image remplacée.
   - Le minimum à l'envoi est la conversion de la plus grande place où l'image
     s'affiche (`minUploadSize()`) : plus petite, elle y serait agrandie, donc
     floue. Il se vérifie sur le **plus grand côté** (un bandeau de 1600 × 400
     passe pour 720), par une règle de validation commune (`MinImageSide`,
     ci-dessous) ; l'aide du champ le dit (« Logo carré, au moins 720 × 720
     px. »), avec le même nombre. Un format (carré) se demande dans l'aide ; il
     ne s'impose qu'après décision.
     ```php
     final class MinImageSide implements ValidationRule
     {
         public function __construct(private readonly int $pixels) {}

         public function validate(string $attribute, mixed $value, Closure $fail): void
         {
             if (! $value instanceof UploadedFile) {
                 return;
             }
             $size = @getimagesize((string) $value->getRealPath());
             if ($size === false) {
                 return; // pas une image : la règle du type s'en charge
             }
             if (max((int) $size[0], (int) $size[1]) < $this->pixels) {
                 $fail('form::validation.image_min_side')->translate(['pixels' => (string) $this->pixels]);
             }
         }
     }
     ```

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
   plus lourde : c'est un défaut à corriger, aperçu d'un champ de formulaire
   compris. Charger `media` avec la requête (`->with('media')`) pour une liste.

8. **Champ Filament** — le même service, pour que le back-office enregistre la
   même image que l'app (skill `filament-schema`) :
   ```php
   SpatieMediaLibraryFileUpload::make('logo')
       ->collection(Partner::LOGO)
       ->image()
       ->acceptedFileTypes(PartnerLogoService::acceptedMimeTypes())
       ->maxSize(PartnerLogoService::maxUploadKb())
       ->rule(new MinImageSide(PartnerLogoService::minUploadSize()))
       ->helperText(__('partner::partner.fields.logo_help', ['pixels' => PartnerLogoService::minUploadSize()]))
       ->saveUploadedFileUsing(
           fn (TemporaryUploadedFile $file, Partner $record): string => app(PartnerLogoService::class)
               ->store($record, $file->getRealPath())
               ->uuid,
       ),
   ```
   La validation d'un formulaire de l'app lit les mêmes méthodes
   (`mimetypes:`, `max:`, `MinImageSide`) et la même aide. Un champ de
   plusieurs fichiers (photos) se range comme les autres : les fichiers envoyés
   un à un passent par le service (`store()`), seul l'ordre est rangé à part.

9. **Images existantes** — après l'ajout ou le changement d'une taille :
   ```
   php artisan media-library:regenerate "Modules\Partner\Models\Partner" --force
   ```
   Une image enregistrée plus petite qu'une nouvelle taille n'est pas
   agrandie : seules les images envoyées ensuite en profitent (choix B :
   jusqu'au plafond).

   Retirer une conversion de la config : ses fichiers restent sur le disque,
   et même quand l'image est remplacée, Spatie ne les efface plus (il ne
   connaît plus la conversion). Régénérer avec `--force` **avant** de la
   retirer, ou supprimer les fichiers `-<conversion>.webp` restés, puis les
   dossiers vides.

10. **Tests** :
    - chaque conversion est produite, à sa taille **lue dans la config** : en
      changer une dans le test (`config([...'list' => 100])`) prouve qu'elle
      n'est pas écrite en dur ; mesurer le grand côté avec `getimagesize()` sur
      `Storage::fake('public')` ;
    - chaque écran reçoit la sienne : l'adresse renvoyée par chaque route ou
      liste contient `-<conversion>.webp` ;
    - le repli : `$media->markAsConversionNotGenerated('home')` puis
      `save()`, l'adresse est celle de l'image ;
    - l'image enregistrée a la taille du choix retenu (plus grande conversion,
      ou plafond de l'original) ;
    - l'envoi refuse une image d'un pixel sous le minimum, avec son message, et
      accepte un bandeau et une image en hauteur dont le grand côté suffit ;
      l'aide du champ affiche le même nombre.
    `UploadedFile::fake()->image('x.png', 2000, 1000)` fournit la source ; la
    garder dans une variable tant qu'on la lit.

## Règles absolues
- Une taille, un type accepté, un poids ou une qualité ne s'écrit jamais dans le code : `.env` → config → code
- `env()` n'est appelé que dans `config/`
- Une conversion par écran, nommée d'après l'écran ; chaque écran demande la sienne
- L'image enregistrée est optimisée et plafonnée : à la plus grande conversion, ou à un plafond d'original décidé ; aucun écran ne la sert
- Le minimum à l'envoi est la conversion de la plus grande place, vérifié sur le plus grand côté, et l'aide du champ affiche le même nombre
- L'app et le back-office enregistrent par le même service
- L'adresse d'une conversion non produite se replie sur l'image enregistrée
- Les tests prouvent les tailles lues dans la config et la conversion servie par chaque écran
