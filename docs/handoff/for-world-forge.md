# Requests for World Forge (tools/world_forge/, owner four-wizards-high)

## `flock` statement (tech-artist, prologue P3 dragon sky, 2026-09-27)
The flock actor is ready: `art/cinematics/flocks/` (README there). **Today it is placed with the existing line**
(no tool change needed):
```
place res://art/cinematics/flocks/dragon_sky.tscn  at=(0,0)  tag=dragons  radius=0.5
```
Request: a `flock` statement so a spec can set the parameters without a new preset scene:
```
flock <tag>  at=(x,z)  preset=sky|far  seed=7  elders=2  big=10  small=42  heroes=2  radius=90  height=22..70
      elder_height=75..115  kinds=cinder_dragon,frost_dragon,roc  small_kinds=...  pattern=mixed|orbit|figure8|wander
      arrive_until=6  leave_at=57  leave_dir=(x,y,z)
```
Build = instance `res://art/cinematics/flocks/dragon_sky.tscn` (`preset=far`: `dragon_sky_far.tscn`) under `Placed`,
name it `<tag>`, set the matching exports of `DragonFlock` (names in the README table: `flock_seed`, `elders`, `big`,
`small`, `heroes`, `radius`, `height` Vector2, `elder_height`, `kinds_big`, `kinds_small`, `pattern`, `arrive_until`,
`leave_at`, `leave_dir`) before `add_child`, owner = root (the exports are saved in the set .tscn).
Checks: skip it in M2 / M3 (camera clearance / line of sight: flyers move, the node has no mesh at build time); B1 can
add `DragonFlock.budget()["draws"]` after one `set_cine_time(0)` (~87 draws with 2 heroes, ~7 with heroes=0). `sheet`
could call `get_tree().call_group(&"cine_timed", &"set_cine_time", t)` with the mark's a / b / c time so the stills
show the flock at that moment.

## Ashwind Reach: a wider Muster Pad clearing (ui-coder, WS3.U1, 2026-10-13)
The pad plate is 26 x 20 m with its rim (24 x 18 cells + 1 m rim, wave-strike.md 15.1), and the WS3.M1 clearing is
20 x 26 m, so trees stand right on the rim: seen from the pad camera (P: behind the pad, pitch 72, zoom 37) the canopies
hide row 0 (the front line) and rows 10-11 (casters), see `docs/ui/lab/ws_pad.png`. Request: grow the clearing to about
**28 x 34 m** (x / z for seat 0: >= 4 m free behind the back edge, i.e. toward -x, >= 3 m ahead of the front edge and on
both sides) and keep the forest trees' jitter out of it (trees are scattered +-1.6 m around their grid in
`WaveStrikeLevel._add_ws_block`, so the block edge needs that margin too). Same for seat 1 (rot180). No UI change needed.
