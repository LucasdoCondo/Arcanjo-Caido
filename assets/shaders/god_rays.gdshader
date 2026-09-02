// ============================================================================
// [ARCANJOS CAIDOS] — God Rays / Volumetric Light Shader
// ----------------------------------------------------------------------------
// Shader para raios de luz volumétricos (crepusculares).
// Simula luz passando por frestas em cenários escuros.
// 
// Uso: Aplique em ColorRect em cima da cena, com blend mode Add.
// ============================================================================

shader_type canvas_item;

render_mode blend_add;

// --- Parâmetros ---
uniform float intensity : hint_range(0.0, 1.0) = 0.4;
uniform float ray_speed : hint_range(0.0, 2.0) = 0.3;
uniform float ray_frequency : hint_range(1.0, 20.0) = 8.0;
uniform float ray_softness : hint_range(0.1, 2.0) = 0.5;
uniform vec4 ray_color : source_color = vec4(1.0, 0.9, 0.7, 1.0);

// --- Direção da luz ---
uniform vec2 light_direction : hint_range(-1.0, 1.0) = vec2(0.3, -1.0);

// --- Funções ---
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i), hash(i + vec2(1,0)), f.x),
        mix(hash(i + vec2(0,1)), hash(i + vec2(1,1)), f.x),
        f.y
    );
}

void fragment() {
    vec2 uv = UV;
    
    // Direção do raio
    vec2 dir = normalize(light_direction);
    
    // Projeção UV na direção do raio
    float projection = dot(uv - vec2(0.5), dir);
    
    // Animação
    float t = TIME * ray_speed;
    
    // Padrão de raios
    float rays = 0.0;
    for (int i = 0; i < 3; i++) {
        float fi = float(i);
        float offset = noise(vec2(projection * ray_frequency + fi * 10.0, t + fi * 5.0));
        rays += smoothstep(0.3 - ray_softness, 0.3, offset);
    }
    rays /= 3.0;
    
    // Atenuação nas bordas
    float edge_fade = smoothstep(0.0, 0.3, uv.x) * smoothstep(1.0, 0.7, uv.x);
    edge_fade *= smoothstep(0.0, 0.2, uv.y) * smoothstep(1.0, 0.5, uv.y);
    
    // Cor final
    vec3 color = ray_color.rgb * rays * intensity * edge_fade;
    
    COLOR = vec4(color, rays * intensity * edge_fade);
}