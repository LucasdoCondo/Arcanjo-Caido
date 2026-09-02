extends Node
## ============================================================================
## [ARCANJO CAIDO] — Autoload: SaveManager (Passo 10/4)
## ----------------------------------------------------------------------------
## 3 Save Slots locais em user://save_slot_N.json — 100% offline.
## Salva: snapshot do Lúcifer, habilidades, salas exploradas do mapa,
## marcadores, sala atual e estado da Cassandra.
## (Pontos de Descanso e respawn no banco chegam na finalização do Passo 4.)
## ============================================================================

const SLOT_COUNT := 3


func slot_path(slot: int) -> String:
	return "user://save_slot_%d.json" % slot


func has_slot(slot: int) -> bool:
	return slot >= 0 and slot < SLOT_COUNT and FileAccess.file_exists(slot_path(slot))


func get_slot_info(slot: int) -> Dictionary:
	## Metadados para o seletor do Menu Principal.
	if not has_slot(slot):
		return {}
	var f := FileAccess.open(slot_path(slot), FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func save_slot(slot: int) -> bool:
	if slot < 0 or slot >= SLOT_COUNT:
		return false
	## Captura o Lúcifer atual antes de gravar.
	var player = get_tree().get_first_node_in_group("player")
	if player:
		GameState.capture_player(player)
	var data := {
		"version": 1,
		"room_name": GameState.rooms.get(GameState.current_room_id, {}).get("name", "?"),
		"player": GameState.player_data,
		"abilities": GameState.abilities,
		"flags": GameState.flags,
		"sigils_owned": GameState.sigils_owned.keys(),
		"sigils_equipped": GameState.sigils_equipped,
		"rooms": GameState.rooms,
		"visited": GameState.visited.keys(),
		"revealed": GameState.revealed.keys(),
		"markers": GameState.markers.keys(),
		"current_room": GameState.current_room_id,
		"cassandra": GameState.cassandra_map_purchased,
		"respawn_room": GameState.respawn_scene_path,
		"respawn_x": GameState.respawn_position.x,
		"respawn_y": GameState.respawn_position.y,
		"has_respawn": GameState.has_respawn,
		"playtime": GameState.playtime_seconds,  ## Passo 22: tempo total de jogo
	}
	var f := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data))
	print("[ARCANJO CAIDO] Jogo salvo no slot %d" % (slot + 1))
	return true


func load_slot(slot: int) -> bool:
	## Restaura o GameState e teletransporta para a sala salva (com fade).
	var info := get_slot_info(slot)
	if info.is_empty():
		return false
	GameState.restore_defaults()
	GameState.player_data = info.get("player", {})
	GameState.abilities = info.get("abilities", GameState.abilities.duplicate())
	for id in info.get("visited", []):
		GameState.visited[id] = true
	for id in info.get("revealed", []):
		GameState.revealed[id] = true
	for id in info.get("markers", []):
		GameState.markers[id] = true
	GameState.cassandra_map_purchased = bool(info.get("cassandra", false))
	for key in info.get("flags", {}):
		GameState.flags[key] = true
	for id in info.get("sigils_owned", []):
		GameState.sigils_owned[id] = true
	GameState.sigils_equipped = info.get("sigils_equipped", [])
	GameState.has_respawn = bool(info.get("has_respawn", false))
	GameState.respawn_scene_path = info.get("respawn_room", "")
	GameState.respawn_position = Vector2(info.get("respawn_x", 0.0),
			info.get("respawn_y", 0.0))
	GameState.playtime_seconds = float(info.get("playtime", 0.0))  ## Passo 22

	var current: String = info.get("current_room", "")
	if current != "" and GameState.rooms.has(current):
		GameState.current_room_id = current
		var scene_path: String = GameState.rooms[current].get("scene", "")
		if scene_path != "":
			SceneTransition.change_room(scene_path, "")
			return true
	## Fallback: vai para a sala inicial.
	SceneTransition.change_room("res://scenes/test/arena_teste.tscn", "")
	return true
