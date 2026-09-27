extends Node
## Perf Lab (docs/plan/perf-lab.md): the band profiler. Opt-in, autoload-free, no game code touched.
##
## How it works: Godot runs every node's _process / _physics_process (and internal processing) in ascending
## process_priority / process_physics_priority order. The probe gives every scripted node (and a few built-in
## classes that process, like NavigationAgent3D) a priority band per script ("band" = all nodes running that script),
## then puts a tiny marker node before each band. Each marker stamps Time.get_ticks_usec(); the gap between two markers
## is what that band's nodes cost this frame. Nodes nobody classified keep their priority (0) and fall in the "other"
## band that starts at the very first marker. The gaps after the last marker are the engine's own work: physics +
## navigation server step (after the physics pass) and render + tweens + idle (after the process pass).
##
## Side effects (documented in the scorecard): process order changes between scripts (bands are in SYSTEM order,
## mount models before riders), and every marker costs ~1 us per pass. The lab runs the frame-time numbers without the
## probe (repeats) and the hot list with it (one run), so the overhead never pollutes the headline numbers.
##
## Usage (a SceneTree script):
##   probe = preload("res://tools/perf_lab/perf_probe.gd").new()
##   root.add_child(probe)                  # before the level, so node_added sees every node
##   probe.begin_frame() at the top of the SceneTree's _process (closes the previous frame, returns its band times)

const BASE := 1_000_000
const STEP := 16
const START_PRIO := -2_000_000_000
const END_PRIO := 2_000_000_000
## Built-in node classes worth a band of their own (they process internally).
const BUILTIN_BANDS: Array[String] = ["NavigationAgent3D", "AnimationPlayer", "AnimationTree", "CPUParticles3D",
	"GPUParticles3D", "Skeleton3D", "NavigationObstacle3D", "AudioStreamPlayer3D", "AudioStreamPlayer", "Timer",
	"RayCast3D", "ShapeCast3D", "Area3D"]
## Band order: system prefixes first (earlier = processed earlier). Mount models before characters (the rider reads
## the seat after the mount posed it: character_model.gd sets its priority to mount + 1).
const ORDER_HINTS: Array[String] = ["scripts/core/", "scripts/world/", "scripts/ai/", "scripts/economy/",
	"scripts/buildings/", "scripts/units/", "scripts/spells/", "scripts/items/", "art/units/kit/mount_model",
	"art/", "scripts/vfx/", "scripts/ui/", "["]

var enabled := true
var bands: Array[String] = ["(other: unclassified nodes)"]   ## index 0 = before the first marker
var band_nodes: PackedInt32Array = PackedInt32Array([0])     ## nodes assigned per band (running count)
var _index := {}                   ## key -> band index
var _proc_markers: Array[Node] = []
var _clock := Clock.new()
var _order_slots := {}             ## ORDER_HINTS index -> Array of band keys (to keep system order when growing)
var _dirty := false


class Clock:
	extends RefCounted
	var proc_acc := PackedInt64Array()
	var phys_acc := PackedInt64Array()
	var last := 0
	var last_kind := 0             ## 0 none, 1 physics end, 2 process end
	var last_end := 0
	var engine_physics := 0        ## physics server + navigation step (gap after the physics pass)
	var engine_other := 0          ## render + tweens + input + idle (gap after the process pass)
	var physics_steps := 0

	func resize(n: int) -> void:
		proc_acc.resize(n)
		phys_acc.resize(n)

	func mark(k: int, physics: bool, is_end: bool) -> void:
		var now := Time.get_ticks_usec()
		if k == 0:
			if physics:
				physics_steps += 1
			_close_gap(now)
		else:
			if physics:
				phys_acc[k - 1] += now - last
			else:
				proc_acc[k - 1] += now - last
		last = now
		if is_end:
			last_kind = 1 if physics else 2
			last_end = now

	## Called at the start of a pass (marker 0) and by the SceneTree script: the time since the previous pass ended.
	func _close_gap(now: int) -> void:
		if last_kind == 1:
			engine_physics += now - last_end
		elif last_kind == 2:
			engine_other += now - last_end
		last_kind = 0


class Marker:
	extends Node
	var k := 0
	var is_end := false
	var clock: RefCounted

	func _process(_d: float) -> void:
		clock.mark(k, false, is_end)

	func _physics_process(_d: float) -> void:
		clock.mark(k, true, is_end)


func _init() -> void:
	name = "PerfLabProbe"
	process_mode = Node.PROCESS_MODE_ALWAYS


func _enter_tree() -> void:
	var tree := get_tree()
	if not tree.node_added.is_connected(_on_node_added):
		tree.node_added.connect(_on_node_added)
	if _proc_markers.is_empty():
		var first: Array[String] = []
		for p: String in ["art/units/kit/mount_model.gd", "art/units/kit/character_model.gd"]:
			if ResourceLoader.exists("res://" + p):
				first.append(p)
		prime(first)


## Classifies a node: its band key, or "" to leave it alone.
static func key_of(n: Node) -> String:
	var s := n.get_script() as Script
	if s != null:
		var p := s.resource_path
		if p == "":
			return ""
		if p.begins_with("res://tools/perf_lab/"):
			return ""
		return p.trim_prefix("res://")
	var c := n.get_class()
	# A Timer / AnimationPlayer runs its owner's callbacks (the Commander thinks on a Timer): charge its parent's band.
	if (c == "Timer" or c == "AnimationPlayer") and n.get_parent() != null and n.get_parent().get_script() != null:
		var pk := key_of(n.get_parent())
		if pk != "":
			return pk
	if BUILTIN_BANDS.has(c):
		return "[" + c + "]"
	return ""


func _on_node_added(n: Node) -> void:
	if not enabled or n is Marker or n == self:
		return
	var key := key_of(n)
	if key == "":
		return
	var k: int = _index.get(key, -1)
	if k < 0:
		k = _add_band(key)
	n.process_priority = _prio_of(k) + 1
	n.process_physics_priority = _prio_of(k) + 1
	band_nodes[k] += 1


func _prio_of(k: int) -> int:
	return BASE + k * STEP


func _order_rank(key: String) -> int:
	for i in ORDER_HINTS.size():
		if key.begins_with(ORDER_HINTS[i]):
			return i
	return ORDER_HINTS.size()


## New band. Bands are appended (priorities never move once given), so bands follow first-seen order. The mount and
## character model bands are reserved first (prime), so a rider (mount priority + 1) still lands after its mount.
func _add_band(key: String) -> int:
	bands.append(key)
	band_nodes.append(0)
	var k := bands.size() - 1
	_index[key] = k
	_dirty = true
	return k


## Reserves bands in ORDER_HINTS order for the given keys (call before the level enters the tree).
func prime(keys: Array[String]) -> void:
	var sorted := keys.duplicate()
	sorted.sort_custom(func(a: String, b: String) -> bool:
		var ra := _order_rank(a)
		var rb := _order_rank(b)
		return ra < rb if ra != rb else a < b)
	for key: String in sorted:
		if not _index.has(key):
			_add_band(key)
	_rebuild_markers()


func _rebuild_markers() -> void:
	# One marker per band (marker k sits just below band k's nodes) + the start and end markers.
	var want := bands.size() + 1   # marker 0 = start, markers 1..n-1 = before band 1..n-1, last = end
	while _proc_markers.size() < want:
		var m := Marker.new()
		m.clock = _clock
		m.name = "PerfMarker%d" % _proc_markers.size()
		_proc_markers.append(m)
		add_child(m)
	for i in _proc_markers.size():
		var m: Marker = _proc_markers[i]
		m.k = i
		m.is_end = i == want - 1
		var prio := START_PRIO if i == 0 else (END_PRIO if m.is_end else _prio_of(i))
		m.process_priority = prio
		m.process_physics_priority = prio
		m.set_process(i < want)
		m.set_physics_process(i < want)
	_clock.resize(bands.size())
	_dirty = false


## Top of the SceneTree script's _process: returns the previous frame's cost per band in usec
## {proc: PackedInt64Array, phys: PackedInt64Array, engine_physics, engine_other, physics_steps} and resets.
## (The SceneTree script's own _process runs before every node's _process, so this sees a whole frame.)
func begin_frame() -> Dictionary:
	if _dirty:
		_rebuild_markers()
	_clock._close_gap(Time.get_ticks_usec())
	var out := {"proc": _clock.proc_acc.duplicate(), "phys": _clock.phys_acc.duplicate(),
		"engine_physics": _clock.engine_physics, "engine_other": _clock.engine_other,
		"physics_steps": _clock.physics_steps}
	_clock.proc_acc.fill(0)
	_clock.phys_acc.fill(0)
	_clock.engine_physics = 0
	_clock.engine_other = 0
	_clock.physics_steps = 0
	return out


## Re-applies the bands to every node already in the tree (for a probe added after the level).
func classify_tree(from: Node) -> void:
	_on_node_added(from)
	for n: Node in from.find_children("*", "", true, false):
		_on_node_added(n)
