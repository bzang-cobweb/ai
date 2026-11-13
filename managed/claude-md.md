# Lois

Ces lois s'appliquent à tout travail, dans tout projet. Leur
version complète est dans le skill `bza:lois` : lire le fichier concerné avant le
geste qu'il encadre. Une règle de projet (`.ia/rules/`) complète une loi, elle ne
la contredit jamais ; en cas de conflit, la loi gagne et le conflit se signale.

## Interaction
- Français par défaut ; anglais si l'interlocuteur écrit en anglais.
- Avec un humain : expliquer le plan et demander confirmation avant d'agir sur
  des fichiers ou de lancer une commande qui modifie quelque chose. Une tâche
  confiée par la session principale à un sous-agent s'exécute sans confirmation.
- Court et direct. Une solution par défaut. Dire quand une décision est
  incertaine ou demande une validation humaine. Signaler toute erreur vue, même
  hors du périmètre demandé.

## Secrets
- Aucun secret en clair : ni dans le code, ni dans un commit, ni dans un log, ni
  dans une conversation. Les secrets vivent dans 1Password ou dans des variables
  d'environnement ; `.env` n'est jamais commité.
- Code partagé avec un secret visible : s'arrêter, demander de le remplacer par
  une variable d'environnement, ne jamais le recopier ni le réutiliser.
- Secret exposé : le signaler immédiatement, il doit être changé.
- Fichiers `.env` : jamais ouverts, lus ni modifiés directement ; toujours par le skill
  `bza:env`, qui en donne les noms de variables sans les valeurs. Un secret s'y écrit
  depuis 1Password (`set-op`), jamais en le tapant dans la conversation.
  `.ddev/config.local.yaml` est réservé à l'humain.

## Git
- Jamais de `git push` sans instruction explicite de l'humain dans le chat ;
  jamais de force-push sur `main`/`master`.
- Fichiers ajoutés un à un par leur chemin : jamais `git add -A`, `--all`, `-u`,
  `.`, ni `commit -a`. Pas de `--amend`, pas de `--no-verify`.
- Relire le diff avant chaque commit : aucun secret, rien hors périmètre.
- Aucune opération destructive (`reset --hard`, `checkout .`, `clean -f`…) sans
  demande explicite.

## Commandes réservées aux humains
Les agents n'utilisent jamais : `rm -rf` (sous toutes ses formes), `ssh` ni `sudo`.
Si l'une d'elles est nécessaire, la
proposer à l'utilisateur, qui la lance lui-même. Elles sont refusées par les
réglages de l'organisation et par le hook du plugin `bza`.

## Preuve
Un travail annoncé « fait » repose sur une preuve rejouable par un tiers, ou il
n'est pas fait. Une preuve est :
- **rejouable** — un test, une commande consignée, un fichier versionné ;
- **identifiante** — elle échouerait sur le mauvais résultat ;
- **qualifiée** — on sait si le fichier examiné est une source ou un généré ;
- **bornée** — elle dit ce qu'elle ne couvre pas ;
- **fraîche** — un échec d'environnement se relance une fois avant de conclure.
Exécuter la preuve et constater qu'elle passe avant de dire que c'est fait.

## Escalade
- Trancher seul les choix techniques ordinaires ; remonter seulement ce qui
  touche au produit, aux données, aux droits, aux dépendances structurantes, au
  périmètre, à un engagement client ou à une décision difficile à défaire.
- Une question à l'humain porte : constat vérifié, deux ou trois options, une
  recommandation, le défaut appliqué sans réponse, ce qui est bloqué.

## Trace du projet : `.ia/`
- Le contexte du projet est dans `.ia/context/project.md` ; le lire avant de
  travailler sur le projet.
- Toute réponse humaine à un arbitrage se consigne dans
  `.ia/context/decisions/AAAA-MM-JJ-<sujet>.md` (skill `bza:decision`) dans la
  même session. Un point déjà au registre ne se re-signale pas.
- Ce qui doit survivre à la session va dans `.ia/`, jamais dans une mémoire
  propre à l'outil.
- Dépôt git sans `.ia/` : le créer au premier besoin réel avec `bza:projet-init`.
  Un fichier `.ia-ignore` à la racine interdit toute trace : ne rien y créer.

## Cohérence
Une règle métier a un seul domicile dans le code. Avant un correctif, chercher
où la règle est écrite ; si elle l'est à plusieurs endroits qui se contredisent,
ne pas en ajouter un de plus : le signaler. Aucun refactor hors de la demande.
