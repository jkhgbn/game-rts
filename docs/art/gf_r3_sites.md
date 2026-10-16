# G-F round 3: construction sites (gf_review3 top-6 item 4)

## Problem
Sites at 0-30 % read wrong and differed per kingdom:
- Fire: a black tiled plinth with a loud orange rim.
- Ice: a dark glass "pond".
- Shadow: flat lilac beams and black slates that floated.

## Recipe (one look for every kingdom)
- **Site pad** (`SiteOutline.make_pad(kingdom, half, stakes)`, node `SitePad`):
  - A lit painted_vc earth / stone pad, every vertex value at least 0.3 (never black).
  - The edge is sunk into the ground, with an ao contact band (ao_bottom -0.6, ao_height 1.5).
  - Kingdom detail:
    - Fire: clay tile courses.
    - Ice: frost flags.
    - Nature: furrows and moss.
    - Shadow: slate flags.
  - Halls also get stakes and cords, plus a beam stack and a kingdom pile (bricks, ice blocks, planks, slates).
  - One mesh is cached per kingdom and size. Each model gets its own material (rule a2_6). Fire runs it through GBF.apply (rule gb_fire).
- **Timber scaffold** is visible from the first frame. When a model has no wood material, it uses a lit timber colour per kingdom (`SiteOutline.timber`).
- **No squashed plinth**: below 7-8 % progress (`SITE_PLINTH_AT`), every Body part is hidden, so nothing floats or reads black.
- **Calm outline on every kingdom**: `outline_calm` now defaults to true in FireHallModel and SmallBuildingModel. The site team rim drops from 0.65 to 0.25, so scaffolds no longer read lilac.
- ContactDecal is hidden while the pad shows. Cost: one pad draw replaces the decal, at every tier, so Low costs no more.

Palette (`SiteOutline.PALETTE`: earth a / earth b / flag / timber / pile):
- Fire: warm clay.
- Ice: cold grey-blue stone.
- Nature: brown loam.
- Shadow: dusk grey-violet slate.

## Files
- `art/buildings/site_outline.gd`: pad builder, palette, `kingdom_of`, `timber`.
- `art/buildings/fire_hall.gd`: pad, plinth gate, timber scaffold, calm default, rim 0.25. Halls, stables, markets, forges and lairs inherit all of it.
- `art/buildings/hearth_small_building.gd`: the same for houses, spires and walls.
- `art/buildings/shadow_hall.gd`, `art/buildings/hovel.gd`: their own site pad and calm overrides are removed; they now use the base.

## Tests
- `tests/test_gf_r3_sites.gd` checks the 4 Halls and the 4 houses at 0 % and 30 %:
  - The pad is lit and has value ≥ 0.2.
  - The scaffold shows.
  - The outline is calm.
  - No Body mesh shows at 0 %.
  - No floating pieces.
  - Once built, the pad, scaffold and outline are hidden.
- `tests/test_gf_shadow_leftovers.gd` is updated: it now expects the calm Fire outline, which used to be the loud one.
- All of these pass: gf_site_outline, gf_billboard_scale, 10_v4, 13_v25, a2_6, gb_fire / ice / nature / shadow, shader_lint, gf_r2_fs, a_9, 10_v1/v2/v3, 13_v26 and a2_4.
- Smoke: `victory=true`. Perf: PERF OK.

## Shots
`docs/art/lab/gf_r3_sites/`:
- `before/` and `after/`: per kingdom, one row overview at z24 (0 / 30 / 70 %) and Hall close-ups at z12.
- `sites_contact_sheet.jpg` and 4 `sites_key_*.png`.
- Tools: `tools/sites_shots.gd` (windowed, `-- --gfx=high --pk= --ek= --tag=`) and `tools/sites_sheet.py`.

## Follow-ups
- Terrain grass pokes through the pad. The grass system should clear it under site footprints (not a tech-artist file).
- The Fire Hall at 30 % still shows its own dark lava-crack stone body. That is the built look, not part of the site.
