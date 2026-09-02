# ============================================================================
# [ARCANJOS CAIDOS] — Camera Controller 2D Avançado
# ----------------------------------------------------------------------------
# Câmera cinematográfica com smooth follow, shake e zoom dinâmico.
# Estilo Ori/Hollow Knight com peso e fluidez.
#
# Uso: Anexe ao nó Camera2D. O player deve estar no grupo "player".
# ============================================================================

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

@export_group("Limites de Câmera")
@export var limit_left_enabled: bool = false
@export var limit_right_enabled: bool = false
@export var limit_top_enabled: bool = false
@export var limit_bottom_enabled: bool = false

@export_group("Deadzone")
@export var deadzone_enabled: bool = true
@export var deadzone_width: float = 80.0
@export var deadzone_height: float = 60.0

# Internals
var _target: Node2D = null
var _velocity: Vector2 = Vector2.ZERO
var _look_ahead_velocity: Vector2 = Vector2.ZERO
var _shake_trauma: float = 0.0
var _shake_time: float = 0.0
var _noise_y: float = 0.0
var _current_zoom: Vector2 = Vector2.ONE

# Noise para shake (Perlin)
var _noise := FastNoiseLite.new()


func _ready() -> void:
	_setup_noise()
	_find_target()
	_current_zoom = zoom_default
	zoom = zoom_default
	
	# Configura limites se habilitados
	if limit_left_enabled:
		limit_left = -10000000
	if limit_right_enabled:
		limit_right = 10000000
	if limit_top_enabled:
		limit_top = -10000000
	if limit_bottom_enabled:
		limit_bottom = 10000000


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
	
	# Look Ahead — Antecipa movimento
	if look_ahead_enabled:
		var velocity := Vector2.ZERO
		if _target is CharacterBody2D:
			velocity = (_target as CharacterBody2D).velocity
		
		var target_look_ahead := velocity.normalized() * look_ahead_distance if velocity.length() > 10.0 else Vector2.ZERO
		_look_ahead_velocity = _look_ahead_velocity.lerp(target_look_ahead, look_ahead_speed * delta)
		target_pos += _look_ahead_velocity
	
	# Deadzone
	if deadzone_enabled:
		var current_offset := global_position - target_pos
		var deadzone_x := deadzone_width / zoom.x
		var deadzone_y := deadzone_height / zoom.y
		
		if absf(current_offset.x) < deadzone_x:
			target_pos.x = global_position.x
		if absf(current_offset.y) < deadzone_y:
			target_pos.y = global_position.y
	
	# Smooth follow
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
	
	# Offset baseado em noise Perlin
	var offset_x := _noise.get_noise_2d(_shake_time * 20.0, 0.0) * shake_max_offset * shake_amount
	var offset_y := _noise.get_noise_2d(0.0, _shake_time * 20.0) * shake_max_offset * shake_amount
	offset = Vector2(offset_x, offset_y)
	
	# Rotação sutil
	rotation = _noise.get_noise_2d(_shake_time * 15.0, 100.0) * shake_max_roll * shake_amount
	
	# Decay do trauma
	_shake_trauma = maxf(_shake_trauma - shake_decay * delta, 0.0)


func _update_zoom(delta: float) -> void:
	if not zoom_dynamic_enabled:
		return
	
	var target_zoom := zoom_default
	
	# Zoom baseado na velocidade do player
	if _target is CharacterBody2D:
		var speed := (_target as CharacterBody2D).velocity.length()
		var speed_factor := clampf(speed / 400.0, 0.0, 1.0) * zoom_speed_multiplier
		target_zoom = Vector2.ONE.lerp(Vector2.ONE * zoom_max, speed_factor)
	
	target_zoom.x = clampf(target_zoom.x, zoom_min, zoom_max)
	target_zoom.y = clampf(target_zoom.y, zoom_min, zoom_max)
	
	_current_zoom = _current_zoom.lerp(target_zoom, zoom_lerp_speed * delta)
	zoom = _current_zoom


## API: Adiciona shake à câmera
## intensity: 0.0 a 1.0 (força do shake)
func add_shake(intensity: float = 0.5) -> void:
	if not shake_enabled:
		return
	_shake_trauma = clampf(_shake_trauma + intensity, 0.0, 1.0)


## API: Define zoom alvo manualmente
func set_zoom_target(new_zoom: Vector2) -> void:
	zoom_default = new_zoom


## API: Define o target manualmente
func set_target(new_target: Node2D) -> void:
	_target = new_target