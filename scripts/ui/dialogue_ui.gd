extends CanvasLayer
## ============================================================================
## [ARCANJO CAIDO] — Autoload: DialogueUI (Passo 5)
## ----------------------------------------------------------------------------
## Sistema de diálogos estilo Hollow Knight:
##   - Falas em JSON externo (res://data/dialogs.json) com nós ramificados
##   - Typewriter effect; Enter/E/Espaço avança ou revela tudo
##   - Escolhas do jogador (botões clicáveis)
##   - Pausa o jogo enquanto ativo (bloqueia o Lúcifer)
##   - "Effects" executam ações: flags de quest, compras de loja, conquistas
##     (uma compra sem saldo redireciona para o nó "sem_pratas")
## ============================================================================

const DIALOGS_PATH := "res://data/dialogs.json"
const CHARS_PER_SEC := 45.0

var active: bool = false
var _dialogs: Dictionary = {}
var _npc_id: String = ""
var _node_id: String = ""
var _full_text: String = ""
var _shown_chars: float = 0.0
var _awaiting_choice: bool = false

var _panel: PanelContainer
var _speaker: Label
var _text: Label
var _choices: VBoxContainer


func _ready() -> void:
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()
	_load_dialogs()


func _build_ui() -> void:
	var anchor := Control.new()
	add_child(anchor)
	anchor.set_anchors_preset(Control.PRESET_FULL_RECT)
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_panel = PanelContainer.new()
	anchor.add_child(_panel)
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = 200.0
	_panel.offset_right = -200.0
	_panel.offset_top = -250.0
	_panel.offset_bottom = -30.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08, 0.96)
	style.border_color = Color(0.83, 0.69, 0.22, 0.7)
	style.set_border_width_all(2)
	_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_panel.add_child(vbox)

	_speaker = Label.new()
	_speaker.add_theme_font_size_override("font_size", 20)
	_speaker.add_theme_color_override("font_color", Color(0.83, 0.69, 0.22))
	vbox.add_child(_speaker)

	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_size_override("font_size", 19)
	_text.add_theme_color_override("font_color", Color(0.92, 0.89, 0.8))
	_text.custom_minimum_size = Vector2(0.0, 90.0)
	vbox.add_child(_text)

	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 4)
	vbox.add_child(_choices)


func _load_dialogs() -> void:
	if not FileAccess.file_exists(DIALOGS_PATH):
		push_warning("Dialogos não encontrados: " + DIALOGS_PATH)
		return
	var f := FileAccess.open(DIALOGS_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		_dialogs = parsed


## Inicia o diálogo de um NPC (nó inicial configurável pelo NPC).
func start_dialogue(npc_id: String, node_id: String = "start") -> void:
	if active or not _dialogs.has(npc_id):
		return
	active = true
	visible = true
	get_tree().paused = true
	_npc_id = npc_id
	_show_node(node_id)


# ===========================================================================
# FLUXO DE NÓS
# ===========================================================================
func _show_node(node_id: String) -> void:
	var tree: Dictionary = _dialogs.get(_npc_id, {})
	if not tree.has(node_id):
		_end_dialogue()
		return
	_node_id = node_id
	var node: Dictionary = tree[node_id]

	_speaker.text = node.get("speaker", _npc_id.capitalize())
	_full_text = node.get("text", "")
	_shown_chars = 0.0
	_text.visible_characters = 0
	_awaiting_choice = false
	_clear_choices()

	# Aplica effects do nó (flags, compras, conquistas...).
	var jump := _apply_effects(node.get("effects", []))
	if jump != "":
		_show_node(jump)
		return


func _finish_node() -> void:
	## Texto completo revelado: mostra escolhas ou avança.
	var node: Dictionary = _dialogs.get(_npc_id, {}).get(_node_id, {})
	var choices: Array = _filtered_choices(node.get("choices", []))

	if not choices.is_empty():
		_awaiting_choice = true
		for choice in choices:
			var btn := Button.new()
			btn.text = choice.get("text", "...")
			btn.pressed.connect(_on_choice.bind(choice))
			_choices.add_child(btn)
	elif node.has("next") and node["next"] != "_END":
		_show_node(node["next"])
	else:
		_end_dialogue()


func _filtered_choices(choices: Array) -> Array:
	## Escolhas podem aparecer condicionais: "show_if_flag", "hide_if_flag".
	var result: Array = []
	for choice in choices:
		if choice.has("show_if_flag") and not GameState.flags.get(choice["show_if_flag"], false):
			continue
		if choice.has("hide_if_flag") and GameState.flags.get(choice["hide_if_flag"], false):
			continue
		result.append(choice)
	return result


func _on_choice(choice: Dictionary) -> void:
	_clear_choices()
	_awaiting_choice = false
	# Efeitos da escolha podem redirecionar (ex: compra sem saldo).
	var jump := _apply_effects(choice.get("effects", []))
	var next: String = jump if jump != "" else choice.get("next", "_END")
	if next == "_END":
		_end_dialogue()
	else:
		_show_node(next)


func _end_dialogue() -> void:
	active = false
	visible = false
	get_tree().paused = false
	_clear_choices()


func _clear_choices() -> void:
	for child in _choices.get_children():
		child.queue_free()

# ===========================================================================
# TYPEWRITER + INPUT
# ===========================================================================
func _process(delta: float) -> void:
	if not active:
		return
	if _shown_chars < _full_text.length():
		_shown_chars = minf(_shown_chars + CHARS_PER_SEC * delta, _full_text.length())
		_text.visible_characters = int(_shown_chars)


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	var advance: bool = event.is_action_pressed("interact") \
			or event.is_action_pressed("jump") \
			or (event is InputEventKey and (event as InputEventKey).pressed \
					and (event as InputEventKey).physical_keycode == KEY_ENTER)

	if not advance:
		return
	get_viewport().set_input_as_handled()

	if _awaiting_choice:
		return  ## Aguardando escolha: use o mouse nos botões

	if _shown_chars < _full_text.length():
		_shown_chars = _full_text.length()  ## Revela tudo de uma vez
		_text.visible_characters = -1
		return

	_finish_node()


# ===========================================================================
# EFEITOS (flags de quest, lojas, conquistas)
# Retorna um node_id para redirecionar o fluxo (ex: compra sem saldo).
# ===========================================================================
func _apply_effects(effects: Array) -> String:
	var player = get_tree().get_first_node_in_group("player")
	for effect in effects:
		var parts: PackedStringArray = String(effect).split(":")
		match parts[0]:
			"flag":
				if parts.size() > 1:
					GameState.flags[parts[1]] = true
			"unlock_ach":
				if parts.size() > 1:
					Achievements.unlock(parts[1])
			"buy_map":
				## Cassandra: compra do Mapa de Aeterna.
				if player and player.spend_pratas(30):
					GameState.purchase_cassandra_map()
					GameState.flags["cassandra_map_bought"] = true
				else:
					return "sem_pratas"
			"buy_sigil":
				## Mormo: buy_sigil:<id>:<custo>
				if parts.size() < 3:
					continue
				if GameState.sigils_owned.has(parts[1]):
					return "ja_tem"
				if player and player.spend_pratas(int(parts[2])):
					GameState.grant_sigil(parts[1])
					if player.has_method("apply_sigils"):
						player.apply_sigils()
					Achievements.unlock("sigils_master") if _all_sigils() else null
				else:
					return "sem_pratas"
			"buy_heal":
				## Mormo: buy_heal:<custo>:<cura>
				if parts.size() < 3:
					continue
				if player and player.spend_pratas(int(parts[1])):
					player.heal(int(parts[2]))
				else:
					return "sem_pratas"
	return ""


func _all_sigils() -> bool:
	for id in ["lamina_longa", "coracao_extra", "chama_rapida",
			"azazel_blade", "selo_serpente", "marca_mammon"]:
		if not GameState.sigils_owned.has(id):
			return false
	return true
