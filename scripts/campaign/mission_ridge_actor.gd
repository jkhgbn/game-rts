class_name MissionRidgeActor
extends Node3D
## A story actor that stands somewhere and does nothing in gameplay (mission-02.md "Aldra on the ridge"): team
## NEUTRAL, invulnerable, untargetable, not in "units" / "buildings", group "scripted" and "minimap_markers" (the
## minimap may draw `minimap_color`), always drawn (not under the fog). `appear()` / `fade(seconds)`,
## `raise_weapon()` (staff up), `rune_lines(targets, seconds)` (glowing lines from the actor to each point;
## HelperVfx.play(&"aldra_sentinel", ...) when that VFX exists, else plain line meshes).
## Model: `model_scene` when set (TH.V3), else a 1.9 m glass-teal placeholder figure with a staff.

@export var model_scene: PackedScene
@export var actor_color := Color(0.62, 0.95, 0.88)

var team: int = Unit.Team.NEUTRAL
var minimap_color := Color(0.62, 0.95, 0.88)
var shown := false          ## Read only.

var _look: Node3D
var _staff: Node3D
var _mats: Array[StandardMaterial3D] = []


func _ready() -> void:
	add_to_group(&"scripted")
	add_to_group(&"minimap_markers")
	set_meta(&"scripted", true)
	visible = false
	if model_scene:
		_look = model_scene.instantiate() as Node3D
		add_child(_look)
	else:
		_build_placeholder()


func is_alive() -> bool:
	return false   # never a target


func appear() -> void:
	shown = true
	visible = true
	for m in _mats:
		m.albedo_color.a = 0.0
		var tw := create_tween()
		tw.tween_property(m, "albedo_color:a", 0.95, 0.6)


func fade(seconds := 1.0) -> void:
	if not shown:
		return
	shown = false
	if not is_inside_tree():
		visible = false
		return
	var tw := create_tween().set_parallel(true)
	for m in _mats:
		tw.tween_property(m, "albedo_color:a", 0.0, seconds)
	tw.chain().tween_callback(hide)


func raise_weapon() -> void:
	if _look and _look.has_method(&"play_gesture"):
		_look.call(&"play_gesture", &"raise_weapon")
	if _staff and is_inside_tree():
		var tw := create_tween()
		tw.tween_property(_staff, "rotation:z", -0.2, 0.3)
		tw.tween_property(_staff, "position:y", 1.6, 0.3)


## Glowing lines from the actor to every point of `targets`, visible `seconds` then fading.
func rune_lines(targets: Array, seconds := 1.5) -> void:
	if not is_inside_tree():
		return
	# TH.U2's HelperVfx.play(&"aldra_sentinel", ...) replaces these plain lines once it exists.
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(actor_color, 0.95)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = actor_color
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES, mat)
	var from := global_position + Vector3(0.0, 1.8, 0.0)
	for t: Variant in targets:
		var to: Vector3 = t if t is Vector3 else (t as Node3D).global_position
		var prev := from
		for k in range(1, 9):   # a slightly arched line
			var f := float(k) / 8.0
			var p := from.lerp(to + Vector3(0.0, 0.3, 0.0), f) + Vector3(0.0, sin(f * PI) * 3.0, 0.0)
			im.surface_add_vertex(prev)
			im.surface_add_vertex(p)
			prev = p
	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.top_level = true
	add_child(mi)
	mi.global_transform = Transform3D.IDENTITY
	var tw := mi.create_tween()
	tw.tween_interval(seconds)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.5)
	tw.tween_callback(mi.queue_free)


func _build_placeholder() -> void:
	_look = Node3D.new()
	_look.name = "Placeholder"
	add_child(_look)
	var body := CapsuleMesh.new()
	body.radius = 0.32
	body.height = 1.6
	_part(body, Vector3(0.0, 0.8, 0.0), Color(actor_color, 0.95))
	var head := SphereMesh.new()
	head.radius = 0.2
	head.height = 0.4
	_part(head, Vector3(0.0, 1.75, 0.0), Color(0.85, 0.98, 0.95, 0.95))
	var cloak := CylinderMesh.new()
	cloak.top_radius = 0.25
	cloak.bottom_radius = 0.55
	cloak.height = 1.2
	_part(cloak, Vector3(0.0, 0.6, 0.0), Color(0.30, 0.55, 0.55, 0.95))
	_staff = Node3D.new()
	_staff.position = Vector3(0.45, 1.1, 0.0)
	_look.add_child(_staff)
	var pole := CylinderMesh.new()
	pole.top_radius = 0.03
	pole.bottom_radius = 0.04
	pole.height = 2.0
	var pm := _part(pole, Vector3.ZERO, Color(0.75, 0.95, 0.92, 0.95))
	pm.reparent(_staff, false)
	var gem := SphereMesh.new()
	gem.radius = 0.1
	gem.height = 0.2
	var gm := _part(gem, Vector3(0.0, 1.05, 0.0), Color(actor_color, 0.95))
	gm.reparent(_staff, false)
	(gm.material_override as StandardMaterial3D).emission_enabled = true
	(gm.material_override as StandardMaterial3D).emission = actor_color
	(gm.material_override as StandardMaterial3D).emission_energy_multiplier = 2.0


func _part(mesh: Mesh, pos: Vector3, color: Color) -> MeshInstance3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.2
	m.rim_enabled = true
	_mats.append(m)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	_look.add_child(mi)
	return mi
