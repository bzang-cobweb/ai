---
name: documentation
description: Rédiger et tenir à jour la documentation projet (README, DOMAIN, ARCHITECTURE, INTEGRATIONS, API, ROLES) à hauteur d'usage — le QUOI, jamais le COMMENT — pour un développeur qui découvre le dépôt.
---

## Quand utiliser ce skill
Dès qu'une tâche demande de créer ou de mettre à jour un document du corpus projet.

## Le destinataire
Un développeur compétent qui n'a **jamais** touché à ce projet, et qui doit
comprendre en une lecture ce que le projet fait, pour qui, et de quoi il est
composé. Il n'a besoin ni des signatures, ni des chemins de fichiers, ni des
choix d'implémentation : le code lui donnera tout cela mieux que la doc.

Cette documentation s'adresse à un **humain**. Le canal machine, ce sont les
specs en mémoire produites par l'auditor (`spec_<concept>`) et, pour les API REST, le
contrat `openapi.yaml` produit par le backend. Ne jamais rapatrier ici ce qui
appartient à ces canaux.

## Test d'altitude

Il s'applique à chaque phrase écrite, et c'est lui que la QA oppose au livrable.

> **Test primaire** — Cette phrase resterait-elle vraie si l'implémentation était
> intégralement réécrite dans un autre langage, à fonctionnalité identique ?
> Si non, elle est au mauvais niveau : la remonter ou la supprimer.

> **Contrôle 1** — Chaque fichier répond à **une seule** question, énoncée en
> tête du fichier. Tout contenu qui ne sert pas cette question sort du fichier.

> **Contrôle 2** — Aucun paragraphe ne s'ouvre sur un nom de classe, de fichier
> ou de fonction. S'applique à `README.md`, `DOMAIN.md` et `ARCHITECTURE.md`
> uniquement : `API.md`, `INTEGRATIONS.md` et `ROLES.md` nomment légitimement des
> éléments techniques et des outils tiers.

## Le corpus

Toujours produits :

| Fichier | La question à laquelle il répond |
|---|---|
| `README.md` | À quoi sert ce projet, pour qui, et comment l'essayer ? |
| `DOMAIN.md` | Que veulent dire les mots propres à ce projet ? |
| `ARCHITECTURE.md` | De quelles grandes pièces est-il fait, et de quoi chacune répond-elle ? |
| `INTEGRATIONS.md` | De quoi ce projet dépend-il à l'extérieur, et qu'est-ce qui tombe si ça tombe ? |

Produits sous condition :

| Fichier | Condition de déclenchement |
|---|---|
| `API.md` | Le projet expose des routes HTTP consommées depuis l'extérieur du projet |
| `ROLES.md` | Le projet a un modèle d'accès : plusieurs acteurs n'ont pas les mêmes droits |

`openapi.yaml` n'appartient **pas** à ce corpus : il est produit par le profil
backend depuis le code, jamais rédigé à la main. `API.md` le référence et ne
duplique aucune de ses signatures.

Ne jamais produire : `DECISIONS.md` / ADR (le *pourquoi* n'est pas dans le code,
il ne peut être écrit qu'en l'inventant), `ROADMAP.md` (documente ce qui
n'existe pas), `CHANGELOG.md` (dérivé de git, déjà outillé). Conventions de code,
installation, configuration et déploiement ne relèvent pas de ce corpus : ils
appartiennent aux profils devops et sre.

## Gabarits

### README.md
1. Une phrase : ce que le projet fait, pour qui.
2. Le problème qu'il résout — l'état du monde sans lui.
3. Ce qu'il ne fait pas (délimiter vaut mieux que promettre).
4. Comment l'essayer : le chemin le plus court vers un premier résultat visible.
5. Où aller ensuite — pointeurs vers les autres documents du corpus.

### DOMAIN.md
Le vocabulaire, et rien d'autre. Pour chaque terme : ce qu'il désigne, à quoi il
sert, ce à quoi il se rattache. Ne retenir que les mots dont le sens est **propre
au projet** — un mot du langage courant ou du framework n'a rien à faire ici.
C'est le seul document qu'un nouveau venu ne peut pas reconstituer en lisant le
code : le soigner en priorité.

### ARCHITECTURE.md
Les grandes pièces, cinq à dix au plus. Pour chacune : de quoi elle répond, ce
qu'elle reçoit, ce qu'elle produit, à quoi elle parle. Puis les parcours
principaux de bout en bout. Pas d'arborescence de fichiers, pas de noms de
classes, pas de justification de choix techniques.

### INTEGRATIONS.md
Pour chaque dépendance externe : à quoi elle sert dans ce projet, ce qui cesse de
fonctionner si elle est indisponible, et si l'usage est bloquant ou dégradable.

### API.md
Les capacités offertes, formulées en termes d'usage : *« un client peut obtenir
X »*, *« le système notifie Y quand Z »*. Qui consomme, à quelles fins, quelles
grandes familles d'opérations existent. **Aucune signature, aucune liste de
paramètres, aucun schéma de réponse** — renvoyer à `openapi.yaml`.

### ROLES.md
Les acteurs du système et ce que chacun peut faire, en termes métier. Pas de
noms de middlewares, de policies ni de gates.

## Sources

Les specs de l'auditor (**Lire la mémoire** `spec_<concept>`) et le code
livré sont la matière première. Elles sont techniques par construction : les
utiliser impose de **remonter d'altitude**, jamais de les paraphraser. Une doc
qui se lit comme une spec reformatée est un échec, même si tout y est exact.

Ne pas attendre qu'un audit soit complet pour documenter : lire directement le
code là où les specs manquent.

## Anti-patterns

| À la place de | Écrire |
|---|---|
| « Le `UserController` expose `index()`, `store()` et `destroy()`. » | « Les comptes se consultent, se créent et se suppriment. » |
| « Le projet utilise Redis pour le cache. » | « Les résultats coûteux sont mémorisés ; sans ce cache, l'application reste correcte mais lente. » |
| « Voir `src/Service/Scheduler.php` pour la logique de planification. » | « Le planificateur décide quelle tâche part, quand, et sur quelles données. » |
| Recopier l'arborescence du dépôt | Nommer les grandes pièces et leur responsabilité |

## Critères transmis à la QA

Cette grille est **figée**. La transmettre telle quelle, sans l'amender ni la
remplacer par des critères de circonstance.

1. Chaque fichier du corpus attendu est présent, et aucun fichier hors corpus n'a été créé.
2. Chaque fichier énonce en tête la question à laquelle il répond, et une seule.
3. Test primaire d'altitude : aucune phrase ne cesserait d'être vraie après une réécriture complète de l'implémentation.
4. Contrôle 2 vérifié sur `README.md`, `DOMAIN.md` et `ARCHITECTURE.md`.
5. `API.md`, s'il existe, ne contient aucune signature ni liste de paramètres.
6. Rien de faux : tout élément nommé (route, service, acteur, dépendance) existe réellement dans le projet.
7. Aucun secret, credential, jeton ni URL interne.

## Règles absolues
- **Incomplet mais jamais faux** — l'exhaustivité n'est pas l'objectif, l'exactitude l'est. Une capacité omise est un manque ; une capacité inventée est une faute.
- Ne documenter que ce qui existe — jamais ce qui est prévu, supposé ou en cours.
- Une zone du code trop ambiguë pour être documentée sans supposer se signale au lead, elle ne se comble pas.
- Ne jamais produire `openapi.yaml` ni aucun artefact destiné aux machines.
- Aucun secret ni credential dans la documentation.

## Règles du rôle
- Corpus : `README.md`, `DOMAIN.md`, `ARCHITECTURE.md`, `INTEGRATIONS.md` ;
  `API.md` si le projet expose des routes HTTP consommées depuis l'extérieur,
  `ROLES.md` s'il a un modèle d'accès
- Sources : `.ia/memory/spec_index.json` pour découvrir les concepts, puis les
  specs **et** la lecture directe du code — les specs sont une matière première,
  pas un modèle de rédaction
- Fin de tâche : vérification par `bza-dev:qa-check`, en lui transmettant la grille
  « Critères transmis à la QA » sans l'amender
- Ne produire aucun artefact destiné aux machines : `openapi.yaml` appartient au
  backend (`bza-laravel:generate-openapi`)
- Ne pas documenter les conventions de code, l'installation, la configuration ni
  le déploiement
- Ne jamais inclure de secret ou de credential
