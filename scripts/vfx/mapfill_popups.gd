class_name MapfillPopups
extends Node3D
## The map-fill listener (step 12, task 12.C7; spec: map-fill.md 3.4 / 4 / 5 / 8, layout: docs/design/ui-mapfill.md
## 7.3, 10, 14): one node in the level, group "mapfill_popups", made by `MapfillPopups.attach(hud)`
## (GameHUD._setup_map_fill). For the local player (the fog's local team, else 0) it owns:
## - the messages of the three map-fill services (CapturePoints, CampManager, EpicBeasts `message(text, seconds)`):
##   one handler forwards them to `hud.show_message`, DROPPING a line identical to one shown in the last 20 s (every
##   point line carries the point's name, so point lines come at most once per 20 s per point). Once connected, the
##   level's own forwarding of those three signals (the skirmish connects them to the HUD) is disconnected, so each
##   line is shown once and goes through the filter;
## - the first-time hint at 0:40 of match time: `Stand near a watchtower, well or shrine with soldiers to capture it`
##   (once; only when there are capture points; skipped when the player already holds one; it waits, up to 30 s,
##   while the HUD's message line shows another line, so it never replaces a more important message);
## - the floating `+5` / `+1` essence over a hunted game critter and the `+40` venison heal over the hunter (own team,
##   critter visible at that moment; Label3D pool of 6, a 7th replaces the oldest);
## - the sounds (bus SFX): capture chime (own capture), distant horn (a shrine wakes, max 1 per 2 s), soft bubble (an
##   own well on screen, checked every 5 s from 2:30, max 1 per 10 s), drum (a camp cleared with its spot visible and
##   within 60 m of the camera focus), stag roar (a Hollow Stag camp engaged, same rule, max 1 per 20 s per camp),
##   beast roar (a beast spawns), wading splashes (3 pooled 3D players at a visible unit on screen that starts to wade,
##   max 1 per 4 s per unit).
## Services are found untyped (groups) and connected guarded (has_signal), retried every 0.5 s while missing.

const GROUP := &"mapfill_popups"
const PLAYER_TEAM := 0
const POOL_SIZE := 6
const RISE := 1.5                 ## Metres a text rises over its life.
const LIFE := 1.0
const FADE := 0.4                 ## The last 0.4 s fade out.
const FONT_SIZE := 40
const PIXEL_SIZE := 0.006
const OUTLINE := 8
const ESSENCE_COLOR := Color(0.75, 0.45, 1.0)
const HEAL_COLOR := Color(0.4, 0.9, 0.4)
const DEER_OFFSET := Vector3(0.0, 1.6, 0.0)
const RABBIT_OFFSET := Vector3(0.0, 0.8, 0.0)
const HUNTER_EXTRA := 0.9         ## Above the hunter's body_height.
const HEAL_DELAY := 0.15
const SCAN_TIME := 0.5
const DUP_WINDOW := 20.0          ## A line identical to one shown in the last 20 s is dropped.
const HINT_TIME := 40.0
const HINT_TEXT := "Stand near a watchtower, well or shrine with soldiers to capture it"
const HINT_SECONDS := 6.0
const HINT_MAX_WAIT := 30.0       ## The hint waits at most this long (s) for the message line to be free.
const WELL_START := 150.0         ## CapturePoints.WELL_START (2:30).
const BUBBLE_CHECK := 5.0
const NEAR_CAMERA := 60.0         ## Camp / stag sounds only within this many metres of the camera focus.
const STAG_INTERVAL := 20.0
const SPLASH_SCAN := 0.2          ## 5 Hz.
const SPLASH_PER_UNIT := 4.0
const SPLASH_PLAYERS := 3
const SPLASH_DB := -18.0
const SPLASH_RANGE := 60.0
## Audio Lab: with the default unit_size 10 the splash lost 9.5 dB at the default zoom (30 m) and was about -44 LUFS
## in game. unit_size 18 (like GameAudio: -4.4 dB at 30 m, -10.5 dB at the 60 m cut-off) and a denser file put it
## near -30 LUFS, inside the frequent-unit range (-36..-22).
const SPLASH_UNIT_SIZE := 18.0
const FORD_MODIFIER := &"terrain:ford"
const SPLASH_PATH := "res://assets/audio/mapfill_splash.wav"
const SERVICE_GROUPS: Array[StringName] = [&"capture_points_service", &"camp_manager", &"epic_beasts"]
const SOUNDS := {
	&"chime": {"path": "res://assets/audio/mapfill_chime.wav", "interval": 0.3, "db": -6.0},
	&"horn": {"path": "res://assets/audio/mapfill_horn.wav", "interval": 2.0, "db": 0.0},
	&"bubble": {"path": "res://assets/audio/mapfill_bubble.wav", "interval": 10.0, "db": -12.0},
	&"drum": {"path": "res://assets/audio/mapfill_drum.wav", "interval": 0.5, "db": -6.0},
	&"stag": {"path": "res://assets/audio/mapfill_stag.wav", "interval": 1.0, "db": 0.0},
	&"roar": {"path": "res://assets/audio/mapfill_roar.wav", "interval": 1.0, "db": -8.0},
}

var hud: Node
## Read only (tests): every line shown through this node, every line dropped by the 20 s filter, sound plays,
## splash plays, and whether the 0:40 hint is done (shown or skipped).
var messages: Array[String] = []
var dropped: Array[String] = []
var sound_counts := {&"chime": 0, &"horn": 0, &"bubble": 0, &"drum": 0, &"stag": 0, &"roar": 0}
var splash_count := 0
var hint_done := false
var hint_shown := false

var _labels: Array[Label3D] = []
var _ages: Array[float] = []      # per pool label: seconds since it started (-1 = free, < -1 = waiting to start)
var _starts: Array[Vector3] = []
var _players := {}                # sound id -> AudioStreamPlayer
var _last_sound := {}             # sound id -> _clock of the last play
var _splash: Array[AudioStreamPlayer3D] = []
var _clock := 0.0
var _scan_left := 0.0
var _bubble_left := BUBBLE_CHECK
var _splash_left := 0.0
var _shown_at := {}               # message text -> _clock when last shown
var _stag_at := {}                # camp instance id -> _clock of its last roar
var _wading := {}                 # unit instance id -> true while it wades (splash edge)
var _splash_at := {}              # unit instance id -> _clock of its last splash
var _pending_heals: Array = []    # [time left, hunter, text]
var _hint_due_at := -1.0          # _clock when the 0:40 hint first came due (-1 = not yet)


## Adds the listener to the HUD's level once (a second call returns the same node).
static func attach(p_hud: Node) -> MapfillPopups:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		for n in tree.get_nodes_in_group(GROUP):
			if n is MapfillPopups and not n.is_queued_for_deletion():
				(n as MapfillPopups).hud = p_hud
				return n
	var p := MapfillPopups.new()
	p.name = "MapfillPopups"
	p.hud = p_hud
	var level: Node = p_hud.get_parent() if p_hud != null else null
	if level == null and tree != null:
		level = tree.current_scene
	if level != null:
		level.add_child(p)
	return p


func _init() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	for i in POOL_SIZE:
		var l := Label3D.new()
		l.font_size = FONT_SIZE
		l.pixel_size = PIXEL_SIZE
		l.outline_size = OUTLINE
		l.outline_modulate = Color.BLACK
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true
		l.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		l.visible = false
		add_child(l)
		_labels.append(l)
		_ages.append(-1.0)
		_starts.append(Vector3.ZERO)
	for id: StringName in SOUNDS:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		p.volume_db = float((SOUNDS[id] as Dictionary)["db"])
		var path := str((SOUNDS[id] as Dictionary)["path"])
		if ResourceLoader.exists(path):
			p.stream = load(path) as AudioStream
		add_child(p)
		_players[id] = p
	var splash_stream: AudioStream = load(SPLASH_PATH) as AudioStream if ResourceLoader.exists(SPLASH_PATH) else null
	for i in SPLASH_PLAYERS:
		var s := AudioStreamPlayer3D.new()
		s.bus = &"SFX"
		s.volume_db = SPLASH_DB
		s.unit_size = SPLASH_UNIT_SIZE
		s.max_distance = SPLASH_RANGE
		s.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		s.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_DISABLED
		s.stream = splash_stream
		add_child(s)
		_splash.append(s)
	_scan()


func _process(delta: float) -> void:
	_clock += delta
	_scan_left -= delta
	if _scan_left <= 0.0:
		_scan_left = SCAN_TIME
		_scan()
		_check_hint()
	_bubble_left -= delta
	if _bubble_left <= 0.0:
		_bubble_left = BUBBLE_CHECK
		_check_bubble()
	_splash_left -= delta
	if _splash_left <= 0.0:
		_splash_left = SPLASH_SCAN
		_scan_splashes()
	_tick_heals(delta)
	for i in _labels.size():
		if _ages[i] < 0.0:
			continue
		_ages[i] += delta
		var t := _ages[i]
		var l := _labels[i]
		if t >= LIFE:
			_ages[i] = -1.0
			l.visible = false
			continue
		var k := t / LIFE
		var ease_out := 1.0 - (1.0 - k) * (1.0 - k)
		l.global_position = _starts[i] + Vector3(0.0, RISE * ease_out, 0.0)
		var a := clampf((LIFE - t) / FADE, 0.0, 1.0)
		l.modulate.a = a
		l.outline_modulate.a = a


# ---------------------------------------------------------------- sources

## Connects the services that exist now; takes the three message signals over from the level.
func _scan() -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	for g in SERVICE_GROUPS:
		var s := tree.get_first_node_in_group(g)
		if s != null:
			_take_messages(s)
	var cp := tree.get_first_node_in_group(&"capture_points_service")
	if cp != null:
		_hook(cp, &"point_captured", _on_point_captured)
		_hook(cp, &"shrine_awakened", _on_shrine_awakened)
	var cm := tree.get_first_node_in_group(&"camp_manager")
	if cm != null:
		_hook(cm, &"camp_cleared", _on_camp_cleared)
		if cm.has_method(&"camps"):
			for camp: Variant in cm.call(&"camps"):
				if camp is Node and StringName(str((camp as Node).get(&"kind"))) == &"hollow_stag":
					_hook(camp, &"engaged", _on_camp_engaged)
	var eb := tree.get_first_node_in_group(&"epic_beasts")
	if eb != null:
		_hook(eb, &"beast_spawned", _on_beast_spawned)
	var ch := tree.get_first_node_in_group(&"critter_herds")
	if ch != null:
		_hook(ch, &"critter_hunted", _on_critter_hunted)


func _hook(obj: Object, sig: StringName, callback: Callable) -> void:
	if obj == null or not is_instance_valid(obj) or not obj.has_signal(sig) or obj.is_connected(sig, callback):
		return
	obj.connect(sig, callback)


## Connects `service.message` to route_message and drops the level's / HUD's own forwarding of it (the filter is the
## only way those lines reach the screen). Other listeners are left alone.
func _take_messages(service: Node) -> void:
	if not service.has_signal(&"message"):
		return
	_hook(service, &"message", route_message)
	var level: Node = hud.get_parent() if hud != null and is_instance_valid(hud) else null
	for conn: Dictionary in service.get_signal_connection_list(&"message"):
		var c: Callable = conn.get("callable", Callable())
		var target := c.get_object()
		if target == null or target == self:
			continue
		if (level != null and target == level) or (hud != null and target == hud):
			service.disconnect(&"message", c)


# ---------------------------------------------------------------- messages

## The one handler of the services' `message(text, seconds)`: shows the line unless an identical one was shown in
## the last 20 s. Returns true when shown.
func route_message(text: String, seconds: float = 4.0) -> bool:
	if text == "":
		return false
	var last := float(_shown_at.get(text, -1.0e9))
	if _clock - last < DUP_WINDOW:
		dropped.append(text)
		return false
	_shown_at[text] = _clock
	messages.append(text)
	if hud != null and is_instance_valid(hud) and hud.has_method(&"show_message"):
		hud.call(&"show_message", text, seconds)
	return true


## The 0:40 hint: once, when capture points exist, unless the player already holds one.
func _check_hint() -> void:
	if hint_done or not is_inside_tree():
		return
	var cp := get_tree().get_first_node_in_group(&"capture_points_service")
	if cp == null or not cp.has_method(&"points"):
		return
	var pts: Array = cp.call(&"points")
	if pts.is_empty():
		return
	var now := float(cp.call(&"match_time")) if cp.has_method(&"match_time") else _clock
	if now < HINT_TIME:
		return
	var team := local_team()
	for p: Variant in pts:
		if p is Node and (p as Node).get(&"owner_team") != null and int((p as Node).get(&"owner_team")) == team:
			hint_done = true
			return   # already holds one: no hint
	# A tip never replaces another line (a tavern opening, a capture...): it waits for a free message line,
	# at most HINT_MAX_WAIT seconds.
	if _hint_due_at < 0.0:
		_hint_due_at = _clock
	if _message_line_busy() and _clock - _hint_due_at < HINT_MAX_WAIT:
		return
	hint_done = true
	hint_shown = route_message(HINT_TEXT, HINT_SECONDS)


## True while the HUD's message line still shows another line.
func _message_line_busy() -> bool:
	if hud == null or not is_instance_valid(hud):
		return false
	if hud.has_method(&"is_message_shown"):
		return bool(hud.call(&"is_message_shown"))
	var left: Variant = hud.get(&"_message_time")   # GameHUD has no public getter for its message line yet
	return left != null and float(left) > 0.0


# ---------------------------------------------------------------- handlers

## CapturePoints.point_captured: the chime for the local team.
func _on_point_captured(_point: Node, team: int) -> void:
	if team == local_team():
		play_sound(&"chime")


## CapturePoints.shrine_awakened: the distant horn (max 1 per 2 s).
func _on_shrine_awakened(_point: Node) -> void:
	play_sound(&"horn")


## CampManager.camp_cleared: the drum when the spot is visible and near the camera focus.
func _on_camp_cleared(camp: Node, _team: int, _reward: Dictionary) -> void:
	if camp is Node3D and _audible_spot((camp as Node3D).global_position):
		play_sound(&"drum")


## NeutralCamp.engaged of a Hollow Stag camp: its roar (visible, near the camera, max 1 per 20 s per camp).
func _on_camp_engaged(camp: Node) -> void:
	if not (camp is Node3D) or not _audible_spot((camp as Node3D).global_position):
		return
	var id := camp.get_instance_id()
	if _clock - float(_stag_at.get(id, -1.0e9)) < STAG_INTERVAL:
		return
	_stag_at[id] = _clock
	play_sound(&"stag")


## EpicBeasts.beast_spawned: the far roar (the message is the service's; the minimap ping is 12.C6's).
func _on_beast_spawned(_beast: Node, _lair_id: StringName, _variant: int) -> void:
	play_sound(&"roar")


## CritterHerds.critter_hunted: `+5` / `+1` over the critter and, for a deer, `+40` over the hunter 0.15 s later
## (own team, critter visible at that moment).
func _on_critter_hunted(critter: Node, team: int, reward: Dictionary) -> void:
	if team != local_team() or critter == null or not is_instance_valid(critter) or not (critter is Node3D):
		return
	var c := critter as Node3D
	if not c.is_visible_in_tree():
		return
	var deer := StringName(str(c.get(&"kind"))) == &"deer"
	var essence := int(reward.get(&"essence", reward.get("essence", 0)))
	if essence > 0:
		popup("+%d" % essence, c.global_position + (DEER_OFFSET if deer else RABBIT_OFFSET), ESSENCE_COLOR)
	if deer:
		var hunter: Variant = c.get(&"killer")
		if is_instance_valid(hunter) and hunter is Node3D:
			var heal := 40
			var herds := get_tree().get_first_node_in_group(&"critter_herds") if is_inside_tree() else null
			if herds != null and herds.get_script() is Script:
				heal = int((herds.get_script() as Script).get_script_constant_map().get("VENISON_HEAL", heal))
			_pending_heals.append([HEAL_DELAY, hunter, "+%d" % heal])


func _tick_heals(delta: float) -> void:
	for i in range(_pending_heals.size() - 1, -1, -1):
		var e: Array = _pending_heals[i]
		e[0] = float(e[0]) - delta
		if float(e[0]) > 0.0:
			continue
		_pending_heals.remove_at(i)
		var hunter: Variant = e[1]
		if not is_instance_valid(hunter) or not (hunter is Node3D):
			continue   # the hunter was freed meanwhile
		var h := hunter as Node3D
		var bh: Variant = h.get(&"body_height")
		var height := float(bh) if bh != null else 1.6
		popup(str(e[2]), h.global_position + Vector3(0.0, height + HUNTER_EXTRA, 0.0), HEAL_COLOR)


# ---------------------------------------------------------------- bubble and splashes

## Every 5 s from 2:30: the bubble when an own well is on screen (the sound's own limit: 1 per 10 s).
func _check_bubble() -> void:
	if not is_inside_tree():
		return
	var cp := get_tree().get_first_node_in_group(&"capture_points_service")
	if cp == null or not cp.has_method(&"points"):
		return
	var now := float(cp.call(&"match_time")) if cp.has_method(&"match_time") else _clock
	if now < WELL_START:
		return
	var team := local_team()
	for w: Variant in cp.call(&"points", &"well"):
		if w is Node3D and int((w as Node3D).get(&"owner_team")) == team and on_screen((w as Node3D).global_position):
			play_sound(&"bubble")
			return


## 5 Hz: visible units on screen that just started to wade (gained `terrain:ford`) splash (3 players, 1 per 4 s per
## unit).
func _scan_splashes() -> void:
	if not is_inside_tree():
		return
	var cam := get_viewport().get_camera_3d() if get_viewport() else null
	if cam == null:
		return
	var seen := {}
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Node3D
		if u == null or not u.has_method(&"has_modifier"):
			continue
		var id := u.get_instance_id()
		var wading := bool(u.call(&"has_modifier", FORD_MODIFIER))
		if not wading:
			continue
		seen[id] = true
		if _wading.has(id):
			continue
		_wading[id] = true
		if not u.is_visible_in_tree() or not on_screen(u.global_position):
			continue
		if _clock - float(_splash_at.get(id, -1.0e9)) < SPLASH_PER_UNIT:
			continue
		if play_splash(u.global_position):
			_splash_at[id] = _clock
	for id: int in _wading.keys():
		if not seen.has(id):
			_wading.erase(id)


## Plays a splash at `at` on a free pooled 3D player (none free = skipped: at most 3 at once). True if it played.
func play_splash(at: Vector3) -> bool:
	for s in _splash:
		if s.playing:
			continue
		s.global_position = at
		splash_count += 1
		# +-6 % pitch: several units wading in do not repeat the same splash.
		s.pitch_scale = randf_range(0.94, 1.06)
		if s.stream != null and s.is_inside_tree():
			s.play()
		return true
	return false


# ---------------------------------------------------------------- helpers

## The local team (the fog's), else PLAYER.
func local_team() -> int:
	var fog := FogOfWar.find() if is_inside_tree() else null
	return fog.local_team if fog != null else PLAYER_TEAM


## True when the local team sees `pos` (no fog = seen).
func is_seen(pos: Vector3) -> bool:
	var fog := FogOfWar.find() if is_inside_tree() else null
	return fog == null or fog.is_visible(fog.local_team, pos)


## True when `pos` projects inside the viewport in front of the camera.
func on_screen(pos: Vector3) -> bool:
	var cam := get_viewport().get_camera_3d() if is_inside_tree() and get_viewport() else null
	if cam == null or cam.is_position_behind(pos):
		return false
	return get_viewport().get_visible_rect().has_point(cam.unproject_position(pos))


## Where the camera looks on the ground (its centre ray on y = 0), else its own position.
func camera_focus() -> Vector3:
	var cam := get_viewport().get_camera_3d() if is_inside_tree() and get_viewport() else null
	if cam == null:
		return Vector3.ZERO
	var centre := get_viewport().get_visible_rect().size * 0.5
	var hit: Variant = Plane(Vector3.UP, 0.0).intersects_ray(cam.project_ray_origin(centre),
			cam.project_ray_normal(centre))
	return hit as Vector3 if hit != null else cam.global_position


## Camp / stag sounds: the spot is visible and within 60 m of the camera focus.
func _audible_spot(pos: Vector3) -> bool:
	if not is_seen(pos):
		return false
	var f := camera_focus()
	return Vector2(pos.x - f.x, pos.z - f.z).length() <= NEAR_CAMERA


## Starts a floating text at `at` (world): rises 1.5 m over 1 s (ease out), fades over the last 0.4 s. Uses a free
## pool label, else the oldest one. Returns the label.
func popup(text: String, at: Vector3, color: Color) -> Label3D:
	var best := 0
	var best_age := -2.0
	for i in _labels.size():
		if _ages[i] < 0.0:
			best = i
			break
		if _ages[i] > best_age:
			best_age = _ages[i]
			best = i
	var l := _labels[best]
	_ages[best] = 0.0
	_starts[best] = at
	l.text = text
	l.modulate = color
	l.outline_modulate = Color.BLACK
	l.visible = true
	l.global_position = at
	return l


## Floating texts in flight.
func active_count() -> int:
	var n := 0
	for a in _ages:
		if a >= 0.0:
			n += 1
	return n


## The texts in flight (tests).
func active_texts() -> PackedStringArray:
	var out: PackedStringArray = []
	for i in _labels.size():
		if _ages[i] >= 0.0:
			out.append(_labels[i].text)
	return out


## The label in flight showing `text` (tests), or null.
func label_of(text: String) -> Label3D:
	for i in _labels.size():
		if _ages[i] >= 0.0 and _labels[i].text == text:
			return _labels[i]
	return null


func pool_size() -> int:
	return _labels.size()


## Plays a map-fill sound unless it played within its rate limit. True if it played.
func play_sound(id: StringName) -> bool:
	if not SOUNDS.has(id):
		return false
	var interval := float((SOUNDS[id] as Dictionary)["interval"])
	if _clock - float(_last_sound.get(id, -1.0e9)) < interval:
		return false
	_last_sound[id] = _clock
	sound_counts[id] = int(sound_counts.get(id, 0)) + 1
	var p: AudioStreamPlayer = _players.get(id)
	if p != null and p.stream != null and p.is_inside_tree():
		p.play()
	return true


## The player of a sound (tests: bus, stream, volume).
func player_of(id: StringName) -> AudioStreamPlayer:
	return _players.get(id)


## The pooled splash players (tests).
func splash_players() -> Array[AudioStreamPlayer3D]:
	return _splash
