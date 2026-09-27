// trade_post_pennant.gdshader - the trading post's "held" pennant (task 10.V10): a swallow-tailed team-colour pennant
// flying from the mast, a darker hem at the staff, toon-lit like painted.gdshader. The mesh is a PlaneMesh along local
// X (UV.x = 0 at the staff, 1 at the tip); the wave grows toward the tip.
// Instance uniform team_color (the holder's colour), uniform amplitude / speed.
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

instance uniform vec3 team_color : source_color = vec3(0.85, 0.30, 0.12);
uniform float amplitude = 0.10;
uniform float speed = 3.2;
uniform vec3 rim_color : source_color = vec3(0.55, 0.65, 0.85);
uniform float rim_strength = 0.2;

void vertex() {
	float w = UV.x;
	VERTEX.z += sin(TIME * speed - UV.x * 5.0) * amplitude * w;
	VERTEX.y += sin(TIME * speed * 0.6 - UV.x * 3.0 + 1.3) * amplitude * 0.3 * w;
}

void fragment() {
	// Tapered pennant (wide at the staff, narrow at the tip) with a swallow-tail notch.
	float half_h = mix(0.5, 0.16, UV.x);
	float dy = abs(UV.y - 0.5);
	if (dy > half_h) {
		discard;
	}
	if (UV.x > 0.8 && dy < (UV.x - 0.8) * 0.9) {
		discard;
	}
	vec3 col = team_color;
	col *= UV.x < 0.1 ? 0.55 : 1.0;                       // hem along the staff
	col = mix(col, vec3(1.0, 0.92, 0.7), step(0.28, UV.x) * step(UV.x, 0.36) * 0.55);   // one pale band
	col *= 0.9 + 0.12 * sin(UV.x * 18.0 - TIME * speed);  // folds
	ALBEDO = col;
	float rim = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 3.0);
	EMISSION = rim_color * rim * rim_strength + team_color * 0.12;
	ROUGHNESS = 1.0;
}

void light() {
	float d = abs(dot(NORMAL, LIGHT)) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
}
