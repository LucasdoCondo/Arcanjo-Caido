shader_type canvas_item;
// Névoa volumétrica 2D — duas camadas de ruído em movimento lento.

uniform vec4 fog_color : source_color = vec4(0.4, 0.45, 0.55, 1.0);
uniform float speed : hint_range(0.0, 0.2) = 0.02;
uniform float scale : hint_range(1.0, 8.0) = 3.0;
uniform float max_alpha : hint_range(0.0, 1.0) = 0.25;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	vec2 uv = UV * scale;
	float t = TIME * speed;
	// Duas camadas de ruído em direções opostas (profundidade).
	float n = vnoise(uv + vec2(t, t * 0.3)) * 0.6
			+ vnoise(uv * 1.7 - vec2(t * 1.3, 0.0)) * 0.4;
	float alpha = smoothstep(0.45, 0.9, n) * max_alpha;
	COLOR = vec4(fog_color.rgb, alpha);
}
