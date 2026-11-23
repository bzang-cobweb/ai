# bza — marketplace Claude

Plugins Claude Code pour démarrer et mener des projets Laravel et Filament : les
**lois** de travail, la **trace des projets** dans `.ia/`, une **méthode de
chantier**, le savoir-faire front et tests, et le savoir-faire Laravel.

## Les plugins

| Plugin | Contenu |
|---|---|
| `bza` | Lois (`bza:lois`), méthode de chantier (`bza:lead`), mode nuit (`bza:nuit`), rétrospective (`bza:retro`), registre des décisions (`bza:decision`), `.env` sans en lire les valeurs (`bza:env`), création du `.ia/` (`bza:projet-init`), migration (`bza:migrer`), fin de mandat (`bza:decommission`), rapport de tâche, analyse de projet. Hooks : liaison du `.ia/` au démarrage, garde-fou (git, `rm -rf`, `ssh`, secrets) |
| `bza-dev` | Règles front communes (`bza-dev:frontend`, point d'entrée ; `html`, `scss`, `js`, `front-build`) ; agents `auditor` et `qa-check` ; Playwright et tests E2E, preuves en navigateur, `visual-qa`, parité visuelle, documentation, migration de site |
| `bza-laravel` | Backend (`bza-laravel:backend`, point d'entrée), migrations, modèles, contrôleurs, policies (`bza-laravel:create-policy`), requêtes et services (`bza-laravel:requete-service`), commandes Artisan (`bza-laravel:create-command`), cascades entre services (`bza-laravel:service-cascade`), listeners (`bza-laravel:create-listener`), ressources d'API (`bza-laravel:api-resource`), ressources Filament (`bza-laravel:filament-resource`), OpenAPI, audit ; front (`front-build`, `blade`) |
| `bza-sysadmin` | Environnement local DDEV (`bza-sysadmin:ddev`) |

`bza-laravel` dépend de `bza-dev` ; tous dépendent de `bza`.

Les commandes s'écrivent `/<plugin>:<skill>` : `/bza:lead`, `/bza:projet-init`,
`/bza-laravel:backend`. Claude charge aussi les skills de lui-même quand leur
description correspond au travail en cours.

## Installer

Dans Claude Code :

```text
/plugin marketplace add <chemin ou dépôt GitHub de ce marketplace>
/plugin install bza@bza
/plugin install bza-dev@bza
/plugin install bza-laravel@bza
/plugin install bza-sysadmin@bza
```

Les lois courtes à imposer à chaque session sont dans `managed/claude-md.md`
(version complète : le skill `bza:lois`). Dans une organisation Claude, coller
`managed/settings.json` dans les réglages imposés de Claude Code ; pour un usage
personnel, reprendre `managed/claude-md.md` dans son `~/.claude/CLAUDE.md`.

## Démarrer un projet Laravel

1. Créer le projet (starter Laravel et Filament), puis l'environnement DDEV :
   `bza-sysadmin:ddev`.
2. Créer la trace du projet : `/bza:projet-init`, puis renseigner
   `.ia/context/project.md` (stack prouvée, commandes, pièges d'environnement).
3. Mener chaque demande qui dépasse une modification ponctuelle avec `/bza:lead` :
   contrat validé, exécution, vérification indépendante, clôture tracée.
4. Le travail backend part de `bza-laravel:backend`, le front de
   `bza-dev:frontend`, les tests de bout en bout de `bza-dev:playwright`.

## Comment ça marche dans un projet

- **`.ia/` garde la trace du projet** : contexte, registre des décisions (un
  fichier par décision), règles et skills propres au projet, mémoire de travail
  des agents. Il est versionné avec le projet. Dans un dépôt git, il est créé au
  premier besoin réel ; un fichier `.ia-ignore` à la racine l'interdit.
- **Au démarrage de chaque session**, le hook du plugin `bza` :
  - injecte les règles du projet (`.ia/rules/*.md`) et la liste des décisions
    actives ;
  - expose chaque skill de `.ia/skills/<nom>/` par un lien `.claude/skills/<nom>`,
    ignoré localement par `.git/info/exclude` (jamais commité) ;
  - signale une migration de format en attente.
- **Le garde-fou** (`bash-guard`) refuse `git add -A`/`.`, `commit -a`,
  `--no-verify`, le force-push sur main/master, `rm -rf` sous toutes ses formes,
  `ssh` et l'accès direct aux `.env` ; il demande confirmation pour
  tout push, `--amend` et les opérations git destructives — y compris dans les
  sous-agents.
- **Le travail multi-agents** suit `bza:lead` : la session principale fait le
  travail en chargeant les skills ; elle ne lance un sous-agent que pour un
  travail isolable (`bza-dev:auditor` pour lire beaucoup de code,
  `bza-dev:qa-check` pour une vérification indépendante).

## Faire évoluer le marketplace

- **Ajouter un skill** : `plugins/<plugin>/skills/<nom>/SKILL.md`, avec en tête
  `name: <nom>` et une `description` qui dit ce que fait le skill **et quand
  l'utiliser** (« dans un projet Laravel »).
- **Modifier une loi** : la version complète dans `plugins/bza/skills/lois/`, la
  version courte dans `managed/claude-md.md` (moins de 200 lignes), puis
  `sh tools/build-managed.sh`.
- **Changer le format de `.ia/`** : incrémenter
  `plugins/bza/templates/ia/VERSION` et ajouter la migration
  `plugins/bza/migrations/NNNN-<sujet>.sh` (`plan|apply <racine>`, rejouable),
  avec son test.
- **Publier** : incrémenter `version` dans le `plugin.json` du plugin modifié.
- **Vérifier en local** : `sh tools/check.sh`, puis un essai réel :
  ```bash
  claude --plugin-dir plugins/bza --plugin-dir plugins/bza-dev --plugin-dir plugins/bza-laravel
  ```

Pas de dossier `bin/` à la racine d'un plugin : les exécutables vont dans
`scripts/`, en `sh` + `jq`, sans autre dépendance.
