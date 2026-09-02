# ============================================================================
# [ARCANJOS CAIDOS] — Post Process Controller
# ----------------------------------------------------------------------------
# Gerencia pós-processamento dinâmico do cenário:
# - Glow/Bloom
# - Color Correction / LUT
# - Tonemapping
# - Transições de humor entre salas
#
# Uso: Anexe ao nó WorldEnvironment. Configure nos exports.
# ============================================================================

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

enum TonemapMode {
	LINEAR,
	ACES_FILMIC,    # Cinematográfico, bom para fantasia
	REINHARD,       # Suave, bom para cenários escuros
	_FILMIC         # Alto contraste, dramático
}

# Internals
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
	
	# Glow
	environment.glow_enabled = glow_enabled
	environment.glow_intensity = glow_intensity
	environment.glow_hdr_threshold = glow_hdr_threshold
	environment.glow_bloom = glow_bloom
	environment.glow_strength = glow_strength
	environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	environment.glow_hdr_luminance_cap = 10.0
	
	# Color Correction
	environment.adjustment_enabled = adjustment_enabled
	environment.adjustment_brightness = brightness
	environment.adjustment_contrast = contrast
	environment.adjustment_saturation = saturation
	
	# Tonemapping
	match tonemap_mode:
		 TonemapMode.LINEAR:
			environment.tonemapper = Environment.TONE_MAPPER_LINEAR
		 TonemapMode.ACES_FILMIC:
			environment.tonemapper = Environment.TONE_MAPPER_ACES
		TonemapMode.REINHARD:
			environment.tonemapper = Environment.TONE_MAPPER_REINHARD
		TonemapMode._FILMIC:
			environment.tonemapper = Environment.TONE_MAPPER_FILMIC


func _lerp_settings(delta: float) -> void:
	if environment == null:
		return
	
	environment.glow_intensity = lerp(environment.glow_intensity, _target_glow, delta * _transition_speed)
	environment.adjustment_brightness = lerp(environment.adjustment_brightness, _target_brightness, delta * _transition_speed)


## API: Define mood visual da sala
func set_room_mood(mood_name: String) -> void:
	match mood_name:
		"neon_ciano":
			_target_glow = 1.2
			environment.glow_bloom = 0.5
			environment.adjustment_saturation = 1.2
		"neon_dourado":
			_target_glow = 1.0
			environment.glow_bloom = 0.4
			environment.adjustment_saturation = 1.1
		"escuro_opressivo":
			_target_glow = 0.5
			_target_brightness = 0.85
			environment.glow_bloom = 0.2
			environment.adjustment_contrast = 1.2
		"bioluminescente":
			_target_glow = 1.5
			environment.glow_bloom = 0.6
			environment.adjustment_saturation = 1.3
		"corrupcao":
			_target_glow = 1.1
			environment.glow_bloom = 0.45
			environment.adjustment_saturation = 0.9
		_:
			_target_glow = glow_intensity
			_target_brightness = brightness


## API: Transição suave para novas configurações
func transition_to(glow: float, brightness: float, speed: float = 2.0) -> void:
	_target_glow = glow
	_target_brightness = brightness
	_transition_speed = speed


## API: Flash de luz (ex: explosão, ataque carregado)
func flash(duration: float = 0.3, intensity: float = 2.0) -> void:
	var original_glow := _target_glow
	_target_glow = intensity
	await get_tree().create_timer(duration).timeout
	_target_glow = original_glow


## API: Ativa/desativa correção de cor
func set_color_correction(enabled: bool) -> void:
	if environment:
		environment.adjustment_enabled = enabled