class_name SiteOutline
extends RefCounted
## G-F Shadow leftovers (docs/art/gf_shadow_leftovers.md): the glowing construction outline (art-keep 8.2: four
## emissive bars round the footprint) in a calm style a model opts into (`outline_calm`, set by the Shadow models):
## thinner bars, a low steady emission, the team glow graded like the Dusk Keep lights (hue kept, saturation <= SAT,
## value <= VAL), so the site's flagstones and scaffold read before the outline. The default style is unchanged.

const ENERGY := 2.0         ## default outline energy (rune_glow `energy`)
const PULSE := TAU          ## default pulse speed (rad/s)
const CALM_ENERGY := 0.45   ## calm: albedo = c x (0.4 + 0.45 x pulse) ~ 0.8 c, never over the glow cap
const CALM_PULSE := 1.6     ## calm: a slow breath, not a 1 Hz blink
const CALM_WIDTH := 0.5     ## calm: bar width x this
const SAT := 0.4            ## calm: saturation cap (DuskKeepModel.LIGHT_SAT)
const VAL := 0.7            ## calm: value cap


static func energy(calm: bool) -> float:
	return CALM_ENERGY if calm else ENERGY


static func pulse(calm: bool) -> float:
	return CALM_PULSE if calm else PULSE


static func width(base: float, calm: bool) -> float:
	return base * CALM_WIDTH if calm else base


static func tint(glow: Color, calm: bool) -> Color:
	if not calm:
		return glow
	return Color.from_hsv(glow.h, minf(glow.s, SAT), minf(glow.v, VAL))
