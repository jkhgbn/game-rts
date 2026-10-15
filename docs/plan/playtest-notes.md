# Four Wizards — build du 14 octobre 2026 au soir (tag playtest-2026-10-14-5)

Double-clic sur **FourWizards.exe** (un vrai .exe maintenant ; garde le fichier .dll à côté).

**Important :** les zips du 13 et du 14 au matin avaient un bug invisible dans nos tests : les objets, l'inventaire,
les champions et les assistants ne se chargeaient pas dans le jeu exporté. C'est corrigé ici, et chaque build est
maintenant vérifié (tous les scripts chargés dans le .exe avant le zip).

## Nouveau depuis le zip du 14 octobre (matin)
### Améliorations propres à chaque unité (escarmouche)
- Les 56 unités de combat des 4 royaumes ont au moins une amélioration (55 nouvelles), achetée dans le bâtiment qui
  les forme (Hall, Écuries ou donjon). Prix en cristaux, de 75 à 200 selon le tier, une recherche à la fois par bâtiment.
  Une recherche ne bloque jamais la formation d'unités.
- Touches : sélectionne le bâtiment, **+** = page de recherche, puis la touche de l'unité = sa page :
  **Z** = son « + » (rang 3), **X C V B** = ses améliorations. Rappuyer sur une recherche en cours = l'annuler
  (remboursée). Échap = page précédente.
- Effets variés : épines, dégâts en zone, poison, bouclier de combat, aura de meute, sorts plus forts pour les lanceurs,
  capacités des T3 renforcées…
- Les 3 améliorations d'unité de la Forge y ont déménagé ; la Forge garde Armes, Armure et l'amélioration du royaume.
- Les améliorations des archers sont enfin achetables.
- Le bot achète aussi ses améliorations selon son armée.

### Musique
- 13 nouveaux morceaux d'orchestre (vrais instruments, sans chant) : un thème par royaume, une marche neutre, Wave
  Strike, boss, carte de campagne, taverne, chant de fin, victoire et défaite.
- En partie : ton thème d'abord, puis au hasard entre les 4 thèmes et la marche (le tien plus souvent, jamais deux
  fois de suite). Des tambours montent quand l'ennemi attaque ta base ou ton sorcier.
- Musique au menu et sur la carte de campagne, musique de boss en mission ; elle se coupe pendant les cinématiques.
- Les missions ont enfin leurs bruitages (il n'y en avait pas).

## Dis-moi
- Les améliorations : trop chères, trop faibles, trop fortes ? Les touches + / unité / Z X C V B sont-elles claires ?
- La musique dans le jeu : le volume, la rotation, les tambours de combat.

## Problèmes connus
- Feu bat encore Ombre en Normal (~70 %) ; Blitz équilibré. Les nouvelles améliorations ne sont pas encore équilibrées
  (mesure bot contre bot en cours).
- e6m2 très dur en difficile ; e3m1, e4m4, e5m4 : nos joueurs simulés échouent encore.
