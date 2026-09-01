extends Area2D
## ============================================================================
## [ARCANJO CAIDO] — Passo 5: NPC base.
## Interagir (E) abre o diálogo configurado no DialogueUI (data/dialogs.json).
## Coloque instâncias nas salas e ajuste dialogue_id / start_node.
## ============================================================================

@export var dialogue_id: String = ""     ## chave em data/dialogs.json
@export var start_node: String = "start" ## nó inicial padrão
## Regras de nó por flag (ordem = prioridade): {"flag": "no_inicial"}
@export var start_nodes_by_flag: Dictionary = {}

var _player_inside: Node = null

@onready var visual: ColorRect = $Visual


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = body
		visual.modulate = Color(1.3, 1.3, 1.1)  ## Destaque: falável


func _on_body_exited(body: Node2D) -> void:
	if body == _player_inside:
		_player_inside = null
		visual.modulate = Color.WHITE


func _unhandled_input(event: InputEvent) -> void:
	if _player_inside == null or DialogueUI.active:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		var node := start_node
		for flag in start_nodes_by_flag:
			if GameState.flags.get(flag, false):
				node = start_nodes_by_flag[flag]
				break
		DialogueUI.start_dialogue(dialogue_id, node)
