# G-B Shadow buildings

Task G-B of the graphics week (JS 2026-10-15: "make the graphics as beautiful as possible"). Every Shadow kingdom
building got a pass for the RTS camera (zoom 10 / 30 / 50): Dusk Keep (tiers, upgrade, construction / damage /
collapse), Gloom Hall, Hovel, Night Spire, Gloom Stables, Gloom Bazaar, Dread Paddock. No contract changed: same
scenes, node names, hooks, footprints, collision (Building's), team colour / banners, selection, merged-mesh budgets.

## What changed

| Building | Shapes and materials (every tier) | Dressing (Medium and up) |
|---|---|---|
| Dusk Keep | **Tier looks** (it had none: Keep drew placeholder gold rings over the roof). `set_tier(t)`, `set_upgrading(on)`, `play_tier_up()`. Stronghold: four obsidian obelisks on the upper plinth (silver collars, a rune slit each, the two by the gate carry team banners), silver spikes at the prism 1 / 2 joint, a second counter-turning rune ring. Citadel: + a crown of six great obsidian thorns with a silver band round the tip, six obsidian fangs on the plinth corners, a halo of seven blades and a soul ring orbiting the eye. Upgrade: six soul-fire beams climb the plinth corners, the rune ring races, the build ring glows. Tier-up: the new parts grow out of the plinth (0.6 s, small overshoot), burst from the eye, glows flare 1.4 s | dead ground r 8.6 m, mist, wisps, 3 ember points |
| Hovel | witch hat rebuilt as four stepped shingle courses (team / team x 0.74) over a dark core, two darker bands on the bent tip; dark iron trim (the old silver read as white sticks); iron spikes on the six eave corners; two dormers with lit windows; horned skull over the door; bone stakes; rough foundation stones; cracked flags at the door; four lit lancet windows | dead ground r 4.3 m, mist, wisps, embers, lantern light at Ultra |
| Night Spire | one merged painted material (`vc_merge`, like the Ember Spire: Art Lab B8 / B9 WARNs gone); an obsidian claw of six shards round the foot, three bone ribs gripping the shaft, a spiked iron crown on the band | dead ground r 2.7 m, mist, wisps, embers, orb light at Ultra |
| Gloom Hall | six slate courses a side alternating team / team x 0.74 (stepped shingle lines instead of one flat purple plane); darker iron-silver metal; iron spikes jutting from both eaves | dead ground r 6.3 m, mist, wisps, embers, brazier light at Ultra |
| Gloom Bazaar, Dread Paddock | inherit the Gloom Hall dressing (they extend ShadowHallModel; their own shapes unchanged) | as the Hall |
| Gloom Stables | unchanged shapes (already the richest) | as the Hall |

## Graphics tiers (`GameSettings.effective_graphics_quality()`, read in `_ready`)

`ShadowDress` (`art/buildings/shadow_dress.gd`, `ShadowDress.attach(model, opts)`; the model forwards `sync(progress,
health, destroyed)` and `set_glow(c)`):

| Tier | Adds |
|---|---|
| Low | nothing (no node, no particle, no pass: the cost before G1). Shapes / materials above apply. |
| Medium | dead ground: one shaded decal per building (`shadow_dead_ground.gdshader`, ONE material for every Shadow building, per-building values as instance uniforms): ash-dark earth, a Voronoi crack network, soul-fire veins in the team glow that breathe outward near the walls, a ragged fbm edge that melts into the map ground; spreads with construction, cracks widen with damage, gutter out on the wreck |
| High | + drifting shadow mist round the plinth (10 puffs, proximity fade), rising soul wisps (8), violet embers from the damage points under 50 % HP and on the wreck (14 each) |
| Ultra | + more mist / wisps / embers (16 / 14 / 22) and one soft breathing violet light per building (no shadows; the keep keeps its two lights) |

The ShadowDress root carries the meta `no_ghost = true`: Building.make_ghost (fog-of-war ghosts) skips it and its
subtree, so a fogged Shadow building leaves a ghost of the building only, never a grey dead-ground square.
The darker roof courses (Hovel, Gloom Hall) are team colour x `TEAM_DARK` = 0.74, one constant for the unmerged
material and the merged multiplier.

Shared caches: one ground material, one plane mesh per size, one ADD and one MIX quad, process materials per size /
team colour. A base of 30 Shadow buildings adds one ground material and a handful of particle materials.

## Measurements

**Art Lab** (default lab run = Low: shapes / materials / tier code; batch `docs/art/lab/gb_shadow/batch.txt`, scorecards
in `docs/art/lab/<asset>/`, before = 2026-10-15 run on the old code):

| Asset | Before | After | Notes |
|---|---|---|---|
| dusk_keep | WARN 89 (2 WARN) | WARN 89 (1 WARN) | R5c (glow points stand out) now PASS; R5 glow count WARN is old (46 points: the keep's many lanterns / windows); C3 palette depth -17 (INFO) |
| shadow_hall | WARN 89 | **PASS 91** | R5 glow-points WARN gone (darker metal); C3 -10 (INFO) |
| hovel | WARN 86 | **PASS 88** | R5 WARN gone; P2 asymmetric secondary INFO 83 -> 49 (the dormers are symmetric; INFO only) |
| shadow_tower | WARN 82 (3 WARN) | **PASS 88** | B8 / B9 (13 materials, per-instance copies) and R1 silhouette area WARNs gone (vc_merge, the shard claw) |
| shadow_stables | PASS 92 | PASS 92 | shapes unchanged |
| market_shadow | FAIL 91 (B8 9 materials) | FAIL 91 | the B8 FAIL is the Bazaar's own (pre-existing, untouched) |
| dread_paddock | WARN 87 | WARN 88 | old R5 / R5c WARNs (its own glows) |

**Shots** (windowed, 1920 x 1080, real skirmish map, Shadow base of 2 halls, 4 hovels, 2 towers, stables, Bazaar, a
hall site, 3 extra keeps at tier 2 / tier 3 / upgrading, `art/buildings/shadow_tools/gb_shadow_shots.gd`):
`docs/art/lab/gb_shadow/contact_sheet_q2.jpg` (before | after at High: base z10 / z30 / z50, tiers z30, damaged hall
z10; `gb_shadow_sheet.ps1` builds it), key PNGs `after_q2_base_z30`, `after_q2_tiers_z30`, `after_q2_small_z10`,
`after_q3_base_z50`.

**fps** (RTX 3070 Laptop, base at zoom 30, 1920 x 1080). The PC was shared with 2-3 other Godot runs (another Art
Lab, a balance match, tests) the whole time, so absolute fps swing by +-30 % between runs. The fair number is the
in-process A/B (`ab=2`: every ShadowDress shown / hidden, interleaved):

| Tier | Before (one run) | After (one run) | A/B dressing on / off, GPU ms median (2 rounds) | Draws added by the dressing |
|---|---|---|---|---|
| Low | 150 fps, GPU 3.4 ms | 115 fps, GPU 4.3 ms (load) | n/a (no dressing at Low) | 0 (+17 draws: the 3 extra keeps' tier parts) |
| High | 85 fps, GPU 9.5 ms | 40 fps, GPU 8.9 ms (heavy load) | 11.2 / 17.7, 9.3 / 9.8 | ~45 (36 buildings) |
| Ultra | 66 fps, GPU 13.3 ms | 77 fps, GPU 10.6 ms | 10.2 / 10.9, 14.6 / 13.5 | ~40 |

The dressing's cost is under the run-to-run noise here (GPU ms on / off cross over); it adds ~1.2 draws per building.
smoke_test `victory=true`, perf_test `PERF OK` (norm 5.42 vs limit 6.72).

**Tests**: `tests/test_gb_shadow.gd` PASS (new), test_a_8, test_a_9, test_10_v2, test_13_v26, test_5_s1, test_6_u3,
test_tool_cine, test_cine_ep1_between, test_data_lab, test_10_c2, test_11_c2 PASS.

## Open points

- A keep model without `set_tier` still gets Keep's placeholder gold rings for tiers 2-3; the Dusk Keep API here
  (`set_tier`, `set_upgrading`, `play_tier_up`, all cached before `_ready`) is the one Keep calls.
- Follow-up: the map's grass blades (G2a ground detail) draw over the dead ground; a no-grass mask under Shadow
  buildings on the ground-detail side would make it read cleaner (art/environment/grass is not part of this task).
- Gloom Bazaar B8 FAIL (9 materials) is untouched.

## Files

- `art/buildings/dusk_keep.gd` (tier hooks, dressing), `art/buildings/dusk_keep_tiers.gd` (new: tier geometry)
- `art/buildings/shadow_dress.gd` (new), `art/buildings/shadow_dead_ground.gdshader` (new)
- `art/buildings/hovel.gd`, `art/buildings/shadow_tower.gd`, `art/buildings/shadow_hall.gd`,
  `art/buildings/stables/shadow/shadow_stables.gd`
- `art/buildings/shadow_tools/gb_shadow_shots.gd` (new: windowed shots + fps + dressing A/B of a Shadow base on the
  skirmish map), `art/buildings/shadow_tools/gb_shadow_sheet.ps1` (new: the before | after contact sheet)
- `tests/test_gb_shadow.gd` (new)
- `docs/art/lab/gb_shadow/` (shots, contact sheet, Art Lab batch file)
