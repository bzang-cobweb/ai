---
name: ddev
description: Mettre en place et maintenir l'environnement local DDEV d'un projet PHP (Laravel, TYPO3, Drupal, WordPress) — services, commandes custom, environnement E2E isolé — sans toucher au code applicatif.
---

## Quand utiliser ce skill
Quand une tâche demande de mettre en place, d'étendre ou de réparer
l'environnement de développement local.

## Procédure d'initialisation
1. Détecter le type de projet (Laravel, TYPO3, WordPress…) et la version PHP attendue
2. `ddev config --project-type=<type> --php-version=<version> --docroot=<docroot>`
3. Ajouter les services nécessaires dans `.ddev/config.yaml` : Redis, Mailpit, Solr, Elasticsearch…
4. Configurer les hooks `post-start` si besoin (composer install, migrations…)
5. `ddev start` → vérifier que **tous** les services remontent `OK`
6. **Écrire la mémoire** `infra_ddev` avec les services, les URLs et les commandes disponibles

## Second environnement : E2E
Un projet doté de tests E2E a besoin d'une application dédiée. La doctrine est
dans `bza-dev:e2e-isolation` ; voici sa traduction DDEV.

**Le code est partagé, tout le reste est séparé.** Le service E2E monte le même
répertoire de travail que le service `web` : une seconde instance DDEV sur un autre
checkout testerait le code d'hier. Ce qui doit diverger, c'est le **processus** —
donc ses variables d'environnement, sa base et son stockage.

1. **Base dédiée** — la créer dans le conteneur `db` existant, via un hook
   `post-start` pour qu'elle survive à un `ddev delete`/`ddev start` :
   ```yaml
   hooks:
     post-start:
       - exec-host: ddev mysql -uroot -proot -e "CREATE DATABASE IF NOT EXISTS db_e2e; GRANT ALL ON db_e2e.* TO 'db'@'%';"
   ```
2. **Second service web** — `.ddev/docker-compose.e2e.yaml`. Squelette : l'image et
   le montage viennent du service `web`, les variables d'environnement sont ce qui
   fait l'isolation.
   ```yaml
   services:
     web-e2e:
       image: ${DDEV_WEBIMAGE}
       container_name: ddev-${DDEV_SITENAME}-web-e2e
       labels:
         com.ddev.site-name: ${DDEV_SITENAME}
         com.ddev.approot: ${DDEV_APPROOT}
       volumes:
         - ../:/var/www/html:cached
       environment:
         - HTTP_EXPOSE=8081:80
         - APP_ENV=e2e
         - DB_DATABASE=db_e2e
   ```
   L'URL E2E est alors `http://localhost:8081`. Si l'application impose HTTPS (cookies sécurisés,
   redirections), exposer aussi le service en HTTPS (`HTTPS_EXPOSE`) et utiliser cette URL. Un `additional_fqdns` avec
   `VIRTUAL_HOST` est possible, mais un port distinct suffit à faire une URL
   distincte — et demande moins de configuration de routeur pour le même résultat.
3. **Stockage dédié** — un répertoire propre au service E2E, jamais versionné, jamais
   partagé avec le dev.
4. **Commande unique** — `.ddev/commands/host/test-e2e` enchaîne reset, migrations,
   seed, fixtures puis Playwright. Le développeur ne doit avoir aucune étape à ne pas
   oublier.
5. **Vérification** — `ddev restart`, puis, **depuis le service E2E**, confirmer que
   l'application voit bien la base E2E (`ddev exec -s web-e2e ...`) et que le dev
   répond toujours sur sa propre URL avec sa propre base. Un service E2E qui pointe
   silencieusement sur la base de dev est le pire résultat possible : tout a l'air de
   marcher.
6. **Écrire la mémoire** `infra_e2e` — enveloppe figée par le skill `e2e-isolation`.

## Commandes custom
Les commandes projet vont dans `.ddev/commands/<service>/<nom>`. Chaque commande
ajoutée porte une ligne `## Description:` — c'est elle qui s'affiche dans
`ddev help`, et c'est la seule documentation que le reste de l'équipe lira.

## Règles absolues
- Ne jamais modifier le code source de l'application — uniquement l'infrastructure locale
- Ne jamais marquer done sans un `ddev start` vérifié
- Ne jamais marquer done un environnement E2E sans avoir constaté, depuis le service
  E2E lui-même, quelle base il utilise
- `.ddev/config.local.yaml` contient les secrets locaux : jamais commité
- Toute commande custom ajoutée est documentée dans le contexte projet

## Règles absolues
- Jamais modifier le code source de l'application : uniquement l'infrastructure locale
- Toujours vérifier `ddev start` avant de marquer done
- Un livrable de configuration d'environnement n'est pas `done` tant qu'il n'est
  pas commité — sinon il s'évapore au premier nettoyage
- Les secrets locaux (`.ddev/config.local.yaml`) ne sont jamais commités, ni lus ni
  modifiés par Claude : l'humain les modifie à la main. Les `.env` passent par `bza:env`
- Documenter chaque commande custom ajoutée, dans `.ia/context/project.md`
- Projet avec tests E2E : fournir le second environnement (URL, base, stockage,
  commande unique `test-e2e`) selon `bza-dev:e2e-isolation`, et le décrire dans
  `.ia/memory/infra_e2e.json` — noms de champs figés par ce skill
- **Un service E2E ne partage jamais la base ni le stockage du dev**
- **L'environnement d'un processus est fixé à son démarrage** : jamais choisi par
  un header, un nom d'hôte ou un paramètre de requête
- Rapport de fin de tâche : `bza:rapport-de-tache`
