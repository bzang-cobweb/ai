# Escalade et décisions

Le temps de l'humain est la ressource rare. Cette règle définit **quand** on le
sollicite, **sous quelle forme**, et **où atterrit sa réponse** pour ne jamais
avoir à la lui redemander.

## 1. Autonomie par défaut

Un agent tranche seul par défaut. Bloquer sur une décision technique ordinaire
coûte autant à l'équipe que trancher seul une vraie décision produit.

### Je tranche seul

Choix d'implémentation locaux · refactors nécessaires à la propreté ·
organisation des tests · **corrections évidentes qui rendent réellement
fonctionnelle une exigence déjà décidée** · problèmes d'outillage ou
d'environnement qui bloquent ou invalident les preuves de livraison.

Quand plusieurs solutions se valent, retenir celle qui maximise, **dans cet
ordre** : maintenabilité, sécurité, lisibilité, testabilité. Documenter
brièvement le choix, et continuer.

- **Maintenabilité** : pas de rustine à remplacer dans deux semaines ; contrats
  clairs entre composants ; ni abstraction prématurée, ni duplication.
- **Sécurité** : aucun élargissement silencieux de permissions, aucune donnée
  rendue accessible par commodité technique. **En cas de doute sur un
  comportement de sécurité : mesurer le chemin réel, jamais conclure par
  intuition.**

### Je remonte — et seulement ça

Comportement produit · conservation ou suppression de données · droits
utilisateurs · dépendance structurante · périmètre fonctionnel · engagement
client · décision difficilement réversible.

### Tri des défauts découverts en cours de route

- Empêche **réellement** la promesse fonctionnelle ou de sécurité du lot →
  traiter dans le lot.
- Amélioration souhaitable ou dette **sans impact immédiat** → documenter et
  continuer.

## 2. La forme d'une escalade

Une question à l'humain n'est jamais posée sans la matière pour y répondre :
**le contrat s'écrit d'abord, la demande de validation vient après.** Demander
de valider sans avoir donné quoi valider est une question perdue pour tout le
monde.

Toute escalade porte les cinq éléments suivants, dans cet ordre :

1. **Constat vérifié** — ce qui est établi, avec sa preuve (voir la règle de preuve)
2. **Options** — deux ou trois, pas un catalogue
3. **Recommandation** — une, assumée
4. **Défaut appliqué sans réponse sous N** — ce que je fais si personne ne répond
5. **Ce qui est bloqué en attendant** — et ce qui continue

Le point 4 est le plus important : il transforme une question bloquante en
question informative. Une escalade sans option par défaut immobilise l'équipe
sur l'agenda de quelqu'un d'autre.

**Groupage** : une salve d'arbitrages par cycle, priorisée. Pas de questions au
fil de l'eau.

## 3. Consigner la réponse — sinon elle n'existe pas

Une réponse humaine qui ne vit que dans une messagerie se perd, et la question
est reposée. Elle est alors payée deux fois par celui qui l'avait déjà tranchée.

**Toute réponse humaine à un arbitrage est consignée dans le registre versionné
du projet, dans le même cycle que sa réception.** L'accusé de réception est le
commit, pas un message.

### Une décision, un fichier

Le registre est le répertoire `.ia/context/decisions/`. Chaque entrée y est un
fichier `AAAA-MM-JJ-<sujet-court>.md`, créé par l'agent qui consigne. Plusieurs
agents qui consignent en parallèle écrivent donc des fichiers distincts : aucun
conflit de fusion, et aucune entrée effacée par la copie périmée d'un autre.

Une entrée consigne : son type (décision, risque assumé, conséquence de
conception, règle de blocage), la date, la question, la réponse, le motif, les
**corollaires**, la **portée**, et qui a tranché. Le modèle est dans
`.ia/context/decisions.md`.

- **On ne modifie jamais l'entrée d'un autre.** Une décision qui en change une
  autre est un **nouveau fichier** qui l'indique en tête
  (`Remplace : AAAA-MM-JJ-<sujet>.md`). L'ancien fichier reste intact, à une
  ligne près : `Remplacée par : AAAA-MM-JJ-<sujet>.md`, ajoutée en tête.
- **Lecture** : au démarrage, un agent lit **tous** les fichiers du répertoire.
  Une entrée marquée `Remplacée par` ne s'applique plus.
- `.ia/context/decisions.md` n'est plus écrit par les agents : il explique le
  registre et porte le modèle d'entrée. Un index éventuel est **généré**, jamais
  tenu à la main — un index manuel recrée le conflit que le répertoire évite.
- **Transition** : les entrées encore présentes dans `decisions.md` restent
  valables tant qu'elles n'ont pas été migrées en fichiers.

## 4. Ne jamais rouvrir ce qui est tranché

- Un point inscrit au registre (`.ia/context/decisions/`) **ne se re-signale pas** — ni comme défaut, ni
  comme question, ni « pour confirmation ». Un risque assumé mais non tracé se
  fait re-remonter à chaque audit.
- Une **conséquence de conception assumée** s'inscrit au registre au moment où
  elle est acceptée. Non écrite, elle se relira dans six mois comme un défaut à
  corriger.
- Un verdict d'autorité (go/no-go rendu par le contrôleur) ne se rouvre pas.

## 5. Les règles de blocage ont une durée de vie

Toute règle qui bloque ou sérialise du travail **porte son motif**, et est
réexaminée dès que ce motif tombe. Une règle de séquencement qui survit à sa
raison d'être immobilise l'équipe sans que personne ne sache plus pourquoi.

Quand un motif est réfuté, la levée est **inscrite explicitement** au registre,
par une nouvelle entrée qui remplace celle qui posait la règle : sans trace de
la levée, les agents réappliquent la règle depuis leurs mémoires.

## 6. Le repos est un état légitime

Un agent sans tâche attend. Il ne s'auto-assigne ni refactor, ni test, ni
documentation « pour occuper le temps ». Une équipe au repos qui se donne du
travail salit un lot que l'humain vient de figer.

## Règles absolues

- Avant de remonter une question, la confronter à la liste « je remonte ». Si
  elle n'y figure pas : trancher, documenter, continuer
- Jamais de demande de validation sans le contrat à valider
- Jamais d'escalade sans option par défaut applicable en l'absence de réponse
- Toute réponse humaine à un arbitrage est consignée dans un fichier du registre
  avant la fin du cycle
- On ne modifie jamais l'entrée d'un autre : on la remplace par une nouvelle
- Un point tranché ne se re-signale pas
- Un run ne se termine jamais « réussi » s'il reste des questions sans réponse
