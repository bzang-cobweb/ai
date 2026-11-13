---
name: audit-laravel
description: Schéma d'extraction Laravel/DB pour la section `stack` d'une spec d'audit.
---

## Quand utiliser ce skill
Quand l'auditor audite un concept sur un projet Laravel ou PHP data-centric.
Ce skill remplit la section `stack` de l'enveloppe définie par `audit-source` —
il ne la remplace pas.

## Section `stack` — schéma d'extraction

### Schéma DB
- Nom exact de la table
- Chaque colonne : nom exact (casse comprise), type, nullable, défaut, valeurs d'enum

### Routes
- Pour chaque action de `fonctionnalites` : méthode HTTP, paramètres, comportement

### Dépendances
- Tables jointes, services externes (mail, upload, PDF...)

## Format

```json
"stack": {
  "table": "organisations",
  "colonnes": [
    {
      "nom": "Statut_Rapport",
      "type": "enum",
      "values": ["non_demarre", "en_cours", "valide"],
      "nullable": false,
      "default": "non_demarre"
    }
  ],
  "routes": {
    "export": { "methode": "GET", "parametres": ["format"], "comportement": "..." }
  },
  "dependances": ["organisations", "coaches"]
}
```

## Règles absolues
- Noms de colonnes et valeurs d'enum copiés depuis la source, casse comprise
- Un défaut ou un nullable non trouvé dans la source → entrée dans
  `incertitudes` de l'enveloppe, jamais de valeur devinée
