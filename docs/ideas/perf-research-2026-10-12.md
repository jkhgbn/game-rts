# Recherche : jeu plus rapide (perf) et parties plus courtes (2026-10-12)

Demande de JS : chercher sur GitHub, le web et YouTube tout ce qui peut rendre le jeu plus rapide, puis (ajout du lead)
comment les autres RTS raccourcissent leurs parties. Ce document ne change aucun code. C'est une liste d'idées classées,
avec les sources, le gain qu'on peut espérer **pour nos goulots à nous**, l'effort, le risque et un premier pas concret.

Honnêteté d'abord : la majorité des chiffres trouvés en ligne viennent de forums, de billets de blogue et de tests maison,
pas d'études contrôlées. Je les donne comme des pistes à mesurer avec notre Perf Lab, pas comme des promesses. Il y a peu
de sources Godot 4 sérieuses sur les RTS à 300+ unités. YouTube a surtout donné des démos sans code ni chiffres
vérifiables, alors je ne les cite presque pas.

---

## Partie 1 : performance à l'exécution

### Où on en est (nos chiffres)

- Perf Lab (headless, logique seulement) : environ 5-6 ms à 100 unités, 10-11 ms à 200 (`docs/perf/lab/latest/summary.md` :
  mid100 7,08 ms, late200 11,49 ms au 2026-10-01, avant la passe perf 161832c1).
- À 300 unités, les deux plus gros postes sont **physique + évitement (~8 ms)** et **animation des modèles (~5 ms)**.
  Ensuite viennent les **scans** (recherche de cible, auras) : `_find_nearest_enemy` coûtait ~300 µs par scan à 200 unités
  (commentaire dans `unit.gd:2205`), et le code fait ~205 appels à `get_nodes_in_group(&"units")`.
- Passe perf 161832c1 (2026-10-09) : les unités immobiles sautent `move_and_slide` (une fois aux 8 frames, décalé),
  `_face` sort tôt, les modèles hors caméra gèlent, et les types de sélection sont mis en cache.

### Trois constats faits en lisant le projet (avant toute recherche web)

1. **`neighbor_distance` de l'évitement est au défaut de Godot : 50 m.** `unit.gd:296-304` règle `radius`, `max_speed`
   et `avoidance_mask`, mais pas `neighbor_distance`, `max_neighbors` (défaut 10) ni `time_horizon_agents` (défaut 1,0 s).
   Défauts vérifiés dans la doc de classe générée par notre propre exe 4.7.2 (`--doctool`). La doc officielle le dit
   clairement : « A lower value reduces processing cost » pour `neighbor_distance` et `max_neighbors`.
   Dans une mêlée, chaque agent cherche donc ses voisins dans un rayon de 50 m pour n'en garder que 10.
2. **L'évitement tourne en multi-thread et ça brise les replays.** `docs/plan/replay-lab.md:193` a prouvé que
   `navigation/avoidance/thread_model/avoidance_use_multiple_threads=true` (défaut) est la dernière source de
   non-déterminisme, et que le mettre à `false` donne des replays identiques. La correction (étape 0, une ligne dans
   `project.godot`) n'est **pas encore appliquée** : `project.godot` n'a pas de section `[navigation]`. On l'a retardée
   parce que l'évitement sur un seul thread coûte plus cher. Le constat 1 peut payer cette facture.
3. **On n'utilise probablement pas Jolt.** `physics/3d/physics_engine` vaut `DEFAULT` chez nous. Godot 4.6 a fait de Jolt
   le défaut **pour les nouveaux projets seulement** (« Existing projects aren't affected », page de la 4.6). Je n'ai
   pas réussi à confirmer par script quel moteur `DEFAULT` donne en 4.7.2 pour notre projet. À vérifier (voir P5).

### Les idées

Légende. Gain : pour nos postes **E** = évitement, **M** = `move_and_slide`, **A** = animation des modèles, **S** = scans.
Effort : petit (< 1 jour), moyen (quelques jours), gros (une semaine et plus). Risque : comportement, déterminisme des
replays, CI.

#### P1. Régler l'évitement RVO (`neighbor_distance`, `max_neighbors`, horizon)
- **Quoi** : dans `unit.gd`, régler `neighbor_distance` autour de 4-8 m (2-3 fois la portée de contact), `max_neighbors`
  autour de 5-6, et garder `time_horizon_agents` court (0,5-1 s). Les drapeaux d'évitement (`avoidance_layers` /
  `avoidance_mask`) peuvent aussi séparer les volants des unités au sol, qui n'ont pas besoin de s'éviter.
- **Sources** : doc Godot « Using NavigationAgents », section évitement
  (https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationagents.html) ; avertissement de
  coût dans la classe NavigationAgent3D (https://docs.godotengine.org/en/stable/classes/class_navigationagent3d.html) ;
  fil de forum « 300 agents = terrible » (https://godotforums.randommomentania.com/d/31934-how-to-handle-large-amounts-of-navigationagents-pathfinding).
- **Gain (E)** : probablement réel, mais **non chiffré** en ligne. La recherche de voisins (arbre k-d de RVO2) et le
  programme linéaire par agent dépendent tous deux du nombre de voisins considérés. Je m'attends à une baisse nette de la
  partie « serveur de navigation » des ~8 ms à 300 unités. Je ne connais pas la part de l'évitement versus
  `move_and_slide` dans ces 8 ms : il faut mesurer avant d'y croire.
- **Effort** : petit (3 lignes et des mesures).
- **Risque** : comportement. Avec un rayon trop petit, des unités rapides (cavaliers) réagissent trop tard et se
  chevauchent. Les tests d'espacement et le Unit Lab doivent repasser. Déterminisme : neutre (et ça rend l'étape 0 du
  Replay Lab abordable). CI : aucun.

#### P2. Évitement mono-thread pour des replays exacts (l'étape 0 du Replay Lab), payé par P1
- **Quoi** : appliquer enfin `avoidance_use_multiple_threads=false`, mais **après** P1, pour que le coût reste sous le
  budget.
- **Sources** : notre propre audit `docs/plan/replay-lab.md:193-241` ; liste des réglages dans la doc ProjectSettings.
- **Gain** : négatif en perf brute (un seul cœur), positif en fiabilité (replays et rapports de bogue rejouables).
- **Effort** : petit. **Risque** : perf si on le fait sans P1.

#### P3. Index spatial partagé pour les scans (grille par équipe, refaite une fois par frame physique)
- **Quoi** : un seul nœud (ou autoload) qui, une fois par frame physique, range les unités vivantes dans une grille 2D
  (cellules de ~8 m, par équipe), avec leurs positions copiées dans un `PackedVector3Array`.
  `_find_nearest_enemy`, `_refresh_auras`, les tourelles, le brouillard et les VFX de zone lisent les cellules voisines au
  lieu de parcourir les ~300 unités et de lire `global_position` (coûteux) à chaque fois.
- **Sources** : article « Boids for RTS » de jdxdev (grille de voisinage, https://www.jdxdev.com/blog/2021/03/19/boids-for-rts/) ;
  fil Godot « Boid behavior and optimization for a Pikmin-like » (grille, 200 entités à 90 FPS en CPU,
  https://forum.godotengine.org/t/boid-behavior-and-optimization-for-a-pikmin-like/71608) ; guide Slashskill 2026
  (grille plate au lieu d'une boucle O(n²), https://www.slashskill.com/godot-4-characterbody3d-vs-multimesh-scaling-hundreds-of-units-without-killing-performance/).
- **Gain (S)** : gros sur les scans. On passe de O(n²) à environ O(n × voisins). À 300 unités, si chaque unité scanne
  quelques fois par seconde, on économise probablement 1 à 3 ms. Estimation de ma part : on a 300 µs par scan à 200
  unités, mais je n'ai pas compté combien de scans tournent par frame.
- **Effort** : moyen. Il y a ~205 boucles sur le groupe `units` : commencer par les 5 plus chaudes du hot list.
- **Risque** : déterminisme correct **si** l'ordre d'insertion est fixe (ordre du groupe) et si les égalités de distance
  se règlent toujours de la même façon. Comportement : aucun si le résultat est identique. On peut le prouver avec un
  test qui compare l'ancien scan et le nouveau sur des positions au hasard (graine fixe).

#### P4. Budget global d'animation des modèles (au lieu d'une décision par modèle)
- **Quoi** : on a déjà les paliers de distance (0 < 30 m, 1 < 45 m, 2 = gelé), la demi-cadence et le gel hors caméra.
  L'étape suivante est un **budget par frame** : un gestionnaire décide combien de modèles posent cette frame (par
  exemple 80), en commençant par les plus proches et les plus « actifs » (attaque, sort, mort). Les autres avancent leur
  horloge sans poser, en tourniquet. Au-delà de N unités à l'écran, les paliers se resserrent aussi tout seuls.
- **Sources** : l'« Animation Budget Allocator » d'Unreal, la même idée appliquée aux squelettes
  (https://dev.epicgames.com/documentation/en-us/unreal-engine/animation-budget-allocator-in-unreal-engine) ; doc Godot
  AnimationMixer, mode `callback_mode_process` manuel + `advance()` pour mettre à jour à cadence choisie
  (https://docs.godotengine.org/en/stable/classes/class_animationmixer.html). Ce n'est pas notre système (on est
  procédural), mais le principe est le même.
- **Gain (A)** : la facture devient un plafond fixe au lieu de croître avec le nombre d'unités. À 300 unités, on peut
  probablement réduire les ~5 ms de moitié, avec un effet visuel faible si les modèles proches restent à pleine cadence.
- **Effort** : petit à moyen (`character_model.gd` a déjà `offscreen_freeze` et les paliers ; il faut un coordonnateur).
- **Risque** : visuel seulement (les modèles loin saccadent un peu). Aucun effet sur le gameplay ni sur les replays,
  **à condition** que rien de gameplay ne lise une pose (pointe d'arme, etc.). À vérifier : `get_weapon_tip()` sert-il
  au départ des projectiles ?

#### P5. Essayer Jolt (A/B d'une ligne), seulement en mesurant
- **Quoi** : `physics/3d/physics_engine="Jolt Physics"` dans un `override.cfg` de laboratoire, puis Perf Lab late200 et
  `test_ws_perf --per-side=150`.
- **Sources** : page de la 4.6 (Jolt par défaut pour les nouveaux projets, https://godotengine.org/releases/4.6/) ;
  issue #93184, « Terrible performance with more than a few CharacterBody3D's » (Jolt ~800 FPS contre 19-109 FPS avec
  GodotPhysics dans le test du rapporteur, https://github.com/godotengine/godot/issues/93184) ; issue #78761
  (https://github.com/godotengine/godot/issues/78761) ; **contre-exemple** godot-jolt #626, « move_and_slide is slower
  than with Godot Physics » (la fixation au sol `_snap_on_floor` déclenchée à chaque appel la rendait ~2x plus lente,
  https://github.com/godot-jolt/godot-jolt/issues/626).
- **Gain (M)** : **incertain dans les deux sens.** Nos unités ne touchent que le monde (masque 1). L'évitement les tient
  séparées, donc le coût est surtout dans les requêtes de mouvement de `move_and_slide`, pas dans la simulation de
  contacts où Jolt brille. On peut gagner gros, ne rien gagner, ou perdre.
- **Effort** : petit pour l'essai. Moyen si on adopte (revalider les pentes, les ponts et le Rime Bulwark).
- **Risque** : comportement (glisse le long des murs, fixation au sol) ; déterminisme à revérifier avec le Replay Lab
  (Jolt est déterministe sur une même machine, mais je n'ai pas trouvé de garantie pour l'intégration Godot avec plusieurs
  threads) ; CI : tous les tests de mouvement.

#### P6. Pas physique à 30 Hz + interpolation physique 3D
- **Quoi** : `physics/common/physics_ticks_per_second=30` et `physics/common/physics_interpolation=true` (3D supportée
  depuis 4.4). L'évitement, `move_and_slide` et tout `_physics_process` tournent deux fois moins souvent, et l'image reste
  fluide grâce à l'interpolation.
- **Sources** : doc « Physics interpolation » (https://docs.godotengine.org/en/stable/tutorials/physics/interpolation/physics_interpolation_introduction.html) ;
  ajout du 3D en 4.4 (https://devclass.com/2025/03/05/godot-4-4-released-open-source-game-engine-adds-jolt-physics-net-8-and-more/).
  Repère : SC2 simule à 16 ticks par seconde de jeu (22,4 en « Faster »), d'après Liquipedia (https://liquipedia.net/starcraft2/Game_Speed).
- **Gain (E + M + scripts physiques)** : le plus gros levier brut de la liste, environ -40 à -50 % sur tout ce qui est
  dans le pas physique.
- **Effort** : moyen à gros. Tout ce qui compte en frames doit être revu : `Engine.get_physics_frames()` (dont notre
  décalage `IDLE_SLIDE_EVERY`), les `--quit-after` des tests et les timers en frames. Il faut aussi revoir les
  cooldowns, les projectiles rapides (risque de traverser une cible) et le ressenti des contrôles.
- **Risque** : élevé côté comportement et CI (beaucoup de tests supposent 60 Hz). Les replays restent déterministes
  (pas fixe), mais les vieux replays deviennent invalides.

#### P7. Mouvement « maison » au lieu de `move_and_slide` pour les unités au sol
- **Quoi** : pour une unité qui marche en terrain ouvert, `global_position += velocity * dt`, puis hauteur prise du
  terrain (ou de `NavigationServer3D.map_get_closest_point`). `move_and_slide` ne sert plus que près d'un mur de glace
  (couche 3) ou sur une pente raide.
- **Sources** : fil Aron Granberg sur un RTS lockstep de ~10 000 unités sans physique, collé au navmesh par « nearest
  point » (https://forum.arongranberg.com/t/pure-ecs-nearest-point-on-the-graph-for-a-large-number-of-units/9676) ;
  guide Slashskill (mouvement manuel sur tableaux compacts).
- **Gain (M)** : gros sur la part `move_and_slide` des unités qui bougent. Notre propre mesure donne ~10 µs par appel à
  300 unités, donc environ 1,5 à 3 ms si la moitié des unités bougent.
- **Effort** : moyen. **Risque** : moyen à élevé côté comportement (ponts, rampes, rivière, murs, unités projetées,
  fixation au sol) ; déterminisme correct (calcul simple en un seul thread) ; CI : tests de déplacement.

#### P8. Écrire les poses directement au RenderingServer (ou passer à un Skeleton3D par unité)
- **Quoi** : aujourd'hui, chaque pivot du kit est un Node3D qu'on bouge en GDScript. Chaque changement de transform
  propage des notifications aux enfants. Deux options : (a) garder les meshes fusionnés par pivot, mais poser leurs
  instances avec `RenderingServer.instance_set_transform` ; (b) un seul mesh avec un Skeleton3D par unité (pivots =
  os), où le skinning se fait sur le GPU et les poses d'os sont mises en lot.
- **Sources** : doc « Optimization using Servers » (https://docs.godotengine.org/en/stable/tutorials/performance/using_servers.html).
- **Gain (A)** : plausible mais **non mesuré** en ligne pour notre cas. Je ne sais pas quelle part des ~5 ms va au calcul
  de pose (GDScript) et quelle part va à la propagation des transforms. À profiler avant (voir P12).
- **Effort** : gros (2 861 lignes dans `character_model.gd`, beaucoup de sous-classes). **Risque** : visuel, et ça touche
  au kit d'art.

#### P9. Animation de marche / repos dans le vertex shader
- **Quoi** : les boucles (marche, repos, respiration, flottement d'orbe) calculées par le GPU à partir de `TIME`, d'une
  phase et d'une vitesse par instance (uniformes d'instance). Le CPU ne pose plus que les gestes ponctuels (attaque,
  sort, mort, monture).
- **Sources** : tutoriel officiel « Animating thousands of fish with MultiMeshInstance3D » (la méthode d'ABZU, tout sur
  le GPU, https://docs.godotengine.org/en/stable/tutorials/performance/vertex_animation/animating_thousands_of_fish.html).
- **Gain (A)** : potentiellement le plus gros sur l'animation, parce que la majorité des frames d'une unité sont de la
  marche ou du repos. **Effort** : gros (chaque pièce a besoin d'un poids de pivot dans le mesh, et chaque kingdom a son
  style). **Risque** : visuel ; les cinématiques et le Art Lab doivent revalider.

#### P10. Textures d'animation (VAT) + MultiMesh pour les unités lointaines
- **Quoi** : cuire les animations dans une texture et dessiner une armée lointaine en un seul MultiMesh par type
  d'unité (imposteurs animés).
- **Sources** : OpenVAT for Godot (https://github.com/antzGames/OpenVAT-for-Godot, présenté sur
  https://forum.godotengine.org/t/openvat-for-godot-animated-multimeshinstance3d-using-vertex-animation-textures/139440) ;
  doc MultiMesh (https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html : pas de culling par
  instance).
- **Gain** : surtout GPU et appels de dessin. **Peu de gain sur nos goulots CPU.** Nos modèles sont procéduraux, donc il
  faudrait d'abord les exporter vers Blender pour les cuire.
- **Effort** : gros. **Risque** : visuel ; c'est un pipeline d'art de plus. À garder pour plus tard (2v2 à 300 unités en
  rendu fenêtré, si le GPU devient le mur).

#### P11. GDExtension (C++ ou godot-rust) pour les boucles chaudes
- **Quoi** : réécrire en natif ce qui est du calcul pur sur des tableaux : index spatial (P3), séparation / évitement
  déterministe maison (P13), intégration du mouvement (P7).
- **Sources** : godot-rust (https://godot-rust.github.io/) et le projet d'évaluation gdext
  (https://github.com/franziskusz/gdext-evaluation). Un test informel 4.4.1 (Reddit, survivors en Rust / C# / GDScript)
  a vu tous les langages tomber sous 50 FPS vers 250 ennemis. Sa conclusion : quand le code passe son temps à appeler
  l'API Godot, le langage change peu. Doc MultiMesh : « for a few thousands, GDScript should be fine ».
- **Gain** : gros seulement sur le calcul pur (scans, voisinage), faible tant que le temps va à `move_and_slide` et aux
  nœuds. **Effort** : gros (chaîne de compilation, binaires pour 2 PC, CI). **Risque** : CI et maintenance ; les agents
  devraient aussi écrire du C++/Rust.
- Verdict : pas avant d'avoir fait P1, P3 et P4 en GDScript et mesuré ce qui reste.

#### P12. Mieux profiler : séparer évitement / `move_and_slide` / pose
- **Quoi** : avant P5, P6, P7 et P8, savoir exactement ce que contiennent les « ~8 ms physique + évitement ». Notre band
  profiler voit le pas physique comme un seul bloc. Mesures simples : (a) une variante de laboratoire avec
  `avoidance_enabled=false` (P1 en bout de course) ; (b) un chrono autour de `move_and_slide()` dans
  `_on_velocity_computed` (somme par frame) ; (c) Godot 4.6+ supporte Tracy et Perfetto pour voir le moteur en C++, mais
  il faut une **build du moteur faite maison** (https://docs.godotengine.org/en/stable/engine_details/development/profiling/index.html).
- **Gain** : indirect. Ça évite d'investir une semaine dans le mauvais poste. **Effort** : petit pour (a) et (b), gros
  pour (c). **Risque** : aucun (code de laboratoire).

#### P13. Remplacer RVO par une séparation « boids » déterministe
- **Quoi** : couper l'évitement de Godot et pousser les unités voisines avec une force de séparation simple sur l'index
  spatial (P3), en un seul thread et dans un ordre fixe.
- **Sources** : jdxdev « Boids for RTS » ; Game AI Pro, « Crowd Pathfinding and Steering Using Flow Field Tiles »
  (Supreme Commander 2, http://www.gameaipro.com/GameAIPro/GameAIPro_Chapter23_Crowd_Pathfinding_and_Steering_Using_Flow_Field_Tiles.pdf).
  Ces sources sont anciennes, mais ce sont les références classiques.
- **Gain (E)** : moyen en GDScript (probablement moins bon que le RVO natif en C++), gros en GDExtension. Ça règle le
  déterminisme pour de bon. **Effort** : gros. **Risque** : comportement (les foules « coulent » autrement, et il y a les
  blocages connus des boids : unités coincées, arrivée en grappe).

#### P14. Champs de flux (flow fields) pour les gros ordres de groupe
- **Quoi** : un seul calcul de chemin par destination au lieu d'un par unité.
- **Sources** : D2klaas/Godot-4-VectorFieldNavigation (https://github.com/D2klaas/Godot-4-VectorFieldNavigation) ;
  jdxdev « RTS Pathfinding 1: Flowfields » (https://www.jdxdev.com/blog/2020/05/03/flowfields/).
- **Gain** : faible pour nous. Nos coûts ne sont pas dans les requêtes de chemin (rien au hot list là-dessus).
  **Effort** : gros. **Risque** : comportement. À garder seulement si le pathfinding apparaît un jour dans le profil.

#### P15. Threads de travail (WorkerThreadPool) en GDScript
- **Quoi** : `WorkerThreadPool.add_group_task` pour des calculs indépendants par unité (scan de cible), puis appliquer
  les résultats sur le thread principal, dans l'ordre des unités.
- **Sources** : doc « Thread-safe APIs » (https://docs.godotengine.org/en/stable/tutorials/performance/thread_safe_apis.html) ;
  le correctif d'un interblocage de WorkerThreadPool dans le cycle 4.7 RC montre que ce chemin bouge encore.
- **Gain** : moyen sur S. **Effort** : moyen. **Risque** : élevé (lecture de nœuds hors thread principal interdite ou
  fragile ; déterminisme OK seulement si l'application des résultats est ordonnée). Passe après P3.

#### P16. Physique sur un thread séparé (`physics/3d/run_on_separate_thread`)
- **Sources** : fil « Rules for running physics on separate thread » (4.6, https://forum.godotengine.org/t/rules-for-running-physics-on-separate-thread/138051).
- **Gain** : incertain. Nos `move_and_slide` sont appelés depuis nos scripts, sur le thread principal, donc le gain réel
  serait faible. **Risque** : élevé (accès à `direct_space_state` seulement dans `_physics_process`, marqué expérimental
  avec Jolt). À ne pas prioriser.

### Boucle de dev (tests, imports)

- **D1. Un seul processus Godot pour plusieurs tests.** Chaque test paie le démarrage du moteur + le cache des classes
  (quelques secondes). Un « runner » qui charge les scripts de test un après l'autre dans le même processus (comme le
  runner en ligne de commande de GdUnit4 : https://github.com/MikeSchulze/gdUnit4-action) réduirait le temps total de CI.
  Effort moyen ; risque : un test qui laisse de l'état global (autoloads) pollue le suivant. Ça ne vaut que pour les
  petits tests unitaires, pas pour les labs.
- **D2. Plus de créneaux sur le portable dédié.** `tools/godot_run.ps1` permet 4 créneaux (`FW_GODOT_SLOTS`). Le
  portable est dédié (mémoire « max it out ») : essayer 6 pour la CI rapide **hors mesures de perf**. Le Perf Lab garde
  son garde-bruit et un seul Godot à la fois.
- **D3. Cache d'import.** On le fait déjà bien (`.godot/` jamais versionné, `--import` seulement quand un asset change).
  En CI, mettre le cache sur une clé faite du hash des `.import` et de la version de Godot évite un réimport complet
  (source : doc import, https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/import_process.html).
- **D4. `SimMode` partout où l'image ne compte pas.** Les labs de bots tournent déjà sans modèles ; vérifier que tous
  les labs d'équilibrage le font (l'animation coûte ~5 ms à 300 unités pour rien en headless).
- Un conseil vu en ligne : isoler les dossiers utilisateur de chaque Godot parallèle (`XDG_*` sous Linux). Sous Windows,
  l'équivalent est `user://` dans `%APPDATA%`. Je n'ai pas trouvé de drapeau officiel en ligne de commande pour ça ; à
  vérifier avant de s'y fier.

### Top 5 perf, avec un premier pas concret

| # | Idée | Pourquoi d'abord | Premier pas |
|---|---|---|---|
| 1 | **P1 Régler l'évitement** (+ P2 juste après) | 3 lignes, gain probable sur le plus gros poste, et ça débloque les replays exacts | Dans `unit.gd` après `_agent.radius`, ajouter des constantes `AVOID_NEIGHBOR_DIST := 6.0`, `AVOID_MAX_NEIGHBORS := 6` ; Perf Lab `-Scenarios late200 -NoGpu -Repeats 3` + `test_ws_perf --per-side=150` avant / après ; puis les tests d'espacement et le Unit Lab. Si c'est vert, refaire la mesure avec `avoidance_use_multiple_threads=false` (override.cfg de labo) |
| 2 | **P12 Profiler le pas physique** | Savoir si les 8 ms sont surtout de l'évitement ou du `move_and_slide` décide entre P5/P7 et P13 | Variante de laboratoire dans `perf_lab.gd` : (a) évitement coupé, (b) chrono cumulé autour de `move_and_slide()` ; une ligne de plus dans le scorecard |
| 3 | **P3 Index spatial pour les scans** | O(n²) qui empire avec la 2v2 à 300 unités ; aucun changement de comportement si on le fait bien | Créer `UnitIndex` (grille par équipe, refaite au début du pas physique, ordre du groupe) ; migrer `_find_nearest_enemy` seulement ; test d'équivalence (1 000 positions au hasard, graine fixe, même résultat) |
| 4 | **P4 Budget d'animation** | Plafonne les ~5 ms, sans effet sur le gameplay | Dans `character_model.gd`, un coordonnateur statique qui donne N poses par frame (proches et actions d'abord) ; mesurer `late200` cpu et gpu ; contrôle visuel dans le Visual Diff Lab |
| 5 | **P5 A/B Jolt** puis, selon P12, **P7** | Un essai d'une ligne avant d'écrire du mouvement maison | `override.cfg` de labo avec `physics/3d/physics_engine="Jolt Physics"` ; late200 + ws_perf + Replay Lab ; garder seulement si `move_and_slide` baisse et si les replays restent identiques |

À garder pour plus tard : P6 (30 Hz, gros levier mais beaucoup de casse), P9 (shader), P11 et P13 (natif).

---

## Partie 2 : parties plus courtes

### Où on en est

- **Blitz** (`docs/balance/blitz_2026-10-10.md`) : médiane 10:57 (normal) et 11:25 (difficile) en temps réel, 9 ouvriers,
  horloge x1,3, bâtiments x0,3, donjon x0,4, entraînement x0,5. Le premier attaquant gagne 53-58 %. Problèmes restants :
  Ice faible, et le sort de zone de Fire contre les lignes d'ouvriers.
- **Normal** : 14-16 min de médiane selon le lead. Le labo du 2026-10-08 donnait encore 22:18 pour la base et 17:31 pour
  l'arm A2. Les chiffres ont dû bouger depuis ; à revérifier dans le même labo avant de comparer.
- Ce que nos labos ont appris : **les parties se décident vers 3-5 min (la première armée tombe), puis il faut ~10 min de
  plus pour finir** une base qui continue de produire. Les bots finissent par **abandon**, presque jamais en rasant la
  base. Les unités de siège (B) n'ont rien changé, parce que le Commander ne pousse jamais dans une base exprès
  (`faster_games_2026-10-06.md`). **Le gros du temps à gagner est donc dans la phase « finir le travail ».**

### Ce que font les autres

| Jeu | Levier | Source |
|---|---|---|
| SC2 : Legacy of the Void | 6 → 12 ouvriers au départ, « pour réduire le temps mort du début » ; des gisements plus petits forcent l'expansion. En 2026, un PTR redescend à 8 ouvriers | https://news.blizzard.com/en-us/article/18483059/starcraft-ii-legacy-of-the-void-beta-patchnotes-1-0 ; https://www.pcgames.de/StarCraft-2-Legacy-of-the-Void-Spiel-55003/News/ueberraschender-Patch-schockt-Fans-1539998/ |
| SC2 | Vitesse « Faster » = x1,4, la norme en classé | https://liquipedia.net/starcraft2/Game_Speed |
| AoE2 DE : Empire Wars | Départ en Âge féodal, 27 villageois déjà au travail, base construite (fermes, camps, caserne, forge) | https://www.ageofempires.com/games/aoeiide/empire-wars/ ; https://ageofempires.fandom.com/wiki/Empire_Wars |
| AoE4 : Empire Wars | Ville préconstruite, 23 villageois au travail + 4 en file, bâtiments éco, marché | https://www.ageofempires.com/news/empire-wars-has-come-to-age-of-empires-iv/ |
| AoE4 | Victoires alternatives : détruire les **Landmarks** (pas besoin de tout raser), tenir les **sites sacrés** (minuterie), merveille | fil Steam https://steamcommunity.com/app/1466860/discussions/0/3196990234713261815/ ; forum https://forums.ageofempires.com/t/does-surrender-counts-as-landmark-victory/201237 (sources communautaires, pas de page officielle trouvée) |
| AoE2 | **Régicide** (le roi meurt = défaite) ; Roi de la colline | https://liquipedia.net/ageofempires/Regicide |
| Company of Heroes | **Points de victoire / tickets** : la majorité des points fait fondre les tickets adverses (250/500/1000). Nombre impair de points, donc pas d'impasse possible | https://www.coh2.org/guides/107552/know-your-map-victory-point-mechanics ; https://www.matchstickeyes.com/2010/12/21/how-to-design-victory-conditions/ |
| Clash Royale | Temps limite + **prolongation** : premier bâtiment détruit = victoire, élixir x2 puis x3 en fin de partie, bris d'égalité sur la tour la plus basse. But affiché : une durée uniforme et une fin plus intense | https://supercell.com/en/games/clashroyale/blog/release-notes/november-update |
| Battle Aces (2024-25, arrêté) | Parties de ~10 min : économie automatique, une seule structure, expansions prédéfinies | https://www.pcgamer.com/games/rts/battle-aces-deckbuilding-rts-hands-on-preview/ ; https://en.wikipedia.org/wiki/Battle_Aces |
| Warcraft 3 | **Upkeep** : moins de revenu avec une grosse armée. Ça **allonge** les parties (anti-boule de neige) | https://pcgamesn.com/warcraft-3/upkeep ; https://waywardstrategy.com/2020/07/06/anti-snowball-design/ |
| Total Annihilation / Spring / BAR | Option « la partie finit si le commandant meurt » | https://springrts.com/phpbb/viewtopic.php?p=12009 (ancien ; je n'ai pas trouvé de page BAR à jour) |
| Zero-K (PlanetWars) | À 100x d'actifs contre 1, les unités du perdant sont révélées en permanence (pour finir vite) | https://planet.freegamedev.net/2019/03/02/zero-k-v1-7-3-1/ (notes de version ; détail PlanetWars d'après le résumé de recherche) |
| Northgard | Plusieurs conditions de victoire (renommée, savoir, commerce, domination), activables à la création | https://steamcommunity.com/app/466560/discussions/1/4300317773582738763 |
| Analyse de design | Anti-boule de neige : « intrinsèque » (rendements décroissants) ou « ajouté » (upkeep, retraite) ; l'avantage du défenseur doit **s'effacer** en milieu de partie pour que le gagnant puisse finir | https://waywardstrategy.com/2020/07/06/anti-snowball-design/ |

Stormgate : je n'ai rien trouvé de fiable sur sa durée cible ni sur son départ en ouvriers. Les aperçus disent plutôt que
le rythme est plus lent que SC2 (https://outof.games/news/6246-stormgate-gameplay-preview-warcraft-meets-starcraft/).

### Les idées pour nous

#### G1. Règle « finisseur » du Commander (fermer la partie quand on mène)
- **Quoi** : quand l'armée du bot vaut X fois celle de l'adversaire (ou que la première armée adverse vient de tomber),
  il pousse **dans** la base avec du siège, vise d'abord les bâtiments de production et le donjon, et ne recule pas pour
  une petite défense.
- **Pourquoi** : c'est exactement notre trou (3-5 min pour décider, ~10 min pour finir). L'analyse wayward le dit :
  l'avantage du défenseur doit s'effacer pour que le gagnant puisse conclure.
- **Convient à** : Normal (le plus gros gain attendu) et Blitz. **Effort** : moyen (ai-coder). **Risque** : un bot qui
  pousse trop tôt perd ; il faut un Bot Lab (40 parties). Ça ne change ni les données ni les unités.

#### G2. Prolongation « à la Clash Royale » pour Blitz (durée bornée)
- **Quoi** : à 9:00, revenus x2 et entraînement plus rapide pour les deux camps (finale intense). À 12:00, prolongation :
  le premier bâtiment de défaite (`Building.defeat_relevant`) détruit fait gagner. À 14:00, bris d'égalité sur le % de
  PV du donjon le plus bas (ou sur le score, qu'on a déjà au tableau de fin).
- **Convient à** : Blitz surtout (ça borne la queue p75 de 13:08). En Normal, seulement comme option.
- **Effort** : moyen (on a déjà une fin « time limit » et un onglet Score). **Risque** : le bris d'égalité doit être
  lisible pour un joueur humain ; les bots doivent savoir qu'ils sont dans le rouge.

#### G3. Victoire par contrôle (tickets façon CoH, sites sacrés façon AoE4)
- **Quoi** : on a déjà `capture_points.gd` (puits, sanctuaires, présence par équipe). Dès 4:00, tenir la majorité des
  points fait fondre les tickets adverses, et à 0 c'est la défaite. Il faut un nombre impair de points.
- **Convient à** : un mode optionnel en Normal (« Contrôle »), et Blitz si les tickets sont bas.
- **Effort** : moyen à gros (règle + HUD + règle de Commander pour défendre ou prendre les points). **Risque** : ça change
  le jeu (on se bat pour la carte, pas pour la base) ; certains kingdoms peuvent y gagner trop (vérifier les 4).

#### G4. Départ « Empire Wars » pour Blitz
- **Quoi** : on va plus loin que 9 ouvriers : 12-15 ouvriers déjà au travail, une Hall et un bâtiment de production
  déjà construits, Stronghold à 1:00. On saute l'ouverture.
- **Convient à** : Blitz. **Effort** : petit à moyen (même endroit que les 9 ouvriers dans `skirmish.gd` /
  `layout_level.gd`). **Risque** : ça aggrave le problème connu (le sort de zone de Fire contre une ligne d'ouvriers), donc
  les ouvriers x2 PV doivent rester ; Ice ne convertit toujours pas son revenu en armée (question de Commander). LotV
  rappelle que l'économie peut s'emballer : leur PTR de 2026 redescend à 8 ouvriers.

#### G5. Base qui « lâche » : moins de production quand le donjon tombe
- **Quoi** : quand le donjon passe sous 30 % de PV, ou que le joueur n'a plus de bâtiment de production, l'entraînement
  ralentit fortement et la base est révélée à l'adversaire (comme la règle PlanetWars de Zero-K). La victoire « Landmark »
  d'AoE4 va dans le même sens : pas besoin de tout raser.
- **Convient à** : Normal et Blitz. **Effort** : petit à moyen. **Risque** : ça renforce la boule de neige. Mettre le
  seuil bas pour ne pas tuer les retours ; mesurer le taux de victoire du premier attaquant (cible < ~70 %).

#### Autres pistes, plus faibles pour nous
- **G6. Vitesse de jeu** : on est déjà à x1,3 en Blitz. Un réglage joueur (x1,0 / x1,2 / x1,4) en Normal coûte peu,
  mais le contrôle et les sorts deviennent plus durs (à faire valider par un playtest humain, comme le dit déjà le doc
  Blitz).
- **G7. Cartes plus petites / bases plus proches** : Thornwater (10:16) finit déjà plus vite que Crown Hollow (11:18).
  Une petite carte Blitz dédiée est un levier sûr, mais c'est un gros travail de carte.
- **G8. Régicide (le sorcier meurt = défaite)** : très court, mais ça change tout le jeu. Le sorcier est une pièce
  centrale, donc ce serait frustrant. Seulement comme mode fun.
- **G9. Upkeep à la WC3** : **à éviter** pour raccourcir. C'est un frein anti-boule de neige qui allonge les parties.
- **G10. Agressivité des bots** : on l'a déjà poussée (patience 45 s, première attaque avant 5:00). Le gain restant est
  dans G1, pas dans « attaquer plus tôt ».

### Top 5 durée de partie, avec un premier pas concret

| # | Idée | Pour | Premier pas |
|---|---|---|---|
| 1 | **G1 Règle finisseur** | Normal + Blitz | ai-coder : nouvelle règle dans `commander.gd` (« si mon armée ≥ 2x la sienne, ou si sa première armée est tombée : push base, cibles = production puis donjon, siège inclus ») ; Bot Lab normal 36 parties sur la même grille que `faster_games_2026-10-06.md` ; regarder la médiane, le temps du « premier bâtiment perdu » et le taux de victoire du premier attaquant |
| 2 | **G2 Prolongation Blitz** | Blitz | Variante de labo `blitz_v16.json` : revenu x2 à 9:00, mort subite à 12:00, bris d'égalité à 14:00 ; viser une p75 < 12:30 sans faire bouger la médiane de plus de 1 min |
| 3 | **G5 Base qui lâche** | Normal + Blitz | Variante de labo : entraînement x0,5 si le donjon est sous 30 % de PV ; mesurer le temps entre « première armée perdue » et la fin |
| 4 | **G4 Départ Empire Wars** | Blitz | `PaceSwitch.BLITZ` : 12 ouvriers + Hall préconstruite (labo d'abord) ; surveiller Fire contre les ouvriers et Ice |
| 5 | **G3 Mode Contrôle (tickets)** | Normal (option), Blitz | Note de design d'une page (nombre de points, débit des tickets, HUD), puis un prototype de labo qui réutilise `CapturePoints` sans HUD pour mesurer la durée |

Ordre conseillé : G1 avant tout. Si les bots savent finir, une bonne partie des 10 minutes de « fermeture » disparaît dans
les deux modes, sans toucher aux règles du jeu.

---

## Sources générales consultées

- Doc de classe générée par notre exe 4.7.2 (`--doctool`, dans le scratchpad, pas dans le dépôt) : défauts de
  NavigationAgent3D et liste des réglages `navigation/*`, `physics/*`, `threading/*`.
- Notes de version Godot 4.6 : https://godotengine.org/releases/4.6/ ; 4.7.2 : https://godotengine.org/article/maintenance-release-godot-4-7-2/
- Projet RTS open source Godot 4 (référence de structure, pas de chiffres de perf) : https://github.com/lampe-games/godot-open-rts
- Ce que je n'ai **pas** trouvé : un RTS Godot 4 open source avec 300+ unités et des chiffres publiés ; une vidéo
  GDQuest sur les foules d'unités ; un benchmark fiable de `move_and_slide` Jolt contre GodotPhysics en 4.6+ ; une source
  officielle sur la durée moyenne d'une partie en classé SC2 ou AoE4 (aoe4world.com publie des médianes par civilisation,
  à consulter au besoin).
