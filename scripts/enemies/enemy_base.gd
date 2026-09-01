class_name EnemyBase
extends CharacterBody2D
## ============================================================================
## [ARCANJO CAIDO] — Passo 3: Classe base de todos os inimigos de Aeterna.
## ----------------------------------------------------------------------------
## - Vida, dano recebido (take_hit), knockback e flash vermelho
## - IA com FSM: PATROL -> CHASE -> ATTACK (com HURT/DEAD como interrupções)
## - Morte instancia o loot (Pratas de Judas) que voa até o Lúcifer
## Inimigos concretos (Guardião Caído etc.) estendem esta classe e ajustam
## os valores exportados na cena.
## ============================================================================

signal health_changed(current_hp: int, maximum_hp: int)
signal enemy_died(enemy: EnemyBase)

enum AIState { PATROL, CHASE, ATTACK, HURT, DEAD }

# ---------------------------------------------------------------------------
# ATRIBUTOS (ajustáveis no inspetor por inimigo)
# ---------------------------------------------------------------------------
@export_group("Vida")
@export var max_hp: int = 20
@export var flash_duration: float = 0.15
@export var hurt_stagger_time: float = 0.25    ## Tempo "atordoado" ao tomar golpe

@export_group("Movimento")
@export var move_speed: float = 90.0           ## Velocidade de patrulha
@export var chase_speed: float = 190.0         ## Velocidade de perseguição
@export var patrol_distance: float = 160.0     ## Meia-largura da patrulha (px)
@export var gravity: float = 2000.0
@export var knockback_force: float = 240.0     ## Repulsão ao tomar golpe

@export_group("Combate")
@export var attack_damage: int = 1
@export var detection_radius: float = 260.0    ## Raio de visão do jogador
@export var attack_range: float = 46.0         ## Distância para iniciar o ataque
@export var attack_windup: float = 0.35        ## "Telegraph" antes do golpe (s)
@export var attack_cooldown: float = 1.1       ## Pausa entre golpes (s)
@export var lunge_speed: float = 260.0         ## Impulso para frente no golpe

@export_group("Loot")
@export var loot_scene: PackedScene            ## Cena da Prata de Judas
@export var loot_amount: int = 3

@export_group("Otimização (Passo 14)")
@export var cull_distance: float = 1400.0      ## IA congelada além desta distância

# ---------------------------------------------------------------------------
# ESTADO
# ---------------------------------------------------------------------------
var hp: int
var ai_state: AIState = AIState.PATROL
var facing: int = 1
var start_position: Vector2 = Vector2.ZERO
var _flash_timer: float = 0.0
var _stagger_timer: float = 0.0
var _windup_timer: float = 0.0
var _cooldown_timer: float = 0.0
var _player: Node2D = null

@onready var visual: CanvasItem = $Visual
@onready var attack_area: Area2D = $AttackArea

func _ready() -> void:
	hp = max_hp
	start_position = global_position


func _physics_process(delta: float) -> void:
	# Gravidade (queda com velocidade terminal).
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, 1300.0)

	_flash_timer = maxf(_flash_timer - delta, 0.0)
	if _flash_timer <= 0.0 and ai_state != AIState.DEAD:
		visual.modulate = Color.WHITE

	# Cache do jogador (grupo "player").
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")

	# Passo 14: CULLING — congela a IA fora do alcance da câmera/jogador
	# (economiza CPU com dezenas de inimigos em salas grandes).
	if _player and global_position.distance_to(_player.global_position) > cull_distance:
		velocity.x = 0.0
		if not is_on_floor():
			velocity.y = minf(velocity.y + gravity * delta, 1300.0)
		move_and_slide()
		return

	_cooldown_timer = maxf(_cooldown_timer - delta, 0.0)

	match ai_state:
		AIState.PATROL:
			_process_patrol()
		AIState.CHASE:
			_process_chase()
		AIState.ATTACK:
			_process_attack(delta)
		AIState.HURT:
			_process_hurt(delta)
		AIState.DEAD:
			pass

	# Área de ataque acompanha a direção que o inimigo está olhando.
	attack_area.position.x = absf(attack_area.position.x) * facing

	move_and_slide()
	## Flip preservando a escala da arte (Sprite2D ou ColorRect).
	visual.scale.x = absf(visual.scale.x) * float(facing)


# ===========================================================================
# IA — MÁQUINA DE ESTADOS
# ===========================================================================
func _process_patrol() -> void:
	velocity.x = facing * move_speed

	# Vira nos limites da patrulha ou ao bater numa parede.
	var too_far := absf(global_position.x - start_position.x) > patrol_distance
	if too_far or is_on_wall():
		facing *= -1
		global_position.x += facing * 2.0

	# Detecta o jogador e parte para a perseguição.
	if _player and _can_see_player():
		ai_state = AIState.CHASE


func _process_chase() -> void:
	if _player == null:
		ai_state = AIState.PATROL
		return

	var dist := global_position.distance_to(_player.global_position)

	# Perdeu o jogador de vista: volta a patrulhar.
	if dist > detection_radius * 1.6:
		ai_state = AIState.PATROL
		return

	# Encara o jogador e persegue.
	facing = 1 if _player.global_position.x > global_position.x else -1
	velocity.x = facing * chase_speed

	# Perto o suficiente: prepara o golpe (se o cooldown permitiu).
	if dist <= attack_range and _cooldown_timer <= 0.0:
		ai_state = AIState.ATTACK
		_windup_timer = attack_windup
		velocity.x = 0.0


func _process_attack(delta: float) -> void:
	## Telegraph: para no lugar "carregando" o golpe, depois avança e acerta.
	velocity.x = 0.0
	_windup_timer -= delta
	if _windup_timer <= 0.0:
		_perform_attack_hit()
		velocity.x = facing * lunge_speed  ## Pequena investida
		_cooldown_timer = attack_cooldown
		ai_state = AIState.CHASE


func _process_hurt(delta: float) -> void:
	## Atordoado: sem controle, o knockback decide o movimento.
	_stagger_timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, knockback_force * 6.0 * delta)
	if _stagger_timer <= 0.0:
		ai_state = AIState.CHASE if _player and _can_see_player() else AIState.PATROL


func _can_see_player() -> bool:
	## Visão simples por distância (linha de visão refinada no Passo 4+).
	return global_position.distance_to(_player.global_position) <= detection_radius


## Gancho virtual para inimigos específicos customizarem o efeito do golpe.
func _perform_attack_hit() -> void:
	for body in attack_area.get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(attack_damage, global_position)


# ===========================================================================
# DANO, KNOCKBACK E MORTE
# ===========================================================================
## Chamado pela MeleeHitbox do Lúcifer (via Hurtbox, grupo "hurtbox").
func take_hit(damage: int, from_position: Vector2) -> void:
	if ai_state == AIState.DEAD:
		return

	hp = maxi(hp - damage, 0)
	health_changed.emit(hp, max_hp)

	# Flash vermelho de dano.
	visual.modulate = Color(3.0, 0.5, 0.5)
	_flash_timer = flash_duration

	# Knockback na direção oposta ao golpe.
	var dir := signf(global_position.x - from_position.x)
	if dir == 0.0:
		dir = -float(facing)
	velocity = Vector2(dir * knockback_force, -knockback_force * 0.4)

	if hp <= 0:
		_die()
	else:
		ai_state = AIState.HURT
		_stagger_timer = hurt_stagger_time


func _die() -> void:
	ai_state = AIState.DEAD
	enemy_died.emit(self)
	_spawn_loot()
	queue_free()


func _spawn_loot() -> void:
	if loot_scene == null:
		return
	## Passo 12: explosão de partículas douradas ao morrer.
	var burst := CPUParticles2D.new()
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.amount = 16
	burst.lifetime = 0.5
	burst.direction = Vector2(0, -1)
	burst.spread = 180.0
	burst.gravity = Vector2(0, 400)
	burst.initial_velocity_min = 120.0
	burst.initial_velocity_max = 260.0
	burst.scale_amount_min = 2.0
	burst.scale_amount_max = 4.0
	burst.color = Color(1.0, 0.8, 0.3, 0.9)
	burst.global_position = global_position
	burst.emitting = true
	get_parent().add_child(burst)
	get_tree().create_timer(1.0).timeout.connect(burst.queue_free)

	for i in loot_amount:
		var coin: Node2D = loot_scene.instantiate()
		coin.global_position = global_position + Vector2(randf_range(-12.0, 12.0), -12.0)
		coin.velocity = Vector2(randf_range(-130.0, 130.0), randf_range(-280.0, -150.0))
		get_parent().add_child(coin)
