class_name CampaignState
extends RefCounted
## Campaign progress between missions (docs/design/mission-01.md "Reward carried to mission 2",
## docs/design/items.md "Campaign"). One JSON file, `user://campaign.json`:
##   { "version": 1,
##     "unlocked": ["m01", "m02"],          # mission ids the menu may start
##     "completed": ["m01"],
##     "flags": {"m1_peddler_freed": true, "m1_outpost_burned": false, "e3m2_alarms": 2},   # bools, or int counters
##     "items": { CampaignItems.snapshot(): slots, artifacts_owned, artifacts_equipped, essence },
##     "companion": {"id": "coin_cutter", "variant": 1, "items": [{"id", "count"} or null x 4], "purse": 150,
##                   "class": "two_hand"} }               # {} = none (docs/design/champions.md 11); "class" only
##                                                        # when it had one (skills-rework.md 8; old saves: none)
## Usage:
##   var cs := CampaignState.open()                       # load (or a fresh campaign)
##   cs.on_mission_victory(&"m01", mission_node)          # saves at once
##   cs.companion_candidates(mission_node)                # the choice screen: champions hired in the mission
##   cs.choose_companion(champion_or_null)                # saves at once
##   cs.apply_to_start(next_mission_node)                 # after the next mission's hero exists (also
##                                                        # spawns the companion if the mission has taverns)
## `level_node` gives the player's wizard through its `hero` property (main.gd), else the first node in
## group "heroes" of team PLAYER. Objective states come from `level_node.objective_state(id) -> String`,
## else a Dictionary `objective_states` / `objectives` (property or meta), values "done" or {state: "done"}.
## Never call the global `load()` in this script: the method below shadows it (use ResourceLoader).

const VERSION := 1
const SAVE_PATH := "user://campaign.json"
const BACKUP_SUFFIX := ".bak"        ## The previous save (save() keeps it; load() falls back to it).
const TMP_SUFFIX := ".tmp"           ## save() writes here first, then renames.
const CORRUPT_SUFFIX := ".corrupt"   ## A copy of an unreadable save (never silently lost).
## Meta on the level node: carried essence held back by no-economy mode (MissionBase.grant_carried_essence adds it).
const META_CARRIED_ESSENCE := &"carried_essence"
const PLAYER_TEAM := 0   # Unit.Team.PLAYER
const FIRST_MISSION := &"m01"
## The episode's opening mission (mission-00.md: the new prologue M0 plays before mission 1 on a new campaign).
const OPENING_MISSION := &"m00"
## Unlocked on a new campaign (mission-00.md "Reward": m00 and m01 both unlocked by default).
const START_UNLOCKED: Array[StringName] = [&"m00", &"m01"]
## Champion companion (docs/design/champions.md 11).
const COMPANION_SLOTS := 4
const COMPANION_PURSE_RATIO := 0.5
const COMPANION_PURSE_CAP := 300
const COMPANION_OFFSET := Vector3(2.0, 0.0, 2.0)   ## Beside the wizard at the mission start.
## Mission order and scenes. A mission whose scene does not exist yet is unlocked but not playable.
const MISSION_ORDER: Array[StringName] = [&"m00", &"m01", &"m02", &"m03", &"m04", &"e2m1", &"e2m2", &"e2m3", &"e2m4", &"e2m5",
		&"e3m1", &"e3m2", &"e3m3", &"e3m4", &"e4m1", &"e4m2", &"e4m3", &"e4m4", &"e5m1", &"e5m2", &"e5m3", &"e5m4",
		&"e6m1", &"e6m2", &"e6m3", &"e6m4", &"e7m1", &"e7m2", &"e7m3", &"e7m4", &"e8m1", &"e8m1_fire", &"e8m1_shadow",
		&"e8m1_ice", &"e8m1_nature", &"e8m2", &"e8m3"]
const MISSION_SCENES := {
	&"m00": "res://missions/mission_00.tscn",
	&"m01": "res://missions/mission_01.tscn",
	&"m02": "res://missions/mission_02.tscn",
	&"m03": "res://missions/mission_03.tscn",
	&"m04": "res://missions/mission_04.tscn",
	&"e2m1": "res://missions/mission_e2_01.tscn",
	&"e2m2": "res://missions/mission_e2_02.tscn",
	&"e2m3": "res://missions/mission_e2_03.tscn",
	&"e2m4": "res://missions/mission_e2_04.tscn",
	&"e2m5": "res://missions/mission_e2_05.tscn",
	&"e3m1": "res://missions/mission_e3_01.tscn",
	&"e3m2": "res://missions/mission_e3_02.tscn",
	&"e3m3": "res://missions/mission_e3_03.tscn",
	&"e3m4": "res://missions/mission_e3_04.tscn",
	&"e4m1": "res://missions/mission_e4_01.tscn",
	&"e4m2": "res://missions/mission_e4_02.tscn",
	&"e4m3": "res://missions/mission_e4_03.tscn",
	&"e4m4": "res://missions/mission_e4_04.tscn",
	&"e5m1": "res://missions/mission_e5_01.tscn",
	&"e5m2": "res://missions/mission_e5_02.tscn",
	&"e5m3": "res://missions/mission_e5_03.tscn",
	&"e5m4": "res://missions/mission_e5_04.tscn",
	&"e6m1": "res://missions/mission_e6_01.tscn",
	&"e6m2": "res://missions/mission_e6_02.tscn",
	&"e6m3": "res://missions/mission_e6_03.tscn",
	&"e6m4": "res://missions/mission_e6_04.tscn",
	&"e7m1": "res://missions/mission_e7_01.tscn",
	&"e7m2": "res://missions/mission_e7_02.tscn",
	&"e7m3": "res://missions/mission_e7_03.tscn",
	&"e7m4": "res://missions/mission_e7_04.tscn",
	&"e8m1": "res://missions/e8_road_choice.tscn",       # mission-e8-01.md: the road picker (outline 4.1)
	&"e8m1_fire": "res://missions/mission_e8_01_fire.tscn",
	&"e8m1_shadow": "res://missions/mission_e8_01_shadow.tscn",
	&"e8m1_ice": "res://missions/mission_e8_01_ice.tscn",
	&"e8m1_nature": "res://missions/mission_e8_01_nature.tscn",
	&"e8m2": "res://missions/mission_e8_02.tscn",
	&"e8m3": "res://missions/mission_e8_03.tscn",
}
## Story films a reward's "next" may name (StoryFilms plays them): film id -> what follows it (a film or a mission).
## The victory unlocks the first mission at the end of the chain (film_target).
const STORY_FILMS := {
	&"c1_offer": &"m02",            # story-episode-1.md 7.2: "The Offer" after m01, before m02's briefing
	&"c2_two_fronts": &"m03",       # story-episode-1.md 7.2: "One Front, Two Watchers" after m02 (no Pell branch yet)
	&"c3_parley": &"m04",           # story-episode-1.md 7.2: "The Parley" after m03 (no companion branch yet)
	&"c_e2_ashes": &"e2m2",          # mission-e2-01.md: "What the Frost Kept" after e2m1, before e2m2's briefing
	&"c_e2_lodge": &"e2m3",          # mission-e2-02.md: "The Price of the Road" after e2m2, before e2m3's briefing
	&"c_e2_stair": &"e2m4",          # mission-e2-03.md: "On the Way Down" after e2m3, before e2m4's briefing
	&"ep2_ending": &"ep3_opening",   # mission-e2-05.md: "All Four, or None", then the Ep3 card
	&"ep3_opening": &"e3m1",         # mission-e3-01.md E1: the opening plays before the briefing
	&"c_e3_knife": &"e3m2",          # mission-e3-02.md: "The Bishop's Knife" after e3m1, before e3m2's briefing
	&"c_e3_price": &"e3m3",          # mission-e3-02.md: "The Stone's First Price" after e3m2, before e3m3's briefing
	&"c_e3_doubt": &"e3m4",          # mission-e3-03.md: "Torvald's Doubt" after e3m3, before e3m4's briefing
	&"ep3_ending": &"ep4_opening",   # mission-e3-04.md: "I Will Not Stop" after e3m4, then the Ep4 card
	&"ep4_opening": &"e4m1",         # mission-e4-01.md E1: the opening plays before the briefing
	&"c_e4_refuge": &"e4m2",         # mission-e4-01.md: "What the Tree Saw" after e4m1, before e4m2's briefing
	&"c_e4_turnback": &"e4m3",       # mission-e4-02.md: "The Way Back" after e4m2, before e4m3's briefing
	&"c_e4_frontier": &"e4m4",       # mission-e4-03.md: "The Wall" after e4m3, before e4m4's briefing
	&"ep4_ending": &"ep5_opening",   # mission-e4-04.md: "Winter's End", then the Ep5 card
	&"ep5_opening": &"e5m1",         # mission-e5-01.md F8: "The Spark and the Candle" plays before e5m1's briefing
	&"c_e5_turn": &"e5m3",           # mission-e5-03.md E0: "By One Candle" after e5m2, before e5m3's briefing
	&"ep5_ending": &"ep6_opening",   # mission-e5-04.md D9: "No Problem at All", then the Ep6 card
	&"ep6_opening": &"e6m1",         # mission-e6-01.md: "Patience and Heart" plays before e6m1's briefing
	&"c_e6_lake": &"e6m2",           # mission-e6-01.md: "The Ice Has Stopped Singing" after e6m1, before e6m2's briefing
	&"c_e6_gate": &"e6m3",           # mission-e6-02.md: the gate film after e6m2 (open branch; FILM_BRANCHES picks the shut cut)
	&"c_e6_gate_shut": &"e6m3",      # mission-e6-02.md: the shut branch's cut of c_e6_gate
	&"c_e6_seed": &"e6m4",           # mission-e6-03.md: after e6m3, before e6m4's briefing
	&"ep6_ending": &"ep7_opening",   # mission-e6-04.md: the night the Master went down, then the Ep7 card
	&"ep7_opening": &"e7m1",         # mission-e7-01.md: "Gold for Fire" plays before e7m1's briefing
	&"c_e7_ledger": &"e7m2",         # mission-e7-01.md: "Clean Coin" after e7m1, before e7m2's briefing
	&"c_e7_mask": &"e7m3",           # mission-e7-02.md: "Mourning" after e7m2, before e7m3's briefing
	&"c_e7_pits": &"e7m4",           # mission-e7-03.md: "The Year Comes Round" (people cut; FILM_BRANCHES picks the pits cut)
	&"c_e7_pits_pits": &"e7m4",      # mission-e7-03.md: the pits cut of c_e7_pits (Ossavar leaves)
	&"ep7_ending": &"ep8_opening",   # mission-e7-04.md: "No. Not for Now.", then the Ep8 card
	&"ep8_opening": &"e8m1",         # outline 4.1: "The Four Keys", then the road picker (e8m1 = its screen)
	&"c_e8_muster": &"e8m2",         # mission-e8-02.md: "Especially Malrik" after the road, before e8m2's briefing
	&"ep8_ending_a": &"ep8_throne_vessa",   # mission-e8-03.md 8.2: the last turn; FILM_BRANCHES picks the throne shot
	&"ep8_throne_vessa": &"ep8_choice",
	&"ep8_throne_malrik": &"ep8_choice",
	&"ep8_throne_torvald": &"ep8_choice",
	&"ep8_throne_ysolde": &"ep8_choice",
	&"ep8_ending_b": &"ep8_bookend",       # canon (Break the throne); FILM_BRANCHES picks ep8_dark_<k> on Take the seat
	&"ep8_dark_fire": &"ep8_bookend",
	&"ep8_dark_shadow": &"ep8_bookend",
	&"ep8_dark_ice": &"ep8_bookend",
	&"ep8_dark_nature": &"ep8_bookend",
	&"ep8_bookend": &"ep8_credits",        # FILM_BRANCHES picks ep8_bookend_dark on Take the seat
	&"ep8_bookend_dark": &"ep8_credits",
}
## Story screens a film chain may reach (not missions, never unlocked): id -> scene. The ending's choice card writes
## `ep8_choice` and goes on with ep8_ending_b; the credits end on the main menu.
const STORY_SCREENS := {
	&"ep8_choice": "res://missions/ep8_choice.tscn",
	&"ep8_credits": "res://missions/ep8_credits.tscn",
}
## Films picked by campaign flags (mission-e6-02.md D4 / D5): film id -> [flag, value, the film played instead], or a
## list of rows [{flag: value, ...}, film] (every flag must match; the first matching row wins). A chain that reaches
## the key film plays the other one; no match (or a flag missing from the save) keeps the key film.
const FILM_BRANCHES := {
	&"c_e6_gate": ["e6m2_gate_opened", false, &"c_e6_gate_shut"],
	&"c_e7_pits": ["e7m3_people", false, &"c_e7_pits_pits"],   # mission-e7-03.md: the Outwall was not sheltered
	# mission-e8-03.md 8.2: e8_road = 0 fire / 1 shadow / 2 ice / 3 nature; ep8_choice = 1 break / 2 take.
	&"ep8_throne_vessa": [[{"e8_road": 1}, &"ep8_throne_malrik"], [{"e8_road": 2}, &"ep8_throne_torvald"],
			[{"e8_road": 3}, &"ep8_throne_ysolde"]],
	&"ep8_ending_b": [[{"ep8_choice": 2, "e8_road": 0}, &"ep8_dark_fire"], [{"ep8_choice": 2, "e8_road": 1}, &"ep8_dark_shadow"],
			[{"ep8_choice": 2, "e8_road": 2}, &"ep8_dark_ice"], [{"ep8_choice": 2, "e8_road": 3}, &"ep8_dark_nature"],
			[{"ep8_choice": 2}, &"ep8_dark_fire"]],
	&"ep8_bookend": [[{"ep8_choice": 2}, &"ep8_bookend_dark"]],
}
## The ending choice (mission-e8-03.md 8.2): the `ep8_choice` values.
const CHOICE_BREAK := 1
const CHOICE_TAKE := 2
## Malrik's track (campaign-outline D8; per-wizard item tracks are not built): Ep3 victories are flags-only
## ("save_items": false, Vessa's items untouched) and carry Malrik's essence (50 %, cap 1 500) in this int flag.
const MALRIK_ESSENCE_FLAG := "malrik_essence"
## Ysolde's track (Episode 4, the same rule): flags only, her essence (50 %, cap 1 500) in this int flag.
const YSOLDE_ESSENCE_FLAG := "ysolde_essence"
## Torvald's track (Episode 7, the same rule): flags only, his essence (50 %, cap 1 500) in this int flag.
const TORVALD_ESSENCE_FLAG := "torvald_essence"
## What each victory gives: an artifact (owned, equipped in slot 1 by default), flags set from
## objectives ("flag": "objective id"), essence added before the 50 % cut per done objective, next mission.
## Optional keys (docs/design/mission-framework.md): "set_flags" (constant values), "items" (extra owned artifacts),
## "unlock" (more mission ids), "save_items" (false = flags only). A mission missing here falls back to its
## MissionConfig.rewards (reward_of); its computed flags / track counters come from mission_flags() / mission_flag_adds().
const MISSION_REWARDS := {
	# docs/design/mission-00.md "Reward carried to mission 1": flags only (nothing carried, the save's items untouched).
	&"m00": {
		"flags": {"m0_hush_driven": "sec_hush", "m0_escort_saved": "sec_guards"},
		"next": &"m01",
		"save_items": false,
	},
	&"m01": {
		"artifact": "ember_crown",
		"flags": {"m1_peddler_freed": "sec_peddler", "m1_outpost_burned": "sec_outpost"},
		"bonus_essence": {"sec_outpost": 300},
		"next": &"c1_offer",   # film c1_offer -> m02 (unlocks m02, as before)
	},
	# docs/design/mission-02.md "Reward carried to mission 3".
	&"m02": {
		"artifact": "stillwater_orb",
		"flags": {"m2_emberguard_sworn": "sec_emberguard", "m2_dig_under_half": "sec_dig"},
		"bonus_essence": {"sec_dig": 300},
		"next": &"c2_two_fronts",   # film c2_two_fronts -> m03 (unlocks m03, as before)
	},
	# docs/design/mission-03.md "Reward carried to mission 4" (m3_hired: M4 knows whether a companion can exist).
	&"m03": {
		"artifact": "masters_signet",
		"flags": {"m3_mossjaw_slain": "sec_mossjaw", "m3_stakes_held": "sec_stakes", "m3_hired": "sec_champion"},
		"bonus_essence": {"sec_stakes": 300, "sec_mossjaw": 150},
		"next": &"c3_parley",   # film c3_parley -> m04 (unlocks m04, as before)
	},
	# docs/design/mission-04.md "Rewards / Episode 2 carry-over" (m4_malrik_pylons is a mission-computed flag).
	&"m04": {
		"flags": {"m4_seat_taken": "sec_seat", "m4_hall_burned": "sec_hall"},
		"bonus_essence": {"sec_seat": 300, "sec_hall": 300},
		"set_flags": {"ep1_complete": true, "ep1_vey_returned": true, "ep1_shard_to_malrik": true},
		"next": &"e2m1",
	},
	# docs/design/mission-e2-01.md "Reward carried to e2m2" (helper_vey_unlocked always set).
	&"e2m1": {
		"flags": {"e2m1_folk_saved": "sec_folk", "e2m1_frosthall_shattered": "sec_frosthall",
				"e2m1_vey_called": "sec_storm"},
		"bonus_essence": {"sec_folk": 300, "sec_frosthall": 150},
		"set_flags": {"helper_vey_unlocked": true},
		"next": &"c_e2_ashes",   # film c_e2_ashes -> e2m2 (unlocks e2m2, as before)
	},
	# docs/design/mission-e2-02.md "Reward carried to e2m3".
	&"e2m2": {
		"flags": {"e2m2_carriers_kept": "sec_carriers", "e2m2_points_held": "sec_points"},
		"bonus_essence": {"sec_carriers": 300, "sec_points": 150},
		"set_flags": {"ep2_nature_allied": true},
		"next": &"c_e2_lodge",   # film c_e2_lodge -> e2m3 (unlocks e2m3, as before)
	},
	# docs/design/mission-e2-03.md "Reward carried to e2m4" (gold is never carried).
	&"e2m3": {
		"flags": {"e2m3_magpies_hunted": "sec_magpies", "e2m3_malrik_robbed": "sec_raid", "e2m3_toll_broken": "sec_toll"},
		"bonus_essence": {"sec_magpies": 150, "sec_raid": 300, "sec_toll": 150},
		"set_flags": {"e2m3_lodge_paid": true},
		"next": &"c_e2_stair",   # film c_e2_stair -> e2m4 (unlocks e2m4, as before)
	},
	# docs/design/mission-e2-04.md "Reward carried to e2m5" (research is never carried).
	&"e2m4": {
		"flags": {"e2m4_sunwardens": "sec_wardens", "e2m4_hush_driven": "sec_hush", "e2m4_road_lit": "sec_sunstones"},
		"bonus_essence": {"sec_wardens": 300, "sec_hush": 150, "sec_sunstones": 150},
		"set_flags": {"e2m4_gate_open": true},
		"next": &"e2m5",
	},
	# docs/design/mission-e2-05.md "Reward and the Episode 2 carry-over" (the Fire titan for Vessa's track).
	&"e2m5": {
		"flags": {"e2m5_seals_kindled": "sec_seals", "e2m5_door_bright": "sec_door", "e2m5_dragon_raised": "sec_dragon"},
		"bonus_essence": {"sec_seals": 300, "sec_door": 300, "sec_dragon": 150},
		"set_flags": {"ep2_complete": true, "ep2_door_held": true, "fire_titans_unlocked": true, "ep2_torvald_doubts": true},
		"next": &"ep2_ending",
	},
	# Episode 3 (Malrik's track: flags only, his essence in MALRIK_ESSENCE_FLAG, written by the mission).
	# docs/design/mission-e3-01.md "Reward carried to e3m2" (e3m1_time / e3m1_standard_toppled are mission-computed).
	&"e3m1": {
		"flags": {"e3m1_horns_silenced": "sec_horns", "e3m1_vessa_driven": "sec_vessa"},
		"set_flags": {"ep3_started": true},
		"next": &"c_e3_knife",   # film c_e3_knife -> e3m2 (unlocks e3m2, as before)
		"save_items": false,
	},
	# docs/design/mission-e3-02.md "Reward carried to e3m3" (e3m2_alarms is mission-computed).
	&"e3m2": {
		"flags": {"e3m2_unseen": "sec_unseen", "e3m2_villagers_spared": "sec_villagers", "e3m2_hush_called": "sec_call"},
		"set_flags": {"helper_hush_unlocked": true, "e3m2_grain_spoiled": true},
		"next": &"c_e3_price",   # film c_e3_price -> e3m3
		"save_items": false,
	},
	# docs/design/mission-e3-03.md "Reward carried to e3m4" (shard uses / seizures and shadow_stone_uses are computed).
	&"e3m3": {
		"flags": {"e3m3_refused": "sec_refuse", "e3m3_crypt_whole": "sec_whole"},
		"next": &"c_e3_doubt",   # film c_e3_doubt -> e3m4
		"save_items": false,
	},
	# docs/design/mission-e3-04.md "Reward: end of Episode 3".
	&"e3m4": {
		"flags": {"e3m4_knight_charge": "sec_knight", "e3m4_refused": "sec_refuse"},
		"set_flags": {"ep3_complete": true, "torvald_heard_stone": true},
		"next": &"ep3_ending",   # film chain ep3_ending -> ep4_opening -> e4m1 (unlocks e4m1, as before)
		"save_items": false,
	},
	# Episode 4 (Ysolde's track: flags only, her essence in YSOLDE_ESSENCE_FLAG, written by the mission; Vessa's and
	# Malrik's tracks untouched). docs/design/mission-e4-01.md "Reward carried to e4m2" (folk saved / time computed).
	&"e4m1": {
		"flags": {"e4m1_ford_held": "sec_ford", "e4m1_horns_held": "sec_horns"},
		"set_flags": {"maelis_story_met": true, "ep4_started": true},
		"next": &"c_e4_refuge",   # film c_e4_refuge -> e4m2
		"save_items": false,
	},
	# docs/design/mission-e4-02.md "Reward carried to e4m3" (e4m2_folk_arrived is mission-computed).
	&"e4m2": {
		"flags": {"e4m2_brook_thawed": "sec_brook", "e4m2_hollow_burned": "sec_hollow", "e4m2_maelis_called": "sec_maelis"},
		"set_flags": {"helper_maelis_unlocked": true},
		"next": &"c_e4_turnback",   # film c_e4_turnback -> e4m3
		"save_items": false,
	},
	# docs/design/mission-e4-03.md "Reward carried to e4m4" (the Heartwood Seed: flag heartwood_seed_owned, no ItemType yet).
	&"e4m3": {
		"flags": {"e4m3_spire_shattered": "sec_spire", "e4m3_groves_unbroken": "sec_unbroken"},
		"set_flags": {"heartwood_seed_owned": true},
		"next": &"c_e4_frontier",   # film c_e4_frontier -> e4m4
		"save_items": false,
	},
	# docs/design/mission-e4-04.md "Reward carried".
	&"e4m4": {
		"flags": {"e4m4_elder_woken": "sec_elder", "e4m4_halls_broken": "sec_halls"},
		"set_flags": {"ep4_complete": true, "torvald_stayed_aldra": true, "elder_treant_unlocked_nature": true},
		"next": &"ep4_ending",   # film chain ep4_ending -> ep5_opening -> e5m1 (unlocks e5m1)
		"save_items": false,
	},
	# Episode 5 (origins, mission-e5-01.md F1): flags only under the ep5 track (nothing carried in or out; items and
	# essence at the end are discarded; Vessa's, Malrik's and Ysolde's tracks untouched). Times / counters are
	# mission-computed (e5m1_time, e5m2_bands_sprung, e5m3_pocketed, e5m4_spoils...).
	&"e5m1": {
		"flags": {"e5m1_farms_saved": "sec_farms", "e5m1_tents_burned": "sec_tents"},
		"set_flags": {"ep5_started": true},
		"next": &"e5m2",
		"save_items": false,
	},
	&"e5m2": {
		"flags": {"e5m2_patient": "sec_patience", "e5m2_towers_burned": "sec_towers"},
		"next": &"c_e5_turn",   # film c_e5_turn -> e5m3
		"save_items": false,
	},
	&"e5m3": {
		"flags": {"e5m3_quiet": "sec_quiet", "e5m3_hands_clean": "sec_hands"},
		"next": &"e5m4",
		"save_items": false,
	},
	&"e5m4": {
		"flags": {"e5m4_took_home": "sec_take", "e5m4_unseen": "sec_unseen"},
		"set_flags": {"ep5_complete": true},
		"next": &"ep5_ending",   # film chain ep5_ending -> ep6_opening -> e6m1 (unlocks e6m1)
		"save_items": false,
	},
	# Episode 6 (origins, mission-e6-01.md ER3): flags only, nothing carried in or out. Times / counts are
	# mission-computed (e6m1_time, e6m2_gate_opened, e6m2_town_saved, e6m2_saved_count...).
	&"e6m1": {
		"flags": {"e6m1_sentinels": "sec_sentinels"},
		"set_flags": {"ep6_started": true},
		"next": &"c_e6_lake",   # film c_e6_lake -> e6m2
		"save_items": false,
	},
	&"e6m2": {
		"flags": {"e6m2_gates_broken": "sec_gates", "e6m2_lake_kept": "sec_lake"},
		"next": &"c_e6_gate",   # film c_e6_gate (or c_e6_gate_shut, FILM_BRANCHES) -> e6m3
		"save_items": false,
	},
	&"e6m3": {
		"flags": {"e6m3_all_gardens": "sec_all", "e6m3_whitepelt": "sec_whitepelt"},
		"next": &"c_e6_seed",   # film c_e6_seed -> e6m4
		"save_items": false,
	},
	&"e6m4": {
		"flags": {"e6m4_seal_unbroken": "sec_unbroken", "e6m4_gates": "sec_gates"},
		"set_flags": {"ep6_complete": true},
		"next": &"ep6_ending",   # film chain ep6_ending -> ep7_opening -> e7m1 (unlocks e7m1)
		"save_items": false,
	},
	# Episode 7 (Torvald's track, campaign-outline D8): flags only, his essence (secondary bonuses included, 50 %, cap
	# 1 500) in TORVALD_ESSENCE_FLAG, written by the mission; times / counts are mission-computed (e7m1_auctions_won,
	# e7m3_sheltered, e7m4_dragons_paid...). The Heartfrost Splinter / Ossavar's Ring have no ItemType yet: flags.
	&"e7m1": {
		"flags": {"e7m1_rock_held": "sec_rock", "e7m1_wares": "sec_wares"},
		"set_flags": {"ep7_started": true, "heartfrost_splinter_owned": true},
		"next": &"c_e7_ledger",   # film c_e7_ledger -> e7m2
		"save_items": false,
	},
	&"e7m2": {
		"flags": {"e7m2_aldra_called": "sec_aldra", "e7m2_boxes": "sec_boxes", "e7m2_duel_won": "sec_duel"},
		"set_flags": {"helper_aldra_unlocked": true, "e7_truth_known": true},
		"next": &"c_e7_mask",   # film c_e7_mask -> e7m3
		"save_items": false,
	},
	&"e7m3": {
		"flags": {"e7m3_people": "sec_people", "e7m3_pits": "sec_pits", "e7m3_mask": "sec_mask"},
		"next": &"c_e7_pits",   # film c_e7_pits (or c_e7_pits_pits, FILM_BRANCHES) -> e7m4
		"save_items": false,
	},
	&"e7m4": {
		"flags": {"e7m4_red_sunk": "sec_red", "e7m4_silver_sunk": "sec_silver", "e7m4_all_paid": "sec_dragons"},
		"set_flags": {"e7_turned": true, "episode7_complete": true, "ossavar_ring_owned": true},
		"next": &"ep7_ending",   # film chain ep7_ending -> ep8_opening -> the road picker (e8m1)
		"save_items": false,
	},
	# Episode 8 (the chosen wizard's track, mission-e8-01.md D2 / 1.5): items, key relic, essence 50 % cap 1 500 and the
	# companion are saved; e8_road (int), e8_road_<k>, e8m1_done, e8_hush_fled and the counters are mission-computed.
	&"e8m1_fire": {
		"flags": {"e8m1_fire_waited": "sec_waited", "e8m1_fire_scouts": "sec_scouts", "e8m1_fire_vey_called": "sec_storm"},
		"bonus_essence": {"sec_waited": 300, "sec_scouts": 200},
		"next": &"c_e8_muster",   # film c_e8_muster -> e8m2
	},
	&"e8m1_shadow": {
		"flags": {"e8m1_shadow_shovel": "sec_shovel", "e8m1_shadow_raids": "sec_raids"},
		"bonus_essence": {"sec_shovel": 400, "sec_raids": 150},
		"next": &"c_e8_muster",
	},
	&"e8m1_ice": {
		"flags": {"e8m1_ice_open_early": "sec_early", "e8m1_ice_thirty": "sec_thirty", "e8m1_ice_shut": "sec_shut"},
		"bonus_essence": {"sec_early": 300, "sec_thirty": 300},
		"next": &"c_e8_muster",
	},
	&"e8m1_nature": {
		"flags": {"e8m1_nature_hamlets": "sec_hamlets", "e8m1_nature_bridge": "sec_bridge"},
		"bonus_essence": {"sec_hamlets": 300, "sec_bridge": 200},
		"next": &"c_e8_muster",
	},
	# mission-e8-02.md 10 (e8m2_early_rise / e8m2_hollow_peak / e8m2_time are mission-computed).
	&"e8m2": {
		"flags": {"e8m2_helped_all": "sec_help", "e8m2_hollow_low": "sec_hollow", "e8m2_gate_broken": "sec_gate"},
		"bonus_essence": {"sec_help": 300, "sec_hollow": 300, "sec_gate": 150},
		"next": &"e8m3",
	},
	# mission-e8-03.md 9: the end of every track; the closing film chain, the choice card and the credits follow.
	&"e8m3": {
		"flags": {"e8m3_chains_held": "sec_chains", "e8m3_unfed": "sec_fed", "e8m3_titan": "sec_titan"},
		"set_flags": {"ep8_complete": true, "campaign_complete": true},
		"unlock": [&"e8m1_fire", &"e8m1_shadow", &"e8m1_ice", &"e8m1_nature"],
		"next": &"ep8_ending_a",
	},
}

var unlocked: Array[StringName] = START_UNLOCKED.duplicate()
var completed: Array[StringName] = []
var flags: Dictionary = {}    # String -> bool
var items: Dictionary = {}    # CampaignItems snapshot ({} = nothing carried yet)
var companion: Dictionary = {}   # {id, variant, items, purse[, class]} ({} = no companion)
## Cinematics already watched (ids, e.g. "prologue_3min"): the campaign prologue auto-plays once, the
## CinematicPlayer's skip is one press once seen. Saved as "seen": [...] (old saves: none).
var seen: Array[StringName] = []
## Track counters (MissionBase.add_track_counter) per mission: {mission id: {counter: amount}}. Saved as "track".
## A replayed mission replaces its own contribution instead of adding it again (docs/design/mission-framework.md).
var track: Dictionary = {}
var path: String = SAVE_PATH
## The file load() read: `path`, `path + ".bak"` (the main save was unreadable) or "" (none: a new campaign).
var loaded_from := ""
## The file `open()` reads when no path is given (tests point it at their own file; "" = SAVE_PATH).
static var default_path: String = ""
## Extra reward entries (MISSION_REWARDS shape) registered at runtime by missions / tests (reward_of reads it last).
static var registered_rewards: Dictionary = {}


## A state loaded from `save_path` (a fresh campaign when there is no file). "" = `default_path` / SAVE_PATH.
static func open(save_path: String = "") -> CampaignState:
	var cs := CampaignState.new()
	if save_path == "":
		save_path = default_path if default_path != "" else SAVE_PATH
	cs.path = save_path
	cs.load()
	return cs


## The scene path of a mission id ("" when unknown).
static func mission_scene(id: StringName) -> String:
	return String(MISSION_SCENES.get(StringName(id), ""))


## True when the mission's scene exists (the menu greys out unlocked missions not built yet).
static func mission_available(id: StringName) -> bool:
	var p := mission_scene(id)
	return p != "" and ResourceLoader.exists(p)


## True when `id` is a story film of STORY_FILMS (not a mission).
static func is_film(id: StringName) -> bool:
	return STORY_FILMS.has(StringName(id))


## What follows the film `id` (a film or a mission id; &"" = none).
static func film_next(id: StringName) -> StringName:
	return StringName(STORY_FILMS.get(StringName(id), &""))


## The first mission at the end of the film chain that starts at `id` (`id` itself when it is not a film).
static func film_target(id: StringName) -> StringName:
	var at := StringName(id)
	for i in 8:
		if STORY_SCREENS.has(at):
			return &""   # the ending's choice card / credits: nothing to unlock
		if not is_film(at):
			return at
		at = film_next(at)
	return at


# ---------------------------------------------------------------- file

## Reads the file; false (and a fresh campaign) when there is no save at all. A save that does not parse (cut by a
## crash or power loss) is never taken silently for a new campaign: a warning names it, a copy is kept as
## `<path>.corrupt`, and the previous save `<path>.bak` (written by save()) is loaded instead. `loaded_from` says
## which file was read ("" = none).
func load() -> bool:
	reset_in_memory()
	loaded_from = ""
	var main_exists := FileAccess.file_exists(path)
	if main_exists:
		var d: Variant = _read_save(path)
		if d is Dictionary:
			_from_dict(d)
			loaded_from = path
			return true
		push_warning("CampaignState: the save %s is unreadable (cut or corrupt); a copy is kept as %s%s" % [path, path,
				CORRUPT_SUFFIX])
		DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(path + CORRUPT_SUFFIX))
	var bak := path + BACKUP_SUFFIX
	if FileAccess.file_exists(bak):
		var b: Variant = _read_save(bak)
		if b is Dictionary:
			if main_exists:
				push_warning("CampaignState: loaded the previous save %s instead" % bak)
			_from_dict(b)
			loaded_from = bak
			return true
		push_error("CampaignState: %s and its backup are both unreadable: a new campaign starts" % path)
	elif main_exists:
		push_error("CampaignState: %s is unreadable and there is no backup: a new campaign starts" % path)
	return false


## The parsed save of `file` (a Dictionary of this VERSION), else null.
static func _read_save(file: String) -> Variant:
	var json := JSON.new()   # JSON.parse_string would print an engine error on a cut file
	if json.parse(FileAccess.get_file_as_string(file)) != OK:
		return null
	var parsed: Variant = json.data
	if not parsed is Dictionary or int((parsed as Dictionary).get("version", 0)) != VERSION:
		return null
	return parsed


func _from_dict(d: Dictionary) -> void:
	unlocked.clear()
	for id: Variant in d.get("unlocked", []):
		_add_unique(unlocked, StringName(str(id)))
	for id in START_UNLOCKED:
		_add_unique(unlocked, id)
	for id: Variant in d.get("completed", []):
		_add_unique(completed, StringName(str(id)))
	var f: Variant = d.get("flags", {})
	if f is Dictionary:
		for k: Variant in f:
			flags[str(k)] = _clean_flag(f[k])
	var it: Variant = d.get("items", {})
	items = it if it is Dictionary else {}
	companion = _clean_companion(d.get("companion", {}))
	var sn: Variant = d.get("seen", [])
	if sn is Array:
		for id: Variant in sn:
			_add_unique(seen, StringName(str(id)))
	var tr: Variant = d.get("track", {})
	if tr is Dictionary:
		for m: Variant in tr:
			if tr[m] is Dictionary:
				var adds := {}
				for k: Variant in tr[m]:
					adds[str(k)] = int(tr[m][k]) if (tr[m][k] is int or tr[m][k] is float) else 0
				track[str(m)] = adds


## Crash-safe: writes `<path>.tmp`, then keeps the current save as `<path>.bak` and renames the new file into place,
## so a crash or power loss at any moment leaves either the old or the new save readable (load() falls back to .bak).
func save() -> Error:
	var tmp := path + TMP_SUFFIX
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(to_dict(), "\t"))
	f.flush()
	var err := f.get_error()
	f.close()
	if err != OK:
		return err
	var target := ProjectSettings.globalize_path(path)
	var bak := ProjectSettings.globalize_path(path + BACKUP_SUFFIX)
	if FileAccess.file_exists(path) and _read_save(path) != null:   # a corrupt file never replaces a good backup
		if FileAccess.file_exists(path + BACKUP_SUFFIX):
			DirAccess.remove_absolute(bak)
		DirAccess.rename_absolute(target, bak)
	elif FileAccess.file_exists(path):   # unreadable: kept aside as .corrupt, never silently lost
		DirAccess.copy_absolute(target, target + CORRUPT_SUFFIX)
		DirAccess.remove_absolute(target)
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), target)


## New campaign: clears memory and deletes the save (and its backup / temp files).
func reset() -> void:
	reset_in_memory()
	for p: String in [path, path + BACKUP_SUFFIX, path + TMP_SUFFIX]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


func reset_in_memory() -> void:
	unlocked = START_UNLOCKED.duplicate()
	completed = []
	flags = {}
	items = {}
	companion = {}
	seen = []
	track = {}


func to_dict() -> Dictionary:
	var u: Array = []
	for id in unlocked:
		u.append(String(id))
	var c: Array = []
	for id in completed:
		c.append(String(id))
	var s: Array = []
	for id in seen:
		s.append(String(id))
	return {"version": VERSION, "unlocked": u, "completed": c, "flags": flags.duplicate(), "items": items.duplicate(true),
			"companion": companion.duplicate(true), "seen": s, "track": track.duplicate(true)}


# ---------------------------------------------------------------- queries

## Unlocked mission ids in campaign order (always at least START_UNLOCKED: &"m00", &"m01").
func unlocked_missions() -> Array[StringName]:
	var out: Array[StringName] = []
	for id in MISSION_ORDER:
		if unlocked.has(id):
			out.append(id)
	for id in unlocked:
		if not out.has(id):
			out.append(id)
	return out


func is_completed(id: StringName) -> bool:
	return completed.has(StringName(id))


func flag(name: String) -> bool:
	return bool(flags.get(name, false))


## A flag's raw value (bool, or int for mission-computed counters such as `e3m2_alarms`), `default` when unset.
func flag_value(name: String, default: Variant = null) -> Variant:
	return flags.get(name, default)


## Writes several flags at once (bools, or ints for counters); `save_now` also saves the file. Returns the save
## result (OK when not saving).
func set_flags(values: Dictionary, save_now: bool = false) -> Error:
	for k: Variant in values:
		flags[str(k)] = _clean_flag(values[k])
	return save() if save_now else OK


## The reward entry of a mission (MISSION_REWARDS shape): the table above first, else the mission's own
## `mission_rewards()` (MissionBase reads it from its MissionConfig), else `registered_rewards`. {} = none.
static func reward_of(mission_id: StringName, level_node: Node = null) -> Dictionary:
	mission_id = StringName(mission_id)
	if MISSION_REWARDS.has(mission_id):
		return MISSION_REWARDS[mission_id]
	if level_node != null and level_node.has_method(&"mission_rewards"):
		var r: Variant = level_node.call(&"mission_rewards")
		if r is Dictionary and not (r as Dictionary).is_empty():
			return r
	return registered_rewards.get(mission_id, {})


static func _clean_flag(v: Variant) -> Variant:
	if v is bool:
		return v
	if v is int or v is float:
		return int(v)
	if v is String or v is StringName:   # bool(String) does not exist in Godot 4: "true" / "1" / "yes" = true
		return String(v).strip_edges().to_lower() in ["true", "1", "yes"]
	return v != null and not (v is Object and not is_instance_valid(v))


## True once the cinematic `id` was watched (or skipped) in this campaign (CinematicPlayer reads it).
func is_seen(id: StringName) -> bool:
	return seen.has(StringName(id))


## Records the cinematic `id` as watched and saves at once.
func mark_seen(id: StringName) -> Error:
	_add_unique(seen, StringName(id))
	return save()


func owned_artifacts() -> Array:
	return items.get("artifacts_owned", [])


func equipped_artifacts() -> Array:
	return items.get("artifacts_equipped", ["", ""])


## Essence given at the next mission start (already halved and capped).
func carried_essence() -> int:
	return int(items.get("essence", 0))


# ---------------------------------------------------------------- mission flow

## Call once on victory (before the scene is freed). Snapshots the player wizard's 6 slots and artifacts,
## the team's essence (+ objective bonuses, then 50 %, cap 1 500), the mission's reward artifact and flags,
## unlocks the next mission and saves. Returns the save result.
func on_mission_victory(mission_id: StringName, level_node: Node) -> Error:
	mission_id = StringName(mission_id)
	var reward: Dictionary = reward_of(mission_id, level_node)
	_apply_reward_flags(reward, level_node, String(mission_id))
	if not bool(reward.get("save_items", true)):   # flags-only missions (e.g. episode 5): items / essence untouched
		_finish_victory(mission_id, reward)
		return save()
	var hero := find_hero(level_node)
	var inventory: Variant = ItemDrops.inventory_of(hero) if hero else null
	var essence := 0
	var bank := _bank_in(level_node, _team_of(hero))
	if bank:
		essence = bank.essence
	var bonus: Dictionary = reward.get("bonus_essence", {})
	for obj: Variant in bonus:
		if objective_done(level_node, str(obj)):
			essence += int(bonus[obj])
	var owned: Array = owned_artifacts().duplicate()
	var art := str(reward.get("artifact", ""))
	if art != "" and not owned.has(art):
		owned.append(art)
	for extra: Variant in reward.get("items", []):   # e7m4: "items": [&"ossavar_ring"] (owned, not equipped)
		if str(extra) != "" and not owned.has(str(extra)):
			owned.append(str(extra))
	items = CampaignItems.snapshot(inventory if inventory != null else {}, essence, owned)
	if art != "":
		_equip_first(art)
	_finish_victory(mission_id, reward)
	return save()


## Victory flags, in order: "flags" (flag -> objective id, true when that objective is done; ORed with the saved value
## so replaying a mission never turns an earned flag back to false, review 2026-10-08 LOW 4), "set_flags"
## (constant values), then the mission's own `mission_flags()` (MissionBase.set_mission_flag: computed counters / bools).
func _apply_reward_flags(reward: Dictionary, level_node: Node, mission_id: String = "") -> void:
	var reward_flags: Dictionary = reward.get("flags", {})
	for flag_name: Variant in reward_flags:   # a replay never takes back an earned flag (true stays true)
		var key := str(flag_name)
		flags[key] = objective_done(level_node, str(reward_flags[flag_name])) or flags.get(key, false) == true
	var constant: Variant = reward.get("set_flags", {})
	if constant is Dictionary:
		set_flags(constant)
	if level_node != null and level_node.has_method(&"mission_flags"):
		var computed: Variant = level_node.call(&"mission_flags")
		if computed is Dictionary:
			set_flags(computed)
	if level_node != null and level_node.has_method(&"mission_flag_adds"):   # track counters (shadow_stone_uses)
		var adds: Variant = level_node.call(&"mission_flag_adds")
		if adds is Dictionary:
			add_track(mission_id if mission_id != "" else mission_id_of(level_node), adds)


## Adds a mission's track counters (counter -> amount) to the totals in `flags`. Each mission counts once: a replayed
## mission replaces what it added last time (the latest victory counts), so replays never inflate a counter.
func add_track(mission_id: String, adds: Dictionary) -> void:
	var before: Dictionary = track.get(mission_id, {})
	var now := {}
	for k: Variant in adds:
		now[str(k)] = int(adds[k])
	for k: String in before:
		if not now.has(k):
			now[k] = 0
	for k: String in now:
		flags[k] = int(flags.get(k, 0)) - int(before.get(k, 0)) + int(now[k])
	if mission_id != "":
		track[mission_id] = now


static func mission_id_of(level_node: Node) -> String:
	if level_node != null and &"mission_id" in level_node:
		return String(level_node.get(&"mission_id"))
	return ""


func _finish_victory(mission_id: StringName, reward: Dictionary) -> void:
	_add_unique(completed, mission_id)
	_add_unique(unlocked, mission_id)
	var next: StringName = StringName(reward.get("next", &""))
	if next == &"":
		var i := MISSION_ORDER.find(mission_id)
		next = MISSION_ORDER[i + 1] if i >= 0 and i + 1 < MISSION_ORDER.size() else &""
	next = film_target(next)   # a film in "next" unlocks the mission at the end of its chain (ep2_ending -> e3m1)
	if next != &"":
		_add_unique(unlocked, next)
	for id: Variant in reward.get("unlock", []):   # e8m3: several missions at once
		_add_unique(unlocked, StringName(str(id)))


## Call at the start of the next mission, once its player wizard exists: fills the wizard's inventory
## (6 slots with potion counts, the 2 equipped artifacts, so their modifiers apply) and adds the carried
## essence to the team's EssenceBank. Flags are also written as metas `campaign_flags` on level_node.
## Returns false when there is no hero / inventory.
func apply_to_start(level_node: Node) -> bool:
	if level_node:
		level_node.set_meta(&"campaign_flags", flags.duplicate())
	var hero := find_hero(level_node)
	if hero == null:
		return false
	apply_companion(level_node)
	var inventory: Variant = ItemDrops.inventory_of(hero)
	if inventory == null:
		ItemDrops.ensure_inventory(hero)
		inventory = ItemDrops.inventory_of(hero)
	if inventory == null or items.is_empty():
		return inventory != null
	var essence := CampaignItems.restore(items, inventory)
	if essence > 0 and not economy_on(level_node):
		# No-economy mode = 0 essence: held back on the level (MissionBase.grant_carried_essence adds it later).
		level_node.set_meta(META_CARRIED_ESSENCE, int(level_node.get_meta(META_CARRIED_ESSENCE, 0)) + essence)
		return true
	var bank := _bank_in(level_node, _team_of(hero))
	if bank and essence > 0:
		bank.add(essence)
	return true


## False when the level is a mission whose MissionConfig turns the economy off (no-economy mode).
static func economy_on(level_node: Node) -> bool:
	if level_node == null or not &"config" in level_node:
		return true
	var c: Variant = level_node.get(&"config")
	if c is Object and is_instance_valid(c) and &"economy_enabled" in (c as Object):
		return bool((c as Object).get(&"economy_enabled"))
	return true


# ---------------------------------------------------------------- champion companion (champions.md 11)

## True when the level has taverns / champions (`tavern_enabled`; missions default to false).
static func tavern_enabled(level_node: Node) -> bool:
	return level_node != null and &"tavern_enabled" in level_node and bool(level_node.get(&"tavern_enabled"))


func has_companion() -> bool:
	return not companion.is_empty()


## The save entry for `champion`: archetype, name variant, its (up to 4) item slots, 50 % of its purse
## capped at 300, and its class id under "class" when it has one (skills-rework.md 8; no key before level 2).
## {} for anything that is not a champion.
static func companion_snapshot(champion: Node) -> Dictionary:
	if champion == null or not is_instance_valid(champion):
		return {}
	var id := &""
	var type: Variant = champion.get(&"champion_type")
	if type is Object and (type as Object).get(&"id") != null:
		id = StringName((type as Object).get(&"id"))
	if id == &"":
		var guild := ChampionGuild.for_team(_team_of(champion))
		if guild:
			id = guild.archetype_of(champion)
	if id == &"":
		return {}
	var variant: Variant = champion.get(&"variant")
	var purse: Variant = champion.get(&"purse")
	var slots: Array = []
	var inv: Variant = ItemDrops.inventory_of(champion)
	var src: Variant = null
	if inv is Object and &"slots" in (inv as Object):
		src = (inv as Object).get(&"slots")
	var src_slots: Array = src if src is Array else []
	for i in COMPANION_SLOTS:
		slots.append(_companion_item(src_slots[i] if i < src_slots.size() else null))
	var out := {"id": String(id), "variant": clampi(int(variant) if variant != null else 0, 0, 1), "items": slots,
			"purse": companion_purse(int(purse) if purse != null else 0)}
	var cls := companion_class_of(champion)
	if cls != "":
		out["class"] = cls
	return out


## The class id of `champion` ("" = none yet): `class_id()` (step 11, 11.C1), else `champion_class.id`.
static func companion_class_of(champion: Node) -> String:
	if champion == null or not is_instance_valid(champion):
		return ""
	if champion.has_method(&"class_id"):
		return String(champion.call(&"class_id"))
	var cc: Variant = champion.get(&"champion_class")
	if cc is Object and (cc as Object).get(&"id") != null:
		return String((cc as Object).get(&"id"))
	return ""


## Purse carried to the next mission: 50 %, rounded down, capped at 300.
static func companion_purse(purse: int) -> int:
	return mini(floori(maxf(purse, 0) * COMPANION_PURSE_RATIO), COMPANION_PURSE_CAP)


## The champions the player hired in this mission (alive or fallen): the choice screen's list.
func companion_candidates(level_node: Node) -> Array:
	var guild := _guild_in(level_node, PLAYER_TEAM)
	return guild.champions.duplicate() if guild else []


## The player picked `champion` (null = none) on the victory choice screen: stores and saves.
func choose_companion(champion: Node) -> Error:
	companion = companion_snapshot(champion) if champion else {}
	return save()


## At the start of a mission with taverns: the stored companion walks in beside the wizard as roster slot 1
## (no hire cost; level 1, carried items and purse; its saved class is re-applied by ChampionGuild.add_companion
## through `set_champion_class`, class skills locked again until levels 2 / 3 / 5). Returns it, or null (none stored, no taverns, no
## guild yet). apply_to_start() calls it.
func apply_companion(level_node: Node) -> Node:
	if companion.is_empty() or not tavern_enabled(level_node):
		return null
	var guild := _guild_in(level_node, PLAYER_TEAM)
	if guild == null:
		return null
	var existing := guild.champion_of(StringName(companion["id"]))
	if existing:
		return existing   # already applied
	var hero := find_hero(level_node) as Node3D
	var at: Vector3 = hero.global_position + COMPANION_OFFSET if hero else guild.home_point()
	if at == Vector3.INF:
		return null
	return guild.add_companion(companion, at)


static func _guild_in(level_node: Node, team: int) -> ChampionGuild:
	var guild := ChampionGuild.for_team(team)
	if guild == null or level_node == null or not (level_node == guild or level_node.is_ancestor_of(guild)):
		return null
	return guild


## {id, count} of an inventory slot entry ({type: ItemType or id, count}) or of a saved {id, count}, or null.
static func _companion_item(e: Variant) -> Variant:
	var t: Variant = e
	if e is Dictionary:
		t = (e as Dictionary).get("type", (e as Dictionary).get("id"))
	var id := ""
	if t is String or t is StringName:
		id = String(t)
	elif t is Object and (t as Object).get(&"id") != null:
		id = String((t as Object).get(&"id"))
	if id == "":
		return null
	var count := int((e as Dictionary).get("count", 1)) if e is Dictionary else 1
	return {"id": id, "count": maxi(1, count)}


## A loaded companion entry, checked ({} when unusable).
static func _clean_companion(v: Variant) -> Dictionary:
	if not v is Dictionary or str((v as Dictionary).get("id", "")) == "":
		return {}
	var d := v as Dictionary
	var out_items: Array = []
	var src: Variant = d.get("items", [])
	var src_items: Array = src if src is Array else []
	for i in COMPANION_SLOTS:
		out_items.append(_companion_item(src_items[i] if i < src_items.size() else null))
	var out := {"id": str(d["id"]), "variant": clampi(int(d.get("variant", 0)), 0, 1), "items": out_items,
			"purse": clampi(int(d.get("purse", 0)), 0, COMPANION_PURSE_CAP)}
	# Optional (step 11): kept only when it is a non-empty id; old saves without it load unchanged.
	var cls: Variant = d.get("class", "")
	if (cls is String or cls is StringName) and String(cls).strip_edges() != "":
		out["class"] = String(cls).strip_edges()
	return out


# ---------------------------------------------------------------- level helpers

## The player's wizard of `level_node`: its `hero` property, else the first PLAYER node in "heroes".
static func find_hero(level_node: Node) -> Node:
	if level_node == null:
		return null
	if &"hero" in level_node:
		var h: Variant = level_node.get(&"hero")
		if is_instance_valid(h) and h is Node:
			return h
	if not level_node.is_inside_tree():
		return null
	for n in level_node.get_tree().get_nodes_in_group("heroes"):
		if (n == level_node or level_node.is_ancestor_of(n)) and _team_of(n) == PLAYER_TEAM:
			return n
	return null


## True when objective `id` of the level is "done" (see the header for what is read).
static func objective_done(level_node: Node, id: String) -> bool:
	if level_node == null:
		return false
	if level_node.has_method(&"objective_state"):
		return _state_is_done(level_node.call(&"objective_state", id))
	for key: StringName in [&"objective_states", &"objectives"]:
		var d: Variant = level_node.get(key) if key in level_node else null
		if d == null and level_node.has_meta(key):
			d = level_node.get_meta(key)
		if d is Dictionary:
			var dict := d as Dictionary
			var v: Variant = dict.get(id, dict.get(StringName(id)))
			if v != null:
				return _state_is_done(v)
	return false


static func _state_is_done(v: Variant) -> bool:
	if v is Dictionary:
		v = (v as Dictionary).get("state", "")
	return str(v) == "done"


static func _team_of(n: Node) -> int:
	if n == null:
		return PLAYER_TEAM
	var t: Variant = n.get(&"team")
	return int(t) if t != null else PLAYER_TEAM


## The team's EssenceBank inside the level's tree (created by EssenceBank.for_team if missing).
static func _bank_in(level_node: Node, team: int) -> EssenceBank:
	if level_node and level_node.is_inside_tree():
		for n in level_node.get_tree().get_nodes_in_group("essence_banks"):
			var b := n as EssenceBank
			if b and b.team == team and not b.is_queued_for_deletion():
				return b
	return EssenceBank.for_team(team)


## Puts `art` in equipped slot 1; what was there moves to slot 2 if it is free (still owned either way).
func _equip_first(art: String) -> void:
	var eq: Array = items.get("artifacts_equipped", ["", ""]).duplicate()
	while eq.size() < CampaignItems.ARTIFACT_SLOTS:
		eq.append("")
	if eq.has(art):
		return
	if str(eq[0]) != "" and str(eq[1]) == "":
		eq[1] = eq[0]
	eq[0] = art
	items["artifacts_equipped"] = eq


static func _add_unique(arr: Array, id: StringName) -> void:
	if id != &"" and not arr.has(id):
		arr.append(id)
