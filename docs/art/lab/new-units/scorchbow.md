# Scorchbow (Fire bowman), art report

Start 11:38, end 12:15 (laptop, 2026-09-27; medium effort). Scene `art/units/fire/scorchbow/scorchbow.tscn` (script
`scorchbow.gd`, extends FireModel). Art Lab output `docs/art/lab/new-units/scorchbow/`, refs ember_archer, flame_guard, pyre_adept.

| Run | Wall | Quality | FAIL / WARN | Change |
|---|---|---|---|---|
| 1 | 27 s | 61 | parse error (`_string` / `_arrow` clash with FireModel) | renamed members |
| 2 | 41 s | 93 | 0 / 0 | first build |
| 3 | ~45 s | 93 | 0 / 1 (R6cb) | plume, breastplate, body_height 1.65 (UnitType) |
| 4 | ~45 s | 95 | 0 / 0 | fire pot moved from hip to a back brazier (P5), dark gambeson (R6cb) |
| 5 | ~45 s | 95 | 0 / 0 | wider brim, bigger plume (plateau: stop) |

Final: PASS 95. 11 meshes / 11 draws, 2483 verts, 1 glow point (PotFire), 0 lights, B13 0.0033 ms, R2 max IoU 0.64 (Ember Archer).

Built: a stocky veteran war-bowman. Bronze kettle helm (wide brim, crest ridge, swept-back team plume), bearded face,
fur collar, dark team gambeson under a bronze half-breastplate, big bronze pauldron on the bow shoulder, leather skirt,
bronze greaves, hip quiver with red fletching. Hook: a 1.95 m dark-wood greatbow with bronze horn caps held upright.
Glow: a bronze brazier cup on a bracket behind the right shoulder; the drawn arrow's head burns (ArrowFlame, own glow).
Hooks: `play_attack` (bow_draw 0.65 s, release 0.15, recoil step), `play_cast` (arcing high shot, 1.0 s),
`get_bow_tip_position()`. Reused: the Frostbow bow rig (counter-rotated Bow node, string / drawn string / arrow swap,
tracks), FireModel burn death, the kit palette.

Next: 1) C1 shape richness 55 (low-sided cylinders); 2) P1 hook 1.9 (the plume could flare more); 3) gameplay could
use `get_bow_tip_position()` for the burning-arrow projectile spawn.

## Art Lab notes
- R8 measures the bow top (1.93 m) as "head top": a tall upright bow reads as a head-height problem.
- R5 names the glow point from the closest part (Wildwood's bud was reported as "BowString").
- A lab run printed another file's parse error ("Warning treated as error") with no path: the wrapper filter hides the file name.
