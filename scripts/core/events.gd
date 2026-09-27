extends Node
## Global game events (autoload "Events"). Systems emit these so other systems can react
## without knowing about each other. Only the lead adds or changes signals here.
## No class_name: it would clash with the autoload name.

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
