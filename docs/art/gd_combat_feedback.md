# G-D combat feedback (2026-10-15)

JS: "make the graphics as beautiful as possible". Wave G-D, piece "combat feedback": hits, deaths, building damage and
collapse, rubble. Owner: tech-artist. Code: `art/vfx/combat_vfx.gd` (hub, hooks) + `art/vfx/combat_g/` (the G layer).

## What changed

`CombatVfx` creates one child `CombatFxG` (`art/vfx/combat_g/combat_fx_g.gd`). At **Low** (every headless / `-s` run)
it builds nothing and CombatVfx keeps its old look exactly. At **Medium / High / Ultra** CombatVfx calls it from its own
existing hooks (no new gameplay hook, nothing in `scripts/` or `data/` changed):

| Event | Medium+ look |
|---|---|
| Melee hit (`Unit.attack_landed`) | The attacker-coloured flash stays. The GPU spark burst is replaced by a response per **target material**: steel = hot white-gold sparks, flesh / hide = a beige dust puff + flecks (no blood), bone = ivory chips + pale dust, wood = splinters + sawdust, ice = cyan shards + glints + frost steam, stone = chips + grey dust + dull sparks; plus 2 streaks in the attacker's kingdom colour. Pieces fly up and sideways, out of the bodies, toward the RTS camera. |
| Projectile end (non-splash) | Same material response at 70 % on what it hit (`Projectile.hit_unit`); arrows / bolts / stones (shooter id has bow, archer, slinger, darter, arbalest, hurler, tower, tracker) add two broken-shaft splinters, magic bolts 3 kingdom streaks; a miss raises ground dust + pebbles. |
| Unit death (`Events.unit_died`) | The old kingdom bursts stay; on top, over the kit's 1 s sink: Fire embers lifting off the body + heat smoke + scorch with cooling embers; Shadow violet wisps dissolving top-down + ink stain; Ice shards that land, lie and melt + frost star; Nature leaves that settle + spores + leaf litter; neutral dust + clods. The ground mark fades after ~7 s (heroes x1.7, bigger). |
| Building hit (`Building.damaged`) | Material chips (stone; Nature = wood; an Ice wall = ice) instead of the GPU debris burst. |
| Building HP 66 % / 33 % | A crack: debris falls off the top, dust, sparks. Below 66 % smoke, below 33 % fire glow + embers for buildings whose model has no damage stages of its own; models with `set_health_ratio` (they already smoke / burn) only get rising embers below 33 % at High+. Healing back drops the stage. |
| Building destroyed (`Building.destroyed`, not a cancelled site) | Dust ring rolling out of the base, dust column, 40-50 debris pieces falling off the walls (glowing on Fire), embers, a rubble pile + rubble stain (Fire: + scorch) that stay ~30 s then sink / fade; warm light flash at High+. The model's own collapse plays on top. Off-screen (but fog-visible): no dust / debris burst, the rubble pile + stain are still laid so panning back shows the ruin. |

Corpses: the CharacterModel kit (frozen) already sinks every body into the ground in 1 s and frees it; the G layer adds
the per-kingdom dissolve over that second, so nothing pops. Rubble pieces shrink and sink in their last 20 %.

## How it stays cheap

- **No node per event.** Six MultiMeshes, one draw call each: sparks (`cg_spark`, additive ribbons), mixed puffs and
  glowing puffs (`cg_puff_mix` / `cg_puff_add` + `cg_puff.gdshaderinc`), chips and rubble (`cg_chunk`, lit, tumbling,
  ground rest), ground marks (`cg_mark`, procedural, lit). Ring buffers (2048 / 1024 / 512 / 1024 / 512 / 192).
- An effect writes its instances **once**; the shaders fly them from one `now` uniform (drag-damped ballistic flight,
  ground clamp, fade), so live pieces cost no per-frame CPU. A MultiMesh draws nothing once all its pieces ended.
- Caps: hit events per frame 14 / 22 / 30 (Medium / High / Ultra), 420 instances per frame, 10 full deaths per frame
  (more = mark only), 24 burning buildings ticked at 4 Hz, chips skipped beyond 55 m (sparks / puffs stay), pieces
  grow up to x1.6 when zoomed out, off-screen hits / collapses skipped (CombatVfx frustum test).
- Piece counts x0.6 / x1.0 / x1.35 by tier. No new GPUParticles3D, no new pass, no new light (one existing pooled
  light used on collapse at High+).
- Fog (VfxFog): every spawn is gated with its source team; ground marks (long-lived, transparent) re-check at 5 Hz and
  hide while the fog covers them; rubble chips are opaque (under the fog overlay). The MultiMesh nodes sit at the first
  effect's spot (always a point the player sees), not at the map origin.
- Shader lint: no tier uniforms, no derivatives.

## Measures (RTX 3070 Laptop, 1600x900 window, other agents running)

200-unit clash (`gd_combat_shots.tscn -- --clash`, 100 v 100 of the four kingdoms, zoom 35, 6 deaths / s, vsync off):

| Tier | Before (G layer off) avg / 1 % low | After avg / 1 % low |
|---|---|---|
| High | 104.7 / 39.3 fps | 117.2 / 42.5 fps |
| Ultra | 105.3 / 38.5 fps | 122.6 / 43.7 fps |

After is faster: the melee / impact / building GPU emitter bursts it replaces cost more than the MultiMeshes.
~1100-1200 hit events drawn per 7 s, ~300-440 skipped by the per-frame cap.

Tests (headless): `test_gd_combat` PASS (new), `test_shader_lint`, smoke (`victory=true`), perf_test `PERF OK`
(norm 5.64 vs limit 6.72), `test_ws_perf`, `test_fog_leak` (`++ --gfx=ultra`), `test_projectile_fog`,
`test_ice_vfx_read`, `test_gb_vfx`, `test_13b_v6` / `v7` / `v9` PASS.

## Shots

`docs/art/lab/gd_combat/` (`.gdignore`): `after/sheet.jpg` (contact sheet, rows top to bottom: hits zoom 10 steel /
flesh / bone / wood / ice / stone, the same at zoom 30, arrows zoom 10, deaths zoom 10 fire / shadow / ice / nature /
neutral, the same at zoom 30, buildings zoom 30 then 14: fire barracks / shadow tower / nature barracks / ice tower, each
60 % crack, 30 % burning, collapse +0.4 / +1.6 / +4 s, rubble +12 s), `after/key_death_ice_z10.png`,
`after/key_collapse_z30.png`, `clash_ultra_after.jpg`. For git: `after/sheet.jpg` + the 2 key PNGs + `clash_ultra_after.jpg`;
`before/`, the strips and the json stay local.

Re-shoot: `tools\godot_run.ps1 --path . res://art/vfx/combat_g/gd_combat_shots.tscn --fixed-fps 60 --quit-after 40000 '--' --gfx=high --shots after`
(`--off` = before, `--only hits|arrows|deaths|buildings`).

## Tuning knobs

`CombatFxG`: `MAT_KEYS` (unit id -> material), `PHYSICAL_KEYS`, `EVENTS_PER_FRAME`, `CHIP_SCALE`, `INSTANCES_PER_FRAME`,
`STAGE_1` / `STAGE_2`, `MARK_LIFE`, `RUBBLE_LIFE`, the palette constants. `CombatFxG.test_tier` / `force_off` for tests and shots.

## Follow-ups

- Materials (review 2026-10-15): beasts / camp creatures (tusker, direwolf, grizzlemaw, scarback, bristleback, mirefang, rocs, hollow_stag...) are FLESH (hide) before the armor fallback; BONE = the Shadow undead only (hollow_oathsworn, not hollow_stag); Ice shardguard = ICE; `MAGIC_KEYS` (magebow) never gets broken-shaft splinters. A new unit of an unusual material: add its id keyword to `MAT_KEYS` (default: armor >= 15 = steel, else flesh).
- Rubble stains on slopes can clip a little (flat quad, 6 cm lift).
