extends Node
## ============================================================================
## [ARCANJO CAIDO] — Autoload: AudioManager (Passo 11 + Passo 19)
## ----------------------------------------------------------------------------
## Gerenciador central de áudio 100% offline:
##   - Buses separados: "Music" (BGM), "SFX" e "Ambience"
##   - Crossfade suave entre trilhas ao mudar de região / entrar em chefe
##   - SFX globais: AudioManager.sfx("jump" | "sword" | "hurt" | "coin" ...)
##   - Pitch variation em sons repetitivos (passos, lâminas, golpes)
##   - Como o projeto ainda não tem assets de áudio, os sons e as trilhas são
##     SINTETIZADOS em tempo real (AudioStreamWAV gerado por código). Quando
##     os .ogg/.wav reais chegarem, basta trocar os streams deste arquivo.
## ⚠️ ONDE CONECTAR ASSETS REAIS (.wav/.ogg):
##   - Substitua as chamadas `_make_tone(...)` / `_make_track(...)` por
##     `preload("res://assets/audio/nome_do_arquivo.ogg")`.
##   - Exemplo: "jump" → preload("res://assets/audio/sfx/jump_01.wav")
##   - Os SFX pools e o crossfade funcionam com qualquer AudioStream.
## ============================================================================

signal bus_volume_changed(bus_name: String, linear: float)
signal music_changed(track_id: String)

const SAMPLE_RATE := 22050
const SFX_POOL_SIZE := 10

## Definição das trilhas: id -> [freq base, "calmo"|"tenso"]
const TRACK_DEFS := {
	"menu": [98.0, "calmo"],
	"cripta_estrelas": [146.83, "calmo"],
	"corredor_cinzas": [110.0, "calmo"],
	"jardim_adonai": [130.81, "calmo"],
	"mar_de_vidro": [123.47, "calmo"],
	"catedral_avareza": [87.31, "tenso"],
	"boss": [65.41, "tenso"],
}

## ⚠️ ONDE CONECTAR ASSETS REAIS DE MÚSICA:
## Substitua `_get_track(track_id)` por um dicionário de preload():
##   const TRACK_ASSETS = {
##     "cripta_estrelas": preload("res://assets/audio/bgm/cripta_estrelas.ogg"),
##     "boss": preload("res://assets/audio/bgm/boss_theme.ogg"),
##     ...
##   }
## E retorne TRACK_ASSETS[track_id] em vez de sintetizar.

var _sounds: Dictionary = {}
var _tracks: Dictionary = {}
var _bgm_a: AudioStreamPlayer
var _bgm_b: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_idx: int = 0
var _using_a: bool = false
var _current_track: String = ""
## Sem tipo estático para permitir acesso dinâmico ao enum State do player
## (PlayerController) em tempo de execução; assim o autoload não depende do
## class cache global, evitando erro de parse no boot headless/fresh-clone.
var _player = null
var _hooks_connected: bool = false

## Passo 19: controle de pitch variation por som
## Sons que recebem variação aleatória de tom (0.9x a 1.1x) para evitar fadiga sonora
var _pitch_var_sounds: Dictionary = {}
var _default_pitch: float = 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_buses()
	_build_players()
	_synth_sounds()
	_setup_pitch_variation()


# ---------------------------------------------------------------------------
# BUSES
# ---------------------------------------------------------------------------
func _setup_buses() -> void:
	for bus_name in ["Music", "SFX", "Ambience"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			var idx := AudioServer.bus_count
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")


func _build_players() -> void:
	_bgm_a = _make_player("Music")
	_bgm_b = _make_player("Music")
	_ambience_player = _make_player("Ambience")
	for i in SFX_POOL_SIZE:
		_sfx_players.append(_make_player("SFX"))


func _make_player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


## Volume de um bus em escala linear (0.0 a 1.0) — usado pelas Opções.
func set_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	linear = clampf(linear, 0.0001, 1.0)
	AudioServer.set_bus_volume_db(idx, linear_to_db(linear))
	bus_volume_changed.emit(bus_name, linear)


func get_bus_volume(bus_name: String) -> float:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return 1.0
	var db := AudioServer.get_bus_volume_db(idx)
	return clampf(db_to_linear(db), 0.0, 1.0)


# ===========================================================================
# SINTETIZADOR (substituível por assets reais no futuro)
# ===========================================================================
func _make_tone(freq: float, dur: float, kind: String = "sine", vol: float = 0.5) -> AudioStreamWAV:
	var n := int(dur * SAMPLE_RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / SAMPLE_RATE
		var s: float
		match kind:
			"square":
				s = 1.0 if fmod(t * freq, 1.0) < 0.5 else -1.0
			"saw":
				s = fmod(t * freq, 1.0) * 2.0 - 1.0
			"noise":
				s = randf_range(-1.0, 1.0)
			_:
				s = sin(TAU * freq * t)
		var env := 1.0 - float(i) / n  ## Envelope de decaimento
		var v := int(clampf(s * env * vol, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, v)
	return _wav_from_data(data, false)


func _make_track(base_freq: float, mood: String = "calmo") -> AudioStreamWAV:
	## Trilha em loop: camadas de senoides com LFOs lentos (protótipo de BGM).
	var dur := 12.0 if mood == "calmo" else 9.0
	var n := int(dur * SAMPLE_RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / SAMPLE_RATE
		var s := 0.22 * sin(TAU * base_freq * t)
		s += 0.16 * sin(TAU * base_freq * 1.5 * t) * (0.5 + 0.5 * sin(TAU * 0.125 * t))
		s += 0.12 * sin(TAU * base_freq * 2.0 * t) * (0.5 + 0.5 * sin(TAU * 0.25 * t + 1.0))
		s += 0.2 * sin(TAU * base_freq * 0.5 * t)  ## Baixo
		if mood == "tenso":
			s += 0.08 * sin(TAU * base_freq * 3.0 * t) * (0.5 + 0.5 * sin(TAU * 0.75 * t))
		var v := int(clampf(s, -1.0, 1.0) * 32767.0 * 0.55)
		data.encode_s16(i * 2, v)
	return _wav_from_data(data, true)


func _wav_from_data(data: PackedByteArray, looping: bool) -> AudioStreamWAV:
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = data
	if looping:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = data.size() / 2
	return wav


func _synth_sounds() -> void:
	# ⚠️ ONDE CONECTAR ASSETS REAIS DE SFX:
	# Substitua cada linha por preload("res://assets/audio/sfx/nome.ogg")
	# Exemplo: "jump" → preload("res://assets/audio/sfx/jump_01.wav")
	_sounds = {
		"jump": _make_tone(520.0, 0.16, "square", 0.3),
		"dash": _make_tone(300.0, 0.14, "saw", 0.28),
		"sword": _make_tone(900.0, 0.09, "noise", 0.32),
		"hurt": _make_tone(170.0, 0.3, "square", 0.45),
		"coin": _make_tone(1250.0, 0.12, "sine", 0.35),
		"step": _make_tone(140.0, 0.06, "noise", 0.2),
		"death": _make_tone(110.0, 0.6, "saw", 0.45),
		"heal": _make_tone(660.0, 0.4, "sine", 0.35),
		"unlock": _make_tone(880.0, 0.5, "sine", 0.4),
		"achievement": _make_tone(1040.0, 0.35, "sine", 0.4),
		"parry": _make_tone(1500.0, 0.12, "square", 0.35),
		"pogo": _make_tone(700.0, 0.1, "square", 0.3),
		"ground_pound": _make_tone(80.0, 0.3, "saw", 0.5),
		"chama_drain": _make_tone(440.0, 0.25, "sine", 0.3),
		"vase_break": _make_tone(600.0, 0.15, "noise", 0.4),
		"wall_slide": _make_tone(200.0, 0.08, "noise", 0.15),
	}


# ===========================================================================
# PASSO 19: PITCH VARIATION (variação aleatória de tom)
# ---------------------------------------------------------------------------
# Sons repetitivos (passos, lâminas, golpes) recebem leve variação de pitch
# entre 0.9x e 1.1x para evitar "fadiga sonora" — o cérebro percebe como
# orgânico em vez de loop mecânico.
# ---------------------------------------------------------------------------
func _setup_pitch_variation() -> void:
	# ⚠️ ADICIONE AQUI os sons que devem ter pitch variation:
	# Basta adicionar o nome do som ao dicionário com o range desejado.
	_pitch_var_sounds = {
		"step": Vector2(0.88, 1.12),    # passos: variação ampla
		"sword": Vector2(0.92, 1.08),   # lâminas: variação sutil
		"jump": Vector2(0.95, 1.05),    # pulo: variação mínima
		"dash": Vector2(0.90, 1.10),    # dash: variação média
		"coin": Vector2(0.95, 1.15),    # moedas: variação ascendente
		"parry": Vector2(0.98, 1.02),   # parry: variação quase nula
	}


## Aplica variação aleatória de pitch a um AudioStreamPlayer.
## Chamado internamente antes de tocar sons repetitivos.
func _apply_pitch_variation(player: AudioStreamPlayer, sound_name: String) -> void:
	if _pitch_var_sounds.has(sound_name):
		var range: Vector2 = _pitch_var_sounds[sound_name]
		player.pitch_scale = randf_range(range.x, range.y)
	else:
		player.pitch_scale = _default_pitch

# ===========================================================================
# API PÚBLICA
# ===========================================================================
func sfx(sound_name: String) -> void:
	## Trigger global de efeito sonoro: AudioManager.sfx("sword")
	## Aplica pitch variation automática em sons repetitivos.
	var stream: AudioStreamWAV = _sounds.get(sound_name)
	if stream == null:
		return
	var p := _sfx_players[_sfx_idx]
	_sfx_idx = (_sfx_idx + 1) % _sfx_players.size()
	p.stream = stream
	# Passo 19: pitch variation para evitar fadiga sonora
	_apply_pitch_variation(p, sound_name)
	p.play()


func play_music(track_id: String, fade: float = 1.5) -> void:
	## Troca de trilha com CROSSFADE (região nova / arena de chefe).
	if _current_track == track_id:
		return
	_current_track = track_id
	music_changed.emit(track_id)

	var incoming := _bgm_b if _using_a else _bgm_a
	var outgoing := _bgm_a if _using_a else _bgm_b
	_using_a = not _using_a

	incoming.stream = _get_track(track_id)
	incoming.volume_db = -40.0
	incoming.play()

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(incoming, "volume_db", 0.0, fade)
	tw.tween_property(outgoing, "volume_db", -40.0, fade)
	tw.chain().tween_callback(outgoing.stop)


# ---------------------------------------------------------------------------
# PASSO 19: MÚSICA DE CHEFE — swap dinâmico na arena
# ---------------------------------------------------------------------------
## Troca instantânea para a versão de batalha ao entrar na arena de um chefe.
## Se já estiver tocando o tema de chefe, não faz nada.
func play_boss_music(fade: float = 0.8) -> void:
	## Chamado ao entrar na arena de um chefe.
	## Exemplo: AudioManager.play_boss_music(0.5) para transição rápida.
	play_music("boss", fade)


## Retorna a música de região ao sair da arena de chefe.
## Parâmetro: track_id da região de origem (ex: "catedral_avareza").
func exit_boss_music(region_track: String = "cripta_estrelas", fade: float = 1.2) -> void:
	## Chamado ao sair da arena de um chefe.
	## Exemplo: AudioManager.exit_boss_music("catedral_avareza")
	play_music(region_track, fade)


func _get_track(track_id: String) -> AudioStreamWAV:
	if _tracks.has(track_id):
		return _tracks[track_id]
	var def: Array = TRACK_DEFS.get(track_id, [110.0, "calmo"])
	var track: AudioStreamWAV = _make_track(def[0], def[1])
	_tracks[track_id] = track
	return track


func play_ambience(sound_name: String = "wind") -> void:
	## Camada de ambiente contínua (vento do Vazio etc.).
	if _ambience_player.playing:
		return
	var stream: AudioStreamWAV = _sounds.get(sound_name)
	if stream == null:
		stream = _make_tone(90.0, 3.0, "noise", 0.12)
		_sounds[sound_name] = stream
	_ambience_player.stream = stream
	_ambience_player.volume_db = -8.0
	_ambience_player.play()


# ===========================================================================
# HOOKS AUTOMÁTICOS — conecta os sinais do Lúcifer aos SFX
# ===========================================================================
func _process(_delta: float) -> void:
	if _hooks_connected and (not is_instance_valid(_player) or _player == null):
		_hooks_connected = false
		_player = null
	if not _hooks_connected:
		_player = get_tree().get_first_node_in_group("player")
		if _player and _player.has_signal("dashed"):
			_player.dashed.connect(func(): sfx("dash"))
			_player.damaged.connect(func(_amount): sfx("hurt"))
			_player.died.connect(func(): sfx("death"))
			_player.state_changed.connect(_on_player_state)
			if _player.has_signal("coin_collected"):
				_player.coin_collected.connect(func(): sfx("coin"))
			_hooks_connected = true


func _on_player_state(new_state: int) -> void:
	## Nota: comparamos com _player.State.JUMP/ATTACK em tempo de execução
	## (acesso dinâmico) para que este autoload não dependa da classe global
	## PlayerController em tempo de parse — ver declaração de `_player`.
	if _player == null:
		return
	if new_state == _player.State.JUMP:
		sfx("jump")
	elif new_state == _player.State.ATTACK:
		sfx("sword")
