extends SceneTree
## Task 12.V24: monster camp sites (map-fill.md 5.2 + 10), art/environment/camps/<kind>_site.tscn.
## Run: $GODOT --headless --path . -s tests/test_12_v24.gd --fixed-fps 60 --quit-after 1500
## Checks, for the 4 CampManager kinds (bristleback, mirefang, gloomcap, hollow_stag):
## - the scene exists at CampSite.scene_path(kind) (map-fill.md 13 path), instantiates headless, root = camp_site.gd
##   with the right `kind`, group "camp_sites", metadata decor_clear_radius; the kinds match CampManager.CAMP_KINDS;
## - draw-only: 0 lights, 0 particles, 0 collision objects, no Area3D; nodes Base (+ Active / Cleared, Ground);
## - shared materials only (nature_mat, nature_contact_mat, camps/camp_glow_mat, camps/camp_mud_mat; Ground =
##   site_ground_mat), every surface indexed; triangle budget (<= 8 000 per mesh, <= 12 000 drawn per state);
##   size (inside r 5.6 m, <= 3.2 m tall);
## - the creature spots stay clear: nothing drawn above the per-kind height near the spot (the ring r 1.5-2.0 and the
##   stag), so creatures never stand inside a prop;
## - set_cleared(true / false, instant): Active / Cleared visibility, the `lit` / `wet` instance uniforms listed in
##   `camp_params` go to 0 / 1; the animated path fades the glow (1.4 s) and dries the wallow (6 s);
## - place_at(): local -Z faces the map centre and the point-mirrored spot gets the point-mirrored dressing; the nest
##   takes the ford flow for both fords (same yaw).
## Prints "PASS 12.v24" or "FAIL 12.v24: <reasons>".

const TASK_ID := "12.v24"
const SITE_SCRIPT := "res://art/environment/camps/camp_site.gd"
const CAMP_MANAGER := "res://scripts/world/camp_manager.gd"
const ALLOWED := [
	"res://art/environment/nature_props/nature_mat.tres",
	"res://art/environment/nature_props/nature_contact_mat.tres",
	"res://art/environment/camps/camp_glow_mat.tres",
	"res://art/environment/camps/camp_mud_mat.tres",
]
const GROUND_MAT := "res://art/environment/neutral/site_ground_mat.tres"
const KINDS: Array[StringName] = [&"bristleback", &"mirefang", &"gloomcap", &"hollow_stag"]
## Spot clearance per kind: [radius around the spot, max height drawn inside it] (alive state: Base + Active).
const CLEAR := {
	&"bristleback": [2.4, 0.35],
	&"mirefang": [1.45, 0.62],
	&"gloomcap": [2.4, 0.3],
	&"hollow_stag": [2.4, 0.3],
}
const SPOTS := {
	&"bristleback": Vector3(-14.0, 0.0, 57.0),
	&"mirefang": Vector3(-8.5, 0.0, -34.0),
	&"gloomcap": Vector3(-55.0, 0.0, -55.0),
	&"hollow_stag": Vector3(-37.0, 0.0, -10.0),
}

var _fails: PackedStringArray = PackedStringArray()
var _holder: Node3D
var _frame := 0
var _anim: Array[Node3D] = []   # [gloomcap, bristleback] sites cleared with the animation


func _initialize() -> void:
	_holder = Node3D.new()
	root.add_child(_holder)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 2:
		_check_kinds()
		for k: StringName in KINDS:
			_check_scene(k)
		_check_place()
		_start_anim()
	if _frame == 2 + 120:   # 2 s: the glow is out, the wallow still drying
		_check_anim_glow()
	if _frame == 2 + 420:   # 7 s: the wallow is dry
		_check_anim_dry()
		if _fails.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
		return true
	return false


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  FAILED: ", what)


func _site(kind: StringName) -> Node3D:
	var script: GDScript = load(SITE_SCRIPT) as GDScript
	var path: String = script.call(&"scene_path", kind)
	_check(path == "res://art/environment/camps/%s_site.tscn" % kind, "%s: scene_path %s" % [kind, path])
	if not ResourceLoader.exists(path):
		_check(false, "%s: missing %s" % [kind, path])
		return null
	var ps := load(path) as PackedScene
	var n := ps.instantiate() as Node3D
	_holder.add_child(n)
	return n


func _check_kinds() -> void:
	if not ResourceLoader.exists(CAMP_MANAGER):
		print("  (no camp_manager.gd: kinds not cross-checked)")
		return
	var s: GDScript = load(CAMP_MANAGER) as GDScript
	var consts: Dictionary = s.get_script_constant_map()
	if not consts.has("CAMP_KINDS"):
		return
	for k: Variant in (consts["CAMP_KINDS"] as Dictionary).keys():
		_check(KINDS.has(StringName(str(k))), "CampManager kind %s has no site" % k)


func _tris(mesh: Mesh) -> int:
	var t := 0
	for s in mesh.get_surface_count():
		var arr: Array = mesh.surface_get_arrays(s)
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		t += idx.size() / 3
	return t


func _check_scene(kind: StringName) -> void:
	var site := _site(kind)
	if site == null:
		return
	_check(site.get_script() != null and (site.get_script() as Script).resource_path == SITE_SCRIPT,
		"%s: root script" % kind)
	_check(StringName(str(site.get(&"kind"))) == kind, "%s: kind export = %s" % [kind, site.get(&"kind")])
	_check(site.is_in_group(&"camp_sites"), "%s: not in group camp_sites" % kind)
	_check(site.has_meta(&"decor_clear_radius") and float(site.get_meta(&"decor_clear_radius")) >= 3.5,
		"%s: decor_clear_radius" % kind)
	for m: String in ["set_cleared", "is_cleared", "place_at", "clear_radius"]:
		_check(site.has_method(m), "%s: no %s()" % [kind, m])
	# Draw-only.
	_check(site.find_children("*", "Light3D", true, false).is_empty(), "%s: has a light" % kind)
	_check(site.find_children("*", "GPUParticles3D", true, false).is_empty()
		and site.find_children("*", "CPUParticles3D", true, false).is_empty(), "%s: has particles" % kind)
	_check(site.find_children("*", "CollisionObject3D", true, false).is_empty(), "%s: has a collider / area" % kind)
	var base := site.get_node_or_null(^"Base") as MeshInstance3D
	_check(base != null and base.mesh != null, "%s: no Base mesh" % kind)
	if base == null:
		site.queue_free()
		return
	# Materials, indices, budgets, size.
	var per_state := {"alive": 0, "cleared": 0}
	var alive_verts: Array[PackedVector3Array] = []
	for mi_node: Node in site.find_children("*", "MeshInstance3D", true, false):
		var mi := mi_node as MeshInstance3D
		var mesh: Mesh = mi.mesh
		_check(mesh != null, "%s/%s: no mesh" % [kind, mi.name])
		if mesh == null:
			continue
		if mi.name == "Ground":
			var gm: Material = mi.material_override
			_check(gm != null and gm.resource_path == GROUND_MAT, "%s/Ground: material %s" % [kind,
				gm.resource_path if gm else "null"])
		else:
			_check(mi.material_override == null, "%s/%s: material_override" % [kind, mi.name])
			for s in mesh.get_surface_count():
				var m: Material = mesh.surface_get_material(s)
				_check(m != null and ALLOWED.has(m.resource_path), "%s/%s surface %d: material %s" % [kind, mi.name, s,
					m.resource_path if m else "null"])
		for s in mesh.get_surface_count():
			var arr: Array = mesh.surface_get_arrays(s)
			_check(arr[Mesh.ARRAY_INDEX] != null and (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() > 0,
				"%s/%s surface %d not indexed" % [kind, mi.name, s])
			if mi.name == "Base" or mi.name == "Active":
				alive_verts.append(arr[Mesh.ARRAY_VERTEX])
		var t := _tris(mesh)
		_check(t <= 8000, "%s/%s: %d triangles > 8000" % [kind, mi.name, t])
		if mi.name != "Cleared":
			per_state["alive"] += t
		if mi.name != "Active":
			per_state["cleared"] += t
		var aabb: AABB = mesh.get_aabb()
		var reach := maxf(maxf(absf(aabb.position.x), absf(aabb.end.x)), maxf(absf(aabb.position.z), absf(aabb.end.z)))
		# The Ground patch mesh reaches further than its painted dirt (the ragged rim sits at ~80 % of it).
		var max_reach := 7.0 if mi.name == "Ground" else 5.6
		_check(reach <= max_reach, "%s/%s: reaches %.2f m from the spot" % [kind, mi.name, reach])
		_check(aabb.end.y <= 3.2, "%s/%s: %.2f m tall" % [kind, mi.name, aabb.end.y])
		var params: PackedStringArray = mi.get_meta(&"camp_params", PackedStringArray())
		for s in mesh.get_surface_count():
			var m: Material = mesh.surface_get_material(s)
			if m and m.resource_path.ends_with("camp_glow_mat.tres"):
				_check(params.has("lit"), "%s/%s: glow surface but no 'lit' in camp_params" % [kind, mi.name])
			if m and m.resource_path.ends_with("camp_mud_mat.tres"):
				_check(params.has("wet"), "%s/%s: mud surface but no 'wet' in camp_params" % [kind, mi.name])
		print("  %-12s %-8s tris %5d surfaces %d params %s" % [kind, mi.name, t, mesh.get_surface_count(), params])
	for st: String in per_state:
		_check(int(per_state[st]) <= 12000, "%s: %d triangles drawn when %s" % [kind, per_state[st], st])
	# Creature spots stay clear.
	# (Overhead parts, >= 1.95 m like the Mother Cap's rim, pass over the creatures.)
	var cl: Array = CLEAR[kind]
	var worst := 0.0
	var at := Vector3.ZERO
	for vs: PackedVector3Array in alive_verts:
		for v: Vector3 in vs:
			if Vector2(v.x, v.z).length() < float(cl[0]) and v.y < 1.95 and v.y > worst:
				worst = v.y
				at = v
	_check(worst <= float(cl[1]), "%s: %.2f m drawn within %.1f m of the spot at %s (max %.2f)" % [kind, worst, cl[0],
		at, cl[1]])
	# set_cleared (instant).
	var active := site.get_node_or_null(^"Active") as Node3D
	var gone := site.get_node_or_null(^"Cleared") as Node3D
	_check(not bool(site.call(&"is_cleared")), "%s: starts cleared" % kind)
	_check(active == null or active.visible, "%s: Active hidden while alive" % kind)
	_check(gone == null or not gone.visible, "%s: Cleared shown while alive" % kind)
	_check_params(site, 1.0, "%s alive" % kind)
	site.call(&"set_cleared", true, true)
	_check(bool(site.call(&"is_cleared")), "%s: is_cleared() false after set_cleared(true)" % kind)
	_check(active == null or not active.visible, "%s: Active still shown when cleared" % kind)
	_check(gone == null or gone.visible, "%s: Cleared hidden when cleared" % kind)
	_check_params(site, 0.0, "%s cleared" % kind)
	site.call(&"set_cleared", false, true)
	_check(active == null or active.visible, "%s: Active hidden after respawn" % kind)
	_check_params(site, 1.0, "%s respawned" % kind)
	var has_params := false
	for gi: Node in site.get_children():
		if gi is GeometryInstance3D and (gi as GeometryInstance3D).has_meta(&"camp_params"):
			has_params = true
	_check(kind == &"bristleback" or has_params, "%s: no glow hook (camp_params)" % kind)
	site.queue_free()


func _check_params(site: Node3D, want: float, what: String) -> void:
	for n: Node in site.get_children():
		var gi := n as GeometryInstance3D
		if gi == null:
			continue
		for p: String in gi.get_meta(&"camp_params", PackedStringArray()):
			var v: Variant = gi.get_instance_shader_parameter(p)
			_check(v != null and absf(float(v) - want) < 0.01, "%s: %s/%s = %s (want %.1f)" % [what, gi.name, p, v, want])


func _check_place() -> void:
	# Point mirror: a local point of the site at p lands at -(world point) for the site at -p.
	for kind: StringName in [&"bristleback", &"gloomcap", &"hollow_stag"]:
		var a := _site(kind)
		var b := _site(kind)
		if a == null or b == null:
			continue
		var p: Vector3 = SPOTS[kind]
		a.call(&"place_at", p)
		b.call(&"place_at", -p)
		var local := Vector3(1.3, 0.4, -2.1)
		var wa: Vector3 = a.transform * local
		var wb: Vector3 = b.transform * local
		_check(Vector2(wa.x + wb.x, wa.z + wb.z).length() < 0.01 and absf(wa.y - wb.y) < 0.01,
			"%s: place_at is not point-mirrored (%s vs %s)" % [kind, wa, wb])
		# Local -Z faces the map centre.
		var fwd: Vector3 = -a.transform.basis.z
		var to_c: Vector3 = (-p).normalized()
		_check(fwd.dot(to_c) > 0.99, "%s: local -Z does not face the map centre" % kind)
		_check(a.position.is_equal_approx(Vector3(p.x, 0.0, p.z)), "%s: place_at position" % kind)
		a.queue_free()
		b.queue_free()
	var n1 := _site(&"mirefang")
	var n2 := _site(&"mirefang")
	if n1 and n2:
		n1.call(&"place_at", Vector3(-8.5, 0, -34), Vector3(1, 0, 8))
		n2.call(&"place_at", Vector3(8.5, 0, 34))
		var z: Vector3 = n1.transform.basis.z
		_check(z.dot(Vector3(1, 0, 8).normalized()) > 0.999, "mirefang: +Z is not the ford flow")
		_check(n1.transform.basis.is_equal_approx(n2.transform.basis), "mirefang: the two fords get different yaws")
		n1.queue_free()
		n2.queue_free()


func _start_anim() -> void:
	for kind: StringName in [&"gloomcap", &"bristleback"]:
		var s := _site(kind)
		if s:
			s.call(&"set_cleared", true)
			_anim.append(s)


func _param(s: Node3D, node: String, p: String) -> float:
	var gi := s.get_node_or_null(NodePath(node)) as GeometryInstance3D
	if gi == null:
		return -1.0
	var v: Variant = gi.get_instance_shader_parameter(p)
	return float(v) if v != null else -1.0


func _check_anim_glow() -> void:
	if _anim.size() < 2:
		return
	var lit := _param(_anim[0], "Base", "lit")
	_check(lit >= 0.0 and lit < 0.01, "gloomcap: glow not faded after 2 s (lit %.2f)" % lit)
	var wet := _param(_anim[1], "Base", "wet")
	_check(wet > 0.05 and wet < 0.95, "bristleback: the wallow should still be drying at 2 s (wet %.2f)" % wet)


func _check_anim_dry() -> void:
	if _anim.size() < 2:
		return
	var wet := _param(_anim[1], "Base", "wet")
	_check(wet >= 0.0 and wet < 0.01, "bristleback: the wallow is not dry after 7 s (wet %.2f)" % wet)
