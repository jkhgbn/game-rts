class_name ArtLabImage
extends RefCounted
## Art Lab (docs/plan/art-lab.md): pixel analysis on the 1600 x 900 renders. Pure functions, no scene access, so the
## headless test (tests/test_art_lab.gd) checks them on synthetic images.
## Every analysis works on a region of interest (ROI, a Rect2i of the full frame) and a Mask of the same size
## (1 = model pixel). Images are RGBA8 in sRGB (what the viewport texture gives).

## A binary mask over an ROI (w x h). `count` and `bbox` (in ROI pixels) are filled by finish().
class Mask:
	extends RefCounted
	var w: int = 0
	var h: int = 0
	var bits: PackedByteArray = PackedByteArray()
	var count: int = 0
	var bbox: Rect2i = Rect2i()

	func _init(width: int = 0, height: int = 0) -> void:
		w = width
		h = height
		bits.resize(w * h)

	func at(x: int, y: int) -> bool:
		return x >= 0 and y >= 0 and x < w and y < h and bits[y * w + x] != 0

	func finish() -> Mask:
		count = 0
		var x0 := w
		var y0 := h
		var x1 := -1
		var y1 := -1
		for y: int in h:
			var row := y * w
			for x: int in w:
				if bits[row + x] != 0:
					count += 1
					x0 = mini(x0, x)
					x1 = maxi(x1, x)
					y0 = mini(y0, y)
					y1 = maxi(y1, y)
		bbox = Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1) if count > 0 else Rect2i()
		return self


static var _lin_lut: PackedFloat32Array = PackedFloat32Array()


## sRGB byte -> linear 0-1 (table).
static func lin(v: int) -> float:
	if _lin_lut.is_empty():
		_lin_lut.resize(256)
		for i: int in 256:
			var c := float(i) / 255.0
			_lin_lut[i] = c / 12.92 if c <= 0.04045 else pow((c + 0.055) / 1.055, 2.4)
	return _lin_lut[v]


## CIE L*a*b* (D65) of an sRGB byte triple.
static func lab(r: int, g: int, b: int) -> Vector3:
	var rl := lin(r)
	var gl := lin(g)
	var bl := lin(b)
	var x := (0.4124 * rl + 0.3576 * gl + 0.1805 * bl) / 0.95047
	var y := 0.2126 * rl + 0.7152 * gl + 0.0722 * bl
	var z := (0.0193 * rl + 0.1192 * gl + 0.9505 * bl) / 1.08883
	var fx := _f(x)
	var fy := _f(y)
	var fz := _f(z)
	return Vector3(116.0 * fy - 16.0, 500.0 * (fx - fy), 200.0 * (fy - fz))


static func _f(t: float) -> float:
	return pow(t, 1.0 / 3.0) if t > 0.008856 else 7.787 * t + 16.0 / 116.0


## Luma 0-1 of an sRGB byte triple (Rec. 709 weights on the encoded values: a "how bright it looks" number).
static func luma(r: int, g: int, b: int) -> float:
	return (0.2126 * float(r) + 0.7152 * float(g) + 0.0722 * float(b)) / 255.0


static func rgba8(img: Image) -> Image:
	if img.get_format() == Image.FORMAT_RGBA8:
		return img
	var c := img.duplicate() as Image
	c.convert(Image.FORMAT_RGBA8)
	return c


## Silhouette mask: pixels darker than `thr` (luma) in a black-on-white render.
static func sil_mask(img: Image, roi: Rect2i, thr: float = 0.5) -> Mask:
	var im := rgba8(img)
	var data := im.get_data()
	var iw := im.get_width()
	var m := Mask.new(roi.size.x, roi.size.y)
	var t := int(thr * 255.0)
	for y: int in roi.size.y:
		var src := ((roi.position.y + y) * iw + roi.position.x) * 4
		var row := y * m.w
		for x: int in roi.size.x:
			var i := src + x * 4
			# luma on bytes, integer math: 54 r + 183 g + 19 b (sum 256)
			if (54 * data[i] + 183 * data[i + 1] + 19 * data[i + 2]) >> 8 < t:
				m.bits[row + x] = 1
	return m.finish()


## Intersection over union of two masks of the same size (0 when both are empty).
static func iou(a: Mask, b: Mask) -> float:
	if a.w != b.w or a.h != b.h:
		return 0.0
	var inter := 0
	var uni := 0
	for i: int in a.bits.size():
		var p := a.bits[i] != 0
		var q := b.bits[i] != 0
		if p and q:
			inter += 1
		if p or q:
			uni += 1
	return float(inter) / float(uni) if uni > 0 else 0.0


## Colour of the model against what is behind it: `lit` = the frame with the model, `bg` = the same frame without it.
## Per mask pixel: CIE76 delta E between the two frames. Returns
##   de_mean, de_p25 (the quarter of the body that stands out least), stand_frac (share of pixels with dE > 12),
##   model_L, ground_L, dL (model - ground), model_C, ground_C (chroma), hue_gap (deg, chroma-weighted), model_lab,
##   ground_lab (means), edge_de (dE across the outline: body pixel vs the ground pixel just outside it).
static func contrast(lit: Image, bg: Image, roi: Rect2i, m: Mask) -> Dictionary:
	var a := rgba8(lit).get_data()
	var b := rgba8(bg).get_data()
	var iw := lit.get_width()
	var des := PackedFloat32Array()
	var sum_m := Vector3.ZERO
	var sum_g := Vector3.ZERO
	var n := 0
	var stand := 0
	var edge_sum := 0.0
	var edge_n := 0
	for y: int in m.h:
		for x: int in m.w:
			if m.bits[y * m.w + x] == 0:
				continue
			var i := (((roi.position.y + y) * iw) + roi.position.x + x) * 4
			var la := lab(a[i], a[i + 1], a[i + 2])
			var lb := lab(b[i], b[i + 1], b[i + 2])
			var de := la.distance_to(lb)
			des.append(de)
			sum_m += la
			sum_g += lb
			n += 1
			if de > 12.0:
				stand += 1
			# outline: a body pixel with a ground neighbour 2 px away (in the lit frame)
			for d: Vector2i in [Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2)]:
				var qx := x + d.x
				var qy := y + d.y
				if qx < 0 or qy < 0 or qx >= m.w or qy >= m.h or m.bits[qy * m.w + qx] != 0:
					continue
				var j := (((roi.position.y + qy) * iw) + roi.position.x + qx) * 4
				edge_sum += la.distance_to(lab(a[j], a[j + 1], a[j + 2]))
				edge_n += 1
				break
	if n == 0:
		return {"n": 0}
	des.sort()
	var mm := sum_m / float(n)
	var gg := sum_g / float(n)
	var cm := Vector2(mm.y, mm.z).length()
	var cg := Vector2(gg.y, gg.z).length()
	var hue_gap := 0.0
	if cm > 4.0 and cg > 4.0:
		hue_gap = rad_to_deg(absf(angle_difference(atan2(mm.z, mm.y), atan2(gg.z, gg.y))))
	var total := 0.0
	for d: float in des:
		total += d
	# "melt": body pixels whose colour is within dE 15 of the MEAN ground colour (what the eye averages at 40 m; the
	# per-pixel dE above is inflated by the grass texture and the body's own shading)
	var melt := 0
	for y2: int in m.h:
		for x2: int in m.w:
			if m.bits[y2 * m.w + x2] == 0:
				continue
			var k := (((roi.position.y + y2) * iw) + roi.position.x + x2) * 4
			if lab(a[k], a[k + 1], a[k + 2]).distance_to(gg) < 15.0:
				melt += 1
	return {
		"de_means": mm.distance_to(gg),
		"melt_frac": float(melt) / float(n),
		"n": n,
		"de_mean": total / float(n),
		"de_p25": des[int(float(n - 1) * 0.25)],
		"stand_frac": float(stand) / float(n),
		"model_L": mm.x,
		"ground_L": gg.x,
		"dL": mm.x - gg.x,
		"model_C": cm,
		"ground_C": cg,
		"hue_gap": hue_gap,
		"model_lab": mm,
		"ground_lab": gg,
		"edge_de": edge_sum / float(edge_n) if edge_n > 0 else 0.0,
	}


## Share of mask pixels whose colour differs by more than `de_thr` (CIE76) between two frames.
static func changed_fraction(img_a: Image, img_b: Image, roi: Rect2i, m: Mask, de_thr: float = 8.0) -> float:
	var a := rgba8(img_a).get_data()
	var b := rgba8(img_b).get_data()
	var iw := img_a.get_width()
	var n := 0
	var ch := 0
	for y: int in m.h:
		for x: int in m.w:
			if m.bits[y * m.w + x] == 0:
				continue
			var i := (((roi.position.y + y) * iw) + roi.position.x + x) * 4
			n += 1
			if lab(a[i], a[i + 1], a[i + 2]).distance_to(lab(b[i], b[i + 1], b[i + 2])) > de_thr:
				ch += 1
	return float(ch) / float(n) if n > 0 else 0.0


## Mean L*a*b* of the mask pixels of one frame.
static func mean_lab(img: Image, roi: Rect2i, m: Mask) -> Vector3:
	var a := rgba8(img).get_data()
	var iw := img.get_width()
	var s := Vector3.ZERO
	var n := 0
	for y: int in m.h:
		for x: int in m.w:
			if m.bits[y * m.w + x] != 0:
				var i := (((roi.position.y + y) * iw) + roi.position.x + x) * 4
				s += lab(a[i], a[i + 1], a[i + 2])
				n += 1
	return s / float(n) if n > 0 else Vector3.ZERO


## Glow points: bright clusters in a render where only emission shows (black world, no lights). Pixels brighter than
## `thr` (luma 0-1) are grown by `merge_px` (clusters closer than that count as one point, as the eye does at 40 m),
## labelled 8-connected, and every cluster with at least `min_px` bright pixels is returned as
## {area, x, y (ROI centroid), peak (max luma)}, biggest first.
## `use_max`: judge a pixel by its brightest channel instead of luma (the "hot" pass: a saturated red / orange / blue
## emission reaches 255 on one channel at the bloom level while its luma stays low).
static func glow_clusters(img: Image, roi: Rect2i, thr: float = 0.35, merge_px: int = 3, min_px: int = 2,
		use_max: bool = false) -> Array[Dictionary]:
	var im := rgba8(img)
	var data := im.get_data()
	var iw := im.get_width()
	var w := roi.size.x
	var h := roi.size.y
	var hot := PackedByteArray()
	hot.resize(w * h)
	var lum := PackedFloat32Array()
	lum.resize(w * h)
	for y: int in h:
		for x: int in w:
			var i := (((roi.position.y + y) * iw) + roi.position.x + x) * 4
			var l := float(maxi(data[i], maxi(data[i + 1], data[i + 2]))) / 255.0 if use_max else luma(data[i], data[i + 1], data[i + 2])
			lum[y * w + x] = l
			if l > thr:
				hot[y * w + x] = 1
	var grown := dilate(hot, w, h, merge_px)
	var label := PackedInt32Array()
	label.resize(w * h)
	var out: Array[Dictionary] = []
	var stack := PackedInt32Array()
	var next_id := 0
	for start: int in w * h:
		if grown[start] == 0 or label[start] != 0:
			continue
		next_id += 1
		var area := 0
		var sx := 0.0
		var sy := 0.0
		var peak := 0.0
		stack.clear()
		stack.append(start)
		label[start] = next_id
		while not stack.is_empty():
			var p := stack[stack.size() - 1]
			stack.remove_at(stack.size() - 1)
			var px := p % w
			var py := p / w
			if hot[p] != 0:
				area += 1
				sx += px
				sy += py
				peak = maxf(peak, lum[p])
			for dy: int in [-1, 0, 1]:
				for dx: int in [-1, 0, 1]:
					var qx := px + dx
					var qy := py + dy
					if qx < 0 or qy < 0 or qx >= w or qy >= h:
						continue
					var q := qy * w + qx
					if grown[q] != 0 and label[q] == 0:
						label[q] = next_id
						stack.append(q)
		if area >= min_px:
			out.append({"area": area, "x": sx / area, "y": sy / area, "peak": peak})
	out.sort_custom(func(p: Dictionary, q: Dictionary) -> bool: return int(p["area"]) > int(q["area"]))
	return out


## Square dilation of a 0/1 map by r pixels (separable running max).
static func dilate(bits: PackedByteArray, w: int, h: int, r: int) -> PackedByteArray:
	if r <= 0:
		return bits.duplicate()
	var tmp := PackedByteArray()
	tmp.resize(w * h)
	for y: int in h:
		var last := -100000
		for x: int in w:
			if bits[y * w + x] != 0:
				last = x
			if x - last <= r:
				tmp[y * w + x] = 1
		last = 100000
		for x: int in range(w - 1, -1, -1):
			if bits[y * w + x] != 0:
				last = x
			if last - x <= r:
				tmp[y * w + x] = 1
	var out := PackedByteArray()
	out.resize(w * h)
	for x: int in w:
		var last := -100000
		for y: int in h:
			if tmp[y * w + x] != 0:
				last = y
			if y - last <= r:
				out[y * w + x] = 1
		last = 100000
		for y: int in range(h - 1, -1, -1):
			if tmp[y * w + x] != 0:
				last = y
			if last - y <= r:
				out[y * w + x] = 1
	return out


## Outline complexity: perimeter^2 / (4 pi area). A disc is 1; a plain blob ~1.3-1.8; horns, weapons, wings and gaps
## push it up (a strong silhouette "hook" at 40 m is usually >= 2.2).
static func complexity(m: Mask) -> float:
	if m.count < 4:
		return 0.0
	var per := 0
	for y: int in m.h:
		for x: int in m.w:
			if m.bits[y * m.w + x] == 0:
				continue
			if not m.at(x + 1, y) or not m.at(x - 1, y) or not m.at(x, y + 1) or not m.at(x, y - 1):
				per += 1
	return float(per * per) / (4.0 * PI * float(m.count))


## Left / right asymmetry about the vertical line x = axis (ROI px): 1 - IoU(mask, mirrored mask). 0 = mirror
## symmetric; the art-keep rule "one asymmetric secondary element" shows as >= ~0.15.
static func asymmetry(m: Mask, axis: float) -> float:
	var inter := 0
	var uni := 0
	for y: int in m.h:
		for x: int in m.w:
			var p := m.bits[y * m.w + x] != 0
			var mx := int(round(2.0 * axis - float(x)))
			var q := m.at(mx, y)
			if p and q:
				inter += 1
			if p or q:
				uni += 1
	return 1.0 - (float(inter) / float(uni) if uni > 0 else 1.0)


## Mean L* of the top third and the bottom third of the silhouette (by the mask's bbox rows). art-keep 0.1: tops
## light, bottoms dark -> top - bottom > 0.
static func value_bands(img: Image, roi: Rect2i, m: Mask) -> Vector2:
	if m.count == 0:
		return Vector2.ZERO
	var a := rgba8(img).get_data()
	var iw := img.get_width()
	var y_top := m.bbox.position.y + m.bbox.size.y / 3
	var y_bot := m.bbox.position.y + (m.bbox.size.y * 2) / 3
	var st := 0.0
	var nt := 0
	var sb := 0.0
	var nb := 0
	for y: int in m.h:
		for x: int in m.w:
			if m.bits[y * m.w + x] == 0:
				continue
			if y > y_top and y < y_bot:
				continue
			var i := (((roi.position.y + y) * iw) + roi.position.x + x) * 4
			var l := lab(a[i], a[i + 1], a[i + 2]).x
			if y <= y_top:
				st += l
				nt += 1
			else:
				sb += l
				nb += 1
	return Vector2(st / float(maxi(nt, 1)), sb / float(maxi(nb, 1)))


## Height (0-1) from the world-height pass at ROI pixel (x, y) (the pass writes linear grey, the frame is sRGB).
static func height_at(hgt: Image, roi: Rect2i, x: int, y: int) -> float:
	var px := clampi(roi.position.x + x, 0, hgt.get_width() - 1)
	var py := clampi(roi.position.y + y, 0, hgt.get_height() - 1)
	var c := hgt.get_pixel(px, py)
	return lin(clampi(int(round(c.r * 255.0)), 0, 255))


## Sub-mask of `m` whose world height (height pass, 0-1 of the model's height) is in [h0, h1].
static func height_mask(m: Mask, hgt: Image, roi: Rect2i, h0: float, h1: float) -> Mask:
	var out := Mask.new(m.w, m.h)
	var data := rgba8(hgt).get_data()
	var iw := hgt.get_width()
	for y: int in m.h:
		for x: int in m.w:
			if m.bits[y * m.w + x] == 0:
				continue
			var i := (((roi.position.y + y) * iw) + roi.position.x + x) * 4
			var hv := lin(data[i])
			if hv >= h0 and hv <= h1:
				out.bits[y * m.w + x] = 1
	return out.finish()


## Sub-mask of the top `frac` of the mask's rows (screen space).
static func top_rows(m: Mask, frac: float) -> Mask:
	var out := Mask.new(m.w, m.h)
	var y1 := m.bbox.position.y + int(float(m.bbox.size.y) * frac)
	for y: int in range(m.bbox.position.y, mini(y1 + 1, m.h)):
		for x: int in m.w:
			out.bits[y * m.w + x] = m.bits[y * m.w + x]
	return out.finish()


## Mean L* of the mask pixels.
static func mean_l(img: Image, roi: Rect2i, m: Mask) -> float:
	return mean_lab(img, roi, m).x


## True when ROI pixel (x, y) is within `r` px of the mask's outline (or outside the mask).
static func near_edge(m: Mask, x: int, y: int, r: int = 2) -> bool:
	for dy: int in range(-r, r + 1):
		for dx: int in range(-r, r + 1):
			if not m.at(x + dx, y + dy):
				return true
	return false


## Inner detail: mean |grad L*| over mask pixels whose 4 neighbours are also in the mask (the outline excluded).
static func detail(img: Image, roi: Rect2i, m: Mask) -> float:
	var a := rgba8(img).get_data()
	var iw := img.get_width()
	var s := 0.0
	var n := 0
	for y: int in range(1, m.h - 1):
		for x: int in range(1, m.w - 1):
			if not (m.at(x, y) and m.at(x + 1, y) and m.at(x - 1, y) and m.at(x, y + 1) and m.at(x, y - 1)):
				continue
			var i := (((roi.position.y + y) * iw) + roi.position.x + x) * 4
			var l0 := lab(a[i], a[i + 1], a[i + 2]).x
			var ir := i + 4
			var id := i + iw * 4
			var gx := lab(a[ir], a[ir + 1], a[ir + 2]).x - l0
			var gy := lab(a[id], a[id + 1], a[id + 2]).x - l0
			s += sqrt(gx * gx + gy * gy)
			n += 1
	return s / float(n) if n > 0 else 0.0


## Mask pixels inside a rectangle (ROI px).
static func count_in_rect(m: Mask, r: Rect2i) -> int:
	var c := 0
	var x0 := maxi(0, r.position.x)
	var y0 := maxi(0, r.position.y)
	var x1 := mini(m.w, r.end.x)
	var y1 := mini(m.h, r.end.y)
	for y: int in range(y0, y1):
		for x: int in range(x0, x1):
			if m.bits[y * m.w + x] != 0:
				c += 1
	return c


## Black-on-white picture of a mask (for the sheets).
static func mask_image(m: Mask, fg: Color = Color.BLACK, bg: Color = Color.WHITE) -> Image:
	var img := Image.create(maxi(m.w, 1), maxi(m.h, 1), false, Image.FORMAT_RGBA8)
	img.fill(bg)
	for y: int in m.h:
		for x: int in m.w:
			if m.bits[y * m.w + x] != 0:
				img.set_pixel(x, y, fg)
	return img


## Rect grown by `margin`, clamped to (0, 0, w, h).
static func clamp_rect(r: Rect2i, margin: int, w: int, h: int) -> Rect2i:
	var x0 := clampi(r.position.x - margin, 0, w - 1)
	var y0 := clampi(r.position.y - margin, 0, h - 1)
	var x1 := clampi(r.end.x + margin, x0 + 1, w)
	var y1 := clampi(r.end.y + margin, y0 + 1, h)
	return Rect2i(x0, y0, x1 - x0, y1 - y0)


## Resizes `img` to fit inside (w, h) keeping the aspect, centred on a `bg` canvas.
static func fit(img: Image, w: int, h: int, bg: Color = Color(0.1, 0.1, 0.1), nearest: bool = false) -> Image:
	var src := rgba8(img).duplicate() as Image
	var s := minf(float(w) / float(src.get_width()), float(h) / float(src.get_height()))
	var nw := maxi(1, int(float(src.get_width()) * s))
	var nh := maxi(1, int(float(src.get_height()) * s))
	src.resize(nw, nh, Image.INTERPOLATE_NEAREST if nearest else Image.INTERPOLATE_BILINEAR)
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	out.fill(bg)
	out.blit_rect(src, Rect2i(0, 0, nw, nh), Vector2i((w - nw) / 2, (h - nh) / 2))
	return out


## Tiles images (all resized to fit tw x th) in a grid of `cols` columns.
static func grid(imgs: Array[Image], cols: int, tw: int, th: int, bg: Color = Color(0.1, 0.1, 0.1),
		nearest: bool = false) -> Image:
	var n := maxi(imgs.size(), 1)
	var c := mini(cols, n)
	var rows := (n + c - 1) / c
	var out := Image.create(tw * c, th * rows, false, Image.FORMAT_RGBA8)
	out.fill(bg)
	for i: int in imgs.size():
		var t := fit(imgs[i], tw, th, bg, nearest)
		out.blit_rect(t, Rect2i(0, 0, tw, th), Vector2i((i % c) * tw, (i / c) * th))
	return out
