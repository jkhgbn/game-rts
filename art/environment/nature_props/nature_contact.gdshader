// nature_contact.gdshader - soft painted contact shadow under trees, rocks and pillars (task A2.8,
// art-keep.md 0.5 "contact decal"). A second surface of the prop mesh: a flat irregular disc just above the ground,
// MULTIPLIED onto whatever is below (order independent, so a MultiMesh needs no sorting), no shadow, no depth write.
//   UV.x   0 at the disc centre -> 1 at its rim
//   UV2.x  variant mask, same rule as nature_painted.gdshader (the disc follows its variant's footprint)
shader_type spatial;
render_mode blend_mul, unshaded, depth_draw_never, cull_back, shadows_disabled, fog_disabled;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec3 contact_color : source_color = vec3(0.56, 0.60, 0.52);
uniform float strength = 1.0;
uniform float variant_count = 3.0;

varying float v_t;
varying vec3 v_wp;

float hash1(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	float mask = UV2.x;
	if (mask > 0.5) {
		float ih4 = hash1(origin.zx + vec2(3.1, 7.7));
		float variant = min(floor(ih4 * variant_count), variant_count - 1.0);
		if (mod(floor(mask / exp2(variant)), 2.0) < 0.5) {
			VERTEX = vec3(0.0, -3.0, 0.0);
		}
	}
	v_t = UV.x;
	v_wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float nz = texture(noise_tex, v_wp.xz * 0.35).r;
	float f = 1.0 - smoothstep(0.15, 1.0, v_t + (nz - 0.5) * 0.35);
	f = f * f * (3.0 - 2.0 * f);
	ALBEDO = mix(vec3(1.0), contact_color, clamp(f * strength, 0.0, 1.0));
}
