extends SceneTree
## Renders every HUD icon to res://art/icons/<kind>/<id>.png (128 x 128, transparent) and a contact sheet
## to res://docs/art/screens/icons_sheet.png. Must run WINDOWED (needs the renderer):
##   Godot_v4.7.2-stable_win64.exe --path . --script art/icons/render_icons.gd --quit-after 6000
## 2D icons are painted by icon_painter.gd at 256 px and downsampled. Buildings, units and the four wizards
## (art/units/<group>/<id>.tscn) are rendered from their model scenes in 3/4 view through a SubViewport.
## Optional user args to re-render a subset (the sheet then goes to icons_sheet_wip.png, or to sheet=res://...):
##   ... --script art/icons/render_icons.gd --quit-after 6000 -- kinds=units,buildings ids=torvald,ice_keep
## Champions (units/<champion>.png busts) and their abilities (abilities/<id>.png): render_champion_icons.gd.

const Painter := preload("res://art/icons/icon_painter.gd")
const ChampPainter := preload("res://art/icons/champion_icon_painter.gd")
const OUT := "res://art/icons/"
const SHEET_PATH := "res://docs/art/screens/icons_sheet.png"
const SHEET_WIP_PATH := "res://docs/art/screens/icons_sheet_wip.png"
const BIG := 256
const SIZE := 128
const ORDERS: Array[StringName] = [&"move", &"stop", &"hold", &"attack_move", &"attack", &"gather", &"build", &"rally", &"cancel", &"back"]
const SPELL_FACTIONS := {
	&"shadow_lance": &"shadow", &"soul_siphon": &"shadow", &"umbral_shroud": &"shadow",
	&"rime_bolt": &"ice", &"flash_freeze": &"ice", &"rime_aegis": &"ice",
	&"thornburst": &"nature", &"wild_bloom": &"nature", &"call_the_thicket": &"nature",
}
## Items designed but whose .tres may not exist yet (id -> tier). Painted anyway so the icon is ready.
const EXTRA_ITEMS := {&"stillwater_orb": 4}
## Wizards have no UnitType .tres: rendered as units/<id>.png with a face close-up.
const WIZARDS := {&"vessa": &"fire", &"malrik": &"shadow", &"torvald": &"ice", &"ysolde": &"nature"}
## Champions (task A2.9): units/<id>.png = a 3/4 bust of art/units/champions/<id>/<id>.tscn (variant 0, neutral sash)
## over a background in the champion's colour code (champion_icon_painter.gd). Framing per champion, model space:
## [bust centre height m, half-height framed m, yaw deg, pitch deg, optional rim-light energy].
const CHAMPIONS := {
	&"wayfinder": [1.48, 0.55, 28.0, 10.0],
	&"oathwall": [1.68, 0.54, 30.0, 6.0, 1.4],   # 3/4 from its right: whole helm + lid, visor, beard; rim light 1.4
	&"coin_cutter": [1.36, 0.54, 28.0, 10.0],
	&"mender": [1.34, 0.56, 30.0, 10.0],
}
## Kingdom-agnostic sash / pennant colour for the portraits (weathered guild ochre).
const CHAMPION_SASH := Color(0.66, 0.50, 0.26)
## abilities/<id>.png (champions.md 4.3), painted in the owner's colour code. id -> champion id.
const ABILITIES := {
	&"flare_arrow": &"wayfinder", &"snare_line": &"wayfinder", &"trailblaze": &"wayfinder",
	&"oath_of_iron": &"oathwall", &"shield_bash": &"oathwall", &"bulwark_stand": &"oathwall",
	&"cutpurse": &"coin_cutter", &"smoke_pouch": &"coin_cutter", &"marked_for_coin": &"coin_cutter",
	&"mending_draught": &"mender", &"soothing_circle": &"mender", &"lifeline": &"mender",
}
## Per-unit framing: [centre height ratio, radius x height ratio, yaw deg, width ratio (0.42), pitch deg (20), dx m, dz m,
## whole height 0/1]. Default [0.58, 0.44, 30]. A small width ratio drops a mount's length so the icon frames the rider.
const UNIT_FRAMING := {
	&"rime_seer": [0.6, 0.36, 30.0],
	# Riders and big units: the rider's head and upper body (2026-10-13, Wave Strike panel / Unit Guide icons).
	&"barrow_knight": [0.70, 0.33, 30.0, 0.0, 12.0, 0.0, 0.0, 1],
	&"veilborn_dreadrider": [0.70, 0.33, 30.0, 0.0, 12.0, 0.0, 0.0, 1],
	&"gloam_rider": [0.48, 0.27, 30.0, 0.0, 12.0, 0.0, 0.0, 1],   # its tall lance would push the rider down
	&"snowdrift_rider": [0.70, 0.32, 30.0, 0.0, 12.0, 0.0, 0.0, 1],
	&"rimehorn_rider": [0.70, 0.32, 30.0, 0.0, 12.0, 0.0, 0.0, 1],
	&"stagrunner": [0.70, 0.32, 30.0, 0.0, 12.0, 0.0, 0.0, 1],
	&"glade_outrider": [0.70, 0.32, 30.0, 0.0, 12.0, 0.0, 0.0, 1],
	&"sunforge_cataphract": [0.70, 0.32, 30.0, 0.0, 12.0, 0.0, 0.0, 1],
	&"frostcrown_juggernaut": [0.68, 0.36, 30.0, 0.0, 12.0, 0.0, 0.0, 1],
	&"briar_roc": [0.62, 0.40, 30.0, 0.14, 20.0],   # body and inner wings; the full span is unreadable at 64 px
	# Infantry / casters with tall staffs or bows: a little tighter than the default.
	&"pyre_adept": [0.62, 0.36, 30.0],
	&"wildwood_archer": [0.62, 0.36, 30.0],
	&"vinelasher": [0.62, 0.36, 30.0],
	&"bleakbow": [0.62, 0.36, 30.0],
	&"hexweaver": [0.62, 0.36, 30.0],
	&"gloom_deacon": [0.62, 0.36, 30.0],
	&"kilnwarden": [0.62, 0.36, 30.0],
	&"rimecarver": [0.62, 0.36, 30.0],
	&"shardguard": [0.62, 0.36, 30.0],
	&"nightblood_reaver": [0.62, 0.36, 30.0],
	&"bramblesage": [0.62, 0.36, 30.0],
}
## Building ids whose BuildingType has no model_scene yet, mapped to the art scene that will be plugged in.
## Trade icons (10.V12) come from art/icons/render_trade_icons.gd (their models live in sub-folders and need their own
## framing): skipped here so a full run does not overwrite them with placeholders.
const TRADE_IDS: Array[StringName] = [&"caravan", &"magpie", &"greywater_tracker", &"fire_market", &"shadow_market",
	&"ice_market", &"nature_market"]
const BUILDING_SCENES := {
	&"fire_barracks": "res://art/buildings/fire_hall.tscn",
	&"fire_hearth": "res://art/buildings/hearth.tscn",
	&"fire_tower": "res://art/buildings/fire_tower.tscn",
	&"shadow_barracks": "res://art/buildings/shadow_hall.tscn",
	&"shadow_hovel": "res://art/buildings/hovel.tscn",
	&"shadow_tower": "res://art/buildings/shadow_tower.tscn",
}

var _entries: Array = []  # [kind, id, Image]
var _only_kinds: Array[String] = []
var _only_ids: Array[String] = []
var _sheet_override: String = ""  # sheet=res://... user arg: where the contact sheet goes
var _frame_override: Dictionary = {}  # champion id -> framing array (render_champion_icons.gd `frame=` arg, for tuning)


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("kinds="):
			_only_kinds.assign(a.trim_prefix("kinds=").split(",", false))
		elif a.begins_with("ids="):
			_only_ids.assign(a.trim_prefix("ids=").split(",", false))
		elif a.begins_with("sheet="):
			_sheet_override = a.trim_prefix("sheet=")
	_run.call_deferred()


func _wanted(kind: StringName, id: StringName) -> bool:
	if not _only_kinds.is_empty() and not _only_kinds.has(String(kind)):
		return false
	return _only_ids.is_empty() or _only_ids.has(String(id))


func _run() -> void:
	await process_frame
	for id in _ids("res://data/spells"):
		if _wanted(&"spells", id):
			await _paint(&"spells", id, SPELL_FACTIONS.get(id, &"fire"), 0)
	var item_ids: Array[StringName] = _ids("res://data/items")
	for extra in EXTRA_ITEMS:
		if not item_ids.has(extra):
			item_ids.append(extra)
	for id in item_ids:
		if not _wanted(&"items", id):
			continue
		var tier: int = int(EXTRA_ITEMS.get(id, 0))
		var p: String = "res://data/items/%s.tres" % id
		if ResourceLoader.exists(p):
			var res: Resource = load(p)
			var t: Variant = res.get("tier") if res else null
			tier = int(t) if t != null else 0
		await _paint(&"items", id, &"fire", tier)
	for id in ORDERS:
		if _wanted(&"orders", id):
			await _paint(&"orders", id, &"fire", 0)
	for id in WIZARDS:
		if not _wanted(&"units", id):
			continue
		var wp: String = _unit_scene(id)
		if wp != "":
			await _render_model(&"units", id, WIZARDS[id], load(wp) as PackedScene, true, true)
		else:
			await _paint(&"units", id, WIZARDS[id], 0)
	for id in CHAMPIONS:
		if not _wanted(&"units", id):
			continue
		var cp: String = "res://art/units/champions/%s/%s.tscn" % [id, id]
		if ResourceLoader.exists(cp):
			await _render_model(&"units", id, id, load(cp) as PackedScene, true)
		else:
			await _paint(&"units", id, id, 0)
	for id in ABILITIES:
		if _wanted(&"abilities", id):
			await _paint(&"abilities", id, ABILITIES[id], 0)
	for id in _ids("res://data/units"):
		if not _wanted(&"units", id) or TRADE_IDS.has(id):
			continue
		var res: Resource = load("res://data/units/%s.tres" % id)
		var f: StringName = StringName(str(res.get("faction"))) if res else &"fire"
		var scene_path: String = _unit_scene(id)
		if scene_path != "":
			await _render_model(&"units", id, f, load(scene_path) as PackedScene, true)
		else:
			await _paint(&"units", id, f, 0)
	for id in _ids("res://data/buildings"):
		if not _wanted(&"buildings", id) or TRADE_IDS.has(id):
			continue
		var res: Resource = load("res://data/buildings/%s.tres" % id)
		var f: StringName = StringName(str(res.get("faction"))) if res else &"fire"
		var scene: PackedScene = res.get("model_scene") as PackedScene if res else null
		if scene == null and BUILDING_SCENES.has(id) and ResourceLoader.exists(BUILDING_SCENES[id]):
			scene = load(BUILDING_SCENES[id]) as PackedScene
		if scene != null:
			await _render_model(&"buildings", id, f, scene, false)
		else:
			await _paint(&"buildings", id, f, 0)
	await _contact_sheet()
	print("ICONS DONE: %d icons" % _entries.size())
	quit()


func _ids(dir_path: String) -> Array[StringName]:
	var names: Array[String] = []
	for f in DirAccess.get_files_at(dir_path):
		if f.ends_with(".tres"):
			names.append(f.get_basename())
	names.sort()
	var out: Array[StringName] = []
	for n in names:
		out.append(StringName(n))
	return out


func _unit_scene(id: StringName) -> String:
	var base := "res://art/units/"
	for group in DirAccess.get_directories_at(base):
		var p: String = base + group + "/" + String(id) + ".tscn"
		if ResourceLoader.exists(p):
			return p
		var sub: String = base + group + "/" + String(id) + "/" + String(id) + ".tscn"  # newer models: own folder
		if ResourceLoader.exists(sub):
			return sub
	return ""


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


func _painted_image(kind: StringName, id: StringName, faction: StringName, tier: int) -> Image:
	var vp := _new_viewport(true)
	var p: Node2D = ChampPainter.new() if (kind == &"abilities" or CHAMPIONS.has(faction)) else Painter.new()
	p.set("kind", kind)
	p.set("id", id)
	p.set("faction", faction)
	p.set("tier", tier)
	vp.add_child(p)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img: Image = vp.get_texture().get_image()
	vp.queue_free()
	img.convert(Image.FORMAT_RGBA8)
	return img


func _paint(kind: StringName, id: StringName, faction: StringName, tier: int) -> void:
	var img: Image = await _painted_image(kind, id, faction, tier)
	_save(kind, id, img)


func _render_model(kind: StringName, id: StringName, faction: StringName, scene: PackedScene, is_unit: bool, face: bool = false) -> void:
	var vp := _new_viewport(false)
	var model: Node = scene.instantiate()
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
	# Let spawn animations settle (the Sapling grows 0.2 -> 1.0 in 0.5 s) before measuring.
	var champ: bool = CHAMPIONS.has(id)
	if champ:
		if model.has_method(&"set_variant"):
			model.call(&"set_variant", 0)
		if model.has_method(&"set_team_color"):
			model.call(&"set_team_color", CHAMPION_SASH)
	await create_timer(0.9 if is_unit else 0.3).timeout
	if is_unit:
		_hide_particles(model)  # motes / pollen read as noise squares at icon size
	var box: AABB = _model_aabb(model)
	var center: Vector3 = box.get_center()
	var radius: float = box.size.length() * 0.5
	var pitch: float = deg_to_rad(25.0)
	var yaw: float = deg_to_rad(30.0)
	var head: Node = model.find_child("Head", true, false)
	if champ:
		# Champions: 3/4 bust (hat / helm / hood, face and shoulders), centred on the head in x / z.
		var fr: Array = _frame_override.get(id, CHAMPIONS[id])
		if head != null:
			var hc: Vector3 = _model_aabb(head).get_center()
			center.x = hc.x
			center.z = hc.z
		center.y = float(fr[0])
		radius = float(fr[1])
		yaw = deg_to_rad(float(fr[2]))
		pitch = deg_to_rad(float(fr[3]))
		if fr.size() > 4 and float(fr[4]) > 0.0:
			# Optional rim light (5th value = energy) from behind-left of the model, travelling toward the camera:
			# a pale edge that cuts a grey silhouette out of the halo.
			var rim := DirectionalLight3D.new()
			rim.light_color = Color(0.85, 0.93, 1.0)
			rim.light_energy = float(fr[4])
			rim.rotation_degrees = Vector3(-28.0, float(fr[2]) + 180.0 - 40.0, 0.0)
			vp.add_child(rim)
	elif face and head != null:
		# Wizards: face close-up (head, hat / crown and the top of the shoulders).
		var hb: AABB = _model_aabb(head)
		center = hb.get_center()
		center.y = hb.position.y + hb.size.y * 0.48
		radius = maxf(hb.size.y * 0.62, maxf(hb.size.x, hb.size.z) * 0.52)
		pitch = deg_to_rad(10.0)
		yaw = deg_to_rad(24.0)
	elif is_unit:
		# Upper body for tall units, whole body for wide ones (hounds, riders): readable at 40 px.
		# Tall held props (Ash Hurler's ball, Rime Seer's hook) must not shrink the body: cap the framed
		# height at 1.3 x the top of the head.
		var h: float = box.size.y
		if head != null:
			var hb: AABB = _model_aabb(head)
			h = minf(h, (hb.end.y - box.position.y) * 1.3)
			var hc: Vector3 = hb.get_center()
			center.x = lerpf(center.x, hc.x, 0.5)
			center.z = lerpf(center.z, hc.z, 0.5)
		# [centre height ratio, radius x height ratio, yaw deg, optional width ratio (0.42), optional pitch deg (20),
		#  optional x / z offset of the centre in metres]. A small width ratio frames a rider / big unit's upper body.
		var fr: Array = _unit_framing(id)
		if fr.size() > 7 and float(fr[7]) > 0.0:
			# 8th value 1 = frame on the whole height, centred on the box (riders: the Head found may be the mount's).
			h = box.size.y
			center.x = box.get_center().x
			center.z = box.get_center().z
		center.y = box.position.y + h * float(fr[0])
		var wr: float = float(fr[3]) if fr.size() > 3 else 0.42
		radius = maxf(h * float(fr[1]), maxf(box.size.x, box.size.z) * wr)
		pitch = deg_to_rad(float(fr[4]) if fr.size() > 4 else 20.0)
		yaw = deg_to_rad(float(fr[2]))
		if fr.size() > 6:
			center.x += float(fr[5])
			center.z += float(fr[6])
	else:
		# Ignore the flat contact decal: frame on the tallest dimension mostly.
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
	var bg: Image = await _painted_image(&"bg", id, faction, 0)
	bg.blend_rect(shot, Rect2i(0, 0, BIG, BIG), Vector2i.ZERO)
	_save(kind, id, bg)


## Unit framing (see _render_model). render_unit_icons.gd overrides it with its own per-unit table.
func _unit_framing(id: StringName) -> Array:
	return UNIT_FRAMING.get(id, [0.58, 0.44, 30.0])


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
	var err: Error = img.save_png(ProjectSettings.globalize_path(path))
	if err != OK:
		push_error("icon save failed: " + path)
	_entries.append([kind, id, img])


# ---------------------------------------------------------------- contact sheet
class SheetDrawer extends Node2D:
	var entries: Array = []
	const COLS := 12
	const CW := 150
	const CH := 214

	var _keep: Array[Texture2D] = []  # textures must outlive _draw

	func _draw() -> void:
		var font: Font = ThemeDB.fallback_font
		draw_rect(Rect2(Vector2.ZERO, Vector2(COLS * CW + 16, 4000)), Color(0.07, 0.06, 0.07))
		for i in entries.size():
			var e: Array = entries[i]
			var img: Image = e[2]
			var tex := ImageTexture.create_from_image(img)
			var small := img.duplicate() as Image
			small.resize(56, 56, Image.INTERPOLATE_LANCZOS)
			var tiny := img.duplicate() as Image
			tiny.resize(32, 32, Image.INTERPOLATE_LANCZOS)
			var small_tex := ImageTexture.create_from_image(small)
			var tiny_tex := ImageTexture.create_from_image(tiny)
			_keep.append_array([tex, small_tex, tiny_tex])
			var o := Vector2(8 + (i % COLS) * CW, 8 + (i / COLS) * CH)
			draw_rect(Rect2(o, Vector2(136, 136)), Color(0.62, 0.40, 0.16))
			draw_rect(Rect2(o + Vector2(3, 3), Vector2(130, 130)), Color(0.14, 0.11, 0.11))
			draw_texture(tex, o + Vector2(4, 4))
			draw_rect(Rect2(o + Vector2(0, 142), Vector2(64, 64)), Color(0.62, 0.40, 0.16))
			draw_rect(Rect2(o + Vector2(3, 145), Vector2(58, 58)), Color(0.14, 0.11, 0.11))
			draw_texture(small_tex, o + Vector2(4, 146))
			draw_rect(Rect2(o + Vector2(72, 142), Vector2(36, 36)), Color(0.85, 0.85, 0.85))
			draw_rect(Rect2(o + Vector2(74, 144), Vector2(32, 32)), Color(0.14, 0.11, 0.11))
			draw_texture(tiny_tex, o + Vector2(74, 144))
			draw_string(font, o + Vector2(72, 192), String(e[0]).left(5), HORIZONTAL_ALIGNMENT_LEFT, 76, 11, Color(0.6, 0.6, 0.6))
			draw_string(font, o + Vector2(72, 206), String(e[1]), HORIZONTAL_ALIGNMENT_LEFT, 78, 11, Color(0.95, 0.92, 0.88))


func _contact_sheet() -> void:
	var rows: int = int(ceil(_entries.size() / 12.0))
	var vp := SubViewport.new()
	vp.size = Vector2i(12 * 150 + 16, rows * 214 + 16)
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var d := SheetDrawer.new()
	d.entries = _entries
	vp.add_child(d)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img: Image = vp.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	var sheet: String = SHEET_PATH if _only_kinds.is_empty() and _only_ids.is_empty() else SHEET_WIP_PATH
	if _sheet_override != "":
		sheet = _sheet_override
	img.save_png(ProjectSettings.globalize_path(sheet))
	vp.queue_free()
