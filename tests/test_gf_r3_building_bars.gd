extends SceneTree
## G-F review 3 item 3: building HP bars are thin (0.12 m), sized by the footprint (x * 0.6, 1.6-4.0 m), a light edge
## (no black frame), and fade like unit bars (0.35 opacity FADE_HOLD s after the last hit; full on a hit / hover /
## selection). Construction sites never fade.
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_gf_r3_building_bars.gd --fixed-fps 60 --quit-after 4000

const TASK_ID := "gf_r3_building_bars"
const TIMEOUT_FRAMES := 3000

var main: Node
var _wait := 0
var _frame := 0
var _step := 0
var _t_ms := 0
var _tower: Building
var _keep: Building
var _errors: Array[String] = []


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	_frame += 1
	if _frame == 1:
		_setup()
		return false
	if _run():
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		return true
	if _frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out at step %d" % [TASK_ID, _step])
		return true
	return false


func _expect(ok: bool, msg: String) -> void:
	if not ok:
		_errors.append(msg)


func _setup() -> void:
	var grid: BuildGrid = main.get(&"build_grid")
	for n in get_nodes_in_group(&"buildings"):
		if n is Keep and int((n as Building).team) == Unit.Team.PLAYER:
			_keep = n
	_tower = grid.spawn_complete(BuildingType.find(&"fire_tower"), _keep.global_position + Vector3(14, 0, 0),
			Unit.Team.PLAYER)


func _bar_size(b: Building) -> Vector2:
	var bar: MeshInstance3D = b.get(&"_hp_bar")
	return (bar.mesh as QuadMesh).size


## The steps run on real time (the shader's fade clock is UnitFx.now(), real milliseconds).
func _run() -> bool:
	var now := Time.get_ticks_msec()
	match _step:
		0:
			# Sizes: tower (1 cell = 2 m) clamps to 1.6, keep (6 m) = 3.6, height 0.12, light edge, fades.
			var ts := _bar_size(_tower)
			var ks := _bar_size(_keep)
			_expect(is_equal_approx(ts.x, 1.6) and is_equal_approx(ts.y, 0.12), "tower bar %s" % str(ts))
			_expect(is_equal_approx(ks.x, 3.6) and is_equal_approx(ks.y, 0.12), "keep bar %s" % str(ks))
			_expect(ks.x <= 4.0 and ts.x >= 1.6, "bar width out of 1.6-4.0")
			var mat := (_keep.get(&"_hp_bar") as MeshInstance3D).material_override as ShaderMaterial
			var fsz: Vector2 = mat.get_shader_parameter(&"frame_size")
			var fcol: Color = mat.get_shader_parameter(&"frame_color")
			_expect(fsz.x <= 0.015 and fcol.a < 0.75, "keep bar keeps a black frame (%.3f m, alpha %.2f)" % [fsz.x, fcol.a])
			_expect(is_equal_approx(float(mat.get_shader_parameter(&"fade_min")), Unit.HP_BAR_FADE_MIN),
					"building bar does not fade to 35 %")
			_tower.take_damage(_tower.max_hp * 0.2, null)
			_expect(is_equal_approx(_tower.hp_bar_opacity(), 1.0), "fresh hit: opacity %.2f" % _tower.hp_bar_opacity())
			_t_ms = now
			_step = 1
		1:
			if now - _t_ms < int((UnitFx.FADE_HOLD + UnitFx.FADE_TIME) * 1000.0) + 200:
				return false
			_expect(_tower.hp_bar_opacity() <= Unit.HP_BAR_FADE_MIN + 0.01,
					"no fade after %.1f s: %.2f" % [UnitFx.FADE_HOLD, _tower.hp_bar_opacity()])
			_tower.set_selected(true)
			_expect(is_equal_approx(_tower.hp_bar_opacity(), 1.0), "selected: opacity %.2f" % _tower.hp_bar_opacity())
			var bar: MeshInstance3D = _tower.get(&"_hp_bar")
			_expect(float(bar.get_instance_shader_parameter(&"focus")) == 1.0, "selected: shader focus not 1")
			_tower.set_selected(false)
			_expect(_tower.hp_bar_opacity() <= Unit.HP_BAR_FADE_MIN + 0.01, "deselected: bar did not fade back")
			_tower.set_hp_bar_hover(true)
			_expect(is_equal_approx(_tower.hp_bar_opacity(), 1.0), "hover: opacity %.2f" % _tower.hp_bar_opacity())
			_tower.set_hp_bar_hover(false)
			_tower.take_damage(_tower.max_hp * 0.1, null)
			_expect(is_equal_approx(_tower.hp_bar_opacity(), 1.0), "new hit: opacity %.2f" % _tower.hp_bar_opacity())
			return true
	return false
