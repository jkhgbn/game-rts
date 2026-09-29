"""Builds prologue_castle.blend: the Master's citadel (World Forge set `forge_citadel`) as a 30-second film.

Reproducible, headless:
    "C:\\Program Files\\Blender Foundation\\Blender 5.2\\blender.exe" --background --factory-startup ^
        --python art\\blender\\prologue_castle\\build_castle.py
Inputs (this folder): export/citadel.glb + export/dragon_*.glb + export/materials.json (made by the Godot tool
tools/blender_export_citadel.gd), narration.wav + bell.wav + narration_timing.json (make_narration.py), script.md
(the shot list this file implements: SHOTS below).
Output: prologue_castle.blend (scene "Citadel" = the 3D film, scene "Film" = the edit: picture + sound + title).
Rendering: render_castle.py (stills of every shot, the film).

Blender coordinates, Z up (Godot (x, y, z) -> Blender (x, -z, y)); -Y = south = the gate and the bridge.
"""
import bpy
import bmesh
import colorsys
import json
import math
import os
import sys
import time

import numpy as np
from mathutils import Euler, Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
EXPORT = os.path.join(HERE, "export")
BLEND = os.path.join(HERE, "prologue_castle.blend")
FPS = 24
LENGTH = 30.0
FRAMES = int(round(LENGTH * FPS))          # 720
RES = (1920, 804)                          # 2.39:1 scope
SUN_AZIMUTH = math.radians(243.0)          # towards the sun, clockwise from +Y (north): WSW
LOG = []


def log(*a):
    s = " ".join(str(x) for x in a)
    LOG.append(s)
    print("[castle]", s, flush=True)


def f_of(t: float) -> int:
    """Seconds -> frame number (frame 1 = t 0)."""
    return int(round(t * FPS)) + 1


# ============================================================================================ the shot list
# Times in seconds (cuts sit on the narration's pauses, narration_timing.json). Camera positions / targets in metres.
# lens in mm (36 mm sensor, horizontal fit). fstop None = no DOF. focus: "target" (the look target) or a point.
SHOTS = [
    # establishing: high from the south-east, descending; side-lit, the sun's glow on the left of frame
    dict(id="SH01", t0=0.00, t1=4.50, lens=(24, 27), cam=((95, -190, 150), (62, -140, 86)),
         look=((0, 0, 95), (0, 0, 62)), fstop=None, ease=(0.0, 0.6), fade_in=0.6, shake=0.0),
    # the colossal Master in silhouette: the camera slides past him and the sun comes out from behind his head
    dict(id="SH02", t0=4.50, t1=6.30, lens=(22, 22), cam=((46, -78, 34.0), (40, -95, 35.5)),
         look=((0, -106, 44.0), (0, -106, 45.0)), fstop=2.8, focus=(0, -106, 45), ease=(0.15, 0.15), shake=0.03),
    # the great bell, side-backlit, beside the belfry at its own height; it strikes at 7.0 s
    dict(id="SH03", t0=6.30, t1=8.50, lens=(40, 40), cam=((15.4, -46.8, 44.4), (14.1, -44.5, 45.0)),
         look=((9.5, -36.2, 49.2), (9.5, -36.2, 49.3)), fstop=2.0, focus=(9.5, -36.2, 49.0), ease=(0.3, 0.3), shake=0.015),
    # the Great Bridge from the west, sun behind the camera: gold light, long shadows; an elder glides under it
    dict(id="SH04", t0=8.50, t1=10.33, lens=(28, 28), cam=((-58, -172, 74), (-46, -126, 66)),
         look=((0, -120, 33), (0, -88, 37)), fstop=None, ease=(0.1, 0.1), shake=0.02),
    # the gate beyond a flaring brazier, low; push in
    dict(id="SH05", t0=10.33, t1=12.00, lens=(28, 28), cam=((0, -84, 31.8), (0, -77, 32.2)),
         look=((0, -64, 35.6), (0, -64, 36.2)), fstop=4.0, focus=(0, -69.2, 33), ease=(0.1, 0.4), shake=0.02),
    # crane down onto the kings' long table in the market
    dict(id="SH06", t0=12.00, t1=15.00, lens=(35, 38), cam=((-24, -76, 54), (-8.5, -62.0, 37.8)),
         look=((-12.5, -47.2, 31.5), (-12.5, -47.2, 31.3)), fstop=2.8, focus="target", ease=(0.3, 0.6), shake=0.02),
    # behind the Master at the orrery: four flames orbit his hand
    dict(id="SH07", t0=15.00, t1=17.00, lens=(32, 32), cam=((-13, -4.4, 50.5), (-13, -2.6, 50.3)),
         look=((-13, 4, 50.8), (-13, 4, 50.8)), fstop=1.8, focus=(-13, 1.4, 50.8), ease=(0.2, 0.2), shake=0.01),
    # high over the summit: the four keeps, each with its kingdom's small crown-fire
    dict(id="SH08", t0=17.00, t1=19.25, lens=(24, 24), cam=((26, -52, 112), (38, -30, 114)),
         look=((0, 0, 46), (0, 0, 46)), fstop=None, ease=(0.2, 0.2), shake=0.0),
    # the four beams, one per word
    dict(id="SH09a", t0=19.25, t1=20.17, lens=(28, 28), cam=((36, -52, 42), (34, -49, 42.5)),
         look=((17.2, -24.6, 62), (17.2, -24.6, 62)), fstop=None, ease=(0.0, 0.3), shake=0.03),
    dict(id="SH09b", t0=20.17, t1=21.08, lens=(28, 28), cam=((-36, -52, 42), (-34, -49, 42.5)),
         look=((-17.2, -24.6, 62), (-17.2, -24.6, 62)), fstop=None, ease=(0.0, 0.3), shake=0.03),
    dict(id="SH09c", t0=21.08, t1=22.15, lens=(28, 28), cam=((36, 52, 42), (34, 49, 42.5)),
         look=((17.2, 24.6, 62), (17.2, 24.6, 62)), fstop=None, ease=(0.0, 0.3), shake=0.03),
    dict(id="SH09d", t0=22.15, t1=23.10, lens=(28, 28), cam=((-36, 52, 42), (-34, 49, 42.5)),
         look=((-17.2, 24.6, 62), (-17.2, 24.6, 62)), fstop=None, ease=(0.0, 0.3), shake=0.03),
    # the empty throne under four coloured shafts; they die on "empty"
    dict(id="SH10", t0=23.10, t1=26.90, lens=(35, 35), cam=((0, -25, 51.0), (0, -17.5, 50.2)),
         look=((0, -6.8, 50.0), (0, -6.8, 49.8)), fstop=2.0, focus=(0, -6.8, 49.4), ease=(0.2, 0.2), shake=0.01),
    # blue hour: crane up and out, the dragons leave
    dict(id="SH11", t0=26.90, t1=30.00, lens=(30, 22), cam=((0, -34, 62), (0, -165, 122)),
         look=((0, -2, 50), (0, 10, 92)), fstop=None, ease=(0.5, 0.0), fade_out=0.8, shake=0.0),
]
SHOT = {s["id"]: s for s in SHOTS}


# ============================================================================================ node helpers
def N(nt, t, x=0, y=0, i=None, **props):
    n = nt.nodes.new(t)
    n.location = (x, y)
    for k, v in props.items():
        setattr(n, k, v)
    for k, v in (i or {}).items():
        sock = n.inputs[k] if isinstance(k, int) else n.inputs.get(k)
        if sock is None:
            raise KeyError(f"{t}: no input {k} in {[s.name for s in n.inputs]}")
        sock.default_value = v
    return n


def L(nt, a, b):
    nt.links.new(a, b)


def out(n, name=0):
    return n.outputs[name] if isinstance(name, int) else n.outputs[name]


def math_node(nt, op, a, b=None, x=0, y=0, clamp=False):
    n = N(nt, "ShaderNodeMath", x, y, operation=op, use_clamp=clamp)
    for k, v in enumerate((a, b)):
        if v is None:
            continue
        if isinstance(v, (int, float)):
            n.inputs[k].default_value = v
        else:
            L(nt, v, n.inputs[k])
    return n.outputs[0]


def mix_col(nt, fac, a, b, blend="MIX", x=0, y=0):
    n = N(nt, "ShaderNodeMix", x, y, data_type="RGBA", blend_type=blend)
    for sock, v in ((n.inputs[0], fac), (n.inputs[6], a), (n.inputs[7], b)):
        if isinstance(v, (int, float)):
            sock.default_value = v
        elif isinstance(v, tuple):
            sock.default_value = v if len(v) == 4 else (*v, 1.0)
        else:
            L(nt, v, sock)
    return n.outputs[2]


def ramp(nt, fac, stops, x=0, y=0):
    """stops: [(pos, (r,g,b,a) or value)]"""
    n = N(nt, "ShaderNodeValToRGB", x, y)
    L(nt, fac, n.inputs[0])
    els = n.color_ramp.elements
    while len(els) > 1:
        els.remove(els[-1])
    for k, (p, c) in enumerate(stops):
        e = els[0] if k == 0 else els.new(p)
        e.position = p
        e.color = c if isinstance(c, tuple) and len(c) == 4 else ((*c, 1.0) if isinstance(c, tuple) else (c, c, c, 1.0))
    return n.outputs[0]


def new_mat(name, method="DITHERED"):
    m = bpy.data.materials.get(name)
    if m:
        bpy.data.materials.remove(m)
    m = bpy.data.materials.new(name)
    try:
        m.use_nodes = True
    except Exception:
        pass
    m.node_tree.nodes.clear()
    m.surface_render_method = method
    return m, m.node_tree


def principled(nt, x=300, y=0, **inputs):
    p = N(nt, "ShaderNodeBsdfPrincipled", x, y)
    for k, v in inputs.items():
        name = k.replace("_", " ")
        s = p.inputs.get(name)
        if s is None:
            raise KeyError(f"Principled has no {name}")
        if isinstance(v, (int, float, tuple)):
            s.default_value = v if not (isinstance(v, tuple) and len(v) == 3 and s.type == "RGBA") else (*v, 1.0)
        else:
            L(nt, v, s)
    return p


def mat_out(nt, shader, x=700, y=0, volume=None, disp=None):
    o = N(nt, "ShaderNodeOutputMaterial", x, y)
    if shader is not None:
        L(nt, shader, o.inputs["Surface"])
    if volume is not None:
        L(nt, volume, o.inputs["Volume"])
    if disp is not None:
        L(nt, disp, o.inputs["Displacement"])
    return o


def vcol(nt, x=-900, y=0):
    n = N(nt, "ShaderNodeVertexColor", x, y)
    n.layer_name = "Color"
    return n.outputs["Color"]


def drv_value(nt, prop, x=-900, y=-400, scale=1.0, name=None):
    """A Value node driven by the scene custom property `prop` (the film's global light cues)."""
    v = N(nt, "ShaderNodeValue", x, y)
    v.label = name or prop
    d = v.outputs[0].driver_add("default_value").driver
    d.type = "SCRIPTED"
    var = d.variables.new()
    var.name = "p"
    var.targets[0].id_type = "SCENE"
    var.targets[0].id = bpy.data.scenes["Citadel"]
    var.targets[0].data_path = f'["{prop}"]'
    d.expression = f"p*{scale}" if scale != 1.0 else "p"
    return v.outputs[0]


# ---------------------------------------------------------------------------------------- shared node groups
def group_tribrick():
    """Triplanar brick pattern in world metres: Mortar (1 = joint), Var (0..1 per block), Rows (0..1 inside a row)."""
    g = bpy.data.node_groups.get("TriBrick")
    if g:
        return g
    g = bpy.data.node_groups.new("TriBrick", "ShaderNodeTree")
    for nm, tp, dv in (("Width", "NodeSocketFloat", 0.8), ("Height", "NodeSocketFloat", 0.4),
                       ("Mortar", "NodeSocketFloat", 0.03), ("Scale", "NodeSocketFloat", 1.0)):
        s = g.interface.new_socket(nm, in_out="INPUT", socket_type=tp)
        s.default_value = dv
    for nm in ("Mortar", "Var"):
        g.interface.new_socket(nm, in_out="OUTPUT", socket_type="NodeSocketFloat")
    nt = g
    gi = N(nt, "NodeGroupInput", -1200, 0)
    go = N(nt, "NodeGroupOutput", 900, 0)
    geo = N(nt, "ShaderNodeNewGeometry", -1200, 300)
    pos = N(nt, "ShaderNodeSeparateXYZ", -1000, 300)
    L(nt, geo.outputs["Position"], pos.inputs[0])
    nor = N(nt, "ShaderNodeSeparateXYZ", -1000, 0)
    L(nt, geo.outputs["Normal"], nor.inputs[0])
    ws = []
    for k, comp in enumerate(("X", "Y", "Z")):
        a = math_node(nt, "ABSOLUTE", nor.outputs[comp], x=-800, y=100 - k * 120)
        ws.append(math_node(nt, "POWER", a, 6.0, x=-650, y=100 - k * 120))
    tot = math_node(nt, "ADD", math_node(nt, "ADD", ws[0], ws[1], x=-500, y=0), ws[2], x=-380, y=0)
    tot = math_node(nt, "MAXIMUM", tot, 1e-4, x=-260, y=0)
    planes = (("Y", "Z"), ("X", "Z"), ("X", "Y"))   # facing X -> (y,z); facing Y -> (x,z); facing Z -> (x,y)
    acc_m = acc_v = None
    for k, (a, b) in enumerate(planes):
        c = N(nt, "ShaderNodeCombineXYZ", -800, -300 - k * 200)
        L(nt, pos.outputs[a], c.inputs[0])
        L(nt, pos.outputs[b], c.inputs[1])
        br = N(nt, "ShaderNodeTexBrick", -550, -300 - k * 200, offset=0.5, offset_frequency=2, squash=1.0,
               squash_frequency=2)
        L(nt, c.outputs[0], br.inputs["Vector"])
        br.inputs["Color1"].default_value = (0, 0, 0, 1)
        br.inputs["Color2"].default_value = (1, 1, 1, 1)
        br.inputs["Mortar"].default_value = (1, 1, 1, 1)
        br.inputs["Mortar Smooth"].default_value = 0.3
        br.inputs["Bias"].default_value = 0.0
        L(nt, gi.outputs["Scale"], br.inputs["Scale"])
        L(nt, gi.outputs["Mortar"], br.inputs["Mortar Size"])
        L(nt, gi.outputs["Width"], br.inputs["Brick Width"])
        L(nt, gi.outputs["Height"], br.inputs["Row Height"])
        w = math_node(nt, "DIVIDE", ws[k], tot, x=-380, y=-300 - k * 200)
        m = math_node(nt, "MULTIPLY", br.outputs["Fac"], w, x=-200, y=-300 - k * 200)
        vv = N(nt, "ShaderNodeRGBToBW", -380, -380 - k * 200)
        L(nt, br.outputs["Color"], vv.inputs[0])
        v = math_node(nt, "MULTIPLY", vv.outputs[0], w, x=-200, y=-380 - k * 200)
        acc_m = m if acc_m is None else math_node(nt, "ADD", acc_m, m, x=0, y=-300 - k * 200)
        acc_v = v if acc_v is None else math_node(nt, "ADD", acc_v, v, x=0, y=-380 - k * 200)
    L(nt, acc_m, go.inputs["Mortar"])
    L(nt, acc_v, go.inputs["Var"])
    return g


def tribrick(nt, width, height, mortar, x=-700, y=0):
    n = N(nt, "ShaderNodeGroup", x, y)
    n.node_tree = group_tribrick()
    n.inputs["Width"].default_value = width
    n.inputs["Height"].default_value = height
    n.inputs["Mortar"].default_value = mortar
    return n.outputs["Mortar"], n.outputs["Var"]


def noise(nt, scale, detail=4.0, rough=0.55, x=-700, y=-300, coord="world", dims="3D", w=None, distortion=0.0):
    n = N(nt, "ShaderNodeTexNoise", x, y, noise_dimensions=dims)
    n.inputs["Scale"].default_value = scale
    n.inputs["Detail"].default_value = detail
    n.inputs["Roughness"].default_value = rough
    n.inputs["Distortion"].default_value = distortion
    if coord == "world":
        geo = N(nt, "ShaderNodeNewGeometry", x - 200, y)
        L(nt, geo.outputs["Position"], n.inputs["Vector"])
    elif coord is not None:
        L(nt, coord, n.inputs["Vector"])
    if w is not None and "W" in n.inputs:
        if isinstance(w, (int, float)):
            n.inputs["W"].default_value = w
        else:
            L(nt, w, n.inputs["W"])
    return n.outputs["Fac"]


def bump(nt, height, strength=0.3, distance=0.05, x=100, y=-500, normal=None):
    b = N(nt, "ShaderNodeBump", x, y)
    b.inputs["Strength"].default_value = strength
    b.inputs["Distance"].default_value = distance
    L(nt, height, b.inputs["Height"])
    if normal is not None:
        L(nt, normal, b.inputs["Normal"])
    return b.outputs["Normal"]


def ao(nt, dist=1.5, x=-500, y=500):
    a = N(nt, "ShaderNodeAmbientOcclusion", x, y, samples=8)
    a.inputs["Distance"].default_value = dist
    return a.outputs["AO"]


# ============================================================================================ materials
def mat_stone():
    m, nt = new_mat("M_stone")
    vc = vcol(nt)
    mort, var = tribrick(nt, 0.62, 0.31, 0.02)
    fine = noise(nt, 6.0, 6, 0.6, y=-500)
    big = noise(nt, 0.05, 3, 0.5, y=-800)
    streak_co = N(nt, "ShaderNodeMapping", -900, -1100)
    geo = N(nt, "ShaderNodeNewGeometry", -1100, -1100)
    L(nt, geo.outputs["Position"], streak_co.inputs[0])
    streak_co.inputs["Scale"].default_value = (1.2, 1.2, 0.08)
    streak = noise(nt, 1.0, 3, 0.5, coord=streak_co.outputs[0], y=-1100)
    # albedo: vertex colour x block variation x mottling x large patches, darker joints, grime in crevices
    blockv = math_node(nt, "ADD", math_node(nt, "MULTIPLY", var, 0.14, x=-500, y=100), 0.90, x=-380, y=100)
    mott = math_node(nt, "ADD", math_node(nt, "MULTIPLY", fine, 0.16, x=-500, y=-40), 0.92, x=-380, y=-40)
    patch = math_node(nt, "ADD", math_node(nt, "MULTIPLY", big, 0.3, x=-500, y=-200), 0.85, x=-380, y=-200)
    st = math_node(nt, "ADD", math_node(nt, "MULTIPLY", streak, 0.25, x=-500, y=-320), 0.88, x=-380, y=-320)
    k = math_node(nt, "MULTIPLY", math_node(nt, "MULTIPLY", blockv, mott, x=-250, y=50),
                  math_node(nt, "MULTIPLY", patch, st, x=-250, y=-150), x=-120, y=0)
    col = N(nt, "ShaderNodeMix", 150, 250, data_type="RGBA", blend_type="MULTIPLY")
    col.inputs[0].default_value = 1.0
    L(nt, vc, col.inputs[6])
    kk = N(nt, "ShaderNodeCombineColor", -50, 350)
    for c in range(3):
        L(nt, k, kk.inputs[c])
    L(nt, kk.outputs[0], col.inputs[7])
    joint = mix_col(nt, mort, col.outputs[2], (0.74, 0.72, 0.74, 1), blend="MULTIPLY", x=320, y=250)
    occ = ao(nt, 2.0, x=150, y=500)
    occf = math_node(nt, "ADD", math_node(nt, "MULTIPLY", occ, 0.45, x=320, y=520), 0.55, x=450, y=520)
    occc = N(nt, "ShaderNodeCombineColor", 580, 520)
    for c in range(3):
        L(nt, occf, occc.inputs[c])
    alb = mix_col(nt, 1.0, joint, occc.outputs[0], blend="MULTIPLY", x=500, y=300)
    rough = math_node(nt, "ADD", math_node(nt, "MULTIPLY", fine, 0.2, x=200, y=-300), 0.74, x=330, y=-300)
    h = math_node(nt, "ADD", math_node(nt, "MULTIPLY", mort, -1.0, x=0, y=-600),
                  math_node(nt, "MULTIPLY", fine, 0.25, x=0, y=-700), x=150, y=-650)
    nrm = bump(nt, h, 0.3, 0.02, x=350, y=-600)
    p = principled(nt, 750, 0, Base_Color=alb, Roughness=rough, Normal=nrm)
    p.inputs["Specular IOR Level"].default_value = 0.35
    mat_out(nt, p.outputs[0], 1050, 0)
    return m


def mat_roof():
    m, nt = new_mat("M_roof")
    vc = vcol(nt)
    hs = N(nt, "ShaderNodeHueSaturation", -600, 200)
    hs.inputs["Saturation"].default_value = 1.18
    hs.inputs["Value"].default_value = 0.82
    L(nt, vc, hs.inputs["Color"])
    mort, var = tribrick(nt, 0.55, 0.32, 0.03)
    fine = noise(nt, 9.0, 5, 0.6, y=-500)
    k = math_node(nt, "ADD", math_node(nt, "MULTIPLY", var, 0.28, x=-400, y=0), 0.82, x=-250, y=0)
    kc = N(nt, "ShaderNodeCombineColor", -100, 0)
    for c in range(3):
        L(nt, k, kc.inputs[c])
    col = mix_col(nt, 1.0, hs.outputs[0], kc.outputs[0], blend="MULTIPLY", x=50, y=150)
    col = mix_col(nt, mort, col, (0.15, 0.13, 0.18, 1), blend="MULTIPLY", x=200, y=150)
    occ = ao(nt, 1.2, x=0, y=450)
    occc = N(nt, "ShaderNodeCombineColor", 250, 450)
    oc = math_node(nt, "ADD", math_node(nt, "MULTIPLY", occ, 0.4, x=100, y=500), 0.6, x=180, y=520)
    for c in range(3):
        L(nt, oc, occc.inputs[c])
    col = mix_col(nt, 1.0, col, occc.outputs[0], blend="MULTIPLY", x=350, y=200)
    rough = math_node(nt, "ADD", math_node(nt, "MULTIPLY", var, 0.25, x=0, y=-250), 0.34, x=150, y=-250)
    h = math_node(nt, "ADD", math_node(nt, "MULTIPLY", mort, -1.0, x=0, y=-600),
                  math_node(nt, "MULTIPLY", fine, 0.15, x=0, y=-700), x=150, y=-650)
    nrm = bump(nt, h, 0.6, 0.03, x=350, y=-600)
    p = principled(nt, 650, 0, Base_Color=col, Roughness=rough, Normal=nrm)
    p.inputs["Specular IOR Level"].default_value = 0.6
    mat_out(nt, p.outputs[0], 950, 0)
    return m


def mat_rock():
    m, nt = new_mat("M_rock")
    vc = vcol(nt)
    geo = N(nt, "ShaderNodeNewGeometry", -1100, -200)
    strata_map = N(nt, "ShaderNodeMapping", -900, -200)
    L(nt, geo.outputs["Position"], strata_map.inputs[0])
    strata_map.inputs["Scale"].default_value = (0.15, 0.15, 1.6)
    strata = noise(nt, 0.6, 6, 0.6, coord=strata_map.outputs[0], y=-200)
    fine = noise(nt, 2.5, 8, 0.62, y=-500)
    vor = N(nt, "ShaderNodeTexVoronoi", -700, -800, feature="DISTANCE_TO_EDGE")
    L(nt, geo.outputs["Position"], vor.inputs["Vector"])
    vor.inputs["Scale"].default_value = 0.12
    crack = math_node(nt, "LESS_THAN", vor.outputs["Distance"], 0.012, x=-500, y=-800)
    k = math_node(nt, "ADD", math_node(nt, "MULTIPLY", strata, 0.4, x=-450, y=-200), 0.78, x=-300, y=-200)
    k = math_node(nt, "MULTIPLY", k, math_node(nt, "ADD", math_node(nt, "MULTIPLY", fine, 0.3, x=-450, y=-450), 0.85,
                                                x=-300, y=-450), x=-150, y=-300)
    kc = N(nt, "ShaderNodeCombineColor", 0, -300)
    for c in range(3):
        L(nt, k, kc.inputs[c])
    col = mix_col(nt, 1.0, vc, kc.outputs[0], blend="MULTIPLY", x=150, y=100)
    col = mix_col(nt, math_node(nt, "MULTIPLY", crack, 0.08, x=0, y=-800), col, (0.12, 0.11, 0.12, 1), x=300, y=100)
    # moss / lichen on up-facing rock
    nz = N(nt, "ShaderNodeSeparateXYZ", -900, 400)
    L(nt, geo.outputs["Normal"], nz.inputs[0])
    upf = ramp(nt, nz.outputs["Z"], [(0.55, (0, 0, 0, 1)), (0.85, (1, 1, 1, 1))], x=-700, y=400)
    mossn = noise(nt, 0.4, 4, 0.6, y=600)
    bw = N(nt, "ShaderNodeRGBToBW", -450, 400)
    L(nt, upf, bw.inputs[0])
    mossm = math_node(nt, "MULTIPLY", bw.outputs[0], math_node(nt, "GREATER_THAN", mossn, 0.48, x=-450, y=600), x=-250, y=500)
    col = mix_col(nt, math_node(nt, "MULTIPLY", mossm, 0.75, x=-100, y=500), col, (0.13, 0.17, 0.07, 1), x=450, y=200)
    occ = ao(nt, 3.0, x=200, y=600)
    oc = math_node(nt, "ADD", math_node(nt, "MULTIPLY", occ, 0.5, x=350, y=600), 0.5, x=480, y=600)
    occc = N(nt, "ShaderNodeCombineColor", 600, 600)
    for c in range(3):
        L(nt, oc, occc.inputs[c])
    col = mix_col(nt, 1.0, col, occc.outputs[0], blend="MULTIPLY", x=620, y=250)
    h = math_node(nt, "ADD", math_node(nt, "MULTIPLY", fine, 0.8, x=100, y=-600),
                  math_node(nt, "MULTIPLY", crack, -0.1, x=100, y=-750), x=250, y=-650)
    nrm = bump(nt, h, 0.7, 0.15, x=450, y=-650)
    p = principled(nt, 850, 0, Base_Color=col, Roughness=0.9, Normal=nrm)
    p.inputs["Specular IOR Level"].default_value = 0.3
    mat_out(nt, p.outputs[0], 1150, 0)
    return m


def mat_statue():
    """The colossal Master: pale weathered limestone, rain streaks, lichen and moss (the vertex colour's green
    patches read as moss), soft carved detail."""
    m, nt = new_mat("M_statue")
    vc = vcol(nt)
    geo = N(nt, "ShaderNodeNewGeometry", -1100, -200)
    mp = N(nt, "ShaderNodeMapping", -900, -900)
    L(nt, geo.outputs["Position"], mp.inputs[0])
    mp.inputs["Scale"].default_value = (2.0, 2.0, 0.12)
    streak = noise(nt, 1.0, 4, 0.55, coord=mp.outputs[0], y=-900)
    fine = noise(nt, 3.0, 8, 0.6, y=-500)
    big = noise(nt, 0.25, 4, 0.55, y=-650)
    stone = mix_col(nt, 0.6, vc, (0.66, 0.64, 0.58, 1), x=-500, y=200)
    k = math_node(nt, "MULTIPLY", math_node(nt, "ADD", math_node(nt, "MULTIPLY", streak, 0.35, x=-600, y=-900), 0.8, x=-480, y=-900),
                  math_node(nt, "ADD", math_node(nt, "MULTIPLY", fine, 0.25, x=-600, y=-500), 0.88, x=-480, y=-500), x=-350, y=-700)
    kc = N(nt, "ShaderNodeCombineColor", -200, -700)
    for c in range(3):
        L(nt, k, kc.inputs[c])
    col = mix_col(nt, 1.0, stone, kc.outputs[0], blend="MULTIPLY", x=-250, y=200)
    nz = N(nt, "ShaderNodeSeparateXYZ", -900, 400)
    L(nt, geo.outputs["Normal"], nz.inputs[0])
    up = ramp(nt, nz.outputs["Z"], [(0.2, (0, 0, 0, 1)), (0.7, (1, 1, 1, 1))], x=-700, y=400)
    upbw = N(nt, "ShaderNodeRGBToBW", -500, 400)
    L(nt, up, upbw.inputs[0])
    moss = math_node(nt, "MULTIPLY", upbw.outputs[0], math_node(nt, "GREATER_THAN", big, 0.47, x=-500, y=600), x=-350, y=500)
    col = mix_col(nt, math_node(nt, "MULTIPLY", moss, 0.85, x=-200, y=500), col, (0.16, 0.22, 0.08, 1), x=0, y=250)
    occ = ao(nt, 2.5, x=0, y=600)
    oc = math_node(nt, "ADD", math_node(nt, "MULTIPLY", occ, 0.5, x=150, y=600), 0.5, x=280, y=600)
    occc = N(nt, "ShaderNodeCombineColor", 400, 600)
    for c in range(3):
        L(nt, oc, occc.inputs[c])
    col = mix_col(nt, 1.0, col, occc.outputs[0], blend="MULTIPLY", x=300, y=250)
    nrm = bump(nt, math_node(nt, "ADD", fine, math_node(nt, "MULTIPLY", big, 0.5, x=0, y=-650), x=150, y=-600), 0.35, 0.1,
               x=300, y=-600)
    p = principled(nt, 600, 0, Base_Color=col, Roughness=0.88, Normal=nrm)
    mat_out(nt, p.outputs[0], 900, 0)
    return m


def mat_paving():
    """Flagstone floors of the terraces, the ring road and the bridge deck."""
    m, nt = new_mat("M_paving")
    vc = vcol(nt)
    geo = N(nt, "ShaderNodeNewGeometry", -1100, 0)
    sep = N(nt, "ShaderNodeSeparateXYZ", -950, 0)
    L(nt, geo.outputs["Position"], sep.inputs[0])
    cxy = N(nt, "ShaderNodeCombineXYZ", -800, 0)
    L(nt, sep.outputs["X"], cxy.inputs[0])
    L(nt, sep.outputs["Y"], cxy.inputs[1])
    br = N(nt, "ShaderNodeTexBrick", -600, 0, offset=0.5, offset_frequency=2, squash=1.0, squash_frequency=2)
    L(nt, cxy.outputs[0], br.inputs["Vector"])
    br.inputs["Color1"].default_value = (0.8, 0.8, 0.8, 1)
    br.inputs["Color2"].default_value = (1.0, 1.0, 1.0, 1)
    br.inputs["Mortar"].default_value = (0.55, 0.53, 0.55, 1)
    br.inputs["Scale"].default_value = 1.0
    br.inputs["Mortar Size"].default_value = 0.025
    br.inputs["Mortar Smooth"].default_value = 0.4
    br.inputs["Brick Width"].default_value = 1.1
    br.inputs["Row Height"].default_value = 0.7
    fine = noise(nt, 5.0, 6, 0.6, y=-400)
    big = noise(nt, 0.08, 3, 0.5, y=-600)
    col = mix_col(nt, 1.0, vc, br.outputs["Color"], blend="MULTIPLY", x=-300, y=200)
    kk = math_node(nt, "MULTIPLY", math_node(nt, "ADD", math_node(nt, "MULTIPLY", fine, 0.2, x=-400, y=-400), 0.9, x=-280, y=-400),
                   math_node(nt, "ADD", math_node(nt, "MULTIPLY", big, 0.3, x=-400, y=-600), 0.85, x=-280, y=-600), x=-150, y=-500)
    kc = N(nt, "ShaderNodeCombineColor", 0, -500)
    for c in range(3):
        L(nt, kk, kc.inputs[c])
    col = mix_col(nt, 1.0, col, kc.outputs[0], blend="MULTIPLY", x=-100, y=200)
    lift = mix_col(nt, 0.35, col, (0.55, 0.5, 0.48, 1), x=50, y=200)
    occ = ao(nt, 1.5, x=0, y=500)
    oc = math_node(nt, "ADD", math_node(nt, "MULTIPLY", occ, 0.5, x=150, y=500), 0.5, x=280, y=500)
    occc = N(nt, "ShaderNodeCombineColor", 400, 500)
    for c in range(3):
        L(nt, oc, occc.inputs[c])
    col = mix_col(nt, 1.0, lift, occc.outputs[0], blend="MULTIPLY", x=250, y=250)
    h = math_node(nt, "ADD", br.outputs["Fac"], math_node(nt, "MULTIPLY", fine, 0.3, x=0, y=-800), x=150, y=-700)
    nrm = bump(nt, h, 0.3, 0.02, x=300, y=-700)
    p = principled(nt, 550, 0, Base_Color=col, Roughness=0.78, Normal=nrm)
    mat_out(nt, p.outputs[0], 850, 0)
    return m


def mat_snow():
    m, nt = new_mat("M_snow")
    fine = noise(nt, 1.5, 6, 0.55, y=-300)
    col = mix_col(nt, fine, (0.86, 0.87, 0.95, 1), (0.98, 0.97, 1.0, 1), x=0, y=100)
    nrm = bump(nt, fine, 0.35, 0.2, x=0, y=-400)
    p = principled(nt, 350, 0, Base_Color=col, Roughness=0.55, Normal=nrm)
    p.inputs["Subsurface Weight"].default_value = 0.4
    p.inputs["Subsurface Radius"].default_value = (0.5, 0.7, 1.0)
    p.inputs["Subsurface Scale"].default_value = 0.4
    mat_out(nt, p.outputs[0], 650, 0)
    return m


def mat_cloud(name="M_cloud", height_tint=True):
    """Cumulus: soft white, warm subsurface, lavender in the troughs, sheen on the rims."""
    m, nt = new_mat(name)
    geo = N(nt, "ShaderNodeNewGeometry", -1000, 300)
    z = N(nt, "ShaderNodeSeparateXYZ", -800, 300)
    L(nt, geo.outputs["Position"], z.inputs[0])
    fine = noise(nt, 0.08, 5, 0.6, y=-300)
    h = math_node(nt, "ADD", z.outputs["Z"], math_node(nt, "MULTIPLY", fine, 6.0, x=-600, y=0), x=-450, y=200)
    tint = ramp(nt, math_node(nt, "MULTIPLY", h, 1.0 / 26.0, x=-300, y=200),
                [(0.0, (0.42, 0.40, 0.58, 1)), (0.35, (0.78, 0.74, 0.86, 1)), (0.75, (1.0, 0.96, 0.95, 1))],
                x=-150, y=200) if height_tint else None
    base = tint if tint is not None else (0.97, 0.95, 0.97, 1)
    nrm = bump(nt, noise(nt, 0.35, 4, 0.55, y=-600), 0.25, 1.5, x=100, y=-500)
    p = principled(nt, 350, 0, Base_Color=base, Roughness=1.0, Normal=nrm)
    p.inputs["Subsurface Weight"].default_value = 0.5
    p.inputs["Subsurface Radius"].default_value = (1.0, 0.72, 0.62)
    p.inputs["Subsurface Scale"].default_value = 3.0
    p.inputs["Sheen Weight"].default_value = 0.35
    p.inputs["Sheen Roughness"].default_value = 0.4
    p.inputs["Specular IOR Level"].default_value = 0.1
    mat_out(nt, p.outputs[0], 650, 0)
    return m


def mat_foliage():
    m, nt = new_mat("M_foliage")
    vc = vcol(nt)
    n1 = noise(nt, 1.2, 4, 0.6, y=-300)
    n2 = noise(nt, 7.0, 3, 0.6, y=-600)
    hs = N(nt, "ShaderNodeHueSaturation", -300, 200)
    L(nt, vc, hs.inputs["Color"])
    L(nt, math_node(nt, "ADD", math_node(nt, "MULTIPLY", n1, 0.08, x=-500, y=0), 0.46, x=-400, y=0), hs.inputs["Hue"])
    L(nt, math_node(nt, "ADD", math_node(nt, "MULTIPLY", n2, 0.5, x=-500, y=-150), 0.75, x=-400, y=-150), hs.inputs["Value"])
    hs.inputs["Saturation"].default_value = 1.1
    occ = ao(nt, 1.0, x=-100, y=450)
    oc = math_node(nt, "ADD", math_node(nt, "MULTIPLY", occ, 0.55, x=50, y=450), 0.45, x=160, y=450)
    occc = N(nt, "ShaderNodeCombineColor", 280, 450)
    for c in range(3):
        L(nt, oc, occc.inputs[c])
    col = mix_col(nt, 1.0, hs.outputs[0], occc.outputs[0], blend="MULTIPLY", x=300, y=250)
    nrm = bump(nt, n2, 0.5, 0.1, x=100, y=-500)
    p = principled(nt, 600, 0, Base_Color=col, Roughness=0.6, Normal=nrm)
    p.inputs["Subsurface Weight"].default_value = 0.3
    p.inputs["Subsurface Radius"].default_value = (0.4, 1.0, 0.2)
    p.inputs["Subsurface Scale"].default_value = 0.3
    p.inputs["Sheen Weight"].default_value = 0.3
    mat_out(nt, p.outputs[0], 900, 0)
    return m


def mat_wood():
    m, nt = new_mat("M_wood")
    vc = vcol(nt)
    geo = N(nt, "ShaderNodeNewGeometry", -1000, -200)
    mp = N(nt, "ShaderNodeMapping", -800, -200)
    L(nt, geo.outputs["Position"], mp.inputs[0])
    mp.inputs["Scale"].default_value = (6.0, 6.0, 0.4)
    grain = noise(nt, 1.0, 6, 0.6, coord=mp.outputs[0], y=-200, distortion=0.6)
    k = math_node(nt, "ADD", math_node(nt, "MULTIPLY", grain, 0.45, x=-400, y=-200), 0.72, x=-250, y=-200)
    kc = N(nt, "ShaderNodeCombineColor", -100, -200)
    for c in range(3):
        L(nt, k, kc.inputs[c])
    col = mix_col(nt, 1.0, vc, kc.outputs[0], blend="MULTIPLY", x=100, y=100)
    nrm = bump(nt, grain, 0.3, 0.02, x=100, y=-500)
    p = principled(nt, 400, 0, Base_Color=col, Roughness=0.72, Normal=nrm)
    mat_out(nt, p.outputs[0], 700, 0)
    return m


def mat_cloth(name="M_cloth"):
    """Heavy cloth: sheen + light through it when back-lit (sunset banners glow)."""
    m, nt = new_mat(name)
    vc = vcol(nt)
    weave = noise(nt, 30.0, 2, 0.5, y=-400)
    folds = noise(nt, 0.9, 2, 0.5, y=-700)
    k = math_node(nt, "ADD", math_node(nt, "MULTIPLY", folds, 0.35, x=-400, y=-600), 0.8, x=-250, y=-600)
    kc = N(nt, "ShaderNodeCombineColor", -100, -600)
    for c in range(3):
        L(nt, k, kc.inputs[c])
    col = mix_col(nt, 1.0, vc, kc.outputs[0], blend="MULTIPLY", x=0, y=100)
    nrm = bump(nt, math_node(nt, "ADD", folds, math_node(nt, "MULTIPLY", weave, 0.1, x=-200, y=-400), x=-50, y=-500),
               0.4, 0.2, x=150, y=-500)
    p = principled(nt, 350, 100, Base_Color=col, Roughness=0.85, Normal=nrm)
    p.inputs["Sheen Weight"].default_value = 0.8
    p.inputs["Sheen Roughness"].default_value = 0.5
    tr = N(nt, "ShaderNodeBsdfTranslucent", 350, -250)
    L(nt, col, tr.inputs["Color"])
    L(nt, nrm, tr.inputs["Normal"])
    mx = N(nt, "ShaderNodeMixShader", 650, 0)
    mx.inputs[0].default_value = 0.35
    L(nt, p.outputs[0], mx.inputs[1])
    L(nt, tr.outputs[0], mx.inputs[2])
    mat_out(nt, mx.outputs[0], 900, 0)
    m.use_backface_culling = False
    return m


def mat_banner(name, info):
    """The game's banner shader rebuilt: cloth colour, stripes, glyph, swallowtail notch (UV-driven)."""
    p_ = info.get("params", {})
    cloth = tuple(p_.get("cloth_color") or (0.3, 0.15, 0.4, 1))[:3]
    stripe = tuple(p_.get("stripe_color") or (0.85, 0.7, 0.35, 1))[:3] if isinstance(p_.get("stripe_color"), list) else (0.85, 0.7, 0.35)
    glyph_c = tuple(p_.get("glyph_color") or (1.0, 0.8, 0.4, 1))[:3]
    shape = int(p_.get("glyph_shape") or 0)
    m, nt = new_mat(name)
    uv = N(nt, "ShaderNodeUVMap", -1200, 0)
    uv.uv_map = "UVMap"
    sep = N(nt, "ShaderNodeSeparateXYZ", -1000, 0)
    L(nt, uv.outputs[0], sep.inputs[0])
    u, v = sep.outputs["X"], sep.outputs["Y"]
    s1 = math_node(nt, "MULTIPLY", math_node(nt, "GREATER_THAN", v, 0.52, x=-800, y=200),
                   math_node(nt, "LESS_THAN", v, 0.62, x=-800, y=120), x=-650, y=160)
    s2 = math_node(nt, "GREATER_THAN", v, 0.80, x=-800, y=40)
    stripe_m = math_node(nt, "MAXIMUM", s1, s2, x=-500, y=100)
    du = math_node(nt, "ABSOLUTE", math_node(nt, "SUBTRACT", u, 0.5, x=-850, y=-200), x=-700, y=-200)
    if shape == 0:
        cond_a = math_node(nt, "MULTIPLY", math_node(nt, "GREATER_THAN", v, 0.18, x=-800, y=-350),
                           math_node(nt, "LESS_THAN", v, 0.46, x=-800, y=-420), x=-650, y=-380)
        lim = math_node(nt, "MULTIPLY", math_node(nt, "SUBTRACT", v, 0.18, x=-700, y=-500), 0.9, x=-560, y=-500)
        glyph = math_node(nt, "MULTIPLY", cond_a, math_node(nt, "LESS_THAN", du, lim, x=-450, y=-450), x=-320, y=-400)
    else:
        dv = math_node(nt, "ABSOLUTE", math_node(nt, "SUBTRACT", v, 0.32, x=-850, y=-500), x=-700, y=-500)
        glyph = math_node(nt, "LESS_THAN", math_node(nt, "ADD", du, math_node(nt, "MULTIPLY", dv, 0.5, x=-560, y=-500),
                                                    x=-450, y=-450), 0.14, x=-320, y=-400)
    col = mix_col(nt, stripe_m, cloth, stripe, x=-250, y=150)
    col = mix_col(nt, glyph, col, glyph_c, x=-100, y=150)
    shade = math_node(nt, "ADD", math_node(nt, "MULTIPLY", math_node(nt, "MINIMUM", v, 0.3, x=-500, y=-700), 0.83, x=-380, y=-700),
                      0.8, x=-250, y=-700)
    sc = N(nt, "ShaderNodeCombineColor", -100, -700)
    for c in range(3):
        L(nt, shade, sc.inputs[c])
    col = mix_col(nt, 1.0, col, sc.outputs[0], blend="MULTIPLY", x=50, y=150)
    notch = math_node(nt, "MULTIPLY", math_node(nt, "GREATER_THAN", v, 0.88, x=-800, y=-900),
                      math_node(nt, "LESS_THAN", du, math_node(nt, "ADD", math_node(nt, "MULTIPLY",
                                math_node(nt, "SUBTRACT", v, 0.88, x=-800, y=-1000), 1.0, x=-650, y=-1000), 0.0001,
                                x=-520, y=-1000), x=-400, y=-950), x=-250, y=-900)
    alpha = math_node(nt, "SUBTRACT", 1.0, notch, x=-100, y=-900)
    folds = noise(nt, 1.3, 2, 0.5, y=-1200)
    nrm = bump(nt, folds, 0.5, 0.25, x=100, y=-600)
    p = principled(nt, 350, 100, Base_Color=col, Roughness=0.85, Normal=nrm, Alpha=alpha)
    p.inputs["Sheen Weight"].default_value = 0.7
    em = math_node(nt, "MULTIPLY", glyph, 0.6, x=100, y=-300)
    L(nt, em, p.inputs["Emission Strength"])
    p.inputs["Emission Color"].default_value = (*glyph_c, 1.0)
    tr = N(nt, "ShaderNodeBsdfTranslucent", 350, -300)
    L(nt, col, tr.inputs["Color"])
    mx = N(nt, "ShaderNodeMixShader", 650, 0)
    mx.inputs[0].default_value = 0.3
    L(nt, p.outputs[0], mx.inputs[1])
    L(nt, tr.outputs[0], mx.inputs[2])
    tp = N(nt, "ShaderNodeBsdfTransparent", 650, -250)
    mx2 = N(nt, "ShaderNodeMixShader", 850, 0)
    L(nt, alpha, mx2.inputs[0])
    L(nt, tp.outputs[0], mx2.inputs[1])
    L(nt, mx.outputs[0], mx2.inputs[2])
    mat_out(nt, mx2.outputs[0], 1050, 0)
    m.use_backface_culling = False
    return m


def mat_gold():
    m, nt = new_mat("M_gold")
    vc = vcol(nt)
    fine = noise(nt, 4.0, 5, 0.6, y=-300)
    col = mix_col(nt, 0.55, vc, (1.0, 0.71, 0.32, 1), x=0, y=100)
    rough = math_node(nt, "ADD", math_node(nt, "MULTIPLY", fine, 0.25, x=0, y=-300), 0.14, x=150, y=-300)
    p = principled(nt, 400, 0, Base_Color=col, Metallic=1.0, Roughness=rough)
    mat_out(nt, p.outputs[0], 700, 0)
    return m


def mat_iron():
    m, nt = new_mat("M_iron")
    vc = vcol(nt)
    fine = noise(nt, 3.0, 5, 0.6, y=-300)
    rough = math_node(nt, "ADD", math_node(nt, "MULTIPLY", fine, 0.3, x=0, y=-300), 0.35, x=150, y=-300)
    col = mix_col(nt, 0.5, vc, (0.35, 0.33, 0.32, 1), x=0, y=100)
    p = principled(nt, 400, 0, Base_Color=col, Metallic=0.85, Roughness=rough)
    mat_out(nt, p.outputs[0], 700, 0)
    return m


def mat_glass():
    m, nt = new_mat("M_glass")
    vc = vcol(nt)
    dusk = drv_value(nt, "glow_gain", x=-600, y=-300)
    p = principled(nt, 300, 0, Base_Color=vc, Metallic=0.35, Roughness=0.05)
    p.inputs["Coat Weight"].default_value = 1.0
    p.inputs["Emission Color"].default_value = (1.0, 0.62, 0.3, 1)
    L(nt, math_node(nt, "MULTIPLY", dusk, 0.08, x=0, y=-300), p.inputs["Emission Strength"])
    mat_out(nt, p.outputs[0], 600, 0)
    return m


def mat_glow(name="M_glow", fixed_color=None, gain=1.0):
    """Windows, lanterns, runes: vertex colour (or a fixed colour) x the film's glow cue."""
    m, nt = new_mat(name)
    col = vcol(nt) if fixed_color is None else None
    g = drv_value(nt, "glow_gain", x=-600, y=-300)
    flick = noise(nt, 0.7, 2, 0.5, y=-600, dims="4D", w=0.0)
    # flicker in time: W driven by the frame
    wn = [n for n in nt.nodes if n.bl_idname == "ShaderNodeTexNoise"][-1]
    d = wn.inputs["W"].driver_add("default_value").driver
    d.expression = "frame/9.0"
    fl = math_node(nt, "ADD", math_node(nt, "MULTIPLY", flick, 0.5, x=-300, y=-600), 0.75, x=-150, y=-600)
    strength = math_node(nt, "MULTIPLY", math_node(nt, "MULTIPLY", g, fl, x=0, y=-400), gain, x=150, y=-400)
    p = principled(nt, 350, 0, Roughness=0.25)
    if col is not None:
        p.inputs["Base Color"].default_value = (0.03, 0.025, 0.03, 1)
        warm = mix_col(nt, 1.0, col, (1.0, 0.70, 0.40, 1), blend="MULTIPLY", x=150, y=150)
        L(nt, warm, p.inputs["Emission Color"])
    else:
        p.inputs["Base Color"].default_value = (*fixed_color, 1)
        p.inputs["Emission Color"].default_value = (*fixed_color, 1)
    L(nt, strength, p.inputs["Emission Strength"])
    mat_out(nt, p.outputs[0], 650, 0)
    return m


def mat_falls():
    m, nt = new_mat("M_falls")
    geo = N(nt, "ShaderNodeNewGeometry", -1200, 0)
    mp = N(nt, "ShaderNodeMapping", -1000, 0)
    L(nt, geo.outputs["Position"], mp.inputs[0])
    mp.inputs["Scale"].default_value = (2.2, 2.2, 0.25)
    dr = mp.inputs["Location"].driver_add("default_value", 2).driver
    dr.expression = "frame*0.28"
    streak = noise(nt, 2.0, 4, 0.6, coord=mp.outputs[0], y=0, distortion=0.3)
    foam = ramp(nt, streak, [(0.35, (0.55, 0.68, 0.78, 1)), (0.62, (0.95, 0.97, 1.0, 1))], x=-500, y=100)
    alpha = math_node(nt, "ADD", math_node(nt, "MULTIPLY", streak, 0.7, x=-500, y=-200), 0.45, x=-350, y=-200, clamp=True)
    p = principled(nt, 200, 0, Base_Color=foam, Roughness=0.15, Alpha=alpha)
    p.inputs["Emission Color"].default_value = (0.9, 0.93, 1.0, 1)
    p.inputs["Emission Strength"].default_value = 0.15
    p.inputs["Subsurface Weight"].default_value = 0.4
    mat_out(nt, p.outputs[0], 600, 0)
    m.use_backface_culling = False
    return m


def mat_water():
    m, nt = new_mat("M_water")
    n1 = noise(nt, 1.5, 4, 0.5, y=-300)
    nrm = bump(nt, n1, 0.15, 0.2, x=0, y=-300)
    p = principled(nt, 300, 0, Base_Color=(0.08, 0.16, 0.22), Roughness=0.03, Normal=nrm)
    p.inputs["Specular IOR Level"].default_value = 0.8
    mat_out(nt, p.outputs[0], 600, 0)
    return m


def mat_ice():
    m, nt = new_mat("M_ice")
    lw = N(nt, "ShaderNodeLayerWeight", -400, -200)
    lw.inputs["Blend"].default_value = 0.35
    p = principled(nt, 200, 0, Base_Color=(0.45, 0.72, 0.95), Roughness=0.06)
    p.inputs["Emission Color"].default_value = (0.5, 0.85, 1.0, 1)
    L(nt, math_node(nt, "ADD", math_node(nt, "MULTIPLY", out(lw, "Facing"), 2.0, x=-200, y=-300), 0.4, x=0, y=-300),
      p.inputs["Emission Strength"])
    p.inputs["Coat Weight"].default_value = 1.0
    mat_out(nt, p.outputs[0], 500, 0)
    return m


def mat_dark():
    m, nt = new_mat("M_dark")
    vc = vcol(nt)
    p = principled(nt, 200, 0, Base_Color=vc, Roughness=0.95)
    mat_out(nt, p.outputs[0], 500, 0)
    return m


def mat_dragon(kind):
    m, nt = new_mat(f"M_dragon_{kind}")
    if kind == "cinder_scale":
        vc = vcol(nt)
        base = mix_col(nt, 0.88, vc, (0.035, 0.025, 0.025, 1), x=0, y=100)
        p = principled(nt, 300, 0, Base_Color=base, Roughness=0.38, Metallic=0.35)
        p.inputs["Specular IOR Level"].default_value = 0.7
    elif kind == "frost_scale":
        vc = vcol(nt)
        base = mix_col(nt, 0.5, vc, (0.55, 0.68, 0.85, 1), x=0, y=100)
        p = principled(nt, 300, 0, Base_Color=base, Roughness=0.35, Metallic=0.2)
    elif kind in ("cinder_membrane", "frost_membrane"):
        c = (0.55, 0.12, 0.05) if kind == "cinder_membrane" else (0.45, 0.72, 0.9)
        p = principled(nt, 300, 100, Base_Color=c, Roughness=0.6)
        tr = N(nt, "ShaderNodeBsdfTranslucent", 300, -250)
        tr.inputs["Color"].default_value = (*[min(1, x * 1.6) for x in c], 1)
        mx = N(nt, "ShaderNodeMixShader", 600, 0)
        mx.inputs[0].default_value = 0.45
        L(nt, p.outputs[0], mx.inputs[1])
        L(nt, tr.outputs[0], mx.inputs[2])
        mat_out(nt, mx.outputs[0], 850, 0)
        m.use_backface_culling = False
        return m
    elif kind == "horn":
        p = principled(nt, 300, 0, Base_Color=(0.12, 0.1, 0.09), Roughness=0.35)
    elif kind == "cinder_lava":
        p = principled(nt, 300, 0, Base_Color=(1.0, 0.35, 0.05), Roughness=0.5)
        p.inputs["Emission Color"].default_value = (1.0, 0.38, 0.06, 1)
        p.inputs["Emission Strength"].default_value = 6.0
    else:  # frost glow / ice
        p = principled(nt, 300, 0, Base_Color=(0.6, 0.9, 1.0), Roughness=0.1)
        p.inputs["Emission Color"].default_value = (0.55, 0.9, 1.0, 1)
        p.inputs["Emission Strength"].default_value = 3.0
    mat_out(nt, p.outputs[0], 700, 0)
    return m


def mat_emit(name, color, strength):
    m, nt = new_mat(name)
    e = N(nt, "ShaderNodeEmission", 0, 0)
    e.inputs["Color"].default_value = (*color, 1)
    e.inputs["Strength"].default_value = strength
    mat_out(nt, e.outputs[0], 300, 0)
    return m


MATS = {}


def build_materials():
    MATS.update(stone=mat_stone(), roof=mat_roof(), rock=mat_rock(), snow=mat_snow(), cloud=mat_cloud("M_cloud_puff"),
                foliage=mat_foliage(), wood=mat_wood(), cloth=mat_cloth(), cloth_wave=mat_cloth("M_cloth_wave"),
                gold=mat_gold(), iron=mat_iron(), glass=mat_glass(), glow=mat_glow(), falls=mat_falls(),
                water=mat_water(), ice=mat_ice(), dark=mat_dark(), statue=mat_statue(), paving=mat_paving())
    for k in ("cinder_scale", "frost_scale", "cinder_membrane", "frost_membrane", "horn", "cinder_lava", "frost_glow"):
        MATS["dragon_" + k] = mat_dragon(k)


# ============================================================================================ classification
HIDE_SHADERS = ("citadel_halo", "citadel_haze", "citadel_mist", "citadel_shaft", "citadel_shade", "_ground",
                "site_ground", "nature_contact", "unit_blob")
GLOW_SHADERS = ("rune_glow", "unit_glow", "_keep_glow", "fire_keep_runes", "nature_keep_seed")
BANNER_SHADERS = ("banner.gdshader", "fire_keep_banner", "nature_keep_banner", "dusk_keep_banner")
PAINTED = ("painted.gdshader",)


def source_kind(name: str, info: dict) -> str:
    sh = (info.get("shader") or "").split("/")[-1]
    cls = info.get("class", "")
    if name == "none":
        return "hide"
    if cls == "StandardMaterial3D":
        if info.get("transparency", 0) != 0 and not info.get("vertex_color_albedo", False):
            return "hide"
        return "metal" if info.get("metallic", 0) > 0.5 else "vc"
    if any(s in sh for s in HIDE_SHADERS):
        return "hide"
    if sh == "citadel_glow.gdshader":
        return "glow_vc"
    if any(s in sh for s in GLOW_SHADERS):
        return "glow_param"
    if sh == "citadel_banner.gdshader":
        return "cloth_wave"
    if any(sh.endswith(s) for s in BANNER_SHADERS):
        return "banner"
    if sh == "citadel_waterfall.gdshader":
        return "falls"
    if sh == "citadel_water.gdshader":
        return "water"
    if sh == "frost_ice.gdshader":
        return "ice"
    if sh == "market_nature_gold.gdshader":
        return "gold"
    if sh == "nature_keep_leaf.gdshader":
        return "leaf"
    if sh == "nature_painted.gdshader":
        return "vc_srgb"
    if sh == "fire_keep_painted.gdshader":
        return "painted_slots"
    if sh == "nature_keep_painted.gdshader":
        return "painted_ao"
    if sh.endswith("painted.gdshader"):
        return "painted"
    if sh in ("dragon_scale.gdshader",):
        return "dragon_cinder_scale"
    if sh in ("frost_scale.gdshader",):
        return "dragon_frost_scale"
    if sh in ("dragon_membrane.gdshader",):
        return "dragon_cinder_membrane"
    if sh in ("frost_membrane.gdshader",):
        return "dragon_frost_membrane"
    return "vc"


def parse_col_list(s):
    """'[(0.33, 0.28, 0.25, 1.0), ...]' -> [(r,g,b), ...]"""
    out_ = []
    for part in str(s).split("("):
        nums = [float(x) for x in part.replace(")", " ").replace("]", " ").replace(",", " ").split() if x.replace(".", "", 1).replace("-", "", 1).isdigit()]
        if len(nums) >= 3:
            out_.append(tuple(nums[:3]))
    return out_


def classify_faces(col, cen, nz, metal):
    """Per face: vertex colour (linear rgb), centre (Blender), normal z, is-metal -> class name array."""
    r = np.hypot(cen[:, 0], cen[:, 1])
    z = cen[:, 2]
    mx = col.max(axis=1)
    mn = col.min(axis=1)
    v = mx
    s = np.where(mx > 1e-6, (mx - mn) / np.maximum(mx, 1e-6), 0.0)
    rc, gc, bc = col[:, 0], col[:, 1], col[:, 2]
    d = np.maximum(mx - mn, 1e-6)
    h = np.where(mx == rc, ((gc - bc) / d) % 6.0, np.where(mx == gc, (bc - rc) / d + 2.0, (rc - gc) / d + 4.0)) * 60.0
    h = np.where(mx - mn < 1e-6, 0.0, h)
    bridge = (np.abs(cen[:, 0]) < 16) & (cen[:, 1] < -60) & (cen[:, 1] > -175)
    outside = (r > 95) & ~bridge
    cls = np.full(len(col), "stone", dtype=object)
    cls[(v >= 0.5)] = "stone"
    cls[(v < 0.5)] = "rock"
    cls[outside & ~(v >= 0.8)] = "rock"
    wood = (h >= 10) & (h <= 50) & (s >= 0.28) & (v < 0.75)
    cls[wood] = "wood"
    goldm = (h >= 30) & (h <= 60) & (s > 0.5) & (v > 0.5)
    cls[goldm] = "gold"
    cloth = (s > 0.35) & ((h < 12) | (h > 290) | ((h >= 175) & (h <= 290))) & (np.abs(nz) < 0.35)
    cls[cloth] = "cloth"
    roof = (h >= 195) & (h <= 300) & (s > 0.18) & (nz > 0.12) & (nz < 0.97)
    cls[roof] = "roof"
    fol = (h >= 65) & (h <= 170) & (s > 0.28)
    cls[fol] = "foliage"
    cls[v < 0.1] = "dark"
    snow = outside & (s < 0.2) & (v >= 0.8) & (z >= 30)
    cls[snow] = "snow"
    cloud = outside & (z < 30) & (s < 0.25) & (v > 0.5)
    cls[cloud] = "cloud"
    paving = ~outside & (nz > 0.85) & (z > 29.0) & np.isin(cls, ["rock", "stone"])
    cls[paving] = "paving"
    if metal is not None:
        mcls = np.full(len(col), "iron", dtype=object)
        mcls[(h >= 150) & (h <= 205) & (s > 0.3)] = "glass"
        mcls[(h >= 25) & (h <= 60) & (s > 0.45)] = "gold"
        mcls[(v >= 0.45) & (s < 0.2)] = "iron"
        cls = np.where(metal, mcls, cls)
    return cls


def process_mesh(obj, minfo, banner_mats):
    """Recolours shader-driven faces into the vertex colour, classifies every face, assigns the film materials,
    deletes hidden faces. Returns per-class face counts."""
    me = obj.data
    n = len(me.polygons)
    if n == 0:
        return {}
    ca = me.color_attributes.get("Color")
    if ca is None:
        ca = me.color_attributes.new("Color", "FLOAT_COLOR", "CORNER")
        ca.data.foreach_set("color", np.ones(len(me.loops) * 4, np.float32))
    if ca.domain != "CORNER" or ca.data_type != "FLOAT_COLOR":
        # convert to float corner colours (precision + easy writes)
        ca = convert_color(me, ca)
    nl = len(me.loops)
    lc = np.empty(nl * 4, np.float32)
    ca.data.foreach_get("color", lc)
    lc = lc.reshape(-1, 4)
    mi = np.empty(n, np.int32)
    me.polygons.foreach_get("material_index", mi)
    ls = np.empty(n, np.int32)
    me.polygons.foreach_get("loop_start", ls)
    lt = np.empty(n, np.int32)
    me.polygons.foreach_get("loop_total", lt)
    nor = np.empty(n * 3, np.float32)
    me.polygons.foreach_get("normal", nor)
    nor = nor.reshape(-1, 3)
    cen = np.empty(n * 3, np.float32)
    me.polygons.foreach_get("center", cen)
    cen = cen.reshape(-1, 3)
    mw = np.array(obj.matrix_world)
    cen = cen @ mw[:3, :3].T + mw[:3, 3]
    loop_face = np.repeat(np.arange(n), lt)   # assumes loops ordered by face (true for glTF imports)
    uv2 = None
    if len(me.uv_layers) > 1:
        u2 = np.empty(nl * 2, np.float32)
        me.uv_layers[1].data.foreach_get("uv", u2)
        uv2 = u2.reshape(-1, 2)
    srcs = [m.name if m else "none" for m in me.materials]
    kinds = []
    for sname in srcs:
        base = sname.split(".")[0] if sname not in minfo else sname
        info = minfo.get(sname) or minfo.get(base) or {}
        kinds.append((source_kind(base, info), info, base))
    face_kind = np.array([kinds[k][0] for k in mi], dtype=object) if n else np.array([])
    # recolour by source material
    for k, (kind, info, base) in enumerate(kinds):
        fsel = mi == k
        if not fsel.any():
            continue
        lsel = fsel[loop_face]
        p_ = info.get("params", {})
        if kind == "painted" and isinstance(p_.get("base_color"), list):
            lc[lsel, :3] = np.array(p_["base_color"][:3], np.float32)
        elif kind == "painted_ao" and isinstance(p_.get("base_color"), list):
            aocol = np.clip(lc[lsel, 0:1], 0, 1)
            lc[lsel, :3] = np.array(p_["base_color"][:3], np.float32) * (0.4 + 0.6 * aocol)
        elif kind == "painted_slots":
            cols = parse_col_list(p_.get("base_colors", ""))
            if cols and uv2 is not None:
                idx = np.clip(np.round(uv2[lsel, 1]).astype(int), 0, len(cols) - 1)
                lc[lsel, :3] = np.array(cols, np.float32)[idx]
        elif kind == "vc_srgb":
            lc[lsel, :3] = np.power(np.clip(lc[lsel, :3], 0, 1), 2.2)
        elif kind == "glow_param":
            gcol = p_.get("glow_color") or p_.get("heart_color") or [1, 0.7, 0.3, 1]
            lc[lsel, :3] = np.array(gcol[:3], np.float32)
        elif kind == "leaf" and isinstance(p_.get("base_color"), list):
            lc[lsel, :3] = np.array(p_["base_color"][:3], np.float32)
    # per-face mean colour
    sums = np.zeros((n, 3), np.float64)
    np.add.at(sums, loop_face, lc[:, :3])
    fcol = (sums / np.maximum(lt, 1)[:, None]).astype(np.float32)
    vc_like = np.isin(face_kind, ["vc", "vc_srgb", "painted", "painted_ao", "painted_slots", "metal"])
    metal = face_kind == "metal"
    cls = classify_faces(fcol, cen, nor[:, 2], metal)
    final = np.where(vc_like, cls, face_kind).astype(object)
    final[final == "cloud"] = "hide"          # the game's low-poly cloud puffs: the film has its own cloud sea
    ruin = np.hypot(cen[:, 0] + 150.0, cen[:, 1] - 120.0) < 34.0
    final[ruin] = "hide"                      # the ruined dome crag (S13, "years later"): not in this film
    for cx, cy in ((-128.0, 45.0), (128.0, 45.0), (42.0, 112.0), (-48.0, 110.0)):
        final[np.hypot(cen[:, 0] - cx, cen[:, 1] - cy) < 14.0] = "hide"   # the four army camps (S30)
    rr = np.hypot(cen[:, 0], cen[:, 1])
    bridge_zone = (np.abs(cen[:, 0]) < 16) & (cen[:, 1] < -60) & (cen[:, 1] > -175)
    region = np.zeros(n, np.int32)
    region[(rr > 95) & ~bridge_zone] = 1      # the far peaks
    statue = ((np.abs(cen[:, 0]) < 6.5) & (cen[:, 1] < -99.5) & (cen[:, 1] > -112.5) & (cen[:, 2] > 30.2)
              & np.isin(final, ["stone", "rock", "foliage", "dark", "wood"]))
    final[statue] = "statue"
    final[face_kind == "glow_vc"] = "glow"
    final[face_kind == "glow_param"] = "glow"
    final[face_kind == "leaf"] = "foliage"
    for kd in ("dragon_cinder_scale", "dragon_frost_scale", "dragon_cinder_membrane", "dragon_frost_membrane"):
        final[face_kind == kd] = kd
    final[face_kind == "banner"] = np.array(["banner:" + kinds[k][2] for k in mi[face_kind == "banner"]], dtype=object)
    region[(face_kind == "banner") | (final == "cloth_wave")] = 2     # waving cloth
    region[final == "statue"] = 3
    region[final == "falls"] = 4
    ra = me.attributes.get("region") or me.attributes.new("region", "INT", "FACE")
    ra.data.foreach_set("value", region)
    # write the colours back
    ca.data.foreach_set("color", lc.ravel())
    # material slots
    names = sorted(set(final.tolist()))
    slot_mats = []
    for nm in names:
        if nm == "hide":
            slot_mats.append(None)
        elif nm.startswith("banner:"):
            src = nm.split(":", 1)[1]
            if src not in banner_mats:
                banner_mats[src] = mat_banner("M_banner_" + src[-12:], minfo.get(src, {}))
            slot_mats.append(banner_mats[src])
        elif nm.startswith("dragon_"):
            key = nm.replace("dragon_cinder_", "dragon_cinder_").replace("dragon_frost_", "dragon_frost_")
            slot_mats.append(MATS.get(key) or MATS["dark"])
        else:
            slot_mats.append(MATS[nm])
    me.materials.clear()
    for m in slot_mats:
        me.materials.append(m)
    lut = {nm: k for k, nm in enumerate(names)}
    new_mi = np.array([lut[x] for x in final], np.int32)
    me.polygons.foreach_set("material_index", new_mi)
    me.update()
    counts = {nm: int((final == nm).sum()) for nm in names}
    if "hide" in lut:
        hide_idx = lut["hide"]
        bm = bmesh.new()
        bm.from_mesh(me)
        dead = [f for f in bm.faces if f.material_index == hide_idx]
        bmesh.ops.delete(bm, geom=dead, context="FACES")
        bm.to_mesh(me)
        bm.free()
        me.update()
    return counts


def split_region(obj, value, name):
    """Moves the faces whose `region` attribute == value into a new object (same materials). None if empty."""
    me = obj.data
    ra = me.attributes.get("region")
    if ra is None:
        return None
    reg = np.empty(len(me.polygons), np.int32)
    ra.data.foreach_get("value", reg)
    if not (reg == value).any():
        return None
    dup = obj.copy()
    dup.data = me.copy()
    dup.name = name
    dup.data.name = name
    for c in obj.users_collection:
        c.objects.link(dup)
    for tgt, keep in ((dup, True), (obj, False)):
        bm = bmesh.new()
        bm.from_mesh(tgt.data)
        lay = bm.faces.layers.int.get("region")
        dead = [f for f in bm.faces if (f[lay] == value) != keep]
        bmesh.ops.delete(bm, geom=dead, context="FACES")
        loose = [v for v in bm.verts if not v.link_faces]
        bmesh.ops.delete(bm, geom=loose, context="VERTS")
        bm.to_mesh(tgt.data)
        bm.free()
        tgt.data.update()
    return dup


def convert_color(me, ca):
    nl = len(me.loops)
    if ca.domain == "CORNER":
        c = np.empty(nl * 4, np.float32)
        ca.data.foreach_get("color", c)
    else:
        pv = np.empty(len(me.vertices) * 4, np.float32)
        ca.data.foreach_get("color", pv)
        lv = np.empty(nl, np.int32)
        me.loops.foreach_get("vertex_index", lv)
        c = pv.reshape(-1, 4)[lv].ravel()
    name = ca.name
    me.color_attributes.remove(ca)
    nca = me.color_attributes.new(name, "FLOAT_COLOR", "CORNER")
    nca.data.foreach_set("color", c)
    return nca


# ============================================================================================ import
def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.name = "Citadel"
    sc["glow_gain"] = 2.5
    sc["dusk"] = 0.0
    sc["sun_elev"] = 8.5
    return sc


def import_glb(path, collection_name):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path, merge_vertices=False)
    new = [o for o in bpy.data.objects if o not in before]
    col = bpy.data.collections.get(collection_name) or bpy.data.collections.new(collection_name)
    if col.name not in bpy.context.scene.collection.children:
        bpy.context.scene.collection.children.link(col)
    for o in new:
        for c in list(o.users_collection):
            c.objects.unlink(o)
        col.objects.link(o)
    return new


def import_citadel():
    t0 = time.time()
    objs = import_glb(os.path.join(EXPORT, "citadel.glb"), "Citadel")
    minfo = json.load(open(os.path.join(EXPORT, "materials.json"), encoding="utf-8"))
    banner_mats = {}
    report = {}
    keep = []
    empties = [o.name for o in objs if o.type == "EMPTY"]
    for o in objs:
        if o.type != "MESH":
            continue
        if o.name.startswith("Ground"):
            bpy.data.objects.remove(o)
            continue
        report[o.name] = process_mesh(o, minfo, banner_mats)
        keep.append(o)
    # flatten: meshes keep their world transform, empties go
    for o in keep:
        mw = o.matrix_world.copy()
        o.parent = None
        o.matrix_world = mw
    for nm in empties:
        if nm in bpy.data.objects:
            bpy.data.objects.remove(bpy.data.objects[nm])
    scatter = next(o for o in keep if o.name.startswith("Scatter"))
    parts = {}
    for value, name in ((1, "Peaks"), (2, "Banners"), (3, "Statue"), (4, "Falls")):
        ob = split_region(scatter, value, name)
        if ob is not None:
            parts[name] = ob
            keep.append(ob)
    if "Banners" in parts:
        add_cloth_wave(parts["Banners"])
    if "Peaks" in parts:
        # the game's low-poly far peaks read as crude cones at film resolution: off (toggle hide_render to see them)
        parts["Peaks"].hide_render = True
        parts["Peaks"].hide_viewport = True
    dress_master(keep)
    log(f"citadel imported + classified in {time.time() - t0:.1f} s: " + json.dumps(report))
    return keep


def mat_robe():
    m, nt = new_mat("M_robe")
    vc = vcol(nt)
    folds = noise(nt, 2.2, 3, 0.5, y=-400)
    col = mix_col(nt, 0.55, vc, (0.10, 0.06, 0.16, 1), x=-200, y=100)
    nrm = bump(nt, folds, 0.4, 0.1, x=0, y=-400)
    p = principled(nt, 250, 0, Base_Color=col, Roughness=0.72, Normal=nrm)
    p.inputs["Sheen Weight"].default_value = 1.0
    p.inputs["Sheen Roughness"].default_value = 0.35
    p.inputs["Sheen Tint"].default_value = (0.85, 0.7, 1.0, 1)
    mat_out(nt, p.outputs[0], 550, 0)
    return m


def dress_master(objs):
    """The Master stand-in (puppet): a deep violet robe with sheen instead of stone/brick classes; his glow stays."""
    robe = mat_robe()
    for o in objs:
        if o.type != "MESH" or not o.name.startswith("Mesh"):
            continue
        c = o.matrix_world @ (sum((Vector(b) for b in o.bound_box), Vector()) / 8.0)
        if (c - Vector((-13.0, 1.4, 49.5))).length > 4.0:
            continue
        for k, m in enumerate(o.data.materials):
            if m is not None and m.name not in ("M_glow",):
                o.data.materials[k] = robe
        log("master dressed:", o.name)


def add_cloth_wave(ob):
    """Banners wave like the game's shader: offset along the normal, weight = UV.x (0 at the pole / top edge)."""
    g = bpy.data.node_groups.new("ClothWave", "GeometryNodeTree")
    g.interface.new_socket("Geometry", in_out="OUTPUT", socket_type="NodeSocketGeometry")
    g.interface.new_socket("Geometry", in_out="INPUT", socket_type="NodeSocketGeometry")
    nt = g
    gi = N(nt, "NodeGroupInput", -1200, 0)
    go = N(nt, "NodeGroupOutput", 600, 0)
    uv = N(nt, "GeometryNodeInputNamedAttribute", -1200, -300, data_type="FLOAT_VECTOR")
    uv.inputs["Name"].default_value = "UVMap"
    sep = N(nt, "ShaderNodeSeparateXYZ", -1000, -300)
    L(nt, uv.outputs["Attribute"], sep.inputs[0])
    w = math_node(nt, "MINIMUM", sep.outputs["X"], 1.5, x=-850, y=-300)
    pos = N(nt, "GeometryNodeInputPosition", -1200, -600)
    ps = N(nt, "ShaderNodeSeparateXYZ", -1000, -600)
    L(nt, pos.outputs[0], ps.inputs[0])
    ph = math_node(nt, "ADD", math_node(nt, "MULTIPLY", ps.outputs["X"], 0.9, x=-850, y=-550),
                   math_node(nt, "MULTIPLY", ps.outputs["Y"], 0.7, x=-850, y=-650), x=-700, y=-600)
    t = N(nt, "GeometryNodeInputSceneTime", -1200, -900)
    arg = math_node(nt, "ADD", math_node(nt, "ADD", math_node(nt, "MULTIPLY", t.outputs["Seconds"], 3.1, x=-850, y=-900), ph,
                                                  x=-550, y=-750), math_node(nt, "MULTIPLY", w, 4.0, x=-700, y=-400), x=-400, y=-600)
    amp = math_node(nt, "MULTIPLY", math_node(nt, "SINE", arg, x=-250, y=-600), math_node(nt, "MULTIPLY", w, 0.32, x=-400, y=-350),
                    x=-100, y=-500)
    nrm = N(nt, "GeometryNodeInputNormal", -250, -800)
    off = N(nt, "ShaderNodeVectorMath", 50, -600, operation="SCALE")
    L(nt, nrm.outputs[0], off.inputs[0])
    L(nt, amp, off.inputs["Scale"])
    sp = N(nt, "GeometryNodeSetPosition", 300, 0)
    L(nt, gi.outputs[0], sp.inputs["Geometry"])
    L(nt, off.outputs[0], sp.inputs["Offset"])
    L(nt, sp.outputs[0], go.inputs[0])
    mod = ob.modifiers.new("wave", "NODES")
    mod.node_group = g


# ============================================================================================ world, sky, fog
def scene_driver(owner, path, index, expr, props, sc=None):
    """Driver on owner.path[index] reading scene custom properties (props = names used as variables)."""
    fc = owner.driver_add(path, index) if index is not None else owner.driver_add(path)
    d = fc.driver
    d.type = "SCRIPTED"
    for pname in props:
        v = d.variables.new()
        v.name = pname
        v.targets[0].id_type = "SCENE"
        v.targets[0].id = sc or bpy.data.scenes["Citadel"]
        v.targets[0].data_path = f'["{pname}"]'
    d.expression = expr
    return d


def dusk_mix(nt, day, dusk_col, x, y):
    """Colour that goes from `day` to `dusk_col` with the scene's dusk cue."""
    return mix_col(nt, drv_value(nt, "dusk", x=x - 200, y=y - 100), day, dusk_col, x=x, y=y)


def build_world(sc):
    """Art-directed sunset sky (gradient zenith -> horizon, warm towards the sun, a belt of pink-lavender away from
    it, a two-lobe sun glow + disc) with a painted alto-cumulus layer; every colour slides to blue hour with the
    `dusk` cue (0 = sunset, 1 = after the Master is gone)."""
    w = bpy.data.worlds.new("Sunset")
    sc.world = w
    try:
        w.use_nodes = True
    except Exception:
        pass
    nt = w.node_tree
    nt.nodes.clear()
    az = SUN_AZIMUTH
    tc = N(nt, "ShaderNodeTexCoord", -2200, 0)
    dn = N(nt, "ShaderNodeVectorMath", -2000, 0, operation="NORMALIZE")
    L(nt, tc.outputs["Generated"], dn.inputs[0])
    d = dn.outputs[0]
    sep = N(nt, "ShaderNodeSeparateXYZ", -1800, 0)
    L(nt, d, sep.inputs[0])
    dz = sep.outputs["Z"]
    sun_dir = N(nt, "ShaderNodeCombineXYZ", -1800, -500)
    exprs = (f"sin({az})*cos(radians(e))", f"cos({az})*cos(radians(e))", "sin(radians(e))")
    for k in range(3):
        dd = sun_dir.inputs[k].driver_add("default_value").driver
        var = dd.variables.new()
        var.name = "e"
        var.targets[0].id_type = "SCENE"
        var.targets[0].id = sc
        var.targets[0].data_path = '["sun_elev"]'
        dd.expression = exprs[k]
    cosang = N(nt, "ShaderNodeVectorMath", -1600, -500, operation="DOT_PRODUCT")
    L(nt, d, cosang.inputs[0])
    L(nt, sun_dir.outputs[0], cosang.inputs[1])
    cosv = out(cosang, "Value")
    # azimuth closeness to the sun (horizontal only)
    hxy = N(nt, "ShaderNodeCombineXYZ", -1600, -200)
    L(nt, sep.outputs["X"], hxy.inputs[0])
    L(nt, sep.outputs["Y"], hxy.inputs[1])
    hn = N(nt, "ShaderNodeVectorMath", -1450, -200, operation="NORMALIZE")
    L(nt, hxy.outputs[0], hn.inputs[0])
    sazv = N(nt, "ShaderNodeCombineXYZ", -1450, -350)
    sazv.inputs[0].default_value = math.sin(az)
    sazv.inputs[1].default_value = math.cos(az)
    hd = N(nt, "ShaderNodeVectorMath", -1300, -250, operation="DOT_PRODUCT")
    L(nt, hn.outputs[0], hd.inputs[0])
    L(nt, sazv.outputs[0], hd.inputs[1])
    close = math_node(nt, "POWER", math_node(nt, "ADD", math_node(nt, "MULTIPLY", out(hd, "Value"), 0.5, x=-1150, y=-250),
                                             0.5, x=-1050, y=-250), 2.2, x=-950, y=-250)
    # elevation gradient
    t = math_node(nt, "POWER", math_node(nt, "MAXIMUM", dz, 0.0, x=-1400, y=150), 0.42, x=-1250, y=150)
    toward = dusk_mix(nt, (2.6, 1.02, 0.32, 1), (0.30, 0.07, 0.07, 1), -900, 500)
    away = dusk_mix(nt, (0.27, 0.30, 0.56, 1), (0.04, 0.04, 0.11, 1), -900, 300)
    zen = dusk_mix(nt, (0.04, 0.085, 0.30, 1), (0.008, 0.012, 0.045, 1), -900, 100)
    horiz = mix_col(nt, close, away, toward, x=-650, y=400)
    # a second, lower band of orange right at the horizon towards the sun
    band = math_node(nt, "MULTIPLY", math_node(nt, "SUBTRACT", 1.0, math_node(nt, "POWER", math_node(nt, "MAXIMUM", dz, 0.0,
                     x=-1000, y=700), 0.25, x=-850, y=700), x=-700, y=700), close, x=-550, y=700)
    base = mix_col(nt, t, horiz, zen, x=-450, y=300)
    band_col = dusk_mix(nt, (1.6, 0.52, 0.12, 1), (0.20, 0.04, 0.04, 1), -450, 750)
    base = mix_col(nt, math_node(nt, "MULTIPLY", band, 0.6, x=-300, y=700), base, band_col, blend="ADD", x=-250, y=400)
    # below the horizon (beyond the cloud sea): a hazy ground colour
    below = ramp(nt, dz, [(-0.08, (1, 1, 1, 1)), (0.0, (0, 0, 0, 1))], x=-450, y=0)
    below_bw = N(nt, "ShaderNodeRGBToBW", -250, 0)
    L(nt, below, below_bw.inputs[0])
    ground = dusk_mix(nt, (0.24, 0.22, 0.32, 1), (0.02, 0.02, 0.04, 1), -250, -150)
    base = mix_col(nt, below_bw.outputs[0], base, ground, x=-50, y=300)
    # sun glow: broad mie lobe + tight core + disc, all off at dusk
    c = math_node(nt, "MAXIMUM", cosv, 0.0, x=-1400, y=-700)
    lobe_a = math_node(nt, "POWER", c, 7.0, x=-1250, y=-700)
    lobe_b = math_node(nt, "POWER", c, 90.0, x=-1250, y=-850)
    disc = math_node(nt, "GREATER_THAN", cosv, math.cos(math.radians(0.75)), x=-1250, y=-1000)
    ga = dusk_mix(nt, (2.6, 0.95, 0.30, 1), (0.25, 0.04, 0.03, 1), -900, -600)
    gb = dusk_mix(nt, (9.0, 4.0, 1.4, 1), (0.0, 0.0, 0.0, 1), -900, -800)
    gd = dusk_mix(nt, (90.0, 50.0, 22.0, 1), (0.0, 0.0, 0.0, 1), -900, -1000)
    glow = mix_col(nt, lobe_a, (0, 0, 0, 1), ga, x=-650, y=-600)
    glow = mix_col(nt, 1.0, glow, mix_col(nt, lobe_b, (0, 0, 0, 1), gb, x=-650, y=-800), blend="ADD", x=-450, y=-650)
    glow = mix_col(nt, 1.0, glow, mix_col(nt, disc, (0, 0, 0, 1), gd, x=-650, y=-1000), blend="ADD", x=-300, y=-700)
    sky = mix_col(nt, 1.0, base, glow, blend="ADD", x=100, y=0)
    # stars come out at blue hour, high in the sky
    sv = N(nt, "ShaderNodeTexVoronoi", -900, -2300, voronoi_dimensions="3D", feature="F1")
    L(nt, d, sv.inputs["Vector"])
    sv.inputs["Scale"].default_value = 260.0
    star = math_node(nt, "LESS_THAN", sv.outputs["Distance"], 0.035, x=-700, y=-2300)
    high = ramp(nt, dz, [(0.12, (0, 0, 0, 1)), (0.45, (1, 1, 1, 1))], x=-700, y=-2500)
    hbw2 = N(nt, "ShaderNodeRGBToBW", -500, -2500)
    L(nt, high, hbw2.inputs[0])
    dusk_s = math_node(nt, "POWER", drv_value(nt, "dusk", x=-700, y=-2700), 3.0, x=-500, y=-2700)
    sfac = math_node(nt, "MULTIPLY", math_node(nt, "MULTIPLY", star, hbw2.outputs[0], x=-350, y=-2400), dusk_s, x=-200, y=-2500)
    sky = mix_col(nt, math_node(nt, "MULTIPLY", sfac, 1.0, x=-50, y=-2500), sky, (2.2, 2.3, 2.6, 1), blend="ADD", x=150, y=-150)
    # painted cloud layer: the view direction projected on a plane
    zc = math_node(nt, "MAXIMUM", dz, 0.02, x=-1400, y=-1300)
    px = math_node(nt, "DIVIDE", sep.outputs["X"], zc, x=-1250, y=-1250)
    py = math_node(nt, "DIVIDE", sep.outputs["Y"], zc, x=-1250, y=-1350)
    cp = N(nt, "ShaderNodeCombineXYZ", -1100, -1300)
    L(nt, px, cp.inputs[0])
    L(nt, py, cp.inputs[1])
    mp = N(nt, "ShaderNodeMapping", -950, -1300)
    L(nt, cp.outputs[0], mp.inputs[0])
    mp.inputs["Scale"].default_value = (0.9, 2.4, 1.0)    # streaky alto-cumulus
    mp.inputs["Rotation"].default_value = (0, 0, math.radians(25))
    dl = mp.inputs["Location"].driver_add("default_value", 0).driver
    dl.expression = "frame*0.0015"
    cn = N(nt, "ShaderNodeTexNoise", -750, -1300, noise_dimensions="3D")
    L(nt, mp.outputs[0], cn.inputs["Vector"])
    cn.inputs["Scale"].default_value = 1.2
    cn.inputs["Detail"].default_value = 9.0
    cn.inputs["Roughness"].default_value = 0.62
    cn.inputs["Distortion"].default_value = 0.3
    dens = ramp(nt, cn.outputs["Fac"], [(0.50, (0, 0, 0, 1)), (0.66, (1, 1, 1, 1))], x=-550, y=-1300)
    dens_bw = N(nt, "ShaderNodeRGBToBW", -350, -1300)
    L(nt, dens, dens_bw.inputs[0])
    horizon = ramp(nt, dz, [(0.02, (0, 0, 0, 1)), (0.10, (1, 1, 1, 1)), (0.55, (0.6, 0.6, 0.6, 1)), (0.9, (0, 0, 0, 1))],
                   x=-550, y=-1550)
    hbw = N(nt, "ShaderNodeRGBToBW", -350, -1550)
    L(nt, horizon, hbw.inputs[0])
    amount = math_node(nt, "MULTIPLY", dens_bw.outputs[0], hbw.outputs[0], x=-150, y=-1400)
    near = ramp(nt, math_node(nt, "ADD", math_node(nt, "MULTIPLY", cosv, 0.5, x=-750, y=-1800), 0.5, x=-650, y=-1800),
                [(0.0, (0.22, 0.21, 0.36, 1)), (0.5, (0.72, 0.44, 0.44, 1)), (0.8, (1.7, 0.80, 0.36, 1)),
                 (1.0, (3.2, 1.8, 0.8, 1))], x=-500, y=-1800)
    lit = mix_col(nt, drv_value(nt, "dusk", x=-500, y=-2050), near, (0.09, 0.05, 0.13, 1), x=-250, y=-1800)
    cloud_col = N(nt, "ShaderNodeVectorMath", -50, -1800, operation="SCALE")
    L(nt, lit, cloud_col.inputs[0])
    L(nt, drv_value(nt, "cloud_gain", x=-250, y=-2050), cloud_col.inputs["Scale"])
    final = mix_col(nt, amount, sky, cloud_col.outputs[0], x=300, y=0)
    gain = N(nt, "ShaderNodeVectorMath", 500, 0, operation="SCALE")
    L(nt, final, gain.inputs[0])
    L(nt, drv_value(nt, "sky_gain", x=300, y=-200), gain.inputs["Scale"])
    lp = N(nt, "ShaderNodeLightPath", 300, 400)
    light = N(nt, "ShaderNodeVectorMath", 500, 250, operation="SCALE")
    L(nt, gain.outputs[0], light.inputs[0])
    L(nt, drv_value(nt, "sky_light", x=300, y=150), light.inputs["Scale"])
    seen = mix_col(nt, lp.outputs["Is Camera Ray"], light.outputs[0], gain.outputs[0], x=600, y=200)
    bg = N(nt, "ShaderNodeBackground", 700, 0)
    L(nt, seen, bg.inputs["Color"])
    bg.inputs["Strength"].default_value = 1.0
    wo = N(nt, "ShaderNodeOutputWorld", 900, 0)
    L(nt, bg.outputs[0], wo.inputs["Surface"])
    # (no world volume: EEVEE in Blender 5.2 renders black with any world volume; the haze is an object volume,
    # build_atmosphere)
    sc["sky_gain"] = 1.0
    sc["sky_light"] = 0.45
    sc["cloud_gain"] = 1.0
    return w


def sky_sun_rotation():
    """Sky texture sun_rotation: the sun's compass angle clockwise from +Y (measured: 0 = +Y, 90 deg = +X), the
    same convention as SUN_AZIMUTH."""
    return SUN_AZIMUTH


def build_sun(sc):
    ld = bpy.data.lights.new("Sun", "SUN")
    ld.angle = math.radians(1.2)
    ld.color = (1.0, 0.72, 0.46)
    ld.energy = 6.0
    try:
        ld.use_shadow = True
    except Exception:
        pass
    so = bpy.data.objects.new("Sun", ld)
    sc.collection.objects.link(so)
    # rotation driven by the elevation cue: the lamp's -Z points from the sun to the scene
    so.rotation_mode = "XYZ"
    az = SUN_AZIMUTH
    # towards-sun t = (sin az cos e, cos az cos e, sin e); lamp -Z = -t -> X rot = 90deg - e about a yawed frame
    for k in range(3):
        d = so.driver_add("rotation_euler", k).driver
        v = d.variables.new()
        v.name = "e"
        v.targets[0].id_type = "SCENE"
        v.targets[0].id = sc
        v.targets[0].data_path = '["sun_elev"]'
        d.expression = ("radians(90.0 - e)", "0.0", f"{-az} + pi")[k]
    return so


def build_cloud_sea(sc):
    """A 12 km sea of cumulus around the mountain (Geometry Nodes, static): radial grid dense near the citadel,
    layered smooth-Voronoi puffs, flatter and bigger far away, a dip where the mountain rises."""
    me = bpy.data.meshes.new("CloudSea")
    ob = bpy.data.objects.new("CloudSea", me)
    col = bpy.data.collections.get("Atmosphere") or bpy.data.collections.new("Atmosphere")
    if col.name not in sc.collection.children:
        sc.collection.children.link(col)
    col.objects.link(ob)
    g = bpy.data.node_groups.new("CloudSeaGN", "GeometryNodeTree")
    g.interface.new_socket("Geometry", in_out="OUTPUT", socket_type="NodeSocketGeometry")
    g.interface.new_socket("Geometry", in_out="INPUT", socket_type="NodeSocketGeometry")
    nt = g
    go = N(nt, "NodeGroupOutput", 1800, 0)
    grid = N(nt, "GeometryNodeMeshGrid", -1600, 0)
    grid.inputs["Size X"].default_value = 2.0
    grid.inputs["Size Y"].default_value = 2.0
    grid.inputs["Vertices X"].default_value = 700
    grid.inputs["Vertices Y"].default_value = 700
    pos = N(nt, "GeometryNodeInputPosition", -1600, -300)
    # radial remap p' = p * |p|^0.9 * R  (|p'| = |p|^1.9 * R)
    ln = N(nt, "ShaderNodeVectorMath", -1400, -300, operation="LENGTH")
    L(nt, pos.outputs[0], ln.inputs[0])
    fac = math_node(nt, "MULTIPLY", math_node(nt, "POWER", out(ln, "Value"), 0.9, x=-1250, y=-350), 6000.0, x=-1100, y=-350)
    sp = N(nt, "ShaderNodeVectorMath", -950, -300, operation="SCALE")
    L(nt, pos.outputs[0], sp.inputs[0])
    L(nt, fac, sp.inputs["Scale"])
    # heights from the remapped xy
    r = N(nt, "ShaderNodeVectorMath", -800, -500, operation="LENGTH")
    L(nt, sp.outputs[0], r.inputs[0])
    # domain warp so the cells are not a regular pattern
    wn = N(nt, "ShaderNodeTexNoise", -900, -1100, noise_dimensions="3D")
    L(nt, sp.outputs[0], wn.inputs["Vector"])
    wn.inputs["Scale"].default_value = 1 / 320.0
    wn.inputs["Detail"].default_value = 2.0
    wsub = N(nt, "ShaderNodeVectorMath", -750, -1100, operation="SUBTRACT")
    L(nt, wn.outputs["Color"], wsub.inputs[0])
    wsub.inputs[1].default_value = (0.5, 0.5, 0.5)
    wsc = N(nt, "ShaderNodeVectorMath", -650, -1100, operation="SCALE")
    L(nt, wsub.outputs[0], wsc.inputs[0])
    wsc.inputs["Scale"].default_value = 140.0
    warped = N(nt, "ShaderNodeVectorMath", -550, -1000, operation="ADD")
    L(nt, sp.outputs[0], warped.inputs[0])
    L(nt, wsc.outputs[0], warped.inputs[1])
    hsum = None
    for k, (scale, amp) in enumerate(((1 / 210.0, 30.0), (1 / 68.0, 12.0), (1 / 21.0, 4.0), (1 / 7.0, 1.1))):
        vo = N(nt, "ShaderNodeTexVoronoi", -400, -700 - k * 260, voronoi_dimensions="2D", feature="SMOOTH_F1")
        vo.inputs["Scale"].default_value = scale
        vo.inputs["Smoothness"].default_value = 1.0
        vo.inputs["Randomness"].default_value = 1.0
        L(nt, warped.outputs[0], vo.inputs["Vector"])
        one_m = math_node(nt, "SUBTRACT", 1.0, vo.outputs["Distance"], x=-250, y=-700 - k * 260, clamp=True)
        puff = math_node(nt, "MULTIPLY", math_node(nt, "POWER", one_m, 1.8, x=-150, y=-700 - k * 260), amp,
                         x=-60, y=-700 - k * 260)
        hsum = puff if hsum is None else math_node(nt, "ADD", hsum, puff, x=30, y=-700 - k * 260)
    patch = N(nt, "ShaderNodeTexNoise", -400, -1800, noise_dimensions="3D")
    L(nt, sp.outputs[0], patch.inputs["Vector"])
    patch.inputs["Scale"].default_value = 1 / 900.0
    patch.inputs["Detail"].default_value = 1.0
    pm = N(nt, "ShaderNodeMapRange", -200, -1800)
    L(nt, patch.outputs["Fac"], pm.inputs["Value"])
    pm.inputs["From Min"].default_value = 0.35
    pm.inputs["From Max"].default_value = 0.65
    pm.inputs["To Min"].default_value = 0.45
    pm.inputs["To Max"].default_value = 1.35
    hsum = math_node(nt, "MULTIPLY", hsum, pm.outputs["Result"], x=100, y=-1500)
    # far = flatter (fade the puffs beyond 900 m), near the mountain: dip below the citadel's rock
    far = N(nt, "ShaderNodeMapRange", -500, -1500)
    L(nt, out(r, "Value"), far.inputs["Value"])
    far.inputs["From Min"].default_value = 600.0
    far.inputs["From Max"].default_value = 3500.0
    far.inputs["To Min"].default_value = 1.0
    far.inputs["To Max"].default_value = 0.35
    h = math_node(nt, "MULTIPLY", hsum, far.outputs["Result"], x=0, y=-900)
    h = math_node(nt, "SUBTRACT", h, 20.0, x=120, y=-900)
    cz = N(nt, "ShaderNodeCombineXYZ", 300, -600)
    sxy = N(nt, "ShaderNodeSeparateXYZ", -800, -300)
    L(nt, sp.outputs[0], sxy.inputs[0])
    L(nt, sxy.outputs["X"], cz.inputs[0])
    L(nt, sxy.outputs["Y"], cz.inputs[1])
    L(nt, h, cz.inputs[2])
    setp = N(nt, "GeometryNodeSetPosition", 600, 0)
    L(nt, grid.outputs[0], setp.inputs["Geometry"])
    L(nt, cz.outputs[0], setp.inputs["Position"])
    smooth = N(nt, "GeometryNodeSetShadeSmooth", 900, 0)
    L(nt, setp.outputs[0], smooth.inputs["Geometry"])
    setm = N(nt, "GeometryNodeSetMaterial", 1200, 0)
    L(nt, smooth.outputs[0], setm.inputs["Geometry"])
    setm.inputs["Material"].default_value = mat_cloud("M_cloud_sea")
    L(nt, setm.outputs[0], go.inputs[0])
    mod = ob.modifiers.new("CloudSea", "NODES")
    mod.node_group = g
    return ob


def build_cumulus(sc):
    """A skyline of towering cumulus 3.5-5 km out, mostly on the sunset side (back-lit, west) and north (the SH11
    horizon): each tower is a cauliflower of displaced spheres whose bases sink into the sea of clouds."""
    import random
    rnd = random.Random(27)
    col = bpy.data.collections["Atmosphere"]
    mat = mat_cloud("M_cloud_tower", height_tint=False)
    t1 = bpy.data.textures.new("cumulus_big", "CLOUDS")
    t1.noise_scale = 0.5
    t1.noise_depth = 2
    t2 = bpy.data.textures.new("cumulus_billow", "CLOUDS")
    t2.noise_scale = 0.13
    t2.noise_depth = 3
    base = bpy.data.meshes.new("CumulusLobe")
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=4, radius=1.0)
    bm.to_mesh(base)
    bm.free()
    for p_ in base.polygons:
        p_.use_smooth = True
    towers = [(4200, 225, 700, 330), (3800, 250, 820, 380), (4600, 272, 900, 300), (3600, 296, 640, 360),
              (4800, 320, 780, 280), (4100, 346, 700, 340), (5000, 14, 950, 300), (4500, 200, 600, 260),
              (5200, 110, 800, 220)]
    n = 0
    for k, (dist, az, w, h) in enumerate(towers):
        cx, cy = dist * math.sin(math.radians(az)), dist * math.cos(math.radians(az))
        lobes = [(0.0, 0.0, 0.0, 1.0)] + [(rnd.uniform(-0.45, 0.45), rnd.uniform(-0.3, 0.3), rnd.uniform(-0.25, 0.35),
                                          rnd.uniform(0.45, 0.75)) for _ in range(5)]
        for j, (ox, oy, oz, sz) in enumerate(lobes):
            ob = bpy.data.objects.new(f"Cumulus{k}_{j}", base)
            col.objects.link(ob)
            ob.location = (cx + ox * w, cy + oy * w, -40 + h * (0.45 + oz))
            ob.scale = (w * 0.5 * sz, w * 0.45 * sz, h * 0.55 * sz)
            ob.rotation_euler = (0, 0, rnd.uniform(0, 6.28))
            for tex, st in ((t1, 0.5), (t2, 0.16)):
                dm = ob.modifiers.new(tex.name, "DISPLACE")
                dm.texture = tex
                dm.texture_coords = "LOCAL"
                dm.strength = st
                dm.mid_level = 0.45
            if not ob.data.materials:
                ob.data.materials.append(mat)
            ob.visible_shadow = False
            n += 1
    log(f"cumulus: {len(towers)} towers, {n} lobes")


def build_atmosphere(sc):
    """One volume box (12 x 12 km, z -40 .. 700) = two scattering layers added:
    haze   aerial perspective + god rays, forward scattering, thins with height (keyed per shot: "fog"),
    layer  the dense mist sitting on the cloud sea (z < 26 m) that swallows the troughs ("fog_layer")."""
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    ob = bpy.context.active_object
    ob.name = "Atmosphere"
    ob.scale = (12000, 12000, 740)
    ob.location = (0, 0, 330)
    for c in list(ob.users_collection):
        c.objects.unlink(ob)
    bpy.data.collections["Atmosphere"].objects.link(ob)
    ob.visible_shadow = False
    m, nt = new_mat("M_atmosphere", method="BLENDED")
    geo = N(nt, "ShaderNodeNewGeometry", -1000, 0)
    sep = N(nt, "ShaderNodeSeparateXYZ", -800, 0)
    L(nt, geo.outputs["Position"], sep.inputs[0])
    # haze: fog * (0.35 + 0.65 * exp(-z / 140))
    ez = math_node(nt, "EXPONENT", math_node(nt, "DIVIDE", sep.outputs["Z"], -140.0, x=-600, y=200), x=-450, y=200)
    hz = math_node(nt, "ADD", math_node(nt, "MULTIPLY", ez, 0.65, x=-300, y=200), 0.35, x=-150, y=200)
    haze_d = math_node(nt, "MULTIPLY", hz, drv_value(nt, "fog", x=-300, y=400), x=0, y=250)
    haze = N(nt, "ShaderNodeVolumePrincipled", 250, 250)
    haze.inputs["Color"].default_value = (1.0, 0.92, 0.82, 1)
    haze.inputs["Absorption Color"].default_value = (0.9, 0.86, 0.9, 1)
    haze.inputs["Anisotropy"].default_value = 0.6
    L(nt, haze_d, haze.inputs["Density"])
    # mist layer on the cloud sea
    dens = N(nt, "ShaderNodeMapRange", -600, -200)
    L(nt, sep.outputs["Z"], dens.inputs["Value"])
    dens.inputs["From Min"].default_value = -12.0
    dens.inputs["From Max"].default_value = 26.0
    dens.inputs["To Min"].default_value = 1.0
    dens.inputs["To Max"].default_value = 0.0
    sq = math_node(nt, "POWER", dens.outputs["Result"], 2.0, x=-400, y=-200)
    wisp = noise(nt, 1 / 45.0, 4, 0.55, coord=geo.outputs["Position"], x=-600, y=-500)
    wisp = math_node(nt, "ADD", math_node(nt, "MULTIPLY", wisp, 1.6, x=-450, y=-500), -0.25, x=-350, y=-500, clamp=True)
    sq = math_node(nt, "MULTIPLY", sq, wisp, x=-300, y=-300)
    layer_d = math_node(nt, "MULTIPLY", sq, drv_value(nt, "fog_layer", x=-400, y=-400), x=-200, y=-250)
    mist = N(nt, "ShaderNodeVolumePrincipled", 250, -250)
    mist.inputs["Color"].default_value = (0.85, 0.8, 0.94, 1)
    mist.inputs["Absorption Color"].default_value = (0.8, 0.78, 0.9, 1)
    mist.inputs["Anisotropy"].default_value = 0.25
    L(nt, layer_d, mist.inputs["Density"])
    add = N(nt, "ShaderNodeAddShader", 550, 0)
    L(nt, haze.outputs[0], add.inputs[0])
    L(nt, mist.outputs[0], add.inputs[1])
    mat_out(nt, None, 800, 0, volume=add.outputs[0])
    ob.data.materials.append(m)
    sc["fog"] = 0.00025
    sc["fog_layer"] = 0.006
    return ob


# ============================================================================================ render setup
def setup_render(sc, res=RES):
    sc.render.engine = "BLENDER_EEVEE"
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.render.resolution_percentage = 100
    sc.render.fps = FPS
    sc.frame_start, sc.frame_end = 1, FRAMES
    e = sc.eevee
    e.taa_render_samples = 64
    e.use_raytracing = True
    e.ray_tracing_method = "SCREEN"
    e.ray_tracing_options.resolution_scale = "2"
    e.use_shadows = True
    e.shadow_pool_size = "1024"
    e.shadow_resolution_scale = 1.0
    e.use_volumetric_shadows = True
    e.volumetric_tile_size = "8"
    e.volumetric_samples = 128
    e.volumetric_start = 1.0
    e.volumetric_end = 6000.0
    e.volumetric_sample_distribution = 1.0    # log slices: interiors (hall, dome) get fine froxels near the lens
    e.volumetric_light_clamp = 0.0
    e.use_fast_gi = True
    e.fast_gi_method = "GLOBAL_ILLUMINATION"
    e.bokeh_max_size = 60.0
    sc.render.use_motion_blur = True
    sc.render.motion_blur_shutter = 0.5
    try:
        sc.render.motion_blur_position = "START"
    except Exception:
        pass
    e.motion_blur_steps = 1
    sc.render.film_transparent = False
    sc.render.filter_size = 1.2
    vs = sc.view_settings
    vs.view_transform = "AgX"
    for look in ("AgX - High Contrast", "AgX - Medium High Contrast", "AgX - Base Contrast"):
        try:
            vs.look = look
            break
        except Exception:
            continue
    vs.exposure = 0.0
    sc.render.image_settings.file_format = "PNG"


# ============================================================================================ animation helpers
def iter_fcurves(id_data):
    ad = id_data.animation_data
    if ad is None or ad.action is None:
        return
    act = ad.action
    legacy = getattr(act, "fcurves", None)
    if legacy is not None and len(legacy):
        yield from legacy
        return
    for layer in getattr(act, "layers", []):
        for strip in layer.strips:
            for cb in getattr(strip, "channelbags", []):
                yield from cb.fcurves


def set_interp(id_data, interp="LINEAR", path=None):
    for fc in iter_fcurves(id_data):
        if path is None or fc.data_path == path:
            for kp in fc.keyframe_points:
                kp.interpolation = interp


def key_prop(sc, prop, keys, interp="LINEAR"):
    """keys: [(seconds, value)] on the scene custom property `prop`."""
    for t, v in keys:
        sc[prop] = v
        sc.keyframe_insert(data_path=f'["{prop}"]', frame=f_of(t))
    set_interp(sc, interp, f'["{prop}"]')


def ease(u, a, b):
    """Monotone ease: a = ease-in amount, b = ease-out amount (0 = linear at that end, 1 = full smoothstep)."""
    u = min(1.0, max(0.0, u))
    s = u * u * (3.0 - 2.0 * u)
    w = a if u < 0.5 else b          # both branches meet at u = 0.5 (s = u there)
    return u * (1.0 - w) + s * w


def lerp(a, b, u):
    return Vector(a).lerp(Vector(b), u)


def shake_at(t, amp, seed):
    """Smooth hand-held drift (sum of sines), metres at the look target."""
    if amp <= 0:
        return Vector((0, 0, 0))
    k = seed * 1.7
    return Vector((math.sin(t * 1.9 + k) * 0.6 + math.sin(t * 4.3 + 2 * k) * 0.3,
                   math.sin(t * 1.3 + 3 * k) * 0.3,
                   math.sin(t * 2.3 + k * 0.5) * 0.5 + math.sin(t * 5.1 + k) * 0.25)) * amp


# ============================================================================================ cameras
def build_cameras(sc):
    col = bpy.data.collections.new("Cameras")
    sc.collection.children.link(col)
    sc.timeline_markers.clear()
    for k, s in enumerate(SHOTS):
        f0, f1 = f_of(s["t0"]), f_of(s["t1"]) - 1
        cd = bpy.data.cameras.new("CAM_" + s["id"])
        cd.sensor_fit = "HORIZONTAL"
        cd.sensor_width = 36.0
        cd.clip_start = 0.05 if s["id"] in ("SH07", "SH10", "SH03") else 0.2
        cd.clip_end = 20000.0
        cam = bpy.data.objects.new("CAM_" + s["id"], cd)
        col.objects.link(cam)
        tgt = bpy.data.objects.new("TGT_" + s["id"], None)
        tgt.empty_display_size = 1.0
        col.objects.link(tgt)
        con = cam.constraints.new("TRACK_TO")
        con.target = tgt
        con.track_axis = "TRACK_NEGATIVE_Z"
        con.up_axis = "UP_Y"
        if s.get("fstop"):
            cd.dof.use_dof = True
            cd.dof.aperture_fstop = s["fstop"]
            cd.dof.aperture_blades = 7
            foc = bpy.data.objects.new("FOC_" + s["id"], None)
            col.objects.link(foc)
            if s.get("focus") == "target" or s.get("focus") is None:
                foc.location = Vector(s["look"][0])
                foc.keyframe_insert("location", frame=f0)
                foc.location = Vector(s["look"][1])
                foc.keyframe_insert("location", frame=f1 + 1)
            else:
                foc.location = Vector(s["focus"])
            cd.dof.focus_object = foc
        a, b = s.get("ease", (0.2, 0.2))
        for f in range(f0, f1 + 2):
            u = (f - f0) / max(1, (f1 + 1 - f0))
            e = ease(u, a, b)
            t = (f - 1) / FPS
            cam.location = lerp(s["cam"][0], s["cam"][1], e)
            cam.keyframe_insert("location", frame=f)
            tgt.location = lerp(s["look"][0], s["look"][1], e) + shake_at(t, s.get("shake", 0.0) * 10.0, k + 1)
            tgt.keyframe_insert("location", frame=f)
            cd.lens = s["lens"][0] + (s["lens"][1] - s["lens"][0]) * e
            cd.keyframe_insert("lens", frame=f)
        for idd in (cam, tgt, cd):
            set_interp(idd, "LINEAR")
        m = sc.timeline_markers.new(s["id"], frame=f0)
        m.camera = cam
        s["_cam"] = cam
    sc.camera = SHOTS[0]["_cam"]
    log("cameras:", ", ".join(f'{s["id"]} f{f_of(s["t0"])}-{f_of(s["t1"]) - 1}' for s in SHOTS))


# ============================================================================================ light cues
def build_cues(sc, sun):
    key_prop(sc, "sun_elev", [(0, 8.0), (10, 7.0), (19.25, 5.2), (23.1, 4.2), (26.05, 3.6), (26.5, -2.5), (30, -4.0)])
    key_prop(sc, "dusk", [(0, 0.0), (19.25, 0.06), (26.05, 0.14), (26.55, 0.8), (27.3, 1.0)])
    key_prop(sc, "glow_gain", [(0, 0.7), (15, 1.1), (23.1, 1.8), (26.05, 2.2), (26.6, 7.5), (30, 9.0)])
    ld = sun.data
    t10 = SHOT["SH10"]["t0"]
    for t, e, c in ((0, 8.5, (1.0, 0.71, 0.44)), (19.25, 7.6, (1.0, 0.64, 0.37)), (t10 - 1.0 / FPS, 7.0, (1.0, 0.60, 0.34)),
                    (t10, 2.2, (1.0, 0.60, 0.34)), (26.05, 2.0, (1.0, 0.58, 0.33)), (26.45, 0.0, (1.0, 0.5, 0.3))):
        # (SH10 plays in a darker key: the coloured shafts own the throne hall)
        ld.energy = e
        ld.color = c
        ld.keyframe_insert("energy", frame=f_of(t))
        ld.keyframe_insert("color", frame=f_of(t))
    set_interp(ld, "LINEAR")
    # per-shot looks (constant within a shot): haze, mist on the cloud sea, exposure, sky light
    per = {
        "fog":       dict(SH01=0.0003, SH02=0.0009, SH03=0.0022, SH04=0.0004, SH05=0.0009, SH06=0.0010, SH07=0.0,
                          SH08=0.0004, SH09a=0.0012, SH09b=0.0012, SH09c=0.0012, SH09d=0.0012, SH10=0.0002, SH11=0.00025),
        "fog_layer": dict(SH01=0.006, SH02=0.006, SH03=0.006, SH04=0.008, SH05=0.006, SH06=0.006, SH07=0.006,
                          SH08=0.006, SH09a=0.006, SH09b=0.006, SH09c=0.006, SH09d=0.006, SH10=0.006, SH11=0.004),
        "sky_light": dict(SH01=0.3, SH02=0.34, SH03=0.3, SH04=0.3, SH05=0.3, SH06=0.34, SH07=0.5, SH08=0.3,
                          SH09a=0.28, SH09b=0.28, SH09c=0.28, SH09d=0.28, SH10=0.25, SH11=1.2),
    }
    for prop, vals in per.items():
        keys = [(SHOT[i]["t0"], v) for i, v in vals.items()]
        if prop == "sky_light":
            keys.append((EMPTY_AT + 0.3, 1.3))      # after 'empty': a faint cold sky keeps the empty throne readable
            keys.sort()
        key_prop(sc, prop, keys, interp="CONSTANT")
    exposure = dict(SH01=0.0, SH02=0.0, SH03=0.0, SH04=0.0, SH05=0.0, SH06=0.1, SH07=0.3, SH08=0.0, SH09a=-0.1,
                    SH09b=-0.1, SH09c=-0.1, SH09d=-0.1, SH10=-0.6, SH11=0.8)
    for i, v in exposure.items():
        sc.view_settings.exposure = v
        sc.view_settings.keyframe_insert("exposure", frame=f_of(SHOT[i]["t0"]))
    set_interp(sc, "CONSTANT", "view_settings.exposure")


# ============================================================================================ props
def lathe(name, profile, segs=48):
    """Surface of revolution about Z from [(radius, z)] (top to bottom)."""
    bm = bmesh.new()
    rings = []
    for r, z in profile:
        ring = [bm.verts.new((r * math.cos(2 * math.pi * k / segs), r * math.sin(2 * math.pi * k / segs), z))
                for k in range(segs)]
        rings.append(ring)
    for a, b in zip(rings, rings[1:]):
        for k in range(segs):
            bm.faces.new((a[k], a[(k + 1) % segs], b[(k + 1) % segs], b[k]))
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for p_ in me.polygons:
        p_.use_smooth = True
    return me


def mat_bronze():
    m, nt = new_mat("M_bronze")
    fine = noise(nt, 6.0, 5, 0.6, y=-300)
    pat = noise(nt, 1.2, 4, 0.6, y=-600)
    col = mix_col(nt, math_node(nt, "GREATER_THAN", pat, 0.62, x=-400, y=-600), (0.62, 0.40, 0.20, 1), (0.22, 0.42, 0.34, 1),
                  x=0, y=100)
    rough = math_node(nt, "ADD", math_node(nt, "MULTIPLY", fine, 0.25, x=0, y=-300), 0.22, x=150, y=-300)
    p = principled(nt, 400, 0, Base_Color=col, Metallic=0.95, Roughness=rough)
    mat_out(nt, p.outputs[0], 700, 0)
    return m


def remove_faces_in(obj, center, radius, zmin, zmax, mats=None):
    me = obj.data
    bm = bmesh.new()
    bm.from_mesh(me)
    mw = obj.matrix_world
    names = [m.name if m else "" for m in me.materials]
    dead = []
    for f in bm.faces:
        c = mw @ f.calc_center_median()
        if math.hypot(c.x - center[0], c.y - center[1]) < radius and zmin < c.z < zmax:
            if mats is None or names[f.material_index] in mats:
                dead.append(f)
    bmesh.ops.delete(bm, geom=dead, context="FACES")
    bm.to_mesh(me)
    bm.free()
    me.update()
    return len(dead)


def build_bell(sc):
    """SH03: the great bronze bell of the south-east belfry, swinging; the clapper strikes at 7.0 s."""
    scatter = bpy.data.objects["Scatter"]
    n = remove_faces_in(scatter, (9.5, -36.2), 1.45, 46.3, 50.4, mats={"M_gold", "M_wood", "M_iron"})
    col = bpy.data.collections.new("Props")
    sc.collection.children.link(col)
    pivot = bpy.data.objects.new("BellPivot", None)
    pivot.location = (9.5, -36.2, 50.25)
    col.objects.link(pivot)
    prof = [(0.10, 0.0), (0.42, -0.02), (0.55, -0.12), (0.60, -0.35), (0.62, -0.8), (0.70, -1.25), (0.86, -1.6),
            (1.02, -1.82), (1.12, -1.95), (1.13, -2.02), (1.05, -2.04), (0.92, -1.9), (0.7, -1.6), (0.56, -1.2),
            (0.5, -0.6), (0.44, -0.2), (0.0, -0.18)]
    bell = bpy.data.objects.new("Bell", lathe("Bell", prof))
    bell.data.materials.append(mat_bronze())
    bell.parent = pivot
    col.objects.link(bell)
    yoke = bpy.data.objects.new("BellYoke", lathe("BellYoke", [(0.18, 0.12), (0.2, 0.0), (0.18, -0.12)], 16))
    yoke.scale = (6.0, 1.0, 1.0)
    yoke.data.materials.append(MATS["wood"])
    yoke.parent = pivot
    col.objects.link(yoke)
    clap = bpy.data.objects.new("Clapper", lathe("Clapper", [(0.02, 0.0), (0.05, -0.3), (0.05, -1.5), (0.16, -1.62),
                                                              (0.18, -1.75), (0.12, -1.88), (0.0, -1.9)], 16))
    clap.data.materials.append(MATS["iron"])
    clap.location = (0, 0, -0.15)
    clap.parent = pivot
    col.objects.link(clap)
    # swing about the axis along the SH03 view (the bell moves across the frame); max deflection = the strike
    pivot.rotation_mode = "XYZ"
    clap.rotation_mode = "XYZ"
    for f in range(1, FRAMES + 2):
        t = (f - 1) / FPS
        a = math.radians(21.0) * math.sin(2 * math.pi * (t - 6.55) / 1.8)
        pivot.rotation_euler = (0.0, a, math.radians(28))
        pivot.keyframe_insert("rotation_euler", frame=f)
        lag = math.radians(21.0) * math.sin(2 * math.pi * (t - 6.55 - 0.12) / 1.8) - a
        clap.rotation_euler = (0.0, lag * 0.9, 0.0)
        clap.keyframe_insert("rotation_euler", frame=f)
    set_interp(pivot, "LINEAR")
    set_interp(clap, "LINEAR")
    log(f"bell: {n} old faces removed, new bell at {tuple(pivot.location)}")


def mat_beam(name, color, falloff=2.5, base_fade=0.004):
    """A pillar of coloured light: hot core, soft edges (facing ratio), fades with height."""
    m, nt = new_mat(name, method="BLENDED")
    lw = N(nt, "ShaderNodeLayerWeight", -800, 0)
    lw.inputs["Blend"].default_value = 0.5
    face = math_node(nt, "POWER", math_node(nt, "SUBTRACT", 1.0, out(lw, "Facing"), x=-600, y=0), falloff, x=-450, y=0)
    tc = N(nt, "ShaderNodeTexCoord", -800, -300)
    sep = N(nt, "ShaderNodeSeparateXYZ", -600, -300)
    L(nt, tc.outputs["Generated"], sep.inputs[0])
    fade = ramp(nt, sep.outputs["Z"], [(0.0, (0, 0, 0, 1)), (base_fade, (1, 1, 1, 1)), (0.6, (0.6, 0.6, 0.6, 1)),
                                       (1.0, (0, 0, 0, 1))], x=-450, y=-300)
    fbw = N(nt, "ShaderNodeRGBToBW", -250, -300)
    L(nt, fade, fbw.inputs[0])
    streak = noise(nt, 3.0, 3, 0.5, coord=None, y=-600)
    nz = [n for n in nt.nodes if n.bl_idname == "ShaderNodeTexNoise"][-1]
    mp = N(nt, "ShaderNodeMapping", -800, -600)
    L(nt, tc.outputs["Generated"], mp.inputs[0])
    mp.inputs["Scale"].default_value = (1.0, 1.0, 0.08)
    dl = mp.inputs["Location"].driver_add("default_value", 2).driver
    dl.expression = "-frame*0.02"
    L(nt, mp.outputs[0], nz.inputs["Vector"])
    s1 = math_node(nt, "ADD", math_node(nt, "MULTIPLY", streak, 0.8, x=-250, y=-600), 0.6, x=-120, y=-600)
    inten = math_node(nt, "MULTIPLY", math_node(nt, "MULTIPLY", face, fbw.outputs[0], x=-100, y=-150), s1, x=50, y=-250)
    power = N(nt, "ShaderNodeValue", -100, 200)
    power.label = "power"
    power.outputs[0].default_value = 0.0
    strength = math_node(nt, "MULTIPLY", inten, power.outputs[0], x=200, y=0)
    em = N(nt, "ShaderNodeEmission", 400, 100)
    em.inputs["Color"].default_value = (*color, 1)
    L(nt, strength, em.inputs["Strength"])
    tr = N(nt, "ShaderNodeBsdfTransparent", 400, -100)
    add = N(nt, "ShaderNodeAddShader", 600, 0)
    L(nt, em.outputs[0], add.inputs[0])
    L(nt, tr.outputs[0], add.inputs[1])
    mat_out(nt, add.outputs[0], 800, 0)
    m.use_backface_culling = False
    try:
        m.use_transparent_shadow = True
    except AttributeError:
        pass
    return m, power


KEEPS = {  # word, time (s), keep centre, colour
    "fire": (19.30, (17.21, -24.57), (1.0, 0.22, 0.05)),
    "ice": (20.22, (-17.21, -24.57), (0.22, 0.58, 1.0)),
    "nature": (21.12, (17.21, 24.57), (0.28, 1.0, 0.32)),
    "shadow": (22.20, (-17.21, 24.57), (0.62, 0.22, 1.0)),
}
EMPTY_AT = 26.09     # "...stood empty": the light dies (bell cut, beams off, shafts off, sun drops)


def top_of(center, radius, zmin=38.0):
    best = zmin
    for ob in bpy.data.objects:
        if ob.type != "MESH" or ob.name.startswith(("CloudSea", "Atmosphere")):
            continue
        me = ob.data
        nv = len(me.vertices)
        if nv == 0:
            continue
        co = np.empty(nv * 3, np.float32)
        me.vertices.foreach_get("co", co)
        co = co.reshape(-1, 3) @ np.array(ob.matrix_world)[:3, :3].T + np.array(ob.matrix_world)[:3, 3]
        sel = np.hypot(co[:, 0] - center[0], co[:, 1] - center[1]) < radius
        if sel.any():
            best = max(best, float(co[sel, 2].max()))
    return best


def build_beams(sc):
    """SH08-SH09: each keep carries a small crown-fire of its kingdom's colour (from 'Four crowns', 17.24 s); on its
    word a pillar of light shoots up from it (hot core + soft sheath + the light it throws). All die at 'empty'."""
    col = bpy.data.collections["Props"]
    for key, (t_on, (x, y), c) in KEEPS.items():
        base_z = top_of((x, y), 6.0) - 1.0
        H = 700.0
        for part, radius, falloff, pmax, psteady, bf in (("core", 1.3, 3.5, 30.0, 12.0, 0.004),
                                                         ("halo", 5.5, 1.6, 2.0, 0.9, 0.04)):
            bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=1.0, depth=1.0, end_fill_type="NOTHING")
            ob = bpy.context.active_object
            ob.name = f"Beam_{key}_{part}"
            for cc in list(ob.users_collection):
                cc.objects.unlink(ob)
            col.objects.link(ob)
            ob.data.transform(Matrix.Translation((0, 0, 0.5)))
            ob.location = (x, y, base_z)
            ob.visible_shadow = False
            m, power = mat_beam(f"M_beam_{key}_{part}", c, falloff, bf)
            ob.data.materials.append(m)
            for t, sz, pw in ((t_on - 0.05, 0.001, 0.0), (t_on, 0.03, pmax), (t_on + 0.3, 1.0, pmax * 0.7),
                              (t_on + 0.7, 1.0, psteady), (EMPTY_AT, 1.0, psteady), (EMPTY_AT + 0.12, 1.0, 0.0)):
                ob.scale = (radius, radius, H * sz)
                ob.keyframe_insert("scale", frame=f_of(t))
                power.outputs[0].default_value = pw
                power.outputs[0].keyframe_insert("default_value", frame=f_of(t))
            set_interp(ob, "LINEAR")
            set_interp(m.node_tree, "LINEAR")
        # the crown-fire: a small bright ember on the keep (SH08), which the beam grows out of
        me = bpy.data.meshes.new(f"Crown_{key}")
        bm = bmesh.new()
        bmesh.ops.create_icosphere(bm, subdivisions=3, radius=0.9)
        bm.to_mesh(me)
        bm.free()
        crown = bpy.data.objects.new(f"Crown_{key}", me)
        crown.location = (x, y, base_z + 1.2)
        cm = mat_emit(f"M_crown_{key}", c, 0.0)
        crown.data.materials.append(cm)
        col.objects.link(crown)
        for t, h in ((0.0, True), (SHOT["SH08"]["t0"] + 0.25, False), (EMPTY_AT + 0.2, True)):
            crown.hide_render = h
            crown.keyframe_insert("hide_render", frame=f_of(t))
        es = cm.node_tree.nodes["Emission"].inputs["Strength"]
        for t, v in ((0.0, 0.0), (SHOT["SH08"]["t0"] + 0.2, 0.0), (SHOT["SH08"]["t0"] + 0.6, 7.0), (EMPTY_AT, 7.0),
                     (EMPTY_AT + 0.12, 0.0)):
            es.default_value = v
            es.keyframe_insert("default_value", frame=f_of(t))
        set_interp(cm.node_tree, "LINEAR")
        # the light the fire and the beam throw on the keep and the terrace
        ld = bpy.data.lights.new(f"BeamLight_{key}", "POINT")
        ld.color = c
        ld.shadow_soft_size = 1.5
        lo = bpy.data.objects.new(f"BeamLight_{key}", ld)
        lo.location = (x, y, base_z + 3.0)
        col.objects.link(lo)
        for t, e in ((0.0, 0.0), (SHOT["SH08"]["t0"] + 0.2, 0.0), (SHOT["SH08"]["t0"] + 0.6, 6000.0), (t_on - 0.05, 6000.0),
                     (t_on, 120000.0), (t_on + 0.4, 38000.0), (EMPTY_AT, 38000.0), (EMPTY_AT + 0.12, 0.0)):
            ld.energy = e
            ld.keyframe_insert("energy", frame=f_of(t))
        set_interp(ld, "LINEAR")
        log(f"beam {key} at ({x}, {y}, {base_z:.1f}) on {t_on} s")


def build_throne_light(sc, sun):
    """SH10: four shafts of coloured light from the hall's four windows cross on the empty throne; they die one by
    one at 'empty'. A dense haze inside the hall shows the shafts; the sun does not light that haze (its volume
    factor is 0 during SH10) so the shafts own the air."""
    col = bpy.data.collections["Props"]
    shafts = (("red", (-5.0, -9.25, 55.8), (1.0, 0.16, 0.06)), ("violet", (-5.0, -12.75, 55.8), (0.6, 0.2, 1.0)),
              ("blue", (5.0, -9.25, 55.8), (0.18, 0.45, 1.0)), ("green", (5.0, -12.75, 55.8), (0.25, 1.0, 0.3)))
    aim = Vector((0.0, -8.4, 48.8))
    t_in, t_out = SHOT["SH10"]["t0"], SHOT["SH10"]["t1"]
    for k, (name, pos, c) in enumerate(shafts):
        ld = bpy.data.lights.new(f"Shaft_{name}", "SPOT")
        ld.color = c
        ld.spot_size = math.radians(17)
        ld.spot_blend = 0.3
        ld.shadow_soft_size = 0.25
        lo = bpy.data.objects.new(f"Shaft_{name}", ld)
        lo.location = pos
        lo.rotation_euler = (aim - Vector(pos)).to_track_quat("-Z", "Y").to_euler()
        col.objects.link(lo)
        off = EMPTY_AT + 0.15 * k
        for t, e in ((0.0, 0.0), (t_in - 0.01, 0.0), (t_in, 16000.0), (off, 16000.0), (off + 0.06, 0.0)):
            ld.energy = e
            ld.keyframe_insert("energy", frame=f_of(t))
        set_interp(ld, "CONSTANT")
    # the visible shafts: soft additive light cones from each window to its pool on the dais
    for k, (name, pos, c) in enumerate(shafts):
        p0 = Vector(pos)
        axis = aim - p0
        length = axis.length
        me = bpy.data.meshes.new(f"ShaftCone_{name}")
        bm = bmesh.new()
        bmesh.ops.create_cone(bm, cap_ends=False, segments=32, radius1=0.45, radius2=0.45 + length * math.tan(math.radians(6.5)),
                              depth=length)
        bmesh.ops.translate(bm, verts=bm.verts, vec=(0, 0, length / 2))
        bm.to_mesh(me)
        bm.free()
        ob = bpy.data.objects.new(f"ShaftCone_{name}", me)
        ob.location = p0
        ob.rotation_euler = axis.to_track_quat("Z", "Y").to_euler()
        col.objects.link(ob)
        ob.visible_shadow = False
        m, power = mat_beam(f"M_shaft_{name}", c, falloff=3.0, base_fade=0.08)
        # the gradient runs along the cone (generated z = 0 at the window, 1 on the floor): brighter up high
        ob.data.materials.append(m)
        off = EMPTY_AT + 0.15 * k
        for t, v_ in ((0.0, 0.0), (t_in - 0.01, 0.0), (t_in, 0.38), (off, 0.38), (off + 0.06, 0.0)):
            power.outputs[0].default_value = v_
            power.outputs[0].keyframe_insert("default_value", frame=f_of(t))
        set_interp(m.node_tree, "CONSTANT")
        for t, h in ((0.0, True), (t_in, False), (t_out, True)):
            ob.hide_render = h
            ob.keyframe_insert("hide_render", frame=f_of(t))
        set_interp(ob, "CONSTANT")
    # the sun does not scatter in the air during SH10 (the coloured shafts own the haze)
    for t, v_ in ((0.0, 1.0), (t_in, 0.0), (t_out, 1.0)):
        sun.data.volume_factor = v_
        sun.data.keyframe_insert("volume_factor", frame=f_of(t))
    for fc in iter_fcurves(sun.data):
        if fc.data_path == "volume_factor":
            for kp in fc.keyframe_points:
                kp.interpolation = "CONSTANT"


def build_orrery_flames(sc):
    """SH07: four little flames (red, blue, green, violet) orbit above the Master's open hand."""
    col = bpy.data.collections["Props"]
    centre = Vector((-13.0, 2.6, 51.4))
    piv = bpy.data.objects.new("FlamesPivot", None)
    piv.location = centre
    col.objects.link(piv)
    cols = ((1.0, 0.25, 0.06), (0.22, 0.55, 1.0), (0.3, 1.0, 0.35), (0.65, 0.25, 1.0))
    for k, c in enumerate(cols):
        me = bpy.data.meshes.new(f"Flame{k}")
        bm = bmesh.new()
        bmesh.ops.create_icosphere(bm, subdivisions=3, radius=0.11)
        bm.to_mesh(me)
        bm.free()
        ob = bpy.data.objects.new(f"Flame{k}", me)
        ob.data.materials.append(mat_emit(f"M_flame{k}", c, 4.0))
        a = 2 * math.pi * k / 4
        ob.location = (math.cos(a) * 0.95, math.sin(a) * 0.95, 0.12 * math.sin(2 * a))
        ob.parent = piv
        col.objects.link(ob)
        ld = bpy.data.lights.new(f"FlameLight{k}", "POINT")
        ld.color = c
        ld.energy = 45.0
        ld.shadow_soft_size = 0.1
        lo = bpy.data.objects.new(f"FlameLight{k}", ld)
        lo.parent = ob
        col.objects.link(lo)
    for f in range(1, FRAMES + 2):
        t = (f - 1) / FPS
        piv.rotation_euler = (math.radians(12) * math.sin(t * 1.3), 0.0, t * 2 * math.pi / 2.1)
        piv.keyframe_insert("rotation_euler", frame=f)
    set_interp(piv, "LINEAR")


def mat_flame_card():
    """A flame drawn on a card (local XZ plane, generated coords u across / v up): a teardrop that narrows upward,
    swayed and torn by upward-scrolling noise, white-yellow core -> orange -> red edges, soft alpha."""
    m, nt = new_mat("M_flame_card", method="BLENDED")
    tc = N(nt, "ShaderNodeTexCoord", -1600, 0)
    oi = N(nt, "ShaderNodeObjectInfo", -1600, -300)
    sep = N(nt, "ShaderNodeSeparateXYZ", -1400, 200)
    L(nt, tc.outputs["Generated"], sep.inputs[0])
    u, v = sep.outputs["X"], sep.outputs["Z"]
    seed = N(nt, "ShaderNodeCombineXYZ", -1400, -300)
    L(nt, math_node(nt, "MULTIPLY", oi.outputs["Random"], 17.0, x=-1500, y=-400), seed.inputs[0])
    for k, (sx, sz, speed, detail) in enumerate(((2.2, 1.3, 0.085, 3.0), (5.0, 2.6, 0.16, 2.0))):
        mp = N(nt, "ShaderNodeMapping", -1200, -100 - k * 300)
        L(nt, tc.outputs["Generated"], mp.inputs[0])
        mp.inputs["Scale"].default_value = (sx, 1.0, sz)
        dl = mp.inputs["Location"].driver_add("default_value", 2).driver
        dl.expression = f"-frame*{speed}"
        add = N(nt, "ShaderNodeVectorMath", -1050, -100 - k * 300, operation="ADD")
        L(nt, mp.outputs[0], add.inputs[0])
        L(nt, seed.outputs[0], add.inputs[1])
        nz = N(nt, "ShaderNodeTexNoise", -900, -100 - k * 300)
        L(nt, add.outputs[0], nz.inputs["Vector"])
        nz.inputs["Scale"].default_value = 1.0
        nz.inputs["Detail"].default_value = detail
        nz.inputs["Roughness"].default_value = 0.55
        if k == 0:
            n1 = nz.outputs["Fac"]
        else:
            n2 = nz.outputs["Fac"]
    # sway: u' = u + (n1 - 0.5) * 0.4 * v
    sway = math_node(nt, "MULTIPLY", math_node(nt, "MULTIPLY", math_node(nt, "SUBTRACT", n1, 0.5, x=-750, y=-100), 0.75,
                                                x=-650, y=-100), v, x=-550, y=0)
    uu = math_node(nt, "ADD", u, sway, x=-450, y=100)
    # teardrop width, widest low
    w = math_node(nt, "MAXIMUM", math_node(nt, "MULTIPLY", math_node(nt, "POWER", math_node(nt, "SUBTRACT", 1.0, v,
                  x=-750, y=300), 0.85, x=-650, y=300), 0.46, x=-550, y=300), 0.001, x=-450, y=300)
    dist = math_node(nt, "DIVIDE", math_node(nt, "ABSOLUTE", math_node(nt, "SUBTRACT", uu, 0.5, x=-350, y=150), x=-250, y=150),
                     w, x=-150, y=200)
    body = math_node(nt, "SUBTRACT", 1.0, dist, x=-50, y=200, clamp=True)
    fl = math_node(nt, "ADD", math_node(nt, "MULTIPLY", n2, 0.6, x=-650, y=-400), 0.55, x=-550, y=-400)
    top = math_node(nt, "SUBTRACT", 1.0, math_node(nt, "MULTIPLY", math_node(nt, "POWER", v, 1.4, x=-650, y=500), 0.75,
                                                   x=-550, y=500), x=-450, y=500)
    low = N(nt, "ShaderNodeMapRange", -450, 700)
    L(nt, v, low.inputs["Value"])
    low.inputs["From Min"].default_value = 0.0
    low.inputs["From Max"].default_value = 0.07
    inten = math_node(nt, "MULTIPLY", math_node(nt, "MULTIPLY", body, fl, x=100, y=100),
                      math_node(nt, "MULTIPLY", top, low.outputs["Result"], x=-300, y=600), x=250, y=200)
    # tongues: the fine noise tears the flame, more so towards the tip
    tear = math_node(nt, "MULTIPLY", math_node(nt, "SUBTRACT", 0.55, n2, x=100, y=-500),
                     math_node(nt, "ADD", math_node(nt, "MULTIPLY", v, 1.1, x=0, y=-650), 0.25, x=100, y=-650), x=200, y=-550)
    inten = math_node(nt, "SUBTRACT", inten, tear, x=320, y=100, clamp=True)
    col = ramp(nt, inten, [(0.04, (0.35, 0.02, 0.0, 1)), (0.2, (1.0, 0.16, 0.01, 1)), (0.4, (1.0, 0.42, 0.04, 1)),
                           (0.62, (1.0, 0.74, 0.24, 1)), (0.88, (1.0, 0.95, 0.78, 1))], x=400, y=200)
    em = N(nt, "ShaderNodeEmission", 650, 200)
    L(nt, col, em.inputs["Color"])
    em.inputs["Strength"].default_value = 1.7
    al = N(nt, "ShaderNodeMapRange", 400, -100)
    L(nt, inten, al.inputs["Value"])
    al.inputs["From Min"].default_value = 0.04
    al.inputs["From Max"].default_value = 0.2
    tr = N(nt, "ShaderNodeBsdfTransparent", 650, -100)
    mx = N(nt, "ShaderNodeMixShader", 850, 100)
    L(nt, al.outputs["Result"], mx.inputs[0])
    L(nt, tr.outputs[0], mx.inputs[1])
    L(nt, em.outputs[0], mx.inputs[2])
    mat_out(nt, mx.outputs[0], 1050, 100)
    m.use_backface_culling = False
    return m


def flame_card(name, base, width, height, yaw, mat, col):
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    vs = [bm.verts.new(p_) for p_ in ((-width / 2, 0, 0), (width / 2, 0, 0), (width / 2, 0, height), (-width / 2, 0, height))]
    bm.faces.new(vs)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    ob.location = base
    ob.rotation_euler = (0, 0, yaw)
    ob.data.materials.append(mat)
    ob.visible_shadow = False
    col.objects.link(ob)
    return ob


def build_braziers(sc):
    """Fire: the set's two braziers inside the gate + two iron stands on the bridge in front of it (SH05); each is
    a pair of crossed flame cards + a flickering warm light."""
    col = bpy.data.collections["Props"]
    fm = mat_flame_card()
    iron = MATS["iron"]
    stands = []
    for side in (-1, 1):
        foot = Vector((3.3 * side, -69.2, 30.0))
        stand = bpy.data.objects.new(f"BrazierStand{side}", lathe(f"BrazierStand{side}", [
            (0.0, 2.62), (0.62, 2.62), (0.7, 2.5), (0.66, 2.3), (0.45, 2.12), (0.14, 2.0), (0.1, 1.9), (0.09, 0.5),
            (0.2, 0.35), (0.34, 0.12), (0.36, 0.0), (0.0, 0.0)], 24))
        stand.location = foot
        stand.data.materials.append(iron)
        col.objects.link(stand)
        stands.append(foot + Vector((0, 0, 2.42)))
    for side, base, w, h in [(-1, Vector((-5.0, -60.0, 33.4)), 1.1, 1.6), (1, Vector((5.0, -60.0, 33.4)), 1.1, 1.6),
                             (-2, stands[0], 1.35, 2.2), (2, stands[1], 1.35, 2.2)]:
        for j, yaw in enumerate((0.0, math.pi / 2, math.pi / 4)):
            flame_card(f"Flame{side}_{j}", base, w * (1.0 if j < 2 else 0.8), h * (1.0 if j < 2 else 0.85), yaw, fm, col)
        ld = bpy.data.lights.new(f"Brazier{side}", "POINT")
        ld.color = (1.0, 0.5, 0.18)
        ld.shadow_soft_size = 0.4
        lo = bpy.data.objects.new(f"Brazier{side}", ld)
        lo.location = base + Vector((0, 0, 0.8))
        col.objects.link(lo)
        for f in range(1, FRAMES + 2, 2):
            t = (f - 1) / FPS
            ld.energy = 2600.0 * (0.8 + 0.12 * math.sin(t * 17 + side) + 0.08 * math.sin(t * 31 + 2 * side))
            if abs(side) == 2:
                ld.energy *= 0.8
            ld.keyframe_insert("energy", frame=f)
        set_interp(ld, "LINEAR")


def build_veils(sc):
    """SH01 opens inside the clouds: two slabs of noisy mist the descending camera falls through (0-1.6 s)."""
    col = bpy.data.collections["Props"]
    m, nt = new_mat("M_veil", method="BLENDED")
    geo = N(nt, "ShaderNodeNewGeometry", -900, 0)
    mp = N(nt, "ShaderNodeMapping", -700, 0)
    L(nt, geo.outputs["Position"], mp.inputs[0])
    mp.inputs["Scale"].default_value = (1.0, 1.0, 2.5)
    nz = noise(nt, 0.045, 5, 0.6, coord=mp.outputs[0], x=-500, y=0, distortion=0.4)
    d = ramp(nt, nz, [(0.42, (0, 0, 0, 1)), (0.62, (1, 1, 1, 1))], x=-300, y=0)
    bw = N(nt, "ShaderNodeRGBToBW", -100, 0)
    L(nt, d, bw.inputs[0])
    v = N(nt, "ShaderNodeVolumePrincipled", 100, 0)
    L(nt, math_node(nt, "MULTIPLY", bw.outputs[0], 0.09, x=0, y=-200), v.inputs["Density"])
    v.inputs["Color"].default_value = (1.0, 0.93, 0.9, 1)
    v.inputs["Anisotropy"].default_value = 0.5
    mat_out(nt, None, 400, 0, volume=v.outputs[0])
    for k, (z, off) in enumerate(((141.0, (6, -4)), (131.0, (-5, 8)))):
        bpy.ops.mesh.primitive_cube_add(size=1.0)
        ob = bpy.context.active_object
        ob.name = f"Veil{k}"
        for cc in list(ob.users_collection):
            cc.objects.unlink(ob)
        col.objects.link(ob)
        ob.location = (88 + off[0], -178 + off[1], z)
        ob.scale = (140, 140, 7)
        ob.data.materials.append(m)
        ob.visible_shadow = False
        for t, h in ((0.0, False), (SHOT["SH01"]["t1"], True)):
            ob.hide_render = h
            ob.keyframe_insert("hide_render", frame=f_of(t))
        set_interp(ob, "CONSTANT")


# ============================================================================================ dragons
DRAGON_MAT = (("membrane", "membrane"), ("scale", "scale"), ("horn", "horn"), ("lava", "lava"), ("flame", "lava"),
              ("glow", "glow"), ("ice", "glow"))


def import_dragon(kind, name, scale, tint=None):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=os.path.join(EXPORT, f"dragon_{kind}.glb"))
    new = [o for o in bpy.data.objects if o not in before]
    col = bpy.data.collections.get("Dragons") or bpy.data.collections.new("Dragons")
    if col.name not in bpy.context.scene.collection.children:
        bpy.context.scene.collection.children.link(col)
    root = None
    parts = {}
    for o in new:
        for c in list(o.users_collection):
            c.objects.unlink(o)
        col.objects.link(o)
        base = o.name.split(".")[0]
        parts[base] = o
        if o.parent is None:
            root = o
        if o.type == "MESH":
            if base == "Shadow":
                o.hide_render = True
                o.hide_viewport = True
                continue
            for k, m in enumerate(o.data.materials):
                mn = (m.name if m else "").lower()
                tag = next((t for key, t in DRAGON_MAT if key in mn), "scale")
                if tag == "membrane":
                    o.data.materials[k] = MATS[f"dragon_{kind}_membrane"]
                elif tag == "scale":
                    o.data.materials[k] = MATS[f"dragon_{kind}_scale"]
                elif tag == "horn":
                    o.data.materials[k] = MATS["dragon_horn"]
                elif tag == "lava":
                    o.data.materials[k] = MATS["dragon_cinder_lava"] if kind == "cinder" else MATS["dragon_frost_glow"]
                else:
                    o.data.materials[k] = MATS["dragon_frost_glow"] if kind == "frost" else MATS["dragon_cinder_lava"]
    root.name = name
    root.scale = (scale, scale, scale)
    root.rotation_mode = "XYZ"
    for o in parts.values():
        o.rotation_mode = "XYZ"
    return root, parts


def fly(root, parts, path, t0, t1, flap_period=1.2, flap_deg=38.0, bank_deg=0.0, pad=0.4):
    """Keys the dragon along a Catmull-Rom path of points (m) between t0 and t1 (s), heading along the path
    (the model faces -Y), wings beating (WingL/R about the body axis, the hand panels lagging)."""
    pts = [Vector(p) for p in path]

    def at(u):
        u = min(1.0, max(0.0, u)) * (len(pts) - 1)
        i = min(int(u), len(pts) - 2)
        s = u - i
        p0 = pts[max(i - 1, 0)]
        p1, p2 = pts[i], pts[i + 1]
        p3 = pts[min(i + 2, len(pts) - 1)]
        return 0.5 * ((2 * p1) + (-p0 + p2) * s + (2 * p0 - 5 * p1 + 4 * p2 - p3) * s * s + (-p0 + 3 * p1 - 3 * p2 + p3) * s ** 3)

    fa, fb = f_of(max(0.0, t0 - pad)), f_of(min(LENGTH, t1 + pad))
    root.hide_render = True
    root.keyframe_insert("hide_render", frame=1)
    root.hide_render = False
    root.keyframe_insert("hide_render", frame=fa)
    root.hide_render = True
    root.keyframe_insert("hide_render", frame=fb + 1)
    for o in root.children_recursive:
        o.hide_render = True
        o.keyframe_insert("hide_render", frame=1)
        o.hide_render = (o.name.split(".")[0] == "Shadow")
        o.keyframe_insert("hide_render", frame=fa)
        o.hide_render = True
        o.keyframe_insert("hide_render", frame=fb + 1)
    ph = hash(root.name) % 100 / 100.0
    for f in range(fa, fb + 1):
        t = (f - 1) / FPS
        u = (t - t0) / max(0.01, (t1 - t0))
        p = at(u)
        q = at(u + 0.01) - at(u - 0.01)
        root.location = p
        yaw = math.atan2(-q.x, q.y) + math.pi       # model faces -Y
        pitch = math.atan2(q.z, math.hypot(q.x, q.y))
        root.rotation_euler = (-pitch * 0.6, math.radians(bank_deg) * math.sin(u * math.pi), yaw)
        root.keyframe_insert("location", frame=f)
        root.keyframe_insert("rotation_euler", frame=f)
        w = 2 * math.pi * (t / flap_period + ph)
        raise_ = math.radians(flap_deg) * math.sin(w) + math.radians(8)
        hand = math.radians(flap_deg * 0.6) * math.sin(w - 0.9)
        for side, sgn in (("L", 1), ("R", -1)):
            wing = parts.get(f"Wing{side}")
            wing2 = parts.get(f"Wing{side}2")
            if wing:
                wing.rotation_euler = (0, sgn * raise_, 0)
                wing.keyframe_insert("rotation_euler", frame=f)
            if wing2:
                wing2.rotation_euler = (0, sgn * hand, 0)
                wing2.keyframe_insert("rotation_euler", frame=f)
        body = parts.get("Body")
        if body:
            body.location = (0, 0, 4.0 - 0.25 * math.sin(w))
            body.keyframe_insert("location", frame=f)
        for tn, amp in (("Tail1", 6), ("Tail2", 9), ("Tail3", 12)):
            tail = parts.get(tn)
            if tail:
                tail.rotation_euler = (math.radians(amp * 0.4) * math.sin(w - 1.2), 0, math.radians(amp) * math.sin(t * 1.7 + ph * 6))
                tail.keyframe_insert("rotation_euler", frame=f)
    for o in [root] + list(root.children_recursive):
        set_interp(o, "LINEAR")
        for fc in iter_fcurves(o):
            if fc.data_path == "hide_render":
                for kp in fc.keyframe_points:
                    kp.interpolation = "CONSTANT"


def build_dragons(sc):
    """The dragon sky: 'not one breathed in anger'. Cinder = dark with ember seams, frost = pale blue; scaled
    from swallow-small to cloud-big (elders ~ 3x)."""
    plan = [
        # SH01: an elder glides across the middle distance, two small ones circle the Master's tower
        ("cinder", "Elder_SH01", 3.2, [(95, -40, 108), (40, -55, 101), (-20, -52, 96), (-90, -30, 92)], 0.0, 4.6, 2.2, 30, 12),
        ("frost", "Small_SH01a", 0.9, [(40, 30, 104), (24, -8, 108), (-4, -18, 110), (-24, 6, 106)], 0.0, 4.6, 0.75, 42, 20),
        ("frost", "Small_SH01b", 0.7, [(60, 10, 88), (40, -20, 92), (10, -30, 96), (-20, -24, 98)], 0.3, 4.6, 0.7, 42, 22),
        # SH03: a frost dragon crosses the god rays behind the belfry
        ("frost", "Frost_SH03", 1.3, [(32, -6, 64), (14, -17, 62), (-4, -24, 61), (-22, -24, 60)], 6.2, 8.6, 0.95, 40, 18),
        # SH04: an elder glides under the Great Bridge
        ("cinder", "Elder_SH04", 2.6, [(-26, -58, 24), (-23, -98, 20), (-20, -138, 19), (-14, -182, 23)], 8.3, 10.6, 2.0, 26, 10),
        # SH08: two circle the summit
        ("frost", "Frost_SH08", 1.4, [(44, 6, 88), (30, -10, 85), (14, -26, 82), (-4, -40, 80)], 16.9, 19.4, 1.0, 38, 25),
        ("cinder", "Cinder_SH08", 1.6, [(-30, 10, 74), (-12, 0, 76), (6, -8, 78), (24, -20, 80)], 16.9, 19.4, 1.1, 36, -25),
        # SH11: the flock leaves the citadel at dusk: they rise off the towers and fly north into the last light
        ("cinder", "Leave_1", 2.2, [(-8, -6, 88), (-40, 70, 105), (-130, 270, 125), (-220, 520, 150)], 26.8, 30.0, 1.6, 30, 10),
        ("frost", "Leave_2", 1.8, [(12, 4, 92), (45, 80, 108), (140, 270, 128), (240, 520, 150)], 26.8, 30.0, 1.4, 32, -10),
        ("frost", "Leave_3", 1.0, [(0, -20, 96), (-6, 50, 104), (-20, 230, 118), (-40, 480, 140)], 26.8, 30.0, 0.9, 40, 5),
        ("cinder", "Leave_4", 1.2, [(20, -10, 100), (50, 50, 110), (120, 210, 125), (200, 430, 145)], 26.8, 30.0, 1.0, 36, -8),
        ("frost", "Leave_5", 0.8, [(-18, 8, 94), (-60, 60, 104), (-160, 190, 118), (-300, 390, 135)], 26.8, 30.0, 0.8, 40, 12),
        ("cinder", "Leave_6", 3.0, [(15, -120, 105), (8, -40, 92), (0, 50, 86), (-10, 240, 104)], 26.9, 30.0, 2.2, 26, 0),
    ]
    for kind, name, scale, path, t0, t1, period, flap, bank in plan:
        root, parts = import_dragon(kind, name, scale)
        fly(root, parts, path, t0, t1, flap_period=period, flap_deg=flap, bank_deg=bank)
    log(f"dragons: {len(plan)} flights")


# ============================================================================================ compositor
def build_compositor(sc):
    ng = bpy.data.node_groups.new("Grade", "CompositorNodeTree")
    ng.interface.new_socket("Image", in_out="OUTPUT", socket_type="NodeSocketColor")
    sc.compositing_node_group = ng
    nt = ng
    rl = N(nt, "CompositorNodeRLayers", -1200, 0)
    rl.scene = sc
    gl = N(nt, "CompositorNodeGlare", -950, 0)
    L(nt, rl.outputs["Image"], gl.inputs["Image"])
    for k, v in (("Type", "Bloom"), ("Quality", "High")):
        try:
            gl.inputs[k].default_value = v
        except Exception:
            try:
                gl.inputs[k].default_value = v.upper()
            except Exception as e:
                log("glare", k, e)
    for k, v in (("Threshold", 1.2), ("Strength", 0.55), ("Size", 0.75), ("Saturation", 1.0), ("Smoothness", 0.4)):
        if gl.inputs.get(k) is not None:
            try:
                gl.inputs[k].default_value = v
            except Exception as e:
                log("glare", k, e)
    ld = N(nt, "CompositorNodeLensdist", -700, 0)
    L(nt, gl.outputs["Image"], ld.inputs["Image"])
    ld.inputs["Dispersion"].default_value = 0.012
    try:
        ld.inputs["Distortion"].default_value = 0.0
    except Exception:
        pass
    # grade: gentle S-curve, lifted cool shadows, warm highlights, a touch more saturation
    cb = N(nt, "CompositorNodeColorBalance", -450, 0)
    L(nt, ld.outputs["Image"], cb.inputs["Image"])
    colsocks = [s for s in cb.inputs if s.type == "RGBA" and s.name in ("Lift", "Gamma", "Gain")]
    for s in colsocks:
        if s.name == "Lift":
            s.default_value = (0.985, 0.99, 1.03, 1)
        elif s.name == "Gamma":
            s.default_value = (1.0, 0.99, 0.985, 1)
        elif s.name == "Gain":
            s.default_value = (1.04, 1.0, 0.95, 1)
    hs = N(nt, "CompositorNodeHueSat", -250, 0)
    L(nt, cb.outputs["Image"], hs.inputs["Image"])
    hs.inputs["Saturation"].default_value = 1.12
    curve = N(nt, "CompositorNodeCurveRGB", -50, 0)
    L(nt, hs.outputs["Image"], curve.inputs["Image"])
    cm = curve.mapping
    c = cm.curves[3]
    c.points.new(0.25, 0.195)
    c.points.new(0.75, 0.805)
    cm.update()
    # vignette
    em = N(nt, "CompositorNodeEllipseMask", -250, -400)
    try:
        em.inputs["Size"].default_value = (0.92, 0.82)
    except Exception:
        pass
    bl = N(nt, "CompositorNodeBlur", -50, -400)
    L(nt, em.outputs["Mask"], bl.inputs["Image"])
    try:
        bl.inputs["Size"].default_value = (300, 300)
    except Exception:
        pass
    vig = N(nt, "ShaderNodeMapRange", 150, -400)
    L(nt, bl.outputs["Image"], vig.inputs["Value"])
    vig.inputs["To Min"].default_value = 0.62
    vig.inputs["To Max"].default_value = 1.0
    mul = N(nt, "ShaderNodeMix", 350, 0, data_type="RGBA", blend_type="MIX")     # image x vignette
    L(nt, vig.outputs["Result"], mul.inputs[0])
    mul.inputs[6].default_value = (0, 0, 0, 1)
    L(nt, curve.outputs["Image"], mul.inputs[7])
    # fades (keyed): black in at the start, black out at the end
    fade = N(nt, "ShaderNodeValue", 350, -600)
    fade.label = "fade"
    for t, v in ((0.0, 0.0), (SHOT["SH01"].get("fade_in", 0.6), 1.0), (LENGTH - SHOT["SH11"].get("fade_out", 0.8), 1.0),
                 (LENGTH, 0.0)):
        fade.outputs[0].default_value = v
        fade.outputs[0].keyframe_insert("default_value", frame=f_of(t))
    fm = N(nt, "ShaderNodeMix", 550, 0, data_type="RGBA", blend_type="MIX")
    L(nt, fade.outputs[0], fm.inputs[0])
    fm.inputs[6].default_value = (0, 0, 0, 1)
    L(nt, mul.outputs[2], fm.inputs[7])
    go = N(nt, "NodeGroupOutput", 800, 0)
    L(nt, fm.outputs[2], go.inputs[0])
    try:
        sc.render.use_compositing = True
    except Exception:
        pass
    return ng


# ============================================================================================ the edit
TITLE = "F O U R    W I Z A R D S"


def build_film_scene(sc):
    """Scene 'Film': the picture (scene strip of 'Citadel') + the Master's narration + the bell + the wind + the
    title."""
    film = bpy.data.scenes.new("Film")
    film.render.resolution_x, film.render.resolution_y = sc.render.resolution_x, sc.render.resolution_y
    film.render.fps = FPS
    film.frame_start, film.frame_end = 1, FRAMES
    ed = film.sequence_editor_create()
    strips = ed.strips
    ss = strips.new_scene("Citadel", sc, channel=1, frame_start=1)
    ss.frame_final_end = FRAMES + 1
    nar = strips.new_sound("Narration", os.path.join(HERE, "narration.wav"), channel=2, frame_start=1)
    nar.volume = 1.0
    bell = strips.new_sound("Bell", os.path.join(HERE, "bell.wav"), channel=3, frame_start=1)
    bell.volume = 0.32
    wind = strips.new_sound("Wind", os.path.join(HERE, "wind.wav"), channel=5, frame_start=1)
    wind.volume = 0.13
    t0, t1 = 28.2, 29.6
    tx = strips.new_effect("Title", "TEXT", channel=4, frame_start=f_of(t0), length=f_of(t1) - f_of(t0))
    tx.text = TITLE
    tx.font_size = 64
    tx.color = (0.96, 0.9, 0.78, 1.0)
    try:
        tx.location = (0.5, 0.5)
        tx.alignment_x = "CENTER"
        tx.anchor_x = "CENTER"
        tx.anchor_y = "CENTER"
    except Exception:
        pass
    for fname in (r"C:\Windows\Fonts\georgia.ttf", r"C:\Windows\Fonts\pala.ttf", r"C:\Windows\Fonts\times.ttf"):
        if os.path.exists(fname):
            tx.font = bpy.data.fonts.load(fname)
            break
    tx.use_shadow = True
    for t, a in ((t0, 0.0), (t0 + 0.4, 1.0), (t1 - 0.35, 1.0), (t1, 0.0)):
        tx.blend_alpha = a
        tx.keyframe_insert("blend_alpha", frame=f_of(t))
    ims = film.render.image_settings
    if hasattr(ims, "media_type"):
        ims.media_type = "VIDEO"
    ims.file_format = "FFMPEG"
    film.render.ffmpeg.format = "MPEG4"
    film.render.ffmpeg.codec = "H264"
    film.render.ffmpeg.constant_rate_factor = "HIGH"
    film.render.ffmpeg.audio_codec = "AAC"
    film.render.ffmpeg.audio_bitrate = 192
    film.render.ffmpeg.audio_channels = "STEREO"
    film.render.filepath = os.path.join(HERE, "prologue_castle_film.mp4")
    film.render.use_sequencer = True
    return film


def main(full=True):
    t0 = time.time()
    sc = reset()
    setup_render(sc)
    build_materials()
    import_citadel()
    build_world(sc)
    sun = build_sun(sc)
    build_cloud_sea(sc)
    build_cumulus(sc)
    build_atmosphere(sc)
    log(f"set, sky and atmosphere built in {time.time() - t0:.1f} s")
    if not full:
        return sc
    build_cues(sc, sun)
    build_bell(sc)
    build_beams(sc)
    build_throne_light(sc, sun)
    build_orrery_flames(sc)
    build_braziers(sc)
    build_veils(sc)
    build_dragons(sc)
    build_cameras(sc)
    build_compositor(sc)
    build_film_scene(sc)
    sc.frame_set(1)
    log(f"film built in {time.time() - t0:.1f} s")
    return sc


if __name__ == "__main__" and "--no-main" not in sys.argv:
    main()
    bpy.ops.wm.save_as_mainfile(filepath=BLEND, compress=True)
    log("saved", BLEND)
