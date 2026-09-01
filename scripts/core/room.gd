class_name Room
extends Node2D
## ============================================================================
## [ARCANJO CAIDO] — Passo 7: Script base de toda sala/mapa do jogo.
## Anexado à raiz de cada cena de sala. Registra a sala no GameState
## (fog of war do mapa) com posição na grade, ícones e conexões.
## ============================================================================

@export var room_id: String = ""                ## Identificador único da sala
@export var room_name: String = ""              ## Nome exibido (futuro: HUD)
@export var grid_col: int = 0                   ## Coluna da sala no mapa
@export var grid_row: int = 0                   ## Linha da sala no mapa
@export var grid_w: int = 1                     ## Largura em células do mapa
@export var grid_h: int = 1                     ## Altura em células do mapa
@export var connections: PackedStringArray = [] ## room_ids conectados (portas)
@export var has_bench: bool = false             ## Ícone de Ponto de Descanso
@export var has_npc: bool = false               ## Ícone de NPC
@export var ambient_color: Color = Color(0.42, 0.44, 0.58)  ## Passo 12: luz ambiente

# --- Passo 15: pós-processamento e atmosfera ---
@export_group("Pós-Processamento (Passo 15)")
@export var glow_enabled_room: bool = true   ## Bloom: chamas/olhos/Chama Negra brilham
@export var adjust_brightness: float = 1.0   ## Color grading: brilho
@export var adjust_saturation: float = 1.0   ## Color grading: saturação (Cripta fria ~0.9, Catedral dourada ~1.15)
@export var vignette_intensity: float = 0.45 ## Escurecimento das bordas
@export var fog_enabled: bool = true         ## Névoa volumétrica em movimento

# ===========================================================================
# [TECH ART] — Iluminação Global, Perfis de Cor e Emissão (Passo 19)
# ===========================================================================
## Perfil de color grading pré-definido (substitui os ajustes manuais).
enum ColorProfile { CUSTOM, CRIPTA_FRIA, CATEDRAL_DOURADA, JARDIM_FRESCO, MAR_GELADO }

@export_group("Tech Art — Color Grading / LUT")
@export var color_profile: ColorProfile = ColorProfile.CUSTOM
## Perfil = preset de adjustment (sat/bright/contrast) + tint. Em CUSTOM os
## valores manuais abaixo continuam valendo. Para LUT real, use a propriedade
## `adjustment_color_correction` do Environment com uma textura PNG 16x16x16.
@export var adjust_contrast: float = 1.0     ## Contraste do color grading

@export_group("Tech Art — Tonemapping")
@export var tonemap_enabled: bool = true
@export var tonemap_exposure: float = 1.0    ## Ajuste fino de exposição global
@export var tonemap_white: float = 1.0       ## Ponto de clipagem do branco

@export_group("Tech Art — Emissão (Bloom)")
## Mult. global de energia das PointLight2D no grupo "emissive" da sala
## (Chama Negra, olhos de chefes, ataques, tochas). Brilha com o bloom.
@export var emissive_boost: float = 1.35
@export var ambient_flicker: float = 0.0     ## Pulso global suave opcional (0 = off)


func _ready() -> void:
	assert(room_id != "", "Sala sem room_id: " + name)
	GameState.visit_room(room_id, {
		"name": room_name,
		"col": grid_col,
		"row": grid_row,
		"w": grid_w,
		"h": grid_h,
		"connections": Array(connections),
		"bench": has_bench,
		"npc": has_npc,
		"scene": scene_file_path,  ## Usado pelo SaveManager ao carregar
	})

	# Passo 11: trilha da região (crossfade automático ao trocar de sala).
	AudioManager.play_music(room_id)
	AudioManager.play_ambience("wind")

	# Passo 10: conquistas de exploração.
	if room_id == "cripta_estrelas":
		Achievements.unlock("first_tomb")

	# Passo 12: atmosfera (luz ambiente escura + parallax em camadas).
	_create_ambient_light()
	_create_parallax()

	# Passo 15: bloom/grading, sombras dinâmicas, vinheta e névoa.
	_create_environment()
	_add_shadow_occluders(self)
	_create_vignette()
	if fog_enabled:
		_create_fog()

	# [TECH ART] Passo 19: gestor de iluminação global (emissão bloom + normal maps).
	_add_lighting_manager()


func _create_ambient_light() -> void:
	if has_node("Ambiente"):
		return
	var cm := CanvasModulate.new()
	cm.name = "Ambiente"
	cm.color = ambient_color
	add_child(cm)


func _create_parallax() -> void:
	## Passo 12: ParallaxBackground com duas camadas de gradiente que se
	## repetem horizontalmente — profundidade do Vazio de Aeterna.
	if has_node("ParallaxBG"):
		return
	var pbg := ParallaxBackground.new()
	pbg.name = "ParallaxBG"
	add_child(pbg)
	_add_parallax_layer(pbg, 0.15, Color(0.10, 0.09, 0.14), Color(0.04, 0.04, 0.07))
	_add_parallax_layer(pbg, 0.4, Color(0.16, 0.14, 0.2), Color(0.07, 0.06, 0.1))


func _add_parallax_layer(pbg: ParallaxBackground, motion: float,
		top_color: Color, bottom_color: Color) -> void:
	var layer := ParallaxLayer.new()
	layer.motion_scale = Vector2(motion, motion * 0.5)
	pbg.add_child(layer)

	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	gradient.colors = PackedColorArray([top_color, bottom_color])
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.width = 512
	tex.height = 720

	var rect := TextureRect.new()
	rect.texture = tex
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.size = Vector2(512, 720)
	layer.add_child(rect)
	layer.motion_mirroring = Vector2(512, 0)


# ===========================================================================
# PASSO 15 — PÓS-PROCESSAMENTO, SOMBRAS, VINHETA E NÉVOA
# ===========================================================================
func _create_environment() -> void:
	## Bloom (glow) + color grading por região + TONEMAPPING. Requer hdr_2d ativo.
	if has_node("WorldEnv"):
		return
	var we := WorldEnvironment.new()
	we.name = "WorldEnv"
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	if glow_enabled_room:
		env.glow_enabled = true
		env.glow_intensity = 0.7
		env.glow_bloom = 0.1
		env.glow_hdr_threshold = 1.0
		env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE

	# [TECH ART] Tonemapping: converte o HDR 2D em imagem final agradável.
	# FILMIC é o padrão "cinematográfico"; adjuste exposure/white no inspetor.
	if tonemap_enabled:
		env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		env.tonemap_exposure = tonemap_exposure
		env.tonemap_white = tonemap_white
	else:
		env.tonemap_mode = Environment.TONE_MAPPER_LINEAR

	env.adjustment_enabled = true
	env.adjustment_brightness = adjust_brightness
	env.adjustment_saturation = adjust_saturation
	env.adjustment_contrast = adjust_contrast

	# [TECH ART] Perfil de cor pré-definido por bioma (LUT-like via adjustment + tint).
	# Para LUT real: `env.adjustment_color_correction = preload("res://assets/luts/xxx.png")`
	# — use o padrão 16x16x16 (4096px) e lembre-se de desativar o blend na textura.
	_apply_color_profile(env)

	we.environment = env
	add_child(we)


func _apply_color_profile(env: Environment) -> void:
	## Aplica o preset do perfil escolhido, sobrescrevendo os valores manuais.
	match color_profile:
		ColorProfile.CRIPTA_FRIA:      ## Cripta das Estrelas Caídas — tons azuis/frios
			env.adjustment_saturation = 0.88
			env.adjustment_brightness = 0.98
			env.adjustment_contrast = 1.06
			_apply_profile_tint(Color(0.55, 0.6, 0.8))
		ColorProfile.CATEDRAL_DOURADA: ## Catedral de Mammon — tons dourados/quentes
			env.adjustment_saturation = 1.15
			env.adjustment_brightness = 1.05
			env.adjustment_contrast = 1.0
			_apply_profile_tint(Color(1.0, 0.85, 0.6))
		ColorProfile.JARDIM_FRESCO:    ## Jardim de Adonai-Gal — verde fresco
			env.adjustment_saturation = 1.06
			env.adjustment_brightness = 1.0
			env.adjustment_contrast = 1.02
			_apply_profile_tint(Color(0.7, 0.9, 0.7))
		ColorProfile.MAR_GELADO:       ## Mar de Vidro — branco-azulado gelado
			env.adjustment_saturation = 0.92
			env.adjustment_brightness = 1.02
			env.adjustment_contrast = 1.08
			_apply_profile_tint(Color(0.7, 0.8, 1.0))


## Pinta a luz ambiente (CanvasModulate) com o tint do perfil de cor.
func _apply_profile_tint(tint: Color) -> void:
	var cm: CanvasModulate = get_node_or_null("Ambiente") as CanvasModulate
	if cm and ambient_color != Color.BLACK:
		cm.color = ambient_color * tint.lerp(Color.WHITE, 0.5)


## [TECH ART] Cria o gestor de iluminação global (emissão bloom + normal maps).
func _add_lighting_manager() -> void:
	if has_node("Lighting"):
		return
	var lm := LightingManager.new()
	lm.name = "Lighting"
	lm.emissive_boost = emissive_boost
	lm.ambient_flicker = ambient_flicker
	add_child(lm)


func _add_shadow_occluders(node: Node) -> void:
	## Gera LightOccluder2D para cada sólido retangular da sala:
	## as luzes das tochas projetam sombras reais nas paredes/chão.
	for child in node.get_children():
		if child is StaticBody2D:
			for sub in child.get_children():
				if sub is CollisionShape2D and sub.shape is RectangleShape2D \
						and not child.has_node("Occluder"):
					var size: Vector2 = (sub.shape as RectangleShape2D).size
					var occ := LightOccluder2D.new()
					occ.name = "Occluder"
					var poly := OccluderPolygon2D.new()
					var h := size * 0.5
					poly.polygon = PackedVector2Array([
						Vector2(-h.x, -h.y), Vector2(h.x, -h.y),
						Vector2(h.x, h.y), Vector2(-h.x, h.y)])
					occ.occluder = poly
					occ.position = sub.position
					child.add_child(occ)
		_add_shadow_occluders(child)


func _create_vignette() -> void:
	if has_node("Vignette"):
		return
	var layer := CanvasLayer.new()
	layer.name = "Vignette"
	layer.layer = 70
	add_child(layer)
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/vignette.gdshader")
	mat.set_shader_parameter("intensity", vignette_intensity)
	rect.material = mat
	layer.add_child(rect)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)


func _create_fog() -> void:
	if has_node("Fog"):
		return
	var layer := CanvasLayer.new()
	layer.name = "Fog"
	layer.layer = 65  ## Entre o mundo e a vinheta
	add_child(layer)
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/fog.gdshader")
	rect.material = mat
	layer.add_child(rect)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
