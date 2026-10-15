shader_type spatial;
// G-D combat feedback: additive glowing puffs: Shadow wisps, Nature spores, Fire heat glow, Ice glints.
// Layout in cg_puff.gdshaderinc.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, skip_vertex_transform, fog_disabled;

#include "res://art/vfx/combat_g/cg_puff.gdshaderinc"

void fragment() {
	float s = puff_shape(v_uv, v_seed);
	ALBEDO = v_col.rgb * (0.6 + 0.6 * s);
	ALPHA = clamp(s * s * v_col.a, 0.0, 1.0);
}
