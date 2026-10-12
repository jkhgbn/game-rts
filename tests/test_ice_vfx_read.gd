extends SceneTree
## Ice readability (docs/art/ingame_grade/under_90.md rows 17 / 19, pass 2026-10-12): Ice VFX stay cyan, dim and
## pooled. Checks:
## - Ice hit flashes are COOL and dimmer. combat_flash.gdshader stays blend_add (one shared MultiMesh for every
##   kingdom; accepted by the lead): the cool path drops the white-hot core, so Ice hits stay cyan, not white.
## - Ice light flashes / ground rings at or under the bloom threshold (<= 1.0).
## - The Rime Aegis dome is alpha-blended and hollow, the ice block alpha-blended.
## - The Ice death frost mist (CombatVfx.ICE_MIST, used by the mist_ice look) is cyan, see-through, <= 1.0.
## - Pooling: a real Ice vs Nature skirmish fight (Ice melee / ranged hits) plus Torvald casting Rime Bolt, Flash
##   Freeze and Rime Aegis, twice. Round 1 warms the lazy pools up; in round 2 every node added under IceVfx /
##   CombatVfx is counted (node_added, so a node created and freed per hit counts too) and must stay far below the
##   number of hits + casts (< 1 per 3 events): a node per hit or per cast would fail.
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_ice_vfx_read.gd --fixed-fps 60 --quit-after 9000

const TASK_ID := "ice_vfx_read"
const SKIRMISH := "res://scenes/skirmish.tscn"
const ROUND_FRAMES := 900

var _fails: Array[String] = []
var main: Node
var _frame := 0
var _phase := 0
var _phase_start := 0
var _ice: Node = null
var _combat: Node = null
var _count1 := -1
var _flashes1 := 0
var _armies: Array = [[], []]
var _center := Vector3.ZERO
var _added := 0                     # nodes added under IceVfx / CombatVfx during round 2
var _counting := false


func _initialize() -> void:
	_check_constants()
	_check_shaders()
	main = (load(SKIRMISH) as PackedScene).instantiate()
	main.set(&"player_kingdom", &"ice")
	main.set(&"enemy_kingdom", &"nature")
	main.set(&"time_limit_s", 0.0)
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame > 8500:
		_fails.append("timed out in phase %d" % _phase)
		return _finish()
	match _phase:
		0:
			if bool(main.get(&"match_started")):
				_phase = 1
				_phase_start = _frame
		1:
			if _frame - _phase_start == 30:
				_ice = _find_class(root, &"IceVfx")
				_combat = _find_class(root, &"CombatVfx")
				if _ice == null or _combat == null:
					_fails.append("IceVfx / CombatVfx not found in the skirmish")
					return _finish()
				_round()
				_phase = 2
				_phase_start = _frame
		2:
			_keep_casting()
			if _frame - _phase_start >= ROUND_FRAMES:
				_count1 = _children(_ice) + _children(_combat)
				_flashes1 = int((_combat.call(&"stats") as Dictionary).get("flashes", 0))
				_round()
				_counting = true
				node_added.connect(_on_node_added)
				_phase = 3
				_phase_start = _frame
		3:
			_keep_casting()
			if _frame - _phase_start >= ROUND_FRAMES:
				var n := _children(_ice) + _children(_combat)
				var flashes := int((_combat.call(&"stats") as Dictionary).get("flashes", 0))
				print("ice_vfx_read: vfx children round1=%d round2=%d, hit flashes round1=%d round2=%d, stats %s"
						% [_count1, n, _flashes1, flashes - _flashes1, _combat.call(&"stats")])
				if flashes - _flashes1 < 10:
					_fails.append("too few hits in round 2 (%d flashes): the pooling check saw no fight" % (flashes - _flashes1))
				# Lazy pools (emitters, lights, auras, trails) may still fill up a little in round 2; a node per hit
				# or per cast (even one freed again) would add at least one node per event.
				var events := flashes - _flashes1 + 3
				print("ice_vfx_read: nodes added under the VFX in round 2 = %d for %d events" % [_added, events])
				if _added * 3 >= events:
					_fails.append("%d nodes added under IceVfx / CombatVfx for %d hits / casts (per-event nodes)"
							% [_added, events])
				return _finish()
	return false


## Ground point at the centre of the active camera's view (y = 0 plane).
func _view_center() -> Vector3:
	var cam := root.get_viewport().get_camera_3d()
	if cam == null:
		return Vector3(-16, 0, 34)
	var o := cam.global_position
	var d := -cam.global_transform.basis.z
	if absf(d.y) < 0.05:
		return Vector3(o.x, 0, o.z)
	var p := o + d * (-o.y / d.y)
	return Vector3(p.x, 0, p.z)


func _on_node_added(n: Node) -> void:
	if _counting and (_ice.is_ancestor_of(n) or _combat.is_ancestor_of(n)):
		_added += 1


func _finish() -> bool:
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	return true


## One fight round: fresh Ice and Nature armies face off next to the two wizards, Torvald learns his spells.
func _round() -> void:
	for team in [0, 1]:
		for u: Variant in _armies[team]:
			if is_instance_valid(u):
				(u as Node).queue_free()
	_armies = [[], []]
	var w0: Node3D = main.call(&"wizard_of", 0)
	var w1: Node3D = main.call(&"wizard_of", 1)
	_center = _view_center()   # the fight happens where the camera looks (CombatVfx skips off-screen hits)
	var fwd := Vector3(1, 0, -1).normalized()
	var axis := Vector3(1, 0, 1).normalized()
	w0.global_position = _center - fwd * 4.0
	w1.global_position = _center + fwd * 4.0
	w0.call(&"command_stop")
	w1.call(&"command_stop")
	if _phase == 1:
		w0.call(&"add_xp", 5000)
		w0.set(&"spell_points", 10)
		for id: StringName in w0.get(&"default_spell_ids"):
			w0.call(&"learn_spell", id)
	var types := [["rimeling", "frostbow", "rimeshield"], ["thornling", "wildwood_archer", "bramblehorn"]]
	for team in [0, 1]:
		var side := -1.0 if team == 0 else 1.0
		var i := 0
		for t: String in types[team]:
			for j in 2:
				var u: Node = main.call(&"make_unit", t)
				if u == null:
					continue
				u.set(&"team", team)
				main.add_child(u)
				(u as Node3D).global_position = _center + axis * (float(i) - 2.5) * 1.6 + fwd * side * 2.0
				_armies[team].append(u)
				i += 1
	for team in [0, 1]:
		for u: Node in _armies[team]:
			if not _armies[1 - team].is_empty():
				u.call(&"command_attack", _armies[1 - team][randi() % _armies[1 - team].size()])


## Torvald casts Rime Bolt, Flash Freeze and Rime Aegis early in the round.
func _keep_casting() -> void:
	var t := _frame - _phase_start
	if t != 60 and t != 200 and t != 340:
		return
	var w0: Node = main.call(&"wizard_of", 0)
	var w1: Node3D = main.call(&"wizard_of", 1)
	if w0 == null or w1 == null:
		return
	w0.set(&"mana", 9999.0)
	var ids: Array = w0.get(&"default_spell_ids")
	var k := [60, 200, 340].find(t)
	if k < ids.size():
		var r: Variant = w0.call(&"command_cast", ids[k], w1)
		if String(r) != "":
			w0.call(&"command_cast", ids[k], w1.global_position)


func _check_constants() -> void:
	if CombatVfx.ICE_COOL < 1.5:
		_fails.append("CombatVfx.ICE_COOL must be >= 1.5 (combat_flash.gdshader cool flag)")
	var f := CombatVfx.ICE_FLASH
	if f.a > 0.75 or maxf(f.r, maxf(f.g, f.b)) > 1.1 or f.b <= f.r:
		_fails.append("Ice flash not a dim cyan: %s" % f)
	if CombatVfx.ICE_HIT_SCALE > 0.5 or CombatVfx.ICE_HIT_LIFE > 0.5:
		_fails.append("Ice hit flash not half size / half life")
	var m := CombatVfx.ICE_MIST
	if m.a > 0.35 or maxf(m.r, maxf(m.g, m.b)) > 1.0 or m.b < m.r * 2.0 or m.g < m.r * 1.5:
		_fails.append("Ice frost mist not a see-through cyan under the bloom: %s" % m)
	for e: float in [IceVfx.LIGHT_CAST, IceVfx.LIGHT_HIT, IceVfx.LIGHT_FREEZE, IceVfx.LIGHT_AEGIS, IceVfx.RING_ENERGY]:
		if e > 1.0:
			_fails.append("Ice light / ring energy %.2f > 1.0" % e)


func _check_shaders() -> void:
	var flash := (load("res://art/vfx/combat_flash.gdshader") as Shader).code
	if not flash.contains("v_cool"):
		_fails.append("combat_flash.gdshader has no cool (Ice) path")
	var dome := (load("res://art/vfx/ice_dome.gdshader") as Shader).code
	if not dome.contains("blend_mix") or dome.contains("blend_add"):
		_fails.append("ice_dome.gdshader must be alpha-blended")
	if not dome.contains("smoothstep(0.45, 0.12, nv)"):
		_fails.append("ice_dome.gdshader is no longer hollow (rim only)")
	var block := (load("res://art/vfx/ice_block.gdshader") as Shader).code
	if block.contains("blend_add"):
		_fails.append("ice_block.gdshader must be alpha-blended")


func _find_class(n: Node, cls: StringName) -> Node:
	var s: Script = n.get_script() as Script
	if s and s.get_global_name() == cls:
		return n
	for c in n.get_children():
		var r := _find_class(c, cls)
		if r:
			return r
	return null


func _children(n: Node) -> int:
	var c := 0
	for k in n.get_children():
		c += 1 + _children(k)
	return c
