extends "res://tools/unit_lab/unit_lab_arena.gd"
## Unit Lab SANDBOX (docs/plan/unit-lab.md, part B): the SC2-style unit tester, scenes/unit_lab.tscn. Dev only: not in
## the player menus; open it with `godot --path . res://scenes/unit_lab.tscn`, with the main menu's `-- --unit-lab`
## flag, or Ctrl+Shift+U on the main menu (debug builds).
## A flat arena (UnitLabArena) + a spawn panel, fight controls, live stats, a damage meter, a fight log and save /
## load of the setup in the runner's spec format (tools/unit_lab/setups/<name>.json -> run_unit_lab.ps1 <path>).
## Keys (physical): right-click or Space = spawn the chosen units at the cursor, left-click = inspect a unit,
## 1 / 2 = team A / B, Enter = start / resume, P = pause, N = step 0.1 s, R = reset (the same setup), Delete = kill the
## inspected unit, H = heal / restore everyone, C = range circles for all, - / = = slower / faster, F12 = screenshot,
## arrows / middle-drag = pan, wheel = zoom, Esc = clear the inspection.
## The tree pauses before Start and on Pause; the camera, input and UI run while paused (PROCESS_MODE_ALWAYS).

const SETUP_DIR := "res://tools/unit_lab/setups/"
const SHOT_DIR := "user://unit_lab_shots/"
const SPEEDS: Array[float] = [0.1, 0.25, 0.5, 1.0, 1.5, 2.0, 3.0]
const STEP_SECONDS := 0.1

class InputRelay extends Node:
	var lab: Node

	func _unhandled_input(event: InputEvent) -> void:
		lab.call(&"_sandbox_input", event)

	func _process(delta: float) -> void:
		lab.call(&"_sandbox_process", delta)

var camera: Camera3D
var ui: CanvasLayer
var setup_spec: Dictionary = {}       # normalized spec; arm 0 = what Reset respawns
var started := false
var paused := true
var speed_i := 3
var show_all_rings := false
var inspected: Unit = null
var spawn_team := 0
var _step_left := 0.0
var _cam_target := Vector3.ZERO
var _cam_dist := 30.0
var _cam_yaw := 0.0
var _drag := false
var _rings: MeshInstance3D
var _ring_mesh: ImmediateMesh
var _meter_left := 0.0
var _relay: InputRelay

# UI widgets
var _kingdom: OptionButton
var _unit: OptionButton
var _count: SpinBox
var _level: SpinBox
var _hp: SpinBox
var _plus: CheckBox
var _full_mana: CheckBox
var _team: OptionButton
var _status: OptionButton
var _status_s: SpinBox
var _buff: OptionButton
var _side_order: Array[OptionButton] = []
var _side_casters: Array[OptionButton] = []
var _side_focus: Array[OptionButton] = []
var _info: Label
var _meter: Label
var _log_box: RichTextLabel
var _state: Label
var _file: LineEdit
var _ids_by_kingdom := {}


func _ready() -> void:
	super._ready()
	process_mode = Node.PROCESS_MODE_PAUSABLE
	setup_spec = SPEC.normalize({"name": "sandbox", "a": {"groups": []}, "b": {"groups": []}, "seeds": [1],
			"time_limit": 600.0, "distance": 20.0}, [])
	time_limit = 600.0
	sides = [setup_spec["arms"][0]["a"], setup_spec["arms"][0]["b"]]
	_build_scene()
	_build_ui()
	fight_log.connect(_on_log)
	fight_ended.connect(func(_r: Dictionary) -> void: _set_paused(true))
	if is_inside_tree():
		get_tree().paused = true
	_refresh_state()


# ---------------------------------------------------------------- scene (camera, light, ground look)

func _build_scene() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.16, 0.18, 0.22)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.8, 0.82, 0.9)
	e.ambient_light_energy = 0.6
	env.environment = e
	add_child(env)
	add_infra(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_energy = 1.1
	add_child(sun)
	add_infra(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(arena_size, arena_size)
	ground.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.32, 0.36, 0.30)
	ground.material_override = mat
	add_child(ground)
	add_infra(ground)
	# grid lines every 5 m and the two spawn spots
	var grid := MeshInstance3D.new()
	var im := ImmediateMesh.new()
	var gm := StandardMaterial3D.new()
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.vertex_color_use_as_albedo = true
	im.surface_begin(Mesh.PRIMITIVE_LINES, gm)
	var h := arena_size * 0.5
	var x := -h
	while x <= h + 0.01:
		var c := Color(0.45, 0.5, 0.42) if absf(x) > 0.01 else Color(0.8, 0.8, 0.5)
		im.surface_set_color(c)
		im.surface_add_vertex(Vector3(x, 0.02, -h))
		im.surface_add_vertex(Vector3(x, 0.02, h))
		im.surface_add_vertex(Vector3(-h, 0.02, x))
		im.surface_add_vertex(Vector3(h, 0.02, x))
		x += 5.0
	im.surface_end()
	grid.mesh = im
	add_child(grid)
	add_infra(grid)
	_rings = MeshInstance3D.new()
	_ring_mesh = ImmediateMesh.new()
	_rings.mesh = _ring_mesh
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.vertex_color_use_as_albedo = true
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_rings.material_override = rm
	add_child(_rings)
	add_infra(_rings)
	camera = Camera3D.new()
	camera.current = true
	camera.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(camera)
	add_infra(camera)
	_place_camera()
	_relay = InputRelay.new()
	_relay.lab = self
	_relay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_relay)
	add_infra(_relay)


func _place_camera() -> void:
	var dir := Vector3(sin(_cam_yaw), 0.0, cos(_cam_yaw))
	camera.position = _cam_target + dir * _cam_dist * 0.62 + Vector3.UP * _cam_dist * 0.78
	camera.look_at(_cam_target, Vector3.UP)


# ---------------------------------------------------------------- UI

func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(ui)
	add_infra(ui)
	var left := PanelContainer.new()
	left.position = Vector2(8, 8)
	left.custom_minimum_size = Vector2(300, 0)
	ui.add_child(left)
	var v := VBoxContainer.new()
	left.add_child(v)
	_title(v, "UNIT LAB  (dev sandbox)")
	_kingdom = _option(v, "Kingdom", ["fire", "ice", "nature", "shadow", "neutral"])
	_kingdom.item_selected.connect(func(_i: int) -> void: _fill_units())
	_unit = _option(v, "Unit", [])
	_count = _spin(v, "Count", 1, 40, 5)
	_team = _option(v, "Team", ["A (blue side, -X)", "B (red side, +X)"])
	_team.item_selected.connect(func(i: int) -> void: spawn_team = i)
	_level = _spin(v, "Level (veterancy)", 1, 4, 1)
	_hp = _spin(v, "HP %", 5, 100, 100)
	_plus = CheckBox.new()
	_plus.text = "\"+\" upgrade"
	v.add_child(_plus)
	_full_mana = CheckBox.new()
	_full_mana.text = "Casters: full mana"
	_full_mana.button_pressed = true
	v.add_child(_full_mana)
	_button(v, "Spawn at cursor  [right-click / Space]", func() -> void: spawn_at_cursor())
	_button(v, "Spawn at side spot", func() -> void:
		spawn_group_at(_choice(), spawn_team, side_centre(spawn_team)))
	_title(v, "Buffs / statuses (to the chosen team)")
	var keys: Array = []
	for k: StringName in Unit.STATUSES:
		keys.append(String(k))
	_status = _option(v, "Status", keys)
	_status_s = _spin(v, "Seconds", 1, 120, 10)
	_button(v, "Apply status", func() -> void: apply_status_to_team(spawn_team, _status.get_item_text(_status.selected),
			_status_s.value))
	_buff = _option(v, "Modifier", ["+25 % damage", "+25 % max HP", "+10 armor", "-25 % attack cooldown", "+1 move speed"])
	_button(v, "Apply modifier", func() -> void: apply_buff_to_team(spawn_team, _buff.selected))
	_title(v, "Sides")
	for s in 2:
		var row := HBoxContainer.new()
		v.add_child(row)
		var l := Label.new()
		l.text = "AB"[s]
		row.add_child(l)
		var o := _opt_in(row, ["attack_move", "hold", "idle", "bot"])
		o.item_selected.connect(func(_i: int) -> void: _sync_sides())
		_side_order.append(o)
		var f := _opt_in(row, ["none", "lowest_hp", "casters"])
		f.item_selected.connect(func(_i: int) -> void: _sync_sides())
		_side_focus.append(f)
		var c := _opt_in(row, ["autocast", "on", "off", "bot"])
		c.item_selected.connect(func(_i: int) -> void: _sync_sides())
		_side_casters.append(c)
	_title(v, "Setup file (tools/unit_lab/setups/)")
	_file = LineEdit.new()
	_file.text = "my_setup"
	v.add_child(_file)
	var fr := HBoxContainer.new()
	v.add_child(fr)
	_button(fr, "Save", func() -> void: save_setup(_file.text))
	_button(fr, "Load", func() -> void: load_setup(_file.text))
	# right column: controls, info, meter, log
	var right := PanelContainer.new()
	right.anchor_left = 1.0
	right.anchor_right = 1.0
	right.offset_left = -500
	right.offset_right = -8
	right.offset_top = 8
	ui.add_child(right)
	var rv := VBoxContainer.new()
	right.add_child(rv)
	var cr := HBoxContainer.new()
	rv.add_child(cr)
	_button(cr, "Start", func() -> void: start_fight())
	_button(cr, "Pause", func() -> void: _set_paused(true))
	_button(cr, "Step", func() -> void: step(STEP_SECONDS))
	_button(cr, "Reset", func() -> void: reset_setup())
	_button(cr, "Clear", func() -> void: clear_setup())
	var cr2 := HBoxContainer.new()
	rv.add_child(cr2)
	_button(cr2, "Slower", func() -> void: set_speed_index(speed_i - 1))
	_button(cr2, "Faster", func() -> void: set_speed_index(speed_i + 1))
	_button(cr2, "Heal all", func() -> void: restore_all())
	_button(cr2, "Kill sel.", func() -> void: kill_inspected())
	_button(cr2, "Shot", func() -> void: screenshot())
	_state = Label.new()
	rv.add_child(_state)
	_info = Label.new()
	_info.custom_minimum_size = Vector2(480, 120)
	rv.add_child(_info)
	_title(rv, "Damage meter")
	_meter = Label.new()
	_meter.custom_minimum_size = Vector2(480, 160)
	rv.add_child(_meter)
	_title(rv, "Fight log")
	_log_box = RichTextLabel.new()
	_log_box.custom_minimum_size = Vector2(480, 200)
	_log_box.scroll_following = true
	rv.add_child(_log_box)
	_fill_units()


func _title(p: Control, t: String) -> void:
	var l := Label.new()
	l.text = t
	l.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
	p.add_child(l)


func _option(p: Control, label: String, items: Array) -> OptionButton:
	var row := HBoxContainer.new()
	p.add_child(row)
	var l := Label.new()
	l.text = label
	l.custom_minimum_size = Vector2(110, 0)
	row.add_child(l)
	return _opt_in(row, items)


func _opt_in(row: Control, items: Array) -> OptionButton:
	var o := OptionButton.new()
	for it: Variant in items:
		o.add_item(String(it))
	o.focus_mode = Control.FOCUS_NONE
	row.add_child(o)
	return o


func _spin(p: Control, label: String, lo: float, hi: float, val: float) -> SpinBox:
	var row := HBoxContainer.new()
	p.add_child(row)
	var l := Label.new()
	l.text = label
	l.custom_minimum_size = Vector2(110, 0)
	row.add_child(l)
	var s := SpinBox.new()
	s.min_value = lo
	s.max_value = hi
	s.value = val
	row.add_child(s)
	return s


func _button(p: Control, t: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	p.add_child(b)
	return b


func _fill_units() -> void:
	if _unit == null:
		return
	var k := _kingdom.get_item_text(_kingdom.selected)
	if not _ids_by_kingdom.has(k):
		var rows: Array = []
		var d := DirAccess.open(UnitType.DIR)
		if d:
			for f in d.get_files():
				if f.ends_with(".tres"):
					var t := UnitType.find(f.get_basename())
					if t and String(t.faction) == k and not t.is_worker and t.cost > 0:
						rows.append([t.requires_tier, t.cost, String(t.id)])
		rows.sort()
		_ids_by_kingdom[k] = rows.map(func(r: Array) -> String: return r[2])
	_unit.clear()
	for id: String in _ids_by_kingdom[k]:
		var t := UnitType.find(id)
		_unit.add_item("%s  (T%d, %d c)" % [id, t.requires_tier, t.cost])
		_unit.set_item_metadata(_unit.item_count - 1, id)


## The spawn panel's current choice as a spec group (without "at").
func _choice() -> Dictionary:
	var id := "flame_guard"
	if _unit and _unit.item_count > 0:
		id = String(_unit.get_item_metadata(_unit.selected))
	return {"id": id, "count": int(_count.value) if _count else 1, "level": int(_level.value) if _level else 1,
			"plus": _plus.button_pressed if _plus else false, "hp_pct": (_hp.value / 100.0) if _hp else 1.0,
			"mana": "full" if (_full_mana and _full_mana.button_pressed) else -1}


func _sync_sides() -> void:
	for s in 2:
		var side: Dictionary = setup_spec["arms"][0]["ab"[s]]
		var o := _side_order[s].get_item_text(_side_order[s].selected)
		if o == "bot":
			side["order"] = "attack_move"
			side["focus"] = "casters"
			side["casters"] = "bot"
		else:
			side["order"] = o
			side["focus"] = _side_focus[s].get_item_text(_side_focus[s].selected)
			side["casters"] = _side_casters[s].get_item_text(_side_casters[s].selected)
	sides = [setup_spec["arms"][0]["a"], setup_spec["arms"][0]["b"]]


# ---------------------------------------------------------------- public API (also used by tests)

## Adds a group to the setup at `at` (ground point) and spawns it now.
func spawn_group_at(group: Dictionary, s: int, at: Vector3) -> Array:
	var errors: Array = []
	var g := group.duplicate(true)
	g["at"] = [snappedf(at.x, 0.1), snappedf(at.z, 0.1)]
	var ng := SPEC.normalize_group(g, errors)
	if ng.is_empty():
		_on_log("spawn refused: " + "; ".join(errors))
		return []
	(setup_spec["arms"][0]["ab"[s]]["groups"] as Array).append(ng)
	setup_spec["arms"][0]["ab"[s]]["label"] = SPEC.side_label(setup_spec["arms"][0]["ab"[s]])
	sides = [setup_spec["arms"][0]["a"], setup_spec["arms"][0]["b"]]
	var t := UnitType.find(String(ng["id"]))
	var out: Array = []
	for p: Vector3 in formation_points(at, side_facing(s), [t], int(ng["count"]), "block"):
		out.append(spawn_unit(String(ng["id"]), s, p, ng))
	if String((sides[s] as Dictionary).get("casters", "")) == "bot" and _commanders[s] == null:
		_make_commander(s)
	_refresh_state()
	return out


func spawn_at_cursor() -> void:
	var p: Variant = cursor_ground()
	if p == null:
		return
	spawn_group_at(_choice(), spawn_team, p as Vector3)


## The ground point under the mouse, or null.
func cursor_ground() -> Variant:
	if camera == null or not is_inside_tree():
		return null
	var mp := get_viewport().get_mouse_position()
	var o := camera.project_ray_origin(mp)
	var d := camera.project_ray_normal(mp)
	if absf(d.y) < 0.001:
		return null
	var t := -o.y / d.y
	if t < 0.0:
		return null
	var p := o + d * t
	var h := arena_size * 0.5 - 0.5
	return Vector3(clampf(p.x, -h, h), 0.0, clampf(p.z, -h, h))


## Starts (or resumes) the fight: the first time, the sides get their start orders.
func start_fight() -> void:
	if ended:
		reset_setup()
	if not started:
		started = true
		_warmup = WARMUP_FRAMES
		running = true
		ended = false
		game_over = false
	_set_paused(false)


## Runs `seconds` of game time then pauses again.
func step(seconds: float) -> void:
	if not started:
		start_fight()
	_step_left = seconds
	_set_paused(false)


func _set_paused(on: bool) -> void:
	paused = on
	if is_inside_tree():
		get_tree().paused = on
	_refresh_state()


func set_speed_index(i: int) -> void:
	speed_i = clampi(i, 0, SPEEDS.size() - 1)
	Engine.time_scale = SPEEDS[speed_i]
	_refresh_state()


## Respawns the setup (arm 0 of setup_spec) as it was placed; the fight waits for Start.
func reset_setup() -> void:
	_sync_sides()
	var keep := setup_spec.duplicate(true)
	clear_units()
	setup_spec = keep
	sides = [setup_spec["arms"][0]["a"], setup_spec["arms"][0]["b"]]
	side_team.assign([0, 1])
	for s in 2:
		spawn_side(s)
	started = false
	running = false
	ended = false
	inspected = null
	time = 0.0
	if _log_box:
		_log_box.clear()
	_set_paused(true)


## Empties the arena and the setup.
func clear_setup() -> void:
	clear_units()
	for s in 2:
		setup_spec["arms"][0]["ab"[s]]["groups"] = []
	sides = [setup_spec["arms"][0]["a"], setup_spec["arms"][0]["b"]]
	started = false
	inspected = null
	_set_paused(true)


## Full HP (and full mana for casters) on every living unit.
func restore_all() -> void:
	for s in 2:
		for u: Unit in living_units(s):
			u.heal(u.max_hp)
			var ab := CasterKit.ability_of(u)
			if ab:
				ab.add_mana(ab.max_mana())


func kill_inspected() -> void:
	if inspected and is_instance_valid(inspected) and inspected.is_alive():
		inspected.take_damage(inspected.hp + inspected.max_hp * 10.0, null)


func apply_status_to_team(s: int, status_id: String, seconds: float) -> void:
	for u: Unit in living_units(s):
		u.apply_status(StringName(status_id), seconds)
	_on_log("%s: status %s %.0f s on side %s" % [_clock(), status_id, seconds, "AB"[s]])


const BUFFS := [{"attack_damage_pct": 0.25}, {"max_hp_pct": 0.25}, {"armor": 10.0}, {"attack_cooldown_pct": -0.25},
		{"move_speed": 1.0}]


func apply_buff_to_team(s: int, i: int) -> void:
	var stats: Dictionary = BUFFS[clampi(i, 0, BUFFS.size() - 1)]
	for u: Unit in living_units(s):
		u.add_modifier(StringName("unit_lab_buff_%d" % i), stats)
	# the setup keeps it (mods on every group of the side)
	for g: Dictionary in setup_spec["arms"][0]["ab"[s]]["groups"]:
		for k: String in stats:
			g["mods"][k] = float(g["mods"].get(k, 0.0)) + float(stats[k])
	_on_log("%s: modifier %s on side %s" % [_clock(), str(stats), "AB"[s]])


## Writes the setup as a runner spec (tools/unit_lab/setups/<name>.json); returns the path ("" on failure).
func save_setup(name_or_path: String) -> String:
	_sync_sides()
	var path := _setup_path(name_or_path)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var raw := SPEC.arm_to_raw(setup_spec, setup_spec["arms"][0])
	raw["name"] = name_or_path.get_file().get_basename()
	raw["notes"] = "Saved by the Unit Lab sandbox (scenes/unit_lab.tscn)."
	raw["seeds"] = "1-10"
	raw["time_limit"] = 120.0
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		_on_log("can't write " + path)
		return ""
	f.store_string(JSON.stringify(raw, "\t"))
	f.close()
	_on_log("saved " + ProjectSettings.globalize_path(path))
	return path


## Loads a setup file, a preset or a text line; arm 0 becomes the setup (groups without "at" use the formation).
func load_setup(name_or_path: String) -> bool:
	var errors: Array = []
	var src := name_or_path
	if not (src.contains(" vs ") or src.contains(" ~ ")):
		var p := _setup_path(src)
		if FileAccess.file_exists(p):
			src = p
	var spec := SPEC.load_any(src, errors)
	if (spec["arms"] as Array).is_empty():
		_on_log("can't load %s: %s" % [name_or_path, "; ".join(errors)])
		return false
	setup_spec = SPEC.normalize({"name": spec["name"], "a": {}, "b": {}}, [])
	setup_spec["arms"][0] = (spec["arms"][0] as Dictionary).duplicate(true)
	distance = float(spec.get("distance", 20.0))
	for s in 2:
		var side: Dictionary = setup_spec["arms"][0]["ab"[s]]
		_select(_side_order[s], String(side.get("order", "attack_move")))
		_select(_side_focus[s], String(side.get("focus", "none")))
		_select(_side_casters[s], String(side.get("casters", "autocast")))
		if String(side.get("casters", "")) == "bot" and String(side.get("focus", "")) == "casters":
			_select(_side_order[s], "bot")
	reset_setup()
	_on_log("loaded %s (%s)" % [name_or_path, spec["name"]])
	return true


func _select(o: OptionButton, text: String) -> void:
	for i in o.item_count:
		if o.get_item_text(i) == text:
			o.select(i)
			return


func _setup_path(n: String) -> String:
	if n.ends_with(".json"):
		return n if (n.begins_with("res://") or n.begins_with("user://") or n.is_absolute_path()) else SETUP_DIR + n
	return SETUP_DIR + n + ".json"


## Saves the viewport to user://unit_lab_shots/ (nothing in headless runs); returns the path or "".
func screenshot() -> String:
	if DisplayServer.get_name() == "headless" or not is_inside_tree():
		return ""
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	var path := SHOT_DIR + "unit_lab_%s.png" % Time.get_datetime_string_from_system().replace(":", "-")
	img.save_png(path)
	_on_log("screenshot " + ProjectSettings.globalize_path(path))
	return path


# ---------------------------------------------------------------- per frame (runs while paused too)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _step_left > 0.0 and not get_tree().paused:
		_step_left -= delta
		if _step_left <= 0.0:
			_set_paused(true)


func _sandbox_process(delta: float) -> void:
	var pan := Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_LEFT):
		pan.x -= 1.0
	if Input.is_physical_key_pressed(KEY_RIGHT):
		pan.x += 1.0
	if Input.is_physical_key_pressed(KEY_UP):
		pan.z -= 1.0
	if Input.is_physical_key_pressed(KEY_DOWN):
		pan.z += 1.0
	if pan != Vector3.ZERO:
		_cam_target += pan.normalized() * _cam_dist * 0.8 * delta / maxf(0.1, Engine.time_scale)
		_place_camera()
	_draw_rings()
	_meter_left -= delta
	if _meter_left <= 0.0:
		_meter_left = 0.25
		_update_info()
		_update_meter()
		_refresh_state()


func _sandbox_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_cam_dist = maxf(8.0, _cam_dist * 0.9)
			_place_camera()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_cam_dist = minf(120.0, _cam_dist * 1.1)
			_place_camera()
		elif mb.button_index == MOUSE_BUTTON_MIDDLE:
			_drag = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			spawn_at_cursor()
		elif mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_inspect_at_cursor()
	elif event is InputEventMouseMotion and _drag:
		var mm := event as InputEventMouseMotion
		_cam_target += Vector3(-mm.relative.x, 0.0, -mm.relative.y) * _cam_dist * 0.002
		_place_camera()
	elif event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		match (event as InputEventKey).physical_keycode:
			KEY_SPACE:
				spawn_at_cursor()
			KEY_1:
				spawn_team = 0
				_team.select(0)
			KEY_2:
				spawn_team = 1
				_team.select(1)
			KEY_ENTER, KEY_KP_ENTER:
				start_fight()
			KEY_P:
				_set_paused(not paused)
			KEY_N:
				step(STEP_SECONDS)
			KEY_R:
				reset_setup()
			KEY_DELETE:
				kill_inspected()
			KEY_H:
				restore_all()
			KEY_C:
				show_all_rings = not show_all_rings
			KEY_MINUS, KEY_KP_SUBTRACT:
				set_speed_index(speed_i - 1)
			KEY_EQUAL, KEY_KP_ADD:
				set_speed_index(speed_i + 1)
			KEY_F12:
				screenshot()
			KEY_ESCAPE:
				inspected = null


func _inspect_at_cursor() -> void:
	var p: Variant = cursor_ground()
	if p == null:
		return
	var best: Unit = null
	var bd := 2.0
	for s in 2:
		for u: Unit in living_units(s):
			var d := Vector2(u.global_position.x - (p as Vector3).x, u.global_position.z - (p as Vector3).z).length()
			if d < bd:
				bd = d
				best = u
	inspected = best


func _draw_rings() -> void:
	_ring_mesh.clear_surfaces()
	var list: Array = []
	if show_all_rings:
		list = living_units(0) + living_units(1)
	elif inspected and is_instance_valid(inspected) and inspected.is_alive():
		list = [inspected]
	if list.is_empty():
		return
	_ring_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for u: Unit in list:
		var side := int(records.get(u.get_instance_id(), {}).get("side", 0))
		var col := Color(0.4, 0.7, 1.0) if side == 0 else Color(1.0, 0.45, 0.4)
		_circle(u.global_position, u.attack_range + u.radius, col)
		if u == inspected:
			_circle(u.global_position, u.aggro_range, Color(col, 0.4))
	_ring_mesh.surface_end()


func _circle(c: Vector3, r: float, col: Color) -> void:
	var n := 40
	for i in n:
		var a0 := TAU * float(i) / float(n)
		var a1 := TAU * float(i + 1) / float(n)
		_ring_mesh.surface_set_color(col)
		_ring_mesh.surface_add_vertex(c + Vector3(cos(a0) * r, 0.08, sin(a0) * r))
		_ring_mesh.surface_add_vertex(c + Vector3(cos(a1) * r, 0.08, sin(a1) * r))


func _update_info() -> void:
	if _info == null:
		return
	if inspected == null or not is_instance_valid(inspected):
		_info.text = "Left-click a unit to inspect it."
		return
	var u := inspected
	var r: Dictionary = records.get(u.get_instance_id(), {})
	var alive_t := maxf(0.1, (float(r.get("died", -1.0)) if float(r.get("died", -1.0)) >= 0.0 else time) \
			- float(r.get("born", 0.0)))
	var lines := PackedStringArray()
	lines.append("%s  side %s  L%d%s" % [r.get("id", u.unit_name), "AB"[int(r.get("side", 0))], u.level,
			"  (dead)" if not u.is_alive() else ""])
	lines.append("HP %d / %d   armor %.0f   shield %.0f" % [roundi(u.hp), roundi(u.max_hp), u.get_stat(&"armor"), u.shield])
	lines.append("Damage %.1f   cooldown %.2f s   range %.1f   speed %.1f" % [u.attack_damage, u.attack_cooldown,
			u.effective_attack_range(), u.move_speed])
	lines.append("Dealt %d   DPS %.1f   taken %d   kills %d" % [roundi(float(r.get("dealt", 0.0))),
			float(r.get("dealt", 0.0)) / alive_t, roundi(float(r.get("taken", 0.0))), int(r.get("kills", 0))])
	var st := PackedStringArray()
	for x: StringName in u.active_statuses():
		st.append("%s %.1fs" % [x, u.status_time_left(x)])
	if not st.is_empty():
		lines.append("Statuses: " + ", ".join(st))
	var ab := CasterKit.ability_of(u)
	if ab:
		var cds := PackedStringArray()
		for sp in ab.spell_ids():
			cds.append("%s%s cd %.1f" % [sp, " (auto)" if ab.autocast(sp) else "", ab.cooldown_left(sp)])
		lines.append("Mana %d / %d   gcd %.1f   %s" % [roundi(ab.mana), roundi(ab.max_mana()), ab.gcd_left(), "; ".join(cds)])
	_info.text = "\n".join(lines)


func _update_meter() -> void:
	if _meter == null:
		return
	var rows := PackedStringArray()
	for s in 2:
		var sm := side_summary(s)
		rows.append("Side %s: %d / %d alive, %d crystals, dealt %d, taken %d" % ["AB"[s], sm["alive"], sm["n"],
				sm["cost"], roundi(float(sm["dealt"])), roundi(float(sm["taken"]))])
		var types: Dictionary = sm["types"]
		var ids := types.keys()
		ids.sort_custom(func(x: String, y: String) -> bool: return float(types[x]["dealt"]) > float(types[y]["dealt"]))
		for id: String in ids:
			var t: Dictionary = types[id]
			var dps := float(t["dealt"]) / maxf(0.1, float(t["alive_time"]) / maxf(1.0, float(t["n"])))
			rows.append("   %-16s %d/%d  dmg %5d  DPS %5.1f  taken %5d  kills %d" % [id, t["alive"], t["n"],
					roundi(float(t["dealt"])), dps, roundi(float(t["taken"])), t["kills"]])
	_meter.text = "\n".join(rows)


func _refresh_state() -> void:
	if _state == null:
		return
	_state.text = "%s   t %s   speed x%s   team %s   %s" % ["PAUSED" if paused else "RUNNING", _clock(),
			str(SPEEDS[speed_i]), "AB"[spawn_team], "rings: all" if show_all_rings else ""]


func _clock() -> String:
	return "%d:%04.1f" % [int(time) / 60, fmod(time, 60.0)]


func _on_log(t: String) -> void:
	if _log_box:
		_log_box.append_text(t + "\n")


func _exit_tree() -> void:
	Engine.time_scale = 1.0
	if get_tree():
		get_tree().paused = false
