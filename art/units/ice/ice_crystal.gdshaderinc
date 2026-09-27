// ice_crystal.gdshaderinc - shared body of the Ice army crystal shaders (task A.6):
//   ice_crystal.gdshader (opaque: armour plates, glacier plates, rods, clubs; merged with the painted parts)
//   ice_clear.gdshader   (translucent: the Rimeshield's round shield, lantern glass).
// Look: hard low-poly facets (flat normals from screen derivatives), a deep blue core that brightens toward the
// silhouette (fresnel = fake thickness / translucency), a faint inner light drifting with the view (parallax
// noise), sharp toon specular glints and tiny sparkles that fade out beyond ~28 m (no noise at RTS zoom 40).
// Instance uniforms match unit_painted.gdshader so the kit's hit / level-up flash and height gradient just work.

uniform vec3 deep_color : source_color = vec3(0.10, 0.30, 0.55);
uniform vec3 surface_color : source_color = vec3(0.55, 0.82, 1.00);
uniform vec3 edge_color : source_color = vec3(0.85, 0.96, 1.00);
uniform float fresnel_power = 2.0;
uniform float inner_energy = 0.30;
uniform float edge_energy = 0.45;
uniform float sparkle_energy = 3.0;
uniform float spec_strength = 0.9;
uniform float facets = 1.0;   // 1 = flat facets (crystal), 0 = smooth normals
uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;

instance uniform float ao_bottom : instance_index(1) = 0.0;
instance uniform float ao_height : instance_index(2) = 1.6;
instance uniform float hit_flash : instance_index(3) = 0.0;
instance uniform vec3 flash_color : instance_index(4) = vec3(1.0, 1.0, 1.0);

varying vec3 v_world_pos;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

vec3 ice_normal(vec3 smooth_n, vec3 vtx, vec3 view) {
	vec3 n = smooth_n;
	if (facets > 0.5) {
		n = normalize(cross(dFdx(vtx), dFdy(vtx)));
		if (dot(n, view) < 0.0) {
			n = -n;
		}
	}
	return n;
}

// Returns the albedo; writes emission and the fresnel term.
vec3 ice_shade(vec3 n, vec3 view, vec3 vtx, mat4 inv_view, float time, out vec3 emission, out float fres) {
	fres = pow(1.0 - clamp(dot(n, view), 0.0, 1.0), fresnel_power);
	vec3 wview = normalize((inv_view * vec4(view, 0.0)).xyz);
	vec3 wn = normalize((inv_view * vec4(n, 0.0)).xyz);
	// Inner light: two noise layers "inside" the ice, shifted along the view ray (parallax = depth).
	vec2 p = v_world_pos.xz * 0.9 + vec2(v_world_pos.y * 0.7, -v_world_pos.y * 0.4);
	float a = texture(noise_tex, p - wview.xz * 0.35).r;
	float b = texture(noise_tex, p * 1.9 + vec2(3.7, 1.3) - wview.xz * 0.8).r;
	float inner = smoothstep(0.35, 0.75, a) * 0.7 + smoothstep(0.55, 0.8, b) * 0.5;
	// Facet-to-facet value variation so neighbouring faces read apart (hand-painted gem look).
	float facet_v = fract(sin(dot(floor(wn * 3.0 + 0.5), vec3(12.9898, 78.233, 37.719))) * 43758.5453);
	vec3 col = mix(deep_color, surface_color, clamp(0.25 + 0.55 * fres + 0.18 * (facet_v - 0.5), 0.0, 1.0));
	float h = v_world_pos.y - ao_bottom;
	col *= mix(0.82, 1.06, smoothstep(0.0, 1.0, h / max(ao_height, 0.01)));
	col *= mix(0.62, 1.0, smoothstep(0.0, 0.30, h));
	// Sparkles: sparse peaks of two noise samples, twinkling with the view and time; close range only.
	float s1 = texture(noise_tex, v_world_pos.xz * 4.1 + v_world_pos.y * 3.3 + wview.xy * 1.7).r;
	float s2 = texture(noise_tex, v_world_pos.zy * 3.7 - v_world_pos.x * 2.1 + vec2(time * 0.05, 0.0)).r;
	float sparkle = smoothstep(0.90, 0.97, s1 * s2 * 1.55);
	sparkle *= 1.0 - smoothstep(16.0, 28.0, length(vtx));
	emission = surface_color * inner_energy * (0.35 + inner) + edge_color * fres * edge_energy
		+ edge_color * sparkle * sparkle_energy;
	return col;
}

void ice_light(vec3 normal, vec3 light, vec3 view, float attenuation, vec3 light_color, inout vec3 diffuse,
		inout vec3 specular) {
	float d = dot(normal, light) * 0.5 + 0.5;
	float ramp = smoothstep(0.30, 0.40, d) * 0.5 + smoothstep(0.56, 0.66, d) * 0.5;
	diffuse += (0.35 + ramp * 0.65) * attenuation * light_color / PI;
	float sp = pow(max(dot(reflect(-light, normal), view), 0.0), 32.0);
	specular += smoothstep(0.35, 0.55, sp) * spec_strength * light_color * attenuation;
}
