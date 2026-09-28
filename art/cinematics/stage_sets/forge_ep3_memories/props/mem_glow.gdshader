// mem_glow.gdshader - E34-B memory sets (forge_ep3_memories / forge_ep4_memories): additive glow cards that fake the
// light of a candle, a flame, the heart-stone or a green shoot (0-lights rule). Unshaded + additive, TIME-only.
//   discs (radial = 1): UV.y 0 at the centre -> 1 at the rim, soft falloff (light pools on the ground, halos)
//   shells (fres > 0): a sphere seen edge-on fades out (a round glow around a small bright core)
//   mode 0 steady, 1 candle flicker, 2 heartbeat (lub-dub every 1.15 s), 3 slow breath
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec4 color : source_color = vec4(1.0, 0.6, 0.25, 1.0);
uniform float energy = 1.0;
uniform int mode = 0;
uniform float radial = 1.0;
uniform float falloff = 2.0;
uniform float fres = 0.0;
uniform float phase = 0.0;

float beat(float t) {
	float p = mod(t, 1.15);
	return exp(-pow(p * 11.0, 2.0)) + 0.65 * exp(-pow((p - 0.26) * 11.0, 2.0));
}

void fragment() {
	float k = 1.0;
	if (radial > 0.5) {
		k = pow(clamp(1.0 - UV.y, 0.0, 1.0), falloff);
	}
	if (fres > 0.0) {
		k *= pow(clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), fres);
	}
	float t = TIME + phase + COLOR.a * 6.2831;
	float m = 1.0;
	if (mode == 1) {
		m = 0.86 + 0.08 * sin(t * 13.0) + 0.05 * sin(t * 23.0 + 1.3) + 0.04 * sin(t * 5.1);
	} else if (mode == 2) {
		m = 0.42 + 0.95 * beat(t);
	} else if (mode == 3) {
		m = 0.8 + 0.2 * sin(t * 1.4);
	}
	ALBEDO = color.rgb * COLOR.rgb * energy * m;
	ALPHA = clamp(k, 0.0, 1.0);
}
