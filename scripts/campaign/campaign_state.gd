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
const MISSION_ORDER: Array[StringName] = [&"m00", &"m01", &"m02", &"m03", &"m04", &"e2m1", &"e2m2", &"e2m3", &"e2m4", &"e2m5"]
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
}
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
		"next": &"m02",
	},
	# docs/design/mission-02.md "Reward carried to mission 3".
	&"m02": {
		"artifact": "stillwater_orb",
		"flags": {"m2_emberguard_sworn": "sec_emberguard", "m2_dig_under_half": "sec_dig"},
		"bonus_essence": {"sec_dig": 300},
		"next": &"m03",
	},
	# docs/design/mission-03.md "Reward carried to mission 4" (m3_hired: M4 knows whether a companion can exist).
	&"m03": {
		"artifact": "masters_signet",
		"flags": {"m3_mossjaw_slain": "sec_mossjaw", "m3_stakes_held": "sec_stakes", "m3_hired": "sec_champion"},
		"bonus_essence": {"sec_stakes": 300, "sec_mossjaw": 150},
		"next": &"m04",
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
		"next": &"e2m2",
	},
	# docs/design/mission-e2-02.md "Reward carried to e2m3".
	&"e2m2": {
		"flags": {"e2m2_carriers_kept": "sec_carriers", "e2m2_points_held": "sec_points"},
		"bonus_essence": {"sec_carriers": 300, "sec_points": 150},
		"set_flags": {"ep2_nature_allied": true},
		"next": &"e2m3",
	},
	# docs/design/mission-e2-03.md "Reward carried to e2m4" (gold is never carried).
	&"e2m3": {
		"flags": {"e2m3_magpies_hunted": "sec_magpies", "e2m3_malrik_robbed": "sec_raid", "e2m3_toll_broken": "sec_toll"},
		"bonus_essence": {"sec_magpies": 150, "sec_raid": 300, "sec_toll": 150},
		"set_flags": {"e2m3_lodge_paid": true},
		"next": &"e2m4",
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


## Victory flags, in order: "flags" (flag -> objective id, true when that objective is done), "set_flags"
## (constant values), then the mission's own `mission_flags()` (MissionBase.set_mission_flag: computed counters / bools).
func _apply_reward_flags(reward: Dictionary, level_node: Node, mission_id: String = "") -> void:
	var reward_flags: Dictionary = reward.get("flags", {})
	for flag_name: Variant in reward_flags:
		flags[str(flag_name)] = objective_done(level_node, str(reward_flags[flag_name]))
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
