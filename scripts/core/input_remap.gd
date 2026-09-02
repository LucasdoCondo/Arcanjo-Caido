extends Node
## ============================================================================
## [ARCANJO CAIDO] — Autoload: InputRemap (Passo 21)
## ----------------------------------------------------------------------------
## Remapeamento basico de teclas/controle, persistido 100% offline em
## user://input_map.json. Aplica os binds salvos no InputMap do Godot.
## Suporta teclado (InputEventKey) e gamepad (InputEventJoypadButton).
## ----------------------------------------------------------------------------

const SAVE_PATH := "user://input_map.json"

## Acoes remapeaveis + rotulo amigavel exibido no menu de opcoes.
const ACTIONS: Array = [
	{"action": "move_left", "label": "Mover Esquerda"},
	{"action": "move_right", "label": "Mover Direita"},
	{"action": "move_up", "label": "Mover Cima"},
	{"action": "move_down", "label": "Mover Baixo"},
	{"action": "jump", "label": "Pular"},
	{"action": "dash", "label": "Dash de Sombra"},
	{"action": "attack", "label": "Lamina do Alvorecer"},
	{"action": "interact", "label": "Interagir"},
	{"action": "heal", "label": "Cura Canalizada"},
	{"action": "map", "label": "Mapa"},
	{"action": "hook", "label": "Sombra de Voo (Gancho)"},
	{"action": "pause", "label": "Pausa"},
	{"action": "parry", "label": "Postura Parry"},
]

## Inputs que NAO devem ser usados como rebind (reservados para o sistema).
const LOCKED_KEYS := [
	KEY_ESCAPE,
	KEY_F11,
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_and_apply()


# ---------------------------------------------------------------------------
# API PUBLICA
# ---------------------------------------------------------------------------
## Retorna a descricao do bind atual da acao (ex: "A", "Gamepad Botao X").
func get_bind_text(action: String) -> String:
	if not InputMap.has_action(action):
		return "—"
	var events := InputMap.action_get_events(action)
	for ev in events:
		if ev is InputEventJoypadButton:
			return "Gamepad Botao %d" % (ev as InputEventJoypadButton).button_index
		if ev is InputEventKey:
			var key := ev as InputEventKey
			var code := key.physical_keycode if key.physical_keycode != 0 else key.keycode
			var txt := OS.get_keycode_string(code)
			if txt != "":
				return txt
	return "—"


## Troca o bind da acao para um novo evento (teclado ou gamepad).
## Retorna true se aplicado e salvo.
func rebind_action(action: String, event: InputEvent) -> bool:
	if not InputMap.has_action(action):
		return false
	if not _event_allowed(event):
		return false
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	_save()
	return true


## Restaura a acao para o bind padrao salvo neste script (fallback).
func reset_action(action: String) -> void:
	if not InputMap.has_action(action):
		return
	InputMap.action_erase_events(action)
	for ev in _default_events(action):
		InputMap.action_add_event(action, ev)
	_save()


## Restaura TODAS as acoes para os binds padrao do project.godot.
func reset_all() -> void:
	for entry in ACTIONS:
		var action: String = entry["action"]
		InputMap.action_erase_events(action)
		for ev in _default_events(action):
			InputMap.action_add_event(action, ev)
	_save()
# ---------------------------------------------------------------------------
# PERSISTENCIA (user:// -> 100% offline)
# ---------------------------------------------------------------------------
func _load_and_apply() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	for action in parsed:
		if not InputMap.has_action(action):
			continue
		InputMap.action_erase_events(action)
		var list = parsed[action]
		if typeof(list) == TYPE_ARRAY:
			for e in list:
				var restored := _dict_to_event(e)
				if restored != null:
					InputMap.action_add_event(action, restored)


func _save() -> void:
	var data: Dictionary = {}
	for entry in ACTIONS:
		var action: String = entry["action"]
		data[action] = []
		for ev in InputMap.action_get_events(action):
			var d := _event_to_dict(ev)
			if d.size() > 0:
				data[action].append(d)
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))


# ---------------------------------------------------------------------------
# SERIALIZACAO DE EVENTOS
# ---------------------------------------------------------------------------
func _event_to_dict(ev: InputEvent) -> Dictionary:
	if ev is InputEventJoypadButton:
		return {"type": "joy_button", "button_index": (ev as InputEventJoypadButton).button_index}
	if ev is InputEventKey:
		var key := ev as InputEventKey
		return {
			"type": "key",
			"keycode": key.keycode,
			"physical_keycode": key.physical_keycode,
		}
	return {}


func _dict_to_event(d: Variant) -> InputEvent:
	if typeof(d) != TYPE_DICTIONARY:
		return null
	var type: String = d.get("type", "")
	if type == "joy_button":
		var jb := InputEventJoypadButton.new()
		jb.button_index = int(d.get("button_index", 0))
		jb.device = -1
		return jb
	if type == "key":
		var k := InputEventKey.new()
		k.keycode = int(d.get("keycode", 0))
		k.physical_keycode = int(d.get("physical_keycode", 0))
		return k
	return null


func _event_allowed(ev: InputEvent) -> bool:
	if ev is InputEventKey:
		var key := ev as InputEventKey
		if key.physical_keycode in LOCKED_KEYS or key.keycode in LOCKED_KEYS:
			return false
		return true
	if ev is InputEventJoypadButton:
		return true
	return false


func _default_events(action: String) -> Array:
	## Reconstroi os binds padrao definidos no project.godot (fallback do reset).
	var defaults := {
		"move_left": [ _key(KEY_A), _key(KEY_LEFT) ],
		"move_right": [ _key(KEY_D), _key(KEY_RIGHT) ],
		"move_up": [ _key(KEY_W), _key(KEY_UP) ],
		"move_down": [ _key(KEY_S), _key(KEY_DOWN) ],
		"jump": [ _key(KEY_SPACE), _key(KEY_Z) ],
		"dash": [ _key(KEY_SHIFT), _key(KEY_X) ],
		"attack": [ _key(KEY_J) ],
		"interact": [ _key(KEY_E) ],
		"heal": [ _key(KEY_F) ],
		"map": [ _key(KEY_M), _key(KEY_TAB) ],
		"hook": [ _key(KEY_C) ],
		"pause": [ _key(KEY_ESCAPE), _key(KEY_P) ],
		"parry": [ _key(KEY_Q) ],
	}
	return defaults.get(action, [])


func _key(code: Key) -> InputEventKey:
	var k := InputEventKey.new()
	k.physical_keycode = code
	return k