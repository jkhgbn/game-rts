class_name M04Look
extends Node3D
## Mission 4 placeholder looks built in code (docs/design/mission-04.md; the real art is 19.V1-V3, tech-artist): the
## Keystone Colossus, a Keystone Pylon and the heart-stone. Used as a Unit `model_scene` through `packed(kind)` (a
## PackedScene of this node), so the Unit calls the usual hooks: `set_moving`, `play_attack`, `play_hit`,
## `play_death` (+ signal `death_finished`). Extra hooks for the mission: `set_kneel(on)`, `set_glow(amount)` (the
## amber core: ward / Exposed), `set_cracked(on)`.

signal death_finished

const STONE := Color(0.36, 0.33, 0.30)
const STONE_DARK := Color(0.22, 0.20, 0.19)
const AMBER := Color(1.0, 0.62, 0.18)
const DEATH_TIME := 5.5

@export var kind: StringName = &"colossus"

var _core_mat: StandardMaterial3D
var _body: Node3D
var _arms: Array[Node3D] = []
var _glow := 1.0
var _t := 0.0
var _moving := 0.0
var _kneel := false
var _dying := false


static func packed(look_kind: StringName) -> PackedScene:
	var root := M04Look.new()
	root.kind = look_kind
	root.name = "M04Look_%s" % look_kind
	var ps := PackedScene.new()
	ps.pack(root)
	root.free()
	return ps


func _ready() -> void:
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)
	_core_mat = StandardMaterial3D.new()
	_core_mat.albedo_color = AMBER
	_core_mat.emission_enabled = true
	_core_mat.emission = AMBER
	_core_mat.emission_energy_multiplier = 2.5
	match kind:
		&"pylon":
			_build_pylon()
		&"heart_stone":
			_build_heart_stone()
		_:
			_build_colossus()


func _process(delta: float) -> void:
	_t += delta
	if _dying:
		return
	var pulse := 0.5 + 0.5 * sin(_t * TAU * (1.0 if kind == &"heart_stone" else 0.6))
	_core_mat.emission_energy_multiplier = (1.2 + 1.8 * pulse) * _glow
	if kind == &"colossus" and not _kneel and _moving > 0.05:
		_body.position.y = absf(sin(_t * 2.2)) * 0.25
		for i in _arms.size():
			_arms[i].rotation.x = sin(_t * 2.2 + PI * i) * 0.25


# ---------------------------------------------------------------- Unit model hooks

func set_moving(speed: float) -> void:
	_moving = speed


func play_attack() -> void:
	if kind != &"colossus" or _arms.is_empty() or _dying:
		return
	var arm := _arms[0]
	var tw := create_tween()
	tw.tween_property(arm, "rotation:x", -1.6, 0.35)
	tw.tween_property(arm, "rotation:x", 0.4, 0.2)
	tw.tween_property(arm, "rotation:x", 0.0, 0.4)


func play_hit() -> void:
	pass


func play_death() -> void:
	_dying = true
	var tw := create_tween()
	if kind == &"colossus":
		_core_mat.emission_energy_multiplier = 5.0
		tw.tween_property(_body, "rotation:x", -0.35, DEATH_TIME * 0.4)
		tw.parallel().tween_property(_core_mat, "emission_energy_multiplier", 0.3, DEATH_TIME)
		tw.tween_property(_body, "position:y", -9.0, DEATH_TIME * 0.6)
	else:
		tw.tween_property(_body, "scale", Vector3(1.3, 0.15, 1.3), 1.2)
		tw.parallel().tween_property(_core_mat, "emission_energy_multiplier", 0.0, 1.2)
	tw.tween_callback(func() -> void: death_finished.emit())


# ---------------------------------------------------------------- mission hooks

## Phase 3: the Colossus kneels where it stands (its chest comes down to reach height).
func set_kneel(on: bool) -> void:
	_kneel = on
	if kind != &"colossus":
		return
	var tw := create_tween()
	tw.tween_property(_body, "position:y", -3.2 if on else 0.0, 1.2)
	tw.parallel().tween_property(_body, "rotation:x", 0.25 if on else 0.0, 1.2)


## The amber core's brightness factor (1 = normal; 2.5 = Exposed; 0.4 = dim).
func set_glow(amount: float) -> void:
	_glow = amount


func set_cracked(on: bool) -> void:
	if kind == &"colossus" and _body.get_node_or_null(^"Crack"):
		(_body.get_node(^"Crack") as Node3D).visible = on


# ---------------------------------------------------------------- builders

func _stone(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.95
	return m


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = b
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _build_colossus() -> void:
	var stone := _stone(STONE)
	var dark := _stone(STONE_DARK)
	# Legs, hips, torso, head: a 12 m rubble giant (radius 3).
	_box(_body, Vector3(1.6, 4.6, 1.8), Vector3(-1.3, 2.3, 0.0), dark).rotation.z = 0.05
	_box(_body, Vector3(1.6, 4.6, 1.8), Vector3(1.3, 2.3, 0.0), dark).rotation.z = -0.05
	_box(_body, Vector3(4.2, 1.4, 2.4), Vector3(0.0, 5.0, 0.0), stone)
	_box(_body, Vector3(5.4, 4.2, 3.0), Vector3(0.0, 7.6, 0.0), stone)
	_box(_body, Vector3(6.6, 1.3, 3.2), Vector3(0.0, 9.9, 0.0), dark)
	var head := _box(_body, Vector3(1.8, 1.6, 1.8), Vector3(0.0, 11.2, 0.3), stone)
	var eye := _box(head, Vector3(1.2, 0.18, 0.1), Vector3(0.0, 0.1, 0.92), _core_mat)
	eye.name = "Eyes"
	for side in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.position = Vector3(3.6 * side, 9.6, 0.0)
		_body.add_child(pivot)
		_box(pivot, Vector3(1.5, 5.0, 1.5), Vector3(0.0, -2.6, 0.0), stone)
		_box(pivot, Vector3(2.0, 1.6, 2.0), Vector3(0.0, -5.4, 0.2), dark)
		_arms.append(pivot)
	# The heart: the amber core in the chest, cracks of light around it.
	var core := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.9
	sphere.height = 1.8
	core.mesh = sphere
	core.material_override = _core_mat
	core.position = Vector3(0.0, 8.0, 1.25)
	core.name = "Heart"
	_body.add_child(core)
	for i in 4:
		var vein := _box(_body, Vector3(0.18, 2.0, 0.1), Vector3(0.0, 8.0, 1.52), _core_mat)
		vein.rotation.z = 0.6 + i * 0.75
	var crack := _box(_body, Vector3(0.2, 3.2, 0.1), Vector3(-1.3, 2.6, 0.92), _core_mat)
	crack.name = "Crack"
	crack.visible = false
	if not _is_headless():
		var light := OmniLight3D.new()
		light.light_color = AMBER
		light.light_energy = 2.0
		light.omni_range = 9.0
		light.position = Vector3(0.0, 8.0, 2.5)
		_body.add_child(light)


func _build_pylon() -> void:
	var dark := _stone(STONE_DARK)
	var obelisk := CylinderMesh.new()
	obelisk.top_radius = 0.35
	obelisk.bottom_radius = 0.95
	obelisk.height = 5.0
	obelisk.radial_segments = 6
	var mi := MeshInstance3D.new()
	mi.mesh = obelisk
	mi.material_override = dark
	mi.position.y = 2.5
	_body.add_child(mi)
	_box(_body, Vector3(2.2, 0.5, 2.2), Vector3(0.0, 0.25, 0.0), _stone(STONE)).rotation.y = 0.4
	var core := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.45
	sphere.height = 0.9
	core.mesh = sphere
	core.material_override = _core_mat
	core.position.y = 3.4
	_body.add_child(core)
	for i in 3:
		var vein := _box(_body, Vector3(0.12, 3.6, 0.12), Vector3(0.0, 2.2, 0.0), _core_mat)
		vein.position = Vector3(cos(i * TAU / 3.0) * 0.62, 2.2, sin(i * TAU / 3.0) * 0.62)
		vein.rotation.y = i * TAU / 3.0


func _build_heart_stone() -> void:
	var stone := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.25
	sphere.height = 0.5
	stone.mesh = sphere
	stone.material_override = _core_mat
	stone.position.y = 0.25
	_body.add_child(stone)


static func _is_headless() -> bool:
	return DisplayServer.get_name() == "headless"
