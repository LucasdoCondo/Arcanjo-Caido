extends Area2D
## ============================================================================
## [ARCANJO CAIDO] — Passo 4: Ponto de Descanso (Estátua do Anjo Caído).
## Ao interagir (E): restaura vida e Chama Negra, define o respawn e
## salva o jogo no Slot 1 (slot de progressão automática).
## ============================================================================

const REST_PROMPT := "Descansar (E): cura + salva o jogo"

var _player_inside: Node = null
var _resting: bool = false

@onready var glow: ColorRect = $Glow


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = body
		glow.color = Color(0.35, 0.8, 0.9, 0.5)  ## brilho ciano: disponível


func _on_body_exited(body: Node2D) -> void:
	if body == _player_inside:
		_player_inside = null
		glow.color = Color(0.83, 0.69, 0.22, 0.25)


func _unhandled_input(event: InputEvent) -> void:
	if _player_inside == null or _resting:
		return
	if event.is_action_pressed("interact"):
		_rest()
		get_viewport().set_input_as_handled()


func _rest() -> void:
	_resting = true
	var player = _player_inside
	if player == null or not is_instance_valid(player):
		return

	# 1) Restaura vida e Chama Negra.
	player.current_health = player.max_health
	player.chama_negra = player.chama_max
	player.health_changed.emit(player.current_health, player.max_health)
	player.chama_changed.emit(player.chama_negra, player.chama_max)

	# 2) Define o respawn aqui (acorda na estátua após morrer).
	GameState.set_respawn(get_tree().current_scene.scene_file_path,
			$RespawnPoint.global_position)

	# 3) Salva o progresso no Slot 1.
	SaveManager.save_slot(0)

	# 4) FX: brilho intenso + som de cura.
	glow.color = Color(1.0, 0.95, 0.6, 0.9)
	AudioManager.sfx("heal")
	var tw := create_tween()
	tw.tween_property(glow, "color", Color(0.83, 0.69, 0.22, 0.25), 1.0)
	tw.tween_callback(func(): _resting = false)
