class_name AIChampions
extends RefCounted
## Rule 9 of the bot (docs/design/champions.md section 10, task 9.C9): hires, revives and bounty flags.
## Owned by the Commander, one per bot; it only uses public APIs (ChampionGuild, BountyBoard, EssenceBank,
## Economy). The champions themselves are driven by their ChampionBrain: the Commander never orders them
## (it skips every unit whose is_commandable() is false) and only counts their power() in its strengths.
## - Hire: the next archetype of ai.champion_order while the roster (alive, reviving, fallen, on its way) is
##   below ai.champion_max, from ai.champion_earliest, when crystals >= price + 150, essence >= price (after a
##   held revive), no build waits for those crystals, and the tavern the champion would walk out of (door
##   nearer the wizard, else the keep) is not held. While a hire is due (plan()) the Commander keeps price + 150
##   crystals from training (the build 20 s rule still lets one unit through), 2 pop free, and the essence
##   price away from the wizard's items.
## - Revive: a fallen champion as soon as the essence allows. ai.revive_before_items (normal / hard): its cost
##   is held from the wizard's items meanwhile; easy: only with the next item paid too (revive_affordable).
## - Bounties B1-B4, one per tick, the first whose trigger holds and whose flag fits the budget:
##   active stakes + the new stake <= ai.bounty_budget_pct x (essence - next item price - held essence), and
##   at most ai.bounty_max_flags flags. Easy: B1 only. Only what the team sees now (AIMemory.seen_now, its
##   fog) triggers a flag. The bot never removes a flag: they end by their own rules.
## - Trade (10.A3, market-trade.md 7): 10h revives a fallen champion in gold (2 gold per essence) when the essence
##   is short and ai.gold_revive (normal / hard); ai.gold_hire (hard) pays a hire's crystal part in gold when gold
##   >= that part + 100 (no crystals are then kept for the hire). At most one gold purchase per think tick
##   (trade.gold_spend_ok()). Flags from ai.trade_flags after B3: B5 Escort 50 on a loaded far caravan (one at a
##   time), B6 Hunt 75 on a seen Magpie carrying loot within 30 m of a bot champion, B7 Guard 50 on the forward
##   hall of a remote node raided in the last 60 s.
## - Map fill (12.A1, map-fill.md 7): flags from ai.mapfill_flags after the trade flags, triggers from
##   AIMapFill.flag_candidates(): B8 Explore (Claim) 25 on a neutral / enemy-held own-bank tower no squad is going
##   to, B9 Hunt 75 on the strongest creature of the stag / hollow the army creeps (hard), B10 Guard 50 on an own-held
##   well an enemy was seen near in 30 s, B11 Hunt 100 (hard 150) on the beast the army goes for. One flag per rule.

const HIRE_CRYSTAL_MARGIN := 150      ## Hire when crystals >= price + this (champions.md 10).
const STRENGTH_RADIUS := 20.0         ## Own champions this close to the rally count in own_strength.
const GUARD_STAKE := 50               ## B1
const RAID_STAKE := 100               ## B2
const WIZARD_STAKE := 150             ## B3
const EXPLORE_STAKE := 25             ## B4
const HALL_RADIUS := 10.0             ## B2: a seen enemy barracks this close to its natural / rich hall spot.
const NODE_RADIUS := 8.0              ## B2: enemy workers this close to a crystal node are "at" it.
const FAR_FROM_KEEP := 30.0           ## B2: ...a node further than this from their keep.
const RAID_WORKERS := 3
const WIZARD_LOW := 0.4               ## B3: the enemy wizard below this HP share...
const WIZARD_NEAR := 30.0             ## ...within this of a living bot champion.
const EXPLORE_EVERY := 120.0          ## B4: at most one Explore flag per this many seconds.
const EXPLORE_MERGE := 8.0            ## B4: no new flag where an own Explore flag already stands this close.
const SAMPLES_KEPT := 2000
const ESCORT_STAKE := 50              ## B5 (10.A3)
const LOOTER_STAKE := 75              ## B6
const RAID_GUARD_STAKE := 50          ## B7
const LOOTER_RADIUS := 30.0           ## B6: a looter this close to a bot champion.
const RAID_WINDOW := 60.0             ## B7: a raid this recent.
const GOLD_HIRE_MARGIN := 100         ## 10h (hard): hire in gold when gold >= the crystal part + this.

## 10.A3: the Commander's trade rule (null: no trade). Read by the gold revive / hire and B5-B7.
var trade: AITrade = null
## 12.A1: the Commander's map-fill rules (null: none). Read by B8-B11.
var mapfill: AIMapFill = null
## Gold revives paid: {"id", "time", "gold"}; gold hires: {"id", "time", "gold"}. Read only.
var gold_revives: Array[Dictionary] = []
var gold_hires: Array[Dictionary] = []

## Every hire paid: {"id": StringName, "time": float, "name": String, "crystals": int, "essence": int}.
var hires: Array[Dictionary] = []
## Every revive paid: {"id": StringName, "time": float, "cost": int}.
var revives: Array[Dictionary] = []
## Every flag placed: {"rule": "B1".."B4", "kind": int, "stake": int, "time": float, "target": Node3D or null,
## "pos": Vector3, "bounty": Bounty, "surplus": int, "active_before": int, "budget": float}.
var flags: Array[Dictionary] = []
## The archetype the bot is saving for (&"" = no hire due). Read only.
var hire_due: StringName = &""
## Most champions the team's roster ever held (sampled every tick). Read only.
var max_roster := 0
## Perf: microseconds of decisions in plan() + tick() (the paid actions guild.hire / revive and board.place
## excluded, like the Commander excludes BuildGrid.place), tick() calls, the last per-tick costs. Read only.
var usec_total := 0
var tick_count := 0
var usec_samples := PackedInt32Array()

var _team := 0
var _enemy_team := 1
var _ai: AIProfile
var _hire_essence := 0                 # essence the due hire holds from the wizard's items
var _revive_hold := 0                  # essence the fallen champions hold (revive_before_items only)
var _raid_flag: Variant = null         # B2: the one active raid flag (Bounty, may be freed)
var _last_explore := -INF
var _spots: Array[Vector3] = []        # B4: the enemy natural and rich hall spots
var _spot_seen: Array[float] = []      # B4: match time each spot was last visible
var _notes := {}                       # key -> last logged refusal (logged once per change)
var _guild: ChampionGuild = null       # cached lookups (re-found when freed)
var _bank_ref: EssenceBank = null
var _board_ref: BountyBoard = null
var _plan_usec := 0
var _action_usec := 0                  # this tick's paid actions (not counted as decision cost)
var _escort_flag: Variant = null       # B5: the one active Escort flag on a far caravan (Bounty, may be freed)
var _map_flags := {}                   # B8-B11: rule -> its active Bounty (may be freed; one per rule)


func _init(team: int, enemy_team: int, profile: AIProfile) -> void:
	_team = team
	_enemy_team = enemy_team
	_ai = profile


## The profile may change on the Commander's first tick (kingdom profile).
func set_profile(profile: AIProfile) -> void:
	_ai = profile


## The team's ChampionGuild, or null (no taverns on this map, or a profile that never hires).
func guild() -> ChampionGuild:
	if _ai == null or _ai.champion_max <= 0:
		return null
	if _guild == null or not is_instance_valid(_guild) or _guild.is_queued_for_deletion():
		_guild = ChampionGuild.for_team(_team)
	return _guild


func _bank() -> EssenceBank:
	if _bank_ref == null or not is_instance_valid(_bank_ref) or _bank_ref.is_queued_for_deletion():
		_bank_ref = EssenceBank.for_team(_team)
	return _bank_ref


func _board() -> BountyBoard:
	if _board_ref == null or not is_instance_valid(_board_ref) or _board_ref.is_queued_for_deletion():
		_board_ref = BountyBoard.for_team(_team)
	return _board_ref


## The next archetype of the hire order not in the roster yet (&"" when the roster is full for this profile).
func next_hire(g: ChampionGuild) -> StringName:
	if g == null or g.roster_size() >= mini(_ai.champion_max, ChampionGuild.MAX_CHAMPIONS):
		return &""
	for id in _ai.champion_order:
		var sid := StringName(id)
		if ChampionGuild.ARCHETYPES.has(sid) and not g.has_archetype(sid):
			return sid
	return &""


## Called early in each think tick (Commander._compute_pending): sets hire_due and the essence holds.
## Returns the crystals a due hire needs kept from training (price + 150), 0 when no hire is due.
func plan(now: float) -> int:
	var t0 := Time.get_ticks_usec()
	hire_due = &""
	_hire_essence = 0
	_revive_hold = 0
	var g := guild()
	var keep_crystals := 0
	if g != null:
		max_roster = maxi(max_roster, g.roster_size())
		if _ai.revive_before_items:
			for ch: Variant in g.champions:
				if ch != null and is_instance_valid(ch) and g.is_fallen(ch) and not g.is_reviving(ch):
					_revive_hold += g.revive_cost(ch)
		if now >= _ai.champion_earliest and g.is_open():
			hire_due = next_hire(g)
			if hire_due != &"":
				var cost := g.hire_cost(hire_due)
				_hire_essence = int(cost["essence"])
				keep_crystals = int(cost["crystals"]) + HIRE_CRYSTAL_MARGIN
				if _gold_hire_ok(g):
					keep_crystals = 0   # 10h (hard): the gold pays the crystal part
	_plan_usec = Time.get_ticks_usec() - t0
	return keep_crystals


## Essence the wizard's items must leave in the bank: the due hire's price + (normal / hard) fallen revives.
func essence_hold() -> int:
	return _hire_essence + _revive_hold


## Population the Commander keeps free for the due hire (ChampionGuild.POP, else 0).
func pop_reserve() -> int:
	return ChampionGuild.POP if hire_due != &"" else 0


## A revive of `cost` may be paid with `essence`: before items (normal / hard) as soon as it is affordable;
## after items (easy) only when the next item (`item_price`, 0 = none) is paid for too.
static func revive_affordable(essence: int, cost: int, item_price: int, before_items: bool) -> bool:
	return essence >= cost + (0 if before_items else maxi(item_price, 0))


## Rule 9 for one think tick: revive, hire, one bounty flag. `item_price` = the essence of the wizard's next
## item (0 = none), `build_cost` = crystals of the build row waiting (0 = none), `intruder_pos` = rule 1's
## intruder while defending (INF otherwise). Returns log lines.
func tick(now: float, level: Skirmish, memory: AIMemory, fog: FogOfWar, item_price: int, build_cost: int,
		own_buildings: Array[Building], defending: bool, intruder_pos: Vector3, group_out: bool) -> Array[String]:
	var out: Array[String] = []
	_action_usec = 0
	var g := guild()
	if g == null or level == null:
		return out
	var t0 := Time.get_ticks_usec()
	_revive(g, now, item_price, out)
	_hire(g, now, level, build_cost, out)
	_bounties(g, now, level, memory, fog, item_price, own_buildings, defending, intruder_pos, group_out, out)
	max_roster = maxi(max_roster, g.roster_size())
	var spent := _plan_usec + Time.get_ticks_usec() - t0 - _action_usec
	usec_total += spent
	tick_count += 1
	usec_samples.append(spent)
	if usec_samples.size() > SAMPLES_KEPT:
		usec_samples.remove_at(0)
	return out


## 20.A3: microseconds of the paid actions (hire / revive spawns, flag placement) in the last tick(): the Commander
## leaves them out of its think cost like BuildGrid.place (a player's hire costs the same).
func last_action_usec() -> int:
	return _action_usec


## Median decision cost of the last think ticks (plan + tick, paid hires / revives / flags excluded), in ms.
func median_ms() -> float:
	if usec_samples.is_empty():
		return 0.0
	var s := usec_samples.duplicate()
	s.sort()
	return float(s[s.size() / 2]) / 1000.0


## The tavern a hire now would walk out of: the one whose door is nearer the living wizard (else the keep,
## else the base centre). Null without taverns.
func chosen_tavern(level: Skirmish) -> Node3D:
	var ref := level.base_center(_team)
	var w := level.wizard_of(_team)
	if w != null and is_instance_valid(w) and w.is_alive():
		ref = w.global_position
	else:
		var k := level.keep_of(_team)
		if k != null:
			ref = k.global_position
	var best: Node3D = null
	var best_d := INF
	for t: Variant in Tavern.all():
		var tavern := t as Tavern
		if tavern == null:
			continue
		var d := _flat(tavern.door_point(), ref)
		if d < best_d:
			best_d = d
			best = tavern
	return best


# ---------------------------------------------------------------- revive / hire

func _revive(g: ChampionGuild, now: float, item_price: int, out: Array[String]) -> void:
	var bank := _bank()
	if bank == null:
		return
	for ch: Variant in g.champions:   # revive() never changes the roster array
		if ch == null or not is_instance_valid(ch) or not g.is_fallen(ch) or g.is_reviving(ch):
			continue
		var cost := g.revive_cost(ch)
		if not revive_affordable(bank.essence, cost, item_price, _ai.revive_before_items):
			if bank.essence < cost:
				_gold_revive(g, ch, now, out)   # 10h: essence short -> gold (normal / hard)
			continue
		var a0 := Time.get_ticks_usec()
		var reason := g.revive(ch)
		_action_usec += Time.get_ticks_usec() - a0
		if reason != "":
			_note(out, "revive", "CHAMPION revive of %s refused: %s" % [_name(ch), reason])
			continue
		revives.append({"id": g.archetype_of(ch), "time": now, "cost": cost})
		_revive_hold = maxi(0, _revive_hold - cost)
		out.append("CHAMPION revive %s for %d essence, back in %.0f s" % [_name(ch), cost, g.revive_time_left(ch)])


## 10h: revive `ch` in gold (2 gold per essence) when ai.gold_revive and the gold is there. True if paid.
func _gold_revive(g: ChampionGuild, ch: Variant, now: float, out: Array[String]) -> bool:
	if not _ai.gold_revive or trade == null or not trade.active() or not trade.gold_spend_ok():
		return false
	var gb := trade.bank()
	var price := g.revive_cost(ch, true)
	if gb == null or gb.gold < price:
		return false
	var a0 := Time.get_ticks_usec()
	var reason := g.revive(ch, true)
	_action_usec += Time.get_ticks_usec() - a0
	if reason != "":
		_note(out, "revive_gold", "CHAMPION gold revive of %s refused: %s" % [_name(ch), reason])
		return false
	trade.note_gold_spent()
	var essence_cost := g.revive_cost(ch)
	revives.append({"id": g.archetype_of(ch), "time": now, "cost": 0, "gold": price})
	gold_revives.append({"id": g.archetype_of(ch), "time": now, "gold": price})
	_revive_hold = maxi(0, _revive_hold - essence_cost)
	out.append("CHAMPION revive %s for %d gold (essence short), back in %.0f s" % [_name(ch), price,
			g.revive_time_left(ch)])
	return true


## 10h (hard): a due hire may be paid in gold: ai.gold_hire, and gold >= the crystal part + 100.
func _gold_hire_ok(g: ChampionGuild) -> bool:
	if not _ai.gold_hire or trade == null or not trade.active() or hire_due == &"":
		return false
	var gb := trade.bank()
	return gb != null and gb.gold >= int(g.hire_cost(hire_due, true)["gold"]) + GOLD_HIRE_MARGIN


func _hire(g: ChampionGuild, now: float, level: Skirmish, build_cost: int, out: Array[String]) -> void:
	if hire_due == &"":
		return
	var eco := Economy.for_team(_team)
	var bank := _bank()
	if eco == null or bank == null:
		return
	if _gold_hire_ok(g) and trade.gold_spend_ok():
		_hire_in_gold(g, now, level, out)
		return
	var id := hire_due
	var cost := g.hire_cost(id)
	var crystals := int(cost["crystals"])
	var essence := int(cost["essence"])
	if eco.crystals < crystals + HIRE_CRYSTAL_MARGIN or bank.essence - _revive_hold < essence:
		return
	if build_cost > 0 and eco.crystals - crystals < build_cost:
		return   # a triggered build waits for these crystals (the 20 s rule's build comes first)
	var tavern := chosen_tavern(level)
	if tavern == null or g.is_tavern_held(tavern):
		_note(out, "hire", "CHAMPION hire of %s waits: the tavern is held" % id)
		return
	var before := eco.crystals
	var a0 := Time.get_ticks_usec()
	var reason := g.hire(id)
	_action_usec += Time.get_ticks_usec() - a0
	if reason != "":
		_note(out, "hire", "CHAMPION hire of %s refused: %s" % [id, reason])
		return
	_notes.erase("hire")
	hires.append({"id": id, "time": now, "name": g.name_for(id), "crystals": crystals, "essence": essence})
	out.append("CHAMPION hire %s (%s) #%d: %d crystals + %d essence, crystals %d -> %d, from %s" % [id,
			g.name_for(id), g.roster_size(), crystals, essence, before, eco.crystals, _xz(tavern.global_position)])
	hire_due = &""
	_hire_essence = 0


## 10h (hard): the due hire with its crystal part paid in gold (the essence part as usual).
func _hire_in_gold(g: ChampionGuild, now: float, level: Skirmish, out: Array[String]) -> void:
	var id := hire_due
	var cost := g.hire_cost(id, true)
	var bank := _bank()
	if bank.essence - _revive_hold < int(cost["essence"]):
		return
	var tavern := chosen_tavern(level)
	if tavern == null or g.is_tavern_held(tavern):
		_note(out, "hire", "CHAMPION hire of %s waits: the tavern is held" % id)
		return
	var a0 := Time.get_ticks_usec()
	var reason := g.hire(id, true)
	_action_usec += Time.get_ticks_usec() - a0
	if reason != "":
		_note(out, "hire", "CHAMPION gold hire of %s refused: %s" % [id, reason])
		return
	_notes.erase("hire")
	trade.note_gold_spent()
	hires.append({"id": id, "time": now, "name": g.name_for(id), "crystals": 0, "essence": int(cost["essence"]),
			"gold": int(cost["gold"])})
	gold_hires.append({"id": id, "time": now, "gold": int(cost["gold"])})
	out.append("CHAMPION hire %s (%s) #%d in gold: %d gold + %d essence, from %s" % [id, g.name_for(id),
			g.roster_size(), int(cost["gold"]), int(cost["essence"]), _xz(tavern.global_position)])
	hire_due = &""
	_hire_essence = 0


# ---------------------------------------------------------------- bounties (B1-B4)

func _bounties(g: ChampionGuild, now: float, level: Skirmish, memory: AIMemory, fog: FogOfWar, item_price: int,
		own_buildings: Array[Building], defending: bool, intruder_pos: Vector3, group_out: bool,
		out: Array[String]) -> void:
	_update_spots(now, level, fog)
	var living: Array[Node3D] = []
	for ch: Variant in g.champions:
		if ch != null and is_instance_valid(ch) and (ch as Unit).is_alive():
			living.append(ch as Node3D)
	if living.is_empty():
		return
	var board := _board()
	if board == null or board.bounties.size() >= _ai.bounty_max_flags:
		return
	var bank := _bank()
	if bank == null:
		return
	var surplus := bank.essence - maxi(item_price, 0) - essence_hold()
	var active := 0
	for b in board.bounties:
		active += b.stake
	var budget := _ai.bounty_budget_pct * float(surplus)
	if float(active + mini(GUARD_STAKE, EXPLORE_STAKE)) > budget + 0.001:
		return   # not even the smallest flag fits (the usual case while the wizard buys items)
	var ctx := {"now": now, "surplus": surplus, "active": active, "budget": budget}
	# B1: rule 1 intrusion on a building and no Guard flag -> Guard 50 on that building (easy too).
	if defending and intruder_pos != Vector3.INF and _fits(ctx, GUARD_STAKE) and not _has_kind(board, Bounty.GUARD):
		var hit := _intruded_building(own_buildings, intruder_pos)
		if hit != null and _place(board, "B1", Bounty.GUARD, hit, hit.global_position, GUARD_STAKE, ctx, out):
			return
	if _ai.bounty_guard_only:
		return
	var seen: Array[Unit] = []
	if memory:
		seen = memory.seen_now(now)
	# B2: no attack group out; a seen enemy forward hall, or 3+ seen enemy workers at a node > 30 m from their
	# keep -> Hunt 100 on the hall / the nearest of those workers (one such flag at a time).
	if not group_out and _fits(ctx, RAID_STAKE) and not _raid_active():
		var raid := _raid_target(level, memory, seen, living)
		if raid != null and board.bounty_on(raid) == null \
				and _place(board, "B2", Bounty.HUNT, raid, raid.global_position, RAID_STAKE, ctx, out):
			_raid_flag = board.bounty_on(raid)
			return
	# B3: the enemy wizard seen below 40 % HP within 30 m of a bot champion -> Hunt 150 on her.
	if _fits(ctx, WIZARD_STAKE):
		var wiz := _weak_wizard(seen, living)
		if wiz != null and board.bounty_on(wiz) == null \
				and _place(board, "B3", Bounty.HUNT, wiz, wiz.global_position, WIZARD_STAKE, ctx, out):
			return
	# B5-B7 (10.A3, market-trade.md 7): the trade flags of this profile.
	if _trade_flags(board, own_buildings, living, ctx, out):
		return
	# B8-B11 (12.A1, map-fill.md 7): the map-fill flags of this profile.
	if _mapfill_flags(board, memory, ctx, out):
		return
	# B4: the enemy natural or rich hall spot unseen for ai.explore_unseen s -> Explore 25 there, every 120 s.
	if now - _last_explore >= EXPLORE_EVERY and _fits(ctx, EXPLORE_STAKE):
		var spot := _unseen_spot(now, board)
		if spot != Vector3.INF and _place(board, "B4", Bounty.EXPLORE, null, spot, EXPLORE_STAKE, ctx, out):
			_last_explore = now


func _fits(ctx: Dictionary, stake: int) -> bool:
	return float(int(ctx["active"]) + stake) <= float(ctx["budget"]) + 0.001


## B5-B7 (ai.trade_flags): the first that applies places its flag (true).
func _trade_flags(board: BountyBoard, own_buildings: Array[Building], living: Array[Node3D], ctx: Dictionary,
		out: Array[String]) -> bool:
	if trade == null or not trade.active() or _ai.trade_flags.is_empty():
		return false
	var flags_on := _ai.trade_flags
	# B5: a loaded caravan on a far route and no such flag -> Escort 50 on it (one at a time).
	if flags_on.has("B5") and _fits(ctx, ESCORT_STAKE) and not _escort_active():
		var c := trade.far_loaded_caravan()
		if c != null and board.bounty_on(c) == null \
				and _place(board, "B5", Bounty.ESCORT, c, c.global_position, ESCORT_STAKE, ctx, out):
			_escort_flag = board.bounty_on(c)
			return true
	# B6: a seen Magpie carrying loot within 30 m of a bot champion -> Hunt 75 on it.
	if flags_on.has("B6") and _fits(ctx, LOOTER_STAKE):
		var m := trade.looter_near(living, LOOTER_RADIUS)
		if m != null and board.bounty_on(m) == null \
				and _place(board, "B6", Bounty.HUNT, m, m.global_position, LOOTER_STAKE, ctx, out):
			return true
	# B7: a remote node raided in the last 60 s with an own forward hall -> Guard 50 on that hall.
	if flags_on.has("B7") and _fits(ctx, RAID_GUARD_STAKE):
		var hall := trade.raided_hall(RAID_WINDOW, own_buildings)
		if hall != null and board.bounty_on(hall) == null \
				and _place(board, "B7", Bounty.GUARD, hall, hall.global_position, RAID_GUARD_STAKE, ctx, out):
			return true
	return false


## B8-B11 (ai.mapfill_flags): the first candidate of AIMapFill whose rule has no active flag places it (true).
func _mapfill_flags(board: BountyBoard, memory: AIMemory, ctx: Dictionary, out: Array[String]) -> bool:
	if mapfill == null or _ai.mapfill_flags.is_empty() or not mapfill.active():
		return false
	for c: Dictionary in mapfill.flag_candidates(float(ctx["now"]), memory):
		var rule := str(c["rule"])
		if not _ai.mapfill_flags.has(rule) or _map_flag_active(rule):
			continue
		var stake := int(c["stake"])
		if not _fits(ctx, stake):
			continue
		var target: Node3D = c["target"]
		var pos: Vector3 = c["pos"]
		if target != null and board.bounty_on(target) != null:
			continue
		if target == null and _explore_flag_near(board, pos) != null:
			continue
		if _place(board, rule, int(c["kind"]), target, pos, stake, ctx, out):
			_map_flags[rule] = board.bounty_on(target) if target != null else _explore_flag_near(board, pos)
			return true
	return false


func _map_flag_active(rule: String) -> bool:
	var b: Variant = _map_flags.get(rule)
	return b != null and is_instance_valid(b) and not (b as Bounty).ended


func _escort_active() -> bool:
	return _escort_flag != null and is_instance_valid(_escort_flag) and not (_escort_flag as Bounty).ended


func _place(board: BountyBoard, rule: String, kind: int, target: Node3D, pos: Vector3, stake: int, ctx: Dictionary,
		out: Array[String]) -> bool:
	var a0 := Time.get_ticks_usec()
	var reason := board.place(kind, target, pos, stake)
	_action_usec += Time.get_ticks_usec() - a0
	if reason != "":
		_note(out, rule, "BOUNTY %s refused: %s" % [rule, reason])
		return false
	_notes.erase(rule)
	var b := board.bounty_on(target) if target != null else _explore_flag_near(board, pos)
	flags.append({"rule": rule, "kind": kind, "stake": stake, "time": float(ctx["now"]), "target": target,
			"pos": pos, "bounty": b, "surplus": int(ctx["surplus"]), "active_before": int(ctx["active"]),
			"budget": float(ctx["budget"])})
	out.append("BOUNTY %s %s %d on %s (stakes %d + %d <= %.0f of %d spare essence)" % [rule,
			Bounty.KIND_NAMES[kind], stake, BountyBoard.name_of(target) if target else _xz(pos), int(ctx["active"]),
			stake, float(ctx["budget"]), int(ctx["surplus"])])
	return true


func _has_kind(board: BountyBoard, kind: int) -> bool:
	for b in board.bounties:
		if b.kind == kind and not b.ended:
			return true
	return false


## The own completed building nearest the intruder (walls last: never a Guard target).
func _intruded_building(own_buildings: Array[Building], pos: Vector3) -> Building:
	var best: Building = null
	var best_d := INF
	for b in own_buildings:
		if b == null or not is_instance_valid(b) or not b.is_alive() or not b.is_constructed() or b.building_type == null:
			continue
		if b.building_type.kind == &"wall":
			continue
		var d := _flat(b.global_position, pos)
		if d < best_d:
			best_d = d
			best = b
	return best


func _raid_active() -> bool:
	return _raid_flag != null and is_instance_valid(_raid_flag) and not (_raid_flag as Bounty).ended


## B2 target: a remembered enemy barracks at their natural / rich hall spot, else the seen enemy worker
## nearest to a bot champion among 3+ seen at one crystal node > 30 m from their keep. Null if none.
func _raid_target(level: Skirmish, memory: AIMemory, seen: Array[Unit], living: Array[Node3D]) -> Node3D:
	if memory:
		for spot in _hall_spots(level):
			var hall := memory.nearest_building(spot, HALL_RADIUS, &"barracks")
			if hall != null and hall.is_alive() and int(hall.team) == _enemy_team:
				return hall
	var workers: Array[Unit] = []
	for u in seen:
		if u.is_worker() and int(u.team) == _enemy_team:
			workers.append(u)
	if workers.size() < RAID_WORKERS:
		return null
	var their_keep := level.base_center(_enemy_team)
	var best: Unit = null
	var best_d := INF
	for node in level.get_tree().get_nodes_in_group("crystal_nodes"):
		var n := node as Node3D
		if n == null or _flat(n.global_position, their_keep) <= FAR_FROM_KEEP:
			continue
		var at: Array[Unit] = []
		for w in workers:
			if _flat(w.global_position, n.global_position) <= NODE_RADIUS:
				at.append(w)
		if at.size() < RAID_WORKERS:
			continue
		for w in at:
			var d := _nearest(w.global_position, living)
			if d < best_d:
				best_d = d
				best = w
	return best


## B3 target: the enemy wizard seen now below 40 % HP within 30 m of a living bot champion.
func _weak_wizard(seen: Array[Unit], living: Array[Node3D]) -> Unit:
	for u in seen:
		if u is Wizard and int(u.team) == _enemy_team and u.hp < WIZARD_LOW * u.max_hp \
				and _nearest(u.global_position, living) <= WIZARD_NEAR:
			return u
	return null


## The enemy natural and rich hall spots (B2 halls, B4 explore points).
func _hall_spots(level: Skirmish) -> Array[Vector3]:
	if _spots.is_empty():
		_spots.append(level.natural_hall_spot(_enemy_team))
		if level.has_method(&"rich_hall_spot"):
			_spots.append(level.rich_hall_spot(_enemy_team))
		_spot_seen.clear()
		for i in _spots.size():
			_spot_seen.append(0.0)   # "not seen" counts from the match start
	return _spots


## B4 memory: a spot counts as seen while its fog cell is VISIBLE for the team (no fog: always seen).
func _update_spots(now: float, level: Skirmish, fog: FogOfWar) -> void:
	var spots := _hall_spots(level)
	for i in spots.size():
		if fog == null or fog.is_visible(_team, spots[i]):
			_spot_seen[i] = now


## The hall spot unseen the longest, if unseen for ai.explore_unseen s and free of an own Explore flag.
func _unseen_spot(now: float, board: BountyBoard) -> Vector3:
	var best := Vector3.INF
	var best_gap := -INF
	for i in _spots.size():
		var gap := now - _spot_seen[i]
		if gap < _ai.explore_unseen or gap <= best_gap or _explore_flag_near(board, _spots[i]) != null:
			continue
		best_gap = gap
		best = _spots[i]
	return best


func _explore_flag_near(board: BountyBoard, pos: Vector3) -> Bounty:
	for b in board.bounties:
		if b.kind == Bounty.EXPLORE and not b.ended and _flat(b.global_position, pos) <= EXPLORE_MERGE:
			return b
	return null


# ---------------------------------------------------------------- helpers

func _note(out: Array[String], key: String, text: String) -> void:
	if str(_notes.get(key, "")) == text:
		return
	_notes[key] = text
	out.append(text)


static func _nearest(pos: Vector3, nodes: Array[Node3D]) -> float:
	var best := INF
	for n in nodes:
		best = minf(best, _flat(n.global_position, pos))
	return best


static func _name(ch: Variant) -> String:
	return BountyBoard.name_of(ch as Node)


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


static func _xz(p: Vector3) -> String:
	return "(%d, %d)" % [roundi(p.x), roundi(p.z)]
