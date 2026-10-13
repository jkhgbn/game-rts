class_name EmberCrown
extends Artifact
## The Ember Crown of the 1v1 map, a carried item (docs/design/skirmish-1v1.md). The first living
## wizard of either team within pickup_radius wears it: +100 max HP (healed by 100) and +50 max mana
## (Wizard.add_bonus_stats). When the wearer dies the bonus is removed
## and, DROP_DELAY seconds later, the crown lies at the death spot (nearest navmesh point), free for
## either wizard to take again. While worn it floats above the wearer (and the node follows her, so
## the minimap shows where it is). The pedestal stays in the centre.
## Balance-1 (docs/design/balance-1.md 2e): sealed until seal_time (6:00) of match time. While sealed it
## stays visible on its pedestal (glowing red), is_available() stays true but can_be_claimed() is false
## and a wizard in range only triggers seal_refused. stirring at 5:30, unsealed at 6:00.

signal dropped(crown: EmberCrown, at: Vector3)   ## The crown landed and can be taken again.
signal lost(crown: EmberCrown, wearer: Wizard)    ## The wearer died (the drop follows DROP_DELAY later).
signal seal_refused(crown: EmberCrown, wizard: Wizard)   ## A wizard in range while sealed (every REFUSE_REPEAT s).
signal stirring(crown: EmberCrown)               ## STIR_LEAD seconds before the seal breaks (5:30).
signal unsealed(crown: EmberCrown)               ## The seal broke (6:00): it can be claimed.

const SEAL_TIME := 360.0
const STIR_LEAD := 30.0
const REFUSE_REPEAT := 3.0
const SEAL_GLOW := Color(0.95, 0.12, 0.08)
const MSG_SEALED := "The Ember Crown is sealed until 6:00"
const MSG_STIRS := "The Ember Crown stirs..."
const MSG_AWAKENS := "The Ember Crown awakens"
const DROP_DELAY := 3.0
const GROUND_GEM_Y := 1.0
const PEDESTAL_GEM_Y := 1.8
const WORN_GEM_SCALE := 0.55
const ITEM_ID := &"ember_crown"

@export var bonus_hp := 100.0

var wearer: Wizard = null   ## Read only: the wizard wearing it (null when on the ground or dropping).
## Match time (s) at which the seal breaks. 0 = never sealed.
var seal_time := SEAL_TIME
## Returns the match time in seconds (Skirmish.match_time). Unset: seconds since the crown entered the tree.
var match_time_source: Callable

var _elapsed := 0.0
var _stirred := false
var _unsealed := false
var _refuse_left := 0.0
var _drop_left := -1.0      # >= 0: counting down to the drop
var _drop_at := Vector3.ZERO
var _gem_y := PEDESTAL_GEM_Y
var _as_item := false       # worn as the `ember_crown` artifact item (the Inventory owns its stats)


func _init() -> void:
	artifact_name = "Ember Crown"
	bonus_mana = 50.0
	bonus_fireball_damage = 0.0


func _ready() -> void:
	super()
	if _pedestal:
		_pedestal.top_level = true   # keeps its global spot when the crown node moves
	_update_seal()


## True when the crown lies somewhere (not worn, not dropping). It may still be sealed: see can_be_claimed().
func is_available() -> bool:
	return wearer == null and _drop_left < 0.0


## True before seal_time of match time: nobody can take it yet.
func is_sealed() -> bool:
	return _match_time() < seal_time


## Seconds until the seal breaks (0 once it can be claimed). The UI shows it as a timer.
func crown_unseal_time_left() -> float:
	return maxf(0.0, seal_time - _match_time())


## True when a wizard stepping on it now would wear it.
func can_be_claimed() -> bool:
	return is_available() and not is_sealed()


func is_worn() -> bool:
	return wearer != null


## The wearer's short name ("Vessa"), or "".
func wearer_name() -> String:
	return short_name(wearer) if wearer else ""


static func short_name(wizard: Unit) -> String:
	if wizard == null or not is_instance_valid(wizard):
		return ""
	return wizard.unit_name.get_slice(",", 0).strip_edges()


func _process(delta: float) -> void:
	_elapsed += delta
	_refuse_left = maxf(0.0, _refuse_left - delta)
	if not _unsealed:
		_update_seal()
	if _drop_left >= 0.0:
		_drop_left -= delta
		if _drop_left < 0.0:
			_land()
		return
	_time += delta
	_gem.rotation.y += delta * 1.5
	if wearer != null:
		if is_instance_valid(wearer) and wearer.is_inside_tree() and not wearer.is_queued_for_deletion() \
				and wearer.is_alive():   # a death already ran _on_wearer_died; not alive here = leave_map
			global_position = wearer.global_position
		else:
			_release_gone_wearer()   # left the map / freed without `died` (C1-9)
		return
	_gem.position.y = _gem_y + sin(_time * 2.0) * 0.15
	for hero in _wizards():
		var d := Vector2(hero.global_position.x - global_position.x,
				hero.global_position.z - global_position.z).length()
		if d <= pickup_radius:
			if not _unsealed:
				if _refuse_left <= 0.0:
					_refuse_left = REFUSE_REPEAT
					seal_refused.emit(self, hero)
				return
			_claim(hero)
			return


func _match_time() -> float:
	if match_time_source.is_valid():
		return float(match_time_source.call())
	return _elapsed


## Emits stirring / unsealed once each and keeps the pedestal glowing red while sealed.
func _update_seal() -> void:
	var left := crown_unseal_time_left()
	if not _stirred and left <= STIR_LEAD and left > 0.0:
		_stirred = true
		stirring.emit(self)
	if left <= 0.0:
		_unsealed = true
		_stirred = true
		if is_inside_tree() and seal_time > 0.0:
			unsealed.emit(self)
	_set_pedestal_glow(not _unsealed)


func _set_pedestal_glow(on: bool) -> void:
	if _pedestal == null:
		return
	_tint_pedestal_runes(on, SEAL_GLOW)
	var mat := _pedestal.material_override as StandardMaterial3D
	if mat == null or mat.emission_enabled == on:
		return
	mat.emission_enabled = on
	mat.emission = SEAL_GLOW
	mat.emission_energy_multiplier = 1.5


## Living wizards of every team (Malrik is in "enemy_heroes", not "heroes").
func _wizards() -> Array[Wizard]:
	var out: Array[Wizard] = []
	for group in [&"heroes", &"enemy_heroes"]:
		for node in get_tree().get_nodes_in_group(group):
			var w := node as Wizard
			if w and w.is_alive() and not out.has(w):
				out.append(w)
	return out


func _claim(hero: Wizard) -> void:
	wearer = hero
	if _claim_as_item(hero):
		hero.artifacts.append(artifact_name)
	elif hero.has_method(&"add_bonus_stats"):
		hero.call(&"add_bonus_stats", bonus_hp, bonus_mana)   # +max and healed by the same amounts
		hero.artifacts.append(artifact_name)
	else:
		var hp_before := hero.hp
		hero.max_hp += bonus_hp
		hero.claim_artifact(artifact_name, bonus_mana, bonus_fireball_damage)   # (full heal inside)
		hero.hp = minf(hp_before, hero.max_hp)
		hero.heal(bonus_hp)
	if not hero.died.is_connected(_on_wearer_died):
		hero.died.connect(_on_wearer_died)
	_gem.scale = Vector3.ONE * WORN_GEM_SCALE
	_gem.position.y = hero.body_height + 1.1
	global_position = hero.global_position
	claimed.emit(self, hero)


func _on_wearer_died(unit: Unit) -> void:
	if unit != wearer:
		return
	var w := wearer
	wearer = null
	if w.died.is_connected(_on_wearer_died):
		w.died.disconnect(_on_wearer_died)
	if _as_item:
		_as_item = false
		var inv := ItemDrops.inventory_of(w)
		if inv:
			var slot := int(inv.call(&"find_slot", ITEM_ID))
			if slot >= 0:
				inv.call(&"remove_item", slot)
	elif w.has_method(&"remove_bonus_stats"):
		w.call(&"remove_bonus_stats", bonus_hp, bonus_mana)
	else:
		w.max_hp -= bonus_hp
		w.max_mana -= bonus_mana
		w.mana = minf(w.mana, w.max_mana)
		w.hp = minf(w.hp, w.max_hp)
	w.artifacts.erase(artifact_name)
	_drop_at = w.global_position
	_drop_left = DROP_DELAY
	_set_shown(false)
	lost.emit(self, w)


## The wearer left the tree without dying (Unit.leave_map, freed by a load): the crown drops where it last was (its
## stats left with the wearer's node). lost(crown, null).
func _release_gone_wearer() -> void:
	var w: Wizard = wearer if is_instance_valid(wearer) else null
	wearer = null
	_as_item = false
	if w and w.died.is_connected(_on_wearer_died):
		w.died.disconnect(_on_wearer_died)
	_drop_at = global_position
	_drop_left = DROP_DELAY
	_set_shown(false)
	lost.emit(self, w)


## Items system present (an Inventory with add_item / find_slot / remove_item, data/items/ember_crown.tres):
## the crown goes into artifact slot 1 and the Inventory applies its +100 HP / +50 mana
## (`item:artifact_1`). Otherwise false and the old bonus-stat path is used.
func _claim_as_item(hero: Wizard) -> bool:
	var inv := ItemDrops.inventory_of(hero)
	if inv == null or not inv.has_method(&"add_item") or not inv.has_method(&"find_slot") or not inv.has_method(&"remove_item"):
		return false
	var type := ItemDrops.item_type(ITEM_ID)
	if type == null or not bool(inv.call(&"add_item", type)):
		return false
	_as_item = true
	return true


## Hides the gem and its light (not the node: the pedestal is a child and must stay visible).
func _set_shown(value: bool) -> void:
	for child in get_children():
		if child != _pedestal and child is Node3D:
			(child as Node3D).visible = value


func _land() -> void:
	_drop_left = -1.0
	var p := _drop_at
	var map := get_world_3d().navigation_map
	if map.is_valid() and NavigationServer3D.map_get_iteration_id(map) > 0:
		p = NavigationServer3D.map_get_closest_point(map, _drop_at)
	global_position = Vector3(p.x, 0.0, p.z)
	_gem_y = GROUND_GEM_Y
	_gem.scale = Vector3.ONE
	_gem.position.y = _gem_y
	_set_shown(true)
	dropped.emit(self, global_position)


# ---------------------------------------------------------------- save / load (docs/design/save-load.md)

## The seal (seal_time: mission 1 breaks it with its braziers, C2-4) travels with the save.
func save_state(ids: Dictionary) -> Dictionary:
	return {"wearer": ids.get(wearer, -1) if wearer != null else -1, "pos": global_position,
			"dropping": _drop_left >= 0.0, "drop_at": _drop_at,
			"seal_time": seal_time, "stirred": _stirred, "unsealed": _unsealed}


## Load (after the wizards): the seal as saved (no stirring / unsealed signal again), then worn again by its wearer,
## or lying where it was (a crown still dropping lands at once).
func load_state(d: Dictionary, nodes: Dictionary) -> void:
	if d.has("seal_time"):
		seal_time = float(d["seal_time"])
		_stirred = bool(d.get("stirred", _stirred))
		_unsealed = bool(d.get("unsealed", _unsealed))
		_set_pedestal_glow(not _unsealed)
	var w: Variant = nodes.get(d.get("wearer", -1))
	var saved_wearer: Wizard = w as Wizard if w is Wizard and is_instance_valid(w) and (w as Wizard).is_alive() else null
	if wearer != null and wearer != saved_wearer:
		_unwear_quiet()   # the rebuilt start's wearer is not the saved one: no lost signal, no second drop
	if saved_wearer != null:
		if wearer != saved_wearer:
			_claim(saved_wearer)
		return
	var at: Vector3 = d.get("drop_at", global_position) if bool(d.get("dropping", false)) else d.get("pos", global_position)
	if at.distance_to(global_position) > 0.5 or _drop_left >= 0.0 or not _gem.visible:
		_drop_at = at
		_land()


## Takes the crown off its wearer without the death path (a load): bonus / item removed, nothing emitted.
func _unwear_quiet() -> void:
	var w: Wizard = wearer if is_instance_valid(wearer) else null
	wearer = null
	_drop_left = -1.0
	if w == null:
		_as_item = false
		return
	if w.died.is_connected(_on_wearer_died):
		w.died.disconnect(_on_wearer_died)
	if _as_item:
		_as_item = false
		var inv := ItemDrops.inventory_of(w)
		if inv:
			var slot := int(inv.call(&"find_slot", ITEM_ID))
			if slot >= 0:
				inv.call(&"remove_item", slot)
	elif w.has_method(&"remove_bonus_stats"):
		w.call(&"remove_bonus_stats", bonus_hp, bonus_mana)
	w.artifacts.erase(artifact_name)
