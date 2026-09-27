# Tiers wave handoff (2026-09-27)

## Tier agent
- **fields added** (17:20): `UnitType.requires_tier := 1` (scripts/units/unit_type.gd) and
  `BuildingType.requires_tier := 1` (scripts/buildings/building_type.gd). Set `requires_tier = 2` (Stronghold) or
  `3` (Citadel) in your .tres files. Checks: `TrainingBuilding.can_queue` and `BuildGrid.prerequisite_reason`
  (build menu + placement) refuse with "Requires Stronghold" / "Requires Citadel".
- `TierSystem.tier_of(team) -> int` (scripts/buildings/tier_system.gd) is live; `TierSystem.gate_reason(needed, team)`
  returns the refusal text or "". No TierSystem node in the game (missions, old tests) = tier 3, nothing gated.
  `TierSystem.instance() != null` tells whether tiers exist in this game. Signal `tier_changed(team, tier)` on it;
  `Keep.tier` (1-3), `Keep.tier_changed(keep, tier)`, `Keep.can_upgrade / upgrade / cancel_upgrade / is_upgrading /
  upgrade_progress / upgrade_time_left`. `TierSystem.set_tier(team, t)` = tests / cheats.
- **T3 agent**: the keep upgrade is a stub UnitType (id `keep_upgrade`, `Keep.TIER_STUB_ID`) appended in
  `TrainingBuilding.trainable_types()` right after the keep's worker (slot 2, key X); put your `T3Kit.keep_types(...)`
  hook AFTER that block. Keep overrides `can_queue` / `queue_unit` for the stub only. The stub disappears at the
  Citadel, so your entries move up one slot then. Stub tooltip text comes from `type.get_meta("card_text")`
  (CommandCard falls back to it when a type has no description) - usable for your stubs too.
- Hall card: r3c4 **+** opens the "+" upgrades page (`UnitUpgrades.options_for(hall)` / `buy(id, hall)`), click only.
- **Art (keep tier look)**: no keep model has `set_tier(t)` yet. Code shows placeholder gold rings over the roof
  (1 ring = Stronghold, 2 = Citadel, `Keep._show_tier`). Wanted on each `art/buildings/<kingdom>_keep` model:
  `set_tier(t: int)` (1-3: e.g. banners / battlements at 2, a crown spire / glow trim at 3, readable when scouting),
  optional `play_tier_up()` and `set_upgrading(bool)` (scaffold). When `set_tier` exists the rings are skipped.
- **Art ("+" units)**: `set_plus(true)` is called (guarded by has_method) on units whose "+" is researched: a small
  detail per unit (trim, plume, rune glow). None exist yet.

## T3 agent (helpers + T3 units; switch `T3Kit.ENABLED`, scripts/units/t3_kit.gd)
- **Keep card**: `TrainingBuilding.trainable_types()` on a keep APPENDS (after the worker and anything the tier agent adds):
  the kingdom's T3 unit (`requires_tier = 3`), then `Call <helper>` / `Revive <helper>` (runtime stub UnitTypes,
  id `call_helper` / `revive_helper`). Tier agent: please add your Stronghold / Citadel upgrade entry BEFORE my hook line
  (the `T3Kit.keep_types(...)` call) so the upgrade keeps slot 2 (X).
- Hooks I add in `scripts/buildings/training_building.gd` (one line each, all `T3Kit.*`): `trainable_types`,
  `can_queue` (after the tier gate), `queue_unit` (essence), `cancel` (essence refund), `_spawn` (helper / revive).
- **Model paths for art agents** (gameplay reads `model_scene`; today each points at the placeholder wrapper; when the real
  scene is built, point the `.tres` `model_scene` at it and delete the placeholder):
  | Who | Real scene to build | Placeholder in use (base, tint) |
  |---|---|---|
  | Old Vey (helper, `data/helpers/helper_vey.tres`) | `res://art/units/helpers/helper_vey/helper_vey.tscn` | **REAL, wired** (set_charge = signature readiness) |
  | Mother Hush (helper) | `res://art/units/helpers/helper_hush/helper_hush.tscn` | **REAL, wired** (set_status(&"veiled", on)) |
  | Aldra Stillwater (helper) | `res://art/units/helpers/helper_aldra/helper_aldra.tscn` | **REAL, wired** |
  | Maelis Oakenhollow (helper) | `res://art/units/helpers/helper_maelis/helper_maelis.tscn` | **REAL, wired** |
  | Ashveil Saboteur | `res://art/units/fire/ashveil_saboteur/ashveil_saboteur.tscn` | **REAL, wired** (18:05; `play_reveal` on reveal) |
  | Nightblood Reaver | `res://art/units/shadow/nightblood_reaver/nightblood_reaver.tscn` | **REAL, wired** (`set_status(&"frenzy", on)`) |
  | Shardguard | `res://art/units/ice/shardguard/shardguard.tscn` | **REAL, wired** (`set_braced(on)` = Hold the Line ready) |
  | Briar Roc | `res://art/units/nature/briar_roc/briar_roc.tscn` | **REAL, wired** (radius 1.2) |
  | Stormbottle Genie | `res://art/units/neutral/stormbottle_genie/stormbottle_genie.tscn` | **REAL, wired** |
  | Spirit Wolf (Maelis summon) | `res://art/units/nature/spirit_wolf/spirit_wolf.tscn` | `art/units/nature/spirit_wolf/placeholder.tscn` (direwolf, spirit green) |
  Hooks gameplay calls when present: the standard Unit hooks + `play_cast(ability_id)`; helpers also `play_arrival`,
  `play_fall`, `play_revive`. 0 lights. Helper models: when one lands, change `model_scene` in `data/helpers/<id>.tres`
  (or tell the T3 agent / gameplay-coder). Stance buttons (Escort / Vanguard / Hold home) sit on the command card while
  an own helper is inspected; the Genie is the tavern window footer button "Stormbottle Genie 400".

## New-units agent (12 new units, `docs/design/new-units-12.md`)
- Done: 12 `data/units/<id>.tres`; the 8 T2 set `requires_tier = 2` (pyre_adept, cinder_arbalest, hexweaver,
  hollow_oathsworn, hoarlight_magebow, frost_mortar, vinelasher, greenheart_oathkeeper). T1: scorchling, barrow_ghoul,
  rimeling, thistle_darter. Hall slots 6-8 (keys N M ,), switch `NewUnits12.ENABLED`. Own stop-gap gate OFF (`OWN_T2_GATE`).
- Bot: `commander._pick_soldier` now skips any slot whose `can_queue` starts with "Requires" (tier-gated units never
  stall rule 5) - works for the T3 units too.
- **Model paths for the art agents** (point `model_scene` AND `model_path` of the .tres at the real scene, then delete the
  `placeholder/` folder):
  | id | current model_scene | real scene to build |
  |---|---|---|
  | scorchling | art/units/fire/scorchling/placeholder/scorchling_placeholder.tscn | art/units/fire/scorchling/scorchling.tscn |
  | pyre_adept | art/units/fire/pyre_adept/pyre_adept.tscn (REAL) | - |
  | cinder_arbalest | art/units/fire/cinder_arbalest/placeholder/cinder_arbalest_placeholder.tscn | art/units/fire/cinder_arbalest/cinder_arbalest.tscn |
  | barrow_ghoul | art/units/shadow/barrow_ghoul/placeholder/barrow_ghoul_placeholder.tscn | art/units/shadow/barrow_ghoul/barrow_ghoul.tscn |
  | hexweaver | art/units/shadow/hexweaver/hexweaver.tscn (REAL) | - |
  | hollow_oathsworn | art/units/shadow/hollow_oathsworn/placeholder/hollow_oathsworn_placeholder.tscn | art/units/shadow/hollow_oathsworn/hollow_oathsworn.tscn |
  | rimeling | art/units/ice/rimeling/placeholder/rimeling_placeholder.tscn | art/units/ice/rimeling/rimeling.tscn |
  | hoarlight_magebow | art/units/ice/hoarlight_magebow/placeholder/hoarlight_magebow_placeholder.tscn | art/units/ice/hoarlight_magebow/hoarlight_magebow.tscn |
  | frost_mortar | art/units/ice/frost_mortar/placeholder/frost_mortar_placeholder.tscn | art/units/ice/frost_mortar/frost_mortar.tscn |
  | thistle_darter | art/units/nature/thistle_darter/placeholder/thistle_darter_placeholder.tscn | art/units/nature/thistle_darter/thistle_darter.tscn |
  | vinelasher | art/units/nature/vinelasher/vinelasher.tscn (REAL) | - |
  | greenheart_oathkeeper | art/units/nature/greenheart_oathkeeper/placeholder/greenheart_oathkeeper_placeholder.tscn | art/units/nature/greenheart_oathkeeper/greenheart_oathkeeper.tscn |
  Briefs: `new-units-12.md` section 6. Hooks: kit hooks + `play_cast(spell_id)` (ability ids in `NewUnits12.ABILITY_IDS`).
  Icons `art/icons/units/<id>.png` for all 12.
## T3 art agent (3 T3 unit models; 2026-09-27 evening, Art Lab v3.1 windowed, all PASS, 0 FAIL / 0 WARN)
Real scenes are ready: point each `.tres` `model_scene` at them (the placeholder wrappers were left in place for gameplay to delete).
| Unit | Real scene | Art Lab (first -> last quality) | Scorecard |
|---|---|---|---|
| Ashveil Saboteur (fire) | `res://art/units/fire/ashveil_saboteur/ashveil_saboteur.tscn` | 89 -> **93** PASS | `docs/art/lab/ashveil_saboteur/scorecard.md` |
| Nightblood Reaver (shadow) | `res://art/units/shadow/nightblood_reaver/nightblood_reaver.tscn` | 89 -> **92** PASS | `docs/art/lab/nightblood_reaver/scorecard.md` |
| Stormbottle Genie (neutral) | `res://art/units/neutral/stormbottle_genie/stormbottle_genie.tscn` (**note: folder `stormbottle_genie/`, not `genie/`** as in the T3 table above) | 91 -> **95** PASS (tier heavy) | `docs/art/lab/stormbottle_genie/scorecard.md` |
- All three: CharacterModel kit (Saboteur extends FireModel, Reaver extends ShadowModel), palette materials only, 0 lights,
  2 glow points each at 40 m, standard hooks incl. `play_attack()` and `play_cast(spell_id)` (any id).
- Extra optional hooks (all `has_method`-guarded on the gameplay side): Saboteur `play_reveal()` (ember burst when the worker
  disguise burns away; the disguise itself = the enemy kingdom's worker scene, swapped by gameplay); Reaver
  `set_status(&"frenzy", on) -> true` (eyes + blade flare during Blood Frenzy); Genie hovers (model-only `fly_height` 0.22,
  it is not a flyer), its death = "Unbottled" (cloud sucked into the bottle, `death_finished` at 1.0 s).

## Audio agent (unit barks + unit SFX, 2026-09-27)
- **Unit voice barks**: `scripts/audio/unit_voice.gd` (`UnitVoice`, switch `ENABLED`), added by GameAudio (load-guarded).
  Lines `data/voice/lines/unit_barks.json` (select / move / attack / death per unit type), voices in
  `data/voice/cast.json` (`unit_<id>`; Shade + helpers use their story speakers), WAVs by Voice Forge. Own units only,
  1 bark / 1.5 s, bus `Voice` (GameSettings.BUS_VOICE, sent to SFX). No edits to unit.gd / selection_manager.gd.
  Bot favourites (barracks slot 0 of each kingdom's AI mix) speak another language: Flame Guard Italian (macho,
  im_nicola), Rimeshield Spanish (proud, em_alex), Nightblood Reaver (Shadow T3) Mandarin (humble, zm_yunxi; Kokoro has
  no Korean and its Japanese is broken), Thornling American (always spoiling for a fight, am_adam).
  A new unit type = add its 4 lines to unit_barks.json + a cast entry, then `run_voice_forge.ps1 build`.
- **Unit SFX**: `GameAudio.UNIT_SFX_FAMILY` (unit / helper id -> blade, heavy, whip, bow, bolt, siege, magic, storm,
  beast) plays `atk_` / `hit_` / `death_<family>` (assets/audio/unit_sfx_generator.gd) for the bowmen, the 12 new units,
  the T3 units, the helpers and summons. New unit = one line in that table.
- **Takes + sound plan (evening)**: the 27 family cues have 3 takes each (81 files, no back-to-back repeat). Every
  order added today has a cue (`docs/design/sound-plan.md`, `GameAudio.SOUND_PLAN`, 48 cues from
  `assets/audio/order_sfx_generator.gd`), all hooked from GameAudio through existing signals / public state
  (`Keep.is_upgrading` / `tier_changed`, UnitUpgrades, HelperRoster, HelperAbilities, StrIntPath, `NewUnitAbility.casts`,
  `T3Ability.casts / disguised / planting`, BowmanKit CRIT_META, SelectionManager, NextStepHint): **no gameplay edits**.
  Please keep those names (renaming one silences its cue; `tests/test_sound_plan.gd` catches the static part).
## T3 art agent 2 (Shardguard + Briar Roc; 2026-09-27 evening, Art Lab v3.1 windowed, 0 FAIL)
Real scenes are ready at the paths the T3 table expects: point `data/units/shardguard.tres` / `briar_roc.tres` `model_scene`
at them (placeholder wrappers left in place for gameplay to delete).
| Unit | Real scene | Art Lab (first -> last quality) | Scorecard |
|---|---|---|---|
| Shardguard (ice) | `res://art/units/ice/shardguard/shardguard.tscn` | 94 -> **96** PASS (tier heavy, 0 WARN) | `docs/art/lab/shardguard/scorecard.md` |
| Briar Roc (nature) | `res://art/units/nature/briar_roc/briar_roc.tscn` | 86 -> **87-90** WARN (3 kept WARNs, see below) | `docs/art/lab/briar_roc/scorecard.md` |
- Shardguard: extends IceModel (kit), palette materials only, 0 lights, 2 glow points (visor + glaive socket rune).
  Hooks: kit set + `play_attack()` (`glaive_cleave`, strike 0.24 s, reach ~2.4 m) + `play_cast(any id)` (hoist + plant,
  glass ring flash). Optional: `set_braced(on)` or `set_status(&"braced" / &"hold_the_line", on) -> true` = Hold the Line
  ready (planted stance + faint glass ring at the feet); call it when the 10 s Hold the Line cooldown is ready / used.
- Briar Roc: extends the neutral Roc (`roc.gd`, FlyerModel rig), own meshes / materials in its folder, 0 lights, 1 glow
  cluster (crest seed buds) + pod seed slits. Flyer hooks: `set_moving`, `set_turning`, `play_attack()` (talon rake with a
  1.8 m stoop), `play_cast(&"seed_storm")` (swoop; at the impact green seed sparks rain from the pod), `play_hit`,
  `play_death` + `death_finished` (1.8 s), `set_team_color` (works: leaf mantle, primaries, tail, vine leaf).
  Scene `body_height` 3.2 (= UnitType), glides `fly_height` 2.2 above its ground point, 5 m span.
  Kept WARNs: R10 footprint (5 m wingspan brief vs `radius` 0.9: the lab suggests `radius` 1.2 in `briar_roc.tres` if
  selection should cover the wings), R8w (wing tips above the HP bar line on the upbeat, inherent to the flight rig),
  R6cb (fire-coloured leaves vs meadow for deutan viewers, dE 5-6; body itself reads dE ~28).

## Helper models: Old Vey + Mother Hush (tech-artist, 2026-09-27 evening, Art Lab v3.1 windowed, 0 FAIL)
Point the helpers' `model_scene` (HelperType `helper_vey` / `helper_hush`) at the real scenes; the placeholder wrappers
in the same folders can go.
| Helper | Real scene | Art Lab (first -> last quality) | Scorecard |
|---|---|---|---|
| Old Vey (fire) | `res://art/units/helpers/helper_vey/helper_vey.tscn` | 94 -> **94** WARN (only B4 verts) | `docs/art/lab/helper_vey/scorecard.md` |
| Mother Hush (shadow) | `res://art/units/helpers/helper_hush/helper_hush.tscn` | 92 -> **94** WARN (only B4 verts) | `docs/art/lab/helper_hush/scorecard.md` |
- Both extend `art/units/helpers/helper_vey/helper_model.gd` (WizardModel, preload-only, 0 lights). Hooks (all
  `has_method`-safe): kit set + `play_attack()` (Vey `sword_slash`, Hush `dual_slash`), `play_cast(id)` with the ability ids
  of t3-helpers.md 4.2 / 4.3 (`vey_lunge`, `vey_chain`, `vey_stormcall`, `vey_storm_sworn`; `hush_blink`, `hush_smoke`,
  `hush_knives` (3.0 s: vanish 1.5 s + 6 strikes), `hush_veil`), `play_arrival()` (1.5 s), `play_fall()`, `play_revive()`,
  `set_charge(0..1)`, `play_gesture(id)` (point, nod, kneel (held until stand_up), stand_up, raise_weapon / raise_sword, bow,
  shrug, push, turn_head_left / right, offer_hand, draw_knives), `set_expression(&"neutral" | &"smile" | &"fierce")`
  (painted face / mask), `set_status(&"veiled" or &"shroud", on) -> true` (Hush's smoke trail thins).
- Vey: every 3rd strike the blade crackles by itself (Storm-Sworn tell). Hush death style = sink (into her smoke).
## Tech-artist (medium): 5 new-units-12 models built (2026-09-27 evening, Art Lab v3.1 windowed, 0 FAIL)
Real scenes are at the paths the new-units table expects. **Data owner: repoint `model_scene` (ext_resource path) AND
`model_path` in these `.tres`, then delete that unit's `placeholder/` folder** (art agents do not write `data/`):
| Unit (`data/units/<id>.tres`) | Real scene | Art Lab first -> last | Icon (64 px) |
|---|---|---|---|
| rimeling | `res://art/units/ice/rimeling/rimeling.tscn` | 95 -> **95** PASS | `art/icons/units/rimeling.png` |
| hoarlight_magebow | `res://art/units/ice/hoarlight_magebow/hoarlight_magebow.tscn` | 94 FAIL (verts) -> **94** PASS | `art/icons/units/hoarlight_magebow.png` |
| frost_mortar | `res://art/units/ice/frost_mortar/frost_mortar.tscn` | 95 -> **95** PASS (tier heavy) | `art/icons/units/frost_mortar.png` |
| thistle_darter | `res://art/units/nature/thistle_darter/thistle_darter.tscn` | 91 FAIL (verts) -> **93** PASS | `art/icons/units/thistle_darter.png` |
| greenheart_oathkeeper | `res://art/units/nature/greenheart_oathkeeper/greenheart_oathkeeper.tscn` | 91 WARN -> **93** WARN (tier heavy; R4 heath dE 6.4) | `art/icons/units/greenheart_oathkeeper.png` |
- Kit models (IceModel / NatureWarModel), palette materials only, 0 lights, 1-2 glow points, all kit hooks + `play_cast(<any id>)`
  (frostbite / frost_needle / frost_shell / skitter / grove_oath poses). Magebow also `get_bow_tip_position()`. Model-side
  attack styles `light_draw` / `mortar_fire` / `blow_dart` fire the `release` event at `attack_windup` (0.15 / 0.15 / 0.14 s).
- Scorecards `docs/art/lab/<id>/`; 256 px Lens icons in `art/icons/lens/units/`.

## Helper art agent: Aldra + Maelis (2026-09-27 evening, Art Lab v3.1 windowed, 0 FAIL)
Real scenes ready: point `model_scene` of the helper data at them (Aldra's placeholder wrapper is left in place for gameplay to delete).
| Helper | Real scene | Art Lab (first -> last quality) | Scorecard |
|---|---|---|---|
| Aldra Stillwater (ice) | `res://art/units/helpers/helper_aldra/helper_aldra.tscn` | 95 (headless) / 91 (first windowed) -> **95** WARN (B4 only) | `docs/art/lab/aldra/scorecard.md` |
| Maelis Oakenhollow (nature) | `res://art/units/helpers/helper_maelis/helper_maelis.tscn` (replaces the champion `wildcaller.tscn` used as is) | 88 -> **88** WARN | `docs/art/lab/maelis/scorecard.md` |
- Hooks (all safe before `_ready`, `has_method`-guarded): kit hooks + `play_attack()`, `play_cast(ability_id)` (Aldra: `aldra_shatter`,
  `aldra_aegis`, `aldra_sentinel`, `aldra_ward`; Maelis: `thornsnare`, `call_the_pack`, `wild_stampede`, `maelis_opinions`),
  `play_arrival()` (3.5 s), `play_fall()` (= kit fall, `death_finished` at 1.0 s), `play_revive()`, `set_charge(0..1)`,
  `play_gesture(id)` + `point()` / `nod()` / `kneel()` (held) / `stand_up()` / `raise_weapon()`, `set_expression(&"neutral"|&"smile"|&"fierce")`;
  Aldra `get_crystal_origin()`, Maelis `get_beam_origin()` / `get_staff_foot()`. 0 lights.
- Check: `art/units/helpers/helper_aldra/tools/helper_hooks_check.gd` (headless, PASS helper_models); pose sheets
  `docs/art/lab/helper_poses/{aldra,maelis}_poses.png`.
