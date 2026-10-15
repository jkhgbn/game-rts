# G-C: mounts and titans

Task G-C of the "graphics as beautiful as possible" block (2026-10-15): the cavalry mounts (`art/units/mounts/`) and the
titans (`art/units/titans/`) at zoom 30-40 and zoom 10. Built on G3b (painted-PBR materials) and G1 lighting. No contract
changed: scenes, node names, pivots, Seat, gait / charge / fidget hooks, attack styles, LOD tiers, team colour, hit
flash, death, barding, draw-instance counts (every mount still 8).

## What changed

### Shared anatomy helper: `MountShapes` (`art/units/mounts/mount_shapes.gd`, class_name, static)
- `leg(s, key, p, rows, mat, w, flat, seg)`: ONE continuous tube from the leg root to the coronet through anatomical
  joints, flattened side to side (wide from the side, narrow from the front, like a real leg), radii swelling at the
  joints. Replaces the old "tube + ball + tube + ball + tube" legs (a kink and a seam at every joint). No end caps (the
  top hides in the body, the coronet in the hoof).
- `leg_bands(...)`: the same leg in colour bands (coat / sock / stocking) that share their joint ring.
- `muscle(...)`: an ellipsoid muscle mass along a direction; `scaled(...)`: one template stretched / thickened per animal.
- Templates `HORSE_FORE` (elbow + forearm, bony knee, flat cannon, fetlock knob, sloping pastern) and `HORSE_HIND`
  (stifle forward, gaskin sloping back to the HOCK point, vertical cannon).

### Mounts
| Mount | Change |
|---|---|
| Ember Boar | jointed legs in two bands (hide, dark bristled sock): heavy forearm into a knobbly knee; hind ham, gaskin back to the hock, short cannon leaning to the hoof; a shoulder mass over each fore leg |
| Dusk Steed | gaunt horse legs from the template (bony knee, hock point, flat cannons), gaskin + calcaneus on the hind legs; body: a shoulder mass sloping from the withers to the point of the shoulder and a haunch from the hip to the stifle (the old haunch ball on the leg is gone) |
| Grove Stag | deer legs (template stretched: long forearm, long slim cannon, sharp hock), forearm / gaskin muscle; moss shawl hem cut finer (21 short teeth instead of 13 big flaps), neck moss locks alternate with dark leaf for depth; trimmed (petal ellipsoids, hoof toes, chest sphere) so it ends under its old vertex count |
| Roan Courser | cob legs from the template (shorter, 1.22 x thicker) in colour bands: roan forearm / gaskin, chestnut from the knee / hock, white hind socks |
| Rimehorn | unchanged (pillar legs and fur boots already read as a rhino) |

### Titans
| Titan | Change |
|---|---|
| War Mammoth | the frosted crown of the dome and the rimed hump crest are now shaggy fur LOCKS (10 + 15, pale frost tips) instead of flat toothed rings that read as cogs from the RTS camera; `mammoth_fur` darker blue-grey with mottling (noise scales) and a frosted top lift (`top_lift` 0.24): a value read from frosted back to darker flanks instead of one pale blob |
| Elder Treant | every crown and forearm leaf mass carries a team-leaf puff on top (vertex `COLOR.a` 1 = albedo `team_tint`, like the waist garland): Nature's fresh green, other kingdoms' leaves turned like autumn, where the camera sees them. Art Lab R6 3 % -> 5 % (WARN -> PASS) |
| Frost Dragon | `frost_membrane.gdshader`: the deepened kingdom colour gets its own brightness back (pow for the hue, then rescaled to the colour's max channel) and the rime overlay is a little lighter (`frost_amount` 0.75 -> 0.62): red / violet / green teams no longer sink to near black. R6 measured 4-7 % across runs (noisy, still WARN; the frosted wings stay mostly pale by design) |
| Cinder / Frost Dragon, Elder Treant | ground blob: one shared `PlaneMesh` per type (was one built per instance: Art Lab B9m WARN gone) |
| Nightmare Knight | unchanged (already the strongest titan read; 17k vertices, over the soft budget) |

## Measurements

Art Lab before / after, `--gfx=high`, batch files `docs/art/lab/gc_mounts/batch_before.txt` / `batch_after.txt`,
scorecards `docs/art/lab/gc_mounts/<before|after>/<asset>/scorecard.md|json` (PNGs local). Body vertices = B4 (face apart).

| Asset | Before | After | B4 before | B4 after |
|---|---|---|---|---|
| ember_boar | PASS 95 | PASS 95 | 4665 | 4635 |
| dusk_steed | PASS 95 | PASS 95 | 5581 | 5455 |
| grove_stag | WARN 92 | WARN 92 | 6577 | 6549 (B4 WARN pre-existing, R5 3 glow points by design) |
| rimehorn | PASS 96 | PASS 96 | 4798 | 4798 |
| roan_courser | PASS 95 | PASS 95 | 4752 | 4686 |
| blaze_rider | FAIL 91 | FAIL 92 | 9336 | 9306 (B2 18 draws, see below) |
| cinder_dragon | WARN 95 (B9m) | WARN 94 (R5w flicker, run noise: model unchanged) | 9476 | 9476 |
| frost_dragon | WARN 92 (R6 4 %) | WARN 92 (R6 4-7 %) | 8580 | 8580 |
| elder_treant | WARN 90 (B4, B9m, R4k, R6) | WARN 92 (B4, R4k, R12 night) | 12777 | 12777 |
| nightmare_knight | WARN 94 | WARN 94 | 17131 | 17131 |
| war_mammoth | WARN 97 | WARN 96 (B4, R5w flicker = run noise) | 13040 | 13236 |

The R5w "glow points while walking" WARNs on the dragons / mammoth appeared with no change to any glow part (the machine
ran other agents' Godot jobs: B13 frame cost swung to 1.7 ms in one run). Mount test caps (13.V2 / V3 / V6, incl.
barded) all hold: the new legs cost about what the old stacked ones did, the shapes are simply better spent.

### Blaze Rider B2 (draw instances) - not fixable inside the mount
The lab judges `blaze_rider.tscn` (Boar + Rider in one scene) on the **cavalry** tier, which is the rider ALONE
(cavalry-mounts.md 10: "cavalry rider, mount separate", 12 draws; test 13.V10 checks rider <= 12 and boar <= 8
separately, and passes: rider 10, boar 8). The boar's 8 draw instances are Body, Head, 4 legs, Tail, blob; each leg,
the head and the tail are animated on their own pivots, so they cannot share a mesh without skinning (a per-frame
bone copy costs more than the B13 budget allows). Same for Stagrunner / Glade Outrider (rider + Grove Stag = 20: the
stag's Neck pivot replaces the Tail). Proposed fix (lab owner, `tools/art_lab/lab_budgets.gd guess_tier`): score a
scene that instances a `MountModel` with a seated rider on the "unit/rider" tier minus the mount's own draws, or
against cavalry + mount (12 + 8 = 20). That is a lab change for the lead to decide.

### Shots
`art/units/mounts/tools/gc_mounts_shots.gd` (windowed, `-- --gfx=high --tag=<before|after> [--only=mounts|titans]`,
`-- --sheet` builds the JPG): `docs/art/lab/gc_mounts/contact_sheet.jpg` = before | after for mounts_z30 (the 5 mounts,
the 4 cavalry riders, a blue-team row, a galloping row), close_mounts / close_cavalry / close_gallop (zoom 10),
portrait_ember_boar / dusk_steed (zoom 4.5), titans_z30 and close_<titan> (zoom 10). Key PNGs for git:
`shots/after_mounts_z30.png`, `shots/after_portrait_dusk_steed.png`, `shots/before_portrait_dusk_steed.png`,
`shots/after_close_war_mammoth.png`. Everything else stays local (folder has a `.gdignore`).
Budget probe: `art/units/mounts/tools/gc_count.gd` (headless, `-- [ids=a,b] [mats]`): vertices per draw node / material.

Honest read: at zoom 30-40 the mounts' silhouettes are the same on purpose; the gain is legs that read as legs (a knee,
a hock, a thin cannon) instead of sticks with balls, most visible on the galloping row and at zoom 10. The mammoth
reads as a shaggy frosted beast instead of a pale smooth blob with a cog on its head; the treant's crown now shows the
team colour; the Frost Dragon change is small.

## Tests
`tests/test_gc_mounts_titans.gd` (headless): MountShapes leg = one surface, outward normals, flattened cannon, bands meet
at the cut row, `scaled` keeps the hoof rows; every mount keeps its pivots / Seat / hooks, <= 8 draw instances, body
vertices <= 6000 (Grove Stag <= 6700), legs on the ground, hit flash on the legs; titans <= 20 draw instances +
particle systems, 0 lights, the treant crown carries >= 300 team-leaf vertices, two treants / dragons share one blob
mesh, the four reworked mounts use MountShapes, frost membrane keeps the colour's brightness, mammoth crown as locks,
mammoth fur top lift. PASS.
Also run 2026-10-15: smoke victory=true, perf_test PERF OK (norm 6.56 / limit 6.72 under load 1.43; one earlier run at
6.95 on a loaded machine), test_ws_perf PASS, test_11_v4, test_13_v1a / v1b / v2 / v3 / v5 / v6 / v7 / v8 / v9 / v10 /
v13 / v14 / v15 / v16 / v18 / v19, test_13c_v1, test_13c_v8, test_13b_v3, test_13b_v4, test_stables,
test_kit_team_color, test_g3b_materials, test_shader_lint, test_art_lab: PASS.

## Next (not done)
- Rimehorn and the Nightmare Knight's horse could take the template legs (the Knight's are 1.4k vertices each already).
- Thornback Charger / Bramble Harrier (boxy at zoom 30, Nature report) live in `art/units/nature/`, not in
  `art/units/mounts/`: the Nature owner can call `MountShapes.leg` from there.
- War Mammoth tusks: ivory growth bands; the Grove Stag shawl as layered moss locks (needs ~300 vertices of room).
