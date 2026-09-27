class_name ArtLabCheckReadV3
extends RefCounted
## Art Lab v3 phase 1, task 1.D (docs/plan/art-lab-v3-plan.md): the new quality checks, called from the readability
## pass (checks/readability.gd) at their place, same frozen pose / camera / masks:
##   R5c  glow points stand out from their 1 m surround (lit 40 m frame); Nature soft glows that pass count as R5 points
##   R6cb team colours for colour-blind players (deutan / protan simulation of the 4 kingdom-colour frames), WARN only
##   R12  contrast on the main ground under every light preset (warm, ice, night stand-in, autumn), WARN only
##   S1   style bible: golden autumn (style-autumn.md 3), INFO (graded)
##   R11  reads while walking: 40 m silhouette over the walk cycle vs the rest read, WARN only
##   R5w  glow points while walking (flicker), WARN only
##   R2   (in readability.references) flyer references posed at the target's wing phase (match_flap)
## Thresholds: ArtLabBudgets.V3 (tools/art_lab/lab_budgets.gd, owner 1.C; moved there as one block and calibrated on
## the calibration set, docs/plan/art-lab.md "Calibration"). Change them there, never here.

const V3 := ArtLabBudgets.V3
const FLOOR_SWATCHES: Array[String] = ["grass_dark", "grass_light", "grass_warm", "grass_cool", "grass_dry",
	"clover_color", "dirt_color", "dirt_dark", "road_color", "road_dark", "bank_damp", "bank_sand", "needle_color",
	"moss_color", "heather_color", "gorse_color"]


## Pixels per metre at the target (current camera, across the screen).
static func px_per_m(ctx: ArtLabRunner) -> float:
	var cam := ctx.stage.cam
	var p := ctx.gp + Vector3(0.0, maxf(ctx.body_height, 0.5) * 0.5, 0.0)
	return cam.unproject_position(p).distance_to(cam.unproject_position(p + cam.global_basis.x))


# ---------------------------------------------------------------- R5c glow-point local contrast (1.D e)

## Each glow point of the first glow phase (same pose as the lit 40 m frame `ctx.m["lit40"]`) against its 1 m
## surround: core L* vs the ring's median L*. For the Nature kingdom the soft glows (under the bloom level, not already
## a point) are judged the same way; returns how many of those stand out (readability counts them as R5 points:
## user pre-approval, v3 plan "Default decisions").
static func glow_contrast(ctx: ArtLabRunner, gs: Dictionary, p0: Dictionary, soft_cl: Array[Dictionary], groi: Rect2i) -> int:
	var lit: Image = ctx.m.get("lit40", null)
	var roi: Rect2i = gs["roi"]
	var pts: Array = p0["points"]
	if lit == null or (pts.is_empty() and (soft_cl.is_empty() or ctx.kingdom != &"nature")):
		return 0
	var r_ring := maxf(px_per_m(ctx) * float(V3["glow_ring_m"]), 6.0)
	var warn: float = V3["glow_dl_warn"]
	var rows: Array[String] = []
	var dls: Array[float] = []
	for c: Dictionary in pts:
		var lc := ArtLabImage.local_contrast(lit, roi.position.x + int(c["mx"]), roi.position.y + int(c["my"]),
			maxf(sqrt(float(c["area"]) / PI) + 1.0, 2.0), r_ring)
		dls.append(float(lc["dL"]))
		rows.append("point %d dL %+d" % [rows.size() + 1, int(float(lc["dL"]))])
	var soft_ok := 0
	var soft_rows: Array[String] = []
	if ctx.kingdom == &"nature":
		for s: Dictionary in soft_cl:
			var sx := groi.position.x + int(round(float(s["x"])))
			var sy := groi.position.y + int(round(float(s["y"])))
			var dup := false
			for c2: Dictionary in pts:
				if Vector2(roi.position.x + int(c2["mx"]), roi.position.y + int(c2["my"])).distance_to(Vector2(sx, sy)) < 5.0:
					dup = true
					break
			if dup:
				continue
			var lc2 := ArtLabImage.local_contrast(lit, sx, sy, maxf(sqrt(float(s["area"]) / PI) + 1.0, 2.0), r_ring)
			var dl2 := float(lc2["dL"])
			if dl2 >= warn:
				soft_ok += 1
				dls.append(dl2)
			soft_rows.append("soft %d dL %+d%s" % [soft_rows.size() + 1, int(dl2), " (counts)" if dl2 >= warn else ""])
	rows.append_array(soft_rows)
	var v := glow_contrast_verdict(dls)
	if dls.is_empty():
		if not soft_rows.is_empty():
			ctx.rep.add("R5c", "read", "Glow points stand out (1 m surround)", "WARN",
				"no point above the bloom level; Nature soft glows: %s" % ", ".join(soft_rows),
				"a glow point's core L* >= its 1 m surround's median L* + %s (Nature soft glows count as points when they pass)" % ctx.fmt(warn, 0),
				"Brighten one sap vein / eye (emission up) or darken the bark / socket around it so it pops from 1 m away",
				0.3, "Make one Nature soft glow stand out from its 1 m surround (dL >= %s; none does now)" % ctx.fmt(warn, 0),
				"glow", float(V3["weight"]))
		return 0
	ctx.rep.add("R5c", "read", "Glow points stand out (1 m surround)", v["status"],
		"worst dL %+d (%s; ring %d px = %s m at 40 m)" % [int(float(v["worst"])), ", ".join(rows), int(r_ring), ctx.fmt(float(V3["glow_ring_m"]), 1)],
		"each glow point's core L* >= the median L* of its 1 m surround + %s in the lit 40 m frame (WARN only)" % ctx.fmt(warn, 0),
		"A point that does not stand out reads as a pale smudge: raise its emission or darken what is around it (socket, hood, dark trim)",
		v["grade"], ("%d glow point(s) barely stand out from their 1 m surround (worst dL %+d): darken around them or raise the energy" % [int(v["weak"]), int(float(v["worst"]))]) if int(v["weak"]) > 0 else "",
		"glow", float(V3["weight"]))
	return soft_ok


## R5c verdict (pure, tested): per-point dL list -> status, grade (mean of the per-point grades), worst, weak count.
static func glow_contrast_verdict(dls: Array[float]) -> Dictionary:
	if dls.is_empty():
		return {"status": "INFO", "grade": -1.0, "worst": 0.0, "weak": 0}
	var worst := INF
	var weak := 0
	var s := 0.0
	for d: float in dls:
		worst = minf(worst, d)
		if d < float(V3["glow_dl_warn"]):
			weak += 1
		s += ArtLabScore.grade(d, float(V3["glow_dl_bad"]), float(V3["glow_dl_good"]))
	return {"status": "PASS" if weak == 0 else "WARN", "grade": s / float(dls.size()), "worst": worst, "weak": weak}


# ---------------------------------------------------------------- R6cb colour-blind team colours (1.D d)

## The 4 kingdom-colour frames (team_pass order fire / shadow / ice / nature) as a deuteranope / protanope sees them
## (Machado 2009): the worst kingdom pair on the team-colour area (pixels that change between colours) and R3t's
## body-vs-ground contrast under the same simulation. WARN only (v3 plan default).
static func colour_blind(ctx: ArtLabRunner, imgs: Array[Image], roi: Rect2i, mask: ArtLabImage.Mask, rules: Dictionary) -> void:
	if imgs.size() < 4:
		return
	var team := ArtLabImage.diff_mask(imgs, roi, mask, 8.0)
	if team.count < 6:
		return
	var names: Array[String] = ["fire", "shadow", "ice", "nature"]
	var bg: Image = ctx.m.get("bg40", null)
	var worst := INF
	var worst_txt := ""
	var worst_ij := Vector2i.ZERO
	var worst_kind: StringName = &"deutan"
	var worst_sims: Array[Image] = []
	var wg := INF
	var wg_txt := ""
	var lines: Array[String] = []
	for kind: StringName in [&"deutan", &"protan"]:
		var sims: Array[Image] = []
		for im: Image in imgs:
			sims.append(ArtLabImage.cvd_image(im, roi, kind))
		var kmin := INF
		var kij := Vector2i.ZERO
		for i: int in 4:
			for j: int in range(i + 1, 4):
				var d := ArtLabImage.mean_de(sims[i], sims[j], roi, team)
				if d < kmin:
					kmin = d
					kij = Vector2i(i, j)
		lines.append("%s: %s / %s dE %s" % [kind, names[kij.x], names[kij.y], ctx.fmt(kmin)])
		if kmin < worst:
			worst = kmin
			worst_ij = kij
			worst_kind = kind
			worst_sims = sims
			worst_txt = "%s / %s (%s)" % [names[kij.x], names[kij.y], kind]
		if bg != null:
			var sbg := ArtLabImage.cvd_image(bg, roi, kind)
			for k: int in 4:
				var ct := ArtLabImage.contrast(sims[k], sbg, roi, mask)
				if int(ct.get("n", 0)) > 0 and float(ct["de_means"]) < wg:
					wg = float(ct["de_means"])
					wg_txt = "%s colour (%s)" % [names[k], kind]
	var normal := ArtLabImage.mean_de(imgs[worst_ij.x], imgs[worst_ij.y], roi, team)
	var df: float = rules.get("de_fail", 10.0)
	var v := cb_verdict(worst, wg, df, float(rules.get("de_warn", 20.0)))
	var gtxt := ("; worst vs ground: %s dE %s" % [wg_txt, ctx.fmt(wg)]) if wg < INF else ""
	ctx.rep.add("R6cb", "read", "Team colours for colour-blind players", v["status"],
		"worst pair %s: dE %s on the team-colour area (normal vision %s; %d px); %s%s" % [worst_txt, ctx.fmt(worst),
			ctx.fmt(normal), team.count, "; ".join(lines), gtxt],
		"deutan / protan simulation: the worst kingdom pair differs by mean dE >= %s on the team-colour area and the body stays >= dE %s from the ground (WARN only)" % [ctx.fmt(float(V3["cb_pair_warn"]), 0), ctx.fmt(df, 0)],
		"Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS)",
		v["grade"], ("For red-green colour-blind players %s look alike on this model (dE %s): add a value step inside the team-colour area" % [worst_txt, ctx.fmt(worst)]) if v["status"] != "PASS" else "",
		"teams", float(V3["weight"]))
	var crops: Array[Image] = []
	for img: Image in worst_sims:
		crops.append(ctx.crop(img, Vector2(roi.get_center()), Vector2i(maxi(roi.size.x * 2, 200), 112)))
	if not crops.is_empty():
		ctx.add_tile(ArtLabImage.grid(crops, 2, 400, 225), "team colours as a %s sees them: fire / shadow / ice / nature" % ("deuteranope" if worst_kind == &"deutan" else "protanope"))


## R6cb verdict (pure, tested): worst kingdom pair dE on the team area, worst body-vs-ground dE (INF = not measured).
static func cb_verdict(worst_pair: float, worst_ground: float, de_fail: float, de_warn: float) -> Dictionary:
	var st := "PASS"
	if worst_pair < float(V3["cb_pair_warn"]) or worst_ground < de_fail:
		st = "WARN"
	var g := ArtLabScore.grade(worst_pair, float(V3["cb_pair_bad"]), float(V3["cb_pair_good"]))
	if worst_ground < INF:
		g = minf(g, ArtLabScore.grade(worst_ground, de_fail * 0.6, de_warn * 1.6))
	return {"status": st, "grade": g}


# ---------------------------------------------------------------- R12 light-preset sweep (1.D g)

## The body's contrast on the main ground under every light preset (warm, ice, the night stand-in, autumn), same
## frozen pose and camera; the stage goes back to its own preset after. Worst preset below de_fail = WARN (like R4).
static func preset_sweep(ctx: ArtLabRunner, rules: Dictionary, roi: Rect2i, mask: ArtLabImage.Mask) -> void:
	if not ctx.kind in (V3["preset_kinds"] as Array):
		return
	var cur := ctx.stage.light_now
	var lines: Array[String] = []
	var tiles: Array[Image] = []
	var worst := INF
	var worst_id := ""
	var worst_con := {}
	for id: StringName in V3["preset_ids"]:
		if not ctx.stage.set_light(id):
			continue
		await ctx.frames(1)
		var lit: Image = await ctx.stage.grab()
		ctx.holder.visible = false
		var bg: Image = await ctx.stage.grab()
		ctx.holder.visible = true
		var c := ArtLabImage.contrast(lit, bg, roi, mask)
		if int(c.get("n", 0)) == 0:
			continue
		var de := float(c["de_means"])
		lines.append("%s dE %s" % [id, ctx.fmt(de)])
		tiles.append(ctx.crop(lit, Vector2(roi.get_center()), Vector2i(maxi(roi.size.x * 2, 200), 112)))
		if de < worst:
			worst = de
			worst_id = String(id)
			worst_con = c
	ctx.stage.set_light(cur)
	await ctx.frames(1)
	if lines.is_empty():
		return
	var df: float = rules.get("de_fail", 10.0)
	var dw: float = rules.get("de_warn", 20.0)
	var st := "PASS" if worst >= df else "WARN"
	ctx.rep.add("R12", "read", "Contrast under every light preset (%s)" % ctx.ground_id, st,
		"worst %s: dE %s, dL %+d (%s); night = lab stand-in (warm preset, dim moon sun)" % [worst_id, ctx.fmt(worst),
			int(float(worst_con.get("dL", 0.0))), ", ".join(lines)],
		"mean-colour dE >= %s on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map)" % ctx.fmt(df, 0),
		"Keep a value step that survives a dim cool light: a pale crest / light top on a dark body, or a glow point that carries it at night",
		ArtLabScore.grade(worst, df * 0.6, dw * 1.5),
		("Under the %s light the body drops to dE %s: add a value step (light top / pale crest) that survives a dim light" % [worst_id, ctx.fmt(worst)]) if worst < dw else "",
		"z40", float(V3["weight"]))
	ctx.add_tile(ArtLabImage.grid(tiles, 2, 400, 225), "light presets at 40 m: " + ", ".join(lines))


# ---------------------------------------------------------------- S1 style bible (1.D f)

## Conformance with the golden-autumn style bible (docs/art/style-autumn.md 3): the body on the autumn floor
## (autumn_ground_params colours on the same zones, preset_autumn light): mean-colour dE, melt share, body L* / C* vs
## the floor's value / chroma band, and the kingdom colour vs every floor swatch (the bible's own dE >= 20 rule).
## INFO (graded) until the autumn runs of style-autumn.md 6 are done (v3 plan default), then WARN.
static func style_bible(ctx: ArtLabRunner, _rules: Dictionary, roi: Rect2i, mask: ArtLabImage.Mask) -> void:
	var cur := ctx.stage.light_now
	if not ctx.stage.set_ground_look(&"autumn"):
		return
	var lit_ok := ctx.stage.set_light(&"autumn")
	await ctx.frames(1)
	var lit: Image = await ctx.stage.grab()
	ctx.holder.visible = false
	var bg: Image = await ctx.stage.grab()
	ctx.holder.visible = true
	ctx.stage.set_ground_look(&"")
	ctx.stage.set_light(cur)
	await ctx.frames(1)
	var c := ArtLabImage.contrast(lit, bg, roi, mask)
	if int(c.get("n", 0)) == 0:
		return
	var team_de := -1.0
	var team_sw := ""
	if ctx.kingdom != &"neutral" and ArtLabBudgets.KINGDOM_COLORS.has(ctx.kingdom):
		var r := team_vs_swatches(ArtLabBudgets.KINGDOM_COLORS[ctx.kingdom], style_swatches())
		team_de = float(r["de"])
		team_sw = String(r["name"])
	var v := style_verdict(float(c["de_means"]), float(c["melt_frac"]), float(c["model_L"]), float(c["model_C"]), team_de)
	var band: Vector2 = V3["style_ground_L"]
	ctx.rep.add("S1", "polish", "Style bible: golden autumn (style-autumn.md 3)", "INFO",
		"on the autumn floor: dE %s, %d%% melts; body L* %s C %s vs floor L* %s C %s%s%s%s" % [ctx.fmt(float(c["de_means"])),
			int(float(c["melt_frac"]) * 100.0), ctx.fmt(float(c["model_L"])), ctx.fmt(float(c["model_C"])), ctx.fmt(float(c["ground_L"])),
			ctx.fmt(float(c["ground_C"])), " (inside the floor band)" if v["in_band"] else "",
			("; %s team colour vs the floor swatches: min dE %s (%s)" % [ctx.kingdom, ctx.fmt(team_de), team_sw]) if team_de >= 0.0 else "",
			"" if lit_ok else "; autumn light preset missing (warm light used)"],
		"units sit outside the autumn floor band (L* %d-%d, C* <= %d): body vs floor dE >= 20, <= 35 %% melting; team colour dE >= %d to every floor swatch (INFO until the style-autumn.md 6 runs)" % [int(band.x), int(band.y), int(float(V3["style_ground_C"])), int(float(V3["style_team_de"]))],
		"Saturated autumn lives in the trees, not on the floor: a mid-value, low-chroma brown / olive body melts on the ochre floor; push the main mass out of the band (value or chroma)",
		v["grade"], ("On the autumn map the body melts into the ochre floor (dE %s): push its main mass out of the L* 25-55 / C* <= 35 band" % ctx.fmt(float(c["de_means"]))) if float(v["grade"]) < 0.6 else "",
		"z40", float(V3["weight"]))
	ctx.add_tile(ctx.crop(lit, Vector2(roi.get_center()), Vector2i(maxi(roi.size.x * 3, 320), 180)), "40 m on the autumn floor (style-autumn.md)")


## The autumn floor swatches (style-autumn.md 1.1, the tones units stand on), name -> sRGB colour.
static func style_swatches() -> Dictionary:
	var out := {}
	if not ResourceLoader.exists(ArtLabStage.AUTUMN_GROUND_PATH):
		return out
	var ap := load(ArtLabStage.AUTUMN_GROUND_PATH) as GDScript
	if ap == null:
		return out
	var gp: Dictionary = ap.call(&"ground_params")
	for k: String in FLOOR_SWATCHES:
		var val: Variant = gp.get(StringName(k), null)
		if val is Color:
			out[k] = val
	return out


## Min CIE76 dE between a colour and a set of swatches (the bible's own rule: team colour vs every floor tone).
static func team_vs_swatches(col: Color, sw: Dictionary) -> Dictionary:
	var kl := ArtLabImage.lab(int(round(col.r * 255.0)), int(round(col.g * 255.0)), int(round(col.b * 255.0)))
	var best := -1.0
	var name := ""
	for k: String in sw:
		var s: Color = sw[k]
		var d := kl.distance_to(ArtLabImage.lab(int(round(s.r * 255.0)), int(round(s.g * 255.0)), int(round(s.b * 255.0))))
		if best < 0.0 or d < best:
			best = d
			name = k
	return {"de": best, "name": name}


## S1 grade (pure, tested): body vs the autumn floor (dE, melt), inside the floor's value / chroma band, team colour
## min dE to the swatches (-1 = no kingdom colour).
static func style_verdict(de: float, melt: float, body_l: float, body_c: float, team_de: float) -> Dictionary:
	var band: Vector2 = V3["style_ground_L"]
	var in_band := body_l >= band.x and body_l <= band.y and body_c <= float(V3["style_ground_C"])
	var g := minf(ArtLabScore.grade(de, float(V3["style_de_bad"]), float(V3["style_de_good"])), ArtLabScore.grade(melt, 0.7, 0.05))
	if in_band:
		g *= 0.85
	if team_de >= 0.0:
		g = minf(g, ArtLabScore.grade(team_de, 8.0, float(V3["style_team_de"]) * 1.5))
	return {"grade": g, "in_band": in_band}


# ---------------------------------------------------------------- R11 / R5w reads while walking (1.D b)

## The unit walking at 40 m (set_moving(stride); critters play_move): the black mask of 8 frames of the gait (0.09 s
## apart after a 0.5 s ramp) against the rest mask (IoU, area kept) and frame to frame (pops); the glow points above
## the bloom level per frame (flicker: points blinking on / off read as noise). `rest_glow` = R5's point count.
static func walk_reads(ctx: ArtLabRunner, rules: Dictionary, box: AABB, rest_glow: int) -> void:
	if ctx.kind in [&"building", &"landmark"]:
		return
	var hook: StringName = &"play_move" if ctx.kind == &"critter" else &"set_moving"
	if not ctx.target.has_method(hook):
		return
	ctx.stage.game_cam(ctx.gp, 40.0)
	var wroi := ctx.stage.roi_of(box, 28)
	ArtLabStage.freeze(ctx.target, true)
	await ctx.frames(1)
	var rest := ArtLabImage.sil_mask(await ArtLabShots.sil(ctx, ctx.target), wroi)
	if rest.count == 0:
		return
	ArtLabStage.freeze(ctx.target, false)
	ctx.target.call(hook, ctx.stride)
	await ctx.wait(float(V3["walk_ramp"]))
	var masks: Array = []
	var counts: Array[int] = []
	for i: int in int(V3["walk_samples"]):
		ArtLabStage.freeze(ctx.target, true)
		await ctx.frames(1)
		var mk := ArtLabImage.sil_mask(await ArtLabShots.sil(ctx, ctx.target), wroi)
		masks.append(mk)
		var hf: Array[Image] = await ArtLabCheckRead.hot_frames(ctx, false)
		counts.append((ArtLabCheckRead.classify_glow(hf[0], wroi, mk if mk.count > 0 else rest)["points"] as Array).size())
		ArtLabStage.freeze(ctx.target, false)
		await ctx.wait(float(V3["walk_dt"]))
	if hook == &"set_moving":
		ctx.target.call(&"set_moving", 0.0)
	else:
		ctx.call_hook(ctx.target, &"play_idle")
	await ctx.wait(0.6)
	var ws := ArtLabImage.walk_stats(rest, masks)
	var area_warn: int = rules.get("area_warn", 100)
	var min_area := int(float(rest.count) * float(ws["area_ratio_min"]))
	var v := walk_verdict(ws, min_area, area_warn, ctx.flyer)
	ctx.rep.add("R11", "read", "Reads while walking (40 m)%s" % (" (flyer: wing beat)" if ctx.flyer else ""), v["status"],
		"walk frames vs rest: mean IoU %s (min %s), area kept %d-%d%% (min %d px), frame-to-frame IoU min %s; %d frames %s s apart" % [
			ctx.fmt(float(ws["mean_iou"]), 2), ctx.fmt(float(ws["min_iou"]), 2), int(float(ws["area_ratio_min"]) * 100.0),
			int(float(ws["area_ratio_max"]) * 100.0), min_area, ctx.fmt(float(ws["step_iou_min"]), 2), int(ws["n"]), ctx.fmt(float(V3["walk_dt"]), 2)],
		"mean IoU walk vs rest >= %s, >= %d%% of the rest area in every frame and >= R1's %d px (WARN only)" % [ctx.fmt(float(V3["walk_iou_warn"]), 2), int(float(V3["walk_area_warn"]) * 100.0), area_warn],
		"The silhouette must survive the gait: keep the key shape (weapon, crest, back mass) out of the swing, damp limbs that sweep the whole outline",
		v["grade"], ("While walking the 40 m silhouette keeps only IoU %s / %d%% area of the rest read: keep the key shape still in the gait" % [ctx.fmt(float(ws["mean_iou"]), 2), int(float(ws["area_ratio_min"]) * 100.0)]) if v["status"] == "WARN" else "",
		"anim", float(V3["weight"]))
	var fl := ArtLabImage.flicker(counts)
	if int(fl["hi"]) > 0 or rest_glow > 0:
		var fst := flicker_verdict(fl)
		var ctxt: Array[String] = []
		for n: int in counts:
			ctxt.append(str(n))
		ctx.rep.add("R5w", "read", "Glow points while walking (flicker)", fst["status"],
			"points per frame %s (median %d, range %d, %d frame(s) at 0; at rest %d)" % ["/".join(ctxt), int(fl["median"]), int(fl["range"]), int(fl["drops"]), rest_glow],
			"the glow-point count stays within +-%d over the walk cycle and never drops to 0 (WARN only)" % int(V3["flicker_range_warn"]),
			"Glow points that hide behind a swinging limb or dip under the bloom level blink at 40 m: move them to a steady part (head, chest, weapon head) or raise their energy",
			fst["grade"], ("The glow points blink while walking (%s per frame): put them on parts the gait does not cover" % "/".join(ctxt)) if fst["status"] != "PASS" else "",
			"glow", float(V3["weight"]))
	var tiles: Array[Image] = []
	var common: Rect2i = rest.bbox
	for mk2: ArtLabImage.Mask in masks:
		if mk2.count > 0:
			common = common.merge(mk2.bbox)
	tiles.append(ArtLabShots.mask_tile(rest, common))
	for mk3: ArtLabImage.Mask in masks:
		tiles.append(ArtLabShots.mask_tile(mk3, common))
	ctx.add_tile(ArtLabImage.grid(tiles, 9, 120, 160, Color.WHITE, true), "walk cycle at 40 m: rest + %d frames (black masks)" % masks.size())


## R11 verdict (pure, tested). Flyers: the wing beat IS the moving read (the Frost Dragon's wings move IoU to ~0.5 and
## grow the area 30 %), so only a lost area warns; the IoU part is INFO.
static func walk_verdict(ws: Dictionary, min_area_px: int, area_warn_px: int, flyer: bool = false) -> Dictionary:
	var area_bad := float(ws["area_ratio_min"]) < float(V3["walk_area_warn"]) or min_area_px < area_warn_px
	var ga := ArtLabScore.grade(float(ws["area_ratio_min"]), float(V3["walk_area_bad"]), float(V3["walk_area_good"]))
	if flyer:
		return {"status": "WARN" if area_bad else "INFO", "grade": ga}
	var st := "WARN" if area_bad or float(ws["mean_iou"]) < float(V3["walk_iou_warn"]) else "PASS"
	var g := minf(ArtLabScore.grade(float(ws["mean_iou"]), float(V3["walk_iou_bad"]), float(V3["walk_iou_good"])), ga)
	return {"status": st, "grade": g}


## R5w verdict (pure, tested).
static func flicker_verdict(fl: Dictionary) -> Dictionary:
	var st := "PASS"
	if int(fl["range"]) > int(V3["flicker_range_warn"]) or int(fl["drops"]) > int(V3["flicker_drop_warn"]):
		st = "WARN"
	var n := maxf(float(V3["walk_samples"]), 1.0)
	return {"status": st, "grade": clampf(1.0 - float(fl["changes"]) / n - 0.15 * float(fl["drops"]), 0.0, 1.0)}


# ---------------------------------------------------------------- R2 flyers at a matching wing phase (1.D c)

## The wing state of a flyer (FlyerModel `_flap_p`, 0-1, and `_flap_amp_w`) under `root`, or {} for a non-flyer.
static func flap_state(root: Node) -> Dictionary:
	var fn := flap_node(root)
	if fn == null:
		return {}
	return {"p": float(fn.get(&"_flap_p")), "amp": float(fn.get(&"_flap_amp_w")) if &"_flap_amp_w" in fn else 1.0}


## The node carrying the wing phase (`_flap_p`) under `root` (itself included), or null.
static func flap_node(root: Node) -> Node:
	if not is_instance_valid(root):
		return null
	if &"_flap_p" in root:
		return root
	for n: Node in root.find_children("*", "", true, false):
		if &"_flap_p" in n:
			return n
	return null


## Poses a frozen flyer reference at the target's wing phase: sets `_flap_p` one frame early (by that frame's advance,
## dt / flap_period), lets exactly one frame pose it, freezes it again; one corrected retry. Returns the phase residual
## (0-0.5), -1 when the reference is not a flyer. v2.1 only set phase 0 at spawn (target and references spawn at
## different times, so their wings still differed by the time between the spawns).
static func match_flap(ctx: ArtLabRunner, rm: Node3D, tflap: Dictionary) -> float:
	var fn := flap_node(rm)
	if fn == null:
		return -1.0
	var want := float(tflap["p"])
	var resid := 1.0
	var period := float(fn.get(&"flap_period")) if &"flap_period" in fn else 1.0
	var adv := ctx.get_process_delta_time() / maxf(period, 0.2)
	for attempt: int in 2:
		if &"_flap_amp_w" in fn:
			fn.set(&"_flap_amp_w", float(tflap.get("amp", 1.0)))
		if &"_gliding" in fn:
			fn.set(&"_gliding", false)
		var start := fposmod(want - adv, 1.0)
		fn.set(&"_flap_p", start)
		ArtLabStage.freeze(rm, false)
		await ctx.frames(1)
		ArtLabStage.freeze(rm, true)
		var got := float(fn.get(&"_flap_p"))
		var d := fposmod(got - want, 1.0)
		resid = minf(d, 1.0 - d)
		if resid <= 0.02:
			break
		adv = fposmod(got - start, 1.0)   # the real advance of that frame
	await ctx.frames(1)
	return resid
