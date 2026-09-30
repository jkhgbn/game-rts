class_name RimeBulwark
extends StaticBody3D
## The Rimecarver's Rime Bulwark (docs/design/caster-units.md 5.2): an ice wall 4.0 m long, 0.9 m thick, 2.2 m high that
## stands 8 s and blocks the ground movement of BOTH teams. A StaticBody3D on physics layer 3 (Unit.CASTER_WALL_LAYER:
## ground units collide with it, flyers do not) plus a NavigationObstacle3D on avoidance layer 2 (ground agents slide
## along it); no navmesh rebake. Never blocks projectiles, spells, flyers or sight. Units in its footprint are pushed to the nearer long
## side when it rises. A titan, or a unit of pop >= 3 that presses on it for 1.0 s, shatters it. Max 4 per team (the
## oldest melts: CasterAbility). Local x = the long axis. The look is UnitVfx `rime_bulwark` (it follows this node); a
## plain translucent box is added only when no UnitVfx is in the level.

signal finished(wall: RimeBulwark, how: StringName)

const TICK := 0.1

var team := 0
var length := 4.0
var thickness := 0.9
var height := 2.2
var lifetime := 8.0
var shatter_pop := 3
var shatter_time := 1.0
## True once it melted or shattered (the registry drops it; the node frees itself a moment later).
var ended := false
## Read only: how it ended (&"melt" / &"shatter"), &"" while standing.
var end_reason: StringName = &""

var _left := 0.0
var _tick_left := 0.0
var _contact := {}   # instance id -> seconds a big unit pressed on it
var _vfx_shown := false


## A new wall centred at `center` (ground), its long axis perpendicular to `facing` (caster -> point). Returns it (in
## the tree, under `parent`).
static func spawn(parent: Node, center: Vector3, facing: Vector3, owner_team: int, data: Dictionary) -> RimeBulwark:
	var w := RimeBulwark.new()
	w.name = "RimeBulwark"
	w.team = owner_team
	w.length = float(data.get("length", 4.0))
	w.thickness = float(data.get("thick", 0.9))
	w.height = float(data.get("height", 2.2))
	w.lifetime = float(data.get("time", 8.0))
	w.shatter_pop = int(data.get("shatter_pop", 3))
	w.shatter_time = float(data.get("shatter_time", 1.0))
	var f := Vector3(facing.x, 0.0, facing.z)
	if f.length() < 0.01:
		f = Vector3(0, 0, 1)
	f = f.normalized()
	var x_axis := Vector3(-f.z, 0.0, f.x)   # perpendicular to the caster -> point line
	var b := Basis(x_axis, Vector3.UP, x_axis.cross(Vector3.UP))
	var xf := Transform3D(b, Vector3(center.x, 0.0, center.z))
	var p3 := parent as Node3D
	w.transform = p3.global_transform.affine_inverse() * xf if p3 and p3.is_inside_tree() else xf   # set before _ready
	parent.add_child(w, true)
	w.global_transform = xf
	return w


func _ready() -> void:
	add_to_group(&"rime_bulwarks")
	collision_layer = Unit.CASTER_WALL_LAYER   # layer 3: ground units only (never flyers, clicks or build checks)
	collision_mask = 0
	_left = lifetime
	var shape := BoxShape3D.new()
	shape.size = Vector3(length, height, thickness)
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position.y = height * 0.5
	add_child(col)
	var obstacle := NavigationObstacle3D.new()
	obstacle.name = "Obstacle"
	var hx := length * 0.5
	var hz := thickness * 0.5
	obstacle.vertices = PackedVector3Array([Vector3(-hx, 0, -hz), Vector3(hx, 0, -hz), Vector3(hx, 0, hz),
			Vector3(-hx, 0, hz)])
	obstacle.height = height
	obstacle.avoidance_enabled = true
	obstacle.avoidance_layers = Unit.CASTER_WALL_AVOIDANCE
	add_child(obstacle)
	_push_units_out()
	var vfx := get_tree().get_first_node_in_group(&"unit_vfx")
	if vfx and vfx.has_method(&"has_effect") and bool(vfx.call(&"has_effect", &"rime_bulwark")):
		_vfx_shown = true
	else:
		_add_fallback_look()


## Plays the rise look (the caster = the frost crack's start).
func play_rise(caster: Node3D) -> void:
	var vfx := get_tree().get_first_node_in_group(&"unit_vfx") if is_inside_tree() else null
	if vfx:
		vfx.call(&"play", &"rime_bulwark", self, {"from": caster, "time": lifetime, "team": team})


func _physics_process(delta: float) -> void:
	if ended:
		return
	_left -= delta
	if _left <= 0.0:
		finish(&"melt")
		return
	_tick_left -= delta
	if _tick_left > 0.0:
		return
	_tick_left = TICK
	_check_shatter()


## Seconds left standing.
func time_left() -> float:
	return maxf(0.0, _left)


## True when world point `p` (+ `margin` m) is inside the footprint.
func contains(p: Vector3, margin: float = 0.0) -> bool:
	if ended or not is_inside_tree():
		return false
	var local := global_transform.affine_inverse() * Vector3(p.x, global_position.y, p.z)
	return absf(local.x) <= length * 0.5 + margin and absf(local.z) <= thickness * 0.5 + margin


## Ends the wall: &"melt" (time out, the oldest of 5) or &"shatter" (a big unit / titan broke it).
func finish(how: StringName) -> void:
	if ended:
		return
	ended = true
	end_reason = how
	collision_layer = 0
	var obstacle := get_node_or_null(^"Obstacle") as NavigationObstacle3D
	if obstacle:
		obstacle.avoidance_enabled = false
	var vfx := get_tree().get_first_node_in_group(&"unit_vfx") if is_inside_tree() else null
	if vfx and _vfx_shown:
		vfx.call(&"play", &"rime_bulwark_shatter" if how == &"shatter" else &"rime_bulwark_melt", global_position)
	finished.emit(self, how)
	if is_inside_tree():
		get_tree().create_timer(0.6, false).timeout.connect(queue_free)
	else:
		queue_free()


# A titan or a unit of pop >= 3 touching the wall for 1.0 s (cumulated while it keeps touching) shatters it.
func _check_shatter() -> void:
	var seen := {}
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or not u.is_alive() or u.unit_type == null:
			continue
		if not CasterKit.is_titan(u) and u.unit_type.pop < shatter_pop:
			continue
		if not contains(u.global_position, u.radius + 0.25):
			continue
		var key := u.get_instance_id()
		seen[key] = true
		_contact[key] = float(_contact.get(key, 0.0)) + TICK
		if float(_contact[key]) >= shatter_time - 0.001:
			finish(&"shatter")
			return
	for key: Variant in _contact.keys():
		if not seen.has(key):
			_contact.erase(key)


# Units standing in the footprint when it rises step out to the nearer long side.
func _push_units_out() -> void:
	var inv := global_transform.affine_inverse()
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or not u.is_alive():
			continue
		var local := inv * Vector3(u.global_position.x, global_position.y, u.global_position.z)
		var hz := thickness * 0.5 + u.radius
		if absf(local.x) > length * 0.5 + u.radius * 0.5 or absf(local.z) >= hz:
			continue
		local.z = (hz + 0.05) * (1.0 if local.z >= 0.0 else -1.0)
		var world := global_transform * local
		u.global_position = Vector3(world.x, u.global_position.y, world.z)


func _add_fallback_look() -> void:
	var m := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(length, height, thickness)
	m.mesh = box
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.45, 0.62, 0.85, 0.7)
	m.material_override = mat
	m.position.y = height * 0.5
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
