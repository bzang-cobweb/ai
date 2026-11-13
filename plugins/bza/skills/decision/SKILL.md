---
name: decision
description: Consigner une décision, un risque assumé, une conséquence de conception ou une règle de blocage dans le registre .ia/context/decisions/ du projet. À utiliser dès qu'un humain tranche un arbitrage, qu'un risque est accepté en connaissance de cause, ou qu'une règle de blocage est posée ou levée.
---

# Consigner une décision

Une réponse humaine qui ne vit que dans le chat se perd, et la question est
reposée. **Toute réponse à un arbitrage se consigne dans la session où elle
arrive.** La règle complète : `bza:lois/escalade.md`, §3 à §5.

## Où

`.ia/context/decisions/AAAA-MM-JJ-<sujet-court>.md` — **un fichier par entrée**.
Si `.ia/` n'existe pas encore dans un dépôt git, le créer d'abord
(`bza:projet-init`), sauf si un fichier `.ia-ignore` est présent à la racine.

## Comment

1. Vérifier qu'aucune entrée active ne tranche déjà le point (lire le
   répertoire). Si oui, ne rien créer.
2. Choisir le type et copier son modèle depuis `.ia/context/decisions.md`
   (à défaut, depuis [modeles.md](modeles.md)).
3. Remplir chaque champ. **Motif**, **Portée** et **Corollaires** ne sont pas
   optionnels : ce sont eux qui disent quand la décision expire.
4. Remplacer une décision existante : **nouveau fichier** avec
   `Remplace : AAAA-MM-JJ-<sujet>.md` en tête, et ajouter une seule ligne en tête
   de l'ancien : `Remplacée par : AAAA-MM-JJ-<sujet>.md`. Ne jamais réécrire
   l'entrée d'un autre.
5. Commiter le fichier seul, par son chemin :
   ```
   git add -- .ia/context/decisions/<fichier>.md
   git commit -m "Décision : <titre court>" -- .ia/context/decisions/<fichier>.md
   ```
   Dans une session avec un humain, présenter le commit et attendre son accord.

## Règles absolues

- Une entrée, un fichier ; jamais d'index tenu à la main
- On ne modifie jamais l'entrée d'un autre : on la remplace
- Un point inscrit au registre ne se re-signale pas
