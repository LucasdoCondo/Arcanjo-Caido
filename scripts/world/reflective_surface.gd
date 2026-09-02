class_name ReflectiveSurface
extends ColorRect
## ============================================================================
## [ARCANJO CAIDO] — Passo 18: Superfície reflexiva (mercúrio / chão polido).
## ----------------------------------------------------------------------------
## Um ColorRect com o shader mirrowater que reflete tudo que está ACIMA da
## sua borda superior (a linha do espelho). A cada frame recalcula a posição
## da linha do espelho em tela para que o reflexo siga a câmera.
## ============================================================================

@export var shader_material: ShaderMaterial


func _ready() -> void:
	if shader_material == null:
		var em := ShaderMaterial.new()
		em.shader = load("res://assets/shaders/mirror_water.gdshader")
		shader_material = em
	material = shader_material


func _process(_delta: float) -> void:
	var vp := get_viewport()
	if vp == null or shader_material == null:
		return
	# Coordenada em tela da borda superior (linha do espelho).
	var top := get_global_transform_with_canvas() * Vector2(0.0, 0.0)
	var vh := float(vp.get_visible_rect().size.y)
	shader_material.set_shader_parameter("mirror_y", top.y / vh)