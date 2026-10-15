# Lighting, sky and post-process (task A.11)

The global look of every map: a warm, readable, hand-painted daylight (SC2 / LoL-like), plus a colder
Ice variant. Everything lives in `art/environment/world_env.tres` and `art/environment/lighting/`.
Low (and every test / lab run) is cheap by design: no SSR, SSAO, SSIL, SDFGI or volumetric fog; the sky is static
(radiance baked once). Medium / High / Ultra add SSAO, SSIL and soft PCSS sun shadows on top (see "Quality tiers").

## Files
| File | What |
|---|---|
| `art/environment/world_env.tres` | The warm Environment (default for every map). `main.gd` already loads it today. |
| `art/environment/lighting/world_env_ice.tres` | The cold Ice Environment. |
| `art/environment/lighting/lighting_preset.gd` | `LightingPreset` resource: environment + sun + fill light + vignette values. |
| `art/environment/lighting/preset_warm.tres`, `preset_ice.tres` | The two moods. |
| `art/environment/lighting/lighting_rig.gd` | `LightingRig` (Node3D): builds WorldEnvironment, sun, fill light and vignette from a preset. |
| `art/environment/lighting/painted_sky.gdshader` | Stylised sky: painted 3-band gradient, sun halo. Also the ambient light source. |
| `art/environment/lighting/vignette.gdshader` | Screen vignette + faint top-of-screen haze (CanvasLayer -1, under the HUD, ignores the mouse). |
| `art/environment/lighting/light_preview.gd` | Screenshot script (skirmish, staged centre fight). |
| `art/environment/lighting/g1_preview.gd` | Task G1: screenshots + fps / GPU ms per graphics tier (`docs/art/lab/g1_lighting/`). |

## Quality tiers (task G1, 2026-10-15)
`LightingRig.set_quality(q)` (0 Low, 1 Medium, 2 High, 3 Ultra; group `"lighting_rigs"`) layers the tier on top of the
preset: any time, both ways, idempotent. In `_ready` the rig reads `GameSettings.effective_graphics_quality()` (`--gfx=`
first, Low in any headless / `-s` run, else the saved setting); `GameSettings.apply_graphics(tree)` (HUD at match start,
Settings row) calls `set_quality` on every rig and sets the viewport side (MSAA / SMAA / LOD / anisotropy, ui-coder).
The rig shows **its own copy** of the preset Environment (one copy per preset; the same object when a preset comes
back), so tiers and missions tinting the environment (mission_04, e5) never edit the shared `.tres`.
**Low = the preset exactly as authored** (`tests/test_g1_lighting.gd` compares every stored property); the global
shadow / AO settings go back to the project's values on Low and when the last rig leaves the tree.

| | Low (today) | Medium | High | Ultra |
|---|---|---|---|---|
| SSAO | off | radius 1.2, intensity 1.8, power 1.4, light_affect 0 | radius 1.4, intensity 2.2, power 1.5, light_affect 0.05 | radius 1.5, intensity 2.4, power 1.55 |
| SSAO quality (global) | project (Medium, half size) | Low, half | Medium, half | High, **full size** |
| SSIL (bounce light) | off | off | radius 4, intensity 1.0 | radius 5, intensity 1.1 |
| SSIL quality (global) | project | project | Low, half | Medium, half |
| Sun shadows | preset `shadow_blur` (1.6 warm), angular 0 | same | **PCSS** `light_angular_distance` 1.2, blur x0.75 | PCSS 1.4, blur x0.75 |
| Directional atlas / filter | project (4096, Soft Low) | 4096, Soft Medium | 4096, Soft High | **8192**, Soft Ultra |
| Positional filter | project | Soft Medium | Soft Medium | Soft High |

What each buys from the RTS camera (`docs/art/lab/g1_lighting/contact_sheet.jpg`, `detail_1to1.jpg`): SSAO grounds units
and props (contact darkening under feet, in roof eaves, between keep towers) and leaves sunlit tops alone; SSIL bleeds
the emissives (centre beacon, keep windows, night fires) and the grass onto nearby surfaces (best at night,
`night_q*_base_z30.png`); PCSS keeps a shadow crisp where it touches its caster and soft further away. Ice and Emberfall
night get the same tiers (`EmberfallNight.fade_to` keeps the tier on its blend copy).

Tried and **not kept**:
- Volumetric fog / valley mist (a low FogVolume over the map, sun shafts): from 30-55 m above a flat map the camera looks
  through the whole layer, so it reads as a pale wash (water and team colours lose contrast) and shafts do not show
  top-down. About +300 MB VRAM.
- SSR: the river water is a transparent (`blend_mix`) shader, which SSR does not reflect. Reflections belong in the water
  shader (G2).
- SDFGI: thin props on an open flat map make leaks / flicker likely, SSIL already gives the visible bounce, and the cost
  would push Ultra under 60 fps.
- Animated sky clouds: the RTS camera sees the sky only past the map edge at zoom 55, and a sky that changes re-renders
  the radiance (ambient) every frame. Cloud **shadows** on the ground are the visible version (G2, ground shader).

### Measured (RTX 3070 Laptop, i7-12650H, 1920x1055 window, centre fight 16 units, zoom 30, vsync off)
`g1_preview.gd` runs every tier in one process with interleaved rounds. The PC was busy during all runs (3 headless
balance-batch Godots + other agents' windowed Godots), so the fps columns are CPU-limited and noisy; the GPU time
(`viewport_get_measured_render_time_gpu`, median of 900 frames, cleanest rounds) is the reliable cost. Includes the
viewport side of each tier (MSAA / SMAA / LOD).

| Tier | GPU ms (median) | GPU-bound fps | Avg fps, busy PC (best rounds) | 1 % low (best rounds) | VRAM (Godot) |
|---|---|---|---|---|---|
| Low | 3.3-4.0 | ~250-300 | 115-206 | 51-183 | 379 MB |
| Medium | 4.6-5.1 | ~200 | 130-161 | 50-151 | 450 MB |
| High | 7.5-9.9 | ~100-130 | 81-101 | 42-96 | 540 MB |
| Ultra | 13.7-15.3 | ~65-73 | 56-70 | 31-66 | 805 MB |

Targets: High >= 90 fps holds on the GPU side (~100+); Ultra >= 60 fps holds with a thin margin (~65). With the viewport
left on Low (`rigonly=1`) the lighting part of Ultra costs about the same as High: most of Ultra's extra GPU time is
8x MSAA (viewport) + the 8192 atlas. Re-measure on an idle PC before quoting numbers to players.

Re-run (windowed only; in PowerShell quote the `'--'`, or it is swallowed and the script gets no arguments):
`tools\godot_run.ps1 --path . -s res://art/environment/lighting/g1_preview.gd --resolution 1920x1080 --quit-after 200000 '--' "tiers=0,1,2,3" tag=warm`
(`rig=ice player=ice`, `rig=night`, `only=fight_z30`, `perf=0` / `shots=0`, `rounds=3`, `rigonly=1`, tweaks
`env:ssao_intensity=2.6` / `sun:light_angular_distance=2.0`). Screens: `docs/art/lab/g1_lighting/<tag>_q<tier>_<shot>.png`.

## The warm look (preset_warm + world_env.tres)
| Setting | Value | Why |
|---|---|---|
| Sun | colour `(1.0, 0.89, 0.74)`, energy 1.35, rotation `(-52, 40, 0)`, shadows on, `shadow_blur 1.6`, max distance 110 | Golden sun; shadows fall up-left of units (visible, never over the unit below them); soft edges |
| Fill light | `(0.55, 0.66, 0.95)`, energy 0.25, rotation `(-30, -140, 0)`, **no shadows**, not in the sky | Cool light on the faces the sun misses: painted warm / cool split |
| Ambient | source **Sky**, energy 0.7 | Tops get the blue zenith, sides the warm horizon: cool shadows without a flat grey |
| Sky | zenith `(0.30, 0.47, 0.76)`, horizon `(0.86, 0.78, 0.62)`, ground `(0.12, 0.12, 0.09)`, soft posterised steps | Painted, not photographic; the dark ground half frames the map past its edges |
| Tonemap | **ACES**, exposure 0.92, white 8 | Punchier, more saturated colour blocks than Filmic; exposure keeps pale stone from clipping |
| Glow | `SCREEN` blend, intensity 0.45, bloom 0, threshold 1.2, hdr scale 2, levels 2 (0.3), 3 (1.0), 5 (0.6) | Emissives (2.5-4) get a tight core + wide soft halo; SCREEN + no bloom = nothing washes to white |
| Adjustments | contrast 1.03, saturation 1.04, colour LUT (`GradientTexture1D`): cool lifted blacks, neutral mids, slightly warm highlights | The colour grade |
| Fog | **depth** fog, begin 55 m, end 190 m, density 0.55, warm `(0.80, 0.75, 0.64)`, sky affect 0 | Only the far top of the screen at zoom 45-55 gets a light aerial haze; zoom 10-35 is untouched |
| Vignette | warm dark `(0.10, 0.06, 0.05)` strength 0.35, top haze 0.10 | Frames the view, adds depth |

Changes against art-keep.md 0.4 (the old values): tonemap FILMIC -> ACES, glow ADDITIVE -> SCREEN (bloom 0.08 -> 0),
ambient colour 0.35 -> sky 0.7, SSAO still off. The emission energies of 0.4 stay valid.

## The Ice look (preset_ice + world_env_ice.tres)
Low pale winter sun `(0.86, 0.93, 1.0)` energy 1.25 at `(-40, 55, 0)` (longer shadows, `shadow_blur 2.0`), pale blue
sky, ambient 0.7, ACES exposure 0.84 (ice buildings are near white), saturation 0.82, cool LUT (blue blacks, white
highlights), glow intensity 0.38 threshold 1.3 (ice crystals stay crisp), closer frosty fog (40-160 m, `(0.78, 0.86, 0.95)`),
blue-black vignette 0.4 and a cold top haze 0.14.

## For the lead: main.gd lines (not applied by me)
Today `scripts/world/main.gd` `_build_environment()` loads `world_env.tres` and makes its own sun, so the new
Environment already shows (screens `polish_light_envonly_*`). To get the tuned sun, the fill light, the vignette and the
Ice preset, replace the first block of `_build_environment()` (the `if ResourceLoader.exists(WORLD_ENV_PATH):` block,
lines 207-222) with:

```gdscript
const LIGHTING_RIG_PATH := "res://art/environment/lighting/lighting_rig.gd"   # next to WORLD_ENV_PATH

func _build_environment() -> void:
	# The tech-artist's lighting (docs/art/lighting.md): environment, sun, fill light, vignette.
	if ResourceLoader.exists(LIGHTING_RIG_PATH):
		var rig: Node = (load(LIGHTING_RIG_PATH) as GDScript).new()
		rig.set(&"preset_id", _lighting_preset())
		add_child(rig)
		return
	# ... the existing WORLD_ENV_PATH block and the old fallback stay below, unchanged ...


## The map's mood: &"warm" (default) or &"ice". Missions / maps override it (an Ice mission returns &"ice").
func _lighting_preset() -> StringName:
	return &"warm"
```

- The rig is a `Node3D` named `LightingRig` with children `WorldEnvironment`, `Sun`, `Fill`, `Vignette` (CanvasLayer -1).
  `rig.sun` is the DirectionalLight3D if anything needs it.
- Switching mood at runtime: `rig.apply(LightingRig.load_preset(&"ice"))`.
- Portraits (`scripts/ui/portrait.gd`) keep their own small environment; nothing to change.
- Project setting suggestion (optional, lead): `rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality`
  stays at its default (soft low); `shadow_blur` does the softening, no extra cost.

## Screenshots (`docs/art/screens/`, 1600x900, game camera pitch 55)
Taken with `light_preview.gd`, same map and art in every set (`rig=old` rebuilds the pre-A.11 lighting in code):
- `polish_light_before_*`: old lighting. `polish_light_after_*`: warm rig. `polish_light_envonly_*`: new
  world_env.tres with today's main.gd sun (before the lines above are applied). `polish_light_ice_*`: Ice rig + Ice army.
- Shots: `base_z30`, `base_z45` (player keep), `fight_z22`, `fight_z40` (staged fight in the centre ring),
  `enemy_z35` (Shadow keep), `edge_z55` (north map edge).

Re-run (windowed only):
`Godot_v4.7.2-stable_win64.exe --path . -s res://art/environment/lighting/light_preview.gd --resolution 1600x900 --quit-after 6000 -- tag=after rig=warm`
(`rig=old|none|warm|ice`, `player=ice`, `only=base_z30,fight_z22`, test tweaks like `env:glow_intensity=0.6`,
`sun:light_energy=1.5`, `vig:strength=0.2`).
