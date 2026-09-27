extends SceneTree
## MAP LAB: path fairness, mirror / symmetry, distances, choke points and a path heat map of a skirmish map
## (docs/plan/map-lab.md is the manual). Headless, ~30-60 s:
##   & tools/godot_run.ps1 --headless --path . -s res://tools/map_lab/map_lab.gd --fixed-fps 60 --quit-after 9000 -- [map=1v1]
## Args after `--` (key=value):
##   map    1v1 (Crown Hollow, default) or 2v2 (Fourfold Hollow, docs/design/map-2v2.md; SKIP until its scene exists)
##   scene  override the profile's scene path
##   out    output folder (default docs/maps/lab/<run>/): scorecard.md, scorecard.json, heatmap.png
##   run    run name (default: date_time_map, e.g. 2026-09-26_2350_1v1)
##   log    0 = no row in docs/maps/lab/history.md
##   heat   0 = no heat map
##   sim    0 = load the full art (default 1: Bot Lab sim mode, same colliders and navmesh, faster)
##   profile_json  a World Forge profile (docs/tools/world_forge/out/<map>/map_profile.json) instead of map=
## Exit code: 0 PASS / WARN / SKIP, 1 FAIL. Last lines: `MAP LAB: <RESULT> score <N> ...` and one line per FAIL / WARN check.

const Report := preload("res://tools/map_lab/map_report.gd")
const Checks := preload("res://tools/map_lab/map_checks.gd")
const Profiles := preload("res://tools/map_lab/map_profiles.gd")
const _SIM := preload("res://scripts/core/sim_mode.gd")
const HISTORY := "res://docs/maps/lab/history.md"
const TIMEOUT_FRAMES := 7000     ## the bake + level start must be done by then
const SETTLE_FRAMES := 10        ## frames after the level is ready (navigation map sync)

var opts := {}
var profile := {}
var level: Node
var frame := 0
var ready_frame := -1
var t0 := 0


func _initialize() -> void:
	t0 = Time.get_ticks_usec()
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		opts[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var map_name := String(opts.get("map", "1v1"))
	profile = Profiles.get_profile(map_name)
	if opts.has("profile_json"):   # World Forge: generated profile (tools/world_forge/README.md)
		profile = Profiles.from_json(String(opts["profile_json"]))
		map_name = String(opts["profile_json"])
	if profile.is_empty():
		print("MAP LAB: FAIL unknown map '%s' (known: %s)" % [map_name, ", ".join(Profiles.names())])
		quit(1)
		return
	var scene_path := String(opts.get("scene", profile["scene"]))
	if not ResourceLoader.exists(scene_path):
		print("MAP LAB: SKIP %s: scene %s does not exist yet (pass scene=<path> when it does)" % [profile["title"], scene_path])
		quit(0)
		return
	_SIM.enabled = String(opts.get("sim", "1")) != "0"
	level = (load(scene_path) as PackedScene).instantiate()
	for k: String in profile.get("settings", {}):
		if k in level:
			level.set(k, profile["settings"][k])
	_disable_bots(level)
	root.add_child(level)
	current_scene = level


func _process(_delta: float) -> bool:
	if level == null:
		return true
	frame += 1
	if ready_frame < 0:
		_disable_bots(level)
		var started: Variant = level.get(&"match_started")
		if started == true or level.get(&"hero") != null:
			ready_frame = frame
		elif frame > TIMEOUT_FRAMES:
			print("MAP LAB: FAIL the level never finished its navmesh bake (%d frames)" % frame)
			quit(1)
			return true
		return false
	if frame < ready_frame + SETTLE_FRAMES:
		return false
	var report: Report = run_on(level, profile, opts, t0, ready_frame)
	quit(report.exit_code())
	return true


## Bots off (the lab only measures the map): every node with an `enabled` flag under an AI script.
static func _disable_bots(node: Node) -> void:
	for c: Node in node.get_children():
		var s: Script = c.get_script()
		if s and s.resource_path.contains("/ai/") and &"enabled" in c:
			c.set(&"enabled", false)


## Runs the lab on a loaded level whose navmesh is baked; writes the scorecard (+ history row unless log=0) and
## returns the report. Usable from a test (opts: out, run, log, heat, scene). 	0 / eady_frame only feed the notes.
static func run_on(level: Node, profile: Dictionary, opts: Dictionary, t0: int = 0, ready_frame: int = 0) -> Report:
	var report := Report.new()
	report.title = "Map Lab: %s" % profile["title"]
	var now := Time.get_datetime_dict_from_system()
	var suffix := "_" + String(profile["name"])
	report.run_id = String(opts.get("run", "%04d-%02d-%02d_%02d%02d%s" % [now.year, now.month, now.day, now.hour, now.minute, suffix]))
	report.started = "%04d-%02d-%02d %02d:%02d" % [now.year, now.month, now.day, now.hour, now.minute]
	var out_dir := String(opts.get("out", "res://docs/maps/lab/" + report.run_id))
	var log_on := String(opts.get("log", "1")) != "0"
	if log_on:
		report.previous_score = Report.read_previous(HISTORY, suffix)
	var t_ready := Time.get_ticks_usec()
	var checks := Checks.new(report, profile, level)
	checks.heat_on = String(opts.get("heat", "1")) != "0"
	checks.out_dir = out_dir
	checks.run()
	report.notes.append("Map %s, scene %s, sim mode %s; level load + navmesh bake %.1f s (%d frames), lab %.1f s. Spec: %s." % [
		profile["title"], String(opts.get("scene", profile["scene"])), "on" if _SIM.enabled else "off",
		float(t_ready - t0) / 1e6, ready_frame, float(Time.get_ticks_usec() - t_ready) / 1e6, profile.get("spec", "-")])
	report.extras.append({"title": "Open the heat map", "source": "H1",
		"text": "heatmap.png shows where the shortest paths crowd: the red metres are the likely fights"})
	report.extras.append({"title": "Combat heat from bot games", "source": "lab idea",
		"text": "v2: feed Bot Lab / Replay Lab unit deaths into the heat map"})
	report.extras.append({"title": "Terrain costs in travel times", "source": "lab idea",
		"text": "T1 has the ford slow; add the step-12b terrain speed costs (mud, heath) per path metre"})
	report.seconds = float(Time.get_ticks_usec() - t0) / 1e6
	report.write(out_dir)
	if log_on:
		report.append_history(HISTORY, out_dir)
	print("MAP LAB: %s score %.0f / 100 (%d FAIL, %d WARN, %d PASS checks; %d FAIL, %d WARN findings) %.1f s -> %s" % [
		report.result(), report.quality(), report.count("FAIL"), report.count("WARN"), report.count("PASS"),
		report.count_findings("FAIL"), report.count_findings("WARN"), report.seconds, out_dir.path_join("scorecard.md")])
	for c: Dictionary in report.checks:
		if c["status"] == "FAIL" or c["status"] == "WARN":
			print("  %s %s %s: %s" % [c["status"], c["id"], c["name"], c["value"]])
	return report
