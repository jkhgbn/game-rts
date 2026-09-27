extends SceneTree
## Audio Lab (docs/plan/audio-lab.md): the Art Lab idea for sound. One command per sound set or scene: measures every
## cue (loudness, peaks, silence, tails, spectrum), reads how the code plays it (bus, volume, 3D, variation, voice
## limits) and which gameplay events have no sound, then writes a scorecard (PASS / WARN / FAIL + fix hints, a
## 0-100 score, "Improve next"), a listening sheet and the cue list for the windowed preview scene.
## Headless: streams are decoded with AudioStreamPlayback.mix_audio (the Dummy driver plays nothing).
##
## Run (Godot console exe as $GODOT; always pass --quit-after):
##   $GODOT --headless --path . -s tools/audio_lab/audio_lab.gd --quit-after 20000 -- set=res://assets/audio/sfx
##   ... -- set=res://assets/audio/mapfill_ kind=auto out=docs/audio/lab/mapfill/
##   ... -- scene=res://scenes/skirmish.tscn fight=1 --fixed-fps 60   (live players + a staged 30 s fight)
## User args (after "--"):
##   set=PATH      a folder (recursive) or a path prefix (res://assets/audio/trade_ = every trade_* file)
##   scene=PATH    a scene: its audio players (live, after it runs) and the cues its scripts can play
##   kind=K        ui / unit / spell / ambience / music / alert, or auto (default: per cue, lab_rules.gd)
##   out=DIR       default docs/audio/lab/<name>/        name=N   report name (default from the set / scene)
##   live=0|1      scene= only: run the scene to list the players it really creates (default 1)
##   fight=1       scene= only: stage a 12 v 12 fight near the hero for fight_s=30 s, measure play rates / voices
##   log=0         do not append docs/audio/lab/improvement-log.md (tests)
## Prints one line: AUDIO_LAB score=N pass=N warn=N fail=N info=N cues=N out=DIR

const Rules := preload("res://tools/audio_lab/lab_rules.gd")
const Sig := preload("res://tools/audio_lab/lab_signal.gd")
const Code := preload("res://tools/audio_lab/lab_code.gd")
const Report := preload("res://tools/audio_lab/lab_report.gd")
const FIGHT_UNITS := [["flame_guard", "shade"], ["ember_archer", "nightbolt"]]
const HERO_WAIT_FRAMES := 6000
const MIN_FIGHT_PLAYS := 40   ## Fewer plays = the staged fight was not representative: keep the expected rates.

var args := {}
var scan: Dictionary
var main: Node
var frame := 0
var phase := "none"   # none / wait / settle / fight / done
var settle_left := 0
var fight_left := 0
var fight_frames := 0
var fight := {}
var census: Array = []
var scene_scripts: Array = []
var _audio: Node
var _counts0 := {}
var _dropped0 := 0
var _busy_frames := 0
var _peak := 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		var s := a.lstrip("-")
		var eq := s.find("=")
		if eq > 0:
			args[s.substr(0, eq)] = s.substr(eq + 1)
		else:
			args[s] = "1"
	if not args.has("set") and not args.has("scene"):
		args["set"] = "res://assets/audio"
	scan = Code.scan_project()
	if args.has("scene") and str(args.get("live", "1")) != "0":
		var ps: PackedScene = load(args["scene"]) if ResourceLoader.exists(args["scene"]) else null
		if ps == null:
			print("AUDIO_LAB error: cannot load scene %s" % args["scene"])
			quit(1)
			return
		main = ps.instantiate()
		var bot := main.get_node_or_null("ShadowBot")
		if bot:
			bot.set("enabled", false)
		root.add_child(main)
		current_scene = main
		phase = "wait"
		return
	_finish()


func _process(_delta: float) -> bool:
	frame += 1
	match phase:
		"wait":
			var ready := not ("hero" in main) or main.get("hero") != null
			if ready or frame > HERO_WAIT_FRAMES:
				phase = "settle"
				settle_left = 120
		"settle":
			settle_left -= 1
			if settle_left <= 0:
				census = _census(main)
				if str(args.get("fight", "0")) == "1" and "hero" in main and main.get("hero") != null:
					_start_fight()
				else:
					phase = "done"
		"fight":
			_step_fight()
		"done":
			_finish()
			phase = "quit"
			return true
		"quit":
			return true
	return false


# ------------------------------------------------------------------ live scene

func _census(n: Node) -> Array:
	var out := []
	var models := ["ATTENUATION_INVERSE_DISTANCE", "ATTENUATION_INVERSE_SQUARE_DISTANCE", "ATTENUATION_LOGARITHMIC",
		"ATTENUATION_DISABLED"]
	var dopp := ["DOPPLER_TRACKING_DISABLED", "DOPPLER_TRACKING_IDLE_STEP", "DOPPLER_TRACKING_PHYSICS_STEP"]
	var scripts := {}
	for node: Node in [n] + n.find_children("*", "", true, false):
		var s: Script = node.get_script()
		if s and s.resource_path != "":
			scripts[s.resource_path] = true
		if not (node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D):
			continue
		var owner_script := ""
		var p := node.get_parent()
		while p != null:
			if p.get_script() and (p.get_script() as Script).resource_path != "":
				owner_script = (p.get_script() as Script).resource_path
				break
			p = p.get_parent()
		var props := {"bus": str(node.get("bus")), "volume_db": float(node.get("volume_db")),
			"max_polyphony": int(node.get("max_polyphony"))}
		var st: AudioStream = node.get("stream")
		if st:
			props["stream"] = st.resource_path
		if node is AudioStreamPlayer3D:
			var a := node as AudioStreamPlayer3D
			props["unit_size"] = a.unit_size
			props["max_distance"] = a.max_distance
			props["attenuation_model"] = models[a.attenuation_model]
			props["doppler_tracking"] = dopp[a.doppler_tracking]
		out.append({"where": "%s (%s)" % [str(main.get_path_to(node)), owner_script.get_file()], "script": owner_script,
			"class": node.get_class(), "source": "live", "props": props})
	scene_scripts = scripts.keys()
	return out


func _start_fight() -> void:
	for c in main.get_children():
		var s: Script = c.get_script()
		if s and s.resource_path.ends_with("game_audio.gd"):
			_audio = c
	if _audio == null:
		fight = {"error": "no GameAudio in the scene"}
		phase = "done"
		return
	# The fight measures play rates and voice use, not camera culling (as tests/test_6_s1.gd does).
	_audio.set(&"max_hear_distance", 1.0e6)
	var hero: Node3D = main.get("hero")
	var base :=hero.global_position + Vector3(6.0, 0.0, 0.0)
	var mine: Array = []
	var theirs: Array = []
	for pair: Array in FIGHT_UNITS:
		for i in 6:
			var off := Vector3(float(i % 3) * 1.6, 0.0, float(i / 3) * 1.6)
			var a: Node = main.call(&"make_unit", pair[0])
			var b: Node = main.call(&"make_unit", pair[1])
			if a:
				main.call(&"_spawn", a, 0, base + off)
				mine.append(a)
			if b:
				main.call(&"_spawn", b, 1, base + off + Vector3(5.0, 0.0, 0.0))
				theirs.append(b)
	for i in mine.size():
		if i < theirs.size():
			mine[i].call(&"command_attack", theirs[i])
			theirs[i].call(&"command_attack", mine[i])
	_counts0 = (_audio.get(&"play_counts") as Dictionary).duplicate()
	_dropped0 = int(_audio.get(&"dropped"))
	fight_frames = int(float(args.get("fight_s", "30")) * 60.0)
	fight_left = fight_frames
	phase = "fight"


func _step_fight() -> void:
	fight_left -= 1
	var active := int(_audio.call(&"active_voice_count"))
	var voices := int(_audio.call(&"voice_count"))
	_peak = maxi(_peak, active)
	if active >= voices:
		_busy_frames += 1
	if fight_left > 0:
		return
	var counts: Dictionary = _audio.get(&"play_counts")
	var minutes := float(fight_frames) / 60.0 / 60.0
	var rates := {}
	var played := 0
	for id in counts:
		var n := int(counts[id]) - int(_counts0.get(id, 0))
		if n > 0:
			rates[str(id)] = n / minutes
			played += n
	fight = {"seconds": fight_frames / 60.0, "rates": rates, "played": played,
		"dropped": int(_audio.get(&"dropped")) - _dropped0, "peak": _peak, "voices": voices,
		"saturation": float(_busy_frames) / maxf(float(fight_frames), 1.0)}
	phase = "done"


# ------------------------------------------------------------------ analysis

func _finish() -> void:
	var kind := str(args.get("kind", "auto"))
	if not (kind in Rules.CATEGORIES) and kind != "auto":
		print("AUDIO_LAB warning: unknown kind %s, using auto" % kind)
		kind = "auto"
	var mode := "scene" if args.has("scene") else "set"
	var target := str(args.get("scene", args.get("set", "")))
	var name := str(args.get("name", ""))
	if name == "":
		name = target.get_file().get_basename().trim_suffix("_")
		if name == "" or name == "audio":
			name = "all_audio"
	var out_dir := str(args.get("out", "res://docs/audio/lab/%s/" % name))
	if not out_dir.begins_with("res://") and not out_dir.contains(":"):
		out_dir = "res://" + out_dir
	# ---- which scripts count, which files
	var scope: Array = []
	var files: Array[String] = []
	var registry: Dictionary = scan["cues"]
	if mode == "set":
		scope = scan["scripts"]
		files = _set_files(target)
	else:
		if scene_scripts.is_empty():
			scene_scripts = _static_scene_scripts(target, 0)
		for s: String in scan["scripts"]:
			if scene_scripts.has(s):
				scope.append(s)
		var seen := {}
		for id: String in registry:
			if scope.has(registry[id]["script"]):
				seen[registry[id]["path"]] = true
		for p: Dictionary in census:
			var sp := str(p["props"].get("stream", ""))
			if sp != "" and sp.get_extension() in ["wav", "ogg", "mp3", "tres"]:
				seen[sp] = true
		for f: String in seen:
			files.append(f)
	files.sort()
	# ---- measure
	var cues := {}
	for path in files:
		cues[path.get_file().get_basename()] = _analyse(path, kind, registry)
	var bed_cues := cues
	var has_unit := false
	for id: String in cues:
		if cues[id]["category"] == "unit":
			has_unit = true
	if not has_unit:
		bed_cues = {}
		for id: String in registry:
			if Report.category_of(id, registry[id]["path"], "auto") == "unit":
				bed_cues[id] = _analyse(registry[id]["path"], "auto", registry)
	# ---- players judged
	var players: Array = []
	if mode == "set":
		var used_scripts := {}
		for id: String in cues:
			if not (cues[id]["meta"] as Dictionary).is_empty():
				used_scripts[cues[id]["meta"]["script"]] = true
		for p: Dictionary in scan["players"]:
			if used_scripts.has(p["script"]):
				players.append(p)
	else:
		players = census.duplicate()
		for p: Dictionary in scan["players"]:
			if p["source"] == "scene" and str(p["script"]) == target:
				players.append(p)
		if census.is_empty():
			for p: Dictionary in scan["players"]:
				if scope.has(p["script"]):
					players.append(p)
	var ctx := {"name": name, "mode": mode, "target": target, "kind": kind, "cues": cues, "bed_cues": bed_cues,
		"players": players, "allowed_buses": scan["allowed_buses"], "fight": fight,
		"events": Code.event_coverage(scan, scope), "log": str(args.get("log", "1")) != "0",
		"missing_scored": mode == "scene" or target.trim_suffix("/") == "res://assets/audio",
		"command": "godot --headless --path . -s tools/audio_lab/audio_lab.gd -- " + " ".join(OS.get_cmdline_user_args()),
		"pool_note": "(live)" if not census.is_empty() else "(from code)"}
	if mode == "scene" and census.is_empty():
		ctx["pool_note"] = "(static: live=0)"
	var res: Dictionary = Report.evaluate(ctx)
	Report.write(ctx, res, out_dir)
	var c: Dictionary = res["counts"]
	print("AUDIO_LAB score=%d pass=%d warn=%d fail=%d info=%d cues=%d out=%s" % [res["score"], c["PASS"], c["WARN"],
		c["FAIL"], c["INFO"], cues.size(), out_dir])
	if main:
		main.queue_free()
	quit()


func _set_files(target: String) -> Array[String]:
	var out: Array[String] = []
	var exts: Array[String] = ["wav", "ogg", "mp3"]
	if DirAccess.dir_exists_absolute(target):
		Code.list_files(target.trim_suffix("/"), exts, out)
	else:
		var all: Array[String] = []
		Code.list_files(target.get_base_dir(), exts, all)
		for f in all:
			if f.begins_with(target) and f.get_base_dir() == target.get_base_dir():
				out.append(f)
		if out.is_empty() and FileAccess.file_exists(target):
			out.append(target)
	return out


## Scripts a scene uses without running it (ext_resource scripts + instanced scenes, 3 levels).
func _static_scene_scripts(path: String, depth: int) -> Array:
	var out := []
	var t := Code.read_text(path)
	var r := RegEx.new()
	r.compile("\\[ext_resource[^\\]]*type=\"(Script|PackedScene)\"[^\\]]*path=\"([^\"]+)\"")
	for m in r.search_all(t):
		if m.get_string(1) == "Script":
			out.append(m.get_string(2))
		elif depth < 3:
			out.append_array(_static_scene_scripts(m.get_string(2), depth + 1))
	return out


func _analyse(path: String, kind: String, registry: Dictionary) -> Dictionary:
	var id := path.get_file().get_basename()
	var meta: Dictionary = registry.get(id, {})
	if not meta.is_empty() and meta["path"] != path:
		meta = {}
	# A take (<id>_1.wav next to <id>.wav) plays through its parent cue: same volume_db, 3D settings, category,
	# play rate and takes count. Its own registry entry (a PATH literal in a TAKES table) only fills the gaps.
	var parent := take_parent(path)
	var rate_id := id
	var cat := Report.category_of(id, path, kind)
	var takes := Code.count_takes(path)
	if parent != "":
		var pmeta: Dictionary = registry.get(parent, {})
		if not pmeta.is_empty():
			var merged := pmeta.duplicate()
			for k in meta:
				if meta[k] != null and not merged.has(k):
					merged[k] = meta[k]
			merged["path"] = path
			meta = merged
		rate_id = parent
		if not Rules.CATEGORY_BY_ID.has(id):
			cat = Report.category_of(parent, path, kind)
		takes = Code.count_takes(path.get_base_dir().path_join(parent + "." + path.get_extension()))
	var r := {"id": id, "path": path, "category": cat, "meta": meta, "error": "", "orphan": meta.is_empty(),
		"generated": Code.is_generated(path, scan["generators"]), "takes": takes}
	if parent != "":
		r["take_of"] = parent
	var stream: AudioStream = load(path) if ResourceLoader.exists(path) else null
	if stream == null:
		r["error"] = "cannot load"
		return r
	var d := Sig.decode(stream)
	if not d["ok"]:
		r["error"] = d["why"]
		return r
	var m := Sig.measure(d["frames"], d["rate"])
	var info := Sig.file_info(path, stream)
	r["m"] = m
	r["info"] = info
	r["memory"] = Sig.memory_bytes(info, float(m["duration_s"]))
	# Import overshoot: decoded peak vs the source .wav peak (only for compressed imports, where it can differ).
	if str(info.get("imported_format", "")) in ["QOA", "IMA-ADPCM"]:
		var sp := Sig.source_peak_dbfs(path)
		if not is_nan(sp):
			r["src_peak_dbfs"] = sp
	var metric: String = Rules.LOUDNESS[cat]["metric"]
	var fl := float(m["lufs_i"] if metric == "integrated" else m["lufs_cue"])
	r["file_level"] = fl
	var att := 0.0
	if str(meta.get("mode", "")) == "3d" and meta.get("unit_size") is float:
		att = Report.att_db(meta.get("attenuation"), float(meta["unit_size"]), Rules.REF_DISTANCE)
	r["att"] = att
	var vol: Variant = meta.get("volume_db", 0.0)
	r["level"] = fl + (float(vol) if vol is float else 0.0) + att
	# Play rate: measured in the fight, else the lab table, else guessed from the cooldown.
	var rate := 0.0
	var fr: Dictionary = fight.get("rates", {}) if int(fight.get("played", 0)) >= MIN_FIGHT_PLAYS else {}
	if fr.has(rate_id):
		rate = float(fr[rate_id])
	elif Rules.EXPECTED_RATE.has(rate_id):
		rate = float(Rules.EXPECTED_RATE[rate_id])
	elif meta.get("rate_limit_s") is float and float(meta["rate_limit_s"]) <= 0.1 and cat == "unit":
		rate = 60.0
	r["rate"] = rate
	r["frequent"] = rate >= Rules.FREQUENT_PER_MIN and not (cat in ["music", "ambience"])
	return r


## "melee_hit" for res://.../melee_hit_1.wav when melee_hit.wav|ogg|mp3 sits next to it, else "".
static func take_parent(path: String) -> String:
	var id := path.get_file().get_basename()
	var re := RegEx.new()
	re.compile("^(.+)_(\\d+|[a-z])$")
	var mt := re.search(id)
	if mt == null:
		return ""
	var parent := mt.get_string(1)
	for ext in ["wav", "ogg", "mp3"]:
		if FileAccess.file_exists(path.get_base_dir().path_join(parent + "." + ext)):
			return parent
	return ""
