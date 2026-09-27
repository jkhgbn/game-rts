class_name ArtLabRunner
extends Node
## Art Lab (docs/plan/art-lab.md): one asset's run and the run context every check module receives (`ctx`). Created by
## tools/art_lab/art_lab.gd (windowed: everything; headless: budgets / health / hooks only, render checks SKIP).
## Args (key=value after `--`): scene, kind, kingdom, out, ref (comma list), tier, ground, light, name, ids (vfx),
## n (instances for the frame cost), quick=1 (no references / frame cost), log=0 (no improvement-log row),
## fail_fast=1 (v3: stop after the headless checks when one FAILs; the render checks come out SKIP),
## compare=prev|off|<dir> (v3: before / after vs the previous run in the out folder, default prev: "What got worse" at the
## top of scorecard.md + diff_sheet.png), focus=<check ids / aliases> (v3: re-run only the passes those checks need and
## merge them into the previous scorecard; lab_diff.gd).
##
## Module map (Art Lab v3, docs/plan/art-lab.md section 1): this file = arguments, the run order (`_run_model`), the
## shared state below and the helpers (`frames`, `wait`, `call_hook`, `spawn`, `settle`, `crop`, `add_tile`,
## `save_shot`, `fmt`...). Shots: lab_shots.gd. Scenes / references: lab_scenes.gd. Checks: checks/budgets.gd,
## checks/readability.gd, checks/animation.gd, checks/decor_vfx.gd, checks/polish.gd. Score: lab_score.gd. Scorecard:
## lab_report.gd. Numbers: lab_budgets.gd. Stage: lab_stage.gd. A check module reads / writes the state through `ctx`
## (`ctx.rep.add(...)`, `ctx.m["box"]`), never through another module's private functions.

const LOG_PATH := "res://docs/art/lab/improvement-log.md"
const MAIN_YAW := 30.0
const UNIT_DATA_DIRS: Array[String] = ["res://data/units/"]
const DEFAULT_RADIUS := {&"unit": 0.45, &"mount": 0.7, &"titan": 1.6, &"beast": 1.0, &"critter": 0.3, &"building": 3.0,
	&"landmark": 3.0}
## Render checks marked SKIP when a run stops after the headless checks (headless run or fail_fast).
const RENDER_SKIPS: Array = [["R1", "Silhouette area at 40 m"], ["R2", "Distinct from references"],
	["R3", "Contrast vs ground"], ["R5", "Glow points at 40 m"], ["R6", "Team-colour visibility"], ["B13", "Frame cost"]]


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


# ---------------------------------------------------------------- run context (read / written by the check modules)
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
## v3 batch (art_lab.gd `batch=`): stages built once and reused by every asset of the batch, per light preset
## (light -> ArtLabStage, parented to `stage_parent`). Empty = this runner builds and owns its own stage.
var stage_pool: Dictionary = {}
var stage_parent: Node = null
## v3 `focus=<check ids / aliases>` (lab_diff.gd): {id: true} of the checks this run re-measures; empty = a full run.
## Passes are skipped with `needs(phase)`, parts of a pass with `wants([ids])`; the result is merged into the previous
## scorecard (ArtLabDiff.finish).
var focus: Dictionary = {}
var _t0: int = 0


# ================================================================ entry

func run(args: PackedStringArray) -> int:
	_t0 = Time.get_ticks_msec()
	for a: String in args:
		var s := a.trim_prefix("--")
		var k := s.get_slice("=", 0).strip_edges().to_lower()
		opts[k] = s.substr(k.length() + 1).strip_edges() if "=" in s else "1"
	headless = DisplayServer.get_name() == "headless"
	focus = ArtLabDiff.focus_set(String(opts.get("focus", "")))
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
	var prev := ArtLabDiff.load_previous(out_dir, opts)   # v3 compare=prev / focus=: read before this run overwrites it
	rep.budget_row = ArtLabBudgets.row(kind, tier)
	logger = LabLogger.new()
	OS.add_logger(logger)
	ArtLabCensus.clear_cache()
	await use_stage(StringName(opts.get("light", "ice" if ground_id == &"snow" else "warm")))
	print("ART LAB %s (%s / %s, %s) -> %s%s" % [asset, kind, tier, kingdom, out_dir, " [headless: no renders]" if headless else ""])
	if not focus.is_empty():
		print("ART LAB %s: focus %s" % [asset, ArtLabDiff.focus_text(focus)])
	match kind:
		&"decor_set":
			await ArtLabCheckDecorVfx.run_decor(self)
		&"vfx":
			await ArtLabCheckDecorVfx.run_vfx(self)
		_:
			await _run_model()
	ArtLabCheckBudgets.check_errors(self)
	ArtLabScore.add_extras(self)
	rep.ground = String(ground_id)
	rep.seconds = float(Time.get_ticks_msec() - _t0) / 1000.0
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var diff_line: String = await ArtLabDiff.finish(self, prev)   # focus merge + before / after (diff_sheet.png)
	if not headless and not tiles.is_empty():
		# a focus run keeps the full run's contact sheet and writes its own tiles apart
		var sheet_name := "contact_focus" if rep.focus_note != "" else "contact_sheet"
		var sheet: Image = await rep.contact_sheet(self, tiles)
		sheet.save_png(ProjectSettings.globalize_path(out_dir.path_join(sheet_name + ".png")))
		rep.shots[sheet_name] = sheet_name + ".png"
	rep.write(out_dir)
	if opts.get("log", "1") != "0" and not headless:
		rep.append_log(opts.get("logfile", LOG_PATH), out_dir)
	OS.remove_logger(logger)
	print("ART LAB %s: %s quality %d (%d FAIL, %d WARN, %d PASS) in %.0f s -> %s" % [asset, rep.result(), ArtLabScore.shown(rep.quality()),
		rep.count("FAIL"), rep.count("WARN"), rep.count("PASS"), rep.seconds, out_dir.path_join("scorecard.md")])
	for c: Dictionary in rep.checks:
		if c["status"] == "FAIL" or c["status"] == "WARN":
			print("  %s %s %s: %s" % [c["status"], c["id"], c["name"], c["value"]])
	if rep.focus_note != "":
		print("  " + rep.focus_note)
	if diff_line != "":
		print(diff_line)
	return rep.exit_code()


func _resolve() -> String:
	scene_path = String(opts.get("scene", ""))
	if scene_path == "":
		return "missing scene=res://..."
	var short := scene_path
	if not scene_path.begins_with("res://"):
		scene_path = "res://" + scene_path.trim_prefix("/")
	if not ResourceLoader.exists(scene_path):
		var rs := ArtLabScenes.resolve_scene(short)   # short names work for scene= too
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
			for k: String in ["id", "faction", "body_height", "radius", "is_worker", "move_speed", "flying", "attack_range"]:
				var v: Variant = res.get(k)
				if v != null:
					unit[k] = v
			return


## Sets `stage` for this run: a pooled batch stage (v3, reset to a clean world, built + warmed once per light preset)
## or a new stage owned by this runner. Windowed: shows the lab viewport in the window.
func use_stage(light: StringName) -> void:
	if stage_parent != null:
		if not stage_pool.has(light):
			var st := ArtLabStage.new()
			st.name = "ArtLabStage_" + String(light)
			stage_parent.add_child(st)
			st.setup(light)
			stage_pool[light] = st
			if not headless:
				await st.warm()
		stage = stage_pool[light]
		await stage.reset()
	else:
		stage = ArtLabStage.new()
		stage.name = "ArtLabStage"
		add_child(stage)
		stage.setup(light)
	if not headless:
		show_viewport()


## Shows the lab viewport (the stage's SubViewport) full window.
func show_viewport() -> void:
	var tr := TextureRect.new()
	tr.name = "LabView"
	tr.texture = stage.vp.get_texture()
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(tr)


func frames(n: int) -> void:
	for i: int in n:
		await get_tree().process_frame


func wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func call_hook(o: Object, method: StringName, a: Array = []) -> bool:
	if is_instance_valid(o) and o.has_method(method):
		o.callv(method, a)
		return true
	return false


func save_shot(img: Image, shot: String, png: bool = false) -> void:
	var file := shot + (".png" if png else ".jpg")
	var path := ProjectSettings.globalize_path(out_dir.path_join(file))
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if png:
		img.save_png(path)
	else:
		img.save_jpg(path, 0.9)
	rep.shots[shot] = file


func add_tile(img: Image, label: String) -> void:
	tiles.append({"img": img, "label": label})


## A 16:9 crop of `img` centred on `c` (px), at least `min_size`, scaled back to fit.
func crop(img: Image, c: Vector2, min_size: Vector2i) -> Image:
	var w := mini(maxi(min_size.x, int(float(min_size.y) * 16.0 / 9.0)), img.get_width())
	var h := mini(int(float(w) * 9.0 / 16.0), img.get_height())
	var x := clampi(int(c.x) - w / 2, 0, img.get_width() - w)
	var y := clampi(int(c.y) - h / 2, 0, img.get_height() - h)
	return img.get_region(Rect2i(x, y, w, h))


## A 16:9 crop around a world box as the current camera sees it (pad = extra share of the box size on each side).
func crop_box(img: Image, box: AABB, pad: float = 0.25) -> Image:
	var roi := stage.roi_of(box, 0)
	var w := int(float(roi.size.x) * (1.0 + 2.0 * pad))
	var h := int(float(roi.size.y) * (1.0 + 2.0 * pad))
	return crop(img, Vector2(roi.get_center()), Vector2i(maxi(w, 96), maxi(h, 54)))


func count_nodes(n: Node) -> int:
	return n.find_children("*", "", true, false).size() + 1 if is_instance_valid(n) else 0


func spawn(path: String, at: Vector3, yaw_deg: float, parent: Node = null) -> Node3D:
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


func free_model(n: Node3D) -> void:
	if is_instance_valid(n) and is_instance_valid(n.get_parent()):
		n.get_parent().queue_free()


func model_color(n: Object) -> Color:
	var c: Variant = n.get(&"kingdom_color") if is_instance_valid(n) else null
	if c is Color:
		return c
	return ArtLabBudgets.KINGDOM_COLORS.get(kingdom, Color(0.5, 0.5, 0.5))


func fmt(v: float, d: int = 1) -> String:
	return String.num(v, d)


func _run_model() -> void:
	gp = ArtLabStage.GROUND_POINTS[ground_id]
	ground_y = gp.y
	await _spawn_target()
	if target == null:
		rep.add("H0", "health", "Scene instantiates", "FAIL", "instantiate() failed or the root is not a Node3D",
			"art-units 8 / 10: every model instantiates without errors", "Open the scene, fix the errors in the Output")
		return
	rep.add("H0", "health", "Scene instantiates", "PASS", "root %s, %d nodes" % [target.get_class(), count_nodes(target)],
		"instantiates without errors")
	_read_model_props()
	var cen := ArtLabCensus.census(target, ground_y)
	m["census"] = cen
	if needs("budgets"):
		ArtLabCheckBudgets.check_budgets(self, cen)
	if needs("instances"):
		await ArtLabCheckBudgets.check_instances(self)
	if needs("hooks"):
		ArtLabCheckAnim.check_hooks(self)
	if needs("actions"):
		await ArtLabCheckBudgets.action_cycle(self)
	if needs("craft_geo"):
		ArtLabCheckCraft.check_geometry(self)   # v3.1 C1 / C2 (geometry, headless too)
	lap("headless checks")
	var stop := fail_fast_stop()
	if headless or stop:
		if needs("anim"):
			await ArtLabCheckAnim.death_check(self, [], false)
		for id_name: Array in RENDER_SKIPS:
			rep.add(id_name[0], "read" if String(id_name[0]).begins_with("R") else "budget", id_name[1], "SKIP",
				"headless" if headless else "fail_fast: stopped after a headless FAIL", "needs a windowed run (1600 x 900)")
		ArtLabCheckRead.check_geometry(self)
		return
	ArtLabCheckRead.check_geometry(self)
	if not needs("shots"):
		return   # focus= on headless-only checks
	await ArtLabShots.shots(self)
	lap("shots")
	if needs("craft"):
		await ArtLabCheckCraft.check_render(self)   # v3.1 C3 / C4 (close-up + 25 m)
		lap("craft")
	if needs("read40"):
		await ArtLabCheckRead.read_40(self)
		lap("read_40")
	if focus.is_empty():
		await ArtLabShots.turns(self)
		await ArtLabCheckAnim.anim_strip(self)
		lap("turns + anim strip")
	elif needs("anim"):
		await ArtLabCheckAnim.death_check(self, [], false)   # focus: A2 without the strip
	if opts.get("quick", "0") != "1":
		if needs("refs"):
			await ArtLabCheckRead.references(self)
			lap("references")
		if needs("frame"):
			await ArtLabCheckBudgets.frame_cost(self)
			lap("frame cost")
	else:
		rep.notes.append("quick=1: references (R2) and frame cost (B13) skipped")


## v3 `fail_fast=1`: true when a check already FAILed (the headless checks run first), so the render passes are skipped
## (a broken asset costs seconds, not a full run). Prints the reason once.
func fail_fast_stop() -> bool:
	if opts.get("fail_fast", "0") != "1" or rep.count("FAIL") == 0:
		return false
	var ids: Array[String] = []
	for c: Dictionary in rep.checks:
		if c["status"] == "FAIL":
			ids.append(String(c["id"]))
	print("ART LAB %s: fail_fast after %s (render checks skipped)" % [asset, ", ".join(ids)])
	rep.notes.append("fail_fast=1: stopped after the headless checks (FAIL %s); render checks SKIP" % ", ".join(ids))
	return true


## v3 `focus=`: true when this run must run the pass `phase` (ArtLabDiff.PHASE_IDS key, "shots"); always true in a
## full run.
func needs(phase: String) -> bool:
	return focus.is_empty() or ArtLabDiff.needs(focus, phase)


## v3 `focus=`: for check modules, true when one of `ids` is re-measured in this run (always true in a full run). Guard
## the costly parts of a pass with it (e.g. `if ctx.wants(["R6", "R3t"]): await team_pass(...)`).
func wants(ids: Array) -> bool:
	if focus.is_empty() or ArtLabDiff.has_unknown(focus):
		return true
	for id: Variant in ids:
		if focus.has(String(id)):
			return true
	return false


## `timing=1`: prints the seconds since the last lap (where a run spends its time).
func lap(what: String) -> void:
	if opts.get("timing", "0") != "1":
		return
	var now := Time.get_ticks_msec()
	var last := int(m.get("_lap", _t0))
	m["_lap"] = now
	print("  [timing] %s %.1f s (total %.1f s)" % [what, float(now - last) / 1000.0, float(now - _t0) / 1000.0])


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
	await frames(4)
	get_tree().node_added.disconnect(cb)
	m["authored"] = authored.size()
	await settle(target)


## Lets a fresh instance finish its spawn animation / spawn effects before any shot (Sapling sprout 0.5 s, spawn
## rings): known skip hooks first, then a 0.6 s grace, then wait for the one-shot emitters to finish (<= 3 s).
func settle(inst: Node) -> void:
	if not is_instance_valid(inst):
		return
	for h: StringName in [&"skip_spawn", &"skip_spawn_animation", &"finish_spawn"]:
		call_hook(inst, h)
	_fix_idle_phase(inst)
	await wait(0.6)
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
		await frames(3)
	if tail > 0.0:
		await wait(minf(tail, 1.5))   # the last particles of the finished one-shots fade out
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
		elif kind in [&"building", &"landmark"] and &"_t" in n and typeof(n.get(&"_t")) == TYPE_FLOAT and n.get_script() != null:
			# v3.1 (trial note 6): building / landmark scripts start their own clock at random (`_t = randf() * 10.0` in
			# the keeps), so the glow flicker stood at another moment every run (nature keep R5 35 -> 41 points with no
			# change). Their clock starts at 0 like the kit models' idle phase. Shader TIME stays global. Buildings /
			# landmarks only: on a kit model a child's `_t` is its own effect clock (resetting it moved the Frost
			# Dragon's walk glow count, R5w).
			n.set(&"_t", 0.0)
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

# ---------------------------------------------------------------- compatibility (older callers: tests, sweeps)

## Same as ArtLabScenes.resolve_scene (short scene / ref names).
static func resolve_scene(s: String) -> String:
	return ArtLabScenes.resolve_scene(s)


## Same as ArtLabScenes.list_scenes (model scenes of a folder).
func list_scenes(dir: String, recursive: bool = true) -> Array[String]:
	return ArtLabScenes.list_scenes(dir, recursive)


## Army silhouette pass of a sweep (ArtLabShots.army_pass on this runner as the context).
func army_pass(paths: Array[String], out: String) -> Dictionary:
	return await ArtLabShots.army_pass(self, paths, out)
