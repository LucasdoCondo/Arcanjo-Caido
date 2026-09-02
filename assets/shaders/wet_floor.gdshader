// ============================================================================
// [ARCANJOS CAIDOS] — Wet Floor / Reflective Surface Shader
// ----------------------------------------------------------------------------
// Shader de chão molhado com reflexo de luzes, ondulação e fresnel.
// Estilo: pedra úmida com poças d'água refletindo luzes neon do cenário.
// ============================================================================

shader_type canvas_item;

// --- Texturas ---
uniform sampler2D base_texture : hint_default_white;
uniform sampler2D normal_map : hint_normal;

// --- Parâmetros de Reflexo ---
uniform float reflection_strength : hint_range(0.0, 1.0) = 0.6;
uniform float roughness : hint_range(0.0, 1.0) = 0.3;
uniform float fresnel_power : hint_range(0.5, 5.0) = 2.5;
uniform float normal_strength : hint_range(0.0, 2.0) = 1.0;

// --- Parâmetros de Água/Wetness ---
uniform float wetness : hint_range(0.0, 1.0) = 0.7;
uniform float puddle_frequency : hint_range(1.0, 20.0) = 8.0;
uniform float puddle_depth : hint_range(0.0, 1.0) = 0.4;
uniform vec4 water_tint : source_color = vec4(0.1, 0.2, 0.3, 0.5);

// --- Animação ---
uniform float time_scale : hint_range(0.0, 2.0) = 0.5;
uniform float ripple_speed : hint_range(0.0, 3.0) = 1.0;

// --- Luzes que Refletem (até 4 simultâneas) ---
// Formato: xy = posição UV [0-1], z = raio, w = energia
uniform vec4 light_position_1 : source_color = vec4(0.5, 0.3, 0.0, 1.0);
uniform vec4 light_color_1 : source_color = vec4(1.0, 0.8, 0.4, 1.0);
uniform vec4 light_position_2 : source_color = vec4(0.5, 0.5, 0.0, 0.0);
uniform vec4 light_color_2 : source_color = vec4(0.2, 0.7, 1.0, 1.0);
uniform vec4 light_position_3 : source_color = vec4(0.5, 0.5, 0.0, 0.0);
uniform vec4 light_color_3 : source_color = vec4(1.0, 0.3, 0.5, 1.0);
uniform vec4 light_position_4 : source_color = vec4(0.5, 0.5, 0.0, 0.0);
uniform vec4 light_color_4 : source_color = vec4(0.3, 1.0, 0.5, 1.0);

// --- Funções de Ruído ---
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 4; i++) {
        value += amplitude * noise(p);
        p *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

// --- Cálculo de Reflexo de Luz Pontual ---
vec3 calculate_light_reflection(vec2 uv, vec2 light_pos, vec3 light_color, float light_radius, float light_energy, vec3 normal) {
    vec2 light_dir = light_pos - uv;
    float dist = length(light_dir);
    float attenuation = smoothstep(light_radius, 0.0, dist) * light_energy;
    vec3 view_dir = vec3(0.0, 0.0, 1.0);
    vec3 light_dir_3d = normalize(vec3(light_dir, 0.5));
    vec3 half_vec = normalize(light_dir_3d + view_dir);
    float spec = pow(max(dot(normal, half_vec), 0.0), mix(16.0, 256.0, 1.0 - roughness));
    float fresnel = pow(1.0 - max(dot(normal, view_dir), 0.0), fresnel_power);
    vec3 reflection = light_color * spec * (fresnel + 0.3) * attenuation;
    reflection += light_color * fresnel * attenuation * 0.2;
    return reflection;
}

void fragment() {
    vec2 uv = UV;
    float time = TIME * time_scale;
    vec3 normal_map_sample = texture(normal_map, uv).rgb * 2.0 - 1.0;
    normal_map_sample.xy *= normal_strength;
    float ripple_noise = fbm(uv * puddle_frequency + time * 0.3);
    normal_map_sample += vec3(ripple_noise * 0.1, ripple_noise * 0.1, 0.0);
    vec3 normal = normalize(normal_map_sample);
    vec4 base_color = texture(base_texture, uv);
    float puddle = smoothstep(0.4, 0.6, ripple_noise) * puddle_depth * wetness;
    vec3 view_dir = vec3(0.0, 0.0, 1.0);
    float fresnel = pow(1.0 - max(dot(normal, view_dir), 0.0), fresnel_power);
    fresnel = mix(1.0 - roughness, 1.0, fresnel);
    vec3 total_reflection = vec3(0.0);
    if (light_position_1.w > 0.0) {
        total_reflection += calculate_light_reflection(uv, light_position_1.xy, light_color_1.rgb, light_position_1.z, light_position_1.w, normal);
    }
    if (light_position_2.w > 0.0) {
        total_reflection += calculate_light_reflection(uv, light_position_2.xy, light_color_2.rgb, light_position_2.z, light_position_2.w, normal);
    }
    if (light_position_3.w > 0.0) {
        total_reflection += calculate_light_reflection(uv, light_position_3.xy, light_color_3.rgb, light_position_3.z, light_position_3.w, normal);
    }
    if (light_position_4.w > 0.0) {
        total_reflection += calculate_light_reflection(uv, light_position_4.xy, light_color_4.rgb, light_position_4.z, light_position_4.w, normal);
    }
    vec3 floor_color = base_color.rgb;
    floor_color = mix(floor_color, water_tint.rgb, puddle * water_tint.a);
    float reflection_amount = reflection_strength * fresnel * (0.5 + wetness * 0.5);
    floor_color += total_reflection * reflection_amount;
    floor_color *= 1.0 - puddle * 0.3;
    floor_color = mix(floor_color, floor_color * floor_color * 0.8 + floor_color * 0.2, wetness);
    COLOR = vec4(floor_color, base_color.a);
    if (luminance(COLOR.rgb) > 0.8) {
        COLOR.rgb *= 1.5;
    }
}