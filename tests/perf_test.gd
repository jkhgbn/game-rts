extends SceneTree
## Performance check: many units cross the map at once (pathfinding + avoidance load).
## Run:  godot --headless --path . -s tests/perf_test.gd --fixed-fps 60 --quit-after 3000
## Optional:  -- units=200  to change the army size (default 100);  -- slowdown=0.3  (or env FW_PERF_SLOWDOWN=0.3)
## adds 30 % more work to every frame (a fake regression, to check that the gate still fails).
## Headless = no rendering, so this measures game logic only (CPU), not graphics.
## Uses the wall clock: the Performance TIME_* monitors are not reliable in headless runs.
##
## Load-proof gate (2026-10-14): frame times on a shared laptop (other Godot runs, the hybrid CPU's slow cores) were
## 8.1-8.9 ms for 100 units vs 5.5-7 ms when quiet, so the fixed budget failed on noise. Every frame now also runs a
## fixed calibration slice (CALIB_ITERS steps of vector math over a 196 KB array) and times it. Both run on the same
## thread, core and moment, so whatever slows the game (other runs, a slow core, a lower clock) slows the calibration too:
##   load = calibration ms per slice / CALIB_REF_MS (the quiet laptop's value)
##   norm_ms_per_frame = ms_per_frame / load    (the frame time "on the quiet reference laptop")
## Measured: raw 200-unit frames went 8.7 -> 11.0 ms between runs while norm stayed 17.4 -> 17.9 (old ref).
## A real regression slows the game but not the calibration. The verdict (PERF OK / OVER BUDGET) needs BOTH:
##   1. norm_ms_per_frame <= the absolute budget (8 ms per 100 units, as before), and
##   2. norm_ms_per_frame <= BASELINES[this CPU][units] x (1 + REGRESSION_TOL): the regression gate (a 30 % slower
##      game fails it; the absolute budget alone had 30-40 % headroom and let it through even on a quiet PC).
##      A CPU without a baseline skips (2) and says so; after an intended cost increase, re-base with the
##      "PERF baseline" line of a quiet run.
## The first PERF line (raw ms_per_frame vs the absolute budget) is unchanged for history; "PERF absolute" says whether
## the raw number alone would have passed.

const RUN_FRAMES := 1500          # 25 s of game time at 60 fps
const BUDGET_MS_PER_100 := 8.0    # logic budget per frame for 100 units (a frame is 16.6 ms)
const CALIB_ITERS := 2000         # calibration steps per frame (~0.17 ms on the quiet laptop)
const CALIB_REF_MS := 0.17        # quiet i7-12650H laptop, ms per calibration slice (measured 2026-10-14)
const CALIB_SIZE := 16384         # Vector3 in the calibration array (196 KB: out of L1 / L2, like unit data)
const LOAD_MIN := 0.5             # a calibration this fast is an artefact: clamp the factor
const WINDOW := 100               # frames per window (window median printed for diagnostics)
const REGRESSION_TOL := 0.2       # fail when the normalised frame time is 20 % above this CPU's baseline
## Normalised ms per frame by CPU name (OS.get_processor_name()) and unit count, from quiet runs. Re-base after an
## intended change with the "PERF baseline" line (date + commit in the comment).
const BASELINES := {
	"12th Gen Intel(R) Core(TM) i7-12650H": {100: 5.6, 200: 10.1},   # JS laptop, 2026-10-14 at 46927b74
}

var main: Node
var unit_count := 100
var units: Array = []
var start_positions: Array = []
var frame := 0
var _wait := 0
var _start_usec := 0
var _slowdown := 0.0
var _calib := PackedVector3Array()
var _calib_sink := 0.0
var _calib_usec := 0              # total calibration time inside the measured span
var _calib_slices := 0
var _last_usec := 0               # previous _process timestamp (measured span only)
var _last_calib := 0              # calibration time spent in the previous frame
var _last_inject := 0             # injected work in the previous frame
var _win_game := 0                # current window: game usec, calibration usec
var _win_calib := 0
var _win_frames := 0
var _windows: Array[float] = []   # normalized ms per frame of each full window


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("units="):
			unit_count = int(arg.substr(6))
		elif arg.begins_with("slowdown="):
			_slowdown = float(arg.substr(9))
	if _slowdown <= 0.0 and OS.get_environment("FW_PERF_SLOWDOWN") != "":
		_slowdown = float(OS.get_environment("FW_PERF_SLOWDOWN"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	_calib.resize(CALIB_SIZE)
	for i in CALIB_SIZE:
		_calib[i] = Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 5000:
			print("FAIL: navigation never finished baking")
			return true
		return false
	frame += 1
	if frame == 5:
		_setup_army()
	elif frame == 10:
		_calibrate()   # warm-up slice, not counted
		_start_usec = Time.get_ticks_usec()
		_last_usec = _start_usec
	elif frame > 10:
		var now := Time.get_ticks_usec()
		# The previous frame: engine work + our _process. Game time = the interval minus last frame's calibration.
		var game := (now - _last_usec) - _last_calib
		if frame >= RUN_FRAMES:
			_add_window_frame(game, 0)
			_report()
			return true
		_inject(game - _last_inject)
		var c := _calibrate()
		_calib_usec += c
		_calib_slices += 1
		_last_calib = c
		_add_window_frame(game, c)
		_last_usec = now
	return false


## One calibration slice; returns its duration in usec.
func _calibrate() -> int:
	var t0 := Time.get_ticks_usec()
	var dir := Vector3(0.3, 0.5, 0.8).normalized()
	var acc := 0.0
	var idx := frame * 977
	for i in CALIB_ITERS:
		idx = (idx + 7919) % CALIB_SIZE
		var v: Vector3 = _calib[idx]
		acc += v.dot(dir)
		dir = (dir + v * 0.01).normalized()
	_calib_sink += acc
	return Time.get_ticks_usec() - t0


## The fake regression: spin for `slowdown` x the previous frame's own game work (excluding the previous injection).
func _inject(base_usec: int) -> void:
	_last_inject = 0
	if _slowdown <= 0.0 or base_usec <= 0:
		return
	var t0 := Time.get_ticks_usec()
	var until := t0 + int(base_usec * _slowdown)
	var x := 1.0
	while Time.get_ticks_usec() < until:
		for i in 200:
			x = sqrt(x * 1.0001 + 0.5)
	_calib_sink += x
	_last_inject = Time.get_ticks_usec() - t0


func _add_window_frame(game_usec: int, calib_usec: int) -> void:
	_win_game += game_usec
	_win_calib += calib_usec
	_win_frames += 1
	if _win_frames >= WINDOW and _win_calib > 0:
		var load_w := maxf(LOAD_MIN, _win_calib / 1000.0 / _win_frames / CALIB_REF_MS)
		_windows.append(_win_game / 1000.0 / _win_frames / load_w)
		_win_game = 0
		_win_calib = 0
		_win_frames = 0


func _setup_army() -> void:
	# Remove every existing unit so nobody fights; this test is about movement only.
	for u in root.get_tree().get_nodes_in_group("units"):
		if u != main.hero:
			u.remove_from_group("units")
			u.queue_free()
	var cols := int(ceil(sqrt(float(unit_count))))
	for i in unit_count:
		var u: Unit = main.make_unit("Flame Guard")
		u.team = Unit.Team.PLAYER
		main.add_child(u)
		var offset := Vector3((i % cols - cols * 0.5) * 1.1, 0.0, (floori(float(i) / cols) - cols * 0.5) * 1.1)
		u.global_position = main.PLAYER_START + Vector3(6.0, 0.0, -6.0) + offset
		u.command_stop()
		units.append(u)
		start_positions.append(u.global_position)
	main.selection.select_units(units)
	main.selection.formation_move(main.ARTIFACT_POS + Vector3(-14.0, 0.0, 14.0))


func _report() -> void:
	var target: Vector3 = main.ARTIFACT_POS + Vector3(-14.0, 0.0, 14.0)
	var arrived := 0
	var stuck := 0
	for i in units.size():
		var u: Unit = units[i]
		if not is_instance_valid(u):
			continue
		if u.global_position.distance_to(target) < 15.0:
			arrived += 1
		elif u.global_position.distance_to(start_positions[i]) < 5.0:
			stuck += 1
	var frames := float(RUN_FRAMES - 10)
	# Game time only: the calibration slices are measured apart and taken out.
	var ms_per_frame := (Time.get_ticks_usec() - _start_usec - _calib_usec) / 1000.0 / frames
	var budget := BUDGET_MS_PER_100 * unit_count / 100.0
	var calib_ms := _calib_usec / 1000.0 / maxf(1.0, float(_calib_slices))
	var load_factor := maxf(LOAD_MIN, calib_ms / CALIB_REF_MS)
	var norm := ms_per_frame / load_factor
	var sorted := _windows.duplicate()
	sorted.sort()
	var median: float = sorted[int(sorted.size() / 2.0)] if not sorted.is_empty() else norm
	print("PERF units=%d ms_per_frame=%.2f budget=%.1f arrived=%d stuck=%d" % [
			unit_count, ms_per_frame, budget, arrived, stuck])
	print("PERF load calib_ms=%.3f ref_ms=%.3f load=%.2f norm_ms_per_frame=%.2f window_median=%.2f windows=%d slowdown=%.2f" % [
			calib_ms, CALIB_REF_MS, load_factor, norm, median, _windows.size(), _slowdown])
	print("PERF absolute %s (raw %.2f vs budget %.1f; history only, not the verdict)" % [
			"ok" if ms_per_frame <= budget else "over", ms_per_frame, budget])
	var cpu := OS.get_processor_name()
	var base := -1.0
	if BASELINES.has(cpu) and BASELINES[cpu].has(unit_count):
		base = float(BASELINES[cpu][unit_count])
	var limit := budget
	var why := ""
	if base > 0.0:
		limit = minf(budget, base * (1.0 + REGRESSION_TOL))
		print("PERF gate norm=%.2f limit=%.2f (baseline %.2f +%d %%, budget %.1f) cpu=%s" % [
				norm, limit, base, roundi(REGRESSION_TOL * 100.0), budget, cpu])
	else:
		print("PERF gate norm=%.2f limit=%.2f (budget only: no baseline for cpu '%s' units=%d)" % [norm, limit, cpu, unit_count])
	print("PERF baseline cpu=\"%s\" units=%d norm=%.2f (to re-base on a quiet PC: BASELINES in tests/perf_test.gd)" % [
			cpu, unit_count, norm])
	if stuck > 0:
		why = " (%d stuck units)" % stuck
	elif norm > budget:
		why = " (normalised %.2f > budget %.1f)" % [norm, budget]
	elif norm > limit:
		why = " (normalised %.2f > baseline %.2f +%d %%: a regression)" % [norm, base, roundi(REGRESSION_TOL * 100.0)]
	print("PERF %s%s" % ["OK" if why == "" else "OVER BUDGET", why])
