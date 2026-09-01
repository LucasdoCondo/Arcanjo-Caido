extends Area2D
## ============================================================================
## [ARCANJO CAIDO] — Passo 8: Relíquia de Habilidade.
## Pickup que desbloqueia uma habilidade de exploração ao ser tocada
## (no jogo final, dropada/aprendida ao derrotar chefes específicos).
## ============================================================================

@export var ability_id: String = ""   ## "wall_jump" | "double_jump" | "ground_pound" | "hook"
@export var ability_name: String = "" ## Nome exibido (futuro: toast de unlock)


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or ability_id == "":
		return
	if not GameState.abilities.get(ability_id, false):
		GameState.unlock_ability(ability_id)
		print("[ARCANJO CAIDO] Habilidade desbloqueada: %s" %
				(ability_name if ability_name != "" else ability_id))
	## FX simples de coleta: brilho e some.
	set_deferred("monitoring", false)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(3.0, 3.0, 2.0, 0.0), 0.25)
	tw.tween_callback(queue_free)
