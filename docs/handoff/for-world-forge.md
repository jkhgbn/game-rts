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
