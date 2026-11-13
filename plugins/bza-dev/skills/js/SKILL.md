---
name: js
description: Écrire le JavaScript d'un thème — style, structure des fichiers, crochets DOM, chargement asynchrone, mobile/desktop. À lire avant tout JS.
---

## Quand utiliser ce skill
Toute création ou modification de JavaScript.

## Structure
Racine JS : voir le skill de la pile (`id-<pile>:front-build`).

- `index.js` : point d'entrée, importe le reste et déclenche les chargements
  asynchrones.
- `app.js` : initialisation globale.
- `components/` : composants chargés à la demande. `elements/` : éléments de la
  page (navigation, en-tête). `utils/` : utilitaires.
- Un fichier, une responsabilité. Un fichier dans le bon dossier ; un nouveau
  dossier seulement s'il clarifie.

## Style
- ES2015+, modules : `import` et `export`, jamais `require` ni `module.exports`.
- Point-virgule à chaque instruction, accolades à chaque bloc, `===` et `!==`.
- `const` par défaut, `let` quand la valeur change, jamais `var`.
- Fonctions fléchées quand c'est possible.
- Indentation : 4 espaces, sauf surcharge de la pile.
- Tout le code est commenté : un commentaire court par fonction (JSDoc), une
  ligne par bloc qui n'est pas évident. Une seule langue de commentaire par
  projet. Un commentaire décrit le code ; les tickets, lots et décisions
  restent dans les specs et les messages de commit.
- `console.log` sert à déboguer et disparaît avant la fin de la tâche.
  `console.warn` et `console.error` restent pour un vrai problème.
- Pas de code mort : variable, import ou fonction inutilisés se suppriment.
- Le linter du projet applique ces règles (`bza-dev:front-build`, « Fin de tâche »).

## Se brancher sur le HTML
- Le JS trouve un élément par sa **classe BEM** (`querySelector('.main-nav')`) ou,
  pour un élément unique de la page, par son **ID** (`getElementById('page-header')`).
  Pas de classes `js-` ; pour les `data-*`, `bza-dev:html`.
- L'état (ouvert, fermé, actif) passe par les attributs natifs (`bza-dev:html`) ou par
  une classe de modificateur (`main-nav--open`), jamais par un `data-*`.
- Une initialisation ne s'applique qu'une fois par élément (idempotente).

## Mobile et desktop
- Pour savoir si l'on est au-dessus ou au-dessous du seuil mobile, appeler
  `getIsMobileDisplay()` de `utils/adaptative.js`. Un autre fichier ne lit jamais
  `--mobile-limit` lui-même et n'écrit jamais un `992` ou un `(min-width: …)` en dur.
  Quand le projet déclare `$mobile-nav-limit` (`bza-dev:scss`), la navigation lit
  `--mobile-nav-limit` par une méthode d'`adaptative`, jamais par un calcul à part.
- `utils/adaptative.js` centralise l'état mobile, desktop et tactile et le
  redistribue : réagir aux changements par `onResizeMobileCallbacks`,
  `onResizeDesktopCallbacks`, `onResizeChangeCallbacks`. S'il manque une information
  (une donnée d'UA-parser, par exemple), on ajoute une méthode dans `adaptative`,
  pas un calcul dans un autre fichier.

## Composants asynchrones
Un composant qui n'est pas utile sur toutes les pages vit dans `components/` et
se charge depuis `index.js` seulement si son sélecteur est dans le DOM :

```javascript
document.addEventListener('DOMContentLoaded', () => {
    if (document.querySelector('.lightgallery')) {
        import('./components/lightgallery');
    }
});
```

Il s'initialise seul et gère le cas où le DOM est déjà prêt (`document.readyState`).
Son SCSS est dans `components/_<nom>.scss`.

## Bibliothèques
- Bootstrap JS : importer le plugin utile (`bootstrap/js/dist/collapse`), pas le
  bundle entier.
- Toute nouvelle dépendance npm est justifiée et demandée avant.
