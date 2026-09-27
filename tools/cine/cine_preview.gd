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


func setup(p_ev: CineEval, p_stage: CineStage, cam_parent: Node, overlay: bool = true) -> void:
	ev = p_ev
	stage = p_stage
	camera = Camera3D.new()
	camera.name = "CineCamera"
	camera.near = 0.1
	camera.far = 250.0
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
		_music.volume_db = -8.0
		_music.play()


## Poses camera + actors at global time `at` (no cues fired).
func pose(at: float) -> void:
	var tt := clampf(at, 0.0, ev.total)
	var c := ev.camera(tt)
	camera.global_transform = c["xform"]
	camera.fov = c["fov"]
	for tag: String in ev.actor_start:
		var a := ev.actor(tag, tt)
		stage.pose_actor(tag, a["pos"], a["yaw"], a["visible"])


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
		for ai: int in (s["actions"] as Array).size():
			var a: Dictionary = s["actions"][ai]
			var key := "%d_%d" % [i, ai]
			if _fired.has(key) or tt < st + float(a["at"]):
				continue
			_fired[key] = true
			_cue(a)


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
	var fs := int(round(22.0 * vs.y / 900.0))
	_sub.add_theme_font_size_override(&"font_size", fs)
	_spk.add_theme_font_size_override(&"font_size", int(fs * 0.8))
	_sub.text = ""
	_spk.text = ""
	if subtitles:
		for ln: Dictionary in s["lines"]:
			var la := float(ln["at"])
			var eff := float(ln["duration"]) if float(ln["duration"]) > 0.0 else maxf(2.5, 0.9 + 0.055 * String(ln["text"]).length())
			if lt >= la and lt < la + eff:
				_sub.text = String(ln["text"])
				_spk.text = String(ln["speaker"]).capitalize()
	var w := vs.x * 0.7
	_sub.size = Vector2(w, fs * 3)
	_sub.position = Vector2((vs.x - w) * 0.5, vs.y - bar + 8.0 if bar >= 80.0 and not crop_band else vs.y - bar - fs * 3.2)
	_spk.size = Vector2(w, fs)
	_spk.position = _sub.position - Vector2(0, fs * 1.1)
	_spk.add_theme_color_override(&"font_color", Color(1.0, 0.75, 0.45))
	_title.add_theme_font_size_override(&"font_size", int(fs * 2.0))
	_title.size = vs
	_title.visible = t < _title_until
