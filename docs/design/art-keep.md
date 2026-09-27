# Art direction: the two keeps (wave 3, tasks 3.V1 / 3.V2 / 3.S1)

Written 2026-09-25 (task 3.D2). Source of truth for the tech-artist (`art/buildings/fire_keep.tscn`,
`art/buildings/dusk_keep.tscn`) and for the systems coder who plugs them in (3.S1).
Metres, seconds, degrees. Positions are `(x, y, z)` **relative to the building centre on the ground**
(`y` up). Colours are `Color(r, g, b)` in 0-1, hex beside them. Everything here is original; the words
"tower", "spire", "banner" describe shapes, not any existing game's buildings.

Section 0 is the **global art style** for the whole game (units and buildings to come will follow it).
Sections 1-11 are the two keeps.

---

## 0. Global art style (all buildings, units, effects from wave 3 on)

User direction (2026-09-25): a stylised, chunky, hand-painted look with crisp glowing details, readable from a
high camera. Nothing photo-real. These are the buildable rules; a scene that breaks one needs a reason in
its handoff note.

### 0.1 Shapes
| Rule | Number |
|---|---|
| Exaggerated proportions | Roofs / caps **1.3-1.6 x** wider than the wall they sit on; walls **>= 0.6 m** thick where a thickness is visible; any decorative detail **>= 0.35 m** in its smallest dimension (smaller is invisible at 40 m) |
| Silhouette first | Every building must be identifiable from its **black silhouette** at 40 m: one dominant vertical element + one asymmetric secondary element. Test: render it unshaded black on white in a screenshot, name it |
| Three levels of detail | Big masses (plinth, body, roof) -> medium (towers, gate, fins) -> small (braziers, merlons, trims). Nothing smaller than the small level |
| Tops are light, bottoms are dark | Value goes from **0.72 x** the base colour at ground contact to **1.08 x** at the top (fake sky light + ambient occlusion, see the shader) |
| Ground contact | Every building has a **contact decal** (soft dark quad, see 0.5) and a few rubble / scorch pieces so it never looks "placed on" the ground |

### 0.2 Palette per kingdom (5 colours per building, no more)
Split of a building's visible surface: **~60 % stone, ~25 % team colour (cloth / roofs), ~10 % trim metal, ~5 % glow**.
Team colours keep saturation >= 0.6; stone keeps saturation <= 0.2 so the team colour pops.
| Kingdom | Team (roofs, cloth) | Glow (emissive) | Stone (walls) | Dark stone (plinth, obsidian) | Trim metal | Cloth shadow / stripe |
|---|---|---|---|---|---|---|
| Fire | `(0.85, 0.30, 0.12)` #D94D1F | `(1.00, 0.55, 0.15)` #FF8C26 | `(0.30, 0.26, 0.24)` #4D423D | `(0.10, 0.08, 0.09)` #1A1417 | bronze `(0.62, 0.40, 0.16)` #9E6629 | `(0.55, 0.08, 0.05)` #8C140D |
| Shadow | `(0.42, 0.22, 0.60)` #6B3899 | `(0.70, 0.30, 1.00)` #B34DFF | `(0.20, 0.17, 0.26)` #332B42 | `(0.09, 0.07, 0.13)` #171221 | tarnished silver `(0.55, 0.52, 0.66)` #8C85A8 | `(0.18, 0.08, 0.28)` #2E1447 |
| Ice (later) | `(0.45, 0.75, 0.95)` #73BFF2 | `(0.75, 0.92, 1.00)` #BFEBFF | `(0.62, 0.70, 0.78)` #9EB3C7 | `(0.30, 0.38, 0.48)` #4D617A | silver-blue `(0.70, 0.78, 0.88)` #B3C7E0 | `(0.15, 0.35, 0.60)` #265999 |
| Nature (later) | `(0.35, 0.70, 0.25)` #59B340 | `(0.75, 1.00, 0.40)` #BFFF66 | mossy `(0.45, 0.42, 0.32)` #736B52 | `(0.22, 0.20, 0.14)` #383324 | bark `(0.40, 0.28, 0.16)` #664729 | `(0.15, 0.40, 0.15)` #266626 |
The existing unit colours in `units-fire-shadow.md` stay; they are the "team" column applied to bodies.

### 0.3 Hand-painted shading: one shared shader `art/shaders/painted.gdshader`
Used by every opaque building part (and units later). StandardMaterial3D is allowed only for particles and
glow spheres. Uniforms and formulas, so it looks the same everywhere:
| Feature | How |
|---|---|
| Colour blocks | `uniform vec3 base_color`. No albedo textures, ever (no photo textures in this game) |
| Painted variation | Sample a `NoiseTexture2D` (FastNoiseLite, Perlin, frequency 0.5, seed fixed) **triplanar in world space** at scale 0.5 m: value tint `1.0 + (noise - 0.5) * 0.20`; a second sample at 2.5 m scale: `1.0 + (noise - 0.5) * 0.12`. Multiplied into albedo |
| Height gradient (fake AO + sky light) | `instance uniform float ao_bottom` (world y of the part's bottom), `instance uniform float ao_height` (its height). `albedo *= mix(0.72, 1.08, smoothstep(0.0, 1.0, (world_y - ao_bottom) / ao_height))`. Plus a **contact band**: `albedo *= mix(0.55, 1.0, smoothstep(0.0, 0.35, world_y - ao_bottom))` |
| Toon-ish ramp | In `light()`: `float d = dot(NORMAL, LIGHT) * 0.5 + 0.5; float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;` `DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR * ALBEDO;` No specular except on trims (`uniform float spec_strength`, 0 stone, 0.35 metal: `SPECULAR_LIGHT += pow(max(dot(reflect(-LIGHT, NORMAL), VIEW), 0.0), 24.0) * spec_strength * LIGHT_COLOR * ATTENUATION`) |
| Soft rim light | `float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0); EMISSION += rim * rim_color * rim_strength;` default `rim_color (0.55, 0.65, 0.85)`, `rim_strength 0.25`. Selected: `set_selected` sets `rim_color` = team colour, `rim_strength 0.9` (see 7.5) |
| Cracks / veins (optional per material) | `uniform float crack_strength` (0 = off), `uniform vec3 crack_color`, `uniform float crack_speed`, `uniform float damage` (0-1). Ridged noise at 0.8 m scale: `c = smoothstep(0.66 - damage * 0.10, 0.72, ridged) * crack_strength`; `EMISSION += crack_color * c * (2.0 + 1.0 * sin(TIME * crack_speed + world_y * 1.7))`. Also `albedo *= 1.0 - damage * 0.35` (soot / dimming) |
| Outline | **No** outline pass (costs a full-screen pass and fights the top-down read). Separation comes from value contrast: light tops, dark plinths, dark contact band, trims in a different hue |
| Vertex colours | Not needed; the instance uniforms replace them |

### 0.4 Glow, bloom, lighting: `art/environment/world_env.tres` (the lead plugs it into `scenes/main.tscn`)
| Setting | Value |
|---|---|
| Tonemap | `FILMIC`, exposure 1.0, white 6.0 |
| Glow | on, `blend_mode ADDITIVE`, `intensity 0.55`, `strength 1.0`, `bloom 0.08`, `hdr_threshold 1.1`, `hdr_scale 2.0`, levels 3 and 5 on (others off) |
| Ambient | colour `(0.45, 0.52, 0.70)` energy 0.35 (cool ambient against a warm sun = painted contrast) |
| Sun (`DirectionalLight3D`, existing) | colour `(1.00, 0.93, 0.82)`, energy 1.3, rotation pitch -50°, yaw 35°, shadows on, `shadow_normal_bias 2.0` |
| SSAO / SSIL / SDFGI / volumetric fog | all **off** (AO is painted into the colour) |
| Anti-aliasing | MSAA 2x, no FXAA/TAA |
| Emission energies | glowing gems / orbs / runes **2.5-4.0** (crosses the bloom threshold, halos), cracks and slits **1.5-2.5**, banners and cloth **0** (except selected rim), stone **0** |
Rule of thumb: from 40 m every building shows **2-4 glowing points** and nothing more; more turns into noise.

### 0.5 Ground contact (SC2-style heaviness), one recipe for every building
- **Contact decal**: `PlaneMesh` of `footprint + 2 m` per side at `y 0.03`, `StandardMaterial3D` unshaded, alpha
  blend, no depth write, albedo = radial `GradientTexture2D` from `(0.05, 0.03, 0.02, 0.60)` at the centre to
  alpha 0 at the edge. Casts no shadow.
- **Rubble**: one `MultiMeshInstance3D` of 6-10 `BoxMesh` 0.35-0.6 m cubes, random yaw and 10-20° tilt, half sunk,
  around the plinth, in the kingdom's dark stone. One draw call.
- **Scorch** (Fire kingdom) or **frost / moss / mist** (others) is the same decal recipe with a second colour.

### 0.6 Effects
- Particles are **unshaded billboards** (`StandardMaterial3D`, `billboard_mode PARTICLES`, `blend_mode ADD` for
  fire / sparks / motes, `MIX` for smoke / mist, `shading_mode UNSHADED`, no depth write), albedo = a radial
  soft gradient texture. Colour ramps come from `ParticleProcessMaterial.color_ramp`.
- Magic = glow + motion: anything magical rotates, bobs or pulses (never static), and its emission is >= 2.5
  so the bloom halo carries it at 40 m.
- Team colour accents are always **the team colour or its glow**, never a third tint.

---

## 1. The two keeps at a glance
| | Vessa's **Fire Keep** ("the Ember Bastion") | Malrik's **Dusk Keep** ("the Umbral Spire") |
|---|---|---|
| One-sentence read from the RTS camera | A squat black-stone fortress with four horned towers, a fat central donjon and a jagged obsidian spire, glowing from every crack, with three ember crystals circling the spire and four braziers roaring at its corners. | A tall, twisted, six-sided black spire leaning fins outward like a crown, bathed in purple runes, with a floating black shard hovering above its tip and shadow-mist pooling at its feet. |
| Mood in words | Forge, volcano, war drum. Heavy, hot, wide. Everything says "the fire is inside, the walls barely hold it". | Cathedral of night, needle, whisper. Thin, tall, cold. Everything says "something is watching from the top". |
| Why it looks epic at 10-55 m | **Silhouette**: the wide base + narrow spire makes a pyramid the eye reads at once. **Height** 14.8 m (2.5 x any other building). **Glow**: 4 brazier fires, the spire's crack veins and the Ember Heart bloom at every zoom. **Motion**: crystals orbit, banners wave, embers rise, flames flicker | **Silhouette**: a needle with fins, no other building is this thin or this tall (17.5 m). **Glow**: rune ring, gate slits, three soul lanterns, the shard core. **Motion**: the ring turns one way, the shard the other, motes rise, mist crawls |
| At zoom 10-15 (close) | The base, gate, braziers and banners fill the screen; the spire cuts through the top edge (the camera is lower than the tip: 12.3 m high at zoom 15). This is wanted: "it is bigger than the screen" | Same: fins and body fill the frame; the shard is off-screen above |
| At zoom 30-55 (normal / far) | The whole pyramid and the circling crystals are visible; 4 glowing points | Whole needle, ring and shard visible; 4-5 glowing points |

Camera facts used above: pitch 55°, zoom 10-55 m (`rts_camera.gd`), fov 75° (Godot default). At zoom
*Z* the camera is `0.82 Z` above the focus point; the top of the frame cuts anything higher than
`0.82 Z - 0.315 D` at horizontal distance `D` from the camera. So at zoom 40 the tip of a 17.5 m spire
sitting on the focus point is well inside the frame.

## 2. Footprint, height, overhang (both keeps)
| Item | Value |
|---|---|
| Collision / placement footprint | **3 x 3 cells = 6 x 6 m**, unchanged (`buildings.md`). The scene has no collision; `Building` keeps it |
| Max visual height | **18 m** (Fire 14.8 m to the Ember Heart, Dusk 17.5 m to the shard tip) |
| Max overhang at ground (y < 2.5) | **0.3 m** per side (plinths 6.4 x 6.4 or hex corner radius 3.3); nothing walks through it because units path around the 6 x 6 footprint |
| Max overhang above 2.5 m | **1.0 m** per side (tower caps, fins, the crystal ring at 2.6 + 0.6 = 3.2 m radius stays inside) |
| Ground contact decal | 8 x 8 m quad (decal only, no collision) |
| Gate side | Local **-Z**. 3.S1 rotates the instance so the gate faces the map centre along x: Fire keep `rotation.y = -90°` (gate faces east, +x), Dusk Keep `rotation.y = +90°` (gate faces west, -x). The unit spawn corner (`buildings.md`) is next to that face |

## 3. Fire Keep: part list ("Ember Bastion")
Materials: **S** stone `painted.gdshader` base `(0.30, 0.26, 0.24)`, cracks on (`crack_color (1.0, 0.55, 0.15)`,
`crack_strength 0.8`, `crack_speed 1.2`); **O** obsidian `painted` base `(0.10, 0.08, 0.09)`, `spec_strength 0.25`,
cracks on (`crack_strength 1.0`); **D** dark stone `painted` base `(0.14, 0.12, 0.11)`, no cracks;
**M** bronze `painted` base `(0.62, 0.40, 0.16)`, `spec_strength 0.35`; **T** team cloth `banner.gdshader`;
**G** glow `rune_glow.gdshader` colour `(1.0, 0.55, 0.15)`. Six materials, all shared.
| # | Part | Primitive and size (x, y, z) | Position (centre) | Mat | Notes |
|---|---|---|---|---|---|
| 1 | Plinth, lower step | `BoxMesh` 6.4 x 0.6 x 6.4 | (0, 0.3, 0) | D | Chunky, 0.2 m overhang |
| 2 | Plinth, upper step | `BoxMesh` 6.0 x 0.4 x 6.0 | (0, 0.8, 0) | D | Top at y 1.0 = "floor" |
| 3 | Wall block | `BoxMesh` 5.0 x 4.0 x 5.0 | (0, 3.0, 0) | S | Lava cracks glow through it |
| 4 | Parapet ledge | 4 x `BoxMesh` 5.6 x 0.5 x 0.5 (one per side) | (0, 5.25, +-2.55) and (+-2.55, 5.25, 0) | M | Bronze band, 0.3 m wider than the wall each side |
| 5 | Merlons | `MultiMeshInstance3D`, 20 x `BoxMesh` 0.45 x 0.45 x 0.45 | 5 per side at y 5.72, spaced 1.0 m along each ledge | D | One draw call |
| 6 | Corner towers | `MultiMeshInstance3D`, 4 x `CylinderMesh` r 0.9 h 7.0, 8 segments | (+-2.6, 3.5, +-2.6) | S | Overhang 0.5 m above y 1 |
| 7 | Tower caps | `MultiMeshInstance3D`, 4 x cone (`CylinderMesh` top r 0, bottom r 1.3, h 1.8, 8 segments) | (+-2.6, 7.9, +-2.6) | team `painted` base `(0.85, 0.30, 0.12)` | Caps 1.45 x wider than the tower (rule 0.1) |
| 8 | Tower horns | `MultiMeshInstance3D`, 4 x cone (top r 0, bottom r 0.25, h 1.2), tilted 20° outward from the centre | on each cap, base at (+-2.9, 8.6, +-2.9) | M | The "horned" silhouette |
| 9 | Donjon | `BoxMesh` 2.8 x 5.0 x 2.8 | (0, 7.5, 0) | S | From y 5 to 10 |
| 10 | Donjon ledge | `BoxMesh` 3.4 x 0.4 x 3.4 | (0, 10.2, 0) | M | |
| 11 | Donjon merlons | `MultiMeshInstance3D`, 12 x `BoxMesh` 0.4 x 0.4 x 0.4 | ring at y 10.6, 3 per side | D | |
| 12 | Spire | cone `CylinderMesh` top r 0, bottom r 1.7, h 4.2, **6 segments** (jagged) | (0, 12.5, 0) | O | From y 10.4 to 14.6; crack veins pulse |
| 13 | Ember Heart | `SphereMesh` r 0.45 | (0, 14.35, 0) | G, emission energy 4.0 | Sits in the spire tip, pulses 1.5 s |
| 14 | Crystal ring pivot | `Node3D` "Ring" | (0, 11.5, 0) | - | Rotates +12°/s about y; bobs +-0.2 m over 3.0 s |
| 15 | Ember crystals | 3 x octahedron = two cones base to base (`CylinderMesh` top r 0, bottom r 0.35, h 0.6, 4 segments, one flipped) | children of Ring at radius 2.6, angles 0 / 120 / 240° | G, emission 3.0 | Each also spins about its own y at 45°/s |
| 16 | Gate recess | `BoxMesh` 2.0 x 2.6 x 0.3 | (0, 2.3, -2.45) | `StandardMaterial3D` unshaded `(0.03, 0.02, 0.02)` | The dark hole |
| 17 | Gate lintel | `BoxMesh` 2.8 x 0.5 x 0.5 | (0, 3.85, -2.6) | M | |
| 18 | Portcullis | `MultiMeshInstance3D`, 5 x `BoxMesh` 0.1 x 2.4 x 0.1 | x = -0.8 .. 0.8 step 0.4, y 2.2, z -2.62 | G, emission 2.0 | Glowing hot bars, the "training" flash point |
| 19 | Braziers, stem | `MultiMeshInstance3D`, 4 x `CylinderMesh` r 0.18 h 0.9 | the four plinth corners (+-2.45, 1.45, +-2.45) | M | On the plinth top (y 1.0 to 1.9), just outside the corner towers; touching them is fine |
| 20 | Brazier bowls | `MultiMeshInstance3D`, 4 x `CylinderMesh` top r 0.42 bottom r 0.2 h 0.35 | (+-2.45, 2.05, +-2.45) | M | |
| 21 | Brazier coals | `MultiMeshInstance3D`, 4 x `SphereMesh` r 0.22 | (+-2.45, 2.2, +-2.45) | G, emission 3.0 | The bright core under each flame |
| 22 | Banners | 4 x `PlaneMesh` 0.9 x 2.2, `subdivide_width 3`, `subdivide_depth 10`, vertical, top edge fixed | one per wall face, centred, top at y 4.6, 0.04 m off the wall (z or x = +-2.55) | T | Waving (see 5.2); the gate face gets two at x = +-1.7 instead of one centred |
| 23 | Contact decal | `PlaneMesh` 8 x 8 | (0, 0.03, 0) | decal (0.5) | |
| 24 | Rubble | `MultiMeshInstance3D`, 8 cubes 0.35-0.6 | ring r 3.4-3.8, random | D | |
Draw calls idle: 24 mesh instances (MultiMeshes count 1 each) + 3 particle systems + 1 decal = **~28**.

## 4. Dusk Keep: part list ("Umbral Spire")
Hexagons are `CylinderMesh` with `radial_segments 6`, rotated about y so one **flat face is perpendicular to -Z**
(the gate face). Apothem (centre to a flat face) = radius x 0.866.
Materials: **S** stone `painted` base `(0.20, 0.17, 0.26)`, cracks on (`crack_color (0.70, 0.30, 1.00)`,
`crack_strength 0.6`, `crack_speed 0.7`); **O** obsidian `painted` base `(0.09, 0.07, 0.13)`, `spec_strength 0.3`,
cracks on (`crack_strength 0.9`); **D** dark stone base `(0.12, 0.10, 0.16)`; **M** tarnished silver base
`(0.55, 0.52, 0.66)`, `spec_strength 0.4`; **T** team cloth `banner.gdshader`; **G** glow `rune_glow.gdshader`
colour `(0.70, 0.30, 1.00)`. Six materials.
| # | Part | Primitive and size | Position (centre) | Mat | Notes |
|---|---|---|---|---|---|
| 1 | Plinth, lower | hex r 3.3 h 0.7 | (0, 0.35, 0) | D | Corner overhang 0.3 m |
| 2 | Plinth, upper | hex r 2.9 h 0.5 | (0, 0.95, 0) | D | Top at y 1.2 |
| 3 | Body | hex r 2.4 h 5.0 | (0, 3.7, 0) | S | y 1.2 to 6.2; shadow veins glow |
| 4 | Body cap | hex r 2.9 h 0.4 | (0, 6.4, 0) | M | Silver band, 1.2 x wider than the body |
| 5 | Fins | `MultiMeshInstance3D`, 6 x `BoxMesh` 0.35 x 4.0 x 1.0, each leaning **20° outward** | base of each fin at radius 2.6, y 6.0, one per hex corner direction (30°, 90°, ... ) | O | Tops reach radius ~4.0 at y 9.8 = 1.0 m overhang, the "crown" silhouette |
| 6 | Fin tips | `MultiMeshInstance3D`, 6 x `SphereMesh` r 0.22 | at each fin top | G, emission 2.5 | Six purple points that read at 40 m |
| 7 | Spire prism 1 | hex r 1.9 h 2.5 | (0, 7.45, 0) | O | y 6.2 to 8.7 |
| 8 | Spire prism 2 | hex r 1.5 h 2.5, **rotated 20°** about y | (0, 9.95, 0) | O | y 8.7 to 11.2 (the twist) |
| 9 | Spire prism 3 | hex r 1.1 h 2.5, **rotated 40°** | (0, 12.45, 0) | O | y 11.2 to 13.7 |
| 10 | Tip | cone top r 0, bottom r 1.1, h 1.8, 6 segments, rotated 60° | (0, 14.6, 0) | O | y 13.7 to 15.5 |
| 11 | Dusk Eye (shard) | octahedron: two cones (top r 0, bottom r 0.5, h 1.0, 4 segments) base to base | (0, 16.5, 0), bobs +-0.3 m over 4.0 s, spins **-20°/s** | O with `rim_strength 0.6` | Floating, never touches the tip |
| 12 | Shard core | `SphereMesh` r 0.3 | inside the shard | G, emission 4.0 | The brightest point of the keep; pulses 2.0 s |
| 13 | Rune ring | `TorusMesh` inner r 2.95 outer r 3.25 | (0, 6.9, 0), rotates **-8°/s** | G with `rune_bands 12` (see 5.3), emission 3.0 | Floats 0.5 m above the body cap, half-hidden by the fins |
| 14 | Gate arch | `BoxMesh` 1.6 x 3.2 x 0.3 | (0, 2.8, -2.12) | `StandardMaterial3D` unshaded `(0.02, 0.01, 0.03)` | On the -Z flat face (apothem 2.08) |
| 15 | Gate peak | `PrismMesh` 1.6 x 0.9 x 0.3 | (0, 4.85, -2.12) | same as 14 | Pointed arch |
| 16 | Gate slits | `MultiMeshInstance3D`, 2 x `BoxMesh` 0.08 x 2.6 x 0.06 | (+-0.55, 2.6, -2.2) | G, emission 2.5 | Two purple lines, the "training" flash point |
| 17 | Gate frame | `MultiMeshInstance3D`, 2 x `BoxMesh` 0.2 x 3.6 x 0.35 | (+-0.95, 3.0, -2.15) | M | |
| 18 | Banners | 3 x `PlaneMesh` 0.8 x 3.0, subdivide 3 x 12, vertical | on the flat faces at 60°, 180° and 300° from -Z (i.e. every other face, the gate face excluded), 0.04 m off the face, top at y 5.8 | T | |
| 19 | Soul lantern stems | `MultiMeshInstance3D`, 3 x `CylinderMesh` r 0.14 h 1.2 | on the upper plinth at radius 2.5, at the flat faces 0° (the gate face, beside the gate at x = +1.4), 120° and 240° measured from -Z; y 1.8 | M | On the faces without banners |
| 20 | Soul lantern orbs | `MultiMeshInstance3D`, 3 x `SphereMesh` r 0.24 | 0.3 m above each stem top (y 2.7), bob +-0.1 m over 2.5 s (animate the MultiMesh transforms or make 3 instances) | G, emission 3.0 | |
| 21 | Contact decal | `PlaneMesh` 8 x 8 | (0, 0.03, 0) | decal, second colour `(0.15, 0.06, 0.25, 0.35)` for the mist stain | |
| 22 | Rubble | `MultiMeshInstance3D`, 8 shards: `BoxMesh` 0.3 x 0.8 x 0.3 tilted 15-35°, half sunk | ring r 3.5-3.9 | D | "Broken teeth" around the base |
Draw calls idle: 22 mesh instances + 3 particle systems + 1 decal = **~26**.

## 5. Shaders (3 custom, shared by both keeps and every later building)
### 5.1 `art/shaders/painted.gdshader`: see 0.3. Uniforms: `base_color`, `noise_tex`, `spec_strength`,
`rim_color`, `rim_strength`, `crack_strength`, `crack_color`, `crack_speed`, `damage`; instance uniforms `ao_bottom`, `ao_height`.
### 5.2 `art/shaders/banner.gdshader` (cloth)
| Uniform | Fire | Dusk |
|---|---|---|
| `cloth_color` | `(0.85, 0.30, 0.12)` | `(0.25, 0.12, 0.38)` |
| `stripe_color` (a band at `UV.y` 0.52-0.62 and the bottom 0.08) | `(0.55, 0.08, 0.05)` | `(0.55, 0.52, 0.66)` |
| `glyph_color` (emission 0.6) | `(1.0, 0.75, 0.30)` | `(0.70, 0.30, 1.00)` |
| Glyph (UV.y 0 = top, fixed edge) | a flame: pixels where `UV.y in [0.18, 0.46]` and `abs(UV.x - 0.5) < (UV.y - 0.18) * 0.9` | a diamond: `abs(UV.x - 0.5) + abs(UV.y - 0.32) * 0.5 < 0.14` |
| `amplitude` / `speed` | 0.14 m / 2.6 | 0.10 m / 1.8 |
- Vertex: `float w = UV.y; VERTEX.z += sin(TIME * speed + UV.y * 6.0 + phase) * amplitude * w; VERTEX.x += sin(TIME * speed * 0.37 + UV.y * 2.0) * amplitude * 0.4 * w;` with `instance uniform float phase` so the 4 banners don't wave in sync. `cull_disable`, two-sided; the toon ramp from 5.1 for lighting; tips end in **two points** (the bottom 12 % of the plane, `abs(UV.x - 0.5) < 0.12`, is discarded: a swallow-tail).
### 5.3 `art/shaders/rune_glow.gdshader` (all emissive parts)
`unshaded`; `uniform vec3 glow_color; uniform float energy; uniform float pulse_speed; uniform int rune_bands; uniform float boost;`
`float pulse = 0.75 + 0.25 * sin(TIME * pulse_speed); float band = rune_bands > 0 ? step(0.45, fract(UV.x * float(rune_bands))) : 1.0; ALBEDO = glow_color * 0.4; EMISSION = glow_color * energy * pulse * band * boost;`
| Part | `energy` | `pulse_speed` | `rune_bands` |
|---|---|---|---|
| Ember Heart, shard core | 4.0 | 4.2 (1.5 s) / 3.1 (2.0 s) | 0 |
| Ember crystals, soul lanterns, brazier coals, fin tips | 3.0 (fin tips 2.5) | 2.0 | 0 |
| Portcullis, gate slits | 2.0 / 2.5 | 1.0 | 0 |
| Rune ring | 3.0 | 1.3 | 12 (dashes = runes, the torus UV.x runs around) |
`boost` is 1.0 idle; the training pulse, the selection and the collapse use it (8.3, 8.5, 8.6).

## 6. Lights (2 OmniLight3D per keep, shadows **off** on both, `light_specular 0.2`)
| Keep | Light | Position | Colour | Energy | Range | Animation |
|---|---|---|---|---|---|---|
| Fire | `HeartLight` (courtyard) | (0, 6.5, 0) | `(1.00, 0.55, 0.20)` | 2.5 | 14 | Flicker: energy `2.5 * (0.9 + 0.1 * noise(TIME * 8))`, noise = a `FastNoiseLite` sampled in script, or `sin(t*8.1)*0.5 + sin(t*13.7)*0.5` |
| Fire | `GateLight` | (0, 2.2, -3.6) | `(1.00, 0.45, 0.10)` | 1.5 | 6 | Same flicker, x2 for 0.3 s on a training pulse |
| Dusk | `SpireLight` | (0, 7.0, 0) | `(0.60, 0.30, 1.00)` | 2.0 | 14 | Slow breath: `2.0 * (0.85 + 0.15 * sin(TIME * 2.1))` |
| Dusk | `GateLight` | (0, 2.5, -3.4) | `(0.70, 0.30, 1.00)` | 1.2 | 6 | Same breath, x2 for 0.3 s on a training pulse |
No SpotLights, no shadowed lights (the sun does the shadows). The lights' `light_cull_mask` excludes nothing.

## 7. Particles (`GPUParticles3D`, all local coords, `fixed_fps 30`, `interpolate on`)
### 7.1 Fire Keep, idle (3 systems, 88 particles)
| System | Where | Amount | Lifetime | Emission shape | Velocity | Size (start -> end) | Colour ramp (alpha) | Blend |
|---|---|---|---|---|---|---|---|---|
| `BrazierFire` (ONE system for the 4 braziers: `emission_shape POINTS`, 4 points at the coal positions, `emission_point_count 4`) | coals (+-2.45, 2.25, +-2.45) | 48 | 0.7 | points | up 1.4 +-0.4, spread 12° | 0.55 -> 0.12 | `(1.0, 0.92, 0.55)` -> `(1.0, 0.50, 0.10)` at 0.4 -> `(0.55, 0.08, 0.0)` at 0.8 -> alpha 0 | ADD |
| `Embers` | box 4 x 1 x 4 at (0, 6.5, 0) | 24 | 3.0 | box | up 0.6-1.2, spread 45°, turbulence on (strength 0.3, scale 1.0) | 0.09 -> 0.05 | `(1.0, 0.65, 0.20)` alpha 1 -> 0 | ADD |
| `SpireSmoke` | sphere r 0.3 at (0, 14.8, 0) | 16 | 4.0 | sphere | up 0.8, wind +x 0.2 | 0.5 -> 1.8 | `(0.28, 0.22, 0.20)` alpha 0.35 -> 0 | MIX |
### 7.2 Dusk Keep, idle (3 systems, 84 particles)
| System | Where | Amount | Lifetime | Emission shape | Velocity | Size | Colour ramp | Blend |
|---|---|---|---|---|---|---|---|---|
| `VoidMotes` | ring r 3.0, inner r 2.0, at (0, 1.0, 0) | 50 | 5.0 | ring (axis y) | up 0.3-0.6, `orbit_velocity 0.12` (slow spiral), no gravity | 0.07 -> 0.04 | `(0.70, 0.30, 1.00)` -> `(0.30, 0.10, 0.50)` at 0.7 -> alpha 0 | ADD |
| `GroundMist` | ring r 3.2, inner r 1.5, at (0, 0.35, 0) | 14 | 6.0 | ring | outward 0.2, no gravity | 1.2 -> 2.4 | `(0.25, 0.12, 0.38)` alpha 0 -> 0.30 at 0.3 -> 0 | MIX, `sorting_offset` so it draws over the decal |
| `ShardSparks` | sphere r 0.4 at the shard (child of the shard node) | 20 | 1.2 | sphere | outward 0.3, gravity -0.8 (they fall a little) | 0.05 -> 0.02 | `(0.90, 0.60, 1.00)` -> alpha 0 | ADD |
### 7.3 State particles (both keeps, spawned once, `emitting` toggled; see 8)
| System | Amount | Lifetime | Size | Colour | Used by |
|---|---|---|---|---|---|
| `Smoke1`, `Smoke2` (columns) | 30 each | 3.5 | 0.7 -> 2.6 | `(0.16, 0.14, 0.13)` (Dusk `(0.12, 0.09, 0.16)`) alpha 0.55 -> 0 | damaged < 50 % |
| `Blaze1`, `Blaze2` (fire plumes; Dusk: `Rift1`, `Rift2` purple flames, same numbers, colour `(0.8, 0.4, 1.0)` -> `(0.3, 0.1, 0.5)`) | 24 each | 1.0 | 0.9 -> 0.3 | fire ramp from 7.1 | damaged < 25 % |
| `TrainBurst` (one-shot, `explosiveness 1.0`) | 24 | 0.8 | 0.15 -> 0.05 | glow colour | training pulse |
| `BuildRing` (construction) | 40 | 1.2 | 0.12 -> 0.04 | team colour, ADD | construction |
| `CollapseDust` (one-shot) | 60 | 2.5 | 1.0 -> 3.0 | stone colour x 0.8, alpha 0.6 -> 0 | destroyed |
Totals: idle 84-88 per keep; worst case (25 % HP) idle + 60 + 48 = **~200**; destroyed peak ~260 for 2.5 s.

## 8. Animation and states (hooks on the scene root script; who calls them is in 8.7)
### 8.1 Idle (every frame, one `_process`, no allocations)
| Keep | What moves |
|---|---|
| Fire | Ring rotates +12°/s and bobs `0.2 * sin(t * 2.09)`; each crystal spins 45°/s; banners wave (shader); braziers flicker (light + particles); Ember Heart pulse (shader); crack veins pulse (shader) |
| Dusk | Shard bobs `0.3 * sin(t * 1.57)` and spins -20°/s; rune ring rotates -8°/s; soul lantern orbs bob `0.1 * sin(t * 2.5 + i)`; banners wave; light breathes; motes spiral |
### 8.2 Construction: `set_construction_progress(p: float)` (0..1, called whenever progress changes)
The keep is not buildable in the 1v1, but 3.V2 builds this anyway (campaign, and the same recipe serves every future building).
| Progress | Look |
|---|---|
| p = 0 | Only the **glowing outline**: a flat emissive quad ring (6.4 x 6.4 outer, 0.2 m thick, `rune_glow` team glow colour, energy 2.0, pulse 1.0 s) at y 0.05, plus the contact decal, plus `BuildRing` particles emitting along the outline. Every other part hidden |
| 0 < p < 1 | Parts appear **from the ground up**: a part whose bottom is at height `b` and top at `t` (total height H = 14.8 / 17.5) is hidden while `p * H < b`, then scales `scale.y` from 0.05 to 1 (pivot at its bottom: shift the mesh so its origin is its base, or wrap it in a Node3D at the base) as `p * H` goes from `b` to `t`, and gets `rim_strength 1.0` team glow for the 0.3 s after it finishes rising. Floating parts (ring, crystals, shard, rune ring) appear at p >= 0.95 with a 0.5 s scale-in. Lights: energy x p. Idle particles off until p = 1 |
| p = 1 | Outline fades out over 0.5 s, `BuildRing` stops, idle particles start, a one-shot `TrainBurst`-style flash (team colour, 40 particles) from the top |
Building must **not** scale `_visual` or fade materials when a model scene handles progress (see 8.7).
### 8.3 Training pulse: `play_training_pulse()` (called when a unit pops out)
0.6 s: gate glow (`boost`) 1 -> 3.0 at 0.1 s -> 1.0 at 0.6 s (ease out); `GateLight` energy x2 for 0.3 s; `TrainBurst`
one-shot from the gate centre (0, 2.0, -2.8), velocity outward -Z 2-4 m/s, spread 60°. Crystal ring / rune ring
speed x3 for 0.6 s. Re-triggering during a pulse restarts it.
### 8.4 Damage: `set_health_ratio(r: float)` (0..1, called on every HP change)
| HP | Fire Keep | Dusk Keep |
|---|---|---|
| r >= 0.5 | idle; shader `damage = (1 - r) * 0.5` (a little soot from the first hit) | same |
| r < 0.5 | `Smoke1` at (-1.8, 5.2, 1.6) and `Smoke2` at (1.9, 8.0, -0.6) emit; `damage 0.6`; one corner tower cap (part 7, instance 2) hidden and 4 rubble cubes appear on that corner (`Rubble2` MultiMesh, visible = true); crystal ring speed 6°/s (limps) | `Smoke1` at (-1.6, 6.5, 1.2), `Smoke2` at (1.4, 10.5, -0.8); `damage 0.6`; two fins (instances 1, 4) hidden, their tip glows off, `Rubble2` shards visible; rune ring speed -3°/s and its `energy` 1.5 (dimmer) |
| r < 0.25 | + `Blaze1` at (-1.5, 5.5, -1.2), `Blaze2` at (0.8, 10.5, 0.9); `damage 1.0` (cracks widen, walls dim 35 %); `HeartLight` flicker amplitude x3 (0.7-1.0); one crystal falls (instance 1 hidden), banners on the gate face hidden | + `Rift1` (-1.2, 7.0, 1.4), `Rift2` (0.6, 12.0, -0.8); `damage 1.0`; shard bob amplitude 0.6 and spin 60°/s (agitated); `SpireLight` breath 0.5-1.0 fast (4 Hz); one banner hidden |
Healing back above a threshold reverts it (caps and fins reappear, particles stop). Thresholds have **no hysteresis**; that's fine because HP changes in steps.
### 8.5 Destroyed: `play_destroyed()` (3.0 s, then the wreck stays; `Building` frees the node at `FREE_DELAY` 5.0 s)
| Time | Fire Keep | Dusk Keep |
|---|---|---|
| 0.0 | All idle particles stop; `Blaze1/2`, `Smoke1/2` keep emitting; lights: `HeartLight` energy 6 for 0.15 s (flash) | Same; `SpireLight` flashes 6 |
| 0.0-0.6 | Ember Heart and crystals: emission `boost` 3, the ring rises 1.5 m and shakes (+-0.15 m at 20 Hz) | Shard core `boost` 4, the shard rises 2 m, spins 180°/s |
| 0.6 | Crystals **burst**: hidden + one-shot `TrainBurst` x3 (72 sparks, fire ramp) at the ring; Ember Heart hidden | Shard bursts the same way (purple); rune ring hidden |
| 0.6-1.4 | Spire tilts 35° about x toward -Z and drops 6 m (`Tween`, `EASE_IN`), passes through the donjon (no collision, it's a show), then hidden; `CollapseDust` fires at the donjon top | Prisms 2-3 and the tip tilt 30° the other way (+Z) and drop 8 m, hidden at 1.4; `CollapseDust` at the body cap |
| 1.0-2.2 | Donjon and towers `scale.y` 1 -> 0.25 with a **rumble** (position x/z jitter +-0.08 m at 15 Hz); caps, horns, merlons, banners hidden at 1.6; `CollapseDust` second burst at 1.6 at the plinth | Body and fins `scale.y` 1 -> 0.3 with rumble; fins tilt outward to 45°; banners, lanterns hidden at 1.6; second dust at 1.6 |
| 2.2-3.0 | Lights fade to 0.4 energy (embers); walls hold at 0.25 scale, `damage 1.0`, `rubble` MultiMesh scaled 1.6 (more debris); `Smoke1/2` keep emitting until freed; the contact decal darkens to alpha 0.9 (scorch) | Lights fade to 0.3; `GroundMist` amount doubles (a second mist emitter kept for this) and it stays; the decal turns purple-black alpha 0.8 |
The wreck (plinth + stubs + smoke) is what the enemy sees for the last 2 s before `queue_free`.
`Building._collapse` must not tween the visual when the model has `play_destroyed` (8.7).
### 8.6 Selected: `set_selected(on: bool)`
On: every `painted` material instance of the keep gets `rim_color` = team colour, `rim_strength 0.9`, and every glow part
`boost 1.4`; over 0.15 s. Off: back over 0.25 s. The existing yellow ground ring from `Building` stays.
Use per-keep material duplicates (6 per keep, made once at `_ready`, no per-frame allocation); the two keeps
never share instances so selecting one never lights the other.
### 8.7 Team colour: `set_team_color(c: Color)`
Sets `cloth_color` on the banners, the cap / roof material base, the ring / lantern glow colours (`glow_color = c.lightened(0.35)`),
`BuildRing` and `TrainBurst` ramps, and the selection rim. Default = the kingdom colour of the scene (Fire / Shadow). Needed for
PvP mirror matches later; 3.S1 calls it once at spawn with `team_color`.
### 8.8 Who calls what (handoff for 3.S1, systems coder; the tech-artist writes it in `docs/handoff/for-systems-coder.md`)
| Hook | Caller | When |
|---|---|---|
| `set_team_color(team_color)` | `Building._build_visual` right after `instantiate()` | once |
| `set_construction_progress(_progress)` | `Building._update_look` | when a site's progress or completion changes; and **skip** the `_visual.scale.y` / alpha code when the model has this method |
| `set_health_ratio(hp / max_hp)` | `Building.take_damage` / heal | every change |
| `play_training_pulse()` | `TrainingBuilding` on `unit_trained` | each unit |
| `play_destroyed()` | `Building._collapse` instead of its tween when the model has this method; keep `FREE_DELAY` 5.0 | once |
| `set_selected(on)` | `Building._on_selected_changed` | on change |
| `rotation.y` of the instance | `Building._build_visual`: `-PI/2` for `fire_keep`, `+PI/2` for `shadow_keep` (gate toward the map centre) | once |
All hooks must be safe to call before `_ready` finishes (cache the value, apply in `_ready`).

## 9. Performance budget (one keep; the base has two keeps only in PvP mirror tests, normally one per side)
| Item | Budget per keep | Notes |
|---|---|---|
| Draw calls (mesh instances incl. MultiMesh + particles + decal) | **<= 32 idle, <= 40 at 25 % HP** | Measured with `Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME` with and without the keep |
| Materials | **<= 8** unique per keep (6 listed + 2 particle materials), duplicated once per keep for the selection rim | No `material_override` created per frame |
| Vertices | <= 12 000 | Cylinders 6-8 segments, spheres `radial 12 / rings 6`, banners 3 x 12 subdivisions |
| Lights | **2 OmniLight3D, shadows off** | The sun is the only shadow caster |
| Particles alive | <= 90 idle, <= 200 at 25 %, <= 260 for 2.5 s when destroyed | All `GPUParticles3D`, `fixed_fps 30` |
| CPU per frame (the root script) | < 0.05 ms; one `_process`, tweens only on state changes, no `get_node` in `_process` (cache `@onready`) | |
| Whole base (1 keep + 3 halls + 2 hearths + 4 towers placeholders) | <= 60 draw calls from buildings | Placeholders are 2 calls each |
| Frame rate check | Windowed 1920 x 1080, zoom 40 over a keep with a full base and 60 units: **>= 60 fps** on the user's PC (`Engine.get_frames_per_second()` printed by the test scene) | |
| Headless | `tests/perf_test.gd` still prints `PERF OK`; the keep scenes must instantiate headless without errors (particles and shaders included) | |

## 10. ASCII views (not to scale: 1 column ~ 0.4 m, 1 row ~ 0.7 m)
### 10.1 Fire Keep, side view from the gate (-Z)
```
                     *              14.35  Ember Heart (glow, pulses)
                    /^\             10.4-14.6  jagged obsidian spire, lava veins
           o       / ^ \       o    11.5  three ember crystals orbit (r 2.6)
                  /  ^  \
                 [n n n n]          10.2-11.0  donjon ledge + merlons
                 |       |
      /\         |donjon |         /\      7.9-9.7  tower caps (team colour) + bronze horns
     /  \        |       |        /  \
    | T  |  n n n|n n n n|n n n  | T  |    5.0-5.9  bronze parapet + merlons
    | o  |  ===========|=========| o  |   4.6  banners hang below the parapet
    | w  |  | ]|     ___    |[ | | w  |
    | e  |  | ]| wall| ||| | |[ | | e  |    1.0-5.0  wall block, cracks glow
    | r  |  |  |     | ||| |  | | | r  |    1.0-3.6  gate: dark recess, glowing portcullis, bronze lintel
   _|__(O)__|__|_____|_|||_|__|_|_(O)_|_   2.2  braziers with flames on the plinth corners
  [==================================]     0-1.0  two-step dark plinth (6.4 m), rubble around
```
### 10.2 Fire Keep, top view (gate at the bottom = -Z)
```
   +----------------------------------+   6.4 x 6.4 plinth; dashed 6 x 6 footprint inside
   | (T) O   [banner]        O (T)   |   T corner towers r 0.9 at (+-2.6, +-2.6), O braziers
   |   +------------------------+    |
   | [ |     .  o  .           | ]   |   . o . crystal orbit r 2.6, y 11.5
   | b |   .   +-----+   .     | b   |   +-----+ donjon 2.8 x 2.8, spire above it
   | a |   o   |  ^  |   o     | a   |
   | n |   .   +-----+   .     | n   |
   | ] |     .  o  .           | [   |
   |   +--------[GATE]---------+     |   gate on -Z: recess 2.0 wide, 5 glowing bars, 2 banners at x +-1.7
   | (T) O                   O (T)   |
   +----------------------------------+   contact decal 8 x 8 under everything
```
### 10.3 Dusk Keep, side view from the gate (-Z)
```
                      ^              17.5  Dusk Eye: floating black shard, purple core, bobs and spins
                     < >             16.5
                      v
                     /|\             13.7-15.5  tip
                    / | \            11.2-13.7  prism 3 (twist 40 deg)
                   /  |  \
                  /___|___\          8.7-11.2  prism 2 (twist 20 deg)
      *          /    |    \          *       fin tips glow (6)
       \        /_____|_____\        /        6.2-8.7  prism 1
        \      [=============]      /         6.4  silver body cap, fins lean out 20 deg from y 6 to 9.8
         \     |  = rune ring =|   /          6.9  floating torus with 12 glowing runes, rotates
          \    |    body       |  /
           \   | ]   /\    [   | /            1.2-6.2  hex body, shadow veins
            \  | ] o | | o [   |/             2.7  soul lantern orbs bob (3, between the banners)
             \ | ]   |||   [   |              1.2-4.85  pointed gate: black arch, 2 purple slits, silver frame
   ~ ~ ~ ~ ~ [=======|||=======] ~ ~ ~ ~ ~    0-1.2  two-step hex plinth, mist crawls, shard rubble
```
### 10.4 Dusk Keep, top view (gate at the bottom = -Z)
```
              _______                 hex plinth r 3.3 (corners), 6 x 6 footprint dashed inside
           * /       \ *              * fin tips at r ~4.0 (6, one per hex corner)
            / [ban]   \               3 banners on alternating flat faces (60, 180, 300 deg)
       o   /   _____   \   o          o soul lanterns on the other faces (0, 120, 240 deg)
          |   /     \   |
      [ban|  |  (^)  |  |ban]         (^) spire + shard above the centre; rune ring r 3.1 around
          |   \_____/   |
       *   \           /   *
            \  ||||   /               gate slits on the -Z face
             \_______/
           *     o     *              contact decal + mist ring r 3.2 under everything
```

## 11. Done when
### 3.V1 (build both keeps)
- [ ] `art/buildings/fire_keep.tscn` and `art/buildings/dusk_keep.tscn` exist, root `Node3D` with a script exposing every hook in 8.8 (stubs allowed for the 3.V2 states), footprint-neutral (no collision), gate on local -Z.
- [ ] Every part in sections 3 and 4 is present at the listed size and position (+-0.1 m), with the listed material; the three shaders of section 5 exist in `art/shaders/` and every opaque part uses `painted.gdshader` with the height gradient, contact band, toon ramp and rim from 0.3.
- [ ] `art/environment/world_env.tres` matches 0.4 and the lead has plugged it into `scenes/main.tscn`; the glow halos are visible on the Ember Heart / shard core at zoom 40.
- [ ] Idle animation (8.1), the two lights (6) and the idle particles (7.1 / 7.2) run; nothing allocates per frame.
- [ ] Screenshots in `docs/art/screens/`: `fire_keep_z15.png`, `fire_keep_z40.png`, `dusk_keep_z15.png`, `dusk_keep_z40.png`, from the game camera (pitch 55°, zoom 15 and 40, keep in the upper third of the frame at zoom 15), plus `keeps_silhouette.png` (both keeps unlit black on white). The tech-artist looked at them and they read as "epic": full pyramid / needle silhouette at 40 m, 2-4 glowing points, visible motion, no floating gaps, no z-fighting.
- [ ] Budget (9): <= 32 draw calls per keep idle, <= 8 materials, 2 lights, <= 90 particles; windowed test scene prints >= 60 fps at zoom 40 with a full placeholder base and 60 units; headless `--import` clean and `tests/perf_test.gd` prints `PERF OK`.
### 3.V2 (states)
- [ ] `set_construction_progress`: outline only at 0, parts rise from the ground in height order, floating parts at >= 0.95, flash at 1; the site fits `Building` without the old scale / alpha trick (8.7).
- [ ] `play_training_pulse`: gate flash + burst + ring speed-up, 0.6 s, safe to retrigger.
- [ ] `set_health_ratio`: the 0.5 and 0.25 looks of 8.4 (smoke columns, then fire / rifts, hidden cap / fins, rubble, dimming) and they revert when healed.
- [ ] `play_destroyed`: the 3.0 s sequence of 8.5 with those timings, ending in a smoking wreck that survives until `FREE_DELAY`; no errors if the node is freed mid-sequence.
- [ ] `set_selected`: team rim + glow boost on, off; `set_team_color` recolours banners, caps, glows and bursts.
- [ ] Screenshots `fire_keep_states.png` and `dusk_keep_states.png` (contact sheet: construction 50 %, idle, 40 % HP, 20 % HP, destroyed at 1.2 s, destroyed at 3 s) at zoom 30; particle peak <= 260, draw calls <= 40 at 25 % HP; perf test still `PERF OK`.
- [ ] `docs/handoff/for-systems-coder.md` lists the hooks of 8.8 for 3.S1.
### 3.S1 (systems, plug-in)
- [ ] `data/buildings/fire_keep.tres` / `shadow_keep.tres` point `model_scene` at the two scenes; the instance is rotated per section 2; every hook in 8.8 is called at the listed moment; the placeholder scale / alpha / collapse code is skipped when the model has the hook.
- [ ] A 1v1 match: the two keeps show construction-free idle at start, pulse on each worker, smoke under 50 %, collapse on death, and the match still ends by the `skirmish-1v1.md` rules.
