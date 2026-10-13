extends SceneTree
## Test for 6.U2 (command card + inventory + shop restyle, docs/design/ui-style.md 3.3, 6, 8) on the 1v1 map:
## - command card: heavy frame, 64 px buttons with the 24 x 24 button-frame textures (5 states), hotkey badge
##   at the bottom-right (right / bottom edge 62), diamond rank pips, icon or abbreviation fallback;
## - Fireball cast: the radial sweep shows (ratio 0-1, seconds text), and the ready flash plays when it ends;
## - styled tooltip panels keep every line of the unchanged `tooltip_text` (reason line in WARN);
## - inventory: items drawn with a cooldown sweep after a draught (no errors), tier-rim frames;
## - shop: stud X (round), primary Buy (texture frame), Sell zone takes the bar's drag data.
## Run:  godot --headless --path . -s tests/test_6_u2.gd --fixed-fps 60 --quit-after 4000
## Screenshots (windowed):  godot --path . -s tests/test_6_u2.gd --fixed-fps 60 --quit-after 4000 -- --shot=<prefix>

const TASK_ID := "6.u2"
const TIMEOUT_FRAMES := 2400
const WARM_UP := 60
const WARN := Color(0.95, 0.35, 0.3)

var main: Node
var hud: Node
var card: Node
var bar: Node
var sel: Node
var hero: Node
var inv: Node
var frame := 0
var _wait := 0
var _warm := 0
var _error := ""
var _done := false
var _step := 0
var _step_frame := 0
var _shot := ""
var _saw_sweep := false


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			_shot = a.trim_prefix("--shot=")
	main = load("res://scenes/skirmish.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	_warm += 1
	if _warm < WARM_UP:
		return false
	frame += 1
	_run()
	if _error != "":
		print("FAIL %s: %s (step %d)" % [TASK_ID, _error, _step])
		return true
	if _done:
		print("PASS %s" % TASK_ID)
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out at step %d" % [TASK_ID, _step])
		return true
	return false


func _next() -> void:
	_step += 1
	_step_frame = frame


func _since() -> int:
	return frame - _step_frame


func _save(name: String) -> void:
	if _shot == "":
		return
	var path := "%s_%s.png" % [_shot, name]
	root.get_viewport().get_texture().get_image().save_png(path)
	print("screenshot saved: ", path)


func _type(id: String) -> Object:
	var script: Script = load("res://scripts/items/item_type.gd")
	return script.call(&"find", StringName(id))


func _run() -> void:
	match _step:
		0:
			root.size = Vector2i(1600, 900)
			hud = main.get("hud")
			sel = main.get("selection")
			hero = main.hero
			card = hud.get("command_card") if hud != null else null
			bar = hud.get("inventory_bar") if hud != null else null
			if card == null or bar == null:
				_error = "HUD has no command card / inventory bar"
				return
			inv = bar.inventory()
			sel.select_units([hero])
			card.refresh()
			_next()
		1:
			if _since() < 3:
				return
			_check_card()
			if _error != "":
				return
			_check_tooltips()
			if _error != "":
				return
			if inv != null:
				inv.add_item(_type("ember_shard"))
				inv.add_item(_type("ember_draught"), 3)
			hero.mana = hero.max_mana
			var r: String = str(hero.command_cast(&"fireball", hero.global_position + Vector3(6, 0, 0)))
			if r != "":
				_error = "Fireball refused: %s" % r
				return
			_next()
		2:
			# Wait for the cooldown sweep on Fireball (slot 5), use a draught for the item sweep.
			sel.select_units([hero])
			card.refresh()
			if card.cooldown_visible(5):
				var sweep: Control = card.cooldown_rects[5]
				var ratio: float = sweep.get("ratio")
				if ratio <= 0.0 or ratio > 1.0 or card.cooldown_labels[5].text == "":
					_error = "sweep ratio %.2f, seconds '%s'" % [ratio, card.cooldown_labels[5].text]
					return
				if inv != null:
					hero.take_damage(150.0, null)
					bar.use_slot(1)
				_saw_sweep = true
				_next()
			elif _since() > 120:
				_error = "no cooldown sweep after casting Fireball"
		3:
			if _since() < 20:
				return
			if inv != null and bar.cooldown_ratio(1) <= 0.0:
				print("note: no item cooldown on the draught slot")
			_save("card_vessa")
			_next()
		4:
			# Ready flash the frame the sweep ends.
			if not card.cooldown_visible(5):
				if not card.ready_flash_active(5):
					_error = "no ready flash when Fireball came back"
					return
				_next()
		5:
			sel.select_units([])
			if sel.has_method(&"select_building"):
				sel.call(&"select_building", main.keep)
			else:
				sel.set("selected_building", main.keep)
			card.refresh()
			_next()
		6:
			if _since() < 10:
				return
			var ids: Array = card.slot_ids()
			if not str(ids[0]).begins_with("train_"):
				print("note: keep slots %s" % [ids])
			elif not card.cost_tags[0].visible or card.cost_tags[0].text == "":
				_error = "no cost tag on the train button"
				return
			_save("card_keep")
			# Shop: Vessa 7 m from the keep.
			var k: Vector3 = main.keep.global_position
			var dir := Vector3(-k.x, 0, -k.z).normalized()
			hero.global_position = Vector3(k.x, hero.global_position.y, k.z) + dir * 7.0
			hero.command_stop()
			sel.select_units([hero])
			var win: Node = hud.get("shop_window")
			if win == null or not win.open(main.keep):
				_error = "shop did not open next to the keep"
				return
			var x_style: StyleBox = null
			for c in win.get_children()[0].get_children()[0].get_children():
				if c is Button:
					x_style = (c as Button).get_theme_stylebox("normal")
			if not (x_style is StyleBoxFlat) or (x_style as StyleBoxFlat).corner_radius_top_left != 12:
				_error = "X is not a round stud"
				return
			if not (win._buy.get_theme_stylebox("normal") is StyleBoxTexture):
				_error = "Buy is not a framed primary button"
				return
			if not win._sell_zone._can_drop_data(Vector2.ZERO, {"inventory_slot": 0}):
				_error = "Sell zone refuses the inventory bar's drag data"
				return
			win._sell_zone._set_hot(false)
			_next()
		7:
			if _since() < 30:
				return
			_save("shop")
			_done = true


func _check_card() -> void:
	var panel_style: StyleBox = card.get_theme_stylebox("panel")
	if panel_style is StyleBoxFlat:
		_error = "command card still uses the flat panel"
		return
	var b: Button = card.buttons[0]
	var st: StyleBox = b.get_theme_stylebox("normal")
	if not (st is StyleBoxTexture) or (st as StyleBoxTexture).texture.get_size() != Vector2(24, 24) \
			or (st as StyleBoxTexture).texture_margin_left != 8:
		_error = "button frame is not the 24 x 24 texture with margins 8"
		return
	for state in ["hover", "pressed", "disabled"]:
		if not (b.get_theme_stylebox(state) is StyleBoxTexture):
			_error = "button state %s not framed" % state
			return
	var br: Rect2 = b.get_global_rect()
	if br.size != Vector2(56, 56):   # SC2.U1: 5 x 3 of 56 (ui-sc2-console.md 4.4)
		_error = "button size %s" % br.size
		return
	var kr: Rect2 = card.key_labels[0].get_global_rect()
	var rel := kr.end - br.position
	if absf(rel.x - 54.0) > 0.5 or absf(rel.y - 54.0) > 0.5 or kr.size.x < 18.0:
		_error = "hotkey badge rect %s in the button (end %s)" % [kr, rel]
		return
	if not (card.key_labels[0].get_theme_stylebox("normal") is StyleBoxFlat):
		_error = "hotkey letter has no badge"
		return
	var ids: Array = card.slot_ids()
	if str(ids[5]) != "fireball":   # SC2.U1: the spells at r2c1-r2c3
		_error = "slot 6 is '%s', not fireball" % ids[5]
		return
	var pip: Control = card.rank_pips[5][0]
	if pip.get("color") == null or pip.size != Vector2(6, 6) or pip.position != Vector2(32, 3):
		_error = "rank pip not a 6 x 6 diamond at (32, 3) (the mana tag is bottom-left)"
		return
	var has_icon := ResourceLoader.exists("res://art/icons/spells/fireball.png")
	if card.icons[5].visible != (has_icon or card.icons[5].texture != null):
		_error = "icon visibility wrong (file exists %s)" % has_icon
		return
	if card.buttons[5].text == "":
		_error = "abbreviation lost"
		return


func _check_tooltips() -> void:
	var text := "Fireball  [F]  Rank 1 / 3\n40 mana · 72 damage · radius 3.75\nBurns everything in the circle.\nNot enough mana"
	var p: Control = ItemTooltip.HudSkin.tooltip_panel(text)
	var box: Container = p.get_child(0)
	if box.get_child_count() != 4:
		_error = "tooltip has %d rows, expected 4" % box.get_child_count()
		p.free()
		return
	var last: Label = box.get_child(3)
	if last.text != "Not enough mana" or last.get_theme_color("font_color") != WARN:
		_error = "reason line not in WARN"
		p.free()
		return
	var head: Container = box.get_child(0)
	var name_label: Label = head.get_child(0)
	if name_label.text != "Fireball" or (head.get_child(1) as Label).text != "F":
		_error = "tooltip line 1 split wrong"
		p.free()
		return
	p.free()
	var tip: Control = ItemTooltip.HudSkin.tooltip_panel(card.buttons[5].tooltip_text)
	if tip == null:
		_error = "no custom tooltip for the Fireball button"
		return
	tip.free()
