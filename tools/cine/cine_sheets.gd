class_name CineSheets
extends RefCounted
## Images of `cine`: the timing sheet (headless, pure Image: shot bars, line bars, cue ticks, music block, fades)
## and the stills contact sheet layout (tiles come from windowed captures).

const W := 1800
const LEFT := 110
const KIND_COLORS := {"move": Color(0.5, 0.8, 1.0), "teleport": Color(0.5, 0.8, 1.0), "face": Color(0.6, 0.7, 0.9),
	"anim": Color(1.0, 0.6, 0.3), "clip": Color(1.0, 0.5, 0.2), "vfx": Color(1.0, 0.3, 0.8), "sfx": Color(0.4, 1.0, 0.5),
	"music": Color(0.3, 0.8, 0.4), "shake": Color(1.0, 1.0, 0.4), "fade": Color(0.8, 0.8, 0.8), "title": Color(1, 1, 1),
	"visible": Color(0.7, 0.5, 1.0), "call": Color(0.9, 0.9, 0.5), "set_shot": Color(0.6, 0.6, 0.6)}
const KIND_LETTER := {"move": "M", "teleport": "T", "face": "F", "anim": "A", "clip": "C", "vfx": "V", "sfx": "S",
	"music": "U", "shake": "K", "fade": "D", "title": "I", "visible": "H", "call": "L", "set_shot": "E"}
const SHOT_COLORS := [Color(0.25, 0.35, 0.55), Color(0.3, 0.45, 0.35), Color(0.5, 0.35, 0.3), Color(0.4, 0.3, 0.5)]


static func timing_sheet(doc: CineDoc, bake: CineBake, ev: CineEval, header: Array) -> Image:
	var speakers: Array[String] = []
	for s: Dictionary in bake.shots:
		for ln: Dictionary in s["lines"]:
			if not String(ln["speaker"]) in speakers:
				speakers.append(String(ln["speaker"]))
	var actors: Array[String] = []
	for s2: Dictionary in bake.shots:
		for a: Dictionary in s2["actions"]:
			var who := String(a["actor"]) if String(a["actor"]) != "" else "(cues)"
			if not who in actors:
				actors.append(who)
	var row_h := 34
	var head_h := 16 + ToolSheet.line_h(3) + header.size() * ToolSheet.line_h(2) + 10
	var rows := 2 + speakers.size() + actors.size() + 1
	var h := head_h + 30 + rows * (row_h + 6) + 60
	var img := ToolSheet.new_image(W, h)
	var y := 10
	ToolSheet.text(img, 10, y, ToolSheet.clip("TIMING  %s  \"%s\"  %.1f S  %d SHOTS" % [doc.id, doc.title, ev.total, bake.shots.size()], W - 20, 3), ToolSheet.FG, 3)
	y += ToolSheet.line_h(3) + 4
	for hl: Variant in header:
		var hs := String(hl)
		var c := ToolSheet.FG
		if hs.begins_with("FAIL"):
			c = ToolSheet.FAIL_C
		elif hs.begins_with("WARN"):
			c = ToolSheet.WARN_C
		elif hs.begins_with("PASS"):
			c = ToolSheet.PASS_C
		ToolSheet.text(img, 10, y, ToolSheet.clip(hs, W - 20, 2), c, 2)
		y += ToolSheet.line_h(2)
	y = head_h
	var span := float(W - LEFT - 20)
	var px := func(t: float) -> int: return LEFT + int(round(t / maxf(0.001, ev.total) * span))
	# ruler
	var step := 5.0 if ev.total > 30.0 else 1.0
	var tt := 0.0
	while tt <= ev.total + 0.001:
		var x: int = px.call(tt)
		ToolSheet.rect(img, Rect2i(x, y + 14, 1, h - y - 40), Color(1, 1, 1, 0.08))
		ToolSheet.text(img, x + 2, y, "%ds" % int(tt), Color(0.7, 0.7, 0.7), 2)
		tt += step
	y += 30
	# shots
	ToolSheet.text(img, 8, y + 10, "SHOTS", ToolSheet.FG, 2)
	for i: int in bake.shots.size():
		var s3: Dictionary = bake.shots[i]
		var x0: int = px.call(ev.starts[i])
		var x1: int = px.call(ev.starts[i] + float(s3["duration"]))
		ToolSheet.rect(img, Rect2i(x0, y, maxi(1, x1 - x0 - 2), row_h), SHOT_COLORS[i % SHOT_COLORS.size()])
		var cam_names := ["STATIC", "DOLLY", "CRANE", "ORBIT", "RAIL", "FOLLOW"]
		ToolSheet.text(img, x0 + 4, y + 3, ToolSheet.clip("%s %.1fS" % [s3["id"], float(s3["duration"])], x1 - x0 - 6, 2), ToolSheet.FG, 2)
		ToolSheet.text(img, x0 + 4, y + 20, ToolSheet.clip("%s" % cam_names[int(s3["camera_mode"])], x1 - x0 - 6, 1), Color(0.85, 0.85, 0.85), 1)
		if int(s3["transition_in"]) in [1, 2]:
			var fw: int = maxi(3, int(float(s3["transition_time"]) / maxf(0.001, ev.total) * span))
			ToolSheet.rect(img, Rect2i(x0 - fw / 2, y - 4, fw, 4), Color.WHITE if int(s3["transition_in"]) == 2 else Color(0.6, 0.6, 0.6))
	y += row_h + 6
	# lines per speaker
	for sp: String in speakers:
		ToolSheet.text(img, 8, y + 10, ToolSheet.clip(sp, LEFT - 12, 2), Color(1.0, 0.75, 0.45), 2)
		for i2: int in bake.shots.size():
			var s4: Dictionary = bake.shots[i2]
			for ln2: Dictionary in s4["lines"]:
				if String(ln2["speaker"]) != sp:
					continue
				var txt := String(ln2["text"])
				var eff := float(ln2["duration"]) if float(ln2["duration"]) > 0.0 else maxf(2.5, 0.9 + 0.055 * txt.length())
				var a0 := ev.starts[i2] + float(ln2["at"])
				var a1 := minf(a0 + eff, ev.starts[i2] + float(s4["duration"]))
				var lx0: int = px.call(a0)
				var lx1: int = px.call(maxf(a1, a0 + 0.2))
				var cps := float(txt.length()) / maxf(0.01, a1 - a0)
				var col := Color(0.35, 0.55, 0.35) if cps <= CineChecks.CPS_OK else (Color(0.6, 0.5, 0.2) if cps <= CineChecks.CPS_MAX else Color(0.65, 0.25, 0.22))
				if txt.length() > CineChecks.MAX_CHARS * CineChecks.MAX_LINES:
					col = Color(0.65, 0.25, 0.22)
				ToolSheet.rect(img, Rect2i(lx0, y, maxi(2, lx1 - lx0 - 1), row_h), col)
				ToolSheet.text(img, lx0 + 3, y + 3, ToolSheet.clip(txt, lx1 - lx0 - 5, 1), ToolSheet.FG, 1)
				ToolSheet.text(img, lx0 + 3, y + 20, ToolSheet.clip("%.0f CPS" % cps, lx1 - lx0 - 5, 1), Color(0.85, 0.85, 0.85), 1)
		y += row_h + 6
	# cue ticks per actor
	for who: String in actors:
		ToolSheet.text(img, 8, y + 10, ToolSheet.clip(who, LEFT - 12, 2), Color(0.6, 0.85, 1.0), 2)
		for i3: int in bake.shots.size():
			for a2: Dictionary in bake.shots[i3]["actions"]:
				var w2 := String(a2["actor"]) if String(a2["actor"]) != "" else "(cues)"
				if w2 != who:
					continue
				var k := String(a2["kind"])
				var ax: int = px.call(ev.starts[i3] + float(a2["at"]))
				var col2: Color = KIND_COLORS.get(k, Color.WHITE)
				if k == "move":
					var tgt: Vector3 = a2["target"]
					var st: Dictionary = ev.actor(who, ev.starts[i3] + float(a2["at"]))
					var dur := (st["pos"] as Vector3).distance_to(tgt) / maxf(0.05, float(a2["params"].get("speed", 2.0)))
					ToolSheet.rect(img, Rect2i(ax, y + 12, maxi(2, int(dur / maxf(0.001, ev.total) * span)), 10), Color(col2, 0.6))
				ToolSheet.rect(img, Rect2i(ax, y, 3, row_h), col2)
				ToolSheet.text(img, ax + 5, y + 2, KIND_LETTER.get(k, "?"), col2, 2)
		y += row_h + 6
	# music
	ToolSheet.text(img, 8, y + 10, "MUSIC", ToolSheet.FG, 2)
	if doc.music != "":
		ToolSheet.rect(img, Rect2i(LEFT, y, int(span), row_h), Color(0.25, 0.5, 0.3))
		ToolSheet.text(img, LEFT + 4, y + 10, ToolSheet.clip(doc.music.get_file(), int(span) - 8, 2), ToolSheet.FG, 2)
	for i4: int in bake.shots.size():
		for a3: Dictionary in bake.shots[i4]["actions"]:
			if String(a3["kind"]) == "music":
				var mx: int = px.call(ev.starts[i4] + float(a3["at"]))
				ToolSheet.rect(img, Rect2i(mx, y, LEFT + int(span) - mx, row_h), Color(0.25, 0.5, 0.3))
				ToolSheet.text(img, mx + 4, y + 10, ToolSheet.clip(String(a3["params"]["path"]).get_file(), LEFT + int(span) - mx - 8, 2), ToolSheet.FG, 2)
	y += row_h + 12
	var legend := "LEGEND  M MOVE  T TELEPORT  F FACE  A ANIM  C CLIP  V VFX  S SFX  U MUSIC  K SHAKE  D FADE  I TITLE  H SHOW/HIDE   LINE COLOUR: GREEN <= 17 CPS, AMBER <= 22, RED OVER / TOO LONG"
	ToolSheet.text(img, 10, y, ToolSheet.clip(legend, W - 20, 1), Color(0.7, 0.7, 0.7), 1)
	return img
