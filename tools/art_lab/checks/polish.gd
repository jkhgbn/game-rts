class_name ArtLabCheckPolish
extends RefCounted
## Art Lab checks (docs/plan/art-lab.md section 3): polish P1-P5, scored 0-100 but never FAIL / WARN (status INFO).
## Called from the readability pass at their place (same frozen pose, same 40 m mask): P1 / P3 / P4 after A3, P2 from
## the references pass (front view), P5 after R5 (glow points).


## P1 silhouette hook (outline complexity), P3 tops light / bottoms dark (world height), P4 detail density 25 / 40 m.
## `lit` = the lit 40 m frame, `roi` / `mask` = the 40 m silhouette, `box` = the model's world box. Shoots the 25 m
## frame (silhouette + lit) and puts the camera back at 40 m.
static func shape_value_detail(ctx: ArtLabRunner, lit: Image, roi: Rect2i, mask: ArtLabImage.Mask, box: AABB) -> void:
	# polish: hook (complexity), value structure, detail density
	var cx := ArtLabImage.complexity(mask)
	ctx.rep.add("P1", "polish", "Silhouette hook", "INFO", "outline complexity %s" % ctx.fmt(cx, 2), "a blob is ~1.3-1.8; a strong hook >= 2.2",
		"", ArtLabScore.grade(cx, 1.3, 2.6), "Give the 40 m silhouette a hook (now %s): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register)" % ctx.fmt(cx, 2) if cx < 2.2 else "", "silhouette")
	# P3 by world height (top third of the model's height vs the bottom third), screen rows as a fallback
	var vbands := ArtLabImage.value_bands(lit, roi, mask)
	var how := "screen rows"
	var mt := ArtLabImage.height_mask(mask, ctx.m["hgt40"], roi, 0.667, 1.0)
	var mb := ArtLabImage.height_mask(mask, ctx.m["hgt40"], roi, 0.0, 0.333)
	if mt.count >= 8 and mb.count >= 8:
		vbands = Vector2(ArtLabImage.mean_l(lit, roi, mt), ArtLabImage.mean_l(lit, roi, mb))
		how = "world height"
	var dv := vbands.x - vbands.y
	ctx.rep.add("P3", "polish", "Tops light, bottoms dark", "INFO", "top third L* %s, bottom third L* %s (%+d, %s)" % [ctx.fmt(vbands.x), ctx.fmt(vbands.y), int(dv), how],
		"top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top)", "", ArtLabScore.grade(dv, -5.0, 12.0),
		"Lighten the top masses / darken the legs and base (top - bottom now %+d L*, aim >= +10)" % int(dv) if dv < 10.0 else "", "z40")
	ctx.stage.game_cam(ctx.gp, 25.0)
	var roi25 := ctx.stage.roi_of(box, 16)
	var mask25 := ArtLabImage.sil_mask(await ArtLabShots.sil(ctx, ctx.target), roi25)
	var lit25: Image = await ctx.stage.grab()
	ctx.stage.game_cam(ctx.gp, 40.0)
	var d40 := ArtLabImage.detail(lit, roi, mask)
	var d25 := ArtLabImage.detail(lit25, roi25, mask25)
	var dscore := 1.0 - clampf(maxf(3.0 - d25, d25 - 11.0) / 4.0, 0.0, 1.0)
	var dimp := ""
	if d25 < 3.0:
		dimp = "Detail density is low at 25 m (%s): add 1-2 mid-size value blocks (trim band, belt, plate edge) that read at 25 m and merge at 40 m" % ctx.fmt(d25)
	elif d25 > 11.0:
		dimp = "Busy at 25 m (%s): merge small value changes into bigger blocks so the 40 m read stays clean" % ctx.fmt(d25)
	ctx.rep.add("P4", "polish", "Detail density 25 m / 40 m", "INFO", "inner detail %s at 25 m, %s at 40 m (mean |grad L*| per px)" % [ctx.fmt(d25), ctx.fmt(d40)],
		"about 3-11 at 25 m: readable blocks, no noise", "", dscore, dimp, "z25")


## P2 asymmetric secondary shape: `front` = the 40 m black mask at yaw 0, `roi` its frame rect (references pass).
static func asymmetry(ctx: ArtLabRunner, front: ArtLabImage.Mask, roi: Rect2i) -> void:
	# P2 asymmetry of the front view (yaw 0)
	var axis := ctx.stage.cam.unproject_position(ctx.gp).x - float(roi.position.x)
	var asym := ArtLabImage.asymmetry(front, axis)
	ctx.rep.add("P2", "polish", "Asymmetric secondary shape", "INFO", "front-view asymmetry %s" % ctx.fmt(asym, 2),
		"one asymmetric secondary element (art-keep 0.1): >= ~0.15", "", ArtLabScore.grade(asym, 0.02, 0.2),
		"Add an asymmetric secondary element to the front read (asymmetry %s): a shoulder banner, a one-sided weapon / shield, a broken horn (>= ~0.25 m wide, or it does not register at 40 m)" % ctx.fmt(asym, 2) if asym < 0.15 else "", "silhouette")


## P5 glow placement by world height (glowing surfaces count too). `p0` = the first glow phase of R5 (clusters,
## height frame), `roi` / `mask` = the 40 m silhouette.
static func glow_placement(ctx: ArtLabRunner, p0: Dictionary, roi: Rect2i, mask: ArtLabImage.Mask) -> void:
	var pts: Array = []
	for c3: Dictionary in p0["all"]:
		if not bool(c3.get("rim", false)):
			pts.append(c3)
	if not pts.is_empty():
		var high := 0
		var hgt: Variant = p0.get("hgt", null)
		for c2: Dictionary in pts:
			var hv := 0.0
			if hgt is Image:
				hv = ArtLabImage.height_at(hgt, roi, int(c2["mx"]), int(c2["my"]))
			else:
				hv = 1.0 - float(int(c2["my"]) - mask.bbox.position.y) / float(maxi(mask.bbox.size.y, 1))
			if hv >= 0.5:
				high += 1
		var frac := float(high) / float(pts.size())
		ctx.rep.add("P5", "polish", "Glow placement", "INFO", "%d of %d glow(s) in the upper half of the model's height (world)" % [high, pts.size()],
			"one glow high (head / weapon / crest) reads over crowds", "", ArtLabScore.grade(frac, 0.0, 0.5),
			"Move or add one glow point to the upper half (head, weapon tip, crest) so it reads above other units" if high == 0 else "",
			"glow")
