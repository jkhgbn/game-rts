// camp_glow.gdshader - the glowing bits of the monster camp sites (task 12.V24, map-fill.md 5.2 / 10): Mirefang
// eggs, the Gloomcap fairy ring and cap spots, the Stag Glade altar groove and cairn leaves. ONE shared material
// (camp_glow_mat.tres) for every site: the colour comes from the vertex colour, baked by build_camps.gd:
//   COLOR.rgb  glow colour (sRGB)
//   COLOR.a    phase 0-1 (each piece breathes on its own beat)
//   UV.x       energy weight 0-1 (faint moss 0.3-0.5, eggs / spots 0.6, the cores 1.0)
// `lit` is an INSTANCE uniform (CampSite.set_cleared tweens it on the MeshInstance3D, no runtime material):
// 1 = the camp is alive (glow + slow pulse), 0 = cleared (the glow dies, the piece turns a dull ashen version of
// its colour, lit like the rest of the prop). No light, no texture, no alpha.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform float energy = 2.6;
uniform float pulse_speed = 1.3;
uniform float pulse_amount = 0.2;
instance uniform float lit = 1.0;

varying vec3 v_col;
varying float v_phase;
varying float v_w;

void vertex() {
	v_col = pow(COLOR.rgb, vec3(2.2));
	v_phase = COLOR.a;
	v_w = UV.x;
}

void fragment() {
	float l = clamp(lit, 0.0, 1.0);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	float pulse = 1.0 + sin(TIME * pulse_speed + v_phase * 6.2831) * pulse_amount;
	vec3 core = mix(v_col, vec3(1.0), 0.1 + 0.3 * fres);
	float lum = dot(v_col, vec3(0.30, 0.59, 0.11));
	vec3 dead = mix(vec3(lum), v_col, 0.3) * 0.55 + vec3(0.02, 0.018, 0.015);
	ALBEDO = mix(dead, v_col * 0.3, l);
	EMISSION = core * energy * v_w * pulse * l * l;
	ROUGHNESS = mix(0.95, 0.5, l);
	SPECULAR = mix(0.1, 0.4, l);
}
