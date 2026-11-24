---
name: media-conversions
description: Dans un projet Laravel avec spatie/laravel-medialibrary, gérer une image envoyée (logo, photo, avatar) — une classe abstraite qui lit les réglages (.env → config) et enregistre l'image (optimisée, bornée à la plus grande conversion ou original plafonné, jamais agrandie), une conversion par écran, adresse avec repli, taille minimale et maximale à l'envoi tirées du cadre de l'image, ressource d'API et listes qui demandent chacune la leur, champ Filament, tests. À utiliser dès qu'on ajoute ou retouche une collection de médias image, ses conversions, ses tailles ou sa validation.
---

## Quand utiliser ce skill
Pour toute image rattachée à un modèle par `HasMedia` et affichée par une API ou
un back-office : logo d'un partenaire, photos d'une offre, photo de profil. Une
image existante qu'on retouche est ramenée à ce schéma si ses tailles sont écrites
en dur, si un écran reçoit l'image enregistrée, ou si son service recopie
l'enregistrement ou la validation d'un autre.

## Le schéma

| Pièce | Rôle |
|---|---|
| `.env` / `.env.example` | les réglages de chaque image : types, poids, qualité, **une taille par écran**, plafond d'original (facultatif), dimension maximale |
| `config/<module>.php` | les lit avec `env()`, castés, avec une valeur par défaut ; seul endroit qui appelle `env()` |
| Classe abstraite (`ConfiguredImageService`) | lit tous les réglages, en déduit la taille enregistrée et les règles d'envoi, **enregistre** l'image |
| Service de l'image (`PartnerLogoService`…) | l'étend : sa clé de config, sa collection, son cadre ou son recadrage s'ils diffèrent, l'envoi depuis l'app |
| Modèle | la collection, une conversion par écran (bouclée sur le service), l'adresse avec repli |
| Ressource d'API / liste | demande **la conversion de son écran**, jamais l'image enregistrée |
| Champ de l'app / Filament | les règles et l'aide du service, l'enregistrement par le service |

Une règle, un domicile : une taille ne s'écrit qu'une fois, dans la config ; le
code ne contient que des **noms** de conversion ; la lecture des réglages,
l'enregistrement et la validation ne s'écrivent qu'une fois, dans la classe
abstraite.

## Procédure

1. **Nommer les écrans et calculer leur taille** — une conversion par endroit où
   l'image s'affiche, nommée d'après l'écran (`home`, `list`, `detail`), jamais
   d'après la taille (`thumb`). Deux écrans de même taille peuvent partager une
   conversion ; elle prend alors la taille du plus grand.
   - Taille = plus grand côté de la place **réellement occupée**, en points ×
     densité, sur le plus grand appareil visé, arrondi. Densité : 3 pour un
     iPhone et la plupart des Android, 3,5 pour les Android les plus denses, 2
     pour un site web.
   - Une image affichée en entier (`contain`) dans un cadre d'une autre forme
     est bornée par le côté le plus court du cadre : un logo carré dans une zone
     16:9 de 360 × 203 points occupe 203 × 203 points.
   - Les pixels ne changent pas la place à l'écran, seulement la netteté. Une
     image « trop petite à l'écran » vient du cadre (marge, forme), pas de la
     conversion.
   - Une conversion n'apporte presque rien quand sa place est à peine plus petite
     que l'image enregistrée ; elle est indispensable quand l'écart est grand
     (une carte de 540 px pour une photo de 1920 px : poids, mémoire décodée,
     données mobiles, vitesse d'un site).

2. **Réglages dans le `.env`** — un préfixe par image, ajouté à `.env.example`
   **et** au `.env` (skill `env`, jamais en éditant le fichier) :
   ```dotenv
   PARTNER_LOGO_MIME_TYPES=image/jpeg,image/png,image/webp
   PARTNER_LOGO_MAX_UPLOAD_KB=5120
   PARTNER_LOGO_MAX_DIMENSION=10000
   PARTNER_LOGO_QUALITY=85
   PARTNER_LOGO_HOME_SIZE=288
   PARTNER_LOGO_LIST_SIZE=360
   PARTNER_LOGO_DETAIL_SIZE=720
   # Seulement si l'original est gardé (étape 4, choix B) :
   AUTH_AVATAR_ORIGINAL_SIZE=720
   ```
   Pas de réglage pour la taille enregistrée hors choix B, ni pour le minimum à
   l'envoi : ils se déduisent (étapes 4 et 5).

3. **Config** — dans la config du module, chaque valeur castée, une liste
   découpée proprement, chaque conversion commentée avec sa place en points :
   ```php
   'logo' => [
       'mime_types' => array_values(array_filter(array_map('trim', explode(',', (string) env('PARTNER_LOGO_MIME_TYPES', 'image/jpeg,image/png,image/webp'))))),
       'max_upload_kb' => (int) env('PARTNER_LOGO_MAX_UPLOAD_KB', 5120),
       // Garde-fou contre une image démesurée à décoder.
       'max_dimension' => (int) env('PARTNER_LOGO_MAX_DIMENSION', 10000),
       'quality' => (int) env('PARTNER_LOGO_QUALITY', 85),
       'conversions' => [
           // Le carrousel de l'accueil (96 points).
           'home' => (int) env('PARTNER_LOGO_HOME_SIZE', 288),
           // La liste, logo à gauche (72 points).
           'list' => (int) env('PARTNER_LOGO_LIST_SIZE', 360),
           // La page du partenaire, en grand.
           'detail' => (int) env('PARTNER_LOGO_DETAIL_SIZE', 720),
       ],
   ],
   ```
   Le code lit la config, jamais `env()` : avec le cache de configuration,
   `env()` hors de `config/` renvoie `null`.

4. **Classe abstraite : réglages et enregistrement** — une seule classe
   (`app/Support/Media/ConfiguredImageService.php`), que chaque service d'image
   étend. Elle lit `config(static::configKey().'.<nom>')` et expose :

   | Méthode | Rend |
   |---|---|
   | `acceptedMimeTypes()`, `maxUploadKb()`, `maxFiles()` (1 sans réglage), `quality()`, `maxDimension()` (10 000 sans réglage) | les réglages |
   | `conversions()`, `conversionSize($name)`, `largestConversion()` | les conversions |
   | `storedSize()` | la taille de l'image enregistrée (ci-dessous) |
   | `minUploadSize()` | `storedSize()` (étape 5) |
   | `uploadRules()` | les règles d'un fichier envoyé (étape 5) |
   | `store(HasMedia $model, string $sourcePath, ?string $name = null): Media` | l'enregistrement |
   | `storeUpload(HasMedia $model, FormUpload $upload): Media` (protégée) | un fichier en attente d'un formulaire de l'app, enregistré puis retiré |

   Points d'extension, redéfinis par un service seulement s'il diffère :
   `configKey()` et `collection()` (abstraites), `mediaName()` (la collection par
   défaut), `bounds(int $size)` (le cadre : un carré par défaut), `fit()`
   (`Fit::Max` par défaut, `Fit::Crop` pour un format imposé) et
   `fileName(?string $name)` (l'identifiant de l'envoi ou un uuid, en `.webp`).

   **La taille enregistrée** — le fichier envoyé tel quel (4000 px d'un
   téléphone) n'est jamais gardé. Deux choix, à décider et consigner :

   | | A. Bornée à la plus grande conversion | B. Original gardé, plafonné |
   |---|---|---|
   | `storedSize()` | `largestConversion()` | `original_size` du réglage |
   | Agrandir une conversion plus tard | sans effet sur les images déjà là | jusqu'au plafond, sans les redemander |
   | Quand | photos nombreuses, logo | image ouverte en grand ou coûteuse à redemander (photo de profil) |

   Ne jamais promettre qu'une image envoyée plus grande servira plus tard : ce
   qui dépasse `storedSize()` est perdu à l'enregistrement.

   **L'enregistrement** :
   ```php
   public function store(HasMedia $model, string $sourcePath, ?string $name = null): Media
   {
       $base = (string) tempnam(sys_get_temp_dir(), 'image');
       $optimised = $base.'.webp';
       [$width, $height] = static::bounds(static::storedSize());

       try {
           $image = Image::load($sourcePath)->orientation();
           // Recadrer remplit le cadre, quitte à agrandir : le cadre est réduit à ce que l'image couvre.
           if (static::fit() === Fit::Crop) {
               $scale = min(1, $image->getWidth() / $width, $image->getHeight() / $height);
               $width = max(1, (int) floor($width * $scale));
               $height = max(1, (int) floor($height * $scale));
           }

           $image->fit(static::fit(), $width, $height)
               ->quality(static::quality())
               ->format('webp')
               ->save($optimised);

           $media = $model->addMedia($optimised)
               ->usingName(static::mediaName())
               ->usingFileName(static::fileName($name))
               ->toMediaCollection(static::collection());
       } finally {
           foreach ([$base, $optimised] as $path) {
               if (is_file($path)) {
                   unlink($path);
               }
           }
       }

       // Sans quoi le modèle garde ses anciens médias, et `getFirstMedia()` l'image remplacée.
       if ($model instanceof Model) {
           $model->unsetRelation('media');
       }

       return $media;
   }
   ```
   - `orientation()` applique l'EXIF avant de redimensionner.
   - `Fit::Max` ne grandit jamais une image ; `Fit::Crop` si, d'où le cadre
     réduit.
   - Une photo qui remplit un cadre 16:9 (`cover`) se borne par sa **largeur** :
     son service redéfinit `bounds()` en `[$size, 4 * $size]`, et une photo en
     hauteur garde toute la largeur de la carte.

   Un service d'image ne garde que ce qui lui est propre :
   ```php
   class PartnerLogoService extends ConfiguredImageService
   {
       public const FIELD = 'logo';

       protected static function configKey(): string
       {
           return 'partner.logo';
       }

       protected static function collection(): string
       {
           return Partner::LOGO;
       }

       // + sync()/current() : l'envoi depuis l'app, avec storeUpload().
   }
   ```

5. **Taille minimale et maximale à l'envoi** — le minimum est `storedSize()` :
   ni l'image enregistrée, qui peut s'ouvrir en grand, ni aucune conversion ne
   doit être un agrandissement. `uploadRules()` tire la règle du cadre
   (`bounds(minUploadSize())`) et du mode (`fit()`), et y joint toujours le
   maximum :

   | Image | Cadre / mode | Ce qu'il faut | Règle |
   |---|---|---|---|
   | Photo de profil | carré, recadrée | largeur **et** hauteur ≥ cadre | `dimensions:min_width,min_height` |
   | Photo d'une offre | bornée par la largeur | largeur ≥ cadre | `dimensions:min_width` |
   | (cadre plus large que haut) | entière | hauteur ≥ cadre | `dimensions:min_height` |
   | Logo | carré, entier | largeur **ou** hauteur ≥ cadre | `MinImageSide` (le plus grand côté) |

   ```php
   public static function uploadRules(): array
   {
       $dimensions = Rule::dimensions()->maxWidth(static::maxDimension())->maxHeight(static::maxDimension());
       $size = static::minUploadSize();
       if ($size <= 0) {
           return [$dimensions];
       }

       [$width, $height] = static::bounds($size);
       if (static::fit() === Fit::Crop) {
           return [$dimensions->minWidth($width)->minHeight($height)];
       }
       if ($width === $height) {
           return [$dimensions, new MinImageSide($width)];
       }
       if ($height > $width) {
           return [$dimensions->minWidth($width)];
       }

       return [$dimensions->minHeight($height)];
   }
   ```
   - `dimensions` ne sait pas dire « le plus grand côté » : seul le carré entier
     a besoin d'une règle à part (`MinImageSide`, qui compare
     `max(largeur, hauteur)`).
   - Le maximum (`max_dimension`, 10 000) est un **garde-fou de décodage**, pas
     une taille d'affichage : une image d'une couleur de 30 000 × 30 000 pèse
     quelques centaines de Ko mais occupe des gigaoctets décodée. Il reste bien
     au-dessus de ce que produit un téléphone (4000 px) ; la réduction se fait à
     l'enregistrement.
   - Le message d'un refus `dimensions` est celui de Laravel, commun à toutes
     les règles `dimensions` : c'est l'aide du champ qui annonce le minimum, avec
     le même nombre (« au moins 1920 px de large », « Logo carré, au moins 720 ×
     720 px »).

6. **Modèle : collection, conversions, adresse avec repli** :
   ```php
   public function registerMediaCollections(): void
   {
       $this->addMediaCollection(self::LOGO)->singleFile()->useDisk('public');
   }

   public function registerMediaConversions(?Media $media = null): void
   {
       foreach (PartnerLogoService::conversions() as $name => $size) {
           [$width, $height] = PartnerLogoService::bounds($size);
           $this->addMediaConversion($name)
               ->performOnCollections(self::LOGO)
               ->fit(Fit::Max, $width, $height) // Fit::Crop pour un format imposé
               ->format('webp')
               ->quality(PartnerLogoService::quality())
               ->nonOptimized()
               ->nonQueued();
       }
   }

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
   - `nonQueued()` quand aucune file ne tourne en production ; sinon le repli
     sert l'image enregistrée le temps du traitement.
   - `nonOptimized()` : l'image source est déjà optimisée par le service.
   - Le repli sert l'image enregistrée tant que la conversion n'existe pas :
     jamais une adresse cassée.

7. **Chaque écran demande la sienne** — la ressource d'API (skill
   `api-resource`) a une conversion par défaut et une méthode par variante ; une
   liste passe le nom de son écran ; l'aperçu d'un champ de formulaire aussi.
   Un écran qui reçoit l'adresse sans nom télécharge l'image enregistrée, la
   plus lourde : c'est un défaut à corriger. Charger `media` avec la requête
   (`->with('media')`) pour une liste.

8. **Champs** — le même service partout :
   ```php
   // App (formulaire générique) :
   Field::upload(PartnerLogoService::FIELD)
       ->accept(PartnerLogoService::acceptedMimeTypes())
       ->maxSize(PartnerLogoService::maxUploadKb())
       ->maxFiles(PartnerLogoService::maxFiles())
       ->uploadRules(PartnerLogoService::uploadRules())
       ->help(__('partner::partner.fields.logo_help', ['pixels' => PartnerLogoService::minUploadSize()]));

   // Back-office :
   SpatieMediaLibraryFileUpload::make('logo')
       ->collection(Partner::LOGO)
       ->image()
       ->acceptedFileTypes(PartnerLogoService::acceptedMimeTypes())
       ->maxSize(PartnerLogoService::maxUploadKb())
       ->rules(PartnerLogoService::uploadRules())
       ->helperText(__('partner::partner.fields.logo_help', ['pixels' => PartnerLogoService::minUploadSize()]))
       ->saveUploadedFileUsing(
           fn (TemporaryUploadedFile $file, Partner $record): string => app(PartnerLogoService::class)
               ->store($record, $file->getRealPath())
               ->uuid,
       );
   ```
   Une validation écrite à la main (envoi de la photo de profil) ajoute aussi
   `...Service::uploadRules()`. Les données de démo enregistrent par
   `store()`, comme le reste.

9. **Images existantes** — après l'ajout ou le changement d'une taille :
   ```
   php artisan media-library:regenerate "Modules\Partner\Models\Partner" --force
   ```
   - Une image enregistrée plus petite qu'une nouvelle taille n'est pas
     agrandie : seules les images envoyées ensuite en profitent.
   - Retirer une conversion de la config laisse ses fichiers sur le disque, et
     même quand l'image est remplacée, Spatie ne les efface plus. Régénérer avec
     `--force` **avant** de la retirer, ou supprimer les fichiers
     `-<conversion>.webp` restés, puis les dossiers vides.

10. **Tests** :
    - la classe abstraite, par une sous-classe anonyme : la taille enregistrée
      (choix A et B), le minimum, la règle de chaque cadre et mode (carré,
      recadré, borné par la largeur), le maximum lu dans la config ;
    - chaque conversion produite, à sa taille **lue dans la config** : en
      changer une dans le test prouve qu'elle n'est pas en dur ; mesurer avec
      `getimagesize()` sur `Storage::fake('public')` ;
    - l'image enregistrée a la taille du choix retenu ; recadrée, une petite
      image n'est pas agrandie ;
    - chaque écran reçoit la sienne (`-<conversion>.webp` dans l'adresse) ;
    - le repli : `markAsConversionNotGenerated()`, puis l'adresse de l'image ;
    - l'envoi refuse une image d'un pixel sous le minimum, sur le bon côté
      (une photo en hauteur trop étroite, un avatar trop bas), et au-dessus du
      maximum ; l'aide affiche le même nombre.
    `UploadedFile::fake()->image('x.png', 2000, 1000)` fournit la source ; la
    garder dans une variable tant qu'on la lit.

## Règles absolues
- Une taille, un type, un poids, une qualité ou une dimension maximale ne s'écrit jamais dans le code : `.env` → config → code
- `env()` n'est appelé que dans `config/`
- Les réglages, l'enregistrement et les règles d'envoi d'une image vivent dans la classe abstraite ; un service ne déclare que sa clé, sa collection et ce qui diffère
- Une conversion par écran, nommée d'après l'écran ; chaque écran demande la sienne, aucun ne sert l'image enregistrée
- L'image enregistrée est optimisée, plafonnée (plus grande conversion ou original plafonné décidé) et jamais agrandie, recadrage compris
- Le minimum à l'envoi est la taille enregistrée, vérifié sur le côté que le cadre et le mode exigent ; le maximum est toujours joint ; l'aide du champ annonce le même nombre
- L'app, le back-office et les données de démo enregistrent par le même service
- L'adresse d'une conversion non produite se replie sur l'image enregistrée
- Les tests prouvent les tailles lues dans la config, la conversion servie par chaque écran et les refus à l'envoi
