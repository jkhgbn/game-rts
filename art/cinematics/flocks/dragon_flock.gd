class_name DragonFlock
extends Node3D
## Dragon sky (prologue P3, art/cinematics/flocks/README.md): 30-60+ flyers of three sizes (cloud-sized elders, big
## dragons / rocs / wyrms, swallow-sized flights) on looping flight paths over the node, with banking, varied wing
## phases and glides. Reuses the real flyer models (FlockKinds): the first `heroes` big flyers ARE the real model
## (its pivots driven here, its own clock switched off), every other flyer is a baked impostor drawn by one MultiMesh
## per kind and LOD (near = the merged model, far = a clustered copy, switched by projected size).
## Deterministic: every pose is a pure function of (flock_seed, time). The time comes from, in order:
##   set_cine_time(t) (a driver calls it every frame / on seek; group "cine_timed"), a playing CinematicPlayer
##   (elapsed()), a playing cine CinePreview (t), else its own clock (delta sum, exact under --fixed-fps).
## Place: any scene / set / .cine prop at the flock centre on the ground (heights are relative to this node).

const ROLE_ELDER := 0
const ROLE_BIG := 1
const ROLE_SMALL := 2
const G := 9.8

@export var flock_seed: int = 7
## Kinds (FlockKinds.KINDS ids) for the big flyers and the elders / for the small recoloured flights.
@export var kinds_big: PackedStringArray = PackedStringArray(["cinder_dragon", "frost_dragon", "roc", "frost_wyrm", "hoarfang", "roc_dusk"])
@export var kinds_elder: PackedStringArray = PackedStringArray(["frost_dragon", "cinder_dragon"])
@export var kinds_small: PackedStringArray = PackedStringArray(["cinder_dragon", "frost_dragon", "roc", "roc_dusk"])
@export_range(0, 12) var elders: int = 2
@export_range(0, 60) var big: int = 10
@export_range(0, 200) var small: int = 42
## Small flyers fly in flights (loose groups sharing a path) of 3..flight_size.
@export_range(1, 12) var flight_size: int = 7
## How many elders / big flyers (in that order) are drawn with the real model. The rest are impostors.
## Each hero costs ~40 draw calls (the models have many surfaces); impostors cost 1 draw per kind and LOD in use.
@export_range(0, 16) var heroes: int = 2
## Big flyers 0 and 1 fly wing to wing (the first two of kinds_big: a cinder and a frost dragon).
@export var pair: bool = true
@export var elder_scale := Vector2(4.0, 5.0)
@export var big_scale := Vector2(0.9, 1.4)
@export var small_scale := Vector2(0.16, 0.34)
## Horizontal radius of the flock (m) and flight heights (m above this node).
@export var radius: float = 90.0
@export var height := Vector2(22.0, 70.0)
@export var elder_height := Vector2(75.0, 115.0)
## Mean air speeds (m/s).
@export var speed_elder: float = 6.0
@export var speed_big: float = 13.0
@export var speed_small: float = 16.0
## "mixed", "orbit", "figure8" or "wander" (every pattern loops).
@export_enum("mixed", "orbit", "figure8", "wander") var pattern: String = "mixed"
## Bank = atan(lateral g) x bank_gain, clamped to the kind's bank_max.
@export var bank_gain: float = 2.2
## Recolours of the small flyers (baby / young dragons); tint_share of them get one.
@export var tints: PackedColorArray = PackedColorArray([Color(1.0, 0.62, 0.2), Color(0.38, 0.66, 0.3),
	Color(0.58, 0.38, 0.85), Color(0.92, 0.88, 0.8), Color(0.3, 0.52, 0.9), Color(0.88, 0.42, 0.45)])
@export_range(0.0, 1.0) var tint_share: float = 0.6
@export_range(0.0, 0.99) var tint_strength: float = 0.75
## Impostor LOD: below this projected size (pixels, wingspan) the far mesh is drawn.
@export var lod_px: float = 70.0
@export var hero_shadows: bool = false
## Flock time = source time x time_scale + time_offset (s).
@export var time_offset: float = 0.0
@export var time_scale: float = 1.0
## Arrival (flock time): before it the flyers fly in (from below / outside), staggered over arrive_spread s. < 0 = off.
@export var arrive_until: float = -1.0
@export var arrive_spread: float = 6.0
@export var arrive_from := Vector3(0.0, -0.8, 0.0)
## Departure (flock time): from it the flyers leave toward leave_dir (mixed with their outward direction), staggered
## over leave_spread s; 30 s after the last one left the flock stops drawing. < 0 = off.
@export var leave_at: float = -1.0
@export var leave_spread: float = 5.0
@export var leave_dir := Vector3(0.0, 0.35, -1.0)

var _flyers: Array[Dictionary] = []
var _kinds: Dictionary = {}          # kind -> baked dict + {mm_near, mm_far, n}
var _heroes: Array[Dictionary] = []  # {holder, model, piv: {path: Node3D}, rest, flyer}
var _built := false
var _own_t := 0.0
var _ext_t := 0.0
var _ext_frame := -10
var _last_t := -1.0
var _preview: Node = null
var _preview_search := 0
var _stats := {"near": 0, "far": 0}


func _ready() -> void:
	add_to_group(&"cine_timed")
	add_to_group(&"flocks")
	process_mode = Node.PROCESS_MODE_ALWAYS
	rebuild()


# ================================================================ public API

## (Re)creates every flyer from the exports (same seed = same flock).
func rebuild() -> void:
	for c: Node in get_children():
		if c.has_meta(&"flock_part"):
			remove_child(c)
			c.queue_free()
	_flyers.clear()
	_heroes.clear()
	_kinds.clear()
	_make_flyers()
	_make_draw()
	_built = true
	update_at(_time_now(0.0))


## A driver (cine preview pose, CinematicPlayer seek, a test) sets the cine time; the flock poses itself at once.
func set_cine_time(t: float) -> void:
	_ext_t = t
	_ext_frame = Engine.get_process_frames()
	update_at(t * time_scale + time_offset)


## The flock time last drawn.
func flock_time() -> float:
	return _last_t


func flyer_count() -> int:
	return _flyers.size()


func hero_count() -> int:
	return _heroes.size()


## Pose of flyer i at flock time t (pure): {xform (flock-local, body centre, scale included), flap, aw, slow, bank_deg,
## kind, role, scale, hero}.
func flyer_state(i: int, t: float) -> Dictionary:
	var f: Dictionary = _flyers[i]
	var dt := 0.08
	var p0 := _pos_at(f, t - dt)
	var p1 := _pos_at(f, t)
	var p2 := _pos_at(f, t + dt)
	var vel := (p2 - p0) / (2.0 * dt)
	var acc := (p2 - 2.0 * p1 + p0) / (dt * dt)
	var fw := vel.normalized() if vel.length() > 0.01 else Vector3.BACK
	fw.y = clampf(fw.y, -0.5, 0.5)
	fw = fw.normalized()
	var xa := Vector3.UP.cross(fw).normalized()
	var ya := fw.cross(xa)
	var bmax := deg_to_rad(float(f["bank_max"]))
	var bank := clampf(atan2(acc.dot(xa) * bank_gain, G), -bmax, bmax)
	# flap / glide schedule (glide beats are whole beats, so the phase is continuous over the cycle)
	var per: float = f["period"]
	var nb: int = f["nb"]
	var ng: int = f["ng"]
	var cyc := float(nb + ng) * per
	var u := fposmod(t + float(f["flap_off"]), cyc)
	var flap := fposmod(u / per, 1.0)
	var aw := 1.0
	if ng > 0:
		var s0 := float(nb) * per
		aw = clampf(1.0 - smoothstep(s0 - 0.15 * per, s0 + 0.5 * per, u) + smoothstep(cyc - 0.6 * per, cyc, u), 0.0, 1.0)
	var slow := t * float(f["slow_rate"]) + float(f["slow_off"])
	var psi := 0.5 * flap / 0.45 if flap < 0.45 else 0.5 + 0.5 * (flap - 0.45) / 0.55
	var c := cos(TAU * psi)
	var sc: float = f["scale"]
	var pitch_bob := deg_to_rad(3.0 * sin(TAU * psi - 0.6) * aw)
	var basis := Basis(xa, ya, fw) * Basis(Vector3.BACK, -bank) * Basis(Vector3.RIGHT, pitch_bob)
	var pos := p1 + ya * (-0.09 * c * aw * sc)
	return {"xform": Transform3D(basis.scaled_local(Vector3.ONE * sc), pos), "flap": flap, "aw": aw, "slow": slow,
		"psi": psi, "c": c, "bank": bank / maxf(bmax, 0.001), "bank_deg": rad_to_deg(bank), "kind": f["kind"],
		"role": f["role"], "scale": sc, "hero": int(f["hero"]) >= 0}


## Global body-centre position of flyer i at flock time t (for a follow camera or a marker).
func flyer_position(i: int, t: float) -> Vector3:
	return global_transform * _pos_at(_flyers[i], t)


## Budget numbers: flyers, heroes, draw calls (hero meshes + multimeshes in use), vertices drawn at the last update.
func budget() -> Dictionary:
	var hero_draws := 0
	var hero_verts := 0
	for h: Dictionary in _heroes:
		for gi: Node in (h["model"] as Node).find_children("*", "MeshInstance3D", true, false):
			var mi := gi as MeshInstance3D
			if mi.is_visible_in_tree() and mi.mesh:
				hero_draws += mi.mesh.get_surface_count()
				for s: int in mi.mesh.get_surface_count():
					hero_verts += mi.mesh.surface_get_array_len(s)
	var mm_draws := 0
	var verts := hero_verts
	for kind: String in _kinds:
		var kd: Dictionary = _kinds[kind]
		for pair: Array in [["mm_near", "verts_near"], ["mm_far", "verts_far"]]:
			var mmi := kd[pair[0]] as MultiMeshInstance3D
			var vis := mmi.multimesh.visible_instance_count
			if vis > 0:
				mm_draws += 1
				verts += vis * int(kd[pair[1]])
	return {"flyers": _flyers.size(), "heroes": _heroes.size(), "kinds": _kinds.size(), "hero_draws": hero_draws,
		"impostor_draws": mm_draws, "draws": hero_draws + mm_draws, "verts": verts, "near": _stats["near"],
		"far": _stats["far"], "lights": 0}


## Poses everything at flock time t (pure: the same t always gives the same frame).
func update_at(t: float) -> void:
	if not _built:
		return
	_last_t = t
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	var cam_pos := Vector3.ZERO
	var k_px := 0.0
	if cam:
		cam_pos = cam.global_position
		var vh := float(get_viewport().get_visible_rect().size.y)
		k_px = vh / (2.0 * tan(deg_to_rad(cam.fov) * 0.5))
	var gone := leave_at >= 0.0 and t > leave_at + leave_spread + 30.0
	var near_n := {}
	var far_n := {}
	var nn := 0
	var fn := 0
	for kind: String in _kinds:
		near_n[kind] = 0
		far_n[kind] = 0
	for i: int in _flyers.size():
		var f: Dictionary = _flyers[i]
		if gone:
			continue
		var st := flyer_state(i, t)
		var xf: Transform3D = st["xform"]
		if int(f["hero"]) >= 0:
			_pose_hero(_heroes[int(f["hero"])], st)
			continue
		var kind: String = f["kind"]
		var kd: Dictionary = _kinds[kind]
		var far := false
		if cam:
			var d := cam_pos.distance_to(global_transform * xf.origin)
			far = maxf(float(kd["span"]), float(kd["length"])) * float(f["scale"]) * k_px / maxf(d, 0.1) < lod_px
		var custom := Color(float(st["flap"]), float(st["aw"]), float(st["slow"]), float(f["tint"]))
		var mm: MultiMesh
		var idx: int
		if far:
			mm = (kd["mm_far"] as MultiMeshInstance3D).multimesh
			idx = far_n[kind]
			far_n[kind] = idx + 1
			fn += 1
		else:
			mm = (kd["mm_near"] as MultiMeshInstance3D).multimesh
			idx = near_n[kind]
			near_n[kind] = idx + 1
			nn += 1
		mm.set_instance_transform(idx, xf)
		mm.set_instance_custom_data(idx, custom)
	for kind: String in _kinds:
		var kd: Dictionary = _kinds[kind]
		(kd["mm_near"] as MultiMeshInstance3D).multimesh.visible_instance_count = near_n[kind]
		(kd["mm_far"] as MultiMeshInstance3D).multimesh.visible_instance_count = far_n[kind]
	for h: Dictionary in _heroes:
		(h["holder"] as Node3D).visible = not gone
	_stats["near"] = nn
	_stats["far"] = fn


# ================================================================ per frame

func _process(delta: float) -> void:
	if not _built or not is_visible_in_tree():
		return
	var t := _time_now(delta)
	if Engine.get_process_frames() - _ext_frame <= 1:
		return   # a driver already posed this frame (set_cine_time)
	update_at(t)


func _time_now(delta: float) -> float:
	var src := -1.0
	if Engine.get_process_frames() - _ext_frame <= 1:
		src = _ext_t
	if src < 0.0 and is_inside_tree():
		var p := get_tree().get_first_node_in_group(&"cinematic_player")
		if p and p.has_method(&"is_playing") and bool(p.call(&"is_playing")):
			src = float(p.call(&"elapsed"))
	if src < 0.0 and is_inside_tree():
		if _preview == null or not is_instance_valid(_preview):
			_preview = null
			_preview_search -= 1
			if _preview_search <= 0:
				_preview_search = 30
				for c: Node in get_tree().root.get_children():
					var s: Script = c.get_script()
					if s and s.get_global_name() == &"CinePreview":
						_preview = c
						break
		if _preview and bool(_preview.get(&"playing")):
			src = maxf(float(_preview.get(&"t")), 0.0)
	if src < 0.0:
		_own_t += delta
		src = _own_t
	return src * time_scale + time_offset


# ================================================================ flyers

func _make_flyers() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(flock_seed) ^ 0x5eed
	# elders: slow wide loops high up
	for e: int in elders:
		var f := _new_path(rng, ROLE_ELDER, _pick(rng, kinds_elder, "frost_dragon"), elder_scale, elder_height,
			speed_elder, radius * 1.1)
		_flyers.append(f)
	# big: the pair first, then the rest
	var b := 0
	while b < big:
		var kind := String(kinds_big[b % kinds_big.size()]) if b < 2 else _pick(rng, kinds_big, "cinder_dragon")
		var f := _new_path(rng, ROLE_BIG, kind, big_scale, height, speed_big, radius)
		if pair and b == 0 and big >= 2:
			var f2 := f.duplicate()
			f2["kind"] = String(kinds_big[1 % kinds_big.size()])
			var span := 9.0 * float(f["scale"])
			f["offset"] = Vector3(-0.55 * span, 0.0, 0.0)
			f2["offset"] = Vector3(0.55 * span, 0.4, -0.6)
			f2["flap_off"] = float(f["flap_off"]) + 0.37
			f2["wob"] = float(f["wob"]) + 2.1
			_finish_kind(f2)
			_flyers.append(f)
			_flyers.append(f2)
			b += 2
			continue
		_flyers.append(f)
		b += 1
	# small: flights sharing a leader path
	var s := 0
	while s < small:
		var n := mini(small - s, rng.randi_range(mini(3, flight_size), maxi(3, flight_size)))
		var kind := _pick(rng, kinds_small, "cinder_dragon")
		var lead := _new_path(rng, ROLE_SMALL, kind, small_scale, height, speed_small, radius)
		var tint := -1
		if rng.randf() < tint_share and tints.size() > 0:
			tint = rng.randi_range(0, tints.size() - 1)
		for m: int in n:
			var f := lead.duplicate()
			var sc := float(lead["scale"]) * rng.randf_range(0.85, 1.15)
			f["scale"] = sc
			var row := float((m + 1) / 2)
			var side := -1.0 if m % 2 == 1 else 1.0
			# a loose V: each pair a little behind and to the side of the one before
			var jit := Vector3(rng.randf_range(-0.6, 0.6), rng.randf_range(-0.8, 0.8), rng.randf_range(-0.6, 0.6))
			f["offset"] = Vector3.ZERO
			if m > 0:
				f["offset"] = (Vector3(side * row * 3.2, 0.0, -row * 2.6) + jit) * maxf(sc / 0.25, 0.6)
			f["flap_off"] = rng.randf_range(0.0, 10.0)
			f["wob"] = rng.randf_range(0.0, TAU)
			f["period"] = float(lead["period"]) * rng.randf_range(0.92, 1.08)
			var tc := tint
			if tc >= 0 and rng.randf() < 0.25:
				tc = rng.randi_range(0, tints.size() - 1)
			f["tint"] = _pack_tint(tints[tc], tint_strength) if tc >= 0 else 0.0
			_flyers.append(f)
		s += n
	# depart / arrive order and directions (seeded, per flyer)
	for f: Dictionary in _flyers:
		var out := Vector3(f["centre"].x, 0.0, f["centre"].z)
		if out.length() < 1.0:
			out = Vector3(1, 0, 0).rotated(Vector3.UP, rng.randf_range(0.0, TAU))
		out = out.normalized()
		f["leave_delay"] = rng.randf_range(0.0, leave_spread)
		f["arrive_delay"] = rng.randf_range(0.0, arrive_spread)
		f["leave_v"] = (out * 0.6 + leave_dir.normalized() + Vector3(0, 0.25, 0)).normalized()
		f["arrive_v"] = (out * 0.6 + arrive_from).normalized() if arrive_from.length() > 0.01 else out
	# heroes: elders first, then big (hero-capable kinds only)
	var nh := 0
	for f: Dictionary in _flyers:
		f["hero"] = -1
		if nh < heroes and int(f["role"]) != ROLE_SMALL and bool(FlockKinds.info(f["kind"])["hero"]):
			f["hero"] = nh
			nh += 1


func _pick(rng: RandomNumberGenerator, list: PackedStringArray, fallback: String) -> String:
	var ok: Array[String] = []
	for k: String in list:
		if FlockKinds.has_kind(k):
			ok.append(k)
	if ok.is_empty():
		return fallback
	return ok[rng.randi_range(0, ok.size() - 1)]


func _new_path(rng: RandomNumberGenerator, role: int, kind: String, scale_r: Vector2, h_r: Vector2, speed: float,
		rad: float) -> Dictionary:
	var pats := ["orbit", "figure8", "wander"]
	var pat := pattern if pattern != "mixed" else String(pats[rng.randi_range(0, 2)])
	var r := rng.randf_range(0.35, 0.8) * rad
	var sc := rng.randf_range(scale_r.x, scale_r.y)
	var sp := speed * rng.randf_range(0.85, 1.15)
	var f := {
		"kind": kind, "role": role, "scale": sc, "pat": pats.find(pat),
		"centre": Vector3(rng.randf_range(-0.35, 0.35) * rad, 0.0, rng.randf_range(-0.35, 0.35) * rad),
		"rx": r * rng.randf_range(0.8, 1.2), "rz": r * rng.randf_range(0.7, 1.1),
		"yaw": rng.randf_range(0.0, TAU), "h": rng.randf_range(h_r.x, h_r.y),
		"ay": rng.randf_range(2.0, 7.0) * (2.0 if role == ROLE_ELDER else 1.0),
		"a2": rng.randf_range(0.08, 0.3), "a3": rng.randf_range(0.0, 0.15),
		"b2": rng.randf_range(0.08, 0.3), "b3": rng.randf_range(0.0, 0.15),
		"p2": rng.randf_range(0.0, TAU), "p3": rng.randf_range(0.0, TAU), "p4": rng.randf_range(0.0, TAU),
		"q2": rng.randf_range(0.0, TAU), "q3": rng.randf_range(0.0, TAU),
		"dir": 1.0 if rng.randf() < 0.5 else -1.0, "th0": rng.randf_range(0.0, TAU),
		"flap_off": rng.randf_range(0.0, 10.0), "slow_off": rng.randf_range(0.0, TAU),
		"offset": Vector3.ZERO, "wob": rng.randf_range(0.0, TAU), "tint": 0.0, "hero": -1, "speed": sp,
	}
	# omega from the mean radius (the loop period stays exact whatever the shape)
	var perim := PI * (float(f["rx"]) + float(f["rz"])) * (1.6 if pat == "figure8" else 1.0)
	f["w"] = float(f["dir"]) * TAU * sp / maxf(perim, 1.0)
	_finish_kind(f)
	return f


## Kind-dependent timing: flap period (small ones beat faster), glides, bank limit.
func _finish_kind(f: Dictionary) -> void:
	var k := FlockKinds.info(f["kind"])
	var sc: float = f["scale"]
	var serp := String(k["style"]) == "serpent"
	f["period"] = float(k["period"]) * clampf(sqrt(sc), 0.45, 1.9)
	f["bank_max"] = float(k["bank"]) * (1.3 if int(f["role"]) == ROLE_SMALL else 1.0)
	var r := int(abs(hash(str(f["th0"]))) % 3)
	if serp:
		f["nb"] = 1
		f["ng"] = 0
		f["slow_rate"] = 1.4 / clampf(sqrt(sc), 0.6, 2.2)
	elif int(f["role"]) == ROLE_SMALL:
		f["nb"] = 3 + r
		f["ng"] = 0 if r == 0 else 2
		f["slow_rate"] = 2.4
	else:
		f["nb"] = 2 + r
		f["ng"] = 2 + r % 2
		f["slow_rate"] = 1.9 / clampf(sqrt(sc), 0.6, 2.2)


static func _pack_tint(c: Color, strength: float) -> float:
	var code := int(roundf(clampf(c.r, 0, 1) * 31.0)) * 1024 + int(roundf(clampf(c.g, 0, 1) * 31.0)) * 32 \
		+ int(roundf(clampf(c.b, 0, 1) * 31.0))
	return float(code) + clampf(strength, 0.0, 0.99)


## Path position (flock-local) at flock time t: the loop, the flight offset + wobble, arrival and departure.
func _pos_at(f: Dictionary, t: float) -> Vector3:
	var th: float = float(f["th0"]) + float(f["w"]) * t
	var rx: float = f["rx"]
	var rz: float = f["rz"]
	var x: float
	var z: float
	var y: float
	match int(f["pat"]):
		0:
			x = rx * (cos(th) + float(f["a3"]) * cos(3.0 * th + float(f["p3"])))
			z = rz * (sin(th) + float(f["b3"]) * sin(3.0 * th + float(f["q3"])))
			y = float(f["ay"]) * sin(2.0 * th + float(f["p4"]))
		1:
			x = rx * sin(th)
			z = rz * sin(th) * cos(th) * 1.6
			y = float(f["ay"]) * sin(th + float(f["p4"]))
		_:
			x = rx * (cos(th) + float(f["a2"]) * cos(2.0 * th + float(f["p2"])) + float(f["a3"]) * sin(3.0 * th + float(f["p3"])))
			z = rz * (sin(th) + float(f["b2"]) * sin(2.0 * th + float(f["q2"])) + float(f["b3"]) * cos(3.0 * th + float(f["q3"])))
			y = float(f["ay"]) * sin(2.0 * th + float(f["p4"]))
	var p := Vector3(x, y, z).rotated(Vector3.UP, f["yaw"]) + (f["centre"] as Vector3) + Vector3(0, float(f["h"]), 0)
	var off: Vector3 = f["offset"]
	if off != Vector3.ZERO or int(f["role"]) == ROLE_SMALL:
		# the offset lives in the path frame (right, up, forward) + a slow wobble
		var q := Vector3(rx * cos(th + 0.01 * signf(float(f["w"]))), 0, rz * sin(th + 0.01 * signf(float(f["w"])))).rotated(Vector3.UP, f["yaw"])
		var q0 := Vector3(rx * cos(th), 0, rz * sin(th)).rotated(Vector3.UP, f["yaw"])
		var fw := (q - q0).normalized() if (q - q0).length() > 0.00001 else Vector3.BACK
		var rt := Vector3.UP.cross(fw).normalized()
		var wb: float = f["wob"]
		var sc: float = f["scale"]
		var wob := Vector3(sin(t * 0.7 + wb) * 0.8, sin(t * 0.93 + wb * 1.3) * 0.5, sin(t * 0.51 + wb * 0.7) * 1.0) \
			* maxf(sc / 0.25, 1.0) * (1.0 if int(f["role"]) == ROLE_SMALL else 0.4)
		p += rt * (off.x + wob.x) + Vector3.UP * (off.y + wob.y) + fw * (off.z + wob.z)
	var sp: float = f["speed"]
	if arrive_until >= 0.0:
		var s := arrive_until - float(f["arrive_delay"]) - t
		if s > 0.0:
			p += (f["arrive_v"] as Vector3) * _ease_dist(s, sp)
	if leave_at >= 0.0:
		var s2 := t - leave_at - float(f["leave_delay"])
		if s2 > 0.0:
			p += (f["leave_v"] as Vector3) * _ease_dist(s2, sp)
	return p


## Distance covered s seconds into a departure (accelerates for 3 s, then 1.5 x the cruise speed).
static func _ease_dist(s: float, sp: float) -> float:
	var ramp := 3.0
	var v := sp * 1.5
	return v * s * s / (2.0 * ramp) if s < ramp else v * (s - ramp * 0.5)


# ================================================================ drawing

func _make_draw() -> void:
	var count := {}
	for f: Dictionary in _flyers:
		if int(f["hero"]) < 0:
			count[f["kind"]] = int(count.get(f["kind"], 0)) + 1
	var ext := radius * 2.5 + 200.0
	var box := AABB(Vector3(-ext, -60.0, -ext), Vector3(ext * 2.0, elder_height.y + 260.0, ext * 2.0))
	for kind: String in count:
		var bk := FlockKinds.baked(kind, self)
		if bk.is_empty():
			continue
		var kd := bk.duplicate()
		for lod: String in ["near", "far"]:
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.use_custom_data = true
			mm.mesh = bk[lod]
			mm.instance_count = int(count[kind])
			mm.visible_instance_count = 0
			var mmi := MultiMeshInstance3D.new()
			mmi.name = "Flock_%s_%s" % [kind, lod]
			mmi.multimesh = mm
			mmi.material_override = bk["material"]
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mmi.custom_aabb = box
			mmi.set_meta(&"flock_part", true)
			add_child(mmi)
			kd["mm_" + lod] = mmi
		_kinds[kind] = kd
	for f: Dictionary in _flyers:
		if int(f["hero"]) >= 0:
			_heroes.append(_make_hero(f))


func _make_hero(f: Dictionary) -> Dictionary:
	var k := FlockKinds.info(f["kind"])
	var m := (load(String(k["scene"])) as PackedScene).instantiate() as Node3D
	var rest := FlockKinds.rest_pose(m)
	var holder := Node3D.new()
	holder.name = "Hero_%s_%d" % [f["kind"], _heroes.size()]
	holder.set_meta(&"flock_part", true)
	add_child(holder)
	holder.add_child(m)
	m.set_process(false)
	m.set_physics_process(false)
	if int(k["variant"]) >= 0 and m.has_method(&"set_variant"):
		m.call(&"set_variant", int(k["variant"]))
	FlockKinds.apply_rest(m, rest)
	for nm: String in ["Shadow", "Fx"]:
		var n := m.get_node_or_null(NodePath(nm)) as Node3D
		if n:
			n.visible = false
	for gp: Node in m.find_children("*", "GPUParticles3D", true, false):
		(gp as GPUParticles3D).emitting = false
		(gp as GPUParticles3D).visible = false
	if not hero_shadows:
		for gi: Node in m.find_children("*", "GeometryInstance3D", true, false):
			(gi as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var body := m.get_node_or_null(^"Root/Body") as Node3D
	var centre := (rest.get("Root", Vector3.ZERO) as Vector3) + (rest.get("Root/Body", Vector3(0, 4, 0)) as Vector3)
	m.position = -centre
	var piv := {}
	for path: String in rest:
		piv[path] = m.get_node(NodePath(path))
	var wa: Variant = m.get(&"wing_axis")
	var ha: Variant = m.get(&"hand_axis")
	var h := {"holder": holder, "model": m, "piv": piv, "rest": rest, "flyer": f, "k": k,
		"wing_axis": wa if wa is Array else [Vector3(0, 0, -1), Vector3(0, 0, -1)],
		"hand_axis": ha if ha is Array else [Vector3(0, 0, -1), Vector3(0, 0, -1)], "body": body}
	return h


## The real model posed like flyer_model.gd's forward flight (same wing curve as the impostor shader).
func _pose_hero(h: Dictionary, st: Dictionary) -> void:
	(h["holder"] as Node3D).transform = st["xform"]
	var k: Dictionary = h["k"]
	var aw: float = st["aw"]
	var gw := 1.0 - aw
	var psi: float = st["psi"]
	var c: float = st["c"]
	var slow: float = st["slow"]
	var bank: float = st["bank"]
	var soar := sin(slow)
	var raise := deg_to_rad((float(k["mid"]) + float(k["amp"]) * c) * aw + gw * (2.0 + 3.0 * soar))
	var hand := deg_to_rad((-float(k["hand"]) * sin(TAU * psi - 0.9) - 6.0) * aw + gw * (5.0 + 2.0 * soar))
	var sweep := deg_to_rad(4.0 * sin(TAU * psi + 0.4) * aw)
	var flick := deg_to_rad(3.0 * sin(TAU * psi + 1.2) * aw)
	var wa: Array = h["wing_axis"]
	var ha: Array = h["hand_axis"]
	_set_piv(h, "Root/Body/WingL", Basis(wa[0], raise) * Basis.from_euler(Vector3(0, sweep, 0)))
	_set_piv(h, "Root/Body/WingR", Basis(wa[1], -raise) * Basis.from_euler(Vector3(0, -sweep, 0)))
	_set_piv(h, "Root/Body/WingL/WingL2", Basis(ha[0], hand) * Basis.from_euler(Vector3(0, flick, 0)))
	_set_piv(h, "Root/Body/WingR/WingR2", Basis(ha[1], -hand) * Basis.from_euler(Vector3(0, -flick, 0)))
	var d := PI / 180.0
	_set_piv(h, "Root/Body/Neck1", Basis.from_euler(Vector3(3.0 * c * aw * d, 12.0 * bank * d, 0)))
	_set_piv(h, "Root/Body/Neck1/Neck2", Basis.from_euler(Vector3(-2.5 * c * aw * d, 10.0 * bank * d, 0)))
	_set_piv(h, "Root/Body/Neck1/Neck2/Head", Basis.from_euler(Vector3(-1.5 * c * aw * d, 6.0 * bank * d, 0)))
	_set_piv(h, "Root/Body/Neck1/Neck2/Head/Jaw", Basis.from_euler(Vector3((2.0 + 2.0 * sin(slow * 0.9)) * d, 0, 0)))
	var tails: Array[String] = ["Root/Body/Tail1", "Root/Body/Tail1/Tail2", "Root/Body/Tail1/Tail2/Tail3"]
	var amps: Array[float] = [3.5, 5.0, 7.0]
	var pits: Array[float] = [1.0, 0.0, 1.0]
	for i: int in 3:
		var ph := slow * 1.37 - float(i) * 0.95
		var yaw := amps[i] * sin(ph) + (6.0 + 3.0 * float(i)) * bank
		var pit := pits[i] + 4.0 * sin(TAU * psi - 1.2 - float(i) * 0.8) * aw
		_set_piv(h, tails[i], Basis.from_euler(Vector3(pit * d, yaw * d, 0)))
	var paddle := 5.0 * sin(TAU * psi + 0.5) * aw * d
	_set_piv(h, "Root/Body/LegFL", Basis.from_euler(Vector3(paddle, 0, 0)))
	_set_piv(h, "Root/Body/LegFR", Basis.from_euler(Vector3(paddle, 0, 0)))
	_set_piv(h, "Root/Body/LegBL", Basis.from_euler(Vector3(-paddle, 0, 0)))
	_set_piv(h, "Root/Body/LegBR", Basis.from_euler(Vector3(-paddle, 0, 0)))


func _set_piv(h: Dictionary, path: String, b: Basis) -> void:
	var n: Node3D = h["piv"].get(path)
	if n:
		n.transform = Transform3D(b, h["rest"][path])
