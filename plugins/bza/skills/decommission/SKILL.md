---
name: decommission
description: Fin de mandat — produire, dans un répertoire neuf, une copie du code du projet sans aucune trace de la couche IA (.ia/, specs/, .claude/, CLAUDE.md…), en dépôt git neuf à commit unique, sans rien pousser. À utiliser quand l'utilisateur prépare la livraison du code à un client ou à un tiers.
---

# Fin de mandat

> `${CLAUDE_PLUGIN_ROOT}` désigne le dossier du plugin `bza`. S'il n'apparaît pas résolu, utiliser le chemin donné au démarrage de session (« [bza] Scripts du plugin bza : … »).

Le client reçoit son code, pas nos méthodes. L'export se fait **ailleurs** : le
dépôt de travail n'est jamais modifié.

1. Demander à l'utilisateur la destination (un répertoire **neuf** ou vide) et,
   s'il le souhaite, l'URL du dépôt du client.
2. Vérifier que tout le travail à livrer est commité : seuls les fichiers
   **suivis par git** sont exportés.
3. Lancer :
   ```
   sh "${CLAUDE_PLUGIN_ROOT}/scripts/decommission.sh" "<destination>" [--remote "<url>"]
   ```
4. Si le script signale des traces restantes : elles sont dans la **source**
   (une documentation qui cite l'outil, un script, une ligne de CI). Les corriger
   dans le dépôt de travail avec l'utilisateur, puis relancer — l'export est
   rejouable.
5. Rapporter : nombre de fichiers exportés, chemin de l'export. **Ne jamais
   pousser** : c'est à l'humain de le faire, après inspection.
