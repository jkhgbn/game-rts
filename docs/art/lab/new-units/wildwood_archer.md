# Wildwood Archer (Nature bowman), art report

Start 11:50, end 12:15 (laptop, 2026-09-27; medium effort). Scene `art/units/nature/wildwood_archer/wildwood_archer.tscn`
(script `wildwood_archer.gd`, extends NatureWarModel). Art Lab output `docs/art/lab/new-units/wildwood_archer/`, refs
burr_slinger, vinelasher, thornling.

| Run | Wall | Quality | FAIL / WARN | Change |
|---|---|---|---|---|
| 1 | 80 s | 92 | 1 / 0 (B4 2581 verts) | first build |
| 2 | ~45 s | 91 | 0 / 2 (R5 0 points, R12 night) | fewer leaves, curved bow, smaller bud |
| 3 | ~45 s | 92 | 0 / 0 | brighter bud, light jerkin |
| 4 | ~45 s | 93 | 0 / 0 | bark kilt (R3) |
| 5 | ~45 s | 93 | 0 / 0 | ochre jerkin (the pale suede read as bare skin) |
| 6 | ~45 s | 94 | 0 / 0 | team-dark leaf capelet (R3 dE 30; plateau: stop) |

Final: PASS 94. 10 meshes / 10 draws, 2455 verts, 1 glow point (seed bud on the bow's top tip), 0 lights,
B13 0.0006 ms (the mass unit), R2 max IoU 0.57 (Vinelasher).

Built: a light upright woodland archer. Ochre buckskin jerkin, team-dark leaf capelet, bark leaf kilt, dark legs with
pale greave bands, bare face with tied-back hair, a leaf circlet with two long team leaves swept back, a bark quiver
with leaf-fletched arrows. Hook: a 1.9 m living-wood longbow sprouting leaves at both tips; the glowing bud on the
top tip is the only glow (bow body surface, own glow: flares on release). Hooks: `play_attack` (bow_draw 0.55 s,
release 0.15), `play_cast` (arcing high shot), `get_bow_tip_position()`, fidget (sights along the bow).
Reused: the Frostbow bow rig, the Vinelasher / NatureWarModel pattern (tapered paths, leaf rings, hit / death bloom).

Next: 1) P4 busy at 25 m (14.6); 2) S1 autumn floor dE 13: the ochre jerkin sits in the autumn band; 3) R12 night dE 11.

## Art Lab notes
- R5 lists the bud as "BowString" (the nearest part, not the glowing surface).
- C4 / P4 pull opposite ways (more inner detail vs less busy) on small units.
