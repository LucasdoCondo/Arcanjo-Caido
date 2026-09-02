class_name MammonBoss
extends CharacterBody2D
## ============================================================================
## [ARCANJO CAIDO] — Passo 9: MAMMON, O INGESTIONÁVEL (Chefe Final)
## ----------------------------------------------------------------------------
## FASE 1 — O Rei de Ouro: fixo no trono.
##   * Golpe de Braços: braços gigantes castigam o chão, gerando ondas de
##     choque rasteiras em ambas as direções.
##   * Chuva de Moedas: moedas incandescentes caem do teto em posições
##     aleatórias da arena.
## TRANSIÇÃO (50% de vida): o trono se desfaz, a câmera treme e Mammon
##   revela sua verdadeira forma.
## FASE 2 — Avatar da Avareza: criatura móvel.
##   * Investida rápida em direção ao Lúcifer.
##   * Chuva de Lingotes pesados que cobrem a arena.
##   * DRENO DE ALMAS: fica perto e parado por muito tempo e a Chama Negra
##     é sugada.
## ============================================================================

signal boss_died

enum Phase { TRONO, TRANSICAO, AVATAR }

const BOSS_NAME := "MAMMON, O INGESTIONÁVEL"

@export_group("Vida")
@export var max_hp: int = 60
@export var contact_damage: int = 1

@export_group("Cenas")
@export var shockwave_scene: PackedScene   ## onda_de_choque.tscn
@export var falling_hazard_scene: PackedScene  ## moeda_incandescente.tscn (Fase 1)
@export var ingot_scene: PackedScene       ## lingote.tscn (Fase 2)
@export var loot_scene: PackedScene        ## prata_judas.tscn

@export_group("Arena")
@export var arena_min_x: float = 150.0
@export var arena_max_x: float = 1450.0
@export var floor_y: float = 720.0
@export var ceiling_y: float = 80.0
@export var activation_range: float = 550.0

@export_group("Fase 2 — Avatar")
@export var charge_speed: float = 720.0
@export var charge_duration: float = 0.45
@export var drain_radius: float = 150.0
@export var drain_rate: float = 25.0       ## Chama Negra drenada por segundo
@export var drain_delay: float = 0.8       ## Tempo parado antes de começar a drenar

var hp: int
var phase: int = Phase.TRONO
var _active: bool = false
var _pattern_timer: float = 1.6
var _use_slam: bool = true
var _burst_count: int = 0
var _burst_timer: float = 0.0
var _burst_heavy: bool = false
var _charge_dir: int = 1
var _charge_timer: float = 0.0
var _drain_time: float = 0.0
var _flash_timer: float = 0.0
var _player: Node2D = null
var _bar: CanvasLayer = null

@onready var visual: CanvasItem = $Visual
@onready var throne: ColorRect = $Throne
@onready var contact_area: Area2D = $ContactArea

func _ready() -> void:
	hp = max_hp
	FxUtil.apply_flat_normal(visual)  ## Passo 15: profundidade sob as luzes da Catedral
	_bar = preload("res://scripts/ui/boss_health_bar.gd").new()
	add_child(_bar)


func _physics_process(delta: float) -> void:
	# Flash de dano.
	_flash_timer -= delta
	if _flash_timer <= 0.0 and phase != Phase.TRANSICAO:
		visual.modulate = Color.WHITE

	if _player == null:
		_player = get_tree().get_first_node_in_group("player")

	# Luta só começa quando o Lúcifer se aproxima do trono.
	if not _active:
		if _player and global_position.distance_to(_player.global_position) < activation_range:
			_activate()
		return

	match phase:
		Phase.TRONO:
			_process_trono(delta)
		Phase.TRANSICAO:
			_process_transicao(delta)
		Phase.AVATAR:
			_process_avatar(delta)

	move_and_slide()


# ===========================================================================
# FASE 1 — O REI DE OURO
# ===========================================================================
func _activate() -> void:
	_active = true
	_bar.setup(max_hp, hp)
	_bar.show_fight(BOSS_NAME)
	## Passo 11: crossfade para a trilha da arena de chefe.
	AudioManager.play_music("boss")


func _process_trono(delta: float) -> void:
	velocity = Vector2.ZERO  ## Fundido ao trono: imóvel

	# Chuva contínua enquanto houver rajada pendente.
	_process_burst(delta)

	_pattern_timer -= delta
	if _pattern_timer > 0.0:
		return

	# Alterna os dois padrões da Fase 1.
	if _use_slam:
		visual.modulate = Color(2.5, 2.0, 0.8)  ## Telegraph dourado
		_flash_timer = 0.3
		_spawn_shockwaves()
		_pattern_timer = 2.2
	else:
		_burst_heavy = false
		_burst_count = 6
		_burst_timer = 0.0
		_pattern_timer = 2.8
	_use_slam = not _use_slam


func _process_burst(delta: float) -> void:
	if _burst_count <= 0:
		return
	_burst_timer -= delta
	if _burst_timer <= 0.0:
		_spawn_falling(_burst_heavy)
		_burst_count -= 1
		_burst_timer = 0.18


# ===========================================================================
# TRANSIÇÃO — O TRONO SE DESFAZ
# ===========================================================================
var transition_timer: float = 1.6


func _start_transition() -> void:
	phase = Phase.TRANSICAO
	velocity = Vector2.ZERO
	_burst_count = 0
	if _player and _player.has_method("shake_camera"):
		_player.shake_camera(8.0, 1.4)  ## A arena treme


func _process_transicao(delta: float) -> void:
	## Invulnerável durante a revelação da verdadeira forma.
	var t := fmod(Time.get_ticks_msec() / 1000.0, 0.3)
	visual.modulate = Color(2.0, 0.6, 0.6) if t < 0.15 else Color(1.5, 1.2, 0.4)
	transition_timer -= delta
	if transition_timer <= 0.0:
		phase = Phase.AVATAR
		throne.visible = false          ## O trono quebrou
		visual.self_modulate = Color(0.55, 0.42, 0.16)  ## Fase 2: ouro escurecido
		_pattern_timer = 1.2
		visual.modulate = Color.WHITE


# ===========================================================================
# FASE 2 — AVATAR DA AVAREZA
# ===========================================================================
func _process_avatar(delta: float) -> void:
	# Gravidade: agora Mammon é uma criatura terrestre.
	if not is_on_floor():
		velocity.y = minf(velocity.y + 2000.0 * delta, 1300.0)

	_process_burst(delta)
	_process_drain(delta)

	# Investida em andamento.
	if _charge_timer > 0.0:
		_charge_timer -= delta
		velocity.x = _charge_dir * charge_speed
		if _charge_timer <= 0.0:
			velocity.x = 0.0
			_pattern_timer = 1.1
	else:
		velocity.x = 0.0
		_pattern_timer -= delta
		if _pattern_timer <= 0.0:
			_choose_avatar_attack()

	# Dano por contato durante a Fase 2.
	for body in contact_area.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(contact_damage, global_position)


func _choose_avatar_attack() -> void:
	var roll := randi() % 3
	if roll == 0:
		# Investida rápida em direção ao Lúcifer.
		if _player:
			_charge_dir = 1 if _player.global_position.x > global_position.x else -1
		else:
			_charge_dir = 1
		_charge_timer = charge_duration
		visual.modulate = Color(2.5, 2.0, 0.8)
		_flash_timer = 0.25
		if _player and _player.has_method("shake_camera"):
			_player.shake_camera(4.0, 0.2)  ## Passo 13: aviso da investida
	elif roll == 1:
		_burst_heavy = true
		_burst_count = 8
		_burst_timer = 0.0
		_pattern_timer = 2.4
	else:
		_spawn_shockwaves()
		_pattern_timer = 2.0


func _process_drain(delta: float) -> void:
	## DRENO DE ALMAS: Lúcifer parado e perto demais tem a Chama Negra sugada.
	if _player == null or not _player.has_method("drain_chama"):
		return
	var near := global_position.distance_to(_player.global_position) < drain_radius
	var still := _player.velocity.length() < 40.0
	if near and still:
		_drain_time += delta
		if _drain_time >= drain_delay:
			_player.drain_chama(drain_rate * delta)
			visual.modulate = Color(1.8, 1.2, 2.2)  ## Tinta de drenagem
	else:
		_drain_time = 0.0


# ===========================================================================
# PROJÉTEIS
# ===========================================================================
func _spawn_shockwaves() -> void:
	if shockwave_scene == null:
		return
	if _player and _player.has_method("shake_camera"):
		_player.shake_camera(5.0, 0.25)  ## Passo 13: impacto dos braços
	for dir in [-1, 1]:
		var wave: Area2D = shockwave_scene.instantiate()
		wave.global_position = Vector2(global_position.x + dir * 90.0, floor_y - 12.0)
		wave.direction = dir
		get_parent().add_child(wave)


func _spawn_falling(heavy: bool) -> void:
	var scene := ingot_scene if heavy else falling_hazard_scene
	if scene == null:
		return
	var p: Area2D = scene.instantiate()
	p.global_position = Vector2(randf_range(arena_min_x, arena_max_x), ceiling_y)
	p.setup(heavy, Vector2(randf_range(-40.0, 40.0), 100.0))
	get_parent().add_child(p)


# ===========================================================================
# DANO E MORTE
# ===========================================================================
func take_hit(damage: int, from_position: Vector2) -> void:
	if not _active:
		_activate()
	if phase == Phase.TRANSICAO:
		return  ## Invulnerável durante a transição

	hp = maxi(hp - damage, 0)
	_bar.set_hp(hp)
	visual.modulate = Color(3.0, 2.4, 0.8)
	_flash_timer = 0.12
	GameState.hit_stop(0.04, 0.1)  ## Passo 13: peso ao ferir o chefe

	if hp <= 0:
		_die()
	elif phase == Phase.TRONO and hp <= max_hp / 2:
		_start_transition()


func _die() -> void:
	_bar.hide_fight()
	boss_died.emit()
	Achievements.unlock("mammon_slain")
	## Passo 22: registra a condição do Final Padrão e leva aos Créditos
	## após a chuva de Pratas (tempo de ver o loot e a queda da Avareza).
	## O FINAL VERDADEIRO (recusar o trono) é acionado por uma escolha de
	## diálogo/quest futura chamando: GameState.request_ending("verdadeiro")
	GameState.flags["mammon_defeated"] = true
	get_tree().create_timer(6.0).timeout.connect(
			func(): GameState.request_ending("padrao"))
	## Volta para a trilha da região após a queda da Avareza.
	AudioManager.play_music("catedral_avareza")
	## A avareza se desfaz: chuva de Pratas de Judas.
	if loot_scene:
		for i in 15:
			var coin: Node2D = loot_scene.instantiate()
			coin.global_position = global_position + Vector2(randf_range(-40, 40), -20)
			coin.velocity = Vector2(randf_range(-200, 200), randf_range(-350, -150))
			get_parent().add_child(coin)
	queue_free()
