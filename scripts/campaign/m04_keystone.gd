class_name M04Keystone
extends Node
## Mission 4's boss fight (docs/design/mission-04.md "Keystone Pylon", "The boss", "Old Vey"; ep1 6 binding numbers),
## built mission-side like M00Cast: the four Keystone Pylons and their Ruin Wardens, the Keystone Colossus's three
## phases (Ward + Hurl; the walk to the Fire keep with Crush, Quake Stomp, Relic Pull, Rubble Call, Cracked Leg; Stone
## Skin, Hollow Pulse, Rubble Call and Turn the Key), and Old Vey's brain and kit (19.C11 / 19.A2: escort, Lightning
## Lunge, Chain Lightning, Charged Ground, Ground the Pulse, Stormcall, the 1 HP kneel). The mission (Mission04) owns
## this node (child of the level: it pauses with the tree for PAUSE cards) and listens to its signals for the story.
## Every timer stops while the mission holds the world.

signal pylon_destroyed(pylon: Unit, by_team: int)
signal exposed(count: int)                 ## Turn the Key worked: the Colossus is Exposed (count 1, 2, 3...).
signal key_reset                           ## A Hollow Pulse broke the key (Vey was not grounding it).
signal vey_down                            ## Vey reached 1 HP and kneels.
signal colossus_died
signal cracked_leg                         ## Phase 2: the Colossus fell to 70 %.

const PYLON_RADIUS := 1.0
const PYLON_WARDEN_EVERY := 35.0
## Back to the spec's 2 per 35 s / max 6 (pacing 2026-10-06): the 2026-10-04 cut (1 / max 4) was for a 15-20 soldier
## army starved by 1 500-crystal home nodes; with the 2 500 nodes the scripted army is 30+ and phase 1 lasted ~1 min.
const PYLON_WARDENS := 2
const PYLON_WARDEN_MAX := 6
const PYLON_WARDEN_RING := 4.0
const PYLON_WARDEN_AGGRO := 10.0
const HURL_RANGE := 30.0
const HURL_RADIUS := 3.5
const HURL_TELEGRAPH := 1.6
const HURL_EVERY := {1: 9.0, 2: 12.0, 3: 10.0}
const CRUSH_REACH := 3.0          ## Crush hits what stands this close to the Colossus's edge (radius 3).
const CRUSH_SPLASH := 2.0
const CRUSH_SPLASH_PCT := 0.5
const STOMP_EVERY := 11.0
const STOMP_RADIUS := 7.0
const STOMP_TELEGRAPH := 1.2
const STOMP_DAMAGE := 55.0
const STOMP_DAZE := 1.0
const PULL_EVERY := 20.0
const PULL_RANGE := 22.0
const RUBBLE_EVERY := {2: 30.0, 3: 20.0}
const RUBBLE_COUNT := {2: 3, 3: 4}
const RUBBLE_RING := 6.0
const CRACK_PCT := 0.7
const CRACK_SECONDS := 8.0
const PULSE_EVERY := 7.0
const PULSE_RADIUS := 5.0
const PULSE_DAMAGE := 40.0
const KEY_RANGE := 4.0            ## Vessa within this of the Colossus's edge...
const KEY_TIME := 3.0             ## ...for this long: Exposed...
const EXPOSED_SECONDS := 10.0     ## ...this long, then...
const KEY_COOLDOWN := 6.0         ## ...this long before the next turn.
const GROUND_RANGE := 8.0         ## Vey within this of Vessa grounds the Hollow Pulse.
const VEY_HP := 1600.0
const VEY_NEAR := 3.0
const VEY_FAR := 6.0
const VEY_LEASH := 9.0
const LUNGE_EVERY := 12.0
const TARGET_RETRY := 0.25   ## no Chain / Lunge target: the next unit scan comes this much later
const LUNGE_DAMAGE := 60.0
const LUNGE_SPLASH := 30.0
const CHAIN_EVERY := 8.0
const CHAIN_DAMAGE: Array[float] = [45.0, 38.0, 32.0, 27.0, 23.0]
const CHAIN_RANGE := 10.0
const CHARGED_RADIUS := 10.0
const CHARGED_DPS := 20.0
const STORM_BOLTS := 8
const STORM_DAMAGE := 60.0
const STORM_EXPOSED := 300.0
const STORM_RANGE := 14.0
const VEY_KNEEL := 10.0
const VEY_STAND_PCT := 0.5
const BRAIN_TICK := 0.25
const AMBER := Color(1.0, 0.75, 0.3)
const HURL_COLOR := Color(1.0, 0.35, 0.1, 0.45)
const BOLT_COLOR := Color(0.85, 0.9, 1.0)

## Difficulty tables [easy, normal, hard].
## Pacing (2026-10-06, 19.C5 scripted runs): the spec's 7 500 / 10 000 / 12 500 Colossus and 1 100 / 1 400 / 1 700
## pylons gave phases 1-3 of ~1:00 / 1:20 / 1:00 against the spec's 4:30-6:00 / 2:00-3:00 / 2:00-3:00 (the whole
## mission 13:30-17:40 of play for 22-28): x 1.2 Colossus HP (phase 3 starts at 40 % of it; x 1.4 left Vessa and Vey
## alone short of the last turn of the key in 3 of 4 runs), x 2 pylon HP (x 1.5 still gave a 3:30 phase 1).
const COLOSSUS_HP: Array[float] = [9000.0, 12000.0, 15000.0]
const HURL_DAMAGE: Array[float] = [55.0, 70.0, 85.0]
const CRUSH_DAMAGE := 60.0
const PYLON_HP: Array[float] = [2200.0, 2800.0, 3400.0]
const STORMCALL_EVERY: Array[float] = [45.0, 45.0, 60.0]

var mission: Node                 ## Mission04 (hero, keep, scaled(), order_wave(), _spawn(), world_is_held).
var difficulty := 1
var colossus: M04Colossus         ## Read only (null before the Rise).
var pylons: Array[Unit] = []      ## Read only: the four, in P1..P4 order (dead ones stay in the list).
var pylon_wardens: Dictionary = {}   ## Read only: pylon -> Array of its Wardens.
var free_wardens: Array = []      ## Read only: Rubble Call / ward-break Wardens (no leash).
var vey: Unit                     ## Read only (null before the darkest hour).
var walk_path: Array[Vector3] = []   ## The phase-2 path (the West Crown Bridge, then the lane).
var exposures := 0                ## Read only.
var key_progress := 0.0           ## Read only: 0-1 while Vessa turns the key.
var hurls := 0                    ## Read only (test hooks).
var stomps := 0
var pulls := 0
var pulses := 0
var pulses_grounded := 0
var rubble_calls := 0
var stormcalls := 0
var vey_kneeling := false         ## Read only.
var cracked := false              ## Read only: Cracked Leg fired.

var _warden_type: UnitType
var _free_warden_type: UnitType
var _pylon_type: UnitType
var _tethers: Dictionary = {}     # pylon -> MeshInstance3D
var _pylon_spawn_left: Dictionary = {}
var _walk_i := 0
var _hurl_left := 5.0
var _crush_left := 1.0
var _stomp_left := STOMP_EVERY
var _pull_left := PULL_EVERY * 0.5
var _rubble_left := 0.0
var _pulse_left := PULSE_EVERY
var _key_cool := 0.0
var _exposed_left := 0.0
var _brain_left := 0.0
var _lunge_left := 3.0
var _chain_left := 2.0
var _storm_left := 0.0
var _charged_tick := 0.0
var _kneel_left := 0.0
var _threats: Array = []         # [at, radius, until (msec)] of the rings on the ground (active_threats)
var _key_ring: MeshInstance3D
var _key_ring_mat: StandardMaterial3D
var _charged_ring: MeshInstance3D


func setup(m: Node, diff: int) -> void:
	mission = m
	difficulty = clampi(diff, 0, 2)
	var base := UnitType.find("ruin_warden")
	if base:
		_warden_type = base
		_free_warden_type = base.duplicate() as UnitType
		_free_warden_type.neutral_leash = false
		_pylon_type = base.duplicate() as UnitType
		_pylon_type.id = &"keystone_pylon"
		_pylon_type.display_name = "Keystone Pylon"
		_pylon_type.max_hp = PYLON_HP[difficulty]
		_pylon_type.armor = 20.0
		_pylon_type.move_speed = 0.0
		_pylon_type.attack_damage = 0.0
		_pylon_type.attack_range = 0.0
		_pylon_type.aggro_range = 0.0
		_pylon_type.radius = PYLON_RADIUS
		_pylon_type.body_height = 5.0
		_pylon_type.kill_xp = 0
		_pylon_type.neutral_leash = false
		_pylon_type.model_scene = M04Look.packed(&"pylon")
	_storm_left = 6.0


# ---------------------------------------------------------------- the Rise

## The Rise end state: the four pylons (P1..P4) and the Colossus at `at`, phase 1 (warded, tethered).
func rise(at: Vector3, pylon_spots: Array) -> void:
	for i in pylon_spots.size():
		var p := _spawn_unit(Worker.make_unit(_pylon_type), Unit.Team.NEUTRAL, pylon_spots[i])
		if p == null:
			continue
		p.name = "KeystonePylon%d" % (i + 1)
		p.add_to_group(&"pylons")
		p.set_meta(&"m4_no_hollow", true)
		p.attacks_blocked = true
		p.command_hold()
		p.died.connect(_on_pylon_died)
		pylons.append(p)
		pylon_wardens[p] = []
		_pylon_spawn_left[p] = 0.0   # the first pair at once
		_add_tether(p)
	colossus = M04Colossus.new()
	colossus.apply_type(M04Colossus.make_type(COLOSSUS_HP[difficulty], CRUSH_DAMAGE))
	colossus.name = "KeystoneColossus"
	_spawn_unit(colossus, Unit.Team.NEUTRAL, at)
	colossus.set_meta(&"m4_no_hollow", true)
	colossus.set_phase(1)
	colossus.set_warded(true)
	colossus.died.connect(func(_u: Unit) -> void: colossus_died.emit())
	_hurl_left = 6.0


func pylons_standing() -> int:
	var n := 0
	for p in pylons:
		if is_instance_valid(p) and p.is_alive():
			n += 1
	return n


func colossus_alive() -> bool:
	return colossus != null and is_instance_valid(colossus) and colossus.is_alive()


func colossus_hp_pct() -> float:
	return colossus.hp / maxf(1.0, colossus.max_hp) if colossus_alive() else 0.0


func _on_pylon_died(u: Unit) -> void:
	var by := -1
	if u.killer != null and is_instance_valid(u.killer) and u.killer.get(&"team") != null:
		by = int(u.killer.get(&"team"))
	var tether: Variant = _tethers.get(u)
	if tether != null and is_instance_valid(tether):
		var mi := tether as MeshInstance3D
		var tw := mi.create_tween()
		tw.tween_property(mi, "scale", Vector3(3.0, 1.0, 3.0), 0.25)
		tw.tween_property(mi, "scale", Vector3(0.01, 1.0, 0.01), 0.25)
		tw.tween_callback(mi.queue_free)
	_tethers.erase(u)
	if colossus_alive() and pylons_standing() == 0:
		colossus.set_warded(false)
	pylon_destroyed.emit(u, by)


## Phase 2 (the 4th pylon fell): the ward shatters; the pylon Wardens go for Vessa; the walk starts.
func start_walk(path: Array[Vector3]) -> void:
	walk_path = path
	_walk_i = 0
	colossus.set_warded(false)
	colossus.set_phase(2)
	colossus.set_base_stat(&"move_speed", 1.4)
	_hurl_left = 4.0
	_rubble_left = RUBBLE_EVERY[2]
	for p: Variant in pylon_wardens:
		for w: Variant in pylon_wardens[p]:
			if is_instance_valid(w) and (w as Unit).is_alive():
				_free_warden(w as Unit)
	pylon_wardens.clear()


## Phase 3 (the darkest hour's end state): kneel where it stands, HP = min(current, 40 %).
func start_kneel(hp_cap_pct: float) -> void:
	if not colossus_alive():
		return
	colossus.set_phase(3)
	colossus.cracked_left = 0.0
	colossus.hp = minf(colossus.hp, colossus.max_hp * hp_cap_pct)
	colossus.heal(0.0)   # refreshes the bar
	_hurl_left = 5.0
	_pulse_left = PULSE_EVERY
	_rubble_left = RUBBLE_EVERY[3]
	_key_cool = 0.0
	_build_key_ring()


# ---------------------------------------------------------------- tick

func _physics_process(delta: float) -> void:
	if mission == null or bool(mission.get(&"world_is_held")) or bool(mission.get(&"game_over")):
		return
	_tick_pylons(delta)
	if colossus_alive():
		match colossus.phase:
			1:
				_tick_hurl(delta)
			2:
				_tick_walk(delta)
				_tick_hurl(delta)
				_tick_crush(delta)
				_tick_stomp(delta)
				_tick_pull(delta)
				_tick_rubble(delta)
				if not cracked and colossus.hp <= colossus.max_hp * CRACK_PCT:
					cracked = true
					colossus.cracked_left = CRACK_SECONDS
					colossus.model_call(&"set_cracked", [true])
					cracked_leg.emit()
			3:
				_tick_hurl(delta)
				_tick_pulse(delta)
				_tick_rubble(delta)
				_tick_key(delta)
	if vey != null and is_instance_valid(vey):
		_tick_vey(delta)


func _tick_pylons(delta: float) -> void:
	for p: Variant in _pylon_spawn_left.keys():
		if not is_instance_valid(p) or not (p as Unit).is_alive():
			_pylon_spawn_left.erase(p)
			continue
		_pylon_spawn_left[p] = float(_pylon_spawn_left[p]) - delta
		if float(_pylon_spawn_left[p]) > 0.0:
			continue
		_pylon_spawn_left[p] = PYLON_WARDEN_EVERY
		var list: Array = (pylon_wardens.get(p, []) as Array).filter(func(w: Variant) -> bool:
			return is_instance_valid(w) and (w as Unit).is_alive())
		var cap := int(mission.call(&"scaled", PYLON_WARDEN_MAX))
		var n := mini(int(mission.call(&"scaled", PYLON_WARDENS)), cap - list.size())
		for i in n:
			var a := randf() * TAU
			var at: Vector3 = (p as Unit).global_position + Vector3(cos(a), 0.0, sin(a)) * PYLON_WARDEN_RING
			var w := _spawn_unit(Worker.make_unit(_warden_type), Unit.Team.NEUTRAL, at)
			if w:
				w.aggro_range = PYLON_WARDEN_AGGRO
				w.set_meta(&"m4_no_hollow", true)
				w.add_to_group(&"m4_wardens")
				list.append(w)
		pylon_wardens[p] = list


func _tick_walk(delta: float) -> void:
	if colossus.cracked_left > 0.0 or not colossus.can_act() or walk_path.is_empty():
		colossus.model_call(&"set_moving", [0.0])
		return
	var k: Node3D = mission.get(&"keep")
	if k != null and is_instance_valid(k) and k.call(&"is_alive"):
		var reach := float(k.call(&"target_radius")) + colossus.radius + CRUSH_REACH * 0.5
		if MissionBase._flat(colossus.global_position, k.global_position) <= reach:
			colossus.model_call(&"set_moving", [0.0])
			return
	if _walk_i >= walk_path.size():
		colossus.model_call(&"set_moving", [0.0])
		return
	var target := walk_path[_walk_i]
	var pos := colossus.global_position
	var to := Vector3(target.x - pos.x, 0.0, target.z - pos.z)
	var step := colossus.get_stat(&"move_speed") * delta
	if to.length() <= step:
		colossus.global_position = Vector3(target.x, 0.0, target.z)
		_walk_i += 1
	else:
		colossus.global_position = Vector3(pos.x, 0.0, pos.z) + to.normalized() * step
		colossus.face_direction(to)
	colossus.model_call(&"set_moving", [1.4])


## Crush (every 2.4 s): Vessa first, else the nearest PLAYER / ENEMY unit within reach, else a building (x 2);
## 50 % splash within 2 m.
func _tick_crush(delta: float) -> void:
	_crush_left -= delta
	if _crush_left > 0.0 or not colossus.can_act():
		return
	_crush_left = colossus.attack_cooldown
	var reach := colossus.radius + CRUSH_REACH
	var hero := _hero()
	var target: Node3D = null
	if hero and MissionBase._flat(hero.global_position, colossus.global_position) <= reach + hero.radius:
		target = hero
	if target == null:
		target = _nearest_fighter(colossus.global_position, reach)
	var dmg := colossus.get_stat(&"attack_damage")
	if target == null:
		for b in get_tree().get_nodes_in_group("buildings"):
			var bn := b as Node3D
			if bn == null or not bn.call(&"is_alive") or int(bn.get(&"team")) == Unit.Team.NEUTRAL:
				continue
			if MissionBase._flat(bn.global_position, colossus.global_position) <= reach + float(bn.call(&"target_radius")):
				target = bn
				dmg *= 2.0
				break
	if target == null:
		return
	colossus.face_direction(target.global_position - colossus.global_position)
	colossus.model_call(&"play_attack")
	target.call(&"take_damage", dmg, colossus)
	for u in _fighters_in(target.global_position, CRUSH_SPLASH):
		if u != target:
			u.take_damage(dmg * CRUSH_SPLASH_PCT, colossus)


## Keystone Hurl: the biggest PLAYER or ENEMY clump within 30 m (Vessa's clump wins ties), a 1.6 s ring, then damage.
func _tick_hurl(delta: float) -> void:
	_hurl_left -= delta
	if _hurl_left > 0.0 or not colossus.can_act():
		return
	_hurl_left = float(HURL_EVERY[colossus.phase])
	var at := _hurl_target()
	if at == Vector3.INF:
		_hurl_left = 2.0
		return
	hurls += 1
	colossus.face_direction(at - colossus.global_position)
	colossus.model_call(&"play_attack")
	var dmg: float = HURL_DAMAGE[difficulty]
	_telegraph(at, HURL_RADIUS, HURL_COLOR, HURL_TELEGRAPH, func() -> void:
		if not is_instance_valid(colossus):
			return
		for u in _fighters_in(at, HURL_RADIUS):
			u.take_damage(dmg, colossus)
		_burst(at, HURL_RADIUS, AMBER))


func _hurl_target() -> Vector3:
	var units := _fighters_in(colossus.global_position, HURL_RANGE)
	if units.is_empty():
		return Vector3.INF
	var hero := _hero()
	var best := Vector3.INF
	var best_n := -1
	for u in units:
		var n := 0
		for o in units:
			if int(o.team) == int(u.team) and MissionBase._flat(o.global_position, u.global_position) <= HURL_RADIUS:
				n += 1
		if n > best_n or (n == best_n and u == hero):
			best_n = n
			best = u.global_position
	return Vector3(best.x, 0.0, best.z)


func _tick_stomp(delta: float) -> void:
	_stomp_left -= delta
	if _stomp_left > 0.0 or not colossus.can_act():
		return
	if _fighters_in(colossus.global_position, STOMP_RADIUS).size() < 3:
		_stomp_left = 1.0
		return
	_stomp_left = STOMP_EVERY
	stomps += 1
	var at := colossus.global_position
	_telegraph(at, STOMP_RADIUS, Color(1.0, 0.6, 0.2, 0.35), STOMP_TELEGRAPH, func() -> void:
		if not is_instance_valid(colossus):
			return
		for u in _fighters_in(at, STOMP_RADIUS):
			u.take_damage(STOMP_DAMAGE, colossus)
			if u.is_alive():
				u.apply_status(&"dazed", STOMP_DAZE)
		_burst(at, STOMP_RADIUS, AMBER))


## Relic Pull: the relics drag Vessa toward the heart (Ember Step out of it is the answer).
func _tick_pull(delta: float) -> void:
	_pull_left -= delta
	var hero := _hero()
	if _pull_left > 0.0 or hero == null:
		return
	var d := MissionBase._flat(hero.global_position, colossus.global_position)
	if d > PULL_RANGE or d < colossus.radius + 3.0:
		_pull_left = 1.0
		return
	_pull_left = PULL_EVERY
	pulls += 1
	var dir := (hero.global_position - colossus.global_position)
	dir.y = 0.0
	var to := colossus.global_position + dir.normalized() * (colossus.radius + 2.0)
	hero.displace(to, 1.0)
	_beam(colossus.global_position + Vector3(0.0, 8.0, 0.0), hero.global_position + Vector3(0.0, 1.0, 0.0), AMBER, 1.0)


## Rubble Call: Ruin Wardens rise beside the Colossus and go for Vessa (phase 3: never inside Charged Ground).
func _tick_rubble(delta: float) -> void:
	_rubble_left -= delta
	if _rubble_left > 0.0:
		return
	var ph := colossus.phase
	_rubble_left = float(RUBBLE_EVERY[ph])
	rubble_calls += 1
	var n := int(mission.call(&"scaled", int(RUBBLE_COUNT[ph])))
	var made := 0
	var tries := 0
	while made < n and tries < n * 6:
		tries += 1
		var a := randf() * TAU
		var at := colossus.global_position + Vector3(cos(a), 0.0, sin(a)) * RUBBLE_RING
		if ph == 3 and vey_alive() and MissionBase._flat(at, vey.global_position) < CHARGED_RADIUS:
			continue
		var w := _spawn_unit(Worker.make_unit(_free_warden_type), Unit.Team.NEUTRAL, at)
		if w == null:
			break
		w.set_meta(&"m4_no_hollow", true)
		w.add_to_group(&"m4_wardens")
		free_wardens.append(w)
		mission.call(&"order_wave", w, &"hero", _hero_pos())
		made += 1


func _free_warden(w: Unit) -> void:
	w.aggro_range = PYLON_WARDEN_AGGRO
	free_wardens.append(w)
	mission.call(&"order_wave", w, &"hero", _hero_pos())


## Hollow Pulse (phase 3, every 7 s): 40 within 5 m; breaks Turn the Key unless Vey grounds it.
func _tick_pulse(delta: float) -> void:
	_pulse_left -= delta
	if _pulse_left > 0.0:
		return
	_pulse_left = PULSE_EVERY
	pulses += 1
	var grounded := grounding()
	if grounded:
		pulses_grounded += 1
	var at := colossus.global_position
	_burst(at, colossus.radius + PULSE_RADIUS, Color(1.0, 0.55, 0.15) if not grounded else BOLT_COLOR)
	for u in _fighters_in(at, colossus.radius + PULSE_RADIUS):
		u.take_damage(PULSE_DAMAGE, colossus)
	if not grounded and key_progress > 0.0:
		key_progress = 0.0
		key_reset.emit()


## True while Old Vey stands within 8 m of Vessa (Ground the Pulse).
func grounding() -> bool:
	var hero := _hero()
	return vey_alive() and not vey_kneeling and hero != null \
			and MissionBase._flat(vey.global_position, hero.global_position) <= GROUND_RANGE


## Turn the Key: Vessa within 4 m of the Colossus's edge for 3 s -> Exposed 10 s, then 6 s until the next turn.
func _tick_key(delta: float) -> void:
	if _exposed_left > 0.0:
		_exposed_left -= delta
		if _exposed_left <= 0.0:
			colossus.set_exposed(false)
			_key_cool = KEY_COOLDOWN
		_update_key_ring()
		return
	if _key_cool > 0.0:
		_key_cool -= delta
		_update_key_ring()
		return
	var hero := _hero()
	if hero != null and MissionBase._flat(hero.global_position, colossus.global_position) <= colossus.radius + KEY_RANGE:
		key_progress = minf(1.0, key_progress + delta / KEY_TIME)
		if key_progress >= 1.0:
			key_progress = 0.0
			exposures += 1
			_exposed_left = EXPOSED_SECONDS
			colossus.set_exposed(true)
			_burst(colossus.global_position, colossus.radius + 2.0, Color(1.0, 0.9, 0.6))
			exposed.emit(exposures)
	else:
		key_progress = 0.0
	_update_key_ring()


func exposed_time_left() -> float:
	return maxf(0.0, _exposed_left)


func key_cooldown_left() -> float:
	return maxf(0.0, _key_cool)


# ---------------------------------------------------------------- Old Vey

## The darkest hour's end state: Old Vey 3 m from Vessa (team PLAYER, not commandable).
func spawn_vey(at: Vector3) -> Unit:
	var u: Unit = mission.call(&"make_unit", "torren_vey")
	if u == null:
		return null
	vey = _spawn_unit(u, Unit.Team.PLAYER, at)
	vey.set_base_stat(&"max_hp", VEY_HP)
	vey.set_base_stat(&"move_speed", 5.0)
	vey.set_base_stat(&"attack_damage", 40.0)
	vey.hp = vey.max_hp
	vey.heal(0.0)
	vey.add_to_group(&"m4_vey")
	vey.set_meta(&"m4_no_hollow", true)
	vey.death_guard = _vey_guard
	vey.apply_aura(&"charged", CHARGED_RADIUS, {"attack_cooldown_pct": -0.15}, &"soldiers")
	_storm_left = 8.0
	_build_charged_ring()
	return vey


func vey_alive() -> bool:
	return vey != null and is_instance_valid(vey) and vey.is_alive()


func _vey_guard(_attacker: Variant) -> bool:
	vey.hp = 1.0
	if not vey_kneeling:
		vey_kneeling = true
		_kneel_left = VEY_KNEEL
		vey.attacks_blocked = true
		vey.command_hold()
		vey.hide_from_auto_target(VEY_KNEEL)
		vey_down.emit()
	return true


func _tick_vey(delta: float) -> void:
	if not vey_alive():
		return
	if _charged_ring:
		_charged_ring.global_position = vey.global_position + Vector3(0.0, 0.06, 0.0)
	if vey_kneeling:
		vey.hp = maxf(vey.hp, 1.0)
		_kneel_left -= delta
		if _kneel_left <= 0.0:
			vey_kneeling = false
			vey.attacks_blocked = false
			vey.hp = vey.max_hp * VEY_STAND_PCT
			vey.heal(0.0)
			vey.command_stop()
		return
	# Charged Ground: Wardens inside take 20 / s.
	_charged_tick -= delta
	if _charged_tick <= 0.0:
		_charged_tick = 0.5
		for w in get_tree().get_nodes_in_group(&"m4_wardens"):
			var wu := w as Unit
			if wu and wu.is_alive() and MissionBase._flat(wu.global_position, vey.global_position) <= CHARGED_RADIUS:
				wu.take_damage(CHARGED_DPS * 0.5, vey)
	_lunge_left -= delta
	_chain_left -= delta
	_storm_left -= delta
	_brain_left -= delta
	if _brain_left <= 0.0:
		_brain_left = BRAIN_TICK
		_vey_brain()
	if _chain_left <= 0.0:
		var first := _vey_target(CHAIN_RANGE)
		if first:
			_chain_left = 8.0
			_chain_lightning(first)
		else:
			_chain_left = TARGET_RETRY   # nothing in reach: look again a bit later, not every physics frame
	if _lunge_left <= 0.0:
		var t := _vey_target(8.0)
		if t:
			_lunge_left = LUNGE_EVERY
			_lunge(t)
		else:
			_lunge_left = TARGET_RETRY
	if _storm_left <= 0.0:
		_storm_left = STORMCALL_EVERY[difficulty]
		_stormcall()


## 3-6 m from Vessa; fights her threats within the leash, else walks back to her.
func _vey_brain() -> void:
	var hero := _hero()
	if hero == null:
		return
	var d := MissionBase._flat(vey.global_position, hero.global_position)
	if d > VEY_LEASH:
		vey.command_move(hero.global_position + (vey.global_position - hero.global_position).normalized() * VEY_NEAR)
		return
	var t := _vey_target(VEY_FAR + 2.0)
	if t != null:
		if vey.attack_target != t:
			vey.command_attack(t)
		return
	if d > VEY_FAR:
		vey.command_move(hero.global_position + (vey.global_position - hero.global_position).normalized() * VEY_NEAR)


## The enemy nearest Vessa within `r` of her (Wardens and Shadow first; the Colossus only while Exposed).
func _vey_target(r: float) -> Unit:
	var hero := _hero()
	var center := hero.global_position if hero else vey.global_position
	var best: Unit = null
	var best_d := INF
	for n in get_tree().get_nodes_in_group("units"):
		var u := n as Unit
		if u == null or not u.is_alive() or int(u.team) == Unit.Team.PLAYER or u.has_meta(&"mission_dormant"):
			continue
		if u == colossus and not colossus.exposed:
			continue
		if u.is_in_group(&"pylons"):
			continue
		var dd := MissionBase._flat(u.global_position, center)
		if dd <= r + u.radius and dd < best_d:
			best_d = dd
			best = u
	return best


func _lunge(t: Unit) -> void:
	var to := t.global_position + (vey.global_position - t.global_position).normalized() * (t.radius + 1.0)
	vey.global_position = Vector3(to.x, vey.global_position.y, to.z)
	_beam(vey.global_position + Vector3(0.0, 1.0, 0.0), t.global_position + Vector3(0.0, 1.0, 0.0), BOLT_COLOR, 0.3)
	t.take_damage(LUNGE_DAMAGE, vey)
	if t.is_alive() and t != colossus:
		t.apply_status(&"dazed", 0.5)
	for u in _enemies_of_vey_in(t.global_position, 2.5):
		if u != t:
			u.take_damage(LUNGE_SPLASH, vey)


func _chain_lightning(first: Unit) -> void:
	var hit: Array[Unit] = []
	var cur := first
	var from := vey.global_position + Vector3(0.0, 1.6, 0.0)
	for i in CHAIN_DAMAGE.size():
		if cur == null:
			break
		var dmg := CHAIN_DAMAGE[i] * (2.0 if cur.is_in_group(&"m4_wardens") else 1.0)
		_beam(from, cur.global_position + Vector3(0.0, 1.0, 0.0), BOLT_COLOR, 0.25)
		cur.take_damage(dmg, vey)
		hit.append(cur)
		from = cur.global_position + Vector3(0.0, 1.0, 0.0)
		var next: Unit = null
		var nd := INF
		for u in _enemies_of_vey_in(cur.global_position, 6.0):
			if hit.has(u):
				continue
			var dd := MissionBase._flat(u.global_position, cur.global_position)
			if dd < nd:
				nd = dd
				next = u
		cur = next


## Stormcall: 8 bolts on enemies within 14 m of Vey (x 2 on Wardens); 300 on an Exposed Colossus in reach.
func _stormcall() -> void:
	stormcalls += 1
	if colossus_alive() and colossus.exposed \
			and MissionBase._flat(colossus.global_position, vey.global_position) <= STORM_RANGE + colossus.radius:
		_bolt(colossus.global_position + Vector3(0.0, 9.0, 0.0))
		colossus.take_damage(STORM_EXPOSED, vey)
	var targets: Array[Unit] = []
	for u in _enemies_of_vey_in(vey.global_position, STORM_RANGE):
		if u != colossus:
			targets.append(u)
	for i in mini(STORM_BOLTS, targets.size() * 2):
		var u: Unit = targets[i % targets.size()]
		if not is_instance_valid(u) or not u.is_alive():
			continue
		_bolt(u.global_position)
		u.take_damage(STORM_DAMAGE * (2.0 if u.is_in_group(&"m4_wardens") else 1.0), vey)


func _enemies_of_vey_in(at: Vector3, r: float) -> Array[Unit]:
	var out: Array[Unit] = []
	for n in get_tree().get_nodes_in_group("units"):
		var u := n as Unit
		if u == null or not u.is_alive() or int(u.team) == Unit.Team.PLAYER or u.is_in_group(&"pylons") \
				or u.has_meta(&"mission_dormant"):
			continue
		if MissionBase._flat(u.global_position, at) <= r + u.radius:
			out.append(u)
	return out


# ---------------------------------------------------------------- helpers

## The telegraph rings on the ground now: [[centre, radius], ...] (Hurl, Stomp; a player steps out of them).
func active_threats() -> Array:
	var out: Array = []
	var keep: Array = []
	for t: Array in _threats:
		if is_instance_valid(t[2]) and not (t[2] as Node).is_queued_for_deletion():
			keep.append(t)
			out.append([t[0], t[1]])
	_threats = keep
	return out


func _spawn_unit(u: Unit, team: Unit.Team, at: Vector3) -> Unit:
	if u == null:
		return null
	return mission.call(&"_spawn", u, team, at) as Unit


func _hero() -> Wizard:
	var h: Variant = mission.get(&"hero")
	if h != null and is_instance_valid(h) and (h as Wizard).is_alive():
		return h as Wizard
	return null


func _hero_pos() -> Vector3:
	return mission.call(&"hero_pos")


## PLAYER and ENEMY units (not NEUTRAL, not dormant) within `r` (+ their radius) of `at`.
func _fighters_in(at: Vector3, r: float) -> Array[Unit]:
	var out: Array[Unit] = []
	for n in get_tree().get_nodes_in_group("units"):
		var u := n as Unit
		if u == null or not u.is_alive() or int(u.team) == Unit.Team.NEUTRAL:
			continue
		if MissionBase._flat(u.global_position, at) <= r + u.radius:
			out.append(u)
	return out


func _nearest_fighter(at: Vector3, r: float) -> Unit:
	var best: Unit = null
	var best_d := INF
	for u in _fighters_in(at, r):
		var d := MissionBase._flat(u.global_position, at)
		if d < best_d:
			best_d = d
			best = u
	return best


func _disc(r: float, color: Color) -> MeshInstance3D:
	var disc := CylinderMesh.new()
	disc.top_radius = r
	disc.bottom_radius = r
	disc.height = 0.05
	disc.radial_segments = 40
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var mi := MeshInstance3D.new()
	mi.mesh = disc
	mi.material_override = mat
	return mi


## A ground ring that fills for `seconds`, then `then` runs (the hit).
func _telegraph(at: Vector3, r: float, color: Color, seconds: float, then: Callable) -> void:
	var mi := _disc(r, color)
	mission.add_child(mi)
	mi.global_position = at + Vector3(0.0, 0.08, 0.0)
	mi.scale = Vector3(0.05, 1.0, 0.05)
	_threats.append([at, r, mi])
	var tw := mi.create_tween()
	tw.tween_property(mi, "scale", Vector3.ONE, seconds)
	tw.tween_callback(func() -> void:
		mi.queue_free()
		if then.is_valid():
			then.call())


func _burst(at: Vector3, r: float, color: Color) -> void:
	var mi := _disc(r, Color(color.r, color.g, color.b, 0.6))
	mission.add_child(mi)
	mi.global_position = at + Vector3(0.0, 0.1, 0.0)
	var mat := mi.material_override as StandardMaterial3D
	var tw := mi.create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.6)
	tw.tween_callback(mi.queue_free)


func _beam(from: Vector3, to: Vector3, color: Color, seconds: float) -> void:
	var mi := _line_mesh(from, to, 0.08, color)
	mission.add_child(mi)
	_place_line(mi, from, to)
	var tw := mi.create_tween()
	tw.tween_interval(seconds)
	tw.tween_callback(mi.queue_free)


func _bolt(at: Vector3) -> void:
	_beam(at + Vector3(0.0, 14.0, 0.0), at, BOLT_COLOR, 0.3)
	_burst(at, 1.5, BOLT_COLOR)


func _line_mesh(_from: Vector3, _to: Vector3, width: float, color: Color) -> MeshInstance3D:
	var cyl := CylinderMesh.new()
	cyl.top_radius = width
	cyl.bottom_radius = width
	cyl.height = 1.0
	cyl.radial_segments = 6
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var mi := MeshInstance3D.new()
	mi.mesh = cyl
	mi.material_override = mat
	return mi


static func _place_line(mi: MeshInstance3D, from: Vector3, to: Vector3) -> void:
	var mid := (from + to) * 0.5
	var len := from.distance_to(to)
	mi.global_position = mid
	var dir := (to - from).normalized()
	var up := Vector3.UP
	if absf(dir.dot(up)) < 0.999:
		var axis := up.cross(dir).normalized()
		mi.global_basis = Basis(axis, up.angle_to(dir))
	mi.scale = Vector3(1.0, maxf(0.01, len), 1.0)


## The golden tether from a pylon to the Colossus's chest (drawn once the Colossus stands).
func _add_tether(p: Unit) -> void:
	var mi := _line_mesh(Vector3.ZERO, Vector3.ZERO, 0.12, Color(1.0, 0.8, 0.35))
	mi.name = "Tether_%s" % p.name
	mission.add_child(mi)
	_tethers[p] = mi
	mi.visible = false
	_place_tethers.call_deferred()


func _place_tethers() -> void:
	if not colossus_alive():
		return
	var chest := colossus.global_position + Vector3(0.0, 8.0, 0.0)
	for p: Variant in _tethers:
		if is_instance_valid(p) and is_instance_valid(_tethers[p]):
			var mi := _tethers[p] as MeshInstance3D
			_place_line(mi, (p as Unit).global_position + Vector3(0.0, 3.4, 0.0), chest)
			mi.visible = true


func _build_key_ring() -> void:
	if _key_ring:
		return
	_key_ring = _disc(colossus.radius + KEY_RANGE, Color(1.0, 0.85, 0.4, 0.18))
	_key_ring_mat = _key_ring.material_override as StandardMaterial3D
	mission.add_child(_key_ring)
	_key_ring.global_position = colossus.global_position + Vector3(0.0, 0.05, 0.0)


func _update_key_ring() -> void:
	if _key_ring == null:
		return
	if _exposed_left > 0.0:
		_key_ring_mat.albedo_color = Color(1.0, 0.95, 0.6, 0.45)
	elif _key_cool > 0.0:
		_key_ring_mat.albedo_color = Color(0.5, 0.45, 0.4, 0.15)
	else:
		_key_ring_mat.albedo_color = Color(1.0, 0.85, 0.4, 0.18 + 0.4 * key_progress)


func _build_charged_ring() -> void:
	_charged_ring = _disc(CHARGED_RADIUS, Color(0.75, 0.85, 1.0, 0.10))
	mission.add_child(_charged_ring)


## Removes the boss-fight decals (the ending).
func clear_decals() -> void:
	for n: Variant in [_key_ring, _charged_ring]:
		if n != null and is_instance_valid(n):
			(n as Node).queue_free()
	_key_ring = null
	_charged_ring = null
