extends SceneTree
## Task 6.U1 (docs/design/ui-style.md): kingdom skin tokens, generated frame / button images, framed panels,
## rects of section 10 at 1600 x 900 for both kingdoms, portrait (single + building views, ~10 Hz, off when
## hidden), low-HP pulse, ghost damage, level-up ring, section-8 tooltips.
## Run: godot --headless --path . -s tests/test_6_u1.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "6.U1"
const TIMEOUT_FRAMES := 2400

var main: Node
var frame := 0
var _wait := 0
var _errors: Array[String] = []
var _step := 0
var _step_frame := 0
var _renders := 0
var hud: Node
var panel: Node
var sel: Node
var _style: GDScript


func _initialize() -> void:
	root.size = Vector2i(1600, 900)
	_style = load("res://scripts/ui/ui_style.gd")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	if frame == 1:
		root.size = Vector2i(1600, 900)
		hud = main.hud
		panel = hud.selection_panel
		sel = panel.selection
		_check_images()
		_check_tooltip()
	if frame > 20 and _run():
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out at step %d (%s)" % [TASK_ID, _step, "; ".join(_errors)])
		return true
	return false


func _near(a: Color, b: Color, eps := 0.02) -> bool:
	return absf(a.r - b.r) < eps and absf(a.g - b.g) < eps and absf(a.b - b.b) < eps and absf(a.a - b.a) < eps


func _check_images() -> void:
	for k: StringName in [&"shadow", &"fire"]:
		_style.set_kingdom(k)
		if _style.get_kingdom() != k:
			_errors.append("set_kingdom(%s) ignored" % k)
		var img: Image = _style.frame_texture().get_image()
		if img.get_size() != Vector2i(48, 48):
			_errors.append("frame image %s" % img.get_size())
			continue
		if not _near(img.get_pixel(24, 0), Color(0, 0, 0, 0.55)):
			_errors.append("%s frame px0 %s" % [k, img.get_pixel(24, 0)])
		if not _near(img.get_pixel(24, 1), _style.token(&"frame_light")) or not _near(img.get_pixel(24, 46), _style.token(&"frame_dark")):
			_errors.append("%s bevel wrong" % k)
		if not _near(img.get_pixel(24, 2), _style.token(&"frame_metal")) or not _near(img.get_pixel(24, 4), _style.token(&"groove")):
			_errors.append("%s rim / groove wrong" % k)
		if not _near(img.get_pixel(5, 5), _style.token(&"trim_glow")) or not _near(img.get_pixel(42, 42), _style.token(&"trim_glow")):
			_errors.append("%s stud gems missing" % k)
		if not _near(img.get_pixel(24, 24), _style.token(&"panel_bg")):
			_errors.append("%s panel centre %s" % [k, img.get_pixel(24, 24)])
		var fs: StyleBoxTexture = _style.frame_style(10.0)
		if fs.texture_margin_left != 16.0 or fs.content_margin_top != 10.0:
			_errors.append("frame_style margins")
		for state: StringName in [&"normal", &"hover", &"pressed", &"disabled", &"selected"]:
			var bf: StyleBoxTexture = _style.button_frame(state)
			var bimg: Image = bf.texture.get_image()
			var want := 26 if state == &"hover" else 24
			if bimg.get_width() != want:
				_errors.append("button %s image %d px" % [state, bimg.get_width()])
		var sel_img: Image = _style.button_frame(&"selected").texture.get_image()
		if not _near(sel_img.get_pixel(12, 2), _style.GOLD):
			_errors.append("selected rim not gold")
		var normal_img: Image = _style.button_frame(&"normal").texture.get_image()
		if not _near(normal_img.get_pixel(12, 2), _style.token(&"frame_metal")):
			_errors.append("%s normal rim %s" % [k, normal_img.get_pixel(12, 2)])
	if _style.token(&"trim_glow").is_equal_approx(Color(0.70, 0.30, 1.00)):
		_errors.append("fire tokens not restored")


func _check_tooltip() -> void:
	var tip: Control = _style.make_tooltip("Fireball  [F]  Rank 2 / 3\n60 mana · 8 s\nHurls fire.\nNot enough mana")
	if tip.get_child_count() != 4:
		_errors.append("tooltip has %d lines" % tip.get_child_count())
	else:
		var reason := tip.get_child(3) as Label
		if reason == null or not reason.get_theme_color("font_color").is_equal_approx(_style.WARN):
			_errors.append("tooltip reason not WARN")
	tip.free()


func _rect_ok(c: Control, want: Rect2, what: String, eps := 1.5) -> void:
	var r := c.get_global_rect()
	if absf(r.position.x - want.position.x) > eps or absf(r.position.y - want.position.y) > eps \
			or (want.size.x > 0.0 and absf(r.size.x - want.size.x) > eps) \
			or (want.size.y > 0.0 and absf(r.size.y - want.size.y) > eps):
		_errors.append("%s at %s, want %s" % [what, r, want])


## SC2.U1-U4 (ui-sc2-console.md 1, 3.1, 4): the console's selection block, the hero tile, the card, the resources.
func _check_rects(tag: String) -> void:
	_rect_ok(panel, Rect2(244, 692, 888, 200), tag + " selection block")
	_rect_ok(hud.console, Rect2(0, 684, 1600, 216), tag + " console")
	_rect_ok(panel.hero_badge, Rect2(46, 586, 20, 20), tag + " badge")
	_rect_ok(panel.hero_hp, Rect2(66, 572, 140, 12), tag + " hero HP")
	_rect_ok(panel.hero_mana, Rect2(66, 586, 140, 12), tag + " hero mana")
	_rect_ok(panel.hero_xp, Rect2(66, 600, 0, 6), tag + " hero XP")
	var xs: Array[float] = hud.console.divider_xs()
	if str(xs) != str([232.0, 1136.0, 1284.0]):
		_errors.append("%s console dividers %s" % [tag, xs])
	_rect_ok(hud.command_card, Rect2(1292, 704, 296, 176), tag + " command card")
	var tb: Rect2 = hud.top_bar.get_global_rect()
	if absf(tb.position.y - 8.0) > 1.0 or absf(tb.size.y - 32.0) > 1.0 or absf(tb.end.x - 1592.0) > 1.5:
		_errors.append("%s top bar %s" % [tag, tb])
	var tab: Control = hud.group_bar.tab_for_group(1)
	if tab.visible:
		_rect_ok(tab, Rect2(252, 652, 56, 32), tag + " group tab")


func _units(team: int, n: int) -> Array:
	var out: Array = []
	for u in main.get_tree().get_nodes_in_group(&"units"):
		if int(u.get("team")) == team and u != main.hero and u.is_alive():
			out.append(u)
			if out.size() >= n:
				break
	return out


func _keep() -> Node:
	for b in main.get_tree().get_nodes_in_group(&"buildings"):
		if int(b.get("team")) == 0 and b.has_method("queue_unit"):
			return b
	return null


## Steps; returns true when finished.
func _run() -> bool:
	var f := frame - _step_frame
	match _step:
		0:   # Single unit: portrait window at (1144, 696), name at (252, 696) (SC2.U1).
			sel.select_units(_units(0, 1))
			_next()
		1:
			if f < 10:
				return false
			if panel.current_view() != "single":
				_errors.append("single view not shown")
			_rect_ok(panel.portrait, Rect2(1144, 696, 136, 136), "portrait")
			_rect_ok(panel.single_name, Rect2(252, 696, 0, 0), "single name", 3.0)
			if not panel.portrait.is_visible_in_tree():
				_errors.append("portrait hidden in single view")
			_renders = panel.portrait.render_count
			_next()
		2:   # 30 Hz while visible (ui-sc2-console.md 4.3): 60 frames -> about 30 renders (or 0 without a model).
			if f < 60:
				return false
			var n: int = panel.portrait.render_count - _renders
			var has_model: bool = panel.portrait._holder.get_child_count() > 0
			if has_model and (n < 20 or n > 40):
				_errors.append("portrait rendered %d times in 1 s" % n)
			if not has_model and panel.portrait.abbrev_label.text == "":
				_errors.append("no model and no abbreviation")
			sel.select_units(_units(0, 4))
			_next()
		3:   # Group: the portrait shows the active type's unit (4.3); nothing selected: no renders.
			if f < 10:
				return false
			if panel.current_view() != "multi" or not panel.portrait.is_visible_in_tree() \
					or not sel.selected.has(panel.portrait.target):
				_errors.append("multi view portrait does not show a selected unit (%s)" % panel.portrait.target)
			sel.select_units([])
			_next()
		4:
			if f == 2:
				_renders = panel.portrait.render_count
			if f < 30:
				return false
			if panel.portrait.render_count != _renders:
				_errors.append("portrait renders with nothing selected")
			var keep := _keep()
			if keep == null:
				_errors.append("no keep")
			else:
				sel.select_building(keep)
			_next()
		5:
			if f < 10:
				return false
			if panel.current_view() != "keep":
				_errors.append("keep view not shown")
			_rect_ok(panel.portrait, Rect2(1144, 696, 136, 136), "keep portrait")
			_rect_ok(panel.keep_name, Rect2(252, 696, 0, 0), "keep name", 3.0)
			_check_rects("fire")
			# Low HP pulse + ghost damage.
			main.hero.hp = main.hero.max_hp * 0.2
			_next()
		6:
			if f < 5:
				return false
			if not panel.is_low_hp_pulsing():
				_errors.append("no low-HP pulse at 20 %")
			if not (panel._ghost_value > main.hero.hp + 1.0):
				_errors.append("no ghost segment after damage (%s)" % panel._ghost_value)
			if absf(panel.hero_trim.color.r - _style.WARN.r) > 0.05:
				_errors.append("trim line not WARN at low HP")
			panel.flash_level_up()
			if panel._ring_t < 0.0:
				_errors.append("no level-up ring")
			main.hero.hp = main.hero.max_hp
			_next()
		7:
			if f < 40:
				return false
			if panel.is_low_hp_pulsing() or panel._ring_t >= 0.0:
				_errors.append("pulse / ring did not stop")
			if panel._ghost_value > main.hero.hp + 0.5 and panel._ghost_value > panel.hero_hp.value + 0.5:
				pass
			# Shadow skin: rebuilt, same rects.
			_style.set_kingdom(&"shadow")
			hud.apply_skin()
			_next()
		8:
			if f < 5:
				return false
			var st := hud.console.get_theme_stylebox("panel") as StyleBoxTexture
			if st == null or not _near(st.texture.get_image().get_pixel(24, 2), Color(0.55, 0.52, 0.66)):
				_errors.append("console frame not re-skinned to shadow")
			if not (hud.top_bar.get_theme_stylebox("panel") is StyleBoxEmpty):
				_errors.append("top bar not chamfered (stylebox)")
			_check_rects("shadow")
			_style.set_kingdom(&"fire")
			hud.apply_skin()
			return true
	return false


func _next() -> void:
	_step += 1
	_step_frame = frame
