extends RefCounted
## Visual Diff Lab (docs/plan/visual-diff-lab.md): the pure image maths. No scene, no autoload: the lab
## (visual_diff_lab.gd) and tests/test_visual_diff_lab.gd both preload it.
##   diff(golden, current, tolerance, masks, unstable) -> Dictionary   per-pixel compare
##   unstable_mask(a, b, tolerance) -> Image                           pixels that moved between two captures
##   heatmap(current, result, masks) -> Image                          dimmed shot + changed pixels in hot colours
##   compare_strip(golden, current, heat, scale) -> Image              golden | current | heatmap side by side
##   verdict(result) -> Dictionary                                     PASS / WARN / FAIL + score 0-100
## A pixel "changed" when its largest RGB channel difference is > tolerance (0-255). Masked pixels (ignore
## rectangles, or white in the unstable mask) are not compared and do not count in the percentage.

## Thresholds on the % of compared pixels that changed.
const PASS_PCT := 0.05
const WARN_PCT := 1.0
## Score 0-100: 100 at 0 %, 0 at SCORE_ZERO_PCT % changed (linear).
const SCORE_ZERO_PCT := 5.0
## A change is only "real" when at least this many pixels changed (single-pixel shimmer never FAILs).
const MIN_CHANGED_PX := 25


static func to_rgba8(img: Image) -> Image:
	if img == null:
		return null
	if img.get_format() == Image.FORMAT_RGBA8:
		return img
	var c := img.duplicate() as Image
	if c.is_compressed():
		c.decompress()
	c.convert(Image.FORMAT_RGBA8)
	return c


## A mask image (L8, 255 = ignore) from rectangles, or null when there are none.
static func rect_mask(size: Vector2i, rects: Array) -> Image:
	if rects.is_empty():
		return null
	var m := Image.create(size.x, size.y, false, Image.FORMAT_L8)
	for r: Variant in rects:
		var rr := (r as Rect2i).intersection(Rect2i(Vector2i.ZERO, size))
		if rr.has_area():
			m.fill_rect(rr, Color.WHITE)
	return m


## Pixels whose colour differs between two captures of the same frozen shot (animated / unstable regions),
## grown by `grow` px. L8 image, 255 = unstable. Returns [mask, unstable_px].
static func unstable_mask(a: Image, b: Image, tolerance: int, grow: int = 2) -> Array:
	var ia := to_rgba8(a)
	var ib := to_rgba8(b)
	var w := ia.get_width()
	var h := ia.get_height()
	var m := Image.create(w, h, false, Image.FORMAT_L8)
	if ib.get_width() != w or ib.get_height() != h:
		m.fill(Color.WHITE)
		return [m, w * h]
	var da := ia.get_data()
	var db := ib.get_data()
	var hits: Array[Vector2i] = []
	var n := w * h
	for p in n:
		var o := p * 4
		var d := maxi(maxi(absi(da[o] - db[o]), absi(da[o + 1] - db[o + 1])), absi(da[o + 2] - db[o + 2]))
		if d > tolerance:
			hits.append(Vector2i(p % w, p / w))
	for q: Vector2i in hits:
		m.fill_rect(Rect2i(q - Vector2i(grow, grow), Vector2i(grow * 2 + 1, grow * 2 + 1)).intersection(Rect2i(0, 0, w, h)), Color.WHITE)
	return [m, hits.size()]


## Union of two L8 masks (either may be null).
static func mask_union(a: Image, b: Image) -> Image:
	if a == null:
		return b
	if b == null:
		return a
	var out := a.duplicate() as Image
	var da := out.get_data()
	var db := b.get_data()
	if da.size() != db.size():
		return out
	for i in da.size():
		if db[i] > da[i]:
			da[i] = db[i]
	return Image.create_from_data(out.get_width(), out.get_height(), false, Image.FORMAT_L8, da)


## Per-pixel compare. `mask` = L8 image (255 = ignore) or null.
## Result: ok, error, width, height, compared_px, ignored_px, changed_px, changed_pct, max_delta, mean_delta
## (over changed pixels), bbox (Rect2i, zero size when nothing changed), delta (L8 image of the per-pixel delta,
## 0 where unchanged or ignored).
static func diff(golden: Image, current: Image, tolerance: int, mask: Image = null) -> Dictionary:
	var res := {"ok": false, "error": "", "width": 0, "height": 0, "compared_px": 0, "ignored_px": 0, "changed_px": 0,
		"changed_pct": 0.0, "max_delta": 0, "mean_delta": 0.0, "bbox": Rect2i(), "delta": null, "tolerance": tolerance}
	if golden == null or current == null:
		res["error"] = "missing image"
		return res
	var g := to_rgba8(golden)
	var c := to_rgba8(current)
	var w := c.get_width()
	var h := c.get_height()
	res["width"] = w
	res["height"] = h
	if g.get_width() != w or g.get_height() != h:
		res["error"] = "size mismatch: golden %dx%d, current %dx%d" % [g.get_width(), g.get_height(), w, h]
		return res
	var dg := g.get_data()
	var dc := c.get_data()
	var dm := PackedByteArray()
	var has_mask := mask != null and mask.get_width() == w and mask.get_height() == h
	if has_mask:
		dm = mask.get_data()
	var dd := PackedByteArray()
	dd.resize(w * h)
	var changed := 0
	var ignored := 0
	var sum := 0
	var mx := 0
	var x0 := w
	var y0 := h
	var x1 := -1
	var y1 := -1
	for p in w * h:
		if has_mask and dm[p] > 127:
			ignored += 1
			continue
		var o := p * 4
		var d := maxi(maxi(absi(dg[o] - dc[o]), absi(dg[o + 1] - dc[o + 1])), absi(dg[o + 2] - dc[o + 2]))
		if d > tolerance:
			changed += 1
			sum += d
			dd[p] = d
			if d > mx:
				mx = d
			var x := p % w
			var y := p / w
			x0 = mini(x0, x)
			x1 = maxi(x1, x)
			y0 = mini(y0, y)
			y1 = maxi(y1, y)
	var compared := w * h - ignored
	res["ok"] = true
	res["compared_px"] = compared
	res["ignored_px"] = ignored
	res["changed_px"] = changed
	res["changed_pct"] = 100.0 * float(changed) / float(maxi(compared, 1))
	res["max_delta"] = mx
	res["mean_delta"] = float(sum) / float(maxi(changed, 1))
	res["bbox"] = Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1) if changed > 0 else Rect2i()
	res["delta"] = Image.create_from_data(w, h, false, Image.FORMAT_L8, dd)
	return res


## PASS / WARN / FAIL + score for one diff result.
static func verdict(res: Dictionary, pass_pct: float = PASS_PCT, warn_pct: float = WARN_PCT) -> Dictionary:
	if not bool(res.get("ok", false)):
		return {"result": "FAIL", "score": 0, "why": String(res.get("error", "no result"))}
	var pct := float(res["changed_pct"])
	var px := int(res["changed_px"])
	var score := int(round(100.0 * clampf(1.0 - pct / SCORE_ZERO_PCT, 0.0, 1.0)))
	if px < MIN_CHANGED_PX or pct <= pass_pct:
		return {"result": "PASS", "score": score, "why": "no visible change" if px == 0 else
			"%d px (%.3f %%) changed, under the noise floor (%.2f %%)" % [px, pct, pass_pct]}
	if pct <= warn_pct:
		return {"result": "WARN", "score": score, "why": "small change: %.3f %% of the frame" % pct}
	return {"result": "FAIL", "score": score, "why": "visual change: %.2f %% of the frame" % pct}


## The current shot dimmed to 30 % grey, changed pixels painted yellow (small delta) to red (big delta), ignored
## pixels tinted blue, and the change bounding box outlined in magenta.
static func heatmap(current: Image, res: Dictionary, mask: Image = null) -> Image:
	var c := to_rgba8(current)
	var w := c.get_width()
	var h := c.get_height()
	var src := c.get_data()
	var out := PackedByteArray()
	out.resize(w * h * 4)
	var dd := PackedByteArray()
	var delta: Variant = res.get("delta")
	if delta is Image and (delta as Image).get_width() == w and (delta as Image).get_height() == h:
		dd = (delta as Image).get_data()
	var dm := PackedByteArray()
	if mask != null and mask.get_width() == w and mask.get_height() == h:
		dm = mask.get_data()
	for p in w * h:
		var o := p * 4
		var lum := int((src[o] * 77 + src[o + 1] * 150 + src[o + 2] * 29) >> 8)
		var gv := 20 + lum * 3 / 10
		var r := gv
		var g := gv
		var b := gv
		if not dd.is_empty() and dd[p] > 0:
			var t := clampf(float(dd[p]) / 128.0, 0.0, 1.0)
			r = 255
			g = int(lerpf(230.0, 20.0, t))
			b = 0
		elif not dm.is_empty() and dm[p] > 127:
			r = gv / 2
			g = gv / 2 + 20
			b = mini(255, gv + 90)
		out[o] = r
		out[o + 1] = g
		out[o + 2] = b
		out[o + 3] = 255
	var img := Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, out)
	var bb: Rect2i = res.get("bbox", Rect2i())
	if bb.has_area():
		var box := bb.grow(3).intersection(Rect2i(0, 0, w, h))
		var col := Color(1.0, 0.2, 1.0)
		img.fill_rect(Rect2i(box.position, Vector2i(box.size.x, 2)), col)
		img.fill_rect(Rect2i(Vector2i(box.position.x, box.end.y - 2), Vector2i(box.size.x, 2)), col)
		img.fill_rect(Rect2i(box.position, Vector2i(2, box.size.y)), col)
		img.fill_rect(Rect2i(Vector2i(box.end.x - 2, box.position.y), Vector2i(2, box.size.y)), col)
	return img


## golden | current | heatmap, each scaled by `scale`, 4 px dark gutters.
static func compare_strip(golden: Image, current: Image, heat: Image, scale: float = 0.34) -> Image:
	var panels: Array[Image] = []
	for src: Image in [golden, current, heat]:
		var p: Image
		if src == null:
			p = Image.create(maxi(1, int(current.get_width() * scale)), maxi(1, int(current.get_height() * scale)), false, Image.FORMAT_RGBA8)
			p.fill(Color(0.3, 0.0, 0.0))
		else:
			p = to_rgba8(src).duplicate() as Image
			p.resize(maxi(1, int(src.get_width() * scale)), maxi(1, int(src.get_height() * scale)), Image.INTERPOLATE_BILINEAR)
		panels.append(p)
	var gut := 4
	var pw := panels[1].get_width()
	var ph := panels[1].get_height()
	var out := Image.create(pw * 3 + gut * 4, ph + gut * 2, false, Image.FORMAT_RGBA8)
	out.fill(Color(0.08, 0.08, 0.1))
	for i in 3:
		var p2 := panels[i]
		out.blit_rect(p2, Rect2i(0, 0, mini(p2.get_width(), pw), mini(p2.get_height(), ph)), Vector2i(gut + i * (pw + gut), gut))
	return out


## Human name for where a box sits in a WxH frame ("top-left", "centre", ...).
static func region_name(box: Rect2i, size: Vector2i) -> String:
	if not box.has_area():
		return "-"
	var c := box.get_center()
	var col := "left" if c.x < size.x / 3 else ("right" if c.x > size.x * 2 / 3 else "centre")
	var row := "top" if c.y < size.y / 3 else ("bottom" if c.y > size.y * 2 / 3 else "middle")
	if row == "middle" and col == "centre":
		return "centre"
	return "%s-%s" % [row, col]
