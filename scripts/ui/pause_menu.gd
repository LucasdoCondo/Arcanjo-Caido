extends CanvasLayer
## ============================================================================
## [ARCANJO CAIDO] — Autoload: PauseMenu (Passo 10)
## ----------------------------------------------------------------------------
## Menu de pause (tecla Esc/P) com 4 abas:
##   Sigilos (inventário/habilidades) | Mapa | Conquistas | Opções (áudio/controles)
## Construído em código; processa com o jogo pausado.
## ============================================================================

const COL_TEXT := Color(0.92, 0.89, 0.8)
const COL_DIM := Color(0.6, 0.58, 0.55)

var _open: bool = false
var _tabs: TabContainer
var _sigilos_box: VBoxContainer
var _achievements_box: VBoxContainer


func _ready() -> void:
	layer = 85
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.6)
	add_child(dim)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	center.add_child(panel)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.06, 0.1, 0.97)
	style.border_color = Color(0.83, 0.69, 0.22, 0.6)
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "PAUSA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", COL_TEXT)
	vbox.add_child(title)

	_tabs = TabContainer.new()
	_tabs.custom_minimum_size = Vector2(600.0, 440.0)
	vbox.add_child(_tabs)

	# --- Aba 1: Sigilos (inventário) ---
	_sigilos_box = VBoxContainer.new()
	_sigilos_box.name = "Sigilos"
	_tabs.add_child(_sigilos_box)

	# --- Aba 2: Mapa ---
	var mapa := VBoxContainer.new()
	mapa.name = "Mapa"
	_tabs.add_child(mapa)
	_add_label(mapa, "O mapa completo de Aeterna é desenhado conforme você explora\n(fog of war). Salas compradas da Cassandra aparecem como contorno.")
	_add_label(mapa, "Marcadores pessoais: abra o mapa (M) e pressione E na sala atual.")
	var btn_map := Button.new()
	btn_map.text = "Abrir Mapa de Aeterna"
	btn_map.pressed.connect(_open_map)
	mapa.add_child(btn_map)

	# --- Aba 3: Conquistas ---
	_achievements_box = VBoxContainer.new()
	_achievements_box.name = "Conquistas"
	_tabs.add_child(_achievements_box)

	# --- Aba 4: Opções ---
	var opts := VBoxContainer.new()
	opts.name = "Opções"
	_tabs.add_child(opts)
	_add_label(opts, "ÁUDIO")
	_add_slider(opts, "Música (BGM)", "Music")
	_add_slider(opts, "Efeitos (SFX)", "SFX")
	_add_slider(opts, "Ambiente", "Ambience")
	opts.add_child(HSeparator.new())
	_add_label(opts, "SALVAR JOGO (3 slots locais)")
	for slot in SaveManager.SLOT_COUNT:
		var btn_save := Button.new()
		btn_save.text = "Salvar no Slot %d" % (slot + 1)
		var captured: int = slot
		btn_save.pressed.connect(func(): SaveManager.save_slot(captured))
		opts.add_child(btn_save)
	opts.add_child(HSeparator.new())
	_add_label(opts, "TELA (configurações salvas em user://settings.json)")
	var btn_full := Button.new()
	btn_full.text = "Alternar Tela Cheia (F11)"
	btn_full.pressed.connect(func(): DisplayManager.toggle_fullscreen())
	opts.add_child(btn_full)
	var btn_borderless := Button.new()
	btn_borderless.text = "Alternar Janela sem Bordas"
	btn_borderless.pressed.connect(func():
		DisplayManager.set_borderless(not DisplayManager.settings["borderless"]))
	opts.add_child(btn_borderless)
	for i in DisplayManager.RESOLUTIONS.size():
		var res: Vector2i = DisplayManager.RESOLUTIONS[i]
		var btn_res := Button.new()
		btn_res.text = "Resolução: %d x %d" % [res.x, res.y]
		var captured: int = i
		btn_res.pressed.connect(func(): DisplayManager.set_resolution(captured))
		opts.add_child(btn_res)
	opts.add_child(HSeparator.new())
	_add_label(opts, "CONTROLES")
	for line in [
		"A/D ou ←/→: mover     Espaço/Z: pular (2x com Asas Caídas)",
		"Shift/X: Dash de Sombra     S+Shift no ar: Macho de Ferro",
		"J: Lâmina do Alvorecer     C: Sombra de Voo (gancho)",
		"F (segurar): Cura canalizada     E: interagir     M: mapa     Esc: pausa",
	]:
		_add_label(opts, line)


func _add_label(parent: Control, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", COL_TEXT)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)


func _add_slider(parent: Control, label_text: String, bus_name: String) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(180.0, 0.0)
	label.add_theme_color_override("font_color", COL_TEXT)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = AudioManager.get_bus_volume(bus_name)
	slider.custom_minimum_size = Vector2(240.0, 20.0)
	row.add_child(slider)
	slider.value_changed.connect(func(v): AudioManager.set_bus_volume(bus_name, v))


func _unhandled_input(event: InputEvent) -> void:
	if DialogueUI.active:
		return  ## Diálogo em andamento tem prioridade
	if not event.is_action_pressed("pause"):
		return
	## Só pausa durante o jogo (com Lúcifer em cena).
	if not _open and get_tree().get_first_node_in_group("player") == null:
		return
	_toggle()
	get_viewport().set_input_as_handled()


func _toggle() -> void:
	_open = not _open
	visible = _open
	get_tree().paused = _open
	if _open:
		_refresh_sigilos()
		_refresh_achievements()


func _refresh_sigilos() -> void:
	for child in _sigilos_box.get_children():
		child.queue_free()
	_add_label(_sigilos_box, "HABILIDADES DE EXPLORAÇÃO")
	for id in GameState.abilities:
		var state_text := "✔ Desbloqueada" if GameState.abilities[id] else "🔒 Selada"
		var label := Label.new()
		label.text = "• %s — %s" % [id.capitalize(), state_text]
		label.add_theme_color_override("font_color",
				COL_TEXT if GameState.abilities[id] else COL_DIM)
		_sigilos_box.add_child(label)

	# --- Passo 6: Sigilos do Banimento (equipáveis) ---
	_sigilos_box.add_child(HSeparator.new())
	_add_label(_sigilos_box, "SIGILOS DO BANIMENTO (%d/%d equipados)" %
			[GameState.sigils_equipped.size(), GameState.MAX_SIGILS])

	if GameState.sigils_owned.is_empty():
		_add_label(_sigilos_box, "Nenhum Sigilo coletado... Mormo, o Encantador, vende alguns.")

	for id in GameState.sigils_owned:
		var equipped: bool = GameState.sigils_equipped.has(id)
		var row := HBoxContainer.new()
		_sigilos_box.add_child(row)
		var label := Label.new()
		label.text = "• %s" % _sigil_display_name(id)
		label.add_theme_color_override("font_color", COL_TEXT)
		label.custom_minimum_size = Vector2(300.0, 0.0)
		row.add_child(label)
		var btn := Button.new()
		btn.text = "Remover" if equipped else "Equipar"
		var captured: String = id
		btn.pressed.connect(func():
			GameState.toggle_sigil(captured)
			var p = get_tree().get_first_node_in_group("player")
			if p and p.has_method("apply_sigils"):
				p.apply_sigils()
			_refresh_sigilos())
		row.add_child(btn)


func _sigil_display_name(id: String) -> String:
	match id:
		"lamina_longa":
			return "Sigilo da Lâmina Longa (alcance +35%)"
		"coracao_extra":
			return "Sigilo do Coração Extra (+1 de vida)"
		"chama_rapida":
			return "Sigilo da Chama Rápida (Chama +40% por golpe)"
		"azazel_blade":
			return "Sigilo de Azazel (alcance +25%, drena vida por golpe)"
		"selo_serpente":
			return "Selo da Serpente (o Dash corrói inimigos)"
		"marca_mammon":
			return "Marca de Mammon (+50% Pratas, dano dobrado em você)"
		_:
			return id.capitalize()


func _refresh_achievements() -> void:
	for child in _achievements_box.get_children():
		child.queue_free()
	for def in Achievements.DEFS:
		var done: bool = Achievements.is_unlocked(def.id)
		var label := Label.new()
		label.text = ("%s  %s\n      %s" %
				["🏆" if done else "🔒", def.name, def.desc])
		label.add_theme_color_override("font_color", COL_TEXT if done else COL_DIM)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_achievements_box.add_child(label)


func _open_map() -> void:
	## Fecha o pause e abre o mapa de Aeterna.
	if _open:
		_toggle()
	if MapOverlay.has_method("open_map"):
		MapOverlay.open_map()
