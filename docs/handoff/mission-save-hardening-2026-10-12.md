# Mission save / load hardening (2026-10-12)

Source: adversarial verify of code-review C1-C4 (`code-review-2026-10-12.md`). C5 / C6 verified later, same rules.

## How a mission save works today
- `MissionBase.save_state` (mission_base.gd:1753) saves the mission's own plain vars, units and buildings (by save id).
  Flags come back; their side effects (signals, props, types, metas) do not.
- SaveWorld restores only units and buildings (save_world.gd:13-62). StaticBody3D / Node3D props (MissionBrazier,
  RootHeart, Heartfrost, WardenGate, thorns, MissionZone, GlasswaterLake, M04Keystone) are rebuilt fresh from the start.
- Matching is by type id + team (buildings within 2 m, save_world.gd:248-358). An unmatched code-made unit type respawns
  as a typeless Unit (361-382); an unmatched code-made building type is dropped (:272); unmatched rebuilt nodes are freed.
- Start-time signal hookups come back; mid-mission ones are lost (no e1-e4 mission overrides load_state).
- `decode_metas` (save_codec.gd:116) only ADDS metas; death_guard untouched; only `mission:` / `save:` modifiers saved.
- Pending `after()` timers block saving unless standard Callables or start/intro-tagged; `.bind()` blocks.
- No Ep1-4 mission overrides `save_block_reason`.

## Verdicts (C1-C4)
All CONFIRMED except C1-7 PLAUSIBLE (hold attacking is documented intent; end timer freeze only if a later timer
releases the hold). C1-6 is more than latent: e7m4 saves open from phase 4 with the seat switched. C4-2 detail:
villagers come back typeless (not dropped), groups / metas survive, `_on_folk_died` lost.
Extra: Building `max_hp` overrides (e2_05:1167 door, e2m3 tollgate TOLLGATE_HP) are not saved.
Ep1 adds (C2): 1 M04Keystone pylons / Colossus typeless, never winnable -> block; 2 thorns back after E10; 3 WardenGate
rows not called by mission_03; 4 crown seal not saved; 5 mission_04:870 freed elem into typed Unit var (runtime error,
not save); 6 mission_03:1067 freed stake into typed Building param (not save); 7 riders unlock not re-applied;
8 braziers cold next to lit_count 3, re-light re-runs; 9 M00Cast.hush not re-bound; 10 thaw blocks re-thaw (+3 veterans
each), Heartfrost HP lost; 11 `signet_carry` modifier not prefixed, RootHeart HP, ember_stake type.

## Design
Load order after the change: SaveWorld phase 1 rebuilds nodes -> phase 2 `MissionBase.load_state` restores base state,
reconciles metas / hero / seats / actors, then calls the mission's `_after_load(nodes)`, all while `save_restoring` is
still true (say() silent).

**A. lead, scripts/core**
1. save_world.gd `_apply_buildings`: when `BuildingType.find` fails, ask the level `save_building_type(id)`.
2. save_world.gd: pass saved meta keys per save id to the level (`ctx["saved_metas"]`); `decode_metas` stays add-only.
3. save_world.gd: after `_apply_units`, call `level.save_units_placed(nodes)` if present (re-point hero early).
4. save_restorer.gd: stop clearing `show_briefing`; the base skips only the briefing while `save_restoring`.
5. save_codec.gd: helper to encode / decode `[method, bound_args]` timers.

**B. systems-coder, mission_base.gd (after A's API)**
1. Meta reconcile per rebuilt node: META_DORMANT, META_LOCKED, TRUCE_META, META_TRUCE_PREV. Absent in save -> `_wake`,
   unlock, `set_truce_id(&"")`; present but awake -> real `_sleep`; recount truces through `_set_truce_id`.
2. Save hero save id, `resources_hidden`, `_seats` / `_tagged_seats` / Commander enabled-team-profile, activated seats.
   Load: `set_player_hero`, `set_resources_hidden`, `_restore_seat(seat, kingdom)` (Economy + Commander only), seat_keeps.
3. HUD: attach MissionHud without briefing while `save_restoring` (ui-coder adds a mode to mission_hud.gd if needed).
4. Local types: `register_local_unit_type` / `register_local_building_type` + base `save_spawn_unit` /
   `save_building_type` (lift MissionE5Base's version).
5. Timers: `_save_timer_ok` accepts Callables on self whose bound args encode; saved as `[due, method, args]`
   (check `get_method()` / `get_bound_arguments()` on Godot 4.7).
6. Actor registry: `register_actor(key, node)` with `save_row() -> Array` / `load_row(Array)`, rows in `save_state.actors`.
7. Virtual `_after_load(nodes)` last in load_state; spotlight guard (C1-8); max_hp override row for scripted buildings.
8. Also C1-7, C1-9 (ember_crown.gd; crown saves its seal for C2-4).

**C. systems-coder, actor rows (needs B6)**: mission_brazier (lit, quiet), root_heart (hp, dead -> quiet removal),
heartfrost (hp, melted), mission_heartwood (kindled -> quiet kindle), mission_zone (owner, progress), glasswater_lake
(floes). WardenGate already has them.

**D. per-mission batches (after B + C)**
- Ep1: m00 re-bind Hush; m01 hall unlocks, crown seal, re-add `spotlight_tower`; m02 blocks / Heartfrost actors;
  m03 thorns if E10, gates / hearts actors, `mission:signet_carry`, stake type, C2-6; m04 `save_block_reason` while
  `phase >= 1`, C2-5.
- Ep2: e2m1 heartwood actor, local types, kindle; e2m2 E14 hookups via B2 seat restore, grove types, W6 / VH bound
  timers (B5); e2m3 tollgate hookup + max_hp; e2m4 research_completed + E10 + Ashby type; e2m5 block while boss_phase
  1-3, C3-7.
- Ep3/4: e3m2 bank trickle + roster hook; e3m3 Sexton + Warden hooks; e3m1 / e4m1 zone actors; e4m1 folk hooks, C4-7;
  e4m2 C4-8; e4m3 grove hearts + frost_late; e4m4 treant type.
- Ep5/6 (C5): e6 save_spawn_unit calls arm_enemy; e5m4 lift yard truce; e5m2 keep _drilled; e6m3 lost gardens quiet;
  e6m4 keep _push + Torvald respawn; non-save C5 items.
- Non-save any time: C1-5 story_films.gd.
- Tests: tests/test_save_load_missions.gd un-skips `mission_e4_*` and adds late-step saves (force events via
  mission_harness).

**Block or restore**: block only short live machines of code-built units with many hookups (m04 after the Rise, e2m5
boss phases 1-3, e7m4's turn already). Restore everything else (e3m2 dawn, e2m2 E14, e4m1 bells cover most of their
missions).
