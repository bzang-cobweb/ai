---
name: env
description: Manipuler les fichiers .env d'un projet (lister les variables, compléter depuis .env.example, écrire une valeur, poser un secret depuis 1Password, lancer une commande avec les variables chargées) sans jamais en voir les valeurs. À utiliser dès qu'une tâche touche un .env ou a besoin de ses variables.
---

# Manipuler un `.env` sans en lire les valeurs

Les fichiers `.env` (et `.env.*`) contiennent des secrets. Claude ne les ouvre
pas, ne les lit pas, ne les modifie pas directement : les réglages de
l'organisation et le hook `bash-guard` le refusent. Il passe par l'outil
ci-dessous, qui ne lui donne que les **noms** des variables.

> `${CLAUDE_PLUGIN_ROOT}` désigne le dossier du plugin `bza`. S'il n'apparaît pas résolu, utiliser le chemin donné au démarrage de session (« [bza] Scripts du plugin bza : … »).

> Toujours appeler l'outil par son chemin complet, sans le ranger dans une variable : le hook ne reconnaît l'outil qu'à son chemin, et refuserait la commande.

| Besoin | Commande |
|---|---|
| Quelles variables, définies ou vides ? | `sh "${CLAUDE_PLUGIN_ROOT}/scripts/env.sh" keys .env` |
| Qu'est-ce qui manque par rapport au modèle ? | `sh "${CLAUDE_PLUGIN_ROOT}/scripts/env.sh" check .env` (modèle : `.env.example` du même dossier) |
| Créer `.env` depuis le modèle | `sh "${CLAUDE_PLUGIN_ROOT}/scripts/env.sh" init .env` |
| Écrire une valeur **non secrète** (`APP_ENV`, une URL locale, un port) | `sh "${CLAUDE_PLUGIN_ROOT}/scripts/env.sh" set .env APP_ENV local` |
| Poser un **secret** | `sh "${CLAUDE_PLUGIN_ROOT}/scripts/env.sh" set-op .env DB_PASSWORD op://<coffre>/<élément>/<champ>` |
| Retirer une variable | `sh "${CLAUDE_PLUGIN_ROOT}/scripts/env.sh" unset .env NOM` |
| Lire ou modifier un modèle versionné (`.env.example`, `.dist`, `.sample`, `.template`, et un `.env.ddev` versionné) | `sh "${CLAUDE_PLUGIN_ROOT}/scripts/env.sh" show .env.example` ; `sh "${CLAUDE_PLUGIN_ROOT}/scripts/env.sh" set .env.example NOUVELLE_VAR ""` |
| Lancer une commande qui a besoin des variables | `sh "${CLAUDE_PLUGIN_ROOT}/scripts/env.sh" run .env -- <commande>` |

## Règles

- **Un secret ne s'écrit jamais avec `set`** : la valeur passerait par la
  conversation. Il s'écrit avec `set-op`, depuis 1Password. La référence
  `op://…`, elle, n'est pas secrète : la demander à l'utilisateur s'il ne l'a pas
  donnée. 1Password lui demande de valider (Touch ID) : c'est voulu.
- **Ajouter une variable au projet** : l'ajouter à `.env.example` (sans valeur
  secrète) **et** au `.env`, pour que `check` reste juste chez les autres.
- **`run` masque les valeurs** dans la sortie de la commande (`***`). Une valeur
  qui apparaîtrait quand même (transformée, encodée, citée dans une erreur) ne
  se recopie jamais : ni dans une réponse, ni dans du code, ni dans un commit.
  Le signaler à l'utilisateur.
- `.ddev/config.local.yaml` est fermé : ni lecture, ni écriture. Une
  modification s'y fait par l'utilisateur, à la main.
- Une commande qui afficherait tout l'environnement (`printenv`, `env`,
  `export -p`) est refusée par le hook : ne pas chercher à la contourner.
