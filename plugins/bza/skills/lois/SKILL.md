---
name: lois
description: Lois de travail — sécurité et secrets, git, preuve de livraison, escalade et registre des décisions, cohérence du code, façon d'interagir. À appliquer à tout travail de projet, dans le code comme dans une conversation ; à relire avant de commiter, de livrer, de demander un arbitrage ou de manipuler un secret.
---

# Lois

Ces lois s'appliquent à **tout** travail, quel que soit le
projet, la stack ou l'outil. Une règle propre à un projet (`.ia/rules/`) les
**complète**, elle ne les contredit jamais : en cas de conflit, la loi gagne et
le conflit se signale.

Dans Claude Code, l'essentiel de ces lois est déjà chargé par l'organisation.
Ce skill porte leur version complète : lire le fichier concerné **avant** le
geste qu'il encadre.

| Loi | Fichier | À lire avant de… |
|---|---|---|
| Sécurité et secrets | [securite.md](securite.md) | manipuler une credential, partager du code, configurer un environnement ; un `.env` se manipule par `bza:env` |
| Git | [git.md](git.md) | commiter, intégrer, toute commande git mutante |
| Preuve | [preuve.md](preuve.md) | annoncer qu'un travail est fait, rendre un verdict |
| Escalade et décisions | [escalade.md](escalade.md) | poser une question à l'humain, consigner sa réponse |
| Cohérence du code | [coherence.md](coherence.md) | poser un correctif, ajouter une règle métier |
| Interactions | [interactions.md](interactions.md) | répondre à un humain ou exécuter une tâche d'agent |

## La trace d'un projet vit dans `.ia/`

- `.ia/context/project.md` : contexte du projet, lu au démarrage.
- `.ia/context/decisions/` : le registre des décisions, un fichier par entrée
  (skill `bza:decision`). Un point qui y figure ne se re-signale pas.
- `.ia/rules/` et `.ia/skills/` : règles et skills propres au projet.
- `.ia/memory/` : la mémoire de travail des agents (specs d'audit, infra).

**Jamais la mémoire native de l'outil** (auto-memory, mémoire de conversation) :
ce qui doit survivre à la session va dans `.ia/`, versionné avec le projet.

Un dépôt git sans `.ia/` : le créer au premier besoin réel (une décision ou un
contexte à consigner) avec `bza:projet-init`. Un fichier `.ia-ignore` à la racine
signifie que la couche IA ne laisse aucune trace dans ce dépôt : ne rien y créer.

## Dans une conversation sans projet (claude.ai, Cowork)

Les lois s'appliquent aussi. En particulier : aucun secret ni donnée client
confidentielle dans une conversation (`securite.md`), une décision qui engage un
projet se consigne ensuite dans son registre, et une réponse qui affirme un fait
technique s'appuie sur une preuve, pas sur un souvenir.
