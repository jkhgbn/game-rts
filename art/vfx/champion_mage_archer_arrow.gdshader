shader_type spatial;
// Velocity-aligned arrows of light for GPU particles (ChampionVfx + ChampionMageArcherVfx, task 13b.V8): Eclipse
// Volley's rain and the volley shot up from the bow. A 1 x 1 QuadMesh drawn as a billboard that only turns around its
// own Y axis (ParticleProcessMaterial.particle_flag_align_y puts the velocity in Y). The particle scale is the arrow's
// WIDTH, `stretch` x scale its length. Colour = particle COLOR (HDR allowed, alpha fades it). Head at +Y.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, skip_vertex_transform, fog_disabled;

uniform float stretch = 6.0;

varying vec2 v_uv;

void vertex() {
	vec3 center = (MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 axis = (MODELVIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz * stretch;
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
	float x = abs(v_uv.x - 0.5) * 2.0;           // 0 centre line, 1 edge
	float y = clamp(v_uv.y, 0.0, 1.0);           // 0 head (+Y), 1 tail
	float hw = clamp(y / 0.16, 0.0, 1.0) * 0.8 * (1.0 - smoothstep(0.13, 0.18, y));
	float head = step(y, 0.18) * (1.0 - smoothstep(hw - 0.15, hw, x));
	float shaft = (1.0 - smoothstep(0.08, 0.2, x)) * step(0.14, y) * (1.0 - smoothstep(0.8, 0.9, y));
	float vt = clamp((y - 0.7) / 0.22, 0.0, 1.0);
	float vane = step(0.7, y) * exp(-pow((x - 0.12 - vt * 0.28) / 0.1, 2.0)) * (1.0 - smoothstep(0.88, 0.98, y));
	float haze = exp(-x * x * 4.0) * (1.0 - y) * 0.35;
	float k = head * 1.8 + shaft * 0.8 + vane * 0.6 + haze;
	ALBEDO = COLOR.rgb * (1.0 + head * 0.35);
	ALPHA = clamp(COLOR.a * k, 0.0, 1.0);
}
