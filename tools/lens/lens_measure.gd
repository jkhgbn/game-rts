class_name LensMeasure
extends RefCounted
## Pixel metrics of Lens (pure Image math, headless-safe on given images): masks from ID passes (white subject on black,
## or alpha), bounding boxes, coverage, contrast (luminance ratio + CIE76 dE between subject and nearby background).

## Mask stats of an ID-pass image: {count, bbox: Rect2i (empty when count 0), rows_in: count inside [y0, y1)}.
## A pixel is "on" when its red channel > 0.5 (use_alpha: alpha > 0.5).
static func mask_stats(img: Image, use_alpha: bool = false, band: Rect2i = Rect2i()) -> Dictionary:
	var w := img.get_width()
	var h := img.get_height()
	var data := img.get_data()
	var fmt := img.get_format()
	var stride := 4 if fmt == Image.FORMAT_RGBA8 else 3
	var ch := 3 if use_alpha else 0
	var mnx := w
	var mny := h
	var mxx := -1
	var mxy := -1
	var count := 0
	var inside := 0
	for y: int in h:
		var row := y * w * stride
		for x: int in w:
			if data[row + x * stride + ch] > 127:
				count += 1
				if x < mnx:
					mnx = x
				if x > mxx:
					mxx = x
				if y < mny:
					mny = y
				if y > mxy:
					mxy = y
				if band.size.y > 0 and y >= band.position.y and y < band.end.y:
					inside += 1
	var bbox := Rect2i() if count == 0 else Rect2i(mnx, mny, mxx - mnx + 1, mxy - mny + 1)
	return {"count": count, "bbox": bbox, "inside": inside}


## Boolean mask (PackedByteArray 0/1, w*h) of an ID pass.
static func mask_of(img: Image, use_alpha: bool = false) -> PackedByteArray:
	var w := img.get_width()
	var h := img.get_height()
	var data := img.get_data()
	var stride := 4 if img.get_format() == Image.FORMAT_RGBA8 else 3
	var ch := 3 if use_alpha else 0
	var out := PackedByteArray()
	out.resize(w * h)
	for i: int in w * h:
		out[i] = 1 if data[i * stride + ch] > 127 else 0
	return out


## Mean colour of the beauty image under the mask, and of the background ring around the mask's bbox (the bbox grown by
## `grow` of its size, minus the mask). Returns {subject: Color, background: Color, lum_ratio, delta_e, n_subject, n_bg}.
static func contrast(beauty: Image, mask: PackedByteArray, bbox: Rect2i, grow: float = 0.35) -> Dictionary:
	var w := beauty.get_width()
	var h := beauty.get_height()
	var g := Vector2i(int(bbox.size.x * grow) + 4, int(bbox.size.y * grow) + 4)
	var r := Rect2i(bbox.position - g, bbox.size + g * 2).intersection(Rect2i(0, 0, w, h))
	var data := beauty.get_data()
	var stride := 4 if beauty.get_format() == Image.FORMAT_RGBA8 else 3
	var sa := Vector3.ZERO
	var ba := Vector3.ZERO
	var ns := 0
	var nb := 0
	var step := maxi(1, int(sqrt(float(r.size.x * r.size.y) / 60000.0)))
	for y: int in range(r.position.y, r.end.y, step):
		for x: int in range(r.position.x, r.end.x, step):
			var i := y * w + x
			var c := Vector3(data[i * stride], data[i * stride + 1], data[i * stride + 2]) / 255.0
			if mask[i] == 1:
				sa += c
				ns += 1
			else:
				ba += c
				nb += 1
	if ns == 0 or nb == 0:
		return {"subject": Color.BLACK, "background": Color.BLACK, "lum_ratio": 1.0, "delta_e": 0.0, "n_subject": ns, "n_bg": nb}
	var cs := Color(sa.x / ns, sa.y / ns, sa.z / ns)
	var cb := Color(ba.x / nb, ba.y / nb, ba.z / nb)
	var ls := luminance(cs)
	var lb := luminance(cb)
	return {"subject": cs, "background": cb, "lum_ratio": (maxf(ls, lb) + 0.05) / (minf(ls, lb) + 0.05),
		"delta_e": delta_e(cs, cb), "n_subject": ns, "n_bg": nb}


## WCAG relative luminance of an sRGB colour.
static func luminance(c: Color) -> float:
	var l := c.srgb_to_linear()
	return 0.2126 * l.r + 0.7152 * l.g + 0.0722 * l.b


## CIE76 delta E between two sRGB colours.
static func delta_e(a: Color, b: Color) -> float:
	var la := lab(a)
	var lb := lab(b)
	return la.distance_to(lb)


static func lab(c: Color) -> Vector3:
	var l := c.srgb_to_linear()
	var x := (0.4124 * l.r + 0.3576 * l.g + 0.1805 * l.b) / 0.95047
	var y := 0.2126 * l.r + 0.7152 * l.g + 0.0722 * l.b
	var z := (0.0193 * l.r + 0.1192 * l.g + 0.9505 * l.b) / 1.08883
	var f := func(t: float) -> float: return pow(t, 1.0 / 3.0) if t > 0.008856 else 7.787 * t + 16.0 / 116.0
	var fx: float = f.call(x)
	var fy: float = f.call(y)
	var fz: float = f.call(z)
	return Vector3(116.0 * fy - 16.0, 500.0 * (fx - fy), 200.0 * (fy - fz))


## 48 px legibility of an icon (UI Lab style): silhouette share of the tile at 48 px and the subject / background
## luminance contrast there. {fill, contrast, delta_e}.
static func legibility(icon: Image, subject_mask_img: Image) -> Dictionary:
	var a := icon.duplicate() as Image
	a.resize(48, 48, Image.INTERPOLATE_LANCZOS)
	var m := subject_mask_img.duplicate() as Image
	m.resize(48, 48, Image.INTERPOLATE_BILINEAR)
	var st := mask_stats(m, true)
	var mk := mask_of(m, true)
	var ct := contrast(a, mk, st["bbox"] if st["count"] > 0 else Rect2i(0, 0, 48, 48), 0.5)
	return {"fill": float(st["count"]) / (48.0 * 48.0), "contrast": ct["lum_ratio"], "delta_e": ct["delta_e"]}
