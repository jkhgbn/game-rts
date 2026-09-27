// wyrm_fin.gdshader - Frost Wyrm ice-feathered fins (task 13c.V8): the frilled head crest, the dorsal fin along the
// whole body, the pectoral fans and the tail fluke. One double-sided surface (cull_disabled), painted toon: a deep cold
// root fading to a pale frosted edge, bright feather RAYS with fine barbs along them (the "ice feather"), a ragged
// rime-white rim broken by noise, a faint cold shimmer on the very edge (glow_boost) and light through the fin when
// seen against the sun (the frosted-glass look). Skinning-safe: the noise is sampled on UV (metres), never on VERTEX.
// Vertex COLOR:
//   r  1 on a feather ray (0 mid-panel)
//   g  0 at the root -> 1 at the edge
//   b  1 on the ragged edge band (frosted rim)
// UV = (along the fin, from the root) in metres.
// Instance uniforms (kit slot map): hit_flash 3, flash_color 4, glow_boost 5.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

uniform vec3 root_color : source_color = vec3(0.16, 0.40, 0.62);
uniform vec3 edge_color : source_color = vec3(0.66, 0.88, 1.0);
uniform vec3 ray_color : source_color = vec3(0.90, 0.98, 1.0);
uniform vec3 frost_color : source_color = vec3(0.94, 0.98, 1.0);
uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float noise_scale = 1.3;
uniform float barb_freq = 26.0;
uniform float frost_amount = 0.8;
uniform vec3 glow_color : source_color = vec3(0.55, 0.92, 1.0);
uniform float glow_energy = 0.9;
uniform float ray_glow = 0.35;
uniform float back_light = 0.45;
uniform vec3 rim_color : source_color = vec3(0.70, 0.90, 1.0);
uniform float rim_strength = 0.25;

instance uniform float hit_flash : instance_index(3) = 0.0;
instance uniform vec3 flash_color : instance_index(4) = vec3(1.0, 1.0, 1.0);
instance uniform float glow_boost : instance_index(5) = 1.0;

void fragment() {
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
	float nz = texture(noise_tex, UV * noise_scale).r;
	float nz2 = texture(noise_tex, UV * noise_scale * 2.7 + vec2(5.1, 2.7)).r;
	float ray = clamp(COLOR.r, 0.0, 1.0);
	float edge = clamp(COLOR.g, 0.0, 1.0);
	vec3 albedo = mix(root_color, edge_color, smoothstep(0.0, 1.0, edge));
	// feather barbs: fine slanted striations off each ray, strongest mid-panel
	float barb = sin((UV.x * 0.9 + UV.y * 0.55) * barb_freq + nz * 3.0);
	albedo *= 0.93 + 0.1 * smoothstep(0.3, 1.0, barb) * (1.0 - ray);
	albedo = mix(albedo, ray_color, smoothstep(0.35, 0.95, ray) * 0.6);
	albedo *= 0.9 + 0.2 * nz;
	// ragged frosted rim (noise-broken) and a few frost flecks out on the panels
	float rim_band = clamp(COLOR.b, 0.0, 1.0);
	float frost = smoothstep(0.62, 1.0, rim_band + (nz2 - 0.5) * 0.45);
	frost = max(frost, smoothstep(0.74, 0.86, nz2) * edge * 0.25);
	albedo = mix(albedo, frost_color, clamp(frost, 0.0, 1.0) * frost_amount);
	float heat = clamp(glow_boost, 0.0, 3.0);
	float flick = 0.7 + 0.3 * sin(TIME * 1.5 + UV.x * 2.3 + UV.y * 1.1);
	vec3 emission = glow_color * glow_energy * smoothstep(0.75, 1.0, rim_band) * flick * min(heat, 2.0) * (0.6 + 0.4 * nz);
	emission += glow_color * ray_glow * smoothstep(0.6, 1.0, ray) * edge * min(heat, 2.0);
	// light through the fin from behind (seen from below / against the sun)
	emission += edge_color * back_light * (1.0 - float(FRONT_FACING)) * (0.4 + 0.6 * edge) * (1.0 - ray * 0.5);
	float rim = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 3.0);
	emission += rim * rim_color * rim_strength;
	ALBEDO = albedo;
	EMISSION = emission + flash_color * hit_flash * 2.0;
	ROUGHNESS = 1.0;
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += (0.2 + 0.8 * ramp) * ATTENUATION * LIGHT_COLOR / PI;
}
