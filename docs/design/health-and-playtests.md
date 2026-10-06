# Game Health Dashboard + Playtest Recorder

JS approved both on 2026-10-06. (A) one number for "how healthy is the game", built from the labs we already run;
(B) a player-safe recorder that turns real playtests into pacing / economy / heatmap reports.

## A. Game Health Dashboard

### Commands
| What | Command | Time |
|---|---|---|
| Dashboard from the latest lab outputs | `tools\health\run_health.ps1` | ~10 s (one headless Godot) |
| Refresh the quick labs first | `tools\health\run_health.ps1 -Refresh` | + Data Lab ~10 s + map balance model ~25 s per ready map |
| Try without touching the history | `tools\health\run_health.ps1 -NoHistory -OutDir <dir>` | |
| Open the page after the run | `... -Open` | |

Output: `docs/health/latest.md`, `docs/health/latest.html` (self-contained: inline CSS + SVG, light / dark, no
external files) and one row per run in `docs/health/history.jsonl` (trend source). `-Refresh` writes into
`docs/health/refresh/` only: the labs' own folders and the balance model's `dataset/` are never touched. Nothing else
is ever re-run (CI, Perf, Art, bot games stay with their own labs).

### Areas and weights (sum 100)
| Area | Weight | Components (weight inside the area) and source |
|---|---|---|
| Stability | 20 | tests pass of the newest Error Lab scorecard (3, `docs/ci/*/error_lab/` or `docs/errors/lab/`), Error Lab score (2), flip-flop tests over the last 6 Error Lab runs (1: 100 - 6 per test), smoke (1, newest `docs/ci/*/ci_result.txt`), Replay Lab (1, `docs/replay/lab/history.jsonl`), Build Lab (1) |
| Performance | 15 | Perf Lab scenario scores (2, `docs/perf/lab/latest/*.json`), CI perf tests ms vs budget (1: 100 x budget / ms, capped) |
| Balance | 15 | Balance Lab score (1; 0.5 when < 40 matches), Unit Lab newest full matrix (1: share of entries that are not "too strong / too weak") |
| Maps | 10 | map gate verdicts (2: PASS 100, PARTIAL 70, FAIL 35, `docs/tools/map_gate/*/scorecard.json`), balance model of the catalog's ready maps (1, `tools/map_lab/balance/dataset/<id>.json` or a newer `-Refresh` file), Map Lab (0.5) |
| Art | 10 | Art Lab mean quality (2, every `docs/art/lab/*/scorecard.json`), share of assets without a FAIL (1), Visual Diff Lab (0.5), Audio Lab mean (0.5) |
| UI/UX | 10 | UI Lab quality (2, `docs/ui/lab/scorecard.json`), other `docs/ui/<run>/scorecard.json` (0.5 each) |
| Data | 5 | Data Lab quality (newest `docs/data/lab/*/`) |
| Content completeness | 15 | episode-1 missions built vs specified (1), all campaign specs (0.5), kingdom units with a Unit Guide block / an icon `art/icons/units/<id>.png` / voice barks `assets/audio/voice/unit_<id>` (1 each), localization coverage (1, first of `locale/`, `localization/`, `translations/`, `data/i18n/`... with CSV / PO files) |

Math (`tools/health/health_core.gd`, pure functions, `tests/test_health.gd`):
- area score = weighted mean of its components that have data;
- health score = weighted mean of the areas that have data; the missing weight is shown as **coverage**, never
  counted as 0 ("no data" is not "bad");
- status: Good >= 85, Watch >= 65, Poor below;
- a problem's **cost** = the health points its component loses (area weight / present weight x component weight /
  area's present component weight x (100 - score)), split over that component's problems (equal, or a `share`). The
  costs of every problem add up to 100 - health;
- **top 3** = highest cost, one per area first (one weak lab cannot fill the list), then the next highest;
- trend = this score minus the mean of the last 5 history rows, per area too (up / down at 1 point).

Every component lists its evidence, its source file and its age in days, so a stale lab is visible (example: the
Replay Lab row of 2026-09-27). A missing / unreadable file gives "no data", never an error.

**In-game dev panel:** skipped (cost); the HTML page is the dashboard.

## B. Playtest Recorder

### Player side
Settings > **"Help improve the game: record my playtest to a local file"** (`GameSettings.playtest_data`, saved as
`playtest_data`, **off by default**), with the hint "Off by default. When on, each match saves a small timeline
(times, resources, orders, frame rate) to a file on this computer only. No names or personal data, nothing is sent
anywhere." It applies from the next match.

### What runs
`GameSettings.set_playtest_data` mirrors the value into `ReplayHooks.playtest_enabled`
(`scripts/core/replay/replay_hooks.gd`). At match start (`Skirmish._start_match` -> `ReplayHooks.match_started`) the
hook attaches `scripts/core/playtest/playtest_recorder.gd` to the level (skirmish and every mission). **Wave Strike**
(not a Skirmish) calls `ReplayHooks.start_playtest(level, "wave_strike")` itself when `ReplayHooks.playtest_enabled`
(one line, for its owner). Off = no node, no file, and `ReplayHooks.note` costs one extra null check.

Commands are **not noted twice**: the recorder is `ReplayHooks.listener`, so it hears the same `note()` stream the
Replay Lab records (train, place, cast, attack_move, formation_move, gather, rally, use_item...; `move_input` and
selections are skipped). When a Replay Lab recording runs for the same match (`ReplayHooks.auto_record`, dev), the
playtest file gets a `replay` line and the report prints the `tools\replay_lab\run_replay.ps1 -Path ...` command to
verify / watch it.

### File: `user://playtests/<date>_<mode>[_n].jsonl` (`%APPDATA%\Godot\app_userdata\Four Wizards RTS\playtests\`)
One JSON object per line, key `k`:
| k | Content |
|---|---|
| `header` | v, game (commit), date (day only), mode (`skirmish` / `mission_<id>` / `wave_strike`), mission, map, map_size, kingdoms, controls, sample_every (5 s), retry (same mode again in this session) |
| `s` (every 5 s of game time, held / paused time excluded) | t, cr (crystals), inc (gathered per min), pop / cap, wk (workers), army {type: supply}, tier, bld {type: n}, cam [x, z], hero hp ratio, units, the bot's e_cr / e_inc / e_wk / e_tier / e_army, keys / clicks since the last sample, frame ms [p50, p95, p99, max] |
| `ev` | `cmd` (c kind, p [x, z], id), `death` (team, type, p, hero, kt), `hero_fell`, `built`, `tier`, `objective` (id, state), `mission_event` (E-id, `MissionBase.event_fired`), `idle` (no input >= 15 s, dur), `pause` (dur), `hitch` (frame > 50 ms: ms, units, cam) |
| `replay` | file (user://replays/...), seed |
| `end` | outcome win / loss / left, reason, t, rage_quit (left within 60 s of a hero death or after 5+ own deaths in 30 s), paused_s, idle_s, keys, clicks, hitches, cmds, whole-match ms [p50, p95, p99] |

No personal data: no names, OS user, hardware ids or paths outside `user://`. The file is flushed at every sample
(a crash keeps everything but the `end` line).

**Overhead** (`tests/test_playtest_recorder.gd`, measured on a live skirmish): ~2 us of work per frame + ~85 us per
sample every 5 s = **~0.002 ms per frame** (limit 0.1 ms).

### Analyzer
`tools\playtest\analyze.ps1` (all recordings) / `-Latest N` / `-Path a.jsonl,b.jsonl` / `-Name` / `-OutDir` ->
`docs/playtests/<name>.md` + `<name>_fights.png` / `<name>_deaths.png` (top-down heatmaps, 20 m grid). Sections:
Summary, Pacing (per objective: start, time spent, expected, deaths and where, idle; skirmish: tier / army / first
fight milestones; mission E-events), Economy vs bot (per minute), Army composition (per minute), Heatmaps, Input
(hotkeys vs clicks per minute, top orders), Hitches, Tuning suggestions, Replay. Expected objective times:
`tools/playtest/expected.json` (`{"mission_m01": {"<objective id>": seconds}}`, optional), else the median over the
loaded recordings. Suggestion rules: objective >= 2x expected (with deaths and their centroid), unfinished objective,
2+ hero deaths within 15 m, idle > 15 % or a 30 s wait, crystals >= 600 for 30 s, income < 75 % of the bot's
(minutes 3-10), 5+ hitches or p99 > 33 ms, hotkey share < 30 %, rage quit, retry #2+.
