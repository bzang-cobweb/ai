---
name: projet-init
description: Créer le .ia/ d'un projet (contexte, registre des décisions, règles et skills propres au projet). À utiliser au premier besoin réel de trace dans un dépôt git qui n'a pas de .ia/ — une décision ou un contexte à consigner — ou quand l'utilisateur le demande.
---

# Créer le `.ia/` d'un projet

> `${CLAUDE_PLUGIN_ROOT}` désigne le dossier du plugin `bza`. S'il n'apparaît pas résolu, utiliser le chemin donné au démarrage de session (« [bza] Scripts du plugin bza : … »).

Le `.ia/` garde la trace du projet : son contexte, ses décisions, ses règles et
skills propres. Il est versionné avec le projet.

## Quand

- Dans un dépôt git, **au premier besoin réel** : une décision à consigner, un
  contexte de projet à poser. Pas « au cas où » : un `.ia/` vide dans chaque
  dépôt cloné pour lire du code est une pollution.
- Hors de git : seulement si l'utilisateur le demande explicitement.
- **Jamais** si un fichier `.ia-ignore` est présent à la racine.

## Comment

1. Annoncer à l'utilisateur ce qui va être créé, et pourquoi maintenant.
2. Lancer :
   ```
   sh "${CLAUDE_PLUGIN_ROOT}/scripts/ia-init.sh" "<racine du projet>"
   ```
   Le script n'écrase rien et ne commite rien.
3. Remplir `.ia/context/project.md` avec l'utilisateur, en appliquant
   `bza:analyse-projet` : **chaque affirmation de stack cite sa preuve**
   (`composer.lock:14`, `package.json:22`) — jamais de version écrite de mémoire.
4. Proposer le commit, par chemin :
   ```
   git add -- .ia
   git commit -m "Trace IA du projet : contexte et registre des décisions" -- .ia
   ```

## Ce que contient `.ia/`

| Chemin | Rôle |
|---|---|
| `VERSION` | Format du `.ia/` (voir `bza:migrer`) |
| `context/project.md` | Contexte du projet, lu au démarrage |
| `context/decisions.md` | Mode d'emploi du registre et modèles d'entrée |
| `context/decisions/` | Le registre : un fichier par décision (`bza:decision`) |
| `rules/` | Règles propres au projet, chargées à chaque session |
| `skills/<nom>/SKILL.md` | Skills propres au projet, exposés automatiquement |
| `memory/` | Mémoire de travail des agents (specs d'audit, infra) |
| `runs/` | Rapports des chantiers menés selon `bza:lead` |
