# G-C: hired champions + class weapons (graphics pass)

Task G-C of the "graphics as beautiful as possible" block (2026-10-15). Goal: the four hired champions (Oathwall,
Wayfinder, Coin-Cutter, Mender; both variants, every class) and the class weapon kit read as heroes at zoom 20-40 and
in the inspect portrait, distinct from soldiers. No contract changed: scenes, node names, pivots, Variant / Face /
DoorShield / DoorBack / Bow / Lantern / HandProp / LootSack / HoodTail nodes, set_variant, set_weapon_class, attack
styles (slam, bow, slash2, spear_thrust, sword_slash, great_cleave, staff_bolt), grips and weapon tips, LOD tiers, team
colour (only the `*_cape` / `*_pennon` / `*_cloth` materials), hit flash, death, ChampionVfx hooks.

## Shared: `ChampionShapes` (`art/units/champions/champion_shapes.gd`, new, static)
Smooth / bevelled mesh helpers appending into a SurfaceTool (callers commit once per part and cache):
`tube` (parallel-transported rings, taper-leaning normals, welded seam), `lathe` (smooth or faceted, open arcs),
`plate` (bevelled extruded outline, flat-shaded chamfer ring so every edge catches a light line; a thin outline halves
its bevel until it triangulates), `lame` (a curved armour band with a rolled lip: pauldrons, faulds, greaves,
vambraces), `stud` (13-vertex rivet / jewel), `band` (rims, grip wraps), `cloth` (banner-shader UVs, folds, flare,
lean, double-sided: capes, mantles, tabards), `arc`, `commit_multi` (one multi-surface mesh, so new detail never adds an
authored part). Kept apart from FireShapes on purpose (no coupling to the Fire folder).

## Per champion
| Champion | What changed |
|---|---|
| **Oathwall** (biggest rework: it read as a grey box robot) | Dark blued steel (`oathwall_iron` #545a69, spec 0.45, rim 0.36) with polished **brass** trims (code copy `oathwall_brass`, a palette entry, no 6th material file). Legs: shaped trousers, riveted greave lame with a front ridge, domed knee cop + brass stud, rounded toe-forward sabatons, oak ankle cuffs. Hips: gambeson bell, iron fauld lame, two bevelled tassets with brass rivets. Chest: barrel cuirass (smooth, centre ridge), plackart lame with brass rivets, brass waist trim, the **glowing oath rune** on the breast in a brass ring, padded roll collar, **stepped pauldrons** (steel dome + steel lame + brass lame + brass stud). **Layered team cape** (long cape with folds clear of the gambeson + a short mantle over the shoulder blades) and a **heraldic front tabard** (banner glyph) under the sash. Helm: the square window helm kept (40 m read), bevelled lid, **brass crest fin**, brass brow band, brass cheek rivets. Arms: shaped sleeves, couters, lame vambraces with brass bands, lame-cuffed gauntlets with brass rims. Hammer: leather-wrapped haft with brass collar and pommel, bevelled head with brass collars and a steel-blue glowing rune line on each cheek. Left-arm plates use a code copy `oathwall_steel` so `oathwall_iron` on ArmL still means "door on the back" (test_11_v3). Authored meshes 24 -> 17. |
| **Wayfinder** | Shaped trousers and coat sleeves (tubes, bent elbow; were capsules), tall boots with a rounded toe-forward foot (was a box), shaped coat body (lathe; was a 12-sided can), bevelled rounded vest / leather straps / buckle stud, soft rounded pack, a **team half-cloak** over the left shoulder (banner glyph). Authored 22 -> 23. |
| **Coin-Cutter** | Shaped legs and sleeves (bent elbow), tall boots with rounded feet (were boxes), flared burgundy bracers, bevelled brass boot buckles; "burgundy" deepened from magenta #cc245c to wine #a81f47 (reads richer against the gold). No brass on the arms (brass in the arm merges = the knives, test_11_v4). Under the 4350 cap of test_9_v3 (4163). |
| **Mender** | Material pass only (her vertex cap in test_9_v4 leaves ~280 vertices; the model was already detailed). |
| **All four** | Heroic rim: rim_strength 0.25 -> 0.32-0.40 on the champions' own painted materials (the cool kit rim lights their silhouettes against the ground; soldiers stay at 0.25). |

## Class weapons (`art/units/champions/weapons/champion_weapon_kit.gd`)
Spear: smooth shaft, raised leather grip wraps, lathed iron socket with two swept lugs, brass ferrule / rings, a gilded
rune line down both flats of the blade. Sword: raised grip wraps, brass wheel pommel with steel buttons, bevelled brass
cross-guard with swept knobbed quillons + langet, dark fuller with a gilded rune line. Round shield: domed board,
bevelled iron rim, 8 brass studs, a raised team-colour boss with a brass spike, a gilded ward ring. Greatsword: grip
wraps, faceted pommel with brass cap, wide bevelled swept cross-guard, brass langet, leather-wrapped ricasso, gilded
rune line. Staff: smooth gnarled shaft and curling prongs (tubes, no more stacked cylinders), leather wraps, a brass ring
floating round the crystal and three small glowing shards orbiting under it. The kit keeps ONE glow surface (the staff
crystal: test_11_v1 and the kit's crystal-glow drive), so the blade runes are gilded (brass), not emissive.
Vertices: spear 645 -> 901, sword 275 -> 684, shield 804 -> 751, greatsword 404 -> 857, staff 1063 -> 742 (all <= 1400).

## Measurements
Art Lab (`--gfx=high`, batch files `docs/art/lab/gc_champions/batch_before.txt` / `batch_after.txt`, scorecards
`docs/art/lab/gc_champions/<before|after>/<id>/scorecard.md|json`, PNGs local):

| Champion | Before | After | Vertices (all drawn, variant A) | Notes |
|---|---|---|---|---|
| oathwall | WARN 87 (R3 contrast, R5c) | **WARN 90** | 2871 -> 5405 | R3 (the pale grey iron melted into the meadow) and R5c fixed; new B4 soft WARN (4593) |
| wayfinder | WARN 92 | WARN 92 | 6481 -> 6742 | B4 / R8w as before |
| coin_cutter | WARN 94 | WARN 94 | 3895 -> 3919 | B4 as before (3157 -> 3117) |
| mender | WARN 92 | WARN 92 | 8353 (unchanged) | B4 / R8w as before |

Draw instances unchanged (oathwall 13, wayfinder 15, coin_cutter 12-13, mender 16), 0 lights, materials unchanged
(Oathwall's brass / steel are palette entries).

Shots (`art/units/champions/tools/gc_champions_shots.gd`, windowed, `'--' --gfx=high --tag=<before|after>`; `'--'
--sheet` builds the JPG): `docs/art/lab/gc_champions/contact_sheet.jpg` = before | after for line_z30 (4 x A in kingdom
colours, 4 x B blue, a class row), close_row0 / close_row2 (zoom 10), the four portraits (zoom 2.4, HUD inspect framing),
classes_oathwall / classes_wayfinder (the 5 classes side by side). Key PNGs for git: `shots/after_line_z30.png`,
`shots/after_portrait_oathwall_0.png`, `shots/after_classes_oathwall.png`, `shots/after_classes_wayfinder.png`. The
rest of `docs/art/lab/gc_champions/` stays local (folder has a `.gdignore`). `after_npcs.png` = the Wildcaller and the
Mage Archer (not hired champions, not reworked) after the G-C Nature palette move: they look right.
Budget probe: `art/units/champions/tools/gc_count.gd` (headless, `'--' all`): vertices + shaders per drawn node.

Honest read: the Oathwall is the visible win (dark steel + brass, plate shapes, cape, crest: a knight instead of a
grey box; at zoom 30 the brass pauldrons and crest are its new read). Wayfinder / Coin-Cutter gain at zoom 10 and in
portraits (rounded boots, bent arms, softer pack); at zoom 30-40 they read as before. The Wayfinder half-cloak is mostly
seen from the side / back. The Oathwall's breast rune sits behind Garran's forked beard (Gerda shows it).

## Tests
`tests/test_gc_champions.gd` (headless): the 4 champions x 2 variants inside authored <= 26 / draw <= 17 / 0 lights /
per-champion vertex caps, every class taken with a weapon tip, Oathwall brass folds into the palette with only its own
files, cape + tabard recolour and restore, the weapon kit (<= 1400 per piece, one glow = the staff, guards present,
brass fittings), ChampionShapes plates / lathes / tubes face outward, tube seam welded, cloth UVs in 0..1. PASS.
Also run 2026-10-15: smoke victory=true, perf_test PERF OK (norm 6.47 / limit 6.72), test_ws_perf PASS, test_9_v1,
test_9_v3, test_9_v4, test_11_v1 - v5, test_13_v1b, test_13_v6, test_9_c10, test_13c_v5, test_13b_v5, test_13b_v8,
test_botfix_champions, test_g3b_materials, test_shader_lint: PASS.
**test_9_v2 FAILS** on its 9.V2 vertex cap (`<= 2950`, the soldier budget): Oathwall now 5401. Request in
`docs/handoff/for-lead.md` (raise to 5600 or drop it; test_gc_champions holds the caps now).
test_kit_team_color hit a parse error in `art/units/shadow/shadow_model.gd` (WISP_GATE, the parallel Shadow pass), not
in champion code; its verdict line still printed PASS.

## Next (not done)
- Mender geometry (shaped arms / boots) needs her test_9_v4 cap raised first.
- A brass emissive accent on blades would need a second glow surface in the kit (test_11_v1 + the kit's crystal drive).
- Door shield rivets are kit spheres (16 x 18 vertices): studs would save ~80 vertices.
