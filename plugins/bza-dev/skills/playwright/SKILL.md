---
name: playwright
description: Écrire et lancer les tests E2E Playwright (TypeScript) — emplacement, configuration, localisateurs, mesures, captures, isolation.
---

## Quand utiliser ce skill
Toute création, modification ou exécution d'un test E2E. Il complète
`bza-dev:e2e-isolation`, dont l'isolation reste la doctrine.

## Principe
- Un test est la **preuve** d'un comportement : un spec versionné et exécuté
  (`bza-dev:preuve-navigateur`).
- Playwright tourne **sur la machine de l'humain**. L'application testée tourne dans
  l'environnement isolé (`bza-dev:e2e-isolation`) : aucune écriture sur la base de dev.
- Un seul point d'entrée : la commande du projet (voir le registre des décisions). Elle
  prend le verrou de l'environnement isolé, refuse tout lancement si l'isolation n'est
  pas constatée, appelle Playwright et se termine par un code de sortie. Ne jamais
  lancer `playwright test` seul contre l'URL de dev.
- Certains codes de sortie ne sont pas des échecs de test (témoin de dev modifié,
  environnement arrêté, configuration périmée…) : le `README.md` du dossier E2E les
  explique, ainsi que l'installation d'un poste ; à lire avant de conclure à une
  régression.

## Emplacement et outillage
- Dossier `e2e/` à la racine du dépôt, avec son propre `package.json`
  (`@playwright/test`, TypeScript, `tsconfig.json`). Ses dépendances sont distinctes de
  celles du thème. `npx tsc --noEmit` passe.
- Les navigateurs s'installent dans le cache de l'utilisateur
  (`npx playwright install chromium`), jamais dans le dépôt.
- Une nouvelle dépendance npm demande l'accord de l'humain.
- Les identifiants de test vivent dans `e2e/.env` (ignoré par git, fichier local de
  l'humain : ne pas le modifier). `e2e/.env.example` ne porte que les clés, jamais de
  valeur.
- Un fichier `*.spec.ts` par composant ou par parcours (`main-nav.spec.ts`). Aides dans
  `e2e/helpers/`, fixtures dans `e2e/fixtures.ts`.
- Style : celui des règles JS du projet (point-virgule, indentation du `.editorconfig`).
  Descriptions de test et commentaires dans la langue du projet.

## Configuration
- `baseURL` vient d'une variable d'environnement posée par la commande de lancement
  (l'URL de l'environnement isolé), jamais écrite en dur.
- Un projet Playwright par largeur de fenêtre : 320, 375, 768, 992, 1440 et 1920 px. Les
  largeurs encadrent le seuil mobile (`$mobile-limit`) ; 320 px est la plus petite
  largeur courante de téléphone.
- **Chromium seul** pour les agents et pour la suite quotidienne. Firefox et WebKit
  (`E2E_BROWSERS=all`) ne se lancent que si le brief le demande explicitement, ou lors
  du passage hebdomadaire lancé à la main par un humain. WebKit de Playwright est le
  moteur de Safari, pas Safari.
- `forbidOnly` activé. Aucun `retries` : un test instable est un défaut à corriger, pas
  à masquer. `trace: 'retain-on-failure'`.

## Écrire un test
- Localisateurs par rôle et nom accessible (`getByRole`, `getByLabel`). Une classe BEM
  seulement pour un composant sans rôle. Pas de `data-testid` sans l'accord de l'humain.
- Aucune attente fixe (`waitForTimeout`) : attendre un état (`expect(...).toBeVisible()`).
- Un test vérifie un comportement et ne dépend d'aucun autre.
- Par défaut, vérifier des **relations** : alignement, non-débordement, égalités,
  centrage, collage (`sticky`), par `boundingBox()` et styles calculés, à chaque largeur.
  Une valeur de design à protéger se vérifie **une seule fois**, en lisant la variable
  du thème ; les autres tests lisent la variable au lieu de recopier le nombre. **Mesurer
  avant de capturer** : une capture ne prouve pas une mesure.
- Chaque composant interactif a son test **clavier** : Tab, Entrée, Échap, focus visible.
- **WebKit et clavier** : comme Safari par défaut, WebKit ne focalise ni liens ni boutons
  avec Tab ; Alt+Tab le fait. Un test clavier qui passe sous WebKit soit est ignoré avec
  une raison, soit paramètre la touche (Alt+Tab sous WebKit, Tab ailleurs) : jamais
  `keyboard.press('Tab')` en dur, mais un helper unique du dossier `e2e/helpers/` (par
  exemple `pressTab`). L'ordre de tabulation diffère sous WebKit : se méfier des tests qui comptent les appuis.
- **Défaut réel du site non corrigé** : le test est marqué `test.fail()` **borné à la ou
  aux largeurs mesurées**, jamais sur tout le test, avec l'annotation
  `{ type: 'issue' }` qui renvoie au rapport de `specs/backlog/`. Une fois le défaut
  corrigé, le test passe au rouge, ce qui force à retirer l'annotation. Ne jamais
  ignorer le test (`skip`) ni élargir une tolérance pour masquer un défaut.
- **Ne jamais affirmer une limite d'un navigateur sans l'avoir mesurée.** Cas réfuté :
  « Chromium headless masque les barres de défilement » ; mesuré à 10 px.
- Les règles communes de `bza-dev:html` (structure Bootstrap, containers, `alt`, un seul
  `<h1>`) se vérifient par un spec partagé.

## Captures
- Elles servent de pièces à relire (échecs, traces), pas de preuve par défaut.
- Les captures **proposées** vont dans `e2e/captures-proposees/` (ignoré par git, rien
  n'y est écrit sous `E2E_INJECT`). Les **références adoptées** vivent dans
  `e2e/captures-reference/` (versionné) : l'adoption est une décision de l'humain.
- Pas de comparaison d'image (`toHaveScreenshot`) sans l'accord de l'humain pour le cas
  concerné, avec une tolérance. Les références ne se remplacent jamais sans lui.

## Prouver qu'un test détecte
Un test qui ne peut pas échouer ne prouve rien. Injecter un défaut (variable
d'environnement lue par le test, ou modification temporaire hors du dépôt), constater
l'échec, puis retirer l'injection. Documenter le défaut injecté dans le rapport.

Le reporter `list` affiche ✘ pour un échec **attendu** (`test.fail`) : ce n'est pas un
échec réel. Le verdict est le décompte final (réussis, ignorés, échecs).
