class_name ItemPassives
extends Node
## Item passives and auras (docs/design/items.md, task 4.G1). The Inventory (scripts/items/) calls
##   ItemPassives.attach(wizard, passive_id, source_id)   when an item enters a slot,
##   ItemPassives.detach(wizard, passive_id, source_id)   when it leaves (or detach_source(wizard, source_id)).
## `passive_id`: a passive id below, an item id (its bundle, e.g. `&"inferno_blade"` = feed_15 +
## searing_strikes_2), or a comma list (`"feed_15,searing_strikes_2"`). `source_id`: the slot's
## modifier id (`&"item:3"`). Unknown / empty ids are ignored (attach returns false).
## Unique rule: the same passive (same family) never stacks; the highest rank wins (Searing Strikes II
## over Searing Strikes, Feed 15 % over 12 %, Rally II over Rally). Removing the last source ends it.
## State lives in one child node "ItemPassives" per wizard, created on the first attach.
##
## Passive ids: searing_strikes, searing_strikes_2, feed (12 %), feed_15, quiet_step, rally, rally_2,
## spell_drain, afterglow, smoulder, spell_feed, rekindle (aliases: *_ii, feed_12, searing_strikes_1);
## Ice: numbing_touch, frostbite, frost_ward; Nature: barbs, blossom (read through heal_multiplier()),
## verdant_ward.

const NODE_NAME := "ItemPassives"

## id -> data. "family" = the unique name, "rank" = which one wins inside a family.
const PASSIVES := {
	&"searing_strikes": {"family": &"burn", "rank": 1, "per_tick": 4.0, "interval": 0.5, "duration": 2.0,
			"jump": 0.0},
	&"searing_strikes_2": {"family": &"burn", "rank": 2, "per_tick": 6.0, "interval": 0.5, "duration": 3.0,
			"jump": 2.0},
	&"feed": {"family": &"feed", "rank": 12, "lifesteal": 12.0},
	&"feed_15": {"family": &"feed", "rank": 15, "lifesteal": 15.0},
	&"quiet_step": {"family": &"quiet_step", "rank": 1, "delay": 5.0, "move_speed": 1.0},
	&"rally": {"family": &"rally", "rank": 1, "radius": 8.0, "stats": {&"attack_damage_pct": 0.10}},
	&"rally_2": {"family": &"rally", "rank": 2, "radius": 10.0,
			"stats": {&"attack_damage_pct": 0.15, &"hp_regen": 1.0}},
	&"spell_drain": {"family": &"spell_drain", "rank": 1, "mana": 3.0, "max_per_cast": 15.0},
	&"afterglow": {"family": &"afterglow", "rank": 1, "move_speed": 1.0, "duration": 2.0},
	&"smoulder": {"family": &"smoulder", "rank": 1, "duration": 1.5},
	&"spell_feed": {"family": &"spell_feed", "rank": 1, "spell_feed": 15.0},
	&"rekindle": {"family": &"rekindle", "rank": 1, "hp_ratio": 0.4, "damage": 80.0, "radius": 4.0,
			"cooldown": 240.0},
	# Ice items (kingdom-ice.md, 7.I1)
	&"numbing_touch": {"family": &"numbing_touch", "rank": 1, "status": &"chill", "duration": 1.5},
	&"frostbite": {"family": &"frostbite", "rank": 1, "status": &"chill", "duration": 1.5},
	&"frost_ward": {"family": &"frost_ward", "rank": 1, "radius": 8.0, "stats": {&"armor": 10.0}},
	# Nature items (kingdom-nature.md 5, 8.I1)
	&"barbs": {"family": &"barbs", "rank": 1, "ratio": 0.2, "melee_range": 3.0},
	&"blossom": {"family": &"blossom", "rank": 1, "heal_mult": 1.25},
	&"verdant_ward": {"family": &"verdant_ward", "rank": 1, "radius": 10.0, "stats": {&"hp_regen": 2.0}},
	# Campaign artifact (mission-02.md "Reward": Stillwater Orb): chill / frozen on the wearer last x 0.5 (after the
	# hero half rule), through Unit.STATUS_TIME_MULT_META.
	&"stillwater": {"family": &"stillwater", "rank": 1, "status_mult": {&"chill": 0.5, &"frozen": 0.5}},
}
const ALIASES := {
	&"searing_strikes_ii": &"searing_strikes_2", &"searing_strikes_1": &"searing_strikes",
	&"rally_ii": &"rally_2", &"rally_1": &"rally", &"feed_12": &"feed",
}
## Item id -> its passives (items.md tables), so an ItemType may simply use its own id.
const ITEM_BUNDLES := {
	&"blazing_edge": [&"searing_strikes"],
	&"nightveil_cloak": [&"quiet_step"],
	&"grave_pact": [&"feed"],
	&"warlords_horn": [&"rally"],
	&"siphon_idol": [&"spell_drain"],
	&"emberwake_band": [&"afterglow"],
	&"inferno_blade": [&"feed_15", &"searing_strikes_2"],
	&"shadowstride": [&"quiet_step"],
	&"staff_of_cinders": [&"afterglow", &"smoulder"],
	&"banner_of_embers": [&"rally_2"],
	&"gravemaw_idol": [&"feed", &"spell_drain", &"spell_feed"],
	&"phoenix_plume": [&"afterglow", &"rekindle"],
	&"oath_of_embers": [&"searing_strikes"],
	&"rimebound_bracers": [&"numbing_touch"],
	&"glacier_heart": [&"frostbite"],
	&"winterwall_aegis": [&"frost_ward"],
	&"thornweave_vest": [&"barbs"],
	&"bloomcaller_staff": [&"blossom"],
	&"heart_of_the_grove": [&"verdant_ward"],
	&"stillwater_orb": [&"stillwater"],
}
const MOD_FEED := &"passive:feed"
const MOD_SPELL_FEED := &"passive:spell_feed"
const MOD_QUIET := &"passive:quiet_step"
const MOD_AFTERGLOW := &"passive:afterglow"
const RALLY_AURA := &"rally"   # receivers get the modifier "aura:rally"
const FROST_WARD_AURA := &"frost_ward"
const VERDANT_WARD_AURA := &"verdant_ward"

var wizard: Unit

var _sources: Dictionary = {}     # StringName passive id -> {source_id: true}
var _active: Dictionary = {}      # StringName family -> StringName winning passive id
var _quiet_on := false
var _afterglow_left := 0.0
var _drain_left := 0.0            # mana Spell Drain may still give for the current cast
var _rekindle_cd := 0.0
var _shield_seen := 0.0           # Barbs: the wizard's shield before the current hit
var _absorbed := 0.0              # Barbs: shield the current hit used up
var _in_barbs := false


# ---------------------------------------------------------------- static API (Inventory)

## Attaches the passive(s) `passive_id` from `source_id` to `wizard`. True if one was known.
static func attach(p_wizard: Node, passive_id: Variant, source_id: Variant) -> bool:
	var ids := expand(passive_id)
	if ids.is_empty() or p_wizard == null or not is_instance_valid(p_wizard) or not p_wizard is Unit:
		return false
	var state := for_wizard(p_wizard, true)
	var src := StringName(str(source_id))
	for id in ids:
		if not state._sources.has(id):
			state._sources[id] = {}
		(state._sources[id] as Dictionary)[src] = true
	state._refresh()
	return true


## Removes what attach(wizard, passive_id, source_id) added.
static func detach(p_wizard: Node, passive_id: Variant, source_id: Variant) -> void:
	var state := for_wizard(p_wizard, false)
	if state == null:
		return
	var src := StringName(str(source_id))
	for id in expand(passive_id):
		var s: Dictionary = state._sources.get(id, {})
		s.erase(src)
		if s.is_empty():
			state._sources.erase(id)
	state._refresh()


## Removes every passive `source_id` gave (e.g. the item left slot 3: detach_source(w, &"item:3")).
static func detach_source(p_wizard: Node, source_id: Variant) -> void:
	var state := for_wizard(p_wizard, false)
	if state == null:
		return
	var src := StringName(str(source_id))
	for id: StringName in state._sources.keys():
		var s: Dictionary = state._sources[id]
		s.erase(src)
		if s.is_empty():
			state._sources.erase(id)
	state._refresh()


## The passive ids a value stands for (aliases, item bundles and comma lists resolved; unknown dropped).
static func expand(passive_id: Variant) -> Array[StringName]:
	var out: Array[StringName] = []
	if passive_id == null:
		return out
	var parts: Array = []
	if passive_id is Array:
		parts = passive_id
	else:
		parts = Array(str(passive_id).split(",", false))
	for part: Variant in parts:
		var key := StringName(str(part).strip_edges().to_lower().replace(" ", "_").replace("'", ""))
		if key == &"":
			continue
		if ITEM_BUNDLES.has(key):
			for id: StringName in ITEM_BUNDLES[key]:
				if not out.has(id):
					out.append(id)
			continue
		key = ALIASES.get(key, key)
		if PASSIVES.has(key) and not out.has(key):
			out.append(key)
	return out


static func is_known(passive_id: Variant) -> bool:
	return not expand(passive_id).is_empty()


## The wizard's state node (null when none and `create` is false).
static func for_wizard(p_wizard: Node, create: bool = false) -> ItemPassives:
	if p_wizard == null or not is_instance_valid(p_wizard):
		return null
	var state := p_wizard.get_node_or_null(NodePath(NODE_NAME)) as ItemPassives
	if state == null and create:
		state = ItemPassives.new()
		state.name = NODE_NAME
		state.wizard = p_wizard as Unit
		p_wizard.add_child(state)
		state._connect()
	return state


## Winning passive ids now on `wizard` (one per family).
static func active_ids(p_wizard: Node) -> Array[StringName]:
	var out: Array[StringName] = []
	var state := for_wizard(p_wizard, false)
	if state:
		for fam: StringName in state._active:
			out.append(state._active[fam])
	return out


## Blossom: what the wizard's SPELL heals and shields are multiplied by, after spell_power (1.25 with
## a Bloomcaller Staff, else 1.0). Spell code (Wild Bloom, Rime Aegis...) calls it per cast / tick;
## item actives (Overgrowth, Rallying Cry) and support autocasts do not use it.
static func heal_multiplier(p_wizard: Node) -> float:
	var state := for_wizard(p_wizard, false)
	if state == null:
		return 1.0
	var b := state._data(&"blossom")
	return float(b["heal_mult"]) if not b.is_empty() else 1.0


## Seconds before a passive with a cooldown (rekindle) works again; 0 = ready or not carried.
static func cooldown_left(p_wizard: Node, passive_id: Variant) -> float:
	var state := for_wizard(p_wizard, false)
	if state and expand(passive_id).has(&"rekindle"):
		return state._rekindle_cd
	return 0.0


# ---------------------------------------------------------------- state

func _connect() -> void:
	wizard.attack_landed.connect(_on_attack_landed)
	if wizard.has_signal(&"spell_hit"):
		wizard.connect(&"spell_hit", _on_spell_hit)
	if wizard.has_signal(&"spell_cast"):
		wizard.connect(&"spell_cast", _on_spell_cast)
	wizard.damage_taken.connect(_on_damage_taken)
	wizard.shield_changed.connect(_on_shield_changed)
	_shield_seen = wizard.shield


func _data(family: StringName) -> Dictionary:
	var id: Variant = _active.get(family)
	return PASSIVES[id] if id != null else {}


# Picks the winner of each family and (re)applies the lasting effects.
func _refresh() -> void:
	_active.clear()
	for id: StringName in _sources:
		var d: Dictionary = PASSIVES[id]
		var fam: StringName = d["family"]
		var cur: Variant = _active.get(fam)
		if cur == null or int(d["rank"]) > int(PASSIVES[cur]["rank"]):
			_active[fam] = id
	if not is_instance_valid(wizard):
		return
	var feed := _data(&"feed")
	if feed.is_empty():
		wizard.remove_modifier(MOD_FEED)
	else:
		wizard.add_modifier(MOD_FEED, {&"lifesteal": feed["lifesteal"]})
	var sfeed := _data(&"spell_feed")
	if sfeed.is_empty():
		wizard.remove_modifier(MOD_SPELL_FEED)
	else:
		wizard.add_modifier(MOD_SPELL_FEED, {&"spell_feed": sfeed["spell_feed"]})
	var rally := _data(&"rally")
	if rally.is_empty():
		wizard.remove_aura(RALLY_AURA)
	else:
		wizard.apply_aura(RALLY_AURA, float(rally["radius"]), rally["stats"], &"soldiers")
	var ward := _data(&"frost_ward")
	if ward.is_empty():
		wizard.remove_aura(FROST_WARD_AURA)
	else:
		wizard.apply_aura(FROST_WARD_AURA, float(ward["radius"]), ward["stats"], &"soldiers")
	var verdant := _data(&"verdant_ward")
	if verdant.is_empty():
		wizard.remove_aura(VERDANT_WARD_AURA)
	else:
		wizard.apply_aura(VERDANT_WARD_AURA, float(verdant["radius"]), verdant["stats"], &"soldiers")
	var still := _data(&"stillwater")
	if still.is_empty():
		if wizard.has_meta(Unit.STATUS_TIME_MULT_META):
			wizard.remove_meta(Unit.STATUS_TIME_MULT_META)
	else:
		wizard.set_meta(Unit.STATUS_TIME_MULT_META, (still["status_mult"] as Dictionary).duplicate())
	if not _active.has(&"quiet_step") and _quiet_on:
		_quiet_on = false
		wizard.remove_modifier(MOD_QUIET)
	if not _active.has(&"afterglow") and _afterglow_left > 0.0:
		_afterglow_left = 0.0
		wizard.remove_modifier(MOD_AFTERGLOW)
	wizard.death_guard = _try_rekindle if _active.has(&"rekindle") else Callable()
	set_physics_process(not _active.is_empty() or _rekindle_cd > 0.0)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(wizard):
		return
	if _rekindle_cd > 0.0:   # keeps running while dead (items.md "Death")
		_rekindle_cd = maxf(0.0, _rekindle_cd - delta)
	if _active.has(&"quiet_step"):
		var q := _data(&"quiet_step")
		var want := wizard.is_alive() and wizard.seconds_since_damage() >= float(q["delay"])
		if want != _quiet_on:
			_quiet_on = want
			if want:
				wizard.add_modifier(MOD_QUIET, {&"move_speed": q["move_speed"]})
			else:
				wizard.remove_modifier(MOD_QUIET)
	if _afterglow_left > 0.0:
		_afterglow_left -= delta
		if _afterglow_left <= 0.0:
			wizard.remove_modifier(MOD_AFTERGLOW)


func _on_attack_landed(target: Node3D, _amount: float) -> void:
	var numb := _data(&"numbing_touch")
	if not numb.is_empty() and target is Unit and (target as Unit).is_alive():
		(target as Unit).apply_status(numb["status"], float(numb["duration"]))
	var burn := _data(&"burn")
	if burn.is_empty() or not is_instance_valid(target) or not target.has_method(&"apply_dot"):
		return
	target.call(&"apply_dot", &"burn", float(burn["per_tick"]), float(burn["interval"]),
			float(burn["duration"]), wizard, float(burn["jump"]))


func _on_spell_cast(_spell_id: StringName) -> void:
	var drain := _data(&"spell_drain")
	_drain_left = float(drain["max_per_cast"]) if not drain.is_empty() else 0.0
	var glow := _data(&"afterglow")
	if not glow.is_empty():
		if _afterglow_left <= 0.0:
			wizard.add_modifier(MOD_AFTERGLOW, {&"move_speed": glow["move_speed"]})
		_afterglow_left = float(glow["duration"])


func _on_spell_hit(target: Node3D, _amount: float, _spell_id: StringName) -> void:
	if not target is Unit:
		return
	var bite := _data(&"frostbite")
	if not bite.is_empty() and _amount > 0.0 and wizard.is_enemy_of(target):
		(target as Unit).apply_status(bite["status"], float(bite["duration"]))
	var smoulder := _data(&"smoulder")
	if not smoulder.is_empty():
		(target as Unit).apply_status(&"smoulder", float(smoulder["duration"]))
	var drain := _data(&"spell_drain")
	if not drain.is_empty() and _drain_left > 0.0 and wizard.is_alive():
		var gain := minf(float(drain["mana"]), _drain_left)
		_drain_left -= gain
		var max_mana: Variant = wizard.get(&"max_mana")
		var mana: Variant = wizard.get(&"mana")
		if mana != null and max_mana != null:
			wizard.set(&"mana", minf(float(max_mana), float(mana) + gain))


func _on_shield_changed(amount: float) -> void:
	# Unit.take_damage emits shield_changed (absorbed) right before damage_taken, in the same call.
	# A drop without a hit (expiry, replaced by a smaller shield) is forgotten at the end of the frame.
	if amount < _shield_seen:
		if _absorbed <= 0.0:
			_forget_absorbed.call_deferred()
		_absorbed += _shield_seen - amount
	_shield_seen = amount


func _forget_absorbed() -> void:
	_absorbed = 0.0


# Barbs: a melee auto-attacker (a Unit with attack_range <= 3, i.e. no projectile) takes 20 % of the
# damage it dealt (HP lost + shield absorbed, after armor), credited to the wizard.
func _on_damage_taken(amount: float, attacker: Node3D) -> void:
	var absorbed := _absorbed
	_absorbed = 0.0
	var barbs := _data(&"barbs")
	if barbs.is_empty() or _in_barbs or not attacker is Unit or not is_instance_valid(wizard):
		return
	var u := attacker as Unit
	if u == wizard or not u.is_alive() or not wizard.is_enemy_of(u) or u.attack_range > float(barbs["melee_range"]):
		return
	var dealt := amount + absorbed
	if dealt <= 0.0:
		return
	_in_barbs = true
	u.take_damage(dealt * float(barbs["ratio"]), wizard)
	_in_barbs = false


# Unit.death_guard: a killing hit instead leaves 40 % HP and burns enemies within 4 m (once per 240 s).
func _try_rekindle(_attacker: Variant) -> bool:
	var r := _data(&"rekindle")
	if r.is_empty() or _rekindle_cd > 0.0 or not is_instance_valid(wizard):
		return false
	_rekindle_cd = float(r["cooldown"])
	set_physics_process(true)
	wizard.hp = wizard.max_hp * float(r["hp_ratio"])
	var at := wizard.global_position
	var reach := float(r["radius"])
	for node in wizard.get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u == null or u == wizard or not u.is_alive() or not wizard.is_enemy_of(u):
			continue
		if Vector2(u.global_position.x - at.x, u.global_position.z - at.z).length() <= reach + u.radius:
			u.take_damage(float(r["damage"]), wizard)
	return true
