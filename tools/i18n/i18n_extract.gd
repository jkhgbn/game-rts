class_name I18nExtract
extends RefCounted
## The extraction / coverage / import logic behind tools/i18n/extract_strings.gd (usage there) and tests/test_i18n.gd.

const I18N := "res://data/i18n"
const LANGS: Array[String] = ["fr"]

## Areas in priority order: a msgid found in two areas belongs to the first one. `src` = folders (non-recursive,
## "/**" = recursive) or files; kinds: gd (GDScript literals), json_text (voice lines "text"), json_guide (Unit Guide),
## tres_text (string properties of resources), mixed (.gd files as gd, .tres files as tres_text plus `"prop": "text"`
## dictionary lines, e.g. the map catalog).
const AREAS: Array[Dictionary] = [
	{"id": "ui_unit_guide", "src": ["res://scripts/ui/menus/unit_guide.gd", "res://scripts/ui/menus/unit_guide_data.gd"],
			"kind": "gd"},
	{"id": "ui_menus", "src": ["res://scripts/ui/menus"], "kind": "gd"},
	{"id": "ui_hud_windows", "src": ["res://scripts/ui/tavern_window.gd", "res://scripts/ui/trade_window.gd",
			"res://scripts/ui/shop_window.gd", "res://scripts/ui/champion_bar.gd", "res://scripts/ui/item_tooltip.gd",
			"res://scripts/ui/inventory_bar.gd", "res://scripts/ui/bounty_mode.gd", "res://scripts/ui/flag_card.gd",
			"res://scripts/ui/mapfill_bar.gd", "res://scripts/ui/point_panel.gd", "res://scripts/ui/post_panel.gd"],
			"kind": "gd"},
	{"id": "ui_hud", "src": ["res://scripts/ui"], "kind": "gd"},
	{"id": "ui_mission", "src": ["res://scripts/ui/mission", "res://scripts/ui/cinematic"], "kind": "gd"},
	{"id": "ui_wave_strike", "src": ["res://scripts/ui/wave_strike"], "kind": "gd"},
	{"id": "campaign", "src": ["res://scripts/campaign"], "kind": "gd"},
	{"id": "campaign_data", "src": ["res://missions/**"], "kind": "tres_text"},
	{"id": "dialogue", "src": ["res://data/voice/lines"], "kind": "json_text"},
	{"id": "unit_guide", "src": ["res://data/ui/unit_guide.json"], "kind": "json_guide"},
	# Map picker: the catalog's titles (names, kept English) and hooks, and the "%s · %d players" template.
	{"id": "maps", "src": ["res://scripts/world/map_catalog.gd", "res://data/maps/catalog.tres"], "kind": "mixed"},
	{"id": "game_data", "src": ["res://data/units", "res://data/buildings", "res://data/spells", "res://data/items",
			"res://data/champions", "res://data/champion_classes", "res://data/helpers"], "kind": "tres_text"},
	{"id": "game_logic", "src": ["res://scripts/buildings", "res://scripts/units", "res://scripts/items",
			"res://scripts/economy", "res://scripts/spells", "res://scripts/world"], "kind": "gd"},
]
## Areas whose every key must have a French entry (test_i18n and `check`). Grows wave by wave.
const REQUIRED_AREAS: Array[String] = ["ui_unit_guide", "ui_menus", "ui_hud", "ui_hud_windows", "ui_mission", "campaign", "dialogue",
		"unit_guide", "maps"]
## .tres properties that hold player-facing text.
const TRES_TEXT_PROPS: Array[String] = ["display_name", "description", "flavor", "tooltip", "title", "hook",
		"summary", "lore", "victory_text", "defeat_text", "end_text", "intro_text", "briefing", "subtitle", "role_text",
		"short_description", "unlock_text", "name_text", "objective_text"]
## Source lines containing one of these never yield keys (debug output, node / meta / theme / group names...).
const SKIP_LINE: Array[String] = ["push_error", "push_warning", "print(", "printerr(", "prints(", "print_rich(",
		"assert(", "get_node", "has_method", "add_theme_", "get_theme_", "has_theme_", ".name = ", "set_meta(",
		"get_meta(", "has_meta(", "remove_meta(", "load(", "preload(", "is_in_group", "add_to_group(",
		"get_nodes_in_group", "get_first_node_in_group", "Input.is_", "InputMap", "is_action", "has_signal(",
		"emit_signal(", ".call(", "callv(", "set_shader_parameter", "OS.get_", "ProjectSettings", "ClassDB",
		"DirAccess", "FileAccess", "RegEx", "begins_with(", "ends_with(", "get_slice(", "_log(", "dialogue_log",
		"class_name ", "extends ", "@export_enum", "LOC_IGNORE", "match_log", "debug_", "_debug"]
## Keys the heuristic picks up but are not player-facing text (exact), from data/i18n/ignore.txt.
var ignore: Dictionary = {}

var mode := "report"
var only_areas: Array[String] = []
var import_path := ""
var quiet := false
var keys: Dictionary = {}          # area -> I18nPo (template)
var owner_of: Dictionary = {}      # key_of(ctx, id) -> area
var bad := 0


func run(args: PackedStringArray) -> int:
	for a in args:
		if a in ["report", "merge", "fix", "check"]:
			mode = a
		elif a.begins_with("import="):
			mode = "import"
			import_path = a.substr(7)
		elif a.begins_with("area="):
			for s in a.substr(5).split(",", false):
				only_areas.append(s)
		elif a == "quiet=1":
			quiet = true
		elif a.begins_with("lang="):
			pass
		else:
			print("I18N ERROR: unknown argument '%s'" % a)
			return 2
	_load_ignore()
	scan_all()
	write_templates()
	match mode:
		"merge":
			merge_french()
		"import":
			if import_french(import_path) != OK:
				return 2
		"fix":
			fix_french()
	var cov := coverage()
	write_coverage(cov)
	var problems := check_french()
	if not quiet:
		for area in cov:
			var c: Dictionary = cov[area]
			print("I18N %-15s keys %4d  fr %4d  %5.1f %%%s" % [area, c["total"], c["fr"], c["pct"],
					"  (required)" if REQUIRED_AREAS.has(area) else ""])
		for p in problems.slice(0, 40):
			print("I18N PROBLEM: " + p)
	var req_total := 0
	var req_done := 0
	for area in REQUIRED_AREAS:
		req_total += int(cov[area]["total"])
		req_done += int(cov[area]["fr"])
	print("I18N: %s, %d keys, required areas %d / %d French, %d problems" % [mode, total_keys(), req_done, req_total,
			problems.size()])
	if mode == "check" and (not problems.is_empty() or req_done < req_total):
		return 1
	return 0


## data/i18n/ignore*.txt (one file per area keeps parallel edits apart: ignore_<area>.txt).
func _load_ignore() -> void:
	for fname in DirAccess.get_files_at(I18N):
		if not (fname.begins_with("ignore") and fname.ends_with(".txt")):
			continue
		for line in FileAccess.get_file_as_string(I18N.path_join(fname)).split("\n"):
			var s := line.strip_edges(false, true)
			if s != "" and not s.begins_with("##"):
				ignore[s.c_unescape()] = true


# ---------------------------------------------------------------- scanning

func scan_all() -> void:
	keys.clear()
	owner_of.clear()
	var taken: Dictionary = {}   # file path -> true (a file belongs to its first area)
	for area: Dictionary in AREAS:
		var po := I18nPo.new()
		po.header = I18nPo.POT_HEADER
		po.title = "# Four Wizards: English keys of area '%s' (generated by tools/i18n/extract_strings.gd; do not edit)" % area["id"]
		keys[area["id"]] = po
		for f in _files_of(area):
			if taken.has(f):
				continue
			taken[f] = true
			match String(area["kind"]):
				"gd": _scan_gd(area["id"], f)
				"json_text": _scan_json_text(area["id"], f)
				"json_guide": _scan_json_guide(area["id"], f)
				"tres_text": _scan_tres(area["id"], f)
				"mixed":
					if f.get_extension() == "gd":
						_scan_gd(area["id"], f)
					else:
						_scan_tres(area["id"], f, true)


func total_keys() -> int:
	var n := 0
	for a in keys:
		n += (keys[a] as I18nPo).entries.size()
	return n


func _files_of(area: Dictionary) -> PackedStringArray:
	var out: PackedStringArray = []
	var ext := {"gd": ["gd"], "json_text": ["json"], "json_guide": ["json"], "tres_text": ["tres"], "mixed": ["gd", "tres"]}[area["kind"]] as Array
	for src: String in area["src"]:
		var rec := src.ends_with("/**")
		var root := src.trim_suffix("/**")
		if FileAccess.file_exists(root):
			out.append(root)
		else:
			_list(root, ext, rec, out)
	return out


func _list(dir: String, ext: Array, rec: bool, out: PackedStringArray) -> void:
	var files := DirAccess.get_files_at(dir)
	var sorted: Array = Array(files)
	sorted.sort()
	for f: String in sorted:
		if ext.has(f.get_extension()):
			out.append(dir.path_join(f))
	if rec:
		for d in DirAccess.get_directories_at(dir):
			_list(dir.path_join(d), ext, rec, out)


func _add(area: String, id: String, ref: String, note: String, ctx := "", plural := "") -> void:
	if id.strip_edges() == "" or ignore.has(id):
		return
	var k := I18nPo.key_of(ctx, id)
	var owner: String = owner_of.get(k, area)
	owner_of[k] = owner
	var po: I18nPo = keys[owner]
	var e := po.add(ctx, id, plural)
	if plural != "" and e["plural"] == "":
		e["plural"] = plural
	if (e["refs"] as PackedStringArray).size() < 6 and not (e["refs"] as PackedStringArray).has(ref):
		e["refs"].append(ref)
	if note != "" and (e["notes"] as PackedStringArray).is_empty():
		e["notes"].append(note)


## Player-facing text heuristic for a GDScript literal (ids, paths, node / class names, format-only strings are not).
static func looks_like_text(s: String) -> bool:
	var t := s.strip_edges()
	if t.length() < 2 or t.contains("res://") or t.contains("user://") or t.begins_with("%") and t.length() <= 3:
		return false
	var letters := 0
	var stripped := RegEx.create_from_string("%[-+0-9.]*[sdfvx%]|\\{[a-z_0-9]*\\}|\\[/?[a-z_]+[^\\]]*\\]").sub(t, "", true)
	for i in stripped.length():
		var c := stripped.unicode_at(i)
		if (c >= 65 and c <= 90) or (c >= 97 and c <= 122):
			letters += 1
	if letters < 2:
		return false
	if RegEx.create_from_string("^[a-z0-9_./:\\-]+$").search(t) != null:
		return false   # id, path, snake_case
	if RegEx.create_from_string("^[A-Z][a-zA-Z0-9]*[A-Z][a-zA-Z0-9]*$").search(t) != null \
			and (RegEx.create_from_string("[a-z]").search(t) != null or t.length() <= 2):
		return false   # CamelCase node / class name, 2-letter badge code (all caps 3+, "VICTORY", counts as text)
	if RegEx.create_from_string("^[A-Z0-9_]+$").search(t) != null and t.length() > 3 and t.contains("_"):
		return false   # CONSTANT_NAME
	if t.begins_with("#") or t.begins_with("--") or t.begins_with("^") or t.begins_with("&"):
		return false
	return true


## The literals of a GDScript file: [{text, line, start, end}], `+`-joined literals merged into one.
static func gd_literals(src: String) -> Array[Dictionary]:
	var raw: Array[Dictionary] = []
	var i := 0
	var line := 1
	var n := src.length()
	while i < n:
		var c := src[i]
		if c == "\n":
			line += 1
			i += 1
			continue
		if c == "#":
			while i < n and src[i] != "\n":
				i += 1
			continue
		if c == "\"" or c == "'":
			var prefix := src[i - 1] if i > 0 else ""
			var triple := src.substr(i, 3) == c + c + c
			var q := c + c + c if triple else c
			var start := i
			var start_line := line
			i += q.length()
			var body := ""
			while i < n:
				if src[i] == "\\" and i + 1 < n:
					body += src.substr(i, 2)
					i += 2
					continue
				if src.substr(i, q.length()) == q:
					break
				if src[i] == "\n":
					line += 1
				body += src[i]
				i += 1
			i += q.length()
			raw.append({"text": body.c_unescape(), "line": start_line, "start": start, "end": i,
					"named": prefix == "&" or prefix == "^" or prefix == "r"})
			continue
		i += 1
	# Merge "a" + "b" (across lines / parentheses-free continuations).
	var out: Array[Dictionary] = []
	for lit in raw:
		if not out.is_empty() and not lit["named"] and not out[-1]["named"]:
			var between := src.substr(out[-1]["end"], lit["start"] - out[-1]["end"])
			if RegEx.create_from_string("^[\\s\\\\]*\\+[\\s\\\\]*$").search(between) != null:
				out[-1]["text"] += lit["text"]
				out[-1]["end"] = lit["end"]
				continue
		out.append(lit)
	return out


func _scan_gd(area: String, path: String) -> void:
	var src := FileAccess.get_file_as_string(path)
	var lines := src.split("\n")
	var rel := path.trim_prefix("res://")
	var lits := gd_literals(src)
	var consumed: Dictionary = {}
	# Loc.tn("singular", "plural", n, args, "ctx"), Loc.t("text", args, "ctx"), Loc.sink("text", "ctx"),
	# tr / atr("text", "ctx"): the call is found across line breaks and the arguments are parsed with nesting and
	# quotes (review 2026-10-08 L1: a dictionary args or a far-indented first literal used to lose ctx / plural).
	for idx in lits.size():
		var lit: Dictionary = lits[idx]
		var callee := callee_before(src, lit["start"])
		if callee == "":
			continue
		var args := call_args(src, lit["start"])
		if callee == "Loc.tn":
			var plural := literal_of(args[1]) if args.size() > 1 else ""
			if plural == "" and idx + 1 < lits.size():
				plural = lits[idx + 1]["text"]   # "a" + "b" joined literal
			if plural == "":
				continue
			var ctx_n := literal_of(args[4]) if args.size() > 4 else ""
			_add(area, lit["text"], "%s:%d" % [rel, lit["line"]], _note(lines, lit["line"]), ctx_n, plural)
			consumed[idx] = true
			if idx + 1 < lits.size() and lits[idx + 1]["text"] == plural:
				consumed[idx + 1] = true
		else:
			var at := 2 if callee == "Loc.t" else 1
			var ctx := literal_of(args[at]) if args.size() > at else ""
			_add(area, lit["text"], "%s:%d" % [rel, lit["line"]], _note(lines, lit["line"]), ctx)
			consumed[idx] = true
	for idx in lits.size():
		if consumed.has(idx):
			continue
		var lit: Dictionary = lits[idx]
		if lit["named"] or not looks_like_text(lit["text"]):
			continue
		var src_line: String = lines[int(lit["line"]) - 1]
		if _skip_line(src_line):
			continue
		var after := src.substr(lit["end"], 3).strip_edges()
		if after.begins_with(":") and not after.begins_with(":="):
			continue   # dictionary key / match pattern
		var before2 := src.substr(maxi(0, lit["start"] - 4), mini(4, lit["start"])).strip_edges()
		if before2.ends_with("==") or before2.ends_with("!=") or before2.ends_with(" in") or before2.ends_with("in"):
			continue   # logic compare
		_add(area, lit["text"], "%s:%d" % [rel, lit["line"]], _note(lines, lit["line"]))


## "Loc.tn", "Loc.t", "Loc.sink", "tr" or "atr" when the literal starting at `at` is the first argument of that call
## (whitespace, line breaks and "\\" continuations allowed before it), else "".
static func callee_before(src: String, at: int) -> String:
	var j := at - 1
	while j >= 0 and (src[j] == " " or src[j] == "\t" or src[j] == "\n" or src[j] == "\r" or src[j] == "\\"):
		j -= 1
	if j < 0 or src[j] != "(":
		return ""
	j -= 1
	var end := j + 1
	while j >= 0 and (src[j] == "." or src[j] == "_" or src[j].is_valid_identifier() or src[j].is_valid_int()):
		j -= 1
	var name := src.substr(j + 1, end - j - 1)
	if name in ["Loc.tn", "Loc.t", "Loc.sink", "tr", "atr"]:
		return name
	return ""


## The raw top-level arguments of the call whose first argument starts at `from` (up to its closing parenthesis),
## strings, brackets and braces skipped.
static func call_args(src: String, from: int) -> PackedStringArray:
	var out: PackedStringArray = []
	var depth := 0
	var cur := from
	var i := from
	var n := src.length()
	while i < n:
		var c := src[i]
		if c == "\"" or c == "'":
			var q := c + c + c if src.substr(i, 3) == c + c + c else c
			i += q.length()
			while i < n and src.substr(i, q.length()) != q:
				i += 2 if src[i] == "\\" else 1
			i += q.length()
			continue
		if c == "#":
			while i < n and src[i] != "\n":
				i += 1
			continue
		if c == "(" or c == "[" or c == "{":
			depth += 1
		elif c == ")" or c == "]" or c == "}":
			if depth == 0:
				out.append(src.substr(cur, i - cur))
				return out
			depth -= 1
		elif c == "," and depth == 0:
			out.append(src.substr(cur, i - cur))
			cur = i + 1
		i += 1
	return out


## The text of an argument that is one plain string literal ("" otherwise).
static func literal_of(arg: String) -> String:
	var a := arg.replace("\\\n", " ").strip_edges()
	var m := RegEx.create_from_string("^\"((?:[^\"\\\\]|\\\\.)*)\"$").search(a)
	return m.get_string(1).c_unescape() if m != null else ""


static func _skip_line(l: String) -> bool:
	var s := l.strip_edges()
	if s.begins_with("##") or s.begins_with("#") or s.begins_with("signal ") or s.begins_with("func "):
		return true
	for k in SKIP_LINE:
		if l.contains(k):
			return true
	return false


static func _note(lines: PackedStringArray, n: int) -> String:
	var s := String(lines[n - 1]).strip_edges()
	return s.substr(0, 110)


func _scan_json_text(area: String, path: String) -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary:
		return
	var rel := path.trim_prefix("res://")
	for line: Variant in (data as Dictionary).get("lines", []):
		if line is Dictionary and String(line.get("text", "")) != "":
			_add(area, String(line["text"]), "%s:%s" % [rel, line.get("id", "?")],
					"speaker %s" % line.get("speaker", "?"))


func _scan_json_guide(area: String, path: String) -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary:
		return
	var rel := path.trim_prefix("res://")
	for group: String in ["units", "buildings", "champions", "helpers", "titans"]:
		var units: Variant = (data as Dictionary).get(group, {})
		if not units is Dictionary:
			continue
		for uid: String in units:
			_guide_values(area, "%s:%s" % [rel, uid], units[uid], "")


func _guide_values(area: String, ref: String, v: Variant, field: String) -> void:
	if v is String:
		if field in ["key", "id", "role", "unit", "kind", "icon"] or not looks_like_text(v):
			return
		if field == "name":
			return   # proper names (abilities, units) stay English
		if field == "good_with" and RegEx.create_from_string("(^|\\s|\\()[a-z]").search(v) == null \
				and RegEx.create_from_string("^[A-Z][a-z]+s$").search(v) == null:
			return   # a unit / building name ("Ember Archer"); generic tags ("Fire army", "Raids") are text
		_add(area, v, ref, field)
	elif v is Array:
		for x: Variant in v:
			_guide_values(area, ref, x, field)
	elif v is Dictionary:
		for k: String in v:
			_guide_values(area, ref, v[k], k)


## `dict_lines` also reads `"prop": "text",` lines (a resource holding an Array[Dictionary], like the map catalog).
func _scan_tres(area: String, path: String, dict_lines := false) -> void:
	var rel := path.trim_prefix("res://")
	var lines := FileAccess.get_file_as_string(path).split("\n")
	var re := RegEx.create_from_string("^([a-z_]+) = \"((?:[^\"\\\\]|\\\\.)*)\"$")
	var dict_re := RegEx.create_from_string("^\"([a-z_]+)\": \"((?:[^\"\\\\]|\\\\.)*)\",?$")
	for i in lines.size():
		var m := re.search(lines[i].strip_edges())
		if m == null and dict_lines:
			m = dict_re.search(lines[i].strip_edges())
		if m == null:
			continue
		var prop := m.get_string(1)
		var text := m.get_string(2).c_unescape()
		if not TRES_TEXT_PROPS.has(prop) or not looks_like_text(text):
			continue
		var is_name := prop == "display_name" or dict_lines and prop == "title"   # a map title is a place name
		_add(area, text, "%s:%d" % [rel, i + 1], "name (glossary: stays English)" if is_name else prop)


# ---------------------------------------------------------------- outputs

func write_templates() -> void:
	for area in keys:
		(keys[area] as I18nPo).save(I18N.path_join("en").path_join(area + ".pot"))


func _fr_path(area: String) -> String:
	return I18N.path_join("fr").path_join(area + ".po")


func _wants(area: String) -> bool:
	return only_areas.is_empty() or only_areas.has(area)


## Adds every missing key to fr/<area>.po (empty msgstr; unit / building names pre-filled with the English name),
## refreshes refs / notes, and marks keys gone from the sources as obsolete (#, obsolete; kept, never deleted).
func merge_french() -> void:
	for area in keys:
		if not _wants(area):
			continue
		var tpl: I18nPo = keys[area]
		var fr := I18nPo.load_file(_fr_path(area))
		fr.header = I18nPo.FR_HEADER
		fr.title = "# Four Wizards: French (Quebec) for area '%s'. Glossary: data/i18n/glossary_fr.md" % area
		for e in tpl.entries:
			var f := fr.add(e["ctx"], e["id"], e["plural"])
			f["refs"] = (e["refs"] as PackedStringArray).duplicate()
			f["notes"] = (e["notes"] as PackedStringArray).duplicate()
			(f["flags"] as PackedStringArray).erase("obsolete")
			if String(f["strs"][0]) == "" and (e["notes"] as PackedStringArray).has("name (glossary: stays English)"):
				f["strs"][0] = e["id"]
		for f in fr.entries:
			if not tpl.has(f["ctx"], f["id"]) and not (f["flags"] as PackedStringArray).has("obsolete"):
				f["flags"].append("obsolete")
		_sort_like(fr, tpl)
		fr.save(_fr_path(area))


func _sort_like(fr: I18nPo, tpl: I18nPo) -> void:
	var order: Dictionary = {}
	for i in tpl.entries.size():
		order[I18nPo.key_of(tpl.entries[i]["ctx"], tpl.entries[i]["id"])] = i
	var big := tpl.entries.size() + 100000
	fr.entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(order.get(I18nPo.key_of(a["ctx"], a["id"]), big)) < int(order.get(I18nPo.key_of(b["ctx"], b["id"]), big)))


## JSON {"English": "Français"} (or {"English": ["sing", "plur"]}; "ctx\u0004English" for a context) -> fills the
## French entries (empty or not) of the areas that own the keys. Typography fixed on the way in.
func import_french(path: String) -> Error:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary:
		print("I18N ERROR: %s is not a JSON object" % path)
		return ERR_PARSE_ERROR
	var files: Dictionary = {}
	var missing := 0
	for k: String in data:
		var area: String = owner_of.get(k, "")
		if area == "" or not _wants(area):
			missing += 1
			if not quiet and area == "":
				print("I18N import: no such key: " + k.replace("\u0004", " | ").substr(0, 80))
			continue
		if not files.has(area):
			files[area] = I18nPo.load_file(_fr_path(area))
		var fr: I18nPo = files[area]
		var ctx := k.get_slice("\u0004", 0) if k.contains("\u0004") else ""
		var id := k.get_slice("\u0004", 1) if k.contains("\u0004") else k
		var tpl_e: Dictionary = (keys[area] as I18nPo).find(ctx, id)
		var e := fr.add(ctx, id, String(tpl_e.get("plural", "")))
		if e["refs"].is_empty() and not tpl_e.is_empty():
			e["refs"] = (tpl_e["refs"] as PackedStringArray).duplicate()
			e["notes"] = (tpl_e["notes"] as PackedStringArray).duplicate()
		var v: Variant = data[k]
		if v is Array:
			var strs := PackedStringArray()
			for s: Variant in v:
				strs.append(typography(String(s)))
			e["strs"] = strs
		else:
			e["strs"][0] = typography(String(v))
		(e["flags"] as PackedStringArray).erase("fuzzy")
	for area in files:
		var fr: I18nPo = files[area]
		fr.header = I18nPo.FR_HEADER
		if fr.title == "":
			fr.title = "# Four Wizards: French (Quebec) for area '%s'. Glossary: data/i18n/glossary_fr.md" % area
		_sort_like(fr, keys[area])
		fr.save(_fr_path(area))
	print("I18N import: %d keys, %d skipped" % [(data as Dictionary).size() - missing, missing])
	return OK


func fix_french() -> void:
	for area in keys:
		if not _wants(area) or not FileAccess.file_exists(_fr_path(area)):
			continue
		var fr := I18nPo.load_file(_fr_path(area))
		for e in fr.entries:
			for i in (e["strs"] as PackedStringArray).size():
				e["strs"][i] = typography(e["strs"][i])
		fr.save(_fr_path(area))


## French typography: no-break space (U+00A0) before : ; ? ! and inside « », decimal comma kept as written.
static func typography(s: String) -> String:
	var nb := "\u00a0"
	for p in [":", ";", "?", "!"]:
		s = s.replace(" " + p, nb + p)
	s = s.replace("« ", "«" + nb).replace(" »", nb + "»")
	s = RegEx.create_from_string("«(?=[^\\s\u00a0])").sub(s, "«" + nb, true)
	s = RegEx.create_from_string("(?<=[^\\s\u00a0])»").sub(s, nb + "»", true)
	# "45 %", "%d %%", "{pct} %": no-break space before the percent sign (glossary), never before a %s / %d spec.
	s = RegEx.create_from_string("(?<=\\d|%d|\\}) %(?![-+0-9.]*[sdfvxo])").sub(s, nb + "%", true)
	return s


## {area: {total, fr, pct, missing: [ids]}}.
func coverage() -> Dictionary:
	var out: Dictionary = {}
	for area: Dictionary in AREAS:
		var id: String = area["id"]
		var tpl: I18nPo = keys[id]
		var fr := I18nPo.load_file(_fr_path(id))
		var done := 0
		var missing: PackedStringArray = []
		for e in tpl.entries:
			if I18nPo.is_translated(fr.find(e["ctx"], e["id"])):
				done += 1
			else:
				missing.append(e["id"])
		var total := tpl.entries.size()
		out[id] = {"total": total, "fr": done, "pct": 100.0 * done / maxf(total, 1.0) if total > 0 else 100.0,
				"missing": missing}
	return out


## Placeholder / plural problems in every French file ("" list = clean): the area files and every other .po the
## game loads (Loc.po_files: game_logic_templates.po, story_e4_e8.po... kept by hand; review 2026-10-08 M3).
func check_french() -> PackedStringArray:
	var out: PackedStringArray = []
	var seen: Dictionary = {}
	for area: Dictionary in AREAS:
		seen[_fr_path(area["id"])] = true
		out.append_array(check_french_file(_fr_path(area["id"]), area["id"]))
	for path in Loc.po_files("fr"):
		if not seen.has(path):
			out.append_array(check_french_file(path, path.get_file().get_basename()))
	return out


## Placeholder / plural problems of one French .po file (`label` prefixes each line).
static func check_french_file(path: String, label: String) -> PackedStringArray:
	var out: PackedStringArray = []
	var fr := I18nPo.load_file(path)
	for e in fr.entries:
		if (e["flags"] as PackedStringArray).has("obsolete"):
			continue
		var strs: PackedStringArray = e["strs"]
		for i in strs.size():
			if strs[i] == "":
				continue
			var src: String = e["id"] if i == 0 or e["plural"] == "" else e["plural"]
			var why := placeholder_mismatch(src, strs[i], e["plural"] != "")
			if why != "":
				out.append("%s: \"%s\": %s" % [label, String(e["id"]).substr(0, 60), why])
		if e["plural"] != "" and strs.size() < 2:
			out.append("%s: \"%s\": plural entry needs msgstr[0] and msgstr[1]" % [label, e["id"]])
	return out


## "" when `a` and `b` use the same placeholders (%s %d %.1f... in order; {name} as a set; BBCode tags as a set).
static func placeholder_mismatch(a: String, b: String, plural := false) -> String:
	var pct := RegEx.create_from_string("%[-+0-9.]*[sdfvxo%]")
	var pa: PackedStringArray = []
	var pb: PackedStringArray = []
	for m in pct.search_all(a):
		pa.append(m.get_string())
	for m in pct.search_all(b):
		pb.append(m.get_string())
	if pa != pb:
		return "printf placeholders %s vs %s" % [pa, pb]
	var named := RegEx.create_from_string("\\{[A-Za-z_0-9]*\\}")
	var na: Dictionary = {}
	var nb: Dictionary = {}
	for m in named.search_all(a):
		na[m.get_string()] = true
	for m in named.search_all(b):
		nb[m.get_string()] = true
	if plural:
		na.erase("{n}")
		nb.erase("{n}")
	if na.keys().size() != nb.keys().size() or not na.keys().all(func(k: Variant) -> bool: return nb.has(k)):
		return "named placeholders %s vs %s" % [na.keys(), nb.keys()]
	var tag := RegEx.create_from_string("\\[/?[a-z_]+")
	var ta: Dictionary = {}
	var tb: Dictionary = {}
	for m in tag.search_all(a):
		ta[m.get_string()] = int(ta.get(m.get_string(), 0)) + 1
	for m in tag.search_all(b):
		tb[m.get_string()] = int(tb.get(m.get_string(), 0)) + 1
	if ta != tb:
		return "BBCode tags differ"
	var hash_a := a.count("#")
	if a.count("#") != b.count("#") and hash_a > 0:
		return "numeric-template '#' count %d vs %d" % [hash_a, b.count("#")]
	return ""


func write_coverage(cov: Dictionary) -> void:
	var md: PackedStringArray = ["# Localization coverage", "",
			"Generated by `tools/i18n/extract_strings.gd` (%s). Keys = English msgids found in the sources; French = keys with a non-empty, non-fuzzy entry in `data/i18n/fr/`. Required areas must stay at 100 %% (`tests/test_i18n.gd`)." % Time.get_date_string_from_system(), "",
			"| Area | Required | Keys | French | % |", "|---|---|---|---|---|"]
	var tot := 0
	var done := 0
	for area: Dictionary in AREAS:
		var c: Dictionary = cov[area["id"]]
		tot += int(c["total"])
		done += int(c["fr"])
		md.append("| %s | %s | %d | %d | %.1f |" % [area["id"], "yes" if REQUIRED_AREAS.has(area["id"]) else "no",
				c["total"], c["fr"], c["pct"]])
	md.append("| **all** | | **%d** | **%d** | **%.1f** |" % [tot, done, 100.0 * done / maxf(tot, 1.0)])
	md.append("")
	md.append("## Not translated yet (first 25 per area)")
	for area: Dictionary in AREAS:
		var miss: PackedStringArray = cov[area["id"]]["missing"]
		if miss.is_empty():
			continue
		md.append("")
		md.append("**%s** (%d)" % [area["id"], miss.size()])
		for m in miss.slice(0, 25):
			md.append("- `%s`" % m.replace("\n", "\\n").replace("`", "'").substr(0, 100))
	var f := FileAccess.open(I18N.path_join("coverage.md"), FileAccess.WRITE)
	if f:
		f.store_string("\n".join(md) + "\n")
		f.close()
