shader_type spatial;
// Flare Arrow in flight (ChampionVfx, task 9.V5). A QuadMesh 1 x 1 drawn as a billboard that only turns around its
// own Y axis (like combat_streak): the node basis Y = flight direction x length, X = width. Head at +Y.
// Dark wooden shaft, bright steel head, amber fletching, wrapped in an amber glow that is hottest at the tip.
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, skip_vertex_transform, fog_disabled;

instance uniform vec4 tint = vec4(2.0, 1.4, 0.6, 1.0);   // glow colour (linear HDR), a = strength
instance uniform float fade = 1.0;
instance uniform float age = 0.0;

varying vec2 v_uv;

void vertex() {
	vec3 center = (MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 axis = (MODELVIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz;
	float width = length((MODELVIEW_MATRIX * vec4(1.0, 0.0, 0.0, 0.0)).xyz);
	vec3 to_cam = normalize(-center);
	vec3 side = cross(axis, to_cam);
	float sl = length(side);
	side = sl > 0.00001 ? side / sl : vec3(1.0, 0.0, 0.0);
	float al = length(axis);
	vec3 along = al > 0.00001 ? axis / al : vec3(0.0, 1.0, 0.0);
	float len = max(al, width);
	VERTEX = center + along * VERTEX.y * len + side * VERTEX.x * width;
	NORMAL = to_cam;
	v_uv = UV;
}

void fragment() {
	float x = abs(v_uv.x - 0.5) * 2.0;   // 0 centre line, 1 edge
	float y = v_uv.y;                    // 0 head, 1 tail
	float hw = y / 0.2 * 0.5;
	float head = step(y, 0.2) * (1.0 - smoothstep(hw - 0.06, hw, x));
	float shaft = step(0.18, y) * step(y, 0.96) * (1.0 - smoothstep(0.06, 0.1, x));
	float tf = clamp((y - 0.72) / 0.24, 0.0, 1.0);
	float fw = 0.08 + 0.42 * tf;
	float fletch = step(0.72, y) * step(y, 0.97) * (1.0 - smoothstep(fw - 0.06, fw, x));
	float body = max(max(head, shaft), fletch * 0.85);
	vec3 bodyc = vec3(0.30, 0.20, 0.11);
	bodyc = mix(bodyc, vec3(1.3, 1.15, 0.9), head);
	bodyc = mix(bodyc, tint.rgb * 0.7, fletch * (1.0 - shaft));
	float glow = exp(-x * x * 5.0) * (1.0 - y * 0.6) * 0.8 + exp(-(x * x * 14.0 + y * y * 40.0)) * 2.2;
	float flick = 0.9 + 0.1 * sin(TIME * 40.0);
	vec3 emit = tint.rgb * tint.a * glow * flick;
	float cover = body * 0.9;
	ALBEDO = (emit + bodyc * cover) * fade;
	ALPHA = cover * fade;
}
