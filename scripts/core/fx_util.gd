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


## [TECH ART] Aplica o normal map neutro a TODOS os sprites/CanvasItem do
## mundo (jogador, cenário, inimigos) de forma recursiva.
## ⚠️ ONDE CONECTAR TEXTURAS REAIS DE NORMAL MAP:
## Substitua `flat_normal()` por uma textura de normal map real por asset
## (p.ex.: `preload("res://assets/art/lucifer_sheet_normal.png")`). A luz 2D
## então terá relevo real em cada sprite. Aquí basta asignar `texture_normal`
## (null = neutro -> flat) para que os sprites REAGAN às PointLight2D.
static func apply_normal_maps(root: Node) -> void:
	if root == null:
		return
	for child in root.get_children():
		if child is CanvasItem:
			apply_flat_normal(child as CanvasItem)
		apply_normal_maps(child)


# ===========================================================================
# PASSO 17: PARTÍCULAS DE COMBATE — faíscas e sangue negro
# ===========================================================================
## Faíscas brilhantes no ponto de contato da lâmina (paredes/armaduras).
static func spawn_sparks(pos: Vector2, parent: Node) -> void:
	if parent == null:
		return
	var b := CPUParticles2D.new()
	b.one_shot = true
	b.explosiveness = 1.0
	b.amount = 10
	b.lifetime = 0.3
	b.direction = Vector2(0, -1)
	b.spread = 150.0
	b.gravity = Vector2(0, 260)
	b.initial_velocity_min = 90.0
	b.initial_velocity_max = 200.0
	b.scale_amount_min = 1.5
	b.scale_amount_max = 3.0
	b.color = Color(1.0, 0.8, 0.3, 0.9)
	b.global_position = pos
	b.emitting = true
	parent.add_child(b)


## Sangue negro: respingo breve (partículas) + gotas físicas que caem,
## colidem e grudam nas plataformas (BloodDroplet).
static func spawn_blood(pos: Vector2, parent: Node) -> void:
	if parent == null:
		return
	var b := CPUParticles2D.new()
	b.one_shot = true
	b.explosiveness = 0.9
	b.amount = 8
	b.lifetime = 0.5
	b.direction = Vector2(0, -1)
	b.spread = 160.0
	b.gravity = Vector2(0, 420)
	b.initial_velocity_min = 50.0
	b.initial_velocity_max = 150.0
	b.scale_amount_min = 1.5
	b.scale_amount_max = 3.5
	b.color = Color(0.1, 0.03, 0.05, 0.8)
	b.global_position = pos
	b.emitting = true
	parent.add_child(b)

	for i in 7:
		var d := BloodDroplet.new()
		d.global_position = pos + Vector2(randf_range(-2.0, 2.0), -2.0)
		d.linear_velocity = Vector2(randf_range(-60.0, 60.0), randf_range(-150.0, -40.0))
		parent.add_child(d)
