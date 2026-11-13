---
name: front-build
description: Front d'un projet Laravel — SCSS/JS dans resources/css/front et resources/js, build Vite.
---

## Quand utiliser ce skill
Toute tâche SCSS, JS ou build dans un projet Laravel. Il complète `bza-dev:html`,
`bza-dev:scss`, `bza-dev:js` et `bza-dev:front-build`, et se lit avec `bza-laravel:blade` pour
les vues. Laravel compile avec **Vite**, pas avec Webpack. L'indentation est celle de la
règle générale (4 espaces), sauf si le projet en décide autrement.

## Où sont les fichiers
- SCSS : `resources/css/front`. JS : `resources/js`. Mêmes noms de dossiers que
  dans les autres projets.
- Absents d'un projet sous Vite : `bricks.js`, `theme.js`, `fix-public-path.js`, les
  configs Webpack.
- Les points d'entrée se déclarent dans `vite.config.js` et se chargent depuis
  Blade avec `@vite(...)`.

## Écrire
- Modules seulement : `import`, jamais `require` (Vite ne gère pas le CommonJS
  dans les sources).
- Les composants asynchrones utilisent l'`import()` dynamique comme dans
  `bza-dev:js` ; Vite crée les chunks.

## HMR et build
Avec Vite : `npm run dev` pour le HMR, `npm run build` pour la production (il remplace
`npm run prod` dans « Fin de tâche »). Certains projets Laravel compilent encore avec
Webpack : leurs commandes, dont le HMR, sont celles de leur `package.json`.

## À compléter (pas encore documenté à partir d'un vrai projet Laravel)
- Scripts exacts de `package.json` et conventions de `vite.config.js` (alias,
  liste des entrées).
- Support des anciens navigateurs (`@vitejs/plugin-legacy`) si un projet en a besoin.
- Où se déclarent les équivalents de `vendor.scss` et `theme.scss`.
