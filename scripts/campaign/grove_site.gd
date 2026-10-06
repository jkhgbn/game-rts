class_name GroveSite
extends Node3D
## A grove site of mission e2m2 (docs/design/mission-e2-02.md "The groves"): before planting a ring of grey burnt stumps
## with a dead-seed glyph (always shown, not a target: a plain Node3D, not a Unit / Building), the planting progress
## ring while 2 seed-carriers channel, and the anchor of its planted MissionGrove (the Sprouts / Seedbed timers live
## here: the site outlives a destroyed grove). The mission drives it (`progress`, `paused`, `set_planted`).

const DEAD := Color(0.30, 0.40, 0.28)
const STUMP := Color(0.28, 0.27, 0.26)
const PROGRESS := Color(0.45, 0.85, 0.35, 0.8)
const PAUSED := Color(0.95, 0.75, 0.30, 0.8)

var site_id: StringName = &""
var grove_name := ""
var radius := 6.0
var progress := 0.0                ## 0-1 of the planting channel.
var paused := false                ## Read only: the last tick paused (enemy inside / fewer than 2 carriers).
var grove: MissionGrove = null     ## The planted grove (null = a site).
var sprout_left := 60.0            ## Sprouts: s until the next 2 Thornlings.
var seed_left := 90.0              ## Seedbed: s until the next carrier.
var sprouts: Array = []            ## Living Thornlings of this grove (max 4).
var times_planted := 0

var _ring_mat: StandardMaterial3D
var _ring: MeshInstance3D
var _stumps: Node3D


func _ready() -> void:
	add_to_group(&"grove_sites")
	_build_look()


func is_planted() -> bool:
	return grove != null and is_instance_valid(grove) and grove.is_alive()


func set_planted(g: MissionGrove) -> void:
	grove = g
	progress = 0.0
	if g != null:
		times_planted += 1
	if _stumps:
		_stumps.visible = g == null
	_update_ring()


## The planting ring (mission tick).
func set_progress(p: float, is_paused: bool) -> void:
	progress = clampf(p, 0.0, 1.0)
	paused = is_paused
	_update_ring()


func _update_ring() -> void:
	if _ring == null:
		return
	var show := progress > 0.0 and not is_planted()
	_ring.visible = show
	if show:
		_ring.scale = Vector3(maxf(0.05, progress), 1.0, maxf(0.05, progress))
		_ring_mat.albedo_color = PAUSED if paused else PROGRESS


func _build_look() -> void:
	if DisplayServer.get_name() == "headless":
		return
	_stumps = Node3D.new()
	_stumps.name = "Stumps"
	add_child(_stumps)
	var stump_mat := StandardMaterial3D.new()
	stump_mat.albedo_color = STUMP
	stump_mat.roughness = 1.0
	for i in 9:
		var a := TAU * float(i) / 9.0
		var c := CylinderMesh.new()
		c.top_radius = 0.22
		c.bottom_radius = 0.32
		c.height = 0.5 + 0.25 * float(i % 3)
		c.radial_segments = 7
		var mi := MeshInstance3D.new()
		mi.mesh = c
		mi.material_override = stump_mat
		mi.position = Vector3(cos(a), 0.0, sin(a)) * radius + Vector3(0.0, c.height * 0.5, 0.0)
		_stumps.add_child(mi)
	var glyph := TorusMesh.new()
	glyph.inner_radius = 1.0
	glyph.outer_radius = 1.25
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = DEAD
	gmat.emission_enabled = true
	gmat.emission = DEAD
	gmat.emission_energy_multiplier = 0.4
	var gmi := MeshInstance3D.new()
	gmi.mesh = glyph
	gmi.material_override = gmat
	gmi.scale = Vector3(1.0, 0.05, 1.0)
	gmi.position.y = 0.03
	_stumps.add_child(gmi)
	var disc := TorusMesh.new()
	disc.inner_radius = radius - 0.35
	disc.outer_radius = radius
	_ring_mat = StandardMaterial3D.new()
	_ring_mat.albedo_color = PROGRESS
	_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring = MeshInstance3D.new()
	_ring.name = "PlantingRing"
	_ring.mesh = disc
	_ring.material_override = _ring_mat
	_ring.position.y = 0.08
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.visible = false
	add_child(_ring)
