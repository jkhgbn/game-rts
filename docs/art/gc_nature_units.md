# G-C: Nature units (graphics pass, 2026-10-15)

Goal (JS: "make the graphics as beautiful as possible"): the Nature army's soldiers read better at play zoom (30-40)
and look like living wood, leaf and thorn at zoom 10, instead of flat-coloured primitives. Hall units and the worker
first (Sprigling, Thornling, Burr Slinger, Bloomtender, Bramblehorn), then the whole roster through the shared layer.
Contract kept: same scenes, pivots, node names (Sprout, Crystals, MineSparks, Hat / HatMesh, Censer, Tip, Seeds, Burr,
VetTrim, Fx, Shadow...), attack / death styles, LOD tiers, team-colour API, hit flash, death, kit slot map.

## What changed

### 1. A Nature shader for the whole palette (`art/units/nature/nature_living.gdshader`)
The kit's `unit_painted.gdshader` + the G3b layer, unchanged (same uniforms, same instance uniforms on the same kit
slots: ao 1 / 2, hit_flash 3, flash_color 4, kit_detail 12), plus Nature layers, all sampled in mesh space (nothing
swims when a unit walks):

| Layer | Driven by | Look |
|---|---|---|
| Leaves | mesh UV tag (UV.x -3..-2, UV.y base 0 .. tip 1) | darker stalk, lighter tip, a pale rim, a pale midrib + side veins (Medium+, fade before they shimmer), silver-sage undersides, light through the leaf when the sun is behind it (Medium+) |
| Thorns / claws / horns | mesh UV tag (UV.x -5..-4, UV.y tip 0 .. root 1) | dark root, pale bone point with a faint glint: the spikes read pale against the grass |
| Bark | uniform `bark` | long wavy furrows round the pivot axis (as on Ysolde's gown), lighter plates; furrows bend the normal close up; they fade out past ~15-25 m (the zoom-30/40 read stays clean blocks) |
| Sap | uniform `sap` (High+, < 22 m) | glowing sap in some furrows pulsing upward; emission on the unit's own mesh, so fog of war hides it with the unit |
| Lichen | uniform `lichen` (Medium+) | pale silver-green patches on the upward planes close up, an even lighter wash on the tops far away: a value step on top that lifts brown / green bodies off the meadow |

The tags are negative on purpose: kit primitives, lathes and tubes keep UV.x >= 0 (a tube's UV once matched an early
positive tag range and turned the Spirit Wolf pale). Writers: `NatureModel.leaf_mesh()` (every Nature leaf, leaf ring,
leaf crown), `NatureModel.thorn_cone(r, h)` (thorn rings, spines, crests, burr spikes), `NatureModel.thorn_tagged(key,
mesh, root, tip)` (any tapered claw / horn), and `cluster_mesh` / `GroveKinModel.bake` now keep UVs. Same vertex counts.

Cost tiers (`kit_detail`, defaults to 0 here per the shader-tier rule; the kit writes it): Low = leaf two-tone / rim,
thorn gradient, bark plates (one texture read); Medium = + veins, translucency, lichen, the G3b extras; High / Ultra =
+ sap near the camera, furrow bump. fwidth and dFdx / dFdy are taken at the top of fragment(); the per-part (UV) branches read no
texture; the bark reads (furrows, sap mask) use textureGrad with gradients of the unwrapped angle (analytic d atan), so
there is no mip seam where the angle wraps; the lichen read sits in a uniform branch.

Materials moved to it: the 20 kit-shader materials of `art/units/nature/materials/` and the 19 per-unit ones
(bramble_harrier, glade_outrider, mossback, spirit_wolf, stagrunner, thornback_charger). Settings:
`nature_bark` bark 0.85 / sap 0.55 / lichen 0.22, `nature_bark_dark` 0.5 / 0.7 / 0.15, `sw_bark` 0.8 / lichen 0.1,
`nature_thorn` paler (#9e7847, was #8c6b3d) and bone (surface_kind 7). Team variants still recolour (the kit
duplicates the material, the shader comes along). Other readers of the palette files: the Grove Stag mount gets the
leaf / bark look too; the Wildcaller champion does not (ChampionPalette folds the materials into its one palette
material and keeps only base_color / spec / rim; `champion_palette.gd` `foldable()` now accepts nature_living
materials, so it folds them as before instead of drawing up to 8 unfolded surfaces per pivot). **Ysolde** (G3a hero,
`art/units/wizards/ysolde.gd`) borrows `nature_bark` / `nature_leaf` / `nature_leaf_dark` for her belt, satchel, vine
and head leaf ring, so they get the furrows, lichen, sap and leaf veins too. Checked on the hero with windowed High
shots, before (`--legacy`) and after, zoom 10 and a 3.5 m portrait (`gc_nature_shots.gd '--' --gfx=high --ysolde`,
`shots/legacy_ysolde_*.png` / `after_ysolde_*.png`): the borrowed parts are small, they match her own bark gown
(ysolde_grove, same furrow / sap idea) and nothing clashes, so it is kept; test_gc_nature checks she still draws
them, keeps a visible glow and flashes on hits.

### 2. Shapes (Hall units)
- **Thornling**: forearm bracers are now 3 team leaves wrapped round the forearm (was a plain cylinder); a dark vine
  belt round the keg; the keg is rounder (12 x 6); spine, crest and the 6 hooked claws carry the thorn tag (pale
  points).
- **Burr Slinger**: the jerkin is a rounded barrel lathe and the straw tunic flares into a 7-lobed scalloped hem (both
  were 8-sided cylinders); rounded bark boots (were boxes); the burr spikes (loaded burr + the sack's spares) carry the
  thorn tag.
- **Bramblehorn**: horns darken to the root and pale to a bone point; spine and horn thorns tagged.
- **Sprigling, Bloomtender**: the shared layer only (veined leaf tunic / hem / sprout / hat petals, bark plates).
- **Greenheart Oathkeeper** (T2): segment counts trimmed (6-sided limbs / cape, 6-ring tori, one tasset and one mantle
  leaf less, a little wider) to get back under the soldier vertex budget: Art Lab B4 FAIL 2703 -> PASS 2438.

### 3. Data fixes
- `stagrunner/materials/stagrunner_blade.tres`, `stagrunner_leaf_amber.tres`, `stagrunner_leaf_gold.tres`: the garbled
  last line (`rim_strength = 0.95, 1.0, 0.8S`) is now `rim_strength = 0.5` (the palette's value), plus their
  surface_kind (blade metal 2, leaves plain 0).
- surface_kind added where G3b's tool found no keyword: `bh_dark`, `bh_pale`, `tb_pale` (fur 6), `glade_outrider_bow`
  (wood 5).

## Measurements

Art Lab before / after, lab v3.1, `--gfx=high`, meadow, warm light (`docs/art/lab/gc_nature/before|after/<unit>/`,
batch files `batch_before.txt` / `batch_after.txt`):

| Unit | Before | After | Notes |
|---|---|---|---|
| sprigling | WARN 90 | WARN 89 | same 3 WARN (sprout height R8 / R8w, HP bar R7: shape, not material) |
| thornling | WARN 90 | WARN 94 | R3 meadow contrast and R3t team contrast fixed (pale points, lichen tops); R6cb remains |
| burr_slinger | WARN 92 | WARN 92 | same R10 footprint (the pod), R6cb |
| bloomtender | WARN 92 | WARN 91 | same 3 WARN (hat height, R6cb) |
| bramblehorn | WARN 93 | WARN 93 | R6cb fixed; new R4 sand dE 9.4 (pale horns / lichen wash closer to sand; 10 wanted) |
| sapling | WARN 91 | WARN 95 | R3 and R3t fixed |
| vinelasher | WARN 92 | WARN 91 | same R3t / R6cb |
| wildwood_archer | WARN 93 | WARN 93 | same R6cb |
| bramblesage | WARN 93 | WARN 93 | same R6cb |
| thistle_darter | WARN 93 | WARN 92 | same R10 |
| greenheart_oathkeeper | FAIL 91 | WARN 92 | B4 vertex FAIL fixed |
| spirit_wolf | PASS 94 | PASS 95 | |
| stagrunner | FAIL 89 | FAIL 89 | pre-existing B2: rider + grove_stag mount = 20 draw instances (16 wanted); the mount is not this folder's |
| glade_outrider | FAIL 89 | FAIL 89 | same pre-existing B2 |
| thornback_charger | WARN 95 | WARN 95 | |
| bramble_harrier | WARN 93 | WARN 94 | |

The P4 "detail density" INFO dropped hard in a first pass (bark furrows busy at 25 m); the distance fade on furrows
and lichen brought the 40 m read back to clean value blocks.

Shots (windowed, `--gfx=high`, Art Lab stage, meadow): `art/units/nature/tools/gc_nature_shots.gd`
(`'--' --gfx=high --tag=after`; `--legacy` swaps the Nature materials back to the kit shader at runtime; `--perf` =
240 Nature soldiers at zoom 30). Kept for git: `docs/art/lab/gc_nature/contact_sheet.jpg` (before | after: army zoom 30
crop, Hall close zoom 10 in green and red, Hall portrait zoom 4.5, tier 2) and `shots/after_army_z30.png`,
`shots/after_close_hall.png`, `shots/after_portrait_hall.png`, `shots/after_close_tier2.png`; everything else in
`shots/` (before_*, wip*, after_low_*, perf_*) and the lab PNG / JPG stays local.

GPU, 240 Nature soldiers filling the zoom-30 view, 1600 x 900 MSAA 4x, RTX 3070 Laptop, machine shared with other
agents' Godot runs: legacy (kit shader) 11.5 / 14.3 ms, nature_living 6.5 / 7.2 ms. The legacy runs swap shaders at
runtime and pay pipeline compiles inside the measured frames, so read this as "no measurable extra GPU cost", not a
speed-up. CPU: unchanged (no new nodes, no per-frame work; vertex counts +111 Thornling, +172 Burr Slinger, -72
Bramblehorn after the open thorn cones, -265 Oathkeeper).

Honest read: at zoom 30-40 the change is a better value structure (pale thorn points, lighter crowns, leaf rims), not a
new silhouette; at zoom 10 and in portraits the leaves, bark, thorns and horns read as their materials.

## Tests
- `tests/test_gc_nature.gd` (headless): shader slot map / include / hit flash / kit_detail default 0 / derivative rule
  (dFdx / dFdy / fwidth only at the top of fragment(); the bark reads are textureGrad with analytic angle gradients, so
  no mip seam where the atan angle wraps); Ysolde keeps her glow and hit flash;
  every Nature material parses (no garbled line) with a surface_kind 0..7; the palette on nature_living and the team
  variant recolours; UV tags on leaves / thorns survive cluster_mesh and bake, kit primitives never in a tag range;
  Hall units: exported values, named nodes, nature_living + tagged surfaces on the body, hit flash, kit_detail; the 16
  roster scenes in budget (the two stag riders capped at their pre-existing 12500 vertices / 20 draws).
- PASS: test_gc_nature, test_11_v4, test_a17, test_9_v4, test_unit_dances, test_kit_team_color, test_13_v5,
  test_13b_v4, test_g3b_materials, test_unit_voice, test_bowmen, test_unit_review_fixes, test_gb_nature; smoke
  victory=true; test_ws_perf PASS (march p95 21.93 ms, clash p95 25.22 ms at 200 units, budget 30.3 ms at load 1.81).
- perf_test: PERF OVER BUDGET twice (norm 6.93 / 6.98 > limit 6.72) while other agents ran Godot (load 1.26-1.30).
  perf_test spawns only Flame Guards (Fire) on mission 1: no Nature model is in it, so this is not from this pass (the
  Fire unit files were being changed in parallel); rerun on a quiet machine.

## Open issues
- Stagrunner / Glade Outrider: 20 draw instances (rider 12 incl. Spear, Cloak, CloakTail keep_separate + the Grove
  Stag mount's 8); a rider-side merge (Cloak + CloakTail, Spear baked into ArmR) would be the fix.
- Thornback Charger / Bramble Harrier mounts still read boxy at zoom 30 (low radial counts in their sculpted barrels):
  next candidate for a shape pass.
- Bramblehorn R4 sand dE 9.4: a darker rump saddle would fix it if sand maps matter.
