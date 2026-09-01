extends Area2D
## ============================================================================
## [ARCANJO CAIDO] — Passo 2: Superfície de perigo (espinhos, gáseres etc).
## - Dá dano ao jogador quando ele toca (via body_entered -> take_damage)
## - É alvo válido de Pogo Strike (está no grupo "hazard", camada 8)
## ============================================================================

@export var damage: int = 1  ## Dano causado ao tocar


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage, global_position)
