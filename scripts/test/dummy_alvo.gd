extends Node2D
## ============================================================================
## [ARCANJO CAIDO] — Passo 2: Alvo de treino para validar combate.
## Possui take_hit() (chamado pela hitbox do Lúcifer), flash de dano,
## recuo visual e "respawn" infinito (é um boneco de treino).
## O EnemyBase real, com IA completa, chega no Passo 3.
## ============================================================================

@export var max_hp: int = 10
@export var flash_duration: float = 0.1

var hp: int
var _flash_timer: float = 0.0

@onready var visual: ColorRect = $Visual


func _ready() -> void:
	hp = max_hp


func _process(delta: float) -> void:
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			visual.modulate = Color.WHITE


## Chamado pela MeleeHitbox do Lúcifer ao acertar a Hurtbox deste alvo.
func take_hit(damage: int, from_position: Vector2) -> void:
	hp -= damage
	_flash_timer = flash_duration
	visual.modulate = Color(3.0, 3.0, 3.0)  ## Flash branco de dano

	# Recuo visual na direção oposta ao golpe.
	var dir := signf(global_position.x - from_position.x)
	if dir == 0.0:
		dir = 1.0
	var tween := create_tween()
	tween.tween_property(visual, "position:x", 6.0 * dir, 0.05)
	tween.tween_property(visual, "position:x", 0.0, 0.12)

	if hp <= 0:
		hp = max_hp  ## Boneco de treino nunca morre de verdade
		visual.modulate = Color(1.0, 0.4, 0.4)
		_flash_timer = 0.3
