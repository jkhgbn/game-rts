extends SceneTree
## G-F root-cause pass (CLAUDE.md "Recurring bugs"): looping particle emitters on unit models kept emitting while the
## model was off-screen (Shadow wisps, Ice snow). CharacterModel now pauses every looping emitter it cached at _ready
## while `_offscreen` holds and restarts only those afterwards; this test keeps any model from regressing.
## Run: $GODOT --headless --path . -s tests/test_gf_offscreen_emitters.gd --fixed-fps 60 --quit-after 6000
## (optionally `-- --gfx=ultra`; the per-feature quality overrides below already force the High+ emitters).
## Steps: every model scene of data/units, data/champions, data/helpers (UnitType / ChampionType / helper
## `model_scene`) plus the mount and titan scenes is instanced on a grid 22 m under a camera (kit tier 0), with the
## High-only emitters forced (Ice snow, Shadow wisps, wizard aura, creature signatures). The camera looks down: the
## looping emitters emitting are recorded. Then `offscreen_freeze` is set on the model root (as Unit._build_model does)
## and the camera looks up (every model off-screen, still tier 0): no looping GPUParticles3D / CPUParticles3D may emit.
## Then it looks down again: every emitter that emitted before must emit again. Then, off-screen: the camera goes
## beyond the far tier and back (tier changes while paused: nothing turns on, all back on screen); every model dies
## (no emitter on the corpse once seen again); every model revives off-screen (nothing until seen, then all back).
## One-shot emitters are ignored.
## Prints "PASS gf_offscreen_emitters (N models, M emitters)" or "FAIL gf_offscreen_emitters: <list>".

const TASK_ID := "gf_offscreen_emitters"
const DATA_DIRS: Array[String] = ["res://data/units", "res://data/champions", "res://data/helpers"]
const SCENE_DIRS: Array[String] = ["res://art/units/mounts", "res://art/units/titans"]
const CAM_H := 22.0
const SPACING := 2.2
const SETTLE := 45
## Camera height beyond every model tier-1 range (45 m): kit tier 2, flyer / treant far tier.
const FAR_H := 60.0
## Longer than every death animation (kit DEATH_LEN, flyers 1.85 s, titans): the corpse stops processing.
const DEATH_FRAMES := 180
## Past every model's death_glow_off (kit fall: 0.25 s) but before the end of its death animation.
const GLOW_OFF_FRAMES := 40

var _fails: PackedStringArray = PackedStringArray()
var _notes: PackedStringArray = PackedStringArray()
var _world: Node3D
var _cam: Camera3D


func _initialize() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	_cam = Camera3D.new()
	_cam.far = 400.0
	_world.add_child(_cam)
	_cam.position = Vector3(0, CAM_H, 0)
	_look(false)
	_run()


func _look(up: bool, h: float = CAM_H) -> void:
	var dir := Vector3.UP if up else Vector3.DOWN
	_cam.transform = Transform3D(Basis.looking_at(dir, Vector3(0, 0, -1)), Vector3(0, h, 0))


## The model's off-screen flag: its own `_offscreen`, else (rider + mount roots) any direct child's.
func _is_offscreen(m: Node) -> bool:
	if &"_offscreen" in m:
		return bool(m.get(&"_offscreen"))
	for c: Node in m.get_children():
		if &"_offscreen" in c and bool(c.get(&"_offscreen")):
			return true
	return false


func _force_quality(q: int) -> void:
	IceModel.snow_quality_override = q
	ShadowModel.wisp_quality_override = q
	WizardModel.aura_quality_override = q
	CreatureSignature.quality_override = q


func _scene_paths() -> PackedStringArray:
	var out := PackedStringArray()
	for d: String in DATA_DIRS:
		for f: String in DirAccess.get_files_at(d):
			if not f.ends_with(".tres"):
				continue
			var r := load(d + "/" + f)
			if r == null:
				continue
			var ms: Variant = r.get(&"model_scene")
			if ms is PackedScene and (ms as PackedScene).resource_path != "":
				var p := (ms as PackedScene).resource_path
				if not out.has(p):
					out.append(p)
	for d: String in SCENE_DIRS:
		for sub: String in DirAccess.get_directories_at(d):
			var p := "%s/%s/%s.tscn" % [d, sub, sub]
			if ResourceLoader.exists(p) and not out.has(p):
				out.append(p)
	return out


func _loop_emitters(n: Node, out: Array[Node]) -> void:
	for c: Node in n.get_children():
		if c is GPUParticles3D and not (c as GPUParticles3D).one_shot:
			out.append(c)
		elif c is CPUParticles3D and not (c as CPUParticles3D).one_shot:
			out.append(c)
		_loop_emitters(c, out)


## Every looping emitter still emitting is a failure "<model>: <node> <what>". Returns how many were checked off.
func _check_none(models: Array[Node3D], names: PackedStringArray, what: String) -> int:
	var n := 0
	for k: int in models.size():
		var em: Array[Node] = []
		_loop_emitters(models[k], em)
		for e: Node in em:
			if bool(e.get(&"emitting")):
				_fails.append("%s: %s %s" % [names[k], models[k].get_path_to(e), what])
			else:
				n += 1
	return n


## Every emitter that emitted in the first on-screen look must emit again.
func _check_restored(models: Array[Node3D], names: PackedStringArray, before: Array, what: String) -> void:
	for k: int in models.size():
		for e: Node in before[k]:
			if is_instance_valid(e) and not bool(e.get(&"emitting")):
				_fails.append("%s: %s %s" % [names[k], models[k].get_path_to(e), what])


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _run() -> void:
	_force_quality(3)
	var paths := _scene_paths()
	var models: Array[Node3D] = []
	var names: PackedStringArray = PackedStringArray()
	var side := int(ceil(sqrt(float(paths.size()))))
	for i: int in paths.size():
		var ps := load(paths[i]) as PackedScene
		var m: Node3D = ps.instantiate() as Node3D if ps else null
		if m == null:
			_notes.append("%s: not a Node3D scene" % paths[i])
			continue
		var gx := float(i % side) - float(side - 1) * 0.5
		var gz := floorf(float(i) / float(side)) - float(side - 1) * 0.5
		m.position = Vector3(gx * SPACING, 0, gz * SPACING)
		_world.add_child(m)
		models.append(m)
		names.append(paths[i].get_file().get_basename())
	await _frames(SETTLE)
	# 1. on screen: what emits
	var before: Array = []   # per model: Array[Node] emitting
	var total := 0
	var no_state: PackedStringArray = PackedStringArray()
	for k: int in models.size():
		var em: Array[Node] = []
		_loop_emitters(models[k], em)
		var on: Array[Node] = []
		for e: Node in em:
			if bool(e.get(&"emitting")):
				on.append(e)
		total += em.size()
		before.append(on)
		if &"offscreen_freeze" in models[k]:
			models[k].set(&"offscreen_freeze", true)   # as Unit._build_model sets it
		elif not em.is_empty():
			no_state.append(names[k])
	# 2. off-screen (camera turned away, same distance: still tier 0)
	_look(true)
	await _frames(SETTLE)
	for k: int in models.size():
		if &"offscreen_freeze" in models[k] and not _is_offscreen(models[k]):
			_fails.append("%s: test setup: model not off-screen" % names[k])
	var off_ok := _check_none(models, names, "emits off-screen")
	# 3. back on screen: the ones that emitted before emit again
	_look(false)
	await _frames(SETTLE)
	_check_restored(models, names, before, "not restored on screen")
	# 4. distance-tier changes while paused (0 -> 2 -> 0, still looking away): nothing turns on off-screen, and
	#    everything comes back on screen afterwards
	_look(true)
	await _frames(SETTLE)
	_look(true, FAR_H)
	await _frames(SETTLE)
	_check_none(models, names, "emits off-screen after a tier change (far)")
	_look(true)
	await _frames(SETTLE)
	_check_none(models, names, "emits off-screen after a tier change (near again)")
	_look(false)
	await _frames(SETTLE)
	_check_restored(models, names, before, "not restored on screen after tier changes off-screen")
	# 5. death off-screen, then seen again: no looping emitter restarts on the corpse
	_look(true)
	await _frames(SETTLE)
	for m: Node3D in models:
		if m.has_method(&"play_death"):
			m.call(&"play_death")
	await _frames(GLOW_OFF_FRAMES)
	_check_none(models, names, "emits off-screen while dying")
	_look(false)   # seen again mid-fall (before DEATH_LEN): the pause lifts while the death still animates
	await _frames(DEATH_FRAMES)
	_check_none(models, names, "restarted on the corpse when seen again")
	# 6. revive while off-screen: nothing emits until the model is seen again, then the emitters are back
	_look(true)
	await _frames(SETTLE)
	for m: Node3D in models:
		if m.has_method(&"revive"):
			m.call(&"revive")
	await _frames(SETTLE)
	_check_none(models, names, "emits off-screen after a revive off-screen")
	_look(false)
	await _frames(SETTLE)
	_check_restored(models, names, before, "not back on screen after a revive off-screen")
	_force_quality(-1)
	for m: Node3D in models:
		m.queue_free()
	await process_frame
	if not no_state.is_empty():
		print("NOTE %s: roots without offscreen_freeze (Unit never pauses them): %s" % [TASK_ID, ", ".join(no_state)])
	for n: String in _notes:
		print("NOTE %s: %s" % [TASK_ID, n])
	var emitting_before := 0
	for b: Array in before:
		emitting_before += b.size()
	if emitting_before < 10:
		_fails.append("test setup: only %d looping emitters emit on screen (High-only emitters not built?)" % emitting_before)
	print("INFO %s: %d models, %d looping emitters, %d emitting on screen, %d checked off-screen" % [TASK_ID, models.size(), total,
		emitting_before, off_ok])
	if _fails.is_empty():
		print("PASS %s (%d models, %d emitters)" % [TASK_ID, models.size(), total])
	else:
		print("FAIL %s: %d problem(s)\n  %s" % [TASK_ID, _fails.size(), "\n  ".join(_fails)])
	quit()
