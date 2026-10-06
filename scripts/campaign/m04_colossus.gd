class_name M04Colossus
extends Unit
## The Keystone Colossus of mission 4 (docs/design/mission-04.md "The boss"; ep1 6): team NEUTRAL, groups "units" +
## "boss", titan rules (crowd control lasts half as long, taunt and knockback immune). It never picks fights or walks
## by itself: M04Keystone drives it (the phase-2 walk, Crush, Hurl, Stomp, Pull, Rubble Call, Turn the Key). Damage
## rules: phase 1 Keystone Ward (no damage while a pylon stands), phase 3 Stone Skin (x 0.1 unless Exposed), Cracked
## Leg (x 1.25 for `cracked_left` s). It cannot die before phase 3 (HP floor 1). Built from a code UnitType
## (`make_type`) with the M04Look placeholder.

signal phase_changed(phase: int)
signal exposed_changed(on: bool)
signal ward_blocked

const TITAN_CC_MULT := 0.5
const IMMUNE: Array[StringName] = [&"taunted"]
const STONE_SKIN := 0.1
const CRACKED_MULT := 1.25

var phase := 0                 ## Read only: 0 hidden, 1 warded on the isle, 2 walking, 3 kneeling.
var warded := true             ## Read only (M04Keystone sets it from the pylons).
var exposed := false           ## Read only.
var cracked_left := 0.0        ## Seconds of Cracked Leg left (x 1.25 damage taken, no walking).
var kneeling := false          ## Read only.


## The Colossus UnitType (not in data/units: one mission, stats from the spec).
static func make_type(hp: float, crush: float) -> UnitType:
	var t := UnitType.new()
	t.id = &"keystone_colossus"
	t.display_name = "Keystone Colossus"
	t.faction = &"neutral"
	t.max_hp = hp
	t.move_speed = 1.1   # spec 1.4; pacing 2026-10-06: phase 2 lasted ~1:15 against the spec's 2:00-3:00
	t.attack_damage = crush
	t.attack_range = 3.0
	t.attack_cooldown = 2.4
	t.aggro_range = 0.0
	t.radius = 3.0
	t.body_height = 12.0
	t.body_color = Color(0.36, 0.33, 0.30)
	t.eye_color = Color(1.0, 0.62, 0.18)
	t.armor = 25.0
	t.kill_xp = 0
	t.neutral_leash = false
	t.model_scene = M04Look.packed(&"colossus")
	return t


func _ready() -> void:
	super()
	add_to_group(&"boss")
	attacks_blocked = true   # Crush is the controller's (it never auto-attacks or chases)
	command_hold()
	death_guard = func(_attacker: Variant) -> bool:
		if phase >= 3:
			return false
		hp = 1.0
		return true


func set_phase(p: int) -> void:
	if p == phase:
		return
	phase = p
	kneeling = p == 3
	if has_model():
		model_call(&"set_kneel", [kneeling])
		model_call(&"set_glow", [1.0 if p != 3 else 0.5])
	phase_changed.emit(p)


func set_exposed(on: bool) -> void:
	if on == exposed:
		return
	exposed = on
	if has_model():
		model_call(&"set_glow", [2.6 if on else 0.5])
	exposed_changed.emit(on)


func set_warded(on: bool) -> void:
	warded = on
	if has_model():
		model_call(&"set_glow", [1.0 if on else 1.4])


## The multiplier on incoming damage now (0 = blocked by the ward).
func damage_mult() -> float:
	if phase <= 1 and warded:
		return 0.0
	var m := 1.0
	if phase >= 3 and not exposed:
		m = STONE_SKIN
	if cracked_left > 0.0:
		m *= CRACKED_MULT
	return m


func take_damage(amount: float, attacker: Node3D = null) -> void:
	var m := damage_mult()
	if m <= 0.0:
		ward_blocked.emit()
		return
	super(amount * m, attacker)
	attack_target = null   # the controller decides who it crushes


## Titan: crowd control lasts half as long; taunt never lands.
func apply_status(status_id: StringName, seconds: float, full_duration: bool = false,
		source: Node3D = null) -> void:
	if IMMUNE.has(status_id):
		return
	super(status_id, seconds * TITAN_CC_MULT, full_duration, source)


## Knockback / pulls never move it.
func displace(_to: Vector3, _seconds: float) -> Vector3:
	return global_position


func _physics_process(delta: float) -> void:
	if cracked_left > 0.0:
		cracked_left = maxf(0.0, cracked_left - delta)
		if cracked_left <= 0.0 and has_model():
			model_call(&"set_cracked", [false])
	super(delta)
