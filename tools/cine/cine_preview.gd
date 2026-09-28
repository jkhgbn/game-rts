class_name CinePreview
extends Node
## cine's own player for `play` / `record` / stills: drives a camera and the stage's actors from CineEval (a pure
## function of t, so --fixed-fps runs are frame-identical), fires the one-shot cues (model hooks, sfx, music), and draws
## a minimal overlay (2.39 bars, subtitles, fades, title). Used when tool 1's CinematicPlayer is missing, and always for
## stills (it can pose any time instantly: seek is free because everything is a function of t).

signal done

var ev: CineEval
var stage: CineStage
var camera: Camera3D
var t := 0.0
var playing := false
var letterbox := 2.39
var subtitles := true
## Recording for a band crop (reframe to 2.39): bars not drawn, subtitles kept inside the band so the crop keeps them.
var crop_band := false
var tail := 0.5
var head := 0.5
var _fired: Dictionary = {}
var _layer: CanvasLayer
var _bars: Array[ColorRect] = []
var _fade: ColorRect
var _sub: Label
var _spk: Label
var _title: Label
var _music: AudioStreamPlayer
var _prev_pos: Dictionary = {}
var _fade_state := {"t": -1.0, "from": 0.0, "to": 0.0, "time": 0.0, "color": Color.BLACK}
var _title_until := -1.0
var _vfx: Dictionary = {}          # action key -> spawned vfx node
## Narration / dialogue voices (line.voice WAVs) at their line time; mixed into Movie Maker's WAV while recording.
var voices := true
var voice_db := -2.0   # Voice Forge WAVs peak at -1 dBFS; leaves room for the music bed (VoicePlayer uses -2 too)
var music_db := -8.0
var _voice_players: Array[AudioStreamPlayer] = []
## Stills: pose the actors' dance clips at the still's time (the stage is frozen, cues never fire there).
var pose_clips := false
var _clip_events: Array[Dictionary] = []
var _clip_scanned := false


func setup(p_ev: CineEval, p_stage: CineStage, cam_parent: Node, overlay: bool = true) -> void:
	ev = p_ev
	stage = p_stage
	camera = Camera3D.new()
	camera.name = "CineCamera"
	camera.near = 0.1
	camera.far = 250.0 if not p_stage.multi else 4000.0   # multi-set movies (the prologue) have vistas
	cam_parent.add_child(camera)
	camera.current = true
	if overlay:
		_build_overlay()
	_music = AudioStreamPlayer.new()
	add_child(_music)


func start(music_path: String = "") -> void:
	t = -head
	playing = true
	pose(0.0)
	if music_path != "" and ResourceLoader.exists(music_path):
		_music.stream = load(music_path) as AudioStream
		_music.volume_db = music_db
		if _music.stream is AudioStreamWAV:
			(_music.stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
			(_music.stream as AudioStreamWAV).loop_end = int((_music.stream as AudioStreamWAV).get_length() * (_music.stream as AudioStreamWAV).mix_rate)
		_music.play()


## Jumps to global time `at` while playing: every cue and line before it counts as fired (not replayed).
func skip_to(at: float) -> void:
	t = at
	for i: int in ev.shots.size():
		for ai: int in (ev.shots[i]["actions"] as Array).size():
			if ev.starts[i] + float(ev.shots[i]["actions"][ai]["at"]) < at:
				_fired["%d_%d" % [i, ai]] = true
		for li: int in (ev.shots[i]["lines"] as Array).size():
			if ev.starts[i] + float(ev.shots[i]["lines"][li]["at"]) < at:
				_fired["L%d_%d" % [i, li]] = true
	pose(at)


## Poses camera + actors at global time `at` (no cues fired). Also: the shot's set (multi-set movies), every
## time-driven node (group "cine_timed": dragon flocks, cine fx) and the vfx scenes alive at `at`.
func pose(at: float) -> void:
	var tt := clampf(at, 0.0, ev.total)
	var c := ev.camera(tt)
	camera.global_transform = c["xform"]
	camera.fov = band_fov(c["fov"])
	var si: int = ev.shot_at(tt)[0]
	if stage.multi:
		stage.set_active_set(StringName(String(ev.shots[si].get("stage_set", ""))))
	for tag: String in ev.actor_start:
		var a := ev.actor(tag, tt)
		stage.pose_actor(tag, a["pos"], a["yaw"], a["visible"])
	_pose_vfx(tt)
	if pose_clips:
		_pose_clips(tt)
	if is_inside_tree():
		get_tree().call_group(&"cine_timed", &"set_cine_time", tt)


## Stills (models frozen, no cues fired): poses each actor's in-game dance clip (`clip <actor> dance_*`, stopped by
## `anim <actor> stop_clip` / an attack / a cast) exactly as it is at `tt`, so a still shows the dance the movie plays.
## Uses the model's own play_clip / stop_clip, then sets its clip clock and blend (CharacterModel has no public seek
## yet: requested in docs/handoff/for-tech-artist.md) and poses it once.
func _pose_clips(tt: float) -> void:
	if _clip_events.is_empty() and not _clip_scanned:
		_clip_scanned = true
		for i: int in ev.shots.size():
			for a: Dictionary in ev.shots[i]["actions"]:
				var k := String(a["kind"])
				var at: float = ev.starts[i] + float(a["at"])
				var p: Dictionary = a["params"]
				if k == "clip" and String(p.get("id", "")).begins_with("dance_"):
					_clip_events.append({"t": at, "tag": String(a["actor"]), "id": String(p["id"])})
				elif k == "anim" and String(p.get("hook", "")) in ["stop_clip", "play_attack", "play_cast", "play_mine", "play_death"]:
					_clip_events.append({"t": at, "tag": String(a["actor"]), "id": ""})
		_clip_events.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return float(x["t"]) < float(y["t"]))
	var st: Dictionary = {}   # tag -> {id, t0, off}
	var dancers: Dictionary = {}
	for e: Dictionary in _clip_events:
		var tag := String(e["tag"])
		if String(e["id"]) != "":
			dancers[tag] = true
		if float(e["t"]) > tt:
			continue
		var cur: Dictionary = st.get(tag, {})
		if String(e["id"]) != "":
			if cur.is_empty() or cur.has("off") or String(cur["id"]) != String(e["id"]):
				st[tag] = {"id": String(e["id"]), "t0": float(e["t"])}
		elif not cur.is_empty() and not cur.has("off"):
			cur["off"] = float(e["t"])
	for tag: String in dancers:
		var n: Node3D = stage.actors.get(tag, null)
		if n == null or not n.has_method(&"play_clip") or not n.has_method(&"_animate") or not "_dn_t" in n:
			continue
		var s: Dictionary = st.get(tag, {})
		if s.is_empty():
			n.call(&"stop_clip")
			n.set(&"_dn_w", 0.0)
		else:
			var id := StringName(String(s["id"]))
			if StringName(n.call(&"current_clip")) != id:
				n.call(&"play_clip", id)
			var t0 := float(s["t0"])
			if s.has("off"):
				var off := float(s["off"])
				n.call(&"stop_clip")
				n.set(&"_dn_last", id)
				n.set(&"_dn_t", off - t0)
				n.set(&"_dn_w", clampf((off - t0) / 0.3, 0.0, 1.0) * clampf(1.0 - (tt - off) / 0.3, 0.0, 1.0))
			else:
				n.set(&"_dn_t", tt - t0)
				n.set(&"_dn_w", clampf((tt - t0) / 0.3, 0.0, 1.0))
		n.set(&"_force_write", true)
		n.call(&"_animate", 0.0)


## Framing is authored on 16:9 (the band is the middle 2.39 strip). A wider viewport (a 1920x804 recording) keeps the
## same horizontal view: the vertical fov shrinks so the picture = the band crop of the 16:9 frame.
func band_fov(fov: float) -> float:
	var vp := camera.get_viewport() if camera != null and camera.is_inside_tree() else null
	if vp == null:
		return fov
	var sz := vp.get_visible_rect().size
	var aspect := sz.x / maxf(1.0, sz.y)
	if aspect <= 16.0 / 9.0 + 0.01:
		return fov
	return rad_to_deg(2.0 * atan(tan(deg_to_rad(fov) * 0.5) * (16.0 / 9.0) / aspect))


## vfx actions with a scene: spawned at their time, freed after `life`; nodes with `set_cine_age(age)` are posed
## exactly (stills / seek), others run on their own clock while playing.
func _pose_vfx(tt: float) -> void:
	for i: int in ev.shots.size():
		var s: Dictionary = ev.shots[i]
		for ai: int in (s["actions"] as Array).size():
			var a: Dictionary = s["actions"][ai]
			if String(a["kind"]) != "vfx" or not (a["params"] as Dictionary).has("scene"):
				continue
			var key := "%d_%d" % [i, ai]
			var t0: float = ev.starts[i] + float(a["at"])
			var life := float(a["params"].get("life", 3.0))
			var alive := tt >= t0 and tt < t0 + life
			var node: Node3D = _vfx.get(key, null)
			if alive and node == null:
				var ps := load(String(a["params"]["scene"])) as PackedScene
				if ps == null:
					continue
				node = ps.instantiate() as Node3D
				if node == null:
					continue
				# placed before it enters the tree (its _ready reads position / scale); the stage sits at the origin
				node.position = stage.to_local(a["target"]) if stage.is_inside_tree() else a["target"]
				if (a["params"] as Dictionary).has("to") and node.has_method(&"set_cine_target"):
					node.call(&"set_cine_target", a["params"]["to"])
				if (a["params"] as Dictionary).has("yaw"):
					node.rotation.y = deg_to_rad(float(a["params"]["yaw"]))
				if (a["params"] as Dictionary).has("scale"):
					node.scale = Vector3.ONE * float(a["params"]["scale"])
				stage.add_child(node)
				_vfx[key] = node
			elif not alive and node != null:
				node.queue_free()
				_vfx.erase(key)
				node = null
			if node != null and node.has_method(&"set_cine_age"):
				node.call(&"set_cine_age", tt - t0)


func _process(delta: float) -> void:
	if not playing:
		return
	t += delta
	if t < 0.0:
		_set_fade(Color.BLACK, 1.0)
		return
	if t > ev.total + tail:
		playing = false
		done.emit()
		return
	var tt := minf(t, ev.total)
	pose(tt)
	for tag: String in ev.actor_start:
		var n: Node3D = stage.actors.get(tag)
		if n == null:
			continue
		var p := n.global_position
		var sp := 0.0
		if _prev_pos.has(tag):
			sp = (p - (_prev_pos[tag] as Vector3)).length() / maxf(delta, 0.0001)
		_prev_pos[tag] = p
		if n.has_method(&"set_moving"):
			n.call(&"set_moving", sp if sp > 0.05 else 0.0)
	_fire_cues(tt)
	_update_overlay(tt)


func _fire_cues(tt: float) -> void:
	for i: int in ev.shots.size():
		var s: Dictionary = ev.shots[i]
		var st: float = ev.starts[i]
		if voices:
			for li: int in (s["lines"] as Array).size():
				var ln: Dictionary = s["lines"][li]
				var lkey := "L%d_%d" % [i, li]
				if _fired.has(lkey) or tt < st + float(ln["at"]):
					continue
				_fired[lkey] = true
				if tt > st + float(ln["at"]) + 0.5:
					continue   # started mid-way (dur= / seek): no late voice
				_play_voice(String(ln.get("voice", "")))
		for ai: int in (s["actions"] as Array).size():
			var a: Dictionary = s["actions"][ai]
			var key := "%d_%d" % [i, ai]
			if _fired.has(key) or tt < st + float(a["at"]):
				continue
			_fired[key] = true
			_cue(a)


func _play_voice(path: String) -> void:
	if path == "" or not ResourceLoader.exists(path):
		return
	var sp := AudioStreamPlayer.new()
	sp.stream = load(path) as AudioStream
	sp.volume_db = voice_db
	add_child(sp)
	sp.play()
	sp.finished.connect(sp.queue_free)


func _cue(a: Dictionary) -> void:
	var p: Dictionary = a["params"]
	var n: Node3D = stage.actors.get(String(a["actor"]))
	match String(a["kind"]):
		"anim":
			if n != null and n.has_method(StringName(p["hook"])):
				if p.has("arg"):
					n.call(StringName(p["hook"]), StringName(String(p["arg"])))
				else:
					n.call(StringName(p["hook"]))
		"clip":
			if n != null:
				if n.has_method(&"play_clip"):
					n.call(&"play_clip", StringName(String(p["id"])))
				elif CineBake.CLIP_FALLBACK.has(String(p["id"])):
					var fb: Array = CineBake.CLIP_FALLBACK[String(p["id"])]
					if n.has_method(StringName(fb[0])):
						if fb[0] in ["play_cast", "play_gesture"]:
							n.call(StringName(fb[0]), StringName(fb[1]))
						else:
							n.call(StringName(fb[0]))
		"sfx":
			var sp := AudioStreamPlayer.new()
			sp.stream = load(String(p["path"])) as AudioStream
			sp.volume_db = float(p.get("volume_db", 0.0))
			add_child(sp)
			sp.play()
			sp.finished.connect(sp.queue_free)
		"music":
			_music.stream = load(String(p["path"])) as AudioStream
			_music.volume_db = float(p.get("volume_db", -6.0))
			_music.play()
		"fade":
			_fade_state = {"t": t, "from": _fade.color.a if _fade else 0.0, "to": float(p.get("alpha", 1.0)),
				"time": maxf(0.001, float(p.get("time", 0.5))), "color": p.get("color", Color.BLACK)}
		"title":
			if _title:
				_title.text = String(p.get("text", "")) + ("\n" + String(p["sub"]) if String(p.get("sub", "")) != "" else "")
				_title_until = t + float(p.get("time", 3.0))
		"shake":
			pass


# ---------------------------------------------------------------- overlay

func _build_overlay() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 85
	add_child(_layer)
	for i: int in 2:
		var r := ColorRect.new()
		r.color = Color.BLACK
		_layer.add_child(r)
		_bars.append(r)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_fade)
	_spk = Label.new()
	_spk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_layer.add_child(_spk)
	_sub = Label.new()
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sub.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 0.9))
	_sub.add_theme_constant_override(&"shadow_offset_x", 2)
	_sub.add_theme_constant_override(&"shadow_offset_y", 2)
	_layer.add_child(_sub)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_layer.add_child(_title)


func _is_voice_over(speaker: String) -> bool:
	if stage == null or stage.doc == null:
		return false
	for tag: String in stage.doc.cast:
		var c: Dictionary = stage.doc.cast[tag]
		if bool(c["hidden"]) and (tag == speaker or String(c["speaker"]) == speaker):
			return true
	return false


func _set_fade(c: Color, a: float) -> void:
	if _fade:
		_fade.color = Color(c, a)


func _update_overlay(tt: float) -> void:
	if _layer == null:
		return
	var vs := get_viewport().get_visible_rect().size
	var bar := float(ToolSheet.bar_px(Vector2i(vs), letterbox))
	_bars[0].position = Vector2.ZERO
	_bars[0].size = Vector2(vs.x, bar)
	_bars[1].position = Vector2(0, vs.y - bar)
	_bars[1].size = Vector2(vs.x, bar)
	_bars[0].visible = not crop_band
	_bars[1].visible = not crop_band
	_fade.position = Vector2.ZERO
	_fade.size = vs
	# fades: shot transitions (half out, half in) + fade actions
	var a := 0.0
	var col := Color.BLACK
	var sl := ev.shot_at(tt)
	var si: int = sl[0]
	var lt: float = sl[1]
	var s: Dictionary = ev.shots[si]
	var tin := int(s["transition_in"])
	var half := float(s["transition_time"]) * 0.5
	if tin in [1, 2] and lt < half:
		a = 1.0 - lt / maxf(0.001, half)
		col = Color.WHITE if tin == 2 else Color.BLACK
	if si + 1 < ev.shots.size():
		var ns: Dictionary = ev.shots[si + 1]
		var nt := int(ns["transition_in"])
		var nh := float(ns["transition_time"]) * 0.5
		var left := float(s["duration"]) - lt
		if nt in [1, 2] and left < nh:
			a = maxf(a, 1.0 - left / maxf(0.001, nh))
			col = Color.WHITE if nt == 2 else Color.BLACK
	if float(_fade_state["t"]) >= 0.0:
		var k := clampf((t - float(_fade_state["t"])) / float(_fade_state["time"]), 0.0, 1.0)
		var fa := lerpf(float(_fade_state["from"]), float(_fade_state["to"]), k)
		if fa > a:
			a = fa
			col = _fade_state["color"]
	if t > ev.total:
		a = maxf(a, clampf((t - ev.total) / maxf(0.01, tail), 0.0, 1.0))
	_set_fade(col, a)
	# subtitles
	var fs := int(round(22.0 * (vs.x / 1600.0 if vs.x / maxf(1.0, vs.y) > 16.0 / 9.0 + 0.01 else vs.y / 900.0)))
	_sub.add_theme_font_size_override(&"font_size", fs)
	_spk.add_theme_font_size_override(&"font_size", int(fs * 0.8))
	_sub.text = ""
	_spk.text = ""
	if subtitles:
		# a line stays up over later cuts until its duration ends or the next line starts
		for j: int in range(si, -1, -1):
			var found := false
			var lines: Array = ev.shots[j]["lines"]
			for ln: Dictionary in lines:
				var la := ev.starts[j] + float(ln["at"])
				var eff := float(ln["duration"]) if float(ln["duration"]) > 0.0 else maxf(2.5, 0.9 + 0.055 * String(ln["text"]).length())
				if tt >= la and tt < la + eff:
					_sub.text = String(ln["text"])
					# a voice-over (speaker cast hidden=1, e.g. the narrator) shows no name
					_spk.text = "" if _is_voice_over(String(ln["speaker"])) else String(ln["speaker"]).capitalize()
				if tt >= la:
					found = true
			if found:
				break
	var w := vs.x * 0.7
	_sub.size = Vector2(w, fs * 3)
	_sub.position = Vector2((vs.x - w) * 0.5, vs.y - bar + 8.0 if bar >= 80.0 and not crop_band else vs.y - bar - fs * 3.2)
	_spk.size = Vector2(w, fs)
	_spk.position = _sub.position - Vector2(0, fs * 1.1)
	_spk.add_theme_color_override(&"font_color", Color(1.0, 0.75, 0.45))
	_title.add_theme_font_size_override(&"font_size", int(fs * 2.0))
	_title.size = vs
	_title.visible = t < _title_until
