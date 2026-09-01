class_name FxUtil
## ============================================================================
## [ARCANJO CAIDO] — Passo 15: utilitários de pós-processamento.
## Gerador de normal map neutro: dá às luzes 2D um ponto de partida
## tridimensional nos sprites. Quando as artes finais tiverem normal maps
## reais (gerados no Aseprite/Krita), basta substituir texture_normal.
## ============================================================================

static var _flat_normal: ImageTexture


static func flat_normal() -> ImageTexture:
	if _flat_normal == null:
		var img := Image.create(4, 4, false, Image.FORMAT_RGB8)
		img.fill(Color(0.5, 0.5, 1.0))  ## Normal "para fora" da tela
		_flat_normal = ImageTexture.create_from_image(img)
	return _flat_normal


## Aplica o normal map neutro em um CanvasItem, se ele suportar.
static func apply_flat_normal(item: CanvasItem) -> void:
	if item != null and "texture_normal" in item and item.texture_normal == null:
		item.texture_normal = flat_normal()
