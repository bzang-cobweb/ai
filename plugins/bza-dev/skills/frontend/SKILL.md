---
name: frontend
description: Point d'entrée de tout travail d'interface (HTML, SCSS, JS, build) dans un projet web Laravel — quelles règles lire et dans quel ordre, comment les lire, choix de GSAP, fidélité à la spec et à la source, preuve de rendu. À lire avant d'écrire du HTML, du SCSS ou du JS.
---

# Implémenter une interface

## Principe
Implémenter les interfaces à partir des specs et en restant fidèle à la référence
(site existant, maquette). Ne jamais inventer de fonctionnalité — se limiter à ce
qui est spécifié ou visible dans la référence.

## Lecture des règles
- « doit », « jamais », « seulement » : **règle**. « préférer », « éviter » :
  **recommandation**, dont on peut s'écarter avec une raison.
- Le front reproduit la maquette. On ne s'en écarte que sur instruction explicite de
  l'humain (par exemple une maquette externe mal adaptée au web) : cet écart est une
  exception, nommée dans le rapport.
- Une règle ou une recommandation qui paraît disproportionnée pour le site (trop
  complexe, trop coûteuse) se discute. Elle s'applique tant qu'il n'y a pas de
  réponse, et la question se pose au format d'escalade (`bza:lois/escalade.md`), avec
  l'effort estimé (fichiers, lignes, tests touchés) et une alternative. Elle ne
  s'écarte jamais seule.
- **Code existant** (reprise, migration) : s'il diffère profondément des règles,
  demander à l'humain s'il veut un refactor complet ou un travail sur l'ancien code.
  Tant qu'il n'a pas répondu, on travaille sur l'ancien code (seule exception à la
  règle précédente) et la réponse est consignée au registre (`bza:decision`). Le code
  neuf suit toujours les règles.
- **En migration, le rendu identique prime** : la structure HTML de la référence est
  reproduite dans la mesure où le rendu l'exige (`bza-dev:migration`,
  `bza-dev:visual-parity`).
- Ces règles sont communes à tous les projets. Ce qui est propre au projet (valeurs
  de la maquette, choix du client, exceptions) se consigne dans le registre des
  décisions (`.ia/context/decisions/`), jamais dans ces skills. Une règle commune se
  modifie par une pull request sur le dépôt de ce marketplace.

## Ordre de lecture
1. Les règles communes :
   - `bza-dev:html` — HTML, SEO, accessibilité, Bootstrap
   - `bza-dev:scss` — SCSS : BEM, fichiers, variables, responsive
   - `bza-dev:js` — JavaScript : style, crochets DOM, chargement asynchrone
   - `bza-dev:front-build` — compilation, début de projet, fin de tâche
2. Celles de la stack du projet :

   | Stack | Skills |
   |---|---|
   | Laravel | `bza-laravel:front-build`, `bza-laravel:blade` |

3. Pour valider le rendu : `bza-dev:visual-qa` ; pour les tests E2E :
   `bza-dev:playwright` ; pour une migration à rendu identique : `bza-dev:visual-parity`.

## Démarche
- Lire la spec du concept (`.ia/memory/spec_<concept>.json`) avant de commencer.
  Absente sur du code existant → la produire d'abord avec `bza-dev:auditor`.
- Respecter la structure de navigation et les libellés de la référence.
- Signaler tout élément d'interface présent dans la référence mais absent de la spec.

## Animations : GSAP
En migration, les bibliothèques déjà utilisées par l'ancien code (GSAP, Flickity…)
sont acquises : on les consigne au registre sans poser la question, et on signale
leur licence si elle n'est pas claire.

Pour le code neuf, avant d'écrire une animation en JavaScript, chercher dans le
registre des décisions si le projet a tranché l'usage de GSAP.
- **Pas de décision** : demander à l'humain si le projet utilise GSAP, et consigner
  sa réponse au registre avant de continuer.
- **Oui** : appliquer les skills du plugin officiel `gsap-skills` (noyau, timelines,
  ScrollTrigger, plugins, utilitaires, performance, React et autres frameworks),
  à installer depuis son dépôt public `greensock/gsap-skills`.
- **Non** : CSS (`transition`, `animation`), avec la variante
  `prefers-reduced-motion` (`bza-dev:scss`).

## Règles absolues
- Jamais modifier la structure de navigation sans validation explicite
- Les libellés visibles par l'utilisateur correspondent à la référence
- Pas de `done` sans vérification du rendu dans le navigateur
- **Une preuve de comportement en navigateur est un spec versionné et exécuté**,
  jamais un script jetable ni un compte rendu de ce qu'on a vu à l'écran
  (`bza-dev:preuve-navigateur`)
- **Ne jamais remplacer un contenu réel déjà livré par un placeholder** au nom de
  la cohérence : le composant enveloppe le contenu existant, il ne le remplace
  pas — en cas de tension, signaler et laisser arbitrer avant d'agir
- Rapport de fin de tâche : `bza:rapport-de-tache`
