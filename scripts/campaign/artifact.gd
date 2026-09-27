class_name Artifact
extends Node3D
## One of the God Wizard's lost artifacts. The first wizard hero to reach it claims its power.

signal claimed(artifact: Artifact, by: Wizard)

const CROWN_MESH_PATH := "res://art/environment/crown/ember_crown_mesh.res"

@export var artifact_name := "Ember Crown"
@export var pickup_radius := 2.2
@export var bonus_mana := 50.0
@export var bonus_fireball_damage := 30.0
@export var glow_color := Color(1.0, 0.8, 0.3)

var _gem: MeshInstance3D
var _pedestal: MeshInstance3D
var _pedestal_runes: MeshInstance3D   # the pedestal art's glowing rune ring (null without the art)
var _rune_tint_mat: ShaderMaterial

const PEDESTAL_ART_PATH := "res://art/environment/crown_pedestal.tscn"


## Recolours the pedestal art's runes (`on`) or restores their own ember glow.
func _tint_pedestal_runes(on: bool, color: Color) -> void:
	if _pedestal_runes == null:
		return
	if not on:
		_pedestal_runes.material_override = null
		return
	if _rune_tint_mat == null:
		var base := _pedestal_runes.get_active_material(0) as ShaderMaterial
		if base == null:
			return
		_rune_tint_mat = base.duplicate() as ShaderMaterial
		_rune_tint_mat.set_shader_parameter(&"glow_color", color)
		_rune_tint_mat.set_shader_parameter(&"core_color", color.lightened(0.4))
		_rune_tint_mat.set_shader_parameter(&"energy", 3.5)
	_pedestal_runes.material_override = _rune_tint_mat
var _time := 0.0
var _taken := false


func _ready() -> void:
	var pedestal := MeshInstance3D.new()
	_pedestal = pedestal
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.7
	cyl.bottom_radius = 0.9
	cyl.height = 0.8
	pedestal.mesh = cyl
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.45, 0.43, 0.5)
	pedestal.material_override = stone
	pedestal.position.y = 0.4
	add_child(pedestal)
	if ResourceLoader.exists(PEDESTAL_ART_PATH):
		var art := (load(PEDESTAL_ART_PATH) as PackedScene).instantiate() as Node3D
		if art:   # the carved pedestal replaces the cylinder (same 0.8 m height, gem still at 1.8)
			pedestal.mesh = null
			pedestal.position.y = 0.0
			pedestal.add_child(art)
			_pedestal_runes = art.get_node_or_null(^"Runes") as MeshInstance3D

	_gem = MeshInstance3D.new()
	var sphere := SphereMesh.new()   # few segments = chunky, faceted gem
	sphere.radius = 0.45
	sphere.height = 1.2
	sphere.radial_segments = 6
	sphere.rings = 2
	_gem.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = glow_color
	mat.emission_enabled = true
	mat.emission = glow_color
	mat.emission_energy_multiplier = 2.5
	mat.metallic = 0.6
	_gem.material_override = mat
	_gem.position.y = 1.8
	add_child(_gem)
	var crown_look := artifact_name == "Ember Crown" and ResourceLoader.exists(CROWN_MESH_PATH)
	if crown_look:   # A2.3: the gold crown model (own gold and ember materials)
		_gem.mesh = load(CROWN_MESH_PATH) as Mesh
		_gem.material_override = null

	var light := OmniLight3D.new()
	light.light_color = glow_color
	light.omni_range = 6.0 if crown_look else 7.0
	light.light_energy = 0.8 if crown_look else 2.0   # at 2.0 the light blows out the crown model
	light.position.y = 2.0
	add_child(light)


func _process(delta: float) -> void:
	if _taken:
		return
	_time += delta
	_gem.rotation.y += delta * 1.5
	_gem.position.y = 1.8 + sin(_time * 2.0) * 0.15
	for node in get_tree().get_nodes_in_group("heroes"):
		var hero := node as Wizard
		if hero == null or not hero.is_alive():
			continue
		var d := Vector2(hero.global_position.x - global_position.x,
				hero.global_position.z - global_position.z).length()
		if d <= pickup_radius:
			_claim(hero)
			return


func _claim(hero: Wizard) -> void:
	_taken = true
	hero.claim_artifact(artifact_name, bonus_mana, bonus_fireball_damage)
	claimed.emit(self, hero)
	var tween := create_tween()
	tween.tween_property(_gem, "position:y", 5.0, 0.8)
	tween.parallel().tween_property(_gem, "scale", Vector3.ZERO, 0.8)
