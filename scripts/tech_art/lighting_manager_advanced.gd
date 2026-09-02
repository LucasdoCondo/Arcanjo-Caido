# ============================================================================
# [ARCANJOS CAIDOS] — Lighting Manager Avançado
# ----------------------------------------------------------------------------
# Gerencia iluminação global do cenário, incluindo:
# - Boost de emissão para luzes neon (Bloom)
# - Flicker ambiental
# - Transições de mood entre salas
# - Normal maps automáticos
#
# Uso: Coloque como filho da cena da sala (Room). Configure nos exports.
# ============================================================================

class_name LightingManagerAdvanced
extends Node2D

@export_group("Iluminação Global")
@export var emissive_boost: float = 1.35
@export var ambient_flicker: float = 0.0
@export var flicker_speed: float = 3.0

@export_group("Mood de Sala")
@export var room_mood: Mood = Mood.NEUTRAL
@export var mood_transition_speed: float = 2.0

@export_group("Luzes de Ambiente")
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
	CYAN_NEON,      # Áreas mágicas/bioluminescentes
	GOLD_WARM,      # Áreas sagradas/de fogo
	DARK_OPPRESSIVE, # Cavernas escuras estilo Hollow Knight
	BIOLUMINESCENT, # Floresta mágica estilo Legend of Mana
	CORRUPTION      # Áreas corrompidas/magenta
}

# Internals
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


func _collect_lights() -> void:
	# Coleta luzes por grupo
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


## API: Muda o mood da sala com transição suave
func set_mood(mood: Mood) -> void:
	room_mood = mood
	_apply_mood(mood)


## API: Força energia de uma luz emissive
func set_emission(light: PointLight2D, energy: float) -> void:
	if light:
		light.energy = energy


## API: Adiciona flicker temporário (ex: dano, explosão)
func add_temporary_flicker(intensity: float, duration: float) -> void:
	var initial_flicker := ambient_flicker
	ambient_flicker = intensity
	await get_tree().create_timer(duration).timeout
	ambient_flicker = initial_flicker


## API: Boost temporário de emissão (ex: ataque carregado)
func add_temporary_boost(multiplier: float, duration: float) -> void:
	var initial_boost := _target_emissive_boost
	_target_emissive_boost = initial_boost * multiplier
	await get_tree().create_timer(duration).timeout
	_target_emissive_boost = initial_boost