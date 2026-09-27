shader_type spatial;
// Rune-rifle muzzle flash (UnitIceRifleVfx, task 13b.V7): a crisp lance of cold light out of the crystal muzzle crown,
// with two pairs of snowflake barbs raking forward and a round burst at the mouth. Not a flame: hard crystal edges.
// QuadMesh 1 x 1 drawn as an AXIAL billboard (like unit_fire_gun_flash): the node basis Y = the barrel direction (its
// length = the flash length), X = the width; the quad turns around Y to face the camera and its bottom edge sits ON
// the node origin (the muzzle), so scaling Y shoots the flash forward. ONE material: instance uniforms only.
// White core -> ice glow -> deep blue rim; `age` (s) cools it to blue; `fade` hides it. Premultiplied alpha with a little
// cover so the flash stays blue (not white) over snow.
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, skip_vertex_transform, fog_disabled;

instance uniform vec4 hot = vec4(2.6, 3.0, 3.4, 1.0);     // linear HDR core
instance uniform vec4 tint = vec4(1.1, 2.1, 3.2, 1.0);    // body
instance uniform vec4 edge = vec4(0.10, 0.35, 1.10, 1.0); // barb / rim colour
instance uniform float fade = 1.0;
instance uniform float age = 0.0;
instance uniform float seed = 0.0;

varying vec2 v_uv;
varying float v_aspect;   // width / length

float seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

void vertex() {
	vec3 origin = (MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 axis = (MODELVIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz;
	float width = length((MODELVIEW_MATRIX * vec4(1.0, 0.0, 0.0, 0.0)).xyz);
	float al = length(axis);
	vec3 along = al > 0.00001 ? axis / al : vec3(0.0, 1.0, 0.0);
	vec3 to_cam = normalize(-(origin + axis * 0.5));
	vec3 side = cross(along, to_cam);
	float sl = length(side);
	side = sl > 0.00001 ? side / sl : vec3(1.0, 0.0, 0.0);
	// Seen down the barrel the flash keeps a length of 0.8 x its width (never a sliver).
	float len = max(al, width * 0.8);
	VERTEX = origin + along * (VERTEX.y + 0.5) * len + side * VERTEX.x * width;
	NORMAL = to_cam;
	v_uv = UV;
	v_aspect = width / max(len, 0.0001);
}

void fragment() {
	float s = clamp(1.0 - v_uv.y, 0.0, 1.0);          // 0 = the muzzle, 1 = the tip (length units)
	vec2 p = vec2((v_uv.x - 0.5) * v_aspect, s);       // x in length units too
	float ax = abs(p.x);
	float cool = clamp(age / 0.09, 0.0, 1.0);
	// The lance: a narrow spear tapering to a needle point.
	float lw = 0.045 * pow(1.0 - s, 0.8) + 0.004;
	float lance = 1.0 - smoothstep(lw * 0.4, lw, ax);
	// Snowflake barbs: two pairs raking forward (60 deg), the second pair shorter.
	float jit = 0.012 * sin(seed * 11.0);
	float d = seg(vec2(ax, s), vec2(0.0, 0.10), vec2(0.15 + jit, 0.27));
	d = min(d, seg(vec2(ax, s), vec2(0.0, 0.30), vec2(0.09 - jit, 0.41)));
	// tiny side twigs on the first barb
	d = min(d, seg(vec2(ax, s), vec2(0.075, 0.185), vec2(0.07, 0.25)));
	float barb = 1.0 - smoothstep(0.006, 0.02, d);
	float barb_glow = exp(-d * 55.0) * 0.45;
	// Round burst at the mouth.
	float br = length(vec2(p.x, s - 0.035));
	float burst = 1.0 - smoothstep(0.05, 0.095, br);
	float halo = exp(-max(br - 0.05, 0.0) * 22.0) * 0.5 * (1.0 - s);
	float body = max(max(lance, barb * (1.0 - cool * 0.6)), burst);
	float core = max((1.0 - smoothstep(0.0, lw * 0.35 + 0.004, ax)) * (1.0 - smoothstep(0.1, 0.8, s)),
			1.0 - smoothstep(0.0, 0.06, br));
	float heat = clamp(core * (1.0 - cool * 0.8), 0.0, 1.0);
	vec3 c = mix(edge.rgb, tint.rgb, clamp(lance + burst * 0.8, 0.0, 1.0));
	c = mix(c, hot.rgb, smoothstep(0.2, 0.9, heat));
	float a = clamp(body * fade, 0.0, 1.0);
	vec3 glow = edge.rgb * (barb_glow + halo) * fade * (1.0 - cool * 0.5);
	ALBEDO = c * a + glow;
	ALPHA = a * 0.25;
}
