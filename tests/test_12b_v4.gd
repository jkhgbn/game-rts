extends SceneTree
## Task 12b.V4: the ash set (art/environment/biomes/ash/), the static-scar particles and TerrainVfx (art/vfx/terrain_vfx.gd).
## Run:  $GODOT --headless --path . -s tests/test_12b_v4.gd --fixed-fps 60 --quit-after 2400
## Checks:
##  - ash_set.gd: the section-10 constants and ENTRIES keys, places &"ash" / &"ash_edge", <= 2 mesh kinds, shadows only on
##    the charred wood, ranges 90 / 65, items() loads every entry with the mesh's own material; the instance budget
##    (<= 200) on the static Cinder Scars of terrain.md 4.2 (2 x r 4.5 + their edge band);
##  - the meshes: one surface, indexed, the set's material, 3 variants with triangles each, heights within max_height,
##    the wood has smouldering (heat) and ember-heart parts, the grass is stiff (wind weight <= 0.12);
##  - ash_scar_fx.tscn: EmberMotes 16 additive unshaded quads + SmokeColumn 8, no light anywhere, no shadows;
##    AshSet.scar_fx() places it at the centre and scales it for another radius (clamped);
##  - TerrainVfx: group "terrain_vfx"; every id plays (default and explicit radius / seconds), unknown ids do nothing;
##    defaults (warnings 10 s, burn 6 s, radii 4.5 / 2.5); dedupe; no node, material or mesh created after _ready
##    (12 scorches at once included); the warning countdown uniform runs down; a burn / strike ends the warning at its
##    spot; the strike pulses the sun +0.3 for ~0.1 s and restores it exactly; fog hides scorch_spawn where the local
##    team does not see, never the weather events; hooks on a stub TerrainSystem (event_warning / event_started /
##    scorch_added, EVENT_KINDS radii, live_events catch-up); flame quads per burn <= 40; at the end nothing is left
##    alive and every pool is full again;
##  - if scripts/world/terrain_system.gd exists: it declares the signals the hooks use.
## Prints "PASS 12b.V4" or "FAIL 12b.V4: <reasons>".

const TASK_ID := "12b.V4"
const SET_PATH := "res://art/environment/biomes/ash/ash_set.gd"
const VFX_PATH := "res://art/vfx/terrain_vfx.gd"
const CHAR_SHADER := "res://art/environment/biomes/ash/ash_char.gdshader"
const NATURE_SHADER := "res://art/environment/nature_props/nature_painted.gdshader"
const TERRAIN_SYSTEM := "res://scripts/world/terrain_system.gd"
const PLACES: Array[StringName] = [&"ash", &"ash_edge"]
const TERRAIN_SRC := "extends Node\nsignal event_warning(kind: StringName, spots: Array, seconds: float)\nsignal event_started(kind: StringName, spots: Array)\nsignal event_ended(kind: StringName, spots: Array)\nsignal scorch_added(id: int, pos: Vector3, radius: float)\nsignal scorch_expired(id: int)\nconst EVENT_KINDS := {&\"wildfire\": {\"radius\": 4.5, \"burn\": 6.0, \"burn_dps\": 5.0, \"ash\": 90.0, \"weight\": 0.6}, &\"lightning\": {\"radius\": 2.5, \"strike\": 30.0, \"ash\": 60.0, \"weight\": 0.4}}\nfunc live_events() -> Array:\n\treturn [{\"kind\": &\"lightning\", \"spots\": [Vector3(-60, 0, 60), Vector3(60, 0, -60)], \"radius\": 2.5, \"state\": &\"warning\", \"time_left\": 4.0}]\n"
const FOG_SRC := "extends Node\nvar enabled: bool = true\nvar local_team: int = 0\nfunc is_visible(team: int, pos: Vector3) -> bool:\n\treturn pos.x < 100.0\n"

var _fails: Array[String] = []
var _frame := 0
var _world: Node3D
var _vfx: Node3D
var _terrain: Node
var _sun: DirectionalLight3D
var _children_before := 0
var _mats_before: Dictionary = {}
var _done := false
var _max_live := 0


func _initialize() -> void:
	_check_set()
	_check_meshes()
	_check_budget()
	_check_scar_fx()
	_check_contract()


func _setup() -> void:
	_world = Node3D.new()
	_world.name = "World"
	root.add_child(_world)
	current_scene = _world
	_sun = DirectionalLight3D.new()
	_sun.name = "Sun"
	_sun.shadow_enabled = true
	_sun.light_energy = 1.3
	_world.add_child(_sun)
	_terrain = _node(TERRAIN_SRC, &"terrain")
	_node(FOG_SRC, &"fog")
	var gs := load(VFX_PATH) as GDScript
	if gs == null:
		_fail("cannot load %s" % VFX_PATH)
		return
	_vfx = gs.new()
	_vfx.name = "TerrainVfx"
	# Before _ready: nothing, no error.
	_vfx.call(&"play", &"wildfire_warning", Vector3.ZERO, 4.5, 10.0)
	_world.add_child(_vfx)
	if get_first_node_in_group(&"terrain_vfx") != _vfx:
		_fail("TerrainVfx not in group terrain_vfx")
	_children_before = _vfx.get_child_count()
	_mats_before = _materials(_vfx)


func _node(src: String, group: StringName) -> Node:
	var s := GDScript.new()
	s.source_code = src
	s.reload()
	var n := Node.new()
	n.set_script(s)
	n.add_to_group(group)
	_world.add_child(n)
	return n


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_setup()
		return false
	if _vfx == null:
		return _finish_run()
	_max_live = maxi(_max_live, int(_vfx.call(&"live_count")))
	match _frame:
		3:
			_phase_hooks()
		6:
			_phase_play_all()
		36:
			_phase_half_second()
		66:
			_phase_one_second()
		75:
			_phase_sun_back()
		80:
			_phase_fog_and_pools()
		96:
			_phase_fog_check()
		1500:
			_final_checks()
			_done = true
	if _done:
		return _finish_run()
	return false


func _finish_run() -> bool:
	print("PASS %s" % TASK_ID if _fails.is_empty() else "FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	return true


func _fail(msg: String) -> void:
	_fails.append(msg)
	print("  fail: " + msg)


# ---------------------------------------------------------------- set / meshes / budget / scar fx

func _consts() -> Dictionary:
	var s := load(SET_PATH) as GDScript
	return s.get_script_constant_map() if s != null else {}


func _check_set() -> void:
	var s := load(SET_PATH) as GDScript
	if s == null:
		_fail("ash_set.gd missing")
		return
	var c: Dictionary = s.get_script_constant_map()
	if c.get("BIOME_ID") != &"ash":
		_fail("BIOME_ID is not &\"ash\"")
	if not (c.get("GROUND_TINT") is Color):
		_fail("GROUND_TINT is not a Color")
	if int(c.get("VARIANTS", 0)) != 3:
		_fail("VARIANTS is not 3")
	if int(c.get("INSTANCE_BUDGET", 0)) != 200:
		_fail("INSTANCE_BUDGET is not 200 (terrain.md 7.2)")
	var meshes := {}
	for e: Variant in c.get("ENTRIES", []):
		var d: Dictionary = e
		for key: String in ["id", "mesh", "material", "per_100m2", "scale", "cluster", "shadow", "range", "place"]:
			if not d.has(key):
				_fail("entry %s without '%s'" % [d.get("id", "?"), key])
		var name: String = String(d.get("mesh", "")).get_file().get_basename()
		meshes[name] = true
		if not PLACES.has(d.get("place")):
			_fail("%s: place %s not in %s" % [d.get("id"), d.get("place"), PLACES])
		var sc: Vector2 = d.get("scale", Vector2.ZERO)
		if sc.x < 0.5 or sc.y > 2.0 or sc.x > sc.y:
			_fail("%s: bad scale %s" % [d.get("id"), sc])
		var wood: bool = name == "ash_charred_wood"
		if bool(d.get("shadow")) != wood:
			_fail("%s: shadow %s (only the stumps / logs cast shadows)" % [d.get("id"), d.get("shadow")])
		if absf(float(d.get("range", 0.0)) - (90.0 if wood else 65.0)) > 0.01:
			_fail("%s: range %s (spec: stumps 90, small 65)" % [d.get("id"), d.get("range")])
		var mat := load(String(d.get("material", ""))) as ShaderMaterial
		var mesh := load(String(d.get("mesh", ""))) as Mesh
		if mat == null or mesh == null:
			_fail("%s: mesh / material missing" % d.get("id"))
		elif mesh.surface_get_material(0) != mat:
			_fail("%s: the mesh's material is not the entry's material" % d.get("id"))
	if meshes.size() > 2:
		_fail("%d mesh kinds (terrain.md 7.2: <= 2)" % meshes.size())
	var items: Array = s.call(&"items")
	if items.size() != (c.get("ENTRIES", []) as Array).size():
		_fail("items() returned %d of %d entries" % [items.size(), (c["ENTRIES"] as Array).size()])
	for it: Dictionary in items:
		for key: String in ["mesh", "material", "density", "scale", "vis_end", "shadow", "variants", "place"]:
			if not it.has(key):
				_fail("items(): missing key %s" % key)
		if not (it.get("mesh") is Mesh) or not (it.get("material") is Material):
			_fail("items(): mesh / material not loaded")
	# The 12b.V6 reader (BiomeMap.load_items) keeps each row's own place (the grass mesh is listed twice).
	var bm := load("res://art/environment/biomes/biome_map.gd") as GDScript
	if bm != null and bm.has_method(&"load_items"):
		var rows: Array = bm.call(&"load_items", &"ash")
		var places: Array = []
		for it: Dictionary in rows:
			places.append(it.get("place"))
		if places != [&"ash", &"ash", &"ash_edge"]:
			_fail("BiomeMap.load_items(&\"ash\") places %s (expected [ash, ash, ash_edge])" % [places])


func _check_meshes() -> void:
	var c := _consts()
	var seen := {}
	for e: Variant in c.get("ENTRIES", []):
		var d: Dictionary = e
		var path: String = d["mesh"]
		if seen.has(path):
			continue
		seen[path] = true
		var mesh := load(path) as ArrayMesh
		if mesh == null:
			_fail("mesh %s missing" % path)
			continue
		var name := path.get_file().get_basename()
		if mesh.get_surface_count() != 1:
			_fail("%s: %d surfaces (1 expected)" % [name, mesh.get_surface_count()])
		var arr: Array = mesh.surface_get_arrays(0)
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		if idx.is_empty():
			_fail("%s: not indexed" % name)
			continue
		var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
		var uv2: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV2]
		var shader: Shader = (mesh.surface_get_material(0) as ShaderMaterial).shader
		var per := [0, 0, 0]
		var kinds := {}
		var max_ux := 0.0
		for t in range(0, idx.size(), 3):
			var m := int(uv2[idx[t]].x)
			kinds[int(uv2[idx[t]].y)] = true
			for k in 3:
				if m == 0 or ((m >> k) & 1) == 1:
					per[k] += 1
		for u: Vector2 in uv:
			max_ux = maxf(max_ux, u.x)
		for k in 3:
			if per[k] < 40:
				_fail("%s: variant %d has only %d triangles" % [name, k, per[k]])
		var top: float = mesh.get_aabb().end.y * (d["scale"] as Vector2).y
		if top > float(d.get("max_height", 99.0)) + 0.01:
			_fail("%s: %.2f m tall at max scale, max_height %s" % [name, top, d.get("max_height")])
		if name == "ash_charred_wood":
			if shader.resource_path != CHAR_SHADER:
				_fail("charred wood: shader %s" % shader.resource_path)
			if max_ux < 0.8:
				_fail("charred wood: no smouldering heat (max UV.x %.2f)" % max_ux)
			if not kinds.has(0) or not kinds.has(2):
				_fail("charred wood: kinds %s (char wood 0 + ember heart 2 expected)" % [kinds.keys()])
		else:
			if shader.resource_path != NATURE_SHADER:
				_fail("burnt grass: shader %s (the shared nature_mat)" % shader.resource_path)
			if max_ux > 0.12:
				_fail("burnt grass: wind weight %.2f (burnt grass is stiff, <= 0.12)" % max_ux)


## Static Cinder Scars (terrain.md 4.2): 2 x ellipse 4.5 x 4.5 = &"ash"; the 0.2-0.5 weight band of the 1 m noisy edge
## counted generously as 0.5 m wide.
func _check_budget() -> void:
	var c := _consts()
	var inside: float = 2.0 * PI * 4.5 * 4.5
	var edge: float = 2.0 * TAU * 4.75 * 0.5
	var total := 0.0
	for e: Variant in c.get("ENTRIES", []):
		var d: Dictionary = e
		var area: float = inside if d["place"] == &"ash" else edge
		total += float(d["per_100m2"]) * area / 100.0
	print("  ash budget: %.0f instances on %.0f m2 inside + %.0f m2 edge (max %d)" % [total, inside, edge,
			int(c.get("INSTANCE_BUDGET", 200))])
	if total > float(c.get("INSTANCE_BUDGET", 200)):
		_fail("ash decor %.0f instances > budget 200" % total)
	if total < 100.0:
		_fail("ash decor only %.0f instances: the scars would look bare" % total)


func _check_scar_fx() -> void:
	var c := _consts()
	var path: String = c.get("SCAR_FX", "")
	if not ResourceLoader.exists(path):
		_fail("scar fx scene missing: %s" % path)
		return
	var n := (load(path) as PackedScene).instantiate() as Node3D
	var parts := {}
	for ch in n.find_children("*", "", true, false):
		if ch is Light3D:
			_fail("scar fx has a light: %s" % ch.name)
		if ch is GPUParticles3D:
			var p := ch as GPUParticles3D
			parts[String(p.name)] = p
			if p.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
				_fail("scar fx %s casts shadows" % p.name)
	var motes: GPUParticles3D = parts.get("EmberMotes")
	var smoke: GPUParticles3D = parts.get("SmokeColumn")
	if motes == null or smoke == null:
		_fail("scar fx: EmberMotes / SmokeColumn missing (%s)" % [parts.keys()])
	else:
		if motes.amount != 16:
			_fail("EmberMotes amount %d (spec 16)" % motes.amount)
		if smoke.amount != 8:
			_fail("SmokeColumn amount %d (spec 8)" % smoke.amount)
		var mm := (motes.draw_pass_1 as QuadMesh).material as StandardMaterial3D
		if mm == null or mm.blend_mode != BaseMaterial3D.BLEND_MODE_ADD \
				or mm.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED:
			_fail("EmberMotes are not additive unshaded (emissive) quads")
	n.free()
	var s := load(SET_PATH) as GDScript
	var a: Node3D = s.call(&"scar_fx", Vector3(-31.0, 0.0, 2.0), 4.5)
	if a == null or a.position.distance_to(Vector3(-31.0, 0.0, 2.0)) > 0.001 or not a.transform.basis.is_equal_approx(Basis.IDENTITY):
		_fail("scar_fx(centre, 4.5) is not at the centre / unscaled")
	var b: Node3D = s.call(&"scar_fx", Vector3(31.0, 0.0, -2.0), 20.0)
	if b == null or absf(b.transform.basis.get_scale().x - 1.6) > 0.001:
		_fail("scar_fx(radius 20) scale not clamped to 1.6")
	if a:
		a.free()
	if b:
		b.free()


func _check_contract() -> void:
	if not FileAccess.file_exists(TERRAIN_SYSTEM):
		print("  (no scripts/world/terrain_system.gd yet: hook contract checked against the spec stub only)")
		return
	var src := FileAccess.get_file_as_string(TERRAIN_SYSTEM)
	for sig: String in ["signal event_warning(", "signal event_started(", "signal scorch_added("]:
		if not src.contains(sig):
			_fail("terrain_system.gd does not declare '%s' (TerrainVfx hooks it)" % sig)


# ---------------------------------------------------------------- TerrainVfx

func _fx_list() -> Array:
	return _vfx.get(&"_fx")


func _find_fx(id: StringName, at: Vector3) -> Object:
	for fx: Object in _fx_list():
		if fx.get(&"id") == id and (fx.get(&"point") as Vector3).distance_to(at) < 0.5:
			return fx
	return null


func _phase_hooks() -> void:
	# The first frame scanned the hooks: the stub's live warning was caught up (2 storm warnings, 4 s left).
	var hooked: Dictionary = _vfx.get(&"_hooked")
	if not hooked.has(_terrain.get_instance_id()):
		_fail("not hooked to the TerrainSystem stub")
	var cu := _find_fx(&"storm_warning", Vector3(-60, 0, 60))
	if cu == null or absf(float(cu.get(&"seconds")) - 4.0) > 0.01:
		_fail("live_events warning not caught up (storm_warning 4 s at (-60, 0, 60))")
	_terrain.emit_signal(&"event_warning", &"wildfire", [Vector3(-40, 0, 40), Vector3(40, 0, -40)], 10.0)
	for p: Vector3 in [Vector3(-40, 0, 40), Vector3(40, 0, -40)]:
		var fx := _find_fx(&"wildfire_warning", p)
		if fx == null:
			_fail("event_warning(wildfire) did not play wildfire_warning at %s" % p)
		elif absf(float(fx.get(&"radius")) - 4.5) > 0.01 or absf(float(fx.get(&"seconds")) - 10.0) > 0.01:
			_fail("hooked wildfire_warning radius %s seconds %s (4.5 / 10)" % [fx.get(&"radius"), fx.get(&"seconds")])
	_terrain.emit_signal(&"event_started", &"lightning", [Vector3(-60, 0, 60), Vector3(60, 0, -60)])
	for p: Vector3 in [Vector3(-60, 0, 60), Vector3(60, 0, -60)]:
		var fx := _find_fx(&"lightning_strike", p)
		if fx == null:
			_fail("event_started(lightning) did not play lightning_strike at %s" % p)
		elif absf(float(fx.get(&"radius")) - 2.5) > 0.01:
			_fail("hooked strike radius %s (2.5)" % fx.get(&"radius"))
		var w := _find_fx(&"storm_warning", p)
		if w != null and float(w.get(&"end_at")) < 0.0:
			_fail("the strike did not end the storm warning at %s" % p)
	if absf(_sun.light_energy - 1.6) > 0.001:
		_fail("sun not pulsed by the strike (%.2f, expected 1.6)" % _sun.light_energy)
	_terrain.emit_signal(&"scorch_added", 7, Vector3(-25, 0, 10), 2.5)
	if _find_fx(&"scorch_spawn", Vector3(-25, 0, 10)) == null:
		_fail("scorch_added did not play scorch_spawn")
	# The same event again (hook + direct call in the same frame): plays once.
	var before: int = _vfx.call(&"active_count")
	_vfx.call(&"play", &"scorch_spawn", Vector3(-25, 0, 10), 2.5)
	if int(_vfx.call(&"active_count")) != before:
		_fail("same id + spot within 0.3 s played twice")


func _phase_play_all() -> void:
	var before: int = _vfx.call(&"active_count")
	_vfx.call(&"play", &"not_a_terrain_effect", Vector3.ZERO, 1.0)
	if int(_vfx.call(&"active_count")) != before:
		_fail("an unknown id started something")
	var ids: Array = _vfx.get(&"EFFECTS")
	for i in ids.size():
		var id: StringName = ids[i]
		# Explicit radius / seconds (short warnings for the timing checks)...
		var sec := 2.0 if String(id).ends_with("warning") else (1.5 if id == &"wildfire_burn" else 0.0)
		_vfx.call(&"play", id, Vector3(-20.0 + 8.0 * i, 0.0, -20.0), 3.0, sec)
		if _find_fx(id, Vector3(-20.0 + 8.0 * i, 0.0, -20.0)) == null:
			_fail("%s did not play" % id)
		# ...and the defaults.
		_vfx.call(&"play", id, Vector3(-20.0 + 8.0 * i, 0.0, 20.0))
		var fx := _find_fx(id, Vector3(-20.0 + 8.0 * i, 0.0, 20.0))
		if fx == null:
			_fail("%s with defaults did not play" % id)
			continue
		var want_r: float = (_vfx.get(&"DEFAULT_RADIUS") as Dictionary)[id]
		if absf(float(fx.get(&"radius")) - want_r) > 0.01:
			_fail("%s default radius %s (expected %s)" % [id, fx.get(&"radius"), want_r])
		if id == &"wildfire_warning" or id == &"storm_warning":
			if absf(float(fx.get(&"seconds")) - 10.0) > 0.01:
				_fail("%s default seconds %s (10)" % [id, fx.get(&"seconds")])
		if id == &"wildfire_burn" and absf(float(fx.get(&"seconds")) - 6.0) > 0.01:
			_fail("wildfire_burn default seconds %s (6)" % fx.get(&"seconds"))
	# Budget of one burn: flames + embers <= 40 quads.
	var streams: Dictionary = _vfx.get(&"STREAMS")
	var quads: int = int(streams[&"flames"][0]) + int(streams[&"fire_embers"][0])
	if quads > 40:
		_fail("wildfire_burn draws %d flame / ember quads (<= 40)" % quads)
	if _vfx.get_child_count() != _children_before or _materials(_vfx) != _mats_before:
		_fail("nodes / materials created at runtime")
	# A warning ended by the burn at its spot (a 2 s warning at (60, 0, 0), then the burn).
	_vfx.call(&"play", &"wildfire_warning", Vector3(60, 0, 0), 4.5, 2.0)
	_vfx.call(&"play", &"wildfire_burn", Vector3(60, 0, 0), 4.5, 1.0)
	var w := _find_fx(&"wildfire_warning", Vector3(60, 0, 0))
	if w == null or float(w.get(&"end_at")) < 0.0:
		_fail("wildfire_burn did not end the wildfire warning at its spot")


func _phase_half_second() -> void:
	# 0.5 s into the 2 s warnings: the countdown is at ~0.75.
	var fx := _find_fx(&"wildfire_warning", Vector3(-12.0, 0.0, -20.0))
	if fx == null:
		_fail("2 s wildfire warning gone at 0.5 s")
		return
	var ring: Object = (fx.get(&"named") as Dictionary).get(&"ring")
	if ring == null:
		_fail("wildfire warning has no ring")
		return
	var left: float = (ring.get(&"n") as GeometryInstance3D).get_instance_shader_parameter(&"left")
	if absf(left - 0.75) > 0.05:
		_fail("countdown 'left' %.2f at 0.5 s of 2 s (expected ~0.75)" % left)
	if not (ring.get(&"n") as GeometryInstance3D).visible:
		_fail("warning ring not visible")


func _phase_one_second() -> void:
	if _find_fx(&"storm_warning", Vector3(-60, 0, 60)) != null:
		_fail("storm warning still running 1 s after the strike ended it")


func _phase_sun_back() -> void:
	if absf(_sun.light_energy - 1.3) > 0.0001:
		_fail("sun energy %.3f after the pulse (expected 1.3 exactly)" % _sun.light_energy)


func _phase_fog_and_pools() -> void:
	# Fog stub: x >= 100 is not seen by the local team.
	_vfx.call(&"play", &"scorch_spawn", Vector3(150, 0, 0), 2.5)
	_vfx.call(&"play", &"storm_warning", Vector3(150, 0, 30), 2.5, 2.0)
	_vfx.call(&"play", &"scorch_spawn", Vector3(50, 0, 50), 2.5)
	# 12 scorches at once: pools run dry gracefully, nothing is allocated.
	for i in 12:
		_vfx.call(&"play", &"scorch_spawn", Vector3(-50.0 + 4.0 * i, 0.0, 70.0), 2.5)
	if _vfx.get_child_count() != _children_before or _materials(_vfx) != _mats_before:
		_fail("nodes / materials created when the pools ran out")


func _phase_fog_check() -> void:
	var hidden := _find_fx(&"scorch_spawn", Vector3(150, 0, 0))
	var seen := _find_fx(&"scorch_spawn", Vector3(50, 0, 50))
	var storm := _find_fx(&"storm_warning", Vector3(150, 0, 30))
	if hidden == null or seen == null or storm == null:
		_fail("fog test effects missing")
		return
	for d: Object in hidden.get(&"pieces"):
		if (d.get(&"n") as GeometryInstance3D).visible:
			_fail("scorch_spawn visible where the local team does not see")
			break
	var any := false
	for d: Object in seen.get(&"pieces"):
		any = any or (d.get(&"n") as GeometryInstance3D).visible
	if not any:
		_fail("scorch_spawn hidden where the local team sees")
	any = false
	for d: Object in storm.get(&"pieces"):
		any = any or (d.get(&"n") as GeometryInstance3D).visible
	if not any:
		_fail("storm_warning hidden by fog (weather is public)")


func _final_checks() -> void:
	if _max_live < 20:
		_fail("barely anything was drawn (max live %d)" % _max_live)
	if int(_vfx.call(&"active_count")) != 0:
		_fail("effects still running at the end: %s" % [_vfx.call(&"active_ids")])
	if int(_vfx.call(&"live_count")) != 0:
		_fail("pieces / bursts / streams still alive at the end (%d)" % _vfx.call(&"live_count"))
	var free: Dictionary = _vfx.get(&"_free")
	var sizes: Dictionary = _vfx.get(&"MESH_POOLS")
	for pool: StringName in sizes:
		if (free[pool] as Array).size() != int(sizes[pool]):
			_fail("pool %s: %d free of %d (leak)" % [pool, (free[pool] as Array).size(), sizes[pool]])
	var sfree: Dictionary = _vfx.get(&"_stream_free")
	var streams: Dictionary = _vfx.get(&"STREAMS")
	for look: StringName in streams:
		if (sfree[look] as Array).size() != int(streams[look][3]):
			_fail("stream pool %s: %d free of %d (leak)" % [look, (sfree[look] as Array).size(), streams[look][3]])
	for c in _vfx.get_children():
		if (c is GPUParticles3D or c is MeshInstance3D) and (c as Node3D).visible:
			_fail("%s still visible at the end" % c.name)
			break
	if _vfx.get_child_count() != _children_before or _materials(_vfx) != _mats_before:
		_fail("nodes / materials created during the run")
	if absf(_sun.light_energy - 1.3) > 0.0001:
		_fail("sun energy not restored (%.3f)" % _sun.light_energy)


## Instance ids of every material, mesh and process material the pools use.
func _materials(v: Node) -> Dictionary:
	var out: Dictionary = {}
	for c in v.get_children():
		if c is MeshInstance3D:
			out[(c as MeshInstance3D).material_override.get_instance_id()] = true
			out[(c as MeshInstance3D).mesh.get_instance_id()] = true
		elif c is GPUParticles3D:
			var p := c as GPUParticles3D
			out[p.process_material.get_instance_id()] = true
			out[p.draw_pass_1.get_instance_id()] = true
			out[(p.draw_pass_1 as PrimitiveMesh).material.get_instance_id()] = true
	return out
