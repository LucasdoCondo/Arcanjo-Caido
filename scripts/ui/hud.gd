extends CanvasLayer
## ============================================================================
## [ARCANJO CAIDO] — Autoload: HUD (Passo 10)
## ----------------------------------------------------------------------------
## HUD principal: máscaras de vida, medidor da Chama Negra e contador de
## Pratas de Judas. Fica oculto quando não há Lúcifer em cena (menu).
## Construído em código; os sprites finais substituem os ColorRects.
## ============================================================================

const MASK_SIZE := 22.0
const CHAMA_W := 180.0
const CHAMA_H := 12.0

var _masks_box: HBoxContainer
var _chama_fill: ColorRect
var _pratas_label: Label
var _cached_max_health: int = -1


func _ready() -> void:
	layer = 80
	visible = false

	var anchor := Control.new()
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(anchor)
	anchor.set_anchors_preset(Control.PRESET_FULL_RECT)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor.add_child(margin)
	margin.set_anchors_preset(Control.PRESET_TOP_LEFT)
	margin.position = Vector2(24.0, 20.0)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)

	# --- Máscaras de vida ---
	_masks_box = HBoxContainer.new()
	_masks_box.add_theme_constant_override("separation", 6)
	vbox.add_child(_masks_box)

	# --- Chama Negra ---
	var chama_bg := ColorRect.new()
	chama_bg.custom_minimum_size = Vector2(CHAMA_W, CHAMA_H)
	chama_bg.color = Color(0.08, 0.07, 0.1, 0.85)
	chama_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(chama_bg)
	var chama_margin := MarginContainer.new()
	chama_bg.add_child(chama_margin)
	chama_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	chama_margin.add_theme_constant_override("margin_left", 2)
	chama_margin.add_theme_constant_override("margin_top", 2)
	chama_margin.add_theme_constant_override("margin_right", 2)
	chama_margin.add_theme_constant_override("margin_bottom", 2)
	_chama_fill = ColorRect.new()
	_chama_fill.color = Color(0.95, 0.75, 0.25, 0.95)
	_chama_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chama_margin.add_child(_chama_fill)

	# --- Pratas de Judas ---
	_pratas_label = Label.new()
	_pratas_label.text = "◇ 0"
	_pratas_label.add_theme_font_size_override("font_size", 20)
	_pratas_label.add_theme_color_override("font_color", Color(0.9, 0.87, 0.75))
	vbox.add_child(_pratas_label)


func _process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player):
		visible = false
		return
	visible = true

	# Máscaras (recria se o máximo mudou).
	if player.max_health != _cached_max_health:
		_cached_max_health = player.max_health
		_rebuild_masks()

	# Máscara cheia/vazia.
	for i in _masks_box.get_child_count():
		var mask := _masks_box.get_child(i) as ColorRect
		mask.color = Color(0.85, 0.3, 0.3) if i < player.current_health \
				else Color(0.15, 0.12, 0.14, 0.8)

	# Chama Negra (proporção 0..1).
	var ratio := 0.0
	if player.chama_max > 0.0:
		ratio = clampf(player.chama_negra / player.chama_max, 0.0, 1.0)
	_chama_fill.size = Vector2((CHAMA_W - 4.0) * ratio, CHAMA_H - 4.0)

	_pratas_label.text = "◇ %d" % player.pratas_de_judas


func _rebuild_masks() -> void:
	for child in _masks_box.get_children():
		child.queue_free()
	for i in _cached_max_health:
		var mask := ColorRect.new()
		mask.custom_minimum_size = Vector2(MASK_SIZE, MASK_SIZE)
		mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_masks_box.add_child(mask)
