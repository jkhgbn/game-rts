class_name ArtLabCheckCraft
extends RefCounted
## Art Lab v3.1 (docs/plan/art-lab.md section 3, "C" rows): shape craft / detail. The effort trial showed a plain, blocky
## model (969 vertices, straight low-sided prisms, one shape per body part) scoring the same as three far richer ones:
## every other check asks "does it read?", none asks "is it crafted?". These checks measure the craft that shows at the
## close-up and 25 m shots:
##   C1 shape richness  (geometry, headless too): separate shapes (mesh islands) per body part, share of the surface on
##      plain low-sided prisms / boxes (<= 10 face directions), face-normal variety (area-weighted entropy)
##   C2 vertex use       (geometry): vertices used vs the tier budget; under-use counts (a unit at 40 % of its budget left
##      detail on the table), over budget is B4's job (capped at 1)
##   C3 palette depth    (render, close-up): distinct colour / value steps on the body (L*a*b* clusters >= 1.5 %)
##   C4 detail at 25 m   (render, 25 m): inner edge density on the body and the silhouette's detail vs its box hull
## Numbers (bad / good ends, weights) live in ArtLabBudgets.CRAFT; calibrated on the 4 effort-trial Vinelashers and the
## 6 good calibration assets (art-lab.md "Calibration").

## Face normals quantised to this many steps per axis for "distinct directions" (1 / 6 ~ 10 deg).
const DIR_STEPS := 6.0


## Kinds whose craft is graded (the character kit: units, mounts, titans, beasts). Critters, buildings and landmarks
## get the values as unscored INFO (not calibrated yet: an imported single-mesh deer or a brick aqueduct is judged by
## other rules); decor sets / VFX have no C checks.
const GRADED_KINDS: Array[StringName] = [&"unit", &"mount", &"titan", &"beast"]


## Headless part (geometry): C1 shape richness + C2 vertex use. Stores the measures in ctx.m["craft_geo"].
static func check_geometry(ctx: ArtLabRunner) -> void:
	if ctx.kind in [&"decor_set", &"vfx"] or ctx.target == null:
		return
	var cf: Dictionary = ArtLabBudgets.CRAFT
	var g := measure_geometry(ctx.target, ctx.holder.global_transform, ctx.ground_y)
	ctx.m["craft_geo"] = g
	var graded := ctx.kind in GRADED_KINDS
	# C1: separate shapes per body part (islands / pivots), plain box / prism share, face-normal variety
	var piv: Dictionary = g["pivots"]
	var n_piv := maxi(piv.size(), 1)
	var per_part := float(g["islands"]) / float(n_piv)
	var g_isl := ArtLabScore.grade(per_part, float(cf["per_part_bad"]), float(cf["per_part_good"]))
	var g_plain := ArtLabScore.grade(float(g["plain_share"]), float(cf["plain_bad"]), float(cf["plain_good"]))
	var g_ent := ArtLabScore.grade(float(g["entropy"]), float(cf["entropy_bad"]), float(cf["entropy_good"]))
	var s1 := (g_isl * float(cf["w_per_part"]) + g_plain * float(cf["w_plain"]) + g_ent * float(cf["w_entropy"])) / \
		(float(cf["w_per_part"]) + float(cf["w_plain"]) + float(cf["w_entropy"]))
	ctx.m["craft_c1"] = s1
	var plist: Array[String] = []
	for k: String in piv:
		plist.append("%s %d" % [k, int(piv[k])])
	var thin: Array[String] = []
	for k2: String in piv:
		if int(piv[k2]) <= 2 and n_piv > 1:
			thin.append(k2)
	var hint1 := ""
	if s1 < 0.8:
		var why: Array[String] = []
		if g_isl < 0.8:
			why.append("only %s shapes per body part (aim >= %s): add secondary / tertiary shapes (straps, plates, bark ridges, cuffs, knuckles, a collar)%s" % [ctx.fmt(per_part), ctx.fmt(float(cf["per_part_good"]), 0), (" on " + ", ".join(thin)) if not thin.is_empty() else ""])
		if g_plain < 0.8:
			why.append("%d%% of the surface is plain boxes / low-sided prisms: taper, bevel or bend the big limbs and the torso (tapered paths, more sides, a lathe profile)" % int(float(g["plain_share"]) * 100.0))
		if g_ent < 0.8:
			why.append("few surface directions (normal variety %s): tilt, curve and rotate parts so the light breaks on them" % ctx.fmt(float(g["entropy"]), 2))
		hint1 = "Plain / blocky shapes: " + "; ".join(why)
	ctx.rep.add("C1", "craft", "Shape richness (secondary shapes)", "INFO",
		"%d shapes over %d body parts (%s per part: %s); %d%% of the surface on plain boxes / prisms (<= 10 face directions); normal variety %s" % [
			int(g["islands"]), n_piv, ctx.fmt(per_part), ", ".join(plist), int(float(g["plain_share"]) * 100.0), ctx.fmt(float(g["entropy"]), 3)],
		"craft (lab v3.1): >= %s separate shapes per body part, <= %d%% plain boxes / prisms, normal variety >= %s%s" % [
			ctx.fmt(float(cf["per_part_good"]), 0), int(float(cf["plain_good"]) * 100.0), ctx.fmt(float(cf["entropy_good"]), 2),
			"" if graded else " (not graded for %s yet)" % ctx.kind],
		"", s1 if graded else -1.0, hint1, "close", float(cf["weight_c1"]))
	# C2: vertex use vs the tier budget (under-use counts: detail left on the table; over budget is B4's job)
	var vb := _vert_budget(ctx)
	var lim := int(vb.get("limit", 0))
	if lim > 0:
		var use := float(g[vb["key"]]) / float(lim)
		ctx.m["craft_use"] = use
		var s2 := ArtLabScore.grade(use, float(cf["use_bad"]), float(cf["use_good"]))
		ctx.rep.add("C2", "craft", "Vertex use vs budget", "INFO", "%d%% of the %d %s budget used (%d)" % [int(use * 100.0), lim, vb["key"], int(g[vb["key"]])],
			"craft (lab v3.1): a finished model uses >= %d%% of its tier budget (under-use = detail left on the table; over is B4)%s" % [
				int(float(cf["use_good"]) * 100.0), "" if graded else " (not graded for %s yet)" % ctx.kind],
			"", s2 if graded else -1.0,
			"Only %d%% of the vertex budget is used: spend it on the close / 25 m read (bevels, tapers, more sides on the big curved masses, secondary shapes)" % int(use * 100.0) if s2 < 0.8 else "",
			"close", float(cf["weight_c2"]))


## Render part: C3 palette depth (close-up) + C4 inner detail at the close-up and 25 m. Windowed only.
static func check_render(ctx: ArtLabRunner) -> void:
	if ctx.kind in [&"decor_set", &"vfx"] or not ctx.m.has("box"):
		return
	var cf: Dictionary = ArtLabBudgets.CRAFT
	var graded := ctx.kind in GRADED_KINDS
	var r: Dictionary = await measure_image(ctx)
	ctx.m["craft_img"] = r
	var gp := ArtLabScore.grade(float(r["palette"]), float(cf["palette_bad"]), float(cf["palette_good"]))
	var gv := ArtLabScore.grade(float(r["values"]), float(cf["values_bad"]), float(cf["values_good"]))
	var s3 := (gp + gv) * 0.5
	ctx.rep.add("C3", "craft", "Palette depth (close-up)", "INFO",
		"%d colour steps (L*a*b* bins >= 2 %% of the body), %d value steps (L* bins of 8 >= 3 %%)" % [int(r["palette"]), int(r["values"])],
		"craft (lab v3.1): >= %d colour steps and >= %d value steps at the close-up%s" % [int(cf["palette_good"]), int(cf["values_good"]),
			"" if graded else " (not graded for %s yet)" % ctx.kind],
		"", s3 if graded else -1.0,
		"Flat palette (%d colour / %d value steps): add a darker and a lighter step of the main colours (trim, recesses, highlights on the top masses)" % [int(r["palette"]), int(r["values"])] if s3 < 0.8 else "",
		"close", float(cf["weight_c3"]))
	var ge := ArtLabScore.grade(float(r["edges_close"]), float(cf["edges_bad"]), float(cf["edges_good"]))
	var g25 := ArtLabScore.grade(float(r["edges25"]), float(cf["edges25_bad"]), float(cf["edges25_good"]))
	var s4 := (ge + g25) * 0.5
	ctx.rep.add("C4", "craft", "Inner detail (close-up / 25 m)", "INFO",
		"inner edges per outline px: %s at the close-up (%d px), %s at 25 m; close-up outline complexity %s" % [ctx.fmt(float(r["edges_close"]), 2),
			int(r["px_close"]), ctx.fmt(float(r["edges25"]), 2), ctx.fmt(float(r["cx_close"]), 2)],
		"craft (lab v3.1): >= %s inner edge px per outline px at the close-up, >= %s at 25 m (shape and value breaks inside the silhouette)%s" % [
			ctx.fmt(float(cf["edges_good"]), 2), ctx.fmt(float(cf["edges25_good"]), 2), "" if graded else " (not graded for %s yet)" % ctx.kind],
		"", s4 if graded else -1.0,
		"Big plain panels inside the silhouette (%s inner edges per outline px): break the torso / limbs with secondary shapes and value breaks (belt, plates, straps, bark seams)" % ctx.fmt(float(r["edges_close"]), 2) if s4 < 0.8 else "",
		"close", float(cf["weight_c4"]))


## {key: "verts" / "tris", limit} of the tier's geometry budget (hard or soft), {} when none.
static func _vert_budget(ctx: ArtLabRunner) -> Dictionary:
	var row := ArtLabBudgets.row(ctx.kind, ctx.tier)
	var soft: Dictionary = row.get("soft", {})
	for k: String in ["verts", "tris"]:
		if row.has(k):
			return {"key": k, "limit": int(row[k])}
		if soft.has(k):
			return {"key": k, "limit": int(soft[k])}
	return {}


## Geometry measures of every visible, non-particle, non-flat part (in the holder's frame). Headless-safe.
## Returns {verts, tris, islands, plain_share, entropy, parts, pivots, area}.
static func measure_geometry(root: Node3D, frame: Transform3D, ground_y: float) -> Dictionary:
	var inv := frame.affine_inverse()
	var islands := 0
	var plain_area := 0.0
	var total_area := 0.0
	var hist := {}   # lat-long bin -> area
	var pivots := {}
	var verts := 0
	var tris := 0
	for gi: GeometryInstance3D in ArtLabCensus.geometry(root):
		if not gi.is_visible_in_tree() or ArtLabCensus.is_particles(gi) or ArtLabCensus.is_flat_decal(gi, ground_y):
			continue
		if not gi is MeshInstance3D or (gi as MeshInstance3D).mesh == null:
			continue
		var mesh := (gi as MeshInstance3D).mesh
		var xf := inv * gi.global_transform
		var st := ArtLabCensus.mesh_stats(mesh)
		verts += st.x
		tris += st.y
		var piv := String(gi.get_parent().name) if gi.get_parent() != root else "(root)"
		for s: int in mesh.get_surface_count():
			if mesh is ArrayMesh and (mesh as ArrayMesh).surface_get_primitive_type(s) != Mesh.PRIMITIVE_TRIANGLES:
				continue
			var arr := mesh.surface_get_arrays(s)
			if arr.is_empty():
				continue
			var r := _surface(arr, xf, hist)
			islands += int(r["islands"])
			plain_area += float(r["plain_area"])
			total_area += float(r["area"])
			pivots[piv] = int(pivots.get(piv, 0)) + int(r["islands"])
	var ent := 0.0
	if total_area > 0.0:
		for k: Variant in hist:
			var p := float(hist[k]) / total_area
			if p > 0.0:
				ent -= p * log(p)
	# normalised by the entropy of a uniform sphere over the used bins (lat-long 16 x 8 = 128 bins)
	var ent_n := ent / log(128.0)
	return {"verts": verts, "tris": tris, "islands": islands, "area": total_area,
		"plain_share": plain_area / total_area if total_area > 0.0 else 0.0, "entropy": ent_n, "pivots": pivots}


## One surface: islands (vertex-connected pieces, positions welded at 0.1 mm), each island's distinct face directions
## (a box has 6, a 6-sided prism 8), area-weighted normal histogram.
static func _surface(arr: Array, xf: Transform3D, hist: Dictionary) -> Dictionary:
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: Variant = arr[Mesh.ARRAY_INDEX]
	var ids := PackedInt32Array()
	if idx is PackedInt32Array and (idx as PackedInt32Array).size() > 0:
		ids = idx
	else:
		ids.resize(v.size() - v.size() % 3)
		for i: int in ids.size():
			ids[i] = i
	# weld positions
	var weld := {}
	var wid := PackedInt32Array()
	wid.resize(v.size())
	for i2: int in v.size():
		var p := v[i2]
		var key := Vector3i(roundi(p.x * 10000.0), roundi(p.y * 10000.0), roundi(p.z * 10000.0))
		var w: Variant = weld.get(key)
		if w == null:
			w = weld.size()
			weld[key] = w
		wid[i2] = int(w)
	var parent := PackedInt32Array()
	parent.resize(weld.size())
	for i3: int in parent.size():
		parent[i3] = i3
	var nt := ids.size() / 3
	for t: int in nt:
		var a := _find(parent, wid[ids[t * 3]])
		var b := _find(parent, wid[ids[t * 3 + 1]])
		var c := _find(parent, wid[ids[t * 3 + 2]])
		if a != b:
			parent[b] = a
		if a != c:
			parent[_find(parent, c)] = a
	var isl := {}   # root -> {area, dirs: {}}
	var basis := xf.basis
	for t2: int in nt:
		var pa := xf * v[ids[t2 * 3]]
		var pb := xf * v[ids[t2 * 3 + 1]]
		var pc := xf * v[ids[t2 * 3 + 2]]
		var nrm := (pc - pa).cross(pb - pa)
		var l := nrm.length()
		if l < 1e-10:
			continue
		var area := l * 0.5
		nrm /= l
		var r := _find(parent, wid[ids[t2 * 3]])
		var d: Dictionary = isl.get(r, {})
		if d.is_empty():
			d = {"area": 0.0, "dirs": {}}
			isl[r] = d
		d["area"] = float(d["area"]) + area
		(d["dirs"] as Dictionary)[Vector3i(roundi(nrm.x * DIR_STEPS), roundi(nrm.y * DIR_STEPS), roundi(nrm.z * DIR_STEPS))] = true
		var lat := int(clampf((asin(clampf(nrm.y, -1.0, 1.0)) / PI + 0.5) * 8.0, 0.0, 7.0))
		var lon := int(clampf((atan2(nrm.z, nrm.x) / TAU + 0.5) * 16.0, 0.0, 15.0))
		var hk := lat * 16 + lon
		hist[hk] = float(hist.get(hk, 0.0)) + area
	var plain := 0.0
	var total := 0.0
	var n_isl := 0
	for r2: Variant in isl:
		var d2: Dictionary = isl[r2]
		total += float(d2["area"])
		n_isl += 1
		# plain = a box / low-sided prism / flat card: few face directions
		if (d2["dirs"] as Dictionary).size() <= 10:
			plain += float(d2["area"])
	var _unused := basis
	return {"islands": n_isl, "plain_area": plain, "area": total}


## Render measures on the frozen idle pose: the close-up 3/4 camera (as the `close` shot) and the 25 m game camera.
## Returns {palette, values, edges_close, edges25, cx_close, px_close}.
##   palette  L*a*b* bins (L 10, a / b 15) holding >= 2 % of the body pixels at the close-up
##   values   L* bins of 8 holding >= 3 % (value steps)
##   edges_*  inner edge pixels (|grad L*| > 8, outline excluded) per outline pixel: secondary / tertiary shapes and
##            value breaks inside the silhouette, scale-free (a box figure has few inner edges for its outline)
##   cx_close outline complexity of the close-up mask (perimeter^2 / 4 pi area)
static func measure_image(ctx: ArtLabRunner) -> Dictionary:
	var box: AABB = ctx.m["box"]
	var out := {}
	ArtLabStage.freeze(ctx.target, true)
	await ctx.frames(1)
	ctx.stage.fit_cam(box, 20.0, 0.0, 0.8)
	var roi := ctx.stage.roi_of(box, 8)
	var mk := ArtLabImage.sil_mask(await ArtLabShots.sil(ctx, ctx.target), roi)
	var lit: Image = await ctx.stage.grab()
	out["px_close"] = mk.count
	out["cx_close"] = ArtLabImage.complexity(mk)
	var pal := palette(lit, roi, mk)
	out["palette"] = pal.x
	out["values"] = pal.y
	out["edges_close"] = edge_ratio(lit, roi, mk)
	ctx.stage.game_cam(ctx.gp, 25.0)
	var roi25 := ctx.stage.roi_of(box, 8)
	var mk25 := ArtLabImage.sil_mask(await ArtLabShots.sil(ctx, ctx.target), roi25)
	var lit25: Image = await ctx.stage.grab()
	out["edges25"] = edge_ratio(lit25, roi25, mk25)
	out["px25"] = mk25.count
	ctx.stage.game_cam(ctx.gp, 40.0)
	ArtLabStage.freeze(ctx.target, false)
	return out


## (colour bins >= 2 %, value bins >= 3 %) of the mask pixels.
static func palette(img: Image, roi: Rect2i, m: ArtLabImage.Mask) -> Vector2i:
	var a := ArtLabImage.rgba8(img).get_data()
	var iw := img.get_width()
	var bins := {}
	var vbins := {}
	var n := 0
	for y: int in m.h:
		for x: int in m.w:
			if m.bits[y * m.w + x] == 0:
				continue
			var i := (((roi.position.y + y) * iw) + roi.position.x + x) * 4
			var c := ArtLabImage.lab(a[i], a[i + 1], a[i + 2])
			var k := Vector3i(int(c.x / 10.0), int(floor(c.y / 15.0)), int(floor(c.z / 15.0)))
			bins[k] = int(bins.get(k, 0)) + 1
			var vk := int(c.x / 8.0)
			vbins[vk] = int(vbins.get(vk, 0)) + 1
			n += 1
	var pc := 0
	for k2: Variant in bins:
		if float(bins[k2]) >= 0.02 * float(n):
			pc += 1
	var vc := 0
	for k3: Variant in vbins:
		if float(vbins[k3]) >= 0.03 * float(n):
			vc += 1
	return Vector2i(pc, vc)


## Inner edge pixels (|grad L*| > 8, 4-neighbours inside the mask) per outline pixel.
static func edge_ratio(img: Image, roi: Rect2i, m: ArtLabImage.Mask) -> float:
	var a := ArtLabImage.rgba8(img).get_data()
	var iw := img.get_width()
	var inner := 0
	var per := 0
	for y: int in range(1, m.h - 1):
		for x: int in range(1, m.w - 1):
			if not m.at(x, y):
				continue
			if not (m.at(x + 1, y) and m.at(x - 1, y) and m.at(x, y + 1) and m.at(x, y - 1)):
				per += 1
				continue
			var i := (((roi.position.y + y) * iw) + roi.position.x + x) * 4
			var l0 := ArtLabImage.lab(a[i], a[i + 1], a[i + 2]).x
			var ir := i + 4
			var id := i + iw * 4
			var gx := ArtLabImage.lab(a[ir], a[ir + 1], a[ir + 2]).x - l0
			var gy := ArtLabImage.lab(a[id], a[id + 1], a[id + 2]).x - l0
			if gx * gx + gy * gy > 64.0:
				inner += 1
	return float(inner) / float(maxi(per, 1))


static func _find(parent: PackedInt32Array, i: int) -> int:
	var r := i
	while parent[r] != r:
		r = parent[r]
	var j := i
	while parent[j] != r:
		var nx := parent[j]
		parent[j] = r
		j = nx
	return r
