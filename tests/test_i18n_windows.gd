extends SceneTree
## French layout check of the HUD windows (localization.md 4 "Length"; the UI Lab has no screens for them): a skirmish,
## then for the tavern (Y; empty rows, then one champion hired), the trade window (Bazaar and Lodge tabs), the keep
## shop (T) and the champion bar, UILabChecks.find_overflow / find_offscreen on the window's visible controls, first in
## English (the baseline), then in French (Loc.set_language("fr")). Fails on a French overflow / off-screen item that
## the English layout does not have (or that is more than 2 px worse). Every French item is printed.
## Run:  godot --headless --path . -s tests/test_i18n_windows.gd --fixed-fps 60 --quit-after 200000

const TASK_ID := "i18n_windows"
const SCENE := "res://scenes/skirmish.tscn"
const PLAYER := 0
const TOL := 2.0

var main: Node
var hud: Node
var _errors: Array[String] = []
var _report: Array[String] = []
var _checked := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	Loc.set_language("en")
	main = load(SCENE).instantiate()
	main.set(&"player_kingdom", &"fire")
	main.set(&"enemy_kingdom", &"shadow")
	main.set(&"camps_enabled", false)
	main.set(&"beasts_enabled", false)
	root.add_child(main)
	current_scene = main
	var t0 := Time.get_ticks_msec()
	while not bool(main.get(&"match_started")):
		await process_frame
		if Time.get_ticks_msec() - t0 > 180000:
			_finish("the skirmish never started")
			return
	await _frames(5)
	hud = main.get(&"hud")
	var hero: Node = main.get(&"hero")
	var path := StrIntPath.of(hero)
	if path != null and not path.is_locked():
		path.choose(&"str")
	paused = false
	Economy.for_team(PLAYER).add(60000)
	var ess := EssenceBank.for_team(PLAYER)
	if ess:
		ess.add(9000)
	for g in get_nodes_in_group(&"gold_banks"):
		if int(g.get(&"team")) == PLAYER and g.has_method(&"add"):
			g.call(&"add", 5000)
	for t in get_nodes_in_group(&"taverns"):
		t.set(&"open_time", 0.0)
	await _frames(3)
	var screens: Array[String] = ["tavern", "tavern_hired", "trade_bazaar", "trade_lodge", "shop", "champion_bar"]
	for s in screens:
		var en := await _measure(s, "en")
		var fr := await _measure(s, "fr")
		_compare(s, en, fr)
	Loc.set_language("en")
	_finish("")


## {key: px} of the overflow / off-screen items of `screen` in `lang` (key = kind + node path).
func _measure(screen: String, lang: String) -> Dictionary:
	Loc.set_language(lang)
	var scope: Control = await _show(screen)
	await _frames(3)
	var out := {}
	if scope == null:
		_errors.append("%s: could not open" % screen)
		return out
	var controls := UILabChecks.visible_controls(scope)
	for it: Dictionary in UILabChecks.find_overflow(controls):
		out["overflow " + _path(it["node"])] = [float(it["value"]), UILabChecks.text_of(it["node"])]
	# Out of the window's own rect (the headless screen is not 1600 x 900, so the window rect stands for the screen).
	if screen != "champion_bar":
		for it: Dictionary in UILabChecks.find_offscreen(controls, UILabChecks.control_rect(scope)):
			out["outside " + _path(it["node"])] = [float(it["value"]), UILabChecks.text_of(it["node"])]
	_checked += controls.size()
	_hide(screen)
	return out


func _compare(screen: String, en: Dictionary, fr: Dictionary) -> void:
	for k: String in fr:
		var v: float = fr[k][0]
		var base: float = en[k][0] if en.has(k) else -1.0
		if base < 0.0 or v > base + TOL:
			_report.append("  %s %s: %.0f px (en %s) '%s'" % [screen, k, v, "-" if base < 0.0 else "%.0f" % base, fr[k][1]])
			_errors.append("%s %s +%.0f px: '%s'" % [screen, k.get_slice(" ", 0), v - maxf(base, 0.0), fr[k][1]])


func _path(n: Node) -> String:
	return str(main.get_path_to(n)) if main.is_ancestor_of(n) else str(n.get_path())


func _show(screen: String) -> Control:
	var tw: TavernWindow = hud.get(&"tavern_window")
	var trade: TradeWindow = hud.get(&"trade_window")
	var shop: ShopWindow = hud.get(&"shop_window")
	match screen:
		"tavern":
			tw.open()
			tw.refresh()
			return tw
		"tavern_hired":
			tw.open()
			var g := tw.guild()
			if g != null and int(g.call(&"roster_size")) == 0:
				tw.press_hire(0)
				await _frames(2)
			tw.refresh()
			return tw
		"trade_bazaar":
			if trade == null or not trade.open(&"bazaar"):
				return null
			trade.refresh()
			return trade
		"trade_lodge":
			if trade == null or not trade.open(&"lodge"):
				return null
			trade.refresh()
			return trade
		"shop":
			if shop == null or not shop.open(main.get(&"keep")):
				return null
			return shop
		"champion_bar":
			var bar: ChampionBar = hud.get(&"champion_bar")
			if bar:
				bar.refresh()
			return bar
	return null


func _hide(screen: String) -> void:
	match screen:
		"tavern", "tavern_hired":
			(hud.get(&"tavern_window") as TavernWindow).close()
		"trade_bazaar", "trade_lodge":
			(hud.get(&"trade_window") as TradeWindow).close()
		"shop":
			(hud.get(&"shop_window") as ShopWindow).close()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _finish(fatal: String) -> void:
	if fatal != "":
		_errors.append(fatal)
	print("French layout items (%d controls checked):" % _checked)
	for l in _report:
		print(l)
	if _errors.is_empty():
		print("PASS %s (%d controls)" % [TASK_ID, _checked])
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors.slice(0, 30))])
	quit(0 if _errors.is_empty() else 1)
