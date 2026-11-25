shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float intensity : hint_range(0.0, 1.0) = 0.45;
uniform float scanline_count : hint_range(120.0, 720.0) = 360.0;

vec2 warp_uv(vec2 uv, float amt) {
	vec2 centered = uv * 2.0 - 1.0;
	vec2 offset = abs(centered.yx) / vec2(6.5, 5.0);
	centered = centered + centered * offset * offset * amt;
	return centered * 0.5 + 0.5;
}

void fragment() {
	if (intensity <= 0.001) {
		COLOR = texture(screen_tex, SCREEN_UV);
	} else {
		vec2 uv = warp_uv(SCREEN_UV, intensity * 0.85);
		if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
			COLOR = vec4(0.02, 0.03, 0.05, 1.0);
		} else {
			float chroma = 0.0016 * intensity;
			float r = texture(screen_tex, uv + vec2(chroma, 0.0)).r;
			float g = texture(screen_tex, uv).g;
			float b = texture(screen_tex, uv - vec2(chroma, 0.0)).b;
			vec3 col = vec3(r, g, b);

			float scan = sin(uv.y * scanline_count * 3.14159265 * 2.0);
			col *= 1.0 - (0.11 * intensity * (0.5 + 0.5 * scan));

			vec2 vig_uv = uv * (1.0 - uv.yx);
			float vig = clamp(pow(vig_uv.x * vig_uv.y * 16.0, 0.18 * intensity), 0.0, 1.0);
			col *= mix(1.0, vig, intensity * 0.75);
			col *= 1.0 + 0.05 * intensity;

			COLOR = vec4(col, 1.0);
		}
	}
}
