// market_nature_gold.gdshader - the Grove Bazaar's trade gold (task 10.V4): the coin emblem, the scale's hub, pan rims
// and the coins heaped in the gold pan, the strongbox bands. Hand-painted like nature_keep_painted.gdshader (noise
// tint, toon ramp, light tops / dark bottoms, contact band), plus what makes it read as metal from the RTS camera:
// a warm specular, a darker "burnished" underside, and a thin highlight band that sweeps slowly across every gold
// surface (world space, so the coin, hub and rims glint together). `glint` 0..1 = the delivery flash (the model
// ramps it up and down when a caravan pays in): the sweep speeds up and the whole metal flares over the bloom
// threshold for a moment. Uniforms driven like the kit's painted materials: `rim_color`, `rim_strength`, `damage`.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec3 base_color : source_color = vec3(0.95, 0.70, 0.24);
uniform vec3 deep_color : source_color = vec3(0.42, 0.24, 0.07);
uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float spec_strength = 0.7;
uniform float sweep_speed = 0.22;
uniform float sweep_energy = 0.55;
uniform float glint : hint_range(0.0, 1.0) = 0.0;
uniform vec3 rim_color : source_color = vec3(1.0, 0.86, 0.5);
uniform float rim_strength = 0.3;
uniform float damage : hint_range(0.0, 1.0) = 0.0;

instance uniform float ao_bottom = 0.0;
instance uniform float ao_height = 10.0;

varying vec3 v_world_pos;
varying vec3 v_world_normal;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float triplanar(vec3 p, vec3 n, float scale) {
	vec3 w = pow(abs(n), vec3(4.0));
	w /= (w.x + w.y + w.z + 0.0001);
	float x = texture(noise_tex, p.zy * scale).r;
	float y = texture(noise_tex, p.xz * scale).r;
	float z = texture(noise_tex, p.xy * scale).r;
	return x * w.x + y * w.y + z * w.z;
}

void fragment() {
	vec3 n = normalize(v_world_normal);
	float na = triplanar(v_world_pos, n, 1.1);
	float nb = triplanar(v_world_pos + vec3(7.1, 3.3, 1.9), n, 0.35);
	vec3 albedo = base_color * (1.0 + (na - 0.5) * 0.28) * (1.0 + (nb - 0.5) * 0.14);
	// Burnished metal: bright tops, deep warm undersides (reads as polished gold, not yellow paint).
	albedo = mix(deep_color, albedo, smoothstep(-0.75, 0.55, n.y));
	// Height gradient + contact band (like every painted part).
	float h = v_world_pos.y - ao_bottom;
	albedo *= mix(0.78, 1.08, smoothstep(0.0, 1.0, h / max(ao_height, 0.01)));
	albedo *= mix(0.6, 1.0, smoothstep(0.0, 0.2, h));
	albedo *= 1.0 - damage * 0.35;
	// The sweeping glint band (faster and brighter during a delivery).
	float s = fract(dot(v_world_pos, vec3(0.31, 0.47, 0.23)) * 0.55 - TIME * sweep_speed * (1.0 + glint * 5.0));
	float band = smoothstep(0.0, 0.035, s) * (1.0 - smoothstep(0.035, 0.11, s));
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	vec3 emission = base_color * band * (sweep_energy * (1.0 - damage * 0.6) + glint * 3.2);
	emission += base_color * glint * glint * 1.6;
	emission += rim * rim_color * rim_strength;
	ALBEDO = albedo;
	EMISSION = emission;
	ROUGHNESS = 0.45;
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
	float sp = pow(max(dot(reflect(-LIGHT, NORMAL), VIEW), 0.0), 14.0);
	SPECULAR_LIGHT += smoothstep(0.25, 0.6, sp) * spec_strength * LIGHT_COLOR * ATTENUATION * ALBEDO;
}
