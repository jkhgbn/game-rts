extends SceneTree
## String extraction + coverage (docs/design/localization.md). Scans the player-facing sources, writes the English
## key list per area (data/i18n/en/<area>.pot: msgid = the English text, "#:" source locations, "#." context notes)
## and the coverage report (data/i18n/coverage.md: % translated per area and language).
##   & tools/godot_run.ps1 --headless --path . -s res://tools/i18n/extract_strings.gd --quit-after 3000 '--' [mode] [opts]
## Modes (default `report`):
##   report            .pot files + coverage.md
##   merge             report + adds every missing msgid to data/i18n/fr/<area>.po (empty msgstr; names pre-filled)
##   import=<json>     fills empty French msgstr from a JSON {"English": "Français", "ctx\u0004English": ...}
##   fix               French typography on every fr msgstr (no-break space before : ; ? ! and inside « »)
##   check             exit 1 when a REQUIRED area has an untranslated key or any entry has a placeholder mismatch
## Options: area=<id>[,<id>] (limit merge / import to these areas), lang=fr, quiet=1.
## Exit codes: 0 ok, 1 check failed, 2 bad arguments.



func _initialize() -> void:
	quit(I18nExtract.new().run(OS.get_cmdline_user_args()))
