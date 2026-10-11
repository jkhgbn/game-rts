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
