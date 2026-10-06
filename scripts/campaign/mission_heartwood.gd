class_name MissionHeartwood
extends Building
## The Last Heartwood of mission e2m1 (docs/design/mission-e2-01.md "The Heartwood"): a young tree growing from the
## dead Oldroot's south root, a green seed-heart in its trunk. A Building of the PLAYER team so the enemy waves (which
## prefer units, then buildings) attack it once it is kindled; until then `invulnerable` and in the &"all" truce (the
## mission sets it: nothing targets it). `counts_for_defeat` false (the mission has its own lose rule). Kindled:
## `kindle()` (the Sap Ward aura of its BuildingType switches on, the frost decal melts). Placeholder look in code
## (E2M1.V1 replaces it): trunk, crown, pulsing seed-heart, frost disc that grows with `set_frost(0-1)`.

signal kindled

const HEART_COLOR := Color(0.55, 0.90, 0.35)
const FROST_COLOR := Color(0.80, 0.90, 1.00, 0.55)
const RADIUS := 2.0

## True until kindle(): no damage at all.
var invulnerable := true
var is_kindled := false     ## Read only.
var frost := 0.0            ## Read only: 0-1, the frost decal size.

var _look: Node3D
var _heart_mat: StandardMaterial3D
var _frost_mi: MeshInstance3D
var _pulse := 0.0


## The Heartwood's BuildingType (code-made): 2 x 2 cells, `hp` HP, the Sap Ward aura (`aura_stats` on own units
## within `aura_r` m once kindled: the mission switches aura_radius on at the kindle).
static func make_type(hp: float, aura_stats: Dictionary) -> BuildingType:
	var t := BuildingType.new()
	t.id = &"last_heartwood"
	t.display_name = "The Last Heartwood"
	t.faction = &"nature"
	t.kind = &"heartwood"
	t.max_hp = hp
	t.footprint = Vector2i(2, 2)
	t.height = 4.0
	t.sight_radius = 14.0
	t.counts_for_defeat = false
	t.color = HEART_COLOR
	t.body_color = Color(0.30, 0.22, 0.14)
	t.aura_radius = 0.0
	t.aura_stats = aura_stats
	t.aura_id = &"sap"
	return t


func _ready() -> void:
	super()
	if _visual:
		_visual.visible = false   # the generic placeholder box: the tree look below replaces it
	_build_tree_look()


func take_damage(amount: float, attacker: Node3D = null) -> void:
	if invulnerable:
		return
	super(amount, attacker)


## The kindle (E7): damageable from now on, the Sap Ward on, the frost melts (2 s).
func kindle(aura_radius: float) -> void:
	if is_kindled:
		return
	is_kindled = true
	invulnerable = false
	building_type.aura_radius = aura_radius
	set_frost(0.0, 2.0)
	kindled.emit()


## The frost decal: 0-1 of the glade's frost meter (tween over `seconds`).
func set_frost(f: float, seconds := 0.0) -> void:
	frost = clampf(f, 0.0, 1.0)
	if _frost_mi == null:
		return
	var s := maxf(0.01, 0.4 + frost * 2.6)
	if seconds > 0.0 and is_inside_tree():
		create_tween().tween_property(_frost_mi, "scale", Vector3(s, 1.0, s), seconds)
	else:
		_frost_mi.scale = Vector3(s, 1.0, s)
	_frost_mi.visible = frost > 0.0 or seconds > 0.0


func _process(delta: float) -> void:
	if _heart_mat == null or not is_alive():
		return
	_pulse += delta * (2.2 if is_kindled else 1.0)
	_heart_mat.emission_energy_multiplier = 1.5 + 1.2 * (0.5 + 0.5 * sin(_pulse * TAU * 0.5))


func _build_tree_look() -> void:
	_look = Node3D.new()
	_look.name = "HeartwoodLook"
	add_child(_look)
	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color(0.36, 0.26, 0.16)
	bark.roughness = 0.9
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.22
	trunk.bottom_radius = 0.45
	trunk.height = 3.2
	trunk.radial_segments = 8
	var tmi := MeshInstance3D.new()
	tmi.mesh = trunk
	tmi.material_override = bark
	tmi.position.y = 1.6
	_look.add_child(tmi)
	var leaf := StandardMaterial3D.new()
	leaf.albedo_color = Color(0.32, 0.62, 0.22)
	leaf.roughness = 0.8
	for c: Vector3 in [Vector3(0.0, 3.6, 0.0), Vector3(0.6, 3.2, 0.3), Vector3(-0.5, 3.3, -0.3)]:
		var crown := SphereMesh.new()
		crown.radius = 0.9
		crown.height = 1.4
		var cmi := MeshInstance3D.new()
		cmi.mesh = crown
		cmi.material_override = leaf
		cmi.position = c
		_look.add_child(cmi)
	var heart := SphereMesh.new()
	heart.radius = 0.32
	heart.height = 0.64
	_heart_mat = StandardMaterial3D.new()
	_heart_mat.albedo_color = HEART_COLOR
	_heart_mat.emission_enabled = true
	_heart_mat.emission = HEART_COLOR
	_heart_mat.emission_energy_multiplier = 2.0
	var hmi := MeshInstance3D.new()
	hmi.mesh = heart
	hmi.material_override = _heart_mat
	hmi.position = Vector3(0.0, 1.2, 0.35)
	_look.add_child(hmi)
	var disc := CylinderMesh.new()
	disc.top_radius = 1.0
	disc.bottom_radius = 1.0
	disc.height = 0.03
	disc.radial_segments = 32
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = FROST_COLOR
	fmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_frost_mi = MeshInstance3D.new()
	_frost_mi.name = "Frost"
	_frost_mi.mesh = disc
	_frost_mi.material_override = fmat
	_frost_mi.position.y = 0.04
	_look.add_child(_frost_mi)
	set_frost(frost)
