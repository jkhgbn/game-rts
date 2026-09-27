extends "../bot_lab/lab_match.gd"
## Balance Lab (docs/plan/balance-lab.md): ONE Bot Lab match (tools/bot_lab/lab_match.gd, unchanged) with a stat
## VARIANT applied at match start. The variant is a JSON file of overrides on the loaded UnitType / BuildingType
## resources, changed in memory only (ResourceLoader cache, held for the whole match): data/*.tres are never written.
## Launched by tools/balance_lab/run_balance.ps1; runnable alone (same flags as lab_match.gd, plus):
##   --variant=PATH        variant JSON (absolute path, or res://). No flag / "baseline" = no override.
## Variant format (see tools/balance_lab/variants/*.json):
##   {"name": "hound_dps_down", "notes": "why",
##    "units":     {"grave_hound": {"attack_damage": 6.5, "cost": "x1.15"}},
##    "buildings": {"fire_tower":  {"max_hp": "+50"}}}
##   value: a number = the new value; "x1.15" = multiply; "+50" / "-2" = add. Only existing numeric fields (int / float)
##   are accepted; anything else is reported in the JSON ("variant.errors") and skipped, never guessed.
## The JSON line of lab_match.gd gets one more key, "variant": {name, file, applied: [...], errors: [...]}.
## The relative `extends` works both from res:// (main folder) and by absolute path (a lab worktree without the Balance
## Lab): it resolves next to this file.

const UNIT_DIR := "res://data/units/"
const BUILDING_DIR := "res://data/buildings/"

var variant_name := "baseline"
var variant_file := ""
var variant_applied: Array = []   # [{kind, id, field, from, to}]
var variant_errors: Array = []    # [String]
var _held: Array[Resource] = []   # keeps the edited resources in the cache for the whole match


func _initialize() -> void:
	_apply_variant_from_args()
	super._initialize()


func _apply_variant_from_args() -> void:
	var path := ""
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--variant="):
			path = a.substr(10)
	if path == "" or path == "baseline":
		return
	variant_file = path
	var data: Variant = read_variant(path)
	if not (data is Dictionary):
		variant_errors.append("can't read variant %s" % path)
		variant_name = "unreadable"
		push_error("BALANCE: can't read variant %s" % path)
		return
	apply_variant(data as Dictionary)
	print("BALANCE variant %s: %d overrides, %d errors" % [variant_name, variant_applied.size(), variant_errors.size()])
	for e: String in variant_errors:
		push_warning("BALANCE: " + e)


## Reads a variant JSON file (absolute path or res://). Returns the Dictionary, or null.
static func read_variant(path: String) -> Variant:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var data: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return data if data is Dictionary else null


func apply_variant(data: Dictionary) -> void:
	variant_name = String(data.get("name", variant_file.get_file().get_basename()))
	apply_to_resources(data, variant_applied, variant_errors, _held)


## Applies a parsed variant to the cached resources (in memory only). Fills `applied` ([{kind, id, field, from, to}]),
## `errors` (String) and `held` (the edited resources: keep them referenced so the cache keeps them). Static and public
## so the test can use it without a match.
static func apply_to_resources(data: Dictionary, applied: Array, errors: Array, held: Array) -> void:
	for section: String in ["units", "buildings"]:
		var entries: Variant = data.get(section, {})
		if not (entries is Dictionary):
			errors.append("%s must be an object" % section)
			continue
		var dir := UNIT_DIR if section == "units" else BUILDING_DIR
		for id: String in (entries as Dictionary):
			var res_path := dir + id + ".tres"
			if not ResourceLoader.exists(res_path):
				errors.append("%s: no %s" % [id, res_path])
				continue
			var res := load(res_path) as Resource
			if res == null:
				errors.append("%s: can't load %s" % [id, res_path])
				continue
			held.append(res)
			var fields: Variant = entries[id]
			if not (fields is Dictionary):
				errors.append("%s: overrides must be an object" % id)
				continue
			for field: String in (fields as Dictionary):
				var err := _apply_field(res, section.trim_suffix("s"), id, field, fields[field], applied)
				if err != "":
					errors.append(err)


static func _apply_field(res: Resource, kind: String, id: String, field: String, spec: Variant, applied: Array) -> String:
	if not (StringName(field) in res):
		return "%s.%s: no such field" % [id, field]
	var old: Variant = res.get(StringName(field))
	if not (old is int or old is float):
		return "%s.%s: not a number (%s)" % [id, field, type_string(typeof(old))]
	var value := resolve_value(float(old), spec)
	if is_nan(value):
		return "%s.%s: bad value %s (use 12, \"x1.1\", \"+5\")" % [id, field, str(spec)]
	var new_value: Variant = roundi(value) if old is int else value
	res.set(StringName(field), new_value)
	applied.append({"kind": kind, "id": id, "field": field, "from": old, "to": new_value})
	return ""


## 12 -> 12; "x1.1" / "*1.1" -> old x 1.1; "+5" / "-5" -> old +/- 5. NAN when unreadable.
static func resolve_value(old: float, spec: Variant) -> float:
	if spec is int or spec is float:
		return float(spec)
	if not (spec is String):
		return NAN
	var s := (spec as String).strip_edges().to_lower()
	if s.begins_with("x") or s.begins_with("*"):
		var m := s.substr(1)
		return old * m.to_float() if m.is_valid_float() else NAN
	if (s.begins_with("+") or s.begins_with("-")) and s.substr(1).is_valid_float():
		return old + s.to_float()
	return s.to_float() if s.is_valid_float() else NAN


## Proof that the game used the edited resources: every unit / building of an overridden id that enters the tree is
## counted, and whether its type is the SAME object as the one edited ("live": {id: {seen, same}}).
var _live := {}


func _on_node_added(node: Node) -> void:
	super._on_node_added(node)
	if _held.is_empty():
		return
	for key: StringName in [&"unit_type", &"building_type"]:
		if key in node:
			var t: Variant = node.get(key)
			if t is Resource:
				var id := String((t as Resource).get(&"id"))
				for h: Resource in _held:
					if String(h.get(&"id")) == id:
						var row: Dictionary = _live.get(id, {"seen": 0, "same": 0})
						row["seen"] += 1
						if h == t:
							row["same"] += 1
						_live[id] = row


## lab_match.gd writes its JSON line in _finish; add the variant to it (same file, same line).
func _finish(reason: String, winner: int, error: String) -> bool:
	var was_finished := _finished
	var r := super._finish(reason, winner, error)
	if was_finished or out_path == "":
		return r
	var f := FileAccess.open(out_path, FileAccess.READ)
	if f == null:
		return r
	var data: Variant = JSON.parse_string(f.get_line())
	f.close()
	if not (data is Dictionary):
		return r
	data["variant"] = {"name": variant_name, "file": variant_file, "applied": variant_applied, "errors": variant_errors,
			"live": _live}
	var w := FileAccess.open(out_path, FileAccess.WRITE)
	if w:
		w.store_line(JSON.stringify(data))
		w.close()
	return r
