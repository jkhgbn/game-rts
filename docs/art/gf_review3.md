# G-F art review, round 3 (2026-10-15)

Read-only art-direction pass after the G-F round-2 fixes. Nothing was edited.

- **Graphics tier.** All shots are at High, 1920x1080, windowed (`'--' --gfx=high`).
- **Ultra.** Skipped: round 2 found it adds little over High.
- **Contact sheet.** `docs/art/lab/gf_review3/gf3_contact_sheet.jpg` has 28 tiles. "#N" below means tile N.
- **Key PNGs (1280x720).**
  - `gf3_key_battle_z30.png`
  - `gf3_key_ice_start_ingame.png`
  - `gf3_key_fire_base_crucible.png`
  - `gf3_key_fire_sites.png`
  - `gf3_key_shadow_site0.png`
  - `gf3_key_ashwind_centre.png`
- **Full set.** The full shot set stays local: `high_fs/`, `high_in/`, `high_mirror/`, `high_maps/`, `high_missions/`, `high_close/`, `menu/`.
- **Tools.**
  - `docs/art/lab/gf_review3/tools/gf3_shots.gd`: the round-2 script plus building sites at 0 % / 45 %, keeps at 20 % HP and the crown isle per map.
  - `docs/art/lab/gf_review3/tools/gf3_sheet.py`: builds the sheet and the key PNGs. Run it with `python -I`.
  - The menu shots come from `art/environment/menu_diorama/menu_diorama_shots.gd`.

## 1. Round-2 items

| # | Round-2 item | Status | Evidence |
|---|---|---|---|
| 1 | Fat HP bars | **Fixed for units** | #14 / #15: the bars are thin and fade out. **Building bars are still the old thick black-framed bars** (`building.gd` `bar_size = (max(2, s.x*0.9), 0.26)`; #7, #9). See new row 3. |
| 2 | Autumn palette and fog | **Partly** | The ground is olive now. The Quartermeet overview (#18) and Ashwind Reach (#20) still sit under a beige-orange haze. The Ashwind lane is a saturated maroon smear (#21). Quartermeet at game zoom is fine. |
| 3 | Shadow roofs and player keep | **Fixed** | #4: slate roofs; the player Dusk Keep reads as dark slate. |
| 4 | Fire keep crown and crucible | **Partly / regression** | The crown is smaller, but its orb cage still dominates every Fire start: #1, #22, #24 and the m03 start. The crucible is no longer a white disc, but from above it now reads as a **black square pit** with small amber puffs (#3). |
| 5 | Ground rings | **Fixed** | #5: the Spire ring is a faint rim. Capture points keep a dashed white circle (minor). |
| 6 | Ice Hall roof | **Partly** | #6: the roof is darker blue slate, but each tile still carries white marble swirl streaks. |
| 7 | White particle blobs | **Fixed (bases), new one in battle** | No mote discs at the bases. In the battle there is a new white blob (new row 2). |
| 8 | Shadow site black square | **Partly** | #8: a scaffold now shows at 0 %. Its beams are flat, unlit lilac-grey, and black slates float at many heights. The Fire site went the other way and is now a black tiled pad (#7). |
| 9 | Crown Hollow vs Thornwater | **Fixed** | #16: Thornwater is a darker marsh with a fen wood. New: its crown-isle bridges are flat green checkered "waffle" carpets (#17). |
| 10 | Ashwind grid forest and grey pads | **Partly** | The forest is clustered now. The muster pads are still dark grey grate rectangles (#20, right), and the overview haze remains. |
| 11 | m02 ice blocks and cliffs | **Fixed** | #24: crystal blocks and rock cliffs. The snow field is flat and empty, with no drifts or tracks. |
| 12 | Start HUD | **Partly** | The champion slots collapsed to one button. The objective panel, the Next hint and the banner still cover the top-left and top-centre at the start (#1, #2, #24). |
| 13 | Menu composition | **Mostly fixed** | #25: the panel is on the right and the pillar is amber. The tagline is thin text on a bright sky. The skirmish setup panel is centred and covers two thirds of the diorama (#26). |
| 14 | Road grass and butterflies | **Fixed** | Butterflies are small. Roads are clean (#27). |
| 15 | m00 grey disc | **Partly** | The small disc is gone. A broad pale grey-lavender blotch, about 15 m across, sits around the keep and the squad, also with fog off (#23). It is probably the base dirt / scorch decal under the night grade. The m00 overview is an empty flat green rectangle. |

## 2. New ranked problems (most visible first)

| # | Problem | Shot | Likely cause file | Owner | Size | Suggested fix |
|---|---|---|---|---|---|---|
| 1 | **The Ice keep is the loudest object on any map.** It is a white crystal spire with white crack veins at full HP and outshines the Fire keep. | #2, #12 | `art/buildings/ice_keep_build.gd`, `ice_keep_glow.gdshader` | tech-artist | S | Crystal albedo about 0.55-0.65 pale blue (not white). Glow / rim energy x0.5. Crack veins only below 50 % HP. |
| 2 | **White HDR blob in the mixed melee** over an Ice unit (steam / frost burst). | #14 (centre) | `art/vfx/spells_g/spell_fx_g.gd` `&"steam"` = `Color(1.5, 1.7, 1.9)` + `steam_puff` 0.9; maybe `art/vfx/caster_fire_vfx.gd` `steam_burst` | tech-artist | S | Cap steam at `MoteCap.VALUE_CAP` 0.72 (e.g. `Color(0.68, 0.72, 0.76)`), alpha 0.45. Halve the `steam_puff` count. Add steam to `test_gf_billboard_scale` / the keep-damage style cap test. |
| 3 | **Building HP bars**: thick 0.26 m black-framed bars across the full footprint on every damaged building and site. They clash with the new thin unit bars. | #7, #9, #14 | `scripts/buildings/building.gd:774` `_build_hp_bar` | systems-coder | S | Use the unit bar look. Height 0.12, width `clamp(s.x*0.6, 1.6, 4.0)`, same fade to 0.35 when not hovered or selected. No black frame. |
| 4 | **Fire construction site at 0 % is a black tiled "hole"** with a bright orange rim. The Ice site is a dark teal glass slab with a white rim that reads as a pond. | #7, #9, #14 (top) | `art/buildings/fire_hall.gd` (site foundation), `art/buildings/ice_hall.gd` site look, `art/buildings/site_outline.gd` | tech-artist | M | Give every kingdom the Nature recipe: a packed-earth / stone pad in the ground colour (value about 0.35), timber scaffold corner posts, a thin calm outline. No dark glass or black floor. |
| 5 | **Fire crucible reads as a black square pit** from the game camera. | #3, #1 | `art/buildings/fire/ember_crucible/ember_crucible.gd`, `crucible_glow.gdshader` | tech-artist | S | Raise the pit floor to a dark ember red (about 0.25, 0.07, 0.03), not black. One soft alpha-blended glow disc at about 0.5 value. Rounded rim stones so it is not a square. |
| 6 | **Haze over the autumn maps** at overview / z45: a beige-orange veil, and the Ashwind lane is a maroon smear. | #18, #20, #21 | `art/environment/autumn/world_env_autumn.tres` (`fog_density` 0.3, `fog_light_color` 0.84/0.81/0.74, `fog_aerial_perspective` 0.22), Ashwind lane ground colour in `art/environment/lane_dressing/lane_dressing.gd` | tech-artist | S | `fog_density` 0.3 to 0.15. `fog_aerial_perspective` 0.22 to 0.1. Fog colour cooler (0.78, 0.80, 0.80). Lane dirt desaturated to a brown-ochre (0.42, 0.30, 0.20). |
| 7 | **Fire keep orb cage still dominates the start** on every Fire map and mission. | #1, #22, #24 | `art/buildings/fire/fire_keep_tiers.gd` / `fire_keep_build.gd` (crown cage) | tech-artist | S | Cage scale 0.82 to 0.65. Orb emission x0.6. Drop the outer ring at tier 1 (show it from tier 2). |
| 8 | **Shadow site at 0 %**: unlit flat lilac scaffold beams, and black slates float at random heights. | #8 | `art/buildings/shadow_hall.gd` (site stage), `art/buildings/dusk_keep_build.gd` share | tech-artist | S | Beams in the dark timber colour with the standard lit material. Slates only on the finished roof plane, stacked on the pad until progress > 0.6. |
| 9 | **Keep damage at 20 % HP is weak for Ice / Nature / Shadow, and no smoke column reads on any keep.** Fire is good (lava trail and rubble). | #10-#13 | `art/buildings/*_keep_build.gd` `Smoke1/2` (30 particles, 2.6 m, alpha 0.65, but invisible from the game camera after the billboard keep-scale pass) | tech-artist | M | Check the drawn smoke size after `gf_billboard.md`'s keep-scale: aim for 3-4 m puffs, lifetime 5 s, 2 columns rising about 8 m. Add 3-4 dark rubble chunks and a missing-roof gap per keep (as Fire has). Shadow's magenta hex net on the ground: alpha x0.5. |
| 10 | **Thornwater crown-isle bridges are flat green checkered "waffle" carpets.** | #17 | `art/environment/crown_variants/crown_isle_variant.gd` / `crown_isle_meshes.gd` (fen variant) | tech-artist | S | Plank boardwalk mesh (as Quartermeet's stone bridges, #19) in weathered wood. No tiled green texture. *A "crown isle per map" task is running now; check it before acting.* |
| 11 | **Ice Hall roof tiles carry white marble swirls.** | #6 | `art/buildings/ice_hall.gd` roof material (stone noise) | tech-artist | S | Remove or dim the swirl layer on the roof (detail strength 0.15). Keep the swirls on the walls only. |
| 12 | **m00 pale grey blotch around the base**, and an empty m00 overview. | #23 | Base dirt / scorch decal under `art/environment/lighting/emberfall_night.gd` grade | tech-artist | S | Darken and tint the base dirt for night (value x0.6, toward the blue-green of the grass). Add a few lantern / campfire props along the m00 road. |

Others, minor:
- **Nature Forge / Stables roof** is a flat lime-green slab (#5, bottom right). Fix: a moss shingle texture.
- **WS muster pads** are dark grey grates (#20). The owner is systems-coder (`scripts/world/wave_strike/muster_pad.gd`), or the tech-artist through `art/environment/lane_dressing/muster_plate.gdshader`. Fix: warm stone, lower contrast.
- **Start HUD**: the objective panel and banner cover the opening shot. Owner: ui-coder (`scripts/ui/`). Fix: collapse the objective panel after 8 s.
- **Skirmish setup menu** covers the diorama (#26). Owner: ui-coder.

## 3. Top 6 fixes for beauty per hour

1. **Calm the Ice keep** (`art/buildings/ice_keep_build.gd`, `ice_keep_glow.gdshader`).
   - Crystal albedo pale blue at value 0.6 or less.
   - Glow energy x0.5.
   - Crack veins only below 50 % HP.
   - Effect: every Ice start (#2) stops being a white beacon.
2. **Cap the battle steam** (`art/vfx/spells_g/spell_fx_g.gd`).
   - `&"steam"` first colour `(1.5, 1.7, 1.9)` becomes `(0.68, 0.72, 0.76)`.
   - `steam_puff` count 10 becomes 5.
   - Check `caster_fire_vfx.gd` `steam_burst` the same way.
   - Effect: the white blob in every big fight goes away (#14).
3. **Thin building HP bars** (`scripts/buildings/building.gd:774`, systems-coder).
   - Height 0.26 becomes 0.12.
   - Width `clamp(s.x*0.6, 1.6, 4.0)`.
   - No black frame.
   - Same fade as the unit bars.
4. **One construction-site recipe for all kingdoms** (`fire_hall.gd`, `ice_hall.gd`, `shadow_hall.gd` site stages, `site_outline.gd`).
   - A ground-coloured earth / stone pad (value about 0.35).
   - Lit timber corner posts.
   - A thin calm outline.
   - Effect: removes the Fire black hole, the Ice pond and the Shadow floating slates (#7-#9).
5. **Lift the autumn haze** (`art/environment/autumn/world_env_autumn.tres`).
   - `fog_density` 0.3 becomes 0.15.
   - `fog_aerial_perspective` 0.22 becomes 0.1.
   - `fog_light_color` becomes `(0.78, 0.80, 0.80)`.
   - The Ashwind lane dirt becomes `(0.42, 0.30, 0.20)` in `lane_dressing.gd`.
   - Effect: Quartermeet and Ashwind overviews read crisp (#18, #20, #21).
6. **Fire keep: crucible and cage** (`ember_crucible.gd` / `crucible_glow.gdshader`, `fire_keep_tiers.gd`).
   - Pit floor dark ember red `(0.25, 0.07, 0.03)` instead of black, with a soft 0.5-value glow disc.
   - Cage scale 0.82 becomes 0.65; orb emission x0.6.
   - Effect: the Fire start (#1, #3, #22, #24) stops reading as "black hole plus giant orb".

## 4. Regressions from the G-F fixes

- **Fire crucible over-corrected.** The white disc (round 2) became a black square pit (#3). This came from `gf_r2_buildings_fs.md` / `crucible_glow.gdshader`.
- **Fire site at 0 % is a black tiled pad** with an orange rim (#7). The site-outline calm pass left a dark foundation. The Ice site is a dark glass slab (#9).
- **White steam / frost blob in the melee** (#14).
  - Not one of the keep emitters the cap test covers. It is probably the HDR `steam` colour now drawn at full size after the billboard keep-scale pass (`gf_billboard.md`).
  - The battle z14 shot also shows a bright yellow-white sphere on a Fire unit (#15, bottom left), same class.
- **Keep damage smoke columns do not read** from the game camera on any keep (#10-#13), although `Smoke1/2` emit.
  - The size after the keep-scale pass needs a check.
  - The damage *caps* themselves work: no white blobs on the keeps at 20 % HP.
- **Shadow site floating slates** (#8). The site outline is present and calm, as intended. The slate pieces are placed at random heights before the roof exists.
- **Not seen as regressions.**
  - Site outlines are present on all four kingdoms.
  - Unit motes and fireflies are not oversized.
  - The keep blazes and rifts stay under the cap.

## Aside (not art)

While lineup units were freed, the run printed this error repeatedly:

`SCRIPT ERROR: Trying to cast a freed object` at `scripts/units/new_units_12.gd:388` (`_try_frost_needle`, called from `_physics_process:279`).

It needs an `is_instance_valid` guard on the target. Owner: gameplay-coder.
