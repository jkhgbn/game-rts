# Waves plan v2

One wave = one week. Goal: use about **50% of the Claude Max 5x weekly limit**, spread evenly over the week.
v2 (2026-09-25) merges plan v1 with the Astra plan: vertical slice first (Fire vs Shadow, mission 1 against
AI by the end of wave 3), medium effort by default, a perf test from day one, and a playtest after every wave.
## Team
| Agent | Model | Default effort | Owns |
|---|---|---|---|
| lead (main session) | Opus 5.5 | medium | `project.godot`, `scenes/main.tscn`, `CLAUDE.md`, `docs/plan/`, `tests/smoke_test.gd`, `tests/perf_test.gd`, contracts, merging |
| game-designer | Opus 5.5 (`claude-opus-5-5`) | **high** | `docs/design/` (all design but UI; from 2026-09-25, user request). Works **one wave ahead**. |
| ui-designer | Fable (`fable`) | medium | `docs/design/ui-*.md`: UI / HUD / menu layout only. |
| tech-artist | Opus 5.5 | high | `art/`: models, shaders, particles, animation (several in parallel, split by subfolder). |
| items-coder | Opus 5.5 | medium (`-high` for [H]) | `scripts/items/`, `data/items/` (wave 4). |
| gameplay-coder ("battlefield") | Opus 5.5 | medium | `scripts/units/`, `scripts/spells/`, `data/units/`, `data/spells/` |
| systems-coder ("kingdom") | Opus 5.5 | medium | `scripts/economy/`, `scripts/buildings/`, `scripts/world/`, `scripts/campaign/`, `data/buildings/`, `missions/` |
| ui-coder | Opus 5.5 | medium | `scripts/ui/`, `scripts/vfx/`, `scenes/ui/`, `assets/audio/` |
| ai-coder (helper) | Opus 5.5 | medium | `scripts/ai/`. Waves 3-5 only. |

Agent files: `gameplay-coder-high` and `systems-coder-high` are copies with `effort: high`, used only for [H] tasks.
The UI never needs high effort.

## Contracts (frozen at the start of each wave; lead-only changes)
- **Unit** (`scripts/units/unit.gd`, group `"units"`): `team`, `command_move(Vector3)`,
  `command_attack(Unit)`, `command_stop()`, `take_damage(amount, attacker)`, `heal(amount)`,
  `is_alive()`, `is_enemy_of(Unit)`, signal `died(unit)`. New orders (attack-move, hold) are added the same way.
- **UnitType** resource (`data/units/*.tres`): `id`, `display_name`, `faction`, `cost`, `pop`,
  `train_time`, `max_hp`, `move_speed`, `attack_damage`, `attack_range`, `attack_cooldown`,
  `aggro_range`, `model_scene`. Nothing reads `UNIT_TYPES` after task 1.G1.
- **Wizard**: `command_cast(spell_id: StringName, target) -> String` (`""` = ok, otherwise the reason).
  It replaces `command_fireball` in wave 2.
- **Economy** (one per team): `crystals`, `pop_used`, `pop_cap`, `can_afford(cost)`,
  `spend(cost) -> bool`, `add(amount)`, signal `changed`.
- **Events** autoload (added by the lead in wave 0): `unit_died(unit)`, `building_completed(building)`,
  `artifact_claimed(artifact, wizard)`, `objective_changed(id, state)`, `mission_ended(victory)`.
- The UI only calls public functions (no `_private` calls). The smoke test calling
  `selection._formation_move` gets a public `formation_move` in wave 0.

## Budget
- Target: **50% of the weekly all-models limit**, about **7% a day**. One wave = one week.
  Pace line: day *d* ≤ 7% × *d*. Hard stop at 50%.
- The week resets **Saturday ~1 AM** (Quebec time). Usage on 2026-09-25: weekly 8%, Fable 2%, 5-hour 56%.
- Split per wave: designer 8% · coders ~30% · lead 6% · **reserve 6%** (integration and fixes).
- Don't start a task when the 5-hour meter is above **70%**.
- After wave 1, compute **cost per point** in `usage-log.md`. Above ~1.7%/point: remove [H] tags
  or move the lowest task to the next wave.
- Above the pace line: skip a session (playtest instead), drop [H] to medium, or move *optional* tasks.

## Weekly rhythm (unchanged from v1)
Day 1 designer (next wave) · Day 2 session A (2 coders) · Day 3 playtest, no agents ·
Day 4 session B (2 coders) · Day 5 session C (leftovers, merge) · Days 6-7 buffer.
Task sizes: S = 1, M = 2, L = 3 points. Max 6 points per agent per wave. If an agent goes over, use the helper.

## How a session merges
1. The lead reads usage, then the wave's tasks. Tasks come only from this file.
2. Backup zip `wave<N>-<session>-before.zip` (no Git yet; with Git: one branch per coder instead).
3. The two coders of a session work in the same folder but only in their own folders. Pair coders whose
   tasks don't depend on each other; a task that needs another's result waits for the next session.
4. Each coder: smallest change that meets "done when", its own `tests/test_<task-id>.gd`, runs import +
   smoke + perf + own test, reports in under 150 words (files, test lines, handoffs).
5. The lead re-runs everything on the combined result: `--import` without errors, smoke `victory=true`,
   `PERF OK`, every task test `PASS`, no duplicate `class_name`.
6. If a check fails: send it back to the same agent **once**. If it fails again, stop and tell the user.
7. Green: backup `wave<N>-<session>-green.zip`, tick tasks, update `usage-log.md`, playtest list (3-5 lines).

---

## Wave 0: Setup (lead only): DONE 2026-09-25
- [x] Project unzipped to `Documents\four-wizards-rts`, `config/features` = 4.7, desktop shortcuts
      "Four Wizards - Play" / "Four Wizards - Editor".
- [x] Smoke test fixed on 4.7.2. It failed about 1 run in 3: idle soldiers crowded the gap between the
      ruin pillars and avoidance stopped the wizard. Fix: moving units get avoidance priority 1.0,
      idle ones 0.5, so idle units step aside. 12/12 runs green after the fix.
- [x] `Events` autoload (`scripts/core/events.gd`), public `SelectionManager.formation_move`.
- [x] `tests/perf_test.gd` + `tests/_template.gd`. Agent files: medium effort, no worktrees, per-task tests,
      `-high` copies. `CLAUDE.md` rewritten (Godot path, contracts, ownership, playbook).
- [ ] **User:** download the design-day files (`docs/design/*.md`: gdd, units, UI layout) from the other chat
      and put them in `docs/design/`. They are not in the zip. Wave 1 needs them.
- [ ] **User (optional, recommended):** install Git for Windows (git-scm.com, default options). Until then,
      the lead makes zip backups before and after each session (see `CLAUDE.md`).

**Perf baseline** (headless, logic only, this PC): 10 units 0.6 ms/frame · 100 units 6.5 ms · 200 units 13.4 ms.
Budget: 8 ms per 100 units. 200 units already use most of a 60 fps frame before graphics, so task 4.G2
must bring 200 units under 8 ms (likely culprit: every unit scans every other unit to find targets).
## Wave 1: Economy and army controls (Fire vs Shadow)
Specs: `docs/design/gdd.md`, `units-fire-shadow.md`, `economy.md`, `ui-hud.md` (rewritten 2026-09-25;
the design-day originals were lost).
| Id | Task | Owner | Size | Session |
|---|---|---|---|---|
| 1.G1 ✅ | `UnitType` resources for every unit in the spec (incl. workers); `main.gd` builds units from them | gameplay | M | A |
| 1.G2 ✅ | Unit side of attack-move and hold: `command_attack_move(Vector3)`, `command_hold()` | gameplay | S | A |
| 1.G3 ✅ | Shadow Wizard (Malrik) + Shadow Lance (heals for half the damage), casts by simple rules | gameplay | M | A |
| 1.U3 ✅ | Minimap: units, camera rectangle, click to move the camera, right-click to move units | ui | M | A |
| 1.U4 ✅ | Hotkeys A (attack-move), H (hold), S (stop), control groups Ctrl+1-9 / 1-9 | ui | S | A |
| 1.S1 ✅ | Crystal nodes; workers gather and return to the keep **[H]** | systems | L | B |
| 1.S2 ✅ | Keep trains units: queue of 5, cancel refunds, rally point | systems | M | B |
| 1.S3 ✅ | Population cap (basic 1, rider 2, Shadow Knight 3) | systems | S | B |
| 1.D1 ✅ | Specs for wave 2: Fire and Shadow spells (3 each), buildings, fog-of-war rules | designer | L | B |
| 1.D2 ✅ | Enemy AI behaviour spec for wave 3 | designer | M | B |
| 1.U1 ✅ | Top bar: crystals and population | ui | S | C |
| 1.U2 ✅ | Command card (orders, Fireball, keep training buttons) | ui | M | C |
| 1.U5 ✅ | Selection panel (hero column, unit icons, keep queue) + selecting the keep, rally and gather right-clicks | ui | M | C |

Added by the lead after reading the specs: 1.U5 (the selection panel was in `ui-hud.md` but in no task),
the Keep / CrystalNode / Worker / Economy contracts in `CLAUDE.md`, and restart moves from R to F9
(R trains a Blaze Rider when the keep is selected; systems changes it in `main.gd` during 1.S2).
ui ends at 8 points this wave; accepted because its session C has only 3 other points.

Why this order: 1.G2 was split (the keys live in `selection_manager.gd`, owned by ui). Session A pairs two
coders that don't depend on each other. Systems (B) needs the `UnitType` resources from 1.G1. The top bar and
command card (C) need the economy and training from B.
In session A, gameplay may edit `make_unit` / `_spawn` in `scripts/world/main.gd` (one-time permission).
Load: gameplay 5 · systems 6 · ui 6 · designer 5.
**Playtest 1:** gather crystals, train a group, attack-move, use control groups, kill the Shadow Wizard. Is the camera comfortable?

**Playtest 1 feedback (2026-09-25):** the user didn't see the economy (the keep was hidden under the bottom
panel at the start and nothing pointed at it). The user wants: **a 1v1 match against a bot, no scripted waves**
(PvP later), **buildings**, **an enemy with its own economy**, and **WASD to walk the wizard**.
So the old waves 2 and 3 are replaced by wave 2 (1v1) below. Spells and fog of war move to wave 3.
Online PvP is a big separate job (networking); it's parked until the 1v1 vs bot is fun.

## Wave 2 (NEW): 1v1 against a bot
Specs: `docs/design/buildings.md`, `docs/design/skirmish-1v1.md` (new, 2.D1), `docs/design/ai.md` (rewritten
by 2.D1: the bot plays like a player, no timed waves). New keys and contracts in `CLAUDE.md`.
| Id | Task | Owner | Size | Session |
|---|---|---|---|---|
| 2.D1 | `skirmish-1v1.md` (symmetric map, win/lose, wizard respawn), `ai.md` rewrite, key scheme in ui-hud/buildings/spells | designer | L | A |
| 2.S1 | Buildings: `Building` base, `BuildingType` data, `BuildGrid` placement rules, worker construction, barracks / hearth / spire for both kingdoms, keep trains only workers, navmesh rebake **[H]** | systems | L | A |
| 2.S2 | Start camera shows the keep and workers (not under the HUD) + a start hint "Click your Keep to train workers" | systems | S | A |
| 2.G1 | Units and wizards attack buildings (unit-first targeting, explicit orders obeyed), towers shoot | gameplay | M | A |
| 2.G2 | `Wizard.set_move_input(dir)` direct control | gameplay | S | A |
| 2.S3 | 1v1 map: mirrored Shadow base (keep, workers, nodes), win / lose from `skirmish-1v1.md`, wizard respawn | systems | M | B |
| 2.U1 | New key scheme incl. WASD (camera-relative, camera follows), build menu + ghost, building selection panel + training, site cancel | ui | L | B |
| 2.A1 | The bot: economy, build order, training, attacks and defends like a player (from `ai.md`) **[H]** | ai-coder | L | B |
| 2.G3 | `Team.NEUTRAL`, the Ruin Warden neutral unit, `Wizard.respawn(at)` | gameplay | S | B |

Decisions taken from `skirmish-1v1.md` (user to confirm at playtest 2): wizard respawns (30 s, +15 s per death)
instead of instant defeat; defeat = no living building; the Ember Crown in the centre (+100 HP / +50 mana,
guarded by 4 neutral wardens, dropped on death); crystals can be dropped at barracks too (expansion).

**Playtest 2:** a full 1v1 against the bot, from 3 workers to destroying (or losing) a base. Fun from 1 to 10?

## Timing (measured 2026-09-25) and the 30-minute rule
Real agent times: S ~7 min, M ~8-13 min, L ~20-22 min (systems buildings 22.2, ui 2.U1 20.1, ui groups 19.9),
Fable specs 5-10 min. Delays came from L tasks done one after another by the same agent, waiting chains
(ui waited for systems, the bot for the map) and long simulated matches in tests.
**Rule from wave 3 (user request): each step finishes in ~30 min wall-clock.**
- Every task fits a **20-minute time box** (S/M only; L tasks are split by folder or file).
- **Up to 6 agents at once**, each in its own folder/file set; no agent waits for another: code against the
  CLAUDE.md contracts with `has_method` guards; the lead glues at the end (10 min).
- Tests: short (max ~3 game-minutes per test; long bot-vs-bot runs only in the lead's final check).
- An agent that hits 20 minutes stops, reports what's done and what's left; the rest moves to the next step.

## Wave 3 step A (30 min, 6 agents in parallel)
| Id | Task | Agent | Files | Box |
|---|---|---|---|---|
| 3.G2a | Stats pipeline (CLAUDE.md "Stats") + unit veterancy (levels 1-4, marks) | gameplay-coder-high | `scripts/units/unit.gd`, `unit_type.gd`, `data/units/` | 20 |
| 3.G2b | Wizard XP / levels / spell points / learn API (levels.md) | gameplay-coder | `scripts/units/wizard.gd`, `shadow_wizard.gd` | 15 |
| 3.G1 | Spell framework: `SpellType` data + `SpellCaster` node (mana, cooldown, targets, ranks) + the 6 spells | gameplay-coder-high | `scripts/spells/`, `data/spells/` | 20 |
| 3.U1 | Level/XP bar, level-up flash, spell buttons with ranks, Ctrl+F/Q/E learn, cooldown sweep, veterancy chevrons in panel | ui-coder | `scripts/ui/` | 20 |
| 3.V1a | Painted shader + world environment + **Fire Keep** | tech-artist | `art/shaders/`, `art/environment/`, `art/buildings/fire_keep*` | 20 |
| 3.V1b | **Dusk Keep** (uses `art/shaders/painted.gdshader` if it exists at the end, else its own materials) | tech-artist | `art/buildings/dusk_keep*` | 20 |
Glue by the lead (10 min): Wizard ↔ SpellCaster wiring, Crown bonus → modifier, integration tests.

**Step A done 2026-09-25** (6 agents, all ≤ 11 min, integration 10 min): 26/26 task tests PASS, smoke 3/3,
perf 6.6-6.9 ms quiet (over 8 ms only while 6 agents ran Godot at once), bot vs bot won at 7:18. Tag `wave3A-green`.

## Wave 3 step B (30 min)
3.U2 spell effects (tech-artist, `art/vfx/`), 3.V2 keep states (tech-artist; also: Fire Keep reads small at
40 m — scale it up, orbiting crystals bigger, ground contact decals), 3.S1 plug keeps + environment (systems;
also `building.gd` must call `Unit.award_soldier_kill_xp(building, killer)` when a building dies),
3.A1 bot learns spells per difficulty (ai-coder; Malrik already casts via `suggest_cast()`),
UI: read status timers from `unit.status_time_left(id)` (SpellStatus nodes aren't created when Unit has
`apply_status`), balance fixes from playtest 2.

## Wave 3 (NEW): Levels and spells
The user asked for a level system (2026-09-25), placed right after the 1v1. Heroes earn XP and levels, and levels
unlock and upgrade spells (spells.md), so spells and levels ship together. Fog of war moves to wave 4.
Spec: `docs/design/levels.md` (3.D1, written during wave 2).
| Id | Task | Owner | Size | Session |
|---|---|---|---|---|
| 3.D1 | `levels.md`: XP sources, level curve, stat growth, spell unlocks / ranks, unit veterancy (if any), HUD, bot use | designer | M | during wave 2 |
| 3.G1 | Spell framework (`command_cast`, mana, cooldowns, target types) **[H]** | gameplay | M | A |
| 3.G2 | **Stats pipeline** (CLAUDE.md "Stats": base + named modifiers, `get_stat`) then XP + levels for wizards **and for units** (user request) on top of it, level marks above units. The Crown's bonus moves to a modifier. **[H]** | gameplay | L | A |
| 3.G3 | Vessa's and Malrik's 3 spells with ranks | gameplay | M | B |
| 3.U1 | Level / XP bar in the hero column, level-up flash, spell buttons with ranks and learn buttons, cooldown icons | ui | M | B |
| 3.U2 | Spell effects (6 spells) | ui | M | B |
| 3.A1 | The bot learns spells and casts them by the rules in `ai.md` / `levels.md` | ai-coder | S | B |

**Art track in wave 3 (user request 2026-09-25: "the main building must look epic").** New agent **tech-artist**
(`art/`), runs in parallel with the coders (no shared folders). Spec `docs/design/art-keep.md` (3.D2, now).
| Id | Task | Owner | Size | Session |
|---|---|---|---|---|
| 3.D2 | `art-keep.md`: art direction for the Fire Keep and the Dusk Keep (silhouette, parts, materials, lights, effects, states) | designer | M | now |
| 3.V1 | Epic Fire Keep + Dusk Keep scenes (`art/buildings/`), built from primitives + shaders + particles + lights **[H]** | tech-artist | L | A |
| 3.V2 | Keep states: construction rise, damage (smoke/fire under 50 % / 25 %), destruction collapse, selected glow, training pulse | tech-artist | M | B |
| 3.S1 | Plug the keep scenes in (`BuildingType.model_scene`), call the visual hooks (hp ratio, progress, destroyed, training), and use the tech-artist's `art/environment/world_env.tres` in `main.gd`'s `_build_environment` (the environment is built in code, not in the .tscn) | systems | S | B |

**Playtest 3:** does levelling feel good? Is the keep epic from the game camera? Is a level 5+ wizard too strong in a 1v1?

## Wave 4 (NEW): Items (full agent stack)
The user asked (2026-09-25) for an item system like hero RTS / MOBA games (inventory, shops, recipes, actives,
items found on the map), built now for the 1v1 and ready for the campaign (items carried between missions).
New agent: **items-coder** (`scripts/items/`, `data/items/`; `-high` copy for [H]). Spec `docs/design/items.md`
(4.D1, written during wave 3). Fog of war moves to wave 5.
| Id | Task | Owner | Size | Session |
|---|---|---|---|---|
| 4.D1 | `items.md`: slots, economy (what items cost and why), tiers, recipes, actives, consumables, shops, map drops / chests, campaign carry-over, bot buying, HUD | designer | L | during wave 3 |
| 4.I1 | `ItemType` data, `Inventory` (6 slots), buy/sell rules, stat items through the Stats API **[H]** | items-coder | L | A |
| 4.I2 | Recipes (combining), active items with cooldowns, consumables | items-coder | M | B |
| 4.G1 | Item effects that need unit code: on-hit effects, auras, spell power / cooldown reduction hooks | gameplay | M | A |
| 4.S1 | Shops on the map (base shop + neutral shop), item drops from Ruin Wardens and chests, campaign save of items | systems | M | B |
| 4.U1 | Inventory bar (6 slots, keys), shop window, item tooltips, drag / drop / sell, pickups on the ground | ui | L | B |
| 4.A1 | The bot buys and uses items (build list per difficulty from items.md) | ai-coder | M | B |

**Decided by the lead (defaults, user can change):** items use **Numpad 1-6 or a click** (Alt+N stays the
group steal); items cost **essence**; the 100 crystals -> 40 essence exchange stays; T = shop.

## Plan change 2026-09-25 (evening): the user is now on **Claude Max 20x**
All meters restarted at 0 %. The 20x limits are 4x the 5x ones, so expect roughly **3 % of the 5-hour meter per
6-agent step** (was 11-13 % on 5x) and ~0.5 % of the week per step (was ~2 %). Rules kept: stop launching at
**95 %** of the 5-hour meter, end each step on a playtest; weekly pace line stays 50 % of the week unless the user
says otherwise. Recalibrate from `usage-log.md` after the first 20x step.

**Scaling on 20x (user request):** 3-4x more agents per step from the next step on (~15-24 in parallel,
still split by file, 20-min boxes). First move: 5 agents at once — 3 character tech-artists (4.V1-4.V3, after the
Opus review of `art-units.md`), 5.P1 performance (gameplay-high: 100 units ≤ 5.5 ms, 200 ≤ 11 ms) and
5.S1 fog of war core (systems-high).

## Scaled plan on 20x (user request 2026-09-25: "add more agents to each step")
Each step: **15-20 agents in parallel**, split by file/folder, 20-min boxes, then ~15 min of lead integration and
a playtest build. New tech-artists and designers are cheap to add because they never share files.

### Step 5 (now): looks + performance + fog (≈13 agents)
| # | Agent | Task | Files |
|---|---|---|---|
| 1 | gameplay-high | 5.P1 performance (100 units ≤ 5.5 ms, 200 ≤ 11 ms) | `scripts/units/`, `scripts/spells/` |
| 2 | systems-high | 5.S1 fog of war core + ghosts + overlay | `scripts/world/fog_of_war.gd` (+glue) |
| 3-5 | tech-artist x3 | 4.V1 wizards, 4.V2 Fire army, 4.V3 Shadow army + warden | `art/units/<group>/` |
| 6 | tech-artist | 5.V1 barracks art (Ember Hall, Gloom Hall) + states | `art/buildings/fire_hall*`, `shadow_hall*` |
| 7 | tech-artist | 5.V2 hearth / hovel + both towers + states | `art/buildings/{hearth,hovel,*_tower}*` |
| 8 | tech-artist | 5.V3 environment: painted ground, trees, rocks, crystal nodes, crown pedestal, peddlers, caches | `art/environment/` |
| 9 | tech-artist | 5.V4 combat VFX: arrows/bolts, melee hits, deaths, building hits, level-up, pickups | `art/vfx/combat_*` |
| 10 | ui-designer (Fable) | 5.D1 HUD visual redesign (SC2/LoL-inspired frames, icons, fonts) | `docs/design/ui-style.md` |
| 11 | game-designer | 5.D2 balance pass (read data + tests' bot-vs-bot numbers) + campaign mission 1 story spec | `docs/design/balance-1.md`, `mission-01.md` |
| 12 | game-designer | 5.D3 Ice (Torvald) and Nature (Ysolde) kingdoms: units, spells, buildings, items flavour | `docs/design/kingdom-ice.md`, `kingdom-nature.md` |
| 13 | ui-coder | 5.U1 main menu + skirmish setup (difficulty, later kingdom), pause menu | `scripts/ui/menus/`, `scenes/ui/` |

### Step 6 budget rule (user request 2026-09-25, overnight)
Use the whole 5-hour window: launch Step 6 agents in waves until the meter reaches **~90 %**, keep **~8 %** for the
lead's integration (at 100 % the lead is blocked too), and leave a **playtest-ready build** in the Playtest
shortcut (`four-wizards-rts-play` worktree) with a short "what's new" note in `docs/plan/playtest-notes.md`.
If the window resets overnight, continue with the next useful tasks under the same rule.
**User update (2026-09-25, before sleeping):** the user wakes at ~6 AM (Quebec). Window 1 (until ~1:10 AM): up to
~90 %. Window 2 (~1:10 → ~6:10 AM): **stop launching at ~80 %** so **~20 % is left for the user** when they wake up;
the playtest build and `playtest-notes.md` must be ready before 6 AM.

**Lead TODO after 5.P1 (perf) finishes** (from 6.B1): `unit.gd:31` `VETERANCY_XP` -> `[0, 120, 350, 800]` and
`test_3_g2a.gd:125` `add_xp(700)` -> 800; spell_power cap 100 -> 60 in `unit.gd:62/65` and `spell_caster.gd:391`
(inventory.gd done).

### Step 6: plug everything in + UI redesign (≈16 agents)
gameplay 4.G2 character models + animation hooks · systems plugs building/environment art · ui-coder x3 build
the HUD redesign (panels / command card + inventory / minimap + fog) · ai-coder: bot "seen" memory from fog ·
gameplay applies balance-1 · tech-artist x3: unit polish from screenshots, UI icons (spell/item/unit icons as
rendered sprites), menu background scene · sound: a tools script generating placeholder SFX + an `AudioManager`
(ui-coder) · game-designer: Ice/Nature review + mission 1 map layout · tests: bot-vs-bot at 3 difficulties.

### Art polish track (user request 2026-09-26: "art takes more time, split into sub-elements, no 30-min limit")
One agent per element, no time box. Running: A.1 Vessa, A.2 Malrik, A.3 Torvald, A.4 Fire army, A.5 Shadow army,
A.6 Ice army. **Queue** (launch as agent slots free up — the app allows 20 agents at once):
A.7 Fire Keep epic pass · A.8 Dusk Keep + Rime Keep · A.9 Fire/Shadow halls, houses, towers (+ mesh merge) ·
A.10 terrain + props · A.11 lighting / sky / post-process · A.12 combat VFX polish · A.13 Vessa/Malrik spell VFX ·
later: A.14 Ysolde + Nature army polish, A.15 icons re-render, A.16 UI art (frames, portraits).

### Step 7 as launched (2026-09-26 night): task ids from `kingdom-ice.md` §10 and `mission-01.md` "Done when"
Mission ids are prefixed **M** to avoid clashes (M7.S1-S3, M7.U1); both ai tasks run as one agent (same files).
7.L1 contracts done by the lead (CLAUDE.md "Kingdoms Ice / Nature", "Campaign", `Events.dialogue`).

### Step 7: Ice kingdom + campaign mission 1 (≈18 agents)
Ice units/spells/buildings/items data (gameplay x2, systems, items-coder), Ice art (tech-artist x3), bot plays Ice
(ai), mission 1 (systems x2: scripted map, objectives, dialogue; ui: briefing, objectives, dialogue box;
game-designer: dialogue lines), campaign save between missions.

### Step 8: Nature kingdom + skirmish kingdom select + export (≈18 agents)
Same pattern for Nature, kingdom select in the menu, 4-kingdom balance, Windows export (.exe) and a smoke run of it.

## Wave 4 "95 %" step (user request 2026-09-25: use the budget up to ~95 % of the 5-hour meter, end on a playtest)
Budget maths (measured): a 6-agent step ≈ 11-13 % of the 5-hour meter. At 70 % → room for **one 10-agent step
(~20 %) + plug-in and integration (~5 %) ≈ 95 %**. The lead checks the meter when agents finish; if it passes 90 %
before the plug-in phase, the plug-in waits for the reset and the playtest uses what's integrated.
Phase 1 (10 agents in parallel, 20-min boxes):
| Agent | Tasks | Files |
|---|---|---|
| items-coder-high | 4.I1: `ItemType` + all `data/items/*.tres`, `Inventory`, buy/sell/drop/swap, item stat modifiers, `EssenceBank` | `scripts/items/` (not recipes/actives files), `data/items/` |
| items-coder | 4.I2: `Recipes`, `ItemActives` (actives, consumables, cooldowns) | `scripts/items/recipes.gd`, `item_actives.gd` |
| gameplay-coder-high | 4.G1: item effect hooks (`attack_landed`, `spell_hit`, DoT, shield, aura, lifesteal, spell power, CDR in SpellCaster) | `scripts/units/`, `scripts/spells/` |
| systems-coder | 4.S1: shops (`is_shop`), 2 peddlers, 4 Lost Caches, warden drop, exchange, campaign item save | `scripts/buildings/`, `scripts/world/`, `scripts/campaign/` |
| ui-coder | 4.U1a: inventory bar (6 + 2 slots, numpad/click, cooldowns), item tooltips, ground pickups, essence in the top bar | `scripts/ui/` (new files `inventory_bar.gd`, `item_tooltip.gd` + top_bar) |
| ui-coder | 4.U1b: shop window (T), recipe tree view, buy/sell | `scripts/ui/shop_window.gd` (new file only) |
| ai-coder | 4.A1: the bot buys and uses items | `scripts/ai/` |
| tech-artist | 4.V1: Vessa + Malrik models and animations | `art/units/wizards/` |
| tech-artist | 4.V2: Fire army models and animations | `art/units/fire/` |
| tech-artist | 4.V3: Shadow army + Ruin Warden models and animations | `art/units/shadow/` |
Phase 2 (~15 min): gameplay 4.G2 plugs the character models in and drives the animation hooks; the lead wires
the shop/inventory into the scenes, runs every test, updates the "Playtest" shortcut, screenshots.
**Playtest (end of step):** a 1v1 with items, new characters, levels, spells and the epic keeps.

**Art track in wave 4: characters (user request 2026-09-25: "make all characters look better").**
Same SC2/LoL-inspired painted style as the keeps (`art-keep.md` section 0). Spec `docs/design/art-units.md`
(4.D2, written now). Runs in parallel with the items coders (only `art/units/` + a small plug-in task).
| Id | Task | Agent | Files | Box |
|---|---|---|---|---|
| 4.D2 | `art-units.md`: silhouettes, proportions, palette, parts, idle/walk/attack/cast/death animation, team colour, veterancy/status looks, LOD rules for 200 units | designer | `docs/design/` | now |
| 4.V1 | Vessa + Malrik (heroes: the most detail, staff/orb glow, cast animation) | tech-artist | `art/units/wizards/` | 20 |
| 4.V2 | Fire army: Cinder Hand, Flame Guard, Ember Archer, Blaze Rider, Ash Hurler | tech-artist | `art/units/fire/` | 20 |
| 4.V3 | Shadow army: Gloom Thrall, Shade, Nightbolt, Grave Hound, Shadow Knight + Ruin Warden | tech-artist | `art/units/shadow/` | 20 |
| 4.G2 | Plug the models in (`UnitType.model_scene`), drive the animation hooks (moving, attack, cast, hit, death, level-up), keep selection rings / HP bars / chevrons working | gameplay | `scripts/units/`, `data/units/` | 15 |
Performance rule: 200 animated units must keep the perf test OK (shared materials, no per-unit lights,
simple procedural animation or AnimationPlayer on few bones/nodes).

**Playtest 4:** buy and combine items in a 1v1; do items make the wizard too strong against the army?

## Wave 5: Fog of war and balance (was wave 4 material)
Fog of war (`fog-of-war.md`), a balance pass from playtests 2-4, performance to 200 units under 8 ms.
Then the campaign (Fire missions 1-3 with story) builds on everything above.

## (Old) Wave 2: Magic, buildings, fog — replaced, kept for reference (spells -> wave 3, fog -> wave 4)
| Id | Task | Owner | Size |
|---|---|---|---|
| 2.G1 | Spell framework: mana, cooldown, target types (point, unit, self, area) **[H]** | gameplay | M |
| 2.G2 | Fire and Shadow spells (6) on the framework | gameplay | M |
| 2.G3 | The Shadow Wizard casts its spells by itself (simple rules) | gameplay | S |
| 2.S1 | Building placement on a grid; workers construct **[H]** | systems | L |
| 2.S2 | Fog of war (explored / visible / hidden), also on the minimap **[H]** | systems | L |
| 2.U1 | Build menu + placement ghost (green/red) | ui | M |
| 2.U2 | Spell icons, cooldowns, tooltips | ui | S |
| 2.U3 | Effects for the 6 spells | ui | M |
| 2.D1 | Mission 1 script: objectives, triggers, dialogue lines, map layout | designer | L |
| 2.D2 | Balance pass from playtest 1 + UI spec for objectives, dialogue, end screen | designer | M |

Load: gameplay 5 · systems 6 · ui 5 · designer 5.
**Playtest 2:** build a barracks, train from it, cast all 6 spells, scout through fog. Spells readable? Buildings easy to place?

## Wave 3: Mission 1 against AI (FIRST BIG DELIVERY)
| Id | Task | Owner | Size |
|---|---|---|---|
| 3.A1 | Enemy commander: gathers, builds, trains from the AI spec | ai-coder | L |
| 3.A2 | Enemy attack waves (timer + army size) | ai-coder | M |
| 3.G1 | Unit micro: retreat at low HP, focus fire | gameplay | M |
| 3.G2 | Guardian camps around the artifact | gameplay | M |
| 3.S1 | Mission framework: objectives, triggers, dialogue events **[H]** | systems | L |
| 3.S2 | Mission 1 built on the framework, from 2.D1 | systems | M |
| 3.S3 | Artifact capture gives its permanent bonus | systems | S |
| 3.U1 | Objectives panel + dialogue box | ui | M |
| 3.U2 | Victory/defeat screen with stats | ui | S |
| 3.U3 | Main menu, pause menu, settings (volume, edge-pan, key rebinding) | ui | M |
| 3.L1 | Lead: first test Windows export (templates, `*.json` filter) | lead | S |
| 3.D1 | Missions 2-3 scripts + campaign map + artifact-choice screen spec | designer | L |

Load: ai 5 · gameplay 4 · systems 6 · ui 5 · designer 3.
**Playtest 3:** play mission 1 start to finish (target 15-25 min). Too easy or too hard? Is the AI's attack fair? Rate the fun from 1 to 10.
**Gate:** if the fun is under 6/10, wave 4 becomes a fix-and-balance wave before adding content.

## Wave 4: Fire campaign loop (missions 2-3)
| Id | Task | Owner | Size |
|---|---|---|---|
| 4.S1 | Campaign progress: save between missions, artifacts carried over **[H]** | systems | L |
| 4.S2 | Mission 3 | systems | M |
| 4.G1 | Mission 2 (+ its scripted encounter) | gameplay | M |
| 4.G2 | Performance: 200 units at 60 fps (perf test) **[H]** | gameplay | M |
| 4.G3 | Balance changes from playtest 3 | gameplay | S |
| 4.U1 | Briefing screen + campaign map | ui | M |
| 4.U2 | Artifact-choice screen (equip 2 of the artifacts you own) | ui | S |
| 4.U3 | Sound hooks + music player (CC0 placeholders) | ui | M |
| 4.A1 | AI difficulty: easy / normal / hard *optional* | ai-coder | M |
| 4.D1 | Ice and Nature rosters, spells, buildings + skirmish map spec | designer | L |

**Playtest 4:** finish missions 1 to 3, quit and continue. Does the artifact from mission 1 carry into mission 2?

## Wave 5: Ice and Nature, skirmish mode
| Id | Task | Owner | Size |
|---|---|---|---|
| 5.G1 | Ice and Nature units (slow, freeze / cheap, regrowth) | gameplay | L |
| 5.G2 | Ice and Nature spells (6) | gameplay | M |
| 5.S1 | Ice and Nature buildings and tech | systems | M |
| 5.S2 | Skirmish setup: pick a kingdom, a map, and an AI opponent | systems | M |
| 5.U1 | Kingdom select screen + kingdom HUD colours | ui | M |
| 5.U2 | Effects for the 6 new spells | ui | M |
| 5.A1 | The AI can play any kingdom | ai-coder | M |
| 5.D1 | Tutorial mission + list of polish tasks | designer | M |

**Playtest 5:** one skirmish with each of the four kingdoms. Does each one feel different?

## Wave 6: Polish and ship the slice
Tutorial mission, balance, the last blockers, performance, and a Windows .exe the user can share.
After that, the Ice, Nature and Shadow campaigns repeat the waves 3-4 pattern. The designer writes their task lists on day 1 of wave 6.

## Step 9: Champions (autonomous hired heroes), started 2026-09-26 morning
Spec `docs/design/champions.md` (9.D2 done). User decisions (2026-09-26): only champions are not directly controlled
(the wizard stays WASD / click); 2 mirrored taverns at (-15,-15) / (15,15); veterancy rank 4 renamed "Paragon";
prices 200+75 / 250+100 / 300+125, pop 2, taverns open 2:00, revive for essence.
- [x] 9.L1 lead: contracts in `CLAUDE.md` (Champions bullet, Keys R / Y / F5-F7 / flag Z / Delete, owner rows).
- Phase 0-1 (in parallel, no shared files; task list = champions.md section 15): 9.D3 (ui-designer, Fable),
  9.C1 [H], 9.C2, 9.C3 [H], 9.C4, 9.C5, 9.C6, 9.C7, 9.C8, 9.V1, 9.V2, 9.V3, 9.V4, 9.V5, 9.V6.
  9.C7 / 9.C8 start from champions.md section 9 and follow `ui-champions.md` as soon as 9.D3 lands.
- Phase 2: 9.C9 (bot), 9.C10 (plug models + VFX), 9.C11 (lead integration run), then 9.D4 (balance) after the playtest.
- Playtest: 1v1 with champions, bounty flags, taverns.

### Step 9 art day (user request 2026-09-26 ~10:30: "as much art as possible", end the day at 32-37 % weekly)
**Budget rule for today:** weekly was 21 % when this was written (resets Sat 2026-09-27 ~1 AM). Target **~35 %** at the end
of the day. Measured: 15 agents ≈ +2 % weekly in the first 10 min. The lead checks `get_usage` each time an agent ends:
- weekly < 30 %: launch the next art agent from the queue as soon as a slot frees (max 20 agents at once);
- 30-32 %: no new art agents; only phase 2 (9.C9, 9.C10), fixes and integration;
- 33 %: finish integration, CI, playtest build, notes; nothing else. Hard stop at 37 %.
**Measured pace (10:35):** 20 agents at once ≈ **+16 % weekly per hour** (19 → 23 % in 15 min). So the queue is on hold
while 20 run; launch a queued art agent only if weekly <= 27 % when a slot frees, and keep ~4 % for phase 2 + integration.
Started: A2.1, A2.2, A2.3, A2.4, A2.5, A2.7. 9.D3 and 9.C6 done.
**11:05 decision:** weekly 27 % with 14 agents still running (~15 %/h) → A2.6, A2.8, A2.9, A2.10 moved to **after the weekly
reset (Sat 2026-09-27 1 AM)**. Today: finish running agents, 9.C10, 9.C11, CI, playtest build.
**12:25 update:** every step-9 agent and A2.1-A2.5, A2.7 done and committed at only 29 % weekly (the pace fell as
agents finished), so A2.6, A2.8, A2.9, A2.10 were launched after all (~0.6 % weekly per agent). Stop rule unchanged.
Art sub-elements (tech-artist, one agent each, same painted SC2/LoL style, `art-units.md` / `art-keep.md`, no time box):
| Id | Element | Folder | When |
|---|---|---|---|
| A2.1 | Nature army polish 1: Sprigling, Sapling, Bloomtender | `art/units/nature/` (those 3 scenes) | now |
| A2.2 | Nature army polish 2: Thornling, Bramblehorn, Burr Slinger | `art/units/nature/` (those 3 scenes) | now |
| A2.3 | Ember Crown centrepiece: crown pedestal + crystal nodes | `art/environment/` (those scenes) | now |
| A2.4 | Ice buildings: hall, lodge, spire, wall | `art/buildings/ice_*` (not the keep) | now |
| A2.5 | Nature keep epic pass | `art/buildings/nature_keep*` | now |
| A2.6 | Nature hall, hollow, spire | `art/buildings/nature_*` (not the keep) | queue |
| A2.7 | Neutrals: Ruin Warden, Ruin Peddler, Lost Cache | `art/units/neutral/`, `art/environment/ruin_peddler*`, `lost_cache*` | queue |
| A2.8 | Trees + rocks second pass (variety, wind, LOD) | `art/environment/tree_*`, `rock_*`, `ruin_pillar*` | queue |
| A2.9 | Champion portraits + 12 ability icons + 4 bounty icons + tavern icon (after 9.V1-9.V4) | `art/icons/champions/`, `art/icons/champion_abilities/`, `art/icons/bounties/` | after models |
| A2.10 | Main menu 3D diorama background (lead plugs it into the menu) | `art/environment/menu_diorama/` | queue |

## "Use the max" plan (user request 2026-09-26 ~11:10): spend what's left of the week before the reset
Weekly 33 % at 11:05; it resets **Sat 2026-09-27 00:59** (Quebec) and unused budget is lost, so aim for **~90-95 %
weekly by 00:59**. 5-hour windows: ~11:00-15:50, 15:50-20:50, 20:50-01:50; stay under ~90 % of each window.
Measured: ~0.6-0.7 % weekly per agent; 20 agents at once ~ +16 %/h. Order (each step ends with CI + playtest build +
OneDrive zip):
1. **Step 10** trade (~27 agents in phases 1a / 1b / 2) — now.
2. **Step 11** champion classes (~15 agents) — its non-conflicting tasks (UI spec, weapon art, icons) start as slots
   free; code tasks that touch step-10 files (champion_guild, tavern_window, champion_brain, unit.gd) after those
   step-10 agents finish.
3. If budget remains: 9.D4 + 10.D3 balance pass (games too short), mission 2 build, test_m7_u1 fix, audio polish.
**Night rule:** stop launching at the user's bedtime (PC loud) unless they say to keep going. User's bedtime tonight:
**midnight - 1 AM** -> last launches ~23:30, final save + test by ~00:30, PC quiet from ~1 AM (weekly reset 00:59).
**Fill-to-80 % plan (user 14:15): build until the weekly meter reaches ~80 %, then keep the last ~5 % (80 -> 85 %)
for "save + test all"** (full CI on a tag, bot-vs-bot matches incl. the --no-* controls, fix blockers, playtest copy,
Windows export, OneDrive zip + source zip, git bundle backup). Per 5-hour window also stop launching at ~80 % so the
running agents finish before the cap. Order of work from the 15:50 reset:
1. Designs: 12b terrain (12b.D1), 13b gunpowder / Mage Archer / Nature riders (13b.D1), 11b revision (running).
2. 12.L1 contracts, then step-12 code (12.C1 map + river nav, C2-C11 camps / points / critters / beasts, 12.A1-A3),
   remaining step-12 art (V2 ground cut, V5 river mouths, V6 scatter, V9-V12 biomes, V15-V16 critters, V21-V24
   creatures / camps, V25 VFX, V26 icons, V27-V32 epic beasts).
3. 13.L1, step-13 code + remaining art (mounts, riders, titans, Stables, Lairs, VFX, icons); 13b art.
4. 11b build (champion skill tree), 14 research, 16 rush + new units — as far as the budget goes (whatever doesn't
   fit waits for next week).
**Window plan 15:50-20:50 (lead, 14:35):**
- Wave A 15:50 (lead first: 12.L1 contracts + step12 agent rules refresh), ~20 agents: step-12 code 12.C1 [H] map + river
  nav, 12.C2 capture points, 12.C3 camps, 12.C4 [H] creatures / beasts data, 12.C10 critters, 12.C11 epic beasts,
  12.A1 creep / capture bot, 12.A3 beast brain; art 12.V2 ground cut, V5 river mouths, V6 scatter, V9 heath, V10 old
  wood, V11 glade, V12 isle ruins, V15 deer / rabbit, V16 cosmetic critters + CritterSystem, V21 Mirefang, V22
  Gloomcap, V23 Hollow Stag. **+ 13c.V1 Frost Dragon art** (user ~14:45; reads `flyer_model.gd` + the Cinder Dragon
  builder, `cinder_dragon_preview` must still pass). Hold 12.V2 / V6 until MAP.P1 is committed (same ground files).
  **Started early at ~14:58 (user "max 100 % now"):** 12.L1 done by the lead (CLAUDE.md "Map fill" bullet + owner rows,
  step12 rules refresh); agents 12.V2, V15, V21, V22, 13c.V1, specs 18.D1, 17b.D1 (+ 19.D1 running). At 15:50 launch the
  rest of Wave A (code C1-C4, C10, C11, A1, A3; art V5, V6 (after V9-V12 or with stubs), V9-V12, V16, V23).
  + 18b.D1 walls spec + **MAP.P3** (user ~15:38, one more map polish agent: the horizon — forest beyond the cliffs,
  sky / backdrop silhouettes, ruin dressing in `build_env.gd`, base surroundings; NOT ground.gdshader (12.V2) nor
  map_dressing_art.gd (12.V6)).
- Wave B ~17:00 (as slots free): 12.V24 camp sites, V25 VFX, V27-V30 epic beasts, V31 beast VFX, V32 lairs; 13.L1;
  13 art V1b seated rider, V2 Ember Boar, V3 Dusk Steed, V5 Grove Stag, V6 Roan Courser, V14 dragon VFX, V15
  Nightmare Knight, V16 + V17 Mammoth + howdah, V18 Elder Treant.
- Wave C ~18:30 (fewer agents, window near 80 %): 12.C5-C9 map-fill UI / glue, 12.A2 champion hooks, first 13 code
  tasks, 12b / 13b art if their specs are answered.
- ~20:15 (95 % of the window): save + test (tag, CI, bundle, OneDrive), playtest build if green.
**Save + test rule (user 14:30): at ~95 % of each 5-hour window, save all** (commit, git bundle in
`Documents\four-wizards-backup`, OneDrive source zip) **and test** (CI suite on a tag; playtest copy / export when
green) before the window resets.
**Testing rule (user 13:30):** don't test hard now — agents run only their own task test; no extra CI / bot-vs-bot
matrices from the lead. The big test + integration pass (CI, bot matches, balance, playtest build, OneDrive) happens
when the weekly meter reaches ~75 %.

## Step 10: Markets, trade caravans, Thieves' / Hunters' guilds (user request 2026-09-26 afternoon)
- [x] 10.L1 lead: contracts in CLAUDE.md (Trade bullet, Keys U / B-B / Z / G, owner rows); agent rules `step10-agent-rules.md`.
- Running (11:20, 20 agents): 10.D2, 10.C1, C2, C3, C4, C5, C6, C11, C12, A1, A2, V1, V2, V3, V4, V5, V6, V7, V8, V10.
- Queue: 10.C7 + 10.C8 (after 10.D2), 10.V9 Lodge, 10.V11 VFX; phase 2: 10.C9, 10.C10, 10.A3, 10.V12 icons; 10.L2 lead.
- 11:45: done 10.D2, C2, C4, C5, C6, C12, A1, A2, 11.D2; launched 10.C7, C8, V9, V11, 11.C1, C2, C3. 5-hour window at 26 %
  (~35 %/h with 19 agents): **no new launches until the running ones drain** (stop at ~75 % of the window, reset 15:50).
  Next: 11.V6, 11.V7, then phase 2 (10.C9, C10, A3, V12, 11.V1-V5, 11.A1 after 10.A3, 11.C4 after 10.C8).
AoE2-style markets + caravans that earn by distance; neutral Thieves' Guild spawning thief NPCs that raid caravans;
neutral Hunters' Guild. Spec `docs/design/market-trade.md` (10.D1, game-designer, running). **Build (~12 agents) after
the weekly reset (Sat 2026-09-27 ~1 AM)**, user agreed ("ok"); ask the user's decisions from the spec first. The PC is
loud at night: don't launch the build while the user sleeps unless they say so.

## Step 11: Champion classes (user request 2026-09-26, after step 10)
User decision: the Silkroad-style system (cap 110, skill tiers 1-8) is for a FUTURE game. In Four Wizards, **champions
choose their own class** (Spear, Sword & Shield, Two-Hand Sword, Wizard), **3 skills per class**, scaling with champion
level 1-6; the player's wizard keeps F/Q/E 1-8. Spec `docs/design/skills-rework.md` (11.D1, game-designer, running);
build after step 10, when the user says.
User answers: class drawn at L2 (archetype + bounty leans), class skills ADD (6 max), odd pairs rare. Task list =
skills-rework.md section 12. **11.L1 done (contracts in CLAUDE.md).** Scheduling vs step 10 (shared files): 11.C3 after
10.C12 (champion_guild.gd); 11.A1 after 10.A3 (champion_brain.gd); 11.C4 after 10.C8 (tavern_window.gd); 11.V1 (kit
character_model.gd) after 10.V5 / V6 / V7. Free to start now: 11.D2, 11.C1, 11.C2, 11.V6, 11.V7.

## Step 11b: Champion skill tree 1-9 (user request 2026-09-26 ~13:20)
Champions (4 classes) level to 9; at each level a skill point and a choice among 2-3 class options; every skill has
ranks 1-3 (+3 max); the champion picks by itself (personality + class). Spec `docs/design/champion-skill-tree.md`
(11b.D1 done, revising). Build after step 11 integration (shares champion.gd / champion_abilities.gd / champion_brain.gd).
**User answers (14:10):** class drawn AT HIRE (changes step 11's level-2 draw); 3 offers, takes its favourite; level 9
at 15-20 min and unique NPCs level fast early (first levels in a few minutes, rush-timing relevant).

## Step 12: Fill the map (user request 2026-09-26 ~12:00, chose ALL four packages)
1. Nature and decor (vegetation, biomes, ruins, ambient critters; cosmetic). 2. Capturable points (watchtowers,
shrines, essence wells). 3. Neutral monster camps (essence / XP / items, respawn). 4. A river with bridges and fords
(must fit the step-10 ring road). Spec `docs/design/map-fill.md` (12.D1, game-designer, running); then the user's
decisions; build after steps 10 / 11 integrate (shares skirmish.gd, env_props.gd, map art), art split per sub-element.

## Step 12b: Terrain types with kingdom pros and cons (user request 2026-09-26 ~13:40)
Terrain / ground types with effects (e.g. sand, snow, mud / swamp, deep forest, road, shallow water, ash / scorched
ground), and each of the 4 kingdoms has pros and cons on each (e.g. Ice fast on snow / slow on sand, Fire strong on ash
or sand; **user choices 13:45: Nature = riverbanks and water** (fast in fords / shallow water, heals near the river;
con: slow on snow), **Shadow stays NEUTRAL on terrain** (user 13:50: no terrain pros or cons for Shadow; its identity lives
in Souls / research instead). Ties into the step-12 biomes and
river (fords already -35 %). Spec `docs/design/terrain.md` (12b.D1, game-designer) — **launch at the 15:50 5-hour reset**;
build with / after step 12 (map_dressing, ground shader, unit speed / Stats hooks, UI tooltips, bot pathing costs).

**12b answers (14:50):** Nature river heal out of combat only; no Fire con — buff the other kingdoms (HP / bonuses) to
match Fire; scorched-ground patches appear at random (seeded, fair, warned). **13b answers:** trained by role, Mage
Archer arrives L3 with XP x2, Frostbow dropped / Rifleman takes its role, reuse existing Ice art where possible.

## Step 13c: Second titans + a neutral Frost Wyrm (user request 2026-09-26 ~14:55: "ice dragon" -> options 3 and 1)
- A **second titan per kingdom** (choice at the Lair): ICE = **Frost Dragon** (flying, freezing breath; reuse the
  Cinder Dragon's `FlyerModel` rig with new materials / horns / ice VFX), and to stay fair Fire, Shadow and Nature
  each get a second titan too. **User (15:00): one second titan is a rock-throwing GIANT (mass-trainable, no cap),
  one is a WIZARD unique NPC (one at a time, autonomous and friendly, like the Mage Archer), and the remaining one
  follows the same idea** — designer maps them onto Fire / Shadow / Nature (Ice = Frost Dragon) and asks the user.
- A **neutral epic beast "Frost Wyrm"** (5th epic beast on the map, 2 variants, mirrored lairs, big rewards; reuses
  the flyer rig) — add to map-fill.md's epic beasts.
Spec `docs/design/titans-2.md` (13c.D1 done); build after step 13. **User answers (15:20):** Ice Frost Dragon, Fire
Ember Crucible (base upgrade: a free Flame Guard every 40 s, max 6 alive), Shadow Barrow Giant (mass), Nature
Wildcaller (unique NPC); both titans of a kingdom stay trainable; Frost Wyrm over the river, first spawn 13:00.

## Step 13: Cavalry for every kingdom + hero mount system (with a dragon) (user request 2026-09-26 ~12:20)
User: "add a dragon to one side and strong cav the other" -> clarified "all can make a cav unit and heroes have a mount
system". Spec `docs/design/cavalry-mounts.md` (13.D1, game-designer, running); then the user's decisions (incl. the
dragon); build after steps 10-12 (shares unit.gd, wizard.gd, champion.gd, commander.gd, hud.gd).
**User answers (13:00):** titans as proposed (Fire Cinder Dragon, Shadow Nightmare Knight, Ice War Mammoth, Nature Elder
Treant, no cap) — "balance after the test, make it EPIC" (top art quality for the titans; tune numbers from the 13.L2 /
13.C9 runs); true flyer; mounts travel-only (Tab); Stables tier 2 + Blaze Rider moves out of the Ember Hall + line
infantry +50 % vs mounted. Spec `docs/design/cavalry-mounts.md` (13.D1 done).

## Step 17: Grand Market (items T1-T5, epic) + more expansions (user request 2026-09-26 ~14:40)
A new town building (per kingdom look) that sells items of tiers 1-5 up to epic ones (fits items.md: essence / gold
prices, recipes, stock / restock?, who can buy: wizard, champions' purses), and more expansion sites (new hall
spots elsewhere on the map, fair / mirrored, fitting the step-12 river, camps and points). Spec
`docs/design/grand-market.md` (17.D1 done). **User answers (15:30):** epics unique, 4 of 8 per match; champions buy up
to tier 4; **3 new expansion sites per side** (Glade Vein, Millrace Vein + the Ford Vein option B at (-22,-30.5)) —
designer to fold option B into the spec before the build.
**User has not playtested since the morning: next playtest build = top priority** as soon as the step-10/11 CI
finishes (fix blockers, export, OneDrive zip).

## Step 18: Building levels + staffing (user request 2026-09-26 ~15:10)
Buildings get levels (upgrade a Hall / Stables / Forge / Market... to level 2-3 for more slots, speed, better units /
items), and production needs **someone** inside: a building must be staffed (a worker or a specialist assigned to it)
to train units or craft items; more / better staff = faster or better output. Must stay readable and not slow the
game down (auto-staff option?). **User: art per level** — every building gets a distinct look at each level (level 2
/ 3 add-ons: extra floors, towers, banners, glow; same footprint), one art task per building family per kingdom. Spec `docs/design/building-levels.md` (18.D1, game-designer, with questions for the
user) — at the 15:50 reset; build after steps 12-14 (touches buildings, economy, UI, bot).

## Step 13b: Tier-3 gunpowder infantry for Fire and Ice (user request 2026-09-26 ~14:00, launch at the 15:50 reset)
A T3 unit of men with guns for 2 kingdoms (user chose Fire + Ice), clearly distinct from each other: FIRE = alchemy
musketeers (black-powder volleys, short range, big explosive damage, slow reload, smoke); ICE = frost-rune riflemen
(long range, freezing / slowing shots, slow and fragile up close). Trained at the Citadel tier (step 14) alongside the
titans; not heroes, no cap. Balance after the tests (knobs), user: "make the 2 unique from each other". Design as an
addendum to `docs/design/cavalry-mounts.md` or its own `docs/design/gunpowder.md` (game-designer), art: one agent per
unit model + musket / rifle VFX (muzzle flash, smoke, frost trail) + icons.
**Balance for the other two (user 14:05):** SHADOW = a **Mage Archer**, really strong, a UNIQUE NPC (one at a time): the
player does not control it (autonomous like a champion) but it is fully friendly / allied. NATURE = **2 units**:
horse archers (fast) and a strong slow unit, each with clear ups and downs (pros / cons). Designer defines stats,
costs, tier, counters; balance after tests.

## Step 14: Research — magic and technology (user "ok" 2026-09-26 ~12:35)
Two tracks per kingdom (Tech: crystals + gold; Magic: crystals + essence), 3 tiers, T3 unlocks the step-13 ultimate
unit; ~12 upgrades per kingdom; unique mechanics Fire Heat, Shadow Souls, Ice control, Nature growth. Spec
`docs/design/research.md` (14.D1, running). Build after steps 10-13.

## Step 15 (future): Food and supply (user request 2026-09-26 ~12:50)
A food resource (farms / fields, hunting the step-12 huntable critters, maybe caravans bringing food) and a supply
system (army supply / upkeep in food, supply buildings or lines, what happens when supply runs out). Must fit the
existing pop (houses), crystals, essence and gold without UI clutter. Design spec later (game-designer, e.g.
`docs/design/food-supply.md`) with the user's decisions first; build after steps 10-14.

## Step 16a (next plan): Score system + score screen (user request 2026-09-26 ~20:00)
A running SCORE per team (AoE-style, original): military (enemy value killed, own value lost), economy (crystals /
essence / gold gathered, trade income, workers), map control (points held over time, camps cleared, beasts slain,
expansions), tech / growth (wizard + champion levels, research, keep tier), with a total. Uses:
1. **Bot-vs-bot tests:** at the 30:00 limit (was "no winner in 1500 s") the match ends on points — the test logs the
   full score table and the leader + margin, so a stalled match still yields data on "how well each bot did"
   (a "won on score" result is logged separately from a real win; balance runs report both).
2. **Future games:** the end screen gets a score tab (per-category table + a score-over-time graph, sampled every
   30 s), for every skirmish / 2v2 / campaign mission; an optional "Time limit" skirmish setting (off / 30 / 45 min)
   ends the match on score.
**User rule (~20:05):** EVERY 1v1 skirmish shows the score screen at the end (win or lose). The match still ends
the normal way — all of the other wizard's buildings destroyed, or a concede ("gg"). Score decides the winner ONLY
when neither happened by the time limit (the 30:00 bot-vs-bot cap; the optional skirmish time limit).
Tasks (small, next window): 16a.D1 score formula (designer, docs/design/score.md; weights so military / economy /
map / tech each matter), 16a.C1 ScoreKeeper (systems: listens to existing signals — unit_died, EssenceBank /
GoldBank / Economy income, CapturePoints, CampManager, EpicBeasts, levels; group "score"), 16a.U1 score tab + graph
on the end screen (ui; the 2v2 end table of ui-2v2.md reuses it), 16a.A1 bot-vs-bot harness: 30:00 cap + score
table in the log (tests only). Build before the big balance pass of step 16.

## Step 16: Balance "good average" + a rush option for all 4 kingdoms (user request 2026-09-26 ~13:00)
Targets: each matchup 45-55 % in bot-vs-bot, median length 15-20 min; every kingdom has a viable early "zerg rush"
(cheap mass units ~2:30-3:30) with clear risk and counters; a "Rusher" bot style; full 16-pair test matrix with the
feature toggles. Spec `docs/design/rush-balance.md` (16.D1 done). Build + the big balance pass after 10-14.
**User answers (13:35):** rush units deal NORMAL damage to buildings (no "Light" rule — not the recommendation; the
Muster Bell + tower / wizard / champion defence must hold rushes instead; re-check the 15 %-games-before-8:00 cap);
Muster Bell on every keep (V): yes; bot style default Random with 25 % Rusher; keep all 10 new units.
Step 14 user answers: Forge + Sanctum, keep upgrades Stronghold / Citadel, Souls autocast rites, and Nature's strong
regen moves to ONE tier-3 unit (not army-wide) — research.md being revised.
## Step 17b (future): Civ 5-style worker improvements (user request 2026-09-26 ~15:00)
User answers: **keep gathering as it is** (trips crystal node -> keep) and ADD Civ 5-style improvements that workers
build, repair after pillage, plus an **Auto** button (the worker picks gather / repair / build itself). Only
improvement chosen for now: the **Trading Post** (the Civ 5 "Trading Post" idea, original art) — a worker builds it
on a spot along a caravan road; caravans passing it pay **more gold per trip** (stacking rule / cap TBD); enemies,
Magpies and thieves can **pillage** it (disabled, not destroyed; a worker repairs it). Must not clash with the
step-10 neutral trade posts (naming: e.g. "Roadside Post") and the step-17 Grand Market. Other improvements (mine,
farm / hunting camp for step 15, roads) stay possible later if the user asks. Spec: short addendum to
`docs/design/market-trade.md` or its own `docs/design/worker-improvements.md` (17b.D1, game-designer: cost, build
time, placement spots, gold bonus, pillage / repair, Auto logic, bot use, UI key, art task); build with or after
step 17.

**18.D1 user answers (~16:00):** auto-staff = crew slot only (recommended); specialist = Master promoted from a staff
worker (recommended); all buildings level except the Ice Wall, houses raise pop 40 -> 60 (recommended); strictness
question answered with a walls idea instead -> keep the recommended "strict + free crew" (4 starting workers) unless
the user says otherwise. Staff do not count for pop (default).

## Step 18b (next plan): City walls (user request 2026-09-26 ~15:37)
**User (~16:00):** the main city gets walls PER KEEP LEVEL; at level 3 a FREE great wall that encloses every building
near the main building (relayed to 18b.D1).
Walls for every kingdom's city: workers build wall segments (drag-to-place line, snaps to the build grid), gates
(own units pass, enemies don't; open / lock toggle), corner towers that can be upgraded, and repair. Each kingdom
gets its own look and one twist (e.g. Fire: burning palisade that hurts attackers; Ice: keeps the existing Ice Wall
and extends it; Nature: living hedge that regrows; Shadow: bone / dark-stone wall that hides units behind it) —
designer proposes, user picks. Must fit: rushes (step 16: walls not affordable before ~3:30?), pathing / navmesh
(runtime rebake cost, gates as nav links), siege (rams / titans / catapults deal bonus damage to walls), step 18
levels (wall levels: wood -> stone -> enchanted), the bot (walls its base at medium+), art per kingdom per level.
Spec `docs/design/walls.md` (18b.D1, game-designer, with questions for the user); build with / after step 18.

**17b.D1 user answers (~16:05):** 8 fixed roadside plots; Auto may spend (own bank, own roads, 100-crystal reserve);
Auto off by default + a setting; a pillaged post collapses after 3 min AND drops FREE GOLD on the map when it
collapses, so "smart" Magpies camp a pillaged post to stop its repair (attack repairing workers) and grab the gold
when it falls — needs a small spec revision of worker-improvements.md (gold amount, Magpie guard behaviour, counters).

## Step 20 (next plan): 2v2 map (user request 2026-09-26 ~16:40)
A 2v2 skirmish: the player controls ONLY their own side (one kingdom); the ally is a bot on the same team, the two
enemies are bots. Build it from what exists, "the same but 2x": a map about twice the Crown Hollow area made by
reusing its pieces (two base slots per team side by side, the river, crossings, Crown Isle in the middle, camps /
points / lairs / trade posts / taverns / guild houses / expansions doubled and re-mirrored), no new art needed
beyond dressing. Needs: team = 2 players each (TEAM A: player + ally bot; TEAM B: 2 bots), shared victory (a team
loses when both wizards / keeps are down — designer confirms the defeat rule), allied vision, ally pings / simple
ally commands (e.g. "attack here" / "help me" on the minimap), shared or separate resources (recommend separate),
the ally bot reusing the existing Commander with an "ally" layer (follow the player's attacks, defend the player's
base), per-kingdom lobby slots (menu: pick your kingdom + ally + 2 enemies, difficulty each), 4 wizards on the map
(perf with ~2x units: check the 200-unit perf budget), fog / minimap / HUD for 4 players, bots targeting the right
enemy. It also serves Story Episode 2 (the 2v1 -> 2v2 turn). Spec `docs/design/map-2v2.md` (20.D1, game-designer,
with questions for the user); build after step 12 lands (reuses its river / camps / points systems).
**Budget plan for the rest of 2026-09-26 (lead, 17:40; 5-hour 55 %, weekly 73 %; user: "use up to 85 % of the
5-hour window for the map-2 design and plan to use everything correctly"):**
1. Now -> ~85 % of this 5-hour window (resets 20:50): three design agents for the 2v2 map, split so they don't
   overlap: **20.D1** map + rules (`docs/design/map-2v2.md`), **20.D2** UI / lobby / 4-player HUD / ally pings
   (`docs/design/ui-2v2.md`), **20.D3** ally bot + 2v2 bot targeting (`docs/design/ai-2v2.md`). All reuse the
   current systems (river, camps, points, beasts, lairs, trade, champions, horizon, decor, bots). + the 3 running
   agents (12.A1, 12.C5, 12.A2) finish and get committed. No new build tasks.
2. When 12.A1 / C5 / A2 are in: big test pass (CI on a tag in the CI worktree, PC quieter), fix list in lead-status
   (test_4_s1, test_9_c5, test_9_c3, smoke defeats, perf with river + decor on the quiet PC, 12.V6 density call).
3. Stop launching at 85 % of the 5-hour window. After the 20:50 reset (weekly ~85 %): lead-only work — fixes that
   are one-liners, 12.L2 glue that is safe (CritterSystem, lairs/camp-site plug via 12.C8 later), playtest build
   exported to OneDrive + notes, final save (bundle + OneDrive zip) ~00:30, PC quiet at 1 AM.
4. Next week (after the weekly reset): 12.C6-C9 + 12.L2 integration, the 13 code, then 13b/13c/14-18b builds,
   then the 2v2 build from 20.D1-D3.

**20.D3 done (ai-2v2.md). User answers (~18:05):** ally personality = RANDOM each match; enemy bots = fair score,
no human bias, no double rush; a conceding bot's kingdom crumbles, its teammate plays on. 20.D2 done (ui-2v2.md);
its 3 questions (4 colours, ally resources, ping controls) go to the user. Team encoding (D2: per-player team values
vs D3: seat + side) is decided by 20.D1.

**User (~17:35, replaces the 17:25 note): as soon as every current art and code task is done -> run the tests, then
launch 20.D1 (the 2v2 map design) right away (same window), reusing as much of the current work as possible.**

## Step 19.0: Cinematic Toolkit — launch at the END of the current wave (user "oui, à la fin de cette wave", ~21:15)
A reusable scene system for the 3-min prologue and ALL future scenes (Episode 1, Episode 2, trailers), built first so
the prologue becomes mostly staging. Base: docs/design/cinematics.md (19.C1 player) + docs/plan/prologue-movie-plan.md
(its simplified player becomes this). Parts: (1) data timeline resource (shots, cameras, actors, gestures, VFX cues,
subtitles, music / sfx cues, timecodes, deterministic at fixed fps); (2) runtime player (shot cuts / blends,
letterbox for 21:9, subtitles, configurable skip lock (0:30 for the prologue), pause, hand-off to a mission / menu);
(3) staging kit (camera + actor markers in sets, actors walk to marks / play hooks, cast proxy for the existing spell /
titan / champion VFX); (4) preview runner (play one scene or jump to a shot, stills to docs/art/screens/); (5) record
button (Movie Maker, windowed, trailer only). ~6-8 agents; then the prologue window uses it.

## Step 19 (future): Cinematics + Story mode Episode 1 (user request 2026-09-26 ~14:50)
A **Story mode** entry in the main menu with **Episode 1** as a complete, polished chapter: build on what exists
(mission 1 `missions/mission_01.tscn`, `mission-02.md`, `campaign_state.gd`, artifacts / items carry-over) and finish
it as a 3-5 mission arc with a beginning, a twist and a boss ending. **Cinematics**: in-engine cutscenes (no video
files, 0 real lights rule kept) — a `Cinematic` player (camera rails / shots, letterbox, subtitles, skip with Esc /
Space, units scripted by the mission), an intro cinematic, one between each mission and an ending; plus in-mission
"talking head" dialogue with portraits. Original story and characters only.
**+ Video (user ~14:55):** pre-rendered **video cinematics** too. We make them ourselves: stage the shot in-engine
at max quality (extra effects, high-res models the game could not afford live), record it with Godot's **Movie
Maker** mode (`--write-movie`, fixed fps), and play it with `VideoStreamPlayer` (Ogg Theora `.ogv`) + skip. If the
Movie Maker build cannot write .ogv directly, converting needs ffmpeg — ask the user before any download.
Recommendation for 19.D1: **hybrid** — video for the big moments (Episode intro, boss reveal, ending), in-engine
for the between-mission scenes and dialogue (they can show the player's own champions / choices). Watch the size
(~10-25 MB per minute at 1080p; the export zip grows) and aspect (render 16:9, letterbox on the 21:9 ultrawide).
**Story directions (user ~15:05):** cinematics 1-2 min max each; designer picks the starring kingdom; Episode 1 =
"a war has just begun": a SURPRISE ATTACK that tries to MURDER the main wizard (an assassination attempt that
fails and starts the war), **1v1** (one kingdom vs the hero's; user correction); dark, but an OLD
FRIEND of the hero arrives and saves the day in a hopeful way (ally for Episode 2) — the old friend is an OLD WIZARD
who fights with a SWORD, very strong, lightning-based attacks. Episode 2 starts hopeful, then
the hero learns another wizard's army was destroyed (a second kingdom joined the enemy: 2v1) and must help that
wizard, who joins the hero: the 2v1 becomes a 2v2.
**Prologue cinematic (user ~19:30): a 3:00 opening scene before the campaign's first mission** — the one exception
to the 2:00 cap. Narrated "Once upon a time, a peaceful world was about to have its first world war between four
strong wizards…": ~1:00 of world building (the peaceful land, the four kingdoms Fire / Shadow / Ice / Nature, the
Master and the regalia rumour from story-episode-1.md, the calm before the storm), then a ~0:30 introduction of each
wizard (Vessa of Fire, Malrik of Shadow, Torvald of Ice, Ysolde of Nature: look, kingdom, temper, one signature
moment each). It flows straight into the first scene of the campaign (M0 "The Night of Knives" assassination
attempt). Replaces / extends the Episode intro VIDEO (2:00) of story-episode-1.md; recommend VIDEO for the world
building, in-engine allowed for the wizard intros (cinematics.md). Task 19.D2 (designer): add the shot list +
narration script to story-episode-1.md; art/video tasks: one per wizard intro + one for the world-building sequence.
**User (~19:35): don't waste work — build the prologue from footage already planned for Episode 1's videos /
in-engine scenes (reuse the staged shots, sets and wizard models; only new narration + cuts), and allow SKIP only
after the first 0:30 of the prologue video (Esc / Space show "Skip" from 0:30; before that they do nothing).**
**19.D1 done (spec + cinematics.md). User answers (~15:45):** prologue M0 + M1-M4 (5 missions); mission 2 re-skinned
vs Shadow (Torvald neutral; 19.D2 rewrites mission-02.md); hybrid with 5 videos (~105 MB); Old Vey = autonomous ally
(not controllable). Pending: ffmpeg download only if the 19.L2 Movie Maker test cannot write .ogv (ask then).
Spec `docs/design/story-episode-1.md`
(19.D1 game-designer: story outline, mission list, cinematic shot lists, dialogue, with questions for the user:
which kingdom stars, tone, length) + `docs/design/cinematics.md` (tech: cutscene system, camera, skip, save). Art:
one agent per cinematic set / new story character / boss. Build after the main steps (12-18) or earlier if the user
wants the story first.

Later backlog (user "all suggestions ok"): tutorial, music / voices / alerts, QoL (queue, patrol, formations, idle
army), 4-player FFA / 2v2 map, more maps, campaign episodes 2+ (after step 19), bot personalities, PvP, stats / replays, profile,
day-night / weather, French UI, graphics / key options, GitHub push (needs the user's sign-in once).

## Decisions waiting for the user
From the design day: population 1 / 2 / 3 (so mission 1 starts at 12 of 20), wizard death = instant loss,
Fireball button moves to the command card. Wave 1 uses these unless the user says otherwise.
**18b.D1 user answers (~16:35):** twists = base set; Stronghold gives FREE TOWERS OR WORKERS (not half a wall); Citadel = free full Great Wall; player walls from 3:30; gates = REAL DOORS (enemies can slip in while open).

**12.D2 done (ui-mapfill.md, Opus). Lead decisions:** boss bar stays on screen top-centre (reused later by titans / story bosses); end-screen map-fill stats split into two lines (skirmish.gd, 12.C1/L2); 12.C7 file list extended with command_card.gd, settings_panel.gd and new scripts/vfx/mapfill_popups.gd; 12.C6 owns camp last-seen state + floating respawn timers in scripts/vfx/capture_rings.gd.

**20.D1 done (map-2v2.md, 'Fourfold Hollow'). User answers (~18:15):** layout Fourfold Hollow (4 corners, allies on one bank); if your kingdom falls while the ally stands you spectate and still share the win; armies = 1v1 pop caps with the perf gate and auto -15 %; no gifts in v1.

**20.D2 user answers (~18:20):** colours = TEAM / KINGDOM colours (option C: each player in their kingdom's colour, friend / foe shown by the ground rings and UI frames — 20.U2 must adapt ui-2v2.md section 1 to this, not the green/blue/red/rose scheme); ally resources hidden; pings = Alt+click + Alt+drag / the ² wheel + card buttons + F4 (add these keys to CLAUDE.md at 20.L1).

**User (~18:50): the Frost Wyrm stays a WINGLESS serpent** (ice fins instead of the spec's wings; titans-2.md 7.1 / sec 11 to be read that way).

**Art Lab (user ~21:30):** tools/art_lab/ — standard shots + automatic quality checks (budgets, 40 m readability, silhouette vs references, contrast vs ground, glow points, team colour, frame cost) -> scorecard with fix hints. Every art agent runs it at the end, fixes FAILs / WARNs, attaches the scorecard and ends with 'Art Lab notes'. The lead collects the notes for 1 day (until 2026-09-27 evening) and then has the lab improved from them.

**Audio Lab (user ~21:45, future update):** tools/audio_lab/ — the Art Lab idea for sound. One command per sound set / unit / scene: renders a listening sheet (plays each cue in context: a staged fight, a UI flow, a map ambience loop) and runs checks -> scorecard with fix hints and an 'Improve next' list + a quality score: loudness (LUFS / peak, no clipping, per-category targets: UI, units, spells, ambience, music), bus routing (SFX / Music / UI buses so the volume sliders work), variation (enough takes per frequent cue, no machine-gun repeats, pitch / volume randomisation), duration and tails, frequency masking of key cues (alerts must cut through a battle mix), 3D attenuation / max-distance sanity, voice limits (max simultaneous instances per cue), memory / disk budget, missing cues (every gameplay event that should have a sound). Audio agents run it at the end, fix FAILs, apply the top improvement and report before/after; notes loop like the Art Lab. Build before step 20 'Sound, music, polish' (original / CC0 audio only).

## Labs program (user ~21:55: ALL of these, next week)
Built tonight / running: Bot Lab, Art Lab, Audio Lab, Perf Lab. Next (one agent each, same scorecard style: PASS/WARN/FAIL + score 0-100 + 'Improve next' + history log; every relevant agent runs the lab at the end of its task):
1. **Balance Lab** (on the Bot Lab): automatic stat variants (cost / HP / damage / timings), win-rate matrix per variant, suggests the knob changes that bring each pair toward 45-55 %.
2. **UI Lab**: screenshots of every screen / menu at 1600x900, 1920x1080 (laptop) and 3440x1440; text overflow, overlaps, min font size, contrast, duplicate hotkeys, missing tooltips.
3. **Replay Lab**: record commands + seed, deterministic replay; bug repro bundles (also from the laptop), watch bot games.
4. **Visual Diff Lab**: golden screenshots per scene, pixel diff on each commit to catch accidental visual changes.
5. **Data Lab**: validate all .tres / data (costs, unique hotkeys, icons / models present, text fits, French-UI readiness).
6. **Map Lab**: path fairness, mirror / symmetry, distances, combat heat maps and chokepoints (2v2 'Fourfold Hollow' + future maps).
7. **Build Lab**: one-click export of the .exe, smoke test of the exported build, size report, OneDrive playtest copy (the copy still asks the user first).
8. **Error Lab**: collects every SCRIPT ERROR from all test logs, dedupes, maps to the owning file and triggers the auto-fix agent (user rule: any failure -> fix agent).

**Faster testing (user ~22:10):** (1) parallel CI runner (lead, tonight); next: (2) test tiers — fast suite per commit, long suite nightly / Bot Lab; (3) affected-tests-only via a test->files map; (4) Bot Lab sim mode for logic-only tests; (5) cached baked navmesh per map version; (6) a machine-wide Godot limit (max 4 concurrent Godot processes for all agents, a lock script everyone uses); (7) skip --import when no asset changed; (8) every test quits as soon as it has its result; (9) later: split the suite across the laptop (16 threads); (10) Error Lab feeding the auto-fix agent.

**2v2 map art style (user ~23:40): GOLDEN AUTUMN** for Fourfold Hollow — russet / golden forests, ochre grass, ground mist, lanterns; reuse Crown Hollow models with autumn palettes; units must stay readable (Art Lab contrast on the autumn ground). Art starts with 20.V0 (style bible + autumn palette resources), then 20.V1-V6 of map-2v2.md once the map scene exists.
