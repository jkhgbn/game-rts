class_name LensSolver
extends RefCounted
## Tool 3 Lens: framing words -> camera (pure math, headless-safe, deterministic). Library entry for other tools:
##   var subs := {"vessa": LensSolver.subject(Vector3(0, 0, 0), 0.0, 1.9)}          # or LensSolver.subject_of(model, tag)
##   var cam := LensSolver.solve_words("mcu on vessa, 3/4 left, low, thirds left", subs, {"res": Vector2i(1600, 900)})
##   if cam["ok"]: cam["a"]["pos"], cam["a"]["look"], cam["a"]["fov"] (Vector3 / float); LensSolver.to_json(cam) = CameraSpec
## Words (comma separated, any order after the first part): see SIZES / ANGLES / HEIGHTS / COMPS and tools/lens/README.md.
## Coverage ("s") = the reference height on screen / the 2.39 band height: head height for ecu / cu / mcu, body height
## for ecu / cu / mcu / ms / cowboy (target from the cut line, see SIZES) and body height for fs / ws / ews.

## size -> {ref: head | body, anchor: top | face | center, headroom: fraction of the band above the head top,
## cut: where the band's bottom edge cuts the body (0 = at the chin, 1 = at the feet, measured down from the head
## bottom), s: fixed coverage target when there is no cut}. With a cut, the coverage target is per subject:
## s = head height / ((head top - cut line) / (1 - headroom)), so stylised (big-head) models frame like realistic ones.
const SIZES := {
	"ecu": {"ref": "head", "s": 1.25, "anchor": "face", "headroom": 0.0, "name": "extreme close-up (eyes / mouth)"},
	"cu": {"ref": "head", "cut": 0.12, "anchor": "top", "headroom": 0.08, "name": "close-up (head + neck)"},
	"mcu": {"ref": "head", "cut": 0.35, "anchor": "top", "headroom": 0.08, "name": "medium close-up (to mid-chest)"},
	"ms": {"ref": "head", "cut": 0.55, "anchor": "top", "headroom": 0.08, "name": "medium shot (waist up)"},
	"cowboy": {"ref": "head", "cut": 0.75, "anchor": "top", "headroom": 0.07, "name": "cowboy (mid-thigh up)"},
	"fs": {"ref": "body", "s": 0.8, "anchor": "center", "headroom": 0.1, "name": "full shot (head to feet)"},
	"ws": {"ref": "body", "s": 0.35, "anchor": "center", "headroom": 0.0, "name": "wide shot (subject + surroundings)"},
	"ews": {"ref": "body", "s": 0.12, "anchor": "center", "headroom": 0.0, "name": "extreme wide shot (landscape)"},
}


## The coverage target of a size for one subject (see SIZES).
static func target_of(size: String, head: AABB, body: AABB) -> float:
	var sz: Dictionary = SIZES[size]
	if not sz.has("cut"):
		return float(sz["s"])
	var cut_y := head.position.y - float(sz["cut"]) * maxf(0.0, head.position.y - body.position.y)
	var frame := (head.end.y - cut_y) / (1.0 - float(sz["headroom"]))
	return head.size.y / maxf(0.01, frame)


## Points whose projected height stands for the silhouette: heads = a slimmed ellipsoid, bodies = slimmed box corners.
static func silhouette_points(b: AABB, is_head: bool) -> PackedVector3Array:
	var c := b.get_center()
	var k := 0.35 if is_head else 0.6
	var s := Vector3(b.size.x * k, b.size.y, b.size.z * k)
	var bb := AABB(c - s * 0.5, s)
	return ellipsoid_points(bb) if is_head else box_points(bb)

## Camera bearing around the subject, degrees from its nose toward ITS left (3/4-left: the camera stands on the subject's
## left, the subject looks toward frame left).
const ANGLES := {"front": 0.0, "3/4-left": 45.0, "3/4-right": -45.0, "profile-left": 90.0, "profile-right": -90.0,
	"back": 180.0, "3/4-back-left": 135.0, "3/4-back-right": -135.0}
## Camera elevation in degrees (+ = above, looking down).
const HEIGHTS := {"eye": 0.0, "low": -14.0, "high": 20.0, "overhead": 70.0, "ground": -28.0}
const COMPS := ["center", "thirds-left", "thirds-right", "auto"]
const LEADS := ["lead-left", "lead-right", "lead-none"]
const KEYS := ["angle", "height", "comp", "lead", "dutch", "fov", "push", "truck", "crane", "arc", "tilt"]
const DEFAULT_FOV := 40.0
const DEFAULT_RES := Vector2i(1600, 900)
const BAND := 2.39


# ---------------------------------------------------------------- subjects

## A subject from its feet position, facing yaw (degrees, facing = (sin, 0, cos)) and height, when no model is at hand
## (cine without models, tests). Head = the top 16 % of the height.
static func subject(pos: Vector3, yaw_deg: float, height: float = 1.9, width: float = 0.8) -> Dictionary:
	var body := AABB(pos - Vector3(width * 0.5, 0, width * 0.5), Vector3(width, height, width))
	var hh := height * 0.16
	var head := AABB(pos + Vector3(-hh * 0.45, height - hh, -hh * 0.45), Vector3(hh * 0.9, hh, hh * 0.9))
	return {"pos": pos, "yaw": yaw_deg, "aabb": body, "head": head}


## A subject measured from a live model (global AABB of visible meshes, minus flat decals; head = the "Head" pivot's
## meshes). Works headless (mesh AABBs need no renderer). `yaw` is read from the node's rotation.
static func subject_of(model: Node3D, yaw_deg: float = NAN) -> Dictionary:
	var box := aabb_of(model)
	var head_node := model.find_child("Head", true, false) as Node3D
	var head := AABB()
	if head_node != null:
		head = aabb_of(head_node)
	if head_node == null or head.size.y < 0.02:
		var hh := box.size.y * 0.16
		var c := box.get_center()
		head = AABB(Vector3(c.x - hh * 0.45, box.end.y - hh, c.z - hh * 0.45), Vector3(hh * 0.9, hh, hh * 0.9))
	var y := yaw_deg
	if is_nan(y):
		y = rad_to_deg(model.global_rotation.y)
	var feet := model.global_position   # the node origin, not the (bobbing) mesh bottom
	# 1 cm grid: idle animations (breathing, sway) must not change the solved camera between runs
	var parts: Array = []
	if head_node != null:
		for pb: AABB in parts_of(head_node):
			parts.append(_snap_box(pb, 0.01))
	var pts := PackedVector3Array()
	if head_node != null:
		pts = vertex_points(head_node, 900)
	return {"pos": feet.snappedf(0.01), "yaw": y, "aabb": _snap_box(box, 0.01), "head": _snap_box(head, 0.01), "head_parts": parts,
		"head_pts": pts, "body_pts": vertex_points(model, 1500)}


## Up to `cap` mesh vertices (global) of the visible MeshInstance3D under `n`: the exact silhouette (a bent hat tip,
## a hood) for the projection. Evenly strided, deterministic.
static var _vcache := {}   # mesh instance id -> sampled local vertices (get_faces is slow on big merged meshes)


static func vertex_points(n: Node, cap: int = 900) -> PackedVector3Array:
	var all := PackedVector3Array()
	for c: Node in n.find_children("*", "MeshInstance3D", true, false):
		var mi := c as MeshInstance3D
		if mi.mesh == null or not mi.is_visible_in_tree():
			continue
		var key := mi.mesh.get_instance_id() * 7919 + cap
		if not _vcache.has(key):
			var faces := mi.mesh.get_faces()
			var loc := PackedVector3Array()
			var step := maxi(1, faces.size() / cap)
			for i: int in range(0, faces.size(), step):
				loc.append(faces[i])
			_vcache[key] = loc
		var xf := mi.global_transform
		for p: Vector3 in (_vcache[key] as PackedVector3Array):
			all.append(xf * p)
	if all.size() > cap * 2:
		var thin := PackedVector3Array()
		var st := all.size() / cap
		for j: int in range(0, all.size(), st):
			thin.append(all[j])
		return thin
	return all


## The AABB of every visible mesh under `n` (a better silhouette than one box: hat cone + face + collar).
static func parts_of(n: Node) -> Array[AABB]:
	var out: Array[AABB] = []
	for c: Node in n.find_children("*", "GeometryInstance3D", true, false):
		var gi := c as GeometryInstance3D
		if gi is GPUParticles3D or gi is CPUParticles3D or not gi.is_visible_in_tree():
			continue
		var b: AABB = gi.global_transform * gi.get_aabb()
		if b.size.length() > 0.001:
			out.append(b)
	return out


## Silhouette points of a subject's body: mesh vertices when measured from a model, else slimmed box corners.
static func body_points(sub: Dictionary) -> PackedVector3Array:
	var vp: PackedVector3Array = sub.get("body_pts", PackedVector3Array())
	return vp if vp.size() >= 24 else silhouette_points(sub["aabb"], false)


## Silhouette points of a subject's head: per-mesh ellipsoids when the parts are known, else the slimmed head box.
static func head_points(sub: Dictionary) -> PackedVector3Array:
	var vp: PackedVector3Array = sub.get("head_pts", PackedVector3Array())
	if vp.size() >= 24:
		return vp
	var parts: Array = sub.get("head_parts", [])
	if parts.is_empty() or parts.size() > 40:
		return silhouette_points(sub["head"], true)
	var out := PackedVector3Array()
	for pb: AABB in parts:
		out.append_array(ellipsoid_points(pb))
	return out


static func _snap_box(b: AABB, g: float) -> AABB:
	return AABB(b.position.snappedf(g), b.size.snappedf(g))


## Global AABB of the visible GeometryInstance3D under `n` (particles and flat decals / rings skipped).
static func aabb_of(n: Node) -> AABB:
	var out := AABB()
	var first := true
	var stack: Array[Node] = [n]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		stack.append_array(cur.get_children())
		if not cur is GeometryInstance3D or cur is GPUParticles3D or cur is CPUParticles3D:
			continue
		var gi := cur as GeometryInstance3D
		if not gi.is_visible_in_tree() or not gi.is_inside_tree():
			continue
		var b: AABB = gi.global_transform * gi.get_aabb()
		if b.size.y < 0.06 * maxf(b.size.x, b.size.z) or b.size.length() < 0.001:
			continue
		if first:
			out = b
			first = false
		else:
			out = out.merge(b)
	if first:
		out = AABB(Vector3(-0.5, 0, -0.5), Vector3(1, 2, 1))
	return out


# ---------------------------------------------------------------- words

## Parses prose framing words. Returns {ok, errors: [{token, message, hint}], size, subjects: [tags], over, angle, pitch,
## comp, lead, dutch, push, truck, crane, arc, fov, words}. Tags are checked against `known` when it is not empty.
static func parse_words(words: String, known: Array = []) -> Dictionary:
	var r := {"ok": true, "errors": [], "size": "ms", "subjects": [], "over": "", "angle": 0.0, "pitch": 0.0,
		"comp": "auto", "lead": "", "dutch": 0.0, "push": 0.0, "truck": 0.0, "crane": 0.0, "arc": 0.0, "fov": 0.0,
		"words": words, "two": false}
	var parts := words.to_lower().replace(";", ",").split(",", false)
	if parts.is_empty():
		_err(r, words, "empty framing", "write e.g. \"mcu on vessa, 3/4 left, low\"")
		return r
	_parse_head(parts[0].strip_edges(), r, known)
	for i: int in range(1, parts.size()):
		_parse_part(parts[i].strip_edges(), r, known)
	return r


static func _parse_head(p: String, r: Dictionary, known: Array) -> void:
	var w := _squash(p).split(" ", false)
	if w.is_empty():
		_err(r, p, "empty framing", "start with a size: " + ", ".join(PackedStringArray(SIZES.keys())))
		return
	var i := 0
	var size := ""
	if SIZES.has(w[0]):
		size = w[0]
		i = 1
	if i < w.size() and (w[i] == "two-shot" or w[i] == "2-shot"):
		r["two"] = true
		i += 1
		if size == "":
			size = "ms"
	elif i < w.size() and w[i] == "ots":
		if size == "":
			size = "mcu"
		# ots <a> over <b>
		var rest := w.slice(i + 1)
		var ov := rest.find("over")
		if ov < 1 or ov >= rest.size() - 1:
			_err(r, p, "ots wants \"ots <a> over <b>\"", "e.g. \"ots vessa over shade\" (camera behind vessa's shoulder)")
			return
		r["over"] = _tag(rest[0], r, known)
		r["subjects"] = [_tag(rest[ov + 1], r, known)]
		r["size"] = size
		return
	elif size == "":
		var n := ToolSpec.nearest(w[0], SIZES.keys() + ["two-shot", "ots"])
		_err(r, w[0], "unknown shot size \"%s\"" % w[0], ("did you mean \"%s\"? " % n if n != "" else "") +
			"sizes: " + " ".join(PackedStringArray(SIZES.keys())) + ", two-shot, ots")
		size = "ms"
	r["size"] = size
	if i < w.size() and w[i] == "on":
		i += 1
	var subs: Array = []
	while i < w.size():
		if w[i] != "and" and w[i] != "&":
			subs.append(_tag(w[i], r, known))
		i += 1
	if subs.is_empty():
		_err(r, p, "no subject", "write \"%s on <tag>\"" % size)
	r["subjects"] = subs
	if subs.size() > 1:
		r["two"] = true


static func _parse_part(p: String, r: Dictionary, known: Array) -> void:
	var q := _squash(p).replace(" ", "-")
	if q == "":
		return
	if ANGLES.has(q):
		r["angle"] = ANGLES[q]
		return
	if HEIGHTS.has(q):
		r["pitch"] = HEIGHTS[q]
		return
	if q in COMPS:
		r["comp"] = q
		return
	if q in LEADS:
		r["lead"] = q.trim_prefix("lead-")
		return
	if q == "dutch":
		r["dutch"] = 10.0
		return
	if q.begins_with("ots-"):
		r["over"] = _tag(q.trim_prefix("ots-"), r, known)
		if r["size"] == "ms":
			r["size"] = "mcu"
		return
	# key value: "dutch 10", "angle=30", "push 0.2", "fov 35"
	var raw := _squash(p)
	var sep := raw.find("=")
	if sep < 0:
		sep = raw.find(" ")
	var kk := raw.substr(0, sep).strip_edges() if sep > 0 else ""
	var vv := raw.substr(sep + 1).strip_edges() if sep > 0 else ""
	if kk in KEYS and _is_num(vv):
		var v := vv.to_float()
		match kk:
			"angle":
				r["angle"] = v
			"height":
				r["pitch"] = v
			"tilt":
				r["pitch"] = v
			_:
				r[kk] = v
		return
	var all: Array = ANGLES.keys() + HEIGHTS.keys() + COMPS + LEADS + ["dutch", "ots <tag>", "angle=<deg>", "push=<0..1>", "fov=<deg>"]
	var n := ToolSpec.nearest(q, all)
	_err(r, p, "unknown framing word \"%s\"" % p, ("did you mean \"%s\"? " % n if n != "" else "") +
		"angles: %s; heights: %s; comps: %s" % [" ".join(PackedStringArray(ANGLES.keys())),
		" ".join(PackedStringArray(HEIGHTS.keys())), " ".join(PackedStringArray(COMPS))])


static func _squash(s: String) -> String:
	var t := s.strip_edges().replace("\t", " ")
	while "  " in t:
		t = t.replace("  ", " ")
	# "3/4 left" -> "3/4-left", "thirds left" -> "thirds-left", "profile right" -> "profile-right"
	for pre: String in ["3/4 back", "3/4", "thirds", "profile", "lead", "two"]:
		t = t.replace(pre + " ", pre + "-")
	return t


static func _is_num(s: String) -> bool:
	return s.is_valid_float() or s.is_valid_int()


static func _tag(t: String, r: Dictionary, known: Array) -> String:
	if not known.is_empty() and not t in known:
		var n := ToolSpec.nearest(t, known)
		_err(r, t, "unknown subject \"%s\"" % t, ("did you mean \"%s\"? " % n if n != "" else "") + "subjects: " +
			", ".join(PackedStringArray(known)))
	return t


static func _err(r: Dictionary, token: String, message: String, hint: String) -> void:
	r["ok"] = false
	(r["errors"] as Array).append({"token": token, "message": message, "hint": hint})


# ---------------------------------------------------------------- solve

## Words + subjects -> CameraSpec dictionary: {ok, errors, pos, look, fov, roll, a: {pos, look, fov}, b: {...},
## words, size, target_s, pred_s, head_ndc: {tag: Vector2}, band_frac, res}. opts: res (Vector2i), band (2.39),
## fov (deg, default 40).
static func solve_words(words: String, subjects: Dictionary, opts: Dictionary = {}) -> Dictionary:
	var w := parse_words(words, subjects.keys())
	if not w["ok"]:
		return {"ok": false, "errors": w["errors"], "words": words}
	return solve(w, subjects, opts)


static func solve(w: Dictionary, subjects: Dictionary, opts: Dictionary = {}) -> Dictionary:
	var res: Vector2i = opts.get("res", DEFAULT_RES)
	var band: float = float(opts.get("band", BAND))
	var fov: float = float(w["fov"]) if float(w.get("fov", 0.0)) > 0.0 else float(opts.get("fov", DEFAULT_FOV))
	var aspect := float(res.x) / float(res.y)
	var bf := band_frac(res, band)
	var size: String = w["size"]
	var sz: Dictionary = SIZES[size]
	var tags: Array = w["subjects"]
	var main: Dictionary = subjects[tags[0]]
	var over: String = w.get("over", "")
	var head: AABB = main["head"]
	var body: AABB = main["aabb"]
	var yaw := deg_to_rad(float(main["yaw"]))
	var target_s: float = target_of(size, head, body)
	# camera bearing: around the main subject, or perpendicular to the pair for a two-shot
	var bearing := yaw + deg_to_rad(float(w["angle"]))
	var heads: Array[Vector3] = []
	for t: String in tags:
		heads.append((subjects[t]["head"] as AABB).get_center())
	if tags.size() > 1:
		var ab: Vector3 = heads[1] - heads[0]
		ab.y = 0.0
		var perp := Vector3(-ab.z, 0, ab.x).normalized()
		var avg := Vector3.ZERO
		for t2: String in tags:
			var yy := deg_to_rad(float(subjects[t2]["yaw"]))
			avg += Vector3(sin(yy), 0, cos(yy))
		if perp.dot(avg) < 0.0:
			perp = -perp
		bearing = atan2(perp.x, perp.z) + deg_to_rad(float(w["angle"]))
	var pitch := deg_to_rad(float(w["pitch"]))
	var dir := Vector3(sin(bearing) * cos(pitch), sin(pitch), cos(bearing) * cos(pitch))
	# horizontal composition (ndc x of the key point); lead room goes where the subject looks
	var comp: String = w["comp"]
	var tx := 0.0
	if comp == "thirds-left":
		tx = -1.0 / 3.0
	elif comp == "thirds-right":
		tx = 1.0 / 3.0
	elif comp == "auto" and tags.size() == 1 and over == "":
		var lead: String = w.get("lead", "")
		if lead == "left":
			tx = 1.0 / 3.0
		elif lead == "right":
			tx = -1.0 / 3.0
		elif lead == "" and absf(float(w["angle"])) > 20.0 and absf(float(w["angle"])) < 160.0 and size != "ecu":
			tx = 1.0 / 3.0 if sin(deg_to_rad(float(w["angle"]))) > 0.0 else -1.0 / 3.0
	# key points
	var key := head.get_center() if tags.size() == 1 else (heads[0] + heads[1]) * 0.5
	var ref_pts: PackedVector3Array = head_points(main) if sz["ref"] == "head" else body_points(main)
	var ratio := 1.0
	if sz["ref"] == "body" and sz["anchor"] == "top":
		ratio = body.size.y / maxf(0.01, head.size.y)   # ms / cowboy: body read through the head size
	var top_y_target := bf * (1.0 - 2.0 * float(sz["headroom"]))
	var ty := 0.0
	var ots := over != ""
	var ots_side := 1.0
	var look := key
	var dist := 4.0
	if ots:
		# behind A's shoulder, looking at B's head; the size is reached with the fov
		var a_head: AABB = subjects[over]["head"]
		# stable anchors only (feet + body height): idle sway of hats / heads must not move a camera 0.5 m from them
		var a_sub: Dictionary = subjects[over]
		var a_h := snappedf((a_sub["aabb"] as AABB).size.y, 0.1)
		var ah := Vector3((a_sub["pos"] as Vector3).x, (a_sub["pos"] as Vector3).y + snappedf(a_head.get_center().y - (a_sub["pos"] as Vector3).y, 0.25), (a_sub["pos"] as Vector3).z)
		var to_b: Vector3 = key - ah
		to_b.y = 0.0
		var fwd := to_b.normalized()
		var right := Vector3(-fwd.z, 0, fwd.x)     # A's right when facing B (facing +Z -> right = -X)
		ots_side = -1.0 if comp == "thirds-left" else 1.0
		var hs := a_h * 0.3
		var cam_pos := ah - fwd * (hs * 2.2 + 0.25) + right * ots_side * (hs * 1.6 + 0.15) + Vector3(0, a_h * 0.12, 0)
		dir = (cam_pos - key).normalized()
		dist = (cam_pos - key).length()
		tx = ots_side / 3.0
	else:
		# first guess: frame height at the subject = ref height / s
		var ref_h := head.size.y if sz["ref"] == "head" else body.size.y
		if sz["ref"] == "body" and sz["anchor"] == "top":
			ref_h = body.size.y
		var frame_h := ref_h / target_s
		dist = frame_h * 0.5 / (tan(deg_to_rad(fov) * 0.5) * bf)
		if sz["anchor"] == "center":
			key = body.get_center() if tags.size() == 1 else Vector3(key.x, (body.position.y + body.end.y) * 0.5, key.z)
		look = key
	# iterate: distance (or fov for ots) from the coverage, look point from the anchors
	var cam := Transform3D()
	var cur_fov := fov
	var pred_s := 0.0
	for it: int in 24:
		var pos := look + dir * dist
		if ots:
			pos = key + dir * dist
		cam = look_xform(pos, look, float(w["dutch"]))
		var ext := extent_ndc(cam, cur_fov, aspect, ref_pts)
		pred_s = ext.y / (2.0 * bf) * ratio
		var k := pred_s / target_s
		if tags.size() > 1 and not ots:
			# a two-shot must also fit both heads across the frame (inside the thirds band +- 0.45)
			var ha := project(cam, cur_fov, aspect, heads[0])
			var hb := project(cam, cur_fov, aspect, heads[1])
			k = maxf(k, absf(ha.x - hb.x) / 0.9)
		if ots:
			var tn := tan(deg_to_rad(cur_fov) * 0.5) * k
			cur_fov = clampf(rad_to_deg(atan(tn)) * 2.0, 8.0, 100.0)
		else:
			dist = clampf(dist * k, 0.3, 4000.0)
		# vertical anchor
		var up := cam.basis.y
		var right := cam.basis.x
		var half_h := tan(deg_to_rad(cur_fov) * 0.5) * (cam.origin - look).length()
		var half_w := half_h * aspect
		var p_anchor := Vector2.ZERO
		match String(sz["anchor"]):
			"top":
				var top_ndc := extent_ndc(cam, cur_fov, aspect, head_points(main))
				p_anchor = Vector2(0, top_ndc.z - top_y_target)   # z = max y
			"face":
				p_anchor = Vector2(0, project(cam, cur_fov, aspect, head.get_center()).y - bf * 0.12)
			"center":
				var e := extent_ndc(cam, cur_fov, aspect, body_points(main))
				p_anchor = Vector2(0, (e.z + e.w) * 0.5 - ty)
		var kx := project(cam, cur_fov, aspect, key).x - tx
		if tags.size() == 1 and not ots:
			kx = mid_x_ndc(cam, cur_fov, aspect, head_points(main)) - tx   # the head silhouette, not its box centre
		look += right * kx * half_w + up * p_anchor.y * half_h
	var a := {"pos": cam.origin, "look": look, "fov": cur_fov}
	var bpos := _move_b(a, w, dist, dir)
	var head_ndc := {}
	for t3: String in subjects:
		head_ndc[t3] = project(cam, cur_fov, aspect, (subjects[t3]["head"] as AABB).get_center())
	return {"ok": true, "errors": [], "words": w["words"], "size": size, "subjects": tags, "over": over,
		"pos": a["pos"], "look": a["look"], "fov": a["fov"], "roll": float(w["dutch"]), "a": a, "b": bpos,
		"target_s": target_s, "pred_s": pred_s, "ratio": ratio, "ref": sz["ref"], "head_ndc": head_ndc, "band_frac": bf,
		"res": res, "band": band, "xform": cam}


## The end camera `b` from push (0-1: fraction of the distance moved toward the subject), truck (m, camera right),
## crane (m, up) and arc (deg around the look point).
static func _move_b(a: Dictionary, w: Dictionary, dist: float, dir: Vector3) -> Dictionary:
	var pos: Vector3 = a["pos"]
	var look: Vector3 = a["look"]
	var off := pos - look
	if float(w["arc"]) != 0.0:
		off = off.rotated(Vector3.UP, deg_to_rad(float(w["arc"])))
	off *= 1.0 - clampf(float(w["push"]), -3.0, 0.95)
	var right := Vector3.UP.cross(off).normalized()     # camera right = forward x up = up x off
	var p2 := look + off + right * float(w["truck"]) + Vector3(0, float(w["crane"]), 0)
	var l2 := look + right * float(w["truck"])
	return {"pos": p2, "look": l2, "fov": a["fov"]}


## Camera transform at `pos` looking at `look` with roll `roll_deg` (world up; safe near vertical).
static func look_xform(pos: Vector3, look: Vector3, roll_deg: float = 0.0) -> Transform3D:
	var d := look - pos
	var up := Vector3.UP
	if absf(d.normalized().dot(up)) > 0.995:
		up = Vector3(0, 0, -1)
	var t := Transform3D(Basis(), pos).looking_at(look, up)
	if roll_deg != 0.0:
		t.basis = t.basis * Basis(Vector3(0, 0, 1), deg_to_rad(roll_deg))
	return t


## Point -> ndc (x right, y up, -1..1 on the full frame; Camera3D keep-height vertical fov). z < 0 behind -> huge.
static func project(cam: Transform3D, fov_deg: float, aspect: float, p: Vector3) -> Vector2:
	var c := cam.affine_inverse() * p
	var z := -c.z
	if z < 0.001:
		return Vector2(99, 99)
	var t := tan(deg_to_rad(fov_deg) * 0.5)
	return Vector2(c.x / z / (t * aspect), c.y / z / t)


## Projected extent of points: Vector4(width_ndc, height_ndc, max_y, min_y).
static func extent_ndc(cam: Transform3D, fov_deg: float, aspect: float, pts: PackedVector3Array) -> Vector4:
	var mn := Vector2(INF, INF)
	var mx := Vector2(-INF, -INF)
	for p: Vector3 in pts:
		var n := project(cam, fov_deg, aspect, p)
		mn = mn.min(n)
		mx = mx.max(n)
	return Vector4(mx.x - mn.x, mx.y - mn.y, mx.y, mn.y)


## Middle of the projected x range of points (ndc).
static func mid_x_ndc(cam: Transform3D, fov_deg: float, aspect: float, pts: PackedVector3Array) -> float:
	var mn := INF
	var mx := -INF
	for p: Vector3 in pts:
		var x := project(cam, fov_deg, aspect, p).x
		mn = minf(mn, x)
		mx = maxf(mx, x)
	return (mn + mx) * 0.5


## Points on the ellipsoid inscribed in a box (a rounded silhouette: heads, bodies).
static func ellipsoid_points(b: AABB) -> PackedVector3Array:
	var out := PackedVector3Array()
	var c := b.get_center()
	var r := b.size * 0.5
	for i: int in 9:
		var ph := -PI * 0.5 + PI * float(i) / 8.0
		for j: int in 16:
			var th := TAU * float(j) / 16.0
			out.append(c + Vector3(r.x * cos(ph) * cos(th), r.y * sin(ph), r.z * cos(ph) * sin(th)))
	return out


## Box corners (buildings, props).
static func box_points(b: AABB) -> PackedVector3Array:
	var out := PackedVector3Array()
	for i: int in 8:
		out.append(b.get_endpoint(i))
	return out


## Fraction of the frame height inside the letterbox band (1600x900 at 2.39 -> 0.744; 2.39 screens -> 1).
static func band_frac(res: Vector2i, band: float = BAND) -> float:
	if band <= 0.0:
		return 1.0
	return minf(1.0, float(res.x) / band / float(res.y))


# ---------------------------------------------------------------- icons

## One framing rule for icons / turnarounds: camera at `yaw_deg` around the subject's facing (0 = front, + = toward its
## left) and `pitch_deg` above, perspective `fov`, subject silhouette filling `fill` of the square tile, centred.
static func solve_fit(box: AABB, facing_yaw_deg: float, yaw_deg: float, pitch_deg: float, fill: float,
		fov: float = 30.0, pts: PackedVector3Array = PackedVector3Array()) -> Dictionary:
	var b := deg_to_rad(facing_yaw_deg + yaw_deg)
	var p := deg_to_rad(pitch_deg)
	var dir := Vector3(sin(b) * cos(p), sin(p), cos(b) * cos(p))
	var shape := pts if not pts.is_empty() else ellipsoid_points(box)
	var look := box.get_center()
	var dist := box.size.length() * 0.5 / tan(deg_to_rad(fov) * 0.5) / fill
	var cam := Transform3D()
	for it: int in 16:
		cam = look_xform(look + dir * dist, look)
		var mn := Vector2(INF, INF)
		var mx := Vector2(-INF, -INF)
		for q: Vector3 in shape:
			var n := project(cam, fov, 1.0, q)
			mn = mn.min(n)
			mx = mx.max(n)
		var ext := maxf(mx.x - mn.x, mx.y - mn.y) * 0.5
		dist *= ext / fill
		var half := tan(deg_to_rad(fov) * 0.5) * (cam.origin - look).length()
		var ctr := (mn + mx) * 0.5
		look += cam.basis.x * ctr.x * half + cam.basis.y * ctr.y * half
	return {"pos": cam.origin, "look": look, "fov": fov, "xform": cam, "dist": dist}


# ---------------------------------------------------------------- CameraSpec JSON (contract 13.2: tool 3 -> tool 2)

static func v3(v: Vector3) -> Array:
	return [snappedf(v.x, 0.0001), snappedf(v.y, 0.0001), snappedf(v.z, 0.0001)]


## CameraSpec `{pos, look, fov, a: {pos, look, fov}, b: {...}}` (+ roll, words, size, metrics) as a JSON-ready dictionary.
static func to_json(cam: Dictionary, shot_id: String = "") -> Dictionary:
	var a: Dictionary = cam["a"]
	var b: Dictionary = cam["b"]
	var hn := {}
	var rs: Vector2i = cam.get("res", DEFAULT_RES)
	for t: String in cam.get("head_ndc", {}):
		var n: Vector2 = cam["head_ndc"][t]
		hn[t] = [snappedf(n.x, 0.0001), snappedf(n.y, 0.0001)]
	return {"shot": shot_id, "words": cam.get("words", ""), "size": cam.get("size", ""),
		"pos": v3(a["pos"]), "look": v3(a["look"]), "fov": snappedf(float(a["fov"]), 0.001), "roll": float(cam.get("roll", 0.0)),
		"a": {"pos": v3(a["pos"]), "look": v3(a["look"]), "fov": snappedf(float(a["fov"]), 0.001)},
		"b": {"pos": v3(b["pos"]), "look": v3(b["look"]), "fov": snappedf(float(b["fov"]), 0.001)},
		"res": [rs.x, rs.y], "band": float(cam.get("band", BAND)),
		"target_s": snappedf(float(cam.get("target_s", 0.0)), 0.0001), "pred_s": snappedf(float(cam.get("pred_s", 0.0)), 0.0001),
		"head_ndc": hn}


## Reads a camera.json back: {pos, look, fov, a, b} with Vector3 values (null when unreadable).
static func from_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not d is Dictionary:
		return null
	var v := func(x: Variant) -> Vector3: return Vector3(float(x[0]), float(x[1]), float(x[2])) if x is Array and (x as Array).size() >= 3 else Vector3.ZERO
	var a: Dictionary = (d as Dictionary).get("a", d)
	var b: Dictionary = (d as Dictionary).get("b", a)
	return {"pos": v.call(d.get("pos", a.get("pos"))), "look": v.call(d.get("look", a.get("look"))), "fov": float(d.get("fov", a.get("fov", 40.0))),
		"a": {"pos": v.call(a.get("pos")), "look": v.call(a.get("look")), "fov": float(a.get("fov", 40.0))},
		"b": {"pos": v.call(b.get("pos")), "look": v.call(b.get("look")), "fov": float(b.get("fov", 40.0))}}
