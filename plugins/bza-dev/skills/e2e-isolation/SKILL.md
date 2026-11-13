---
name: e2e-isolation
description: Isoler l'environnement des tests E2E — application, base, stockage et fixtures dédiés.
---

## Quand utiliser ce skill
Quand un projet reçoit ses premiers tests E2E, et au début de **chaque** run E2E.
C'est la doctrine partagée entre le `tester` (qui la fait respecter) et
le `devops` (qui fournit l'environnement).

## Le principe
> Les tests automatisés construisent leur propre monde, le testent, puis le
> jettent entièrement. Ils ne nettoient jamais le monde du développeur.

La frontière est **l'environnement**, jamais un marqueur posé dans les tables
métier (`is_test_data`, `test_run_id`) ni une heuristique de nettoyage. Un test
qui doit deviner quelles lignes lui appartiennent a déjà perdu : il finira par se
tromper sur une ligne du développeur.

Corollaire : l'environnement E2E est **jetable**. Il doit pouvoir être détruit et
reconstruit sans aucune validation humaine — c'est ce qui rend le reset banal, et
donc systématique.

## Constat d'isolation
Six points, réponse binaire. **Un seul « non » ⇒ NON ISOLÉ.**

1. L'application E2E a sa propre URL, distincte de celle du développeur.
2. Elle a sa propre base, au nom explicite (`..._e2e`), distincte de la base de dev.
3. Son environnement (`APP_ENV` ou équivalent) est fixé **au démarrage du
   processus**. Ni un header HTTP, ni un nom d'hôte, ni un paramètre de requête ne
   peuvent faire basculer l'application d'une base à l'autre.
4. Le reset destructif est autorisé sur cette base **et refusé partout ailleurs** —
   garde-fou vérifié, pas supposé.
5. Un seed déterministe reconstruit l'état commun, avec des clés métier stables.
6. Si des scénarios manipulent des fichiers, le stockage E2E est distinct de celui
   du dev.

Verdict `NON ISOLÉ` : aucun test n'est écrit, aucun test n'est lancé. Le manque est
remonté tel quel — la liste des points en échec est le cahier des charges.

## Contrat d'infra : `infra_e2e`
L'environnement est décrit une fois en mémoire (`infra_e2e`), sous des noms figés — le
tester et le devops les lisent tels quels.

```json
{
  "base_url": "http://localhost:8081",
  "app_env": "e2e",
  "database": "db_e2e",
  "storage": "storage/app/e2e",
  "reset_command": "ddev exec -s web-e2e php artisan e2e:reset",
  "seed_command": "ddev exec -s web-e2e php artisan db:seed --class=E2eSeeder",
  "run_command": "ddev test-e2e",
  "garde_fous": [
    "refus si APP_ENV != e2e",
    "refus si DB_DATABASE != db_e2e"
  ],
  "temoins": {
    "base": "<comment poser et relire le témoin en base de dev>",
    "fichier": "<chemin du témoin dans le stockage de dev>"
  }
}
```

Un champ absent signifie « non fourni », jamais « pas nécessaire ».

## Qui produit quoi

| Livrable | Profil |
|---|---|
| Second environnement applicatif (URL, processus, base, stockage), commande unique `test-e2e`, mémoire `infra_e2e` | `devops` |
| Commande de reset gardée (`APP_ENV` + nom de base vérifiés) et seeder déterministe | l'agent d'implémentation de la stack (ex. `backend-laravel`), sur tâche dispatchée |
| Constat d'isolation, fixtures de scénario, tests, preuves négatives | `tester` |

Le tester ne construit pas l'infrastructure et ne touche pas au code applicatif :
il constate, refuse, et dit précisément ce qui manque.

## Seed et fixtures
- Le seed porte l'état **commun** : utilisateurs, rôles, permissions, données de
  référence, et les relations qui les lient. Une relation nécessaire au scénario
  est créée par le seed ou la fixture — jamais empruntée à la base de dev.
- Les objets se retrouvent par **clé métier stable et explicite**
  (`e2e-client-alpha@example.test`, `e2e-site-main`), jamais par un identifiant
  numérique supposé (`client_id = 4`).
- Chaque scénario reçoit le **chemin** de sa fixture. Jamais de découverte : pas de
  glob, pas de « dernier fichier du jour », pas de « fichier présent dans le
  répertoire d'import ». Sinon un test finira par consommer le fichier qu'un
  développeur venait de déposer.
- Une fixture est fictive, petite, versionnée et stable.

## Importeurs et connecteurs
Deux usages qu'on ne mélange pas :
- **tester l'importeur** — fixture fictive → importeur → base E2E → assertions. C'est
  le test automatisé.
- **valider un connecteur réel** — API réelle → connecteur → base de dev. C'est du
  travail de recette manuelle, hors suite standard.

Aucune suite E2E standard n'appelle une source externe réelle.

## Preuves négatives
Les garde-fous se prouvent, ils ne se déclarent pas. Trois témoins, à rejouer à
chaque fois que la chaîne E2E change :

1. **Refus du reset** — lancer le reset avec l'environnement de dev
   (`APP_ENV=local`, base de dev). Attendu : refus, sans aucune écriture.
2. **Témoin fichier** — déposer un fichier dans le stockage de dev, lancer toute la
   suite. Attendu : fichier présent et inchangé.
3. **Témoin base** — créer une donnée en base de dev, lancer toute la suite.
   Attendu : donnée strictement inchangée.

Et une preuve de reproductibilité : deux runs consécutifs depuis un reset donnent
le même résultat.

## Exécution parallèle
Si plusieurs workers sont nécessaires : **une base par worker**
(`db_e2e_1`, `db_e2e_2`…). Le préfixage des fixtures par identifiant de run reste
possible mais ne s'introduit que si le parallélisme l'impose réellement — c'est un
retour du marquage ligne à ligne, avec ses erreurs.

## Anti-patterns
- Playwright pointé sur l'application de développement.
- Une suite qui modifie un `.env` partagé puis tente de le restaurer.
- Un header ou un nom d'hôte qui choisit la base côté serveur.
- `DELETE WHERE name LIKE 'Test%'`, `DELETE WHERE import_id IS NULL`,
  « tous les fichiers du jour ».
- `ID 4 supposé existant`, « premier enregistrement disponible ».

## Règles absolues
- Constat `NON ISOLÉ` ⇒ aucun test lancé, aucune exception.
- Le reset détruit un environnement, il ne trie jamais des lignes.
- Une fixture est déclarée par son chemin, jamais découverte.
- Un run E2E qui n'a pas laissé les témoins de dev intacts est un incident, pas un
  échec de test.
