# Bleakbow (Shadow bowman), art report

Start 11:46, end 12:15 (laptop, 2026-09-27; medium effort). Scene `art/units/shadow/bleakbow/bleakbow.tscn` (script
`bleakbow.gd`, extends ShadowModel). Art Lab output `docs/art/lab/new-units/bleakbow/`, refs nightbolt, shade, hexweaver.

| Run | Wall | Quality | FAIL / WARN | Change |
|---|---|---|---|---|
| 1 | 117 s | 94 | 0 / 0 | first build |
| 2 | ~45 s | 93 | 0 / 1 (R5 median 0/0/1) | 2 rib pairs, lower hooks, body_height 1.6 (UnitType) |
| 3 | ~45 s | 94 | 0 / 0 | bigger quiver barbs, glow_gain 1.7 (R5 stable) |
| 4 | ~45 s | 93 | 0 / 0 | bow barbs in obsidian, leather boot bands (P4 busy) |
| 5 | ~45 s | 94 | 0 / 0 | silver rib harness (plateau: stop) |

Final: PASS 94. 10 meshes / 10 draws, 2418 verts, 1 glow point (quiver barbs, merged chest), 0 lights, B13 0.0015 ms,
R2 max IoU 0.60 (Shade).

Built: a gaunt grave-hunter. Deep violet cowl with a bone half-mask and fangs, two bone hooks sweeping up and back,
violet jerkin with a silver rib harness, iron gorget, three tattered coat tails, iron-shod boots. A quiver slung across
the back with glowing violet barbed heads over the right shoulder. Hook: a black obsidian recurve with barbs down both
limbs and bone hook tips. The drawn arrow's barbed head glows (own glow, charges on the draw). Hooks: `play_attack`
(bow_draw 0.6 s, release 0.15), `play_cast` (held draw, 1.0 s), `get_bow_tip_position()`; ShadowModel violet dissolve.
Reused: the Frostbow bow rig, the Hexweaver death motes / blob, ShadowModel.

Next: 1) P4 still busy at 25 m (19): fewer pale bits on the dark body; 2) C1 shape richness 49; 3) a small
blood-red accent on the barbs if the palette gets one (Shadow has no red).

## Art Lab notes
- R5 flips 0/1 on a glow just at the bloom level (like OC3): a merged glow part gets no per-unit boost except glow_gain.
- R8 uses the UnitType body_height (1.6), not the scene's: the scene value was silently ignored until matched.
