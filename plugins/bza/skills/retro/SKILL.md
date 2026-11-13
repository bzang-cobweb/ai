---
name: retro
description: Rétrospective d'une session ou d'un chantier — relire ce qui s'est réellement passé et proposer, rangé à la bonne place, ce qui évitera les mêmes erreurs la prochaine fois — garde-fou, loi, skill du marketplace, règle du projet. À lancer en fin de chantier, après une nuit, ou quand une même erreur revient.
disable-model-invocation: true
---

# Rétrospective

On n'améliore pas l'agent en lui répétant une consigne : on améliore son
**environnement** — un contrôle qui attrape l'erreur, une information trouvable, une
consigne mieux placée. La rétrospective relit ce qui s'est passé et propose ces
changements. **Elle ne modifie rien sans l'accord de l'humain.**

## 1. Lire les sources

Par défaut, la session en cours. Sinon, celle que l'humain désigne :

- **Journaux de session** : `~/.claude/projects/<dossier du projet, encodé>/<session>.jsonl`.
  Ne pas les lire en entier : en extraire avec `jq` les appels d'outils, leurs erreurs,
  les refus de hook (`[bza] …`), les relances d'une même commande, les corrections de
  l'humain.
- **Trace du projet** : `.ia/runs/` (rapports de tâche, `RETEX.md`, bilans de nuit),
  `.ia/context/decisions/`, et le `git log` du chantier.

Noter ce qui n'a pas été lu : la rétrospective est bornée, comme toute preuve.

## 2. Chercher

| Catégorie | Signe dans la session |
|---|---|
| **Erreur qu'un contrôle aurait attrapée** | Une erreur mécanique (motif fixe, commande interdite, emplacement de fichier) corrigée après coup, ou pas du tout |
| **Garde-fou qui se trompe** | Un refus injustifié (faux positif) contourné, ou un geste dangereux passé sans refus (trou) |
| **Information introuvable** | Longue recherche d'un fichier, d'une commande, d'une convention ; information qui n'existait nulle part |
| **Consigne ignorée ou mal comprise** | Un skill qui aurait dû se déclencher et ne l'a pas fait ; une règle appliquée de travers. La description d'un skill est son déclencheur : c'est souvent elle qu'il faut reprendre |
| **Consigne sans effet ou trop lourde** | Instructions que rien dans la session n'a utilisées ; lois condensées au-delà de 200 lignes |
| **Outil coûteux** | Appels répétés, sorties énormes, commandes qui auraient pu être groupées |
| **Accès manquant** | Une information cruciale hors de portée : journaux d'un serveur de dev, service en lecture seule |
| **Répétition** | Ce qui s'est produit deux fois est une règle candidate |

**Mécanique ou jugement** : une erreur mécanique appelle un contrôle automatique, pas
une phrase de plus. Seule une question de jugement (cohérence entre fichiers, « comme
le code voisin ») devient une règle écrite.

## 3. Ranger chaque piste à sa place

| La leçon… | Elle va dans |
|---|---|
| est mécanique, et vaut partout | **marketplace** : hook `bash-guard`, ou permission dans `managed/settings.base.json` |
| est une règle de conduite commune | **marketplace** : `managed/claude-md.md` (version courte) et `bza:lois` (version complète) |
| est un savoir-faire de stack ou de métier | **marketplace** : un skill du plugin concerné (`bza-dev`, `bza-laravel`…), ou sa description |
| ne vaut que pour ce projet | **projet** : `.ia/rules/`, `.ia/skills/`, ou `.ia/context/project.md` pour une information à retrouver |
| est un arbitrage | **registre** : `bza:decision` |
| concerne le poste ou un outil tiers | **note pour l'humain** (réglage, outil à corriger), hors marketplace |

**Marketplace ou projet ?** Une leçon va au marketplace si elle resterait vraie mot pour
mot sur un autre projet. Une proposition pour le marketplace ne contient **aucun nom de
client, URL, donnée ni identifiant**.

## 4. Rendre

Le rapport s'écrit dans `.ia/runs/retro-AAAA-MM-JJ.md` si le projet a un `.ia/`, sinon
dans la conversation :

```
# Rétrospective du AAAA-MM-JJ — <session ou chantier>
Sources lues : <journaux, rapports, commits> — Non lu : <…>

## Pistes, de la plus grave à la moins grave
### 1. <titre>
- Constat : <ce qui s'est passé, avec sa preuve : extrait de session, commit>
- Cause : <pourquoi l'environnement l'a permis>
- Destination : <marketplace : … | projet : … | registre | note pour l'humain>
- Proposition : <diff ou texte prêt à appliquer>
- Coût : <fichiers touchés, contrôle à écrire, tests>
```

Puis proposer à l'humain les pistes du **projet** (écrire la règle ou le contexte dans
`.ia/`, et le commiter) et du **registre** (`bza:decision`), une par une.

## 5. Remonter au marketplace

Dès qu'**au moins une piste** a le marketplace pour destination.

1. Rédiger les pistes pour le marketplace, chacune avec sa proposition, et le rapport
   **expurgé** : aucune valeur secrète, aucune donnée personnelle, aucun nom de client.
2. **Montrer le texte à l'humain et attendre son accord.**
3. Travailler dans un clone du dépôt du marketplace, sur une branche
   **`retro/AAAA-MM-JJ-<sujet>`** partie de `main`. Jamais sur `main`.
4. Un commit par piste, avec ses tests ; `sh tools/check.sh` doit passer, et la version
   du plugin modifié est incrémentée.
5. Pousser la branche (le garde-fou demande la confirmation de l'humain) et ouvrir la
   pull request. Sans accès au dépôt : écrire le texte complet dans
   `.ia/runs/retro-AAAA-MM-JJ-marketplace.md` et le remettre à l'humain.

## Règles absolues

- Rien n'est appliqué ni envoyé sans l'accord de l'humain : ni piste, ni
  pull request
- Jamais modifier un plugin installé sur le poste : un changement du marketplace passe
  par son dépôt et sa pull request
- Chaque constat cite sa preuve ; une impression n'est pas une piste
- Une piste a une seule destination ; deux destinations, ce sont deux pistes
- Aucune valeur secrète ni donnée personnelle dans un ticket ; aucun nom de client, URL
  ni donnée dans une pull request

---

Adapté du skill `retro` de Matt Pocock (`mattpocock/skills`, licence MIT) : voir
[ATTRIBUTION.md](ATTRIBUTION.md).
