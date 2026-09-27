// mossback_leaf.gdshader - the Mossback's tree crowns (tier3-extras.md 12, task 13b.V4). Painted style of
// unit_painted.gdshader (same light ramp, noise, height gradient, rim, hit / level-up flash) for leaf masses, plus the
// Canopy glow. The kit slot map is followed verbatim (kit/README.md "Instance uniform slots"):
//   ao_bottom 1, ao_height 2, hit_flash 3, flash_color 4, glow_boost 5.
// glow_boost is driven by MossbackModel on the crown nodes (meta own_glow): CROWN_GLOW_OFF (0.55) at rest ..
// CROWN_GLOW_ON (2.2) with the Canopy spread; the leaf glow ramps in above 0.6 (canopy = (glow_boost - 0.6) / 1.6),
// so the leaves and the amber seed pods (mossback_lantern.tres: this shader with amber colours, a surface of the same
// mesh) share one per-node value: at rest they are painted only (no glow point at 40 m), the Canopy lights both.
// Leaves: painted lobes (noise cells), light tops / dark undersides, a yellow-green backlit rim and a small breeze in
// MODEL space (the crown node's scale does not swim the paint). Canopy: the leaves light up from within (lobe tops
// brighter), a slow pulse, a stronger breeze.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec3 base_color : source_color = vec3(0.26, 0.52, 0.22);
uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float spec_strength : hint_range(0.0, 1.0) = 0.06;
uniform vec3 rim_color : source_color = vec3(0.78, 0.95, 0.45);
uniform float rim_strength = 0.22;
uniform vec3 glow_color : source_color = vec3(0.70, 1.00, 0.42);
uniform float glow_energy = 0.85;
uniform float sway = 0.022;

instance uniform float ao_bottom : instance_index(1) = 0.0;
instance uniform float ao_height : instance_index(2) = 10.0;
instance uniform float hit_flash : instance_index(3) = 0.0;
instance uniform vec3 flash_color : instance_index(4) = vec3(1.0, 1.0, 1.0);
instance uniform float glow_boost : instance_index(5) = 1.0;

varying vec3 v_obj;
varying vec3 v_objn;
varying vec3 v_world;

float canopy_level() {
	return clamp((glow_boost - 0.6) / 1.6, 0.0, 1.0);
}

void vertex() {
	v_obj = VERTEX;
	v_objn = NORMAL;
	vec3 o = VERTEX;
	float k = sway * (1.0 + 1.2 * canopy_level());
	VERTEX += vec3(sin(TIME * 1.3 + o.x * 2.3 + o.z * 1.1), 0.5 * sin(TIME * 1.8 + o.y * 2.9),
		cos(TIME * 1.1 + o.y * 1.9 + o.x * 0.8)) * k;
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
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
	vec3 n = normalize(v_objn);
	float na = triplanar(v_obj, n, 1.5);
	float nb = triplanar(v_obj + vec3(7.1, 3.3, 1.9), n, 0.35);
	vec3 albedo = base_color * (1.0 + (na - 0.5) * 0.26) * (1.0 + (nb - 0.5) * 0.14);
	// painted leaf lobes
	float lob = smoothstep(0.32, 0.68, triplanar(v_obj + vec3(2.2, 0.0, 4.4), n, 3.2));
	albedo *= 0.82 + 0.34 * lob;
	// light tops, dark undersides (object normal: the crown's spread scale does not change it)
	albedo *= mix(0.60, 1.12, smoothstep(-0.55, 0.85, n.y));
	// height gradient + contact band (kit)
	float h = v_world.y - ao_bottom;
	albedo *= mix(0.78, 1.06, smoothstep(0.0, 1.0, h / max(ao_height, 0.01)));
	albedo *= mix(0.55, 1.0, smoothstep(0.0, 0.3, h));

	float c = canopy_level();
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	vec3 emission = rim * rim_color * rim_strength;
	// Canopy: the leaves glow softly from within (lobe tops and the upper side brighter), a slow breathing pulse.
	float pulse = 0.82 + 0.18 * sin(TIME * 1.7 + v_obj.x * 2.0 + v_obj.z * 1.3);
	float inner = (0.30 + 0.70 * lob) * (0.55 + 0.45 * smoothstep(-0.4, 0.9, n.y));
	emission += glow_color * glow_energy * c * inner * pulse + rim * glow_color * 0.6 * c;
	albedo = mix(albedo, albedo * 1.12 + glow_color * 0.05, c);

	float warm = clamp(hit_flash * 2.4, 0.0, 1.0) * (1.0 - smoothstep(0.2, 0.4, flash_color.b))
		* smoothstep(0.42, 0.5, flash_color.g);
	vec3 tint = mix(vec3(1.0), flash_color, warm);
	ALBEDO = albedo * tint;
	EMISSION = emission * tint + flash_color * hit_flash * 2.0;
	ROUGHNESS = 1.0;
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.30, 0.40, d) * 0.55 + smoothstep(0.56, 0.66, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
	if (spec_strength > 0.0) {
		SPECULAR_LIGHT += pow(max(dot(reflect(-LIGHT, NORMAL), VIEW), 0.0), 14.0) * spec_strength * LIGHT_COLOR * ATTENUATION / PI;
	}
}
