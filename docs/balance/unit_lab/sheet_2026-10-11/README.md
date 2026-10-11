# Feuille d'équilibrage des unités (Unit Lab, 2026-10-11)

Tableur interne pour l'équilibre des unités, bâti à partir de matrices Unit Lab fraîches sur le HEAD du 2026-10-10
(`e309fe21`, donc après les améliorations de la Forge, le Blitz et le bot Ice). Rien dans le jeu n'a été modifié : les
changements proposés ont seulement été essayés en mémoire (variantes A/B).

## Ce qui a roulé (environ 32 000 combats, tick 60, 0 erreur de script)
| Matrice | Budget | Graines | Combats |
|---|---|---|---|
| Cristaux égaux | 720 cristaux | 1-6 | 8 910 |
| Population égale | 8 de pop | 1-6 | 8 910 |
| Les deux budgets (le premier qui bloque) | 720 c / 8 pop | 1-4 | 5 940 |
| Duels ciblés (20 graines) | 720 c | 1-20 | 80 |
| A/B des suggestions (r1, r2 ; 10 unités contre tout le champ) | cristaux et pop | 1-4 | ~8 000 |

55 entrées : toutes les unités T1/T2/T3 entraînables des 4 royaumes (Stormbottle Genie est neutre, donc absent) et les
4 lanceurs de sorts (entrée « lanceur + son unité de ligne »). Les sorties brutes sont dans `raw_*/` (scorecard + matrice),
les JSONL dans `..\four-wizards-lab-runs\unit-lab-sheet_2026-10-11_*`. Pour tout regénérer : `python build_sheet.py`.

## Comment lire les fichiers
- **`units.csv`** : une ligne par unité. Stats tirées des `.tres` (coût, pop, temps d'entraînement, PV, dégâts, cooldown,
  DPS de base = dégâts / cooldown sans capacités, portée, vitesse, armure).
  - `mean_crystals / mean_pop / mean_both` = score moyen (victoire 1, nul 0,5) contre chaque adversaire du **champ jugé**,
    chaque adversaire pesant pareil. **Champ jugé** : les T1/T2 contre les T1/T2 (comme les passes d'avant), les T3 contre
    les autres T3. Les colonnes `*_vs_all` donnent le score contre les 54 autres; `t3_vs_t1t2_crystals` dit à quel point un
    T3 écrase les T1/T2.
  - `rank_in_kingdom` : rang dans le royaume selon le score à cristaux égaux contre tous.
  - `best / worst_matchups_crystals` : les 3 meilleurs et 3 pires affrontements (% de victoire à cristaux égaux).
  - `outlier` : `strong` (> 70) ou `weak` (< 30) à cristaux **ou** à pop. `exempt` = rôle exempté (soutien, archers T1,
    bowmen, siège, Hexweaver, saboteur) : seuls de front, ils perdent par construction, on les juge en armée mixte.
    Les petites unités à 1 pop et ≤ 60 cristaux (Scorchling, Rimeling, etc.) sont jugées seulement sur `both`.
  - `severity` = nombre de points au-delà de 70 / en deçà de 30. `suggested_change` = petite valeur concrète (± 15 % max);
    quand la note dit « suggestion tested », le texte donne le résultat de l'A/B (avant -> après).
- **`matchups.csv`** : % de victoire de la ligne contre la colonne à cristaux égaux (6 graines par case, donc ± 20 points
  par case : lisez les tendances, pas une case seule).
- **`kingdoms.csv`** : moyenne par royaume et par tier (champ jugé), meilleure / pire unité, nombre d'outliers.
- Bruit : une moyenne d'environ 280 combats (cristaux) bouge d'à peu près ± 4 points; les A/B à 4 graines, ± 6-7.
- Pas de `.xlsx` : `openpyxl` n'est pas installé. Ouvrez les CSV dans Excel ou LibreOffice.

## Top 10 des outliers (hors lanceurs) et valeurs proposées
| # | Unité | Cristaux / Pop / Both | Proposition | Résultat de l'A/B |
|---|---|---|---|---|
| 1 | Frostcrown Juggernaut (Ice T3) | 100 / 98 / 96 | max_hp 780 -> **700**, armor 35 -> **28** | 79 / 93 : encore fort à pop, prochaine étape armure 25 |
| 2 | Vinelasher (Nature T2) | 69 / 97 / 84 | max_hp 170 -> **145**, attack_damage 13 -> **12** | PV seuls : 52 / 97. Pop 1 -> 2 dépasse la cible (pop 32) |
| 3 | Bramblehorn (Nature T1) | 80 / 95 / 93 | max_hp 380 -> **325**, attack_damage 18 -> **16** | 54 / 77 |
| 4 | Pyre Adept (Fire T2) | 76 / 93 / 73 | max_hp 80 -> **70** | 74 / 92 : la force à pop vient du prix (130 c pour 1 pop); jugez-le sur `both` |
| 5 | Rimeshield (Ice T1) | 89 / 93 / 96 | max_hp 150 -> **130**, attack_damage 11 -> **10** | 70 / 88. Le mix Ice était correct (37-51 %) : confirmer dans `mix_line_check` avant |
| 6 | Rime Colossus (Ice T1) | 77 / 93 / 88 | max_hp 520 -> **440**, attack_damage 28 -> **25** | 60 / 79 |
| 7 | Shade (Shadow T1) | 88 / 74 / 74 | max_hp 110 -> **95** | 73 / 61 |
| 8 | Greenheart Oathkeeper (Nature T2) | 87 / 75 / 88 | max_hp 300 -> **260** | 78 / 67 |
| 9 | Shardguard (Ice T3) | 26 / 14 / 25 | attack_damage 18 -> **21** | à 24 dégâts + 495 PV : 86 / 18 (trop fort à cristaux, rien à pop). Sa pop de 3 est la vraie limite : envisager pop 3 -> 2 |
| 10 | Snowdrift Rider (Ice T1) | 83 / 76 / 85 | max_hp 240 -> **210** | pas encore testé |

Juste en dessous : **Briar Roc** (Nature T3, 17 / 29 / 18) : +12 % PV et 18 -> 23 dégâts n'ont rien changé (14-18) :
**à investiguer** avant d'y toucher (volant, Seed Storm). **Sunforge Cataphract** (79 / 83 / 82 contre les T3) :
max_hp 700 -> 615 proposé, pas testé. Le lanceur **Bramblesage + Thornling** est à 46 / 7 / 14 (pire entrée à pop, déjà
connu) : on ne le change pas ici, il se juge en armée mixte (`caster_ab.md`).

## Ce qu'il faut retenir
- **Les T3 écrasent les T1/T2** : 6 des 8 T3 gagnent 95-100 % contre le champ T1/T2 à cristaux égaux (Shardguard 76,
  Briar Roc 77). C'est peut-être voulu (prime de tech), mais à décider côté design.
- **Entre T3** : Juggernaut (100) et Veilborn Dreadrider (76) dominent; Juggernaut bat Veilborn 20/20 et Sunforge 17/20
  en duel de 20 graines. Shardguard perd 0/20 contre Sunforge et contre Glade Outrider : son Hold the Line (gel de 1 s,
  une fois aux 10 s) ne suffit pas à en faire un anti-cavalerie. Ashveil Saboteur est à 0 de front (exempté : espion).
- **Par royaume** (`kingdoms.csv`) : Nature est le plus faible (45 / 38 / 42, T1 à 26 à pop), Shadow le plus fort
  (56 / 53 / 54). Les résultats T1/T2 concordent avec la passe du 2026-10-06 (Rimeshield, Shade, Greenheart, Snowdrift,
  Bramblehorn, Rime Colossus déjà nommés « prochains candidats »).
- **Leçon de l'A/B** : -15 % de PV seuls règlent le score à cristaux mais à peine celui à pop. Pour les unités fortes par
  pop, il faut PV + dégâts, ou la pop elle-même (mais +1 pop sur une unité à 1 pop est un gros coup : Vinelasher 97 -> 32).

## Fichiers
`units.csv`, `matchups.csv`, `kingdoms.csv`, `build_sheet.py` (regénère les trois CSV), `validate/` (variantes A/B
`sheet_suggested.json` et `sheet_round2.json`, specs focus, `before_after*.csv`, scorecards), `duels/` (4 duels de 20
graines), `raw_*/` (scorecards des matrices). Le `.gdignore` empêche Godot d'importer les CSV comme traductions.

## T3 game changers + outliers T1/T2 (2026-10-11, passe appliquée)

Décision de JS : « T3 should be game changers ». Les T3 gardent leur prime contre les T1/T2 (aucun nerf vers les T1/T2);
on les équilibre **entre eux**. Cible : chaque T3 >= 85 contre le champ T1/T2 et 40-60 dans le champ T3, à cristaux égaux
**et** à pop égale. JS a aussi approuvé les changements T1/T2 de la feuille (top 10 + `suggested_change`) : même passe,
cible 30-70 contre le champ T1/T2 (exemptions de rôle comme avant). **Les valeurs sont maintenant dans `data/units/*.tres`**
(31 fichiers, 56 champs, écrits une seule fois à la fin) et `units.csv` / `matchups.csv` / `kingdoms.csv` ont été regénérés
à partir des matrices refaites après le changement (l'ancienne version est dans `t3gc/before/`).

**Champ T3** : les 7 T3 de combat. L'Ashveil Saboteur (espion, 0 % de front par design) est maintenant sorti du champ T3
(`build_sheet.py`), sinon chaque T3 gagnait 1/7 gratuit. Les chiffres « avant » ci-dessous sont recalculés de la même façon.

### Ce qui a roulé (tick 60, 0 erreur de script)
- T3 seuls, 4 rondes de variantes en mémoire (`t3gc/t3gc_v1..v4`, `c..f`, `g..j`, `k..m`; 6 puis 10 graines, cristaux / pop /
  both) : environ 5 000 combats. La courbe est **très raide** : à 2 T3 contre 2 T3, 2-4 % de PV font passer un matchup de
  0/6 à 6/6 (ex. Veilborn 600 PV / 45 dégâts = 50, 580 / 42 = 6, 610 / 46 = 81).
- Candidat complet `t3gc_n` (T3 + 23 changements T1/T2) : les 55 entrées, 6 graines, les trois budgets (26 730 combats) et
  `mix_line_check` (24 graines par bras). La ronde 2 T1/T2 vient de ces résultats.
- Après l'écriture dans les `.tres` : les mêmes trois matrices complètes (6 graines, `unit-lab-t3gc_after_<budget>`), 6 graines
  de plus pour les T3 entre eux (12 au total) et `mix_line_check`. Les tableaux ci-dessous viennent de ces runs.

### Bogues trouvés
- **Briar Roc : pas de bogue de ciblage ni de vol.** Dans les JSONL, le Roc fait 14,8 DPS par oiseau vivant (son DPS de base,
  12,9, plus Seed Storm) : il attaque normalement et les unités au sol le frappent comme prévu. Il était juste trop faible :
  12,9 DPS et 735 PV effectifs pour 380 cristaux, contre 31 DPS pour le Glade Outrider au même prix. +PV ou 18 -> 23 dégâts
  ne suffisaient pas (le seuil est autour de 30 dégâts). Une portée de 6 au lieu de 4 n'a rien changé (variante `t3gc_v4`).
- **Shardguard : Hold the Line ne pouvait jamais se déclencher en vrai combat** (corrigé dans `scripts/units/t3_unit_ability.gd`).
  Il fallait un ennemi à plus de 7,5 m/s (plus vite que tous les cavaliers T3 : 6-7,6) **et** à moins de 2,4 m, alors qu'un
  cavalier de mêlée s'arrête à sa propre allonge (2,1-2,2 m + les deux rayons, environ 3,5 m). Maintenant : 5,8 m/s et une
  zone = l'allonge de l'attaquant de mêlée + 0,9 m (un tick d'avance). Le reste ne change pas (gel 1 s, une fois aux 10 s;
  `test_t3` passe toujours).

### T3 : valeurs et scores (champ T3 sans le Saboteur; c / p / b = cristaux / pop / both; 12 graines entre T3)
| T3 | Changement | Champ T3 avant | Champ T3 après | vs T1/T2 avant | vs T1/T2 après |
|---|---|---|---|---|---|
| Frostcrown Juggernaut | PV 780 -> **665**, armure 35 -> **24**, dégâts 40 -> **38** | 100 / 96 / 92 | **51 / 68 / 57** | 100 / 100 / 100 | **98 / 100 / 100** |
| Sunforge Cataphract | PV 700 -> **625** | 75 / 83 / 83 | **79 / 67 / 71** | 100 / 100 / 100 | **100 / 100 / 100** |
| Veilborn Dreadrider | PV 650 -> **600**, dégâts 46 -> **45** | 72 / 71 / 75 | **56 / 51 / 51** | 100 / 100 / 100 | **100 / 100 / 100** |
| Nightblood Reaver | aucun | 53 / 46 / 50 | **56 / 15 / 56** | 99 / 97 / 100 | **99 / 100 / 100** |
| Glade Outrider | PV 520 -> **620**, armure 10 -> **15**, dégâts 34 -> **37** | 33 / 38 / 33 | **39 / 38 / 42** | 95 / 96 / 91 | **100 / 100 / 100** |
| Shardguard | pop 3 -> **2**, dégâts 18 -> **22**, PV 440 -> **470** | 14 / 0 / 8 | **35 / 67 / 38** | 76 / 53 / 60 | **99 / 100 / 100** |
| Briar Roc | dégâts 18 -> **31**, PV 700 -> **820**, armure 5 -> **13** | 3 / 17 / 8 | **35 / 44 / 36** | 77 / 84 / 79 | **100 / 100 / 100** |

- **Game changers : réussi.** Les 7 T3 battent maintenant 98-100 % du champ T1/T2 aux trois budgets (Shardguard et Briar Roc
  étaient à 53-84). L'écart entre T3 passe de 3-100 à 35-79 (cristaux).
- **Entre T3 : pas encore tous dans 40-60.** Juggernaut, Veilborn et Reaver (cristaux / both) sont dedans. Restent :
  - Sunforge 79 / 67 / 71 : à 610 PV, le candidat donnait 39 / 47 / 44; à 625 PV, 79 (courbe raide + bruit de ± 10).
    Prochaine étape : max_hp 625 -> **615**.
  - Briar Roc 35 / 44 / 36 et Shardguard 35 / 67 / 38 : à 32 dégâts, le Roc donnait 61-67. Prochaine étape : Roc
    attack_damage 31 -> **32**; Shardguard max_hp 470 -> **480** (à pop, il est déjà à 67).
  - Glade Outrider 39 / 38 / 42 : armor 15 -> **16** ou attack_damage 37 -> **38**.
  - Nightblood Reaver 56 / **15** / 56 : limite de structure, pas de stats. À pop égale, c'est 4 Reavers (pop 3, 1 040 c)
    contre 3 T3 de pop 4 (1 200 c); à cristaux égaux, 3 contre 2 (780 c contre 800). Monter ses stats le pousse au-dessus
    de 70 à cristaux, et changer son coût ne change pas les nombres (3 contre 2 de 260 à 300 c). Seule la pop règle ça
    (décision de design : pop 3 -> 4 avec un prix et des stats de T3 cavalier).

### T1/T2 : valeurs et scores (champ T1/T2, 6 graines)
| T1/T2 | Changement | Avant (c / p / b) | Après (c / p / b) |
|---|---|---|---|
| Flame Guard | PV 120 -> **105**, dégâts 11 -> **10** | 73 / 80 / 86 | 70 / 78 / 84 |
| Blaze Rider | PV 220 -> **205**, dégâts 18 -> **17** | 67 / 73 / 78 | 68 / 82 / 85 |
| Pyre Adept | PV 80 -> **65**, dégâts 10 -> **9** | 76 / 93 / 73 | 72 / 95 / 75 |
| Cinder Arbalest | dégâts 20 -> **18**, coût 135 -> **125** | 30 / 79 / 40 | 29 / 89 / 46 |
| Pyrehoof Lancer | PV 320 -> **305**, dégâts 28 -> **25** | 57 / 74 / 71 | 57 / 73 / 74 |
| Rimeshield | PV 150 -> **140** | 89 / 94 / 96 | 92 / 96 / 96 |
| Snowdrift Rider | PV 240 -> **200**, dégâts 15 -> **14** | 83 / 77 / 84 | 71 / 69 / 73 |
| Rime Colossus | PV 520 -> **410**, dégâts 28 -> **24** | 77 / 92 / 86 | 60 / 76 / 74 |
| Frost Mortar | PV 160 -> **135**, dégâts 26 -> **24** | 76 / 76 / 76 | 67 / 73 / 74 |
| Rimehorn Rider | PV 320 -> **300**, dégâts 24 -> **22** | 61 / 75 / 80 | 61 / 75 / 84 |
| Bramblehorn | PV 380 -> **305**, dégâts 18 -> **15** | 80 / 95 / 95 | 54 / 82 / 75 |
| Vinelasher | pop 1 -> **2**, coût 120 -> **135**, PV 170 -> **180** | 69 / 98 / 86 | 67 / 33 / 43 |
| Greenheart Oathkeeper | PV 300 -> **245**, dégâts 15 -> **14** | 87 / 73 / 89 | 72 / 65 / 78 |
| Thornback Charger | PV 360 -> **345**, dégâts 25 -> **23** | 62 / 73 / 71 | 60 / 75 / 82 |
| Shade | PV 110 -> **100** | 88 / 73 / 74 | 87 / 82 / 86 |
| Gloam Rider | PV 240 -> **215**, dégâts 16 -> **15** | 68 / 79 / 82 | 68 / 79 / 83 |
| Shadow Knight | PV 480 -> **400**, dégâts 26 -> **24** | 76 / 77 / 86 | 59 / 67 / 72 |
| Barrow Knight | dégâts 30 -> **26** | 61 / 73 / 79 | 64 / 78 / 81 |
| Hollow Oathsworn | PV 200 -> **185** | 51 / 63 / 67 | 63 / 78 / 86 |
| Grave Hound | coût 70 -> **75** | 69 / 43 / 47 | 67 / 44 / 51 |
| Rimeling (swarm : jugé sur b) | PV 65 -> **70** | 70 / 13 / 29 | 88 / 15 / 32 |
| Emberdart Harrier | dégâts 14 -> **15** | 35 / 28 / 43 | 37 / 34 / 42 |
| Rime Harrier | dégâts 13 -> **14** | 36 / 23 / 42 | 37 / 32 / 43 |
| Bramble Harrier | PV 165 -> **195** | 33 / 18 / 36 | 40 / 33 / 43 |
| Duskbolt Harrier | dégâts 15 -> **16** | 35 / 29 / 41 | 35 / 29 / 42 |

- **À cristaux égaux**, presque tout est rentré dans 30-70 ou tout près (Bramblehorn 80 -> 54, Greenheart 87 -> 72, Rime
  Colossus 77 -> 60, Shadow Knight 76 -> 59, Snowdrift 83 -> 71, Vinelasher 69 -> 67, harriers 33-36 -> 35-40).
- **À pop égale**, beaucoup d'unités non exemptées restent à 73-96. C'est en bonne partie le champ : 12 entrées exemptées
  (archers, soutien, siège, Hexweaver) font 0-35 à pop et tirent la moyenne des autres vers le haut. Les unités chères à
  1 pop (Pyre Adept 95, Cinder Arbalest 89, Rimeshield 96) sont fortes par le prix de la pop, pas par leurs stats : à juger
  sur `both` ou en armée mixte.
- **Rimeshield et Shade** ont reçu exprès un nerf léger (PV seulement) : le candidat `t3gc_n` (-10 % PV et -1 dégât) faisait
  tomber le mix Ice de 57 à 38 et le mix Shadow de 51 à 33 dans `mix_line_check`. Seuls de front, ils restent forts (92 / 87).
- Nouveaux cas créés par la hausse du champ : Hollow Oathsworn 51 / 63 / 67 -> 63 / 78 / 86 (PV 200 -> 185 n'a pas suffi),
  Stagrunner 49 -> 71 à cristaux, Rimecarver + Rimeshield 57 -> 68 / 77 / 82 (entrée lanceur).

### Armées mixtes (`mix_line_check`, 24 graines par bras; score d'un royaume = moyenne de ses 3 bras)
| | Fire | Ice | Nature | Shadow |
|---|---|---|---|---|
| Avant (HEAD du 2026-10-10) | 60 | 57 | 32 | 51 |
| Candidat `t3gc_n` (nerf plus fort de Rimeshield / Shade) | 72 | 38 | 57 | 33 |
| **Après (valeurs écrites)** | **38** | **54** | **67** | **42** |

Le nerf du Flame Guard (120 -> 105 PV, 11 -> 10 dégâts) fait passer Fire du plus fort au plus faible des mixes, et Nature
(rien de changé dans son mix : Thornling, Burr Slinger, Bramblesage) monte parce que les autres ont baissé. Prochaine étape
proposée : Flame Guard max_hp 105 -> **115** (garder 10 dégâts), puis refaire `mix_line_check`.

### Unit Guide
Claims devenus faux, corrigés dans `data/ui/unit_guide.json` (+ le français dans `data/i18n/fr/unit_guide.po` et le gabarit
`data/i18n/en/unit_guide.pot`) : Juggernaut (« Highest HP / Most armour in any army » -> plus de PV de l'armée de Glace +
« Every hit chills its target »), Shardguard (meilleurs PV par cristal **de Glace**, « Low damage for a tier-3 unit »),
Briar Roc (« Short reach for a ranged unit »), Bramblehorn, Greenheart Oathkeeper, Shadow Knight, Stagrunner et Thornback
Charger. `test_unit_guide` passe (70 unités).

### Tests
`test_unit_guide`, `test_t3`, `test_tiers`, `test_stables`, `test_unit_lab` (74 checks) et `test_data_lab` : PASS. Le Data Lab
sur les vraies données garde 3 FAIL T8 dans `campaign.po` (textes de campagne d'un autre chantier, pas de cette passe).

### Fichiers (`t3gc/`)
`t3gc_final.json` (les valeurs écrites, format variante), `make_variants.py` + `r2..r5.json` + `t3gc_*.json` (toutes les
variantes essayées), `score.py` (score par entrée, champ jugé), `compare.py` -> `before_after_t3gc.csv` (avant / après, les
trois budgets, T3 aussi contre T1/T2), `after_cost/`, `after_pop/`, `after_both/`, `after_mix/`, `mix_n/` (scorecards) et
`before/` (les CSV de la feuille avant la passe). JSONL : `..\four-wizards-lab-runs\unit-lab-t3gc_*`. Pour refaire la feuille
d'après : `SHEET_TAG=unit-lab-t3gc_after_ python build_sheet.py`.

## Ronde 2 (2026-10-11, appliquée)

Suite de la passe « T3 game changers » : les « prochaines étapes » ci-dessus, essayées en variantes
(`t3gc/round2/r2_a..d.json`, en mémoire), puis écrites une seule fois dans `data/units/*.tres` (7 fichiers).

| Unité | Changement | Pourquoi |
|---|---|---|
| Sunforge Cataphract | max_hp 625 -> **615** | 79 dans le champ T3 |
| Briar Roc | attack_damage 31 -> **32** | 35 dans le champ T3 |
| Shardguard | max_hp 470 -> **480** | 35 à cristaux |
| Glade Outrider | armor 15 -> **16** | 39 dans le champ T3 |
| Flame Guard | max_hp 105 -> **115** (dégâts 10 gardés) | mix Fire à 38 |
| Hollow Oathsworn | max_hp 185 -> **175**, attack_damage 17 -> **16** | 63 / 78 / 86 (dégâts 16 seuls : 57 / 63 / 76; les deux : 51 / 61 / 71) |
| Nightbolt | max_hp 65 -> **70** (comme l'Ember Archer) | mix Shadow à 36-39 avec le Flame Guard à 115 |

### T3 entre eux (champ T3 sans le Saboteur; c / p / b)
24 graines par paire : 12 de la variante `r2_a` (mêmes valeurs T3) + 12 sur les valeurs écrites (graines 1-6 de la matrice
complète, 7-12 en T3 seuls). Sur les 12 graines écrites seules : Veilborn 53 / 51 / **35**, Shardguard 43 / **82** / 47
(bruit de ± 10 par entrée à 12 graines, la courbe reste raide).

| T3 | Ronde 1 (12 graines) | **Ronde 2 (24 graines)** | vs T1/T2 (c / p / b) |
|---|---|---|---|
| Frostcrown Juggernaut | 51 / 68 / 57 | **42 / 51 / 47** | 98 / 100 / 100 |
| Sunforge Cataphract | 79 / 67 / 71 | **51 / 55 / 51** | 100 / 100 / 100 |
| Veilborn Dreadrider | 56 / 51 / 51 | **46 / 52 / 44** | 100 / 100 / 100 |
| Nightblood Reaver | 56 / 15 / 56 | **59 / 16 / 58** | 99 / 100 / 100 |
| Glade Outrider | 39 / 38 / 42 | **50 / 47 / 45** | 100 / 100 / 100 |
| Shardguard | 35 / 67 / 38 | **43 / 75 / 47** | 98 / 100 / 100 |
| Briar Roc | 35 / 44 / 36 | **58 / 54 / 57** | 100 / 100 / 100 |

- **Cristaux et both : les 7 T3 sont dans 40-60.** Tous restent >= 98 contre le champ T1/T2.
- **À pop égale, deux limites de structure, en miroir** : le Reaver (pop 3 : 4 Reavers contre 2 T3 de pop 4, voir plus haut)
  à 16, et le Shardguard (pop 2 : 4 Shardguards contre 2 T3) à 75. Ses stats ne règlent pas ça (67 à 470 PV, 75-82 à 480).
  Si on veut les deux dans 40-60 à pop, c'est une décision de pop (Reaver 3 -> 4, Shardguard 2 -> 3 avec un prix plus bas).

### T1/T2 touchés (champ T1/T2, 6 graines)
| T1/T2 | Ronde 1 (c / p / b) | Ronde 2 |
|---|---|---|
| Flame Guard | 70 / 78 / 84 | 77 / 87 / 91 (voulu : le mix d'abord) |
| Hollow Oathsworn | 63 / 78 / 86 | **50 / 64 / 68** |
| Nightbolt (archer, exempté) | 18 / 22 / 26 | 21 / 23 / 26 |

Les autres T1/T2 bougent de moins de 4 points (seules leurs cases contre ces trois unités changent).
Moyennes par royaume (`kingdoms.csv`, tous tiers) : Fire 45 / 54 / 47, Ice 49 / 58 / 54, Nature 48 / 35 / 43, Shadow 54 / 49 / 53.

### Armées mixtes (`mix_line_check`)
| | Fire | Ice | Nature | Shadow |
|---|---|---|---|---|
| Ronde 1 (valeurs écrites) | 38 | 54 | 67 | 42 |
| Variante `r2_a` (Flame Guard 115, Nightbolt 65) | 52 | 52 | 57 | **39** |
| **Ronde 2 écrite (48 parties par bras)** | **58** | **46** | **54** | **42** |

Les 4 mixes sont dans 40-60. Le bras le plus déséquilibré reste fire.shadow (Fire 81 %). Le run se répète mal d'une fois
à l'autre (mêmes valeurs, 24 graines : Shadow 47 puis 36) : jugez sur les 48 parties.

### Méthode et fichiers (`t3gc/round2/`)
`r2_a..d.json` (variantes), `before_r2/` (les CSV de la feuille avant la ronde 2), `t3_*`, `focus_*`, `after_mix/`
(scorecards), `focus_merge.py` (A/B d'une liste d'unités contre la matrice complète), `merge_runs.py`, `mix_score.py`.
Les matrices complètes n'ont pas été rejouées : `merge_runs.py` garde les cases de la matrice « after » qui ne touchent aucune
des 7 unités changées et ajoute un run `-Focus` de ces 7 unités (toutes leurs paires, 6 graines, 3 budgets) sur les
valeurs écrites; les autres unités n'ayant pas changé, c'est équivalent à rejouer la matrice. JSONL :
`..\four-wizards-lab-runs\unit-lab-t3gc_rnd2_*` (+ `_t3x`), `unit-lab-t3gc_r2*`. Pour refaire la feuille :
`python t3gc/round2/merge_runs.py` puis `SHEET_TAG=unit-lab-t3gc_rnd2_ python build_sheet.py`.

### Escarmouche bot contre bot après les deux rondes (faster-games, normal, Crown Hollow)
`run_fg.py --run r2units --arms baseline --levels normal --seeds 1-2 --tick 60` : 12 paires ordonnées x 2 graines, 24 parties,
12 par royaume (± 14 points). Référence : `fg-icebot` (2026-10-10, même protocole, avant la passe d'unités; le code a aussi
bougé entre les deux, donc l'écart n'est pas que la passe).

| Royaume | `fg-icebot` (10-10) | **Après la ronde 2** |
|---|---|---|
| Fire | 9 / 12 (75 %) | 8 / 12 (67 %) |
| Ice | 5 / 12 (42 %) | **1 / 12 (8 %)** |
| Nature | 8 / 12 (67 %) | 8 / 12 (67 %) |
| Shadow | 2 / 12 (17 %) | **7 / 12 (58 %)** |
| Durée médiane | 14:21 | 16:11 |

Ice ne gagne qu'une partie (nature-ice s1, côté ennemi); il perd ses 4 parties contre Fire au score anticipé. Les nerfs Ice de
la ronde 1 (Rimeshield, Snowdrift, Rime Colossus, Frost Mortar, Rimehorn, Juggernaut) sont le suspect n° 1, à confirmer avec
plus de graines. Shadow remonte de 17 à 58 %.

### Sims de campagne (une fois chacune, normal)
PASS : e4m1 (22:01), e4m3 (22:03), e4m3_rush (28:11), e4m4 (23:35), e6m3 (16:01), e7m4 (23:51), e8m1_nature.
e4m2 (temps écoulé) et e7m1 (défaite à 20:48, 1 enchère sur 3) ont échoué au premier passage, sous une charge de 4 Godot;
relancés une fois : **PASS** (e4m2 17:24, 40 / 40; e7m1 22:46, 3 enchères sur 3, les mêmes temps que la revue du 10-11).
e3m1 : FAIL (temps écoulé), le bogue de test déjà connu (`docs/reviews/campaign-notes-2026-10-11.md` : le joueur scripté
reste en « regroup », seuil `REGROUP_LEAVE = 32` inatteignable), pas cette passe.

### Unit Guide
Glade Outrider (armure 16) passe le Greenheart Oathkeeper (15) : « Most armour in the Nature army » du Greenheart devient
« Top 3 for armour in the Nature army » (`data/ui/unit_guide.json`, chaîne déjà traduite; références mises à jour dans
`data/i18n/fr/unit_guide.po` et `data/i18n/en/unit_guide.pot`). `test_unit_guide` passe (70 unités).

### Tests (ronde 2)
`test_unit_guide`, `test_t3`, `test_tiers`, `test_unit_lab`, `test_data_lab` : PASS (le Data Lab sur les vraies données garde
ses 3 FAIL T8 déjà connus dans `campaign.po`).

## Ice en escarmouche après les deux rondes (2026-10-11, rien d'appliqué)

Le run `fg-r2units` donnait Ice à 1 / 12. Refait plus gros : faster-games, normal, **Crown Hollow + Thornwater**, les 12 paires
x 4 graines (96 parties, 48 par royaume, ± 13 points), puis des bras A/B sur les 6 paires avec Ice (24 à 48 parties Ice par
bras). Variantes et vérifs Unit Lab : `t3gc/icefix/`. Runs : `..\four-wizards-lab-runs\fg-icefix-ch`, `fg-icefix-tw`.

### Ce qu'on a trouvé
- **Ice est à 23 % (11 / 48), pas à 8 %.** Le 1 / 12 était surtout du bruit sur un bot Ice déjà faible (le 42 % du 10-10 aussi,
  dans l'autre sens). Ice contre Nature : 1 / 16 dans **tous** les bras.
- **Les nerfs Ice de la ronde 1 n'expliquent qu'une petite partie.** Tout remettre (`ice_rev_all`) : 31 %; seulement le Frost
  Hall du bot, Rimeshield 150 PV + Rime Colossus 520 / 28 (`ice_rev_hall`) : 33 %; les unités Stables / T3 / Forge ne changent
  rien (le bot en fait peu). La part du score d'Ice en fin de partie reste à 42-45 % dans **tous** les bras (43,6 en base) :
  aucun changement d'unité ne bouge vraiment la partie.
- **La vraie cause est l'économie du bot Ice** : à 10:00, -1 100 cristaux récoltés et -6 de pop d'armée contre l'adversaire,
  dans chaque bras; environ 2 attaques par partie (Nature 6,8, Fire 4,5), beaucoup de blocages « defending ». Les tours plus
  tard (S1 5:00 / S2 8:00, `ice_towers`) : 25 %, rien.
- **Remonter le Colossus casse la feuille** (focus Unit Lab, 6 graines, contre la matrice de la ronde 2) : 480 / 28 donne
  80 / 96 / 91 (c / p / b, avant 60 / 78 / 73), 450 / 26 donne 73 / 94 / 86. Rimeshield 150 PV ne bouge presque pas
  (92 / 96 / 96 -> 94-95 / 98 / 98). Donc pas de changement d'unité.

### Meilleur candidat, essayé puis **pas gardé**
Mix du Frost Hall du bot Ice (`AIProfile.ice()` + `data/ai/ice_{easy,normal,hard}.tres`) : Rimeshield / Shardcaster /
Rime Seer / Rime Colossus **35 / 30 / 0 / 35** dans les trois cas (aujourd'hui 40 / 30 / 10 / 20, contre ranged 50 / 20 / 10 / 20,
contre mêlée 30 / 40 / 15 / 15) : bras `ice_f6`. Aucune stat d'unité touchée, donc matrices Unit Lab et `mix_line_check`
inchangées. Les tests demandés passaient avec ce mix (`test_unit_guide`, `test_unit_lab`, `test_tiers`, `test_8_b3`,
`test_casters_bots`). Il n'est **pas** gardé : il fait passer Ice de 23 à 31 % mais Shadow de 42 à 31 %, donc un seul royaume
dans 35-65 au lieu de deux. Le code et les données sont revenus à leurs valeurs d'avant.

### Base contre `ice_f6` (normal, CH + TW, 4 graines; `ice_f6` = ses parties Ice + les parties sans Ice de la base)
| Royaume | `fg-r2units` (CH, 2 graines) | Base (96 parties) | `ice_f6` | CH base -> f6 | TW base -> f6 |
|---|---|---|---|---|---|
| Fire | 67 % | 71 % (34 / 48) | 73 % (35 / 48) | 58 -> 63 | 83 -> 83 |
| Ice | 8 % | 23 % (11 / 48) | **31 % (15 / 48)** | 17 -> 38 | 29 -> 25 |
| Nature | 67 % | 65 % (31 / 48) | 65 % (31 / 48) | 67 -> 67 | 63 -> 63 |
| Shadow | 58 % | 42 % (20 / 48) | 31 % (15 / 48) | 58 -> 33 | 25 -> 29 |

Autres bras (parties Ice) : `ice_f3` (même mix + Rimeshield 150 + Colossus 480 / 28) 29 %, `ice_f1` (Rimeshield 150, mix sans
Seer 40 / 40 / 0 / 20) 22 %, `ice_f2` 22 %, `ice_comp_noseer` 25 %, `ice_f4` / `ice_f5` (+ Shardcaster 10 dégâts) 8-9 % sur
13 parties (arrêtés).

### Cible 35-65 : pas atteinte, rien d'appliqué
- Avec `ice_f6`, Ice 31 % et Shadow 31 % restent sous 35; dans la base, Ice 23 % (le gain d'Ice vient surtout de Shadow : 6 -> 11 victoires d'Ice sur 16). Fire est à 71-73 %
  à cause de **Thornwater** (20 / 24, problème déjà noté dans `docs/balance/blitz_2026-10-10.md`), pas d'Ice.
- Avec ± 13 points par royaume, aucun changement d'unité ou de mix testé ne passe Ice au-dessus de 35 de façon fiable. La suite
  est côté bot (ai-coder) : l'économie d'Ice avant 7:00 et le nombre d'attaques, puis Fire sur Thornwater.

## Économie du bot Ice (2026-10-11, appliqué)

Suite de la section d'avant : la cause est côté bot, pas côté unités. Aucune stat d'unité touchée (`data/units` intact,
feuille Unit Lab inchangée).

### La cause
Les journaux du bot (`--log=1`) et les stats par minute des 96 parties de base (`fg-icefix-ch` / `-tw`) montrent que le bot
Ice prend son expansion **trop tard** :
- Mêmes 6 travailleurs que les autres jusqu'à X1, mais X1 posé à 4:30-5:20 et fini à 5:25-6:00 (Frost Hall : 54 s), contre
  4:20-4:40 / 4:50-5:15 pour Fire, Shadow et Nature. Les 3 travailleurs de plus (cible 9) arrivent donc ~45 s plus tard.
- Avant X1, la banque d'Ice flotte (290-530 cristaux vers 2:30-3:20) : le Frost Hall lent ne la dépense pas. La règle des Halls
  en plus (7bf098b9) la dépensait sur **H2** à ~2:00 (150 cristaux + un bâtisseur 54 s), placé **avant** S1 et X1 dans l'ordre
  des rangées, ce qui repoussait encore X1.
- Résultat (Ice moins l'adversaire, base) : cristaux récoltés -90 à -135 à 5:00, -370 à -460 à 7:00, -840 à -850 à 10:00
  contre Fire / Shadow; contre Nature (7 travailleurs, X1 4:30) -590 / -1 490 / -2 180. Les travailleurs morts d'Ice viennent
  surtout de 6:00-8:00 (2,0 par partie, le héros ennemi 1,3) : la naturelle prise en retard, quand l'ennemi attaque déjà.
- Les règles de sécurité des travailleurs (ccb9227b) ne sont pas la cause : rien dans les journaux ne montre Ice sautant ses
  nœuds plus que les autres avant 7:00.

### Le changement (Ice normal et difficile seulement; facile, Fire, Shadow, Nature : rien ne change)
Trois nouveaux boutons `AIProfile` (défaut = comportement d'avant), réglés dans `AIProfile.ice()` et `data/ai/ice_{normal,hard}.tres` :
- `expand_bank = 300` : X1 se déclenche aussi dès que la banque tient 300 cristaux (en pratique ~2:30-3:00); `expand_time`
  reste 5:30 en filet.
- `expand_first = true` : un X1 dû passe avant toutes les autres rangées (maisons, Halls en plus, tours).
- `extra_hall_after_x1 = true` : H2 / H3 attendent que X1 soit fini.
- `worker_target_home` 6 -> 7 (comme Nature; expansion / X2 inchangés 9 / 12).

Code : `scripts/ai/commander.gd` (`_next_row`, `_row_trigger` X1, `_extra_hall_due`). Outil : `fg_match.gd` accepte
`"fg": {"ai_kingdom": {"ice": {...}}}` (boutons d'un seul royaume, pour les bras A/B).

### Résultats (normal, Crown Hollow + Thornwater, 6 paires avec Ice x 4 graines = 48 parties Ice; parties sans Ice = la base)
| Royaume | Base | `ie_e` (le changement + X1 4:30) | `ie_e6` (`ie_e` + mix `ice_f6`) | **Appliqué** (`fg-iceeco2`) |
|---|---|---|---|---|
| Fire | 71 % (CH 58 / TW 83) | 60 % | 75 % | **67 %** (62 / 71) |
| Ice | 23 % (17 / 29) | 44 % | 38 % | **40 %** (38 / 42) |
| Nature | 65 % (67 / 62) | 58 % | 54 % | **58 %** (58 / 58) |
| Shadow | 42 % (58 / 25) | 38 % | 33 % | **35 %** (42 / 29) |
| Ice récolté à 10:00 contre l'adversaire | -21 % | +10 % | +6 % | **+6 %** |
| Attaques d'Ice par partie | 1,8 | 3,2 | 3,2 | 2,8 |

Ice contre l'adversaire (appliqué, cristaux récoltés 5:00 / 7:00 / 10:00) : contre Fire +370 / +770 / +500 (6 / 16), contre
Shadow +420 / +840 / +890 (9 / 16), contre Nature -160 / -350 / -480 (4 / 16, était 1 / 16 et -2 180 à 10:00).
- **Ice passe de 23 à 40 %**, dans 35-65, et son économie rattrape (de -21 % à +6 % à 10:00).
- Fire baisse (71 -> 67, toujours au-dessus à cause de Thornwater, 71 % là), Nature 65 -> 58. Shadow 42 -> 35, au bord :
  le gain d'Ice contre Shadow (6 -> 9 sur 16) lui coûte 3 victoires. ± 13 points par royaume.
- Le mix `ice_f6` en plus n'aide pas (Ice 38 %, Fire 75 %, Shadow 33 %) : **pas appliqué**.
- La différence `ie_e` (X1 au plus tard 4:30) / appliqué (5:30) est dans le bruit : la banque déclenche X1 avant dans tous
  les journaux; `expand_time` 330 reste pour `test_8_b3`.

### Reste à faire
Ice contre Nature reste à 4 / 16 : Nature attaque ~5 fois de plus par partie et Ice perd ses travailleurs de 6:00 à 8:00
(héros ennemi). C'est la défense de la naturelle, pas l'économie. Shadow est à surveiller (35 %).

### Tests
`test_casters_bots`, `test_tiers`, `test_7_a1`, `test_mt10_bot_slots`, `test_2_a1_rules`, `test_8_b3` : PASS.
Variantes : `t3gc/icefix/ie_e.json`, `ie_e6.json`. Runs : `..\four-wizards-lab-runs\fg-iceeco-ch|tw` (bras `ie_e`, `ie_e6`), `fg-iceeco2-ch|tw` (le code appliqué).
