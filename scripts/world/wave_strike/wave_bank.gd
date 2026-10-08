class_name WaveBank
extends Node
## One Wave Strike player's money (docs/design/wave-strike.md 4.2, 7.3): wraps the team's Economy (crystals), the
## Coffer levels, the income formula (base + Coffers, + the underdog tithe) and the bounty book. Group "wave_banks".
## 1v1: seat = team (0 PLAYER, 1 ENEMY); the seat model of team modes comes in M3.

signal changed

var seat := 0
var team: int = Unit.Team.PLAYER
var rules: WaveStrikeRules
var economy: Economy
var coffer_level := 0
var earned_total := 0          ## income + bounty since the start (score / reports)
var bounty_total := 0
var spent_total := 0
var last_income := 0           ## the last horn's income (HUD)
var underdog_mult := 0.0       ## the current tithe (0 - 0.24), set by the director before paying


func setup(p_seat: int, p_team: int, p_rules: WaveStrikeRules, p_economy: Economy) -> void:
	seat = p_seat
	team = p_team
	rules = p_rules
	economy = p_economy
	name = "WaveBank%d" % seat
	add_to_group(&"wave_banks")
	if economy:
		economy.crystals = rules.start_crystals
		economy.changed.emit()


static func for_seat(tree: SceneTree, p_seat: int) -> WaveBank:
	if tree == null:
		return null
	for n in tree.get_nodes_in_group(&"wave_banks"):
		if n is WaveBank and (n as WaveBank).seat == p_seat:
			return n
	return null


func crystals() -> int:
	return economy.crystals if economy else 0


func can_afford(cost: int) -> bool:
	return economy != null and economy.crystals >= cost


func spend(cost: int) -> bool:
	if economy == null or cost < 0 or not economy.spend(cost):
		return false
	spent_total += cost
	changed.emit()
	return true


func refund(amount: int) -> void:
	if economy and amount > 0:
		economy.add(amount)
		spent_total -= amount
		changed.emit()


## Income of the next horn: base + Coffers, x (1 + tithe).
func income() -> int:
	var base := rules.base_income + coffer_level * rules.coffer_step
	return int(roundf(base * (1.0 + underdog_mult)))


## Pays one horn's income. Returns the amount.
func pay_income() -> int:
	last_income = income()
	if economy:
		economy.add(last_income)
	earned_total += last_income
	changed.emit()
	return last_income


func add_bounty(amount: int) -> void:
	if amount <= 0 or economy == null:
		return
	economy.add(amount)
	bounty_total += amount
	earned_total += amount
	changed.emit()


## Price of the next Coffer level (-1 = all 8 bought).
func coffer_price() -> int:
	return rules.coffer_price(coffer_level)


## "" = can buy, else the reason.
func can_buy_coffer() -> String:
	var p := coffer_price()
	if p < 0:
		return "Coffers maxed"
	if not can_afford(p):
		return "Not enough crystals"
	return ""


func buy_coffer() -> String:
	var why := can_buy_coffer()
	if why != "":
		return why
	spend(coffer_price())
	coffer_level += 1
	changed.emit()
	return ""


# ---------------------------------------------------------------- save / load (docs/design/save-load.md)

## The crystals themselves live in the Economy (saved with the teams).
func save_state() -> Dictionary:
	return {"coffer_level": coffer_level, "earned_total": earned_total, "bounty_total": bounty_total,
			"spent_total": spent_total, "last_income": last_income, "underdog_mult": underdog_mult}


func load_state(d: Dictionary) -> void:
	coffer_level = int(d.get("coffer_level", coffer_level))
	earned_total = int(d.get("earned_total", earned_total))
	bounty_total = int(d.get("bounty_total", bounty_total))
	spent_total = int(d.get("spent_total", spent_total))
	last_income = int(d.get("last_income", last_income))
	underdog_mult = float(d.get("underdog_mult", underdog_mult))
