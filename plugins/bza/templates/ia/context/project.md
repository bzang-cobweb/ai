# Contexte projet

> À compléter à la création du `.ia/` (skill `bza:projet-init`) : objectif du projet, stack technique,
> conventions locales, liens utiles.

Ce fichier est **lu au démarrage par tous les agents**. Une affirmation fausse
ici se propage dans toute la documentation produite et n'est jamais rattrapée :
elle est réputée vraie par construction.

- **Propriétaire** : <qui corrige ce fichier — sans nom, personne ne le corrige>
- **Toute affirmation de stack cite sa preuve** (`composer.lock:14`,
  `package.json:22`) — jamais de version ni de composant écrit de mémoire.
- **Vérification d'ouverture de run** : l'orchestrateur confronte trois
  affirmations de ce fichier au disque avant tout dispatch. Cinq minutes.

## Projet

- **Nom** :
- **Type** :
- **Description** :

## Stack technique

> Format : `affirmation` — *preuve* (fichier:ligne, ou commande et son résultat)

- **Langage / framework** :
- **Base de données** :
- **Environnement local** :
- **CI/CD** :

## Environnement — comment on exécute ici

> Section à remplir dès le premier blocage résolu. Elle existe parce que les
> pertes de temps les plus coûteuses n'ont ni le code ni l'outil pour cause,
> mais **la façon dont la commande a été lancée**.

- **Chemin d'invocation canonique** : <depuis quel répertoire les commandes
  d'environnement doivent être lancées — un lien symbolique ou un second chemin
  vers le même arbre peut faire échouer un outil qui a enregistré le projet
  sous l'autre>
- **Où se lancent les commandes** : <host ou conteneur, par outil — un
  gestionnaire de paquets exécuté du mauvais côté peut mutiler un lockfile ou
  installer des binaires natifs pour la mauvaise plateforme>
- **Commandes de vérification** : <ce qui prouve que l'environnement est sain>
- **Faux positifs connus** : <les échecs qui n'en sont pas — voir la propriété
  « fraîche » de `bza:lois/preuve.md`>
- **Consignes d'erreur à ne PAS suivre** : <messages d'outils dont la
  remédiation affichée est destructrice dans ce projet>

## Conventions

- À documenter au fur et à mesure du projet.

## Décisions

Les arbitrages tranchés sont dans `.ia/context/decisions/`, un fichier par
entrée (voir `.ia/context/decisions.md`) — **pas ici, et jamais uniquement dans
une messagerie.**

## Liens utiles

- Repo :
- Documentation :
- Staging :
- Production :
