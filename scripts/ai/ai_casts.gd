class_name AICasts
extends RefCounted
## Small kingdom helpers for the Commander (8.A1). Ysolde's cast rules themselves (kingdom-nature.md 3.3) live in
## SpellCaster.suggest_cast() (task 8.G2); the Commander calls it every 0.5 s like for Malrik and Torvald, and
## also while no enemy is near, keeping only a Wild Bloom (the army mends after a fight).
## 8.A2: Vessa's cast rules live here (SpellCaster.suggest_cast() has no Fire branch): suggest_vessa(). The
## Commander calls it every 0.5 s instead of suggest_cast() when its wizard is Vessa, so they only run for a bot
## Vessa (a Commander drives her team); the human's Vessa has no Commander and never casts by herself.

const NATURE_SPELLS: Array[StringName] = [&"thornburst", &"wild_bloom", &"call_the_thicket"]
const VESSA_SPELLS: Array[StringName] = [&"fireball", &"ember_step", &"kindle"]

## Vessa's rules (8.A2), first that applies, at most one cast per 0.5 s check. Foes = visible living enemy units
## (neutrals skipped, as Malrik's Soul Siphon); fighters = foes that are not workers.
const VESSA_WATCH := 30.0            ## Foes this close (visible) start the reaction clock and feed the rules.
const ESCAPE_HP := 0.35              ## 1. Ember Step home when HP < this (Commander.HERO_LOW)...
const ESCAPE_DANGER := 9.0           ## ...and a foe fighter is this close.
const RESERVE_HP := 0.5              ## Below this HP, Fireball / Kindle keep Ember Step's mana (if it is ready soon).
const RESERVE_COOLDOWN := 3.0
const FIREBALL_CLUSTER := 3          ## 2. Fireball on the foe with the most foes in the blast (itself included).
const KINDLE_ALLIES := 3             ## 3. Kindle: this many own soldiers within its radius...
const KINDLE_FOES := 2               ## ...and this many foe fighters...
const KINDLE_FOE_RANGE := 12.0       ## ...within this of Vessa.
## 4. Fireball on the enemy wizard when in range (focus).
const ENGAGE_SELF_HP := 0.6          ## 5. Ember Step to engage: Vessa HP >= this...
const ENGAGE_FOE_HP := 0.5           ## ...the enemy wizard under this, out of Fireball range, reachable...
const ENGAGE_GUARDS := 2             ## ...with at most this many foe fighters...
const ENGAGE_GUARD_RADIUS := 6.0     ## ...within this of it; she lands ENGAGE_LAND from it, then Fireball.
const ENGAGE_LAND := 11.0
const SPARE_MANA := 0.7              ## 6. Spare mana: Fireball a pair of foes from this share of max mana...
const FULL_MANA := 0.95              ## ...or any foe from this share.

## B13 Cause 2 (docs/balance/b13_2026-10-13/diagnosis.md): a bot wizard other than Vessa whose escape spell (slot E:
## Umbral Shroud, Rime Aegis, Call the Thicket) is not ready (not learned, cooldown, mana) goes home from
## NO_ESCAPE_LOW HP while a foe fighter is within RETREAT_DANGER, on a path that bends around the foes
## (retreat_point), and casts on its chasers on the way (suggest_retreat_cast). Vessa keeps her rules (35 %, blink).
## Switch (lead 2026-10-14, Cause 3 measured alone): false = the bot behaves exactly as before Cause 2 (35 % line,
## straight walk home, no chaser casts). A static var so tests / labs can turn it on (tests/test_bal_cause2.gd).
static var retreat_rule := false
const NO_ESCAPE_LOW := 0.5
const RETREAT_DANGER := 16.0         ## Foe fighters this close count as chasers.
const DETOUR_STEP := 12.0            ## Detour waypoint distance when the foes stand between the wizard and home.
const DETOUR_CONE := 0.3             ## Detour while dot(home dir, foes dir) > this (foes within ~70 deg of the way home).
const SIPHON_RETREAT_FOES := 2       ## Malrik: Soul Siphon on the chasers from this many foes in the circle.


## The wizard's escape spell: Vessa's Ember Step, else its slot E spell (&"" when it has fewer than 3 slots).
static func escape_spell(w: Wizard) -> StringName:
	if w == null or not is_instance_valid(w):
		return &""
	if is_vessa(w):
		return &"ember_step"
	var ids := w.spell_ids()
	return ids[2] if ids.size() >= 3 else &""


## True when the escape spell could be cast now (learned, off cooldown, mana).
static func escape_ready(w: Wizard) -> bool:
	var id := escape_spell(w)
	if id == &"" or w.spell_caster == null or not w.spell_caster.has_method(&"can_cast"):
		return false
	return str(w.spell_caster.call(&"can_cast", id)) == ""


## HP share under which the bot sends its wizard home: 0.35 (Commander.HERO_LOW) for Vessa, with a ready escape or
## with no chaser near; NO_ESCAPE_LOW for the others while `chased`.
static func low_hp_line(w: Wizard, chased: bool, base := 0.35) -> float:
	if not retreat_rule or not chased or is_vessa(w) or escape_ready(w):
		return base
	return maxf(base, NO_ESCAPE_LOW)


## Where a hurt wizard walks now: `home`, unless the foe fighters' centre lies on the way home (within the
## DETOUR_CONE and nearer than home): then a point `step` away that goes sideways around them (toward home's side) and
## a little away from them. Re-asked every tick, it bends the walk around the threat instead of through it.
static func retreat_point(me: Vector3, home: Vector3, fighters: Array[Unit], step := DETOUR_STEP) -> Vector3:
	var to_home := home - me
	to_home.y = 0.0
	if not retreat_rule or fighters.is_empty() or to_home.length() < 0.5:
		return home
	var c := Vector3.ZERO
	for f in fighters:
		c += f.global_position
	c /= float(fighters.size())
	var toward := c - me
	toward.y = 0.0
	if toward.length() < 0.01 or toward.length() > to_home.length():
		return home
	var t := toward.normalized()
	var hd := to_home.normalized()
	if hd.dot(t) <= DETOUR_CONE:
		return home
	var side := hd - t * hd.dot(t)
	if side.length() < 0.05:
		side = Vector3(-t.z, 0.0, t.x)
	var dir := (side.normalized() - t * 0.5).normalized()
	var p := me + dir * step
	p.y = me.y
	return p


## A cast on the chasers while the wizard walks home, or {} ({"spell_id", "target", "retreat": true, "rule"}):
## Torvald: Flash Freeze on the nearest foe fighter in range; Malrik: Soul Siphon on the best circle with >=
## SIPHON_RETREAT_FOES foes in range. Others: {} (their suggest_cast rules stay).
static func suggest_retreat_cast(w: Wizard, foes: Array[Unit]) -> Dictionary:
	if not retreat_rule or w == null or not is_instance_valid(w) or not w.is_alive() or not w.can_act() or foes.is_empty():
		return {}
	var c := w.spell_caster as SpellCaster
	if c == null:
		return {}
	var me := w.global_position
	var ids := w.spell_ids()
	if ids.has(&"flash_freeze") and c.can_cast(&"flash_freeze") == "":
		var nearest: Unit = null
		for u in foes:
			if not u.is_worker() and _dist(me, u.global_position) <= c.range_of(&"flash_freeze") \
					and (nearest == null or _dist(me, u.global_position) < _dist(me, nearest.global_position)):
				nearest = u
		if nearest:
			return {"spell_id": &"flash_freeze", "target": nearest.global_position, "retreat": true, "rule": "chaser"}
	if ids.has(&"soul_siphon") and c.can_cast(&"soul_siphon") == "":
		var center: Variant = best_cluster(me, foes, c.range_of(&"soul_siphon"), c.radius_of(&"soul_siphon"),
				SIPHON_RETREAT_FOES)
		if center != null:
			return {"spell_id": &"soul_siphon", "target": center, "retreat": true, "rule": "chaser"}
	return {}


## True if the wizard casts Nature spells (one of its spell ids is a Nature one).
static func is_nature(w: Wizard) -> bool:
	if w == null or not is_instance_valid(w):
		return false
	for id in w.spell_ids():
		if NATURE_SPELLS.has(id):
			return true
	return false


## True if the wizard casts Fire spells (Vessa: Fireball / Ember Step / Kindle).
static func is_vessa(w: Wizard) -> bool:
	if w == null or not is_instance_valid(w):
		return false
	for id in w.spell_ids():
		if VESSA_SPELLS.has(id):
			return true
	return false


## True if a unit is a summon (UnitType.lifetime > 0, e.g. a Sapling): the Commander never orders or counts it.
static func is_summon(u: Unit) -> bool:
	if u == null or u.unit_type == null:
		return false
	var life: Variant = u.unit_type.get(&"lifetime")
	return life != null and float(life) > 0.0


## Vessa's cast for now, or {}: {"spell_id", "target", "retreat", "rule"}. `foes`: visible living enemy units
## (not neutral) within VESSA_WATCH; `allies`: own soldiers (no workers, wizards or summons); `home`: where she
## retreats (keep drop-off point or anchor); `may_engage`: rule 5 allowed (she attacks or defends, not while she
## holds her anchor). Skips a spell not learned, on cooldown or without mana.
## 1 escape: HP < 35 % and a foe fighter within 9 m: Ember Step toward home, or away from the nearest fighter
##   when home is closer than the blink ("retreat" = true).
## 2 Fireball on the foe with >= 3 foes within the blast radius (ties: the group holding the enemy wizard, nearest).
## 3 Kindle: >= 3 own soldiers within its radius and >= 2 foe fighters within 12 m.
## 4 Fireball on the enemy wizard in range.
## 5 engage: HP >= 60 %, the enemy wizard < 50 % HP, out of Fireball range but reachable with Ember Step (lands
##   11 m from it), <= 2 foe fighters within 6 m of it, mana for Ember Step + Fireball: Ember Step toward it.
## 6 spare mana: Fireball on a pair of foes from 70 % mana, on any foe in range from 95 %.
## Below 50 % HP, Fireball and Kindle keep 30 mana for Ember Step when it is ready within 3 s.
static func suggest_vessa(w: Wizard, foes: Array[Unit], allies: Array[Unit], home: Vector3,
		may_engage: bool = true) -> Dictionary:
	if w == null or not is_instance_valid(w) or not w.is_alive() or not w.can_act():
		return {}
	var c := w.spell_caster as SpellCaster
	if c == null:
		return {}
	var me := w.global_position
	var hp_ratio := w.hp / _max_hp(w)
	var fighters: Array[Unit] = []
	var foe_wizard: Wizard = null
	for u in foes:
		if not u.is_worker():
			fighters.append(u)
		if u is Wizard and (foe_wizard == null or _dist(me, u.global_position) < _dist(me, foe_wizard.global_position)):
			foe_wizard = u as Wizard
	var step_ok := c.can_cast(&"ember_step") == ""
	# 1. escape
	if step_ok and hp_ratio < ESCAPE_HP and _nearest(me, fighters) <= ESCAPE_DANGER:
		return {"spell_id": &"ember_step", "target": _escape_point(me, home, fighters, c.range_of(&"ember_step")),
				"retreat": true, "rule": "escape"}
	var reserve := 0.0
	if hp_ratio < RESERVE_HP and c.rank_of(&"ember_step") > 0 and c.cooldown_left(&"ember_step") <= RESERVE_COOLDOWN:
		reserve = c.mana_cost(&"ember_step")
	var fb_ok := c.can_cast(&"fireball") == "" and w.mana - c.mana_cost(&"fireball") >= reserve
	var reach := c.range_of(&"fireball")
	var blast := c.radius_of(&"fireball")
	# 2. Fireball on a cluster
	if fb_ok:
		var center: Variant = best_cluster(me, foes, reach, blast, FIREBALL_CLUSTER)
		if center != null:
			return {"spell_id": &"fireball", "target": center, "retreat": false, "rule": "cluster"}
	# 3. Kindle while the army fights nearby
	if c.can_cast(&"kindle") == "" and w.mana - c.mana_cost(&"kindle") >= reserve:
		var kr := c.radius_of(&"kindle")
		var near_allies := 0
		for a in allies:
			if _dist(me, a.global_position) <= kr:
				near_allies += 1
		var near_fighters := 0
		for f in fighters:
			if _dist(me, f.global_position) <= KINDLE_FOE_RANGE:
				near_fighters += 1
		if near_allies >= KINDLE_ALLIES and near_fighters >= KINDLE_FOES:
			return {"spell_id": &"kindle", "target": null, "retreat": false, "rule": "kindle"}
	# 4. focus the enemy wizard
	if fb_ok and foe_wizard and _dist(me, foe_wizard.global_position) <= reach:
		return {"spell_id": &"fireball", "target": foe_wizard.global_position, "retreat": false, "rule": "wizard"}
	# 5. engage a hurt enemy wizard
	if may_engage and step_ok and foe_wizard and hp_ratio >= ENGAGE_SELF_HP:
		var d := _dist(me, foe_wizard.global_position)
		var mana_need := c.mana_cost(&"ember_step") + c.mana_cost(&"fireball")
		if foe_wizard.hp / _max_hp(foe_wizard) < ENGAGE_FOE_HP and d > reach and d - ENGAGE_LAND <= c.range_of(&"ember_step") \
				and w.mana >= mana_need and c.cooldown_left(&"fireball") <= 1.0 \
				and _count_within(foe_wizard.global_position, fighters, ENGAGE_GUARD_RADIUS) <= ENGAGE_GUARDS:
			var back := me - foe_wizard.global_position
			back.y = 0.0
			var land := foe_wizard.global_position + back.normalized() * ENGAGE_LAND
			land.y = me.y
			return {"spell_id": &"ember_step", "target": land, "retreat": false, "rule": "engage"}
	# 6. spare mana
	if fb_ok:
		var mana_ratio := w.mana / maxf(1.0, w.max_mana)
		var min_count := 0
		if mana_ratio >= FULL_MANA:
			min_count = 1
		elif mana_ratio >= SPARE_MANA:
			min_count = 2
		if min_count > 0:
			var spare: Variant = best_cluster(me, foes, reach, blast, min_count)
			if spare != null:
				return {"spell_id": &"fireball", "target": spare, "retreat": false, "rule": "spare"}
	return {}


## The foe within `reach` of `from` with the most foes within `r` of it (itself included, at least `min_count`);
## ties: the group holding an enemy wizard, then the nearest. Its position, or null.
static func best_cluster(from: Vector3, foes: Array[Unit], reach: float, r: float, min_count: int) -> Variant:
	var best: Unit = null
	var best_count := 0
	var best_wiz := false
	var best_dist := INF
	for u in foes:
		var d := _dist(from, u.global_position)
		if d > reach:
			continue
		var count := 0
		var has_wiz := false
		for v in foes:
			if _dist(u.global_position, v.global_position) <= r:
				count += 1
				has_wiz = has_wiz or v is Wizard
		var better := count > best_count
		if count == best_count:
			better = (has_wiz and not best_wiz) or (has_wiz == best_wiz and d < best_dist)
		if better:
			best = u
			best_count = count
			best_wiz = has_wiz
			best_dist = d
	if best == null or best_count < min_count:
		return null
	return best.global_position


## Ember Step's point for an escape: `reach` toward home; home closer than `reach`: away from the nearest fighter.
static func _escape_point(me: Vector3, home: Vector3, fighters: Array[Unit], reach: float) -> Vector3:
	var dir := home - me
	dir.y = 0.0
	if dir.length() < reach:
		var nearest: Unit = null
		for f in fighters:
			if nearest == null or _dist(me, f.global_position) < _dist(me, nearest.global_position):
				nearest = f
		dir = me - nearest.global_position if nearest else Vector3.FORWARD
		dir.y = 0.0
	if dir.length() < 0.01:
		dir = Vector3.FORWARD
	return me + dir.normalized() * reach


static func _max_hp(u: Unit) -> float:
	var m := u.get_stat(&"max_hp")
	return maxf(1.0, m if m > 0.0 else u.max_hp)


static func _nearest(from: Vector3, units: Array[Unit]) -> float:
	var best := INF
	for u in units:
		best = minf(best, _dist(from, u.global_position))
	return best


static func _count_within(from: Vector3, units: Array[Unit], r: float) -> int:
	var n := 0
	for u in units:
		if _dist(from, u.global_position) <= r:
			n += 1
	return n


static func _dist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
