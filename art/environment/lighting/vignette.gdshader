// vignette.gdshader - screen-space vignette for the RTS view (task A.11, docs/art/lighting.md).
// Drawn by LightingRig on a full-screen ColorRect in a CanvasLayer below the HUD (layer -1), so it
// darkens / tints the 3D world only. Two effects, both cheap (one full-screen ALU-only pass):
//  - an oval corner darkening that frames the play area (painted-illustration look);
//  - a faint haze at the top of the screen (farther ground) for aerial depth.
shader_type canvas_item;
render_mode unshaded;

uniform vec3 tint : source_color = vec3(0.10, 0.06, 0.05);    // corner colour (warm dark brown)
uniform float strength : hint_range(0.0, 1.0) = 0.35;          // corner alpha
uniform float inner : hint_range(0.0, 1.5) = 0.55;             // radius where darkening starts
uniform float outer : hint_range(0.1, 2.0) = 1.15;             // radius where it reaches `strength`
uniform vec3 haze_color : source_color = vec3(0.95, 0.85, 0.70);
uniform float haze_strength : hint_range(0.0, 1.0) = 0.0;      // top-of-screen haze alpha
uniform float haze_height : hint_range(0.01, 1.0) = 0.25;      // share of the screen height it covers

void fragment() {
	vec2 p = (UV - 0.5) * vec2(2.0, 2.0);
	p.x *= 0.85;   // wider than tall: keep the sides lighter than the corners
	float r = length(p);
	float v = smoothstep(inner, outer, r) * strength;
	float h = (1.0 - smoothstep(0.0, haze_height, UV.y)) * haze_strength;
	// Premultiplied-style mix of the two layers into one output.
	vec3 c = mix(haze_color, tint, v / max(v + h, 0.0001));
	COLOR = vec4(c, clamp(v + h, 0.0, 1.0));
}
