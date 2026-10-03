class_name MissionSkeleton
extends MissionBase
## The smallest complete mission on MissionBase (docs/design/mission-framework.md "Skeleton"): the skirmish map,
## both wizards, a few workers, two objectives, a three-event E-list, a cutscene hook with its skip end state and a
## timed victory. Copy it to start a new mission; tests/test_mission_framework.gd runs it with every knob
## (tests set `config` before the node enters the tree, the data-driven path a `.tres` would take).
## Not in the campaign (no MISSION_SCENES entry).

const MISSION_ID := &"m_skeleton"
const GOAL_POS := Vector3(-20.0, 0.0, 20.0)       ## obj_reach: the hero stands within GOAL_RADIUS of it.
const GOAL_RADIUS := 4.0
const HOLD_SECONDS := 5.0                         ## obj_hold: then victory.
const DIALOGUE := [
	[&"narrator", "A quiet field. Something is about to happen."],
	[&"vessa", "Then I'll be standing right where it happens."],
	[&"vessa", "Five seconds. I can hold anything for five seconds."],
]

## Read only: what the cutscene end state set (true once it ran, played or skipped).
var gate_open := false


func _init() -> void:
	super()
	mission_title = "Skeleton"
	dialogue_lines = DIALOGUE
	briefing_paragraphs = ["The smallest mission there is."]
	define_objectives([
		[&"obj_reach", "primary", "Walk to the marker"],
		[&"obj_hold", "primary", "Hold for 5 seconds"],
		[&"obj_alive", "primary", "Vessa must survive"],
		[&"sec_bonus", "secondary", "Say hello"],
	])


func _mission_config() -> MissionConfig:
	var c := MissionConfig.new()
	c.mission_id = MISSION_ID
	c.title = "Skeleton"
	c.instant_loss_on_wizard_death = true
	c.rewards = {"set_flags": {"skeleton_done": true}, "next": &""}
	return c


func _on_navigation_ready() -> void:
	fog.reveal(Unit.Team.ENEMY, SHADOW_START, FogOfWar.START_REVEAL)
	hero = _make_wizard(Unit.Team.PLAYER)
	_spawn(hero, Unit.Team.PLAYER, PLAYER_START)
	_claim_wizard(hero, Unit.Team.PLAYER)
	shadow_hero = _make_wizard(Unit.Team.ENEMY)
	_spawn(shadow_hero, Unit.Team.ENEMY, SHADOW_START)
	_claim_wizard(shadow_hero, Unit.Team.ENEMY)
	for wiz: Wizard in [hero, shadow_hero]:
		ItemDrops.ensure_inventory(wiz)
	for i in 2:
		var w := _spawn(make_unit("cinder_hand"), Unit.Team.PLAYER, PLAYER_START + Vector3(-3.0 + i * 1.2, 0.0, 3.0))
		w.call(&"command_gather", node_of(Unit.Team.PLAYER, "a"))
	# The E-list: checked once per second, in order.
	add_event(&"E2", func() -> bool: return hero_alive() and _flat(hero.global_position, GOAL_POS) <= GOAL_RADIUS,
			_on_reached)
	add_event(&"E3", func() -> bool: return objective_state("obj_hold") == "active" and has_fired(&"E2"),
			func() -> void: say_line(3))
	begin_mission([&"obj_reach", &"obj_alive"])


func _intro() -> void:
	say_line(1)
	say_line(2)
	play_cutscene(&"m_skeleton_gate", func() -> void: gate_open = true)


func _objective_extra(id: StringName, _o: Dictionary) -> Dictionary:
	return {"position": GOAL_POS} if id == &"obj_reach" else {}


func _on_reached() -> void:
	set_objective(&"obj_reach", "done")
	set_objective(&"obj_hold", "active")
	after(HOLD_SECONDS, func() -> void:
		set_objective(&"obj_hold", "done")
		set_objective(&"obj_alive", "done")
		win(1.0))
