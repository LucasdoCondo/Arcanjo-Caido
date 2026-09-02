// ============================================================================
// [ARCANJOS CAIDOS] — Wind Vegetation Shader
// ----------------------------------------------------------------------------
// Shader de distorção de vértices para vegetação, grama, estandartes.
// Faz folhas e plantas balançarem organicamente com o vento.
// 
// Uso: Aplique em Sprite2D de vegetação, árvores, grama, bandeiras.
// ============================================================================

shader_type canvas_item;

// --- Texturas ---
uniform sampler2D texture_albedo : source_texture;
uniform sampler2D texture_normal : hint_normal;

// --- Parâmetros de Vento ---
uniform float wind_strength : hint_range(0.0, 0.1) = 0.02;
uniform float wind_speed : hint_range(0.0, 5.0) = 1.5;
uniform float wind_frequency : hint_range(0.1, 10.0) = 2.0;
uniform float turbulence : hint_range(0.0, 0.05) = 0.01;

// --- Parâmetros de Fase (para variação entre instâncias) ---
uniform float phase_offset : hint_range(0.0, 6.28) = 0.0;

// --- Controle de Animação por Altura ---
// Quanto mais alto no sprite, mais se move (0 = base fixa, 1 = topo livre)
uniform float height_influence : hint_range(0.0, 1.0) = 1.0;

// --- Cor de Tint ---
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// --- Funções de Ruído ---
float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}

float noise(float x) {
    float i = floor(x);
    float f = fract(x);
    return mix(hash(i), hash(i + 1.0), f * f * (3.0 - 2.0 * f));
}

// --- Vertex Shader ---
void vertex() {
    // Posição Y normalizada (0 = base, 1 = topo)
    float height_factor = UV.y * height_influence;
    height_factor = height_factor * height_factor; // Quadrático para mais movimento no topo
    
    // Tempo com offset de fase
    float t = TIME * wind_speed + phase_offset;
    
    // Vento primário (senoidal suave)
    float wind_primary = sin(t + UV.x * wind_frequency) * wind_strength;
    
    // Turbulência (ruído)
    float turb = noise(t * 2.0 + UV.x * 10.0 + UV.y * 5.0) * turbulence;
    
    // Vento secundário (diferente frequência)
    float wind_secondary = sin(t * 1.7 + UV.x * wind_frequency * 1.5) * wind_strength * 0.5;
    
    // Combina todos os componentes de vento
    float total_wind = (wind_primary + turb + wind_secondary) * height_factor;
    
    // Aplica deslocamento horizontal
    VERTEX.x += total_wind;
    
    // Pequeno deslocamento vertical para naturalidade
    VERTEX.y += sin(t * 0.5 + UV.x * 8.0) * turbulence * height_factor * 0.5;
}

// --- Fragment Shader ---
void fragment() {
    vec4 base_color = texture(texture_albedo, UV);
    
    // Aplica tint
    base_color *= tint_color;
    
    // Variação de cor baseada no vento (simula luz passando através)
    float wind_color_shift = sin(TIME * wind_speed * 0.5 + UV.x * 5.0) * 0.05;
    base_color.rgb += wind_color_shift;
    
    COLOR = base_color;
}