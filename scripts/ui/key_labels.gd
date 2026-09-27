class_name KeyLabels
extends RefCounted
## Layout-aware key names (task UX.1). The game binds **physical** keys (QWERTY positions); these helpers return
## the letter printed on the player's own keyboard for that position, so an AZERTY player reads "Q" for the
## physical A key and "W" for the physical Z key. The headless display server has no keyboard layout: there the
## QWERTY names are used (tests can simulate a layout with `overrides`).

## Tests: physical Key (int) -> the label to show instead of asking the OS.
static var overrides: Dictionary = {}
static var _cache: Dictionary = {}
static var _cache_time := -100000
const CACHE_MS := 1000   # the OS layout can change while the game runs: re-read once a second


## The label of the physical key `physical` on the current keyboard layout ("Q" for KEY_A on AZERTY).
static func of(physical: int) -> String:
	if overrides.has(physical):
		return str(overrides[physical])
	var now := Time.get_ticks_msec()
	if now - _cache_time > CACHE_MS:
		_cache.clear()
		_cache_time = now
	if _cache.has(physical):
		return _cache[physical]
	var text := ""
	if layout_supported():
		var label := DisplayServer.keyboard_get_label_from_physical(physical as Key)
		if label != KEY_NONE:
			text = OS.get_keycode_string(label)
	if text == "":
		text = OS.get_keycode_string(physical as Key)
	if text.length() == 1:
		text = text.to_upper()
	_cache[physical] = text
	return text


## A QWERTY letter ("Q" = the physical key there) -> its label on the player's keyboard ("A" on AZERTY).
## Anything that is not a single letter A-Z ("Del", "Esc", "") comes back unchanged.
static func letter(qwerty: String) -> String:
	if qwerty.length() != 1:
		return qwerty
	var c := qwerty.to_upper().unicode_at(0)
	if c < KEY_A or c > KEY_Z:
		return qwerty
	return of(c)


## Several physical keys joined by `sep`: `join([KEY_W, KEY_A, KEY_S, KEY_D])` = "W A S D" ("Z Q S D" on AZERTY).
static func join(keys: Array, sep := " ") -> String:
	var parts: PackedStringArray = []
	for k: int in keys:
		parts.append(of(k))
	return sep.join(parts)


## Replaces the key hints of QWERTY letter `qwerty` in `text` ("[Q]", "Ctrl+Q", "Shift+Q") by its layout label.
static func localize_hints(text: String, qwerty: String) -> String:
	var shown := letter(qwerty)
	if shown == qwerty:
		return text
	return text.replace("[%s]" % qwerty, "[%s]" % shown).replace("Ctrl+%s" % qwerty, "Ctrl+" + shown) \
			.replace("Shift+%s" % qwerty, "Shift+" + shown)


## False on the headless display server (no keyboard layout: asking it only prints errors).
static func layout_supported() -> bool:
	return DisplayServer.get_name() != "headless"
