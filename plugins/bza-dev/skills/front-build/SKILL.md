---
name: front-build
description: Compiler et livrer le front — commandes, début de projet (Node LTS, npm login, audit, update), critères de fin de tâche.
---

## Quand utiliser ce skill
Au démarrage d'un projet, avant d'installer ou de mettre à jour des paquets npm,
et à la fin de toute tâche front.

## Compilation
- Vite, ou parfois Webpack selon le projet (détail : `bza-laravel:front-build`).
- **Deux commandes seulement** : `npm run watch` pour travailler, `npm run prod` avant de
  commiter (détail et exceptions : `bza-laravel:front-build`). Quand la pile a deux builds
  (moderne et legacy), jamais l'un sans l'autre : ils sortent ensemble de `prod`, sinon les
  navigateurs récents et anciens ne recevraient pas le même code.
- Les fichiers générés (`dist`) ne s'éditent jamais à la main.
- `vendor/`, `node_modules/` et les thèmes de base ne se modifient jamais :
  on surcharge dans le thème du projet.

## Début de projet
1. **Node LTS** : la dernière version LTS, inscrite dans `.nvmrc`. Une version non
   LTS est une décision humaine, consignée dans le registre des décisions (`.ia/context/decisions/`).
2. **Accès npm** : pour un paquet privé, `npm whoami` doit afficher le nom de
   l'utilisateur ; sur un `401` ou un `404`, demander à l'humain `npm login`. Ne
   jamais lire, afficher ni commiter `~/.npmrc`.
3. `npm install`. Modifier `package.json` ou un lockfile demande l'autorisation de
   l'humain (`bza:lois/git.md`, « dépendances ») : la demander avant
   toute mise à jour.
4. `npm audit` : lister les vulnérabilités par gravité, les **critical** d'abord.
5. `npm outdated` : noter les paquets figés exprès (version exacte dans
   `package.json`) ; signaler les majeures, ne pas les appliquer.
6. `npm update` (reste dans les plages semver). Jamais `--force`, jamais
   `npm audit fix --force` ; demander avant `npm audit fix`.
7. Relancer `npm audit`, puis `npm run prod`.
8. Rapporter : critical et high restantes, majeures retenues, avertissements de build.

## Rechargement à chaud (HMR)
Le HMR dépend de la pile : voir `id-<pile>:front-build`. Pour travailler, on lance la
commande de HMR du projet (`npm run watch` avec Webpack), jamais un build qui écrit dans
le dossier livré, suivi par git (`dist`, `Resources/Public/Assets`).

## Fin de tâche
1. `npm run prod` se termine sans erreur ni avertissement nouveau.
2. Le linter du projet ne signale rien de nouveau dans les fichiers écrits ou
   modifiés : `npx eslint <fichiers>` (config `eslint.config.js`, `npm run lint`
   pour tout le JS ; `--fix` corrige seul points-virgules, indentation, accolades et
   `const`) ; stylelint s'il est configuré.
3. Ni `console.log` oublié (`bza-dev:js`), ni code commenté.
4. Le rapport liste les fichiers touchés, les avertissements de build, et ce qui
   reste à faire. Git : `bza:lois/git.md`.
