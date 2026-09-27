extends "res://art/icons/render_icons.gd"
## Task A2.9 + 11.V7: renders only the champion icons with render_icons.gd's pipeline:
##   art/icons/units/<champion>.png   (wayfinder, oathwall, coin_cutter, mender: 3/4 bust of the model, variant 0)
##   art/icons/abilities/<id>.png     (the 12 abilities of champions.md 4.3, champion_icon_painter.gd)
##   art/icons/classes/<class_id>.png (step 11: spear, sword_shield, two_hand, wizard; bold glyphs read at 14 px)
##   art/icons/abilities/<id>.png     (step 11: the 12 class skills of skills-rework.md 4.2, in the class colour)
## and the contact sheets docs/art/screens/champion_icons.png (step 9: every icon at 128 and at its UI sizes: bar 56,
## tavern 68, ability slot 48, small 32) and docs/art/screens/champion_class_icons.png (step 11: class icons at 128 / 48 /
## 32 / the 16 px badge (14 px icon) + a x4 zoom of that badge; class skills at 128 / slot 48 / 36 / 32 / locked 48).
## Must run WINDOWED (needs the renderer):
##   Godot_v4.7.2-stable_win64.exe --path . --script art/icons/render_champion_icons.gd --fixed-fps 60 --quit-after 3000
## then `--headless --path . --import` so Godot imports the new PNGs. A full render_icons.gd run renders the step-9 set.
## Optional user args: `-- set=classes` (only the 16 step-11 icons + their sheet), `-- set=step9` (only the step-9 set).

const CHAMP_SHEET := "res://docs/art/screens/champion_icons.png"
const CLASS_SHEET := "res://docs/art/screens/champion_class_icons.png"
## Step 11 (skills-rework.md 4.2): class id -> its 3 class skills in unlock order (levels 2, 3, 5).
const CLASS_SKILLS := {
	&"spear": [&"lunge", &"hobbling_javelin", &"skewer"],
	&"sword_shield": [&"riposte", &"second_wind", &"shield_throw"],
	&"two_hand": [&"cleave", &"crushing_blow", &"whirlwind"],
	&"wizard": [&"arc_bolt", &"slipstep", &"starfall"],
}

var _do_step9: bool = true
var _do_classes: bool = true


## Optional `-- ids=oathwall,lifeline,spear` re-renders only those; the sheets then read the others from disk.
## Optional `-- frame=<champion>:<centre y>,<half-height>,<yaw>,<pitch>` tries a framing without editing CHAMPIONS.
func _initialize() -> void:
	_only_kinds.assign(["units", "abilities", "classes"])
	var ids: Array[String] = []
	for c in CHAMPIONS:
		ids.append(String(c))
	for a in ABILITIES:
		ids.append(String(a))
	for cid in CLASS_SKILLS:
		ids.append(String(cid))
		for sid in CLASS_SKILLS[cid]:
			ids.append(String(sid))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("ids="):
			ids.assign(arg.trim_prefix("ids=").split(",", false))
		elif arg == "set=classes":
			_do_step9 = false
		elif arg == "set=step9":
			_do_classes = false
		elif arg.begins_with("frame="):
			# Tuning: frame=oathwall:1.7,0.58,30,8 (centre height, half-height, yaw, pitch) overrides CHAMPIONS.
			var kv: PackedStringArray = arg.trim_prefix("frame=").split(":")
			var nums: Array = []
			for s in kv[1].split(","):
				nums.append(float(s))
			_frame_override[StringName(kv[0])] = nums
	_only_ids.assign(ids)
	_run.call_deferred()


func _run() -> void:
	await process_frame
	if _do_step9:
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
		await _contact_sheet()
	if _do_classes:
		for cid in CLASS_SKILLS:
			if _wanted(&"classes", cid):
				await _paint(&"classes", cid, cid, 0)
			for sid in CLASS_SKILLS[cid]:
				if _wanted(&"abilities", sid):
					await _paint(&"abilities", sid, cid, 0)
		await _class_sheet()
	print("ICONS DONE: %d icons" % _entries.size())
	quit()


## Class icons and class skills are painted by champion_icon_painter.gd (render_icons.gd only routes champion ids there).
func _painted_image(kind: StringName, id: StringName, faction: StringName, tier: int) -> Image:
	if kind != &"classes" and not CLASS_SKILLS.has(faction):
		return await super._painted_image(kind, id, faction, tier)
	var vp := _new_viewport(true)
	var p: Node2D = ChampPainter.new()
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


class ChampSheet extends Node2D:
	var entries: Array = []
	var abilities: Dictionary = {}
	var champions: Array = []
	const ROW_H := 236
	const RIM := Color(0.62, 0.40, 0.16)
	const INNER := Color(0.14, 0.11, 0.11)
	var _keep: Array[Texture2D] = []

	func _img(id: StringName) -> Image:
		for e in entries:
			if e[1] == id:
				return e[2]
		var kind: String = "abilities" if abilities.has(id) else "units"
		var p: String = ProjectSettings.globalize_path("res://art/icons/%s/%s.png" % [kind, id])
		return Image.load_from_file(p) if FileAccess.file_exists(p) else null

	func _tile(img: Image, at: Vector2, size: int, rim: Color = RIM, inset: int = 3) -> void:
		draw_rect(Rect2(at, Vector2(size + inset * 2, size + inset * 2)), rim)
		draw_rect(Rect2(at + Vector2(2, 2), Vector2(size + inset * 2 - 4, size + inset * 2 - 4)), INNER)
		if img == null:
			return
		var s := img.duplicate() as Image
		if size != s.get_width():
			s.resize(size, size, Image.INTERPOLATE_LANCZOS)
		var t := ImageTexture.create_from_image(s)
		_keep.append(t)
		draw_texture(t, at + Vector2(inset, inset))

	func _draw() -> void:
		var font: Font = ThemeDB.fallback_font
		draw_rect(Rect2(0, 0, 2000, 2000), Color(0.07, 0.06, 0.07))
		draw_string(font, Vector2(16, 26), "Champion icons (A2.9): 128 px | tavern 68 | bar 56 | slot 48 | 32", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.95, 0.9, 0.8))
		for r in champions.size():
			var cid: StringName = champions[r]
			var o := Vector2(16, 44 + r * ROW_H)
			var p: Image = _img(cid)
			_tile(p, o, 128)
			_tile(p, o + Vector2(142, 0), 68, Color(0.85, 0.72, 0.40), 4)
			_tile(p, o + Vector2(142, 84), 56, RIM, 3)
			_tile(p, o + Vector2(142, 152), 32, Color(0.85, 0.85, 0.85), 2)
			draw_string(font, o + Vector2(0, 156), String(cid), HORIZONTAL_ALIGNMENT_LEFT, 136, 13, Color(0.95, 0.92, 0.88))
			var j: int = 0
			for aid in abilities:
				if abilities[aid] != cid:
					continue
				var ao: Vector2 = o + Vector2(240 + j * 150, 0)
				var a: Image = _img(aid)
				_tile(a, ao, 128)
				_tile(a, ao + Vector2(0, 142), 48, RIM, 4)
				_tile(a, ao + Vector2(64, 142), 32, Color(0.85, 0.85, 0.85), 2)
				draw_string(font, ao + Vector2(0, 216), String(aid), HORIZONTAL_ALIGNMENT_LEFT, 146, 13, Color(0.95, 0.92, 0.88))
				j += 1


func _contact_sheet() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(16 + 240 + 3 * 150, 44 + CHAMPIONS.size() * ChampSheet.ROW_H)
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var d := ChampSheet.new()
	d.entries = _entries
	d.abilities = ABILITIES
	d.champions = CHAMPIONS.keys()
	vp.add_child(d)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img: Image = vp.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	img.save_png(ProjectSettings.globalize_path(CHAMP_SHEET))
	vp.queue_free()


# ---------------------------------------------------------------- step 11 contact sheet
## One row per class: the class icon at 128, slot 48, 32 and inside the real 16 x 16 badge (14 px icon, bg black 0.75,
## 1 px frame_dark border, like ui-champions.md 15.1), then its 3 skills at 128, in a 48 slot (40 px icon inset 4),
## 36, 32 and locked (48 slot at alpha 0.45). Every small copy is drawn the way the UI draws it: a mipmapped texture
## scaled with LINEAR_WITH_MIPMAPS. The x4 zooms of the badges are pasted after the capture (nearest).
class ClassSheet extends Node2D:
	var entries: Array = []
	var classes: Dictionary = {}
	const ROW_H := 236
	const RIM := Color(0.62, 0.40, 0.16)
	const INNER := Color(0.14, 0.11, 0.11)
	const FRAME_DARK := Color(0.16, 0.12, 0.09)
	const PANEL := Color(0.17, 0.14, 0.12)
	var badge_spots: Array[Vector2] = []   # where the 16 px badges are (read back by the renderer for the zoom)
	var zoom_spots: Array[Vector2] = []
	var _keep: Array[Texture2D] = []
	var _tex: Dictionary = {}

	func _init() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	func _texture(kind: String, id: StringName) -> Texture2D:
		if _tex.has(id):
			return _tex[id]
		var img: Image = null
		for e in entries:
			if e[1] == id and String(e[0]) == kind:
				img = (e[2] as Image).duplicate()
		if img == null:
			var p: String = ProjectSettings.globalize_path("res://art/icons/%s/%s.png" % [kind, id])
			img = Image.load_from_file(p) if FileAccess.file_exists(p) else null
		var t: Texture2D = null
		if img != null:
			img.generate_mipmaps()
			t = ImageTexture.create_from_image(img)
			_keep.append(t)
		_tex[id] = t
		return t

	func _tile(t: Texture2D, at: Vector2, size: int, rim: Color = RIM, inset: int = 3, alpha: float = 1.0) -> void:
		draw_rect(Rect2(at, Vector2(size + inset * 2, size + inset * 2)), rim)
		draw_rect(Rect2(at + Vector2(2, 2), Vector2(size + inset * 2 - 4, size + inset * 2 - 4)), INNER)
		if t != null:
			draw_texture_rect(t, Rect2(at + Vector2(inset, inset), Vector2(size, size)), false, Color(1, 1, 1, alpha))

	## The bar / tavern badge: 16 x 16, bg (0, 0, 0, 0.75) on the panel, 1 px frame_dark border, icon 14 inset 1.
	func _badge(t: Texture2D, at: Vector2) -> void:
		draw_rect(Rect2(at - Vector2(6, 6), Vector2(28, 28)), PANEL)
		draw_rect(Rect2(at, Vector2(16, 16)), FRAME_DARK)
		draw_rect(Rect2(at + Vector2(1, 1), Vector2(14, 14)), Color(0, 0, 0, 0.75))
		if t != null:
			draw_texture_rect(t, Rect2(at + Vector2(1, 1), Vector2(14, 14)), false)
		badge_spots.append(at - Vector2(6, 6))

	func _draw() -> void:
		var font: Font = ThemeDB.fallback_font
		var txt := Color(0.95, 0.92, 0.88)
		var muted := Color(0.6, 0.58, 0.55)
		draw_rect(Rect2(0, 0, 3000, 3000), Color(0.07, 0.06, 0.07))
		draw_string(font, Vector2(16, 26), "Champion classes (11.V7): class 128 | 48 | 32 | badge 16 (14 px) + x4 zoom      class skills: 128 | slot 48 | 36 | 32 | locked",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.95, 0.9, 0.8))
		var r: int = 0
		for cid in classes:
			var o := Vector2(16, 44 + r * ROW_H)
			var ct: Texture2D = _texture("classes", cid)
			_tile(ct, o, 128)
			_tile(ct, o + Vector2(142, 0), 48, RIM, 3)
			_tile(ct, o + Vector2(142, 62), 32, Color(0.85, 0.85, 0.85), 2)
			_badge(ct, o + Vector2(196, 70))
			zoom_spots.append(o + Vector2(142, 108))
			draw_string(font, o + Vector2(0, 156), String(cid), HORIZONTAL_ALIGNMENT_LEFT, 136, 14, txt)
			draw_string(font, o + Vector2(142, 232), "badge x4", HORIZONTAL_ALIGNMENT_LEFT, 112, 11, muted)
			var j: int = 0
			for sid in classes[cid]:
				var ao: Vector2 = o + Vector2(270 + j * 196, 0)
				var st: Texture2D = _texture("abilities", sid)
				_tile(st, ao, 128)
				_tile(st, ao + Vector2(0, 142), 40, RIM, 4)
				_tile(st, ao + Vector2(56, 142), 36, Color(0.85, 0.85, 0.85), 1)
				_tile(st, ao + Vector2(102, 142), 32, Color(0.85, 0.85, 0.85), 2)
				_tile(st, ao + Vector2(142, 0), 40, RIM, 4, 0.45)
				draw_string(font, ao + Vector2(142, 62), "L%d" % [2, 3, 5][j], HORIZONTAL_ALIGNMENT_LEFT, 40, 12, Color(1.0, 0.8, 0.3))
				draw_string(font, ao + Vector2(0, 208), String(sid), HORIZONTAL_ALIGNMENT_LEFT, 190, 13, txt)
				j += 1
			r += 1


func _class_sheet() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(16 + 270 + 3 * 196, 44 + CLASS_SKILLS.size() * ClassSheet.ROW_H)
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var d := ClassSheet.new()
	d.entries = _entries
	d.classes = CLASS_SKILLS
	vp.add_child(d)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img: Image = vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	for i in d.badge_spots.size():
		var crop: Image = img.get_region(Rect2i(Vector2i(d.badge_spots[i]), Vector2i(28, 28)))
		crop.resize(112, 112, Image.INTERPOLATE_NEAREST)
		img.blit_rect(crop, Rect2i(0, 0, 112, 112), Vector2i(d.zoom_spots[i]))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	img.save_png(ProjectSettings.globalize_path(CLASS_SHEET))
	vp.queue_free()
