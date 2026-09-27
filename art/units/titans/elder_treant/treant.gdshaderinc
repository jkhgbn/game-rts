// treant.gdshaderinc - shared by the Elder Treant shaders (task 13.V18): the instance uniforms (kit slot map,
// art/units/kit/README.md "Instance uniform slots"; slots 7-9 are this model's own, declared the same in all three
// shaders so a merged pivot mesh never mixes them up) and the root-morph growth.
//   1 ao_bottom, 2 ao_height, 3 hit_flash, 4 flash_color, 5 glow_boost   (kit names, set by elder_treant.gd)
//   7 root_morph  0 = walking form .. 1 = rooted form (the 3 s morph)
//   8 heal_glow   0 .. 1: the regeneration / grove-aura glow (sap veins pulse, green rim, eyes a little brighter)
//   9 team_tint   the kingdom colour (leaf surfaces whose COLOR.a is 1: the waist garland)
// Growth: CUSTOM0.xyz = anchor (model rest space), CUSTOM0.w = 0 static, +(1 + start) grows out between
// root_morph = start and start + 0.3 (a small pop), -(1 + start) shrinks away instead. A vertex that is not grown
// sits on its anchor (the triangle has no area and draws nothing).

instance uniform float ao_bottom : instance_index(1) = 0.0;
instance uniform float ao_height : instance_index(2) = 4.2;
instance uniform float hit_flash : instance_index(3) = 0.0;
instance uniform vec3 flash_color : instance_index(4) = vec3(1.0, 1.0, 1.0);
instance uniform float glow_boost : instance_index(5) = 1.0;
instance uniform float root_morph : instance_index(7) = 0.0;
instance uniform float heal_glow : instance_index(8) = 0.0;
instance uniform vec3 team_tint : instance_index(9) = vec3(0.35, 0.70, 0.25);

float treant_growth(vec4 c0) {
	if (c0.w == 0.0) {
		return 1.0;
	}
	float t0 = abs(c0.w) - 1.0;
	float g = smoothstep(t0, t0 + 0.3, root_morph);
	g *= 1.0 + 0.14 * sin(g * 3.14159);
	return c0.w < 0.0 ? 1.0 - g : g;
}

vec3 treant_morph(vec3 p, vec4 c0) {
	if (c0.w == 0.0) {
		return p;
	}
	return c0.xyz + (p - c0.xyz) * treant_growth(c0);
}

float treant_triplanar(sampler2D tex, vec3 p, vec3 n, float scale) {
	vec3 w = pow(abs(n), vec3(4.0));
	w /= (w.x + w.y + w.z + 0.0001);
	float x = texture(tex, p.zy * scale).r;
	float y = texture(tex, p.xz * scale).r;
	float z = texture(tex, p.xy * scale).r;
	return x * w.x + y * w.y + z * w.z;
}

// Vertex colours are authored in sRGB (like every palette colour); ALBEDO wants linear.
vec3 treant_linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

// The kit's hit / level-up flash (A.17): gold tints the surface, white adds.
vec3 treant_flash_tint() {
	float warm = clamp(hit_flash * 2.4, 0.0, 1.0) * (1.0 - smoothstep(0.2, 0.4, flash_color.b))
		* smoothstep(0.42, 0.5, flash_color.g);
	return mix(vec3(1.0), flash_color, warm);
}
