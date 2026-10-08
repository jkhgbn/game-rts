class_name Keep
extends TrainingBuilding
## The team's keep: trains workers only (from wave 2), is the workers' crystal drop-off point,
## gives +20 pop (building_type.pop_bonus). Queue / rally API: TrainingBuilding.
## Numbers: docs/design/economy.md and buildings.md. From balance-1 the keep also shoots like a spire
## (BuildingGun: attack_damage / attack_range / attack_cooldown of its BuildingType, units first;
## the range counts from its walls).

const SIZE := Vector3(5.0, 6.0, 5.0)
const BOLT_SIZE := 0.16
const DROP_OFF_DISTANCE := 3.5   ## Per axis, toward the corner facing front_toward: (3.5, -3.5) on the Fire side.
const RALLY_DISTANCE := 6.0
const ESSENCE_BANK_PATH := "res://scripts/items/essence_bank.gd"

## The optional crystal -> essence exchange (items.md, a user decision). False = refused everywhere.
static var exchange_enabled := true

## Keep tiers (docs/design/tiers.md, TierSystem): the upgrade finished (tier 2 Stronghold / 3 Citadel).
signal tier_changed(keep: Keep, tier: int)

const REASON_TIERS_OFF := "Tiers are off"
const REASON_MAX_TIER := "Already a Citadel"
const REASON_UPGRADING := "Upgrade in progress"
const TIER_STUB_ID := &"keep_upgrade"

## Read only: what the keep shoots at (null when idle or when its type has no attack).
var attack_target: Node3D:
	get:
		return _gun.target if _gun else null
## Read only: 1 Keep, 2 Stronghold, 3 Citadel (set_tier_now / the upgrade change it). ScoreKeeper reads it.
var tier := 1

var _gun: BuildingGun
var _up_to := 0          # tier being upgraded to (0 = none)
var _up_left := 0.0
var _up_paid := 0
var _tier_emblem: Node3D
var _tier_stub: UnitType
var _card_text_busy := false
var _card_text_ms := -100000
var _card_text_for := 0
var _quiet_tier := false   # set_start_tier: no tier-up flourish


func _physics_process(delta: float) -> void:
	super(delta)
	if _up_to > 0 and not _dead and is_constructed():
		_up_left -= delta
		if _up_left <= 0.0:
			var to := _up_to
			_up_to = 0
			_up_paid = 0
			set_tier_now(to)
			TierSystem.announce(int(team), to)
	if _dead or not is_constructed() or not BuildingGun.can_shoot(building_type):
		return
	if _gun == null:
		_gun = BuildingGun.new(self, building_type.height, BOLT_SIZE, target_radius())
	_gun.damage_bonus = TierSystem.DAMAGE_BONUS[tier - 1]
	_gun.tick(delta)


# ---------------------------------------------------------------- tiers (tiers.md 2)

func tier_name() -> String:
	return TierSystem.tier_name(tier)


## Crystals / seconds of the next upgrade (0 at the Citadel).
func upgrade_cost() -> int:
	return int((TierSystem.UPGRADES.get(tier + 1, {}) as Dictionary).get("crystals", 0))


func upgrade_time() -> float:
	return float((TierSystem.UPGRADES.get(tier + 1, {}) as Dictionary).get("time", 0.0))


## "" if the next upgrade can start now, else the reason (tiers off, destroyed, max, in progress, time, Hall, crystals).
func can_upgrade() -> String:
	var ts := TierSystem.instance()
	if ts == null:
		return REASON_TIERS_OFF
	if _dead:
		return REASON_DESTROYED
	if not is_constructed():
		return REASON_UNDER_CONSTRUCTION
	if tier >= 3:
		return REASON_MAX_TIER
	if _up_to > 0:
		return REASON_UPGRADING
	var need := ts.upgrade_reason(int(team), tier + 1)
	if need != "":
		return need
	var eco := _get_economy()
	if eco == null or not eco.can_afford(upgrade_cost()):
		return REASON_NO_CRYSTALS
	return ""


## Pays and starts the upgrade to the next tier (beside the worker queue). "" or the reason.
func upgrade() -> String:
	var reason := can_upgrade()
	if reason == REASON_NO_CRYSTALS and _get_economy():
		_get_economy().spend(upgrade_cost())   # fails on purpose: spend_failed flashes the top bar
	if reason != "":
		return reason
	_up_paid = upgrade_cost()
	_get_economy().spend(_up_paid)
	_up_left = upgrade_time()
	_up_to = tier + 1
	_call_model(&"set_upgrading", [true])
	queue_changed.emit()
	return ""


## Stops the upgrade: full refund.
func cancel_upgrade() -> void:
	if _up_to == 0:
		return
	var eco := _get_economy()
	if eco and _up_paid > 0:
		eco.add(_up_paid)
	_up_to = 0
	_up_paid = 0
	_up_left = 0.0
	_call_model(&"set_upgrading", [false])
	queue_changed.emit()


func is_upgrading() -> bool:
	return _up_to > 0


## 0-1 while upgrading (0 otherwise).
func upgrade_progress() -> float:
	if _up_to == 0:
		return 0.0
	var total := float((TierSystem.UPGRADES[_up_to] as Dictionary)["time"])
	return clampf(1.0 - _up_left / maxf(total, 0.01), 0.0, 1.0)


func upgrade_time_left() -> float:
	return maxf(_up_left, 0.0) if _up_to > 0 else 0.0


## Campaign start state (mission-e2-01.md "Code", MissionBase / TierSystem.set_start_tier): the keep IS tier `t`
## (tier HP and attack, the tier look) with no announcement, no timer and no tier-up flourish. Any running upgrade is
## refunded first. Works mid-mission too (a phase switch).
func set_start_tier(t: int) -> void:
	cancel_upgrade()
	_quiet_tier = true
	set_tier_now(t)
	_quiet_tier = false


## Puts the keep at tier `t` now: max HP x1.2 / x1.4 of its base (the gain is healed), attack +4 / +8, the look.
func set_tier_now(t: int) -> void:
	t = clampi(t, 1, 3)
	if t == tier:
		return
	var old_mult: float = TierSystem.HP_MULT[tier - 1]
	var new_mult: float = TierSystem.HP_MULT[t - 1]
	var old_max := max_hp
	max_hp = roundf(max_hp / old_mult * new_mult)
	if not _dead:
		hp = clampf(hp + (max_hp - old_max), minf(hp, 1.0), max_hp)
	tier = t
	if is_inside_tree():
		_update_hp_bar()
		_call_model(&"set_health_ratio", [hp / maxf(max_hp, 1.0)])
		_show_tier()
		if not _quiet_tier:
			_call_model(&"play_tier_up")
		_call_model(&"set_upgrading", [false])
	tier_changed.emit(self, tier)
	queue_changed.emit()
	var ts := TierSystem.instance()
	if ts:
		ts.refresh(int(team))


## The keep card's tier button (tiers.md 3): a stub UnitType (id TIER_STUB_ID) that TrainingBuilding.trainable_types
## lists right after the worker (slot 2, key X), so the card, hotkey and bot plumbing need nothing new. Queuing it
## starts the upgrade (can_queue / queue_unit below); while upgrading it becomes "Cancel <tier> n %" (full refund).
## Null when tiers are off, the keep is a site / destroyed, or it is a Citadel.
func tier_card_type() -> UnitType:
	if TierSystem.instance() == null or _dead or not is_constructed() or (tier >= TierSystem.cap() and _up_to == 0):
		return null
	if _tier_stub == null:
		_tier_stub = UnitType.new()
		_tier_stub.id = TIER_STUB_ID
		_tier_stub.pop = 0
		_tier_stub.faction = building_type.faction if building_type else &""
	if _up_to > 0:
		var name_to := TierSystem.tier_name(_up_to)
		_tier_stub.display_name = "Cancel %s" % name_to
		_tier_stub.cost = 0
		_tier_stub.train_time = upgrade_time_left()
		_tier_stub.set_meta(&"card_text", "%s %d %%: %d s left. Cancel = full refund (%d crystals)." % [name_to,
				roundi(upgrade_progress() * 100.0), ceili(upgrade_time_left()), _up_paid])
		_card_text_for = 0   # the upgrade text is rebuilt once the button is back
	else:
		var to := tier + 1
		_tier_stub.display_name = TierSystem.tier_name(to)
		_tier_stub.cost = upgrade_cost()
		_tier_stub.train_time = upgrade_time()
		# The text lists the other buildings' units (their trainable_types() call back here): cached 1 s, no re-entry.
		var now_ms := Time.get_ticks_msec()
		if not _card_text_busy and (now_ms - _card_text_ms > 1000 or _card_text_for != to):
			_card_text_busy = true
			_tier_stub.set_meta(&"card_text", tier_card_text(to))
			_card_text_busy = false
			_card_text_ms = now_ms
			_card_text_for = to
	return _tier_stub


## The tier button's tooltip body (tiers.md 3, 2026-09-30 "make the way up obvious"): the effect, the exact list of what
## the tier opens (TierSystem.unlock_text), and what it needs (time floor, a completed Hall).
func tier_card_text(to: int) -> String:
	var lines: Array[String] = ["Upgrade the keep: +%d %% HP, +%d damage." % [
			roundi((TierSystem.HP_MULT[to - 1] - 1.0) * 100.0), roundi(TierSystem.DAMAGE_BONUS[to - 1])]]
	var opens: Array[String] = []
	var unlocks := TierSystem.unlock_text(int(team), to)   # one walk over the buildings (review 2026-10-08 L6)
	if unlocks != "":
		opens.append(unlocks)
	if to == 2 and UnitUpgrades.ENABLED:
		opens.append("the \"+\" upgrades at the Hall")
	if not opens.is_empty():
		lines.append("Opens: " + " · ".join(opens))
	var ts := TierSystem.instance()
	var needs: Array[String] = []
	if ts and ts.time_gates and ts.start_time(to) > 0.0:
		needs.append("from %s" % TierSystem.clock(ts.start_time(to)))
	if bool((TierSystem.UPGRADES.get(to, {}) as Dictionary).get("needs_hall", false)):
		needs.append("a completed Hall")
	if to == 3:
		needs.push_front("the Stronghold")
	if not needs.is_empty():
		lines.append("Needs " + ", ".join(needs) + ".")
	return "\n".join(lines)


func can_queue(type: UnitType) -> String:
	if type != null and type.id == TIER_STUB_ID:
		return "" if _up_to > 0 else can_upgrade()
	return super(type)


func queue_unit(type: UnitType) -> String:
	if type != null and type.id == TIER_STUB_ID:
		if _up_to > 0:
			cancel_upgrade()
			return ""
		return upgrade()
	return super(type)


## The keep model's set_tier(t) if it has one; else a placeholder emblem: 1 (Stronghold) or 2 (Citadel) gold rings
## over the roof (tiers-wave.md: art replaces it with a real tier look).
func _show_tier() -> void:
	if _model != null and is_instance_valid(_model) and _model.has_method(&"set_tier"):
		_model.call(&"set_tier", tier)
		return
	if _tier_emblem:
		_tier_emblem.queue_free()
		_tier_emblem = null
	if tier <= 1:
		return
	_tier_emblem = Node3D.new()
	_tier_emblem.name = "TierEmblem"
	add_child(_tier_emblem)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.82, 0.3) if tier == 2 else Color(1.0, 0.95, 0.7)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in tier - 1:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 1.7 - 0.45 * i
		torus.outer_radius = 1.95 - 0.45 * i
		torus.rings = 24
		torus.ring_segments = 6
		ring.mesh = torus
		ring.material_override = mat
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ring.position.y = _top_height() + 0.6 + 0.5 * i
		_tier_emblem.add_child(ring)


func _on_destroyed() -> void:
	super()
	_up_to = 0   # the upgrade dies with the keep (no refund)
	var ts := TierSystem.instance()
	if ts:
		ts.refresh(int(team))


## The living keep of `for_team_id` closest to `pos` (null if none).
static func nearest(for_team_id: int, pos: Vector3) -> Keep:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var best: Keep = null
	var best_d := INF
	for node in tree.get_nodes_in_group("buildings"):
		var k := node as Keep
		if k == null or k.team != for_team_id or not k.is_alive():
			continue
		var d := k.global_position.distance_squared_to(pos)
		if d < best_d:
			best_d = d
			best = k
	return best


## The base-shop exchange: `team` pays 100 crystals and gets 40 essence (EssenceBank). "" = done,
## else the reason. The caller (shop UI / bot) checks the wizard is within ShopStock.SHOP_RADIUS.
func exchange_crystals(for_team: int) -> String:
	if not exchange_enabled:
		return "Exchange disabled"
	if not is_shop():
		return "No shop nearby"
	if for_team != int(team):
		return "Not your shop"
	var bank: Object = essence_bank_for(for_team)
	if bank == null:
		return "Essence not available"
	var eco := Economy.for_team(for_team)
	if eco == null or not eco.spend(ShopStock.EXCHANGE_CRYSTALS):   # a failed spend flashes the top bar
		return TrainingBuilding.REASON_NO_CRYSTALS
	bank.call(&"add", ShopStock.EXCHANGE_ESSENCE)
	return ""


## EssenceBank.for_team(team) if scripts/items/essence_bank.gd exists (else null).
static func essence_bank_for(for_team: int) -> Object:
	if not ResourceLoader.exists(ESSENCE_BANK_PATH):
		return null
	var script := load(ESSENCE_BANK_PATH) as Script
	if script == null or not script_has(script, &"for_team"):
		return null
	return script.call(&"for_team", for_team) as Object


static func script_has(script: Script, method: StringName) -> bool:
	for m in script.get_script_method_list():
		if StringName(m.get("name", "")) == method:
			return true
	return false


## Where workers drop crystals and where trained units appear.
func drop_off_point() -> Vector3:
	return global_position + _corner_offset(DROP_OFF_DISTANCE)


func spawn_point() -> Vector3:
	return drop_off_point()


func _spawn_distance() -> float:
	return DROP_OFF_DISTANCE


func _rally_distance() -> float:
	return RALLY_DISTANCE


func _default_type() -> BuildingType:
	return BuildingType.find("fire_keep" if team == Unit.Team.PLAYER else "shadow_keep")


func _body_size() -> Vector3:
	return SIZE


func _top_height() -> float:
	return maxf(9.0, _model_top())   # the art keeps are ~15-18 m tall


func _build_shape() -> void:
	var box := BoxMesh.new()
	box.size = SIZE
	_add_mesh(box, building_type.body_color if building_type else Color(0.5, 0.45, 0.4), SIZE.y * 0.5)
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 3.8
	cone.height = 3.0
	cone.radial_segments = 4
	var roof := _add_mesh(cone, team_color.darkened(0.2), 7.5)
	roof.rotation.y = PI / 4.0
