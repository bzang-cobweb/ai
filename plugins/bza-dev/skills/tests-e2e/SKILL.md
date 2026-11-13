---
name: tests-e2e
description: Écrire et exécuter des tests E2E Playwright à partir des specs d'audit, sur un environnement de test isolé du développement. À utiliser pour couvrir des fonctionnalités et des contrôles d'accès par des tests de bout en bout.
---

# Tests E2E

Produire des tests E2E couvrant les fonctionnalités et les règles d'accès
définies dans la spec. Ne jamais tester ce qui n'est pas dans la spec — ni plus,
ni moins.

Avant de tester quoi que ce soit, s'assurer que la suite a **son propre monde** :
sa base, son URL, son stockage. Un test qui tourne sur l'environnement du
développeur n'est pas un test, c'est un incident en attente.

## Phase 0 — l'environnement (une fois par projet, revérifié à chaque chantier)
1. Lire `.ia/memory/infra_e2e.json` et appliquer le constat d'isolation de
   `bza-dev:e2e-isolation` (six points binaires).
2. Un seul point en échec → s'arrêter et remonter **les points en échec et eux
   seuls** : c'est le cahier des charges de l'environnement (`bza-sysadmin:ddev`)
   et de la stack (commande de reset gardée, seeder déterministe). **Ne rien
   écrire, ne rien lancer.**
3. Constat `ISOLÉ` → vérifier que la config Playwright utilise `base_url` de
   `infra_e2e`, et rien d'autre.
4. Poser les témoins de dev (base + fichier) avant la première suite.

## Phase 1 — les tests
5. Lire `.ia/memory/spec_<concept>.json` : `fonctionnalites`, `acces`,
   `regles_metier`. Absente → la produire d'abord (`bza-dev:auditor`).
6. Créer le fichier de test dans le dossier `e2e/` du projet :
   `e2e/<composant-ou-parcours>.spec.ts`, selon les règles de `bza-dev:playwright`.
7. Pour chaque fonctionnalité : un `test()` avec les assertions suffisantes.
8. Pour chaque rôle de `acces` : un test d'accès (succès ou 403 selon le rôle).
9. Lancer la chaîne complète via `run_command` de `infra_e2e` (reset →
   migrations → seed → fixtures → tests).
10. Corriger les erreurs techniques (sélecteurs, timing) ; rapporter les vrais
    échecs fonctionnels sans toucher au code source.
11. Relire les témoins de dev : intacts, sinon **incident** avant tout rapport.

## Format du rapport
```
RAPPORT TESTS — <concept>
Isolation : ISOLÉ (base <db>, url <base_url>)
Témoins dev : intacts / VIOLÉS
Passés : <n> / <total>
Échecs fonctionnels : <n>
- <test> — <description de l'échec>
Erreurs techniques : <n> (corrigées avant rapport)
```

## Règles absolues
- Un test ne teste qu'une seule chose
- **Assertion identifiante** : sur le contenu attendu, jamais sur la présence
  seule — un test qui passerait avec un libellé vide ne prouve rien
- **Un spec pose son propre état de départ et le défait** dans un hook qui
  s'exécute même en cas d'échec ou de timeout
- **Relancer une fois** avant de conclure à une régression
- Ne jamais modifier le code source pour faire passer un test
- **Ne jamais pointer Playwright sur l'application de développement**
- **Ne jamais nettoyer par heuristique** (glob, `LIKE 'Test%'`, « fichiers du
  jour ») : on jette un environnement, on ne trie pas des lignes
- Ne jamais modifier un `.env` partagé ni choisir l'environnement par header HTTP
- Aucune source externe réelle dans la suite standard — fixtures déterministes
- Un vrai échec fonctionnel se rapporte et le test reste rouge
- Pas de `done` avec des tests fonctionnels en échec ou un témoin de dev qui a bougé
