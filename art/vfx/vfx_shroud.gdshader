shader_type spatial;
// Umbral Shroud veil (SpellVfx, task A.13): an open, tapered cylinder of dark smoke wrapped around Malrik.
// Wisps rise and swirl, the top frays away, the silhouette edges glow violet (fresnel) so the veil reads as
// "shielded" from the RTS camera. Premultiplied alpha: dark smoke covers, the rim adds light.
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

instance uniform float fade = 1.0;
instance uniform float seed = 0.0;
uniform vec3 smoke_color : source_color = vec3(0.06, 0.02, 0.1);
uniform vec3 rim_color : source_color = vec3(0.55, 0.15, 1.0);
uniform float rim_energy = 1.7;

uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;   // seamless fbm (SpellVfx builds it)

varying vec3 v_local;

void vertex() {
	v_local = VERTEX;
	// Slow twist + breathing so it never looks static.
	float h = VERTEX.y + 0.5;
	float a = sin(TIME * 1.3 + h * 4.0 + seed * 6.0) * 0.12 * h;
	VERTEX.xz = mat2(vec2(cos(a), -sin(a)), vec2(sin(a), cos(a))) * VERTEX.xz;
	VERTEX.xz *= 1.0 + 0.05 * sin(TIME * 2.2 + h * 5.0);
}

void fragment() {
	float h = clamp(v_local.y + 0.5, 0.0, 1.0);          // 0 bottom, 1 top
	float ang = atan(v_local.z, v_local.x) / 6.2831853;
	float t = TIME + seed * 10.0;
	// The angle runs 0-1 around, and the noise texture is seamless, so the wrap has no seam.
	vec2 q = vec2(ang + h * 0.12 + t * 0.03, h * 0.45 - t * 0.16);
	float n = clamp((texture(noise_tex, q).r * 0.6 + texture(noise_tex, q * 2.0 + 0.37).r * 0.4 - 0.5) * 1.8 + 0.5, 0.0, 1.0);
	float streak = texture(noise_tex, vec2(ang * 2.0 + t * 0.05, h * 0.2 - t * 0.3)).r;
	// Bottom dense, top frays into wisps.
	float body = smoothstep(1.02, 0.35, h + (n - 0.5) * 0.55);
	body *= smoothstep(0.0, 0.08, h);
	float wisps = smoothstep(0.45, 0.8, n) * smoothstep(1.0, 0.5, h);
	float edge_on = 1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0);
	float fres = edge_on * edge_on;
	// The silhouette dissolves into noisy wisps instead of the hard edge of a cylinder.
	float sil = smoothstep(0.97, 0.6, edge_on + (n - 0.5) * 0.5);
	float cover = clamp(body * (0.42 + 0.5 * n) + wisps * 0.3, 0.0, 0.9) * sil * fade;
	fres *= sil;
	vec3 glow = rim_color * rim_energy * (fres * (0.35 + 0.65 * n) * body + smoothstep(0.7, 0.95, streak) * body * 0.5);
	ALBEDO = smoke_color * cover + glow * fade;
	ALPHA = cover;
}
