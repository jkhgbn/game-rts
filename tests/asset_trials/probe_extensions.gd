extends SceneTree
## Asset trial probe: are the GDExtension classes (LimboAI, Debug Draw 3D) registered in this Godot build, and
## which methods do we need? Headless. Run:
##   tools\godot_run.ps1 --headless --path . -s tests/asset_trials/probe_extensions.gd --quit-after 600


func _initialize() -> void:
	for c: String in ["BehaviorTree", "BTInstance", "BTPlayer", "BTAction", "BTCondition", "BTSelector",
			"BTSequence", "Blackboard", "LimboHSM", "DebugDraw3D", "DebugDrawManager"]:
		print("class %s exists=%s" % [c, ClassDB.class_exists(c)])
	for c: String in ["BehaviorTree", "BTInstance"]:
		if ClassDB.class_exists(c):
			var names: Array = []
			for m: Dictionary in ClassDB.class_get_method_list(c, true):
				names.append(m.name)
			print("%s methods: %s" % [c, ", ".join(names)])
	if Engine.has_singleton("DebugDraw3D"):
		var dd: Object = Engine.get_singleton("DebugDraw3D")
		var names2: Array = []
		for m: Dictionary in dd.get_method_list():
			if String(m.name).begins_with("draw_"):
				names2.append(m.name)
		print("DebugDraw3D draw_*: %s" % ", ".join(names2))
	else:
		print("DebugDraw3D singleton missing")
	quit()
