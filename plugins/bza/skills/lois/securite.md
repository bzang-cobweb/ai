---
apply: always
---

# Règle sécurité : secrets et données confidentielles

## La règle

**Aucun credential, secret ou donnée confidentielle n'est jamais exposé en clair.**

- ❌ Jamais de secret écrit dans le code, un commit, un dépôt ou un fichier versionné
- ❌ Jamais de fichier `.env` contenant des secrets dans git
- ❌ Jamais de credential brut partagé avec une IA, collé dans une conversation ou un ticket
- ❌ Jamais de secret dans un log, une sortie de commande ou un message d'erreur
- ✅ Toujours un gestionnaire de mots de passe, des variables d'environnement ou les
  secrets de la CI

## Ce qui est protégé

| Catégorie | Exemples |
|---|---|
| Hébergement et infrastructure | accès serveurs, clés SSH, clés d'API de l'hébergeur |
| Clients | credentials propres à un client, données personnelles, données métier sensibles |
| Authentification | jetons OAuth/OIDC, secrets clients, clés de signature (JWT) |
| APIs externes | paiement, stockage, cartographie, envoi d'e-mails |
| Bases de données | utilisateurs et mots de passe MySQL/MariaDB, Redis, Solr |
| Déploiement et CI/CD | variables sécurisées du pipeline, clés de déploiement, URLs de déclenchement à jeton |

## Où vit un secret

1. **Gestionnaire de mots de passe** (1Password ou équivalent) : la source de vérité,
   partagée par projet ou par équipe.
2. **Variables d'environnement** : `.env` local, toujours dans `.gitignore`. Les
   variables requises se documentent dans `.env.example`, **sans valeur**. Un `.env`
   se manipule par l'outil `bza:env`, qui ne montre que les noms.
3. **Secrets de la CI** : variables sécurisées du pipeline, injectées à l'exécution.
   Jamais `echo $SECRET`, même pour déboguer.

## Dans le code

```php
// ❌ Un secret écrit en dur
$apiKey = '<la clé écrite en clair>';

// ✅ Lu depuis la configuration, elle-même alimentée par l'environnement
$apiKey = config('services.stripe.secret'); // config/services.php : env('STRIPE_SECRET')
```

- Une variable requise et absente fait échouer le démarrage explicitement, plutôt que
  d'envoyer une valeur vide.
- Aucun secret dans un log, même partiellement : ni `Log::info("clé : $key")`, ni une
  exception qui l'embarque.
- Un jeton dans une URL (webhook, déclenchement de déploiement) est un secret : il
  vit dans une variable sécurisée, pas dans un fichier versionné.

## Avec une IA

- Remplacer chaque valeur sensible par sa variable (`env('DB_PASSWORD')`) avant de
  partager un extrait de code.
- Un agent qui voit un secret en clair le signale, ne le recopie nulle part et
  recommande sa rotation.
- Une IA ne lit pas un `.env` : elle passe par `bza:env`.

## Avant chaque commit

- [ ] Aucun secret ni mot-clé sensible avec une valeur réelle dans le diff
      (`git diff --cached`)
- [ ] `.env`, `.env.local` et équivalents dans `.gitignore`
- [ ] Aucun secret dans un message de commit, une description de PR ou un ticket
- [ ] Un scanner de secrets tourne en CI (gitleaks, TruffleHog…) quand le projet en a un

## Si un secret a fui

1. Arrêter tout déploiement en cours.
2. **Révoquer et remplacer le secret** chez son fournisseur, puis dans le gestionnaire
   de mots de passe : une fuite se traite par rotation, jamais en supprimant seulement
   le fichier.
3. Prévenir le responsable du projet.
4. Nettoyer l'historique git si le secret y est entré : c'est une réécriture
   d'historique, donc une décision humaine (`git.md`).
5. Consigner l'incident dans le registre des décisions du projet (`bza:decision`).

**Cette règle est absolue et s'applique sans exception.**
