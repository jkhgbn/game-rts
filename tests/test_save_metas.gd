extends SceneTree
## Root-cause guard (CLAUDE.md "Recurring bugs", code review 2026-10-12 R4-1 / R5-1 / R5-2 / Wither Hex):
## SaveCodec.encode_metas saves every meta of a Unit / Building whose name does not start with "_". A marker meta
## ("already hooked"), an absolute time from process start or a node / instance-id reference saved that way breaks
## after a load. This test scans scripts/**/*.gd for every set_meta (and set("metadata/...")) and FAILS for a name
## without a "_" prefix unless it is listed below as state worth saving (SAVE_METAS) or as a meta only ever set on
## nodes the save never encodes (OFF_SAVE_METAS).
## Fix for a FAIL: rename the meta with a "_" prefix (marker / time / transient: not saved), or, when the value really
## is state a load must keep (no absolute time, no instance id, no "connected" flag), add it to SAVE_METAS with a reason.
## Run:  godot --headless --path . -s tests/test_save_metas.gd --quit-after 3000
## Prints one line "PASS save_metas" or "FAIL save_metas: <reason>" at the end.

const TASK_ID := "save_metas"
const SCAN_ROOT := "res://scripts"

## Metas that ARE saved on purpose (plain values a load must keep). Name -> one-line reason.
const SAVE_METAS := {
	# core / units / world
	"truce": "MissionBase.set_truce id shared by nodes that must not fight (Unit.in_truce)",
	"loot": "a Magpie's carried gold (Unit.get_loot / set_loot, loot sacks)",
	"last_attacker_team": "team that last hit a building (essence kill credit)",
	"plus": "the unit carries its team's researched '+' upgrade",
	"rank": "Stables rank 3 applied to this unit",
	"rank_name": "Stables rank 3 display name of this unit",
	"bowman_crit_acc": "Bowman crit accumulator (deterministic gameplay state)",
	"bowman_bleed_stacks": "Bleakbow bleed stacks (only read while the bleed DoT runs)",
	"bowman_twin": "this archer is a Wildwood twin (never twinned again)",
	"status_time_mult": "item passive status-duration multipliers on the wizard (plain Dictionary)",
	"lair_id": "the lair an epic beast belongs to",
	"beast_variant": "an epic beast's variant",
	"e2m2_guest": "e2m2: a pop-0 guest of Ysolde's column / grove sprouts (the load rebuilds it with its pop-0 type)",
	"hired_by": "team that hired a Greywater tracker",
	"tracker_kind": "a tracker's contract kind",
	"tracker_leaving": "the tracker is walking off the map",
	"ws_card": "Wave Strike card id of a lane unit",
	"ws_seat": "Wave Strike seat of a lane unit",
	"scripted": "MissionBase.mark_scripted: the Commander leaves this node alone (group is saved too)",
	# mission framework (MissionBase: 'their metas travel with the units'; times are mission_time(), which is saved)
	"mission_seat": "MissionBase seat of a node",
	"mission_home": "MissionBase home point of a mission unit",
	"mission_mode": "MissionBase behaviour mode of a mission unit",
	"mission_target": "MissionBase target of a mission unit",
	"mission_dormant": "MissionBase.set_dormant state",
	"mission_aggro": "aggro_range before set_dormant",
	"mission_prev_guard": "death_guard before set_dormant",
	"mission_truce_prev": "truce id a seat node had before its switch grace",
	"mission_locked": "TrainingBuilding locked by the mission (lock_base)",
	# mission scripts: per-unit mission state (times are mission_time() based, restored by MissionBase.load_state)
	"side": "mission 0 building side",
	"m0_leaving": "mission 0 unit is leaving",
	"m0_ashby": "mission 0 Ashby",
	"m0_escort": "mission 1 escort unit",
	"m1_free_rider": "mission 1 freed rider",
	"dig_slot": "mission 2 dig slot",
	"squad": "mission 3 squad id",
	"drain_slot": "mission 3 drain slot",
	"m3_home": "mission 3 home spot",
	"sinking": "mission 3 Ysolde sinking",
	"m4_no_hollow": "mission 4 unit immune to the Hollow",
	"m4_buried": "mission 4 buried unit",
	"m4_strike": "mission 4 strike unit",
	"e2m1_home": "E2M1 unit went home",
	"e2m2_goal": "E2M2 Ysolde goal point",
	"e2m2_walking": "E2M2 companion walking",
	"e2m2_spent": "E2M2 companion spent",
	"e2m2_ally_order": "E2M2 ally got its order",
	"e2m3_tribute": "E2M3 tribute caravan",
	"e2m3_cargo": "E2M3 caravan cargo",
	"e2m4_sleeper": "E2M4 sleeper id",
	"e2m4_storm": "E2M4 storm unit",
	"e2m4_targets": "E2M4 acolyte targets",
	"e2m4_wave": "E2M4 wave id",
	"e2m5_hall": "E2M5 hall",
	"e3m1_hall": "E3M1 hall",
	"e3m2_hall": "E3M2 hall",
	"veterancy": "E3M2 starting veterancy",
	"night": "E3M2 night unit",
	"alert_guard": "E3M2 alerted guard",
	"lured": "E3M2 lure time left (relative countdown)",
	"lodge": "E3M3 lodge unit",
	"e3m4_hall": "E3M4 hall",
	"via": "E3M4 ford to cross",
	"watch": "E3M4 watched target",
	"crossed": "E3M4 crossed the ford",
	"e4m1_hall": "E4M1 hall",
	"vessa_guard": "E4M1 Vessa guard",
	"bell": "E4M1 bell id",
	"saved": "E4M1 folk saved",
	"convoy": "E4M2 convoy index",
	"wp": "E4M2 waypoint index",
	"arrived": "E4M2 arrived",
	"on_ice": "E4M2 on the ice",
	"e4m4_hall": "E4M4 hall",
	"e5m2_wood": "E5M2 wood building",
	"e5_route": "E5M3 patrol route",
	"e5_wp": "E5M3 waypoint index",
	"e5_mode": "E5M3 guard mode",
	"e5_post": "E5M3 guard post",
	"e5_seen_at": "E5M3 last seen (mission_time)",
	"e5_hunt": "E5M3 hunt point",
	"e5_cry_at": "E5M3 last cry (mission_time)",
	"e5_extra": "E5M3 extra guard",
	"e5_wake_at": "E5M3 wakes at (mission_time)",
	"e5_search_until": "E5M3 search end (mission_time)",
	"garden": "E6M3 garden index",
	"hit_at": "E6M3 last hit (mission_time)",
	"e7_raid_until": "E7 raid end (mission_time)",
	"e7_route": "E7 route points",
	"e7_back_at": "E7 back at (mission_time)",
	"e7_mode": "E7M3 mode",
	"e7_default": "E7M3 default row",
	"e7_up_at": "E7M4 up at (mission_time)",
	"fled": "E7M4 Hush fled",
	"frozen": "E7M4 frozen building",
	"leg": "E8 fire leg",
	"home": "E8 fire unit reached home",
	"slot": "E8 ice slot",
	"to": "E8 ice destination",
	"door": "E8 shadow door id",
	"kneel_fed": "E8M2 last kneel feed (mission_time)",
	"kneeling": "E8 kneeling end (mission_time)",
}

## Metas set only on nodes the save never encodes (encode_metas runs on Units and Buildings only):
## UI controls, UnitType stubs (Resources), props, the level node. Key "name" or "res-relative file|name" -> reason.
const OFF_SAVE_METAS := {
	"campaign_flags": "set on the mission level node (CampaignState reads it at the end), never a Unit / Building",
	"scripts/campaign/campaign_state.gd|carried_essence": "level node",
	"scripts/campaign/mission_e7_04.gd|truce_end": "level node (mission script itself)",
	"scripts/campaign/mission_e3_03.gd|door_mat": "barrow door MeshInstance3D",
	"scripts/buildings/forge_kit.gd|forge_line": "Forge UnitType stub (command card)",
	"scripts/buildings/forge_kit.gd|forge_level": "Forge UnitType stub (command card)",
	"scripts/buildings/forge_kit.gd|card_text": "Forge UnitType stub (command card)",
	"scripts/buildings/keep.gd|card_text": "tier UnitType stub (command card)",
	"scripts/units/stables16.gd|rank_of": "rank UnitType stub (command card)",
	"scripts/units/stables16.gd|card_text": "rank UnitType stub (command card)",
	"scripts/units/t3_kit.gd|card_text": "UnitType / stub (command card)",
	"scripts/world/bounty.gd|bounty": "the bounty flag's click StaticBody3D",
	"scripts/world/layout_level.gd|kind": "layout prop body",
	"scripts/world/layout_level.gd|landmark_id": "landmark prop root",
	"scripts/world/skirmish.gd|landmark_id": "landmark prop root",
	"scripts/ui/flag_card.gd|champion": "UI button",
	"scripts/ui/mapfill_bar.gd|popping": "UI chip",
	"scripts/ui/portrait.gd|rim": "UI frame",
	"scripts/ui/selection_panel.gd|row_text": "UI chip",
	"scripts/ui/selection_panel.gd|mapfill": "UI chip",
	"scripts/ui/shop_window.gd|item_type": "UI button",
	"scripts/ui/shop_window.gd|rim": "UI button",
	"scripts/ui/tavern_window.gd|reason": "UI button",
	"scripts/ui/tavern_window.gd|ability_id": "UI label",
	"scripts/ui/trade_window.gd|tab_text": "UI button",
	"scripts/ui/trade_window.gd|to": "UI button",
	"scripts/ui/trade_window.gd|key_badge": "UI button",
	"scripts/ui/ui_style.gd|fill_gradient": "UI button",
	"scripts/ui/ui_style.gd|fill_color": "UI button",
}

## Files allowed to call set_meta with a computed name. File -> reason.
const DYNAMIC_OK := {
	"scripts/core/save_codec.gd": "decode_metas puts the saved names back",
	"scripts/units/clock_meta_ledger.gd": "puts back its own `_`-prefixed clock metas (time left saved by the ledger)",
}

var _re_const := RegEx.new()
var _re_class := RegEx.new()
var _re_extends := RegEx.new()
var _re_set := RegEx.new()
var _re_set_prop := RegEx.new()
var _re_lit := RegEx.new()
var _re_sn := RegEx.new()
var _re_ident := RegEx.new()

var _files: Dictionary = {}       # rel path -> text
var _consts: Dictionary = {}      # rel path -> {CONST: "value"}
var _class_file: Dictionary = {}  # class_name -> rel path
var _extends: Dictionary = {}     # rel path -> rel path of the parent script ("" = engine class)
var _errors: Array[String] = []


func _initialize() -> void:
	_re_const.compile("(?m)^[ \\t]*(?:static[ \\t]+)?const[ \\t]+([A-Za-z_][A-Za-z_0-9]*)[ \\t]*(?::[ \\t]*[A-Za-z_]+[ \\t]*)?:?=[ \\t]*(?:&|StringName\\([ \\t]*)?\"([^\"\\\\]*)\"")
	_re_class.compile("(?m)^class_name[ \\t]+([A-Za-z_][A-Za-z_0-9]*)")
	_re_extends.compile("(?m)^extends[ \\t]+([A-Za-z_][A-Za-z_0-9.]*|\"[^\"]*\")")
	_re_set.compile("\\bset_meta\\(")
	_re_set_prop.compile("\\bset\\(\\s*&?\"metadata/([^\"]+)\"")
	_re_lit.compile("^&?\"([^\"]*)\"$")
	_re_sn.compile("^StringName\\(\\s*\"([^\"]*)\"\\s*\\)$")
	_re_ident.compile("^([A-Za-z_][A-Za-z_0-9]*)(?:\\.([A-Za-z_][A-Za-z_0-9]*))?$")
	_self_test()
	_load_dir(SCAN_ROOT)
	_index()
	var found := _scan()   # name -> Array of "file:line"
	_report(found)
	quit()


# ---------------------------------------------------------------- scanning

func _load_dir(path: String) -> void:
	var d := DirAccess.open(path)
	if d == null:
		_errors.append("cannot open %s" % path)
		return
	for sub: String in d.get_directories():
		_load_dir(path.path_join(sub))
	for f: String in d.get_files():
		if f.ends_with(".gd"):
			var full := path.path_join(f)
			_files[full.trim_prefix("res://")] = FileAccess.get_file_as_string(full)


func _index() -> void:
	for rel: String in _files:
		var text: String = _files[rel]
		var c := {}
		for m: RegExMatch in _re_const.search_all(text):
			c[m.get_string(1)] = m.get_string(2)
		_consts[rel] = c
		var cm := _re_class.search(text)
		if cm != null:
			_class_file[cm.get_string(1)] = rel
	for rel: String in _files:
		var em := _re_extends.search(_files[rel])
		var parent := ""
		if em != null:
			var e := em.get_string(1)
			if e.begins_with("\""):
				parent = e.trim_prefix("\"").trim_suffix("\"").trim_prefix("res://")
			elif _class_file.has(e):
				parent = _class_file[e]
		_extends[rel] = parent


## Value of constant `name` seen from `rel` (own file, then its parent scripts); "" = not found.
func _const_in_chain(rel: String, name: String) -> String:
	var at := rel
	var guard := 0
	while at != "" and guard < 32:
		var c: Dictionary = _consts.get(at, {})
		if c.has(name):
			return c[name]
		at = _extends.get(at, "")
		guard += 1
	return ""


## The meta name an argument expression stands for; "" = computed at runtime.
func _resolve(rel: String, arg: String) -> String:
	var m := _re_lit.search(arg)
	if m != null:
		return m.get_string(1)
	m = _re_sn.search(arg)
	if m != null:
		return m.get_string(1)
	m = _re_ident.search(arg)
	if m == null:
		return ""
	if m.get_string(2) != "":   # Class.CONST
		var owner_file: String = _class_file.get(m.get_string(1), "")
		return _const_in_chain(owner_file, m.get_string(2)) if owner_file != "" else ""
	var name := m.get_string(1)
	var v := _const_in_chain(rel, name)
	if v != "":
		return v
	# An unqualified constant from elsewhere (autoload-free static access): only when every definition agrees.
	var seen := ""
	for f: String in _consts:
		var c: Dictionary = _consts[f]
		if c.has(name):
			if seen != "" and seen != String(c[name]):
				return ""
			seen = c[name]
	return seen


## The first argument of a call whose "(" ends at `from` (nested brackets and strings skipped), stripped.
func _first_arg(text: String, from: int) -> String:
	var depth := 0
	var quote := ""
	var i := from
	while i < text.length():
		var ch := text[i]
		if quote != "":
			if ch == "\\":
				i += 1
			elif ch == quote:
				quote = ""
		elif ch == "\"" or ch == "'":
			quote = ch
		elif ch == "(" or ch == "[" or ch == "{":
			depth += 1
		elif ch == ")" or ch == "]" or ch == "}":
			if depth == 0:
				break
			depth -= 1
		elif ch == "," and depth == 0:
			break
		i += 1
	return text.substr(from, i - from).strip_edges()


func _line_of(text: String, pos: int) -> int:
	return text.substr(0, pos).count("\n") + 1


func _in_comment(text: String, pos: int) -> bool:
	var ls := text.rfind("\n", pos) + 1
	return text.substr(ls, pos - ls).contains("#")


func _scan() -> Dictionary:
	var found := {}
	var calls := 0
	for rel: String in _files:
		var text: String = _files[rel]
		for m: RegExMatch in _re_set.search_all(text):
			if _in_comment(text, m.get_start()):
				continue
			calls += 1
			var arg := _first_arg(text, m.get_end())
			var name := _resolve(rel, arg)
			var where := "%s:%d" % [rel, _line_of(text, m.get_start())]
			if name == "":
				if not DYNAMIC_OK.has(rel):
					_errors.append("computed meta name `%s` at %s (use a literal or a constant)" % [arg, where])
				continue
			_add(found, name, rel, where)
		for m: RegExMatch in _re_set_prop.search_all(text):
			if not _in_comment(text, m.get_start()):
				calls += 1
				_add(found, m.get_string(1), rel, "%s:%d" % [rel, _line_of(text, m.get_start())])
	# The scan must really see the code base (a broken regex must not pass vacuously).
	if _files.size() < 100 or calls < 300:
		_errors.append("scan too small (%d files, %d set_meta calls): the scanner is broken" % [_files.size(), calls])
	for must: String in ["mission_home", "loot", "truce"]:
		if not found.has(must):
			_errors.append("scan did not find the meta `%s` (constant resolution broken?)" % must)
	print("save_metas: %d files, %d set_meta calls, %d distinct names" % [_files.size(), calls, found.size()])
	return found


func _add(found: Dictionary, name: String, rel: String, where: String) -> void:
	if not found.has(name):
		found[name] = []
	(found[name] as Array).append([rel, where])


# ---------------------------------------------------------------- verdict

func _report(found: Dictionary) -> void:
	var codec := FileAccess.get_file_as_string("res://scripts/core/save_codec.gd")
	if not codec.contains("begins_with(\"_\")"):
		_errors.append("SaveCodec.encode_metas no longer skips \"_\" metas: this test's rule is out of date")
	var bad: Array[String] = []
	var names := found.keys()
	names.sort()
	for name: String in names:
		if name.begins_with("_") or SAVE_METAS.has(name) or OFF_SAVE_METAS.has(name):
			continue
		var wheres: Array[String] = []
		for hit: Array in found[name]:
			if not OFF_SAVE_METAS.has("%s|%s" % [hit[0], name]):
				wheres.append(hit[1])
		if not wheres.is_empty():
			bad.append("  %s  (%s)  %s" % [name, _owner(wheres[0]), ", ".join(wheres)])
	for name: String in SAVE_METAS:
		if not found.has(name):
			print("save_metas: note: SAVE_METAS entry `%s` is no longer set anywhere (remove it)" % name)
	for key: String in OFF_SAVE_METAS:
		var nm := key.get_slice("|", 1) if key.contains("|") else key
		if not found.has(nm):
			print("save_metas: note: OFF_SAVE_METAS entry `%s` is no longer set anywhere (remove it)" % key)
	if not bad.is_empty():
		print("save_metas: %d meta name(s) saved by SaveCodec.encode_metas but not listed as SAVE state." % bad.size())
		print("  Rename with a \"_\" prefix (marker / absolute time / transient), or add to SAVE_METAS with a reason:")
		for b: String in bad:
			print(b)
		_errors.append("%d unlisted saved meta name(s): %s" % [bad.size(),
				", ".join(bad.map(func(s: String) -> String: return s.strip_edges().get_slice(" ", 0)))])
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for e: String in _errors.slice(0, _errors.size() - 1):
			print("save_metas: error: %s" % e)
		print("FAIL %s: %s" % [TASK_ID, _errors[_errors.size() - 1]])


func _owner(where: String) -> String:
	var p := where.get_slice(":", 0)
	for pair: Array in [["scripts/units/", "gameplay-coder"], ["scripts/spells/", "gameplay-coder"],
			["scripts/economy/", "systems-coder"], ["scripts/buildings/", "systems-coder"],
			["scripts/world/", "systems-coder"], ["scripts/campaign/", "systems-coder"],
			["scripts/cinematics/", "systems-coder"], ["scripts/ui/", "ui-coder"], ["scripts/vfx/", "ui-coder"],
			["scripts/ai/", "ai-coder"], ["scripts/items/", "items-coder"]]:
		if p.begins_with(pair[0]):
			return pair[1]
	return "lead"


# ---------------------------------------------------------------- matcher self-test

func _self_test() -> void:
	var src := "\n".join([
		"extends Node",
		"const A_META := &\"a_const\"",
		"const B_META: StringName = StringName(\"b_const\")",
		"func f(n: Node, u: Node) -> void:",
		"\tn.set_meta(&\"lit_sn\", true)",
		"\tn.set_meta(\"lit_str\", 1)",
		"\tn.set_meta(StringName(\"lit_ctor\"), 1)",
		"\tu.get_parent().set_meta(A_META, 2)",
		"\tset_meta(B_META,",
		"\t\t\t3)",
		"\t# n.set_meta(&\"commented\", 1)",
		"\tn.set(&\"metadata/via_set\", 1)",
	])
	var rel := "selftest.gd"
	_files[rel] = src
	_index()
	var found := _scan_one(rel)
	_files.erase(rel)
	_consts.erase(rel)
	_extends.erase(rel)
	var want := ["lit_sn", "lit_str", "lit_ctor", "a_const", "b_const", "via_set"]
	for w: String in want:
		if not found.has(w):
			_errors.append("self-test: the scanner missed `%s`" % w)
	if found.has("commented"):
		_errors.append("self-test: the scanner read a commented-out set_meta")


func _scan_one(rel: String) -> Dictionary:
	var text: String = _files[rel]
	var found := {}
	for m: RegExMatch in _re_set.search_all(text):
		if not _in_comment(text, m.get_start()):
			found[_resolve(rel, _first_arg(text, m.get_end()))] = true
	for m: RegExMatch in _re_set_prop.search_all(text):
		if not _in_comment(text, m.get_start()):
			found[m.get_string(1)] = true
	return found
