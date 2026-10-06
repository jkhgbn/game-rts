class_name MissionGrove
extends Building
## A planted grove of mission e2m2 (docs/design/mission-e2-02.md "The groves"): a Building of the ALLY seat (900 HP,
## sight 12, idle regen) with the Sap Ward aura (own and allied units, `aura:sap`), spawned by its GroveSite
## when the planting completes. The site owns Sprouts / Seedbed (it outlives the grove). Destroyed = the site goes back
## to burnt stumps (the mission listens to `destroyed`). Placeholder look in code (E2M2.V1 replaces it): young trees,
## moss and flowers, the only spring colours on the map, grown in 1.5 s.

const SPRING := Color(0.45, 0.85, 0.35)
const RADIUS := 4.0

var site: Node3D = null      ## The GroveSite that planted it.
var _look: Node3D


## The grove's BuildingType (code-made): 2 x 2 cells, `hp` HP, armor 5, sight 12, idle regen 1 %/s, the Sap Ward.
static func make_type(hp: float, aura_radius: float, aura_stats: Dictionary, counts_for_defeat := false) -> BuildingType:
	var t := BuildingType.new()
	t.id = &"ysolde_grove"
	t.display_name = "Grove"
	t.faction = &"nature"
	t.kind = &"grove"
	t.max_hp = hp
	t.footprint = Vector2i(2, 2)
	t.height = 3.0
	t.sight_radius = 12.0
	t.idle_regen_pct = 1.0
	t.counts_for_defeat = counts_for_defeat
	t.color = SPRING
	t.body_color = Color(0.32, 0.24, 0.16)
	t.aura_radius = aura_radius
	t.aura_stats = aura_stats
	t.aura_id = &"sap"
	return t


func _ready() -> void:
	super()
	if _visual:
		_visual.visible = false
	_build_look()


func target_radius() -> float:
	return RADIUS * 0.5


func _build_look() -> void:
	if DisplayServer.get_name() == "headless":
		return
	_look = Node3D.new()
	_look.name = "GroveLook"
	add_child(_look)
	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color(0.38, 0.28, 0.17)
	var leaf := StandardMaterial3D.new()
	leaf.albedo_color = SPRING
	var moss := StandardMaterial3D.new()
	moss.albedo_color = Color(0.30, 0.55, 0.22)
	var disc := CylinderMesh.new()
	disc.top_radius = RADIUS
	disc.bottom_radius = RADIUS
	disc.height = 0.04
	disc.radial_segments = 32
	var dmi := MeshInstance3D.new()
	dmi.mesh = disc
	dmi.material_override = moss
	dmi.position.y = 0.03
	_look.add_child(dmi)
	for i in 5:
		var a := TAU * float(i) / 5.0 + 0.3
		var p := Vector3(cos(a), 0.0, sin(a)) * (1.2 + 0.5 * float(i % 2))
		var trunk := CylinderMesh.new()
		trunk.top_radius = 0.08
		trunk.bottom_radius = 0.16
		trunk.height = 1.6
		var tmi := MeshInstance3D.new()
		tmi.mesh = trunk
		tmi.material_override = bark
		tmi.position = p + Vector3(0.0, 0.8, 0.0)
		_look.add_child(tmi)
		var crown := SphereMesh.new()
		crown.radius = 0.55
		crown.height = 0.9
		var cmi := MeshInstance3D.new()
		cmi.mesh = crown
		cmi.material_override = leaf
		cmi.position = p + Vector3(0.0, 1.8, 0.0)
		_look.add_child(cmi)
	for i in 8:
		var a := TAU * float(i) / 8.0
		var f := SphereMesh.new()
		f.radius = 0.12
		f.height = 0.2
		var fmat := StandardMaterial3D.new()
		fmat.albedo_color = Color(1.0, 0.85, 0.35) if i % 2 == 0 else Color(0.95, 0.5, 0.75)
		var fmi := MeshInstance3D.new()
		fmi.mesh = f
		fmi.material_override = fmat
		fmi.position = Vector3(cos(a), 0.0, sin(a)) * 2.6 + Vector3(0.0, 0.1, 0.0)
		_look.add_child(fmi)
	_look.scale = Vector3(0.05, 0.05, 0.05)
	create_tween().tween_property(_look, "scale", Vector3.ONE, 1.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
