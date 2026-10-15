# G-B Nature: the Nature kingdom's buildings

Task G-B Nature of the "graphics as beautiful as possible" block (2026-10-15, plan `docs/plan/graphics-week.md`).
Scope: the Heartwood (keep, every tier, upgrade and construction states), Grove Hall, Seed Hollow, Bramble Spire,
Grove Stables, Grove Bazaar. No node, hook, footprint, collision, LOD or team-colour contract changed; the keep gained
the three tier hooks Keep already calls (`set_tier`, `set_upgrading`, `play_tier_up`).

## What changed

| Area | Before | After |
|---|---|---|
| Keep tiers | no tier look: Keep drew its placeholder gold torus rings over the canopy | **Stronghold**: four leaning rune menhirs on the plinth corners, five blossoms opened on the canopy top, a glowing rune circle (8 leaf glyphs) on the ground; **Citadel**: + four great blossoms, seed lights on the menhirs, a slowly turning crown of rune-light rays and seeds floating over the Crown Bloom, a double rune circle with veins out to the fairy ring; the sap runs a bit brighter per tier |
| Keep upgrading | nothing | four glowing vines (leaves along them) climb the rampart and wrap onto the trunk as the upgrade progresses (`Keep.upgrade_progress()`), the ground circle fills with a sweeping light, the sap surges; Medium+ also runs the existing build-ring motes |
| Tier-up | nothing | the new parts swell open over 1.1 s, a petal burst from the crown, the build flash, a gate pulse |
| Canopy colour | khaki "popcorn" body (0.8, 0.78, 0.56) | spring sage (0.68, 0.77, 0.5): still pale enough to read off the meadow, now reads as foliage; team colour stays on the leaf cards / moss / banners |
| Painted layer (all Nature buildings) | 2-band toon ramp, flat rim | Medium+: softer wrapped light, cool fill on the shade side, warm terminator, sun rim on the lit silhouette, sky catch on tops, cool crease under overhangs, dappled hue in the foliage (sunny yellow-green crowns, blue-green hollows), crisper leaf scales, leaf translucency (back-lit leaves glow), moss velvet sheen, a soft waxy sheen on bark |
| Close-up relief | none | High+: bark plates, masonry joints, leaf scales and moss cushions bend the normal (derivative bump, faded out by 16 m, so an RTS-zoom pixel never pays) |
| Wind | cards swayed alone, canopy bodies rigid | Medium+: one world-space wind field moves canopy bodies, their leaf / blossom cards and the crown seeds together (gusts, grows with height; trunks and walls below ~3 m never move) |
| Damage (withering) | flat orange blotches | leaf by leaf, in a spread of autumn tones (dry olive, ochre, rust, dead brown), at every tier |
| Fireflies | none | High / Ultra: blinking yellow-green specks around the Heartwood (20), the Grove Hall (12) and each Seed Hollow (6); near the camera only (the existing ambient rule), never in the fog-of-war ghost |
| Grove Stables | bare straw roof | moss cushions and wild blossoms seeded over the thatch (merged, no new draw call) |

## Files

- `art/buildings/nature/nature_paint.gdshaderinc` (new): the layer (`gfx_detail`, wind field, bump, light pass).
- `art/buildings/nature_keep/nature_keep_painted.gdshader`, `art/buildings/nature/nature_vc.gdshader` (painted
  surfaces), `art/buildings/nature_keep/nature_keep_leaf.gdshader`, `art/buildings/nature/nature_cards_vc.gdshader`
  (cards), `art/buildings/nature_keep/nature_keep_seed.gdshader` (seeds ride the wind).
- `art/buildings/nature_keep_ground.gdshader`: `tier` and `upgrade` uniforms (rune circles, sweep).
- `art/buildings/nature_keep/nature_keep_tiers.gd` (new, `NatureKeepTiers`): tier / vine meshes, built once per process
  from code (NatureKit.MB), drawn with the keep's own per-instance materials.
- `art/buildings/nature_keep.gd`: tier hooks, upgrade growth, tier-up, gfx tier on its materials, fireflies, spring sage.
- `art/buildings/nature/nature_fireflies.gd` (new, `NatureFireflies`), `nature_kit.gd` (`gfx_detail()`, `gfx_rich()`,
  materials get the tier), `nature_vc.gd` (syncs `gfx_detail` into the merged materials).
- `art/buildings/nature_hall.gd`, `art/buildings/nature_hollow.gd` (fireflies), `art/buildings/stables/nature/nature_stables.gd` (living thatch).
- `art/buildings/nature_tools/gb_nature_shots.gd` (new): the windowed shot / fps script (`ab=1` measures the layer on /
  off / on in one process).
- `tests/test_gb_nature.gd` (new).

## Cost tiers

`gfx_detail` is a plain material uniform written from `GameSettings.effective_graphics_quality()` when a building is
made (NatureKit.make_materials, the Heartwood's `_ready`): Low 0, Medium 1, High / Ultra 2. Shader default 0 (stage
sets / cinematics that use these shaders without a script keep the Low cost). The relief branches on the uniform only
(derivatives in uniform control flow) and fades with distance (10-16 m).

| gfx_detail | Runs |
|---|---|
| 0 Low | the pre-G-B light, look and cost (only the withering palette and the tier parts, which are shapes); no wind, no new particles |
| 1 Medium | + wind, the soft light, translucency, velvet, sky catch / crease, dappled foliage |
| 2 High / Ultra | + close-up relief (< 16 m); fireflies (a gfx_rich() check at build time) |

## Measurements

Shots (`docs/art/lab/gb_nature/`, `.gdignore`; 1920 x 1080, `--gfx=high`, the skirmish map with the enemy Nature base
built around its Heartwood; shot list in `gb_nature_shots.gd`). Kept for the commit: `contact_sheet.jpg` (before | after:
base z30, tiers z30, hollows z10, damaged hall z10, base z50, stables z10; then after-only: tiers z50 with T1 / T2 / T3
keeps, upgrade z15, Citadel z30, Low base z30) and the key PNGs `before_q2_base_z30`, `before_q2_tiers_z30`,
`after_q2_base_z30`, `after_q2_tiers_z50`, `after_q2_tier3_z30`, `after_q2_upgrade_z15`, `after_q0_base_z30`. The other
shots are regenerated by the script (`tag=after`, `only=...`).
Note: in both sets the freshly placed buildings show white completion puffs around their bases (the building-complete
effect, not the model; it is not there on the original keep).

GPU / fps (RTX 3070 Laptop, zoom 30 over the base, 600 frames; 3-4 other Godot runs of parallel agents were going, so
absolute fps swings 43-73 between runs; the A/B is in one process):

| Run | avg fps | GPU ms (median) |
|---|---|---|
| before, High | 72.8 | 9.23 |
| after, High (a quieter moment) | 103.2 | 8.33 |
| after, High, A/B layer off / on | 71.6 / 71.3 | 11.32 / 11.53 (+0.2 ms) |
| after, Ultra, A/B layer off / on | 65.6 / 29.5 (CPU load spike) | 14.23 / 14.88 (+0.65 ms) |
| after, Low | 71.5 | 4.40 |

Art Lab (`--gfx=high`, `docs/art/lab/gb_nature/before|after/<asset>/scorecard.md`):

| Asset | Before | After | Notes |
|---|---|---|---|
| nature_keep | FAIL 88 | FAIL 89 | B8 materials 20 -> 21 (the fireflies' shared quad; B8 was already FAIL); R3 meadow dE 15.6 -> 16+ PASS with the silver-sage canopy (a warmer sage, 0.67 / 0.8 / 0.57, fell to dE 12.5 WARN, so the canopy leans blue-green on purpose) |
| nature_hall | FAIL 91 | FAIL 91 | same B4 vertex FAIL (12 893, pre-existing), R5 glow count WARN unchanged |
| nature_hollow | PASS 97 | WARN 93 | R3 / R3t meadow dE 14.0 -> 13.2 (threshold 14): the hollow's team-green roof shares the meadow's hue; at Low it measures 13.8 too, so it is the borderline case, not the layer alone. Darkening the foliage 7 % and toning the translucency moved it +0.4 only |
| nature_spire | WARN 93 | WARN 92 | same B8 / B9 WARN |
| nature_stables | PASS 91 | PASS 91 | vertices 11 725 -> < 12 000 (the thatch pads are low-poly; a first 7-pad version hit B4 FAIL 12 635) |
| market_nature | WARN 92 | WARN 93 | same R5 WARN |

## Tests

`tests/test_gb_nature.gd` (headless): every Nature shader includes the layer, Low materials headless, the tier hooks and
parts per tier, ground circle tier, vines only while upgrading, a site hides the tier parts, tier parts inside the keep
volume with keep materials on every surface, 2 unshadowed lights, no fireflies at Low, a tier-3 keep collapses, the other
five Nature models take their hooks. Also: test_a2_5, test_a2_6, test_10_v4, test_a_9 PASS, smoke, perf_test (below).

Results 2026-10-15: test_gb_nature PASS, test_a2_5 PASS, test_a2_6 PASS, test_10_v4 PASS, test_a_9 PASS, test_8_s1 PASS,
smoke `victory=true`, perf_test `PERF OK` (norm 5.58).

## Open issues / follow-ups

- No Grove Forge model: `nature_forge` (like every kingdom's forge) still uses ForgeBuilding's placeholder boxes
  (`art/buildings/forge/nature/` does not exist). A Grove Forge in this language is the obvious next Nature piece.
- The white completion puffs on freshly placed buildings (see Measurements) look like big blurry balls at zoom 10-18;
  they come from the building-complete effect, not from the Nature models.
- The canopy colour change (khaki to spring sage) reverses part of the 2026-09-30 in-game grade pass; the Art Lab R3
  meadow check is in the table above. If JS prefers the paler canopy, it is one constant (`CANOPY_COLOR`).
