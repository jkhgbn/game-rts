class_name Heartfrost
extends StaticBody3D
## The Heartfrost of mission 2 (docs/design/mission-02.md "The Heartfrost and Malrik's dig"): Torvald's old ice
## monolith over the Stillwater Orb. A static NEUTRAL target, radius 1.5, group "scripted" (never "units" /
## "buildings": no auto-aggro, never counts for defeat). Only the player's wizard (`melter_hero`: attacks and the
## spells the mission forwards) and the player's Ash Hurlers damage it; everything else is ignored (Shadow units never
## damage or heal it). It regenerates `regen_per_second` once `REGEN_DELAY` s passed since the last Fire damage.
## Add it under the NavigationRegion3D before the bake (the ice is an obstacle, layer 1); `burst()` removes the
## collider (the mission rebakes) and plays the shatter. Placeholder art (M9.V1): 5 hex prisms + the orb inside, the
## ice shrinks from 100 % to 40 % height with HP; a billboard HP bar like a building's.

signal damaged(amount: float, attacker: Node3D)
signal melted(heartfrost: Heartfrost)

const RADIUS := 1.5
const REGEN_DELAY := 5.0
const ICE_COLOR := Color(0.70, 0.88, 1.00, 0.6)
const ORB_COLOR := Color(0.60, 0.90, 1.00)
const MIN_HEIGHT := 0.4
const BAR_SHADER := """shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled;
uniform float ratio = 1.0;
uniform vec4 fill_color : source_color = vec4(0.55, 0.88, 1.0, 1.0);
uniform vec4 back_color : source_color = vec4(0.05, 0.05, 0.08, 0.85);
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}
void fragment() {
	bool edge = UV.y < 0.15 || UV.y > 0.85 || UV.x < 0.01 || UV.x > 0.99;
	vec4 c = (!edge && UV.x <= ratio) ? fill_color : back_color;
	ALBEDO = c.rgb;
	ALPHA = c.a;
}
"""
## Hex prisms [x, z, radius, height] (the tallest r 1.2 h 5).
const PRISMS := [[0.0, 0.0, 1.2, 5.0], [0.9, 0.5, 0.6, 3.2], [-0.8, 0.6, 0.55, 2.6], [0.3, -0.9, 0.5, 2.9],
		[-0.6, -0.7, 0.45, 2.1]]

var team: int = Unit.Team.NEUTRAL
var max_hp := 1500.0
var hp := 1500.0
var regen_per_second := 15.0
## The only wizard whose damage counts (the mission sets its hero).
var melter_hero: Node3D = null
## Read only: seconds since the last accepted damage (INF = never hit).
var since_fire_damage := INF
var is_melted := false
## Mission-set rush floor (m02, campaign notes 2026-10-11): damage never takes hp below this (0 = off).
var hp_floor := 0.0

var _ice: Node3D
var _orb: MeshInstance3D
var _bar_fill: MeshInstance3D
var _bar_root: Node3D
var _bar_mat: ShaderMaterial
var _col: CollisionShape3D


func _ready() -> void:
	add_to_group(&"scripted")
	add_to_group(&"heartfrost")
	set_meta(&"scripted", true)
	collision_layer = 1
	collision_mask = 0
	_col = CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = RADIUS
	shape.height = 4.0
	_col.shape = shape
	_col.position.y = 2.0
	add_child(_col)
	_build_look()
	_update_look()


func is_alive() -> bool:
	return not is_melted and hp > 0.0


func target_radius() -> float:
	return RADIUS


## Fraction melted (0 full ice, 1 gone): the objective's percent.
func melted_ratio() -> float:
	return clampf(1.0 - hp / maxf(1.0, max_hp), 0.0, 1.0)


## True when `attacker` may damage it: the hero, or a PLAYER Ash Hurler.
func accepts_damage_from(attacker: Node3D) -> bool:
	if attacker == null or not is_instance_valid(attacker):
		return false
	if melter_hero != null and attacker == melter_hero:
		return true
	var u := attacker as Unit
	return u != null and int(u.team) == Unit.Team.PLAYER and u.unit_type != null and u.unit_type.id == &"ash_hurler"


func take_damage(amount: float, attacker: Node3D = null) -> void:
	if not is_alive() or amount <= 0.0 or not accepts_damage_from(attacker):
		return
	hp = maxf(minf(hp_floor, hp), hp - amount)   # the rush floor holds (never heals what is already below it)
	since_fire_damage = 0.0
	damaged.emit(amount, attacker)
	_update_look()
	if hp <= 0.0:
		is_melted = true
		melted.emit(self)


func _physics_process(delta: float) -> void:
	if is_melted:
		return
	since_fire_damage += delta
	if since_fire_damage >= REGEN_DELAY and hp < max_hp:
		hp = minf(max_hp, hp + regen_per_second * delta)
		_update_look()


## Sets HP and max HP (difficulty table) before or after _ready.
func setup(p_max_hp: float, p_regen: float) -> void:
	max_hp = p_max_hp
	hp = p_max_hp
	regen_per_second = p_regen
	if is_inside_tree():
		_update_look()


## E10: the ice is gone (collider off; the mission rebakes), the shards fly, the orb stays at its spot.
func burst() -> void:
	is_melted = true
	hp = 0.0
	if _col:
		_col.disabled = true
	collision_layer = 0
	if _bar_root:
		_bar_root.visible = false
	if _ice and is_inside_tree():
		var tw := create_tween()
		tw.tween_property(_ice, "scale", Vector3(1.6, 0.05, 1.6), 0.5)
		tw.tween_callback(_ice.hide)
	_spawn_shards()


func orb_node() -> MeshInstance3D:
	return _orb


# ---------------------------------------------------------------- look (placeholder, M9.V1)

func _build_look() -> void:
	_ice = Node3D.new()
	_ice.name = "Ice"
	add_child(_ice)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = ICE_COLOR
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.15
	mat.metallic = 0.1
	mat.rim_enabled = true
	mat.rim = 0.6
	mat.emission_enabled = true
	mat.emission = Color(0.35, 0.55, 0.75)
	mat.emission_energy_multiplier = 0.4
	for p: Array in PRISMS:
		var cyl := CylinderMesh.new()
		cyl.radial_segments = 6
		cyl.rings = 1
		cyl.top_radius = float(p[2]) * 0.75
		cyl.bottom_radius = float(p[2])
		cyl.height = float(p[3])
		var mi := MeshInstance3D.new()
		mi.mesh = cyl
		mi.material_override = mat
		mi.position = Vector3(float(p[0]), float(p[3]) * 0.5, float(p[1]))
		mi.rotation.y = float(p[0]) * 1.7
		_ice.add_child(mi)
	var orb := SphereMesh.new()
	orb.radius = 0.4
	orb.height = 0.8
	var omat := StandardMaterial3D.new()
	omat.albedo_color = ORB_COLOR
	omat.emission_enabled = true
	omat.emission = ORB_COLOR
	omat.emission_energy_multiplier = 3.0
	_orb = MeshInstance3D.new()
	_orb.name = "Orb"
	_orb.mesh = orb
	_orb.material_override = omat
	_orb.position = Vector3(0.0, 1.0, 0.0)
	add_child(_orb)
	# HP bar (billboard), a building's look: dark back + ice-blue fill (one quad, the fill drawn by the shader).
	_bar_root = Node3D.new()
	_bar_root.position = Vector3(0.0, 5.8, 0.0)
	add_child(_bar_root)
	var quad := QuadMesh.new()
	quad.size = Vector2(3.0, 0.3)
	var sh := Shader.new()
	sh.code = BAR_SHADER
	_bar_mat = ShaderMaterial.new()
	_bar_mat.shader = sh
	_bar_fill = MeshInstance3D.new()
	_bar_fill.mesh = quad
	_bar_fill.material_override = _bar_mat
	_bar_fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_bar_root.add_child(_bar_fill)


func _update_look() -> void:
	if _ice == null:
		return
	var f := clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
	_ice.scale = Vector3(1.0, lerpf(MIN_HEIGHT, 1.0, f), 1.0)
	if _bar_mat:
		_bar_mat.set_shader_parameter(&"ratio", f)


func _spawn_shards() -> void:
	if not is_inside_tree():
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.93, 1.0, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for i in 16:
		var box := BoxMesh.new()
		box.size = Vector3(0.35, 0.5, 0.25) * randf_range(0.6, 1.4)
		var mi := MeshInstance3D.new()
		mi.mesh = box
		mi.material_override = mat
		add_child(mi)
		mi.position = Vector3(0.0, randf_range(0.5, 3.0), 0.0)
		var a := float(i) * TAU / 16.0
		var to := Vector3(cos(a), 0.0, sin(a)) * randf_range(3.0, 7.0)
		var tw := mi.create_tween()
		tw.tween_property(mi, "position", to + Vector3(0.0, 0.1, 0.0), 0.7).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(mi, "rotation", Vector3(randf() * 4.0, randf() * 4.0, 0.0), 0.7)
		tw.tween_interval(2.0)
		tw.tween_property(mi, "scale", Vector3.ONE * 0.01, 1.0)
		tw.tween_callback(mi.queue_free)
