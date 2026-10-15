shader_type spatial;
// G-D combat feedback: mixed (opaque-ish) puffs: dust, smoke, frost steam. Layout in cg_puff.gdshaderinc.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, skip_vertex_transform;

#include "res://art/vfx/combat_g/cg_puff.gdshaderinc"

void fragment() {
	float s = puff_shape(v_uv, v_seed);
	// Lit from above: the top of the puff a little lighter, the bottom darker (reads as volume at zoom 30-40).
	float shade = mix(1.0, 0.72 + 0.5 * (1.0 - v_uv.y), v_top);
	ALBEDO = v_col.rgb * shade;
	ALPHA = clamp(s * v_col.a, 0.0, 1.0);
}
