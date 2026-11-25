shader_type canvas_item;

uniform vec4 base_col : source_color = vec4(0.05, 0.55, 0.95, 1.0);
uniform vec4 flame_col : source_color = vec4(0.45, 0.88, 1.0, 1.0);
uniform float heat : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = floor(UV * vec2(48.0, 24.0)) / vec2(48.0, 24.0);
	vec3 col = base_col.rgb;
	if (heat > 0.01) {
		float n = sin(uv.x * 26.0 + TIME * 9.0) * 0.5 + 0.5;
		float n2 = cos(uv.x * 41.0 - TIME * 13.0) * 0.5 + 0.5;
		float tongue = (n * 0.6 + n2 * 0.4) * heat * 0.65;
		float mask = step(uv.y, tongue);
		col = mix(col, flame_col.rgb, mask * 0.75);
	}
	// Hard bottom keycap shadow
	if (UV.y > 0.86) {
		col *= 0.62;
	}
	COLOR = vec4(col, 1.0);
}
