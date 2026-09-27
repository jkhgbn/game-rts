extends RefCounted
## Audio Lab (docs/plan/audio-lab.md): reads the game's code (no running) to find how sounds are played.
## - "audio scripts" = .gd files that create AudioStreamPlayer / 2D / 3D nodes;
## - the cue registry: every sound file those scripts can play, with its player type (2D / 3D), volume_db, per-cue
##   rate limit, pitch / volume randomisation and the players' bus / unit_size / max_distance, understood from three
##   patterns the game uses today:
##     DIR   const X_DIR := "res://assets/audio/sfx/" + &"id" tokens (GameAudio: SOUNDS, COOLDOWNS, VOLUMES)
##     DICT  const SOUNDS := {&"coin": {"path": "res://...wav", "interval": 0.3, "db": -6.0}} (trade / map-fill)
##     PATH  const SPLASH_PATH := "res://...wav" + SPLASH_DB / SPLASH_RANGE / SPLASH_PER_UNIT
##   plus any other literal "res://....wav|ogg|mp3" (LITERAL, parameters unknown);
## - every player created in code or placed in a .tscn (bus, 3D settings);
## - signal connections in audio scripts and whether their handler plays a sound (missing-cue check).
## New patterns: add a branch here and a line in docs/plan/audio-lab.md.

const Rules := preload("res://tools/audio_lab/lab_rules.gd")
const AUDIO_EXT: Array[String] = ["wav", "ogg", "mp3", "tres"]
const PLAY_RE := "\\bplay_(?:sound|at|ui|splash|cue|sfx|one_shot|stinger)\\w*\\s*\\(|\\.play\\(\\s*\\)"
const PROPS: Array[String] = ["bus", "max_distance", "unit_size", "attenuation_model", "max_polyphony",
	"doppler_tracking", "volume_db", "max_db", "panning_strength"]


# ------------------------------------------------------------------ files

static func list_files(root: String, exts: Array[String], out: Array[String] = []) -> Array[String]:
	var d := DirAccess.open(root)
	if d == null:
		return out
	d.include_hidden = false
	for f in d.get_files():
		if f.get_extension().to_lower() in exts:
			out.append(root.path_join(f))
	for sub in d.get_directories():
		if sub.begins_with(".") or sub == "addons":
			continue
		list_files(root.path_join(sub), exts, out)
	return out


static func read_text(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var t := f.get_as_text()
	f.close()
	return t


# ------------------------------------------------------------------ parsing helpers

static func _re(p: String) -> RegEx:
	var r := RegEx.new()
	r.compile(p)
	return r


## {name: {"start": line index, "body": text, "lines": PackedStringArray}} of every top-level func.
static func split_funcs(text: String) -> Dictionary:
	var out := {}
	var lines := text.split("\n")
	var head := _re("^(?:static\\s+)?func\\s+(\\w+)\\s*\\(")
	var cur := ""
	var start := 0
	var buf: PackedStringArray = []
	for i in lines.size():
		var l := lines[i]
		var m := head.search(l)
		var top := l.length() > 0 and not (l[0] in ["\t", " ", "#"])
		if m or (top and cur != ""):
			if cur != "":
				out[cur] = {"start": start, "body": "\n".join(buf), "lines": buf}
				cur = ""
			if m:
				cur = m.get_string(1)
				start = i
				buf = PackedStringArray([l])
			continue
		if cur != "":
			buf.append(l)
	if cur != "":
		out[cur] = {"start": start, "body": "\n".join(buf), "lines": buf}
	return out


## Top-level const / var / @export var values as raw expression strings.
static func top_values(text: String) -> Dictionary:
	var out := {}
	var r := _re("^(?:@export\\w*(?:\\([^)]*\\))?\\s+)?(?:static\\s+)?(?:const|var)\\s+(\\w+)\\s*(?::\\s*[\\w\\[\\], ]+)?\\s*:?=\\s*(.+)$")
	for l in text.split("\n"):
		var m := r.search(l)
		if m:
			out[m.get_string(1)] = m.get_string(2).strip_edges()
	return out


## Multi-line const block text (`const NAME ... = {` or `[` until the brackets close).
static func const_block(text: String, name: String) -> String:
	var i := text.find("const " + name)
	if i < 0:
		return ""
	var open := -1
	for j in range(i, mini(text.length(), i + 400)):
		if text[j] == "{" or text[j] == "[":
			open = j
			break
		if text[j] == "\n":
			break
	if open < 0:
		return ""
	var depth := 0
	for j in range(open, text.length()):
		var c := text[j]
		if c == "{" or c == "[":
			depth += 1
		elif c == "}" or c == "]":
			depth -= 1
			if depth == 0:
				return text.substr(open, j - open + 1)
	return ""


## Turns an expression into a number / string when it is a literal or a known top-level name.
static func resolve(expr: String, values: Dictionary, depth: int = 0) -> Variant:
	var e := expr.strip_edges()
	var hash := e.find("#")
	if hash > 0:
		e = e.substr(0, hash).strip_edges()
	if e.is_valid_float():
		return float(e)
	for q in ["&\"", "\""]:
		if e.begins_with(q) and e.ends_with("\"") and e.length() >= q.length() + 1:
			return e.substr(q.length(), e.length() - q.length() - 1)
	if e.begins_with("-") and e.substr(1).is_valid_float():
		return float(e)
	if depth < 3 and values.has(e):
		return resolve(str(values[e]), values, depth + 1)
	var dot := e.rfind(".")
	if dot > 0 and depth < 3:
		var tail := e.substr(dot + 1)
		if values.has(tail):
			return resolve(str(values[tail]), values, depth + 1)
		if tail.begins_with("ATTENUATION_") or tail.begins_with("DOPPLER_"):
			return tail
	if e.begins_with("ATTENUATION_") or e.begins_with("DOPPLER_"):
		return e
	return null


# ------------------------------------------------------------------ project scan

## Everything the checks need from the code. Keys: scripts (audio script paths), cues, players, connections,
## declared_signals, allowed_buses, listener, texts (audio script path -> text).
static func scan_project() -> Dictionary:
	var res := {"scripts": [], "cues": {}, "players": [], "connections": [], "declared_signals": {},
		"allowed_buses": allowed_buses(), "listener": false, "texts": {}, "generators": {}}
	var gd: Array[String] = []
	for root in Rules.CODE_ROOTS:
		list_files(root, ["gd"], gd)
	var sig_re := _re("(?m)^\\s*signal\\s+(\\w+)")
	for path in gd:
		var t := read_text(path)
		for m in sig_re.search_all(t):
			var s := m.get_string(1)
			if not res["declared_signals"].has(s):
				res["declared_signals"][s] = []
			(res["declared_signals"][s] as Array).append(path)
		if t.find("AudioListener3D") >= 0:
			res["listener"] = true
		if path.ends_with("_generator.gd") or path in Rules.GENERATOR_HINTS:
			res["generators"][path] = t
		if t.find("AudioStreamPlayer") >= 0 and not path.ends_with("_generator.gd"):
			res["scripts"].append(path)
			res["texts"][path] = t
	for g in Rules.GENERATOR_HINTS:
		if FileAccess.file_exists(g):
			res["generators"][g] = read_text(g)
	for path: String in res["scripts"]:
		_scan_script(path, res["texts"][path], res)
	var tscn: Array[String] = []
	for root in Rules.CODE_ROOTS:
		list_files(root, ["tscn"], tscn)
	for path in tscn:
		var t2 := read_text(path)
		if t2.find("AudioListener3D") >= 0:
			res["listener"] = true
		if t2.find("type=\"AudioStreamPlayer") >= 0:
			_scan_scene(path, t2, res)
	return res


## Buses the settings sliders drive (GameSettings BUS_* constants + default_bus_layout.tres), minus Master.
static func allowed_buses() -> Array[String]:
	var out: Array[String] = []
	var t := read_text(Rules.SETTINGS_SCRIPT)
	for m in _re("const\\s+BUS_\\w+\\s*:=\\s*&?\"(\\w+)\"").search_all(t):
		var b := m.get_string(1)
		if b != "Master" and not out.has(b):
			out.append(b)
	var layout := str(ProjectSettings.get_setting("audio/buses/default_bus_layout", "res://default_bus_layout.tres"))
	if FileAccess.file_exists(layout):
		for m2 in _re("bus/\\d+/name\\s*=\\s*&?\"(\\w+)\"").search_all(read_text(layout)):
			var b2 := m2.get_string(1)
			if b2 != "Master" and not out.has(b2):
				out.append(b2)
	if out.is_empty():
		out.append_array(Rules.FALLBACK_BUSES)
	return out


static func _scan_script(path: String, text: String, res: Dictionary) -> void:
	var funcs := split_funcs(text)
	var values := top_values(text)
	# ---- player-typed variables (file level and local)
	var typed := {}   # var name -> "3d" / "2d"
	for m in _re("\\b(?:var\\s+)?(\\w+)\\s*:\\s*(?:Array\\[)?AudioStreamPlayer(2D|3D)?\\b").search_all(text):
		typed[m.get_string(1)] = "3d" if m.get_string(2) == "3D" else "2d"
	for m in _re("\\b(\\w+)\\s*:?=\\s*AudioStreamPlayer(2D|3D)?\\.new\\(\\)").search_all(text):
		typed[m.get_string(1)] = "3d" if m.get_string(2) == "3D" else "2d"
	# ---- players created in code, their properties and the container they go into
	var players_by_container := {}   # container name -> player dict
	var new_re := _re("\\b(\\w+)\\s*:?=\\s*AudioStreamPlayer(2D|3D)?\\.new\\(\\)")
	for fname: String in funcs:
		var fb: Dictionary = funcs[fname]
		var lines: PackedStringArray = fb["lines"]
		for i in lines.size():
			var m := new_re.search(lines[i])
			if m == null:
				continue
			var v := m.get_string(1)
			var p := {"where": "%s:%d" % [path, int(fb["start"]) + i + 1], "script": path, "func": fname, "var": v,
				"class": "AudioStreamPlayer" + m.get_string(2), "source": "code", "props": {}, "container": "",
				"stream_var": ""}
			var prop_re := _re("^\\s*" + v + "\\.(" + "|".join(PROPS) + ")\\s*=\\s*(.+)$")
			var cont_re := _re("(\\w+)(?:\\[[^\\]]+\\]\\s*=\\s*" + v + "\\b|\\.append\\(\\s*" + v + "\\s*\\))")
			var stream_re := _re("^\\s*" + v + "\\.stream\\s*=\\s*(.+)$")
			for j in range(i + 1, mini(lines.size(), i + 30)):
				var pm := prop_re.search(lines[j])
				if pm:
					var val: Variant = resolve(pm.get_string(2), values)
					p["props"][pm.get_string(1)] = val if val != null else "? " + pm.get_string(2).strip_edges()
				var cm := cont_re.search(lines[j])
				if cm and p["container"] == "":
					p["container"] = cm.get_string(1)
				var sm := stream_re.search(lines[j])
				if sm:
					p["stream_var"] = sm.get_string(1).strip_edges()
				if new_re.search(lines[j]) and j > i:
					break
			if not p["props"].has("bus"):
				p["props"]["bus"] = "Master"   # Godot's default when the code never sets it
			(res["players"] as Array).append(p)
			if p["container"] != "":
				players_by_container[p["container"]] = p
	# ---- play functions: player type, randomisation
	var play_funcs := {}   # func name -> {mode, pitch, vol_rand, containers}
	var pitch_re := _re("pitch_scale\\s*=\\s*randf_range\\(\\s*([\\d.]+)\\s*,\\s*([\\d.]+)\\s*\\)")
	var pitch_any := _re("pitch_scale\\s*[+\\-*]?=.*rand")
	var vol_re := _re("volume_db\\s*[+\\-]?=.*rand")
	for fname: String in funcs:
		var body: String = funcs[fname]["body"]
		if body.find(".play(") < 0:
			continue
		var info := {"mode": "", "pitch": 0.0, "vol_rand": vol_re.search(body) != null, "containers": []}
		for v: String in typed:
			if _re("\\b" + v + "\\b").search(body):
				if typed[v] == "3d":
					info["mode"] = "3d"
				elif info["mode"] == "":
					info["mode"] = "2d"
		for c: String in players_by_container:
			if _re("\\b" + c + "\\b").search(body):
				(info["containers"] as Array).append(c)
		var pm := pitch_re.search(body)
		if pm:
			info["pitch"] = (float(pm.get_string(2)) - float(pm.get_string(1))) * 0.5
		elif pitch_any.search(body):
			info["pitch"] = Rules.PITCH_MIN
		play_funcs[fname] = info
	# ---- connections (signal -> handler, does it play?)
	var play_re := _re(PLAY_RE)
	var conn_res: Array[RegEx] = [
		_re("(?:connect|_hook)\\s*\\([^\\n]*?&?\"(\\w+)\"\\s*,\\s*(func\\b[^\\n]*|[A-Za-z_]\\w*)"),
		_re("\\.(\\w+)\\.connect\\(\\s*(func\\b[^\\n]*|[A-Za-z_]\\w*)"),
	]
	for l in text.split("\n"):
		if l.find("connect") < 0 and l.find("_hook(") < 0:
			continue
		for r in conn_res:
			var m := r.search(l)
			if m == null:
				continue
			var sig := m.get_string(1)
			var h := m.get_string(2)
			var plays := false
			if h.begins_with("func"):
				plays = play_re.search(h) != null
				h = "(lambda)"
			else:
				plays = _func_plays(h, funcs, play_re, 0)
			(res["connections"] as Array).append({"script": path, "signal": sig, "handler": h, "plays": plays})
			break
	# ---- cues
	var dirs := {}   # const name -> dir
	for k: String in values:
		var v: Variant = resolve(str(values[k]), values)
		if v is String and (v as String).begins_with("res://") and (v as String).ends_with("/") \
				and (v as String).find("audio") >= 0:
			dirs[k] = v
	var cues: Dictionary = res["cues"]
	if not dirs.is_empty():
		_dir_cues(path, text, funcs, values, dirs, play_funcs, players_by_container, cues, res["players"])
	_dict_cues(path, text, funcs, values, play_funcs, players_by_container, typed, res, cues)
	_path_cues(path, text, funcs, values, play_funcs, typed, res, cues)
	for m in _re("\"(res://[^\"]+\\.(?:wav|ogg|mp3))\"").search_all(text):
		var p2 := m.get_string(1)
		var id := p2.get_file().get_basename()
		if not cues.has(id):
			cues[id] = _cue(id, p2, path, "LITERAL")


static func _func_plays(h: String, funcs: Dictionary, play_re: RegEx, depth: int) -> bool:
	if not funcs.has(h):
		return false
	var body: String = funcs[h]["body"]
	if play_re.search(body):
		return true
	if depth >= 1:
		return false
	for m in _re("\\b(_?\\w+)\\s*\\(").search_all(body):
		var callee := m.get_string(1)
		if callee != h and funcs.has(callee) and _func_plays(callee, funcs, play_re, depth + 1):
			return true
	return false


static func _cue(id: String, path: String, script: String, style: String) -> Dictionary:
	return {"id": id, "path": path, "script": script, "style": style, "mode": "", "volume_db": null,
		"rate_limit_s": null, "pitch": 0.0, "vol_rand": false, "priority": false, "bus": null, "unit_size": null,
		"max_distance": null, "attenuation": null, "play_funcs": [], "triggers": [], "notes": [], "takes": 1}


## Per-id numbers from a const dictionary (`&"id": -4.0`).
static func _id_numbers(text: String, name: String) -> Dictionary:
	var out := {}
	var block := const_block(text, name)
	for m in _re("&?\"(\\w+)\"\\s*:\\s*(-?[\\d.]+)").search_all(block):
		out[m.get_string(1)] = float(m.get_string(2))
	return out


static func _dir_cues(path: String, text: String, funcs: Dictionary, values: Dictionary, dirs: Dictionary,
		play_funcs: Dictionary, by_container: Dictionary, cues: Dictionary, res_players: Array) -> void:
	var vols := {}
	var rates := {}
	var prio: Array[String] = []
	var default_rate: Variant = null
	for k: String in values:
		var up := k.to_upper()
		if up.find("DEFAULT") >= 0 and (up.find("COOLDOWN") >= 0 or up.find("INTERVAL") >= 0):
			default_rate = resolve(str(values[k]), values)
		elif str(values[k]).begins_with("{"):
			if up.find("VOLUME") >= 0 or up.ends_with("_DB"):
				vols.merge(_id_numbers(text, k))
			elif up.find("COOLDOWN") >= 0 or up.find("INTERVAL") >= 0:
				rates.merge(_id_numbers(text, k))
		elif up.find("PRIORITY") >= 0:
			for m in _re("&?\"(\\w+)\"").search_all(const_block(text, k)):
				prio.append(m.get_string(1))
	var tokens := {}
	for m in _re("&\"(\\w+)\"").search_all(text):
		tokens[m.get_string(1)] = true
	# literal play calls: play_xxx(&"id" ...) (ternaries too); dynamic: play_xxx(var, ...)
	var call_re := _re("\\b(play_\\w+)\\s*\\(")
	var lit_mode := {}   # id -> [play funcs]
	var dyn_count := {}
	for l in text.split("\n"):
		var cm := call_re.search(l)
		if cm == null or not play_funcs.has(cm.get_string(1)):
			continue
		var fn := cm.get_string(1)
		var rest := l.substr(cm.get_end())
		var ids := _re("&\"(\\w+)\"").search_all(rest)
		if ids.is_empty():
			dyn_count[fn] = int(dyn_count.get(fn, 0)) + 1
		for im in ids:
			var id := im.get_string(1)
			if not lit_mode.has(id):
				lit_mode[id] = []
			if not (lit_mode[id] as Array).has(fn):
				(lit_mode[id] as Array).append(fn)
	var dyn_fn := ""
	var best := 0
	for fn: String in dyn_count:
		if int(dyn_count[fn]) > best:
			best = int(dyn_count[fn])
			dyn_fn = fn
	for dname: String in dirs:
		var dir: String = dirs[dname]
		for id: String in tokens:
			var file := ""
			for ext in ["wav", "ogg", "mp3", "tres"]:
				if FileAccess.file_exists(dir + id + "." + ext) or ResourceLoader.exists(dir + id + "." + ext):
					file = dir + id + "." + ext
					break
			if file == "" or cues.has(id):
				continue
			var c := _cue(id, file, path, "DIR")
			var is_music := dname.to_upper().find("MUSIC") >= 0 or id.begins_with("music_")
			if vols.has(id):
				c["volume_db"] = vols[id]
			elif is_music:
				for k: String in values:
					if k.to_upper().find("MUSIC") >= 0 and k.to_upper().ends_with("_DB"):
						c["volume_db"] = resolve(str(values[k]), values)
			if c["volume_db"] == null:
				c["volume_db"] = 0.0
			if not is_music:
				c["rate_limit_s"] = rates.get(id, default_rate)
			c["priority"] = prio.has(id)
			var fns: Array = lit_mode.get(id, [])
			if fns.is_empty() and not is_music and dyn_fn != "":
				fns = [dyn_fn]
				(c["notes"] as Array).append("played through %s(<computed id>)" % dyn_fn)
			c["play_funcs"] = fns
			_apply_play_funcs(c, fns, play_funcs, by_container)
			if is_music:
				c["mode"] = "2d"
				_music_player(c, path, res_players)
			c["triggers"] = _triggers(id, text, funcs)
			cues[id] = c


## The player that holds the music: a created player whose bus / var name says Music.
static func _music_player(c: Dictionary, path: String, players: Array) -> void:
	for p: Dictionary in players:
		if p["script"] == path and str(p["props"].get("bus", "")).to_lower() == "music":
			c["bus"] = p["props"]["bus"]
			return


static func _apply_play_funcs(c: Dictionary, fns: Array, play_funcs: Dictionary, by_container: Dictionary) -> void:
	var modes := {}
	for fn: String in fns:
		var pf: Dictionary = play_funcs.get(fn, {})
		if pf.is_empty():
			continue
		modes[pf["mode"]] = true
		c["pitch"] = maxf(float(c["pitch"]), float(pf["pitch"]))
		c["vol_rand"] = bool(c["vol_rand"]) or bool(pf["vol_rand"])
		for cn: String in pf["containers"]:
			var p: Dictionary = by_container[cn]
			_take_player_props(c, p, pf["mode"])
	if modes.has("3d") and modes.has("2d"):
		c["mode"] = "both"
	elif modes.has("3d"):
		c["mode"] = "3d"
	elif modes.has("2d"):
		c["mode"] = "2d"


static func _take_player_props(c: Dictionary, p: Dictionary, mode: String) -> void:
	var pr: Dictionary = p["props"]
	if c["bus"] == null or mode == "3d":
		c["bus"] = pr.get("bus", "Master")
	if str(p["class"]).ends_with("3D"):
		c["unit_size"] = pr.get("unit_size", 10.0)
		c["max_distance"] = pr.get("max_distance", 0.0)
		c["attenuation"] = pr.get("attenuation_model", "ATTENUATION_INVERSE_DISTANCE")


## Signals / functions that lead to a cue: the funcs that mention "<id>" (or its "<prefix>_" when built at run
## time), and the signals connected to those funcs.
static func _triggers(id: String, text: String, funcs: Dictionary) -> Array:
	var out := []
	var needles: Array[String] = ["\"" + id + "\""]
	var us := id.find("_")
	if us > 0:
		needles.append("\"" + id.substr(0, us + 1) + "\"")
	for fn: String in funcs:
		if fn.begins_with("_load") or fn.begins_with("_build") or fn == "_ready":
			continue
		var body: String = funcs[fn]["body"]
		for n in needles:
			if body.find(n) >= 0:
				var sigs := []
				for m in _re("&?\"(\\w+)\"\\s*,\\s*" + fn + "\\b").search_all(text):
					sigs.append(m.get_string(1))
				for m2 in _re("\\.(\\w+)\\.connect\\(\\s*" + fn + "\\b").search_all(text):
					sigs.append(m2.get_string(1))
				var entry := fn if sigs.is_empty() else "%s -> %s" % ["/".join(sigs), fn]
				if not out.has(entry):
					out.append(entry)
				break
	return out


static func _dict_cues(path: String, text: String, funcs: Dictionary, values: Dictionary, play_funcs: Dictionary,
		_by_container: Dictionary, _typed: Dictionary, res: Dictionary, cues: Dictionary) -> void:
	var entry := _re("&?\"(\\w+)\"\\s*:\\s*\\{\\s*\"path\"\\s*:\\s*\"(res://[^\"]+)\"([^}]*)\\}")
	var num := _re("\"(\\w+)\"\\s*:\\s*(-?[\\d.]+)")
	for m in entry.search_all(text):
		var key := m.get_string(1)
		var file := m.get_string(2)
		var id := file.get_file().get_basename()
		if cues.has(id):
			continue
		var c := _cue(id, file, path, "DICT")
		for nm in num.search_all(m.get_string(3)):
			var k := nm.get_string(1)
			if k in ["interval", "cooldown", "rate"]:
				c["rate_limit_s"] = float(nm.get_string(2))
			elif k in ["db", "volume_db", "volume"]:
				c["volume_db"] = float(nm.get_string(2))
		if c["volume_db"] == null:
			c["volume_db"] = 0.0
		# The dict's name: the const block that holds this entry.
		var dict_name := ""
		for k2: String in values:
			if str(values[k2]).begins_with("{") and const_block(text, k2).find(file) >= 0:
				dict_name = k2
				break
		_link_created_player(c, dict_name, "", funcs, play_funcs, res)
		c["triggers"] = _call_triggers(key, text, funcs)
		cues[id] = c


static func _path_cues(path: String, text: String, funcs: Dictionary, values: Dictionary, play_funcs: Dictionary,
		_typed: Dictionary, res: Dictionary, cues: Dictionary) -> void:
	for k: String in values:
		var v: Variant = resolve(str(values[k]), values)
		if not (v is String) or not (v as String).begins_with("res://") or not ((v as String).get_extension() in AUDIO_EXT):
			continue
		var id := (v as String).get_file().get_basename()
		if cues.has(id):
			continue
		var c := _cue(id, v, path, "PATH")
		var prefix := k.substr(0, k.rfind("_")) if k.rfind("_") > 0 else k
		for k2: String in values:
			if not k2.begins_with(prefix + "_") or k2 == k:
				continue
			var val: Variant = resolve(str(values[k2]), values)
			if not (val is float):
				continue
			var up := k2.to_upper()
			if up.ends_with("_DB"):
				c["volume_db"] = val
			elif up.find("INTERVAL") >= 0 or up.find("COOLDOWN") >= 0 or up.find("PER_UNIT") >= 0:
				c["rate_limit_s"] = val
				if up.find("PER_UNIT") >= 0:
					(c["notes"] as Array).append("rate limit %s is per unit (%s)" % [str(val), k2])
		_link_created_player(c, "", k, funcs, play_funcs, res)
		if c["volume_db"] == null:
			c["volume_db"] = 0.0
		var fnames: Array = c["play_funcs"]
		for fn: String in fnames:
			c["triggers"].append_array(_call_triggers_fn(fn, text, funcs))
		cues[id] = c


## Finds the player this cue's stream goes into (the func that uses the dict / path const, then the player whose
## .stream is set there), and the play funcs that use that player's container.
static func _link_created_player(c: Dictionary, dict_name: String, const_name: String, funcs: Dictionary,
		play_funcs: Dictionary, res: Dictionary) -> void:
	var needle := dict_name if dict_name != "" else const_name
	if needle == "":
		return
	for fn: String in funcs:
		var body: String = funcs[fn]["body"]
		if not _re("\\b" + needle + "\\b").search(body):
			continue
		var stream_vars: Array[String] = []
		if const_name != "":
			for m in _re("(\\w+)\\s*(?::\\s*\\w+)?\\s*:?=[^\\n]*\\b" + const_name + "\\b").search_all(body):
				stream_vars.append(m.get_string(1))
		for p: Dictionary in res["players"]:
			if p["script"] != c["script"] or p["func"] != fn:
				continue
			var sv: String = p["stream_var"]
			if sv == "":
				continue
			var ok := false
			if const_name != "":
				for s in stream_vars:
					if sv == s or sv.find(s) >= 0:
						ok = true
			else:
				ok = sv.find("load(") >= 0 or sv.find("path") >= 0
			if not ok:
				continue
			var mode := "3d" if str(p["class"]).ends_with("3D") else "2d"
			c["mode"] = mode
			_take_player_props(c, p, mode)
			var pv: Variant = p["props"].get("volume_db")
			if pv is float and c["volume_db"] == null:
				c["volume_db"] = pv
			var cont: String = p["container"]
			for pf_name: String in play_funcs:
				var pf: Dictionary = play_funcs[pf_name]
				if cont != "" and (pf["containers"] as Array).has(cont):
					(c["play_funcs"] as Array).append(pf_name)
					c["pitch"] = maxf(float(c["pitch"]), float(pf["pitch"]))
					c["vol_rand"] = bool(c["vol_rand"]) or bool(pf["vol_rand"])
			return


## Triggers of a DICT cue: funcs that call play_xxx(&"key"), with their connected signals.
static func _call_triggers(key: String, text: String, funcs: Dictionary) -> Array:
	var out := []
	var r := _re("\\bplay_\\w+\\s*\\(\\s*&?\"" + key + "\"")
	for fn: String in funcs:
		if r.search(funcs[fn]["body"]):
			for t in _call_triggers_fn(fn, text, funcs):
				if not out.has(t):
					out.append(t)
	return out


static func _call_triggers_fn(fn: String, text: String, funcs: Dictionary) -> Array:
	var sigs := []
	for m in _re("&?\"(\\w+)\"\\s*,\\s*" + fn + "\\b").search_all(text):
		sigs.append(m.get_string(1))
	if sigs.is_empty():
		# One level up: who calls fn?
		for other: String in funcs:
			if other != fn and _re("\\b" + fn + "\\s*\\(").search(funcs[other]["body"]):
				for m2 in _re("&?\"(\\w+)\"\\s*,\\s*" + other + "\\b").search_all(text):
					sigs.append(m2.get_string(1))
				if sigs.is_empty():
					return ["%s -> %s" % [other, fn]]
	return [fn] if sigs.is_empty() else ["%s -> %s" % ["/".join(sigs), fn]]


## AudioStreamPlayer* nodes placed in a .tscn (the properties Godot saves; missing = default).
static func _scan_scene(path: String, text: String, res: Dictionary) -> void:
	var ext := {}
	for m in _re("\\[ext_resource[^\\]]*path=\"([^\"]+)\"[^\\]]*id=\"([^\"]+)\"").search_all(text):
		ext[m.get_string(2)] = m.get_string(1)
	var blocks := text.split("\n[")
	for b in blocks:
		var m := _re("^node name=\"([^\"]+)\" type=\"(AudioStreamPlayer(?:2D|3D)?)\"").search(b)
		if m == null:
			continue
		var p := {"where": "%s:%s" % [path, m.get_string(1)], "script": path, "func": "", "var": m.get_string(1),
			"class": m.get_string(2), "source": "scene", "props": {"bus": "Master"}, "container": "", "stream_var": ""}
		for l in b.split("\n"):
			var pm := _re("^(\\w+)\\s*=\\s*(.+)$").search(l)
			if pm == null:
				continue
			var k := pm.get_string(1)
			var v := pm.get_string(2).strip_edges()
			if k == "stream":
				var em := _re("ExtResource\\(\"([^\"]+)\"\\)").search(v)
				p["props"]["stream"] = ext.get(em.get_string(1), v) if em else v
			elif k in PROPS:
				var rv: Variant = resolve(v, {})
				p["props"][k] = rv if rv != null else v
		(res["players"] as Array).append(p)


# ------------------------------------------------------------------ takes / generators

## Number of takes of a cue: <id>_1.. / <id>_a.. files next to it, or the streams of an AudioStreamRandomizer.
static func count_takes(cue_path: String) -> int:
	if cue_path.get_extension() == "tres" and ResourceLoader.exists(cue_path):
		var r: Resource = load(cue_path)
		if r is AudioStreamRandomizer:
			return maxi((r as AudioStreamRandomizer).streams_count, 1)
	var dir := cue_path.get_base_dir()
	var base := cue_path.get_file().get_basename()
	var n := 1
	var d := DirAccess.open(dir)
	if d == null:
		return n
	var re := _re("^" + base + "_(\\d+|[a-z])\\.(wav|ogg|mp3)$")
	for f in d.get_files():
		if re.search(f):
			n += 1
	return n


## True when a generator script (tools/generate_sfx.gd, *_generator.gd) writes this file: a placeholder.
static func is_generated(file_path: String, generators: Dictionary) -> String:
	var base := file_path.get_file()
	var stem := base.get_basename()
	for g: String in generators:
		var t: String = generators[g]
		if t.find(base) >= 0 or t.find("\"" + stem + "\"") >= 0 or t.find("&\"" + stem + "\"") >= 0:
			return g
		if g.get_base_dir() == file_path.get_base_dir() and stem.begins_with(g.get_file().get_basename().replace("_sfx_generator", "")):
			return g
	return ""


# ------------------------------------------------------------------ missing cues

## One row per KEY_EVENTS entry: {id, label, core, status (covered / partial / missing / design_gap / absent),
## via (what covers it), signals_found (declared somewhere)}. `scripts` limits the audio scripts that count.
static func event_coverage(scan: Dictionary, scripts: Array) -> Array:
	var out := []
	var conns: Array = scan["connections"]
	var texts: Dictionary = scan["texts"]
	for ev: Dictionary in Rules.KEY_EVENTS:
		var sigs: Array = ev.get("signals", [])
		var row := {"id": ev["id"], "label": ev["label"], "core": bool(ev.get("core", false)), "status": "missing",
			"via": "", "signals_found": [], "design_gap": bool(ev.get("design_gap", false))}
		for s: String in sigs:
			if scan["declared_signals"].has(s) or s in ["pressed", "tree_exiting"]:
				(row["signals_found"] as Array).append(s)
		var by_signal := ""
		for c: Dictionary in conns:
			if not scripts.has(c["script"]):
				continue
			if sigs.has(c["signal"]) and c["plays"]:
				by_signal = "%s.%s -> %s" % [str(c["script"]).get_file(), c["signal"], c["handler"]]
				break
		var by_evidence := ""
		if ev.has("evidence"):
			var r := _re(ev["evidence"])
			for sp: String in texts:
				if scripts.has(sp) and r.search(texts[sp]):
					by_evidence = "%s (%s)" % [sp.get_file(), ev["evidence"]]
					break
		if by_signal != "":
			row["status"] = "covered"
			row["via"] = by_signal
		elif by_evidence != "":
			row["status"] = "partial" if not sigs.is_empty() else "covered"
			row["via"] = by_evidence
		elif sigs.is_empty():
			row["status"] = "design_gap" if row["design_gap"] else "missing"
		elif (row["signals_found"] as Array).is_empty():
			row["status"] = "absent"
		out.append(row)
	return out
