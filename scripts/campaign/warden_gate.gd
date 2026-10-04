class_name WardenGate
extends StaticBody3D
## A Warden Gate (docs/design/mission-03.md "Warden Gate"; shared with mission 4, story-episode-1.md 19.V2 / 19.C6):
## a ruined arch, team NEUTRAL, groups "scripted" + "warden_gates" (never "units" / "buildings": no auto-aggro, never
## counts for defeat), attackable by everyone once `open()` played (closed = invulnerable). 1 800 HP, armor 20
## (Unit.armor_multiplier). Open: it spawns its Warden tide from `front_point()` (2 m in front, facing `face_toward`)
## through the `spawner` Callable (the mission's: (gate) -> void) every `tide_interval` s. Signal `gate_down(gate)`.
## Footprint 4 x 2 (the arch's feet), layer 1: add it under the NavigationRegion3D before the bake.
## Placeholder art (M3.V1 / 19.V2 replace it): two stone feet, a lintel, an amber crack glow when open.

signal gate_down(gate: WardenGate)
signal damaged(amount: float, attacker: Node3D)

const SIZE := Vector3(4.0, 4.5, 2.0)
const STONE := Color(0.50, 0.48, 0.46)
const CRACK := Color(1.0, 0.65, 0.2)

var team: int = Unit.Team.NEUTRAL
var gate_id: StringName = &""
var display_name := "Warden Gate"
var max_hp := 1800.0
var hp := 1800.0
var armor := 20.0
var tide_interval := 25.0
var face_toward := Vector3.ZERO
## (gate: WardenGate) -> void: spawns one tide (the mission's).
var spawner: Callable
## Read only.
var is_open := false
var tides := 0

var _dead := false
var _tide_left := 0.0
var _look: Node3D
var _crack_mat: StandardMaterial3D
var _bar_root: Node3D
var _bar_mat: ShaderMaterial


func _ready() -> void:
	add_to_group(&"scripted")
	add_to_group(&"warden_gates")
	set_meta(&"scripted", true)
	collision_layer = 1
	collision_mask = 0
	for side in [-1.0, 1.0]:   # the two feet are the colliders; the arch's middle stays walkable
		var col := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(1.0, SIZE.y, SIZE.z)
		col.shape = box
		col.position = Vector3(side * (SIZE.x * 0.5 - 0.5), SIZE.y * 0.5, 0.0)
		add_child(col)
	var to := face_toward - global_position
	to.y = 0.0
	if to.length() > 0.1:
		rotation.y = atan2(to.x, to.z)
	_build_look()


func setup(p_hp: float, p_interval: float) -> void:
	max_hp = p_hp
	hp = p_hp
	tide_interval = p_interval
	_update_bar()


func is_alive() -> bool:
	return not _dead and hp > 0.0


func target_radius() -> float:
	return 1.8


## 2 m in front of the arch, toward `face_toward`.
func front_point() -> Vector3:
	var to := face_toward - global_position
	to.y = 0.0
	return global_position + (to.normalized() * 2.0 if to.length() > 0.1 else Vector3(0.0, 0.0, 2.0))


func take_damage(amount: float, attacker: Node3D = null) -> void:
	if not is_open or not is_alive() or amount <= 0.0:
		return
	var dealt := amount * Unit.armor_multiplier(armor)
	hp = maxf(0.0, hp - dealt)
	damaged.emit(dealt, attacker)
	_update_bar()
	if hp <= 0.0:
		_dead = true
		is_open = false
		_crumble()
		gate_down.emit(self)


## Cracks open (1 s amber light) and starts the tide (the first one at once).
func open() -> void:
	if is_open or _dead:
		return
	is_open = true
	_tide_left = 0.0
	if _bar_root:
		_bar_root.visible = true
	if _crack_mat and is_inside_tree():
		var tw := create_tween()
		tw.tween_property(_crack_mat, "emission_energy_multiplier", 3.0, 1.0)


## Stops the tide without destroying the gate (the mission's end).
func close_tide() -> void:
	is_open = false


func _physics_process(delta: float) -> void:
	if not is_open or _dead:
		return
	_tide_left -= delta
	if _tide_left <= 0.0:
		_tide_left = tide_interval
		tides += 1
		if spawner.is_valid():
			spawner.call(self)


func _crumble() -> void:
	for c in get_children():
		if c is CollisionShape3D:
			(c as CollisionShape3D).disabled = true
	collision_layer = 0
	if _bar_root:
		_bar_root.visible = false
	if _look and is_inside_tree():
		var tw := create_tween()
		tw.tween_property(_look, "scale", Vector3(1.2, 0.15, 1.2), 0.8)
		tw.parallel().tween_property(_look, "position:y", -0.3, 0.8)


func _update_bar() -> void:
	if _bar_mat:
		_bar_mat.set_shader_parameter(&"ratio", clampf(hp / maxf(1.0, max_hp), 0.0, 1.0))


func _build_look() -> void:
	_look = Node3D.new()
	_look.name = "Look"
	add_child(_look)
	var stone := StandardMaterial3D.new()
	stone.albedo_color = STONE
	stone.roughness = 0.95
	for side in [-1.0, 1.0]:
		var foot := BoxMesh.new()
		foot.size = Vector3(1.0, SIZE.y, SIZE.z * 0.9)
		var mi := MeshInstance3D.new()
		mi.mesh = foot
		mi.material_override = stone
		mi.position = Vector3(side * (SIZE.x * 0.5 - 0.5), SIZE.y * 0.5, 0.0)
		_look.add_child(mi)
	var lintel := BoxMesh.new()
	lintel.size = Vector3(SIZE.x + 0.4, 0.8, SIZE.z)
	var top := MeshInstance3D.new()
	top.mesh = lintel
	top.material_override = stone
	top.position = Vector3(0.0, SIZE.y + 0.2, 0.0)
	top.rotation.z = 0.06   # ruined: a little askew
	_look.add_child(top)
	_crack_mat = StandardMaterial3D.new()
	_crack_mat.albedo_color = Color(0.2, 0.12, 0.05)
	_crack_mat.emission_enabled = true
	_crack_mat.emission = CRACK
	_crack_mat.emission_energy_multiplier = 0.0
	var crack := QuadMesh.new()
	crack.size = Vector2(SIZE.x - 2.0, SIZE.y - 0.3)
	var cmi := MeshInstance3D.new()
	cmi.mesh = crack
	cmi.material_override = _crack_mat
	cmi.position = Vector3(0.0, (SIZE.y - 0.3) * 0.5, 0.0)
	_look.add_child(cmi)
	_bar_root = Node3D.new()
	_bar_root.position = Vector3(0.0, SIZE.y + 1.4, 0.0)
	_bar_root.visible = false
	_look.add_child(_bar_root)
	var quad := QuadMesh.new()
	quad.size = Vector2(3.4, 0.3)
	var sh := Shader.new()
	sh.code = RootHeart.BAR_SHADER
	_bar_mat = ShaderMaterial.new()
	_bar_mat.shader = sh
	_bar_mat.set_shader_parameter(&"fill_color", Color(0.85, 0.6, 0.3))
	var bar := MeshInstance3D.new()
	bar.mesh = quad
	bar.material_override = _bar_mat
	bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_bar_root.add_child(bar)
	_update_bar()
