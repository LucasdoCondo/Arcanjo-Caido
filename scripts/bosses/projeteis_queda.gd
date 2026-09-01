extends Area2D
## ============================================================================
## [ARCANJO CAIDO] — Passo 9: Projétil de queda (moeda incandescente do teto
## na Fase 1 e lingote pesado da Fase 2 de Mammon). Dano ao tocar o Lúcifer;
## some ao tocar qualquer superfície sólida.
## ============================================================================

@export var damage: int = 1
@export var heavy: bool = false        ## lingote = queda mais rápida
@export var start_speed: float = 120.0

var _velocity: Vector2 = Vector2.ZERO


func setup(is_heavy: bool, start_velocity: Vector2 = Vector2.ZERO) -> void:
	heavy = is_heavy
	if is_heavy:
		damage = 2
	_velocity = start_velocity


func _ready() -> void:
	_velocity.y = start_speed
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	var g := 1500.0 if heavy else 900.0
	_velocity.y += g * delta
	position += _velocity * delta


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position)
	queue_free()  ## some no jogador OU no chão
