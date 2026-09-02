# ============================================================================
# [ARCANJOS CAIDOS] — Parallax System
# ----------------------------------------------------------------------------
# Sistema de paralaxe com 7 camadas para máxima profundidade.
# Estilo Legend of Mana (aquarela) + Hollow Knight (profundidade).
#
# Uso: Anexe ao ParallaxBackground. Configure texturas nos exports.
# ============================================================================

class_name ParallaxSystem
extends ParallaxBackground

@export_group("Configuração de Camadas")
@export var layer_count: int = 7
@export var mirror_horizontal: bool = true
@export var mirror_vertical: bool = false

@export_group("Texturas por Camada")
@export var texture_sky: Texture2D
@export var texture_mountains_far: Texture2D
@export var texture_mountains_near: Texture2D
@export var texture_forest_far: Texture2D
@export var texture_forest_near: Texture2D
@export var texture_details: Texture2D
@export var texture_foreground: Texture2D

@export_group("Escala de Movimento (motion_scale)")
@export var scale_sky: Vector2 = Vector2(0.0, 0.0)
@export var scale_mountains_far: Vector2 = Vector2(0.05, 0.02)
@export var scale_mountains_near: Vector2 = Vector2(0.15, 0.05)
@export var scale_forest_far: Vector2 = Vector2(0.3, 0.1)
@export var scale_forest_near: Vector2 = Vector2(0.5, 0.15)
@export var scale_details: Vector2 = Vector2(0.7, 0.2)
@export var scale_foreground: Vector2 = Vector2(0.9, 0.3)

@export_group("Tints por Camada")
@export var tint_sky: Color = Color(0.1, 0.15, 0.25, 1.0)
@export var tint_mountains_far: Color = Color(0.08, 0.12, 0.18, 1.0)
@export var tint_mountains_near: Color = Color(0.1, 0.15, 0.2, 1.0)
@export var tint_forest_far: Color = Color(0.12, 0.18, 0.15, 1.0)
@export var tint_forest_near: Color = Color(0.15, 0.22, 0.18, 1.0)
@export var tint_details: Color = Color(0.18, 0.25, 0.2, 1.0)
@export var tint_foreground: Color = Color(0.05, 0.08, 0.06, 1.0)

@export_group("Offset Vertical")
@export var offset_sky: float = 0.0
@export var offset_mountains_far: float = 100.0
@export var offset_mountains_near: float = 200.0
@export var offset_forest_far: float = 300.0
@export var offset_forest_near: float = 400.0
@export var offset_details: float = 500.0
@export var offset_foreground: float = 600.0

# Internals
var _layers: Array[ParallaxLayer] = []


func _ready() -> void:
	_setup_parallax()


func _setup_parallax() -> void:
	# Configura espelhamento
	if mirror_horizontal:
		motion_mirroring = Vector2(1920, 0)
	
	# Cria todas as camadas
	_create_layer("Sky", texture_sky, scale_sky, tint_sky, offset_sky, -70)
	_create_layer("MountainsFar", texture_mountains_far, scale_mountains_far, tint_mountains_far, offset_mountains_far, -60)
	_create_layer("MountainsNear", texture_mountains_near, scale_mountains_near, tint_mountains_near, offset_mountains_near, -50)
	_create_layer("ForestFar", texture_forest_far, scale_forest_far, tint_forest_far, offset_forest_far, -40)
	_create_layer("ForestNear", texture_forest_near, scale_forest_near, tint_forest_near, offset_forest_near, -30)
	_create_layer("Details", texture_details, scale_details, tint_details, offset_details, -20)
	_create_layer("Foreground", texture_foreground, scale_foreground, tint_foreground, offset_foreground, -10)


func _create_layer(name: String, texture: Texture2D, scale: Vector2, tint: Color, offset_y: float, z_index: int) -> void:
	var layer := ParallaxLayer.new()
	layer.name = name
	layer.motion_scale = scale
	layer.z_index = z_index
	
	if mirror_horizontal:
		layer.motion_mirroring = Vector2(1920, 0)
	
	var sprite := Sprite2D.new()
	
	if texture:
		sprite.texture = texture
	else:
		sprite.texture = _create_placeholder_texture(name, tint)
	
	sprite.modulate = tint
	sprite.centered = false
	sprite.position = Vector2(0, offset_y)
	
	layer.add_child(sprite)
	add_child(layer)
	_layers.append(layer)


func _create_placeholder_texture(name: String, tint: Color) -> ImageTexture:
	var img := Image.create(960, 540, false, Image.FORMAT_RGBA8)
	
	# Cria gradiente vertical
	for y in range(540):
		var alpha := 1.0 - (float(y) / 540.0) * 0.3
		var row_color := Color(tint.r, tint.g, tint.b, alpha)
		for x in range(960):
			img.set_pixel(x, y, row_color)
	
	return ImageTexture.create_from_image(img)


## API: Atualiza textura de uma camada em runtime
func set_layer_texture(layer_name: String, new_texture: Texture2D) -> void:
	for layer in _layers:
		if layer.name == layer_name:
			var sprite := layer.get_child(0) as Sprite2D
			if sprite:
				sprite.texture = new_texture
			break


## API: Atualiza tint de uma camada
func set_layer_tint(layer_name: String, new_tint: Color) -> void:
	for layer in _layers:
		if layer.name == layer_name:
			var sprite := layer.get_child(0) as Sprite2D
			if sprite:
				sprite.modulate = new_tint
			break


## API: Atualiza motion_scale de uma camada
func set_layer_scale(layer_name: String, new_scale: Vector2) -> void:
	for layer in _layers:
		if layer.name == layer_name:
			layer.motion_scale = new_scale
			break


## API: Define espelhamento horizontal
func set_horizontal_mirror(enabled: bool) -> void:
	motion_mirroring = Vector2(1920, 0) if enabled else Vector2.ZERO
	for layer in _layers:
		layer.motion_mirroring = motion_mirroring