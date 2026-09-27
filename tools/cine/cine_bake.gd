class_name CineBake
extends RefCounted
## Resolves a parsed .cine against its stage (markers, actors, heads, clips, vfx, audio, lines) into "baked shots":
## Dictionaries with exactly the field names of the runtime's CinematicShot / CinematicLine / CinematicAction
## (scripts/cinematics/README.md, frozen at M1), then writes data/cinematics/<id>.tres through the runtime classes
## (load-guarded: no runtime = WARN, a JSON bake is still written). Every problem = one row for the report.

const RT_DIR := "res://scripts/cinematics/"
const MODE := {"static": 0, "dolly": 1, "crane": 2, "orbit": 3, "rail": 4, "follow": 5}
const TRANS_IN := {"cut": 0, "fade_black": 1, "fade_white": 2, "blend": 3}
const EASES := {"in": Tween.EASE_IN, "out": Tween.EASE_OUT, "in_out": Tween.EASE_IN_OUT, "out_in": Tween.EASE_OUT_IN}
const TRANS := {"linear": Tween.TRANS_LINEAR, "sine": Tween.TRANS_SINE, "quad": Tween.TRANS_QUAD, "cubic": Tween.TRANS_CUBIC,
	"quart": Tween.TRANS_QUART, "quint": Tween.TRANS_QUINT, "expo": Tween.TRANS_EXPO, "circ": Tween.TRANS_CIRC,
	"back": Tween.TRANS_BACK}
## Clip ids cine can play without tool 5 (Motion Lab): id -> model hook (+ arg). A clip outside this table and outside
## tool 5's clip files is an unknown clip (FAIL).
const CLIP_FALLBACK := {"cast": ["play_cast", "cast"], "attack": ["play_attack", ""], "hit": ["play_hit", ""],
	"death": ["play_death", ""], "level_up": ["play_level_up", ""], "staff_slam": ["play_cast", "staff_slam"],
	"draw_knife": ["play_attack", ""], "slash": ["play_attack", ""], "kneel": ["play_gesture", "kneel"],
	"bow": ["play_gesture", "bow"], "point": ["play_gesture", "point"], "nod": ["play_gesture", "nod"],
	"turn_head_left": ["play_gesture", "turn_head_left"], "turn_head_right": ["play_gesture", "turn_head_right"]}
const MOTION_DIR := "res://art/motion/"
const VFX_DIR := "res://art/vfx/composer/"
const LENS_DIR := "res://tools/lens/"
const SIZES := {"ecu": 0.4, "cu": 0.75, "mcu": 1.05, "ms": 1.6, "mls": 2.2, "ws": 3.6, "ews": 9.0}
const SIZE_DROP := {"ecu": 0.0, "cu": 0.05, "mcu": 0.12, "ms": 0.3, "mls": 0.55, "ws": -1.0, "ews": -1.0}
const ANGLES := {"front": 0.0, "3/4 left": 45.0, "3/4 right": -45.0, "profile left": 90.0, "profile right": -90.0,
	"back": 180.0}
const HEIGHTS := {"eye": 0.0, "low": -0.22, "high": 0.35, "top": 1.2}
const BAND_FRAC := 0.744   # 2.39 band / 16:9 frame height (1 - 2 x 115 / 900)

var doc: CineDoc
var stage: CineStage
var shots: Array[Dictionary] = []        # baked (resource field names) + "src_line", "faces", "fallback_cam"
var problems: Array[Dictionary] = []     # {status, group, name, value, rule, hint, line}
var partner: Dictionary = {}             # tool -> "present" / "missing"
var _pos: Dictionary = {}                # tag -> Vector3 (actor position at the current shot start)
var _yaw: Dictionary = {}
var _clip_ids: Array = []
var _vfx_ids: Array = []
var line_track: Dictionary = {}          # shot id -> [{at, speaker, text, duration}] from tool 10
var _cur_set := ""                       # the set of the shot being baked (multi-set movies)
var _voices: Dictionary = {}             # "speaker\nnorm text" -> {path, duration} (data/voice/manifest.json)
const VOICE_MANIFEST := "res://data/voice/manifest.json"


static func run(p_doc: CineDoc, p_stage: CineStage) -> CineBake:
	var b := CineBake.new()
	b.doc = p_doc
	b.stage = p_stage
	b._partners()
	b._load_lines()
	b._load_voices()
	if p_doc.music != "" and not ResourceLoader.exists(p_doc.music):
		b.problem("FAIL", "resolve", "use music", "missing file " + p_doc.music, "audio paths exist", "fix the res:// path", p_doc.music_line)
	for tag: String in p_stage.actor_start:
		b._pos[tag] = p_stage.actor_start[tag]["pos"]
		b._yaw[tag] = float(p_stage.actor_start[tag]["yaw"])
	for s: Dictionary in p_doc.shots:
		b.shots.append(b._shot(s))
	return b


func problem(status: String, group: String, what: String, value: String, rule: String, hint: String, line: ToolSpecLine) -> void:
	problems.append({"status": status, "group": group, "name": what, "value": value, "rule": rule, "hint": hint, "line": line})


func _fail_count() -> int:
	var n := 0
	for p: Dictionary in problems:
		if p["status"] == "FAIL":
			n += 1
	return n


func head_of(tag: String) -> float:
	return float(stage.actor_start.get(tag, {}).get("head", CineStage.DEFAULT_HEAD))


# ---------------------------------------------------------------- partners

func _partners() -> void:
	partner["runtime"] = "present" if ResourceLoader.exists(RT_DIR + "cinematic_shot.gd") else "missing"
	partner["player"] = "present" if ResourceLoader.exists(RT_DIR + "cinematic_player.gd") else "missing"
	partner["motion"] = "present" if DirAccess.dir_exists_absolute(MOTION_DIR) else "missing"
	partner["vfx"] = "present" if DirAccess.dir_exists_absolute(VFX_DIR) else "missing"
	partner["lens"] = "present" if DirAccess.dir_exists_absolute(LENS_DIR) else "missing"
	if partner["motion"] == "present":
		_clip_ids = _basenames(MOTION_DIR, ["tres", "res", "json", "clip", "gd"])
	if partner["vfx"] == "present":
		_vfx_ids = _basenames(VFX_DIR, ["tres", "tscn", "vfx", "json"])


static func _basenames(dir: String, exts: Array) -> Array:
	var out: Array = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f: String in d.get_files():
		if f.get_extension() in exts:
			out.append(f.get_basename().get_basename())
	for sub: String in d.get_directories():
		out.append_array(_basenames(dir.path_join(sub), exts))
	return out


func _load_lines() -> void:
	if doc.lines_path == "":
		return
	var p := doc.lines_path if doc.lines_path.begins_with("res://") else "res://" + doc.lines_path
	if not FileAccess.file_exists(p):
		problem("WARN", "resolve", "line track " + doc.lines_path, "not found", "tool 10 LineTrack JSON exists",
			"write it with Script Desk (tool 10) or put the lines in the .cine (`at 1.0 line vessa \"...\"`)", doc.lines_line)
		return
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(p))
	if not d is Dictionary or not (d as Dictionary).get("lines") is Dictionary:
		problem("FAIL", "resolve", "line track " + doc.lines_path, "not a LineTrack", "{cine_id, lines: {shot: [...]}}",
			"fix the JSON (tools-wave.md 13.2 LineTrack)", doc.lines_line)
		return
	line_track = (d as Dictionary)["lines"]


## Voice Forge manifest (data/voice/manifest.json): the WAV of a line, matched on speaker + text like VoicePlayer.
func _load_voices() -> void:
	if not FileAccess.file_exists(VOICE_MANIFEST):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(VOICE_MANIFEST))
	if not data is Dictionary or not (data as Dictionary).get("lines") is Dictionary:
		return
	for k: String in data["lines"]:
		var e: Variant = data["lines"][k]
		if not e is Dictionary:
			continue
		var entry := {"path": String(e.get("path", "")), "duration": float(e.get("duration", 0.0))}
		if entry["path"] == "" or not ResourceLoader.exists(entry["path"]):
			continue
		var tx := norm_text(String(e.get("text", "")))
		_voices[String(e.get("speaker", "")).to_lower() + "\n" + tx] = entry
		for src: Variant in e.get("sources", []):
			if src is Dictionary and (src as Dictionary).has("speaker_id"):
				_voices[String(src["speaker_id"]).to_lower() + "\n" + tx] = entry


func voice_of(speaker: String, text: String) -> Dictionary:
	return _voices.get(speaker.to_lower() + "\n" + norm_text(text), {})


static func norm_text(text: String) -> String:
	return " ".join(text.replace("|", " ").replace("\n", " ").split(" ", false)).strip_edges()


# ---------------------------------------------------------------- names -> positions

func all_markers() -> Array:
	var out: Array = []
	out.append_array(doc.marks.keys())
	out.append_array(stage.set_marks.keys())
	return out


func _marker(name: String) -> Variant:
	if doc.marks.has(name):
		return doc.marks[name]
	var sm := stage.marks_of(_cur_set)
	if sm.has(name):
		return sm[name]
	return null


## The shot's set is not built yet (its shots fall back to a proxy camera, WARN once per set).
func _set_missing() -> bool:
	if stage.multi:
		return _cur_set != "" and not stage.has_set(_cur_set)
	return doc.set_id != "" and not stage.set_found


## A position token: (x,y,z) | @marker | actor | actor+(dx,dy,dz). Returns {ok, pos, actor, missing_set}.
## `look` = an actor means its head point. Problems are recorded against `line`.
func pos_of(tok: String, line: ToolSpecLine, what: String, look: bool) -> Dictionary:
	var v: Variant = ToolSpec.vec_of(tok)
	if v is Vector3:
		return {"ok": true, "pos": v, "actor": ""}
	if tok.begins_with("@"):
		var m: Variant = _marker(tok.substr(1))
		if m != null:
			return {"ok": true, "pos": m, "actor": ""}
		if _set_missing():
			return {"ok": false, "pos": Vector3.ZERO, "actor": "", "missing_set": true}
		var near := ToolSpec.nearest(tok.substr(1), all_markers())
		problem("FAIL", "resolve", "marker " + tok, "missing (%s)" % what, "every @marker exists in the set or a mark line",
			("did you mean \"@%s\"? " % near if near != "" else "") + "add `mark %s (x, y, z)` or the marker to the set" % tok.substr(1), line)
		return {"ok": false, "pos": Vector3.ZERO, "actor": ""}
	var base := tok
	var off := Vector3.ZERO
	var plus := tok.find("+(")
	if plus > 0:
		base = tok.substr(0, plus)
		var ov: Variant = ToolSpec.vec_of(tok.substr(plus + 1))
		if ov is Vector3:
			off = ov
	if _pos.has(base):
		var p: Vector3 = _pos[base] + off
		if look and plus < 0:
			p += Vector3(0, head_of(base), 0)
		return {"ok": true, "pos": p, "actor": base if plus < 0 else ""}
	var cands: Array = stage.actor_tags()
	var near2 := ToolSpec.nearest(base, cands + all_markers())
	problem("FAIL", "resolve", "name \"%s\"" % base, "not an actor, marker or (x, y, z) (%s)" % what,
		"actors come from cast lines / set puppets", ("did you mean \"%s\"?" % near2) if near2 != "" else "cast it: `cast %s res://... at=(x, y, z)`" % base, line)
	return {"ok": false, "pos": Vector3.ZERO, "actor": ""}


func _actor_ok(tag: String, line: ToolSpecLine, what: String) -> bool:
	if stage.actors.has(tag):
		return true
	var n := ToolSpec.nearest(tag, stage.actor_tags())
	problem("FAIL", "resolve", "actor \"%s\"" % tag, "unknown (%s)" % what, "every actor is cast or a set puppet",
		("did you mean \"%s\"?" % n) if n != "" else "add `cast %s res://... at=(x, y, z)`" % tag, line)
	return false


# ---------------------------------------------------------------- one shot

func _shot(s: Dictionary) -> Dictionary:
	var l: ToolSpecLine = s["line"]
	var kv: Dictionary = s["kv"]
	var b := {"id": s["id"], "duration": float(s["dur"]), "camera_mode": 0, "from_pos": Vector3(0, 2, 6), "to_pos": Vector3(0, 2, 6),
		"look_from": Vector3.ZERO, "look_to": Vector3.ZERO, "look_actor": "", "look_offset": Vector3(0, 1.6, 0),
		"pivot_actor": "", "pivot": Vector3.ZERO, "orbit_radius": 6.0, "orbit_height": 2.0, "orbit_from_deg": 0.0,
		"orbit_to_deg": 90.0, "rail": "", "follow_actor": "", "follow_offset": Vector3(0, 3, 6), "fov_from": 40.0,
		"fov_to": 40.0, "roll_deg": float(String(kv.get("roll", "0")).to_float()), "ease_type": Tween.EASE_IN_OUT,
		"trans_type": Tween.TRANS_SINE, "transition_in": 0, "transition_time": 0.5, "shake": String(kv.get("shake", "0")).to_float(),
		"dof_far": String(kv.get("dof", "0")).to_float(), "branch_flag": String(kv.get("branch", "")),
		"stage_set": doc.set_id, "marker_prefix": "", "lines": [], "actions": [],
		"src_line": l.line, "cam": s["cam"], "faces": [], "fallback_cam": false}
	# fov
	var fv := ToolSpec.fromto(String(kv.get("fov", "")))
	if String(kv.get("fov", "")) != "":
		for i: int in 2:
			if not fv[i].is_valid_float():
				problem("FAIL", "parse", "fov", fv[i], "fov=<deg> or fov=<a>><b>", "e.g. fov=38>32", l)
		b["fov_from"] = fv[0].to_float() if fv[0].is_valid_float() else 40.0
		b["fov_to"] = fv[1].to_float() if fv[1].is_valid_float() else b["fov_from"]
	# transition
	var tin := String(kv.get("in", "cut"))
	var tname := tin.get_slice(":", 0)
	if TRANS_IN.has(tname):
		b["transition_in"] = TRANS_IN[tname]
		if ":" in tin:
			b["transition_time"] = tin.get_slice(":", 1).to_float()
	else:
		problem("FAIL", "parse", "in=" + tin, "unknown transition", "cut | fade_black[:s] | fade_white[:s] | blend[:s]",
			("did you mean \"%s\"?" % ToolSpec.nearest(tname, TRANS_IN.keys())), l)
	if kv.has("ease"):
		if EASES.has(kv["ease"]):
			b["ease_type"] = EASES[kv["ease"]]
		else:
			problem("FAIL", "parse", "ease=" + String(kv["ease"]), "unknown ease", "in | out | in_out | out_in", "did you mean \"%s\"?" % ToolSpec.nearest(kv["ease"], EASES.keys()), l)
	if kv.has("trans"):
		if TRANS.has(kv["trans"]):
			b["trans_type"] = TRANS[kv["trans"]]
		else:
			problem("FAIL", "parse", "trans=" + String(kv["trans"]), "unknown curve", ", ".join(PackedStringArray(TRANS.keys())), "did you mean \"%s\"?" % ToolSpec.nearest(kv["trans"], TRANS.keys()), l)
	if kv.has("set"):
		b["stage_set"] = String(kv["set"])
	_cur_set = String(b["stage_set"])
	# faces
	var faces: Array = []
	for f: String in ToolSpec.list_of(String(kv.get("faces", ""))):
		if _actor_ok(f, l, "faces="):
			faces.append(f)
	# camera (a camera that failed to resolve falls back to a proxy view: its framing / axis rows SKIP, so one bug = one FAIL)
	var fails_before := _fail_count()
	_camera(s, b, faces)
	if _fail_count() > fails_before and not b["fallback_cam"]:
		b["fallback_cam"] = true
		_proxy_cam(b, faces)
	b["faces"] = faces
	# lines (inline + tool 10 track)
	var lines: Array = s["lines"].duplicate()
	for tl: Variant in line_track.get(s["id"], []):
		if tl is Dictionary:
			lines.append({"at": float(tl.get("at", 0.0)), "speaker": String(tl.get("speaker", "")), "text": String(tl.get("text", "")),
				"dur": float(tl.get("duration", 0.0)), "voice": "", "line": doc.lines_line})
	for ln: Dictionary in lines:
		var vo := String(ln.get("voice", ""))
		var vdur := 0.0
		if vo == "":
			var ve: Dictionary = voice_of(String(ln["speaker"]), String(ln["text"]))
			vo = String(ve.get("path", ""))
			vdur = float(ve.get("duration", 0.0))
		elif not ResourceLoader.exists(vo):
			problem("FAIL", "resolve", "voice " + vo.get_file(), "missing file " + vo, "voice= paths exist", "fix the res:// path or drop voice= (the manifest is used)", ln["line"])
			vo = ""
		b["lines"].append({"at": ln["at"], "speaker": ln["speaker"], "text": ln["text"], "duration": ln["dur"],
			"voice": vo, "voice_dur": vdur, "src_line": (ln["line"] as ToolSpecLine).line if ln["line"] != null else 0})
	# actions
	for a: Dictionary in s["actions"]:
		var ba: Variant = _action(a, float(s["dur"]))
		if ba != null:
			b["actions"].append(ba)
	_set_cues(b, l)
	# actors' end states become the next shot's start
	var acts: Array = b["actions"].duplicate()
	acts.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return float(x["at"]) < float(y["at"]))
	for ba2: Dictionary in acts:
		var tag: String = ba2["actor"]
		if tag == "" or not _pos.has(tag):
			continue
		match String(ba2["kind"]):
			"move":
				var d: Vector3 = ba2["target"] - _pos[tag]
				if Vector2(d.x, d.z).length() > 0.01:
					_yaw[tag] = rad_to_deg(atan2(d.x, d.z))
				_pos[tag] = ba2["target"]
			"teleport":
				_pos[tag] = ba2["target"]
				if (ba2["params"] as Dictionary).has("yaw_deg"):
					_yaw[tag] = float(ba2["params"]["yaw_deg"])
			"face":
				if (ba2["params"] as Dictionary).has("yaw_deg"):
					_yaw[tag] = float(ba2["params"]["yaw_deg"])
	return b


## Set cue API (scripts/cinematics/README.md section 4): the shot's set may define `cine_cues(shot_id) -> Array` of
## cue Dictionaries (its own spell VFX / sfx / anims). They are baked as ordinary actions (params `from_set`, so the
## runtime does not merge them twice) and so show in stills, the timing sheet, play / record and the .tres.
const SET_CUE_KINDS := ["vfx", "sfx", "anim", "clip", "shake"]
const SET_CUE_KEYS := ["scene", "vfx_id", "life", "scale", "yaw", "hook", "arg", "path", "volume_db", "amount", "travel_time"]
func _set_cues(b: Dictionary, l: ToolSpecLine) -> void:
	var sn: Node = stage.find_set(StringName(_cur_set)) if _cur_set != "" else null
	if sn == null or not sn.has_method(&"cine_cues"):
		return
	var cues: Variant = sn.call(&"cine_cues", StringName(String(b["id"])))
	if not cues is Array:
		return
	var xf := (sn as Node3D).global_transform if sn is Node3D and (sn as Node3D).is_inside_tree() else Transform3D.IDENTITY
	for c: Variant in cues:
		if not c is Dictionary:
			continue
		var d: Dictionary = c
		var kind := String(d.get("kind", "vfx"))
		if not kind in SET_CUE_KINDS:
			problem("WARN", "resolve", "set cue %s %s" % [_cur_set, kind], "kind not allowed in a set cue (skipped)", "set cues: " + ", ".join(PackedStringArray(SET_CUE_KINDS)), "put it in the .cine", l)
			continue
		var p: Dictionary = (d["params"] as Dictionary).duplicate() if d.get("params") is Dictionary else {}
		for k: String in SET_CUE_KEYS:
			if d.has(k):
				p[k] = d[k]
		if d.get("to") is Vector3:
			p["to"] = xf * (d["to"] as Vector3)
		p["from_set"] = true
		var sc := String(p.get("scene", ""))
		if sc != "" and not ResourceLoader.exists(sc):
			problem("FAIL", "resolve", "set cue %s vfx" % _cur_set, "missing " + sc, "res:// scene exists", "fix the set's cine_cues()", l)
			continue
		if kind == "vfx" and sc != "" and not p.has("life"):
			p["life"] = 3.0
		var tag := String(d.get("actor", ""))
		if tag != "" and not stage.actors.has(tag):
			problem("WARN", "resolve", "set cue actor \"%s\"" % tag, "unknown (cue kept without actor)", "cue actors are cast / set puppets", "fix the set's cine_cues()", l)
			tag = ""
		var at := clampf(float(d.get("at", 0.0)), 0.0, float(b["duration"]))
		var tgt: Vector3 = d["target"] if d.get("target") is Vector3 else Vector3.ZERO
		b["actions"].append({"at": at, "kind": kind, "actor": tag, "target": xf * tgt, "params": p, "on_skip": true, "src_line": l.line})


func _camera(s: Dictionary, b: Dictionary, faces: Array) -> void:
	var l: ToolSpecLine = s["line"]
	var kv: Dictionary = s["kv"]
	var cam: String = s["cam"]
	var sid: String = s["id"]
	var missing_set := false
	match cam:
		"marks":
			var f: Variant = _marker(sid + "_from")
			if f == null:
				if _set_missing():
					missing_set = true
				else:
					problem("FAIL", "resolve", "shot %s camera" % sid, "no cam= and no marks for %s" % sid,
						"a shot names cam=<mode> or has marks <shot>", "add `cam=frame \"ms on <actor>\"` or `marks %s from=... look=...`" % sid, l)
					missing_set = true
			else:
				b["marker_prefix"] = sid if stage.marks_of(_cur_set).has(sid + "_from") else ""
				b["from_pos"] = f
				var t: Variant = _marker(sid + "_to")
				b["to_pos"] = t if t != null else f
				var lf: Variant = _marker(sid + "_look_from")
				var lt: Variant = _marker(sid + "_look_to")
				b["look_from"] = lf if lf != null else (f as Vector3) + Vector3.FORWARD
				b["look_to"] = lt if lt != null else b["look_from"]
				b["camera_mode"] = MODE["dolly"] if not (b["from_pos"] as Vector3).is_equal_approx(b["to_pos"]) else MODE["static"]
				# the set's marks name the subject they frame: judge its face like a look= actor
				var subj := stage.subject_of(_cur_set, sid)
				if subj != "" and _pos.has(subj) and not subj in faces:
					faces.append(subj)
				if not kv.has("fov"):
					b["fov_from"] = float(doc.mark_fov.get(sid + "_from", stage.mark_fov_of(_cur_set).get(sid + "_from", 40.0)))
					b["fov_to"] = float(doc.mark_fov.get(sid + "_to", stage.mark_fov_of(_cur_set).get(sid + "_to", b["fov_from"])))
		"static", "dolly", "crane":
			b["camera_mode"] = MODE[cam]
			var fr := pos_of(String(kv.get("from", "")), l, "from=", false) if kv.has("from") else {"ok": false}
			if not kv.has("from"):
				problem("FAIL", "parse", "shot %s from=" % sid, "missing", "cam=%s needs from=" % cam, "add from=@%s_from or from=(x, y, z)" % sid, l)
			missing_set = missing_set or fr.get("missing_set", false)
			if fr["ok"]:
				b["from_pos"] = fr["pos"]
				b["to_pos"] = fr["pos"]
				if String(fr.get("from", "")).begins_with("@"):
					pass
			if kv.has("to"):
				var to := pos_of(String(kv["to"]), l, "to=", false)
				missing_set = missing_set or to.get("missing_set", false)
				if to["ok"]:
					b["to_pos"] = to["pos"]
			if String(kv.get("from", "")) == "@%s_from" % sid and stage.marks_of(_cur_set).has(sid + "_from"):
				b["marker_prefix"] = sid
			_look(kv, l, b, faces)
			missing_set = missing_set or b.get("_ms", false)
		"orbit":
			b["camera_mode"] = MODE["orbit"]
			var pv := String(kv.get("pivot", ""))
			if pv == "":
				problem("FAIL", "parse", "shot %s pivot=" % sid, "missing", "cam=orbit needs pivot=<actor | @marker | (x,y,z)>", "add pivot=<actor>", l)
			elif _pos.has(pv):
				b["pivot_actor"] = pv
				b["pivot"] = _pos[pv]
				b["look_offset"] = Vector3(0, head_of(pv), 0)
				if not pv in faces:
					faces.append(pv)
			else:
				var pp := pos_of(pv, l, "pivot=", false)
				missing_set = missing_set or pp.get("missing_set", false)
				b["pivot"] = pp["pos"]
				b["look_offset"] = Vector3(0, 1.2, 0)
			b["orbit_radius"] = String(kv.get("r", "6")).to_float()
			b["orbit_height"] = String(kv.get("h", "2")).to_float()
			var dg := ToolSpec.fromto(String(kv.get("deg", "0>90")))
			b["orbit_from_deg"] = dg[0].to_float()
			b["orbit_to_deg"] = dg[1].to_float()
		"follow":
			b["camera_mode"] = MODE["follow"]
			var fa := String(kv.get("actor", ""))
			if _actor_ok(fa, l, "follow actor="):
				b["follow_actor"] = fa
				b["look_offset"] = Vector3(0, head_of(fa), 0)
				if not fa in faces:
					faces.append(fa)
			var ov: Variant = ToolSpec.vec_of(String(kv.get("offset", "(0,3,6)")))
			if ov is Vector3:
				b["follow_offset"] = ov
		"rail":
			b["camera_mode"] = MODE["rail"]
			b["rail"] = String(kv.get("rail", sid + "_rail"))
			problem("WARN", "resolve", "shot %s rail" % sid, "rail cameras are not evaluated by cine checks", "checks need a pure camera",
				"prefer dolly / crane between marks; the runtime still plays the rail", l)
			_look(kv, l, b, faces)
		"frame", "lens":
			if cam == "lens":
				var spec_path := String(kv.get("lens_spec", ""))
				if spec_path != "" and FileAccess.file_exists(spec_path):
					_lens_spec(spec_path, b)
					return
				if spec_path == "" and _lens_solve(String(s["words"]), l, b, faces, kv):
					return
				problem("WARN", "resolve", "shot %s cam=lens" % sid,
					"tool 3 Lens %s: built-in framer used" % ("output missing" if partner["lens"] == "present" else "not installed"),
					"lens shots come from tool 3 CameraSpec", "run Lens for this shot (lens_spec=<camera.json>) or write cam=frame", l)
			_frame(String(s["words"]), l, b, faces, String(kv.get("push", "0")).to_float())
	if missing_set:
		b["fallback_cam"] = true
		_proxy_cam(b, faces)


func _look(kv: Dictionary, l: ToolSpecLine, b: Dictionary, faces: Array) -> void:
	if not kv.has("look"):
		problem("FAIL", "parse", "shot %s look=" % b["id"], "missing", "the camera needs look=<actor | @marker | (x,y,z)>[><...>]",
			"add look=<actor>", l)
		return
	var lk := ToolSpec.fromto(String(kv["look"]))
	var a := pos_of(lk[0], l, "look=", true)
	var c := pos_of(lk[1], l, "look=", true) if lk[1] != lk[0] else a
	if a.get("missing_set", false) or c.get("missing_set", false):
		b["_ms"] = true
	if String(a["actor"]) != "" and a["actor"] == c["actor"]:
		b["look_actor"] = a["actor"]
		b["look_offset"] = Vector3(0, head_of(a["actor"]), 0)
		if not String(a["actor"]) in faces:
			faces.append(String(a["actor"]))
	b["look_from"] = a["pos"]
	b["look_to"] = c["pos"]


## A default camera on the shot's faces when the set (tool 6) is missing: 5 m in front of the first face, eye height.
func _proxy_cam(b: Dictionary, faces: Array) -> void:
	var tag: String = faces[0] if not faces.is_empty() else (stage.actor_tags()[0] if not stage.actor_tags().is_empty() else "")
	var c := Vector3(0, 1.6, 0)
	var yaw := 0.0
	if tag != "":
		c = _pos[tag] + Vector3(0, head_of(tag), 0)
		yaw = float(_yaw.get(tag, 0.0))
	var dir := Vector3(sin(deg_to_rad(yaw)), 0, cos(deg_to_rad(yaw)))
	b["camera_mode"] = MODE["static"]
	b["from_pos"] = c + dir * 5.0
	b["to_pos"] = b["from_pos"]
	b["look_from"] = c
	b["look_to"] = c


## `cam=lens "<words>"` without lens_spec=: tool 3's LensSolver solves the camera at bake time on the actors' poses at
## this shot's start (docs/handoff/for-cine.md). Load-guarded; false = Lens missing (the caller falls back to the framer).
func _lens_solve(words: String, l: ToolSpecLine, b: Dictionary, faces: Array, kv: Dictionary) -> bool:
	if not ResourceLoader.exists(LENS_DIR + "lens_solver.gd"):
		return false
	var ls: Script = load(LENS_DIR + "lens_solver.gd")
	if ls == null:
		return false
	var subs := {}
	for tag: String in _pos:
		subs[tag] = ls.call(&"subject", _pos[tag], float(_yaw.get(tag, 0.0)), maxf(0.5, head_of(tag) / 0.92))
	var fov := String(kv.get("fov", "40")).to_float() if String(kv.get("fov", "")).is_valid_float() else 40.0
	var cam: Dictionary = ls.call(&"solve_words", words, subs, {"res": Vector2i(1600, 900), "band": doc.letterbox if doc.letterbox > 0.0 else 2.39, "fov": fov})
	if not bool(cam.get("ok", false)):
		var errs: Array = cam.get("errors", [])
		var e0: Dictionary = errs[0] if not errs.is_empty() and errs[0] is Dictionary else {}
		problem("FAIL", "resolve", "shot %s cam=lens" % b["id"], "Lens: %s" % String(e0.get("message", "no camera")),
			"Lens solves the words on this shot's actors", String(e0.get("hint", "check the words (run_lens.ps1 help)")), l)
		b["fallback_cam"] = true
		_proxy_cam(b, faces)
		return true
	var a: Dictionary = cam.get("a", cam)
	var z: Dictionary = cam.get("b", a)
	b["from_pos"] = a["pos"]
	b["to_pos"] = z["pos"]
	b["look_from"] = a["look"]
	b["look_to"] = z["look"]
	b["fov_from"] = float(a.get("fov", fov))
	b["fov_to"] = float(z.get("fov", b["fov_from"]))
	b["camera_mode"] = MODE["dolly"] if not (b["from_pos"] as Vector3).is_equal_approx(b["to_pos"]) else MODE["static"]
	for tag2: Variant in (cam.get("head_ndc", {}) as Dictionary).keys():
		if _pos.has(String(tag2)) and not String(tag2) in faces:
			faces.append(String(tag2))
	return true


func _lens_spec(path: String, b: Dictionary) -> void:
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not d is Dictionary:
		return
	var a: Dictionary = (d as Dictionary).get("a", d)
	var z: Dictionary = (d as Dictionary).get("b", a)
	var v := func(x: Variant) -> Vector3: return Vector3(float(x[0]), float(x[1]), float(x[2])) if x is Array else Vector3.ZERO
	b["from_pos"] = v.call(a.get("pos"))
	b["to_pos"] = v.call(z.get("pos"))
	b["look_from"] = v.call(a.get("look"))
	b["look_to"] = v.call(z.get("look"))
	b["fov_from"] = float(a.get("fov", 40.0))
	b["fov_to"] = float(z.get("fov", b["fov_from"]))
	b["camera_mode"] = MODE["dolly"]


## Built-in framer: "mcu on vessa, 3/4 left, low, thirds left" | "ms on vessa and shade" | "cu on shade, ots vessa".
func _frame(words: String, l: ToolSpecLine, b: Dictionary, faces: Array, push: float) -> void:
	var parts := words.to_lower().split(",", false)
	var first := parts[0].strip_edges() if parts.size() > 0 else ""
	var size := first.get_slice(" on ", 0).strip_edges()
	var who := first.get_slice(" on ", 1).strip_edges() if " on " in first else ""
	if not SIZES.has(size):
		problem("FAIL", "parse", "frame size \"%s\"" % size, "unknown", ", ".join(PackedStringArray(SIZES.keys())),
			"did you mean \"%s\"?" % ToolSpec.nearest(size, SIZES.keys()), l)
		size = "ms"
	var subj: Array[String] = []
	for w: String in who.split(" and ", false):
		var t := w.strip_edges()
		if _actor_ok(t, l, "frame subject"):
			subj.append(t)
	if subj.is_empty():
		return
	var angle := 0.0
	var height := 0.0
	var thirds := 0.0
	var ots := ""
	var ots_side := 1.0
	for i: int in range(1, parts.size()):
		var p := parts[i].strip_edges()
		if ANGLES.has(p):
			angle = ANGLES[p]
		elif HEIGHTS.has(p):
			height = HEIGHTS[p]
		elif p == "thirds left":
			thirds = -1.0
		elif p == "thirds right":
			thirds = 1.0
		elif p == "center":
			thirds = 0.0
		elif p.begins_with("ots "):
			var ow := p.substr(4).strip_edges().split(" ", false)
			ots = ow[0] if ow.size() > 0 else ""
			ots_side = -1.0 if ow.size() > 1 and ow[1] == "left" else 1.0
			if not _actor_ok(ots, l, "ots"):
				ots = ""
		else:
			var all: Array = ANGLES.keys() + HEIGHTS.keys() + ["thirds left", "thirds right", "center", "ots <actor>"]
			problem("FAIL", "parse", "frame word \"%s\"" % p, "unknown", "angle / height / thirds / ots words (README)",
				"did you mean \"%s\"?" % ToolSpec.nearest(p, all), l)
	var fov := float(b["fov_from"])
	var heads: Array[Vector3] = []
	for t2: String in subj:
		heads.append(_pos[t2] + Vector3(0, head_of(t2), 0))
		if not t2 in faces:
			faces.append(t2)
	var c := Vector3.ZERO
	for h: Vector3 in heads:
		c += h
	c /= float(heads.size())
	var fh: float = SIZES[size]
	var drop: float = SIZE_DROP[size]
	var ground_y: float = _pos[subj[0]].y
	if drop < 0.0:
		c.y = ground_y + (c.y - ground_y) * 0.55
	else:
		c.y -= drop
	var yaw := float(_yaw.get(subj[0], 0.0))
	if heads.size() > 1:
		var ab := heads[1] - heads[0]
		ab.y = 0.0
		fh = maxf(fh, (ab.length() + 1.4) / 2.39 * 1.1)
		var perp := Vector3(-ab.z, 0, ab.x).normalized()
		var avg := Vector3.ZERO
		for t3: String in subj:
			avg += Vector3(sin(deg_to_rad(_yaw[t3])), 0, cos(deg_to_rad(_yaw[t3])))
		if perp.dot(avg) < 0.0:
			perp = -perp
		yaw = rad_to_deg(atan2(perp.x, perp.z))
	var dist := fh / (2.0 * tan(deg_to_rad(fov) * 0.5) * BAND_FRAC)
	var a := deg_to_rad(yaw + angle)
	var dir := Vector3(sin(a), 0, cos(a))
	var pos := c + dir * dist + Vector3(0, height * dist, 0)
	var look := c
	if ots != "":
		var oh: Vector3 = _pos[ots] + Vector3(0, head_of(ots), 0)
		var to_subj := (c - oh)
		to_subj.y = 0.0
		to_subj = to_subj.normalized()
		var right := to_subj.cross(Vector3.UP).normalized()
		pos = oh - to_subj * 1.6 + right * 0.85 * ots_side + Vector3(0, 0.3, 0)
		dist = pos.distance_to(c)
	if thirds != 0.0:
		var fwd := (look - pos).normalized()
		var right2 := fwd.cross(Vector3.UP).normalized()
		var half_w := dist * tan(deg_to_rad(fov) * 0.5) * (16.0 / 9.0)
		look -= right2 * (thirds * half_w / 3.0)
	b["camera_mode"] = MODE["static"]
	b["from_pos"] = pos
	b["to_pos"] = pos
	if push != 0.0:
		b["camera_mode"] = MODE["dolly"]
		b["to_pos"] = pos + (look - pos).normalized() * push
	b["look_from"] = look
	b["look_to"] = look


# ---------------------------------------------------------------- actions

func _action(a: Dictionary, dur: float) -> Variant:
	var l: ToolSpecLine = a["line"]
	var kind: String = a["kind"]
	var args: PackedStringArray = a["args"]
	var kv: Dictionary = a["kv"]
	var at := float(a["at"])
	if at < 0.0 or at > dur:
		problem("FAIL", "timing", "at %.2f %s" % [at, kind], "outside the shot (0..%.2f s)" % dur, "0 <= at <= shot duration",
			"move it into the shot or lengthen the shot", l)
	var out := {"at": at, "kind": kind, "actor": "", "target": Vector3.ZERO, "params": {}, "on_skip": true, "src_line": l.line}
	var p: Dictionary = out["params"]
	match kind:
		"move", "teleport", "face", "anim", "clip", "show", "hide":
			var tag := args[0] if args.size() > 0 else ""
			if not _actor_ok(tag, l, kind):
				return null
			out["actor"] = tag
			match kind:
				"move", "teleport":
					var tp := pos_of(String(kv.get("to", "")), l, "to=", false) if kv.has("to") else {"ok": false}
					if not kv.has("to"):
						problem("FAIL", "parse", "%s %s" % [kind, tag], "no to=", "%s <actor> to=<pos>" % kind, "add to=(x, y, z) or to=@marker", l)
						return null
					out["target"] = tp["pos"]
					if kind == "move":
						p["speed"] = float(String(kv.get("speed", "2.0")).to_float())
					elif kv.has("yaw"):
						p["yaw_deg"] = String(kv["yaw"]).to_float()
				"face":
					if kv.has("yaw"):
						p["yaw_deg"] = String(kv["yaw"]).to_float()
					elif kv.has("to"):
						var ft := String(kv["to"])
						if _pos.has(ft):
							p["look_actor"] = ft
							var d: Vector3 = _pos[ft] - _pos[tag]
							p["yaw_deg"] = rad_to_deg(atan2(d.x, d.z))
						else:
							var fp := pos_of(ft, l, "face to=", false)
							var d2: Vector3 = fp["pos"] - _pos[tag]
							p["yaw_deg"] = rad_to_deg(atan2(d2.x, d2.z))
					if kv.has("time"):
						p["time"] = String(kv["time"]).to_float()
				"anim":
					var hook := args[1] if args.size() > 1 else ""
					var node: Node3D = stage.actors[tag]
					if hook == "" or (not node.has_method(hook) and not stage.animatic):
						var hooks: Array = []
						for m: Dictionary in node.get_method_list():
							if String(m["name"]).begins_with("play_"):
								hooks.append(m["name"])
						problem("FAIL", "resolve", "anim %s %s" % [tag, hook], "model has no such hook", "anim hooks exist on the model",
							("did you mean \"%s\"?" % ToolSpec.nearest(hook, hooks)) if not hooks.is_empty() else "use play_cast / play_attack", l)
						return null
					p["hook"] = hook
					if kv.has("arg"):
						p["arg"] = String(kv["arg"])
				"clip":
					var cid := args[1] if args.size() > 1 else ""
					if not _clip_ok(cid, l, tag):
						return null
					p["id"] = cid
				"show", "hide":
					out["kind"] = "visible"
					p["on"] = kind == "show"
		"vfx":
			var vid := args[0] if args.size() > 0 else ""
			if kv.has("scene"):
				if not ResourceLoader.exists(String(kv["scene"])):
					problem("FAIL", "resolve", "vfx scene", "missing " + String(kv["scene"]), "res:// scene exists", "fix the path", l)
					return null
				p["scene"] = String(kv["scene"])
				p["life"] = String(kv.get("life", "3")).to_float()
			elif partner["vfx"] == "present" and vid in _vfx_ids:
				p["vfx_id"] = vid
			else:
				if partner["vfx"] == "present":
					problem("FAIL", "resolve", "vfx " + vid, "unknown vfx id", "ids = VFX Composer files", "did you mean \"%s\"?" % ToolSpec.nearest(vid, _vfx_ids), l)
					return null
				problem("WARN", "resolve", "vfx " + vid, "tool 7 VFX Composer missing: animatic marker only",
					"vfx ids come from tool 7", "build it with VFX Composer, or use scene=res://... meanwhile", l)
				p["vfx_id"] = vid
			if kv.has("at"):
				out["target"] = pos_of(String(kv["at"]), l, "vfx at=", true)["pos"]
			if kv.has("to"):
				p["to"] = pos_of(String(kv["to"]), l, "vfx to=", true)["pos"]
			for k2: String in ["yaw", "scale"]:
				if kv.has(k2):
					p[k2] = String(kv[k2]).to_float()
		"sfx", "music":
			var path := args[0] if args.size() > 0 else ""
			if not path.begins_with("res://"):
				path = "res://assets/audio/" + path
				if path.get_extension() == "":
					path += ".wav"
			if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
				var forge := path.begins_with("res://assets/audio/forge/")
				problem("WARN" if forge and not DirAccess.dir_exists_absolute("res://assets/audio/forge") else "FAIL", "resolve",
					"%s %s" % [kind, args[0] if args.size() > 0 else ""], "missing file " + path, "audio paths exist",
					"make it with Sound Forge (tool 9)" if forge else "fix the path (res://assets/audio/sfx/...)", l)
				if not forge:
					return null
			p["path"] = path
			if kv.has("vol"):
				p["volume_db"] = String(kv["vol"]).to_float()
		"shake":
			p["amount"] = args[0].to_float() if args.size() > 0 and args[0].is_valid_float() else 0.5
		"fade":
			var col: Variant = ToolSpec.color_of(String(kv.get("color", "#000000")))
			p["color"] = col if col != null else Color.BLACK
			p["alpha"] = String(kv.get("alpha", "1")).to_float()
			p["time"] = String(kv.get("time", "0.5")).to_float()
		"title":
			p["text"] = args[0] if args.size() > 0 else ""
			p["sub"] = String(kv.get("sub", ""))
			p["time"] = String(kv.get("time", "3")).to_float()
		"call":
			p["method"] = args[0] if args.size() > 0 else ""
			p["args"] = Array(ToolSpec.list_of(String(kv.get("args", ""))))
			out["on_skip"] = String(kv.get("on_skip", "true")) != "false"
		"set_shot":
			p["set"] = args[0] if args.size() > 0 else ""
	return out


func _clip_ok(cid: String, l: ToolSpecLine, tag: String) -> bool:
	if partner["motion"] == "present" and cid in _clip_ids:
		return true
	if CLIP_FALLBACK.has(cid):
		if partner["motion"] == "missing":
			problem("WARN", "resolve", "clip %s %s" % [tag, cid], "tool 5 Motion Lab missing: falls back to %s" % CLIP_FALLBACK[cid][0],
				"clip ids come from tool 5", "make the clip with Motion Lab (art/motion/)", l)
		return true
	var cands: Array = CLIP_FALLBACK.keys() + _clip_ids
	problem("FAIL", "resolve", "clip %s %s" % [tag, cid], "unknown clip", "clip ids = Motion Lab files or the fallback table",
		("did you mean \"%s\"?" % ToolSpec.nearest(cid, cands)) if ToolSpec.nearest(cid, cands) != "" else "see `run_cine.ps1 help` clip list", l)
	return false


# ---------------------------------------------------------------- output

## The baked script as plain data (vectors as [x, y, z]): what the determinism hash and the JSON bake use.
func to_data() -> Dictionary:
	var out := {"id": doc.id, "title": doc.title, "letterbox_aspect": doc.letterbox, "skip_locked_until": doc.skip_lock,
		"skippable": doc.skippable, "shake_seed": doc.rng_seed, "music_cue": doc.music, "stage_set": doc.set_id, "shots": []}
	for b: Dictionary in shots:
		var s := {}
		for k: String in b:
			if k in ["src_line", "cam", "_ms"]:
				continue
			s[k] = _plain(b[k])
		out["shots"].append(s)
	return out


static func _plain(v: Variant) -> Variant:
	if v is Vector3:
		return [snappedf(v.x, 0.0001), snappedf(v.y, 0.0001), snappedf(v.z, 0.0001)]
	if v is float:
		return snappedf(v, 0.0001)
	if v is Color:
		return (v as Color).to_html()
	if v is Array:
		var a: Array = []
		for x: Variant in v:
			a.append(_plain(x))
		return a
	if v is Dictionary:
		var d := {}
		for k: Variant in v:
			d[k] = _plain(v[k])
		return d
	return v


## Builds the runtime CinematicScript (load-guarded; null when tool 1's classes are missing).
func to_resource() -> Resource:
	if partner["runtime"] != "present":
		return null
	var SScript: Script = load(RT_DIR + "cinematic_script.gd")
	var SShot: Script = load(RT_DIR + "cinematic_shot.gd")
	var SLine: Script = load(RT_DIR + "cinematic_line.gd")
	var SAct: Script = load(RT_DIR + "cinematic_action.gd")
	if SScript == null or SShot == null or SLine == null or SAct == null:
		return null
	var cs: Resource = SScript.new()
	cs.set(&"id", StringName(doc.id))
	cs.set(&"title", doc.title)
	cs.set(&"letterbox_aspect", doc.letterbox)
	cs.set(&"skip_locked_until", doc.skip_lock)
	cs.set(&"skippable", doc.skippable)
	cs.set(&"shake_seed", doc.rng_seed)
	if doc.music != "":
		cs.set(&"music_cue", StringName(doc.music))
	var stage_path := "res://missions/cinematics/tool_demo/%s.tscn" % doc.id
	if ResourceLoader.exists(stage_path):
		cs.set(&"stage_scene", stage_path)
	var shot_arr: Array = cs.get(&"shots")
	for b: Dictionary in shots:
		var sh: Resource = SShot.new()
		for k: String in b:
			if k in ["lines", "actions", "src_line", "cam", "faces", "fallback_cam", "_ms"]:
				continue
			var v: Variant = b[k]
			if k in ["id", "look_actor", "pivot_actor", "follow_actor", "stage_set", "marker_prefix"]:
				v = StringName(String(v))
			elif k == "rail":
				v = NodePath(String(v))
			sh.set(StringName(k), v)
		var la: Array = sh.get(&"lines")
		for ln: Dictionary in b["lines"]:
			var r: Resource = SLine.new()
			r.set(&"at", float(ln["at"]))
			r.set(&"speaker", StringName(String(ln["speaker"])))
			r.set(&"text", String(ln["text"]))
			r.set(&"duration", float(ln["duration"]))
			r.set(&"voice", String(ln.get("voice", "")))
			la.append(r)
		var aa: Array = sh.get(&"actions")
		for ac: Dictionary in b["actions"]:
			var r2: Resource = SAct.new()
			r2.set(&"at", float(ac["at"]))
			r2.set(&"kind", StringName(String(ac["kind"])))
			r2.set(&"actor", StringName(String(ac["actor"])))
			r2.set(&"target", ac["target"])
			r2.set(&"params", (ac["params"] as Dictionary).duplicate(true))
			r2.set(&"on_skip", bool(ac["on_skip"]))
			aa.append(r2)
		shot_arr.append(sh)
	return cs


## Writes data/cinematics/<id>.tres (runtime classes) or <id>.bake.json (no runtime). Returns the written path.
func save(out_dir: String = "res://data/cinematics/") -> String:
	var res := to_resource()
	if res != null:
		var p := out_dir.path_join(doc.id + ".tres")
		var err := ResourceSaver.save(res, p)
		return p if err == OK else ""
	var pj := out_dir.path_join(doc.id + ".bake.json")
	var f := FileAccess.open(pj, FileAccess.WRITE)
	if f == null:
		return ""
	f.store_string(JSON.stringify(to_data(), "\t", true))
	f.close()
	return pj
