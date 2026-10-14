class_name SelectionManager
extends Node
## Handles mouse selection and orders, Warcraft style.
## Left click / drag box = select. Shift = add. Double-click = select all of that type on screen.
## Left click on one of your buildings = select it alone (a box only takes buildings when it holds no unit).
## Right click ground = move. Right click an enemy unit or building = attack. Right click a crystal
## node = workers gather. Right click your own unfinished site with workers = they build it.
## With a building selected: right click ground = rally point, right click a crystal node = gather rally.
## Targeted orders (then left-click in the world or on the minimap): M move, X attack-move, G gather,
## F Fireball, Set Rally (card button only). H = hold. C = stop.
## Workers only: B = build menu, then Z / X / C (the BuildingType hotkey_label) = placement ghost;
## left click places (Shift keeps placing), right click / Esc backs out.
## Building selected: Z X C V B N M , = its training slots 1-8 (`train_slots()`: the keep keeps X for its tier button,
## empty at the Citadel, so a unit's key never changes). Construction site selected: Delete = cancel.
## Hall / Stables / keep selected (UR.U1, ui-sc2-console.md 7.1): + (the =/+ key, or numpad +) opens / closes its
## research page (`upgrades_hall`); there a unit's training key opens that unit's page (`research_unit`): Z = its "+",
## X C V B = its research rows, then the Stables rank-3; a key again on a running research cancels it (full refund).
## Esc / Back = one page back; + closes both. While a page is open the slot keys never train.
## Own tier-3 helper inspected (t3-helpers.md 2.1): Z / X / C = its stances Escort / Vanguard / Hold home.
## Every button of the command card shows the key that does the same (2026-09-29, JS: "each unit / building shows its
## own hotkey"); the card reads its letters from here (`train_slots`, `train_key`, SLOT_LETTERS, STANCE_KEYS).
## Control groups (StarCraft II style), keys 1-9 and 0 (= group 10): Ctrl+N = set, Shift+N = add,
## Alt+N = steal (take the selection out of every other group, then set N), Shift+Alt+N = steal and add,
## N = select (twice quickly = centre camera). Buildings can be in groups; dead members leave them.
## Several buildings (2026-09-27): Shift+click own buildings, double-click one (all of its type on screen), or drag a
## box with no unit in it selects several (`selected_buildings`); a group of buildings recalls them all. Tab /
## Shift+Tab (physical) cycle the ACTIVE one (`selected_building`: card, panel, rally, Delete); Z X C V B queue at the
## least busy selected building of the active one's type (`train_target`). Units always win over buildings.
## F1 = select hero (centre on the keep while she is dead), F2 = select the whole army (every own
## non-worker unit, wizard included), F3 = select the next idle worker and centre on it.
## Esc / right click = cancel targeting. Keys use physical keycodes (QWERTY positions), so AZERTY works.
## Control scheme (GameSettings.control_scheme, UX.1): Classic (default) = right click moves the wizard like any
## unit, physical A (and X) = attack-move targeting, W S D unused; Hero WASD = W A S D walk the wizard (WizardControl,
## a child), X = attack-move. Attack-move then a left click: enemy = attack it, own unit = attack-move to it, ground
## or minimap = attack-move there. F Q E = her spells 1 / 2 / 3, Ctrl + F Q E = learn
## or rank up (SpellInfo reads the wizard's SpellCaster); never bind
## W A S D Q E F to anything else (A = attack-move in Classic only).
## Items (4.U1a): Numpad 1-6 (or a click on the inventory bar) use Vessa's item slots 1-6; point actives
## (Blink...) use the same cross-cursor targeting as spells. Right click a ground item (group
## "item_pickups") with Vessa selected = she walks there and takes it at 2.2 m.
## Champions (9.C8, champions.md 9 / 13, ui-champions.md 4 / 7): a unit whose `is_commandable()` is false is never
## selected for orders: box select, double-click, groups, F2 and every order skip it (`orderable_units()`). Clicking
## one (own, or an enemy one in vision) **inspects** it: `inspected` points at it and `selected` stays empty (the
## selection panel shows its champion view, the command card `Champions act on their own.`). Kept while it is fallen;
## cleared by any other selection, Esc, or when it is freed (an enemy one also when the fog hides it).
## Bounty flags (group "bounties"): clicking one selects it (`selected_bounty`, `selected` and the building cleared);
## with your flag selected Z = raise +25, Shift+Z = +100, Delete = remove; Esc clears it.
## R = bounty mode (`bounty_mode`, the scene's BountyMode, in this node's canvas layer).
## Champion barks and the flags' stake labels run in the child `barks` (ChampionBarks).
## Trade (10.C7, ui-trade.md 4-9): B in the open build menu places the Bazaar. With the own Bazaar selected, right
## click a trading post (group "trade_posts": a layer-2 hit, or the ground within 3.5 m of its centre) = its route
## (`market.set_route`, refusals on the message line); right click elsewhere = the hint `Right-click a trading post to
## set the route` (once per 2 s); the card's Set Route is the targeted order ORDER_ROUTE. Caravans (group
## "caravans"): right click / G then a post = `command_trade(post)`, the own Bazaar = go home; they never attack or
## attack-move (a move next to the target instead). With workers too, G resolves per unit (node = gather, post /
## Bazaar = trade, ground = move). Left click on a post or a guild house (group "guilds") selects it read-only:
## `selected_neutral` + signal `neutral_building_clicked(node)` (the post / Den / Lodge panel shows it).
## `hovered_post` = the post under the mouse (20 Hz), for the route preview. Clicking a visible enemy or neutral unit
## inspects it read-only (`inspected`, like champions): the selection panel shows its single view.
## Map fill (12.C6, ui-mapfill.md 4.1 / 7.1): the layer-2 ray also hits Area3Ds (`_ray(..., areas = true)`) for the game
## critters (their "ClickArea", walked up to the node with `is_game_critter()`) and the shrines' click areas. Left click on
## a capture point (its body / area, or the ground within capture_radius x 0.5 of a watchtower / well) or on a visible
## critter = `selected_neutral` + `neutral_building_clicked` like a post (a critter is dropped when it dies or hides,
## checked at 4 Hz). Right click / A-click on a visible critter: `command_attack(critter)` for the hunters (`can_hunt`:
## combatants, never workers, caravans or trackers), the others get the ground order under it (move / attack-move).
## Right click on a point = a plain ground move (points are never targets). With hunters selected and no order pending
## the mouse over a critter shows the cross cursor and a red ring (`hovered_critter`).

signal selection_changed
## A trading post, a guild house, a capture point or a game critter was left-clicked (it is now `selected_neutral`).
signal neutral_building_clicked(node: Node3D)
signal message(text: String)
## A control group was set, added to, stolen from, or lost a dead member.
signal groups_changed
## The build menu opened / closed, or a placement started / ended (the command card refreshes).
signal mode_changed

## Replay Lab (docs/plan/replay-lab.md): every order below is noted (`_REPLAY.note`, a no-op without a replay
## session) at its world-level entry point, so a replay can give it again. No noted function calls another noted one.
const _REPLAY := preload("res://scripts/core/replay/replay_hooks.gd")
const DRAG_THRESHOLD := 8.0
const FORMATION_SPACING := 1.5
const GROUP_DOUBLE_TAP := 0.4
const GROUP_COUNT := 10                 # keys 1-9 are groups 1-9, key 0 is group 10
const NODE_CLICK_RADIUS := 3.0          # a ground click this close to a crystal node counts as the node
const IDLE_SPEED := 0.3                 # a worker slower than this (m/s) with no job counts as idle

const ORDER_MOVE := &"move"
const ORDER_ATTACK_MOVE := &"attack_move"
const ORDER_GATHER := &"gather"
const ORDER_FIREBALL := &"fireball"
const ORDER_RALLY := &"rally"
const ORDER_BUILD := &"build"           # the placement ghost is up (placing_type)
const ORDER_ITEM := &"item"             # a point item active is being aimed (_pending_item_slot)
const ORDER_ROUTE := &"route"           # the Bazaar's Set Route: the next left click on a trading post
const POST_CLICK_RADIUS := 3.5          # a ground click this close (per axis) to a post / guild house centre counts
const MINIMAP_POST_RADIUS := 4.0        # a minimap click this close to a post centre counts as the post
const HOVER_INTERVAL := 0.05            # hovered_post refresh (20 Hz)
const ROUTE_HINT_INTERVAL := 2.0
const MSG_ROUTE_HINT := "Right-click a trading post to set the route"
const CRITTER_CLICK_PX := 18.0          # a click this close to a visible critter (nothing else under it) picks it
const CRITTER_CHECK_INTERVAL := 0.25    # a selected critter that died / hid is dropped (4 Hz)
const POINT_GROUND_FACTOR := 0.5        # a ground click within capture_radius x this of a tower / well = the point
const HUNT_RING_COLOR := Color(0.95, 0.35, 0.3, 0.7)
const ITEM_KEYS: Array[Key] = [KEY_KP_1, KEY_KP_2, KEY_KP_3, KEY_KP_4, KEY_KP_5, KEY_KP_6]   # item slots 1-6
const PICKUP_RANGE := 2.2               # items.md: the wizard takes a ground item at 2.2 m
const PICKUP_CLICK_PX := 28.0
const FLAG_CLICK_PX := 22.0             # a click this close to a flag's pole selects it
# Training slots 1-5, then 6-8 for the Hall's new units (docs/design/new-units-12.md 2: N M , on the bottom row).
const SLOT_KEYS: Array[Key] = [KEY_Z, KEY_X, KEY_C, KEY_V, KEY_B, KEY_N, KEY_M, KEY_COMMA]
const SLOT_LETTERS := "ZXCVBNM,"
const SPELL_KEYS: Array[Key] = [KEY_F, KEY_Q, KEY_E]                  # spells 1-3
## The Hall's "+" upgrades page (tiers.md 5): the =/+ key (physical, it carries "+" on QWERTY and AZERTY) or numpad +.
## A layout with its own "+" key (keycode KEY_PLUS) works too. The card shows "+".
const UPGRADES_KEYS: Array[Key] = [KEY_EQUAL, KEY_KP_ADD]
const UPGRADES_KEY_LABEL := "+"
## Own helper inspected: its 3 stances (Helper.STANCES order) on the card's first three letters.
const STANCE_KEYS: Array[Key] = [KEY_Z, KEY_X, KEY_C]
## Caster units (caster-units.md 3.2 / 3.3): Z / V = the selected casters' first / second spell (Ctrl = autocast on /
## off), the keep's caster on training slot 5 (B).
const CASTER_KEYS: Array[Key] = [KEY_Z, KEY_V]
const CASTER_KEEP_SLOT := 4
const MSG_NO_UPGRADE := "No upgrade for that unit"
## UR.U1: a unit page holds at most 5 buttons (Z "+", X C V B rows, then the Stables rank-3), row 1 only.
const RESEARCH_PAGE_MAX := 5
const RESEARCH_UNITS_TTL_MS := 500
static var _research_units_cache: Dictionary = {}   # building instance id -> [msec, Array[StringName]]
const GHOST_TEXT_COLOR := Color(1.0, 0.45, 0.4)

var camera: Camera3D
var hero: Wizard
var enabled := true
var selected: Array[Unit] = []
## The selected building (keep, barracks, hearth, spire or a site), or null. Never with units.
var selected_building: Node3D = null
## Every selected own building (2026-09-27 playtest, "all buildings on one hotkey, Tab to each one"). Empty, or it holds
## `selected_building`, which is the ACTIVE one: the command card / selection panel show it, Z X C V B train there
## (or at the least busy selected building of the same type), right click sets the rally of every selected trainer.
## Tab / Shift+Tab cycle the active one (only while 2+ buildings are selected; else Tab stays free).
var selected_buildings: Array[Node3D] = []
## Read only: the build menu (Hearth / Hall / Spire) replaces the worker card.
var build_menu_open := false
## Read only: the building being placed (ghost under the mouse), or null.
var placing_type: BuildingType = null
## Read only: the Hall whose "+" upgrades page the command card shows (tiers.md 5), or null. `upgrades_open()` is true
## while it is the selected building; any new selection or Tab to another building closes it.
var upgrades_hall: Node3D = null
## Read only (UR.U1): the unit whose page is open on top of the research page, &"" = the research page itself.
var research_unit: StringName = &""
## W A S D direct control of the wizard.
var wizard_control: WizardControl
## Read only: the bounty flag selected (own or a visible enemy one), or null. Never with units or a building.
var selected_bounty: Node3D = null
## Read only: the unit being inspected (read-only view; `selected` stays empty), or null: a champion or another
## unit the player can't order (a Greywater Tracker), or a visible enemy / neutral unit (a Magpie, an enemy caravan).
var inspected: Unit = null
## Read only: the trading post or guild house selected with a left click (read-only panel), or null.
var selected_neutral: Node3D = null
## Read only: the trading post under the mouse (updated at 20 Hz), or null.
var hovered_post: Node3D = null
## Read only: the visible game critter under the mouse while hunters are selected and no order is pending (the
## cross cursor and the red ring are up), or null.
var hovered_critter: Node3D = null
var _critter_cursor := false
var _critter_check_left := 0.0
var _hover_left := 0.0
var _route_hint_time := -100.0
## R: bounty mode (chip cursor, target ring).
var bounty_mode: BountyMode
## Champion barks and the flags' stake labels.
var barks: ChampionBarks
var _ring_radius := -1.0   # radius of the torus mesh the bounty ring uses now

var _mouse_down := false
var _dragging := false
var _double_click := false
var _drag_start := Vector2.ZERO
var _drag_now := Vector2.ZERO
var _pending: StringName = &""          # targeted order waiting for a left click
# U1-3: Shift-placed sites are split between the selected workers: each new site goes to a free worker, then (all busy)
# into the shortest worker queue; a worker starts its next queued site when its current one is finished or gone.
var _shift_session := false             # a Shift-placement happened since the ghost came up
var _build_current: Dictionary = {}     # worker (Unit) -> the site it was given by the split
var _build_queue: Dictionary = {}       # worker (Unit) -> Array of sites waiting for it
var _build_queue_tick := 0.0
var _pending_spell: StringName = &""    # the spell being aimed (then _pending == the spell id)
var _pending_item_slot := -1            # the item slot being aimed (then _pending == ORDER_ITEM)
var _pickup_target: Node3D = null       # the ground item Vessa is walking to
var _pickup_time_left := 0.0
var _groups: Dictionary = {}          # int (1-10) -> Array of Unit / building nodes
var _clock := 0.0
var _last_group_key := 0
var _last_group_time := -10.0
var _last_idle_worker: Unit = null     # F3 cycles on from this one
var _last_army_time := -10.0           # F2 twice = centre on the army
const TYPES_CACHE_FRAMES := 30
var _types_cache: Array[StringName] = []
var _types_key := 0
var _types_frame := -1000
var _types_version := 0
var _active_unit_type: StringName = &""  # the Tab subgroup (see active_unit_type)
var _box_ui: Control
var _target_ring: MeshInstance3D
var _target_ring_mat: StandardMaterial3D
var _ghost: BuildGhost
var _ghost_label: Label
var _ghost_center := Vector3.INF
var _ghost_reason := ""
var _mouse_pos := Vector2.ZERO
var _grid: BuildGrid = null
var _pending_caster_spell: StringName = &""   # a caster spell being aimed (then _pending == the spell id)
var _caster_ghost: MeshInstance3D              # the Rime Bulwark wall ghost under the cursor
var _range_ring: MeshInstance3D                # the aiming caster's range ring


func _ready() -> void:
	selection_changed.connect(_bump_types_version)
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_box_ui = Control.new()
	_box_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_box_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box_ui.draw.connect(_draw_box)
	layer.add_child(_box_ui)

	_target_ring = MeshInstance3D.new()
	_target_ring_mat = StandardMaterial3D.new()
	_target_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_target_ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_target_ring_mat.albedo_color = Color(1.0, 0.5, 0.1, 0.8)
	_target_ring.material_override = _target_ring_mat
	_target_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_target_ring.visible = false
	add_child(_target_ring)

	_ghost = BuildGhost.new()
	add_child(_ghost)
	_ghost_label = UIStyle.label("", 14)
	_ghost_label.add_theme_color_override("font_color", GHOST_TEXT_COLOR)
	_ghost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ghost_label.visible = false
	_box_ui.add_child(_ghost_label)

	GameSettings.ensure_read()   # the control scheme (UX.1), also when the level starts without the menu
	wizard_control = WizardControl.new()
	wizard_control.selection = self
	add_child(wizard_control)

	# Bounty mode (R) lives in this canvas layer so its chip draws over the HUD panels; one per scene.
	var existing: Node = get_tree().get_first_node_in_group(BountyMode.GROUP)
	if existing is BountyMode and not existing.is_queued_for_deletion():
		bounty_mode = existing
	else:
		bounty_mode = BountyMode.new()
		bounty_mode.name = "BountyMode"
		layer.add_child(bounty_mode)
	bounty_mode.selection = self
	barks = ChampionBarks.new()
	barks.name = "ChampionBarks"
	barks.selection = self
	add_child(barks)


## Tracks the mouse for the placement ghost (also for events pushed by tests).
func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		_mouse_pos = (event as InputEventMouse).position
	# Esc leaves bounty mode / drops the inspect view or the selected flag before the pause menu (which listens in
	# _unhandled_input) sees it. Open windows (shop, tavern) take Esc earlier in their own _input.
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and enabled and _pending == &"" \
			and (key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode) == KEY_ESCAPE:
		if bounty_mode != null and bounty_mode.active:
			bounty_mode.exit()
			get_viewport().set_input_as_handled()
		elif inspected != null or selected_bounty != null or selected_neutral != null:
			select_units([])
			get_viewport().set_input_as_handled()
	# Tab / Shift+Tab: next / previous active building while 2+ are selected. Read here (not in _unhandled_input) so
	# the GUI's focus navigation never eats it; a focused text field keeps its Tab.
	if key != null and key.pressed and enabled and not key.ctrl_pressed and not key.alt_pressed \
			and (key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode) == KEY_TAB \
			and (selected_buildings.size() >= 2 or selected_unit_types().size() >= 2):
		# A selection never mixes units and buildings (groups may: a mixed group recalls its units), so Tab cycles
		# whichever is selected: the active building, or the active unit subgroup (SC2 style).
		var focus := get_viewport().gui_get_focus_owner()
		if not (focus is LineEdit or focus is TextEdit):
			if selected_buildings.size() >= 2:
				cycle_active_building(-1 if key.shift_pressed else 1)
			else:
				cycle_active_unit_type(-1 if key.shift_pressed else 1)
			get_viewport().set_input_as_handled()


## U3-8: a targeting mode (cross cursor) left by F9 / quit to menu puts the arrow cursor back.
func _exit_tree() -> void:
	if _pending != &"":
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _process(delta: float) -> void:
	_clock += delta
	if not _build_current.is_empty():
		_build_queue_tick -= delta
		if _build_queue_tick <= 0.0:
			_build_queue_tick = 0.25
			advance_build_queues()
	# Drop units that died, and a destroyed building.
	var before := selected.size()
	selected.assign(selected.filter(func(u): return is_instance_valid(u) and u.is_alive()))
	var changed := selected.size() != before
	if not selected_buildings.is_empty():
		var alive_b: Array[Node3D] = []
		for b in selected_buildings:
			if _building_alive(b):
				alive_b.append(b)
		if alive_b.size() != selected_buildings.size():
			selected_buildings = alive_b
			changed = true
	if selected_building != null and not _building_alive(selected_building):
		# The active building fell: the next selected one becomes active (else nothing).
		selected_building = selected_buildings[0] if not selected_buildings.is_empty() else null
		changed = true
	if inspected != null:
		# The inspected unit was freed, or (an enemy one) went into the fog. A fallen champion stays inspected;
		# other units (trackers, enemy / neutral units) are dropped when they die.
		if not is_instance_valid(inspected) or not inspected.is_inside_tree() \
				or (inspected.team != Unit.Team.PLAYER and inspected.is_alive() and _is_hidden(inspected)) \
				or (not inspected.is_alive() and not inspected.is_in_group(&"champions")):
			_clear_inspect()
			changed = true
	if selected_neutral != null and (not is_instance_valid(selected_neutral) or not selected_neutral.is_inside_tree()):
		selected_neutral = null
		changed = true
	_critter_check_left -= delta
	if _critter_check_left <= 0.0:
		_critter_check_left = CRITTER_CHECK_INTERVAL
		if selected_neutral != null and not _critter_ok(selected_neutral) \
				and selected_neutral.has_method(&"is_game_critter"):
			_clear_neutral()   # the selected critter died or went into the fog
			changed = true
	_hover_left -= delta
	if _hover_left <= 0.0:
		_hover_left = HOVER_INTERVAL
		hovered_post = post_at(_mouse_pos) if enabled and camera != null else null
		_update_critter_hover()
	elif hovered_critter != null:
		if _critter_ok(hovered_critter):
			_target_ring.global_position = hovered_critter.global_position + Vector3.UP * 0.06
		else:
			_set_hovered_critter(null)
	if selected_bounty != null and (not _flag_alive(selected_bounty) \
			or not BountyMode.flag_shown(selected_bounty, Unit.Team.PLAYER)):
		selected_bounty = null   # ended, or an enemy flag that went into the fog
		changed = true
	if changed:
		selection_changed.emit()
	_prune_groups()

	_update_pickup(delta)
	if _pending == ORDER_ITEM:
		if hero == null or not is_instance_valid(hero) or not hero.is_alive():
			cancel_targeting()
			return
		var ip: Variant = ground_point(_box_ui.get_local_mouse_position())
		if ip != null:
			_target_ring.global_position = (ip as Vector3) + Vector3.UP * 0.06
	if _pending_caster_spell != &"":
		_update_caster_aim()
	if _pending_spell != &"":
		if hero == null or not is_instance_valid(hero) or not hero.is_alive():
			cancel_targeting()
			return
		var p: Variant = ground_point(_box_ui.get_local_mouse_position())
		if p != null:
			_target_ring.global_position = (p as Vector3) + Vector3.UP * 0.06
		var offset := _target_ring.global_position - hero.global_position
		var spell_range := SpellInfo.value(hero, _pending_spell, "range", maxi(1, SpellInfo.rank(hero, _pending_spell)))
		var in_range := spell_range <= 0.0 or Vector2(offset.x, offset.z).length() <= spell_range
		_target_ring_mat.albedo_color = Color(1.0, 0.5, 0.1, 0.85) if in_range else Color(1.0, 0.8, 0.3, 0.45)
	match _pending:
		ORDER_RALLY:
			if selected_building == null:
				cancel_targeting()
		ORDER_ROUTE:
			if selected_market() == null:
				cancel_targeting()
		ORDER_MOVE, ORDER_ATTACK_MOVE, ORDER_GATHER:
			if orderable_units().is_empty():
				cancel_targeting()
		ORDER_BUILD:
			if not can_build() or _build_grid() == null:
				cancel_targeting()
			else:
				_update_ghost(_mouse_pos)
	if build_menu_open and not can_build():
		close_build_menu()


func _unhandled_input(event: InputEvent) -> void:
	if not enabled or camera == null:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if bounty_mode != null and bounty_mode.active:
					bounty_mode.click(mb.position, mb.shift_pressed)
					return
				if _pending == ORDER_BUILD:
					place_building_at_screen(mb.position, mb.shift_pressed)
					return
				if _pending != &"":
					_confirm_pending(mb.position)
					return
				_mouse_down = true
				_dragging = false
				_double_click = mb.double_click
				_drag_start = mb.position
				_drag_now = mb.position
			elif _mouse_down:
				_mouse_down = false
				if _dragging:
					_box_select(mb.shift_pressed)
				else:
					_click_select(mb.position, mb.shift_pressed, _double_click)
				_dragging = false
				_box_ui.queue_redraw()
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			if bounty_mode != null and bounty_mode.active:
				bounty_mode.exit()
			elif _pending == ORDER_ROUTE:
				# Set Route pending: a right click on a post confirms (as the plain right-click rule), else cancels.
				var post := post_at(mb.position)
				cancel_targeting()
				if post != null:
					set_market_route(post)
			elif _pending != &"":
				cancel_targeting()
			elif build_menu_open:
				close_build_menu()
			elif selected_market() != null:
				_market_right_click(mb.position)
			elif selected_building != null:
				_rally_order(mb.position)
			else:
				_issue_order(mb.position)

	elif event is InputEventMouseMotion and _mouse_down:
		_drag_now = (event as InputEventMouseMotion).position
		if _drag_start.distance_to(_drag_now) > DRAG_THRESHOLD:
			_dragging = true
		_box_ui.queue_redraw()

	elif event is InputEventKey and event.pressed and not event.echo:
		if _handle_key(event as InputEventKey):
			get_viewport().set_input_as_handled()


## Returns true when the key was used (so the level does not also react to it, e.g. R).
func _handle_key(key: InputEventKey) -> bool:
	# Physical keycode = key position, so AZERTY users press the same spots as QWERTY users.
	var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	var item_slot := ITEM_KEYS.find(code)
	if item_slot >= 0:
		use_item_slot(item_slot)
		return true
	var group := group_for_key(code)
	if group != 0:
		# Alt is checked first: AltGr on AZERTY sends Ctrl+Alt, and should steal, not set.
		if key.alt_pressed:
			steal_to_control_group(group, key.shift_pressed)
		elif key.ctrl_pressed:
			set_control_group(group)
		elif key.shift_pressed:
			add_to_control_group(group)
		else:
			recall_control_group(group)
		return true
	# F / Q / E = the wizard's spells 1 / 2 / 3; Ctrl + the key = learn / rank up (never targets).
	var spell_slot := SPELL_KEYS.find(code)
	if spell_slot >= 0 and not key.alt_pressed:
		if key.ctrl_pressed:
			learn_spell_slot(spell_slot)
		else:
			cast_spell_slot(spell_slot)
		return true
	# Ctrl+A (physical) = select all own commandable units (wizard included); Ctrl+Shift+A adds them to the selection.
	if code == KEY_A and key.ctrl_pressed and not key.alt_pressed:
		select_all_units(key.shift_pressed)
		return true
	# Classic control scheme (UX.1): physical A = attack-move targeting (X too, below).
	if code == KEY_A and not key.ctrl_pressed and not key.alt_pressed and GameSettings.attack_move_keys().has(KEY_A):
		begin_attack_move_targeting()
		return true
	# Hero WASD: W A S D walk the wizard (WizardControl reads them). In both schemes they never do anything else.
	if WizardControl.is_walk_key(code) or code == KEY_Q or code == KEY_E:
		return true
	# A flag selected: Z = raise +25 (Shift = +100), Delete = remove (own flags only).
	if selected_bounty != null and not key.ctrl_pressed and not key.alt_pressed:
		if code == KEY_Z:
			raise_selected_bounty(BountyMode.RAISE_BIG if key.shift_pressed else BountyMode.RAISE_STEP)
			return true
		if code == KEY_DELETE:
			remove_selected_bounty()
			return true
	# An own helper inspected (t3-helpers.md 2.1): Z / X / C = its stances, like the card's first three buttons.
	if not key.ctrl_pressed and not key.alt_pressed and inspected_own_helper() != null:
		var stance_i := STANCE_KEYS.find(code)
		if stance_i >= 0 and stance_i < Helper.STANCES.size():
			set_helper_stance(Helper.STANCES[stance_i])
			return true
	# R: bounty mode on / off.
	if code == KEY_R and not key.ctrl_pressed and not key.alt_pressed and bounty_mode != null:
		bounty_mode.toggle()
		return true
	# UR.U1 research pages: + opens / closes them; while open the slot keys act on the page (unit key = its page, then
	# Z = "+", X C V B = rows) and never train.
	if selected_building != null and not key.ctrl_pressed and not key.alt_pressed:
		if is_upgrades_key(key):
			if upgrades_open():
				close_upgrades()
			elif can_open_upgrades():
				open_upgrades()
			else:
				return false
			return true
		if upgrades_open():
			var up_slot := SLOT_KEYS.find(code)
			if up_slot >= 0:
				press_research_slot(up_slot)
				return true
	# Training slots Z X C V B N M , only act while a building is selected.
	if selected_building != null:
		var type: Variant = _type_for_key(code)
		if type != null:
			train(type)
			return true
	# Build menu (or a placement) open: its Z / X / C pick the building.
	if build_menu_open or _pending == ORDER_BUILD:
		var building_type := _build_type_for_key(code)
		if building_type != null:
			begin_placement(building_type)
			return true
	# caster-units.md 3.2: Z / V = the selected casters' spells (any active subgroup), Ctrl+Z / Ctrl+V = autocast.
	var caster_slot := CASTER_KEYS.find(code)
	if caster_slot >= 0 and not key.alt_pressed and selected_building == null and caster_type() != &"":
		if key.ctrl_pressed:
			toggle_caster_autocast(caster_slot)
		else:
			cast_caster_slot(caster_slot)
		return true
	match code:
		KEY_X:
			begin_attack_move_targeting()
		KEY_M:
			begin_order(ORDER_MOVE)
		KEY_G:
			begin_order(ORDER_GATHER)
		KEY_H:
			hold()
		KEY_C:
			stop()
		KEY_B:
			open_build_menu()
		KEY_DELETE:
			if not cancel_site():
				return false
		KEY_F1:
			if hero and is_instance_valid(hero) and hero.is_alive():
				select_units([hero])
			else:
				# Dead wizard: centre on the keep (she comes back there).
				var home := own_keep()
				if home != null:
					centre_camera_on([home])
		KEY_F2:
			if key.shift_pressed:
				add_army()
			else:
				select_army()
		KEY_F3:
			if key.ctrl_pressed:
				select_all_idle_workers()
			else:
				select_idle_worker()
		KEY_ESCAPE:
			if bounty_mode != null and bounty_mode.active:
				bounty_mode.exit()
			elif _pending != &"":
				cancel_targeting()
			elif build_menu_open:
				close_build_menu()
			elif upgrades_open():
				research_back()   # unit page -> research page -> the training buttons
			elif inspected != null or selected_bounty != null or selected_neutral != null:
				select_units([])   # Esc drops the inspect view / the selected flag / post / guild house
			else:
				return false
		_:
			return false
	return true


# ---------------------------------------------------------------- public

## Selects the player's living, commandable units among `units` (champions and other units whose
## `is_commandable()` is false are dropped: see `inspect_unit`).
func select_units(units: Array) -> void:
	for u in selected:
		if is_instance_valid(u):
			u.selected = false
	selected.clear()
	_active_unit_type = &""   # a new selection starts on its highest-priority subgroup
	_clear_building()
	_clear_inspect()
	_clear_neutral()
	selected_bounty = null
	for u in units:
		if u is Unit and is_instance_valid(u) and u.is_alive() and u.team == Unit.Team.PLAYER \
				and is_commandable_unit(u) and not selected.has(u):
			selected.append(u)
			u.selected = true
	if _pending == ORDER_RALLY or _pending == ORDER_BUILD:
		cancel_targeting()
	close_build_menu()
	selection_changed.emit()


## Selects a building (the keep) alone. Units are deselected.
func select_building(building: Node3D) -> void:
	select_buildings([building] if building != null else [])


## Selects several buildings at once (a building control group, Shift+click, double-click, a box with no units).
## Units are deselected. They are sorted by type (keep first, then by name) so Tab walks type by type; `active`
## (when among them) becomes the active one, else the first. Dead ones are skipped.
func select_buildings(buildings: Array, active: Node3D = null) -> void:
	for u in selected:
		if is_instance_valid(u):
			u.selected = false
	selected.clear()
	_clear_building()
	_clear_inspect()
	_clear_neutral()
	selected_bounty = null
	for b in buildings:
		if b is Node3D and _building_alive(b) and not selected_buildings.has(b):
			selected_buildings.append(b)
	if selected_buildings.size() > 1:
		selected_buildings.sort_custom(_building_order)
	for b in selected_buildings:
		if b.has_method("set_selected"):
			b.call("set_selected", true)
	if not selected_buildings.is_empty():
		selected_building = active if active != null and selected_buildings.has(active) else selected_buildings[0]
	cancel_targeting()
	close_build_menu()
	selection_changed.emit()


## Tab (+1) / Shift+Tab (-1): the next / previous selected building becomes the active one (the card and the panel
## show it). Returns the new active building, or null when fewer than 2 buildings are selected.
func cycle_active_building(step := 1) -> Node3D:
	if selected_buildings.size() < 2:
		return null
	var i := selected_buildings.find(selected_building)
	i = posmod((i if i >= 0 else 0) + step, selected_buildings.size())
	set_active_building(selected_buildings[i])
	return selected_building


## Makes `b` (one of the selected buildings) the active one; a pending rally / route order is dropped.
func set_active_building(b: Node3D) -> void:
	if b == null or not selected_buildings.has(b) or b == selected_building:
		return
	selected_building = b
	upgrades_hall = null   # the "+" page belongs to the Hall it was opened on
	if _pending == ORDER_RALLY or _pending == ORDER_ROUTE:
		cancel_targeting()
	selection_changed.emit()


## Tab order of selected buildings: the keep first, then by type name, then by creation order.
func _building_order(a: Node3D, b: Node3D) -> bool:
	var ka := _building_sort_name(a)
	var kb := _building_sort_name(b)
	if ka != kb:
		return ka < kb
	return a.get_instance_id() < b.get_instance_id()


func _building_sort_name(b: Node3D) -> String:
	var type: Variant = b.get("building_type")
	if type is Object:
		var prefix := "0" if StringName(str(type.get("kind"))) == &"keep" else "1"
		return prefix + str(type.get("display_name"))
	return "2" + b.name


## Clicking a champion (own, or an enemy one the player sees): the read-only inspect view. `inspected` = it,
## `selected` stays empty, so nothing can ever order it. It shows its selection ring while inspected.
func inspect_unit(u: Unit) -> void:
	if u == null or not is_instance_valid(u) or not u.is_inside_tree():
		return
	if u.team != Unit.Team.PLAYER and _is_hidden(u):
		return
	for s in selected:
		if is_instance_valid(s):
			s.selected = false
	selected.clear()
	_clear_building()
	_clear_inspect()
	_clear_neutral()
	selected_bounty = null
	inspected = u
	u.selected = true
	if _pending in [ORDER_RALLY, ORDER_BUILD, ORDER_MOVE, ORDER_ATTACK_MOVE, ORDER_GATHER, ORDER_ROUTE]:
		cancel_targeting()
	close_build_menu()
	selection_changed.emit()


## True while a champion is inspected (the command card is empty with the hint lines).
func is_inspecting() -> bool:
	return inspected != null and is_instance_valid(inspected)


## Clicking a bounty flag selects it alone (own flags: Z / Shift+Z raise, Delete removes; enemy ones read-only).
func select_flag(flag: Node3D) -> void:
	for u in selected:
		if is_instance_valid(u):
			u.selected = false
	selected.clear()
	_clear_building()
	_clear_inspect()
	_clear_neutral()
	selected_bounty = flag if _flag_alive(flag) else null
	if _pending in [ORDER_RALLY, ORDER_BUILD, ORDER_MOVE, ORDER_ATTACK_MOVE, ORDER_GATHER, ORDER_ROUTE]:
		cancel_targeting()
	close_build_menu()
	selection_changed.emit()


## Left click on a trading post or a guild house: it becomes `selected_neutral` alone (read-only; the post / Den /
## Lodge panel shows it), its `set_selected(true)` is called, then `neutral_building_clicked(node)` is emitted.
func select_neutral(node: Node3D) -> void:
	if node == null or not is_instance_valid(node) or not node.is_inside_tree():
		return
	for u in selected:
		if is_instance_valid(u):
			u.selected = false
	selected.clear()
	_clear_building()
	_clear_inspect()
	_clear_neutral()
	selected_bounty = null
	selected_neutral = node
	if node.has_method(&"set_selected"):
		node.call(&"set_selected", true)
	if _pending in [ORDER_RALLY, ORDER_BUILD, ORDER_MOVE, ORDER_ATTACK_MOVE, ORDER_GATHER, ORDER_ROUTE]:
		cancel_targeting()
	close_build_menu()
	selection_changed.emit()
	neutral_building_clicked.emit(node)


## True when the selected flag belongs to the player (it can be raised / removed).
func is_own_bounty_selected() -> bool:
	return selected_bounty != null and _flag_alive(selected_bounty) and selected_bounty.get("team") != null \
			and int(selected_bounty.get("team")) == Unit.Team.PLAYER


## Z / Shift+Z (or the card button): raises the selected own flag. Returns "" or the reason (also a message).
func raise_selected_bounty(amount: int) -> String:
	if not is_own_bounty_selected():
		return "No bounty selected"
	_REPLAY.note(&"raise_selected_bounty", [amount], self)
	var result := bounty_mode.raise_flag(selected_bounty, amount)
	selection_changed.emit()
	return result


## Delete (or the card button): removes the selected own flag. Returns the refund (-1 when nothing was removed).
func remove_selected_bounty() -> int:
	if not is_own_bounty_selected():
		return -1
	_REPLAY.note(&"remove_selected_bounty", [], self)
	var refund := BountyMode.remove_flag(selected_bounty)   # the board says "Bounty refunded: N"
	if refund >= 0:
		select_units([])
	return refund


## The bounty-mode ring under the hovered target (ui-champions.md 6.1): the targeting ring, recoloured.
func show_bounty_ring(pos: Vector3, radius: float, color: Color) -> void:
	if _target_ring == null or (_pending != &"" and _pending != ORDER_BUILD):
		return   # a spell / item aim owns the ring
	radius = maxf(radius, 0.3)
	if not is_equal_approx(radius, _ring_radius):
		_ring_radius = radius
		var torus := TorusMesh.new()
		torus.inner_radius = maxf(radius - 0.15, 0.1)
		torus.outer_radius = radius
		torus.rings = 48
		_target_ring.mesh = torus
	_target_ring.scale = Vector3(1.0, 0.1, 1.0)
	_target_ring_mat.albedo_color = color
	_target_ring.global_position = pos + Vector3.UP * 0.06
	_target_ring.visible = true


func hide_bounty_ring() -> void:
	if _target_ring != null and _pending == &"":
		_target_ring.visible = false
	_ring_radius = -1.0


## False for units the player may never order (champions: `is_commandable()` returns false).
static func is_commandable_unit(u: Object) -> bool:
	if u == null or not is_instance_valid(u):
		return false
	if u.has_method(&"is_commandable"):
		return bool(u.call(&"is_commandable"))
	return not (u is Node and (u as Node).is_in_group(&"champions"))


## The selected units that take orders (never an inspected champion). Every order goes through this list.
func orderable_units() -> Array[Unit]:
	var out: Array[Unit] = []
	for u in selected:
		if is_instance_valid(u) and u.team == Unit.Team.PLAYER and is_commandable_unit(u):
			out.append(u)
	return out


## The bounty flag (group "bounties") under the mouse: a layer-2 hit on it, else the one drawn nearest the click
## within 22 px (its pole). Hidden (fogged) flags are skipped.
func flag_at(screen_pos: Vector2) -> Node3D:
	if camera == null:
		return null
	var flags := get_tree().get_nodes_in_group(&"bounties")
	if flags.is_empty():
		return null
	var hit := _ray(screen_pos, 2)
	if hit:
		var f := _in_group_upwards(hit.collider, &"bounties")
		if f != null and _flag_alive(f):
			return f
	var best: Node3D = null
	var best_d := FLAG_CLICK_PX
	for node in flags:
		var f := node as Node3D
		if f == null or not _flag_alive(f) or not BountyMode.flag_shown(f, Unit.Team.PLAYER):
			continue   # an enemy flag out of sight can't be clicked
		for h: float in [0.4, 1.2]:
			var world := f.global_position + Vector3.UP * h
			if camera.is_position_behind(world):
				continue
			var d := camera.unproject_position(world).distance_to(screen_pos)
			if d < best_d:
				best_d = d
				best = f
	return best

## The targeted order waiting for a left click: &"" (none), &"move", &"attack_move", &"gather",
## &"fireball", &"rally" or &"build" (placement ghost).
func get_pending_order() -> StringName:
	return _pending


# ---------------------------------------------------------------- build menu and placement

## True when the selection can build: at least one unit and every selected unit is a worker.
func can_build() -> bool:
	if selected.is_empty() or selected_building != null or is_inspecting():
		return false
	for u in selected:
		if not u.has_method(&"command_build"):
			return false
	return true


## The selected units that can build.
func selected_workers() -> Array[Unit]:
	var out: Array[Unit] = []
	for u in orderable_units():
		if u.has_method(&"command_build"):
			out.append(u)
	return out


## B: the command card shows the build menu (workers only).
func open_build_menu() -> void:
	if not can_build():
		return
	if _pending != &"":
		cancel_targeting()
	_end_bounty_mode()
	if not build_menu_open:
		build_menu_open = true
		mode_changed.emit()


## Back to the normal card (Esc / right click / Back button); also ends a placement.
func close_build_menu() -> void:
	if _pending == ORDER_BUILD:
		cancel_targeting()
	if build_menu_open:
		build_menu_open = false
		mode_changed.emit()


## What the selected workers can build, in menu order (Hearth, Hall, Spire for Fire).
func buildable_types() -> Array[BuildingType]:
	return BuildingType.buildable_for(_player_faction())


## "" if the player could place `type` somewhere now, else why not (for the build menu buttons), in the grid's
## order: the prerequisite ("Needs a completed Hall"), "Not enough crystals", then the limit
## (BuildGrid.limit_message: "Population limit reached", "Only one Bazaar", "Wall limit reached").
func build_reason(type: BuildingType) -> String:
	if type == null:
		return BuildGrid.MSG_UNKNOWN
	var needs := BuildGrid.prerequisite_reason(type, Unit.Team.PLAYER)
	if needs != "":
		return needs
	var eco := Economy.for_team(Unit.Team.PLAYER)
	if eco == null or not eco.can_afford(type.cost):
		return BuildGrid.MSG_NO_CRYSTALS
	if BuildGrid.at_limit(type, Unit.Team.PLAYER):
		return BuildGrid.limit_message(type)
	return ""


## Z / X / C in the build menu (or its buttons): the ghost of `type` follows the mouse.
## Refused (with a message) when the player can't afford it or is at the limit.
func begin_placement(type: BuildingType) -> void:
	if type == null or not can_build() or _build_grid() == null:
		return
	var reason := build_reason(type)
	if reason != "":
		message.emit(reason)
		return
	if _pending != &"" and _pending != ORDER_BUILD:
		cancel_targeting()
	_end_bounty_mode()
	build_menu_open = false
	placing_type = type
	_pending = ORDER_BUILD
	_ghost.show_type(type)
	_update_ghost(_mouse_pos)
	mode_changed.emit()


## Moves the ghost to the last mouse position now (it also follows the mouse every frame).
func refresh_ghost() -> void:
	if _pending == ORDER_BUILD:
		_update_ghost(_mouse_pos)


## The snapped centre under the ghost (Vector3.INF when none) and its refusal message ("" = valid).
func ghost_center() -> Vector3:
	return _ghost_center


func ghost_reason() -> String:
	return _ghost_reason


## Left click during a placement: places the site under `screen_pos` with the selected workers.
## `keep_placing` (Shift) keeps the ghost up afterwards. Returns the site, or null (message shown).
func place_building_at_screen(screen_pos: Vector2, keep_placing := false) -> Building:
	var p: Variant = ground_point(screen_pos)
	if p == null:
		return null
	return place_building_at(p, keep_placing)


## Places `placing_type` at `point` (snapped) for the selected workers. See place_building_at_screen.
func place_building_at(point: Vector3, keep_placing := false) -> Building:
	var grid := _build_grid()
	if grid == null or placing_type == null or not can_build():
		cancel_targeting()
		return null
	var type := placing_type
	var center := grid.snap(point, type.footprint)
	if not footprint_explored(type, center):
		# Checked here, not in BuildGrid (see _placement_reason); ground rules still speak first.
		message.emit(_placement_reason(grid, type, center))
		_update_ghost(_mouse_pos)
		return null
	var split := keep_placing or _shift_session
	var workers := selected_workers()
	var queue_to: Unit = null
	if split and not workers.is_empty():
		var free := workers.filter(func(w: Unit) -> bool: return not _split_busy(w))
		if not free.is_empty():
			workers = [_nearest_worker(free, center)]
		else:
			queue_to = _shortest_queue_worker(workers, center)
			workers = []
	if split:
		# Replay: the place with the workers really used (one, or none when queued), not the whole selection
		_REPLAY.note(&"call", [grid, &"place", type, center, Unit.Team.PLAYER, workers.duplicate()], self)
	else:
		_REPLAY.note(&"place", [type, center], self)
	var site := grid.place(type, center, Unit.Team.PLAYER, workers)
	if site != null and split:
		_shift_session = keep_placing
		if queue_to != null:
			var q: Array = _build_queue.get(queue_to, [])
			q.append(site)
			_build_queue[queue_to] = q
		elif not workers.is_empty():
			_build_current[workers[0]] = site
	if site == null:
		# "Not enough crystals" already reaches the HUD through Economy.spend_failed (top bar).
		if grid.last_reason != BuildGrid.MSG_NO_CRYSTALS:
			message.emit(grid.last_reason)
		_update_ghost(_mouse_pos)
		return null
	_spawn_marker(center, Color(0.3, 1.0, 0.4))
	if not keep_placing:
		cancel_targeting()
	else:
		_update_ghost(_mouse_pos)
	return site


## U1-3: the Shift-placed sites waiting for worker `w` (read only, in build order).
func build_queue_of(w: Unit) -> Array:
	return (_build_queue.get(w, []) as Array).duplicate()


## U1-3: true while `w` builds a site the Shift split gave it (or has sites queued).
func _split_busy(w: Unit) -> bool:
	if (_build_queue.get(w, []) as Array).size() > 0:
		return true
	var site: Variant = _build_current.get(w)
	return site != null and is_instance_valid(site) and _site_open(site) and w.get(&"build_site") == site


func _site_open(site: Variant) -> bool:
	if site == null or not is_instance_valid(site) or not _building_alive(site):
		return false
	return not (site.has_method(&"is_constructed") and bool(site.call(&"is_constructed")))


func _nearest_worker(list: Array, at: Vector3) -> Unit:
	var best: Unit = null
	var best_d := INF
	for w: Unit in list:
		var d := w.global_position.distance_squared_to(at)
		if d < best_d:
			best_d = d
			best = w
	return best


func _shortest_queue_worker(list: Array, at: Vector3) -> Unit:
	var best: Unit = null
	var best_n := 1 << 30
	var best_d := INF
	for w: Unit in list:
		var n := (_build_queue.get(w, []) as Array).size()
		var d := w.global_position.distance_squared_to(at)
		if n < best_n or (n == best_n and d < best_d):
			best_n = n
			best_d = d
			best = w
	return best


## U1-3: a worker whose split site is finished or gone starts its next queued site; a worker the player ordered
## elsewhere (another site, a move...) drops its queue. Runs 4 times a second while a queue exists.
func advance_build_queues() -> void:
	for w: Variant in _build_current.keys():
		if w == null or not is_instance_valid(w) or not (w as Unit).is_alive():
			var orphans: Array = _build_queue.get(w, [])
			_build_current.erase(w)
			_build_queue.erase(w)
			_rehome_sites(orphans)   # the dead builder's paid sites go to another worker
			continue
		var worker := w as Unit
		var cur: Variant = _build_current[w]
		if _site_open(cur):
			if worker.get(&"build_site") != cur:
				_build_current.erase(w)   # re-ordered by the player: the queue is dropped
				_build_queue.erase(w)
			continue
		var q: Array = _build_queue.get(w, [])
		var next: Variant = null
		while not q.is_empty():
			var s0: Variant = q.pop_front()
			if _site_open(s0):
				next = s0
				break
		if next == null:
			_build_current.erase(w)
			_build_queue.erase(w)
			continue
		_build_queue[w] = q
		_build_current[w] = next
		_REPLAY.note(&"call", [worker, &"command_build", next], self)   # a UI-timer order: noted for replays
		worker.call(&"command_build", next)


## U1-3: the open sites a dead builder still had queued go to another worker of the split (shortest queue), else the
## nearest idle own worker; with nobody left the player is told.
func _rehome_sites(sites: Array) -> void:
	var open := sites.filter(func(x: Variant) -> bool: return _site_open(x))
	if open.is_empty():
		return
	var others: Array = []
	for o: Variant in _build_current.keys():
		if o != null and is_instance_valid(o) and (o as Unit).is_alive():
			others.append(o)
	var at: Vector3 = (open[0] as Node3D).global_position
	var heir: Unit = _shortest_queue_worker(others, at) if not others.is_empty() else _nearest_idle_worker(at)
	if heir == null:
		message.emit("A builder died: its queued buildings wait for a worker")
		return
	if _build_current.has(heir):
		var q: Array = _build_queue.get(heir, [])
		q.append_array(open)
		_build_queue[heir] = q
	else:
		var first: Variant = open.pop_front()
		_build_current[heir] = first
		_build_queue[heir] = open
		_REPLAY.note(&"call", [heir, &"command_build", first], self)
		heir.call(&"command_build", first)


func _nearest_idle_worker(at: Vector3) -> Unit:
	var best: Unit = null
	var best_d := INF
	for node in get_tree().get_nodes_in_group("units"):
		var u := node as Unit
		if u == null or u.team != Unit.Team.PLAYER or not u.is_alive() or not u.has_method(&"command_build") \
				or not is_commandable_unit(u):
			continue
		if u.has_method(&"is_building") and bool(u.call(&"is_building")):
			continue
		if u.has_method(&"is_gathering") and bool(u.call(&"is_gathering")):
			continue
		var d := u.global_position.distance_squared_to(at)
		if d < best_d:
			best_d = d
			best = u
	return best


## Delete / the Cancel button with a construction site selected: cancels it (75 % refund).
## Returns false when no site is selected.
func cancel_site() -> bool:
	var b := selected_building
	if b == null or not _building_alive(b) or not b.has_method(&"cancel_construction"):
		return false
	if b.has_method(&"is_constructed") and bool(b.call(&"is_constructed")):
		return false
	_REPLAY.note(&"cancel_site", [b], self)
	b.call(&"cancel_construction")
	select_units([])
	return true


## The player's living keep, or null.
func own_keep() -> Node3D:
	for node in get_tree().get_nodes_in_group("buildings"):
		if node is Keep and int(node.get("team")) == Unit.Team.PLAYER and _building_alive(node):
			return node
	return null


## Starts a targeted order (cross cursor; left click confirms, right click / Esc cancels).
func begin_order(order: StringName) -> void:
	match order:
		ORDER_FIREBALL:
			begin_fireball_targeting()
			return
		ORDER_ATTACK_MOVE:
			begin_attack_move_targeting()
			return
		ORDER_MOVE:
			if orderable_units().is_empty():
				return
		ORDER_GATHER:
			if not has_gatherers() and not has_caravans():
				return
		ORDER_RALLY:
			if selected_building == null or not selected_building.has_method("set_rally_point"):
				return
		ORDER_ROUTE:
			if selected_market() == null:
				return
		_:
			return
	cancel_targeting()
	close_build_menu()
	_end_bounty_mode()
	_pending = order
	Input.set_default_cursor_shape(Input.CURSOR_CROSS)


## The Fireball button / F: spell 1 (Fireball for Vessa).
func begin_fireball_targeting() -> void:
	cast_spell_slot(0)


## The spell being aimed, or &"" (then get_pending_order() returns the same id).
func pending_spell() -> StringName:
	return _pending_spell


## F / Q / E (slot 0 / 1 / 2): targeted spells start the cross cursor, self spells cast at once.
func cast_spell_slot(slot: int) -> void:
	var spell_ids := SpellInfo.ids(hero)
	if slot < 0 or slot >= spell_ids.size():
		return
	begin_spell(spell_ids[slot])


## Ctrl + F / Q / E (or the card's + chip): learn or rank up that spell. Never starts targeting.
func learn_spell_slot(slot: int) -> String:
	var spell_ids := SpellInfo.ids(hero)
	if slot < 0 or slot >= spell_ids.size() or hero == null or not is_instance_valid(hero):
		return "Unknown spell"
	if not hero.has_method(&"learn_spell"):
		return "No spell points"
	_REPLAY.note(&"learn", [spell_ids[slot]], self)
	var result := str(hero.call(&"learn_spell", spell_ids[slot]))
	if result != "":
		message.emit(result)
	return result


func begin_spell(spell_id: StringName) -> void:
	if hero == null or not is_instance_valid(hero) or not hero.is_alive():
		return
	var reason := SpellInfo.cast_reason(hero, spell_id)
	if reason != "":
		message.emit(reason)
		return
	var target := SpellInfo.target_type(spell_id)
	if target == &"self" or target == &"none":
		_cast(spell_id, null)
		return
	cancel_targeting()
	close_build_menu()
	_end_bounty_mode()
	var r := SpellInfo.value(hero, spell_id, "radius", maxi(1, SpellInfo.rank(hero, spell_id)))
	if target == &"unit" or r <= 0.0:
		r = 0.8
	var torus := TorusMesh.new()
	torus.inner_radius = maxf(r - 0.2, 0.1)
	torus.outer_radius = r
	torus.rings = 48
	_target_ring.mesh = torus
	_target_ring.scale = Vector3(1.0, 0.1, 1.0)
	_target_ring.visible = true
	_pending_spell = spell_id
	_pending = spell_id
	Input.set_default_cursor_shape(Input.CURSOR_CROSS)


## Orders the cast (Wizard.command_cast, or command_fireball on a wave 2 wizard).
func _cast(spell_id: StringName, target: Variant) -> void:
	if hero == null or not is_instance_valid(hero) or not hero.is_alive():
		return
	_REPLAY.note(&"cast", [spell_id, target], self)
	var result := ""
	if hero.has_method(&"command_cast"):
		result = str(hero.call(&"command_cast", spell_id, target))
	elif spell_id == &"fireball" and target is Vector3:
		result = hero.command_fireball(target)
	if result != "":
		message.emit(result)


func cancel_targeting() -> void:
	var was_placing := _pending == ORDER_BUILD
	_shift_session = false
	_pending = &""
	_pending_spell = &""
	_pending_item_slot = -1
	_pending_caster_spell = &""
	if _caster_ghost:
		_caster_ghost.visible = false
	if _range_ring:
		_range_ring.visible = false
	_target_ring.visible = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	if placing_type != null or was_placing:
		placing_type = null
		_ghost.visible = false
		_ghost_label.visible = false
		_ghost_center = Vector3.INF
		_ghost_reason = ""
		mode_changed.emit()


# ---------------------------------------------------------------- caster units (caster-units.md 3.2)

## The selected own casters (of `type_id`, or of any caster type when &"").
func selected_casters(type_id: StringName = &"") -> Array[Unit]:
	var out: Array[Unit] = []
	for u in orderable_units():
		if not u.is_alive() or u.unit_type == null or not CasterKit.is_caster_unit(u):
			continue
		if type_id == &"" or u.unit_type.id == type_id:
			out.append(u)
	return out


## The caster type Z / V act for: the active subgroup's when it is a caster, else the first caster type selected
## (&"" = no caster selected).
func caster_type() -> StringName:
	var active := active_unit_type()
	if active != &"" and CasterKit.is_caster(active) and not selected_casters(active).is_empty():
		return active
	for u in selected_casters():
		return u.unit_type.id
	return &""


## The Z / V spells of the selected casters ([] when none).
func caster_spell_ids() -> Array[StringName]:
	var t := caster_type()
	if t == &"":
		var none: Array[StringName] = []
		return none
	return CasterKit.spells_of(t)


## The spell being aimed by the casters, or &"".
func pending_caster_spell() -> StringName:
	return _pending_caster_spell


## Z (slot 0) / V (slot 1): starts aiming that spell (cross cursor, range ring, area preview), or says why no selected
## caster can cast it (Not enough mana, Recharging, Can't cast now).
func cast_caster_slot(slot: int) -> void:
	var ids := caster_spell_ids()
	if slot < 0 or slot >= ids.size():
		return
	begin_caster_spell(ids[slot])


func begin_caster_spell(spell_id: StringName) -> void:
	var casters := selected_casters(CasterKit.caster_of_spell(spell_id))
	if casters.is_empty():
		return
	var reason := caster_ready_reason(spell_id)
	if reason != "":
		message.emit(reason)
		return
	cancel_targeting()
	close_build_menu()
	_end_bounty_mode()
	var r := float(CasterKit.spell_value(spell_id, "radius", 0.0))
	if CasterKit.target_kind(spell_id) != &"point" or r <= 0.0:
		r = 0.8
	var torus := TorusMesh.new()
	torus.inner_radius = maxf(r - 0.2, 0.1)
	torus.outer_radius = r
	torus.rings = 48
	_target_ring.mesh = torus
	_target_ring.scale = Vector3(1.0, 0.1, 1.0)
	_target_ring.visible = spell_id != &"rime_bulwark"
	_ensure_caster_aim_meshes()
	_caster_ghost.visible = spell_id == &"rime_bulwark"
	var rng := float(CasterKit.spell_value(spell_id, "range", 0.0))
	(_range_ring.mesh as TorusMesh).inner_radius = maxf(rng - 0.12, 0.1)
	(_range_ring.mesh as TorusMesh).outer_radius = rng
	_range_ring.visible = true
	_pending_caster_spell = spell_id
	_pending = spell_id
	Input.set_default_cursor_shape(Input.CURSOR_CROSS)
	_update_caster_aim()


## "" when at least one selected caster could cast `spell_id` (target and range aside), else the best refusal.
func caster_ready_reason(spell_id: StringName) -> String:
	var casters := selected_casters(CasterKit.caster_of_spell(spell_id))
	if casters.is_empty():
		return CasterKit.REASON_CANT
	var reasons := {}
	for u in casters:
		var ab := CasterKit.ability_of(u)
		var r := ""
		if not u.can_act() or u.is_displaced():
			r = CasterKit.REASON_CANT
		elif ab.cooldown_left(spell_id) > 0.0:
			r = CasterKit.REASON_RECHARGING
		elif ab.mana + 0.001 < ab.mana_cost(spell_id):
			r = CasterKit.REASON_MANA
		if r == "":
			return ""
		reasons[r] = true
	for r: String in [CasterKit.REASON_MANA, CasterKit.REASON_RECHARGING, CasterKit.REASON_CANT]:
		if reasons.has(r):
			return r
	return CasterKit.REASON_CANT


## One click = one cast (smart-cast): the selected caster with the most mana in range casts, else the nearest walks
## into range. Returns "" or the refusal (also sent as a message).
func cast_caster_at(spell_id: StringName, target: Variant) -> String:
	var casters := selected_casters(CasterKit.caster_of_spell(spell_id))
	var why: Array = []
	var u := CasterKit.pick_caster(casters, spell_id, target, why)
	var result := ""
	if u == null:
		result = str(why[0]) if not why.is_empty() else CasterKit.REASON_CANT
	else:
		_REPLAY.note(&"caster_cast", [spell_id, target], self)
		result = CasterKit.ability_of(u).order_cast(spell_id, target)
	if result != "":
		message.emit(result)
	return result


## Ctrl+Z / Ctrl+V or a right click on the button: autocast on for every selected caster of that type (off when all
## of them already have it on). Returns the new state.
func toggle_caster_autocast(slot: int) -> bool:
	var ids := caster_spell_ids()
	if slot < 0 or slot >= ids.size():
		return false
	var sid := ids[slot]
	var casters := selected_casters(CasterKit.caster_of_spell(sid))
	var all_on := true
	for u in casters:
		if not CasterKit.ability_of(u).autocast(sid):
			all_on = false
	_REPLAY.note(&"caster_autocast", [sid, not all_on], self)
	for u in casters:
		CasterKit.ability_of(u).set_autocast(sid, not all_on)
	return not all_on


## The autocast state of `spell_id` over the selected casters: 0 = off, 1 = on for all, 2 = mixed.
func caster_autocast_state(spell_id: StringName) -> int:
	var on := 0
	var casters := selected_casters(CasterKit.caster_of_spell(spell_id))
	for u in casters:
		if CasterKit.ability_of(u).autocast(spell_id):
			on += 1
	if on == 0:
		return 0
	return 1 if on == casters.size() else 2


func _ensure_caster_aim_meshes() -> void:
	if _caster_ghost == null:
		_caster_ghost = MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(float(CasterKit.spell_value(&"rime_bulwark", "length", 4.0)), 0.25,
				float(CasterKit.spell_value(&"rime_bulwark", "thick", 0.9)))
		_caster_ghost.mesh = box
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(0.55, 0.8, 1.0, 0.45)
		_caster_ghost.material_override = mat
		_caster_ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_caster_ghost.visible = false
		add_child(_caster_ghost)
	if _range_ring == null:
		_range_ring = MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.rings = 64
		_range_ring.mesh = torus
		_range_ring.scale = Vector3(1.0, 0.05, 1.0)
		var rmat := StandardMaterial3D.new()
		rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		rmat.albedo_color = Color(1.0, 0.85, 0.4, 0.35)
		_range_ring.material_override = rmat
		_range_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_range_ring.visible = false
		add_child(_range_ring)


# Follows the mouse while a caster spell is aimed: the area ring / wall ghost at the point, the range ring on the
# caster that would cast (in range: bright, else pale).
func _update_caster_aim() -> void:
	var spell := _pending_caster_spell
	var casters := selected_casters(CasterKit.caster_of_spell(spell))
	if casters.is_empty():
		cancel_targeting()
		return
	var p: Variant = ground_point(_box_ui.get_local_mouse_position()) if camera != null else null
	if p == null:
		return
	var point := p as Vector3
	var target: Variant = point
	if CasterKit.target_kind(spell) != &"point":
		var hovered := unit_at(_box_ui.get_local_mouse_position()) if camera != null else null
		target = hovered if hovered != null else point
	var who: Unit = null
	if target is Unit or CasterKit.target_kind(spell) == &"point":
		who = CasterKit.pick_caster(casters, spell, target)
	if who == null:
		who = _nearest_caster(casters, point)
	var in_range := CasterKit.ability_of(who).distance_to_target(target) \
			<= float(CasterKit.spell_value(spell, "range", 0.0))
	_target_ring.global_position = point + Vector3.UP * 0.06
	_target_ring_mat.albedo_color = Color(1.0, 0.5, 0.1, 0.85) if in_range else Color(1.0, 0.8, 0.3, 0.45)
	_range_ring.global_position = who.global_position + Vector3.UP * 0.05
	if spell == &"rime_bulwark":
		var facing := _bulwark_facing(who, point)
		var x_axis := Vector3(-facing.normalized().z, 0.0, facing.normalized().x)
		_caster_ghost.global_transform = Transform3D(Basis(x_axis, Vector3.UP, x_axis.cross(Vector3.UP)),
				point + Vector3.UP * 0.15)
		(_caster_ghost.material_override as StandardMaterial3D).albedo_color = Color(0.55, 0.8, 1.0, 0.5) if in_range \
				else Color(0.8, 0.8, 0.8, 0.3)


# The Rime Bulwark lies across this (the line from the caster the ghost shows to the point). The click sends it with
# the point ({at, facing}), so the wall that rises matches the ghost even when the caster walks in first (review L4).
static func _bulwark_facing(who: Unit, point: Vector3) -> Vector3:
	var facing := point - who.global_position if who != null else Vector3.FORWARD
	facing.y = 0.0
	if facing.length() < 0.01:
		facing = Vector3.FORWARD
	return facing


# A Rime Bulwark click (3D view or minimap) at `target` (a Vector3) -> {at, facing} with the facing the ghost showed:
# from the caster smart-cast picks, else the nearest (as _update_caster_aim). Other spells: `target` unchanged.
func _with_bulwark_facing(spell: StringName, target: Variant) -> Variant:
	if spell != &"rime_bulwark" or not (target is Vector3):
		return target
	var casters := selected_casters(CasterKit.caster_of_spell(spell))
	if casters.is_empty():
		return target
	var who := CasterKit.pick_caster(casters, spell, target)
	if who == null:
		who = _nearest_caster(casters, target as Vector3)
	return {"at": target, "facing": _bulwark_facing(who, target as Vector3)}


func _nearest_caster(casters: Array[Unit], point: Vector3) -> Unit:
	var best: Unit = casters[0]
	var bd := INF
	for u in casters:
		var d := Vector2(u.global_position.x - point.x, u.global_position.z - point.z).length()
		if d < bd:
			bd = d
			best = u
	return best


# Left click while aiming a caster spell: an enemy / own unit under the cursor for the unit spells, else a ground point.
# Shift keeps the cursor for the next caster.
func _confirm_caster_spell(spell: StringName, pos: Vector2, keep_aiming: bool) -> void:
	var kind := CasterKit.target_kind(spell)
	var target: Variant = null
	if kind == &"point":
		target = ground_point(pos)
	else:
		var u := unit_at(pos)
		if u != null and ((kind == &"enemy") == (u.team != Unit.Team.PLAYER)):
			target = u
	if target == null:
		message.emit(CasterKit.REASON_NO_TARGET if kind == &"point" else "Pick a unit")
		begin_caster_spell(spell)   # the cursor stays: pick again
		return
	var r := cast_caster_at(spell, _with_bulwark_facing(spell, target))
	if keep_aiming and r == "" and caster_ready_reason(spell) == "":
		begin_caster_spell(spell)


# ---------------------------------------------------------------- items (4.U1a; items code read untyped)

## Numpad 1-6 / a click on the inventory bar: point actives start the cross cursor, the rest fire now.
## Returns the refusal reason ("" = used or aiming).
func use_item_slot(slot: int) -> String:
	if hero == null or not is_instance_valid(hero):
		return "No wizard"
	var inv := InventoryBar.inventory_of(hero)
	if inv == null or not inv.has_method(&"use_item"):
		return "No inventory"
	var type: Variant = InventoryBar.type_of_entry(InventoryBar.slot_entry(inv, slot))
	if type != null and ItemTooltip.active_target(type) == &"point" and hero.is_alive():
		begin_item_targeting(slot)
		return ""
	var target: Variant = hero if type != null and ItemTooltip.active_target(type) == &"self" else null
	return _use_item(slot, target)


## A point item active (Blink): next left click on the ground uses it (right click / Esc cancels).
func begin_item_targeting(slot: int) -> void:
	cancel_targeting()
	close_build_menu()
	_end_bounty_mode()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.6
	torus.outer_radius = 0.8
	torus.rings = 48
	_target_ring.mesh = torus
	_target_ring.scale = Vector3(1.0, 0.1, 1.0)
	_target_ring_mat.albedo_color = Color(0.3, 0.75, 1.0, 0.85)
	_target_ring.visible = true
	_pending = ORDER_ITEM
	_pending_item_slot = slot
	Input.set_default_cursor_shape(Input.CURSOR_CROSS)


## The item slot being aimed, or -1.
func pending_item_slot() -> int:
	return _pending_item_slot


func _use_item(slot: int, target: Variant) -> String:
	var inv := InventoryBar.inventory_of(hero)
	if inv == null or not inv.has_method(&"use_item"):
		return "No inventory"
	_REPLAY.note(&"use_item", [slot, target], self)
	var result := str(inv.call(&"use_item", slot, target))
	if result != "":
		message.emit(result)
	return result


## The ground item (group "item_pickups") under the mouse: a layer-2 hit on it, else the one drawn
## nearest the click within 28 px.
func item_pickup_at(screen_pos: Vector2) -> Node3D:
	if camera == null:
		return null
	var pickups := get_tree().get_nodes_in_group(&"item_pickups")
	if pickups.is_empty():
		return null
	var hit := _ray(screen_pos, 2)
	if hit:
		var n := _in_group_upwards(hit.collider, &"item_pickups")
		if n != null:
			return n
	var best: Node3D = null
	var best_d := PICKUP_CLICK_PX
	for node in pickups:
		var p := node as Node3D
		if p == null or not p.is_inside_tree():
			continue
		var world := p.global_position + Vector3.UP * 0.6
		if camera.is_position_behind(world):
			continue
		var d := camera.unproject_position(world).distance_to(screen_pos)
		if d < best_d:
			best_d = d
			best = p
	return best


## Right click on a ground item with Vessa selected: she walks there and takes it at 2.2 m
## (the wizard's own `command_pickup` when gameplay adds one).
func pick_up_item(pickup: Node3D) -> void:
	if hero == null or not is_instance_valid(hero) or not hero.is_alive() or pickup == null:
		return
	_REPLAY.note(&"pick_up_item", [pickup], self)
	if hero.has_method(&"command_pickup"):
		var r: Variant = hero.call(&"command_pickup", pickup)
		if r is String and r != "":
			message.emit(r)
		return
	hero.command_move(pickup.global_position)
	_spawn_marker(pickup.global_position, Color(1.0, 0.85, 0.3))
	_pickup_target = pickup
	_pickup_time_left = 30.0
	# ItemPickup takes itself when she is within 2.2 m: listen for it, and let the dropper retake it.
	if pickup.has_method(&"request_pickup"):
		pickup.call(&"request_pickup", hero)
	if pickup.has_signal(&"picked_up") and not pickup.is_connected(&"picked_up", _on_item_picked_up):
		pickup.connect(&"picked_up", _on_item_picked_up, CONNECT_ONE_SHOT)


func _on_item_picked_up(_pickup: Variant, wizard: Variant, type: Variant) -> void:
	if wizard == hero:
		message.emit(Loc.t("Picked up %s") % ItemTooltip.display_name(type))


## The ground item Vessa is walking to, or null.
func pickup_target() -> Node3D:
	return _pickup_target


func _update_pickup(delta: float) -> void:
	if _pickup_target == null:
		return
	_pickup_time_left -= delta
	if not is_instance_valid(_pickup_target) or not _pickup_target.is_inside_tree() \
			or hero == null or not is_instance_valid(hero) or not hero.is_alive() or _pickup_time_left <= 0.0:
		_pickup_target = null
		return
	var off := _pickup_target.global_position - hero.global_position
	if Vector2(off.x, off.z).length() <= PICKUP_RANGE:
		var p := _pickup_target
		_pickup_target = null
		_take_pickup(p)


## Takes the item: the pickup's own method when it has one, else `inventory.add_item(type)` + free it.
func _take_pickup(pickup: Node3D) -> void:
	var type: Variant = InventoryBar.pickup_type(pickup)
	var name := ItemTooltip.display_name(type) if type != null else "item"
	var result: Variant = null
	var handled := false
	for m in [&"pick_up", &"try_pick_up", &"take", &"collect"]:
		if pickup.has_method(m):
			result = pickup.call(m, hero)
			handled = true
			break
	if not handled:
		var inv := InventoryBar.inventory_of(hero)
		if inv == null or not inv.has_method(&"add_item") or type == null:
			return
		result = inv.call(&"add_item", type)
		if result is bool and result:
			pickup.queue_free()
	if result is String:
		message.emit(result if result != "" else Loc.t("Picked up %s") % name)
	elif result is bool:
		message.emit(Loc.t("Picked up %s") % name if result else "Inventory full")


## A (Classic) or X pressed: the next left click gives an attack-move order (right click / Esc cancels).
## Caravans alone never attack-move (they never fight).
func begin_attack_move_targeting() -> void:
	if orderable_units().is_empty() or orderable_units().all(is_caravan):
		return
	cancel_targeting()
	close_build_menu()
	_end_bounty_mode()
	_pending = ORDER_ATTACK_MOVE
	Input.set_default_cursor_shape(Input.CURSOR_CROSS)


func is_attack_move_pending() -> bool:
	return _pending == ORDER_ATTACK_MOVE


## True if the selection holds at least one worker (Cinder Hand...).
func has_workers() -> bool:
	for u in orderable_units():
		if _is_worker(u):
			return true
	return false


## True if at least one selected worker can take a gather order right now.
func has_gatherers() -> bool:
	for u in orderable_units():
		if u.has_method("command_gather"):
			return true
	return false


## True if the selection holds a unit that fights (anything but a worker or a caravan, the wizard included).
func has_fighters() -> bool:
	for u in orderable_units():
		if not _is_worker(u) and not is_caravan(u):
			return true
	return false


## True if the selection holds a caravan (group "caravans").
func has_caravans() -> bool:
	for u in orderable_units():
		if is_caravan(u):
			return true
	return false


## The selected caravans.
func selected_caravans() -> Array[Unit]:
	var out: Array[Unit] = []
	for u in orderable_units():
		if is_caravan(u):
			out.append(u)
	return out


## A trade caravan (group "caravans", or a unit with `command_trade`).
static func is_caravan(u: Object) -> bool:
	if u == null or not is_instance_valid(u) or not u is Node:
		return false
	return (u as Node).is_in_group(&"caravans") or (u as Node).has_method(&"command_trade")


## The selected own, completed, living Bazaar (group "markets"), or null.
func selected_market() -> Node3D:
	var b := selected_building
	if b == null or not _building_alive(b) or not b.is_in_group(&"markets"):
		return null
	if b.get("team") == null or int(b.get("team")) != Unit.Team.PLAYER:
		return null
	if b.has_method(&"is_constructed") and not bool(b.call(&"is_constructed")):
		return null
	return b


## The trading post (group "trade_posts") under the mouse: a layer-2 ray hit on it, or a ground click within 3.5 m
## (per axis) of its centre, like the taverns. null when none.
func post_at(screen_pos: Vector2) -> Node3D:
	var hit := _neutral_hit(screen_pos)
	var n: Node3D = hit.get("node")
	return n if n != null and n.is_in_group(&"trade_posts") else null


## The trading post or guild house under the mouse (same rule as post_at), or null.
func neutral_building_at(screen_pos: Vector2) -> Node3D:
	return _neutral_hit(screen_pos).get("node")


## The nearest trading post whose centre is within `radius` m (flat) of `point` (the minimap), or null.
func post_near(point: Vector3, radius: float = MINIMAP_POST_RADIUS) -> Node3D:
	var best: Node3D = null
	var best_d := radius
	for node in get_tree().get_nodes_in_group(&"trade_posts"):
		var p := node as Node3D
		if p == null or not p.is_inside_tree():
			continue
		var d := Vector2(p.global_position.x - point.x, p.global_position.z - point.z).length()
		if d <= best_d:
			best_d = d
			best = p
	return best


## The visible, living game critter under the mouse (its click area is the first thing the layer-2 ray hits, or
## nothing is under the mouse and it is drawn within 18 px), or null.
func critter_at(screen_pos: Vector2) -> Node3D:
	return _critter_hit(screen_pos).get("node")


## The capture point under the mouse (its body / click area first, else a ground click within capture_radius x 0.5
## of a watchtower / well centre), or null.
func point_at(screen_pos: Vector2) -> Node3D:
	return _point_hit(screen_pos).get("node")


## True for a selected unit that may be ordered onto a game critter: a combatant, never a worker (anything with
## command_gather), a caravan or a Greywater Tracker (map-fill.md 3.4).
static func can_hunt(u: Object) -> bool:
	if u == null or not is_instance_valid(u) or not u is Unit:
		return false
	var unit := u as Unit
	if unit.is_non_combatant() or unit.has_method(&"command_gather") or is_caravan(unit):
		return false
	if unit.is_in_group(&"trackers") or (unit.unit_type != null and unit.unit_type.id == &"greywater_tracker"):
		return false
	return is_commandable_unit(unit)


## The selected units that can hunt a critter.
func hunters() -> Array[Unit]:
	var out: Array[Unit] = []
	for u in orderable_units():
		if can_hunt(u):
			out.append(u)
	return out


## Right click / A-click on a critter: the hunters attack it; every other selected unit gets the order the click
## gives on the ground under it (`at`, else the critter's spot): a move, or an attack-move for an A-click. Workers,
## caravans and trackers are never given command_attack on a critter.
func hunt_critter(critter: Node3D, at: Variant = null, as_attack_move := false) -> void:
	if not _critter_ok(critter):
		return
	var units := orderable_units()
	if units.is_empty():
		return
	_REPLAY.note(&"hunt_critter", [critter, at, as_attack_move], self)
	_pickup_target = null
	var others: Array[Unit] = []
	for u in units:
		if can_hunt(u):
			u.command_attack(critter)
		else:
			others.append(u)
	var spot: Vector3 = at if at is Vector3 else Vector3(critter.global_position.x, 0.0, critter.global_position.z)
	var offsets := _formation_offsets(others.size())
	for i in others.size():
		var u := others[i]
		if as_attack_move and not is_caravan(u) and u.has_method(&"command_attack_move"):
			u.call(&"command_attack_move", spot + offsets[i])
		else:
			u.command_move(spot + offsets[i])
	_spawn_marker(critter.global_position, Color(1.0, 0.25, 0.2))


## Sets the selected Bazaar's route to `post` (the card's route buttons, right click, Set Route). Returns "" or the
## refusal (also on the message line): "Not a trading post", "Route too short"...
func set_market_route(post: Node3D) -> String:
	var market := selected_market()
	if market == null:
		return "No Bazaar selected"
	if not market.has_method(&"set_route"):
		return "No Bazaar selected"
	_REPLAY.note(&"set_market_route", [post], self)
	var result := str(market.call(&"set_route", post))
	if result != "":
		message.emit(result)
	else:
		_spawn_marker(RouteLine.door_of(post), Color(1.0, 0.85, 0.3))
		mode_changed.emit()   # the card refreshes its route buttons now (the route line follows route_changed)
	return result


## The Bazaar hint for a right click that is not on a post (at most once per 2 s). Returns true when shown.
func show_route_hint() -> bool:
	if _clock - _route_hint_time < ROUTE_HINT_INTERVAL:
		return false
	_route_hint_time = _clock
	message.emit(MSG_ROUTE_HINT)
	return true


## Caravans trade with `target` (a trading post: from now on; the own Bazaar: go home and deliver); every other
## selected unit walks next to it. Refusals go to the message line (once).
func trade_with(target: Node3D) -> void:
	if target == null or not is_instance_valid(target):
		return
	_REPLAY.note(&"trade_with", [target], self)
	_pickup_target = null
	var others: Array[Unit] = []
	var refusal := ""
	for u in orderable_units():
		if is_caravan(u) and u.has_method(&"command_trade"):
			var r := str(u.call(&"command_trade", target))
			if r != "" and refusal == "":
				refusal = r
		else:
			others.append(u)
	var spot := RouteLine.door_of(target) if target.is_in_group(&"trade_posts") \
			else target.global_position + Vector3(0.0, 0.0, 5.0)
	var offsets := _formation_offsets(others.size())
	for i in others.size():
		others[i].command_move(spot + offsets[i])
	if refusal != "":
		message.emit(refusal)
	_spawn_marker(RouteLine.door_of(target) if target.is_in_group(&"trade_posts") else target.global_position,
			Color(1.0, 0.85, 0.3))


## The mouse position the selection last saw (screen pixels).
func mouse_position() -> Vector2:
	return _mouse_pos


func has_hero() -> bool:
	return hero != null and is_instance_valid(hero) and selected.has(hero)


## Attack-move the selection to `center` in the same square formation as a move.
func attack_move(center: Vector3) -> void:
	_REPLAY.note(&"attack_move", [center], self)
	var units := orderable_units()
	var offsets := _formation_offsets(units.size())
	for i in units.size():
		var u := units[i]
		if is_caravan(u):
			u.command_move(center + offsets[i])   # caravans never attack-move
		elif u.has_method("command_attack_move"):
			u.call("command_attack_move", center + offsets[i])
		else:
			u.command_move(center + offsets[i])


func hold() -> void:
	_REPLAY.note(&"hold", [], self)
	_pickup_target = null
	for u in orderable_units():
		if u.has_method("command_hold"):
			u.call("command_hold")
		else:
			u.command_stop()


func stop() -> void:
	_REPLAY.note(&"stop", [], self)
	_pickup_target = null
	for u in orderable_units():
		u.command_stop()


## Plain move with a ground marker (used by right click on the ground and on the minimap).
func order_move(point: Vector3) -> void:
	if orderable_units().is_empty():
		return
	_pickup_target = null
	formation_move(point)
	_spawn_marker(point, Color(0.3, 1.0, 0.4))


## A right-click order on a world point (the minimap uses it): rally point with the keep selected,
## gather when workers are selected and the point is near a crystal node, else a plain move.
func order_at(point: Vector3) -> void:
	var node := crystal_node_near(point, NODE_CLICK_RADIUS)
	var post := post_near(point, MINIMAP_POST_RADIUS)
	if selected_market() != null:
		# The Bazaar: a post (within 4 m of its centre) = the route, anything else = the hint.
		if post != null:
			set_market_route(post)
		else:
			show_route_hint()
	elif selected_building != null:
		_set_rally(point, node)
	elif post != null and has_caravans():
		trade_with(post)
	elif node != null and has_gatherers():
		gather(node)
	else:
		order_move(point)


## Workers gather from `node`; other selected units walk next to it.
func gather(node: Node3D) -> void:
	if node == null or not is_instance_valid(node):
		return
	_REPLAY.note(&"gather", [node], self)
	var others: Array[Unit] = []
	for u in orderable_units():
		if u.has_method("command_gather"):
			u.call("command_gather", node)
		else:
			others.append(u)
	var offsets := _formation_offsets(others.size())
	for i in others.size():
		others[i].command_move(node.global_position + Vector3(0.0, 0.0, 3.0) + offsets[i])
	_spawn_marker(node.global_position, Color(0.45, 0.85, 1.0))


## Every selected unit attacks `building` (an enemy or neutral building; always obeyed). Caravans never fight:
## they walk next to it instead.
func attack_building(building: Node3D) -> void:
	if building == null or not _building_alive(building):
		return
	_REPLAY.note(&"attack_building", [building], self)
	for u in orderable_units():
		if is_caravan(u):
			u.command_move(building.global_position)
		else:
			u.command_attack(building)
	_spawn_marker(building.global_position, Color(1.0, 0.25, 0.2))


## Selected workers build (or resume) our unfinished `site`; the other units walk next to it.
func build_site(site: Node3D) -> void:
	if not _is_unfinished_site(site):
		return
	_REPLAY.note(&"build_site", [site], self)
	var others: Array[Unit] = []
	for u in orderable_units():
		if u.has_method(&"command_build"):
			u.call(&"command_build", site)
		else:
			others.append(u)
	var offsets := _formation_offsets(others.size())
	for i in others.size():
		others[i].command_move(site.global_position + Vector3(0.0, 0.0, 5.0) + offsets[i])
	_spawn_marker(site.global_position, Color(0.3, 1.0, 0.4))


## Queues `type` at the selected building. Returns "" or the reason it was refused (also sent as a message).
## With several buildings of the active one's type selected, it goes to the least busy of them that can take it
## (shortest queue; ties: the active one, then Tab order). See `train_target`.
func train(type: Variant) -> String:
	if selected_building == null or not selected_building.has_method("queue_unit"):
		return "No building selected"
	_REPLAY.note(&"train", [type], self)
	var reason: String = str(train_target(type).call("queue_unit", type))
	if reason != "":
		message.emit(reason)
	return reason


## The building `train(type)` queues at: the active one, or the least busy selected building of the same type whose
## `can_queue(type)` is "" (the active one wins ties). The active one when none can take it (its refusal is shown).
func train_target(type: Variant) -> Node3D:
	var active := selected_building
	if active == null or selected_buildings.size() < 2:
		return active
	var active_type: Variant = active.get("building_type")
	var best: Node3D = null
	var best_load := 1 << 30
	var candidates: Array[Node3D] = [active]
	for b in selected_buildings:
		if b != active:
			candidates.append(b)
	for b in candidates:
		if not _building_alive(b) or not b.has_method("queue_unit") or b.get("building_type") != active_type:
			continue
		if b.has_method("can_queue") and str(b.call("can_queue", type)) != "":
			continue
		var q: Variant = b.get("queue")
		var busy := (q as Array).size() if q is Array else 0
		if busy < best_load:
			best = b
			best_load = busy
	return best if best != null else active


## The unit types the selected building can train (empty if none), in slot order.
func trainable_types() -> Array:
	if selected_building == null or not selected_building.has_method("trainable_types"):
		return []
	return selected_building.call("trainable_types")


## The selected building's training card, slot by slot: entry `i` is the type trained with key SLOT_KEYS[i] (Z X C V B
## N M ,), or null for an empty slot (no trailing nulls). It follows trainable_types(), except the keep: while tiers are
## on its tier button keeps slot X, empty at the Citadel, so its tier-3 unit stays on C and the helper's call / revive
## on V at every tier (tiers.md 3, t3-helpers.md 3). The card draws these slots and the keys use them: a letter is
## always the one on the unit's own button.
func train_slots() -> Array:
	var types: Array = trainable_types().duplicate()
	var keep := selected_building as Keep
	if keep != null and types.size() > 1 and TierSystem.instance() != null and keep.tier >= 3 \
			and not keep.is_upgrading():
		types.insert(1, null)   # Keep.tier_card_type() is null at the Citadel: keep its slot
	# caster-units.md 3.3: the keep's caster always sits on slot 5 (key B), whatever the slots before it hold.
	if keep != null:
		for i in types.size():
			if CasterKit.is_keep_caster(types[i]) and i < CASTER_KEEP_SLOT:
				var c: Variant = types[i]
				types.remove_at(i)
				while types.size() < CASTER_KEEP_SLOT:
					types.append(null)
				types.insert(CASTER_KEEP_SLOT, c)
				break
	if types.size() > SLOT_KEYS.size():
		types.resize(SLOT_KEYS.size())
	while not types.is_empty() and types.back() == null:
		types.pop_back()
	return types


## The hotkey letter of training slot `index` (0-7): Z X C V B N M , (QWERTY positions, CLAUDE.md "Keys").
## `type` is unused (kept for callers); the slot decides the key (see train_slots()).
func train_key(_type: Variant, index: int) -> String:
	return SLOT_LETTERS[index] if index >= 0 and index < SLOT_LETTERS.length() else ""


## The slot of unit type id `id` on the selected building's card (-1 when it is not there).
func train_slot_of(id: StringName) -> int:
	var slots := train_slots()
	for i in slots.size():
		if slots[i] != null and StringName(str((slots[i] as Object).get(&"id"))) == id:
			return i
	return -1


# ---------------------------------------------------------------- research pages (UR.U1, ui-sc2-console.md 7.1)

## True when the selected building is an own, living, completed Hall / Stables / keep with something to research (the
## card shows its "+" button at r3c5).
func can_open_upgrades() -> bool:
	var b := selected_building
	return b != null and _building_alive(b) and int(b.get(&"team")) == Unit.Team.PLAYER \
			and (not b.has_method(&"is_constructed") or bool(b.call(&"is_constructed"))) \
			and not research_units(b).is_empty()


## The card's "+" button / the + key: the command card shows the building's research page. Ends a pending rally order.
func open_upgrades() -> void:
	if not can_open_upgrades():
		return
	if _pending == ORDER_RALLY:
		cancel_targeting()
	upgrades_hall = selected_building
	research_unit = &""
	mode_changed.emit()


## + on a page (or Back on the research page): the building's training buttons again (both pages close).
func close_upgrades() -> void:
	if upgrades_hall == null and research_unit == &"":
		return
	upgrades_hall = null
	research_unit = &""
	mode_changed.emit()


## Esc / Back: the unit page goes back to the research page, the research page closes.
func research_back() -> void:
	if research_unit != &"" and upgrades_open():
		research_unit = &""
		mode_changed.emit()
	else:
		close_upgrades()


## True while a research page (or a unit page on top of it) of the selected building is open.
func upgrades_open() -> bool:
	return upgrades_hall != null and is_instance_valid(upgrades_hall) and upgrades_hall == selected_building \
			and _building_alive(upgrades_hall)


## The unit page shown now (&"" = none: the research page or no page).
func open_research_unit_id() -> StringName:
	return research_unit if upgrades_open() else &""


## True for the key that opens / closes the "+" page: physical =/+ or numpad +, or a layout's own + key.
static func is_upgrades_key(key: InputEventKey) -> bool:
	var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	return UPGRADES_KEYS.has(code) or key.keycode == KEY_PLUS


## The units of building `b` shown on its research page, in its card order: each has a "+" here (Hall), a research row
## (UnitResearch, skirmish games) or a Stables rank-3.
## Cached 0.5 s per building (the selection panel asks every frame; a keep's card can change with its tier).
static func research_units(b: Node) -> Array[StringName]:
	var out: Array[StringName] = []
	if b == null or not is_instance_valid(b) or not b.has_method(&"trainable_types"):
		return out
	var now := Time.get_ticks_msec()
	var hit: Variant = _research_units_cache.get(b.get_instance_id())
	if hit != null and now - int((hit as Array)[0]) < RESEARCH_UNITS_TTL_MS:
		return (hit as Array)[1]
	if _research_units_cache.size() > 64:
		_research_units_cache.clear()
	_research_units_cache[b.get_instance_id()] = [now, out]
	var plus := UnitUpgrades.ids_for_hall(b)
	var rows_on := UnitResearch.enabled_here()
	for t: Variant in b.call(&"trainable_types"):
		var ut := t as UnitType
		if ut == null or out.has(ut.id) or Stables16.is_rank_stub(ut):
			continue
		if plus.has(ut.id) or (rows_on and not UnitResearch.rows_for_unit(ut.id).is_empty()) or rank_here(b, ut.id):
			out.append(ut.id)
	return out


## True when `b` is a Stables that ranks `unit_id` up (stables.md 3).
static func rank_here(b: Node, unit_id: StringName) -> bool:
	if b == null or not is_instance_valid(b) or not Stables16.has_rank_up(unit_id) or not Stables16.enabled_here():
		return false
	var bt: Variant = b.get(&"building_type")
	return bt is BuildingType and (bt as BuildingType).kind == &"stables" \
			and (Stables16.ROSTER.get((bt as BuildingType).faction, []) as Array).has(unit_id)


## The unit page of `unit_id` at `b`, slot by slot (Z X C V B, max RESEARCH_PAGE_MAX): {} = empty slot, else
## {kind: &"plus" / &"row" / &"rank", id} (plus / rank: the unit id; row: the UnitResearch row id). Z = the "+".
static func research_entries(b: Node, unit_id: StringName) -> Array[Dictionary]:
	var out: Array[Dictionary] = [{}]
	if b == null or not is_instance_valid(b):
		return []
	if UnitUpgrades.ids_for_hall(b).has(unit_id):
		out[0] = {"kind": &"plus", "id": unit_id}
	if UnitResearch.enabled_here():
		for id in UnitResearch.rows_for_unit(unit_id):
			out.append({"kind": &"row", "id": id})
	if rank_here(b, unit_id):
		out.append({"kind": &"rank", "id": unit_id})
	if out.size() > RESEARCH_PAGE_MAX:
		out.resize(RESEARCH_PAGE_MAX)
	if out.size() == 1 and out[0].is_empty():
		return []
	return out


## Slot key `index` (Z X C V B N M ,) while a page is open. Research page: the unit trained with that key opens its
## page. Unit page: the entry of that slot (buy, or cancel when it runs). "" or the reason (also a message).
func press_research_slot(index: int) -> String:
	if not upgrades_open():
		return MSG_NO_UPGRADE
	var b := upgrades_hall
	if research_unit == &"":
		var slots := train_slots()
		if index < 0 or index >= slots.size() or slots[index] == null:
			return MSG_NO_UPGRADE
		var uid := StringName(str((slots[index] as Object).get(&"id")))
		if not research_units(b).has(uid):
			message.emit(MSG_NO_UPGRADE)
			return MSG_NO_UPGRADE
		open_research_unit(uid)
		return ""
	var entries := research_entries(b, research_unit)
	if index < 0 or index >= entries.size() or entries[index].is_empty():
		return MSG_NO_UPGRADE
	var e: Dictionary = entries[index]
	match StringName(e["kind"]):
		&"plus":
			return buy_upgrade(StringName(e["id"]))
		&"rank":
			return rank_up_research(StringName(e["id"]))
	return buy_research(StringName(e["id"]))


## Opens the page of unit `unit_id` (one of research_units) on the open research page.
func open_research_unit(unit_id: StringName) -> void:
	if not upgrades_open() or not research_units(upgrades_hall).has(unit_id):
		return
	research_unit = unit_id
	mode_changed.emit()


## The "+" page's slot `index` (the letter of the unit's training button): buys that unit's "+" at the building. Kept
## for callers of the old "+" page; the keys go through press_research_slot.
func buy_upgrade_slot(index: int) -> String:
	if not upgrades_open():
		return MSG_NO_UPGRADE
	var slots := train_slots()
	if index < 0 or index >= slots.size() or slots[index] == null:
		return MSG_NO_UPGRADE
	return buy_upgrade(StringName(str((slots[index] as Object).get(&"id"))))


## Buys the "+" of unit `unit_id` at the open page's Hall (UnitUpgrades.buy). "" or the reason (also a message).
func buy_upgrade(unit_id: StringName) -> String:
	var hall := _own_research_building()
	if hall == null or not UnitUpgrades.ids_for_hall(hall).has(unit_id):
		message.emit(MSG_NO_UPGRADE)
		return MSG_NO_UPGRADE
	var bank := UnitUpgrades.for_team(int(hall.get(&"team")))
	if bank == null:
		return MSG_NO_UPGRADE
	var reason := bank.buy(unit_id, hall)
	if reason != "":
		message.emit(reason)
	mode_changed.emit()   # the card shows the research at once
	return reason


## The building research acts on: the open page's, else the selected one; null unless it is a valid own building (the
## player never researches for another team, and no enemy research node is ever made from here).
func _own_research_building() -> Node3D:
	var b := upgrades_hall if upgrades_open() else selected_building
	if b == null or not is_instance_valid(b) or b.get(&"team") == null or int(b.get(&"team")) != Unit.Team.PLAYER:
		return null
	return b


## A research row of the open unit page: starts it at the page's building, or cancels it while it runs (full refund,
## message `Research cancelled: <name>`); a done row answers "Already researched". "" or the reason (also a message).
func buy_research(row_id: StringName) -> String:
	var b := _own_research_building()
	var bank := UnitResearch.for_team(Unit.Team.PLAYER) if b != null else null
	if bank == null or UnitResearch.row(row_id).is_empty():
		message.emit(MSG_NO_UPGRADE)
		return MSG_NO_UPGRADE
	if bank.is_working(row_id):
		bank.cancel(row_id)
		message.emit(Loc.t("Research cancelled: {name}", {"name": Loc.sink(str(UnitResearch.row(row_id)["name"]))}))
		mode_changed.emit()
		return ""
	var reason := bank.buy(row_id, b)
	if reason != "":
		message.emit(reason)
	mode_changed.emit()
	return reason


## The Stables rank-3 of `unit_id` on its unit page: starts it at the page's Stables, or cancels it while it runs.
func rank_up_research(unit_id: StringName) -> String:
	var b := _own_research_building()
	var ranks := Stables16.for_team(Unit.Team.PLAYER) if b != null else null
	if ranks == null:
		message.emit(MSG_NO_UPGRADE)
		return MSG_NO_UPGRADE
	if ranks.is_working(unit_id):
		ranks.cancel(unit_id)
		message.emit(Loc.t("Research cancelled: {name}", {"name": Loc.sink(Stables16.rank_name(unit_id))}))
		mode_changed.emit()
		return ""
	var reason := ranks.rank_up(unit_id, b)
	if reason != "":
		message.emit(reason)
	mode_changed.emit()
	return reason


## The research running at building `b` (its one slot: a unit row or its "+"): {kind: &"row" / &"plus", id, progress,
## left (s), name} or {} when idle. The building view's research chip and the card's "+" bar read it.
static func research_running_at(b: Node) -> Dictionary:
	if b == null or not is_instance_valid(b):
		return {}
	var t := int(b.get(&"team"))
	var bank := ResearchMarks.research_node(t)   # registry read: no group scan (asked every frame)
	if bank != null:
		var id := bank.working_at(b)
		if id != &"":
			var p := bank.progress(id)
			return {"kind": &"row", "id": id, "progress": p, "name": str(UnitResearch.row(id)["name"]),
					"left": float(UnitResearch.row(id)["time"]) * (1.0 - p)}
	var plus := ResearchMarks.plus_node(t)
	if plus != null:
		var uid := plus.working_at(b)
		if uid != &"":
			var p := plus.progress(uid)
			return {"kind": &"plus", "id": uid, "progress": p, "name": UnitUpgrades.display_name(uid),
					"left": UnitUpgrades.time_of(uid) * (1.0 - p)}
	return {}


## Cancels the research running at building `b` (the building view's research chip `x`): full refund. True if one ran.
func cancel_research_at(b: Node) -> bool:
	if b == null or not is_instance_valid(b) or int(b.get(&"team")) != Unit.Team.PLAYER:
		return false
	var r := research_running_at(b)
	if r.is_empty():
		return false
	var t := int(b.get(&"team"))
	if r["kind"] == &"row":
		UnitResearch.for_team(t, false).cancel(r["id"])
	else:
		UnitUpgrades.for_team(t, false).cancel(r["id"])
	message.emit(Loc.t("Research cancelled: {name}", {"name": Loc.sink(str(r["name"]))}))
	mode_changed.emit()
	return true


# ---------------------------------------------------------------- helper stances (t3-helpers.md 2.1)

## The own tier-3 helper being inspected (its card shows the 3 stances), or null.
func inspected_own_helper() -> Helper:
	if not is_inspecting() or not (inspected is Helper) or int(inspected.team) != Unit.Team.PLAYER:
		return null
	return inspected as Helper


## Z / X / C (or the card's stance buttons) with an own helper inspected: its stance. Not an order: the helper stays
## non-commandable. "" or the reason.
func set_helper_stance(stance: StringName) -> String:
	var h := inspected_own_helper()
	if h == null:
		return "No helper"
	var r := h.set_stance(stance)
	mode_changed.emit()   # the card highlights the new stance
	return r


## The control group of a number key (physical): KEY_1..KEY_9 = 1..9, KEY_0 = 10, else 0.
static func group_for_key(code: Key) -> int:
	if code >= KEY_1 and code <= KEY_9:
		return int(code - KEY_0)
	if code == KEY_0:
		return GROUP_COUNT
	return 0


## The key label of a group: "1".."9", "0" for group 10.
static func group_label(group: int) -> String:
	return "0" if group == GROUP_COUNT else str(group)


## Ctrl + number: the group becomes the current selection (units, or the selected building).
func set_control_group(group: int) -> void:
	if group < 1 or group > GROUP_COUNT or _only_uncommandable():
		return   # an inspected champion (or a flag) never becomes a group, and doesn't wipe one
	var members := _selection_members()
	if members.is_empty():
		return   # U1-4: Ctrl+N with nothing selected keeps the group
	_groups[group] = members
	_last_group_key = group
	_last_group_time = -10.0
	groups_changed.emit()


## Shift + number: add the current selection to the group.
func add_to_control_group(group: int) -> void:
	if group < 1 or group > GROUP_COUNT:
		return
	# start from the kept members (a dead wizard stays, U1-1), not only the living ones
	var members: Array = (_groups.get(group, []) as Array).filter(_member_kept)
	for m in _selection_members():
		if not members.has(m):
			members.append(m)
	_groups[group] = members
	_last_group_key = group
	_last_group_time = -10.0
	groups_changed.emit()


## Alt + number (steal): the selection leaves every other group, then becomes group N.
## Shift + Alt + number (`add` = true): same, but it is added to group N instead of replacing it.
func steal_to_control_group(group: int, add := false) -> void:
	if group < 1 or group > GROUP_COUNT or _only_uncommandable():
		return
	var members := _selection_members()
	if members.is_empty():
		return   # U1-4: Alt+N with nothing selected keeps every group
	for g in _groups.keys():
		if g == group:
			continue
		var list: Array = _groups[g]
		for m in members:
			list.erase(m)
	if add:
		add_to_control_group(group)
	else:
		set_control_group(group)


## Living members of a control group (units and buildings; dead ones leave the group).
func get_control_group(group: int) -> Array:
	var members: Array = []
	if _groups.has(group):
		for m in _groups[group]:
			if _member_alive(m):
				members.append(m)
		_groups[group] = (_groups[group] as Array).filter(_member_kept)
	return members


## The non-empty control groups, in key order 1-9 then 10 (key 0).
func control_groups() -> Array[int]:
	var out: Array[int] = []
	for g in range(1, GROUP_COUNT + 1):
		if not get_control_group(g).is_empty():
			out.append(g)
	return out


## The group whose members are exactly the current selection (the last used one first), or 0.
func active_control_group() -> int:
	var current := _selection_members()
	if current.is_empty():
		return 0
	var order: Array[int] = []
	if _last_group_key != 0:
		order.append(_last_group_key)
	for g in range(1, GROUP_COUNT + 1):
		if g != _last_group_key:
			order.append(g)
	for g in order:
		var members := _selectable_part(get_control_group(g))
		if members.size() == current.size() and members.all(func(m): return current.has(m)):
			return g
	return 0


## Number key: select the group; a second press within 0.4 s centres the camera on it.
## A group with units selects its units; a group of buildings selects all its buildings (Tab cycles the active one;
## a re-press keeps the active one).
func recall_control_group(group: int) -> void:
	var members := get_control_group(group)
	if members.is_empty():
		return
	var double_tap := _last_group_key == group and _clock - _last_group_time <= GROUP_DOUBLE_TAP
	_last_group_key = group
	_last_group_time = _clock
	var part := _selectable_part(members)
	if not part.is_empty() and not part.any(func(m): return m is Unit):
		select_buildings(part, selected_building)
	else:
		select_units(part)
	if double_tap:
		centre_camera_on(part)   # U1-6: what was selected (the army of a mixed group), not between army and base


## F2: every own living non-worker unit (the wizard included; never a champion). F2 twice within 0.4 s
## centres the camera on the army.
func select_army() -> void:
	var army := army_units()
	var double_tap := _clock - _last_army_time <= GROUP_DOUBLE_TAP
	_last_army_time = _clock
	select_units(army)
	if double_tap and not army.is_empty():
		centre_camera_on(army)


## Shift+F2: adds every army unit to the current selection (units stay; a building selection is replaced).
func add_army() -> void:
	var out: Array = orderable_units()
	for u in army_units():
		if not out.has(u):
			out.append(u)
	select_units(out)


## The player's living commandable non-worker units (F2's army).
func army_units() -> Array:
	var army: Array = []
	for node in get_tree().get_nodes_in_group("units"):
		var u := node as Unit
		if u and u.team == Unit.Team.PLAYER and u.is_alive() and not _is_worker(u) and is_commandable_unit(u) \
				and not u.is_in_group(&"caravans"):   # U1-2: caravans stay on their route
			army.append(u)
	return army


## Every own living commandable unit, workers and the wizard included (never a building or a champion).
func all_own_units() -> Array:
	var out: Array = []
	for node in get_tree().get_nodes_in_group("units"):
		var u := node as Unit
		if u and u.team == Unit.Team.PLAYER and u.is_alive() and is_commandable_unit(u):
			out.append(u)
	return out


## Ctrl+A: selects every own commandable unit; `add` (Ctrl+Shift+A) keeps the current units too.
func select_all_units(add := false) -> void:
	var out: Array = orderable_units() if add else []
	for u in all_own_units():
		if not out.has(u):
			out.append(u)
	select_units(out)


## Ctrl+F3 (or Ctrl+click the idle-worker button): selects every idle worker and centres on them.
func select_all_idle_workers() -> Array:
	var idle: Array = idle_workers()
	if idle.is_empty():
		message.emit("No idle workers")
		return []
	select_units(idle)
	centre_camera_on(idle)
	return idle


# ---------------------------------------------------------------- unit subgroups (SC2 style, Tab)

## The subgroup key of a unit: &"wizard" for wizards, else its UnitType id (else its name).
static func unit_type_key(u: Unit) -> StringName:
	if u is Wizard:
		return &"wizard"
	if u.unit_type != null and u.unit_type.id != &"":
		return u.unit_type.id
	return StringName(u.unit_name)


## Sort rank of a subgroup (lower = earlier in Tab order, active first): the saved Unit priority list
## (GameSettings.unit_priority()) when it names the type, else wizard, heroes, then dearer soldiers, workers last.
func unit_type_rank(u: Unit) -> int:
	var key := unit_type_key(u)
	var custom: Array = GameSettings.unit_priority()
	var i := custom.find(key)
	if i >= 0:
		return i - 100000
	if u is Wizard:
		return 0
	if u.is_in_group(&"heroes"):
		return 1
	if _is_worker(u):
		return 90000
	return 10000 - (u.unit_type.cost if u.unit_type != null else 0)


## The selected unit subgroups (type keys) in Tab order.
## Perf pass 2026-10-09: the HUD asks several times per frame (1+ ms with 150 units selected); the answer is cached
## and rebuilt when the selection changes (selection_changed, size, first / last unit), the unit priority setting
## changes, or at least every TYPES_CACHE_FRAMES frames.
func selected_unit_types() -> Array[StringName]:
	var key := [_types_version, selected.size(), GameSettings.unit_priority().hash(),
			selected[0].get_instance_id() if not selected.is_empty() and is_instance_valid(selected[0]) else 0,
			selected[-1].get_instance_id() if not selected.is_empty() and is_instance_valid(selected[-1]) else 0].hash()
	var frame := Engine.get_process_frames()
	if key == _types_key and frame - _types_frame < TYPES_CACHE_FRAMES:
		return _types_cache.duplicate()
	_types_key = key
	_types_frame = frame
	_types_cache = _selected_unit_types_uncached()
	return _types_cache.duplicate()


func _bump_types_version() -> void:
	_types_version += 1


func _selected_unit_types_uncached() -> Array[StringName]:
	var first := {}
	for u in orderable_units():
		var k := unit_type_key(u)
		if not first.has(k):
			first[k] = u
	var keys: Array = first.keys()
	keys.sort_custom(func(a, b) -> bool:
		var ra := unit_type_rank(first[a])
		var rb := unit_type_rank(first[b])
		return ra < rb if ra != rb else String(a) < String(b))
	var out: Array[StringName] = []
	for k in keys:
		out.append(k)
	return out


## The active subgroup: its abilities show on the command card, its portraits get the gold frame. &"" = none.
func active_unit_type() -> StringName:
	var types := selected_unit_types()
	if types.is_empty():
		return &""
	if not types.has(_active_unit_type):
		_active_unit_type = types[0]
	return _active_unit_type


## Tab / Shift+Tab with 2+ unit types selected: the next / previous subgroup becomes active.
func cycle_active_unit_type(step := 1) -> void:
	var types := selected_unit_types()
	if types.size() < 2:
		return
	var i := types.find(active_unit_type())
	_active_unit_type = types[posmod(i + step, types.size())]
	selection_changed.emit()


## The selected units of the active subgroup (all selected units when there is only one type).
func active_type_units() -> Array[Unit]:
	var key := active_unit_type()
	var out: Array[Unit] = []
	for u in orderable_units():
		if unit_type_key(u) == key:
			out.append(u)
	return out


## Own workers with nothing to do: not gathering, not building, no target, standing still.
func idle_workers() -> Array[Unit]:
	var out: Array[Unit] = []
	for node in get_tree().get_nodes_in_group("units"):
		var u := node as Unit
		if u == null or u.team != Unit.Team.PLAYER or not u.is_alive() or not _is_worker(u):
			continue
		if u.has_method("is_gathering") and bool(u.call("is_gathering")):
			continue
		if u.has_method("is_building") and bool(u.call("is_building")):
			continue
		if u.attack_target != null or Vector2(u.velocity.x, u.velocity.z).length() > IDLE_SPEED:
			continue
		out.append(u)
	out.sort_custom(func(a: Unit, b: Unit) -> bool: return a.get_instance_id() < b.get_instance_id())
	return out


## F3: selects the next idle worker (cycling on repeated presses) and centres the camera on it.
## Returns the worker, or null (with a message) if none is idle.
func select_idle_worker() -> Unit:
	var idle := idle_workers()
	if idle.is_empty():
		message.emit("No idle workers")
		return null
	var index := 0
	if _last_idle_worker != null and is_instance_valid(_last_idle_worker):
		var last := idle.find(_last_idle_worker)
		if last >= 0:
			index = (last + 1) % idle.size()
		else:
			# The previous one found a job: take the first idle one after it in the same order.
			for i in idle.size():
				if idle[i].get_instance_id() > _last_idle_worker.get_instance_id():
					index = i
					break
	var worker := idle[index]
	_last_idle_worker = worker
	select_units([worker])
	centre_camera_on([worker])
	return worker


## Moves the camera to the average position of `nodes`.
func centre_camera_on(nodes: Array) -> void:
	var center := Vector3.ZERO
	var n := 0
	for m in nodes:
		if is_instance_valid(m) and m is Node3D:
			center += (m as Node3D).global_position
			n += 1
	if n == 0:
		return
	center /= float(n)
	var rig := camera.get_parent() if camera else null
	if rig and rig.has_method("focus_on"):
		rig.call("focus_on", center)


## Confirms the pending targeted order at a world point (a left click on the minimap).
## Returns false when no order is pending.
func confirm_pending_at(point: Vector3) -> bool:
	if bounty_mode != null and bounty_mode.active:
		# Bounty mode + a minimap click: an Explore flag there (also on unexplored ground).
		bounty_mode.click_world(point, Input.is_key_pressed(KEY_SHIFT))
		return true
	if _pending == &"" or _pending == ORDER_BUILD:
		return false   # a placement is confirmed in the world only (the minimap click moves the camera)
	if _pending == ORDER_ROUTE:
		var route_post := post_near(point, MINIMAP_POST_RADIUS)
		if route_post == null:
			show_route_hint()   # the order stays pending
			return true
		cancel_targeting()
		set_market_route(route_post)
		return true
	var order := _pending
	var spell := _pending_spell
	var caster_spell := _pending_caster_spell
	var item_slot := _pending_item_slot
	cancel_targeting()
	if order == ORDER_ITEM:   # U1-5: a point item (Blink) used at the minimap point
		if item_slot >= 0:
			_use_item(item_slot, point)
		return true
	if caster_spell != &"":   # a minimap click: point spells cast there, unit spells need the 3D view
		if CasterKit.target_kind(caster_spell) == &"point":
			cast_caster_at(caster_spell, _with_bulwark_facing(caster_spell, point))
		else:
			message.emit("Pick a unit")
		return true
	if spell != &"":
		if SpellInfo.target_type(spell) == &"unit":
			message.emit("Pick a unit")
		else:
			_cast(spell, point)
		return true
	match order:
		ORDER_ATTACK_MOVE:
			if not orderable_units().is_empty():
				attack_move(point)
				_spawn_marker(point, Color(1.0, 0.45, 0.2))
		ORDER_MOVE:
			order_move(point)
		ORDER_GATHER:
			var post := post_near(point, MINIMAP_POST_RADIUS) if has_caravans() else null
			var node := crystal_node_near(point, NODE_CLICK_RADIUS)
			if post != null:
				trade_with(post)
			elif node != null:
				gather(node)
			elif has_caravans():
				order_move(point)
			else:
				message.emit("Click a crystal node")
		ORDER_RALLY:
			_set_rally(point, crystal_node_near(point, NODE_CLICK_RADIUS))
	return true


## Where the mouse ray hits the ground (y = 0). Returns null if it misses.
## If you add hills later, replace this with a physics raycast on layer 1.
func ground_point(screen_pos: Vector2) -> Variant:
	var from := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	return Plane(Vector3.UP, 0.0).intersects_ray(from, dir)


func unit_at(screen_pos: Vector2) -> Unit:
	var hit := _ray(screen_pos, 2)
	if hit and hit.collider is Unit and (hit.collider as Unit).is_alive() and not _is_hidden(hit.collider):
		return hit.collider   # U3-2: a unit the fog hides is never picked (bounty mode, inspect, orders)
	if hit and _in_group_upwards(hit.collider, "buildings") != null:
		return null   # the click landed on a building, not next to a unit
	# Forgiving fallback: nearest unit drawn within 28 pixels of the click.
	var best: Unit = null
	var best_d := 28.0
	for node in get_tree().get_nodes_in_group("units"):
		var u := node as Unit
		if u == null or _is_hidden(u):
			continue   # hidden by the fog: not clickable, not a target
		var world := u.global_position + Vector3.UP * u.body_height * 0.5
		if camera.is_position_behind(world):
			continue
		var d := camera.unproject_position(world).distance_to(screen_pos)
		if d < best_d:
			best_d = d
			best = u
	return best


## The building (group "buildings", collision layer 2) under the mouse, or null.
func building_at(screen_pos: Vector2) -> Node3D:
	var hit := _ray(screen_pos, 2)
	if hit:
		var b := _in_group_upwards(hit.collider, "buildings")
		if b != null and _building_alive(b):
			return b
	return null


## The crystal node under the mouse (its collider, or a ground click within 3 m of it), or null.
func crystal_node_at(screen_pos: Vector2) -> Node3D:
	var hit := _ray(screen_pos, 1)
	if hit:
		var n := _in_group_upwards(hit.collider, "crystal_nodes")
		if n != null:
			return n
	var p: Variant = ground_point(screen_pos)
	if p == null:
		return null
	return crystal_node_near(p, NODE_CLICK_RADIUS)


## The nearest crystal node within `max_distance` m (flat) of `point`, or null.
func crystal_node_near(point: Vector3, max_distance: float) -> Node3D:
	var best: Node3D = null
	var best_d := max_distance
	for node in get_tree().get_nodes_in_group("crystal_nodes"):
		var n := node as Node3D
		if n == null or not n.is_inside_tree() or _is_hidden(n):
			continue   # unexplored nodes are hidden by the fog
		var d := Vector2(n.global_position.x - point.x, n.global_position.z - point.z).length()
		if d <= best_d:
			best_d = d
			best = n
	return best


# ---------------------------------------------------------------- internals

## The first collider under `screen_pos` that is shown: things hidden by the fog of war
## (`visible == false`, they keep their collision) are skipped as if they were not there.
## `areas`: Area3Ds count too (the game critters' and the shrines' click areas, 12.C6).
func _ray(screen_pos: Vector2, mask: int, areas := false) -> Dictionary:
	var from := camera.project_ray_origin(screen_pos)
	var to := from + camera.project_ray_normal(screen_pos) * 500.0
	var query := PhysicsRayQueryParameters3D.create(from, to, mask)
	query.collide_with_areas = areas
	var space := camera.get_world_3d().direct_space_state
	var exclude: Array[RID] = []
	for i in 6:
		var hit := space.intersect_ray(query)
		if hit.is_empty() or not _is_hidden(hit.collider):
			return hit
		exclude.append(hit.rid)
		query.exclude = exclude
	return {}


## True for a node the fog of war hides from the player (it or a parent has `visible == false`).
func _is_hidden(node: Variant) -> bool:
	return is_instance_valid(node) and node is Node3D and not (node as Node3D).is_visible_in_tree()


## Placement rules plus the fog (buildings.md: `Unexplored` comes after the ground rules and before
## the cost rules): every footprint cell must be explored by the player. BuildGrid itself doesn't
## check the fog (the bot places blind), so the UI does it for the player only.
func _placement_reason(grid: BuildGrid, type: BuildingType, center: Vector3) -> String:
	var reason := grid.check(type, center, Unit.Team.PLAYER)
	if reason != "" and reason != BuildGrid.MSG_NO_CRYSTALS and reason != BuildGrid.limit_message(type):
		return reason
	if not footprint_explored(type, center):
		return BuildGrid.MSG_UNEXPLORED
	return reason


## True when every footprint cell of `type` centred at `center` is explored by the player (or no fog).
func footprint_explored(type: BuildingType, center: Vector3) -> bool:
	var fog := FogOfWar.find()
	if fog == null or not fog.enabled:
		return true
	var cell := BuildGhost.CELL
	for i in type.footprint.x:
		for j in type.footprint.y:
			var p := center + Vector3((float(i) - (type.footprint.x - 1) * 0.5) * cell, 0.0,
					(float(j) - (type.footprint.y - 1) * 0.5) * cell)
			if not fog.is_explored(Unit.Team.PLAYER, p):
				return false
	return true


func _in_group_upwards(node: Object, group: StringName) -> Node3D:
	var n := node as Node
	while n != null:
		if n.is_in_group(group):
			return n as Node3D
		n = n.get_parent()
	return null


## A flag still on the map (not freed, in the tree, not ended).
func _flag_alive(f: Node3D) -> bool:
	return f != null and is_instance_valid(f) and f.is_inside_tree() and not f.is_queued_for_deletion()


## The flag whose collider is the first thing under `screen_pos` (layer 2), or null.
func _flag_ray(screen_pos: Vector2) -> Node3D:
	if camera == null or get_tree().get_nodes_in_group(&"bounties").is_empty():
		return null
	var hit := _ray(screen_pos, 2)
	if hit:
		var f := _in_group_upwards(hit.collider, &"bounties")
		if f != null and _flag_alive(f):
			return f
	return null


func _building_alive(b: Node3D) -> bool:
	if not is_instance_valid(b) or not b.is_inside_tree():
		return false
	return not b.has_method("is_alive") or bool(b.call("is_alive"))


## An own, living construction site.
func _is_unfinished_site(b: Node3D) -> bool:
	return b != null and _building_alive(b) and int(b.get("team")) == Unit.Team.PLAYER \
			and b.has_method(&"is_constructed") and not bool(b.call(&"is_constructed"))


func _clear_building() -> void:
	if selected_building != null and is_instance_valid(selected_building) \
			and selected_building.has_method("set_selected"):
		selected_building.call("set_selected", false)
	for b in selected_buildings:
		if is_instance_valid(b) and b.has_method("set_selected"):
			b.call("set_selected", false)
	selected_buildings.clear()
	selected_building = null
	upgrades_hall = null


func _is_worker(u: Unit) -> bool:
	return is_worker_unit(u)


## A worker for the card and the orders: it gathers (command_gather) or its type is a worker. Public (the command card).
static func is_worker_unit(u: Unit) -> bool:
	return u.has_method("command_gather") or u.is_worker()


## What a control group key stores: the selected units (never a champion), or the selected building.
func _selection_members() -> Array:
	var out: Array = []
	if selected_building != null and _building_alive(selected_building):
		for b in selected_buildings:
			if _building_alive(b):
				out.append(b)
		if not out.has(selected_building):
			out.append(selected_building)
	else:
		out.append_array(orderable_units())
	return out


## True when something is shown (an inspected champion, a flag) but nothing in it could join a group.
func _only_uncommandable() -> bool:
	if selected_building != null:
		return false
	return selected_bounty != null or inspected != null or selected_neutral != null \
			or (not selected.is_empty() and orderable_units().is_empty())


## Ends the inspect view (the champion's selection ring goes off).
func _clear_inspect() -> void:
	if inspected != null and is_instance_valid(inspected):
		inspected.selected = false
	inspected = null


## Drops the selected post / guild house (its set_selected(false)).
func _clear_neutral() -> void:
	if selected_neutral != null and is_instance_valid(selected_neutral) and selected_neutral.has_method(&"set_selected"):
		selected_neutral.call(&"set_selected", false)
	selected_neutral = null


## The trading post / guild house under `screen_pos`: {"node": Node3D or null, "direct": bool}. `direct` = the first
## layer-2 collider under the mouse is it (a unit in front of it wins); otherwise a ground point within 3.5 m (per
## axis) of its centre, the 6 x 6 footprint (like the taverns).
func _neutral_hit(screen_pos: Vector2) -> Dictionary:
	var out := {"node": null, "direct": false}
	if camera == null or not camera.is_inside_tree():
		return out
	var tree := get_tree()
	if tree.get_first_node_in_group(&"trade_posts") == null and tree.get_first_node_in_group(&"guilds") == null:
		return out
	var hit := _ray(screen_pos, 2)
	if hit:
		var n := _in_group_upwards(hit.collider, &"trade_posts")
		if n == null:
			n = _in_group_upwards(hit.collider, &"guilds")
		if n != null:
			out["node"] = n
			out["direct"] = true
			return out
		if hit.collider is Unit:
			return out
	var p: Variant = ground_point(screen_pos)
	if p == null:
		return out
	var g := p as Vector3
	for group: StringName in [&"trade_posts", &"guilds"]:
		for node in tree.get_nodes_in_group(group):
			var b := node as Node3D
			if b == null or not b.is_inside_tree():
				continue
			var c := b.global_position
			if absf(g.x - c.x) <= POST_CLICK_RADIUS and absf(g.z - c.z) <= POST_CLICK_RADIUS:
				out["node"] = b
				return out
	return out


## A game critter that can be clicked / hunted now: in the tree, alive, shown (hidden = fogged or parked).
func _critter_ok(c: Variant) -> bool:
	if c == null or not is_instance_valid(c) or not c is Node3D:
		return false
	var n := c as Node3D
	if not n.is_inside_tree() or n.is_queued_for_deletion() or not n.has_method(&"is_game_critter"):
		return false
	return (not n.has_method(&"is_alive") or bool(n.call(&"is_alive"))) and n.is_visible_in_tree()


## Walks up from a collider (the "ClickArea") to the node with is_game_critter(), or null.
func _critter_of(collider: Variant) -> Node3D:
	var n := collider as Node
	while n != null:
		if n.has_method(&"is_game_critter"):
			return n as Node3D
		n = n.get_parent()
	return null


## The game critter under `screen_pos`: {"node": Node3D or null, "direct": bool}. `direct` = its click area is the first
## layer-2 thing (bodies and areas) under the mouse; otherwise, with nothing on layer 2 under the mouse, the visible
## critter drawn nearest within 18 px.
func _critter_hit(screen_pos: Vector2) -> Dictionary:
	var out := {"node": null, "direct": false}
	if camera == null or not camera.is_inside_tree():
		return out
	var tree := get_tree()
	if tree.get_first_node_in_group(&"game_critters") == null:
		return out
	var hit := _ray(screen_pos, 2, true)
	if hit:
		var c := _critter_of(hit.collider)
		if c != null and _critter_ok(c):
			out["node"] = c
			out["direct"] = true
		return out   # a critter, or something else in front of the mouse
	var best_d := CRITTER_CLICK_PX
	for node in tree.get_nodes_in_group(&"game_critters"):
		if not _critter_ok(node):
			continue
		var c := node as Node3D
		var world := c.global_position + Vector3.UP * 0.4
		if camera.is_position_behind(world):
			continue
		var d := camera.unproject_position(world).distance_to(screen_pos)
		if d < best_d:
			best_d = d
			out["node"] = c
	return out


## The capture point under `screen_pos`: {"node", "direct"} like _neutral_hit. `direct` = its body (tower / well) or
## click area (shrine) is the first layer-2 thing under the mouse; else a ground point within capture_radius x 0.5 of
## a watchtower / well centre (not when a unit or a critter is under the mouse).
func _point_hit(screen_pos: Vector2) -> Dictionary:
	var out := {"node": null, "direct": false}
	if camera == null or not camera.is_inside_tree():
		return out
	var tree := get_tree()
	if tree.get_first_node_in_group(&"capture_points") == null:
		return out
	var hit := _ray(screen_pos, 2, true)
	if hit:
		var n := _in_group_upwards(hit.collider, &"capture_points")
		if n != null:
			out["node"] = n
			out["direct"] = true
			return out
		if hit.collider is Unit or _critter_of(hit.collider) != null:
			return out
	var p: Variant = ground_point(screen_pos)
	if p == null:
		return out
	var g := p as Vector3
	var best_d := INF
	for node in tree.get_nodes_in_group(&"capture_points"):
		var pt := node as Node3D
		if pt == null or not pt.is_inside_tree():
			continue
		var kind := StringName(str(pt.get(&"kind")))
		if kind != &"watchtower" and kind != &"well":
			continue
		var radius := float(pt.get(&"capture_radius")) if pt.get(&"capture_radius") != null else 6.0
		var d := Vector2(g.x - pt.global_position.x, g.z - pt.global_position.z).length()
		if d <= radius * POINT_GROUND_FACTOR and d < best_d:
			best_d = d
			out["node"] = pt
	return out


## 20 Hz: the critter under the mouse while hunters are selected, no order is pending and bounty mode is off.
func _update_critter_hover() -> void:
	var c: Node3D = null
	if enabled and camera != null and _pending == &"" and not (bounty_mode != null and bounty_mode.active) \
			and not selected.is_empty() and get_tree().get_first_node_in_group(&"game_critters") != null \
			and not hunters().is_empty():
		c = critter_at(_mouse_pos)
	_set_hovered_critter(c)


## The hunt cursor: CURSOR_CROSS + the red ring under the critter; back to the arrow / no ring when it leaves (unless
## another targeting mode took the cursor meanwhile: it owns the cursor then).
func _set_hovered_critter(c: Node3D) -> void:
	hovered_critter = c
	if c != null:
		if not _critter_cursor:
			_critter_cursor = true
			Input.set_default_cursor_shape(Input.CURSOR_CROSS)
		var r := float(c.call(&"target_radius")) if c.has_method(&"target_radius") else 0.5
		show_bounty_ring(c.global_position, r + 0.3, HUNT_RING_COLOR)
		return
	if not _critter_cursor:
		return
	_critter_cursor = false
	var bounty_on := bounty_mode != null and bounty_mode.active
	if _pending == &"" and not bounty_on:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		hide_bounty_ring()
	elif not bounty_on and _pending_spell == &"" and _pending != ORDER_ITEM and _target_ring != null:
		_target_ring.visible = false   # an order without its own ring started: drop the hunt ring


## True while the hunt cursor (cross + red ring over a critter) is up.
func is_hunt_cursor() -> bool:
	return _critter_cursor


## Ends bounty mode when another targeted order starts.
func _end_bounty_mode() -> void:
	if bounty_mode != null and bounty_mode.active:
		bounty_mode.exit()


## The part of a group that can be selected at once: its units, or else all its buildings.
func _selectable_part(members: Array) -> Array:
	var units: Array = members.filter(func(m): return m is Unit and is_commandable_unit(m))
	if not units.is_empty():
		return units
	return members.filter(func(m): return not m is Unit)


func _member_alive(m: Variant) -> bool:
	if m == null or not is_instance_valid(m):
		return false
	if m is Unit:
		return (m as Unit).is_alive()
	return m is Node3D and _building_alive(m)


## U1-1: a dead hero (the player's wizard) stays in her groups: she respawns as the same node.
func _member_kept(m: Variant) -> bool:
	if _member_alive(m):
		return true
	return m != null and is_instance_valid(m) and m is Wizard \
			and not (m as Unit).is_queued_for_deletion()


## Dead units and destroyed buildings leave their groups (tabs update through groups_changed); a dead hero stays.
func _prune_groups() -> void:
	var changed := false
	for g in _groups.keys():
		var list: Array = _groups[g]
		for m in list:
			if not _member_kept(m):
				_groups[g] = list.filter(_member_kept)
				changed = true
				break
	if changed:
		groups_changed.emit()


## The trainable type of the slot whose key (Z X C V B N M , physical) is `code`, or null (see train_slots()).
func _type_for_key(code: Key) -> Variant:
	var slot := SLOT_KEYS.find(code)
	var types := train_slots()
	if slot < 0 or slot >= types.size():
		return null
	return types[slot]


## The buildable type whose hotkey_label (Z / X / C, physical) is `code`, or null.
func _build_type_for_key(code: Key) -> BuildingType:
	for t in buildable_types():
		if t.hotkey_label != "" and OS.find_keycode_from_string(t.hotkey_label) == code:
			return t
	return null


## The faction of the selected workers, else the player's wizard's kingdom ("fire" when unknown).
func _player_faction() -> StringName:
	for u in selected:
		if u.unit_type != null and u.unit_type.faction != &"":
			return u.unit_type.faction
	return GameHUD.kingdom_of(hero)


## The level's BuildGrid (main.build_grid), or null.
func _build_grid() -> BuildGrid:
	if _grid != null and is_instance_valid(_grid):
		return _grid
	for level in [get_parent(), get_tree().current_scene]:
		if level != null and "build_grid" in level:
			_grid = level.get("build_grid") as BuildGrid
			if _grid != null:
				return _grid
	return null


## Moves the ghost under `screen_pos` (snapped), colours it and shows the refusal message above it.
func _update_ghost(screen_pos: Vector2) -> void:
	var grid := _build_grid()
	var p: Variant = ground_point(screen_pos) if camera else null
	if grid == null or placing_type == null or p == null:
		_ghost.visible = false
		_ghost_label.visible = false
		_ghost_center = Vector3.INF
		return
	_ghost_center = grid.snap(p, placing_type.footprint)
	_ghost_reason = _placement_reason(grid, placing_type, _ghost_center)
	_ghost.visible = true
	_ghost.global_position = _ghost_center
	_ghost.set_valid(_ghost_reason == "")
	var top := _ghost_center + Vector3.UP * (_ghost.top_height() + 0.6)
	if _ghost_reason == "" or camera.is_position_behind(top):
		_ghost_label.visible = false
		return
	_ghost_label.text = _ghost_reason
	_ghost_label.reset_size()
	var screen := camera.unproject_position(top)
	_ghost_label.position = screen - Vector2(_ghost_label.size.x * 0.5, _ghost_label.size.y)
	_ghost_label.visible = true


func _click_select(pos: Vector2, add: bool, double: bool) -> void:
	# A flag's own collider first (it may stand on its hunted target).
	var flag := _flag_ray(pos)
	if flag != null:
		if not add:
			select_flag(flag)
		return
	# A game critter whose click area is the first thing under the mouse (12.C6): its read-only card.
	var ch := _critter_hit(pos)
	if ch.get("node") != null and bool(ch.get("direct")):
		if not add:
			select_neutral(ch.get("node"))
		return
	var building := building_at(pos)
	if building != null:
		if building.get("team") == Unit.Team.PLAYER:
			if double:
				select_buildings(_own_buildings_on_screen(building.get("building_type")), building)
			elif add and selected_building != null:
				# Shift+click with buildings selected: toggle this one in the building selection.
				var list: Array = selected_buildings.duplicate()
				if list.has(building):
					list.erase(building)
				else:
					list.append(building)
				if list.is_empty():
					select_units([])
				else:
					select_buildings(list, building if list.has(building) else selected_building)
			else:
				select_building(building)
		elif not add:
			select_units([])
		return
	var u := unit_at(pos)
	# A trading post / guild house (its own collider first; a unit standing in front of it wins).
	var nh := _neutral_hit(pos)
	if nh.get("node") != null and (bool(nh.get("direct")) or u == null):
		if not add:
			select_neutral(nh.get("node"))
		return
	# A capture point (its body / click area first; a unit standing in front of it wins) (12.C6).
	var ph := _point_hit(pos)
	if ph.get("node") != null and (bool(ph.get("direct")) or u == null):
		if not add:
			select_neutral(ph.get("node"))
		return
	# A critter drawn next to the click with nothing else under the mouse.
	if u == null and ch.get("node") != null:
		if not add:
			select_neutral(ch.get("node"))
		return
	if u != null and not is_commandable_unit(u):
		# A champion (own, or an enemy one in sight): read-only inspect. Shift+click leaves the selection alone.
		if not add:
			inspect_unit(u)
		return
	if u != null and u.team != Unit.Team.PLAYER and u.is_alive():
		# A visible enemy / neutral unit (a Magpie, an enemy caravan): read-only inspect, never ordered.
		if not add:
			inspect_unit(u)
		return
	if u == null or u.team != Unit.Team.PLAYER:
		var near_flag := flag_at(pos) if u == null else null
		if near_flag != null:
			if not add:
				select_flag(near_flag)
			return
		if not add:
			select_units([])
		return
	if double:
		var same: Array = []
		var screen := _box_ui.get_viewport_rect()
		for node in get_tree().get_nodes_in_group("units"):
			var other := node as Unit
			if other != null and other.team == Unit.Team.PLAYER and other.unit_name == u.unit_name \
					and is_commandable_unit(other) \
					and not camera.is_position_behind(other.global_position) \
					and screen.has_point(camera.unproject_position(other.global_position)):
				same.append(other)
		select_units(same)
	elif add:
		var list: Array = orderable_units().duplicate()
		if list.has(u):
			list.erase(u)
		else:
			list.append(u)
		select_units(list)
	else:
		select_units([u])


func _box_select(add: bool) -> void:
	var rect := Rect2(_drag_start, _drag_now - _drag_start).abs()
	var list: Array = orderable_units().duplicate() if add else []
	for node in get_tree().get_nodes_in_group("units"):
		var u := node as Unit
		if u == null or u.team != Unit.Team.PLAYER or not is_commandable_unit(u):
			continue   # champions never join a box selection
		var world := u.global_position + Vector3.UP * u.body_height * 0.5
		if camera.is_position_behind(world):
			continue
		if rect.has_point(camera.unproject_position(world)):
			list.append(u)
	if list.is_empty():
		# No unit in the box: own buildings in it are selected (units always win a box). Shift adds to the buildings.
		var found: Array = selected_buildings.duplicate() if add else []
		for b in _own_buildings_on_screen(null, rect):
			if not found.has(b):
				found.append(b)
		if not found.is_empty():
			select_buildings(found, selected_building)
			return
	if list.is_empty() and selected_building != null:
		return   # an empty drag keeps the keep selected
	select_units(list)


## Own living buildings whose centre is on screen (inside `rect` when given; of `type` when not null).
func _own_buildings_on_screen(type: Variant = null, rect := Rect2()) -> Array:
	var out: Array = []
	if camera == null:
		return out
	var screen := _box_ui.get_viewport_rect()
	for node in get_tree().get_nodes_in_group("buildings"):
		var b := node as Node3D
		if b == null or not _building_alive(b) or b.get("team") != Unit.Team.PLAYER:
			continue
		if type != null and b.get("building_type") != type:
			continue
		var world := b.global_position + Vector3.UP * 1.0
		if camera.is_position_behind(world):
			continue
		var p := camera.unproject_position(world)
		if (rect.has_area() and rect.has_point(p)) or (not rect.has_area() and screen.has_point(p)):
			out.append(b)
	return out


func _issue_order(pos: Vector2) -> void:
	var units := orderable_units()
	if units.is_empty():
		return   # nothing selected, or only an inspected champion: champions are never ordered
	_pickup_target = null
	if has_hero():
		var pickup := item_pickup_at(pos)
		if pickup != null:
			order_move(pickup.global_position)
			pick_up_item(pickup)
			return
	# Trading posts (10.C7): caravans trade there, the others walk to the door. The post's own collider wins over
	# a unit behind it; a ground click on the footprint only when no enemy unit is under the mouse.
	var nh := _neutral_hit(pos)
	var post: Node3D = nh.get("node")
	if post != null and not post.is_in_group(&"trade_posts"):
		post = null
	if post != null and bool(nh.get("direct")):
		trade_with(post)
		return
	var target := unit_at(pos)
	# A visible game critter (12.C6): the hunters attack it, the others move to the ground under it.
	var ch := _critter_hit(pos)
	if ch.get("node") != null and (bool(ch.get("direct")) or target == null):
		hunt_critter(ch.get("node"), ground_point(pos), false)
		return
	if target != null and Teams.is_hostile(int(target.team), Unit.Team.PLAYER):
		_REPLAY.note(&"attack_unit", [target], self)
		for u in units:
			if is_caravan(u):
				u.command_move(target.global_position)   # caravans never fight: a move next to it
			else:
				u.command_attack(target)
		_spawn_marker(target.global_position, Color(1.0, 0.25, 0.2))
		return
	var building := building_at(pos)
	if building != null:
		if Teams.is_hostile(int(building.get("team")), Unit.Team.PLAYER):
			attack_building(building)
			return
		if _is_unfinished_site(building) and not selected_workers().is_empty():
			build_site(building)
			return
		if has_caravans() and _is_own_market(building):
			trade_with(building)   # caravans go home and deliver
			return
	if post != null:
		trade_with(post)
		return
	if has_gatherers():
		var node := crystal_node_at(pos)
		if node != null:
			gather(node)
			return
	var p: Variant = ground_point(pos)
	if p == null:
		return
	order_move(p)


## Right click with the own Bazaar selected: a trading post = its route, anything else = the hint (no rally).
func _market_right_click(pos: Vector2) -> void:
	var post := post_at(pos)
	if post != null:
		set_market_route(post)
	else:
		show_route_hint()


## An own, completed, living Bazaar (group "markets").
func _is_own_market(b: Node3D) -> bool:
	return b != null and _building_alive(b) and b.is_in_group(&"markets") and b.get("team") != null \
			and int(b.get("team")) == Unit.Team.PLAYER \
			and (not b.has_method(&"is_constructed") or bool(b.call(&"is_constructed")))


## G then a left click: a trading post = caravans trade there (workers walk next to it), the own Bazaar = caravans
## go home, a crystal node = workers gather (the others walk next to it), the ground = a plain move when caravans
## are selected, else "Click a crystal node".
func _confirm_gather(pos: Vector2) -> void:
	var caravans := has_caravans()
	if caravans:
		var post := post_at(pos)
		if post != null:
			trade_with(post)
			return
		var b := building_at(pos)
		if b != null and _is_own_market(b):
			trade_with(b)
			return
	var node := crystal_node_at(pos)
	if node != null:
		gather(node)
		return
	if caravans:
		var p: Variant = ground_point(pos)
		if p != null:
			order_move(p)
		return
	message.emit("Click a crystal node")


## Right click / Set Rally + left click with a building selected: rally on a crystal node or on the ground.
func _rally_order(pos: Vector2) -> void:
	var node := crystal_node_at(pos)
	var p: Variant = ground_point(pos)
	if node == null and p == null:
		return
	_set_rally(p if p != null else node.global_position, node)


func _set_rally(point: Vector3, node: Node3D) -> void:
	var b := selected_building
	if b == null:
		return
	_REPLAY.note(&"rally", [point, node], self)
	# Several selected buildings: every other selected trainer (not a Bazaar: right click is its route) rallies too.
	var others: Array[Node3D] = []
	for o in selected_buildings:
		if o != b and _building_alive(o) and not CommandCard.is_market(o):
			others.append(o)
	if node != null and b.has_method("set_rally_node"):
		b.call("set_rally_node", node)
		for o in others:
			if o.has_method("set_rally_node"):
				o.call("set_rally_node", node)
		_spawn_marker(node.global_position, Color(0.45, 0.85, 1.0))
	elif b.has_method("set_rally_point"):
		b.call("set_rally_point", point)
		for o in others:
			if o.has_method("set_rally_point"):
				o.call("set_rally_point", point)
		_spawn_marker(point, Color(1.0, 0.85, 0.4))


## Moves the selected units to `center` in a square formation.
func formation_move(center: Vector3) -> void:
	_REPLAY.note(&"formation_move", [center], self)
	var units := orderable_units()
	var offsets := _formation_offsets(units.size())
	for i in units.size():
		units[i].command_move(center + offsets[i])


func _formation_offsets(n: int) -> Array[Vector3]:
	var offsets: Array[Vector3] = []
	if n == 0:
		return offsets
	var cols := int(ceil(sqrt(float(n))))
	var rows := int(ceil(float(n) / cols))
	for i in n:
		var row := floori(float(i) / cols)
		var col := i % cols
		offsets.append(Vector3((col - (cols - 1) * 0.5) * FORMATION_SPACING, 0.0,
				(row - (rows - 1) * 0.5) * FORMATION_SPACING))
	return offsets


func _confirm_pending(pos: Vector2) -> void:
	if _pending == ORDER_ROUTE:
		# Set Route: a left click on a post sets it; anything else keeps the order pending with the hint.
		var route_post := post_at(pos)
		if route_post == null:
			show_route_hint()
			return
		cancel_targeting()
		set_market_route(route_post)
		return
	var order := _pending
	var spell := _pending_spell
	var item_slot := _pending_item_slot
	var caster_spell := _pending_caster_spell
	cancel_targeting()
	if caster_spell != &"":
		_confirm_caster_spell(caster_spell, pos, Input.is_key_pressed(KEY_SHIFT))
		return
	if spell != &"":
		_confirm_spell(spell, pos)
		return
	match order:
		ORDER_ITEM:
			var ip: Variant = ground_point(pos)
			if ip != null:
				_use_item(item_slot, ip)
		ORDER_ATTACK_MOVE:
			_confirm_attack_move(pos)
		ORDER_MOVE:
			var p: Variant = ground_point(pos)
			if p != null:
				order_move(p)
		ORDER_GATHER:
			_confirm_gather(pos)
		ORDER_RALLY:
			_rally_order(pos)


## A (Classic) / X then left click: on an enemy or neutral unit = plain attack, on an enemy building = attack it,
## on one of your own units = attack-move to where it stands (no friendly fire), on the ground = attack-move.
func _confirm_attack_move(pos: Vector2) -> void:
	var units := orderable_units()
	if units.is_empty():
		return
	var target := unit_at(pos)
	# A visible game critter (12.C6): the hunters attack it, the others attack-move to the ground under it.
	var ch := _critter_hit(pos)
	if ch.get("node") != null and (bool(ch.get("direct")) or target == null):
		hunt_critter(ch.get("node"), ground_point(pos), true)
		return
	if target != null and target.team == Unit.Team.PLAYER and target.is_alive():
		var at := Vector3(target.global_position.x, 0.0, target.global_position.z)
		attack_move(at)
		_spawn_marker(at, Color(1.0, 0.45, 0.2))
		return
	if target != null and Teams.is_hostile(int(target.team), Unit.Team.PLAYER):
		_REPLAY.note(&"attack_unit", [target], self)
		for u in units:
			if is_caravan(u):
				u.command_move(target.global_position)
			else:
				u.command_attack(target)
		_spawn_marker(target.global_position, Color(1.0, 0.25, 0.2))
		return
	var building := building_at(pos)
	if building != null and Teams.is_hostile(int(building.get("team")), Unit.Team.PLAYER):
		attack_building(building)
		return
	var p: Variant = ground_point(pos)
	if p == null:
		return
	attack_move(p)
	_spawn_marker(p, Color(1.0, 0.45, 0.2))


## Left click while aiming a spell: a unit spell needs a unit under the cursor, the others a ground point.
func _confirm_spell(spell: StringName, pos: Vector2) -> void:
	if SpellInfo.target_type(spell) == &"unit":
		var target := unit_at(pos)
		if target == null:
			message.emit("Pick a unit")
			return
		_cast(spell, target)
		return
	var p: Variant = ground_point(pos)
	if p != null:
		_cast(spell, p)


func _spawn_marker(pos: Vector3, color: Color) -> void:
	var marker := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.5
	torus.outer_radius = 0.7
	marker.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	marker.material_override = mat
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(marker)
	marker.global_position = pos + Vector3.UP * 0.08
	marker.scale = Vector3(1.4, 0.1, 1.4)
	var tween := marker.create_tween().set_parallel(true)
	tween.tween_property(marker, "scale", Vector3(0.3, 0.1, 0.3), 0.5)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.5)
	tween.chain().tween_callback(marker.queue_free)


func _draw_box() -> void:
	if not _dragging:
		return
	var rect := Rect2(_drag_start, _drag_now - _drag_start).abs()
	_box_ui.draw_rect(rect, Color(0.3, 1.0, 0.4, 0.12), true)
	_box_ui.draw_rect(rect, Color(0.3, 1.0, 0.4, 0.9), false, 1.5)
