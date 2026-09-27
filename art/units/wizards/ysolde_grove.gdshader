// ysolde_grove.gdshader - Ysolde's hero variant of art/units/kit/unit_painted.gdshader (task A.14).
// Same colour blocks, paint noise, height gradient, toon ramp, rim, hit / level-up flash and the SAME instance uniforms
// in the same order as unit_painted (so the kit's hit flash, gold flash and ao_height work on merged meshes), plus:
//   bark      painted bark grooves: long wavy vertical furrows wrapped around the pivot's vertical axis (the gown,
//             the staff), plates between them lighter
//   sap       glowing sap in some furrows, pulsing slowly upward (below 22 m only; farther it melts into a faint
//             even glow so thin lines never shimmer at 45 m)
//   moss_hem  moss creeping up from the ground (the gown hem), broken by noise
//   petal     blossom petals: pale glancing edges and a soft inner glow so the pink carries in shade
// Bark / sap / moss noise is sampled in MESH space (the merged pivot mesh), so it never swims when she walks.
// Uniforms of unit_painted: base_color, noise_tex, noise_scale_a / _b, spec_strength, rim_color, rim_strength.
// Instance uniforms: ao_bottom, ao_height, hit_flash, flash_color (set by the kit).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec3 base_color : source_color = vec3(0.34, 0.23, 0.14);
uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float noise_scale_a = 0.5;
uniform float noise_scale_b = 0.12;
uniform float spec_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec3 rim_color : source_color = vec3(0.55, 0.65, 0.85);
uniform float rim_strength = 0.25;

uniform float bark : hint_range(0.0, 1.0) = 0.0;
uniform float bark_density = 7.0;      // furrow tiles around the axis (integer: no seam)
uniform float bark_stretch = 0.45;     // noise tiles per metre along the axis (small = long furrows)
uniform float sap : hint_range(0.0, 1.0) = 0.0;
uniform vec3 sap_color : source_color = vec3(0.75, 1.00, 0.40);
uniform float sap_energy = 1.6;
uniform float sap_speed = 0.5;
uniform float moss_hem : hint_range(0.0, 1.0) = 0.0;
uniform vec3 moss_color : source_color = vec3(0.30, 0.44, 0.14);
uniform float moss_height = 0.30;
uniform float petal : hint_range(0.0, 1.0) = 0.0;
uniform vec3 petal_edge : source_color = vec3(1.00, 0.90, 0.94);

instance uniform float ao_bottom : instance_index(1) = 0.0;
instance uniform float ao_height : instance_index(2) = 2.0;
instance uniform float hit_flash : instance_index(3) = 0.0;
instance uniform vec3 flash_color : instance_index(4) = vec3(1.0, 1.0, 1.0);

varying vec3 v_world_pos;
varying vec3 v_world_normal;
varying vec3 v_local_pos;
varying vec3 v_local_normal;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_local_pos = VERTEX;
	v_local_normal = NORMAL;
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
	float na = triplanar(v_world_pos, n, noise_scale_a);
	float nb = triplanar(v_world_pos + vec3(17.3, 5.1, 9.7), n, noise_scale_b);
	vec3 albedo = base_color * (1.0 + (na - 0.5) * 0.20) * (1.0 + (nb - 0.5) * 0.12);
	vec3 emission = vec3(0.0);
	float dist = length(VERTEX);

	// Bark furrows + sap: noise wrapped around the pivot's vertical axis, stretched along it.
	if (bark > 0.0 || sap > 0.0) {
		float ang = atan(v_local_pos.z, v_local_pos.x) / 6.2831853;
		vec2 uv = vec2(ang * bark_density, v_local_pos.y * bark_stretch);
		float f = texture(noise_tex, uv).r;
		float ridged = 1.0 - abs(f * 2.0 - 1.0);
		float furrow = smoothstep(0.78, 0.96, ridged);
		albedo *= 1.0 + (f - 0.5) * 0.45 * bark;
		albedo *= 1.0 - 0.55 * furrow * bark;
		if (sap > 0.0) {
			float mask = smoothstep(0.60, 0.72, texture(noise_tex, uv * vec2(0.5, 0.37) + vec2(0.31, 0.57)).r);
			float core = smoothstep(0.93, 0.99, ridged) * mask;
			float flow = 0.5 + 0.5 * sin(v_local_pos.y * 5.0 - TIME * sap_speed * 6.2831853 + ang * 37.0);
			float near = 1.0 - smoothstep(14.0, 22.0, dist);
			emission += sap_color * sap_energy * sap * (core * (0.35 + 0.65 * flow) * near + mask * 0.05 * (1.0 - near));
			albedo = mix(albedo, sap_color * 0.45, core * sap * 0.6 * near);
		}
	}

	// Moss creeping up from the ground (before the AO, so it sits in the contact shade).
	if (moss_hem > 0.0) {
		float nm = triplanar(v_local_pos * 3.0, normalize(v_local_normal), 1.0);
		float h0 = v_world_pos.y - ao_bottom;
		float m = 1.0 - smoothstep(0.0, moss_height, h0 + (nm - 0.5) * 0.28);
		albedo = mix(albedo, moss_color * (0.8 + 0.4 * nm), m * moss_hem);
	}

	// Petals: pale glancing edges, a faint inner glow of their own colour.
	if (petal > 0.0) {
		float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
		albedo = mix(albedo, petal_edge, pow(1.0 - facing, 2.0) * 0.35 * petal);
		emission += base_color * 0.12 * petal;
	}

	// Height gradient (fake sky light + AO) and dark contact band.
	float h = v_world_pos.y - ao_bottom;
	albedo *= mix(0.72, 1.08, smoothstep(0.0, 1.0, h / max(ao_height, 0.01)));
	albedo *= mix(0.55, 1.0, smoothstep(0.0, 0.35, h));

	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	emission += rim * rim_color * rim_strength;

	// A.17: the gold level-up flash (low blue, mid green: hit white, Ice freeze blue, Fire ember are untouched) also tints
	// the surface, so pale and blue parts turn gold instead of adding up to white.
	float warm = clamp(hit_flash * 2.4, 0.0, 1.0) * (1.0 - smoothstep(0.2, 0.4, flash_color.b))
		* smoothstep(0.42, 0.5, flash_color.g);
	vec3 tint = mix(vec3(1.0), flash_color, warm);
	ALBEDO = albedo * tint;
	EMISSION = emission * tint + flash_color * hit_flash * 2.0;
	ROUGHNESS = 1.0;
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
	if (spec_strength > 0.0) {
		SPECULAR_LIGHT += pow(max(dot(reflect(-LIGHT, NORMAL), VIEW), 0.0), 24.0) * spec_strength * LIGHT_COLOR * ATTENUATION / PI;
	}
}
