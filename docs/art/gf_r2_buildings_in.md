# G-F round 2: Ice / Nature buildings (items 6 and 7) (2026-10-15)

This pass fixes items 6 and 7 of `docs/art/gf_review2.md`:

- **Item 6:** the Frost Hall roof was a pale flat slab.
- **Item 7:** white out-of-focus blobs around the Ice and Nature buildings.

Another agent handled the Fire and Shadow buildings in parallel. Nothing here touches `art/buildings/nature_spire.gd` or
`art/vfx/`.

Shots were taken windowed at High, 1600 x 900, with `--gfx=high`:

- Contact sheet with 10 before | after pairs: `docs/art/lab/gf_r2_in/gf_r2_in_contact_sheet.jpg`.
- Key PNGs: `gf_r2_in_key_{ice_hall_z10,ice_hall_z18,ice_base_z30,nature_keep_z10}.png`.
- The raw shots stay local in `docs/art/lab/gf_r2_in/{before,after}/`. That folder has a `.gdignore`.
- Shot tool: `docs/art/lab/gf_r2_in/tools/gfr2in_shots.gd`. It is a trimmed copy of `gf2_shots.gd` that shoots
  buildings only, plus z18 and house shots. Debug flags: `--inspect`, `--hide=<emitter> [--hidein=hall]`.
- Sheet script: `docs/art/lab/gf_r2_in/tools/gfr2in_sheet.py`.

## Root cause found on the way: billboard particles drop the process scale

Hiding emitters one at a time showed that the "discs" were the motes themselves, drawn about 0.6-1 m wide.

- The Frost Hall motes had `scale_min = scale_max = 0.06` on the hall's 1 m quad. They still drew as the whole 1 m soft
  quad.
- A `StandardMaterial3D` in `BILLBOARD_PARTICLES` mode rebuilds the model matrix from normalised camera axes, so the
  particle scale (in the instance transform) is lost unless `billboard_keep_scale` is set.
- As a result, every kit emitter that sizes its particles with `scale_min/max` on a 1 m quad draws at the quad's size:
  - the Ice Hall motes and cold flame,
  - the Nature keep, hall and hollow pollen,
  - the Snow Lodge crystal sparkles,
  - the Frost Bazaar motes.
- The Ice keep's 0.14 m quad and the unit motes' 0.045 m quad were fine, because they put the size in the quad.

**The fix:** the motes now carry their world size in the quad.

- `MoteCap.sized(mesh, size)` makes a copy of the building's own quad at that size, with the same material. This adds no
  material, so Art Lab B8 is unchanged.
- `MoteCap.normalize_scale` turns the process scale into a relative spread of at most 1. The size is then right with or
  without `keep_scale`.

The other kit emitters (smoke, flames, dust) are untouched. They have the same latent issue, which is a follow-up for
the lead, see the end.

## Item 7: white motes

`art/buildings/mote_cap.gd` (`class_name MoteCap`, static) holds the shared rules for every ambient mote:

- **No additive white-out:** motes are alpha-blended (MIX), so a stack never sums past its own colour.
- **Near-camera fade:** distance fade with pixel alpha. A mote is invisible closer than 4 m and fully visible from 9 m.
  Either the MoteCap material carries it, or `fade()` adds it to the building's own MIX soft dot.
- **Value cap:** the colour ramp stays at or under `VALUE_CAP` 0.72. The Ice whites sit near 0.75-0.8
  (`ge_value_pass.md`), and glows stay the brightest thing.
- **Tier:** Low shows nothing (`amount_ratio` 0, hidden), which is no more than the pre-G1 cost. Medium shows half,
  High and Ultra show all of them. The emitting flag stays its owner's business.

| Emitter | Before | After |
|---|---|---|
| Ice keep SnowMotes (`ice_keep.gd` `_cap_motes`, build tool comment in `ice_keep_build.gd`) | 30 motes falling from 12 m, alpha 0.8, pale | Fall from 7.5 m in a 4.2 m box, 0.1 m quad, ramp (0.66, 0.74, 0.86) at alpha 0.6, keep's own ParticleMix with the fade |
| Ice keep FrostSwirl | 0.16 m blue glitter | Unchanged look; gets the fade and the tier |
| Frost Hall SnowMotes | Additive, from 4 m above the ridge crystal (between the camera and the roof), drew 1 m | Ring around the walls under the eaves (y 3.3), 0.06 m MoteCap quad, 12 motes |
| Frost Hall ColdFlame (the "white hex" at the door) | 12 additive 1 m quads | 9 MIX quads of 0.3 m |
| Snow Lodge / Frost Forge Snowfall (High only, `IceShapes.snowfall_pm`) | Near-white at alpha 0.85 | Capped ramp at alpha 0.6, 0.05 m MoteCap quad |
| Snow Lodge CrystalSparkles | Additive 1 m (a white puff on the crystal) | 0.09 m quad, same material |
| Frost Bazaar SnowMotes | Additive near-white, 1 m | 0.06 m MoteCap quad, 10 motes |
| Nature keep Pollen | Additive HDR (x1.5) 1 m dots rising to about 7 m (the "white ball" of tile 12) | 0.06 m on the keep's MIX soft dot, ramp x 0.62, slower (stays under about 4 m) |
| Nature hall / hollow Pollen | Additive 1 m | MIX atlas dot at 0.05 / 0.045 m |
| Fireflies (`nature/nature_fireflies.gd`, High only) | HDR (1.3, 1.7, 0.6) additive | (0.62, 0.72, 0.3) on the building's MIX dot, 0.11 m; new optional `quad` argument |
| Fairy-ring caps + spore dots (`nature_keep_ground.gdshader`, `nature/nature_ground.gdshader`) | Unshaded up to x2.4 / x1.6 the glow, pale bloomed ovals round the keep | Caps breathe at or under x0.85, spores x0.9 |

Note for the lead: `nature/nature_ground.gdshader` is shared through `NatureKit.ground_material`. Its dimmer caps
therefore also reach the Bramble Spire's moss patch. `nature_spire.gd` itself was not edited.

## Item 6: Frost Hall roof (`art/buildings/ice_hall.gd`, `_ice_roof`)

**Before:** 4 slabs per slope, a third of each slope under a snow blanket, a row of drift mounds ("pillows") and a
1 m snow ridge prism.

**Now:**

- **Tiles:** 6 staggered courses per slope, 8-9 tiles per course, 102 tiles in all. Each tile is tilted 7 degrees
  flatter than the slope, so its lower edge lifts and casts a line. Each tile also has a little hand-laid jitter.
- **Tile shades:** three shades of the team colour, `ROOF_MULTS` 0.52 / 0.45 / 0.6 (was 0.65). There is one value step
  per course, and 18 % of the tiles use the light shade. All three follow `set_team_color` and the B8 merge.
- **Streak cracks:** half strength, `ROOF_CRACK` 0.15 (was 0.35).
- **"Satin" glaze:** `ROOF_SPEC` 0.32. `ice_paint.gdshaderinc` drops the sharp lobe to 30 % for team or frost ice with
  spec 0.30-0.41. Before, the sun side mirrored the sun as one cream sheet. Crystals (0.45-0.5) and spec 0 are
  unchanged.
- **Eaves and edges:** a dark eave board with a dark-silver drip edge (the eave now reads thick), and dark-silver
  bargeboards (the bright silver drew a white frame).
- **Ridge:** a dark ridge cap with a crest of small team crystals (9, kept clear of the ridge crystal's collar).
- **Snow:** only a thin broken line under the ridge, about 5 % of the roof's up-facing area.
- **Icicles:** frosted ice instead of paper-white snow.
- **Ground snow:** packed grey-blue snow, flatter and 25 % smaller. The store's snowball was removed.
- **Frost brazier:** a dark-silver rim, a smaller dimmer glow (`mat_brazier` 1.2, was `mat_glow` 3.0) and a smaller
  shard.

**Measured** on the Ice base z30 shot, over the hall's roof area, as HSV value:

| | Mean | Median | 90th percentile |
|---|---|---|---|
| Before | 0.71 | 0.73 | 0.82 |
| After | 0.57 | 0.56 | 0.78 |

The roof is no longer the brightest flat area of the Ice base. Vertices rise from 6124 by about 2.4 k, which stays
under the 12 000 budget (B4 PASS).

## Art Lab (`docs/art/lab/<asset>/scorecard.md`, rescored)

| Asset | Before (last run in that folder) | After |
|---|---|---|
| ice_hall | WARN 90 (R5) | WARN 90 (R5, same; 20 soft glows, was 24) |
| ice_keep | PASS 87 | PASS 87 |
| ice_lodge | PASS 90 | PASS 90 |
| market_ice | PASS 94 | PASS 93 |
| ice_forge | PASS 90 | PASS 90 |
| nature_keep | FAIL (B8 21, already failing) | FAIL (B8 20, one material fewer), WARN R5 / B9 |
| nature_hall | FAIL (B4 12 893, already failing) | FAIL (B4 the same), WARN R3 / R5 |
| nature_hollow | WARN 93 (R3, R3t) | WARN 91 (R3, R3t, R5 noisy: "median of 3/5/5") |

No new FAIL. The first try put a new MoteCap material on the Ice keep and on the Nature hall and hollow, which gave a
new B8 FAIL (9 materials). These emitters now reuse the building's own soft dot, through `apply_own` and `sized`.

## Tests

- `tests/test_gf_r2_in.gd` checks:
  - MoteCap rules: MIX, the near fade, the cap and the tier ratio;
  - every ambient mote emitter of the 8 buildings: drawn as a mote, tier, value cap, quad of at most 0.15 m, relative
    scale;
  - Frost Hall motes under the eaves, Ice keep snow at or under 8 m, ColdFlame MIX at or under 0.35 m;
  - the roof: 3 shades darker than x0.65, crack at or under 0.18, shades follow the team colour, snow share under
    0.2, at least 150 tile triangles.

  It passes at Low, and with `-- --gfx=medium` and `-- --gfx=high`.
- These also pass: `test_shader_lint`, `test_ge_additive_fog`, `test_ge_value_pass`, `test_unique_class_names`,
  `test_gb_ice`, `test_gb_nature`, `test_a2_4`, `test_a2_5`, `test_a_9`, `test_gb_fire`, `test_gb_leftovers`,
  `test_gf_offscreen_emitters`, and smoke (`victory=true`).

## Follow-ups (not done here)

- **Other building particles:** every building particle that sizes with `scale_min/max` on a 1 m `BILLBOARD_PARTICLES`
  quad draws at 1 m. Examples are smoke at 2.2 or 2.6 m, Fire flames at 0.4 m and build dust. The fix is either
  `billboard_keep_scale = true` on the shared kit quads (`FireHallModel._quad`, `NatureKit` cards,
  `HearthSmallBuilding`), which changes the size of many effects at once and needs a look pass, or sized quads per
  effect as done here. A shared Fire / Shadow / VFX change belongs to the lead or the art-direction owner.
- **Fairy-ring caps:** the caps in `nature/nature_ground.gdshader` are dimmer on the Bramble Spire too, as noted
  above.
