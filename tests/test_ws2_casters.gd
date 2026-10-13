extends SceneTree
## WS2.G1 (docs/design/wave-strike.md 14.1 / 14.6): CasterAbility.lane_mode. Two Wave Strike lane clashes, 10 v 10, each
## side one kingdom (Fire v Shadow, then Ice v Nature), spawned through a real LaneSpawner at both gates (no horns, no
## wizards) and marching with LaneMarch; every kingdom caster gets lane_mode = true (LaneSpawner's job later, WS2.C2).
## PASS when: each kingdom caster type casts >= 1 of its "on" spells, Umbral Passage / Scrying Rune 0 casts, pyre_adept,
## hexweaver, shardguard, briar_roc and nightblood_reaver abilities fire, a rime_seer shields and a bloomtender heals.
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_ws2_casters.gd --fixed-fps 60 --quit-after 12000 ['--' --verbose]
## Casters start with a full mana bar (the rules are under test, not the 50-mana start).

const TASK_ID := "ws2_casters"
const SCENE := "res://scenes/wave_strike.tscn"
const CLASH_FRAMES := 4800    ## 80 s of game per clash (march ~25 s + the fight)
const CLASHES := [
	# A thin Fire front and a Shadow melee mob: the mob reaches the Fire back line in clumps (Flame Burst, Slag Rain).
	[[&"flame_guard", &"flame_guard", &"sunforge_cataphract", &"ember_archer", &"ember_archer", &"cinder_arbalest",
		&"pyre_adept", &"pyre_adept", &"kilnwarden", &"kilnwarden"],
	[&"shade", &"shade", &"shade", &"shade", &"nightblood_reaver", &"nightblood_reaver", &"nightbolt",
		&"hexweaver", &"gloom_deacon", &"gloom_deacon"]],
	# Ice ranged-heavy and Nature rider-heavy: divers reach the Ice archers (Bulwark's dive guard, Hold the Line) and
	# the Ice archers clump (Pollen Haze).
	[[&"rimeshield", &"shardguard", &"shardcaster", &"shardcaster", &"shardcaster", &"shardcaster", &"hoarlight_magebow",
		&"rime_seer", &"rimecarver", &"rimecarver"],
	[&"bramblehorn", &"bramblehorn", &"stagrunner", &"stagrunner", &"stagrunner", &"briar_roc", &"wildwood_archer",
		&"bloomtender", &"bramblesage", &"bramblesage"]],
]
## Kingdom caster -> its "on" spells in the lane (14.1).
const ON_SPELLS := {
	&"kilnwarden": [&"slag_rain", &"mana_scald"], &"rimecarver": [&"rime_bulwark"],
	&"bramblesage": [&"snagroot", &"pollen_haze"], &"gloom_deacon": [&"blood_tithe"],
}
const OFF_SPELLS := [&"umbral_passage", &"scrying_rune"]
const ABILITY_UNITS := [&"pyre_adept", &"hexweaver", &"shardguard", &"briar_roc", &"nightblood_reaver"]

var level: Node
var clash := -1
var frame := 0
var spawners: Array = []
var hooked := {}            # unit instance id -> true
var tracked: Array = []     # [unit, type id] for the per-unit ability counters
var spell_casts := {}       # caster type id -> {spell id: count}
var ability_casts := {}     # unit type id -> max casts seen (summed over units)
var _per_unit := {}         # instance id -> last casts total seen
var support := {&"shield": 0, &"heal": 0}
var _wait := 0
var verbose := false    ## -- --verbose: a caster state line every 5 s


func _initialize() -> void:
	verbose = OS.get_cmdline_user_args().has("--verbose")
	_start_clash(0)


func _start_clash(i: int) -> void:
	clash = i
	frame = 0
	spawners.clear()
	level = (load(SCENE) as PackedScene).instantiate()
	var rules: Resource = (load("res://scripts/world/wave_strike/wave_strike_rules.gd") as Script).call(&"load_default")
	rules.set(&"horn_first", 100000.0)
	rules.set(&"time_limit", 0.0)
	level.set(&"rules", rules)
	level.set(&"autopilot_player", true)
	level.set(&"wizards_enabled", false)
	root.add_child(level)
	current_scene = level
	_wait = 0


func _process(delta: float) -> bool:
	if level.get(&"director") == null:
		_wait += 1
		if _wait > 3000:
			print("FAIL %s: the Wave Strike level never got ready" % TASK_ID)
			return true
		return false
	if spawners.is_empty():
		var rules: Resource = level.get(&"rules")
		for team in 2:
			var sp := LaneSpawner.new()
			var fwd := Vector3.RIGHT if team == 0 else Vector3.LEFT
			sp.setup(team, team, level.call(&"gate_position", team), fwd, level, rules)
			level.add_child(sp)
			var ids: Array[StringName] = []
			for id: StringName in CLASHES[clash][team]:
				ids.append(id)
			sp.queue_wave(ids)
			spawners.append(sp)
	frame += 1
	for sp: LaneSpawner in spawners:
		sp.tick(delta)
	_hook_new_units()
	_poll_counters()
	if verbose and frame % 300 == 0:
		_debug_dump()
	if frame >=CLASH_FRAMES or (frame > 600 and _clash_done()):
		print("ws2_casters: clash %d ended at frame %d" % [clash, frame])
		if clash + 1 < CLASHES.size():
			level.queue_free()
			hooked.clear()
			tracked.clear()
			_start_clash(clash + 1)
			return false
		return _verdict()
	return false


func _hook_new_units() -> void:
	for u: Unit in level.call(&"lane_units", -1):
		var key := u.get_instance_id()
		if hooked.has(key) or u.unit_type == null:
			continue
		hooked[key] = true
		var tid := u.unit_type.id
		var ab := CasterKit.ability_of(u)
		if ab != null:
			ab.lane_mode = true
			ab.add_mana(ab.max_mana())   # a full bar: the test proves the lane rules, not the mana timing
			ab.spell_cast.connect(_on_spell_cast.bind(tid))
		var sc := u.get_node_or_null(^"SupportCaster") as SupportCaster
		if sc != null:
			sc.support_cast.connect(_on_support_cast)
		if ABILITY_UNITS.has(tid):
			tracked.append([u, tid])


func _on_spell_cast(sid: StringName, tid: StringName) -> void:
	if not spell_casts.has(tid):
		spell_casts[tid] = {}
	var d: Dictionary = spell_casts[tid]
	d[sid] = int(d.get(sid, 0)) + 1


func _on_support_cast(_caster: Unit, _target: Unit, kind: StringName) -> void:
	support[kind] = int(support.get(kind, 0)) + 1


func _poll_counters() -> void:
	for pair: Array in tracked:
		var u: Variant = pair[0]
		if not is_instance_valid(u):
			continue
		var tid: StringName = pair[1]
		var n := 0
		var na := (u as Node).get_node_or_null(^"NewUnitAbility")
		if na != null:
			n += int(na.get(&"casts"))
		var t3 := (u as Node).get_node_or_null(^"T3Ability")
		if t3 != null:
			for k: Variant in (t3.get(&"casts") as Dictionary):
				n += int((t3.get(&"casts") as Dictionary)[k])
		var key := (u as Node).get_instance_id()
		var before := int(_per_unit.get(key, 0))
		if n > before:
			ability_casts[tid] = int(ability_casts.get(tid, 0)) + n - before
			_per_unit[key] = n


func _debug_dump() -> void:
	var line := "f%d:" % frame
	var all: Array[Unit] = level.call(&"lane_units", -1)
	for u: Unit in all:
		var ab := CasterKit.ability_of(u)
		if u.unit_type.id == &"pyre_adept":
			var inr := 0
			for o: Unit in all:
				if o.team != u.team and u.global_position.distance_to(o.global_position) <= 8.5:
					inr += 1
			line += " PYRE(hp%d in8=%d x%.0f)" % [int(u.hp), inr, u.global_position.x]
		if ab == null:
			continue
		var near := INF
		for o: Unit in all:
			if o.team != u.team:
				near = minf(near, u.global_position.distance_to(o.global_position))
		line += " %s(m%d hp%d d%.0f x%.0f)" % [u.unit_type.id, int(ab.mana), int(u.hp), near, u.global_position.x]
		for sid: StringName in ab.spell_ids():
			var t: Variant = ab.autocast_target(sid)
			line += "{%s t=%s r=%s}" % [sid, "-" if t == null else "Y", "" if t == null else ab.can_cast(sid, t)]
		line += "act=%s cast=%s ch=%s appr=%s gcd=%.1f" % [u.can_act(), ab.is_casting(), ab.is_channelling(), ab.is_approaching(), ab.gcd_left()]
		if u.unit_type.id == &"rimecarver":
			var dives := 0
			for o: Unit in all:
				if o.team != u.team and o.attack_range <= 3.0 and o.attack_target is Unit and is_instance_valid(o.attack_target):
					var v := o.attack_target as Unit
					if v.attack_range > 3.0 or CasterKit.is_caster_unit(v):
						dives += 1
						line += "[dive %s->%s d%.1f]" % [o.unit_type.id, v.unit_type.id, o.global_position.distance_to(v.global_position)]
			line += " spot=%s" % str(ab.dive_guard_spot())
	print(line)


func _clash_done() -> bool:
	var teams := {}
	for u: Unit in level.call(&"lane_units", -1):
		teams[int(u.team)] = true
	return teams.size() < 2


func _on_count(tid: StringName) -> int:
	var n := 0
	var d: Dictionary = spell_casts.get(tid, {})
	for sid: StringName in ON_SPELLS[tid]:
		n += int(d.get(sid, 0))
	return n


func _verdict() -> bool:
	print("ws2_casters: spells %s abilities %s support %s" % [str(spell_casts), str(ability_casts), str(support)])
	var fails: Array[String] = []
	for tid: StringName in ON_SPELLS:
		if _on_count(tid) < 1:
			fails.append("%s cast none of %s" % [tid, str(ON_SPELLS[tid])])
	for tid: Variant in spell_casts:
		for sid: StringName in OFF_SPELLS:
			if int((spell_casts[tid] as Dictionary).get(sid, 0)) > 0:
				fails.append("%s cast %s (off in the lane)" % [tid, sid])
	for tid: StringName in ABILITY_UNITS:
		if int(ability_casts.get(tid, 0)) < 1:
			fails.append("%s ability never fired" % tid)
	if int(support[&"shield"]) < 1:
		fails.append("no rime_seer shield")
	if int(support[&"heal"]) < 1:
		fails.append("no bloomtender heal")
	if fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(fails)])
	quit(0 if fails.is_empty() else 1)
	return true
