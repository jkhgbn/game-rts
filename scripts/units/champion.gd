class_name Champion
extends Unit
## An autonomous hired hero (docs/design/champions.md, contract in section 13). The player never orders it:
## `is_commandable()` is false; its "Brain" child (scripts/ai/champion_brain.gd) drives it with the normal
## command_* calls. Levels 1-6 on the wizard XP curve (+8 % HP / damage per level, modifier
## "champion_level"), XP and loot from kills, a personal purse, a 4-slot Inventory, home / tavern rest.
## Build one with `ChampionType.find(id).create_champion(variant)` (or `Champion.new()` +
## `apply_champion_type(type, variant)`) BEFORE it enters the tree, then set `team`, add it, place it and
## call `command_stop()` (like main._spawn). Groups "units" (alive only), "champions" (alive or fallen) and
## "fog_sources" (FogOfWar stamps `sight_radius` while alive). Its hits (auto-attacks, projectiles) pass
## itself as the attacker, so bounty contributors and kill credit find it.
## A fallen champion stays in the tree, hidden, until `respawn(at)` (the guild's revive timer).
## Look (9.C10): `champion_type.model_scene` (art/units/champions/<id>/<id>.tscn) with set_variant(variant) and
## set_team_color(owner kingdom colour); Unit drives set_moving / play_attack (+ windup) / play_hit /
## play_death / revive, Champion play_level_up; ChampionAbilities play_cast(id) + ChampionVfx. Gold-framed
## world HP bar, never veterancy chevrons.
## Classes (step 11, docs/design/skills-rework.md): at level 2 (inside add_xp, before level_changed) it draws
## its class once with `ChampionClass.pick(self, class_rng)` (archetype weights + the bounties paid to it before
## level 2, `bounty_leans`); `set_champion_class(id)` swaps the weapon numbers, range, projectile, the modifier
## `class:<id>` and the flee threshold, and tells the model (`set_weapon_class`). Kept through death and revive.

## `intent` changed (brain rule R1-R9). `intent` is the text the UI shows ("Fighting", "Fallen"...).
signal intent_changed(champion: Champion, intent: StringName)
## The purse changed; `amount` = the new purse.
signal purse_changed(amount: int)
## As Wizard.xp_changed: `xp` is inside the current level, `xp_to_next` the bar size (0 at MAX).
signal xp_changed(xp: int, xp_to_next: int)
## Emitted by respawn(), once the champion is back (alive, full HP, cooldowns reset).
signal respawned(champion: Champion)
## Emitted once, by the level-2 draw (not by set_champion_class or a save restore), before level_changed.
signal class_chosen(champion: Champion, class_id: StringName)
# Inherited: level_changed(unit, level), died(unit), stats_changed, damage_taken...

const MAX_LEVEL := 6
## Model scale of a hired champion vs its army-scale model scene (in-game read at RTS zoom 30, 2026-09-30).
const MODEL_SCALE := 1.15
## Total XP to reach level i + 1 (index 0 = level 1): the step-9 curve x1.25 (skills-rework.md 9.2).
const LEVEL_TOTAL_XP: Array[int] = [0, 190, 500, 940, 1500, 2190]
## The class is drawn when the champion reaches this level (skills-rework.md 2.1).
const CLASS_DRAW_LEVEL := 2
const POWER_PER_CLASS_SKILL := 20.0    ## power() + 20 per unlocked class skill (skills-rework.md 6)
const CLASS_VFX_ID := &"class_chosen"  ## ChampionVfx.play id and bark trigger of the draw
const LEVEL_MODIFIER := &"champion_level"
const START_PURSE := 50
const TEAM_KILL_SHARE_RADIUS := 12.0   ## An own team's kill this close to the champion: 25 %.
const TEAM_KILL_SHARE := 0.25
const LOOT_RATIO := 0.25               ## Own killing blows: 25 % of the victim's XP value to the purse.
const DEATH_DROP_RATIO := 0.30         ## On death, 30 % of the purse goes to the killer.
const REST_PCT_PER_SECOND := 2.0       ## Home / tavern rest: 2 % of max HP per second.
const HOME_REST_RADIUS := 15.0         ## ... within 15 m of an own completed keep or barracks
const TAVERN_REST_RADIUS := 8.0        ## ... or within 8 m of a tavern door (either team).
const TAVERN_DOOR_FACTOR := 0.8        ## A tavern's door = its position x 0.8 (the side facing the crown).
const REST_CHECK_INTERVAL := 0.5
const INVENTORY_SLOTS := 4
const INVENTORY_ARTIFACTS := 0
const POWER_BASE := 150.0              ## power() = 150 + 50 x level + items' total value / 5 (8.2)
const POWER_PER_LEVEL := 50.0
const POWER_ITEM_DIVISOR := 5.0
const ABILITIES_PATH := "res://scripts/units/champion_abilities.gd"
const BRAIN_PATH := "res://scripts/ai/champion_brain.gd"
const INTENT_IDLE := &"Idle"
const INTENT_FALLEN := &"Fallen"
## World HP bar (9.C10): gold frame, 0.2 m tall, shown at full HP too.
const HP_FRAME_GOLD := Color(1.0, 0.82, 0.3)
const HP_BAR_HEIGHT_CHAMPION := 0.2
const HP_BAR_ALWAYS_VISIBLE := true

## The archetype (data/champions/<id>.tres). Set through apply_champion_type().
@export var champion_type: ChampionType
## 0 = name A, 1 = name B (the sibling). Change it with set_variant().
@export var variant := 0

## "Sable Quint" (unit_name is the same).
var display_name := ""
## All XP ever earned (`xp` is the part inside the current level, like Wizard).
var total_xp := 0
## Personal essence (champions.md 7). Change it only with add_purse / spend_purse.
var purse := START_PURSE
## What the brain is doing, as shown by the UI (`Idle`, `Fighting`, `Fleeing`, `Resting`, `Hunting bounty`...).
var intent: StringName = INTENT_IDLE
## The node the intent is about (bounty flag, target, building), or null.
var intent_target: Node3D = null
## The items (4 slots, 0 artifacts), child "Inventory".
var inventory: Inventory = null
## The "ChampionAbilities" child (scripts/units/champion_abilities.gd) or null when that script is missing.
var abilities: Node = null
## The "Brain" child (scripts/ai/champion_brain.gd) or null when that script is missing.
var brain: Node = null
## Set by the ChampionGuild after 3 unpaid upkeep ticks; the brain then ignores bounties (R5).
var is_unpaid := false
## Fog of war sight (m), from the type.
var sight_radius := 12.0
## Flee threshold (HP ratio), from the type.
var flee_pct := 0.35
## Stat growth per level (0.08), from the type.
var growth_pct := 0.08
## The class (null before the level-2 draw). Change it only with set_champion_class().
var champion_class: ChampionClass = null
## Bounty kind (&"hunt", &"explore", &"guard", &"escort") -> bounties of that kind paid to this champion before its
## class was chosen (each bounty counts once, even a Guard / Escort paid in ticks). Read by ChampionClass.weights_for.
var bounty_leans: Dictionary = {}
## The generator of the class draw (randomized at creation; tests may replace it or set its seed).
var class_rng := RandomNumberGenerator.new()
## Auto-attack bolt speed in m/s (the class's projectile_speed; 0 = the Unit default).
var projectile_speed := 0.0

var _type_applied := false
var _lean_bounties: Dictionary = {}   # Bounty instance id -> true (counted once each)
var _bounty_board: Node = null        # the own team's BountyBoard whose bounty_paid we listen to
var _rest_check_left := 0.0
var _resting_here := false
var _pending_items: Array = []   # save-state items waiting for the Inventory (apply before _ready)


func _init() -> void:
	add_to_group(&"champions")
	add_to_group(&"fog_sources")   # FogOfWar stamps `sight_radius` for `team` while is_alive()
	unit_name = "Champion"
	class_rng.randomize()


func _ready() -> void:
	if champion_type and not _type_applied:
		apply_champion_type(champion_type, variant)
	super._ready()
	_create_inventory()
	abilities = _create_child(ABILITIES_PATH, "ChampionAbilities")
	brain = _create_child(BRAIN_PATH, "Brain")
	_connect_bounty_board()


# ---------------------------------------------------------------- type and identity

## Copies the archetype's level-1 stats. Call it before the champion enters the tree (radius, height and
## the look are only built once). Keeps the current level (its growth is re-applied).
func apply_champion_type(type: ChampionType, variant_index: int = 0) -> void:
	if type == null:
		return
	champion_type = type
	_ensure_base()
	_base[&"max_hp"] = type.max_hp
	_base[&"move_speed"] = type.move_speed
	_base[&"attack_damage"] = type.attack_damage
	_base[&"attack_cooldown"] = type.attack_cooldown
	_base[&"armor"] = type.armor
	_recompute_stats(false)
	attack_range = type.attack_range
	aggro_range = type.aggro_range
	radius = type.radius
	body_height = type.body_height
	body_color = type.body_color
	eye_color = type.eye_color
	projectile_color = type.projectile_color
	model_scene = type.model_scene
	sight_radius = type.sight_radius
	flee_pct = type.flee_pct
	growth_pct = type.growth_pct
	_type_applied = true
	set_variant(variant_index)
	if level > 1:
		_apply_level_stats()
	if champion_class:
		_apply_class_weapon()   # the class keeps setting the weapon over the new archetype's


## Name A (0) or B (1); updates display_name / unit_name and the model's variant piece.
func set_variant(v: int) -> void:
	variant = clampi(v, 0, 1)
	if champion_type:
		display_name = champion_type.name_for(variant)
		unit_name = display_name
	if _model and _model.has_method(&"set_variant"):
		_model.call(&"set_variant", variant)


## "Sable Quint, the Coin-Cutter".
func full_name() -> String:
	return champion_type.full_name(variant) if champion_type else display_name


## The archetype id (&"coin_cutter"), or &"" before a type is applied.
func type_id() -> StringName:
	return champion_type.id if champion_type else &""


## Champions are never ordered by the player (champions.md 1).
func is_commandable() -> bool:
	return false


## No soldier veterancy (no chevrons, no soldiers' 8 m share): champions have their own levels.
func can_gain_veterancy() -> bool:
	return false


# ---------------------------------------------------------------- levels and XP (champions.md 5)

## Size of the current level's XP bar (190 at level 1 ... 690 at level 5); 0 at level 6 (the UI shows MAX).
func xp_to_next() -> int:
	if level >= MAX_LEVEL:
		return 0
	return LEVEL_TOTAL_XP[level] - LEVEL_TOTAL_XP[level - 1]


func is_max_level() -> bool:
	return level >= MAX_LEVEL


## HP / damage / ability multiplier of the current level: 1.00 at L1 ... 1.40 at L6.
func growth_mult() -> float:
	return 1.0 + growth_pct * float(level - 1)


## Adds XP (works while fallen). Each level: +8 % max HP and damage of the base (modifier
## "champion_level"), healed by the HP gained (only while alive), gold flash, model play_level_up,
## level_changed(self, level). Overflow carries over; nothing is gained at level 6.
## Reaching level 2 without a class draws it first (class_chosen, then level_changed).
func add_xp(amount: int) -> void:
	if amount <= 0 or level >= MAX_LEVEL:
		return
	total_xp += amount
	xp += amount
	while level < MAX_LEVEL and xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		_apply_level_stats()
		if level >= CLASS_DRAW_LEVEL and champion_class == null:
			_draw_class(true)
		_gold_flash = GOLD_FLASH_TIME
		_model_call(&"play_level_up")
		level_changed.emit(self, level)
	if level >= MAX_LEVEL:
		xp = 0
	xp_changed.emit(xp, xp_to_next())


## Told by Unit.award_soldier_kill_xp about every kill worth `value` XP. Killing blow by this champion:
## 100 % of the value as XP + LOOT_RATIO of it in the purse. Another kill by its team within 12 m of it:
## 25 % (rounded up, min 1). Returns the XP given.
func credit_kill(victim: Node3D, killer_node: Node3D, value: int) -> int:
	if value <= 0 or victim == null or not is_instance_valid(victim) \
			or killer_node == null or not is_instance_valid(killer_node):
		return 0
	var killer_team: Variant = killer_node.get(&"team")
	if killer_team == null or int(killer_team) != int(team):
		return 0
	var victim_team: Variant = victim.get(&"team")
	if victim_team != null and int(victim_team) == int(team):
		return 0
	if killer_node == self:
		add_xp(value)
		add_purse(roundi(float(value) * LOOT_RATIO))
		return value
	if _dead or _flat_distance(victim.global_position) > TEAM_KILL_SHARE_RADIUS:
		return 0
	var share := maxi(1, ceili(float(value) * TEAM_KILL_SHARE))
	add_xp(share)
	return share


func _apply_level_stats() -> void:
	var bonus := growth_pct * float(level - 1)
	if bonus <= 0.0:
		remove_modifier(LEVEL_MODIFIER)
	else:
		add_modifier(LEVEL_MODIFIER, {&"max_hp_pct": bonus, &"attack_damage_pct": bonus})


# ---------------------------------------------------------------- class (skills-rework.md 2, 3, 10)

## The class id (&"spear", &"sword_shield", &"two_hand", &"wizard"), or &"" before the level-2 draw.
func class_id() -> StringName:
	return champion_class.id if champion_class else &""


## Takes up class `id` (a ChampionClass id; &"" = back to the archetype weapon, for tests and tools):
## base attack damage and cooldown, attack range, projectile colour and speed, modifier `class:<id>`,
## flee threshold = the archetype's + the class delta, and the model's `set_weapon_class(id)` when it has it.
## Quiet by default (campaign companion, save restore): no class_chosen, no VFX, no bark. `announce` = true does
## what the level-2 draw does after it: class_chosen + the `class_chosen` VFX ring + the class bark.
## Idempotent (the same class again does nothing, not even the announce). Works at any level, in or out of the
## tree; a champion with a class never draws at level 2.
func set_champion_class(id: StringName, announce: bool = false) -> void:
	var cls: ChampionClass = null
	if id != &"":
		cls = ChampionClass.find(id)
		if cls == null:
			push_warning("Champion: unknown class '%s'" % id)
			return
	if cls == champion_class:
		return
	if champion_class:
		remove_modifier(champion_class.modifier_id())
	champion_class = cls
	_apply_class_weapon()
	_send_weapon_class()
	if cls:
		_disconnect_bounty_board()   # leans only count until the class
		if announce:
			_announce_class()


## True when the champion attacks from range: its class's weapon, or before the class its archetype's
## (Wayfinder, Mender). The brain's stance reads it.
func is_ranged() -> bool:
	if champion_class:
		return champion_class.is_ranged
	return (champion_type.attack_range if champion_type else attack_range) > 3.0


## Class skills unlocked at the current level (0 before the class; 1 / 2 / 3 at levels 2 / 3 / 5).
func class_skills_unlocked() -> int:
	return champion_class.skills_unlocked_at(level) if champion_class else 0


# The weapon numbers of the class (or of the archetype when there is none), then one stats recompute.
func _apply_class_weapon() -> void:
	_ensure_base()
	var cls := champion_class
	var type := champion_type
	if cls:
		_base[&"attack_damage"] = cls.attack_damage
		_base[&"attack_cooldown"] = cls.attack_cooldown
		attack_range = cls.attack_range
		if cls.is_ranged:
			projectile_color = cls.projectile_color
			projectile_speed = cls.projectile_speed
		else:
			projectile_speed = 0.0
			if type:
				projectile_color = type.projectile_color
		if type:
			flee_pct = type.flee_pct + cls.flee_delta
		add_modifier(cls.modifier_id(), cls.stats)   # recomputes every stat (with the new base)
		return
	projectile_speed = 0.0
	if type:
		_base[&"attack_damage"] = type.attack_damage
		_base[&"attack_cooldown"] = type.attack_cooldown
		attack_range = type.attack_range
		projectile_color = type.projectile_color
		flee_pct = type.flee_pct
	_recompute_stats(true)


# Tells the model which weapon to hold (11.V1 hook; &"" = the archetype weapon). No-op without the hook.
# The model's set_weapon_class also changes its attack_windup (0.12 for the Wizard staff, 0 for the melee classes, the
# archetype's back with &""), which Unit only reads once at build: re-read it (11.C5). A shot still waiting for the old
# release frame is dropped (the model cancels the old attack pose too).
func _send_weapon_class() -> void:
	if _model == null or not _model.has_method(&"set_weapon_class"):
		return
	_model.call(&"set_weapon_class", class_id())
	_refresh_model_windup()
	if _shot_left > 0.0:
		_shot_left = -1.0
		_shot_target = null


# Re-reads the model's ranged release delay (Unit._build_model reads it once), clamped like there.
func _refresh_model_windup() -> void:
	if _model == null:
		return
	var windup: Variant = _model.get(&"attack_windup")
	_model_windup = clampf(float(windup), 0.0, MAX_ATTACK_WINDUP) if windup != null else 0.0


# The level-2 draw (2.1). `announce`: class_chosen + the VFX ring + the class bark (2.2); the UI shows the message
# from class_chosen. A restore (old save) draws silently.
func _draw_class(announce: bool) -> void:
	var id := ChampionClass.pick(self, class_rng)
	if id != &"":
		set_champion_class(id, announce)


# class_chosen, then the VFX ring and the class bark (skills-rework.md 2.2).
func _announce_class() -> void:
	class_chosen.emit(self, class_id())
	if not is_inside_tree():
		return
	var vfx := get_tree().get_first_node_in_group(&"champion_vfx")
	if vfx and vfx.has_method(&"play"):
		vfx.call(&"play", CLASS_VFX_ID, self, self)   # unknown ids are ignored until 11.V6 adds it
	var barks := get_tree().get_first_node_in_group(&"champion_barks")
	if barks and barks.has_method(&"bark"):
		barks.call(&"bark", self, CLASS_VFX_ID)   # its 20 s cooldown then swallows the level-up bark


# Listens to the own team's BountyBoard (an existing one: never creates it) until the class is chosen.
func _connect_bounty_board() -> bool:
	if champion_class != null or not is_inside_tree():
		return false
	if _bounty_board != null and is_instance_valid(_bounty_board) and not _bounty_board.is_queued_for_deletion():
		var bt: Variant = _bounty_board.get(&"team")
		if bt != null and int(bt) == int(team):
			return true
		_disconnect_bounty_board()
	for node in get_tree().get_nodes_in_group(&"bounty_boards"):
		if node.is_queued_for_deletion() or not node.has_signal(&"bounty_paid"):
			continue
		var t: Variant = node.get(&"team")
		if t == null or int(t) != int(team):
			continue
		_bounty_board = node
		if not node.is_connected(&"bounty_paid", _on_bounty_paid):
			node.connect(&"bounty_paid", _on_bounty_paid)
		return true
	return false


func _disconnect_bounty_board() -> void:
	if _bounty_board != null and is_instance_valid(_bounty_board) \
			and _bounty_board.is_connected(&"bounty_paid", _on_bounty_paid):
		_bounty_board.disconnect(&"bounty_paid", _on_bounty_paid)
	_bounty_board = null


# BountyBoard.bounty_paid(bounty, champion, amount): each bounty paid to this champion before its class counts
# once for its kind (a Guard / Escort service pays in ticks).
func _on_bounty_paid(bounty: Variant, paid_champion: Variant, _amount: Variant) -> void:
	if champion_class != null or not is_instance_valid(bounty) or paid_champion != self:
		return
	var bid := (bounty as Object).get_instance_id()
	if _lean_bounties.has(bid):
		return
	var kind := ChampionClass.bounty_kind_name((bounty as Object).get(&"kind"))
	if kind == &"":
		return
	_lean_bounties[bid] = true
	bounty_leans[kind] = int(bounty_leans.get(kind, 0)) + 1


# ---------------------------------------------------------------- purse, intent, power

## Adds `n` essence to the purse (negative removes, never below 0). Emits purse_changed.
func add_purse(n: int) -> void:
	if n == 0:
		return
	purse = maxi(0, purse + n)
	purse_changed.emit(purse)


## Pays `n` from the purse: true if it had enough (then purse_changed), else false and nothing changes.
func spend_purse(n: int) -> bool:
	if n < 0 or purse < n:
		return false
	if n > 0:
		purse -= n
		purse_changed.emit(purse)
	return true


## Sets what the champion is doing (brain). Emits intent_changed when the id or the target changes.
func set_intent(id: StringName, target: Node3D = null) -> void:
	if id == intent and target == intent_target:
		return
	intent = id
	intent_target = target
	intent_changed.emit(self, intent)


## Strength for the brain and the bot (8.2, skills-rework.md 6): 150 + 50 x level + 20 x unlocked class skills
## + items' total value / 5 (L1 = 200; a level-5 champion with its class = 460 before items).
## `with_hp` = true multiplies it by the HP ratio (danger checks).
func power(with_hp: bool = false) -> float:
	var items := float(inventory.total_item_value()) if inventory else 0.0
	var p := POWER_BASE + POWER_PER_LEVEL * float(level) \
			+ POWER_PER_CLASS_SKILL * float(class_skills_unlocked()) + items / POWER_ITEM_DIVISOR
	if with_hp:
		p *= clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
	return p


## HP / max HP (0 when fallen).
func hp_ratio() -> float:
	return clampf(hp / maxf(1.0, max_hp), 0.0, 1.0) if is_alive() else 0.0


# ---------------------------------------------------------------- rest (champions.md 2, 8.1 R2)

## True within 15 m of an own completed keep or barracks, or within 8 m of a tavern door.
func is_at_rest_spot() -> bool:
	if not is_inside_tree():
		return false
	var r2 := HOME_REST_RADIUS * HOME_REST_RADIUS
	var me := global_position
	for node in get_tree().get_nodes_in_group(&"buildings"):
		var b := node as Building
		if b == null or int(b.team) != int(team) or b.building_type == null:
			continue
		var kind := b.building_type.kind
		if kind != &"keep" and kind != &"barracks":
			continue
		if not b.is_alive() or not b.is_constructed():
			continue
		var dx := b.global_position.x - me.x
		var dz := b.global_position.z - me.z
		if dx * dx + dz * dz <= r2:
			return true
	var t2 := TAVERN_REST_RADIUS * TAVERN_REST_RADIUS
	for node in get_tree().get_nodes_in_group(&"taverns"):
		var tavern := node as Node3D
		if tavern == null:
			continue
		var door := tavern_door(tavern)
		var ex := door.x - me.x
		var ez := door.z - me.z
		if ex * ex + ez * ez <= t2:
			return true
	return false


## The door point of a tavern: its `door_position()` if it has one, else its position x 0.8 (x and z).
static func tavern_door(tavern: Node3D) -> Vector3:
	if tavern.has_method(&"door_position"):
		return tavern.call(&"door_position")
	var p := tavern.global_position
	return Vector3(p.x * TAVERN_DOOR_FACTOR, p.y, p.z * TAVERN_DOOR_FACTOR)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _dead:
		return
	_rest_check_left -= delta
	if _rest_check_left <= 0.0:
		_rest_check_left += REST_CHECK_INTERVAL
		if _rest_check_left < 0.0:
			_rest_check_left = REST_CHECK_INTERVAL
		_resting_here = hp < max_hp and is_at_rest_spot()
		if champion_class == null and not is_instance_valid(_bounty_board):
			_connect_bounty_board()   # the board is created on demand, maybe after this champion
	if _resting_here and hp < max_hp:
		heal(max_hp * REST_PCT_PER_SECOND / 100.0 * delta)


# ---------------------------------------------------------------- death and revive (champions.md 3.3)

func die() -> void:
	if _dead:
		return
	_drop_purse_to_killer()
	_resting_here = false
	super.die()
	set_intent(INTENT_FALLEN, null)


# 30 % of the purse (rounded) goes to the killer champion's purse, else to the killer team's bank.
# Neutral killers (Ruin Wardens) and unknown killers take nothing: the purse is kept.
func _drop_purse_to_killer() -> void:
	if purse <= 0 or killer == null or not is_instance_valid(killer):
		return
	var killer_team: Variant = killer.get(&"team")
	if killer_team == null or int(killer_team) == int(team):
		return
	var n := roundi(float(purse) * DEATH_DROP_RATIO)
	if n <= 0:
		return
	# Helpers extend Champion but never spend a purse: their team's bank takes the drop (R2-4).
	if killer.is_in_group(&"champions") and not killer.is_in_group(&"helpers") and killer.has_method(&"add_purse"):
		add_purse(-n)
		killer.call(&"add_purse", n)
	elif int(killer_team) != Team.NEUTRAL:
		var bank := EssenceBank.for_team(int(killer_team))
		if bank:
			add_purse(-n)
			bank.add(n)


## Puts the champion in the fallen state quietly (a save restoring a champion that was already fallen, W2-6): no
## `died`, no Events.unit_died, no kill XP / purse drop / announcement. Hidden, out of "units", intent Fallen; the
## guild's revive (respawn) brings it back as after a normal death. Does nothing on a fallen champion.
func restore_fallen() -> void:
	if _dead:
		return
	killer = null
	_resting_here = false
	_enter_dead_state()
	_dots_at_death = {}
	_death_done = true
	_death_serial += 1
	_on_death_finished()
	set_intent(INTENT_FALLEN, null)


## A fallen champion stays in the tree, hidden, until respawn().
func _on_death_finished() -> void:
	visible = false


## Brings the champion back at `at` (ChampionGuild's revive; on a living one it just moves and heals it):
## full HP, same level / XP / items / purse, no orders, ability cooldowns reset, intent Idle.
func respawn(at: Vector3) -> void:
	_revive(at)
	_rest_check_left = 0.0
	if abilities and abilities.has_method(&"reset_cooldowns"):
		abilities.call(&"reset_cooldowns")
	set_intent(INTENT_IDLE, null)
	respawned.emit(self)


# ---------------------------------------------------------------- save state

## Everything a save / the campaign needs (JSON-safe): id, variant, level, xp, total_xp, purse, hp_ratio,
## alive, items [{id, count, slot}], class ("" before level 2), bounty_leans ({"guard": 2}).
func get_save_state() -> Dictionary:
	var items: Array = []
	if inventory:
		for i in inventory.slots.size():
			var e: Variant = inventory.slots[i]
			if e is Dictionary:
				items.append({"id": String((e["type"] as ItemType).id), "count": int(e["count"]), "slot": i})
	var leans := {}
	for k: Variant in bounty_leans:
		leans[str(k)] = int(bounty_leans[k])
	return {
		"class": String(class_id()),
		"bounty_leans": leans,
		"id": String(type_id()),
		"variant": variant,
		"level": level,
		"xp": xp,
		"total_xp": total_xp,
		"purse": purse,
		"hp_ratio": hp_ratio() if is_alive() else 1.0,
		"alive": is_alive(),
		"items": items,
	}


## Restores get_save_state(): type (if different, before the tree only), variant, level (growth
## re-applied, no heal), class (no class_chosen, VFX or bark; a save past level 2 without one draws it
## quietly), bounty leans, XP, purse, HP ratio and items (the inventory is emptied first).
func apply_save_state(d: Dictionary) -> void:
	var tid := StringName(str(d.get("id", "")))
	if tid != &"" and tid != type_id():
		var t := ChampionType.find(tid)
		if t:
			apply_champion_type(t, int(d.get("variant", variant)))
	set_variant(int(d.get("variant", variant)))
	var old_level := level
	level = clampi(int(d.get("level", level)), 1, MAX_LEVEL)
	xp = 0 if level >= MAX_LEVEL else maxi(0, int(d.get("xp", 0)))
	total_xp = maxi(int(d.get("total_xp", LEVEL_TOTAL_XP[level - 1] + xp)), 0)
	_apply_level_stats()
	var raw_leans: Variant = d.get("bounty_leans", null)
	if raw_leans is Dictionary:
		bounty_leans = {}
		for k: Variant in raw_leans:
			var kind := ChampionClass.bounty_kind_name(k)
			if kind != &"" and int((raw_leans as Dictionary)[k]) > 0:
				bounty_leans[kind] = int((raw_leans as Dictionary)[k])
	if d.has("class"):
		var cid := StringName(str(d.get("class", "")))
		if cid != &"":
			set_champion_class(cid)
		elif level < CLASS_DRAW_LEVEL:
			set_champion_class(&"")
	if champion_class == null and level >= CLASS_DRAW_LEVEL:
		_draw_class(false)   # an old (step-9) save of a champion past level 2: draw quietly
	if is_node_ready() and is_alive():
		hp = clampf(max_hp * float(d.get("hp_ratio", 1.0)), 1.0, max_hp)
		_update_hp_bar()
	purse = maxi(0, int(d.get("purse", purse)))
	purse_changed.emit(purse)
	var raw_items: Variant = d.get("items", [])
	_pending_items = (raw_items as Array).duplicate(true) if raw_items is Array else []
	if inventory:
		_restore_items()
	xp_changed.emit(xp, xp_to_next())
	if level != old_level:
		level_changed.emit(self, level)


func _restore_items() -> void:
	var list := _pending_items
	_pending_items = []
	for i in inventory.slots.size():
		if inventory.slots[i] != null:
			inventory.remove_item(i)
	list.sort_custom(func(a: Variant, b: Variant) -> bool:
		return int((a as Dictionary).get("slot", 0)) < int((b as Dictionary).get("slot", 0)))
	for entry: Variant in list:
		if not entry is Dictionary:
			continue
		var t := ItemType.find(StringName(str((entry as Dictionary).get("id", ""))))
		if t:
			inventory.add_item(t, maxi(1, int((entry as Dictionary).get("count", 1))))


# ---------------------------------------------------------------- children

# The items: 4 slots, 0 artifacts (Inventory detects champion owners; set explicitly when it can),
# bought from the purse with the 20 % tithe (items-coder, 9.C6).
func _create_inventory() -> void:
	inventory = Inventory.ensure_for(self)
	if inventory and inventory.has_method(&"set_slot_counts"):
		inventory.call(&"set_slot_counts", INVENTORY_SLOTS, INVENTORY_ARTIFACTS)
	if inventory and not _pending_items.is_empty():
		_restore_items()


# Creates child `node_name` from the script at `path` when it exists (like Wizard's SpellCaster), then
# calls its `setup(champion)` (or `setup()`) if it has one.
func _create_child(path: String, node_name: String) -> Node:
	var existing := get_node_or_null(NodePath(node_name))
	if existing:
		return existing
	if not ResourceLoader.exists(path):
		return null
	var script := load(path) as Script
	if script == null or not script.can_instantiate():
		return null
	var node := script.new() as Node
	if node == null:
		return null
	node.name = node_name
	add_child(node)
	if node.has_method(&"setup"):
		var args := 1
		var required := 1
		for m: Dictionary in node.get_method_list():
			if m.get("name", "") == "setup":
				args = (m.get("args", []) as Array).size()
				required = args - (m.get("default_args", []) as Array).size()
				break
		if args >= 1 and required <= 1:
			node.call(&"setup", self)
		elif args == 0:
			node.call(&"setup")
		else:
			push_warning("Champion: %s.setup() needs %d arguments, expected (champion)" % [node_name, required])
	return node


# ---------------------------------------------------------------- look (task 9.C10)

## The owner's kingdom (its wizard's `kingdom`; else the skirmish's `player_kingdom` / `enemy_kingdom`;
## else fire for the player, shadow for the enemy). Its colour goes to the model's set_team_color.
func owner_kingdom() -> StringName:
	return _team_kingdom()   # Unit's rule (wizard, 2v2 seat_kingdom, skirmish kingdoms): one copy (review L6)


# The owner's kingdom colour for the sash / the model's set_team_color (Unit._build_model sends it).
func _kingdom_color() -> Color:
	return kingdom_color_for(team, owner_kingdom())   # G-E: the alt palette in a mirror match


## Re-sends the owner's kingdom colour to the model (e.g. after the owner's wizard appeared).
func refresh_team_color() -> void:
	if _model and _model.has_method(&"set_team_color"):
		_model.call(&"set_team_color", _kingdom_color())


func _build_visual() -> void:
	super._build_visual()
	if _model:
		# In-game grade 2026-09-30: champions read as small slabs at RTS zoom 30; the hired heroes stand 15 % taller
		# than their army-scale model (ChampionType.body_height is the scaled height: HP bar, click box).
		_model.scale = Vector3.ONE * MODEL_SCALE
		if _model.has_method(&"set_variant"):
			_model.call(&"set_variant", variant)
		if champion_class:
			_send_weapon_class()   # a class applied before the tree (save, campaign companion)
		return
	_build_placeholder_props()


## Ranged champions (Wayfinder, Mender) shoot from the model's release point when it has one (the Mender's
## censer, get_beam_origin()); else from the Unit default (3/4 of the height). With a class weapon (11.C5) the
## model's get_weapon_tip() comes first (the Wizard staff's crystal; the Mender's censer is hidden then).
func _shot_origin() -> Vector3:
	if champion_class and _model and _model.has_method(&"get_weapon_tip"):
		var tip: Variant = _model.call(&"get_weapon_tip")
		if tip is Vector3:
			return tip
	if _model and _model.has_method(&"get_beam_origin"):
		var p: Variant = _model.call(&"get_beam_origin")
		if p is Vector3:
			return p
	return super._shot_origin()


## The Wizard class's bolt flies at its own speed (26 m/s); every other shot is the Unit's.
func _spawn_shot(target: Node3D) -> void:
	if projectile_speed <= 0.0:
		super._spawn_shot(target)
		return
	var bolt := Projectile.new()
	get_tree().current_scene.add_child(bolt)
	bolt.launch_at_target(self, _shot_origin(), target, attack_damage, projectile_color, 0.14, projectile_speed)
	bolt.hit_unit.connect(_on_attack_hit)


## The world HP bar: gold frame, a black line inside it, a little taller than a soldier's (champions.md 9.C10).
func _hp_bar_frame_style() -> Dictionary:
	return {"color": HP_FRAME_GOLD, "height": HP_BAR_HEIGHT_CHAMPION, "frame": 0.03, "inner": 0.012,
			"fade_min": HP_BAR_FADE_MIN_HERO, "min_width": HP_BAR_MIN_WIDTH_HERO}


## Champions keep their bar on screen while alive (the gold frame tells them apart from soldiers).
func _hp_bar_always_visible() -> bool:
	return HP_BAR_ALWAYS_VISIBLE


## True: the world HP bar has the gold champion frame.
func has_gold_hp_frame() -> bool:
	return hp_bar_frame_color().is_equal_approx(HP_FRAME_GOLD)


## No veterancy chevrons on champions (champions.md 4): they have their own level badge in the UI.
func _update_chevrons() -> void:
	if _chevrons:
		_chevrons.visible = false


# Fallback when the type has no model_scene (9.C10 plugs art/units/champions/<id>/<id>.tscn): the capsule
# (palette colour) + a team sash + the role's silhouette piece (champions.md 4.6). No lights, no shadows.
func _build_placeholder_props() -> void:
	var sash := _prop(BoxMesh.new(), _kingdom_color(), Vector3(0.0, body_height * 0.55, 0.0))
	(sash.mesh as BoxMesh).size = Vector3(radius * 2.15, 0.14, radius * 2.15)
	sash.rotation.z = 0.35
	var id := type_id()
	match id:
		&"wayfinder":
			var brim := CylinderMesh.new()
			brim.top_radius = radius * 1.7
			brim.bottom_radius = radius * 1.7
			brim.height = 0.05
			_prop(brim, Color(0.22, 0.18, 0.14), Vector3(0.0, body_height + 0.02, 0.0))
			var crown := CylinderMesh.new()
			crown.top_radius = radius * 0.6
			crown.bottom_radius = radius * 0.8
			crown.height = 0.25
			_prop(crown, Color(0.22, 0.18, 0.14), Vector3(0.0, body_height + 0.15, 0.0))
			var pole := CylinderMesh.new()
			pole.top_radius = 0.03
			pole.bottom_radius = 0.03
			pole.height = 1.8
			_prop(pole, Color(0.40, 0.26, 0.14), Vector3(0.0, 1.7, -radius - 0.05))
			var lantern := SphereMesh.new()
			lantern.radius = 0.1
			lantern.height = 0.2
			_prop(lantern, Color(1.0, 0.8, 0.4), Vector3(0.0, 2.6, -radius - 0.05), true)
		&"oathwall":
			var shield := BoxMesh.new()
			shield.size = Vector3(0.9, 1.4, 0.08)
			_prop(shield, Color(0.36, 0.24, 0.12), Vector3(-radius * 0.4, body_height * 0.45, radius + 0.12))
			var rune := SphereMesh.new()
			rune.radius = 0.08
			rune.height = 0.16
			_prop(rune, Color(0.6, 0.85, 1.0), Vector3(-radius * 0.4, body_height * 0.5, radius + 0.18), true)
		&"coin_cutter":
			var hood := CylinderMesh.new()
			hood.top_radius = 0.0
			hood.bottom_radius = radius * 1.05
			hood.height = 0.55
			_prop(hood, Color(0.16, 0.15, 0.17), Vector3(0.0, body_height + 0.1, -0.05))
			var sack := SphereMesh.new()
			sack.radius = 0.2
			sack.height = 0.4
			_prop(sack, Color(0.70, 0.55, 0.25), Vector3(radius + 0.05, body_height * 0.4, -0.1))
		&"mender":
			var pack := BoxMesh.new()
			pack.size = Vector3(0.6, 0.7, 0.35)
			_prop(pack, Color(0.55, 0.40, 0.20), Vector3(0.0, body_height * 0.62, -radius - 0.12))
			var jar := SphereMesh.new()
			jar.radius = 0.11
			jar.height = 0.22
			_prop(jar, Color(0.5, 1.0, 0.6), Vector3(0.0, body_height * 0.62 + 0.45, -radius - 0.12), true)


func _prop(mesh: Mesh, color: Color, pos: Vector3, glow: bool = false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	if glow:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.5
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos
	_visual.add_child(mi)
	return mi
