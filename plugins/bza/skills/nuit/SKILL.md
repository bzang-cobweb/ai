---
name: nuit
description: Mode nuit — faire avancer seul un projet doté d'un .ia/ pendant que l'humain est absent (demandes de specs/todo/, suspens des contrats), sur une branche dédiée, en tranchant au lieu de questionner, sans rien d'irréversible, avec un bilan lisible au matin. Ne s'active que sur demande explicite (/bza:nuit), typiquement depuis une tâche planifiée du soir.
---

# Mode nuit — le projet avance seul, l'humain relit au matin

Ce mode ne s'active **que** par `/bza:nuit`. Hors de ce lancement, il ne s'applique pas.

L'humain est **absent et ne répondra pas** avant la fin de la session. Il délègue
les arbitrages techniques : une question posée la nuit n'a pas de réponse avant le
matin, et une session qui l'attend a perdu la nuit entière. La méthode reste celle
de `bza:lead`, et toutes les lois s'appliquent : ce skill ne lève que ce qu'il nomme.

## 0. Ouvrir la nuit

1. **Arbre de travail propre** (`git status`). S'il ne l'est pas : ne rien toucher,
   ne rien mettre de côté, écrire le bilan (« arbre non propre, nuit annulée ») et
   s'arrêter. Le travail non commité de l'humain ne se manipule pas en son absence.
2. **Branche dédiée** : `git switch -c nuit/AAAA-MM-JJ` depuis la branche courante.
   C'est le seul changement de branche de la nuit. Au matin, l'humain relit, intègre
   ou jette la branche d'un seul geste.
3. **Ouvrir le bilan** : `.ia/runs/nuit-AAAA-MM-JJ/BILAN.md` (§6), commité tout de
   suite, avant le premier travail.
4. Ouverture de `bza:lead` (contexte confronté au disque, registre relu), **sans** la
   question des dépendances : la nuit, aucune n'est ajoutée.

## 1. Ce que le mode nuit lève

| Règle de jour (`bza:lead`) | La nuit |
|---|---|
| Faire valider le contrat et **attendre** | Le contrat s'écrit, puis s'exécute. Son en-tête porte `Validation : non — exécuté en mode nuit le AAAA-MM-JJ`. Les interprétations retenues vont dans « Ce que j'ai décidé seul ». |
| Clarifier en posant les questions | Trancher chaque ambiguïté avec le contexte du projet (specs, conventions, implémentations voisines) ; retenir la lecture la plus cohérente et la moins complexe ; la noter. |
| Une demande à la fois | Les demandes de `specs/todo/` se traitent l'une après l'autre, de la plus ancienne à la plus récente. Une demande close ouvre la suivante. |
| Sans demande, on attend | On reprend du **travail déjà défini** (§3), jamais un chantier inventé. |
| Modifier le schéma de base : poser la question | Autorisé si la migration est **additive et réversible** (§4). |
| Consulter l'humain et attendre | Ne jamais attendre. L'escalade s'écrit au format habituel, son **défaut s'applique immédiatement**, elle entre au bilan et au registre (`bza:decision`, « Tranché par : session de nuit, défaut d'escalade »). |

## 2. Ce qui ne bouge pas

- Aucun `git push`, aucun merge, aucun changement de branche après l'ouverture. Le
  garde-fou demanderait une confirmation que personne ne donnera : la session
  resterait bloquée jusqu'au matin.
- **Dépendances** (`composer.json`, `package.json`, lockfiles) : aucun ajout. Le
  besoin se note, la tâche se bloque, le travail continue ailleurs.
- **Secrets** : `bza:env set-op` demande une validation humaine (Touch ID) ; un secret
  manquant bloque la tâche, il ne se contourne pas.
- Audit avant implémentation sur du code existant (`bza-dev:auditor`) ; vérification
  `bza-dev:qa-check` avant chaque étape suivante ; loi de preuve pour toute livraison.
- Jamais de test désactivé, de protection contournée, d'erreur masquée, ni de spec
  détournée pour obtenir un état vert.
- Pas de refactor hors demande, pas de chantier ouvert pour anticiper.

## 3. D'où vient le travail

Dans cet ordre, sans rien inventer au-delà :

1. les demandes de `specs/todo/` ;
2. « Ce qui reste en suspens » des contrats de `specs/` ;
3. les tickets, lots et feuille de route décrits par le projet (`.ia/context/project.md`
   dit où ils vivent).

Entre deux travaux, prendre d'abord ce qui **débloque** d'autres tâches, puis ce qui
sert l'objectif en cours, ce qui réduit un risque réel, ce qui **termine** une
fonctionnalité — le confort en dernier. Une fonctionnalité finie vaut mieux que trois
commencées.

Paralléliser ce qui a des périmètres de fichiers disjoints (sous-agents, worktrees,
selon `bza:lead`). Un blocage local ne suspend que les tâches qui en dépendent.

## 4. Décider seul

Entre plusieurs solutions raisonnables, retenir dans cet ordre : la plus simple à
comprendre, la plus maintenable, celle qui ajoute le moins de complexité, celle qui
suit le mieux l'existant, celle qui ajoute le moins de dépendances et de mécanismes
spécifiques.

**Migrations** : colonnes nullables ou avec un défaut sûr, nouvelles tables, retour
arrière renseigné, une migration par sujet. Pas de suppression de colonne ou de
données, pas de conversion irréversible, pas de contrainte qui invaliderait des
données existantes — si une telle transformation devient nécessaire, chercher une
voie progressive, sinon la laisser à l'humain (§5).

Un défaut découvert en route se corrige s'il bloque le travail ou présente un risque
immédiat ; sinon il se note au bilan. Un échec n'arrête pas une tâche : chercher la
cause, essayer les alternatives pertinentes, décider, vérifier, continuer.

## 5. Ce qui attend l'humain

Ne se décide pas la nuit, même avec un défaut : suppression massive ou irréversible de
données · destruction d'un environnement · secrets et credentials · action
irréversible sur un système externe · changement fonctionnel majeur non prévu ·
refonte d'architecture sans rapport direct avec l'objectif · risque sur la production
· parité visuelle d'une migration hors seuil sans cause établie.

Le point se documente précisément (constat, options, recommandation), la tâche se
bloque, et tout ce qui n'en dépend pas continue.

## 6. Terminé veut dire vérifié — le bilan

« Terminé », « testé », « conforme » se vérifient sur le disque : tests, lint, analyse
statique, migrations, chemins fonctionnels principaux. Commits propres, un par unité
logique, par chemin, jamais sur un état cassé quand on peut l'éviter.

`.ia/runs/nuit-AAAA-MM-JJ/BILAN.md`, **mis à jour et commité à chaque clôture de
tâche** : la session peut s'arrêter à tout moment (Mac en veille, limite d'usage), le
bilan doit être lisible à tout moment.

```
# Nuit du AAAA-MM-JJ — <projet>
Branche : nuit/AAAA-MM-JJ (depuis <branche>@<sha>)
État : terminée | terminée avec réserves | interrompue

## Ce qui attend votre attention       ← en tête : réserves, blocages, défauts appliqués
## Fait                                ← par demande : ce qui est fini, preuves, commits
## Reste à faire
## Décidé seul                         ← décisions et leur motif
## Défauts trouvés                     ← corrigés, ou notés
```

Concis : l'humain doit savoir en deux minutes ce qui est réellement fini, ce qui
reste, et ce qui demande son attention. La nuit n'est pas « réussie » s'il reste une
question sans réponse : elle est « terminée avec réserves », et les réserves sont en
tête.

Au matin, une rétrospective de la nuit (`/bza:retro`, lancée par l'humain sur la
session de nuit) transforme les réserves répétées en garde-fous ou en règles.

## Lancer une nuit (pour l'humain)

- **Tâche planifiée de l'app Claude** (recommandé) : dans le dossier du projet, le
  soir, avec pour consigne `/bza:nuit`. Elle tourne sur le Mac : le code client ne
  quitte pas le poste. Le Mac doit rester allumé et éveillé.
- **À la main** : `/bza:nuit` dans une session laissée ouverte.
- **Permissions** : sans humain, la session doit pouvoir éditer et lancer des
  commandes sans confirmation. Les lois, les réglages de l'organisation et le
  garde-fou `bash-guard` continuent de s'appliquer dans ce mode.
- **À éviter** : les tâches dans le cloud — le code client y part chez Anthropic.
