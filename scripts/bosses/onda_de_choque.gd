extends Area2D
## ============================================================================
## [ARCANJO CAIDO] — Passo 9: Onda de Choque rasteira gerada pelos braços
## de Mammon (Fase 1) e pela queda dos lingotes. Corre pelo chão e dá dano
## ao Lúcifer ao passar por ele (i-frames do jogador protegem).
## Ignora pisos (só reage ao corpo do jogador).
## ============================================================================

@export var speed: float = 320.0
@export var direction: int = 1
@export var damage: int = 1
@export var life_time: float = 2.2

var _life: float = 0.0


func _ready() -> void:
	_life = life_time
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position.x += direction * speed * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	## Só reage ao jogador; pisos são ignorados (a onda "desliza" neles).
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position)
		queue_free()
