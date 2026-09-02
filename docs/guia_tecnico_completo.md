# Guia Técnico Completo — Arcanjos Caídos
## Direção de Arte: Legend of Mana × Hollow Knight
### Lead Technical Artist — Godot 4.7+

---

## Índice

1. Arquitetura de Cena e Paralaxe de 7 Camadas
2. Iluminação 2D e Normal Maps
3. Pós-Processamento e Atmosfera
4. Shaders Customizados
5. Pipeline de Arte

---

## 1. Arquitetura de Cena e Paralaxe

### 1.1 Estrutura de Nós Completa

```
Room (Node2D) — Nível raiz da sala
|
├── WorldEnvironment
|   └── environment: Resource (Glow, Tonemap, Color Correction)
|
├── ParallaxBackground
|   ├── motion_mirroring: Vector2(1920, 0)
|   |
|   ├── ParallaxLayer_Sky (z_index: -70)
|   |   ├── motion_scale: Vector2(0.0, 0.0)
|   |   └── Sprite2D (céu em aquarela)
|   |
|   ├── ParallaxLayer_MountainsFar (z_index: -60)
|   |   ├── motion_scale: Vector2(0.05, 0.02)
|   |   └── Sprite2D (montanhas distantes)
|   |
|   ├── ParallaxLayer_MountainsNear (z_index: -50)
|   |   ├── motion_scale: Vector2(0.15, 0.05)
|   |   └── Sprite2D (montanhas próximas)
|   |
|   ├── ParallaxLayer_ForestFar (z_index: -40)
|   |   ├── motion_scale: Vector2(0.3, 0.1)
|   |   └── Sprite2D (floresta média)
|   |
|   ├── ParallaxLayer_ForestNear (z_index: -30)
|   |   ├── motion_scale: Vector2(0.5, 0.15)
|   |   └── Sprite2D (floresta próxima)
|   |
|   ├── ParallaxLayer_Details (z_index: -20)
|   |   ├── motion_scale: Vector2(0.7, 0.2)
|   |   └── Sprite2D (raízes, pedras)
|   |
|   └── ParallaxLayer_Foreground (z_index: -10)
|       ├── motion_scale: Vector2(0.9, 0.3)
|       └── Sprite2D (silhueta frontal)
|
├── DirectionalLight2D (luz ambiente global)
|
├── LightingManager (Node2D)
|   └── script: lighting_manager_advanced.gd
|
├── WetFloor (ColorRect com ShaderMaterial)
|   └── script: wet_floor_controller.gd
|
├── NeonLights (PointLight2D instâncias)
|
├── AmbientParticles (Node2D)
|   └── script: particle_ambient.gd
|
├── GameplayElements
|   ├── StaticBody2D (chão, paredes)
|   ├── Player (instância)
|   ├── Enemies (instâncias)
|   └── Interactables (instâncias)
|
└── Camera2D
    └── script: camera_controller_2d.gd
```

### 1.2 Tabela de Configuração das Camadas de Paralaxe

| Camada | Nome | motion_scale | z_index | Descrição |
|--------|------|--------------|---------|-----------|
| 7 | Sky | (0.0, 0.0) | -70 | Céu estático em aquarela |
| 6 | MountainsFar | (0.05, 0.02) | -60 | Montanhas distantes (silhueta) |
| 5 | MountainsNear | (0.15, 0.05) | -50 | Montanhas próximas |
| 4 | ForestFar | (0.3, 0.1) | -40 | Floresta ao fundo |
| 3 | ForestNear | (0.5, 0.15) | -30 | Floresta média |
| 2 | Details | (0.7, 0.2) | -20 | Detalhes (raízes, pedras) |
| 1 | Foreground | (0.9, 0.3) | -10 | Primeiro plano (silhueta escura) |

**Regra:** Quanto menor o motion_scale, mais distante parece a camada.

### 1.3 Script de Camera2D Cinematográfica

```gdscript
class_name CameraController2D
extends Camera2D

@export_group("Smooth Follow")
@export var smoothing_enabled: bool = true
@export var smoothing_speed: float = 5.0
@export var look_ahead_enabled: bool = true
@export var look_ahead_distance: float = 50.0
@export var look_ahead_speed: float = 3.0

@export_group("Camera Shake")
@export var shake_enabled: bool = true
@export var shake_decay: float = 5.0
@export var shake_max_offset: float = 10.0
@export var shake_max_roll: float = 0.05

@export_group("Zoom Dinâmico")
@export var zoom_dynamic_enabled: bool = true
@export var zoom_default: Vector2 = Vector2(1.0, 1.0)
@export var zoom_speed_multiplier: float = 1.0
@export var zoom_lerp_speed: float = 3.0
@export var zoom_min: float = 0.8
@export var zoom_max: float = 1.3

@export_group("Deadzone")
@export var deadzone_enabled: bool = true
@export var deadzone_width: float = 80.0
@export var deadzone_height: float = 60.0

var _target: Node2D = null
var _look_ahead_velocity: Vector2 = Vector2.ZERO
var _shake_trauma: float = 0.0
var _shake_time: float = 0.0
var _current_zoom: Vector2 = Vector2.ONE
var _noise := FastNoiseLite.new()

func _ready() -> void:
	_setup_noise()
	_find_target()
	_current_zoom = zoom_default
	zoom = zoom_default

func _process(delta: float) -> void:
	if _target == null:
		_find_target()
		return
	_follow_target(delta)
	_apply_shake(delta)
	_update_zoom(delta)

func _setup_noise() -> void:
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.seed = randi()
	_noise.frequency = 4.0

func _find_target() -> void:
	_target = get_tree().get_first_node_in_group("player")

func _follow_target(delta: float) -> void:
	var target_pos := _target.global_position
	if look_ahead_enabled:
		var velocity := Vector2.ZERO
		if _target is CharacterBody2D:
			velocity = (_target as CharacterBody2D).velocity
		var target_look_ahead := velocity.normalized() * look_ahead_distance if velocity.length() > 10.0 else Vector2.ZERO
		_look_ahead_velocity = _look_ahead_velocity.lerp(target_look_ahead, look_ahead_speed * delta)
		target_pos += _look_ahead_velocity
	if deadzone_enabled:
		var current_offset := global_position - target_pos
		var deadzone_x := deadzone_width / zoom.x
		var deadzone_y := deadzone_height / zoom.y
		if absf(current_offset.x) < deadzone_x:
			target_pos.x = global_position.x
		if absf(current_offset.y) < deadzone_y:
			target_pos.y = global_position.y
	if smoothing_enabled:
		global_position = global_position.lerp(target_pos, smoothing_speed * delta)
	else:
		global_position = target_pos

func _apply_shake(delta: float) -> void:
	if not shake_enabled or _shake_trauma <= 0.0:
		offset = Vector2.ZERO
		rotation = 0.0
		return
	_shake_time += delta
	var shake_amount := pow(_shake_trauma, 2.0)
	var offset_x := _noise.get_noise_2d(_shake_time * 20.0, 0.0) * shake_max_offset * shake_amount
	var offset_y := _noise.get_noise_2d(0.0, _shake_time * 20.0) * shake_max_offset * shake_amount
	offset = Vector2(offset_x, offset_y)
	rotation = _noise.get_noise_2d(_shake_time * 15.0, 100.0) * shake_max_roll * shake_amount
	_shake_trauma = maxf(_shake_trauma - shake_decay * delta, 0.0)
---

## 2. Iluminação 2D e Normal Maps

### 2.1 Hierarquia de Iluminação

```
LightingManager (Node2D)
|
├── DirectionalLight2D (Luz Ambiente Global)
|   ├── energy: 0.4
|   ├── color: Color(0.6, 0.7, 0.9)
|   ├── rotation_degrees: -45
|   ├── shadow_enabled: true
|   └── shadow_filter: SHADOW_FILTER_PCF5
|
├── PointLight2D_NeonCiano (grupo: "neon_cyan")
|   ├── color: Color(0.0, 0.9, 1.0)
|   ├── energy: 2.5
|   ├── texture: GradientTexture2D circular
|   ├── texture_scale: 8.0
|   ├── shadow_enabled: true
|   └── blend_mode: ADD
|
├── PointLight2D_NeonDourado (grupo: "neon_gold")
|   ├── color: Color(1.0, 0.75, 0.2)
|   ├── energy: 2.0
|   ├── texture: GradientTexture2D circular
|   ├── texture_scale: 6.0
|   ├── shadow_enabled: true
|   └── blend_mode: ADD
|
└── PointLight2D_Fogo (grupo: "fire")
    ├── color: Color(1.0, 0.6, 0.2)
    ├── energy: 1.8
    ├── texture: GradientTexture2D
    ├── texture_scale: 4.0
    ├── shadow_enabled: true
    └── blend_mode: ADD
```

### 2.2 Script de Iluminação com Múltiplos Moods

```gdscript
class_name LightingManagerAdvanced
extends Node2D

@export_group("Iluminação Global")
@export var emissive_boost: float = 1.35
@export var ambient_flicker: float = 0.0
@export var flicker_speed: float = 3.0

@export_group("Mood de Sala")
@export var room_mood: Mood = Mood.NEUTRAL
@export var mood_transition_speed: float = 2.0

@export_group("Luz Direcional")
@export var directional_light: DirectionalLight2D
@export var directional_base_energy: float = 0.4
@export var directional_shadow: bool = true

@export_group("Grupos de Luz")
@export var emissive_group: String = "emissive"
@export var neon_cyan_group: String = "neon_cyan"
@export var neon_gold_group: String = "neon_gold"
@export var fire_group: String = "fire"

enum Mood {
	NEUTRAL,
	CYAN_NEON,
	GOLD_WARM,
	DARK_OPPRESSIVE,
	BIOLUMINESCENT,
	CORRUPTION
}

var _emissive_lights: Array[PointLight2D] = []
var _neon_cyan_lights: Array[PointLight2D] = []
var _neon_gold_lights: Array[PointLight2D] = []
var _fire_lights: Array[PointLight2D] = []
var _base_energy: Dictionary = {}
var _target_emissive_boost: float = 1.35
var _time: float = 0.0

func _ready() -> void:
	_collect_lights()
	_apply_normal_maps()
	_setup_directional_light()
	_apply_mood(room_mood)

func _process(delta: float) -> void:
	_time += delta
	_update_flicker()
	_transition_mood(delta)

---

## 3. Pós-Processamento e Atmosfera

### 3.1 Configuração do WorldEnvironment

```gdscript
class_name PostProcessController
extends WorldEnvironment

@export_group("Glow / Bloom")
@export var glow_enabled: bool = true
@export var glow_intensity: float = 0.8
@export var glow_hdr_threshold: float = 0.8
@export var glow_bloom: float = 0.3
@export var glow_strength: float = 1.2

@export_group("Color Correction")
@export var adjustment_enabled: bool = true
@export var brightness: float = 0.95
@export var contrast: float = 1.1
@export var saturation: float = 1.15

@export_group("Tonemapping")
@export var tonemap_mode: TonemapMode = TonemapMode.ACES_FILMIC

enum TonemapMode { LINEAR, ACES_FILMIC, REINHARD, FILMIC }

var _target_glow: float = 0.8
var _target_brightness: float = 0.95
var _transition_speed: float = 2.0

func _ready() -> void:
	_apply_all_settings()

func _process(delta: float) -> void:
	_lerp_settings(delta)

func _apply_all_settings() -> void:
	if environment == null:
		return
	environment.glow_enabled = glow_enabled
	environment.glow_intensity = glow_intensity
	environment.glow_hdr_threshold = glow_hdr_threshold
	environment.glow_bloom = glow_bloom
	environment.glow_strength = glow_strength
	environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	environment.glow_hdr_luminance_cap = 10.0
	environment.adjustment_enabled = adjustment_enabled
	environment.adjustment_brightness = brightness
### 3.2 Sistema de Partículas Ambiente

```gdscript
class_name ParticleAmbientSystem
extends Node2D

@export_group("Configuração")
@export var particle_type: ParticleType = ParticleType.DUST
@export var max_particles: int = 50
@export var emission_area: Vector2 = Vector2(1920, 1080)

@export_group("Movimento")
@export var drift_speed: Vector2 = Vector2(5.0, 2.0)
@export var lifetime_min: float = 3.0
@export var lifetime_max: float = 8.0

@export_group("Aparência")
@export var particle_color: Color = Color(1.0, 0.95, 0.8, 0.6)
@export var particle_size_min: float = 1.0
@export var particle_size_max: float = 3.0

enum ParticleType { DUST, FIREFLIES, SPARKS, MOTES, ASH, SNOW }

var _particles: Array[CPUParticles2D] = []

func _ready() -> void:
	_create_particle_system()

func _create_particle_system() -> void:
	match particle_type:
		ParticleType.DUST: _create_dust()
		ParticleType.FIREFLIES: _create_fireflies()
		ParticleType.SPARKS: _create_sparks()
		ParticleType.MOTES: _create_motes()
		ParticleType.ASH: _create_ash()
		ParticleType.SNOW: _create_snow()

func _create_dust() -> void:
	var p := CPUParticles2D.new()
	p.name = "DustParticles"
	p.amount = max_particles
	p.lifetime = randf_range(lifetime_min, lifetime_max)
	p.emitting = true
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = drift_speed.x * 0.5
	p.initial_velocity_max = drift_speed.x
	p.gravity = Vector2(drift_speed.x * 0.1, -drift_speed.y * 0.2)
	p.scale_amount_min = particle_size_min
	p.scale_amount_max = particle_size_max
	p.color = particle_color
	_setup_fade_gradient(p)
	add_child(p)
	_particles.append(p)

func _create_fireflies() -> void:
	var p := CPUParticles2D.new()
	p.name = "FireflyParticles"
	p.amount = max_particles / 2
	p.lifetime = randf_range(lifetime_min, lifetime_max)
	p.emitting = true
	p.direction = Vector2(0, -1)
	p.spread = 360.0
	p.initial_velocity_min = 10.0
	p.initial_velocity_max = 30.0
	p.gravity = Vector2(0, -10.0)
	p.scale_amount_min = particle_size_min * 1.5
	p.scale_amount_max = particle_size_max * 2.0
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(0.2, 1.0, 0.4, 0.0), Color(0.8, 1.0, 0.3, 1.0), Color(0.2, 1.0, 0.4, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	p.color_ramp = g
	add_child(p)
	_particles.append(p)

func _create_sparks() -> void:
	var p := CPUParticles2D.new()
	p.name = "SparkParticles"
	p.amount = max_particles / 3
	p.lifetime = lifetime_min * 0.5
	p.emitting = true
	p.direction = Vector2(0, 1)
	p.spread = 30.0
	p.initial_velocity_min = 20.0
	p.initial_velocity_max = 60.0
	p.gravity = Vector2(0, 100.0)
	p.scale_amount_min = particle_size_min
	p.scale_amount_max = particle_size_max * 0.5
	p.color = Color(1.0, 0.8, 0.4, 1.0)
	add_child(p)
	_particles.append(p)

func _create_motes() -> void:
	var p := CPUParticles2D.new()
	p.name = "MoteParticles"
---

## 4. Shaders Customizados

### 4.1 Shader 1: Chão Molhado com Reflexo

```glsl
// wet_floor.gdshader
// Shader de chão molhado com reflexo de luzes, ondulação e fresnel.
// USO: Aplique em ColorRect ou Polygon2D que cubra o chão da cena.
// REQUER: viewport/hdr_2d=true para bloom funcionar corretamente.

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
### 4.2 Shader 2: Vegetação com Vento

```glsl
// wind_vegetation.gdshader
// Shader de distorção de vértices para vegetação, grama, estandartes.
// Faz folhas e plantas balançarem organicamente com o vento.
// USO: Aplique em Sprite2D de vegetação, árvores, grama, bandeiras.

shader_type canvas_item;

uniform sampler2D texture_albedo : source_texture;
uniform sampler2D texture_normal : hint_normal;

uniform float wind_strength : hint_range(0.0, 0.1) = 0.02;
uniform float wind_speed : hint_range(0.0, 5.0) = 1.5;
uniform float wind_frequency : hint_range(0.1, 10.0) = 2.0;
uniform float turbulence : hint_range(0.0, 0.05) = 0.01;
uniform float phase_offset : hint_range(0.0, 6.28) = 0.0;
uniform float height_influence : hint_range(0.0, 1.0) = 1.0;
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}

float noise(float x) {
    float i = floor(x);
    float f = fract(x);
    return mix(hash(i), hash(i + 1.0), f * f * (3.0 - 2.0 * f));
}

void vertex() {
    float height_factor = UV.y * height_influence;
    height_factor = height_factor * height_factor;
    float t = TIME * wind_speed + phase_offset;
    float wind_primary = sin(t + UV.x * wind_frequency) * wind_strength;
    float turb = noise(t * 2.0 + UV.x * 10.0 + UV.y * 5.0) * turbulence;
    float wind_secondary = sin(t * 1.7 + UV.x * wind_frequency * 1.5) * wind_strength * 0.5;
    float total_wind = (wind_primary + turb + wind_secondary) * height_factor;
    VERTEX.x += total_wind;
    VERTEX.y += sin(t * 0.5 + UV.x * 8.0) * turbulence * height_factor * 0.5;
}

void fragment() {
    vec4 base_color = texture(texture_albedo, UV);
    base_color *= tint_color;
    float wind_color_shift = sin(TIME * wind_speed * 0.5 + UV.x * 5.0) * 0.05;
    base_color.rgb += wind_color_shift;
    COLOR = base_color;
}
```

### 4.3 Script de Controle do Chão Molhado

```gdscript
class_name WetFloorController
extends ColorRect

@export_group("Controle de Poças")
@export var wetness: float = 0.7
@export var puddle_frequency: float = 8.0
@export var puddle_depth: float = 0.4

@export_group("Reflexo")
@export var reflection_strength: float = 0.6
@export var roughness: float = 0.3

@export_group("Rastreamento de Luzes")
@export var track_player: bool = true
@export var tracked_lights: Array[PointLight2D] = []
@export var max_tracked_lights: int = 4

@export_group("Performance")
@export var update_frequency: int = 1

var _material: ShaderMaterial = null
var _player: CharacterBody2D = null
var _frame_counter: int = 0

func _ready() -> void:
	_setup_shader()
	_find_player()

func _process(_delta: float) -> void:
	_frame_counter += 1
	if _frame_counter % update_frequency != 0:
		return
	_update_shader_params()
	_track_lights()

func _setup_shader() -> void:
	material = get_material()
	if material is ShaderMaterial:
		_material = material
		_material.set_shader_parameter("wetness", wetness)
---

## 5. Pipeline de Arte

### 5.1 Especificações Técnicas

| Asset | Resolução | Formato | Notas |
|-------|-----------|---------|-------|
| Sprites de personagem | 64x64 por frame | PNG com alpha | Quadro-a-quadro |
| Tiles de cenário | 32x32 ou 64x64 | PNG | Grid-based |
| Backgrounds | 1920x1080 mínimo | PNG | Preferencialmente 3840x2160 |
| Atlas de sprites | Máx 2048x2048 | PNG | Use TexturePacker |
| Normal Maps | Mesmo tamanho do sprite | PNG 8-bit RGB | Formato OpenGL |
| LUTs de cor | 256x16 ou 1024x32 | PNG | Para color grading |

### 5.2 Taxas de Quadro para Animações

| Tipo de Animação | FPS | Frames Mínimos |
|------------------|-----|----------------|
| Idle personagem | 8-12 | 4-6 |
| Walk/Run personagem | 12 | 6-8 |
| Ataque | 15-20 | 4-6 |
| VFX (partículas) | 20-30 | 8-12 |
| Background parallax | Estático | 1 |
| Vegetação (wind shader) | Shader-based | N/A |

### 5.3 Paleta de Cores

**Tema Ciano (Mágica/Bioluminescente):**
```
Primária:    #00E6FF (0, 0.9, 1.0)
Secundária:  #0088AA
Destaque:    #80FFFF
Sombra:      #003344
```

**Tema Dourado (Sagrado/Fogo):**
```
Primária:    #FFB347 (1.0, 0.7, 0.2)
Secundária:  #CC7700
Destaque:    #FFE066
Sombra:      #553300
```

**Tema Corrupção (Magenta/Violeta):**
```
Primária:    #E63399 (0.9, 0.2, 0.6)
Secundária:  #9933CC
Destaque:    #FF80FF
Sombra:      #330033
```

**Tema Natureza (Legend of Mana):**
```
Folha:       #44AA66
Carca:       #8B6914
Flor:        #FFB7C5
Água:        #2288AA
```

**Tema Caverna (Hollow Knight):**
```
Pedra:       #333842
Musgo:       #3A5F3A
Fungo:       #6644AA
Abismo:      #0A0A0F
```

### 5.4 Organização de Assets

```
assets/
├── art/
│   ├── characters/
│   │   ├── lucifer/
│   │   │   ├── lucifer_sheet.png
│   │   │   ├── lucifer_sheet_normal.png
│   │   │   └── lucifer_roughness.png
│   │   └── enemies/
│   ├── tiles/
│   │   ├── pedra/
│   │   │   ├── pedra_parede.png
│   │   │   └── pedra_parede_normal.png
│   │   └── madeira/
│   ├── backgrounds/
│   │   ├── jardim_adonai/
│   │   │   ├── bg_sky.png
│   │   │   ├── bg_mountains_far.png
│   │   │   ├── bg_mountains_near.png
│   │   │   ├── bg_forest_far.png
│   │   │   ├── bg_forest_near.png
│   │   │   ├── bg_details.png
│   │   │   └── bg_foreground.png
│   │   └── ...
│   └── fx/
│       ├── particles/
│       └── shaders/
├── shaders/
│   ├── wet_floor.gdshader
│   ├── wind_vegetation.gdshader
│   └── god_rays.gdshader
└── textures/
    ├── normal_maps/
    └── luts/
```

---

## Resumo de Implementação

| Sistema | Arquivo | Status |
|---------|---------|--------|
| Camera Cinematográfica | camera_controller_2d.gd | ✅ Pronto |
| Iluminação com Moods | lighting_manager_advanced.gd | ✅ Pronto |
| Pós-Processamento | post_process_controller.gd | ✅ Pronto |
| Chão Molhado | wet_floor.gdshader + wet_floor_controller.gd | ✅ Pronto |
| Vegetação com Vento | wind_vegetation.gdshader | ✅ Pronto |
| Raios Volumétricos | god_rays.gdshader | ✅ Pronto |
| Partículas Ambiente | particle_ambient.gd | ✅ Pronto |
| Sistema de Paralaxe | parallax_system.gd | ✅ Pronto |
| Pipeline de Arte | pipeline_artistas.md | ✅ Pronto |

---

**Documento criado por:** Lead Technical Artist
**Engine:** Godot 4.7+
**Última atualização:** 02/09/2026
		_material.set_shader_parameter("puddle_frequency", puddle_frequency)
		_material.set_shader_parameter("puddle_depth", puddle_depth)
		_material.set_shader_parameter("reflection_strength", reflection_strength)
		_material.set_shader_parameter("roughness", roughness)

func _find_player() -> void:
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("player")

func _update_shader_params() -> void:
	if _material:
		_material.set_shader_parameter("wetness", wetness)
		_material.set_shader_parameter("puddle_frequency", puddle_frequency)
		_material.set_shader_parameter("puddle_depth", puddle_depth)
		_material.set_shader_parameter("reflection_strength", reflection_strength)
		_material.set_shader_parameter("roughness", roughness)

func _track_lights() -> void:
	if _material == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var light_index := 1
	if track_player and _player and light_index <= max_tracked_lights:
		var player_light := _get_player_light()
		if player_light:
			_update_light_position(light_index, player_light, viewport_size, camera)
			light_index += 1
	for light in tracked_lights:
		if light_index > max_tracked_lights:
			break
		if light:
			_update_light_position(light_index, light, viewport_size, camera)
			light_index += 1
	for i in range(light_index, max_tracked_lights + 1):
		_material.set_shader_parameter("light_position_" + str(i), Vector4(0.5, 0.5, 0.0, 0.0))

func _update_light_position(index: int, light: PointLight2D, viewport_size: Vector2, camera: Camera2D) -> void:
	var light_screen := light.global_position - camera.global_position
	var light_uv := light_screen / viewport_size
	var pos_param := "light_position_" + str(index)
	var col_param := "light_color_" + str(index)
	_material.set_shader_parameter(pos_param, Vector4(light_uv.x, light_uv.y, 0.35, light.energy * 0.8))
	_material.set_shader_parameter(col_param, Vector4(light.color.r, light.color.g, light.color.b, 1.0))

func _get_player_light() -> PointLight2D:
	if _player == null:
		return null
	for child in _player.get_children():
		if child is PointLight2D:
			return child
	return null

func set_wetness(value: float) -> void:
	wetness = clampf(value, 0.0, 1.0)

func add_tracked_light(light: PointLight2D) -> void:
	if not tracked_lights.has(light):
		tracked_lights.append(light)

func remove_tracked_light(light: PointLight2D) -> void:
	tracked_lights.erase(light)
```
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
```
	p.amount = max_particles
	p.lifetime = randf_range(lifetime_min, lifetime_max)
	p.emitting = true
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = 5.0
	p.initial_velocity_max = 15.0
	p.gravity = Vector2(0, -20.0)
	p.scale_amount_min = particle_size_min * 2.0
	p.scale_amount_max = particle_size_max * 3.0
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(0.0, 0.8, 1.0, 0.0), Color(0.3, 0.9, 1.0, 0.8), Color(0.0, 0.8, 1.0, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	p.color_ramp = g
	add_child(p)
	_particles.append(p)

func _create_ash() -> void:
	var p := CPUParticles2D.new()
	p.name = "AshParticles"
	p.amount = max_particles
	p.lifetime = randf_range(lifetime_min, lifetime_max)
	p.emitting = true
	p.direction = Vector2(0, 1)
	p.spread = 45.0
	p.initial_velocity_min = 10.0
	p.initial_velocity_max = 30.0
	p.gravity = Vector2(0, 50.0)
	p.scale_amount_min = particle_size_min
	p.scale_amount_max = particle_size_max
	p.color = Color(0.3, 0.3, 0.3, 0.7)
	add_child(p)
	_particles.append(p)

func _create_snow() -> void:
	var p := CPUParticles2D.new()
	p.name = "SnowParticles"
	p.amount = max_particles
	p.lifetime = randf_range(lifetime_min * 2.0, lifetime_max * 2.0)
	p.emitting = true
	p.direction = Vector2(0, 1)
	p.spread = 30.0
	p.initial_velocity_min = 20.0
	p.initial_velocity_max = 50.0
	p.gravity = Vector2(0, 80.0)
	p.scale_amount_min = particle_size_min * 1.5
	p.scale_amount_max = particle_size_max * 2.0
	p.color = Color(0.95, 0.95, 1.0, 0.8)
	add_child(p)
	_particles.append(p)

func _setup_fade_gradient(p: CPUParticles2D) -> void:
	var g := Gradient.new()
	g.colors = PackedColorArray([
		Color(particle_color.r, particle_color.g, particle_color.b, 0.0),
		particle_color,
		Color(particle_color.r, particle_color.g, particle_color.b, 0.0)
	])
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	p.color_ramp = g

func set_particle_type(new_type: ParticleType) -> void:
	particle_type = new_type
	for p in _particles:
		p.queue_free()
	_particles.clear()
	_create_particle_system()

func set_color(new_color: Color) -> void:
	particle_color = new_color
	for p in _particles:
		p.color = new_color

func set_emitting(enabled: bool) -> void:
	for p in _particles:
		p.emitting = enabled
```
	environment.adjustment_contrast = contrast
	environment.adjustment_saturation = saturation
	match tonemap_mode:
		TonemapMode.LINEAR: environment.tonemapper = Environment.TONE_MAPPER_LINEAR
		TonemapMode.ACES_FILMIC: environment.tonemapper = Environment.TONE_MAPPER_ACES
		TonemapMode.REINHARD: environment.tonemapper = Environment.TONE_MAPPER_REINHARD
		TonemapMode.FILMIC: environment.tonemapper = Environment.TONE_MAPPER_FILMIC

func _lerp_settings(delta: float) -> void:
	if environment == null:
		return
	environment.glow_intensity = lerp(environment.glow_intensity, _target_glow, delta * _transition_speed)
	environment.adjustment_brightness = lerp(environment.adjustment_brightness, _target_brightness, delta * _transition_speed)

func set_room_mood(mood_name: String) -> void:
	match mood_name:
		"neon_ciano":
			_target_glow = 1.2
			environment.glow_bloom = 0.5
		"escuro_opressivo":
			_target_glow = 0.5
			_target_brightness = 0.85
			environment.glow_bloom = 0.2
		"bioluminescente":
			_target_glow = 1.5
			environment.glow_bloom = 0.6
		_:
			_target_glow = glow_intensity
			_target_brightness = brightness

func flash(duration: float = 0.3, intensity: float = 2.0) -> void:
	var original_glow := _target_glow
	_target_glow = intensity
	await get_tree().create_timer(duration).timeout
	_target_glow = original_glow
```
func _collect_lights() -> void:
	_collect_lights_by_group(emissive_group, _emissive_lights)
	_collect_lights_by_group(neon_cyan_group, _neon_cyan_lights)
	_collect_lights_by_group(neon_gold_group, _neon_gold_lights)
	_collect_lights_by_group(fire_group, _fire_lights)

func _collect_lights_by_group(group: String, array: Array[PointLight2D]) -> void:
	var nodes := get_tree().get_nodes_in_group(group)
	for node in nodes:
		var light := node as PointLight2D
		if light:
			array.append(light)
			_base_energy[light.get_instance_id()] = light.energy

func _apply_normal_maps() -> void:
	var room := get_parent()
	if room:
		FxUtil.apply_normal_maps(room)

func _setup_directional_light() -> void:
	if directional_light:
		directional_light.energy = directional_base_energy
		directional_light.shadow_enabled = directional_shadow
		directional_light.shadow_filter = SHADOW_FILTER_PCF5

func _update_flicker() -> void:
	if ambient_flicker <= 0.0:
		return
	var flicker := 1.0 + ambient_flicker * sin(_time * flicker_speed)
	for light in _emissive_lights:
		var base: float = _base_energy.get(light.get_instance_id(), 1.0)
		light.energy = base * emissive_boost * flicker

func _transition_mood(delta: float) -> void:
	emissive_boost = lerp(emissive_boost, _target_emissive_boost, delta * mood_transition_speed)

func _apply_mood(mood: Mood) -> void:
	match mood:
		Mood.NEUTRAL:
			_target_emissive_boost = 1.35
			ambient_flicker = 0.0
		Mood.CYAN_NEON:
			_target_emissive_boost = 1.8
			ambient_flicker = 0.05
			_tint_lights(_neon_cyan_lights, Color(0.0, 0.9, 1.0))
		Mood.GOLD_WARM:
			_target_emissive_boost = 1.6
			ambient_flicker = 0.1
			_tint_lights(_neon_gold_lights, Color(1.0, 0.75, 0.2))
		Mood.DARK_OPPRESSIVE:
			_target_emissive_boost = 2.5
			ambient_flicker = 0.02
			if directional_light:
				directional_light.energy = directional_base_energy * 0.3
		Mood.BIOLUMINESCENT:
			_target_emissive_boost = 2.0
			ambient_flicker = 0.15
		Mood.CORRUPTION:
			_target_emissive_boost = 1.9
			ambient_flicker = 0.08

func _tint_lights(lights: Array[PointLight2D], color: Color) -> void:
	for light in lights:
		light.color = color

func set_mood(mood: Mood) -> void:
	room_mood = mood
	_apply_mood(mood)

func set_emission(light: PointLight2D, energy: float) -> void:
	if light:
		light.energy = energy

func add_temporary_flicker(intensity: float, duration: float) -> void:
	var initial_flicker := ambient_flicker
	ambient_flicker = intensity
	await get_tree().create_timer(duration).timeout
	ambient_flicker = initial_flicker

func add_temporary_boost(multiplier: float, duration: float) -> void:
	var initial_boost := _target_emissive_boost
	_target_emissive_boost = initial_boost * multiplier
	await get_tree().create_timer(duration).timeout
	_target_emissive_boost = initial_boost
```

### 2.3 Configuração de Normal Maps nos Sprites

```gdscript
extends Sprite2D

@export var normal_map: Texture2D
@export var roughness_map: Texture2D
@export var normal_strength: float = 1.0

func _ready() -> void:
	if normal_map:
		texture_normal = normal_map
	if roughness_map:
		texture_roughness = roughness_map
```

### 2.4 Geração de Normal Maps

**Ferramentas recomendadas:**
- GIMP + plugin Normal Map
- Photoshop (Filter > 3D > Generate Normal Map)
- Online: https://cpetry.github.io/NormalMap-Online/

**Configurações de exportação:**
- Formato: OpenGL (não DirectX!)
- Força: 2.0-4.0 para pedra, 0.5-1.0 para tecido
- Suavização: 1-2 pixels

func _update_zoom(delta: float) -> void:
	if not zoom_dynamic_enabled:
		return
	var target_zoom := zoom_default
	if _target is CharacterBody2D:
		var speed := (_target as CharacterBody2D).velocity.length()
		var speed_factor := clampf(speed / 400.0, 0.0, 1.0) * zoom_speed_multiplier
		target_zoom = Vector2.ONE.lerp(Vector2.ONE * zoom_max, speed_factor)
	target_zoom.x = clampf(target_zoom.x, zoom_min, zoom_max)
	target_zoom.y = clampf(target_zoom.y, zoom_min, zoom_max)
	_current_zoom = _current_zoom.lerp(target_zoom, zoom_lerp_speed * delta)
	zoom = _current_zoom

func add_shake(intensity: float = 0.5) -> void:
	if not shake_enabled:
		return
	_shake_trauma = clampf(_shake_trauma + intensity, 0.0, 1.0)

func set_zoom_target(new_zoom: Vector2) -> void:
	zoom_default = new_zoom

func set_target(new_target: Node2D) -> void:
	_target = new_target
```