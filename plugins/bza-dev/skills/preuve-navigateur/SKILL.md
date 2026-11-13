---
name: preuve-navigateur
description: Ce qui constitue une preuve de comportement en navigateur — livrable, assertion, isolation, pièges.
---

## Quand utiliser ce skill
Dès qu'une tâche demande de prouver un **comportement** observable dans le
navigateur : bandeau, blocage, rendu conditionnel, redirection, état d'un
formulaire, chargement d'un visuel.

Application directe de `bza:lois/preuve.md` au navigateur.

## Le livrable

Un **spec versionné dans le répertoire de tests E2E du projet**, nommé de façon
cohérente avec ses voisins, et **réellement exécuté jusqu'au vert**.

Ce qui n'est pas un livrable : un script jeté dans `/tmp`, une session de
navigateur pilotée à la main, une capture d'écran seule, un compte rendu de ce
qu'on a vu à l'écran. Ces gestes sont **légitimes pour explorer** — trouver le
flux, les sélecteurs, la cause — jamais pour prouver.

## Les quatre exigences

1. **Assertion identifiante** — porter sur le **texte réel attendu**
   (`toHaveText(libellé)`), jamais sur la seule présence ou visibilité. Un test
   qui passerait avec un libellé vide ne prouve rien.
2. **Auto-suffisance** — le spec pose son propre état de départ par les chemins
   applicatifs (interface, administration), **jamais par écriture SQL directe**
   de la configuration testée, et le défait dans un hook de fin qui s'exécute
   **même en cas d'échec ou de timeout**. Aucune préparation manuelle de la base
   ne doit être nécessaire pour rejouer le test.
3. **Artefact durable** — produire une capture à un chemin stable et explicite,
   même quand le test passe. Une configuration en `only-on-failure` ne laisse
   aucune trace d'un succès.
4. **Exécution réelle** — lancer le spec et vérifier qu'il passe avant de le
   rapporter. L'écrire et supposer qu'il fonctionnerait n'est pas une preuve.

## Pièges récurrents

- **Préfixe de locale et `baseURL`** — sur une application préfixée
  (`/fr/`, `/en/`), un `goto('/chemin')` à slash initial **écrase** le préfixe
  porté par le `baseURL` et produit un 404 silencieux. Naviguer en relatif, ou
  reconstruire l'URL complète.
- **Chargement différé par `IntersectionObserver`** — `scrollIntoViewIfNeeded()`
  ne déclenche pas fiablement l'observateur d'une bibliothèque tierce : le
  scroll programmatique n'est pas vu comme un geste utilisateur. Utiliser un
  scroll simulé (`page.mouse.wheel(0, ~250)`) **en plusieurs petits pas**.
  Tant que ce scroll n'a pas été essayé, un contenu lazy absent n'est **pas**
  un défaut produit.
- **Trois façons de référencer une image** — attribut `src`, URI `data:` inline,
  et **injection par JavaScript à l'exécution**. Un audit qui n'en connaît
  qu'une est borgne : chercher les trois avant de conclure qu'un visuel est en
  place.

## Règles absolues
- Le livrable est le spec versionné, jamais le script d'exploration
- Assertion sur le contenu attendu, jamais sur la présence seule
- Nettoyage dans un hook qui s'exécute même en cas d'échec
- Spec exécuté et vert avant d'être rapporté
- Un contenu lazy absent n'est un défaut qu'après un scroll simulé réaliste
