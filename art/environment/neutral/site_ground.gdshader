shader_type spatial;
// Task MAP.P2: the painted ground apron under a neutral site (tavern, peddler, cache, trading post, guild houses,
// Crown altar). Lit like the map ground (so it takes the sun, the dusk tint and the building's shadow), alpha
// blended, never writes depth. It paints what the ground shader paints for its trodden-dirt spots: a crisp noisy
// dirt edge with a darker grass-lip just inside it, plus a baked contact shadow hugging the walls.
// Mesh contract (SiteGround.mesh): UV.x = 0 at the wall line -> 1 at the outer rim of the apron,
// UV.y = metres out from the wall line (negative = under the building), COLOR.rgb = dirt tint, COLOR.a = strength.
render_mode blend_mix, depth_draw_never, cull_disabled, diffuse_lambert, specular_disabled;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec3 dirt_color : source_color = vec3(0.48, 0.405, 0.30);   // ground.gdshader dirt_color
uniform vec3 dirt_dark : source_color = vec3(0.31, 0.255, 0.19);    // ground.gdshader dirt_dark
uniform vec3 contact_color : source_color = vec3(0.10, 0.085, 0.06);
uniform float dirt_alpha = 0.86;
uniform float contact_alpha = 0.72;
uniform float contact_width = 0.55;   // metres the contact shadow reaches out from the wall line
uniform float edge_noise = 0.42;      // how ragged the dirt rim is (fraction of the apron width)

varying vec3 v_world;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 w = v_world.xz;
	float n1 = texture(noise_tex, w * 0.045).r;
	float n2 = texture(noise_tex, w * 0.17 + vec2(0.37, 0.61)).r;
	float n = n1 * 0.65 + n2 * 0.35;
	// Crisp painted rim, same half width as the ground's dirt spots.
	float edge = 0.80 + (n - 0.5) * edge_noise * 2.0;
	float t = UV.x;
	float dirt = 1.0 - smoothstep(edge - 0.035, edge + 0.035, t);
	// Worn texture inside: darker packed earth near the walls and in blotches, lighter dust in between.
	float blot = smoothstep(0.42, 0.68, texture(noise_tex, w * 0.32 + vec2(0.11, 0.83)).r);
	vec3 col = mix(dirt_color * 1.1, dirt_dark, clamp(blot * 0.32 + (1.0 - t) * 0.14, 0.0, 1.0)) * (COLOR.rgb * 2.0);
	// Grass-lip shadow just inside the rim (the ground shader's edge_lip look).
	float lip = smoothstep(edge - 0.16, edge - 0.02, t) * dirt;
	col *= 1.0 - lip * 0.28;
	// Baked contact shadow: strongest at the wall line, gone after contact_width metres; ragged like the paint.
	float d = max(UV.y, 0.0) / max(contact_width * (0.75 + n2 * 0.5), 0.01);
	float contact = exp(-d * d * 2.2) * step(-0.6, UV.y);
	col = mix(col, contact_color, contact * 0.85);
	ALBEDO = col;
	ROUGHNESS = 1.0;
	ALPHA = clamp(max(dirt * dirt_alpha, contact * contact_alpha) * COLOR.a, 0.0, 1.0);
}
