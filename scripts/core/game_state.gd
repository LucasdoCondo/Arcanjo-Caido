extends Node
## ============================================================================
## [ARCANJO CAIDO] — Autoload: GameState
## ----------------------------------------------------------------------------
## Estado global do jogo, persistente entre as salas (e base para o
## Save/Load offline do Passo 4).
##   - player_data: snapshot do Lúcifer (vida, Chama Negra, Pratas de Judas)
##   - rooms/visited/revealed: mapa com fog of war (estilo Cassandra)
##   - markers: marcadores personalizados que o jogador coloca no mapa
## ============================================================================

## Snapshot do Lúcifer, capturado a cada transição de sala.
var player_data: Dictionary = {}

## id -> {name, col, row, w, h, connections, bench, npc}
var rooms: Dictionary = {}
## Salas exploradas (fog of war aberta).
var visited: Dictionary = {}
## Salas reveladas pelo "Mapa da Cassandra" (visíveis só como contorno,
## até serem visitadas) — exige cassandra_map_purchased.
var revealed: Dictionary = {}
## id -> true: marcador personalizado colocado pelo jogador.
var markers: Dictionary = {}
## Sala em que o Lúcifer está agora (destaque dourado no mapa).
var current_room_id: String = ""

## Se o jogador já comprou o mapa base com a Cartógrafa Cassandra.
var cassandra_map_purchased: bool = false

## Passo 8: habilidades de exploração desbloqueadas ao derrotar chefes.
## ids: "wall_jump" (Garra do Abismo), "double_jump" (Asas Caídas),
##      "ground_pound" (Macho de Ferro), "hook" (Sombra de Voo)
var abilities: Dictionary = {
	"wall_jump": false,
	"double_jump": false,
	"ground_pound": false,
	"hook": false,
}


func unlock_ability(id: String) -> void:
	if abilities.has(id):
		abilities[id] = true
		# Passo 10: conquista das 4 habilidades de exploração.
		var all_unlocked := true
		for ability_id in abilities:
			if not abilities[ability_id]:
				all_unlocked = false
				break
		if all_unlocked:
			Achievements.unlock("abilities_all")


## Passo 13: hit stop / freeze frame — micro-congelamento global para dar
## peso aos impactos (golpes críticos, dano sofrido, ground pound).
func hit_stop(duration: float = 0.05, time_scale: float = 0.1) -> void:
	if Engine.time_scale < 1.0:
		return  ## Já existe um hit stop em andamento
	Engine.time_scale = time_scale
	var t := get_tree().create_timer(duration, true, false, true)  ## ignora time_scale
	t.timeout.connect(func(): Engine.time_scale = 1.0)


# ===========================================================================
# PASSO 5: FLAGS DE QUESTS E NPCs
# ===========================================================================
var flags: Dictionary = {}   ## ex: "cassandra_map_bought", "azazel_freed"


# ===========================================================================
# PASSO 6: SIGILOS DO BANIMENTO (talismãs equipáveis)
# ===========================================================================
const MAX_SIGILS := 2

var sigils_owned: Dictionary = {}    ## id -> true
var sigils_equipped: Array = []      ## até MAX_SIGILS ids


func grant_sigil(id: String) -> void:
	sigils_owned[id] = true


func toggle_sigil(id: String) -> void:
	if not sigils_owned.has(id):
		return
	if sigils_equipped.has(id):
		sigils_equipped.erase(id)
	elif sigils_equipped.size() < MAX_SIGILS:
		sigils_equipped.append(id)


# ===========================================================================
# PASSO 4: RESPAWN NO ÚLTIMO PONTO DE DESCANSO
# ===========================================================================
var respawn_scene_path: String = ""
var respawn_position: Vector2 = Vector2.ZERO
var has_respawn: bool = false


func set_respawn(scene_path: String, position: Vector2) -> void:
	respawn_scene_path = scene_path
	respawn_position = position
	has_respawn = true


func respawn_player() -> void:
	## Lúcifer morreu: acorda no último banco, de vida cheia e Chama vazia.
	if not has_respawn:
		respawn_scene_path = "res://scenes/test/arena_teste.tscn"
		respawn_position = Vector2(300, 600)
	player_data["health"] = player_data.get("max_health", 5)
	player_data["chama"] = 0.0
	SceneTransition.change_room(respawn_scene_path, "", respawn_position)


# ===========================================================================
# PASSO 22: TEMPO DE JOGO, CONCLUSÃO DO MAPA E FINAIS
# ===========================================================================
## Tempo total de jogo acumulado (segundos). Exibido no seletor de Save Slots
## como "H:MM". Persistido junto de cada slot.
var playtime_seconds: float = 0.0

## Final pendente a ser exibido pela tela de Créditos ("padrao"/"verdadeiro").
var pending_ending: String = ""


func _process(delta: float) -> void:
	playtime_seconds += delta


## Percentual de conclusão do mapa (0..100): salas visitadas / salas conhecidas.
## Usado no seletor de Save Slots do Menu Principal.
func map_completion_percent() -> int:
	if rooms.is_empty():
		return 0
	return int(round(float(visited.size()) / float(rooms.size()) * 100.0))


## Formata o tempo de jogo como "H:MM" (ex: "3:07" = 3 horas e 7 minutos).
static func format_playtime(seconds: float) -> String:
	var total_min := int(seconds) / 60
	return "%d:%02d" % [total_min / 60, total_min % 60]


## Passo 22: aciona um final do jogo e leva o jogador à tela de Créditos.
##   "padrao"    — derrotar Mammon (Soberano do Vazio)
##   "verdadeiro" — recusar o trono, destruir Aeterna (A Verdadeira Libertação)
## A tela de créditos lê pending_ending para escolher o texto do epílogo.
func request_ending(ending_id: String) -> void:
	pending_ending = ending_id
	match ending_id:
		"verdadeiro":
			Achievements.unlock("true_freedom")
		_:
			Achievements.unlock("mammon_slain")
	SceneTransition.change_room("res://scenes/ui/credits_screen.tscn", "")


# ---------------------------------------------------------------------------
# JOGADOR
# ---------------------------------------------------------------------------
func capture_player(p: Node) -> void:
	## Chamado pelo SceneTransition antes de trocar de sala.
	player_data = {
		"max_health": p.max_health,
		"health": p.current_health,
		"chama": p.chama_negra,
		"pratas": p.pratas_de_judas,
	}


func restore_defaults() -> void:
	player_data = {}
	rooms = {}
	visited = {}
	revealed = {}
	markers = {}
	current_room_id = ""
	cassandra_map_purchased = false
	flags = {}
	sigils_owned = {}
	sigils_equipped = []
	has_respawn = false
	respawn_scene_path = ""
	playtime_seconds = 0.0
	pending_ending = ""


# ---------------------------------------------------------------------------
# MAPA / SALAS
# ---------------------------------------------------------------------------
func visit_room(id: String, data: Dictionary) -> void:
	## Chamado pelo script Room ao carregar uma sala: registra e abre o fog.
	rooms[id] = data
	visited[id] = true
	current_room_id = id


func reveal_room(id: String) -> void:
	## Chamado ao comprar/usar um mapa da Cassandra.
	revealed[id] = true


func purchase_cassandra_map() -> void:
	cassandra_map_purchased = true
	for id in rooms:
		revealed[id] = true


func toggle_marker(id: String) -> void:
	markers[id] = not markers.get(id, false)


func is_room_visible(id: String) -> bool:
	## Sala aparece no mapa se visitada OU revelada pela Cassandra.
	return visited.has(id) or (cassandra_map_purchased and revealed.has(id))
