extends Control
## ============================================================================
## [ARCANJO CAIDO] — Passo 10: Menu Principal.
## Opções: Novo Jogo, Carregar Jogo (3 Save Slots locais) e Sair.
## É a main scene do projeto. UI construída em código (placeholder visual).
## ============================================================================

const FIRST_ROOM := "res://scenes/test/arena_teste.tscn"

var _slot_panel: VBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	AudioManager.play_music("menu")

	# Fundo.
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.06)
	add_child(bg)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_preset(Control.PRESET_FULL_RECT)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "ARCANJO  CAIDO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.92, 0.87, 0.72))
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Do Céu você caiu. Em Aeterna você desperta."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.58, 0.55))
	vbox.add_child(subtitle)
	vbox.add_child(HSeparator.new())

	var btn_new := Button.new()
	btn_new.text = "NOVO JOGO"
	btn_new.custom_minimum_size = Vector2(280.0, 44.0)
	btn_new.pressed.connect(_on_new_game)
	vbox.add_child(btn_new)

	var btn_load := Button.new()
	btn_load.text = "CARREGAR JOGO"
	btn_load.custom_minimum_size = Vector2(280.0, 44.0)
	btn_load.pressed.connect(_toggle_slots)
	vbox.add_child(btn_load)

	# Painel de Save Slots (oculto até clicar em Carregar).
	_slot_panel = VBoxContainer.new()
	_slot_panel.visible = false
	vbox.add_child(_slot_panel)

	var btn_quit := Button.new()
	btn_quit.text = "SAIR"
	btn_quit.custom_minimum_size = Vector2(280.0, 44.0)
	btn_quit.pressed.connect(func(): get_tree().quit())
	vbox.add_child(btn_quit)

	var hint := Label.new()
	hint.text = "Esc in-game: pausa (Sigilos, Mapa, Conquistas, Opções)"
	hint.add_theme_color_override("font_color", Color(0.45, 0.43, 0.42))
	hint.add_theme_font_size_override("font_size", 14)
	vbox.add_child(hint)


func _on_new_game() -> void:
	GameState.restore_defaults()
	SceneTransition.change_room(FIRST_ROOM, "")


func _toggle_slots() -> void:
	for child in _slot_panel.get_children():
		child.queue_free()
	_slot_panel.visible = not _slot_panel.visible
	if not _slot_panel.visible:
		return

	_add_slot_label("— SAVE SLOTS LOCAIS —")
	for slot in SaveManager.SLOT_COUNT:
		var info := SaveManager.get_slot_info(slot)
		var text := "Slot %d — vazio" % (slot + 1)
		if not info.is_empty():
			var pratas: int = int(info.get("player", {}).get("pratas", 0))
			text = "Slot %d — %s — ◇ %d" % [slot + 1, info.get("room_name", "?"), pratas]
		var btn := Button.new()
		btn.text = text
		btn.disabled = not SaveManager.has_slot(slot)
		var captured := slot
		btn.pressed.connect(func(): SaveManager.load_slot(captured))
		_slot_panel.add_child(btn)

	var btn_back := Button.new()
	btn_back.text = "Voltar"
	btn_back.pressed.connect(_toggle_slots)
	_slot_panel.add_child(btn_back)


func _add_slot_label(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.7, 0.68, 0.6))
	_slot_panel.add_child(label)
