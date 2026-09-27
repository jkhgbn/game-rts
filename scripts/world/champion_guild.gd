class_name ChampionGuild
extends Node
## One team's champion roster (docs/design/champions.md section 3, contract section 13). One node per team
## in group "champion_guilds"; find it with `ChampionGuild.for_team(team)` (null when the level has none,
## e.g. mission 1 / the smoke-test map).
## - Hire (`can_hire` / `hire`): max 3 in the roster (alive, reviving, fallen and hires on their way all
##   count), each archetype once, the n-th costs HIRE_COSTS[n - 1] crystals + essence and POP population
##   (reserved from the payment on, kept while fallen). The champion walks out of the door of a tavern not
##   held by the enemy (the one nearer the wizard, or the keep while she is dead) HIRE_DELAY s after paying,
##   level 1, empty inventory, purse SIGNING_PURSE. Name A (variant 0) for the first hire of an archetype on
##   either side, B (variant 1) for the other side's.
## - Upkeep: every UPKEEP_INTERVAL s, UPKEEP_PER_CHAMPION essence per living champion. UNPAID_AFTER failed
##   ticks in a row make every champion of the team Unpaid (`is_unpaid`) until the next paid tick.
## - Death: the champion stays in the roster (fallen). `revive` costs 80 + 35 x level essence and brings it
##   back after 15 + 5 x level s at the keep's spawn point (oldest barracks without a keep).
## - Dismiss (alive or fallen): the bank gets 50 % of its purse + 50 % of its items' value; it fades out
##   over 1 s; the slot, the pop and the archetype are free again.
## - Gold (market-trade.md 3.2, step 10): `pay_gold = true` on hire_cost / can_hire / hire pays the crystal part
##   in gold instead (GOLD_PER_CRYSTAL, 1:1; essence and pop unchanged); on revive_cost / can_revive / revive it
##   pays REVIVE_GOLD_PER_ESSENCE gold per essence instead of essence. The team's GoldBank is found through the
##   group "gold_banks" (none when trade is off: every gold payment is refused with "Not enough gold").
##   Without the flag everything is exactly the step-9 behaviour.
## Messages for the local team go out through `message(text, seconds)` (the level connects it to
## hud.show_message). Champions are built from res://scripts/units/champion.gd with their ChampionType
## (res://scripts/units/champion_type.gd `find(id)`), both loaded by path. A Champion is expected to stay in
## the tree while fallen (hidden, like a Wizard) and to offer `respawn(at: Vector3)`.

signal roster_changed
signal champion_hired(champion: Node)
signal champion_fallen(champion: Node)
signal champion_revived(champion: Node)
signal champion_dismissed(champion: Node, refund: int)
## A line for the HUD message area (only what the local team should read).
signal message(text: String, seconds: float)
## After each upkeep tick: `paid` false when the bank could not pay `amount` (0 = nobody to pay).
signal upkeep_ticked(paid: bool, amount: int)
## The team became Unpaid (true) or was paid again (false).
signal unpaid_changed(unpaid: bool)

const CHAMPION_SCRIPT_PATH := "res://scripts/units/champion.gd"
const CHAMPION_TYPE_PATH := "res://scripts/units/champion_type.gd"
## The four archetypes (champions.md 4.1), in tavern-window order.
const ARCHETYPES: Array[StringName] = [&"wayfinder", &"oathwall", &"coin_cutter", &"mender"]

const MAX_CHAMPIONS := 3
## Crystals + essence of the 1st, 2nd and 3rd champion in the roster (step 11, skills-rework.md 9.2: was 200 / 250 / 300).
const HIRE_COSTS: Array[Dictionary] = [
	{"crystals": 225, "essence": 75},
	{"crystals": 275, "essence": 100},
	{"crystals": 325, "essence": 125},
]
const POP := 2
const HIRE_DELAY := 3.0
const SIGNING_PURSE := 50
const UPKEEP_INTERVAL := 10.0
const UPKEEP_PER_CHAMPION := 1
const UNPAID_AFTER := 3
## Revive essence = REVIVE_BASE_COST + REVIVE_COST_PER_LEVEL x level (step 11: was 60 + 30 x level).
const REVIVE_BASE_COST := 80
const REVIVE_COST_PER_LEVEL := 35
const REVIVE_BASE_TIME := 15.0
const REVIVE_TIME_PER_LEVEL := 5.0
## Gold paid per crystal of a hire's crystal part (pay_gold) and per essence of a revive (pay_gold).
const GOLD_PER_CRYSTAL := 1
const REVIVE_GOLD_PER_ESSENCE := 2
const GOLD_BANKS_GROUP := &"gold_banks"
const DISMISS_PURSE_RATIO := 0.5
const DISMISS_ITEM_RATIO := 0.5
const DISMISS_FADE := 1.0
const NAV_SNAP := 3.0            ## A door / home point snaps to the navmesh when it is this close.

## can_hire / hire refusals, in the order they are checked (champions.md 3.1).
const R_CLOSED := "Tavern closed"
const R_MAX := "Max 3 champions"
const R_HIRED := "Already hired"
const R_POP := "Population cap reached"
const R_CRYSTALS := "Not enough crystals"
const R_ESSENCE := "Not enough essence"
const R_GOLD := "Not enough gold"   ## pay_gold: in place of R_CRYSTALS (hire) / R_ESSENCE (revive)
const R_HELD := "Enemies hold both taverns"
const R_UNKNOWN := "Unknown champion"
## can_revive / revive refusals, in order.
const R_NOT_FALLEN := "Not fallen"
const R_REVIVING := "Already reviving"
const R_NO_HOME := "No home"

const MSG_JOINS := "%s joins you"
const MSG_ENEMY_HIRED := "%s hired %s"
const MSG_FALLEN := "%s has fallen"
const MSG_RETURNS := "%s returns in %d s"
const MSG_LEAVES := "%s leaves your service"
const MSG_UNPAID := "Your champions are unpaid: they ignore bounties"

const PLAYER_TEAM := 0
const ENEMY_TEAM := 1
const NEUTRAL_TEAM := 2

@export var team: int = PLAYER_TEAM
## The team whose player reads the messages (the others' lines are only about what that player can see).
@export var local_team: int = PLAYER_TEAM
## Seconds between upkeep ticks (tests may shorten it).
var upkeep_interval := UPKEEP_INTERVAL

## The hired champions (spawned nodes: alive, reviving or fallen), oldest first. Read only.
var champions: Array = []
## True while the team is Unpaid (3 failed upkeep ticks in a row, until the next paid one). Read only.
var unpaid := false
## Where champions are added (default: this guild's parent, the level).
var spawn_parent: Node
## Hooks for tests and tools: a Script to build champions with (default: CHAMPION_SCRIPT_PATH) and a
## Callable(id: StringName) -> Resource returning the ChampionType (default: ChampionType.find by path).
var champion_script: Script
var type_lookup: Callable

var _pending: Array[Dictionary] = []   # {id, variant, type, tavern, left, companion}
var _rec: Dictionary = {}              # champion Node -> {id, variant, reserved, reviving, revive_left, leaving}
var _claims: Dictionary = {}           # StringName archetype id -> variant this team uses (0 A, 1 B)
var _upkeep_left := UPKEEP_INTERVAL
var _failed_ticks := 0
var _reserved_pending := 0             # pop reserved for hires on their way


## The guild of `for_team_id`, or null when the level has none.
static func for_team(for_team_id: int) -> ChampionGuild:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	for node in tree.get_nodes_in_group("champion_guilds"):
		var g := node as ChampionGuild
		if g and g.team == for_team_id and not g.is_queued_for_deletion():
			return g
	return null


func _init() -> void:
	add_to_group("champion_guilds")


func _ready() -> void:
	add_to_group("champion_guilds")
	_upkeep_left = upkeep_interval


func _physics_process(delta: float) -> void:
	_tick_pending(delta)
	_tick_revives(delta)
	_upkeep_left -= delta
	if _upkeep_left <= 0.0:
		_upkeep_left += upkeep_interval
		_upkeep_tick()


# ---------------------------------------------------------------- queries

## True when a tavern of the level is open (2:00 of match time). False without taverns.
func is_open() -> bool:
	return Tavern.any_open()


## This team's GoldBank (group "gold_banks", matched on its `team`), or null when trade is off. Returned
## untyped: GoldBank is step-10 code reached by group, has_method and call (can_afford / spend).
func gold_bank_of_team() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	for node in tree.get_nodes_in_group(GOLD_BANKS_GROUP):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var t: Variant = node.get(&"team")
		if t != null and int(t) == team and node.has_method(&"can_afford") and node.has_method(&"spend"):
			return node
	return null


## Champions in the roster + hires on their way (the slots used, max 3).
func roster_size() -> int:
	return champions.size() + _pending.size()


## What the next hire costs: {crystals, essence, gold}. The price depends on the roster size, not on the
## archetype (after a full roster: the 3rd price). `pay_gold`: the crystal part is paid in gold instead
## (1 gold per crystal: crystals 0, gold 225 / 275 / 325); the essence part is the same either way.
func hire_cost(_id: StringName = &"", pay_gold: bool = false) -> Dictionary:
	var base: Dictionary = HIRE_COSTS[clampi(roster_size(), 0, HIRE_COSTS.size() - 1)]
	var crystals := int(base["crystals"])
	if pay_gold:
		return {"crystals": 0, "essence": int(base["essence"]), "gold": crystals * GOLD_PER_CRYSTAL}
	return {"crystals": crystals, "essence": int(base["essence"]), "gold": 0}


## "" if `id` can be hired now, else the first refusal of champions.md 3.1 (see the R_* constants).
## `pay_gold`: "Not enough gold" (also when trade is off) is checked in place of "Not enough crystals".
func can_hire(id: StringName, pay_gold: bool = false) -> String:
	id = StringName(id)
	if not ARCHETYPES.has(id):
		return R_UNKNOWN
	if not is_open():
		return R_CLOSED
	if roster_size() >= MAX_CHAMPIONS:
		return R_MAX
	if has_archetype(id):
		return R_HIRED
	var eco := Economy.for_team(team)
	if eco and not eco.has_pop_for(POP):
		return R_POP
	var cost := hire_cost(id, pay_gold)
	if pay_gold:
		var gold_bank := gold_bank_of_team()
		if gold_bank == null or not bool(gold_bank.call(&"can_afford", int(cost["gold"]))):
			return R_GOLD
	elif eco == null or not eco.can_afford(int(cost["crystals"])):
		return R_CRYSTALS
	var bank := EssenceBank.for_team(team)
	if bank == null or not bank.can_afford(int(cost["essence"])):
		return R_ESSENCE
	if _free_tavern() == null:
		return R_HELD
	return ""


## Pays and sends the champion out of a free tavern door HIRE_DELAY s later. "" = ok, else the reason.
## `pay_gold`: the crystal part is paid from the team's GoldBank (see hire_cost).
func hire(id: StringName, pay_gold: bool = false) -> String:
	id = StringName(id)
	var reason := can_hire(id, pay_gold)
	if reason != "":
		return reason
	var type := find_type(id)
	if type == null:
		push_warning("ChampionGuild: no ChampionType '%s' yet, can't hire" % id)
		return R_UNKNOWN
	var cost := hire_cost(id, pay_gold)
	var eco := Economy.for_team(team)
	var bank := EssenceBank.for_team(team)
	if pay_gold:
		# can_hire checked both banks: the essence spend can't fail, so gold is never taken for nothing.
		if not bool(gold_bank_of_team().call(&"spend", int(cost["gold"]))):
			return R_GOLD
		if not bank.spend(int(cost["essence"])):
			return R_ESSENCE   # can't happen after can_hire, but never spawn for free
	elif not eco.spend(int(cost["crystals"])) or not bank.spend(int(cost["essence"])):
		return R_ESSENCE   # can't happen after can_hire, but never spawn for free
	if eco:
		eco.reserve_pop(POP)
	_reserved_pending += POP
	var variant := _claim_variant(id)
	_pending.append({"id": id, "variant": variant, "type": type, "tavern": _free_tavern(), "left": HIRE_DELAY,
			"companion": {}})
	roster_changed.emit()
	return ""


## True when an archetype is in the roster (alive, fallen, reviving) or on its way.
func has_archetype(id: StringName) -> bool:
	return champion_of(id) != null or is_hiring(id)


## The roster's champion of that archetype, or null.
func champion_of(id: StringName) -> Node:
	for ch in champions:
		var r: Dictionary = _rec.get(ch, {})
		if StringName(r.get("id", &"")) == StringName(id):
			return ch
	return null


## True while a hire of `id` waits to walk out of the tavern.
func is_hiring(id: StringName) -> bool:
	for p in _pending:
		if StringName(p["id"]) == StringName(id):
			return true
	return false


## Seconds until the hired `id` walks out (0 when not on its way).
func hire_time_left(id: StringName) -> float:
	for p in _pending:
		if StringName(p["id"]) == StringName(id):
			return maxf(0.0, float(p["left"]))
	return 0.0


## Archetype ids of the hires on their way.
func pending_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for p in _pending:
		out.append(StringName(p["id"]))
	return out


## The variant (0 = name A, 1 = name B) this team gets for `id`: its own claim, else the opposite of the
## other side's claim, else A.
func variant_for(id: StringName) -> int:
	id = StringName(id)
	if _claims.has(id):
		return int(_claims[id])
	for node in get_tree().get_nodes_in_group("champion_guilds") if is_inside_tree() else []:
		var g := node as ChampionGuild
		if g and g != self and g._claims.has(id):
			return 1 - int(g._claims[id])
	return 0


## The name this team's `id` has (or will have when hired): ChampionType.names[variant_for(id)].
func name_for(id: StringName) -> String:
	var type := find_type(id)
	var names: Variant = type.get(&"names") if type else null
	var v := variant_for(id)
	if names is PackedStringArray or names is Array:
		if v < names.size():
			return String(names[v])
	return String(id).capitalize()


## The display name this team would get by hiring `id` now (tavern window rows; same as name_for).
func next_name(id: StringName) -> String:
	return name_for(id)


## The price of the next hire (roster size + 1): {crystals, essence}.
func next_hire_cost() -> Dictionary:
	return hire_cost()


## The taverns held by this team's enemy right now (empty = every tavern is free).
func held_taverns() -> Array:
	var out: Array = []
	for t in Tavern.all():
		if bool(t.call(&"is_held_by_enemy_of", team)):
			out.append(t)
	return out


## True when `tavern` is held by this team's enemy.
func is_tavern_held(tavern: Node) -> bool:
	return tavern != null and is_instance_valid(tavern) and tavern.has_method(&"is_held_by_enemy_of") \
			and bool(tavern.call(&"is_held_by_enemy_of", team))


## The archetype id of a roster champion (&"" if it is not ours).
func archetype_of(ch: Node) -> StringName:
	return StringName((_rec.get(ch, {}) as Dictionary).get("id", &""))


## Alive champions of the roster (the ones upkeep pays for).
func living_count() -> int:
	var n := 0
	for ch in champions:
		if _alive(ch):
			n += 1
	return n


func is_fallen(ch: Node) -> bool:
	return _rec.has(ch) and not _alive(ch)


func is_reviving(ch: Node) -> bool:
	return _rec.has(ch) and bool(_rec[ch]["reviving"])


## What a revive of `ch` costs, in the currency it is paid with: essence 80 + 35 x level (L1 115, L4 220,
## L6 290), or with `pay_gold` 2 gold per essence (L1 230, L4 440, L6 580). An int (not the section-12 Dictionary) so the step-9
## callers doing arithmetic on `revive_cost(ch)` keep working.
func revive_cost(ch: Node, pay_gold: bool = false) -> int:
	var essence := REVIVE_BASE_COST + REVIVE_COST_PER_LEVEL * _level_of(ch)
	return essence * REVIVE_GOLD_PER_ESSENCE if pay_gold else essence


## Seconds a revive of `ch` takes: 15 + 5 x level.
func revive_duration(ch: Node) -> float:
	return REVIVE_BASE_TIME + REVIVE_TIME_PER_LEVEL * float(_level_of(ch))


## "" if `ch` can be revived now, else "Not fallen", "Already reviving", "No home" or "Not enough essence"
## ("Not enough gold" with `pay_gold`, also when trade is off).
func can_revive(ch: Node, pay_gold: bool = false) -> String:
	if ch == null or not is_instance_valid(ch) or not _rec.has(ch) or _alive(ch):
		return R_NOT_FALLEN
	if bool(_rec[ch]["reviving"]):
		return R_REVIVING
	if home_point() == Vector3.INF:
		return R_NO_HOME
	if pay_gold:
		var gold_bank := gold_bank_of_team()
		if gold_bank == null or not bool(gold_bank.call(&"can_afford", revive_cost(ch, true))):
			return R_GOLD
		return ""
	var bank := EssenceBank.for_team(team)
	if bank == null or not bank.can_afford(revive_cost(ch)):
		return R_ESSENCE
	return ""


## Pays the revive (essence, or gold with `pay_gold`); the champion comes back at home_point() after
## revive_duration(ch). "" = ok.
func revive(ch: Node, pay_gold: bool = false) -> String:
	var reason := can_revive(ch, pay_gold)
	if reason != "":
		return reason
	var cost := revive_cost(ch, pay_gold)
	if pay_gold:
		if not bool(gold_bank_of_team().call(&"spend", cost)):
			return R_GOLD
	elif not EssenceBank.for_team(team).spend(cost):
		return R_ESSENCE
	var seconds := revive_duration(ch)
	_rec[ch]["reviving"] = true
	_rec[ch]["revive_left"] = seconds
	_say(MSG_RETURNS % [_name_of(ch), roundi(seconds)])
	roster_changed.emit()
	return ""


## Seconds until a reviving champion is back (0 when not reviving).
func revive_time_left(ch: Node) -> float:
	if not _rec.has(ch) or not bool(_rec[ch]["reviving"]):
		return 0.0
	return maxf(0.0, float(_rec[ch]["revive_left"]))


## Essence a dismiss of `ch` gives the team: 50 % of its purse + 50 % of its items' total value.
func dismiss_value(ch: Node) -> int:
	if ch == null or not is_instance_valid(ch):
		return 0
	var purse := int(ch.get(&"purse")) if ch.get(&"purse") != null else 0
	var items := 0
	var inv: Object = ItemDrops.inventory_of(ch)
	if inv and inv.has_method(&"total_item_value"):
		items = int(inv.call(&"total_item_value"))
	return floori(purse * DISMISS_PURSE_RATIO) + floori(items * DISMISS_ITEM_RATIO)


## Sends `ch` (alive or fallen) away: the bank gets dismiss_value(ch), the slot and the pop are freed at
## once, a living champion fades out over 1 s where it stands. Returns the essence given (0 if not ours).
func dismiss(ch: Node) -> int:
	if ch == null or not is_instance_valid(ch) or not _rec.has(ch):
		return 0
	var refund := dismiss_value(ch)
	var bank := EssenceBank.for_team(team)
	if bank and refund > 0:
		bank.add(refund)
	var champ_name := _name_of(ch)
	var alive := _alive(ch)
	_rec[ch]["leaving"] = true
	_forget(ch)
	_say(MSG_LEAVES % champ_name)
	champion_dismissed.emit(ch, refund)
	roster_changed.emit()
	if alive:
		_fade_out(ch)
	else:
		ch.queue_free()
	return refund


## Where a revived champion comes back: the living keep's spawn point, else the spawn corner of the oldest
## completed barracks; Vector3.INF when the team has neither.
func home_point() -> Vector3:
	var barracks: TrainingBuilding = null
	for node in get_tree().get_nodes_in_group("buildings"):   # tree order = oldest first
		var b := node as TrainingBuilding
		if b == null or int(b.team) != team or not b.is_alive():
			continue
		if b is Keep:
			return b.spawn_point()
		if barracks == null and b.is_constructed():
			barracks = b
	return barracks.spawn_point() if barracks else Vector3.INF


## Seconds until the next upkeep tick.
func upkeep_time_left() -> float:
	return maxf(0.0, _upkeep_left)


## The ChampionType of `id` (type_lookup, else ChampionType.find through its script path), or null.
func find_type(id: StringName) -> Resource:
	if type_lookup.is_valid():
		return type_lookup.call(StringName(id)) as Resource
	if not ResourceLoader.exists(CHAMPION_TYPE_PATH):
		return null
	var script := load(CHAMPION_TYPE_PATH) as Script
	if script == null or not Keep.script_has(script, &"find"):
		return null
	return script.call(&"find", StringName(id)) as Resource


## A carried campaign companion (champions.md 11): spawns at once near `at` as a roster champion, no cost,
## level 1, with `data` = {id, variant, items: [{id, count} or null...], purse, class (optional, step 11)}. A saved
## class is re-applied with `set_champion_class` (when the champion has it; class skills unlock again at 2 / 3 / 5);
## without the key the champion draws at level 2 as usual. Returns it, or null.
func add_companion(data: Dictionary, at: Vector3) -> Node:
	var id := StringName(str(data.get("id", "")))
	if not ARCHETYPES.has(id) or has_archetype(id) or roster_size() >= MAX_CHAMPIONS:
		return null
	var type := find_type(id)
	if type == null:
		push_warning("ChampionGuild: no ChampionType '%s' yet, companion lost" % id)
		return null
	var variant := clampi(int(data.get("variant", 0)), 0, 1)
	if not _claims.has(id):
		_claims[id] = variant
	var eco := Economy.for_team(team)
	if eco:
		eco.reserve_pop(POP)
		_reserved_pending += POP
	var ch := _spawn_champion(id, variant, type, _snap(at), data)
	return ch


# ---------------------------------------------------------------- hiring internals

## The tavern a new champion walks out of: not held by the enemy; if both are free, the one whose door is
## nearer the wizard (the keep while she is dead). Null when every tavern is held (or there is none).
func _free_tavern() -> Node3D:
	var free: Array = []
	for t in Tavern.all():
		if t.has_method(&"is_held_by_enemy_of") and not bool(t.call(&"is_held_by_enemy_of", team)):
			free.append(t)
	if free.is_empty():
		return null
	if free.size() == 1:
		return free[0]
	var ref := _reference_point()
	var best: Node3D = free[0]
	var best_d := INF
	for t: Node3D in free:
		var d := (t.call(&"door_point") as Vector3).distance_squared_to(ref)
		if d < best_d:
			best_d = d
			best = t
	return best


## The living wizard of the team, else its keep, else the home point (for the door choice).
func _reference_point() -> Vector3:
	var wiz := _wizard()
	if wiz and wiz.is_alive():
		return wiz.global_position
	var k := Keep.nearest(team, Vector3.ZERO)
	if k:
		return k.global_position
	var h := home_point()
	return h if h != Vector3.INF else Vector3.ZERO


func _wizard() -> Wizard:
	var level := get_parent()
	if level and level.has_method(&"wizard_of"):
		var w: Variant = level.call(&"wizard_of", team)
		if w is Wizard and is_instance_valid(w):
			return w
	for group in [&"heroes", &"enemy_heroes"]:
		for node in get_tree().get_nodes_in_group(group):
			var wz := node as Wizard
			if wz and int(wz.team) == team:
				return wz
	return null


func _claim_variant(id: StringName) -> int:
	var v := variant_for(id)
	_claims[id] = v
	return v


func _tick_pending(delta: float) -> void:
	if _pending.is_empty():
		return
	var due: Array[Dictionary] = []
	for p in _pending:
		p["left"] = float(p["left"]) - delta
		if float(p["left"]) <= 0.0:
			due.append(p)
	for p in due:
		_pending.erase(p)
		var tavern: Node3D = p["tavern"] if is_instance_valid(p["tavern"]) and p["tavern"] is Node3D else null
		# If its tavern was taken meanwhile, use a free one (already paid: the held one if none is free).
		if tavern == null or bool(tavern.call(&"is_held_by_enemy_of", team)):
			var other := _free_tavern()
			if other:
				tavern = other
		var at: Vector3 = tavern.call(&"door_point") if tavern else _reference_point()
		_spawn_champion(StringName(p["id"]), int(p["variant"]), p["type"], _snap(at), p["companion"])


## Builds the champion, adds it to the level at `at`, counts its pop (Economy counts a unit whose
## UnitType has a pop; the guild reserves the rest of POP itself) and announces it.
func _spawn_champion(id: StringName, variant: int, type: Resource, at: Vector3, companion: Dictionary) -> Node:
	var eco := Economy.for_team(team)
	var ch := _make_champion(type, variant)
	if ch == null:
		if eco:
			eco.release_pop(POP)
		_reserved_pending = maxi(0, _reserved_pending - POP)
		roster_changed.emit()
		return null
	# The payment's reservation ends right before the unit exists (like a training queue).
	if eco:
		eco.release_pop(POP)
	_reserved_pending = maxi(0, _reserved_pending - POP)
	var before := eco.pop_used if eco else 0
	var parent := spawn_parent if spawn_parent and is_instance_valid(spawn_parent) else get_parent()
	ch.position = at   # the level sits at the origin; set again below in world space
	parent.add_child(ch)
	var counted := clampi((eco.pop_used - before) if eco else 0, 0, POP)
	var reserved := POP - counted
	if eco and reserved > 0:
		eco.reserve_pop(reserved)
	ch.global_position = at
	if ch.has_method(&"command_stop"):
		ch.call(&"command_stop")   # the door is its first "home"
	_rec[ch] = {"id": id, "variant": variant, "reserved": reserved, "counted": counted, "reviving": false,
			"revive_left": 0.0, "leaving": false}
	champions.append(ch)
	if ch.has_signal(&"died"):
		ch.connect(&"died", _on_champion_died)
	ch.tree_exiting.connect(_on_champion_exiting.bind(ch), CONNECT_ONE_SHOT)
	if companion.is_empty():
		_set_purse(ch, SIGNING_PURSE)
	else:
		_restore_companion(ch, companion)
	if &"is_unpaid" in ch:
		ch.set(&"is_unpaid", unpaid)
	if team == local_team:
		_say(MSG_JOINS % _name_of(ch))
	elif _visible_to_local(at):
		var wiz := _wizard()
		var who := EmberCrown.short_name(wiz) if wiz else "The enemy"
		_say(MSG_ENEMY_HIRED % [who, _name_of(ch)], true)
	champion_hired.emit(ch)
	roster_changed.emit()
	return ch


## A new champion node (not in the tree): team set, then `apply_champion_type(type, variant)` (Champion),
## else `setup(type, variant)`, else the champion_type / variant fields.
func _make_champion(type: Resource, variant: int) -> Node3D:
	var script := champion_script
	if script == null and ResourceLoader.exists(CHAMPION_SCRIPT_PATH):
		script = load(CHAMPION_SCRIPT_PATH) as Script
	if script == null or not script.can_instantiate():
		push_warning("ChampionGuild: no champion script (%s) yet, nobody walks out" % CHAMPION_SCRIPT_PATH)
		return null
	var ch := script.new() as Node3D
	if ch == null:
		return null
	ch.set(&"team", team)
	if ch.has_method(&"apply_champion_type"):
		ch.call(&"apply_champion_type", type, variant)
	elif ch.has_method(&"setup"):
		ch.call(&"setup", type, variant)
	else:
		ch.set(&"champion_type", type)
		ch.set(&"variant", variant)
	ch.name = "Champion_%s_%d" % [String(type.get(&"id")) if type.get(&"id") != null else "x", team]
	return ch


## Level 1 champion with the carried items, purse and class (the ChampionType gives the rest).
func _restore_companion(ch: Node, data: Dictionary) -> void:
	_set_purse(ch, maxi(0, int(data.get("purse", 0))))
	var cls := StringName(str(data.get("class", "")).strip_edges())
	if cls != &"" and ch.has_method(&"set_champion_class"):
		ch.call(&"set_champion_class", cls)
	var inv: Object = ItemDrops.inventory_of(ch)
	if inv == null or not inv.has_method(&"add_item"):
		return
	for e: Variant in data.get("items", []):
		if not e is Dictionary:
			continue
		var type := ItemDrops.item_type(StringName(str((e as Dictionary).get("id", ""))))
		if type:
			inv.call(&"add_item", type, maxi(1, int((e as Dictionary).get("count", 1))))


# ---------------------------------------------------------------- death / revive / leave

func _on_champion_died(unit: Node) -> void:
	if not _rec.has(unit):
		return
	var eco := Economy.for_team(team)
	var r: Dictionary = _rec[unit]
	# Economy releases what it counted on death; the roster keeps the full POP reserved while fallen.
	var extra := POP - int(r["reserved"])
	if eco and extra > 0:
		eco.reserve_pop(extra)
	r["reserved"] = POP
	r["counted"] = 0
	r["reviving"] = false
	_say(MSG_FALLEN % _name_of(unit))
	champion_fallen.emit(unit)
	roster_changed.emit()


func _tick_revives(delta: float) -> void:
	for ch in champions.duplicate():
		var r: Dictionary = _rec.get(ch, {})
		if r.is_empty() or not bool(r["reviving"]):
			continue
		r["revive_left"] = float(r["revive_left"]) - delta
		if float(r["revive_left"]) > 0.0:
			continue
		var at := home_point()
		if at == Vector3.INF:
			r["revive_left"] = 0.0
			continue   # no home right now: it waits for one
		_bring_back(ch, _snap(at))


func _bring_back(ch: Node, at: Vector3) -> void:
	var r: Dictionary = _rec[ch]
	r["reviving"] = false
	r["revive_left"] = 0.0
	if not is_instance_valid(ch) or not ch.has_method(&"respawn"):
		push_error("ChampionGuild: champion can't respawn (needs respawn(at) and to stay in the tree while fallen)")
		_forget(ch)
		roster_changed.emit()
		return
	var eco := Economy.for_team(team)
	var before := eco.pop_used if eco else 0
	ch.call(&"respawn", at)
	# If the champion re-entered the tree, Economy counts it again: keep the total at POP.
	var counted := clampi((eco.pop_used - before) if eco else 0, 0, POP)
	if eco and counted > 0:
		eco.release_pop(mini(counted, int(r["reserved"])))
		r["reserved"] = maxi(0, int(r["reserved"]) - counted)
		r["counted"] = counted
	if &"is_unpaid" in ch:
		ch.set(&"is_unpaid", unpaid)
	champion_revived.emit(ch)
	roster_changed.emit()


## Drops `ch` from the roster and gives back the pop the guild holds for it.
func _forget(ch: Node) -> void:
	if not _rec.has(ch):
		return
	var r: Dictionary = _rec[ch]
	var eco := Economy.for_team(team)
	if eco and int(r["reserved"]) > 0:
		eco.release_pop(int(r["reserved"]))
	r["reserved"] = 0
	_rec.erase(ch)
	champions.erase(ch)
	if is_instance_valid(ch) and ch.is_connected(&"died", _on_champion_died):
		ch.disconnect(&"died", _on_champion_died)


## Freed from outside (scene change, a script freeing it): leave the roster cleanly.
func _on_champion_exiting(ch: Node) -> void:
	if _rec.has(ch):
		_forget(ch)
		roster_changed.emit()


## Out of play at once (no targets, no brain), shrinks away over DISMISS_FADE s, then freed.
func _fade_out(ch: Node) -> void:
	if ch.is_in_group(&"units"):
		ch.remove_from_group(&"units")
	if ch.is_in_group(&"champions"):
		ch.remove_from_group(&"champions")
	if ch is CollisionObject3D:
		(ch as CollisionObject3D).collision_layer = 0
	ch.process_mode = Node.PROCESS_MODE_DISABLED
	var node3d := ch as Node3D
	if node3d == null or not is_inside_tree():
		ch.queue_free()
		return
	var tween := create_tween()
	tween.tween_property(node3d, "scale", Vector3(0.05, 0.05, 0.05), DISMISS_FADE)
	tween.tween_callback(func() -> void:
		if is_instance_valid(node3d):
			node3d.queue_free())


# ---------------------------------------------------------------- upkeep

func _upkeep_tick() -> void:
	var living := living_count()
	var amount := living * UPKEEP_PER_CHAMPION
	var bank := EssenceBank.for_team(team) if amount > 0 else null
	var paid := amount == 0 or (bank != null and bank.can_afford(amount) and bank.spend(amount))
	if paid:
		_failed_ticks = 0
		if unpaid:
			_set_unpaid(false)
	else:
		_failed_ticks += 1
		if _failed_ticks >= UNPAID_AFTER and not unpaid:
			_set_unpaid(true)
			_say(MSG_UNPAID, false, 5.0)
	upkeep_ticked.emit(paid, amount)


func _set_unpaid(value: bool) -> void:
	unpaid = value
	for ch in champions:
		if is_instance_valid(ch) and &"is_unpaid" in ch:
			ch.set(&"is_unpaid", value)
	unpaid_changed.emit(value)


# ---------------------------------------------------------------- helpers

func _alive(ch: Node) -> bool:
	return ch != null and is_instance_valid(ch) and ch.has_method(&"is_alive") and bool(ch.call(&"is_alive"))


func _level_of(ch: Node) -> int:
	var l: Variant = ch.get(&"level") if ch and is_instance_valid(ch) else null
	return maxi(1, int(l)) if l != null else 1


## The champion's name: display_name, else ChampionType.names[variant], else its unit name.
func _name_of(ch: Node) -> String:
	if ch == null or not is_instance_valid(ch):
		return "A champion"
	var dn: Variant = ch.get(&"display_name")
	if dn is String and dn != "":
		return dn
	var r: Dictionary = _rec.get(ch, {})
	var type: Variant = ch.get(&"champion_type")
	if type is Object and r.has("variant"):
		var names: Variant = (type as Object).get(&"names")
		if (names is PackedStringArray or names is Array) and int(r["variant"]) < names.size():
			return String(names[int(r["variant"])])
	var un: Variant = ch.get(&"unit_name")
	return String(un) if un != null else "A champion"


## Sets the purse to exactly `amount` through the Champion API (add_purse / spend_purse), else the field.
func _set_purse(ch: Node, amount: int) -> void:
	var cur_v: Variant = ch.get(&"purse")
	if cur_v == null:
		return
	var cur := int(cur_v)
	if cur == amount:
		return
	if amount > cur and ch.has_method(&"add_purse"):
		ch.call(&"add_purse", amount - cur)
	elif amount < cur and ch.has_method(&"spend_purse"):
		ch.call(&"spend_purse", cur - amount)
	if int(ch.get(&"purse")) != amount:
		ch.set(&"purse", amount)


## `p` moved onto the navmesh when a navmesh point is within NAV_SNAP (the door is open ground).
func _snap(p: Vector3) -> Vector3:
	if not is_inside_tree():
		return p
	var map := get_viewport().find_world_3d().navigation_map if get_viewport() else RID()
	if not map.is_valid() or NavigationServer3D.map_get_iteration_id(map) == 0:
		return p
	var q := NavigationServer3D.map_get_closest_point(map, p)
	if Vector2(q.x - p.x, q.z - p.z).length() <= NAV_SNAP:
		return Vector3(q.x, p.y, q.z)
	return p


func _visible_to_local(pos: Vector3) -> bool:
	var fog := FogOfWar.find()
	return fog == null or fog.is_visible(local_team, pos)


## Emits `message` when the local team should read it (its own guild; `force` for lines about the other
## side that were already filtered, e.g. an enemy hire in sight).
func _say(text: String, force: bool = false, seconds: float = 4.0) -> void:
	if force or team == local_team:
		message.emit(text, seconds)
