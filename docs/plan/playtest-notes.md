# Notes de playtest — 13 octobre 2026 (version `playtest-2026-10-13-2`)

## Comment jouer
- `FourWizards-2026-10-13.zip` sur le Bureau et dans OneDrive : décompresse, puis double-clic sur **`Jouer.bat`**
  (lance `FourWizards.exe` avec `FourWizards.pck`). RTX 3070 en « Performances élevées », chargeur branché.
- Pourquoi un `.pck` et pas un seul `.exe` : les modèles d'export de Godot 4.7.2 manquent sur ce PC. Le jeu tourne
  avec le moteur Godot officiel renommé `FourWizards.exe` + le paquet du jeu. Aucun téléchargement n'a été fait ;
  les modèles peuvent être réinstallés plus tard avec ton OK (un vrai `.exe` unique, plus léger).
- Les réglages et les sauvegardes sont les mêmes que le jeu de développement (même dossier utilisateur).

## Nouveau depuis le dernier playtest
### Revue complète du code (scripts/) et ses corrections
- Bots : les bugs trouvés par la revue des bots sont corrigés (constructions bloquées, routes de commerce, lanceurs de sorts, champions,
  sauvegarde des bots). Vessa (bot) refait son Pas de braise pour fuir à 25 % de PV.
- Jeu : unités poussées hors des bâtiments sans perdre leurs ordres, modificateurs de stats qui ne soignent plus
  par erreur, Mère Hush n'annule plus les ordres de ceux qui l'attaquent (elle leur fait seulement lâcher la cible).
- Interface, cinématiques, objets, bâtiments : corrections de la revue (liste dans
  `docs/handoff/code-review-2026-10-12.md`).
### Sauvegardes dans les missions
- **F12 / Ctrl+F12** marchent maintenant dans toutes les missions des épisodes 1 à 8 : phases, minuteries, alliés,
  dragons, cloches, etc. sont restaurés. Pendant une cinématique, la sauvegarde est refusée (message).
### Traduction
- Les nouveaux textes des missions et des améliorations sont traduits (100 % en jeu).

## Problèmes connus
- **Équilibrage, rythme Normal** : Feu gagne trop souvent contre Ombre (≈ 72-75 %, surtout à Crown Hollow).
  En Blitz c'est correct (Feu 58, Nature 60, Ombre 52), sauf **Glace faible en Blitz** (29 %).
  Cause confirmée (test A/B) : la correction de Mère Hush. Avant, elle arrêtait net les attaques du bot Feu (Ombre gagnait alors 10 / 12). On garde la correction et on compensera Ombre.
- **e6m2 (épisode 6, mission 2) en difficile** : très dur, même avant les corrections.
- **e8m3 (mission finale)** : la Frappe de clé de voûte du roi punit les groupes serrés ; Vessa ne régénère pas
  ses PV, les potions comptent.
- e3m1, e4m4, e5m4 : nos joueurs simulés échouent encore (déjà avant les corrections) ; les missions elles-mêmes
  semblent correctes, dis-moi si tu bloques.

## Dis-moi
- Les sauvegardes en mission : sauvegarde / recharge au milieu d'une mission, tout revient comme avant ?
- Les bots te paraissent-ils plus solides (moins de bases figées, d'armées qui tournent en rond) ?
- Feu contre Ombre en Normal : tu sens l'écart ?
