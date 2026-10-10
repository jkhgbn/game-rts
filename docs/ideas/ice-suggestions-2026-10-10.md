# Glace : pourquoi elle perd et quoi essayer (2026-10-10)

Demande de JS : des suggestions pour le royaume de Glace (le bot, les unités, etc.). Glace gagne 22-28 % dans toutes les
études bot contre bot (`docs/balance/faster_games_2026-10-06.md`, `_2026-10-08.md`, `blitz_2026-10-10.md`).
Document d'idées seulement : rien n'est changé dans `data/` ni `scripts/`. Aucun nouveau lancement de labo pour ce document.
Les chiffres viennent des docs ci-dessus, des fichiers de données et des JSON de labo déjà sur disque
(`..\four-wizards-lab-runs\fg-c8n` = baseline du 10-08, 96 parties par royaume ; `fg-icefix`, `fg-workersafety`,
`fg-wsbefore`). Le Blitz est réglé par un autre agent dans `scripts/world/pace_switch.gd` : on n'y touche pas ici.

## 1. Diagnostic

### 1.1 Les unités de Glace ne sont pas faibles au combat
Matrices finales du 2026-10-06 (`final_matrix_t1t2*`, 47 entrées, score moyen par royaume) :

| Budget | Feu | Ombre | Glace | Nature |
|---|---|---|---|---|
| Cristaux égaux | 48 | 53 | **51** | 47 |
| Pop égale | 57 | 51 | **55** | 38 |
| Les deux | 50 | 53 | **54** | 44 |

Rimeshield 90 / 93 / 92, Rime Colossus 76 / 94 / 89, Snowdrift Rider 81 / 79 / 83 et Frost Mortar 76 / 76 / 78 sont parmi
les plus forts. Le mix Glace en armées mixtes fait 37-51 % (`mix_line_check_fg60`). **Donner plus de PV ou de dégâts aux
unités de Glace ne règle pas la cause** et briserait la passe du 06 (Rimeshield et Colossus sont déjà « too strong »).
Seuls points faibles réels : les tireurs T1 (Shardcaster 14 / 32 / 18, Frostbow 16 / 62 / 23) et le soigneur (Rime Seer 0 / 5 / 0),
exemptés par rôle.

### 1.2 Ce que la Unit Lab ne voit pas : le temps
La Unit Lab compare des armées déjà là. Glace paie en **temps** partout :

| | Feu | Ombre | Glace | Nature |
|---|---|---|---|---|
| Caserne (coût / construction) | Ember Hall 150 / 45 s | Gloom Hall 150 / 45 s | **Frost Hall 150 / 54 s** | Grove Hall 130 / 38 s |
| Ligne T1 (coût / formation) | Flame Guard 90 / 18 s | Shade 80 / 16 s | **Rimeshield 95 / 22 s** | Thornling 60 / 12 s |
| Tireur T1 | Ember Archer 100 / 20 s, 7,5 dps | Nightbolt 100 / 20 s, 7,7 dps | **Shardcaster 110 / 22 s, 6,4 dps** | Burr Slinger 70 / 14 s |
| Lourd du Hall | Blaze Rider 180 / 30 s | (Barrow / Shadow Knight) | **Rime Colossus 290 / 52 s, pop 3** | Bramblehorn 200 / 34 s |
| Tour | 120 / 35 s | 120 / 35 s | **130 / 42 s** | 100 / 30 s |
| Maison | 80 / 25 s | 80 / 25 s | **80 / 30 s** | 60 / 20 s |

Résultat mesuré (baseline 10-08, `fg-c8n`, moyenne par royaume, 96 parties) :

| | Feu | Ombre | Glace | Nature |
|---|---|---|---|---|
| Victoires | 71 % | 45 % | **20 %** | 65 % |
| Pop d'armée à 3:00 | 7,2 | 7,0 | **4,7** | 8,9 |
| Pop d'armée à 5:00 | 8,2 | 8,1 | **7,2** | 10,0 |
| Récolté à 10:00 | 5 025 | 5 010 | **4 912** | 5 845 |
| Unités formées / partie | 76 | 83 | **70** | 101 |
| **Attaques lancées / partie** | 2,3 | 2,7 | **1,1** | 6,4 |
| **Parties sans aucune attaque** | 20 % | 21 % | **48 %** | 0 % |
| Niveau du sorcier à la fin | 7,5 | 7,0 | **6,3** | 7,1 |

Par adversaire : Glace bat Ombre 11 / 32 (34 %), Feu 5 / 32 (16 %), Nature 3 / 32 (9 %). Sur 77 défaites, **43 sans une
seule attaque** ; 51 par abandon, 24 par score anticipé (early-score : le score militaire d'une Glace qui n'attaque pas reste bas).

Lecture : **Glace a le revenu des autres (4 912 contre 5 010-5 025 pour Feu / Ombre) mais elle reste chez elle.**
Ce n'est pas un problème d'économie, c'est un problème de bot qui n'attaque pas, plus un départ lent de ~2,5 pop à 3:00.

### 1.3 Pourquoi le bot n'attaque pas (`commander.gd` règle 7, `ai_profile.gd` `ice()`)
1. **`min_attack_pop` = 6 + 2 = 8 pour Glace** (les autres : 6). Il compte la pop **hors réserve**.
2. **La réserve (`RESERVE := 2`) garde les 2 soldats avec le plus de PV** (`home.sort_custom(... a.hp > b.hp)`). Chez Glace,
   c'est le Rime Colossus (520 PV, **pop 3**) et un Rimeshield (150 PV). La réserve de Glace mange donc ~4 pop, contre 2 pop
   pour Feu (2 Flame Guard) ou Nature. **Glace doit avoir ~12 pop à la maison pour lancer une attaque ; Feu en a besoin de 8.**
   Or la pop d'armée de Glace plafonne à 7-8 entre 5:00 et 10:00. Le blocage « pop » gagne presque tout le temps.
   (C'est déduit du code et des chiffres ; `attack_blocks` n'est pas écrit dans les JSON du labo. Le confirmer : voir 4.1.)
3. **`attack_ratio` 1,4** (normal, +0,1) et 1,3 en difficile (+0,2) : plus prudent que tout le monde, alors que l'armée est
   plus petite au moment où ça compte.
4. **`first_attack_by` (10:00) baisse seulement le ratio, pas le seuil de pop** : il ne débloque donc pas Glace.
5. Le Blitz le confirme : +800 cristaux et formation x0,35 n'ont rien changé (28 % / 22 %). Plus d'unités plus vite ne
   donnent pas d'attaques si la porte de pop (8 + réserve lourde) reste là.

### 1.4 Les autres causes (secondaires)
- **Ordre de construction défensif** : S1 à 3:30 (les autres 5:00), S2 à 7:00 (les autres 8:00), `defend_radius` 32 m,
  murs en difficile, puis H2 / H3 (2 x 150 cristaux, 54 s chacun) quand la banque dépasse 300. Ça fait 260 cristaux de
  tours avant 7:00 et, au mieux, 300 de Halls de plus, dans une armée qui n'attaque pas de toute façon.
- **Mix du Hall** `[0.40, 0.30, 0.10, 0.20]` : 10 % de Rime Seer (4 dps, soigneur) et 20 % de Colossus (52 s, pop 3). Le
  Colossus arrive tard (`heavy_crystals` 300, `heavy_soldier_pop` 8), puis il gonfle la réserve (voir 1.3-2).
- **`mix_vs_ranged` met 50 % de Rimeshield** (lent, 4,2 m/s) contre des tireurs qui le kitent : la fiche Unit Guide le dit
  (« weak against Kiting archers »). Glace n'a rien de rapide au T1 ; le Snowdrift Rider (T1, 81 / 79 / 83) n'est pris
  qu'à la petite part `NewUnits12.bot_share`.
- **Torvald frappe le moins fort** : Rime Bolt 45 dégâts à une cible / 6 s, Flash Freeze 20 dégâts en zone r 3 / 20 s.
  Comparé à Fireball 60 en zone r 3,5 / 3 s et Thornburst 40 en zone r 3 / 5 s. Il tue 1,2 ouvrier par partie (Vessa 4,7, Blitz),
  finit au niveau 6,3 (le plus bas) et ne rejoint que les attaques qui n'ont pas lieu. Ses forces (440 PV, armure 10,
  Rime Aegis) sont défensives, comme tout le reste.
- **Tours de Glace** : 12 dégâts / 1,5 s (8 dps) contre 15 dégâts pour Feu / Ombre, pour 10 cristaux et 7 s de plus. Une
  stratégie de tortue avec les tours les plus faibles du jeu.
- **Sécurité des ouvriers (ccb9227b)** : Glace 12 % contre 25 % sur 24 parties (non significatif). Dans `fg-workersafety`,
  Glace perd surtout ses ouvriers aux champions ennemis (127 / 24 parties) et aux sorciers (35). Pas le premier suspect.

## 2. Suggestions pour le bot (classées)
Toutes touchent `scripts/ai/ai_profile.gd` `ice()` et `data/ai/ice_*.tres` (qui doivent rester alignés), sauf B2 (`commander.gd`).
Aucune ne change les matrices de la Unit Lab.

| # | Changement | Valeurs | Effet attendu | Risque |
|---|---|---|---|---|
| **B1** | Enlever le +2 de `min_attack_pop` | `p.min_attack_pop += 2` -> rien (normal 8 -> 6, difficile 7 -> 5, facile 10 -> 8) | Glace attaque à la même taille que les autres ; fait passer les « 0 attaque » de 48 % à ~20 % | Bas. Peut perdre des petites attaques ; la retraite à 40 % limite les pertes |
| **B2** | Réserve en **pop**, pas en unités, et sans le lourd | `commander.gd` règle 7 : réserve = soldats les plus sains jusqu'à 2 pop, en sautant les unités pop >= 3 (Colossus, T3) | Corrige l'asymétrie : le Colossus part avec l'armée au lieu de garder la maison. Aide aussi les bots Feu / Ombre / Nature avec leurs lourds plus tard | Moyen : touche tous les royaumes ; à mesurer sur les 12 paires |
| **B3** | Ratio normal comme les autres | `attack_ratio` +0,1 / +0,2 -> **+0,0** (normal 1,3, difficile 1,1) | Attaques plus tôt avec la même patience (`attack_patience`) | Bas |
| **B4** | Mix plus rapide à produire | `mix_default` `[0.40, 0.30, 0.10, 0.20]` -> **`[0.45, 0.35, 0.05, 0.15]`** ; `mix_vs_ranged` `[0.50, 0.20, 0.10, 0.20]` -> **`[0.40, 0.30, 0.05, 0.25]`** | Plus de pop par minute de Hall, moins de Rime Seer à 4 dps ; contre les tireurs, plus de Colossus (armure 20) que de Rimeshield kités | Bas |
| **B5** | Lourd plus tôt mais seulement s'il part | `heavy_crystals` 300 -> 290 (son prix), `heavy_soldier_pop` 8 -> **6** ; seulement avec B2 | Le Colossus (94 % à pop égale) arrive avant 5:00 | Moyen sans B2 (il gonflerait la réserve) |
| **B6** | Construction moins défensive | `tower1_time` 210 -> **300**, `tower2_time` 420 -> **480** (comme les autres), `extra_hall_bank` 300 -> **250** | 130 cristaux de plus dans l'armée avant 5:00 ; H2 un peu plus tôt (formation parallèle) | Moyen : plus de raids d'ouvriers tôt ; surveiller « 1er bâtiment perdu » |
| **B7** | Torvald rejoint les attaques | `malrik_joins` normal = `EVERY_ATTACK` pour Glace (440 PV + armure 10 + Aegis : c'est un tank) | Plus de puissance (`_attack_power` le compte) donc moins de blocage « strength » ; plus d'XP | Moyen : le sorcier meurt plus ; le retour à 35 % PV le protège |
| **B8** | Éclaireur rapide | `scout_fast` false -> **true** (prend le Snowdrift Rider / le plus rapide) | Mémoire ennemie plus fraîche, donc `seen_strength` moins gonflé par des tours vues il y a longtemps | Bas |
| B9 | Rayon de défense | `defend_radius` 32 -> 28 (comme les autres) | Moins de soldats tirés en défense loin du rally | Bas ; effet probablement petit |

Pour le Blitz : B1-B3 devraient aussi marcher là, parce que `PaceSwitch.BLITZ` ne touche pas `min_attack_pop` ni la réserve.
C'est à l'agent du Blitz de les reprendre dans `pace_switch.gd` ou de les recevoir par `ice()`.

## 3. Suggestions d'unités, de bâtiments et de sorcier
Règle : **ne pas monter les PV ni les dégâts des unités fortes** (Rimeshield, Colossus, Snowdrift, Mortar). Glace manque de
vitesse de production, pas de puissance. Chaque ligne donne l'effet sur la passe du 2026-10-06.

| # | Changement | Valeurs | Effet attendu | Risque pour la passe du 06 |
|---|---|---|---|---|
| **U1** | Frost Hall plus vite construit | `ice_barracks.tres` `build_time` 54 -> **45 s** (comme Feu / Ombre) ; garder 1 560 PV | +9 s de formation au départ ; H2 / H3 aussi plus vite | Aucun (pas d'unité) |
| **U2** | Rimeshield plus vite formé | `train_time` 22 -> **19 s** | ~+0,7 pop à 3:00 par Hall ; plus de pop / minute partout | Aucun dans les matrices (le temps n'y entre pas). Joueur humain : 90 / 93 au combat + formation rapide = à surveiller ; ne pas toucher au coût |
| **U3** | Shardcaster plus vite formé | `train_time` 22 -> **20 s** (comme Ember Archer / Nightbolt) | Le tireur T1 le plus faible devient au moins aussi rapide à sortir | Aucun |
| **U4** | Rime Colossus plus vite formé | `train_time` 52 -> **44 s** | Le lourd arrive avant la 1re attaque | Aucun dans les matrices ; ne pas baisser son coût (94 % à pop égale) |
| U5 | Shardcaster un peu plus fort | `attack_damage` 9 -> **10** (7,1 dps) | Le mix Glace tire mieux contre les lignes | Bas : 14 / 32 / 18, exempté par rôle ; refaire la matrice focus |
| U6 | Tour de Glace | Rime Spire 130 / 42 s -> **120 / 35 s**, ou dégâts 12 -> 13 | Aligne sur Feu / Ombre ; la tortue tient mieux | Aucun sur les unités ; peut rallonger les parties (contraire au but des parties plus rapides) |
| U7 | Snow Lodge | `build_time` 30 -> **25 s** | Moins de blocages de pop | Aucun |
| **W1** | Rime Bolt | dégâts 45 / 58 / 72 -> **55 / 70 / 85**, cd 6 -> **5 s** | Torvald tue et gagne de l'XP ; reste à une cible (moins dangereux pour les ouvriers que Fireball) | Pas dans la Unit Lab (sauf Hollow casters) ; à valider en partie bot |
| W2 | Flash Freeze | dégâts 20 / 30 / 40 -> **30 / 40 / 50**, cd 20 -> **16 s** | Un vrai sort de zone | Le gel en zone + plus de dégâts peut gâcher les combats du joueur ; tester |

À éviter : plus de PV ou d'armure au Rimeshield ou au Colossus, coût plus bas du Colossus, plus de cristaux de départ en Normal
(le Blitz a montré +800 sans effet).

## 4. Plan de test

### 4.1 Avant tout : confirmer le blocage (1 lot court)
Ajouter au résumé `LAB_RESULT` de `tools/bot_lab/lab_match.gd` le dictionnaire `Commander.attack_blocks` par camp (et la
pop de la réserve au moment du blocage), puis relancer **12 parties Glace** (Glace contre les 3 autres, 2 sièges, 2 graines,
normal, tick 30, Crown Hollow). Hypothèse confirmée si « pop » est le blocage dominant de Glace et pas des autres.

### 4.2 Lots (outil `tools/balance_lab/faster_games/run_fg.py`, variantes dans `tools/balance_lab/variants/`)
Attention : `fg.ai` s'applique aux deux camps. Les variantes bot de Glace ont besoin d'une clé par royaume (ex.
`"ai_ice": {...}`) ou d'un patch de `ice()` dans une branche de labo. Sinon une variante comme B1 changerait aussi les autres bots.

Ordre, en arrêtant dès qu'un bras atteint le critère :
1. `ice_b1_b3` : B1 + B3. 36 parties (3 graines, 12 paires ordonnées), normal.
2. `ice_b1_b3_b2` : + B2 (réserve en pop). 36 parties normal **et** 24 parties difficile (la réserve change pour tous).
3. `ice_bot_full` : + B4, B5, B6, B8. 36 normal.
4. Seulement si 3 reste sous 35 % : `ice_u1_u2` (Frost Hall 45 s, Rimeshield 19 s) par-dessus 3. 36 normal.
5. Puis W1 seul par-dessus le meilleur bras. 36 normal.
6. Le gagnant : 72 parties normal (6 graines) + 24 difficile + 12 facile, et 1 graine Thornwater (12 parties).

### 4.3 Critères de réussite
- **Chaque royaume entre 35 et 65 %** en normal (N >= 36 par royaume au total, pas 18 : à 18 parties un taux porte
  ±12 points). En difficile, entre 30 et 70 % (N plus petit).
- Glace : attaques / partie >= 2, parties sans attaque <= 25 %, pop d'armée à 5:00 >= 8.
- Pas de nouvelle domination : Nature et Feu ne montent pas au-dessus de 70 %.
- Durée médiane normal dans ±2:00 de 22:18 ; le premier attaquant gagne <= 70 %.
- Pour U5 / W1 / W2 seulement : matrice focus 20 graines (`run_unit_lab.ps1`, l'entrée changée contre les 46 autres, cristaux
  et pop) ; aucune entrée ne dépasse 75 %. Pour U1-U4, U6, U7 : pas de Unit Lab (le temps n'y entre pas), mais `test_unit_guide`
  si une phrase « rapide / lent » de la fiche change.
- Les changements de données (U, W) sont aussi vus par le joueur humain : un playtest de JS avec Glace avant de les garder.

## 5. Les 3 changements à essayer en premier
1. **B1 + B3 : enlever les bonus de prudence du bot Glace** (`min_attack_pop` +2 -> 0, `attack_ratio` +0,1 / +0,2 -> 0).
   Deux lignes dans `ice()` et `ice_*.tres`, aucun effet sur les unités, vise la cause mesurée (1,1 attaque par partie, 48 % sans attaque).
2. **B2 : une réserve en pop qui n'enferme pas le Rime Colossus.** Aujourd'hui les 2 soldats avec le plus de PV restent à la
   maison ; chez Glace ça bloque ~4 pop, donc il faut ~12 pop pour attaquer contre 8 pour Feu.
3. **U1 + U2 : Frost Hall 54 -> 45 s et Rimeshield 22 -> 19 s.** Ça comble le retard de 2,5 pop à 3:00 sans toucher aux
   PV, aux dégâts ni aux coûts, donc sans bouger les matrices du 06. À faire seulement si 1 et 2 ne suffisent pas, parce que
   le joueur humain le sentira aussi.
