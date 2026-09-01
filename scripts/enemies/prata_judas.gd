class_name PrataDeJudas
extends Area2D
## ============================================================================
## [ARCANJO CAIDO] — Passo 3: Moeda do jogo ("Pratas de Judas").
## - Solta com velocidade de dispersão (física manual, sem corpo rígido)
## - Magnetiza e voa até o Lúcifer quando ele se aproxima
## - Some ao ser coletada, creditando o valor na bolsa do jogador
## ============================================================================

@export var value: int = 1
@export var magnet_radius: float = 110.0    ## Raio em que começa a ser atraída
@export var collect_radius: float = 18.0    ## Distância para contar como coletada
@export var coin_gravity: float = 1500.0
@export var magnet_speed: float = 620.0
@export var collect_delay: float = 0.45     ## Espera antes de poder ser coletada
@export var life_time: float = 30.0         ## Desaparece se ninguém pegar

var velocity: Vector2 = Vector2.ZERO
var _collect_delay_timer: float = 0.0
var _life_timer: float = 0.0
var _player: Node2D = null


func _ready() -> void:
	_collect_delay_timer = collect_delay
	_life_timer = life_time


func _physics_process(delta: float) -> void:
	_collect_delay_timer = maxf(_collect_delay_timer - delta, 0.0)
	_life_timer -= delta
	if _life_timer <= 0.0:
		queue_free()
		return

	# Cache do jogador.
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")

	# Fase de coleta: magnetiza em direção ao Lúcifer.
	if _collect_delay_timer <= 0.0 and _player != null:
		var dist := global_position.distance_to(_player.global_position)
		if dist <= magnet_radius:
			var to_player := (_player.global_position - global_position).normalized()
			velocity = velocity.move_toward(to_player * magnet_speed, 3400.0 * delta)
		if dist <= collect_radius:
			if _player.has_method("collect_pratas"):
				_player.collect_pratas(value)
			queue_free()
			return

	# Física simples: gravidade + movimento.
	velocity.y += coin_gravity * delta
	position += velocity * delta

	# Quica levemente no "chão de spawn" (queda se acomoda sozinha).
	if velocity.y > 0.0 and absf(velocity.x) < 20.0:
		velocity *= 0.9
