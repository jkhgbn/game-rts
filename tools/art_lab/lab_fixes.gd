class_name ArtLabFixes
extends RefCounted
## Art Lab v3 task 1.A "fix recipes" (docs/plan/art-lab-v3-plan.md, docs/plan/art-lab.md section 4): every FAIL / WARN
## gets a machine-readable recipe in `fixes.json` next to the scorecard: the node / mesh / material / parameter to touch,
## the measured vs the wanted value and a concrete proposal. Where the lab has the data the proposal is COMPUTED:
##  - colour (R3 / R3t / R4k, R4 as a soft goal): the nearest albedo of one body material that passes all of them at
##    once, predicted with a linear mix model of the body's mean colour (visible-area weights x a measured light gain);
##  - glow (R5): the emission energy that brings a glow point over (or under) the bloom level, from the measured peak of
##    each point on an unclipped "hot" render (exposure / 8), grouped by emissive material;
##  - budgets: which meshes to merge (B1 / B2, per pivot and material), which meshes to thin (B4 / B4t), which parts
##    stop casting shadows (B7), which materials to fold together (B8); R1 scale, R9 lift, R10 radius.
## Anything else gets a recipe from the check's own hint (computed = false).
## Flow: readability.gd hands over the 40 m data (ctx.m "fix_grounds" / "fix_team" and the `capture_40` hook, both
## behind guards); ArtLabScore.add_extras calls `build(ctx)` after the last check, which writes fixes.json and puts the
## recipe text on each check (`c["fix"]`), so "Improve next" (ArtLabScore.improve_next) shows the top recipe in words.

const VERSION := "1.0"
const FILE := "fixes.json"
## Safety margin (dE) over the wanted contrast: the mix model is an estimate, the re-run is the judge.
const MARGIN_DE := 4.0
## Crossing / clearing the bloom level: a point must reach 1.3 x the level to stay over it through the idle pulse, and
## drop to 0.75 x to stay under it.
const GLOW_OVER := 1.3
const GLOW_UNDER := 0.75
## Exposure divisor of the second hot render (peaks up to 8 x the bloom level are measured unclipped).
const HOT_RANGE := 8.0
const COLOR_PARAMS: Array[String] = ["base_color", "albedo_color", "albedo", "color", "cloth_color", "bark_color", "body_color"]
const COLOR_SKIP: Array[String] = ["rim", "crack", "glow", "emis", "flash", "team", "spec", "hot", "core", "outline",
	"glyph", "fog", "void", "window", "heart", "lava", "sky", "shadow"]
const ENERGY_PARAMS: Array[String] = ["energy", "emission_energy", "glow_energy", "emission_strength", "glow_strength",
	"boost", "intensity"]
const PASS_SCORE := 0.97


# ================================================================ hook (readability.gd, 40 m pass, frozen pose)

## Called once from ArtLabCheckRead.read_40 right after the first glow phase (same frozen pose as the 40 m mask):
## grabs the "hot" frame at the bloom exposure and at exposure / 8 (unclipped peaks), and records the projected part
## boxes and the per-material visible-area weights of this pose. Everything lands in ctx.m["fix40"].
static func capture_40(ctx: ArtLabRunner, roi: Rect2i, mask: ArtLabImage.Mask) -> void:
	if ctx.headless or ctx.target == null or ctx.stage == null:
		return
	var off: Array[Node3D] = []
	for ln: Node in ctx.target.find_children("*", "Light3D", true, false):
		if (ln as Light3D).visible:
			off.append(ln as Node3D)
			(ln as Light3D).visible = false
	for gi: GeometryInstance3D in ArtLabCensus.geometry(ctx.target):
		if gi.visible and ArtLabCensus.is_flat_decal(gi, ctx.ground_y):
			off.append(gi)
			gi.visible = false
	ctx.stage.set_mode(&"hot")
	var hot: Image = await ctx.stage.grab()
	var env: Environment = ctx.stage.env_hot
	var exp0 := env.tonemap_exposure
	env.tonemap_exposure = exp0 / HOT_RANGE
	var hot8: Image = await ctx.stage.grab()
	env.tonemap_exposure = exp0
	ctx.stage.set_mode(&"lit")
	for n: Node3D in off:
		n.visible = true
	var boxes: Array = []
	for gi2: GeometryInstance3D in ArtLabCensus.geometry(ctx.target):
		if gi2.is_visible_in_tree() and not ArtLabCensus.is_particles(gi2):
			boxes.append({"rect": ctx.stage.roi_of(gi2.global_transform * gi2.get_aabb(), 1),
				"path": String(ctx.target.get_path_to(gi2))})
	ctx.m["fix40"] = {"hot": hot, "hot8": hot8, "roi": roi, "mask": mask, "boxes": boxes,
		"level": ctx.stage.glow_level, "weights": material_weights(ctx.target, ctx.ground_y, to_camera(ctx))}


static func to_camera(ctx: ArtLabRunner) -> Vector3:
	if ctx.stage != null and ctx.stage.cam != null:
		return ctx.stage.cam.global_basis.z.normalized()
	var p := deg_to_rad(55.0)
	return Vector3(0.0, sin(p), cos(p))


# ================================================================ entry (ArtLabScore.add_extras, after the last check)

## Builds every recipe, writes <out>/fixes.json and puts each recipe's text on its check (`fix`, `fix_rank`).
## Returns the fixes dictionary (also for tests).
static func build(ctx: ArtLabRunner) -> Dictionary:
	var fixes: Array[Dictionary] = []
	var done := {}
	for c0: Dictionary in ctx.rep.checks:   # checks kept from a previous run (1.B focus=) may carry old recipes
		c0.erase("fix")
		c0.erase("fix_rank")
	var rules :=ArtLabBudgets.read_rules(ctx.kind, ctx.tier) if ctx.kind != &"" else {}
	var model_ok := ctx.target != null and is_instance_valid(ctx.target)
	# colour: one recipe covers R3 / R3t / R4k / R4 (attached to the worst of them)
	var colour := {}
	if model_ok:
		colour = colour_fix(ctx, rules)
		if not colour.is_empty():
			fixes.append(colour)
			for id: String in colour.get("covers", []):
				done[id] = true
	for c: Dictionary in ctx.rep.checks:
		var st: String = c["status"]
		var id2: String = c["id"]
		if done.has(id2):
			continue
		if st != "FAIL" and st != "WARN":
			continue
		var f := {}
		if model_ok:
			match id2:
				"R5":
					f = glow_fix(ctx, c, rules)
				"B1", "B2":
					f = merge_fix(ctx, c)
				"B4", "B4t":
					f = verts_fix(ctx, c)
				"B7":
					f = casters_fix(ctx, c)
				"B8":
					f = materials_fix(ctx, c)
				"R1":
					f = area_fix(ctx, c, rules)
				"R9":
					f = feet_fix(ctx, c)
				"R10":
					f = radius_fix(ctx, c)
				"R8":
					f = head_fix(ctx, c)
		if f.is_empty():
			f = generic_fix(c)
		done[id2] = true
		fixes.append(f)
	_rank(ctx, fixes)
	var out := {"version": VERSION, "asset": ctx.asset, "scene": ctx.scene_path, "kind": String(ctx.kind),
		"tier": String(ctx.tier), "kingdom": String(ctx.kingdom), "ground": String(ctx.ground_id),
		"result": ctx.rep.result(), "quality": snappedf(ctx.rep.quality(), 0.1), "count": fixes.size(), "fixes": fixes}
	if ctx.out_dir != "":
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ctx.out_dir))
		var fa := FileAccess.open(ctx.out_dir.path_join(FILE), FileAccess.WRITE)
		if fa:
			fa.store_string(JSON.stringify(_jsonable(out), "\t"))
			fa.close()
	if not fixes.is_empty():
		ctx.rep.notes.append("Fix recipes: %d in %s (top: %s)" % [fixes.size(), FILE, String(fixes[0]["text"]).left(160)])
	return out


## Ranks the fixes like "Improve next" (FAIL, then WARN, then weighted headroom) and writes each one's text on its check.
static func _rank(ctx: ArtLabRunner, fixes: Array[Dictionary]) -> void:
	var by_id := {}
	for c: Dictionary in ctx.rep.checks:
		by_id[String(c["id"])] = c
	for f: Dictionary in fixes:
		var c2: Dictionary = by_id.get(String(f["check"]), {})
		var r := 0.0
		if not c2.is_empty():
			var w: float = float(c2["weight"]) * float(ArtLabScore.GROUP_WEIGHT.get(c2["group"], 1.0))
			r = w * (1.0 - maxf(float(c2["score"]), 0.0))
		match String(f["status"]):
			"FAIL":
				r += 100.0
			"WARN":
				r += 10.0
		if bool(f.get("computed", false)):
			r += 0.5   # a computed recipe beats a hint at the same level
		f["_r"] = r
	fixes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["_r"]) > float(b["_r"]))
	for i: int in fixes.size():
		var f2: Dictionary = fixes[i]
		f2.erase("_r")
		f2["rank"] = i + 1
		# the proposal alone (no check id in front): what lab_army.gd (1.E) shows next to "<check>: "
		var t: String = f2["text"]
		var cid: String = f2["check"]
		f2["proposal"] = t.trim_prefix(cid + ": ").trim_prefix(cid + " ") if t.begins_with(cid) else t
		var c3: Dictionary = by_id.get(String(f2["check"]), {})
		if not c3.is_empty():
			c3["fix"] = "%s [fixes.json #%d]" % [String(f2["text"]), i + 1]
			c3["fix_rank"] = i + 1


# ================================================================ colour (R3 / R3t / R4k / R4)

## The nearest albedo of one body material that passes R3, R3t (every team colour) and R4k at once (R4 on the other
## grounds as a soft goal). Model: body mean (linear RGB) = sum over materials of visible-area weight x albedo x a
## per-channel light gain measured from the real render; changing material X by d moves every measured body mean
## (main ground, other grounds, team copies) by gain x w_X x d. Empty when no colour check has headroom or data.
static func colour_fix(ctx: ArtLabRunner, rules: Dictionary) -> Dictionary:
	var con: Dictionary = ctx.m.get("con", {})
	if con.is_empty() or int(con.get("n", 0)) == 0:
		return {}
	var checks := {}
	for c: Dictionary in ctx.rep.checks:
		if String(c["id"]) in ["R3", "R3t", "R4k", "R4"]:
			checks[String(c["id"])] = c
	var need := false
	var worst: Dictionary = {}
	for id: String in ["R3", "R3t", "R4k", "R4"]:
		var c2: Dictionary = checks.get(id, {})
		if c2.is_empty():
			continue
		if c2["status"] == "FAIL" or c2["status"] == "WARN":
			need = true
			if worst.is_empty() or _sev(c2) > _sev(worst):
				worst = c2
	if not need:
		return {}
	var de_warn: float = rules.get("de_warn", 20.0)
	var de_fail: float = rules.get("de_fail", 10.0)
	var melt_warn: float = rules.get("melt_warn", 0.35)
	var want := de_warn + MARGIN_DE
	if float(con.get("melt_frac", 0.0)) > melt_warn:
		want += 5.0   # melting pixels: the mean must move further so the melting share drops too
	# the views: [label, body Lab, ground Lab, wanted dE, hard]
	var views: Array = []
	views.append(["R3 " + String(ctx.ground_id), con["model_lab"], con["ground_lab"], want, true])
	var team: Dictionary = ctx.m.get("fix_team", {})
	for k: String in team:
		var ct: Dictionary = team[k]
		if int(ct.get("n", 0)) > 0:
			views.append(["R3t " + k, ct["model_lab"], ct["ground_lab"], de_warn + MARGIN_DE, true])
	var grounds: Dictionary = ctx.m.get("fix_grounds", {})
	var home: StringName = ArtLabBudgets.KINGDOM_GROUND.get(ctx.kingdom, &"")
	for g: String in grounds:
		var cg: Dictionary = grounds[g]
		if int(cg.get("n", 0)) == 0:
			continue
		if StringName(g) == home:
			views.append(["R4k " + g, cg["model_lab"], cg["ground_lab"], de_warn + MARGIN_DE, true])
		else:
			views.append(["R4 " + g, cg["model_lab"], cg["ground_lab"], de_fail + MARGIN_DE, false])
	var cap: Dictionary = ctx.m.get("fix40", {})
	var weights: Dictionary = cap.get("weights", {})
	if weights.is_empty():
		weights = material_weights(ctx.target, ctx.ground_y, to_camera(ctx))
	# the light gain: measured body mean (linear) / predicted albedo mix
	var mix := Vector3.ZERO
	var wsum := 0.0
	for key: String in weights:
		var e: Dictionary = weights[key]
		if bool(e["info"].get("emissive", false)) or not e["info"].has("color"):
			continue
		mix += srgb_to_lin(e["info"]["color"]) * float(e["w"])
		wsum += float(e["w"])
	if wsum <= 0.0:
		ctx.rep.notes.append("fix recipes: colour not computed (no body material with an albedo among %d drawn materials)" % weights.size())
		return {}
	var body_lin := lab_to_lin(con["model_lab"])
	var gain := Vector3.ONE
	for i: int in 3:
		gain[i] = clampf(body_lin[i] / maxf(mix[i], 0.002), 0.05, 8.0)
	# candidates: the biggest non-team, non-emissive, recolourable materials
	var cands: Array[Dictionary] = []
	for key2: String in weights:
		var e2: Dictionary = weights[key2]
		var inf: Dictionary = e2["info"]
		if bool(inf.get("emissive", false)) or bool(inf.get("team", false)) or not inf.has("color") or float(e2["w"]) < 0.06:
			continue
		cands.append(e2)
	cands.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["w"]) > float(b["w"]))
	cands = cands.slice(0, 4)
	var measured := {}
	for v: Array in views:
		measured[v[0]] = snappedf((v[1] as Vector3).distance_to(v[2]), 0.1)
	var best := {}
	for cand: Dictionary in cands:
		var sol := _solve(cand, gain, views)
		if sol.is_empty():
			continue
		if best.is_empty() or (bool(sol["ok"]) and not bool(best["ok"])) \
				or (bool(sol["ok"]) == bool(best["ok"]) and bool(sol["ok"]) and float(sol["cost"]) < float(best["cost"])) \
				or (not bool(sol["ok"]) and not bool(best["ok"]) and float(sol["margin"]) > float(best["margin"])):
			best = sol
			best["cand"] = cand
	var covers: Array[String] = []
	for id2: String in checks:
		covers.append(id2)
	var f := {"check": String(worst["id"]), "status": String(worst["status"]), "title": "Body colour vs the grounds",
		"computed": not best.is_empty(), "covers": covers,
		"measured": {"dE": measured, "melt_share": snappedf(float(con.get("melt_frac", 0.0)), 0.01),
			"body_lab": _v(con["model_lab"]), "ground_lab": _v(con["ground_lab"])},
		"wanted": {"dE_R3_R3t_R4k": ">= %s (rule %s + margin %s)" % [ctx.fmt(want, 0), ctx.fmt(de_warn, 0), ctx.fmt(want - de_warn, 0)],
			"dE_R4": ">= %s (soft)" % ctx.fmt(de_fail + MARGIN_DE, 0), "melt_share": "<= %d%%" % int(melt_warn * 100.0)},
		"changes": [], "predicted": {}}
	if best.is_empty():
		f["text"] = "Body colour: no single recolourable body material found (all team / emissive / tiny): " + String(worst["hint"])
		return f
	var cand2: Dictionary = best["cand"]
	var info: Dictionary = cand2["info"]
	var from_c: Color = info["color"]
	var to_c: Color = best["color"]
	f["changes"] = [{"node": ", ".join(PackedStringArray((cand2["nodes"] as Array).slice(0, 4))), "material": info["label"],
		"material_path": info["path"], "param": info["param"], "from": "#" + from_c.to_html(false), "to": "#" + to_c.to_html(false),
		"weight": snappedf(float(cand2["w"]), 0.01), "shared": _shared_note(ctx, info)}]
	f["predicted"] = best["pred"]
	f["gain"] = _v(gain)
	var worst_pred := ""
	var lines: Array[String] = []
	for v2: Array in views:
		if bool(v2[4]):
			lines.append("%s %s -> %s" % [v2[0], ctx.fmt(float(measured[v2[0]])), ctx.fmt(float(best["pred"][v2[0]]))])
	var soft: Array[String] = []
	for v3: Array in views:
		if not bool(v3[4]):
			soft.append("%s %s" % [String(v3[0]).trim_prefix("R4 "), ctx.fmt(float(best["pred"][v3[0]]))])
	if not soft.is_empty():
		worst_pred = "; other grounds " + ", ".join(soft)
	f["text"] = "%s of `%s` %s -> %s (%d%% of the visible body): predicted dE %s (want >= %s)%s%s%s" % [
		info["param"], info["label"], "#" + from_c.to_html(false), "#" + to_c.to_html(false), int(float(cand2["w"]) * 100.0),
		", ".join(lines), ctx.fmt(want, 0), worst_pred,
		"" if bool(best["ok"]) else "; PARTIAL: best reachable with one material, also recolour the next biggest mass",
		("; " + String(f["changes"][0]["shared"])) if String(f["changes"][0]["shared"]) != "" else ""]
	return f


static func _sev(c: Dictionary) -> float:
	return (100.0 if c["status"] == "FAIL" else (10.0 if c["status"] == "WARN" else 0.0)) + (1.0 - float(c["score"]))


## Grid search (sRGB step 1/12, then 1/48 around the best) for the albedo nearest to the current one (CIE76 of the
## albedos) whose predicted views all pass; else the one with the best worst margin. {color, ok, cost, margin, pred}.
static func _solve(cand: Dictionary, gain: Vector3, views: Array) -> Dictionary:
	var a0: Color = cand["info"]["color"]
	var a0_lin := srgb_to_lin(a0)
	var a0_lab := lin_to_lab(a0_lin)
	var w: float = cand["w"]
	var base: Array = []   # per view: body linear, ground Lab, want, hard
	for v: Array in views:
		base.append([lab_to_lin(v[1]), v[2], float(v[3]), bool(v[4])])
	var best := {}
	var eval := func(c: Color) -> Dictionary:
		var cl := srgb_to_lin(c)
		var d := (cl - a0_lin) * gain * w
		var margin := INF
		var soft_pen := 0.0
		for b: Array in base:
			var nb := ((b[0] as Vector3) + d).max(Vector3.ZERO)
			var de := lin_to_lab(nb).distance_to(b[1])
			if bool(b[3]):
				margin = minf(margin, de - float(b[2]))
			else:
				soft_pen += maxf(float(b[2]) - de, 0.0)
		return {"margin": margin, "cost": lin_to_lab(cl).distance_to(a0_lab) + soft_pen * 0.5, "ok": margin >= 0.0}
	var better := func(r: Dictionary, bst: Dictionary) -> bool:
		if bst.is_empty():
			return true
		if bool(r["ok"]) != bool(bst["ok"]):
			return bool(r["ok"])
		if bool(r["ok"]):
			return float(r["cost"]) < float(bst["cost"])
		return float(r["margin"]) > float(bst["margin"])
	for ri: int in 13:
		for gi: int in 13:
			for bi: int in 13:
				var c := Color(float(ri) / 12.0, float(gi) / 12.0, float(bi) / 12.0)
				var r: Dictionary = eval.call(c)
				if better.call(r, best):
					best = r
					best["color"] = c
	if best.is_empty():
		return {}
	var c0: Color = best["color"]
	for ri2: int in range(-4, 5):
		for gi2: int in range(-4, 5):
			for bi2: int in range(-4, 5):
				var c2 := Color(clampf(c0.r + float(ri2) / 48.0, 0.0, 1.0), clampf(c0.g + float(gi2) / 48.0, 0.0, 1.0),
					clampf(c0.b + float(bi2) / 48.0, 0.0, 1.0))
				var r2: Dictionary = eval.call(c2)
				if better.call(r2, best):
					best = r2
					best["color"] = c2
	var col: Color = best["color"]
	var d2 := (srgb_to_lin(col) - a0_lin) * gain * w
	var pred := {}
	for v2: Array in views:
		pred[v2[0]] = snappedf(lin_to_lab((lab_to_lin(v2[1]) + d2).max(Vector3.ZERO)).distance_to(v2[2]), 0.1)
	best["pred"] = pred
	return best


## Visible-area weight of every material the model draws at rest: triangle area x how much it faces the camera
## (pitch 55 from above), flat decals and particles skipped. {key: {w (0-1), info (material_info), nodes: [paths]}}.
static func material_weights(root: Node3D, ground_y: float, to_cam: Vector3) -> Dictionary:
	var acc := {}
	var total := 0.0
	for gi: GeometryInstance3D in ArtLabCensus.geometry(root):
		if not gi.is_visible_in_tree() or ArtLabCensus.is_particles(gi) or ArtLabCensus.is_flat_decal(gi, ground_y):
			continue
		var mesh: Mesh = null
		var xfs: Array[Transform3D] = []
		if gi is MeshInstance3D:
			mesh = (gi as MeshInstance3D).mesh
			xfs.append(gi.global_transform)
		elif gi is MultiMeshInstance3D and (gi as MultiMeshInstance3D).multimesh:
			var mm := (gi as MultiMeshInstance3D).multimesh
			mesh = mm.mesh
			var n := mm.visible_instance_count if mm.visible_instance_count >= 0 else mm.instance_count
			for i: int in mini(n, 48):
				xfs.append(gi.global_transform * mm.get_instance_transform(i))
		if mesh == null or xfs.is_empty():
			continue
		for s: int in mesh.get_surface_count():
			var mat := surface_material(gi, s)
			if mat == null:
				continue
			var area := _surface_area(mesh, s, xfs, to_cam)
			if area <= 0.0:
				continue
			var key := str(mat.get_instance_id())
			if not acc.has(key):
				acc[key] = {"w": 0.0, "info": material_info(mat), "nodes": []}
			acc[key]["w"] = float(acc[key]["w"]) + area
			var p := String(root.get_path_to(gi))
			if not p in (acc[key]["nodes"] as Array):
				(acc[key]["nodes"] as Array).append(p)
			total += area
	if total > 0.0:
		for k: String in acc:
			acc[k]["w"] = float(acc[k]["w"]) / total
	return acc


static func _surface_area(mesh: Mesh, s: int, xfs: Array[Transform3D], to_cam: Vector3) -> float:
	if mesh is ArrayMesh and (mesh as ArrayMesh).surface_get_primitive_type(s) != Mesh.PRIMITIVE_TRIANGLES:
		return 0.0
	var arr := mesh.surface_get_arrays(s)
	if arr.is_empty():
		return 0.0
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: Variant = arr[Mesh.ARRAY_INDEX]
	var ids := PackedInt32Array()
	if idx is PackedInt32Array and (idx as PackedInt32Array).size() > 0:
		ids = idx
	else:
		ids.resize(v.size() - v.size() % 3)
		for i: int in ids.size():
			ids[i] = i
	var sum := 0.0
	for xf: Transform3D in xfs:
		for t: int in range(0, ids.size() - 2, 3):
			var a := xf * v[ids[t]]
			var b := xf * v[ids[t + 1]]
			var c := xf * v[ids[t + 2]]
			var nrm := (c - a).cross(b - a)   # Godot front faces wind clockwise: outward normal
			var l := nrm.length()
			if l < 1e-9:
				continue
			sum += 0.5 * l * maxf(nrm.dot(to_cam) / l, 0.0)
	return sum


## The material a surface really draws with (override > surface override > mesh material).
static func surface_material(gi: GeometryInstance3D, s: int) -> Material:
	if gi.material_override:
		return gi.material_override
	if gi is MeshInstance3D:
		var mi := gi as MeshInstance3D
		var m := mi.get_surface_override_material(s)
		return m if m else mi.mesh.surface_get_material(s)
	if gi is MultiMeshInstance3D:
		return (gi as MultiMeshInstance3D).multimesh.mesh.surface_get_material(s)
	return null


## What a fix can change on a material: its albedo parameter (+ colour), whether it glows (+ energy parameter / value
## and glow colour), whether it is a team-colour material (kit cloth / cape: recoloured at spawn).
static func material_info(m: Material) -> Dictionary:
	var label := m.resource_name if m.resource_name != "" else (m.resource_path.get_file().get_basename() if m.resource_path != "" else "%s#%d" % [m.get_class(), m.get_instance_id() % 100000])
	var info := {"label": label, "path": m.resource_path, "class": m.get_class()}
	var lname := label.to_lower()
	info["team"] = lname.ends_with("_cloth") or lname.ends_with("_cloth_dark") or lname.ends_with("_cape") or "team" in lname
	if m is BaseMaterial3D:
		var bm := m as BaseMaterial3D
		info["param"] = "albedo_color"
		info["color"] = bm.albedo_color
		if bm.emission_enabled:
			info["emissive"] = true
			info["glows"] = true
			info["energy_param"] = "emission_energy_multiplier"
			info["energy"] = bm.emission_energy_multiplier
			info["glow_color"] = bm.emission
		elif bm.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
			info["emissive"] = true   # unshaded: its albedo is its glow
			info["glows"] = true
		return info
	if m is ShaderMaterial and (m as ShaderMaterial).shader:
		var sm := m as ShaderMaterial
		var code := sm.shader.code
		info["shader"] = sm.shader.resource_path.get_file()
		var colors: Array[String] = []
		var floats: Array[String] = []
		for u: Dictionary in sm.shader.get_shader_uniform_list():
			var nm: String = u["name"]
			var ty: int = u["type"]
			if ty == TYPE_COLOR or ty == TYPE_VECTOR3:
				colors.append(nm)
			elif ty == TYPE_FLOAT:
				floats.append(nm)
		var pick := ""
		for want: String in COLOR_PARAMS:
			if want in colors:
				pick = want
				break
		if pick == "":
			for nm2: String in colors:
				var skip := false
				for bad: String in COLOR_SKIP:
					if bad in nm2:
						skip = true
						break
				if not skip and "color" in nm2:
					pick = nm2
					break
		var unshaded := "unshaded" in code
		var glows := "EMISSION" in code or unshaded
		if glows:
			for want2: String in ENERGY_PARAMS:
				if want2 in floats:
					info["energy_param"] = "shader_parameter/" + want2
					info["energy"] = float(sm.get_shader_parameter(want2)) if sm.get_shader_parameter(want2) != null else 1.0
					break
			if not info.has("energy_param"):
				for nm3: String in floats:
					if "energy" in nm3 or "boost" in nm3 or (("glow" in nm3 or "emis" in nm3 or "crack" in nm3) and "strength" in nm3):
						info["energy_param"] = "shader_parameter/" + nm3
						info["energy"] = float(sm.get_shader_parameter(nm3)) if sm.get_shader_parameter(nm3) != null else 1.0
						break
			for gname: String in ["glow_color", "emission_color", "emission", "color", "crack_color"]:
				if gname in colors:
					info["glow_color"] = _to_color(sm.get_shader_parameter(gname))
					break
			# kit rune / unit glow: ALBEDO = c * 0.4 + c * energy * pulse (the 0.4 floor does not scale with energy)
			if "* 0.4 +" in code and "energy" in code:
				info["energy_floor"] = 0.4
		if pick != "":
			var val: Variant = sm.get_shader_parameter(pick)
			if val != null:
				info["param"] = "shader_parameter/" + pick
				info["color"] = _to_color(val)
		# "glows": can emit (an energy knob for R5); "emissive": a glow material first (unshaded, or emits without a
		# body colour), never a recolour candidate. A painted body with a crack / hit-flash EMISSION is not emissive.
		info["glows"] = glows
		info["emissive"] = unshaded or (glows and not info.has("color"))
		return info
	return info


static func _to_color(v: Variant) -> Color:
	if v is Color:
		return v
	if v is Vector3:
		return Color((v as Vector3).x, (v as Vector3).y, (v as Vector3).z)
	if v is Vector4:
		return Color((v as Vector4).x, (v as Vector4).y, (v as Vector4).z)
	return Color(0.5, 0.5, 0.5)


## A warning when the material lives outside the asset's folder (a kit / palette material shared by other assets).
static func _shared_note(ctx: ArtLabRunner, info: Dictionary) -> String:
	var p: String = info.get("path", "")
	if p == "" or "::" in p:
		return "built in code or embedded: change it where the model script creates it"
	if not p.begins_with(ctx.scene_path.get_base_dir()):
		return "shared material (%s): give %s its own copy first, other assets use it too" % [p, ctx.asset]
	return ""


# ================================================================ glow (R5)

## Brings the glow-point count into the tier range by changing emission energies, grouped by emissive material:
## too many -> dim the materials with the most points to GLOW_UNDER x the bloom level (brightest point first kept);
## too few -> raise the brightest soft glows to GLOW_OVER x the level. Peaks come from the capture_40 hot renders.
static func glow_fix(ctx: ArtLabRunner, c: Dictionary, rules: Dictionary) -> Dictionary:
	var cap: Dictionary = ctx.m.get("fix40", {})
	if cap.is_empty():
		ctx.rep.notes.append("fix recipes: glow not computed (no 40 m capture: headless, focus or fixes=0)")
		return {}
	var gr: Vector2i = rules.get("glow", Vector2i(1, 3))
	var roi: Rect2i = cap["roi"]
	var mask: ArtLabImage.Mask = cap["mask"]
	var level: float = cap["level"]
	var groi := ArtLabImage.clamp_rect(roi, 10, ArtLabStage.W, ArtLabStage.H)
	var dx := groi.position.x - roi.position.x
	var dy := groi.position.y - roi.position.y
	var surf_px := maxi(int(float(mask.count) * 0.15), 30)
	var hot: Image = cap["hot"]
	var hot8: Image = cap["hot8"]
	var spots: Array[Dictionary] = []
	# points over the bloom level: R5's own clustering (0.97 of the hot frame); soft glows: 0.2-0.97, apart from them
	for pass_i: int in 2:
		var thr := 0.97 if pass_i == 0 else 0.2
		for cl: Dictionary in ArtLabImage.glow_clusters(hot, groi, thr, 3, 2, true):
			var mx := int(round(float(cl["x"]))) + dx
			var my := int(round(float(cl["y"]))) + dy
			if int(cl["area"]) > surf_px:
				continue   # a glowing surface, not a point
			if int(cl["area"]) <= 4 and ArtLabImage.near_edge(mask, mx, my, 2):
				continue   # painted rim speck
			var fx := roi.position.x + mx
			var fy := roi.position.y + my
			var peak := float(cl["peak"])
			if pass_i == 1 and peak >= 0.97:
				continue   # holds a point already counted
			var above := pass_i == 0
			if above:
				peak = _peak_around(hot8, fx, fy, int(ceil(sqrt(float(cl["area"])))) + 2) * HOT_RANGE
			spots.append({"x": fx, "y": fy, "peak": peak, "above": above, "area": int(cl["area"]),
				"part": _part_at(cap["boxes"], Vector2i(fx, fy))})
	var n_meas := 0
	for s: Dictionary in spots:
		if bool(s["above"]):
			n_meas += 1
	# the check's own count (median of 3 idle phases) decides; this capture is one phase
	var n_now := n_meas
	var rx := RegEx.create_from_string("^(\\d+) point")
	var mt := rx.search(String(c["value"]))
	if mt != null:
		n_now = int(mt.get_string(1))
	# group by emissive material of the part
	var groups := {}
	for s2: Dictionary in spots:
		var gi := ctx.target.get_node_or_null(NodePath(String(s2["part"]))) as GeometryInstance3D
		var info := {}
		if gi:
			info = _emissive_info(gi)
		var key: String = String(info.get("label", "part " + String(s2["part"])))
		if not groups.has(key):
			groups[key] = {"info": info, "parts": [], "spots": []}
		(groups[key]["spots"] as Array).append(s2)
		if not String(s2["part"]) in (groups[key]["parts"] as Array):
			(groups[key]["parts"] as Array).append(String(s2["part"]))
	var changes: Array = []
	var words: Array[String] = []
	var n_after := n_now
	var target_n := n_now
	if n_now > gr.y:
		target_n = gr.y
		var gl: Array = groups.values()
		gl.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _n_above(a) > _n_above(b))
		for g: Dictionary in gl:
			if n_after <= gr.y:
				break
			var k := _n_above(g)
			if k == 0 or n_after - k < gr.x:
				continue
			var pk := _max_peak(g, true)
			var ch := _energy_change(g, pk, GLOW_UNDER, level, "dim under the bloom level: %d point(s), peak %s x the level%s" % [k, ctx.fmt(pk, 2), " (>= %s, clipped)" % ctx.fmt(HOT_RANGE, 0) if pk >= HOT_RANGE * 0.99 else ""])
			changes.append(ch)
			words.append("%s %s" % [ch["material"], ch["words"]])
			n_after -= k
	elif n_now < gr.x:
		target_n = gr.x
		var soft: Array = []
		for g2: Dictionary in groups.values():
			if _n_above(g2) == 0 and _max_peak(g2, false) >= 0.15:
				soft.append(g2)
		soft.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _max_peak(a, false) > _max_peak(b, false))
		for g3: Dictionary in soft:
			if n_after >= gr.x:
				break
			var pk2 := _max_peak(g3, false)
			var ch2 := _energy_change(g3, pk2, GLOW_OVER, level, "raise over the bloom level: brightest soft glow %s x the level" % ctx.fmt(pk2, 2))
			changes.append(ch2)
			words.append("%s %s" % [ch2["material"], ch2["words"]])
			n_after += 1
		if n_after < gr.x:
			words.append("add %d glow point(s) high on the body (eyes / rune / weapon tip): an unshaded kit glow with energy >= %s or emission x colour >= %s x the bloom level %s" % [gr.x - n_after, ctx.fmt(GLOW_OVER * level / 0.9, 1), ctx.fmt(GLOW_OVER, 1), ctx.fmt(level, 2)])
			n_after = gr.x
	else:
		ctx.rep.notes.append("fix recipes: R5 count %d is inside %d-%d (a WARN from surfaces / phases): generic recipe" % [n_now, gr.x, gr.y])
		return {}
	var f := {"check": "R5", "status": String(c["status"]), "title": "Glow points at the bloom level", "computed": not changes.is_empty(),
		"measured": {"points": n_now, "points_this_phase": n_meas, "spots": _spot_list(spots), "value": String(c["value"])},
		"wanted": {"points": "%d-%d above the bloom level %s" % [gr.x, gr.y, ctx.fmt(level, 2)]},
		"changes": changes, "predicted": {"points": n_after}}
	f["text"] = "Glow points %d -> %d (want %d-%d): %s" % [n_now, n_after, gr.x, gr.y, "; ".join(words)]
	return f


static func _n_above(g: Dictionary) -> int:
	var n := 0
	for s: Dictionary in g["spots"]:
		if bool(s["above"]):
			n += 1
	return n


static func _max_peak(g: Dictionary, above: bool) -> float:
	var p := 0.0
	for s: Dictionary in g["spots"]:
		if bool(s["above"]) == above:
			p = maxf(p, float(s["peak"]))
	return p


## One energy change that moves the group's peak from `pk` to `want` (both in multiples of the bloom level). Kit glow
## shaders (rune / unit / keep glow: value = c x 0.4 + c x energy x pulse x boost) keep a floor that does not scale, so
## only the part above it moves; without an energy knob the emission colour itself is scaled.
static func _energy_change(g: Dictionary, pk: float, want: float, level: float, why: String) -> Dictionary:
	var info: Dictionary = g["info"]
	var parts: Array[String] = []
	for p: String in (g["parts"] as Array).slice(0, 4):
		parts.append(p.get_file())
	var ch := {"node": ", ".join(PackedStringArray((g["parts"] as Array).slice(0, 6))), "material": String(info.get("label", "?")),
		"material_path": String(info.get("path", "")), "param": String(info.get("energy_param", "")), "why": why,
		"peak_x_bloom": snappedf(pk, 0.01), "want_x_bloom": want}
	var floor_rel := 0.0
	if info.has("energy_floor") and info.has("glow_color"):
		var gl := srgb_to_lin(info["glow_color"])
		floor_rel = float(info["energy_floor"]) * maxf(gl.x, maxf(gl.y, gl.z)) / maxf(level, 0.01)
	var fac := (want - floor_rel) / maxf(pk - floor_rel, 0.01)
	ch["factor"] = snappedf(fac, 0.001)
	var on := " on %s" % ", ".join(parts) if not parts.is_empty() else ""
	if want <= floor_rel:
		ch["words"] = "its floor alone is %s x the bloom level: darken its glow colour by x%s%s (%s)" % [ctx_fmt(floor_rel), ctx_fmt(want / maxf(floor_rel, 0.01)), on, why]
	elif info.has("energy"):
		var e0: float = info["energy"]
		var e1 := maxf(e0 * fac, 0.0)
		ch["from"] = snappedf(e0, 0.001)
		ch["to"] = snappedf(e1, 0.001)
		ch["words"] = "%s %s -> %s%s (%s)" % [String(ch["param"]).trim_prefix("shader_parameter/"), ctx_fmt(e0), ctx_fmt(e1), on, why]
	elif info.has("glow_color"):
		var c0: Color = info["glow_color"]
		var c1 := lin_to_srgb(srgb_to_lin(c0) * fac)
		ch["param"] = "glow / emission colour"
		ch["from"] = "#" + c0.to_html(false)
		ch["to"] = "#" + c1.to_html(false)
		ch["words"] = "glow colour #%s -> #%s (x%s linear)%s (%s)" % [c0.to_html(false), c1.to_html(false), ctx_fmt(fac), on, why]
	else:
		ch["words"] = "emission x %s%s (%s; no energy / glow-colour parameter found)" % [ctx_fmt(fac), on, why]
	return ch


static func ctx_fmt(v: float) -> String:
	return String.num(v, 2)


static func _peak_around(img: Image, x: int, y: int, r: int) -> float:
	var p := 0.0
	for yy: int in range(maxi(y - r, 0), mini(y + r + 1, img.get_height())):
		for xx: int in range(maxi(x - r, 0), mini(x + r + 1, img.get_width())):
			var c := img.get_pixel(xx, yy)
			p = maxf(p, maxf(c.r, maxf(c.g, c.b)))
	return p


## The smallest projected part box holding a frame pixel (as glow_report does): the node path, or "?".
static func _part_at(boxes: Array, p: Vector2i) -> String:
	var best := "?"
	var area := INF
	for b: Dictionary in boxes:
		var r: Rect2i = b["rect"]
		if r.has_point(p) and float(r.get_area()) < area:
			area = float(r.get_area())
			best = b["path"]
	return best


static func _emissive_info(gi: GeometryInstance3D) -> Dictionary:
	var first := {}
	var n := 0
	if gi is MeshInstance3D and (gi as MeshInstance3D).mesh:
		n = (gi as MeshInstance3D).mesh.get_surface_count()
	elif gi is MultiMeshInstance3D and (gi as MultiMeshInstance3D).multimesh and (gi as MultiMeshInstance3D).multimesh.mesh:
		n = (gi as MultiMeshInstance3D).multimesh.mesh.get_surface_count()
	for s: int in n:
		var m := surface_material(gi, s)
		if m == null:
			continue
		var inf := material_info(m)
		if bool(inf.get("glows", false)) or bool(inf.get("emissive", false)):
			if inf.has("energy_param") and bool(inf.get("emissive", false)):
				return inf   # a glow material with an energy knob beats a painted body that can also emit
			if first.is_empty() or (inf.has("energy_param") and not first.has("energy_param")):
				first = inf
	return first


static func _spot_list(spots: Array[Dictionary]) -> Array:
	var out: Array = []
	for s: Dictionary in spots:
		out.append({"part": s["part"], "peak_x_bloom": snappedf(float(s["peak"]), 0.01), "above": s["above"], "px": s["area"]})
	return out


# ================================================================ budgets

## B1 / B2: which meshes to merge. Meshes under the same pivot with the same materials are merge candidates (the kit
## merge stops at keep_separate or a different material); the same mesh drawn 3+ times -> one MultiMesh; a pivot with
## several materials -> fold them into one palette material so the kit can merge it.
static func merge_fix(ctx: ArtLabRunner, c: Dictionary) -> Dictionary:
	var cen: Dictionary = ctx.m.get("census", {})
	if cen.is_empty():
		return {}
	var key := "meshes" if String(c["id"]) == "B1" else "draw"
	var lim := ArtLabBudgets.limit(ctx.rep.budget_row, key)
	if lim.is_empty():
		return {}
	var now := int(cen["meshes"]) + int(cen["multimeshes"]) if key == "meshes" else int(cen["draw"])
	var over := now - int(lim["limit"])
	if over <= 0:
		return {}
	var by_pivot := {}
	var by_mesh := {}
	for me: Dictionary in cen["mesh_list"]:
		var path := String(me["name"])
		var gi := ctx.target.get_node_or_null(NodePath(path)) as GeometryInstance3D
		var mats: Array[String] = []
		var sep := false
		if gi:
			sep = gi.has_meta(&"keep_separate")
			for m: Material in ArtLabCensus.materials_of(gi):
				mats.append(material_info(m)["label"])
			if gi is MeshInstance3D and (gi as MeshInstance3D).mesh:
				var mid := (gi as MeshInstance3D).mesh.get_instance_id()
				if not by_mesh.has(mid):
					by_mesh[mid] = []
				(by_mesh[mid] as Array).append(path)
		mats.sort()
		var piv := path.get_base_dir()
		if not by_pivot.has(piv):
			by_pivot[piv] = []
		(by_pivot[piv] as Array).append({"path": path, "mats": ",".join(mats), "sep": sep})
	var groups: Array = []   # {what, nodes, saves, words}
	for mid2: int in by_mesh:
		var ps: Array = by_mesh[mid2]
		if ps.size() >= 3:
			groups.append({"action": "multimesh", "nodes": ps, "saves": ps.size() - 1,
				"words": "draw %s (%d copies of one mesh) as one MultiMesh" % [_pattern(ps), ps.size()]})
	for piv2: String in by_pivot:
		var list: Array = by_pivot[piv2]
		if list.size() < 2:
			continue
		var by_mat := {}
		for e: Dictionary in list:
			if bool(e["sep"]):
				continue
			if not by_mat.has(e["mats"]):
				by_mat[e["mats"]] = []
			(by_mat[e["mats"]] as Array).append(e["path"])
		for mk: String in by_mat:
			var ps2: Array = by_mat[mk]
			if ps2.size() >= 2:
				groups.append({"action": "merge", "nodes": ps2, "saves": ps2.size() - 1,
					"words": "merge %s %d meshes -> 1 (same pivot `%s`, same material %s)" % [_pattern(ps2), ps2.size(), piv2.get_file() if piv2 != "" else "(root)", mk]})
		if by_mat.size() >= 2:
			var mats2: Array[String] = []
			var nodes2: Array = []
			var n2 := 0
			for mk2: String in by_mat:
				mats2.append(mk2)
				nodes2.append_array(by_mat[mk2])
				n2 += 1
			groups.append({"action": "unify_materials", "nodes": nodes2, "saves": n2 - 1,
				"words": "pivot `%s` draws %d meshes in %d materials (%s): put them on one palette material so the kit merges them" % [piv2.get_file() if piv2 != "" else "(root)", nodes2.size(), n2, "; ".join(mats2)]})
		var seps: Array = []
		for e2: Dictionary in list:
			if bool(e2["sep"]):
				seps.append(e2["path"])
		if seps.size() >= 2:
			groups.append({"action": "drop_keep_separate", "nodes": seps, "saves": seps.size() - 1,
				"words": "%s are keep_separate under `%s`: keep only the animated / toggled one separate" % [_pattern(seps), piv2.get_file()]})
	var order := {"multimesh": 0, "merge": 1, "drop_keep_separate": 2, "unify_materials": 3}
	groups.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(order[a["action"]]) != int(order[b["action"]]):
			return int(order[a["action"]]) < int(order[b["action"]])
		return int(a["saves"]) > int(b["saves"]))
	var picked: Array = []
	var saved := 0
	for g: Dictionary in groups:
		if saved >= over:
			break
		picked.append({"action": g["action"], "node": ", ".join(PackedStringArray((g["nodes"] as Array).slice(0, 8))),
			"saves": g["saves"], "words": g["words"]})
		saved += int(g["saves"])
	var words: Array[String] = []
	for p: Dictionary in picked:
		words.append(String(p["words"]))
	var f := {"check": String(c["id"]), "status": String(c["status"]), "title": String(c["name"]), "computed": not picked.is_empty(),
		"measured": {key: now}, "wanted": {key: "<= %d" % int(lim["limit"])}, "changes": picked,
		"predicted": {key: now - mini(saved, now)}}
	f["text"] = "%s %d -> %d (want <= %d): %s" % [c["id"], now, now - mini(saved, now), int(lim["limit"]),
		"; ".join(words) if not words.is_empty() else "no merge group found (every mesh has its own pivot and material): " + String(c["hint"])]
	return f


## "Strap*" for Strap1 / Strap2..., else the first names.
static func _pattern(paths: Array) -> String:
	var names: Array[String] = []
	for p: String in paths:
		names.append(p.get_file())
	var pre: String = names[0]
	for n: String in names:
		while pre != "" and not n.begins_with(pre):
			pre = pre.left(pre.length() - 1)
	pre = pre.rstrip("_0123456789")
	if pre.length() >= 3:
		return "`%s*`" % pre
	return "`" + "`, `".join(PackedStringArray(names.slice(0, 4))) + "`" + (" ..." if names.size() > 4 else "")


## B4 / B4t: thin the biggest meshes (at most by half each) until the total fits the budget.
static func verts_fix(ctx: ArtLabRunner, c: Dictionary) -> Dictionary:
	var cen: Dictionary = ctx.m.get("census", {})
	var key := "verts" if String(c["id"]) == "B4" else "tris"
	var lim := ArtLabBudgets.limit(ctx.rep.budget_row, key)
	if cen.is_empty() or lim.is_empty():
		return {}
	var now := int(cen[key])
	var over := now - int(lim["limit"])
	if over <= 0:
		return {}
	var target := over * 1.05
	var cut := 0
	var changes: Array = []
	for me: Dictionary in cen["mesh_list"]:
		if float(cut) >= target:
			break
		var v := int(me[key])
		var take := mini(v / 2, int(ceil(target)) - cut)
		if take < 20:
			continue
		cut += take
		changes.append({"node": String(me["name"]), "from": v, "to": v - take,
			"words": "`%s` %d -> %d %s" % [String(me["name"]).get_file(), v, v - take, key]})
	var words: Array[String] = []
	for ch: Dictionary in changes:
		words.append(String(ch["words"]))
	var f := {"check": String(c["id"]), "status": String(c["status"]), "title": String(c["name"]), "computed": true,
		"measured": {key: now}, "wanted": {key: "<= %d" % int(lim["limit"])}, "changes": changes, "predicted": {key: now - cut}}
	f["text"] = "%s %d -> %d (want <= %d): %s (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces)" % [c["id"], now, now - cut, int(lim["limit"]), "; ".join(words)]
	return f


## B7: stop the smallest casters from casting shadows (the 3-4 biggest masses keep them).
static func casters_fix(ctx: ArtLabRunner, c: Dictionary) -> Dictionary:
	var lim := ArtLabBudgets.limit(ctx.rep.budget_row, "casters")
	if lim.is_empty():
		return {}
	var casters: Array = []
	for gi: GeometryInstance3D in ArtLabCensus.geometry(ctx.target):
		if not gi.is_visible_in_tree() or ArtLabCensus.is_particles(gi) or ArtLabCensus.is_flat_decal(gi, ctx.ground_y):
			continue
		if gi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			continue
		var box := gi.global_transform * gi.get_aabb()
		casters.append({"path": String(ctx.target.get_path_to(gi)), "vol": box.size.x * box.size.y * box.size.z})
	var over := casters.size() - int(lim["limit"])
	if over <= 0:
		return {}
	casters.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["vol"]) < float(b["vol"]))
	var changes: Array = []
	var names: Array[String] = []
	for i: int in over:
		changes.append({"node": casters[i]["path"], "param": "cast_shadow", "from": "on", "to": "SHADOW_CASTING_SETTING_OFF",
			"volume_m3": snappedf(float(casters[i]["vol"]), 0.001)})
		names.append("`%s`" % String(casters[i]["path"]).get_file())
	var f := {"check": "B7", "status": String(c["status"]), "title": String(c["name"]), "computed": true,
		"measured": {"casters": casters.size()}, "wanted": {"casters": "<= %d" % int(lim["limit"])}, "changes": changes,
		"predicted": {"casters": casters.size() - over}}
	f["text"] = "B7 %d -> %d casters: cast_shadow off on the %d smallest: %s" % [casters.size(), casters.size() - over, over, ", ".join(names)]
	return f


## B8: fold the closest pairs of look-alike materials (albedo CIE76 dE, same glow kind) until the count fits.
static func materials_fix(ctx: ArtLabRunner, c: Dictionary) -> Dictionary:
	var lim := ArtLabBudgets.limit(ctx.rep.budget_row, "materials")
	if lim.is_empty():
		return {}
	var mats := {}
	for gi: GeometryInstance3D in ArtLabCensus.geometry(ctx.target):
		for m: Material in ArtLabCensus.materials_of(gi):
			if m is ParticleProcessMaterial:
				continue
			mats[m.get_instance_id()] = m
	var over := mats.size() - int(lim["limit"])
	if over <= 0:
		return {}
	var infos: Array[Dictionary] = []
	for id: int in mats:
		var inf := material_info(mats[id])
		if inf.has("color") and not bool(inf.get("team", false)):
			infos.append(inf)
	var pairs: Array = []
	for i: int in infos.size():
		for j: int in range(i + 1, infos.size()):
			if bool(infos[i].get("emissive", false)) != bool(infos[j].get("emissive", false)):
				continue
			if String(infos[i].get("shader", infos[i]["class"])) != String(infos[j].get("shader", infos[j]["class"])):
				continue
			var de := lin_to_lab(srgb_to_lin(infos[i]["color"])).distance_to(lin_to_lab(srgb_to_lin(infos[j]["color"])))
			pairs.append([de, i, j])
	pairs.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var gone := {}
	var changes: Array = []
	var words: Array[String] = []
	for p: Array in pairs:
		if changes.size() >= over:
			break
		var i2: int = p[1]
		var j2: int = p[2]
		if gone.has(i2) or gone.has(j2):
			continue
		gone[j2] = true
		changes.append({"material": infos[j2]["label"], "material_path": infos[j2]["path"], "to": infos[i2]["label"],
			"to_path": infos[i2]["path"], "albedo_dE": snappedf(float(p[0]), 0.1)})
		words.append("`%s` -> `%s` (dE %s)" % [infos[j2]["label"], infos[i2]["label"], ctx.fmt(float(p[0]))])
	var f := {"check": "B8", "status": String(c["status"]), "title": String(c["name"]), "computed": not changes.is_empty(),
		"measured": {"materials": mats.size()}, "wanted": {"materials": "<= %d" % int(lim["limit"])}, "changes": changes,
		"predicted": {"materials": mats.size() - changes.size()}}
	f["text"] = "B8 %d -> %d materials: use one material for look-alike pairs: %s" % [mats.size(), mats.size() - changes.size(),
		", ".join(words) if not words.is_empty() else "(no look-alike pair of the same shader) " + String(c["hint"])]
	return f


# ================================================================ geometry reads

static func area_fix(ctx: ArtLabRunner, c: Dictionary, rules: Dictionary) -> Dictionary:
	var rx := RegEx.create_from_string("^(\\d+) px")
	var mt := rx.search(String(c["value"]))
	if mt == null:
		return {}
	var area := float(mt.get_string(1))
	var aw: float = float(rules.get("area_warn", 120))
	var sc := sqrt(aw * 1.15 / maxf(area, 1.0))
	var f := {"check": "R1", "status": String(c["status"]), "title": String(c["name"]), "computed": true,
		"measured": {"area_px": int(area)}, "wanted": {"area_px": ">= %d" % int(aw)},
		"changes": [{"node": "(model root) or its key masses", "param": "scale", "from": 1.0, "to": snappedf(sc, 0.01)}],
		"predicted": {"area_px": int(area * sc * sc)}}
	f["text"] = "R1 %d -> ~%d px: grow the 40 m read x%s (area goes with the square: scale the key masses / body %d %%)" % [int(area), int(area * sc * sc), ctx.fmt(sc, 2), int(round((sc - 1.0) * 100.0))]
	return f


static func feet_fix(ctx: ArtLabRunner, c: Dictionary) -> Dictionary:
	var vb: Dictionary = ctx.m.get("bounds", {})
	if vb.is_empty():
		return {}
	var lo := float((vb["min"] as Vector3).y)
	var dy := -lo if lo > 0.05 else (-0.08 - lo if lo < -0.08 else 0.0)
	if is_zero_approx(dy):
		return {}
	var f := {"check": "R9", "status": String(c["status"]), "title": String(c["name"]), "computed": true,
		"measured": {"lowest_m": snappedf(lo, 0.001)}, "wanted": {"lowest_m": "-0.08 .. +0.05"},
		"changes": [{"node": "Root", "param": "position.y", "delta": snappedf(dy, 0.001)}], "predicted": {"lowest_m": snappedf(lo + dy, 0.001)}}
	f["text"] = "R9: move `Root` %s m %s (lowest point %s -> %s m)" % [ctx.fmt(absf(dy), 3), "down" if dy < 0.0 else "up", ctx.fmt(lo, 3), ctx.fmt(lo + dy, 3)]
	return f


static func radius_fix(ctx: ArtLabRunner, c: Dictionary) -> Dictionary:
	var vb: Dictionary = ctx.m.get("bounds", {})
	if vb.is_empty():
		return {}
	var tlo: Vector3 = vb.get("min_thick", vb["min"])
	var thi: Vector3 = vb.get("max_thick", vb["max"])
	var ext_x := maxf(absf(tlo.x), absf(thi.x))
	var ext_z := maxf(absf(tlo.z), absf(thi.z))
	var quad := bool(ctx.target.get(&"is_quadruped")) if ctx.target.get(&"is_quadruped") != null else false
	var kz := 2.4 if quad or ctx.kind != &"unit" else 1.4
	var need := maxf(ext_x / 1.4, ext_z / kz) / 1.25
	var f := {"check": "R10", "status": String(c["status"]), "title": String(c["name"]), "computed": true,
		"measured": {"x_m": snappedf(ext_x, 0.01), "z_m": snappedf(ext_z, 0.01), "radius": ctx.radius},
		"wanted": {"x_m": "<= %s" % ctx.fmt(ctx.radius * 1.4 * 1.25, 2), "z_m": "<= %s" % ctx.fmt(ctx.radius * kz * 1.25, 2)},
		"changes": [{"node": String(ctx.unit.get("file", "UnitType")), "param": "radius", "from": ctx.radius, "to": snappedf(need, 0.01)},
			{"node": "widest parts", "param": "pull in", "x_m": snappedf(ctx.radius * 1.4 * 1.25, 2), "z_m": snappedf(ctx.radius * kz * 1.25, 2)}],
		"predicted": {}}
	f["text"] = "R10: raise UnitType.radius %s -> %s, or pull the widest parts in to x <= %s / z <= %s m" % [ctx.fmt(ctx.radius, 2), ctx.fmt(need, 2), ctx.fmt(ctx.radius * 1.4 * 1.25, 2), ctx.fmt(ctx.radius * kz * 1.25, 2)]
	return f


## R8: body_height to the measured head top (the HP bar hangs at body_height + 0.5), in the scene and its UnitType.
static func head_fix(ctx: ArtLabRunner, c: Dictionary) -> Dictionary:
	var rx := RegEx.create_from_string("head top ([0-9.]+) m / body_height ([0-9.]+)")
	var mt := rx.search(String(c["value"]))
	if mt == null:
		return {}
	var top := float(mt.get_string(1))
	var bh := float(mt.get_string(2))
	var rules := ArtLabBudgets.read_rules(ctx.kind, ctx.tier)
	var hmax: float = rules.get("head_max", 1.25)
	var nodes: Array[String] = [ctx.scene_path + " (root)"]
	if ctx.unit.has("file"):
		nodes.append(String(ctx.unit["file"]))
	var f := {"check": "R8", "status": String(c["status"]), "title": String(c["name"]), "computed": true,
		"measured": {"head_top_m": top, "body_height": bh, "ratio": snappedf(top / maxf(bh, 0.01), 0.01)},
		"wanted": {"ratio": "0.75-%s" % ctx.fmt(hmax, 2)},
		"changes": [{"node": ", ".join(nodes), "param": "body_height", "from": bh, "to": snappedf(top, 0.01)}],
		"predicted": {"ratio": 1.0}}
	f["text"] = "R8: body_height %s -> %s in %s (the head top; x%s now), or lower the head / crest %s m" % [ctx.fmt(bh, 2), ctx.fmt(top, 2),
		" and ".join(nodes), ctx.fmt(top / maxf(bh, 0.01), 2), ctx.fmt(maxf(top - bh * hmax, 0.0), 2)]
	return f


## Any other FAIL / WARN: the check's own measured value, rule and hint.
static func generic_fix(c: Dictionary) -> Dictionary:
	var txt := String(c.get("improve", ""))
	if txt == "":
		txt = String(c.get("hint", ""))
	if txt == "":
		txt = "meet the rule: " + String(c["rule"])
	return {"check": String(c["id"]), "status": String(c["status"]), "title": String(c["name"]), "computed": false,
		"measured": {"value": String(c["value"])}, "wanted": {"rule": String(c["rule"])}, "changes": [], "predicted": {},
		"text": "%s %s: %s" % [c["id"], c["name"], txt]}


# ================================================================ colour maths (sRGB <-> linear <-> CIE L*a*b*, D65)

static func srgb_to_lin(c: Color) -> Vector3:
	return Vector3(_s2l(c.r), _s2l(c.g), _s2l(c.b))


static func lin_to_srgb(v: Vector3) -> Color:
	return Color(_l2s(v.x), _l2s(v.y), _l2s(v.z))


static func _s2l(c: float) -> float:
	return c / 12.92 if c <= 0.04045 else pow((c + 0.055) / 1.055, 2.4)


static func _l2s(c: float) -> float:
	var x := clampf(c, 0.0, 1.0)
	return x * 12.92 if x <= 0.0031308 else 1.055 * pow(x, 1.0 / 2.4) - 0.055


## Linear RGB -> L*a*b* (same matrix as ArtLabImage.lab).
static func lin_to_lab(v: Vector3) -> Vector3:
	var x := (0.4124 * v.x + 0.3576 * v.y + 0.1805 * v.z) / 0.95047
	var y := 0.2126 * v.x + 0.7152 * v.y + 0.0722 * v.z
	var z := (0.0193 * v.x + 0.1192 * v.y + 0.9505 * v.z) / 1.08883
	var fx := _f(x)
	var fy := _f(y)
	var fz := _f(z)
	return Vector3(116.0 * fy - 16.0, 500.0 * (fx - fy), 200.0 * (fy - fz))


static func _f(t: float) -> float:
	return pow(t, 1.0 / 3.0) if t > 0.008856 else 7.787 * t + 16.0 / 116.0


static func _finv(t: float) -> float:
	var t3 := t * t * t
	return t3 if t3 > 0.008856 else (t - 16.0 / 116.0) / 7.787


static func lab_to_lin(l: Vector3) -> Vector3:
	var fy := (l.x + 16.0) / 116.0
	var fx := fy + l.y / 500.0
	var fz := fy - l.z / 200.0
	var x := _finv(fx) * 0.95047
	var y := _finv(fy)
	var z := _finv(fz) * 1.08883
	return Vector3(3.2406 * x - 1.5372 * y - 0.4986 * z, -0.9689 * x + 1.8758 * y + 0.0415 * z,
		0.0557 * x - 0.2040 * y + 1.0570 * z).max(Vector3.ZERO)


static func _v(v: Vector3) -> Array:
	return [snappedf(v.x, 0.1), snappedf(v.y, 0.1), snappedf(v.z, 0.1)]


## JSON-safe copy (Vector3 / Color / StringName / Rect2i as plain values).
static func _jsonable(v: Variant) -> Variant:
	if v is Dictionary:
		var d := {}
		for k: Variant in v:
			d[str(k)] = _jsonable(v[k])
		return d
	if v is Array:
		var a: Array = []
		for e: Variant in v:
			a.append(_jsonable(e))
		return a
	if v is Vector3:
		return _v(v)
	if v is Color:
		return "#" + (v as Color).to_html(false)
	if v is StringName or v is NodePath or v is Rect2i:
		return str(v)
	if v is float:
		return snappedf(v, 0.001)
	return v
