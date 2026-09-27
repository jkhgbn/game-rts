// camp_mud.gdshader - the Bristleback Wallow's mud pit (task 12.V24, map-fill.md 5.2 / 10). ONE shared material
// (camp_mud_mat.tres). The pit mesh is baked by build_camps.gd:
//   COLOR.rgb  wet mud colour (sRGB)
//   UV.x       wetness 0-1 (1 = the standing puddle in the middle, ~0.5 churned mud, 0 the outer lip)
//   UV.y       height above the ground in metres
// `wet` is an INSTANCE uniform (CampSite.set_cleared tweens it on the MeshInstance3D, no runtime material):
// 1 = the boars are home (dark glossy mud, a puddle that mirrors the sky with slow ripples and glints),
// 0 = cleared (the pit dries out: pale caked earth broken by dark cracks, no puddle). Painted toon light like the
// nature props; no light, no screen / depth read.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec3 dry_color : source_color = vec3(0.58, 0.49, 0.37);
uniform vec3 crack_color : source_color = vec3(0.20, 0.15, 0.10);
uniform vec3 sky_color : source_color = vec3(0.62, 0.74, 0.86);
uniform float puddle_level = 0.62;     // wetness where the puddle starts
uniform float ripple_speed = 0.35;
instance uniform float wet = 1.0;

varying vec3 v_wp;
varying vec3 v_col;
varying float v_w;
varying float v_y;

void vertex() {
	v_wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_col = pow(COLOR.rgb, vec3(2.2));
	v_w = UV.x;
	v_y = UV.y;
}

void fragment() {
	float wt = clamp(wet, 0.0, 1.0);
	vec2 p = v_wp.xz;
	float n1 = texture(noise_tex, p * 0.9).r;
	float n2 = texture(noise_tex, p * 2.3 + vec2(0.31, 0.77)).r;
	// Wet mud: painted blotches of darker and lighter mud, hoof-churned.
	vec3 mud = v_col * (0.78 + n1 * 0.36) * mix(0.85, 1.1, smoothstep(0.35, 0.65, n2));
	// The puddle: ragged edge, a sky-tinted sheen, slow ripple rings and small glints.
	float edge = puddle_level + (n1 - 0.5) * 0.22;
	float puddle = smoothstep(edge, edge + 0.06, v_w) * wt;
	// Broad, slow sheen patches drifting over the water (low frequency: no speckle at any zoom).
	float rip = texture(noise_tex, p * 0.32 + vec2(TIME * ripple_speed * 0.05, TIME * ripple_speed * 0.03)).r;
	float rip2 = texture(noise_tex, p * 0.45 - vec2(TIME * ripple_speed * 0.04, -TIME * ripple_speed * 0.025)).r;
	float sheen = smoothstep(0.52, 0.72, rip * 0.6 + rip2 * 0.4);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	// Murky brown-olive water: lighter than the mud, a soft sky sheen.
	vec3 water = mix(v_col * vec3(1.45, 1.4, 1.0), sky_color * 0.45, 0.06 + 0.12 * fres + 0.1 * sheen);
	water *= mix(0.8, 1.0, smoothstep(edge, edge + 0.2, v_w));   // darker ring where the mud meets the water
	// Dried pit: pale caked earth broken into big plates by dark cracks (two low-frequency noise ridges).
	float c1 = abs(texture(noise_tex, p * 0.55 + vec2(0.13, 0.4)).r - 0.5);
	float c2 = abs(texture(noise_tex, p * 1.1 + vec2(0.71, 0.2)).r - 0.5);
	float crack = max(1.0 - smoothstep(0.012, 0.028, c1), (1.0 - smoothstep(0.008, 0.02, c2)) * 0.75);
	crack *= smoothstep(0.2, 0.45, v_w);   // the lip stays plain earth
	float plate = smoothstep(0.03, 0.12, min(c1, c2));   // plate centres lighter, edges curl dark
	vec3 dry = dry_color * (0.9 + n1 * 0.16) * mix(0.82, 1.06, plate) * mix(1.0, 0.92, v_w);
	dry = mix(dry, crack_color, crack * 0.85);
	vec3 wet_col = mix(mud, water, puddle);
	vec3 albedo = mix(dry, wet_col, smoothstep(0.0, 1.0, wt));
	// Contact band on the lip (it meets the grass): a little darker at the very bottom.
	albedo *= mix(0.8, 1.0, smoothstep(0.0, 0.05, v_y));
	ALBEDO = albedo;
	// Glints on the puddle (tiny sparkles that come and go), a faint sheen on wet mud.
	EMISSION = sky_color * puddle * (fres * 0.05 + sheen * 0.03);
	ROUGHNESS = mix(1.0, mix(0.55, 0.15, puddle), wt);
	SPECULAR = mix(0.0, mix(0.25, 0.7, puddle), wt);
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.44, d) * 0.55 + smoothstep(0.58, 0.70, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
	float spec = pow(max(dot(reflect(-LIGHT, NORMAL), VIEW), 0.0), mix(8.0, 60.0, 1.0 - ROUGHNESS));
	SPECULAR_LIGHT += spec * SPECULAR_AMOUNT * ATTENUATION * LIGHT_COLOR * 0.6;
}
