class_name CaptureRings
extends Node3D
## Capture rings on the ground and the camp memory / floating respawn timers (task 12.C6, docs/design/ui-mapfill.md 3
## and 3.1). One per level, group "capture_rings", made by `CaptureRings.attach(hud, selection)` (lead glue in hud.gd,
## guarded like the other optional UI pieces).
## - Rings: one flat QuadMesh per capture point (group "capture_points", found through CapturePoints or the group,
##   re-checked every 1 s) at (x, 0.20, z), size 2 x (capture_radius + 0.6), all sharing one Shader built in code (8
##   ShaderMaterials). Only uniforms change, at 10 Hz and at once on owner_changed / progress_changed / awakened; the
##   pulses, the contested flash and the awake-shrine spin run in the shader (TIME). Relation colours (own green / enemy
##   red), not the kingdom colours. The owner and shrine state are always shown (points are explored for both teams from
##   0:00); the capture arc and the contested flash only where the local team sees the point now.
## - Camp memory (read by the minimap): per camp `state` &"unknown" / &"alive" / &"cleared" (updated at 2 Hz from what
##   the local team sees; fogged camps keep their last state; explored but never seen = &"alive") and `known_cleared`
##   (set on CampManager.camp_cleared when the local team cleared it or saw it cleared, reset on the camp's respawned).
## - Floating `1:20` (Label3D) over a known-cleared camp while its spot is visible: respawn_left() as m:ss, 2 Hz, gold in
##   the last 10 s, hidden while the timer reads 0 (the respawn waits for units to leave).
## Every step-12 class is reached untyped (groups, has_method, get), so this works with any of them missing.

const GROUP := &"capture_rings"
const LOCAL_TEAM := 0                        ## Unit.Team.PLAYER
const ENEMY_TEAM := 1
const RING_Y := 0.20
const RING_MARGIN := 0.6                     ## The quad reaches this far past the capture radius (inner glow + width).
const RING_WIDTH := 0.20
const ARC_WIDTH_FACTOR := 1.8
const SELECTED_WIDTH_FACTOR := 1.5
const SELECTED_ALPHA_ADD := 0.2
const DASHES := 24.0
const REFRESH_INTERVAL := 0.1                ## Uniforms at 10 Hz.
const SCAN_INTERVAL := 1.0                   ## New points / camps.
const CAMP_INTERVAL := 0.5                   ## Camp memory + timer labels at 2 Hz.

const OWN := Color(0.3, 1.0, 0.4)
const ENEMY := Color(1.0, 0.3, 0.3)
const GOLD := Color(1.0, 0.85, 0.4)
const NEUTRAL_RING := Color(0.85, 0.85, 0.85, 0.40)
const ASLEEP_RING := Color(0.60, 0.60, 0.65, 0.25)
const HELD_ALPHA := 0.70
const ARC_ALPHA := 0.9
const CONTESTED_ALPHA := 0.9
const ASLEEP_HELD_ALPHA := 0.40
const AWAKE_ALPHA := 0.7                     ## 0.5-0.9 pulse at 1 Hz.
const AWAKE_PULSE := 0.2
const AWAKE_SPIN := 0.2                      ## Dashes turn at 0.2 rad / s.
const CONTESTED_FLASH_HZ := 3.0

const TIMER_COLOR := Color(0.85, 0.85, 0.80)
const TIMER_FONT_SIZE := 40
const TIMER_PIXEL_SIZE := 0.006
const TIMER_OUTLINE := 8
const TIMER_HEIGHT := 1.0
const TIMER_GOLD_SECONDS := 10.0

const STATE_UNKNOWN := &"unknown"
const STATE_ALIVE := &"alive"
const STATE_CLEARED := &"cleared"

const SHADER_CODE := """shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform float radius = 7.0;
uniform float width = 0.2;
uniform vec4 color : source_color = vec4(1.0);
uniform float dashes = 0.0;
uniform float dash_phase = 0.0;
uniform float dash_spin = 0.0;
uniform vec4 arc_color : source_color = vec4(1.0);
uniform float progress = 0.0;
uniform float flash = 0.0;
uniform float flash_hz = 0.0;
uniform float pulse = 0.0;
uniform float pulse_hz = 1.0;
uniform float glow = 0.0;

varying vec2 local_xz;

void vertex() {
	local_xz = VERTEX.xz;
}

void fragment() {
	float d = length(local_xz);
	float ang = atan(local_xz.x, -local_xz.y);
	if (ang < 0.0) {
		ang += TAU;
	}
	float f = flash_hz > 0.0 ? 0.5 + 0.5 * sin(TIME * TAU * flash_hz) : flash;
	vec3 ring_rgb = mix(color.rgb, vec3(1.0), f);
	float ring_a = clamp(color.a + pulse * sin(TIME * TAU * pulse_hz), 0.0, 1.0);
	bool in_arc = progress > 0.0 && ang < progress * TAU;
	float half_w = in_arc ? width * 0.9 : width * 0.5;
	float aa = max(fwidth(d), 0.001);
	float band = 1.0 - smoothstep(half_w - aa, half_w + aa, abs(d - radius));
	if (!in_arc && dashes > 0.5) {
		float seg = fract((ang + dash_phase + TIME * dash_spin) / TAU * dashes);
		band *= step(seg, 0.6);
	}
	float band_a = band * (in_arc ? arc_color.a : ring_a);
	vec3 band_rgb = in_arc ? arc_color.rgb : ring_rgb;
	float g = 0.0;
	if (d < radius && d > radius - 0.6) {
		g = ring_a * 0.25 * (d - radius + 0.6) / 0.6 * glow;
	}
	ALBEDO = band_a >= g ? band_rgb : ring_rgb;
	ALPHA = max(band_a, g);
}
"""

static var _shader: Shader

## The selection manager (reads `selected_neutral` for the selected look). Untyped: the tests may pass a stub.
var selection: Node
var hud: Node
## Read only (tests): uniform updates applied since setup, labels shown in the last camp pass.
var uniform_updates := 0
var shown_timers := 0

var _rings := {}             # point instance id -> {point, mesh, mat, look}
var _camps := {}             # camp instance id -> {camp, state, known_cleared, label}
var _manager: Node = null    # CampManager
var _fog: FogOfWar = null
var _refresh_left := 0.0
var _scan_left := 0.0
var _camp_left := 0.0


## Adds the (single) CaptureRings node to the level (the HUD's parent) and binds it; returns the existing one on a
## second call.
static func attach(p_hud: Node, p_selection: Node) -> CaptureRings:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		for n in tree.get_nodes_in_group(GROUP):
			if n is CaptureRings and not n.is_queued_for_deletion():
				var existing := n as CaptureRings
				existing.hud = p_hud
				existing.selection = p_selection
				return existing
	var rings := CaptureRings.new()
	rings.name = "CaptureRings"
	rings.hud = p_hud
	rings.selection = p_selection
	var parent: Node = p_hud.get_parent() if p_hud != null and p_hud.get_parent() != null else p_hud
	if parent != null:
		parent.add_child(rings)
	return rings


func _init() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	_scan()
	_scan_camps()
	refresh_now()


func _process(delta: float) -> void:
	_scan_left -= delta
	if _scan_left <= 0.0:
		_scan_left = SCAN_INTERVAL
		_scan()
		_scan_camps()
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = REFRESH_INTERVAL
		for id in _rings.keys():
			_refresh_ring(id)
	_camp_left -= delta
	if _camp_left <= 0.0:
		_camp_left = CAMP_INTERVAL
		_update_camps()


# ---------------------------------------------------------------- public

## Refreshes every ring and the camp memory now (tests; the node also does it on its own clock).
func refresh_now() -> void:
	for id in _rings.keys():
		_refresh_ring(id)
	_update_camps()


## Number of rings (one per capture point found).
func ring_count() -> int:
	_prune_rings()
	return _rings.size()


## The ring mesh of a point, or null.
func ring_of(point: Node) -> MeshInstance3D:
	if point == null or not is_instance_valid(point):
		return null
	var r: Variant = _rings.get(point.get_instance_id())
	return (r as Dictionary)["mesh"] if r is Dictionary else null


## The uniforms the ring of `point` has now ({} when the point has no ring): radius, width, color, dashes, dash_spin,
## arc_color, progress, flash, flash_hz, pulse, glow.
func ring_look(point: Node) -> Dictionary:
	if point == null or not is_instance_valid(point):
		return {}
	var r: Variant = _rings.get(point.get_instance_id())
	return ((r as Dictionary)["look"] as Dictionary).duplicate() if r is Dictionary else {}


## The last-seen state of a camp: &"unknown" (never explored), &"alive" or &"cleared".
func camp_state(camp: Node) -> StringName:
	if camp == null or not is_instance_valid(camp):
		return STATE_UNKNOWN
	var m: Variant = _camps.get(camp.get_instance_id())
	return StringName((m as Dictionary)["state"]) if m is Dictionary else STATE_UNKNOWN


## True when the local team cleared the camp or saw it cleared, until it respawns.
func is_known_cleared(camp: Node) -> bool:
	if camp == null or not is_instance_valid(camp):
		return false
	var m: Variant = _camps.get(camp.get_instance_id())
	return bool((m as Dictionary)["known_cleared"]) if m is Dictionary else false


## The floating respawn timer of a camp (null until it was first needed).
func timer_label(camp: Node) -> Label3D:
	if camp == null or not is_instance_valid(camp):
		return null
	var m: Variant = _camps.get(camp.get_instance_id())
	if not m is Dictionary:
		return null
	var l: Variant = (m as Dictionary)["label"]
	return l as Label3D if l != null and is_instance_valid(l) else null


## "m:ss" of a number of seconds (rounded up).
static func time_text(seconds: float) -> String:
	var s := maxi(0, ceili(seconds))
	return "%d:%02d" % [s / 60, s % 60]


## The shared ring shader (built once).
static func ring_shader() -> Shader:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER_CODE
	return _shader


# ---------------------------------------------------------------- rings

## Every capture point (the CapturePoints service's list, else the group).
func _points() -> Array:
	if not is_inside_tree():
		return []
	var svc := get_tree().get_first_node_in_group(&"capture_points_service")
	if svc != null and svc.has_method(&"points"):
		var list: Variant = svc.call(&"points")
		if list is Array:
			return list
	return get_tree().get_nodes_in_group(&"capture_points")


## Makes a ring for every point that has none (points never move; missions may add some later).
func _scan() -> void:
	_prune_rings()
	for p: Variant in _points():
		if not p is Node3D or not is_instance_valid(p) or _rings.has((p as Node).get_instance_id()):
			continue
		_add_ring(p as Node3D)


func _prune_rings() -> void:
	for id in _rings.keys():
		var r: Dictionary = _rings[id]
		if not is_instance_valid(r["point"]) or not (r["point"] as Node).is_inside_tree():
			if is_instance_valid(r["mesh"]):
				(r["mesh"] as Node).queue_free()
			_rings.erase(id)


func _add_ring(point: Node3D) -> void:
	var radius := float(point.get(&"capture_radius")) if point.get(&"capture_radius") != null else 6.0
	var quad := QuadMesh.new()
	quad.orientation = PlaneMesh.FACE_Y
	quad.size = Vector2.ONE * 2.0 * (radius + RING_MARGIN)
	var mat := ShaderMaterial.new()
	mat.shader = ring_shader()
	var mesh := MeshInstance3D.new()
	mesh.name = "Ring_%s" % str(point.get(&"point_id")) if point.get(&"point_id") != null else "Ring"
	mesh.mesh = quad
	mesh.material_override = mat
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)
	var at := point.global_position
	mesh.global_position = Vector3(at.x, RING_Y, at.z)
	var id := point.get_instance_id()
	_rings[id] = {"point": point, "mesh": mesh, "mat": mat, "look": {}}
	for sig: StringName in [&"owner_changed", &"progress_changed"]:
		if point.has_signal(sig):
			var cb := Callable(self, &"_on_point_signal").bind(id)
			if not point.is_connected(sig, cb):
				point.connect(sig, cb)
	if point.has_signal(&"awakened"):
		var cb2 := Callable(self, &"_on_point_awakened").bind(id)
		if not point.is_connected(&"awakened", cb2):
			point.connect(&"awakened", cb2)
	_refresh_ring(id)


func _on_point_signal(_point: Variant, _a: Variant, _b: Variant, id: int) -> void:
	_refresh_ring(id)


func _on_point_awakened(_point: Variant, id: int) -> void:
	_refresh_ring(id)


func _refresh_ring(id: int) -> void:
	var r: Variant = _rings.get(id)
	if not r is Dictionary:
		return
	var ring := r as Dictionary
	var point: Variant = ring["point"]
	if not is_instance_valid(point):
		return
	var look := look_for(point as Node3D)
	var old: Dictionary = ring["look"]
	var mat: ShaderMaterial = ring["mat"]
	for key: String in look:
		if not old.has(key) or old[key] != look[key]:
			mat.set_shader_parameter(key, look[key])
			uniform_updates += 1
	ring["look"] = look


## The ring uniforms for a point's current state (ui-mapfill.md 3, table).
func look_for(point: Node3D) -> Dictionary:
	var radius := float(point.get(&"capture_radius")) if point.get(&"capture_radius") != null else 6.0
	var kind := StringName(str(point.get(&"kind")))
	var held := int(point.get(&"owner_team")) if point.get(&"owner_team") != null else -1
	var awake := not point.has_method(&"is_awake") or bool(point.call(&"is_awake"))
	var look := {
		"radius": radius, "width": RING_WIDTH, "color": NEUTRAL_RING, "dashes": DASHES, "dash_phase": 0.0,
		"dash_spin": 0.0, "arc_color": Color(1, 1, 1, 0), "progress": 0.0, "flash": 0.0, "flash_hz": 0.0,
		"pulse": 0.0, "pulse_hz": 1.0, "glow": 0.0,
	}
	if kind == &"shrine" and not awake:
		if held == LOCAL_TEAM or held == ENEMY_TEAM:
			look["color"] = Color(relation_color(held), ASLEEP_HELD_ALPHA)
			look["dashes"] = 0.0
		else:
			look["color"] = ASLEEP_RING
	elif kind == &"shrine":
		look["color"] = Color(GOLD, AWAKE_ALPHA)
		look["pulse"] = AWAKE_PULSE
		look["dash_spin"] = AWAKE_SPIN
		look["glow"] = 1.0
	elif held == LOCAL_TEAM or held == ENEMY_TEAM:
		look["color"] = Color(relation_color(held), HELD_ALPHA)
		look["dashes"] = 0.0
		look["glow"] = 1.0
	# The capture arc and the contested flash: only where the local team sees the point now.
	if _visible(point.global_position):
		var progress := float(point.get(&"progress")) if point.get(&"progress") != null else 0.0
		var capturer := int(point.get(&"capture_team")) if point.get(&"capture_team") != null else -1
		if progress > 0.0 and (capturer == LOCAL_TEAM or capturer == ENEMY_TEAM):
			look["arc_color"] = Color(relation_color(capturer), ARC_ALPHA)
			look["progress"] = clampf(progress, 0.0, 1.0)
		var contested: bool = point.has_method(&"is_contested") and bool(point.call(&"is_contested"))
		if contested:
			look["flash_hz"] = CONTESTED_FLASH_HZ
			look["color"] = Color(look["color"] as Color, CONTESTED_ALPHA)
	if _is_selected(point):
		look["width"] = float(look["width"]) * SELECTED_WIDTH_FACTOR
		var c: Color = look["color"]
		look["color"] = Color(c, minf(1.0, c.a + SELECTED_ALPHA_ADD))
	return look


## Own green / enemy red (relation colours).
static func relation_color(team: int) -> Color:
	return OWN if team == LOCAL_TEAM else ENEMY


func _is_selected(point: Node) -> bool:
	if selection == null or not is_instance_valid(selection):
		return false
	var s: Variant = selection.get(&"selected_neutral")
	return s != null and is_instance_valid(s) and s == point


# ---------------------------------------------------------------- camps

func _camp_manager() -> Node:
	if _manager != null and is_instance_valid(_manager) and not _manager.is_queued_for_deletion():
		return _manager
	_manager = null
	if is_inside_tree():
		for n in get_tree().get_nodes_in_group(&"camp_manager"):
			if n.has_method(&"camps") and not n.is_queued_for_deletion():
				_manager = n
				break
	if _manager != null and _manager.has_signal(&"camp_cleared") \
			and not _manager.is_connected(&"camp_cleared", _on_camp_cleared):
		_manager.connect(&"camp_cleared", _on_camp_cleared)
	return _manager


## Every camp (the CampManager's list, else the group "neutral_camps").
func _camp_list() -> Array:
	var m := _camp_manager()
	if m != null:
		var list: Variant = m.call(&"camps")
		if list is Array:
			return list
	return get_tree().get_nodes_in_group(&"neutral_camps") if is_inside_tree() else []


func _scan_camps() -> void:
	if not is_inside_tree():
		return
	for id in _camps.keys():
		var c: Variant = (_camps[id] as Dictionary)["camp"]
		if not is_instance_valid(c):
			var l: Variant = (_camps[id] as Dictionary)["label"]
			if l != null and is_instance_valid(l):
				(l as Node).queue_free()
			_camps.erase(id)
	for c: Variant in _camp_list():
		if not c is Node3D or not is_instance_valid(c):
			continue
		_mem(c as Node3D)


func _mem(camp: Node3D) -> Dictionary:
	var id := camp.get_instance_id()
	if _camps.has(id):
		return _camps[id]
	var m := {"camp": camp, "state": STATE_UNKNOWN, "known_cleared": false, "label": null}
	_camps[id] = m
	if camp.has_signal(&"respawned"):
		var cb := Callable(self, &"_on_camp_respawned")
		if not camp.is_connected(&"respawned", cb):
			camp.connect(&"respawned", cb)
	return m


func _on_camp_cleared(camp: Variant, team: int, _reward: Variant) -> void:
	if not camp is Node3D or not is_instance_valid(camp):
		return
	var m := _mem(camp as Node3D)
	var seen := _visible((camp as Node3D).global_position)
	if team == LOCAL_TEAM or seen:
		m["known_cleared"] = true
		m["state"] = STATE_CLEARED
	_update_label(m)


func _on_camp_respawned(camp: Variant) -> void:
	if not camp is Node3D or not is_instance_valid(camp):
		return
	var m := _mem(camp as Node3D)
	m["known_cleared"] = false
	if _visible((camp as Node3D).global_position):
		m["state"] = STATE_ALIVE
	_update_label(m)


## 2 Hz: the last-seen state of every camp the local team sees now, and the timer labels.
func _update_camps() -> void:
	if not is_inside_tree():
		return
	if _camps.is_empty():
		_scan_camps()
	shown_timers = 0
	for id in _camps.keys():
		var m: Dictionary = _camps[id]
		var camp: Variant = m["camp"]
		if not is_instance_valid(camp):
			continue
		var c := camp as Node3D
		var pos := c.global_position
		if _visible(pos):
			var cleared: bool = c.has_method(&"is_cleared") and bool(c.call(&"is_cleared"))
			m["state"] = STATE_CLEARED if cleared else STATE_ALIVE
			if not cleared:
				m["known_cleared"] = false   # seen alive again (a respawn this node missed)
		elif StringName(m["state"]) == STATE_UNKNOWN and _explored(pos):
			m["state"] = STATE_ALIVE
		_update_label(m)


func _update_label(m: Dictionary) -> void:
	var camp: Variant = m["camp"]
	if not is_instance_valid(camp):
		return
	var c := camp as Node3D
	var left := float(c.call(&"respawn_left")) if c.has_method(&"respawn_left") else 0.0
	var show := bool(m["known_cleared"]) and _visible(c.global_position) and ceili(left) > 0
	var label: Label3D = null
	if m["label"] != null and is_instance_valid(m["label"]):
		label = m["label"]
	if not show:
		if label != null:
			label.visible = false
		return
	if label == null:
		label = _make_label()
		m["label"] = label
	label.global_position = c.global_position + Vector3(0.0, TIMER_HEIGHT, 0.0)
	var text := time_text(left)
	if label.text != text:
		label.text = text
	label.modulate = GOLD if left <= TIMER_GOLD_SECONDS else TIMER_COLOR
	label.visible = true
	shown_timers += 1


func _make_label() -> Label3D:
	var l := Label3D.new()
	l.name = "CampTimer"
	l.font_size = TIMER_FONT_SIZE
	l.pixel_size = TIMER_PIXEL_SIZE
	l.modulate = TIMER_COLOR
	l.outline_modulate = Color.BLACK
	l.outline_size = TIMER_OUTLINE
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	l.visible = false
	add_child(l)
	return l


# ---------------------------------------------------------------- fog

func _get_fog() -> FogOfWar:
	if _fog != null and is_instance_valid(_fog):
		return _fog
	_fog = FogOfWar.find() if is_inside_tree() else null
	return _fog


## True where the local team sees now (no fog / fog off: everywhere).
func _visible(pos: Vector3) -> bool:
	var fog := _get_fog()
	return fog == null or not fog.enabled or fog.is_visible(LOCAL_TEAM, pos)


func _explored(pos: Vector3) -> bool:
	var fog := _get_fog()
	return fog == null or not fog.enabled or fog.is_explored(LOCAL_TEAM, pos)
