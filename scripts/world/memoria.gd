extends Area2D
## ============================================================================
## [ARCANJO CAIDO] — Passo 15/lore: Memória Fragmentada (Ato III).
## Fragmento da lembrança de um anjo caído. Ao tocar, exibe a memória via
## DialogueUI e marca a flag correspondente (ex: "lore:m1").
## Coletar todas as memórias é requisito do Final Verdadeiro (conquista
## "A Verdadeira Libertação" — implementação do final no Passo de endings).
## ============================================================================

@export var memoria_id: String = ""   ## ex: "1" → diálogo "memoria_1", flag "lore:m1"


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or memoria_id == "":
		return
	var flag := "lore:m" + memoria_id
	if GameState.flags.get(flag, false):
		return
	GameState.flags[flag] = true
	set_deferred("monitoring", false)
	DialogueUI.start_dialogue("memoria_" + memoria_id, "start")
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1.5, 1.5, 2.0, 0.0), 0.4)
	tw.tween_callback(queue_free)
