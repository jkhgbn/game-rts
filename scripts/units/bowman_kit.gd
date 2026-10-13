class_name BowmanKit
extends RefCounted
## The four kingdom bowmen (docs/design/bowmen.md): Frostbow (Ice, chill + Hamstring Shot), Scorchbow (Fire, burn),
## Bleakbow (Shadow, stacking bleed), Wildwood Archer (Nature, crits and Hunting Party from its upgrades).
## Everything is static and keyed by UnitType.id, so Unit only calls three cheap hooks:
## on_unit_ready (Unit._ready), shot_damage (Unit._spawn_shot), on_hit (Unit._on_attack_hit).
## Upgrades live in BowmanUpgrades (one node per team). The whole feature hangs on BOWMEN_ENABLED.

## THE switch (bowmen.md 1): false = no Hall lists a bowman, bots never train one, hooks are no-ops.
const BOWMEN_ENABLED := true

## Per-unit numbers (bowmen.md 2 / 3). Upgrade effects are read in the functions below.
const BOWMEN := {
	&"frostbow": {"faction": &"ice", "chill": 1.5, "hamstring_cd": 12.0, "hamstring_chill": 3.5},
	&"scorchbow": {"faction": &"fire", "burn_dps": 2.0, "burn_time": 3.0},
	&"bleakbow": {"faction": &"shadow", "bleed_dps": 1.5, "bleed_time": 5.0, "bleed_cap": 3},
	&"wildwood_archer": {"faction": &"nature"},
}
## The Hall bowman of each kingdom (slot 5, key B).
const HALL_BOWMAN := {&"fire": &"scorchbow", &"shadow": &"bleakbow", &"ice": &"frostbow", &"nature": &"wildwood_archer"}
## Bot mix share of a Hall bowman (rush-balance.md 7.3 style; the Hall's 4 older slots keep their AIProfile mix).
const BOT_SHARE := {&"frostbow": 0.08, &"scorchbow": 0.08, &"bleakbow": 0.08, &"wildwood_archer": 0.10}

const BURN_INTERVAL := 1.0
const BLEED_INTERVAL := 0.5
const BLEED_META := &"bowman_bleed_stacks"
const CRIT_META := &"bowman_crit_acc"
const HAMSTRING_META := &"_bowman_hamstring_at"    # clock second Hamstring is ready (ClockMetaLedger saves the rest)
const HAMSTRING_TARGET_META := &"_bowman_hamstring_target"
const HAMSTRING_MOVING := 1.5                       # m/s: the target counts as moving (not a shove)
const SKIRMISH_SCRIPT := "res://scripts/world/skirmish.gd"

## Tests on scenes/main.tscn set this true (the Halls list bowmen only in a real skirmish otherwise).
static var force_enabled := false


static func is_bowman(type_id: StringName) -> bool:
	return BOWMEN_ENABLED and BOWMEN.has(type_id)


## True when the Halls of the current game list bowmen: the plain skirmish or a generated map (LayoutLevel), not
## missions, which extend it (CasterKit.is_plain_skirmish; thornwater_2026-10-11.md: layout maps had no bowmen).
static func enabled_here() -> bool:
	if not BOWMEN_ENABLED:
		return false
	if force_enabled:
		return true
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return false
	return CasterKit.is_plain_skirmish(tree.current_scene)


## The bowman a Hall of `building_type` adds as its last slot, or null (TrainingBuilding.trainable_types).
static func hall_bowman(building_type: Resource) -> UnitType:
	if building_type == null or StringName(building_type.get(&"kind")) != &"barracks" or not enabled_here():
		return null
	var id: Variant = HALL_BOWMAN.get(StringName(building_type.get(&"faction")))
	return UnitType.find(String(id)) if id != null else null


## Bot target share for a Hall slot past the AIProfile mix (commander _pick_soldier). 0 for anything else.
static func bot_share(type_id: StringName) -> float:
	return float(BOT_SHARE.get(type_id, 0.0)) if BOWMEN_ENABLED else 0.0


# ---------------------------------------------------------------- unit hooks

## Unit._ready: finished upgrades of the team (stat modifiers) and the Frostbow's ready bow string.
static func on_unit_ready(unit: Unit) -> void:
	BowmanUpgrades.apply_to(unit)
	if unit.unit_type.id == &"frostbow":
		_set_hamstring_ready(unit, true)


## Unit._spawn_shot: the damage this arrow carries. Wildwood crits (deterministic: a chance accumulator, so replays
## and tests repeat), Frostbow arms Hamstring Shot on a moving unit.
static func shot_damage(unit: Unit, target: Node3D) -> float:
	var dmg := unit.attack_damage
	var id := unit.unit_type.id
	if id == &"wildwood_archer":
		var crit := crit_numbers(int(unit.team))
		if crit.x > 0.0:
			var acc := float(unit.get_meta(CRIT_META, 0.5)) + crit.x
			if acc >= 1.0:
				acc -= 1.0
				dmg *= crit.y
			unit.set_meta(CRIT_META, acc)
	elif id == &"frostbow":
		var victim := target as Unit
		if victim and _now() >= float(unit.get_meta(HAMSTRING_META, 0.0)) \
				and Vector2(victim.velocity.x, victim.velocity.z).length() >= HAMSTRING_MOVING:
			unit.set_meta(HAMSTRING_TARGET_META, victim.get_instance_id())
			var cd := hamstring_cooldown(int(unit.team))
			unit.set_meta(HAMSTRING_META, _now() + cd)
			ClockMetaLedger.ensure()   # saves the cooldown left (the meta itself is not saved)
			_set_hamstring_ready(unit, false)
			var tree := unit.get_tree()
			if tree:
				var ref: WeakRef = weakref(unit)
				tree.create_timer(cd, false, true).timeout.connect(func() -> void:
					var u := ref.get_ref() as Unit
					if u and u.is_alive():
						_set_hamstring_ready(u, true))
	return dmg


## Unit._on_attack_hit (a bowman's arrow landed on `target`). Units only: buildings never burn / bleed / chill.
static func on_hit(unit: Unit, target: Node3D, _dealt: float) -> void:
	var victim := target as Unit
	if victim == null or not victim.is_alive():
		return
	var team := int(unit.team)
	match unit.unit_type.id:
		&"frostbow":
			var dur := chill_seconds(team)
			if unit.has_meta(HAMSTRING_TARGET_META) and int(unit.get_meta(HAMSTRING_TARGET_META)) == victim.get_instance_id():
				unit.remove_meta(HAMSTRING_TARGET_META)
				dur = maxf(dur, float(BOWMEN[&"frostbow"]["hamstring_chill"]))
			# Never shorten a longer chill already on the target (apply_status overwrites the timer).
			victim.apply_status(&"chill", maxf(dur, victim.status_time_left(&"chill")))
		&"scorchbow":
			var burn := burn_numbers(team)
			victim.apply_dot(&"burn", burn.x * BURN_INTERVAL, BURN_INTERVAL, burn.y, unit)
		&"bleakbow":
			var b: Dictionary = BOWMEN[&"bleakbow"]
			var stacks := 0
			if victim.dot_time_left(&"bleed") > 0.0:
				stacks = int(victim.get_meta(BLEED_META, 0))
			stacks = mini(stacks + 1, bleed_cap(team))
			victim.set_meta(BLEED_META, stacks)
			victim.apply_dot(&"bleed", float(b["bleed_dps"]) * stacks * BLEED_INTERVAL, BLEED_INTERVAL,
					float(b["bleed_time"]), unit)


# ---------------------------------------------------------------- numbers (base + upgrades)

static func chill_seconds(team: int) -> float:
	return 2.5 if BowmanUpgrades.team_has(team, &"frostbow_rimed_shafts") else float(BOWMEN[&"frostbow"]["chill"])


static func hamstring_cooldown(team: int) -> float:
	return 8.0 if BowmanUpgrades.team_has(team, &"frostbow_rimed_shafts") \
			else float(BOWMEN[&"frostbow"]["hamstring_cd"])


## (damage per second, seconds).
static func burn_numbers(team: int) -> Vector2:
	if BowmanUpgrades.team_has(team, &"scorchbow_pitch_arrows"):
		return Vector2(3.5, 4.0)
	var b: Dictionary = BOWMEN[&"scorchbow"]
	return Vector2(float(b["burn_dps"]), float(b["burn_time"]))


static func bleed_cap(team: int) -> int:
	return 5 if BowmanUpgrades.team_has(team, &"bleakbow_serrated_barbs") else int(BOWMEN[&"bleakbow"]["bleed_cap"])


## (crit chance, crit damage multiplier); chance 0 = no crits yet.
static func crit_numbers(team: int) -> Vector2:
	if BowmanUpgrades.team_has(team, &"wildwood_heartseeker"):
		return Vector2(0.20, 2.75)
	if BowmanUpgrades.team_has(team, &"wildwood_keen_eye"):
		return Vector2(0.15, 2.0)
	return Vector2.ZERO


# ---------------------------------------------------------------- helpers

static func _now() -> float:
	return CasterKit.now_s()   # the shared pausable match clock (R3-7)


static func _set_hamstring_ready(unit: Unit, on: bool) -> void:
	if unit.model_has(&"set_hamstring_ready"):
		unit.model_call(&"set_hamstring_ready", [on])
