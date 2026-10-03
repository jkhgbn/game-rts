extends SceneTree
## Face review fixes (docs/reviews/review-art-faces.md H1, M1, M2, M3, L3, L4):
## - H1: after a level-up the face smiles ~1.6 s, then an attack shows the fierce face again (it smiled for good).
##   Checked on a FaceRig unit (Ember Archer), a CreatureFaceRig beast (direwolf) and after a revive.
## - M1: the face node is a hit-flash target (hit_flash > 0 on the FaceRig right after play_hit).
## - M2: the face has a visibility range end (not drawn at tier 2).
## - M3: FacePrewarm warms a kingdom; the first spawn after it is as cheap as a second instance (prints the numbers).
## - L3: FaceKit._dens is back to DENSITY after a build.
## - L4: the kit API FaceRig reads exists (face_tier / face_mood / level_up_age) and CreatureFaceRig's fallback fields
##   are real CharacterModel members (a rename fails here instead of silently).
## Run: godot --headless --path . -s tests/test_face_review.gd --fixed-fps 60 --quit-after 4000

const TASK_ID := "face_review"
const ARCHER := "res://art/units/fire/ember_archer.tscn"
const WOLF := "res://art/units/neutral/beasts/direwolf/direwolf.tscn"
const PREWARM_KINGDOM := &"shadow"

var _cam: Camera3D
var _archer: CharacterModel
var _wolf: CharacterModel
var _frame := 0
var _step := 0
var _mark := 0
var _fails: PackedStringArray = []


func _initialize() -> void:
	pass


func _spawn() -> void:   # frame 1: the root is inside the tree (not yet in _initialize)
	var w := Node3D.new()
	root.add_child(w)
	_cam = Camera3D.new()
	w.add_child(_cam)
	_cam.position = Vector3(0, 1.4, 4.0)
	_cam.make_current()
	_archer = (load(ARCHER) as PackedScene).instantiate() as CharacterModel
	w.add_child(_archer)
	_wolf = (load(WOLF) as PackedScene).instantiate() as CharacterModel
	_wolf.position = Vector3(1.5, 0, 0)
	w.add_child(_wolf)
	_static_checks()


func _face_of(m: Node) -> FaceRig:
	var f: Variant = m.get(&"_face")
	return f as FaceRig


func _static_checks() -> void:
	# L4: typed API + fallback field names
	for meth: StringName in [&"face_tier", &"face_mood", &"level_up_age"]:
		if not _archer.has_method(meth):
			_fails.append("CharacterModel has no %s()" % meth)
	var names := {}
	for p: Dictionary in _archer.get_property_list():
		names[p["name"]] = true
	for f: String in ["_tier", "_action", "_cast_id", "_dead", "_level_t", "_t", "_flash_hit_targets"]:
		if not names.has(f):
			_fails.append("CharacterModel field %s renamed (FaceRig / CreatureFaceRig read it)" % f)
	var face := _face_of(_archer)
	if face == null:
		_fails.append("ember archer has no FaceRig")
		return
	# M1
	if not _archer.get(&"_flash_hit_targets").has(face):
		_fails.append("FaceRig not in _flash_hit_targets")
	# M2
	if absf(face.visibility_range_end - FaceRig.FACE_RANGE_END) > 0.01:
		_fails.append("FaceRig visibility_range_end %.1f" % face.visibility_range_end)
	# L3
	if absf(FaceKit._dens - FaceKit.DENSITY) > 0.0001:
		_fails.append("FaceKit._dens left at %.2f after a build" % FaceKit._dens)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_spawn()
		return false
	if _frame > 3000:
		_fails.append("timed out at step %d" % _step)
		return _finish()
	var face := _face_of(_archer)
	var wf := _face_of(_wolf)
	if face == null:
		return _finish()
	match _step:
		0:
			if _frame >= 40:   # the tier timer has run (camera 4 m away = tier 0)
				if _archer.face_tier() != 0:
					_fails.append("archer not at tier 0 (%d)" % _archer.face_tier())
				_archer.play_level_up()
				_wolf.play_level_up()
				_mark = _frame
				_step = 1
		1:
			if _frame - _mark == 20:
				if face.shown_expression() != &"smile":
					_fails.append("no smile right after the level-up (%s)" % face.shown_expression())
				if wf and wf.shown_expression() != &"smile":
					_fails.append("wolf: no smile right after the level-up (%s)" % wf.shown_expression())
			if _frame - _mark >= 130:   # > SMILE_LEN (1.6 s) at 60 fps
				_archer.play_attack()
				_wolf.play_attack()
				_mark = _frame
				_step = 2
		2:
			if _frame - _mark == 4:
				if face.shown_expression() != &"fierce":
					_fails.append("H1: attack after a level-up shows %s, not fierce" % face.shown_expression())
				if wf and wf.shown_expression() != &"fierce":
					_fails.append("H1 (CreatureFaceRig): wolf attack shows %s, not fierce" % wf.shown_expression())
				_archer.play_hit()
				_mark = _frame
				_step = 3
		3:
			if _frame - _mark == 2:
				var hf: Variant = face.get_instance_shader_parameter(&"hit_flash")
				if hf == null or float(hf) <= 0.0:
					_fails.append("M1: the face does not flash on a hit (%s)" % str(hf))
			if _frame - _mark >= 90:
				# revive resets the level-up age
				_archer.play_level_up()
				_archer.play_death()
				_archer.revive()
				if _archer.level_up_age() < 50.0:
					_fails.append("revive kept the level-up age (%.2f)" % _archer.level_up_age())
				_step = 4
		4:
			_prewarm_check()
			return _finish()
	return false


func _prewarm_check() -> void:
	var holder := Node3D.new()
	root.add_child(holder)
	var scenes := FacePrewarm.scenes_of(PREWARM_KINGDOM)
	if scenes.is_empty():
		_fails.append("FacePrewarm found no %s scenes" % PREWARM_KINGDOM)
		return
	var r := FacePrewarm.warm(holder, [PREWARM_KINGDOM])
	print("face_review: prewarm %s: %d types in %.1f ms (slowest %s %.1f ms)" % [PREWARM_KINGDOM, int(r["types"]),
		float(r["ms"]), String(r["slowest"][0]).get_file(), float(r["slowest"][1])])
	# after the prewarm, a spawn of the slowest type costs a warm instance
	var ps := load(String(r["slowest"][0])) as PackedScene
	var t0 := Time.get_ticks_usec()
	var n := ps.instantiate()
	holder.add_child(n)
	var ms := float(Time.get_ticks_usec() - t0) / 1000.0
	print("face_review: spawn after prewarm %.1f ms (cold was %.1f ms)" % [ms, float(r["slowest"][1])])
	if ms > float(r["slowest"][1]):
		_fails.append("M3: a spawn after the prewarm (%.1f ms) is not cheaper than cold (%.1f ms)" % [ms, float(r["slowest"][1])])
	var again := FacePrewarm.warm(holder, [PREWARM_KINGDOM])
	if int(again["types"]) != 0:
		_fails.append("FacePrewarm warmed %d types twice" % int(again["types"]))
	n.queue_free()


func _finish() -> bool:
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for f: String in _fails:
			print("  " + f)
		print("FAIL %s: %s" % [TASK_ID, _fails[0]])
	return true
