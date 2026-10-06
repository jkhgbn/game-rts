# Localization (English + French Québec)

Status 2026-10-06: system built, French (Québec) is the first translation. English is the source, the default and the
fallback: any text without a French entry shows in English. Coverage numbers: `data/i18n/coverage.md` (generated).

## 1. How it works
- **Keys = the English text** (gettext msgid). No separate key names: the code stays readable, English needs no file,
  and a missing translation falls back to English by itself.
- **Files**: `data/i18n/fr/<area>.po` (one French file per area, so diffs stay small and areas can be translated in
  parallel); `data/i18n/en/<area>.pot` = the generated English key list (source locations `#:`, context notes `#.`);
  `data/i18n/glossary_fr.md` = the term list every French string follows; `data/i18n/ignore_<area>.txt` = literals
  the extractor picks up that are not player text.
- **`Loc`** (`scripts/core/loc.gd`, static): `Loc.t("Need {n} crystals", {"n": 5})`, `Loc.t("%s  vs  %s") % [a, b]`,
  `Loc.tn("{n} worker", "{n} workers", n)` (plurals; French: singular for 0 and 1), `Loc.t(text, args, "ctx")`
  (msgctxt for a word with two meanings), `Loc.sink(text)` (text that comes from game logic, see below),
  `Loc.num(1.5)` ("1,5" in French), `Loc.set_language("fr")`, `Loc.language`.
- **Three ways text gets translated**
  1. Static Control text (Label, Button, tooltip, OptionButton / ItemList items, RichTextLabel): Godot translates it
     itself (`auto_translate`, `atr`) when the text is exactly a msgid. Nothing to wrap; it switches live. `.text`
     keeps the English, so code and tests that read `.text` keep working.
  2. Text built in code (formats, concatenations): wrap the template, `Loc.t("Random %s map") % mode`. Never
     concatenate translated fragments ("Train " + name): one template per sentence, named `{placeholders}` when
     there are several (the French order can differ).
  3. Text from game logic (refusal reasons, HUD messages, objectives, dialogue lines, map notes): the logic keeps
     English (code compares it: `== "Not learned"`), the UI translates where it shows it: `Loc.sink(reason)` = the
     exact msgid, else the **numeric template** (every number replaced by `#`: "Need 50 more crystals" -> msgid
     "Need # more crystals", numbers put back), else a **printf msgid** of the loaded .po files ("Knives from the %s!",
     "Malrik's dig: %d %%": captured values put back, a captured %s translated too), else line by line, else English.
     Cached per language. `StoryText.tr_text` (mission UI) is the same call.
- **Language setting**: Settings > Language (English / Français (Québec)), `GameSettings.language` ("" = first run:
  the OS locale decides, then it is saved). Switching is live: `Loc.set_language` changes the TranslationServer
  locale, Godot sends `NOTIFICATION_TRANSLATION_CHANGED`; screens that build text in code rebuild it in
  `_notification` (main menu, kingdom cards, settings). HUD text refreshes on its own timers.
- **Scripted runs** (tests, labs: `-s`) always start in English, whatever the player's saved setting; pass
  `-- --lang=fr` (or call `Loc.set_language`) to run one in French. The UI Lab takes `lang=fr`.

## 2. Adding strings (every agent)
1. Write the English in code as usual. Static label / button / tooltip text: nothing else to do. Built text: wrap
   it (section 1.2). Logic text shown somewhere: `Loc.sink` at the place it is shown.
2. Run the extractor, which adds the new keys to the French file of their area:
   `& tools\godot_run.ps1 --headless --path . -s res://tools/i18n/extract_strings.gd --quit-after 5000 '--' merge`
3. Translate: edit `data/i18n/fr/<area>.po` (fill `msgstr`), or write a JSON `{"English": "Français"}` (plurals:
   `["singulier", "pluriel"]`, context: `"ctx\u0004English"`) and run `... extract_strings.gd '--' import=<file.json>`.
   Then `... '--' fix` (French typography) and `tests/test_i18n.gd`.
4. `tests/test_i18n.gd` fails when a key of a **required area** has no French, when placeholders differ, when a
   French character is missing from the fonts, or on a plain space before `: ; ? !`.

Extractor modes: `report` (default: .pot + coverage.md), `merge`, `import=`, `fix`, `check` (exit 1 on a missing
required key or a placeholder problem); `area=<id>` limits merge / import. Heuristic for GDScript: every literal that
looks like text (not ids, paths, CamelCase names, dictionary keys, compares, debug prints); `Loc.t / tn / sink / tr`
literals always count. A false positive goes in `data/i18n/ignore_<area>.txt` (one literal per line, `\n` escaped; every `ignore*.txt` is read).

## 3. Areas (`I18nExtract.AREAS`, first area wins a shared msgid)
| Area | Sources | Required |
|---|---|---|
| ui_unit_guide | `scripts/ui/menus/unit_guide.gd`, `unit_guide_data.gd` | yes |
| ui_menus | `scripts/ui/menus/` (main menu, skirmish setup, map picker, settings, pause, campaign panel) | yes |
| ui_hud | `scripts/ui/*.gd` (top bar, command card, selection panel, HUD, minimap, score...) | yes |
| ui_hud_windows | tavern, trade, shop, champion bar, items, bounty, map-fill panels | yes |
| ui_mission | `scripts/ui/mission/`, `scripts/ui/cinematic/` | yes |
| ui_wave_strike | `scripts/ui/wave_strike/` | no (mode in prototype) |
| campaign | `scripts/campaign/` (objectives, briefings, dialogue, end texts) | yes |
| campaign_data | `missions/**/*.tres` text properties | no |
| dialogue | `data/voice/lines/*.json` "text" (subtitles; the voices stay English) | yes |
| unit_guide | `data/ui/unit_guide.json` (roles, classes, pros / cons, ability text) | yes |
| maps | `scripts/world/map_catalog.gd`, `data/maps/catalog.tres` ("title" = names kept English, "hook") | yes |
| game_data | `data/units`, `buildings`, `spells`, `items`, `champions`... (`display_name` = names, kept English) | no |
| game_logic | refusal reasons and messages in `scripts/buildings`, `units`, `items`, `economy`, `spells`, `world` | no |

## 4. French rules
- Glossary: `data/i18n/glossary_fr.md` (keep = donjon, Stronghold / Citadel = Forteresse / Citadelle, tier =
  palier, crystals = cristaux, wizard = sorcier, helper = assistant, caster = lanceur de sorts, score = pointage...).
  Proper names (characters, units, buildings, champions, items, spells, places) stay English, except Keep, Caravan,
  Ice Wall and the tier names.
- Typography: no-break space U+00A0 before `: ; ? !` and inside « » (the fonts have no U+202F narrow one);
  `extract_strings.gd fix` applies it. Decimal comma (`Loc.num`).
- Length: French runs 20-30 % longer. Every screen must pass the UI Lab in French:
  `& tools\godot_run.ps1 --path . -s res://tools/ui_lab/ui_lab.gd --quit-after 200000 '--' 'res=1600x900,1920x1080' lang=fr out=res://docs/ui/lab_fr log=0`.
  Prefer a shorter French wording over a wider frame; widen a frame only when the English layout has room.
- Fonts: Cinzel (titles) and Alegreya (body) have every French accent (é è ê ë à â ç î ï ô û ù ü ÿ œ æ, capitals,
  « », ’, U+00A0). `test_i18n` checks every character used in the French files.

## 5. Adding a language
1. Add its code to `Loc.LANGS`, its name (in its own language) to `Loc.LANG_NAMES`, its locale to `Loc.LOCALES`.
2. Create `data/i18n/<lang>/`, copy the header of a French file (Language, Plural-Forms for that language), and
   generalize the extractor's `merge` (`LANGS`) to that folder; add a glossary `glossary_<lang>.md`.
3. Check the fonts with the glyph check of `test_i18n` (extend `FRENCH_GLYPHS`).

## 6. Not translated (by design or not yet)
- Voice audio stays English (subtitles are translated).
- Proper names (glossary). Debug / lab / tool output, the Unit Lab sandbox, cinematics tooling.
- Areas marked "no" above: see `data/i18n/coverage.md` for what is left.
