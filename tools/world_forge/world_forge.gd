extends SceneTree
## World Forge CLI (tools/world_forge/README.md). Run through tools/world_forge/run_world_forge.ps1:
##   run_world_forge.ps1 <verb> <id> [key=value...]
## Verbs: help, check <set>, build <set>, sheet <set> (windowed stills), map <map>, export-map <crown_hollow|scene path>,
##        demo (the acceptance demo: set forge_watch_keep, map fourfold_hollow, Crown Hollow round trip).
## Exit codes: 0 PASS / WARN, 1 FAIL, 2 bad input (spec errors name file:line, token and "did you mean").

const FSet := preload("res://tools/world_forge/forge_set.gd")
const Checks := preload("res://tools/world_forge/forge_set_checks.gd")
const FMap := preload("res://tools/world_forge/forge_map.gd")
const Report := preload("res://tools/world_forge/forge_report.gd")

const VERBS: Array[String] = ["help", "check", "build", "sheet", "map", "export-map", "demo"]

var opts := {}
var verb := ""
var id := ""
var frame := 0
var step := 0
var t0 := 0
var fs: FSet
var holder: Node3D
var inst: Node3D
var queue: Array = []     ## demo: [[verb, id], ...]
var results: Array[String] = []
var worst := 0
var fmap: FMap


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		opts[kv[0]] = kv[1] if kv.size() > 1 else "1"
	verb = String(opts.get("verb", "help"))
	id = String(opts.get("id", ""))
	if not VERBS.has(verb):
		print("WORLD FORGE: unknown verb \"%s\" -> did you mean \"%s\"? (verbs: %s)" % [verb, _near(verb, VERBS), ", ".join(VERBS)])
		quit(2)
		return
	if verb == "help":
		print(help_text())
		quit(0)
		return
	if verb == "demo":
		queue = [["build", "forge_watch_keep"], ["map", "fourfold_hollow"], ["export-map", "crown_hollow"], ["map", "crown_hollow"]]
	else:
		if id == "":
			print("WORLD FORGE: %s wants an id (run_world_forge.ps1 %s <id>)" % [verb, verb])
			quit(2)
			return
		queue = [[verb, id]]
	_next_job()


func _near(t: String, choices: Array) -> String:
	var best := ""
	var bs := -1.0
	for c: String in choices:
		var s := t.similarity(c)
		if s > bs:
			bs = s
			best = c
	return best


func _next_job() -> void:
	if queue.is_empty():
		for r in results:
			print(r)
		quit(worst)
		return
	var job: Array = queue.pop_front()
	verb = job[0]
	id = job[1]
	frame = 0
	step = 0
	t0 = Time.get_ticks_usec()
	match verb:
		"check", "build", "sheet":
			_start_set()
		"map":
			_start_map()
		"export-map":
			_start_export()


func _finish(code: int, line: String) -> void:
	results.append(line)
	worst = maxi(worst, code)
	if holder and is_instance_valid(holder):
		holder.queue_free()
	holder = null
	inst = null
	# let queued frees run before the next job
	step = -100
	frame = 0


func _process(_delta: float) -> bool:
	frame += 1
	if step == -100:
		if frame > 2:
			step = 0
			_next_job()
		return false
	match verb:
		"check", "build":
			_tick_set()
		"sheet":
			_tick_sheet()
		"map":
			_tick_map()
		"export-map":
			_tick_export()
	return false


# ---------------------------------------------------------------- sets

func spec_path(set_id: String) -> String:
	return "%s/%s/%s.set" % [FSet.SETS_DIR, set_id, set_id]


func _start_set() -> void:
	fs = FSet.new()
	var path := String(opts.get("spec", spec_path(id)))
	if not fs.compile(path):
		for l in fs.spec.error_lines():
			print("ERROR " + l)
		for l in fs.spec.warning_lines():
			print("WARN  " + l)
		print("WORLD FORGE set %s: BAD INPUT (%d errors)" % [id, fs.spec.errors.size()])
		_finish(2, "WORLD FORGE set %s: BAD INPUT" % id)
		return
	for l in fs.spec.warning_lines():
		print("WARN  " + l)
	fs.report.title = "World Forge set: %s" % id
	fs.report.id = id
	fs.report.kind = "set"
	holder = Node3D.new()
	holder.name = "ForgeHolder"
	root.add_child(holder)
	step = 1


func _tick_set() -> void:
	match step:
		1:
			fs.build(holder)
			step = 2
			frame = 0
		2:
			if frame < 3:
				return
			var built: Node3D = holder.get_child(0)
			if verb == "build":
				fs.save(built)
				built.queue_free()
				step = 3
			else:
				inst = built
				step = 4
			frame = 0
		3:
			if frame < 2:
				return
			var scene_path := "%s/%s.tscn" % [fs.set_dir(), id]
			ResourceLoader.load(scene_path, "", ResourceLoader.CACHE_MODE_REPLACE)
			inst = (load(scene_path) as PackedScene).instantiate()
			holder.add_child(inst)
			step = 4
			frame = 0
		4:
			if frame < 4:
				return
			Checks.run(fs, inst)
			var h1 := fs.layout_hash()
			# determinism: rebuild the layout from the same spec in memory
			var fs2 := FSet.new()
			fs2.compile(fs.plan["path"])
			var h2_holder := Node3D.new()
			holder.add_child(h2_holder)
			fs2.build(h2_holder)
			var h2 := fs2.layout_hash()
			h2_holder.queue_free()
			fs.report.add("D1", "Deterministic layout", "PASS" if h1 == h2 else "FAIL", "%s vs %s" % [h1, h2],
				"same spec + seed = the same layout (every transform)", "a scatter / row depends on something outside the spec", 1.5)
			fs.report.hash = h1
			var od := fs.out_dir()
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(od))
			var img := Checks.plan_image(fs)
			img.save_png(od + "/plan.png")
			fs.report.files.append(od + "/plan.png")
			if verb == "build":
				var md5s: Array[String] = []
				for f in fs.report.files:
					if f.ends_with(".res"):
						md5s.append(f.get_file() + " " + FileAccess.get_md5(f).substr(0, 8))
				fs.report.notes.append("Mesh file md5: " + ", ".join(md5s))
			fs.report.notes.append("Art Lab decor_set: not wired yet (run `tools/art_lab/run_art_lab.ps1` on the set scene by hand); Lens stills: `sheet` verb (windowed).")
			fs.report.seconds = float(Time.get_ticks_usec() - t0) / 1e6
			fs.report.write(od)
			if verb == "build":
				fs.report.append_history()
			fs.report.print_summary(od)
			_finish(fs.report.exit_code(), "WORLD FORGE set %s: %s score %.0f" % [id, fs.report.result(), fs.report.score()])


# ---------------------------------------------------------------- sheet (windowed stills)

var _shots: Array = []   ## [[label, cam, look, fov]]
var _cam: Camera3D
var _rig: Node
var _label: Label
var _images: Array = []  ## [[label, Image]]


func _tick_sheet() -> void:
	match step:
		1:
			if DisplayServer.get_name() == "headless":
				print("WORLD FORGE sheet: needs a window (run without --headless; the ps1 does this)")
				_finish(2, "WORLD FORGE sheet %s: needs a window" % id)
				return
			var scene_path := "%s/%s.tscn" % [fs.set_dir(), id]
			if not ResourceLoader.exists(scene_path):
				print("WORLD FORGE sheet: %s not built yet (run build first)" % scene_path)
				_finish(2, "WORLD FORGE sheet %s: not built" % id)
				return
			root.size = Vector2i(1600, 900)
			DisplayServer.window_set_size(Vector2i(1600, 900))
			inst = (load(scene_path) as PackedScene).instantiate()
			holder.add_child(inst)
			_rig = LightingRig.new()
			_rig.set(&"preset", inst.get(&"lighting"))
			holder.add_child(_rig)
			_cam = Camera3D.new()
			_cam.near = 0.1
			_cam.far = 400.0
			holder.add_child(_cam)
			_cam.current = true
			var layer := CanvasLayer.new()
			layer.layer = 10
			holder.add_child(layer)
			for y in [0, 1]:
				var bar := ColorRect.new()
				bar.color = Color.BLACK
				var bh := int((900.0 - 1600.0 / 2.39) * 0.5)
				bar.position = Vector2(0, 0 if y == 0 else 900 - bh)
				bar.size = Vector2(1600, bh)
				layer.add_child(bar)
			_label = Label.new()
			_label.position = Vector2(16, 8)
			_label.add_theme_font_size_override(&"font_size", 28)
			layer.add_child(_label)
			for m: Dictionary in fs.plan["marks"]:
				for ph: Array in [["a", 0.0], ["b", 0.5], ["c", 1.0]]:
					var t: float = ph[1]
					_shots.append(["%s_%s" % [m["shot"], ph[0]], (m["from"] as Vector3).lerp(m["to"], t),
						(m["look_from"] as Vector3).lerp(m["look_to"], t), lerpf(m["fov_from"], m["fov_to"], t)])
			var sz: Vector2 = fs.plan["size"]
			_shots.append(["top", Vector3(0, maxf(sz.x, sz.y) * 1.25, 0.01), Vector3.ZERO, 0.0])
			step = 2
			frame = 0
		2:
			if _shots.is_empty():
				step = 5
				return
			var s: Array = _shots[0]
			if s[0] == "top":
				_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
				_cam.size = maxf(fs.plan["size"].x / 1.7778, fs.plan["size"].y) * 1.02
				_cam.global_transform = Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), s[1])
			else:
				_cam.projection = Camera3D.PROJECTION_PERSPECTIVE
				_cam.fov = s[3]
				_cam.global_transform = Transform3D.IDENTITY.translated(s[1]).looking_at(s[2], Vector3.UP)
			_label.text = "%s  %s" % [id, s[0]]
			step = 3
			frame = 0
		3:
			if frame < 12:
				return
			var img := root.get_texture().get_image()
			_images.append([_shots[0][0], img])
			_shots.pop_front()
			step = 2
		5:
			var od := fs.out_dir()
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(od + "/stills"))
			var tw := 400
			var th := 225
			var cols := 3
			var rows := int(ceil(_images.size() / float(cols)))
			var sheet := Image.create(tw * cols, th * rows, false, Image.FORMAT_RGBA8)
			sheet.fill(Color(0.1, 0.1, 0.1))
			var k := 0
			for e: Array in _images:
				var img: Image = e[1]
				img.convert(Image.FORMAT_RGBA8)
				img.save_png("%s/stills/%s.png" % [od, e[0]])
				var small := img.duplicate() as Image
				small.resize(tw, th, Image.INTERPOLATE_BILINEAR)
				sheet.blit_rect(small, Rect2i(0, 0, tw, th), Vector2i((k % cols) * tw, (k / cols) * th))
				k += 1
			sheet.save_png(od + "/sheet.png")
			print("WORLD FORGE sheet %s: %d stills -> %s/sheet.png (+ stills/*.png, top.png = top-down)" % [id, _images.size(), od])
			_finish(0, "WORLD FORGE sheet %s: %d stills" % [id, _images.size()])


# ---------------------------------------------------------------- maps

func _start_map() -> void:
	fmap = FMap.new()
	holder = Node3D.new()
	holder.name = "ForgeMapHolder"
	root.add_child(holder)
	var err := fmap.start_map(id, opts, holder)
	if err != "":
		print(err)
		_finish(2, "WORLD FORGE map %s: BAD INPUT" % id)
		return
	step = 1


func _tick_map() -> void:
	var r := fmap.tick_map(frame)
	if r.is_empty():
		return
	_finish(int(r["code"]), String(r["line"]))


func _start_export() -> void:
	fmap = FMap.new()
	holder = Node3D.new()
	holder.name = "ForgeExportHolder"
	root.add_child(holder)
	var err := fmap.start_export(id, opts, holder)
	if err != "":
		print(err)
		_finish(2, "WORLD FORGE export-map %s: BAD INPUT" % id)
		return
	step = 1


func _tick_export() -> void:
	var r := fmap.tick_export(frame)
	if r.is_empty():
		return
	_finish(int(r["code"]), String(r["line"]))


# ---------------------------------------------------------------- help

static func help_text() -> String:
	return FileAccess.get_file_as_string("res://tools/world_forge/README.md") if FileAccess.file_exists("res://tools/world_forge/README.md") else "see tools/world_forge/README.md"
