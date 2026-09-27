// neutral_glow.gdshader - glowing bits of the neutral props (Ruin Peddler potions, Lost Cache seal gem and
// treasure) where every part has its OWN colour: the glow colour comes from the VERTEX COLOUR (sRGB, baked by
// art/environment/neutral/build_neutral.gd), so one mesh + one material carries green / blue / orange potions or
// gold coins and a crystal gem. Same look as env_glow.gdshader (fresnel core, slow pulse, energy 2.5-3).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform float energy = 2.6;
uniform float pulse_speed = 1.8;
uniform float pulse_amount = 0.15;

varying vec3 v_col;
varying vec3 v_wp;

void vertex() {
	v_col = pow(COLOR.rgb, vec3(2.2));
	v_wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	float pulse = 1.0 + sin(TIME * pulse_speed + v_wp.x * 1.3 + v_wp.z * 0.9) * pulse_amount;
	vec3 core = mix(v_col, vec3(1.0), 0.45);
	ALBEDO = v_col * 0.25;
	EMISSION = mix(v_col, core, fres) * energy * pulse;
	ROUGHNESS = 0.25;
	SPECULAR = 0.7;
}
