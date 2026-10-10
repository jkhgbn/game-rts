# Suggestions pour Four Wizards, 2026-10-10

Regard indépendant sur tout le projet, en lecture seule. J'ai lu CLAUDE.md, les notes de reprise, jss_asks.md,
campaign-outline.md, review-2026-10-08.md, blitz_2026-10-10.md, faster_games_2026-10-08.md, test-hygiene.md et
save-load.md, plus le git log des 10 derniers jours (213 commits). Pour le code et les tests, j'ai pris un échantillon
(tailles de fichiers, noms de fonctions, liste des tests lents). Je n'ai lancé ni Godot ni les tests. Les chiffres
viennent des docs ou de `wc`, `git status` et `grep`. Quand c'est une impression, je l'écris.

## 1. Ce qui est fort aujourd'hui

- **Le contenu est énorme pour l'âge du projet.** Les 33 missions des 8 épisodes sont bâties, avec embranchements,
  choix de fin, fin sombre et générique. Les films sont enchaînés de l'ep1 à l'ep8, les voix Kokoro couvrent presque
  tout et le français est complet. La campagne est estimée à ~13 h sans défaite et ~16 h au premier passage.
- **Les outils de mesure sont rares pour un jeu indé** : Balance Lab, Unit Lab (duels et matrices), Bot Lab, Map Gate
  avec prédicteur d'équilibre, Game Health (77.6 au premier passage), Playtest Recorder, Replay. Les décisions
  d'équilibrage reposent sur des chiffres (Blitz : 554 parties bot contre bot).
- **Il y a beaucoup de tests et ils sont réfléchis** : 451 fichiers de test (~127 k lignes), une CI rapide
  `-Changed`, des règles pour que le timing ne dépende pas de la charge (test-hygiene.md) et la liste des tests liés aux
  chiffres d'équilibrage.
- **Les systèmes de confort sont déjà là** : sauvegarde en cours de partie (3 emplacements + rapide), Unit Guide (70
  unités), paramètres (volumes, plein écran, FSR 1/2, échelle de l'UI), touches physiques AZERTY, rythme Normal /
  Rapide / Blitz.
- **Un vrai processus de revue** : 63 problèmes confirmés le 10-08, les graves corrigés le jour même.

## 2. Top 10, classé par impact pour le joueur

| # | Suggestion | Pourquoi | Effort | Risque |
|---|---|---|---|---|
| 1 | **Une vraie partie de test de la campagne par JS, épisode par épisode, avec un build play4 figé** | Les épisodes 4 à 8 (21 missions) ont été bâtis entre le 10-08 et le 10-09. Ils ne sont validés que par des joueurs scriptés (`*_sim`, `*_passive_sim`). Les dernières notes de playtest (`docs/plan/playtest-notes.md`) datent de l'étape 11 (commerce). Aucun humain n'a fini une mission de l'ep4 ou plus. Un bot scripté ne voit pas une mission ennuyante, un objectif pas clair ou un pic de difficulté. | Moyen (surtout le temps de JS ; un build + un formulaire court par mission) | Faible |
| 2 | **Corriger Ice (bot) avant tout le reste de l'équilibrage** | Ice est dernier dans chaque mesure : 22 % en Normal (faster_games), 28 % / 22 % en Blitz, 0 % sur 18 parties avec 9 ouvriers. La cause est connue (le bot Ice ne transforme pas son revenu en armée), mais le correctif du 10-09 n'a porté que sur les Frost Halls. Tant qu'Ice est cassé, les chiffres de Blitz, de Fire et des cartes sont faussés. | Moyen (ai-coder, `scripts/ai/commander.gd`) | Moyen (commander.gd fait 3 567 lignes) |
| 3 | **Une courbe de difficulté mesurée pour la campagne** | Les tableaux donnent des durées par mission (65 à 117 min par épisode), mais aucune mesure de difficulté. La revue a aussi trouvé que la difficulté du menu n'atteignait pas les missions (corrigé le 10-08, donc les sims d'avant ont toutes tourné en Normal). Il faut un tableau par mission : taux de victoire du joueur scripté en easy / normal / hard, marge de temps, PV restants du héros. Ensuite on lisse les pics (ex. : e4m3 « rush ≥ 16 min », e2m5 ×1.6 PV du boss). | Moyen | Faible |
| 4 | **Onboarding : un vrai tutoriel interactif ou des astuces contextuelles** | Je n'ai trouvé aucun script `tutorial`. La mission 0 sert peut-être d'introduction, mais le jeu cumule beaucoup de systèmes (tiers, Forge, champions et classes, commerce et or, caravanes, essence, STR / INT, lanceurs, rivière, camps). Un nouveau joueur va décrocher. Proposition : des cartes « première fois » (un système = une carte de 2 lignes à sa première apparition) et une page Aide dans le menu pause. | Moyen | Faible |
| 5 | **Remplacer les décors provisoires des films par de vrais décors** | Plusieurs films tournent sur des décors empruntés (`forge_intro_torvald` pour Rime Keep, `forge_watch_keep` pour le camp et le lieu de parlementer, ce que les commits nomment « stand-in sets »). C'est ce que le joueur voit entre chaque mission ; ça pèse lourd sur l'impression de qualité. Il faut prioriser les 8 ouvertures et les 8 fins avant les scènes d'entre-missions. | Grand (art, Opus medium, une tâche par décor) | Faible |
| 6 | **Un build public de test (« démo ») : prologue + épisode 1 + escarmouche** | Le jeu est assez riche pour avoir des retours externes. Ce build a besoin d'un export testé (un preset Windows existe déjà, `build/FourWizards.exe`), d'un journal de plantage et des réglages graphiques de base (section 6). Dix joueurs externes trouveront plus que dix sims. | Moyen | Moyen (images publiques, droits des voix Kokoro à vérifier) |
| 7 | **Les AoE contre les lignes d'ouvriers (Fire)** | En Blitz, le sorcier Fire tue 4.7 ouvriers par partie (1.2 pour Ice) et gagne 83-100 % sur Thornwater en Normal. Ça risque de se voir aussi en Normal contre des humains : un plafond de dégâts des sorts sur les ouvriers (ou une réduction des dégâts de zone sur les ouvriers en récolte), testé dans le Balance Lab. | Petit à moyen | Moyen (touche l'équilibre global) |
| 8 | **Retours en arrière (comebacks) et fins de partie** | En Normal, la médiane est de 22:18. Le doc Blitz note que le gagnant met ~10 min à finir une base qui continue de former des soldats. Ce n'est pas du suspense, c'est de l'attente. Proposition : un bouton « abandonner » proposé au bot (ou au joueur) quand l'écart d'armée dépasse un seuil, et/ou un bonus de défense temporaire (« dernier rempart ») pour que le perdant ait une vraie chance de se relever. | Moyen | Moyen |
| 9 | **Une passe perf sur le GTX 1660 de JS** | Les mesures perf sont faites sur le laptop (RTX 3070). La note du 10-06 dit « 200 unités = 13 ms/frame ». La passe perf du 10-09 a aidé, mais rien n'a été mesuré sur le desktop ultrawide de JS (plus de pixels, GPU plus faible). Il faut lancer le Perf Lab là-bas avec FSR 2 à 67 % et à 100 %, puis choisir les préréglages par défaut. | Petit (une soirée, JS lance le script) | Faible |
| 10 | **Fusionner le Blitz et le rythme « Rapide (test) » en un choix clair** | Le menu affiche Normal / Fast (test) / Blitz. « (test) » dans un menu joueur, ça fait inachevé. Proposition : garder Normal + Blitz, ou renommer Fast en « Rapide » une fois validé par un playtest. Le x1.3 sur l'horloge du Blitz doit aussi être essayé par un humain (caméra, micro, timing des sorts). | Petit | Faible |

## 3. Santé technique

### Gros fichiers à découper (lignes, `wc -l`)
| Fichier | Lignes | Idée de découpe |
|---|---|---|
| `scripts/ai/commander.gd` | 3 567 | économie / armée / attaque / 2v2-sièges / pace knobs en modules ; c'est aussi là qu'Ice bloque |
| `scripts/ui/selection_manager.gd` | 3 349 | entrée souris / boîte de sélection / ordres / groupes de contrôle |
| `scripts/ui/selection_panel.gd` | 2 873 | panneau unité / bâtiment / multi-sélection (la revue y a trouvé des réécritures à chaque image) |
| `scripts/units/unit.gd` | 2 577 | contrat central : sortir les statuts, l'auto-cible, le mouvement |
| `scripts/units/champion_abilities.gd` | 2 240 | une classe par famille de compétences |
| `scripts/campaign/mission_e2_02.gd` | 2 212 | la plus grosse mission ; c'est elle qui avait les soft-locks |
| `scripts/ai/champion_brain.gd` | 2 056 | |
| `scripts/world/skirmish.gd` | 1 898 | |

Au total, `scripts/campaign/` fait 51 859 lignes (73 fichiers), plus que `scripts/ui/` (29 k) et `scripts/ai/` (15 k).

### Motifs dupliqués dans les missions
Des fonctions du même nom reviennent dans presque tous les fichiers `mission_*.gd` : `_on_player_hero_fell` (37),
`_objective_extra` (37), `_intro` (38), `_mission_config` (39), `_title_line` (34), `_build_map` (33),
`_refresh_wave_unit` (28), `_ground_spots` (17). Les épisodes 5 à 8 ont déjà une base par épisode
(`mission_e5_base.gd` ... `mission_e8_base.gd`), mais pas les épisodes 1 à 4. Suggestions :
- Remonter dans `MissionBase` ce qui est identique : la défaite à la chute du héros, la ligne de titre, le rafraîchissement
  des unités de vague. Ce sont trois sources de bugs déjà vues dans la revue (défaites en attente, soft-locks).
- Une fonction commune « fin de mission sûre » (victoire et défaite exclusives, pas de fin pendant un film) plutôt que
  37 versions.
- À ne pas faire en grosse refonte d'un coup : une mission à la fois, avec son `_sim` comme filet.

### Coût et instabilité des tests
- 451 fichiers de test. `tools/ci/slow_tests.txt` liste 73 tests lents, presque tous des sims de mission de 10 à 33 min
  de jeu (+ `test_save_load_missions`, ~2 bakes par mission). À l'œil, la CI complète doit prendre plusieurs heures de
  machine. Je ne l'ai pas mesuré.
- Les instabilités sont traitées au cas par cas (3 commits « fix CI flakes » en 10 jours). La cause qui reste, selon
  test-hygiene.md : l'évitement et la navigation en threads rendent les parties bot contre bot non déterministes.
- Suggestions : (a) un tableau de bord de flakiness (chaque test avec son taux d'échec sur les 20 derniers runs, à
  partir de `docs/ci/`) ; (b) les sims « passives » (`*_passive_sim`, ~20) en run nocturne seulement ; (c) une option
  de nav déterministe (single-thread) pour les tests seulement, si c'est faisable.

### Dérive de CLAUDE.md (40 Ko, 400 lignes)
- La ligne 49 dit encore que les stats sont dans `UNIT_TYPES` de `main.gd` et « moving to data/units/*.tres in task
  1.G1 ». C'est fait depuis longtemps.
- Le playbook du lead parle de « run wave N session X » et de tags `wave<N>-<session>-green` ; le travail se fait
  maintenant par demandes et labs.
- La règle d'effort (HIGH pour le code complexe, ligne ~360) contredit la règle actuelle de JS (tout en Opus MEDIUM
  depuis le 09-30, dans la mémoire du lead).
- Le playbook dit `origin` = GitHub. **Aucune remote n'est configurée dans ce dépôt** (`git remote` ne renvoie rien),
  voir plus bas.
- CLAUDE.md a des changements non commités en ce moment.
- Suggestion : CLAUDE.md à ~150 lignes (règles + contrats), les détails des labs dans leurs docs, et un passage de
  nettoyage par semaine.

### Hygiène du travail non commité (`git status`, 10-10)
- **554 fichiers modifiés et 3 081 non suivis.** Les non suivis sont surtout des sorties d'outils :
  `docs/tools/cine/out` (2 330), `docs/tools/map_gate` (260), `docs/tools/world_forge/out` (187), 6 × 46 fichiers de
  matrices Unit Lab. Les modifiés comprennent les .po/.pot, des scorecards Art Lab et **du code de jeu** : 17 fichiers
  dans `scripts/` et `tests/` (~980 lignes ajoutées), dont `mission_e3_02.gd` (+252 / −), `pace_switch.gd` et les
  sims e2m5 / e3m1 / e3m4. C'est probablement le travail d'un agent arrêté.
- Suggestions : (a) commiter ou mettre de côté ces 17 fichiers de code tout de suite, une fois vérifiés ; (b) ajouter
  `docs/tools/*/out/` et les matrices brutes au `.gitignore` (ou les sortir du dépôt, comme les runs du lab dans
  `..\four-wizards-lab-runs`) ; (c) l'agent qui finit commite son propre bloc, ou laisse une ligne dans les notes de
  reprise.
- `.git` pèse **4.6 Go**. Les sorties binaires (rendus, WAV, PNG) finissent par rendre tout clone ou toute sauvegarde
  lents. Il faudrait regarder Git LFS ou garder les gros binaires hors du dépôt.

### Push et sauvegardes
- **Pas de remote git.** La seule copie hors de la machine, c'est la sauvegarde OneDrive manuelle « LIGHT save
  2026-10-03 » (310 Mo, sans `.git` ?) et `Documents\four-wizards-backup` sur le même disque. Une semaine entière de
  campagne (ep4-ep8, films, voix) n'existe que sur le laptop. **C'est le plus gros risque du projet.**
- Suggestion : rebrancher `origin` (GitHub jkhgbn/game-rts, privé), pousser après chaque bloc vert. Si 4.6 Go c'est trop
  pour GitHub, pousser d'abord le code et les données (sans les sorties d'outils), et garder les binaires lourds en LFS
  ou sur OneDrive. Sinon, au minimum, un `git bundle` hebdomadaire copié sur OneDrive.

## 4. Contenu et finition

- **Films** : décors provisoires (Rime Keep = cour de Torvald, camp de guerre = `forge_watch_keep`, plusieurs
  accessoires simples). Le passage de cadrage du 10-08 a corrigé les caméras, pas les décors. Des « stand-in audio »
  sont encore cités pour `ep2_opening`. La liste des jss_asks de septembre (visages, cheveux, fichier Blender du château
  du prologue, personnage qui « vole » au prologue) est toujours au statut `doing`. Il faut soit les fermer, soit les
  marquer `parked` pour que la liste reste vraie.
- **Voix et textes** : presque tout est voisé (916 lignes ep4-8, 101 + 289 restantes le 10-07). Il manque un compte
  final « lignes sans WAV = 0 » par film et par mission, sous forme de test (`test_speakers` existe, à étendre ?).
  Je n'ai pas vérifié.
- **Cartes** : les cartes de mission sont bâties en code (`_build_map` dans 33 fichiers). Ça marche, mais : pas de
  retouche visuelle possible sans code, pas de passage dans le Map Gate, et chaque carte ressemble un peu aux autres.
  Suggestion : sortir les 5-6 cartes les plus vues (ep1, finales) en scènes ou layouts World Forge, pour que l'art
  puisse les retoucher.
- **Art en jeu < 90** : la liste existe (`docs/art/ingame_grade/under_90.md`), le travail n'a pas commencé (jss_asks).
  Priorité : les unités qu'on voit en spotlight de mission.
- **Escarmouche** : deux cartes vraiment prêtes (Crown Hollow ; Thornwater a encore un biais de siège à 67 / 31 / 25 %
  dans le gate du 10-04, et Fire y gagne 83-100 % en Blitz Normal). Pour un public, 3-4 cartes 1v1 validées valent plus
  que 30 cartes générées.

## 5. Gameplay et équilibre

- **Royaumes en Blitz** : objectif de durée atteint (médiane 10:57 Normal / 11:25 Hard, 53-58 % pour le premier
  attaquant). Équilibre non atteint : écart de 50-56 points (Fire 61-72 %, Ice 22-28 %). Les échantillons sont petits
  (6-9 parties par royaume et par carte, ±20 points de bruit, comme le doc le dit). Je n'appellerais pas Blitz
  « prêt » avant la correction d'Ice et un run à tick 60 avec plus de seeds.
- **Ice** : voir la suggestion n° 2. C'est le même symptôme dans trois études (06, 08, 10). La correction des Frost
  Halls (8 % → 42 % dans le lab) montre que le levier est dans le Commander, pas dans les données.
- **Champions** : la revue du 10-08 a trouvé des bugs 2v2 (Starfall, sense) qui sont corrigés. Il n'existe pas encore
  de mesure de l'impact des champions sur l'issue des parties : « Bot Lab --champions=0 » vient d'arriver (10-09). Un
  A/B avec et sans champions dirait s'ils décident trop les parties.
- **Comebacks** : en Normal, le premier attaquant gagne 58 % (bien) ; avec 9 ouvriers sans les autres réglages, 81 %
  (mal). Les fins de partie sont longues (voir la suggestion n° 8).
- **Courbe de la campagne** : les sims vérifient « gagnable par un joueur scripté efficace » et « perdue si passif ».
  C'est un bon plancher, mais ça ne dit rien de la difficulté pour un humain moyen. Les durées par épisode ne suivent pas
  une courbe : l'ep5 (65 min) est plus court que l'ep2 (117 min). Un épisode d'origines plus court est peut-être voulu,
  à confirmer avec JS. Il faudrait un indicateur simple par mission (marge du joueur scripté en easy / normal / hard) et
  une mission de respiration après chaque finale d'épisode.

## 6. Prêt pour une première version publique ?

| Besoin | État (ce que j'ai vu) | Manque |
|---|---|---|
| Réglages | Volumes (Master / Music / SFX / Voice), plein écran, FSR 1/2 + échelle de rendu, échelle UI, panoramique au bord | Je n'ai pas vu de VSync, limite de FPS, qualité des ombres ou remappage des touches (à vérifier dans `scripts/ui/menus/game_settings.gd`) ; un préréglage « Bas » pour les GPU modestes |
| Tutoriel | Mission 0, Unit Guide, panneau de touches | Pas de tutoriel interactif ni d'astuces contextuelles (suggestion n° 4) |
| Perf sur le GTX 1660 | Mesures faites sur le laptop seulement | Perf Lab sur le desktop ultrawide, à 200 unités et en mission chargée |
| Export | `export_presets.cfg` (Windows Desktop → `build/FourWizards.exe`) | Un export testé de bout en bout (sans `.godot/`), icône, nom de la compagnie (vide), version, taille du paquet (voix + films) |
| Plantages | Touche F8 = rapport de bug, Playtest Recorder (désactivé par défaut) | Pas de journal de plantage automatique ni de reprise après plantage (la reprise était dans la liste du 10-06). Au minimum : un fichier log horodaté dans `user://logs` et un écran « le jeu a planté, voici le fichier » au relancement |
| Sauvegardes | 3 emplacements + rapide, versionnées | Les vieilles sauvegardes sont refusées à chaque changement de VERSION. Pour un public, prévoir des migrations ou avertir clairement |
| Légal / originalité | Règle « tout original » dans CLAUDE.md | Vérifier la licence des voix Kokoro et des polices ; écran de crédits techniques (Godot, FSR) |

## 7. Gains rapides (moins d'une heure chacun)

1. **Rebrancher `origin` et pousser** (ou faire un `git bundle` sur OneDrive). Juste les commandes, rien à coder.
2. **Commiter ou mettre de côté les 17 fichiers de code modifiés** (`mission_e3_02.gd`, `pace_switch.gd`, sims e2m5 /
   e3m1 / e3m4...) après `ci_quick -Changed`.
3. **`.gitignore` pour `docs/tools/cine/out/`, `docs/tools/world_forge/out/`, `docs/tools/map_gate/**/runs`** et les
   matrices brutes : `git status` passe de 3 600 lignes à quelques dizaines.
4. **CLAUDE.md** : retirer la ligne `UNIT_TYPES`, la règle d'effort HIGH et la référence à `origin` si elle reste
   absente ; mettre le playbook à jour avec le flux actuel (demandes → labs → commit).
5. **jss_asks.md** : passer les items de septembre au bon statut (`done` / `parked`). Six sont à `doing` depuis 10 à 12
   jours.
6. **Renommer « Fast (test) »** dans le menu (ou le cacher hors des builds debug).
7. **Remplir `application/company_name`** et la version dans `export_presets.cfg`, puis faire un export d'essai.
8. **Ajouter « Playtest data » activé par défaut dans le build de playtest de JS**, pour que chaque partie de JS
   alimente `tools\playtest\analyze.ps1`.
9. **Lancer `tools\health\run_health.ps1 -Refresh`** et noter le score dans les notes de reprise : le dernier score
   connu (77.6) date du 10-06, avant toute la campagne.
10. **Un test « aucune ligne sans voix »** qui parcourt `data/voice/lines/*.json` et les films, s'il n'existe pas déjà.

---
Incertitudes : je n'ai pas lancé le jeu ni les tests. L'état des réglages et de la mission 0 comme tutoriel vient d'un
grep, pas d'une partie. Le coût de la CI complète est une estimation. Je ne sais pas si la sauvegarde OneDrive du 10-03
contient `.git`.
