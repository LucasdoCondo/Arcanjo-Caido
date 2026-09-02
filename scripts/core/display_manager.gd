extends Node
## ============================================================================
## [ARCANJO CAIDO] — Autoload: DisplayManager (Passo 14)
## ----------------------------------------------------------------------------
## Gerenciador de tela e configurações persistentes 100% offline:
##   - Fullscreen / Janela / Janela sem bordas + resoluções comuns (F11)
##   - Configurações (vídeo + áudio) salvas em user://settings.json
##   - Verificação de persistência offline (user:// gravável, sem rede)
## ============================================================================

const SETTINGS_PATH := "user://settings.json"
const RESOLUTIONS: Array = [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]

var settings: Dictionary = {
	"fullscreen": false,
	"borderless": false,
	"resolution_idx": 2,
	"vsync": true,
	"vol_music": 1.0,
	"vol_sfx": 1.0,
	"vol_amb": 0.8,
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_settings()
	_apply_display()
	_apply_audio()
	verify_offline_storage()


# ---------------------------------------------------------------------------
# TELA
# ---------------------------------------------------------------------------
func toggle_fullscreen() -> void:
	settings["fullscreen"] = not settings["fullscreen"]
	_apply_display()
	_save_settings()


func set_fullscreen(on: bool) -> void:
	settings["fullscreen"] = on
	_apply_display()
	_save_settings()


func set_borderless(on: bool) -> void:
	settings["borderless"] = on
	_apply_display()
	_save_settings()


func set_resolution(idx: int) -> void:
	settings["resolution_idx"] = clampi(idx, 0, RESOLUTIONS.size() - 1)
	_apply_display()
	_save_settings()


## Passo 21: alterna V-Sync (60 FPS+ com tear eliminado; desligue p/ menor latencia).
func set_vsync(on: bool) -> void:
	settings["vsync"] = on
	_apply_display()
	_save_settings()


func _apply_display() -> void:
	var vsync := DisplayServer.VSYNC_ENABLED if settings["vsync"] else DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(vsync)
	if settings["fullscreen"]:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS,
				settings["borderless"])
		var res: Vector2i = RESOLUTIONS[settings["resolution_idx"]]
		DisplayServer.window_set_size(res)
	DisplayServer.window_set_position(
			(DisplayServer.screen_get_size() - DisplayServer.window_get_size()) / 2)


func _unhandled_input(event: InputEvent) -> void:
	## Atalho global: F11 alterna tela cheia.
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_F11:
		toggle_fullscreen()
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------------------
# CONFIGURAÇÕES PERSISTENTES (user://)
# ---------------------------------------------------------------------------
func _apply_audio() -> void:
	AudioManager.set_bus_volume("Music", settings["vol_music"])
	AudioManager.set_bus_volume("SFX", settings["vol_sfx"])
	AudioManager.set_bus_volume("Ambience", settings["vol_amb"])


func set_audio_volume(bus_name: String, linear: float) -> void:
	match bus_name:
		"Music": settings["vol_music"] = linear
		"SFX": settings["vol_sfx"] = linear
		"Ambience": settings["vol_amb"] = linear
	_save_settings()


func _save_settings() -> void:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(settings))


func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		for key in settings:
			if parsed.has(key):
				settings[key] = parsed[key]


# ---------------------------------------------------------------------------
# VERIFICAÇÃO DE PERSISTÊNCIA OFFLINE (Passo 14)
# ---------------------------------------------------------------------------
func verify_offline_storage() -> bool:
	## Garante que user:// é gravável localmente (sem dependência de rede).
	var ok := false
	var f := FileAccess.open("user://.offline_check", FileAccess.WRITE)
	if f:
		f.store_string("offline-ok")
		f.close()
		ok = FileAccess.file_exists("user://.offline_check")
		DirAccess.remove_absolute("user://.offline_check")
	if not ok:
		push_error("[ARCANJO CAIDO] Falha na persistência local (user://)!")
	else:
		print("[ARCANJO CAIDO] Persistência offline OK: user://")
	return ok
