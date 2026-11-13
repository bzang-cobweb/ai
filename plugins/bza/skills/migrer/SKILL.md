---
name: migrer
description: Mettre le .ia/ d'un projet au format attendu par le plugin bza. À utiliser quand le démarrage de session signale une migration en attente, ou à la demande.
---

# Migrer le `.ia/` d'un projet

> `${CLAUDE_PLUGIN_ROOT}` désigne le dossier du plugin `bza`. S'il n'apparaît pas résolu, utiliser le chemin donné au démarrage de session (« [bza] Scripts du plugin bza : … »).

Une migration modifie des fichiers suivis par git. Elle ne s'applique donc
**jamais sans l'accord de l'utilisateur, donné après lecture du plan**.

1. Vérifier que l'arbre de travail est propre (`git status`). S'il ne l'est pas,
   le signaler : une migration mêlée à un travail en cours produit un commit
   illisible.
2. Afficher le plan, sans rien modifier :
   ```
   sh "${CLAUDE_PLUGIN_ROOT}/scripts/migrate.sh" plan "<racine du projet>"
   ```
3. Présenter le plan à l'utilisateur, en distinguant ce qui sera supprimé, ce
   qui sera déplacé, et ce qui est **conservé pour revue à la main** (lignes
   `CONSERVER` et `À REVOIR`). Attendre son accord.
4. Appliquer :
   ```
   sh "${CLAUDE_PLUGIN_ROOT}/scripts/migrate.sh" apply "<racine du projet>"
   ```
5. Traiter avec l'utilisateur les lignes `CONSERVER` / `À REVOIR`, une par une.
6. Proposer un commit unique, par chemin, avec la liste des fichiers touchés
   (`git status --short`). Message : « Migration du .ia/ au format <N> ».

Une migration se relance sans dégât : en cas de doute, relancer le plan.
