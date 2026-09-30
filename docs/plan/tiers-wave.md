# Tiers wave: T2 and T3 playable for all 4 wizards (2026-09-27 evening, laptop)

JS (after the playtest): "don't ask, make sure once you're done T2 and T3 are playable for all 4 wizards".
All open design questions take the doc's RECOMMENDED answer (level-boons.md, t3-helpers.md, episode3-4-opening.md,
new-maps.md). STR/INT ability timing stays 20 s / 60 s (constants). Goal = in a skirmish, each kingdom can reach
T2 and T3, train its T2 / T3 units, research "+" upgrades, and call its T3 helper; bots do it too.

## Shared contracts (frozen here; owner in brackets)
- **TierSystem** [tier agent, `scripts/buildings/tier_system.gd`]: `TierSystem.tier_of(team) -> int` (1-3),
  signal `tier_changed(team, tier)` (on the Events-free node in group `"tier_systems"`), keep upgrade
  T1 -> T2 "Stronghold" -> T3 "Citadel" (costs / times in `docs/design/tiers.md`, written by the tier agent first).
- **`UnitType.requires_tier: int = 1`** and **`BuildingType.requires_tier: int = 1`** [tier agent adds the fields in
  the FIRST 15 minutes and writes "fields added" to `docs/handoff/tiers-wave.md`]. Training / build checks refuse
  with "Requires Stronghold" / "Requires Citadel". Everyone else only sets the values in their .tres files.
- **"+" upgrades** [tier agent]: `UnitUpgrades` research at the unit's training building, available at T2, one per
  T1 / T2 unit: `<unit>+` = stat modifiers (`add_modifier(&"plus", {...})`) + `set_plus(true)` visual hook if the model
  has it (art adds a detail later). Data table in `data/upgrades/plus.tres` or a const table.
- **T3 helpers + T3 units** [T3 agent]: per `docs/design/t3-helpers.md` (recommended set: Fire Ashveil Saboteur,
  Shadow Nightblood Reaver, Ice Shardguard, Nature Briar Roc, neutral Stormbottle Genie; helpers Old Vey, Mother Hush,
  Aldra Stillwater, Maelis), `requires_tier = 3`, helpers called at the Citadel keep, autonomous with 3 stances.
- **12 new units** [new-units agent, already running]: `docs/design/new-units-12.md`; T2 ones use `requires_tier = 2`.
- **Casters** [caster agent, step 21]: `docs/design/caster-units.md`, `requires_tier = 2`, keep slot B (Set Rally r3c1).
- Models: gameplay uses `model_scene`; if the art isn't ready, a placeholder wrapper (existing kingdom unit, recoloured /
  scaled) in `art/units/<kingdom>/<id>/placeholder.tscn`; art agents replace `model_scene` targets with the real scene
  path written in `docs/handoff/tiers-wave.md`.

## Rules
Project `C:\Users\elzzo\Documents\four-wizards-rts` (never the -play copy). CLAUDE.md ownership + code style.
Godot only via `tools\godot_run.ps1` (quote `'--'`), at most 2 runs at once per agent. Never run git, no downloads,
don't call mcp__hearthbot__ tools. Every new system behind a switch constant. Tests `tests/test_<id>.gd` print PASS.
Before finishing: import, your test, smoke (victory=true), and any older test your change touches. Art at MEDIUM effort
(JS's effort-trial pick), Art Lab loop, 0 lights. Report <= 200 words: what works, files, tests, what's left.
