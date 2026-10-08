class_name Wizard
extends Unit
## A wizard hero: a strong unit with mana and a Fireball spell.
## Each of the four kingdoms will get its own wizard; this one is Vessa, the Fire Wizard.
## Stats are the "Wizards" table of docs/design/units-fire-shadow.md. ShadowWizard (Malrik) extends it.

signal artifact_claimed(artifact_name: String)
## Emitted by respawn(), after the wizard is back (alive, full HP and mana, at the new spot).
signal respawned(wizard: Wizard)
## Levels (docs/design/levels.md). `xp` is the XP inside the current level, `xp_to_next` the size of
## the current level's bar (0 at max level). The HUD shows "XP xp / xp_to_next".
signal xp_changed(xp: int, xp_to_next: int)
signal spell_points_changed(points: int)
signal spell_learned(spell_id: StringName, rank: int)
## Item hooks (items.md, 4.G1): one enemy (unit or building) lost `amount` HP (> 0) to spell
## `spell_id` (every hit / tick of the six spells). Spell Feed is already applied when it fires.
signal spell_hit(target: Node3D, amount: float, spell_id: StringName)
## A spell went off (mana and cooldown paid). Same as SpellCaster.spell_cast.
signal spell_cast(spell_id: StringName)
# `level` (1-8), `xp` and `level_changed(unit, level)` are inherited from Unit.

const MAX_LEVEL := 8
## Total XP needed to reach level i + 1 (index 0 = level 1).
const LEVEL_TOTAL_XP: Array[int] = [0, 150, 400, 750, 1200, 1750, 2450, 3350]
const XP_FULL_SHARE_RANGE := 20.0   ## Alive and this close to the victim: 100 % of its XP.
const XP_FAR_SHARE := 0.25          ## Farther away, or dead: 25 % (rounded, min 1).
## Per spell slot (F / Q / E): max rank and the level each rank needs (index = rank - 1).
const SPELL_MAX_RANK: Array[int] = [3, 3, 2]
const SPELL_LEVEL_REQUIRED: Array = [[1, 3, 5], [2, 4, 6], [4, 7]]
const SPELL_CASTER_PATH := "res://scripts/spells/spell_caster.gd"
const STR_INT_PATH_SCRIPT := "res://scripts/units/str_int_path.gd"
const SPELL_HEAL_CAP := 0.6  ## items.md: spell life drain + Spell Feed heal at most 60 % of the damage

## Stat growth per level above 1 (levels.md; Malrik overrides these in _init).
@export var hp_per_level := 25.0
@export var damage_per_level := 2.0
@export var mana_per_level := 10.0
@export var mana_regen_per_level := 0.25
## Highest level this wizard can reach (missions: mission 1 caps Vessa at 5). 0 = no cap (MAX_LEVEL).
## At the cap XP stops: add_xp does nothing, xp stays 0 and xp_to_next() is 0 (the HUD shows max).
@export var level_cap: int = 0:
	set(value):
		level_cap = maxi(0, value)
		if level >= max_level() and xp != 0:
			xp = 0
			if is_inside_tree():
				xp_changed.emit(xp, xp_to_next())
## Spell ids in slot order F / Q / E, used when there is no SpellCaster (or it has no list).
@export var default_spell_ids: Array[StringName] = [&"fireball", &"ember_step", &"kindle"]

@export var max_mana := 100.0
@export var mana_regen := 4.0            ## Mana per second.
@export var fireball_cost := 40.0
@export var fireball_damage := 60.0
@export var fireball_radius := 3.5
@export var fireball_range := 16.0
@export var hat_color := Color(0.55, 0.08, 0.05)
@export var orb_color := Color(1.0, 0.45, 0.1)
## Character model used when model_scene is empty ("" = placeholder hat and staff).
@export var default_model_path := "res://art/units/wizards/vessa.tscn"
## Kingdom for the model's team colour (Unit.KINGDOM_COLORS key).
@export var kingdom: StringName = &"fire"

var mana: float
var artifacts: Array[String] = []
var total_xp := 0          ## All XP ever earned (xp is the part inside the current level).
var spell_points := 0
## The "SpellCaster" child (scripts/spells/spell_caster.gd) or null when that script doesn't exist.
var spell_caster: Node = null
## The items Inventory (scripts/items/, set by Inventory.ensure_for(wizard)); null until then.
var inventory: Node = null
## The "StrIntPath" child (scripts/units/str_int_path.gd, STR / INT path) or null when off.
var str_int: Node = null

var _ranks: Dictionary = {}   # spell_id -> rank (missing = 0)

## Wave 1 walk-then-cast Fireball; with a SpellCaster it mirrors the caster's pending cast, and
## writing false cancels it (every command_* and direct control does that).
var _has_pending_cast := false:
	get:
		if spell_caster and spell_caster.has_method(&"has_pending"):
			return bool(spell_caster.call(&"has_pending"))
		return _has_pending_cast
	set(value):
		_has_pending_cast = value
		if not value and spell_caster and spell_caster.has_method(&"cancel_pending"):
			spell_caster.call(&"cancel_pending")
var _pending_cast_pos := Vector3.ZERO
var _move_input := Vector3.ZERO   # direct control (WASD), world space, length 0-1


func _init() -> void:
	unit_name = "Vessa, Fire Wizard"
	max_hp = 350.0
	move_speed = 4.6
	attack_damage = 14.0
	attack_range = 7.0
	attack_cooldown = 1.3
	aggro_range = 9.0
	radius = 0.5
	body_height = 2.0
	body_color = Color(0.9, 0.35, 0.1)
	projectile_color = Color(1.0, 0.55, 0.15)


func _ready() -> void:
	super._ready()
	if has_method(&"set_base_stat"):   # Stats pipeline: mana stats get a base like the others
		call(&"set_base_stat", &"max_mana", max_mana)
		call(&"set_base_stat", &"mana_regen", mana_regen)
	mana = max_mana
	add_to_group("heroes")
	_create_spell_caster()
	_create_str_int_path()
	# Spell 1 (F) rank 1 is known at level 1, free; the others start unlearned.
	var ids := spell_ids()
	for i in ids.size():
		_set_rank(ids[i], 1 if i == 0 else 0)
	if has_signal(&"stats_changed"):
		connect(&"stats_changed", _sync_mana_stats)
	# XP from kills: units through Events.unit_died, buildings through their own signals.
	var events := get_node_or_null(^"/root/Events")
	if events and events.has_signal(&"unit_died"):
		events.connect(&"unit_died", _on_unit_died)
	get_tree().node_added.connect(_on_node_added)
	for b in get_tree().get_nodes_in_group("buildings"):
		_watch_building(b)


## Creates the "SpellCaster" child if scripts/spells/spell_caster.gd exists (wave 3 framework).
func _create_spell_caster() -> void:
	if not ResourceLoader.exists(SPELL_CASTER_PATH):
		return
	var script := load(SPELL_CASTER_PATH) as Script
	if script == null or not script.can_instantiate():
		return
	var node := script.new() as Node
	if node == null:
		return
	node.name = "SpellCaster"
	add_child(node)
	spell_caster = node
	if node.has_method(&"setup"):
		node.call(&"setup", self, default_spell_ids)   # each wizard's own F / Q / E list
	if node.has_signal(&"spell_cast"):
		node.connect(&"spell_cast", func(id: StringName) -> void: spell_cast.emit(id))
	spell_cast.connect(_on_spell_cast_model)


## Creates the "StrIntPath" child (STR / INT path, level-boons.md) if its script exists and is ENABLED.
func _create_str_int_path() -> void:
	if not ResourceLoader.exists(STR_INT_PATH_SCRIPT):
		return
	var script := load(STR_INT_PATH_SCRIPT) as Script
	if script == null or not script.can_instantiate() \
			or not bool(script.get_script_constant_map().get("ENABLED", false)):
		return
	var node := script.new() as Node
	if node == null:
		return
	if node.has_method(&"setup"):
		node.call(&"setup", self)
	node.name = "StrIntPath"
	add_child(node)
	str_int = node


# The body part of a cast (art-units.md 6.5); the spell VFX stay in scripts/vfx/.
func _on_spell_cast_model(spell_id: StringName) -> void:
	if _model and _model.has_method(&"play_cast"):
		_model.call(&"play_cast", spell_id)


func _kingdom_color() -> Color:
	return KINGDOM_COLORS.get(kingdom, Color(0, 0, 0, 0))


## SpellCaster calls this for every spell hit (`amount` = HP really lost). Heals by the stat
## `spell_feed` (percent; the spell's own life drain + feed is capped at 60 %, items.md), then emits
## spell_hit.
func notify_spell_hit(target: Node3D, amount: float, spell_id: StringName) -> void:
	if amount <= 0.0:
		return
	var feed := get_stat(&"spell_feed")
	if feed > 0.0 and is_alive():
		var own := 0.0
		if spell_caster and spell_caster.has_method(&"spell_type"):
			var t: Variant = spell_caster.call(&"spell_type", spell_id)
			if t is SpellType:
				own = (t as SpellType).heal_ratio
		var ratio := minf(feed / 100.0, maxf(0.0, SPELL_HEAL_CAP - own))
		if ratio > 0.0:
			heal(amount * ratio)
	spell_hit.emit(target, amount, spell_id)


# ---------------------------------------------------------------- levels and XP

## Wizards never get soldier veterancy (their XP comes from credit_kill).
func can_gain_veterancy() -> bool:
	return false


## The level XP stops at: level_cap when set (clamped to 1..MAX_LEVEL), else MAX_LEVEL.
func max_level() -> int:
	return clampi(level_cap, 1, MAX_LEVEL) if level_cap > 0 else MAX_LEVEL


## Size of the current level's XP bar (150 at level 1 ... 900 at level 7), 0 at max level / the cap.
func xp_to_next() -> int:
	if level >= max_level():
		return 0
	return LEVEL_TOTAL_XP[level] - LEVEL_TOTAL_XP[level - 1]


## Adds XP (works while dead). Each level gained applies the stat growth, heals by the gain,
## gives 1 spell point and emits level_changed. Overflow carries into the next level; nothing is
## gained at max_level() (xp stays 0 there; total_xp keeps the XP of the call that reached it).
func add_xp(amount: int) -> void:
	var cap := max_level()
	if amount <= 0 or level >= cap:
		return
	total_xp += amount
	xp += amount
	while level < cap and xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		spell_points += 1
		_apply_level_stats()
		_model_call(&"play_level_up")   # never set_veterancy on wizards (art-units.md 7.1)
		_emit_level_changed()
		spell_points_changed.emit(spell_points)
	if level >= cap:
		xp = 0
	xp_changed.emit(xp, xp_to_next())


## XP a killing blow on `victim` is worth (levels.md table, Unit.kill_xp_value); any wizard
## (Malrik is not in "heroes") is worth 120 + 30 x its level, a champion 100 + 25 x its level
## (champions.md 3.3). EssenceBank pays its kill essence from this value too.
static func xp_value_of(victim: Node) -> int:
	if victim == null or not is_instance_valid(victim):
		return 0
	if victim is Wizard:
		return 120 + 30 * int((victim as Wizard).level)
	if victim.is_in_group(&"champions"):
		var lvl: Variant = victim.get(&"level")
		return Unit.CHAMPION_KILL_XP + Unit.CHAMPION_KILL_XP_PER_LEVEL * (int(lvl) if lvl != null else 1)
	return Unit.kill_xp_value(victim)


## Credits a kill whose killing blow came from team `killer_team`. Only an enemy victim of that
## team's wizard pays: 100 % when alive within 20 m of the victim, else 25 %. Returns the XP given.
func credit_kill(victim: Node3D, killer_team: int) -> int:
	if victim == null or victim == self or killer_team != int(team):
		return 0
	var victim_team: Variant = victim.get(&"team")
	if victim_team == null or int(victim_team) == int(team):
		return 0
	var value := xp_value_of(victim)
	if value <= 0:
		return 0
	var amount := value
	if not is_alive() or _flat_distance(victim.global_position) > XP_FULL_SHARE_RANGE:
		amount = maxi(1, roundi(value * XP_FAR_SHARE))
	add_xp(amount)
	return amount


func _on_unit_died(victim: Node) -> void:
	var killer_team := _killer_team_of(victim)
	if killer_team >= 0 and victim is Node3D:
		credit_kill(victim, killer_team)


## The team that dealt the killing blow, or -1 when unknown. Reads what Unit exposes about its
## last attacker (task 3.G2a); buildings store it in meta via _watch_building.
static func _killer_team_of(victim: Node) -> int:
	if victim == null or not is_instance_valid(victim):
		return -1
	for prop: StringName in [&"killer_team", &"last_attacker_team"]:
		var t: Variant = victim.get(prop)
		if t is int:
			return t
	for prop: StringName in [&"killer", &"last_attacker"]:
		var a: Variant = victim.get(prop)
		if typeof(a) == TYPE_OBJECT and is_instance_valid(a):
			var t: Variant = (a as Object).get(&"team")
			if t != null:
				return int(t)
	if victim.has_meta(&"last_attacker_team"):
		return int(victim.get_meta(&"last_attacker_team"))
	return -1


func _on_node_added(node: Node) -> void:
	if node is Building:
		_watch_building(node)


func _watch_building(node: Node) -> void:
	if not node is Building:
		return
	var cb_damaged := _on_building_damaged.bind(node)
	if not node.is_connected(&"damaged", cb_damaged):
		node.connect(&"damaged", cb_damaged)
	if not node.is_connected(&"destroyed", _on_building_destroyed):
		node.connect(&"destroyed", _on_building_destroyed)


func _on_building_damaged(_amount: float, attacker: Node3D, building: Node) -> void:
	if attacker != null and is_instance_valid(attacker) and attacker.get(&"team") != null:
		building.set_meta(&"last_attacker_team", int(attacker.get(&"team")))


func _on_building_destroyed(building: Node) -> void:
	# A cancelled site also emits destroyed: only a building beaten to 0 HP pays.
	if building is Node3D and float(building.get(&"hp")) <= 0.0:
		var killer_team := _killer_team_of(building)
		if killer_team >= 0:
			credit_kill(building, killer_team)


func _emit_level_changed() -> void:
	for s in get_signal_list():
		if s["name"] == "level_changed":
			if (s["args"] as Array).size() >= 2:
				emit_signal(&"level_changed", self, level)
			else:
				emit_signal(&"level_changed", level)
			return


## Applies the per-level growth for the current level: through the Stats pipeline (modifier
## "wizard_level") when Unit has it, else by raising the fields by one level's worth. The new maxima
## apply at once and HP / mana are healed by the gain (only while alive).
func _apply_level_stats() -> void:
	var hp_before := hp
	var max_hp_before := max_hp
	var mana_before := mana
	var max_mana_before := max_mana
	var steps := float(level - 1)
	if has_method(&"add_modifier"):
		if has_method(&"remove_modifier"):
			call(&"remove_modifier", &"wizard_level")
		call(&"add_modifier", &"wizard_level", {
			"max_hp": hp_per_level * steps,
			"attack_damage": damage_per_level * steps,
			"max_mana": mana_per_level * steps,
			"mana_regen": mana_regen_per_level * steps,
		})
		_sync_mana_stats()
	else:
		max_hp += hp_per_level
		attack_damage += damage_per_level
		max_mana += mana_per_level
		mana_regen += mana_regen_per_level
	_heal_by_gain(hp_before, max_hp_before, mana_before, max_mana_before)


## With the Stats pipeline, mana stats live on Wizard: copy them from get_stat().
func _sync_mana_stats() -> void:
	if not has_method(&"get_stat"):
		return
	var m := float(call(&"get_stat", &"max_mana"))
	if m > 0.0:
		max_mana = m
	var r := float(call(&"get_stat", &"mana_regen"))
	if r > 0.0:
		mana_regen = r
	mana = minf(mana, max_mana)


func _heal_by_gain(hp_before: float, max_hp_before: float, mana_before: float,
		max_mana_before: float) -> void:
	if is_alive():
		hp = clampf(hp_before + maxf(0.0, max_hp - max_hp_before), 0.0, max_hp)
		mana = clampf(mana_before + maxf(0.0, max_mana - max_mana_before), 0.0, max_mana)
	else:
		hp = minf(hp, max_hp)
		mana = minf(mana, max_mana)
	_update_hp_bar()


# ---------------------------------------------------------------- spells: ranks and learning

## Spell ids in slot order F / Q / E (from the SpellCaster when it has them).
func spell_ids() -> Array[StringName]:
	if spell_caster and spell_caster.has_method(&"spell_ids"):
		var from_caster: Array = spell_caster.call(&"spell_ids")
		if not from_caster.is_empty():
			var ids: Array[StringName] = []
			for id: Variant in from_caster:
				ids.append(StringName(str(id)))
			return ids
	return default_spell_ids


## 0 = not learned.
func spell_rank(spell_id: StringName) -> int:
	return int(_ranks.get(spell_id, 0))


## "" = can learn / rank up now, else (in this order) "Unknown spell", "Max rank", "Needs level n",
## "No spell points". Works while dead.
func can_learn(spell_id: StringName) -> String:
	var slot := spell_ids().find(spell_id)
	if slot < 0:
		return "Unknown spell"
	slot = mini(slot, SPELL_MAX_RANK.size() - 1)
	var rank := spell_rank(spell_id)
	if rank >= SPELL_MAX_RANK[slot]:
		return "Max rank"
	var needed: int = SPELL_LEVEL_REQUIRED[slot][rank]
	if level < needed:
		return "Needs level %d" % needed
	if spell_points <= 0:
		return "No spell points"
	return ""


## Spends 1 point to learn / rank up a spell. Same reasons as can_learn.
func learn_spell(spell_id: StringName) -> String:
	var reason := can_learn(spell_id)
	if reason != "":
		return reason
	spell_points -= 1
	var rank := spell_rank(spell_id) + 1
	_set_rank(spell_id, rank)
	spell_learned.emit(spell_id, rank)
	spell_points_changed.emit(spell_points)
	return ""


func _set_rank(spell_id: StringName, rank: int) -> void:
	_ranks[spell_id] = rank
	if spell_caster and spell_caster.has_method(&"set_rank"):
		spell_caster.call(&"set_rank", spell_id, rank)


## Casts a spell: "" = ok, else the reason (spells.md order; "Not learned" comes after
## "Unknown spell"). Delegates to the SpellCaster; without one only Fireball works (wave 1 rules).
func command_cast(spell_id: StringName, target: Variant) -> String:
	if spell_caster and spell_caster.has_method(&"cast"):
		if is_alive() and spell_ids().has(spell_id) and spell_rank(spell_id) <= 0:
			return "Not learned"
		_has_pending_cast = false
		return str(spell_caster.call(&"cast", spell_id, target))
	if not is_alive():
		return "Dead"
	if spell_id == &"fireball" and target is Vector3 and default_spell_ids.has(&"fireball"):
		return _legacy_fireball(target)
	return "Unknown spell"


## Direct control: while `dir` (world space, flattened, length 0-1) is non-zero the wizard walks
## that way at move_speed * length and drops her current order and pending cast. Vector3.ZERO =
## released: she stands still where she is and auto-aggro resumes. Call it every frame or on change.
func set_move_input(dir: Vector3) -> void:
	dir.y = 0.0
	if dir.length() > 1.0:
		dir = dir.normalized()
	elif dir.length() < 0.01:
		dir = Vector3.ZERO
	var was_moving := _move_input != Vector3.ZERO
	_move_input = dir
	if dir != Vector3.ZERO:
		_drop_orders()
	elif was_moving:
		_drop_orders()   # released: stand still here; auto-aggro picks targets again


func get_move_input() -> Vector3:
	return _move_input


func _drop_orders() -> void:
	_has_pending_cast = false
	attack_target = null
	_auto_target = false
	_has_move_order = false
	_attack_move = false
	_hold = false
	_anchor = global_position


func _direct_velocity() -> Vector3:
	if _move_input == Vector3.ZERO:
		return Vector3.INF
	return _move_input * move_speed


func _physics_process(delta: float) -> void:
	mana = min(max_mana, mana + mana_regen * delta)
	if _move_input != Vector3.ZERO and is_alive():
		_drop_orders()   # orders given while walking are ignored; the keys win
	if spell_caster == null and _has_pending_cast and _flat_distance(_pending_cast_pos) <= fireball_range:
		_has_pending_cast = false
		_has_move_order = false
		_anchor = global_position
		_launch_fireball(_pending_cast_pos)
	super._physics_process(delta)


## Returns "" on success, or a short reason the spell can't be cast. A wrapper of
## command_cast(&"fireball", target) once the SpellCaster exists.
func command_fireball(target: Vector3) -> String:
	if spell_caster and spell_caster.has_method(&"cast"):
		return command_cast(&"fireball", target)
	return _legacy_fireball(target)


func _legacy_fireball(target: Vector3) -> String:
	if not is_alive():
		return "Your wizard has fallen"
	if mana < fireball_cost:
		return "Not enough mana"
	if _flat_distance(target) <= fireball_range:
		_launch_fireball(target)
	else:
		# Walk into range first, then cast.
		super.command_move(target)
		_has_pending_cast = true
		_pending_cast_pos = target
	return ""


func command_move(target: Vector3) -> void:
	_has_pending_cast = false
	super.command_move(target)


## `target`: an enemy Unit or building (see Unit.command_attack).
func command_attack(target) -> void:
	_has_pending_cast = false
	super.command_attack(target)


func command_attack_move(target: Vector3) -> void:
	_has_pending_cast = false
	super.command_attack_move(target)


func command_hold() -> void:
	_has_pending_cast = false
	super.command_hold()


func command_stop() -> void:
	_has_pending_cast = false
	super.command_stop()


## Brings a dead wizard back at `at` (1v1 rules: the timer lives in main.gd): alive, full HP and
## mana, spells ready, no orders, selectable again. Artifacts and bonus stats she still carries are
## kept (the crown's owner removes its bonus with remove_bonus_stats when she dies). On a living
## wizard it just moves her there and heals her fully. Emits respawned(self).
func respawn(at: Vector3) -> void:
	_move_input = Vector3.ZERO
	_revive(at)
	mana = max_mana
	_reset_spells()
	respawned.emit(self)


## A dead wizard stays in the tree, hidden, until respawn().
func _on_death_finished() -> void:
	visible = false


## Clears spell state on respawn. Subclasses reset their own cooldowns too.
func _reset_spells() -> void:
	_has_pending_cast = false
	if spell_caster and spell_caster.has_method(&"reset_cooldowns"):
		spell_caster.call(&"reset_cooldowns")


## Carried bonuses (the Ember Crown: +100 max HP, +50 max mana). Raises the maxima and, if she is
## alive, heals HP and mana by the same amounts. With the Stats pipeline it is the modifier "crown".
func add_bonus_stats(bonus_hp: float, bonus_mana: float) -> void:
	if has_method(&"add_modifier"):
		var hp_before := hp
		var max_hp_before := max_hp
		var mana_before := mana
		var max_mana_before := max_mana
		call(&"add_modifier", &"crown", {"max_hp": bonus_hp, "max_mana": bonus_mana})
		_sync_mana_stats()
		_heal_by_gain(hp_before, max_hp_before, mana_before, max_mana_before)
		return
	max_hp += bonus_hp
	max_mana += bonus_mana
	if is_alive():
		hp = minf(max_hp, hp + bonus_hp)
		mana = minf(max_mana, mana + bonus_mana)
	_update_hp_bar()


## Undoes add_bonus_stats (works on a dead wizard too). HP and mana are capped to the new maxima.
func remove_bonus_stats(bonus_hp: float, bonus_mana: float) -> void:
	if has_method(&"remove_modifier"):
		call(&"remove_modifier", &"crown")
		_sync_mana_stats()
		hp = minf(hp, max_hp)
		mana = minf(mana, max_mana)
		_update_hp_bar()
		return
	max_hp = maxf(1.0, max_hp - bonus_hp)
	max_mana = maxf(0.0, max_mana - bonus_mana)
	hp = minf(hp, max_hp)
	mana = minf(mana, max_mana)
	_update_hp_bar()


func claim_artifact(artifact_name: String, bonus_mana: float, bonus_damage: float) -> void:
	artifacts.append(artifact_name)
	if has_method(&"set_base_stat"):
		call(&"set_base_stat", &"max_mana", float(call(&"get_base_stat", &"max_mana")) + bonus_mana)
		_sync_mana_stats()
	else:
		max_mana += bonus_mana
	mana = max_mana
	fireball_damage += bonus_damage
	heal(max_hp)
	artifact_claimed.emit(artifact_name)


func _launch_fireball(target: Vector3) -> void:
	if mana < fireball_cost:
		return
	mana -= fireball_cost
	_face(target - global_position)
	var fireball := Projectile.new()
	get_tree().current_scene.add_child(fireball)
	fireball.launch_at_point(self, global_position + Vector3.UP * body_height, target,
			fireball_damage, fireball_radius, orb_color)


func _build_visual() -> void:
	# Each wizard picks its own character model (Malrik overrides default_model_path).
	if model_scene == null and default_model_path != "" and ResourceLoader.exists(default_model_path):
		model_scene = load(default_model_path) as PackedScene
	super._build_visual()
	if model_scene:
		# The model's body_height is its (scaled) head top, art-units 1.1: the HP bar / chevrons hang above it.
		# Only ever raised (the collision capsule was already built from the default).
		var mh: Variant = _model.get(&"body_height") if _model else null
		if mh != null:
			body_height = maxf(body_height, float(mh))
		return
	# Pointy hat.
	var hat := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = radius * 1.4
	cone.height = 1.0
	hat.mesh = cone
	var hat_mat := StandardMaterial3D.new()
	hat_mat.albedo_color = hat_color
	hat.material_override = hat_mat
	hat.position.y = body_height + 0.35
	_visual.add_child(hat)

	# Staff with a glowing orb.
	var staff := MeshInstance3D.new()
	var stick := CylinderMesh.new()
	stick.top_radius = 0.05
	stick.bottom_radius = 0.05
	stick.height = body_height * 1.1
	staff.mesh = stick
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.35, 0.22, 0.12)
	staff.material_override = wood
	staff.position = Vector3(radius + 0.2, body_height * 0.55, 0.15)
	_visual.add_child(staff)

	var orb := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.18
	sphere.height = 0.36
	orb.mesh = sphere
	var orb_mat := StandardMaterial3D.new()
	orb_mat.albedo_color = orb_color
	orb_mat.emission_enabled = true
	orb_mat.emission = orb_color
	orb_mat.emission_energy_multiplier = 3.0
	orb.material_override = orb_mat
	orb.position = Vector3(radius + 0.2, body_height * 1.12, 0.15)
	_visual.add_child(orb)

	var light := OmniLight3D.new()
	light.light_color = orb_color
	light.omni_range = 4.0
	light.light_energy = 1.2
	light.position = orb.position
	_visual.add_child(light)


# ---------------------------------------------------------------- save / load (docs/design/save-load.md)

const SAVE_CROWN_ITEM := &"ember_crown"   ## Worn crown: the EmberCrown restores it (never the inventory row).


func save_snapshot(ids: Dictionary) -> Dictionary:
	var d := super(ids)
	var ranks := {}
	for id: Variant in _ranks:
		ranks[String(id)] = int(_ranks[id])
	var w := {
		"kingdom": String(kingdom), "level": level, "xp": xp, "total_xp": total_xp, "spell_points": spell_points,
		"ranks": ranks, "mana": mana, "path": String(str_int.get(&"path")) if str_int else "",
		"artifacts": artifacts.filter(func(a: String) -> bool: return a != "Ember Crown"),
	}
	var items: Array = []
	if inventory and &"slots" in inventory:
		var inv_slots: Array = inventory.get(&"slots")
		var inv_arts: Array = inventory.get(&"artifacts")
		for e: Variant in inv_slots + inv_arts:
			if e is Dictionary and (e as Dictionary).get("type") is ItemType:
				var t := (e as Dictionary)["type"] as ItemType
				if t.id != SAVE_CROWN_ITEM:
					items.append({"id": String(t.id), "count": int((e as Dictionary).get("count", 1)),
							"cd": float((e as Dictionary).get("cooldown_left", 0.0))})
	w["items"] = items
	d["wizard"] = w
	return d


func load_snapshot_base(d: Dictionary, nodes: Dictionary) -> void:
	super(d, nodes)
	var w: Dictionary = d.get("wizard", {})
	if w.is_empty():
		return
	level = clampi(int(w.get("level", level)), 1, MAX_LEVEL)
	xp = int(w.get("xp", 0))
	total_xp = int(w.get("total_xp", total_xp))
	spell_points = int(w.get("spell_points", spell_points))
	_apply_level_stats()
	var ranks: Dictionary = w.get("ranks", {})
	for id: Variant in ranks:
		_set_rank(StringName(str(id)), int(ranks[id]))
	artifacts.assign((w.get("artifacts", []) as Array).duplicate())
	var p := StringName(str(w.get("path", "")))
	if p != &"" and str_int and str_int.has_method(&"choose") and str_int.get(&"path") == &"":
		str_int.call(&"choose", p)
	if inventory and inventory.has_method(&"remove_item"):
		var n := (inventory.get(&"slots") as Array).size()
		for i in n:
			inventory.call(&"remove_item", i)
		for i in (inventory.get(&"artifacts") as Array).size():
			if inventory.call(&"get_type", 6 + i) != null and (inventory.call(&"get_type", 6 + i) as ItemType).id != SAVE_CROWN_ITEM:
				inventory.call(&"remove_item", 6 + i)
		for e: Variant in w.get("items", []):
			var t := ItemDrops.item_type(StringName(str((e as Dictionary).get("id", ""))))
			if t:
				inventory.call(&"add_item", t, int((e as Dictionary).get("count", 1)), float((e as Dictionary).get("cd", 0.0)))
	xp_changed.emit(xp, xp_to_next())
	spell_points_changed.emit(spell_points)
	_emit_level_changed()


func load_snapshot_late(d: Dictionary, nodes: Dictionary, crystal_nodes: Dictionary) -> void:
	super(d, nodes, crystal_nodes)
	var w: Dictionary = d.get("wizard", {})
	_sync_mana_stats()
	mana = clampf(float(w.get("mana", mana)), 0.0, max_mana)
	if not bool(d.get("alive", true)) and is_alive():
		death_guard = Callable()
		take_damage(hp + max_hp * 100.0, null)   # the level's respawn timer is restored after this
