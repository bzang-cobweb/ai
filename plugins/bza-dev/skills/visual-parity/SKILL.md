---
name: visual-parity
description: Prouver au pixel près qu'un site migré (CMS, framework, refonte technique — TYPO3, Drupal, Laravel, WordPress…) rend comme l'ancien — captures côte à côte sur Google Chrome, diff pixelmatch, travail par zones, rapport de revue de fin de migration. Kit complet inclus.
---

## Quand utiliser ce skill

Toute migration où le rendu doit rester identique : montée de version d'un CMS, changement de framework ou de
thème, refonte technique « à iso-rendu ». La méthode ne dépend que d'une chose : **l'ancien site et le nouveau
tournent en même temps** (deux projets locaux, un local et une préprod…), chacun avec sa propre URL.

Le livrable obligatoire en fin de migration est le **rapport de revue** (`report/review/index.html`, voir §5) :
il est joint au bilan et présenté au client pour valider les écarts restants.

## 1. Principes non négociables

- **Outil distinct des tests E2E** : il vit dans `tests/visual/`, n'est pas un test E2E et ne passe pas par
  l'environnement isolé (`bza-dev:e2e-isolation`), car il lit un site de référence qui n'est jamais isolé.

- **La référence est capturée une fois, avant toute modification, et ne bouge plus.** On ne touche jamais au
  site de référence (ni code, ni base) : il n'est que lu.
- **Google Chrome** (`channel: 'chrome'`), jamais le Chromium embarqué de Playwright : on compare ce que
  voit un visiteur réel. C'est une exception voulue à `bza-dev:playwright` (Chromium seul pour les tests E2E).
- **Pleine page**, cinq largeurs : 375, 768, 992 (seuil mobile/desktop), 1024, 1440 (adaptables dans la
  configuration).
- **Rendu gelé** : animations et transitions coupées, `reducedMotion`, défilement complet avant capture
  (chargement différé, apparitions au scroll), attente des polices et du réseau.
- **Ce qui n'est pas déterministe est masqué**, d'une même couleur des deux côtés (flux sociaux, captcha,
  iframes, publicités, dates du jour…) ; la mesure d'audience et les bandeaux de consentement sont bloqués.
- **États interactifs** (menu ouvert, sous-menu mobile, recherche, modale, accordéon, en-tête réduit…) :
  même nom de clé des deux côtés, sélecteurs propres à chaque site. Lire le JS de l'ancien site avant d'écrire
  un état (un méga-menu « au survol » s'ouvre parfois au clic).
- **Une différence de hauteur est un écart** : l'image la plus courte est complétée en magenta.
- Seuil pixelmatch 0,1 (anti-crénelage toléré, couleur non). La comparaison d'images est l'objet même de
  la migration : c'est une exception décidée par la mission, à la règle de `bza-dev:playwright` (pas de
  comparaison d'image sans l'accord de l'humain).

## 2. Mise en place (≈ 15 minutes)

1. Créer `tests/visual/` à la racine du projet cible et y écrire **tels quels** les fichiers du kit (§7) :
   `package.json`, `kit.mjs`, `discover-pages.mjs`, `capture.mjs`, `compare.mjs`, `crop-element.mjs`,
   `report.mjs`, `report-template.html`. Ignorer `tests/visual/node_modules/`, `shots/`, `report/` dans git.
2. `cd tests/visual && npm install` (versions exactes du `package.json`). L'accord donné à la mission de
   migration couvre les dépendances du kit (`playwright`, `pixelmatch`, `pngjs`) ; toute autre dépendance
   demande l'accord habituel de l'humain.
3. Écrire `parity.config.mjs` à partir de l'exemple (§7) : URL des deux sites, libellés, zones masquées,
   états, requêtes bloquées. C'est **le seul fichier propre au projet**.
4. Construire `pages.json` :
   - `node discover-pages.mjs` (sitemap.xml du site de référence, sinon exploration des liens) ;
   - ou depuis la base du CMS quand des pages hors menu doivent être incluses (voir §6).
5. `node capture.mjs --site ref` → référence complète, **avant tout travail**. Vérifier le journal : une page
   en erreur côté référence n'a pas de référence ; la noter (`excludeFromReport`) et la vérifier autrement.

## 3. Boucle de travail

```
(build du nouveau site) → vider les caches → node capture.mjs --site target --only <motif> --viewport <liste>
→ node compare.mjs --only <motif> → lire report/<largeur>/<nom>.diff.png → corriger → recommencer
```

- `compare.mjs` imprime l'écart de chaque capture (trié) ; les images `.ref.png`, `.target.png`, `.diff.png`
  sont dans `report/<largeur>/`.
- Une comparaison partielle écrit `summary-partial.json` et ne remplace pas le résumé complet.

## 4. Travailler par zones (et en parallèle)

Découper le site en zones indépendantes : en-tête et navigation, pied de page, sections et contenus,
formulaires, recherche… Chaque zone a ses propres fichiers (gabarits, styles, scripts, configuration),
créés vides et importés d'avance : plusieurs personnes ou agents avancent en même temps sans conflit.
Tant que les autres zones bougent, juger sa zone sur un **recadrage** :

```
node crop-element.mjs --path /contact --ref-selector "form#contact" --target-selector "form.contact" --viewport mobile,desktop [--match-width]
```

`--match-width` donne à la zone cible la largeur de la référence, pour isoler son rendu interne d'un
problème de largeur venu du conteneur.

## 5. Rapport de fin de migration (obligatoire)

1. Capture complète de la cible et comparaison complète : `npm run parity`
   (`capture --site target` + `compare` + `report`).
2. Renseigner dans `parity.config.mjs` la **cause de chaque écart** restant (`notes` : motif du nom de capture →
   explication) et `defaultNote`. Un écart sans cause identifiée n'est pas acceptable en fin de migration.
3. `node report.mjs [--min 0.1]` → `report/review/` : `index.html` + `img/` (vignettes JPEG). Page autonome :
   synthèse chiffrée, filtres par largeur et par seuil, une rangée par capture (référence | cible | différence,
   défilement synchronisé, bouton Agrandir), cause de l'écart, liste des écarts sous le seuil.
4. Publier le dossier `report/review/` (Artifact claude.ai avec `index.html` + les fichiers `img/*`, ou
   intranet), en donner le lien dans le bilan de migration, et faire **valider les écarts assumés** par le client.

Critère de sortie : 0 % hors zones masquées, ou chaque écart expliqué et accepté.
Repère (migration TYPO3 11 → 14, 45 pages) : 196 captures, 43 identiques, 167 sous 0,5 %, 3 au-dessus de 2 %, tous expliqués.

## 6. Adapter à la technologie

Seuls `pages.json` et l'environnement changent ; le kit est identique.

| Technologie | Source de `pages.json` | Avant chaque capture de la cible |
|---|---|---|
| TYPO3 | requête `pages` (doktype standard, visibles, langue par défaut) ou sitemap EXT:seo | `typo3 cache:flush` (staticfilecache compris) |
| Drupal | sitemap (module simple_sitemap / xmlsitemap) ou `drush` sur `node_field_data` + alias | `drush cr` |
| Laravel | routes GET sans paramètre (`php artisan route:list --json`) + exemples de routes paramétrées | `php artisan optimize:clear`, build Vite |
| WordPress | sitemap natif `wp-sitemap.xml` ou `wp post list --post_type=page,post` | purge du cache de pages |
| Autre / statique | `discover-pages.mjs` (sitemap ou exploration) | — |

Format attendu : `[{ "path": "/fr/contact", "title": "Contact" }]`, chemins relatifs aux deux `baseUrl`.

## Pièges connus

- Page en erreur sur la référence locale (service absent, index vide) : pas de référence ; ne pas « réparer »
  la référence, documenter et vérifier autrement (préprod, production en lecture seule).
- L'ancien site sert parfois des images basse définition agrandies : la cible, correcte, diffère de 1 à 3 % et
  d'1–2 px de hauteur (tout le bas de page se décale). C'est un écart assumé, à expliquer dans `notes`.
- Compression d'images différente (webp, qualité) : petits écarts diffus, normaux.
- Carrousels, vidéos, compteurs animés : figer par `freezeCss` ou masquer.
- Caches de pages statiques et assets non recompilés : toujours vider/recompiler avant de capturer.
- Les captures concurrentes de plusieurs personnes écrivent dans `shots/target/` : ne pas lancer deux
  captures complètes en même temps.

## 7. Kit (à copier tel quel dans `tests/visual/`)

Les fichiers ci-dessous sont la version de référence, éprouvée sur une migration TYPO3 11 → 14. Un projet qui
améliore le kit reverse ses fichiers ici.

### `package.json`

````json
{
  "name": "visual-parity",
  "private": true,
  "type": "module",
  "description": "Parité visuelle d'une migration : site de référence / site cible — captures Google Chrome, diff pixelmatch, rapport de revue (skill bza-dev:visual-parity)",
  "scripts": {
    "discover": "node discover-pages.mjs",
    "capture:ref": "node capture.mjs --site ref",
    "capture:target": "node capture.mjs --site target",
    "compare": "node compare.mjs",
    "report": "node report.mjs",
    "parity": "node capture.mjs --site target && node compare.mjs && node report.mjs"
  },
  "devDependencies": {
    "playwright": "1.63.0",
    "pixelmatch": "7.1.0",
    "pngjs": "7.0.0"
  }
}
````

### `kit.mjs`

````js
// Kit de parité visuelle — fonctions communes (ne pas modifier par projet, voir parity.config.mjs).
import { readFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';

export const root = new URL('./', import.meta.url);
export const config = (await import(new URL('./parity.config.mjs', root))).default;

export const viewports = config.viewports ?? [
  { name: 'mobile', width: 375, height: 812 },
  { name: 'tablet', width: 768, height: 1024 },
  { name: 'compact', width: 992, height: 768 },
  { name: 'laptop', width: 1024, height: 768 },
  { name: 'desktop', width: 1440, height: 900 },
];
export const maskColor = config.maskColor ?? '#ff00ff';
export const threshold = config.threshold ?? 0.1;

// Toujours Google Chrome, jamais le Chromium embarqué de Playwright.
export const browserOptions = { channel: 'chrome' };

export const selectViewports = (list) => viewports.filter((v) => !list || list.split(',').includes(v.name));

// Nom de fichier d'une capture : /fr/emplois/metiers → fr__emplois__metiers
export const slug = (path) => path.replace(/^\/|\/$/g, '').replace(/[/?=&#]+/g, '__') || 'root';

export async function loadPages() {
  const file = new URL('./pages.json', root);
  if (!existsSync(file)) throw new Error('pages.json absent : lancer `node discover-pages.mjs` ou le générer depuis la base');
  return JSON.parse(await readFile(file));
}

// Gel du rendu : pas d'animations ni de transitions, curseur texte invisible, révélations au scroll forcées.
export const freezeCss = `
  *, *::before, *::after { animation: none !important; transition: none !important; caret-color: transparent !important; }
  [data-sr-id], .sr, .reveal, .animate { opacity: 1 !important; transform: none !important; visibility: visible !important; }
  ${config.freezeCss ?? ''}
`;

// Fait défiler toute la page (chargement différé, animations au scroll), revient en haut, attend polices et réseau.
export async function settle(page) {
  await page.evaluate(async () => {
    const step = window.innerHeight / 2;
    for (let y = 0; y < document.body.scrollHeight; y += step) {
      window.scrollTo(0, y);
      await new Promise((r) => setTimeout(r, 60));
    }
    window.scrollTo(0, 0);
  });
  await page.evaluate(() => document.fonts.ready);
  await page.waitForLoadState('networkidle').catch(() => {});
  await page.waitForTimeout(300);
}

export async function newContext(browser, site, vp) {
  const context = await browser.newContext({
    viewport: { width: vp.width, height: vp.height },
    ignoreHTTPSErrors: true,
    reducedMotion: 'reduce',
    deviceScaleFactor: 1,
  });
  if (config.blockRequests) await context.route(config.blockRequests, (r) => r.abort());
  if (site.beforeEach) await context.addInitScript(site.beforeEach);
  return context;
}

export const label = (key) => config.labels?.[key] ?? key;
````

### `discover-pages.mjs`

````js
// Construit pages.json (liste des pages à comparer) à partir du site de référence, sans dépendre de sa technologie :
// sitemap.xml (index de sitemaps compris), sinon exploration des liens internes depuis la page d'accueil.
// Usage : node discover-pages.mjs [--sitemap <url>] [--crawl <profondeur>] [--exclude <regex>] [--start <chemin>]
// Variante : générer pages.json depuis la base du CMS quand les pages masquées du menu doivent être incluses.
import { chromium } from 'playwright';
import { writeFile } from 'node:fs/promises';
import { parseArgs } from 'node:util';
import { config, browserOptions } from './kit.mjs';

const { values: args } = parseArgs({
  options: { sitemap: { type: 'string' }, crawl: { type: 'string' }, exclude: { type: 'string' }, start: { type: 'string' } },
});
const base = new URL(config.ref.baseUrl);
const exclude = args.exclude ? new RegExp(args.exclude) : /\.(pdf|jpe?g|png|gif|svg|webp|zip|docx?|xlsx?)$/i;
const found = new Map();
const keep = (u) => {
  const url = new URL(u, base);
  if (url.host !== base.host) return null;
  const path = url.pathname + url.search;
  return exclude.test(path) ? null : path;
};

async function fromSitemap(url, depth = 0) {
  const res = await fetch(url).catch(() => null);
  if (!res?.ok || depth > 3) return;
  const xml = await res.text();
  for (const [, loc] of xml.matchAll(/<loc>\s*([^<\s]+)\s*<\/loc>/g)) {
    if (/<sitemapindex/i.test(xml)) await fromSitemap(loc, depth + 1);
    else { const p = keep(loc); if (p) found.set(p, ''); }
  }
}

process.env.NODE_TLS_REJECT_UNAUTHORIZED ??= '0'; // sites locaux en HTTPS auto-signé
await fromSitemap(args.sitemap ?? new URL('/sitemap.xml', base).href);

if (found.size === 0 || args.crawl) {
  const maxDepth = Number(args.crawl ?? 2);
  const browser = await chromium.launch(browserOptions);
  const page = await (await browser.newContext({ ignoreHTTPSErrors: true })).newPage();
  let frontier = [args.start ?? '/'];
  for (let d = 0; d <= maxDepth && frontier.length; d++) {
    const next = [];
    for (const path of frontier) {
      if (found.has(path) && d > 0) continue;
      const res = await page.goto(new URL(path, base).href, { waitUntil: 'domcontentloaded' }).catch(() => null);
      if (!res?.ok()) continue;
      const finalPath = keep(page.url());
      if (finalPath) found.set(finalPath, await page.title());
      for (const href of await page.$$eval('a[href]', (as) => as.map((a) => a.getAttribute('href')))) {
        const p = href && !href.startsWith('#') && !/^(mailto|tel|javascript):/.test(href) ? keep(href) : null;
        if (p && !found.has(p)) next.push(p.split('#')[0]);
      }
    }
    frontier = [...new Set(next)];
  }
  await browser.close();
}

const pages = [...found].map(([path, title]) => ({ path, title })).sort((a, b) => a.path.localeCompare(b.path));
await writeFile(new URL('./pages.json', import.meta.url), JSON.stringify(pages, null, 1));
console.log(`${pages.length} pages → pages.json`);
````

### `capture.mjs`

````js
// Capture pleine page de toutes les pages et des états interactifs d'un site, sur Google Chrome.
// Usage : node capture.mjs --site ref|target [--only <motif de chemin>] [--viewport mobile,desktop]
import { chromium } from 'playwright';
import { mkdir, writeFile } from 'node:fs/promises';
import { parseArgs } from 'node:util';
import { config, maskColor, browserOptions, selectViewports, slug, loadPages, freezeCss, settle, newContext } from './kit.mjs';

const { values: args } = parseArgs({ options: { site: { type: 'string' }, only: { type: 'string' }, viewport: { type: 'string' } } });
if (!['ref', 'target'].includes(args.site)) throw new Error('--site ref|target requis');
const site = config[args.site];

const pages = (await loadPages()).filter((p) => !args.only || p.path.includes(args.only));
const outDir = (vp) => new URL(`./shots/${args.site}/${vp.name}/`, import.meta.url);
const browser = await chromium.launch(browserOptions);
const log = [];

for (const vp of selectViewports(args.viewport)) {
  await mkdir(outDir(vp), { recursive: true });
  const context = await newContext(browser, site, vp);
  const page = await context.newPage();
  const shoot = async (name, fullPage = true) => {
    await page.addStyleTag({ content: freezeCss });
    const mask = (site.masks ?? []).map((s) => page.locator(s));
    await page.screenshot({ path: new URL(`${name}.png`, outDir(vp)).pathname, fullPage, mask, maskColor, animations: 'disabled' });
  };

  for (const p of pages) {
    try {
      const res = await page.goto(site.baseUrl + p.path, { waitUntil: 'load', timeout: 60000 });
      await settle(page);
      await shoot(slug(p.path));
      log.push({ viewport: vp.name, path: p.path, status: res?.status() });
    } catch (e) {
      log.push({ viewport: vp.name, path: p.path, error: e.message.split('\n')[0] });
    }
  }

  for (const [state, def] of Object.entries(site.states ?? {})) {
    if ((def.minWidth && vp.width < def.minWidth) || (def.maxWidth && vp.width > def.maxWidth)) continue;
    for (const path of def.pages.filter((x) => !args.only || x.includes(args.only))) {
      try {
        await page.goto(site.baseUrl + path, { waitUntil: 'load' });
        await settle(page);
        await def.run(page, vp);
        await shoot(`${slug(path)}--${state}`, !def.viewportOnly);
        log.push({ viewport: vp.name, path, state, status: 'ok' });
      } catch (e) {
        log.push({ viewport: vp.name, path, state, error: e.message.split('\n')[0] });
      }
    }
  }
  await context.close();
}

await browser.close();
const partial = args.only || args.viewport ? '-partial' : '';
await writeFile(new URL(`./shots/${args.site}/capture-log${partial}.json`, import.meta.url), JSON.stringify(log, null, 1));
const errors = log.filter((l) => l.error || (typeof l.status === 'number' && l.status >= 400));
console.log(`${args.site} : ${log.length} captures, ${errors.length} en erreur`);
for (const e of errors) console.log(' ', e.viewport, e.path, e.state ?? '', e.error ?? e.status);
````

### `compare.mjs`

````js
// Compare les captures de référence et de la cible ; écrit report/summary.json et les images de différence.
// Une différence de hauteur est un écart à part entière : l'image la plus courte est complétée en magenta.
// Usage : node compare.mjs [--only <motif>] [--viewport mobile,desktop]
import { readdir, readFile, writeFile, mkdir, copyFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { parseArgs } from 'node:util';
import { PNG } from 'pngjs';
import pixelmatch from 'pixelmatch';
import { root, threshold, selectViewports } from './kit.mjs';

const { values: args } = parseArgs({ options: { only: { type: 'string' }, viewport: { type: 'string' } } });
const report = new URL('./report/', root);
const rows = [];

function pad(png, width, height) {
  if (png.width === width && png.height === height) return png;
  const out = new PNG({ width, height });
  for (let i = 0; i < out.data.length; i += 4) out.data.set([255, 0, 255, 255], i);
  PNG.bitblt(png, out, 0, 0, Math.min(png.width, width), Math.min(png.height, height), 0, 0);
  return out;
}

for (const vp of selectViewports(args.viewport)) {
  const dirA = new URL(`./shots/ref/${vp.name}/`, root);
  if (!existsSync(dirA)) continue;
  await mkdir(new URL(`./${vp.name}/`, report), { recursive: true });
  const files = (await readdir(dirA)).filter((f) => f.endsWith('.png') && (!args.only || f.includes(args.only))).sort();
  for (const file of files) {
    const fileB = new URL(`./shots/target/${vp.name}/${file}`, root);
    const out = (suffix) => new URL(`./${vp.name}/${file.replace('.png', suffix)}`, report);
    await copyFile(new URL(file, dirA), out('.ref.png'));
    if (!existsSync(fileB)) {
      rows.push({ vp: vp.name, file, ratio: null });
      continue;
    }
    await copyFile(fileB, out('.target.png'));
    const a = PNG.sync.read(await readFile(new URL(file, dirA)));
    const b = PNG.sync.read(await readFile(fileB));
    const width = Math.max(a.width, b.width);
    const height = Math.max(a.height, b.height);
    const diff = new PNG({ width, height });
    const n = pixelmatch(pad(a, width, height).data, pad(b, width, height).data, diff.data, width, height, { threshold });
    await writeFile(out('.diff.png'), PNG.sync.write(diff));
    rows.push({ vp: vp.name, file, ratio: n / (width * height), heights: [a.height, b.height] });
  }
}

rows.sort((x, y) => (y.ratio ?? 2) - (x.ratio ?? 2));
const pct = (r) => (r === null ? 'absente (cible)' : `${(r * 100).toFixed(3)} %`);
for (const r of rows) console.log(`${pct(r.ratio).padStart(15)}  ${r.vp.padEnd(8)} ${r.file}  ${r.heights?.join(' / ') ?? ''}`);
// Le résumé d'une comparaison partielle ne remplace pas celui d'une comparaison complète.
await writeFile(new URL(args.only || args.viewport ? './summary-partial.json' : './summary.json', report), JSON.stringify(rows, null, 1));
console.log(`${rows.filter((r) => r.ratio === 0).length}/${rows.length} identiques — rapport de revue : node report.mjs`);
````

### `crop-element.mjs`

````js
// Compare une seule zone (sélecteur CSS) sur les deux sites, à une ou plusieurs largeurs.
// Utile pour juger sa zone pendant que le reste de la page bouge encore.
// Usage : node crop-element.mjs --path /fr/contacts --ref-selector "form" [--target-selector "form"]
//         [--viewport mobile,desktop] [--match-width]
import { chromium } from 'playwright';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { parseArgs } from 'node:util';
import { PNG } from 'pngjs';
import pixelmatch from 'pixelmatch';
import { config, maskColor, threshold, browserOptions, selectViewports, slug, freezeCss, settle, newContext } from './kit.mjs';

const { values: args } = parseArgs({
  options: {
    path: { type: 'string' },
    'ref-selector': { type: 'string' },
    'target-selector': { type: 'string' },
    viewport: { type: 'string' },
    'match-width': { type: 'boolean' },
  },
});
if (!args.path || !args['ref-selector']) throw new Error('--path et --ref-selector requis');
const selectors = { ref: args['ref-selector'], target: args['target-selector'] ?? args['ref-selector'] };
const out = new URL('./report/crop/', import.meta.url);
await mkdir(out, { recursive: true });
const browser = await chromium.launch(browserOptions);

for (const vp of selectViewports(args.viewport)) {
  const sides = {};
  for (const key of ['ref', 'target']) {
    const site = config[key];
    const context = await newContext(browser, site, vp);
    const page = await context.newPage();
    await page.goto(site.baseUrl + args.path, { waitUntil: 'load' });
    await settle(page);
    await page.addStyleTag({ content: freezeCss });
    const el = page.locator(selectors[key]).first();
    sides[key] = { context, el, width: (await el.boundingBox())?.width, mask: (site.masks ?? []).map((s) => page.locator(s)) };
  }
  // --match-width : la zone cible prend la largeur de la référence, pour isoler le rendu interne de la zone.
  if (args['match-width'] && sides.ref.width) {
    await sides.target.el.evaluate((n, w) => { n.style.width = `${w}px`; n.style.maxWidth = `${w}px`; }, sides.ref.width);
  }
  const png = {};
  for (const key of ['ref', 'target']) {
    const file = new URL(`${slug(args.path)}.${vp.name}.${key}.png`, out);
    await sides[key].el.screenshot({ path: file.pathname, mask: sides[key].mask, maskColor, animations: 'disabled' });
    png[key] = PNG.sync.read(await readFile(file));
    await sides[key].context.close();
  }
  const width = Math.max(png.ref.width, png.target.width);
  const height = Math.max(png.ref.height, png.target.height);
  const fit = (p) => { const o = new PNG({ width, height }); PNG.bitblt(p, o, 0, 0, p.width, p.height, 0, 0); return o; };
  const diff = new PNG({ width, height });
  const n = pixelmatch(fit(png.ref).data, fit(png.target).data, diff.data, width, height, { threshold });
  await writeFile(new URL(`${slug(args.path)}.${vp.name}.diff.png`, out), PNG.sync.write(diff));
  console.log(`${((n / (width * height)) * 100).toFixed(3).padStart(8)} %  ${vp.name.padEnd(8)} ${args.path}  ${png.ref.width}×${png.ref.height} / ${png.target.width}×${png.target.height}`);
}
await browser.close();
````

### `report.mjs`

````js
// Rapport de revue de fin de migration : page HTML autonome (référence | cible | différence, défilement synchronisé,
// filtres, causes des écarts) dans report/review/, prête à ouvrir en local ou à publier (Artifact, intranet).
// Usage : node report.mjs [--min 0.1] [--width 640]
import { chromium } from 'playwright';
import { mkdir, readFile, writeFile, rm } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { parseArgs } from 'node:util';
import { root, config, viewports, threshold, browserOptions } from './kit.mjs';

const { values: args } = parseArgs({ options: { min: { type: 'string' }, width: { type: 'string' } } });
const minPct = Number(args.min ?? 0.1);
const maxWidth = Number(args.width ?? 640);
const summaryFile = new URL('./report/summary.json', root);
if (!existsSync(summaryFile)) throw new Error('report/summary.json absent : lancer une comparaison complète (node compare.mjs)');

const excluded = config.excludeFromReport;
const all = JSON.parse(await readFile(summaryFile)).filter((r) => !(excluded && excluded.test(r.file)));
const out = new URL('./report/review/', root);
await rm(out, { recursive: true, force: true });
await mkdir(new URL('./img/', out), { recursive: true });

const widthOf = Object.fromEntries(viewports.map((v) => [v.name, v.width]));
const vpLabels = { mobile: 'Mobile', tablet: 'Tablette', compact: 'Bureau étroit', laptop: 'Portable', desktop: 'Bureau' };
const shown = all.filter((r) => r.ratio === null || r.ratio * 100 >= minPct);

// Vignettes JPEG réduites, rendues par Chrome (aucune dépendance d'image supplémentaire).
const browser = await chromium.launch(browserOptions);
const page = await browser.newPage();
const rows = [];
for (const r of shown) {
  const name = r.file.replace(/\.png$/, '');
  const key = `${r.vp}__${name}`;
  const width = Math.min(maxWidth, widthOf[r.vp] ?? maxWidth);
  for (const kind of r.ratio === null ? ['ref'] : ['ref', 'target', 'diff']) {
    const src = new URL(`./report/${r.vp}/${name}.${kind}.png`, root);
    const data = (await readFile(src)).toString('base64');
    await page.setViewportSize({ width, height: 600 });
    await page.setContent(`<style>html,body{margin:0}img{display:block;width:100%}</style><img src="data:image/png;base64,${data}">`);
    await page.locator('img').evaluate((img) => img.decode());
    await page.screenshot({ path: new URL(`./img/${key}.${kind}.jpg`, out).pathname, fullPage: true, type: 'jpeg', quality: 70 });
  }
  rows.push({ key, vp: r.vp, name, pct: r.ratio === null ? null : Math.round(r.ratio * 100000) / 1000, h: r.heights ?? null });
}
await browser.close();

const data = {
  project: config.project ?? 'Migration',
  labels: { ref: config.labels?.ref ?? 'référence', target: config.labels?.target ?? 'cible' },
  viewports: viewports.map((v) => ({ name: v.name, width: v.width, label: vpLabels[v.name] ?? v.name })),
  notes: (config.notes ?? []).map(([re, text]) => [re, text]),
  defaultNote: config.defaultNote ?? 'Écart résiduel de lissage ; aucune différence de mise en page repérée.',
  threshold,
  minPct,
  excluded: config.excludeLabel ?? (excluded ? String(excluded) : ''),
  accent: config.reportAccent ?? null,
  generated: new Date().toLocaleString('fr-CH'),
  rows,
  others: all.filter((r) => r.ratio !== null && r.ratio > 0 && r.ratio * 100 < minPct)
    .map((r) => ({ vp: r.vp, name: r.file.replace(/\.png$/, ''), pct: Math.round(r.ratio * 100000) / 1000 })),
  same: all.filter((r) => r.ratio === 0).length,
  missing: all.filter((r) => r.ratio === null).length,
  total: all.length,
};
const template = await readFile(new URL('./report-template.html', root), 'utf8');
await writeFile(new URL('./index.html', out), template.replace('__DATA__', JSON.stringify(data)));
console.log(`${rows.length} captures dans le rapport (${data.same} identiques, ${data.others.length} sous ${minPct} %) → ${out.pathname}index.html`);
````

### `report-template.html`

````html
<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Parité visuelle</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Roboto:wght@300;400;500&family=Roboto+Mono:wght@400;500&display=swap">
<style>
/* Rapport de parité visuelle (kit universal/visual-parity) : synthèse, filtres, puis une rangée par capture
   (référence | cible | différence, défilement synchronisé). Généré par report.mjs, ne pas éditer à la main. */
:root {
  color-scheme: light;
  --bg: #f4f4f3;
  --surface: #ffffff;
  --ink: #17191b;
  --muted: #5d6166;
  --line: #dcdcda;
  --accent: #c32037;
  --ok: #2d7a4b;
  --warn: #a8660a;
  --crit: #b3261e;
  --display: 'Bebas Neue', 'Oswald', Impact, sans-serif;
  --body: 'Roboto', system-ui, -apple-system, 'Segoe UI', sans-serif;
  --mono: 'Roboto Mono', ui-monospace, Menlo, monospace;
}
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    color-scheme: dark;
    --bg: #121314; --surface: #1b1d1f; --ink: #ececea; --muted: #a2a6aa; --line: #303336;
    --accent: #e0485e; --ok: #2f7d4f; --warn: #9a6008; --crit: #b3261e;
  }
}
:root[data-theme="dark"] {
  color-scheme: dark;
  --bg: #121314; --surface: #1b1d1f; --ink: #ececea; --muted: #a2a6aa; --line: #303336;
  --accent: #e0485e; --ok: #2f7d4f; --warn: #9a6008; --crit: #b3261e;
}
* { box-sizing: border-box; }
body { margin: 0; background: var(--bg); color: var(--ink); font: 15px/1.55 var(--body); padding-inline: 16px; padding-block: 28px 64px; }
.wrap { max-width: 1240px; margin: 0 auto; display: grid; gap: 28px; }
header { display: grid; gap: 12px; }
.eyebrow { font: 500 12px/1 var(--mono); letter-spacing: .12em; text-transform: uppercase; color: var(--accent); }
h1 { font: 400 clamp(40px, 6vw, 64px)/0.95 var(--display); letter-spacing: .01em; margin: 0; text-wrap: balance; }
.lede { max-width: 68ch; color: var(--muted); margin: 0; }
.stats { display: flex; flex-wrap: wrap; gap: 8px; }
.stat { background: var(--surface); border: 1px solid var(--line); padding: 10px 14px; display: grid; gap: 2px; min-width: 120px; }
.stat b { font: 400 30px/1 var(--display); font-variant-numeric: tabular-nums; }
.stat span { font: 12px/1.3 var(--mono); color: var(--muted); }
.stat.key b { color: var(--accent); }
.controls { display: flex; flex-wrap: wrap; gap: 8px; align-items: center; position: sticky; top: env(safe-area-inset-top, 0px); z-index: 5; background: var(--bg); padding-block: 10px; border-bottom: 1px solid var(--line); }
.controls .label { font: 500 11px/1 var(--mono); letter-spacing: .1em; text-transform: uppercase; color: var(--muted); margin-right: 4px; }
.chip { font: 500 13px/1 var(--body); padding: 8px 12px; border: 1px solid var(--line); background: var(--surface); color: var(--ink); cursor: pointer; }
.chip[aria-pressed="true"] { background: var(--ink); color: var(--bg); border-color: var(--ink); }
.chip:focus-visible, select:focus-visible, button:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
select { font: 13px var(--body); padding: 7px 10px; border: 1px solid var(--line); background: var(--surface); color: var(--ink); }
.spacer { flex: 1; }
.count { font: 12px var(--mono); color: var(--muted); }
.list { display: grid; gap: 22px; }
.row { background: var(--surface); border: 1px solid var(--line); display: grid; }
.row[hidden] { display: none; }
.row-head { display: flex; flex-wrap: wrap; gap: 10px 14px; align-items: baseline; padding: 14px 16px; border-bottom: 1px solid var(--line); }
.row-head h2 { font: 400 26px/1 var(--display); margin: 0; letter-spacing: .02em; overflow-wrap: anywhere; }
.vp { font: 500 11px/1 var(--mono); letter-spacing: .08em; text-transform: uppercase; padding: 5px 7px; background: var(--bg); border: 1px solid var(--line); color: var(--muted); }
.pill { font: 500 13px/1 var(--mono); font-variant-numeric: tabular-nums; padding: 5px 8px; color: #fff; }
.pill.lo { background: var(--ok); } .pill.mid { background: var(--warn); } .pill.hi { background: var(--crit); } .pill.na { background: var(--muted); }
.heights { font: 12px var(--mono); color: var(--muted); }
.note { flex-basis: 100%; margin: 2px 0 0; color: var(--muted); font-size: 14px; max-width: 90ch; }
.trio { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 1px; background: var(--line); }
.pane { background: var(--surface); display: grid; grid-template-rows: auto 1fr; min-width: 0; }
.pane-title { font: 500 11px/1 var(--mono); letter-spacing: .1em; text-transform: uppercase; color: var(--muted); padding: 8px 10px; }
.pane-title.diff { color: var(--accent); }
.scroll { height: 460px; overflow: auto; overscroll-behavior: contain; }
.row.open .scroll { height: 78vh; }
.scroll img { display: block; width: 100%; height: auto; max-width: 100%; }
.row-foot { display: flex; justify-content: flex-end; padding: 8px 12px; }
.row-foot button { font: 500 13px var(--body); background: none; border: 0; color: var(--accent); cursor: pointer; padding: 4px 6px; }
details { background: var(--surface); border: 1px solid var(--line); padding: 14px 16px; }
summary { cursor: pointer; font: 400 22px/1 var(--display); letter-spacing: .02em; }
.table-wrap { overflow-x: auto; }
.small-table { width: 100%; border-collapse: collapse; margin-top: 12px; font-size: 14px; }
.small-table th, .small-table td { text-align: left; padding: 6px 8px; border-bottom: 1px solid var(--line); }
.small-table td.num { font: 13px var(--mono); font-variant-numeric: tabular-nums; }
footer { color: var(--muted); font-size: 13px; max-width: 80ch; }
@media (max-width: 720px) {
  .trio { grid-template-columns: 1fr; }
  .scroll { height: 340px; }
}
@media (prefers-reduced-motion: no-preference) { .chip, .row-foot button { transition: background .15s, color .15s; } }
</style>
</head>
<body>
<div class="wrap">
  <header>
    <div class="eyebrow" id="project"></div>
    <h1>Parité visuelle : les rendus qui diffèrent</h1>
    <p class="lede" id="lede"></p>
    <div class="stats" id="stats"></div>
  </header>

  <div class="controls" role="toolbar" aria-label="Filtres">
    <span class="label">Largeur</span>
    <span id="vp-chips" style="display:contents"></span>
    <span class="spacer"></span>
    <label class="label" for="min">Écart minimum</label>
    <select id="min"></select>
    <span class="count" id="count"></span>
  </div>

  <section class="list" id="list" aria-label="Captures"></section>

  <details id="others-block">
    <summary id="others-title"></summary>
    <div class="table-wrap"><table class="small-table" id="others"><thead><tr><th>Page</th><th>Largeur</th><th>Écart</th></tr></thead><tbody></tbody></table></div>
  </details>

  <footer id="foot"></footer>
</div>
<script>
const DATA = __DATA__;
const L = DATA.labels;
const VP = Object.fromEntries(DATA.viewports.map((v) => [v.name, `${v.label} ${v.width}`]));
const NOTES = DATA.notes.map(([re, text]) => [new RegExp(re), text]);
const note = (name) => (NOTES.find(([re]) => re.test(name)) || [null, DATA.defaultNote])[1];
const title = (name) => '/' + name.replace(/--(.+)$/, '').replace(/__/g, '/') + (name.includes('--') ? ` · état « ${name.split('--')[1]} »` : '');
const fmt = (p, d = 2) => p.toLocaleString('fr-CH', { minimumFractionDigits: d, maximumFractionDigits: d }) + ' %';
const level = (p) => (p === null ? 'na' : p >= 2 ? 'hi' : p >= 0.5 ? 'mid' : 'lo');
const min0 = DATA.minPct;

document.getElementById('project').textContent = DATA.project;
if (DATA.accent) document.documentElement.style.setProperty('--accent', DATA.accent);
document.getElementById('lede').textContent =
  `Captures pleine page sur Google Chrome de ${L.ref} et de ${L.target}, comparées pixel à pixel (seuil ${DATA.threshold}). ` +
  `Chaque capture dont l'écart atteint ${fmt(min0, 1)} est présentée en trois vues qui défilent ensemble : la référence, la cible, ` +
  `et la différence (en rouge, les pixels qui changent).` + (DATA.excluded ? ` Exclues du rapport : ${DATA.excluded}.` : '');

const rows = DATA.rows.slice().sort((a, b) => (b.pct ?? 101) - (a.pct ?? 101));
const bands = [
  ['identiques', DATA.same],
  [`moins de ${fmt(min0, 1)}`, DATA.others.length],
  [`${fmt(min0, 1)} à 0,5 %`, rows.filter((r) => r.pct !== null && r.pct < 0.5).length],
  ['0,5 % à 2 %', rows.filter((r) => r.pct >= 0.5 && r.pct < 2).length],
  ['2 % et plus', rows.filter((r) => r.pct >= 2).length],
];
if (DATA.missing) bands.push(['absentes de la cible', DATA.missing]);
document.getElementById('stats').innerHTML =
  `<div class="stat key"><b>${DATA.total}</b><span>captures comparées</span></div>` +
  bands.map(([l, n]) => `<div class="stat"><b>${n}</b><span>${l}</span></div>`).join('');

document.getElementById('vp-chips').innerHTML =
  `<button class="chip" type="button" data-vp="all" aria-pressed="true">Toutes</button>` +
  DATA.viewports.map((v) => `<button class="chip" type="button" data-vp="${v.name}" aria-pressed="false">${VP[v.name]}</button>`).join('');
const minSel = document.getElementById('min');
minSel.innerHTML = [min0, 0.5, 1, 2].filter((v, i, a) => a.indexOf(v) === i && v >= min0)
  .map((v) => `<option value="${v}">${fmt(v, 1)}</option>`).join('');

const list = document.getElementById('list');
const paneTitle = { ref: L.ref, target: L.target, diff: 'Différence' };
list.innerHTML = rows.map((r) => `
  <article class="row" data-vp="${r.vp}" data-pct="${r.pct ?? 100}">
    <div class="row-head">
      <h2>${title(r.name)}</h2>
      <span class="vp">${VP[r.vp]}</span>
      <span class="pill ${level(r.pct)}">${r.pct === null ? 'absente de la cible' : fmt(r.pct)}</span>
      ${r.h ? `<span class="heights">hauteur ${r.h[0]} px · ${r.h[1]} px</span>` : ''}
      <p class="note">${note(r.name)}</p>
    </div>
    <div class="trio">
      ${['ref', 'target', 'diff'].filter((k) => r.pct !== null || k === 'ref').map((k) => `
        <div class="pane">
          <div class="pane-title ${k === 'diff' ? 'diff' : ''}">${paneTitle[k]}</div>
          <div class="scroll"><img loading="lazy" decoding="async" src="img/${r.key}.${k}.jpg" alt="${title(r.name)}, ${VP[r.vp]}, ${paneTitle[k]}"></div>
        </div>`).join('')}
    </div>
    <div class="row-foot"><button type="button" class="toggle" aria-expanded="false">Agrandir</button></div>
  </article>`).join('');

// Défilement synchronisé des vues d'une rangée.
list.querySelectorAll('.row').forEach((row) => {
  const panes = [...row.querySelectorAll('.scroll')];
  let lock = false;
  panes.forEach((p) => p.addEventListener('scroll', () => {
    if (lock) return;
    lock = true;
    const ratio = p.scrollTop / Math.max(1, p.scrollHeight - p.clientHeight);
    panes.forEach((o) => { if (o !== p) o.scrollTop = ratio * (o.scrollHeight - o.clientHeight); });
    requestAnimationFrame(() => { lock = false; });
  }));
  row.querySelector('.toggle').addEventListener('click', (e) => {
    const open = row.classList.toggle('open');
    e.currentTarget.setAttribute('aria-expanded', String(open));
    e.currentTarget.textContent = open ? 'Réduire' : 'Agrandir';
  });
});

let vp = 'all';
const storeKey = `parity-filter-${DATA.project}`;
try {
  const saved = JSON.parse(localStorage.getItem(storeKey) || 'null');
  if (saved) { vp = saved.vp || 'all'; if ([...minSel.options].some((o) => o.value === saved.min)) minSel.value = saved.min; }
} catch (e) { /* stockage indisponible : filtres par défaut */ }
const apply = () => {
  const min = parseFloat(minSel.value);
  let n = 0;
  list.querySelectorAll('.row').forEach((row) => {
    const show = (vp === 'all' || row.dataset.vp === vp) && parseFloat(row.dataset.pct) >= min;
    row.hidden = !show;
    if (show) n++;
  });
  document.querySelectorAll('.chip').forEach((c) => c.setAttribute('aria-pressed', String(c.dataset.vp === vp)));
  document.getElementById('count').textContent = `${n} capture${n > 1 ? 's' : ''}`;
  try { localStorage.setItem(storeKey, JSON.stringify({ vp, min: minSel.value })); } catch (e) { /* ignoré */ }
};
document.querySelectorAll('.chip').forEach((c) => c.addEventListener('click', () => { vp = c.dataset.vp; apply(); }));
minSel.addEventListener('change', apply);
apply();

document.getElementById('others-title').textContent = `Écarts inférieurs à ${fmt(min0, 1)} (sans images)`;
if (!DATA.others.length) document.getElementById('others-block').hidden = true;
document.querySelector('#others tbody').innerHTML = DATA.others.slice().sort((a, b) => b.pct - a.pct)
  .map((o) => `<tr><td>${title(o.name)}</td><td>${VP[o.vp]}</td><td class="num">${o.pct.toLocaleString('fr-CH', { maximumFractionDigits: 3 })} %</td></tr>`).join('');

document.getElementById('foot').textContent =
  `Généré le ${DATA.generated} par le kit de parité visuelle (skill bza-dev:visual-parity). Images allégées pour la revue ` +
  `(JPEG, largeur réduite) ; les originaux sont dans tests/visual/report. Zones masquées en magenta des deux côtés : contenus non déterministes.`;
</script>
</body>
</html>
````

### `parity.config.mjs` — exemple (à adapter)

````js
// Configuration de la parité visuelle du projet : SEUL fichier propre au projet dans tests/visual/.
// Les scripts du kit (discover-pages, capture, compare, crop-element, report) ne se modifient pas.
// Méthode et kit : skill bza-dev:visual-parity.

const states = (selectors) => ({
  // Clé = nom de l'état, identique des deux côtés ; run(page, viewport) amène la page dans l'état voulu.
  // Méga-menu : ouverture au clic (timeline gsap), pas au survol.
  'menu-open': {
    pages: ['/fr/accueil'],
    viewportOnly: true,
    run: async (page, vp) => {
      await page.click(vp.width < 992 ? '.burger-navbar-toggler' : 'ul.navbar-nav > li.has-submenu > a >> nth=0');
      await page.waitForTimeout(1500);
    },
  },
  // En mobile la recherche est déjà visible dans le menu ouvert.
  'search-open': {
    pages: ['/fr/accueil'],
    viewportOnly: true,
    minWidth: 992,
    run: async (page) => {
      await page.click('#nav-item-999999');
      await page.waitForTimeout(1500);
    },
  },
  'submenu-open-mobile': {
    pages: ['/fr/accueil'],
    viewportOnly: true,
    maxWidth: 991,
    run: async (page) => {
      await page.click('.burger-navbar-toggler');
      await page.waitForTimeout(800);
      await page.click('ul.navbar-nav > li.has-submenu > a >> nth=0');
      await page.waitForTimeout(1200);
    },
  },
  'emergency-modal': {
    pages: ['/fr/accueil'],
    viewportOnly: true,
    run: async (page) => {
      await page.click('[data-target="#emergency-modal-navigation"] >> visible=true');
      await page.waitForSelector('#emergency-modal-navigation.show');
      await page.waitForTimeout(400);
    },
  },
  'accordion-open': {
    pages: ['/fr/emplois/les-metiers'],
    run: async (page) => {
      await page.click(selectors.accordionToggle);
      await page.waitForTimeout(600);
    },
  },
  'header-scrolled': {
    pages: ['/fr/accueil'],
    viewportOnly: true,
    run: async (page) => {
      await page.evaluate(() => window.scrollTo(0, 600));
      await page.waitForTimeout(600);
    },
  },
});

export default {
  // Titre et libellés du rapport de revue.
  project: 'Nom du projet — migration TYPO3 11 → 14 (TICKET-123)',
  labels: { ref: 'v11 · référence', target: 'v14 · nouveau site' },

  ref: {
    baseUrl: process.env.REF_URL ?? 'https://ancien.ddev.site',
    // Contenus non déterministes : flux social, captcha, carte interactive.
    masks: ['.socialfeeds', '.turnstile', 'iframe'],
    states: states({ accordionToggle: '.accordion [data-toggle="collapse"] >> nth=0' }),
  },
  target: {
    baseUrl: process.env.TARGET_URL ?? 'https://nouveau.ddev.site',
    masks: ['.socialfeeds', '.turnstile', 'iframe', '.cf-turnstile'],
    // Accordéon de la brique : bouton .accordion-button (lien data-toggle en v11).
    states: states({ accordionToggle: '.accordion .accordion-button >> nth=0' }),
  },

  viewports: [
    { name: 'mobile', width: 375, height: 812 },
    { name: 'tablet', width: 768, height: 1024 },
    { name: 'compact', width: 992, height: 768 },
    { name: 'laptop', width: 1024, height: 768 },
    { name: 'desktop', width: 1440, height: 900 },
  ],

  // Mesure d'audience et consentement : hors comparaison.
  blockRequests: /axept\.io|googletagmanager|google-analytics|matomo|facebook\.net/,

  // Pages exclues du rapport (pas de référence exploitable) : la v11 locale n'a pas d'index Solr.
  excludeFromReport: /recherche/,
  excludeLabel: 'la page de recherche (la v11 locale n\'a pas d\'index Solr)',

  // Couleur d'accent du rapport (identité du client).
  reportAccent: '#1f6feb',

  // Explication des écarts, affichée dans le rapport : [motif du nom de capture, cause].
  notes: [
    ['waiting', "Page d'attente de 2022, obsolète. Son en-tête dépendait d'un gabarit TypoScript supprimé lors du nettoyage (décision du client). Proposition : supprimer la page."],
    ['page-a|page-b|page-c|page-d', "Images : la v11 servait des vignettes basse définition agrandies (ex. 320 px affichés sur 680 px), la v14 sert la bonne définition. Le ratio arrondi diffère d'1 à 2 px, ce qui décale tout le bas de page."],
    ['affiches-flyers', 'Carrousel Flickity : lissage différent des cartes et des images pendant la mise en place.'],
    ['contacts', "Une ligne de hauteur d'écart dans la section du formulaire, puis tout le bas de page est décalé d'1 px ; le formulaire seul est à 0–0,55 %."],
    ['accueil', "Lissage des polices et images recompressées (webp) dans le bandeau d'accueil."],
  ],
  defaultNote: 'Écart résiduel de lissage (polices, images recompressées en webp) ; aucune différence de mise en page repérée.',
};
````
