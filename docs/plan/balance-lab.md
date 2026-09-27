# Balance Lab: stat variants A/B on the Bot Lab

Built 2026-09-26 night (Labs program item 1, `docs/plan/waves.md`). Runs Bot Lab matches (`docs/plan/bot-lab.md`) for a
**baseline** arm and one or more stat **variant** arms over the same pairs and seeds, compares win rate / length / score
per matchup, and a **suggest** step ranks knob changes (stat or cost) that should bring each kingdom toward 45-55 %.
Scorecard style of the other labs: PASS / WARN / FAIL per check, score 0-100, "Improve next", history log.
Nothing in the game changed: no `data/*.tres` is ever written, no game script is touched.

## Files
| File | What |
|---|---|
| `tools/balance_lab/balance_match.gd` | One match: `extends "../bot_lab/lab_match.gd"` (unchanged Bot Lab match) + `--variant=<json>` applied in memory at match start; adds `"variant"` to the JSON line |
| `tools/balance_lab/run_balance.ps1` | The runner: arms x pairs x seeds, interleaved, run_lab.ps1 machinery (sim, Godot gate, `-StopAt`, timeout), then the scorecard |
| `tools/balance_lab/balance_report.gd` | `results.jsonl` -> `scorecard.md` + `scorecard.json` + a row in `docs/balance/lab/history.md` |
| `tools/balance_lab/balance_suggest.gd` | Data Lab B1 table + kingdom win rates -> ranked knobs, `suggest.md` / `.json`, one variant JSON per top knob |
| `tools/balance_lab/variants/*.json` | Hand-written variants (`grave_hound_dps.json`: Grave Hound damage x0.75) |
| `tests/test_balance_lab.gd` | Unit test (no match): value specs, in-memory apply + restore, report stats / checks / markdown, suggest table and ranking |
| `docs/balance/lab/<run>/` | Scorecards; `docs/balance/lab/history.md` the history; `docs/balance/lab/suggest_<name>/` suggest output |

## Variant format
```json
{
	"name": "grave_hound_dps",
	"notes": "why (free text, copied into suggested variants)",
	"units":     {"grave_hound": {"attack_damage": "x0.75", "cost": 80}},
	"buildings": {"fire_tower":  {"max_hp": "+50"}}
}
```
- Keys under `units` / `buildings` are ids = file names in `data/units/` / `data/buildings/` (the lab worktree's copy).
- Value: a number = the new value; `"x1.15"` (or `"*1.15"`) = multiply; `"+50"` / `"-2"` = add. Int fields stay ints (rounded).
- Only existing numeric fields (int / float) of the resource are accepted. An unknown id, unknown field, a non-number field or
  an unreadable value is reported in the JSON (`variant.errors`) and skipped, never guessed. V1 fails on any error.
- How it applies: `balance_match.gd` `load()`s each named `.tres` before the level loads and edits that object. Godot's
  ResourceLoader cache hands the same object to every later `load()` / `preload` / ext_resource of that path
  (`UnitType.find`, `BuildingType.find`, barracks `trains`), and the lab holds a reference for the whole match so the cache
  keeps it. Nothing is saved.
- **Live proof**: every unit / building of an overridden id that enters the tree is counted with whether its type is the
  same (edited) object: `variant.live = {id: {seen, same}}`. V1 fails if `same < seen`.
  (Fields read at `_ready` into the Stats system use the edited base; Unit levels / items stack on top as usual.)
- Arrays, sub-resources, spells (`data/spells/`), champions, AI profiles: not in v1 (see Next steps).

## How to use
```powershell
# 1. Suggest (seconds, main folder): ranks knobs from the Data Lab table + the newest / biggest Bot Lab results.jsonl
& tools\godot_run.ps1 --headless --path . -s res://tools/balance_lab/balance_suggest.gd --quit-after 600 '--' `
    --results=C:/Users/elzzo/Documents/four-wizards-lab-runs/first-batch-sim/results.jsonl --out=res://docs/balance/lab/suggest_first-batch
# 2. A/B: baseline + the suggested variant(s) on the pairs that matter, several seeds
powershell -ExecutionPolicy Bypass -File tools\balance_lab\run_balance.ps1 -Variants docs\balance\lab\suggest_first-batch\variants\blaze_rider_cost.json `
    -Pairs fire:shadow,shadow:fire,fire:ice,ice:fire -Seeds 1-6 -StopAt 06:00
# Quick sweep (tick 30, 10-minute games scored at the limit), confirm the winner at 60 Hz
.\tools\balance_lab\run_balance.ps1 -Variants a.json,b.json -Pairs shadow:fire,fire:shadow -Seeds 1-8 -Tick 30 -Limit 600 -Early off
```
Note: when calling a Godot wrapper `.ps1` (godot_run.ps1) write the separator as `'--'`: PowerShell eats a bare `--`.

| Parameter | Default | Meaning |
|---|---|---|
| `-Variants` | none | Variant JSON paths (comma list); a bare name is looked up in `tools/balance_lab/variants/` |
| `-NoBaseline` | off | Skip the baseline arm (compare to an older run by merging the results.jsonl files by hand) |
| `-Pairs` | the 12 non-mirror pairs | `player:enemy` comma list; give both seat orders (`fire:shadow,shadow:fire`) |
| `-Seeds` | `1` | `1-6`, `1,2,3` |
| `-Run` | `yyyy-MM-dd_HHmm` | Run name: scorecard in `docs/balance/lab/<run>/`, raw in `..\four-wizards-lab-runs\balance-<run>\` |
| `-Dir`, `-Parallel`, `-Difficulty`, `-Style`, `-Sim`, `-Limit`, `-Early`, `-Tick`, `-Extra`, `-TimeoutMin`, `-StopAt` | as run_lab.ps1 | Same meaning as the Bot Lab (`docs/plan/bot-lab.md`) |
| `-Set` | none | Ad-hoc arms by unit / building id, no JSON file: one string per arm, `"<id>.<field>=<value>"`, fields joined with `;` (`-Set "scorchbow.attack_damage=x0.9","caravan.pop=1;caravan.cost=+10"`). The id is looked up in `data/units/` then `data/buildings/` of `-Dir` (unknown id = the runner stops); the generated JSON goes to the run's `variants/` folder |
| `-NoHistory` | off | No row in `docs/balance/lab/history.md` |
| `-DryRun` | off | Prints the arms, jobs, expected wall time and the evidence note, starts nothing |

Before starting, the runner prints the **expected wall time** (quiet PC .. busy PC, `tools/bot_lab/lab_eta.ps1`) and,
when an arm has fewer than 98 games, what that batch can show: e.g. `-Variants grave_hound_dps -Pairs shadow:fire,fire:shadow
-Seeds 1-6` = 24 matches, ~31 min quiet / ~3.7 h busy; "12 games per arm; a 20-point change needs ~98 per arm (~4.2 h
quiet / ~30 h busy for 2 arms)". The scorecard's Low-N banner repeats it at the measured pace of that run.

Jobs are ordered seed -> pair -> arm, so the baseline and the variant of one pair / seed start back to back (same machine
load). `-Dir` defaults to the lab worktree (`..\four-wizards-rts-lab`) when it exists, else this repo (laptop); when it has no
`tools/balance_lab/`, the main folder's `balance_match.gd` is used by absolute path and its relative `extends` pulls the
main folder's `tools/bot_lab/lab_match.gd` with it (checked: works). The variant JSON is copied into the raw run folder.

## Scorecard (balance_report.gd)
- Matchups are unordered (`fire-shadow` = both seat orders together); kingdom win rates are non-mirror games only.
- **Score** (per arm, 0-100) = 100 - 2 x points outside 45-55 % (kingdom win rates 2/3, matchups 1/3). A kingdom at 65 %
  costs 20 points on its share. Headline score = the best arm.
- **Checks**: R1 matches ran (0 failed, 0 SCRIPT ERROR); V1 variants applied (no error, live proof); K1 kingdom win rates
  per arm (PASS 45-55 %, WARN 35-65 %, FAIL outside; **below 10 games always WARN**: not enough evidence either way);
  M1 matchups per arm (same bands); L1 median length 15:00-20:00 (not judged when `-Limit` < 20:00); S1 evidence per
  variant (a matchup change with p < 0.05).
- **Significance**: Fisher exact test (two-sided) on win / loss counts, base vs variant, per matchup and per kingdom;
  Wilson 95 % intervals per kingdom. Notes: `significant` (p < 0.05), `a hint` (p < 0.2), `noise at this N` (< 20 games).
  Rule of thumb printed in the card: ~98 games per arm to see a 20-point change, ~392 for 10 points (80 % power). The
  **score share** (a side's total / both totals at the end) is shown as the continuous, lower-noise signal.
- "Improve next": the worst matchup of the best arm (only when outside 45-55 %), the N needed, variants that moved a
  matchup toward 50 % with p < 0.2, script errors.

## Suggest (balance_suggest.gd)
- Unit table = the Data Lab B1 formulas (`tools/data_lab/data_lab_checks.gd` `check_balance`): barracks slots Z X C V B,
  EHP = max_hp x (1 + armor / 100), DPS = attack_damage / attack_cooldown, per 100 crystals. Power per cost
  = sqrt(EHP/100 x DPS/100) (Lanchester square law for a fixed budget).
- **Peers**: combat units are compared with the combat units of their slot, support units (`support_kind` set) with the
  support units of their slot, because the Data Lab's whole-row median mixes both (slot C = Blaze Rider, Grave Hound,
  Rime Seer (shield), Bloomtender (heal)). A Data Lab **lead** (whole-row per-100 ratio beyond x1.6 = B1, or raw
  max_hp / damage beyond x2.5 = F6-like) also gets knobs on the whole-row basis.
- **Knobs**: multipliers on max_hp / attack_damage / cost, at most 25 % per step, half-way (log) to the median:
  the stat itself, the stat with a cost change that keeps power (power-neutral), cost alone (power off), and a
  power-neutral damage / HP trade when one metric is high and the other low. Support units get no DPS or cost knob.
- **Rank** = 0.5 x shape gain (log distance to the median removed, in points) + 3 x band gain x confidence, where band
  gain = points the kingdom's win rate moves into 45-55 % under the prior "10 % unit power ~ 3 win-rate points"
  (`WR_PER_POWER`), confidence = kingdom games / 20. The prior is a guess: the A/B run measures the real effect.
  Verdicts: toward / neutral / away from 45-55 %. The top 3 (one per unit, never "away") are written as variants.

### First suggest (first-batch-sim win rates, N = 6 per kingdom: low confidence)
`docs/balance/lab/suggest_first-batch/suggest.md`. Win rates: Fire 5/6, Nature 5/6, Shadow 1/6, Ice 1/6.
- **grave_hound** (Data Lab: DPS/100 x2.2 of slot C): against its combat peer (Blaze Rider) it is only DPS x1.19, power
  x1.05: the B1 flag comes from the two support units in slot C. Every nerf pushes Shadow (17 %) further away: **do not
  nerf it now**; the only option that doesn't hurt Shadow is power-neutral (damage 8 -> 6 with cost 70 -> 61, more
  hounds for the same crystals). The hand-written `grave_hound_dps` variant (damage x0.75 alone) is the "away" knob, kept
  as the validation variant precisely because the lab should see it hurt Shadow.
- **ash_hurler** (EHP/100 x0.23, raw max_hp x0.14): a real outlier (glass artillery), but Fire already wins 83 %: any
  HP buff is "away"; the power-neutral options (more HP + less damage, or more HP + higher cost) are the ones to test.
- **blaze_rider** (raw max_hp x3.1, damage x2.6 of slot C): per cost it is in line with its combat peer; on the Data
  Lab's whole-row basis its power/cost is x1.40, and Fire needs a nerf: top knob **cost 180 -> 212** (power -15 %).
- Top 3 written: blaze_rider cost 180 -> 212; rimeshield HP/damage trade; rime_colossus HP/damage trade.

## Validation (tiny run, 2026-09-26 23:31 - 00:05)
`run_balance.ps1 -Variants grave_hound_dps -Pairs shadow:fire,fire:shadow -Seeds 1 -Limit 600 -Early off -Run
2026-09-26_validation -StopAt 00:33`, lab worktree, sim (partial), machine busy (6-7 Godot processes: the gate held the
last two matches ~12-15 min; wall 34 min for 4 matches of ~3.5-4.5 min each). Scorecard:
`docs/balance/lab/2026-09-26_validation/scorecard.md` (WARN: low N, as expected).
- 4 / 4 matches ok, 0 SCRIPT ERROR (the exit-time "ObjectDB leaked" warning is the Bot Lab's own, same in the baseline).
  The relative `extends` worked from an absolute path in the lab worktree. Speed x3.3 of real time in sim.
- V1 PASS: `grave_hound.attack_damage 8.0 -> 6.0`, 0 errors, **live proof 9 / 9 Grave Hounds on the edited type**.
- Baseline fire-shadow 1-1, variant (hound damage x0.75) 2-0 for Fire; Fire's score share 57 % -> 59 %. Direction as
  expected (nerfing a Shadow unit helps Fire), but p = 1.00 at N = 2 per arm: a smoke of the lab, not a balance result.
- `tests/test_balance_lab.gd`: PASS (headless, < 2 s).

## Lab review 2026-09-27
- `-Dir` falls back to the repo when the lab worktree is missing (laptop); default `-Parallel` is capped at the gate's
  `FW_GODOT_SLOTS` (4).
- Expected wall time + evidence note before a run, `-DryRun`; the scorecard's Low-N banner gives the hours needed for
  98 / 392 games per arm at the run's own pace.
- `history.md` links the scorecard relatively (`<run>/scorecard.md`) instead of an absolute desktop path.
- `tests/test_balance_lab.gd`: PASS (laptop, 2026-09-27). No match run today (the machine is shared: no balance numbers).

## Arms for the new bowmen and the caravan 0 supply (U5, 2026-09-27)
Variant files in `tools/balance_lab/variants/` (the test applies every one of them with 0 errors on today's data):
| Arm | Change | Question it answers |
|---|---|---|
| `caravan_pop1` | `caravan.pop` 0 -> 1 (the old value) | What the caravan's 0 supply is worth: baseline (0 supply) vs this arm. Use `-Limit` >= 900 (caravans pay after 5:00) |
| `bowmen_cost_up` | `scorchbow` / `frostbow` / `bleakbow` / `wildwood_archer` cost x1.2 | How much each kingdom leans on its bowman (a big shift = a pillar unit) |
| `scorchbow_dmg_down` | `scorchbow.attack_damage` x0.9 (14 -> 12.6) | `bowmen.md` 8: the first knob if Fire rises (the Heavy Draw upgrade is code, not a variant field) |
| `wildwood_cost_up` | `wildwood_archer.cost` 85 -> 100 | `bowmen.md` 8: Hunting Party halves the archer's price late (the upgrade price is code) |
Any other bowman knob: `-Set "<bowman id>.<field>=<value>"` (ids `scorchbow`, `frostbow`, `bleakbow`, `wildwood_archer`).
Limits: upgrade prices / effects (`BowmanUpgrades`), `BowmanKit.BOT_SHARE` and `BOWMEN_ENABLED` are constants in code,
not data, so "bowmen off" is not a variant: compare with a `-Dir` worktree on a commit before the bowmen. The `-Dir` must
have the bowmen's `.tres` (V1 fails on an unknown id). Suggested first run (quiet PC, ~2 h): `-Variants
caravan_pop1,bowmen_cost_up -Pairs fire:ice,ice:fire,shadow:nature,nature:shadow -Seeds 1-6 -Tick 30 -Limit 900 -Early off`.
Only a `-DryRun` was done today (the PC was busy): 6 arms x fire:nature planned, ~10 min quiet.

## Next steps
1. **Lead**: commit `tools/balance_lab/`, `tests/test_balance_lab.gd`, `docs/balance/lab/`, this file. Move the lab
   worktree to a tag that has `tools/bot_lab/` + `tools/balance_lab/` (then everything runs from the worktree's own copy).
2. First real A/B: the 3 suggested variants + `grave_hound_dps`, pairs with Fire / Shadow in both seat orders, seeds
   1-8, `-Tick 30 -Limit 900 -Early off` sweep; confirm the best one at 60 Hz with 1-12. Needs ~2-3 h of machine time.
3. Calibrate `WR_PER_POWER` from those runs (measured win-rate shift / power change) so the suggest ranking uses data.
4. Variant grids: `-Grid "grave_hound.attack_damage=x0.8,x0.9,x1.0"` expanding into one arm per value.
5. More knobs: spells (`data/spells/` rank arrays), building fields (tower damage), train_time, AI profile numbers;
   array / sub-resource overrides with an explicit path syntax.
6. Paired analysis per seed (same seed baseline vs variant) once the game is deterministic (bot-lab.md next step 6).
7. Army composition in the Bot Lab JSON (units trained per type) so the suggest step can weight a unit by how much its
   kingdom actually uses it.
