shader_type spatial;
// Updraft wind column (MapFillBeastVfx, task 12.V31): an open cylinder (radius 1, height 1, no caps) scaled to the
// column; spiral wind bands climb and turn around it, brighter at the silhouette, fading at the foot and the top.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

instance uniform vec4 tint = vec4(0.9, 1.1, 1.4, 1.0);   // linear HDR, a = strength
instance uniform float fade = 1.0;
instance uniform float seed = 0.0;

varying float v_h;
varying float v_u;

void vertex() {
	v_h = VERTEX.y + 0.5;                                   // 0 foot .. 1 top
	v_u = atan(VERTEX.z, VERTEX.x) / 6.2831853 + 0.5;       // 0..1 around
}

void fragment() {
	float s = fract(v_u * 3.0 + v_h * 1.3 - TIME * 1.25 + seed);
	float band = smoothstep(0.0, 0.07, s) * pow(1.0 - s, 3.0);
	float s2 = fract(v_u * 5.0 + v_h * 2.2 - TIME * 2.0 + seed * 1.7);
	float band2 = smoothstep(0.0, 0.05, s2) * pow(1.0 - s2, 5.0) * 0.6;
	float vert = smoothstep(0.0, 0.18, v_h) * (1.0 - smoothstep(0.55, 1.0, v_h));
	float fres = pow(1.0 - abs(dot(NORMAL, VIEW)), 1.5);
	ALBEDO = tint.rgb * tint.a;
	ALPHA = clamp((band + band2) * vert * (0.3 + 0.7 * fres) * fade, 0.0, 1.0);
}
