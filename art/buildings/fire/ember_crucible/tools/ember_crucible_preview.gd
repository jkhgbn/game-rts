extends Node3D
## Ember Crucible annex preview (task 13c.V7). Windowed:
##   Godot_v4.7.2-stable_win64.exe --path . res://art/buildings/fire/ember_crucible/tools/ember_crucible_preview.tscn
##       --resolution 1600x900 --fixed-fps 60 -- --shots
## writes docs/art/screens/13c_v7_*.png (states, forge, views, z40, silhouette) then quits. Without --shots: keys
## 1-4 zoom 7 / 12 / 25 / 40 · L light / put out · F forge · Y turn the Roost 90 deg.
## The Dragon Roost (13.V25) art does not exist yet: a clearly rough PROXY (6 x 6 m plinth, 9 m basalt spire, a nest
## crown of beams) stands in for it so the annex can be judged at the right scale and placement (ROOST_ANCHOR).

const SCENE := "res://art/buildings/fire/ember_crucible/ember_crucible.tscn"
const GUARD := "res://art/units/fire/flame_guard.tscn"
const OUT := "res://docs/art/screens/"
const PREFIX := "13c_v7_"
const ORIGIN := Vector3(30.0, 0.0, 30.0)
const PLINTH_TOP := 0.6
const FIRE_TEAM := Color(0.85, 0.30, 0.12)

var _cam: Camera3D
var _env: WorldEnvironment
var _ground: MeshInstance3D
var _roosts: Array[Node3D] = []     # holders (the proxy + its annex)
var _annexes: Array[Node3D] = []
var _extra: Array[Node3D] = []


func _ready() -> void:
	_setup_world()
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	add_child(_cam)
	_cam.make_current()
	_add_roost(Vector3.ZERO, -90.0, true)
	_set_zoom(12.0, Vector3(1.5, 1.2, 1.5))
	if "--shots" in OS.get_cmdline_user_args():
		_take_shots()


func _setup_world() -> void:
	_env = WorldEnvironment.new()
	_env.environment = load("res://art/environment/world_env.tres")
	add_child(_env)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.00, 0.93, 0.82)
	sun.light_energy = 1.3
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.shadow_enabled = true
	sun.shadow_normal_bias = 2.0
	add_child(sun)
	_ground = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(300, 300)
	_ground.mesh = pm
	_ground.material_override = load("res://art/environment/ground_material.tres")
	add_child(_ground)


## A Roost proxy (holder at `at`, yaw: -90 = the player's camera sees its local +X side) with the annex at ROOST_ANCHOR.
func _add_roost(at: Vector3, yaw_deg: float, with_annex: bool) -> Node3D:
	var holder := Node3D.new()
	holder.position = ORIGIN + at
	holder.rotation.y = deg_to_rad(yaw_deg)
	add_child(holder)
	holder.add_child(_roost_proxy())
	if with_annex:
		var a: Node3D = load(SCENE).instantiate()
		var anchor: Vector3 = (a.get_script() as Script).get_script_constant_map()["ROOST_ANCHOR"]
		a.position = anchor + Vector3(0.0, PLINTH_TOP, 0.0)
		holder.add_child(a)
		_annexes.append(a)
	_roosts.append(holder)
	return holder


## Rough stand-in for the Dragon Roost (cavalry-mounts.md 13.V25: a 9 m basalt spire with a dominant nest crown of
## charred beams, lava seams): plinth, tapering spire, perch ledge, crown beams, a glow in the nest. Preview only.
func _roost_proxy() -> Node3D:
	var root := Node3D.new()
	root.name = "RoostProxy"
	var dark: Material = load("res://art/buildings/fire/ember_crucible/materials/ec_dark.tres")
	var stone: Material = load("res://art/buildings/fire/ember_crucible/materials/ec_stone.tres")
	var coals: Material = load("res://art/buildings/fire/ember_crucible/materials/ec_coals.tres")
	var box := BoxMesh.new()
	_part(root, box, Vector3(0, PLINTH_TOP * 0.5, 0), Vector3(6.2, PLINTH_TOP, 6.2), Vector3.ZERO, dark)
	var segs: Array[Vector3] = [Vector3(2.0, 1.75, 2.2), Vector3(1.75, 1.45, 2.2), Vector3(1.45, 1.15, 2.0), Vector3(1.15, 0.95, 1.6)]
	var y := PLINTH_TOP
	for s: Vector3 in segs:
		var c := CylinderMesh.new()
		c.bottom_radius = s.x
		c.top_radius = s.y
		c.height = s.z
		c.radial_segments = 7
		_part(root, c, Vector3(0, y + s.z * 0.5, 0), Vector3.ONE, Vector3(0, y * 20.0, 0), stone if int(y) % 2 == 0 else dark)
		y += s.z
	# lava seams (vertical glow strips)
	for k: int in 3:
		var a := TAU * k / 3.0 + 0.4
		_part(root, box, Vector3(cos(a) * 1.72, 2.6, sin(a) * 1.72), Vector3(0.12, 3.2, 0.12), Vector3(0, -rad_to_deg(a), 8), coals)
	# perch ledge
	_part(root, box, Vector3(-1.4, 6.2, 0.0), Vector3(1.8, 0.3, 1.0), Vector3.ZERO, dark)
	# nest crown: a flared bowl of charred beams around the top
	var top := y
	for k: int in 14:
		var a := TAU * k / 14.0
		var d := Vector3(cos(a), 0, sin(a))
		var p := d * 1.55 + Vector3(0, top + 0.55, 0)
		var basis := Basis(Vector3.UP.cross(d).normalized(), deg_to_rad(-38.0))
		var mi := MeshInstance3D.new()
		mi.mesh = box
		mi.material_override = dark
		mi.transform = Transform3D(basis.scaled_local(Vector3(0.28, 1.9, 0.28)), p)
		root.add_child(mi)
	var bowl := CylinderMesh.new()
	bowl.bottom_radius = 1.0
	bowl.top_radius = 1.9
	bowl.height = 0.7
	_part(root, bowl, Vector3(0, top + 0.3, 0), Vector3.ONE, Vector3.ZERO, dark)
	var egg := SphereMesh.new()
	egg.radius = 0.55
	egg.height = 1.3
	_part(root, egg, Vector3(0, top + 0.95, 0), Vector3.ONE, Vector3.ZERO, coals)
	return root


func _part(root: Node3D, mesh: Mesh, pos: Vector3, scale: Vector3, rot_deg: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.scale = scale
	root.add_child(mi)


func _set_zoom(z: float, focus: Vector3 = Vector3.ZERO, pitch_deg: float = 55.0, yaw_deg: float = 0.0) -> void:
	var pitch := deg_to_rad(pitch_deg)
	var yaw := deg_to_rad(yaw_deg)
	var back := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
	_cam.position = ORIGIN + focus + back * z
	_cam.rotation = Vector3(-pitch, yaw, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	match (event as InputEventKey).keycode:
		KEY_1: _set_zoom(7.0, Vector3(1.8, 1.0, 1.8))
		KEY_2: _set_zoom(12.0, Vector3(1.5, 1.2, 1.5))
		KEY_3: _set_zoom(25.0, Vector3(0, 2.0, 0))
		KEY_4: _set_zoom(40.0, Vector3(0, 2.0, 0))
		KEY_L:
			for a: Node3D in _annexes:
				a.call(&"set_crucible", not bool(a.call(&"is_crucible_on")))
		KEY_F:
			for a: Node3D in _annexes:
				a.call(&"play_forge")
		KEY_Y:
			for r: Node3D in _roosts:
				r.rotation.y += deg_to_rad(90.0)


# ---------------------------------------------------------------- screenshots

func _take_shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _wait(1.0)
	await _states_sheet()
	await _forge_sheet()
	await _views_sheet()
	await _z40()
	await _silhouettes()
	print("EMBER CRUCIBLE SHOTS DONE")
	get_tree().quit()


func _annex() -> Node3D:
	return _annexes[0]


## Where the annex sits in the world (its pad centre, a little up).
func _annex_focus() -> Vector3:
	return _annex().global_position - ORIGIN + Vector3(0, 0.9, 0)


## Off / lit / forge pulse (at the pour's hit 0.45 s): top row the player's camera (Roost local +X side), bottom row the
## enemy's (local -X side), both at the close game camera (12 m) with the Roost proxy in frame.
func _states_sheet() -> void:
	var a := _annex()
	var imgs: Array[Image] = []
	for yaw: float in [-90.0, 90.0]:
		_roosts[0].rotation.y = deg_to_rad(yaw)
		a.call(&"set_crucible", false, true)
		await _wait(0.3)
		var f := _annex_focus()
		_set_zoom(8.5, f + Vector3(0, 0.4, 0))
		await _wait(0.4)
		imgs.append(_grab())
		a.call(&"set_crucible", true)
		await _wait(3.0)
		imgs.append(_grab())
		a.call(&"play_forge")
		await _until(a, 0.45)
		imgs.append(_grab())
		await _wait(5.0)
	_roosts[0].rotation.y = deg_to_rad(-90.0)
	_sheet(imgs, 3, PREFIX + "states")


## The forge close up (player side, 3/4): 0.15 bellows + tip, 0.3 the stream starts, 0.45 the hit (sparks, flare),
## 0.8 pouring, 1.35 steam + righting, 2.2 the fresh cast cooling.
func _forge_sheet() -> void:
	var a := _annex()
	a.call(&"set_crucible", true, true)
	await _wait(0.5)
	_set_zoom(5.6, _annex_focus() + Vector3(-0.2, 0.2, 0.0), 32.0, 30.0)
	await _wait(0.3)
	var imgs: Array[Image] = []
	a.call(&"play_forge")
	for t: float in [0.15, 0.3, 0.45, 0.8, 1.35, 2.19]:
		await _until(a, t)
		imgs.append(_grab())
	await _wait(5.0)
	_sheet(imgs, 3, PREFIX + "forge")


## Close views of the lit annex: player 3/4, enemy 3/4, front (gate side), back (chimney, bellows), top, off close up.
func _views_sheet() -> void:
	var a := _annex()
	var holder := _roosts[0]
	# Take the annex out of the Roost for clean views of every side.
	holder.visible = false
	var solo: Node3D = load(SCENE).instantiate()
	var sh := Node3D.new()
	sh.position = ORIGIN + Vector3(0, 0, 12.0)
	add_child(sh)
	sh.add_child(solo)
	solo.call(&"set_crucible", true, true)
	var f := Vector3(0, 1.0, 12.0)
	var imgs: Array[Image] = []
	for v: Vector3 in [Vector3(6.0, 35.0, 40.0), Vector3(6.0, 35.0, -140.0), Vector3(5.5, 18.0, 180.0),
			Vector3(5.5, 25.0, 0.0), Vector3(5.5, 85.0, 180.0)]:
		_set_zoom(v.x, f, v.y, v.z)
		await _wait(0.35)
		imgs.append(_grab())
	solo.call(&"set_crucible", false, true)
	_set_zoom(6.0, f, 35.0, 40.0)
	await _wait(0.35)
	imgs.append(_grab())
	sh.queue_free()
	holder.visible = true
	a.call(&"set_crucible", true, true)
	_sheet(imgs, 3, PREFIX + "views")


## In-game read at 40 m: three Roost proxies (annex off / lit / forging at the hit), Flame Guards for scale, player side.
func _z40() -> void:
	_roosts[0].visible = false
	var hs: Array[Node3D] = []
	var anx: Array[Node3D] = []
	for i: int in 3:
		var h := _add_roost(Vector3(-11.0 + 11.0 * i, 0, 0), -90.0, true)
		hs.append(h)
		anx.append(_annexes[_annexes.size() - 1])
	anx[1].call(&"set_crucible", true, true)
	anx[2].call(&"set_crucible", true, true)
	for i: int in 3:
		for k: int in 2:
			var g := _spawn_guard(Vector3(-8.2 + 11.0 * i + 0.9 * k, 0, 4.4 + 0.7 * k), 20.0)
			if g:
				_extra.append(g)
	_set_zoom(40.0, Vector3(0.0, 2.0, 0.0))
	await _wait(1.0)
	anx[2].call(&"play_forge")
	await _until(anx[2], 0.45)
	var img := _grab()
	img.save_png(OUT + PREFIX + "z40_full.png")
	_crop(img, 40.0, 2.4).save_png(OUT + PREFIX + "z40.png")
	await _wait(2.5)
	for h: Node3D in hs:
		_roosts.erase(h)
		h.queue_free()
	for a: Node3D in anx:
		_annexes.erase(a)
	for g: Node3D in _extra:
		g.get_parent().queue_free()
	_extra.clear()
	_roosts[0].visible = true


func _spawn_guard(at: Vector3, yaw_deg: float) -> Node3D:
	if not ResourceLoader.exists(GUARD):
		return null
	var m: Node3D = load(GUARD).instantiate()
	var holder := Node3D.new()
	holder.position = ORIGIN + at
	holder.rotation.y = deg_to_rad(yaw_deg)
	add_child(holder)
	if &"fidget_every" in m:
		m.set(&"fidget_every", 0.0)
	if m.has_method(&"set_team_color"):
		m.call(&"set_team_color", FIRE_TEAM)
	holder.add_child(m)
	return m


## Unlit black on white at 40 m, player side and enemy side: the Roost proxy without the annex, then with it (the
## crown must stay the read; the annex only adds a low knob at the foot).
func _silhouettes() -> void:
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	var white := StandardMaterial3D.new()
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	white.albedo_color = Color.WHITE
	var old_ground := _ground.material_override
	var old_env := _env.environment
	_ground.material_override = white
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color.WHITE
	_env.environment = e
	_roosts[0].visible = false
	var hs: Array[Node3D] = []
	hs.append(_add_roost(Vector3(-15.0, 0, 0), -90.0, false))
	hs.append(_add_roost(Vector3(-5.0, 0, 0), -90.0, true))
	hs.append(_add_roost(Vector3(5.0, 0, 0), 90.0, false))
	hs.append(_add_roost(Vector3(15.0, 0, 0), 90.0, true))
	await _wait(0.4)
	for h: Node3D in hs:
		for g: Node in h.find_children("*", "GeometryInstance3D", true, false):
			if g is GPUParticles3D or g.name == "LightPool":
				(g as Node3D).visible = false
			else:
				(g as GeometryInstance3D).material_override = black
	_set_zoom(40.0, Vector3(0.0, 3.0, 0.0))
	await _wait(0.5)
	var img := _grab()
	var c := img.get_region(Rect2i(200, 130, 1200, 560))
	c.save_png(OUT + PREFIX + "silhouette.png")
	_ground.material_override = old_ground
	_env.environment = old_env
	for h: Node3D in hs:
		_roosts.erase(h)
		h.queue_free()
	_annexes.resize(1)
	_roosts[0].visible = true


## Crop a window of the same world size at every zoom (x widen), nearest upscale to 800 x 450.
func _crop(img: Image, z: float, widen: float = 1.0) -> Image:
	var iw := img.get_width()
	var ih := img.get_height()
	var w: int = clampi(int(float(iw) * 13.0 / z * 0.55 * widen), 80, iw)
	var h: int = int(float(w) * 9.0 / 16.0)
	var r := Rect2i(clampi(iw / 2 - w / 2, 0, iw - w), clampi(ih / 2 - h / 2 - int(h * 0.1), 0, ih - h), w, h)
	var c := img.get_region(r)
	c.resize(1600, 900, Image.INTERPOLATE_NEAREST)
	return c


func _sheet(imgs: Array[Image], cols: int, nm: String) -> void:
	var w: int = 800
	var h: int = 450
	var rows: int = (imgs.size() + cols - 1) / cols
	var out := Image.create(w * cols, h * rows, false, Image.FORMAT_RGBA8)
	out.fill(Color(0.1, 0.1, 0.1))
	for i: int in imgs.size():
		var im: Image = imgs[i]
		im.convert(Image.FORMAT_RGBA8)
		im.resize(w, h, Image.INTERPOLATE_BILINEAR)
		out.blit_rect(im, Rect2i(0, 0, w, h), Vector2i((i % cols) * w, (i / cols) * h))
	out.save_png(OUT + nm + ".png")


## Waits until the annex's forge clock reaches `t` s.
func _until(a: Object, t: float) -> void:
	var guard := 0
	while float(a.get(&"_forge_t")) < t and float(a.get(&"_forge_t")) >= 0.0 and guard < 300:
		await get_tree().process_frame
		guard += 1


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _grab() -> Image:
	return get_viewport().get_texture().get_image()
