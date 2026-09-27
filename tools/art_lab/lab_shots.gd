class_name ArtLabShots
extends RefCounted
## Art Lab (docs/plan/art-lab.md): the shots. Black silhouette / height passes, the game-camera frames (40 / 55 / 25 m,
## close-up), the 4 turns, the lineup with the references and the army silhouette pass of a sweep. Every function takes
## the run context (`ctx: ArtLabRunner`: stage, target, holder, report, shared measurements `ctx.m`).
## Checks call these; they never add a check themselves.

static func sil(ctx: ArtLabRunner, root: Node) -> Image:
	ctx.stage.set_mode(&"sil")
	var rec := ctx.stage.override(root, ctx.stage.black_mat, ctx.ground_y)
	var img: Image = await ctx.stage.grab()
	ctx.stage.restore(rec)
	ctx.stage.set_mode(&"lit")
	return img


static func shots(ctx: ArtLabRunner) -> void:
	ctx.stage.set_mode(&"lit")
	var box := ArtLabCensus.world_aabb(ctx.target, ctx.ground_y)
	ctx.m["box"] = box
	for z: float in [40.0, 55.0, 25.0]:
		ctx.stage.game_cam(ctx.gp, z)
		var img: Image = await ctx.stage.grab()
		ctx.save_shot(img, "z%d" % int(z))
		var roi := ctx.stage.roi_of(box, 8)
		var c := Vector2(roi.get_center())
		var crop := ctx.crop(img, c, Vector2i(maxi(roi.size.x * 3, 320), maxi(roi.size.y * 3, 180)))
		ctx.add_tile(crop, "%d m game camera (crop, real pixels)" % int(z))
		if z == 40.0:
			ctx.m["img40"] = img
	ctx.stage.fit_cam(box, 20.0, 0.0, 0.8)
	var close: Image = ctx.crop_box(await ctx.stage.grab(), box, 0.12)
	ctx.save_shot(close, "close")
	ctx.add_tile(close, "close-up 3/4")


## World-height pass: grey = height above the ground / the model's top (P3 / P5 judge by world height, so flat
## creatures and quadrupeds seen at pitch 55 are not judged by screen rows).
static func height_pass(ctx: ArtLabRunner, root: Node3D) -> Image:
	var top := maxf(float(((ctx.m.get("bounds", {}) as Dictionary).get("max", Vector3.ONE) as Vector3).y), 0.2)
	ctx.stage.height_mat.set_shader_parameter(&"y0", ctx.ground_y)
	ctx.stage.height_mat.set_shader_parameter(&"span", top)
	ctx.stage.set_mode(&"sil")
	var rec := ctx.stage.override(root, ctx.stage.height_mat, ctx.ground_y)
	var img: Image = await ctx.stage.grab()
	ctx.stage.restore(rec)
	ctx.stage.set_mode(&"lit")
	return img


static func mark(img: Image, cx: int, cy: int, r: int, col: Color) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for i: int in range(-r, r + 1):
		for p: Vector2i in [Vector2i(cx + i, cy - r), Vector2i(cx + i, cy + r), Vector2i(cx - r, cy + i), Vector2i(cx + r, cy + i)]:
			if p.x >= 0 and p.y >= 0 and p.x < w and p.y < h:
				img.set_pixelv(p, col)


static func turns(ctx: ArtLabRunner) -> void:
	var box: AABB = ctx.m["box"]
	ctx.stage.fit_cam(box.grow(0.2), 22.0, 0.0, 0.75)
	var imgs: Array[Image] = []
	var big := AABB()
	for yaw0: float in [0.0, 90.0]:
		ctx.holder.rotation.y = deg_to_rad(yaw0)
		var b0 := ArtLabCensus.world_aabb(ctx.target, ctx.ground_y)
		big = b0 if yaw0 == 0.0 else big.merge(b0)
	for yaw: float in [0.0, 90.0, 180.0, 270.0]:
		ctx.holder.rotation.y = deg_to_rad(yaw)
		imgs.append(ctx.crop_box(await ctx.stage.grab(), big, 0.1))
	ctx.holder.rotation.y = deg_to_rad(ArtLabRunner.MAIN_YAW)
	var sheet := ArtLabImage.grid(imgs, 2, 800, 450)
	ctx.save_shot(sheet, "turns")
	ctx.add_tile(sheet, "turns 0 / 90 / 180 / 270")


static func mask_tile(mk: ArtLabImage.Mask, crop: Rect2i) -> Image:
	var img := ArtLabImage.mask_image(mk)
	var r := ArtLabImage.clamp_rect(crop, 4, mk.w, mk.h)
	return img.get_region(r) if r.size.x > 1 and r.size.y > 1 else img


static func lineup(ctx: ArtLabRunner, refs: Array[String]) -> void:
	var paths: Array[String] = [ctx.scene_path]
	paths.append_array(refs)
	var models: Array[Node3D] = []
	var widths: Array[float] = []
	for p: String in paths:
		var mm := ctx.spawn(p, ctx.gp + Vector3(0.0, 0.0, 300.0), 0.0)
		if mm == null:
			continue
		if mm.has_method(&"set_team_color"):
			mm.call(&"set_team_color", ctx.model_color(mm) if p != ctx.scene_path else ctx.model_color(ctx.target))
		models.append(mm)
	await ctx.frames(4)
	await ctx.wait(0.7)   # spawn animations (sprouts, rise-ups) end before the lineup shot
	for mm2: Node3D in models:
		var b := ArtLabCensus.world_aabb(mm2, ctx.ground_y)
		widths.append(maxf(b.size.x, 0.6))
	var total := 0.0
	for w: float in widths:
		total += w + 0.8
	var x := -total * 0.5
	for i: int in models.size():
		x += widths[i] * 0.5 + 0.4
		(models[i].get_parent() as Node3D).position = ctx.gp + Vector3(x, 0.0, 0.0)
		(models[i].get_parent() as Node3D).rotation.y = deg_to_rad(20.0)
		x += widths[i] * 0.5 + 0.4
	ctx.holder.visible = false
	await ctx.frames(2)
	ctx.stage.game_cam(ctx.gp, 40.0)
	var img: Image = await ctx.stage.grab()
	var row := AABB()
	for j: int in models.size():
		var bj := ArtLabCensus.world_aabb(models[j], ctx.ground_y)
		row = bj if j == 0 else row.merge(bj)
	var roi := ctx.stage.roi_of(row, 20)
	ctx.add_tile(ctx.crop(img, Vector2(roi.get_center()), Vector2i(roi.size.x, roi.size.y)), "lineup at 40 m (first = %s)" % ctx.asset)
	ctx.stage.fit_cam(row, 10.0, 0.0, 0.9)
	var side: Image = ctx.crop_box(await ctx.stage.grab(), row, 0.06)
	ctx.save_shot(side, "lineup")
	ctx.add_tile(side, "lineup side: " + ", ".join(paths.map(func(p: String) -> String: return p.get_file().get_basename())))
	for mm3: Node3D in models:
		ctx.free_model(mm3)
	ctx.holder.visible = true
	await ctx.frames(1)


## Army sweep (art_lab.gd `sweep=<kingdom>`): every model's 40 m black silhouette rendered ONCE (4 turns, one
## common camera), then every pair compared (mean IoU over the turns + mean colour dE). Returns
## {"pairs": [{a, b, iou, de}] sorted by IoU, "alike": pairs that read alike (IoU > 0.8 and dE < 15)}.
static func army_pass(ctx: ArtLabRunner, paths: Array[String], out: String) -> Dictionary:
	ctx.headless = DisplayServer.get_name() == "headless"
	if ctx.headless or paths.size() < 2:
		return {"pairs": [], "alike": [], "skipped": true}
	await ctx.use_stage(&"warm")
	ctx.gp = ArtLabStage.GROUND_POINTS[&"meadow"]
	ctx.ground_y = ctx.gp.y
	ctx.stage.game_cam(ctx.gp, 40.0)
	var roi := ctx.stage.roi_of(AABB(ctx.gp - Vector3(3.0, 0.0, 3.0), Vector3(6.0, 5.0, 6.0)), 4)
	var masks: Array = []
	var labs: Array[Vector3] = []
	var names: Array[String] = []
	for p: String in paths:
		var inst := ctx.spawn(p, ctx.gp, 0.0)
		if inst == null:
			continue
		if inst.has_method(&"set_team_color"):
			inst.call(&"set_team_color", ctx.model_color(inst))
		await ctx.frames(2)
		await ctx.settle(inst)
		ArtLabStage.freeze(inst, true)
		var ms: Array = []
		for yaw: float in [0.0, 90.0, 180.0, 270.0]:
			(inst.get_parent() as Node3D).rotation.y = deg_to_rad(yaw)
			ms.append(ArtLabImage.sil_mask(await sil(ctx, inst), roi))
		(inst.get_parent() as Node3D).rotation.y = 0.0
		var lit: Image = await ctx.stage.grab()
		labs.append(ArtLabImage.mean_lab(lit, roi, ms[0]))
		masks.append(ms)
		names.append(p.get_file().get_basename())
		ctx.free_model(inst)
		await ctx.frames(1)
	var pairs: Array[Dictionary] = []
	for i: int in masks.size():
		for j: int in range(i + 1, masks.size()):
			var s := 0.0
			for y: int in 4:
				s += ArtLabImage.iou(masks[i][y], masks[j][y])
			pairs.append({"a": names[i], "b": names[j], "iou": s / 4.0, "de": labs[i].distance_to(labs[j])})
	pairs.sort_custom(func(x: Dictionary, y2: Dictionary) -> bool: return float(x["iou"]) > float(y2["iou"]))
	var alike: Array[Dictionary] = []
	for pr: Dictionary in pairs:
		if float(pr["iou"]) > 0.8 and float(pr["de"]) < 15.0:
			alike.append(pr)
	var tiles_img: Array[Image] = []
	var common := Rect2i()
	for k: int in masks.size():
		var mk0: ArtLabImage.Mask = masks[k][0]
		if mk0.count > 0:
			common = mk0.bbox if common.size == Vector2i.ZERO else common.merge(mk0.bbox)
	for k2: int in masks.size():
		tiles_img.append(mask_tile(masks[k2][0], common))
	if not tiles_img.is_empty():
		var sheet := ArtLabImage.grid(tiles_img, mini(tiles_img.size(), 6), 200, 200, Color.WHITE, true)
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
		sheet.save_png(ProjectSettings.globalize_path(out.path_join("army_silhouettes.png")))
	return {"pairs": pairs, "alike": alike, "names": names}
