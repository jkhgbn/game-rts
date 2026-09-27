extends SceneTree
## Task 10.V12: renders the trade icons (market-trade.md 9, ui-trade.md 15) to res://art/icons/<kind>/<id>.png
## (128 x 128, transparent where nothing is drawn, no baked frame) and the contact sheet
## res://docs/art/screens/trade_icons.png (every icon at 128 and at the sizes the UI shows it). Stand-alone (does not
## touch render_icons.gd's pipeline); same renderer, sizes and look. Must run WINDOWED (needs the renderer):
##   Godot_v4.7.2-stable_win64_console.exe --path . --script art/icons/render_trade_icons.gd --fixed-fps 60 --quit-after 6000
## then `--headless --path . --import` so Godot imports the new PNGs. Optional: `-- ids=caravan,heron_ford` re-renders
## only those (the sheet then reads the others from disk).
## Painted (trade_icon_painter.gd): orders/trade|route|wares, wares/<4>, contracts/<2>, posts/<4>, ui/<5>.
## Rendered from the models (3/4 view through a SubViewport, over a painted halo): units/caravan (loaded),
## units/magpie, units/greywater_tracker, buildings/<kingdom>_market, buildings/magpie_den, buildings/greywater_lodge.
## A model scene that does not exist yet falls back to icon_painter.gd's placeholder and is listed as MISSING.

const Painter := preload("res://art/icons/trade_icon_painter.gd")
const OUT := "res://art/icons/"
const SHEET_PATH := "res://docs/art/screens/trade_icons.png"
const BIG := 256
const SIZE := 128

## [kind, id] painted in code.
const PAINTED: Array = [
	[&"ui", &"gold_coin"], [&"ui", &"exchange_crystals"], [&"ui", &"exchange_essence"],
	[&"ui", &"crest_bazaar"], [&"ui", &"crest_lodge"],
	[&"orders", &"trade"], [&"orders", &"route"], [&"orders", &"wares"],
	[&"wares", &"iron_axles"], [&"wares", &"masons_charter"], [&"wares", &"tempered_steel"], [&"wares", &"gambesons"],
	[&"contracts", &"outriders"], [&"contracts", &"sweep"],
	[&"posts", &"heron_ford"], [&"posts", &"millstone_cross"], [&"posts", &"lantern_wharf"], [&"posts", &"saltgate"],
]
## [kind, id, model scene, background (trade_icon_painter.gd bg faction)].
const MODELS: Array = [
	[&"units", &"caravan", "res://art/units/caravan/caravan.tscn", &"trade"],
	[&"units", &"magpie", "res://art/units/neutral/magpie/magpie.tscn", &"magpie"],
	[&"units", &"greywater_tracker", "res://art/units/neutral/tracker/tracker.tscn", &"tracker"],
	[&"buildings", &"fire_market", "res://art/buildings/market/fire/market_fire.tscn", &"fire"],
	[&"buildings", &"shadow_market", "res://art/buildings/market/shadow/market_shadow.tscn", &"shadow"],
	[&"buildings", &"ice_market", "res://art/buildings/market/ice/market_ice.tscn", &"ice"],
	[&"buildings", &"nature_market", "res://art/buildings/market/nature/market_nature.tscn", &"nature"],
	[&"buildings", &"magpie_den", "res://art/buildings/guilds/magpie_den/magpie_den.tscn", &"magpie"],
	[&"buildings", &"greywater_lodge", "res://art/buildings/guilds/greywater_lodge/greywater_lodge.tscn", &"tracker"],
]
## Per-id camera: [centre height ratio of the framed height, radius ratio, yaw deg, pitch deg]. Units frame the upper
## body like render_icons.gd; the caravan is framed whole (ox + wagon) from its right side.
const FRAMING := {
	&"caravan": [0.5, 0.44, 68.0, 24.0],
	&"magpie": [0.6, 0.44, 28.0, 14.0],
	&"greywater_tracker": [0.62, 0.42, 26.0, 14.0],
}
## Team colour for the models that take one (icons are shared by both teams): the weathered guild ochre that the
## champion portraits use.
const NEUTRAL_SASH := Color(0.66, 0.50, 0.26)
## The caravan canvas: a pale sun-bleached cream, so the wagon reads against the warm gold halo.
const CARAVAN_CANVAS := Color(0.90, 0.84, 0.70)
## UI sizes per kind (ui-trade.md 15) for the contact sheet.
const UI_SIZES := {
	&"units": [56, 40], &"buildings": [88, 56], &"posts": [88, 56], &"wares": [40, 24], &"contracts": [68, 40],
	&"orders": [56, 40], &"ui": [32, 16, 12, 10],
}

var _entries: Array = []  # [kind, id, Image]
var _only_ids: Array[String] = []
var _missing: Array[String] = []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("ids="):
			_only_ids.assign(a.trim_prefix("ids=").split(",", false))
	_run.call_deferred()


func _wanted(id: StringName) -> bool:
	return _only_ids.is_empty() or _only_ids.has(String(id))


func _run() -> void:
	await process_frame
	for e: Array in PAINTED:
		if _wanted(e[1]):
			await _paint(e[0], e[1], &"fire")
		else:
			_load_existing(e[0], e[1])
	for e: Array in MODELS:
		if not _wanted(e[1]):
			_load_existing(e[0], e[1])
			continue
		var path: String = e[2]
		if ResourceLoader.exists(path):
			await _render_model(e[0], e[1], load(path) as PackedScene, e[3])
		else:
			_missing.append(path)
			await _paint(e[0], e[1], e[3] if e[3] in [&"fire", &"shadow", &"ice", &"nature"] else &"neutral")
	await _contact_sheet()
	for m in _missing:
		print("MISSING model (placeholder painted): ", m)
	print("TRADE ICONS DONE: %d icons, %d missing models" % [_entries.size(), _missing.size()])
	quit()


func _load_existing(kind: StringName, id: StringName) -> void:
	var p: String = ProjectSettings.globalize_path("%s%s/%s.png" % [OUT, kind, id])
	if FileAccess.file_exists(p):
		var img := Image.load_from_file(p)
		if img != null and not img.is_empty():
			img.convert(Image.FORMAT_RGBA8)
			_entries.append([kind, id, img])


func _new_viewport(two_d: bool) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = Vector2i(BIG, BIG)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	if two_d:
		vp.disable_3d = true
		vp.msaa_2d = Viewport.MSAA_4X
	else:
		vp.own_world_3d = true
		vp.msaa_3d = Viewport.MSAA_4X
	root.add_child(vp)
	return vp


func _painted_image(kind: StringName, id: StringName, faction: StringName) -> Image:
	var vp := _new_viewport(true)
	var p: Node2D = Painter.new()
	p.set("kind", kind)
	p.set("id", id)
	p.set("faction", faction)
	vp.add_child(p)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img: Image = vp.get_texture().get_image()
	vp.queue_free()
	img.convert(Image.FORMAT_RGBA8)
	return img


func _paint(kind: StringName, id: StringName, faction: StringName) -> void:
	var img: Image = await _painted_image(kind, id, faction)
	_save(kind, id, img)


func _render_model(kind: StringName, id: StringName, scene: PackedScene, bg_faction: StringName) -> void:
	var model: Node = scene.instantiate()
	if model.get_script() == null:
		# Every trade model builds itself in its root script: no script = it failed to parse (someone is editing the
		# kit). Keep the icon already on disk instead of saving an empty halo.
		print("SKIPPED %s/%s: the model script did not load, kept the old icon" % [kind, id])
		model.free()
		_load_existing(kind, id)
		return
	var vp := _new_viewport(false)
	vp.add_child(model)
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.52, 0.70)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 6.0
	env_node.environment = env
	vp.add_child(env_node)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.93, 0.82)
	sun.light_energy = 1.3
	sun.rotation_degrees = Vector3(-40, -35, 0)
	vp.add_child(sun)
	var cam := Camera3D.new()
	cam.fov = 30.0
	vp.add_child(cam)
	var is_unit: bool = kind == &"units"
	if is_unit and model.has_method(&"set_team_color") and id != &"magpie":
		model.call(&"set_team_color", CARAVAN_CANVAS if id == &"caravan" else NEUTRAL_SASH)
	if model.has_method(&"set_loaded") and id == &"caravan":
		model.call(&"set_loaded", true)  # the strongbox of glowing coins + the lit lantern: "this unit brings gold"
	await create_timer(0.9 if is_unit else 0.4).timeout
	_hide_particles(model)
	var box: AABB = _model_aabb(model)
	var center: Vector3 = box.get_center()
	var radius: float
	var pitch: float = deg_to_rad(25.0)
	var yaw: float = deg_to_rad(30.0)
	if is_unit:
		var h: float = box.size.y
		var head: Node = model.find_child("Head", true, false)
		var fr: Array = FRAMING.get(id, [0.58, 0.44, 30.0, 20.0])
		if head != null and id != &"caravan":
			var hb: AABB = _model_aabb(head)
			h = minf(h, (hb.end.y - box.position.y) * 1.3)
			var hc: Vector3 = hb.get_center()
			center.x = lerpf(center.x, hc.x, 0.5)
			center.z = lerpf(center.z, hc.z, 0.5)
		center.y = box.position.y + h * float(fr[0])
		if id == &"caravan":
			radius = maxf(box.size.x, box.size.z) * float(fr[1])
		else:
			radius = maxf(h * float(fr[1]), maxf(box.size.x, box.size.z) * 0.42)
		yaw = deg_to_rad(float(fr[2]))
		pitch = deg_to_rad(float(fr[3]))
	else:
		# Ignore the flat contact decal: frame on the tallest dimension mostly (render_icons.gd's building rule).
		radius = maxf(box.size.y * 0.62, maxf(box.size.x, box.size.z) * 0.42)
		center.y = box.position.y + box.size.y * 0.45
	var dist: float = radius / sin(deg_to_rad(cam.fov * 0.5))
	cam.position = center + Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * dist
	cam.look_at(center, Vector3.UP)
	cam.current = true
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var shot: Image = vp.get_texture().get_image()
	vp.queue_free()
	shot.convert(Image.FORMAT_RGBA8)
	var bg: Image = await _painted_image(&"bg", id, bg_faction)
	bg.blend_rect(shot, Rect2i(0, 0, BIG, BIG), Vector2i.ZERO)
	_save(kind, id, bg)


func _hide_particles(n: Node) -> void:
	for c in n.find_children("*", "GPUParticles3D", true, false):
		(c as GPUParticles3D).visible = false
	for c in n.find_children("*", "CPUParticles3D", true, false):
		(c as CPUParticles3D).visible = false


func _model_aabb(n: Node) -> AABB:
	var out := AABB()
	var first := true
	var stack: Array[Node] = [n]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		stack.append_array(cur.get_children())
		if cur is GeometryInstance3D and not (cur is GPUParticles3D) and not (cur is CPUParticles3D):
			var gi := cur as GeometryInstance3D
			if not gi.is_visible_in_tree():
				continue
			var b: AABB = gi.global_transform * gi.get_aabb()
			if b.size.y < 0.06 * maxf(b.size.x, b.size.z):
				continue  # contact decal / ground quad / selection ring
			if first:
				out = b
				first = false
			else:
				out = out.merge(b)
	if first:
		out = AABB(Vector3(-1, 0, -1), Vector3(2, 2, 2))
	return out


func _save(kind: StringName, id: StringName, img: Image) -> void:
	img.resize(SIZE, SIZE, Image.INTERPOLATE_LANCZOS)
	var dir: String = OUT + String(kind)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var path: String = "%s/%s.png" % [dir, id]
	if img.save_png(ProjectSettings.globalize_path(path)) != OK:
		push_error("icon save failed: " + path)
	_entries.append([kind, id, img])


# ---------------------------------------------------------------- contact sheet
class SheetDrawer extends Node2D:
	const COLS := 6
	const CW := 252
	const CH := 204
	var entries: Array = []
	var sizes: Dictionary = {}
	var _keep: Array[Texture2D] = []  # textures must outlive _draw

	func _tex(img: Image, s: int) -> Texture2D:
		var im := img.duplicate() as Image
		if s != im.get_width():
			im.resize(s, s, Image.INTERPOLATE_LANCZOS)
		var t := ImageTexture.create_from_image(im)
		_keep.append(t)
		return t

	func _slot(at: Vector2, s: int, rim: Color) -> void:
		draw_rect(Rect2(at - Vector2(3, 3), Vector2(s + 6, s + 6)), rim)
		draw_rect(Rect2(at - Vector2(1, 1), Vector2(s + 2, s + 2)), Color(0.14, 0.11, 0.11))

	func _draw() -> void:
		var font: Font = ThemeDB.fallback_font
		var rows: int = int(ceil(entries.size() / float(COLS)))
		draw_rect(Rect2(Vector2.ZERO, Vector2(COLS * CW + 16, rows * CH + 16)), Color(0.07, 0.06, 0.07))
		for i in entries.size():
			var e: Array = entries[i]
			var img: Image = e[2]
			var o := Vector2(12 + (i % COLS) * CW, 12 + (i / COLS) * CH)
			_slot(o, 128, Color(0.62, 0.40, 0.16))
			draw_texture(_tex(img, 128), o)
			draw_string(font, o + Vector2(0, 150), String(e[0]), HORIZONTAL_ALIGNMENT_LEFT, 128, 12, Color(0.6, 0.6, 0.6))
			draw_string(font, o + Vector2(0, 166), String(e[1]), HORIZONTAL_ALIGNMENT_LEFT, 136, 13, Color(0.95, 0.92, 0.88))
			var y: float = o.y
			var x: float = o.x + 140.0
			for s: int in sizes.get(e[0], [56]):
				if y + s > o.y + CH - 20:
					y = o.y
					x += 40.0
				_slot(Vector2(x, y), s, Color(0.62, 0.40, 0.16) if s >= 24 else Color(0.35, 0.30, 0.26))
				draw_texture(_tex(img, s), Vector2(x, y))
				draw_string(font, Vector2(x + s + 6, y + minf(s, 14.0)), str(s), HORIZONTAL_ALIGNMENT_LEFT, 30, 10, Color(0.55, 0.55, 0.55))
				y += s + 12.0


func _contact_sheet() -> void:
	var rows: int = int(ceil(_entries.size() / 6.0))
	var vp := SubViewport.new()
	vp.size = Vector2i(6 * 252 + 16, rows * 204 + 16)
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var d := SheetDrawer.new()
	d.entries = _entries
	d.sizes = UI_SIZES
	vp.add_child(d)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img: Image = vp.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	img.save_png(ProjectSettings.globalize_path(SHEET_PATH))
	vp.queue_free()
