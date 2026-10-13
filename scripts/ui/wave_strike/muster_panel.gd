class_name MusterPanel
extends Control
## The Wave Strike Muster panel (docs/design/ui-wave-strike.md 1-3, task WS2.U1), inside the SC2 console
## (ui-sc2-console.md 6: no frame of its own, it fills `console.zone_rect(&"muster")`; the spec's rects shifted by
## x - 346, y + 20 = local coordinates below with the zone at (244, 692)). Left to right: the 10 cards in three tier
## groups (T1 slots 1-5, T2 6-8, T3 9-10) with dividers and tier labels, the supply bar and the key hint under them;
## the right column (anchored to the zone's right edge) holds Coffer, next tier, the field counter and the next-wave
## size; the title row has `Muster` and the horn countdown + ring. The extra width between the cards and the column
## shows the kingdom emblem faintly. WaveStrikeHud owns the logic (keys, buys); this node only shows and forwards
## clicks: signal `card_action(slot, kind)`, `coffer_pressed`, `tier_pressed`.

signal card_action(slot: int, kind: StringName)
signal coffer_pressed
signal tier_pressed

const SLOTS := 10
const CARD_W := 72.0
const CARD_STEP := 78.0
const CARD_Y := 38.0
const GROUPS: Array[Vector2i] = [Vector2i(0, 5), Vector2i(5, 8), Vector2i(8, 10)]
const GROUP_X: Array[float] = [10.0, 410.0, 654.0]
const COL_W := 160.0
const COL_RIGHT := 12.0
const LEFT_W := 794.0
const EMBLEM_ALPHA := 0.07
## Lane autocast line of each kingdom caster (wave-strike.md 14.1 table).
const CASTER_LANE := {
	&"kilnwarden": "In the lane: Slag Rain, Mana Scald on auto",
	&"rimecarver": "In the lane: Rime Bulwark on auto · Scrying Rune off",
	&"bramblesage": "In the lane: Snagroot, Pollen Haze on auto",
	&"gloom_deacon": "In the lane: Blood Tithe on auto · Umbral Passage off",
}

var roster: MusterRoster
var bank: WaveBank
var director: WaveDirector
var level: Node
var cards: Array[MusterCard] = []
var coffer_button: MusterButton
var tier_button: MusterButton
var field_counter: WsFieldCounter
var horn_ring: HornRing
var supply_bar: ProgressBar
var card_keys: Array[int] = []
var coffer_key := KEY_G
var tier_key := KEY_U
var peek_key := KEY_I

var _title: Label
var _horn_label: Label
var _group_rows: Array[HBoxContainer] = []
var _group_names: Array[Label] = []
var _group_reasons: Array[Label] = []
var _group_locks: Array[Control] = []
var _supply_text: Label
var _next_cap: Label
var _hint: Label
var _wave_label: Label
var _last_counts: Array[int] = []
var _last_ranks: Array[int] = []
var _last_tier := 0
var _role_cache: Dictionary = {}


func setup(p_level: Node, p_roster: MusterRoster, p_bank: WaveBank, p_director: WaveDirector, p_card_keys: Array[int]) -> void:
	level = p_level
	roster = p_roster
	bank = p_bank
	director = p_director
	card_keys = p_card_keys
	name = "MusterPanel"
	mouse_filter = Control.MOUSE_FILTER_STOP   # the console under it already stops clicks; this keeps them here
	_build()
	_last_tier = roster.tier
	for i in SLOTS:
		_last_counts.append(-1)
		_last_ranks.append(-1)


func _build() -> void:
	_title = UIStyle.use_title_font(UIStyle.panel_label("", 20, UIStyle.token(&"title")))
	_title.position = Vector2(10, -5)
	_title.size = Vector2(300, 26)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	add_child(_title)
	_horn_label = UIStyle.panel_label("", 16)
	_horn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_horn_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_horn_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	add_child(_horn_label)
	horn_ring = HornRing.new(20.0)
	add_child(horn_ring)
	for g in GROUPS.size():
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 4)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(row)
		var nl := UIStyle.use_title_font(UIStyle.panel_label("", 12, UIStyle.token(&"text_muted")))
		nl.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(nl)
		var rl := UIStyle.panel_label("", 12, UIStyle.WARN)
		rl.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		rl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(rl)
		var lock := LockGlyph.new()
		row.add_child(lock)
		_group_rows.append(row)
		_group_names.append(nl)
		_group_reasons.append(rl)
		_group_locks.append(lock)
	for i in SLOTS:
		var c := MusterCard.new()
		c.slot = i
		c.name = "Card%d" % (i + 1)
		c.position = Vector2(card_x(i), CARD_Y)
		c.action.connect(func(s: int, kind: StringName) -> void: card_action.emit(s, kind))
		add_child(c)
		cards.append(c)
	var b: Array = UIStyle.bar(UIStyle.GOLD, 14.0)
	supply_bar = b[0]
	_supply_text = b[1]
	_supply_text.add_theme_font_size_override("font_size", 11)
	_supply_text.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	supply_bar.position = Vector2(10, 164)
	supply_bar.size = Vector2(LEFT_W, 14)
	add_child(supply_bar)
	_next_cap = UIStyle.number_label("", 10, UIStyle.token(&"text_muted"))
	_next_cap.position = Vector2(10 + LEFT_W + 8, 163)
	_next_cap.size = Vector2(30, 16)
	_next_cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_next_cap)
	_hint = UIStyle.panel_label("", 11, UIStyle.token(&"text_muted"))
	_hint.position = Vector2(10, 181)
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_hint.clip_text = true
	_hint.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_child(_hint)
	coffer_button = MusterButton.new()
	coffer_button.name = "Coffer"
	coffer_button.pressed.connect(func() -> void: coffer_pressed.emit())
	add_child(coffer_button)
	tier_button = MusterButton.new()
	tier_button.name = "NextTier"
	tier_button.pressed.connect(func() -> void: tier_pressed.emit())
	add_child(tier_button)
	field_counter = WsFieldCounter.new()
	field_counter.name = "FieldCounter"
	add_child(field_counter)
	_wave_label = UIStyle.panel_label("", 12, UIStyle.token(&"text_muted"))
	_wave_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wave_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_wave_label.clip_text = true
	_wave_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_child(_wave_label)
	_layout()


static func card_x(i: int) -> float:
	for g in GROUPS.size():
		if i >= GROUPS[g].x and i < GROUPS[g].y:
			return GROUP_X[g] + (i - GROUPS[g].x) * CARD_STEP
	return 0.0


static func group_of(i: int) -> int:
	return 0 if i < 5 else (1 if i < 8 else 2)


func col_x() -> float:
	return size.x - COL_RIGHT - COL_W


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and coffer_button != null:
		_layout()


## Places the right-anchored parts for the current width.
func _layout() -> void:
	var cx := col_x()
	coffer_button.position = Vector2(cx, CARD_Y - 2.0)
	tier_button.position = Vector2(cx, CARD_Y + 42.0)
	field_counter.position = Vector2(cx, CARD_Y + 86.0)
	_wave_label.position = Vector2(cx, 180.0)
	_wave_label.size = Vector2(COL_W, 17)
	horn_ring.position = Vector2(size.x - COL_RIGHT - 20.0, -1.0)
	_horn_label.position = Vector2(cx - 140.0, -3.0)
	_horn_label.size = Vector2(COL_W + 140.0 - 26.0, 22)
	_hint.size = Vector2(maxf(LEFT_W, cx - 20.0), 17)
	queue_redraw()


## Rect available to group g's label (T3 may run into the empty middle).
func _group_label_rect(g: int) -> Rect2:
	var x := GROUP_X[g]
	var w := (GROUPS[g].y - GROUPS[g].x) * CARD_STEP - 6.0
	if g == 2:
		w = maxf(w, col_x() - 10.0 - x)
	return Rect2(x, 21, w, 16)


func _draw() -> void:
	var groove := UIStyle.token(&"groove")
	var light := UIStyle.token(&"frame_light")
	for g in [1, 2]:
		var x: float = GROUP_X[g] - 12.0
		var y0 := 24.0
		var y1 := CARD_Y + 118.0
		draw_rect(Rect2(x, y0, 2, y1 - y0), groove)
		draw_rect(Rect2(x + 2, y0, 1, y1 - y0), light)
		for y: float in [y0, y1]:
			draw_colored_polygon(PackedVector2Array([Vector2(x + 1.5, y - 3), Vector2(x + 4.5, y),
					Vector2(x + 1.5, y + 3), Vector2(x - 1.5, y)]), light)
	var gap_l := GROUP_X[2] + 2 * CARD_STEP + 10.0
	var gap_r := col_x() - 10.0
	if gap_r - gap_l > 80.0:
		var c := Vector2((gap_l + gap_r) * 0.5, CARD_Y + 59.0)
		UIStyle.draw_emblem(self, roster.kingdom if roster else UIStyle.get_kingdom(), c, minf(56.0, (gap_r - gap_l) * 0.3),
				Color(UIStyle.token(&"title"), EMBLEM_ALPHA))


# ---------------------------------------------------------------- refresh

func refresh() -> void:
	if roster == null:
		return
	_title.text = Loc.t("Muster")
	var to_horn := director.time_to_next_horn()
	var interval := maxf(1.0, director.next_horn_time() - _prev_horn_time())
	var last := director.is_last_horns()
	_horn_label.text = Loc.t("LAST HORNS") if last and to_horn > director.rules.horn_warning else \
			Loc.t("Horn %d in %s") % [director.horn_index + 1, mmss(to_horn)]
	var hot := to_horn <= director.rules.horn_warning
	_horn_label.add_theme_color_override("font_color", UIStyle.WARN if last else (HornRing.HOT if hot else UIStyle.token(&"text")))
	horn_ring.set_state(to_horn / interval, hot, last)
	_refresh_groups()
	var ids := roster.card_ids()
	var opened := roster.tier > _last_tier
	for i in SLOTS:
		var d := card_data(i, ids)
		var c := cards[i]
		var was_locked := bool(c.data.get("locked", false))
		c.set_data(d)
		if bool(d.get("empty", false)):
			continue
		var n := int(d["count"])
		var r := int(d["rank"])
		if _last_counts[i] >= 0:
			if n > _last_counts[i]:
				c.play_buy()
			elif n < _last_counts[i]:
				c.play_sell()
			if r > _last_ranks[i]:
				c.play_rank()
		if opened and was_locked and not bool(d["locked"]):
			c.play_open()
		_last_counts[i] = n
		_last_ranks[i] = r
	_last_tier = roster.tier
	_refresh_supply()
	_refresh_buttons()
	var fc := int(level.call(&"field_count", roster.team)) if level and level.has_method(&"field_count") else 0
	var held := int(level.call(&"held_last_horn", roster.seat)) if level and level.has_method(&"held_last_horn") else 0
	field_counter.set_counts(fc, int(director.rules.field_cap), held)
	_wave_label.text = Loc.tn("Next wave: {n} unit", "Next wave: {n} units", roster.card_total())
	_hint.text = Loc.t("Key / click = buy  ·  Ctrl = rank up  ·  Alt / right-click = sell  ·  %s = enemy roster") % KeyLabels.of(peek_key)
	_fit_hint()


static func mmss(t: float) -> String:
	var s := maxi(0, ceili(t))
	return "%d:%02d" % [s / 60, s % 60]


func _prev_horn_time() -> float:
	return director.rules.horn_time(director.horn_index) if director.horn_index > 0 else 0.0


func _fit_hint() -> void:
	var font := _hint.get_theme_default_font()
	if font == null:
		return
	var fs := 11 if font.get_string_size(_hint.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x <= _hint.size.x else 10
	UIStyle.set_font_size_if_changed(_hint, &"font_size", fs)


func _refresh_groups() -> void:
	var names: Array[String] = [Loc.t("Keep"), Loc.t("Stronghold"), Loc.t("Citadel")]
	for g in GROUPS.size():
		var tier := g + 1
		var nl := _group_names[g]
		var rl := _group_reasons[g]
		var lock := _group_locks[g] as LockGlyph
		nl.text = Loc.t("%s · T%d") % [names[g], tier]
		nl.add_theme_color_override("font_color", UIStyle.token(&"title") if tier == roster.tier else UIStyle.token(&"text_muted"))
		var locked := tier > roster.tier and _group_has_cards(g)
		var reason := ""
		if locked:
			reason = Loc.t("Requires Stronghold", null, "ws group lock") if tier == 2 else Loc.t("Requires Citadel", null, "ws group lock")  # LOC_IGNORE (ctx literal)
		rl.text = "·  " + reason
		var rect := _group_label_rect(g)
		var font := nl.get_theme_font(&"font")
		var full := 0.0
		if font != null:
			full = font.get_string_size(nl.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x \
					+ rl.get_theme_font(&"font").get_string_size(rl.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 4.0
		var fits := full <= rect.size.x
		rl.visible = locked and fits
		lock.visible = locked and not fits
		lock.tooltip_text = reason
		var row := _group_rows[g]
		row.position = rect.position
		row.size = rect.size
		row.alignment = BoxContainer.ALIGNMENT_CENTER if (g < 2 or full <= (GROUPS[g].y - GROUPS[g].x) * CARD_STEP) \
				else BoxContainer.ALIGNMENT_BEGIN


func _group_has_cards(g: int) -> bool:
	return roster.card_ids().size() > GROUPS[g].x


func _refresh_supply() -> void:
	var used := roster.pop_used()
	var cap := roster.cap()
	supply_bar.max_value = maxf(1.0, float(cap))
	supply_bar.value = minf(float(used), float(cap))
	UIStyle.set_bar_color(supply_bar, UIStyle.WARN if used >= cap else UIStyle.GOLD)
	_supply_text.text = Loc.t("Supply  %d / %d") % [used, cap]
	if roster.upgrade_left > 0.0:
		_next_cap.text = "| %d" % director.rules.cap_at(roster.tier + 1)
		_next_cap.visible = true
	else:
		_next_cap.visible = false


func _refresh_buttons() -> void:
	# Coffer
	var cp := bank.coffer_price()
	var total := director.rules.coffer_prices.size()
	var cwhy := bank.can_buy_coffer()
	if cp >= 0:
		coffer_button.set_content(KeyLabels.of(coffer_key), Loc.t("Coffer %d / %d") % [bank.coffer_level + 1, total],
				Loc.t("%d  ·  +%d / horn") % [cp, director.rules.coffer_step], false, cwhy != "", -1.0, [
					[Loc.t("Coffer %d  [%s]") % [bank.coffer_level + 1, KeyLabels.of(coffer_key)], UIStyle.token(&"title"), 15],
					[Loc.t("%d crystals · +%d crystals per horn") % [cp, director.rules.coffer_step], UIStyle.token(&"text"), 13]]
					+ ([[Loc.sink(cwhy), UIStyle.WARN, 13]] if cwhy != "" else []))
	else:
		coffer_button.set_content("", Loc.t("Coffers: all %d bought") % total, "", false, true, -1.0,
				[[Loc.t("Coffers: all %d bought") % total, UIStyle.token(&"text"), 13]])
	# Next tier
	var max_tier := director.rules.max_tier
	var twhy := roster.can_upgrade()
	if roster.tier >= max_tier:
		tier_button.set_content("", Loc.t("%s reached") % Loc.t(roster.tier_name()), "", false, true, -1.0,
				[[Loc.t("%s reached") % Loc.t(roster.tier_name()), UIStyle.token(&"text"), 13]])
		return
	var next_name := Loc.t(roster.tier_name(roster.tier + 1))
	var opens := Loc.t("T2 cards, Drilled, supply %d") if roster.tier == 1 else Loc.t("T3 cards, Elite, supply %d")
	var opens_long := Loc.t("opens T2 cards, Drilled rank, supply %d") if roster.tier == 1 else Loc.t("opens T3 cards, Elite rank, supply %d")
	var next_cap := director.rules.cap_at(roster.tier + 1)
	var rows: Array = [[Loc.t("%s  [%s]") % [next_name, KeyLabels.of(tier_key)], UIStyle.token(&"title"), 15],
			[Loc.t("%d crystals · %s") % [roster.next_tier_price(), opens_long % next_cap], UIStyle.token(&"text"), 13]]
	if roster.upgrade_left > 0.0:
		var total_t := director.rules.stronghold_time if roster.tier == 1 else director.rules.citadel_time
		tier_button.set_content("", Loc.t("%s rising: %d s") % [next_name, ceili(roster.upgrade_left)], opens % next_cap,
				false, false, 1.0 - roster.upgrade_left / maxf(1.0, total_t), rows,
				Loc.t("T2 cards, Drilled") if roster.tier == 1 else Loc.t("T3 cards, Elite"))
		return
	if twhy != "":
		rows.append([Loc.sink(twhy), UIStyle.WARN, 13])
	var opens_short := Loc.t("T2 cards, Drilled") if roster.tier == 1 else Loc.t("T3 cards, Elite")
	tier_button.set_content(KeyLabels.of(tier_key), next_name, ("%d  ·  " % roster.next_tier_price()) + opens % next_cap,
			twhy == "", twhy != "", -1.0, rows, ("%d  ·  " % roster.next_tier_price()) + opens_short)


# ---------------------------------------------------------------- card data

## Everything card `i` shows (also read by tests).
func card_data(i: int, ids: Array[StringName]) -> Dictionary:
	if i >= ids.size():
		return {"empty": true, "slot": i, "tip": [[Loc.t("Empty slot (later: Ember Crucible)"), UIStyle.token(&"text"), 13]]}
	var id := ids[i]
	var t := UnitType.find(String(id))
	var key := KeyLabels.of(card_keys[i]) if i < card_keys.size() else ""
	var nm := Loc.t(t.display_name) if t else String(id)
	var price := roster.unit_price(id)
	var pop := roster.pop_of(id)
	var most := roster.table.max_copies_of(id) if roster.table else 0
	var n := roster.count(id)
	var rk := roster.rank(id)
	var why := roster.can_buy(id)
	var locked := roster.tier_of_card(id) > roster.tier
	var d := {"slot": i, "id": id, "kingdom": roster.kingdom, "name": nm, "abbrev": UIStyle.abbrev(nm),
			"icon": UnitGuideData.icon_of(id), "key": key, "role": role_tag(id), "price": price, "pop": pop, "count": n,
			"max": most, "rank": rk, "why": why, "locked": locked, "maxed": most > 0 and n >= most,
			"crystals_short": not locked and not bank.can_afford(price),
			"supply_short": not locked and roster.pop_used() + pop > roster.cap()}
	d["tip"] = _card_tip(id, t, d)
	if role_kind(id) == &"caster":
		d["role_tip"] = Loc.t("Casters autocast in the lane; max %d copies") % most if most > 0 else Loc.t("Casters autocast in the lane")
	elif most > 0:
		d["role_tip"] = Loc.t("Max %d copies") % most
	return d


func _card_tip(id: StringName, t: UnitType, d: Dictionary) -> Array:
	var rows: Array = []
	var key := String(d["key"])
	var rk := int(d["rank"])
	var rank_names: Array[String] = [Loc.t("Recruit"), Loc.t("Drilled"), Loc.t("Elite")]
	var right := Loc.t("Rank %d / 3") % rk if rk <= 1 else Loc.t("Rank %d / 3 · %s") % [rk, rank_names[rk - 1]]
	rows.append(["%s  [%s]\t%s" % [d["name"], key, right] if key != "" else "%s\t%s" % [d["name"], right],
			UIStyle.token(&"title"), 15])
	if t:
		rows.append([Loc.t("%d crystals · %d pop · %d HP · %d dmg · range %.1f · speed %.1f") % [int(d["price"]), int(d["pop"]),
				int(t.max_hp), int(t.attack_damage), t.attack_range, t.move_speed], UIStyle.CRYSTAL_TEXT, 13])
	var guide := UnitGuideData.text_of(id)
	var pros: Array = guide.get("pros", [])
	var role := UnitGuideData.role_label(str(guide.get("role", "")))
	if not pros.is_empty():
		rows.append(["%s · %s" % [role, Loc.t(str(pros[0]))], UIStyle.token(&"text_muted"), 13])
	if CASTER_LANE.has(id):
		rows.append([Loc.t(String(CASTER_LANE[id])), UIStyle.token(&"trim_glow"), 13])
	var why := String(d["why"])
	if why != "":
		rows.append([Loc.sink(why), UIStyle.WARN, 13])
	if rk < 3 and key != "":
		var rwhy := roster.can_rank_up(id)
		var next_rank := rank_names[rk]
		if rwhy == "" or rwhy == MusterRoster.REASON_CRYSTALS:
			rows.append([Loc.t("Ctrl+%s: %s for %d") % [key, next_rank, roster.rank_up_price(id)], UIStyle.GOLD, 13])
		elif rwhy.begins_with("Requires"):
			rows.append([Loc.t("Ctrl+%s: %s (needs %s)") % [key, next_rank, Loc.t(roster.tier_name(rk + 1))], UIStyle.GOLD, 13])
	if int(d["count"]) > 0 and key != "":
		var refund := int(roundf(roster.unit_price(id) * roster.rules.sell_refund))
		rows.append([Loc.t("Alt+%s / right-click: sell for %d") % [key, refund], UIStyle.token(&"text_muted"), 13])
	return rows


## &"caster" / &"support" / &"rider" / &"heavy" / &"melee" / &"ranged" (ui-wave-strike.md 1.1).
func role_kind(id: StringName) -> StringName:
	if _role_cache.has(id):
		return _role_cache[id]
	var t := UnitType.find(String(id))
	var role := str(UnitGuideData.text_of(id).get("role", ""))
	var k := &"melee"
	if CasterKit.CASTERS.has(id):
		k = &"caster"
	elif t and t.support_kind != &"":
		k = &"support"
	elif role == "cavalry":
		k = &"rider"
	elif role == "siege" or (roster and roster.pop_of(id) >= 3):
		k = &"heavy"
	elif t and t.attack_range > 3.0:
		k = &"ranged"
	_role_cache[id] = k
	return k


func role_tag(id: StringName) -> String:
	match role_kind(id):
		&"caster":
			return Loc.t("Caster", null, "ws role tag")  # LOC_IGNORE (ctx literal)
		&"support":
			return Loc.t("Support", null, "ws role tag")  # LOC_IGNORE (ctx literal)
		&"rider":
			return Loc.t("Rider", null, "ws role tag")  # LOC_IGNORE (ctx literal)
		&"heavy":
			return Loc.t("Heavy", null, "ws role tag")  # LOC_IGNORE (ctx literal)
		&"ranged":
			return Loc.t("Ranged", null, "ws role tag")  # LOC_IGNORE (ctx literal)
	return Loc.t("Melee", null, "ws role tag")  # LOC_IGNORE (ctx literal)


## A refused buy: the card's price (or pop) shakes.
func refuse(slot: int) -> void:
	if slot >= 0 and slot < cards.size():
		cards[slot].play_refuse()


## The horn fired: the ring bursts.
func on_horn() -> void:
	horn_ring.burst()


## The 10 x 12 WARN lock glyph used when a tier label has no room for its reason (tooltip = the reason).
class LockGlyph extends Control:
	func _init() -> void:
		custom_minimum_size = Vector2(10, 12)
		mouse_filter = Control.MOUSE_FILTER_PASS
		size_flags_vertical = Control.SIZE_SHRINK_CENTER

	func _draw() -> void:
		var col := UIStyle.WARN
		draw_rect(Rect2(0, 5, 10, 7), col)
		draw_arc(Vector2(5, 5), 3.2, PI, TAU, 8, col, 1.6)

	func _make_custom_tooltip(for_text: String) -> Object:
		return MusterCard.tip_panel([[for_text, UIStyle.WARN, 13]]) if for_text != "" else null
