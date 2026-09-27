extends RefCounted
## Data Lab: text helpers. Width measured with the project's GUI font when one is set (gui/theme/custom_font), else
## the engine fallback font (what the HUD uses today), else estimated at 0.55 x font size per character.

const Rules := preload("res://tools/data_lab/data_lab_rules.gd")

var _font: Font = null
var _font_name := "estimate"
var _placeholder := RegEx.create_from_string(Rules.PLACEHOLDER_RE)
var _mojibake := RegEx.create_from_string(Rules.MOJIBAKE_RE)


func _init() -> void:
	var custom := String(ProjectSettings.get_setting("gui/theme/custom_font", ""))
	if custom != "" and ResourceLoader.exists(custom):
		_font = load(custom) as Font
		_font_name = custom.get_file()
	if _font == null:
		_font = ThemeDB.fallback_font
		_font_name = "engine fallback font"
	if _font != null and _font.get_string_size("Wide text", HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x <= 0.0:
		_font = null
		_font_name = "estimate (0.55 em / char)"


func font_name() -> String:
	return _font_name


func width_px(text: String, size: int) -> float:
	if _font != null:
		return _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	return float(text.length()) * float(size) * 0.55


## Lines after word-wrapping `text` (explicit newlines kept) into `width` px at `size`.
func wrapped_lines(text: String, size: int, width: float) -> int:
	var total := 0
	for para in text.split("\n"):
		var line := ""
		var count := 1
		for word in para.split(" ", false):
			var candidate := word if line == "" else line + " " + word
			if width_px(candidate, size) > width and line != "":
				count += 1
				line = word
			else:
				line = candidate
		total += count
	return total


## Numbers printed in `text` (ignoring level / rank / tier words: "level 2", "Rally II") that match none of
## `values` (also |v|, v x 100 for shares, v1 x v2 and v1 x v2 / v3 for totals such as 4 per tick x 2 s / 0.5 s = 16).
## Returns the missing numbers as strings.
func numbers_missing(text: String, values: Array[float]) -> Array[String]:
	var out: Array[String] = []
	if text == "":
		return out
	var cand: Array[float] = []
	for v in values:
		cand.append(absf(v))
		cand.append(absf(v * 100.0))
	var k := mini(values.size(), 14)
	for i in k:
		for j in k:
			if i == j:
				continue
			cand.append(absf(values[i] * values[j]))
			cand.append(absf(values[i] * values[j] * 100.0))
			for m in k:
				if m != i and m != j and absf(values[m]) > 0.0001:
					cand.append(absf(values[i] * values[j] / values[m]))
	var re := RegEx.create_from_string("(?<![\\w.])(\\d+(?:\\.\\d+)?)(?![\\w.]*\\d)")
	var skip_re := RegEx.create_from_string("(?i)(level|rank|tier|lv|L)\\s*$")
	for m2 in re.search_all(text):
		var num := m2.get_string(1).to_float()
		var before := text.substr(maxi(0, m2.get_start() - 7), mini(7, m2.get_start()))
		if skip_re.search(before) != null:
			continue
		var found := false
		for c in cand:
			if absf(c - num) <= maxf(0.011, num * 0.005):
				found = true
				break
		if not found and not out.has(m2.get_string(1)):
			out.append(m2.get_string(1))
	return out


func has_placeholder(text: String) -> bool:
	return _placeholder.search(text) != null


func has_mojibake(text: String) -> bool:
	return _mojibake.search(text) != null


## Literal UI strings in scripts/ui (INFO list for the French pass): `.text = "..."`, `tooltip_text = "..."`,
## `label("...")`-style calls and `const X := "..."` with a word. Returns {total, files, tr, markdown}.
func scan_ui_strings(dirs: Array[String]) -> Dictionary:
	var pats: Array[RegEx] = [
		RegEx.create_from_string("\\.(?:text|tooltip_text|placeholder_text)\\s*[+]?=\\s*\"([^\"]{2,})\""),
		RegEx.create_from_string("(?:label|panel_label|display_label|text|button|_slot|add_item|set_objective)\\(\\s*\"([^\"]*[A-Za-z]{2,}[^\"]*)\""),
		RegEx.create_from_string("^const\\s+\\w+\\s*:?=\\s*\"([^\"]*[A-Za-z]{3,}[^\"]*)\""),
	]
	var tr_re := RegEx.create_from_string("\\btr\\(")
	var rows: Array[Dictionary] = []
	var entries: Array[Dictionary] = []   # {file, line, text}: the ui_strings.csv key list
	var unique := {}
	var total := 0
	var tr_count := 0
	var seen_files := {}
	for d: String in dirs:
		var da := DirAccess.open(d)
		if da == null:
			continue
		for f in da.get_files():
			if not f.ends_with(".gd"):
				continue
			var path := d.path_join(f)
			if seen_files.has(path):
				continue
			seen_files[path] = true
			var found: Array[String] = []
			var line_no := 0
			for line in FileAccess.get_file_as_string(path).split("\n"):
				line_no += 1
				var s := line.strip_edges()
				if s.begins_with("#") or s.begins_with("##"):
					continue
				tr_count += tr_re.search_all(s).size()
				for re in pats:
					for m in re.search_all(s):
						var lit := m.get_string(1)
						if lit.begins_with("res://") or lit.begins_with("user://") or lit.begins_with("%") and lit.length() < 4:
							continue
						if not found.has(lit):
							found.append(lit)
							entries.append({"file": path.replace("res://", ""), "line": line_no, "text": lit})
							unique[lit] = true
			if found.is_empty():
				continue
			total += found.size()
			rows.append({"file": path.replace("res://", ""), "n": found.size(), "examples": found.slice(0, 3)})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["n"]) > int(b["n"]))
	var md := "| Script | Strings | Examples |\n|---|---|---|\n"
	for r: Dictionary in rows:
		var ex: Array[String] = []
		for e: String in r["examples"]:
			ex.append("`%s`" % e.left(40).replace("|", "/"))
		md += "| %s | %d | %s |\n" % [r["file"], r["n"], ", ".join(ex)]
	# The key list for a strings table (French pass): one row per literal with its place and a suggested key.
	var csv := "key,file,line,text\n"
	var used_keys := {}
	for e: Dictionary in entries:
		var k := suggest_key(String(e["text"]))
		var base := k
		var n := 2
		while used_keys.has(k) and used_keys[k] != e["text"]:
			k = "%s_%d" % [base, n]
			n += 1
		used_keys[k] = e["text"]
		csv += "%s,%s,%d,\"%s\"\n" % [k, e["file"], int(e["line"]), String(e["text"]).replace("\"", "\"\"")]
	return {"total": total, "files": rows.size(), "tr": tr_count, "markdown": md, "unique": unique.size(), "csv": csv,
		"top": rows.slice(0, 3)}


## "Train %s (%d)" -> "UI_TRAIN_S_D"-style key: upper snake of the first 4 words.
static func suggest_key(text: String) -> String:
	var words: Array[String] = []
	var re := RegEx.create_from_string("[A-Za-z0-9]+")
	for m in re.search_all(text):
		words.append(m.get_string().to_upper())
		if words.size() >= 4:
			break
	if words.is_empty():
		return "UI_TEXT"
	return "UI_" + "_".join(words)
