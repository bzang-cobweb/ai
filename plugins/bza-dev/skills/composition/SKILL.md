---
name: composition
description: Composer l'interface au lieu de dupliquer — un seul conteneur (panneau, modale, carte, barre, en-tête de page) qui porte le cadre et rend `children`, chaque usage n'écrivant que son contenu. À lire avant d'écrire un composant d'interface qui ressemble à un composant existant, ou quand deux écrans copient le même cadre (React, React Native, Blade).
---

# Un conteneur, des `children`

Deux écrans qui ont besoin du même **cadre** (un panneau qui monte du bas, une modale, une carte, une barre fixe, un
en-tête) ne le recopient pas. Le cadre vit dans **un seul conteneur**, qui le porte entièrement et rend ses `children`
(en Blade : `{{ $slot }}` et les slots nommés) ; chaque usage n'écrit que son **contenu**.

Le cadre, c'est tout ce qui doit être pareil d'un usage à l'autre : la fenêtre, le fond, l'en-tête, la fermeture, la
taille, les marges, la largeur, les bordures, les coins, l'accessibilité. Le contenu, c'est ce qui change : les champs,
la liste, les boutons propres à l'usage.

Deux copies d'un cadre divergent dès la deuxième retouche, chacune corrigée de son côté : fermeture, bordure, coins,
marges. Le conteneur unique donne le même rendu partout et une correction faite une fois.

## Écrire un composant d'interface

1. **Chercher le conteneur existant** avant d'écrire : un composant qui porte déjà ce cadre (même rôle, même
   apparence). S'il existe, l'utiliser tel quel, en ne passant que le contenu.
2. **Repérer les copies.** Deux usages (ou plus) qui recopient un cadre — même structure, mêmes styles, à quelques écarts
   près — en appellent un conteneur. Fait quand chaque copie est trouvée et ses écarts listés.
3. **Extraire le conteneur.** Il porte le cadre, rend `children`, et ne prend en props que ce qui varie vraiment d'un
   usage à l'autre et ne peut pas être du contenu : un titre, `onClose`, un `testID`, un choix de forme (un booléen :
   taille maximale ou taille du contenu). Les écarts entre copies se tranchent : un seul rendu est retenu (celui que
   l'humain désigne, à défaut le plus récent), et l'écart n'est pas gardé en option.
4. **Faire passer chaque usage par lui.** Fait quand plus aucun écran ne recopie le cadre.
5. **Prouver** : tests du conteneur (le cadre, chaque forme, la fermeture), et chaque usage vu dans le simulateur ou le
   navigateur, dans **chacun** des contextes où il s'ouvre (un écran d'onglet, un écran de la pile, une page).

## Ce qui va dans le contenu, ce qui va dans le conteneur

- **Un élément propre à l'usage reste dans le contenu**, même s'il se place en bas ou en haut : une barre de boutons qui
  dépend de l'état d'un formulaire vit dans le formulaire. Le conteneur lui laisse la place (un contenu en `flex: 1` qui
  remplit le cadre) au lieu de l'exiger en prop.
- **Un élément répété dans plusieurs contenus devient à son tour un petit conteneur** : la même barre fixe du bas,
  écrite deux fois avec ses bordures et ses marges, devient un composant qui rend `children`, avec une prop de
  disposition (`row`) si les usages l'exigent.
- **Une marge, une hauteur, une largeur se règlent une fois**, dans le conteneur. Le contenu n'en rajoute pas : une marge
  du bas de l'écran appliquée par le cadre **et** par la barre est comptée deux fois.
- **Ce qui dépend de l'environnement du conteneur se mesure dans le conteneur** : les marges de sûreté d'une fenêtre
  native se lisent dans cette fenêtre, la place disponible vient de la mise en page plutôt que d'un calcul sur l'écran.
- **Une prop ne sert pas à recréer une copie** : une prop qui active l'ancien rendu d'un usage (« coins de 16 pour le
  calendrier ») ramène la duplication dans le conteneur.

## Exemple : le panneau qui monte du bas (React Native)

Les filtres d'une liste et les demandes d'un jour du calendrier recopiaient chacun un `Modal` qui glisse du bas, avec
leur fond, leur en-tête et leur fermeture, et avaient divergé. Un seul `BottomSheet` porte maintenant le cadre ; une
`SheetBar` porte la barre fixe du bas, répétée dans les deux contenus.

```tsx
// Le conteneur : tout le cadre, puis children.
export function BottomSheet({ visible, title, onClose, children, fitContent = false }: Props) {
  return (
    <Modal visible={visible} transparent animationType="slide" onRequestClose={onClose}>
      <SafeAreaProvider>{/* les marges de la fenêtre du Modal, pas de l'écran qui l'ouvre */}
        <Sheet title={title} onClose={onClose} fitContent={fitContent}>{children}</Sheet>
      </SafeAreaProvider>
    </Modal>
  );
}

// Un usage : seulement son contenu.
<BottomSheet visible={open} title={t('list.filters')} onClose={close}>
  <ScrollView style={{ flex: 1 }}>{fields}</ScrollView>
  <SheetBar row>
    <Clear />
    <Apply />
  </SheetBar>
</BottomSheet>
```

Ce que l'exemple a appris, et qui vaut pour tout conteneur :

- le cadre a été retenu tel quel (celui des filtres) ; le calendrier a perdu ses écarts au lieu de les garder en props ;
- la hauteur vient de la mise en page de la fenêtre du `Modal` ; une hauteur calculée sur l'écran débordait sur un écran
  de la pile, dont la fenêtre ne commence pas en haut ;
- la barre du bas des filtres dépend de l'état du formulaire : elle reste dans le contenu, et la `SheetBar` ne porte que
  son style.

## Règles absolues

- Un cadre répété vit dans un seul conteneur, qui rend `children` ; chaque usage n'écrit que son contenu
- Le conteneur ne prend en props que ce qui ne peut pas être du contenu
- Les écarts entre copies se tranchent ; aucun n'est gardé en option
- Une marge, une hauteur, une largeur se règlent une fois, dans le conteneur
