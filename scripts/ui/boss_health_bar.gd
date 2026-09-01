extends CanvasLayer
## ============================================================================
## [ARCANJO CAIDO] — Passo 9: Barra de vida do chefe.
## UI dedicada na parte inferior da tela, visível apenas durante a luta.
## Instanciada pelo próprio chefe em código (sem cena extra).
## ============================================================================

var _bar: ProgressBar
var _label: Label


func _ready() -> void:
	layer = 60
	visible = false

	var anchor := Control.new()
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(anchor)
	anchor.set_anchors_preset(Control.PRESET_FULL_RECT)

	_label = Label.new()
	_label.text = ""
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	anchor.add_child(_label)
	_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_label.position.y = -84.0

	_bar = ProgressBar.new()
	_bar.min_value = 0
	_bar.show_percentage = false
	anchor.add_child(_bar)
	_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_bar.offset_left = 240.0
	_bar.offset_right = -240.0
	_bar.offset_top = -64.0
	_bar.offset_bottom = -44.0

	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.83, 0.65, 0.15)
	_bar.add_theme_stylebox_override("fill", fill)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.08, 0.07, 0.1, 0.85)
	_bar.add_theme_stylebox_override("background", back)


func setup(max_hp: int, current_hp: int) -> void:
	_bar.max_value = max_hp
	_bar.value = current_hp


func set_hp(hp: int) -> void:
	_bar.value = hp


func show_fight(boss_name: String) -> void:
	_label.text = boss_name
	visible = true


func hide_fight() -> void:
	visible = false
