# tools/common: shared base of the tools wave

Owner this window: the tool 2 (`cine`) agent. Other tools **read and use** these files, never edit them; requests go
in `docs/handoff/for-cine.md`. The API below is **stable** (additions only). Spec: `docs/plan/tools-wave.md` sections 0-1.

| File | Class | What |
|---|---|---|
| `tool_spec.gd` + `tool_spec_line.gd` | `ToolSpec`, `ToolSpecLine` | The one line-based spec reader (all tool formats look alike) |
| `tool_cli.gd` | `ToolCli` | `<verb> <id> key=value` args, help table, exit codes, watchdog, hashes |
| `tool_report.gd` | `ToolReport` (extends `ArtLabReport`) | Scorecard `report.md` / `report.json` + `history.md` row + printed summary |
| `tool_sheet.gd` | `ToolSheet` | Headless image drawing: 5x7 bitmap text, contact-sheet grid, 2.39 band / safe area, rects |
| `tool_capture.gd` | `ToolCapture` | Windowed SubViewport render of 3D content at W x H -> `Image` |
| `run_tool.ps1` | - | Launcher: gate + headless / windowed + `--fixed-fps` + `--quit-after` + args after `--` |

## 1. Spec format (`ToolSpec`)
```
# a comment line                         (# at line start, or " # " after a space = comment)
set watch_keep  size=40x30  ground=ash   # keyword, positional args, key=value
place res://art/buildings/fire_keep.tscn at=(-8, 0, -10) yaw=30 tint=#ff8800
  child_line  arg  k="quoted value"       # indented deeper = child of the line above
marks P11 lens "mcu on torvald, 3/4 left, low"
fov=38>32   look=@P11_from>@P11_to   area=ring((0,0),14..20)   poly=[(-20,5),(0,3),(20,8)]
```
- Tokens split on spaces **outside** `"quotes"`, `(parens)` and `[brackets]`. `key=value` = a token whose key is
  `[A-Za-z0-9_.-]+`; quoted tokens are never key=value. Quotes are removed from values / args.
- Token kinds, `ToolSpec.kind_of(tok)`: `marker` `@name` · `res` `res://...` · `color` `#hex` (3/4/6/8 digits) ·
  `vector` `(x,y[,z])` · `list` `[...]` · `range` `a..b` · `fromto` `a>b` · `number` · `word`.
- Helpers (static): `fromto("38>32") -> ["38","32"]` (no `>` = same value twice), `range_of("14..20") -> Vector2`,
  `vec_of("(1,2,3)") -> Vector3 / Vector2 / null`, `color_of("#f80") -> Color / null`, `list_of("[a,(1,2)]") ->
  PackedStringArray` (top-level commas), `nearest(word, candidates) -> String` ("" if nothing close),
  `levenshtein(a, b)`, `tokenize(line)`.

```gdscript
var spec := ToolSpec.parse_file("res://data/cinematics/src/watch_keep.cine")   # or ToolSpec.parse_text(text, "name")
for l: ToolSpecLine in spec.lines:             # top-level lines; l.children = indented block below
    match l.keyword:
        "shot":
            spec.check_keys(l, ["cam", "from", "to", "look", "fov", "in"])   # unknown key -> error + "did you mean"
            var fov := ToolSpec.fromto(l.get_str("fov", "45"))
        _:
            spec.error(l, l.keyword, "unknown keyword \"%s\"" % l.keyword, ["shot", "cast", "use"])
if not spec.ok():
    for e: String in spec.error_lines(): print(e)
    # data/cinematics/src/watch_keep.cine:12: unknown actor "vesa" -> did you mean "vessa"?
```
`ToolSpec`: `path`, `lines`, `all_lines` (flat, file order), `errors` / `warnings` (`{file, line, token, message,
hint, text}`), `ok()`, `find(keyword)`, `first(keyword)`, `error(line, token, message, candidates=[])`,
`warn(line, token, message, hint)`, `check_keys(line, allowed) -> bool`, `expect_one_of(line, value, allowed, what) ->
bool`, `error_lines()`, `static format_error(e)`.
`ToolSpecLine`: `line` (1-based), `indent`, `text`, `keyword`, `args`, `quoted[i]`, `kv`, `kv_order`, `children`,
`parent`, `has(k)`, `arg(i, default)`, `arg_count()`, `get_str / get_float / get_int / get_bool(k, default)`,
`bad_numbers(keys)`, `find(keyword)`.

## 2. CLI (`ToolCli`) and the launcher
Entry script `tools/<tool>/<tool>_main.gd` (`extends SceneTree`), run by `tools/<tool>/run_<tool>.ps1`:
```gdscript
extends SceneTree
const VERBS := [{"verb": "help", "args": "", "text": "grammar + example"},
    {"verb": "check", "args": "<id>", "text": "headless checks", "needs_id": true}]
const KEYS := [{"key": "seed", "default": "0", "text": "random seed"}]
func _initialize() -> void:
    _main.call_deferred()
func _main() -> void:
    var cli := ToolCli.parse("mytool", VERBS, KEYS)      # verb, id, opts; unknown verb / key -> cli.bad (did you mean)
    if cli.bad != "":
        print(cli.bad); quit(ToolCli.BAD_INPUT); return
    ToolCli.watchdog(self, 120.0, "mytool")
    if cli.verb == "help":
        print(cli.help_text("one line summary", EXAMPLE)); quit(ToolCli.OK); return
    var rep := ToolReport.start("mytool", cli.verb, cli.id)
    ...
    quit(rep.finish())
```
`ToolCli`: consts `OK 0`, `FAIL 1`, `BAD_INPUT 2`, `WATCHDOG 3`; fields `tool, verb, id, opts, positional, bad`;
`static parse(tool, verbs, keys, argv = user args)`, `has(k)`, `opt(k, d)`, `opt_float`, `opt_int`, `opt_bool`,
`opt_size(k, Vector2i)`, `opt_sizes(k, [Vector2i...]) -> Array[Vector2i]` (`res=1600x900,3440x1440`),
`help_text(summary, example)`, `static is_windowed()`, `static watchdog(tree, seconds, tool)`,
`static hash_of(String | PackedByteArray) -> String` (sha256, 16 hex), `static file_hash(path)`.

`run_<tool>.ps1` template (4 lines):
```powershell
param([Parameter(Position = 0)][string]$Verb = "help", [Parameter(Position = 1)][string]$Id = "",
      [Parameter(ValueFromRemainingArguments = $true)][string[]]$Rest = @())
$win = $Verb -in @("sheet", "stills")                    # verbs that need pixels
& "$PSScriptRoot\..\common\run_tool.ps1" -Script "res://tools/mytool/mytool_main.gd" -Windowed:$win -QuitAfter 30000 -ToolArgs (@($Verb, $Id) + $Rest)
exit $LASTEXITCODE
```
`run_tool.ps1 -Script <res path> [-ToolArgs @()] [-Windowed] [-Fps 60] [-QuitAfter 20000] [-GodotArgs @()] [-Quiet]`.

## 3. Report (`ToolReport`)
Same scorecard as the Art Lab (`tools/art_lab/lab_report.gd`): every check = status (PASS / WARN / FAIL / INFO /
SKIP), measured value, rule, fix hint, optional graded score 0-1 and "improve" text; quality 0-100; "Improve next".
```gdscript
var rep := ToolReport.start("world_forge", "set", "forge_watch")   # out dir docs/tools/world_forge/out/forge_watch/
rep.add_group("budget", "Budgets", 1.0)                              # sections in this order
rep.check("B1", "budget", "draw calls", "PASS", 132, "<= 150", "merge the scatter", "bake the pines to one mesh")
rep.add("B2", "budget", "lights", "FAIL", "2", "0 lights", "use emission", ToolReport.grade(2, 3, 0))  # full ArtLabReport.add
rep.hash_value = ToolCli.hash_of(bytes); rep.hash_note = "2 runs identical"
rep.shots["top-down"] = "top_down.png"; rep.notes.append("...")
var code := rep.finish()      # report.md + report.json (+ history row) + printed summary; code 0 PASS/WARN, 1 FAIL
```
Writes `docs/tools/<tool>/out/<id>/report.md` + `report.json` for verbs `check` / `build` (other verbs:
`report_<verb>.md` / `.json`), one row in `docs/tools/<tool>/history.md`, and prints:
```
WORLD_FORGE set forge_watch: FAIL quality 71 (1 FAIL, 0 WARN) hash 3fa2... -> docs/tools/world_forge/out/forge_watch
  FAIL B2 lights: 2 -> use emission
```
Also: `problem_lines()`, `write(dir)`, `append_history(path)`, `print_summary()`, `static out_dir_of(tool, id)`,
`static history_path(tool)`, `static read_previous_quality(dir, verb)`, `static read_previous_hash(dir, verb)`; inherited
`add`, `grade(value, bad, good)`, `budget_status`, `count`, `result`, `quality`, `improve_next`, `exit_code`,
`extras` (`{title, text, source}` ideas that top up "Improve next" to >= 3), `notes`, `shots`.

## 4. Sheets (`ToolSheet`, headless-safe, deterministic)
`new_image(w, h, bg)`, `text(img, x, y, s, color, scale=2) -> width` (5x7 font, upper case, ASCII punctuation),
`text_width(s, scale)`, `line_h(scale)`, `clip(s, max_px, scale)`, `rect(img, Rect2i, color)` (alpha blends),
`frame(img, Rect2i, color, t)`, `bar_px(size, aspect=2.39)` (cinematics.md 6.1: 115 px at 1600x900, 43 at 3440x1440),
`band_rect(size, aspect)`, `safe_rect(size, aspect, safe=0.9)`, `band_overlay(img, aspect, safe, darken)` (bars darkened,
band edges yellow, safe area cyan), `fit(img, w, h)`, `grid(tiles, cols, tile_w=400, header=[], title="") -> Image`
(tiles `{img, label, color?, mark?}`; header lines starting with FAIL / WARN / PASS get their colour),
`save_png(img, path)`. Colours: `BG FG PASS_C WARN_C FAIL_C BAND_COLOR SAFE_COLOR`.

## 5. Capture (`ToolCapture`, windowed only)
```gdscript
var cap := ToolCapture.create(get_root(), Vector2i(1600, 900))   # own World3D; or create(parent, size, world_3d)
cap.viewport.add_child(stage)                                     # your lights / environment / models
cap.set_camera(Transform3D(...), 40.0)
var img: Image = await cap.snap(3)                                # null when headless (prints once)
cap.free_viewport()
```
Also `set_size(size)`, `camera`, `viewport`, `static grab_main(tree, frames) -> Image`. Headless runs: the dummy
renderer draws nothing and drops MultiMesh transforms (bake to ArrayMesh first).
