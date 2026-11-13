---
name: generate-openapi
description: Produire et rafraîchir le contrat OpenAPI d'une API Laravel en le dérivant du code, jamais en le rédigeant.
---

## Quand utiliser ce skill
Quand le projet expose des routes HTTP consommées depuis l'extérieur, après
toute création ou modification de route, de FormRequest ou de Resource.

## Principe
Le contrat est **dérivé du code**, jamais écrit à la main. Un OpenAPI rédigé
manuellement est faux en quelques semaines, et personne ne s'en aperçoit tant
qu'un client ne casse pas. Si le contrat ne peut pas être généré, le problème
est dans le code (types manquants, validation implicite), pas dans la doc.

## Procédure
1. Identifier le générateur **déjà présent** dans `composer.json` :
   `dedoc/scramble`, `knuckleswtf/scribe`, `darkaonline/l5-swagger`,
   `vyuldashev/laravel-openapi`. Utiliser celui-là, quel qu'il soit.
2. Aucun générateur installé → **Écrire à** `lead` pour arbitrage,
   avec la recommandation `dedoc/scramble` : il dérive le contrat des types et
   des FormRequests sans annotations à maintenir, donc sans dérive possible.
   **Ne jamais installer une dépendance sans validation du lead.**
3. Lancer la commande de génération du paquet retenu et écrire la sortie dans
   `openapi.yaml` à la racine du projet.
4. Vérifier que chaque route exposée figure au contrat. Une route absente
   signale un endpoint que le générateur n'a pas pu typer : corriger le code
   (FormRequest, Resource, type de retour), pas le YAML.
5. Ne jamais éditer `openapi.yaml` à la main, même pour un détail.

## Règles absolues
- Un contrat édité manuellement est réputé faux — le régénérer
- `openapi.yaml` est versionné et régénéré à chaque changement de route
- Aucun exemple contenant une donnée réelle, un jeton ou une URL interne
- Le contrat décrit uniquement les routes réellement exposées — jamais une route prévue
