extends SceneTree
## Unit voice barks + per-family unit SFX (JS 2026-09-27). Checks:
## 1. UnitVoice bank: every soldier / worker / new unit has select / move / attack / death lines with a WAV; the 4
##    bot favourites speak their language (manifest lang: flame_guard it, rimeshield es, nightblood_reaver cmn,
##    thornling American am_*).
## 2. bark(): own unit only, throttled (1 per 1.5 s), no bark cuts another.
## 3. GameAudio.UNIT_SFX_FAMILY: every mapped id exists, the 27 atk_ / hit_ / death_ files load.
## 4. In main.tscn: GameAudio adds a UnitVoice; selecting a Flame Guard barks "select" (Italian).
## Run: godot --headless --path . -s tests/test_unit_voice.gd --fixed-fps 60 --quit-after 4000

const TASK_ID := "unit_voice"
const MUST_VOICE: Array[StringName] = [
	&"cinder_hand", &"flame_guard", &"ember_archer", &"blaze_rider", &"ash_hurler", &"scorchbow", &"scorchling",
	&"pyre_adept", &"cinder_arbalest", &"ashveil_saboteur",
	&"gloom_thrall", &"shade", &"nightbolt", &"shadow_knight", &"bleakbow", &"barrow_ghoul", &"hexweaver",
	&"hollow_oathsworn", &"nightblood_reaver",
	&"rime_hauler", &"rimeshield", &"shardcaster", &"rime_seer", &"rime_colossus", &"frostbow", &"rimeling",
	&"hoarlight_magebow", &"frost_mortar", &"shardguard",
	&"sprigling", &"thornling", &"burr_slinger", &"bloomtender", &"bramblehorn", &"wildwood_archer",
	&"thistle_darter", &"vinelasher", &"greenheart_oathkeeper", &"stormbottle_genie",
]
const HELPERS: Array[StringName] = [&"helper_vey", &"helper_hush", &"helper_aldra", &"helper_maelis"]
const LANGS := {&"flame_guard": "it", &"rimeshield": "es", &"nightblood_reaver": "cmn", &"thornling": "en-us"}

class FakeUnit extends Node3D:
	var team := 0
	var unit_type: Resource = null
	var attack_target: Node3D = null

var main: Node
var frame := 0
var _wait := 0
var _fails: Array[String] = []
var _stage := 0


func _process(_delta: float) -> bool:
	if main == null:
		_static_checks()   # in the tree (in _initialize, _ready would not run yet)
		main = load("res://scenes/main.tscn").instantiate()
		root.add_child(main)
		current_scene = main
		return false
	if main.get(&"hero") == null:
		_wait += 1
		if _wait > 5000:
			return _finish("navigation never finished baking")
		return false
	frame += 1
	if frame == 30:
		var uv := _unit_voice()
		if uv == null:
			return _finish("GameAudio did not add a UnitVoice")
		var guard: Node = null
		for u in main.get_tree().get_nodes_in_group(&"units"):
			if int(u.get(&"team")) == 0 and GameAudio.unit_type_id(u) == &"flame_guard":
				guard = u
				break
		if guard == null:
			print("  (no player Flame Guard in main.tscn: live select check skipped)")
			return _finish("")
		main.get(&"selection").call(&"select_units", [guard])
		_stage = 1
	if frame == 40 and _stage == 1:
		var uv := _unit_voice()
		var ok := false
		for p: Dictionary in uv.played:
			if p["unit"] == &"flame_guard" and p["event"] == &"select":
				ok = true
				print("  live: select -> %s" % p["path"])
		if not ok:
			_fails.append("selecting a Flame Guard in main.tscn did not bark (played %s)" % str(uv.played))
		return _finish("")
	if frame > 600:
		return _finish("timed out")
	return false


func _unit_voice() -> Node:
	var ga := _find(main, "GameAudio")
	return ga.get_node_or_null(^"UnitVoice") if ga else null


func _find(n: Node, cls: String) -> Node:
	if n.get_script() and (n.get_script() as Script).get_global_name() == cls:
		return n
	for c in n.get_children():
		var r := _find(c, cls)
		if r:
			return r
	return null


func _static_checks() -> void:
	# 1. bank
	var uv := UnitVoice.new()
	root.add_child(uv)
	var total := uv.line_count()
	print("  bank: %d voiced lines, %d unit types" % [total, uv.voiced_units().size()])
	if total < 150:
		_fails.append("only %d voiced bark lines (want >= 150)" % total)
	for id in MUST_VOICE:
		for ev: StringName in UnitVoice.EVENTS:
			if uv.lines_for(id, ev).is_empty():
				_fails.append("%s has no voiced %s line" % [id, ev])
	for id in HELPERS:
		for ev: StringName in [&"select", &"death"]:
			if uv.lines_for(id, ev).is_empty():
				_fails.append("%s has no voiced %s line" % [id, ev])
	var man: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(UnitVoice.MANIFEST_PATH))
	var by_path := {}
	for k: String in man["lines"]:
		by_path[str(man["lines"][k]["path"])] = man["lines"][k]
	for id: StringName in LANGS:
		var paths := uv.lines_for(id, &"select")
		if paths.is_empty():
			continue
		var e: Dictionary = by_path.get(paths[0], {})
		if str(e.get("lang", "")) != LANGS[id]:
			_fails.append("%s speaks %s, want %s" % [id, e.get("lang", "?"), LANGS[id]])
		else:
			print("  %s: %s, voice %s, e.g. \"%s\"" % [id, LANGS[id], str(e.get("voice")), str(e.get("text"))])
	if not str(by_path.get(uv.lines_for(&"thornling", &"attack")[0] if not uv.lines_for(&"thornling", &"attack").is_empty() else "", {}).get("voice", "")).begins_with("am_"):
		_fails.append("thornling is not an American man's voice")
	# 2. bark rules
	var fg := FakeUnit.new()
	var ut := UnitType.new()
	ut.id = &"flame_guard"
	fg.unit_type = ut
	root.add_child(fg)
	var foe := FakeUnit.new()
	foe.team = 1
	foe.unit_type = ut
	root.add_child(foe)
	if uv.bark(foe, &"select"):
		_fails.append("an enemy unit barked")
	if not uv.bark(fg, &"select"):
		_fails.append("own Flame Guard select did not bark")
	if uv.bark(fg, &"move"):
		_fails.append("second bark inside 1.5 s was not throttled")
	uv.tick(1.0)
	if uv.bark(fg, &"attack"):
		_fails.append("bark after 1.0 s was not throttled")
	uv.tick(0.6)
	(uv.get_child(0) as AudioStreamPlayer).stop()   # headless: the stream would still be "playing"
	if not uv.bark(fg, &"attack"):
		_fails.append("bark after 1.6 s was refused")
	print("  barks: %s" % str(uv.played.map(func(p: Dictionary) -> String: return "%s/%s" % [p["unit"], p["event"]])))
	# 3. SFX families
	var fams := {}
	for id: StringName in GameAudio.UNIT_SFX_FAMILY:
		fams[GameAudio.UNIT_SFX_FAMILY[id]] = true
		var ok := ResourceLoader.exists("res://data/units/%s.tres" % id) or ResourceLoader.exists("res://data/helpers/%s.tres" % id)
		if not ok:
			_fails.append("UNIT_SFX_FAMILY id %s has no .tres" % id)
	for f: StringName in fams:
		for kind in ["atk_", "hit_", "death_"]:
			var p := "res://assets/audio/sfx/%s%s.wav" % [kind, f]
			if not ResourceLoader.exists(p) or load(p) == null:
				_fails.append("missing SFX %s" % p)
			if not GameAudio.SOUNDS.has(StringName(kind + String(f))):
				_fails.append("%s%s not in GameAudio.SOUNDS" % [kind, f])
	var bow := FakeUnit.new()
	var but := UnitType.new()
	but.id = &"scorchbow"
	bow.unit_type = but
	if GameAudio.unit_sfx_family(bow) != &"bow":
		_fails.append("scorchbow family is not bow")
	bow.free()
	print("  sfx: %d families, %d mapped unit types" % [fams.size(), GameAudio.UNIT_SFX_FAMILY.size()])
	uv.queue_free()
	fg.queue_free()
	foe.queue_free()


func _finish(reason: String) -> bool:
	if reason != "":
		_fails.append(reason)
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	return true
