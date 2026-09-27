// watchtower_banner.gdshader - the watchtower's banners (task 12.V17), shared by every tower (watchtower_banner_mat.tres).
// Mesh: WatchtowerMesh.banner(size): a grid hanging from its top-left corner (the pole side), UV (0, 0) top-left.
// owner_k 0 = the neutral banner: grey, stained, torn into ragged strips with holes, a ghost of the emblem;
// owner_k 1 = the owner's banner: clean team cloth, swallow-tailed, dark top hem, pale trims and the watch-eye emblem.
// In between the tears mend (the owner blend animates). Toon-lit both sides like painted.gdshader, waving (the free
// bottom-right corner swings most). Per banner (instance uniforms): cloth_color, owner_k, phase, rod (1 = draw its own
// carrying rod along the top: the rising capture banner), glow_color / glow_energy (the cresset above lights the top),
// flash (capture flash).
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec3 neutral_color : source_color = vec3(0.40, 0.39, 0.36);
uniform vec3 emblem_color : source_color = vec3(0.95, 0.89, 0.72);
uniform vec3 rod_color : source_color = vec3(0.30, 0.21, 0.13);
uniform float amplitude = 0.13;
uniform float speed = 2.2;
uniform vec3 rim_color : source_color = vec3(0.55, 0.65, 0.85);
uniform float rim_strength = 0.18;

instance uniform vec3 cloth_color : source_color = vec3(0.47, 0.46, 0.43);
instance uniform float owner_k = 0.0;
instance uniform float phase = 0.0;
instance uniform float rod = 0.0;
instance uniform vec3 glow_color : source_color = vec3(1.0, 0.55, 0.15);
instance uniform float glow_energy = 0.0;
instance uniform float flash = 0.0;

void vertex() {
	// The top edge hangs from the crossbar, the left edge from rings on the pole: the bottom-right swings most.
	float w = UV.y * mix(0.3, 1.0, UV.x);
	float amp = amplitude * mix(0.55, 1.0, owner_k);   // the torn grey rag hangs heavier
	VERTEX.z += sin(TIME * speed + UV.y * 3.6 + UV.x * 2.4 + phase) * amp * w;
	VERTEX.z += sin(TIME * speed * 2.1 + UV.x * 6.0 + phase * 1.7) * amp * 0.25 * w;
	VERTEX.x += sin(TIME * speed * 0.55 + UV.y * 2.0 + phase) * amp * 0.3 * w * UV.y;
}

float seg_dist(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

void fragment() {
	vec2 uv = UV;
	float torn = 1.0 - clamp(owner_k, 0.0, 1.0);
	float nz = texture(noise_tex, uv * vec2(2.3, 3.7) + vec2(phase * 0.37, 0.0)).r;
	float nf = texture(noise_tex, uv * vec2(9.0, 5.0) + vec2(0.0, phase)).r;
	// --- Shape ---
	// Torn: five ragged strips of different lengths, split near the bottom, holes, a frayed free edge.
	float strip = floor(uv.x * 5.0);
	float len = mix(1.0, 0.62 + 0.3 * fract(sin(strip * 12.9898 + 4.1) * 43758.5453), torn);
	len -= (nf - 0.5) * 0.08 * torn;
	if (uv.y > len) {
		discard;
	}
	float fs = fract(uv.x * 5.0);
	if (torn > 0.5 && uv.y > 0.58 && (fs < 0.06 || fs > 0.97)) {
		discard;
	}
	if (uv.y > 0.2 && nz > mix(1.2, 0.72, torn)) {
		discard;
	}
	if (uv.y > 0.3 && uv.x > 0.94 - (nf - 0.4) * 0.12 * torn && torn > 0.5) {
		discard;
	}
	// Owned: swallow tail.
	float notch = (uv.y - 0.84) / 0.16 * 0.3 * owner_k;
	if (uv.y > 0.84 && abs(uv.x - 0.5) < notch) {
		discard;
	}

	// --- Colour ---
	vec3 cloth = mix(neutral_color, cloth_color, owner_k);
	vec3 col = cloth;
	// Emblem: a watching eye with three rays (pale on the owner's cloth, a faded ghost on the grey rag).
	vec2 p = vec2(uv.x - 0.5, (uv.y - 0.43) / 0.56);
	float R = 0.405;
	float c = 0.235;
	float lens = step(length(p - vec2(0.0, c)), R) * step(length(p + vec2(0.0, c)), R);
	float iris = step(length(p), 0.13);
	float rays = 0.0;
	for (int i = -1; i <= 1; i++) {
		float a = float(i) * 0.55;
		vec2 dir = vec2(sin(a), -cos(a));
		rays = max(rays, 1.0 - step(0.028, seg_dist(p, dir * 0.24, dir * 0.4)));
	}
	float emblem = max(lens * (1.0 - iris), rays);
	vec3 pale = mix(cloth * 1.2, emblem_color, mix(0.3, 1.0, owner_k));
	col = mix(col, pale, emblem * mix(0.35, 1.0, owner_k));
	col = mix(col, cloth * 0.42, iris * lens * owner_k);
	// Hem along the top, pale trim lines (owned), folds, stains and a wet dark bottom on the rag.
	col *= uv.y < 0.075 ? 0.55 : 1.0;
	float trim = (step(0.1, uv.y) * step(uv.y, 0.12) + step(0.79, uv.y) * step(uv.y, 0.81)) * owner_k;
	col = mix(col, emblem_color * 0.9, trim);
	col *= 0.88 + 0.12 * sin(uv.x * 15.0 + sin(uv.y * 4.0 + phase) * 1.5);
	col *= mix(1.0, 0.7, smoothstep(0.55, 0.78, nz) * torn);
	col *= mix(1.0, 0.8, smoothstep(0.5, 0.95, uv.y) * torn);
	if (rod > 0.5 && uv.y < 0.05) {
		col = rod_color;
	}
	ALBEDO = col;
	float rim = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 3.0);
	vec3 emit = rim_color * rim * rim_strength + col * 0.06 * owner_k;
	emit += col * glow_color * glow_energy * 0.3 * (1.0 - smoothstep(0.0, 0.55, uv.y));
	emit += cloth_color * flash * 0.7;
	EMISSION = emit;
	ROUGHNESS = 1.0;
}

void light() {
	float d = abs(dot(NORMAL, LIGHT)) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
}
