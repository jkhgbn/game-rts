class_name ArtLabRunner
extends Node
## Art Lab (docs/plan/art-lab.md): runs every shot and check for one asset and writes the scorecard. Created by
## tools/art_lab/art_lab.gd (windowed: everything; headless: budgets / health / hooks only, render checks SKIP).
## Args (key=value after `--`): scene, kind, kingdom, out, ref (comma list), tier, ground, light, name, ids (vfx),
## n (instances for the frame cost), quick=1 (no references / frame cost), log=0 (no improvement-log row).

const LOG_PATH := "res://docs/art/lab/improvement-log.md"
const KIT_DIR := "res://art/units/kit/"
const MAIN_YAW := 30.0
const UNIT_DATA_DIRS: Array[String] = ["res://data/units/"]
const DEFAULT_RADIUS := {&"unit": 0.45, &"mount": 0.7, &"titan": 1.6, &"beast": 1.0, &"critter": 0.3, &"building": 3.0,
	&"landmark": 3.0}
const DECOR_UNITS: Array[String] = ["res://art/units/fire/flame_guard.tscn", "res://art/units/shadow/shade.tscn",
	"res://art/units/ice/rimeshield.tscn", "res://art/units/nature/thornling.tscn"]
const OTHER_GROUNDS: Array[StringName] = [&"meadow", &"heath", &"old_wood", &"riverbank", &"snow", &"ash", &"sand", &"marsh"]


## Captures engine / script errors during the run (Godot 4.5+ Logger).
class LabLogger:
	extends Logger
	var mutex := Mutex.new()
	var entries: Array[Dictionary] = []

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool,
			error_type: int, script_backtrace: Array[ScriptBacktrace]) -> void:
		var f := file
		if not f.begins_with("res://") and not script_backtrace.is_empty():
			var bt: ScriptBacktrace = script_backtrace[0]
			if bt and bt.get_frame_count() > 0:
				f = bt.get_frame_file(0)
		mutex.lock()
		entries.append({"type": error_type, "file": f, "line": line, "msg": rationale if rationale != "" else code,
			"function": function})
		mutex.unlock()

	func _log_message(_message: String, _error: bool) -> void:
		pass


var opts: Dictionary = {}
var kind: StringName = &""
var tier: StringName = &""
var kingdom: StringName = &""
var scene_path: String = ""
var asset: String = ""
var out_dir: String = ""
var ground_id: StringName = &"meadow"
var headless: bool = false
var stage: ArtLabStage
var rep: ArtLabReport
var logger: LabLogger
var holder: Node3D
var target: Node3D
var unit: Dictionary = {}
var body_height: float = 1.6
var radius: float = 0.45
var flyer: bool = false
var stride: float = 3.0
var ground_y: float = 0.0
var gp: Vector3 = Vector3.ZERO
var tiles: Array[Dictionary] = []
var m: Dictionary = {}          # measurements shared between passes
var _t0: int = 0


# ================================================================ entry

func run(args: PackedStringArray) -> int:
	_t0 = Time.get_ticks_msec()
	for a: String in args:
		var s := a.trim_prefix("--")
		var k := s.get_slice("=", 0).strip_edges().to_lower()
		opts[k] = s.substr(k.length() + 1).strip_edges() if "=" in s else "1"
	headless = DisplayServer.get_name() == "headless"
	var err := _resolve()
	if err != "":
		printerr("ART LAB ERROR: " + err)
		print("ART LAB ERROR: " + err)
		return 2
	rep = ArtLabReport.new()
	rep.asset = asset
	rep.scene = scene_path
	rep.kind = String(kind)
	rep.tier = String(tier)
	rep.kingdom = String(kingdom)
	rep.headless = headless
	rep.started = Time.get_datetime_string_from_system(false, true)
	rep.previous_score = ArtLabReport.read_previous(out_dir)
	rep.budget_row = ArtLabBudgets.row(kind, tier)
	logger = LabLogger.new()
	OS.add_logger(logger)
	ArtLabCensus.clear_cache()
	stage = ArtLabStage.new()
	stage.name = "ArtLabStage"
	add_child(stage)
	stage.setup(StringName(opts.get("light", "ice" if ground_id == &"snow" else "warm")))
	if not headless:
		_show_viewport()
	print("ART LAB %s (%s / %s, %s) -> %s%s" % [asset, kind, tier, kingdom, out_dir, " [headless: no renders]" if headless else ""])
	match kind:
		&"decor_set":
			await _run_decor()
		&"vfx":
			await _run_vfx()
		_:
			await _run_model()
	_check_errors()
	_add_extras()
	rep.ground = String(ground_id)
	rep.seconds = float(Time.get_ticks_msec() - _t0) / 1000.0
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	if not headless and not tiles.is_empty():
		var sheet: Image = await rep.contact_sheet(self, tiles)
		sheet.save_png(ProjectSettings.globalize_path(out_dir.path_join("contact_sheet.png")))
		rep.shots["contact_sheet"] = "contact_sheet.png"
	rep.write(out_dir)
	if opts.get("log", "1") != "0" and not headless:
		rep.append_log(opts.get("logfile", LOG_PATH), out_dir)
	OS.remove_logger(logger)
	print("ART LAB %s: %s quality %.0f (%d FAIL, %d WARN, %d PASS) in %.0f s -> %s" % [asset, rep.result(), rep.quality(),
		rep.count("FAIL"), rep.count("WARN"), rep.count("PASS"), rep.seconds, out_dir.path_join("scorecard.md")])
	for c: Dictionary in rep.checks:
		if c["status"] == "FAIL" or c["status"] == "WARN":
			print("  %s %s %s: %s" % [c["status"], c["id"], c["name"], c["value"]])
	return rep.exit_code()


func _resolve() -> String:
	scene_path = String(opts.get("scene", ""))
	if scene_path == "":
		return "missing scene=res://..."
	var short := scene_path
	if not scene_path.begins_with("res://"):
		scene_path = "res://" + scene_path.trim_prefix("/")
	if not ResourceLoader.exists(scene_path):
		var rs := resolve_scene(short)   # short names work for scene= too
		if rs != "":
			scene_path = rs
	if not ResourceLoader.exists(scene_path):
		return "scene not found: " + scene_path
	kind = StringName(String(opts.get("kind", "")).to_lower())
	if not kind in ArtLabBudgets.KINDS:
		return "kind=%s must be one of %s" % [kind, ArtLabBudgets.KINDS]
	var base := scene_path.get_file().get_basename()
	asset = String(opts.get("name", base.trim_suffix("_set")))
	_lookup_unit_data()
	kingdom = StringName(String(opts.get("kingdom", "")).to_lower())
	if kingdom == &"":
		kingdom = _guess_kingdom()
	if not kingdom in ArtLabBudgets.KINGDOMS:
		return "kingdom=%s must be one of %s" % [kingdom, ArtLabBudgets.KINGDOMS]
	tier = StringName(String(opts.get("tier", "")))
	if tier == &"":
		var hint := unit.duplicate()
		if not hint.has("body_height"):
			var bh: Variant = _scene_prop(scene_path, "body_height")
			if bh != null:
				hint["body_height"] = bh
		tier = ArtLabBudgets.guess_tier(kind, scene_path, hint)
	if not ArtLabBudgets.has_tier(kind, tier):
		return "tier=%s is not a %s tier (%s)" % [tier, kind, ArtLabBudgets.tiers_of(kind)]
	out_dir = String(opts.get("out", "docs/art/lab/%s/" % asset))
	if not out_dir.begins_with("res://") and not out_dir.is_absolute_path():
		out_dir = "res://" + out_dir.trim_prefix("/")
	out_dir = out_dir.trim_suffix("/")
	ground_id = StringName(opts.get("ground", "meadow"))
	if not ArtLabStage.GROUND_POINTS.has(ground_id):
		return "ground=%s must be one of %s" % [ground_id, ArtLabStage.GROUND_POINTS.keys()]
	return ""


## A property of a scene's root as saved in the .tscn (no instancing), or null.
func _scene_prop(path: String, prop: String) -> Variant:
	var ps := load(path) as PackedScene
	if ps == null:
		return null
	var st := ps.get_state()
	if st.get_node_count() == 0:
		return null
	for i: int in st.get_node_property_count(0):
		if String(st.get_node_property_name(0, i)) == prop:
			return st.get_node_property_value(0, i)
	return null


func _guess_kingdom() -> StringName:
	var f: String = String(unit.get("faction", ""))
	if f in ["fire", "shadow", "ice", "nature", "neutral"]:
		return StringName(f)
	var p := scene_path.to_lower()
	for k: String in ["fire", "shadow", "ice", "nature"]:
		if "/%s/" % k in p or "/%s_" % k in p or p.get_file().begins_with(k):
			return StringName(k)
	for pair: Array in [["vessa", "fire"], ["malrik", "shadow"], ["torvald", "ice"], ["ysolde", "nature"],
			["cinder", "fire"], ["frost", "ice"], ["dusk", "shadow"], ["ember", "fire"], ["rime", "ice"], ["grove", "nature"],
			["gloam", "shadow"], ["nightmare", "shadow"], ["mammoth", "ice"], ["treant", "nature"], ["mossback", "nature"]]:
		if String(pair[0]) in p:
			return StringName(pair[1])
	return &"neutral"


func _lookup_unit_data() -> void:
	unit = {}
	for dir: String in UNIT_DATA_DIRS:
		var d := DirAccess.open(dir)
		if d == null:
			continue
		for f: String in d.get_files():
			if not f.ends_with(".tres"):
				continue
			var text := FileAccess.get_file_as_string(dir + f)
			if not scene_path in text:
				continue
			var res := load(dir + f)
			if res == null:
				continue
			unit = {"found": true, "file": dir + f}
			for k: String in ["id", "faction", "body_height", "radius", "is_worker", "move_speed", "flying"]:
				var v: Variant = res.get(k)
				if v != null:
					unit[k] = v
			return


func _show_viewport() -> void:
	var tr := TextureRect.new()
	tr.name = "LabView"
	tr.texture = stage.vp.get_texture()
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(tr)


# ================================================================ helpers

func _frames(n: int) -> void:
	for i: int in n:
		await get_tree().process_frame


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _call(o: Object, method: StringName, a: Array = []) -> bool:
	if is_instance_valid(o) and o.has_method(method):
		o.callv(method, a)
		return true
	return false


func _save(img: Image, shot: String, png: bool = false) -> void:
	var file := shot + (".png" if png else ".jpg")
	var path := ProjectSettings.globalize_path(out_dir.path_join(file))
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if png:
		img.save_png(path)
	else:
		img.save_jpg(path, 0.9)
	rep.shots[shot] = file


func _tile(img: Image, label: String) -> void:
	tiles.append({"img": img, "label": label})


## A 16:9 crop of `img` centred on `c` (px), at least `min_size`, scaled back to fit.
func _crop(img: Image, c: Vector2, min_size: Vector2i) -> Image:
	var w := mini(maxi(min_size.x, int(float(min_size.y) * 16.0 / 9.0)), img.get_width())
	var h := mini(int(float(w) * 9.0 / 16.0), img.get_height())
	var x := clampi(int(c.x) - w / 2, 0, img.get_width() - w)
	var y := clampi(int(c.y) - h / 2, 0, img.get_height() - h)
	return img.get_region(Rect2i(x, y, w, h))


## A 16:9 crop around a world box as the current camera sees it (pad = extra share of the box size on each side).
func _crop_box(img: Image, box: AABB, pad: float = 0.25) -> Image:
	var roi := stage.roi_of(box, 0)
	var w := int(float(roi.size.x) * (1.0 + 2.0 * pad))
	var h := int(float(roi.size.y) * (1.0 + 2.0 * pad))
	return _crop(img, Vector2(roi.get_center()), Vector2i(maxi(w, 96), maxi(h, 54)))


func _sil(root: Node) -> Image:
	stage.set_mode(&"sil")
	var rec := stage.override(root, stage.black_mat, ground_y)
	var img: Image = await stage.grab()
	stage.restore(rec)
	stage.set_mode(&"lit")
	return img


func _count_nodes(n: Node) -> int:
	return n.find_children("*", "", true, false).size() + 1 if is_instance_valid(n) else 0


func _spawn(path: String, at: Vector3, yaw_deg: float, parent: Node = null) -> Node3D:
	var ps := load(path) as PackedScene
	if ps == null:
		return null
	var h := Node3D.new()
	h.position = at
	h.rotation.y = deg_to_rad(yaw_deg)
	(parent if parent else stage.world).add_child(h)
	var inst := ps.instantiate() as Node3D
	if inst == null:
		h.queue_free()
		return null
	h.add_child(inst)
	return inst


func _free_model(n: Node3D) -> void:
	if is_instance_valid(n) and is_instance_valid(n.get_parent()):
		n.get_parent().queue_free()


func _model_color(n: Object) -> Color:
	var c: Variant = n.get(&"kingdom_color") if is_instance_valid(n) else null
	if c is Color:
		return c
	return ArtLabBudgets.KINGDOM_COLORS.get(kingdom, Color(0.5, 0.5, 0.5))


func _fmt(v: float, d: int = 1) -> String:
	return String.num(v, d)


# ================================================================ model kinds (unit, mount, titan, beast, critter,
# building, landmark)

func _run_model() -> void:
	gp = ArtLabStage.GROUND_POINTS[ground_id]
	ground_y = gp.y
	await _spawn_target()
	if target == null:
		rep.add("H0", "health", "Scene instantiates", "FAIL", "instantiate() failed or the root is not a Node3D",
			"art-units 8 / 10: every model instantiates without errors", "Open the scene, fix the errors in the Output")
		return
	rep.add("H0", "health", "Scene instantiates", "PASS", "root %s, %d nodes" % [target.get_class(), _count_nodes(target)],
		"instantiates without errors")
	_read_model_props()
	var cen := ArtLabCensus.census(target, ground_y)
	m["census"] = cen
	_check_budgets(cen)
	await _check_instances()
	_check_hooks()
	await _action_cycle()
	if headless:
		await _death_check([], false)
		for id_name: Array in [["R1", "Silhouette area at 40 m"], ["R2", "Distinct from references"],
				["R3", "Contrast vs ground"], ["R5", "Glow points at 40 m"], ["R6", "Team-colour visibility"],
				["B13", "Frame cost"]]:
			rep.add(id_name[0], "read" if String(id_name[0]).begins_with("R") else "budget", id_name[1], "SKIP",
				"headless", "needs a windowed run (1600 x 900)")
		_check_geometry()
		return
	_check_geometry()
	await _shots()
	await _read_40()
	await _turns()
	await _anim_strip()
	if opts.get("quick", "0") != "1":
		await _refs()
		await _frame_cost()
	else:
		rep.notes.append("quick=1: references (R2) and frame cost (B13) skipped")


func _spawn_target() -> void:
	var ps := load(scene_path) as PackedScene
	if ps == null:
		return
	holder = Node3D.new()
	holder.name = "Target"
	holder.position = gp
	holder.rotation.y = deg_to_rad(MAIN_YAW)
	stage.world.add_child(holder)
	var authored: Array[String] = []
	var cb := func(n: Node) -> void:
		if target != null and is_instance_valid(target) and n is GeometryInstance3D and not ArtLabCensus.is_particles(n) \
				and target.is_ancestor_of(n) and not String(n.name).begins_with("Merged"):
			authored.append(String(n.name))
	get_tree().node_added.connect(cb)
	var inst := ps.instantiate()
	target = inst as Node3D
	if target == null:
		if inst:
			inst.free()
		get_tree().node_added.disconnect(cb)
		return
	holder.add_child(target)
	await _frames(4)
	get_tree().node_added.disconnect(cb)
	m["authored"] = authored.size()
	await _settle(target)


## Lets a fresh instance finish its spawn animation / spawn effects before any shot (Sapling sprout 0.5 s, spawn
## rings): known skip hooks first, then a 0.6 s grace, then wait for the one-shot emitters to finish (<= 3 s).
func _settle(inst: Node) -> void:
	if not is_instance_valid(inst):
		return
	for h: StringName in [&"skip_spawn", &"skip_spawn_animation", &"finish_spawn"]:
		_call(inst, h)
	_fix_idle_phase(inst)
	await _wait(0.6)
	var t0 := Time.get_ticks_msec()
	var tail := 0.0
	while float(Time.get_ticks_msec() - t0) < 3000.0:
		var busy := false
		for gi: GeometryInstance3D in ArtLabCensus.geometry(inst):
			if ArtLabCensus.is_particles(gi) and bool(gi.get("one_shot")) and bool(gi.get("emitting")) and gi.is_visible_in_tree():
				busy = true
				tail = maxf(tail, float(gi.get("lifetime")))
		if not busy:
			break
		await _frames(3)
	if tail > 0.0:
		await _wait(minf(tail, 1.5))   # the last particles of the finished one-shots fade out
	if not m.has("settle_s") and inst == target:
		m["settle_s"] = float(Time.get_ticks_msec() - t0) / 1000.0 + 0.6


## Lab v2.1: the kit picks each model's idle phase from hash(instance id) in _ready (CharacterModel `_phase_off`,
## flyers also `_flap_p`), so the same asset stood in another idle pose every run (scores moved by a few points) and
## two flyers were compared at random wing phases (R2). Every instance the lab spawns gets phase 0 instead: runs are
## repeatable and the target, its references and team-colour copies share one idle phase.
func _fix_idle_phase(inst: Node) -> void:
	if not is_instance_valid(inst):
		return
	var nodes: Array[Node] = [inst]
	nodes.append_array(inst.find_children("*", "", true, false))
	for n: Node in nodes:
		if &"_phase_off" in n:
			n.set(&"_phase_off", 0.0)
			if &"_flap_p" in n:
				n.set(&"_flap_p", 0.0)
			m["phase_fixed"] = int(m.get("phase_fixed", 0)) + 1


func _read_model_props() -> void:
	var bh: Variant = unit.get("body_height", target.get(&"body_height"))
	body_height = float(bh) if bh != null else 0.0
	var r: Variant = unit.get("radius", null)
	radius = float(r) if r != null else float(DEFAULT_RADIUS.get(kind, 0.5))
	flyer = target.get(&"fly_height") != null
	var s: Variant = target.get(&"stride_speed")
	stride = float(s) if s != null and float(s) > 0.0 else float(unit.get("move_speed", 3.0))
	var vb := ArtLabCensus.vertex_bounds(target, holder.global_transform, ground_y)
	m["bounds"] = vb
	if body_height <= 0.0:
		body_height = (vb["max"] as Vector3).y
	var claim: Variant = target.call(&"authored_mesh_count") if target.has_method(&"authored_mesh_count") else null
	if claim != null:
		m["authored_claim"] = int(claim)


func _check_budgets(cen: Dictionary) -> void:
	var r := rep.budget_row
	var src: String = r.get("src", "")
	var rows: Array = [
		["B1", "Meshes after the kit merge", "meshes", int(cen["meshes"]) + int(cen["multimeshes"]),
			"Merge static parts per pivot (kit merge), drop hidden / duplicate parts, repeats as one MultiMesh"],
		["B2", "Draw instances at rest", "draw", int(cen["draw"]),
			"Fewer keep_separate parts, bake static props into one mesh, one MultiMesh per repeated part"],
		["B3", "keep_separate parts", "separate", int(cen["separate"]),
			"Only toggled / animated / own-glow parts stay separate (art-units 2.3)"],
		["B4", "Vertices", "verts", int(cen["verts"]), "Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces"],
		["B4t", "Triangles", "tris", int(cen["tris"]), "Fewer segments; critters use a vertex-shader cycle, not more geometry"],
		["B5", "Real lights", "lights", int(cen["lights"]),
			"No Light3D: emission >= 2.5 on the glow part and the bloom carries it (art-keep 0.4)"],
		["B6", "Particle systems", "systems", int(cen["systems"]), "One system with emission points instead of several; pre-built one-shots"],
		["B6l", "Looping particle systems", "looping", int(cen["looping"]),
			"Looping systems only where the spec lists them; stop them beyond 45 m (kit does it for GPUParticles3D)"],
		["B6p", "Looping particles alive", "particles", int(cen["particles"]), "Lower `amount`, longer lifetime, bigger soft sprites"],
		["B7", "Shadow casters", "casters", int(cen["casters"]), "cast_shadow only on the 3-4 biggest parts (art-units 1.5 / 8)"],
		["B8", "Unique materials", "materials", int(cen["materials"]), "Snap to the closed palette (art-units 2.2); no per-part materials"],
	]
	for row_def: Array in rows:
		var key: String = row_def[2]
		var v: int = row_def[3]
		var lim := ArtLabBudgets.limit(r, key)
		if lim.is_empty():
			if key in ["meshes", "draw", "verts", "materials", "casters"] or v > 0:
				if key == "tris" or (key == "separate" and v == 0):
					continue
				rep.add(row_def[0], "budget", row_def[1], "INFO", str(v), "no budget for %s/%s" % [kind, tier])
			continue
		var st := ArtLabReport.budget_status(float(v), lim)
		var l := float(lim["limit"])
		var extra := ""
		if key == "meshes":
			extra = " drawn (%d mesh + %d multimesh)" % [int(cen["meshes"]), int(cen["multimeshes"])]
			var piv := _meshes_per_pivot(cen["mesh_list"])
			if not piv.is_empty():
				extra += "; per pivot: " + ", ".join(PackedStringArray(piv.slice(0, 6).map(func(p: Array) -> String: return "%s %d" % [p[0], p[1]])))
				if st != "PASS" and int(piv[0][1]) >= 3:
					rep.extras.push_front({"title": "Meshes per pivot", "source": "B1", "text":
						"Pivot %s draws %d meshes: merge its static parts into one (the kit merge works per pivot; separate materials or keep_separate parts stop it)" % [piv[0][0], int(piv[0][1])]})
		if key == "verts" and not (cen["mesh_list"] as Array).is_empty():
			var top: Array[String] = []
			for me: Dictionary in (cen["mesh_list"] as Array).slice(0, 4):
				top.append("%s %d" % [String(me["name"]).get_file(), int(me["verts"])])
			extra = " (biggest: %s)" % ", ".join(top)
		if key == "lights" and v > 0:
			extra = " (%s)" % ", ".join(PackedStringArray(cen["light_names"]))
		if key == "looping" and v > 0:
			extra = " (%s)" % ", ".join(PackedStringArray(cen["looping_names"]))
		if key == "casters" and v > 0:
			extra = " (%s)" % ", ".join(PackedStringArray((cen["caster_names"] as Array).slice(0, 6)))
		var g := ArtLabReport.grade(float(v), l * 1.3 + 1.0, l * 0.7) if l > 0.0 else (1.0 if v == 0 else 0.0)
		rep.add(row_def[0], "budget", row_def[1], st, "%d%s" % [v, extra],
			"<= %s%s (%s)" % [str(lim["limit"]), "" if bool(lim["hard"]) else " soft", src],
			row_def[4] if st != "PASS" else "", g, "" if st == "PASS" else row_def[4])
	# B1a: authored build parts before the merge (v1's B1; INFO since the user decision 2026-09-26: render cost counts)
	var authored := int(m.get("authored", cen["meshes"]))
	var lim_m := ArtLabBudgets.limit(r, "meshes")
	rep.add("B1a", "budget", "Authored build parts (before the merge)", "INFO", "%d%s" % [authored,
		(" (model says %d)" % int(m["authored_claim"])) if m.has("authored_claim") else ""],
		"info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes)%s" % ((", v1 limit %s" % str(lim_m["limit"])) if not lim_m.is_empty() else ""))
	# per-mesh vertex breakdown, surfaces, downward-facing waste
	var ml: Array = cen["mesh_list"]
	if not ml.is_empty():
		var rows_txt: Array[String] = []
		for me2: Dictionary in ml.slice(0, 8):
			rows_txt.append("%s %d v / %d s%s" % [String(me2["name"]), int(me2["verts"]), int(me2["surfaces"]),
				(" x%d" % int(me2["n"])) if int(me2["n"]) > 1 else ""])
		rep.notes.append("Per-mesh vertices (biggest first): " + "; ".join(rows_txt))
		var surf := int(cen["surfaces"])
		rep.add("B11", "budget", "Surfaces per instance", "INFO", "%d surfaces over %d meshes (each surface = 1 draw call)" % [surf, ml.size()],
			"about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes",
			"", -1.0, "")
		var dn := int(cen["down_tris"])
		var share := float(dn) / float(maxi(int(cen["tris"]), 1))
		# INFO + hint only: rounded bodies have ~15 % steep-down faces by nature; above ~25 % caps / undersides are waste
		rep.add("B12", "budget", "Downward-facing triangles", "INFO", "%d of %d triangles (%d%%) face steeply down (normal y < -0.7)" % [dn, int(cen["tris"]), int(share * 100.0)],
			"hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest",
			"", -1.0, "")
		if share > 0.25 and dn > 150:
			rep.extras.push_front({"title": "Downward-facing waste", "source": "B12", "text":
				"Drop bottom caps / undersides (cylinders, boxes, plinths, hat brims seen from below): %d%% of the triangles face down and are never seen" % int(share * 100.0)})
		if surf > ml.size() + 2:
			rep.extras.push_front({"title": "Surfaces per instance", "source": "B11", "text":
				"Merge surfaces that share a material (%d surfaces for %d meshes = %d draw calls)" % [surf, ml.size(), surf]})
	if int(cen["hidden_parts"]) > 0:
		rep.notes.append("%d hidden parts at rest (toggled states, not counted as draws)" % int(cen["hidden_parts"]))
	if int(cen["code_materials"]) > 0:
		rep.notes.append("%d materials are built in code (fine when cached per type: see B9)" % int(cen["code_materials"]))


## B1 breakdown: drawn meshes grouped by their parent node (the kit pivot: Torso, Head, ArmR...), biggest first,
## as [[pivot, count], ...]. A pivot with several drawn meshes is where a merge is missing.
func _meshes_per_pivot(mesh_list: Array) -> Array:
	var by := {}
	for me: Dictionary in mesh_list:
		var p := String(me["name"]).get_base_dir()
		var key := p.get_file() if p != "" else "(root)"
		by[key] = int(by.get(key, 0)) + 1
	var out: Array = []
	for k: String in by:
		out.append([k, int(by[k])])
	out.sort_custom(func(a: Array, b: Array) -> bool: return int(a[1]) > int(b[1]) or (int(a[1]) == int(b[1]) and String(a[0]) < String(b[0])))
	return out


func _check_instances() -> void:
	var r1 := ArtLabCensus.resource_ids(target)
	var far := Node3D.new()
	far.position = gp + Vector3(400.0, 0.0, 400.0)
	stage.world.add_child(far)
	var second := _spawn(scene_path, Vector3.ZERO, 0.0, far)
	await _frames(4)
	if second == null:
		far.queue_free()
		return
	var r2 := ArtLabCensus.resource_ids(second)
	var mats := 0
	var meshes := 0
	for id: int in r2["materials"]:
		if not (r1["materials"] as Dictionary).has(id):
			mats += 1
	for id2: int in r2["meshes"]:
		if not (r1["meshes"] as Dictionary).has(id2):
			meshes += 1
	far.queue_free()
	var lim := ArtLabBudgets.limit(rep.budget_row, "runtime_mats")
	var st := ArtLabReport.budget_status(float(mats), lim) if not lim.is_empty() else ("WARN" if mats > 0 else "PASS")
	# art-keep 8.6: a building may duplicate its materials once per instance (selection rim, owner colour, damage
	# tint): a handful of buildings per map, so accepted (INFO, full score) up to 2x the building's own material
	# budget; beyond that it is a real per-instance leak (WARN).
	var accepted := false
	if kind in [&"building", &"landmark"] and st == "WARN":
		var mlim := ArtLabBudgets.limit(rep.budget_row, "materials")
		var cap := int(float(mlim["limit"]) * 2.0) if not mlim.is_empty() else 16
		if mats <= cap:
			st = "INFO"
			accepted = true
	rep.add("B9", "health", "Materials built per instance", st, "%d material(s), %d mesh(es) not shared by a 2nd instance%s" % [mats, meshes,
		" (per-building copies, accepted by art-keep 8.6)" if accepted else ""],
		"0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6)",
		"Cache built materials / meshes in a static dictionary keyed by type (or save them as .tres / .res); per-unit looks go through instance uniforms",
		1.0 if mats == 0 or accepted else 0.0, "" if mats == 0 or accepted else "Share the %d per-instance material(s) (static cache) so 200 units do not build 200 copies" % mats)
	if meshes > 0 and mats == 0:
		rep.add("B9m", "health", "Meshes built per instance", "WARN", "%d mesh(es) per instance" % meshes,
			"meshes shared per type", "Build meshes once (static cache or .res) and share them", 0.5,
			"Cache the %d per-instance mesh(es) in a static dictionary" % meshes)


func _check_hooks() -> void:
	var need := ArtLabCensus.expected_hooks(kind)
	if need.is_empty():
		return
	var missing: Array[String] = []
	for h: String in need:
		if not ArtLabCensus.has_hook(target, h):
			missing.append(h)
	var st := "PASS" if missing.is_empty() else "WARN"
	rep.add("A1", "anim", "Standard hooks", st, "missing: " + ", ".join(missing) if not missing.is_empty() else "all %d present" % need.size(),
		", ".join(need), "Add the missing hooks (gameplay calls them through has_method; missing = no animation)",
		1.0 - float(missing.size()) / float(need.size()), "" if missing.is_empty() else "Implement %s" % ", ".join(missing))


## Runs the usual actions once and watches for nodes / materials created after _ready.
func _action_cycle() -> void:
	var nodes0 := _count_nodes(target)
	var seen1: Dictionary = (ArtLabCensus.resource_ids(target)["materials"] as Dictionary).duplicate()
	var created: Array[int] = [0]
	var cb := func(n: Node) -> void:
		if is_instance_valid(target) and target.is_ancestor_of(n):
			created[0] += 1
	get_tree().node_added.connect(cb)
	# Cycle 1 learns every material the actions show (cached / swapped ones included); cycle 2 counts only materials
	# never seen before: a material.duplicate() per action shows up again, a static cache does not.
	await _actions_once(seen1)
	var created1 := created[0]
	var nodes1 := _count_nodes(target)
	var seen2: Dictionary = {}
	await _actions_once(seen2)
	get_tree().node_added.disconnect(cb)
	var created2 := created[0] - created1
	var new_mats := 0
	var swapped := 0
	for id: int in seen2:
		if seen1.has(id):
			continue
		if String(seen2[id]) != "":
			swapped += 1   # a saved resource: shared, never "built"
			continue
		new_mats += 1
	if swapped > 0:
		rep.notes.append("B10: %d saved material(s) swapped in by the actions (shared resources, not counted)" % swapped)
	var net := nodes1 - nodes0
	var hard := kind in [&"unit", &"mount", &"titan", &"beast", &"critter"]
	var st := "PASS"
	if new_mats > 0:
		st = "FAIL" if hard else "WARN"
	elif created1 > 0 or net > 0:
		st = "WARN"
	rep.add("B10", "health", "Allocations after _ready (actions)", st,
		"%d node(s) created, net %+d, 2nd action cycle: %d node(s), %d new material(s)" % [created1, net, created2, new_mats],
		"0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new",
		"Pre-build the effect nodes as hidden children and restart / toggle them; never material.duplicate() in an action",
		1.0 if st == "PASS" else (0.5 if st == "WARN" else 0.0),
		"" if st == "PASS" else "Pre-build what the actions create (%d nodes, %d materials) and reuse it" % [created1, new_mats])


## One pass of the kind's usual actions; every material the model shows after each step goes into `seen`.
func _actions_once(seen: Dictionary) -> void:
	var sample := func() -> void:
		if is_instance_valid(target):
			seen.merge(ArtLabCensus.resource_ids(target)["materials"])
	await _actions_steps(sample)


func _actions_steps(sample: Callable) -> void:
	match kind:
		&"building", &"landmark":
			_call(target, &"set_selected", [true])
			_call(target, &"set_health_ratio", [0.4])
			await _wait(0.6)
			sample.call()
			_call(target, &"play_training_pulse")
			await _wait(0.8)
			sample.call()
			_call(target, &"set_health_ratio", [1.0])
			_call(target, &"set_selected", [false])
			await _wait(0.6)
			sample.call()
		&"critter":
			for step: Array in [[&"play_move", [stride], 0.8], [&"play_flee", [], 0.6], [&"play_hit", [], 0.4], [&"play_idle", [], 0.6]]:
				_call(target, step[0], step[1])
				await _wait(float(step[2]))
				sample.call()
		_:
			if _call(target, &"set_moving", [stride]):
				await _wait(1.0)
				sample.call()
				_call(target, &"set_moving", [0.0])
			if _call(target, &"play_attack"):
				await _wait(1.0)
				sample.call()
			if _call(target, &"play_hit"):
				await _wait(0.5)
				sample.call()
			if kind == &"beast" or tier in [&"wizard", &"champion"]:
				if _call(target, &"play_cast", [&"lab_cast"]):
					await _wait(1.0)
					sample.call()
			await _wait(0.5)
			sample.call()


## play_death -> death_finished within 2 s (the gameplay fallback frees the unit at 2.0 s).
func _death_check(strip: Array, capture: bool) -> void:
	if not target.has_method(&"play_death"):
		return
	var t_done: Array[float] = [-1.0]
	var t0 := Time.get_ticks_msec()
	var has_sig := target.has_signal(&"death_finished")
	var cb := func() -> void:
		if t_done[0] < 0.0:
			t_done[0] = float(Time.get_ticks_msec() - t0) / 1000.0
	if has_sig:
		target.connect(&"death_finished", cb, CONNECT_ONE_SHOT)
	target.call(&"play_death")
	if capture:
		await _wait(0.45)
		ArtLabStage.freeze(target, true)
		strip.append({"img": await stage.grab(), "label": "death 0.45 s"})
		ArtLabStage.freeze(target, false)
	var guard := 0
	while t_done[0] < 0.0 and float(Time.get_ticks_msec() - t0) < 3000.0 and guard < 600:
		await get_tree().process_frame
		guard += 1
	if capture:
		strip.append({"img": await stage.grab(), "label": "death end (%s s)" % _fmt(t_done[0], 2)})
	if not has_sig:
		return
	var t: float = t_done[0]
	var st := "PASS" if t >= 0.0 and t <= 2.0 else "WARN"
	rep.add("A2", "anim", "death_finished", st, "after %s s" % _fmt(t, 2) if t >= 0.0 else "never (3 s)",
		"emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7)",
		"Emit death_finished at the end of the death timeline (it must fire even at the far distance tier)",
		1.0 if st == "PASS" else 0.3)
	if target.has_method(&"revive"):
		target.call(&"revive")
		await _wait(0.3)


func _check_geometry() -> void:
	var vb: Dictionary = m.get("bounds", {})
	if vb.is_empty():
		return
	var lo: Vector3 = vb["min"]
	var hi: Vector3 = vb["max"]
	var rules := ArtLabBudgets.read_rules(kind, tier)
	# R9 feet on the ground
	var feet: StringName = rules.get("feet", &"ground")
	if flyer:
		rep.add("R9", "read", "Feet on the ground", "INFO", "flyer: lowest point %s m (hovers)" % _fmt(lo.y, 2),
			"flyers hover (FlyerModel fly_height)")
	elif feet == &"base":
		var st := "PASS" if lo.y <= 0.05 else "FAIL"
		if lo.y < -1.0 and kind == &"building":
			st = "WARN"   # landmarks may be half buried on purpose (fallen colossus, stumps)
		rep.add("R9", "read", "Ground contact", st, "lowest point %s m" % _fmt(lo.y, 2),
			"touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5)",
			"Sink the plinth / base 0.05-0.3 m into the ground and add the contact decal", 1.0 if st == "PASS" else 0.2)
	else:
		var st2 := "PASS"
		var hint := ""
		if lo.y > 0.15:
			st2 = "FAIL"
			hint = "Lower the feet: the model floats %s m above the ground" % _fmt(lo.y, 2)
		elif lo.y > 0.05:
			st2 = "WARN"
			hint = "Lower the feet %s m (they hover)" % _fmt(lo.y, 2)
		elif lo.y < -0.08:
			st2 = "WARN"
			hint = "A part sits %s m below y 0 (art-units 1.6: nothing below the ground but the blob)" % _fmt(-lo.y, 2)
		rep.add("R9", "read", "Feet on the ground", st2, "lowest point %s m" % _fmt(lo.y, 3),
			"-0.08 .. +0.05 m (art-units 1.6)", hint, 1.0 if st2 == "PASS" else (0.5 if st2 == "WARN" else 0.0), hint)
	# R8 head height vs body_height, top parts narrower than 0.35 m (wizards / champions: identity-crest tolerance)
	if bool(rules.get("head", false)) and body_height > 0.0:
		var head_max: float = rules.get("head_max", 1.25)
		var top_w: float = rules.get("top_width", 0.35)
		var crest := bool(rules.get("crest", false))
		var head := target.get_node_or_null("Root/Chest/Head") as Node3D
		if head:
			var hb := ArtLabCensus.vertex_bounds(head, holder.global_transform, ground_y)
			var top: float = (hb["max"] as Vector3).y
			var ratio := top / body_height
			var st3 := "PASS" if ratio >= 0.75 and ratio <= head_max else "WARN"
			rep.add("R8", "read", "Head height vs body_height", st3,
				"head top %s m / body_height %s (x%s)" % [_fmt(top, 2), _fmt(body_height, 2), _fmt(ratio, 2)],
				"x0.75-%s (art-units 1.1: the HP bar hangs at body_height + 0.5%s)" % [_fmt(head_max, 2), "; identity crest allowed for %s" % tier if crest else ""],
				"Set body_height (UnitType + scene) to the head top, or rescale the body", 1.0 - clampf(absf(clampf(ratio, 0.75, 1.0) - ratio) * 2.0, 0.0, 1.0))
		var tb := ArtLabCensus.vertex_bounds(target, holder.global_transform, ground_y, body_height + 0.4)
		var wide: Array[String] = []
		var crests: Array[String] = []
		for p: Dictionary in tb["top_parts"]:
			var wtxt := "%s %s m" % [String(p["name"]).get_file(), _fmt(float(p["width"]), 2)]
			if float(p["width"]) > top_w:
				wide.append(wtxt)
			elif float(p["width"]) > 0.35:
				crests.append(wtxt)
		if not wide.is_empty():
			rep.add("R8w", "read", "Parts above body_height + 0.4", "WARN", ", ".join(wide),
				"narrower than %s m (art-units 1.1: the HP bar stays readable%s)" % [_fmt(top_w, 2), "; crest tolerance" if crest else ""],
				"Narrow the hat / horn / staff head above the bar line", 0.5, "Narrow %s so the HP bar reads over the head" % ", ".join(wide))
		elif not crests.is_empty():
			rep.add("R8w", "read", "Parts above body_height + 0.4", "INFO", "identity crest: " + ", ".join(crests),
				"%s tier: a crest up to %s m wide is part of the identity (the HP bar sits on it)" % [tier, _fmt(top_w, 2)])
	# R10 footprint (thin "line" parts under 8 cm, e.g. spear shafts / staffs / bow strings, do not count)
	if kind in [&"unit", &"mount", &"beast", &"critter"]:
		var tlo: Vector3 = vb.get("min_thick", lo)
		var thi: Vector3 = vb.get("max_thick", hi)
		var ext_x := maxf(absf(tlo.x), absf(thi.x))
		var ext_z := maxf(absf(tlo.z), absf(thi.z))
		var full_x := maxf(absf(lo.x), absf(hi.x))
		var full_z := maxf(absf(lo.z), absf(hi.z))
		var line_parts: Array = vb.get("line_parts", [])
		var quad := bool(target.get(&"is_quadruped")) if target.get(&"is_quadruped") != null else false
		var lim_x := radius * 1.4
		var lim_z := radius * (2.4 if quad or kind != &"unit" else 1.4)
		var over := maxf(ext_x / lim_x, ext_z / lim_z)
		var st4 := "PASS" if over <= 1.25 else "WARN"   # 25 % slack: a tail tip or a swung weapon is fine
		if not unit.has("radius"):
			st4 = "INFO"   # no UnitType yet: the radius is a guess
		var lines_txt := ""
		if not line_parts.is_empty() and (full_x > ext_x + 0.01 or full_z > ext_z + 0.01):
			lines_txt = "; thin parts ignored (%s): with them x %s / z %s" % [", ".join(PackedStringArray(line_parts.slice(0, 3))), _fmt(full_x, 2), _fmt(full_z, 2)]
		rep.add("R10", "read", "Footprint vs selection radius", st4,
			"x %s / z %s m (radius %s%s)%s" % [_fmt(ext_x, 2), _fmt(ext_z, 2), _fmt(radius, 2), ", from " + String(unit.get("file", "")).get_file() if unit.has("file") else ", default", lines_txt],
			"x <= radius x 1.4, z <= x %s (art-units 1.1; parts thinner than 8 cm ignored)" % ("2.4" if lim_z > lim_x else "1.4"),
			"Pull wide parts in, or raise UnitType.radius", 1.0 if st4 == "PASS" else (0.5 if st4 == "WARN" else -1.0))


# ---------------------------------------------------------------- shots

func _shots() -> void:
	stage.set_mode(&"lit")
	var box := ArtLabCensus.world_aabb(target, ground_y)
	m["box"] = box
	for z: float in [40.0, 55.0, 25.0]:
		stage.game_cam(gp, z)
		var img: Image = await stage.grab()
		_save(img, "z%d" % int(z))
		var roi := stage.roi_of(box, 8)
		var c := Vector2(roi.get_center())
		var crop := _crop(img, c, Vector2i(maxi(roi.size.x * 3, 320), maxi(roi.size.y * 3, 180)))
		_tile(crop, "%d m game camera (crop, real pixels)" % int(z))
		if z == 40.0:
			m["img40"] = img
	stage.fit_cam(box, 20.0, 0.0, 0.8)
	var close: Image = _crop_box(await stage.grab(), box, 0.12)
	_save(close, "close")
	_tile(close, "close-up 3/4")


## Readability at 40 m (and 25 / 55): silhouette, contrast on every ground, glow, team colour, HP bar, motion, polish.
func _read_40() -> void:
	var rules := ArtLabBudgets.read_rules(kind, tier)
	var box: AABB = m["box"]
	stage.game_cam(gp, 40.0)
	ArtLabStage.freeze(target, true)
	await _frames(2)
	var roi := stage.roi_of(box, 16)
	var sil: Image = await _sil(target)
	var mask := ArtLabImage.sil_mask(sil, roi)
	m["mask40"] = mask
	m["roi40"] = roi
	var lit: Image = await stage.grab()
	m["hgt40"] = await _height_pass(target)
	holder.visible = false
	var bg: Image = await stage.grab()
	holder.visible = true
	m["bg40"] = bg
	var con := ArtLabImage.contrast(lit, bg, roi, mask)
	# top third (world height) vs the ground: the part that reads over crowds and against the ground from pitch 55
	var top_mask := ArtLabImage.height_mask(mask, m["hgt40"], roi, 0.667, 1.0)
	if top_mask.count < 12:
		top_mask = ArtLabImage.top_rows(mask, 0.34)
	con["top"] = ArtLabImage.contrast(lit, bg, roi, top_mask) if top_mask.count > 0 else {}
	# R1 area
	var aw: int = rules.get("area_warn", 100)
	var af: int = rules.get("area_fail", 40)
	var area := mask.count
	stage.game_cam(gp, 55.0)
	var roi55 := stage.roi_of(box, 16)
	var mask55 := ArtLabImage.sil_mask(await _sil(target), roi55)
	stage.game_cam(gp, 40.0)
	var st := "PASS" if area >= aw else ("WARN" if area >= af else "FAIL")
	rep.add("R1", "read", "Silhouette area at 40 m", st, "%d px (%d x %d bbox; 55 m: %d px)" % [area, mask.bbox.size.x,
		mask.bbox.size.y, mask55.count], ">= %d px (FAIL < %d) at 1600 x 900" % [aw, af],
		"Exaggerate the big masses (art-keep 0.1 / art-units 1.1): wider shoulders, bigger weapon / head, a taller vertical",
		ArtLabReport.grade(float(area), float(af), float(aw) * 2.0),
		"Grow the read at 40 m (now %d px): push the key shape (weapon, horns, crest, back mass) 15-25 %% bigger" % area, "z40")
	if con.get("n", 0) == 0:
		rep.add("R3", "read", "Contrast vs ground", "FAIL", "no silhouette pixels at 40 m", "visible at 40 m")
		ArtLabStage.freeze(target, false)
		return
	# R3 contrast on the main ground
	_add_contrast("R3", String(ground_id), con, rules, true)
	m["con"] = con
	# R4 other grounds (same frozen pose, same camera offset)
	var worst := {}
	var worst_g := ""
	var lines: Array[String] = []
	var home := {}
	for g: StringName in OTHER_GROUNDS:
		if g == ground_id:
			continue
		# Same camera offset and frozen pose: the model lands on the same pixels, so roi and mask are reused.
		var p: Vector3 = ArtLabStage.GROUND_POINTS[g]
		holder.position = p
		stage.game_cam(p, 40.0)
		var roi_g := roi
		var lit_g: Image = await stage.grab()
		holder.visible = false
		var bg_g: Image = await stage.grab()
		holder.visible = true
		var cg := ArtLabImage.contrast(lit_g, bg_g, roi_g, mask)
		if int(cg.get("n", 0)) == 0:
			continue
		lines.append("%s dE %s" % [g, _fmt(float(cg["de_means"]))])
		if g == ArtLabBudgets.KINGDOM_GROUND.get(kingdom, &""):
			home = cg
		if worst.is_empty() or float(cg["de_means"]) < float(worst["de_means"]):
			worst = cg
			worst_g = String(g)
			m["worst_ground_img"] = _crop(lit_g, Vector2(roi_g.get_center()), Vector2i(maxi(roi_g.size.x * 3, 320), 180))
	holder.position = gp
	stage.game_cam(gp, 40.0)
	var home_g: StringName = ArtLabBudgets.KINGDOM_GROUND.get(kingdom, &"")
	if home_g == ground_id and home_g != &"":
		home = con
	if not home.is_empty():
		var hw: float = rules.get("de_warn", 20.0)
		var hde := float(home["de_means"])
		rep.add("R4k", "read", "Contrast on the home ground (%s)" % home_g, "PASS" if hde >= hw else "WARN",
			"dE %s, %d%% melts (%s is where %s units stand most)" % [_fmt(hde), int(float(home["melt_frac"]) * 100.0), home_g, kingdom],
			"dE >= %s on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh)" % _fmt(hw, 0),
			"A value step against the home ground: pale crests on dark ash / marsh, dark trims on snow",
			ArtLabReport.grade(hde, float(rules.get("de_fail", 10.0)) * 0.6, hw * 1.6),
			"On its home ground (%s) the body is only dE %s: add a value step for that ground" % [home_g, _fmt(hde)] if hde < hw * 1.2 else "", "z40")
	if not worst.is_empty():
		var de_fail: float = rules.get("de_fail", 10.0)
		var st4 := "WARN" if float(worst["de_means"]) < de_fail else "PASS"
		rep.add("R4", "read", "Contrast on the other grounds", st4, "worst %s: dE %s (%s)" % [worst_g, _fmt(float(worst["de_means"])),
			", ".join(lines)], "dE >= %s on every skirmish ground (WARN only)" % _fmt(de_fail, 0),
			"A value accent that works on dark and light grounds (a pale crest / dark saddle)",
			ArtLabReport.grade(float(worst["de_means"]), de_fail * 0.6, float(rules.get("de_warn", 18.0)) * 1.5),
			"On %s the body drops to dE %s: add a value accent that separates it there too" % [worst_g, _fmt(float(worst["de_means"]))], "z40")
		if m.has("worst_ground_img"):
			_tile(m["worst_ground_img"], "40 m on %s (worst ground)" % worst_g)
	# R5 glow points at the bloom level, phase 1 of 3 (same frozen pose as the mask); phases 2-3 at the end of _read_40
	var gstate := {"phases": [], "roi": roi, "mask": mask}
	await _glow_phase(gstate, mask, m.get("hgt40", null))
	# R6 team colour
	await _team_pass(rules, roi, mask)
	# R7 HP bar
	if rules.has("bar_warn") and body_height > 0.0:
		var bw := maxf(1.0, radius * 2.6)
		var centre := holder.global_position + Vector3(0.0, body_height + 0.5, 0.0)
		var bx := stage.cam.global_basis.x * (bw * 0.5)
		var by := stage.cam.global_basis.y * 0.08
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		for s: Vector3 in [centre - bx - by, centre + bx - by, centre - bx + by, centre + bx + by]:
			var q := stage.cam.unproject_position(s)
			lo = lo.min(q)
			hi = hi.max(q)
		var rect := Rect2i(Vector2i(int(lo.x) - roi.position.x, int(lo.y) - roi.position.y), Vector2i(int(hi.x - lo.x) + 1, int(hi.y - lo.y) + 1))
		var covered := float(ArtLabImage.count_in_rect(mask, rect)) / float(maxi(mask.count, 1))
		var gap := float(mask.bbox.position.y) - float(rect.end.y)
		var bwarn: float = rules["bar_warn"]
		var bfail: float = rules["bar_fail"]
		var st7 := "PASS" if covered <= bwarn else ("WARN" if covered <= bfail else "FAIL")
		rep.add("R7", "read", "HP bar over the body at 40 m", st7, "bar hides %d%% of the silhouette (gap %d px)" % [int(covered * 100.0), int(gap)],
			"<= %d%% (FAIL > %d%%); bar at body_height + 0.5 = %s m, %s m wide" % [int(bwarn * 100.0), int(bfail * 100.0), _fmt(body_height + 0.5, 2), _fmt(bw, 2)],
			"Keep tall parts under body_height + 0.4 or narrower than 0.35 m, or raise body_height to the real head top",
			ArtLabReport.grade(covered, bfail, 0.0), "" if st7 == "PASS" else "The HP bar hides %d%% of the body: lower / narrow what sticks up, or fix body_height" % int(covered * 100.0), "z40")
	# A3 attack pose change at 40 m
	var mot: float = rules.get("motion", 0.0)
	if mot > 0.0 and target.has_method(&"play_attack"):
		# Sample the timeline at 4 moments (custom attack styles peak at different times) and keep the biggest change.
		ArtLabStage.freeze(target, false)
		target.call(&"play_attack")
		var change := 0.0
		var strike := 0.0
		var t_prev := 0.0
		for t_s: float in [0.08, 0.14, 0.24, 0.36]:
			await _wait(t_s - t_prev)
			t_prev = t_s
			ArtLabStage.freeze(target, true)
			var mask_a := ArtLabImage.sil_mask(await _sil(target), roi)
			var ch := 1.0 - ArtLabImage.iou(mask, mask_a)
			if ch > change:
				change = ch
				strike = t_s
			ArtLabStage.freeze(target, false)
		await _wait(1.0)
		var st8 := "PASS" if change >= mot else "WARN"
		rep.add("A3", "anim", "Attack reads at 40 m", st8, "strike pose changes %d%% of the silhouette (t %s s)" % [int(change * 100.0), _fmt(strike, 2)],
			">= %d%% (1 - IoU rest vs strike)" % int(mot * 100.0), "Bigger wind-up / strike: the weapon or head should leave the body outline",
			ArtLabReport.grade(change, 0.0, mot * 2.5), "Push the attack pose: the strike should change >= %d%% of the 40 m silhouette (now %d%%)" % [int(mot * 250.0), int(change * 100.0)], "anim")
		ArtLabStage.freeze(target, true)
		await _frames(1)
	# polish: hook (complexity), value structure, detail density
	var cx := ArtLabImage.complexity(mask)
	rep.add("P1", "polish", "Silhouette hook", "INFO", "outline complexity %s" % _fmt(cx, 2), "a blob is ~1.3-1.8; a strong hook >= 2.2",
		"", ArtLabReport.grade(cx, 1.3, 2.6), "Give the 40 m silhouette a hook (now %s): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register)" % _fmt(cx, 2) if cx < 2.2 else "", "silhouette")
	# P3 by world height (top third of the model's height vs the bottom third), screen rows as a fallback
	var vbands := ArtLabImage.value_bands(lit, roi, mask)
	var how := "screen rows"
	var mt := ArtLabImage.height_mask(mask, m["hgt40"], roi, 0.667, 1.0)
	var mb := ArtLabImage.height_mask(mask, m["hgt40"], roi, 0.0, 0.333)
	if mt.count >= 8 and mb.count >= 8:
		vbands = Vector2(ArtLabImage.mean_l(lit, roi, mt), ArtLabImage.mean_l(lit, roi, mb))
		how = "world height"
	var dv := vbands.x - vbands.y
	rep.add("P3", "polish", "Tops light, bottoms dark", "INFO", "top third L* %s, bottom third L* %s (%+d, %s)" % [_fmt(vbands.x), _fmt(vbands.y), int(dv), how],
		"top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top)", "", ArtLabReport.grade(dv, -5.0, 12.0),
		"Lighten the top masses / darken the legs and base (top - bottom now %+d L*, aim >= +10)" % int(dv) if dv < 10.0 else "", "z40")
	stage.game_cam(gp, 25.0)
	var roi25 := stage.roi_of(box, 16)
	var mask25 := ArtLabImage.sil_mask(await _sil(target), roi25)
	var lit25: Image = await stage.grab()
	stage.game_cam(gp, 40.0)
	var d40 := ArtLabImage.detail(lit, roi, mask)
	var d25 := ArtLabImage.detail(lit25, roi25, mask25)
	var dscore := 1.0 - clampf(maxf(3.0 - d25, d25 - 11.0) / 4.0, 0.0, 1.0)
	var dimp := ""
	if d25 < 3.0:
		dimp = "Detail density is low at 25 m (%s): add 1-2 mid-size value blocks (trim band, belt, plate edge) that read at 25 m and merge at 40 m" % _fmt(d25)
	elif d25 > 11.0:
		dimp = "Busy at 25 m (%s): merge small value changes into bigger blocks so the 40 m read stays clean" % _fmt(d25)
	rep.add("P4", "polish", "Detail density 25 m / 40 m", "INFO", "inner detail %s at 25 m, %s at 40 m (mean |grad L*| per px)" % [_fmt(d25), _fmt(d40)],
		"about 3-11 at 25 m: readable blocks, no noise", "", dscore, dimp, "z25")
	# R5 glow phases 2-3 (idle moves on 0.37 s each; drifting motes and flickers are judged by the median)
	for ph_i: int in 2:
		ArtLabStage.freeze(target, false)
		await _wait(0.37)
		ArtLabStage.freeze(target, true)
		await _frames(1)
		var mk := ArtLabImage.sil_mask(await _sil(target), roi)
		await _glow_phase(gstate, mk if mk.count > 0 else mask, null)
	_glow_report(gstate, rules)
	ArtLabStage.freeze(target, false)


func _add_contrast(id: String, gname: String, con: Dictionary, rules: Dictionary, main: bool) -> void:
	# Primary: dE between the body's mean colour and the mean colour of the ground behind it (the 40 m "average read")
	# + the share of body pixels within dE 15 of that ground colour ("melt"). The per-pixel dE is shown for info.
	var de: float = con["de_means"]
	var melt: float = con["melt_frac"]
	var de_warn: float = rules.get("de_warn", 20.0)
	var de_fail: float = rules.get("de_fail", 10.0)
	var mw: float = rules.get("melt_warn", 0.35)
	var mf: float = rules.get("melt_fail", 0.6)
	var st := "PASS"
	if de < de_fail or melt > mf:
		st = "FAIL"
	elif de < de_warn or melt > mw:
		st = "WARN"
	var dl: float = con["dL"]
	# the hue gap only means something when the body is saturated (C* > 25): a grey-brown body has no real hue
	var chroma_ok := float(con["model_C"]) > 25.0
	var hue_txt := ("hue gap %d deg" % int(float(con["hue_gap"]))) if chroma_ok else "hue gap n/a (body C* <= 25)"
	var top: Dictionary = con.get("top", {})
	var top_txt := ""
	if int(top.get("n", 0)) > 0:
		top_txt = "; top third (world height) dE %s, L* %s" % [_fmt(float(top["de_means"])), _fmt(float(top["model_L"]))]
	var val := "mean-colour dE %s, %d%% of the body melts (within dE 15 of the ground); body L* %s C %s vs ground L* %s C %s, %s%s; per-pixel dE %s, outline %s" % [
		_fmt(de), int(melt * 100.0), _fmt(float(con["model_L"])), _fmt(float(con["model_C"])), _fmt(float(con["ground_L"])),
		_fmt(float(con["ground_C"])), hue_txt, top_txt, _fmt(float(con["de_mean"])), _fmt(float(con["edge_de"]))]
	var why: Array[String] = []
	if absf(dl) < 10.0:
		why.append("value is close to the ground (dL %+d): lighten the top / back 15-20 %% or add a dark saddle / pale belly band" % int(dl))
	if int(top.get("n", 0)) > 0 and float(top["de_means"]) < de_warn and de >= de_warn:
		why.append("the top third (what reads from pitch 55) is close to the ground (dE %s): lighten helmets / shoulders / back" % _fmt(float(top["de_means"])))
	if chroma_ok and float(con["hue_gap"]) < 35.0 and float(con["ground_C"]) > 12.0:
		why.append("the body sits in the ground's hue (gap %d deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it" % int(float(con["hue_gap"])))
	if why.is_empty():
		why.append("raise the value step between the big masses and the ground (dL %+d now)" % int(dl))
	var hint := "Melts into the %s: %s" % [gname, "; ".join(why)] if st != "PASS" else ""
	rep.add(id, "read", "Contrast vs ground (%s)" % gname, st, val,
		"mean-colour dE >= %s and <= 35 %% melting (FAIL: dE < %s or > 60 %% melting): the body must not melt into the grass" % [_fmt(de_warn, 0), _fmt(de_fail, 0)], hint,
		minf(ArtLabReport.grade(de, de_fail * 0.6, de_warn * 2.0), ArtLabReport.grade(melt, 0.7, 0.05)),
		("Raise the contrast of the key read on %s (dE %s): " % [gname, _fmt(de)]) + "; ".join(why), "z40", 1.5)


## World-height pass: grey = height above the ground / the model's top (P3 / P5 judge by world height, so flat
## creatures and quadrupeds seen at pitch 55 are not judged by screen rows).
func _height_pass(root: Node3D) -> Image:
	var top := maxf(float(((m.get("bounds", {}) as Dictionary).get("max", Vector3.ONE) as Vector3).y), 0.2)
	stage.height_mat.set_shader_parameter(&"y0", ground_y)
	stage.height_mat.set_shader_parameter(&"span", top)
	stage.set_mode(&"sil")
	var rec := stage.override(root, stage.height_mat, ground_y)
	var img: Image = await stage.grab()
	stage.restore(rec)
	stage.set_mode(&"lit")
	return img


## One glow phase: the "hot" frame (emission only, no bloom, 255 = the bloom level), flat decals and the model's own
## lights off. Clusters <= 4 px on the silhouette outline are a painted rim light, not glow points.
func _glow_phase(gs: Dictionary, mask: ArtLabImage.Mask, hgt: Variant) -> void:
	var roi: Rect2i = gs["roi"]
	var off: Array[Node3D] = []
	for ln: Node in target.find_children("*", "Light3D", true, false):
		if (ln as Light3D).visible:
			off.append(ln as Node3D)
			(ln as Light3D).visible = false
	for gi: GeometryInstance3D in ArtLabCensus.geometry(target):
		if gi.visible and ArtLabCensus.is_flat_decal(gi, ground_y):
			off.append(gi)
			gi.visible = false
	stage.set_mode(&"hot")
	var hot: Image = await stage.grab()
	var dark: Image = null
	if (gs["phases"] as Array).is_empty():
		stage.set_mode(&"dark")
		dark = await stage.grab()
	stage.set_mode(&"lit")
	for n: Node3D in off:
		n.visible = true
	var groi := ArtLabImage.clamp_rect(roi, 10, ArtLabStage.W, ArtLabStage.H)
	var dx := groi.position.x - roi.position.x
	var dy := groi.position.y - roi.position.y
	var all_cl := ArtLabImage.glow_clusters(hot, groi, 0.97, 3, 2, true)
	var surf_px := maxi(int(float(mask.count) * 0.15), 30)
	var pts: Array[Dictionary] = []
	var rim := 0
	var surfaces := 0
	for c0: Dictionary in all_cl:
		var mx := int(round(float(c0["x"]))) + dx
		var my := int(round(float(c0["y"]))) + dy
		c0["mx"] = mx
		c0["my"] = my
		if int(c0["area"]) > surf_px:
			surfaces += 1
		elif int(c0["area"]) <= 4 and ArtLabImage.near_edge(mask, mx, my, 2):
			rim += 1
			c0["rim"] = true
		else:
			pts.append(c0)
	var ph := {"points": pts, "rim": rim, "surfaces": surfaces, "all": all_cl}
	if dark != null:
		ph["dark"] = dark
		if hgt is Image:
			ph["hgt"] = hgt
	(gs["phases"] as Array).append(ph)


## Median of the glow phases -> R5 (+ per-part report) and P5 (world height).
func _glow_report(gs: Dictionary, rules: Dictionary) -> void:
	var phases: Array = gs["phases"]
	if phases.is_empty():
		return
	var roi: Rect2i = gs["roi"]
	var mask: ArtLabImage.Mask = gs["mask"]
	var surf_px := maxi(int(float(mask.count) * 0.15), 30)
	var counts: Array[int] = []
	for p: Dictionary in phases:
		counts.append((p["points"] as Array).size())
	var sorted := counts.duplicate()
	sorted.sort()
	var n_glow: int = sorted[sorted.size() / 2]
	var p0: Dictionary = phases[0]
	var best: Dictionary = p0
	for p2: Dictionary in phases:
		if (p2["points"] as Array).size() == n_glow:
			best = p2
			break
	var surfaces := int(best["surfaces"])
	var rim := int(best["rim"])
	var gr: Vector2i = rules.get("glow", Vector2i(1, 3))
	var st5 := "PASS" if n_glow >= gr.x and n_glow <= gr.y else "WARN"
	if n_glow < gr.x and surfaces > 0:
		st5 = "PASS"   # a glowing surface carries the glow read
	# per-part report: the smallest projected part box holding each point's centre
	var boxes: Array = []
	for gi: GeometryInstance3D in ArtLabCensus.geometry(target):
		if gi.is_visible_in_tree():
			boxes.append([stage.roi_of(gi.global_transform * gi.get_aabb(), 1), String(gi.name)])
	var parts: Dictionary = {}
	for c: Dictionary in best["points"]:
		var fp := Vector2i(roi.position.x + int(c["mx"]), roi.position.y + int(c["my"]))
		var nm := "?"
		var area_best := INF
		for b: Array in boxes:
			var rr: Rect2i = b[0]
			if rr.has_point(fp) and float(rr.get_area()) < area_best:
				area_best = float(rr.get_area())
				nm = b[1]
		parts[nm] = int(parts.get(nm, 0)) + 1
	var plist: Array[String] = []
	for k: String in parts:
		plist.append(("%s x%d" % [k, int(parts[k])]) if int(parts[k]) > 1 else k)
	var ctxt: Array[String] = []
	for v: int in counts:
		ctxt.append(str(v))
	# soft glows: v1's count (luma > 0.4 on the bloom render) for information, e.g. sap veins under the bloom level
	var soft := -1
	if p0.has("dark"):
		soft = ArtLabImage.glow_clusters(p0["dark"], ArtLabImage.clamp_rect(roi, 10, ArtLabStage.W, ArtLabStage.H), 0.4, 3, 2).size()
	var gtxt := "%d point(s) above the bloom level %s (median of %s)%s%s%s" % [n_glow, _fmt(stage.glow_level, 2),
		"/".join(ctxt), (": " + ", ".join(plist)) if not plist.is_empty() else "",
		(", + %d glowing surface(s)" % surfaces) if surfaces > 0 else "",
		(", %d rim-light speck(s) ignored" % rim) if rim > 0 else ""]
	if soft >= 0:
		gtxt += "; soft glows under the bloom (v1 count, luma > 0.4): %d" % soft
	var ghint := ""
	if n_glow < gr.x:
		ghint = "Add a glow point (eyes / rune / weapon, emission >= 2.5 so the bloom carries it)"
		if soft > 0:
			ghint += "; %d soft glow(s) sit under the bloom level: raise one to emission >= %s" % [soft, _fmt(stage.glow_level * 2.0, 1)]
	elif n_glow > gr.y:
		ghint = "Too many glow points read as noise: merge them or dim the small ones below the bloom level (%s): %s" % [_fmt(stage.glow_level, 1), ", ".join(plist)]
	rep.add("R5", "read", "Glow points at 40 m", st5, gtxt, "%d-%d above the bloom level (art-units 1.4 / art-keep 0.4)" % [gr.x, gr.y], ghint,
		1.0 if st5 == "PASS" else 0.4, ghint, "glow")
	if p0.has("dark"):
		var dimg: Image = (p0["dark"] as Image).duplicate()
		for c1: Dictionary in p0["all"]:
			var col := Color(0.2, 1.0, 0.3)
			if bool(c1.get("rim", false)):
				col = Color(0.6, 0.6, 0.6)
			elif int(c1["area"]) > surf_px:
				col = Color(1.0, 0.6, 0.1)
			_mark(dimg, roi.position.x + int(c1["mx"]), roi.position.y + int(c1["my"]), 5, col)
		_tile(_crop(dimg, Vector2(roi.get_center()), Vector2i(maxi(roi.size.x * 3, 320), 180)),
			"emission: %d glow point(s) boxed green (rim grey, surfaces orange)" % n_glow)
	# P5 glow placement by world height (glowing surfaces count too)
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
		rep.add("P5", "polish", "Glow placement", "INFO", "%d of %d glow(s) in the upper half of the model's height (world)" % [high, pts.size()],
			"one glow high (head / weapon / crest) reads over crowds", "", ArtLabReport.grade(frac, 0.0, 0.5),
			"Move or add one glow point to the upper half (head, weapon tip, crest) so it reads above other units" if high == 0 else "",
			"glow")


func _mark(img: Image, cx: int, cy: int, r: int, col: Color) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for i: int in range(-r, r + 1):
		for p: Vector2i in [Vector2i(cx + i, cy - r), Vector2i(cx + i, cy + r), Vector2i(cx - r, cy + i), Vector2i(cx + r, cy + i)]:
			if p.x >= 0 and p.y >= 0 and p.x < w and p.y < h:
				img.set_pixelv(p, col)


func _team_pass(rules: Dictionary, roi: Rect2i, mask: ArtLabImage.Mask) -> void:
	var need: float = rules.get("team", 0.0)
	if need <= 0.0 or kingdom == &"neutral" or not target.has_method(&"set_team_color"):
		if need > 0.0:
			rep.add("R6", "read", "Team-colour visibility", "INFO", "neutral / no set_team_color", "kingdom units only")
		return
	# One fresh instance per colour: set_team_color is a spawn-time hook (the kit ignores the scene's own colour and
	# keeps the first colour on material_override parts), so recolouring one model 4 times would lie.
	var imgs: Array[Image] = []
	holder.visible = false
	for k: StringName in [&"fire", &"shadow", &"ice", &"nature"]:
		var inst := _spawn(scene_path, gp, MAIN_YAW)
		if inst == null:
			continue
		inst.call(&"set_team_color", ArtLabBudgets.KINGDOM_COLORS[k])
		await _frames(2)
		await _settle(inst)
		ArtLabStage.freeze(inst, true)
		imgs.append(await stage.grab())
		_free_model(inst)
		await _frames(1)
	holder.visible = true
	if imgs.size() < 4:
		return
	var fr: Array[float] = []
	for i: int in 4:
		for j: int in range(i + 1, 4):
			fr.append(ArtLabImage.changed_fraction(imgs[i], imgs[j], roi, mask, 8.0))
	var mean := 0.0
	var lo := 1.0
	for f: float in fr:
		mean += f
		lo = minf(lo, f)
	mean /= float(fr.size())
	var st := "PASS" if mean >= need else ("WARN" if mean > 0.001 else "FAIL")
	rep.add("R6", "read", "Team-colour visibility at 40 m", st, "%d%% of body pixels change between kingdom colours (min pair %d%%)" % [int(mean * 100.0), int(lo * 100.0)],
		">= %d%% (FAIL = set_team_color changes nothing)" % int(need * 100.0),
		"Put the team colour on a big, top-facing mass (cloth, plates, cape, caparison); ~25-45 %% of the surface (art-keep 0.2 / art-units 1.3)",
		ArtLabReport.grade(mean, 0.0, 0.25),
		"Give the team colour more top-facing area (now %d%% of the 40 m body; aim ~20%%): shoulder cloth, a banner, the cape top" % int(mean * 100.0) if mean < 0.2 else "", "teams")
	# R3t: the same contrast with every team colour (an enemy / mirror colour must not melt either)
	if m.has("bg40"):
		var names: Array[String] = ["fire", "shadow", "ice", "nature"]
		var worst_de := INF
		var worst_k := ""
		var tl: Array[String] = []
		for i2: int in imgs.size():
			var ct := ArtLabImage.contrast(imgs[i2], m["bg40"], roi, mask)
			if int(ct.get("n", 0)) == 0:
				continue
			tl.append("%s %s" % [names[i2], _fmt(float(ct["de_means"]))])
			if float(ct["de_means"]) < worst_de:
				worst_de = float(ct["de_means"])
				worst_k = names[i2]
		if worst_de < INF:
			var dw: float = rules.get("de_warn", 20.0)
			var df: float = rules.get("de_fail", 10.0)
			var st3 := "PASS" if worst_de >= dw else "WARN"
			rep.add("R3t", "read", "Contrast in every team colour (%s)" % ground_id, st3, "worst %s colour: dE %s (%s)" % [worst_k, _fmt(worst_de), ", ".join(tl)],
				"dE >= %s in every kingdom colour (WARN only: mirror matches / enemy colours)" % _fmt(dw, 0),
				"Keep the team colour off the silhouette's biggest mass or give it a value step (trim, dark border)",
				ArtLabReport.grade(worst_de, df * 0.6, dw * 1.6),
				"In the %s team colour the body drops to dE %s on %s: add a value step around the team-colour area" % [worst_k, _fmt(worst_de), ground_id] if worst_de < dw * 1.2 else "", "teams")
	var crops: Array[Image] = []
	for img: Image in imgs:
		crops.append(_crop(img, Vector2(roi.get_center()), Vector2i(maxi(roi.size.x * 2, 200), 112)))
	_tile(ArtLabImage.grid(crops, 2, 400, 225), "team colours at 40 m: fire / shadow / ice / nature")


func _turns() -> void:
	var box: AABB = m["box"]
	stage.fit_cam(box.grow(0.2), 22.0, 0.0, 0.75)
	var imgs: Array[Image] = []
	var big := AABB()
	for yaw0: float in [0.0, 90.0]:
		holder.rotation.y = deg_to_rad(yaw0)
		var b0 := ArtLabCensus.world_aabb(target, ground_y)
		big = b0 if yaw0 == 0.0 else big.merge(b0)
	for yaw: float in [0.0, 90.0, 180.0, 270.0]:
		holder.rotation.y = deg_to_rad(yaw)
		imgs.append(_crop_box(await stage.grab(), big, 0.1))
	holder.rotation.y = deg_to_rad(MAIN_YAW)
	var sheet := ArtLabImage.grid(imgs, 2, 800, 450)
	_save(sheet, "turns")
	_tile(sheet, "turns 0 / 90 / 180 / 270")


func _anim_strip() -> void:
	var box: AABB = m["box"]
	stage.fit_cam(box.grow(0.4), 16.0, 0.0, 0.7)
	var strip: Array = []
	await _wait(0.3)
	strip.append({"img": await stage.grab(), "label": "idle"})
	match kind:
		&"building", &"landmark":
			if _call(target, &"set_construction_progress", [0.5]):
				await _wait(0.6)
				strip.append({"img": await stage.grab(), "label": "construction 50 %"})
				_call(target, &"set_construction_progress", [1.0])
				await _wait(0.8)
			if _call(target, &"set_health_ratio", [0.4]):
				await _wait(0.8)
				strip.append({"img": await stage.grab(), "label": "40 % HP"})
				_call(target, &"set_health_ratio", [0.2])
				await _wait(0.8)
				strip.append({"img": await stage.grab(), "label": "20 % HP"})
				_call(target, &"set_health_ratio", [1.0])
			if _call(target, &"play_training_pulse"):
				await _wait(0.12)
				strip.append({"img": await stage.grab(), "label": "training pulse"})
			if _call(target, &"set_selected", [true]):
				await _wait(0.3)
				strip.append({"img": await stage.grab(), "label": "selected"})
				_call(target, &"set_selected", [false])
			if _call(target, &"play_destroyed"):
				await _wait(1.2)
				strip.append({"img": await stage.grab(), "label": "destroyed 1.2 s"})
				await _wait(1.8)
				strip.append({"img": await stage.grab(), "label": "destroyed 3 s"})
		&"critter":
			for step: Array in [[&"play_move", [stride], 0.5, "move"], [&"play_flee", [], 0.5, "flee"],
					[&"play_hit", [], 0.07, "hit"], [&"play_death", [], 0.6, "death 0.6 s"]]:
				if _call(target, step[0], step[1]):
					await _wait(step[2])
					ArtLabStage.freeze(target, true)
					strip.append({"img": await stage.grab(), "label": step[3]})
					ArtLabStage.freeze(target, false)
		_:
			if _call(target, &"set_moving", [stride]):
				await _wait(0.7)
				ArtLabStage.freeze(target, true)
				strip.append({"img": await stage.grab(), "label": "move"})
				ArtLabStage.freeze(target, false)
				if kind == &"mount":
					target.call(&"set_moving", stride * 2.2)
					await _wait(0.8)
					ArtLabStage.freeze(target, true)
					strip.append({"img": await stage.grab(), "label": "gallop"})
					ArtLabStage.freeze(target, false)
				target.call(&"set_moving", 0.0)
				await _wait(0.6)
			if _call(target, &"play_attack"):
				var wu: Variant = target.get(&"attack_windup")
				await _wait(0.35 if flyer or kind == &"titan" else (float(wu) if wu != null and float(wu) > 0.0 else 0.1))
				ArtLabStage.freeze(target, true)
				strip.append({"img": await stage.grab(), "label": "attack (strike)"})
				ArtLabStage.freeze(target, false)
				await _wait(1.0)
			if kind == &"mount" and _call(target, &"play_charge"):
				await _wait(0.2)
				ArtLabStage.freeze(target, true)
				strip.append({"img": await stage.grab(), "label": "charge"})
				ArtLabStage.freeze(target, false)
				await _wait(0.8)
			if _call(target, &"play_hit"):
				await _wait(0.07)
				ArtLabStage.freeze(target, true)
				strip.append({"img": await stage.grab(), "label": "hit"})
				ArtLabStage.freeze(target, false)
				await _wait(0.5)
			if (kind == &"beast" or tier in [&"wizard", &"champion"]) and _call(target, &"play_cast", [&"lab_cast"]):
				await _wait(0.25)
				ArtLabStage.freeze(target, true)
				strip.append({"img": await stage.grab(), "label": "cast"})
				ArtLabStage.freeze(target, false)
				await _wait(1.0)
			await _death_check(strip, true)
	var imgs: Array[Image] = []
	var cbox := box.grow(maxf(box.size.length() * 0.12, 0.3))
	for f: Dictionary in strip:
		var c := _crop_box(f["img"], cbox, 0.05)
		imgs.append(c)
		_tile(c, "anim: " + String(f["label"]))
	var sheet := ArtLabImage.grid(imgs, 4, 480, 270)
	_save(sheet, "anim")


# ---------------------------------------------------------------- references (distinctness + lineup)

static var _scene_index: Dictionary = {}   # base name -> res:// path (every .tscn under res://art/)


## A scene from a short name ("ember_archer", "ember_archer.tscn", "fire/ember_archer") or a path ("art/..." or
## "res://..."); "" when nothing matches.
static func resolve_scene(s: String) -> String:
	if s == "":
		return ""
	var p := s if s.begins_with("res://") else "res://" + s.trim_prefix("/")
	if p.ends_with(".tscn") and ResourceLoader.exists(p):
		return p
	if ResourceLoader.exists(p + ".tscn"):
		return p + ".tscn"
	if _scene_index.is_empty():
		_index_scenes("res://art/")
	var key := s.get_file().trim_suffix(".tscn").to_lower()
	var hit: String = _scene_index.get(key, "")
	if hit != "" and ("/" in s):
		# "fire/ember_archer": the folder part must match too
		var want := s.trim_suffix(".tscn").to_lower()
		if not hit.to_lower().trim_suffix(".tscn").ends_with(want):
			return ""
	return hit


static func _index_scenes(dir: String) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for f: String in d.get_files():
		if f.ends_with(".tscn"):
			var k := f.get_basename().to_lower()
			if not _scene_index.has(k):
				_scene_index[k] = dir.path_join(f)
	for sub: String in d.get_directories():
		if not sub.begins_with("."):
			_index_scenes(dir.path_join(sub))


## Model scenes of a folder (the same filter as the auto references: no previews, riders, axemen, flags).
func list_scenes(dir: String, recursive: bool = true) -> Array[String]:
	return _scenes_in(dir, recursive)


func _scenes_in(dir: String, recursive: bool) -> Array[String]:
	var out: Array[String] = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f: String in d.get_files():
		if f.ends_with(".tscn") and not ("preview" in f or f.ends_with("_rider.tscn") or f.ends_with("_axeman.tscn")
				or f in ["howdah.tscn", "bounty_flag.tscn"]):
			out.append(dir.path_join(f))
	if recursive:
		for sub: String in d.get_directories():
			if sub in ["tools", "materials", "meshes", "kit", "parts", "baked"]:
				continue
			out.append_array(_scenes_in(dir.path_join(sub), true))
	return out


func _auto_candidates() -> Array:
	var same: Array[String] = []
	var near: Array[String] = []
	var u := "res://art/units/"
	match kind:
		&"unit":
			if kingdom == &"neutral":
				for s: String in _scenes_in(u + "neutral/", true):
					if not ("/beasts/" in s or "/critters/" in s):
						same.append(s)
				for k: String in ["fire", "shadow", "ice", "nature"]:
					near.append_array(_scenes_in(u + k + "/", false))
			else:
				same = _scenes_in(u + String(kingdom) + "/", true)
				if tier == &"wizard":
					same.append_array(_scenes_in(u + "wizards/", false))
				elif tier == &"champion":
					same.append_array(_scenes_in(u + "champions/", true))
				for s2: String in _scenes_in(u + "neutral/", true):
					if not ("/beasts/" in s2 or "/critters/" in s2):
						near.append(s2)
		&"mount":
			same = _scenes_in(u + "mounts/", true)
			near = _scenes_in(u + "neutral/beasts/", true)
		&"titan":
			same = _scenes_in(u + "titans/", true)
			near = _scenes_in(u + "neutral/beasts/", true)
		&"beast":
			same = _scenes_in(u + "neutral/beasts/", true)
			near = _scenes_in(u + "titans/", true)
		&"critter":
			same = _scenes_in(u + "neutral/critters/", false)
			near = _scenes_in(u + "neutral/", false)
		&"building":
			for s3: String in _scenes_in("res://art/buildings/", true):
				var f := s3.to_lower()
				if String(kingdom) in f or (kingdom == &"shadow" and "dusk" in f):
					same.append(s3)
				elif "/capture/" in f or "/tavern/" in f or "/guilds/" in f or "trade_post" in f:
					near.append(s3)
		&"landmark":
			same = _scenes_in("res://art/environment/landmarks/", false)
			near = _scenes_in("res://art/environment/lairs/", false)
	same.erase(scene_path)
	near.erase(scene_path)
	return [same, near]


## Height (m) of a candidate scene (instantiated off-screen for a frame).
func _probe_height(path: String) -> float:
	var far := Node3D.new()
	far.position = gp + Vector3(-400.0, 0.0, 400.0)
	stage.world.add_child(far)
	var inst := _spawn(path, Vector3.ZERO, 0.0, far)
	await _frames(2)
	var h := 0.0
	if inst:
		var b := ArtLabCensus.world_aabb(inst, far.global_position.y)
		h = b.end.y - far.global_position.y
	far.queue_free()
	return h


func _pick_refs() -> Array[String]:
	var explicit := String(opts.get("ref", ""))
	var out: Array[String] = []
	if explicit != "":
		var missing: Array[String] = []
		for r: String in explicit.split(",", false):
			var p := resolve_scene(r.strip_edges())
			if p != "":
				out.append(p)
			else:
				missing.append(r.strip_edges())
		if not missing.is_empty():
			var msg := "ref not found: %s (use a short name like ember_archer or a res:// path)" % ", ".join(missing)
			printerr("ART LAB WARNING: " + msg)
			print("ART LAB WARNING: " + msg)
			rep.add("R2r", "read", "References found", "WARN", msg, "every ref= must resolve (else R2 compares against fewer assets)",
				"Fix the ref= list")
		return out
	var box: AABB = m["box"]
	var ht := maxf(box.end.y - gp.y, 0.2)
	var cands := _auto_candidates()
	for group_i: int in 2:
		var lst: Array[String] = []
		lst.assign(cands[group_i])
		var scored: Array = []
		for p2: String in lst.slice(0, 24):
			var h: float = await _probe_height(p2)
			if h > 0.05:
				scored.append([absf(log(h / ht)), p2])
		scored.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
		var take := 4 if group_i == 0 else 2
		for s: Array in scored.slice(0, take):
			out.append(String(s[1]))
	return out


func _refs() -> void:
	var refs := await _pick_refs()
	if refs.is_empty():
		rep.add("R2", "read", "Distinct from references", "INFO", "no reference found", "silhouette IoU <= 0.8")
		return
	var box: AABB = m["box"]
	var rules := ArtLabBudgets.read_rules(kind)
	var half := maxf(maxf(box.size.x, box.size.z) * 0.5, 1.5) * 2.2
	var hh := maxf(box.end.y - gp.y, 2.0) * 1.7
	var big := AABB(gp - Vector3(half, 0.0, half), Vector3(half * 2.0, hh, half * 2.0))
	stage.game_cam(gp, 40.0)
	var roi := stage.roi_of(big, 4)
	var yaws: Array[float] = [0.0, 90.0, 180.0, 270.0]
	ArtLabStage.freeze(target, true)
	var tmask: Array = []
	for y: float in yaws:
		holder.rotation.y = deg_to_rad(y)
		tmask.append(ArtLabImage.sil_mask(await _sil(target), roi))
	holder.rotation.y = 0.0
	var tlit: Image = await stage.grab()
	var tlab := ArtLabImage.mean_lab(tlit, roi, tmask[0])
	holder.rotation.y = deg_to_rad(MAIN_YAW)
	ArtLabStage.freeze(target, false)
	# P2 asymmetry of the front view (yaw 0)
	var axis := stage.cam.unproject_position(gp).x - float(roi.position.x)
	var asym := ArtLabImage.asymmetry(tmask[0], axis)
	rep.add("P2", "polish", "Asymmetric secondary shape", "INFO", "front-view asymmetry %s" % _fmt(asym, 2),
		"one asymmetric secondary element (art-keep 0.1): >= ~0.15", "", ArtLabReport.grade(asym, 0.02, 0.2),
		"Add an asymmetric secondary element to the front read (asymmetry %s): a shoulder banner, a one-sided weapon / shield, a broken horn (>= ~0.25 m wide, or it does not register at 40 m)" % _fmt(asym, 2) if asym < 0.15 else "", "silhouette")
	holder.visible = false
	var results: Array[Dictionary] = []
	var sil_masks: Array = [tmask[0]]
	var sil_labels: Array[String] = [asset]
	for rp: String in refs:
		var rm := _spawn(rp, gp, 0.0)
		if rm == null:
			continue
		if rm.has_method(&"set_team_color"):
			rm.call(&"set_team_color", _model_color(rm))
		await _frames(2)
		await _settle(rm)
		ArtLabStage.freeze(rm, true)
		var ious: Array[float] = []
		var rmask0: ArtLabImage.Mask = null
		for i: int in yaws.size():
			rm.get_parent().rotation.y = deg_to_rad(yaws[i])
			var mk := ArtLabImage.sil_mask(await _sil(rm), roi)
			if i == 0:
				rmask0 = mk
			ious.append(ArtLabImage.iou(tmask[i], mk))
		rm.get_parent().rotation.y = 0.0
		var rlit: Image = await stage.grab()
		var rlab := ArtLabImage.mean_lab(rlit, roi, rmask0)
		var mean := 0.0
		for v: float in ious:
			mean += v
		mean /= float(ious.size())
		results.append({"path": rp, "name": rp.get_file().get_basename(), "iou": mean, "de": tlab.distance_to(rlab)})
		sil_masks.append(rmask0)
		sil_labels.append("%s %s" % [rp.get_file().get_basename(), _fmt(mean, 2)])
		_free_model(rm)
		await _frames(1)
	holder.visible = true
	results.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["iou"]) > float(b["iou"]))
	var lim: float = rules.get("iou", 0.8)
	var top: Dictionary = results[0] if not results.is_empty() else {}
	var lst: Array[String] = []
	for r: Dictionary in results:
		lst.append("%s %s" % [r["name"], _fmt(float(r["iou"]), 2)])
	var st := "PASS"
	var hint := ""
	var value := "max IoU %s (%s)" % [_fmt(float(top.get("iou", 0.0)), 2), ", ".join(lst)]
	if not top.is_empty() and float(top["iou"]) > lim:
		if float(top["de"]) < 15.0:
			st = "WARN"
			hint = "Reads like %s at 40 m (IoU %s, colour dE %s): change the silhouette hook (a different vertical, weapon, head shape)" % [top["name"], _fmt(float(top["iou"]), 2), _fmt(float(top["de"]))]
		else:
			value += "; same shape family as %s but told apart by colour (dE %s)" % [top["name"], _fmt(float(top["de"]))]
	rep.add("R2", "read", "Distinct from references (black masks)", st, value,
		"IoU <= %s vs every reference (4 turns, 40 m), else colour must differ (dE >= 15)" % _fmt(lim, 2), hint,
		ArtLabReport.grade(float(top.get("iou", 0.0)), 0.9, 0.45),
		("Make it read apart from %s (IoU %s): change one big shape of the silhouette" % [top.get("name", ""), _fmt(float(top.get("iou", 0.0)), 2)]) if float(top.get("iou", 0.0)) > 0.6 else "", "silhouette")
	# every silhouette cropped with the same rect: same scale, as at 40 m
	var common: Rect2i = (sil_masks[0] as ArtLabImage.Mask).bbox
	for mk: ArtLabImage.Mask in sil_masks:
		if mk.count > 0:
			common = common.merge(mk.bbox)
	var sil_tiles: Array[Image] = []
	for mk2: ArtLabImage.Mask in sil_masks:
		sil_tiles.append(_mask_tile(mk2, common))
	var sheet := ArtLabImage.grid(sil_tiles, mini(sil_tiles.size(), 4), 240, 240, Color.WHITE, true)
	_save(sheet, "silhouette", true)
	_tile(sheet, "40 m silhouettes (same scale): " + ", ".join(sil_labels))
	await _lineup(refs)


func _mask_tile(mk: ArtLabImage.Mask, crop: Rect2i) -> Image:
	var img := ArtLabImage.mask_image(mk)
	var r := ArtLabImage.clamp_rect(crop, 4, mk.w, mk.h)
	return img.get_region(r) if r.size.x > 1 and r.size.y > 1 else img


func _lineup(refs: Array[String]) -> void:
	var paths: Array[String] = [scene_path]
	paths.append_array(refs)
	var models: Array[Node3D] = []
	var widths: Array[float] = []
	for p: String in paths:
		var mm := _spawn(p, gp + Vector3(0.0, 0.0, 300.0), 0.0)
		if mm == null:
			continue
		if mm.has_method(&"set_team_color"):
			mm.call(&"set_team_color", _model_color(mm) if p != scene_path else _model_color(target))
		models.append(mm)
	await _frames(4)
	await _wait(0.7)   # spawn animations (sprouts, rise-ups) end before the lineup shot
	for mm2: Node3D in models:
		var b := ArtLabCensus.world_aabb(mm2, ground_y)
		widths.append(maxf(b.size.x, 0.6))
	var total := 0.0
	for w: float in widths:
		total += w + 0.8
	var x := -total * 0.5
	for i: int in models.size():
		x += widths[i] * 0.5 + 0.4
		(models[i].get_parent() as Node3D).position = gp + Vector3(x, 0.0, 0.0)
		(models[i].get_parent() as Node3D).rotation.y = deg_to_rad(20.0)
		x += widths[i] * 0.5 + 0.4
	holder.visible = false
	await _frames(2)
	stage.game_cam(gp, 40.0)
	var img: Image = await stage.grab()
	var row := AABB()
	for j: int in models.size():
		var bj := ArtLabCensus.world_aabb(models[j], ground_y)
		row = bj if j == 0 else row.merge(bj)
	var roi := stage.roi_of(row, 20)
	_tile(_crop(img, Vector2(roi.get_center()), Vector2i(roi.size.x, roi.size.y)), "lineup at 40 m (first = %s)" % asset)
	stage.fit_cam(row, 10.0, 0.0, 0.9)
	var side: Image = _crop_box(await stage.grab(), row, 0.06)
	_save(side, "lineup")
	_tile(side, "lineup side: " + ", ".join(paths.map(func(p: String) -> String: return p.get_file().get_basename())))
	for mm3: Node3D in models:
		_free_model(mm3)
	holder.visible = true
	await _frames(1)


# ---------------------------------------------------------------- frame cost

func _measure(frames: int, tick: Callable = Callable()) -> Vector3:
	var proc := 0.0
	var cpu := 0.0
	var gpu := 0.0
	var t0 := Time.get_ticks_usec()
	for i: int in frames:
		if tick.is_valid():
			tick.call(i)
		await get_tree().process_frame
		proc += Performance.get_monitor(Performance.TIME_PROCESS)
		var r := stage.render_ms()
		cpu += r.x
		gpu += r.y
	var wall := float(Time.get_ticks_usec() - t0) / 1000.0 / float(frames)
	# TIME_PROCESS is documented in seconds; this build reports milliseconds. A per-frame process time can never exceed
	# the wall frame time, so a value that would (x 1000) is already in ms.
	var p := proc / float(frames)
	if p * 1000.0 <= wall * 1.5:
		p *= 1000.0
	if opts.get("debug", "0") == "1":
		print("  measure: %d frames, wall %.2f ms/frame, process %.4f ms, render cpu %.2f gpu %.2f" % [frames, wall, p,
			cpu / frames, gpu / frames])
	return Vector3(p, cpu / float(frames), gpu / float(frames))


func _frame_cost() -> void:
	var row := rep.budget_row
	var n := int(opts.get("n", row.get("n", 20)))
	if n <= 0:
		return
	stage.game_cam(gp, 40.0)
	holder.visible = false
	ArtLabStage.freeze(target, true)
	await _frames(10)
	var base: Vector3 = await _measure(90)
	var box: AABB = m["box"]
	var step := maxf(maxf(box.size.x, box.size.z) + 0.6, 1.2)
	var cols := int(ceil(sqrt(float(n))))
	var inst: Array[Node3D] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i: int in n:
		var at := gp + Vector3((float(i % cols) - float(cols - 1) * 0.5) * step, 0.0, (float(i / cols) - float(cols - 1) * 0.5) * step)
		var mm := _spawn(scene_path, at, rng.randf_range(0.0, 360.0))
		if mm:
			inst.append(mm)
	await _frames(5)
	for i2: int in inst.size():
		if i2 % 2 == 0:
			_call(inst[i2], &"set_moving", [stride])
			_call(inst[i2], &"play_move", [stride])
	await _frames(30)
	var tick := func(f: int) -> void:
		if f % 3 == 0 and not inst.is_empty():
			var u: Node3D = inst[(f / 3) % inst.size()]
			if is_instance_valid(u) and u.has_method(&"play_attack"):
				u.call(&"play_attack")
	var meas: Vector3 = await _measure(120, tick)
	for mm2: Node3D in inst:
		_free_model(mm2)
	holder.visible = true
	ArtLabStage.freeze(target, false)
	await _frames(2)
	var per := maxf(meas.x - base.x, 0.0) / float(maxi(inst.size(), 1))   # < 0 = noise
	var lim := ArtLabBudgets.limit(row, "frame_ms")
	var st := ArtLabReport.budget_status(per, lim)
	if st == "FAIL" and per <= float(lim.get("limit", 0.0)) * 1.5:
		st = "WARN"   # v2 noise band: 1-1.5 x the budget on a loaded PC is not a verdict; re-run quiet to confirm
		rep.notes.append("B13 in the noise band (%s ms, budget %s): re-run on a quiet PC before fixing" % [_fmt(per, 4), str(lim.get("limit", "-"))])
	var val := "%s ms process per instance (%d animated at 40 m: +%s ms process, render CPU +%s ms, GPU +%s ms)" % [
		_fmt(per, 4), inst.size(), _fmt(meas.x - base.x, 2), _fmt(meas.y - base.y, 2), _fmt(meas.z - base.z, 2)]
	var l := float(lim.get("limit", 0.01))
	rep.add("B13", "budget", "Frame cost", st, val,
		"<= %s ms per instance%s (%s)" % [str(lim.get("limit", "-")), "" if bool(lim.get("hard", true)) else " soft", row.get("src", "")],
		"One _process per model, cached pivots, no get_node / allocation per frame, respect the distance tiers (art-units 6.10)",
		ArtLabReport.grade(per, l * 1.5, l * 0.4), "Cut the per-frame script cost (%s ms per instance): write pivots only when they change, skip work at the far tiers" % _fmt(per, 4) if per > l * 0.6 else "")


# ================================================================ decor sets

func _run_decor() -> void:
	var scr := load(scene_path) as GDScript
	if scr == null:
		rep.add("H0", "health", "Set script loads", "FAIL", "not a GDScript", "biome set file (map-fill.md 10)")
		return
	var consts := scr.get_script_constant_map()
	var entries: Array = consts.get("ENTRIES", [])
	var biome: StringName = consts.get("BIOME_ID", &"")
	if opts.get("ground", "") == "" and ArtLabStage.GROUND_POINTS.has(biome):
		ground_id = biome
	gp = ArtLabStage.GROUND_POINTS[ground_id]
	rep.add("H0", "health", "Set script loads", "PASS" if not entries.is_empty() else "FAIL", "%d entries, biome %s" % [entries.size(), biome],
		"ENTRIES / BIOME_ID / GROUND_TINT (map-fill.md 10)")
	var row := rep.budget_row
	# D1 kinds
	var lk := ArtLabBudgets.limit(row, "kinds")
	var stk := ArtLabReport.budget_status(float(entries.size()), lk)
	rep.add("D1", "decor", "Mesh kinds in the set", stk, str(entries.size()), "<= %s soft (map total <= 24 kinds, map-fill.md 9)" % str(lk.get("limit", "-")),
		"Merge look-alike kinds; use the 3 shape variants of nature_painted instead of new meshes", 1.0 if stk == "PASS" else 0.5)
	# per entry
	var max_tris := 0
	var tri_list: Array[String] = []
	var bad_shadow: Array[String] = []
	var bad_range: Array[String] = []
	var density := 0.0
	var mats := {}
	var meshes: Array[Mesh] = []
	for e: Dictionary in entries:
		var path: String = e.get("mesh", "")
		var mesh: Mesh = load(path) as Mesh if ResourceLoader.exists(path) else null
		meshes.append(mesh)
		if mesh == null:
			bad_range.append("%s missing" % path.get_file())
			continue
		var stt := ArtLabCensus.mesh_stats(mesh)
		max_tris = maxi(max_tris, stt.y)
		tri_list.append("%s %d" % [path.get_file().get_basename(), stt.y])
		for s: int in mesh.get_surface_count():
			if mesh.surface_get_material(s):
				mats[mesh.surface_get_material(s).get_instance_id()] = true
		var nm := path.get_file().to_lower()
		var big := false
		for w: String in ["tree", "log", "rock", "boulder", "stump", "trunk", "willow"]:
			if w in nm:
				big = true
		if bool(e.get("shadow", false)) and not big:
			bad_shadow.append(nm)
		var rng_end: float = float(e.get("range", 90.0))
		var small := false
		for w2: String in ["tuft", "flower", "clover", "pebble", "lily", "grass", "daisy", "dandelion"]:
			if w2 in nm:
				small = true
		if rng_end > 90.0 or (small and rng_end > 65.0):
			bad_range.append("%s %s m" % [nm.get_basename(), _fmt(rng_end, 0)])
		density += float(e.get("per_100m2", 0.0))
	var lt := ArtLabBudgets.limit(row, "tris_per_mesh")
	var stt2 := ArtLabReport.budget_status(float(max_tris), lt)
	rep.add("D2", "decor", "Triangles per decor mesh", stt2, "max %d (%s)" % [max_tris, ", ".join(tri_list)], "<= %s soft (lab default)" % str(lt.get("limit", "-")),
		"Fewer segments / cards; the vertex wind and the variants carry the detail", ArtLabReport.grade(float(max_tris), 900.0, 250.0))
	rep.add("D3", "decor", "Shadow casters", "FAIL" if not bad_shadow.is_empty() else "PASS",
		", ".join(bad_shadow) if not bad_shadow.is_empty() else "only trees / logs / big rocks cast", "map-fill.md 9: only trees, logs, big rocks, landmarks, bridges cast shadows",
		"Set shadow false on small decor")
	rep.add("D4", "decor", "Visibility ranges", "WARN" if not bad_range.is_empty() else "PASS",
		", ".join(bad_range) if not bad_range.is_empty() else "all within 65 / 90 m", "tufts / flowers / pebbles <= 65 m, bushes / reeds / ferns / mushrooms <= 90 m (map-fill.md 9)",
		"Lower `range` on the small pieces")
	var budget_n: int = int(consts.get("INSTANCE_BUDGET", ArtLabBudgets.SET_INSTANCES.get(biome, 0)))
	if budget_n > 0 and density > 0.0:
		rep.add("D5", "decor", "Instance budget coverage", "INFO", "%s per 100 m2 -> the %d-instance budget covers %d m2 at full weight" % [_fmt(density), budget_n, int(float(budget_n) / density * 100.0)],
			"map-fill.md 10 instance budget per set")
	rep.add("B8", "budget", "Unique materials", "INFO", str(mats.size()), "shared nature material + contact disc expected")
	if headless:
		for id_name: Array in [["D7", "Units hidden by decor"], ["D8", "Units on this decor"], ["D9", "Decor coverage"]]:
			rep.add(id_name[0], "decor", id_name[1], "SKIP", "headless", "needs a windowed run")
		return
	# scatter a 30 x 30 m patch
	var patch := Node3D.new()
	patch.name = "DecorPatch"
	stage.world.add_child(patch)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	var side := 30.0
	for i: int in entries.size():
		var e2: Dictionary = entries[i]
		var mesh2: Mesh = meshes[i]
		if mesh2 == null:
			continue
		var count := int(round(float(e2.get("per_100m2", 0.0)) * side * side / 100.0))
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh2
		mm.instance_count = count
		var cl: float = float(e2.get("cluster", 0.0))
		var sc: Vector2 = e2.get("scale", Vector2.ONE)
		var centre := Vector2.ZERO
		for k: int in count:
			var p := Vector2(rng.randf_range(-side * 0.5, side * 0.5), rng.randf_range(-side * 0.5, side * 0.5))
			if rng.randf() < cl:
				if k % 8 == 0:
					centre = Vector2(rng.randf_range(-side * 0.5, side * 0.5), rng.randf_range(-side * 0.5, side * 0.5))
				p = centre + Vector2(rng.randfn(0.0, 1.2), rng.randfn(0.0, 1.2))
			var yaw: float = float(e2["yaw"]) + rng.randf_range(-1.0, 1.0) * float(e2.get("yaw_jitter", 0.0)) if e2.has("yaw") else rng.randf_range(0.0, TAU)
			var s2 := rng.randf_range(sc.x, sc.y)
			mm.set_instance_transform(k, Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * s2), gp + Vector3(p.x, 0.0, p.y)))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if bool(e2.get("shadow", false)) else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.visibility_range_end = float(e2.get("range", 90.0))
		mmi.visibility_range_end_margin = 10.0
		patch.add_child(mmi)
	# reference units standing in the patch
	var units: Array[Node3D] = []
	var xs: Array[float] = [-3.0, -1.0, 1.0, 3.0]
	for j: int in DECOR_UNITS.size():
		if ResourceLoader.exists(DECOR_UNITS[j]):
			var u := _spawn(DECOR_UNITS[j], gp + Vector3(xs[j], 0.0, 1.0), 20.0)
			if u:
				units.append(u)
	await _frames(6)
	await _wait(0.5)
	stage.set_mode(&"lit")
	for z: float in [40.0, 55.0, 25.0]:
		stage.game_cam(gp, z)
		var img: Image = await stage.grab()
		_save(img, "z%d" % int(z))
		var roi0 := stage.roi_of(AABB(gp - Vector3(8.0, 0.0, 8.0), Vector3(16.0, 2.0, 16.0)), 0)
		_tile(_crop(img, Vector2(roi0.get_center()), roi0.size), "%d m game camera (patch + 4 units)" % int(z))
	stage.fit_cam(AABB(gp - Vector3(4.0, 0.0, 3.0), Vector3(8.0, 1.5, 6.0)), 25.0, 0.0, 0.9)
	var close: Image = await stage.grab()
	_save(close, "close")
	_tile(close, "close-up")
	stage.game_cam(gp, 40.0)
	# D7 / D8: occlusion and contrast of each unit
	var rules := ArtLabBudgets.read_rules(kind)
	var worst_occ := 0.0
	var worst_de := 999.0
	var occ_list: Array[String] = []
	for u2: Node3D in units:
		ArtLabStage.freeze(u2, true)
	for u3: Node3D in units:
		var ub := ArtLabCensus.world_aabb(u3, ground_y)
		var roi_u := stage.roi_of(ub, 10)
		var others: Array = []
		for u4: Node3D in units:
			if u4 != u3:
				others.append(u4.get_parent())
				(u4.get_parent() as Node3D).visible = false
		# unit alone (decor hidden)
		patch.visible = false
		var mask_u := ArtLabImage.sil_mask(await _sil(u3), roi_u)
		patch.visible = true
		# decor in white in front of the black unit
		stage.set_mode(&"sil")
		var rec := stage.override(u3, stage.black_mat, ground_y)
		var rec2 := stage.override(patch, stage.white_mat, ground_y)
		var vis: Image = await stage.grab()
		stage.restore(rec)
		stage.restore(rec2)
		stage.set_mode(&"lit")
		var mask_v := ArtLabImage.sil_mask(vis, roi_u)
		var occ := 1.0 - float(mask_v.count) / float(maxi(mask_u.count, 1))
		var lit_u: Image = await stage.grab()
		(u3.get_parent() as Node3D).visible = false
		var bg_u: Image = await stage.grab()
		(u3.get_parent() as Node3D).visible = true
		for o: Node3D in others:
			o.visible = true
		var cu := ArtLabImage.contrast(lit_u, bg_u, roi_u, mask_v if mask_v.count > 10 else mask_u)
		var de_u: float = cu.get("de_means", 0.0)
		worst_occ = maxf(worst_occ, occ)
		worst_de = minf(worst_de, de_u)
		occ_list.append("%s %d%% hidden, dE %s" % [u3.scene_file_path.get_file().get_basename(), int(occ * 100.0), _fmt(de_u)])
	var ow: float = rules["occlude_warn"]
	var of: float = rules["occlude_fail"]
	var st7 := "PASS" if worst_occ <= ow else ("WARN" if worst_occ <= of else "FAIL")
	rep.add("D7", "decor", "Units hidden by decor at 40 m", st7, "worst %d%% (%s)" % [int(worst_occ * 100.0), "; ".join(occ_list)],
		"<= %d%% of a unit's silhouette (FAIL > %d%%)" % [int(ow * 100.0), int(of * 100.0)],
		"Lower / thin the tall pieces (tall grass, gorse) or lower their density near open ground", ArtLabReport.grade(worst_occ, of, 0.02),
		"Tall pieces hide up to %d%% of a unit: cap them ~0.6 m or thin the clusters" % int(worst_occ * 100.0) if worst_occ > 0.08 else "", "z40")
	var uw: float = rules["unit_de_warn"]
	var uf: float = rules["unit_de_fail"]
	# WARN only: a unit sharing the decor's colours is half the unit's own problem (its R4 on this ground)
	var st8 := "PASS" if worst_de >= uw else "WARN"
	rep.add("D8", "decor", "Units still read on this decor", st8, "worst unit mean-colour dE %s (per unit in D7)" % _fmt(worst_de),
		"dE >= %s (WARN only; < %s = that unit melts into this decor)" % [_fmt(uw, 0), _fmt(uf, 0)],
		"Keep the decor a value step away from unit colours (darker / desaturated under units)", ArtLabReport.grade(worst_de, uf * 0.6, uw * 1.6),
		"Units drop to dE %s on this decor: desaturate / darken the busiest piece" % _fmt(worst_de) if worst_de < uw * 1.3 else "", "z40")
	# D9 coverage + D10 glow
	for u5: Node3D in units:
		(u5.get_parent() as Node3D).visible = false
	var proi := stage.roi_of(AABB(gp - Vector3(6.0, 0.0, 6.0), Vector3(12.0, 0.1, 12.0)), 0)
	var pmask := ArtLabImage.sil_mask(await _sil(patch), proi)
	var cover := float(pmask.count) / float(maxi(proi.size.x * proi.size.y, 1))
	var cw: float = rules["cover_warn"]
	rep.add("D9", "decor", "Decor coverage at 40 m", "PASS" if cover <= cw else "WARN", "%d%% of the ground covered" % int(cover * 100.0),
		"<= %d%% (busy ground hides units and orders)" % int(cw * 100.0), "Lower the densities or cluster more (bare ground between patches)",
		ArtLabReport.grade(cover, 0.8, 0.3), "Leave more bare ground between clumps (coverage %d%%)" % int(cover * 100.0) if cover > 0.4 else "", "z40")
	stage.set_mode(&"dark")
	var dark: Image = await stage.grab()
	stage.set_mode(&"lit")
	var gl := ArtLabImage.glow_clusters(dark, proi, 0.3, 3, 2)
	var gr: Vector2i = rules["glow"]
	rep.add("R5", "read", "Glow points in the patch (12 x 12 m)", "PASS" if gl.size() <= gr.y else "WARN", "%d" % gl.size(),
		"<= %d per 144 m2 (emissive decor only in its biome)" % gr.y, "Fewer / dimmer glowing pieces")
	# D11 frame cost
	patch.visible = false
	await _frames(10)
	var base: Vector3 = await _measure(60)
	patch.visible = true
	await _frames(10)
	var with_p: Vector3 = await _measure(60)
	var lim := ArtLabBudgets.limit(row, "frame_ms_patch")
	var dproc := with_p.x - base.x
	rep.add("B13", "budget", "Patch frame cost (900 m2)", "INFO", "process +%s ms, render CPU +%s ms, GPU +%s ms" % [_fmt(dproc, 3), _fmt(with_p.y - base.y, 2), _fmt(with_p.z - base.z, 2)],
		"script cost ~0 (MultiMesh, vertex-shader wind); GPU for info (soft %s ms)" % str(lim.get("limit", "-")))
	for u6: Node3D in units:
		(u6.get_parent() as Node3D).visible = true


# ================================================================ VFX families

func _run_vfx() -> void:
	gp = ArtLabStage.GROUND_POINTS[ground_id]
	var res := load(scene_path)
	var fam: Node3D = null
	if res is PackedScene:
		fam = (res as PackedScene).instantiate() as Node3D
	elif res is GDScript:
		fam = (res as GDScript).new() as Node3D
	if fam == null or not fam.has_method(&"play"):
		rep.add("H0", "health", "VFX family loads", "FAIL", "no Node3D with play(id, at, target)", "VFX family contract (TitanVfx / MapFillVfx / UnitVfx)")
		return
	stage.world.add_child(fam)
	var ids: Array[StringName] = []
	if opts.has("ids"):
		for s: String in String(opts["ids"]).split(",", false):
			ids.append(StringName(s.strip_edges()))
	else:
		var consts := (fam.get_script() as GDScript).get_script_constant_map()
		for k: String in ["EFFECTS", "IDS", "GROUND_IDS", "FROST_IDS"]:
			if consts.has(k):
				for e: Variant in consts[k]:
					if not StringName(e) in ids:
						ids.append(StringName(e))
	rep.add("H0", "health", "VFX family loads", "PASS", "%d effect ids" % ids.size(), "play(id, at, target)")
	target = fam
	var tgt := gp + Vector3(0.0, 0.0, -4.0)
	await _frames(3)
	# warm-up (pools fill on first use)
	for id: StringName in ids:
		fam.call(&"play", id, gp, tgt)
		await _wait(0.15)
	await _wait(4.0)
	var nodes0 := _count_nodes(fam)
	var lights_max := 0
	var part_max := 0
	var draw_max := 0
	var per_play: Array[String] = []
	var new_mats_total := 0
	var weak: Array[String] = []
	stage.game_cam(gp, 40.0)
	var base40: Image = null
	if not headless:
		base40 = await stage.grab()
	var droi := stage.roi_of(AABB(gp - Vector3(10.0, 0.0, 10.0), Vector3(20.0, 6.0, 20.0)), 0)
	var created: Array[int] = [0]
	var cb := func(n: Node) -> void:
		if is_instance_valid(fam) and fam.is_ancestor_of(n):
			created[0] += 1
	get_tree().node_added.connect(cb)
	var frames_all: Array[Image] = []
	var labels: Array[String] = []
	for id2: StringName in ids:
		created[0] = 0
		var r0 := ArtLabCensus.resource_ids(fam)
		fam.call(&"play", id2, gp, tgt)
		var peak := 0
		var t_prev := 0.0
		for t: float in [0.05, 0.12, 0.35, 0.8, 1.5]:
			await _wait(maxf(t - t_prev, 0.01))
			t_prev = t
			var cen := ArtLabCensus.census(fam, ground_y)
			lights_max = maxi(lights_max, int(cen["lights"]))
			part_max = maxi(part_max, int(cen["particles"]))
			draw_max = maxi(draw_max, int(cen["draw"]))
			if not headless:
				var img: Image = await stage.grab()
				var full := ArtLabImage.Mask.new(droi.size.x, droi.size.y)
				full.bits.fill(1)
				full.finish()
				var ch := ArtLabImage.changed_fraction(base40, img, droi, full, 10.0)
				peak = maxi(peak, int(ch * float(full.count)))
				if t == 0.12 or t == 0.35:
					frames_all.append(_crop(img, Vector2(droi.get_center()), Vector2i(droi.size.x / 2, droi.size.y / 2)))
					labels.append("%s %s s" % [id2, _fmt(t, 2)])
		await _wait(1.5)
		var r1 := ArtLabCensus.resource_ids(fam)
		var nm := 0
		for mid: int in r1["materials"]:
			if not (r0["materials"] as Dictionary).has(mid):
				nm += 1
		new_mats_total += nm
		per_play.append("%s %d" % [id2, created[0]])
		if not headless and peak < int(ArtLabBudgets.read_rules(&"vfx").get("area_warn", 200)):
			weak.append("%s %d px" % [id2, peak])
	get_tree().node_added.disconnect(cb)
	await _wait(3.0)
	var leak := _count_nodes(fam) - nodes0
	var row := rep.budget_row
	rep.add("B5", "budget", "Real lights during effects", "PASS" if lights_max == 0 else "FAIL", "max %d" % lights_max, "0 (emission + bloom)", "Replace lights with emissive cards")
	var tot_created := 0
	for s2: String in per_play:
		tot_created += int(s2.get_slice(" ", 1))
	rep.add("V2", "vfx", "Nodes created per play (after warm-up)", "PASS" if tot_created == 0 else "WARN", ", ".join(per_play),
		"0: pooled (art-units 6.10: no runtime instancing)", "Pool the nodes (create at _ready / first use, then reuse)", 1.0 if tot_created == 0 else 0.4,
		"Pool what each play creates (%d nodes over %d ids)" % [tot_created, ids.size()] if tot_created > 0 else "")
	rep.add("V3", "vfx", "Leak after all effects end", "PASS" if leak <= 0 else "WARN", "%+d nodes 3 s after the last effect" % leak, "back to the warm pool size",
		"Free / return every node when its effect ends", 1.0 if leak <= 0 else 0.3)
	rep.add("V4", "vfx", "Materials created per play", "PASS" if new_mats_total == 0 else "WARN", str(new_mats_total), "0 (shared materials, instance uniforms)",
		"Share materials; per-effect colour via instance uniforms or vertex colour", 1.0 if new_mats_total == 0 else 0.4)
	var lp := ArtLabBudgets.limit(row, "particles")
	rep.add("V5", "vfx", "Peak particles / draws", ArtLabReport.budget_status(float(part_max), lp), "%d looping particles, %d draw instances" % [part_max, draw_max],
		"particles <= %s soft, draws <= %s soft" % [str(lp.get("limit", "-")), str(ArtLabBudgets.limit(row, "draw").get("limit", "-"))], "Smaller amounts, bigger soft sprites")
	if headless:
		rep.add("V6", "vfx", "Visible at 40 m", "SKIP", "headless", "needs a windowed run")
		return
	rep.add("V6", "vfx", "Visible at 40 m", "PASS" if weak.is_empty() else "WARN", "weak: " + ", ".join(weak) if not weak.is_empty() else "every id changes >= %d px" % int(ArtLabBudgets.read_rules(&"vfx").get("area_warn", 200)),
		"each effect changes >= %d px of the 40 m frame (ids that need a unit target may show nothing here)" % int(ArtLabBudgets.read_rules(&"vfx").get("area_warn", 200)),
		"Bigger / brighter core (emission >= 2.5), a ground ring for area effects", 1.0 if weak.is_empty() else 0.5,
		"Strengthen the 40 m read of %s" % ", ".join(weak) if not weak.is_empty() else "")
	var sheet := ArtLabImage.grid(frames_all, 4, 400, 225)
	_save(sheet, "effects")
	for i: int in range(0, frames_all.size(), 2):
		var pair: Array[Image] = [frames_all[i]]
		if i + 1 < frames_all.size():
			pair.append(frames_all[i + 1])
		_tile(ArtLabImage.grid(pair, 2, 400, 225), labels[i].get_slice(" ", 0) + " at 0.12 / 0.35 s (40 m)")
	# frame cost: every id at once, 3 times
	await _frames(10)
	var base: Vector3 = await _measure(60)
	var burst := func(f: int) -> void:
		if f % 20 == 0:
			for id3: StringName in ids:
				fam.call(&"play", id3, gp + Vector3(randf_range(-6.0, 6.0), 0.0, randf_range(-6.0, 6.0)), tgt)
	var with_p: Vector3 = await _measure(60, burst)
	rep.add("B13", "budget", "Frame cost (all ids x 3 in 1 s)", "INFO", "process +%s ms, render CPU +%s ms, GPU +%s ms" % [_fmt(with_p.x - base.x, 3), _fmt(with_p.y - base.y, 2), _fmt(with_p.z - base.z, 2)],
		"for information")


# ================================================================ errors + ideas

func _check_errors() -> void:
	logger.mutex.lock()
	var entries := logger.entries.duplicate()
	logger.mutex.unlock()
	var own_dir := scene_path.get_base_dir()
	var asset_err: Array[String] = []
	var asset_warn: Array[String] = []
	var other: Array[String] = []
	var lab: Array[String] = []
	for e: Dictionary in entries:
		var f: String = e["file"]
		var line := "%s:%d %s" % [f.get_file(), int(e["line"]), String(e["msg"]).left(140)]
		if "tools/art_lab" in f:
			lab.append(line)
		elif f.begins_with(own_dir) or f.begins_with(KIT_DIR) or f == scene_path:
			if int(e["type"]) == 1:
				asset_warn.append(line)
			else:
				asset_err.append(line)
		else:
			other.append(line)
	var st := "PASS"
	if not asset_err.is_empty():
		st = "FAIL"
	elif not asset_warn.is_empty():
		st = "WARN"
	var shown := asset_err.slice(0, 3) + asset_warn.slice(0, 3)
	rep.add("H1", "health", "Errors from the asset while running", st, "%d error(s), %d warning(s)%s" % [asset_err.size(), asset_warn.size(),
		(": " + " / ".join(shown)) if not shown.is_empty() else ""], "0 (its folder + the kit)", "Fix the errors listed (full list in the console)",
		1.0 if st == "PASS" else (0.5 if st == "WARN" else 0.0))
	if not other.is_empty():
		rep.add("H2", "health", "Errors from other files during the run", "INFO", "%d: %s" % [other.size(), " / ".join(other.slice(0, 3))],
			"not the asset's fault (shared shaders, systems); report them to their owner")
	if not lab.is_empty():
		rep.notes.append("Art Lab errors (a lab bug, tell the lead): " + " / ".join(lab.slice(0, 4)))


## Army sweep (art_lab.gd `sweep=<kingdom>`): every model's 40 m black silhouette rendered ONCE (4 turns, one
## common camera), then every pair compared (mean IoU over the turns + mean colour dE). Returns
## {"pairs": [{a, b, iou, de}] sorted by IoU, "alike": pairs that read alike (IoU > 0.8 and dE < 15)}.
func army_pass(paths: Array[String], out: String) -> Dictionary:
	headless = DisplayServer.get_name() == "headless"
	if headless or paths.size() < 2:
		return {"pairs": [], "alike": [], "skipped": true}
	stage = ArtLabStage.new()
	stage.name = "ArtLabStage"
	add_child(stage)
	stage.setup(&"warm")
	_show_viewport()
	gp = ArtLabStage.GROUND_POINTS[&"meadow"]
	ground_y = gp.y
	stage.game_cam(gp, 40.0)
	var roi := stage.roi_of(AABB(gp - Vector3(3.0, 0.0, 3.0), Vector3(6.0, 5.0, 6.0)), 4)
	var masks: Array = []
	var labs: Array[Vector3] = []
	var names: Array[String] = []
	for p: String in paths:
		var inst := _spawn(p, gp, 0.0)
		if inst == null:
			continue
		if inst.has_method(&"set_team_color"):
			inst.call(&"set_team_color", _model_color(inst))
		await _frames(2)
		await _settle(inst)
		ArtLabStage.freeze(inst, true)
		var ms: Array = []
		for yaw: float in [0.0, 90.0, 180.0, 270.0]:
			(inst.get_parent() as Node3D).rotation.y = deg_to_rad(yaw)
			ms.append(ArtLabImage.sil_mask(await _sil(inst), roi))
		(inst.get_parent() as Node3D).rotation.y = 0.0
		var lit: Image = await stage.grab()
		labs.append(ArtLabImage.mean_lab(lit, roi, ms[0]))
		masks.append(ms)
		names.append(p.get_file().get_basename())
		_free_model(inst)
		await _frames(1)
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
		tiles_img.append(_mask_tile(masks[k2][0], common))
	if not tiles_img.is_empty():
		var sheet := ArtLabImage.grid(tiles_img, mini(tiles_img.size(), 6), 200, 200, Color.WHITE, true)
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
		sheet.save_png(ProjectSettings.globalize_path(out.path_join("army_silhouettes.png")))
	return {"pairs": pairs, "alike": alike, "names": names}


## Kind-specific improvement ideas that top up "Improve next" to 3 items when the checks leave little headroom.
func _add_extras() -> void:
	var ideas: Array = []
	match kind:
		&"unit", &"mount", &"titan", &"beast", &"critter":
			ideas = [["Idle / attack beats", "Give the idle one secondary motion (tail flick, cloth, head turn) and the attack a 0.1 s anticipation pose so it reads at 40 m", "anim strip"],
				["Detail density at 25 m", "Add 1-2 mid-size value accents (trim band, belt, plate edge, markings) that read at 25 m and merge into the big mass at 40 m", "shot z25"],
				["Key-read contrast", "Put the lightest value and the team colour on the top-facing masses (seen from pitch 55), darker values low", "shot z40"],
				["Glow placement", "Keep one glow point high (head / weapon tip) and one lower accent at most", "glow shot"],
				["Ground contact", "Check the blob strength and a darker contact band at the feet so it never looks pasted on", "shot close"]]
		&"building", &"landmark":
			ideas = [["Dominant vertical + asymmetric secondary", "Push the one dominant vertical 10-15 % taller and make the secondary element clearly one-sided", "silhouette"],
				["Tops light, bottoms dark", "Lighten roofs / caps and darken the plinth band (0.72 x at the ground, 1.08 x at the top)", "shot z40"],
				["Magic moves", "Something magical should rotate, bob or pulse (art-keep 0.6)", "anim strip"],
				["Ground contact", "Contact decal + a few rubble / scorch pieces (art-keep 0.5)", "shot close"]]
		&"decor_set":
			ideas = [["Value step under units", "Keep decor one value step darker / less saturated than unit colours", "D8"],
				["Clusters and bare ground", "Group pieces in clumps with bare ground between them so paths and units stay readable", "D9"],
				["Variety", "Use the 3 shape variants and a 15-25 % scale spread so repeats do not show at 25 m", "shot z25"]]
		&"vfx":
			ideas = [["Read in 0.3 s", "A bright core in the first 0.1 s, then a slower fade; the 40 m read comes from the core + a ground ring", "effects sheet"],
				["Team / kingdom colour", "Tint with the owner's glow colour, never a third tint (art-keep 0.6)", "effects sheet"],
				["Cost", "Pool and reuse; no particles beyond 45 m", "V2 / V5"]]
	for i: Array in ideas:
		rep.extras.append({"title": i[0], "text": i[1], "source": i[2]})
