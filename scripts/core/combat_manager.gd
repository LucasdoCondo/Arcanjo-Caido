extends Node
## ============================================================================
## [ARCANJO CAIDO] — Autoload: CombatManager (Passo 20)
## ----------------------------------------------------------------------------
## Gerenciador de polimento de combate (Game Feel/Impact):
##   - Hit Stop / Freeze Frame: pausa o jogo ao acertar inimigos
##   - Camera Shake: tremor com Perlin noise e decay exponencial
##   - Flash White: material override nos inimigos ao receber golpe
## ⚠️ COMO USAR:
##   - CombatManager.hit_stop() ao acertar inimigo
##   - CombatManager.camera_shake(intensity, duration) ao causar impacto
##   - EnemyBase.take_hit() já chama flash_white automaticamente
## ============================================================================

## Durações do Hit Stop (em segundos)
const HIT_STOP_LIGHT := 0.04   ## Golpe básico
const HIT_STOP_HEAVY := 0.08   ## Crítico / abate

## Valores padrão de Camera Shake
const SHAKE_DEFAULT_INTENSITY := 4.0
const SHAKE_DEFAULT_DURATION := 0.2

var _hit_stop_timer: float = 0.0
var _shake_timer: float = 0.0
var _shake_intensity: float = 0.0
var _shake_duration: float = 0.0
var _shake_seed: float = 0.0
var _shake_offset: Vector2 = Vector2.ZERO  ## Offset calculado (consumido pelo PlayerController)
var _camera: Camera2D = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	# Hit Stop: controla o time scale
	if _hit_stop_timer > 0.0:
		_hit_stop_timer -= delta
		if _hit_stop_timer <= 0.0:
			Engine.time_scale = 1.0

	# Camera Shake: CALCULA o offset com Perlin noise e decay exponencial.
	# NOTA: nao aplicamos direto em _camera.offset aqui - o PlayerController
	# soma get_shake_offset() ao look-ahead (sem conflito entre os sistemas).
	if _shake_timer > 0.0:
		_shake_timer -= delta
		var progress := 1.0 - (_shake_timer / _shake_duration)
		var decay := pow(2.0, -3.0 * progress)  # Decay exponencial suave
		var offset_x := _perlin_noise(_shake_seed, progress * 5.0) * _shake_intensity * decay
		var offset_y := _perlin_noise(_shake_seed + 100.0, progress * 5.0) * _shake_intensity * decay
		_shake_offset = Vector2(offset_x, offset_y)
		if _shake_timer <= 0.0:
			_shake_offset = Vector2.ZERO


## Retorna o offset de tremor calculado no _process (Perlin + decay).
## O PlayerController soma este valor ao look-ahead da camera.
func get_shake_offset() -> Vector2:
	return _shake_offset


# ---------------------------------------------------------------------------
# PASSO 20: HIT STOP / FREEZE FRAME
# ---------------------------------------------------------------------------
## Pausa o jogo por alguns milissegundos ao acertar um inimigo.
## Parâmetro heavy: se true, pausa mais (crítico/abate).
func hit_stop(heavy: bool = false) -> void:
	## Chamado ao acertar um inimigo.
	## Exemplo: CombatManager.hit_stop() para golpe normal
	##          CombatManager.hit_stop(true) para crítico/abate
	Engine.time_scale = 0.0001
	_hit_stop_timer = HIT_STOP_HEAVY if heavy else HIT_STOP_LIGHT


# ---------------------------------------------------------------------------
# PASSO 20: CAMERA SHAKE
# ---------------------------------------------------------------------------
## Tremor de câmera com Perlin noise e decay exponencial.
## Parâmetros:
##   - intensity: força do tremor (px). Leve=2, Médio=5, Forte=8
##   - duration: duração em segundos
func camera_shake(intensity: float = SHAKE_DEFAULT_INTENSITY, duration: float = SHAKE_DEFAULT_DURATION) -> void:
	## Chamado ao causar impacto significativo.
	## Exemplo: CombatManager.camera_shake(2.0, 0.15) para golpe leve
	##          CombatManager.camera_shake(6.0, 0.3) para ground pound
	##          CombatManager.camera_shake(8.0, 0.4) para abate
	_shake_intensity = intensity
	_shake_duration = duration
	_shake_timer = duration
	_shake_seed = randf() * 1000.0
	# Cache da câmera do jogador
	if _camera == null:
		var player := get_tree().get_first_node_in_group("player")
		if player:
			_camera = player.get_node_or_null("Camera2D")


# ---------------------------------------------------------------------------
# Perlin Noise (implementação simples para shake orgânico)
# ---------------------------------------------------------------------------
static func _perlin_noise(seed: float, t: float) -> float:
	## Noise 1D baseado em senoides combinadas (aproximação de Perlin).
	var n := 0.0
	n += sin(t * 2.1 + seed) * 0.5
	n += sin(t * 4.7 + seed * 1.3) * 0.25
	n += sin(t * 9.3 + seed * 1.7) * 0.125
	return clampf(n, -1.0, 1.0)