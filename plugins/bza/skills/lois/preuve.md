# Règle de preuve

Un livrable annoncé « fait » repose sur une **preuve**, ou il n'est pas fait.
Cette règle définit ce qui compte comme preuve. Elle vaut pour tous les
profils, y compris l'orchestrateur et la QA.

## Les cinq propriétés

Une preuve est **rejouable, identifiante, qualifiée, bornée et fraîche**.
S'il en manque une, ce n'est pas une preuve : c'est un témoignage.

### 1. Rejouable — un tiers doit pouvoir la refaire

Le livrable de preuve est un **fichier versionné** — un test, un spec, une
commande consignée, un artefact rangé à un chemin stable. Jamais un script
jeté dans `/tmp` et supprimé après usage, même s'il a réellement tourné et
même si le compte rendu qui en découle est exact.

Le problème n'est pas la sincérité, c'est la **vérifiabilité** : quand aucun
fichier n'a bougé et qu'aucun artefact n'a été produit, rien ne distingue un
vrai succès d'un récit exact.

L'exploration jetable reste légitime pour **découvrir** — le flux, les
sélecteurs, la cause d'un échec. Elle n'est jamais le livrable.

Exécuter réellement la preuve, et vérifier qu'elle passe, avant de la
rapporter comme faite. L'écrire ne suffit pas.

### 2. Identifiante — elle doit distinguer le bon objet du mauvais

**Une preuve qui ne peut pas distinguer le bon objet du mauvais n'est pas une
preuve.** Une assertion porte sur le **contenu attendu**, jamais sur la seule
présence ou visibilité : un test qui passerait aussi avec un libellé vide, une
image absente ou une valeur nulle ne prouve rien.

Corollaire : **tester ce qui est demandé ne dit rien de ce qui manque.** Une
vérification qui ne trouve que ce qu'elle cherchait est borgne — un même objet
peut être référencé par plusieurs mécanismes, et la méthode qui en trouve un
ne voit pas les autres.

### 3. Qualifiée — savoir sur quoi on conclut

Avant de conclure sur un fichier, établir **s'il est versionné ou généré, et
par quoi**. Lire le bon contenu ne suffit pas si on se trompe sur la nature du
fichier : une analyse techniquement juste sur un artefact généré produit une
conclusion fausse sur la source qui l'engendre.

Même exigence pour l'état d'un répertoire : avant d'affirmer « ce n'était pas
cassé », vérifier si l'état constaté résulte d'un changement récent
(déplacement, renommage, régénération) — et le nommer.

### 4. Bornée — dire ce qu'elle ne couvre pas

Tout rapport de preuve énonce explicitement son périmètre **et son
complément** : ce qui a été vérifié, et ce qui ne l'a pas été.

Un verdict non borné se relit quelques semaines plus tard comme couvrant tout
un lot. La mention de ce qu'il ne couvre pas est la moitié utile du verdict.

### 5. Fraîche — l'environnement avant le code

Avant de conclure à une régression, à un défaut ou à un environnement mort :
**relancer une fois**. Un service qui vient de démarrer, un conteneur froid,
un cache vide produisent des échecs fantômes qui disparaissent au second
passage sans qu'une ligne ait changé.

N'ouvrir un ticket de régression qu'après ce second passage. Ne jamais
réveiller un humain sur un premier échec d'environnement.

## Le verdict d'un contrôleur

Un go/no-go, un gate, une validation reposent sur un **rejeu indépendant** —
la personne qui contrôle exécute elle-même — jamais sur la relecture du
dossier de l'agent contrôlé. Relire un rapport ne vérifie que la cohérence du
rapport avec lui-même.

## Règles absolues

- Preuve non rejouable par un tiers → le livrable est refusé, quel que soit le
  compte rendu
- Assertion sur la présence seule → à réécrire sur le contenu attendu
- Conclusion sur un fichier dont on n'a pas établi la nature → à refaire
- Rapport de preuve sans son complément (« ce que ceci ne couvre pas ») → incomplet
- Échec d'environnement au premier passage → relancer avant toute conclusion
- Verdict rendu sur dossier au lieu d'un rejeu → sans valeur
