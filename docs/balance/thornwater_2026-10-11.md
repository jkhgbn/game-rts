# Thornwater : pourquoi Fire gagne (2026-10-11)

Demande : Fire gagne 71-83 % des parties bot contre bot sur Thornwater (83-100 % en Blitz) et le premier attaquant y
gagne peu. Est-ce la carte, la programmation des bots ou l'équilibre des unités ? Corriger de préférence par la carte ou
le trajet des bots. Méthode : labo faster-games (bot contre bot, normal tick 60, Blitz v20 tick 30, arrêt anticipé),
les 12 paires ordonnées (chaque royaume joue les deux sièges), plus des sondes qui notent où meurent les unités.

## Résumé

- **La cause : un bogue de code, pas la carte.** `BowmanKit`, `Stables16`, `NewUnits12` et `T3Kit` (`enabled_here()`)
  n'acceptaient que le script exact `scripts/world/skirmish.gd`. Sur une carte générée (`LayoutLevel`, qui hérite de
  `Skirmish` : Thornwater, Quartermeet...), les **archers de Hall, les 3 nouvelles unités, les Écuries et les T3 étaient
  absents**, pour les bots comme pour le joueur. La Forge et les lanceurs de sorts, eux, acceptaient déjà `LayoutLevel`.
  Sans ces unités, Fire (son sorcier et ses 4 unités de base) écrase les autres.
- **La preuve** : Crown Hollow joué comme `LayoutLevel` (`crown_hollow_level_layout.tres`, même carte que skirmish.tscn)
  donne Fire **15 / 15** ; le même Crown Hollow par skirmish.tscn donne Fire 62 %.
- **Le correctif** : les quatre kits utilisent maintenant `CasterKit.is_plain_skirmish()` (skirmish.gd, ou un
  `LayoutLevel` qui n'est pas une mission ; missions inchangées). Thornwater normal après : **Fire 71 -> 67 %, Shadow 29 -> 54 %, premier attaquant 65 %**.
- **Tous les chiffres Thornwater d'avant** (portail de carte G5 du 10-05 / 10-09, bras faster-games TW, Blitz TW de
  `blitz_2026-10-10.md`, Unit Lab feuille 10-11 « TW ») **ont été mesurés avec ces unités absentes**. Quartermeet aussi.
  Les réglages Blitz faits « pour Thornwater » (Fire x0,9, etc.) sont à revoir avec le correctif.
- Carte, trajet, rayon de Fireball : testés avant de trouver le bogue, aucun n'est la cause (section 3).
- Rayon de Fireball réduit en escarmouche seulement (accord de JS si Fire reste > 65 %) : **pas appliqué**. Après le correctif, Fire est à 60 % sur CH + TW (67 % sur Thornwater seul, 16 / 24, à ± 10 points du seuil) : la règle (« seulement si Fire reste au-dessus de 65 % ») ne le demande pas, et le rayon x0,75 faisait tomber Fire à 38 % sur Crown Hollow. Fireball est inchangé partout.

## 1. Les trois effets séparés (contrôles demandés, mesurés AVANT le correctif)

### a) Carte / siège : miroirs (même royaume des deux côtés, normal)
| Carte | Parties | Siège sud-ouest gagne | Détail |
|---|---|---|---|
| Crown Hollow (skirmish.tscn) | 16 (4 royaumes x 4 graines) | 8 / 16 = 50 % | - |
| Thornwater | 32 (16 + 16 sièges inversés) | 21 / 32 = 66 % | non inversé 13 / 16 ; inversé (`--swap-sides`) 8 / 16 |

L'équipe PLAYER du labo gagne aussi 21 / 32 sur Thornwater : avec ces échantillons on ne sépare pas siège et équipe.
L'effet est faible (environ 1,8 écart-type) et s'annule dans les taux par royaume (chaque paire joue les deux sièges).
Les chemins de la carte sont symétriques (Map Lab F1 812 / 812 paires à 2 %, C1 / C2 PASS).

### b) Programmation des bots : bras « même cerveau » (Thornwater, normal, 42 parties)
Ice et Nature reçoivent les boutons de stratégie du profil normal de base (celui de Fire et Shadow) : travailleurs 6 / 9 /
12, attack_ratio 1,3, X1 à 5:00 sans banque ni priorité, pas de Halls en plus, défense 28 m, retraite 40 %, pas de
regrow, tours S1 5:00 / S2 8:00, scout de base. Mix d'unités, sorts et objets restent ceux du royaume. Variante :
`tools/balance_lab/variants/thornwater/tw_same_brain.json`.

| Royaume | Base Thornwater (48) | Même cerveau (42) | Base Crown Hollow (48) |
|---|---|---|---|
| Fire | 71 % (17 / 24) | **91 % (21 / 23)** | 62 % (15 / 24) |
| Ice | 42 % | 33 % (7 / 21) | 38 % |
| Nature | 58 % | 42 % (8 / 19) | 58 % |
| Shadow | 29 % | 29 % (6 / 21) | 42 % |

Le réglage par royaume ne crée pas l'avance de Fire : il retient Fire (Ice / Nature contre Fire : 4:4 et 3:5 avec leur
réglage, 1:7 et 0:7 sans). Fire et Shadow ont déjà le même cerveau : Fire contre Shadow donnait 15:1 sur Thornwater.

### c) Unités (ce qui reste) = le roster amputé
Avec le même cerveau partout, Fire gagnait encore 91 % : l'effet venait des unités. La sonde
(`tools/map_lab/tw_probe.gd`) montre le sorcier Fire qui tue 50-60 % des soldats ennemis sur les deux cartes (normal TW 41
par partie, CH 25 ; Blitz TW 24, CH 28). Sur Thornwater, sans archers, nouvelles unités, Écuries ni T3, il n'y a rien
pour contrer cette zone : Crown Hollow en `LayoutLevel` donne la même chose (Fire 15 / 15). Les journaux le montrent
aussi : sur Crown Hollow chaque bot fait des centaines de pas « STABLES » par partie, sur Thornwater zéro.

## 2. Après le correctif (code actuel)

### Normal, 12 paires x 4 graines
Crown Hollow est rejoué au complet (le correctif ne touche pas skirmish.gd : l'écart est la variance d'une série à
l'autre, ± 14 points par royaume et par carte).

| Royaume | CH avant | CH après | TW avant | **TW après** | CH + TW avant | **CH + TW après** |
|---|---|---|---|---|---|---|
| Fire | 62 % | 54 % (13 / 24) | 71 % | **67 % (16 / 24)** | 67 % | **60 %** |
| Ice | 38 % | 29 % (7 / 24) | 42 % | **17 % (4 / 24)** | 40 % | **23 %** |
| Nature | 58 % | 71 % (17 / 24) | 58 % | **62 % (15 / 24)** | 58 % | **67 %** |
| Shadow | 42 % | 46 % (11 / 24) | 29 % | **54 % (13 / 24)** | 35 % | **50 %** |
| 1er attaquant gagne | 52 % | 54 % | 56 % | **65 %** | 54 % | 59 % |
| Siège sud-ouest gagne | 65 % | 67 % | 60 % | 54 % | 62 % | 60 % |

Paires sur Thornwater après (victoires du premier : second) : Fire-Ice 7:1, Fire-Nature 5:3, **Fire-Shadow 4:4** (était
8:0), Ice-Nature 1:7, Ice-Shadow 2:6, Nature-Shadow 5:3.

- Fire et Shadow rentrent dans 35-65 sur l'ensemble (Shadow 35 -> 50 %). Fire reste à 67 % sur Thornwater seul, surtout
  contre Ice (7:1).
- **Ice tombe à 23 %** (17 % sur Thornwater) : avec le roster complet, Ice perd contre tout le monde (Ice-Nature 1:7 sur
  les deux cartes). C'est le problème qui reste, côté bot Ice / unités Ice, plus Thornwater. Nature est à 67 %, juste
  au-dessus.
- Le premier attaquant gagne 65 % sur Thornwater (cible 40-60) : il gagne maintenant un peu trop souvent, au lieu de trop
  peu en Blitz avant.

### Blitz v20, Thornwater, 12 paires x 2 graines (tick 30)
| Royaume | Avant (`fg-bz12tw`, v20) | Après (`fg-twfix-bz-tw`) | Blitz CH v20 (`fg-bz12`, pour comparer) |
|---|---|---|---|
| Fire | 100 % (12 / 12) | **83 % (10 / 12)** | 58 % |
| Ice | 50 % | 17 % (2 / 12) | 42 % |
| Nature | 42 % | 58 % (7 / 12) | 50 % |
| Shadow | 8 % | 42 % (5 / 12) | 50 % |
| 1er attaquant gagne | 21 % | **42 %** | 46 % |
| Médiane | 14:42 | 13:54 | 16:24 |

Le Blitz sur Thornwater bouge dans le bon sens (Fire 100 -> 83 %, Shadow 8 -> 42 %, premier attaquant 21 -> 42 %), mais
Fire reste haut et Ice bas. Les réglages Blitz par royaume (`PaceSwitch.BLITZ`, `blitz_2026-10-10.md`) ont été faits avec
Thornwater amputé : à refaire avec le roster complet avant de toucher Fireball.

## 3. Ce qui a été testé avant de trouver le bogue (roster amputé sur Thornwater)

| Bras | Parties | Fire | Ice | Nature | Shadow | 1er attaquant gagne |
|---|---|---|---|---|---|---|
| Blitz v20 base (`fg-bz12tw`) | 24 | 100 % | 50 % | 42 % | 8 % | 21 % |
| Blitz W1 : ponts couronne 10, marches 8, ponts route 7, gués 8 (navmesh route clé -> clé 7,6 m au lieu de 4,8) | 24 | 100 % | 25 % | 50 % | 25 % | 33 % |
| Blitz W2 : ponts couronne 12, marches 10, ponts route 8, gués 9 | 19 (arrêté) | 91 % | 22 % | 25 % | 50 % | 26 % |
| Blitz : regroupement à la couronne avant de chasser un bâtiment (bouton de labo, retiré) | 15 (arrêté) | 89 % | 29 % | 43 % | 29 % | 40 % |
| Normal : bots plus calmes (attack_ratio / floor x1,2) | 5 (arrêté) | 3 / 4 | - | - | - | - |

Diagnostics sur le sorcier Fire (normal, 6 paires avec Fire ; surcharge de sorts en mémoire, labo seulement) :

| Bras | Carte | Parties Fire | Fire gagne |
|---|---|---|---|
| Base | TW / CH | 24 / 24 | 71 % / 62 % |
| Fireball dégâts x0,75 | TW | 12 | 92 % |
| Fireball dégâts x0,5 | TW | 11 | 82 % |
| Kindle quasi jamais (recharge x20) | TW | 12 | 83 % |
| Fireball rayon x0,75 | TW / CH | 24 / 13 | 79 % / 38 % |
| Fireball rayon x0,75, Blitz | TW / CH | 12 / 12 | 83 % / 50 % |

Rien de tout ça ne touchait la cause. Le rayon x0,75 faisait même l'inverse de ce qu'on veut : peu d'effet sur
Thornwater, Fire à 38 % sur Crown Hollow.

Ce que Thornwater a quand même de différent (sans effet mesuré sur Fire) : passages plus étroits sur le navmesh que sur
Crown Hollow avec la même largeur de spec (pont de la couronne 6,0 m contre 7,1 ; marches 4,3 contre 5,0 ; route clé ->
clé 4,8 m au plus étroit contre 6,9), naturelle plus près de la maison (39,8 m de chemin contre 47), champions qui tuent
moitié moins de travailleurs. `data/maps/thornwater.map` n'est pas modifié.

## 4. Suites proposées
- **Relancer les chiffres faits avec le roster amputé** : portail de carte G5 de Thornwater et Quartermeet
  (`run_map_gate.ps1 <map>`, `-Seats alternate`), bras Blitz Thornwater (`blitz_2026-10-10.md`), et toute autre mesure
  sur une carte générée.
- **Ice** (23 % sur CH + TW, 17 % sur Thornwater) : c'est maintenant le royaume hors cible ; Ice-Nature 1:7 sur les deux
  cartes. Côté bot Ice (ai-coder) ou mix Ice, pas Thornwater.
- **Fireball** : pas touché. Si Fire dépasse encore 65 % après les deux points plus haut, le rayon réduit en escarmouche
  seulement (missions inchangées) reste l'option approuvée ; essayer x0,85-0,9 plutôt que x0,75 (x0,75 donnait Fire 38 %
  sur Crown Hollow).

## Méthode, fichiers
- Base avant : `..\four-wizards-lab-runs\fg-icefix-ch|tw` (parties sans Ice) + `fg-iceeco2-ch|tw` (commit 668af976).
- Contrôles : `fg-twmirror-tw`, `fg-twmirror-ch`, `twmirror-swap-tw` (`--swap-sides=1`), `fg-twbrain-tw`,
  `fg-twchl` (Crown Hollow en `LayoutLevel`).
- Sondes : `twprobe-tw|ch` (normal), `twprobe-bz-tw|ch` (Blitz v20), avec `--log=1`.
- Carte : variantes `twx_s901` / `twx_s902` (data/maps/gen, effacées après), runs `fg-twbz-w1`, `fg-twbz-w2`.
- Diagnostics Fire : `twfb75-tw`, `twfb50-tw`, `twnokindle-tw`, `twfbr75-tw|ch`, `twfbr75-bz-tw|ch`.
- Après correctif : `fg-twfix-tw`, `fg-twfix-ch`, `fg-twfix-bz-tw`.
- Outil ajouté : `tools/map_lab/tw_probe.gd` (fg_match + chaque mort avec position et tueur, centre du groupe d'attaque
  toutes les 5 s, surcharge de sorts en mémoire `"spells": {...}` dans une variante). Variantes :
  `tools/balance_lab/variants/thornwater/*.json`.
- Tests : `test_map_start` (nouvelle vérification : sur Thornwater, archers, nouvelles unités, Écuries et T3 sont
  actifs), `test_bowmen`, `test_stables`, `test_t3`, `test_7_s1`, `test_mission_framework`, `test_e2m3` (missions : Écuries
  seulement via `cavalry_enabled`, inchangé), `test_map_tools`, `test_map_lab`, `test_mt9_map_picker`, `test_mt9_catalog`,
  `test_mt10_bot_slots`, `test_mt10_layout_bots` : PASS. `test_new_units_12` : FAIL déjà présent avant (« Piercing bolt :
  9,0 au lieu de 10 », scène skirmish.tscn, chemin de code inchangé par ce correctif ; probablement la passe d'unités
  039a5050).
