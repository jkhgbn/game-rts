extends RefCounted
## Story text shown by the mission / cinematic UI (briefing, objectives, dialogue box, cinematic subtitles):
## translates English text from the mission logic at the display point (docs/design/localization.md 1.3).
## Since 2026-10-06 this is `Loc.sink` (exact msgid, numeric template, printf msgids like
## "Light the braziers of Emberfall (%d / 3)" with captured values put back, line by line; cached), which the HUD
## uses too. Kept so the mission UI keeps one call site.
## Usage (no class_name, so scripted runs need no class cache): `const StoryText := preload(".../story_text.gd")`.


## `text` (English, from the logic) in the current language.
static func tr_text(text: String) -> String:
	return Loc.sink(text)


## Never called: msgids the extractor cannot see in the mission scripts (words filled into a printf text, like
## "Knives from the %s!" with SIDE_NAMES, and a hint built on a `.call(` line), listed so they get a French entry.
static func _extra_msgids() -> void:
	Loc.t("north")
	Loc.t("north-east")
	Loc.t("east")
	Loc.t("%s. Light the brazier to the north-east.")
