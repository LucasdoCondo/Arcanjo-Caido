class_name SettingsPanel
extends VBoxContainer
## ============================================================================
## [ARCANJO CAIDO] — Passo 22: Painel de Opções REUTILIZÁVEL.
## ----------------------------------------------------------------------------
## Módulo de interface com as configurações do jogo, embutível em qualquer
## tela: Menu Principal (aba Opções) e Menu de Pausa (aba Opções).
##   - ÁUDIO: sliders dos barramentos BGM / SFX / AMB (AudioManager)
##   - TELA: fullscreen, sem bordas, resolução e V-Sync (DisplayManager)
##   - CONTROLES: remapeamento de teclado/controle (InputRemap)
## Persistência 100% offline: user://settings.json e user://input_map.json.
## ============================================================================

signal back_requested  ## Emitido quando o usuário clica em "Voltar".

const COL_TEXT := Color(0.92, 0.89, 0.8)
const COL_DIM := Color(0.6, 0.58, 0.55)

## Estado do rebind em andamento (ação aguardando nova tecla/botão).
var _pending_rebind: String = ""
var _rebind_buttons: Dictionary = {}  ## action -> Button (rótulo dinâmico)


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	_build_audio()
	add_child(HSeparator.new())
	_build_screen()
	add_child(HSeparator.new())
	_build_controls()


# ---------------------------------------------------------------------------
# ÁUDIO — barramentos do AudioManager (Passo 19)
# ---------------------------------------------------------------------------
func _build_audio() -> void:
	_add_label("ÁUDIO")
	_add_slider("Música (BGM)", "Music")
	_add_slider("Efeitos (SFX)", "SFX")
	_add_slider("Ambiente", "Ambience")


# ---------------------------------------------------------------------------
# TELA — DisplayManager (Passo 21)
# ---------------------------------------------------------------------------
func _build_screen() -> void:
	_add_label("TELA (configurações salvas em user://settings.json)")
	var btn_full := Button.new()
	btn_full.text = "Alternar Tela Cheia (F11)"
	btn_full.pressed.connect(func(): DisplayManager.toggle_fullscreen())
	add_child(btn_full)
	var btn_borderless := Button.new()
	btn_borderless.text = "Alternar Janela sem Bordas"
	btn_borderless.pressed.connect(func():
		DisplayManager.set_borderless(not DisplayManager.settings["borderless"]))
	add_child(btn_borderless)
	for i in DisplayManager.RESOLUTIONS.size():
		var res: Vector2i = DisplayManager.RESOLUTIONS[i]
		var btn_res := Button.new()
		btn_res.text = "Resolução: %d x %d" % [res.x, res.y]
		var captured: int = i
		btn_res.pressed.connect(func(): DisplayManager.set_resolution(captured))
		add_child(btn_res)
	var btn_vsync := Button.new()
	btn_vsync.text = "V-Sync: %s" % ("Ligado" if DisplayManager.settings["vsync"] else "Desligado")
	btn_vsync.pressed.connect(func():
		DisplayManager.set_vsync(not DisplayManager.settings["vsync"])
		btn_vsync.text = "V-Sync: %s" % ("Ligado" if DisplayManager.settings["vsync"] else "Desligado"))
	add_child(btn_vsync)


# ---------------------------------------------------------------------------
# CONTROLES — InputRemap (Passo 21)
# ---------------------------------------------------------------------------
func _build_controls() -> void:
	_add_label("CONTROLES (clique no botão para remapear)")
	_refresh_rebind_rows()
	var btn_reset := Button.new()
	btn_reset.text = "Restaurar Controles Padrão"
	btn_reset.pressed.connect(func():
		InputRemap.reset_all()
		_refresh_rebind_rows())
	add_child(btn_reset)
	var btn_back := Button.new()
	btn_back.text = "Voltar"
	btn_back.pressed.connect(func(): back_requested.emit())
	add_child(btn_back)


func _refresh_rebind_rows() -> void:
	_rebind_buttons.clear()
	for child in get_children():
		if child is Button and child.has_meta("rebind_action"):
			child.queue_free()
	for entry in InputRemap.ACTIONS:
		var action: String = entry["action"]
		var btn := Button.new()
		btn.text = "%s  —  %s" % [entry["label"], InputRemap.get_bind_text(action)]
		btn.set_meta("rebind_action", action)
		btn.toggle_mode = true
		var captured: String = action
		btn.pressed.connect(func(): _start_rebind(captured))
		add_child(btn)
		_rebind_buttons[action] = btn


func _start_rebind(action: String) -> void:
	## Cancela rebind anterior (se houver) e aguarda a próxima tecla.
	if _pending_rebind != "" and _rebind_buttons.has(_pending_rebind):
		var prev: Button = _rebind_buttons[_pending_rebind]
		prev.button_pressed = false
		prev.text = "%s  —  %s" % [_action_label(_pending_rebind),
				InputRemap.get_bind_text(_pending_rebind)]
	_pending_rebind = action
	if _rebind_buttons.has(action):
		var b: Button = _rebind_buttons[action]
		b.button_pressed = true
		b.text = "%s  —  pressione uma tecla..." % _action_label(action)


func _input(event: InputEvent) -> void:
	if _pending_rebind == "":
		return
	## Consome a próxima tecla/botão e aplica no InputMap (+ user://).
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_cancel_rebind()
		elif InputRemap.rebind_action(_pending_rebind, event):
			_finish_rebind()
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.pressed:
		if InputRemap.rebind_action(_pending_rebind, event):
			_finish_rebind()
		get_viewport().set_input_as_handled()


func _finish_rebind() -> void:
	if _rebind_buttons.has(_pending_rebind):
		var b: Button = _rebind_buttons[_pending_rebind]
		b.button_pressed = false
		b.text = "%s  —  %s" % [_action_label(_pending_rebind),
				InputRemap.get_bind_text(_pending_rebind)]
	_pending_rebind = ""


func _cancel_rebind() -> void:
	if _rebind_buttons.has(_pending_rebind):
		var b: Button = _rebind_buttons[_pending_rebind]
		b.button_pressed = false
		b.text = "%s  —  %s" % [_action_label(_pending_rebind),
				InputRemap.get_bind_text(_pending_rebind)]
	_pending_rebind = ""


func _action_label(action: String) -> String:
	for entry in InputRemap.ACTIONS:
		if entry["action"] == action:
			return entry["label"]
	return action


# ---------------------------------------------------------------------------
# Helpers de UI
# ---------------------------------------------------------------------------
func _add_label(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", COL_TEXT)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(label)


func _add_slider(label_text: String, bus_name: String) -> void:
	var row := HBoxContainer.new()
	add_child(row)
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
