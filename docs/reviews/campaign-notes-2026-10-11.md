# Notes de campagne, 2026-10-11 : chaque mission et chaque film

**Résumé pour JS**
1. J'ai fait jouer les 36 missions (les 4 routes d'E8 comptées) par leurs sims (55 parties scriptées au normal, plus 2 relances détaillées) et j'ai passé les
   ~157 films au crible (planches contact + fichiers `.cine`). Notes, temps, problèmes et correctifs ci-dessous.
2. **Ce qui marche le mieux** : e3m4 (Vey en boss qui ne meurt pas), e6m2 (le choix de la porte), e4m1 (l'autre côté de
   e3m1), e8m2 (les quatre royaumes ensemble) ; côté films, le prologue et l'ouverture d'E4 (9/10).
3. **Les Épisodes 1 et 2 sont trop courts** : m02 se gagne en 7:48 (cible 18-24) en rushant l'Orbe, m03 en 11:33, e2m1 allume
   le Heartwood à 1:14. Les épisodes 4 à 8 ont reçu des « planchers » de temps ; les premiers, non.
4. **Trois sims ne gagnent plus aujourd'hui** : e4m3 (les deux), e2m2 (1 fois sur 2, l'armée est rasée à Rimehold et l'économie
   ne repart pas) et e5m3 (la sim furtive se fait prendre par le Reeve). Suspect n°1 pour e4m3 / e2m2 : le patch IA Ice d'hier
   soir (`56e1c316`), parce que ces missions construisent leur Torvald avec `AIProfile.ice(...)`. La sim e3m1 est cassée
   (seuil inatteignable), pas la mission.
5. **Les gros trous pour un premier joueur** : les boss finaux sans vrai modèle (le Roi creux = Rime Colossus x2,2, le
   Doorwarden = capsule de 16 m), les 34 films in-mission d'E7-E8 en caméras fixes qui ne placent personne (le « Non. » de
   Torvald peut tomber sur un sol vide), la fin du jeu (ep8_ending_a, 4/10), et de longues attentes forcées (8 min dans e4m4,
   8 min dans e5m3).

---

## 1. Couverture et méthode

| Quoi | Couvert | Pas couvert / limites |
|---|---|---|
| Missions (36, dont les 4 routes, + l'écran de route) | 55 sims au normal (`test_<id>_sim` + variantes rush / passive / shut), cap 150 000 frames ; relances verbose d'e2m2 et e3m1 ; en-têtes des scripts, notes « Built » des specs, cibles de durée, spotlights, fichiers de répliques | **m01** : pas de sim complète (`test_m7_s2` retire les gardes et protège Vessa) ; **e3m1** : pas de temps (sim cassée) ; **e4m3** : pas de victoire aujourd'hui ; facile / difficile pas joués ; une seule graine par sim |
| Films (prologue, ouvertures, entre-films, fins, variantes) | 93 planches contact (`index.json` + notes) ; 4 planches regardées à l'œil (prologue, ep8_ending_a, ep2_ending, e3m4_field) ; `framing_fixes.md` | Les planches datent du 08/10 ~13 h, **avant** les 3 passes de cadrage et le correctif de hauteur de visage : plusieurs défauts sont corrigés depuis (marqués) |
| Films in-mission E4-E8 (64, sans planche) | Les 64 `.cine` résumés par script (plans, caméras, cast, SFX / VFX, répliques) ; 4 lus en entier (e4m4_enough, e7m4_turn, e8m3_king, e6m4_first_crack) | Pas rendus : jugés sur le papier |
| Voix | Comptage des répliques par mission et recherche des WAV par texte | Heuristique : quelques « manquants » peuvent être des faux négatifs (m04 19/25, e8m3 38/45, e8m1_shadow 21/26, e6m4 23/27). La note « Not voiced yet » en tête de tous les fichiers d'E4-E8 est périmée (~95 % trouvés) |

Temps total estimé : ~10 h 20 de jeu pour les sims (en prenant une route d'E8 et ~17 min pour m01, ~25 pour e3m1 et e4m3),
donc **13 à 16 h pour un premier joueur**, plus ~1 h 30 de films.

Logs des sims : scratchpad de la session, `sims/*.log` (pas copiés dans le dépôt).

**Attention : les sims ont tourné sur l'arbre de travail, pas sur `HEAD` (`2ec186cf`).** Il y a des changements non commités
(datés du 10/10 vers 13 h 50, pas les miens) dans `mission_01`, `mission_02`, `mission_e2_02`, `mission_e2_04`, `mission_e2_05`,
`mission_e3_01`, `mission_e3_02`, `mission_e3_04`, `t3_unit_ability.gd`, `main.gd` et dans les tests `test_e2m5_sim`,
`test_e3m1_sim`, `test_e3m2`, `test_e3m4_sim`. Les résultats de m01, m02, e2m2, e2m4, e2m5, e3m1, e3m2 et e3m4 peuvent donc
changer une fois ce travail commité ou jeté. En particulier, le bug de seuil de la sim e3m1 est peut-être dans la version en cours.

## 2. Les missions, une par une

Chaque carte : **note /10** (plaisir estimé, clarté de l'objectif, rythme vs la longueur du spec, difficulté, force du moment
d'histoire, spotlight), le **résultat de la sim** (normal, cinématiques coupées ; « jeu » = temps de mission + longueur des films
in-mission), ce qui marche, ce qu'il faut corriger, et le risque de blocage / cheese.

> **Attention au temps des sims.** Le joueur scripté joue parfait : il sait où aller, ne se perd pas, micro-gère. Un premier
> joueur va prendre en gros **1,3 à 1,6 fois** le temps de la sim. Une mission dont la sim tombe *sous* le spec n'est donc pas
> forcément trop courte en vrai ; une mission dont la sim tombe *pile au milieu* risque d'être longue pour un débutant.

### Épisode 1, « La Couronne dans les cendres » (Vessa)

**m00, La Nuit des couteaux** (cible 9-12 min, nuit fixe de 8:00), **7/10**
- Sim : victoire 8:02, escorte 8 / 8, **A4 a perdu 0 soldat** (le spec en veut 2 à 4), Vessa 359 HP, niveau 3.
- Marche : objectif limpide (survivre jusqu'à l'aube), compte à rebours, braseros qui soignent, Vey qui veille. Bon premier
  contact avec l'histoire. 21 répliques courtes (6 mots en moyenne), toutes doublées. Spotlight Flame Guard bien placé (A2 1:30).
- À corriger : trop facile au normal pour un premier vrai combat (0 perte en A4). Monter A4 de 1-2 Grave Hounds ou faire plonger
  Hush plus tôt pour que le joueur sente le danger au moins une fois. Les films `m0_fall` / `m0_dawn` n'ont pas de planche : à vérifier.
- Blocage / cheese : aucun vu. La nuit est fixe, donc pas de rush possible.

**m01, La Couronne dans les cendres** (cible 15-20 min), **6/10** *(pas mesurée)*
- Sim : pas de sim de jeu complète. `test_m7_s2` gagne en 2:15 de jeu, mais **avec les gardes retirés et Vessa protégée** : ça ne dit
  rien sur la durée réelle.
- Marche : la première mission « base + braseros + tenir », bonne école. Spotlight Blaze Rider avec un moment clair (Westwatch).
  4 petits films in-mission propres (m1_crown 7/10).
- À corriger : **écrire une vraie sim** (comme `test_m3_sim`) ; c'est la seule mission du jeu sans mesure de durée. Pas de
  `data/voice/lines/m01.json` : vérifier que les 15 répliques de mission sont doublées (les films le sont).
- Blocage / cheese : inconnu faute de sim.

**m02, L'Orbe sous la glace** (cible 18-24 min), **5/10**
- Sim : **ÉCHEC du test** : victoire à **7:48** (7:58 avec le film), hors de la fenêtre 10-24 du test. Fouille de Malrik à 18,8 %,
  armée finale de 3.
- Marche : la meilleure idée mécanique de l'E1 (banquises qui craquent, blizzard pour les deux, l'Orbe sous le Heartfrost).
  Spotlight Ash Hurler logique (seul lui et Vessa blessent le Heartfrost).
- À corriger : **on peut rusher l'Orbe** : Vessa + quelques Hurlers cassent le Heartfrost vers 6:00 et sortent. Mettre un plancher
  (le Heartfrost se régénère tant que la fouille n'a pas atteint X %, ou le Heartfrost ne devient attaquable qu'à W2), ou monter
  ses HP. Une mission de 8 min sur une cible de 20, c'est le plus gros écart de la campagne.
- Blocage / cheese : **cheese confirmé** (rush de l'Orbe).

**m03, La Chevalière dans le Bois-Soupir** (cible 20-25 min), **6/10**
- Sim : victoire 11:33. 3 cœurs, armée 25, Vessa niveau 7 ; `sec_stakes` échoué.
- Marche : première taverne, premier champion (Wayfinder), la course au Sceau : beaucoup de nouveautés bien amenées.
- À corriger : **trop court** de presque moitié. La course part à 8:57 ; ajouter un plancher sur le réveil des Root Hearts ou
  garder la Chevalière scellée jusqu'à ~14:00. `sec_stakes` échoue même pour le joueur scripté : l'objectif secondaire est mal
  expliqué ou trop dur. Le m3_oldroot (12 s sans personnage ni réplique) casse le rythme.
- Blocage / cheese : faible ; le rush des cœurs raccourcit beaucoup.

**m04, Le Trône creux** (cible 22-28 min, films compris), **7/10**
- Sim : victoire 13:36 (**16:42** avec les films). Montée à 6:15 **par le siège** (Vessa s'assoit sur le trône), marche 9:40,
  tempête 11:10. Grosses pertes sur le Colosse (20 morts en p1/p2).
- Marche : vraie finale de boss en phases, compteur du Creux lisible, l'arrivée de Vey à l'heure la plus sombre. Kilnwarden en
  spotlight, avec un chiffre clair (armure 25 → 5).
- À corriger : le siège à 6:15 coupe la phase 0 en deux ; mettre « Vessa s'assoit » au plus tôt à 10:00 ou exiger le compteur
  à 50 %. Le film `m4_fall` est une capsule « HEART_STONE » géante (3/10) : à remplacer avant tout test joueur. 19 répliques
  sur 25 trouvées doublées (heuristique) : à vérifier.
- Blocage / cheese : le siège précoce raccourcit beaucoup ; pas de blocage vu.

### Épisode 2, « La Lumière d'en bas » (Vessa, 2v1 puis 2v2)

**e2m1, Le Bosquet qui brûle** (cible 20-25 min), **6/10**
- Sim : victoire 13:20 (14:22). Allumage du Heartwood à **1:14**, 8 survivants ramenés, Vey appelé, gel 15 %.
- Marche : spotlight Old Vey très bien posé (premier appel à la Citadelle). Les Rime Totems et le gel donnent un objectif clair.
- À corriger : l'allumage à 1:14 transforme la mission en un simple « tiens 12:00 ». Le spec prévoit G1 → S1 → G2 → totems
  avant d'allumer ; forcer cet ordre (le Heartwood ne s'allume pas tant qu'un totem vit dans 30 m, pas 10 m) ou mettre un
  plancher à ~7:00. 20 morts sur Grave Hounds pendant le hold : le hold est un mur de hounds, varier les vagues.
- Blocage / cheese : rush d'allumage confirmé.

**e2m2, Racines et braises** (cible 22-28 min), **6/10**
- Sim : **1re course : ÉCHEC (temps écoulé à 34:26)**. Relance en verbose : victoire 17:34 (18:47). La relance montre pourquoi :
  à 9:00 l'armée compte 22 unités, après l'assaut de Rimehold elle tombe à **0-5 pendant 4 minutes** avec ~50 cristaux.
- Marche : premier 2v2 de l'histoire, l'allié Ysolde qu'on envoie planter (panneau 3 boutons), Saboteur en spotlight.
- À corriger : **Rimehold est un piège** : un joueur qui attaque à 9:00 perd tout et n'a plus l'économie pour reconstruire.
  Baisser la garnison (ou un spire de moins), ou donner un filet (relève gratuite de 6 soldats après un assaut raté, ou des
  nœuds plus riches). Le panneau « Envoyer Ysolde ici » doit être expliqué une fois à l'écran.
- Blocage / cheese : **quasi-blocage économique** possible (armée rasée + nœuds secs).

**e2m3, La Route du sel** (cible 18-24 min), **7/10**
- Sim : victoire 17:58 (18:56), 6 tributs, 0 perdu, W1 13 / 13, Vey appelé.
- Marche : rythme dans la cible, boucle escorte / défense variée, Emberdart en spotlight avec un vrai usage (Magpies).
- À corriger : 30 changements de phase escorte ↔ défense dans la sim : beaucoup d'allers-retours, ça peut devenir du baby-sitting
  pour un humain. Le bouton « Envoyer le tribut » (en haut à droite) doit être pointé par un indice. Bettany est une capsule
  dans ses deux films (e2m3_lodge / e2m3_paid).
- Blocage / cheese : rien vu.

**e2m4, La Route du lever** (cible 17-23 min), **7/10**
- Sim : victoire 14:29 (15:54), 8 Wardens, 6 pierres, 3 recherches, Hush en fuite, G1 11 / 13.
- Marche : changement d'ambiance réussi (sous terre, petite armée, lumière contre noir). Bon spotlight Ember Forge.
- À corriger : un peu court ; la règle du noir (ennemis invisibles aux auto-cibles hors lumière) doit être annoncée par un indice
  au premier ennemi caché, sinon ça ressemble à un bug (« mes archers tirent pas »). Pas de vignette ni d'eau qui ralentit.
- Blocage / cheese : rien vu.

**e2m5, La Lumière d'en bas** (cible 25-31 min), **6/10**
- Sim : victoire 18:28 (19:54), réveil à 13:00, Porte min 54 %, 11 lances, 1 dragon ; `sec_seals` échoué.
  117 avertissements « Vector3 cannot be normalized » venant du script de test (`sim_tactics.spread_to`), pas du jeu.
- Marche : finale d'épisode avec un vrai boss et une course aux sceaux ; la Porte qui doit tenir donne une tension claire.
- À corriger : **le Doorwarden est une capsule de 16 m** (pas de modèle) : c'est le boss de l'épisode. Pas de barre de boss
  (le % est dans les objectifs). Le Cinder Dragon **marche** sur les ponts au lieu de voler par-dessus la Faille : le spotlight
  promet le contraire (« it flies over the Rift »). Court de 5-10 min.
- Blocage / cheese : rien vu ; le tether de Malrik attire beaucoup de morts (11).

### Épisode 3, « Le Fils du fossoyeur » (Malrik)

**e3m1, Prendre le gué** (cible 22-28 min), **6/10** *(pas mesurée)*
- Sim : **ÉCHEC (temps écoulé)**, deux fois. La relance verbose montre que ce n'est **pas** un blocage du jeu : le gué est pris à
  16:00, puis le joueur scripté reste en « regroup » jusqu'à la fin parce que son seuil `REGROUP_LEAVE = 32` est
  **inatteignable** sous un plafond de 40 pop avec 14 ouvriers (armée max ~26). Bug du test.
- Marche : premier 2v2 joué du côté de Malrik, le gué qui ralentit, le Gloom Deacon et son Umbral Passage : bon spotlight.
- À corriger : réparer la sim (seuil à 24, ou `min(32, pop_cap - workers)`) pour avoir un temps. Côté jeu : vérifier qu'un
  joueur à 40 pop peut vraiment tenir les trois étendards (la sim n'y arrive jamais).
- Blocage / cheese : pas de blocage du jeu prouvé ; le plafond de 40 pop est serré pour un 2v2.

**e3m2, Une autre nuit** (cible 14-18 min), **7/10**
- Sim : victoire 10:19 (11:31), 4 chariots sur 4, 3 alarmes, nuit finie à 7:47 ; `sec_unseen` échoué.
- Marche : miroir de m00 (même femme, l'autre côté du couteau), mécanique de commando fraîche, Hush appelable à la fin.
- À corriger : courte ; un humain fera plus d'alarmes, donc ça s'équilibre. Les touches F / Q / E de Hush doivent être montrées
  à l'écran au départ (sinon on ne sait pas qu'elle a des sorts). `e3m2_embers` : 25 s sans réplique, à couper.
- Blocage / cheese : rien vu.

**e3m3, Le Prix de la pierre** (cible 20-25 min), **7/10**
- Sim : victoire 17:08 (18:28), 4 chandelles, crypte jamais sous 100 %, **pierre utilisée 0 fois**, Sexton à 16:28.
- Marche : bon dilemme moral (le pouvoir de la pierre et son prix), Sexton en boss, Reaver en spotlight cohérent.
- À corriger : la sim n'utilise jamais la pierre et gagne quand même facilement : le pouvoir n'est pas assez tentant. Le
  rendre utile à un moment précis (une porte qui ne tombe qu'avec lui, ou un Sexton qui charge). Le Sexton est une capsule
  (placeholder 7 000 HP) dans ses films.
- Blocage / cheese : rien vu.

**e3m4, La Tempête sur la crête** (cible 24-30 min), **8/10**
- Sim : victoire 20:43 (22:03), 3 brisures de tempête, 3 Nightmare Knights (charge réussie), 1 guet sur 3 tenu.
- Marche : Vey en boss-héros qui ne meurt pas, trois tempêtes à briser : structure claire et dramatique. Spotlight Nightmare
  Knight parfait (« The old man can't stop a horse. »). Une des meilleures missions.
- À corriger : 30 morts sur la tempête de Vey (VeyStorm) : bien signaler la zone (anneau au sol) avant chaque frappe. Un 4e
  assaut répète A3 si on rate une brisure : dire au joueur pourquoi ça recommence.
- Blocage / cheese : rien vu.

### Épisode 4, « Ce qui repousse » (Ysolde)

**e4m1, Tenir Lark Hill** (cible 22-28 min), **8/10**
- Sim : victoire 22:01 (22:53), 27 villageois sauvés / 3 perdus, gué tenu, arbre intact.
- Marche : pile dans la cible, l'autre côté de e3m1 (même carte, autre camp) : super idée de structure. Les cloches à sonner
  donnent des petites tâches claires. Bramblesage en spotlight au gué.
- À corriger : carte plate (pas de collines) alors que tout le texte parle de « Lark Hill » : ajouter au moins une butte autour
  de l'arbre. Beaucoup de morts « ? » dans le log (tueur inconnu) : vérifier que les sorts tagguent leur auteur.
- Blocage / cheese : rien vu.

**e4m2, La Route verte** (cible 18-22 min), **7/10**
- Sim : victoire 17:21 (18:14), 40 / 40 arrivés, 0 perdu, Maelis appelée à 7:40 ; `sec_hollow` échoué.
- Marche : escorte avec base, convois qui se cachent quand l'ennemi approche : lisible. Maelis en spotlight.
- À corriger : 34 morts sur Mother Hush pendant les attentes : elle est très forte pour un premier contact Nature ; montrer son
  retour (« Hush revient dans 90 s ») pour que le joueur prépare la riposte. Carte plate, accessoires placeholder.
- Blocage / cheese : rien vu.

**e4m3, Les Cendres gelées** (cible 22-26 min), **5/10**
- Sim : **ÉCHEC des deux sims aujourd'hui**. Rythmée : temps écoulé (34+ min, pas de victoire). Rush : **défaite à 16:57** (Ysolde
  meurt). Les notes « Built » du 08/10 donnaient des victoires à 21:52-24:16. Hypothèse forte : le patch IA Ice d'hier soir
  (`56e1c316`, `commander.gd` + profils Ice, « Ice 17 % → 42 % ») passe aussi dans le Commander de Torvald ici
  (`AIProfile.ice(...)`), qui devient bien plus solide. À confirmer en relançant la sim sur `e021764f`.
- Marche : idée forte (regrowth, cinq bosquets, tenir tout vert), bon film de fin (e4m3_spring 8/10).
- À corriger : remesurer après le patch IA ; si c'est bien lui, isoler les profils de mission (`AIProfile.ice` → profil figé
  `mission_e4_03`). La règle « rooting 30 s » est subtile : la montrer avec un anneau qui se remplit.
- Blocage / cheese : **risque de mur de difficulté** ; les nœuds 4 000 sont là pour éviter la famine, mais un joueur qui perd ses
  armées contre des gardes x2,15 HP va trouver ça très long.

**e4m4, La Fin de l'hiver** (cible 24-30 min), **6/10**
- Sim : victoire 23:57 (25:12), 2 Wallwardens, 1 Treant, Ysolde à 34 % après I2 ; `sec_elder` pas fait, `halls` échoué.
- Marche : siège de mur, Treant en spotlight (x1,0 contre x0,35), et le meilleur film in-mission (e4m4_enough, 8/10).
- À corriger : **l'armée attend 8:20 à la maison** (de 10:39 à 19:00) parce que le Winterheart reste « frost-bound » jusqu'à
  `HEART_OPEN_AT`. C'est le plus long temps mort de la campagne. Remplir l'attente (une vague de contre-attaque, le Sleeping
  Elder à réveiller, une tour à prendre) ou ouvrir le cœur sur un événement (les deux wardens + une 3e brèche).
- Blocage / cheese : pas de blocage ; l'attente forcée est le problème.

### Épisode 5, « L'Étincelle et la Chandelle » (flashbacks)

**e5m1, La Première Étincelle** (cible 12-15 min), **7/10**
- Sim : victoire 11:09 (12:04). Rush : défaite à 2:30 (le rush des balises est bien puni).
- Marche : bon rappel des bases pour qui reprend ici, jeune Vessa + Vey dans sa force, Ember Spire en spotlight.
- À corriger : `e5m1_watch` (« A Road of Fire ») n'a aucun feu ni VFX. Le hold attend le crépuscule (`DUSK_AT`) : afficher
  l'heure du crépuscule pour que l'attente se comprenne.
- Blocage / cheese : rien vu.

**e5m2, Brûler une porte** (cible 16-20 min), **7/10**
- Sim : victoire 14:06 (15:14), 3 bandes repérées, 0 déclenchée. Rush (Vessa seule devant) : défaite à 2:05.
- Marche : la faiblesse de Vessa devient la règle (foncer seule = embuscade) : très bonne idée, bien punie. Archer + Ashby en spotlight.
- À corriger : le rush perd à 2:05 sans que le joueur comprenne forcément pourquoi : un indice « Attends ton armée » à la
  première embuscade. Un peu court.
- Blocage / cheese : rien vu.

**e5m3, Pierres tombales à la chandelle** (cible 12-15 min), **5/10**
- Sim : **ÉCHEC de la sim furtive** : défaite à 12:05, Malrik attrapé par Reeve Pike après la cloche. Rush : victoire 10:44, mais
  les 3 secrets sont lus à **0:43** et la cloche à 1:31 : **le joueur attend ~8 minutes** que minuit (10:00) arrive.
- Marche : la chandelle allumée / soufflée est une super mécanique, les Shades qui brûlent à la lumière aussi.
- À corriger : le plancher de minuit crée un temps mort énorme pour qui va vite ; remplacer par du contenu (les rondes qui
  s'épaississent, un 4e secret optionnel, le Reeve qui fouille). La sim furtive meurt contre le Reeve : sa lanterne x2 est
  peut-être trop dure à la fin. Un indice pour la touche J.
- Blocage / cheese : **attente forcée** ; défaite tardive possible après 12 min de jeu propre (frustrant).

**e5m4, Les Restes** (cible 18-22 min), **7/10**
- Sim : victoire 16:11 (16:56), 3 bannières contre 2, 4 butins. Passif : défaite 15:34 (bien).
- Marche : 1v1 amical, voler ce qu'elle laisse derrière elle : on joue le caractère de Malrik. Grave Hound en spotlight au bon moment.
- À corriger : la cloche ne compte qu'à partir de 12:00 ; afficher « La cloche commence à compter à 12:00 » dès le départ. Fin
  du flashback juste avant ep5_ending : bon enchaînement.
- Blocage / cheese : rien vu.

### Épisode 6, « Le Lac et la Graine » (origines)

**e6m1, Cent hivers** (cible 16-20 min), **7/10**
- Sim : victoire 18:45 (19:55), Heartfrost jamais touché, 2 pierres sculptées. Passif : défaite 4:02.
- Marche : première mission Ice, saisons qui changent, Rimeshield dans les brèches : clair.
- À corriger : **0 banquise cassée** dans la sim : la mécanique signature (la glace qui casse sous l'ennemi) n'arrive pas toute
  seule. Pousser les vagues sur le lac ou montrer un indice « Attire-les sur la glace ». Films e6m1 sans aucun SFX.
- Blocage / cheese : rien vu.

**e6m2, Le Cavalier à la porte** (cible 18-22 min), **8/10**
- Sim : porte ouverte : victoire 17:04 (17:49), 24 / 24 sauvés ; porte fermée : victoire 20:01 (20:46). Les deux branches tiennent.
- Marche : **vrai choix**, deux missions différentes selon la porte, et le choix est sauvé pour l'E8. Très fort.
- À corriger : le film de branche (c_e6_gate / gate_shut) montre les mêmes images : le choix doit se voir. Les films e6m2 n'ont
  aucun son (même pas la porte).
- Blocage / cheese : rien vu (le « plancher » de l'aube est justifié par l'histoire).

**e6m3, L'Année où rien n'a poussé** (cible 14-18 min), **7/10**
- Sim : victoire 16:01 (16:51), 4 jardins à 500 / 500, Whitepelt tué. Passif : défaite 6:19.
- Marche : petite mission de défense douce, loups qui mangent les graines, Thornling en spotlight parfait.
- À corriger : jardins pleins à 500 / 500 pour la sim : facile au normal. `e6m3_spring` (« Show me again ») mérite une floraison VFX.
- Blocage / cheese : rien vu (horloge fixe).

**e6m4, La Première Fissure** (cible 20-24 min), **7/10**
- Sim : victoire 19:00 (20:27), hold 100 % (pause 0:51), sceau min 90 %, 49 morts comptés. Passif : défaite 2:59.
- Marche : Nature et Ice côte à côte, le Maître à genoux qui tient : bonne scène d'origine. Wildwood Archer en spotlight.
- À corriger : pas de rivière ni de douves (carte générée) : les « montées des douves » sortent de nulle part. Le Maître est un
  placeholder. Films sans son.
- Blocage / cheese : rien vu.

### Épisode 7, « De l'or pour le feu » (Torvald)

**e7m1, La Vente aux dragons** (cible 22-28 min), **7/10**
- Sim : victoire 22:46 (23:45), 3 enchères gagnées sur 3, Séraphine ramenée, 2 140 d'or. Passif : défaite 12:37.
- Marche : enchères à dragons = mécanique unique, carte de « portes » qui justifie le Rimecarver.
- À corriger : les dragons sont des Stormcrest Roc mis à l'échelle et ne meurent pas ; le duel du Laurel est 20 s de face-à-face
  sans coups : décevant pour un « duel ». Panneau d'enchères à bien montrer (45 s, ça passe vite).
- Blocage / cheese : rien vu.

**e7m2, Premier sang, et pas plus loin** (cible 18-24 min), **6/10**
- Sim : victoire 17:15 (18:30), 3 indices, **duel perdu** (et la mission gagne quand même), `aldra` échoué. Passif : **aucune fin à
  25:00** (ni victoire ni défaite).
- Marche : enquête (couteaux, registre, héraut), Aldra appelable, révélation Hush.
- À corriger : un joueur qui ne trouve pas les indices **tourne en rond sans fin** : ajouter une échéance (défaite ou indice
  forcé à ~20:00). Le duel perdu ne change rien de visible : soit il compte, soit on ne l'appelle pas un duel. Le spotlight
  Aldra est « failed » dans la sim : vérifier que son premier appel arrive bien.
- Blocage / cheese : **mission sans fin** si le joueur rate les indices.

**e7m3, L'Outwall** (cible 20-25 min), **7/10**
- Sim : victoire 22:01 (23:06), 32 abrités / 8 perdus, 4 cloches. **Mammouths jamais libérés.** Passif : défaite 16:57.
- Marche : « les gens ou les mines », choisi avec les pieds de l'armée : excellent design. Nuit tendue.
- À corriger : le spotlight War Mammoth (libéré vers 14:00) **n'arrive pas** dans la sim : un joueur peut finir l'épisode sans
  jamais voir le titan Ice. Le rendre automatique (ou un indice fort à 13:00).
- Blocage / cheese : rien vu.

**e7m4, L'Année des deux ciels** (cible 25-30 min), **7/10**
- Sim : victoire 23:52 (25:20), le Tournant à 8:01, 1 dragon payé, compteur max 69 %, 3 étapes de « Calmer la mer ».
  Passif : **aucune fin à 28:00**.
- Marche : le climax d'E7 (Torvald dit non, le siège de Malrik change de camp en pleine partie, Ossavar arrive) : le meilleur
  retournement scénarisé du jeu sur papier. Shardguard en spotlight.
- À corriger : le film du Tournant (`e7m4_turn`) est en caméras fixes sans placer personne : le « Non. » peut tomber sur un sol
  vide (voir 3.3). « Calmer la mer » ouvre au plus tôt à 22:00 (plancher) : prévenir le joueur (« la mer se calme à la marée de
  midi, 22:00 ») pour qu'il ne pense pas qu'il a raté quelque chose. Un joueur passif ne perd jamais : ajouter une défaite si le
  rocher tombe.
- Blocage / cheese : pas de blocage, mais pas de défaite pour un joueur qui ne fait rien.

### Épisode 8, « Les Quatre Clés » (finale)

**Choix de la route** (`e8_road_choice`, écran), **6/10**
- Marche : la question « Whose road do you walk? » avec la faiblesse de chacun en info-bulle ; les autres routes s'ouvrent
  pour le rejeu.
- À corriger : quatre boutons texte sur un écran vide, pour **le** choix de la finale. Il faut au minimum les portraits des
  quatre et la phrase de faiblesse **visible** (pas en tooltip). Seule la route de Vessa charge son vrai sac (objets, essence,
  compagnon) ; les trois autres n'ont que l'essence : prévenir ou équilibrer.

**e8m1_fire, L'Étincelle attend** (cible 18-22 min), **7/10**
- Sim : victoire 18:40 (19:45), Faim max 47 %, 6 frappes de l'Orage, 4 éclaireurs revenus. Passif : défaite 9:37.
- Marche : la faiblesse de Vessa retournée (attendre remplit l'Orage de Vey, foncer remplit la Faim) : thème et mécanique collés.
- À corriger : la « rive ouest » est un demi-plan invisible (z - x > 10) marqué par six piquets : la ligne doit se voir au sol
  (une bande de lumière), sinon la Faim monte sans qu'on sache pourquoi. Hold plancher 17:30.
- Blocage / cheese : rien vu.

**e8m1_shadow, Pose la pelle** (cible 18-22 min), **6/10**
- Sim : victoire 17:06 (18:26), 3 portes, pierre utilisée 0 fois. Passif : **aucune fin à 25:00**.
- Marche : le Don de la pierre compté pour la finale (les PV du Roi), Hush qu'on laisse partir : bonne écriture.
- À corriger : Duskbarrow = carte générée avec des blocs de crypte, pas de ruelles ; la porte de l'Escalier n'ouvre qu'à 16:30
  (« au coucher de lune ») : l'annoncer. Pas de défaite pour un joueur passif.
- Blocage / cheese : mission sans fin si le joueur ne fait rien.

**e8m1_ice, La Porte s'ouvre** (cible 18-22 min), **7/10**
- Sim : victoire 17:43 (18:33), 35 réfugiés sauvés / 5 perdus. Passif : défaite 16:23 (27 perdus).
- Marche : ouvrir enfin la porte (la faiblesse de Torvald retournée), et la milice de Kettlewick qui vient si e6m2 a ouvert la
  porte : la conséquence du choix d'E6 se voit. Très bien.
- À corriger : le Mur est dessiné mais traversable (pas d'obstacle) : les chasseurs et l'armée passent à travers les blocs de
  glace. La colonne attend 9:30 au camp (plancher) : rendre cette pause active (défendre le camp).
- Blocage / cheese : rien vu.

**e8m1_nature, Prendre parti** (cible 18-22 min), **7/10**
- Sim : victoire 18:19 (19:04), 3 nœuds défaits, 3 hameaux sauvés, rivière traversée à 11:59. Passif : défaite 16:24.
- Marche : Ysolde doit choisir et agir : thème clair, les hameaux qui brûlent donnent l'urgence.
- À corriger : murs de racines et Thistlewater **dessinés, pas des obstacles** : on traverse le « mur » qu'on est censé défaire.
  La sortie n'ouvre qu'à 18:00 : 6 minutes après la traversée (11:59) à attendre.
- Blocage / cheese : rien vu ; attente en fin de mission.

**e8m2, Le Dernier Rassemblement** (cible 25-30 min), **7/10**
- Sim : victoire 26:31 (27:46), 4 serrures allumées, les trois alliés partis en marche (rassemblement 100 %), Creux à 49 %.
  Passif : défaite 21:31.
- Marche : les quatre royaumes du même bord pour la première fois, chacun porte sa clé à sa serrure : le moment que toute la
  campagne prépare. Bon rythme, dans la cible.
- À corriger : les alliés ne marchent **pas avant 14:00 / 18:00 / 24:00** même avec leur barre pleine (« les cors du
  rassemblement ») : afficher ces heures à côté de chaque barre, sinon remplir la barre semble inutile. Les pings d'alliés sont des
  messages HUD sans roue de ping. Carte 120 m générée au lieu de Fourfold Hollow (168 m) : moins de sentiment d'épopée. Le
  spotlight dépend de la route (Lancer / Barrow Knight / Rimehorn / Thornback) : les quatre intro-cards doivent exister.
- Blocage / cheese : rien vu.

**e8m3, Le Roi creux** (cible 28-35 min), **6/10**
- Sim : victoire 29:56 (30:56), 3 tours de clé, les 4 Key-Wards pleins à la fin. Passif : **aucune fin à 36:40** (une ward à 0,
  pas de défaite).
- Marche : trois phases lisibles (Quatre chaînes → Le Roi marche → Tenir ensemble), le tour de clé à quatre au même moment,
  et le correctif du 10/10 (le monde qui gèle si le Roi tombe pendant une défaite en attente) est bien en place (`is_ending()`).
- À corriger : **le Roi creux est le modèle du Rime Colossus x2,2**. Le boss final de toute la campagne ne peut pas être un
  colosse de glace recoloré : c'est la priorité art n°1. Planchers de phase (phase 2 pas avant 17:00, phase 3 pas avant 25:30,
  chute au 3e tour minimum) : le joueur fort attend sans comprendre ; les annoncer (« les chaînes tiennent encore ») ou les
  remplacer par des conditions de jeu. Pas de défaite quand une ward tombe à 0 : soit la ward compte, soit elle ne doit pas
  s'afficher comme un objectif. Pas de titans (sec_titan retiré).
- Blocage / cheese : le gel du 10/10 est corrigé ; un joueur passif ne perd jamais (à corriger).
## 3. Les films, un par un

**Comment lire ça.** Note /10 = cadrage, lisibilité, rythme, doublures (stand-ins). Les planches contact datent du **08/10 vers 13 h**, donc
**avant** les trois passes de cadrage (`2abd6f22`, `8a31cdd3`, `de22934d`) et le correctif de hauteur de visage (`ea67db1f`).
Quand le problème principal de la planche est listé comme corrigé dans `framing_fixes.md`, je le marque **(corrigé depuis, à
revérifier)** et la note tient compte d'une partie du gain. Les films in-mission d'E1 à E3 sont jugés sur la scène de test vide
(pas de décor) : je juge le cadrage seulement. Ceux d'E4 à E8 n'ont pas de planche : je les juge sur le `.cine` (caméras, cast,
SFX/VFX, longueur).

### 3.1 Prologue, ouvertures, films entre les missions, fins

| Film | Note | Ce qui accroche le plus |
|---|---|---|
| prologue_3min (3:00, 36 plans) | **9** | Le meilleur film du jeu. Citadelle superbe, 4 intros de royaume très lisibles. Seuls défauts : S12 boîtes sans texture, S13 plan presque noir (la chandelle seule). |
| c1_offer (1:21) | 6 | Dalles de glace au premier plan (O2/O6/O8), Malrik de dos (O4), visages sous-éclairés. O2/O4/O7 (corrigé depuis, à revérifier) ; l'éclairage des visages reste. |
| c2_two_fronts (1:23) | 7 | Correct. Vessa cachée par la table / le bâton en S2/S5, tête du garde coupée S4. |
| c3_parley (1:45) | 7 | Bon texte, un peu long. P6/P7 de dos sur la ligne d'axe (corrigé depuis) ; P10 plan large vide à la fin : ça finit à plat. |
| ep2_opening (1:12, 28 répliques) | 7 | Beau décor de festin. Sur la planche : **pas bakée** (musique + 3 SFX manquants). Bakée depuis avec du son « stand-in » (`ea67db1f`) : la vraie musique `ep2_opening.wav` et les SFX foule / cor / galop manquent encore. |
| c_e2_ashes (1:15) | 6 | Le dos de Vessa mange la moitié du cadre (A3/A6), ECU bizarre de dos (A5) (corrigé depuis). Visage d'Ysolde pas éclairé (A2). |
| c_e2_lodge (1:01) | **8** | Propre, rythme serré. Juste L8 sur une nuque. |
| c_e2_stair (1:25) | 5 | **Trop sombre** : silhouettes. Bâton dans la face de Vessa (T4/T7) corrigé depuis ; l'éclairage, lui, n'a pas bougé. |
| ep2_ending (1:25) | 4 | **Aucun décor** : un disque sombre dans le vide, des abat-jour. Caméra dans la robe du Maître (S5/S7) corrigée depuis, mais le vide reste. Une fin d'épisode mérite un vrai lieu (la caverne de la Porte). |
| ep3_opening (1:31) | **8** | Bon. N10 tête coupée. |
| c_e3_knife (1:08) | 6 | Taches de reflet (B14), visages sombres. K6 corrigé depuis. |
| c_e3_price (1:04) | 5 | Sombre + reflets ; reflet de lampe sur un visage (P5), Torvald coupé (P8) (corrigés depuis). L'éclairage reste le vrai problème. |
| c_e3_doubt (1:05) | 5 | Aldra en **capsule** ; 4 plans presque identiques de Torvald tête coupée (corrigé depuis : 2-shot ajouté). Reste la capsule. |
| ep3_ending (0:58) | 4 | Nuit boueuse, gros reflets, faisceaux délavés ; Aldra et Obren (capsules) **jamais à l'écran**. |
| ep4_opening (1:28) | **9** | Le meilleur des ouvertures après le prologue. Rien à signaler. |
| c_e4_frontier (1:10) | **8** | Bon. Orbe lumineux collé au visage (F3). |
| c_e4_refuge (1:10) | 6 | Géométrie sombre en diagonale (R4B), reflets R5/R7/R8, bâton au premier plan (R2). R5 corrigé depuis. |
| c_e4_turnback (1:10) | 7 | Grosses taches sombres sur le haut des inserts (T6/T7). Sinon correct. |
| ep4_ending (1:00) | 7 | Poteau de lampe dans la face de Vessa (W4, corrigé depuis). Sinon bien. |
| ep5_opening (3:00, 32 plans) | 7 | Réutilise beaucoup le prologue (S01-S13) : pour un joueur qui enchaîne, c'est **3 minutes de déjà-vu**. Pilier au premier plan (VD1/MD1). À couper à ~1:45. |
| c_e5_turn (0:30) | 4 | Caméra dans la robe de Malrik (U2/U4) : on ne voit pas la chandelle. Corrigé depuis avec une chandelle de la citadelle, mais **blanche** (le script veut violette). |
| ep5_ending (0:40) | 6 | 3 plans sur 7 = le Maître de dos, tête coupée (N4 corrigé depuis). |
| ep6_opening (3:00, 24 plans) | 6 | Réutilise le prologue ; sujets minuscules au loin (T02/T03/T04/T08). Encore 3 minutes. |
| c_e6_lake (0:40) | 5 | Très sombre, Torvald et Aldra en silhouettes. K3 bâton dans le visage (corrigé depuis). |
| c_e6_gate / c_e6_gate_shut (0:35) | 5 | Les deux variantes donnent **les mêmes images** : le choix du joueur (porte ouverte / fermée) ne se voit pas. G1/G4 plans larges sans personnage. |
| c_e6_seed (0:40) | 5 | D3 = un dos sombre (corrigé depuis), D1 sujet minuscule. |
| ep6_ending (0:50) | 4 | Tache blanche surexposée sur le sujet (X2), tête du Maître = blob lumineux (X3/X4) (corrigés depuis), champ de débris noir (X1, éclairage pas touché). |
| ep7_opening (3:26, 41 plans) | 6 | **Trop long**. Plans de sable vide (D08B), sol nu vu de haut (D12), beaucoup de désert pauvre en détails. À couper à ~2:00. |
| c_e7_ledger (1:10) | 6 | Pièces = cylindres sans texture (G3), grosse tache rose (G4), épaule qui bouche le cadre (G9/G10, corrigé depuis). |
| c_e7_mask (1:10) | 6 | Même cadrage répété, visage collé à l'objectif (M5/M7), insert de table vide (M3) (corrigés depuis). |
| c_e7_pits / c_e7_pits_pits (1:10) | 6 | Ne diffèrent que par le dragon (P7). P10 large vide, P4 tête coupée. |
| ep7_ending (1:10) | 7 | Caméra dans la robe de Torvald (N8). Sinon bien. |
| ep8_opening (2:00) | 6 | O2A murs vides sans sujet ; O6 silhouette blanche surexposée. |
| c_e8_muster (1:20) | 6 | Sujets petits, moitié du cadre = herbe sombre (M1-M3, corrigés depuis), reflet M5. |
| ep8_throne_vessa / torvald / malrik / ysolde (0:08) | 5 | Un seul plan chacun, visage caché (de dos, bâton, chapeau). Corrigé depuis (caméra de face) : à revérifier, c'est **la réplique de tentation**, elle doit se lire. |
| ep8_ending_a (1:50, 17 plans) | **4** | **La fin du jeu et le film le plus faible de l'E8.** E04 dôme orange vide, E05 noir + lueur, E10 cône blanc plein cadre, E12 robes qui se traversent, E13 trône vide, visages collés en haut (E02A-D). Corrigé en partie depuis, mais le **Roi agenouillé n'est jamais visible** (caché derrière le trône) et E05 n'a pas de fissure. |
| ep8_ending_b (1:07) | 7 | E22 plan presque vide (corrigé depuis : la poussée va jusqu'aux pousses de chêne), E19 surexposé. |
| ep8_dark_fire / ice / nature / shadow (0:45) | 6 | Flare blanc sur la tête du sorcier en T1 (les quatre). T3 vu de haut. |
| ep8_bookend / ep8_bookend_dark (0:35) | 5 | Les deux variantes donnent les mêmes images. E25 dos de l'enfant plein cadre (corrigé depuis : contrechamp), E25B délavé ; pas de pose « mains en coupe ». |

### 3.2 Films in-mission, Épisodes 1 à 3 (planche sur scène vide : cadrage seulement)

| Film | Note | Ce qui accroche le plus |
|---|---|---|
| m1_westwatch | 6 | W1 = le dos de la robe plein cadre. |
| m1_seal | 6 | S1 cadre vide. |
| m1_crown | 7 | OK. |
| m1_watchers | 6 | H2 presque vide. |
| m2_heartfrost | 5 | H1 cadre vide, une seule réplique pour 11 s. |
| m3_oldroot | 4 | Aucun personnage, aucune réplique : 12 s de lumière. À couper à 5 s ou à mettre en jeu. |
| m3_plea (0:40) | 6 | Y5 gros plan d'épaule de dos (corrigé depuis). Bon texte. |
| m3_parting (0:40) | 6 | P3 nuque d'Ysolde. |
| m4_war (0:30) | 6 | W1 presque vide. |
| m4_fall (0:06) | **3** | Les deux plans = une **capsule géante étiquetée « HEART_STONE »**. Si ça passe en jeu tel quel, c'est le pire plan du jeu (fin d'E1). |
| e2m1_arrival | 5 | Messager en capsule ; A1 sujet minuscule, A3 pilier de lumière seul. |
| e2m1_frostwarden | 5 | F2 sujet minuscule. |
| e2m1_ysolde (0:30) | 5 | Y3 minuscule, Y4 gros plan de robe. 2 répliques pour 30 s : lent. |
| e2m2_first_grove | 7 | OK. |
| e2m2_heartwood | 5 | H1 vide (lueur), H4 minuscule. |
| e2m2_muster | 6 | M1 sujets minuscules. |
| e2m2_two_banners | 5 | B1 cadre vide. |
| e2m3_lodge | 4 | Capsule « BETTANY » = le sujet des deux plans. À vérifier en jeu (a-t-elle un modèle ?). |
| e2m3_paid | 4 | P1 vide, P2 capsule BETTANY. |
| e2m3_road | 5 | R1/R3 vides (figurants capsules invisibles). |
| e2m4_descent | 5 | D1 presque noir. |
| e2m4_first_warden | 5 | W1 pilier surexposé + orbes. |
| e2m4_forge | 4 | F1 gros plan de robe, F2 capsule « ASHBY ». |
| e2m4_hush | 5 | H1 minuscule. |
| e2m4_sunrise (0:30) | 5 | S2 surexposé, S4 vide. |
| e2m5_cavern | 4 | Vey et Malrik en capsules sur la scène de test ; C1 pilier seul, C3 minuscule. |
| e2m5_breach | 4 | Un seul plan, un orbe, pas de cast. |
| e2m5_fall | 4 | F1 pilier surexposé seul. |
| e2m5_wake (0:30) | 4 | K2 vide, K4 moitié lueur blanche. |
| e2m5_answer | 3 | A1 **cadre tout blanc** (brûlé). |
| e3m1_dusk (0:30) | 5 | D1/D4 vides ; D3 ECU (corrigé depuis). |
| e3m1_ford | 7 | OK. |
| e3m1_standard | 4 | Les deux plans vides (sujets absents de la scène de test). |
| e3m2_slip | 5 | S1 minuscule, S3 vide. |
| e3m2_embers (0:25) | 4 | E1/E2 vides, aucune réplique. |
| e3m2_dawn (0:30) | 5 | W1/W3 minuscules (W4 corrigé depuis). |
| e3m3_homecoming | 5 | H1 minuscule. |
| e3m3_offer | 5 | O1 épaule en ECU (corrigé depuis). |
| e3m3_sexton | 4 | Les 3 plans = capsule SEXTON, petite ; X2 voix 3,63 s dans un créneau de 3,54 s. |
| e3m3_rest (0:30) | 5 | R1 capsule SEXTON, R4 presque vide. |
| e3m4_return | 5 | R1 vide, R4 dôme violet seul. |
| e3m4_whisper | 6 | H2 épaule (corrigé depuis). |
| e3m4_field (0:45) | 5 | Vu sur la planche : F3 et F6 = deux points au loin sur un sol vide ; F2 le chapeau de Vessa bouche la gauche. En jeu, le décor comblera le vide, mais F3/F6 restent trop larges. |

### 3.3 Films in-mission, Épisodes 4 à 8 (jugés sur le `.cine`)

Tendance nette quand on lit les 64 fichiers dans l'ordre :
- **E4** : caméras `orbit` qui suivent les vraies unités, VFX et SFX (glace, cage, pas dans la neige). C'est le standard à viser.
- **E5** : `orbit` + `static`, plus de VFX, 1 ou 2 SFX.
- **E6** : **0 SFX, 0 VFX** dans les 9 films. Juste des voix sur des plans.
- **E7 et E8** (34 films) : **100 % caméras `static`** pointées sur des coordonnées fixes, tout le cast en capsules cachées, 0 SFX, 0 VFX.
  Le joueur contrôle son héros : rien ne garantit qu'il est là où la caméra regarde. Exemple : `e7m4_turn` N3 « CU Torvald,
  long hold, then *No.* » vise (-34, 1.7, 34) ; si Torvald est sur le Tollrock, le « Non » de tout l'épisode tombe sur un sol vide.
  Autre exemple : `e8m3_king` S4 vise le siège A1 (-17.5, 17.5) pour la réplique de **Malrik**, alors que A1 est le siège **du joueur** :
  sur la route de Vessa, la caméra montre Vessa pendant que Malrik parle.

| Film | Note | Ce qui accroche le plus |
|---|---|---|
| e4m1_foot / e4m1_horn | 7 | Courts, orbit sur Torvald / Ysolde, SFX. OK. |
| e4m1_nightfall (0:30) | 7 | 5 plans, crane + dolly, belle fin de mission. |
| e4m2_border (0:30) | 6 | Ashby en capsule visible. |
| e4m2_hush / e4m2_lantern | 6 | Lantern : narrateur seul, pas de personnage. |
| e4m3_arrival / e4m3_aldra / e4m3_shoot | 7 | Beaucoup de VFX (6 dans arrival). |
| e4m3_spring (0:35) | **8** | 7 VFX, 4 répliques, le printemps qui revient : bon moment. |
| e4m4_arrival / e4m4_wardens / e4m4_thaw | 7 | Corrects. |
| e4m4_enough (0:40, 7 plans) | **8** | Le meilleur in-mission du jeu sur papier : cage de glace, « Enough, Aldra. », grue sur le blizzard. Le VFX `glass_prison` manque (repli ice_burst). |
| e5m1_valley / e5m1_watch (0:40) | 6 | Aucun VFX ; « A Road of Fire » sans feu. |
| e5m2_door (0:08) / e5m2_rookhold | 6 | Door = 1 plan, 1 réplique : bien. |
| e5m2_morning (0:45) | 6 | « Very Good Toast » : 3 répliques pour 45 s, long. |
| e5m3_wickmoor / e5m3_found (0:45) | 6 | « This One, Too » mérite un VFX (l'ourlet qui brûle) ; 0 VFX. |
| e5m4_green / e5m4_bell | 6 | Corrects, statiques. |
| e6m1_heartfrost (0:42) / e6m1_return (0:45) | 5 | 7 et 6 répliques, 0 SFX : radio sur images. |
| e6m2_rider / dawn_open / dawn_shut | 5 | 0 SFX ; la porte qui s'ouvre ou reste fermée sans un son. |
| e6m3_spring (0:36) | 5 | « Show Me Again » : le moment clé d'Ysolde, sans un seul VFX de floraison. |
| e6m4_crack / first_crack / down | 5 | first_crack : 2 plans statiques, narrateur « the amber came up » sans ambre ni son. |
| e7m1_arrival / dusk / laurel | 4 | Statiques, cast caché, 0 son ; rien ne garantit que les sujets sont dans le cadre. |
| e7m2_herald / knives / laurel_call / mask / morning | 4 | Idem. laurel_call : 3 plans, **0 réplique**, 8 s. |
| e7m3_boats / dawn / outwall / unmask | 4 | Idem. « Violet Under Grey » (le démasquage) sans aucun effet. |
| e7m4_dawn / still / turn / two_skies | 4 | `turn` = le climax d'E7 (voir plus haut). two_skies : 5 locuteurs, tous cachés. |
| e8m1_fire_stakes / fire_storm | 4 | Statiques ; « The Great Storm » sans orage. |
| e8m1_ice_gate / ice_south | 4 | Idem. |
| e8m1_nature_out / nature_road | 4 | Idem. |
| e8m1_shadow_father / home / hush / stair | 4 | Idem, très courts. |
| e8m2_hand / seats / turn | 4 | `turn` (0:38, 7 locuteurs) : le moment des quatre clés, en plans fixes muets. |
| e8m3_chains / king / walk | 4 | `king` : bon texte (« What could possibly go wrong. »), mais S4 vise le mauvais siège selon la route. |

## 4. Synthèse

### 4.1 Les 5 meilleures missions
1. **e3m4, La Tempête sur la crête (8)** : boss-héros qui ne meurt pas, trois tempêtes à briser, spotlight parfait.
2. **e6m2, Le Cavalier à la porte (8)** : un vrai choix, deux missions jouables, conséquence en E8 (e8m1_ice).
3. **e4m1, Tenir Lark Hill (8)** : l'autre côté de e3m1, cloches + arbre + gué, pile dans la cible.
4. **e8m2, Le Dernier Rassemblement (7)** : le moment que toute la campagne prépare, dans la cible.
5. **e7m3, L'Outwall (7)** : « les gens ou les mines » choisi avec l'armée ; meilleure idée de design d'E7.

### 4.2 Les 5 pires missions (pour un premier joueur, aujourd'hui)
1. **m02, L'Orbe sous la glace (5)** : se rushe en 7:48 sur une cible de 18-24 ; le test échoue.
2. **e4m3, Les Cendres gelées (5)** : les deux sims échouent aujourd'hui (mur de difficulté, probablement le patch IA Ice).
3. **e5m3, Pierres tombales (5)** : 8 min d'attente forcée si on va vite, défaite tardive contre le Reeve sinon.
4. **e2m2, Racines et braises (6)** : l'assaut de Rimehold rase l'armée et l'économie ne repart pas (1 sim sur 2).
5. **e4m4, La Fin de l'hiver (6)** : 8:20 à attendre à la maison que le Winterheart dégèle.

### 4.3 Films
- **Meilleurs** : prologue_3min (9), ep4_opening (9), c_e2_lodge (8), ep3_opening (8), c_e4_frontier (8), e4m4_enough (8),
  e4m3_spring (8).
- **Pires** : m4_fall (3, capsule « HEART_STONE »), e2m5_answer (3, cadre brûlé blanc), **ep8_ending_a (4, la fin du jeu)**,
  ep2_ending (4, pas de décor), ep3_ending (4), ep6_ending (4), c_e5_turn (4), et les 34 in-mission d'E7-E8 (4, caméras fixes
  muettes).
- **Tendances** : (1) les entre-films d'E2, E3 et E6 sont trop sombres (silhouettes, reflets) : une passe d'éclairage des visages
  réglerait 8 films d'un coup ; (2) ep5, ep6 et ep7_opening durent 3:00-3:26 et réutilisent le prologue : à couper vers 1:45-2:00 ;
  (3) les variantes de branche (c_e6_gate / gate_shut, ep8_bookend / bookend_dark, c_e7_pits / pits_pits) donnent presque les
  mêmes images : le choix du joueur ne se voit pas ; (4) les films in-mission ont perdu leurs SFX / VFX à partir d'E5 et leurs
  caméras vivantes à partir d'E7.

### 4.4 Les 10 correctifs les plus importants pour un premier joueur
1. **Donner un vrai modèle aux boss** : le Roi creux (Rime Colossus x2,2 aujourd'hui), le Doorwarden (capsule de 16 m), le
   Sexton (placeholder), et remplacer la capsule « HEART_STONE » de m4_fall. Le Roi d'abord : c'est la dernière image jouée.
2. **Placer le cast avant chaque film in-mission d'E7-E8** (34 films) : téléporter / cacher les héros sur les marques du film,
   ou passer les plans perso en `cam=orbit pivot=<héros>` comme en E4. Commencer par `e7m4_turn` (« No. ») et `e8m3_king`
   (S4 vise le siège du joueur, pas celui de Malrik). Remettre au moins 2-3 SFX par film.
3. **Refaire ep8_ending_a** : le Roi agenouillé visible, une vraie fissure en E05, le Maître lisible, E04 / E13 pas vides.
4. **Mettre des planchers / conditions aux Épisodes 1-2** comme en E4-E8 : m02 (Orbe attaquable seulement après W2 ou une
   fouille à X %), m03 (Sceau scellé jusqu'à ~14:00), e2m1 (pas d'allumage tant qu'un totem vit dans 30 m), m04 (le siège pas
   avant 10:00). Viser au moins 70 % de la cible du spec dans la sim.
5. **Remplir ou afficher les attentes forcées** : e4m4 (8:20 avant le Winterheart), e5m3 (minuit à 10:00), e8m1_nature (sortie à
   18:00), e8m2 (marches à 14 / 18 / 24:00), e8m3 (phases à 17:00 / 25:30), e7m4 (22:00). Au minimum un compte à rebours à
   l'écran avec la raison de l'histoire ; idéalement une tâche pendant l'attente.
6. **Ajouter une défaite ou un indice forcé aux missions sans fin** : e7m2 (on peut rater les indices et tourner à l'infini),
   e7m4, e8m1_shadow, e8m3 (une ward à 0 sans conséquence).
7. **Remesurer e4m3 / e2m2 / e5m3 et figer les profils IA des missions** : relancer leurs sims sur `e021764f` (avant le patch
   Ice) pour confirmer ; si c'est lui, les missions ne doivent pas hériter des réglages de skirmish (`AIProfile.ice(...)` →
   profil de mission figé). Réparer la sim e3m1 (`REGROUP_LEAVE` 32 → 24) et écrire une vraie sim m01.
8. **Filet de sécurité économique dans e2m2** (et e4m3) : relève gratuite ou nœuds plus riches après un assaut raté, pour qu'une
   armée rasée à Rimehold ne finisse pas en partie morte.
9. **Rendre visibles les règles « dessinées »** : en E8, le Mur, les murs de racines, la Thistlewater et la « rive ouest » sont des
   marques qu'on traverse ; en E4-E6, les cartes plates contredisent le texte (« Lark Hill »). Une bande au sol, une collision, une
   butte : le joueur doit voir la règle.
10. **Indices et spotlights qui n'arrivent pas** : montrer la règle du noir (e2m4), les touches de Hush (e3m2), la touche J (e5m3),
    le panneau d'enchères (e7m1), le bouton de tribut (e2m3), le panneau « Envoyer Ysolde » (e2m2) ; et forcer les spotlights que
    la sim n'a jamais vus : mammouths d'e7m3, banquises d'e6m1, pierre d'e3m3, dragon qui *vole* d'e2m5.

### 4.5 Courbe de difficulté (normal)

Difficulté = estimation pour un **premier joueur** (1 très facile, 5 mur), à partir des pertes, des défaites passives, des échecs
de sim et des pics signalés. « Jeu » = temps de mission + films in-mission, sim.

| # | Mission | Cible | Sim (jeu) | vs cible | Diff. | Commentaire |
|---|---|---|---|---|---|---|
| 1 | m00 | 9-12 | 8:02 (nuit fixe) | dans | 1 | 0 perte en A4 : trop doux |
| 2 | m01 | 15-20 | pas mesurée | ? | 2 | écrire une sim |
| 3 | m02 | 18-24 | 7:58 | **−60 %** | 2 | rush de l'Orbe |
| 4 | m03 | 20-25 | 11:33 | −50 % | 2 | course au Sceau trop tôt |
| 5 | m04 | 22-28 | 16:42 | −30 % | 3 | boss, siège précoce |
| 6 | e2m1 | 20-25 | 14:22 | −35 % | 2 | allumage à 1:14 |
| 7 | e2m2 | 22-28 | 18:47 / **temps écoulé** | −20 % | **4** | piège de Rimehold |
| 8 | e2m3 | 18-24 | 18:56 | dans | 3 | |
| 9 | e2m4 | 17-23 | 15:54 | −10 % | 3 | |
| 10 | e2m5 | 25-31 | 19:54 | −25 % | 3 | boss capsule |
| 11 | e3m1 | 22-28 | pas mesurée (sim cassée) | ? | 3 | plafond 40 pop serré |
| 12 | e3m2 | 14-18 | 11:31 | −20 % | 2 | |
| 13 | e3m3 | 20-25 | 18:28 | −10 % | 3 | |
| 14 | e3m4 | 24-30 | 22:03 | −10 % | 3 | |
| 15 | e4m1 | 22-28 | 22:53 | dans | 3 | |
| 16 | e4m2 | 18-22 | 18:14 | dans | 3 | Hush très forte |
| 17 | e4m3 | 22-26 | **échec** (temps écoulé ; rush : défaite 17:22) | — | **5** | pic de la campagne |
| 18 | e4m4 | 24-30 | 25:12 | dans | 4 | 8:20 d'attente |
| 19 | e5m1 | 12-15 | 12:04 | dans | 1 | rappel des bases |
| 20 | e5m2 | 16-20 | 15:14 | −5 % | 2 | |
| 21 | e5m3 | 12-15 | **échec** furtif (défaite 12:05) ; rush 11:41 | — | 3 | attente de minuit |
| 22 | e5m4 | 18-22 | 16:56 | −5 % | 2 | |
| 23 | e6m1 | 16-20 | 19:55 | dans | 2 | |
| 24 | e6m2 | 18-22 | 17:49 (ouverte) / 20:46 (fermée) | dans | 3 | |
| 25 | e6m3 | 14-18 | 16:51 | dans | 2 | |
| 26 | e6m4 | 20-24 | 20:27 | dans | 3 | |
| 27 | e7m1 | 22-28 | 23:45 | dans | 3 | |
| 28 | e7m2 | 18-24 | 18:30 | dans | 3 | pas de fin si passif |
| 29 | e7m3 | 20-25 | 23:06 | dans | 3 | |
| 30 | e7m4 | 25-30 | 25:20 | dans | 4 | |
| 31 | e8m1 (4 routes) | 18-22 | feu 19:45 · ombre 18:26 · glace 18:33 · nature 19:04 | dans | 3 | |
| 32 | e8m2 | 25-30 | 27:46 | dans | 4 | |
| 33 | e8m3 | 28-35 | 30:56 | dans | 4 | Roi = colosse recoloré |

**Lecture de la courbe.** E1-E2 sont plats et courts (difficulté 2, temps à −30 / −60 %) : le premier joueur risque de trouver
le début « mince » alors que c'est là qu'il décide s'il continue. E2m2 fait un saut à 4 au milieu d'un épisode à 2-3. E4 monte
fort jusqu'au **pic e4m3 (5)**, puis E5 redescend à 1-2 (voulu : flashbacks et rappel des bases, ça donne une respiration après
le pic). E6 reste doux, E7 et E8 tiennent un plateau de 3-4 bien calé sur les cibles. Correctif de forme : remonter E1-E2 d'un
cran (plus de contenu, pas plus de dégâts), adoucir e4m3 et e2m2 d'un cran, et garder la redescente d'E5.
