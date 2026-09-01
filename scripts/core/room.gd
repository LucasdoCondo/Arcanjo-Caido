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
	## Bloom (glow) + color grading por região. Requer hdr_2d ativo no projeto.
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
	env.adjustment_enabled = true
	env.adjustment_brightness = adjust_brightness
	env.adjustment_saturation = adjust_saturation
	we.environment = env
	add_child(we)


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
