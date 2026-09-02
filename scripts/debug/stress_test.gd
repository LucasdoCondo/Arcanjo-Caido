class_name StressTest
extends Node
## ============================================================================
## [ARCANJO CAIDO] — Passo 26: Suíte de Testes Stress & Profiling
## ----------------------------------------------------------------------------
## FERRAMENTA DE QA — existe apenas em builds de debug (é criada pelo DevMenu,
## e o filtro de export "scripts/debug/*" a remove do lançamento por completo).
## ----------------------------------------------------------------------------
## 1. DETECTOR DE VAZAMENTO DE MEMÓRIA:
##    monitora RAM (OS.get_static_memory_usage) e VRAM
##    (RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) a cada transição de
##    cena/sala. Se a memória continuar SUBINDO após 10 trocas de sala
##    consecutivas, envia alerta via GameLogger.error (com stack trace) e
##    push_warning no console.
## 2. INSTANCIAÇÃO MASSIVA (stress test de CPU/GPU):
##    engendra 100 Pratas de Judas + 20 Guardiões Caídos ao redor do Lúcifer,
##    mede FPS antes/depois e registra o resultado. A limpeza (F7) libera
##    tudo com queue_free() e VALIDA que nenhum nó ficou órfão.
## ----------------------------------------------------------------------------
## USO (via DevMenu, F1):
##   F6 — engendrar 100 Pratas + 20 inimigos
##   F7 — limpar o stress e validar a limpeza dos nós
##   F8 — relatório de memória imediato
## ============================================================================

const PRATA_SCENE := "res://scenes/enemies/prata_judas.tscn"
const ENEMY_SCENE := "res://scenes/enemies/guardiao_caido.tscn"

const COIN_COUNT := 100
const ENEMY_COUNT := 20
const STRESS_GROUP := "stress_spawn"

## Monitor de vazamento: histórico com 11 amostras = 10 transições analisadas.
const LEAK_HISTORY := 11
const RAM_TOLERANCE := 0.01     ## 1% de ruído aceitável entre amostras
const RAM_TOTAL_RISE := 0.03    ## alerta só se a subida total passar de 3%
const VRAM_TOLERANCE := 0.02
const VRAM_TOTAL_RISE := 0.05

var _last_scene_path := ""
var _ram_history: Array[float] = []
var _vram_history: Array[float] = []
var _ram_leak_warned := false
var _vram_leak_warned := false

var _stress_nodes: Array[Node] = []
var _node_count_before_spawn := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var cs := get_tree().current_scene
	_last_scene_path = cs.scene_file_path if cs != null else ""


func _process(_delta: float) -> void:
	var cs := get_tree().current_scene
	if cs == null:
		return
	if cs.scene_file_path != _last_scene_path:
		_last_scene_path = cs.scene_file_path
		_on_scene_changed()


# ---------------------------------------------------------------------------
# DETECTOR DE VAZAMENTO DE MEMÓRIA (Passo 26.1)
# ---------------------------------------------------------------------------
func _on_scene_changed() -> void:
	## Um frame de respiro para a cena assentar (recursos carregarem).
	await get_tree().process_frame
	var ram_mb := OS.get_static_memory_usage() / 1048576.0
	var vram_mb := RenderingServer.get_rendering_info(
			RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / 1048576.0
	_ram_history.append(ram_mb)
	_vram_history.append(vram_mb)
	while _ram_history.size() > LEAK_HISTORY:
		_ram_history.pop_front()
	while _vram_history.size() > LEAK_HISTORY:
		_vram_history.pop_front()
	GameLogger.info("Transição de sala → %s | RAM %.1f MB | VRAM %.1f MB | nós %d" % [
		_last_scene_path.get_file(), ram_mb, vram_mb,
		get_tree().get_node_count()])
	_check_memory_leak()


func _check_memory_leak() -> void:
	if _history_is_rising(_ram_history, RAM_TOLERANCE, RAM_TOTAL_RISE) \
			and not _ram_leak_warned:
		_ram_leak_warned = true
		var msg := ("POSSÍVEL VAZAMENTO DE RAM: memória subiu continuamente de " +
			"%.1f MB para %.1f MB ao longo de %d trocas de sala consecutivas.") % [
				_ram_history[0], _ram_history[_ram_history.size() - 1],
				_ram_history.size() - 1]
		GameLogger.error(msg)
		push_warning("[STRESS] " + msg)
	if _history_is_rising(_vram_history, VRAM_TOLERANCE, VRAM_TOTAL_RISE) \
			and not _vram_leak_warned:
		_vram_leak_warned = true
		var msg := ("POSSÍVEL VAZAMENTO DE VRAM: memória de vídeo subiu continuamente de " +
			"%.1f MB para %.1f MB ao longo de %d trocas de sala consecutivas.") % [
				_vram_history[0], _vram_history[_vram_history.size() - 1],
				_vram_history.size() - 1]
		GameLogger.error(msg)
		push_warning("[STRESS] " + msg)


func _history_is_rising(history: Array[float], tolerance: float,
		min_total_rise: float) -> bool:
	## True quando as 10 transições consecutivas mostram subida monotônica
	## (aceitando ruído de `tolerance` por passo) acima de `min_total_rise`.
	if history.size() < LEAK_HISTORY:
		return false
	var first := history[0]
	var last := history[history.size() - 1]
	if last <= first * (1.0 + min_total_rise):
		return false
	for i in range(1, history.size()):
		if history[i] < history[i - 1] * (1.0 - tolerance):
			return false
	return true


# ---------------------------------------------------------------------------
# INSTANCIAÇÃO MASSIVA DE PARTÍCULAS/INIMIGOS (Passo 26.2)
# ---------------------------------------------------------------------------
func spawn_stress() -> void:
	## Engendra 100 Pratas de Judas + 20 Guardiões ao redor do Lúcifer e
	## mede a queda de FPS (stress de CPU/GPU).
	if _stress_nodes.size() > 0:
		GameLogger.warning(
			"STRESS: já existe uma onda ativa (%d nós). Use Limpar (F7) antes." %
			_stress_nodes.size())
		return
	var player: Node2D = get_tree().get_first_node_in_group("player")
	if player == null:
		GameLogger.warning(
			"STRESS: o Lúcifer precisa estar em cena (não funciona no menu).")
		return
	var scene := get_tree().current_scene
	if scene == null:
		return

	var prata_scene: PackedScene = load(PRATA_SCENE)
	var enemy_scene: PackedScene = load(ENEMY_SCENE)
	if prata_scene == null or enemy_scene == null:
		GameLogger.error("STRESS: cenas de Prata de Judas/Guardião não encontradas.")
		return

	_node_count_before_spawn = get_tree().get_node_count()
	var baseline_fps: float = await _avg_fps(30)
	var origin: Vector2 = player.global_position

	## 100 Pratas de Judas em leque acima do Lúcifer (caem com a física própria).
	for i in COIN_COUNT:
		var coin := prata_scene.instantiate()
		coin.add_to_group(STRESS_GROUP)
		coin.position = origin + Vector2(
			randf_range(-380.0, 380.0), randf_range(-280.0, -40.0))
		_stress_nodes.append(coin)
		scene.add_child.call_deferred(coin)

	## 20 Guardiões Caídos em duas fileiras laterais (IA completa ativa).
	for i in ENEMY_COUNT:
		var enemy := enemy_scene.instantiate()
		enemy.add_to_group(STRESS_GROUP)
		var side := 1.0 if i % 2 == 0 else -1.0
		enemy.position = origin + Vector2(
			side * randf_range(120.0, 420.0), randf_range(-240.0, -80.0))
		_stress_nodes.append(enemy)
		scene.add_child.call_deferred(enemy)

	## Espera a cena assentar (spawns deferred + física) e mede o impacto.
	await get_tree().create_timer(3.0).timeout
	var stress_fps: float = await _avg_fps(30)
	var nodes_now := get_tree().get_node_count()
	var drop_pct := (baseline_fps - stress_fps) / maxf(baseline_fps, 1.0) * 100.0
	var report := ("STRESS: %d Pratas + %d inimigos engendrados. " +
		"FPS %.0f → %.0f (queda de %.1f%%). Nós: %d → %d.") % [
			COIN_COUNT, ENEMY_COUNT, baseline_fps, stress_fps, drop_pct,
			_node_count_before_spawn, nodes_now]
	GameLogger.info(report)
	print("[STRESS] ", report)


func clear_stress() -> void:
	## Libera todos os nós do stress com queue_free() e VALIDA a limpeza:
	## após 3 frames nenhum nó do grupo pode sobrar na árvore.
	if _stress_nodes.is_empty():
		print("[STRESS] Nenhuma onda de stress ativa para limpar.")
		return
	var freed_count := _stress_nodes.size()
	for node in _stress_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_stress_nodes.clear()
	## queue_free remove ao fim do frame; aguarda alguns para a limpeza efetivar.
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var remaining := get_tree().get_nodes_in_group(STRESS_GROUP).size()
	var nodes_now := get_tree().get_node_count()
	if remaining == 0:
		var msg := ("STRESS: limpeza VALIDADA — %d nós liberados com queue_free(), " +
			"nenhum órfão restou (nós na árvore: %d).") % [freed_count, nodes_now]
		GameLogger.info(msg)
		print("[STRESS] ", msg)
	else:
		var msg := ("STRESS: FALHA NA LIMPEZA — %d nós do stress continuam na " +
			"árvore após o queue_free (possível vazamento de nós).") % remaining
		GameLogger.error(msg)
		push_error("[STRESS] " + msg)


func memory_report() -> void:
	## Relatório imediato de profilling: RAM, VRAM, nós, FPS e draw calls.
	var ram_mb := OS.get_static_memory_usage() / 1048576.0
	var vram_mb := RenderingServer.get_rendering_info(
			RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / 1048576.0
	var report := ("MEMÓRIA: RAM %.1f MB | VRAM %.1f MB | nós %d | FPS %d | draw calls %d" % [
		ram_mb, vram_mb, get_tree().get_node_count(),
		Engine.get_frames_per_second(),
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])
	GameLogger.info(report)
	print("[STRESS] ", report)


func _avg_fps(frames: int) -> float:
	## FPS médio ao longo de N frames (evita ruído de um frame solto).
	var total := 0.0
	for i in frames:
		await get_tree().process_frame
		total += float(Engine.get_frames_per_second())
	return total / maxf(float(frames), 1.0)