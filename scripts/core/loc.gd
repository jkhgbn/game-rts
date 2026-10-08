class_name Loc
extends RefCounted
## Localization (docs/design/localization.md): a thin wrapper over Godot's TranslationServer.
## Source text = English = the gettext msgid ("key"); French lives in data/i18n/fr/*.po (one file per area).
## English is the default and the fallback: a string with no French entry shows in English.
##
## How the game's text gets translated:
## - Static Control text (Label / Button / tooltip / OptionButton / ItemList / RichTextLabel) is translated by Godot
##   itself (auto_translate, `atr`) when the text is exactly a msgid: nothing to wrap, and it switches live.
## - Text built in code goes through `Loc.t("Need {n} crystals", {"n": 5})` (named placeholders) or
##   `Loc.tn("{n} worker", "{n} workers", n)` (plurals; French: plural when n > 1).
## - Text that comes from game logic (refusal reasons, HUD messages, objectives, dialogue) stays English in the logic
##   (code compares it) and is translated where it is shown: `Loc.sink(text)` = exact msgid, else a "numeric template"
##   (every number replaced by "#": "Need 50 more crystals" -> msgid "Need # more crystals", numbers put back).
## Live switch: `set_language` changes the TranslationServer locale; Godot sends NOTIFICATION_TRANSLATION_CHANGED to
## every node (auto-translated text redraws; screens that build text in code refresh on it).

const DEFAULT_LANG := "en"
const LANGS: Array[String] = ["en", "fr"]
## Shown in Settings > Language, each in its own language.
const LANG_NAMES: Array[String] = ["English", "Français (Québec)"]
## The TranslationServer locale per language (the .po headers say fr_CA).
const LOCALES := {"en": "en", "fr": "fr_CA"}
const I18N_DIR := "res://data/i18n"

## The language in use ("en" / "fr").
static var language := DEFAULT_LANG
static var _loaded: Dictionary = {}   # lang -> true once its .po files are in the TranslationServer
static var _number_re: RegEx
static var _sink_cache: Dictionary = {}   # (ctx + U+0004 +) shown English text -> translated text (no digits)
## Texts with digits (live numbers: countdowns, costs, timers) get their own small cache, so a stream of one-off
## values never pushes the static entries out (review 2026-10-08 M6). Both evict their oldest quarter when full.
static var _volatile_cache: Dictionary = {}
const SINK_CACHE_MAX := 4096
const VOLATILE_CACHE_MAX := 512
static var _letter_re: RegEx
static var _sink_cache_lang := ""
static var _formats: Array = []    # printf msgids: [{re, specs, msgid, n, prefix, suffix}]
static var _formats_lang := ""


## Switches the game's language (live). Unknown codes = English. Returns the language set.
static func set_language(lang: String) -> String:
	lang = lang.strip_edges().to_lower().substr(0, 2)
	if not LANGS.has(lang):
		lang = DEFAULT_LANG
	if lang != DEFAULT_LANG:
		_load_language(lang)
	language = lang
	_sink_cache.clear()
	_volatile_cache.clear()
	_formats_lang = ""
	TranslationServer.set_locale(String(LOCALES[lang]))
	return lang


static func is_french() -> bool:
	return language == "fr"


## The language the OS asks for ("fr" when its locale is any French, else "en").
static func detect_os_language() -> String:
	return "fr" if OS.get_locale_language() == "fr" else DEFAULT_LANG


## The saved setting ("" = not chosen yet: the OS locale) -> the language to use. Scripted runs (tests, labs: `-s`)
## stay English unless `-- --lang=fr` is passed, so a player's French setting never changes a test's strings.
static func resolve_setting(saved: String) -> String:
	var forced := cmdline_language()
	if forced != "":
		return forced
	if is_scripted_run():
		return DEFAULT_LANG
	return saved if LANGS.has(saved) else detect_os_language()


## `-- --lang=xx` on the command line, else "".
static func cmdline_language() -> String:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--lang=") or a.begins_with("lang="):
			return lang_from_arg(a.get_slice("=", 1))
	return ""


## A `--lang=` value -> a language: "fr_CA" / "FR-ca" -> "fr", as set_language does (review 2026-10-08 L8);
## unknown -> English.
static func lang_from_arg(value: String) -> String:
	var l := value.strip_edges().to_lower().substr(0, 2)
	return l if LANGS.has(l) else DEFAULT_LANG


static func is_scripted_run() -> bool:
	var args := OS.get_cmdline_args()
	return args.has("-s") or args.has("--script")


## Translates a msgid (English source text) and fills `{name}` placeholders from `args` (Dictionary, or Array for
## {0} {1}...). `ctx` = gettext msgctxt for msgids that need two meanings.
static func t(msg: String, args: Variant = null, ctx := "") -> String:
	var s := String(TranslationServer.translate(msg, ctx)) if msg != "" else ""
	return _fill(s, args)


## Plural: `singular` / `plural` msgids, `n` picks the form (English n == 1; French n <= 1). `{n}` is filled with n.
static func tn(singular: String, plural: String, n: int, args: Variant = null, ctx := "") -> String:
	var s := String(TranslationServer.translate_plural(singular, plural, n, ctx))
	var d: Dictionary = {}
	if args is Dictionary:
		d = (args as Dictionary).duplicate()
	d["n"] = n
	return _fill(s, d)


## Text from game logic, translated where it is shown: the exact msgid, else its numeric template (numbers -> "#"),
## else a printf msgid of the loaded .po files ("Knives from the %s!", "Malrik's dig: %d %%": the shown text is
## matched against each one and the French format is filled with the captured values, a captured %s translated too),
## else each line on its own, else unchanged (English). Results are cached per language.
static func sink(text: String, ctx := "") -> String:
	if text == "" or language == DEFAULT_LANG:
		return text
	if _sink_cache_lang != language:
		_sink_cache.clear()
		_volatile_cache.clear()
		_sink_cache_lang = language
	var key := text if ctx == "" else ctx + "\u0004" + text
	if _sink_cache.has(key):
		return _sink_cache[key]
	if _volatile_cache.has(key):
		return _volatile_cache[key]
	if not _has_letter(text):
		# Clocks, "12 / 40", "3:05": only the exact / numeric-template lookups apply (no printf msgid matches a
		# text without letters); never cached, a new value arrives every second.
		return _sink_numbers_only(text, ctx)
	var out := _sink_uncached(text, ctx)
	if (numeric_template(text)["numbers"] as PackedStringArray).is_empty():
		_cache_put(_sink_cache, key, out, SINK_CACHE_MAX)
	else:
		_cache_put(_volatile_cache, key, out, VOLATILE_CACHE_MAX)
	return out


## Number of cached sink results, static + volatile (tests).
static func sink_cache_size() -> int:
	return _sink_cache.size() + _volatile_cache.size()


## True when `text` is in the static (digit-free) sink cache (tests).
static func sink_cached(text: String, ctx := "") -> bool:
	return _sink_cache.has(text if ctx == "" else ctx + "\u0004" + text)


static func _cache_put(cache: Dictionary, key: String, value: String, limit: int) -> void:
	if cache.size() >= limit:
		# Dictionaries keep insertion order: drop the oldest quarter, keep the rest (no full flush).
		var old := cache.keys().slice(0, maxi(1, limit / 4))
		for k: Variant in old:
			cache.erase(k)
	cache[key] = value


static func _has_letter(text: String) -> bool:
	if _letter_re == null:
		_letter_re = RegEx.create_from_string("\\p{L}")
	return _letter_re.search(text) != null


static func _sink_numbers_only(text: String, ctx: String) -> String:
	var exact := String(TranslationServer.translate(text, ctx))
	if exact != text:
		return exact
	var templ := numeric_template(text)
	if templ["template"] != text:
		var tr_t := String(TranslationServer.translate(templ["template"], ctx))
		if tr_t != templ["template"]:
			return _put_numbers(tr_t, templ["numbers"])
	return text


static func _sink_uncached(text: String, ctx: String) -> String:
	var exact := String(TranslationServer.translate(text, ctx))
	if exact != text:
		return exact
	var templ := numeric_template(text)
	if templ["template"] != text:
		var tr_t := String(TranslationServer.translate(templ["template"], ctx))
		if tr_t != templ["template"]:
			return _put_numbers(tr_t, templ["numbers"])
	if ctx == "":
		var pf := _printf(text)
		if pf != text:
			return pf
	if text.contains("\n"):
		var lines := text.split("\n")
		var out: PackedStringArray = []
		var changed := false
		for line in lines:
			var tl := sink(line, ctx) if line != "" else line
			changed = changed or tl != line
			out.append(tl)
		if changed:
			return "\n".join(out)
	return text


## `text` matched against the printf msgids ("%s", "%d", "%02d", "%%") of the current language's .po files.
static func _printf(text: String) -> String:
	_load_formats()
	for f: Dictionary in _formats:
		if not text.begins_with(String(f.prefix)) or not text.ends_with(String(f.suffix)):
			continue
		var m: RegExMatch = (f.re as RegEx).search(text)
		if m == null:
			continue
		var fr := String(TranslationServer.translate(String(f.msgid)))
		if fr == f.msgid:
			continue
		var specs: PackedStringArray = f.specs
		var args: Array = []
		for i in specs.size():
			var v := m.get_string(i + 1)
			args.append(int(v) if specs[i] == "d" else sink(v))
		return fr % args
	return text


static func _load_formats() -> void:
	if _formats_lang == language:
		return
	_formats_lang = language
	_formats.clear()
	var spec_re := RegEx.create_from_string("%(%|0?\\d*d|s)")
	for path in po_files(language):
		var tr := load(path) as Translation
		if tr == null:
			continue
		for id: String in tr.get_message_list():
			if not id.contains("%") or id.length() < 4:
				continue
			var pattern := "^"
			var specs: PackedStringArray = []
			var last := 0
			var useful := false
			var prefix := ""
			for m in spec_re.search_all(id):
				var lit := id.substr(last, m.get_start() - last)
				pattern += _re_escape(lit)
				var s := m.get_string(1)
				if s == "%":
					pattern += "%"
					if not useful:
						prefix += lit + "%"
				else:
					if not useful:
						prefix += lit
					useful = true
					if s == "s":
						pattern += "(.+?)"
						specs.append("s")
					else:
						pattern += "(-?\\d+)"
						specs.append("d")
				last = m.get_end()
			var tail := id.substr(last)
			pattern += _re_escape(tail) + "$"
			var literal := id
			for x in ["%s", "%d", "%%"]:
				literal = literal.replace(x, "")
			if not useful or literal.strip_edges().length() < 3:
				continue   # "%s (%d)" alone would match anything
			var re := RegEx.create_from_string(pattern)
			if re.is_valid():
				_formats.append({"re": re, "specs": specs, "msgid": id, "n": literal.length(),
						"prefix": prefix, "suffix": tail.replace("%%", "%")})
	# Most specific (longest literal part) first.
	_formats.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.n) > int(b.n))


static func _re_escape(s: String) -> String:
	var out := ""
	for c in s:
		out += "\\" + c if "\\^$.|?*+()[]{}".contains(c) else c
	return out


## True when `text` (or its numeric template) has a translation in the current language.
static func has_translation(text: String, ctx := "") -> bool:
	if language == DEFAULT_LANG:
		return true
	return sink(text, ctx) != text


## {"template": text with every number replaced by "#", "numbers": the numbers as written, in order}.
static func numeric_template(text: String) -> Dictionary:
	if _number_re == null:
		_number_re = RegEx.create_from_string("(?<![A-Za-z#\\d])\\d+(?:[.,:]\\d+)*(?![A-Za-z\\d])")
	var nums: PackedStringArray = []
	var out := ""
	var last := 0
	for m in _number_re.search_all(text):
		out += text.substr(last, m.get_start() - last) + "#"
		nums.append(m.get_string())
		last = m.get_end()
	out += text.substr(last)
	return {"template": out, "numbers": nums}


## Display form of a decimal number in the current language ("1.5" -> "1,5" in French).
static func num(v: float, decimals := 1) -> String:
	var s := String.num(v, decimals)
	return s.replace(".", ",") if language == "fr" else s


## Loads every data/i18n/<lang>/*.po into the TranslationServer (once).
static func _load_language(lang: String) -> void:
	if _loaded.get(lang, false):
		return
	_loaded[lang] = true
	for path in po_files(lang):
		var tr := load(path) as Translation
		if tr != null:
			TranslationServer.add_translation(tr)
		else:
			push_warning("Loc: could not load " + path)


## The .po files of a language (sorted; exported builds list them too).
static func po_files(lang: String) -> PackedStringArray:
	var out: PackedStringArray = []
	var dir := I18N_DIR.path_join(lang)
	for f in DirAccess.get_files_at(dir):
		var file := f.trim_suffix(".remap").trim_suffix(".import")
		if file.ends_with(".po") and not out.has(dir.path_join(file)):
			out.append(dir.path_join(file))
	out.sort()
	return out


static func _fill(s: String, args: Variant) -> String:
	if args is Dictionary and not (args as Dictionary).is_empty():
		return s.format(args)
	if args is Array and not (args as Array).is_empty():
		return s.format(args)
	return s


static func _put_numbers(templ: String, nums: PackedStringArray) -> String:
	var out := ""
	var k := 0
	for i in templ.length():
		var c := templ[i]
		if c == "#" and k < nums.size():
			out += Loc.num(nums[k].to_float(), nums[k].get_slice(".", 1).length()) if language == "fr" \
					and nums[k].contains(".") else nums[k]
			k += 1
		else:
			out += c
	return out
