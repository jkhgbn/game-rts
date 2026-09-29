"""Renders prologue_castle.blend (built by build_castle.py): stills of every shot, or the 30-second film.

    set B="C:\\Program Files\\Blender Foundation\\Blender 5.2\\blender.exe"
    %B% -b art\\blender\\prologue_castle\\prologue_castle.blend -P art\\blender\\prologue_castle\\render_castle.py -- stills
    %B% -b art\\blender\\prologue_castle\\prologue_castle.blend -P art\\blender\\prologue_castle\\render_castle.py -- film

Options (after --):
    stills | film          what to render
    res=1280               width (height = width / 2.39); default stills 1280, film 1920
    samples=48             EEVEE samples per frame (motion blur / DOF / volumes converge with them)
    shots=SH01,SH03        stills: only these shots; at=0.5 = where in the shot (0..1), several: at=0.2,0.8
                           (default: each shot's key moment, KEY_AT)
    frames=DIR             film: where the frames go (default: Blender's temp dir, resumable: existing frames kept)
    out=FILE.mp4           film: output (default prologue_castle_film.mp4 next to this script)
    fmt=JPEG|PNG           film frames format (default JPEG 95; PNG for the final master)
    start=1 end=720        film: a frame range (encode still uses every frame found)
"""
import os
import sys
import tempfile
import time

import bpy

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import build_castle as bc  # noqa: E402


def opts():
    a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    o = {"mode": a[0] if a else "stills"}
    for x in a[1:]:
        if "=" in x:
            k, v = x.split("=", 1)
            o[k] = v
    return o


def setup(sc, width, samples):
    sc.render.resolution_x = width
    sc.render.resolution_y = int(round(width / 2.388))
    sc.render.resolution_percentage = 100
    sc.eevee.taa_render_samples = samples
    # the volume grid follows the resolution: finer tiles at high res
    sc.eevee.volumetric_tile_size = "4" if width >= 1900 else "8"


# where in each shot its still is taken (0..1): the bell's strike, the beams up, the shafts on...
KEY_AT = dict(SH01=0.7, SH02=0.6, SH03=0.32, SH04=0.5, SH05=0.6, SH06=0.8, SH07=0.5, SH08=0.6, SH09a=0.75,
              SH09b=0.75, SH09c=0.75, SH09d=0.75, SH10=0.45, SH11=0.6)


def stills(o):
    sc = bpy.data.scenes["Citadel"]
    setup(sc, int(o.get("res", 1280)), int(o.get("samples", 48)))
    outdir = o.get("dir", os.path.join(HERE, "stills"))
    os.makedirs(outdir, exist_ok=True)
    want = set(o["shots"].split(",")) if "shots" in o else None
    ats = [float(x) for x in o["at"].split(",")] if "at" in o else None
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGB"
    times = {}
    for s in bc.SHOTS:
        if want and s["id"] not in want:
            continue
        f0, f1 = bc.f_of(s["t0"]), bc.f_of(s["t1"]) - 1
        for at in (ats or [KEY_AT.get(s["id"], 0.5)]):
            f = int(round(f0 + (f1 - f0) * at))
            sc.frame_set(f)
            suffix = "" if not ats or len(ats) == 1 else f"_{int(at * 100):02d}"
            sc.render.filepath = os.path.join(outdir, f"{s['id']}{suffix}.png")
            t0 = time.time()
            bpy.ops.render.render(write_still=True, scene=sc.name)
            times[f"{s['id']}{suffix}"] = round(time.time() - t0, 1)
            print(f"STILL {s['id']}{suffix} frame {f} ({(f - 1) / bc.FPS:.2f} s) in {times[s['id'] + suffix]} s", flush=True)
    print("STILLS", times)


def film(o):
    sc = bpy.data.scenes["Citadel"]
    width = int(o.get("res", 1920))
    setup(sc, width, int(o.get("samples", 48)))
    fmt = o.get("fmt", "JPEG").upper()
    frames = o.get("frames", os.path.join(tempfile.gettempdir(), f"prologue_castle_frames_{width}"))
    os.makedirs(frames, exist_ok=True)
    ext = "jpg" if fmt == "JPEG" else "png"
    ims = sc.render.image_settings
    if hasattr(ims, "media_type"):
        ims.media_type = "IMAGE"
    ims.file_format = fmt
    ims.color_mode = "RGB"
    if fmt == "JPEG":
        ims.quality = 95
    else:
        ims.compression = 15
    sc.render.filepath = os.path.join(frames, "f_####")
    sc.render.use_overwrite = False       # resumable: frames already on disk are skipped
    sc.render.use_placeholder = True
    sc.frame_start = int(o.get("start", 1))
    sc.frame_end = int(o.get("end", bc.FRAMES))
    t0 = time.time()
    bpy.ops.render.render(animation=True, scene=sc.name)
    render_s = time.time() - t0
    print(f"FILM frames {sc.frame_start}-{sc.frame_end} rendered in {render_s / 60:.1f} min -> {frames}", flush=True)
    if sc.frame_start != 1 or sc.frame_end != bc.FRAMES:
        return
    encode(sc, frames, ext, o.get("out", os.path.join(HERE, "prologue_castle_film.mp4")))


def encode(sc, frames, ext, out):
    """Picture (the rendered frames) + narration + bell + wind + title -> H.264 / AAC mp4."""
    ed_scene = bpy.data.scenes.new("Encode")
    ed_scene.render.resolution_x, ed_scene.render.resolution_y = sc.render.resolution_x, sc.render.resolution_y
    ed_scene.render.resolution_percentage = 100
    ed_scene.render.fps = bc.FPS
    ed_scene.frame_start, ed_scene.frame_end = 1, bc.FRAMES
    ed = ed_scene.sequence_editor_create()
    files = sorted(f for f in os.listdir(frames) if f.startswith("f_") and f.endswith("." + ext))
    img = ed.strips.new_image("Picture", os.path.join(frames, files[0]), channel=1, frame_start=1)
    for f in files[1:]:
        img.elements.append(f)
    img.frame_final_end = bc.FRAMES + 1
    film_src = bpy.data.scenes.get("Film")
    # sounds + title copied from the Film scene of the .blend (same timings)
    nar = ed.strips.new_sound("Narration", os.path.join(HERE, "narration.wav"), channel=2, frame_start=1)
    bell = ed.strips.new_sound("Bell", os.path.join(HERE, "bell.wav"), channel=3, frame_start=1)
    wind = ed.strips.new_sound("Wind", os.path.join(HERE, "wind.wav"), channel=5, frame_start=1)
    wind.volume = 0.13
    if film_src and film_src.sequence_editor:
        src = {s.name: s for s in film_src.sequence_editor.strips_all}
        if "Bell" in src:
            bell.volume = src["Bell"].volume
        if "Narration" in src:
            nar.volume = src["Narration"].volume
        if "Wind" in src:
            wind.volume = src["Wind"].volume
        t = src.get("Title")
        if t is not None:
            tx = ed.strips.new_effect("Title", "TEXT", channel=4, frame_start=int(t.frame_final_start),
                                      length=int(t.frame_final_end - t.frame_final_start))
            for attr in ("text", "font_size", "color", "use_shadow", "location", "alignment_x", "anchor_x", "anchor_y",
                         "font"):
                try:
                    setattr(tx, attr, getattr(t, attr))
                except Exception:
                    pass
            # the title was laid out for 1920 px: keep its size relative to the frame
            tx.font_size = max(8, int(round(t.font_size * ed_scene.render.resolution_x / 1920.0)))
            if film_src.animation_data and film_src.animation_data.action:
                for fc in bc.iter_fcurves(film_src):
                    if "Title" in fc.data_path and fc.data_path.endswith("blend_alpha"):
                        for kp in fc.keyframe_points:
                            tx.blend_alpha = kp.co[1]
                            tx.keyframe_insert("blend_alpha", frame=int(kp.co[0]))
    r = ed_scene.render
    ims = r.image_settings
    if hasattr(ims, "media_type"):
        ims.media_type = "VIDEO"
    ims.file_format = "FFMPEG"
    r.ffmpeg.format = "MPEG4"
    r.ffmpeg.codec = "H264"
    r.ffmpeg.constant_rate_factor = "HIGH"
    r.ffmpeg.ffmpeg_preset = "GOOD"
    r.ffmpeg.audio_codec = "AAC"
    r.ffmpeg.audio_bitrate = 192
    r.ffmpeg.audio_channels = "STEREO"
    r.ffmpeg.audio_mixrate = 48000
    r.use_sequencer = True
    r.filepath = out
    if os.path.exists(out):
        os.remove(out)
    t0 = time.time()
    bpy.ops.render.render(animation=True, scene=ed_scene.name)
    # Blender appends the frame range to video names unless the path has an extension it recognises
    print(f"ENCODED {out} in {time.time() - t0:.0f} s, {os.path.getsize(out) / 1e6:.1f} MB" if os.path.exists(out)
          else f"ENCODE: {out} not found (check {os.path.dirname(out)})", flush=True)


if __name__ == "__main__":
    o = opts()
    if o["mode"] == "stills":
        stills(o)
    elif o["mode"] == "film":
        film(o)
    elif o["mode"] == "encode":
        sc = bpy.data.scenes["Citadel"]
        setup(sc, int(o.get("res", 1920)), 1)
        encode(sc, o["frames"], o.get("ext", "jpg"), o.get("out", os.path.join(HERE, "prologue_castle_film.mp4")))
    else:
        print("usage: -- stills | film | encode frames=DIR")
