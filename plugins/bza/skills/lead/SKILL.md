---
name: lead
description: Mener un chantier sur un projet doté d'un .ia/ — de la demande au contrat validé, à l'exécution, à la vérification indépendante et à la clôture tracée. À utiliser pour toute demande qui dépasse une modification ponctuelle (fonctionnalité, correctif transverse, migration, audit), ou quand l'humain dépose une demande dans specs/todo/.
---

# Mener un chantier

`lead` n'est pas un agent à qui l'on délègue : c'est **la façon dont la session
principale mène un chantier**. La session fait le travail elle-même, en chargeant
les skills utiles au fil de l'eau. Elle ne lance un sous-agent que pour un
travail **isolable**, qui demande peu du reste du contexte et rend un résultat
compact :

| Sous-agent | Quand |
|---|---|
| `bza-dev:auditor` | Lire beaucoup de code existant et en tirer une spec par concept, sans encombrer la session |
| `bza-dev:qa-check` | Vérifier un livrable **sans** le contexte de celui qui l'a produit — c'est ce qui rend le verdict indépendant |
| Agents d'exploration natifs | Recherches indépendantes menées en parallèle |

Découper un chantier par métier (un agent backend, un agent frontend…) fait
perdre de l'information à chaque passage de relais. Ne pas le faire.

Sans humain pour répondre (la nuit, un week-end) : `bza:nuit`, qui reprend cette
méthode et dit ce qu'elle lève.

## 1. Ouvrir — cinq minutes, avant tout travail

1. Lire `.ia/context/project.md` et **confronter trois de ses affirmations au
   disque** (version de framework, présence d'un composant, chemin
   d'exécution). Une fausseté dans le contexte se propage à tout ce qui suit.
2. Relire le registre `.ia/context/decisions/`, notamment les **règles de
   blocage en vigueur** : une règle dont le motif est tombé se lève
   explicitement, par une nouvelle entrée (`bza:decision`).
3. Demander quelles **dépendances** le chantier peut ajouter ou modifier. C'est
   la seule autorisation à demander d'avance (`bza:lois/git.md`).

## 2. De la demande au contrat

Une demande déposée dans `specs/todo/` (ou formulée dans le chat) suit ce cycle.
**Une demande à la fois** : s'il y en a plusieurs dans `specs/todo/`, prendre la
plus ancienne.

1. **Clarifier** — poser les questions à l'humain **au format d'escalade**
   (`bza:lois/escalade.md`) : constat, options, recommandation, défaut appliqué
   sans réponse, ce qui reste bloqué. Ne rien produire à ce stade.
2. **Contractualiser** — rédiger `specs/AAAA-MM-JJ-<nom>.md` : ce que *tu as
   compris*, le découpage prévu, les critères de succès. Ce n'est pas une copie
   de la demande, c'est ta lecture de la demande.
3. **Faire valider** — demander l'accord de l'humain et **l'attendre**. Il
   valide ce que tu as compris, pas ce qu'il a écrit. La réponse est consignée
   dans `.ia/context/decisions/` **avant** de commencer.

### Écrire un critère de succès

Un critère énonce **ce qui doit être vrai à la fin**, jamais le mécanisme par
lequel on imagine y arriver. S'il nomme un fichier, un import ou un nombre
d'occurrences, c'est probablement un mécanisme : le reformuler en résultat
observable. Quand le travail tient le but mais pas la lettre du critère,
**présumer le critère fautif** et l'examiner.

## 3. Exécuter

- **Code existant touché → audit d'abord.** Lancer `bza-dev:auditor` sur les
  concepts concernés avant toute implémentation ; les specs d'un chantier
  précédent sont réputées périmées.
- **Situer chaque correctif** : nommer la règle générale dont le défaut est un
  cas particulier, et le fichier qui la porte (`bza:lois/coherence.md`). Plusieurs
  implémentations divergentes → domicilier la règle **avant** de corriger.
- Charger le skill de la stack ou du geste au moment où il sert
  (`bza-laravel:backend`, `bza-dev:frontend`).
- **Parallélisme** : les lectures se lancent en parallèle librement. Des
  sous-agents qui écrivent ne tournent en parallèle que sur des périmètres
  **disjoints**, ou isolés en worktree (`isolation: "worktree"`). Tout ce qu'un
  agent en worktree doit lire (`.ia/`, le contrat) est commité avant.
- Chaque livrable est commité par chemin (`bza:lois/git.md`).

### Confier une tâche à un sous-agent

Le sous-agent ne voit que son prompt. Il ne reçoit rien en cours de route : pour
changer sa consigne, l'arrêter et le relancer avec la nouvelle consigne.

```
Chantier : <AAAA-MM-JJ-nom> — tâche <NN>
Tâche : <énoncé>
Périmètre de fichiers (écriture autorisée) : <liste / globs> | lecture seule
Mémoire à lire : <.ia/memory/...> | aucune
Critères de succès (état observable) : <liste>
Dépendances autorisées : aucune | <lesquelles, autorisées par l'humain le …>
Contexte utile : <décisions, messages, résultats d'autres tâches>
Rapport : .ia/runs/<chantier>/<NN>-<agent>-<tâche>.md
```

### Les opérations nommées des skills

Plusieurs skills décrivent le travail en opérations en gras. Elles se traduisent
ainsi :

| Opération | Geste |
|---|---|
| **Prendre la tâche** | La tâche est la demande de l'humain, ou le prompt de lancement d'un sous-agent |
| **Lire / Écrire la mémoire `<clé>`** | Lire / écrire `.ia/memory/<clé>.json`, le relire, le commiter. Fichier absent = clé absente. Le préfixe `spec_` est réservé à `bza-dev:auditor` |
| **Point d'étape** | Section « Point d'étape » du rapport de la tâche |
| **Écrire à `<destinataire>`** | Ligne `→ <destinataire> : <contenu>` dans le rapport ; la session principale la transmet |
| **Clore la tâche** | Rapport final `STATUT : DONE` (`bza:rapport-de-tache`) |
| **Bloquer la tâche** | S'arrêter, rapport final `STATUT : BLOQUÉ` + raison. Une extension de périmètre se demande ainsi : `Extension demandée : <fichiers> — <motif>` |
| **Consulter l'humain** | Question dans le chat, au format d'escalade |

## 4. Vérifier — go / no-go

- Fin d'une étape ou du chantier : lancer `bza-dev:qa-check` avec les critères de
  succès. Ne pas lui transmettre le raisonnement de l'implémentation : c'est son
  ignorance du contexte qui rend le verdict indépendant.
- **Go** : 0 écart bloquant → étape suivante.
- **No-go** : corriger, puis relancer `bza-dev:qa-check`.
- Tout verdict est **borné** (ce qu'il ne couvre pas) et inscrit au registre.

## 5. Clore

1. Déplacer la demande vers `specs/done/AAAA-MM-JJ-<nom>.md` **sans la
   modifier** : l'écart avec le contrat est l'information utile.
2. Compléter le contrat de quatre sections, dans cet ordre : *Ce que j'ai décidé
   seul*, *Ce qui a été fait*, *Ce que je n'ai pas vérifié*, *Ce qui reste en
   suspens*.
3. Retour d'expérience court dans `.ia/runs/<chantier>/RETEX.md` : **ce qui
   s'est produit deux fois devient une règle candidate** — pour le projet
   (`.ia/rules/`) ou pour tous les projets (à proposer dans le marketplace). Y répondre
   aussi : quelle règle a été ré-implémentée, laquelle a trouvé un domicile ?
4. Proposer à l'humain une rétrospective (`/bza:retro`) si le chantier a connu des
   erreurs répétées, des refus du garde-fou ou des recherches longues : elle range
   chaque leçon à sa place (garde-fou, loi, skill du marketplace, règle du projet).

> « Décidé seul » vient en tête parce que c'est la section qui se lit vraiment.
> « Pas vérifié » vient avant « en suspens » parce qu'un angle mort n'est pas une
> tâche restante : personne ne sait encore qu'il existe.

## Règles absolues

- Jamais de travail avant que l'humain ait validé le contrat
- Code existant touché → audit avant implémentation
- Jamais d'étape suivante sans go de `bza-dev:qa-check`
- Ne jamais modifier une demande déplacée dans `specs/done/`
- Toute réponse humaine à un arbitrage est consignée dans `.ia/context/decisions/`
  dans la session où elle arrive
- Un chantier ne se termine jamais « réussi » s'il reste des questions sans réponse
- Jamais de chantier ouvert « pour occuper » : sans demande, on attend
