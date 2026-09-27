class_name Tower
extends Building
## Ember Spire / Night Spire: shoots the kingdom's archer bolt (Projectile) at enemies in range.
## Targeting and firing: BuildingGun (shared with the Keep). Only a finished tower shoots. Numbers: docs/design/buildings.md.
## Towers and keeps never pick an epic beast (group "beasts", map-fill.md 5.5): `BuildingGun.is_ignored`.

const BLINK_TIME := 0.1
const BODY_RADIUS := 0.9
const ORB_RADIUS := 0.25
const BOLT_SIZE := 0.14

## Read only: what the tower shoots at (the gun's target).
var attack_target: Node3D:
	get:
		return _gun.target if _gun else null

var _gun: BuildingGun
var _blink_left := 0.0
var _orb_mat: StandardMaterial3D


func _physics_process(delta: float) -> void:
	super(delta)
	if _dead or not is_constructed() or building_type == null:
		return
	if _blink_left > 0.0:
		_blink_left -= delta
		if _blink_left <= 0.0 and _orb_mat:
			_orb_mat.emission_energy_multiplier = 2.0
	if _gun == null:
		_gun = BuildingGun.new(self, building_type.height + ORB_RADIUS, BOLT_SIZE)
	if _gun.tick(delta):
		_blink_left = BLINK_TIME
		if _orb_mat:
			_orb_mat.emission_energy_multiplier = 8.0
		_call_model(&"play_shot")   # the art's orb blinks (art/buildings/fire_tower.gd)

# ---------------------------------------------------------------- look

func _body_size() -> Vector3:
	return Vector3(BODY_RADIUS * 2.0, building_type.height if building_type else 5.0, BODY_RADIUS * 2.0)


func _top_height() -> float:
	return maxf(_body_size().y + ORB_RADIUS * 2.0, _model_top())


## Cylinder radius 0.9, a 0.5 m emissive orb on top in the bolt colour (blinks on each shot).
func _build_shape() -> void:
	var h := _body_size().y
	var cyl := CylinderMesh.new()
	cyl.top_radius = BODY_RADIUS * 0.85
	cyl.bottom_radius = BODY_RADIUS
	cyl.height = h
	_add_mesh(cyl, building_type.body_color, h * 0.5)
	var sphere := SphereMesh.new()
	sphere.radius = ORB_RADIUS
	sphere.height = ORB_RADIUS * 2.0
	var orb := _add_mesh(sphere, building_type.projectile_color, h + ORB_RADIUS)
	_orb_mat = orb.material_override as StandardMaterial3D
	_orb_mat.emission_enabled = true
	_orb_mat.emission = building_type.projectile_color
	_orb_mat.emission_energy_multiplier = 2.0
	orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
