---
name: rapport-de-tache
description: Enveloppe commune du rapport de complétion, point d'étape, extension de périmètre — tous profils d'exécution.
---

## Quand utiliser ce skill
À chaque tâche reçue, du début à la clôture. Ce skill n'est pas un format de
rédaction : c'est ce qui rend le travail d'un agent lisible par les autres.

## Avant d'écrire la première ligne — situer le correctif

Un défaut se manifeste à un endroit. La règle qu'il viole vit peut-être
ailleurs, ou nulle part, ou partout. **Corriger là où ça fait mal sans le
savoir est la manière normale de dégrader un code propre.**

Avant toute modification, répondre par écrit à deux questions :

1. **De quelle règle générale ce défaut est-il un cas particulier ?**
2. **Où cette règle est-elle écrite — et combien de fois ?**

La seconde se répond par un **balayage du concept**, jamais de mémoire et
jamais en suivant les seuls appels que la tâche cite : chercher le concept
lui-même dans tout le code applicatif. Une commande, trente secondes.
Le corollaire sur les angles morts d'un relevé s'applique ici en entier — voir
plus bas : la méthode qui trouve un mécanisme ne voit pas les autres.

### Trois résultats, trois conduites

| Le balayage trouve | Conduite |
|---|---|
| **Un seul endroit** | Corriger là. C'est le cas normal, et il n'appelle rien de plus. |
| **Aucun endroit** — la règle est implicite | Corriger au plus près, **et le dire** : la règle n'a pas de domicile. |
| **Plusieurs endroits qui se contredisent** | ⛔ **Ne pas écrire le énième.** Bloquer, joindre le relevé, demander où poser la règle. |

Seul le troisième cas interdit d'agir — et c'est le seul qui compte. Ajouter
une implémentation de plus à une règle déjà éclatée **aggrave le défaut tout en
fermant le ticket** : le correctif a l'air juste, la revue passe, le code
empire. C'est le seul type de travail qui recule en ayant l'air d'avancer.

**Plusieurs endroits *cohérents* ne bloquent pas** — ils se signalent, et le
travail continue. Ce qui bloque, c'est la contradiction. Une règle qui ferait
bloquer sur la simple multiplicité serait désactivée en trois jours, et elle
l'aurait mérité.

Le blocage coûte peu : un relevé et une question. Il s'inscrit dans le format
d'escalade — constat, options, recommandation, défaut applicable sans réponse.

## Pendant la tâche

### Point d'étape à mi-parcours — spontané
Dès qu'une tâche dépasse ~1 à 2 h de travail actif, envoyer un **Point d'étape**
**sans qu'on ait à le demander**. Trois lignes suffisent : ce qui est vert, ce
qui est rouge, ce qui ralentit.

Personne ne peut répondre à des heures de silence sur une tâche qui gate une
phase entière — et une tâche muette est indistinguable d'une tâche morte.

### Relire les messages à mi-parcours — la contrepartie du point d'étape

Le point d'étape ci-dessus est **sortant**. Il a une contrepartie **entrante**,
et elle est tout aussi obligatoire : **au même moment, Lire les messages.**
En mode local, un sous-agent ne reçoit rien en cours de tâche : c'est
l'orchestrateur qui l'arrête et le relance avec la nouvelle consigne
(`bza:lead`) — la règle qui suit reste la sienne.

Une consigne peut changer *pendant* qu'on travaille. Le ticket qu'on a lu au
départ n'est pas forcément celui qui fait foi à l'arrivée.

**Cas mesuré, 07.09.2026** — un agent a passé une tâche longue sans relire son
inbox. Pendant ce temps, deux messages lui demandaient d'arrêter une manœuvre
précise ; il a continué et abîmé un artefact partagé, puis a dû tout reprendre
après coup. *« Je ne relis l'inbox qu'au réveil, pas en cours de tâche longue,
et j'aurais dû. »* Le même jour, une consigne a été annulée **une minute**
avant qu'un autre agent ne rende son travail.

**Ce que ça implique concrètement :**

- Relire **sans filtre de date**, et lire le **corps complet** des messages —
  un objet de message ne dit pas si la consigne a changé.
- Une consigne reçue en cours de route **prime sur le ticket d'origine**.
- Si un message contredit ce qu'on est en train de faire : **s'arrêter, puis
  répondre**. Pas l'inverse.

Ce n'est pas une question de discipline individuelle : sur un arbre partagé,
un agent qui n'écoute pas pendant qu'il écrit est indiscernable d'un agent qui
part dans le mur.

### Un ticket conditionné s'écrit pour rester vrai après sa promotion

*(à l'usage de qui **rédige** les tickets — lead)*

Un ticket mis en attente porte souvent son avertissement en tête de corps :
« ⚠️ BACKLOG — non réclamable, ne pas s'auto-assigner ». **La promotion change
le statut, jamais le corps.** L'avertissement survit donc à sa propre péremption
et dit l'inverse de l'état réel.

Ce n'est pas anodin : `escalade.md` §6 demande à un agent de ne pas
s'auto-assigner. Face à un statut `pending` et à un texte « ne pas
s'auto-assigner », **le texte gagne** — et le ticket dort.

**Écrire la condition sous une forme qui reste vraie dans les deux états :**

```
⏳ Conditionné à <X>.
> Si tu lis ce ticket en `pending`, la condition est remplie : il est réclamable.
```

Et **coupler le geste** : promouvoir *et* réécrire l'en-tête, dans le même
mouvement. Promouvoir seul est un demi-geste.

> Constaté le 07.09.2026 par `auditor` sur quatre tickets d'un coup, puis
> **refait par le lead une heure après l'avoir corrigé** — d'où la
> formulation défensive plutôt que la consigne de vigilance. Une règle qui
> repose sur le fait de penser à quelque chose se re-viole.

### Extension de périmètre — demander AVANT, pas rapporter APRÈS
Quand la tâche annonce un périmètre de fichiers et qu'un correctif semble
exiger d'en sortir : **bloquer, demander l'extension, puis continuer**. Jamais
modifier silencieusement le fichier hors périmètre, même si le correctif est
nécessaire, propre, additif et sans impact connu.

L'extension est accordée en trente secondes. Le débordement silencieux, lui,
est exactement le mécanisme par lequel deux agents s'écrasent sans que personne
ne le voie.

### Ne jamais régresser un contenu réel
Quand une tâche demande d'harmoniser plusieurs emplacements avec un composant
générique, **ne jamais déréférencer un contenu réel déjà livré** (image, texte,
composant) au profit d'un placeholder, même en documentant l'arbitrage.

Le principe : **le composant gouverne le slot** (dimensions, ratio, point
d'accroche), **le slot porte le vrai visuel**. Le générique enveloppe
l'existant, il ne le remplace pas. Si la tension est réelle, la signaler et
laisser arbitrer **avant** d'agir.

### Lire une spec au pied de la lettre
Quand une spec énumère deux listes séparément dans le même ordre, les apparier
**positionnellement** — premier élément de la première liste avec premier
élément de la seconde — jamais par heuristique de bon sens. C'est la seule
lecture qui donne un sens au fait que la spec ait pris la peine de les ordonner.

Quand un critère d'acceptation nomme un mécanisme (un fichier, un import, un
nombre d'occurrences) alors que la spec vise un but : **tenir le but, signaler
l'écart de lettre**. Un critère qui décrit une implémentation plutôt qu'un état
observable est souvent le fautif.

## À la clôture — l'enveloppe du rapport

```
RAPPORT — <tâche>
Livrable      : <ce qui a été produit>
Preuve        : <chemin du fichier rejouable + comment la relancer>
Périmètre     : <fichiers réellement touchés>
Déplacements  : <tout fichier déplacé/renommé/créé hors édition, ou « aucun »>
Non couvert   : <ce que la preuve ne prouve pas>
Effets de bord: <ou « aucun »>
Règle générale: <de quelle règle ce cas est un cas particulier, et OÙ elle est écrite>
Reste ouvert  : <ou « rien »>
```

### « Règle générale » — pourquoi la ligne existe

**Une ligne, obligatoire :** *de quelle règle générale ce bug est-il un cas
particulier, et **où cette règle est-elle écrite** ?*

**Si la réponse est « nulle part », le ticket engendre un ticket de
domiciliation avant d'être clos.** La correction reste valide ; c'est la règle
qui n'a pas encore d'adresse.

Le motif, mesuré le 07.09.2026 sur `is_admin` : **treize points de décision,
sept fichiers, trois règles incompatibles** — dont deux commentaires du même
dépôt qui se contredisaient en se présentant chacun comme la règle. À côté, les
capacités d'abonnement — fonctionnellement bien plus tordues — ont **une**
source de vérité et n'ont jamais été patchées endpoint par endpoint.

**Ce n'est pas de l'indiscipline** : un concept sans domicile se ré-implémente à
chaque rencontre. Remettez n'importe qui dans cette position, il corrigera là où
le symptôme se manifeste — c'est mécanique, et cette ligne est ce qui l'arrête.

⚠️ **Elle vaut aussi pour celui qui rédige le ticket**, pas seulement pour celui
qui l'exécute. C'est au moment de la rédaction qu'elle sert le plus.

### Corollaire — un relevé ne vaut que par ses angles morts

Quand une tâche demande d'**inventorier** les endroits où vit un concept :
**chercher ce qui est demandé ne dit rien de ce qui manque.**

Cas d'école du 07.09 : un relevé suit les `authorize()` → il manque
`EstimationResource`. Un second balaye `is_admin` → il manque
`ResponseResource`, qui écrit `isAdministrator()`. **Trois méthodes, trois
angles morts différents, un seul concept.**

Un même objet est référencé par plusieurs mécanismes, et la méthode qui en
trouve un ne voit pas les autres. Un relevé énonce donc **par quoi il a
cherché** — c'est la seule façon de savoir ce qu'il ne pouvait pas trouver.

### « Déplacements » — pourquoi la ligne existe
Un rapport factuellement vrai sur l'instant T mais muet sur le **chemin** qui y
a mené induit des décisions d'intégration erronées. Avant de conclure « X n'était
pas cassé » à partir d'un état de fichier actuel, vérifier si cet état résulte
d'un changement récent sur l'arbre partagé — et le nommer.

Cette ligne vaut particulièrement pour les fichiers **non suivis par git** :
aucun historique ne rattrapera un rapport incomplet.

### « Non couvert » — pourquoi la ligne existe
Tester ce qui est demandé ne dit rien de ce qui manque. Un rapport qui ne borne
pas sa preuve la fait lire comme exhaustive.

## Règles absolues
- Correctif **situé avant la première modification** : règle générale nommée,
  domicile relevé. Plusieurs domiciles **divergents** ⇒ bloquer et remonter le
  relevé, jamais écrire le énième
- Point d'étape spontané au-delà de ~1-2 h de travail actif
- **Messages relus au même moment**, sans filtre de date, corps complet — une
  consigne reçue en route prime sur le ticket d'origine
- Extension de périmètre demandée avant le premier octet écrit hors scope
- Aucun contenu réel remplacé par un placeholder sans arbitrage préalable
- Les sept lignes de l'enveloppe sont toutes renseignées, « aucun » compris
- « Règle générale » renseignée — réponse « nulle part » ⇒ ticket de
  domiciliation avant clôture. Vaut aussi pour qui **rédige** le ticket
- Un relevé énonce **par quel mécanisme il a cherché**, donc ce qu'il ne pouvait
  pas trouver
- Un échec fonctionnel réel se signale et reste rouge — jamais de code adapté
  pour faire passer une vérification
