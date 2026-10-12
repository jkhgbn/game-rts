extends SceneTree
## Bug E1 (bot-review-2026-10-12, shadow_fire_2026-10-12 report 2d / item 8): projectile spells (Fireball,
## Shadow Lance, Rime Bolt) take the Blitz spell factor (PaceSwitch.spell_damage_x) like SpellCaster.deal_damage.
## Two phases on mission 1's map, Normal then Blitz (PaceSwitch.setup(lvl, false, true) as in test_blitz):
## - Fireball on a worker = raw x worker_spell_x; on a soldier = raw x the fire factor (1.0 today);
##   the Blitz Fireball data edit (x0.75) still applies (raw read at cast time).
## - Shadow Lance on a worker = raw x worker_spell_x (x the shadow factor).
## - An arrow (plain Projectile, is_spell false) on a worker deals the same in both phases.
## - Normal: Fireball deals exactly its rank-1 damage (60) x armor.
## Run: tools/godot_run.ps1 --headless --path . -s tests/test_botfix_projectile.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "botfix_projectile"
const TIMEOUT_FRAMES := 2400
const BASE := Vector3(-20.0, 0.0, 20.0)
const WAIT_FRAMES := 150
const ARROW_DAMAGE := 10.0

var main: Node
var frame := 0
var _wait := 0
var errors: Array[String] = []
var done := false

var phase := 0   # 0 normal, 1 Blitz
var phase_frame := 0
var _lvl: Node
var _spawned: Array[Node] = []
var _taken: Dictionary = {}   # Unit -> damage taken (after armor)
var _cases: Array = []   # [unit, raw, factor, label]
var _arrow_dealt: Array[float] = []
var _fb_raw_normal := 0.0


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	_step()
	if not errors.is_empty():
		print("FAIL %s: %s (phase %d)" % [TASK_ID, " | ".join(errors), phase])
		_cleanup_blitz()
		return true
	if done:
		print("PASS %s" % TASK_ID)
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out in phase %d" % [TASK_ID, phase])
		_cleanup_blitz()
		return true
	return false


func _check(ok: bool, msg: String) -> void:
	if not ok:
		errors.append(msg)


func _near(a: float, b: float, msg: String, tol: float = 0.01) -> void:
	_check(absf(a - b) <= tol, "%s: got %.3f, want %.3f" % [msg, a, b])


func _cleanup_blitz() -> void:
	if _lvl != null and is_instance_valid(_lvl):
		_lvl.free()
		_lvl = null


func _step() -> void:
	phase_frame += 1
	if phase_frame == 1:
		if phase == 1:
			_lvl = Node.new()
			root.add_child(_lvl)
			_check(PaceSwitch.setup(_lvl, false, true) != null and PaceSwitch.is_blitz(), "Blitz did not apply")
			_check(PaceSwitch.spell_mods_on and PaceSwitch.worker_spell_x < 1.0, "Blitz worker spell factor not on")
		_start_phase()
		return
	if phase_frame < WAIT_FRAMES:
		return
	_check_phase()
	for n in _spawned:
		if is_instance_valid(n):
			n.queue_free()
	_spawned.clear()
	_taken.clear()
	_cases.clear()
	if phase == 1:
		_cleanup_blitz()
		_check(not PaceSwitch.spell_mods_on and is_equal_approx(PaceSwitch.worker_spell_x, 1.0), "Blitz factors not restored")
		_near(SpellType.find(&"fireball").damage_at(1), _fb_raw_normal, "Fireball not restored after Blitz")
		_near(_arrow_dealt[0], _arrow_dealt[1], "arrow damage changed in Blitz")
		done = true
		return
	phase += 1
	phase_frame = 0


func _spawn(type_id: String, team: int, pos: Vector3) -> Unit:
	var u: Unit = main.make_unit(type_id)
	u.team = team
	u.attack_damage = 0.0
	u.aggro_range = 0.0
	main.add_child(u)
	u.global_position = pos
	u.command_hold()
	u.add_modifier(&"test_botfix", {"max_hp": 1000.0})   # workers have 50 HP: a Fireball must not kill
	u.heal(10000.0)
	_spawned.append(u)
	_taken[u] = 0.0
	u.damage_taken.connect(func(amount: float, _attacker: Node3D) -> void: _taken[u] = float(_taken[u]) + amount)
	return u


func _make_wizard(kingdom: StringName, pos: Vector3, ids: Array[StringName]) -> Array:
	var w := Wizard.new()
	w.team = Unit.Team.PLAYER
	w.kingdom = kingdom
	w.attack_damage = 0.0
	w.aggro_range = 0.0
	main.add_child(w)
	w.global_position = pos
	w.command_stop()
	var c: Node = w.get_node_or_null(^"SpellCaster")
	if c == null:
		c = load("res://scripts/spells/spell_caster.gd").new()
		c.name = "SpellCaster"
		w.add_child(c)
	c.call(&"setup", w, ids)
	c.call(&"set_rank", ids[0], 1)
	w.mana = w.max_mana
	_spawned.append(w)
	return [w, c]


func _factor(kingdom: String, worker: bool) -> float:
	var x := PaceSwitch.worker_spell_x if worker else 1.0
	return x * float(PaceSwitch.spell_x_by_kingdom.get(kingdom, 1.0))


func _start_phase() -> void:
	var fb := SpellType.find(&"fireball")
	var sl := SpellType.find(&"shadow_lance")
	_check(fb != null and sl != null, "missing SpellType")
	if not errors.is_empty():
		return
	if phase == 0:
		_fb_raw_normal = fb.damage_at(1)
		_near(_fb_raw_normal, 60.0, "Normal Fireball rank 1")
	else:
		_near(fb.damage_at(1), _fb_raw_normal * float(PaceSwitch.BLITZ["spell_type_x"].get("fireball", 1.0)),
				"Blitz Fireball data edit")
	# Fireball on a worker.
	var worker := _spawn("cinder_hand", Unit.Team.ENEMY, BASE)
	var r: Array = _make_wizard(&"fire", BASE + Vector3(0.0, 0.0, 8.0), [&"fireball"])
	var raw := float(r[1].call(&"spell_damage", fb, 1))
	_check(String(r[1].call(&"cast", &"fireball", worker.global_position)) == "", "fireball on worker refused")
	_cases.append([worker, raw, _factor("fire", true), "Fireball on a worker"])
	# Fireball on a soldier.
	var soldier := _spawn("flame_guard", Unit.Team.ENEMY, BASE + Vector3(-14.0, 0.0, 0.0))
	r = _make_wizard(&"fire", BASE + Vector3(-14.0, 0.0, 8.0), [&"fireball"])
	raw = float(r[1].call(&"spell_damage", fb, 1))
	_check(String(r[1].call(&"cast", &"fireball", soldier.global_position)) == "", "fireball on soldier refused")
	_cases.append([soldier, raw, _factor("fire", false), "Fireball on a soldier"])
	# Shadow Lance on a worker.
	var w3 := _spawn("gloom_thrall", Unit.Team.ENEMY, BASE + Vector3(14.0, 0.0, 0.0))
	r = _make_wizard(&"shadow", BASE + Vector3(14.0, 0.0, 6.0), [&"shadow_lance"])
	raw = float(r[1].call(&"spell_damage", sl, 1))
	_check(String(r[1].call(&"cast", &"shadow_lance", w3)) == "", "lance on worker refused")
	_cases.append([w3, raw, _factor("shadow", true), "Shadow Lance on a worker"])
	# A plain arrow (not a spell) on a worker.
	var archer := _spawn("ember_archer", Unit.Team.PLAYER, BASE + Vector3(28.0, 0.0, 8.0))
	var w2 := _spawn("cinder_hand", Unit.Team.ENEMY, BASE + Vector3(28.0, 0.0, 0.0))
	var arrow := Projectile.new()
	main.add_child(arrow)
	arrow.launch_at_target(archer, archer.global_position + Vector3.UP, w2, ARROW_DAMAGE, Color.WHITE, 0.1)
	_check(not arrow.is_spell, "an arrow reads as a spell")
	_cases.append([w2, ARROW_DAMAGE, 1.0, "arrow on a worker"])


func _check_phase() -> void:
	if phase == 1:
		_check(PaceSwitch.worker_spell_x < 1.0, "Blitz worker factor gone before the check")
	for c: Array in _cases:
		var u: Unit = c[0]
		var want := float(c[1]) * float(c[2]) * Unit.armor_multiplier(u.get_stat(&"armor"))
		_near(float(_taken[u]), want, "%s (%s)" % [c[3], "Blitz" if phase == 1 else "Normal"], 0.05)
		if String(c[3]) == "arrow on a worker":
			_arrow_dealt.append(float(_taken[u]))
