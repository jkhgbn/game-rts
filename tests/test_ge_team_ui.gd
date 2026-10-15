extends SceneTree
## G-E team read, UI side: the minimap's team marks and the HUD kingdom colours follow Unit.team_display_color /
## kingdom_color_for, so a mirror match's later side shows its alternate palette like its units.
## Run:  tools\godot_run.ps1 --headless --path . -s tests/test_ge_team_ui.gd --fixed-fps 60 --quit-after 600

const TASK_ID := "ge_team_ui"

var world: Node3D
var failures: Array[String] = []
var frame := 0


func _initialize() -> void:
	_build_world(&"fire", &"fire")


func _process(_delta: float) -> bool:
	frame += 1
	if frame == 2:
		_check_mirror()
		world.set(&"enemy_kingdom", &"shadow")
		_check_plain()
		if failures.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(failures)])
		return true
	return false


# A bare level naming the kingdoms the way Skirmish does.
func _build_world(pk: StringName, ek: StringName) -> void:
	var s := GDScript.new()
	s.source_code = "extends Node3D\nvar player_kingdom := &\"%s\"\nvar enemy_kingdom := &\"%s\"\n" % [pk, ek]
	s.reload()
	world = Node3D.new()
	world.set_script(s)
	world.name = "TestWorld"
	root.add_child(world)
	current_scene = world


func _check_mirror() -> void:
	var mm := Minimap.new()
	var c1 := mm.team_mark_color(Unit.Team.ENEMY)
	var c0 := mm.team_mark_color(Unit.Team.PLAYER)
	_expect(c1 == Unit.team_display_color(Unit.Team.ENEMY), "minimap team 1 %s != team_display_color %s" \
			% [c1, Unit.team_display_color(Unit.Team.ENEMY)])
	_expect(c1 == Unit.KINGDOM_ALT_COLORS[&"fire"], "fire mirror: team 1 not in the alt palette (%s)" % c1)
	_expect(c0 == Unit.KINGDOM_COLORS[&"fire"], "fire mirror: team 0 not in the main palette (%s)" % c0)
	_expect(c0 != c1, "fire mirror: both sides share one minimap colour")
	var u1 := UIStyle.team_kingdom_color(Unit.Team.ENEMY, &"fire")
	_expect(u1 == Unit.kingdom_color_for(Unit.Team.ENEMY, &"fire"), "HUD team 1 colour %s not the alt palette" % u1)
	_expect(UIStyle.team_kingdom_color(Unit.Team.PLAYER, &"fire") == UIStyle.kingdom_color(&"fire"),
			"HUD team 0 colour changed")
	mm.free()


# Fire vs Shadow: no visual change (the old fixed minimap colours, the signature HUD colours).
func _check_plain() -> void:
	var mm := Minimap.new()
	_expect(mm.team_mark_color(Unit.Team.PLAYER) == Minimap.PLAYER_TEAM_COLOR, "fire vs shadow: team 0 mark changed")
	_expect(mm.team_mark_color(Unit.Team.ENEMY) == Minimap.ENEMY_TEAM_COLOR, "fire vs shadow: team 1 mark changed")
	_expect(UIStyle.team_kingdom_color(Unit.Team.ENEMY, &"shadow") == UIStyle.kingdom_color(&"shadow"),
			"fire vs shadow: HUD team 1 colour changed")
	mm.free()


func _expect(ok: bool, why: String) -> void:
	if not ok:
		failures.append(why)
