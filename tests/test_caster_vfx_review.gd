extends SceneTree
## Code-review fixes of the four caster VFX families (art/vfx/caster_fire_vfx.gd, caster_ice_vfx.gd,
## caster_nature_vfx.gd, caster_shadow_vfx.gd):
##   - the Slag Rain landing / shock rings still spawn while many units are slagged (own ring pools);
##   - _process is off while a family is idle, on while an effect runs, off again after it ends;
##   - scrying_rune_end ends the right rune (node match first, skips fading runes, oldest on a tie);
##   - a Rime Bulwark that follows a body starts melting when that body is freed;
##   - a snagroot whose victim is freed keeps its last real position (no jump);
##   - instance uniforms are cached (the wall's last sent `rise`).
## Run:  godot --headless --path . -s tests/test_caster_vfx_review.gd --fixed-fps 60 --quit-after 3000
## Prints "PASS caster_vfx_review" or "FAIL caster_vfx_review: <reasons>".

const TASK_ID := "caster_vfx_review"
const FIRE := "res://art/vfx/caster_fire_vfx.gd"
const ICE := "res://art/vfx/caster_ice_vfx.gd"
const NATURE := "res://art/vfx/caster_nature_vfx.gd"
const SHADOW := "res://art/vfx/caster_shadow_vfx.gd"

var _fails: Array[String] = []
var _world: Node3D


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, why: String) -> void:
	if not ok:
		_fails.append(why)
		print("  check failed: ", why)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


## Waits (max `limit` s) until the family has nothing running and has switched _process off.
func _until_idle(fam: Node, limit: float) -> bool:
	var t := 0.0
	while t < limit:
		if int(fam.call(&"active_count")) == 0 and not fam.is_processing():
			return true
		await process_frame
		t += 1.0 / 60.0
	return false


func _family(path: String) -> Node3D:
	var fam: Node3D = (load(path) as GDScript).new()
	_world.add_child(fam)
	return fam


func _run() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	var cam := Camera3D.new()
	_world.add_child(cam)
	cam.position = Vector3(0, 30, 30)
	var fire := _family(FIRE)
	var ice := _family(ICE)
	var nature := _family(NATURE)
	var shadow := _family(SHADOW)
	await _frames(2)

	# 1. Idle families do not process.
	for fam: Node in [fire, ice, nature, shadow]:
		_check(not fam.is_processing(), "%s processes while idle after _ready" % fam.get_script().resource_path.get_file())

	# 2. Each family wakes on a start and sleeps again once everything ended.
	fire.call(&"play", &"mana_scald", Vector3(0, 0, 0), Vector3(3, 0, 0))
	ice.call(&"play", &"scrying_rune", Vector3(60, 0, 0), {"team": 0, "time": 1.0})
	nature.call(&"play", &"hazed", Vector3(0, 1, 5), 0.2)
	shadow.call(&"play", &"passage_step", Vector3(0, 0, 8))
	for fam: Node in [fire, ice, nature, shadow]:
		_check(fam.is_processing(), "%s not processing with an active effect" % fam.get_script().resource_path.get_file())
	for fam: Node in [fire, ice, nature, shadow]:
		var idle: bool = await _until_idle(fam, 5.0)
		_check(idle, "%s still processing / active after its effect ended (active %d)" % [
				fam.get_script().resource_path.get_file(), int(fam.call(&"active_count"))])
	# a second start after sleeping wakes it again
	shadow.call(&"play", &"passage_step", Vector3(2, 0, 8))
	_check(shadow.is_processing(), "shadow family did not wake on a second start")

	# 3. Fire: 30 slagged units do not starve the Slag Rain landing / shock rings.
	var units: Array[Node3D] = []
	for i in 30:
		var u := Node3D.new()
		_world.add_child(u)
		u.position = Vector3(-20.0 + float(i % 6) * 2.0, 0.0, -20.0 + float(i / 6) * 2.0)
		units.append(u)
		fire.call(&"play", &"slagged", u, 10.0)
	_check(int(fire.call(&"slagged_count")) == 30, "slagged_count %d, want 30" % int(fire.call(&"slagged_count")))
	for k in 3:   # three rains in a row on top of that
		fire.call(&"play", &"slag_rain", Vector3(10.0 + 8.0 * float(k), 0, 10), Vector3(10.0 + 8.0 * float(k), 2, 4))
	var rains := 0
	for fx: Variant in fire.get(&"_fx"):
		if fx.id != &"slag_rain":
			continue
		rains += 1
		var warn := 0
		var cracks := 0
		for d: Variant in fx.pieces:
			if d.pool == &"warn":
				warn += 1
			elif d.pool == &"ring":
				cracks += 1
		_check(warn == 2, "a slag_rain got %d landing / shock rings, want 2 (pool starved)" % warn)
		_check(cracks == 1, "a slag_rain got %d cooling-crack rings, want 1" % cracks)
	_check(rains == 3, "%d slag_rain effects running, want 3" % rains)
	await _frames(20)
	var warn_seen := false
	for g: Node in (fire.get(&"_all") as Dictionary)[&"warn"]:
		if (g as GeometryInstance3D).visible:
			warn_seen = true
	_check(warn_seen, "no landing warning ring visible during the flight with 30 slagged units")
	# slagging the same unit again refreshes it (one look per unit)
	fire.call(&"play", &"slagged", units[0], 10.0)
	_check(int(fire.call(&"slagged_count")) == 30, "re-slagging a unit added a second look")

	# 4. Ice: scrying_rune_end ends the right rune.
	var r1 := Vector3(100, 0, 0)
	ice.call(&"play", &"scrying_rune", r1, 0)                       # A (oldest)
	ice.call(&"play", &"scrying_rune", r1 + Vector3(0.5, 0, 0), 0)  # B
	ice.call(&"play", &"scrying_rune", Vector3(110, 0, 0), 0)      # C (tie, older)
	ice.call(&"play", &"scrying_rune", Vector3(110, 0, 0), 0)      # D (tie, newer)
	var anchor := Node3D.new()
	_world.add_child(anchor)
	anchor.position = Vector3(120, 0, 0)
	ice.call(&"play", &"scrying_rune", Vector3(120, 0, 0), 0)      # E (point, older)
	ice.call(&"play", &"scrying_rune", anchor, 0)                  # F (follows the anchor)
	var runes := _runes(ice)
	_check(runes.size() == 6, "%d runes running, want 6" % runes.size())
	if runes.size() == 6:
		ice.call(&"play", &"scrying_rune_end", r1 + Vector3(0.5, 0, 0))
		_check(runes[1].ending != &"" and runes[0].ending == &"", "end at B's spot did not end B alone")
		ice.call(&"play", &"scrying_rune_end", r1 + Vector3(0.5, 0, 0))
		_check(runes[0].ending != &"", "a second end at that spot hit the fading B instead of A")
		ice.call(&"play", &"scrying_rune_end", Vector3(110, 0, 0))
		_check(runes[2].ending != &"" and runes[3].ending == &"", "on a tie the oldest rune did not end first")
		ice.call(&"play", &"scrying_rune_end", anchor)
		_check(runes[5].ending != &"" and runes[4].ending == &"", "end by node did not end the rune following it")
		var n_before := int(ice.call(&"active_count"))
		ice.call(&"play", &"scrying_rune_end", r1)   # A and B both fading: nothing new
		_check(int(ice.call(&"active_count")) == n_before, "an end on fading runes spawned a loose end effect")

	# 5. Ice: a wall following a body melts once the body is freed.
	var body := Node3D.new()
	_world.add_child(body)
	body.position = Vector3(140, 0, 0)
	ice.call(&"play", &"rime_bulwark", body, {"time": 8.0})
	_check(int(ice.call(&"wall_count")) == 1, "the wall did not start")
	await _frames(40)
	_check(int(ice.call(&"wall_count")) == 1, "the wall melted while its body still stood")
	var wall_fx: Variant = null
	for fx: Variant in ice.get(&"_fx"):
		if fx.id == &"rime_bulwark":
			wall_fx = fx
	if wall_fx and wall_fx.wall:
		_check(is_equal_approx(float(wall_fx.wall.last.get(&"rise", -1.0)), 1.0), "the wall's cached `rise` is not 1")
	body.queue_free()
	await _frames(3)
	_check(int(ice.call(&"wall_count")) == 0, "the wall still stands after its body was freed")
	if wall_fx:
		_check(wall_fx.ending == &"melt", "the wall ends with '%s', want melt" % wall_fx.ending)
	await _frames(50)
	var walls_left := 0
	for fx: Variant in ice.get(&"_fx"):
		if fx.id == &"rime_bulwark":
			walls_left += 1
	_check(walls_left == 0, "the melted wall is still running after 0.8 s")

	# 6. Nature: a snagroot victim freed mid-drag leaves the vine at its last real spot.
	var victim := Node3D.new()
	_world.add_child(victim)
	victim.position = Vector3(160, 0, 0)
	nature.call(&"play", &"snagroot", Vector3(150, 1.2, 0), victim)
	await _frames(20)
	victim.position = Vector3(157, 0, 0)
	await _frames(2)
	var last_spot := victim.global_position
	victim.queue_free()
	await _frames(6)
	for fx: Variant in nature.get(&"_fx"):
		if fx.id == &"snagroot":
			_check((fx.tpos as Vector3).distance_to(last_spot) < 0.01, "snagroot tpos jumped to %s after the victim was freed (last %s)" % [
					fx.tpos, last_spot])

	_world.queue_free()
	await _frames(2)
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()


func _runes(ice: Node) -> Array:
	var out: Array = []
	for fx: Variant in ice.get(&"_fx"):
		if fx.id == &"scrying_rune":
			out.append(fx)
	return out
