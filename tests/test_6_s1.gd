extends SceneTree
## Task 6.S1: GameAudio in a skirmish. A melee attack plays a hit sound, a spell plays its sound,
## every generated sound loads, the 3D voice cap (16) holds and per-sound cooldowns stop spam.
## Run: godot --headless --path . -s tests/test_6_s1.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "6.s1"
const TIMEOUT_FRAMES := 1200

var main: Node
var audio: Node
var frame := 0
var _wait := 0
var _phase := 0
var _phase_frame := 0
var _guard: Node
var _shade: Node


func _initialize() -> void:
	main = load("res://scenes/skirmish.tscn").instantiate()
	var bot: Node = main.get_node_or_null("ShadowBot")
	if bot:
		bot.set("enabled", false)
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: map never ready" % TASK_ID)
			return true
		return false
	frame += 1
	if frame == 1:
		return _setup()
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out in phase %d (plays %s)" % [TASK_ID, _phase, audio.get(&"play_counts")])
		return true
	return _step()


func _setup() -> bool:
	# The lead adds GameAudio to the scenes; add one here if it is not there yet.
	for c in main.get_children():
		if c.get_script() == load("res://scripts/audio/game_audio.gd"):
			audio = c
	if audio == null:
		audio = load("res://scripts/audio/game_audio.gd").new()
		audio.name = "GameAudio"
		main.add_child(audio)
	audio.set(&"max_hear_distance", 1.0e6)
	# Every sound file loads.
	var sounds: Array = audio.get_script().get_script_constant_map()["SOUNDS"]
	for id in sounds:
		var path := "res://assets/audio/sfx/%s.wav" % id
		if not ResourceLoader.exists(path) or load(path) == null:
			print("FAIL %s: missing sound %s" % [TASK_ID, path])
			return true
	for m in ["music_match", "music_menu"]:
		if not ResourceLoader.exists("res://assets/audio/music/%s.wav" % m):
			print("FAIL %s: missing music %s" % [TASK_ID, m])
			return true
	# A player melee soldier next to a neutral-free enemy target.
	var hero: Node3D = main.hero
	var at := hero.global_position + Vector3(4.0, 0.0, 0.0)
	_guard = main.call(&"make_unit", "flame_guard")
	_shade = main.call(&"make_unit", "shade")
	main.call(&"_spawn", _guard, 0, at)
	main.call(&"_spawn", _shade, 1, at + Vector3(1.5, 0.0, 0.0))
	return false


func _step() -> bool:
	var counts: Dictionary = audio.get(&"play_counts")
	match _phase:
		0:   # melee attack -> melee_hit
			if frame == 5 and is_instance_valid(_guard) and is_instance_valid(_shade):
				_guard.call(&"command_attack", _shade)
			if int(counts.get(&"melee_hit", 0)) > 0:
				print("  melee_hit played at frame %d" % frame)
				_next_phase()
		1:   # a spell -> its sound
			if frame - _phase_frame == 1:
				var hero: Node = main.hero
				var caster: Node = hero.get_node_or_null(^"SpellCaster")
				if caster == null:
					print("FAIL %s: hero has no SpellCaster" % TASK_ID)
					return true
				caster.call(&"set_rank", &"kindle", 1)
				hero.set(&"mana", 1000.0)
				var why := str(caster.call(&"cast", &"kindle", null))
				if why != "":
					print("FAIL %s: kindle refused: %s" % [TASK_ID, why])
					return true
			if int(counts.get(&"spell_kindle", 0)) > 0:
				print("  spell_kindle played")
				_next_phase()
		2:   # voice cap + cooldown
			var before := int(counts.get(&"bolt_impact", 0))
			for i in 50:
				audio.call(&"play_at", &"bolt_impact", Vector3(i, 0, 0))
			var after := int((audio.get(&"play_counts") as Dictionary).get(&"bolt_impact", 0))
			if after - before > 1:
				print("FAIL %s: cooldown let %d bolt_impacts through in one frame" % [TASK_ID, after - before])
				return true
			var sounds: Array = audio.get_script().get_script_constant_map()["SOUNDS"]
			for id in sounds:
				audio.call(&"play_at", id, Vector3.ZERO)
			var active := int(audio.call(&"active_voice_count"))
			var voices := int(audio.call(&"voice_count"))
			if voices != 16 or active > 16:
				print("FAIL %s: voice cap broken (voices %d, active %d)" % [TASK_ID, voices, active])
				return true
			if active < 16:
				print("FAIL %s: expected all 16 voices busy after %d sounds, got %d" % [TASK_ID, sounds.size(), active])
				return true
			print("PASS %s (voices %d/16 busy, dropped %d, plays %s)" % [TASK_ID, active,
					int(audio.get(&"dropped")), audio.get(&"play_counts")])
			return true
	return false


func _next_phase() -> void:
	_phase += 1
	_phase_frame = frame
