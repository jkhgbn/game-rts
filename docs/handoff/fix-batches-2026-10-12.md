# Code review fix batches (2026-10-12)

Findings: `code-review-2026-10-12.md` (ids R / W / V / U / C, verify verdicts at the end of that file).
Mission save design: `mission-save-hardening-2026-10-12.md`. Fix every CONFIRMED and PLAUSIBLE id in your batch unless
noted; skip REFUTED ones. Batches are file-disjoint: never edit a file listed under another running batch. If a fix needs a
file outside your batch, write the request in `docs/handoff/for-<owner>.md` and go on.

## Shared APIs agreed for this pass (lead)
- **Generic saved state** (new, F1 builds it in save_world.gd): any node in group `&"saved_state"` with
  `save_key() -> String` (unique per match, e.g. `"helper_roster:1"`), `save_state() -> Dictionary` (plain values; units /
  buildings by `SaveCodec` save id) and `load_state(d: Dictionary, nodes: Dictionary) -> void` (`nodes` = save id -> node)
  is saved and restored by SaveWorld. The row stores the script path; when no node has that key after the rebuild,
  SaveWorld calls the script's `static func create_for_save(level: Node, key: String) -> Node` if it has one, then
  `load_state`. `load_state` runs after units and buildings are placed.
- **Unit.set_down(pos: Vector3)** (gameplay-coder): put a unit at a point on the navmesh, quietly, keeping its orders.
- **Unit.add_modifier(source_id, stats, heal_gain := true)** (gameplay-coder): `false` = a max_hp gain does not heal.
- **Champion.restore_fallen()** (gameplay-coder): put a champion in the fallen state quietly (no `died`, no
  `Events.unit_died`); SaveWorld calls it when present.
- **Unit drop-target**: `Unit.drop_target_if(target)` (gameplay-coder) clears `attack_target` only when it is `target`,
  keeps the order.
- **Match clock**: gameplay timers that must pause and follow Blitz use the level's `match_time()` (Skirmish, saved) when
  the level has it, else fall back to their current clock (Unit Lab, Wave Strike).
- **MissionHud.attach(level, mission_node, hud, show_briefing := true)**: F1 may add this parameter to
  `scripts/ui/mission/mission_hud.gd` (only that change); F4 does not touch that file.
- **MenuFlow.set_loaded_match(props: Dictionary)** (F4, ui): remembers a loaded save's match props (kingdoms, map, pace,
  seats...) so the F9 restart hook re-applies them instead of the menu settings; F1's `SaveGame.launch` calls it when present.
- Plain-named metas that are runtime markers or absolute times get a `_` prefix (`tests/test_save_metas.gd`).

## Wave 1 (parallel)
| Batch | Agent | Files | Ids |
|---|---|---|---|
| F1 save framework | general (lead-directed, cross-owner) | `scripts/core/save_*.gd`, `scripts/audio/game_audio.gd`, `scripts/campaign/mission_base.gd`, `mission_e5_base.gd`, `ember_crown.gd`, `mission_hud.gd` (attach param only) | hardening A1-A5, B1-B8 (C1-1..4, C1-6..9), generic saved_state, R5-2a/b, R5-3, R5-8, R5-9 + W1-3 (core side), R4-5, W2-6 (core side), V1-1 (refuse load while a film plays), RC `mission_held`, `mission_truce_hook`, `game_audio`, `game_audio_crit` |
| F2 gameplay | gameplay-coder | `scripts/units/`, `scripts/spells/` | R1-1 (Unit side), R1-2, R1-4..R1-8, R2-1..R2-7, R2-c, R2-2 (HelperRoster via saved_state), R3-2..R3-13, R3-3 (Stables16 / BowmanUpgrades via saved_state), R4-3 stub factories (public), R5-1 renames, W2-6 `restore_fallen`, `set_down`, `drop_target_if`, `add_modifier` heal flag. R1-3 kept as is (design). |
| F3a world save | systems-coder | `scripts/world/` (skirmish, score_keeper, lost_cache, champion_guild, bounty_board, epic_beasts, neutral_camp, camp_manager, capture_points, wave_strike/, thieves / hunters / trade network, tavern, trade_post, env_props), `scripts/economy/caravan.gd` | W1-1, W1-2, W1-4, W1-6 (+ handoff to tech-artist for the shader array), W2-1..W2-8, W3-1..W3-7, R4-4, U3-4 (`kind_for`), RC `neutral_camp`, `tracker_contract` |
| F3b buildings | systems-coder | `scripts/buildings/`, `scripts/economy/` except caravan.gd, `scripts/campaign/story_films.gd` | R4-1 (+ `forge_sig` / `forge_range` renames), R4-3 (training_building, uses F2's stub factories via has_method, else refund), R4-6, R4-7, U2-7 (keep.gd stub text), Building saves a `max_hp` override (for scripted buildings), C1-5 |
| F4 UI | ui-coder | `scripts/ui/` except `mission_hud.gd`, `scripts/vfx/`, `scenes/ui/` | U1-1..U1-7, U2-1..U2-7 (U2-5 UI side), U3-1..U3-9, U4-1..U4-8, U5-1..U5-9, V1-5, V1-6, W1-3 (`set_loaded_match`), U5-6 |

## Wave 2 (after the files above are free)
| Batch | Agent | Ids |
|---|---|---|
| F5 cinematics | systems-coder-high (medium) | V1-1 (stop the film on context exit), V1-2, V1-3, V1-4 |
| F6 items | items-coder | R1-1 (inventory uses `heal_gain`), R5-4, R5-5 (ItemPickup via saved_state), R5-6, R5-7, U2-5 (no drop of `campaign_only`) |
| F7 bots | ai-coder | RC `ai_casters_hits`, `contract`; bot-review follow-ups: hunters contract and `attacks_launched` saved (saved_state) |
| M1-M5 missions | systems-coder | hardening D per episode (Ep1, Ep2, Ep3/4, Ep5/6 = C5, Ep7/8 = C6) on F1's framework |

Then: commit `tests/test_save_metas.gd` (core CI list), un-skip `mission_e4_*` in `tests/test_save_load_missions.gd`, balance
confirmation run, playtest build.
