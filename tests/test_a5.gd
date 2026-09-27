extends SceneTree
## Task A.5 (Shadow army + Ruin Warden polish): every model instantiates headless, drives every hook without
## errors, the dissolve / crumble deaths emit death_finished and fade the body, revive() restores it.
## Run:  godot --headless --path . -s tests/test_a5.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "a5"
const SCENES: Array[String] = [
	"res://art/units/shadow/gloom_thrall.tscn",
	"res://art/units/shadow/shade.tscn",
	"res://art/units/shadow/nightbolt.tscn",
	"res://art/units/shadow/grave_hound.tscn",
	"res://art/units/shadow/shadow_knight.tscn",
	"res://art/units/neutral/ruin_warden.tscn",
]
const SHADOW := Color(0.42, 0.22, 0.60)

var models: Array = []
var deaths: Array[int] = []
var frame := 0
var fails: Array[String] = []


func _initialize() -> void:
	for i: int in SCENES.size():
		var ps := load(SCENES[i]) as PackedScene
		if ps == null:
			fails.append("cannot load " + SCENES[i])
			continue
		var holder := Node3D.new()
		holder.position = Vector3(i * 3.0, 0, 0)
		root.add_child(holder)
		var m = ps.instantiate()
		m.set_team_color(SHADOW)          # before _ready: cached
		holder.add_child(m)
		models.append(m)
		deaths.append(0)
		var idx := models.size() - 1
		m.death_finished.connect(func() -> void: deaths[idx] += 1)


func _body_alpha(m) -> float:
	var n := m.get_node_or_null(^"Root/Chest/Merged") as GeometryInstance3D
	if n == null:
		n = m.get_node_or_null(^"Root/Mount/Merged") as GeometryInstance3D
	return n.transparency if n else -1.0


func _process(_delta: float) -> bool:
	frame += 1
	match frame:
		2:
			for m in models:
				if not m.has_method(&"glow_level") or m.get(&"unit_kind") == &"":
					fails.append("%s: not a ShadowModel" % m.name)
				m.set_moving(float(m.stride_speed))
			models[1].set_team_color(Color(0.2, 0.5, 0.9))   # mirror-match recolour path
		40:
			for m in models:
				m.set_moving(float(m.stride_speed) * 1.5)   # hound bound, haste rates
		70:
			for m in models:
				m.set_moving(0.0)
				m.play_attack()
		100:
			for m in models:
				m.play_hit()
				m.play_level_up()
				m.set_veterancy(4)
				if not m.set_status(&"haste", true):
					fails.append("%s: haste not handled" % m.name)
				m.set_status(&"shroud", true)
		130:
			models[0].set_carrying(true)
			var cr := models[0].get_node_or_null(^"Root/Chest/Crystals") as Node3D
			if cr == null or not cr.visible:
				fails.append("thrall: carried crystals not shown")
			models[0].play_mine()
			for m in models:
				m.set_status(&"haste", false)
		200:
			for m in models:
				m.play_death()
		250:
			for m in models:
				if _body_alpha(m) < 0.2:
					fails.append("%s: body not fading mid-death (%s)" % [m.name, _body_alpha(m)])
		300:
			for i: int in models.size():
				if deaths[i] != 1:
					fails.append("%s: death_finished emitted %d times" % [models[i].name, deaths[i]])
				if _body_alpha(models[i]) < 0.95:
					fails.append("%s: body still visible after death (%s)" % [models[i].name, _body_alpha(models[i])])
			for m in models:
				m.revive()
		320:
			for m in models:
				if absf(_body_alpha(m)) > 0.001:
					fails.append("%s: revive did not restore the body (%s)" % [m.name, _body_alpha(m)])
				if m.glow_level() <= 0.0:
					fails.append("%s: glows still off after revive" % m.name)
			if fails.is_empty():
				print("PASS %s" % TASK_ID)
			else:
				print("FAIL %s: %s" % [TASK_ID, "; ".join(fails)])
			return true
	return false
