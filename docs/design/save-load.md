# Mid-match save / load

Queued in `docs/ideas/restart_2026-10-03.md` (approved by JS). Skirmish (every map), campaign missions on MissionBase,
Wave Strike and the mission 1 test map (`scenes/main.tscn`).

## Player view
- Pause menu: **Save** and **Load** open a slot list: 3 slots + the quicksave, each with its title (map / mission),
  match time and date. Save asks nothing (overwrites); Load starts the saved match at once.
- Keys: **F12** = quicksave, **Ctrl+F12** = quickload (F5 / F6 / F7 = champions, F8 = bug report, F9 = restart,
  F10 = surrender, F11 = fog, F4 = reserved for the helper centre key in Ep2 specs; all physical keycodes).
- A refused save says why (HUD message): during a film, a world hold, after the match ended, before the match started,
  while a mission's scripted step is pending (a timer the mission set with a lambda), or in a mission marked
  "save not supported".

## Files
`user://saves/<slot>.save` (`slot_1`, `slot_2`, `slot_3`, `quick`): `FileAccess.store_var` of
`{magic "FWSAVE", version, meta {title, mode, time, date}, level {...}, world {...}}` (binary Variant, no objects).
A file whose `version` differs from `SaveGame.VERSION` is refused ("This save is from another version of the game"),
never half-loaded. Bump VERSION whenever the shape below changes.

## How a load works
The level is rebuilt from scratch through the normal start path (MenuFlow: same scene / map / layout / kingdoms /
difficulty / mission difficulty / trade / time limit), with briefing, films and dialogue off. Once its match clock runs,
a `SaveRestorer` child applies the world in two phases (frame 0: teams, buildings, units; frame +2, after the
node_added flushes of upgrades / wares / Forge: HP, mana, saved modifiers, orders, mission state, camera). Start units
and buildings of the fresh level are matched (type + team, nearest) and reused, extras are freed quietly, missing ones
are created. References between saved things (attack targets, builders' sites, mission variables) use save ids.

## Saved
- Level: scene / script, map id, layout path, kingdoms, bot difficulty, mission difficulty, trade, time limit, Wave
  Strike kingdoms + personality.
- Clock: Skirmish match time, wizard deaths, respawn timers, end-screen stats; MissionBase held time.
- Teams: crystals + gathered total (Economy), essence (EssenceBank), gold + wares (GoldBank), tiers (keep tier and a
  running upgrade with its time left / price), Forge line levels, unit "+" upgrades (done + in progress).
- Buildings: type, team, position, rotation, HP, construction progress, training queue (units, Forge research stubs)
  with slot-1 progress, rally point / node, mission lock.
- Units: type, team, position, HP, veterancy level + XP, caster mana, metas and groups (mission tags), persistent
  modifiers (`mission:*`, `ws_*`; level / veterancy / item / Forge / upgrade / ware / path modifiers are re-derived),
  order (idle, move, attack, attack-move, hold, gather node, build site) and its home spot.
- Wizards: level, XP, spell points, spell ranks, mana, STR / INT path, inventory (6 slots with counts) and artifacts,
  alive / dead (dead = the respawn timer runs on).
- Champions: `Champion.get_save_state()` (type, variant, level, XP, class, purse, items, leans) + position, through
  `ChampionGuild.add_companion`.
- Crystal nodes (crystals left), the Ember Crown (on its pedestal, worn by a wizard, or on the ground), fog of war
  (explored cells, both sides).
- Missions: `MissionBase.save_state()` / `load_state()`: objectives (state + text), fired events, mission flags and
  track counters, intro done + intro time, keep-seen, held time, guards / wave units, bases locked by `lock_base`, and
  the mission script's own variables (plain values; units / buildings by save id; other nodes keep the rebuilt
  level's value). Timers: `after()` tags the ones set while the mission starts or by `_intro()`; the rebuilt mission
  sets those again (intro ones moved to the saved intro time) and the load keeps the ones not yet due. A timer set
  mid-mission is saved when it calls a named method; a pending mid-mission lambda blocks the save until it fires
  ("a scripted event is in progress"). Events (`add_event`) come back from the rebuilt start, `_fired` from the save.
  While a save is put back the mission's timers / events / dialogue wait (`save_restoring`). A mission overrides the
  hooks (call `super`) when that is not enough, or sets `save_supported = false`.
  `tests/test_save_load_missions.gd` (slow list) plays every campaign mission, saves and rebuilds it.
- Wave Strike: director clock / horn index, banks (coffer level, totals), rosters (cards, ranks, tier, upgrade, locked
  pop), per-team stats, wizard respawn timers; lane units are respawned on their lane (`spawn_lane_unit`).

## Not saved (limits)
In-flight projectiles, spell / ability VFX, timed statuses (chill, frozen, rooted...), shields, damage over time,
auras (they come back from their carriers), spell / item cooldowns, cinematics (no save during a film), bot memory
(Commanders re-plan from the world they find), champion brains' current intent, map-fill services' timers (camps,
beasts, capture points, trade network routes, caravans' routes, Magpies, trackers: rebuilt fresh, their units matched
when they exist), dialogue history, the replay recording (a loaded match records a new replay). Story missions whose
script needs more than the default hook refuse to save until they override it.
