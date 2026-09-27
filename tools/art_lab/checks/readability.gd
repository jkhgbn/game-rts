class_name ArtLabCheckRead
extends RefCounted
## Art Lab checks (docs/plan/art-lab.md section 3): readability at 40 m. R1 area, R2 distinct from references (+ R2r),
## R3 / R3t / R4 / R4k contrast, R5 glow points, R6 team colour, R7 HP bar, R8 / R8w head / tall parts, R9 feet,
## R10 footprint. Numbers come from lab_budgets.gd (READ / GLOW_TIER / TIER_READ). A3 (animation.gd) and the polish
## checks (polish.gd) are called from this pass at their place (same frozen pose, same mask).

const OTHER_GROUNDS: Array[StringName] = [&"meadow", &"heath", &"old_wood", &"riverbank", &"snow", &"ash", &"sand", &"marsh"]

## Art Lab v3 1.D checks (R11 / R5w / R5c / R6cb / R12 / S1, flyer wing-phase match for R2) and their thresholds
## live in checks/read_v3.gd (ArtLabCheckReadV3); this pass calls them at their place.


static func check_geometry(ctx: ArtLabRunner) -> void:
	var vb: Dictionary = ctx.m.get("bounds", {})
	if vb.is_empty():
		return
	var lo: Vector3 = vb["min"]
	var hi: Vector3 = vb["max"]
	var rules := ArtLabBudgets.read_rules(ctx.kind, ctx.tier)
	# R9 feet on the ground
	var feet: StringName = rules.get("feet", &"ground")
	if ctx.flyer:
		ctx.rep.add("R9", "read", "Feet on the ground", "INFO", "flyer: lowest point %s m (hovers)" % ctx.fmt(lo.y, 2),
			"flyers hover (FlyerModel fly_height)")
	elif feet == &"base":
		var st := "PASS" if lo.y <= 0.05 else "FAIL"
		if lo.y < -1.0 and ctx.kind == &"building":
			st = "WARN"   # landmarks may be half buried on purpose (fallen colossus, stumps)
		ctx.rep.add("R9", "read", "Ground contact", st, "lowest point %s m" % ctx.fmt(lo.y, 2),
			"touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5)",
			"Sink the plinth / base 0.05-0.3 m into the ground and add the contact decal", 1.0 if st == "PASS" else 0.2)
	else:
		var st2 := "PASS"
		var hint := ""
		if lo.y > 0.15:
			st2 = "FAIL"
			hint = "Lower the feet: the model floats %s m above the ground" % ctx.fmt(lo.y, 2)
		elif lo.y > 0.05:
			st2 = "WARN"
			hint = "Lower the feet %s m (they hover)" % ctx.fmt(lo.y, 2)
		elif lo.y < -0.08:
			st2 = "WARN"
			hint = "A part sits %s m below y 0 (art-units 1.6: nothing below the ground but the blob)" % ctx.fmt(-lo.y, 2)
		ctx.rep.add("R9", "read", "Feet on the ground", st2, "lowest point %s m" % ctx.fmt(lo.y, 3),
			"-0.08 .. +0.05 m (art-units 1.6)", hint, 1.0 if st2 == "PASS" else (0.5 if st2 == "WARN" else 0.0), hint)
	# R8 head height vs body_height, top parts narrower than 0.35 m (wizards / champions: identity-crest tolerance)
	if bool(rules.get("head", false)) and ctx.body_height > 0.0:
		var head_max: float = rules.get("head_max", 1.25)
		var top_w: float = rules.get("top_width", 0.35)
		var crest := bool(rules.get("crest", false))
		var head := ctx.target.get_node_or_null("Root/Chest/Head") as Node3D
		if head:
			var hb := ArtLabCensus.vertex_bounds(head, ctx.holder.global_transform, ctx.ground_y)
			var top: float = (hb["max"] as Vector3).y
			var ratio := top / ctx.body_height
			var st3 := "PASS" if ratio >= 0.75 and ratio <= head_max else "WARN"
			ctx.rep.add("R8", "read", "Head height vs body_height", st3,
				"head top %s m / body_height %s (x%s)" % [ctx.fmt(top, 2), ctx.fmt(ctx.body_height, 2), ctx.fmt(ratio, 2)],
				"x0.75-%s (art-units 1.1: the HP bar hangs at body_height + 0.5%s)" % [ctx.fmt(head_max, 2), "; identity crest allowed for %s" % ctx.tier if crest else ""],
				"Set body_height (UnitType + scene) to the head top, or rescale the body", 1.0 - clampf(absf(clampf(ratio, 0.75, 1.0) - ratio) * 2.0, 0.0, 1.0))
		var tb := ArtLabCensus.vertex_bounds(ctx.target, ctx.holder.global_transform, ctx.ground_y, ctx.body_height + 0.4)
		var wide: Array[String] = []
		var crests: Array[String] = []
		for p: Dictionary in tb["top_parts"]:
			var wtxt := "%s %s m" % [String(p["name"]).get_file(), ctx.fmt(float(p["width"]), 2)]
			if float(p["width"]) > top_w:
				wide.append(wtxt)
			elif float(p["width"]) > 0.35:
				crests.append(wtxt)
		if not wide.is_empty():
			ctx.rep.add("R8w", "read", "Parts above body_height + 0.4", "WARN", ", ".join(wide),
				"narrower than %s m (art-units 1.1: the HP bar stays readable%s)" % [ctx.fmt(top_w, 2), "; crest tolerance" if crest else ""],
				"Narrow the hat / horn / staff head above the bar line", 0.5, "Narrow %s so the HP bar reads over the head" % ", ".join(wide))
		elif not crests.is_empty():
			ctx.rep.add("R8w", "read", "Parts above body_height + 0.4", "INFO", "identity crest: " + ", ".join(crests),
				"%s tier: a crest up to %s m wide is part of the identity (the HP bar sits on it)" % [ctx.tier, ctx.fmt(top_w, 2)])
	# R10 footprint (thin "line" parts under 8 cm, e.g. spear shafts / staffs / bow strings, do not count)
	if ctx.kind in [&"unit", &"mount", &"beast", &"critter"]:
		var tlo: Vector3 = vb.get("min_thick", lo)
		var thi: Vector3 = vb.get("max_thick", hi)
		var ext_x := maxf(absf(tlo.x), absf(thi.x))
		var ext_z := maxf(absf(tlo.z), absf(thi.z))
		var full_x := maxf(absf(lo.x), absf(hi.x))
		var full_z := maxf(absf(lo.z), absf(hi.z))
		var line_parts: Array = vb.get("line_parts", [])
		var quad := bool(ctx.target.get(&"is_quadruped")) if ctx.target.get(&"is_quadruped") != null else false
		var lim_x := ctx.radius * 1.4
		var lim_z := ctx.radius * (2.4 if quad or ctx.kind != &"unit" else 1.4)
		var over := maxf(ext_x / lim_x, ext_z / lim_z)
		var st4 := "PASS" if over <= 1.25 else "WARN"   # 25 % slack: a tail tip or a swung weapon is fine
		if not ctx.unit.has("radius"):
			st4 = "INFO"   # no UnitType yet: the radius is a guess
		var lines_txt := ""
		if not line_parts.is_empty() and (full_x > ext_x + 0.01 or full_z > ext_z + 0.01):
			lines_txt = "; thin parts ignored (%s): with them x %s / z %s" % [", ".join(PackedStringArray(line_parts.slice(0, 3))), ctx.fmt(full_x, 2), ctx.fmt(full_z, 2)]
		ctx.rep.add("R10", "read", "Footprint vs selection radius", st4,
			"x %s / z %s m (radius %s%s)%s" % [ctx.fmt(ext_x, 2), ctx.fmt(ext_z, 2), ctx.fmt(ctx.radius, 2), ", from " + String(ctx.unit.get("file", "")).get_file() if ctx.unit.has("file") else ", default", lines_txt],
			"x <= radius x 1.4, z <= x %s (art-units 1.1; parts thinner than 8 cm ignored)" % ("2.4" if lim_z > lim_x else "1.4"),
			"Pull wide parts in, or raise UnitType.radius", 1.0 if st4 == "PASS" else (0.5 if st4 == "WARN" else -1.0))


## Readability at 40 m (and 25 / 55): silhouette, contrast on every ground, glow, team colour, HP bar, motion, polish.
static func read_40(ctx: ArtLabRunner) -> void:
	var rules := ArtLabBudgets.read_rules(ctx.kind, ctx.tier)
	var box: AABB = ctx.m["box"]
	ctx.stage.game_cam(ctx.gp, 40.0)
	ArtLabStage.freeze(ctx.target, true)
	await ctx.frames(2)
	var roi := ctx.stage.roi_of(box, 16)
	var sil: Image = await ArtLabShots.sil(ctx, ctx.target)
	var mask := ArtLabImage.sil_mask(sil, roi)
	ctx.m["mask40"] = mask
	ctx.m["roi40"] = roi
	var lit: Image = await ctx.stage.grab()
	ctx.m["lit40"] = lit
	if not ctx.m.has("terrain_note"):
		ctx.m["terrain_note"] = true
		ctx.rep.notes.append(ctx.stage.terrain_note())
	ctx.m["hgt40"] = await ArtLabShots.height_pass(ctx, ctx.target)
	ctx.holder.visible = false
	var bg: Image = await ctx.stage.grab()
	ctx.holder.visible = true
	ctx.m["bg40"] = bg
	var con := ArtLabImage.contrast(lit, bg, roi, mask)
	# top third (world height) vs the ground: the part that reads over crowds and against the ground from pitch 55
	var top_mask := ArtLabImage.height_mask(mask, ctx.m["hgt40"], roi, 0.667, 1.0)
	if top_mask.count < 12:
		top_mask = ArtLabImage.top_rows(mask, 0.34)
	con["top"] = ArtLabImage.contrast(lit, bg, roi, top_mask) if top_mask.count > 0 else {}
	# R1 area
	var aw: int = rules.get("area_warn", 100)
	var af: int = rules.get("area_fail", 40)
	var area := mask.count
	ctx.stage.game_cam(ctx.gp, 55.0)
	var roi55 := ctx.stage.roi_of(box, 16)
	var mask55 := ArtLabImage.sil_mask(await ArtLabShots.sil(ctx, ctx.target), roi55)
	ctx.stage.game_cam(ctx.gp, 40.0)
	var st := "PASS" if area >= aw else ("WARN" if area >= af else "FAIL")
	ctx.rep.add("R1", "read", "Silhouette area at 40 m", st, "%d px (%d x %d bbox; 55 m: %d px)" % [area, mask.bbox.size.x,
		mask.bbox.size.y, mask55.count], ">= %d px (FAIL < %d) at 1600 x 900" % [aw, af],
		"Exaggerate the big masses (art-keep 0.1 / art-units 1.1): wider shoulders, bigger weapon / head, a taller vertical",
		ArtLabScore.grade(float(area), float(af), float(aw) * 2.0),
		"Grow the read at 40 m (now %d px): push the key shape (weapon, horns, crest, back mass) 15-25 %% bigger" % area, "z40")
	if con.get("n", 0) == 0:
		ctx.rep.add("R3", "read", "Contrast vs ground", "FAIL", "no silhouette pixels at 40 m", "visible at 40 m")
		ArtLabStage.freeze(ctx.target, false)
		return
	# R3 contrast on the main ground
	add_contrast(ctx, "R3", String(ctx.ground_id), con, rules, true)
	ctx.m["con"] = con
	# R4 other grounds (same frozen pose, same camera offset)
	var worst := {}
	var worst_g := ""
	var lines: Array[String] = []
	var home := {}
	for g: StringName in OTHER_GROUNDS:
		if g == ctx.ground_id or not ctx.wants(["R4", "R4k"]):   # v3 focus= (1.B): skip the other grounds
			continue
		# Same camera offset and frozen pose: the model lands on the same pixels, so roi and mask are reused.
		var p: Vector3 = ArtLabStage.GROUND_POINTS[g]
		ctx.holder.position = p
		ctx.stage.game_cam(p, 40.0)
		var roi_g := roi
		var lit_g: Image = await ctx.stage.grab()
		ctx.holder.visible = false
		var bg_g: Image = await ctx.stage.grab()
		ctx.holder.visible = true
		var cg := ArtLabImage.contrast(lit_g, bg_g, roi_g, mask)
		if int(cg.get("n", 0)) == 0:
			continue
		lines.append("%s dE %s" % [g, ctx.fmt(float(cg["de_means"]))])
		(ctx.m.get_or_add("fix_grounds", {}) as Dictionary)[String(g)] = cg   # v3 1.A hook: lab_fixes.gd colour recipe
		if g == ArtLabBudgets.KINGDOM_GROUND.get(ctx.kingdom, &""):
			home = cg
		if worst.is_empty() or float(cg["de_means"]) < float(worst["de_means"]):
			worst = cg
			worst_g = String(g)
			ctx.m["worst_ground_img"] = ctx.crop(lit_g, Vector2(roi_g.get_center()), Vector2i(maxi(roi_g.size.x * 3, 320), 180))
	ctx.holder.position = ctx.gp
	ctx.stage.game_cam(ctx.gp, 40.0)
	var home_g: StringName = ArtLabBudgets.KINGDOM_GROUND.get(ctx.kingdom, &"")
	if home_g == ctx.ground_id and home_g != &"":
		home = con
	if not home.is_empty():
		var hw: float = rules.get("de_warn", 20.0)
		var hde := float(home["de_means"])
		ctx.rep.add("R4k", "read", "Contrast on the home ground (%s)" % home_g, "PASS" if hde >= hw else "WARN",
			"dE %s, %d%% melts (%s is where %s units stand most)" % [ctx.fmt(hde), int(float(home["melt_frac"]) * 100.0), home_g, ctx.kingdom],
			"dE >= %s on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh)" % ctx.fmt(hw, 0),
			"A value step against the home ground: pale crests on dark ash / marsh, dark trims on snow",
			ArtLabScore.grade(hde, float(rules.get("de_fail", 10.0)) * 0.6, hw * 1.6),
			"On its home ground (%s) the body is only dE %s: add a value step for that ground" % [home_g, ctx.fmt(hde)] if hde < hw * 1.2 else "", "z40")
	if not worst.is_empty():
		var de_fail: float = rules.get("de_fail", 10.0)
		var st4 := "WARN" if float(worst["de_means"]) < de_fail else "PASS"
		ctx.rep.add("R4", "read", "Contrast on the other grounds", st4, "worst %s: dE %s (%s)" % [worst_g, ctx.fmt(float(worst["de_means"])),
			", ".join(lines)], "dE >= %s on every skirmish ground (WARN only)" % ctx.fmt(de_fail, 0),
			"A value accent that works on dark and light grounds (a pale crest / dark saddle)",
			ArtLabScore.grade(float(worst["de_means"]), de_fail * 0.6, float(rules.get("de_warn", 18.0)) * 1.5),
			"On %s the body drops to dE %s: add a value accent that separates it there too" % [worst_g, ctx.fmt(float(worst["de_means"]))], "z40")
		if ctx.m.has("worst_ground_img"):
			ctx.add_tile(ctx.m["worst_ground_img"], "40 m on %s (worst ground)" % worst_g)
	# R5 glow points at the bloom level, phase 1 of 3 (same frozen pose as the mask); phases 2-3 at the end of _read_40
	var gstate := {"phases": [], "roi": roi, "mask": mask}
	if ctx.wants(["R5", "R5c", "P5"]):   # v3 focus= (1.B) guards: ctx.wants is always true in a full run
		await glow_phase(ctx, gstate, mask, ctx.m.get("hgt40", null))
		# v3 1.A hook (fix recipes, lab_fixes.gd): unclipped glow peaks + part boxes + material weights of this pose
		var fx_s: Script = (load("res://tools/art_lab/lab_fixes.gd") as Script) if ResourceLoader.exists("res://tools/art_lab/lab_fixes.gd") else null
		if fx_s != null and fx_s.has_method(&"capture_40") and String(ctx.opts.get("fixes", "1")) != "0":
			await fx_s.call(&"capture_40", ctx, roi, mask)
	# R6 team colour
	if ctx.wants(["R6", "R3t", "R6cb"]):
		await team_pass(ctx, rules, roi, mask)
	# R7 HP bar
	if rules.has("bar_warn") and ctx.body_height > 0.0:
		var bw := maxf(1.0, ctx.radius * 2.6)
		var centre := ctx.holder.global_position + Vector3(0.0, ctx.body_height + 0.5, 0.0)
		var bx := ctx.stage.cam.global_basis.x * (bw * 0.5)
		var by := ctx.stage.cam.global_basis.y * 0.08
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		for s: Vector3 in [centre - bx - by, centre + bx - by, centre - bx + by, centre + bx + by]:
			var q := ctx.stage.cam.unproject_position(s)
			lo = lo.min(q)
			hi = hi.max(q)
		var rect := Rect2i(Vector2i(int(lo.x) - roi.position.x, int(lo.y) - roi.position.y), Vector2i(int(hi.x - lo.x) + 1, int(hi.y - lo.y) + 1))
		var covered := float(ArtLabImage.count_in_rect(mask, rect)) / float(maxi(mask.count, 1))
		var gap := float(mask.bbox.position.y) - float(rect.end.y)
		var bwarn: float = rules["bar_warn"]
		var bfail: float = rules["bar_fail"]
		var st7 := "PASS" if covered <= bwarn else ("WARN" if covered <= bfail else "FAIL")
		ctx.rep.add("R7", "read", "HP bar over the body at 40 m", st7, "bar hides %d%% of the silhouette (gap %d px)" % [int(covered * 100.0), int(gap)],
			"<= %d%% (FAIL > %d%%); bar at body_height + 0.5 = %s m, %s m wide" % [int(bwarn * 100.0), int(bfail * 100.0), ctx.fmt(ctx.body_height + 0.5, 2), ctx.fmt(bw, 2)],
			"Keep tall parts under body_height + 0.4 or narrower than 0.35 m, or raise body_height to the real head top",
			ArtLabScore.grade(covered, bfail, 0.0), "" if st7 == "PASS" else "The HP bar hides %d%% of the body: lower / narrow what sticks up, or fix body_height" % int(covered * 100.0), "z40")
	# A3 attack pose change at 40 m (animation.gd), then the polish checks P1 / P3 / P4 (polish.gd)
	if ctx.wants(["A3"]):
		await ArtLabCheckAnim.attack_reads(ctx, rules, roi, mask)
	if ctx.wants(["P1", "P3", "P4"]):
		await ArtLabCheckPolish.shape_value_detail(ctx, lit, roi, mask, box)
	# R5 glow phases 2-3 (idle moves on 0.37 s each; drifting motes and flickers are judged by the median)
	for ph_i: int in (2 if ctx.wants(["R5", "R5c", "P5"]) else 0):
		ArtLabStage.freeze(ctx.target, false)
		await ctx.wait(0.37)
		ArtLabStage.freeze(ctx.target, true)
		await ctx.frames(1)
		var mk := ArtLabImage.sil_mask(await ArtLabShots.sil(ctx, ctx.target), roi)
		await glow_phase(ctx, gstate, mk if mk.count > 0 else mask, null)
	glow_report(ctx, gstate, rules)
	# v3 1.D: light-preset sweep (R12) and the style bible (S1) on the rest pose, then the walk cycle (R11 / R5w)
	var rest := ArtLabImage.sil_mask(await ArtLabShots.sil(ctx, ctx.target), roi)
	if ctx.opts.get("quick", "0") != "1":
		if ctx.wants(["R12"]):
			await ArtLabCheckReadV3.preset_sweep(ctx, rules, roi, rest if rest.count > 0 else mask)
		if ctx.wants(["S1"]):
			await ArtLabCheckReadV3.style_bible(ctx, rules, roi, rest if rest.count > 0 else mask)
	else:
		ctx.rep.notes.append("quick=1: light-preset sweep (R12) and style bible (S1) skipped")
	if ctx.wants(["R11", "R5w"]):
		await ArtLabCheckReadV3.walk_reads(ctx, rules, box, int(gstate.get("n_hot", 0)))
	ArtLabStage.freeze(ctx.target, false)


static func add_contrast(ctx: ArtLabRunner, id: String, gname: String, con: Dictionary, rules: Dictionary, main: bool) -> void:
	# Primary: dE between the body's mean colour and the mean colour of the ground behind it (the 40 m "average read")
	# + the share of body pixels within dE 15 of that ground colour ("melt"). The per-pixel dE is shown for info.
	var de: float = con["de_means"]
	var melt: float = con["melt_frac"]
	var de_warn: float = rules.get("de_warn", 20.0)
	var de_fail: float = rules.get("de_fail", 10.0)
	var mw: float = rules.get("melt_warn", 0.35)
	var mf: float = rules.get("melt_fail", 0.6)
	var st := "PASS"
	if de < de_fail or melt > mf:
		st = "FAIL"
	elif de < de_warn or melt > mw:
		st = "WARN"
	var dl: float = con["dL"]
	# the hue gap only means something when the body is saturated (C* > 25): a grey-brown body has no real hue
	var chroma_ok := float(con["model_C"]) > 25.0
	var hue_txt := ("hue gap %d deg" % int(float(con["hue_gap"]))) if chroma_ok else "hue gap n/a (body C* <= 25)"
	var top: Dictionary = con.get("top", {})
	var top_txt := ""
	if int(top.get("n", 0)) > 0:
		top_txt = "; top third (world height) dE %s, L* %s" % [ctx.fmt(float(top["de_means"])), ctx.fmt(float(top["model_L"]))]
	var val := "mean-colour dE %s, %d%% of the body melts (within dE 15 of the ground); body L* %s C %s vs ground L* %s C %s, %s%s; per-pixel dE %s, outline %s" % [
		ctx.fmt(de), int(melt * 100.0), ctx.fmt(float(con["model_L"])), ctx.fmt(float(con["model_C"])), ctx.fmt(float(con["ground_L"])),
		ctx.fmt(float(con["ground_C"])), hue_txt, top_txt, ctx.fmt(float(con["de_mean"])), ctx.fmt(float(con["edge_de"]))]
	var why: Array[String] = []
	if absf(dl) < 10.0:
		why.append("value is close to the ground (dL %+d): lighten the top / back 15-20 %% or add a dark saddle / pale belly band" % int(dl))
	if int(top.get("n", 0)) > 0 and float(top["de_means"]) < de_warn and de >= de_warn:
		why.append("the top third (what reads from pitch 55) is close to the ground (dE %s): lighten helmets / shoulders / back" % ctx.fmt(float(top["de_means"])))
	if chroma_ok and float(con["hue_gap"]) < 35.0 and float(con["ground_C"]) > 12.0:
		why.append("the body sits in the ground's hue (gap %d deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it" % int(float(con["hue_gap"])))
	if why.is_empty():
		why.append("raise the value step between the big masses and the ground (dL %+d now)" % int(dl))
	var hint := "Melts into the %s: %s" % [gname, "; ".join(why)] if st != "PASS" else ""
	ctx.rep.add(id, "read", "Contrast vs ground (%s)" % gname, st, val,
		"mean-colour dE >= %s and <= 35 %% melting (FAIL: dE < %s or > 60 %% melting): the body must not melt into the grass" % [ctx.fmt(de_warn, 0), ctx.fmt(de_fail, 0)], hint,
		minf(ArtLabScore.grade(de, de_fail * 0.6, de_warn * 2.0), ArtLabScore.grade(melt, 0.7, 0.05)),
		("Raise the contrast of the key read on %s (dE %s): " % [gname, ctx.fmt(de)]) + "; ".join(why), "z40", 1.5)


## One glow phase: the "hot" frame (emission only, no bloom, 255 = the bloom level), flat decals and the model's own
## lights off. Clusters <= 4 px on the silhouette outline are a painted rim light, not glow points.
static func glow_phase(ctx: ArtLabRunner, gs: Dictionary, mask: ArtLabImage.Mask, hgt: Variant) -> void:
	var roi: Rect2i = gs["roi"]
	var frames: Array[Image] = await hot_frames(ctx, (gs["phases"] as Array).is_empty())
	var hot: Image = frames[0]
	var dark: Image = frames[1] if frames.size() > 1 else null
	var ph := classify_glow(hot, roi, mask)
	if dark != null:
		ph["dark"] = dark
		if hgt is Image:
			ph["hgt"] = hgt
	(gs["phases"] as Array).append(ph)


## The "hot" frame (emission only, no bloom, 255 = the bloom level) of the target as it stands, with its own lights
## and flat decals off; + the "dark" frame (emission with bloom) when `with_dark`. Returns [hot] or [hot, dark].
static func hot_frames(ctx: ArtLabRunner, with_dark: bool) -> Array[Image]:
	var off: Array[Node3D] = []
	for ln: Node in ctx.target.find_children("*", "Light3D", true, false):
		if (ln as Light3D).visible:
			off.append(ln as Node3D)
			(ln as Light3D).visible = false
	for gi: GeometryInstance3D in ArtLabCensus.geometry(ctx.target):
		if gi.visible and ArtLabCensus.is_flat_decal(gi, ctx.ground_y):
			off.append(gi)
			gi.visible = false
	var out: Array[Image] = []
	ctx.stage.set_mode(&"hot")
	out.append(await ctx.stage.grab())
	if with_dark:
		ctx.stage.set_mode(&"dark")
		out.append(await ctx.stage.grab())
	ctx.stage.set_mode(&"lit")
	for n: Node3D in off:
		n.visible = true
	return out


## Glow clusters of a hot frame split into points / painted rim specks (<= 4 px on the outline) / glowing surfaces
## (> 15 % of the body). Cluster centres in ROI px as "mx" / "my".
static func classify_glow(hot: Image, roi: Rect2i, mask: ArtLabImage.Mask) -> Dictionary:
	var groi := ArtLabImage.clamp_rect(roi, 10, ArtLabStage.W, ArtLabStage.H)
	var dx := groi.position.x - roi.position.x
	var dy := groi.position.y - roi.position.y
	var all_cl := ArtLabImage.glow_clusters(hot, groi, 0.97, 3, 2, true)
	var surf_px := maxi(int(float(mask.count) * 0.15), 30)
	var pts: Array[Dictionary] = []
	var rim := 0
	var surfaces := 0
	for c0: Dictionary in all_cl:
		var mx := int(round(float(c0["x"]))) + dx
		var my := int(round(float(c0["y"]))) + dy
		c0["mx"] = mx
		c0["my"] = my
		if int(c0["area"]) > surf_px:
			surfaces += 1
		elif int(c0["area"]) <= 4 and ArtLabImage.near_edge(mask, mx, my, 2):
			rim += 1
			c0["rim"] = true
		else:
			pts.append(c0)
	return {"points": pts, "rim": rim, "surfaces": surfaces, "all": all_cl}


## Median of the glow phases -> R5 (+ per-part report) and P5 (world height).
static func glow_report(ctx: ArtLabRunner, gs: Dictionary, rules: Dictionary) -> void:
	var phases: Array = gs["phases"]
	if phases.is_empty():
		return
	var roi: Rect2i = gs["roi"]
	var mask: ArtLabImage.Mask = gs["mask"]
	var surf_px := maxi(int(float(mask.count) * 0.15), 30)
	var counts: Array[int] = []
	for p: Dictionary in phases:
		counts.append((p["points"] as Array).size())
	var sorted := counts.duplicate()
	sorted.sort()
	var n_glow: int = sorted[sorted.size() / 2]
	var p0: Dictionary = phases[0]
	var best: Dictionary = p0
	for p2: Dictionary in phases:
		if (p2["points"] as Array).size() == n_glow:
			best = p2
			break
	var surfaces := int(best["surfaces"])
	var rim := int(best["rim"])
	var gr: Vector2i = rules.get("glow", Vector2i(1, 3))
	var st5 := "PASS" if n_glow >= gr.x and n_glow <= gr.y else "WARN"
	if n_glow < gr.x and surfaces > 0:
		st5 = "PASS"   # a glowing surface carries the glow read
	# per-part report: the smallest projected part box holding each point's centre
	var boxes: Array = []
	for gi: GeometryInstance3D in ArtLabCensus.geometry(ctx.target):
		if gi.is_visible_in_tree():
			boxes.append([ctx.stage.roi_of(gi.global_transform * gi.get_aabb(), 1), String(gi.name)])
	var parts: Dictionary = {}
	for c: Dictionary in best["points"]:
		var fp := Vector2i(roi.position.x + int(c["mx"]), roi.position.y + int(c["my"]))
		var nm := "?"
		var area_best := INF
		for b: Array in boxes:
			var rr: Rect2i = b[0]
			if rr.has_point(fp) and float(rr.get_area()) < area_best:
				area_best = float(rr.get_area())
				nm = b[1]
		parts[nm] = int(parts.get(nm, 0)) + 1
	var plist: Array[String] = []
	for k: String in parts:
		plist.append(("%s x%d" % [k, int(parts[k])]) if int(parts[k]) > 1 else k)
	var ctxt: Array[String] = []
	for v: int in counts:
		ctxt.append(str(v))
	# soft glows: v1's count (luma > 0.4 on the bloom render) for information, e.g. sap veins under the bloom level
	var soft := -1
	var soft_cl: Array[Dictionary] = []
	var groi := ArtLabImage.clamp_rect(roi, 10, ArtLabStage.W, ArtLabStage.H)
	if p0.has("dark"):
		soft_cl = ArtLabImage.glow_clusters(p0["dark"], groi, 0.4, 3, 2)
		soft = soft_cl.size()
	# v3 1.D (e): every point must stand out from its 1 m surround in the lit frame (R5c); Nature's soft sap glows that
	# pass the same local contrast count as glow points for the nature kingdom (user pre-approval, v3 plan defaults)
	var soft_ok := ArtLabCheckReadV3.glow_contrast(ctx, gs, p0, soft_cl, groi)
	var n_eff := n_glow
	if ctx.kingdom == &"nature" and n_glow < gr.x and soft_ok > 0:
		n_eff = n_glow + soft_ok
		if n_eff >= gr.x and st5 != "PASS":
			st5 = "PASS" if n_eff <= gr.y else "WARN"
	gs["n_glow"] = n_eff
	gs["n_hot"] = n_glow   # points above the bloom level only (R5w compares the walk frames with this)
	var gtxt := "%d point(s) above the bloom level %s (median of %s)%s%s%s" % [n_glow, ctx.fmt(ctx.stage.glow_level, 2),
		"/".join(ctxt), (": " + ", ".join(plist)) if not plist.is_empty() else "",
		(", + %d glowing surface(s)" % surfaces) if surfaces > 0 else "",
		(", %d rim-light speck(s) ignored" % rim) if rim > 0 else ""]
	if soft >= 0:
		gtxt += "; soft glows under the bloom (v1 count, luma > 0.4): %d" % soft
	if n_eff != n_glow:
		gtxt += "; + %d Nature soft glow(s) that stand out from their 1 m surround count as points (R5c)" % soft_ok
	var ghint := ""
	if n_eff < gr.x:
		ghint = "Add a glow point (eyes / rune / weapon, emission >= 2.5 so the bloom carries it)"
		if soft > 0:
			ghint += "; %d soft glow(s) sit under the bloom level: raise one to emission >= %s" % [soft, ctx.fmt(ctx.stage.glow_level * 2.0, 1)]
	elif n_glow > gr.y:
		ghint = "Too many glow points read as noise: merge them or dim the small ones below the bloom level (%s): %s" % [ctx.fmt(ctx.stage.glow_level, 1), ", ".join(plist)]
	ctx.rep.add("R5", "read", "Glow points at 40 m", st5, gtxt, "%d-%d above the bloom level (art-units 1.4 / art-keep 0.4)" % [gr.x, gr.y], ghint,
		1.0 if st5 == "PASS" else 0.4, ghint, "glow")
	if p0.has("dark"):
		var dimg: Image = (p0["dark"] as Image).duplicate()
		for c1: Dictionary in p0["all"]:
			var col := Color(0.2, 1.0, 0.3)
			if bool(c1.get("rim", false)):
				col = Color(0.6, 0.6, 0.6)
			elif int(c1["area"]) > surf_px:
				col = Color(1.0, 0.6, 0.1)
			ArtLabShots.mark(dimg, roi.position.x + int(c1["mx"]), roi.position.y + int(c1["my"]), 5, col)
		ctx.add_tile(ctx.crop(dimg, Vector2(roi.get_center()), Vector2i(maxi(roi.size.x * 3, 320), 180)),
			"emission: %d glow point(s) boxed green (rim grey, surfaces orange)" % n_glow)
	# P5 glow placement by world height (polish.gd)
	ArtLabCheckPolish.glow_placement(ctx, p0, roi, mask)


static func team_pass(ctx: ArtLabRunner, rules: Dictionary, roi: Rect2i, mask: ArtLabImage.Mask) -> void:
	var need: float = rules.get("team", 0.0)
	if need <= 0.0 or ctx.kingdom == &"neutral" or not ctx.target.has_method(&"set_team_color"):
		if need > 0.0:
			ctx.rep.add("R6", "read", "Team-colour visibility", "INFO", "neutral / no set_team_color", "kingdom units only")
		return
	# One fresh instance per colour: set_team_color is a spawn-time hook (the kit ignores the scene's own colour and
	# keeps the first colour on material_override parts), so recolouring one model 4 times would lie.
	var imgs: Array[Image] = []
	ctx.holder.visible = false
	for k: StringName in [&"fire", &"shadow", &"ice", &"nature"]:
		var inst := ctx.spawn(ctx.scene_path, ctx.gp, ArtLabRunner.MAIN_YAW)
		if inst == null:
			continue
		inst.call(&"set_team_color", ArtLabBudgets.KINGDOM_COLORS[k])
		await ctx.frames(2)
		await ctx.settle(inst)
		ArtLabStage.freeze(inst, true)
		imgs.append(await ctx.stage.grab())
		ctx.free_model(inst)
		await ctx.frames(1)
	ctx.holder.visible = true
	if imgs.size() < 4:
		return
	var fr: Array[float] = []
	for i: int in 4:
		for j: int in range(i + 1, 4):
			fr.append(ArtLabImage.changed_fraction(imgs[i], imgs[j], roi, mask, 8.0))
	var mean := 0.0
	var lo := 1.0
	for f: float in fr:
		mean += f
		lo = minf(lo, f)
	mean /= float(fr.size())
	var st := "PASS" if mean >= need else ("WARN" if mean > 0.001 else "FAIL")
	ctx.rep.add("R6", "read", "Team-colour visibility at 40 m", st, "%d%% of body pixels change between kingdom colours (min pair %d%%)" % [int(mean * 100.0), int(lo * 100.0)],
		">= %d%% (FAIL = set_team_color changes nothing)" % int(need * 100.0),
		"Put the team colour on a big, top-facing mass (cloth, plates, cape, caparison); ~25-45 %% of the surface (art-keep 0.2 / art-units 1.3)",
		ArtLabScore.grade(mean, 0.0, 0.25),
		"Give the team colour more top-facing area (now %d%% of the 40 m body; aim ~20%%): shoulder cloth, a banner, the cape top" % int(mean * 100.0) if mean < 0.2 else "", "teams")
	# R3t: the same contrast with every team colour (an enemy / mirror colour must not melt either)
	if ctx.m.has("bg40"):
		var names: Array[String] = ["fire", "shadow", "ice", "nature"]
		var worst_de := INF
		var worst_k := ""
		var tl: Array[String] = []
		for i2: int in imgs.size():
			var ct := ArtLabImage.contrast(imgs[i2], ctx.m["bg40"], roi, mask)
			if int(ct.get("n", 0)) == 0:
				continue
			tl.append("%s %s" % [names[i2], ctx.fmt(float(ct["de_means"]))])
			(ctx.m.get_or_add("fix_team", {}) as Dictionary)[names[i2]] = ct   # v3 1.A hook: lab_fixes.gd colour recipe
			if float(ct["de_means"]) < worst_de:
				worst_de = float(ct["de_means"])
				worst_k = names[i2]
		if worst_de < INF:
			var dw: float = rules.get("de_warn", 20.0)
			var df: float = rules.get("de_fail", 10.0)
			var st3 := "PASS" if worst_de >= dw else "WARN"
			ctx.rep.add("R3t", "read", "Contrast in every team colour (%s)" % ctx.ground_id, st3, "worst %s colour: dE %s (%s)" % [worst_k, ctx.fmt(worst_de), ", ".join(tl)],
				"dE >= %s in every kingdom colour (WARN only: mirror matches / enemy colours)" % ctx.fmt(dw, 0),
				"Keep the team colour off the silhouette's biggest mass or give it a value step (trim, dark border)",
				ArtLabScore.grade(worst_de, df * 0.6, dw * 1.6),
				"In the %s team colour the body drops to dE %s on %s: add a value step around the team-colour area" % [worst_k, ctx.fmt(worst_de), ctx.ground_id] if worst_de < dw * 1.2 else "", "teams")
	var crops: Array[Image] = []
	for img: Image in imgs:
		crops.append(ctx.crop(img, Vector2(roi.get_center()), Vector2i(maxi(roi.size.x * 2, 200), 112)))
	ctx.add_tile(ArtLabImage.grid(crops, 2, 400, 225), "team colours at 40 m: fire / shadow / ice / nature")
	ArtLabCheckReadV3.colour_blind(ctx, imgs, roi, mask, rules)


static func references(ctx: ArtLabRunner) -> void:
	var refs := await ArtLabScenes.pick_refs(ctx)
	if refs.is_empty():
		ctx.rep.add("R2", "read", "Distinct from references", "INFO", "no reference found", "silhouette IoU <= 0.8")
		return
	var box: AABB = ctx.m["box"]
	var rules := ArtLabBudgets.read_rules(ctx.kind)
	var half := maxf(maxf(box.size.x, box.size.z) * 0.5, 1.5) * 2.2
	var hh := maxf(box.end.y - ctx.gp.y, 2.0) * 1.7
	var big := AABB(ctx.gp - Vector3(half, 0.0, half), Vector3(half * 2.0, hh, half * 2.0))
	ctx.stage.game_cam(ctx.gp, 40.0)
	var roi := ctx.stage.roi_of(big, 4)
	var yaws: Array[float] = [0.0, 90.0, 180.0, 270.0]
	ArtLabStage.freeze(ctx.target, true)
	var tmask: Array = []
	for y: float in yaws:
		ctx.holder.rotation.y = deg_to_rad(y)
		tmask.append(ArtLabImage.sil_mask(await ArtLabShots.sil(ctx, ctx.target), roi))
	ctx.holder.rotation.y = 0.0
	var tlit: Image = await ctx.stage.grab()
	var tlab := ArtLabImage.mean_lab(tlit, roi, tmask[0])
	var tflap := ArtLabCheckReadV3.flap_state(ctx.target)   # v3 1.D (c): the target's wing phase (frozen) for flyer references
	var matched: Array[String] = []
	ctx.holder.rotation.y = deg_to_rad(ArtLabRunner.MAIN_YAW)
	ArtLabStage.freeze(ctx.target, false)
	# P2 asymmetry of the front view (polish.gd)
	ArtLabCheckPolish.asymmetry(ctx, tmask[0], roi)
	ctx.holder.visible = false
	var results: Array[Dictionary] = []
	var sil_masks: Array = [tmask[0]]
	var sil_labels: Array[String] = [ctx.asset]
	for rp: String in refs:
		var rm := ctx.spawn(rp, ctx.gp, 0.0)
		if rm == null:
			continue
		if rm.has_method(&"set_team_color"):
			rm.call(&"set_team_color", ctx.model_color(rm))
		await ctx.frames(2)
		await ctx.settle(rm)
		ArtLabStage.freeze(rm, true)
		if not tflap.is_empty():
			var resid: float = await ArtLabCheckReadV3.match_flap(ctx, rm, tflap)
			if resid >= 0.0:
				matched.append("%s %s" % [rp.get_file().get_basename(), ctx.fmt(resid, 2)])
		var ious: Array[float] = []
		var rmask0: ArtLabImage.Mask = null
		for i: int in yaws.size():
			rm.get_parent().rotation.y = deg_to_rad(yaws[i])
			var mk := ArtLabImage.sil_mask(await ArtLabShots.sil(ctx, rm), roi)
			if i == 0:
				rmask0 = mk
			ious.append(ArtLabImage.iou(tmask[i], mk))
		rm.get_parent().rotation.y = 0.0
		var rlit: Image = await ctx.stage.grab()
		var rlab := ArtLabImage.mean_lab(rlit, roi, rmask0)
		var mean := 0.0
		for v: float in ious:
			mean += v
		mean /= float(ious.size())
		results.append({"path": rp, "name": rp.get_file().get_basename(), "iou": mean, "de": tlab.distance_to(rlab)})
		sil_masks.append(rmask0)
		sil_labels.append("%s %s" % [rp.get_file().get_basename(), ctx.fmt(mean, 2)])
		ctx.free_model(rm)
		await ctx.frames(1)
	ctx.holder.visible = true
	results.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["iou"]) > float(b["iou"]))
	var lim: float = rules.get("iou", 0.8)
	var top: Dictionary = results[0] if not results.is_empty() else {}
	var lst: Array[String] = []
	for r: Dictionary in results:
		lst.append("%s %s" % [r["name"], ctx.fmt(float(r["iou"]), 2)])
	var st := "PASS"
	var hint := ""
	var value := "max IoU %s (%s)" % [ctx.fmt(float(top.get("iou", 0.0)), 2), ", ".join(lst)]
	if not top.is_empty() and float(top["iou"]) > lim:
		if float(top["de"]) < 15.0:
			st = "WARN"
			hint = "Reads like %s at 40 m (IoU %s, colour dE %s): change the silhouette hook (a different vertical, weapon, head shape)" % [top["name"], ctx.fmt(float(top["iou"]), 2), ctx.fmt(float(top["de"]))]
		else:
			value += "; same shape family as %s but told apart by colour (dE %s)" % [top["name"], ctx.fmt(float(top["de"]))]
	if not matched.is_empty():
		value += "; wing phase matched to the target's (p %s; residual per flyer ref: %s)" % [ctx.fmt(float(tflap["p"]), 2), ", ".join(matched)]
	elif not tflap.is_empty():
		value += "; flyer: no flyer reference to phase-match"
	ctx.rep.add("R2", "read", "Distinct from references (black masks)", st, value,
		"IoU <= %s vs every reference (4 turns, 40 m), else colour must differ (dE >= 15)" % ctx.fmt(lim, 2), hint,
		ArtLabScore.grade(float(top.get("iou", 0.0)), 0.9, 0.45),
		("Make it read apart from %s (IoU %s): change one big shape of the silhouette" % [top.get("name", ""), ctx.fmt(float(top.get("iou", 0.0)), 2)]) if float(top.get("iou", 0.0)) > 0.6 else "", "silhouette")
	# every silhouette cropped with the same rect: same scale, as at 40 m
	var common: Rect2i = (sil_masks[0] as ArtLabImage.Mask).bbox
	for mk: ArtLabImage.Mask in sil_masks:
		if mk.count > 0:
			common = common.merge(mk.bbox)
	var sil_tiles: Array[Image] = []
	for mk2: ArtLabImage.Mask in sil_masks:
		sil_tiles.append(ArtLabShots.mask_tile(mk2, common))
	var sheet := ArtLabImage.grid(sil_tiles, mini(sil_tiles.size(), 4), 240, 240, Color.WHITE, true)
	ctx.save_shot(sheet, "silhouette", true)
	ctx.add_tile(sheet, "40 m silhouettes (same scale): " + ", ".join(sil_labels))
	await ArtLabShots.lineup(ctx, refs)
