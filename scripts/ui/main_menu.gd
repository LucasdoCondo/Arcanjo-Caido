extends Control
## ============================================================================
## [ARCANJO CAIDO] — Passo 22: Menu Principal completo.
## ----------------------------------------------------------------------------
## Tela de título com fundo animado (Parallax de silhuetas de Aeterna +
## partículas de brasas da Chama Negra) e trilha sonora em loop.
## Opções: NOVO JOGO | CONTINUAR / CARREGAR (3 Save Slots) | OPÇÕES |
##         CONQUISTAS | SAIR
## UI construída em código; é a main scene do projeto (menu_principal.tscn).
## ============================================================================

const FIRST_ROOM := "res://scenes/test/arena_teste.tscn"

## Módulos de UI do Passo 22 via preload (robusto mesmo sem o cache de
## class_name do editor — importante para boot headless e clones novos).
const SettingsPanelScript := preload("res://scripts/ui/settings_panel.gd")
const SaveSlotSelectorScript := preload("res://scripts/ui/save_slot_selector.gd")

## Camadas do parallax: velocidade (px/s) e cor da silhueta (fundo → frente).
const PARALLAX_LAYERS := [
	{"speed": 6.0, "color": Color(0.09, 0.09, 0.14), "height": 220.0, "rough": 0.55},
	{"speed": 14.0, "color": Color(0.06, 0.06, 0.10), "height": 160.0, "rough": 0.75},
	{"speed": 26.0, "color": Color(0.03, 0.03, 0.05), "height": 110.0, "rough": 0.95},
]

var _parallax_root: Node2D
var _layer_offsets: Array = [0.0, 0.0, 0.0]
var _layer_widths: Array = [0.0, 0.0, 0.0]
var _title_label: Label
var _menu_box: VBoxContainer
var _panel_box: VBoxContainer          ## Painéis deslizantes (slots/opções/etc.)
var _settings                     ## Instância do SettingsPanel (preload)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	AudioManager.play_music("menu")
	_bootstrap_dev_menu()

	# --- Fundo base ---
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.06)
	add_child(bg)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)

	_build_parallax()
	_build_ember_particles()

	# --- UI ---
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_preset(Control.PRESET_FULL_RECT)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	center.add_child(vbox)

	_title_label = Label.new()
	_title_label.text = "ARCANJO  CAIDO"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 64)
	_title_label.add_theme_color_override("font_color", Color(0.92, 0.87, 0.72))
	vbox.add_child(_title_label)

	var subtitle := Label.new()
	subtitle.text = "Do Céu você caiu. Em Aeterna você desperta."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.58, 0.55))
	vbox.add_child(subtitle)
	vbox.add_child(HSeparator.new())

	# --- Botões principais (Passo 22.1) ---
	_menu_box = VBoxContainer.new()
	_menu_box.add_theme_constant_override("separation", 10)
	vbox.add_child(_menu_box)
	_add_menu_button("NOVO JOGO", _on_new_game)
	_add_menu_button("CONTINUAR / CARREGAR JOGO", _on_load_game)
	_add_menu_button("OPÇÕES", _on_options)
	_add_menu_button("CONQUISTAS", _on_achievements)
	_add_menu_button("SAIR", func(): get_tree().quit())

	# --- Painel deslizante (slots / opções / conquistas) ---
	_panel_box = VBoxContainer.new()
	_panel_box.visible = false
	vbox.add_child(_panel_box)

	var hint := Label.new()
	hint.text = "Esc in-game: pausa (Sigilos, Mapa, Conquistas, Opções)"
	hint.add_theme_color_override("font_color", Color(0.45, 0.43, 0.42))
	hint.add_theme_font_size_override("font_size", 14)
	vbox.add_child(hint)



func _process(delta: float) -> void:
	## Parallax horizontal contínuo (deriva lenta das ruínas de Aeterna).
	for i in PARALLAX_LAYERS.size():
		_layer_offsets[i] = fposmod(_layer_offsets[i] +
				PARALLAX_LAYERS[i]["speed"] * delta, _layer_widths[i])
		if i < _parallax_root.get_child_count():
			var layer := _parallax_root.get_child(i) as Node2D
			layer.position.x = -_layer_offsets[i]

	## Pulso da chama no título (brasa viva).
	if _title_label != null:
		var t := Time.get_ticks_msec() / 1000.0
		_title_label.modulate = Color(1, 1, 1, 0.85 + 0.15 * sin(t * 2.0))


# ---------------------------------------------------------------------------
# FUNDO ANIMADO: parallax procedural + partículas da Chama Negra
# ---------------------------------------------------------------------------
func _build_parallax() -> void:
	## Silhuetas de ruínas/torres geradas proceduralmente (seed fixa),
	## movendo em velocidades diferentes = paralaxe de profundidade.
	_parallax_root = Node2D.new()
	add_child(_parallax_root)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20240210  ## Silhueta estável entre execuções
	for i in PARALLAX_LAYERS.size():
		var cfg: Dictionary = PARALLAX_LAYERS[i]
		var layer := Node2D.new()
		_parallax_root.add_child(layer)
		var width := 960.0
		_layer_widths[i] = width
		## Duas cópias lado a lado para o loop contínuo do wrap.
		for copy in 2:
			var poly := Polygon2D.new()
			poly.color = cfg["color"]
			var points := PackedVector2Array()
			points.append(Vector2(0, 720))
			points.append(Vector2(0, 720 - cfg["height"]))
			var x := 0.0
			while x < width:
				x += rng.randf_range(50.0, 110.0)
				var h: float = cfg["height"] + rng.randf_range(
						-cfg["height"] * cfg["rough"] * 0.4,
						cfg["height"] * cfg["rough"])
				points.append(Vector2(minf(x, width), 720 - maxf(h, 30.0)))
			points.append(Vector2(width, 720))
			poly.polygon = points
			poly.position.x = copy * width
			layer.add_child(poly)


func _build_ember_particles() -> void:
	## Brasas da Chama Negra: partículas roxas subindo lentamente, morrendo
	## em brasa laranja (CPUParticles2D — leve e seguro em qualquer build).
	var embers := CPUParticles2D.new()
	embers.amount = 60
	embers.lifetime = 7.0
	embers.preprocess = 7.0
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	embers.emission_rect_extents = Vector2(640.0, 20.0)
	embers.position = Vector2(640.0, 740.0)
	embers.direction = Vector2(0.0, -1.0)
	embers.spread = 18.0
	embers.gravity = Vector2(0.0, -14.0)
	embers.initial_velocity_min = 12.0
	embers.initial_velocity_max = 42.0
	embers.scale_amount_min = 1.5
	embers.scale_amount_max = 4.0
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.5, 0.2, 0.8, 0.65))   ## Roxo do Vazio
	ramp.set_color(1, Color(0.95, 0.55, 0.15, 0.0)) ## Morre em brasa laranja
	embers.color_ramp = ramp
	add_child(embers)


# ---------------------------------------------------------------------------
# NAVEGAÇÃO DO MENU (Passo 22.1 / 22.2)
# ---------------------------------------------------------------------------
func _add_menu_button(text: String, callback: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(280.0, 44.0)
	btn.pressed.connect(callback)
	_menu_box.add_child(btn)


# ---------------------------------------------------------------------------
# PASSO 24: BOOTSTRAP DO DEV MENU (só em builds de debug)
# ---------------------------------------------------------------------------
func _bootstrap_dev_menu() -> void:
	## O DevMenu NÃO é autoload (Passo 24): é anexado à raiz da árvore apenas
	## em builds de debug, para que o filtro de export "scripts/debug/*"
	## remova o código de QA do lançamento por completo.
	## - Em debug: load() acha o script e instala o F1/F2/F3/F4 normalmente.
	## - Em release: load() retorna null (arquivo fora do .pck) → guard evita
	##   qualquer erro — o jogo segue 100% limpo, sem rastro de debug.
	if not OS.is_debug_build():
		return
	if get_tree().root.has_node("DevMenu"):
		return
	var dev_script: Script = load("res://scripts/debug/dev_menu.gd")
	if dev_script == null:
		return
	var dev_menu: Node = dev_script.new()
	dev_menu.name = "DevMenu"
	get_tree().root.add_child.call_deferred(dev_menu)
	print("[ARCANJO CAIDO] DevMenu de QA instalado (F1 = painel)")


func _show_panel(panel: Control) -> void:
	## Exibe um painel deslizante e esconde os demais (e o menu principal).
	for child in _panel_box.get_children():
		child.queue_free()
	_menu_box.visible = panel == null
	_panel_box.visible = panel != null
	if panel != null:
		_panel_box.add_child(panel)


func _on_new_game() -> void:
	## Passo 22.2: seletor de slots em modo "Criar Novo Slot".
	var selector := SaveSlotSelectorScript.new(SaveSlotSelectorScript.Mode.MODE_NEW)
	selector.slot_selected.connect(_on_slot_chosen)
	_show_panel(selector)


func _on_load_game() -> void:
	## Passo 22.2: Continuar — carrega o slot mais recente direto; se não
	## houver nenhum save, abre o seletor (todos vazios).
	var last_slot := _most_recent_slot()
	if last_slot >= 0:
		_start_game(last_slot, false)
		return
	var selector := SaveSlotSelectorScript.new(SaveSlotSelectorScript.Mode.MODE_LOAD)
	selector.slot_selected.connect(_on_slot_chosen)
	_show_panel(selector)


func _on_slot_chosen(slot: int, is_new_game: bool) -> void:
	## slot -1 = usuário clicou "Voltar".
	if slot < 0:
		_show_panel(null)
		return
	if is_new_game:
		_start_game(slot, true)
	else:
		_start_game(slot, false)


func _start_game(slot: int, is_new_game: bool) -> void:
	if is_new_game:
		GameState.restore_defaults()
		SaveManager.save_slot(slot)  ## Cria o arquivo do slot já na abertura
		SceneTransition.change_room(FIRST_ROOM, "")
	else:
		if not SaveManager.load_slot(slot):
			push_warning("Falha ao carregar slot %d" % (slot + 1))
			_show_panel(null)


func _most_recent_slot() -> int:
	## Slot com o maior "playtime" salvo = mais recente/progresso maior.
	var best := -1
	var best_time := -1.0
	for slot in SaveManager.SLOT_COUNT:
		var info := SaveManager.get_slot_info(slot)
		if not info.is_empty() and float(info.get("playtime", 0.0)) > best_time:
			best_time = float(info.get("playtime", 0.0))
			best = slot
	return best


func _on_options() -> void:
	## Passo 22: Opções no Menu Principal usa o SettingsPanel reutilizável.
	_settings = SettingsPanelScript.new()
	_settings.back_requested.connect(func(): _show_panel(null))
	_show_panel(_settings)


func _on_achievements() -> void:
	## Lista de conquistas locais (Achievements autoload, user://).
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var header := Label.new()
	header.text = "— CONQUISTAS DE AETERNA —"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_color_override("font_color", Color(0.83, 0.69, 0.22))
	box.add_child(header)
	for def in Achievements.DEFS:
		var done: bool = Achievements.is_unlocked(def.id)
		var label := Label.new()
		label.text = "%s  %s\n      %s" % ["🏆" if done else "🔒", def.name, def.desc]
		label.add_theme_color_override("font_color",
				Color(0.92, 0.89, 0.8) if done else Color(0.6, 0.58, 0.55))
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(520.0, 0.0)
		box.add_child(label)
	var btn_back := Button.new()
	btn_back.text = "Voltar"
	btn_back.pressed.connect(func(): _show_panel(null))
	box.add_child(btn_back)
	_show_panel(box)

