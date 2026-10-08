class_name MissionTree
extends Building
## The Master's golden tree of mission e4m1 (docs/design/mission-e4-01.md D4): a Building of the PLAYER team that the
## Final wave and Hush's raid attack (3 000 HP, armor 20, building idle regen), the centre of the refuge ring. The
## same tree e3m1 shows as decor (MissionE3_01.add_golden_tree). `counts_for_defeat` false: the mission owns the loss
## rule (obj_tree). Placeholder look in code (E4M1.V1 replaces it): trunk, golden crown whose glow dims and whose
## leaves thin with the HP (never "dead" before 0 HP), the refuge ring decal (r 8).

const GOLD := Color(1.0, 0.82, 0.3)
const RADIUS := 2.0
const _SIM := preload("res://scripts/core/sim_mode.gd")

var refuge_radius := 8.0
var armor := 20.0          ## Damage x 100 / (100 + armor), the Unit formula (BuildingType has no armour).
var _look: Node3D
var _crown_mat: StandardMaterial3D


## The tree's BuildingType (code-made): 2 x 2 cells, `hp` HP, 1 % / s idle regen, sight 14.
static func make_type(hp: float) -> BuildingType:
	var t := BuildingType.new()
	t.id = &"golden_tree"
	t.display_name = "The Master's Golden Tree"
	t.faction = &"nature"
	t.kind = &"tree"
	t.max_hp = hp
	t.footprint = Vector2i(2, 2)
	t.height = 6.0
	t.sight_radius = 14.0
	t.idle_regen_pct = 1.0
	t.counts_for_defeat = false
	t.color = GOLD
	t.body_color = Color(0.45, 0.34, 0.2)
	return t


func _ready() -> void:
	super()
	if _visual:
		_visual.visible = false
	_build_look()


func target_radius() -> float:
	return RADIUS


func take_damage(amount: float, attacker: Node3D = null) -> void:
	super(amount * 100.0 / (100.0 + maxf(0.0, armor)), attacker)
	_paint_damage()


func _paint_damage() -> void:
	if _crown_mat == null or max_hp <= 0.0:
		return
	var f := clampf(hp / max_hp, 0.0, 1.0)
	_crown_mat.emission_energy_multiplier = 0.25 + 0.75 * f
	_crown_mat.albedo_color = GOLD.lerp(Color(0.55, 0.45, 0.25), 1.0 - f)
	if _look:
		var s := 0.7 + 0.3 * f   # the leaves thin, the crown shrinks a little
		var crown := _look.get_node_or_null(^"Crown") as Node3D
		if crown:
			crown.scale = Vector3(s, s, s)


func _build_look() -> void:
	if _SIM.enabled or DisplayServer.get_name() == "headless":
		return
	_look = Node3D.new()
	_look.name = "GoldenTreeLook"
	add_child(_look)
	var trunk := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.5
	c.bottom_radius = 0.9
	c.height = 6.0
	trunk.mesh = c
	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color(0.45, 0.34, 0.2)
	trunk.material_override = bark
	trunk.position.y = 3.0
	_look.add_child(trunk)
	var crown := MeshInstance3D.new()
	crown.name = "Crown"
	var s := SphereMesh.new()
	s.radius = 4.2
	s.height = 6.5
	crown.mesh = s
	_crown_mat = StandardMaterial3D.new()
	_crown_mat.albedo_color = GOLD
	_crown_mat.emission_enabled = true
	_crown_mat.emission = Color(0.9, 0.7, 0.25) * 0.4
	crown.material_override = _crown_mat
	crown.position.y = 8.0
	_look.add_child(crown)
	var ring := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = refuge_radius
	disc.bottom_radius = refuge_radius
	disc.height = 0.03
	disc.radial_segments = 48
	ring.mesh = disc
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(1.0, 0.85, 0.35, 0.16)
	rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = rmat
	ring.position.y = 0.05
	_look.add_child(ring)
