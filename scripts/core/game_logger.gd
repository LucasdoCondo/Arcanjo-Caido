extends Node
## ============================================================================
## [ARCANJO CAIDO] — Autoload: GameLogger (Passo 25)
## ----------------------------------------------------------------------------
## Logger local de execução — crash dump local, 100% offline em user://.
## ----------------------------------------------------------------------------
## O QUE FAZ:
##   1. Log estruturado em user://game_session.log — cada evento registra:
##      timestamp | nível | versão do jogo | cena atual | última ação do
##      jogador | mensagem (+ stack trace em ERROR/CRITICAL em builds debug).
##   2. Intercepta o crash súbito da engine (NOTIFICATION_CRASH) e grava o
##      marcador user://last_session_crash.flag antes do encerramento forçado.
##   3. Verificação na inicialização: se a sessão anterior terminou em crash
##      crítico, exibe uma mensagem amigável na tela; se terminou sem
##      fechamento limpo, apenas registra o aviso no log.
##   4. Complementa o log nativo da engine (erros/warnings com stack trace em
##      user://logs/godot.log), ativado em project.godot → [debug]
##      file_logging/enable_file_logging_pc.
## ----------------------------------------------------------------------------
## ARQUIVOS GERADOS (todos em user://):
##   - game_session.log          → log de sessão estruturado (este autoload)
##   - logs/godot.log            → log nativo da engine (rotativo .1/.2/.3)
##   - session_active.flag       → existe = sessão aberta (sessão anterior
##                                 não fechou limpa quando encontrado no boot)
##   - last_session_crash.flag   → JSON com o contexto do crash crítico
## ----------------------------------------------------------------------------
## API (disponível em qualquer script):
##   GameLogger.info("...")     → apenas registra
##   GameLogger.warning("...")  → registra + push_warning
##   GameLogger.error("...")    → registra com stack trace + push_error
##   GameLogger.critical("...") → registra, grava o marcador de crash e exibe
##                                o aviso amigável na PRÓXIMA inicialização
## ============================================================================

const LOG_PATH := "user://game_session.log"
const SESSION_FLAG_PATH := "user://session_active.flag"
const CRASH_MARKER_PATH := "user://last_session_crash.flag"

const LVL_INFO := "INFO"
const LVL_WARNING := "WARNING"
const LVL_ERROR := "ERROR"
const LVL_CRITICAL := "CRITICAL"

## Versão do jogo (project.godot → application/config/version).
var game_version: String = "dev"
## Última ação de jogo pressionada pelo jogador (input map, ex: "jump").
var last_player_action: String = "início"

var _last_session_unexpected := false
var _last_session_critical := false
var _session_closed := false
var _crash_notice_shown := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var ver = ProjectSettings.get_setting("application/config/version", "dev")
	game_version = str(ver)
	_inspect_previous_session()
	_open_session()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_CRASH:
			## Crash súbito da engine (desktop): última chance de gravar em disco.
			_write_crash_marker("Crash súbito da engine (NOTIFICATION_CRASH).")
		NOTIFICATION_WM_CLOSE_REQUEST:
			_close_session()


func _exit_tree() -> void:
	## Fechamento limpo (get_tree().quit() ou fechamento da janela):
	## remove o marcador de sessão aberta. Em um crash real este método
	## normalmente NÃO roda — o .flag fica para trás e é detectado no boot.
	_close_session()


# ---------------------------------------------------------------------------
# API PÚBLICA DE LOG
# ---------------------------------------------------------------------------
func info(message: String) -> void:
	log_event(LVL_INFO, message)


func warning(message: String) -> void:
	log_event(LVL_WARNING, message)
	push_warning(message)


func error(message: String) -> void:
	log_event(LVL_ERROR, message, true)
	push_error(message)


func critical(message: String) -> void:
	## Erro fatal: grava o marcador de crash para que a PRÓXIMA sessão exiba
	## o aviso amigável de encerramento inesperado.
	_write_crash_marker(message)
	log_event(LVL_CRITICAL, message, true)
	push_error(message)


func log_event(level: String, message: String, with_stack: bool = false) -> void:
	var line := "[%s] [%s] [v%s] [cena=%s] [acao=%s] %s" % [
		_timestamp(), level, game_version, _current_scene_name(),
		last_player_action, message]
	if with_stack:
		var stack := get_stack()  ## vazio em builds release (limitação da engine)
		if stack.is_empty():
			line += "\n    (stack trace indisponível nesta build)"
		for frame in stack:
			line += "\n    em %s() — %s:%d" % [
				str(frame.get("function", "?")),
				str(frame.get("file", "?")), int(frame.get("line", 0))]
	_append(line)
	if level != LVL_INFO:
		print("[GameLogger] ", line.replace("\n", "\n    "))


# ---------------------------------------------------------------------------
# RASTREIO DA AÇÃO DO JOGADOR (contexto antes do erro)
# ---------------------------------------------------------------------------
func _input(event: InputEvent) -> void:
	## Registra a última ação de jogo pressionada — vai para o log junto de
	## cada evento, permitindo saber o que o jogador fazia antes do erro.
	if event is InputEventKey and event.pressed and not event.echo:
		for action in InputMap.get_actions():
			if String(action).begins_with("ui_"):
				continue
			if event.is_action_pressed(action):
				last_player_action = String(action)
				return


# ---------------------------------------------------------------------------
# VERIFICAÇÃO DA SESSÃO ANTERIOR (crash dump)
# ---------------------------------------------------------------------------
func _inspect_previous_session() -> void:
	_last_session_critical = FileAccess.file_exists(CRASH_MARKER_PATH)
	_last_session_unexpected = FileAccess.file_exists(SESSION_FLAG_PATH)


func _open_session() -> void:
	_append("================================================================")
	_append("[%s] [%s] [v%s] Sessão iniciada" % [
		_timestamp(), LVL_INFO, game_version])
	_append("[%s] [%s] Build de debug: %s | SO: %s" % [
		_timestamp(), LVL_INFO, OS.is_debug_build(), OS.get_name()])

	if _last_session_critical:
		var details := _read_file(CRASH_MARKER_PATH)
		_append("[%s] [%s] A SESSÃO ANTERIOR TERMINOU EM CRASH CRÍTICO: %s" % [
			_timestamp(), LVL_CRITICAL,
			details if details != "" else "(sem detalhes)"])
		_show_crash_notice()
	elif _last_session_unexpected:
		_append("[%s] [%s] A sessão anterior foi encerrada sem fechamento limpo (sem crash crítico registrado)." % [
			_timestamp(), LVL_WARNING])

	## Limpa os marcadores da sessão anterior e abre a sessão atual.
	var dir := DirAccess.open("user://")
	if dir != null:
		if _last_session_critical:
			dir.remove(CRASH_MARKER_PATH.get_file())
		dir.remove(SESSION_FLAG_PATH.get_file())
	var flag := FileAccess.open(SESSION_FLAG_PATH, FileAccess.WRITE)
	if flag != null:
		flag.store_string(JSON.stringify({
			"start": _timestamp(),
			"version": game_version,
			"debug_build": OS.is_debug_build(),
		}))


func _close_session() -> void:
	if _session_closed:
		return
	_session_closed = true
	_append("[%s] [%s] [v%s] Sessão encerrada normalmente." % [
		_timestamp(), LVL_INFO, game_version])
	var dir := DirAccess.open("user://")
	if dir != null:
		dir.remove(SESSION_FLAG_PATH.get_file())


func _write_crash_marker(message: String) -> void:
	## Grava em disco o contexto do crash (timestamp, versão, cena e a ação
	## que o jogador fazia) ANTES do encerramento forçado do processo.
	var data := {
		"timestamp": _timestamp(),
		"version": game_version,
		"scene": _current_scene_name(),
		"player_action": last_player_action,
		"message": message,
	}
	var f := FileAccess.open(CRASH_MARKER_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data, "  "))


# ---------------------------------------------------------------------------
# AVISO AMIGÁVEL DE CRASH DA SESSÃO ANTERIOR
# ---------------------------------------------------------------------------
func _show_crash_notice() -> void:
	if _crash_notice_shown:
		return
	_crash_notice_shown = true

	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.6)
	layer.add_child(dim)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	layer.add_child(center)
	center.set_anchors_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.05, 0.09, 0.97)
	style.border_color = Color(0.95, 0.5, 0.25, 0.85)
	style.set_border_width_all(2)
	style.set_content_margin_all(24.0)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "⚠  AETERNA ESTREMECEU..."
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.95, 0.5, 0.25))
	vbox.add_child(title)

	var body := Label.new()
	body.text = ("O ARCANJO CAIDO foi encerrado inesperadamente na última sessão.\n" +
		"Um registro técnico foi salvo localmente (user://game_session.log).\n" +
		"Seu progresso salvo não foi afetado.")
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_color_override("font_color", Color(0.85, 0.9, 0.85))
	vbox.add_child(body)

	var btn := Button.new()
	btn.text = "ENTENDI"
	btn.custom_minimum_size = Vector2(180.0, 44.0)
	btn.pressed.connect(func(): layer.queue_free())
	vbox.add_child(btn)


# ---------------------------------------------------------------------------
# HELPERS DE DISCO E FORMATAÇÃO
# ---------------------------------------------------------------------------
func _append(line: String) -> void:
	var f: FileAccess = null
	if FileAccess.file_exists(LOG_PATH):
		f = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
		if f != null:
			f.seek_end()
	else:
		f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("GameLogger: falha ao abrir o log em " + LOG_PATH)
		return
	f.store_string(line + "\n")
	f.close()


func _read_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	return f.get_as_text().strip_edges()


func _timestamp() -> String:
	var d := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d %02d:%02d:%02d" % [
		d.year, d.month, d.day, d.hour, d.minute, d.second]


func _current_scene_name() -> String:
	var cs := get_tree().current_scene
	if cs == null:
		return "?"
	return cs.scene_file_path.get_file()