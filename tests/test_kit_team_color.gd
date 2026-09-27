extends SceneTree
## Kit fix: set_team_color works any number of times, in any order (mid-game recolour, mirror matches), on every part:
## merged cloth, keep_separate parts (material_override), mounts (+ barding swap), rider wrappers (forwarded hook), titans
## (kit mount + howdah, instance-uniform tints), a warden-based model (Barrow Giant). Restoring the scene's own
## kingdom_color gives the authored materials back. A second instance of each type stays untouched (mirror match), and
## repeating the cycle creates no new materials (the kit's per-colour cache).
## Run: $GODOT --headless --path . -s tests/test_kit_team_color.gd --fixed-fps 60 --quit-after 3000
## Prints "PASS kit_team_color" or "FAIL kit_team_color: <reasons>".

const TASK_ID := "kit_team_color"
const MODELS: Array[String] = [
	"res://art/units/fire/flame_guard.tscn",             # soldier
	"res://art/units/shadow/shadow_knight.tscn",         # soldier (ShadowModel)
	"res://art/units/shadow/barrow_giant/barrow_giant.tscn",   # warden-based model with cloth
	"res://art/units/champions/oathwall/oathwall.tscn",  # champion (had its own restore workaround)
	"res://art/units/champions/wayfinder/wayfinder.tscn",   # champion
	"res://art/units/mounts/rimehorn/rimehorn.tscn",     # mount
	"res://art/units/mounts/grove_stag/grove_stag.tscn", # mount
	"res://art/units/nature/glade_outrider/glade_outrider.tscn",   # rider wrapper (stag + rider)
	"res://art/units/fire/blaze_rider.tscn",             # rider wrapper (boar + rider)
	"res://art/units/titans/war_mammoth/war_mammoth.tscn",   # titan: MountModel + nested howdah
	"res://art/units/titans/cinder_dragon/cinder_dragon.tscn",   # titan: instance-uniform tint
]
const TINT_PARAMS: Array[StringName] = [&"membrane_tint", &"team_tint"]
const SUFFIX_CLOTH: Array[String] = ["_cloth", "_cloth_dark"]
const SUFFIX_CAPE: Array[String] = ["_cape", "_cape_plain", "_pennon"]

var _fails: PackedStringArray = PackedStringArray()
var _world: Node3D
var _colors: Array[Color] = [Color8(200, 40, 40), Color8(40, 90, 220), Color8(230, 200, 30)]


func _initialize() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 8, 14)
	_world.add_child(cam)
	cam.look_at_from_position(cam.position, Vector3.ZERO)
	_run()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  FAILED: ", what)


func _wait(frames: int) -> void:
	for i: int in frames:
		await process_frame


func _run() -> void:
	var x := 0.0
	for path: String in MODELS:
		if not ResourceLoader.exists(path):
			_check(false, "%s exists" % path)
			continue
		await _test_model(path, x)
		x += 8.0
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()


func _test_model(path: String, x: float) -> void:
	var nm := path.get_file().get_basename()
	var ps := load(path) as PackedScene
	var a: Node3D = ps.instantiate()
	var b: Node3D = ps.instantiate()   # the mirror-match twin, never recoloured
	a.position = Vector3(x, 0, 0)
	b.position = Vector3(x, 0, 5)
	a.call(&"set_team_color", _colors[0])   # before _ready (the Unit's spawn call)
	_world.add_child(a)
	_world.add_child(b)
	await _wait(6)
	var kc: Color = a.get(&"kingdom_color") if a.get(&"kingdom_color") != null else Color.WHITE
	var surf := _team_surfaces(a)
	var tints := _tint_nodes(a)
	var mo_n := 0
	for e: Array in surf:
		if e[1] < 0:
			mo_n += 1
	print("%s: %d team surfaces (%d material_override parts), %d tint nodes" % [nm, surf.size(), mo_n, tints.size()])
	_check(surf.size() + tints.size() > 0, "%s: has something that takes the team colour" % nm)
	_check(_all_colored(a, _colors[0], kc), "%s: colour 1 (set before _ready)" % nm)
	# three recolours, a restore, again, a restore
	var seq: Array = [_colors[1], _colors[2], _colors[0], kc, _colors[2], _colors[1], kc]
	var cache_before := -1
	for i: int in seq.size():
		var c: Color = seq[i]
		a.call(&"set_team_color", c)
		await _wait(1)
		if i == 4:
			cache_before = _cache_size()
		var what := "restore" if c == kc else "colour %s" % c.to_html(false)
		_check(_all_colored(a, c, kc), "%s: step %d (%s)" % [nm, i + 1, what])
		_check(_all_colored(b, kc, kc), "%s: twin untouched after step %d" % [nm, i + 1])
	_check(_cache_size() == cache_before, "%s: no new materials when a colour comes back (%d -> %d)" % [nm, cache_before,
		_cache_size()])
	# the barding swap keeps the colour (mounts)
	if a.has_method(&"set_barded"):
		a.call(&"set_team_color", _colors[1])
		a.call(&"set_barded", true)
		await _wait(2)
		_check(_all_colored(a, _colors[1], kc), "%s: barded keeps the colour" % nm)
		a.call(&"set_team_color", kc)
		await _wait(1)
		_check(_all_colored(a, kc, kc), "%s: barded restore" % nm)
		a.call(&"set_barded", false)
		await _wait(1)
		_check(_all_colored(a, kc, kc), "%s: unbarded stays restored" % nm)
	a.queue_free()
	b.queue_free()
	await _wait(2)


func _cache_size() -> int:
	return CharacterModel._team_mats.size()


## [[GeometryInstance3D, surface (-1 = material_override)], ...] for every surface whose authored material is team cloth.
func _team_surfaces(n: Node) -> Array:
	var out: Array = []
	for gi: Node in n.find_children("*", "GeometryInstance3D", true, false):
		var g := gi as GeometryInstance3D
		if g.material_override:
			if _is_team_mat(_base(g.material_override)):
				out.append([g, -1])
		elif g is MeshInstance3D and (g as MeshInstance3D).mesh:
			var mi := g as MeshInstance3D
			for s: int in mi.mesh.get_surface_count():
				if _is_team_mat(_base(_effective(mi, s))):
					out.append([mi, s])
	return out


func _tint_nodes(n: Node) -> Array:
	var out: Array = []
	for gi: Node in n.find_children("*", "GeometryInstance3D", true, false):
		for p: StringName in TINT_PARAMS:
			if (gi as GeometryInstance3D).get_instance_shader_parameter(p) != null:
				out.append([gi, p])
	return out


func _effective(mi: MeshInstance3D, s: int) -> Material:
	if mi.material_override:
		return mi.material_override
	var o := mi.get_surface_override_material(s)
	return o if o else mi.mesh.surface_get_material(s)


func _base(m: Material) -> Material:
	if m and m.has_meta(&"team_base"):
		return m.get_meta(&"team_base") as Material
	return m


func _is_team_mat(m: Material) -> bool:
	if m == null or m.resource_path == "":
		return false
	var nm := m.resource_path.get_file().get_basename()
	for s: String in SUFFIX_CLOTH + SUFFIX_CAPE:
		if nm.ends_with(s):
			return true
	return false


## Every team surface of the model shows colour c (c == kc: the authored material), every tint node too.
func _all_colored(model: Node, c: Color, kc: Color) -> bool:
	var ok := true
	var restore := _near(c, kc)
	for e: Array in _team_surfaces(model):
		var g: GeometryInstance3D = e[0]
		var s: int = e[1]
		var m: Material = g.material_override if s < 0 else _effective(g as MeshInstance3D, s)
		var owner_kc := _owner_kingdom(g, kc)
		var want_restore := restore or _near(c, owner_kc)
		if want_restore:
			if m.has_meta(&"team_base"):
				print("    %s surface %d still a team variant after restore" % [g.get_path(), s])
				ok = false
			continue
		if not m.has_meta(&"team_base"):
			print("    %s surface %d not recoloured (%s)" % [g.get_path(), s, m.resource_path.get_file()])
			ok = false
			continue
		var bn := _base(m).resource_path.get_file().get_basename()
		var sm := m as ShaderMaterial
		var got: Variant
		var want: Color = c
		if bn.ends_with("_cloth") or bn.ends_with("_cloth_dark"):
			got = sm.get_shader_parameter(&"base_color")
			if bn.ends_with("_dark"):
				want = c.darkened(0.55)
		else:
			got = sm.get_shader_parameter(&"cloth_color")
		if not (got is Color) or not _near(got, want):
			print("    %s surface %d shows %s, want %s" % [g.get_path(), s, str(got), want.to_html(false)])
			ok = false
	for e: Array in _tint_nodes(model):
		var v: Variant = (e[0] as GeometryInstance3D).get_instance_shader_parameter(e[1])
		if not (v is Vector3) or (v as Vector3).distance_to(Vector3(c.r, c.g, c.b)) > 0.02:
			print("    %s %s = %s, want %s" % [(e[0] as Node).get_path(), e[1], str(v), c.to_html(false)])
			ok = false
	return ok


## The kingdom colour of the kit model that owns g (a rider wrapper's children have their own).
func _owner_kingdom(g: Node, fallback: Color) -> Color:
	var n: Node = g
	while n:
		if n is CharacterModel:
			return (n as CharacterModel).kingdom_color
		n = n.get_parent()
	return fallback


func _near(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) <= 0.01 and absf(a.g - b.g) <= 0.01 and absf(a.b - b.b) <= 0.01
