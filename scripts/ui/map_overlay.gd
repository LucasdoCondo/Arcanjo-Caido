extends CanvasLayer
## ============================================================================
## [ARCANJO CAIDO] — Autoload: MapOverlay
## ----------------------------------------------------------------------------
## Tela de mapa pausada (tecla M), estilo Hollow Knight + Cassandra:
##   - Fog of war: só desenha salas VISITADAS (ou reveladas pelo mapa
##     comprado com a Cartógrafa Cassandra — aparecem só como contorno)
##   - Ícones: Pontos de Descanso (bancos), NPCs e conexões entre salas
##   - Sala atual destacada em dourado
##   - Marcador personalizado: com o mapa aberto, aperte E para marcar/desmarcar
##   - [DEBUG] K revela todas as salas (simula compra do mapa da Cassandra)
## ============================================================================

const CELL: float = 56.0
const COL_BG := Color(0.03, 0.03, 0.05, 0.94)
const COL_ROOM := Color(0.16, 0.15, 0.2, 1.0)
const COL_BORDER := Color(0.83, 0.69, 0.22, 1.0)
const COL_REVEALED := Color(0.55, 0.53, 0.6, 0.55)
const COL_CURRENT := Color(1.0, 0.85, 0.3, 1.0)
const COL_MARKER := Color(0.9, 0.25, 0.25, 1.0)
const COL_TEXT := Color(0.92, 0.89, 0.8, 1.0)

var _open: bool = false
var _canvas: MapCanvas


class MapCanvas extends Control:
	func _draw() -> void:
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(24.0, 44.0), "MAPA DE AETERNA",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0.92, 0.89, 0.8, 1.0))

		# Salas visíveis: visitadas ou reveladas pela Cassandra.
		var visible_ids: Array = []
		for id in GameState.rooms:
			if GameState.is_room_visible(id):
				visible_ids.append(id)

		if visible_ids.is_empty():
			draw_string(font, Vector2(24.0, 120.0),
					"O mapa está em branco... Explore Aeterna para revelá-lo.",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.6, 0.58, 0.55, 1.0))
			return

		# Limites da grade (para centralizar o desenho).
		var min_col := 9999
		var max_col := -9999
		var min_row := 9999
		var max_row := -9999
		for id in visible_ids:
			var r: Dictionary = GameState.rooms[id]
			min_col = mini(min_col, r.col)
			max_col = maxi(max_col, r.col + r.w - 1)
			min_row = mini(min_row, r.row)
			max_row = maxi(max_row, r.row + r.h - 1)

		var content := Vector2((max_col - min_col + 1) * CELL, (max_row - min_row + 1) * CELL)
		var offset := (size - content) * 0.5 + Vector2(0.0, 20.0)

				# Conexões (passagens) entre salas visíveis.
		for id in visible_ids:
			var r: Dictionary = GameState.rooms[id]
			var a := _room_center(offset, r, min_col, min_row)
			for conn in r.connections:
				if visible_ids.has(conn):
					var b := _room_center(offset, GameState.rooms[conn], min_col, min_row)
					draw_line(a, b, COL_BORDER, 3.0)

		# Salas + ícones.
		for id in visible_ids:
			var r: Dictionary = GameState.rooms[id]
			var top_left := offset + Vector2((r.col - min_col) * CELL, (r.row - min_row) * CELL)
			var rect := Rect2(top_left, Vector2(r.w * CELL, r.h * CELL))

			if GameState.visited.has(id):
				draw_rect(rect, COL_ROOM)                      # preenchida
				draw_rect(rect, COL_BORDER, false, 2.0)        # contorno dourado
			else:
				draw_rect(rect, COL_REVEALED, false, 1.5)      # só contorno (Cassandra)

			var icon_base := top_left + Vector2(10.0, rect.size.y - 18.0)
			if r.bench:
				draw_rect(Rect2(icon_base, Vector2(12.0, 8.0)), Color(0.55, 0.36, 0.2, 1.0))
			if r.npc:
				draw_circle(icon_base + Vector2(22.0, 4.0), 5.0, Color(0.35, 0.55, 0.85, 1.0))

			# Sala atual: destaque dourado + ponto do jogador.
			if GameState.current_room_id == id and GameState.visited.has(id):
				draw_rect(rect, COL_CURRENT, false, 3.0)
				draw_circle(rect.get_center(), 4.0, COL_CURRENT)

			# Marcador personalizado do jogador (losango vermelho).
			if GameState.markers.get(id, false):
				var m := rect.get_center() + Vector2(0.0, -CELL * 0.25)
				draw_colored_polygon(
					PackedVector2Array([m + Vector2(0, -7), m + Vector2(7, 0),
							m + Vector2(0, 7), m + Vector2(-7, 0)]), COL_MARKER)

		# Legenda.
		var legend_y := size.y - 28.0
		draw_string(font, Vector2(24.0, legend_y),
				"M: fechar    E: marcar/desmarcar sala atual",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 15, COL_TEXT)

	func _room_center(offset: Vector2, r: Dictionary, min_col: int, min_row: int) -> Vector2:
		var top_left := offset + Vector2((r.col - min_col) * CELL, (r.row - min_row) * CELL)
		return top_left + Vector2(r.w * CELL, r.h * CELL) * 0.5


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	var bg := ColorRect.new()
	bg.color = COL_BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)

	_canvas = MapCanvas.new()
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_canvas)
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)


func _unhandled_input(event: InputEvent) -> void:
	if DialogueUI.active:
		return  ## Diálogo em andamento tem prioridade
	if event.is_action_pressed("map"):
		_toggle_map()
		get_viewport().set_input_as_handled()
		return

	if _open and event.is_action_pressed("interact"):
		if GameState.current_room_id != "":
			GameState.toggle_marker(GameState.current_room_id)
			_canvas.queue_redraw()
		get_viewport().set_input_as_handled()
		return

	# [DEBUG] Revela tudo — simula a compra do mapa da Cassandra.
	if _open and event is InputEventKey and event.pressed and event.physical_keycode == KEY_K:
		GameState.purchase_cassandra_map()
		_canvas.queue_redraw()


func _toggle_map() -> void:
	_open = not _open
	visible = _open
	get_tree().paused = _open
	if _open:
		_canvas.queue_redraw()


## API pública usada pelo PauseMenu (aba Mapa).
func open_map() -> void:
	if not _open:
		_toggle_map()


func close_map() -> void:
	if _open:
		_toggle_map()
