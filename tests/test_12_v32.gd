extends SceneTree
## Task 12.V32: epic-beast lairs (map-fill.md 5.5 + section 10): art/environment/lairs/<scene>.tscn, draw-only,
## `set_occupied(bool)`.
## Run: $GODOT --headless --path . -s tests/test_12_v32.gd --fixed-fps 60 --quit-after 900
## Checks:
## - the four scenes exist; root = LairArt (lair_art.gd), group "lairs", metadata lair_kind / beast_rest / decor_clear;
##   children Model (casts shadows), Active, Dormant (MeshInstance3D, no material override);
## - draw-only: no CollisionObject3D / CollisionShape3D, 0 lights, no particles;
## - shared materials only (nature_mat / nature_contact_mat / Old Wood cobweb mat), meshes saved under lairs/meshes/,
##   every surface indexed; budgets: Model <= 10 000 triangles, Active / Dormant <= 2 000 each;
## - set_occupied: starts empty (Dormant shown, Active hidden), true -> Active shown / Dormant hidden, false -> back;
## - LairArt.scene_path_for() covers every lair of EpicBeasts.default_lairs() (load-guarded) with the right kind, and
##   yaw_for() is PI on the east bank;
## - fits on the real spots (both banks, point mirror = position -p, yaw PI):
##     crag: branches of the nest lie ON the Fallen Colossus head (vertices >= 1.6 m high inside the head collider),
##           the nest crown is >= 2.4 m high;
##     den: the boulder (vertices >= 1.2 m) stands within 7.5 m of the aqueduct pier, nothing in the river water,
##          everything inside the map edge (|x|, |z| <= 60.3);
##     heath: no geometry taller than 0.45 m within 0.3 m of a Standing Stones collider;
##     all: everything within 9 m of the lair centre, hollow and wallow clutter low (< 1.6 m);
## - decor_clear_circles() returns world circles around the placed lair.
## Prints "PASS 12.v32" or "FAIL 12.v32: <reasons>".

const TASK_ID := "12.v32"
const DIR := "res://art/environment/lairs/"
const MATS: Array[String] = ["res://art/environment/nature_props/nature_mat.tres",
	"res://art/environment/nature_props/nature_contact_mat.tres",
	"res://art/environment/biomes/old_wood/old_wood_web_mat.tres"]
const SCENES := {
	"heath_wallow.tscn": {"kind": &"tusker", "lair": &"lair_heath_w", "center": Vector3(-53, 0, 13)},
	"crag_nest.tscn": {"kind": &"roc", "lair": &"lair_crag_w", "center": Vector3(-53, 0, -18)},
	"greymane_hollow.tscn": {"kind": &"direwolf", "lair": &"lair_hollow_w", "center": Vector3(-56, 0, -34)},
	"old_wood_den.tscn": {"kind": &"grizzlemaw", "lair": &"lair_den_w", "center": Vector3(-26, 0, -54)},
}
const COLOSSUS := Vector3(-57.0, 0.0, -16.0)
const HEAD_CENTER := Vector3(1.0, 0.0, -0.7)   # landmarks: head collider axis (colossus space)
const HEAD_R := 2.2
const PIER_W := Vector3(-17.5, 0.0, -55.0)
const STONES := Vector3(-54.0, 0.0, 20.0)
const RIVER_N: Array[Vector2] = [Vector2(-15, -62), Vector2(-12, -48.7), Vector2(-9, -38), Vector2(-8, -30), Vector2(-5, -21),
	Vector2(-2.5, -12.5)]
const HALF_W := 2.5

var _fails: PackedStringArray = PackedStringArray()
var _holder: Node3D
var _frame := 0
var _lairs: Array[Node3D] = []


func _initialize() -> void:
	_holder = Node3D.new()
	root.add_child(_holder)
	for file: String in SCENES:
		var path: String = DIR + file
		_check(ResourceLoader.exists(path), "%s exists" % path)
		if not ResourceLoader.exists(path):
			continue
		for mirror: bool in [false, true]:
			var lair := (load(path) as PackedScene).instantiate() as Node3D
			_check(lair != null, "%s: root is a Node3D" % file)
			if lair == null:
				continue
			var c: Vector3 = SCENES[file]["center"]
			lair.position = -c if mirror else c
			lair.rotation.y = PI if mirror else 0.0
			lair.set_meta(&"_test_file", file)
			lair.set_meta(&"_test_mirror", mirror)
			_holder.add_child(lair)
			_lairs.append(lair)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 3:   # global transforms and _ready are live from here
		return false
	for lair: Node3D in _lairs:
		_check_lair(lair)
	_check_mapping()
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	return true


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  FAILED: ", what)


func _river_dist(p: Vector2) -> float:
	var best := INF
	for i in RIVER_N.size() - 1:
		var a: Vector2 = RIVER_N[i]
		var ab: Vector2 = RIVER_N[i + 1] - a
		var t: float = clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		best = minf(best, p.distance_to(a + ab * t))
	return best


## World-space vertices of a MeshInstance3D's painted surface (surface 0).
func _world_verts(mi: MeshInstance3D) -> PackedVector3Array:
	var out := PackedVector3Array()
	if mi == null or mi.mesh == null or mi.mesh.get_surface_count() == 0:
		return out
	var v: PackedVector3Array = mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var xf: Transform3D = mi.global_transform
	for p: Vector3 in v:
		out.append(xf * p)
	return out


func _check_lair(lair: Node3D) -> void:
	var file: String = lair.get_meta(&"_test_file")
	var mirror: bool = lair.get_meta(&"_test_mirror")
	var tag: String = file + (" (east)" if mirror else "")
	var spec: Dictionary = SCENES[file]
	var s: float = -1.0 if mirror else 1.0
	# --- root, script, metadata ---
	_check(lair.has_method(&"set_occupied") and lair.has_method(&"is_occupied") and lair.has_method(&"decor_clear_circles"),
		"%s: root has set_occupied / is_occupied / decor_clear_circles" % tag)
	_check(lair.get_script() != null and (lair.get_script() as Script).resource_path == DIR + "lair_art.gd",
		"%s: root script is lair_art.gd" % tag)
	_check(lair.is_in_group(&"lairs"), "%s: in group lairs" % tag)
	_check(lair.get_meta(&"lair_kind", &"") == spec["kind"], "%s: lair_kind %s" % [tag, spec["kind"]])
	_check(lair.get_meta(&"beast_rest", null) is Vector3, "%s: beast_rest metadata" % tag)
	var clear: Variant = lair.get_meta(&"decor_clear", null)
	_check(clear is PackedVector3Array and not (clear as PackedVector3Array).is_empty(), "%s: decor_clear metadata" % tag)
	# --- draw-only ---
	_check(lair.find_children("*", "CollisionObject3D", true, false).is_empty() and
		lair.find_children("*", "CollisionShape3D", true, false).is_empty(), "%s: draw-only (no collider)" % tag)
	_check(lair.find_children("*", "Light3D", true, false).is_empty(), "%s: 0 lights" % tag)
	_check(lair.find_children("*", "GPUParticles3D", true, false).is_empty() and lair.find_children("*", "CPUParticles3D",
		true, false).is_empty(), "%s: no particles" % tag)
	# --- meshes, materials, budgets ---
	var parts := {}
	for name: String in ["Model", "Active", "Dormant"]:
		var mi := lair.get_node_or_null(name) as MeshInstance3D
		_check(mi != null and mi.mesh != null, "%s: %s MeshInstance3D with a mesh" % [tag, name])
		if mi == null or mi.mesh == null:
			continue
		parts[name] = mi
		_check(mi.material_override == null, "%s: %s has no material override" % [tag, name])
		_check(mi.mesh.resource_path.begins_with(DIR + "meshes/"), "%s: %s mesh saved under lairs/meshes (%s)" % [tag, name,
			mi.mesh.resource_path])
		var tris := 0
		for si in mi.mesh.get_surface_count():
			var m: Material = mi.mesh.surface_get_material(si)
			_check(m != null and m.resource_path in MATS and m == load(m.resource_path), "%s: %s surface %d uses a shared material (%s)"
				% [tag, name, si, m.resource_path if m else "none"])
			var idx: Variant = mi.mesh.surface_get_arrays(si)[Mesh.ARRAY_INDEX]
			_check(idx is PackedInt32Array and not (idx as PackedInt32Array).is_empty(), "%s: %s surface %d indexed" % [tag, name, si])
			if idx is PackedInt32Array:
				tris += (idx as PackedInt32Array).size() / 3
		var cap: int = 10000 if name == "Model" else 2000
		_check(tris <= cap, "%s: %s <= %d triangles (%d)" % [tag, name, cap, tris])
		if not mirror:
			print("%-22s %-8s %5d tris, %d surfaces" % [file, name, tris, mi.mesh.get_surface_count()])
	if parts.has("Model"):
		_check((parts["Model"] as MeshInstance3D).cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
			"%s: Model casts shadows" % tag)
	# --- set_occupied ---
	if parts.has("Active") and parts.has("Dormant"):
		var act := parts["Active"] as MeshInstance3D
		var dor := parts["Dormant"] as MeshInstance3D
		_check(not act.visible and dor.visible and not bool(lair.call(&"is_occupied")), "%s: starts empty (Dormant shown)" % tag)
		lair.call(&"set_occupied", true)
		_check(act.visible and not dor.visible and bool(lair.call(&"is_occupied")), "%s: set_occupied(true) shows Active" % tag)
		lair.call(&"set_occupied", false)
		_check(not act.visible and dor.visible and not bool(lair.call(&"is_occupied")), "%s: set_occupied(false) shows Dormant" % tag)
	# --- decor circles ---
	var circles: PackedVector3Array = lair.call(&"decor_clear_circles")
	_check(not circles.is_empty() and Vector2(circles[0].x - lair.position.x, circles[0].y - lair.position.z).length() < 6.0,
		"%s: decor_clear_circles in world space near the lair" % tag)
	# --- fits on the real spots ---
	if not parts.has("Model"):
		return
	var verts: PackedVector3Array = _world_verts(parts["Model"])
	for name2: String in ["Active", "Dormant"]:
		if parts.has(name2):
			verts.append_array(_world_verts(parts[name2]))
	var top := -INF
	var far := 0.0
	for p: Vector3 in verts:
		top = maxf(top, p.y)
		far = maxf(far, Vector2(p.x - lair.position.x, p.z - lair.position.z).length())
	_check(far <= 9.0, "%s: everything within 9 m of the centre (%.1f)" % [tag, far])
	match file:
		"crag_nest.tscn":
			var head: Vector3 = (COLOSSUS + HEAD_CENTER) * s
			var on_head := 0
			for p2: Vector3 in verts:
				if p2.y >= 1.6 and Vector2(p2.x - head.x, p2.z - head.z).length() < HEAD_R:
					on_head += 1
			_check(on_head >= 40, "%s: nest branches lie on the Colossus head (%d vertices >= 1.6 m over it)" % [tag, on_head])
			_check(top >= 2.4, "%s: nest crown >= 2.4 m (%.2f)" % [tag, top])
			print("%-22s %d nest vertices over the head, crown %.2f m" % [tag, on_head, top])
		"old_wood_den.tscn":
			var pier: Vector3 = PIER_W * s
			var rock_near := INF
			var wet := 0
			var outside := 0
			for p3: Vector3 in verts:
				if p3.y >= 1.2:
					rock_near = minf(rock_near, Vector2(p3.x - pier.x, p3.z - pier.z).length())
				if p3.y > -0.2 and _river_dist(Vector2(p3.x * s, p3.z * s)) < HALF_W + 0.2:
					wet += 1
				if absf(p3.x) > 60.3 or absf(p3.z) > 60.3:
					outside += 1
			_check(rock_near <= 7.5, "%s: the den boulder stands by the aqueduct pier (%.1f m)" % [tag, rock_near])
			_check(wet == 0, "%s: nothing in the river water (%d vertices)" % [tag, wet])
			_check(outside == 0, "%s: inside the map edge (%d vertices outside)" % [tag, outside])
			print("%-22s boulder %.1f m from the pier, %d wet, %d outside" % [tag, rock_near, wet, outside])
		"heath_wallow.tscn":
			var stones := (load("res://art/environment/landmarks/standing_stones.tscn") as PackedScene).instantiate() as Node3D \
				if ResourceLoader.exists("res://art/environment/landmarks/standing_stones.tscn") else null
			if stones:
				_holder.add_child(stones)
				stones.position = STONES * s
				stones.rotation.y = PI if mirror else 0.0
				var cols: Array[Vector3] = []
				for cs: Node in stones.find_children("*", "CollisionShape3D", true, false):
					var cp: Vector3 = (cs as Node3D).global_position
					var r: float = ((cs as CollisionShape3D).shape as CylinderShape3D).radius if (cs as CollisionShape3D).shape is CylinderShape3D else 0.5
					cols.append(Vector3(cp.x, r, cp.z))
				var clash := 0
				for p4: Vector3 in verts:
					if p4.y > 0.45:
						for c4: Vector3 in cols:
							if Vector2(p4.x - c4.x, p4.z - c4.z).length() < c4.y + 0.3:
								clash += 1
				_check(clash == 0, "%s: clear of the Standing Stones (%d vertices clash)" % [tag, clash])
				stones.queue_free()
			_check(top < 1.6, "%s: wallow clutter low (top %.2f)" % [tag, top])
		"greymane_hollow.tscn":
			_check(top < 1.6, "%s: hollow clutter low (top %.2f)" % [tag, top])


## LairArt's lair-id -> scene mapping covers EpicBeasts.default_lairs() (both loaded by path, guarded).
func _check_mapping() -> void:
	var la_path := DIR + "lair_art.gd"
	_check(ResourceLoader.exists(la_path), "lair_art.gd exists")
	if not ResourceLoader.exists(la_path):
		return
	var la := load(la_path) as GDScript
	var eb_path := "res://scripts/world/epic_beasts.gd"
	if not ResourceLoader.exists(eb_path):
		print("epic_beasts.gd missing: mapping check skipped")
		return
	var eb := load(eb_path) as GDScript
	var lairs: Array = eb.call(&"default_lairs")
	_check(lairs.size() == 8, "EpicBeasts.default_lairs() has 8 lairs (%d)" % lairs.size())
	for l: Dictionary in lairs:
		var id: StringName = l["id"]
		var path: String = la.call(&"scene_path_for", id, l["kind"])
		_check(path != "" and ResourceLoader.exists(path), "scene_path_for(%s) -> an existing scene (%s)" % [id, path])
		if path != "" and ResourceLoader.exists(path):
			var inst := (load(path) as PackedScene).instantiate()
			_check(inst.get_meta(&"lair_kind", &"") == l["kind"], "%s: scene kind %s matches" % [id, l["kind"]])
			inst.free()
		var yaw: float = la.call(&"yaw_for", id)
		var want: float = PI if String(id).ends_with("_e") else 0.0
		_check(is_equal_approx(yaw, want), "yaw_for(%s) = %.2f" % [id, want])
		# The scene's default fit centre is the lair centre: west lairs at +c, east at -c.
		var c: Vector3 = l["center"]
		var base: Vector3 = SCENES[String(path.get_file())]["center"] if SCENES.has(path.get_file()) else c
		_check(c.is_equal_approx(base) or c.is_equal_approx(-base), "%s: centre %s is the scene's fit spot (or its mirror)" % [id, c])
	_check(String(la.call(&"scene_path_for", &"unknown_lair", &"roc")).ends_with("crag_nest.tscn"),
		"scene_path_for falls back on the kind")
