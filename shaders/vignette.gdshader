shader_type canvas_item;
// Vinheta — escurece as bordas da tela (atmosfera do Vazio).

uniform float intensity : hint_range(0.0, 1.0) = 0.45;
uniform vec4 tint : source_color = vec4(0.0, 0.0, 0.02, 1.0);

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float d = length(uv) * 2.0;
	float v = smoothstep(0.45, 1.35, d) * intensity;
	COLOR = vec4(tint.rgb, v);
}
