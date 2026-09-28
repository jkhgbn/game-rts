# Writes the four Ep4 memory moods (mood_<name>.tres, LightingPreset) for props/mood_zones.gd.
# Run: python art/cinematics/stage_sets/forge_ep4_memories/tools/make_moods.py   (from the project root)
import os
D = "art/cinematics/stage_sets/forge_ep4_memories/"

def c(t): return "Color(%g, %g, %g, 1)" % t

MOODS = {
  # H03: the year nothing grew. Blue hour after snowfall, a low peach sun behind the village (rim on the snow),
  # lavender shadows, the windows the only warm things.
  "winter": dict(top=(0.2, 0.26, 0.46), hor=(0.86, 0.7, 0.66), gb=(0.16, 0.17, 0.24), gh=(0.62, 0.6, 0.7), sun_ang=12,
    amb=0.62, exp=0.95, glow=0.7, gstr=1.0, thr=1.0, fog=(0.62, 0.64, 0.8), fd=0.012, fsky=0.35,
    con=1.12, sat=0.95, grad=[(0, (0.02, 0.025, 0.06)), (0.28, (0.18, 0.2, 0.33)), (0.64, (0.62, 0.64, 0.74)), (1, (1.0, 0.95, 0.9))],
    sun=(1.0, 0.72, 0.52), se=1.15, rot=(-12, 18, 0), sb=2.5, so=0.75, fill=(0.5, 0.58, 1.0), fe=0.45, frot=(-35, -160, 0),
    vc=(0.06, 0.06, 0.14), vs=0.55, vi=0.42, vo=1.1, hc=(0.8, 0.72, 0.8), hs=0.12, hh=0.3),
  # H04: the same place in spring. Golden morning, saturated greens, pollen in the backlight.
  "spring": dict(top=(0.28, 0.52, 0.9), hor=(0.96, 0.9, 0.74), gb=(0.16, 0.2, 0.1), gh=(0.62, 0.68, 0.46), sun_ang=14,
    amb=0.5, exp=1.0, glow=0.75, gstr=1.0, thr=1.0, fog=(0.98, 0.92, 0.78), fd=0.007, fsky=0.25,
    con=1.12, sat=1.12, grad=[(0, (0.03, 0.03, 0.02)), (0.28, (0.22, 0.21, 0.15)), (0.64, (0.7, 0.66, 0.52)), (1, (1.0, 0.97, 0.86))],
    sun=(1.0, 0.82, 0.55), se=1.85, rot=(-16, 18, 0), sb=2.0, so=0.8, fill=(0.7, 0.76, 0.95), fe=0.28, frot=(-35, -160, 0),
    vc=(0.1, 0.07, 0.03), vs=0.45, vi=0.45, vo=1.12, hc=(1.0, 0.92, 0.72), hs=0.1, hh=0.3),
  # H05: the frost clearing before sunrise. Cold blue air, a thin rose-gold dawn on the horizon; the Master's burning
  # hem is the one warm light (props: emissive), the child's hands and the rimed sapling catch the cold key.
  "frost": dict(top=(0.1, 0.16, 0.36), hor=(0.84, 0.62, 0.58), gb=(0.08, 0.1, 0.18), gh=(0.46, 0.5, 0.66), sun_ang=10,
    amb=0.6, exp=0.95, glow=0.8, gstr=1.05, thr=0.95, fog=(0.46, 0.54, 0.76), fd=0.02, fsky=0.3,
    con=1.14, sat=1.0, grad=[(0, (0.01, 0.02, 0.06)), (0.28, (0.13, 0.17, 0.3)), (0.64, (0.56, 0.6, 0.72)), (1, (1.0, 0.94, 0.9))],
    sun=(0.96, 0.78, 0.74), se=0.9, rot=(-10, -60, 0), sb=2.5, so=0.7, fill=(0.46, 0.6, 1.0), fe=0.55, frot=(-30, 150, 0),
    vc=(0.02, 0.03, 0.1), vs=0.62, vi=0.4, vo=1.08, hc=(0.6, 0.66, 0.86), hs=0.1, hh=0.28),
  # H08 / H09: the burned wood under frost. Steel-blue and black, a pale winter sun low behind the trunks (silhouettes,
  # long shadows over the rime), blue fog between the trunks; no green or brown in the grade so Ysolde's green and the
  # shoot are the only colour.
  "ash": dict(top=(0.26, 0.32, 0.46), hor=(0.9, 0.84, 0.78), gb=(0.06, 0.07, 0.1), gh=(0.44, 0.46, 0.54), sun_ang=8,
    amb=0.38, exp=0.95, glow=0.45, gstr=0.9, thr=1.2, fog=(0.52, 0.56, 0.66), fd=0.013, fsky=0.2,
    con=1.2, sat=0.78, grad=[(0, (0.01, 0.012, 0.022)), (0.3, (0.14, 0.16, 0.22)), (0.66, (0.58, 0.62, 0.7)), (1, (0.98, 0.99, 1.0))],
    sun=(1.0, 0.9, 0.8), se=1.4, rot=(-13, -143, 0), sb=2.0, so=0.85, fill=(0.5, 0.6, 0.9), fe=0.3, frot=(-30, 37, 0),
    vc=(0.02, 0.025, 0.05), vs=0.6, vi=0.42, vo=1.08, hc=(0.7, 0.74, 0.82), hs=0.1, hh=0.3),
}

for name, m in MOODS.items():
    offs = ", ".join("%g" % g[0] for g in m["grad"])
    cols = ", ".join("%g, %g, %g, 1" % g[1] for g in m["grad"])
    s = f'''[gd_resource type="Resource" script_class="LightingPreset" load_steps=7 format=3]

[ext_resource type="Script" path="res://art/environment/lighting/lighting_preset.gd" id="1_mood"]

[sub_resource type="ProceduralSkyMaterial" id="Sky_{name}_mat"]
sky_top_color = {c(m["top"])}
sky_horizon_color = {c(m["hor"])}
ground_bottom_color = {c(m["gb"])}
ground_horizon_color = {c(m["gh"])}
sun_angle_max = {m["sun_ang"]}.0

[sub_resource type="Sky" id="Sky_{name}"]
sky_material = SubResource("Sky_{name}_mat")

[sub_resource type="Gradient" id="Grad_{name}"]
offsets = PackedFloat32Array({offs})
colors = PackedColorArray({cols})

[sub_resource type="GradientTexture1D" id="GradTex_{name}"]
gradient = SubResource("Grad_{name}")
width = 256

[sub_resource type="Environment" id="Env_{name}"]
background_mode = 2
sky = SubResource("Sky_{name}")
ambient_light_source = 3
ambient_light_energy = {m["amb"]}
tonemap_mode = 2
tonemap_exposure = {m["exp"]}
glow_enabled = true
glow_intensity = {m["glow"]}
glow_strength = {m["gstr"]}
glow_bloom = 0.0
glow_hdr_threshold = {m["thr"]}
fog_enabled = true
fog_light_color = {c(m["fog"])}
fog_density = {m["fd"]}
fog_sky_affect = {m["fsky"]}
adjustment_enabled = true
adjustment_brightness = 1.0
adjustment_contrast = {m["con"]}
adjustment_saturation = {m["sat"]}
adjustment_color_correction = SubResource("GradTex_{name}")

[resource]
script = ExtResource("1_mood")
environment = SubResource("Env_{name}")
sun_color = {c(m["sun"])}
sun_energy = {m["se"]}
sun_rotation_degrees = Vector3({m["rot"][0]}, {m["rot"][1]}, {m["rot"][2]})
shadow_blur = {m["sb"]}
shadow_opacity = {m["so"]}
fill_color = {c(m["fill"])}
fill_energy = {m["fe"]}
fill_rotation_degrees = Vector3({m["frot"][0]}, {m["frot"][1]}, {m["frot"][2]})
vignette_color = {c(m["vc"])}
vignette_strength = {m["vs"]}
vignette_inner = {m["vi"]}
vignette_outer = {m["vo"]}
haze_color = {c(m["hc"])}
haze_strength = {m["hs"]}
haze_height = {m["hh"]}
'''
    open(os.path.join(D, "mood_%s.tres" % name), "w", newline="\n").write(s)
    print("wrote", name)
