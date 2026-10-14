class_name UnitResearch
extends Node
## Unit-specific research at the building that trains the unit (docs/design/unit-upgrades.md 7-15; JS 2026-10-14 "add
## unit specique upgrade to most unit and a way in the barrack to upgrade that specique unit").
## Static side: the ROWS table (55 new rows, the 12 lines moved from the Forge, the 7 bowman rows), the game rule
## (enabled_here), apply_to (modifier "research:<id>", + attack range in the runtime meta "_research_range", then
## ResearchEffects.on_applied through a load guard), the reads the unit code uses (has / param / effects_of) and the
## per-building research slot shared with the "+" (UnitUpgrades). Instance side: one node per team (groups
## "unit_research" and "saved_state") holding the done rows and the research in progress.
## Rules: pay when started, one research per building at a time (the "+" included), never blocks training, cancel =
## full refund, building destroyed = 75 % refund, permanent, applies to every living and future unit of the listed
## types. The Unit Lab never makes a node (level 0); `lab_off` turns everything off for a lab arm.

signal research_started(id: StringName)
signal research_completed(id: StringName)
signal research_cancelled(id: StringName, refund: int)

## THE switch: false = no unit research anywhere.
const ENABLED := true
const MODIFIER_PREFIX := "research:"
const RANGE_META := &"_research_range"
const SIG_META := &"_research_sig"
const SAVE_KEY_PREFIX := "unit_research_"
const SKIRMISH_SCRIPT := "res://scripts/world/skirmish.gd"
const EFFECTS_PATH := "res://scripts/units/research_effects.gd"
const DESTROYED_REFUND := 0.75

## Refusals (logic text, shown through Loc.sink). "Requires Stronghold / Citadel" come from TierSystem.gate_reason.
const REASON_UNKNOWN := "No upgrade for that unit"
const REASON_DONE := "Already researched"
const REASON_WORKING := "Already in progress"
const REASON_BUILDING := "Needs a completed building that trains it"
const REASON_NEEDS := "Needs %s"
const REASON_BUSY := "Busy with another upgrade"
const REASON_NO_CRYSTALS := "Not enough crystals"

## id -> {name, units, tier (1 = no gate), price, time, needs, text, mods (Stats keys -> modifier "research:<id>"),
## range (+ attack range), effect (H kinds, ResearchEffects), kit (K / S keys read through param()), forge (moved from
## the Forge, same id), bowman (bowmen.md 4 row, effects in BowmanKit)}. Order inside a unit = its unit-page keys.
## Shared rows (Forge lines) sit after the rows of each unit they list, so every unit's own rows come first.
const ROWS := {
	# ---------------------------------------------------------------- Fire (16 + 2 bowman)
	&"flame_guard_kindled_mail": {"name": "Kindled Mail", "units": [&"flame_guard"], "tier": 1, "price": 75,
			"time": 30.0, "needs": &"", "text": "+5 armor", "mods": {&"armor": 5.0}, "range": 0.0, "effect": {}, "kit": {}},
	&"flame_guard_backdraft": {"name": "Backdraft", "units": [&"flame_guard"], "tier": 2, "price": 125, "time": 40.0,
			"needs": &"", "text": "Melee attackers take 3 damage per hit they land on it.", "mods": {}, "range": 0.0,
			"effect": {"kind": &"thorns", "damage": 3.0}, "kit": {}},
	&"ember_archer_quick_nock": {"name": "Quick Nock", "units": [&"ember_archer"], "tier": 1, "price": 75, "time": 30.0,
			"needs": &"", "text": "-10 % attack cooldown", "mods": {&"attack_cooldown_pct": -0.10}, "range": 0.0,
			"effect": {}, "kit": {}},
	&"blaze_rider_running_start": {"name": "Running Start", "units": [&"blaze_rider"], "tier": 1, "price": 100,
			"time": 35.0, "needs": &"", "text": "The first hit on a fresh target deals +12 damage.", "mods": {},
			"range": 0.0, "effect": {"kind": &"first_hit", "damage": 12.0}, "kit": {}},
	&"ash_hurler_wheeled_mantlet": {"name": "Wheeled Mantlet", "units": [&"ash_hurler"], "tier": 1, "price": 100,
			"time": 35.0, "needs": &"", "text": "+35 % max HP", "mods": {&"max_hp_pct": 0.35}, "range": 0.0,
			"effect": {}, "kit": {}},
	&"ash_hurler_packed_shot": {"name": "Packed Shot", "units": [&"ash_hurler"], "tier": 2, "price": 150, "time": 45.0,
			"needs": &"", "text": "Each shot also hits enemy units within 1.5 m of the target for 40 % of its damage.",
			"mods": {}, "range": 0.0, "effect": {"kind": &"splash", "radius": 1.5, "ratio": 0.4}, "kit": {}},
	&"scorchbow_heavy_draw": {"name": "Heavy Draw", "units": [&"scorchbow"], "tier": 1, "price": 100, "time": 35.0,
			"needs": &"", "text": "Scorchbows +3 arrow damage (17).", "mods": {&"attack_damage": 3.0}, "range": 0.0,
			"effect": {}, "kit": {}, "bowman": true},
	&"scorchbow_pitch_arrows": {"name": "Pitch Arrows", "units": [&"scorchbow"], "tier": 1, "price": 125, "time": 45.0,
			"needs": &"scorchbow_heavy_draw",
			"text": "Scorchbow burn: 3.5 damage per second for 4 s (was 2 for 3 s). Needs Heavy Draw.", "mods": {},
			"range": 0.0, "effect": {}, "kit": {}, "bowman": true},
	&"fire_bowstrings": {"name": "Ember Bowstrings", "units": [&"ember_archer", &"scorchbow"], "tier": 2, "price": 125,
			"time": 40.0, "needs": &"", "text": "+1 attack range", "mods": {}, "range": 1.0, "effect": {}, "kit": {},
			"forge": true},
	&"fire_lances": {"name": "Lance Drill", "units": [&"blaze_rider", &"pyrehoof_lancer"], "tier": 2, "price": 125,
			"time": 40.0, "needs": &"", "text": "+10 % damage and +0.3 speed",
			"mods": {&"attack_damage_pct": 0.10, &"move_speed": 0.3}, "range": 0.0, "effect": {}, "kit": {},
			"forge": true},
	&"scorchling_volatile_core": {"name": "Volatile Core", "units": [&"scorchling"], "tier": 1, "price": 75,
			"time": 30.0, "needs": &"", "text": "Flashpoint deals 25 damage (was 15) in 2.5 m (was 2).", "mods": {},
			"range": 0.0, "effect": {}, "kit": {&"flashpoint_damage": 25.0, &"flashpoint_radius": 2.5}},
	&"pyre_adept_kindling_lore": {"name": "Kindling Lore", "units": [&"pyre_adept"], "tier": 2, "price": 125,
			"time": 40.0, "needs": &"", "text": "Flame Burst fires on 2+ enemies (was 3), radius 3 m (was 2.5).",
			"mods": {}, "range": 0.0, "effect": {}, "kit": {&"flame_burst_min_count": 2.0, &"flame_burst_radius": 3.0}},
	&"cinder_arbalest_barbed_bolts": {"name": "Barbed Bolts", "units": [&"cinder_arbalest"], "tier": 2, "price": 125,
			"time": 40.0, "needs": &"", "text": "Bolts pierce to the enemy behind for 80 % (was 50 %).", "mods": {},
			"range": 0.0, "effect": {}, "kit": {&"pierce_ratio": 0.8}},
	&"emberdart_harrier_firebrand": {"name": "Firebrand Javelins", "units": [&"emberdart_harrier"], "tier": 1,
			"price": 100, "time": 35.0, "needs": &"", "text": "Hits burn for 2 damage per second for 3 s.", "mods": {},
			"range": 0.0, "effect": {"kind": &"dot", "id": &"burn", "dps": 2.0, "seconds": 3.0}, "kit": {}},
	&"sunforge_cataphract_dawnshield": {"name": "Dawnshield", "units": [&"sunforge_cataphract"], "tier": 3,
			"price": 200, "time": 60.0, "needs": &"",
			"text": "Hit after 5 s unhurt: a 120 shield for 6 s (once per 20 s).", "mods": {}, "range": 0.0,
			"effect": {"kind": &"combat_shield", "amount": 120.0, "seconds": 6.0, "idle": 5.0, "cooldown": 20.0},
			"kit": {}},
	&"fire_caster": {"name": "Kiln Focus", "units": [&"kilnwarden"], "tier": 2, "price": 125, "time": 40.0,
			"needs": &"", "text": "+25 % max mana and mana regeneration",
			"mods": {&"max_mana_pct": 0.25, &"mana_regen_pct": 0.25}, "range": 0.0, "effect": {}, "kit": {},
			"forge": true},
	&"kilnwarden_molten_slag": {"name": "Molten Slag", "units": [&"kilnwarden"], "tier": 3, "price": 175, "time": 50.0,
			"needs": &"", "text": "Slag Rain deals 18 damage (was 12) in 3.5 m (was 3).", "mods": {}, "range": 0.0,
			"effect": {}, "kit": {&"slag_rain_damage": 18.0, &"slag_rain_radius": 3.5}},
	&"ashveil_saboteur_double_powder": {"name": "Double Powder", "units": [&"ashveil_saboteur"], "tier": 3,
			"price": 175, "time": 50.0, "needs": &"",
			"text": "Powder Charge deals 325 damage (was 250) and pauses training 14 s (was 10).", "mods": {},
			"range": 0.0, "effect": {}, "kit": {&"powder_damage": 325.0, &"powder_pause": 14.0}},
	# ---------------------------------------------------------------- Shadow (17 + 1 bowman)
	&"shade_siphoning_blades": {"name": "Siphoning Blades", "units": [&"shade"], "tier": 1, "price": 75, "time": 30.0,
			"needs": &"", "text": "15 % lifesteal", "mods": {&"lifesteal": 15.0}, "range": 0.0, "effect": {}, "kit": {}},
	&"shade_shroudcloak": {"name": "Shroudcloak", "units": [&"shade"], "tier": 2, "price": 125, "time": 40.0,
			"needs": &"", "text": "+8 % speed and +5 armor", "mods": {&"move_speed_pct": 0.08, &"armor": 5.0},
			"range": 0.0, "effect": {}, "kit": {}},
	&"nightbolt_hexed_bolts": {"name": "Hexed Bolts", "units": [&"nightbolt"], "tier": 2, "price": 125, "time": 40.0,
			"needs": &"", "text": "Hits mark the target for 2 s (it takes +15 % damage).", "mods": {}, "range": 0.0,
			"effect": {"kind": &"on_hit_status", "status": &"marked", "seconds": 2.0}, "kit": {}},
	&"bleakbow_serrated_barbs": {"name": "Serrated Barbs", "units": [&"bleakbow"], "tier": 1, "price": 100,
			"time": 40.0, "needs": &"",
			"text": "Bleed stacks up to 5 times (was 3): 7.5 damage per second at full stacks.", "mods": {},
			"range": 0.0, "effect": {}, "kit": {}, "bowman": true},
	&"shadow_bowstrings": {"name": "Nightstring", "units": [&"nightbolt", &"bleakbow"], "tier": 2, "price": 125,
			"time": 40.0, "needs": &"", "text": "+1 attack range", "mods": {}, "range": 1.0, "effect": {}, "kit": {},
			"forge": true},
	&"grave_hound_pack_hunger": {"name": "Pack Hunger", "units": [&"grave_hound"], "tier": 1, "price": 75, "time": 30.0,
			"needs": &"", "text": "+2 damage while another Grave Hound is within 5 m.", "mods": {}, "range": 0.0,
			"effect": {"kind": &"pack_aura", "radius": 5.0, "stats": {&"attack_damage": 2.0}}, "kit": {}},
	&"grave_hound_bone_fed": {"name": "Bone-Fed", "units": [&"grave_hound"], "tier": 2, "price": 125, "time": 40.0,
			"needs": &"", "text": "+25 % max HP", "mods": {&"max_hp_pct": 0.25}, "range": 0.0, "effect": {}, "kit": {}},
	&"shadow_knight_grim_reprisal": {"name": "Grim Reprisal", "units": [&"shadow_knight"], "tier": 1, "price": 100,
			"time": 35.0, "needs": &"",
			"text": "Under 50 % HP: braced for 4 s (takes 30 % less damage), once per 30 s.", "mods": {}, "range": 0.0,
			"effect": {"kind": &"low_hp_status", "pct": 0.5, "status": &"braced", "seconds": 4.0, "cooldown": 30.0},
			"kit": {}},
	&"shadow_knights": {"name": "Dread Charge", "units": [&"shadow_knight", &"barrow_knight"], "tier": 2, "price": 125,
			"time": 40.0, "needs": &"", "text": "+10 % damage and +0.3 speed",
			"mods": {&"attack_damage_pct": 0.10, &"move_speed": 0.3}, "range": 0.0, "effect": {}, "kit": {},
			"forge": true},
	&"barrow_ghoul_gorge": {"name": "Gorge", "units": [&"barrow_ghoul"], "tier": 1, "price": 75, "time": 30.0,
			"needs": &"", "text": "Grave Feast heals 50 % on a kill (was 30 %).", "mods": {}, "range": 0.0,
			"effect": {}, "kit": {&"grave_feast_heal_pct": 0.5}},
	&"hexweaver_deepening_hex": {"name": "Deepening Hex", "units": [&"hexweaver"], "tier": 2, "price": 125,
			"time": 40.0, "needs": &"", "text": "Wither Hex lasts 8 s (was 6) and slows by 1.", "mods": {}, "range": 0.0,
			"effect": {}, "kit": {&"wither_time": 8.0, &"wither_move_speed": -1.0}},
	&"hollow_oathsworn_oath_unending": {"name": "Oath Unending", "units": [&"hollow_oathsworn"], "tier": 2,
			"price": 150, "time": 45.0, "needs": &"",
			"text": "Unbroken Vow every 30 s (was 45), shield 80 (was 50).", "mods": {}, "range": 0.0, "effect": {},
			"kit": {&"vow_cd": 30.0, &"vow_shield": 80.0}},
	&"gloam_rider_nightdrinker": {"name": "Nightdrinker", "units": [&"gloam_rider"], "tier": 1, "price": 100,
			"time": 35.0, "needs": &"", "text": "20 % lifesteal", "mods": {&"lifesteal": 20.0}, "range": 0.0,
			"effect": {}, "kit": {}},
	&"duskbolt_harrier_bleeding_bolts": {"name": "Bleeding Bolts", "units": [&"duskbolt_harrier"], "tier": 1,
			"price": 100, "time": 35.0, "needs": &"", "text": "Hits bleed for 2 damage per second for 4 s.", "mods": {},
			"range": 0.0, "effect": {"kind": &"dot", "id": &"dusk_bleed", "dps": 2.0, "seconds": 4.0}, "kit": {}},
	&"veilborn_dreadrider_veil_ride": {"name": "Veil Ride", "units": [&"veilborn_dreadrider"], "tier": 3,
			"price": 200, "time": 60.0, "needs": &"",
			"text": "Under 50 % HP: shrouded for 4 s (+2 speed, takes half damage), once per 30 s.", "mods": {},
			"range": 0.0,
			"effect": {"kind": &"low_hp_status", "pct": 0.5, "status": &"shroud", "seconds": 4.0, "cooldown": 30.0},
			"kit": {}},
	&"shadow_caster": {"name": "Vigil Focus", "units": [&"gloom_deacon"], "tier": 2, "price": 125, "time": 40.0,
			"needs": &"", "text": "+25 % max mana and mana regeneration",
			"mods": {&"max_mana_pct": 0.25, &"mana_regen_pct": 0.25}, "range": 0.0, "effect": {}, "kit": {},
			"forge": true},
	&"gloom_deacon_hungering_tithe": {"name": "Hungering Tithe", "units": [&"gloom_deacon"], "tier": 3, "price": 175,
			"time": 50.0, "needs": &"", "text": "Blood Tithe heals 14 per second (was 10) and drains 7 (was 5).",
			"mods": {}, "range": 0.0, "effect": {}, "kit": {&"tithe_heal": 14.0, &"tithe_drain": 7.0}},
	&"nightblood_reaver_crimson_thirst": {"name": "Crimson Thirst", "units": [&"nightblood_reaver"], "tier": 3,
			"price": 175, "time": 50.0, "needs": &"",
			"text": "Heals 45 % of its damage (was 35 %); Blood Frenzy under 50 % HP (was 40 %).", "mods": {},
			"range": 0.0, "effect": {}, "kit": {&"reaver_lifesteal": 0.45, &"frenzy_hp_pct": 0.5}},
	# ---------------------------------------------------------------- Ice (17 + 1 bowman)
	&"rimeshield_frostrim": {"name": "Frostrim Shields", "units": [&"rimeshield"], "tier": 1, "price": 75, "time": 30.0,
			"needs": &"", "text": "Hits chill for 1 s.", "mods": {}, "range": 0.0,
			"effect": {"kind": &"on_hit_status", "status": &"chill", "seconds": 1.0}, "kit": {}},
	&"ice_shields": {"name": "Shield Wall", "units": [&"rimeshield"], "tier": 2, "price": 125, "time": 40.0,
			"needs": &"", "text": "+6 armor", "mods": {&"armor": 6.0}, "range": 0.0, "effect": {}, "kit": {},
			"forge": true},
	&"shardcaster_deep_chill": {"name": "Deep Chill", "units": [&"shardcaster"], "tier": 1, "price": 100, "time": 35.0,
			"needs": &"", "text": "Hits chill for 2.5 s (was 1.5).", "mods": {}, "range": 0.0,
			"effect": {"kind": &"on_hit_status", "status": &"chill", "seconds": 2.5}, "kit": {}},
	&"frostbow_rimed_shafts": {"name": "Rimed Shafts", "units": [&"frostbow"], "tier": 1, "price": 100, "time": 40.0,
			"needs": &"", "text": "Frostbow arrows chill for 2.5 s (was 1.5); Hamstring Shot every 8 s (was 12).",
			"mods": {}, "range": 0.0, "effect": {}, "kit": {}, "bowman": true},
	&"ice_bowstrings": {"name": "Rime Fletching", "units": [&"shardcaster", &"frostbow"], "tier": 2, "price": 125,
			"time": 40.0, "needs": &"", "text": "+1 attack range", "mods": {}, "range": 1.0, "effect": {}, "kit": {},
			"forge": true},
	&"rime_seer_thick_rime": {"name": "Thick Rime", "units": [&"rime_seer"], "tier": 1, "price": 100, "time": 35.0,
			"needs": &"", "text": "Ward shield 85 (was 60).", "mods": {}, "range": 0.0, "effect": {},
			"kit": {&"support_amount": 85.0}},
	&"rime_seer_quick_ward": {"name": "Quick Ward", "units": [&"rime_seer"], "tier": 2, "price": 125, "time": 40.0,
			"needs": &"", "text": "A ward every 9 s (was 12).", "mods": {}, "range": 0.0, "effect": {},
			"kit": {&"support_interval": 9.0}},
	&"rime_colossus_glacial_stride": {"name": "Glacial Stride", "units": [&"rime_colossus"], "tier": 1, "price": 100,
			"time": 35.0, "needs": &"", "text": "+0.6 move speed", "mods": {&"move_speed": 0.6}, "range": 0.0,
			"effect": {}, "kit": {}},
	&"rime_colossus_shatter_blow": {"name": "Shatter Blow", "units": [&"rime_colossus"], "tier": 2, "price": 150,
			"time": 45.0, "needs": &"", "text": "+20 % damage to a chilled or frozen target.", "mods": {}, "range": 0.0,
			"effect": {"kind": &"bonus_vs_status", "statuses": [&"chill", &"frozen"], "pct": 0.2}, "kit": {}},
	&"rimeling_thick_furs": {"name": "Thick Furs", "units": [&"rimeling"], "tier": 1, "price": 75, "time": 30.0,
			"needs": &"", "text": "+25 % max HP", "mods": {&"max_hp_pct": 0.25}, "range": 0.0, "effect": {}, "kit": {}},
	&"hoarlight_magebow_needle_volley": {"name": "Needle Volley", "units": [&"hoarlight_magebow"], "tier": 2,
			"price": 125, "time": 40.0, "needs": &"", "text": "Frost Needle every 6 s (was 8), 26 damage (was 20).",
			"mods": {}, "range": 0.0, "effect": {}, "kit": {&"frost_needle_cd": 6.0, &"frost_needle_damage": 26.0}},
	&"frost_mortar_wide_shells": {"name": "Wide Shells", "units": [&"frost_mortar"], "tier": 2, "price": 150,
			"time": 45.0, "needs": &"", "text": "Frost Shell radius 2.75 m (was 2).", "mods": {}, "range": 0.0,
			"effect": {}, "kit": {&"frost_shell_radius": 2.75}},
	&"snowdrift_rider_snowblind_charge": {"name": "Snowblind Charge", "units": [&"snowdrift_rider"], "tier": 1,
			"price": 100, "time": 35.0, "needs": &"",
			"text": "The first hit on a fresh target deals +10 damage and chills for 2 s.", "mods": {}, "range": 0.0,
			"effect": {"kind": &"first_hit", "damage": 10.0, "status": &"chill", "seconds": 2.0}, "kit": {}},
	&"rime_harrier_hoarfrost_tips": {"name": "Hoarfrost Tips", "units": [&"rime_harrier"], "tier": 1, "price": 100,
			"time": 35.0, "needs": &"", "text": "Hits chill for 2 s (was 1).", "mods": {}, "range": 0.0,
			"effect": {"kind": &"on_hit_status", "status": &"chill", "seconds": 2.0}, "kit": {}},
	&"frostcrown_juggernaut_glacier_heart": {"name": "Glacier Heart", "units": [&"frostcrown_juggernaut"], "tier": 3,
			"price": 200, "time": 60.0, "needs": &"", "text": "+20 % max HP and +5 armor",
			"mods": {&"max_hp_pct": 0.20, &"armor": 5.0}, "range": 0.0, "effect": {}, "kit": {}},
	&"ice_caster": {"name": "Carver's Focus", "units": [&"rimecarver"], "tier": 2, "price": 125, "time": 40.0,
			"needs": &"", "text": "+25 % max mana and mana regeneration",
			"mods": {&"max_mana_pct": 0.25, &"mana_regen_pct": 0.25}, "range": 0.0, "effect": {}, "kit": {},
			"forge": true},
	&"rimecarver_deep_bulwark": {"name": "Deep Bulwark", "units": [&"rimecarver"], "tier": 3, "price": 175,
			"time": 50.0, "needs": &"", "text": "Rime Bulwark lasts 12 s (was 8) and is 5 m long (was 4).", "mods": {},
			"range": 0.0, "effect": {}, "kit": {&"bulwark_time": 12.0, &"bulwark_length": 5.0}},
	&"shardguard_shard_ward": {"name": "Shard Ward", "units": [&"shardguard"], "tier": 3, "price": 175, "time": 50.0,
			"needs": &"", "text": "Hold the Line also shields it for 100 during 6 s.", "mods": {}, "range": 0.0,
			"effect": {}, "kit": {&"hold_line_shield": 100.0, &"hold_line_shield_time": 6.0}},
	# ---------------------------------------------------------------- Nature (17 + 3 bowman)
	&"thornling_briar_coat": {"name": "Briar Coat", "units": [&"thornling"], "tier": 1, "price": 75, "time": 30.0,
			"needs": &"", "text": "Melee attackers take 2 damage per hit they land on it.", "mods": {}, "range": 0.0,
			"effect": {"kind": &"thorns", "damage": 2.0}, "kit": {}},
	&"nature_bark": {"name": "Barkskin", "units": [&"thornling"], "tier": 2, "price": 125, "time": 40.0, "needs": &"",
			"text": "+6 armor", "mods": {&"armor": 6.0}, "range": 0.0, "effect": {}, "kit": {}, "forge": true},
	&"burr_slinger_sticky_burrs": {"name": "Sticky Burrs", "units": [&"burr_slinger"], "tier": 1, "price": 75,
			"time": 30.0, "needs": &"", "text": "Every 5th hit roots the target for 0.5 s.", "mods": {}, "range": 0.0,
			"effect": {"kind": &"every_nth", "n": 5, "status": &"rooted", "seconds": 0.5}, "kit": {}},
	&"wildwood_keen_eye": {"name": "Keen Eye", "units": [&"wildwood_archer"], "tier": 1, "price": 75, "time": 30.0,
			"needs": &"", "text": "Wildwood Archers: 15 % of arrows crit for double damage.", "mods": {}, "range": 0.0,
			"effect": {}, "kit": {}, "bowman": true},
	&"wildwood_heartseeker": {"name": "Heartseeker Points", "units": [&"wildwood_archer"], "tier": 1, "price": 100,
			"time": 40.0, "needs": &"wildwood_keen_eye", "text": "Crits: 20 % of arrows, x2.75 damage. Needs Keen Eye.",
			"mods": {}, "range": 0.0, "effect": {}, "kit": {}, "bowman": true},
	&"wildwood_hunting_party": {"name": "Hunting Party", "units": [&"wildwood_archer"], "tier": 1, "price": 200,
			"time": 60.0, "needs": &"wildwood_heartseeker",
			"text": "Every Wildwood Archer trained brings a second one for free (needs 1 free pop). Needs Heartseeker Points.",
			"mods": {}, "range": 0.0, "effect": {}, "kit": {}, "bowman": true},
	&"nature_bowstrings": {"name": "Thornstring", "units": [&"wildwood_archer", &"burr_slinger"], "tier": 2,
			"price": 125, "time": 40.0, "needs": &"", "text": "+1 attack range", "mods": {}, "range": 1.0, "effect": {},
			"kit": {}, "forge": true},
	&"bloomtender_deep_roots": {"name": "Deep Roots", "units": [&"bloomtender"], "tier": 1, "price": 75, "time": 30.0,
			"needs": &"", "text": "Heals 16 (was 12).", "mods": {}, "range": 0.0, "effect": {},
			"kit": {&"support_amount": 16.0}},
	&"bloomtender_wide_bloom": {"name": "Wide Bloom", "units": [&"bloomtender"], "tier": 2, "price": 125, "time": 40.0,
			"needs": &"", "text": "Heal range 9 m (was 7).", "mods": {}, "range": 0.0, "effect": {},
			"kit": {&"support_range": 9.0}},
	&"bramblehorn_gorehorn": {"name": "Gorehorn", "units": [&"bramblehorn"], "tier": 1, "price": 100, "time": 35.0,
			"needs": &"", "text": "The first hit on a fresh target deals +12 damage.", "mods": {}, "range": 0.0,
			"effect": {"kind": &"first_hit", "damage": 12.0}, "kit": {}},
	&"bramblehorn_mossback": {"name": "Mossback", "units": [&"bramblehorn"], "tier": 2, "price": 150, "time": 45.0,
			"needs": &"", "text": "+5 armor; out-of-combat regeneration 3 % per second (was 2 %).",
			"mods": {&"armor": 5.0}, "range": 0.0, "effect": {"kind": &"idle_regen", "pct": 0.03}, "kit": {}},
	&"thistle_darter_quickfoot": {"name": "Quickfoot", "units": [&"thistle_darter"], "tier": 1, "price": 75,
			"time": 30.0, "needs": &"", "text": "Skitter gives +1.5 speed for 2.5 s (was +1 for 1.5 s).", "mods": {},
			"range": 0.0, "effect": {}, "kit": {&"skitter_speed": 1.5, &"skitter_time": 2.5}},
	&"vinelasher_strangling_vines": {"name": "Strangling Vines", "units": [&"vinelasher"], "tier": 2, "price": 125,
			"time": 40.0, "needs": &"", "text": "Snare Lash deals 18 damage (was 10) and roots 2 s (was 1.5).",
			"mods": {}, "range": 0.0, "effect": {}, "kit": {&"snare_damage": 18.0, &"snare_root": 2.0}},
	&"greenheart_oathkeeper_heartwood_oath": {"name": "Heartwood Oath", "units": [&"greenheart_oathkeeper"], "tier": 2,
			"price": 150, "time": 45.0, "needs": &"", "text": "Grove Oath radius 6.5 m (was 5), brace 5 s (was 4).",
			"mods": {}, "range": 0.0, "effect": {}, "kit": {&"grove_oath_radius": 6.5, &"grove_oath_brace": 5.0}},
	&"stagrunner_wild_gallop": {"name": "Wild Gallop", "units": [&"stagrunner"], "tier": 1, "price": 100, "time": 35.0,
			"needs": &"", "text": "Its attack kills a unit: haste for 3 s.", "mods": {}, "range": 0.0,
			"effect": {"kind": &"kill_status", "status": &"haste", "seconds": 3.0}, "kit": {}},
	&"bramble_harrier_pollen_darts": {"name": "Pollen Darts", "units": [&"bramble_harrier"], "tier": 1, "price": 100,
			"time": 35.0, "needs": &"", "text": "Every 3rd hit hazes the target for 1.5 s.", "mods": {}, "range": 0.0,
			"effect": {"kind": &"every_nth", "n": 3, "status": &"hazed", "seconds": 1.5}, "kit": {}},
	&"glade_outrider_far_sight": {"name": "Far Sight", "units": [&"glade_outrider"], "tier": 3, "price": 200,
			"time": 60.0, "needs": &"", "text": "+2 attack range", "mods": {}, "range": 2.0, "effect": {}, "kit": {}},
	&"nature_caster": {"name": "Sage's Focus", "units": [&"bramblesage"], "tier": 2, "price": 125, "time": 40.0,
			"needs": &"", "text": "+25 % max mana and mana regeneration",
			"mods": {&"max_mana_pct": 0.25, &"mana_regen_pct": 0.25}, "range": 0.0, "effect": {}, "kit": {},
			"forge": true},
	&"bramblesage_deep_snag": {"name": "Deep Snag", "units": [&"bramblesage"], "tier": 3, "price": 175, "time": 50.0,
			"needs": &"", "text": "Snagroot drags 9 m (was 7) and roots 1.5 s (was 1); heroes unchanged.", "mods": {},
			"range": 0.0, "effect": {}, "kit": {&"snag_drag": 9.0, &"snag_root": 1.5}},
	&"briar_roc_thornstorm": {"name": "Thornstorm", "units": [&"briar_roc"], "tier": 3, "price": 200, "time": 60.0,
			"needs": &"", "text": "Seed Storm every 12 s (was 16), 40 damage (was 30).", "mods": {}, "range": 0.0,
			"effect": {}, "kit": {&"seed_storm_cd": 12.0, &"seed_storm_damage": 40.0}},
}

## Tests may set this true (research runs only in skirmish-type games otherwise).
static var force_enabled := false
## A lab arm (`ur_off`) sets it: nothing applies, nothing can be bought, param() gives the defaults.
static var lab_off := false

static var _done_by_team: Dictionary = {}   # team -> {id: true}
static var _cache: Dictionary = {}          # "team|unit_id" -> Array of done row ids touching that unit type
static var _effects_script: Script = null
static var _effects_checked := false

var team := 0
var done: Array[StringName] = []    ## Finished row ids (read only).

var _work: Array[Dictionary] = []   # {id, building, left, paid}
var _pending: Array = []
var _flush_queued := false


func _init() -> void:
	add_to_group(&"unit_research")
	add_to_group(&"saved_state")


# ---------------------------------------------------------------- static: game / table

## True in a skirmish-type game (a scene whose script inherits skirmish.gd, layout maps too); a mission only with its
## `research_enabled` knob; never Wave Strike nor the Unit Lab. Tests: force_enabled.
static func enabled_here() -> bool:
	if not ENABLED or lab_off:
		return false
	if force_enabled:
		return true
	var tree := Engine.get_main_loop() as SceneTree
	return tree != null and enabled_for(tree.current_scene)


## The rule of enabled_here for a level node (tests call it on scenes outside the tree).
static func enabled_for(scene: Node) -> bool:
	if scene == null or not ENABLED:
		return false
	if scene.has_method(&"define_objectives"):   # a mission: its research_enabled knob (MissionConfig)
		return &"research_enabled" in scene and bool(scene.get(&"research_enabled"))
	var s := scene.get_script() as Script
	while s != null:
		if s.resource_path == SKIRMISH_SCRIPT:
			return true
		s = s.get_base_script()
	return false


static func row(id: StringName) -> Dictionary:
	return ROWS.get(id, {})


## The row ids that list `unit_id`, in table order (= its unit-page keys X C V B).
static func rows_for_unit(unit_id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in ROWS:
		if ((ROWS[id] as Dictionary)["units"] as Array).has(unit_id):
			out.append(id)
	return out


## The trainable unit ids of building `b` that have at least one row (its card order).
static func unit_ids_for_building(b: Node) -> Array[StringName]:
	var out: Array[StringName] = []
	if b == null or not is_instance_valid(b) or not b.has_method(&"trainable_types"):
		return out
	for t: Variant in b.call(&"trainable_types"):
		var ut := t as UnitType
		if ut and not out.has(ut.id) and not rows_for_unit(ut.id).is_empty():
			out.append(ut.id)
	return out


## True when building `b` trains one of the units of row `id` (any team, any state).
static func building_trains(b: Node, id: StringName) -> bool:
	if not ROWS.has(id) or b == null or not is_instance_valid(b) or not b.has_method(&"trainable_types"):
		return false
	var units: Array = (ROWS[id] as Dictionary)["units"]
	for t: Variant in b.call(&"trainable_types"):
		if t is UnitType and units.has((t as UnitType).id):
			return true
	return false


## "Ember Archer, Scorchbow" (display names from the data).
static func units_text(id: StringName) -> String:
	var names: PackedStringArray = []
	for uid: StringName in row(id).get("units", []):
		var t := UnitType.find(String(uid))
		names.append(t.display_name if t else String(uid).capitalize())
	return ", ".join(names)


# ---------------------------------------------------------------- static: teams / units

## The team's node (created under the current scene when missing, `create` and research is on here).
static func for_team(for_team_id: int, create: bool = true) -> UnitResearch:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	for n in tree.get_nodes_in_group(&"unit_research"):
		var b := n as UnitResearch
		if b and b.team == for_team_id and not b.is_queued_for_deletion() and b.is_inside_tree():
			return b
	if not create or tree.current_scene == null or not enabled_here():
		return null
	var node := UnitResearch.new()
	node.name = "UnitResearch%d" % for_team_id
	node.team = for_team_id
	tree.current_scene.add_child(node)
	return node


## SaveWorld (saved_state): the team's node when the rebuilt level has not made it yet.
static func create_for_save(level: Node, key: String) -> Node:
	if not key.begins_with(SAVE_KEY_PREFIX) or not key.trim_prefix(SAVE_KEY_PREFIX).is_valid_int():
		return null
	var t := int(key.trim_prefix(SAVE_KEY_PREFIX))
	for n in level.get_tree().get_nodes_in_group(&"unit_research"):
		if n is UnitResearch and (n as UnitResearch).team == t and not n.is_queued_for_deletion():
			return n
	var node := UnitResearch.new()
	node.team = t
	node.name = "UnitResearch%d" % t
	level.add_child(node)
	return node


static func team_has(for_team_id: int, id: StringName) -> bool:
	var d: Variant = _done_by_team.get(for_team_id)
	return d != null and (d as Dictionary).has(id)


## True when `unit`'s team has row `id` done and the row lists the unit's type.
static func has(unit: Node, id: StringName) -> bool:
	var u := unit as Unit
	if u == null or not is_instance_valid(u) or u.unit_type == null or lab_off:
		return false
	return team_has(int(u.team), id) and ((ROWS.get(id, {}) as Dictionary).get("units", []) as Array).has(u.unit_type.id)


## A K / S number for `unit` (section 10 keys): the done row's value, else `default` (today's constant).
static func param(unit: Node, key: StringName, default: float) -> float:
	for id: StringName in _rows_on(unit as Unit):
		var kit: Dictionary = (ROWS[id] as Dictionary)["kit"]
		if kit.has(key):
			return float(kit[key])
	return default


## The H effect dicts ({"kind": ..., params}) of the done rows that touch `unit`.
static func effects_of(unit: Node) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: StringName in _rows_on(unit as Unit):
		var e: Dictionary = (ROWS[id] as Dictionary)["effect"]
		if not e.is_empty():
			out.append(e)
	return out


## Puts the team's done rows on `u` (idempotent): modifier "research:<id>" per M row, + attack range (meta
## "_research_range"), then ResearchEffects.on_applied(u) when that script exists. `heal_gain` false = a max-HP gain
## does not heal (a load).
static func apply_to(u: Unit, heal_gain: bool = true) -> void:
	if u == null or not is_instance_valid(u) or u.unit_type == null or int(u.team) == int(Unit.Team.NEUTRAL):
		return
	var ids := _rows_on(u)
	var sig := ",".join(PackedStringArray(ids))
	var old_sig := str(u.get_meta(SIG_META, ""))
	if ids.is_empty() and old_sig == "":
		return
	if old_sig == sig and _mods_present(u, ids):
		return
	u.set_meta(SIG_META, sig)
	for old: String in old_sig.split(",", false):   # rows taken away by a load
		if not ids.has(StringName(old)):
			u.remove_modifier(StringName(MODIFIER_PREFIX + old))
	var want_range := 0.0
	for id in ids:
		var r: Dictionary = ROWS[id]
		var mods: Dictionary = r["mods"]
		if not mods.is_empty():
			u.add_modifier(StringName(MODIFIER_PREFIX + String(id)), mods, heal_gain)
		want_range += float(r["range"])
	var have := float(u.get_meta(RANGE_META, 0.0))
	if not is_equal_approx(have, want_range):
		u.attack_range += want_range - have
		u.set_meta(RANGE_META, want_range)
	var fx := _effects()
	if fx:
		fx.call(&"on_applied", u)


## True while building `b` runs a research: a unit row or its "+" (UnitUpgrades). Stables rank-3 has its own slot.
static func building_busy(b: Node) -> bool:
	if b == null or not is_instance_valid(b):
		return false
	var t := int(b.get(&"team"))
	var bank := for_team(t, false)
	if bank and bank.working_at(b) != &"":
		return true
	var plus := UnitUpgrades.for_team(t, false)
	return plus != null and plus.working_at(b) != &""


## UI rows for unit `unit_id` at building `b`: [{id, name, text, crystals, time, state (&"ready" / &"working" /
## &"done" / &"locked"), progress 0-1, reason ("" = can buy)}], table order.
static func options_for_unit(b: Node, unit_id: StringName) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if b == null or not is_instance_valid(b):
		return out
	var t := int(b.get(&"team"))
	var bank := for_team(t, false)
	for id in rows_for_unit(unit_id):
		var r: Dictionary = ROWS[id]
		var reason := bank.can_buy(id, b) if bank else _static_reason(id, b)
		var state := &"ready"
		var progress := 0.0
		if team_has(t, id):
			state = &"done"
		elif bank and bank.is_working(id):
			state = &"working"
			progress = bank.progress(id)
		elif reason != "" and reason != REASON_NO_CRYSTALS:
			state = &"locked"
		out.append({"id": id, "name": r["name"], "text": r["text"], "crystals": int(r["price"]),
				"time": float(r["time"]), "state": state, "progress": progress, "reason": reason})
	return out


static func _static_reason(id: StringName, b: Node) -> String:
	var tmp := UnitResearch.new()
	tmp.team = int(b.get(&"team"))
	var r := tmp.can_buy(id, b)
	tmp.free()
	return r


## Done row ids that touch `u`'s type for its team (cached; cleared on any change).
static func _rows_on(u: Unit) -> Array:
	if u == null or not is_instance_valid(u) or u.unit_type == null or lab_off:
		return []
	var d: Variant = _done_by_team.get(int(u.team))
	if d == null or (d as Dictionary).is_empty():
		return []
	var key := "%d|%s" % [int(u.team), u.unit_type.id]
	if _cache.has(key):
		return _cache[key]
	var out: Array = []
	for id: StringName in ROWS:
		if (d as Dictionary).has(id) and ((ROWS[id] as Dictionary)["units"] as Array).has(u.unit_type.id):
			out.append(id)
	_cache[key] = out
	return out


static func _mods_present(u: Unit, ids: Array) -> bool:
	for id: StringName in ids:
		if not ((ROWS[id] as Dictionary)["mods"] as Dictionary).is_empty() \
				and not u.has_modifier(StringName(MODIFIER_PREFIX + String(id))):
			return false
	return true


## ResearchEffects (gameplay-coder, UR.G1 / G2) when it exists and has on_applied (load guard).
static func _effects() -> Script:
	if _effects_checked:
		return _effects_script
	_effects_checked = true
	if not ResourceLoader.exists(EFFECTS_PATH):
		return null
	var s := load(EFFECTS_PATH) as Script
	if s == null:
		return null
	for m: Dictionary in s.get_script_method_list():
		if StringName(m["name"]) == &"on_applied":
			_effects_script = s
			break
	return _effects_script


# ---------------------------------------------------------------- per team

func _enter_tree() -> void:
	_sync_static()
	if not get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.connect(_on_node_added)


func _exit_tree() -> void:
	# Another live node of the team (a load's new node entering while this one waits for deletion) keeps its rows.
	var other := false
	for n in get_tree().get_nodes_in_group(&"unit_research"):
		if n != self and n is UnitResearch and (n as UnitResearch).team == team and not n.is_queued_for_deletion():
			other = true
	if _done_by_team.has(team) and not other:
		_done_by_team.erase(team)
	_cache.clear()
	if get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.disconnect(_on_node_added)
	_pending.clear()


func _sync_static() -> void:
	var d := {}
	for id in done:
		d[id] = true
	_done_by_team[team] = d
	_cache.clear()


func save_key() -> String:
	return "%s%d" % [SAVE_KEY_PREFIX, team]


func is_done(id: StringName) -> bool:
	return done.has(id)


func is_working(id: StringName) -> bool:
	for w in _work:
		if w["id"] == id:
			return true
	return false


## 0-1 progress of `id` (0 when not in progress).
func progress(id: StringName) -> float:
	for w in _work:
		if w["id"] == id:
			return clampf(1.0 - float(w["left"]) / float((ROWS[id] as Dictionary)["time"]), 0.0, 1.0)
	return 0.0


## The row running at building `b` (&"" = none).
func working_at(b: Node) -> StringName:
	for w in _work:
		if w["building"] == b:
			return w["id"]
	return &""


## "" when row `id` can start at building `b` now, else the first reason (unknown, done, in progress, building,
## tier, needs, busy, crystals).
func can_buy(id: StringName, b: Node) -> String:
	if not ROWS.has(id) or not enabled_here():
		return REASON_UNKNOWN
	if done.has(id):
		return REASON_DONE
	if is_working(id):
		return REASON_WORKING
	if b == null or not is_instance_valid(b) or int(b.get(&"team")) != team or not b.has_method(&"is_constructed") \
			or not bool(b.call(&"is_alive")) or not bool(b.call(&"is_constructed")) or not building_trains(b, id):
		return REASON_BUILDING
	var r: Dictionary = ROWS[id]
	var gate := TierSystem.gate_reason(int(r["tier"]), team)
	if gate != "":
		return gate
	var needs: StringName = r["needs"]
	if needs != &"" and not done.has(needs):
		return REASON_NEEDS % String((ROWS[needs] as Dictionary)["name"])
	if building_busy(b):
		return REASON_BUSY
	var eco := Economy.for_team(team)
	if eco == null or not eco.can_afford(int(r["price"])):
		return REASON_NO_CRYSTALS
	return ""


## Pays and starts row `id` at building `b`. "" or the reason (a crystal refusal also flashes the top bar).
func buy(id: StringName, b: Node) -> String:
	var reason := can_buy(id, b)
	var eco := Economy.for_team(team)
	if reason == REASON_NO_CRYSTALS and eco:
		eco.spend(int((ROWS[id] as Dictionary)["price"]))   # fails on purpose: spend_failed
	if reason != "":
		return reason
	var price := int((ROWS[id] as Dictionary)["price"])
	eco.spend(price)
	_work.append({"id": id, "building": b, "left": float((ROWS[id] as Dictionary)["time"]), "paid": price})
	research_started.emit(id)
	return ""


## Stops row `id`: full refund.
func cancel(id: StringName) -> void:
	for i in range(_work.size() - 1, -1, -1):
		if _work[i]["id"] == id:
			var paid := int(_work[i]["paid"])
			var eco := Economy.for_team(team)
			if eco:
				eco.add(paid)
			_work.remove_at(i)
			research_cancelled.emit(id, paid)
			return


## Tests / cheats / campaign / old saves: finishes `id` now without paying.
func grant(id: StringName) -> void:
	if not ROWS.has(id) or done.has(id):
		return
	for i in range(_work.size() - 1, -1, -1):
		if _work[i]["id"] == id:
			_work.remove_at(i)
	_complete(id)


func _physics_process(delta: float) -> void:
	for i in range(_work.size() - 1, -1, -1):
		var w: Dictionary = _work[i]
		var b: Variant = w["building"]
		if not is_instance_valid(b) or not bool((b as Node).call(&"is_alive")):
			_work.remove_at(i)
			var refund := floori(int(w["paid"]) * DESTROYED_REFUND)
			var eco := Economy.for_team(team)
			if eco:
				eco.add(refund)
			research_cancelled.emit(w["id"], refund)
			continue
		w["left"] = float(w["left"]) - delta
		if float(w["left"]) <= 0.0:
			_work.remove_at(i)
			_complete(w["id"])


func _complete(id: StringName) -> void:
	done.append(id)
	_sync_static()
	refresh_units()
	research_completed.emit(id)


## Re-applies the done rows to every living unit of the team.
func refresh_units(heal_gain: bool = true) -> void:
	if not is_inside_tree():
		return
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and int(u.team) == team and u.is_alive():
			# A load: a unit restored at full HP (its saved HP may have been capped by the max HP without the row)
			# stays full; the others keep their HP.
			apply_to(u, heal_gain or u.hp >= u.max_hp - 0.01)


func _on_node_added(node: Node) -> void:
	if done.is_empty() or not (node is Unit):
		return
	_pending.append(node)
	if not _flush_queued:
		_flush_queued = true
		_flush.call_deferred()


func _flush() -> void:
	_flush_queued = false
	var batch := _pending
	_pending = []
	for n: Variant in batch:
		if is_instance_valid(n) and n is Unit and int((n as Unit).team) == team and (n as Unit).is_alive():
			apply_to(n as Unit)


# ---------------------------------------------------------------- save / load (saved_state)

## {done: [ids], work: [{id, building (node: saved as its id), left, paid}]}.
func save_state() -> Dictionary:
	var work: Array = []
	for w in _work:
		if is_instance_valid(w["building"]):
			work.append({"id": String(w["id"]), "building": w["building"], "left": float(w["left"]),
					"paid": int(w["paid"])})
	var ids: Array = []
	for id in done:
		ids.append(String(id))
	return {"done": ids, "work": work}


## Done rows back (already paid) and re-applied to every unit; the research in progress back on its building (one
## whose building is gone is refunded 75 % by the next tick, as in play).
func load_state(d: Dictionary, nodes: Dictionary) -> void:
	done.clear()
	for v: Variant in d.get("done", []):
		var id := StringName(str(v))
		if ROWS.has(id) and not done.has(id):
			done.append(id)
	_sync_static()
	_work.clear()
	for v: Variant in d.get("work", []):
		if not v is Dictionary:
			continue
		var w := v as Dictionary
		var id := StringName(str(w.get("id", "")))
		if not ROWS.has(id) or done.has(id):
			continue
		var b: Variant = w.get("building")
		if b is int:
			b = nodes.get(b)
		_work.append({"id": id, "building": b, "left": float(w.get("left", 0.0)),
				"paid": int(w.get("paid", (ROWS[id] as Dictionary)["price"]))})
	refresh_units(false)
