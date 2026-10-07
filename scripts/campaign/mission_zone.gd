class_name MissionZone
extends Node3D
## A mission capture zone by SIDE (2v2: side 0 = the player's alliance, side 1 = the other): the ford zone and the
## standards of e3m1 (docs/design/mission-e3-01.md "Ford zone" / "Standards"), the ridge points of e3m4. No collider,
## never a target (not in "units" / "buildings"); the mission calls `tick(dt)` (4 times per second is plenty).
## Rules (the map-fill.md 4.3 capture rules, by side):
## - presence: living soldiers / wizards / helpers of a side within `radius` (workers and dormant units never count;
##   a wizard counts 2). Both sides present = contested (frozen). Nobody = the progress decays `DECAY` of the bar per s.
## - rate: `fixed_rate` = 1 / capture_time per second whatever the count; else min(1 + 0.25 x (n - 1), 1.75) / time.
## - an owned zone is first neutralised by the other side (full time), then captured; the owner alone lets the other
##   side's partial progress decay. `sides_allowed` limits who may capture (the ford: side 0 only); `lock_on_capture`
##   = once captured it stays (the ford).
## Look (placeholder, 0 lights): a ground ring in the owner's colour, a growing progress disc, and for standards a 6 m
## pole with a banner (`topple()` = the 2 s fall of e3m1_standard).

signal captured(zone: MissionZone, side: int)
signal neutralised(zone: MissionZone, side: int)
signal progress_moved(zone: MissionZone, side: int, ratio: float)

const DECAY := 0.10
const RATE_PER_EXTRA := 0.25
const RATE_CAP := 1.75
const NEUTRAL_COLOR := Color(0.75, 0.72, 0.62)

@export var zone_id: StringName = &""
@export var display_name := "Zone"
@export var radius := 6.0
@export var capture_time := 12.0
@export var fixed_rate := false
@export var lock_on_capture := false
@export var has_pole := false
## Sides that may capture (empty = both).
var sides_allowed: Array[int] = []
## Capture time multiplier per side (e3m1: x1.25 on the far bank).
var time_factor := {0: 1.0, 1: 1.0}

var owner_side := -1          ## Read only: -1 neutral, else 0 / 1.
var capture_side := -1        ## Read only: the side whose partial progress `progress` is.
var progress := 0.0           ## Read only: 0-1.
var contested := false        ## Read only.
var locked := false           ## Read only (lock_on_capture after the capture).
var counts := [0, 0]          ## Read only: presence at the last tick.

var _ring: MeshInstance3D
var _ring_mat: StandardMaterial3D
var _disc: MeshInstance3D
var _disc_mat: StandardMaterial3D
var _pole: Node3D
var _banner_mat: StandardMaterial3D
const _SIM := preload("res://scripts/core/sim_mode.gd")


func _ready() -> void:
	add_to_group(&"mission_zones")
	if not _SIM.enabled:
		_build_look()
	_paint()


## The side of a team (Teams in a 2v2, else PLAYER = 0 / the rest 1).
static func side_of_team(team: int) -> int:
	if Teams.multi:
		return Teams.side_of(team)
	return 0 if team == Unit.Team.PLAYER or team == Unit.Team.ALLY else 1


## [side 0 count, side 1 count] of the units within `r` of `at` (wizards count 2; workers, NEUTRAL, dormant and
## truce units never count).
static func presence(tree: SceneTree, at: Vector3, r: float) -> Array:
	var out := [0, 0]
	for n in tree.get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or not u.is_alive() or int(u.team) == Unit.Team.NEUTRAL or u.is_worker():
			continue
		if u.has_meta(&"mission_dormant") or u.has_meta(Unit.TRUCE_META):
			continue
		if Vector2(u.global_position.x - at.x, u.global_position.z - at.z).length() > r:
			continue
		var s := side_of_team(int(u.team))
		if s < 0 or s > 1:
			continue
		out[s] += 2 if u is Wizard else 1
	return out


func tick(dt: float) -> void:
	if locked or not is_inside_tree():
		return
	counts = presence(get_tree(), global_position, radius)
	var n0: int = counts[0]
	var n1: int = counts[1]
	var allowed0 := sides_allowed.is_empty() or sides_allowed.has(0)
	var allowed1 := sides_allowed.is_empty() or sides_allowed.has(1)
	contested = n0 > 0 and n1 > 0
	if contested:
		_paint()
		return
	var side := -1
	var n := 0
	if n0 > 0 and allowed0:
		side = 0
		n = n0
	elif n1 > 0 and allowed1:
		side = 1
		n = n1
	if side < 0:
		_decay(dt)   # nobody (or only a side not allowed): the partial bar falls
		return
	if side == owner_side:
		_decay(dt)   # the owner alone lets the other side's partial progress fall
		return
	var rate := (1.0 if fixed_rate else minf(1.0 + RATE_PER_EXTRA * float(n - 1), RATE_CAP)) \
			/ maxf(0.1, capture_time * float(time_factor.get(side, 1.0)))
	if capture_side != side and progress > 0.0:
		progress = maxf(0.0, progress - rate * dt)   # drain the other side's partial progress first
		if progress <= 0.0:
			capture_side = -1
		_paint()
		return
	capture_side = side
	progress = minf(1.0, progress + rate * dt)
	progress_moved.emit(self, side, progress)
	if progress >= 1.0:
		progress = 0.0
		capture_side = -1
		if owner_side >= 0 and owner_side != side:
			var old := owner_side
			owner_side = -1
			neutralised.emit(self, old)
		else:
			owner_side = side
			if lock_on_capture:
				locked = true
			captured.emit(self, side)
	_paint()


func _decay(dt: float) -> void:
	if progress <= 0.0:
		return
	progress = maxf(0.0, progress - DECAY * dt)
	if progress <= 0.0:
		capture_side = -1
	_paint()


## Sets the owner at once (scripts / tests): -1 = neutral.
func set_owner_side(side: int) -> void:
	owner_side = side
	progress = 0.0
	capture_side = -1
	if side >= 0 and lock_on_capture:
		locked = true
	_paint()


## The 2 s topple of the standard's pole (e3m1_standard fallback); `upright` puts it back.
func topple(upright := false) -> void:
	if _pole == null:
		return
	if upright:
		_pole.rotation = Vector3.ZERO
		return
	var tw := create_tween()
	tw.tween_property(_pole, "rotation:z", deg_to_rad(84.0), 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func side_color(side: int) -> Color:
	if side < 0:
		return NEUTRAL_COLOR
	return Unit.team_color(Unit.Team.PLAYER if side == 0 else Unit.Team.ENEMY)


func _build_look() -> void:
	_ring = MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = maxf(0.2, radius - 0.35)
	t.outer_radius = radius
	t.rings = 48
	_ring.mesh = t
	_ring.scale = Vector3(1.0, 0.08, 1.0)
	_ring_mat = StandardMaterial3D.new()
	_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring.material_override = _ring_mat
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)
	_ring.position.y = 0.08
	_disc = MeshInstance3D.new()
	var d := CylinderMesh.new()
	d.top_radius = radius
	d.bottom_radius = radius
	d.height = 0.02
	d.radial_segments = 48
	_disc.mesh = d
	_disc_mat = StandardMaterial3D.new()
	_disc_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_disc_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_disc.material_override = _disc_mat
	_disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_disc)
	_disc.position.y = 0.05
	if has_pole:
		_pole = Node3D.new()
		add_child(_pole)
		var staff := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.08
		c.bottom_radius = 0.12
		c.height = 6.0
		staff.mesh = c
		var wood := StandardMaterial3D.new()
		wood.albedo_color = Color(0.42, 0.30, 0.18)
		staff.material_override = wood
		staff.position.y = 3.0
		_pole.add_child(staff)
		var banner := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(1.6, 2.2, 0.06)
		banner.mesh = b
		_banner_mat = StandardMaterial3D.new()
		_banner_mat.emission_enabled = true
		banner.material_override = _banner_mat
		banner.position = Vector3(0.85, 4.7, 0.0)
		_pole.add_child(banner)


func _paint() -> void:
	if _ring_mat == null:
		return
	var c := side_color(owner_side)
	if contested:
		c = c.lerp(Color(1, 1, 1), 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.012))
	_ring_mat.albedo_color = Color(c.r, c.g, c.b, 0.85)
	var pc := side_color(capture_side)
	_disc_mat.albedo_color = Color(pc.r, pc.g, pc.b, 0.25 * progress)
	_disc.scale = Vector3(maxf(0.02, progress), 1.0, maxf(0.02, progress))
	if _banner_mat:
		_banner_mat.albedo_color = c
		_banner_mat.emission = c * 0.35
