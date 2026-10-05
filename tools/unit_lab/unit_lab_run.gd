extends SceneTree
## Unit Lab (docs/plan/unit-lab.md): the HEADLESS runner. Plays the fights of one spec (or one shard of them) in a
## row, one fresh UnitLabArena per fight, and appends one JSON line per fight to --out. Launched by
## tools/unit_lab/run_unit_lab.ps1 (several shards in parallel); runnable alone:
##   godot --headless --path . -s tools/unit_lab/unit_lab_run.gd --fixed-fps 60 --quit-after 9000000 -- \
##       --spec=c1_kilnwarden --seeds=1-4 --out=C:/tmp/u.jsonl
## User args (after "--"):
##   --spec=X        a preset name (tools/unit_lab/presets/X.json), a .json path, or a fight text line
##   --seeds=1-10    overrides the spec's seeds;  --limit=90  overrides time_limit;  --tick=60 physics rate
##   --shard=i/n     plays only the jobs with index % n == i (jobs: seed -> arm, or pair -> seed for a matrix)
##   --variant=PATH  a Balance Lab variant JSON (tools/balance_lab/variants/*.json format), applied in memory before
##                   the first fight (tools/balance_lab/balance_match.gd apply_to_resources); "baseline" = none
##   --arm=NAME      plays only that arm;  --out=PATH  the JSONL file (appended);  --log=1  prints each fight's log
##   --budget=N      matrix budget override;  --entries=a,b,c  matrix entries override
## Output line: the arena's result + {"variant", "job"}; a last line "UNIT_LAB done ..." on stdout.

const SPEC := preload("res://tools/unit_lab/unit_lab_spec.gd")
const ARENA := preload("res://tools/unit_lab/unit_lab_arena.gd")
const BALANCE_MATCH := "res://tools/balance_lab/balance_match.gd"

var args := {}
var spec: Dictionary = {}
var jobs: Array = []        # [{arm: Dictionary, seed: int, swap: bool, extra: Dictionary}]
var job_i := 0
var arena: Node3D = null
var out_path := ""
var variant_name := "baseline"
var variant_applied: Array = []
var variant_errors: Array = []
var _held: Array = []
var _t0 := 0
var _fight_frames := 0
var _max_frames := 0
var _done := 0
var _errors: Array = []
var _print_log := false


func _initialize() -> void:
	_t0 = Time.get_ticks_msec()
	for a: String in OS.get_cmdline_user_args():
		var s := a.trim_prefix("--").trim_prefix("++")
		var eq := s.find("=")
		if eq < 0:
			args[s] = "1"
		else:
			args[s.substr(0, eq)] = s.substr(eq + 1)
	out_path = String(args.get("out", ""))
	_print_log = String(args.get("log", "0")) == "1"
	_apply_variant(String(args.get("variant", "")))
	var src := String(args.get("spec", "mirror_flame_guard"))
	var data: Variant = SPEC.read_json(src) if src.ends_with(".json") else null
	if data is Dictionary and (data as Dictionary).has("text"):
		spec = SPEC.parse_text(String(data["text"]), _errors)
	else:
		spec = SPEC.load_any(src, _errors)
	if args.has("seeds"):
		spec["seeds"] = SPEC.parse_seeds(String(args["seeds"]))
	if args.has("limit"):
		spec["time_limit"] = String(args["limit"]).to_float()
	var tick := int(args.get("tick", spec.get("tick", 60)))
	Engine.physics_ticks_per_second = tick
	_build_jobs()
	_max_frames = int((float(spec["time_limit"]) + 15.0) * tick)
	if not _errors.is_empty():
		push_warning("UNIT_LAB spec problems: " + "; ".join(_errors))
	print("UNIT_LAB start spec=%s mode=%s jobs=%d variant=%s tick=%d" % [spec.get("name", "?"), spec.get("mode", "?"),
			jobs.size(), variant_name, tick])
	node_added.connect(_on_node_added)


func _build_jobs() -> void:
	var all: Array = []
	var seeds: Array = spec.get("seeds", [1])
	if String(spec.get("mode", "arms")) == "matrix":
		var m: Dictionary = spec["matrix"]
		if args.has("budget"):
			m["budget"] = String(args["budget"]).to_int()
		if args.has("entries"):
			var es: Array[String] = []
			for e in String(args["entries"]).split(",", false):
				es.append(e.strip_edges())
			m["entries"] = es
		for pair: Array in SPEC.matrix_pairs(m):
			for sd: int in seeds:
				all.append({"pair": pair, "seed": sd, "swap": sd % 2 == 0})
	else:
		for sd: int in seeds:
			for arm: Dictionary in spec.get("arms", []):
				if args.has("arm") and String(arm["name"]) != String(args["arm"]):
					continue
				all.append({"arm": arm, "seed": sd, "swap": sd % 2 == 0})
	var shard_i := 0
	var shard_n := 1
	if args.has("shard"):
		var p := String(args["shard"]).split("/")
		if p.size() == 2:
			shard_i = p[0].to_int()
			shard_n = maxi(1, p[1].to_int())
	for i in all.size():
		if i % shard_n == shard_i:
			var j: Dictionary = all[i]
			j["job"] = i
			jobs.append(j)


func _apply_variant(path: String) -> void:
	if path == "" or path == "baseline":
		return
	var bm := load(BALANCE_MATCH) as Script
	var data: Variant = SPEC.read_json(path)
	if bm == null or not (data is Dictionary):
		variant_errors.append("can't read variant %s" % path)
		variant_name = "unreadable"
		return
	variant_name = String((data as Dictionary).get("name", path.get_file().get_basename()))
	bm.call(&"apply_to_resources", data, variant_applied, variant_errors, _held)
	print("UNIT_LAB variant %s: %d overrides, %d errors" % [variant_name, variant_applied.size(), variant_errors.size()])


func _process(_delta: float) -> bool:
	if arena == null:
		if job_i >= jobs.size():
			print("UNIT_LAB done %d fights in %.1fs (%s)" % [_done, (Time.get_ticks_msec() - _t0) / 1000.0, out_path])
			return true
		_start_job(jobs[job_i])
		return false
	_fight_frames += 1
	if not bool(arena.get(&"ended")) and _fight_frames > _max_frames:
		arena.call(&"end_fight", "draw", "cap")
	if bool(arena.get(&"ended")):
		_finish_job()
	return false


func _start_job(j: Dictionary) -> void:
	var arm: Dictionary
	var extra := {"variant": variant_name, "job": int(j["job"])}
	if j.has("pair"):
		var errs: Array = []
		arm = SPEC.matrix_arm(spec["matrix"], String(j["pair"][0]), String(j["pair"][1]), errs)
		extra["entry_a"] = arm["entry_a"]
		extra["entry_b"] = arm["entry_b"]
		extra["budget"] = int((spec["matrix"] as Dictionary)["budget"])
	else:
		arm = j["arm"]
	arena = ARENA.new()
	arena.name = "UnitLabArena"
	arena.set(&"arena_size", float(spec.get("arena", 80.0)))
	arena.set(&"log_enabled", _print_log)
	arena.set(&"extra", extra)
	root.add_child(arena)
	current_scene = arena
	arena.call(&"setup", spec, arm, int(j["seed"]), bool(j["swap"]))
	_fight_frames = 0


func _finish_job() -> void:
	var r: Dictionary = arena.get(&"result")
	if _print_log:
		for l: String in arena.get(&"log_lines"):
			print("  " + l)
	_write(r)
	_done += 1
	print("UNIT_LAB fight %d/%d %s seed %d: %s (%s, %.1fs)" % [job_i + 1, jobs.size(), r.get("arm", ""),
			int(r.get("seed", 0)), r.get("winner", "?"), r.get("reason", "?"), float(r.get("time", 0.0))])
	arena.call(&"clear_units")
	root.remove_child(arena)
	arena.free()
	arena = null
	current_scene = null
	job_i += 1


func _write(r: Dictionary) -> void:
	if out_path == "":
		print("UNIT_LAB_RESULT " + JSON.stringify(r))
		return
	var f: FileAccess
	if FileAccess.file_exists(out_path):
		f = FileAccess.open(out_path, FileAccess.READ_WRITE)
		if f:
			f.seek_end()
	else:
		f = FileAccess.open(out_path, FileAccess.WRITE)
	if f == null:
		push_error("UNIT_LAB: can't write %s" % out_path)
		return
	f.store_line(JSON.stringify(r))
	f.close()


# Art scripts (res://art/, res://scripts/vfx/) stop processing in the headless runner (the Bot Lab's sim freeze: the
# hooks still run, only the per-frame animation stops); a unit's model wakes up when it dies (death timing kept).
func _on_node_added(node: Node) -> void:
	var script := node.get_script() as Script
	if script == null:
		return
	var path := script.resource_path
	if not (path.begins_with("res://art/") or path.begins_with("res://scripts/vfx/")):
		return
	var p := node.get_parent()
	for i in 8:
		if p == null:
			break
		if p is Unit:
			node.process_mode = Node.PROCESS_MODE_DISABLED
			var wake := func(_u: Variant) -> void:
				if is_instance_valid(node):
					node.process_mode = Node.PROCESS_MODE_INHERIT
			(p as Unit).died.connect(wake, CONNECT_ONE_SHOT)
			return
		p = p.get_parent()
	if script.get_script_signal_list().is_empty():
		node.process_mode = Node.PROCESS_MODE_DISABLED
