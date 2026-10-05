# Unit Lab: unit-level battle simulator (headless duels + an SC2-style sandbox)

Built 2026-10-05 (JS: "do we have a unit tester where u can simulate battle similar to the SC2 one"). The Balance Lab
(`balance-lab.md`) plays whole bot-vs-bot matches; the Unit Lab plays **fights**: two armies on a flat arena, through the
real game systems, many seeds, a scorecard. Nothing in the game changes; no `data/*.tres` is written.

## What is real, what is set up
- **Real**: `UnitType.create_unit()`, `Unit` combat (targeting, aggro, chase, attack-move, hold, avoidance, navmesh),
  projectiles, armour, statuses, shields, support casters (Rime Seer, Bloomtender), the unit abilities that attach in
  `Unit._ready` (NewUnits12, T3Kit, BowmanKit), the casters' `CasterAbility` (mana, spells, autocast rules, passives) and,
  for `"casters": "bot"`, the real bot brain `AICasters` (caster-units.md 8.2 positioning + 8.3 rules) behind a stand-in
  commander (`tools/unit_lab/unit_lab_commander.gd`, answers only what AICasters asks; never trains).
- **Set up by the lab** (what a player would do): the start formation, level (veterancy XP), the "+" upgrade
  (`UnitUpgrades` modifier), Stats modifiers, statuses, HP %, mana, autocast flags, the orders (attack-move / hold /
  idle / retreat) and a focus rule. Attack-move sides "hunt": every second an idle unit attack-moves to the nearest
  enemy (the player's re-click), so fights never stall out of aggro range (`"hunt": false` turns it off).
- **Fairness**: odd seeds put side A on the player team, even seeds on the enemy team, and the spawn / node order flips
  with it; positions get a seeded jitter of +/- 0.3 m. Same seed = same fight (checked by the test). Measured
  2026-10-05: in an 80-seed Flame Guard mirror the player-team side wins 62 % (the engine's processing order), the
  alternation brings the total to 50 % (40 / 40): **use an even number of seeds**.

## Files
| File | What |
|---|---|
| `tools/unit_lab/unit_lab_spec.gd` | Spec format: JSON / text line / presets / equal-cost normaliser / matrix entries / roster |
| `tools/unit_lab/unit_lab_arena.gd` | The arena (Node3D): ground + navmesh, spawns, orders, tracking, result. Shared by runner and sandbox |
| `tools/unit_lab/unit_lab_commander.gd` | Stand-in commander so the real `AICasters` drives "bot" casters |
| `tools/unit_lab/unit_lab_run.gd` | Headless runner (SceneTree): plays a spec or one shard of it, one JSON line per fight |
| `tools/unit_lab/unit_lab_report.gd` | JSONL -> `scorecard.md` / `.json` (+ `matrix.md` / `matrix.csv`), checks, outliers |
| `tools/unit_lab/run_unit_lab.ps1` | The runner script: shards x variants in parallel through `tools/godot_run.ps1`, then the report |
| `tools/unit_lab/presets/*.json` | Presets: `c1_kilnwarden` ... `c7_passage_retreat`, `mirror_flame_guard`, `damage_plus25`, `equal_hound_guard`, `matrix_t1t2` |
| `tools/unit_lab/setups/` | Sandbox saves (same format, runnable by the runner) |
| `scenes/unit_lab.tscn` + `tools/unit_lab/unit_lab_sandbox.gd` | The interactive sandbox (extends the arena) |
| `tests/test_unit_lab.gd`, `tests/test_unit_lab_sandbox.gd` | Tests |
| `docs/balance/unit_lab/<run>/` | Scorecards; raw JSONL in `..\four-wizards-lab-runs\unit-lab-<run>\` |

## How to use (headless)
```powershell
# a preset (C1-C7 = caster-units.md 7.2)
powershell -ExecutionPolicy Bypass -File tools\unit_lab\run_unit_lab.ps1 c1_kilnwarden
# a text line
... run_unit_lab.ps1 "6 flame_guard + 1 kilnwarden mana=full vs 7 rimeshield ; dist=20" -Seeds 1-20
# cost-equal duel from two ids (armies of ~720 crystals; "kilnwarden+flame_guard" = 1 caster + the rest in Flame Guards)
... run_unit_lab.ps1 -Equal grave_hound,flame_guard -Budget 720 -Seeds 1-20
# matrix: every T1/T2 unit of the 4 kingdoms + the 4 casters at equal cost (or -Entries a,b,c,d for a custom list)
... run_unit_lab.ps1 -Matrix -Kingdoms fire,ice,nature,shadow -Tiers 1,2 -Seeds 1-4
... run_unit_lab.ps1 matrix_t1t2 -Run first_matrix
# A/B with a Balance Lab variant (tools/balance_lab/variants/*.json format, applied in memory per shard)
... run_unit_lab.ps1 c4_gloom_deacon -Variants grave_hound_dps
```
| Parameter | Default | Meaning |
|---|---|---|
| (first) | - | Preset name, `.json` spec path, or a text line (contains ` vs ` or ` ~ `) |
| `-Seeds` | the spec's | `1-10`, `1,3,5` |
| `-Parallel` | 4 | Shards per arm (each a Godot process; the gate caps live runs at FW_GODOT_SLOTS) |
| `-Run` | `yyyy-MM-dd_HHmm` | Run name: scorecard folder `docs/balance/unit_lab/<run>/` |
| `-Variants`, `-NoBaseline` | none | Balance Lab variant JSON(s) (bare name = `tools/balance_lab/variants/<name>.json`) |
| `-Tick` | 60 | Physics ticks per second (30 = faster, coarser) |
| `-Limit` | the spec's | Time limit per fight (s); at the limit the fight is a draw (the `lead` field says who was ahead) |
| `-Matrix`, `-Kingdoms`, `-Tiers`, `-NoCasters`, `-Budget`, `-Entries` | all kingdoms, 1-2, casters on, 720 | Matrix mode |
| `-Equal a,b` | - | Cost-equal duel |
| `-Out`, `-RawDir`, `-TimeoutMin`, `-Log`, `-DryRun` | | Folders, timeout, per-fight logs in the shard logs, dry run |
Single process by hand: `godot --headless --path . -s tools/unit_lab/unit_lab_run.gd --fixed-fps 60 --quit-after 9000000 -- --spec=c6_counter_casters --seeds=1-2 --log=1`
(from PowerShell write `'--'`; the ps1 uses Godot's other separator `++`, which survives `powershell -File`).
Speed: ~1 s per small fight per process (a 6 v 6 fight of 15 s game time = ~0.4 s); the T1/T2 matrix (47 entries,
1081 pairs x 4 seeds = 4324 fights) takes ~40-60 min on 4 slots.

## Spec format
```json
{
	"name": "C1 Kilnwarden vs the Ice line",
	"notes": "free text",
	"seeds": "1-10",            "time_limit": 120,   "distance": 20,   "arena": 80,   "tick": 60,
	"arms": [
		{"name": "caster",
		 "a": {"groups": [{"id": "flame_guard", "count": 6},
		                  {"id": "kilnwarden", "count": 1, "mana": "full", "level": 1, "plus": false,
		                   "mods": {"attack_damage_pct": 0.25}, "statuses": [["haste", 5]], "hp_pct": 1.0,
		                   "autocast": true, "at": [-10, 0], "bowman": ["scorchbow_heavy_draw"]}],
		       "order": "attack_move", "focus": "none", "casters": "autocast", "formation": "auto",
		       "target": null, "hunt": true, "retreat_to": [-24, 0], "bot_difficulty": 1, "hero": {"kingdom": "ice", "level": 3}},
		 "b": {"groups": [{"id": "rimeshield", "count": 7}]}},
		{"name": "control", "a": {...}, "b": {...}}
	],
	"checks": [{"type": "wr_delta", "arm": "caster", "control": "control", "min": 20, "max": 60}]
}
```
- One fight: `"a"` / `"b"` at the top instead of `"arms"`. Equal cost: `"equal": {"a": id, "b": id, "budget": 720}`.
  Matrix: `"matrix": {"kingdoms": [...], "tiers": [1, 2], "casters": true, "budget": 720}` or `"ids": [...]`.
- Side keys: `order` attack_move / hold / idle / retreat; `focus` none / lowest_hp (every 0.5 s the weakest enemy in
  reach) / casters (`Unit.prefer_casters`, the bots' rule); `casters` autocast (the spells' defaults) / on / off / bot;
  `formation` auto (melee front, ranged and casters behind) / line / block; `target` the attack-move point; `hunt`.
- Group keys: `level` 1-4, `plus`, `mods` (any Stats key, flat or `_pct`), `statuses` [[id, s]], `hp_pct`, `mana`
  (number or "full"; default = the game's 50 start), `autocast`, `at` [x, z] (absolute; side A starts at x = -distance/2,
  B at +distance/2), `bowman` (BowmanUpgrades ids granted to the side's team).
- `hero` (experimental): the kingdom's wizard at `level` with its spells learned; non-Fire wizards autocast
  (`ai_auto_cast`), Vessa only auto-attacks; `items` ids go to its inventory.
- Text line: `"6 flame_guard + 1 kilnwarden mana=full level=2 vs 7 rimeshield order=hold ; dist=20 seeds=1-10 limit=90"`;
  equal cost: `"grave_hound ~ flame_guard @720"`. Group words: count, id, `plus`, key=value (level, mana, hp, autocast,
  at=x:z, status=id:s, bowman=a:b, any Stats key); side keys (order, focus, casters, formation, retreat_to=x:z) may
  sit in any group of that side.
- Checks (report, baseline variant): `wr_delta` (arm score - control score, points), `spell_rate` (share of fights with
  a cast), `first_spell` (side/spell X before side/spell Y), `alive_avg` (units alive per fight), `survival`.
- Variants: `-Variants` reuses the Balance Lab format and code (`balance_match.gd apply_to_resources`, in memory).

## Scorecard
- Arms: games, A wins / draws / B wins, **A score** (win 1, draw 0.5) with a **Wilson 95 % interval**, median time to
  kill, units alive per side, **crystal trade** (enemy value destroyed / own value lost; value = cost x HP fraction);
  per unit type: count, survival, damage dealt / taken, **DPS** (dealt / its time alive), kills, **kills and damage per
  100 crystals**; spells (casts per fight, median first cast time); checks PASS / FAIL; variants vs baseline.
- Matrix: ranking by mean score (each opponent weighted equally) with its interval, beats / loses-to counts, crystal
  trade, **top 10 outliers** (mean >= 70 % or beats >= 85 % of opponents = too strong; mean <= 30 % or loses to >= 85 % =
  too weak; then by distance from 50 %), the **counter table** (3 best counters, 3 best prey), and the full sorted
  table in `matrix.md` / `matrix.csv` (cell = the row's score vs the column).

## Sandbox (scenes/unit_lab.tscn)
Dev only, not in the player menus. Open with `godot --path . res://scenes/unit_lab.tscn`, or the game's flag
`godot --path . -- --unit-lab` (main menu -> sandbox), or **Ctrl+Shift+U** on the main menu in debug builds.
- Left panel: kingdom / unit (all units of the kingdom, any tier) / count / team / level / HP % / "+" / full mana;
  **right-click or Space** spawns at the cursor (block formation), "Spawn at side spot"; statuses and modifiers
  (+25 % damage, +25 % HP, +10 armour, -25 % cooldown, +1 speed) to a team; per side: order (attack_move / hold / idle /
  **bot** = attack-move + focus casters + AICasters), focus, casters mode; setup file save / load (`tools/unit_lab/setups/`,
  also loads presets and text lines: arm 0 becomes the setup).
- Right panel: Start (Enter), Pause (P), Step 0.1 s (N), Reset = respawn the same setup (R), Clear, Slower / Faster
  (- / =, 0.1x-3x), Heal all = HP and mana (H), Kill inspected (Delete), Shot (F12, `user://unit_lab_shots/`); the
  inspected unit's live stats (left-click: HP, armour, shield, damage, cooldown, range, speed, dealt, DPS, taken, kills,
  statuses, mana / spell cooldowns / autocast); its attack range and aggro circles (C = circles on every unit); the
  **damage meter** (per side and type: alive, damage, DPS, taken, kills) and the **fight log** (deaths, casts, end).
- Arrows / middle-drag pan, wheel zoom. Placement happens paused; the fight runs only after Start.

## Limits (v1)
- Flat arena only: no river, ramp, forest cover or buildings yet (the arena has `build_arena()`; terrain is the next step).
- No kiting / micro beyond the orders and focus rules; ranged units stand and shoot as the game's own Unit logic does.
- Healing is not counted (only damage); summons are tracked (flagged "summon", cost 0).
- Matrix entries are judged **alone** at equal cost: support units (Rime Seer, Bloomtender) and units built for a mix
  read "too weak" by construction; the caster entries are "caster + its kingdom's line unit" (caster-units.md 7.1).
- Hero support is experimental (no hero AI beyond the wizards' `ai_auto_cast`); items only on heroes.
- Draws at the time limit count 0.5; the `lead` field records who was ahead on value.
- Bowman / "+" upgrades: "+" is the `plus` modifier; BowmanUpgrades are granted per team (code effects read
  `team_has`), cleared with the arena.

## First results (2026-10-05)
`docs/balance/unit_lab/first_matrix.md`: the T1/T2 matrix (47 entries, 4324 fights, ~45 min on a shared PC) and the
C1-C7 caster duels (`docs/balance/unit_lab/c*/scorecard.md`). Top outliers: Hollow Oathsworn (99 %), the four T2
cavalry (87-93 %), Scorchling (89 %); Hexweaver / Ash Hurler (5-6 %); the casters score below their own line unit at
equal cost and fail C1 / C3 / C4 / C5-Kilnwarden / C7.

## Next steps
1. Terrain: a river strip with a ford, a ramp, a forest band (the map kit's colliders + navmesh carve) as `"terrain"`.
2. Kiting micro option for ranged sides; a "bot army" order that reuses the Commander's fight code.
3. Matrix at several budgets (360 / 720 / 1440) to catch units that scale badly with numbers (splash, Lanchester).
4. Feed the matrix means into the Balance Lab suggest step (a unit-level prior instead of the B1 formula).
