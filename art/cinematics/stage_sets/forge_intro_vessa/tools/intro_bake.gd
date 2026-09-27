extends SceneTree
## Prologue P4 polish (2026-09-27): bakes the four wizard vignettes' extra props, which the .set files then use as
## `actor` lines (so the cine can show / hide / move them per shot):
##   army_<name>.tscn : a whole formation of real unit models (their own scenes, posed mid-attack / mid-cast / dead by
##                      running their CharacterModel animation for a few fixed frames), merged into ONE mesh with 2-3
##                      surfaces (painted parts -> vertex colours, glowing parts -> army_glow.gdshader). 0 lights.
##   fx_*.tscn        : static / looping spell props (emissive sheets + GPUParticles3D with a fixed seed and fixed_fps,
##                      TIME-only shaders): fire pillar, ember rain, arrow volley, shadow vortex, tendrils, ice wall...
## Run (writes into art/cinematics/stage_sets/forge_intro_<wizard>/{props,fx}/):
##   tools\godot_run.ps1 --headless --path . -s res://art/cinematics/stage_sets/forge_intro_vessa/tools/intro_bake.gd
##       --fixed-fps 30 --quit-after 20000 '--' only=vessa,malrik part=army,fx
## Deterministic: fixed frame counts, hashed jitter, fixed particle seeds.

const ROOT := "res://art/cinematics/stage_sets/"
const SH_ADD := "res://art/cinematics/stage_sets/forge_intro_vessa/fx/fx_add.gdshader"
const SH_VEIL := "res://art/cinematics/stage_sets/forge_intro_vessa/fx/fx_veil.gdshader"
const SH_SOLID := "res://art/cinematics/stage_sets/forge_intro_vessa/fx/fx_solid.gdshader"
const SH_ARMY_GLOW := "res://art/cinematics/stage_sets/forge_intro_vessa/fx/army_glow.gdshader"

const U := "res://art/units/"
const FLAME_GUARD := U + "fire/flame_guard.tscn"
const SCORCHBOW := U + "fire/scorchbow/scorchbow.tscn"
const PYRE_ADEPT := U + "fire/pyre_adept/pyre_adept.tscn"
const CINDERLOCK := U + "fire/cinderlock/cinderlock.tscn"
const ASH_HURLER := U + "fire/ash_hurler.tscn"
const CINDER_HAND := U + "fire/cinder_hand.tscn"
const BLAZE_RIDER := U + "fire/blaze_rider.tscn"
const SHADE := U + "shadow/shade.tscn"
const SKNIGHT := U + "shadow/shadow_knight.tscn"
const HEXWEAVER := U + "shadow/hexweaver/hexweaver.tscn"
const BLEAKBOW := U + "shadow/bleakbow/bleakbow.tscn"
const HOUND := U + "shadow/grave_hound.tscn"
const THRALL := U + "shadow/gloom_thrall.tscn"
const BARROW := U + "shadow/barrow_giant/barrow_giant.tscn"
const NIGHTMARE := U + "titans/nightmare_knight/nightmare_knight.tscn"
const RIMESHIELD := U + "ice/rimeshield.tscn"
const FROSTBOW := U + "ice/frostbow/frostbow.tscn"
const RIFLEMAN := U + "ice/frostrune_rifleman/frostrune_rifleman.tscn"
const SHARDCASTER := U + "ice/shardcaster.tscn"
const MAMMOTH := U + "titans/war_mammoth/war_mammoth.tscn"
const COLOSSUS := U + "ice/rime_colossus.tscn"
const VINELASHER := U + "nature/vinelasher/vinelasher.tscn"
const WILDWOOD := U + "nature/wildwood_archer/wildwood_archer.tscn"
const BRAMBLEHORN := U + "nature/bramblehorn.tscn"
const THORNLING := U + "nature/thornling.tscn"
const STAGRUNNER := U + "nature/stagrunner/stagrunner.tscn"
const MOSSBACK := U + "nature/mossback/mossback.tscn"

const TOTAL_FRAMES := 96
const ADD_GAIN := 0.42

var only: PackedStringArray = PackedStringArray(["vessa", "malrik", "torvald", "ysolde"])
var parts: PackedStringArray = PackedStringArray(["army", "fx"])
var _paint_mat: StandardMaterial3D
var _glow_mat: ShaderMaterial


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("only="):
			only = a.substr(5).split(",")
		elif a.begins_with("part="):
			parts = a.substr(5).split(",")
	_run.call_deferred()


func _run() -> void:
	await process_frame
	_paint_mat = StandardMaterial3D.new()
	_paint_mat.vertex_color_use_as_albedo = true
	_paint_mat.vertex_color_is_srgb = true
	_paint_mat.roughness = 0.82
	_paint_mat.rim_enabled = true
	_paint_mat.rim = 0.25
	_glow_mat = ShaderMaterial.new()
	_glow_mat.shader = load(SH_ARMY_GLOW)
	for w in only:
		if parts.has("fx"):
			call("_fx_" + w)
		if parts.has("army"):
			for job: Dictionary in call("_armies_" + w):
				await _bake_army(w, job)
	print("intro_bake: done")
	quit(0)


# ================================================================ formations

static func h01(a: float, b: float, s: int) -> float:
	var h := int(floor(a * 97.0)) * 73856093 ^ int(floor(b * 89.0)) * 19349663 ^ s * 83492791
	h = (h ^ (h >> 13)) * 1274126177
	return float((h ^ (h >> 16)) & 0xffff) / 65535.0


## One unit: scene, set position (x, y, z), yaw deg, action (idle / attack / cast / death / walk), frames before capture.
static func unit(scene: String, p: Vector3, yaw: float, act := "idle", f := 12, scale := 1.0, rot := Vector3.ZERO) -> Dictionary:
	return {"scene": scene, "pos": p, "yaw": yaw, "act": act, "f": f, "scale": scale, "rot": rot}


## A block of cols x rows units centred on c (set coordinates), facing yaw; hashed jitter + pose-time variety.
static func block(scene: String, c: Vector3, cols: int, rows: int, dx: float, dz: float, yaw: float, act: String, f: int,
		seed: int, scale := 1.0, jit := 0.25) -> Array:
	var out: Array = []
	var b := Basis(Vector3.UP, deg_to_rad(yaw))
	for r in rows:
		for k in cols:
			var lx := (k - (cols - 1) * 0.5) * dx + (0.5 * dx if r % 2 == 1 else 0.0) * 0.5
			var lz := -(r - (rows - 1) * 0.5) * dz
			var j := Vector3((h01(k, r, seed) - 0.5) * 2.0 * jit, 0, (h01(r, k, seed + 1) - 0.5) * 2.0 * jit)
			var p := c + b * Vector3(lx, 0, lz) + j
			var yv := yaw + (h01(k + 3, r, seed + 2) - 0.5) * 16.0
			var ff := f + int(h01(k, r + 7, seed + 3) * 8.0)
			out.append(unit(scene, p, yv, act, ff, scale))
	return out


## Units on a line from a to b (inclusive), n of them.
static func line(scene: String, a: Vector3, b: Vector3, n: int, yaw: float, act: String, f: int, seed: int, scale := 1.0) -> Array:
	var out: Array = []
	for i in n:
		var t := 0.5 if n == 1 else float(i) / (n - 1)
		var p := a.lerp(b, t)
		out.append(unit(scene, p, yaw + (h01(i, 1, seed) - 0.5) * 14.0, act, f + int(h01(i, 2, seed) * 8.0), scale))
	return out


func _armies_vessa() -> Array:
	var a: Array = []   # the host pouring through the breach behind her (gate (0,-5), she stands at (0,6))
	a += block(FLAME_GUARD, Vector3(0, 0, -1.2), 5, 2, 1.45, 1.5, 0, "attack", 8, 11)
	a += [unit(BLAZE_RIDER, Vector3(-2.7, 0, 1.6), 8, "walk", 20, 1.0), unit(BLAZE_RIDER, Vector3(2.9, 0, 1.2), -10, "walk", 26, 1.0)]
	a += [unit(ASH_HURLER, Vector3(-11.6, 0, -2.8), 20, "attack", 10, 1.15), unit(ASH_HURLER, Vector3(6.4, 0, 0.6), -18, "attack", 14, 1.15)]
	a += block(SCORCHBOW, Vector3(-7.4, 0, -2.4), 4, 2, 1.25, 1.3, 14, "attack", 9, 12)
	a += block(SCORCHBOW, Vector3(7.6, 0, -2.6), 4, 2, 1.25, 1.3, -14, "attack", 9, 13)
	a += [unit(PYRE_ADEPT, Vector3(-4.4, 0, -3.6), 12, "cast", 16), unit(PYRE_ADEPT, Vector3(5.6, 0, -3.8), -12, "cast", 20),
		unit(PYRE_ADEPT, Vector3(1.6, 0, -3.9), 0, "cast", 12)]
	a += line(CINDERLOCK, Vector3(-10.5, 0, 0.2), Vector3(-9.4, 0, 2.2), 3, 18, "attack", 10, 14)
	a += line(CINDERLOCK, Vector3(10.4, 0, 0.0), Vector3(9.6, 0, 2.0), 3, -18, "attack", 12, 15)
	# archers on the curtain wall (top at y = 5)
	a += line(SCORCHBOW, Vector3(-15, 5.0, -5.1), Vector3(-5, 5.0, -5.1), 5, 0, "attack", 10, 16)
	a += line(SCORCHBOW, Vector3(5, 5.0, -5.1), Vector3(15, 5.0, -5.1), 5, 0, "attack", 10, 17)
	# the defeated defenders before the breach
	var foes: Array = [unit(WILDWOOD, Vector3(-4.2, 0, 3.6), 150, "death", 45), unit(HEXWEAVER, Vector3(4.6, 0, 4.4), 200, "death", 45),
		unit(VINELASHER, Vector3(-6.8, 0, 6.4), 120, "death", 45), unit(FROSTBOW, Vector3(6.4, 0, 7.6), 230, "death", 45),
		unit(WILDWOOD, Vector3(-2.6, 0, 9.5), 170, "death", 45), unit(RIMESHIELD, Vector3(7.6, 0, 9.6), 200, "death", 16)]
	return [{"name": "host", "units": a}, {"name": "fallen", "units": foes}]


func _armies_malrik() -> Array:
	var a: Array = []   # the dark answers: the host rising before the Dusk keep (Malrik at (0,2), gate (0,-7))
	a += [unit(NIGHTMARE, Vector3(6.6, 0, -4.2), -22, "attack", 14, 1.0)]
	a += [unit(BARROW, Vector3(-7.4, 0, -4.4), 18, "attack", 10, 1.0)]
	a += line(SKNIGHT, Vector3(-4.2, 0, -3.8), Vector3(3.2, 0, -3.6), 5, 0, "attack", 9, 21)
	a += block(SHADE, Vector3(-9.6, 0, -0.6), 3, 2, 1.3, 1.4, 20, "attack", 8, 22)
	a += block(SHADE, Vector3(9.4, 0, -0.8), 3, 2, 1.3, 1.4, -20, "attack", 8, 23)
	a += [unit(HEXWEAVER, Vector3(-7.2, 0, 1.8), 25, "cast", 16), unit(HEXWEAVER, Vector3(7.4, 0, 1.4), -25, "cast", 20),
		unit(HEXWEAVER, Vector3(-1.6, 0, -5.8), 5, "cast", 12)]
	a += [unit(HOUND, Vector3(4.6, 0, 0.6), -8, "walk", 20), unit(HOUND, Vector3(5.8, 0, 2.4), -4, "walk", 26),
		unit(HOUND, Vector3(-9.2, 0, 3.0), 12, "walk", 22)]
	a += line(THRALL, Vector3(-12.5, 0, -2.2), Vector3(-12.0, 0, 2.2), 3, 30, "walk", 18, 24)
	a += line(THRALL, Vector3(12.5, 0, -2.2), Vector3(12.0, 0, 2.2), 3, -30, "walk", 18, 25)
	# Bleakbows on the ward wall (top at y = 4)
	a += line(BLEAKBOW, Vector3(-14.5, 4.0, -7.1), Vector3(-4.5, 4.0, -7.1), 5, 0, "attack", 10, 26)
	a += line(BLEAKBOW, Vector3(4.5, 4.0, -7.1), Vector3(14.5, 4.0, -7.1), 5, 0, "attack", 10, 27)
	var foes: Array = [unit(FLAME_GUARD, Vector3(-3.2, 0, 5.2), 160, "death", 45), unit(RIMESHIELD, Vector3(5.8, 0, 6.2), 210, "death", 45),
		unit(WILDWOOD, Vector3(-6.4, 0, 7.4), 130, "death", 45), unit(FLAME_GUARD, Vector3(7.8, 0, 8.6), 240, "death", 45)]
	return [{"name": "host", "units": a}, {"name": "fallen", "units": foes}]


func _armies_torvald() -> Array:
	var a: Array = []   # the line that holds: shields on the ice, bows on the rampart, the big ones behind him
	a += line(RIMESHIELD, Vector3(-9.0, 0, 5.6), Vector3(-2.0, 0, 5.8), 5, 0, "attack", 8, 31)
	a += line(RIMESHIELD, Vector3(3.2, 0, 5.8), Vector3(10.0, 0, 5.6), 5, 0, "attack", 8, 32)
	a += line(RIFLEMAN, Vector3(-11.5, 0, 3.4), Vector3(-9.5, 0, 2.6), 3, 10, "attack", 10, 33)
	a += line(RIFLEMAN, Vector3(9.5, 0, 2.6), Vector3(11.5, 0, 3.4), 3, -10, "attack", 10, 34)
	a += line(FROSTBOW, Vector3(-15, 5.0, -4.1), Vector3(-5.5, 5.0, -4.1), 5, 0, "attack", 10, 35)
	a += line(FROSTBOW, Vector3(5.5, 5.0, -4.1), Vector3(15, 5.0, -4.1), 5, 0, "attack", 10, 36)
	a += [unit(MAMMOTH, Vector3(10.6, 0, -0.4), -25, "idle", 10, 1.0), unit(SHARDCASTER, Vector3(-4.0, 0, -2.6), 10, "cast", 16),
		unit(SHARDCASTER, Vector3(2.6, 0, -2.9), -10, "cast", 20)]
	# the enemy charge across the lake: fire host running north, the front rank frozen, some fallen
	var e: Array = []
	e += block(FLAME_GUARD, Vector3(-2.0, 0, 11.6), 5, 2, 1.7, 1.8, 180, "walk", 16, 37)
	e += [unit(ASH_HURLER, Vector3(4.8, 0, 12.4), 190, "attack", 12, 1.15), unit(ASH_HURLER, Vector3(-8.2, 0, 12.0), 170, "attack", 14, 1.15)]
	e += line(CINDER_HAND, Vector3(-9.0, 0, 8.6), Vector3(7.0, 0, 8.4), 5, 180, "attack", 8, 38)
	e += [unit(FLAME_GUARD, Vector3(-5.4, 0, 7.2), 200, "death", 45), unit(CINDER_HAND, Vector3(1.6, 0, 7.4), 150, "death", 45),
		unit(FLAME_GUARD, Vector3(6.6, 0, 7.0), 220, "death", 45)]
	# the titan flash-frozen in mid-leap over the ice
	e += [unit(BARROW, Vector3(-4.6, 2.6, 6.8), 180, "attack", 12, 1.25, Vector3(-28, 0, 8))]
	return [{"name": "line", "units": a}, {"name": "charge", "units": e}]


func _armies_ysolde() -> Array:
	var a: Array = []   # the wood answers: archers step out in pairs, vinelashers whip, stags charge
	var pairs := [Vector3(-7.0, 0, -4.8), Vector3(-10.2, 0, -1.2), Vector3(-4.2, 0, -7.2), Vector3(14.2, 0, -4.0), Vector3(-12.6, 0, 3.2)]
	var i := 0
	for p: Vector3 in pairs:
		a += [unit(WILDWOOD, p, 20 - i * 6, "attack", 9 + i), unit(WILDWOOD, p + Vector3(0.9, 0, -0.5), 20 - i * 6, "attack", 13 + i)]
		i += 1
	a += [unit(VINELASHER, Vector3(1.8, 0, -4.6), 5, "attack", 8), unit(VINELASHER, Vector3(-2.8, 0, -3.8), 15, "attack", 12),
		unit(VINELASHER, Vector3(5.4, 0, -5.4), -10, "attack", 10), unit(VINELASHER, Vector3(-1.2, 0, -6.6), 0, "attack", 14)]
	a += [unit(STAGRUNNER, Vector3(-8.2, 0, 2.6), 25, "walk", 18), unit(STAGRUNNER, Vector3(-10.6, 0, 0.8), 30, "walk", 24),
		unit(STAGRUNNER, Vector3(13.0, 0, 0.6), -30, "walk", 20)]
	a += [unit(MOSSBACK, Vector3(-7.0, 0, -9.4), 20, "attack", 12, 1.0), unit(BRAMBLEHORN, Vector3(12.2, 0, -6.6), -20, "attack", 10)]
	a += line(THORNLING, Vector3(15.0, 0, -1.6), Vector3(16.5, 0, 1.6), 3, -40, "walk", 12, 41)
	# the fire that swept her wood, beaten in the burn
	var foes: Array = [unit(FLAME_GUARD, Vector3(7.6, 0, 4.6), 200, "death", 45), unit(CINDER_HAND, Vector3(10.2, 0, 2.4), 150, "death", 45),
		unit(FLAME_GUARD, Vector3(12.6, 0, 4.8), 240, "death", 45), unit(ASH_HURLER, Vector3(6.2, 0, 7.0), 120, "death", 45),
		unit(SCORCHBOW, Vector3(9.4, 0, 7.8), 210, "death", 45)]
	return [{"name": "host", "units": a}, {"name": "fallen", "units": foes}]


func _act(n: Node, act: String) -> void:
	match act:
		"attack":
			if n.has_method("play_attack"):
				n.call("play_attack")
		"cast":
			if n.has_method("play_cast"):
				n.call("play_cast", &"prologue")
		"death":
			if n.has_method("play_death"):
				n.call("play_death")
		"walk":
			if n.has_method("set_moving"):
				n.call("set_moving", 4.5)


func _bake_army(w: String, job: Dictionary) -> void:
	var holder := Node3D.new()
	holder.name = "Bake"
	root.add_child(holder)
	var list: Array = []
	for u: Dictionary in job["units"]:
		var ps := load(u["scene"]) as PackedScene
		if ps == null:
			push_warning("intro_bake: missing " + String(u["scene"]))
			continue
		var n := ps.instantiate() as Node3D
		var r: Vector3 = u["rot"]
		var b := Basis.from_euler(Vector3(deg_to_rad(r.x), deg_to_rad(float(u["yaw"]) + r.y), deg_to_rad(r.z)))
		n.transform = Transform3D(b.scaled(Vector3.ONE * float(u["scale"])), u["pos"])
		holder.add_child(n)
		list.append([n, u])
	for k in 3:
		await process_frame
	for fr in TOTAL_FRAMES:
		for pr: Array in list:
			var u: Dictionary = pr[1]
			if TOTAL_FRAMES - int(u["f"]) == fr:
				_act(pr[0], u["act"])
		await process_frame
	# merge
	var bk := {"paint": _Bucket.new(), "glow": _Bucket.new()}
	var keep := {}
	var idx := 0
	for pr: Array in list:
		idx += 1
		_collect(pr[0], holder, bk, keep, float(idx % 17) / 17.0)
	var mesh := ArrayMesh.new()
	var tris := 0
	for key in ["paint", "glow"]:
		var b: _Bucket = bk[key]
		if b.v.size() > 0:
			tris += b.commit(mesh, _paint_mat if key == "paint" else _glow_mat)
	for key in keep:
		var b: _Bucket = keep[key]
		tris += b.commit(mesh, b.mat)
	var dir := ROOT + "forge_intro_%s/props/" % w
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var mpath := dir + "army_%s.res" % job["name"]
	ResourceSaver.save(mesh, mpath)
	mesh.take_over_path(mpath)
	var sroot := Node3D.new()
	sroot.name = "Army_%s_%s" % [w, job["name"]]
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = mesh
	sroot.add_child(mi)
	mi.owner = sroot
	var ps2 := PackedScene.new()
	ps2.pack(sroot)
	ResourceSaver.save(ps2, dir + "army_%s.tscn" % job["name"])
	print("intro_bake: %s army_%s  units %d  surfaces %d  tris %d  kept materials %d" % [w, job["name"], list.size(), mesh.get_surface_count(), tris, keep.size()])
	sroot.free()
	holder.queue_free()
	await process_frame


class _Bucket:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var uv := PackedVector2Array()
	var idx := PackedInt32Array()
	var mat: Material

	func add(mesh: Mesh, s: int, xf: Transform3D, col: Variant) -> void:
		if mesh is ArrayMesh and (mesh as ArrayMesh).surface_get_primitive_type(s) != Mesh.PRIMITIVE_TRIANGLES:
			return
		var arr := mesh.surface_get_arrays(s)
		if arr.is_empty():
			return
		var sv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		if sv.is_empty():
			return
		var sn: Variant = arr[Mesh.ARRAY_NORMAL]
		var sc: Variant = arr[Mesh.ARRAY_COLOR]
		var suv: Variant = arr[Mesh.ARRAY_TEX_UV]
		var base := v.size()
		var nb := xf.basis.inverse().transposed()
		var flip := xf.basis.determinant() < 0.0
		for i in sv.size():
			v.append(xf * sv[i])
			n.append((nb * (sn[i] as Vector3)).normalized() if sn is PackedVector3Array and (sn as PackedVector3Array).size() > i else Vector3.UP)
			if col is Color:
				c.append(col)
			else:
				c.append(sc[i] if sc is PackedColorArray and (sc as PackedColorArray).size() > i else Color.WHITE)
			uv.append(suv[i] if suv is PackedVector2Array and (suv as PackedVector2Array).size() > i else Vector2.ZERO)
		var si: Variant = arr[Mesh.ARRAY_INDEX]
		if si is PackedInt32Array and not (si as PackedInt32Array).is_empty():
			var ii: PackedInt32Array = si
			for k in range(0, ii.size(), 3):
				if flip:
					idx.append_array([base + ii[k], base + ii[k + 2], base + ii[k + 1]])
				else:
					idx.append_array([base + ii[k], base + ii[k + 1], base + ii[k + 2]])
		else:
			for k in range(0, sv.size(), 3):
				if flip:
					idx.append_array([base + k, base + k + 2, base + k + 1])
				else:
					idx.append_array([base + k, base + k + 1, base + k + 2])

	func commit(mesh: ArrayMesh, m: Material) -> int:
		if v.is_empty():
			return 0
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = v
		arr[Mesh.ARRAY_NORMAL] = n
		arr[Mesh.ARRAY_COLOR] = c
		arr[Mesh.ARRAY_TEX_UV] = uv
		arr[Mesh.ARRAY_INDEX] = idx
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		mesh.surface_set_material(mesh.get_surface_count() - 1, m)
		return idx.size() / 3


static func _param(mat: ShaderMaterial, name: String) -> Variant:
	var v: Variant = mat.get_shader_parameter(name)
	if v == null and mat.shader:
		v = RenderingServer.shader_get_parameter_default(mat.shader.get_rid(), name)
	if v is Vector3:
		return Color(v.x, v.y, v.z)
	if v is Vector4:
		return Color(v.x, v.y, v.z, v.w)
	return v


## [kind, colour]: kind paint / glow / skip / keep.
static func _classify(mat: Material) -> Array:
	if mat == null:
		return ["paint", Color(0.5, 0.5, 0.5)]
	if mat is ShaderMaterial:
		var sm := mat as ShaderMaterial
		var path := sm.shader.resource_path if sm.shader else ""
		if path.get_file().contains("blob"):
			return ["skip", null]
		var g: Variant = _param(sm, "glow_color")
		if g is Color:
			return ["glow", g]
		for k in ["base_color", "albedo", "albedo_color", "color", "tint", "body_color"]:
			var b: Variant = _param(sm, k)
			if b is Color:
				return ["paint", b]
		return ["keep", null]
	if mat is BaseMaterial3D:
		var bm := mat as BaseMaterial3D
		if bm.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or bm.blend_mode != BaseMaterial3D.BLEND_MODE_MIX:
			return ["skip", null]
		if bm.emission_enabled and bm.emission.get_luminance() > 0.05:
			return ["glow", bm.emission]
		if bm.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
			return ["glow", bm.albedo_color]
		return ["paint", bm.albedo_color]
	return ["keep", null]


func _collect(n: Node, holder: Node3D, bk: Dictionary, keep: Dictionary, phase: float) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh and mi.is_visible_in_tree():
			var xf := holder.global_transform.affine_inverse() * mi.global_transform
			for s in mi.mesh.get_surface_count():
				var mat := mi.get_active_material(s)
				var cl := _classify(mat)
				match cl[0]:
					"paint":
						(bk["paint"] as _Bucket).add(mi.mesh, s, xf, Color(cl[1].r, cl[1].g, cl[1].b, 1.0))
					"glow":
						(bk["glow"] as _Bucket).add(mi.mesh, s, xf, Color(cl[1].r, cl[1].g, cl[1].b, phase))
					"keep":
						var key := str(mat.get_instance_id())
						if not keep.has(key):
							var b := _Bucket.new()
							b.mat = mat
							keep[key] = b
						(keep[key] as _Bucket).add(mi.mesh, s, xf, null)
	for c in n.get_children():
		_collect(c, holder, bk, keep, phase)


# ================================================================ fx mesh helpers

class MB:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var uv := PackedVector2Array()
	var idx := PackedInt32Array()

	func vert(p: Vector3, nn: Vector3, u: Vector2, col: Color) -> int:
		v.append(p)
		n.append(nn)
		uv.append(u)
		c.append(col)
		return v.size() - 1

	func tri(a: int, b: int, d: int) -> void:
		idx.append_array([a, b, d])

	## A tube along pts with radii (UV.x around 0..1, UV.y along 0..1).
	func tube(pts: PackedVector3Array, radii: PackedFloat32Array, seg: int, col: Color) -> void:
		var cnt := pts.size()
		var side := Vector3.ZERO
		var rings: Array = []
		for i in cnt:
			var t := (pts[mini(i + 1, cnt - 1)] - pts[maxi(i - 1, 0)]).normalized()
			if side == Vector3.ZERO:
				var ref := Vector3.UP if absf(t.y) < 0.9 else Vector3.RIGHT
				side = t.cross(ref).normalized()
			else:
				side = (side - t * side.dot(t)).normalized()
			var up2 := side.cross(t).normalized()
			var ring: Array = []
			for j in seg + 1:
				var a := TAU * float(j) / seg
				var d := side * cos(a) + up2 * sin(a)
				ring.append(vert(pts[i] + d * radii[i], d, Vector2(float(j) / seg, float(i) / (cnt - 1)), col))
			rings.append(ring)
		for i in cnt - 1:
			for j in seg:
				var a: int = rings[i][j]
				var b: int = rings[i][j + 1]
				var d: int = rings[i + 1][j]
				var e: int = rings[i + 1][j + 1]
				tri(a, d, b)
				tri(b, d, e)

	## Flat annulus at c (UV.y = 0 at r0 -> 1 at r1, UV.x around).
	func disc(ctr: Vector3, r0: float, r1: float, seg: int, col: Color, rings := 3) -> void:
		var rows: Array = []
		for i in rings + 1:
			var r := lerpf(r0, r1, float(i) / rings)
			var row: Array = []
			for j in seg + 1:
				var a := TAU * float(j) / seg
				row.append(vert(ctr + Vector3(cos(a) * r, 0, sin(a) * r), Vector3.UP, Vector2(float(j) / seg, float(i) / rings), col))
			rows.append(row)
		for i in rings:
			for j in seg:
				tri(rows[i][j], rows[i][j + 1], rows[i + 1][j])
				tri(rows[i][j + 1], rows[i + 1][j + 1], rows[i + 1][j])

	## A pointed crystal (sides-gon prism with a tip) from base along dir.
	func crystal(base: Vector3, dir: Vector3, h: float, r: float, sides: int, col: Color) -> void:
		var d := dir.normalized()
		tube(PackedVector3Array([base - d * 0.4, base + d * h * 0.72, base + d * h]), PackedFloat32Array([r, r * 0.92, 0.0]), sides, col)

	## Crossed-quad ribbon along a parabola a -> b with peak height (UV.y along).
	func arc(a: Vector3, b: Vector3, peak: float, w: float, col: Color, steps := 16) -> void:
		for plane in 2:
			var prev := -1
			var prev2 := -1
			for i in steps + 1:
				var t := float(i) / steps
				var p := a.lerp(b, t) + Vector3(0, 4.0 * peak * t * (1.0 - t), 0)
				var dirv := (b - a).normalized()
				var off := (Vector3.UP if plane == 0 else dirv.cross(Vector3.UP).normalized()) * w * 0.5
				var nn := dirv.cross(off).normalized()
				var i0 := vert(p - off, nn, Vector2(0, t), col)
				var i1 := vert(p + off, nn, Vector2(1, t), col)
				if prev >= 0:
					tri(prev, i0, prev2)
					tri(prev2, i0, i1)
				prev = i0
				prev2 = i1

	func mesh() -> ArrayMesh:
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = v
		arr[Mesh.ARRAY_NORMAL] = n
		arr[Mesh.ARRAY_COLOR] = c
		arr[Mesh.ARRAY_TEX_UV] = uv
		arr[Mesh.ARRAY_INDEX] = idx
		var m := ArrayMesh.new()
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		return m


static func smat(path: String, params: Dictionary) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(path)
	for k in params:
		var v: Variant = params[k]
		if k == "energy" and path == SH_ADD:
			v = float(v) * ADD_GAIN   # additive sheets read through bloom: one global gain, tuned on the sheets
		m.set_shader_parameter(k, v)
	return m


static func add_mesh(parent: Node3D, owner: Node, name: String, mb: MB, mat: Material, shadows := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mb.mesh()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	parent.add_child(mi)
	mi.owner = owner
	return mi


static var _mote_tex: GradientTexture2D

static func mote_tex() -> GradientTexture2D:
	if _mote_tex == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.5), Color(1, 1, 1, 0)])
		_mote_tex = GradientTexture2D.new()
		_mote_tex.gradient = g
		_mote_tex.width = 32
		_mote_tex.height = 32
		_mote_tex.fill = GradientTexture2D.FILL_RADIAL
		_mote_tex.fill_from = Vector2(0.5, 0.5)
		_mote_tex.fill_to = Vector2(1.0, 0.5)
	return _mote_tex


## Looping, seek-safe particles: fixed seed, fixed_fps 30, preprocessed to a full cycle, local coords.
## o: amount, life, shape (box / sphere / ring), ext (Vector3 box extents | radius), dir, spread, v (Vector2 min/max),
## grav, size (Vector2 scale min/max), quad (m), cols (PackedColorArray HDR ramp), seed, damp, radial, tang, aabb, pos,
## additive (true), turb.
static func particles(parent: Node3D, owner: Node, name: String, o: Dictionary) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = name
	p.amount = int(o.get("amount", 64))
	p.lifetime = float(o.get("life", 3.0))
	p.preprocess = p.lifetime
	p.fixed_fps = 30
	p.use_fixed_seed = true
	p.seed = int(o.get("seed", 1))
	p.randomness = 0.3
	p.local_coords = true
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	p.visibility_aabb = o.get("aabb", AABB(Vector3(-20, -2, -20), Vector3(40, 40, 40)))
	p.position = o.get("pos", Vector3.ZERO)
	var pm := ParticleProcessMaterial.new()
	match String(o.get("shape", "sphere")):
		"box":
			pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			pm.emission_box_extents = o.get("ext", Vector3.ONE)
		"ring":
			pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
			var e: Vector3 = o.get("ext", Vector3(3, 2, 0.2))
			pm.emission_ring_axis = Vector3.UP
			pm.emission_ring_radius = e.x
			pm.emission_ring_inner_radius = e.y
			pm.emission_ring_height = e.z
		_:
			pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			pm.emission_sphere_radius = float((o.get("ext", Vector3.ONE) as Vector3).x)
	pm.direction = o.get("dir", Vector3.UP)
	pm.spread = float(o.get("spread", 20.0))
	var vv: Vector2 = o.get("v", Vector2(1, 2))
	pm.initial_velocity_min = vv.x
	pm.initial_velocity_max = vv.y
	pm.gravity = o.get("grav", Vector3.ZERO)
	var dmp: float = o.get("damp", 0.0)
	pm.damping_min = dmp
	pm.damping_max = dmp * 1.5
	var rad: float = o.get("radial", 0.0)
	pm.radial_accel_min = rad
	pm.radial_accel_max = rad
	var tg: float = o.get("tang", 0.0)
	pm.tangential_accel_min = tg
	pm.tangential_accel_max = tg * 1.3
	var sz: Vector2 = o.get("size", Vector2(0.8, 1.2))
	pm.scale_min = sz.x
	pm.scale_max = sz.y
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.3))
	curve.add_point(Vector2(0.15, 1.0))
	curve.add_point(Vector2(0.75, 0.8))
	curve.add_point(Vector2(1, 0.0))
	var ct := CurveTexture.new()
	ct.curve = curve
	pm.scale_curve = ct
	var g := Gradient.new()
	var cols: PackedColorArray = o.get("cols", PackedColorArray([Color(3, 1.4, 0.3, 0), Color(3, 1.2, 0.3, 1), Color(1.2, 0.2, 0.02, 0)]))
	var offs := PackedFloat32Array()
	for i in cols.size():
		offs.append(float(i) / (cols.size() - 1) if cols.size() > 1 else 0.0)
	if cols.size() >= 3:
		offs[1] = 0.12
	g.offsets = offs
	g.colors = cols
	var gt := GradientTexture1D.new()
	gt.gradient = g
	gt.use_hdr = true
	pm.color_ramp = gt
	if o.get("turb", 0.0) > 0.0:
		pm.turbulence_enabled = true
		pm.turbulence_noise_strength = float(o["turb"])
		pm.turbulence_noise_scale = 3.0
		pm.turbulence_influence_min = 0.05
		pm.turbulence_influence_max = 0.15
	p.process_material = pm
	var q := QuadMesh.new()
	var qs: float = o.get("quad", 0.3)
	q.size = Vector2(qs, qs)
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if bool(o.get("additive", true)):
		sm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	sm.billboard_keep_scale = true
	sm.vertex_color_use_as_albedo = true
	sm.albedo_texture = mote_tex()
	sm.disable_receive_shadows = true
	sm.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	q.material = sm
	p.draw_pass_1 = q
	parent.add_child(p)
	p.owner = owner
	return p


static func save_fx(w: String, root_node: Node3D) -> void:
	var dir := ROOT + "forge_intro_%s/fx/" % w
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var ps := PackedScene.new()
	ps.pack(root_node)
	var path := dir + String(root_node.name).to_snake_case() + ".tscn"
	var err := ResourceSaver.save(ps, path)
	print("intro_bake: %s %s (%s)" % [w, path, error_string(err)])
	root_node.free()


static func fx_root(name: String) -> Node3D:
	var r := Node3D.new()
	r.name = name
	return r


## A wobbling vertical column of points (for pillars / beams).
static func column(h: float, n: int, wob: float, seed: int, base := Vector3.ZERO) -> PackedVector3Array:
	var pts := PackedVector3Array()
	for i in n:
		var t := float(i) / (n - 1)
		pts.append(base + Vector3(sin(t * 7.0 + seed) * wob * t, t * h, cos(t * 5.0 + seed * 1.7) * wob * t))
	return pts


static func radii(n: int, r0: float, r1: float, bulge := 0.0) -> PackedFloat32Array:
	var r := PackedFloat32Array()
	for i in n:
		var t := float(i) / (n - 1)
		r.append(lerpf(r0, r1, t) + bulge * sin(t * PI))
	return r


# ================================================================ Vessa: fire pillar, fire columns, ember rain, volley

func _fx_vessa() -> void:
	# the pillar of fire answering her staff (S08): 30 m, three shells + a ground flare + rising embers
	var r := fx_root("FxFirePillar")
	var core := MB.new()
	core.tube(column(30, 14, 0.5, 1), radii(14, 0.8, 0.45, 0.2), 16, Color.WHITE)
	add_mesh(r, r, "Core", core, smat(SH_ADD, {"col_a": Color(1, 0.6, 0.15), "col_b": Color(1, 0.95, 0.7), "energy": 4.5,
		"scroll": Vector2(0.05, -1.6), "tiling": Vector2(4, 6), "sharp": 0.8, "base": 0.45, "fres": 0.8, "fade_lo": 0.02, "fade_hi": 0.3}))
	var mid := MB.new()
	mid.tube(column(30, 14, 0.8, 2), radii(14, 1.6, 1.1, 0.5), 18, Color.WHITE)
	add_mesh(r, r, "Mid", mid, smat(SH_ADD, {"col_a": Color(1, 0.3, 0.03), "col_b": Color(1, 0.7, 0.2), "energy": 2.6,
		"scroll": Vector2(0.1, -1.1), "tiling": Vector2(5, 5), "twist": 1.5, "sharp": 1.4, "base": 0.1, "fres": 1.2, "fade_lo": 0.02, "fade_hi": 0.35}))
	var outer := MB.new()
	outer.tube(column(30, 14, 1.2, 3), radii(14, 2.8, 2.0, 0.8), 20, Color.WHITE)
	add_mesh(r, r, "Outer", outer, smat(SH_ADD, {"col_a": Color(0.9, 0.12, 0.02), "col_b": Color(1, 0.45, 0.08), "energy": 1.3,
		"scroll": Vector2(-0.08, -0.7), "tiling": Vector2(6, 4), "twist": -2.0, "sharp": 2.2, "base": 0.0, "fres": 1.5, "fade_lo": 0.03, "fade_hi": 0.45}))
	var flare := MB.new()
	flare.disc(Vector3(0, 0.08, 0), 0.0, 6.0, 32, Color.WHITE, 4)
	add_mesh(r, r, "Flare", flare, smat(SH_ADD, {"col_a": Color(1, 0.3, 0.04), "col_b": Color(1, 0.8, 0.35), "energy": 2.2,
		"scroll": Vector2(0.05, -0.4), "tiling": Vector2(10, 3), "sharp": 1.6, "base": 0.2, "fres": 0.0, "fade_lo": 0.001, "fade_hi": 0.9}))
	particles(r, r, "Embers", {"amount": 90, "life": 3.5, "shape": "ring", "ext": Vector3(2.6, 0.5, 1.0), "dir": Vector3.UP, "spread": 18.0,
		"v": Vector2(5, 10), "grav": Vector3(0.4, -0.5, 0.2), "size": Vector2(0.6, 1.3), "quad": 0.22, "seed": 11, "turb": 0.8,
		"cols": PackedColorArray([Color(4, 2.2, 0.6, 0), Color(4, 1.8, 0.4, 1), Color(1.5, 0.25, 0.02, 0)]),
		"aabb": AABB(Vector3(-8, -1, -8), Vector3(16, 40, 16))})
	save_fx("vessa", r)

	# Pyre Adept fire columns (S15 / S15U): three 8 m columns over the adepts of army_host
	r = fx_root("FxFireColumns")
	var cm := MB.new()
	var cm2 := MB.new()
	var fl := MB.new()
	var spots := [Vector3(-4.4, 0, -3.6), Vector3(5.6, 0, -3.8), Vector3(1.6, 0, -3.9)]
	var si := 0
	for s: Vector3 in spots:
		cm.tube(column(8, 8, 0.25, si + 5, s), radii(8, 0.3, 0.12, 0.1), 12, Color(1, 1, 1, si * 0.3))
		cm2.tube(column(8.5, 8, 0.4, si + 9, s), radii(8, 0.6, 0.3, 0.2), 14, Color(1, 1, 1, si * 0.3))
		fl.disc(s + Vector3(0, 0.07, 0), 0.0, 1.8, 20, Color.WHITE, 2)
		si += 1
	add_mesh(r, r, "Core", cm, smat(SH_ADD, {"col_a": Color(1, 0.55, 0.12), "col_b": Color(1, 0.95, 0.6), "energy": 2.2,
		"scroll": Vector2(0.0, -2.0), "tiling": Vector2(3, 6), "sharp": 0.9, "base": 0.4, "fres": 0.8, "fade_lo": 0.02, "fade_hi": 0.35}))
	add_mesh(r, r, "Shell", cm2, smat(SH_ADD, {"col_a": Color(0.95, 0.2, 0.02), "col_b": Color(1, 0.6, 0.15), "energy": 1.1,
		"scroll": Vector2(0.1, -1.3), "tiling": Vector2(4, 4), "twist": 1.0, "sharp": 1.6, "base": 0.05, "fres": 1.3, "fade_lo": 0.02, "fade_hi": 0.4}))
	add_mesh(r, r, "Flares", fl, smat(SH_ADD, {"col_a": Color(1, 0.35, 0.05), "col_b": Color(1, 0.8, 0.4), "energy": 2.0,
		"scroll": Vector2(0.0, -0.5), "tiling": Vector2(8, 2), "sharp": 1.2, "base": 0.3, "fres": 0.0, "fade_lo": 0.001, "fade_hi": 0.9}))
	save_fx("vessa", r)

	# ember rain over the whole field (S15, S16, S17): slow glowing embers + a few falling fire-drops
	r = fx_root("FxEmberRain")
	particles(r, r, "Embers", {"amount": 420, "life": 9.0, "shape": "box", "ext": Vector3(26, 1, 16), "pos": Vector3(0, 16, 4),
		"dir": Vector3.DOWN, "spread": 25.0, "v": Vector2(0.8, 1.8), "grav": Vector3(0.35, -1.2, 0.25), "size": Vector2(0.5, 1.2),
		"quad": 0.14, "seed": 12, "turb": 1.2, "cols": PackedColorArray([Color(4, 1.6, 0.3, 0), Color(4, 1.5, 0.3, 1), Color(2.5, 0.5, 0.05, 0.9), Color(0.8, 0.1, 0.02, 0)]),
		"aabb": AABB(Vector3(-30, -20, -22), Vector3(60, 24, 44))})
	particles(r, r, "Drops", {"amount": 26, "life": 3.0, "shape": "box", "ext": Vector3(22, 1, 14), "pos": Vector3(0, 22, 2),
		"dir": Vector3(0.2, -1, 0.15), "spread": 5.0, "v": Vector2(5, 8), "grav": Vector3(0, -2, 0), "size": Vector2(0.8, 1.3),
		"quad": 0.45, "seed": 13, "cols": PackedColorArray([Color(5, 2.6, 0.8, 0), Color(5, 2.4, 0.7, 1), Color(3, 0.6, 0.05, 1), Color(1, 0.1, 0.0, 0)]),
		"aabb": AABB(Vector3(-30, -24, -22), Vector3(60, 30, 44))})
	save_fx("vessa", r)

	# the Scorchbow volley: burning arrows arcing over the field toward the south (S15 / S15U)
	r = fx_root("FxArrowVolley")
	var av := MB.new()
	for i in 28:
		var side := -1.0 if i % 2 == 0 else 1.0
		var sx := side * lerpf(4.0, 10.0, h01(i, 1, 5))
		var sz := lerpf(-3.5, -1.0, h01(i, 2, 5))
		var tx := side * lerpf(9.0, 22.0, h01(i, 3, 5))
		var tz := lerpf(10.0, 20.0, h01(i, 4, 5))
		av.arc(Vector3(sx, 2.2, sz), Vector3(tx, 0.0, tz), lerpf(7.0, 10.0, h01(i, 5, 5)), 0.1, Color(1, 1, 1, h01(i, 6, 5)), 24)
	add_mesh(r, r, "Streaks", av, smat(SH_ADD, {"col_a": Color(1, 0.35, 0.05), "col_b": Color(1, 0.9, 0.5), "energy": 4.0,
		"scroll": Vector2(0.0, -0.9), "tiling": Vector2(1, 2), "sharp": 0.6, "base": 0.6, "fres": 0.0, "fade_lo": 0.05, "fade_hi": 0.2, "dash": 5.0}))
	save_fx("vessa", r)


# ================================================================ Malrik: vortex, tendrils, the Master's shadow, crown

func _fx_malrik() -> void:
	# the swirling dark vortex over the Dusk keep (S19, S09): a funnel, a glowing eye ring, a beam, sucked-in motes
	var r := fx_root("FxShadowVortex")
	var fun := MB.new()
	var pts := PackedVector3Array()
	var rr := PackedFloat32Array()
	for i in 10:
		var t := float(i) / 9.0
		pts.append(Vector3(0, 10.0 + t * 10.0, 0))
		rr.append(lerpf(1.6, 18.0, pow(t, 1.6)))
	fun.tube(pts, rr, 40, Color(1, 1, 1, 1))
	add_mesh(r, r, "Funnel", fun, smat(SH_VEIL, {"dark": Color(0.03, 0.01, 0.06), "glow": Color(0.85, 0.45, 1.0), "energy": 5.0,
		"scroll": Vector2(0.18, 0.12), "tiling": Vector2(9, 3), "twist": 3.0, "streak": 0.5, "opacity": 0.9, "fade_lo": 0.05, "fade_hi": 0.35}))
	var eye := MB.new()
	var ring := PackedVector3Array()
	var rr2 := PackedFloat32Array()
	for i in 49:
		var a := TAU * i / 48.0
		ring.append(Vector3(cos(a) * 2.4, 10.2, sin(a) * 2.4))
		rr2.append(0.35)
	eye.tube(ring, rr2, 8, Color.WHITE)
	var beam := MB.new()
	beam.tube(column(10.5, 8, 0.2, 4), radii(8, 0.5, 1.4), 12, Color.WHITE)
	add_mesh(r, r, "EyeRing", eye, smat(SH_ADD, {"col_a": Color(0.6, 0.2, 1.0), "col_b": Color(0.95, 0.75, 1.0), "energy": 4.0,
		"scroll": Vector2(0.0, -2.0), "tiling": Vector2(2, 12), "sharp": 1.0, "base": 0.4, "fres": 0.0, "fade_lo": 0.0001, "fade_hi": 0.0001}))
	add_mesh(r, r, "Beam", beam, smat(SH_ADD, {"col_a": Color(0.45, 0.12, 0.9), "col_b": Color(0.85, 0.6, 1.0), "energy": 2.6,
		"scroll": Vector2(0.1, 1.2), "tiling": Vector2(4, 5), "twist": 2.0, "sharp": 1.5, "base": 0.1, "fres": 1.0, "fade_lo": 0.2, "fade_hi": 0.1}))
	particles(r, r, "Motes", {"amount": 160, "life": 5.0, "shape": "ring", "ext": Vector3(15, 6, 3), "pos": Vector3(0, 15, 0),
		"dir": Vector3.DOWN, "spread": 30.0, "v": Vector2(0.5, 1.5), "radial": -3.0, "tang": 4.0, "size": Vector2(0.6, 1.3), "quad": 0.22,
		"seed": 21, "cols": PackedColorArray([Color(1.4, 0.6, 3.0, 0), Color(1.6, 0.7, 3.2, 1), Color(0.5, 0.1, 1.2, 0)]),
		"aabb": AABB(Vector3(-22, -2, -22), Vector3(44, 34, 44))})
	save_fx("malrik", r)

	# shadow tendrils standing up out of the ground around him (S19): 13 curling arms, a dark pool, rising motes
	r = fx_root("FxShadowTendrils")
	var tb := MB.new()
	var n := 0
	for i in 14:
		var ang := deg_to_rad(lerpf(-172.0, -8.0, float(i) / 13.0)) + (h01(i, 1, 31) - 0.5) * 0.2
		var rad := lerpf(4.5, 9.0, h01(i, 2, 31))
		var base := Vector3(cos(ang) * rad, 0, sin(ang) * rad * 0.8 - 0.5)
		var hh := lerpf(3.5, 8.0, h01(i, 3, 31))
		var tp := PackedVector3Array()
		var tr := PackedFloat32Array()
		var curl := (h01(i, 4, 31) - 0.5) * 3.0
		for k in 12:
			var t := float(k) / 11.0
			var out := base.normalized() * (sin(t * 2.2) * 1.2)
			tp.append(base + out + Vector3(sin(t * 4.0 + i) * curl * t, t * hh, cos(t * 3.5 + i) * curl * t))
			tr.append(lerpf(0.26, 0.015, pow(t, 0.7)))
		tb.tube(tp, tr, 7, Color(0.1, 0.07, 0.14, h01(i, 5, 31)))
		n += 1
	var tm := add_mesh(r, r, "Tendrils", tb, smat(SH_SOLID, {"vein": Color(0.7, 0.3, 1.0), "energy": 2.2, "tiling": Vector2(2, 26),
		"scroll": Vector2(0.0, -1.2), "vein_w": 0.8, "sway": 0.5, "rough": 0.5, "spec": 0.5, "rim": 0.6, "tip_glow": 1.2}), true)
	tm.extra_cull_margin = 2.0
	var pool := MB.new()
	pool.disc(Vector3(0, 0.06, -1.5), 0.0, 9.5, 40, Color(1, 1, 1, 1), 4)
	add_mesh(r, r, "Pool", pool, smat(SH_VEIL, {"dark": Color(0.03, 0.01, 0.05), "glow": Color(0.6, 0.25, 1.0), "energy": 2.0,
		"scroll": Vector2(0.05, 0.15), "tiling": Vector2(14, 3), "twist": 1.0, "streak": 0.75, "opacity": 0.8, "fade_lo": 0.0001, "fade_hi": 0.6}))
	particles(r, r, "Wisps", {"amount": 70, "life": 4.0, "shape": "ring", "ext": Vector3(7, 3, 0.5), "dir": Vector3.UP, "spread": 15.0,
		"v": Vector2(0.8, 2.2), "size": Vector2(0.6, 1.2), "quad": 0.13, "seed": 22, "turb": 1.0,
		"cols": PackedColorArray([Color(1.2, 0.5, 2.6, 0), Color(1.4, 0.6, 3.0, 0.9), Color(0.4, 0.1, 1.0, 0)])})
	save_fx("malrik", r)

	# the Master: a tall shadow with a burning hem (S18 behind young Malrik; reused kneeling in Ysolde's S26)
	r = fx_root("FxMasterShadow")
	var body := MB.new()
	body.tube(PackedVector3Array([Vector3(0, 0.05, 0), Vector3(0, 0.8, 0), Vector3(0, 1.8, 0.02), Vector3(0, 2.6, 0.05), Vector3(0, 2.95, 0.1)]),
		PackedFloat32Array([0.95, 0.72, 0.5, 0.42, 0.3]), 14, Color(0.07, 0.06, 0.09, 0.2))
	body.tube(PackedVector3Array([Vector3(0, 2.85, 0.1), Vector3(0, 3.15, 0.16), Vector3(0, 3.45, 0.1), Vector3(0, 3.62, 0.0)]),
		PackedFloat32Array([0.26, 0.33, 0.28, 0.0]), 12, Color(0.06, 0.05, 0.08, 0.2))
	# shoulders / arms (cloak folds)
	body.tube(PackedVector3Array([Vector3(-0.45, 2.55, 0.05), Vector3(-0.62, 1.9, 0.2), Vector3(-0.55, 1.35, 0.35)]),
		PackedFloat32Array([0.16, 0.14, 0.1]), 8, Color(0.07, 0.06, 0.09, 0.4))
	body.tube(PackedVector3Array([Vector3(0.45, 2.55, 0.05), Vector3(0.62, 1.9, 0.2), Vector3(0.55, 1.35, 0.35)]),
		PackedFloat32Array([0.16, 0.14, 0.1]), 8, Color(0.07, 0.06, 0.09, 0.6))
	add_mesh(r, r, "Robe", body, smat(SH_SOLID, {"vein": Color(1.0, 0.45, 0.1), "energy": 1.2, "tiling": Vector2(4, 10), "scroll": Vector2(0, -0.3),
		"vein_w": 0.9, "rough": 0.9, "spec": 0.1, "rim": 0.8, "tip_glow": 0.0}), true)
	var hem := MB.new()
	var hp := PackedVector3Array()
	var hr := PackedFloat32Array()
	for i in 33:
		var a := TAU * i / 32.0
		hp.append(Vector3(cos(a) * 0.95, 0.12 + 0.05 * sin(a * 5.0), sin(a) * 0.95))
		hr.append(0.1)
	hem.tube(hp, hr, 6, Color.WHITE)
	hem.disc(Vector3(0.08, 3.2, 0.44), 0.0, 0.05, 8, Color.WHITE, 1)
	hem.disc(Vector3(-0.08, 3.2, 0.44), 0.0, 0.05, 8, Color.WHITE, 1)
	add_mesh(r, r, "Hem", hem, smat(SH_ADD, {"col_a": Color(1, 0.35, 0.05), "col_b": Color(1, 0.85, 0.4), "energy": 4.0,
		"scroll": Vector2(0.4, 0.0), "tiling": Vector2(12, 1), "sharp": 1.0, "base": 0.5, "fres": 0.0, "fade_lo": 0.0001, "fade_hi": 0.0001}))
	particles(r, r, "HemSparks", {"amount": 40, "life": 2.2, "shape": "ring", "ext": Vector3(0.95, 0.8, 0.1), "pos": Vector3(0, 0.15, 0),
		"dir": Vector3.UP, "spread": 25.0, "v": Vector2(0.4, 1.2), "size": Vector2(0.5, 1.0), "quad": 0.12, "seed": 23, "turb": 0.8,
		"cols": PackedColorArray([Color(4, 1.8, 0.4, 0), Color(4, 1.6, 0.3, 1), Color(1.2, 0.2, 0.02, 0)]),
		"aabb": AABB(Vector3(-3, -1, -3), Vector3(6, 6, 6))})
	save_fx("malrik", r)

	# the crown on the trophy table (S20): gold band with spikes + a pile of gold, glowing
	r = fx_root("FxCrown")
	var cr := MB.new()
	var cp := PackedVector3Array()
	var cq := PackedFloat32Array()
	for i in 25:
		var a := TAU * i / 24.0
		cp.append(Vector3(cos(a) * 0.17, 0.0, sin(a) * 0.17))
		cq.append(0.035)
	cr.tube(cp, cq, 6, Color(1.0, 0.78, 0.3, 0.1))
	for i in 7:
		var a := TAU * i / 7.0
		cr.crystal(Vector3(cos(a) * 0.17, 0.0, sin(a) * 0.17), Vector3.UP, 0.16, 0.035, 4, Color(1.0, 0.8, 0.35, 0.3))
	for i in 14:
		cr.disc(Vector3((h01(i, 1, 3) - 0.5) * 0.7, 0.02 + i * 0.003, (h01(i, 2, 3) - 0.5) * 0.5 + 0.25), 0.0, 0.06, 10, Color(1.0, 0.75, 0.25, 0.5), 1)
	var crm := add_mesh(r, r, "Crown", cr, smat(SH_SOLID, {"vein": Color(1.0, 0.75, 0.3), "energy": 1.6, "tiling": Vector2(3, 3),
		"scroll": Vector2(0.2, 0.0), "vein_w": 0.55, "rough": 0.25, "spec": 0.9, "rim": 0.5, "tip_glow": 2.0}), true)
	crm.position = Vector3(0, 0.46, 0)   # sits on the small crate (set (3.2, 3.6), top at 0.45 m)
	particles(r, r, "Glints", {"amount": 12, "life": 2.0, "shape": "sphere", "ext": Vector3(0.3, 0, 0), "pos": Vector3(0, 0.62, 0.1),
		"dir": Vector3.UP, "spread": 60.0, "v": Vector2(0.05, 0.2), "size": Vector2(0.5, 1.0), "quad": 0.08, "seed": 24,
		"cols": PackedColorArray([Color(4, 3, 1.2, 0), Color(4, 3, 1.2, 1), Color(2, 1.2, 0.3, 0)]), "aabb": AABB(Vector3(-1, -1, -1), Vector3(2, 2, 2))})
	save_fx("malrik", r)


# ================================================================ Torvald: ice wall, frost burst, lake cracks, Heartfrost, snow

func _fx_torvald() -> void:
	# the ice wall: two crystal ramparts flanking the shield line, out onto the lake (S22, S10)
	var r := fx_root("FxIceWall")
	var cw := MB.new()
	for side in [-1.0, 1.0]:
		for i in 18:
			var t := float(i) / 17.0
			var p := Vector3(side * lerpf(12.5, 22.0, t), 0, lerpf(1.0, 9.0, t)) + Vector3((h01(i, side, 41) - 0.5) * 1.2, 0, (h01(side, i, 41) - 0.5) * 1.2)
			var hh := lerpf(2.8, 6.5, h01(i, 3 + side, 41)) * (1.0 - 0.35 * t)
			var tilt := Vector3((h01(i, 5, 41) - 0.5) * 0.5, 1.0, (h01(i, 6, 41) - 0.5) * 0.5 + 0.15)
			cw.crystal(p, tilt, hh, lerpf(0.5, 0.95, h01(i, 7, 41)), 6, Color(0.72, 0.86, 0.98, h01(i, 8, 41)))
			if i % 2 == 0:
				cw.crystal(p + Vector3(0.7, 0, 0.5), tilt + Vector3(0.4, 0, 0.2), hh * 0.55, 0.4, 5, Color(0.8, 0.92, 1.0, h01(i, 9, 41)))
	add_mesh(r, r, "Crystals", cw, smat(SH_SOLID, {"vein": Color(0.45, 0.85, 1.0), "energy": 2.2, "tiling": Vector2(2, 5), "scroll": Vector2(0, 0.25),
		"vein_w": 0.7, "rough": 0.15, "spec": 0.9, "rim": 0.7, "tip_glow": 1.2}), true)
	save_fx("torvald", r)

	# the frost burst at his feet (S23, S10): shards radiating out, a glowing frost ring, rising rime
	r = fx_root("FxFrostBurst")
	var fb := MB.new()
	for i in 26:
		var a := TAU * i / 26.0 + (h01(i, 1, 42) - 0.5) * 0.2
		if absf(wrapf(a - PI * 0.5, -PI, PI)) < 1.2:
			continue   # keep the camera side (south) open
		var d := Vector3(cos(a), 0, sin(a))
		var rad := lerpf(2.0, 4.2, h01(i, 2, 42))
		fb.crystal(d * rad, d * 0.9 + Vector3.UP * 0.9, lerpf(0.9, 2.4, h01(i, 3, 42)), lerpf(0.18, 0.34, h01(i, 4, 42)), 5, Color(0.8, 0.92, 1.0, h01(i, 5, 42)))
	add_mesh(r, r, "Shards", fb, smat(SH_SOLID, {"vein": Color(0.5, 0.9, 1.0), "energy": 2.6, "tiling": Vector2(2, 4), "scroll": Vector2(0, 0.4),
		"vein_w": 0.66, "rough": 0.12, "spec": 0.9, "rim": 0.8, "tip_glow": 1.8}), true)
	var ring := MB.new()
	ring.disc(Vector3(0, 0.05, 0), 1.0, 6.5, 48, Color.WHITE, 4)
	add_mesh(r, r, "FrostRing", ring, smat(SH_ADD, {"col_a": Color(0.25, 0.6, 1.0), "col_b": Color(0.85, 0.97, 1.0), "energy": 2.2,
		"scroll": Vector2(0.0, -0.6), "tiling": Vector2(24, 3), "sharp": 2.5, "base": 0.05, "fres": 0.0, "fade_lo": 0.1, "fade_hi": 0.7}))
	particles(r, r, "Rime", {"amount": 90, "life": 3.0, "shape": "ring", "ext": Vector3(4.5, 1.5, 0.3), "dir": Vector3.UP, "spread": 35.0,
		"v": Vector2(0.5, 1.8), "size": Vector2(0.6, 1.3), "quad": 0.2, "seed": 43, "turb": 0.8, "grav": Vector3(0, 0.2, 0),
		"cols": PackedColorArray([Color(1.6, 2.2, 3.0, 0), Color(1.8, 2.4, 3.2, 1), Color(0.6, 1.0, 2.0, 0)])})
	save_fx("torvald", r)

	# the lake freezing in one cracking wave (S10, S22): glowing crack lines out from him across the lake
	r = fx_root("FxLakeCracks")
	var lc := MB.new()
	for i in 34:
		var a := lerpf(0.12, PI - 0.12, h01(i, 1, 44))
		var p := Vector3(0, 0.06, 2.6)
		var d := Vector3(cos(a), 0, sin(a) * 0.8 + 0.2).normalized()
		var steps := 10 + int(h01(i, 2, 44) * 8.0)
		var prev := p
		var dist := 0.0
		for k in steps:
			d = (d + Vector3((h01(i, k, 45) - 0.5) * 0.9, 0, (h01(k, i, 45) - 0.5) * 0.6)).normalized()
			var nx := prev + d * lerpf(1.2, 2.4, h01(i, k + 30, 46))
			nx.y = 0.06
			if nx.z > 15.5 or absf(nx.x) > 31.0:
				break
			var sd := d.cross(Vector3.UP).normalized() * lerpf(0.09, 0.03, float(k) / steps)
			var u0 := dist / 30.0
			dist += prev.distance_to(nx)
			var u1 := dist / 30.0
			var i0 := lc.vert(prev - sd, Vector3.UP, Vector2(0, u0), Color.WHITE)
			var i1 := lc.vert(prev + sd, Vector3.UP, Vector2(1, u0), Color.WHITE)
			var i2 := lc.vert(nx - sd, Vector3.UP, Vector2(0, u1), Color.WHITE)
			var i3 := lc.vert(nx + sd, Vector3.UP, Vector2(1, u1), Color.WHITE)
			lc.tri(i0, i2, i1)
			lc.tri(i1, i2, i3)
			prev = nx
	add_mesh(r, r, "Cracks", lc, smat(SH_ADD, {"col_a": Color(0.3, 0.7, 1.0), "col_b": Color(0.9, 1.0, 1.0), "energy": 3.0,
		"scroll": Vector2(0.0, -0.35), "tiling": Vector2(1, 5), "sharp": 0.8, "base": 0.35, "fres": 0.0, "fade_lo": 0.0001, "fade_hi": 0.4, "dash": 1.2}))
	save_fx("torvald", r)

	# the Heartfrost below the clear ice (S25 tilt-down): a vast sleeping shape, a slow pulse
	r = fx_root("FxHeartfrost")
	var hf := MB.new()
	hf.disc(Vector3(0, 0.16, 0), 0.0, 6.0, 64, Color.WHITE, 6)
	add_mesh(r, r, "Sigil", hf, smat(SH_VEIL, {"dark": Color(0.02, 0.07, 0.2), "glow": Color(0.4, 0.85, 1.0), "energy": 3.0,
		"scroll": Vector2(0.01, -0.05), "tiling": Vector2(16, 5), "twist": 1.0, "streak": 0.6, "opacity": 0.8, "fade_lo": 0.001, "fade_hi": 0.5}))
	var core := MB.new()
	var ep := PackedVector3Array()
	var er := PackedFloat32Array()
	for i in 9:
		var t := float(i) / 8.0
		ep.append(Vector3(lerpf(-2.6, 2.6, t), 0.18, 0))
		er.append(sin(t * PI) * 0.75 + 0.02)
	core.tube(ep, er, 16, Color.WHITE)
	var cm := add_mesh(r, r, "Eye", core, smat(SH_ADD, {"col_a": Color(0.3, 0.8, 1.0), "col_b": Color(0.95, 1.0, 1.0), "energy": 8.0,
		"scroll": Vector2(0.2, 0.0), "tiling": Vector2(6, 2), "sharp": 1.0, "base": 0.5, "fres": 0.0, "fade_lo": 0.0001, "fade_hi": 0.0001, "pulse": 0.4}))
	cm.scale = Vector3(1, 0.12, 1)
	save_fx("torvald", r)

	# snowfall over the lake (a hundred winters, S23 / S24)
	r = fx_root("FxSnow")
	particles(r, r, "Snow", {"amount": 520, "life": 10.0, "shape": "box", "ext": Vector3(24, 1, 16), "pos": Vector3(0, 14, 4),
		"dir": Vector3.DOWN, "spread": 20.0, "v": Vector2(0.6, 1.3), "grav": Vector3(0.5, -0.8, 0.2), "size": Vector2(0.6, 1.2),
		"quad": 0.12, "seed": 47, "turb": 1.0, "additive": false,
		"cols": PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0.95), Color(0.95, 0.98, 1, 0.9), Color(1, 1, 1, 0)]),
		"aabb": AABB(Vector3(-28, -16, -22), Vector3(56, 20, 44))})
	save_fx("torvald", r)


# ================================================================ Ysolde: the blooming tree, the vine surge, the bloom wave

func _fx_ysolde() -> void:
	# a giant tree blooming out of the burn (S27, S11): trunk + branches (lit bark with gold veins), blossom crowns,
	# falling petals, golden motes
	var r := fx_root("FxBloomTree")
	var bark := MB.new()
	bark.tube(PackedVector3Array([Vector3(0, -0.3, 0), Vector3(0.2, 3, 0.1), Vector3(-0.3, 6.5, -0.2), Vector3(0.1, 10, 0.1), Vector3(0.3, 13, 0)]),
		PackedFloat32Array([1.5, 1.0, 0.8, 0.55, 0.3]), 12, Color(0.36, 0.25, 0.16, 0.1))
	var crowns: Array = [Vector3(0.3, 14.2, 0)]
	for i in 7:
		var a := TAU * i / 7.0 + 0.4
		var y0 := lerpf(5.5, 11.0, h01(i, 1, 51))
		var l := lerpf(3.5, 6.0, h01(i, 2, 51))
		var tip := Vector3(cos(a) * l, y0 + l * 0.55, sin(a) * l)
		bark.tube(PackedVector3Array([Vector3(0, y0, 0), Vector3(cos(a) * l * 0.5, y0 + l * 0.35, sin(a) * l * 0.5), tip]),
			PackedFloat32Array([0.45, 0.3, 0.1]), 8, Color(0.34, 0.24, 0.15, h01(i, 3, 51)))
		crowns.append(tip + Vector3(0, 0.8, 0))
	for i in 5:
		var a := TAU * i / 5.0
		bark.tube(PackedVector3Array([Vector3(0, 0.6, 0), Vector3(cos(a) * 1.6, 0.2, sin(a) * 1.6), Vector3(cos(a) * 3.0, -0.2, sin(a) * 3.0)]),
			PackedFloat32Array([0.7, 0.4, 0.1]), 8, Color(0.33, 0.23, 0.14, 0.3))
	add_mesh(r, r, "Bark", bark, smat(SH_SOLID, {"vein": Color(1.0, 0.85, 0.35), "energy": 2.2, "tiling": Vector2(3, 8), "scroll": Vector2(0, 0.4),
		"vein_w": 0.8, "rough": 0.85, "spec": 0.2, "rim": 0.3, "tip_glow": 0.0}), true)
	var bloom := MB.new()
	var ci := 0
	for c: Vector3 in crowns:
		var s := lerpf(2.2, 3.4, h01(ci, 4, 51)) * (1.4 if ci == 0 else 1.0)
		for k in 3:
			var o := Vector3((h01(ci, k, 52) - 0.5) * s, (h01(k, ci, 52) - 0.5) * s * 0.4, (h01(ci + 9, k, 52) - 0.5) * s)
			var rs := PackedFloat32Array()
			var ps := PackedVector3Array()
			for q in 7:
				var t := float(q) / 6.0
				ps.append(c + o + Vector3(0, (t - 0.5) * s * 1.2, 0))
				rs.append(sin(t * PI) * s * 0.65 + 0.01)
			var pink := Color(1.0, 0.62, 0.8, h01(ci, k, 53)) if (ci + k) % 3 != 0 else Color(0.55, 0.85, 0.35, h01(ci, k, 53))
			bloom.tube(ps, rs, 12, pink)
		ci += 1
	add_mesh(r, r, "Blossoms", bloom, smat(SH_SOLID, {"vein": Color(1.0, 0.7, 0.9), "energy": 1.6, "tiling": Vector2(8, 6), "scroll": Vector2(0.05, 0.1),
		"vein_w": 0.74, "rough": 0.7, "spec": 0.2, "rim": 0.6, "sway": 0.25, "tip_glow": 0.0}), true)
	particles(r, r, "Petals", {"amount": 160, "life": 7.0, "shape": "sphere", "ext": Vector3(7, 0, 0), "pos": Vector3(0, 11, 0),
		"dir": Vector3.DOWN, "spread": 60.0, "v": Vector2(0.2, 0.8), "grav": Vector3(0.5, -0.9, 0.3), "size": Vector2(0.6, 1.2),
		"quad": 0.2, "seed": 54, "turb": 1.4, "additive": false,
		"cols": PackedColorArray([Color(1, 0.7, 0.85, 0), Color(1.3, 0.8, 1.0, 1), Color(1.2, 0.75, 0.9, 1), Color(1, 0.6, 0.8, 0)]),
		"aabb": AABB(Vector3(-14, -2, -14), Vector3(28, 22, 28))})
	particles(r, r, "Motes", {"amount": 90, "life": 5.0, "shape": "sphere", "ext": Vector3(8, 0, 0), "pos": Vector3(0, 6, 0),
		"dir": Vector3.UP, "spread": 40.0, "v": Vector2(0.3, 0.9), "size": Vector2(0.6, 1.2), "quad": 0.16, "seed": 55, "turb": 1.0,
		"cols": PackedColorArray([Color(3, 2.4, 0.8, 0), Color(3, 2.6, 0.9, 1), Color(1.2, 1.6, 0.4, 0)]),
		"aabb": AABB(Vector3(-14, -2, -14), Vector3(28, 22, 28))})
	save_fx("ysolde", r)

	# the vine surge: vines bursting out of the burn in a wave from her toward the fallen fire host (S27, S27U)
	r = fx_root("FxVineSurge")
	var vb := MB.new()
	for i in 34:
		var t0 := h01(i, 1, 56)
		var base := Vector3(lerpf(5.5, 13.0, t0), 0, lerpf(-1.5, 6.0, t0)) + Vector3((h01(i, 2, 56) - 0.5) * 4.0, 0, (h01(i, 3, 56) - 0.5) * 3.0)
		if base.distance_to(Vector3(3, 0, 1)) < 2.6 or base.distance_to(Vector3(3.7, 0, 3.8)) < 3.0 or base.distance_to(Vector3(8.5, 0, -2.5)) < 1.6 or base.distance_to(Vector3(12, 0, 11)) < 4.5:
			continue   # keep Ysolde, the S29 camera and the treant clear (set coordinates, actor at (0, 0))
		var hh := lerpf(0.9, 2.6, h01(i, 4, 56))
		var ps := PackedVector3Array()
		var rs := PackedFloat32Array()
		var ph := h01(i, 5, 56) * TAU
		for k in 12:
			var t := float(k) / 11.0
			ps.append(base + Vector3(sin(t * 5.0 + ph) * 0.6 * t, sin(t * PI * 0.9) * hh, cos(t * 4.0 + ph) * 0.6 * t + t * 0.9))
			rs.append(lerpf(0.1, 0.012, t))
		vb.tube(ps, rs, 6, Color(0.25, 0.5, 0.15, h01(i, 6, 56)))
		for k in 3:
			var lp: Vector3 = ps[3 + k * 3]
			vb.crystal(lp, Vector3(sin(ph + k), 0.6, cos(ph + k)), 0.28, 0.07, 3, Color(0.4, 0.75, 0.2, 0.5))
	add_mesh(r, r, "Vines", vb, smat(SH_SOLID, {"vein": Color(0.75, 1.0, 0.35), "energy": 2.4, "tiling": Vector2(2, 6), "scroll": Vector2(0, -0.9),
		"vein_w": 0.74, "rough": 0.6, "spec": 0.3, "rim": 0.5, "sway": 0.25, "tip_glow": 1.6}), true)
	var wave := MB.new()
	wave.disc(Vector3(3, 0.07, 1), 2.0, 10.0, 56, Color.WHITE, 5)
	add_mesh(r, r, "BloomWave", wave, smat(SH_ADD, {"col_a": Color(0.35, 0.9, 0.2), "col_b": Color(1.0, 0.9, 0.4), "energy": 1.8,
		"scroll": Vector2(0.0, -0.45), "tiling": Vector2(28, 3), "sharp": 2.0, "base": 0.05, "fres": 0.0, "fade_lo": 0.2, "fade_hi": 0.5}))
	particles(r, r, "Leaves", {"amount": 120, "life": 4.0, "shape": "ring", "ext": Vector3(6, 2, 0.3), "pos": Vector3(3, 0, 1), "dir": Vector3.UP, "spread": 20.0,
		"v": Vector2(1.5, 3.5), "tang": 3.0, "radial": -0.4, "size": Vector2(0.6, 1.2), "quad": 0.2, "seed": 57, "turb": 0.8,
		"cols": PackedColorArray([Color(0.8, 2.0, 0.4, 0), Color(1.0, 2.4, 0.5, 1), Color(2.0, 1.8, 0.4, 0.8), Color(1, 1, 0.3, 0)]),
		"aabb": AABB(Vector3(-12, -2, -12), Vector3(24, 16, 24))})
	save_fx("ysolde", r)
