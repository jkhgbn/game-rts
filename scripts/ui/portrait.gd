class_name Portrait
extends Control
## 3D portrait of the selected unit / building (ui-style.md 7.2), 136 x 136 in the console's portrait window
## (ui-sc2-console.md 4.3, PortraitWindow). One SubViewport (192 x 192, own World3D, MSAA 2x) for the whole HUD. It
## renders once per UPDATE_INTERVAL (30 Hz) while visible (UPDATE_ONCE), never while hidden; the model is swapped only
## when the target's type changes. Without a model_scene it shows the 2-letter abbreviation.

const SIZE := Vector2(136, 136)
const VIEWPORT_SIZE := Vector2i(192, 192)
const UPDATE_INTERVAL := 1.0 / 30.0

var viewport: SubViewport
var view: TextureRect
var abbrev_label: Label
var target: Node = null
var render_count := 0          ## Viewport renders requested (for tests / perf checks).

var _camera: Camera3D
var _holder: Node3D
var _model_key := ""
var _update_left := 0.0
var _frame: Panel
var _bg: TextureRect
var _vignette: TextureRect
var _skin := -1


func _ready() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_bg = TextureRect.new()
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	viewport = SubViewport.new()
	viewport.size = VIEWPORT_SIZE
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_2X
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(viewport)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.45, 0.52, 0.70)
	e.ambient_light_energy = 0.5
	env.environment = e
	viewport.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, -35, 0)
	light.light_color = Color(1.0, 0.93, 0.82)
	light.light_energy = 1.2
	light.shadow_enabled = false
	viewport.add_child(light)
	_camera = Camera3D.new()
	_camera.fov = 30.0
	viewport.add_child(_camera)
	_holder = Node3D.new()
	viewport.add_child(_holder)

	view = TextureRect.new()
	view.texture = viewport.get_texture()
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_SCALE
	view.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(view)

	_vignette = TextureRect.new()
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.visible = false
	var vg := Gradient.new()
	vg.set_color(0, Color(0.9, 0.1, 0.1, 0.0))
	vg.set_color(1, Color(0.9, 0.1, 0.1, 0.35))
	vg.set_offset(0, 0.55)
	var vt := GradientTexture2D.new()
	vt.gradient = vg
	vt.fill = GradientTexture2D.FILL_RADIAL
	vt.fill_from = Vector2(0.5, 0.5)
	vt.fill_to = Vector2(1.0, 0.5)
	vt.width = 64
	vt.height = 64
	_vignette.texture = vt
	add_child(_vignette)

	abbrev_label = UIStyle.display_label("", 36)
	abbrev_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	abbrev_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	abbrev_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(abbrev_label)

	_frame = Panel.new()
	_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame)
	apply_skin()


func apply_skin() -> void:
	_skin = UIStyle.skin_version
	var g := Gradient.new()
	var glow := UIStyle.token(&"trim_glow")
	g.set_color(0, Color(glow.r, glow.g, glow.b, 0.35))
	g.set_color(1, UIStyle.token(&"panel_inner"))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 128
	t.height = 128
	_bg.texture = t
	abbrev_label.add_theme_color_override("font_color", UIStyle.token(&"title"))
	_set_rim(Color(0, 0, 0, 0))


## Shows `node` (a Unit or a building); null hides the content. Swaps the model only on a type change.
func set_target(node: Node) -> void:
	var next: Node = node if node != null and is_instance_valid(node) else null
	if next == target:
		return
	target = next
	_update_left = 0.0
	var key := _type_key(target)
	if key != _model_key:
		_model_key = key
		_swap_model()


func _process(delta: float) -> void:
	if _skin != UIStyle.skin_version:
		apply_skin()
	if not is_visible_in_tree() or target == null or not is_instance_valid(target):
		if viewport.render_target_update_mode != SubViewport.UPDATE_DISABLED:
			viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return
	_update_state()
	_update_left -= delta
	if _update_left <= 0.0 and _holder.get_child_count() > 0:
		_update_left = UPDATE_INTERVAL
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		render_count += 1


## Dead / destroyed dims the picture, low HP shows the red vignette, enemies get a red rim.
func _update_state() -> void:
	var hp: Variant = target.get("hp")
	var max_hp: Variant = target.get("max_hp")
	var dead := target.has_method(&"is_alive") and not bool(target.call(&"is_alive"))
	view.modulate = Color(0.5, 0.5, 0.5) if dead else Color.WHITE
	var low := false
	if hp != null and max_hp != null and float(max_hp) > 0.0:
		low = float(hp) / float(max_hp) < 0.3 and not dead
	_vignette.visible = low
	var team: Variant = target.get("team")
	var rim := Color(0, 0, 0, 0)
	if team != null and int(team) != 0:
		rim = UIStyle.DEFEAT if int(team) == 1 else UIStyle.token(&"frame_dark")
	_set_rim(rim)


func _set_rim(rim: Color) -> void:
	var key := rim.to_html()
	if _frame.get_meta(&"rim", "") == key:
		return
	_frame.set_meta(&"rim", key)
	var s := UIStyle.button_frame(&"normal", rim)
	s.draw_center = false
	_frame.add_theme_stylebox_override("panel", s)


func _type_key(node: Node) -> String:
	if node == null:
		return ""
	var type: Variant = node.get("unit_type")
	if type == null:
		type = node.get("building_type")
	if type is Resource:
		return (type as Resource).resource_path + str(type.get("display_name"))
	return str(node.get("unit_name"))


func _model_aabb(model: Node) -> AABB:
	var out := AABB()
	var first := true
	for n in model.find_children("*", "VisualInstance3D", true, false) + ([model] if model is VisualInstance3D else []):
		var vi := n as VisualInstance3D
		if vi == null or not vi.is_inside_tree():
			continue
		var b := vi.global_transform * vi.get_aabb()
		if first:
			out = b
			first = false
		else:
			out = out.merge(b)
	return out


func _swap_model() -> void:
	for c in _holder.get_children():
		c.queue_free()
	abbrev_label.text = ""
	if target == null:
		return
	var scene: PackedScene = target.get("model_scene") as PackedScene
	var name_text := str(target.get("unit_name")) if target.get("unit_name") != null else ""
	var type: Variant = target.get("building_type")
	if type is Object:
		name_text = str(type.get("display_name"))
		if scene == null:
			scene = type.get("model_scene") as PackedScene
	var building := type is Object
	if scene == null:
		abbrev_label.text = UIStyle.abbrev(name_text)
		return
	var model := scene.instantiate()
	_holder.add_child(model)
	if building:
		# s = the building's size: footprint cells are 2 m; tall models count their height.
		var s := 4.0
		var fp: Variant = type.get("footprint")
		if fp is Vector2i:
			s = maxf(2.0 * maxi(fp.x, fp.y), 1.0)
		var bh: Variant = type.get("height")
		if bh is float or bh is int:
			s = maxf(s, float(bh))
		_camera.position = Vector3(0.9 * s, 0.9 * s, 1.6 * s)
		_camera.look_at(Vector3(0, 0.35 * s, 0))
	else:
		var h := float(target.get("body_height")) if target.get("body_height") != null else 1.6
		if model is Node3D:
			(model as Node3D).rotation_degrees.y = 20.0
		_camera.position = Vector3(0, 0.85 * h, 2.3 * h)
		_camera.look_at(Vector3(0, 0.65 * h, 0))
	# Buildings: frame the real model's AABB (models are bigger than the type's numbers). Units keep
	# body_height (their scenes carry wide effects that would shrink the head-and-shoulders shot).
	var box := _model_aabb(model) if building else AABB()
	if box.size.length() > 0.01:
		var c := box.get_center()
		var s := maxf(maxf(box.size.x, box.size.z), box.size.y * 0.8)
		_camera.position = c + Vector3(0.9, 0.55, 1.6).normalized() * s * 2.1
		_camera.look_at(c)
	if model.has_method(&"play_idle"):
		model.call(&"play_idle")
	else:
		var anim := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if anim:
			for a in [&"idle", &"Idle"]:
				if anim.has_animation(a):
					anim.play(a)
					break
