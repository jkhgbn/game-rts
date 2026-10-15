extends Node
## Global game events (autoload "Events"). Systems emit these so other systems can react
## without knowing about each other. Only the lead adds or changes signals here.
## No class_name: it would clash with the autoload name.


func _ready() -> void:
	if BootCheck.wanted():
		BootCheck.run.call_deferred(get_tree())

@warning_ignore("unused_signal")
signal unit_died(unit: Unit)
@warning_ignore("unused_signal")
signal building_completed(building: Node3D)
@warning_ignore("unused_signal")
signal artifact_claimed(artifact: Artifact, wizard: Wizard)
@warning_ignore("unused_signal")
signal objective_changed(objective_id: StringName, state: StringName)
@warning_ignore("unused_signal")
signal mission_ended(victory: bool)
## A line of mission dialogue for the dialogue box (speaker id e.g. &"vessa", &"malrik", &"narrator").
@warning_ignore("unused_signal")
signal dialogue(speaker: StringName, text: String)
## Tools wave, tool 1 (Cinematic Runtime): a cinematic started / finished (skipped = the player skipped it).
@warning_ignore("unused_signal")
signal cinematic_started(id: StringName)
@warning_ignore("unused_signal")
signal cinematic_finished(id: StringName, skipped: bool)
## Campaign unit spotlight (mission-framework.md 7): a mission's spotlight card was shown (`card` = the English line).
@warning_ignore("unused_signal")
signal spotlight_shown(id: StringName, card: String)
