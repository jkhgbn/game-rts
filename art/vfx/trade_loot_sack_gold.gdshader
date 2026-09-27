shader_type spatial;
// Gold coins of the loot sack (task 10.V11, art/vfx/trade_loot_sack.tscn): the spill on the ground, the coins
// peeking from the sack's mouth and the stitched coin patch. Colour blocks come from the VERTEX COLOUR (sRGB, baked
// by trade_loot_sack_build.gd). Polished metal: painted toon diffuse + a hard specular, an emissive core so the
// gold reads at 40 m through the bloom, and a glint band that sweeps across the coins every few seconds.
// `glint_boost` (per instance) is raised by the model while the sack is about to vanish (warning blink).
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform float energy = 0.3;          // emissive core (x vertex colour)
uniform float glint_energy = 2.4;    // the sweeping glint
uniform float glint_period = 2.6;    // seconds between glints
instance uniform float glint_boost = 0.0;

varying vec3 v_col;
varying vec3 v_wp;
varying vec3 v_lp;

void vertex() {
	v_col = pow(COLOR.rgb, vec3(2.2));
	v_wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_lp = VERTEX;
}

void fragment() {
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	// A diagonal band crossing the sack (model space), once per period; phase from the world position so
	// neighbouring sacks do not glint together.
	float ph = fract(TIME / glint_period + fract(sin(dot(floor(v_wp.xz * 0.5), vec2(12.9898, 78.233))) * 43758.5453));
	float band = v_lp.x * 0.8 + v_lp.y * 1.4 - (ph * 3.2 - 1.2);
	float glint = exp(-band * band * 90.0);
	ALBEDO = v_col * 0.8;
	EMISSION = v_col * (energy + fres * 0.35) +vec3(1.0, 0.9, 0.6) * glint * (glint_energy + glint_boost * 2.0)
			+ v_col * glint_boost * 1.2;
	ROUGHNESS = 0.3;
	METALLIC = 0.0;
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
	SPECULAR_LIGHT += pow(max(dot(reflect(-LIGHT, NORMAL), VIEW), 0.0), 24.0) * 0.6 * LIGHT_COLOR * ATTENUATION;
}
