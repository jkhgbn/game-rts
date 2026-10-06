class_name AllyChannel
extends Node
## The 2v2 ping contract (docs/design/ai-2v2.md 5.1; UI ui-2v2.md 6, the first cut built 2026-10-06 for e2m2).
## One node per level (group "ally_channel", child of the level): the human pings its side (`ping`), the ally's brain
## (AIAlly, a mission's scripted column) reads `pinged` / `active(side)` and answers with `answer(...)`, which the HUD
## shows as the ally wizard's line. Input (first cut of ui-2v2.md 6.3): **Alt + left click** on the world = context
## ping (a hostile unit / building under the cursor -> `attack`, an own / allied one -> `defend`, the ground -> `help`);
## Alt + right click = `retreat`. Only while the human seat has an ally (`Teams.allies_of(human)` not empty).

signal pinged(p: Dictionary)
signal answered(ping_id: int, from_seat: int, kind: StringName, text: String)

const GROUP := &"ally_channel"
const HUMAN_KINDS: Array[StringName] = [&"attack", &"defend", &"help", &"retreat", &"cancel"]
const BOT_KINDS: Array[StringName] = [&"attacking", &"need_help", &"enemy_army", &"enemy_expand", &"on_my_way", &"cant"]
const TTL := 60.0
const SHORT_TTL := 10.0                  ## retreat / cancel
const MAX_PINGS := 3                     ## per seat per WINDOW s
const WINDOW := 5.0
const REFUSE_SPAM := "Too many pings"
## The standard answer lines (ai-2v2.md 5.1; English UI text, shown through Loc.sink).
const ANSWER_ON_MY_WAY := "On my way."
const ANSWER_BEHIND := "Right behind you."
const ANSWER_NOT_YET := "Not yet: my army is too small. Give me 30 seconds."
const ANSWER_TOO_STRONG := "Too strong for us. Gather first."
const ANSWER_BASE := "Your base is under attack! Coming."
const ANSWER_FALLING_BACK := "Falling back."
const KIND_COLORS := {&"attack": Color(1.0, 0.3, 0.25), &"defend": Color(0.35, 0.75, 1.0), &"help": Color(1.0, 0.85, 0.3),
		&"retreat": Color(0.85, 0.85, 0.85), &"cancel": Color(0.6, 0.6, 0.6)}

var time_source: Callable = Callable()   ## () -> float; default: engine ticks
var input_enabled := true
var _next_id := 1
var _pings: Array[Dictionary] = []
var _recent := {}                        ## seat -> Array[float] ping times
var _last_command := {}                  ## seat -> time


## The level's channel, created under `level` when missing (null when neither exists).
static func instance(tree: SceneTree, level: Node = null) -> AllyChannel:
	if tree == null:
		return null
	var c := tree.get_first_node_in_group(GROUP) as AllyChannel
	if c != null or level == null:
		return c
	c = AllyChannel.new()
	c.name = "AllyChannel"
	level.add_child(c)
	return c


func _enter_tree() -> void:
	add_to_group(GROUP)


func now() -> float:
	if time_source.is_valid():
		return float(time_source.call())
	return Time.get_ticks_msec() / 1000.0


## A ping from `from_seat` to its side: "" or the refusal. `target` = the unit / building pinged (optional).
func ping(kind: StringName, pos: Vector3, from_seat: int = Unit.Team.PLAYER, target: Node3D = null) -> String:
	var t := now()
	var recent: Array = _recent.get(from_seat, [])
	var fresh: Array = []
	for x: Variant in recent:
		if t - float(x) < WINDOW:
			fresh.append(x)
	if fresh.size() >= MAX_PINGS and HUMAN_KINDS.has(kind):
		_recent[from_seat] = fresh
		return REFUSE_SPAM
	fresh.append(t)
	_recent[from_seat] = fresh
	if kind == &"cancel":
		for i in range(_pings.size() - 1, -1, -1):
			if int(_pings[i]["from_seat"]) == from_seat:
				_pings.remove_at(i)
				break
	var short := kind == &"retreat" or kind == &"cancel"
	var p := {"id": _next_id, "kind": kind, "pos": Vector3(pos.x, 0.0, pos.z), "target": target, "from_seat": from_seat,
			"side": Teams.side_of(from_seat), "time": t, "expires": t + (SHORT_TTL if short else TTL)}
	_next_id += 1
	_pings.append(p)
	if from_seat == Teams.human_seat():
		note_command(from_seat)
	_marker(p)
	pinged.emit(p)
	return ""


## Living pings of a side, newest first.
func active(side: int) -> Array[Dictionary]:
	var t := now()
	var out: Array[Dictionary] = []
	for i in range(_pings.size() - 1, -1, -1):
		var p := _pings[i]
		if float(p["expires"]) < t:
			_pings.remove_at(i)
			continue
		if int(p["side"]) == side:
			out.append(p)
	return out


## The newest living ping of a side (empty when none).
func latest(side: int) -> Dictionary:
	var a := active(side)
	return a[0] if not a.is_empty() else {}


## The ally's reply to `ping_id` (0 = an unprompted bot line).
func answer(ping_id: int, from_seat: int, kind: StringName, text: String) -> void:
	answered.emit(ping_id, from_seat, kind, text)


func note_command(seat: int) -> void:
	_last_command[seat] = now()


func last_command_time(seat: int) -> float:
	return float(_last_command.get(seat, -INF))


# ---------------------------------------------------------------- input (first cut of ui-2v2.md 6.3)

func _input(event: InputEvent) -> void:
	if not input_enabled or not Teams.multi or Teams.allies_of(Teams.human_seat()).is_empty():
		return
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or not mb.alt_pressed:
		return
	if mb.button_index != MOUSE_BUTTON_LEFT and mb.button_index != MOUSE_BUTTON_RIGHT:
		return
	var level := get_parent()
	var sel: Variant = level.get(&"selection") if level else null
	if sel == null or not is_instance_valid(sel):
		return
	var gp: Variant = sel.call(&"ground_point", mb.position)
	if gp == null:
		return
	var human := Teams.human_seat()
	var kind := &"help"
	var target: Node3D = null
	if mb.button_index == MOUSE_BUTTON_RIGHT:
		kind = &"retreat"
	else:
		var u: Variant = sel.call(&"unit_at", mb.position)
		if u == null:
			u = sel.call(&"building_at", mb.position)
		if u != null and is_instance_valid(u) and (u as Node).get(&"team") != null:
			target = u as Node3D
			kind = &"defend" if Teams.is_ally(int(target.get(&"team")), human) else &"attack"
		elif level.has_method(&"ping_context"):   # a mission may name what a ground spot means (e2m2 grove sites)
			var k: Variant = level.call(&"ping_context", gp)
			if k is StringName and k != &"":
				kind = k
	var why := ping(kind, gp as Vector3, human, target)
	if why != "" and level.get(&"hud") != null:
		level.get(&"hud").call(&"show_message", why, 2.0)
	get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- marker

func _marker(p: Dictionary) -> void:
	var level := get_parent() as Node3D
	if level == null or not level.is_inside_tree() or DisplayServer.get_name() == "headless":
		return
	var col: Color = KIND_COLORS.get(p["kind"], Color(0.9, 0.9, 0.9))
	var ring := TorusMesh.new()
	ring.inner_radius = 1.6
	ring.outer_radius = 2.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	var mi := MeshInstance3D.new()
	mi.mesh = ring
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	level.add_child(mi)
	mi.global_position = (p["pos"] as Vector3) + Vector3(0.0, 0.25, 0.0)
	var tw := mi.create_tween()
	tw.tween_property(mi, "scale", Vector3(1.6, 1.0, 1.6), 0.6)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 2.5)
	tw.tween_callback(mi.queue_free)
