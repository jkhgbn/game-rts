extends SceneTree
## Projectile fog (fog-leak pass 2026-10-15): a projectile shot by a team not allied to the local player is drawn
## (mesh + light) only while it is in the player's sight; the player's own are always drawn; fog off = always drawn;
## the hidden shot still hits for its full damage. Same rule for SpellZone (Ember Step / Soul Siphon ground).
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_projectile_fog.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "projectile_fog"
const TIMEOUT_FRAMES := 600

const SHOOTER_SRC := "extends Node3D\nvar team := 0\n"
const TARGET_SRC := "extends Node3D\nvar team := 0\nvar hp := 100.0\nvar got := 0.0\n" \
		+ "func is_alive() -> bool:\n\treturn hp > 0.0\n" \
		+ "func target_radius() -> float:\n\treturn 0.5\n" \
		+ "func take_damage(amount: float, _attacker: Node3D) -> void:\n\tgot += amount\n\thp -= amount\n"

var main: Node
var fog: FogOfWar
var frame := 0
var _wait := 0
var _fails: Array[String] = []
var _enemy_dark: Projectile
var _enemy_seen: Projectile
var _player_dark: Projectile
var _hit_shot: Projectile
var _target: Node3D
var _enemy_zone: SpellZone
var _player_zone: SpellZone
var _dark := Vector3.ZERO
var _seen := Vector3.ZERO


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	if frame == 30:
		if not _setup():
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
			return true
	elif frame == 34:
		_check_flight()
	elif frame == 40:
		fog.enabled = false
	elif frame == 52:
		_check(_enemy_dark != null and is_instance_valid(_enemy_dark) and _enemy_dark.visible,
				"fog off: the enemy shot is not drawn again")
		_check(is_instance_valid(_enemy_zone) and _enemy_zone.visible, "fog off: the enemy zone is not drawn again")
	elif frame >= 60 and (_hit_shot == null or not is_instance_valid(_hit_shot)):
		_check(is_equal_approx(float(_target.get(&"got")), 37.0),
				"hidden shot dealt %.1f, expected 37" % float(_target.get(&"got")))
		if _fails.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out (%s)" % [TASK_ID, "; ".join(_fails)])
		return true
	return false


func _setup() -> bool:
	fog = FogOfWar.find()
	if fog == null or not fog.enabled:
		_fails.append("no enabled FogOfWar on main.tscn")
		return false
	_seen = (main.hero as Node3D).global_position
	var found := false
	for x in range(-50, 51, 4):
		for z in range(-50, 51, 4):
			var p := Vector3(x, 0.0, z)
			if fog.state_at(fog.local_team, p) == FogOfWar.UNEXPLORED and p.distance_to(_seen) > 30.0:
				_dark = p
				found = true
				break
		if found:
			break
	if not found:
		_fails.append("no unexplored point found")
		return false
	var enemy := _make(SHOOTER_SRC, Unit.Team.ENEMY, _dark)
	var mine := _make(SHOOTER_SRC, Unit.Team.PLAYER, _dark)
	var col := Color(1, 0.5, 0.2)
	# Long ground shots (slow, arc) that stay inside their area for the whole check.
	_enemy_dark = _shot()
	_enemy_dark.launch_at_point(enemy, _dark, _dark + Vector3(8, 0, 0), 0.0, 2.0, col)
	_enemy_seen = _shot()
	_enemy_seen.launch_at_point(enemy, _seen + Vector3.UP, _seen + Vector3(4, 0, 0), 0.0, 2.0, col)
	_player_dark = _shot()
	_player_dark.launch_at_point(mine, _dark, _dark + Vector3(8, 0, 0), 0.0, 2.0, col)
	_target = _make(TARGET_SRC, Unit.Team.PLAYER, _dark + Vector3(3, 0, 0))
	_hit_shot = _shot()
	_hit_shot.launch_at_target(enemy, _dark, _target, 37.0, col, 0.2)
	_enemy_zone = _zone(enemy, Unit.Team.ENEMY, _dark + Vector3(0, 0, 4))
	_player_zone = _zone(mine, Unit.Team.PLAYER, _dark + Vector3(0, 0, 4))
	_check(not _enemy_zone.visible, "enemy zone in unexplored fog drawn at spawn")
	_check(_player_zone.visible, "player's own zone hidden in fog")
	_check(not _enemy_dark.visible, "enemy shot in unexplored fog drawn at launch")
	_check(not _hit_shot.visible, "enemy aimed shot in unexplored fog drawn at launch")
	return true


func _check_flight() -> void:
	_check(not _enemy_dark.visible, "enemy shot in unexplored fog drawn in flight")
	_check(not _light_drawn(_enemy_dark), "enemy shot's light drawn in unexplored fog")
	_check(_enemy_seen.visible, "enemy shot in the player's sight not drawn")
	_check(_player_dark.visible and _light_drawn(_player_dark), "player's own shot hidden in fog")
	_check(not _enemy_zone.visible, "enemy zone in unexplored fog drawn later")


func _zone(caster: Node3D, team: int, at: Vector3) -> SpellZone:
	var z := SpellZone.new()
	z.setup(caster, team, 2.5, 4.0, 0.0, 0.5, 0.0, Color(1, 0.4, 0.1))
	z.position = at   # main sits at the origin: the zone checks the fog in _ready, so place it first
	main.add_child(z)
	return z


func _light_drawn(p: Projectile) -> bool:
	for c in p.get_children():
		if c is OmniLight3D and (c as OmniLight3D).is_visible_in_tree():
			return true
	return false


func _shot() -> Projectile:
	var p := Projectile.new()
	main.add_child(p)
	return p


func _make(src: String, team: int, at: Vector3) -> Node3D:
	var s := GDScript.new()
	s.source_code = src
	s.reload()
	var n := Node3D.new()
	n.set_script(s)
	main.add_child(n)
	n.set(&"team", team)
	n.global_position = at
	return n


func _check(ok: bool, why: String) -> void:
	if not ok:
		_fails.append(why)
