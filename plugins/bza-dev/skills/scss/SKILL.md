---
name: scss
description: Écrire le SCSS d'un thème — BEM, structure des fichiers, variables, unités, responsive. À lire avant toute modification de style.
---

## Quand utiliser ce skill
Toute création ou modification de style.

## Fichiers
Racine SCSS : voir le skill de la pile (`id-<pile>:front-build`).

| Dossier | Contenu |
|---|---|
| `abstracts/shared/` | `_variables.scss` seulement |
| `abstracts/` | `_extensibles`, `_mixins`, `_functions` |
| `global/` | CSS global qui n'appartient à aucun bloc : `_css-variables`, `_animations`, `_colors-contexts` |
| `abstracts/bootstrap/` | imports Bootstrap (`_bootstrap-min.scss`) |
| `structure/` | mise en page : layouts, header, footer, navigation, fil d'Ariane |
| `text/` | typographie, polices, impression |
| `elements/` | boutons, liens, formulaires, éléments de page |
| `components/` | composants (dont ceux dotés de JS asynchrone) |

- Entrées compilées : `theme.scss` (styles du site) et `vendor.scss` (Bootstrap
  et bibliothèques). Chaque dossier a un `index.scss` qui liste ses partials.
- `abstracts/` ne produit **aucun** CSS : on peut l'importer dans n'importe quelle
  entrée (`ckeditor.scss` comprise) sans effet de bord. Tout ce qui écrit du CSS
  sans appartenir à un bloc va dans `global/`, importé **une seule fois**, par
  `theme.scss`, juste après `abstracts/` : variables CSS de `:root`, `@keyframes`
  partagées, couleurs des contextes (ex. cadre sombre).
- Un style de contexte (`global/_colors-contexts`) gagne par la **spécificité** de
  son sélecteur (`.frame.frame-background-dark …`), jamais par l'ordre
  d'import : pas de second import « en dernier ».
- Un partial inutilisé ne se supprime pas en cours de projet : on retire son
  `@import` de l'`index.scss` et on garde le fichier, qui pourra resservir. Les
  partials restés inutilisés se suppriment en fin de projet, quand on est
  certain qu'ils ne serviront pas.
- **Un fichier par composant ou élément**, nommé d'après son bloc BEM
  (`_main-nav.scss` pour `.main-nav`, `_site-header.scss` pour `.site-header`).
  On ne découpe pas un bloc en plusieurs fichiers à cause de sa taille : un bloc
  devenu énorme est le signe qu'il faut deux blocs.
- Bootstrap est inclus à la carte : ne garder dans `_bootstrap-min.scss` que ce
  que le projet utilise. Changer breakpoints ou containers impose de recompiler
  `vendor`.

## Nommage : BEM
- Bloc `.news-group`, élément `.news-group__item`, modificateur
  `.news-group--compact`. Pas d'éléments enchaînés (`__a__b`).
- Un composant varie selon son contexte par un modificateur ou par un sélecteur
  parent d'un seul niveau (`.footer .news-group`).
- Les classes du CMS, de Bootstrap et des bibliothèques ne se renomment pas.

## Écrire
- Imbrication : 4 niveaux au maximum (le bloc est le niveau 1), 3 dans la pratique.
- Dans une règle, les déclarations communes d'abord, puis les blocs `@media` écrits
  dans la règle ; plusieurs `@media` d'un même composant restent dans l'ordre croissant
  de leurs `min-width`, toujours après les déclarations communes. La règle ne vise pas
  les `@include`, `@extend` ou autres, même si un mixin émet un `@media` : un `@include`
  garde sa place.
- Styler par classe BEM (un ID d'élément unique est permis, `bza-dev:html`). Sur un
  même élément, ne pas mêler des règles préfixées par un ID et des modificateurs
  BEM : la spécificité de l'ID l'emporte et le modificateur perd. Éviter les
  sélecteurs `[data-…]` (`bza-dev:html`) ; les états natifs sont autorisés
  (`[aria-expanded="true"]`, `[hidden]`).
- Une variable de `abstracts/shared/_variables.scss` existe pour une valeur
  utilisée dans **au moins deux partials**, ou pour un point de réglage voulu et
  documenté (valeur de design à surcharger, comme le plafond d'un container). Une
  valeur propre à un seul élément s'écrit dans son partial. Les couleurs viennent
  toujours d'une variable : pas de couleur en dur dans un composant.
- Préférer `position: sticky` à `absolute` ou `fixed` pour un élément qui suit le
  défilement (colonne latérale, en-tête collant) ; `sticky` se pose sur le contenu
  de la colonne, pas sur la colonne. `fixed` et `absolute` restent pour les
  superpositions et les éléments hors flux (voile, volet, bouton flottant).
- Un élément `sticky` plus haut que l'espace visible reste atteignable : il gère
  son débordement (`overflow: auto` avec une `max-height` adaptée à son contexte,
  par exemple la hauteur de la fenêtre moins ce qui est déjà occupé au-dessus de
  lui).
- Police, interligne, marge basse et espacement de lettres : `@include
  font($size, $line-height, $margin-bottom, $letter-spacing)`.
- La marge basse **de base** d'un titre est une entrée de l'échelle typographique, par
  titre et par gabarit, passée par le 3e argument de `font()`. Elle règle les titres du
  texte courant (titres et paragraphes qui se suivent dans un texte riche). Un élément
  de contenu (carrousel, galerie, liste d'items…) peut avoir une autre marge basse sur
  un titre si la maquette le demande : il la pose dans son propre partial, sur son
  contexte (`.carousel h2`). Ce qu'on évite, c'est une marge de titre posée au hasard,
  hors de l'échelle, sans que la maquette l'explique.
- **Tailles** : pas de largeur en dur sur un élément placé dans une colonne ou un
  container (il prend 100 % de son parent) ; éviter les largeurs et hauteurs fixes. La
  taille ne vient jamais d'un contenu précis : on ne fixe pas une largeur, une hauteur
  ou une marge d'après un libellé ou une cote de maquette autour d'un texte variable.
  Un libellé peut passer à la ligne ; il ne déborde jamais de son conteneur. Un libellé
  trop long se raccourcit côté contribution, pas côté CSS. Une boîte tire sa hauteur de
  son contenu et de son `padding-block`.
- **Unités** : texte en `rem` ; espacements liés au texte en `rem` ou `em` ; mise en
  page, bordures et ombres en `px`. Les `px` sont des entiers, jamais à virgule (une cote
  à virgule s'arrondit comme une taille de police : 1,4 → 1 ; 1,5 → 2) ; `rem` et `em`
  peuvent être décimaux. Une même déclaration n'emploie qu'**une seule unité** : pas de
  `padding: 47px 18px 2rem 32px`. Une taille qui compense un autre élément se dérive de
  la variable de cet élément (`calc(var(--…) + …)`), jamais d'un nombre recopié à la main.
- `dvh` pour tout ce qui dépend de la hauteur visible sur mobile ; `vh` seulement quand
  le contenu ne doit pas bouger avec les barres du navigateur.
- Quand un en-tête ou une barre est fixe ou collant, `scroll-padding` (en haut, ou en
  bas pour une barre basse) évite qu'un élément focalisé passe dessous (WCAG 2.4.11).
- Toute animation ou transition a sa variante `@media (prefers-reduced-motion:
  reduce)` (`animation: none` ou `transition: none`).
- `!important` en dernier recours, avec un commentaire qui dit pourquoi.
- Les images SVG vivent dans des fichiers (`img/`, `icons/`), jamais en data-URI
  dans le SCSS.
- Les fonctions et modules natifs de Sass s'utilisent toujours par `@use`
  (`@use "sass:math"`, `sass:map`, `sass:color`, `sass:list`, `sass:string`), jamais
  par les fonctions globales dépréciées (`map-get`, `lighten`, `/` pour diviser).
- Nos propres partials : `@use` seulement s'il est possible sans rien perdre, sinon
  `@import`. Tant que le thème de base reste en `@import`, ce n'est pas une règle
  absolue : les variables et mixins du projet et du thème de base sont globaux par
  la chaîne d'`@import`, et un partial en `@use` ne les voit plus. `@use` sert aux
  modules natifs et aux modules autonomes. `@use "abstracts/shared" as *` échoue
  (variable en double), ne pas l'écrire. Les fichiers existants gardent leur
  `@import`. Les avertissements de dépréciation qui en découlent sont acceptés,
  jamais masqués (`silenceDeprecations`).
- Indentation : 4 espaces, sauf surcharge de la pile.

## Pied de page collé en bas
Le pied de page reste en bas même quand la page est courte : le conteneur de la
page est une colonne flex qui occupe au moins la hauteur de la fenêtre. Ce
conteneur est `body` quand on maîtrise tout ce qui s'y ajoute, sinon un wrapper
`.page` (voir la skill de la pile).

```scss
.page {
    min-height: 100dvh;
    display: flex;
    flex-direction: column;

    > header,
    > footer {
        flex-shrink: 0;
        flex-grow: 0;
    }

    > main {
        flex-grow: 1;
    }
}
```

## Responsive
- `$mobile-limit` est le seuil mobile/desktop de la page (Bootstrap `lg`, 992px par
  défaut). Le modifier demande une raison et l'accord de l'équipe.
- **Exception rare** : quand une navigation horizontale est trop large pour tenir
  jusqu'à `$mobile-limit`, elle peut basculer en burger plus tôt. Le projet déclare
  alors `$mobile-nav-limit`, supérieure à `$mobile-limit`, qui ne pilote que la
  navigation ; le reste de la page reste sur `$mobile-limit`. Cette variable demande
  une raison écrite et l'accord de l'équipe.
- Mobile d'abord : préférer `@media (min-width: $mobile-limit)`. `max-width` se tolère
  quand `min-width` obligerait à annuler des règles. Aucun point de rupture en px
  écrit à la main.
- Un composant qui a son propre point de rupture le déclare par `@container`, sans
  nouvelle variable de page.
- `global/_css-variables.scss` expose en variables CSS `$mobile-limit` (et
  `$mobile-nav-limit` quand elle existe), les couleurs, les polices et les dimensions
  que le JS peut lire.
