---
name: migration
description: Mener la migration d'un site existant vers une nouvelle version ou une nouvelle base technique (CMS, framework, thème), à rendu identique et avec des données rejouables, de la mise en place au rapport de parité final. Indépendant de la technologie ; les gestes propres à chacune sont dans le plugin de sa stack (bza-laravel).
---

# Migrer un site

Faire passer un site existant (la **référence**) vers sa nouvelle version (la
**cible**) sans perte de contenu, de fonctionnalité ni de rendu : montée de
version d'un CMS sur plusieurs majeures, changement de framework, passage sur un
nouveau starter.

La migration traite **deux chantiers séparés** : le **code** (va directement à la
cible) et les **données** (traversent chaque version intermédiaire dans un
pipeline rejouable). On ne mélange jamais les deux.

## Phases
Une phase se termine par son livrable vérifié (`bza-dev:qa-check`), un bilan court, puis
le **go humain** avant la suivante. Les décisions de cadrage sont numérotées (Q1,
Q2…) dans `MIGRATION.md` et consignées au registre (`bza:decision`).

| Phase | Livrable | Critère de sortie |
|---|---|---|
| P0 Mise en place | référence et cible côte à côte, outil de parité installé, **référence capturée** | captures de référence complètes, pages en erreur notées |
| P1 Squelette cible | code cible qui démarre (dépendances résolues, structure du modèle de projet) | schéma généré sans erreur, site cible en 200 |
| P2 Données | `scripts/migration/run.sh <dump>` de bout en bout | rejoué sur base fraîche, contrôles à 0 anomalie |
| P3 Parité visuelle | rendu cible = référence | rapport de parité : chaque écart restant expliqué |
| P4 Fonctionnalités | formulaires, recherche, en-têtes de sécurité, mesure d'audience, tâches planifiées | chacun vérifié en conditions réelles, sinon réserve écrite |
| P5 Préproduction | déploiement de recette | recette client possible |
| P6 Capitalisation | skills mis à jour, propositions aux briques/thèmes/modèles | reversés ou listés |

## Démarche
- **Cadrer avant d'agir** : état des lieux (branches, travail antérieur, données
  hors dépôt), décisions structurantes posées à l'humain en un tour de questions
  avec recommandation.
- **Inventorier en base, pas dans le code** : usage réel de chaque type de
  contenu, champ et extension avant de décider de le migrer, le remplacer ou le
  supprimer.
- **Toute transformation de données dans le pipeline** (SQL ou commandes
  versionnés, rejouables sans effet de bord), jamais à la main dans une base.
- **Découper le travail par zones** (en-tête, pied de page, contenus,
  formulaires, recherche…) avec des fichiers propres à chaque zone créés
  d'avance, pour pouvoir avancer en parallèle sans conflit ; intégrer et
  commiter zone par zone.
- **Mesurer plutôt que supposer** : valeurs lues dans le CSS compilé de la
  référence, causes des écarts établies sur pièce.
- Méthode de comparaison, kit et rapport final : `bza-dev:visual-parity`.
- Règles front communes, à lire avant d'écrire du HTML, du SCSS ou du JS :
  `bza-dev:frontend`. Le rendu identique y prime sur les règles de structure.

## Règles absolues
- **La référence est en lecture seule** : jamais de modification de son code ni
  de sa base ; les dumps s'exportent en lecture seule. Une page en erreur sur la
  référence se documente, elle ne se « répare » pas.
- **La référence visuelle est capturée avant tout travail** et ne se recapture plus.
- **Aucune écriture en base hors du pipeline** : une restauration de dump efface
  sans bruit tout ce qui a été fait à la main.
- **Les données traversent chaque version majeure** dans sa propre instance ; les
  mises à jour automatiques (wizards, migrations) se lancent **une par une**,
  journalisées.
- **Rien de destructif avant la conversion** : les anciennes colonnes et tables
  restent lisibles tant que la conversion ne les a pas lues.
- **Nommer l'environnement visé** dans chaque commande ; ne jamais supprimer ni
  recréer un environnement ou un volume de données sans demande explicite.
- **Ne jamais qualifier un élément de mort sur simple lecture de code** :
  vérifier en base et dans le rendu.
- **Un élément manquant dans le catalogue partagé (brique, module) se construit
  comme un vrai paquet** réutilisable dans `packages/`, pas comme un bricolage
  propre au projet.
- **Garder le balisage du modèle de projet** ; une surcharge de gabarit n'est
  faite que si les styles ne peuvent pas reproduire la référence, et chaque
  surcharge est listée avec sa raison.
- **Secrets** : aucun dans les fichiers suivis ; ceux trouvés dans l'existant
  sont signalés (rotation à la bascule), jamais recopiés.
- **Rester léger** : un journal (`MIGRATION.md`), un bilan, des commits qui disent
  pourquoi ; pas de rapport qui duplique le code.
