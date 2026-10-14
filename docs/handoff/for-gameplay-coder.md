# For gameplay-coder (from systems-coder, wave 1 session B)

- `Worker extends Unit` (`scripts/economy/worker.gd`) overrides `command_move`, `command_attack`,
  `command_attack_move`, `command_stop`, `die` and `_physics_process` (calling `super`), and uses `_visual`
  (carried-crystal mesh) and `attack_target`. Please keep those names, or tell systems-coder when they change.
- Optional cleanup: `UnitType.create_unit()` returns a plain `Unit` even for worker types, so `main.make_unit`
  and `Keep` build units with `Worker.make_unit(type)`. If you want `create_unit()` to return a Worker
  itself, say so and systems will switch back to it.


# From ui-coder (wave 2 session B, task 2.U1)

## Bug: `set_move_input` does nothing on a freshly spawned wizard
- A wizard whose `NavigationAgent3D` never got a `target_position` (e.g. Vessa at the start of the skirmish,
  spawned + `command_stop()`) gets `velocity_computed(Vector3.ZERO)` from avoidance while
  `_direct_velocity()` is non-zero, so W A S D do nothing until she has had one move order. `test_2_g2` does
  not see it because it gives a Fireball walk first. Repro: skirmish, `hero.set_move_input(dir)` every frame
  from the first frames: she never moves; after one `command_move` it works.
- Workaround in `scripts/ui/wizard_control.gd`: on each walk start it calls `hero.command_move(hero.global_position)`
  before `set_move_input`. Suggested fix: give the agent a target in `Unit._ready` / `command_stop`
  (`_agent.target_position = global_position`), or set it in `set_move_input`; then the UI line can go.

## Stale data
- `UnitType.card_key` (Q W E R T in `data/units/*.tres`) is no longer used by the UI: training keys are the
  slot keys Z X C V B (CLAUDE.md "Keys"). You may clear or drop the field.

# From ai-coder (wave 3 step B, task 3.A1)

## Optional: let the Commander own Malrik's casting
- Today Malrik casts by himself (`ShadowWizard._physics_process` -> `_ai_cast_with_caster`, every 0.5 s) and the
  Commander never casts, so there is exactly one caster. The Commander cannot apply the difficulty's
  `reaction_delay` to casts or start its HEAL retreat on the Shroud cast.
- Request: add `var ai_auto_cast := true` to `ShadowWizard`; when false, skip `_ai_cast_with_caster()`.
  `scripts/ai/commander.gd` already detects the property (`"ai_auto_cast" in wizard`), sets it to false and casts
  itself through `spell_caster.suggest_cast()` + `command_cast` every 0.5 s (same spells.md rules). No other change.

# From systems-coder (step 7, tasks 7.S1 / 7.S2)

## Building XP for the Ice buildings (kingdom-ice.md section 5, levels.md)
- `Unit.BUILDING_XP` (scripts/units/unit.gd, the `&"fire_keep": 200...` table) has no Ice ids yet. Please add:
  `&"ice_keep": 200, &"ice_barracks": 100, &"ice_tower": 80, &"ice_lodge": 40, &"ice_wall": 10` (essence the same).

## From tech-artist 7.V4 (Shardcaster, Rime Seer, Rime Colossus)
- Scenes: `art/units/ice/shardcaster.tscn`, `rime_seer.tscn`, `rime_colossus.tscn` (already referenced by `data/units/*.tres`).
  `kingdom_color = (0.45, 0.75, 0.95)`: call `set_team_color` with the Ice kingdom colour, no material duplicates.
  Shardcaster / Seer: `attack_windup = 0.12` (ranged). Colossus: melee (`attack_windup = 0`), its slam visual lands at 0.16 s.
- **Support autocast (7.G1, `support_caster.gd`)**: when the Rime Seer applies its shield, call
  `model.play_cast(&"support")` (staff thrust + lantern flare, 0.6 s) and start the 0.25 s beam (7.V5) at
  `model.get_beam_origin()` (world position of the lantern). Both `has_method`-guarded.

# Step 8 (8.I1, from items-coder): Blossom (Bloomcaller Staff)
- `ItemPassives.heal_multiplier(wizard) -> float` (scripts/units/item_passives.gd) returns 1.25 while the wizard
  carries a Bloomcaller Staff, else 1.0. Please multiply the wizard's **spell** heals and shields by it, after
  `spell_power_multiplier()`: Wild Bloom's heal per tick (8.G2) and Rime Aegis's `shield_at(rank)` in
  `spell_caster.gd`. Wild Bloom rank 1 = 60 x 1.25 = 75 without spell power (90 with the staff's own +20).
  Not for item actives, support autocasts or life-drain heals.

# Step 7 (M7.S2, from systems-coder): wizard level cap
- Mission 1 caps Vessa at level 5. There is no hook, so `Mission01` zeroes `hero.xp` on `xp_changed` once she is level 5. A `Wizard.level_cap: int` (default `MAX_LEVEL`) used by `add_xp` / `xp_to_next` would be cleaner; I would switch to it.



# Step 8 (8.S2, from systems-coder): wizards on either team
- Any wizard can now be the player's or the bot's. `ShadowWizard._ready` always leaves "heroes" for "enemy_heroes", and
  `Wizard._ready` always joins "heroes" (also on team ENEMY). The skirmish corrects the groups after spawn
  (`Skirmish._claim_wizard`), but please make them team-based like `IceWizard` (`if team != Team.PLAYER`) so other
  levels get it right too. The player's wizard gets `ai_auto_cast = false` (no self-casting).

# Step 8 (8.B4, from ai-coder): Thornling cost 60
- balance-2 section 5: `data/units/thornling.tres` `cost` is now **60** (was 55), `kill_xp` still 30. `tests/test_8_g1.gd`
  still expects 55 in its `&"thornling"` row (cost column). Please change it to 60.

# Step 9 (task 9.C4, from systems-coder): what the bounty board / fog / caches read from champions
- **Fog:** `FogOfWar` now also stamps nodes in group `"fog_sources"` that have `team` + `sight_radius` (skipped while
  `is_alive()` is false). A Champion without a `unit_type` gets only `DEFAULT_UNIT_SIGHT` (10 m) from `sight_of()`, so
  please `add_to_group("fog_sources")` in `Champion._ready` and expose `var sight_radius: float` (18 / 11 / 12 / 12 from
  the ChampionType). Being in both "units" and "fog_sources" is fine (the bigger circle wins).
- **Bounty payouts** call `champion.add_purse(n)` and `champion.add_xp(roundi(n / 2.0))`; messages use
  `champion.display_name`. Contributors to a Hunt are found through `Unit.damage_taken(amount, attacker)` /
  `Building.damaged(amount, attacker)`: **every champion hit (auto-attacks, projectiles, ability damage: Snare Line,
  Shield Bash, Flare Arrow, Cutpurse...) must pass the champion itself as `attacker` to `take_damage`**, or the hit does
  not count as "damaged it in the last 10 s".
- **Flare Arrow (9.C2):** `load("res://scripts/world/sight_marker.gd").spawn(team, point, 8.0, 6.0)` (guard with
  `ResourceLoader.exists`); it frees itself after 6 s.
- **Lost Caches:** a living node of group `"champions"` within 2.2 m opens one; essence goes to `add_purse`, an item to
  `champion.inventory` (`add_item`) or the ground.
# Step 9 (task 9.C1): Unit / Champion hooks for ChampionAbilities (9.C2) and the model pass (9.C10)
- Taunt: `unit.apply_status(&"taunted", 3.0, false, caster)` (4th argument `source` sets `unit.taunted_by`; your current
  `apply_status` + `set(&"taunted_by", champion)` works too), never lands on a wizard, lasts x0.5 on champions. While it lasts the unit's `attack_target` is
  forced to the source every frame (orders dropped); `unit.taunt_source()` returns it. Ends early if the source dies.
- `dazed` (no move / act, no immunity after, x0.5 on heroes), `braced` (damage taken x0.7), `marked` (x1.15) are plain
  `apply_status` ids. Bulwark rooting itself: `apply_status(&"rooted", 6.0, true)` (full_duration skips hero_mult).
- Smoke Pouch: `unit.hide_from_auto_target(3.0)` = nobody auto-aggroes it for 3 s (`is_hidden_from_auto_target()`);
  clear `attack_target` of the enemies within 6 m yourself.
- Growth: `champion.growth_mult()` = 1 + 0.08 x (level - 1) for ability damage / heals / shields.
- 9.C10: `ChampionType.model_scene` is empty in the 4 .tres; set it to `res://art/units/champions/<id>/<id>.tscn`.
  Champion already calls `set_team_color(<owner wizard's kingdom colour>)` (via `_kingdom_color()`) and
  `set_variant(variant)` on the model, `play_level_up` on level-up; the placeholder props are skipped once a model exists.

# Step 9 (task 9.V2, from tech-artist): the Oathwall model, for 9.C10
- Scene `res://art/units/champions/oathwall/oathwall.tscn` (root extends `CharacterModel`, faces +Z like every unit).
  Root exports: `body_height 2.0`, `attack_style &"slam"` (melee, `attack_windup 0`: damage at the trigger, the hammer
  hits the ground 0.12 s later), `death_style &"fall"`, `stride_speed 4.3` (its base move_speed).
- `play_cast(ability_id)`: `&"oath_of_iron"`, `&"shield_bash"`, `&"bulwark_stand"` (unknown ids play oath_of_iron).
  Bulwark: the model plants the shield and HOLDS the pose 6 s by itself; the next `play_attack` / `play_cast` /
  `play_death` or `set_moving(>= 0.3)` ends it. Nothing to call when the 6 s status ends.
- `set_variant(v)` (0 Garran, 1 Gerda) and `set_team_color(kingdom colour)` work before or after `add_child`; only the
  sash and the cape change colour; passing the Fire colour (the authored one) restores the original material.
- Extra, optional: `get_variant() -> int`, `play_fidget()` (preview helper), `authored_mesh_count() -> int` (tests).
- The door-shield is 1.2 m wide: at rest its outer edge is ~1.1 m from the centre (collision radius 0.6).

# Step 9 (task 9.V1, from tech-artist): the Wayfinder model, for 9.C10
- Scene `res://art/units/champions/wayfinder/wayfinder.tscn` (root extends `CharacterModel`, faces +Z like every unit).
  Root exports: `body_height 1.8`, `attack_style &"bow"` (ranged, `attack_windup 0.15`: spawn the arrow through the
  existing windup countdown), `death_style &"fall"`, `stride_speed 5.8` (its base move_speed).
- `play_cast(ability_id)`: `&"flare_arrow"`, `&"snare_line"`, `&"trailblaze"` (unknown ids play flare_arrow). The arrow
  leaves the bow at 0.42 s (flare_arrow), 0.26 s (snare_line), 0.34 s (trailblaze) after the call, if the VFX wants
  to line up; the body pose lasts 0.95 / 0.72 / 1.10 s.
- `set_variant(v)` (0 Tamsin, 1 Tobin) and `set_team_color(kingdom colour)` work before or after `add_child`; only the
  waist sash + tails and the back pennant change colour (the kit's cached `*_pennon` recolour).
- Extra, optional: `authored_mesh_count() -> int` (tests). No light; the lantern glow follows veterancy / haste / death.

# Step 9 (task 9.V4, from tech-artist): the Mender model, for 9.C10
- Scene `res://art/units/champions/mender/mender.tscn` (root extends `CharacterModel`, faces +Z like every unit).
  Root exports: `body_height 1.7`, `attack_style &"staff"` (ranged jab, `attack_windup 0.14`: spawn the bolt through
  the existing windup countdown), `death_style &"fall"`, `stride_speed 4.8` (its base move_speed).
- Bolt / heal origin: `get_beam_origin() -> Vector3` (world position of the censer-kettle, which hangs on a swinging
  chain; use it for the projectile spawn and for `ChampionVfx` if it wants the exact point).
- `play_cast(ability_id)`: `&"mending_draught"` (0.8 s, puff at 0.42 s), `&"soothing_circle"` (1.2 s, staff raised,
  two censer circles, puff at 0.9 s), `&"lifeline"` (0.95 s, staff thrust at the ally at 0.52 s). Unknown ids play
  mending_draught. The model does not turn toward the target: facing stays `Unit._face`.
- `set_variant(v)` (0 Orla, 1 Osric) and `set_team_color(kingdom colour)` work before or after `add_child`; only the
  waist sash (+ its dark trim) and the back pennant change colour (kit recolour, cached per colour).
- Extra, optional: `authored_mesh_count() -> int` (tests). No light. The kettle sticks out ~0.9 m from the centre on the
  weapon side at rest (collision radius 0.45): it is the "weapon", like the Oathwall's door-shield.
# Task 10.C2 (systems): Bazaar kill XP
- `Unit.BUILDING_KILL_XP` (scripts/units/unit.gd) needs the 4 Bazaar ids at **80** (levels.md victim table, market-trade.md
  4.1 / 12): `&"fire_market"`, `&"shadow_market"`, `&"ice_market"`, `&"nature_market"`. Sites keep the 25 % rule.

# Step 10 (task 10.V6, from tech-artist): the Magpie model, for 10.C10
- Scene `res://art/units/neutral/magpie/magpie.tscn` (root extends `CharacterModel`, faces +Z). Set it as
  `data/units/magpie.tres` `model_scene`. Root exports: `body_height 1.6`, `attack_style &"scissor"` (melee,
  `attack_windup 0`), `death_style &"fall"`, `stride_speed 5.2`. Neutral: `set_team_color` is a no-op (the faction has
  no kingdom colour anyway).
- **Loot**: call `set_carrying(thief.get_meta(&"loot", 0) > 0)` whenever the loot meta changes (snatch success, sack
  picked up, loot dropped). It shows the big burlap sack on the back; works before or after `add_child`.
- **Snatch**: `play_snatch()` starts the 1.5 s channel pose (the sack flies over the shoulder at ~1.1-1.36 s but is
  hidden again at the end unless `set_carrying(true)` came). `cancel_snatch()` when the channel breaks (>= 20 damage);
  `set_moving(>= 0.3)` and `play_attack()` also end it. `is_snatching() -> bool`.
- **Flee**: nothing extra: `set_status(&"shroud", true)` (the existing `_add_mark` path) plays the smoke puff + flee
  pose and turns the walk into a low sprint until `set_status(&"shroud", false)`. It returns true (skip the placeholder).
  `play_smoke_flee()` / `is_fleeing()` exist if another caller wants them.
- Death: the model hides its sack when the glows die (0.25 s): the LootSack spawned by gameplay takes over. `leave_map`
  fades it like any model (no hook needed).
# Task 10.V7 (from tech-artist): the Greywater Tracker model, for 10.C10
- Scene: `res://art/units/neutral/tracker/tracker.tscn` -> `data/units/greywater_tracker.tres` `model_scene`.
- Root exports: `body_height 1.8`, `attack_style &"crossbow"`, **`attack_windup 0.15`** (the snare bolt leaves at the
  release frame; the existing ranged windup countdown in `Unit` covers it), `death_style &"fall"`, `stride_speed 5.4`
  (= the tracker's move speed).
- Hooks: the standard CharacterModel set (`set_team_color`, `set_moving`, `play_attack`, `play_cast` (any id = an aimed
  shot, optional), `play_hit`, `play_death` + `death_finished`, `revive`, `set_status` haste / shroud); plus read-only
  `is_loaded() -> bool`. No levels / veterancy (never called is fine). `leave_map()`'s fade may set `transparency` on
  every part: tolerated.
- **Team colour (needs glue)**: `Unit._kingdom_color()` reads `unit_type.faction`; a tracker's type is neutral-ish, so
  today `set_team_color` would never be called and every tracker would show the default Fire orange band / ribbon.
  Please send the **hiring team's kingdom colour** (like `Champion.owner_kingdom()`: the team's wizard kingdom, else
  the skirmish `player_kingdom` / `enemy_kingdom`) to `set_team_color(c)` right after spawning the tracker (or give
  the tracker's Unit a `_kingdom_color()` override from its `team`). The model recolours only `tracker_pennon`
  (forearm band + hood ribbon), one cached duplicate per colour.

# Task 11.C3 (from systems-coder): the campaign companion's class, for 11.C1 (`champion.gd`)
- The campaign companion entry now carries an optional `"class"` (`CampaignState.companion_snapshot` writes it from
  `class_id()`, else `champion_class.id`; nothing before level 2). At the next mission `ChampionGuild.add_companion`
  calls `set_champion_class(id)` on the new level-1 champion (has_method guard), right after `add_child` and before
  `champion_hired` is emitted. Please make sure:
  1. `set_champion_class` works on a champion already in the tree at level 1 (the class skills stay locked until
     levels 2 / 3 / 5 through `ChampionAbilities.is_unlocked`).
  2. The level-2 draw in `add_xp` does **not** run when a class is already set (no second `class_chosen`).
  3. Like `apply_save_state`, this restore should not play the `class_chosen` VFX / HUD message (a companion walks in
     with its class; it was not "just chosen"). If `set_champion_class` itself emits `class_chosen`, an optional
     argument or a separate quiet path would be welcome; tell systems-coder the name and the guild will call it.
- `tests/test_11_c3.gd` runs these checks against the real Champion automatically once `set_champion_class` exists
  (prints SKIP until then).
# Step 11 (task 11.C1, for 11.C2 champion_abilities.gd)
- `Champion.champion_class` (ChampionClass or null): `ability_ids` (3, unlock order), `unlock_levels` [2, 3, 5],
  `unlock_level_of(id)`, `skills_unlocked_at(level)`; `Champion.class_id()`, `class_skills_unlocked()`,
  `is_ranged()`. The class weapon is already set (attack_damage / cooldown / range / projectile, Wizard bolt 26 m/s).
- Display name: `ChampionType.ability_name(&"flare_arrow")` = "Signal Flare" (+ `ability_text`); rename it in
  `ABILITIES` too (or read the type's override) so every UI shows Signal Flare.
- test_9_c2.gd line ~725: I changed `add_xp(750)` to `add_xp(940)` (level 4 on the new table); the drawn class may
  now add class skills to that champion's autocast.

# From 10.V11 (tech-artist): tracker snare effect (10.C10 hooks)
- When a Greywater Tracker's arrow applies `rooted` (its `on_hit_status`), play
  `get_tree().get_first_node_in_group(&"trade_vfx").play(&"snare", victim.global_position, victim)` (guard null).
  The rope coils follow the victim for 0.5 s and end early when `has_status(&"rooted")` is false (hero half root)
  or the victim dies. Nothing else in step 10 plays `snare` today.

# Step 10 (task 10.V5, from tech-artist): the caravan model, for 10.C10
- Scene `res://art/units/caravan/caravan.tscn` (root extends `CharacterModel`, faces +Z like every unit: the ox walks
  ahead, the wagon trails behind). Plug it as `model_scene` of `data/units/caravan.tres`.
  Root exports: `body_height 1.9`, `attack_style &"none"` (never attacks: `play_attack()` is a no-op), `attack_windup 0`,
  `death_style &"topple"` (1.0 s, `death_finished` as usual), `stride_speed 4.0` (its base move_speed; the loaded 3.6
  just plays the trot a little slower).
- `set_loaded(on: bool)`: shows / hides the rear-deck cargo (strongbox on a heap of glowing coins, crates) and lights /
  darkens the front lantern. `scripts/economy/caravan.gd` already calls it (`_model.set_loaded`); safe before `_ready`.
- `set_team_color(kingdom colour)`: canvas, rear pennant, the ox's rump blanket, the drover's scarf and hat band (kit
  recolour of `caravan_cloth`, cached per colour). The type has no kingdom, so it relies on `Unit._kingdom_color()`
  resolving faction `&""` to the owning team's kingdom (already in unit.gd). Default look = Fire orange.
- Size: ~3.3 m long (z -1.6 .. +1.8 around the unit centre, 2.2 x the 0.8 radius, within the quadruped rule), 1.9 m to
  the canvas top; the pennant pole tip and the lantern crook reach 2.25 m (HP bar at 2.4 stays clear).
- Wheels spin from the `set_moving(speed)` value (speed / 0.46 rad/s), so keep feeding the real flat speed.
- Hooks also answered: `play_hit` (the rig jolts back, the ox tosses its head), `set_status` (haste / shroud true),
  `revive()`. Extra, optional: `is_showing_cargo() -> bool`. No light; 14 draw instances, 5 materials.

# Step 11 (task 11.V1, from tech-artist): champion model weapon swap
- `CharacterModel.set_weapon_class(class_id, pop := true)` exists on every model (`Champion._send_weapon_class` already
  calls it). It also sets the model's `attack_style` and **`attack_windup`** (0.12 for the Wizard staff bolt, 0 for the
  melee classes; the archetype value comes back with `&""`). `Unit._build_model` reads `attack_windup` only once
  (`_model_windup`): please re-read it after `set_weapon_class` in `Champion._send_weapon_class`, e.g.
  `_model_windup = clampf(float(_model.get(&"attack_windup")), 0.0, MAX_ATTACK_WINDUP)`; otherwise a Wayfinder / Mender
  keeps its 0.15 / 0.14 bow / censer release in melee and a melee archetype taking the Wizard class shoots at once.
- Shot origin for the Wizard class: every model answers `get_weapon_tip() -> Variant` (world position of the class
  weapon's working end: the staff crystal; null without a class). `Champion._shot_origin()` / `ChampionAbilities` could
  prefer it over `get_beam_origin()` when `class_id() != &""` (the Mender's censer is hidden once she holds a class
  weapon; 11.V2-11.V5 may also route their own `get_beam_origin()` to it).
- The model routes `play_cast(id)` for the 12 class skill ids to its class poses; nothing to change on your side.

# Step 10 (task 10.A3, from ai-coder): a freed attack target in ChampionAbilities
- `ChampionAbilities._trigger_cutpurse` (`scripts/units/champion_abilities.gd` ~line 1468) does
  `champion.attack_target as Unit` without `is_instance_valid`: when the champion's target is freed without dying first
  (seen in `tests/test_10_a3.gd` before it switched to `leave_map()`: a Magpie freed while a Coin-Cutter attacked it) every
  autocast tick prints `Trying to cast a freed object`. Guard it like the other triggers, e.g.
  `var at: Variant = champion.attack_target` then `if at == null or not is_instance_valid(at): return []`. Low priority: in play
  Magpies / trackers leave through `leave_map()` (`is_alive()` false at once, freed 1 s later).

# Step 11 (task 11.V5, from tech-artist): the Mender's jar throw wants the cast point
- With a class weapon, the Mender's Soothing Circle throws a jar that should land on the circle's centre, and her
  Mending Draught is tossed to the ally. The model does not get the target from `play_cast(id)`. New optional hook on
  `art/units/champions/mender/mender.gd`: `set_cast_point(point: Variant) -> void` (a Vector3 or a Node3D). In
  `ChampionAbilities`, right before (or right after, same frame) `model.play_cast(&"soothing_circle")` /
  `(&"mending_draught")`, call `if model.has_method(&"set_cast_point"): model.call(&"set_cast_point", target)`.
  Without it the jar lands 5 m (circle) / 3 m (draught) straight ahead, so nothing breaks.
- `Mender.get_beam_origin()` already returns `get_weapon_tip()` while a class weapon is held (the censer is hidden then),
  so `Champion._shot_origin()` needs no change for her.

## 12.V22 Gloomcap models (tech-artist, 2026-09-26)
- `gloomcap_elder.tres` / `gloomcap_sprout.tres` (12.C4): `model_scene` = `res://art/units/neutral/gloomcap/gloomcap_elder.tscn` /
  `gloomcap_sprout.tscn`. Elder: ranged, `attack_windup` 0.12 (bolt release), `attack_style` `spore_bolt`; Sprout: melee `cap_bonk`.
- `CreatureAbilities` Spore Burst: call `model.play_cast(&"spore_burst")`; the cloud bursts from the cap at **0.46 s** (cast pose 1.1 s),
  so start `MapFillVfx.play(&"spore_burst", ...)` / apply the damage around then if you want them in sync.
- Optional: the Elder has `get_beam_origin() -> Vector3` (the glowing bulb on its staff, ~2.0 m up). `Unit._shot_origin()` uses
  3/4 of the height today; if creatures should shoot from the model, read `get_beam_origin` there like `champion.gd` does.

## 12.C10 game critters (systems-coder, 2026-09-26)
- Critters (`GameCritter`, group `"game_critters"`) must pay no champion loot (map-fill.md 3.4). `ChampionAbilities._land_cutpurse`
  calls `add_purse` whenever the empowered hit kills its target: please skip it when `target.has_method(&"is_game_critter")`.
- Cosmetic: `Projectile.launch_at_target` aims every non-Unit target at `BUILDING_AIM_HEIGHT` (1.5 m): bolts at a rabbit fly
  over it. Optional: aim at `0.4 m` when `target.has_method(&"is_game_critter")`.
## 12.V28 Roc model (tech-artist, 2026-09-26)
- `stormcrest_roc.tres` / `duskwing_roc.tres`: `model_scene` = `res://art/units/neutral/beasts/roc/roc.tscn` (one scene; EpicBeasts
  already calls `set_variant(variant)`: 0 Stormcrest, 1 Duskwing). Melee, `attack_windup` 0 (talon rake, strike frame 0.16 s).
- The model glides with its body 2.5 m above the unit origin (crest top ~3.6 m, wing tips up to ~5 m in a beat): suggest
  `body_height` 3.6 (today 3.2) so the HP bar sits above the bird, not in it.
- `CreatureAbilities`: `play_cast(&"gale_swoop" / &"shrieking_dive")` dives and hits the ground at **0.5 s** (feather burst; the
  leap motion already lands around then); `play_cast(&"updraft")` launches and climbs +2.8 m for 4 s, and stays up while
  `set_status(&"shroud", true)` (Unit already forwards statuses), then glides down. `get_beak_point() -> Vector3` for the shriek VFX.

# From tech-artist (task 13.V1b): rider model hooks for 13.C4 / 13.C7
`CharacterModel` (every unit model): `set_seated(on: bool, mount: Node3D = null)` (instant), `play_mount()` (0.3 s,
call right after `set_seated(true, mount)`), `play_dismount()` (0.3 s, then unseats itself and emits
`dismount_finished`), `play_thrown()` (0.5 s tumble, same end), `is_seated()`, `seat_mount()`, `seat_action()`;
all has_method-safe and safe before `_ready`. Put the mount model as a sibling of the rider model under the unit's
visual (same transform; its origin = the rider's). Order: riding starts -> spawn mount + `set_seated(true, mount)` +
`play_mount()`; hop-off -> `play_dismount()` and remove / puff the mount on `dismount_finished` (or after 0.3 s);
thrown -> `play_thrown()` (the mount node may be freed at once, the tumble still finishes); death while riding: just
`play_death()` (a living mount throws the rider, a dying mount carries it down); `revive()` puts it on foot. The rider
ignores `set_moving` while seated (keep calling it; drive the mount's `set_moving` with the unit speed).

## 13b.V8 Mage Archer VFX (tech-artist, 2026-09-26): calls and timings for 13b.C3 / 13b.C5
All through the one ChampionVfx node: `get_tree().get_first_node_in_group(&"champion_vfx").play(id, champion, target)`, with the
model's `play_cast(id)` at the same moment (ChampionAbilities._play_feedback already does both). Constants live in
`ChampionMageArcherVfx` (`art/vfx/champion_mage_archer_vfx.gd`).
- `sable_shaft` (target = the unit, or the aim point): the arrow leaves the bow at **0.55 s** (`SHAFT_RELEASE`, the model's heavy
  draw) and runs 16 m at 64 m/s. If you want the damage in sync, apply it at 0.55 s + distance / 64 (else instant is fine). The
  VFX picks the pierced units (first enemy + 2 behind, 1 m line) itself when it looses.
- `grave_mark` (target = the unit): the mark lands at **0.4 s**; the sigil follows the `marked` status. When the marked unit dies
  the VFX plays the soul wisp back to her by itself (no call needed for the 40 heal).
- `eclipse_volley` (target = the point): telegraph at once, waves land at **0.75 / 1.125 / 1.5 s** (`VOLLEY_WAVES`). Apply the
  3 x 22 damage at those times to match.
- `unique_call` (champion = the Mage Archer, right with `model.play_call()` when she steps out of the Lair; target = her or the
  Lair). `unique_revive` (champion = her, where she comes back, with the kit `revive()`).
- Optional `arcane_arrow` (target = the unit), once per auto-attack when the bolt is spawned: an arrow of light on the
  Projectile's path (32 m/s, arc 0.6). If used, the Projectile's own violet sphere can stay (it sits on the arrow head).

# From tech-artist (task 13.V20): CavalryVfx calls for 13.C1 / 13.C4 / 13.C7
`art/vfx/cavalry_vfx.gd` (group `"cavalry_vfx"`; reach it with `get_tree().get_first_node_in_group(&"cavalry_vfx")`,
`has_method(&"play")`, never a static type). `play(id, at, target) -> bool`; full header in the file.
- Charge hit (with `charged(unit, target)` and the mount's `play_charge()`): `play(&"charge", target, self)`. The streak
  shows at once, the ring / flash / sparks land with the model's strike frame (0.10 s). Titans get the big version.
- Lifesteal heal of a mounted unit (Gloam Rider, Nightmare Knight; `Unit._on_attack_hit` when `ls > 0` and `is_mounted()`):
  `play(&"lifesteal", target, self)` (max one per drainer per 0.25 s, 12 at once; extra calls are merged).
- MountRider: mount completes (with `rider.play_mount()` right after `set_seated(true, mount)`): `play(&"mount", unit, unit)`
  then `play(&"speed_lines", unit, unit)`; `dismount(false)` (with `play_dismount()`): `play(&"dismount", unit, unit)`;
  `dismount(true)` (with `play_thrown()`): `play(&"thrown", unit, unit)`. Remove / hide the mount model when the rider's
  `dismount_finished` fires (0.3 s hop-off, 0.5 s thrown): the puffs peak then. Speed lines stop by themselves when
  `MountRider.is_riding()` (or `Unit.is_mounted()`) turns false; `play(&"speed_lines_off", null, unit)` also works.
## From lab group C (Data Lab review, 2026-09-27)
- **Stale `card_key` on Fire units** (Data Lab K4, WARN): `data/units/flame_guard.tres` W, `cinder_hand.tres` Q,
  `ember_archer.tres` E (+ `blaze_rider` R, `ash_hurler` T). No code reads `UnitType.card_key` (slots are Z X C V B by
  index); W / Q / E are the Hero WASD walk and spell keys, so wiring it later would clash. Fix: set `card_key = ""` on
  those 5 files (or the slot letters Z X C V B), or remove the field from `UnitType` if nothing will use it (12 other
  units carry Z X C V letters that nobody reads either). Re-check: `docs/plan/data-lab.md` command, K4 PASS.

# Replay Lab determinism (lab review 2026-09-27, group B; details: docs/plan/replay-lab.md 'Determinism audit')
- **Step 2**: `projectile.gd:93` flight + hit in `_process` -> `_physics_process` (hit timing decides kills). Gameplay
  SceneTreeTimers in `unit.gd:1307`, `support_caster.gd:151` -> `create_timer(t, false, true)`.
- `champion_class.gd:152` `pick(champion, rng = null)`: the null path calls `randomize()`; use a seeded rng.
# Fix batch F3b (systems, 2026-10-12): R4-3 queue stubs after a load
- `TrainingBuilding` now saves a code-built queue stub (no `.tres`: helper Call / Revive) as `{"stub": id, "cost",
  "essence"}` and, on load, rebuilds it through the owner node: first `stub_for_save(id: StringName) -> UnitType` on
  `HelperRoster.for_team(team)` / `Stables16.for_team(team, false)` when that method exists, else
  `HelperRoster.call_type()` / `revive_type()` for `CALL_ID` / `REVIVE_ID`. Nobody rebuilds it = crystals + essence
  refunded. Optional for you: add `stub_for_save` if a stub needs more than call_type / revive_type. The roster's own
  state (`queued` / `reviving`) must come back through its saved_state row (your R2-2), or the training stub finishes
  into a roster that thinks no call is pending.

## WS3.C2 / WS4.C2 formation interface (systems-coder, 2026-10-13)
`WaveFormation` (`scripts/world/wave_strike/wave_formation.gd`, RefCounted, one per seat per horn, made by LaneSpawner).
Matches your LaneMarch side as it stands; please keep these names:
- Systems -> LaneMarch: `hold(formation)` right after `LaneMarch.attach` (spawn); `march(speed)` when the seat's last copy
  of the horn is out + `rules.muster_hold_extra` (speed = slowest living member's `move_speed`, >= `march_speed_floor`;
  `0.0` when `rules.march_lock` is false); `release(effects: Array)` on every living member, once, when the formation breaks.
- LaneMarch -> formation: `release(reason: String)` (idempotent; it calls your `release(fx)` on every member),
  `release_effects_of(unit) -> Array` ([{status, duration} | {shield, duration}] = the card's bought upgrades' `release`
  rows), `release_after` (float var = rules.march_release_after), `is_released()`, `members`, `speed`, `state`.
- The formation also times out on the director clock (`release("timeout")` after `release_after` s of march), so both
  timers agree. A loaded game never holds: lane units come back via `save_spawn_unit` without a formation.
- `tests/test_ws_formation.gd` exists with the spawn-position rows (systems); add your hold / lock / release rows there.
