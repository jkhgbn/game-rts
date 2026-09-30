extends SceneTree
## Hook check for the six Stables T3 / extra models (read-only; headless is fine):
##   tools\godot_run.ps1 --headless --path . -s res://art/units/ice/frostcrown_juggernaut/tools/t3_hooks_check.gd --fixed-fps 60
##     --quit-after 6000
## Every scene: the unit hooks run (team colours x3 and back, move / gallop / stop, attack, charge, hit, cast, level-up,
## veterancy 4, fidget, dances x3, rank 3 = a visible "RankCrest" on the rank units, death -> death_finished <= 2 s,
## revive), the draw count at rest stays <= 12 (cavalry) and a 2nd instance builds no new mesh / material.
## Prints "T3HOOKS PASS" or "T3HOOKS FAIL: <reasons>".

const SCENES := {
	"frostcrown_juggernaut": "res://art/units/ice/frostcrown_juggernaut/frostcrown_juggernaut.tscn",
	"rime_harrier": "res://art/units/ice/rime_harrier/rime_harrier.tscn",
	"snowdrift_rider": "res://art/units/ice/snowdrift_rider/snowdrift_rider.tscn",
	"bramble_harrier": "res://art/units/nature/bramble_harrier/bramble_harrier.tscn",
	"spirit_wolf": "res://art/units/nature/spirit_wolf/spirit_wolf.tscn",
	"thornback_charger": "res://art/units/nature/thornback_charger/thornback_charger.tscn",
}
const RANKED: Array[String] = ["snowdrift_rider", "thornback_charger"]

var _fails: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, msg: String) -> void:
	if not ok:
		_fails.append(msg)
		print("  FAIL ", msg)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _draws(n: Node) -> int:
	var c := 0
	for g in n.find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		if gi.is_visible_in_tree() and ((gi is MeshInstance3D and (gi as MeshInstance3D).mesh) or gi is MultiMeshInstance3D):
			c += 1
	return c


func _run() -> void:
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.position = Vector3(0, 12, 16)
	cam.look_at_from_position(cam.position, Vector3.ZERO)
	for id: String in SCENES:
		var ps := load(SCENES[id]) as PackedScene
		_check(ps != null, "%s: scene loads" % id)
		if ps == null:
			continue
		var t := UnitType.find(id)
		_check(t != null and t.model_scene != null and t.model_scene.resource_path == SCENES[id],
			"%s: data model_scene points at the real model" % id)
		var m := ps.instantiate() as Node3D
		root.add_child(m)
		await _frames(4)
		var d := _draws(m)
		_check(d <= 12, "%s: %d draws at rest (<= 12)" % [id, d])
		for h in [&"set_team_color", &"set_moving", &"play_attack", &"play_hit", &"play_death", &"revive", &"play_cast",
				&"play_level_up", &"set_veterancy", &"set_status", &"play_clip", &"stop_clip", &"has_clip"]:
			_check(m.has_method(h), "%s: hook %s" % [id, h])
		_check(m.has_signal(&"death_finished"), "%s: signal death_finished" % id)
		for c: Color in [Color(0.85, 0.3, 0.12), Color(0.42, 0.22, 0.6), Color(0.45, 0.75, 1.0)]:
			m.call(&"set_team_color", c)
			await _frames(1)
		m.call(&"set_moving", 6.5)
		await _frames(30)
		m.call(&"play_attack")
		await _frames(20)
		if m.has_method(&"play_charge"):
			m.call(&"play_charge")
			await _frames(20)
		m.call(&"set_moving", 0.0)
		m.call(&"play_hit")
		m.call(&"play_cast", &"lab_cast")
		await _frames(20)
		m.call(&"play_level_up")
		m.call(&"set_veterancy", 4)
		if m.has_method(&"play_fidget"):
			m.call(&"play_fidget")
		await _frames(20)
		for clip in [&"dance_victory", &"dance_surrender", &"dance_random"]:
			_check(bool(m.call(&"has_clip", clip)), "%s: has %s" % [id, clip])
			m.call(&"play_clip", clip)
			await _frames(10)
		m.call(&"stop_clip")
		if id in RANKED:
			m.call(&"set_rank", 3)
			await _frames(2)
			var crest := false
			for n in m.find_children("RankCrest", "", true, false):
				crest = crest or (n as Node3D).is_visible_in_tree()
			_check(crest, "%s: rank 3 shows a RankCrest" % id)
			_check(int(m.get_meta(&"rank", 0)) == 3, "%s: rank meta" % id)
		# a second instance shares every mesh / material (built once per type)
		var m2 := ps.instantiate() as Node3D
		root.add_child(m2)
		await _frames(3)
		m2.queue_free()
		# death
		var done := [false]
		m.connect(&"death_finished", func() -> void: done[0] = true)
		m.call(&"play_death")
		var f := 0
		while not done[0] and f < 150:
			await process_frame
			f += 1
		_check(done[0] and f <= 126, "%s: death_finished within 2 s (%d frames at 60 fps)" % [id, f])
		m.call(&"revive")
		await _frames(10)
		print("T3HOOKS %s ok (%d draws at rest)" % [id, d])
		m.queue_free()
		await _frames(2)
	if _fails.is_empty():
		print("T3HOOKS PASS")
	else:
		print("T3HOOKS FAIL: ", "; ".join(_fails))
	quit(0 if _fails.is_empty() else 1)
