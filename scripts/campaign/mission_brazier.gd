class_name MissionBrazier
extends StaticBody3D
## A brazier of mission 1 (docs/design/mission-01.md "Brazier"): a 1.2 m wide, 1 m tall cold stone
## bowl. `lighter` (Vessa) standing within LIGHT_RADIUS for LIGHT_TIME seconds lights it (a progress
## ring grows on the ground; leaving the radius resets it, damage does not). A lit brazier stays lit:
## orange flame particles + a light. Group "braziers"; the minimap can draw minimap_flame_line().
## Add it under the NavigationRegion3D before the bake (the bowl is an obstacle, layer 1).

signal lit_up(brazier: MissionBrazier)

const LIGHT_RADIUS := 3.0
const LIGHT_TIME := 3.0
const COLD_COLOR := Color(0.35, 0.33, 0.3)
const FLAME_COLOR := Color(1.0, 0.5, 0.15)
const RING_COLOR := Color(1.0, 0.55, 0.15, 0.55)

@export var brazier_id: StringName = &""
@export var display_name := "Brazier"

var lit := false          ## Read only.
var progress := 0.0       ## Read only: 0-1 while Vessa stands close.
var lighter: Node3D = null   ## The only unit that can light it (the mission sets its hero).
var flame_target := Vector3.ZERO   ## Where the minimap flame line points (the crown).

var _ring: MeshInstance3D
var _ring_mat: StandardMaterial3D
var _flame: CPUParticles3D
var _light: OmniLight3D


func _ready() -> void:
	add_to_group("braziers")
	collision_layer = 1
	collision_mask = 0
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.6
	shape.height = 1.0
	col.shape = shape
	col.position.y = 0.5
	add_child(col)
	_build_look()


## The minimap line [from, to] (world positions) once lit, else [].
func minimap_flame_line() -> Array[Vector3]:
	if not lit:
		return []
	return [global_position, flame_target]


## Lights it now (scripts / tests). Emits lit_up once.
func light() -> void:
	if lit:
		return
	lit = true
	progress = 1.0
	_ring.visible = false
	_flame.emitting = true
	_flame.visible = true
	_light.visible = true
	lit_up.emit(self)


## Mission save row (MissionBase.register_actor): [lit: bool].
func save_row() -> Array:
	return [lit]


## QUIET load: a saved lit brazier burns again without lit_up (the mission's counters come from its own variables);
## a saved cold one is cold with no progress.
func load_row(row: Array) -> void:
	if row.is_empty():
		return
	progress = 0.0
	if bool(row[0]):
		lit = true
		progress = 1.0
	else:
		lit = false
	if _ring == null:
		return
	_ring.visible = false
	_flame.emitting = lit
	_flame.visible = lit
	_light.visible = lit


func _physics_process(delta: float) -> void:
	if lit:
		return
	var near := false
	if lighter != null and is_instance_valid(lighter) and lighter.is_inside_tree() \
			and (not lighter.has_method(&"is_alive") or bool(lighter.call(&"is_alive"))):
		var d := Vector2(lighter.global_position.x - global_position.x,
				lighter.global_position.z - global_position.z).length()
		near = d <= LIGHT_RADIUS
	if near:
		progress = minf(1.0, progress + delta / LIGHT_TIME)
	else:
		progress = 0.0
	_ring.visible = progress > 0.0
	if _ring.visible:
		var s := maxf(0.05, progress) * LIGHT_RADIUS
		_ring.scale = Vector3(s, 1.0, s)
	if progress >= 1.0:
		light()


func _build_look() -> void:
	var stone := StandardMaterial3D.new()
	stone.albedo_color = COLD_COLOR
	stone.roughness = 0.95
	var stem := CylinderMesh.new()
	stem.top_radius = 0.25
	stem.bottom_radius = 0.4
	stem.height = 0.6
	_add_mesh(stem, stone, 0.3)
	var bowl := CylinderMesh.new()
	bowl.top_radius = 0.6
	bowl.bottom_radius = 0.35
	bowl.height = 0.4
	_add_mesh(bowl, stone, 0.8)

	# Progress ring: a flat disc of radius 1 scaled to progress x LIGHT_RADIUS.
	var disc := CylinderMesh.new()
	disc.top_radius = 1.0
	disc.bottom_radius = 1.0
	disc.height = 0.02
	disc.radial_segments = 32
	_ring_mat = StandardMaterial3D.new()
	_ring_mat.albedo_color = RING_COLOR
	_ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring = _add_mesh(disc, _ring_mat, 0.03)
	_ring.visible = false

	_flame = CPUParticles3D.new()
	_flame.amount = 24
	_flame.lifetime = 0.8
	_flame.position.y = 1.0
	_flame.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_flame.emission_sphere_radius = 0.3
	_flame.direction = Vector3.UP
	_flame.spread = 15.0
	_flame.gravity = Vector3(0.0, 2.0, 0.0)
	_flame.initial_velocity_min = 0.5
	_flame.initial_velocity_max = 1.2
	_flame.scale_amount_min = 0.6
	_flame.scale_amount_max = 1.0
	var quad := SphereMesh.new()
	quad.radius = 0.12
	quad.height = 0.24
	quad.radial_segments = 6
	quad.rings = 3
	var fire_mat := StandardMaterial3D.new()
	fire_mat.albedo_color = FLAME_COLOR
	fire_mat.emission_enabled = true
	fire_mat.emission = FLAME_COLOR
	fire_mat.emission_energy_multiplier = 3.0
	fire_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	quad.material = fire_mat
	_flame.mesh = quad
	_flame.emitting = false
	_flame.visible = false
	add_child(_flame)

	_light = OmniLight3D.new()
	_light.light_color = FLAME_COLOR
	_light.light_energy = 2.0
	_light.omni_range = 8.0
	_light.position.y = 1.6
	_light.visible = false
	add_child(_light)


func _add_mesh(mesh: Mesh, mat: Material, y: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position.y = y
	add_child(mi)
	return mi
