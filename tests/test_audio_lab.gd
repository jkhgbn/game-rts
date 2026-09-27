extends SceneTree
## Audio Lab (docs/plan/audio-lab.md): the measures are right on known signals, the checks catch known faults, the
## code scan finds how GameAudio plays its cues, the report files are written and the preview scene plays.
## Run: godot --headless --path . -s tests/test_audio_lab.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "audio_lab"
const Rules := preload("res://tools/audio_lab/lab_rules.gd")
const Sig := preload("res://tools/audio_lab/lab_signal.gd")
const Code := preload("res://tools/audio_lab/lab_code.gd")
const Report := preload("res://tools/audio_lab/lab_report.gd")
const OUT := "user://audio_lab_test/"

var _preview: Node
var _frame := 0
var _failed := false


func _initialize() -> void:
	if not _check_signal() or not _check_rules() or not _check_scan() or not _check_report():
		_failed = true
		return
	_preview = load("res://tools/audio_lab/audio_lab_preview.tscn").instantiate()
	root.add_child(_preview)


func _process(_delta: float) -> bool:
	if _failed:
		return true
	_frame += 1
	if _frame == 5:
		# Pick the first unit cue: its context is the battle bed.
		var cues: Array = _preview.get(&"cues")
		for i in cues.size():
			if str(cues[i]["category"]) == "unit":
				_preview.call(&"select", i)
				break
		_preview.call(&"play_current")
	if _frame == 240:
		var played := int(_preview.get(&"played"))
		var hits := int(_preview.get(&"bed_hits"))
		if played < 1 or hits < 3:
			return _fail("preview: played %d cues, %d battle bed hits" % [played, hits])
		print("PASS %s (preview played %d, bed hits %d)" % [TASK_ID, played, hits])
		return true
	return false


func _fail(why: String) -> bool:
	print("FAIL %s: %s" % [TASK_ID, why])
	_failed = true
	return true


## A PCM16 mono stream: `lead` s of silence, `tone` s of a 997 Hz sine at `amp` (clamped to full scale), `tail` s
## of silence.
func _wav(amp: float, lead: float, tone: float, tail: float, rate: int = 44100) -> AudioStreamWAV:
	var n := int((lead + tone + tail) * rate)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / rate
		var v := 0.0
		if t >= lead and t < lead + tone:
			v = clampf(amp * sin(TAU * 997.0 * t), -1.0, 1.0)
		data.encode_s16(i * 2, int(round(v * 32767.0)))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	return w


func _measure(w: AudioStream) -> Dictionary:
	var d := Sig.decode(w)
	if not d["ok"]:
		return {}
	return Sig.measure(d["frames"], d["rate"])


func _check_signal() -> bool:
	# -6 dBFS 997 Hz sine, 2 s, 50 ms lead, 200 ms tail: dual mono -> about -6 LUFS integrated.
	var m := _measure(_wav(0.5, 0.05, 2.0, 0.2))
	if m.is_empty():
		return not _fail("decode failed")
	if not bool(m["dual_mono"]):
		return not _fail("mono file not read as dual mono")
	if absf(float(m["peak_dbfs"]) + 6.02) > 0.3:
		return not _fail("peak %.2f dBFS, expected -6.0" % float(m["peak_dbfs"]))
	if absf(float(m["lufs_i"]) + 6.0) > 1.0:
		return not _fail("integrated %.2f LUFS, expected about -6" % float(m["lufs_i"]))
	if absf(float(m["lead_ms"]) - 50.0) > 3.0:
		return not _fail("lead %.1f ms, expected 50" % float(m["lead_ms"]))
	if absf(float(m["trail_ms"]) - 200.0) > 5.0:
		return not _fail("trail %.1f ms, expected 200" % float(m["trail_ms"]))
	var b: Dictionary = m["bands"]
	if float(b["mid"]) < 0.8:
		return not _fail("a 997 Hz tone should be mid band, got %s" % str(b))
	# A clipped tone (amp 1.5): clipped runs and true peak >= 0.
	var c := _measure(_wav(1.5, 0.0, 0.3, 0.05))
	if int(c["clipped"]) <= 0 or float(c["true_peak_dbtp"]) < -0.1:
		return not _fail("clipping not found (runs %d, tp %.2f)" % [int(c["clipped"]), float(c["true_peak_dbtp"])])
	print("  signal ok: -6 dBFS sine = %.2f LUFS, lead %.0f ms, trail %.0f ms, clipped runs %d" % [float(m["lufs_i"]),
		float(m["lead_ms"]), float(m["trail_ms"]), int(c["clipped"])])
	return true


func _check_rules() -> bool:
	var expect := {"ui_click": "ui", "melee_hit": "unit", "spell_kindle": "spell", "level_up": "alert",
		"music_match": "music", "mapfill_splash": "unit", "trade_whistle": "alert", "alert_wizard_fell": "alert",
		"ability_cast": "spell", "skill_hit": "unit"}
	for id: String in expect:
		var got: String = Report.category_of(id, "res://assets/audio/sfx/%s.wav" % id, "auto")
		if got != expect[id]:
			return not _fail("category of %s = %s, expected %s" % [id, got, expect[id]])
	if Report.category_of("melee_hit", "", "alert") != "alert":
		return not _fail("kind= does not override the category")
	for cat: String in Rules.CATEGORIES:
		if not Rules.LOUDNESS.has(cat) or not Rules.LISTEN_FOR.has(cat) or not Rules.REPLACEMENT_SPEC.has(cat):
			return not _fail("rules table missing category %s" % cat)
	# 3D loss: inverse distance at 2x unit_size = -6 dB.
	if absf(Report.att_db("ATTENUATION_INVERSE_DISTANCE", 15.0, 30.0) + 6.02) > 0.1:
		return not _fail("att_db inverse distance wrong")
	# v1.1: takes fold into their parent cue (melee_hit_1.wav sits next to melee_hit.wav); a lone suffix does not.
	var lab: GDScript = load("res://tools/audio_lab/audio_lab.gd")
	if lab.take_parent("res://assets/audio/sfx/melee_hit_1.wav") != "melee_hit":
		return not _fail("take_parent(melee_hit_1) != melee_hit")
	if lab.take_parent("res://assets/audio/sfx/melee_hit.wav") != "" or lab.take_parent("res://assets/audio/sfx/death_fire.wav") != "":
		return not _fail("take_parent on a cue that is not a take")
	# v1.1: source .wav peak reader (import overshoot): every sfx file is 16-bit PCM, peak between -30 and 0 dBFS.
	var sp := Sig.source_peak_dbfs("res://assets/audio/sfx/melee_hit.wav")
	if is_nan(sp) or sp > 0.01 or sp < -30.0:
		return not _fail("source_peak_dbfs(melee_hit.wav) = %s" % sp)
	return true


func _check_scan() -> bool:
	var s := Code.scan_project()
	if not (s["allowed_buses"] as Array).has("SFX"):
		return not _fail("allowed buses %s lack SFX" % str(s["allowed_buses"]))
	var cues: Dictionary = s["cues"]
	for id in ["melee_hit", "ui_click", "music_match", "trade_coin", "mapfill_splash"]:
		if not cues.has(id):
			return not _fail("scan did not find cue %s" % id)
	var mh: Dictionary = cues["melee_hit"]
	if mh["mode"] != "3d" or str(mh["bus"]) != "SFX" or float(mh["pitch"]) <= 0.0 or mh["rate_limit_s"] == null:
		return not _fail("melee_hit facts wrong: %s" % str(mh))
	if cues["ui_click"]["mode"] != "2d":
		return not _fail("ui_click should be 2D")
	if cues["mapfill_splash"]["mode"] != "3d":
		return not _fail("mapfill_splash should be 3D (%s)" % str(cues["mapfill_splash"]))
	var ev := Code.event_coverage(s, s["scripts"])
	var by_id := {}
	for e: Dictionary in ev:
		by_id[e["id"]] = e["status"]
	if by_id.get("unit_death") != "covered" or by_id.get("trade_arrival") != "covered":
		return not _fail("event coverage wrong: %s" % str(by_id))
	print("  scan ok: %d cues, %d players, %d connections" % [cues.size(), (s["players"] as Array).size(),
		(s["connections"] as Array).size()])
	return true


func _check_report() -> bool:
	# One hot clipped unit cue on a Master-bus 3D player: FAIL peaks, FAIL bus, WARN 3D (max_distance 0).
	var w := _wav(1.5, 0.0, 0.3, 0.05)
	var d := Sig.decode(w)
	var m := Sig.measure(d["frames"], d["rate"])
	var row := {"id": "test_hit", "path": "res://test_hit.wav", "category": "unit", "meta": {"mode": "3d",
		"volume_db": 0.0, "pitch": 0.0, "rate_limit_s": null, "script": "res://x.gd"}, "error": "", "orphan": false,
		"generated": "", "takes": 1, "m": m, "info": {"src_rate": 44100, "src_channels": 1, "disk_bytes": 30000,
		"imported_format": "PCM16"}, "memory": 30000, "file_level": float(m["lufs_cue"]), "att": 0.0,
		"level": float(m["lufs_cue"]), "rate": 120.0, "frequent": true}
	var player := {"where": "res://x.gd:1", "script": "res://x.gd", "class": "AudioStreamPlayer3D", "source": "code",
		"props": {"bus": "Master", "unit_size": 10.0, "max_distance": 0.0}}
	var ctx := {"name": "test", "mode": "set", "target": "res://test", "kind": "auto", "cues": {"test_hit": row},
		"players": [player], "allowed_buses": ["SFX", "Music"], "fight": {}, "events": [], "log": false,
		"missing_scored": false, "command": "test"}
	var res: Dictionary = Report.evaluate(ctx)
	var found := {}
	for c: Dictionary in res["checks"]:
		found["%s:%s" % [c["group"], c["status"]]] = true
	for need in ["peaks:FAIL", "bus:FAIL", "3d:WARN", "variation:FAIL", "voices:FAIL", "loudness:FAIL"]:
		if not found.has(need):
			return not _fail("report misses %s (got %s)" % [need, str(found.keys())])
	if (res["improve"] as Array).size() < 3:
		return not _fail("Improve next has %d items" % (res["improve"] as Array).size())
	if int(res["score"]) >= 80:
		return not _fail("score %d too high for a broken cue" % int(res["score"]))
	Report.write(ctx, res, OUT)
	for f in ["scorecard.md", "scorecard.json", "listening_sheet.md", "preview_cues.json"]:
		if not FileAccess.file_exists(OUT + f):
			return not _fail("report file %s not written" % f)
	var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(OUT + "scorecard.json"))
	if not (j is Dictionary) or int((j as Dictionary).get("score", -1)) != int(res["score"]):
		return not _fail("scorecard.json unreadable")
	print("  report ok: score %d, %d checks, improve %d" % [int(res["score"]), (res["checks"] as Array).size(),
		(res["improve"] as Array).size()])
	return true
