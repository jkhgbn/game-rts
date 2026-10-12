# Art assets graded below 90 (worst first)

## Status 2026-10-12 (refresh; read this first, the 2026-09-28 table below is history)

Evidence: file exists / `model_path` resolves, dated `in-game grade 2026-09-30` / `2026-10-12` comments in the asset code,
the newest lab card (`docs/art/lab/<name>/` vs `_army/assets/<name>/`, newest `started` wins), and 10 headless budget-only
re-runs tonight in `docs/art/lab/_headless_2026-10-12/<name>/` (headless skips every render check, so its quality is
not comparable with windowed cards; it only proves the B2 / B4 / B8 FAILs are gone). Tally: **45 done, 11 partly, 11 open**
(section A, 67 rows). "code fix" = the fix is in the code with a row-numbered comment but no windowed lab run confirms it.

### Still open (worst first)

- 69.9 **ember_crucible** (row 28; lab 2026-09-30 WARN): R1 grow the 40 m read x1.23, team colour visible at 40 m, contrast on ash / other grounds. Worst asset left.
- 81.1 **ice_wall** (row 44; lab 09-30): R1 3677 -> ~5750 px: grow the key masses x1.25 (got worse than 86.1).
- 82.5 **ruin_warden** (row 34; card 09-27, scene untouched since): B2 12 -> 10: GapLight / Core keep_separate under Chest, keep only the animated one.
- 85 (headless) **gloam_rider** (row 64; re-run tonight): B2 still FAIL 20 (want <= 12): bake the static props into one mesh; R10 radius 0.6 vs z 2.15 m.
- 86.0 **trade_post** (row 43; card 09-27, untouched): B4 10711 -> <= 6000 (Structure 6310, Sign0 1824: fewer segments).
- 86.4 **briar_roc** (row 50; lab 09-30, down from 87.2): R3t base colour per team on meadow, R10 radius 1.1 vs its wing span.
- 87.7 **maelis** (row 54; card 09-27, untouched): R4 nature_stone #85806b -> #9f9585 (tiny gain; low value).
- 88.3 **grove_stag** (row 56; card 09-27, grove_stag.gd edited 09-28): R4 antler colour; needs a windowed re-run first, may already pass.
- 88.7 **roc** (row 60; card 09-27, roc.gd edited 09-30 for other reasons): R10 raise radius 0.9 -> 1.54 or pull the wings in.
- 88.9 **flame_guard** (row 62; card 09-27, scene edited 09-30): R3t fire_bronze #9e6629 -> #c57535 (Nature team dE 14); windowed re-run first.
- 89.6 **sprigling** (row 61; lab 09-30): R8 body_height 1.2 -> 1.97 in sprigling.tscn + data/units/sprigling.tres (still 1.2).

### Partly done

- 55 / 60 / 60 **wayfinder, mage_archer, wildcaller** (rows 18 / 20 / 21): B8 merged 09-30 (headless tonight: wayfinder 92, wildcaller 91, no FAIL; B4 / R8w WARN left). Scale 1.15x + class colour **waits for JS**.
- 72 -> lab 88.2 **nature_keep** (row 27): canopy pale sage 09-30 (in-game fix done); lab still FAIL B8 20 -> 16 materials.
- 78 -> lab 90.3 **vessa** (row 31): crown flames low + wide 09-30; R8 body_height 2.0 -> 2.9 still WARN (the 1.15x wizard scale is not done).
- 80 **cinder_dragon** (row 32): cinder_membrane.tres ember_energy 1.0 -> 0.2 (09-30); render check R5 never re-run (windowed run to confirm).
- 89.6 **dragon_roost** (row 42; lab 09-30): R4k ash contrast: no single recolourable body material.
- 88.9 **dusk_keep** (row 47; lab 09-30): R5 glow points 47 -> 10: DarkStone crack_strength 1.0 -> lower.
- 88.4 **dread_paddock** (row 51; lab 09-30): R5 glow points 6 -> 3: crack_strength down.
- 89.1 **glade_outrider** (row 53; lab 09-30, rider edited 10-02 after it): B2 FAIL 20 -> 16.
- 88.9 **stagrunner** (row 55; lab 09-30): B2 FAIL 20 -> 16 (Spear / Cloak keep_separate).

### Done (evidence)

- Rows 1-4 **stables** x4: models built 09-30 (art/buildings/stables/<k>/<k>_stables.tscn); lab fire 90.5, ice 93.4, nature 91.4, shadow 92.4.
- Rows 5-16 **T3 / extra units** x12: every model_path resolves (files 09-30); lab 92.0-97.3 (no FAIL).
- Rows 17 / 19 **Ice spell + hit VFX**: ice_vfx.gd / combat_vfx.gd 09-30 pass + 10-12 readability pass (commits 6a5803c5, a3141a3e; docs/art/ingame_grade/ice_vfx_2026-10-12/).
- Rows 22 / 23 **snow skirt + ice_keep**: ice_keep.gd / ice_keep_build.gd 09-30 (snow ~17 % darker, crystal albedo down); before / after in ice_keep_2026-10-12/; lab 10-11 87.2 PASS (no FAIL; remaining points are C1 shape INFO).
- Row 24 **essence_well**: lab 10-12 WARN 88, R3 meadow PASS (dE 56.7).
- Row 25 **Nature spell VFX**: nature_vfx.gd pale-gold rim + petals (09-30).
- Row 26 **torvald**: 09-30 dark-blue mass + 10-12 pass; lab 10-11 95.0.
- Row 29 **Fire / Shadow spell decals**: spell_vfx.gd 09-30 decal = real AoE, opacity lowered (code fix, no lab card for VFX).
- Row 30 **market_fire** 91.8; row 35 **nature_hall** 91.2; row 38 **shadow_hall** 90.7; row 41 **fire_hall** 91.5; row 45 **nature_hollow** 93.2; row 46 **market_nature** 92.4; row 49 **ice_hall** 90.5; row 52 **ice_lodge** 90.2; row 57 **market_ice** 94.3; row 63 **fire_tower** 90.1 (all windowed lab 2026-09-30).
- Rows 33 / 36 / 39 / 59 **magpie_den, greywater_lodge, tavern_model, hovel**: B8 palette merge (+ greywater B4) 09-30; headless tonight: B4 / B8 PASS, 0 FAIL (only A1 missing-hooks WARN, already a WARN before).
- Row 37 **hollow_stag**: B2 shins as one skinned mesh (09-30); headless tonight 93, B2 PASS.
- Row 66 **cinderlock**: B4 cut (09-30); headless tonight 95, B4 PASS.
- Rows 40 / 48 / 58 / 65 / 67 **wayshrine, crown_pedestal, barrow_giant, heath, watchtower**: code fix with a row-numbered comment (wayshrine READ_SCALE x1.1, crown_beacon rings, barrow_soul_glow energy 0.2, heath gorse darker, watchtower cresset glow); render checks not re-run, so one windowed batch should confirm them.

Section B (army reads) and C (ungraded) were not re-graded: no new skirmish capture since 09-28 (the Ice white-smear part of B is
covered by rows 17 / 19).

2026-09-28. **Grade** = the in-game grade where the asset was seen in the skirmish captures (`shots/`, method in
`report.md`), else the latest Art Lab quality (123 scorecards from the 2026-09-26/27 runs: `docs/art/lab/_army/assets/`
+ `docs/art/lab/<name>/`; the full army sweep was **not** re-run today: it is a 47-min windowed run and the laptop had to
stay light. Re-run: `.	oolsrt_labun_art_lab.ps1 -Sweep all`). **What reaches 90** = the concrete change; lab rows
quote the lab's own top "Improve next" (its `fixes.json` recipe when there is one). Many lab rows below 90 are pure
budget items (B8 material count, B2 draw instances, B4 vertices): they cost score but are invisible on screen.

## A. Per asset

| # | grade | asset | kind | kingdom | what reaches 90 | evidence |
|---|---|---|---|---|---|---|
| 1 | 5 | fire_stables | building | fire | Model missing: data/buildings/fire_stables.tres model_path -> art/buildings/stables/fire/fire_stables.tscn does not exist, so the game shows a flat red box with a chimney. Build the model (a lair model as stopgap). | shots/a_battle_fire_shadow_far.png |
| 2 | 5 | ice_stables | building | ice | Model missing (art/buildings/stables/ice/ice_stables.tscn): flat pale box in-game. Build the model. | shots/b_battle_ice_nature_far.png |
| 3 | 5 | nature_stables | building | nature | Model missing (art/buildings/stables/nature/nature_stables.tscn): flat green box in-game. Build the model. | shots/b_base_nature_far.png |
| 4 | 5 | shadow_stables | building | shadow | Model missing (art/buildings/stables/shadow/shadow_stables.tscn): flat purple box in-game. Build the model. | shots/a_base_shadow_far.png |
| 5 | 15 | barrow_knight | unit (T3 / extra) | shadow | Placeholder model in-game (data/units/barrow_knight.tres model_path -> art/units/shadow/barrow_knight/barrow_knight.tscn is missing; the placeholder scene is shown). Build the real model in the kingdom kit: silhouette, team-colour cloth, attack / death animation. | shots/a_battle_fire_shadow_close.png |
| 6 | 15 | bramble_harrier | unit (T3 / extra) | nature | Placeholder model in-game (data/units/bramble_harrier.tres model_path -> art/units/nature/bramble_harrier/bramble_harrier.tscn is missing; the placeholder scene is shown). Build the real model in the kingdom kit: silhouette, team-colour cloth, attack / death animation. | shots/b_battle_ice_nature_close.png |
| 7 | 15 | duskbolt_harrier | unit (T3 / extra) | shadow | Placeholder model in-game (data/units/duskbolt_harrier.tres model_path -> art/units/shadow/duskbolt_harrier/duskbolt_harrier.tscn is missing; the placeholder scene is shown). Build the real model in the kingdom kit: silhouette, team-colour cloth, attack / death animation. | shots/a_battle_fire_shadow_close.png |
| 8 | 15 | emberdart_harrier | unit (T3 / extra) | fire | Placeholder model in-game (data/units/emberdart_harrier.tres model_path -> art/units/fire/emberdart_harrier/emberdart_harrier.tscn is missing; the placeholder scene is shown). Build the real model in the kingdom kit: silhouette, team-colour cloth, attack / death animation. | shots/a_battle_fire_shadow_close.png |
| 9 | 15 | frostcrown_juggernaut | unit (T3 / extra) | ice | Placeholder model in-game (data/units/frostcrown_juggernaut.tres model_path -> art/units/ice/frostcrown_juggernaut/frostcrown_juggernaut.tscn is missing; the placeholder scene is shown). Build the real model in the kingdom kit: silhouette, team-colour cloth, attack / death animation. | shots/b_battle_ice_nature_close.png |
| 10 | 15 | pyrehoof_lancer | unit (T3 / extra) | fire | Placeholder model in-game (data/units/pyrehoof_lancer.tres model_path -> art/units/fire/pyrehoof_lancer/pyrehoof_lancer.tscn is missing; the placeholder scene is shown). Build the real model in the kingdom kit: silhouette, team-colour cloth, attack / death animation. | shots/a_battle_fire_shadow_close.png |
| 11 | 15 | rime_harrier | unit (T3 / extra) | ice | Placeholder model in-game (data/units/rime_harrier.tres model_path -> art/units/ice/rime_harrier/rime_harrier.tscn is missing; the placeholder scene is shown). Build the real model in the kingdom kit: silhouette, team-colour cloth, attack / death animation. | shots/b_battle_ice_nature_close.png |
| 12 | 15 | snowdrift_rider | unit (T3 / extra) | ice | Placeholder model in-game (data/units/snowdrift_rider.tres model_path -> art/units/ice/snowdrift_rider/snowdrift_rider.tscn is missing; the placeholder scene is shown). Build the real model in the kingdom kit: silhouette, team-colour cloth, attack / death animation. | shots/b_battle_ice_nature_close.png |
| 13 | 15 | spirit_wolf | unit (T3 / extra) | nature | Placeholder model in-game (data/units/spirit_wolf.tres model_path -> art/units/nature/spirit_wolf/spirit_wolf.tscn is missing; the placeholder scene is shown). Build the real model in the kingdom kit: silhouette, team-colour cloth, attack / death animation. | shots/b_battle_ice_nature_close.png |
| 14 | 15 | sunforge_cataphract | unit (T3 / extra) | fire | Placeholder model in-game (data/units/sunforge_cataphract.tres model_path -> art/units/fire/sunforge_cataphract/sunforge_cataphract.tscn is missing; the placeholder scene is shown). Build the real model in the kingdom kit: silhouette, team-colour cloth, attack / death animation. | shots/a_battle_fire_shadow_close.png |
| 15 | 15 | thornback_charger | unit (T3 / extra) | nature | Placeholder model in-game (data/units/thornback_charger.tres model_path -> art/units/nature/thornback_charger/thornback_charger.tscn is missing; the placeholder scene is shown). Build the real model in the kingdom kit: silhouette, team-colour cloth, attack / death animation. | shots/b_battle_ice_nature_close.png |
| 16 | 15 | veilborn_dreadrider | unit (T3 / extra) | shadow | Placeholder model in-game (data/units/veilborn_dreadrider.tres model_path -> art/units/shadow/veilborn_dreadrider/veilborn_dreadrider.tscn is missing; the placeholder scene is shown). Build the real model in the kingdom kit: silhouette, team-colour cloth, attack / death animation. | shots/a_battle_fire_shadow_close.png |
| 17 | 52 | Ice spell VFX (ice_vfx.gd: Rime Aegis dome, Flash Freeze block) | vfx | ice | Near-white, additive and huge: domes and ice blocks hide Torvald, his targets and the ground. Tint cyan / steel, alpha-blend instead of additive, emission <= 1.5, hollow the dome to a rim. | shots/b_hero_ice_nature_1.png |
| 18 | 55 | wayfinder | unit/champion | neutral | Champions at 22-30 m read as small brown slabs; only the HUD shield marker tells them apart. Scale 1.15x, one bright class colour on cloak / plume, a clear weapon silhouette per class; B8 10 -> 5 materials. (lab 85.4) | shots/b_hero_ice_nature_rts.png |
| 19 | 60 | Combat hit VFX on Ice units (frost on-hit puffs, combat_vfx.gd) | vfx | ice | Every hit leaves a white puff the size of a unit: the Ice line turns into a white smear mid-fight. Halve puff size / lifetime, tint cyan, keep it under the bloom threshold. | shots/b_battle_ice_nature_close.png |
| 20 | 60 | mage_archer | unit/champion | neutral | Same champion read problem (not in the captured fight; lab 91). Bright class accent + 1.15x scale; B8 11 -> 7 materials. (lab 91.2) | lab only |
| 21 | 60 | wildcaller | unit/champion | neutral | Same champion read problem (not in the captured fight; lab 87). Bright class accent + 1.15x scale; B8 13 -> 5 materials. (lab 86.7) | lab only |
| 22 | 66 | Snow skirt under Ice buildings (ice_keep_ground / snow ground decal) | terrain | ice | Soft cotton-wool white blobs around every Ice building; reads as a rendering glitch at 30 m. Hard edge, ~1 m wide, blue-grey shadow side. | shots/b_base_ice_far.png |
| 23 | 68 | ice_keep | building/keep | ice | In-game it is the brightest thing on screen: pale crystal + snow skirt blow out under bloom and the silhouette melts into its own white fringe. Drop crystal / snow albedo ~15 % (white only on spire tips), shrink the snow-skirt decal to a hard-edged 1 m rim, then the B8 merge (11 -> 8 materials). (lab 88.4) | shots/b_base_ice.png |
| 24 | 69.3 | essence_well | building/hall | neutral | Lab FAIL: R3 Contrast vs ground (meadow): Raise the contrast of the key read on meadow (dE 14.9): value is close to the ground (dL -5): lighten the top / back 15-20 % or add a dark saddle / pale belly band; the body sits in the gr... | lab: `docs/art/lab/_army/assets/essence_well/scorecard.json` |
| 25 | 70 | Nature spell VFX (nature_vfx.gd: Wild Bloom / Call the Thicket domes) | vfx | nature | Legible green dome, but the same green as the grass; add a pale-gold rim and petals so it reads on meadow. | shots/b_hero_ice_nature_rts.png |
| 26 | 70 | torvald | unit/wizard | ice | Reads only by the white dome of his own spells; in the hero fight he vanishes inside Rime Aegis / Flash Freeze. Give him one dark-blue mass (cloak) and a saturated cyan staff glow; lab B4 verts 4.6k -> 3k. (lab 90.9) | shots/b_hero_ice_nature_1.png |
| 27 | 72 | nature_keep | building/keep | nature | Green canopy on green meadow (lab dE 4.9) confirmed in-game: the keep reads as a big bush. Move the canopy to pale sage / autumn olive with a bark-brown trunk (not the neon #65ff85 of the lab recipe), put the team banner on top-facing surfaces; cut verts 39.6k -> 12k. (lab 85.0) | shots/b_base_nature.png |
| 28 | 73.4 | ember_crucible | building/hall | fire | Lab FAIL: B8 12 -> 8 materials: use one material for look-alike pairs: StandardMaterial3D#-17671 -> StandardMaterial3D#-25632 (dE 0.0), StandardMaterial3D#-91110 -> StandardMaterial3D#-25632 (dE 0.0), ec_iron -> ec_dark (dE 9.1), ... | lab: `docs/art/lab/_army/assets/ember_crucible/scorecard.json` |
| 29 | 74 | Fire / Shadow spell VFX (spell_vfx.gd: Kindle ring, Umbral Shroud spiral) | vfx | fire / shadow | Colour-coded and readable, but the ground decals are ~12 m wide and cover the keep and every unit; shrink to the real AoE and drop decal opacity to ~60 %. | shots/a_hero_fire_shadow_2.png |
| 30 | 74 | market_fire | building/hall | fire | The red/white striped awning is the most saturated object in the Fire base and reads as a circus tent, louder than the keep. Desaturate the stripes to ember-red / soot-cream, shrink the awning 20 %, then the B8 merge. (lab 89.2) | shots/a_battle_fire_shadow_close.png |
| 31 | 78 | vessa | unit/wizard | fire | Tiny at 30 m: a red dot next to the keep. Raise body_height to the head top (lab R8) and scale ~1.15x so the wizard is the biggest infantry-size figure; keep the crown flames low and wide. (lab 91.3) | shots/a_base_fire.png |
| 32 | 80 | cinder_dragon | titan/titan | fire | Strong silhouette in-game, but 9 glow points speckle over the Fire base; dim the membrane embers (lab recipe ember_energy 1.0 -> 0.2) so only mouth / heart glow. (lab 86.4) | shots/a_battle_fire_shadow_far.png |
| 33 | 80.5 | magpie_den | building/hall | neutral | Lab FAIL: B8 19 -> 8 materials: use one material for look-alike pairs: StandardMaterial3D#-21508 -> StandardMaterial3D#-74709 (dE 0.0), StandardMaterial3D#-74709 -> StandardMaterial3D#-38011 (dE 0.0), StandardMaterial3D#-38011 -> ... | lab: `docs/art/lab/_army/assets/magpie_den/scorecard.json` |
| 34 | 82.5 | ruin_warden | unit/creature | neutral | Lab FAIL: B2 12 -> 11 (want <= 10): GapLight, Core are keep_separate under Chest: keep only the animated / toggled one separate | lab: `docs/art/lab/_army/assets/ruin_warden/scorecard.json` |
| 35 | 83.1 | nature_hall | building/hall | nature | Lab FAIL: B8 21 -> 9 materials: use one material for look-alike pairs: StandardMaterial3D#-10823 -> StandardMaterial3D#-24714 (dE 0.0), StandardMaterial3D#-24714 -> StandardMaterial3D#-16893 (dE 0.0), StandardMaterial3D#-16893 -> ... | lab: `docs/art/lab/_army/assets/nature_hall/scorecard.json` |
| 36 | 83.4 | greywater_lodge | building/hall | neutral | Lab FAIL: B4 24101 -> 12093 (want <= 12000): Structure 21865 -> 10933 verts; HoundMesh 861 -> 431 verts; Rubble 480 -> 240 verts; Lantern 324 -> 162 verts; ContactDecal 288 -> 144 verts; DoorLeaf 201 -> 101 verts (fewer segments: ... | lab: `docs/art/lab/_army/assets/greywater_lodge/scorecard.json` |
| 37 | 83.6 | hollow_stag | unit/creature | neutral | Lab FAIL: B2 13 -> 13 (want <= 10): no merge group found (every mesh has its own pivot and material): Fewer keep_separate parts, bake static props into one mesh, one MultiMesh per repeated part | lab: `docs/art/lab/_army/assets/hollow_stag/scorecard.json` |
| 38 | 83.9 | shadow_hall | building/hall | shadow | Lab FAIL: B8 13 -> 8 materials: use one material for look-alike pairs: StandardMaterial3D#-73222 -> StandardMaterial3D#-59258 (dE 0.0), StandardMaterial3D#-23843 -> StandardMaterial3D#-59258 (dE 0.0), ShaderMaterial#-54303 -> Shad... | lab: `docs/art/lab/_army/assets/shadow_hall/scorecard.json` |
| 39 | 84.2 | tavern_model | building/hall | neutral | Lab FAIL: B8 16 -> 8 materials: use one material for look-alike pairs: StandardMaterial3D#-52373 -> StandardMaterial3D#-60218 (dE 0.0), StandardMaterial3D#-60218 -> StandardMaterial3D#-23293 (dE 0.0), StandardMaterial3D#-23293 -> ... | lab: `docs/art/lab/_army/assets/tavern_model/scorecard.json` |
| 40 | 84.8 | wayshrine | building/hall | neutral | Lab WARN: R1 4749 -> ~5750 px: grow the 40 m read x1.1 (area goes with the square: scale the key masses / body 10 %) | lab: `docs/art/lab/_army/assets/wayshrine/scorecard.json` |
| 41 | 85.1 | fire_hall | building/hall | fire | Lab FAIL: B8 13 -> 8 materials: use one material for look-alike pairs: StandardMaterial3D#-84631 -> StandardMaterial3D#-70794 (dE 0.0), StandardMaterial3D#-13749 -> StandardMaterial3D#-70794 (dE 0.0), ShaderMaterial#-65876 -> Shad... | lab: `docs/art/lab/_army/assets/fire_hall/scorecard.json` |
| 42 | 85.5 | dragon_roost | building/hall | fire | Lab FAIL: B8 17 -> 8 materials: use one material for look-alike pairs: StandardMaterial3D#-7256 -> StandardMaterial3D#-70684 (dE 0.0), StandardMaterial3D#-70684 -> StandardMaterial3D#-15114 (dE 0.0), StandardMaterial3D#-15114 -> S... | lab: `docs/art/lab/_army/assets/dragon_roost/scorecard.json` |
| 43 | 86.0 | trade_post | building/small | neutral | Lab WARN: B4 10711 -> 5764 (want <= 6000): Structure 6310 -> 3155 verts; Sign0 1824 -> 912 verts; Awning 546 -> 273 verts; Rubble 480 -> 240 verts; AwningFrame 357 -> 179 verts; Lantern 335 -> 168 verts; Arm 334 -> 312 verts (fewe... | lab: `docs/art/lab/_army/assets/trade_post/scorecard.json` |
| 44 | 86.1 | ice_wall | building/small | ice | Lab WARN: R1 2759 -> ~5750 px: grow the 40 m read x1.44 (area goes with the square: scale the key masses / body 44 %) | lab: `docs/art/lab/_army/assets/ice_wall/scorecard.json` |
| 45 | 86.1 | nature_hollow | building/hall | nature | Lab FAIL: B8 18 -> 9 materials: use one material for look-alike pairs: StandardMaterial3D#-73353 -> StandardMaterial3D#-16893 (dE 0.0), StandardMaterial3D#-16893 -> StandardMaterial3D#-79643 (dE 0.0), Wood -> Bark (dE 15.7), Bark ... | lab: `docs/art/lab/_army/assets/nature_hollow/scorecard.json` |
| 46 | 86.3 | market_nature | building/hall | nature | Lab FAIL: B8 19 -> 10 materials: use one material for look-alike pairs: StandardMaterial3D#-60158 -> StandardMaterial3D#-46252 (dE 0.0), StandardMaterial3D#-46252 -> StandardMaterial3D#-16893 (dE 0.0), StandardMaterial3D#-16893 ->... | lab: `docs/art/lab/_army/assets/market_nature/scorecard.json` |
| 47 | 86.5 | dusk_keep | building/keep | shadow | Lab FAIL: B8 10 -> 8 materials: use one material for look-alike pairs: Obsidian -> DarkStone (dE 4.6), Stone -> DarkStone (dE 13.1) | lab: `docs/art/lab/_army/assets/dusk_keep/scorecard.json` |
| 48 | 86.8 | crown_pedestal | landmark/landmark | neutral | Lab WARN: Too many glow points read as noise: merge or dim the small ones (energy 1.5, no halo) | lab: `docs/art/lab/crown_pedestal/scorecard.json` |
| 49 | 87.1 | ice_hall | building/hall | ice | Lab FAIL: B8 14 -> 8 materials: use one material for look-alike pairs: StandardMaterial3D#-46761 -> StandardMaterial3D#-33009 (dE 0.0), ShaderMaterial#-2355 -> ShaderMaterial#-28083 (dE 8.2), ShaderMaterial#-73393 -> ShaderMateria... | lab: `docs/art/lab/_army/assets/ice_hall/scorecard.json` |
| 50 | 87.2 | briar_roc | unit/heavy | nature | Lab WARN: R10: raise UnitType.radius 0.9 -> 1.2, or pull the widest parts in to x <= 1.58 / z <= 1.58 m | lab: `docs/art/lab/briar_roc/scorecard.json` |
| 51 | 87.2 | dread_paddock | building/hall | shadow | Lab FAIL: B8 20 -> 8 materials: use one material for look-alike pairs: StandardMaterial3D#-59493 -> StandardMaterial3D#-96331 (dE 0.0), StandardMaterial3D#-96331 -> StandardMaterial3D#-63412 (dE 0.0), StandardMaterial3D#-63412 -> ... | lab: `docs/art/lab/_army/assets/dread_paddock/scorecard.json` |
| 52 | 87.3 | ice_lodge | building/hall | ice | Lab FAIL: B8 14 -> 8 materials: use one material for look-alike pairs: StandardMaterial3D#-90724 -> StandardMaterial3D#-79643 (dE 0.0), StandardMaterial3D#-79643 -> StandardMaterial3D#-73353 (dE 0.0), ShaderMaterial#-84728 -> Shad... | lab: `docs/art/lab/_army/assets/ice_lodge/scorecard.json` |
| 53 | 87.4 | glade_outrider | unit/soldier | nature | Lab FAIL: B4 11511 -> 5764 (want <= 2500): Merged 2684 -> 1342 verts; Merged 2521 -> 1261 verts; Merged 1124 -> 562 verts; Merged 885 -> 443 verts; Merged 479 -> 240 verts; Merged 406 -> 203 verts; Merged 406 -> 203 verts; Merged ... | lab: `docs/art/lab/_army/assets/glade_outrider/scorecard.json` |
| 54 | 87.7 | maelis | unit/wizard | nature | Lab WARN: shader_parameter/base_color of nature_stone #85806b -> #9f9585 (12% of the visible body): predicted dE R3 meadow 36.5 -> 36.7, R3t fire 42.4 -> 42.4, R3t shadow 49.8 -> 49.6, R3t ice 42.0 -> 42.0, R3t nature 35.8 -> 36.0... | lab: `docs/art/lab/maelis/scorecard.json` |
| 55 | 87.7 | stagrunner | unit/soldier | nature | Lab FAIL: B4 10968 -> 5490 (want <= 2500): Merged 2684 -> 1342 verts; Merged 2521 -> 1261 verts; Merged 668 -> 334 verts; Merged 579 -> 290 verts; Spear 488 -> 244 verts; Merged 448 -> 224 verts; Merged 448 -> 224 verts; Merged 44... | lab: `docs/art/lab/_army/assets/stagrunner/scorecard.json` |
| 56 | 88.3 | grove_stag | mount/mount | nature | Lab WARN: shader_parameter/base_color of grove_stag_antler #c7b085 -> #c5af85 (7% of the visible body): predicted dE R3 meadow 25.7 -> 25.7, R3t fire 31.8 -> 31.8, R3t shadow 38.9 -> 38.9, R3t ice 31.8 -> 31.8, R3t nature 25.8 -> ... | lab: `docs/art/lab/_army/assets/grove_stag/scorecard.json` |
| 57 | 88.3 | market_ice | building/hall | ice | Lab FAIL: B8 17 -> 8 materials: use one material for look-alike pairs: StandardMaterial3D#-63210 -> StandardMaterial3D#-49274 (dE 0.0), ShaderMaterial#-96435 -> ShaderMaterial#-12612 (dE 0.0), ShaderMaterial#-73286 -> ShaderMateri... | lab: `docs/art/lab/_army/assets/market_ice/scorecard.json` |
| 58 | 88.5 | barrow_giant | unit/heavy | shadow | Lab WARN: Glow points 6 -> 2 (want 1-3): barrow_soul_glow energy 3.0 -> 0.2 (dim under the bloom level: 4 point(s), peak 4.24 x the level) | lab: `docs/art/lab/_army/assets/barrow_giant/scorecard.json` |
| 59 | 88.5 | hovel | building/hall | neutral | Lab FAIL: B8 13 -> 8 materials: use one material for look-alike pairs: StandardMaterial3D#-73353 -> StandardMaterial3D#-79643 (dE 0.0), StandardMaterial3D#-65561 -> StandardMaterial3D#-79643 (dE 0.0), ShaderMaterial#-89064 -> Shad... | lab: `docs/art/lab/_army/assets/hovel/scorecard.json` |
| 60 | 88.7 | roc | beast/hero | neutral | Lab WARN: R10: raise UnitType.radius 0.9 -> 1.54, or pull the widest parts in to x <= 1.58 / z <= 2.7 m | lab: `docs/art/lab/_army/assets/roc/scorecard.json` |
| 61 | 88.7 | sprigling | unit/worker | nature | Lab WARN: R8: body_height 1.2 -> 1.97 in res://art/units/nature/sprigling.tscn (root) and res://data/units/sprigling.tres (the head top; x1.64 now), or lower the head / crest 0.47 m | lab: `docs/art/lab/_army/assets/sprigling/scorecard.json` |
| 62 | 88.9 | flame_guard | unit/soldier | fire | Lab WARN: shader_parameter/base_color of fire_bronze #9e6629 -> #c57535 (45% of the visible body): predicted dE R3 meadow 61.3 -> 64.6, R3t fire 61.2 -> 64.5, R3t shadow 77.6 -> 74.2, R3t ice 38.5 -> 42.0, R3t nature 14.0 -> 24.2,... | lab: `docs/art/lab/_army/assets/flame_guard/scorecard.json` |
| 63 | 89.0 | fire_tower | building/small | fire | Lab WARN: B8 12 -> 6 materials: use one material for look-alike pairs: StandardMaterial3D#-51813 -> StandardMaterial3D#-58204 (dE 0.0), StandardMaterial3D#-22742 -> StandardMaterial3D#-58204 (dE 0.0), ShaderMaterial#-70990 -> Shad... | lab: `docs/art/lab/fire_tower/scorecard.json` |
| 64 | 89.0 | gloam_rider | unit/cavalry | shadow | Lab FAIL: B2 19 -> 19 (want <= 12): no merge group found (every mesh has its own pivot and material): Fewer keep_separate parts, bake static props into one mesh, one MultiMesh per repeated part | lab: `docs/art/lab/_army/assets/gloam_rider/scorecard.json` |
| 65 | 89.3 | heath | decor_set/set | neutral | Lab WARN: Units drop to dE 8.0 on this decor: desaturate / darken the busiest piece | lab: `docs/art/lab/heath/scorecard.json` |
| 66 | 89.6 | cinderlock | unit/soldier | fire | Lab FAIL: B4 3725 -> 2438 (want <= 2500): Merged 1226 -> 613 verts; Merged 925 -> 463 verts; Musket 542 -> 330 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) | lab: `docs/art/lab/_army/assets/cinderlock/scorecard.json` |
| 67 | 89.9 | watchtower | building/small | neutral | Lab WARN: Glow points 0 -> 2 (want 2-4): watchtower_contact_mat emission x 3.31 (raise over the bloom level: brightest soft glow 0.39 x the level; no energy parameter found: scale its emission colour / strength); watchtower_mat em... | lab: `docs/art/lab/_army/assets/watchtower/scorecard.json` |

## B. Army-level problems seen in-game (apply to every unit listed; lab scores of those units are 88-99)

The per-unit lab scores are high, but in a real fight at the default RTS zoom (30) these whole rosters grade below 90:

| grade | group | units | what reaches 90 | evidence |
|---|---|---|---|---|
| 56 | Nature army | bloomtender, bramblehorn, briar_roc, burr_slinger, glade_outrider, greenheart_oathkeeper, stagrunner, thistle_darter, thornling, vinelasher, wildwood_archer (+ sapling, sprigling, mossback) | Green / brown bodies on green meadow and tiny team colour: next to the Ice army they vanish; I could not pick out single Nature unit types at zoom 30. Main masses to bark-brown / straw / pale moss, team colour on top-facing cloth >= 15 % of the visible body, a pale rim or cap per unit. | `shots/b_battle_ice_nature_mid.png`, `_close.png` |
| 60 | Ice army | frost_mortar, frostbow, hoarlight_magebow, rime_colossus, rime_seer, rimehorn_rider, rimeling, rimeshield, shardcaster, shardguard | All pale blue-white: types look alike, and with the white hit puffs the line is one white smear. Darker steel-blue mid-tones on armour (white only on crests / crystals), one saturated cyan accent per type, a dark base under each unit. | `shots/b_battle_ice_nature_close.png` |
| 76 | Fire army | ash_hurler, ashveil_saboteur, blaze_rider, cinder_arbalest, ember_archer, flame_guard, pyre_adept, scorchbow, scorchling (+ cinder_hand, cinderlock) | Clear orange team read, but infantry is small at 30 m and several types share the same orange-bronze mass; one distinct shape per type (tall shield, long gun, hood) and 10-15 % larger infantry. | `shots/a_battle_fire_shadow_mid.png` |
| 78 | Shadow army | barrow_ghoul, bleakbow, gloam_rider, grave_hound, hexweaver, hollow_oathsworn, nightblood_reaver, nightbolt, shade, shadow_knight | Best army read, but purple-on-black types merge into one violet mass; infantry readable only by the cavalry beside it. Lighter violet top planes / helmets and one bright rune per type. | `shots/a_battle_fire_shadow_close.png` |

## C. Not graded (no Art Lab card and not seen in these captures)

Cannot be honestly placed above or below 90; they need a lab run (`kind=vfx` / decor / stage):
- **VFX families:** cavalry_vfx, champion_vfx, champion_class_vfx, champion_mage_archer_vfx, mapfill_vfx, mapfill_beast_vfx,
  mapfill_wyrm_vfx, terrain_vfx, titan_vfx, titan_ground_vfx, trade_vfx (+ loot sack), unit_ice_rifle_vfx,
  unit_nature_t3_vfx, unit_vfx, str_int (only unit_fire_gun_vfx is scored: 100).
- **Biome decor sets:** ash, glade, marsh, meadow, old_wood, riverbank, ruins, sand, snow (only heath is scored: 89.3).
  Meadow / old wood / riverbank / Crown Isle were seen in-game and look good (84-92, see `report.md`).
- **Cinematic stage sets** (`art/cinematics/stage_sets/`): forge_citadel, forge_common, forge_ep2_feast, forge_ep3_memories
  (+ _sonnet), forge_ep4_memories (+ _sonnet), forge_evenmead, forge_hills_demo, forge_intro_malrik / torvald / vessa /
  ysolde, forge_watch_keep. Not part of the skirmish view; grade them with the Cine tool.
