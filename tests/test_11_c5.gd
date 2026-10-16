extends SceneTree
## 11.C5: Champion glue for the 11.V1 class weapons. After set_champion_class the unit re-reads the model's
## attack_windup (Wizard staff 0.12, melee classes 0, the archetype's back with &""), the shot origin is the model's
## get_weapon_tip() with a class weapon (not the Mender's hidden censer), projectile colour / speed come from
## ChampionClass, the model's attack style follows. Each archetype x each class, then back to no class; a shot waiting
## for the old release frame is dropped; timed: an Oathwall Wizard's bolt waits ~0.12 s and leaves from the staff tip,
## a Mender with a spear hits in melee at once (no censer release delay, no bolts).
## Run: godot --headless --path . -s tests/test_11_c5.gd --fixed-fps 60 --quit-after 1200

const TASK_ID := "11.c5"
const FAR := Vector3(260.0, 0.0, -260.0)
const ARCHETYPES: Array[StringName] = [&"wayfinder", &"oathwall", &"coin_cutter", &"mender"]
const ARCH_WINDUP: Dictionary = {&"wayfinder": 0.15, &"oathwall": 0.0, &"coin_cutter": 0.0, &"mender": 0.14}
const ARCH_STYLE: Dictionary = {&"wayfinder": &"bow", &"oathwall": &"slam", &"coin_cutter": &"slash2", &"mender": &"staff"}
const CLASSES: Array[StringName] = [&"spear", &"sword_shield", &"two_hand", &"wizard"]
const CLASS_WINDUP: Dictionary = {&"spear": 0.0, &"sword_shield": 0.0, &"two_hand": 0.0, &"wizard": 0.12}
const CLASS_STYLE: Dictionary = {&"spear": &"spear_thrust", &"sword_shield": &"sword_slash", &"two_hand": &"great_cleave",
	&"wizard": &"staff_bolt"}
const WIZ_BOLT := Color(0.6, 0.75, 1.0)
const TIMED_END := 300

var main: Node3D
var frame := 0
var _boot := 0
var _errors: Array[String] = []

# timed
var _wiz: Champion
var _wiz_foe: Unit
var _wiz_bolts := 0
var _wiz_bolt_near_tip := 0
var _wiz_windup_seen := false
var _spear: Champion
var _spear_foe: Unit
var _spear_bolts := 0
var _spear_windup_seen := false
var _seen: Dictionary = {}


func _initialize() -> void:
	main = Node3D.new()
	main.name = "World"
	root.add_child(main)
	current_scene = main
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2000.0, 1.0, 2000.0)
	shape.shape = box
	shape.position.y = -0.5
	floor_body.add_child(shape)
	main.add_child(floor_body)


func _process(_delta: float) -> bool:
	_boot += 1
	if _boot < 3:
		return false
	frame += 1
	if frame == 1:
		_run_instant()
		_setup_timed()
	elif frame > 1 and frame < TIMED_END:
		_watch()
	elif frame == TIMED_END:
		_check_timed()
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		return true
	return false


func _check(ok: bool, what: String) -> void:
	if not ok:
		_errors.append(what)
		print("  FAILED: ", what)


func _near(a: float, b: float, eps: float = 0.001) -> bool:
	return absf(a - b) < eps


func _quiet(ch: Node) -> void:
	for child_name: String in ["Brain", "ChampionAbilities"]:
		var n := ch.get_node_or_null(child_name)
		if n:
			n.process_mode = Node.PROCESS_MODE_DISABLED


func _champion(id: StringName, pos: Vector3) -> Champion:
	var ch := ChampionType.find(id).create_champion(0)
	ch.team = Unit.Team.PLAYER
	main.add_child(ch)
	ch.global_position = pos
	ch.command_stop()
	_quiet(ch)
	return ch


func _unit(type_id: String, team: int, pos: Vector3) -> Unit:
	var u := UnitType.find(type_id).create_unit()
	u.team = team as Unit.Team
	main.add_child(u)
	u.global_position = pos
	u.command_stop()
	return u


func _model_of(ch: Champion) -> Node3D:
	return ch.get(&"_model") as Node3D


# ------------------------------------------------------------------ instant: each archetype x each class

func _run_instant() -> void:
	var i := 0
	for arch: StringName in ARCHETYPES:
		var ch := _champion(arch, FAR + Vector3(4.0 * i, 0.0, 0.0))
		i += 1
		var m := _model_of(ch)
		_check(m != null and m.has_method(&"set_weapon_class"), "%s has a class-weapon model" % arch)
		if m == null:
			continue
		_check_state(ch, arch, &"", "fresh")
		for cls: StringName in CLASSES:
			ch.set_champion_class(cls)
			_check_state(ch, arch, cls, "class")
			ch.set_champion_class(&"")
			_check_state(ch, arch, &"", "back from %s" % cls)
		# class to class, without the archetype in between
		ch.set_champion_class(&"wizard")
		_check_state(ch, arch, &"wizard", "archetype -> wizard")
		ch.set_champion_class(&"two_hand")
		_check_state(ch, arch, &"two_hand", "wizard -> two_hand")
		ch.set_champion_class(&"wizard")
		_check_state(ch, arch, &"wizard", "two_hand -> wizard")
		ch.set_champion_class(&"")
		_check_state(ch, arch, &"", "wizard -> none")
	_check_pending_shot_dropped()
	_check_class_before_tree()


func _check_state(ch: Champion, arch: StringName, cls: StringName, when: String) -> void:
	var tag := "%s %s (%s)" % [arch, cls if cls != &"" else &"none", when]
	var m := _model_of(ch)
	var want_windup: float = CLASS_WINDUP[cls] if cls != &"" else ARCH_WINDUP[arch]
	var got_windup := float(ch.get(&"_model_windup"))
	_check(ch.class_id() == cls, "%s: class_id %s" % [tag, ch.class_id()])
	_check(_near(got_windup, want_windup), "%s: unit windup %.3f (want %.2f)" % [tag, got_windup, want_windup])
	_check(_near(float(m.get(&"attack_windup")), want_windup), "%s: model windup %s" % [tag, m.get(&"attack_windup")])
	var want_style: StringName = CLASS_STYLE[cls] if cls != &"" else ARCH_STYLE[arch]
	_check(m.get(&"attack_style") == want_style, "%s: attack_style %s (want %s)" % [tag, m.get(&"attack_style"), want_style])
	_check(m.call(&"weapon_class") == cls, "%s: model weapon_class %s" % [tag, m.call(&"weapon_class")])
	# shot origin
	# (get_weapon_tip / get_beam_origin return Variants: null for "none" on some models, e.g. the Oathwall)
	var origin: Vector3 = ch.call(&"_shot_visual_origin")   # drawn start (the gameplay start is chest height)
	var tip: Variant = m.call(&"get_weapon_tip")
	var beam: Variant = m.call(&"get_beam_origin") if m.has_method(&"get_beam_origin") else null
	var def := ch.global_position + Vector3.UP * ch.body_height * 0.75
	if cls != &"":
		_check(tip is Vector3, "%s: model gives a weapon tip" % tag)
		if tip is Vector3:
			_check(origin.distance_to(tip) < 0.001, "%s: shot origin = weapon tip (%s vs %s)" % [tag, origin, tip])
			var local := origin - ch.global_position
			_check(local.y > 0.3 and local.y < 3.2 and Vector2(local.x, local.z).length() < 2.6,
					"%s: tip near the champion (%s)" % [tag, local])
			if cls == &"wizard" and beam is Vector3:
				_check((beam as Vector3).distance_to(tip) < 0.001, "%s: the model's beam origin is the staff tip too" % tag)
		elif beam is Vector3:
			_check(origin.distance_to(beam) < 0.001, "%s: no tip: shot origin = get_beam_origin" % tag)
		else:
			_check(origin.distance_to(def) < 0.001, "%s: no tip: shot origin = Unit default" % tag)
		if arch == &"mender":
			var censer: Variant = _censer_core(m)
			_check(censer is Vector3, "%s: censer core found" % tag)
			if censer is Vector3:
				_check(origin.distance_to(censer) > 0.05, "%s: shot origin not the hidden censer" % tag)
				if beam is Vector3:
					_check((beam as Vector3).distance_to(censer) > 0.05, "%s: beam origin not the hidden censer" % tag)
	else:
		_check(tip == null, "%s: no weapon tip without a class" % tag)
		if beam is Vector3:
			_check(origin.distance_to(beam) < 0.001, "%s: shot origin = get_beam_origin" % tag)
			if arch == &"mender":
				var core: Variant = _censer_core(m)
				_check(core is Vector3 and origin.distance_to(core) < 0.001, "%s: shot origin = the censer" % tag)
		else:
			_check(origin.distance_to(def) < 0.001, "%s: shot origin = Unit default" % tag)
	# projectile colour / speed, range, ranged flag (from ChampionClass / the archetype)
	var type := ch.champion_type
	if cls == &"":
		_check(_near(ch.projectile_speed, 0.0) and ch.projectile_color.is_equal_approx(type.projectile_color),
				"%s: archetype projectile (%s, %s)" % [tag, ch.projectile_speed, ch.projectile_color])
		_check(_near(ch.attack_range, type.attack_range), "%s: archetype range %s" % [tag, ch.attack_range])
		_check(ch.is_ranged() == (type.attack_range > 3.0), "%s: is_ranged from the archetype" % tag)
	else:
		var c := ChampionClass.find(cls)
		_check(_near(ch.attack_range, c.attack_range) and ch.is_ranged() == c.is_ranged, "%s: class range %s" % [tag, ch.attack_range])
		if c.is_ranged:
			_check(_near(ch.projectile_speed, c.projectile_speed) and ch.projectile_color.is_equal_approx(c.projectile_color),
					"%s: class projectile (%s, %s)" % [tag, ch.projectile_speed, ch.projectile_color])
			_check(c.projectile_color.is_equal_approx(WIZ_BOLT) and _near(c.projectile_speed, 26.0), "%s: wizard bolt data" % tag)
		else:
			_check(_near(ch.projectile_speed, 0.0) and ch.projectile_color.is_equal_approx(type.projectile_color),
					"%s: melee class keeps no bolt speed (%s)" % [tag, ch.projectile_speed])
	# Unit's attack branch: ranged with > 3 m (the melee classes strike, the Wizard shoots)
	_check((ch.attack_range > 3.0) == (cls == &"wizard" or (cls == &"" and type.attack_range > 3.0)),
			"%s: attack branch (range %s)" % [tag, ch.attack_range])


# World position of the Mender's censer core (the archetype release point), or null when the model has no censer.
func _censer_core(m: Node3D) -> Variant:
	var censer := m.get(&"_censer") as Node3D
	if censer == null or not censer.is_inside_tree():
		return null
	var consts: Dictionary = (m.get_script() as GDScript).get_script_constant_map()
	var kettle: Variant = consts.get("KETTLE_C", null)
	if not kettle is Vector3:
		return null
	return censer.global_transform * ((kettle as Vector3) + Vector3(0, 0.1, 0))


# A Wayfinder's drawn arrow (waiting for the 0.15 s release) is dropped when it takes a melee class.
func _check_pending_shot_dropped() -> void:
	var ch := _champion(&"wayfinder", FAR + Vector3(0, 0, 10))
	var foe := _unit("shade", 1, FAR + Vector3(0, 0, 16))
	ch.set(&"_shot_left", 0.1)
	ch.set(&"_shot_target", foe)
	ch.set_champion_class(&"spear")
	_check(float(ch.get(&"_shot_left")) < 0.0 and ch.get(&"_shot_target") == null, "waiting arrow dropped on a class swap")
	# the same class again: nothing changes, a waiting shot is kept (set_champion_class is idempotent)
	ch.set_champion_class(&"wizard")
	ch.set(&"_shot_left", 0.05)
	ch.set(&"_shot_target", foe)
	ch.set_champion_class(&"wizard")
	_check(_near(float(ch.get(&"_shot_left")), 0.05) and ch.get(&"_shot_target") == foe, "same class again keeps the shot")
	ch.set(&"_shot_left", -1.0)
	ch.set(&"_shot_target", null)
	foe.queue_free()


# A class set before the tree (save restore, campaign companion) gives the right windup once built.
func _check_class_before_tree() -> void:
	var mender := ChampionType.find(&"mender").create_champion(0)
	mender.set_champion_class(&"sword_shield")
	mender.team = Unit.Team.PLAYER
	main.add_child(mender)
	mender.global_position = FAR + Vector3(0, 0, 20)
	_quiet(mender)
	_check(_near(float(mender.get(&"_model_windup")), 0.0), "Mender given Sword and Shield before the tree: windup 0 (%s)"
			% mender.get(&"_model_windup"))
	var oath := ChampionType.find(&"oathwall").create_champion(0)
	oath.set_champion_class(&"wizard")
	oath.team = Unit.Team.PLAYER
	main.add_child(oath)
	oath.global_position = FAR + Vector3(4, 0, 20)
	_quiet(oath)
	_check(_near(float(oath.get(&"_model_windup")), 0.12), "Oathwall given Wizard before the tree: windup 0.12 (%s)"
			% oath.get(&"_model_windup"))
	var tip: Variant = _model_of(oath).call(&"get_weapon_tip")
	_check(tip is Vector3 and (oath.call(&"_shot_visual_origin") as Vector3).distance_to(tip) < 0.001,
			"Oathwall Wizard (before the tree): shot origin = staff tip")
	oath.set_champion_class(&"")
	_check(_near(float(oath.get(&"_model_windup")), 0.0), "Oathwall back to its slam: windup 0")


# ------------------------------------------------------------------ timed

func _setup_timed() -> void:
	var base := FAR + Vector3(-100, 0, 60)
	_wiz = _champion(&"oathwall", base)
	_wiz.set_champion_class(&"wizard")
	_wiz_foe = _unit("shade", 1, base + Vector3(6, 0, 0))
	_wiz_foe.max_hp = 100000.0
	_wiz_foe.hp = 100000.0
	_wiz_foe.command_hold()
	_wiz.command_attack(_wiz_foe)
	var base2 := FAR + Vector3(-100, 0, 120)
	_spear = _champion(&"mender", base2)
	_spear.set_champion_class(&"spear")
	_spear_foe = _unit("shade", 1, base2 + Vector3(1.8, 0, 0))
	_spear_foe.max_hp = 100000.0
	_spear_foe.hp = 100000.0
	_spear_foe.command_hold()
	_spear.command_attack(_spear_foe)


func _watch() -> void:
	if float(_wiz.get(&"_shot_left")) > 0.0:
		_wiz_windup_seen = true
	if float(_spear.get(&"_shot_left")) > 0.0:
		_spear_windup_seen = true
	for n in main.get_children():
		var p := n as Projectile
		if p == null or _seen.has(p.get_instance_id()):
			continue
		_seen[p.get_instance_id()] = true
		if p.source == _wiz:
			_wiz_bolts += 1
			var tip: Variant = _model_of(_wiz).call(&"get_weapon_tip")
			var start: Vector3 = (p.get(&"_start") as Vector3) + (p.get(&"_visual_offset") as Vector3)   # the drawn start
			if tip is Vector3 and start.distance_to(tip) < 0.4 and p.color.is_equal_approx(WIZ_BOLT):
				_wiz_bolt_near_tip += 1
		elif p.source == _spear:
			_spear_bolts += 1


func _check_timed() -> void:
	_check(_wiz_windup_seen, "Oathwall Wizard waits for the staff release (a shot pending with windup 0.12)")
	_check(_wiz_bolts > 0 and _wiz_bolt_near_tip == _wiz_bolts, "Oathwall Wizard bolts leave from the staff tip, blue (%d / %d)"
			% [_wiz_bolt_near_tip, _wiz_bolts])
	_check(_wiz_foe.hp < _wiz_foe.max_hp, "the Wizard's bolts hit (%s)" % _wiz_foe.hp)
	_check(not _spear_windup_seen and _spear_bolts == 0, "Spear Mender: no release delay, no bolts (%s, %d)"
			% [_spear_windup_seen, _spear_bolts])
	_check(_spear_foe.hp < _spear_foe.max_hp, "the Spear Mender hits in melee (%s)" % _spear_foe.hp)
