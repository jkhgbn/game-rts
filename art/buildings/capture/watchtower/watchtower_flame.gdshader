// watchtower_flame.gdshader - the cresset fire of the watchtower (task 12.V17), shared (watchtower_flame_mat.tres).
// Emission only (no light node). Mesh: WatchtowerMesh.flames(): camera-facing quads, every vertex at the quad's centre
// (model space) with its corner offset in UV2 (metres, view-space right / up) and UV 0..1 (y up); COLOR.r = phase,
// COLOR.g = 1 for the soft halo quad. The flame is a flickering teardrop of scrolling paint noise: a pale core, the
// owner's glow colour, darker tips. Per tower (instance uniforms): flame_color (the owner's glow), energy (0 = cold:
// the node is hidden), height_k (flare / ignition size).
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, skip_vertex_transform, shadows_disabled, fog_disabled;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float halo_strength = 0.16;

instance uniform vec3 flame_color : source_color = vec3(1.0, 0.55, 0.15);
instance uniform float energy = 0.0;
instance uniform float height_k = 1.0;

varying float v_halo;
varying float v_phase;

void vertex() {
	v_halo = COLOR.g;
	v_phase = COLOR.r;
	float s = length(MODEL_MATRIX[0].xyz);
	vec2 off = UV2 * s;
	if (v_halo < 0.5) {
		off.y = off.y < 0.0 ? off.y : off.y * height_k;
		off.x *= mix(1.0, height_k, 0.5);
	} else {
		off *= mix(1.0, height_k, 0.6);
	}
	vec4 c = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	VERTEX = c.xyz + vec3(off, 0.0);
	// A little toward the camera so the flame is not cut by the bowl's back rim.
	VERTEX.z += 0.12;
	NORMAL = vec3(0.0, 0.0, 1.0);
}

void fragment() {
	vec2 uv = UV;
	vec3 col;
	float a;
	if (v_halo > 0.5) {
		float r = length(uv - 0.5) * 2.0;
		float flick = 0.85 + 0.15 * sin(TIME * 7.3 + v_phase * 10.0) * sin(TIME * 3.1);
		a = pow(max(1.0 - r, 0.0), 2.2) * halo_strength * flick;
		col = flame_color * a;
	} else {
		float t = TIME + v_phase * 7.0;
		float n1 = texture(noise_tex, vec2(uv.x * 0.8 + v_phase, uv.y * 0.55 - t * 1.25)).r;
		float n2 = texture(noise_tex, vec2(uv.x * 1.6 - v_phase, uv.y * 1.1 - t * 2.2)).r;
		float x = (uv.x - 0.5) * 2.0 + (n1 - 0.5) * 0.7 * uv.y;
		// The base (uv.y ~0.3) sits in the bowl; the teardrop narrows and licks upward.
		float y = max(uv.y - 0.2, 0.0) / 0.8;
		float width = mix(0.8, 0.06, pow(y, 0.75));
		float body = 1.0 - smoothstep(width * 0.45, width, abs(x));
		body *= smoothstep(0.12, 0.3, uv.y);
		float top = y + (n2 - 0.5) * 0.45;
		body *= 1.0 - smoothstep(0.5, 0.92, top);
		float core = body * (1.0 - smoothstep(0.0, 0.45, y + abs(x) * 0.9));
		vec3 hot = mix(flame_color, vec3(1.0, 0.96, 0.85), 0.65);
		col = flame_color * body * mix(1.0, 0.55, smoothstep(0.3, 0.9, y)) + hot * core * 1.3;
		a = body;
	}
	// Additive: the colour carries the shape (ALPHA only keeps it in the transparent pass).
	ALBEDO = col * energy;
	ALPHA = a > 0.001 ? 1.0 : 0.0;
}
