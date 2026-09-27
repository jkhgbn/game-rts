extends RefCounted
## World Forge, set checks: set contract, budgets (draws / lights / triangles), marks (subject inside the 2.39 band at
## the start / middle / end of each move, camera not inside geometry, line of sight), scatter counts, determinism.
## Also paints plan.png (top-down, headless): ground, paths, walls, footprints, scatter, actors, cameras + frusta.
## No class_name on purpose (preloaded tool script).

const FSet := preload("res://tools/world_forge/forge_set.gd")
const Kits := preload("res://tools/world_forge/forge_kits.gd")


## Measures the instantiated saved set `inst` (in the tree for a few frames).
static func run(fs: FSet, inst: Node3D) -> void:
	var rep := fs.report
	var plan := fs.plan
	# ---- K1 contract
	var miss: Array[String] = []
	if not inst.is_in_group(&"cinematic_sets"):
		miss.append("group cinematic_sets")
	if StringName(inst.get(&"set_id")) != StringName(plan["id"]):
		miss.append("set_id")
	if not inst.get(&"lighting") is LightingPreset:
		miss.append("lighting")
	for m: String in ["begin_shot", "end_shot", "set_active", "puppet"]:
		if not inst.has_method(m):
			miss.append(m + "()")
	var shots := inst.get_node_or_null(^"Shots")
	if shots == null:
		miss.append("Shots node")
	var mj_path := fs.set_dir() + "/marks.json"
	var marks_json: Variant = JSON.parse_string(FileAccess.get_file_as_string(mj_path)) if FileAccess.file_exists(mj_path) else null
	for m: Dictionary in plan["marks"]:
		for suf: String in ["from", "to", "look_from", "look_to"]:
			var mk := shots.get_node_or_null(NodePath("%s_%s" % [m["shot"], suf])) as Marker3D if shots else null
			if mk == null:
				miss.append("marker %s_%s" % [m["shot"], suf])
			elif marks_json is Dictionary and (marks_json as Dictionary).has(m["shot"]):
				var a: Array = marks_json[m["shot"]][suf]
				if mk.global_position.distance_to(Vector3(a[0], a[1], a[2])) > 0.01:
					miss.append("marks.json %s.%s differs from the marker" % [m["shot"], suf])
	for a: Dictionary in plan["actors"]:
		if inst.call(&"puppet", StringName(a["tag"])) == null:
			miss.append("puppet(%s)" % a["tag"])
	if not plan["marks"].is_empty() and inst.has_method(&"begin_shot"):
		inst.call(&"begin_shot", StringName(plan["marks"][0]["shot"]))
		inst.call(&"end_shot", StringName(plan["marks"][0]["shot"]))
		inst.call(&"set_active", false)
		inst.call(&"set_active", true)
	rep.fcheck("K1", "Set contract (prologue 2.3)", "FAIL" if not miss.is_empty() else "PASS",
		"all present" if miss.is_empty() else ", ".join(miss), "group, set_id, lighting, Shots markers = marks.json, begin_shot / end_shot / set_active / puppet(tag)",
		"rebuild the set; never hand-edit the generated scene", 2.0)
	# ---- budgets
	var draws := 0
	var tris := 0
	var lights := 0
	var mm := 0
	var light_names: Array[String] = []
	var lights_off := 0
	# flocks: their runtime flyers are not in the saved scene; count DragonFlock.budget() draws after one pose at t = 0
	var flocks: Array[Node] = []
	var flock_draws := 0
	for fl: Dictionary in plan.get("flocks", []):
		var fn := inst.get_node_or_null(NodePath("Placed/%s" % fl["tag"]))
		if fn and fn.has_method(&"budget"):
			flocks.append(fn)
			if fn.has_method(&"set_cine_time"):
				fn.call(&"set_cine_time", 0.0)
			flock_draws += int((fn.call(&"budget") as Dictionary).get("draws", 0))
	draws += flock_draws
	var n_flocks := flocks.size()
	# engine=proton scatters: their output is built at load (threaded); count 1 multimesh draw each, skip their children
	for c: Node in inst.get_children():
		if String(c.name).begins_with("Proton_"):
			flocks.append(c)
			draws += 1
			mm += 1
	for n: Node in inst.find_children("*", "", true, false):
		if not flocks.is_empty() and flocks.any(func(f: Node) -> bool: return f == n or f.is_ancestor_of(n)):
			continue
		if n is MeshInstance3D and (n as MeshInstance3D).is_visible_in_tree() and (n as MeshInstance3D).mesh:
			var mesh: Mesh = (n as MeshInstance3D).mesh
			draws += mesh.get_surface_count()
			for s in mesh.get_surface_count():
				var arr := mesh.surface_get_arrays(s)
				var idx: Variant = arr[Mesh.ARRAY_INDEX]
				tris += ((idx as PackedInt32Array).size() if idx is PackedInt32Array and not (idx as PackedInt32Array).is_empty() else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
		elif (n is MultiMeshInstance3D or n is GPUParticles3D or n is CPUParticles3D) and (n as Node3D).is_visible_in_tree():
			draws += 1
			mm += 1
		elif n is Light3D and not (n as Light3D).visible:
			lights_off += 1
		elif n is Light3D and (n as Light3D).is_visible_in_tree():
			lights += 1
			light_names.append(String(inst.get_path_to(n)))
	var bd: float = plan["budget"]["draws"]
	var bl: float = plan["budget"]["lights"]
	var bt: float = plan["budget"]["tris"]
	rep.fcheck("B1", "Draw calls", "PASS" if draws <= bd else ("WARN" if draws <= bd * 1.15 else "FAIL"), "%d surfaces (%d particles / multimesh)%s" % [draws, mm, (", %d in %d flock(s) at t 0" % [flock_draws, n_flocks]) if n_flocks > 0 else ""],
		"<= %d (budget line)" % bd, "scatter bakes to one surface per material; drop a placed model or use a mesh-only kit", 2.0)
	rep.fcheck("B2", "Lights", "PASS" if lights <= bl else "FAIL", "%d visible Light3D%s; %d switched off by lights=off" % [lights, (" " + ", ".join(light_names)) if lights > 0 else "", lights_off], "<= %d (0 = the stage's LightingRig only)" % bl,
		"add lights=off to the place / actor line of the model that brings them (the path is in the measured value)", 2.0)
	rep.fcheck("B3", "Triangles", "PASS" if tris <= bt else "WARN", "%d" % tris, "<= %d" % bt, "lower scatter count or use smaller kits")
	# ---- scatter counts
	var short: Array[String] = []
	var tot := 0
	for s: Dictionary in plan["scatters"]:
		tot += int(s.get("placed", 0))
		if int(s.get("placed", 0)) < int(s["count"]):
			short.append("line %d %s: %d / %d" % [s["line"], s["kit"]["name"], s.get("placed", 0), s["count"]])
	rep.fcheck("S3", "Scatter counts", "WARN" if not short.is_empty() else "PASS", "%d instances%s" % [tot, "" if short.is_empty() else "; short: " + ", ".join(short)],
		"every scatter line places its count", "widen the area, lower gap= or count= (the area is full)")
	# ---- terrain
	if fs.terrain.on:
		var steep: Array[String] = []
		var n := 0
		for p: Dictionary in plan["places"]:
			if bool(p.get("row", false)) or bool(p.get("y_set", false)):
				continue
			n += 1
			var sl := fs.terrain.slope_deg(p["at"].x, p["at"].z)
			if sl > 12.0:
				steep.append("line %d %s %.0f deg" % [p["line"], p["kit"]["name"], sl])
		for a: Dictionary in plan["actors"]:
			if bool(a.get("y_set", false)):
				continue
			n += 1
			var sl := fs.terrain.slope_deg(a["at"].x, a["at"].z)
			if sl > 12.0:
				steep.append("line %d actor %s %.0f deg" % [a["line"], a["tag"], sl])
		var hmm := fs.terrain.min_max()
		rep.fcheck("T1", "Placements on flat enough ground", "WARN" if not steep.is_empty() else "PASS",
			("%d / %d on slopes: %s" % [steep.size(), n, ", ".join(steep)]) if not steep.is_empty() else "%d placements; terrain %dx%d cells of %.2f m, y %.1f..%.1f" % [n, fs.terrain.nx - 1, fs.terrain.nz - 1, fs.terrain.step, hmm.x, hmm.y],
			"slope under every place / actor <= 12 deg", "add pad=<radius> to the place / actor line (or a `pad` statement)")
	# ---- marks
	_check_marks(fs, rep, inst)


static func _check_marks(fs: FSet, rep, inst: Node3D) -> void:
	var plan := fs.plan
	if plan["marks"].is_empty():
		rep.fcheck("M1", "Marks", "WARN", "no marks", "a set has >= 1 mark per shot", "add `mark <shot> from=(x,y,z) look=(x,y,z) subject=<tag>`")
		return
	var band_bad: Array[String] = []
	var band_warn: Array[String] = []
	var inside: Array[String] = []
	var blocked: Array[String] = []
	var near: Array[String] = []
	var rows: Array[String] = []
	for m: Dictionary in plan["marks"]:
		var subj := _subject_point(fs, inst, m)
		for ph: Array in [["a", 0.0], ["b", 0.5], ["c", 1.0]]:
			var t: float = ph[1]
			var cam: Vector3 = (m["from"] as Vector3).lerp(m["to"], t)
			var look: Vector3 = (m["look_from"] as Vector3).lerp(m["look_to"], t)
			var fov: float = lerpf(m["fov_from"], m["fov_to"], t)
			var ndc := project(cam, look, fov, subj)
			var tag := "%s_%s" % [m["shot"], ph[0]]
			rows.append("%s ndc (%.2f, %.2f)" % [tag, ndc.x, ndc.y])
			if ndc.z <= 0.0 or absf(ndc.y) > FSet.BAND or absf(ndc.x) > 0.95:
				band_bad.append("%s (%.2f, %.2f)%s" % [tag, ndc.x, ndc.y, " behind" if ndc.z <= 0 else ""])
			elif absf(ndc.y) > FSet.BAND_SAFE or absf(ndc.x) > 0.8:
				band_warn.append("%s (%.2f, %.2f)" % [tag, ndc.x, ndc.y])
			for o: Dictionary in fs.obstacles:
				if m["subject"] != "" and o.get("tag", "") != m["subject"] and not _point_in(o, cam, 0.9) and _seg_hits(o, cam, subj):
					blocked.append("%s: %s blocks the view of %s" % [tag, o["name"], m["subject"]])
			if fs.terrain.on:
				for s in range(1, 24):
					var q := cam.lerp(subj, s / 24.0 * 0.95)
					if q.y < fs.terrain.height_at(q.x, q.z) - 0.2:
						blocked.append("%s: the terrain (a hill) hides %s at (%.0f, %.0f)" % [tag, m["subject"] if m["subject"] != "" else "the look point", q.x, q.z])
						break
		# the camera path, sampled every 1/8 of the move
		for k in 9:
			var t := k / 8.0
			var cam: Vector3 = (m["from"] as Vector3).lerp(m["to"], t)
			var tag := "%s@%.2f" % [m["shot"], t]
			var gy := fs.terrain.height_at(cam.x, cam.z)
			if cam.y < gy + 0.3:
				inside.append("%s under the ground (y %.2f, ground %.2f)" % [tag, cam.y, gy])
			for o: Dictionary in fs.obstacles:
				if _point_in(o, cam, 0.15):
					inside.append("%s inside %s" % [tag, o["name"]])
				elif _point_in(o, cam, 0.9):
					near.append("%s within 0.9 m of %s (fills the frame)" % [tag, o["name"]])
	rep.fcheck("M1", "Subject inside the 2.39 band", "FAIL" if not band_bad.is_empty() else ("WARN" if not band_warn.is_empty() else "PASS"),
		("; ".join(band_bad + band_warn)) if not (band_bad.is_empty() and band_warn.is_empty()) else "%d mark phases inside |y| <= %.2f" % [rows.size(), FSet.BAND_SAFE],
		"subject point (actor head / place centre / look point) projects inside the central 2.39:1 band (|ndc y| <= %.3f, PASS <= %.2f) at a / b / c" % [FSet.BAND, FSet.BAND_SAFE],
		"aim look= closer to the subject, or raise from= y", 2.0)
	rep.fcheck("M2", "Cameras clear of geometry", "FAIL" if not inside.is_empty() else ("WARN" if not near.is_empty() else "PASS"), "ok" if inside.is_empty() and near.is_empty() else "; ".join(_dedupe(inside + near)),
		"every mark phase's camera is above the ground, outside walls / placed models (FAIL) and >= 0.9 m from them (WARN)", "move from= / to= out of the model (see plan.png)", 2.0)
	rep.fcheck("M3", "Line of sight to the subject", "WARN" if not blocked.is_empty() else "PASS", "ok" if blocked.is_empty() else "; ".join(_dedupe(blocked)),
		"nothing placed between the camera and the subject (bounding boxes)", "raise the camera or move it round the blocker")
	rep.notes.append("Mark projections: " + ", ".join(rows))


static func _dedupe(a: Array[String]) -> Array[String]:
	var out: Array[String] = []
	for s in a:
		if not out.has(s):
			out.append(s)
	return out


## Subject: actor head (y + 1.6 * scale), a tagged place's box centre, else the look point.
static func _subject_point(fs: FSet, inst: Node3D, m: Dictionary) -> Vector3:
	if m["subject"] != "":
		for a: Dictionary in fs.plan["actors"]:
			if a["tag"] == m["subject"]:
				return (a["at"] as Vector3) + Vector3(0, 1.6 * float(a["scale"]), 0)
		for o: Dictionary in fs.obstacles:
			if o.get("tag", "") == m["subject"] and o.has("aabb"):
				return (o["aabb"] as AABB).get_center()
	return (m["look_from"] as Vector3).lerp(m["look_to"], 0.5)


## (ndc x, ndc y, depth) of `p` for a 16:9 camera at `cam` looking at `look` with vertical fov (deg).
static func project(cam: Vector3, look: Vector3, fov: float, p: Vector3) -> Vector3:
	var dir := (look - cam)
	if dir.length() < 0.001:
		return Vector3(0, 0, -1)
	var up := Vector3.UP if absf(dir.normalized().y) < 0.99 else Vector3.BACK
	var b := Basis.looking_at(dir, up)
	var q := b.inverse() * (p - cam)
	var depth := -q.z
	if depth <= 0.001:
		return Vector3(0, 0, -1)
	var th := tan(deg_to_rad(fov) * 0.5)
	return Vector3(q.x / (depth * th * FSet.ASPECT), q.y / (depth * th), depth)


static func _point_in(o: Dictionary, p: Vector3, margin: float) -> bool:
	if o.has("aabb"):
		return (o["aabb"] as AABB).grow(margin).has_point(p)
	var lp: Vector3 = (o["xf"] as Transform3D).affine_inverse() * p - (o["center"] as Vector3)
	var h: Vector3 = o["half"]
	return absf(lp.x) < h.x + margin and absf(lp.y) < h.y + margin and absf(lp.z) < h.z + margin


static func _seg_hits(o: Dictionary, a: Vector3, b: Vector3) -> bool:
	var ab: AABB
	var pa := a
	var pb := b
	if o.has("aabb"):
		ab = o["aabb"]
	else:
		var inv := (o["xf"] as Transform3D).affine_inverse()
		pa = inv * a - (o["center"] as Vector3)
		pb = inv * b - (o["center"] as Vector3)
		ab = AABB(-(o["half"] as Vector3), (o["half"] as Vector3) * 2.0)
	# shrink the far end a little so the subject standing against a wall does not count
	pb = pa.lerp(pb, 0.92)
	return ab.intersects_segment(pa, pb) != null


# ---------------------------------------------------------------- plan.png

static func plan_image(fs: FSet) -> Image:
	var plan := fs.plan
	var sz: Vector2 = plan["size"]
	var ppm := clampf(1400.0 / maxf(sz.x, sz.y), 4.0, 24.0)
	var w := int(sz.x * ppm)
	var h := int(sz.y * ppm)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill((plan["ground"] as Color).lerp(Color(0.5, 0.5, 0.5), 0.3))
	var to_px := func(p: Vector3) -> Vector2:
		return Vector2((p.x + sz.x * 0.5) * ppm, (p.z + sz.y * 0.5) * ppm)
	if fs.terrain.on:
		# hill shading + 2 m contours, water in blue (0.5 m cells)
		var base: Color = (plan["ground"] as Color).lerp(Color(0.5, 0.5, 0.5), 0.3)
		var cell := 0.5
		var cx := 0.0
		while cx < sz.x:
			var cz := 0.0
			while cz < sz.y:
				var wx := cx - sz.x * 0.5 + cell * 0.5
				var wz := cz - sz.y * 0.5 + cell * 0.5
				var col := fs.terrain.shade(base, wx, wz)
				if not plan["waters"].is_empty() and fs.under_water(Vector3(wx, 0, wz)):
					col = col.lerp(Color(0.18, 0.38, 0.55), 0.7)
				img.fill_rect(Rect2i(int(cx * ppm), int(cz * ppm), int(ceil(cell * ppm)) + 1, int(ceil(cell * ppm)) + 1), col)
				cz += cell
			cx += cell
	# 5 m grid
	var gx := 0.0
	while gx <= sz.x:
		_line(img, Vector2(gx * ppm, 0), Vector2(gx * ppm, h), Color(1, 1, 1, 0.12), 1)
		gx += 5.0
	var gz := 0.0
	while gz <= sz.y:
		_line(img, Vector2(0, gz * ppm), Vector2(w, gz * ppm), Color(1, 1, 1, 0.12), 1)
		gz += 5.0
	for p: Dictionary in plan["paths"]:
		var poly: PackedVector3Array = p["poly"]
		for i in range(poly.size() - 1):
			_line(img, to_px.call(poly[i]), to_px.call(poly[i + 1]), Kits.PATH_KITS[p["kit"]], int(float(p["width"]) * ppm))
	for o: Dictionary in fs.obstacles:
		if o.has("aabb"):
			var ab: AABB = o["aabb"]
			var a: Vector2 = to_px.call(ab.position)
			var b: Vector2 = to_px.call(ab.end)
			_rect(img, a, b, Color(0.85, 0.45, 0.2, 0.55) if o.get("tag", "") != "" or not String(o["name"]).begins_with("brazier") else Color(1, 0.6, 0.1, 0.9))
		else:
			var xf: Transform3D = o["xf"]
			var c: Vector3 = xf * (o["center"] as Vector3)
			var hh: Vector3 = o["half"]
			var d := xf.basis * Vector3(hh.x, 0, 0)
			_line(img, to_px.call(c - d), to_px.call(c + d), Color(0.15, 0.13, 0.13), maxi(2, int(hh.z * 2.0 * ppm)))
	for s: Dictionary in fs.scatter_pts:
		_disc(img, to_px.call(s["pos"]), maxf(2.0, float(s["r"]) * ppm), Color(0.2, 0.55, 0.25, 0.8))
	for a: Dictionary in plan["actors"]:
		_disc(img, to_px.call(a["at"]), 5, Color(1, 1, 1))
	var palette := [Color(1, 0.9, 0.2), Color(0.3, 0.9, 1), Color(1, 0.4, 0.8), Color(0.6, 1, 0.4), Color(1, 0.6, 0.2), Color(0.7, 0.6, 1)]
	var k := 0
	for m: Dictionary in plan["marks"]:
		var col: Color = palette[k % palette.size()]
		k += 1
		var f: Vector2 = to_px.call(m["from"])
		var t: Vector2 = to_px.call(m["to"])
		_line(img, f, t, col, 2)
		for ph: Array in [[m["from"], m["look_from"], m["fov_from"]], [m["to"], m["look_to"], m["fov_to"]]]:
			var cam: Vector3 = ph[0]
			var look: Vector3 = ph[1]
			var d2 := Vector2(look.x - cam.x, look.z - cam.z).normalized()
			var half_h := atan(tan(deg_to_rad(float(ph[2])) * 0.5) * FSet.ASPECT)
			var c2: Vector2 = to_px.call(cam)
			for sgn in [-1.0, 1.0]:
				var r := d2.rotated(half_h * sgn)
				_line(img, c2, c2 + r * 14.0 * ppm, Color(col, 0.7), 1)
			_disc(img, c2, 4, col)
			var lp: Vector2 = to_px.call(look)
			_line(img, lp - Vector2(5, 5), lp + Vector2(5, 5), Color(1, 0.2, 0.2), 2)
			_line(img, lp - Vector2(5, -5), lp + Vector2(5, -5), Color(1, 0.2, 0.2), 2)
		# shot index ticks next to the camera (1 tick = mark #1 ...), text needs a font
		for tick in k:
			_rect(img, f + Vector2(6 + tick * 4, -10), f + Vector2(8 + tick * 4, -4), col)
	return img


static func _blend(img: Image, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	if c.a >= 0.999:
		img.set_pixel(x, y, c)
	else:
		img.set_pixel(x, y, img.get_pixel(x, y).lerp(Color(c, 1.0), c.a))


static func _line(img: Image, a: Vector2, b: Vector2, c: Color, width: int) -> void:
	var n := int(maxf(absf(b.x - a.x), absf(b.y - a.y))) + 1
	var r := maxi(0, width / 2)
	var done := {}
	for i in n + 1:
		var p := a.lerp(b, float(i) / n)
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var key := Vector2i(int(p.x) + dx, int(p.y) + dy)
				if done.has(key):
					continue
				done[key] = true
				_blend(img, key.x, key.y, c)


static func _rect(img: Image, a: Vector2, b: Vector2, c: Color) -> void:
	for x in range(int(minf(a.x, b.x)), int(maxf(a.x, b.x)) + 1):
		for y in range(int(minf(a.y, b.y)), int(maxf(a.y, b.y)) + 1):
			_blend(img, x, y, c)


static func _disc(img: Image, c: Vector2, r: float, col: Color) -> void:
	for x in range(int(c.x - r), int(c.x + r) + 1):
		for y in range(int(c.y - r), int(c.y + r) + 1):
			if Vector2(x, y).distance_to(c) <= r:
				_blend(img, x, y, col)
