extends Node
## ============================================================================
## [ARCANJO CAIDO] — Autoload: Culling (Passo 21)
## ----------------------------------------------------------------------------
## Sistema de Culling 2D baseado na AREA VISIVEL da camera ativa.
## Qualquer Node pode entrar no grupo "cullable" (via add_to_group no _ready
## ou no editor) e sera automaticamente gerenciado:
##   - Fora da tela (+ margem): _process e _physics_process sao desligados,
##     particulas param de emitir, e os hooks opcionais sao chamados.
##   - Dentro da tela: tudo e religado.
## Hooks opcionais que o node pode implementar (chamados pelo manager):
##   - on_culled()   : para animacoes/AudioStreamPlayer/tweens antes do freeze
##   - on_unculled() : retoma o que estava pausado
## 100% offline e sem custo de rede. Otimizacao para 60 FPS+ em salas grandes.
## ============================================================================

const SCAN_INTERVAL := 0.15          ## Segundos entre varreduras da cena
const MARGIN := 180.0                ## Margem extra alem da borda da tela (px)
const GROUP := "cullable"

var _scan_timer := 0.0
var _state: Dictionary = {}          ## instance_id -> bool (true = culled)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	_scan_timer -= delta
	if _scan_timer > 0.0:
		return
	_scan_timer = SCAN_INTERVAL
	_scan()


func _scan() -> void:
	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam == null:
		## Sem camera ativa (menu, loading): reativa tudo.
		for n in get_tree().get_nodes_in_group(GROUP):
			_set_culled(n, false)
		return

	var center: Vector2 = cam.get_screen_center_position()
	var view_size: Vector2 = cam.get_viewport_rect().size / cam.zoom
	var half := view_size * 0.5 + Vector2(MARGIN, MARGIN)

	for n in get_tree().get_nodes_in_group(GROUP):
		if not is_instance_valid(n):
			continue
		var pos := Vector2.ZERO
		if n is Node2D:
			pos = (n as Node2D).global_position
		var inside := absf(pos.x - center.x) <= half.x and absf(pos.y - center.y) <= half.y
		_set_culled(n, not inside)


func _set_culled(n: Node, culled: bool) -> void:
	var key: int = n.get_instance_id()
	if _state.has(key) and _state[key] == culled:
		return
	_state[key] = culled

	if culled:
		if n.has_method("on_culled"):
			n.call("on_culled")
		n.set_process(false)
		n.set_physics_process(false)
		## Desliga emissores de particulas (CPUParticles2D / GPUParticles2D).
		for child in n.find_children("*", "CPUParticles2D", true, false):
			(child as CPUParticles2D).emitting = false
		for child in n.find_children("*", "GPUParticles2D", true, false):
			(child as GPUParticles2D).emitting = false
	else:
		if n.has_method("on_unculled"):
			n.call("on_unculled")
		n.set_process(true)
		n.set_physics_process(true)


## [API] Utility: adiciona um node ao grupo gerenciado (idempotente).
static func register(n: Node) -> void:
	if n == null:
		return
	n.add_to_group(GROUP)


## [API] Remove um node do grupo gerenciado.
static func unregister(n: Node) -> void:
	if n == null:
		return
	n.remove_from_group(GROUP)