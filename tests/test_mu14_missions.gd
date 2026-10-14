extends SceneTree
## MU14 (docs/design/music.md 4-5), the missions part: MissionBase adds a GameAudio node to a mission scene that has
## none (mission 1), MissionConfig.music_tracks overrides the match pool, and a boss fight (a living, awake enemy in
## group "boss", MissionBase._boss_fight_active) switches the MusicDirector to `boss`, back to `match` when it falls
## (with the mission's pool again).
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_mu14_missions.gd --fixed-fps 60 --quit-after 9000

const TASK_ID := "mu14_missions"
const POOL: Array[StringName] = [&"ice", &"field"]

var h := MissionHarness.new()
var main: Node
var boss: Node


func _initialize() -> void:
	var m := (load("res://missions/mission_01.tscn") as PackedScene).instantiate()
	h.check(m.get_node_or_null(^"GameAudio") == null, "mission_01.tscn already has a GameAudio (test premise)")
	var cfg := (m.get(&"config") as Resource).duplicate() as Resource
	cfg.set(&"music_tracks", POOL)
	m.set(&"config", cfg)
	main = h.open(self, m, {"difficulty": 1, "task_id": TASK_ID})
	h.steps.add("GameAudio added", _game_audio_ok, 10)
	h.steps.add("match context with the override", func() -> bool:
		var d := _director()
		return d != null and d.call(&"music_context") == &"match" and _picks_in(POOL), 600)
	h.steps.add("boss appears", _spawn_boss, 10)
	h.steps.add("boss context", func() -> bool:
		var d := _director()
		return d.call(&"music_context") == &"boss" and bool(main.call(&"boss_music_on")) \
				and _picks_in([&"boss"] as Array[StringName]), 120)
	h.steps.add("boss falls", func() -> bool:
		MissionHarness.kill([boss])
		return true, 10)
	h.steps.add("back to match, pool again", func() -> bool:
		var d := _director()
		return d.call(&"music_context") == &"match" and not bool(main.call(&"boss_music_on")) and _picks_in(POOL), 120)


func _process(_delta: float) -> bool:
	return h.tick()


func _game_audio_ok() -> bool:
	var ga := main.get_node_or_null(^"GameAudio")
	if not h.check(ga != null, "no GameAudio child on the mission"):
		return true
	var s := ga.get_script() as Script
	h.check(s != null and s.resource_path == "res://scripts/audio/game_audio.gd", "GameAudio has the wrong script")
	h.check(main.get_children().filter(func(c: Node) -> bool: return c.name.begins_with("GameAudio")).size() == 1,
			"more than one GameAudio")
	return true


func _spawn_boss() -> bool:
	var hero := main.get(&"hero") as Node3D
	var at := hero.global_position + Vector3(25.0, 0.0, 0.0)
	var units: Array = main.call(&"spawn_group", [["shade", 1]], at, 0.0, 1, false)
	if not h.check(units.size() == 1, "no boss unit spawned"):
		return true
	boss = units[0]
	boss.add_to_group(&"boss")
	h.check(not bool(main.call(&"boss_music_on")), "boss music on before the boss")
	return true


func _director() -> Node:
	return root.get_node_or_null(^"MusicDirector")


## Every pick of the director's current pool (simulate_picks, files not checked) is in `allowed`.
func _picks_in(allowed: Array[StringName]) -> bool:
	var d := _director()
	if d == null:
		return false
	var picks: Array = d.call(&"simulate_picks", 8, [] as Array[StringName], 7)
	if picks.is_empty():
		return false
	for id: Variant in picks:
		if not allowed.has(StringName(str(id))):
			return false
	return true
