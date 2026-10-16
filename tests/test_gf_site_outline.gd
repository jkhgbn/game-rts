extends SceneTree
## G-F Shadow leftovers: Building's own site outline (docs/handoff/for-lead.md).
## Run: godot --headless --path . -s tests/test_gf_site_outline.gd --fixed-fps 60 --quit-after 300
## Checks: a construction site with an art model that draws its own site (BuildOutline) hides Building's footprint
## square; a site with no art model (placeholder boxes) still shows it.

const TASK_ID := "gf_site_outline"

var frame := 0
var world: Node3D
var _art: Array[Building] = []
var _plain: Building
var _errors: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	world = Node3D.new()
	root.add_child(world)
	var x: float = 0.0
	for id: String in ["shadow_hovel", "fire_hearth"]:
		_art.append(_site(BuildingType.find(StringName(id)), Vector3(x, 0, 0)))
		x += 14.0
	var bare := (BuildingType.find(&"shadow_hovel") as BuildingType).duplicate() as BuildingType
	bare.model_scene = null
	bare.model_path = ""
	_plain = _site(bare, Vector3(x, 0, 0))


func _site(type: BuildingType, pos: Vector3) -> Building:
	var b := BuildGrid.create_building(type)
	b.team = 0
	b.make_site()
	world.add_child(b)
	b.position = pos
	return b


func _check(ok: bool, msg: String) -> void:
	if not ok:
		_errors.append(msg)


func _process(_delta: float) -> bool:
	frame += 1
	if frame == 5:
		for b: Building in _art:
			var model := b.model()
			_check(model != null, "%s: no art model" % b.name)
			if model == null:
				continue
			var ol := model.find_child("BuildOutline", true, false) as Node3D
			_check(ol != null and ol.is_visible_in_tree(), "%s: model BuildOutline not shown on the site" % b.name)
			_check(b._outline != null and not b._outline.visible, "%s: Building outline shown over the art model" % b.name)
		_check(_plain.model() == null, "placeholder building got a model")
		_check(_plain._outline != null and _plain._outline.visible, "placeholder site: Building outline hidden")
		_check(not _plain.is_constructed(), "placeholder is not a site")
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		return true
	return false
