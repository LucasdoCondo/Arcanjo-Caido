class_name SaveSlotSelector
extends VBoxContainer
## ============================================================================
## [ARCANJO CAIDO] — Passo 22: Seletor de Save Slots (Menu Principal).
## ----------------------------------------------------------------------------
## 3 slots independentes (user://save_slot_N.json — SaveManager, 100% offline).
## Cada slot usado exibe: Região atual, Tempo Total de Jogo (H:MM),
## Pratas de Judas e % de Conclusão do Mapa.
## Slot vazio exibe "Criar Novo Slot" (inicia um novo jogo naquele slot).
## ----------------------------------------------------------------------------
## Modos:
##   MODE_LOAD — Carregar Jogo: só slots existentes são clicáveis.
##   MODE_NEW  — Novo Jogo: escolhe o slot onde a jornada começa; se o slot
##               já tem save, pede confirmação para sobrescrever.
## ============================================================================

signal slot_selected(slot: int, is_new_game: bool)

enum Mode { MODE_LOAD, MODE_NEW }

const COL_TEXT := Color(0.92, 0.89, 0.8)
const COL_DIM := Color(0.6, 0.58, 0.55)
const COL_EMPTY := Color(0.45, 0.43, 0.42)

var mode: int = Mode.MODE_LOAD
var _slot_buttons: Dictionary = {}  ## slot -> Button (para confirmar sobrescrita)


func _init(p_mode: int = Mode.MODE_LOAD) -> void:
	mode = p_mode


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	_rebuild()


func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	_slot_buttons.clear()

	var header := Label.new()
	header.text = "— SAVE SLOTS DE AETERNA (3 slots locais) —"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_color_override("font_color", COL_DIM)
	add_child(header)

	for slot in SaveManager.SLOT_COUNT:
		add_child(_make_slot_row(slot))

	var btn_back := Button.new()
	btn_back.text = "Voltar"
	btn_back.pressed.connect(func(): slot_selected.emit(-1, false))
	add_child(btn_back)


func _make_slot_row(slot: int) -> Button:
	var info := SaveManager.get_slot_info(slot)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(520.0, 64.0)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

	if info.is_empty():
		## Slot vazio: sempre clicável no modo Novo Jogo.
		btn.text = "Slot %d  —  VAZIO" % (slot + 1)
		if mode == Mode.MODE_NEW:
			btn.text += "  (Criar Novo Slot)"
			btn.add_theme_color_override("font_color", COL_TEXT)
		else:
			btn.disabled = true
			btn.add_theme_color_override("font_color", COL_EMPTY)
	else:
		btn.text = _format_slot(slot, info)
		btn.add_theme_color_override("font_color", COL_TEXT)

	var captured: int = slot
	btn.pressed.connect(func(): _on_slot_pressed(captured, not info.is_empty()))
	if mode == Mode.MODE_NEW and not info.is_empty():
		## Passo 22: sobrescrever exige duplo clique (confirmação).
		btn.text += "\n⚠ JÁ EXISTE SAVE — clique de novo para SOBRESCREVER"
		_slot_buttons[slot] = {"btn": btn, "armed": false}
	add_child(btn)
	return btn


func _format_slot(slot: int, info: Dictionary) -> String:
	## Dados exibidos por slot (Passo 22.2):
	## Região | Tempo Total de Jogo (H:MM) | Pratas de Judas | % Conclusão.
	var region: String = info.get("room_name", "?")
	var playtime: float = float(info.get("playtime", 0.0))
	var pratas: int = int(info.get("player", {}).get("pratas", 0))
	var visited: int = info.get("visited", []).size()
	var total: int = maxi(info.get("rooms", {}).size(), 1)
	var pct := int(round(float(visited) / float(total) * 100.0))
	return "Slot %d  —  %s\n⏱ %s   ◇ %d Pratas   🗺 %d%% do mapa" % [
			slot + 1, region, GameState.format_playtime(playtime), pratas, pct]


func _on_slot_pressed(slot: int, has_save: bool) -> void:
	## Novo Jogo em slot ocupado: primeira clique arma a confirmação.
	if mode == Mode.MODE_NEW and has_save:
		var entry: Dictionary = _slot_buttons.get(slot, {})
		if not entry.get("armed", false):
			entry["armed"] = true
			var b: Button = entry["btn"]
			b.text = "Slot %d  —  CONFIRMAR SOBRESCREVER? (clique de novo)" % (slot + 1)
			return
	slot_selected.emit(slot, mode == Mode.MODE_NEW)
