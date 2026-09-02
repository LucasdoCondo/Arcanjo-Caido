extends Control
## ============================================================================
## [ARCANJO CAIDO] — Passo 22: Tela de Créditos e Finais.
## ----------------------------------------------------------------------------
## Rolagem automática de créditos configurável 100% via ARQUIVO DE TEXTO:
##   assets/text/credits.txt
##   - Linhas começando com "#"  → título de seção (equipe, agradecimentos...)
##   - Linhas em branco          → espaçamento
##   - Qualquer outra linha      → crédito simples
## O epílogo exibido no topo depende de GameState.pending_ending:
##   "padrao"     — Final Padrão (derrotar Mammon)
##   "verdadeiro" — Final Verdadeiro (recusar o trono / libertar as almas)
## Como chegar aqui (ganchos já conectados):
##   - MammonBoss._die() → GameState.request_ending("padrao") após 6s
##   - Escolha narrativa futura → GameState.request_ending("verdadeiro")
## Qualquer tecla pula a rolagem; ao terminar, volta ao Menu Principal.
## ============================================================================

const CREDITS_FILE := "res://assets/text/credits.txt"
const MENU_SCENE := "res://scenes/ui/menu_principal.tscn"
const SCROLL_SPEED := 42.0   ## pixels por segundo

var _scroll: ScrollContainer
var _content: VBoxContainer
var _finished: bool = false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	AudioManager.play_music("menu")

	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.03)
	add_child(bg)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)

	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 10)
	_scroll.add_child(_content)

	_build_ending_title()
	_load_credits_file()
	_build_footer()

	## Começa com o conteúdo abaixo da borda inferior.
	_scroll.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_interval(0.4)
	tw.tween_property(_scroll, "modulate:a", 1.0, 1.0)


func _build_ending_title() -> void:
	var end_title := Label.new()
	var end_sub := Label.new()
	match GameState.pending_ending:
		"verdadeiro":
			end_title.text = "A VERDADEIRA LIBERTAÇÃO"
			end_title.add_theme_color_override("font_color", Color(0.95, 0.9, 0.6))
			end_sub.text = "Você recusou o trono. Aeterna se desfaz em estrelas,\ne as almas do Limbo enfim sobem para o céu."
		_:
			end_title.text = "O TRONO DE AETERNA"
			end_title.add_theme_color_override("font_color", Color(0.85, 0.72, 0.3))
			end_sub.text = "Mammon caiu. A Avareza tem um novo soberano...\ne o Vazio ainda sussurra seu nome."
	end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_title.add_theme_font_size_override("font_size", 40)
	end_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_sub.add_theme_color_override("font_color", Color(0.6, 0.58, 0.55))
	_content.add_child(end_title)
	_content.add_child(end_sub)
	_content.add_child(HSeparator.new())


func _load_credits_file() -> void:
	## Créditos definidos em assets/text/credits.txt (editável sem recompilar).
	if not FileAccess.file_exists(CREDITS_FILE):
		_add_center("créditos não encontrados: %s" % CREDITS_FILE, Color(1, 0.4, 0.4), 16)
		return
	var f := FileAccess.open(CREDITS_FILE, FileAccess.READ)
	if f == null:
		return
	while not f.eof_reached():
		var line := f.get_line()
		if line.begins_with("#"):
			_add_section(line.trim_prefix("#").strip_edges())
		elif line.strip_edges() == "":
			var spacer := Control.new()
			spacer.custom_minimum_size = Vector2(0.0, 12.0)
			_content.add_child(spacer)
		else:
			_add_center(line, Color(0.85, 0.82, 0.75), 18)


func _build_footer() -> void:
	_content.add_child(HSeparator.new())
	_add_center("OBRIGADO POR JOGAR", Color(0.92, 0.87, 0.72), 26)
	var hint := Label.new()
	hint.text = "Pressione qualquer tecla para voltar ao Menu Principal"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.45, 0.43, 0.42))
	_content.add_child(hint)


func _add_section(text: String) -> void:
	_add_center(text.to_upper(), Color(0.83, 0.69, 0.22), 24)


func _add_center(text: String, color: Color, size: int) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", size)
	_content.add_child(label)


func _process(delta: float) -> void:
	if _finished:
		return
	## Rolagem automática (para manual = fim da rolagem).
	_scroll.scroll_vertical += int(SCROLL_SPEED * delta)
	var max_scroll: int = _scroll.get_v_scroll_bar().max_value
	if _scroll.scroll_vertical >= int(max_scroll) - 2:
		_leave()


func _input(event: InputEvent) -> void:
	## Qualquer tecla/botão pula os créditos e volta ao menu.
	if event is InputEventKey and event.pressed:
		_leave()
	elif event is InputEventJoypadButton and event.pressed:
		_leave()
	elif event is InputEventMouseButton and event.pressed:
		_leave()


func _leave() -> void:
	if _finished:
		return
	_finished = true
	## Fim dos créditos: volta ao Menu Principal.
	get_tree().change_scene_to_file(MENU_SCENE)
