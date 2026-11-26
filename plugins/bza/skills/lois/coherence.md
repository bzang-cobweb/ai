# Cohérence du code

Une base de code ne se dégrade pas par gros gestes. Elle se dégrade par
**correctifs justes, posés au bon endroit du symptôme et au mauvais endroit de
la règle**. Chacun passe la revue. L'ensemble devient illisible.

Cette règle dit où poser un correctif. Elle complète `preuve.md`, qui dit
comment le prouver, et `escalade.md`, qui dit quand demander.

## 1. Une règle a un domicile, ou elle n'existe pas

**Un concept transverse — un droit, une capacité, une locale, un quota, un
format — a un point d'entrée unique.** Les autres fichiers y délèguent ; ils ne
le ré-implémentent pas.

Contrôle, en une commande : *« où est écrite la règle X ? »* doit avoir **une**
réponse-fichier. Plusieurs réponses divergentes ⇒ le concept n'a pas de
domicile, et chaque correctif futur en créera un de plus.

**Ce n'est pas un défaut de discipline.** Un concept sans domicile se
ré-implémente à chaque rencontre : placez n'importe qui, humain ou agent,
devant un symptôme et aucun endroit où poser la règle — il corrigera là où le
symptôme se manifeste. C'est mécanique, et c'est ce que cette règle arrête.

## 2. Un domicile se verrouille, sinon il se re-disperse

Domicilier sans verrou tient quelques semaines. Le verrou est un **test de
balayage** : il échoue si le concept réapparaît hors de son point d'entrée.

C'est un test comme un autre — rejouable, identifiant, versionné. Il relève
donc de `preuve.md`, pas d'une bonne intention.

⚠️ **Un balayage ne voit que le mécanisme qu'il cherche.** Un même concept
passe souvent par plusieurs noms — un attribut, un accesseur, un helper. Le
verrou énonce **par quoi il cherche**, donc ce qu'il ne peut pas trouver.

## 3. Une exception est le symptôme d'une couche manquante

Quand une règle « ne se traite pas pareil » sur deux ou trois cas,
**l'exception n'est presque jamais dans le problème** — elle est dans une
distinction de couche qu'on n'a pas nommée : application / supervision,
lecture / écriture, propriétaire / opérateur, public / interne.

Nommer la couche fait disparaître l'exception. Coder l'exception fait
disparaître la couche — et il faudra la re-découvrir au correctif suivant, en
la payant plus cher.

## 4. La taille est une contrainte, pas un goût

Au-delà d'un certain seuil, un fichier n'est plus modifiable autrement que par
ajout : personne ne peut le tenir en tête — ni son auteur, ni un relecteur, ni
un agent. Le patch local cesse alors d'être un choix de facilité pour devenir
**la seule opération que le fichier autorise encore**.

**Franchir le seuil n'interdit rien et ne bloque aucun lot** : cela ouvre un
ticket de découpe, daté, avec son motif. Une dette écrite se planifie ; une
dette subie se paie deux fois.

## 5. Dans une fonction, une valeur se calcule une fois

La même règle, à l'échelle d'une fonction : **un appel répété à l'identique —
même méthode, mêmes arguments, même résultat — se range dans une variable**,
nommée d'après ce qu'elle contient, puis la variable sert partout.

```php
$prefix = OfferNotificationFilter::bookingThreadPrefix();
if (! str_starts_with($event->thread, $prefix)) {
    return;
}
$id = Str::after($event->thread, $prefix);
```

Deux appels identiques sont deux endroits à modifier, et une invitation à en
changer un seul. La variable dit aussi au lecteur que c'est **la même** valeur.

Quand ce n'est pas possible, garder l'appel : une valeur qui peut changer entre
les deux appels (une requête, l'heure, un état modifié entre-temps), ou une
expression plus courte que le nom qu'on lui donnerait (`$a->b`).

## 6. Ce que cette règle n'autorise pas

Elle ne justifie **aucun refactor spontané**. Un agent sans tâche reste au
repos (`escalade.md`). Domicilier une règle, poser un verrou, découper un
fichier sont des **tickets** — demandés, dispatchés, bornés. Jamais un geste
pris au passage pendant un correctif.

Une règle de propreté qui autorise à élargir son propre périmètre produit
exactement le désordre qu'elle prétend corriger.

## Règles absolues

- Un concept transverse a un point d'entrée unique ; les autres délèguent
- Plusieurs implémentations **divergentes** d'une même règle ⇒ blocage et
  relevé, jamais une implémentation de plus
- Un domicile posé sans test de balayage est réputé temporaire
- Un balayage énonce par quel mécanisme il a cherché, donc son angle mort
- Une exception non domiciliée se traite comme une couche manquante à nommer
- Un dépassement de seuil ouvre un ticket, ne bloque pas un lot
- Un appel répété à l'identique dans une fonction se range dans une variable
- Aucun refactor hors ticket
