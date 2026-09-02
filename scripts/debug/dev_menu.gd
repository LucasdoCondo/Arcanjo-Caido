extends CanvasLayer
## ============================================================================
## [ARCANJO CAIDO] — Passo 23: Dev Menu / Console de Desenvolvedor.
## ----------------------------------------------------------------------------
## FERRAMENTA DE QA — disponível APENAS em builds de debug.
## ----------------------------------------------------------------------------
## ISOLAMENTO PARA A BUILD FINAL (equivalente ao "#if DEBUG"):
##   1. Este autoload verifica OS.is_debug_build() no _ready: em builds de
##      lançamento (export com debug desligado) ele se autodestrói e o
##      overlay nunca aparece.
##   2. Dupla proteção: no export_presets.cfg adicione o filtro de exclusão
##      "scripts/debug/*" em "Filters to exclude files from project"
##      (o script sai do pacote por completo).
##   3. O jogo em si NUNCA referencia o autoload DevMenu diretamente — a
##      integração é via flag god_mode no player_controller.gd (var comum,
##      sempre presente e false no lançamento).
## ----------------------------------------------------------------------------
## ATALHOS:
##   F1  — abre/fecha o painel de debug
##   F2  — alterna God Mode rapidamente
##   F3  — +1000 Pratas de Judas
##   F4  — encher a Chama Negra
## ============================================================================

## Regiões de Aeterna para teleporte (Passo 23.1). As cenas das regiões que
## ainda não existem ficam desabilitadas; mapeie aqui conforme o mundo cresce.
const REGIONS := [
	{"id": "cripta_estrelas", "name": "Cripta das Estrelas Caídas",
			"scene": "res://scenes/test/arena_teste.tscn"},
	{"id": "corredor_cinzas", "name": "Corredor Cinzas",
			"scene": "res://scenes/test/sala_teste_02.tscn"},
	{"id": "jardim_adonai", "name": "Jardim de Adonai-Gal",
			"scene": "res://scenes/biomas/jardim_adonai.tscn"},
	{"id": "mar_de_vidro", "name": "Mar de Vidro",
			"scene": "res://scenes/biomas/mar_de_vidro.tscn"},
	{"id": "catedral_avareza", "name": "Catedral da Avareza (Mammon)",
			"scene": "res://scenes/bosses/arena_mammon.tscn"},
]

const ALL_SIGILS := ["lamina_longa", "coracao_extra", "chama_rapida",
		"azazel_blade", "selo_serpente", "marca_mammon"]

const COL_TITLE := Color(0.95, 0.5, 0.25)
const COL_TEXT := Color(0.85, 0.9, 0.85)

var _panel: PanelContainer
var _god_label: Button
var _perf_label: Label      ## Overlay discreto de desempenho (canto)
var _perf_visible: bool = true


func _ready() -> void:
	## --- ISOLAMENTO DE BUILD: fora de builds de debug, nem existe. ---
	if not OS.is_debug_build():
		queue_free()
		return

	layer = 99
	process_mode = Node.PROCESS_MODE_ALWAYS  ## Funciona com o jogo pausado
	_build_perf_overlay()
	_build_panel()


# ---------------------------------------------------------------------------
# OVERLAY DE DESEMPENHO (Passo 23.3)
# ---------------------------------------------------------------------------
func _build_perf_overlay() -> void:
	_perf_label = Label.new()
	_perf_label.position = Vector2(10.0, 6.0)
	_perf_label.add_theme_font_size_override("font_size", 12)
	_perf_label.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7, 0.75))
	add_child(_perf_label)


func _process(_delta: float) -> void:
	if _perf_label == null:
		return
	if not _perf_visible:
		_perf_label.text = ""
		return


# ---------------------------------------------------------------------------
# PAINEL DE DEBUG (Passo 23.1 / 23.2)
# ---------------------------------------------------------------------------
func _build_panel() -> void:
	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.05, 0.94)
	style.border_color = Color(0.95, 0.5, 0.25, 0.7)
	style.set_border_width_all(2)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	_panel.visible = false
	_panel.position = Vector2(60.0, 60.0)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_panel.add_child(vbox)

	_title_label(vbox, "DEV MENU — FERRAMENTAS DE QA")
	_god_label = _add_row_button(vbox, "God Mode: DESLIGADO (F2)", _toggle_god)
	_add_row_button(vbox, "+1000 Pratas de Judas (F3)", _add_pratas)
	_add_row_button(vbox, "Encher Chama Negra (F4)", _fill_chama)
	_add_row_button(vbox, "Vida Cheia", _fill_health)

	_title_label(vbox, "TELEPORTE — REGIÕES DE AETERNA")
	for region in REGIONS:
		var captured: Dictionary = region
		_add_row_button(vbox, "→ %s" % region["name"],
				func(): _teleport(captured["scene"]))

	_title_label(vbox, "HABILIDADES DE MOVIMENTAÇÃO")
	for id in GameState.abilities:
		var captured: String = id
		_add_row_button(vbox, "Toggle: %s" % id,
				func(): _toggle_ability(captured))
	_add_row_button(vbox, "Liberar TODAS", _unlock_all_abilities)

	_title_label(vbox, "SIGILOS DO BANIMENTO")
	_add_row_button(vbox, "Conceder e Equipar TODOS", _grant_all_sigils)
	for id in ALL_SIGILS:
		var captured: String = id
		_add_row_button(vbox, "Toggle Sigilo: %s" % id,
				func(): _toggle_sigil(captured))

	_title_label(vbox, "OUTROS")
	_add_row_button(vbox, "Overlay de desempenho: LIGADO",
			func(): _toggle_perf_overlay())


func _title_label(parent: Control, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", COL_TITLE)
	label.add_theme_font_size_override("font_size", 15)
	parent.add_child(label)


func _add_row_button(parent: Control, text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.pressed.connect(callback)
	parent.add_child(btn)
	return btn


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F1:
				_toggle_panel()
				get_viewport().set_input_as_handled()
			KEY_F2:
				_toggle_god()
			KEY_F3:
				_add_pratas()
			KEY_F4:
				_fill_chama()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_QUOTELEFT:
		_toggle_panel()  ## Tecla ~ alternativa


func _toggle_panel() -> void:
	_panel.visible = not _panel.visible
	## O painel consome cliques (não deixa passar para o jogo).
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP if _panel.visible else Control.MOUSE_FILTER_IGNORE


# ---------------------------------------------------------------------------
# COMANDOS DE CHECAGEM (Passo 23.1)
# ---------------------------------------------------------------------------
func _player() -> Node:
	return get_tree().get_first_node_in_group("player")


func _toggle_god() -> void:
	var p := _player()
	if p == null:
		return
	p.god_mode = not p.god_mode
	_god_label.text = "God Mode: %s (F2)" % ("LIGADO ✔" if p.god_mode else "DESLIGADO")
	print("[DEV] God Mode = ", p.god_mode)


func _add_pratas() -> void:
	var p := _player()
	if p == null:
		return
	p.pratas_de_judas += 1000
	p.pratas_changed.emit(p.pratas_de_judas)
	print("[DEV] +1000 Pratas de Judas")


func _fill_chama() -> void:
	var p := _player()
	if p == null:
		return
	p.chama_negra = p.chama_max
	p.chama_changed.emit(p.chama_negra, p.chama_max)
	print("[DEV] Chama Negra cheia")


func _fill_health() -> void:
	var p := _player()
	if p == null:
		return
	p.heal(p.max_health)


func _teleport(scene_path: String) -> void:
	## Teleporta Lúcifer para o spawn da região escolhida (com fade).
	_panel.visible = false
	SceneTransition.change_room(scene_path, "")


# ---------------------------------------------------------------------------
# SELETOR DE HABILIDADES E SIGILOS (Passo 23.2)
# ---------------------------------------------------------------------------
func _toggle_ability(id: String) -> void:
	GameState.abilities[id] = not GameState.abilities[id]
	print("[DEV] Habilidade %s = %s" % [id, GameState.abilities[id]])


func _unlock_all_abilities() -> void:
	for id in GameState.abilities:
		GameState.abilities[id] = true
	print("[DEV] Todas as habilidades liberadas")


func _grant_all_sigils() -> void:
	for id in ALL_SIGILS:
		GameState.grant_sigil(id)
		if not GameState.sigils_equipped.has(id) and GameState.sigils_equipped.size() < GameState.MAX_SIGILS:
			GameState.sigils_equipped.append(id)
	var p := _player()
	if p and p.has_method("apply_sigils"):
		p.apply_sigils()
	print("[DEV] Todos os Sigilos concedidos")


func _toggle_sigil(id: String) -> void:
	if not GameState.sigils_owned.has(id):
		GameState.grant_sigil(id)
	GameState.toggle_sigil(id)
	var p := _player()
	if p and p.has_method("apply_sigils"):
		p.apply_sigils()
	print("[DEV] Sigilo %s alternado" % id)


func _toggle_perf_overlay() -> void:
	_perf_visible = not _perf_visible
	print("[DEV] Overlay de desempenho = ", _perf_visible)

	## FPS, RAM, nós ativos e tempo de carregamento de frame.
	var fps := Engine.get_frames_per_second()
	var ram_mb := OS.get_static_memory_usage() / 1048576.0
	var nodes := get_tree().get_node_count()
	var frame_ms := (Performance.get_monitor(Performance.TIME_PROCESS)
			+ Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)) * 1000.0
	var draw_calls := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	_perf_label.text = "FPS %d | RAM %.1f MB | Nós %d | Frame %.2f ms | Draw %d" % [
			fps, ram_mb, nodes, frame_ms, draw_calls]
