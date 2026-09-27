shader_type spatial;
// Flickering flame billboard (SpellVfx): the `haste` mark above a unit's head (task A.13: instance uniforms so
// every pooled mark shares one material). Draw on a QuadMesh; size = node scale.
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 color_core : source_color = vec4(1.0, 0.7, 0.25, 1.0);
uniform vec4 color_edge : source_color = vec4(1.0, 0.25, 0.03, 1.0);
uniform float energy = 2.2;
instance uniform float fade = 1.0;
instance uniform float seed = 0.0;

void vertex() {
	// Face the camera, keep the node's scale.
	float s = length(MODEL_MATRIX[0].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * s, INV_VIEW_MATRIX[1] * s,
			INV_VIEW_MATRIX[2] * s, MODEL_MATRIX[3]);
}

void fragment() {
	vec2 uv = vec2(UV.x, 1.0 - UV.y);   // y = 0 at the bottom
	float t = TIME * 7.0 + seed * 10.0;
	float x = (uv.x - 0.5) + sin(uv.y * 7.0 - t) * 0.07 * uv.y;
	float w = 0.34 * pow(max(0.0, 1.0 - uv.y), 0.8) * (0.9 + 0.1 * sin(t * 1.3));
	float body = (1.0 - smoothstep(w * 0.55, w, abs(x))) * smoothstep(0.0, 0.2, uv.y);
	float core = (1.0 - smoothstep(0.0, w * 0.55, abs(x))) * (1.0 - smoothstep(0.1, 0.7, uv.y));
	vec3 c = mix(color_edge.rgb, color_core.rgb, core) * energy * (0.85 + 0.15 * sin(t * 2.1));
	float a = clamp(body * fade, 0.0, 1.0);
	// A little cover so the flame stays orange (not white) over bright ground.
	ALBEDO = c * a;
	ALPHA = a * 0.3;
}
