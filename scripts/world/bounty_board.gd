class_name BountyBoard
extends Node
## The bounty flags of one team (docs/design/champions.md sections 6-7, contract in section 13).
## One node per team in group "bounty_boards". Get it with `BountyBoard.for_team(team)`: it is
## **created on demand** under the current scene the first time (like EssenceBank), so the skirmish,
## the UI and the bot never have to create it; a level may also add one itself (set `team` first).
##
## Stakes are taken from the team's EssenceBank when a flag is placed or raised and paid from the
## stake into champions' purses (`add_purse(n)`, plus `add_xp(n / 2)`: bounty XP = half the payment).
## Champions are found through group "champions" (`team`, `is_alive()`, `display_name`); the roster
## (for "No champions") through the team's ChampionGuild (group "champion_guilds", `champions`) or,
## without one, every node of group "champions" of the team.
##
## Rules (section 6):
## - HUNT: paid when the target dies to the contributors, split equally: own living champions that
##   damaged it in the last 10 s (Unit.damage_taken / Building.damaged with the champion as attacker)
##   or pursuers within 12 m of it when it died. No contributor = 100 % refund. A HUNT unit target
##   unseen by the team for 60 s = 100 % refund (the flag waits on its last seen spot). Buildings do
##   not move and stay known as ghosts, so a building target never expires that way.
## - EXPLORE: the first own champion within 4 m of the point gets the whole stake. Never expires.
## - GUARD / ESCORT: every 10 s after placement, `stake / 9` (cumulative rounding, so 9 ticks pay the
##   exact stake) is split among own champions within 14 m of the building / 10 m of the unit; a tick
##   with nobody there is kept for later. Done after 9 paid ticks; at 180 s, or when the target dies,
##   the unpaid rest is refunded.
## Map fill (map-fill.md 6, 2.4; capture points reached through the group "capture_points": `owner_team`,
## `capture_radius`, signal `owner_changed(point, new_team, old_team)`; the river through the group "river"):
## - GUARD may target an own-held capture point: same service ticks (champions within 14 m); when the point
##   changes owner the flag ends (`&"owner_changed"`) and the unpaid rest is refunded.
## - CLAIM: an EXPLORE placed within 7 m of a point the team does not hold (`Bounty.is_claim()`). Arrival pays
##   nothing; when the point becomes held by the team, the stake is split among own living champions inside
##   its capture circle (+1 m) or pursuing within 12 m of it; nobody = 100 % refund. Never expires.
## - EXPLORE on deep water is refused "Invalid target".
## Messages go to `message` (always) and to the HUD (`current_scene.hud.show_message`) when this is
## the local team's board and `show_on_hud` is true.

signal bounty_placed(bounty: Bounty)
## Also emitted when a place() on an already flagged target raised it instead.
signal bounty_raised(bounty: Bounty, amount: int)
signal bounty_paid(bounty: Bounty, champion: Node3D, amount: int)
## reason: &"paid", &"no_contributor", &"expired", &"target_died", &"target_gone", &"removed",
## &"owner_changed" (GUARD on a capture point that changed owner).
signal bounty_ended(bounty: Bounty, reason: StringName)
## A message line for this team (payments, refunds, warnings about hunts on its things).
signal message(text: String)

const MAX_BOUNTIES := 5
const MAX_STAKE := 500
const RAISE_STEP := 25                 ## Z (and place() on an already flagged target).
const RAISE_STEP_BIG := 100            ## Shift+Z; a HUNT raise of this much warns the victim again.
const MIN_STAKES: Array[int] = [75, 25, 50, 50]   ## By kind: HUNT, EXPLORE, GUARD, ESCORT.
const EXPLORE_MERGE_RADIUS := 8.0      ## A new Explore flag this close to another one raises it.
const EXPLORE_CLAIM_RADIUS := 4.0
const HUNT_CONTRIBUTION_WINDOW := 10.0
const HUNT_PURSUE_RADIUS := 12.0
const HUNT_UNSEEN_EXPIRY := 60.0
const SERVICE_TICK := 10.0
const SERVICE_TICKS := 9
const GUARD_RADIUS := 14.0
const ESCORT_RADIUS := 10.0
const SERVICE_EXPIRY := 180.0
const CHECK_EVERY := 0.25              ## Seconds between rule checks (deaths are handled at once).
const MESSAGE_SECONDS := 3.0
const CLAIM_RADIUS := 7.0              ## An Explore this close to a not-own-held capture point is a Claim.
const CLAIM_CIRCLE_SLACK := 1.0        ## Claim pay: champions within capture_radius + this of the point.
const POINT_GROUP := &"capture_points"

@export var team: int = 0
## Show this board's messages on the HUD when it is the local team's board. The UI may set it false
## and show `message` itself.
var show_on_hud := true
## Active bounties, oldest first (ended ones leave the array at once).
var bounties: Array[Bounty] = []

var _clock := 0.0
var _check_acc := 0.0
var _watch: Dictionary = {}            # Bounty instance id -> Array of [Object, StringName, Callable]


## The board of `for_team_id`, created under the current scene the first time.
static func for_team(for_team_id: int) -> BountyBoard:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	for node in tree.get_nodes_in_group("bounty_boards"):
		var board := node as BountyBoard
		if board and board.team == for_team_id and not board.is_queued_for_deletion():
			return board
	var parent: Node = tree.current_scene if tree.current_scene else tree.root
	var created := BountyBoard.new()
	created.team = for_team_id
	created.name = "BountyBoard%d" % for_team_id
	created.add_to_group("bounty_boards")   # before add_child, so a second call finds it at once
	if parent.is_inside_tree() and not parent.is_node_ready():
		parent.add_child.call_deferred(created)
	else:
		parent.add_child(created)
	return created


## HUNT bounties of every board whose target belongs to `victim_team`.
static func all_hunts_on(victim_team: int) -> Array:
	var out: Array = []
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return out
	for node in tree.get_nodes_in_group("bounty_boards"):
		var board := node as BountyBoard
		if board:
			out.append_array(board.hunts_on(victim_team))
	return out


## Kingdom colour of a team's pennants (the level's player_kingdom / enemy_kingdom, else Fire /
## Shadow; neutral: its ring colour).
static func team_color(t: int) -> Color:
	var kingdom: StringName = &""
	var tree := Engine.get_main_loop() as SceneTree
	var scene: Node = tree.current_scene if tree else null
	var key := &"player_kingdom" if t == Unit.Team.PLAYER else &"enemy_kingdom"
	if scene and t != Unit.Team.NEUTRAL and key in scene:
		kingdom = StringName(str(scene.get(key)))
	if kingdom == &"" and t != Unit.Team.NEUTRAL:
		kingdom = &"fire" if t == Unit.Team.PLAYER else &"shadow"
	return Unit.KINGDOM_COLORS.get(kingdom, Unit.team_color(t))


## Short display name of a unit, champion, wizard or building ("Vessa", "Sable Quint", "Ember Hall").
static func name_of(node: Node) -> String:
	if node == null or not is_instance_valid(node):
		return ""
	var dn: Variant = node.get(&"display_name")
	if dn != null and str(dn) != "":
		return str(dn)
	var b := node as Building
	if b:
		return b.building_type.display_name if b.building_type and b.building_type.display_name != "" \
				else String(b.name)
	var un: Variant = node.get(&"unit_name")
	if un != null:
		return str(un).get_slice(",", 0).strip_edges()
	return String(node.name)


## True for things called by their own name (wizards, champions): "on Vessa", not "on your Shade".
static func is_named(node: Node) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	return node is Wizard or node.is_in_group(&"champions") or node.is_in_group(&"heroes") \
			or node.is_in_group(&"enemy_heroes")


func _ready() -> void:
	add_to_group("bounty_boards")


func _physics_process(delta: float) -> void:
	_clock += delta
	for b in bounties:
		b.elapsed += delta
	_check_acc += delta
	if _check_acc < CHECK_EVERY:
		return
	var dt := _check_acc
	_check_acc = 0.0
	_step(dt)


# ---------------------------------------------------------------- public API

## The kind of flag R would place on `target`: null / ground / props = EXPLORE, an enemy or neutral
## unit or an enemy building = HUNT, an own building = GUARD, an own unit = ESCORT; -1 = nothing can
## be placed there (own champion, neutral building, tavern). A capture point: GUARD when this team
## holds it, else EXPLORE (placed at the click, within 7 m of it: a Claim).
func kind_for(target: Node3D) -> int:
	if target == null or not is_instance_valid(target):
		return Bounty.EXPLORE
	if target.is_in_group(&"taverns"):
		return -1
	if is_point(target):
		return Bounty.GUARD if point_owner(target) == team else Bounty.EXPLORE
	var t: Variant = target.get(&"team")
	if t == null:
		return Bounty.EXPLORE
	if target is Unit:
		if int(t) != team:
			return Bounty.HUNT
		return -1 if target.is_in_group(&"champions") else Bounty.ESCORT
	if target is Building:
		if int(t) == team:
			return Bounty.GUARD
		return Bounty.HUNT if int(t) != Unit.Team.NEUTRAL else -1
	return Bounty.EXPLORE


## Smallest stake of a kind (75 / 25 / 50 / 50).
func min_stake(kind: int) -> int:
	return MIN_STAKES[kind] if kind >= 0 and kind < MIN_STAKES.size() else 0


## Places a flag of `kind` on `target` (EXPLORE: the ground point `pos`, target ignored). `stake`
## <= 0 = the minimum; it is clamped to [min, 500]. If `target` already carries one of our flags (or
## an Explore point is within 8 m of our Explore flag) that flag is raised instead, by `stake` or
## RAISE_STEP. Returns "" or, in order: "No champions", "Too many bounties", "Invalid target",
## "Not enough essence" (a raise may also return "Max bounty").
func place(kind: int, target: Node3D, pos: Vector3, stake: int = 0) -> String:
	if roster_size() == 0:
		return "No champions"
	var existing := _existing_for(kind, target, pos)
	if existing:
		return raise(existing, stake if stake > 0 else RAISE_STEP)
	if bounties.size() >= MAX_BOUNTIES:
		return "Too many bounties"
	if not _target_ok(kind, target, pos):
		return "Invalid target"
	var amount := clampi(maxi(stake, min_stake(kind)), min_stake(kind), MAX_STAKE)
	var bank := EssenceBank.for_team(team)
	if bank == null or not bank.spend(amount):
		return "Not enough essence"
	var b := Bounty.new()
	var at := pos
	var claim: Node3D = null
	if kind != Bounty.EXPLORE:
		at = target.global_position
	else:
		target = null
		claim = claim_point_near(pos)
	b.setup(team, kind, target, amount, at)
	b.claim_point = claim
	b.name = "Bounty_%s" % Bounty.KIND_NAMES[kind]
	add_child(b, true)
	bounties.append(b)
	_watch_bounty(b)
	bounty_placed.emit(b)
	if kind == Bounty.HUNT:
		_warn_hunted(b)
	return ""


## What place(kind, target, pos) would answer now, without placing or spending ("" = it would place or
## raise). Same order: "No champions", "Too many bounties", "Invalid target", "Not enough essence" (a raise:
## "Max bounty" / "Not enough essence"). The bounty mode UI reads it for its preview.
func can_place(kind: int, target: Node3D, pos: Vector3) -> String:
	if roster_size() == 0:
		return "No champions"
	var existing := _existing_for(kind, target, pos)
	if existing:
		return can_raise(existing, RAISE_STEP)
	if bounties.size() >= MAX_BOUNTIES:
		return "Too many bounties"
	if kind < 0 or not _target_ok(kind, target, pos):
		return "Invalid target"
	var bank := EssenceBank.for_team(team)
	if bank == null or bank.essence < min_stake(kind):
		return "Not enough essence"
	return ""


## What raise(bounty, amount) would answer now, without spending.
func can_raise(bounty: Bounty, amount: int) -> String:
	if bounty == null or not is_instance_valid(bounty) or bounty.ended or not bounties.has(bounty):
		return "Invalid target"
	if bounty.stake >= MAX_STAKE:
		return "Max bounty"
	var add := mini(maxi(amount, 0), MAX_STAKE - bounty.stake)
	var bank := EssenceBank.for_team(team)
	if add > 0 and (bank == null or bank.essence < add):
		return "Not enough essence"
	return ""


## The capture point an Explore at `pos` would claim: the nearest one within 7 m (flat) that this team does
## not hold, or null.
func claim_point_near(pos: Vector3) -> Node3D:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var best: Node3D = null
	var best_d := CLAIM_RADIUS + 0.0001
	for node in tree.get_nodes_in_group(POINT_GROUP):
		var p := node as Node3D
		if p == null or not is_instance_valid(p) or p.is_queued_for_deletion() or point_owner(p) == team:
			continue
		var d := _flat(p.global_position, pos)
		if d <= best_d:
			best_d = d
			best = p
	return best


## True for a capture point (group "capture_points").
static func is_point(node: Node) -> bool:
	return node != null and is_instance_valid(node) and node.is_in_group(POINT_GROUP)


## The team holding a capture point (`owner_team`), -1 when neutral or unknown.
static func point_owner(node: Node) -> int:
	if node == null or not is_instance_valid(node):
		return -1
	var o: Variant = node.get(&"owner_team")
	return int(o) if o != null else -1


## Adds `amount` essence to `bounty` (clipped at 500). Returns "" or "Invalid target" (not an active
## flag of ours), "Max bounty", "Not enough essence".
func raise(bounty: Bounty, amount: int) -> String:
	if bounty == null or not is_instance_valid(bounty) or bounty.ended or not bounties.has(bounty):
		return "Invalid target"
	if bounty.stake >= MAX_STAKE:
		return "Max bounty"
	if amount <= 0:
		return ""
	var add := mini(amount, MAX_STAKE - bounty.stake)
	var bank := EssenceBank.for_team(team)
	if bank == null or not bank.spend(add):
		return "Not enough essence"
	bounty.stake += add
	bounty.notify_changed()
	bounty_raised.emit(bounty, add)
	if bounty.kind == Bounty.HUNT and add >= RAISE_STEP_BIG:
		_warn_hunted(bounty)
	return ""


## Takes the flag down. Unpaid part: 100 % back to the bank if no champion pursues it, else 50 % back
## and 50 % split among the pursuers as a walk fee. Returns the refund.
func remove(bounty: Bounty) -> int:
	if bounty == null or not is_instance_valid(bounty) or bounty.ended or not bounties.has(bounty):
		return 0
	var rest := bounty.unpaid()
	var walkers := bounty.active_pursuers()
	var refund := rest
	if not walkers.is_empty() and rest > 0:
		var fee := rest / 2
		refund = rest - fee
		_pay(bounty, walkers, fee)
	_refund(refund)
	_end(bounty, &"removed")
	return refund


## Our active HUNT bounties whose target belongs to `victim_team` (the bot reads it; for "every
## hunt on my things" use the static all_hunts_on).
func hunts_on(victim_team: int) -> Array:
	var out: Array = []
	for b in bounties:
		if b.kind == Bounty.HUNT and not b.ended and b.target != null and is_instance_valid(b.target) \
				and b.target.get(&"team") != null and int(b.target.get(&"team")) == victim_team:
			out.append(b)
	return out


## Our active bounty on `target` (any kind), or null.
func bounty_on(target: Node3D) -> Bounty:
	if target == null:
		return null
	for b in bounties:
		if not b.ended and b.target == target:
			return b
	return null


## Champions in the roster (alive, reviving or fallen), for "No champions".
func roster_size() -> int:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return 0
	for node in tree.get_nodes_in_group("champion_guilds"):
		var gt: Variant = node.get(&"team")
		if gt == null or int(gt) != team or not &"champions" in node:
			continue
		var list: Variant = node.get(&"champions")
		if list is Array:
			var n := 0
			for ch: Variant in list:
				if ch != null and is_instance_valid(ch):
					n += 1
			return n
	var count := 0
	for node in tree.get_nodes_in_group("champions"):
		var ct: Variant = node.get(&"team")
		if ct != null and int(ct) == team and not node.is_queued_for_deletion():
			count += 1
	return count


## Our living champions.
func living_champions() -> Array:
	var out: Array = []
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return out
	for node in tree.get_nodes_in_group("champions"):
		var ch := node as Node3D
		if ch == null or ch.is_queued_for_deletion():
			continue
		var ct: Variant = ch.get(&"team")
		if ct == null or int(ct) != team:
			continue
		if ch.has_method(&"is_alive") and not bool(ch.call(&"is_alive")):
			continue
		if ch.is_in_group(&"helpers"):
			continue   # t3-helpers.md 2.1: bounties never steer or pay a tier-3 helper
		out.append(ch)
	return out


## Sends a message line to this team (the `message` signal, and the HUD for the local team).
func notify(text: String) -> void:
	message.emit(text)
	if not show_on_hud or team != _local_team():
		return
	var tree := Engine.get_main_loop() as SceneTree
	var scene: Node = tree.current_scene if tree else null
	if scene == null or not &"hud" in scene:
		return
	var hud: Variant = scene.get(&"hud")
	if is_instance_valid(hud) and hud is Object and (hud as Object).has_method(&"show_message"):
		(hud as Object).call(&"show_message", text, MESSAGE_SECONDS)


# ---------------------------------------------------------------- placement checks

func _existing_for(kind: int, target: Node3D, pos: Vector3) -> Bounty:
	if kind == Bounty.EXPLORE:
		var best: Bounty = null
		var best_d := EXPLORE_MERGE_RADIUS
		for b in bounties:
			if b.kind != Bounty.EXPLORE or b.ended:
				continue
			var d := _flat(b.global_position, pos)
			if d <= best_d:
				best_d = d
				best = b
		return best
	if target != null and is_instance_valid(target):
		return bounty_on(target)
	return null


func _target_ok(kind: int, target: Node3D, pos: Vector3) -> bool:
	match kind:
		Bounty.EXPLORE:
			if absf(pos.x) > FogOfWar.MAP_HALF or absf(pos.z) > FogOfWar.MAP_HALF:
				return false
			return not _on_water(pos)
		Bounty.HUNT:
			if kind_for(target) != Bounty.HUNT or not _alive(target):
				return false
			var fog := FogOfWar.find()
			if fog == null or not fog.enabled:
				return true
			if target is Building:   # a building ghost counts: known once its spot is explored
				return fog.is_explored(team, target.global_position)
			return fog.is_visible(team, target.global_position)
		Bounty.GUARD:
			if kind_for(target) != Bounty.GUARD:
				return false
			if is_point(target):   # an own-held capture point (kind_for checked the owner)
				return true
			var b := target as Building
			return b != null and _alive(b) and b.is_constructed()
		Bounty.ESCORT:
			return kind_for(target) == Bounty.ESCORT and _alive(target)
	return false


# ---------------------------------------------------------------- rules

func _step(dt: float) -> void:
	for b in bounties.duplicate():
		if not is_instance_valid(b) or b.ended:
			continue
		match b.kind:
			Bounty.HUNT:
				_step_hunt(b, dt)
			Bounty.EXPLORE:
				_step_explore(b)
			Bounty.GUARD, Bounty.ESCORT:
				_step_service(b)


func _step_hunt(b: Bounty, dt: float) -> void:
	if not _valid(b.target):
		_refund(b.unpaid())
		_end(b, &"target_gone")
		return
	var seen := b.target is Building or _sees(b.target.global_position)
	b.set_sighting(seen, dt)
	if b.unseen_time >= HUNT_UNSEEN_EXPIRY:
		_refund(b.unpaid())
		_end(b, &"expired")


func _step_explore(b: Bounty) -> void:
	if b.claim_point != null:
		_step_claim(b)
		return
	var best: Node3D = null
	var best_d := EXPLORE_CLAIM_RADIUS
	for ch: Node3D in living_champions():
		var d := _flat(ch.global_position, b.global_position)
		if d <= best_d:
			best_d = d
			best = ch
	if best:
		_pay(b, [best], b.unpaid())
		_end(b, &"paid")


## CLAIM: waits for the point to become held by the team (the owner_changed signal pays at once; this poll
## is the safety net). The point freed = refund.
func _step_claim(b: Bounty) -> void:
	if not _valid(b.claim_point):
		_refund(b.unpaid())
		_end(b, &"target_gone")
		return
	if point_owner(b.claim_point) == team:
		_pay_claim(b)


## CLAIM: the point is ours: pay the champions in its circle (+1 m) or pursuing within 12 m of it.
func _pay_claim(b: Bounty) -> void:
	if b == null or not is_instance_valid(b) or b.ended:
		return
	var p := b.claim_point
	var at := p.global_position if _valid(p) else b.global_position
	var circle := CLAIM_CIRCLE_SLACK
	if _valid(p) and p.get(&"capture_radius") != null:
		circle += float(p.get(&"capture_radius"))
	var paid_to: Array = []
	for ch: Node3D in living_champions():
		var d := _flat(ch.global_position, at)
		if d <= circle or (b.pursuers.has(ch) and d <= HUNT_PURSUE_RADIUS):
			paid_to.append(ch)
	if paid_to.is_empty():
		_refund(b.unpaid())
		_end(b, &"no_contributor")
		return
	_pay(b, paid_to, b.unpaid())
	_end(b, &"paid")


func _on_claim_owner_changed(_point: Variant, new_team: int, _old_team: int, b: Bounty) -> void:
	if b == null or not is_instance_valid(b) or b.ended or new_team != team:
		return
	_pay_claim(b)


## GUARD on a capture point: it changed hands -> the flag ends, the unpaid rest comes back.
func _on_guard_owner_changed(_point: Variant, new_team: int, _old_team: int, b: Bounty) -> void:
	if b == null or not is_instance_valid(b) or b.ended or new_team == team:
		return
	_end_guard_point_lost(b)


func _end_guard_point_lost(b: Bounty) -> void:
	if b.ended:
		return
	_announce_totals(b)
	_refund(b.unpaid())
	_end(b, &"owner_changed")


func _step_service(b: Bounty) -> void:
	if not _alive(b.target):
		_end_service_on_death(b)
		return
	if b.kind == Bounty.GUARD and is_point(b.target) and point_owner(b.target) != team:
		_end_guard_point_lost(b)
		return
	var radius := GUARD_RADIUS if b.kind == Bounty.GUARD else ESCORT_RADIUS
	var due_ticks := floori(b.elapsed / SERVICE_TICK + 0.0001)
	while b.ticks_done < due_ticks and b.ticks_paid < SERVICE_TICKS:
		b.ticks_done += 1
		var near := _champions_near(b.target.global_position, radius)
		if near.is_empty():
			continue   # a tick with nobody there is kept
		var goal := roundi(float(b.stake) * float(b.ticks_paid + 1) / float(SERVICE_TICKS))
		var due := mini(goal - b.paid, b.unpaid())
		b.ticks_paid += 1
		_pay(b, near, due, false)
	if b.ticks_paid >= SERVICE_TICKS:   # the 9th tick paid exactly the rest of the stake
		_announce_totals(b)
		_end(b, &"paid")
	elif b.elapsed >= SERVICE_EXPIRY - 0.0001:
		_announce_totals(b)
		_refund(b.unpaid())
		_end(b, &"expired")


func _end_service_on_death(b: Bounty) -> void:
	if b.ended:
		return
	_announce_totals(b)
	_refund(b.unpaid())
	_end(b, &"target_died")


func _on_target_died(_victim: Variant, b: Bounty) -> void:
	if b == null or not is_instance_valid(b) or b.ended:
		return
	if b.kind == Bounty.GUARD or b.kind == Bounty.ESCORT:
		_end_service_on_death(b)
		return
	if b.kind != Bounty.HUNT:
		return
	var target := b.target
	if target is Building and bool((target as Building).cancelled):
		_refund(b.unpaid())
		_end(b, &"target_gone")
		return
	var at := target.global_position if _valid(target) else b.last_seen_pos
	var contributors: Array = []
	for ch: Node3D in living_champions():
		var id := ch.get_instance_id()
		var hit := b.hit_times.has(id) and _clock - float(b.hit_times[id]) <= HUNT_CONTRIBUTION_WINDOW + 0.0001
		var pursuing := b.pursuers.has(ch) and _flat(ch.global_position, at) <= HUNT_PURSUE_RADIUS
		if hit or pursuing:
			contributors.append(ch)
	if contributors.is_empty():
		_refund(b.unpaid())
		_end(b, &"no_contributor")
		return
	_pay(b, contributors, b.unpaid())
	_end(b, &"paid")


func _on_target_exiting(b: Bounty) -> void:
	if b == null or not is_instance_valid(b) or b.ended:
		return
	# The whole level is being freed: no refunds (EssenceBank.for_team would try to add a bank to a busy parent).
	if not is_inside_tree() or is_queued_for_deletion() or (get_parent() and get_parent().is_queued_for_deletion()):
		return
	# Freed without dying first (a dismissed / despawned unit): nobody earned it.
	if b.kind == Bounty.GUARD or b.kind == Bounty.ESCORT:
		_end_service_on_death(b)
	else:
		_refund(b.unpaid())
		_end(b, &"target_gone")


func _on_target_hit(_amount: float, attacker: Variant, b: Bounty) -> void:
	if b == null or not is_instance_valid(b) or b.ended or attacker == null or not is_instance_valid(attacker):
		return
	var a := attacker as Node
	if a == null or not a.is_in_group(&"champions"):
		return
	var at: Variant = a.get(&"team")
	if at != null and int(at) == team:
		b.hit_times[a.get_instance_id()] = _clock


func _on_pursuer_added(champion: Node3D, b: Bounty) -> void:
	if b.ended or champion == null or b.announced.has(champion.get_instance_id()):
		return
	b.announced[champion.get_instance_id()] = true
	var what := "bounty on %s" % _the(b.target)
	if b.is_claim():
		what = "claim on %s" % name_of(b.claim_point)
	elif b.kind == Bounty.EXPLORE:
		what = "scouting bounty"
	notify("%s took your %s" % [name_of(champion), what])


# ---------------------------------------------------------------- money

## Splits `amount` equally among `champs` (the first ones get the odd units): purse + half as XP.
func _pay(b: Bounty, champs: Array, amount: int, announce := true) -> void:
	var n := champs.size()
	if n == 0 or amount <= 0:
		return
	var base := amount / n
	var extra := amount % n
	for i in n:
		var ch := champs[i] as Node3D
		var share := base + (1 if i < extra else 0)
		if ch == null or share <= 0:
			continue
		b.paid += share
		var id := ch.get_instance_id()
		b.paid_to[id] = int(b.paid_to.get(id, 0)) + share
		# Emit before the XP: a champion that reaches level 2 on this payment still counts it as a class lean (step 11).
		bounty_paid.emit(b, ch, share)
		_give(ch, share)
		if announce:
			notify("Bounty paid: %d to %s" % [share, name_of(ch)])
	b.notify_changed()


func _give(ch: Node3D, share: int) -> void:
	if ch.has_method(&"add_purse"):
		ch.call(&"add_purse", share)
	elif &"purse" in ch:
		ch.set(&"purse", int(ch.get(&"purse")) + share)
	var xp := roundi(share * 0.5)
	if xp > 0 and ch.has_method(&"add_xp"):
		ch.call(&"add_xp", xp)


## GUARD / ESCORT: one "Bounty paid" line per champion at the end of the service.
func _announce_totals(b: Bounty) -> void:
	for id: int in b.paid_to:
		var ch := instance_from_id(id) as Node
		var who := name_of(ch) if ch else "a champion"
		notify("Bounty paid: %d to %s" % [int(b.paid_to[id]), who])


func _refund(amount: int) -> void:
	if amount <= 0:
		return
	var bank := EssenceBank.for_team(team)
	if bank:
		bank.add(amount)
	notify("Bounty refunded: %d" % amount)


func _warn_hunted(b: Bounty) -> void:
	if not _valid(b.target):
		return
	var vt: Variant = b.target.get(&"team")
	if vt == null or (int(vt) != Unit.Team.PLAYER and int(vt) != Unit.Team.ENEMY) or int(vt) == team:
		return
	var what := name_of(b.target) if is_named(b.target) else "your %s" % name_of(b.target)
	var victim_board := BountyBoard.for_team(int(vt))
	if victim_board:
		victim_board.notify("A bounty of %d is on %s!" % [b.stake, what])


func _end(b: Bounty, reason: StringName) -> void:
	if b.ended:
		return
	bounties.erase(b)
	_unwatch_bounty(b)
	b.finish(reason)
	bounty_ended.emit(b, reason)


# ---------------------------------------------------------------- signal plumbing

func _watch_bounty(b: Bounty) -> void:
	var list: Array = []
	var t := b.target
	if _valid(t):
		if t.has_signal(&"died"):
			list.append([t, &"died", _on_target_died.bind(b)])
		if t is Building and t.has_signal(&"destroyed"):
			list.append([t, &"destroyed", _on_target_died.bind(b)])
		list.append([t, &"tree_exiting", _on_target_exiting.bind(b)])
		if b.kind == Bounty.HUNT:
			if t.has_signal(&"damage_taken"):
				list.append([t, &"damage_taken", _on_target_hit.bind(b)])
			if t.has_signal(&"damaged"):
				list.append([t, &"damaged", _on_target_hit.bind(b)])
		if b.kind == Bounty.GUARD and is_point(t) and t.has_signal(&"owner_changed"):
			list.append([t, &"owner_changed", _on_guard_owner_changed.bind(b)])
	var cp := b.claim_point
	if b.kind == Bounty.EXPLORE and _valid(cp):
		if cp.has_signal(&"owner_changed"):
			list.append([cp, &"owner_changed", _on_claim_owner_changed.bind(b)])
		list.append([cp, &"tree_exiting", _on_target_exiting.bind(b)])
	list.append([b, &"pursuer_added", _on_pursuer_added.bind(b)])
	for c: Array in list:
		(c[0] as Object).connect(c[1], c[2])
	_watch[b.get_instance_id()] = list


func _unwatch_bounty(b: Bounty) -> void:
	var list: Array = _watch.get(b.get_instance_id(), [])
	_watch.erase(b.get_instance_id())
	for c: Array in list:
		var obj: Variant = c[0]
		if obj != null and is_instance_valid(obj) and (obj as Object).is_connected(c[1], c[2]):
			(obj as Object).disconnect(c[1], c[2])


# ---------------------------------------------------------------- helpers

func _champions_near(pos: Vector3, radius: float) -> Array:
	var out: Array = []
	for ch: Node3D in living_champions():
		if _flat(ch.global_position, pos) <= radius:
			out.append(ch)
	return out


## Deep water of the map's river (group "river", `is_water`); false without a river.
static func _on_water(pos: Vector3) -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return false
	for node in tree.get_nodes_in_group(&"river"):
		if is_instance_valid(node) and not node.is_queued_for_deletion() and node.has_method(&"is_water"):
			return bool(node.call(&"is_water", pos))
	return false


func _sees(pos: Vector3) -> bool:
	var fog := FogOfWar.find()
	return fog == null or not fog.enabled or fog.is_visible(team, pos)


func _local_team() -> int:
	var fog := FogOfWar.find()
	return fog.local_team if fog else Unit.Team.PLAYER


## "Vessa" / "the Gloom Hall".
static func _the(node: Node) -> String:
	if node == null or not is_instance_valid(node):
		return "a lost target"
	return name_of(node) if is_named(node) else "the %s" % name_of(node)


static func _valid(node: Variant) -> bool:
	return node != null and is_instance_valid(node)


static func _alive(node: Variant) -> bool:
	if not _valid(node):
		return false
	var obj := node as Object
	return not obj.has_method(&"is_alive") or bool(obj.call(&"is_alive"))


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
