# G-F crown isle variants

Each layout map gets its own look of the Crown Isle. This is art only: no colliders, navmesh or map data change.
Code lives in `art/environment/crown_variants/`. Test: `tests/test_gf_crown_isle.gd`. Shots: `docs/art/lab/gf_crown_isle/`.

## Which map gets what

| Level | Variant |
|---|---|
| Crown Hollow (`skirmish.tscn`, or a layout with id `crown_hollow`), missions, menus | none (unchanged) |
| Thornwater | `thornwater`: a drowned, overgrown ruin |
| Quartermeet | `quartermeet`: a harvest-highland stone circle |
| Any other layout map with a crown isle | `neutral`: a weathered ruin |

The variant is keyed on the level's `map_layout().id`. A level without a layout gets none.

## Hook

The hook is `CrownPedestalArt._ready`, which calls `_apply_isle_look` deferred. That runs
`crown_isle_look.gd ensure_for_pedestal(self)`.

- The altar is spawned after the props, the river and LevelLooks, so the whole isle exists by then.
- Windowed runs only. Headless and `-s` runs are skipped unless `allow_headless` is set (the test sets it).
- Sim mode and `disabled` (the "before" shots) do nothing.
- `ensure_for_level` is idempotent. It adds one child node to the level, named `CrownIsleVariant` (class `CrownIsleVariant`).

No lead hook is needed.

## Every tier (Low included): swaps only

These add no draw, material, shader, light or particle.

- **Pillars.** The isle's ruin pillars (EnvProps `RuinPillar` MultiMesh) get a level-local MultiMesh copy that draws a repainted copy of `ruin_pillar.res`.
  - If that MultiMesh also holds pillars off the isle, Low leaves it untouched.
- **Rubble ring.** The altar's `RuinDressing` gets a repainted mesh copy.
- **Crown crossings.** Lane bridges and crown steps within the moat radius + 6.5 m get repainted mesh copies.
  - Only the stone surfaces (nature / env painted) are repainted.
  - The gold trims, ember coals, altar `Stone`, runes, seal, beacon and glow are untouched, so the Ember Crown reads the same on every map.
- **Paving.** `paving_color` is set on the level's own ground material(s). The shared `ground_material.tres` is never touched.

Repainting rewrites vertex colours on stone-kind vertices, keeping each vertex's luminance:

| Variant | Stone | Moss / lichen |
|---|---|---|
| thornwater | peat-dark (0.335, 0.33, 0.285) | wet dark foot, moss climbing the shafts, mossy break faces |
| quartermeet | pale granite (0.50, 0.515, 0.52) | yellow / orange lichen rosettes, no moss |
| neutral | weathered (0.47, 0.45, 0.405) | sparse moss |

Walked tops (bridge decks, steps, flat faces below 0.3 m) never gain moss (shader UV.x is capped at its source value and
the painted moss is cut to a third), so the crossings keep reading as stone paths. Luminance gain is capped at 1.2.

Paving colours: thornwater (0.37, 0.39, 0.33), quartermeet (0.55, 0.565, 0.565), neutral (0.50, 0.48, 0.44).

The repainted meshes keep the source materials: the shared `nature_mat` (the autumn shader on Quartermeet is
recognised) and `env_painted_mat`. They are cached once per run.

## Medium and up: props

Each kind is one MultiMesh, draw-only (no collider, nothing on nav layers). Small kinds cast no shadow.

- **thornwater (7 draws on the map):**
  - Half the isle pillars are broken to mossy stumps, about 1.05 m tall with a jagged break.
    - The pick is point-symmetric: it hashes the angle mod PI.
    - The pillar collider stays; a stump still reads as an obstacle.
  - Fallen drums lie beside the stumps.
  - 30 rushes in clumps on the rim, 6 lily pads at the isle waterline (never at a crossing).
  - 7 rain puddles and 12 sunk flagstones on the paving, 5 mossy boulders.
- **quartermeet (5 draws):**
  - Every pillar stands, each with a straw harvest garland at 58 % of its height.
  - A low drystone edging (Quartermeet's `wall()`, scaled 0.95 / 0.6 / 0.62) runs round the rim at inner r - 0.7, with gaps at the crossings and a few fallen gaps.
  - Small stooks at some pillar feet, heather and lichen stones on the rim.
- **neutral (4 draws):** a quarter of the pillars broken, fallen drums, 9 sunk flagstones, 3 boulders.

Placement keeps clear of:

- the altar dais (r < 3.8)
- the lane from each crossing to the crown (2.6 m either side)
- the water
- the bridges

The test checks every placed prop against these.

## Restore

The variant node records every value it swaps (node `mesh` / `multimesh`, ground `paving_color`) and puts it back in
`_exit_tree`. No shared material or source mesh is ever written. The test snapshots nature_mat, env_painted_mat,
ground_material.tres, the water materials and the source meshes (pillar, rubble, lane bridge, altar, drums,
flagstones), then compares after each map and after Crown Hollow following it.

## Not done here (not owned)

- Timber-plank bridges for Thornwater: `art/environment/bridges/` is not mine. The crown lane bridges and steps are
  only repainted (peat-dark stone, more moss). See `docs/handoff/for-lead.md`.
- The ground paving pattern itself (`ground.gdshader`): only its colour uniform is used.
