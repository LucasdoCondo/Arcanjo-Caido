shader_type canvas_item;
// ============================================================================
// [ARCANJO CAIDO] — Passo 18: Reflexo em superfícies (mercúrio / chão polido).
// ----------------------------------------------------------------------------
// Sample a textura da tela (hint_screen_texture) refletida horizontalmente
// sobre a linha do espelho (uniform mirror_y, em uv 0..1 = borda superior do
// ColorRect). Ondas sutis + fade de distância + tint da superfície.
// NOTA: canvas_item não aceita `render_mode = unshaded` (válido só em spatial).
// ============================================================================

uniform sampler2D screen_tex : hint_screen_texture, filter_linear, repeat_disable;
uniform float mirror_y : hint_range(0.0, 1.0) = 0.5;
uniform float wave_amp : hint_range(0.0, 3.0) = 1.5;
uniform float fade : hint_range(0.0, 40.0) = 14.0;
uniform vec4 tint : source_color = vec4(0.22, 0.42, 0.5, 0.7);

void fragment() {
	vec2 uv = SCREEN_UV;

	// Reflete a área ACIMA da linha do espelho:
	//   linha do espelho = mirror_y; fragmento a dy abaixo → amostra dy acima.
	vec2 muv = uv;
	float dy = uv.y - mirror_y;                 // positivo abaixo da linha
	muv.y = clamp(mirror_y - dy, 0.0, 1.0);

	// Ondas suaves (mercúrio vivo).
	muv.y += sin(uv.x * 60.0 + TIME * 8.0) * wave_amp * 0.001;
	muv.x += cos(uv.y * 40.0 + TIME * 6.0) * wave_amp * 0.0008;
	muv = clamp(muv, vec2(0.0), vec2(1.0));

	vec3 col = texture(screen_tex, muv).rgb;

	// Intensidade do reflexo: forte perto da linha, sumindo com a distância.
	float refl = 1.0 - clamp(dy * fade, 0.0, 1.0);
	vec3 out_col = mix(COLOR.rgb, col, refl * 0.9);

	COLOR = vec4(out_col * tint.rgb, tint.a * refl);
}