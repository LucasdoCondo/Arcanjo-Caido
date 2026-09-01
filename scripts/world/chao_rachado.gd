extends StaticBody2D
## ============================================================================
## [ARCANJO CAIDO] — Passo 8: Piso Rachado.
## Quebrável exclusivamente pelo Macho de Ferro (Ground Pound). O Area2D
## filho (grupo "gp_breakable") é detectado pela onda de choque do Lúcifer.
## ============================================================================


func smash() -> void:
	## Desativa a colisão imediatamente (Lúcifer cai através) e esfarela.
	collision_layer = 0
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1.0, 0.8, 0.6, 0.0), 0.18)
	tw.tween_callback(queue_free)
