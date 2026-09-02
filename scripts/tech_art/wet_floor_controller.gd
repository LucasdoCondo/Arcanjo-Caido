# ============================================================================
# [ARCANJOS CAIDOS] — Wet Floor Controller
# ----------------------------------------------------------------------------
# Controla o shader de chão molhado, atualizando posições das luzes
# que refletem na superfície em tempo real.
#
# Uso: Anexe ao CanvasItem (ColorRect/Polygon2D) que usa o ShaderMaterial
# ============================================================================

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
@export var update_frequency: int = 1  # Atualiza a cada N frames (1 = todo frame)

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
	# Tenta obter o material atual
	material = get_material()
	
	if material is ShaderMaterial:
		_material = material
		_material.set_shader_parameter("wetness", wetness)
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
	
	# Rastreia o player (se tiver luz)
	if track_player and _player and light_index <= max_tracked_lights:
		var player_light := _get_player_light()
		if player_light:
			_update_light_position(light_index, player_light, viewport_size, camera)
			light_index += 1
	
	# Rastreia luzes adicionais
	for light in tracked_lights:
		if light_index > max_tracked_lights:
			break
		if light:
			_update_light_position(light_index, light, viewport_size, camera)
			light_index += 1
	
	# Desativa luzes restantes
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
	
	# Procura por luzes no player
	for child in _player.get_children():
		if child is PointLight2D:
			return child
	
	return null


## API: Atualiza parâmetros de wetness em tempo de útil
## Útil para efeitos de chuva, inundação, etc.
func set_wetness(value: float) -> void:
	wetness = clampf(value, 0.0, 1.0)


## API: Adiciona uma luz para rastrear
func add_tracked_light(light: PointLight2D) -> void:
	if not tracked_lights.has(light):
		tracked_lights.append(light)


## API: Remove uma luz do rastreamento
func remove_tracked_light(light: PointLight2D) -> void:
	tracked_lights.erase(light)