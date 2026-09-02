class_name PlayerController
extends CharacterBody2D
## ============================================================================
## [ARCANJO CAIDO] — Passos 1–2: Controller e Combate do Lúcifer
## ----------------------------------------------------------------------------
## Movimentação estilo Hollow Knight:
##   - Aceleração/desaceleração com fricção configurável (chão e ar separados)
##   - Pulo com altura variável (cortar o pulo ao soltar o botão)
##   - Coyote Time + Jump Buffer (pulo "perdoador", feel de precisão)
##   - Dash de Sombra com cooldown e invulnerabilidade temporária (i-frames)
##   - FSM: IDLE, WALK, JUMP, FALL, DASH, ATTACK
## Combate (Passo 2):
##   - Lâmina do Alvorecer: ataque em 3 direções (frente, cima, baixo)
##   - Pogo Strike: golpe para baixo no ar rebate em inimigos/perigos
##   - Chama Negra: ganha acertando, gasta curando (canalizada segurando F)
## ============================================================================

signal state_changed(new_state: State)
signal dashed
signal health_changed(current_health: int, max_health: int)  ## Passo 2: HUD futuro
signal chama_changed(current: float, maximum: float)          ## Passo 2: HUD futuro
signal damaged(amount: int)                                    ## Emitido ao tomar dano
signal died                                                    ## Passo 4: respawn no banco
signal pratas_changed(total: int)                              ## Passo 3: economia
signal coin_collected                                          ## Passo 11: SFX de moeda

## Direções de ataque da Lâmina do Alvorecer.
enum Direction { NEUTRAL, UP, DOWN }

## Estados da máquina de estados do Lúcifer.
enum State {
	IDLE,    ## Parado no chão
	WALK,    ## Andando no chão
	JUMP,    ## Subindo (pulo / caindo com velocidade para cima)
	FALL,    ## Caindo
	DASH,    ## Dash de Sombra (invulnerável durante a duração)
	ATTACK,  ## Golpe da Lâmina do Alvorecer (implementado no Passo 2)
	WALL_SLIDE,      ## Garra do Abismo: deslizando na parede (Passo 8)
	GROUND_POUND,    ## Macho de Ferro: queda devastadora (Passo 8)
	HOOK,            ## Sombra de Voo: projetado por nó de energia (Passo 8)
}

# ---------------------------------------------------------------------------
# MOVIMENTO HORIZONTAL (ajustável no inspetor)
# ---------------------------------------------------------------------------
@export_group("Movimento Horizontal")
@export var max_speed: float = 320.0            ## Velocidade máxima de corrida (px/s)
@export var acceleration: float = 2600.0        ## Aceleração no chão (px/s²)
@export var friction: float = 3400.0            ## Fricção no chão ao soltar o direcional
@export var air_acceleration: float = 1800.0    ## Aceleração no ar (menor = mais "pesado")
@export var air_friction: float = 900.0         ## Fricção no ar
# ---------------------------------------------------------------------------
# PASSO 16: ANIMAÇÃO FLUIDA — Squash & Stretch + Rotational Lean
# ---------------------------------------------------------------------------
@export_group("Squash & Stretch (Deformação)")
@export var squash_intensity: float = 0.10     ## Deformação máxima ao pular/aterrissar (1.0 = tamanho original(
@export var squash_speed: float = 10.0        ## Velocidade de retorno ao normal do sprite
@export var squash_fall_factor: float = 0.0022 ## Converte velocidade de queda → intensidade do squash

@export_group("Rotational Lean (Inclinação dinâmica)")
@export var lean_intensity: float = 0.09        ## Inclinação máxima ao acelerar/frear (rad(
@export var lean_speed: float = 8.0           ## Suavização do lean (maior = mais ágil(
@export var lean_dash_tilt: float = 0.15        ## Inclinação do dash (antes era -0.15 fixo(

# ---------------------------------------------------------------------------
# PASSO 17: Rastros Fantasma (Afterimage) no Dash de Sombra
# ---------------------------------------------------------------------------
@export_group("Rastros Fantasma (Passo 17)")
@export var ghost_interval: float = 0.03        ## Intervalo entre afterimages durante o dash
@export var ghost_alpha: float = 0.5            ## Opacidade inicial do afterimage
@export var ghost_lifetime: float = 0.3         ## Duração do fade-out (s)

# ---------------------------------------------------------------------------
# PASSO 19: TRIGGERS DE ÁUDIO — cadências de SFX no player
# ---------------------------------------------------------------------------
@export_group("Trigger de Passos (Passo 19)")
@export var step_interval: float = 0.24         ## Cadência do som "step" ao correr no chão

# ---------------------------------------------------------------------------
# PULO (altura variável + coyote time + buffer)
# ---------------------------------------------------------------------------
@export_group("Pulo")
@export var jump_force: float = -720.0          ## Impulso inicial do pulo (negativo = para cima)
@export var gravity: float = 2000.0             ## Gravidade própria (ignora a do projeto)
@export var fall_gravity_multiplier: float = 1.35  ## Queda mais rápida que subida (game feel)
@export var max_fall_speed: float = 1300.0      ## Velocidade terminal de queda
@export var jump_cut_multiplier: float = 0.4    ## Velocidade restante ao soltar o botão cedo
@export var coyote_time: float = 0.1            ## Janela para pular após sair da borda (s)
@export var jump_buffer_time: float = 0.12      ## Buffer de pulo antes de tocar o chão (s)
@export var max_jumps: int = 1                  ## Pulos no ar (pulo duplo desbloqueável depois)

# ---------------------------------------------------------------------------
# DASH DE SOMBRA
# ---------------------------------------------------------------------------
@export_group("Dash de Sombra")
@export var dash_speed: float = 700.0           ## Velocidade do dash (px/s)
@export var dash_duration: float = 0.18         ## Duração do dash (s)
@export var dash_cooldown: float = 0.45         ## Tempo até poder dar dash novamente (s)
@export var dash_gravity_freeze: bool = true    ## Congela a gravidade durante o dash
@export var dash_invulnerable: bool = true      ## I-frames durante o dash (Passo 2/3 usam isso)

# ---------------------------------------------------------------------------
# HABILIDADES DE EXPLORAÇÃO (Passo 8) — desbloqueadas ao derrotar chefes
# ---------------------------------------------------------------------------
@export_group("Garra do Abismo (Wall Jump)")
@export var wall_slide_speed: float = 120.0     ## Velocidade de deslize na parede
@export var wall_jump_x: float = 380.0          ## Impulso horizontal do wall jump
@export var wall_jump_y: float = -620.0         ## Impulso vertical do wall jump

@export_group("Macho de Ferro (Ground Pound)")
@export var gp_hover_time: float = 0.12         ## Suspensão antes de despencar (s)
@export var gp_fall_speed: float = 1600.0       ## Velocidade da queda devastadora
@export var gp_damage: int = 2                  ## Dano da onda de choque

@export_group("Sombra de Voo (Gancho)")
@export var hook_range: float = 280.0           ## Alcance de conexão com nós
@export var hook_speed: float = 900.0           ## Velocidade de projeção

@export_group("Postura Parry (lore)")
@export var parry_window: float = 0.15          ## Janela de reflexo perfeito (s)
@export var parry_cooldown: float = 0.8         ## Recarga da postura (s)

# ---------------------------------------------------------------------------
# COMBATE — LÂMINA DO ALVORECER (Passo 2)
# ---------------------------------------------------------------------------
@export_group("Combate — Lâmina do Alvorecer")
@export var attack_damage: int = 1              ## Dano por golpe
@export var attack_duration: float = 0.25       ## Duração total do golpe (s)
@export var hitbox_active_delay: float = 0.05   ## Antes dela (startup frames)
@export var hitbox_active_duration: float = 0.12 ## Janela ativa da hitbox (s)
@export var pogo_force: float = -560.0          ## Impulso do Pogo Strike (para cima)

@export_group("Chama Negra")
@export var chama_max: float = 99.0             ## Máximo da Chama Negra (estilo ALMA do HK)
@export var chama_por_golpe: float = 12.0       ## Ganho por ataque bem-sucedido (cura custa 33 ≈ 3 golpes)
@export var heal_channel_time: float = 0.8      ## Tempo canalizando a cura (s)
@export var heal_cost: float = 33.0             ## Custo em Chama Negra por cura
@export var heal_amount: int = 1                ## Pontos de vida restaurados

@export_group("Vida")
@export var max_health: int = 5                 ## Máscaras de vida do Lúcifer
@export var iframes_duration: float = 1.0       ## Invulnerabilidade após tomar dano (s)
@export var damage_knockback_force: float = 260.0 ## Repulsão ao ser atingido

# ---------------------------------------------------------------------------
# ESTADO INTERNO
# ---------------------------------------------------------------------------
var state: State = State.IDLE:
	set(value):
		if state != value:
			state = value
			state_changed.emit(value)

var facing: int = 1                  ## 1 = direita, -1 = esquerda (espelha o sprite)
var jumps_left: int = 1              ## Pulos restantes (recarrega ao tocar o chão)
var coyote_timer: float = 0.0        ## Contagem regressiva do coyote time
var jump_buffer_timer: float = 0.0   ## Contagem regressiva do buffer de pulo
var dash_timer: float = 0.0          ## Tempo restante do dash ativo
var dash_cooldown_timer: float = 0.0 ## Cooldown do dash
var dash_direction: Vector2 = Vector2.RIGHT
var is_invulnerable: bool = false    ## true durante o Dash de Sombra (combate futuro)
var is_on_wall_check: bool = false   ## Snapshot de parede (wall jump no Passo 2)

# --- Habilidades de exploração (Passo 8) ---
var _wall_dir: int = 0               ## -1 parede à esquerda, 1 à direita, 0 nenhuma
var _gp_hover_timer: float = 0.0
var _hook_target: Node2D = null
var _hook_timer: float = 0.0
var _was_airborne: bool = false
var _look_offset: Vector2 = Vector2.ZERO
var _parry_timer: float = 0.0       ## Janela de parry ativa
var _parry_cd: float = 0.0          ## Recarga do parry
var _dash_hits: Array[Area2D] = []  ## Alvos já corroídos pelo dash venenoso

# --- Passo 16: Squash & Stretch + Rotational Lean ---
var _squash_scale: Vector2 = Vector2.ONE     ## Escala deformada atual do sprite
var _sprite_base_scale: Vector2 = Vector2.ONE ## Escala base da cena (multiplicador(
var _landing_pending: bool = false             ## Evita squash duplicado na mesma aterrissagem
var _fall_impact_speed: float = 0.0       ## Velocidade Y capturada antes do impacto
var _lean_angle: float = 0.0              ## Rotação suavizada atual (Rotational Lean(

# --- Passo 17: Física secundária + partículas ---
var _cape: Cape2D = null                  ## Capa física (juntas) criada no _ready
var _dust_fx: CPUParticles2D = null        ## Poeira dos pés (Passo 17)
var _ghost_timer: float = 0.0              ## Acumulador para os afterimages do dash
var _step_timer: float = 0.0              ## Passo 19: cadencia do som de passos

# --- Combate (Passo 2) ---
var _attack_dir: Direction = Direction.NEUTRAL
var _attack_timer: float = 0.0
var _hitbox_delay_timer: float = 0.0
var _hitbox_active_timer: float = 0.0
var _hits_this_swing: Array[Area2D] = []  ## Evita acertar o mesmo alvo 2x no golpe

# --- Vida / Chama Negra (Passo 2) ---
var current_health: int = 5
var chama_negra: float = 0.0
var _iframes_timer: float = 0.0
var _is_healing: bool = false
var _heal_channel_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var camera: Camera2D = $Camera2D
@onready var hitbox: Area2D = $MeleeHitbox
@onready var hitbox_shape: RectangleShape2D = $MeleeHitbox/CollisionShape2D.shape
@onready var wall_ray_left: RayCast2D = $WallRayLeft
@onready var wall_ray_right: RayCast2D = $WallRayRight
@onready var wings_fx: CPUParticles2D = $WingsFX
@onready var shockwave: Area2D = $Shockwave
@onready var hook_line: Line2D = $HookLine
@onready var dash_fx: CPUParticles2D = $DashFX
@onready var land_fx: CPUParticles2D = $LandFX
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var chama_light: PointLight2D = $ChamaNegra  ## Passo 19: luz emissiva do Chama Negra

func _ready() -> void:
	jumps_left = _max_jumps()
	current_health = max_health
	chama_negra = 0.0
	apply_sigils()
	FxUtil.apply_flat_normal(sprite)  ## Passo 15: luzes 2D reagem ao sprite
	if sprite:
		_sprite_base_scale = sprite.scale  ## Passo 16: base para o Squash & Stretch
	if hitbox:
		hitbox.monitoring = false  ## Hitbox só liga durante a janela ativa do golpe

	# Passo 17: capa física + emisor de poeira dos pés (criados por código).
	if $Cape == null:
		_cape = Cape2D.new()
		_cape.name = "Cape"
		add_child(_cape)
	else:
		_cape = $Cape
	if $DustFX == null:
		var dust := CPUParticles2D.new()
		dust.name = "DustFX"
		dust.position = Vector2(0.0, 30.0)
		dust.amount = 6
		dust.one_shot = false
		dust.lifetime = 0.3
		dust.direction = Vector2(0, -1)
		dust.spread = 90.0
		dust.gravity = Vector2(0, 220)
		dust.initial_velocity_min = 30.0
		dust.initial_velocity_max = 90.0
		dust.scale_amount_min = 1.5
		dust.scale_amount_max = 3.0
		dust.color = Color(0.45, 0.4, 0.34, 0.55)
		add_child(dust)
	_dust_fx = $DustFX
	
	_dust_fx.emitting = false

	# [TECH ART] Passo 19: inicializa a luz do Chama Negra (invisível até ganhar chama).
	if chama_light:
		chama_light.visible = false
		chama_light.energy = 0.0
	_update_chama_visual()  ## Passo 19: sincroniza emissão com a Chama Negra



func get_facing() -> int:
	## Usado pela capa (Cape2D) para saber detrás do sprite deve pendular.
	return facing


func _physics_process(delta: float) -> void:
	# --- Timers (sempre atualizados, independente do estado) ---
	coyote_timer = maxf(coyote_timer - delta, 0.0)
	jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)
	dash_cooldown_timer = maxf(dash_cooldown_timer - delta, 0.0)
	_iframes_timer = maxf(_iframes_timer - delta, 0.0)
	_parry_timer = maxf(_parry_timer - delta, 0.0)
	_parry_cd = maxf(_parry_cd - delta, 0.0)

	# Buffer de pulo: registra o input mesmo se pressionado "cedo demais".
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time

	# --- Snapshot de colisões (para FSM e mecânicas futuras) ---
	var was_on_floor := is_on_floor()
	is_on_wall_check = is_on_wall()

	# Garra do Abismo: detecta parede próxima (esquerda/direita).
	_wall_dir = 0
	if wall_ray_left.is_colliding():
		_wall_dir = -1
	elif wall_ray_right.is_colliding():
		_wall_dir = 1

	# --- Coyote time: recarrega ao tocar o chão ---
	if was_on_floor:
		coyote_timer = coyote_time
		jumps_left = _max_jumps()

	# --- FSM ---
	match state:
		State.DASH:
			_process_dash(delta)
		State.ATTACK:
			_process_attack(delta)
		State.WALL_SLIDE:
			_process_wall_slide(delta)
		State.GROUND_POUND:
			_process_ground_pound(delta)
		State.HOOK:
			_process_hook(delta)
		_:
			_process_locomotion(delta)

	# --- Aplicação final do movimento ---
	# Passo 16: captura a velocidade de impacto (usada no squash de aterrissagem).
	_fall_impact_speed = velocity.y
	move_and_slide()
	_update_camera_shake(delta)

	# Passo 12: poeira de aterrissagem + Passo 16: squash de impacto.
	if is_on_floor() and _was_airborne:
		if land_fx:
			land_fx.restart()
		# Deformação proporcional à velocidade da queda (achata na horizontal).
		if not _landing_pending:
			_landing_pending = true
			var fall_factor := clampf(absf(_fall_impact_speed) * squash_fall_factor, 0.4, 1.3)
			_apply_squash(false, fall_factor)
			# Passo 19: som de aterrissagem (só no impacto principal, não duplicado).
			AudioManager.sfx("land")
		# Passo 17: nuvem de poeira ao aterrissar (reforza o impacto).
		if _dust_fx:
			_dust_fx.restart()
	elif not is_on_floor():
		_landing_pending = false  ## Reseta para detectar a próxima aterrissagem
	_was_airborne = not is_on_floor()

	# --- Atualiza estado "aéreo" com base no resultado físico ---
	if state != State.DASH and state != State.ATTACK and state != State.WALL_SLIDE \
			and state != State.GROUND_POUND and state != State.HOOK:
		if is_on_floor():
			state = State.WALK if absf(velocity.x) > 10.0 else State.IDLE
		elif velocity.y < 0.0:
			state = State.JUMP
		else:
			state = State.FALL

	# Passo 16: os visuais (squash/lean/animação) são atualizados no _process,
	# com o delta real do frame (interpolação em 120/144Hz+).

	# Passo 17: poeira dos pés ao correr no chão.
	if _dust_fx:
		_dust_fx.emitting = is_on_floor() and state == State.WALK and absf(velocity.x) > 60.0

	# Passo 19: som de passos com cadência (pitch variation automática).
	if state == State.WALK and is_on_floor() and absf(velocity.x) > 60.0:
		_step_timer -= delta
		if _step_timer <= 0.0:
			_step_timer = step_interval
			AudioManager.sfx("step")


# ===========================================================================
# PASSO 16: ANIMAÇÃO FLUIDA — processa os visuais a cada frame renderizado
# A física continua no _physics_process; aqui suavizamos squash & stretch e
# o rotational lean com o delta de renderização (alta taxa de atualização).
# ===========================================================================
func _process(delta: float) -> void:
	if sprite:
		_update_visuals(delta)
	# [TECH ART] Passo 19: atualiza a emissão do Chama Negra a cada frame.
	_update_chama_visual()


# ===========================================================================
# LOCOMOÇÃO: chão + ar + pulo + entrada do dash
# ===========================================================================


func _process_locomotion(delta: float) -> void:
	# Canalizando a cura: bloqueia movimento (estilo Hollow Knight).
	if _is_healing:
		_process_heal_channel(delta)
		return
	var input_dir := Input.get_axis("move_left", "move_right")

	# --- Aceleração horizontal (parâmetros diferentes no chão e no ar) ---
	if input_dir != 0.0:
		var accel := acceleration if is_on_floor() else air_acceleration
		velocity.x = move_toward(velocity.x, input_dir * max_speed, accel * delta)
		facing = 1 if input_dir > 0.0 else -1
	else:
		var fric := friction if is_on_floor() else air_friction
		velocity.x = move_toward(velocity.x, 0.0, fric * delta)

	# --- Gravidade (mais forte na queda para um arco de pulo "snappy") ---
	if not is_on_floor():
		var g := gravity * (fall_gravity_multiplier if velocity.y > 0.0 else 1.0)
		velocity.y = minf(velocity.y + g * delta, max_fall_speed)

		# Garra do Abismo: desliza encostado na parede segurando o direcional dela.
		if GameState.abilities.get("wall_jump", false) and _wall_dir != 0 \
				and velocity.y > 0.0 and input_dir == float(_wall_dir):
			state = State.WALL_SLIDE
			return

	# --- Pulo: buffer + coyote + pulo múltiplo + wall jump ---
	if jump_buffer_timer > 0.0:
		if coyote_timer > 0.0 or is_on_floor():
			_do_jump()
		elif GameState.abilities.get("wall_jump", false) and _wall_dir != 0:
			_do_wall_jump()
		elif jumps_left > 0:
			_do_jump()

	# --- Altura variável: soltar o botão cedo corta o pulo ---
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier

	# --- Macho de Ferro (S/↓ + dash no ar) ou Dash de Sombra ---
	if Input.is_action_just_pressed("dash"):
		if not is_on_floor() and Input.is_action_pressed("move_down") \
				and GameState.abilities.get("ground_pound", false):
			_start_ground_pound()
			return
		if dash_cooldown_timer <= 0.0:
			_start_dash()
			return

	# --- Cura (Chama Negra): segurar o botão de magia no chão ---
	if Input.is_action_just_pressed("heal") and _can_start_heal():
		_start_heal()
		return

	# --- Postura Parry: reflexo no timing exato (lore) ---
	if Input.is_action_just_pressed("parry") and _parry_cd <= 0.0:
		_parry_timer = parry_window
		_parry_cd = parry_cooldown
		AudioManager.sfx("parry")
		return

	# --- Sombra de Voo: gancho em nós de energia arcana (no ar) ---
	if Input.is_action_just_pressed("hook") and not is_on_floor() \
			and GameState.abilities.get("hook", false):
		if _try_hook():
			return

	# --- Ataque da Lâmina do Alvorecer (3 direções) ---
	if Input.is_action_just_pressed("attack"):
		_start_attack()
		return


func _do_jump() -> void:
	var is_air_jump := not is_on_floor()
	velocity.y = jump_force
	jump_buffer_timer = 0.0
	coyote_timer = 0.0
	jumps_left -= 1
	state = State.JUMP
	# Passo 16: estica na vertical — impulso da decolagem.
	_apply_squash(true)
	# Asas Caídas: jato de fumaça dourada no pulo aéreo.
	if is_air_jump and wings_fx:
		wings_fx.restart()
	# Passo 17: puff de poeira dos pés na decolagem.
	if _dust_fx:
		_dust_fx.restart()


# ===========================================================================
# DASH DE SOMBRA
# ===========================================================================
func _start_dash() -> void:
	state = State.DASH
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	_dash_hits.clear()
	# Passo 16: estica na horizontal — o dash é um "corte" veloz.
	_apply_squash(true, 0.6, true)
	## Passo 12: rastro de fumaça e brasas do Dash de Sombra.
	if dash_fx:
		dash_fx.restart()

	# Direção do dash: direcional pressionado, senão a direção que está olhando.
	var input_dir := Input.get_axis("move_left", "move_right")
	dash_direction = Vector2(input_dir, 0.0)
	if dash_direction == Vector2.ZERO:
		dash_direction = Vector2(facing, 0.0)
	dash_direction = dash_direction.normalized()

	if dash_invulnerable:
		is_invulnerable = true

	# Zera a velocidade vertical: o dash é um "corte" limpo no ar.
	velocity = dash_direction * dash_speed
	dashed.emit()


func _process_dash(delta: float) -> void:
	dash_timer -= delta

	# Passo 17: rastro fantasma (afterimage) durante o Dash de Sombra.
	_ghost_timer += delta
	if _ghost_timer >= ghost_interval:
		_ghost_timer = 0.0
		_spawn_ghost()

	# Durante o dash a gravidade é congelada: movimento puramente horizontal.
	if dash_gravity_freeze:
		velocity.y = 0.0
	velocity.x = dash_direction.x * dash_speed

	# Sigilo "selo_serpente": o rastro do dash corrói inimigos (1 de dano).
	if GameState.sigils_equipped.has("selo_serpente"):
		for area in shockwave.get_overlapping_areas():
			if area in _dash_hits:
				continue
			_dash_hits.append(area)
			var target: Node = area.owner if area.owner != null else area.get_parent()
			if target != null and target != self and target.has_method("take_hit"):
				target.take_hit(1, global_position)

	if dash_timer <= 0.0:
		is_invulnerable = false
		# Sair do dash com velocidade moderada para transição suave.
		velocity.x = dash_direction.x * max_speed
		state = State.FALL


## Passo 17: duplica a silhueta de Lúcifer na posição atual e a desvanece.
func _spawn_ghost() -> void:
	if sprite == null:
		return
	var ghost := Sprite2D.new()
	ghost.texture = sprite.texture
	ghost.hframes = sprite.hframes
	ghost.frame = sprite.frame
	ghost.flip_h = sprite.flip_h
	ghost.global_position = sprite.global_position
	ghost.scale = sprite.scale * 1.05
	ghost.modulate = Color(0.7, 0.8, 0.9, ghost_alpha)
	ghost.z_index = -2
	get_parent().add_child(ghost)
	var t := create_tween()
	t.tween_property(ghost, "modulate:a", 0.0, ghost_lifetime).set_trans(Tween.TRANS_EXPO)
	t.parallel().tween_property(ghost, "scale", sprite.scale * 1.3, ghost_lifetime).set_trans(Tween.TRANS_QUAD)
	t.chain().tween_callback(ghost.queue_free)


# ===========================================================================
# COMBATE — LÂMINA DO ALVORECER (Passo 2)
# Ataque em 3 direções + Pogo Strike + Chama Negra
# ===========================================================================
func _start_attack() -> void:
	state = State.ATTACK
	_attack_timer = attack_duration
	_hits_this_swing.clear()

	# Direção do golpe: cima (segurando W/↑), baixo no ar (segurando S/↓), senão frente.
	if Input.is_action_pressed("move_up"):
		_attack_dir = Direction.UP
	elif Input.is_action_pressed("move_down") and not is_on_floor():
		_attack_dir = Direction.DOWN
	else:
		_attack_dir = Direction.NEUTRAL

	_position_hitbox()
	_hitbox_delay_timer = hitbox_active_delay
	_hitbox_active_timer = 0.0


## Reposiciona e redimensiona a hitbox conforme a direção do golpe.
func _position_hitbox() -> void:
	match _attack_dir:
		Direction.UP:
			hitbox.position = Vector2(0.0, -44.0)
			hitbox_shape.size = Vector2(40.0, 48.0)
		Direction.DOWN:
			hitbox.position = Vector2(0.0, 46.0)
			hitbox_shape.size = Vector2(40.0, 48.0)
		_:
			hitbox.position = Vector2(34.0 * facing, 4.0)
			hitbox_shape.size = Vector2(46.0, 36.0)
	# Sigilo "lamina_longa": amplia o alcance horizontal.
	hitbox_shape.size.x *= _sigil_reach


func _process_attack(delta: float) -> void:
	_attack_timer -= delta

	# Momentum reduzido durante o golpe (ataque "pesado").
	velocity.x = move_toward(velocity.x, 0.0, friction * 0.5 * delta)
	if not is_on_floor():
		velocity.y += gravity * delta

	# Janela ativa da hitbox: delay (startup) -> ativa -> desliga.
	if _hitbox_delay_timer > 0.0:
		_hitbox_delay_timer -= delta
		if _hitbox_delay_timer <= 0.0:
			_hitbox_active_timer = hitbox_active_duration
			hitbox.monitoring = true
	elif _hitbox_active_timer > 0.0:
		_hitbox_active_timer -= delta
		_check_melee_hits()
		if _hitbox_active_timer <= 0.0:
			hitbox.monitoring = false

	if _attack_timer <= 0.0:
		hitbox.monitoring = false
		state = State.IDLE if is_on_floor() else State.FALL


## Verifica sobreposições da hitbox: inimigos (take_hit) e perigos (pogo).
func _check_melee_hits() -> void:
	for area in hitbox.get_overlapping_areas():
		if area in _hits_this_swing:
			continue
		_hits_this_swing.append(area)

		var target: Node = area.owner if area.owner != null else area.get_parent()
		var hit_something := false

		if target != null and target.has_method("take_hit"):
			target.take_hit(attack_damage, global_position)
			hit_something = true
		elif area.is_in_group("hazard"):
			## Superfícies de perigo (espinhos) não recebem dano, mas rebatem.
			hit_something = true

		if hit_something:
			_gain_chama(chama_por_golpe)
			AudioManager.sfx("hit")  ## Passo 19: acerto de golpe no inimigo
			CombatManager.hit_stop(false)  ## Passo 20: hit stop no acerto
			CombatManager.camera_shake(2.0, 0.08)  ## Passo 20: tremor leve

			# Passo 17: faíscas no contato + sangue negro dos inimigos.
			var contact := hitbox.global_position
			FxUtil.spawn_sparks(contact, get_parent())
			var is_destructible := area.is_in_group("destructible")
			if not is_destructible and target != null and target.has_method("take_hit"):
				FxUtil.spawn_blood(contact, get_parent())

			# Sigilo "azazel_blade": alcance maior, mas drena vida por golpe.
			if GameState.sigils_equipped.has("azazel_blade"):
				current_health = maxi(current_health - 1, 1)
				health_changed.emit(current_health, max_health)

			# --- POGO STRIKE: golpe para baixo no ar rebate o Lúcifer ---
			if _attack_dir == Direction.DOWN and not is_on_floor():
				velocity.y = pogo_force
				# Passo 16: rebate com uma leve esticada (impulso elástico).
				_apply_squash(true, 0.7)
				# Passo 19: SFX do pogo strike (rebate sonoro da lâmina).
				AudioManager.sfx("pogo")
				# Permite encadear outro pogo imediatamente (estilo HK).
				_hits_this_swing.clear()
				return


# ===========================================================================
# HABILIDADES DE EXPLORAÇÃO (Passo 8)
# Garra do Abismo | Asas Caídas | Macho de Ferro | Sombra de Voo
# ===========================================================================
func _max_jumps() -> int:
	## Asas Caídas: segundo pulo no ar.
	return 2 if GameState.abilities.get("double_jump", false) else max_jumps


func _do_wall_jump() -> void:
	velocity = Vector2(-_wall_dir * wall_jump_x, wall_jump_y)
	facing = -_wall_dir
	jump_buffer_timer = 0.0
	coyote_timer = 0.0
	jumps_left = _max_jumps() - 1  ## Wall jump não consome o pulo aéreo
	state = State.JUMP
	# Passo 16: estica na vertical — impulso da parede.
	_apply_squash(true)


func _process_wall_slide(delta: float) -> void:
	velocity.x = 0.0
	velocity.y = minf(velocity.y + gravity * delta, wall_slide_speed)

	# Passo 19: som de atrito na parede (com cadência).
	_step_timer -= delta
	if _step_timer <= 0.0:
		_step_timer = step_interval
		AudioManager.sfx("wall_slide")

	# Salta da parede (para longe dela).
	if jump_buffer_timer > 0.0:
		_do_wall_jump()
		return

	# Saiu da parede / parou de pressionar o direcional: volta a cair.
	var input_dir := Input.get_axis("move_left", "move_right")
	if _wall_dir == 0 or input_dir != float(_wall_dir):
		state = State.FALL


func _start_ground_pound() -> void:
	state = State.GROUND_POUND
	_gp_hover_timer = gp_hover_time


func _process_ground_pound(delta: float) -> void:
	# Suspensão breve antes de despencar (telegraph do golpe).
	if _gp_hover_timer > 0.0:
		_gp_hover_timer -= delta
		velocity = Vector2.ZERO
		return
	velocity = Vector2(0.0, gp_fall_speed)

	if is_on_floor():
		_ground_pound_impact()


func _ground_pound_impact() -> void:
	# Passo 19: SFX do impacto do Macho de Ferro.
	AudioManager.sfx("ground_pound")
	CombatManager.camera_shake(7.0, 0.25)  ## Passo 20: tremor forte
	CombatManager.hit_stop(true)  ## Passo 20: peso do impacto
	# Passo 16: achatamento forte — peso do impacto no chão.
	_apply_squash(false, 1.3)
	if land_fx:
		land_fx.restart()
	# Passo 17: poeira + faíscas na onda de choque.
	if _dust_fx:
		_dust_fx.restart()
	FxUtil.spawn_sparks(global_position + Vector2(0.0, 26.0), get_parent())

	# Onda de choque: dano em área + quebra de pisos rachados.
	for area in shockwave.get_overlapping_areas():
		var target: Node = area.owner if area.owner != null else area.get_parent()
		if target != null and target != self and target.has_method("take_hit"):
			target.take_hit(gp_damage, global_position)
		if area.is_in_group("gp_breakable") and target != null \
				and target.has_method("smash"):
			target.smash()

	velocity.x = 0.0
	state = State.IDLE if is_on_floor() else State.FALL


func _try_hook() -> bool:
	## Sombra de Voo: conecta ao nó de energia mais próximo dentro do alcance.
	var best: Node2D = null
	var best_dist := hook_range
	for node in get_tree().get_nodes_in_group("hook_point"):
		var n := node as Node2D
		if n == null:
			continue
		var d := global_position.distance_to(n.global_position)
		if d < best_dist:
			best_dist = d
			best = n
	if best == null:
		return false
	_hook_target = best
	_hook_timer = 1.2
	hook_line.visible = true
	state = State.HOOK
	return true


func _process_hook(delta: float) -> void:
	_hook_timer -= delta
	if _hook_target == null or _hook_timer <= 0.0:
		_finish_hook(false)
		return

	var to_target := _hook_target.global_position - global_position
	hook_line.points = PackedVector2Array([Vector2.ZERO, to_target])

	if to_target.length() < 26.0:
		_finish_hook(true)
		return
	velocity = to_target.normalized() * hook_speed


func _finish_hook(connected: bool) -> void:
	if connected and _hook_target != null:
		# Impulso de saída ao alcançar o nó.
		velocity = (_hook_target.global_position - global_position).normalized() \
				* dash_speed * 0.5 + Vector2(0.0, -220.0)
	_hook_target = null
	hook_line.visible = false
	state = State.FALL


## Usado pelo Dreno de Almas de Mammon (Passo 9). Retorna o drenado.
func drain_chama(amount: float) -> float:
	var drained := minf(chama_negra, amount)
	chama_negra -= drained
	chama_changed.emit(chama_negra, chama_max)
	return drained


## Tremor de câmera (impactos do Macho de Ferro, transição do chefe etc.).
## Passo 20: delega ao CombatManager (Perlin + decay + integração com look-ahead).
func shake_camera(intensity: float, duration: float) -> void:
	CombatManager.camera_shake(intensity, duration)


func _update_camera_shake(delta: float) -> void:
	if camera == null:
		return
	# Passo 13: look-ahead — antecipa o movimento para onde Lúcifer olha,
	# com suavização exponencial (funciona como dead zone dinâmica).
	var target := Vector2(facing * 70.0, -24.0)
	_look_offset = _look_offset.lerp(target, 1.0 - pow(0.001, delta))

	# Passo 20: o offset de tremor vem do CombatManager (Perlin + decay),
	# somado ao look-ahead — sem conflito entre os dois sistemas.
	camera.offset = _look_offset + CombatManager.get_shake_offset()


# ===========================================================================
# CHAMA NEGRA — recurso de alma (ganha acertando, gasta curando)
# ===========================================================================
func _gain_chama(amount: float) -> void:
	## Sigilo "chama_rapida": +40% de Chama por golpe.
	var mult := 1.4 if GameState.sigils_equipped.has("chama_rapida") else 1.0
	chama_negra = minf(chama_negra + amount * mult, chama_max)
	chama_changed.emit(chama_negra, chama_max)


func _can_start_heal() -> bool:
	return is_on_floor() \
		and not _is_healing \
		and chama_negra >= heal_cost \
		and current_health < max_health \
		and (state == State.IDLE or state == State.WALK)


func _start_heal() -> void:
	_is_healing = true
	_heal_channel_timer = heal_channel_time
	# Passo 19: dreno da Chama Negra ao iniciar a canalização da cura.
	AudioManager.sfx("chama_drain")


func _process_heal_channel(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	_heal_channel_timer -= delta

	# Interrompe se soltar o botão ou sair do chão.
	if Input.is_action_just_released("heal") or not is_on_floor():
		_cancel_heal()
	elif _heal_channel_timer <= 0.0:
		_complete_heal()


func _complete_heal() -> void:
	_is_healing = false
	chama_negra = maxf(chama_negra - heal_cost, 0.0)
	current_health = mini(current_health + heal_amount, max_health)
	chama_changed.emit(chama_negra, chama_max)
	health_changed.emit(current_health, max_health)
	# Passo 19: som de conclusão da cura.
	AudioManager.sfx("heal")


func _cancel_heal() -> void:
	_is_healing = false


# ===========================================================================
# DANO — Hurtbox do Lúcifer (chamado por inimigos e superfícies de perigo)
# ===========================================================================
func take_damage(amount: int, source_position: Vector2 = Vector2(1e9, 1e9)) -> void:
	if is_invulnerable or _iframes_timer > 0.0:
		return

	# --- POSTURA PARRY: bloqueio no timing exato reflete o golpe ---
	if _parry_timer > 0.0:
		_parry_timer = 0.0
		_iframes_timer = 0.25
		AudioManager.sfx("parry")
		CombatManager.hit_stop(true)  ## Freeze frame do reflexo perfeito
		CombatManager.camera_shake(5.0, 0.2)  ## Tremor do reflexo
		# Contra-golpe: stagger nos inimigos ao alcance da lâmina.
		for area in shockwave.get_overlapping_areas():
			var target: Node = area.owner if area.owner != null else area.get_parent()
			if target != null and target != self and target.has_method("take_hit"):
				target.take_hit(2, global_position)
		return

	# Sigilo "marca_mammon": inimigos causam o dobro de dano em Lúcifer.
	if GameState.sigils_equipped.has("marca_mammon"):
		amount *= 2

	current_health = maxi(current_health - amount, 0)
	_iframes_timer = iframes_duration
	damaged.emit(amount)
	health_changed.emit(current_health, max_health)
	_cancel_heal()
	CombatManager.hit_stop(false)  ## Passo 20: peso ao sofrer dano
	CombatManager.camera_shake(4.0, 0.2)  ## Passo 20: tremor ao tomar golpe

	# Knockback na direção oposta à fonte do dano.
	var dir := signf(global_position.x - source_position.x)
	if dir == 0.0:
		dir = -float(facing)
	velocity = Vector2(dir * damage_knockback_force, -damage_knockback_force * 0.6)

	if current_health <= 0:
		died.emit()  ## Passo 4: respawn no último Ponto de Descanso
		GameState.respawn_player()


## Cura direta (bancos, bênçãos de loja, frascos futuros).
func heal(amount: int) -> void:
	if current_health <= 0:
		return
	current_health = mini(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)


## Passo 5: gasto de moedas em lojas. Retorna false se não tiver saldo.
func spend_pratas(amount: int) -> bool:
	if pratas_de_judas < amount:
		return false
	pratas_de_judas -= amount
	pratas_changed.emit(pratas_de_judas)
	return true


# ===========================================================================
# PASSO 6: SIGILOS DO BANIMENTO — modificadores equipados em tempo real
# ===========================================================================
var _sigil_reach: float = 1.0    ## "lamina_longa": alcance da lâmina
var _sigil_coin: float = 1.0     ## "moeda_extra": rendimento das Pratas


func apply_sigils() -> void:
	var eq: Array = GameState.sigils_equipped
	# "lamina_longa" (1.35) tem prioridade sobre "azazel_blade" (1.25).
	_sigil_reach = 1.35 if eq.has("lamina_longa") \
			else (1.25 if eq.has("azazel_blade") else 1.0)
	# "moeda_extra" (+50%) e "marca_mammon" (+50%) acumulam até 2.0x.
	_sigil_coin = 1.0 + (0.5 if eq.has("moeda_extra") else 0.0) \
			+ (0.5 if eq.has("marca_mammon") else 0.0)
	max_health = 5 + (1 if eq.has("coracao_extra") else 0)
	current_health = mini(current_health, max_health)
	health_changed.emit(current_health, max_health)


# ===========================================================================
# ECONOMIA — Pratas de Judas (Passo 3)
# ===========================================================================
var pratas_de_judas: int = 0  ## Bolsa do Lúcifer (moeda de Aeterna)


## Chamado pela PrataDeJudas ao ser coletada.
func collect_pratas(amount: int) -> void:
	pratas_de_judas += int(round(amount * _sigil_coin))
	pratas_changed.emit(pratas_de_judas)
	coin_collected.emit()


## Restaura o snapshot do Lúcifer após uma transição de sala
## (futuramente também usado pelo Load do Passo 4).
func apply_state(data: Dictionary) -> void:
	if data.is_empty():
		return
	current_health = int(data.get("health", current_health))
	max_health = int(data.get("max_health", max_health))
	chama_negra = float(data.get("chama", chama_negra))
	pratas_de_judas = int(data.get("pratas", pratas_de_judas))
	apply_sigils()  ## Recalcula modificadores dos Sigilos equipados
	health_changed.emit(current_health, max_health)
	chama_changed.emit(chama_negra, chama_max)
	pratas_changed.emit(pratas_de_judas)


# ===========================================================================
# PASSO 16: VISUAIS FLUIDOS — Squash & Stretch + Rotational Lean
# (animações reais chegam junto com o AnimationPlayer no Passo 3)
# ===========================================================================
func _update_visuals(delta: float) -> void:
	# Passo "animação": troca a animação conforme a FSM.
	var anim := "idle"
	match state:
		State.WALK:
			anim = "walk"
		State.JUMP:
			anim = "jump"
		State.FALL:
			anim = "fall"
		State.DASH:
			anim = "dash"
		State.ATTACK:
			anim = "attack"
		_:
			anim = "idle"
	if anim_player and anim_player.has_animation(anim) \
			and anim_player.current_animation != anim:
		anim_player.play(anim)

	if sprite:
		sprite.flip_h = facing < 0

		# --- SQUASH & STRETCH: deformação suavizada (elástica, estilo HK) ---
		# A escala deformada converge de volta ao normal a cada frame renderizado.
		_squash_scale = _squash_scale.lerp(Vector2.ONE, 1.0 - pow(0.001, delta * squash_speed))
		sprite.scale = _sprite_base_scale * _squash_scale

		# --- ROTATIONAL LEAN: inclinação dinâmica ao acelerar/frear/mudar de direção ---
		sprite.rotation = _compute_lean(delta)

		# I-frames: pisca em transparente (estilo Hollow Knight).
		if _iframes_timer > 0.0:
			sprite.modulate.a = 0.4 if fmod(_iframes_timer, 0.16) < 0.08 else 0.9
		# Postura Parry: brilho frio durante a janela de reflexo.
		elif _parry_timer > 0.0:
			sprite.modulate = Color(1.8, 1.8, 2.4, 1.0)
		# Canalizando cura: brilho dourado.
		elif _is_healing:
			sprite.modulate = Color(1.5, 1.3, 0.7, 1.0)
		else:
			sprite.modulate = Color.WHITE


## Passo 16: dispara uma deformação Squash & Stretch no sprite.
##   stretch=true  → estica na vertical (pulo/pogo/wall jump); com horizontal=true estica na horizontal (dash).
##   stretch=false → achata na horizontal (aterrissagem/ground pound).
##   intensity_scale multiplica a intensidade base (queda alta, impacto forte, etc.).
func _apply_squash(stretch: bool, intensity_scale: float = 1.0, horizontal: bool = false) -> void:
	var s := squash_intensity * clampf(intensity_scale, 0.25, 1.5)
	if horizontal:
		_squash_scale = Vector2(1.0 + s, 1.0 - s)   ## Estica na horizontal (dash)
	elif stretch:
		_squash_scale = Vector2(1.0 - s, 1.0 + s)   ## Estica na vertical (impulso)
	else:
		_squash_scale = Vector2(1.0 + s, 1.0 - s)   ## Achata na horizontal (impacto)


## Passo 16: calcula a inclinação suavizada do sprite (Rotational Lean).
##   Acelerando   → inclina para a frente (sentido do facing).
##   Freando/mudança brusca/sem input com velocidade → inclina para trás.
##   Dash usa a inclinacao dedicada (lean_dash_tilt).
func _compute_lean(delta: float) -> float:
	var lean_target := 0.0
	if state == State.DASH:
		lean_target = -lean_dash_tilt * facing
	elif _is_healing or state == State.GROUND_POUND or state == State.WALL_SLIDE:
		lean_target = 0.0  ## Posturas fixas nao inclinam
	else:
		var input_dir := Input.get_axis("move_left", "move_right")
		var vel_dir := signf(velocity.x) if absf(velocity.x) > 20.0 else 0.0
		# Fator 0..1 conforme a velocidade real (para a inclinacao "crescer" suave).
		var speed_factor := clampf(absf(velocity.x) / max_speed, 0.0, 1.0)
		if input_dir != 0.0:
			if vel_dir == 0.0 or vel_dir == signf(input_dir):
				lean_target = -lean_intensity * facing * speed_factor  ## Acelerando -> frente
			else:
				lean_target = lean_intensity * facing * speed_factor   ## Mudanca brusca -> tras
		elif speed_factor > 0.06:
			lean_target = lean_intensity * facing * speed_factor       ## Derrapagem -> tras
	_lean_angle = lerpf(_lean_angle, lean_target, 1.0 - pow(0.001, delta * lean_speed))
	return _lean_angle





# ===========================================================================
# [TECH ART] PASSO 19: CHAMA NEGRA - luz emissiva que brilha con bloom
# ===========================================================================
## Sincroniza la luz PointLight2D "ChamaNegra" com el valor de chama_negra.
## - visible solo hay chama suficiente (más de ~5% del máximo)
## - intensidad (energy) proporcional al porcentaje de chama
## - color se calienta al cargar (rojo/ámbar) y se enfría al gastar (negro)
## Conectado al LightingManager que multiplica la energía con emissive_boost.
func _update_chama_visual() -> void:
	if chama_light == null:
		return
	var pct := chama_negra / chama_max  ## 0.0 .. 1.0
	chama_light.visible = pct > 0.05
	chama_light.energy = lerpf(0.0, 2.8, pct * pct)  ## curva gamma: brilha mais no final
	## El color va de negro frío (vacío) a rojo/ámbar (chama viva).
	var cold := Color(0.3, 0.15, 0.08)
	var hot := Color(0.95, 0.65, 0.2)
	chama_light.color = cold.lerp(hot, pct)

