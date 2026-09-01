extends EnemyBase
## ============================================================================
## [ARCANJO CAIDO] — Bioma Jardim de Adonai-Gal: "Espectro do Jardim".
## Inimigo VOADOR que herda de EnemyBase apenas o combate (take_hit, flash,
## knockback e loot) — o movimento é próprio: flutuação em senoide e
## perseguição aérea em 2D, com dano por contato.
## ============================================================================

@export var hover_amplitude: float = 22.0     ## Amplitude da flutuação (px)
@export var hover_speed: float = 3.0          ## Velocidade da oscilação
@export var fly_chase_speed: float = 150.0    ## Velocidade de perseguição aérea


func _ready() -> void:
	super()
	start_position = global_position  ## Guarda o "ninho" aéreo


func _physics_process(delta: float) -> void:
	# Flash de dano (herdado).
	_flash_timer = maxf(_flash_timer - delta, 0.0)
	if _flash_timer <= 0.0 and ai_state != AIState.DEAD:
		visual.modulate = Color.WHITE

	if _player == null:
		_player = get_tree().get_first_node_in_group("player")

	# Culling (Passo 14).
	if _player and global_position.distance_to(_player.global_position) > cull_distance:
		return

	_t += delta * hover_speed

	# Comportamento: patrulha aérea em senoide OU perseguição em 2D.
	if _player and _can_see_player():
		var target := _player.global_position + Vector2(0.0, -36.0)
		var dir := (target - global_position).normalized()
		velocity = dir * fly_chase_speed
		facing = 1 if _player.global_position.x > global_position.x else -1
	else:
		var hover := Vector2(
			start_position.x + sin(_t * 0.6) * patrol_distance,
			start_position.y + sin(_t) * hover_amplitude)
		velocity = (hover - global_position) * 3.0
		velocity = velocity.limit_length(move_speed * 1.4)
		facing = 1 if velocity.x >= 0.0 else -1

	# Dano por contato (o toque do Espectro corrói).
	for body in $ContactArea.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(attack_damage, global_position)

	move_and_slide()
	visual.scale.x = absf(visual.scale.x) * float(facing)
	visual.modulate.a = 0.75 + 0.15 * sin(_t * 1.7)  ## Transparência espectral


var _t: float = 0.0
