# G-E fixes C (2026-10-15)

Review items 9, 10, 12 and 13 of `docs/art/ge_review.md` (the ones outside its top 8). Tech-artist pass, art-owned
files only; mission code changes are requests in `docs/handoff/for-systems-coder.md` ("G-E fixes C").

Shots (windowed, High): `docs/art/lab/ge_fixes_c/gec_contact_sheet.jpg` (before = the G-E review shots, after = this
pass) + `gec_key_oldroot.png`, `gec_key_forest_floor.png`, `gec_key_ashwind_lane.png`. Every other frame stays local in
`docs/art/lab/ge_fixes_c/after/` (the folder has a `.gdignore`). Tool: `docs/art/lab/ge_fixes_c/tools/gec_shots.gd`
(modes `m03`, `ashwind`, `crown`, `all`). Test: `tests/test_ge_fixes_c.gd`.

## Hook

`art/environment/level_looks.gd` (`LevelLooks.apply(level)`, load()-only) runs per-level moods from
`GroundDetail._ready` (main.gd's existing art hook). GroundDetail is never made in headless or sim runs, so tests, labs
and the Bot Lab do not change. It runs before the map dressing populates (deferred) and before GroundDetail bakes the
ground. Each look checks for itself whether the level wants it, and running it again does nothing new.

## 9. Sighing Wood (mission 3)

- **Oldroot** (`art/environment/ge_props/oldroot.tscn`, mesh `ge_props/meshes/oldroot.res`, ~27.6k tris for one
  landmark): seven twisted trunk strands around a near-black heart. The front strand is missing, so the Signet spot
  (0, 2.1, 1.15) shows through the gap with a soft sap-green glow (opaque emission 0.9: no white disc, no light).
  Buttress roots taper and dive into the ground (r <= 3.8 m, inside the thorn ring). Five great limbs, and a high canopy
  of leaf puffs, open on the camera's line to the gap. Also hanging moss, ivy and bracket fungi. Leaves use the IVY kind,
  because the shader's position hash at the origin turned a LEAVES crown gold. Draw-only: the mission's trunk collider
  stays the only collider.
- **Warden Gate** (`ge_props/warden_gate_art.tscn`): a mossy ruined arch of dressed stone. Two piers inside the gate's
  feet colliders, nine voussoirs, a carved warden keystone, coping, ivy, rubble and low wall stubs. The mission keeps its
  amber crack quad (open state) and HP bar. These replace the grey placeholder boxes from the review.
- **Forest mood** (`art/environment/sighing_wood/forest_mood.gd`, `ForestMood`, levels with `MISSION_ID == &"m03"` or
  `forest_mood() == true`):
  - Ground: the level's own ground copy paints the Old Wood biome (dark moss floor) over the wood, with Hearth Meadow
    round both bases. MapDressingArt then scatters the Old Wood set (ferns, glowcaps, moss boulders, fallen trunks)
    instead of glade flowers, at density 0.8. Every tier.
  - Light: `preset_forest.tres` (green-gold sun, cool green fill, mossy vignette, same Environment as warm) on the
    LightingRig. Every tier.
  - High+ only (Low = cost before G1):
    - Canopy shade: a shadow-only MultiMesh of small leaf masses (~300) placed from the sun direction, so the dapple
      lands on the wood and never on a clearing.
    - 12 sun shafts (`light_shaft.gdshader`: additive, unshaded, `fog_disabled`, no depth write). They lean away from
      the camera so they read as streaks, and show only where the local player sees now (VfxFog.ok, 4 Hz, faded,
      `no_ghost`).
  - Interim: until the systems-coder request lands, ForestMood hides the placeholder Oldroot / Warden Gate meshes at
    runtime and adds the art scenes. It skips any node that already has the art.
- Not done: the thorn ring hedge boxes and the Root Hearts' cradles are still placeholders. A denser tree layout is
  offered as an optional request (it is gameplay-visible).

## 10. Ashwind Reach lane

`art/environment/lane_dressing/lane_dressing.gd` (`LaneDressing`, any level with `lane_for()` and a MapLayout `layout`
whose path `lane_a` exists, i.e. Wave Strike) reads the layout:

- Road edges: kerb stones in broken runs, waystones every 30 m, banner pairs at each spawn approach and mid-road (new
  meshes `lane_banner.res` and `lane_fence.res`).
- Treeline: fence runs, fallen trunks, mossy boulders, gorse and heather.
- Grass bands: autumn grass and heather patches, plus charred snags with burnt tufts.
- A ruined shrine on each side of the central plaza (plinths, drums, flagstones, ember moss, a broken pillar), at the
  lane edge.
- Burnt grass and charred wood in the layout's ash zones round the Bastions.

About 700 pieces in 16 MultiMesh draws, built the same way every time. Medium+ only (Low keeps the cost before G1).
Map detail Low keeps half of the small scatter kinds (424 pieces); the landmarks, fences, banners and waystones stay whole. Draw-only: nothing on nav layers. Bastions, spawn
boxes, tower / muster slots and rock blocks are kept clear; tall pieces stay off the road band. No data/maps change was
needed: the layout already has everything this reads. Note: the after shots also show the autumn swap (AutumnSwap,
G-D), which is not part of this pass.

## 12. Neutral thatch

`TavernModel.C_THATCH` (0.63, 0.47, 0.25) -> (0.54, 0.44, 0.30): value -15 %, saturation -25 %. The tavern roofs no
longer out-shout the crown altar.

## 13. Nature death leaves

CombatFxG Nature death: leaves are 0.08-0.12 m (was 0.16-0.24), twice as many, and live 1.8-2.6 s (was 3.5-4.8). The
burst reads as leaves, not plates. A second leaf source comes from the unit model itself:
`art/units/nature/nature_war_model.gd` `add_death_bloom` -> `make_petals(..., 0.15)`. It is G-C's area, so it was left
alone; halving that size would finish the job.
