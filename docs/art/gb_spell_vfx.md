# G-B spell VFX pass (graphics week, wave G-B)

JS: "make the graphics as beautiful as possible". Scope: the 4 wizards' F / Q / E spells and the 4 kingdoms' caster
spells. Owner: tech-artist. Date: 2026-10-15.

## What changed

One new layer, `SpellFxG` (`art/vfx/spells_g/spell_fx_g.gd`), built only at **Medium / High / Ultra**. At **Low**
(and in every headless or `-s` run) it never exists, so Low keeps the exact look, node count and cost of before G-B
(test_gb_vfx checks it).

The existing hubs keep drawing everything they drew before, at every tier, with the same entry points, timing and
lifetimes. At their existing timing hooks they now also call the layer (one line each, null at Low):

| Hub | Hook points that call SpellFxG |
|---|---|
| `spell_vfx.gd` (Vessa, Malrik) | cast wind-up (Fireball, Shadow Lance), projectile tracked (fireball / lance), Fireball impact, Lance hit, Ember Step out / in, Kindle, Soul Siphon, Umbral Shroud, `_light_flash` |
| `ice_vfx.gd` (Torvald) | Rime Bolt projectile + hit, Flash Freeze, Rime Aegis (+ per shielded unit), `_light_flash` |
| `nature_vfx.gd` (Ysolde) | Thornburst, Wild Bloom, Call the Thicket, Sapling sprout, `_light_flash` |
| `caster_fire_vfx.gd` | Slag Rain (flying light along the glob's arc + impact at the landing), Mana Scald, Stoke |
| `caster_ice_vfx.gd` | Rime Bulwark rise, shatter / melt, Scrying Rune |
| `caster_nature_vfx.gd` | Snagroot (at the snap), Pollen Haze, Seedcloak |
| `caster_shadow_vfx.gd` | Blood Tithe (new tether only, throttled), Umbral Passage (both rifts), Passage step (throttled), Vigil |

Every call passes the caster's team (hero hubs: the wizard / summon, caster families: `fx.team`, and only when the
family's own fog check shows the effect). Fog rule in SpellFxG: the local team's own effects always show; any other
team's, and a call without a team (the routed hub light flashes), only where the local team sees the point. Pieces
riding a projectile re-check 4 x / s and hide while an enemy shot flies through unseen fog (test_gb_vfx checks all of it).
`combat_vfx.gd` was not changed.

### Layers the G layer adds

- **Boiling sphere** (`g_billow.gdshader`): a domain-warped, noise-displaced sphere that cools from a hot core to smoke
  and dissolves through its noise. Palettes: fire, fire_core, smoke, molten, shadow (dark vortex with a violet rim in
  implode mode), ice, steam, dust, gold. Used for the Fireball explosion (core + fireball + smoke plume) and its
  flying head, Ember Step, Kindle, Slag Rain, the Shadow implosions (Soul Siphon, Umbral Shroud, Umbral Passage),
  Lance hit, ice / steam puffs, Thornburst dust, Wild Bloom glow.
- **Screen-space distortion** (`g_distort.gdshader`, High / Ultra only): shockwave rings (Fireball, Ember Step landing,
  Kindle, Flash Freeze, Thornburst, Slag Rain, Bulwark), implosion rings (Soul Siphon, Shroud, Passage), heat haze over
  the Fireball / Slag Rain craters, and a heat haze riding the Fireball at Ultra.
- **Pooled dynamic lights** with a fast attack and squared decay; projectiles carry a flying light (Fireball orange,
  Lance violet, slag glob along its arc). The hubs' own light flashes are routed here at Medium+ with the **same
  energies**, and no recipe adds a second light where a hub already flashes one (the Fireball impact stays at the graded
  3.5). **No Ice light at all** in the layer (no Rime Bolt flying light, no Bulwark / shatter / Scrying Rune flash): the
  Ice readability limits of 2026-10-12 hold. No light casts shadows.
- **Particle layers**: velocity-aligned ember streaks, glowing debris chunks, smoke plumes (soft-edged at High+),
  rising ash with turbulence, flame-tongue rings, void motes pulled inward, violet sparks, spinning ice shards, frost
  mist, ice glints, earth clods, dust rings, leaves, spiralling petals, spores, steam; trails on the three projectiles.
- **Ground marks** (`g_mark.gdshader`): frost (Rime Bolt hit), void burn with a rune ring (Lance hit, Soul Siphon).
  Fire scorches stay the hubs' own.

### Readability rules kept

Big spheres live <= 0.85 s and break up from their thin parts; smoke <= 0.58 opacity and rises above the units; ground
marks <= 0.62 alpha; the Ice cyan-wash and Kindle-disc fixes of the earlier grade passes are untouched (same light
energies, no new Ice light flashes, mist kept faint).

## Budget

One `SpellFxG` per level (group `spell_fx_g`), made on first use next to the hub and rebuilt when the tier changes.
Everything is pre-built and pooled (a full pool steals its oldest slot); nothing is created per cast except a few small
dictionaries for delayed recipes. Bursts are not started beyond 70 m from the camera, at most 18 a frame.

| Pool | Medium | High | Ultra |
|---|---|---|---|
| boiling spheres | 6 | 10 | 14 |
| distortion quads | 0 | 6 | 10 |
| ground marks | 8 | 12 | 16 |
| lights | 3 | 6 | 8 |
| projectile trails | 4 | 6 | 8 |
| emitters per burst look | 2 | 3 | 4 |
| particle amounts | x0.5 | x1.0 | x1.6 |

## Measurements (RTX 3070 Laptop, 1600 x 900 window, other Godot runs active on the PC)

20-spell storm: every wizard and caster casts on a 30-unit clump, 20 casts in 2.5 s; round 1 warms the pipelines,
round 2 is measured (`art/vfx/spells_g/gb_vfx_shots.gd -- --storm <tag>`, results `docs/art/lab/gb_vfx/storm_*.json`).

| Run | avg fps | 1 % low | min |
|---|---|---|---|
| High, without G-B (`--no-g`) | 150 | 51 | 14 |
| Medium | 147 | 50 | 13 |
| High | 117 | 44 | 12 |
| Ultra | 100 | 41 | 11 |

Average stays far above 60 at High and Ultra (the G-B layer costs about 2 ms a frame at High in a storm). The 1 % lows
and the single worst frame are the same without the layer, so they come from the machine (parallel Godot runs) or
the base scene, not from G-B. Headless gates: smoke `victory=true`, perf_test `PERF OK` (norm 5.28 / limit 6.72).

## Contact sheets

`docs/art/lab/gb_vfx/` (`.gdignore` inside, no imports):
- `gb_vfx_before_after_close.jpg`: every family, before (left) | after (right), close camera (zoom 11), High.
- `gb_vfx_before_after.jpg`: the same at the RTS camera distance (zoom 19-21).
- `before*/`, `after*/`: the per-family sheets (cast / impact / linger); `probe_fireball_impact_*.jpg`: the new
  Fireball explosion alone at 0.12 / 0.24 / 0.36 / 0.48 s; `storm_*.jpg`: one storm frame per tier.
The "before" sheets are the same build with `--no-g` (same tier, same lighting).

Commands (windowed; `'--'` quoted in PowerShell):

```
tools\godot_run.ps1 --path . res://art/vfx/spells_g/gb_vfx_shots.tscn --fixed-fps 60 --quit-after 30000 '--' --gfx=high --shots after [--zoom 11] [--only fire|shadow|ice|nature|casters] [--no-g]
tools\godot_run.ps1 --path . res://art/vfx/spells_g/gb_vfx_shots.tscn --quit-after 90000 '--' --gfx=ultra --storm ultra
tools\godot_run.ps1 --path . res://art/vfx/spells_g/gb_vfx_shots.tscn --quit-after 2000 '--' --gfx=high --compose before_close after_close
tools\godot_run.ps1 --path . res://art/vfx/spells_g/gb_vfx_shots.tscn --fixed-fps 60 --quit-after 2000 '--' --gfx=high --probe fireball_impact
```

## Tests

`tests/test_gb_vfx.gd`: Low builds nothing and the hubs keep their own lights; every recipe id a hub calls exists and
every recipe is called (source scan); at High one layer per level, pools sized by tier, every recipe plays twice with a
flat node count and everything back in its pool; hub lights routed; a tier change rebuilds; Low drops it.
Also green: test_caster_vfx_review, test_ice_vfx_read, test_13b_v6, test_13b_v7, test_13b_v9, test_casters.

## Later ideas

- The Shadow layer is subtle next to Malrik's strong violet base effects; a darker base (fewer additive violets) would
  let the void spheres read more.
- G1's glow / volumetric fog may change: re-grade the fire palette (`PALETTES` in spell_fx_g.gd) against the final glow.
