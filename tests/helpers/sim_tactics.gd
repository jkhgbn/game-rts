class_name SimTactics
extends RefCounted
## Human-like army handling for the campaign scripted runs (tests/test_*_sim.gd, 2026-10-07): what a real player does
## against enemy wizards' area spells (Fireball r 3.5-4, Thornburst, Malrik's Soul Siphon, boss slams) instead of
## walking one packed blob of 110-HP Shades into them.
## - spread_to(): a loose formation (slots SPACING apart, melee in front, ranged behind) instead of a random +-4 m pile.
## - focus_wizards(): the enemy wizard near the army is everyone's target (ranged first, melee within reach), the Unit
##   Guide answer ("Hexweaver: shuts down elites and heroes", "Grave Hound: reaches casters").
## - pull_back_wounded(): a unit under `low` of its HP walks back to `safe` until healed or the fight is over.
## - unclump(): idle units with 2+ friends within GAP of them step apart while an enemy caster is close.
## Only public Unit orders (command_move / command_attack_move / command_attack); nothing the player could not do.

const SPACING := 4.2        ## > the Fireball radius at rank 2 (3.75): one blast catches 1-2 units, not 6
const GAP := 2.4            ## unclump: closer than this to 2+ friends = a clump
const CASTER_NEAR := 20.0   ## unclump only while an enemy caster stands this close


static func centroid(units: Array) -> Vector3:
	var c := Vector3.ZERO
	var n := 0
	for u: Variant in units:
		if is_instance_valid(u):
			c += (u as Node3D).global_position
			n += 1
	return c / float(n) if n > 0 else Vector3.INF


static func is_ranged(u: Unit) -> bool:
	return u.attack_range > 3.0


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


static func _busy(u: Unit, near := 9.0) -> bool:
	var t: Variant = u.attack_target
	return t != null and is_instance_valid(t) and (t as Node3D).is_inside_tree() and bool((t as Node).call(&"is_alive")) \
			and _flat(u.global_position, (t as Node3D).global_position) <= near


## Loose formation at `center` facing `facing` (any length; ZERO = south, +z): melee rows in front, ranged rows behind,
## columns SPACING apart. Units fighting something within 9 m keep fighting; the others attack-move to their slot.
static func spread_to(units: Array, center: Vector3, facing: Vector3, spacing := SPACING) -> void:
	var fwd := Vector3(facing.x, 0.0, facing.z)
	fwd = fwd.normalized() if fwd.length() > 0.01 else Vector3(0.0, 0.0, 1.0)
	var side := Vector3(-fwd.z, 0.0, fwd.x)
	var melee: Array[Unit] = []
	var ranged: Array[Unit] = []
	for v: Variant in units:
		var u := v as Unit
		if u == null or not is_instance_valid(u) or not u.is_alive():
			continue
		(ranged if is_ranged(u) else melee).append(u)
	var rows: Array = [melee, ranged]
	var depth := 0.0
	for r in rows.size():
		var list: Array[Unit] = rows[r]
		if list.is_empty():
			continue
		var cols := maxi(3, int(ceil(sqrt(float(list.size()) * 2.5))))
		# sort by lateral position so units keep their side (fewer crossings)
		list.sort_custom(func(a: Unit, b: Unit) -> bool: return (a.global_position - center).dot(side) < (b.global_position - center).dot(side))
		var n_rows := int(ceil(float(list.size()) / float(cols)))
		for i in list.size():
			var row := i / cols
			var col := i % cols
			var in_row := mini(cols, list.size() - row * cols)
			var lat := (float(col) - float(in_row - 1) * 0.5) * spacing + (spacing * 0.5 if row % 2 == 1 else 0.0)
			var back := depth + float(row) * spacing * 0.85
			var slot := center + side * lat - fwd * back
			var u := list[i]
			if _busy(u):
				continue
			if _flat(u.global_position, slot) > 1.6:
				u.command_attack_move(slot)
		depth += float(n_rows) * spacing * 0.85 + 1.0


## Every unit's target = the nearest awake enemy wizard within `reach` of the army's centre (ranged units within
## reach + their range, melee within `reach`). Returns the wizard or null. `wizards` may hold nulls / dead ones.
static func focus_wizards(units: Array, wizards: Array, reach := 14.0, is_awake: Callable = Callable()) -> Unit:
	var c := centroid(units)
	if c == Vector3.INF:
		return null
	var best: Unit = null
	var best_d := INF
	for v: Variant in wizards:
		if v == null or not is_instance_valid(v):
			continue
		var w := v as Unit
		if not w.is_alive() or w.has_meta(Unit.TRUCE_META) or (is_awake.is_valid() and not bool(is_awake.call(w))):
			continue
		var d := _flat(w.global_position, c)
		if d <= reach and d < best_d:
			best = w
			best_d = d
	if best == null:
		return null
	for v: Variant in units:
		var u := v as Unit
		if u == null or not is_instance_valid(u) or not u.is_alive() or u.attack_target == best:
			continue
		var d := _flat(u.global_position, best.global_position)
		if d <= reach + (u.attack_range if is_ranged(u) else 0.0):
			u.command_attack(best)
	return best


## Units under `low` of their max HP walk to `safe` and stay out until `back` of their HP or `max_time` s (state keeps
## {unit_id: seconds_left}; `dt` = the caller's tick). Returns the units still in the fight.
static func pull_back_wounded(units: Array, safe: Vector3, state: Dictionary, dt: float, low := 0.3, back := 0.8,
		max_time := 25.0) -> Array:
	var out: Array = []
	for v: Variant in units:
		var u := v as Unit
		if u == null or not is_instance_valid(u) or not u.is_alive():
			continue
		var id := u.get_instance_id()
		var frac := u.hp / maxf(1.0, u.max_hp)
		if state.has(id) and float(state[id]) < 0.0:
			# Back from the rear without healing (no regen): it fights for 60 s before it may be pulled again.
			state[id] = float(state[id]) + dt
			if float(state[id]) >= 0.0:
				state.erase(id)
		elif state.has(id):
			state[id] = float(state[id]) - dt
			if frac >= back or float(state[id]) <= 0.0:
				state[id] = -60.0 if frac < back else 0.0
				if float(state[id]) == 0.0:
					state.erase(id)
			else:
				if _flat(u.global_position, safe) > 3.0 and not u.has_move_order():
					u.command_move(safe + Vector3(randf_range(-3.0, 3.0), 0.0, randf_range(-3.0, 3.0)))
				continue
		elif frac < low and u.max_hp >= 100.0:
			state[id] = max_time
			u.command_move(safe + Vector3(randf_range(-3.0, 3.0), 0.0, randf_range(-3.0, 3.0)))
			continue
		out.append(u)
	for id: Variant in state.keys():
		if not is_instance_valid(instance_from_id(int(id))):
			state.erase(id)
	return out


## Idle units with 2+ friends within GAP step 2.5 m away from their neighbours while an enemy caster (any of
## `casters`) is within CASTER_NEAR of them.
static func unclump(units: Array, casters: Array) -> void:
	var threats: Array[Vector3] = []
	for v: Variant in casters:
		if v != null and is_instance_valid(v) and (v as Unit).is_alive():
			threats.append((v as Node3D).global_position)
	if threats.is_empty():
		return
	for v: Variant in units:
		var u := v as Unit
		if u == null or not is_instance_valid(u) or not u.is_alive() or u.has_move_order() or _busy(u, 3.0):
			continue
		var near := false
		for t in threats:
			if _flat(t, u.global_position) <= CASTER_NEAR:
				near = true
				break
		if not near:
			continue
		var push := Vector3.ZERO
		var n := 0
		for o: Variant in units:
			if o == u or not is_instance_valid(o):
				continue
			var d := (u.global_position - (o as Node3D).global_position)
			d.y = 0.0
			if d.length() < GAP:
				n += 1
				push += d.normalized() if d.length() > 0.05 else Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)).normalized()
		if n >= 2 and push.length() > 0.01:
			u.command_attack_move(u.global_position + push.normalized() * 2.5)
