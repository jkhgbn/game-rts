extends SceneTree
## G-F round 2 Fire / Shadow buildings (docs/art/gf_r2_buildings_fs.md; gf_review2 items 3, 4, 8).
## Run: godot --headless --path . -s tests/test_gf_r2_fs.gd --fixed-fps 60 --quit-after 2400
## Checks: the Fire keep's crown is 25 % lower and slimmer (spire, heart, rune band, crystal ring) and keeps its hooks
## (site, tiers, damage, collapse); the Ember Crucible's glows go through the glow cap; the Ember Hall coals are dimmer;
## the Dusk Keep's lights are graded the same for every team; the Gloom Hall / Gloom Forge / Hovel roofs are slates
## (three team shades in the merge); a Shadow site shows the site pad + scaffold, not the squashed plinth, and the
## pad goes away once built or destroyed; the dead ground lifts while building.

const TASK_ID := "gf_r2_fs"
const FIRE_KEEP := "res://art/buildings/fire_keep.tscn"
const DUSK_KEEP := "res://art/buildings/dusk_keep.tscn"
const HALL := "res://art/buildings/shadow_hall.tscn"
const HOVEL := "res://art/buildings/hovel.tscn"
const FIRE_HALL := "res://art/buildings/fire_hall.tscn"
const DUSK_SCRIPT := preload("res://art/buildings/dusk_keep.gd")
const CRUCIBLE_DIR := "res://art/buildings/fire/ember_crucible/materials/"

var frame := 0
var world: Node3D
var _fk: Node3D
var _fk_site: Node3D
var _dk: Node3D
var _dk_alt: Node3D
var _hall: Node3D
var _hall_site: Node3D
var _hovel_site: Node3D
var _fire_hall: Node3D
var _finished: int = 0
var _errors: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	world = Node3D.new()
	root.add_child(world)
	_fk = _add(FIRE_KEEP, Vector3(0, 0, 0))
	_fk.connect(&"destroyed_finished", func() -> void: _finished += 1)
	_fk_site = _add(FIRE_KEEP, Vector3(16, 0, 0))
	_fk_site.call(&"set_construction_progress", 0.0)
	_dk = _add(DUSK_KEEP, Vector3(32, 0, 0))
	_dk_alt = _add(DUSK_KEEP, Vector3(48, 0, 0))
	_dk_alt.call(&"set_team_color", Color(0.2, 0.62, 0.55))
	_hall = _add(HALL, Vector3(0, 0, 20))
	_hall_site = _add(HALL, Vector3(16, 0, 20))
	_hall_site.call(&"set_construction_progress", 0.0)
	_hovel_site = _add(HOVEL, Vector3(32, 0, 20))
	_hovel_site.call(&"set_construction_progress", 0.0)
	_fire_hall = _add(FIRE_HALL, Vector3(48, 0, 20))


func _add(path: String, pos: Vector3) -> Node3D:
	var m := (load(path) as PackedScene).instantiate() as Node3D
	m.position = pos
	world.add_child(m)
	return m


func _check(ok: bool, msg: String) -> void:
	if not ok:
		_errors.append(msg)


func _process(_delta: float) -> bool:
	frame += 1
	if frame == 5:
		_check_static()
	if frame == 6:
		_fk.call(&"set_tier", 3)
		_fk.call(&"set_health_ratio", 0.2)
		_fk.call(&"play_destroyed")
		_hall_site.call(&"set_construction_progress", 0.5)
		_hovel_site.call(&"set_construction_progress", 0.5)
		_fk_site.call(&"set_construction_progress", 1.0)
	if frame == 8:
		_check_mid()
	if frame == 9:
		_hall_site.call(&"set_construction_progress", 1.0)
		_hovel_site.call(&"set_construction_progress", 1.0)
	if frame == 60:
		_check_built()
	if frame == 260:
		_check(_finished == 1, "Fire keep collapse did not emit destroyed_finished (%d)" % _finished)
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		quit(0)
	return false


func _check_static() -> void:
	# --- Fire keep crown (item 4).
	var spire := _fk.get_node(^"Body/Spire") as Node3D
	_check(absf(spire.scale.y - 0.75) < 0.01 and absf(spire.scale.x - 0.82) < 0.01, "spire not squashed / slimmed: %s" % spire.scale)
	var heart := _fk.get_node(^"Body/EmberHeart") as Node3D
	_check(heart.position.y < 15.5 and heart.position.y > 14.8, "heart not lowered: %.2f" % heart.position.y)
	var ring := _fk.get_node(^"Body/Ring") as Node3D
	_check(ring.position.y < 13.9 and absf(ring.scale.x - 0.82) < 0.01, "ring not lowered / slimmed: y %.2f s %.2f" % [ring.position.y, ring.scale.x])
	var crystal := _fk.get_node(^"Body/Ring/Crystal1") as Node3D
	var rad: float = Vector2(crystal.global_position.x - _fk.global_position.x, crystal.global_position.z - _fk.global_position.z).length()
	_check(rad < 2.8 and rad > 2.4, "crystal ring radius %.2f (want ~2.67)" % rad)
	_check((_fk.get_node(^"Body/RuneTilt") as Node3D).scale.x < 0.9, "rune band not slimmed")
	_check(not (_fk_site.get_node(^"Body/Ring") as Node3D).visible, "keep site shows the crystal ring")
	# --- Crucible glows through the cap.
	for id: String in ["ec_molten", "ec_white_hot", "ec_coals"]:
		var m := load(CRUCIBLE_DIR + id + ".tres") as ShaderMaterial
		_check(m != null and m.shader.resource_path.ends_with("crucible_glow.gdshader"), "%s not on crucible_glow" % id)
		_check(m != null and m.shader.code.contains("glow_cap("), "%s shader without the glow cap" % id)
	var cr := load("res://art/buildings/fire/ember_crucible/ember_crucible.tscn") as PackedScene
	_check(cr != null and cr.instantiate() != null, "ember crucible does not instantiate")
	# --- Ember Hall chimney flames.
	var cf := _fire_hall.find_child("ChimneyFire", true, false) as GPUParticles3D
	_check(cf != null and cf.amount <= 12, "Ember Hall chimney flames not reduced")
	# --- Dusk Keep lights (item 3): graded for every team, the same way.
	for k: Node3D in [_dk, _dk_alt]:
		for ln: String in ["SpireLight", "GateLight"]:
			var l := k.get_node(NodePath(ln)) as OmniLight3D
			_check(l.light_color.s <= 0.41, "%s %s saturation %.2f" % [k.name, ln, l.light_color.s])
	var ls: float = (_dk.get_node(^"SpireLight") as OmniLight3D).light_color.s
	var la: float = (_dk_alt.get_node(^"SpireLight") as OmniLight3D).light_color.s
	_check(absf(ls - la) < 0.05, "player / alt spire light saturation differ: %.2f vs %.2f" % [ls, la])
	_check(DUSK_SCRIPT.IDLE_RIM.s < 0.35, "idle rim still saturated")
	# --- Slate roofs: three team shades merged (dark, mid, team).
	_check(_count_team_shades(_hall) >= 3, "Gloom Hall roof: fewer than 3 team shades")
	var hv := (load(HOVEL) as PackedScene).instantiate() as Node3D
	world.add_child(hv)
	_check(_count_team_shades(hv) >= 3, "Hovel roof: fewer than 3 team shades")
	var roof := _hall.find_child("Roof", true, false) as MeshInstance3D
	_check(roof != null and _verts(roof.mesh) > 2000, "Gloom Hall roof has no slates (%d verts)" % (_verts(roof.mesh) if roof else 0))
	# --- Sites (item 8).
	_check_site(_hall_site, "PlinthBase", "hall")
	_check_site(_hovel_site, "Plinth", "hovel")
	var sh := (load("res://art/buildings/shadow_dead_ground.gdshader") as Shader).code
	_check(sh.contains("float site"), "dead ground has no site lift")


func _check_site(m: Node3D, plinth: String, nm: String) -> void:
	var pad := m.get_node_or_null(^"SitePad") as Node3D
	_check(pad != null and pad.visible, "%s site: no visible site pad" % nm)
	_check(not (m.get_node(NodePath("Body/" + plinth)) as Node3D).visible, "%s site: squashed plinth shown at 0" % nm)
	var sc := m.get_node_or_null(^"Scaffold") as Node3D
	_check(sc != null and sc.visible, "%s site: no scaffold at 0" % nm)


func _check_mid() -> void:
	for pair: Array in [[_hall_site, "PlinthBase"], [_hovel_site, "Plinth"]]:
		var m: Node3D = pair[0]
		_check((m.get_node(NodePath("Body/" + String(pair[1]))) as Node3D).visible, "%s at 0.5: plinth hidden" % m.name)
		_check((m.get_node(^"SitePad") as Node3D).visible, "%s at 0.5: pad hidden" % m.name)
	_check((_fk_site.get_node(^"Body/Ring") as Node3D).visible, "built keep site: no crystal ring")


func _check_built() -> void:
	for m: Node3D in [_hall_site, _hovel_site]:
		_check(not (m.get_node(^"SitePad") as Node3D).visible, "%s built: pad still shown" % m.name)
		_check(not (m.get_node(^"Scaffold") as Node3D).visible, "%s built: scaffold still shown" % m.name)
	var ring := _fk_site.get_node(^"Body/Ring") as Node3D
	_check(absf(ring.scale.x - 0.82) < 0.02, "built keep site: ring scale %.2f after appearing" % ring.scale.x)


## Distinct team multipliers in the model's merged painted_vc surfaces (team vertices: COLOR.a == 0).
func _count_team_shades(m: Node) -> int:
	var seen := {}
	for n: Node in m.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = (n as MeshInstance3D).mesh
		if mesh == null:
			continue
		for s: int in mesh.get_surface_count():
			var arr: Array = mesh.surface_get_arrays(s)
			var cols: Variant = arr[Mesh.ARRAY_COLOR]
			if not (cols is PackedColorArray):
				continue
			for c: Color in cols as PackedColorArray:
				if c.a < 0.5:
					seen[snappedf(c.r, 0.01)] = true
	return seen.size()


func _verts(mesh: Mesh) -> int:
	var n: int = 0
	if mesh == null:
		return 0
	for s: int in mesh.get_surface_count():
		n += (mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	return n
