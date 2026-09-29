extends RefCounted
## Data Lab (docs/plan/data-lab.md): every check. load_all() fills the lists from data/**; a test can fill them with
## synthetic resources instead and call run_checks() (or one check_* function) on its own report.
## Numbers and lists live in data_lab_rules.gd. Only reads game data and scripts; never writes them.

const Rules := preload("res://tools/data_lab/data_lab_rules.gd")
const TextTools := preload("res://tools/data_lab/data_lab_text.gd")

var report: RefCounted   # data_lab_report.gd
## Each entry: {"path": String, "res": Resource}.
var units: Array[Dictionary] = []
var buildings: Array[Dictionary] = []
var champions: Array[Dictionary] = []
var classes: Array[Dictionary] = []
var items: Array[Dictionary] = []
var spells: Array[Dictionary] = []
var ai_profiles: Array[Dictionary] = []
var load_issues: Array = []
var files_seen := 0
## Wizard script -> kingdom + its F / Q / E spell ids (parsed from scripts/units/*wizard.gd).
var wizard_spells: Dictionary = {}
## Skip the UI string scan (tests with synthetic data).
var scan_ui := true
var scan_code_tables := true


func _init(r: RefCounted) -> void:
	report = r


# ---------------------------------------------------------------- loading

func load_all() -> void:
	for dir_path: String in Rules.DATA_DIRS:
		for file: String in _tres_files(dir_path):
			files_seen += 1
			var path := dir_path.path_join(file)
			var res: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE)
			if res == null:
				load_issues.append({"sev": "FAIL", "where": path, "what": "does not load (parse error or missing script)",
					"fix": "open it in the editor, fix the broken ext_resource / field"})
				continue
			var entry := {"path": path, "res": res}
			if res is UnitType:
				units.append(entry)
			elif res is BuildingType:
				buildings.append(entry)
			elif res is ChampionType:
				champions.append(entry)
			elif res is ChampionClass:
				classes.append(entry)
			elif res is ItemType:
				items.append(entry)
			elif res is SpellType:
				spells.append(entry)
			elif res is AIProfile:
				ai_profiles.append(entry)
			else:
				load_issues.append({"sev": "WARN", "where": path, "what": "unknown resource type %s" % res.get_class(),
					"fix": "give it a data script (UnitType, BuildingType...) or move it out of data/"})
	wizard_spells = _parse_wizard_spells()


static func _tres_files(dir_path: String) -> PackedStringArray:
	var out := PackedStringArray()
	var d := DirAccess.open(dir_path)
	if d == null:
		return out
	for f in d.get_files():
		var name := f.trim_suffix(".remap")
		if name.ends_with(".tres") and not out.has(name):
			out.append(name)
	out.sort()
	return out


## scripts/units/*wizard*.gd: `default_spell_ids = [&"a", &"b", &"c"]` -> {script: {kingdom, ids}}.
static func _parse_wizard_spells() -> Dictionary:
	var out := {}
	var re := RegEx.create_from_string("default_spell_ids\\s*(?::[^=\\n]*)?=\\s*\\[([^\\]]*)\\]")
	var id_re := RegEx.create_from_string("&\"(\\w+)\"")
	var kingdoms := {"wizard.gd": "fire", "shadow_wizard.gd": "shadow", "ice_wizard.gd": "ice", "nature_wizard.gd": "nature"}
	for file: String in kingdoms:
		var path := "res://scripts/units/" + file
		if not FileAccess.file_exists(path):
			continue
		var m := re.search(FileAccess.get_file_as_string(path))
		if m == null:
			continue
		var ids: Array[String] = []
		for im in id_re.search_all(m.get_string(1)):
			ids.append(im.get_string(1))
		out[file] = {"kingdom": kingdoms[file], "ids": ids}
	return out


# ---------------------------------------------------------------- run

func run_checks() -> void:
	report.counts_scanned = {"units": units.size(), "buildings": buildings.size(), "champions": champions.size(),
		"classes": classes.size(), "items": items.size(), "spells": spells.size(), "ai": ai_profiles.size()}
	check_load()
	check_fields()
	check_refs()
	check_keys()
	check_text()
	check_ai()
	check_balance()
	report.extras.assign([
		{"title": "Move bounds into the design tables", "text": "hard bounds are lab defaults; link each kind to its design table (units-fire-shadow.md, kingdom-*.md) so a stat outside the spec FAILs", "source": "data_lab_rules.gd HARD_BOUNDS"},
		{"title": "Translation table", "text": "move the INFO list of hard-coded UI strings (T7) into one strings table read through tr()", "source": "T7"},
		{"title": "Tooltips from data", "text": "command_card TRAIN_DESCRIPTIONS lives in code: a `description` field on UnitType would put it with the other text", "source": "T6"},
	])


func _all_entries() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	out.append_array(units)
	out.append_array(buildings)
	out.append_array(champions)
	out.append_array(classes)
	out.append_array(items)
	out.append_array(spells)
	out.append_array(ai_profiles)
	return out


static func _kind_of(res: Resource) -> String:
	if res is UnitType:
		return "unit"
	if res is BuildingType:
		return "building"
	if res is ChampionType:
		return "champion"
	if res is ChampionClass:
		return "class"
	if res is ItemType:
		return "item"
	if res is SpellType:
		return "spell"
	if res is AIProfile:
		return "ai"
	return "?"


static func _short(path: String) -> String:
	return path.replace("res://", "")


# ---------------------------------------------------------------- L: load

func check_load() -> void:
	var total := files_seen if files_seen > 0 else _all_entries().size()
	report.add_check("L1", "load", "Every data .tres loads", "each file under data/ loads as its data script", total,
		load_issues, "fix the file (broken ext_resource, renamed script, typo)")
	# L2 id == file name
	var issues: Array = []
	var n := 0
	for e: Dictionary in _all_entries():
		var res: Resource = e["res"]
		n += 1
		var rid := String(res.get(&"id"))
		var fname := String(e["path"]).get_file().get_basename()
		if rid == "":
			continue   # F1 reports the missing id
		if rid != fname:
			issues.append({"sev": "FAIL", "where": _short(e["path"]), "what": "id `%s` != file name `%s`" % [rid, fname],
				"fix": "rename the file or the id: find(id) loads <id>.tres"})
	report.add_check("L2", "load", "Ids match file names", "find(id) loads DIR/<id>.tres, so id == file name", n, issues,
		"rename one of them")
	if scan_code_tables:
		_check_code_lists()


## Ids listed in code tables must have a file (and data files should be listed where the code enumerates them).
func _check_code_lists() -> void:
	var issues: Array = []
	var n := 0
	var bids := {}
	for e: Dictionary in buildings:
		bids[String(e["res"].id)] = true
	for bid in BuildingType.ALL_IDS:
		n += 1
		if not bids.has(String(bid)):
			issues.append({"sev": "FAIL", "where": "BuildingType.ALL_IDS", "what": "`%s` has no data/buildings file" % bid,
				"fix": "add data/buildings/%s.tres or remove the id" % bid})
	for b: String in bids:
		if not BuildingType.ALL_IDS.has(StringName(b)):
			n += 1
			issues.append({"sev": "WARN", "where": "data/buildings/%s.tres" % b, "what": "not in BuildingType.ALL_IDS (never in a build menu, find by name misses it)",
				"fix": "add it to ALL_IDS (systems-coder)"})
	var cids := {}
	for e: Dictionary in champions:
		cids[String(e["res"].id)] = true
	for cid in ChampionType.IDS:
		n += 1
		if not cids.has(String(cid)):
			issues.append({"sev": "FAIL", "where": "ChampionType.IDS", "what": "`%s` has no data/champions file" % cid, "fix": "add the .tres"})
	var clids := {}
	for e: Dictionary in classes:
		clids[String(e["res"].id)] = true
	for cl in ChampionClass.IDS:
		n += 1
		if not clids.has(String(cl)):
			issues.append({"sev": "FAIL", "where": "ChampionClass.IDS", "what": "`%s` has no data/champion_classes file" % cl, "fix": "add the .tres"})
	var uids := {}
	for e: Dictionary in units:
		uids[String(e["res"].id)] = true
	for table_name: String in ["CREATURES", "BEASTS"]:
		var table: Dictionary = _creature_table(table_name)
		for k in table:
			n += 1
			if not uids.has(String(k)):
				issues.append({"sev": "FAIL", "where": "CreatureAbilities.%s" % table_name, "what": "`%s` has no data/units file" % k,
					"fix": "add data/units/%s.tres" % k})
	report.add_check("L3", "load", "Code id lists have data files", "BuildingType.ALL_IDS, ChampionType.IDS, ChampionClass.IDS, CreatureAbilities.CREATURES / BEASTS", n,
		issues, "add the file or the id")


static func _creature_table(table_name: String) -> Dictionary:
	return CreatureAbilities.CREATURES if table_name == "CREATURES" else CreatureAbilities.BEASTS


# ---------------------------------------------------------------- F: fields and bounds

func check_fields() -> void:
	var req: Array = []
	var nan: Array = []
	var neg: Array = []
	var bounds: Array = []
	var cons: Array = []
	var n := 0
	for e: Dictionary in _all_entries():
		var res: Resource = e["res"]
		var kind := _kind_of(res)
		var where := _short(e["path"])
		n += 1
		for field: String in Rules.REQUIRED.get(kind, []):
			if _is_empty(res.get(StringName(field))):
				req.append({"sev": "FAIL", "where": where, "what": "`%s` is empty" % field, "fix": "set %s" % field})
		for p: Dictionary in res.get_property_list():
			if not (int(p["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE) or not (int(p["usage"]) & PROPERTY_USAGE_STORAGE):
				continue
			var pname: String = p["name"]
			var v: Variant = res.get(StringName(pname))
			var bad_num := _find_nan(v)
			if bad_num != "":
				nan.append({"sev": "FAIL", "where": where, "what": "`%s` holds %s" % [pname, bad_num], "fix": "type a real number"})
			if (v is float or v is int) and _is_money_or_life(pname) and float(v) < 0.0 \
					and not (Rules.SENTINELS.has(pname) and is_equal_approx(float(v), float(Rules.SENTINELS[pname]))):
				neg.append({"sev": "FAIL", "where": where, "what": "`%s` = %s (negative)" % [pname, str(v)], "fix": "use 0 or a positive value"})
		var hb: Dictionary = Rules.HARD_BOUNDS.get(kind, {})
		for field: String in hb:
			var v2: Variant = res.get(StringName(field))
			if not (v2 is float or v2 is int):
				continue
			var lo: float = float(hb[field][0])
			var hi: float = float(hb[field][1])
			if float(v2) < lo or float(v2) > hi:
				bounds.append({"sev": "FAIL", "where": where, "what": "`%s` = %s outside [%s, %s]" % [field, str(v2), str(lo), str(hi)],
					"fix": "check the design table; widen HARD_BOUNDS only if the value is intended"})
		cons.append_array(_consistency(res, kind, where))
	report.add_check("F1", "fields", "Required fields set", "ids, names, HP, abilities... (Rules.REQUIRED per kind)", n, req, "fill the field")
	report.add_check("F2", "fields", "No NaN / inf", "every float, array and dictionary number is finite", n, nan, "type a real number")
	report.add_check("F3", "fields", "No negative cost / HP / damage / time", "cost, hp, damage, cooldown, time, range, speed, pop fields >= 0", n, neg, "use 0 or a positive value")
	report.add_check("F4", "fields", "Stats inside hard bounds", "Rules.HARD_BOUNDS per kind (broken values only)", n, bounds, "fix the number")
	report.add_check("F5", "fields", "Internal consistency", "rank arrays = max_rank, unlock levels ascending, recipes have parts, towers shoot, trainers train...", n, cons,
		"see each finding")
	_check_spread()


static func _is_empty(v: Variant) -> bool:
	if v == null:
		return true
	if v is String or v is StringName:
		return String(v).strip_edges() == ""
	if v is Array or v is PackedStringArray or v is Dictionary:
		return v.is_empty()
	if v is float or v is int:
		return float(v) == 0.0
	return false


static func _find_nan(v: Variant) -> String:
	if v is float:
		if is_nan(v):
			return "NaN"
		if is_inf(v):
			return "inf"
	elif v is Array or v is PackedFloat32Array or v is PackedFloat64Array:
		for x in v:
			var r := _find_nan(x)
			if r != "":
				return r
	elif v is Dictionary:
		for k in v:
			var r2 := _find_nan(v[k])
			if r2 != "":
				return r2
	elif v is Vector2 or v is Vector3:
		if not v.is_finite():
			return "NaN/inf"
	return ""


static func _is_money_or_life(field: String) -> bool:
	if field in ["armor", "flee_delta"] or field.ends_with("_pct") or field.ends_with("_delta"):
		return false
	for key: String in ["cost", "hp", "damage", "cooldown", "time", "range", "speed", "pop", "radius", "duration",
			"price", "amount", "interval", "lifetime", "xp", "height"]:
		if key in field:
			return true
	return false


func _consistency(res: Resource, kind: String, where: String) -> Array:
	var out: Array = []
	match kind:
		"unit":
			var u := res as UnitType
			if u.attack_damage > 0.0 and u.attack_range > 3.0 and u.projectile_speed <= 0.0:
				out.append({"sev": "FAIL", "where": where, "what": "ranged (range %.1f) with projectile_speed %.1f" % [u.attack_range, u.projectile_speed], "fix": "set projectile_speed > 0"})
			if u.support_kind != &"" and (u.support_amount <= 0.0 or u.support_interval <= 0.0 or u.support_range <= 0.0):
				out.append({"sev": "FAIL", "where": where, "what": "support `%s` with amount / interval / range 0" % u.support_kind, "fix": "set support_amount, support_interval, support_range"})
			if u.on_hit_status != &"" and u.on_hit_duration <= 0.0:
				out.append({"sev": "WARN", "where": where, "what": "on_hit_status `%s` with duration 0" % u.on_hit_status, "fix": "set on_hit_duration"})
			if u.faction in Rules.FACTIONS and not u.is_worker and not u.is_caravan and u.cost > 0:
				if u.kill_xp <= 0:
					out.append({"sev": "WARN", "where": where, "what": "trainable soldier with kill_xp 0", "fix": "levels.md: soldiers ~ cost / 2"})
				elif float(u.kill_xp) < float(u.cost) * Rules.KILL_XP_RATIO[0] or float(u.kill_xp) > float(u.cost) * Rules.KILL_XP_RATIO[1]:
					out.append({"sev": "WARN", "where": where, "what": "kill_xp %d for cost %d (levels.md: soldiers ~ cost / 2)" % [u.kill_xp, u.cost], "fix": "about %d" % (u.cost / 2)})
			if u.cost > 0 and u.train_time <= 0.0:
				out.append({"sev": "FAIL", "where": where, "what": "costs %d but train_time 0" % u.cost, "fix": "set train_time"})
		"building":
			var b := res as BuildingType
			if b.kind == &"tower" and (b.attack_damage <= 0.0 or b.attack_range <= 0.0):
				out.append({"sev": "FAIL", "where": where, "what": "tower without attack damage / range", "fix": "set attack_damage and attack_range"})
			if b.kind in [&"keep", &"barracks"] and b.trains.is_empty() and b.train_ids.is_empty():
				out.append({"sev": "FAIL", "where": where, "what": "%s trains nothing" % b.kind, "fix": "fill trains or train_ids"})
			if b.kind == &"house" and b.pop_bonus <= 0:
				out.append({"sev": "WARN", "where": where, "what": "house with pop_bonus 0", "fix": "set pop_bonus"})
			if b.is_buildable() and b.build_time <= 0.0:
				out.append({"sev": "FAIL", "where": where, "what": "buildable with build_time 0", "fix": "set build_time"})
			if b.aura_radius > 0.0 and b.aura_stats.is_empty():
				out.append({"sev": "WARN", "where": where, "what": "aura_radius %.1f with no aura_stats" % b.aura_radius, "fix": "set aura_stats"})
		"champion":
			var c := res as ChampionType
			if c.names.size() != 2:
				out.append({"sev": "WARN", "where": where, "what": "%d names (champions.md: name A and B)" % c.names.size(), "fix": "two sibling names"})
			for t: String in ["greed", "courage", "engage_radius"]:
				if not (c.traits.has(t) or c.traits.has(StringName(t))):
					out.append({"sev": "FAIL", "where": where, "what": "trait `%s` missing" % t, "fix": "champions.md 4.2"})
			if c.ability_ids.size() != 3:
				out.append({"sev": "WARN", "where": where, "what": "%d archetype abilities (champions.md 4.3: 3)" % c.ability_ids.size(), "fix": "3 ability ids"})
		"class":
			var k := res as ChampionClass
			if k.ability_ids.size() != 3 or k.unlock_levels.size() != 3:
				out.append({"sev": "FAIL", "where": where, "what": "%d skills / %d unlock levels (skills-rework.md: 3 / 3)" % [k.ability_ids.size(), k.unlock_levels.size()], "fix": "3 skills, 3 levels"})
			for i in range(1, k.unlock_levels.size()):
				if k.unlock_levels[i] < k.unlock_levels[i - 1]:
					out.append({"sev": "FAIL", "where": where, "what": "unlock_levels not ascending %s" % str(k.unlock_levels), "fix": "[2, 3, 5]"})
			# The tooltip repeats the weapon numbers ("13 damage every 0.95 s", "reach 2.4 m"): they must match the fields.
			var m := RegEx.create_from_string("(\\d+(?:\\.\\d+)?) damage every (\\d+(?:\\.\\d+)?) s").search(k.tooltip)
			if m and (not is_equal_approx(m.get_string(1).to_float(), k.attack_damage) or not is_equal_approx(m.get_string(2).to_float(), k.attack_cooldown)):
				out.append({"sev": "WARN", "where": where, "what": "tooltip says %s damage every %s s, fields say %s every %s s" % [m.get_string(1), m.get_string(2), _fmt(k.attack_damage), _fmt(k.attack_cooldown)], "fix": "update the tooltip"})
			var mr := RegEx.create_from_string("(?:reach|range) (\\d+(?:\\.\\d+)?) m").search(k.tooltip)
			if mr and not is_equal_approx(mr.get_string(1).to_float(), k.attack_range):
				out.append({"sev": "WARN", "where": where, "what": "tooltip says reach %s m, attack_range is %s" % [mr.get_string(1), _fmt(k.attack_range)], "fix": "update the tooltip"})
			if k.is_ranged != (k.attack_range > 3.0):
				out.append({"sev": "WARN", "where": where, "what": "is_ranged %s but attack_range %.1f (ranged means > 3 m)" % [k.is_ranged, k.attack_range], "fix": "match the flag and the range"})
		"item":
			var it := res as ItemType
			var needs_parts := it.tier == ItemType.Tier.MID or it.tier == ItemType.Tier.TOP
			if needs_parts and it.parts.is_empty():
				if it.campaign_only:
					out.append({"sev": "INFO", "where": where, "what": "campaign reward in a recipe tier with no parts", "fix": ""})
				else:
					out.append({"sev": "FAIL", "where": where, "what": "recipe tier with no parts", "fix": "items.md: list the parts"})
			if (it.passive_id != &"" or it.active_id != &"") and it.tooltip.strip_edges() == "":
				out.append({"sev": "FAIL", "where": where, "what": "has a passive / active but no tooltip", "fix": "write the description line"})
			if not needs_parts and not it.parts.is_empty():
				out.append({"sev": "WARN", "where": where, "what": "tier %d has parts" % it.tier, "fix": "components / consumables / artifacts have no parts"})
			for p in it.parts:
				if p == null:
					out.append({"sev": "FAIL", "where": where, "what": "a recipe part is null (missing file)", "fix": "fix the parts list"})
			if it.is_sold_at(ItemType.SOLD_BASE | ItemType.SOLD_PEDDLER) and it.total_cost() <= 0:
				out.append({"sev": "FAIL", "where": where, "what": "sold for 0", "fix": "set cost"})
			if it.has_active() and it.active_cooldown <= 0.0 and not it.is_consumable():
				out.append({"sev": "WARN", "where": where, "what": "active `%s` with cooldown 0" % it.active_id, "fix": "set active_cooldown"})
			if it.passive_id != &"" and not (it.passives.has(it.passive_id) or it.passives.has(String(it.passive_id))):
				out.append({"sev": "WARN", "where": where, "what": "passive_id `%s` not a key of passives" % it.passive_id, "fix": "add its numbers to passives"})
			if it.is_consumable() and it.stack_max <= 1:
				out.append({"sev": "INFO", "where": where, "what": "consumable with stack_max 1", "fix": ""})
		"spell":
			var s := res as SpellType
			var arrays := {"damage_by_rank": s.damage_by_rank, "cooldown_by_rank": s.cooldown_by_rank, "range_by_rank": s.range_by_rank,
				"radius_by_rank": s.radius_by_rank, "duration_by_rank": s.duration_by_rank, "shield_by_rank": s.shield_by_rank,
				"heal_by_rank": s.heal_by_rank, "summon_count_by_rank": s.summon_count_by_rank}
			for an: String in arrays:
				var arr: Array = arrays[an]
				if not arr.is_empty() and arr.size() != s.max_rank:
					out.append({"sev": "FAIL", "where": where, "what": "%s has %d values, max_rank %d" % [an, arr.size(), s.max_rank], "fix": "one value per rank"})
				if not arr.is_empty() and an == "damage_by_rank" and s.damage > 0.0 and not is_equal_approx(float(arr[0]), s.damage):
					out.append({"sev": "WARN", "where": where, "what": "damage %.1f != damage_by_rank[0] %.1f" % [s.damage, float(arr[0])], "fix": "the scalar is rank 1"})
			if s.level_required.size() != s.max_rank:
				out.append({"sev": "FAIL", "where": where, "what": "level_required has %d values, max_rank %d" % [s.level_required.size(), s.max_rank], "fix": "one level per rank"})
			for i in range(1, s.level_required.size()):
				if s.level_required[i] <= s.level_required[i - 1]:
					out.append({"sev": "FAIL", "where": where, "what": "level_required not rising %s" % str(s.level_required), "fix": "e.g. [1, 3, 5]"})
			if s.is_zone and s.tick_interval <= 0.0:
				out.append({"sev": "FAIL", "where": where, "what": "zone spell with tick_interval 0", "fix": "set tick_interval"})
			if s.cooldown <= 0.0:
				out.append({"sev": "WARN", "where": where, "what": "cooldown 0", "fix": "spells.md"})
	return out


## F6: WARN stats far from the median of their group (soldiers of the 4 kingdoms, camp creatures, beasts, champions).
func _check_spread() -> void:
	# Soldiers are compared with the same barracks slot of the other kingdoms (Z X C V = the same role), camp
	# creatures with strength >= 500 (the hollow guardian) with the beasts; attack_range is left out (melee vs ranged
	# is a role, not an outlier).
	var groups := {"slot Z": [], "slot X": [], "slot C": [], "slot V": [], "workers": [], "creatures": [], "beasts": [],
		"champions": [], "towers": []}
	var slot_of := {}
	for e: Dictionary in buildings:
		var b := e["res"] as BuildingType
		if b.kind == &"barracks":
			b.resolve_trains()
			for i in mini(b.trains.size(), 4):
				if b.trains[i]:
					slot_of[String(b.trains[i].id)] = "slot " + Rules.TRAIN_SLOT_KEYS[i]
	for e: Dictionary in units:
		var u := e["res"] as UnitType
		var uid := StringName(u.id)
		if CreatureAbilities.BEASTS.has(uid):
			groups["beasts"].append(e)
		elif CreatureAbilities.CREATURES.has(uid):
			groups["beasts" if float(CreatureAbilities.CREATURES[uid].get("strength", 0.0)) >= 500.0 else "creatures"].append(e)
		elif u.is_worker and u.faction in Rules.FACTIONS:
			groups["workers"].append(e)
		elif slot_of.has(String(uid)):
			groups[slot_of[String(uid)]].append(e)
	groups["champions"] = champions.duplicate()
	for e: Dictionary in buildings:
		if e["res"].kind == &"tower":
			groups["towers"].append(e)
	var fields := ["max_hp", "move_speed", "attack_damage", "attack_cooldown", "aggro_range", "cost"]
	var issues: Array = []
	var n := 0
	var spread_rows := "| Group | n | " + " | ".join(fields) + " |\n|---|---|" + "---|".repeat(fields.size()) + "\n"
	for g: String in groups:
		var members: Array = groups[g]
		n += members.size()
		var row := "| %s | %d |" % [g, members.size()]
		for f: String in fields:
			var vals: Array[float] = []
			for e: Dictionary in members:
				var v: Variant = e["res"].get(StringName(f))
				if v is float or v is int:
					vals.append(float(v))
			if vals.size() < Rules.SPREAD_MIN_GROUP:
				row += " - |"
				continue
			var med := _median(vals)
			row += " %s (%s-%s) |" % [_fmt(med), _fmt(vals.min()), _fmt(vals.max())]
			if med <= 0.0:
				continue
			for e: Dictionary in members:
				var v2: Variant = e["res"].get(StringName(f))
				if not (v2 is float or v2 is int) or float(v2) <= 0.0:
					continue
				var ratio := float(v2) / med
				if ratio > Rules.SPREAD_FACTOR or ratio < 1.0 / Rules.SPREAD_FACTOR:
					issues.append({"sev": "WARN", "where": _short(e["path"]), "what": "%s %s is %.1fx the %s median %s" % [f, _fmt(float(v2)), ratio, g, _fmt(med)],
						"fix": "check the design table; if intended, note it in the spec"})
		spread_rows += row + "\n"
	report.add_check("F6", "fields", "Stat outliers vs their group", "within x%.1f of the group median (barracks slot Z / X / C / V across kingdoms, workers, creatures, beasts, champions, towers)" % Rules.SPREAD_FACTOR,
		n, issues, "check the value against the design table", "", 0.5)
	report.add_table("Stat spread per group (median (min-max))", spread_rows)


static func _median(vals: Array[float]) -> float:
	var s := vals.duplicate()
	s.sort()
	var m := s.size() / 2
	return s[m] if s.size() % 2 == 1 else (s[m - 1] + s[m]) * 0.5


static func _fmt(v: float) -> String:
	if absf(v - roundf(v)) < 0.01:
		return str(int(roundf(v)))
	return "%.2f" % v


# ---------------------------------------------------------------- R: references

func check_refs() -> void:
	_check_models()
	_check_abilities()
	_check_item_refs()
	_check_status_and_stats()
	_check_spell_refs()
	_check_trains()


func _check_models() -> void:
	var issues: Array = []
	var bug: Array = []
	var n := 0
	for e: Dictionary in units + buildings + champions:
		var res: Resource = e["res"]
		var where := _short(e["path"])
		n += 1
		var ms: Variant = res.get(&"model_scene")
		var mp: Variant = res.get(&"model_path")
		var mp_s := String(mp) if mp != null else ""
		if ms is PackedScene:
			var rp := (ms as PackedScene).resource_path
			if rp != "" and not ResourceLoader.exists(rp):
				issues.append({"sev": "FAIL", "where": where, "what": "model_scene %s is missing" % rp, "fix": "fix the path"})
			if mp_s != "" and rp != "" and mp_s != rp:
				issues.append({"sev": "WARN", "where": where, "what": "model_path %s != model_scene %s" % [mp_s, rp], "fix": "keep one path"})
		if mp_s != "":
			if not ResourceLoader.exists(mp_s):
				issues.append({"sev": "WARN" if res is BuildingType else "INFO", "where": where, "what": "model_path %s does not exist yet" % mp_s,
					"fix": "the art task creates it; clear model_path if the plan changed"})
			elif ms == null:
				if res is UnitType:
					bug.append({"sev": "FAIL", "where": where, "what": "model_path %s exists but model_scene is empty (UnitType never loads model_path: the unit shows the placeholder)" % mp_s,
						"fix": "set model_scene = ExtResource(\"%s\") in the .tres (gameplay-coder)" % mp_s})
				else:
					bug.append({"sev": "INFO", "where": where, "what": "model loaded from model_path at runtime (get_model_scene)", "fix": ""})
		elif ms == null and res is UnitType and (res as UnitType).faction in Rules.FACTIONS:
			issues.append({"sev": "INFO", "where": where, "what": "no model_scene (code placeholder)", "fix": ""})
	report.add_check("R1", "refs", "Model files exist", "model_scene / model_path point at existing scenes", n, issues, "fix the path")
	report.add_check("R2", "refs", "model_path without model_scene", "UnitType never loads model_path: a finished model must be in model_scene (FAIL)", n, bug,
		"set model_scene in the .tres", "", 1.5)


func _check_abilities() -> void:
	var issues: Array = []
	var n := 0
	for table_name: String in ["CREATURES", "BEASTS"]:
		var table := _creature_table(table_name)
		for k in table:
			for aid in table[k].get("abilities", []):
				n += 1
				if not CreatureAbilities.ABILITIES.has(aid):
					issues.append({"sev": "FAIL", "where": "CreatureAbilities.%s.%s" % [table_name, k], "what": "ability `%s` unknown to CreatureAbilities.ABILITIES" % aid, "fix": "add it or fix the id"})
	for aid in CreatureAbilities.AUTOCAST_ORDER:
		n += 1
		if not CreatureAbilities.ABILITIES.has(aid):
			issues.append({"sev": "FAIL", "where": "CreatureAbilities.AUTOCAST_ORDER", "what": "`%s` unknown" % aid, "fix": "fix the id"})
	for e: Dictionary in champions:
		var c := e["res"] as ChampionType
		var where := _short(e["path"])
		for aid in c.ability_ids:
			n += 1
			if not ChampionAbilities.ABILITIES.has(aid):
				issues.append({"sev": "FAIL", "where": where, "what": "ability `%s` unknown to ChampionAbilities.ABILITIES" % aid, "fix": "fix the id"})
			elif ChampionAbilities.ABILITIES[aid].get("champion", &"") != c.id:
				issues.append({"sev": "WARN", "where": where, "what": "ability `%s` belongs to `%s`" % [aid, ChampionAbilities.ABILITIES[aid].get("champion", &"?")], "fix": "use this archetype's ids"})
		for key in c.ability_names:
			if not c.ability_ids.has(StringName(key)):
				issues.append({"sev": "WARN", "where": where, "what": "ability_names key `%s` is not one of its abilities" % key, "fix": "remove or fix the key"})
		for key in c.class_weights:
			n += 1
			if not ChampionClass.IDS.has(StringName(key)):
				issues.append({"sev": "FAIL", "where": where, "what": "class_weights key `%s` unknown" % key, "fix": "ChampionClass.IDS"})
		for key in c.barks:
			if not ChampionType.BARK_CHANCES.has(StringName(key)):
				issues.append({"sev": "WARN", "where": where, "what": "bark trigger `%s` never fires" % key, "fix": "BARK_CHANCES keys"})
		for trig in ChampionType.BARK_CHANCES:
			if not (c.barks.has(trig) or c.barks.has(String(trig))):
				issues.append({"sev": "WARN", "where": where, "what": "no bark for `%s`" % trig, "fix": "write the line"})
	for e: Dictionary in classes:
		var k := e["res"] as ChampionClass
		var where := _short(e["path"])
		var expected: Array = ChampionAbilities.CLASS_SKILLS.get(k.id, [])
		for i in k.ability_ids.size():
			var aid: StringName = k.ability_ids[i]
			n += 1
			if not ChampionAbilities.ABILITIES.has(aid):
				issues.append({"sev": "FAIL", "where": where, "what": "skill `%s` unknown to ChampionAbilities" % aid, "fix": "fix the id"})
				continue
			var info: Dictionary = ChampionAbilities.ABILITIES[aid]
			if info.get("class", &"") != k.id:
				issues.append({"sev": "WARN", "where": where, "what": "skill `%s` has class `%s`" % [aid, info.get("class", &"")], "fix": "use this class's skills"})
			if i < k.unlock_levels.size() and int(info.get("unlock", 0)) != k.unlock_levels[i]:
				issues.append({"sev": "WARN", "where": where, "what": "skill `%s` unlock %d in the .tres, %d in ChampionAbilities" % [aid, k.unlock_levels[i], int(info.get("unlock", 0))], "fix": "one source of truth"})
			if i < expected.size() and expected[i] != aid:
				issues.append({"sev": "WARN", "where": where, "what": "skill %d is `%s`, CLASS_SKILLS says `%s`" % [i + 1, aid, expected[i]], "fix": "align the .tres and CLASS_SKILLS"})
		if not Rules.ATTACK_STYLES.has(k.attack_style):
			issues.append({"sev": "FAIL", "where": where, "what": "attack_style `%s` unknown" % k.attack_style, "fix": str(Rules.ATTACK_STYLES)})
		if not ChampionClass.BOUNTY_KINDS.has(k.bounty_kind):
			issues.append({"sev": "FAIL", "where": where, "what": "bounty_kind `%s` unknown" % k.bounty_kind, "fix": str(ChampionClass.BOUNTY_KINDS)})
	for aid in ChampionAbilities.AUTOCAST_ORDER:
		n += 1
		if not ChampionAbilities.ABILITIES.has(aid):
			issues.append({"sev": "FAIL", "where": "ChampionAbilities.AUTOCAST_ORDER", "what": "`%s` unknown" % aid, "fix": "fix the id"})
	for aid in ChampionAbilities.ABILITIES:
		if not ChampionAbilities.AUTOCAST_ORDER.has(aid):
			issues.append({"sev": "WARN", "where": "ChampionAbilities.AUTOCAST_ORDER", "what": "`%s` is never autocast" % aid, "fix": "add it to AUTOCAST_ORDER"})
	report.add_check("R3", "refs", "Ability ids known", "creature / beast / champion / class ability ids exist in CreatureAbilities / ChampionAbilities, owners match", n, issues, "fix the id")


func _item_known(iid: Variant) -> bool:
	return _item(iid) != null


func _item(iid: Variant) -> ItemType:
	for e: Dictionary in items:
		if String(e["res"].id) == String(iid):
			return e["res"] as ItemType
	return null


## "" when a bot / champion can buy `iid` in a skirmish, else why not.
func _unbuyable_reason(iid: Variant) -> String:
	var it := _item(iid)
	if it == null:
		return ""
	if not it.available:
		return "not available yet (available = false)"
	if it.campaign_only:
		return "campaign only"
	if it.is_artifact:
		return "an artifact (never sold)"
	if it.sold_at == 0:
		return "sold nowhere (sold_at = 0)"
	return ""


func _check_item_refs() -> void:
	var issues: Array = []
	var n := 0
	for e: Dictionary in champions:
		var c := e["res"] as ChampionType
		for iid in c.wishlist:
			n += 1
			if not _item_known(iid):
				issues.append({"sev": "FAIL", "where": _short(e["path"]), "what": "wishlist item `%s` unknown" % iid, "fix": "an id from data/items"})
			elif _unbuyable_reason(iid) != "":
				issues.append({"sev": "WARN", "where": _short(e["path"]), "what": "wishlist item `%s` is %s" % [iid, _unbuyable_reason(iid)], "fix": "a shop item"})
	for e: Dictionary in items:
		var it := e["res"] as ItemType
		if it.active_id != &"":
			n += 1
			if not (ItemActives.ACTIVES.has(it.active_id) or ItemActives.ALIASES.has(it.active_id)):
				issues.append({"sev": "FAIL", "where": _short(e["path"]), "what": "active `%s` unknown to ItemActives" % it.active_id, "fix": "add it to ItemActives.ACTIVES or fix the id"})
	report.add_check("R4", "refs", "Item ids known", "champion wishlists, item actives (ItemActives.ACTIVES / ALIASES)", n, issues, "fix the id")


func _check_status_and_stats() -> void:
	var statuses: Array = Unit.STATUSES.keys()
	statuses.append_array(Rules.EXTRA_STATUSES)
	var stat_names: Array = Unit.STAT_NAMES.duplicate()
	var issues: Array = []
	var n := 0
	var check_status := func(where: String, s: StringName) -> void:
		if s != &"" and not statuses.has(s):
			issues.append({"sev": "FAIL", "where": where, "what": "status `%s` unknown to Unit.STATUSES" % s, "fix": "a known status"})
	var check_stats := func(where: String, d: Dictionary) -> void:
		for key in d:
			var base := String(key).trim_suffix("_pct")
			if not stat_names.has(StringName(base)):
				issues.append({"sev": "FAIL", "where": where, "what": "stat `%s` unknown to Unit.STAT_NAMES" % key, "fix": "Stats contract names (+ _pct)"})
	for e: Dictionary in units:
		n += 1
		check_status.call(_short(e["path"]), e["res"].on_hit_status)
		if not Rules.SUPPORT_KINDS.has(e["res"].support_kind):
			issues.append({"sev": "FAIL", "where": _short(e["path"]), "what": "support_kind `%s` unknown" % e["res"].support_kind, "fix": "shield / heal"})
		if not Rules.UNIT_FACTIONS.has(e["res"].faction):
			issues.append({"sev": "FAIL", "where": _short(e["path"]), "what": "faction `%s` unknown" % e["res"].faction, "fix": str(Rules.UNIT_FACTIONS)})
	for e: Dictionary in buildings:
		n += 1
		check_status.call(_short(e["path"]), e["res"].on_hit_status)
		check_stats.call(_short(e["path"]), e["res"].aura_stats)
		if not Rules.FACTIONS.has(e["res"].faction):
			issues.append({"sev": "FAIL", "where": _short(e["path"]), "what": "faction `%s` unknown" % e["res"].faction, "fix": str(Rules.FACTIONS)})
		if not Rules.BUILDING_KINDS.has(e["res"].kind):
			issues.append({"sev": "FAIL", "where": _short(e["path"]), "what": "kind `%s` unknown" % e["res"].kind, "fix": str(Rules.BUILDING_KINDS)})
		if e["res"].requires_kind != &"" and not Rules.BUILDING_KINDS.has(e["res"].requires_kind):
			issues.append({"sev": "FAIL", "where": _short(e["path"]), "what": "requires_kind `%s` unknown (tech prerequisite)" % e["res"].requires_kind, "fix": str(Rules.BUILDING_KINDS)})
	for e: Dictionary in spells:
		n += 1
		check_status.call(_short(e["path"]), e["res"].status_id)
		check_status.call(_short(e["path"]), e["res"].secondary_status_id)
	for e: Dictionary in items:
		n += 1
		check_stats.call(_short(e["path"]), e["res"].stats)
	for e: Dictionary in classes:
		n += 1
		check_stats.call(_short(e["path"]), e["res"].stats)
	if scan_code_tables:
		for wid in GoldBank.WARES:
			n += 1
			var w: Dictionary = GoldBank.WARES[wid]
			check_stats.call("GoldBank.WARES.%s" % wid, w.get("stats", {}))
			if int(w.get("price", 0)) <= 0 or String(w.get("name", "")) == "" or String(w.get("text", "")) == "":
				issues.append({"sev": "FAIL", "where": "GoldBank.WARES.%s" % wid, "what": "price / name / text missing", "fix": "fill the ware row"})
			if not [&"caravans", &"buildings", &"soldiers", &"workers", &"units"].has(w.get("filter", &"")):
				issues.append({"sev": "WARN", "where": "GoldBank.WARES.%s" % wid, "what": "filter `%s` unusual" % w.get("filter", &""), "fix": "caravans / buildings / soldiers"})
	report.add_check("R5", "refs", "Statuses, stats, kinds known", "statuses in Unit.STATUSES, stat keys in Unit.STAT_NAMES (+ _pct), factions / kinds / wares valid", n, issues, "fix the name")


func _check_spell_refs() -> void:
	var issues: Array = []
	var n := 0
	var sids := {}
	for e: Dictionary in spells:
		sids[String(e["res"].id)] = e["res"]
		var s := e["res"] as SpellType
		if s.summon_unit_id != &"":
			n += 1
			if UnitType.find(String(s.summon_unit_id)) == null:
				issues.append({"sev": "FAIL", "where": _short(e["path"]), "what": "summon_unit_id `%s` has no data/units file" % s.summon_unit_id, "fix": "fix the id"})
	var used := {}
	for file: String in wizard_spells:
		for sid: String in wizard_spells[file]["ids"]:
			n += 1
			used[sid] = true
			if not sids.has(sid):
				issues.append({"sev": "FAIL", "where": "scripts/units/" + file, "what": "default spell `%s` has no data/spells file" % sid, "fix": "add the .tres or fix the id"})
	for sid: String in sids:
		if not used.has(sid) and not wizard_spells.is_empty():
			issues.append({"sev": "WARN", "where": "data/spells/%s.tres" % sid, "what": "no wizard casts it (default_spell_ids)", "fix": "remove it or give it to a wizard"})
	report.add_check("R6", "refs", "Spell references", "wizard default_spell_ids exist, summon ids exist, every spell has a caster", n, issues, "fix the id")


func _check_trains() -> void:
	var issues: Array = []
	var n := 0
	for e: Dictionary in buildings:
		var b := e["res"] as BuildingType
		for i in b.trains.size():
			n += 1
			if b.trains[i] == null:
				issues.append({"sev": "FAIL", "where": _short(e["path"]), "what": "trains[%d] is null (missing unit file)" % i, "fix": "fix the list"})
			elif b.trains[i].faction != b.faction and b.trains[i].faction != &"" and not b.trains[i].is_worker:
				issues.append({"sev": "WARN", "where": _short(e["path"]), "what": "trains `%s` of faction `%s`" % [b.trains[i].id, b.trains[i].faction], "fix": "check the kingdom"})
		for uid in b.train_ids:
			n += 1
			if UnitType.find(String(uid)) == null:
				issues.append({"sev": "FAIL", "where": _short(e["path"]), "what": "train_ids `%s` unknown" % uid, "fix": "fix the id"})
	report.add_check("R7", "refs", "Training lists resolve", "every trains / train_ids entry is a unit file", n, issues, "fix the list")
	report.add_info("R8", "refs", "Icons / sounds / research", "no icon or sound paths in data yet (icons are icon_abbrev letters, sounds are generated by name); research.md has no data table in code yet (tech prerequisites checked: requires_kind, spell level_required)")


# ---------------------------------------------------------------- K: hotkeys

func check_keys() -> void:
	# K1 training slots (Z X C V B N M , by index): at most 8 per building's data list, and each listed unit's card_key
	# is the letter of its slot there (the card shows the slot's letter; card_key documents it). Slots the code adds
	# (Hall bowman / new units, Stables, the keep's tier-3 unit) are checked by tests/test_ui_card_hotkeys.gd.
	var issues: Array = []
	var n := 0
	for e: Dictionary in buildings:
		var b := e["res"] as BuildingType
		var listed: Array = []
		if not b.trains.is_empty():
			listed = b.trains
		else:
			for uid in b.train_ids:
				listed.append(UnitType.find(String(uid)))
		if listed.is_empty():
			continue
		n += 1
		if listed.size() > Rules.TRAIN_SLOT_KEYS.size():
			issues.append({"sev": "FAIL", "where": _short(e["path"]), "what": "%d trainable units, only %d slot keys %s" % [listed.size(), Rules.TRAIN_SLOT_KEYS.size(), str(Rules.TRAIN_SLOT_KEYS)], "fix": "at most 8 per building"})
		var seen := {}
		for i in listed.size():
			var t: UnitType = listed[i]
			if t == null or t.card_key == "":
				continue
			var k := t.card_key.to_upper()
			if seen.has(k):
				issues.append({"sev": "FAIL", "where": _short(e["path"]), "what": "card_key %s used by `%s` and `%s`" % [k, seen[k], t.id], "fix": "unique keys per card"})
			seen[k] = t.id
			if i < Rules.TRAIN_SLOT_KEYS.size() and k != Rules.TRAIN_SLOT_KEYS[i]:
				issues.append({"sev": "WARN", "where": "data/units/%s.tres" % t.id, "what": "card_key %s but `%s` trains it on slot %d = %s" % [k, b.id, i + 1, Rules.TRAIN_SLOT_KEYS[i]], "fix": "card_key = the slot letter"})
	report.add_check("K1", "keys", "Training card keys", "<= 8 units per building (Z X C V B N M , by slot), card_key = the slot letter, unique per card", n, issues, "fix the card")
	# K2 build menu per faction
	issues = []
	n = 0
	var per_faction := {}
	for e: Dictionary in buildings:
		var b := e["res"] as BuildingType
		if b.hotkey_label == "":
			if b.is_buildable():
				issues.append({"sev": "WARN", "where": _short(e["path"]), "what": "buildable but no hotkey_label (not reachable by key)", "fix": "give it a free build-menu key"})
			continue
		n += 1
		var k := b.hotkey_label.to_upper()
		if not Rules.BUILD_MENU_KEYS.has(k):
			issues.append({"sev": "FAIL", "where": _short(e["path"]), "what": "hotkey_label %s is not a build-menu slot key %s" % [k, str(Rules.BUILD_MENU_KEYS)], "fix": "command_card BUILD_KEY_SLOTS"})
		var fk := String(b.faction)
		if not per_faction.has(fk):
			per_faction[fk] = {}
		if per_faction[fk].has(k):
			issues.append({"sev": "FAIL", "where": _short(e["path"]), "what": "build key %s also used by `%s` (%s build menu)" % [k, per_faction[fk][k], fk], "fix": "one key per building in a menu"})
		per_faction[fk][k] = b.id
		if not b.is_buildable():
			issues.append({"sev": "WARN", "where": _short(e["path"]), "what": "hotkey_label %s on a building that is not buildable" % k, "fix": "clear it"})
	report.add_check("K2", "keys", "Build menu keys", "hotkey_label in Z X C V B N, unique per kingdom build menu (trade on = all entries)", n, issues, "fix the key")
	# K3 spell keys
	issues = []
	n = 0
	for file: String in wizard_spells:
		var ids: Array = wizard_spells[file]["ids"]
		var seen := {}
		for i in ids.size():
			n += 1
			var s := SpellType.find(StringName(ids[i]))
			if s == null:
				continue
			var want: String = Rules.SPELL_KEYS[i] if i < Rules.SPELL_KEYS.size() else "?"
			if s.hotkey_label.to_upper() != want:
				issues.append({"sev": "FAIL", "where": "data/spells/%s.tres" % ids[i], "what": "hotkey_label %s but slot %d of %s is %s" % [s.hotkey_label, i + 1, file, want], "fix": "slot order F / Q / E"})
			if seen.has(s.hotkey_label):
				issues.append({"sev": "FAIL", "where": "scripts/units/" + file, "what": "two spells on key %s" % s.hotkey_label, "fix": "F / Q / E once each"})
			seen[s.hotkey_label] = true
	report.add_check("K3", "keys", "Spell keys", "each wizard's default_spell_ids are F, Q, E in order", n, issues, "fix hotkey_label")
	# K4 reserved letters (Hero WASD + spells) and global unit keys
	issues = []
	n = 0
	for e: Dictionary in buildings:
		var k2 := String(e["res"].hotkey_label).to_upper()
		if k2 == "":
			continue
		n += 1
		if Rules.RESERVED_LETTERS.has(k2):
			issues.append({"sev": "FAIL", "where": _short(e["path"]), "what": "build key %s is reserved (W A S D walk in Hero WASD, Q E F spells)" % k2, "fix": "Z X C V B"})
	for e: Dictionary in units:
		var k3 := String(e["res"].card_key).to_upper()
		if k3 == "":
			continue
		n += 1
		# card_key documents the unit's training slot letter (the card shows the slot's letter): a reserved letter or a
		# letter that is no training slot is stale data.
		if Rules.RESERVED_LETTERS.has(k3):
			issues.append({"sev": "WARN", "where": _short(e["path"]), "what": "card_key %s is a reserved letter (W A S D walk in Hero WASD, Q E F spells)" % k3,
				"fix": "set the slot letter (Z X C V B N M ,)"})
		elif not Rules.TRAIN_SLOT_KEYS.has(k3):
			issues.append({"sev": "WARN", "where": _short(e["path"]), "what": "card_key %s is not a training slot key %s" % [k3, str(Rules.TRAIN_SLOT_KEYS)],
				"fix": "set the slot letter"})
	report.add_check("K4", "keys", "Reserved keys respected", "no data key on W A S D Q E F (Controls setting Classic / Hero WASD, CLAUDE.md Keys); card_key a slot letter", n, issues, "pick a free key")


# ---------------------------------------------------------------- T: text

func check_text() -> void:
	var tt := TextTools.new()
	var texts: Array[Dictionary] = []   # {where, field, text, kind: name|tooltip|abbrev|line}
	for e: Dictionary in units:
		texts.append({"where": _short(e["path"]), "field": "display_name", "text": e["res"].display_name, "kind": "name"})
	for e: Dictionary in buildings:
		texts.append({"where": _short(e["path"]), "field": "display_name", "text": e["res"].display_name, "kind": "name"})
	for e: Dictionary in champions:
		var c := e["res"] as ChampionType
		for nm in c.names:
			texts.append({"where": _short(e["path"]), "field": "names", "text": nm, "kind": "name"})
		texts.append({"where": _short(e["path"]), "field": "title", "text": c.title, "kind": "name"})
		texts.append({"where": _short(e["path"]), "field": "role", "text": c.role, "kind": "line"})
		for f: String in ["personality_line", "likes", "fears"]:
			texts.append({"where": _short(e["path"]), "field": f, "text": String(c.get(StringName(f))), "kind": "tooltip"})
		for key in c.barks:
			texts.append({"where": _short(e["path"]), "field": "barks.%s" % key, "text": String(c.barks[key]), "kind": "line"})
		for key in c.ability_texts:
			texts.append({"where": _short(e["path"]), "field": "ability_texts.%s" % key, "text": String(c.ability_texts[key]), "kind": "tooltip"})
	for e: Dictionary in classes:
		texts.append({"where": _short(e["path"]), "field": "display_name", "text": e["res"].display_name, "kind": "name"})
		texts.append({"where": _short(e["path"]), "field": "tooltip", "text": e["res"].tooltip, "kind": "tooltip"})
		texts.append({"where": _short(e["path"]), "field": "icon_abbrev", "text": e["res"].icon_abbrev, "kind": "abbrev"})
	for e: Dictionary in items:
		texts.append({"where": _short(e["path"]), "field": "display_name", "text": e["res"].display_name, "kind": "name"})
		# Components with stats only have no description line (the UI prints the stats): tooltip optional there.
		if e["res"].tooltip != "" or e["res"].passive_id != &"" or e["res"].active_id != &"":
			texts.append({"where": _short(e["path"]), "field": "tooltip", "text": e["res"].tooltip, "kind": "tooltip"})
		texts.append({"where": _short(e["path"]), "field": "icon_abbrev", "text": e["res"].icon_abbrev, "kind": "abbrev"})
	for e: Dictionary in spells:
		texts.append({"where": _short(e["path"]), "field": "display_name", "text": e["res"].display_name, "kind": "name"})
		texts.append({"where": _short(e["path"]), "field": "tooltip", "text": e["res"].tooltip, "kind": "tooltip"})
		texts.append({"where": _short(e["path"]), "field": "icon_abbrev", "text": e["res"].icon_abbrev, "kind": "abbrev"})
	if scan_code_tables:
		for aid in ChampionAbilities.ABILITIES:
			var a: Dictionary = ChampionAbilities.ABILITIES[aid]
			texts.append({"where": "ChampionAbilities.%s" % aid, "field": "name", "text": String(a.get("name", "")), "kind": "name"})
			texts.append({"where": "ChampionAbilities.%s" % aid, "field": "text", "text": String(a.get("text", "")), "kind": "tooltip"})
		for wid in GoldBank.WARES:
			texts.append({"where": "GoldBank.WARES.%s" % wid, "field": "text", "text": String(GoldBank.WARES[wid].get("text", "")), "kind": "tooltip"})
	var missing: Array = []
	var bad: Array = []
	var width: Array = []
	var n := texts.size()
	for t: Dictionary in texts:
		var s: String = t["text"]
		var tag := "%s `%s`" % [t["field"], s.left(60)]
		if s.strip_edges() == "":
			missing.append({"sev": "FAIL" if t["kind"] in ["name", "tooltip"] else "WARN", "where": t["where"], "what": "%s is empty" % t["field"], "fix": "write it"})
			continue
		if tt.has_placeholder(s):
			bad.append({"sev": "FAIL", "where": t["where"], "what": "placeholder text in %s" % tag, "fix": "write the real text"})
		if tt.has_mojibake(s):
			bad.append({"sev": "FAIL", "where": t["where"], "what": "broken encoding in %s" % tag, "fix": "re-save as UTF-8 (· and é must stay one character)"})
		if s != s.strip_edges() or "  " in s:
			bad.append({"sev": "WARN", "where": t["where"], "what": "extra spaces in %s" % t["field"], "fix": "trim"})
		match t["kind"]:
			"name":
				var px := tt.width_px(s, Rules.NAME_FONT_SIZE)
				if px > Rules.NAME_MAX_PX:
					width.append({"sev": "WARN", "where": t["where"], "what": "%s is %.0f px at %d px (limit %.0f)" % [tag, px, Rules.NAME_FONT_SIZE, Rules.NAME_MAX_PX], "fix": "shorten it"})
			"tooltip":
				var lines := tt.wrapped_lines(s, Rules.TOOLTIP_FONT_SIZE, Rules.TOOLTIP_WIDTH_PX)
				if lines > Rules.TOOLTIP_MAX_LINES:
					width.append({"sev": "WARN", "where": t["where"], "what": "%s wraps to %d lines at %.0f px (limit %d)" % [t["field"], lines, Rules.TOOLTIP_WIDTH_PX, Rules.TOOLTIP_MAX_LINES], "fix": "cut words or split it"})
			"abbrev":
				if s.length() > Rules.ABBREV_MAX:
					width.append({"sev": "WARN", "where": t["where"], "what": "icon_abbrev `%s` longer than %d" % [s, Rules.ABBREV_MAX], "fix": "2-3 letters"})
			"line":
				var px2 := tt.width_px(s, Rules.TOOLTIP_FONT_SIZE)
				if px2 > Rules.TOOLTIP_WIDTH_PX * 2.0:
					width.append({"sev": "WARN", "where": t["where"], "what": "%s is %.0f px at %d px (2 lines max)" % [tag, px2, Rules.TOOLTIP_FONT_SIZE], "fix": "shorten it"})
	_check_tooltip_numbers(tt)
	# T4: the same display name on two resources of one kind reads as the same thing in the UI.
	var dup: Array = []
	var nd := 0
	for lst: Array in [units, buildings, items, spells, classes]:
		var seen := {}
		for e: Dictionary in lst:
			var dn := String(e["res"].get(&"display_name")).strip_edges().to_lower()
			if dn == "":
				continue
			nd += 1
			if seen.has(dn):
				dup.append({"sev": "WARN", "where": _short(e["path"]), "what": "display name `%s` also used by %s" % [e["res"].display_name, seen[dn]], "fix": "make it unique"})
			seen[dn] = _short(e["path"])
	report.add_check("T4", "text", "Display names unique per kind", "no two units / buildings / items / spells / classes share a name", nd, dup, "rename one")
	report.add_check("T1", "text", "Names and tooltips exist", "every display name / tooltip / ability text / bark is written", n, missing, "write it")
	report.add_check("T2", "text", "No placeholder or broken text", "no TODO / TBD / xxx / lorem, no mojibake (Â·, Ã©), no double spaces", n, bad, "fix the text")
	report.add_check("T3", "text", "Text fits its UI width", "names <= %.0f px at %d px; tooltips <= %d lines at %.0f px / %d px; abbrev <= %d letters (font: %s)" % [Rules.NAME_MAX_PX, Rules.NAME_FONT_SIZE, Rules.TOOLTIP_MAX_LINES, Rules.TOOLTIP_WIDTH_PX, Rules.TOOLTIP_FONT_SIZE, Rules.ABBREV_MAX, tt.font_name()],
		n, width, "shorten it")
	if scan_ui:
		var scan := tt.scan_ui_strings(Rules.UI_DIRS)
		var top: Array[String] = []
		for r: Dictionary in scan.get("top", []):
			top.append("%s (%d)" % [String(r["file"]).get_file(), int(r["n"])])
		report.add_info("T7", "text", "Hard-coded UI strings (French readiness)", "%d literal UI strings (%d distinct) in %d scripts under scripts/ui/, %d wrapped in tr(); no translation table yet; biggest: %s" % [scan["total"], scan.get("unique", 0), scan["files"], scan["tr"], ", ".join(top)],
			"INFO only. Next step (ui-coder): ui_strings.csv in this folder = key, file, line, text of every literal: load it as a Translation (CSV import) and wrap the literals in tr(KEY), biggest scripts first")
		report.add_table("Hard-coded UI strings per script (T7, INFO)", scan["markdown"])
		report.extra_files["ui_strings.csv"] = String(scan.get("csv", ""))


## T5: every number a tooltip prints must exist in the data next to it (so a balance change that forgets the text
## shows up). Champion abilities (text vs the ChampionAbilities row, + the archetype's ability_texts override), items
## (tooltip vs stats / passives / active params / cooldown) and spells (tooltip vs rank-1 fields).
func _check_tooltip_numbers(tt: RefCounted) -> void:
	var issues: Array = []
	var n := 0
	# Status effects print their own numbers ("hobbled (-1.5 speed)" = the smoulder modifier): allowed in every text.
	var status_nums: Array[float] = []
	for sid in Unit.STATUSES:
		status_nums.append_array(_numbers_of(Unit.STATUSES[sid].get("mods", {})))
	if scan_code_tables:
		for aid in ChampionAbilities.ABILITIES:
			var a: Dictionary = ChampionAbilities.ABILITIES[aid]
			n += 1
			var nums_a := _numbers_of(a)
			nums_a.append_array(status_nums)
			for miss in tt.numbers_missing(String(a.get("text", "")), nums_a):
				issues.append({"sev": "WARN", "where": "ChampionAbilities.%s" % aid, "what": "text says %s, not in the ability's numbers" % miss, "fix": "update the text or the number"})
		for e: Dictionary in champions:
			var c := e["res"] as ChampionType
			for key in c.ability_texts:
				n += 1
				var row: Dictionary = ChampionAbilities.ABILITIES.get(StringName(key), {})
				for miss in tt.numbers_missing(String(c.ability_texts[key]), _numbers_of(row)):
					issues.append({"sev": "WARN", "where": "%s ability_texts.%s" % [_short(e["path"]), key], "what": "text says %s, not in ChampionAbilities.%s" % [miss, key], "fix": "update the text"})
	for e: Dictionary in items:
		var it := e["res"] as ItemType
		if it.tooltip == "":
			continue
		n += 1
		var nums := _numbers_of([it.stats, it.passives, it.active_params, it.active_cooldown, it.cost, it.total_cost(), it.stack_max])
		for miss in tt.numbers_missing(it.tooltip, nums):
			issues.append({"sev": "WARN", "where": _short(e["path"]), "what": "tooltip says %s, not in the item's numbers" % miss, "fix": "update the tooltip or the data"})
	for e: Dictionary in spells:
		var s := e["res"] as SpellType
		if s.tooltip == "":
			continue
		n += 1
		var fields := [s.damage, s.cooldown, s.cast_range, s.radius, s.duration, s.heal_ratio, s.shield_amount, s.heal_amount,
			s.summon_count, s.tick_interval, s.secondary_duration, s.mana_cost, s.total_damage_at(1)]
		var nums_s := _numbers_of(fields)
		nums_s.append_array(status_nums)
		for miss in tt.numbers_missing(s.tooltip, nums_s):
			issues.append({"sev": "WARN", "where": _short(e["path"]), "what": "tooltip says %s, not in the rank-1 fields" % miss, "fix": "update the tooltip"})
	report.add_check("T5", "text", "Tooltip numbers match the data", "every number printed in an ability / item / spell text exists in its data (also x100 for shares, products of two values)", n, issues,
		"update the text after a balance change", "", 0.75)


## Every number inside `v` (nested dictionaries / arrays), for T5.
static func _numbers_of(v: Variant) -> Array[float]:
	var out: Array[float] = []
	if v is float or v is int:
		out.append(float(v))
	elif v is Dictionary:
		for k in v:
			out.append_array(_numbers_of(v[k]))
	elif v is Array or v is PackedFloat32Array or v is PackedInt32Array:
		for x in v:
			out.append_array(_numbers_of(x))
	return out


# ---------------------------------------------------------------- A: AI profiles

func check_ai() -> void:
	# A1: every kingdom resolves easy / normal / hard.
	var issues: Array = []
	var resolved: Array[Dictionary] = []   # {where, profile, kingdom, diff}
	var n := 0
	var src_rows := "| Kingdom | Easy | Normal | Hard |\n|---|---|---|---|\n"
	for k in Rules.FACTIONS:
		var pid := AIProfile.id_for_faction(k)
		var row := "| %s (`%s`) |" % [k, pid]
		for d in 3:
			n += 1
			var p := AIProfile.for_id(pid, d)
			var file := AIProfile.DATA_PATH % (String(pid).trim_suffix("_default") + "_" + AIProfile.DIFFICULTY_NAMES[d])
			var src := "data" if ResourceLoader.exists(file) else "code"
			row += " %s (`%s`) |" % [src, p.id if p else &"null"]
			if p == null:
				issues.append({"sev": "FAIL", "where": "%s %s" % [k, AIProfile.DIFFICULTY_NAMES[d]], "what": "no profile", "fix": "add %s" % file})
				continue
			resolved.append({"where": "%s %s (%s)" % [k, AIProfile.DIFFICULTY_NAMES[d], _short(file) if src == "data" else "AIProfile code preset"], "profile": p, "kingdom": k, "diff": d})
		src_rows += row + "\n"
	report.add_check("A1", "ai", "Every kingdom has easy / normal / hard", "AIProfile.for_id(id_for_faction(k), 0..2) returns a profile (data/ai .tres or code preset)", n, issues, "add the .tres")
	report.add_table("AI profile sources (A1)", src_rows + "\nFire uses the Shadow bot (`shadow_default`, ai.md), built in code; Ice / Nature read data/ai/*.tres.")
	for e: Dictionary in ai_profiles:
		var p2 := e["res"] as AIProfile
		if not resolved.any(func(r: Dictionary) -> bool: return String(r["where"]).contains(_short(e["path"]))):
			resolved.append({"where": _short(e["path"]), "profile": p2, "kingdom": &"", "diff": -1})
	# A2 knob bounds, A3 references, A4 mixes
	var bounds: Array = []
	var refs: Array = []
	var mixes: Array = []
	var item_ids := {}
	for e: Dictionary in items:
		item_ids[String(e["res"].id)] = true
	for r: Dictionary in resolved:
		var p: AIProfile = r["profile"]
		var where: String = r["where"]
		for knob: String in Rules.AI_BOUNDS:
			var v: Variant = p.get(StringName(knob))
			if v == null:
				bounds.append({"sev": "WARN", "where": where, "what": "knob `%s` does not exist on AIProfile" % knob, "fix": "update Rules.AI_BOUNDS"})
				continue
			var lo: float = float(Rules.AI_BOUNDS[knob][0])
			var hi: float = float(Rules.AI_BOUNDS[knob][1])
			if is_nan(float(v)) or float(v) < lo or float(v) > hi:
				bounds.append({"sev": "FAIL", "where": where, "what": "%s = %s outside [%s, %s]" % [knob, str(v), str(lo), str(hi)], "fix": "ai.md / ai_profile.gd range"})
		if p.attack_ratio_floor > p.attack_ratio:
			bounds.append({"sev": "WARN", "where": where, "what": "attack_ratio_floor %.2f > attack_ratio %.2f (patience raises the bar)" % [p.attack_ratio_floor, p.attack_ratio], "fix": "floor <= ratio"})
		if p.caravan_target_late < p.caravan_target:
			bounds.append({"sev": "WARN", "where": where, "what": "caravan_target_late %d < caravan_target %d" % [p.caravan_target_late, p.caravan_target], "fix": "late >= early"})
		if p.tower2_time < p.tower1_time:
			bounds.append({"sev": "WARN", "where": where, "what": "tower2_time before tower1_time", "fix": "S2 after S1"})
		for iid in p.item_build:
			if not item_ids.is_empty() and not item_ids.has(String(iid)):
				refs.append({"sev": "FAIL", "where": where, "what": "item_build `%s` unknown" % iid, "fix": "an id from data/items"})
			elif _unbuyable_reason(iid) != "" and p.profile_id != &"mission_01":
				refs.append({"sev": "WARN", "where": where, "what": "item_build `%s` is %s: the bot stalls on it" % [iid, _unbuyable_reason(iid)], "fix": "a shop item"})
		for cid in p.champion_order:
			if not ChampionType.IDS.has(StringName(cid)):
				refs.append({"sev": "FAIL", "where": where, "what": "champion_order `%s` unknown" % cid, "fix": str(ChampionType.IDS)})
		if p.champion_max > p.champion_order.size() and p.champion_max > 0:
			refs.append({"sev": "WARN", "where": where, "what": "champion_max %d but %d in champion_order" % [p.champion_max, p.champion_order.size()], "fix": "list enough archetypes"})
		if p.retreat_spell != &"" and SpellType.find(p.retreat_spell) == null:
			refs.append({"sev": "FAIL", "where": where, "what": "retreat_spell `%s` unknown" % p.retreat_spell, "fix": "an id from data/spells"})
		if p.retreat_spell != &"" and r["kingdom"] != &"":
			var own := false
			for file: String in wizard_spells:
				if wizard_spells[file]["kingdom"] == String(r["kingdom"]) and wizard_spells[file]["ids"].has(String(p.retreat_spell)):
					own = true
			if not own and not wizard_spells.is_empty():
				refs.append({"sev": "FAIL", "where": where, "what": "retreat_spell `%s` is not a %s wizard spell" % [p.retreat_spell, r["kingdom"]], "fix": "use the kingdom's own spell"})
		for wid in p.ware_order:
			if not GoldBank.WARES.has(StringName(wid)):
				refs.append({"sev": "FAIL", "where": where, "what": "ware_order `%s` unknown" % wid, "fix": str(GoldBank.WARES.keys())})
		var re_sp := RegEx.create_from_string(Rules.AI_SPELL_ORDER_RE)
		for so in p.spell_order:
			if re_sp.search(so) == null:
				refs.append({"sev": "FAIL", "where": where, "what": "spell_order entry `%s`" % so, "fix": "<F|Q|E><1-3>"})
		var re_row := RegEx.create_from_string(Rules.AI_BUILD_ROW_RE)
		for br in p.build_rows:
			if re_row.search(br) == null:
				refs.append({"sev": "FAIL", "where": where, "what": "build_rows entry `%s`" % br, "fix": "H1, V1, S1..."})
		var re_flag := RegEx.create_from_string(Rules.AI_FLAG_RE)
		for fl in p.trade_flags + p.mapfill_flags:
			if re_flag.search(fl) == null:
				refs.append({"sev": "FAIL", "where": where, "what": "flag rule `%s`" % fl, "fix": "B5..B11"})
		if not AIProfile.PROFILE_IDS.has(p.profile_id):
			refs.append({"sev": "WARN", "where": where, "what": "profile_id `%s` not in AIProfile.PROFILE_IDS" % p.profile_id, "fix": str(AIProfile.PROFILE_IDS)})
		for mk: String in Rules.AI_MIX_KEYS:
			var mix: PackedFloat32Array = p.get(StringName(mk))
			var sum := 0.0
			for x in mix:
				sum += x
				if x < 0.0:
					mixes.append({"sev": "FAIL", "where": where, "what": "%s has a negative share" % mk, "fix": ">= 0"})
			if mix.size() != 4:
				mixes.append({"sev": "FAIL", "where": where, "what": "%s has %d entries (4 barracks slots)" % [mk, mix.size()], "fix": "4 shares"})
			if absf(sum - 1.0) > Rules.AI_MIX_SUM_TOLERANCE:
				mixes.append({"sev": "WARN", "where": where, "what": "%s sums to %.2f" % [mk, sum], "fix": "shares sum to 1"})
	report.add_check("A2", "ai", "AI knobs in range", "Rules.AI_BOUNDS (ai_profile.gd / ai.md ranges) + ordering (floor <= ratio, S2 after S1...)", resolved.size(), bounds, "fix the knob")
	report.add_check("A3", "ai", "AI references", "item_build, champion_order, retreat_spell (own kingdom), ware_order, spell_order, build rows, flag rules", resolved.size(), refs, "fix the id")
	report.add_check("A4", "ai", "Army mixes", "mix_default / vs_ranged / vs_melee: 4 shares >= 0 summing to 1", resolved.size(), mixes, "fix the shares")
	# A5 difficulty order
	var mono: Array = []
	var nm := 0
	for k in Rules.FACTIONS:
		var by_d := {}
		for r: Dictionary in resolved:
			if r["kingdom"] == k:
				by_d[r["diff"]] = r["profile"]
		if by_d.size() < 3:
			continue
		for knob: String in Rules.AI_MONOTONIC:
			nm += 1
			var e0 := float(by_d[0].get(StringName(knob)))
			var e1 := float(by_d[1].get(StringName(knob)))
			var e2 := float(by_d[2].get(StringName(knob)))
			var ok := (e0 >= e1 and e1 >= e2) if Rules.AI_MONOTONIC[knob] == "down" else (e0 <= e1 and e1 <= e2)
			if not ok:
				mono.append({"sev": "WARN", "where": "%s %s" % [k, knob], "what": "easy %s / normal %s / hard %s (should go %s)" % [_fmt(e0), _fmt(e1), _fmt(e2), Rules.AI_MONOTONIC[knob]], "fix": "hard must be at least as sharp as normal"})
	report.add_check("A5", "ai", "Difficulty order", "easy -> normal -> hard moves each knob of Rules.AI_MONOTONIC one way", nm, mono, "fix the preset or the .tres")


# ---------------------------------------------------------------- B: balance table

func check_balance() -> void:
	var rows := ["Worker", "Z", "X", "C", "V", "B"]
	var cell := {}   # row -> kingdom -> {u, ehp, dps}
	for e: Dictionary in buildings:
		var b := e["res"] as BuildingType
		if not (b.kind in [&"keep", &"barracks"]):
			continue
		b.resolve_trains()
		for i in b.trains.size():
			var u: UnitType = b.trains[i]
			if u == null or u.cost <= 0 or u.is_caravan:
				continue
			var row: String = "Worker" if u.is_worker else (rows[i + 1] if b.kind == &"barracks" and i + 1 < rows.size() else "")
			if row == "":
				continue
			if not cell.has(row):
				cell[row] = {}
			var ehp := u.max_hp * (1.0 + maxf(0.0, u.armor) / 100.0)
			var dps := u.attack_damage / maxf(0.1, u.attack_cooldown)
			cell[row][String(b.faction)] = {"u": u, "ehp": ehp, "dps": dps}
	var md := "EHP = max_hp x (1 + armor / 100); DPS = attack_damage / attack_cooldown (no splash, statuses or support). Per 100 crystals. " + \
		"Rows = card slot (barracks Z X C V = the same role in every kingdom). **bold** = more than x%.1f from the row median (WARN).\n\n" % Rules.BALANCE_FACTOR
	md += "| Slot | " + " | ".join(Rules.FACTIONS.map(func(f: StringName) -> String: return String(f))) + " | median EHP/100 | median DPS/100 |\n|---|---|---|---|---|---|---|\n"
	var issues: Array = []
	var n := 0
	for row: String in rows:
		if not cell.has(row):
			continue
		var ehps: Array[float] = []
		var dpss: Array[float] = []
		for f: String in cell[row]:
			var c: Dictionary = cell[row][f]
			var cost := float((c["u"] as UnitType).cost)
			ehps.append(c["ehp"] / cost * 100.0)
			dpss.append(c["dps"] / cost * 100.0)
		var me := _median(ehps)
		var mdps := _median(dpss)
		var line := "| %s |" % row
		for f in Rules.FACTIONS:
			if not cell[row].has(String(f)):
				line += " - |"
				continue
			n += 1
			var c2: Dictionary = cell[row][String(f)]
			var u2: UnitType = c2["u"]
			var e100: float = c2["ehp"] / float(u2.cost) * 100.0
			var d100: float = c2["dps"] / float(u2.cost) * 100.0
			var te := "%.0f" % e100
			var td := "%.1f" % d100
			if me > 0.0 and (e100 / me > Rules.BALANCE_FACTOR or e100 / me < 1.0 / Rules.BALANCE_FACTOR):
				te = "**%s**" % te
				issues.append({"sev": "WARN", "where": "%s (%s slot %s)" % [u2.id, f, row], "what": "EHP per 100 crystals %.0f vs row median %.0f (x%.2f)" % [e100, me, e100 / me], "fix": "Balance Lab: check cost or HP"})
			if mdps > 0.0 and d100 > 0.0 and (d100 / mdps > Rules.BALANCE_FACTOR or d100 / mdps < 1.0 / Rules.BALANCE_FACTOR):
				td = "**%s**" % td
				issues.append({"sev": "WARN", "where": "%s (%s slot %s)" % [u2.id, f, row], "what": "DPS per 100 crystals %.1f vs row median %.1f (x%.2f)" % [d100, mdps, d100 / mdps], "fix": "Balance Lab: check cost or damage (support units may be meant low)"})
			line += " %s %dc: %s EHP, %s DPS |" % [u2.display_name, u2.cost, te, td]
		md += line + " %.0f | %.1f |\n" % [me, mdps]
	report.add_check("B1", "balance", "Cross-kingdom cost efficiency", "EHP / DPS per 100 crystals within x%.1f of the slot median (WARN only)" % Rules.BALANCE_FACTOR, n, issues,
		"a lead for the Balance Lab, not a bug", "", 0.5)
	report.add_table("Cross-kingdom balance (B1)", md)
