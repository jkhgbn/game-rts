class_name RootHeart
extends StaticBody3D
## A Root Heart of mission 3 (docs/design/mission-03.md "Root Heart"): a pulsing seed-pod 2.4 m tall in a root cradle,
## radius 1.4, team NEUTRAL, groups "scripted" + "root_hearts" (never "units" / "buildings": no auto-aggro, never
## counts for defeat). Anyone damages it (right-click attack by Fire units, Vessa's spells, Shadow's drain: the
## mission calls `drain(amount, thrall)`). 900 HP, regen 1 % / s (9 HP/s) after 10 s without damage. On death
## `destroyed_by` = the team of the killing blow, the pod bursts (green spores), signal `heart_down(heart, team)`.
## Hidden until its spot is explored by the player (FogOfWar), then shown (the ghost rule, simplified: it stays drawn).
## Add it under the NavigationRegion3D before the bake (the cradle is an obstacle); `burst()` removes the collider.
## Placeholder art (M3.V1 replaces it): root cradle, pod, drain tint toward grey-violet, a billboard HP bar.

signal damaged(amount: float, attacker: Node3D)
signal heart_down(heart: RootHeart, team: int)

const RADIUS := 1.4
const HEIGHT := 2.4
const MAX_HP := 900.0
const REGEN_PCT := 0.01          ## Of max HP per second.
const REGEN_DELAY := 10.0
const POD_COLOR := Color(0.35, 0.85, 0.30)
const DRAINED_COLOR := Color(0.55, 0.45, 0.65)
const ROOT_COLOR := Color(0.32, 0.22, 0.14)
const BAR_SHADER := """shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled;
uniform float ratio = 1.0;
uniform vec4 fill_color : source_color = vec4(0.45, 0.9, 0.35, 1.0);
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

var team: int = Unit.Team.NEUTRAL
var heart_id: StringName = &""
var display_name := "Root Heart"
var max_hp := MAX_HP
var hp := MAX_HP
## Read only: seconds since the last damage (INF = never hit).
var since_damage := INF
## Read only: the team of the killing blow (-1 while alive).
var destroyed_by := -1
## Read only: HP taken by drains (the grey-violet tint).
var drained := 0.0
## Read only: true once the player has explored its spot (the mission's E4).
var discovered := false

var _dead := false
var _pod: MeshInstance3D
var _pod_mat: StandardMaterial3D
var _look: Node3D
var _bar_root: Node3D
var _bar_mat: ShaderMaterial
var _col: CollisionShape3D
var _fog_left := 0.0
var _pulse := 0.0


func _ready() -> void:
	add_to_group(&"scripted")
	add_to_group(&"root_hearts")
	set_meta(&"scripted", true)
	collision_layer = 1
	collision_mask = 0
	_col = CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = RADIUS
	shape.height = HEIGHT
	_col.shape = shape
	_col.position.y = HEIGHT * 0.5
	add_child(_col)
	_build_look()
	_update_look()


func is_alive() -> bool:
	return not _dead and hp > 0.0


func target_radius() -> float:
	return RADIUS


## Damage from anything (a unit, a spell the mission forwards). The killing blow decides the credit.
func take_damage(amount: float, attacker: Node3D = null) -> void:
	if not is_alive() or amount <= 0.0:
		return
	hp = maxf(0.0, hp - amount)
	since_damage = 0.0
	damaged.emit(amount, attacker)
	_update_look()
	if hp <= 0.0:
		var t := -1
		if attacker != null and is_instance_valid(attacker) and &"team" in attacker:
			t = int(attacker.get(&"team"))
		_die(t)


## A Gloom Thrall's channel (4 HP/s, the mission sends amount = 4 x delta): same as damage, tinted.
func drain(amount: float, thrall: Node3D) -> void:
	if not is_alive():
		return
	drained += amount
	take_damage(amount, thrall)


func _physics_process(delta: float) -> void:
	if _dead:
		return
	since_damage += delta
	if since_damage >= REGEN_DELAY and hp < max_hp:
		hp = minf(max_hp, hp + max_hp * REGEN_PCT * delta)
		drained = maxf(0.0, drained - max_hp * REGEN_PCT * delta)
		_update_look()
	_pulse += delta
	if _pod:
		var s := 1.0 + 0.05 * sin(_pulse * TAU * 0.8)
		_pod.scale = Vector3(s, s * 1.15, s)
	_fog_left -= delta
	if _fog_left <= 0.0:
		_fog_left = 0.25
		_check_fog()


func _check_fog() -> void:
	if discovered:
		return
	var fog := FogOfWar.find() if is_inside_tree() else null
	if fog == null or fog.is_explored(Unit.Team.PLAYER, global_position):
		discovered = true
		if _look:
			_look.visible = true


func _die(by_team: int) -> void:
	_dead = true
	hp = 0.0
	destroyed_by = by_team
	burst()
	heart_down.emit(self, by_team)


## Mission save row (MissionBase.register_actor): [hp: float, destroyed_by: int (-1 alive), drained: float,
## discovered: bool].
func save_row() -> Array:
	return [hp, destroyed_by, drained, discovered]


## QUIET load: HP / drain tint / discovered back; a saved dead heart is removed quietly (no heart_down, no spores:
## pod hidden, collider off; the mission rebakes its navmesh).
func load_row(row: Array) -> void:
	if row.size() < 4:
		return
	destroyed_by = int(row[1])
	drained = float(row[2])
	discovered = bool(row[3])
	if _look and discovered:
		_look.visible = true
	if float(row[0]) <= 0.0:
		if _look:
			_look.visible = true   # burst() shows a dead heart's cradle (explored or not)
		_dead = true
		hp = 0.0
		if _col:
			_col.disabled = true
		collision_layer = 0
		if _bar_root:
			_bar_root.visible = false
		if _pod:
			_pod.hide()
		return
	hp = clampf(float(row[0]), 1.0, max_hp)
	since_damage = 0.0
	_update_look()


## The pod bursts (spores), the collider goes (the mission rebakes). Idempotent.
func burst() -> void:
	_dead = true
	hp = 0.0
	if _col:
		_col.disabled = true
	collision_layer = 0
	if _bar_root:
		_bar_root.visible = false
	if _look:
		_look.visible = true
	if _pod and is_inside_tree():
		var tw := create_tween()
		tw.tween_property(_pod, "scale", Vector3(1.5, 0.1, 1.5), 0.4)
		tw.tween_callback(_pod.hide)
		_spawn_spores()


# ---------------------------------------------------------------- look (placeholder, M3.V1)

func _build_look() -> void:
	_look = Node3D.new()
	_look.name = "Look"
	add_child(_look)
	var root_mat := StandardMaterial3D.new()
	root_mat.albedo_color = ROOT_COLOR
	root_mat.roughness = 0.95
	for i in 6:   # the root cradle: six arched roots around the pod
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.12
		cyl.bottom_radius = 0.3
		cyl.height = 2.2
		cyl.radial_segments = 6
		var mi := MeshInstance3D.new()
		mi.mesh = cyl
		mi.material_override = root_mat
		var a := float(i) * TAU / 6.0
		mi.position = Vector3(cos(a) * 1.0, 0.8, sin(a) * 1.0)
		mi.rotation = Vector3(0.0, -a, 0.0)
		mi.rotate_object_local(Vector3.FORWARD, 0.45)
		_look.add_child(mi)
	var pod := SphereMesh.new()
	pod.radius = 0.85
	pod.height = 1.9
	pod.radial_segments = 16
	pod.rings = 8
	_pod_mat = StandardMaterial3D.new()
	_pod_mat.albedo_color = POD_COLOR
	_pod_mat.emission_enabled = true
	_pod_mat.emission = POD_COLOR
	_pod_mat.emission_energy_multiplier = 0.9
	_pod_mat.roughness = 0.5
	_pod = MeshInstance3D.new()
	_pod.name = "Pod"
	_pod.mesh = pod
	_pod.material_override = _pod_mat
	_pod.position = Vector3(0.0, 1.35, 0.0)
	_look.add_child(_pod)
	_bar_root = Node3D.new()
	_bar_root.position = Vector3(0.0, HEIGHT + 0.9, 0.0)
	_look.add_child(_bar_root)
	var quad := QuadMesh.new()
	quad.size = Vector2(2.6, 0.28)
	var sh := Shader.new()
	sh.code = BAR_SHADER
	_bar_mat = ShaderMaterial.new()
	_bar_mat.shader = sh
	var bar := MeshInstance3D.new()
	bar.mesh = quad
	bar.material_override = _bar_mat
	bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_bar_root.add_child(bar)
	_look.visible = false   # until explored (_check_fog)


func _update_look() -> void:
	var f := clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
	if _bar_mat:
		_bar_mat.set_shader_parameter(&"ratio", f)
	if _pod_mat:
		var d := clampf(drained / maxf(1.0, max_hp * 0.6), 0.0, 1.0)
		var c := POD_COLOR.lerp(DRAINED_COLOR, d)
		_pod_mat.albedo_color = c
		_pod_mat.emission = c


func _spawn_spores() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 1.0, 0.45, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.5, 0.95, 0.35)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in 18:
		var s := SphereMesh.new()
		s.radius = 0.12
		s.height = 0.24
		s.radial_segments = 6
		s.rings = 3
		var mi := MeshInstance3D.new()
		mi.mesh = s
		mi.material_override = mat
		add_child(mi)
		mi.position = Vector3(0.0, 1.4, 0.0)
		var a := float(i) * TAU / 18.0
		var to := Vector3(cos(a) * randf_range(1.5, 4.0), randf_range(1.0, 3.5), sin(a) * randf_range(1.5, 4.0))
		var tw := mi.create_tween()
		tw.tween_property(mi, "position", to, 1.2).set_ease(Tween.EASE_OUT)
		tw.tween_property(mi, "scale", Vector3.ONE * 0.01, 1.0)
		tw.tween_callback(mi.queue_free)
