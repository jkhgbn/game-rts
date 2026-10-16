// frozen_ice_back.gdshader - the far inner faces of a frozen block (FrozenBlockArt next_pass, Medium and up):
// drawn before the front faces (render_priority -1) in deep ice blue so the block reads as a volume of ice, not a
// glass case. Unshaded, no depth write.
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_front, unshaded, shadows_disabled;

uniform vec3 ice_deep : source_color = vec3(0.13, 0.27, 0.37);
uniform float back_alpha = 0.32;

void fragment() {
	ALBEDO = ice_deep;
	ALPHA = back_alpha;
}
