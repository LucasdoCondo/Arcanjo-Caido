extends Area2D
## ============================================================================
## [ARCANJO CAIDO] — Passo 7: Porta/Passagem entre salas.
## Ao ser tocada (ou interagida, se configurada), dispara a transição com
## fade para a sala destino, preservando o estado do Lúcifer via GameState.
## ============================================================================

@export_file("*.tscn") var target_scene: String = ""  ## Cena da sala destino
@export var target_spawn: String = "Spawn"            ## Nome do Marker2D de chegada
@export var requires_interact: bool = false           ## false = trigger ao tocar

var _armed: bool = true
var _player_inside: Node = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	_player_inside = body
	if _armed and not requires_interact and body.is_in_group("player"):
		_go()


func _on_body_exited(body: Node2D) -> void:
	if body == _player_inside:
		_player_inside = null


func _unhandled_input(event: InputEvent) -> void:
	if _armed and requires_interact and _player_inside != null \
			and event.is_action_pressed("interact"):
		_go()
		get_viewport().set_input_as_handled()


func _go() -> void:
	_armed = false
	if target_scene != "":
		SceneTransition.change_room(target_scene, target_spawn)
