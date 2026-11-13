---
name: html
description: Écrire le HTML d'un template ou d'un composant — sémantique, SEO, accessibilité, Bootstrap. À lire avant tout balisage.
---

## Quand utiliser ce skill
Toute création ou modification de balisage (template, composant, gabarit de page).

## Principe
Le HTML le plus simple qui exprime le contenu. Le style et le comportement se
branchent sur lui, jamais l'inverse.

## Structure
- HTML5 valide (W3C), sémantique : `<main>`, `<nav>`, `<header>`, `<footer>`,
  `<article>`, `<section>`, `<aside>`, `<figure>`, `<dialog>`, `<details>`, chacun
  pour son usage.
- `<main id="…">` porte l'ancre du lien d'évitement. Pas de `role` redondant avec
  l'élément, pas d'ancre `<a id>` vide.
- Un seul `<h1>` par page, niveaux de titres consécutifs.
- Chaque élément a une raison d'être. Un `<div>` se justifie (mise en page,
  hook d'animation) ; un `<div>` sans classe est un signal : le supprimer. Ni
  enveloppe « au cas où », ni élément vide.
- Un bloc peut être une `<section>` si on peut lui donner un titre qui a du sens,
  où qu'il soit dans la page ; sinon c'est un `<div>`. Ce n'est jamais une
  obligation.
- Un seul balisage par contenu : le responsive se règle en CSS. Pas de copie
  mobile et de copie desktop d'une même liste ou d'un même bouton.
- `<button>` pour agir, `<a href>` pour naviguer. Jamais `<div onclick>`.

## Classes
- Nom clair qui décrit l'élément, en BEM (`bza-dev:scss`).
- Une classe par élément dans le balisage écrit par le projet ; un modificateur
  seulement quand une variante le justifie.
- Le contexte d'un composant (main, aside, footer) se règle en SCSS, pas en
  ajoutant des classes au HTML (`bza-dev:scss`).
- Un titre (`<h1>` à `<h6>`) ne porte pas de classe, sauf raison précise : un titre qui
  diffère du titre de base dans un composant se cible par son contexte en SCSS
  (`.textmedia h2 { … }`), pas par une classe posée sur le titre. C'est l'exception à
  « une classe par élément ».
- Les classes générées par le CMS ou un framework (`frame-*`, `paragraph--*`,
  utilitaires Bootstrap) restent telles quelles.
- Un `.container` (quelle qu'en soit la variante) ou une `.row` écrit par le projet ne
  porte aucune autre classe ni aucun autre style que le colonnage. Le contenu qui a sa
  propre classe vit dans un enfant : `<div class="container"><div class="home">…</div></div>`,
  pas `<div class="home container">`. Ce qu'une brique ou le CMS génère reste tel quel.
- Un container ne s'imbrique pas dans un autre (fluid ou non) : c'est une mauvaise
  conception du HTML. Quand un composant généré en produit un, on neutralise son effet
  en SCSS (pas de seconde marge ni de padding), sans toucher au balisage généré.
- Un ID est autorisé sur un élément unique de la page (`#page-header`,
  `#page-footer`).
- Le JS se branche sur la classe BEM de l'élément, ou sur l'ID d'un élément unique
  (`bza-dev:js`). Éviter les `data-*` quand une classe, un attribut ARIA ou `hidden`
  fait le travail ; ils restent légitimes quand ils sont justifiés (bibliothèques
  comme Bootstrap et lightGallery, CMS, donnée transmise au JS).

## Accessibilité
Chaque composant est utilisable **au clavier**, au minimum.
- Éléments interactifs atteignables par Tab ; widget sur mesure : `tabindex="0"`
  plus gestionnaire `keydown` ; focus piégé dans une modale ; jamais de
  `tabindex` supérieur à 0.
- **Focus visible** : l'anneau est présent par défaut (`:focus-visible`), contour de
  2px, décalage de 2px, contraste 3:1. Jamais de `outline: none` qui supprime un
  indicateur sans le remplacer. La largeur du contour a un seul domicile dans le thème
  (une variable) ; les champs de formulaire ont un indicateur au clavier.
- ARIA pour les éléments **sans texte visible** : `aria-label` sur un bouton-icône,
  `aria-labelledby` sur un groupe. Un texte visible est déjà le nom : pas d'ARIA
  en plus. Pas d'attribut ARIA sans rôle qui le porte.
- État exprimé par les attributs natifs : `aria-expanded`, `hidden`, `inert`.
  `hidden` exprime un état, jamais une présentation : on ne le contourne pas en CSS
  (`[hidden] { display: block !important }`). Soit le JS ne pose `hidden` que dans la
  présentation où le contenu est masqué (`matchMedia`), soit l'état passe par
  `aria-expanded` et une classe.
- Lien d'évitement en premier dans `<body>` : `<a class="visually-hidden-focusable"
  href="#…">`.
- Toute `<img>` a un attribut `alt` : image informative = son contenu, décorative
  = `alt=""`, fonctionnelle = l'action, complexe = `alt` court plus description liée.
- Lien `target="_blank"` : `rel="noopener"` et indication accessible d'ouverture
  dans une nouvelle fenêtre.
- Chaque champ de formulaire a un `<label>` associé.

## Découpage de la page
- La page se découpe en sections sémantiques (`<header>`, `<section>`, `<footer>`)
  qui contiennent chacune leur `.container`. La section porte le fond, le
  container porte le contenu.
- Un média ou un bandeau pleine largeur se place directement dans sa section, sans
  container.
- Un seul container autour de tout le contenu de la page est un signe de mauvais
  découpage : il empêche d'insérer plus tard un bloc pleine largeur.

```html
<body>
  <a class="visually-hidden-focusable" href="#…">…</a>
  <header id="page-header"><div class="container">…</div></header>
  <main id="…">
    <section><div class="container">…</div></section>
    <section>…</section>
  </main>
  <footer id="page-footer"><div class="container">…</div></footer>
</body>
```

## Bootstrap
- Le contenu se place dans un container Bootstrap : `.container` ou
  `.container-fluid`, au choix du projet (la décision est consignée par projet).
- Bootstrap 5 fournit container, row et colonnes. Une colonne se déclare par son
  seul point de rupture : `col-lg-9`, pas `col-12 col-lg-9` (sous le point de
  rupture, une colonne fait déjà 100 %).
- Une colonne (`.col-lg-9`) a toujours une `.row` pour parent direct : la `row`
  compense le padding des colonnes par sa marge négative. Une `row` peut ne
  contenir qu'une seule colonne, par exemple un contenu étroit décalé
  (`<div class="row"><div class="col-lg-8 offset-lg-1">`).
- Un contenu qui occupe toute la largeur du container se place directement dans le
  container, **sans `row` ni `col`**.
- Un composant Bootstrap existe (accordéon, onglets, collapse, modale,
  carrousel) : l'utiliser. Du code sur mesure demande une raison écrite.
- Ni Tailwind ni autre framework CSS : demander avant.

## SEO
- Contenu porteur de sens dans le HTML, titres cohérents, liens explicites.
