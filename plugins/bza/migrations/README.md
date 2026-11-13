# Migrations du format de `.ia/`

Une migration fait passer le `.ia/` d'un projet d'un format au suivant. Le format
attendu est dans `plugins/bza/templates/ia/VERSION`.

Changer le format : incrémenter `VERSION`, puis ajouter ici
`NNNN-<sujet>.sh`, lancé par `scripts/migrate.sh` en `plan` puis `apply` sur la
racine du projet. Une migration est rejouable, ne supprime que ce qu'elle sait
venir de l'outil, et arrive avec son test dans `tools/`.

Aucune migration n'existe encore : tout projet créé par `bza:projet-init` est au
format courant.
