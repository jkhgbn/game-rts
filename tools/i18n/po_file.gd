class_name I18nPo
extends RefCounted
## A gettext .po / .pot file as data (docs/design/localization.md): read, edit, write back in a stable order.
## Entry = {ctx, id, plural, strs: PackedStringArray (1, or 2 for plurals), refs: PackedStringArray ("path:line"),
## notes: PackedStringArray ("#." lines), flags: PackedStringArray ("#," e.g. fuzzy)}.
## Obsolete entries (flag "obsolete") are written gettext-style as "#~ msgid ..." lines, so Godot's PO loader skips
## them and a removed key can never shadow the live one of another area (review 2026-10-08 L2). Both the old
## "#, obsolete" form and "#~" lines read back as obsolete entries.

const FR_HEADER := "Content-Type: text/plain; charset=UTF-8\\nLanguage: fr_CA\\nPlural-Forms: nplurals=2; plural=(n > 1);\\n"
const POT_HEADER := "Content-Type: text/plain; charset=UTF-8\\nLanguage: en\\nPlural-Forms: nplurals=2; plural=(n != 1);\\n"

var header := FR_HEADER   ## raw (escaped) header text
var title := ""           ## "# ..." comment lines written at the top
var entries: Array[Dictionary] = []
var _index: Dictionary = {}   # key(ctx, id) -> entry


static func key_of(ctx: String, id: String) -> String:
	return (ctx + "\u0004" + id) if ctx != "" else id


static func load_file(path: String) -> I18nPo:
	var po := I18nPo.new()
	if not FileAccess.file_exists(path):
		return po
	po.parse(FileAccess.get_file_as_string(path))
	return po


func find(ctx: String, id: String) -> Dictionary:
	return _index.get(key_of(ctx, id), {})


func has(ctx: String, id: String) -> bool:
	return _index.has(key_of(ctx, id))


func add(ctx: String, id: String, plural := "") -> Dictionary:
	var k := key_of(ctx, id)
	if _index.has(k):
		# An existing singular entry becomes plural when the source now uses Loc.tn (review 2026-10-08 M2):
		# without this, merge / import kept "plural" empty and the French plural form was never written.
		var old: Dictionary = _index[k]
		if plural != "" and String(old["plural"]) == "":
			old["plural"] = plural
			while (old["strs"] as PackedStringArray).size() < 2:
				old["strs"].append("")
		return old
	var e := {"ctx": ctx, "id": id, "plural": plural, "strs": PackedStringArray([""] if plural == "" else ["", ""]),
			"refs": PackedStringArray(), "notes": PackedStringArray(), "flags": PackedStringArray()}
	entries.append(e)
	_index[k] = e
	return e


func remove(ctx: String, id: String) -> void:
	var k := key_of(ctx, id)
	if not _index.has(k):
		return
	entries.erase(_index[k])
	_index.erase(k)


static func is_translated(e: Dictionary) -> bool:
	if e.is_empty():
		return false
	for s: String in e["strs"]:
		if s == "":
			return false
	return not (e["flags"] as PackedStringArray).has("fuzzy")


func parse(text: String) -> void:
	entries.clear()
	_index.clear()
	var cur := _blank()
	var field := ""
	var title_lines: PackedStringArray = []
	var seen_entry := false
	for raw in text.split("\n"):
		var line := raw.strip_edges()
		var old_entry := false
		if line.begins_with("#~"):
			line = line.substr(2).strip_edges()
			old_entry = true
			if line == "":
				continue
		if line == "":
			if field != "":
				_commit(cur)
				cur = _blank()
				field = ""
				seen_entry = true
			continue
		if line.begins_with("#"):
			if field != "" and (cur["id"] != "" or cur["header"]):
				_commit(cur)
				cur = _blank()
				field = ""
				seen_entry = true
			if line.begins_with("#:"):
				for r in line.substr(2).strip_edges().split(" ", false):
					cur["refs"].append(r)
			elif line.begins_with("#."):
				cur["notes"].append(line.substr(2).strip_edges())
			elif line.begins_with("#,"):
				for f in line.substr(2).split(",", false):
					cur["flags"].append(f.strip_edges())
			elif not seen_entry and field == "" and cur["refs"].is_empty():
				title_lines.append(line)
			continue
		if old_entry and not (cur["flags"] as PackedStringArray).has("obsolete"):
			cur["flags"].append("obsolete")
		if line.begins_with("msgctxt "):
			field = "ctx"
			cur["ctx"] = _unquote(line.substr(8))
		elif line.begins_with("msgid_plural "):
			field = "plural"
			cur["plural"] = _unquote(line.substr(13))
		elif line.begins_with("msgid "):
			field = "id"
			cur["id"] = _unquote(line.substr(6))
			cur["has_id"] = true
		elif line.begins_with("msgstr["):
			var n := int(line.substr(7, line.find("]") - 7))
			field = "str%d" % n
			while (cur["strs"] as PackedStringArray).size() <= n:
				cur["strs"].append("")
			cur["strs"][n] = _unquote(line.substr(line.find("]") + 2))
		elif line.begins_with("msgstr "):
			field = "str0"
			if (cur["strs"] as PackedStringArray).is_empty():
				cur["strs"].append("")
			cur["strs"][0] = _unquote(line.substr(7))
		elif line.begins_with("\""):
			var more := _unquote(line)
			match field:
				"ctx": cur["ctx"] += more
				"id": cur["id"] += more
				"plural": cur["plural"] += more
				_:
					if field.begins_with("str"):
						var n2 := int(field.substr(3))
						cur["strs"][n2] = String(cur["strs"][n2]) + more
	if field != "":
		_commit(cur)
	title = "\n".join(title_lines)


func _blank() -> Dictionary:
	return {"ctx": "", "id": "", "plural": "", "strs": PackedStringArray(), "refs": PackedStringArray(),
			"notes": PackedStringArray(), "flags": PackedStringArray(), "header": false, "has_id": false}


func _commit(e: Dictionary) -> void:
	if not e["has_id"]:
		return
	if e["id"] == "" and e["ctx"] == "":
		header = _escape(String(e["strs"][0]) if not (e["strs"] as PackedStringArray).is_empty() else "")
		return
	if (e["strs"] as PackedStringArray).is_empty():
		e["strs"].append("")
	e.erase("header")
	e.erase("has_id")
	var k := key_of(e["ctx"], e["id"])
	if not _index.has(k):
		entries.append(e)
		_index[k] = e


func to_text() -> String:
	var out: PackedStringArray = []
	if title != "":
		out.append(title)
	out.append("msgid \"\"")
	out.append("msgstr \"\"")
	for part in header.split("\\n", false):
		out.append("\"%s\\n\"" % part)
	out.append("")
	for e in entries:
		for n: String in e["notes"]:
			out.append("#. " + n.strip_edges())   # parse() strips: a re-read file stays byte-identical
		var refs: PackedStringArray = e["refs"]
		var line := ""
		for r in refs:
			if line.length() + r.length() > 100 and line != "":
				out.append("#:" + line)
				line = ""
			line += " " + r
		if line != "":
			out.append("#:" + line)
		var flags: PackedStringArray = (e["flags"] as PackedStringArray).duplicate()
		var pre := ""
		if flags.has("obsolete"):
			flags.erase("obsolete")
			pre = "#~ "
		if not flags.is_empty():
			out.append("#, " + ", ".join(flags))
		if e["ctx"] != "":
			out.append(pre + "msgctxt " + _quote(e["ctx"]))
		out.append(pre + "msgid " + _quote(e["id"]))
		if e["plural"] != "":
			out.append(pre + "msgid_plural " + _quote(e["plural"]))
			var strs: PackedStringArray = e["strs"]
			for i in maxi(strs.size(), 2):
				out.append(pre + "msgstr[%d] %s" % [i, _quote(strs[i] if i < strs.size() else "")])
		else:
			out.append(pre + "msgstr " + _quote(String(e["strs"][0])))
		out.append("")
	return "\n".join(out)


func save(path: String) -> Error:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(to_text())
	f.close()
	return OK


static func _unquote(s: String) -> String:
	s = s.strip_edges()
	if s.begins_with("\"") and s.ends_with("\"") and s.length() >= 2:
		s = s.substr(1, s.length() - 2)
	return s.c_unescape()


static func _escape(s: String) -> String:
	return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t")


static func _quote(s: String) -> String:
	return "\"" + _escape(s) + "\""
