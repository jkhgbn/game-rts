class_name WaveDirector
extends Node
## The Wave Strike horn clock (docs/design/wave-strike.md 4.1, 7.3). Group "wave_director".
## Its own game clock (`time`, advanced in _physics_process: a paused tree holds it). First horn at rules.horn_first,
## then every horn_interval s (every last_horns_interval s from last_horns_at). At each horn: 1) every bank is paid
## (base + Coffers, + the underdog tithe); 2) every roster's cards go to its LaneSpawner (one unit per card, staggered);
## 3) sold pop is freed; 4) wizards get rules.wizard_horn_xp. Signals `horn(index)`, `horn_soon(seconds)` (once per
## horn at rules.horn_warning s).

signal horn(index: int)
signal horn_soon(seconds: float)

var rules: WaveStrikeRules
var level: Node                         ## WaveStrikeLevel (bastions, wizards); untyped
var banks: Array[WaveBank] = []         ## index = seat
var rosters: Array[MusterRoster] = []
var spawners: Array[LaneSpawner] = []
var time := 0.0
var horn_index := 0                     ## horns fired so far
var running := false
var last_wave_size: Array[int] = []     ## per seat: units queued at the last horn

var _warned_for := 0


func setup(p_rules: WaveStrikeRules, p_level: Node) -> void:
	rules = p_rules
	level = p_level
	name = "WaveDirector"
	add_to_group(&"wave_director")


static func instance(tree: SceneTree) -> WaveDirector:
	if tree == null:
		return null
	return tree.get_first_node_in_group(&"wave_director") as WaveDirector


func add_seat(bank: WaveBank, roster: MusterRoster, spawner: LaneSpawner) -> void:
	banks.append(bank)
	rosters.append(roster)
	spawners.append(spawner)
	last_wave_size.append(0)


func next_horn_time() -> float:
	return rules.horn_time(horn_index + 1)


func time_to_next_horn() -> float:
	return maxf(next_horn_time() - time, 0.0)


func is_last_horns() -> bool:
	return time >= rules.last_horns_at


func _physics_process(delta: float) -> void:
	if not running:
		return
	advance(delta)


## Moves the clock by `delta` s (tests call it directly with running = false).
func advance(delta: float) -> void:
	time += delta
	for r in rosters:
		r.tick(delta)
	for s in spawners:
		s.tick(delta)
	var to_horn := time_to_next_horn()
	if to_horn <= rules.horn_warning and _warned_for != horn_index + 1:
		_warned_for = horn_index + 1
		horn_soon.emit(to_horn)
	while time >= next_horn_time():
		_fire_horn()


func _fire_horn() -> void:
	horn_index += 1
	for seat in banks.size():
		var bank := banks[seat]
		bank.underdog_mult = _underdog(bank.team)
		bank.pay_income()
		var roster := rosters[seat]
		last_wave_size[seat] = roster.card_total()
		spawners[seat].queue_horn(roster)   # the Muster Pad snapshot (wave-strike.md 15.3)
		roster.on_horn()
	if level and level.has_method(&"on_horn"):
		level.call(&"on_horn", horn_index)
	horn.emit(horn_index)


## The underdog tithe of `team`: + rules.underdog_pct_per_step per full underdog_step of Bastion HP gap, capped.
func _underdog(team: int) -> float:
	if not rules.underdog_enabled or level == null or not level.has_method(&"bastion_ratio"):
		return 0.0
	var mine := float(level.call(&"bastion_ratio", team))
	var theirs := float(level.call(&"bastion_ratio", 1 - team))
	var steps := floori((theirs - mine) / rules.underdog_step + 0.0001)
	if steps <= 0:
		return 0.0
	return minf(steps * rules.underdog_pct_per_step, rules.underdog_max)
