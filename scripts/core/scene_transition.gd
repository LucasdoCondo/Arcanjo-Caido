extends CanvasLayer
## ============================================================================
## [ARCANJO CAIDO] — Autoload: SceneTransition
## ----------------------------------------------------------------------------
## Gerenciador de transição de cenas com fade in / fade out:
##   1) Captura o estado do Lúcifer no GameState
##   2) Escurece a tela
##   3) Troca a cena da sala
##   4) Reposiciona o Lúcifer no Marker2D de spawn da nova sala
##   5) Restaura vida/Chama Negra/Pratas e clareia a tela
## Uso: SceneTransition.change_room("res://scenes/.../sala.tscn", "SpawnNome")
## ============================================================================

var _busy: bool = false
var _rect: ColorRect


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color.BLACK
	_rect.modulate.a = 0.0
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)


func change_room(scene_path: String, spawn_name: String = "Spawn",
		force_position: Variant = null) -> void:
	if _busy:
		return
	_busy = true
	var tree := get_tree()

	# 1) Salva o estado do Lúcifer antes de sair da sala atual.
	var player: Node2D = tree.get_first_node_in_group("player")
	if player:
		GameState.capture_player(player)

	# 2) Fade out.
	var tw_out := create_tween()
	tw_out.tween_property(_rect, "modulate:a", 1.0, 0.3)
	await tw_out.finished

	# 3) Troca a sala.
	tree.change_scene_to_file(scene_path)
	await tree.process_frame
	await tree.process_frame

	# 4) Posiciona no spawn e restaura o estado preservado.
	player = tree.get_first_node_in_group("player")
	if player:
		if force_position is Vector2:
			player.global_position = force_position
			player.velocity = Vector2.ZERO
		else:
			var spawn := tree.current_scene.find_child(spawn_name, true, false)
			if spawn is Node2D:
				player.global_position = (spawn as Node2D).global_position
				player.velocity = Vector2.ZERO
		if player.has_method("apply_state"):
			player.apply_state(GameState.player_data)

	# 5) Fade in.
	var tw_in := create_tween()
	tw_in.tween_property(_rect, "modulate:a", 0.0, 0.3)
	await tw_in.finished
	_busy = false
