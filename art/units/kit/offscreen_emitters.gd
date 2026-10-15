class_name OffscreenEmitters
extends RefCounted
## G-F root-cause pass (CLAUDE.md "Recurring bugs": looping emitters on unit models kept emitting off-screen, Shadow
## wisps then Ice snow). One per model root (CharacterModel, FlyerModel): `cache(root)` once after the model is built
## lists every looping emitter (GPUParticles3D / CPUParticles3D, not one_shot) under it; `pause(true)` when the model
## goes off-screen stops the ones emitting and remembers them, `pause(false)` restarts only those. Skipped by the cache:
## emitters under a nested model root that owns its own pause (any node with an `offscreen_freeze` property) and
## emitters with their own script (self-gated: Shadow SoulWisps, creature Signature; they read the model's state).
## Every runtime on / off a model makes on a looping emitter goes through `set_emitting(p, on)` (its
## set_fx_emitting()), never a direct `emitting =` write; `clear_restore()` at death.
## `tier_set(list, on)` is the distance-tier switch for a model's tier-driven list: while paused it only edits the set
## restored on screen, so a tier change never turns an emitter on off-screen.
## `outside_view(n)`: true when `n` is more than OFFSCREEN_MARGIN m (x its scale) outside the root viewport camera's
## frustum (planes cached once per frame for every model); false in SubViewports or without a camera.
## Guarded by tests/test_gf_offscreen_emitters.gd (every unit / champion / helper / mount / titan model).

const OFFSCREEN_MARGIN := 6.0

static var _fr_frame: int = -1
static var _fr_planes: Array[Plane] = []

var paused: bool = false
var _all: Array[Node] = []
var _was: Array[Node] = []


## Lists the looping emitters under `root` (call again after adding one later).
func cache(root: Node) -> void:
	_all.clear()
	_scan(root)


## Number of cached looping emitters.
func count() -> int:
	return _all.size()


func _scan(n: Node) -> void:
	for c: Node in n.get_children():
		if &"offscreen_freeze" in c:
			continue
		var looping := false
		if c is GPUParticles3D:
			looping = not (c as GPUParticles3D).one_shot
		elif c is CPUParticles3D:
			looping = not (c as CPUParticles3D).one_shot
		if looping and c.get_script() == null:
			_all.append(c)
		_scan(c)


## Off-screen (true): stops every cached emitter that is emitting and remembers it. On screen (false): restarts those.
func pause(off: bool) -> void:
	if off == paused:
		return
	paused = off
	if off:
		_was.clear()
		for n: Node in _all:
			if is_instance_valid(n) and bool(n.get(&"emitting")):
				n.set(&"emitting", false)
				_was.append(n)
	else:
		for n: Node in _was:
			if is_instance_valid(n):
				n.set(&"emitting", true)
		_was.clear()


## A model's own on / off of one emitter (death, revive, class change, gait...). On screen (or an emitter the pause
## does not drive) it sets `emitting`; while paused it only edits the set restored on screen, so nothing turns on
## off-screen and nothing switched off meanwhile comes back. Models call it through their set_fx_emitting().
func set_emitting(p: Node, on: bool) -> void:
	if p == null or not is_instance_valid(p):
		return
	if not paused or not _all.has(p):
		p.set(&"emitting", on)
	elif on:
		if not _was.has(p):
			_was.append(p)
	else:
		_was.erase(p)


## The model died: nothing paused comes back on screen (the death / revive code switches what it needs).
func clear_restore() -> void:
	_was.clear()


## Distance-tier switch of a tier-driven emitter list (see the header).
func tier_set(list: Array[GPUParticles3D], on: bool) -> void:
	for p: GPUParticles3D in list:
		if not is_instance_valid(p):
			continue
		if not paused:
			p.emitting = on
		elif on:
			if not _was.has(p):
				_was.append(p)
		else:
			_was.erase(p)


## For a model root that only holds other model roots (rider + mount scenes): passes Unit's `offscreen_freeze` on to
## every direct child that has one (scene children exist right after instantiate, before Unit adds the model).
static func forward_freeze(root: Node, on: bool) -> void:
	for c: Node in root.get_children():
		if &"offscreen_freeze" in c:
			c.set(&"offscreen_freeze", on)


## True when `n` is outside the root viewport camera's view by more than OFFSCREEN_MARGIN m x its scale.
static func outside_view(n: Node3D) -> bool:
	if not n.is_inside_tree():
		return false
	var vp := n.get_viewport()
	if vp == null or vp != n.get_tree().root:
		return false
	var f := Engine.get_process_frames()
	if f != _fr_frame:
		_fr_frame = f
		var cam := vp.get_camera_3d()
		if cam != null:
			_fr_planes.assign(cam.get_frustum())
		else:
			_fr_planes.clear()
	var p := n.global_position
	# Review 2026-10-10 #9: a big model (Hollow King x 2.2, colossi) casts a long shadow into the view: the margin grows
	# with its scale.
	var margin := OFFSCREEN_MARGIN * maxf(1.0, absf(n.global_basis.get_scale().y))
	for pl: Plane in _fr_planes:
		if pl.distance_to(p) > margin:
			return true
	return false
